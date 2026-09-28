# io_death_rates.R
# Nebraska death rates by industry and occupation, residents aged 16+.
# One outcome per row of the OUTCOMES table below; add a row to add an indicator.
#
# Steps: 1 load deaths  2 flag outcomes  3 code industry/occupation (NIOCCS)
#        4 ACS worker denominators  5 rates  6 checks and write
# Death-certificate rules copy the team's SAS (dc_condition_surveillance.sas,
# subindicators.sas); the rate method copies the Massachusetts DPH report.
# No suppression here. Nothing record-level leaves the Cache folder.

suppressPackageStartupMessages({ library(readxl); library(dplyr); library(stringr); library(httr); library(jsonlite); library(readr) })

# ---- SETTINGS ---------------------------------------------------------
here <- tryCatch(dirname(normalizePath(sys.frame(1)$ofile)), error = function(e) getwd())
cfg <- list(
  years      = 2020:2024,
  dc_dir     = "K:/Occupational Health Grant/data/dc",   # {YYYY}/DeathCertificates{YY}.csv or .xlsx
  out_dir    = file.path(here, "Output"),
  cache_dir  = file.path(here, "Cache"),
  acs_year   = 2024,     # ACS 5-year ending year
  min_age    = 16,
  run_nioccs = FALSE     # TRUE sends industry/occupation text to CDC NIOCCS (needs data use OK)
)
if (!is.null(getOption("io_death_rates.test_cfg"))) cfg <- modifyList(cfg, getOption("io_death_rates.test_cfg"))
for (d in c(cfg$out_dir, cfg$cache_dir)) dir.create(d, showWarnings = FALSE, recursive = TRUE)

# ---- OUTCOMES: one row each. Codes are ICD-10 prefixes; ranges allowed. ---
#  underlying   : matched against the underlying cause only
#  anymention   : matched against all 40 multiple-cause fields
#  need_mention : TRUE = a record must match BOTH the underlying/text rule AND anymention
#  text         : regex searched in the five cause-of-death text fields
#  text_needs   : a second regex the text must also contain (for overdose: a drug word, so "ethanol intoxication" is not one)
#  not_manner   : manner codes that disqualify a text-only match (S H N = suicide, homicide, natural)
#  field_rule   : "Field=Value" on any certificate field
drug_words <- "drug|fentanyl|opioid|opiate|heroin|methamphetamine|amphetamine|cocaine|oxycodone|methadone|medication|pill|polysubstance"
outcomes <- tribble(
  ~outcome,          ~underlying,        ~anymention,                     ~need_mention, ~text,                                        ~text_needs, ~not_manner, ~field_rule,
  "suicide",         "X60-X84 Y870 U03", "",                              FALSE,         "",                                           "",          "",          "",
  "overdose",        "X40-X44 Y10-Y14",  "",                              FALSE,         "overdose|toxicity|intoxication|poisoning",   drug_words,  "S H N",     "",
  "overdose_opioid", "X40-X44 Y10-Y14",  "T400 T401 T402 T403 T404 T406", TRUE,          "overdose|toxicity|intoxication|poisoning",   drug_words,  "S H N",     "",
  "opioid_ma_def",   "X40-X49 X60-X69 X85-X90 Y10-Y19 Y352", "T400 T401 T402 T403 T404 T406", TRUE, "",         "",          "",          "",
  "pneumoconiosis",  "",                 "J60 J61 J62 J63 J64 J65 J66",   FALSE,         "",                                           "",          "",          "",
  "injury_at_work",  "",                 "",                              FALSE,         "",                                           "",          "",          "InjuryAtWork=Y"
)
text_exclude <- "carbon monoxide"      # a text match naming this is never an overdose

# ---- 1. LOAD DEATHS ---------------------------------------------------
fields <- c("DeathCertificateId", "EventYear", "DateOfDeath", "DateOfBirth", "ResidingStateNchs", "NchsAge", "NchsAgeUnit",
            "Sex", "MannerDeath", "InjuryAtWork", "AcmeUnderlyingCode", paste0("D2Acme", 1:20), paste0("D2SmicarAxis", 1:20),
            "ImmedCauseDeath", "Consq1", "Consq2", "Consq3", "OtherSignificantConditions", "IndustryLit", "OccupationLIt")
read_year <- function(yr) {
  f <- file.path(cfg$dc_dir, yr, sprintf("DeathCertificates%02d", yr %% 100))
  d <- if (file.exists(paste0(f, ".csv"))) read_csv(paste0(f, ".csv"), col_types = cols(.default = "c"), na = "", show_col_types = FALSE)
       else if (file.exists(paste0(f, ".xlsx"))) read_excel(paste0(f, ".xlsx"), col_types = "text")
       else stop("No DeathCertificates file for ", yr)
  for (v in setdiff(fields, names(d))) d[[v]] <- NA_character_
  d[fields]
}
# Dates arrive as text or as Excel serial numbers (45291 = 2023-12-31).
to_date <- function(x) {
  x <- str_trim(coalesce(x, "")); n <- suppressWarnings(as.numeric(x))
  out <- as.Date(ifelse(!is.na(n) & n >= 1 & n < 80000, n, NA), origin = "1899-12-30")
  for (f in c("%m/%d/%Y", "%Y-%m-%d", "%m/%d/%Y %H:%M", "%Y-%m-%d %H:%M:%S")) {
    todo <- is.na(out) & x != ""; if (!any(todo)) break
    out[todo] <- suppressWarnings(as.Date(x[todo], format = f))
  }
  out
}
deaths <- bind_rows(lapply(cfg$years, read_year)) %>%
  mutate(across(everything(), str_trim),
         dod = to_date(DateOfDeath), dob = to_date(DateOfBirth),
         year = coalesce(as.integer(format(dod, "%Y")), suppressWarnings(as.integer(EventYear))),
         age_dob  = trunc(as.numeric(dod - dob) / 365.25),
         age_nchs = suppressWarnings(as.numeric(NchsAge)),          # SAS route: NchsAge with unit 1 = years
         age = if (mean(age_nchs >= 16, na.rm = TRUE) > 0.5) ifelse(NchsAgeUnit == "1", age_nchs, 0) else age_dob,
         sex = case_when(substr(toupper(Sex), 1, 1) %in% c("M", "1") ~ "M", substr(toupper(Sex), 1, 1) %in% c("F", "2") ~ "F", TRUE ~ "U"),
         manner = substr(toupper(coalesce(MannerDeath, "")), 1, 1)) %>%
  filter(year %in% cfg$years) %>%                          # keep requested years
  distinct(DeathCertificateId, year, .keep_all = TRUE) %>%  # one row per certificate (exports overlap)
  filter(toupper(coalesce(ResidingStateNchs, "")) == "NE") # Nebraska residents
n_all_ages <- nrow(deaths)
deaths <- deaths %>% filter(!is.na(age), age >= cfg$min_age)
message("Deaths: ", n_all_ages, " residents, ", nrow(deaths), " aged ", cfg$min_age, "+; years ", paste(sort(unique(deaths$year)), collapse = " "))

# ---- 2. FLAG OUTCOMES -------------------------------------------------
expand <- function(s) unlist(lapply(strsplit(str_trim(s), " +")[[1]], function(tok) {
  if (tok == "") return(character()); m <- str_match(tok, "^([A-Z])(\\d+)-[A-Z](\\d+)$")
  if (is.na(m[1])) tok else sprintf("%s%02d", m[2], as.integer(m[3]):as.integer(m[4])) }))
clean <- function(x) { x[is.na(x)] <- ""; toupper(gsub("[. ]", "", x)) }
under <- clean(deaths$AcmeUnderlyingCode)
mention <- as.matrix(deaths[c(paste0("D2Acme", 1:20), paste0("D2SmicarAxis", 1:20))]); mention[] <- clean(mention)
text <- do.call(paste, c(deaths[c("ImmedCauseDeath", "Consq1", "Consq2", "Consq3", "OtherSignificantConditions")], sep = " | "))
starts_any <- function(x, prefixes) Reduce(`|`, lapply(prefixes, function(p) startsWith(x, p)), rep(FALSE, length(x)))
mention_any <- function(prefixes) if (!length(prefixes)) rep(FALSE, nrow(deaths)) else Reduce(`|`, lapply(seq_len(ncol(mention)), function(j) starts_any(mention[, j], prefixes)))

manner_in <- function(m, codes) if (codes == "") rep(FALSE, length(m)) else m %in% strsplit(codes, " ")[[1]]

for (i in seq_len(nrow(outcomes))) {
  o <- outcomes[i, ]
  hit_under <- if (o$underlying != "") starts_any(under, expand(o$underlying)) else rep(FALSE, nrow(deaths))
  hit_text  <- if (o$text != "") str_detect(text, regex(o$text, ignore_case = TRUE)) &
                                 (o$text_needs == "" | str_detect(text, regex(o$text_needs, ignore_case = TRUE))) &
                                 !str_detect(text, regex(text_exclude, ignore_case = TRUE)) &
                                 !manner_in(deaths$manner, o$not_manner) else rep(FALSE, nrow(deaths))
  hit_ment  <- if (o$anymention != "") mention_any(expand(o$anymention)) else rep(FALSE, nrow(deaths))
  hit_field <- if (o$field_rule != "") { kv <- strsplit(o$field_rule, "=")[[1]]; toupper(coalesce(deaths[[kv[1]]], "")) == toupper(kv[2]) } else rep(FALSE, nrow(deaths))
  base <- hit_under | hit_text | hit_field
  deaths[[o$outcome]] <- if (o$need_mention) base & hit_ment else base | hit_ment
  deaths[[paste0(o$outcome, "_text_only")]] <- deaths[[o$outcome]] & hit_text & !hit_under & !hit_field
}
cases <- deaths %>% filter(if_any(all_of(outcomes$outcome)))
message("Cases: ", paste(outcomes$outcome, sapply(outcomes$outcome, function(o) sum(deaths[[o]])), collapse = ", "))

# ---- 3. CODE INDUSTRY AND OCCUPATION (CDC NIOCCS web service) ---------
# One GET per distinct text pair (team's GET.R); replies cached so each pair is sent once.
cache_file <- file.path(cfg$cache_dir, "nioccs_cache.csv")
cache <- if (file.exists(cache_file)) read_csv(cache_file, col_types = cols(.default = "c"), na = character(), show_col_types = FALSE) else
         tibble(IndustryLit = character(), OccupationLIt = character(), NAICSCode = character(), SOCCode = character())
cases <- cases %>% mutate(IndustryLit = coalesce(IndustryLit, ""), OccupationLIt = coalesce(OccupationLIt, ""))
todo <- cases %>% distinct(IndustryLit, OccupationLIt) %>% filter(IndustryLit != "" | OccupationLIt != "") %>% anti_join(cache, by = c("IndustryLit", "OccupationLIt"))
if (cfg$run_nioccs && nrow(todo) > 0) {
  message("NIOCCS: coding ", nrow(todo), " text pairs")
  for (i in seq_len(nrow(todo))) {
    r <- try(GET("https://wwwn.cdc.gov/nioccs/IOCode?", query = list(i = todo$IndustryLit[i], o = todo$OccupationLIt[i], c = 2), timeout(30)), silent = TRUE)
    if (inherits(r, "try-error") || status_code(r) != 200) next
    j <- fromJSON(content(r, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)
    row <- tibble(IndustryLit = todo$IndustryLit[i], OccupationLIt = todo$OccupationLIt[i],
                  NAICSCode = as.character(j$Industry$NAICSCode %||% ""), SOCCode = as.character(j$Occupation$SOCCode %||% ""))
    write_csv(row, cache_file, append = file.exists(cache_file), na = "")
    cache <- bind_rows(cache, row); Sys.sleep(0.2)
  }
} else if (nrow(todo) > 0) message("NIOCCS off: ", nrow(todo), " text pairs not coded (set run_nioccs = TRUE)")
`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a

# Sector = NAICS 2-digit (31-33, 44-45, 48-49 combined); occupation group = SOC first 2 digits.
# Rows that get counts but no rate: Military (not in ACS), Not in workforce, Not coded.
sector_of <- function(code) { s <- substr(coalesce(code, ""), 1, 2)
  case_when(s %in% c("31","32","33") ~ "31-33", s %in% c("44","45") ~ "44-45", s %in% c("48","49") ~ "48-49", TRUE ~ s) }
nonwork <- regex("\\b(homemaker|housewife|student|retired|unemployed|never worked|disabled|disability)\\b", ignore_case = TRUE)
map_file <- c(file.path(here, "acs_group_map.csv"), "scripts/acs_group_map.csv"); map_file <- map_file[file.exists(map_file)][1]
if (is.na(map_file)) stop("acs_group_map.csv must sit next to this script")
acs_map <- read_csv(map_file, col_types = cols(.default = "c"), show_col_types = FALSE)
sectors <- unique(acs_map$group[acs_map$table == "C24030"]); socgrps <- unique(acs_map$group[acs_map$table == "C24010"])
cases <- cases %>% left_join(cache, by = c("IndustryLit", "OccupationLIt")) %>%
  mutate(sector = sector_of(NAICSCode), socgrp = substr(coalesce(SOCCode, ""), 1, 2),
         military = startsWith(coalesce(NAICSCode, ""), "928110") | socgrp == "55",
         nonworker = str_detect(paste(IndustryLit, OccupationLIt), nonwork),
         ind_group = case_when(military ~ "Military", sector %in% sectors ~ sector, nonworker ~ "Not in workforce", TRUE ~ "Not coded"),
         occ_group = case_when(military ~ "Military", socgrp %in% socgrps ~ socgrp, nonworker ~ "Not in workforce", TRUE ~ "Not coded"))
nonrate <- c("Military", "Not in workforce", "Not coded")

# ---- 4. ACS DENOMINATORS: civilian employed 16+, Nebraska, by sex --------
# C24030 = sex by industry, C24010 = sex by occupation. Rows matched by label text via acs_group_map.csv.
acs_file <- file.path(cfg$cache_dir, sprintf("acs_%d.csv", cfg$acs_year))
if (!file.exists(acs_file)) {
  key <- Sys.getenv("CENSUS_API_KEY"); if (!nzchar(key)) stop("Set CENSUS_API_KEY (tidycensus::census_api_key(key, install = TRUE))")
  vars <- tidycensus::load_variables(cfg$acs_year, "acs5") %>% filter(str_detect(name, "^C2403[0]_|^C24010_")) %>% select(name, label)
  tidycensus::get_acs("state", state = "NE", variables = vars$name, year = cfg$acs_year, survey = "acs5", key = key) %>%
    left_join(vars, by = c("variable" = "name")) %>% select(variable, label, estimate, moe) %>% write_csv(acs_file)
}
acs <- read_csv(acs_file, show_col_types = FALSE) %>%
  mutate(table = substr(variable, 1, 6), label = str_remove(label, "^Estimate!!"),
         sex = case_when(str_detect(label, "!!Male") ~ "M", str_detect(label, "!!Female") ~ "F", TRUE ~ "T"),
         leaf_name = str_remove(str_extract(label, "[^!]+$"), ":$"))
acs$is_leaf <- !sapply(seq_len(nrow(acs)), function(i) any(startsWith(acs$label[acs$table == acs$table[i]], paste0(acs$label[i], "!!"))))
denominator <- function(tab) {
  d <- acs %>% filter(table == tab, is_leaf, sex != "T") %>% inner_join(acs_map %>% filter(table == tab), by = c("table", "leaf_name"))
  total <- acs$estimate[acs$variable == paste0(tab, "_001")]
  if (abs(sum(d$estimate) - total) > 0.005 * total) stop(tab, ": mapped rows do not add to the table total; check acs_group_map.csv")
  d <- d %>% group_by(group, sex) %>% summarise(workers = sum(estimate), .groups = "drop")
  bind_rows(d, d %>% group_by(group) %>% summarise(sex = "T", workers = sum(workers), .groups = "drop")) %>%
    { bind_rows(., group_by(., sex) %>% summarise(group = "All workers", workers = sum(workers), .groups = "drop")) }
}
den_ind <- denominator("C24030"); den_occ <- denominator("C24010")
acs_total_ind <- acs$estimate[acs$variable == "C24030_001"]; acs_total_occ <- acs$estimate[acs$variable == "C24010_001"]

# ---- 5. RATES per 100,000 worker-years, exact Poisson 95% CI, rate ratio vs all workers ----
rate_table <- function(outcome, group_col, den, yrs = cfg$years) {
  cs <- cases %>% filter(.data[[outcome]], year %in% yrs) %>% mutate(group = .data[[group_col]])
  counts <- bind_rows(cs %>% count(group, sex, name = "deaths"),
                      cs %>% count(group, name = "deaths") %>% mutate(sex = "T"),
                      cs %>% filter(!group %in% nonrate) %>% count(sex, name = "deaths") %>% mutate(group = "All workers"),
                      tibble(group = "All workers", sex = "T", deaths = sum(!cs$group %in% nonrate)))
  den %>% full_join(counts, by = c("group", "sex")) %>%
    mutate(outcome = outcome, years = paste(range(yrs), collapse = "-"), deaths = coalesce(deaths, 0L),
           worker_years = ifelse(group %in% nonrate, NA, workers * length(yrs)),
           rate    = deaths / worker_years * 1e5,
           rate_lo = ifelse(deaths == 0, 0, qchisq(0.025, 2 * deaths) / 2) / worker_years * 1e5,
           rate_hi = qchisq(0.975, 2 * (deaths + 1)) / 2 / worker_years * 1e5) %>%
    group_by(sex) %>% mutate(pct_of_deaths = 100 * deaths / sum(deaths[group != "All workers"]),
                             rr = rate / rate[group == "All workers"]) %>% ungroup() %>%
    select(outcome, years, group, sex, deaths, pct_of_deaths, workers, worker_years, rate, rate_lo, rate_hi, rr) %>% arrange(sex, group)
}
tables <- list()
for (o in outcomes$outcome) { tables[[paste0(o, "_industry")]] <- rate_table(o, "ind_group", den_ind)
                              tables[[paste0(o, "_occupation")]] <- rate_table(o, "occ_group", den_occ) }
tables_raw <- tables

# ---- 6. CHECKS AND WRITE ----------------------------------------------
sums_ok <- all(sapply(names(tables), function(nm) { t <- tables[[nm]] %>% filter(sex == "T")
  sum(t$deaths[t$group != "All workers"]) == sum(cases[[t$outcome[1]]]) }))
qa <- list(
  deaths_by_year_16plus = deaths %>% group_by(year) %>% summarise(across(all_of(outcomes$outcome), sum), .groups = "drop"),
  text_only_cases = sapply(paste0(outcomes$outcome, "_text_only"), function(v) sum(deaths[[v]])),
  group_rows_sum_to_totals = sums_ok,
  acs_totals = c(C24030 = acs_total_ind, C24010 = acs_total_occ),
  text_pairs_not_yet_coded = nrow(todo),
  not_coded_share = mean(cases$ind_group == "Not coded"))
print(qa)
if (!sums_ok) warning("Group rows do not add up to the case totals")
stamp <- format(Sys.Date(), "%Y%m%d")
write_csv(bind_rows(tables), file.path(cfg$out_dir, sprintf("io_death_rates_%s.csv", stamp)), na = "")
capture.output(print(qa), file = file.path(cfg$cache_dir, sprintf("qa_%s.txt", stamp)))
write_csv(cases %>% select(DeathCertificateId, year, all_of(outcomes$outcome), IndustryLit, OccupationLIt, NAICSCode, SOCCode, ind_group, occ_group),
          file.path(cfg$cache_dir, sprintf("cases_%s.csv", stamp)), na = "")   # record level: Cache only
message("Done. Table in ", cfg$out_dir, "; QA and case list in ", cfg$cache_dir)
