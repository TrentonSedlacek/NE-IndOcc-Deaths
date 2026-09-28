# =====================================================================
# io_death_rates.R
# Nebraska suicide and drug overdose death rates by industry and
# occupation, residents aged 16+, 2020 to 2024 pooled.
#
# One script, top to bottom. Sections:
#   0 config      1 load deaths     2 flag outcomes    3 NIOCCS coding
#   4 cert-code cross-check         5 ACS denominators 6 rates
#   7 suppression                   8 QA checks        9 write
#
# Provenance: every death-certificate rule copies a line in SAS that the
# team already uses.
#   DC template = dc-hdd-surveillance/programs/dc/dc_condition_surveillance.sas
#   OHIs        = ohis/sub-indicators/subindicators.sas
#   NIOCCS      = team-archive/io-coding/nioccs/CDC NIOCCS web service i_o GET.R
#   Plan        = docs/analysis-plan.md
# Runs on a DHHS machine with K: access. Needs: readxl, dplyr, tidyr,
# stringr, httr, jsonlite, tidycensus, readr. Census key from the
# environment variable CENSUS_API_KEY; never write it in this file.
# =====================================================================

suppressPackageStartupMessages({
  library(readxl); library(dplyr); library(tidyr); library(stringr)
  library(httr); library(jsonlite); library(readr); library(tidycensus)
})

# ---------------------------------------------------------------------
# 0. CONFIG. The only block anyone should need to edit.
# ---------------------------------------------------------------------
cfg <- list(
  years        = 2020:2024,
  dc_dir       = "K:/Occupational Health Grant/data/dc",     # {YYYY}/DeathCertificates{YY}.xlsx
  out_dir      = "K:/Occupational Health Grant/Trenton Sedlacek/IO-Death-Rates/Output",
  cache_dir    = "K:/Occupational Health Grant/Trenton Sedlacek/IO-Death-Rates/Cache",
  census_xwalk = "K:/Occupational Health Grant/ables/Data/ABLES analysis 2026/crosswalks/2022-Census-Industry-Code-List-with-Crosswalk.xlsx",
  acs_year     = 2024,          # ACS 5-year ending year: 2020-2024 window
  acs_span     = 5,
  min_age      = 16,            # OHIs line 412: age ge 16 (worker denominator)
  suppress_floor = 6,           # OHIs line 64: counts 1 to 5 are not published
  unstable_below = 20,          # OHIs line 932: fewer than 20 events flagged unstable
  ne_residents_only = TRUE,     # DC template line 68
  run_nioccs   = TRUE,          # FALSE to reuse the cache without new API calls
  census_key   = Sys.getenv("CENSUS_API_KEY")
)
dir.create(cfg$out_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(cfg$cache_dir, showWarnings = FALSE, recursive = TRUE)
stopifnot("Set CENSUS_API_KEY in the environment" = nzchar(cfg$census_key))
census_api_key(cfg$census_key, install = FALSE, overwrite = TRUE)

# ---------------------------------------------------------------------
# 1. LOAD DEATHS. Guardian yearly exports, read directly from xlsx
#    (SAS cannot open them: floating point overflow, see DC-HDD docs).
#    Keep only the fields the plan names. Everything is read as text so
#    no code loses a leading zero.
# ---------------------------------------------------------------------
keep_vars <- c("DeathCertificateId", "StateFileNumber", "EventYear", "DateOfDeath",
               "ResidingStateNchs", "NchsAge", "NchsAgeUnit", "Sex", "MannerDeath",
               "AcmeUnderlyingCode", paste0("D2Acme", 1:20), paste0("D2SmicarAxis", 1:20),
               "ImmedCauseDeath", "Consq1", "Consq2", "Consq3", "OtherSignificantConditions",
               "IndustryLit", "OccupationLIt", "IndustryCode", "OccupationCode")

read_guardian <- function(yr) {
  f <- file.path(cfg$dc_dir, yr, sprintf("DeathCertificates%02d.xlsx", yr %% 100))
  if (!file.exists(f)) stop("Missing ", f)
  d <- read_excel(f, col_types = "text", guess_max = 0)
  missing <- setdiff(keep_vars, names(d))
  if (length(missing)) stop(yr, ": fields not in export: ", paste(missing, collapse = ", "))
  d[, keep_vars]
}
deaths_raw <- bind_rows(lapply(cfg$years, read_guardian))

deaths <- deaths_raw %>%
  mutate(across(everything(), ~ str_trim(.x))) %>%
  mutate(EventYear = as.integer(EventYear),
         NchsAge = as.numeric(NchsAge), NchsAgeUnit = as.integer(NchsAgeUnit)) %>%
  # OHIs line 378: keep EventYear = requested years (exports overlap by 53 to 66 late deaths)
  filter(EventYear %in% cfg$years) %>%
  # DC template line 28 and OHIs line 409: one row per certificate
  distinct(DeathCertificateId, .keep_all = TRUE) %>%
  # DC template line 68 and OHIs line 379: Nebraska residents
  { if (cfg$ne_residents_only) filter(., toupper(ResidingStateNchs) == "NE") else . } %>%
  # DC template lines 71 to 75 and OHIs lines 382 to 387: age in years from age and unit
  mutate(age = case_when(
    NchsAge == 999 ~ NA_real_,
    NchsAgeUnit == 1 ~ NchsAge,
    NchsAgeUnit == 2 ~ floor(NchsAge / 12),
    NchsAgeUnit == 3 ~ floor(NchsAge / 52),
    NchsAgeUnit %in% 4:6 ~ 0,
    TRUE ~ NA_real_)) %>%
  mutate(sex = case_when(toupper(substr(Sex, 1, 1)) == "M" ~ "M",
                         toupper(substr(Sex, 1, 1)) == "F" ~ "F", TRUE ~ "U"),
         manner = toupper(substr(MannerDeath, 1, 1)))   # DC template line 103: S = suicide

all_ages_n <- nrow(deaths)
deaths <- deaths %>% filter(!is.na(age), age >= cfg$min_age)   # OHIs line 412
message("Deaths loaded: ", all_ages_n, " residents, ", nrow(deaths), " aged ", cfg$min_age, "+")

# ---------------------------------------------------------------------
# 2. FLAG OUTCOMES.
#    Code scan copies DC template lines 43 to 55: 41 fields (underlying
#    plus both multiple-cause axes), codes compressed of dots and spaces,
#    prefix match. Text scan copies lines 56 to 63: five literal fields,
#    case-insensitive.
# ---------------------------------------------------------------------
cause_fields <- c("AcmeUnderlyingCode", paste0("D2Acme", 1:20), paste0("D2SmicarAxis", 1:20))
text_fields  <- c("ImmedCauseDeath", "Consq1", "Consq2", "Consq3", "OtherSignificantConditions")

clean_code <- function(x) toupper(str_replace_all(coalesce(x, ""), "[. ]", ""))
code_mat <- sapply(deaths[cause_fields], clean_code)         # n x 41 character matrix
underlying <- code_mat[, 1]
text_all <- do.call(paste, c(deaths[text_fields], sep = " | "))

any_prefix <- function(mat, prefixes) {
  hit <- matrix(FALSE, nrow(mat), ncol(mat))
  for (p in prefixes) hit <- hit | (substr(mat, 1, nchar(p)) == p)
  rowSums(hit) > 0
}
in_range <- function(code3, lo, hi) code3 >= lo & code3 <= hi   # 3-char ICD block compare

u3 <- substr(underlying, 1, 3)
u4 <- substr(underlying, 1, 4)

deaths <- deaths %>% mutate(
  # Suicide: X60 to X84, Y87.0, U03. Plan step 2; NEVDRS dashboard definition.
  # Legacy combine data.sas line 196 used "UO3" with a letter O; fixed here.
  suicide_icd = in_range(u3, "X60", "X84") | u4 == "Y870" | u3 == "U03",
  suicide_manner = manner == "S",
  suicide = suicide_icd,

  # SUDORS overdose: underlying X40 to X44 or Y10 to Y14, or literal text
  # indicating acute drug overdose (SUDORS case definition, CDC dashboard).
  od_icd  = in_range(u3, "X40", "X44") | in_range(u3, "Y10", "Y14"),
  od_text = str_detect(text_all, regex("overdose|toxicity|intoxication|drug poison", ignore_case = TRUE)) &
            !str_detect(text_all, regex("carbon monoxide|\\bCO\\b poison", ignore_case = TRUE)),
  # Text hits with only alcohol named and no drug T code are not SUDORS cases.
  od_alcohol_only = od_text & str_detect(text_all, regex("alcohol|ethanol", ignore_case = TRUE)) &
                    !str_detect(text_all, regex("fentanyl|opioid|opiate|heroin|methamphetamine|cocaine|drug|medication|pill", ignore_case = TRUE)) &
                    !any_prefix(code_mat, c("T40", "T41", "T42", "T43", "T44", "T45", "T46", "T47", "T48", "T49", "T50")),
  overdose = od_icd | (od_text & !od_alcohol_only),
  od_needs_review = !od_icd & overdose,          # text-only cases: manual review list

  # Opioid involvement: T40.0 to T40.4, T40.6 in any multiple-cause field (MA report, p. 10).
  opioid_t = any_prefix(code_mat[, -1, drop = FALSE], c("T400", "T401", "T402", "T403", "T404", "T406")),
  overdose_opioid = overdose & opioid_t,

  # Massachusetts all-intent opioid-related definition, for comparability only.
  ma_opioid = opioid_t & (in_range(u3, "X40", "X49") | in_range(u3, "X60", "X69") |
                          in_range(u3, "X85", "X90") | u4 == "Y352" | in_range(u3, "Y10", "Y19"))
)

# Data note: manner versus ICD disagreement (plan step 2).
manner_note <- deaths %>% count(suicide_icd, suicide_manner)

cases <- deaths %>% filter(suicide | overdose | ma_opioid)
message("Cases: suicide ", sum(deaths$suicide), ", overdose ", sum(deaths$overdose),
        ", opioid subset ", sum(deaths$overdose_opioid), ", MA all-intent opioid ", sum(deaths$ma_opioid))

# ---------------------------------------------------------------------
# 3. NIOCCS CODING of the usual industry and occupation text.
#    Call copied from the team's GET.R (lines 6 to 19): one GET per
#    record, i = industry text, o = occupation text, c = 2. Added here:
#    a cache keyed on the text pair so reruns make no calls, a retry,
#    and a status check (the original had none).
# ---------------------------------------------------------------------
nioccs_one <- function(industry, occupation) {
  for (attempt in 1:3) {
    r <- try(GET("https://wwwn.cdc.gov/nioccs/IOCode?",
                 query = list(i = industry, o = occupation, c = 2), timeout(30)), silent = TRUE)
    if (!inherits(r, "try-error") && status_code(r) == 200) {
      j <- fromJSON(content(r, as = "text", encoding = "UTF-8"))
      ind <- as.list(j$Industry); occ <- as.list(j$Occupation)
      return(tibble(
        NAICSCode = as.character(ind$NAICSCode %||% NA), CensusIndustryCode = as.character(ind$CensusIndustryCode %||% ind$CensusCode %||% NA),
        CensusIndustryTitle = as.character(ind$CensusIndustryTitle %||% ind$Title %||% NA), ind_score = as.character(ind$Score %||% ind$Confidence %||% NA),
        SOCCode = as.character(occ$SOCCode %||% NA), CensusOccupationCode = as.character(occ$CensusOccupationCode %||% occ$CensusCode %||% NA),
        CensusOccupationTitle = as.character(occ$CensusOccupationTitle %||% occ$Title %||% NA), occ_score = as.character(occ$Score %||% occ$Confidence %||% NA)))
    }
    Sys.sleep(2 * attempt)
  }
  tibble(NAICSCode = NA_character_, CensusIndustryCode = NA_character_, CensusIndustryTitle = NA_character_, ind_score = NA_character_,
         SOCCode = NA_character_, CensusOccupationCode = NA_character_, CensusOccupationTitle = NA_character_, occ_score = "CALL_FAILED")
}
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a

cache_file <- file.path(cfg$cache_dir, "nioccs_cache.csv")
cache <- if (file.exists(cache_file)) read_csv(cache_file, col_types = cols(.default = "c")) else
  tibble(IndustryLit = character(), OccupationLIt = character())

pairs <- cases %>% distinct(IndustryLit, OccupationLIt) %>%
  mutate(across(everything(), ~ coalesce(.x, ""))) %>%
  anti_join(cache, by = c("IndustryLit", "OccupationLIt"))
if (cfg$run_nioccs && nrow(pairs) > 0) {
  message("NIOCCS: coding ", nrow(pairs), " new text pairs")
  coded <- bind_rows(lapply(seq_len(nrow(pairs)), function(i)
    bind_cols(pairs[i, ], nioccs_one(pairs$IndustryLit[i], pairs$OccupationLIt[i]))))
  cache <- bind_rows(cache, coded)
  write_csv(cache, cache_file)
}
cases <- cases %>% mutate(across(c(IndustryLit, OccupationLIt), ~ coalesce(.x, ""))) %>%
  left_join(cache, by = c("IndustryLit", "OccupationLIt"))

# Roll-ups. NAICS sector with 31-33, 44-45, 48-49 combined (suicide_agg.R,
# nioccs_suicide.R, MA report, OHIs strata.csv). SOC major group = first two digits.
naics_sector <- function(code) {
  s <- substr(coalesce(code, ""), 1, 2)
  case_when(s %in% c("31", "32", "33") ~ "31-33", s %in% c("44", "45") ~ "44-45",
            s %in% c("48", "49") ~ "48-49", s == "" ~ NA_character_, TRUE ~ s)
}
sector_labels <- c("11" = "Agriculture, forestry, fishing and hunting", "21" = "Mining, quarrying, oil and gas",
  "22" = "Utilities", "23" = "Construction", "31-33" = "Manufacturing", "42" = "Wholesale trade",
  "44-45" = "Retail trade", "48-49" = "Transportation and warehousing", "51" = "Information",
  "52" = "Finance and insurance", "53" = "Real estate and rental", "54" = "Professional, scientific and technical",
  "55" = "Management of companies", "56" = "Administrative, support, waste management", "61" = "Educational services",
  "62" = "Health care and social assistance", "71" = "Arts, entertainment and recreation",
  "72" = "Accommodation and food services", "81" = "Other services", "92" = "Public administration")
soc_labels <- c("11" = "Management", "13" = "Business and financial operations", "15" = "Computer and mathematical",
  "17" = "Architecture and engineering", "19" = "Life, physical and social science", "21" = "Community and social service",
  "23" = "Legal", "25" = "Educational instruction and library", "27" = "Arts, design, entertainment, sports and media",
  "29" = "Healthcare practitioners and technical", "31" = "Healthcare support", "33" = "Protective service",
  "35" = "Food preparation and serving", "37" = "Building and grounds cleaning and maintenance",
  "39" = "Personal care and service", "41" = "Sales and related", "43" = "Office and administrative support",
  "45" = "Farming, fishing and forestry", "47" = "Construction and extraction", "49" = "Installation, maintenance and repair",
  "51" = "Production", "53" = "Transportation and material moving", "55" = "Military specific")

# Non-rate groups assigned BEFORE anything is dropped (plan step 4).
nonwork_rx <- regex("homemaker|housewife|house wife|student|retired|unemployed|never worked|disabled|disability|child|infant|minor|inmate|prisoner", ignore_case = TRUE)
cases <- cases %>% mutate(
  io_text = paste(IndustryLit, OccupationLIt),
  sector  = naics_sector(NAICSCode),
  socgrp  = substr(coalesce(SOCCode, ""), 1, 2),
  military = sector == "92" & str_detect(io_text, regex("army|navy|air force|marine|military|armed forces|national guard", ignore_case = TRUE)) |
             socgrp == "55" | str_detect(coalesce(NAICSCode, ""), "^928110"),
  ind_group = case_when(
    military ~ "Military",
    str_detect(io_text, nonwork_rx) & (is.na(sector) | sector %in% c("", "00", "99")) ~ "Not in workforce",
    is.na(sector) | sector %in% c("", "00", "99") ~ "Not coded",
    TRUE ~ sector),
  occ_group = case_when(
    military ~ "Military",
    str_detect(io_text, nonwork_rx) & (socgrp %in% c("", "00", "99")) ~ "Not in workforce",
    socgrp %in% c("", "00", "99") ~ "Not coded",
    TRUE ~ socgrp),
  # Deliberately NOT recoding SOC 11-9013 farm managers into group 45 (nioccs_suicide.R
  # line 68 did). ACS SOC denominators keep them in 11; numerator must match.
  review_flag = occ_score == "CALL_FAILED" | is.na(NAICSCode) | is.na(SOCCode) |
                str_detect(coalesce(ind_score, ""), regex("low", ignore_case = TRUE)) |
                str_detect(coalesce(occ_score, ""), regex("low", ignore_case = TRUE)))

# Manual review list (plan step 3). De-identified: no names, no ids beyond the certificate id.
review_list <- cases %>% filter(review_flag | od_needs_review) %>%
  select(DeathCertificateId, EventYear, suicide, overdose, od_needs_review, IndustryLit, OccupationLIt,
         NAICSCode, SOCCode, ind_score, occ_score, ind_group, occ_group)
write_csv(review_list, file.path(cfg$cache_dir, "manual_review_list.csv"))
# After review, save decisions as Cache/manual_review_decisions.csv with columns
# DeathCertificateId, ind_group, occ_group, note. They override below.
dec_file <- file.path(cfg$cache_dir, "manual_review_decisions.csv")
if (file.exists(dec_file)) {
  dec <- read_csv(dec_file, col_types = cols(.default = "c"))
  cases <- cases %>% left_join(dec %>% select(DeathCertificateId, ind_dec = ind_group, occ_dec = occ_group), by = "DeathCertificateId") %>%
    mutate(ind_group = coalesce(ind_dec, ind_group), occ_group = coalesce(occ_dec, occ_group)) %>% select(-ind_dec, -occ_dec)
  message("Applied ", nrow(dec), " manual review decisions")
}

# ---------------------------------------------------------------------
# 4. CROSS-CHECK against the certificate's own coded fields.
#    OHIs line 392: IndustryCode is the 4-digit Census code with the
#    trailing digit dropped; OHIs multiplies by 10 and maps through the
#    2022 Census industry code list to a NAICS sector.
# ---------------------------------------------------------------------
xw <- try(read_excel(cfg$census_xwalk, col_types = "text"), silent = TRUE)
if (!inherits(xw, "try-error")) {
  # Expect a column holding the 4-digit Census code and one holding NAICS; find them by name.
  ccol <- names(xw)[str_detect(tolower(names(xw)), "census.*code|^code")][1]
  ncol_ <- names(xw)[str_detect(tolower(names(xw)), "naics")][1]
  xw2 <- xw %>% transmute(census4 = str_pad(str_replace_all(.data[[ccol]], "\\D", ""), 4, "left", "0"),
                          sector_cert = naics_sector(str_replace_all(.data[[ncol_]], "\\D", ""))) %>% distinct(census4, .keep_all = TRUE)
  cases <- cases %>%
    mutate(census4 = ifelse(nchar(coalesce(IndustryCode, "")) == 3, paste0(IndustryCode, "0"), IndustryCode)) %>%
    left_join(xw2, by = "census4")
  coding_agreement <- cases %>% filter(!ind_group %in% c("Military", "Not in workforce", "Not coded"), !is.na(sector_cert)) %>%
    count(ind_group, agree = ind_group == sector_cert) %>% group_by(ind_group) %>%
    mutate(pct_agree = round(100 * n / sum(n), 1)) %>% ungroup()
} else {
  coding_agreement <- tibble(note = "Census industry crosswalk not found; cross-check skipped")
}

# ---------------------------------------------------------------------
# 5. ACS DENOMINATORS. C24030 sex by industry, C24010 sex by occupation,
#    civilian employed 16+, Nebraska, 5-year 2020-2024. Categories are
#    mapped by their LABEL TEXT from the API metadata, not by variable
#    number, so a table re-numbering cannot silently misalign them.
#    Worker-years = estimate x 5 (docs/acs-denominator-spec.md).
# ---------------------------------------------------------------------
vars <- load_variables(cfg$acs_year, "acs5", cache = TRUE) %>%
  filter(str_detect(name, "^C24030_|^C24010_")) %>%
  mutate(label = str_replace_all(label, "!!", " > "))
acs <- get_acs(geography = "state", state = "NE", table = NULL,
               variables = vars$name, year = cfg$acs_year, survey = "acs5") %>%
  left_join(vars, by = c("variable" = "name")) %>%
  mutate(sex = case_when(str_detect(label, "> Male") ~ "M", str_detect(label, "> Female") ~ "F", TRUE ~ "T"),
         leaf = str_trim(str_replace(label, ".*> ", "")))

# Industry: ACS C24030 leaf categories to NAICS sectors. Leaves that are
# parents of finer leaves are dropped (their children carry the count).
ind_map <- tribble(~pattern, ~sector,
  "^Agriculture, forestry, fishing and hunting$", "11", "^Mining, quarrying, and oil and gas extraction$", "21",
  "^Construction$", "23", "^Manufacturing$", "31-33", "^Wholesale trade$", "42", "^Retail trade$", "44-45",
  "^Transportation and warehousing$", "48-49", "^Utilities$", "22", "^Information$", "51",
  "^Finance and insurance$", "52", "^Real estate and rental and leasing$", "53",
  "^Professional, scientific, and technical services$", "54", "^Management of companies and enterprises$", "55",
  "^Administrative and support and waste management services$", "56", "^Educational services$", "61",
  "^Health care and social assistance$", "62", "^Arts, entertainment, and recreation$", "71",
  "^Accommodation and food services$", "72", "^Other services, except public administration$", "81",
  "^Public administration$", "92")
map_leaf <- function(leaf, map) { out <- rep(NA_character_, length(leaf))
  for (i in seq_len(nrow(map))) out[is.na(out) & str_detect(leaf, regex(map$pattern[i], ignore_case = TRUE))] <- map[[2]][i]
  out }
den_ind <- acs %>% filter(str_detect(variable, "^C24030_"), sex != "T") %>%
  mutate(sector = map_leaf(leaf, ind_map)) %>% filter(!is.na(sector)) %>%
  group_by(group = sector, sex) %>% summarise(workers = sum(estimate), moe = sqrt(sum(moe^2)), .groups = "drop")
stopifnot("ACS industry mapping did not find all 20 sectors" = n_distinct(den_ind$group) == 20)

# Occupation: ACS C24010 leaf categories to SOC major groups. The ACS
# groupings follow SOC major groups closely; each pattern below is one
# leaf. AUDIT THIS TABLE against the 2020-2024 C24010 labels before use.
occ_map <- tribble(~pattern, ~socgrp,
  "^Management occupations$", "11", "^Business and financial operations occupations$", "13",
  "^Computer and mathematical occupations$", "15", "^Architecture and engineering occupations$", "17",
  "^Life, physical, and social science occupations$", "19", "^Community and social service occupations$", "21",
  "^Legal occupations$", "23", "^Educational instruction, and library occupations$", "25",
  "^Arts, design, entertainment, sports, and media occupations$", "27",
  "^Health diagnosing and treating practitioners and other technical occupations$", "29",
  "^Health technologists and technicians$", "29", "^Healthcare support occupations$", "31",
  "^Firefighting and prevention, and other protective service workers including supervisors$", "33",
  "^Law enforcement workers including supervisors$", "33", "^Food preparation and serving related occupations$", "35",
  "^Building and grounds cleaning and maintenance occupations$", "37", "^Personal care and service occupations$", "39",
  "^Sales and related occupations$", "41", "^Office and administrative support occupations$", "43",
  "^Farming, fishing, and forestry occupations$", "45", "^Construction and extraction occupations$", "47",
  "^Installation, maintenance, and repair occupations$", "49", "^Production occupations$", "51",
  "^Transportation occupations$", "53", "^Material moving occupations$", "53")
den_occ <- acs %>% filter(str_detect(variable, "^C24010_"), sex != "T") %>%
  mutate(socgrp = map_leaf(leaf, occ_map)) %>% filter(!is.na(socgrp)) %>%
  group_by(group = socgrp, sex) %>% summarise(workers = sum(estimate), moe = sqrt(sum(moe^2)), .groups = "drop")
stopifnot("ACS occupation mapping did not find all 22 civilian SOC groups" = n_distinct(den_occ$group) == 22)

acs_total_ind <- acs %>% filter(variable == "C24030_001") %>% pull(estimate)
acs_total_occ <- acs %>% filter(variable == "C24010_001") %>% pull(estimate)
add_totals <- function(den) bind_rows(den, den %>% group_by(group) %>% summarise(sex = "T", workers = sum(workers), moe = sqrt(sum(moe^2)), .groups = "drop"),
                                          den %>% group_by(sex) %>% summarise(group = "All workers", workers = sum(workers), moe = sqrt(sum(moe^2)), .groups = "drop"),
                                          den %>% summarise(group = "All workers", sex = "T", workers = sum(workers), moe = sqrt(sum(moe^2))))
den_ind <- add_totals(den_ind); den_occ <- add_totals(den_occ)

# ---------------------------------------------------------------------
# 6. RATES. deaths / (workers x span) x 100,000. Exact Poisson 95% CI on
#    the count (MA report p. 10). Rate ratio vs all workers with a
#    log-normal CI. Crude only; no age adjustment by sector (plan step 7).
# ---------------------------------------------------------------------
pois_ci <- function(k) { lo <- ifelse(k == 0, 0, qchisq(0.025, 2 * k) / 2); hi <- qchisq(0.975, 2 * (k + 1)) / 2; cbind(lo, hi) }

build_table <- function(cases, outcome_col, group_col, den, group_labels, years) {
  cs <- cases %>% filter(.data[[outcome_col]], EventYear %in% years)
  counts <- bind_rows(
    cs %>% count(group = .data[[group_col]], sex, name = "deaths"),
    cs %>% count(group = .data[[group_col]], name = "deaths") %>% mutate(sex = "T"),
    cs %>% filter(!.data[[group_col]] %in% c("Military", "Not in workforce", "Not coded")) %>% count(sex, name = "deaths") %>% mutate(group = "All workers"),
    cs %>% filter(!.data[[group_col]] %in% c("Military", "Not in workforce", "Not coded")) %>% summarise(deaths = n()) %>% mutate(group = "All workers", sex = "T"))
  span <- length(years)
  tab <- den %>% full_join(counts, by = c("group", "sex")) %>%
    mutate(deaths = coalesce(deaths, 0L),
           worker_years = workers * span,
           rate = deaths / worker_years * 1e5)
  ci <- pois_ci(tab$deaths)
  tab <- tab %>% mutate(rate_lo = ci[, 1] / worker_years * 1e5, rate_hi = ci[, 2] / worker_years * 1e5)
  ref <- tab %>% filter(group == "All workers") %>% select(sex, ref_deaths = deaths, ref_wy = worker_years)
  tab <- tab %>% left_join(ref, by = "sex") %>%
    mutate(rr = rate / (ref_deaths / ref_wy * 1e5),
           rr_se = sqrt(1 / pmax(deaths, 0.5) + 1 / ref_deaths),
           rr_lo = exp(log(rr) - 1.96 * rr_se), rr_hi = exp(log(rr) + 1.96 * rr_se),
           pct_of_all_deaths = 100 * deaths / sum(counts$deaths[counts$sex == sex & !counts$group %in% c("All workers")], na.rm = TRUE),
           label = coalesce(group_labels[group], group),
           outcome = outcome_col, years = paste(range(years), collapse = "-")) %>%
    select(outcome, years, group, label, sex, deaths, pct_of_all_deaths, workers, worker_years, rate, rate_lo, rate_hi, rr, rr_lo, rr_hi) %>%
    arrange(sex, group)
  tab
}

pooled <- cfg$years; check_yrs <- 2020:2021
tables <- list(
  suicide_ind  = build_table(cases, "suicide", "ind_group", den_ind, sector_labels, pooled),
  suicide_occ  = build_table(cases, "suicide", "occ_group", den_occ, soc_labels, pooled),
  overdose_ind = build_table(cases, "overdose", "ind_group", den_ind, sector_labels, pooled),
  overdose_occ = build_table(cases, "overdose", "occ_group", den_occ, soc_labels, pooled),
  opioid_ind   = build_table(cases, "overdose_opioid", "ind_group", den_ind, sector_labels, pooled),
  opioid_occ   = build_table(cases, "overdose_opioid", "occ_group", den_occ, soc_labels, pooled),
  # NEVDRS reconciliation cut: 2020-2021 only. The ACS 2020-2024 window is used
  # as the denominator here because no cleaner 2-year denominator exists; the
  # point of this table is the COUNTS (84 / 72 / 55), not the rate.
  suicide_ind_2020_2021 = build_table(cases, "suicide", "ind_group", den_ind, sector_labels, check_yrs))

# ---------------------------------------------------------------------
# 7. SUPPRESSION. OHIs line 64 (floor 6) and 932 (unstable under 20).
#    Non-rate rows keep counts (they are large) but never a rate.
# ---------------------------------------------------------------------
suppress <- function(tab) tab %>% mutate(
  nonrate = group %in% c("Military", "Not in workforce", "Not coded"),
  flag = case_when(deaths == 0 ~ "zero", deaths < cfg$suppress_floor ~ "suppressed",
                   deaths < cfg$unstable_below ~ "unstable", TRUE ~ ""),
  across(c(workers, worker_years, rate, rate_lo, rate_hi, rr, rr_lo, rr_hi), ~ ifelse(nonrate, NA, .x)),
  across(c(rate, rate_lo, rate_hi, rr, rr_lo, rr_hi), ~ ifelse(flag == "suppressed", NA, .x)),
  deaths_shown = ifelse(flag == "suppressed", NA_integer_, deaths)) %>%
  select(-nonrate)
tables <- lapply(tables, suppress)

# ---------------------------------------------------------------------
# 8. QA CHECKS (plan section 5). Printed; the run is not done until all pass.
# ---------------------------------------------------------------------
by_year <- deaths %>% group_by(EventYear) %>% summarise(suicide = sum(suicide), overdose = sum(overdose), opioid = sum(overdose_opioid))
sum_check <- function(tab) { t <- tab %>% filter(sex == "T"); all_rows <- sum(t$deaths[t$group != "All workers"]); w <- t$deaths[t$group == "All workers"]
  nr <- sum(t$deaths[t$group %in% c("Military", "Not in workforce", "Not coded")]); c(sectors_plus_nonrate = all_rows, all_workers_plus_nonrate = w + nr) }
qa <- list(
  deaths_by_year_age16plus = by_year,
  note_all_ages_vs_16plus = c(all_ages_residents = all_ages_n, aged_16_plus = nrow(deaths)),
  manner_vs_icd_suicide = manner_note,
  sector_sums_equal_total = sapply(tables, sum_check),
  acs_industry_total_vs_mapped = c(published_C24030_001 = acs_total_ind, mapped_sectors_T = den_ind$workers[den_ind$group == "All workers" & den_ind$sex == "T"]),
  acs_occupation_total_vs_mapped = c(published_C24010_001 = acs_total_occ, mapped_groups_T = den_occ$workers[den_occ$group == "All workers" & den_occ$sex == "T"]),
  coding_agreement_nioccs_vs_certificate = coding_agreement,
  records_needing_review = nrow(review_list),
  nevdrs_reconciliation_2020_2021 = tables$suicide_ind_2020_2021 %>% filter(sex == "T", group %in% c("Not in workforce", "23", "31-33")) %>%
    select(group, label, deaths) %>% mutate(nevdrs_sheet = c("Not in workforce" = 84, "23" = 72, "31-33" = 55)[group])
)
print(qa)
message("Reference totals to compare by hand: NEVDRS dashboard suicides 2020 289, 2021 305, 2022 284 (all ages); ",
        "SUDORS 2021-2022 combined 366 (all ages). The by-year table above is 16+ residents by ICD, so expect it slightly lower.")

# ---------------------------------------------------------------------
# 9. WRITE. Aggregate tables only. No record-level output leaves Cache/.
# ---------------------------------------------------------------------
stamp <- format(Sys.Date(), "%Y%m%d")
for (nm in names(tables)) write_csv(tables[[nm]], file.path(cfg$out_dir, sprintf("%s_%s.csv", nm, stamp)))
write_csv(bind_rows(tables), file.path(cfg$out_dir, sprintf("io_death_rates_all_%s.csv", stamp)))
capture.output(print(qa), file = file.path(cfg$out_dir, sprintf("qa_checks_%s.txt", stamp)))
writeLines(c(sprintf("io_death_rates.R run %s", Sys.time()), sprintf("years %s", paste(cfg$years, collapse = " ")),
             sprintf("ACS %d 5-year, C24030 and C24010, Nebraska", cfg$acs_year),
             "Suicide: underlying X60-X84, Y87.0, U03. Overdose: SUDORS (X40-44, Y10-14, or overdose text). Opioid: T40.0-.4, .6 any mention.",
             "Residents, age 16+, one row per certificate. NIOCCS coding of usual industry and occupation text.",
             sprintf("Suppression: rates blank under %d deaths; unstable under %d.", cfg$suppress_floor, cfg$unstable_below)),
           file.path(cfg$out_dir, sprintf("methods_%s.txt", stamp)))
message("Done. Outputs in ", cfg$out_dir)
