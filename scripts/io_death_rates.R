# =====================================================================
# io_death_rates.R
# Nebraska suicide and drug overdose death rates by industry and
# occupation, residents aged 16+, 2020 to 2024 pooled.
#
# One script, top to bottom. Sections:
#   0 config      1 load deaths     2 flag outcomes    3 NIOCCS coding
#   4 cert-code cross-check         5 ACS denominators 6 rates
#   7 (no suppression; see CLAUDE.md)  8 QA checks   9 write
#
# Provenance: every death-certificate rule copies a line in SAS that the
# team already uses.
#   DC template = dc-hdd-surveillance/programs/dc/dc_condition_surveillance.sas
#   OHIs        = ohis/sub-indicators/subindicators.sas
#   NIOCCS      = team-archive/io-coding/nioccs/CDC NIOCCS web service i_o GET.R
#   Plan        = docs/analysis-plan.md
# Audit notes: docs/script-audit.md.
#
# Runs on a DHHS machine with K: access. Needs: readxl, dplyr, stringr,
# httr, jsonlite, readr; tidycensus only if the ACS CSVs are not saved
# (section 5). Census key from the environment variable CENSUS_API_KEY;
# never write it in this file.
#
# Where record-level data goes: only the Cache folder (NIOCCS replies,
# manual review list, QA counts). The Output folder gets aggregate
# tables only, with full counts: NO suppression at this stage. Nothing prints a record to the console.
# =====================================================================

suppressPackageStartupMessages({
  library(readxl); library(dplyr); library(stringr)
  library(httr); library(jsonlite); library(readr)
})

# ---------------------------------------------------------------------
# 0. CONFIG. The only block anyone should need to edit.
# ---------------------------------------------------------------------
cfg <- list(
  years        = 2020:2024,
  # {YYYY}/DeathCertificates{YY}.csv (the CSV the SAS programs read). If the
  # CSV is not there the .xlsx is read instead; R can open it, SAS cannot.
  dc_dir       = "K:/Occupational Health Grant/data/dc",
  out_dir      = "K:/Occupational Health Grant/Trenton Sedlacek/IO-Death-Rates/Output",
  cache_dir    = "K:/Occupational Health Grant/Trenton Sedlacek/IO-Death-Rates/Cache",
  # Folder holding acs_acs5_2024_C24030_NE.csv and acs_acs5_2024_C24010_NE.csv
  # from scripts/fetch_acs_denominators.py. If absent, tidycensus pulls them.
  acs_dir      = "K:/Occupational Health Grant/Trenton Sedlacek/IO-Death-Rates/Denominators",
  acs_year     = 2024,          # ACS 5-year ending year: 2020-2024 window
  min_age      = 16,            # OHIs line 412: age ge 16 (worker denominator)
  ne_residents_only = TRUE,     # DC template line 68, OHIs line 379
  # Sending I/O text to CDC needs Derry's data use agreement answer (plan
  # section 4). Leave FALSE until then; the cache is reused either way.
  run_nioccs   = FALSE,
  # NIOCCS confidence field. UNKNOWN: no team script ever read one. Open
  # one raw_json value in Cache/nioccs_cache.csv, find the field name under
  # "Industry" and "Occupation", and put it here (for example "IndustryScore").
  # While NA, the review list is driven by missing codes only.
  nioccs_ind_conf_field = NA_character_,
  nioccs_occ_conf_field = NA_character_,
  nioccs_conf_min = NA_real_    # records scoring below this go on the review list
)

# Test hook: tests/synthetic_run.R sets this option to point every path at
# fake data. It is never set in a normal run.
if (!is.null(getOption("io_death_rates.test_cfg"))) cfg <- modifyList(cfg, getOption("io_death_rates.test_cfg"))

dir.create(cfg$out_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(cfg$cache_dir, showWarnings = FALSE, recursive = TRUE)

# ---------------------------------------------------------------------
# 1. LOAD DEATHS. Guardian yearly exports, one file per year.
#    Keep only the fields the plan names. Everything is read as text so
#    no code loses a leading zero.
# ---------------------------------------------------------------------
keep_vars <- c("DeathCertificateId", "StateFileNumber", "EventYear", "DateOfDeath",
               "ResidingStateNchs", "NchsAge", "NchsAgeUnit", "Sex", "MannerDeath",
               "AcmeUnderlyingCode", paste0("D2Acme", 1:20), paste0("D2SmicarAxis", 1:20),
               "ImmedCauseDeath", "Consq1", "Consq2", "Consq3", "OtherSignificantConditions",
               "IndustryLit", "OccupationLIt", "IndustryCode", "OccupationCode")

read_guardian <- function(yr) {
  yy     <- sprintf("%02d", yr %% 100)
  f_csv  <- file.path(cfg$dc_dir, yr, paste0("DeathCertificates", yy, ".csv"))
  f_xlsx <- file.path(cfg$dc_dir, yr, paste0("DeathCertificates", yy, ".xlsx"))
  if (file.exists(f_csv)) {
    d <- read_csv(f_csv, col_types = cols(.default = col_character()), na = "",
                  progress = FALSE, show_col_types = FALSE)
  } else if (file.exists(f_xlsx)) {
    d <- read_excel(f_xlsx, col_types = "text")
  } else {
    stop("Missing ", f_csv, " (and no .xlsx either)")
  }
  missing_vars <- setdiff(keep_vars, names(d))
  if (length(missing_vars) > 0) stop(yr, ": fields not in export: ", paste(missing_vars, collapse = ", "))
  d[keep_vars]
}
deaths_raw <- bind_rows(lapply(cfg$years, read_guardian))

# Text to numbers. suppressWarnings plays the role of SAS "input(x, ?? 8.)"
# in OHIs lines 378 and 381: a non-number quietly becomes missing.
deaths <- deaths_raw %>%
  mutate(across(everything(), str_trim)) %>%
  mutate(EventYear   = suppressWarnings(as.integer(EventYear)),
         NchsAge     = suppressWarnings(as.numeric(NchsAge)),
         NchsAgeUnit = suppressWarnings(as.integer(NchsAgeUnit)))

# DC template line 25, OHIs line 378: keep the requested years. This also
# drops the 5 ROSTER placeholder rows (EventYear 0) in the 2021 export.
deaths <- deaths %>% filter(EventYear %in% cfg$years)

# DC template line 28 (proc sort nodupkey by DeathCertificateId EventYear):
# one row per certificate. Yearly exports overlap by 53 to 66 late deaths
# that are also in the prior year's file; the first copy read is kept,
# which is the earlier file, the same as SAS.
deaths <- deaths %>% distinct(DeathCertificateId, EventYear, .keep_all = TRUE)
ids_in_two_years <- deaths %>% count(DeathCertificateId) %>% filter(n > 1) %>% nrow()   # QA: expect 0

# DC template line 68 and OHIs line 379: Nebraska residents.
if (cfg$ne_residents_only) {
  deaths <- deaths %>% filter(toupper(coalesce(ResidingStateNchs, "")) == "NE")
}

# OHIs lines 382 to 386 (same as DC template lines 70 to 75): age in years.
# Unit 1 years, 2 months, 3 weeks, 4 to 6 days/hours/minutes, 9 unknown;
# NchsAge 999 is unknown. trunc() is SAS int().
deaths <- deaths %>% mutate(age = case_when(
    NchsAge == 999      ~ NA_real_,
    NchsAgeUnit == 1    ~ NchsAge,
    NchsAgeUnit == 2    ~ trunc(NchsAge / 12),
    NchsAgeUnit == 3    ~ trunc(NchsAge / 52),
    NchsAgeUnit %in% 4:6 ~ 0,
    TRUE                ~ NA_real_))

# OHIs line 388 and format $sexf (line 96): M or 1 = M, F or 2 = F, else U.
# DC template line 103: MannerDeath S = suicide.
deaths <- deaths %>% mutate(
  sex1   = toupper(substr(coalesce(Sex, ""), 1, 1)),
  sex    = case_when(sex1 %in% c("M", "1") ~ "M", sex1 %in% c("F", "2") ~ "F", TRUE ~ "U"),
  manner = toupper(substr(coalesce(MannerDeath, ""), 1, 1))) %>%
  select(-sex1)

message("Deaths loaded: ", nrow(deaths), " residents, all ages, ", paste(range(cfg$years), collapse = "-"))

# ---------------------------------------------------------------------
# 2. FLAG OUTCOMES.
#    Code scan copies DC template lines 43 to 54: 41 fields (underlying
#    plus both multiple-cause axes), codes compressed of dots and spaces,
#    upper case, prefix match. Text scan copies lines 56 to 65: five
#    literal fields, case-insensitive substring search.
#    ICD ranges are spelled out code by code (dc-data-sources.md: the
#    template does not do ranges), so X60-X84 is X60, X61, ..., X84.
# ---------------------------------------------------------------------
cause_fields <- c("AcmeUnderlyingCode", paste0("D2Acme", 1:20), paste0("D2SmicarAxis", 1:20))
text_fields  <- c("ImmedCauseDeath", "Consq1", "Consq2", "Consq3", "OtherSignificantConditions")

# DC template line 45: code = upcase(compress(field, '. ')). One column per field.
code_mat <- as.matrix(deaths[cause_fields])
code_mat[is.na(code_mat)] <- ""
code_mat[] <- toupper(gsub("[. ]", "", code_mat))

# TRUE for a record if any of the given columns starts with any of the codes
# (DC template line 48: substr(code, 1, length(icd)) = icd).
any_field_starts <- function(mat, codes) {
  hit <- rep(FALSE, nrow(mat))
  for (j in seq_len(ncol(mat))) for (p in codes) hit <- hit | startsWith(mat[, j], p)
  hit
}
icd_list <- function(letter, from, to) sprintf("%s%02d", letter, from:to)   # icd_list("X", 60, 62) = X60 X61 X62

underlying <- code_mat[, 1]
u3 <- substr(underlying, 1, 3)
u4 <- substr(underlying, 1, 4)
multi_mat <- code_mat[, -1, drop = FALSE]      # D2Acme1-20 and D2SmicarAxis1-20 only

# The five text fields joined into one string per record (blank fields as "").
text_all <- paste(coalesce(deaths$ImmedCauseDeath, ""), coalesce(deaths$Consq1, ""), coalesce(deaths$Consq2, ""),
                  coalesce(deaths$Consq3, ""), coalesce(deaths$OtherSignificantConditions, ""), sep = " | ")
text_has <- function(pattern) str_detect(text_all, regex(pattern, ignore_case = TRUE))

drug_t_codes <- icd_list("T", 36, 50)          # T36-T50: poisoning by drugs and biologicals
opioid_t     <- c("T400", "T401", "T402", "T403", "T404", "T406")

deaths <- deaths %>% mutate(
  # Suicide: underlying X60 to X84, Y87.0, U03 (plan step 2; NEVDRS definition).
  # Legacy "combine data.sas" line 196 used "UO3" with a letter O; fixed here.
  suicide_icd    = u3 %in% icd_list("X", 60, 84) | u4 == "Y870" | u3 == "U03",
  suicide_manner = manner == "S",
  suicide        = suicide_icd,

  # SUDORS overdose (CDC dashboard case definition): underlying X40-X44
  # (unintentional) or Y10-Y14 (undetermined), OR literal cause text saying
  # overdose, toxicity, intoxication or drug poisoning.
  od_icd  = u3 %in% c(icd_list("X", 40, 44), icd_list("Y", 10, 14)),
  od_text = text_has("overdose|toxicity|intoxication|drug poison"),
  # Plan step 2: exclude carbon monoxide and alcohol-only text hits. Alcohol-
  # only = alcohol named, no drug word, and no T36-T50 drug code anywhere.
  od_text_co      = text_has("carbon monoxide|\\bCO\\b poison"),
  od_text_alcohol = text_has("alcohol|ethanol") &
                    !text_has("fentanyl|opioid|opiate|heroin|methamphetamine|amphetamine|cocaine|drug|medication|pill") &
                    !any_field_starts(code_mat, drug_t_codes),
  # SUDORS covers unintentional and undetermined intent only, so a text-only
  # hit on a suicide, homicide or natural death is not a case. HUMAN DECISION:
  # see docs/script-audit.md.
  od_text_case = od_text & !od_text_co & !od_text_alcohol & !manner %in% c("S", "H", "N"),
  overdose        = od_icd | od_text_case,
  od_text_only    = overdose & !od_icd,          # goes on the manual review list

  # Opioid involvement: T40.0-T40.4, T40.6 in any D2Acme or D2SmicarAxis
  # field (plan step 2; MA report p. 10).
  opioid_any      = any_field_starts(multi_mat, opioid_t),
  overdose_opioid = overdose & opioid_any,

  # Massachusetts all-intent opioid-related definition, for comparability only:
  # underlying X40-X49, X60-X69, X85-X90, Y10-Y19 or Y35.2, with an opioid T code.
  ma_opioid = opioid_any & (u3 %in% c(icd_list("X", 40, 49), icd_list("X", 60, 69),
                                      icd_list("X", 85, 90), icd_list("Y", 10, 19)) | u4 == "Y352")
)

# Data note: manner versus ICD disagreement (plan step 2), all ages.
manner_note <- deaths %>% count(suicide_icd, suicide_manner)

# By-year totals at all ages, for the plan section 5 comparison with the
# Vital Statistics and SUDORS sheets (those are all ages).
by_year_all_ages <- deaths %>% group_by(EventYear) %>%
  summarise(suicide = sum(suicide), overdose = sum(overdose), overdose_opioid = sum(overdose_opioid),
            ma_opioid = sum(ma_opioid), .groups = "drop")

# OHIs line 412: age 16 and over (the worker denominator).
n_all_ages <- nrow(deaths)
deaths <- deaths %>% filter(!is.na(age), age >= cfg$min_age)

cases <- deaths %>% filter(suicide | overdose | ma_opioid)
message("Cases aged ", cfg$min_age, "+: suicide ", sum(deaths$suicide), ", overdose ", sum(deaths$overdose),
        " (text only ", sum(deaths$od_text_only), "), opioid subset ", sum(deaths$overdose_opioid),
        ", MA all-intent opioid ", sum(deaths$ma_opioid))

# ---------------------------------------------------------------------
# 3. NIOCCS CODING of the usual industry and occupation text.
#    Call copied from the team's GET.R (lines 6 to 19): one GET per
#    record, i = industry text, o = occupation text, c = 2. Added here:
#    a cache keyed on the text pair so reruns make no calls, a retry, a
#    status check (the original had none), and blank pairs are not sent.
#    The cache keeps CDC's full JSON reply; fields are read from it below.
# ---------------------------------------------------------------------
cache_file <- file.path(cfg$cache_dir, "nioccs_cache.csv")
empty_cache <- tibble(IndustryLit = character(), OccupationLIt = character(),
                      status = character(), coded_on = character(), raw_json = character())
read_cache <- function() {
  if (!file.exists(cache_file)) return(empty_cache)
  # na = character(): a blank text stays "" so it still matches the key.
  read_csv(cache_file, col_types = cols(.default = col_character()), na = character(),
           progress = FALSE, show_col_types = FALSE)
}

nioccs_call <- function(industry, occupation) {
  for (attempt in 1:3) {
    r <- try(GET("https://wwwn.cdc.gov/nioccs/IOCode?",
                 query = list(i = industry, o = occupation, c = 2), timeout(30)), silent = TRUE)
    if (!inherits(r, "try-error") && status_code(r) == 200) return(content(r, as = "text", encoding = "UTF-8"))
    Sys.sleep(2 * attempt)
  }
  NA_character_
}

# Text pairs of the cases, blanks as "". A pair with both texts blank is
# "Not coded" and is never sent.
cases <- cases %>% mutate(IndustryLit = coalesce(IndustryLit, ""), OccupationLIt = coalesce(OccupationLIt, ""))
cache <- read_cache()
pairs_to_code <- cases %>% distinct(IndustryLit, OccupationLIt) %>%
  filter(IndustryLit != "" | OccupationLIt != "") %>%
  anti_join(cache %>% filter(status == "OK"), by = c("IndustryLit", "OccupationLIt"))

if (cfg$run_nioccs && nrow(pairs_to_code) > 0) {
  message("NIOCCS: coding ", nrow(pairs_to_code), " new text pairs")
  for (i in seq_len(nrow(pairs_to_code))) {
    raw <- nioccs_call(pairs_to_code$IndustryLit[i], pairs_to_code$OccupationLIt[i])
    row <- tibble(IndustryLit = pairs_to_code$IndustryLit[i], OccupationLIt = pairs_to_code$OccupationLIt[i],
                  status = ifelse(is.na(raw), "FAILED", "OK"), coded_on = as.character(Sys.Date()),
                  raw_json = coalesce(raw, ""))
    # Append each reply as it arrives, so a crash loses nothing.
    write_csv(row, cache_file, append = file.exists(cache_file), na = "")
    Sys.sleep(0.2)
  }
  cache <- read_cache()
} else if (nrow(pairs_to_code) > 0) {
  message("NIOCCS: ", nrow(pairs_to_code), " text pairs are not in the cache and run_nioccs is FALSE; they will show as Not coded")
}
cache <- cache %>% filter(status == "OK") %>% distinct(IndustryLit, OccupationLIt, .keep_all = TRUE)

# Read fields from one JSON reply. The field names are the ones the team's
# scripts use (nioccs.R lines 51 and 59, nioccs_suicide.R lines 64, 68, 71,
# 73): Industry$NAICSCode, Industry$CensusIndustryTitle, Occupation$SOCCode,
# Occupation$SOCTitle, Occupation$CensusOccupationTitle. The team also
# widened Industry and Occupation side by side without a name clash, so
# the two halves do not share field names; a bare "Score" in both is unlikely.
get_field <- function(part, name) {
  if (is.na(name) || is.null(part) || is.null(part[[name]]) || length(part[[name]]) == 0) return("")
  as.character(part[[name]][[1]])
}
parse_nioccs <- function(raw) {
  j <- tryCatch(fromJSON(raw, simplifyVector = FALSE), error = function(e) list())
  ind <- j$Industry; occ <- j$Occupation
  if (!is.null(ind) && is.null(names(ind)) && length(ind) > 0) ind <- ind[[1]]   # reply wrapped in a one-element array
  if (!is.null(occ) && is.null(names(occ)) && length(occ) > 0) occ <- occ[[1]]
  tibble(NAICSCode = get_field(ind, "NAICSCode"), CensusIndustryTitle = get_field(ind, "CensusIndustryTitle"),
         ind_conf = get_field(ind, cfg$nioccs_ind_conf_field),
         SOCCode = get_field(occ, "SOCCode"), SOCTitle = get_field(occ, "SOCTitle"),
         CensusOccupationTitle = get_field(occ, "CensusOccupationTitle"),
         occ_conf = get_field(occ, cfg$nioccs_occ_conf_field))
}
coded <- bind_rows(lapply(cache$raw_json, parse_nioccs))
if (nrow(coded) == 0) coded <- parse_nioccs("{}")[0, ]
coded <- bind_cols(cache %>% select(IndustryLit, OccupationLIt), coded)

cases <- cases %>% left_join(coded, by = c("IndustryLit", "OccupationLIt")) %>%
  mutate(across(c(NAICSCode, SOCCode, ind_conf, occ_conf), ~ coalesce(.x, "")))

# Roll-ups. NAICS sector with 31-33, 44-45, 48-49 combined (nioccs_suicide.R
# lines 73 to 82, MA report, OHIs format "sector" line 80). SOC major group
# = first two digits (nioccs_suicide.R line 71).
naics_sector <- function(code) {
  s <- substr(code, 1, 2)
  case_when(s %in% c("31", "32", "33") ~ "31-33", s %in% c("44", "45") ~ "44-45",
            s %in% c("48", "49") ~ "48-49", TRUE ~ s)
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
  "51" = "Production", "53" = "Transportation and material moving")   # 22 civilian groups; 55 = military
nonrate_groups <- c("Military", "Not in workforce", "Not coded")

# Non-rate groups assigned BEFORE anything is dropped (plan step 4).
#  Military: NAICS 928110 or a military SOC (55-xxxx). ACS counts civilians only.
#  Not in workforce: the text field is just a non-worker word (e.g. "RETIRED"),
#    or NIOCCS gave no usable code and the text has a non-worker word.
#  Not coded: everything else without a usable code (blank or uncodable text,
#    NIOCCS failure, or a code outside the 20 sectors / 22 groups).
nonwork_words <- "homemaker|housewife|house wife|student|retired|unemployed|never worked|disabled|disability|child"
nonwork_only  <- regex(paste0("^(", nonwork_words, ")$"), ignore_case = TRUE)
nonwork_any   <- regex(paste0("\\b(", nonwork_words, ")\\b"), ignore_case = TRUE)

cases <- cases %>% mutate(
  sector   = naics_sector(NAICSCode),
  socgrp   = substr(SOCCode, 1, 2),
  military = startsWith(NAICSCode, "928110") | socgrp == "55",
  ind_text_nonwork = str_detect(IndustryLit, nonwork_only),
  occ_text_nonwork = str_detect(OccupationLIt, nonwork_only),
  any_text_nonwork = str_detect(paste(IndustryLit, OccupationLIt), nonwork_any),
  ind_group = case_when(
    military                        ~ "Military",
    ind_text_nonwork                ~ "Not in workforce",
    sector %in% names(sector_labels) ~ sector,
    any_text_nonwork                ~ "Not in workforce",
    TRUE                            ~ "Not coded"),
  occ_group = case_when(
    military                        ~ "Military",
    occ_text_nonwork                ~ "Not in workforce",
    socgrp %in% names(soc_labels)   ~ socgrp,
    any_text_nonwork                ~ "Not in workforce",
    TRUE                            ~ "Not coded"))
  # Deliberately NOT recoding SOC 11-9013 farm managers into group 45
  # (nioccs_suicide.R line 68 did). ACS keeps them in Management; the
  # numerator must match the denominator.

# Manual review list (plan step 3): uncoded, low confidence (once the field
# name is known), text-only overdose cases, and every case in the top three
# industry sectors for suicide and for overdose.
top3 <- function(flag) cases %>% filter(.data[[flag]], !ind_group %in% nonrate_groups) %>%
  count(ind_group, sort = TRUE) %>% head(3) %>% pull(ind_group)
top_sectors <- union(top3("suicide"), top3("overdose"))
low_conf <- function(x) !is.na(cfg$nioccs_conf_min) & suppressWarnings(as.numeric(x)) < cfg$nioccs_conf_min
cases <- cases %>% mutate(review_reason = case_when(
  ind_group == "Not coded" | occ_group == "Not coded" ~ "not coded",
  coalesce(low_conf(ind_conf) | low_conf(occ_conf), FALSE) ~ "low confidence",
  od_text_only                                          ~ "overdose by text only",
  ind_group %in% top_sectors                            ~ "top-three sector",
  TRUE                                                  ~ ""))

review_list <- cases %>% filter(review_reason != "") %>%
  select(DeathCertificateId, EventYear, review_reason, suicide, overdose, od_text_only, IndustryLit, OccupationLIt,
         NAICSCode, CensusIndustryTitle, SOCCode, SOCTitle, ind_conf, occ_conf, ind_group, occ_group)
write_csv(review_list, file.path(cfg$cache_dir, "manual_review_list.csv"), na = "")   # record level: Cache only

# After review, save decisions as Cache/manual_review_decisions.csv with
# columns DeathCertificateId, ind_group, occ_group, note. A blank group
# keeps the NIOCCS result. Allowed values: a sector or SOC group code, or
# Military / Not in workforce / Not coded.
dec_file <- file.path(cfg$cache_dir, "manual_review_decisions.csv")
if (file.exists(dec_file)) {
  dec <- read_csv(dec_file, col_types = cols(.default = col_character()), na = "", show_col_types = FALSE) %>%
    distinct(DeathCertificateId, .keep_all = TRUE)
  bad <- setdiff(na.omit(c(dec$ind_group, dec$occ_group)), c(names(sector_labels), names(soc_labels), nonrate_groups))
  if (length(bad) > 0) stop("manual_review_decisions.csv has unknown group values: ", paste(bad, collapse = ", "))
  cases <- cases %>%
    left_join(dec %>% select(DeathCertificateId, ind_dec = ind_group, occ_dec = occ_group), by = "DeathCertificateId") %>%
    mutate(ind_group = coalesce(ind_dec, ind_group), occ_group = coalesce(occ_dec, occ_group)) %>%
    select(-ind_dec, -occ_dec)
  message("Applied ", nrow(dec), " manual review decisions")
}

# ---------------------------------------------------------------------
# 4. CROSS-CHECK against the certificate's own IndustryCode (plan step 5).
#    OHIs lines 392 to 393: IndustryCode is the 4-digit Census code with
#    the trailing digit dropped; multiply by 10 and look it up in format
#    cind2sec (OHIs lines 87 to 91). The ranges below are that format.
#    One deliberate difference: OHIs has 7071-7190 for real estate, so
#    code 707 (x10 = 7070) falls to UNK there. 7070 is used here; the SAS
#    line needs the same fix. Occupation cross-check: not done (no SAS rule
#    exists for Census occupation code ranges yet).
# ---------------------------------------------------------------------
cind2sec <- tribble(~lo, ~hi, ~sector_cert,
   170,  290, "11",     370,  490, "21",     570,  690, "22",     770,  770, "23",
  1070, 3990, "31-33", 4070, 4590, "42",    4670, 5790, "44-45", 6070, 6390, "48-49",
  6470, 6780, "51",    6870, 6990, "52",    7070, 7190, "53",    7270, 7490, "54",
  7570, 7570, "55",    7580, 7790, "56",    7860, 7890, "61",    7970, 8470, "62",
  8560, 8590, "71",    8660, 8690, "72",    8770, 9290, "81",    9370, 9590, "92",
  9670, 9870, "MIL")
cert_sector <- function(code) {
  census4 <- suppressWarnings(as.numeric(code)) * 10
  out <- rep("UNK", length(census4))
  for (i in seq_len(nrow(cind2sec))) {
    out[!is.na(census4) & census4 >= cind2sec$lo[i] & census4 <= cind2sec$hi[i]] <- cind2sec$sector_cert[i]
  }
  out
}
cases <- cases %>% mutate(sector_cert = cert_sector(IndustryCode))
coding_agreement <- cases %>%
  filter(!ind_group %in% nonrate_groups, !sector_cert %in% c("UNK", "MIL")) %>%
  group_by(ind_group) %>%
  summarise(n_both_coded = n(), n_agree = sum(ind_group == sector_cert), .groups = "drop") %>%
  mutate(pct_agree = round(100 * n_agree / n_both_coded, 1))

# ---------------------------------------------------------------------
# 5. ACS DENOMINATORS. C24030 sex by industry, C24010 sex by occupation,
#    civilian employed 16+, Nebraska, 5-year 2020-2024.
#    Rows are matched by their LABEL TEXT, not by variable number. Only
#    leaf rows are used (a row with no rows under it), so a parent such as
#    "Transportation and warehousing, and utilities:" is never added on
#    top of its children. The script stops if any leaf is not in the map,
#    or if the mapped leaves do not add up to the table total.
#    Worker-years = estimate x number of years (docs/acs-denominator-spec.md).
# ---------------------------------------------------------------------
acs_files <- file.path(cfg$acs_dir, sprintf("acs_acs5_%d_%s_NE.csv", cfg$acs_year, c("C24030", "C24010")))
if (all(file.exists(acs_files))) {
  # Saved by scripts/fetch_acs_denominators.py: variable ends in E, e.g. C24030_001E.
  acs <- bind_rows(lapply(acs_files, read_csv, col_types = cols(.default = col_character()), show_col_types = FALSE)) %>%
    transmute(variable = str_remove(variable, "E$"), label,
              estimate = as.numeric(estimate), moe = as.numeric(moe))
} else {
  if (!requireNamespace("tidycensus", quietly = TRUE)) stop("ACS CSVs not found in ", cfg$acs_dir, " and tidycensus is not installed")
  census_key <- Sys.getenv("CENSUS_API_KEY")
  if (!nzchar(census_key)) stop("Set CENSUS_API_KEY in the environment (never in this file)")
  vars <- tidycensus::load_variables(cfg$acs_year, "acs5", cache = TRUE) %>%
    filter(str_detect(name, "^C24030_|^C24010_")) %>% select(name, label)
  acs <- tidycensus::get_acs(geography = "state", state = "NE", variables = vars$name,
                             year = cfg$acs_year, survey = "acs5", key = census_key) %>%
    left_join(vars, by = c("variable" = "name")) %>%
    select(variable, label, estimate, moe)
}

# Label "Estimate!!Total:!!Male:!!Construction" -> sex M, leaf name "Construction".
acs <- acs %>% mutate(
  table     = substr(variable, 1, 6),
  label     = str_remove(label, "^Estimate!!"),
  sex       = case_when(str_detect(label, "!!Male:?(!!|$)") ~ "M",
                        str_detect(label, "!!Female:?(!!|$)") ~ "F", TRUE ~ "T"),
  leaf_name = str_remove(str_extract(label, "[^!]+$"), ":$"))
acs$is_leaf <- TRUE
for (i in seq_len(nrow(acs))) {
  same_table <- acs$label[acs$table == acs$table[i]]
  if (any(startsWith(same_table, paste0(acs$label[i], "!!")))) acs$is_leaf[i] <- FALSE
}

# Industry: C24030 leaf names to NAICS sectors. UNVERIFIED against the live
# Census API in the 2026-09-28 audit (api.census.gov was not reachable); the
# names are the 2019-onward C24030 labels as recalled. If any is wrong, map_acs()
# below stops and names the leaf, so nothing is silently dropped or doubled.
# Row-by-row status is in docs/script-audit.md. The parent rows (Agriculture ... and
# mining:, Transportation ... and utilities:, Finance ... and leasing:,
# Professional ... waste management services:, Educational services, and
# health care ...:, Arts ... food services:) are not leaves and are not listed.
ind_map <- tribble(~leaf_name, ~group,
  "Agriculture, forestry, fishing and hunting",                  "11",
  "Mining, quarrying, and oil and gas extraction",               "21",
  "Construction",                                                "23",
  "Manufacturing",                                               "31-33",
  "Wholesale trade",                                             "42",
  "Retail trade",                                                "44-45",
  "Transportation and warehousing",                              "48-49",
  "Utilities",                                                   "22",
  "Information",                                                 "51",
  "Finance and insurance",                                       "52",
  "Real estate and rental and leasing",                          "53",
  "Professional, scientific, and technical services",            "54",
  "Management of companies and enterprises",                     "55",
  "Administrative and support and waste management services",    "56",
  "Educational services",                                        "61",
  "Health care and social assistance",                           "62",
  "Arts, entertainment, and recreation",                         "71",
  "Accommodation and food services",                             "72",
  "Other services, except public administration",                "81",
  "Public administration",                                       "92")

# Occupation: C24010 leaf names to SOC major groups. UNVERIFIED against the
# live API, same as above; least certain punctuation: "Educational
# instruction, and library occupations" and the two protective service leaves.
# Three SOC groups are
# split in two in ACS and summed here: 29 (diagnosing/treating + technologists),
# 33 (firefighting + law enforcement), 53 (transportation + material moving).
occ_map <- tribble(~leaf_name, ~group,
  "Management occupations",                                      "11",
  "Business and financial operations occupations",               "13",
  "Computer and mathematical occupations",                       "15",
  "Architecture and engineering occupations",                    "17",
  "Life, physical, and social science occupations",              "19",
  "Community and social service occupations",                    "21",
  "Legal occupations",                                           "23",
  "Educational instruction, and library occupations",            "25",
  "Arts, design, entertainment, sports, and media occupations",  "27",
  "Health diagnosing and treating practitioners and other technical occupations", "29",
  "Health technologists and technicians",                        "29",
  "Healthcare support occupations",                              "31",
  "Firefighting and prevention, and other protective service workers including supervisors", "33",
  "Law enforcement workers including supervisors",               "33",
  "Food preparation and serving related occupations",            "35",
  "Building and grounds cleaning and maintenance occupations",   "37",
  "Personal care and service occupations",                       "39",
  "Sales and related occupations",                               "41",
  "Office and administrative support occupations",               "43",
  "Farming, fishing, and forestry occupations",                  "45",
  "Construction and extraction occupations",                     "47",
  "Installation, maintenance, and repair occupations",           "49",
  "Production occupations",                                      "51",
  "Transportation occupations",                                  "53",
  "Material moving occupations",                                 "53")

# Map one table's male and female leaves; stop on anything unexpected.
map_acs <- function(tab_id, map, n_groups) {
  leaves <- acs %>% filter(table == tab_id, is_leaf, sex != "T") %>% left_join(map, by = "leaf_name")
  unmapped <- unique(leaves$leaf_name[is.na(leaves$group)])
  if (length(unmapped) > 0) stop(tab_id, " leaf rows not in the map: ", paste(unmapped, collapse = " | "))
  if (n_distinct(leaves$group) != n_groups) stop(tab_id, ": expected ", n_groups, " groups, found ", n_distinct(leaves$group))
  total <- acs$estimate[acs$variable == paste0(tab_id, "_001")]
  if (abs(sum(leaves$estimate) - total) > 0.005 * total) stop(tab_id, ": mapped leaves do not add up to the table total")
  leaves %>% group_by(group, sex) %>%
    summarise(workers = sum(estimate), workers_moe90 = sqrt(sum(moe^2)), .groups = "drop")
}
den_ind <- map_acs("C24030", ind_map, 20)
den_occ <- map_acs("C24010", occ_map, 22)

acs_total_ind <- acs$estimate[acs$variable == "C24030_001"]
acs_total_occ <- acs$estimate[acs$variable == "C24010_001"]

# Add sex T (male + female) for each group, and an "All workers" row per sex.
# MOE of a sum: square root of the sum of squared MOEs (Census approximation).
add_totals <- function(den) {
  both_sexes  <- den %>% group_by(group) %>% summarise(sex = "T", workers = sum(workers), workers_moe90 = sqrt(sum(workers_moe90^2)), .groups = "drop")
  den <- bind_rows(den, both_sexes)
  all_workers <- den %>% group_by(sex) %>% summarise(group = "All workers", workers = sum(workers), workers_moe90 = sqrt(sum(workers_moe90^2)), .groups = "drop")
  bind_rows(den, all_workers)
}
den_ind <- add_totals(den_ind)
den_occ <- add_totals(den_occ)

# ---------------------------------------------------------------------
# 6. RATES. deaths / (workers x years) x 100,000. Exact Poisson 95% CI on
#    the count (MA report p. 10). Rate ratio vs all workers with a
#    log-normal CI. Crude only; no age adjustment by sector (plan step 7).
# ---------------------------------------------------------------------
# Exact Poisson limits for a count k (Garwood): chi-square with 2k and 2k+2 df.
pois_lo <- function(k) ifelse(k == 0, 0, qchisq(0.025, 2 * k) / 2)
pois_hi <- function(k) qchisq(0.975, 2 * (k + 1)) / 2

build_table <- function(outcome_col, group_col, den, group_labels, years) {
  cs <- cases %>% filter(.data[[outcome_col]], EventYear %in% years) %>% mutate(group = .data[[group_col]])
  workers_only <- cs %>% filter(!group %in% nonrate_groups)
  counts <- bind_rows(
    cs %>% count(group, sex, name = "deaths"),                                       # each group by sex
    cs %>% count(group, name = "deaths") %>% mutate(sex = "T"),                     # each group, both sexes
    workers_only %>% count(sex, name = "deaths") %>% mutate(group = "All workers"), # all workers by sex
    tibble(group = "All workers", sex = "T", deaths = nrow(workers_only)))          # all workers
  n_years <- length(years)

  tab <- den %>% full_join(counts, by = c("group", "sex")) %>%
    mutate(deaths       = coalesce(deaths, 0L),
           worker_years = workers * n_years,
           rate         = deaths / worker_years * 1e5,
           rate_lo      = pois_lo(deaths) / worker_years * 1e5,
           rate_hi      = pois_hi(deaths) / worker_years * 1e5)

  # Percent of all deaths of that sex (every group row counts, the All workers row does not).
  tab <- tab %>% group_by(sex) %>%
    mutate(pct_of_all_deaths = 100 * deaths / sum(deaths[group != "All workers"])) %>% ungroup()

  # Rate ratio vs the All workers rate of the same sex. The CI treats the two
  # counts as independent (the sector is part of All workers, so it is
  # slightly wide). No CI when deaths = 0.
  ref <- tab %>% filter(group == "All workers") %>% select(sex, ref_deaths = deaths, ref_rate = rate)
  tab <- tab %>% left_join(ref, by = "sex") %>%
    mutate(rr    = rate / ref_rate,
           rr_se = ifelse(deaths > 0, sqrt(1 / deaths + 1 / ref_deaths), NA_real_),
           rr_lo = exp(log(rr) - 1.96 * rr_se),
           rr_hi = exp(log(rr) + 1.96 * rr_se),
           label = coalesce(unname(group_labels[group]), group),
           outcome = outcome_col,
           years = paste(range(years), collapse = "-")) %>%
    select(outcome, years, group, label, sex, deaths, pct_of_all_deaths, workers, workers_moe90,
           worker_years, rate, rate_lo, rate_hi, rr, rr_lo, rr_hi) %>%
    arrange(sex, group)
  tab
}

pooled <- cfg$years
check_yrs <- 2020:2021
tables <- list(
  suicide_ind  = build_table("suicide", "ind_group", den_ind, sector_labels, pooled),
  suicide_occ  = build_table("suicide", "occ_group", den_occ, soc_labels, pooled),
  overdose_ind = build_table("overdose", "ind_group", den_ind, sector_labels, pooled),
  overdose_occ = build_table("overdose", "occ_group", den_occ, soc_labels, pooled),
  opioid_ind   = build_table("overdose_opioid", "ind_group", den_ind, sector_labels, pooled),
  opioid_occ   = build_table("overdose_opioid", "occ_group", den_occ, soc_labels, pooled),
  ma_opioid_ind = build_table("ma_opioid", "ind_group", den_ind, sector_labels, pooled),
  # NEVDRS reconciliation cut: 2020-2021 only. The ACS 2020-2024 window is used
  # as the denominator (x 2 years) because no cleaner 2-year denominator exists;
  # the point of this table is the COUNTS (84 / 72 / 55), not the rate.
  suicide_ind_2020_2021 = build_table("suicide", "ind_group", den_ind, sector_labels, check_yrs))

# ---------------------------------------------------------------------
# 7. NO SUPPRESSION. Full counts and rates everywhere, on purpose.
#    Suppression is applied only at the moment something goes to the
#    public, in a separate step, never inside the analysis. Non-rate rows
#    (military, not in workforce, not coded) keep counts and get no rate.
# ---------------------------------------------------------------------
tables <- lapply(tables, function(tab) tab %>%
  mutate(across(c(workers, workers_moe90, worker_years, rate, rate_lo, rate_hi, rr, rr_lo, rr_hi),
                ~ ifelse(group %in% nonrate_groups, NA, .x))))
tables_raw <- tables

# ---------------------------------------------------------------------
# 8. QA CHECKS (plan section 5). Printed; the run is not done until all pass.
#    Written to Cache alongside the review list.
# ---------------------------------------------------------------------
by_year_16plus <- deaths %>% group_by(EventYear) %>%
  summarise(suicide = sum(suicide), overdose = sum(overdose), overdose_opioid = sum(overdose_opioid), .groups = "drop")

# Plan: sector counts sum to the total plus not-in-workforce plus not-coded
# plus military, exactly. The total is counted straight from the cases.
sum_check <- function(tab, outcome_col, years) {
  t <- tab %>% filter(sex == "T")
  c(cases_total    = sum(cases[[outcome_col]] & cases$EventYear %in% years),
    sum_of_rows    = sum(t$deaths[t$group != "All workers"]),
    workers_plus_nonrate = sum(t$deaths[t$group %in% c("All workers", nonrate_groups)]))
}
table_outcome <- c(suicide_ind = "suicide", suicide_occ = "suicide", overdose_ind = "overdose", overdose_occ = "overdose",
                   opioid_ind = "overdose_opioid", opioid_occ = "overdose_opioid", ma_opioid_ind = "ma_opioid",
                   suicide_ind_2020_2021 = "suicide")
sum_checks <- sapply(names(tables_raw), function(nm)
  sum_check(tables_raw[[nm]], table_outcome[[nm]], if (nm == "suicide_ind_2020_2021") check_yrs else pooled))

qa <- list(
  deaths_by_year_all_ages_residents = by_year_all_ages,
  deaths_by_year_age16plus_residents = by_year_16plus,
  residents_all_ages_vs_16plus = c(all_ages = n_all_ages, aged_16_plus = nrow(deaths)),
  certificate_ids_in_two_event_years = ids_in_two_years,
  manner_vs_icd_suicide_all_ages = manner_note,
  overdose_text_only_cases_16plus = sum(deaths$od_text_only),
  sector_sums_equal_total = sum_checks,
  all_sums_match = all(sum_checks[1, ] == sum_checks[2, ] & sum_checks[1, ] == sum_checks[3, ]),
  acs_industry_total_vs_mapped = c(published_C24030_001 = acs_total_ind,
                                   mapped_sectors_T = den_ind$workers[den_ind$group == "All workers" & den_ind$sex == "T"]),
  acs_occupation_total_vs_mapped = c(published_C24010_001 = acs_total_occ,
                                     mapped_groups_T = den_occ$workers[den_occ$group == "All workers" & den_occ$sex == "T"]),
  text_pairs_not_yet_coded = nrow(pairs_to_code),
  coding_agreement_nioccs_vs_certificate = coding_agreement,
  records_needing_review = nrow(review_list),
  nevdrs_reconciliation_2020_2021 = tables_raw$suicide_ind_2020_2021 %>%
    filter(sex == "T", group %in% c("Not in workforce", "23", "31-33")) %>%
    select(group, label, deaths) %>%
    mutate(nevdrs_sheet = c("Not in workforce" = 84, "23" = 72, "31-33" = 55)[group])
)
print(qa)
if (!qa$all_sums_match) warning("Sector counts do not add up to the case totals; see qa$sector_sums_equal_total")
message("Reference totals to compare by hand (all ages): NEVDRS dashboard suicides 2020 289, 2021 305, 2022 284; ",
        "SUDORS 2021-2022 combined 366. Compare them with deaths_by_year_all_ages_residents.")

# ---------------------------------------------------------------------
# 9. WRITE. Output gets the aggregate tables (full counts) and a methods note.
#    QA counts go to Cache. No record-level output leaves Cache.
# ---------------------------------------------------------------------
stamp <- format(Sys.Date(), "%Y%m%d")
for (nm in names(tables)) write_csv(tables[[nm]], file.path(cfg$out_dir, sprintf("%s_%s.csv", nm, stamp)), na = "")
write_csv(bind_rows(tables), file.path(cfg$out_dir, sprintf("io_death_rates_all_%s.csv", stamp)), na = "")
capture.output(print(qa), file = file.path(cfg$cache_dir, sprintf("qa_checks_%s.txt", stamp)))
writeLines(c(sprintf("io_death_rates.R run %s", Sys.time()),
             sprintf("Years %s", paste(cfg$years, collapse = " ")),
             sprintf("ACS %d 5-year, C24030 and C24010, Nebraska, civilian employed 16+; worker-years = estimate x years", cfg$acs_year),
             "Suicide: underlying X60-X84, Y87.0, U03.",
             "Overdose: SUDORS (underlying X40-X44, Y10-Y14, or overdose text on a death not ruled suicide, homicide or natural).",
             "Opioid: T40.0-T40.4, T40.6 in any multiple-cause field. MA all-intent opioid as a separate table.",
             "Residents, age 16+, one row per certificate and event year. NIOCCS coding of usual industry and occupation text."),
             "No suppression applied. Apply the DHHS floor only when a table is released to the public."),
           file.path(cfg$out_dir, sprintf("methods_%s.txt", stamp)))
message("Done. Tables in ", cfg$out_dir, "; QA and review list in ", cfg$cache_dir)
