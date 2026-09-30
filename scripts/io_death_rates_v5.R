# io_death_rates_v5.R   2026-09-28. Replaces io_death_rates_v4.R (changes: docs/v5-changes.md). No suppression anywhere.
# Suicide and drug overdose death rates by industry and occupation, Nebraska residents 16+, 2020-2024. Read top to
# bottom like a SAS program: each block is one DATA step or PROC. Sources (detail: docs/provenance-audit-v4.md):
#   Suicide X60-X84, Y87.0, U03: NE DHHS suicide dashboard. Overdose X40-X44, Y10-Y14: the ICD part of the SUDORS
#   definition only; its cause-text search is NOT counted (text-only candidates go to a review list). Opioid subset:
#   the Massachusetts DPH T40 list on that base (our combination). opioid_ma_def: Massachusetts DPH 2018-2020 report as
#   written. NIOCCS call: team's GET.R. Military and not-in-workforce NIOCCS codes: read off our own replies, not NIOSH
#   documentation. Not-in-workforce words: Massachusetts list plus "retired" (ours). Denominator: ACS 2020-2024 C24030 /
#   C24010, civilian employed 16+ (our table choice). Rates and 95% CIs as Massachusetts; the exact Poisson CI is ours.
# Run: source("C:/Users/tsedlac/Downloads/io_death_rates_v5.R"). Needs next to it: acs_group_map.csv (required),
#   Cache/nioccs_cache_v3.csv (reused; new text pairs go to CDC) and Cache/acs_2024.csv (reused; else pulled with CENSUS_API_KEY).
# Writes Output/ (group tables only) and Cache/ (QA, case list, review list: record level stays in Cache).
library(readxl); library(readr); library(dplyr); library(httr); library(jsonlite)
# ---- Settings (like %LET). The two getOption() calls are set only by tests/synthetic_run.R (temp folders) ----
years     <- 2020:2024
dc_dir    <- getOption("io_v5_dc_dir", "K:/Occupational Health Grant/data/dc")          # {YYYY}/DeathCertificates{YY}.csv or .xlsx
work_dir  <- getOption("io_v5_work_dir")                                   # else: the folder of the file source() is running
for (f in sys.frames()) if (is.null(work_dir) && !is.null(f$ofile)) work_dir <- dirname(normalizePath(f$ofile))
if (is.null(work_dir)) stop('Run it with source("C:/Users/tsedlac/Downloads/io_death_rates_v5.R")')
out_dir   <- file.path(work_dir, "Output"); cache_dir <- file.path(work_dir, "Cache"); stamp <- format(Sys.Date(), "%Y%m%d")
for (d in c(out_dir, cache_dir)) dir.create(d, showWarnings = FALSE)
# ---- 1. PROC IMPORT each yearly export (every column as text), then SET them together, keeping the export year ----
keep <- c("DeathCertificateId", "DateOfDeath", "DateOfBirth", "ResidingStateNchs", "Sex", "MannerDeath",
          "AcmeUnderlyingCode", paste0("D2Acme", 1:20), paste0("D2SmicarAxis", 1:20), "ImmedCauseDeath",
          "Consq1", "Consq2", "Consq3", "OtherSignificantConditions", "IndustryLit", "OccupationLIt")
dc <- NULL
for (yr in years) {
  f <- file.path(dc_dir, yr, paste0("DeathCertificates", yr %% 100))
  if (file.exists(paste0(f, ".csv"))) one <- read_csv(paste0(f, ".csv"), col_types = cols(.default = "c"), na = "")
  else one <- read_excel(paste0(f, ".xlsx"), col_types = "text")
  dc <- bind_rows(dc, select(one, any_of(keep)) %>% mutate(export = yr))
}
to_date <- function(x) {       # dates arrive as Excel serial numbers (45291 = 2023-12-31) or as text; a trailing time is ignored
  d <- as.Date(floor(suppressWarnings(as.numeric(x))), origin = "1899-12-30")   # serial number
  d[is.na(d)] <- as.Date(x[is.na(d)], format = "%m/%d/%Y")                      # text like 1/31/2021
  d[is.na(d)] <- as.Date(x[is.na(d)], format = "%Y-%m-%d")                      # text like 2021-01-31
  d
}
# ---- 2. DATA deaths: one row per certificate, latest export wins (EventYear and NchsAge are 0 on every row) ----
n_blank_id <- sum(coalesce(dc$DeathCertificateId, "") == "")        # cannot be deduplicated: dropped and counted
dc <- dc %>% filter(coalesce(DeathCertificateId, "") != "") %>%
  mutate(dod = to_date(DateOfDeath), dob = to_date(DateOfBirth), year = as.integer(format(dod, "%Y")))
n_year_moved <- dc %>% distinct(DeathCertificateId, year) %>% count(DeathCertificateId) %>% filter(n > 1) %>% nrow()
# PROC SORT BY id DESCENDING export, then NODUPKEY BY id: the later export has the final cause of death
deaths <- dc %>% arrange(DeathCertificateId, desc(export)) %>% distinct(DeathCertificateId, .keep_all = TRUE)
n_bad_dod <- sum(is.na(deaths$dod) & coalesce(deaths$DateOfDeath, "") != "")   # unreadable dates: counted in QA, row dropped
n_bad_dob <- sum(is.na(deaths$dob) & coalesce(deaths$DateOfBirth, "") != "")
deaths <- deaths %>% filter(year %in% years) %>%
  mutate(age = trunc(as.numeric(dod - dob) / 365.25), s1 = toupper(substr(Sex, 1, 1)),
         sex = case_when(s1 %in% c("M", "1") ~ "M", s1 %in% c("F", "2") ~ "F", TRUE ~ "U")) %>%
  filter(toupper(ResidingStateNchs) == "NE", age >= 16)
# ---- 3. DATA deaths: flag outcomes (IF statements) ----
# Codes lose their dots ("Y87.0" -> "Y870"); u3 >= "X60" & u3 <= "X84" is SAS's  if "X60" <= substrn(ucod,1,3) <= "X84".
nodot <- function(x) toupper(gsub("[. ]", "", coalesce(x, "")))
t40   <- c("T400", "T401", "T402", "T403", "T404", "T406")          # opioids (T40.5 cocaine is not one)
od_words <- "overdose|toxicity|intoxication|poisoning"                 # these two lists feed the review list only
drugs <- paste0("drug|fentanyl|opioid|opiate|heroin|meth|amphetamine|cocaine|oxycodone|hydrocodone|morphine|tramadol|",
                "xylazine|alprazolam|benzodiazepine|acetaminophen|medication|pill|polysubstance")
deaths <- deaths %>%
  mutate(ucod = nodot(AcmeUnderlyingCode), u3 = substr(ucod, 1, 3), manner = toupper(substr(coalesce(MannerDeath, ""), 1, 1)),
         # any of the 40 multiple-cause fields starts with an opioid T code (the SAS 40-field ARRAY loop)
         t40_any = if_any(c(starts_with("D2Acme"), starts_with("D2SmicarAxis")), ~ substr(nodot(.x), 1, 4) %in% t40),
         suicide = (u3 >= "X60" & u3 <= "X84") | substr(ucod, 1, 4) == "Y870" | u3 == "U03",
         overdose        = (u3 >= "X40" & u3 <= "X44") | (u3 >= "Y10" & u3 <= "Y14"),                 # SUDORS ICD
         overdose_opioid = overdose & t40_any,
         opioid_ma_def   = t40_any & ((u3 >= "X40" & u3 <= "X49") | (u3 >= "X60" & u3 <= "X69") |   # Massachusetts
                           (u3 >= "X85" & u3 <= "X90") | (u3 >= "Y10" & u3 <= "Y19") | substr(ucod, 1, 4) == "Y352"),
         # Review list only, never counted: overdose word + drug word in the SAME cause field, not ICD overdose, manner not S/H/N
         text_candidate = !overdose & !manner %in% c("S", "H", "N") &
           if_any(c(ImmedCauseDeath, Consq1, Consq2, Consq3, OtherSignificantConditions),
                  ~ grepl(od_words, tolower(.x)) & grepl(drugs, tolower(.x))))
outcomes <- c("suicide", "overdose", "overdose_opioid", "opioid_ma_def")
cases <- deaths %>% filter(suicide | overdose | opioid_ma_def) %>%
  mutate(IndustryLit = coalesce(IndustryLit, ""), OccupationLIt = coalesce(OccupationLIt, ""))
# ---- 4. Code industry and occupation text with CDC NIOCCS (the team's GET.R call) ----
# One call per pair not in the cache, saved as it arrives (never sent twice). An error page is NOT saved (retried next run).
cache_file <- file.path(cache_dir, "nioccs_cache_v3.csv"); n_unusable <- 0
cache <- tibble(IndustryLit = character(), OccupationLIt = character(), NAICSCode = character(), SOCCode = character(), raw = character())
if (file.exists(cache_file)) cache <- read_csv(cache_file, col_types = cols(.default = "c"), na = character())
todo <- cases %>% distinct(IndustryLit, OccupationLIt) %>% filter(IndustryLit != "" | OccupationLIt != "") %>%
  anti_join(cache, by = c("IndustryLit", "OccupationLIt"))
for (i in seq_len(nrow(todo))) {
  r <- GET("https://wwwn.cdc.gov/nioccs/IOCode?", query = list(i = todo$IndustryLit[i], o = todo$OccupationLIt[i], c = 2))
  reply <- content(r, as = "text", encoding = "UTF-8")
  j <- if (status_code(r) == 200 && validate(reply)) fromJSON(reply)      # NULL unless the reply is JSON
  if (!is.list(j) || is.null(j$Industry)) { message("NIOCCS reply not usable, not saved: ", substr(reply, 1, 80)); n_unusable <- n_unusable + 1; next }
  row <- tibble(IndustryLit = todo$IndustryLit[i], OccupationLIt = todo$OccupationLIt[i],    # c(x, "")[1] = first code, or ""
                NAICSCode = as.character(c(j$Industry$NAICSCode, "")[1]), SOCCode = as.character(c(j$Occupation$SOCCode, "")[1]), raw = reply)
  write_csv(row, cache_file, append = file.exists(cache_file)); cache <- bind_rows(cache, row); Sys.sleep(0.2)
}
n_cached_no_codes <- sum(!grepl("Industry", cache$raw) & cache$NAICSCode == "" & cache$SOCCode == "")   # error replies saved by v3/v4
cache <- cache %>% distinct(IndustryLit, OccupationLIt, .keep_all = TRUE) %>% select(-raw)   # stored codes used as they are
# ---- 5. DATA cases: roll codes to the ACS groups (like a PROC FORMAT) ----
# Sector = NAICS first 2 digits (31-33, 44-45, 48-49 combined); SOC group = SOC first 2 digits. NIOCCS placeholders:
# 0096xx/0097xx or 00-98xx = armed forces; 009890 or 00-90xx/00-91xx = not in workforce; 009990/00-9900 = Not coded.
# NAICS 928110 (national security) stays in sector 92: DoD civilians are in the ACS civilian denominator.
acs_map <- read_csv(file.path(work_dir, "acs_group_map.csv"), col_types = cols(.default = "c"))
nonwork <- "homemaker|housewife|student|retired|unemployed|never worked|never employed|disabled|disability"
sectors <- acs_map$group[acs_map$table == "C24030"]; socgrps <- acs_map$group[acs_map$table == "C24010"]
cases <- cases %>% left_join(cache, by = c("IndustryLit", "OccupationLIt")) %>%
  mutate(naics = coalesce(NAICSCode, ""), soc = coalesce(SOCCode, ""), n2 = substr(naics, 1, 2), socgrp = substr(soc, 1, 2),
         sector = case_when(n2 %in% c("31", "32", "33") ~ "31-33", n2 %in% c("44", "45") ~ "44-45", n2 %in% c("48", "49") ~ "48-49", TRUE ~ n2),
         military  = substr(naics, 1, 4) %in% c("0096", "0097") | substr(soc, 1, 5) == "00-98" | socgrp == "55",
         nonworker = !military & (naics == "009890" | substr(soc, 1, 5) %in% c("00-90", "00-91") |
                                  grepl(nonwork, tolower(paste(IndustryLit, OccupationLIt)))),
         ind_group = case_when(military ~ "Military", sector %in% sectors ~ sector, nonworker ~ "Not in workforce", TRUE ~ "Not coded"),
         occ_group = case_when(military ~ "Military", socgrp %in% socgrps ~ socgrp, nonworker ~ "Not in workforce", TRUE ~ "Not coded"))
# ---- 6. ACS 2020-2024 5-year, Nebraska: C24030 (industry) and C24010 (occupation), civilian employed 16+ ----
acs_file <- file.path(cache_dir, "acs_2024.csv")    # pulled once; key from the CENSUS_API_KEY environment variable
if (!file.exists(acs_file)) {
  vars <- tidycensus::load_variables(2024, "acs5") %>% filter(substr(name, 1, 7) %in% c("C24030_", "C24010_"))
  tidycensus::get_acs("state", state = "NE", variables = vars$name, year = 2024, survey = "acs5", key = Sys.getenv("CENSUS_API_KEY")) %>%
    left_join(vars, by = c("variable" = "name")) %>% select(variable, label, estimate, moe) %>% write_csv(acs_file)
}
# A label reads "Estimate!!Total:!!Male:!!Construction"; its last piece is matched to acs_group_map.csv. A row that no
# other row hangs under (is not a "parent") is a leaf; every leaf with a sex must be in the map, or the run stops.
acs <- read_csv(acs_file, col_types = cols(.default = "c", estimate = "d")) %>%
  mutate(table = substr(variable, 1, 6), leaf_name = sub(":$", "", sub(".*!!", "", label)), parent = sub("!![^!]*$", "", label),
         sex = ifelse(grepl("!!Male", label), "M", ifelse(grepl("!!Female", label), "F", "T")))
leaves <- acs %>% filter(!label %in% parent, sex != "T")
unmapped <- anti_join(leaves, acs_map, by = c("table", "leaf_name"))
if (nrow(unmapped) > 0) stop("ACS rows not in acs_group_map.csv (add them to the map): ", paste(unique(unmapped$leaf_name), collapse = "; "))
den <- leaves %>% inner_join(acs_map, by = c("table", "leaf_name")) %>% group_by(table, group, sex) %>% summarise(workers = sum(estimate), .groups = "drop")
den <- bind_rows(den, den %>% group_by(table, group) %>% summarise(sex = "T", workers = sum(workers), .groups = "drop"))
den <- bind_rows(den, den %>% group_by(table, sex) %>% summarise(group = "All workers", workers = sum(workers), .groups = "drop"))
acs_check <- den %>% filter(group == "All workers", sex == "T") %>%      # mapped groups must add to C24030_001 / C24010_001
  left_join(acs %>% filter(variable %in% c("C24030_001", "C24010_001")) %>% select(table, acs_total = estimate), by = "table")
# ---- 7. Rates per 100,000 worker-years (workers x years), exact Poisson 95% CI, by sex M, F and T ----
nonrate <- c("Military", "Not in workforce", "Not coded")                  # counted, but no rate
rate_table <- function(outcome, group_var, acs_table, yrs) {
  d <- cases %>% filter(.data[[outcome]], year %in% yrs) %>% mutate(group = .data[[group_var]])
  d <- bind_rows(d, mutate(d, sex = "T"))           # each death once under its sex and once under T (OUTPUT twice)
  counts <- bind_rows(count(d, group, sex, name = "deaths"),
                      d %>% filter(!group %in% nonrate) %>% count(sex, name = "deaths") %>% mutate(group = "All workers")) %>%
    filter(sex != "U")                              # sex U deaths are in the T rows only
  den %>% filter(table == acs_table) %>% select(group, sex, workers) %>% full_join(counts, by = c("group", "sex")) %>%
    mutate(outcome = outcome, grouping = ifelse(acs_table == "C24030", "industry", "occupation"), acs_table = acs_table,
           years = paste(min(yrs), max(yrs), sep = "-"), deaths = coalesce(deaths, 0L),
           worker_years = ifelse(group %in% nonrate, NA, workers * length(yrs)),
           rate = deaths / worker_years * 100000, rate_lo = ifelse(deaths == 0, 0, qchisq(0.025, 2 * deaths) / 2) / worker_years * 100000,
           rate_hi = qchisq(0.975, 2 * deaths + 2) / 2 / worker_years * 100000) %>%
    group_by(sex) %>% mutate(pct_of_deaths = 100 * deaths / sum(deaths[group != "All workers"])) %>% ungroup() %>%
    select(outcome, grouping, acs_table, years, group, sex, deaths, pct_of_deaths, workers, worker_years, rate, rate_lo, rate_hi) %>% arrange(sex, group)
}
tables <- NULL
for (o in outcomes) tables <- bind_rows(tables, rate_table(o, "ind_group", "C24030", years), rate_table(o, "occ_group", "C24010", years))
# Suicide by sector 2020-2021 beside the NEVDRS sheet (84 / 72 / 55). Compare counts; rates use the 2020-2024 ACS (approximate).
recon <- rate_table("suicide", "ind_group", "C24030", 2020:2021) %>% filter(sex == "T") %>%
  mutate(nevdrs_sheet = case_when(group == "Not in workforce" ~ 84, group == "23" ~ 72, group == "31-33" ~ 55))
# ---- 8. Checks (PROC FREQ style) to the screen and Cache/qa_{date}.txt (PROC PRINTTO); sums: T rows = flagged in step 3 ----
flagged <- colSums(deaths[outcomes])                        # counted in step 3, before NIOCCS and grouping
sums <- tables %>% filter(sex == "T", group != "All workers") %>% count(outcome, grouping, wt = deaths, name = "table_rows") %>%
  mutate(flagged = flagged[outcome], ok = table_rows == flagged)
sink(file.path(cache_dir, paste0("qa_", stamp, ".txt")), split = TRUE)
print(c(blank_id_rows_dropped = n_blank_id, overlap_copies_dropped = nrow(dc) - n_distinct(dc$DeathCertificateId), year_moved_between_exports = n_year_moved,
        unreadable_DateOfDeath = n_bad_dod, unreadable_DateOfBirth = n_bad_dob, nioccs_replies_not_usable_this_run = n_unusable,
        cached_pairs_without_codes = n_cached_no_codes, case_text_pairs_not_in_cache = nrow(anti_join(todo, cache, by = c("IndustryLit", "OccupationLIt")))))
print(deaths %>% group_by(year) %>% summarise(deaths_16plus = n(), suicide = sum(suicide), overdose = sum(overdose),
        overdose_opioid = sum(overdose_opioid), opioid_ma_def = sum(opioid_ma_def), text_candidates_not_counted = sum(text_candidate)), width = Inf)
print(count(cases, ind_group), n = 40); print(acs_check); print(sums)
print(recon %>% filter(!is.na(nevdrs_sheet)) %>% select(group, deaths, rate, nevdrs_sheet))
sink()
if (any(abs(acs_check$workers - acs_check$acs_total) > 0.5) || !all(sums$ok)) stop("ACS total or table sums check failed; see Cache/qa_", stamp, ".txt")
write_csv(tables, file.path(out_dir, paste0("io_death_rates_", stamp, ".csv")), na = "")
write_csv(recon,  file.path(out_dir, paste0("suicide_2020_2021_vs_nevdrs_", stamp, ".csv")), na = "")
write_csv(cases %>% select(DeathCertificateId, year, sex, age, all_of(outcomes), IndustryLit, OccupationLIt, NAICSCode, SOCCode, ind_group, occ_group),
          file.path(cache_dir, paste0("cases_", stamp, ".csv")), na = "")   # record level: Cache only
write_csv(deaths %>% filter(text_candidate) %>% select(DeathCertificateId, year, AcmeUnderlyingCode, MannerDeath, ImmedCauseDeath, Consq1, Consq2, Consq3,
          OtherSignificantConditions), file.path(cache_dir, paste0("review_", stamp, ".csv")), na = "")   # text-only overdose candidates
