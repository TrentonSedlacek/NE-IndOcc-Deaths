# io_death_rates_simple_sketch.R   DRAFT for review, not a release. Not yet run on K:.
# Suicide and drug overdose death rates by industry and occupation, Nebraska residents 16+, 2020-2024.
# Read top to bottom like a SAS program: each block is one DATA step or PROC. No suppression.

library(readxl); library(readr); library(dplyr); library(httr); library(jsonlite)

# ---- Settings (like %LET) ----
years     <- 2020:2024
dc_dir    <- "K:/Occupational Health Grant/data/dc"   # {YYYY}/DeathCertificates{YY}.csv or .xlsx
work_dir  <- "C:/Users/tsedlac/Downloads"             # acs_group_map.csv must be here
out_dir   <- file.path(work_dir, "Output")            # summary tables only
cache_dir <- file.path(work_dir, "Cache")             # NIOCCS replies, ACS pull, case list (record level)
for (d in c(out_dir, cache_dir)) dir.create(d, showWarnings = FALSE)

# ---- 1. PROC IMPORT each yearly export (every column as text), then SET them together ----
keep <- c("DeathCertificateId", "DateOfDeath", "DateOfBirth", "ResidingStateNchs", "Sex", "MannerDeath",
          "AcmeUnderlyingCode", paste0("D2Acme", 1:20), paste0("D2SmicarAxis", 1:20), "ImmedCauseDeath",
          "Consq1", "Consq2", "Consq3", "OtherSignificantConditions", "IndustryLit", "OccupationLIt")
dc <- NULL
for (yr in years) {
  f <- file.path(dc_dir, yr, paste0("DeathCertificates", yr %% 100))
  if (file.exists(paste0(f, ".csv"))) one <- read_csv(paste0(f, ".csv"), col_types = cols(.default = "c"), na = "")
  else one <- read_excel(paste0(f, ".xlsx"), col_types = "text")
  dc <- bind_rows(dc, select(one, any_of(keep)))
}

# Dates arrive as Excel serial numbers (45291 = 2023-12-31) or as text; a trailing time is ignored.
to_date <- function(x) {
  d <- as.Date(suppressWarnings(as.numeric(x)), origin = "1899-12-30")   # serial number
  d[is.na(d)] <- as.Date(x[is.na(d)], format = "%m/%d/%Y")               # text like 1/31/2021
  d[is.na(d)] <- as.Date(x[is.na(d)], format = "%Y-%m-%d")               # text like 2021-01-31
  d
}

# ---- 2. DATA deaths: year and age from the dates (EventYear and NchsAge are 0 on every row) ----
deaths <- dc %>%
  mutate(dod = to_date(DateOfDeath), dob = to_date(DateOfBirth),
         year = as.integer(format(dod, "%Y")),
         age  = trunc(as.numeric(dod - dob) / 365.25),
         sex  = case_when(toupper(substr(Sex, 1, 1)) %in% c("M", "1") ~ "M",
                          toupper(substr(Sex, 1, 1)) %in% c("F", "2") ~ "F", TRUE ~ "U")) %>%
  filter(year %in% years) %>%
  distinct(DeathCertificateId, year, .keep_all = TRUE) %>%   # PROC SORT NODUPKEY BY id year (exports overlap)
  filter(toupper(ResidingStateNchs) == "NE", age >= 16)

# ---- 3. DATA deaths: flag outcomes (IF statements) ----
# Codes lose their dots ("Y87.0" -> "Y870"). u3 = first 3 characters of the underlying cause, and
# u3 >= "X60" & u3 <= "X84" is SAS's  if "X60" <= substrn(code,1,3) <= "X84".
nodot <- function(x) toupper(gsub("[. ]", "", coalesce(x, "")))
t40   <- c("T400", "T401", "T402", "T403", "T404", "T406")          # opioids (T40.5 cocaine is not one)
drugs <- "drug|fentanyl|opioid|opiate|heroin|methamphetamine|amphetamine|cocaine|oxycodone|methadone|medication|pill|polysubstance"
deaths <- deaths %>%
  mutate(ucod = nodot(AcmeUnderlyingCode), u3 = substr(ucod, 1, 3),
         manner = toupper(substr(coalesce(MannerDeath, ""), 1, 1)),
         causes = tolower(paste(ImmedCauseDeath, Consq1, Consq2, Consq3, OtherSignificantConditions)),
         # any of the 40 multiple-cause fields starts with an opioid T code (the SAS 40-field ARRAY loop)
         t40_any = if_any(c(starts_with("D2Acme"), starts_with("D2SmicarAxis")), ~ substr(nodot(.x), 1, 4) %in% t40),
         suicide = (u3 >= "X60" & u3 <= "X84") | substr(ucod, 1, 4) == "Y870" | u3 == "U03",
         # SUDORS overdose: underlying X40-X44 or Y10-Y14, OR cause text names an overdose of a drug
         od_icd  = (u3 >= "X40" & u3 <= "X44") | (u3 >= "Y10" & u3 <= "Y14"),
         od_text = grepl("overdose|toxicity|intoxication|poisoning", causes) & grepl(drugs, causes) &
                   !grepl("carbon monoxide", causes) & !manner %in% c("S", "H", "N"),  # not suicide/homicide/natural
         overdose        = od_icd | od_text,
         overdose_opioid = overdose & t40_any,
         opioid_ma_def   = t40_any & ((u3 >= "X40" & u3 <= "X49") | (u3 >= "X60" & u3 <= "X69") |   # Massachusetts
                           (u3 >= "X85" & u3 <= "X90") | (u3 >= "Y10" & u3 <= "Y19") | substr(ucod, 1, 4) == "Y352"))
outcomes <- c("suicide", "overdose", "overdose_opioid", "opioid_ma_def")
cases <- deaths %>% filter(suicide | overdose | opioid_ma_def) %>%
  mutate(IndustryLit = coalesce(IndustryLit, ""), OccupationLIt = coalesce(OccupationLIt, ""))

# ---- 4. Code industry and occupation text with CDC NIOCCS (the team's GET.R call) ----
# One call per text pair not yet in the cache (the file v3 and v4 filled). Each reply is saved as it
# arrives, so a stopped run loses nothing and no pair is ever sent twice.
cache_file <- file.path(cache_dir, "nioccs_cache_v3.csv")
cache <- tibble(IndustryLit = character(), OccupationLIt = character(), NAICSCode = character(), SOCCode = character(), raw = character())
if (file.exists(cache_file)) cache <- read_csv(cache_file, col_types = cols(.default = "c"), na = character())
todo <- cases %>% distinct(IndustryLit, OccupationLIt) %>% filter(IndustryLit != "" | OccupationLIt != "") %>%
  anti_join(cache, by = c("IndustryLit", "OccupationLIt"))
for (i in seq_len(nrow(todo))) {
  r <- GET("https://wwwn.cdc.gov/nioccs/IOCode?", query = list(i = todo$IndustryLit[i], o = todo$OccupationLIt[i], c = 2))
  if (status_code(r) != 200) next                      # failed call: not saved, tried again next run
  reply <- content(r, as = "text", encoding = "UTF-8")
  j <- fromJSON(reply)                                  # c(x, "")[1] = first code returned, or "" if none
  row <- tibble(IndustryLit = todo$IndustryLit[i], OccupationLIt = todo$OccupationLIt[i],
                NAICSCode = c(j$Industry$NAICSCode, "")[1], SOCCode = c(j$Occupation$SOCCode, "")[1], raw = reply)
  write_csv(row, cache_file, append = file.exists(cache_file))
  cache <- bind_rows(cache, row)
  Sys.sleep(0.2)
}
cache <- cache %>% distinct(IndustryLit, OccupationLIt, .keep_all = TRUE) %>% select(-raw)

# ---- 5. DATA cases: roll codes to the ACS groups (like a PROC FORMAT) ----
# Sector = NAICS first 2 digits (31-33, 44-45, 48-49 combined); SOC group = SOC first 2 digits.
# NIOCCS special codes: industry 0096xx/0097xx or occupation 00-98xx = armed forces;
# industry 009890 or occupation 00-90xx/00-91xx = not in the workforce.
acs_map <- read_csv(file.path(work_dir, "acs_group_map.csv"), col_types = cols(.default = "c"))
nonwork <- "\\b(homemaker|housewife|student|retired|unemployed|not employed|never (worked|employed)|disabled|disability|inmate|incarcerated)\\b"
cases <- cases %>%
  left_join(cache, by = c("IndustryLit", "OccupationLIt")) %>%
  mutate(naics = coalesce(NAICSCode, ""), soc = coalesce(SOCCode, ""), n2 = substr(naics, 1, 2), socgrp = substr(soc, 1, 2),
         sector = case_when(n2 %in% c("31", "32", "33") ~ "31-33", n2 %in% c("44", "45") ~ "44-45",
                            n2 %in% c("48", "49") ~ "48-49", TRUE ~ n2),
         military  = substr(naics, 1, 6) == "928110" | socgrp == "55" |
                     substr(naics, 1, 4) %in% c("0096", "0097") | substr(soc, 1, 5) == "00-98",
         nonworker = !military & (naics == "009890" | substr(soc, 1, 5) %in% c("00-90", "00-91") |
                                  grepl(nonwork, tolower(paste(IndustryLit, OccupationLIt)))),
         ind_group = case_when(military ~ "Military", sector %in% acs_map$group[acs_map$table == "C24030"] ~ sector,
                               nonworker ~ "Not in workforce", TRUE ~ "Not coded"),
         occ_group = case_when(military ~ "Military", socgrp %in% acs_map$group[acs_map$table == "C24010"] ~ socgrp,
                               nonworker ~ "Not in workforce", TRUE ~ "Not coded"))

# ---- 6. ACS 2020-2024 5-year, Nebraska: C24030 (industry) and C24010 (occupation), civilian employed 16+ ----
acs_file <- file.path(cache_dir, "acs_2024.csv")    # pulled once; key from the CENSUS_API_KEY environment variable
if (!file.exists(acs_file)) {
  vars <- tidycensus::load_variables(2024, "acs5") %>% filter(substr(name, 1, 7) %in% c("C24030_", "C24010_"))
  tidycensus::get_acs("state", state = "NE", variables = vars$name, year = 2024, survey = "acs5", key = Sys.getenv("CENSUS_API_KEY")) %>%
    left_join(vars, by = c("variable" = "name")) %>% select(variable, label, estimate, moe) %>% write_csv(acs_file)
}
# A label reads "Estimate!!Total:!!Male:!!Construction"; its last piece is matched to acs_group_map.csv.
# Subtotals ("Service occupations") are not in the map, so the join drops them.
acs <- read_csv(acs_file, col_types = cols(.default = "c", estimate = "d")) %>%
  mutate(table = substr(variable, 1, 6), leaf_name = sub(":$", "", sub(".*!!", "", label)),
         sex = ifelse(grepl("!!Male", label), "M", ifelse(grepl("!!Female", label), "F", "T")))
den <- acs %>% inner_join(acs_map, by = c("table", "leaf_name")) %>%
  group_by(table, group, sex) %>% summarise(workers = sum(estimate), .groups = "drop")
den <- bind_rows(den, den %>% group_by(table, group) %>% summarise(sex = "T", workers = sum(workers), .groups = "drop"))
den <- bind_rows(den, den %>% group_by(table, sex) %>% summarise(group = "All workers", workers = sum(workers), .groups = "drop"))
acs_check <- den %>% filter(group == "All workers", sex == "T") %>%      # mapped groups must add to C24030_001 / C24010_001
  left_join(acs %>% filter(variable %in% c("C24030_001", "C24010_001")) %>% select(table, acs_total = estimate), by = "table")
print(acs_check); stopifnot(abs(acs_check$workers - acs_check$acs_total) < 0.005 * acs_check$acs_total)

# ---- 7. Rates per 100,000 worker-years (workers x years), exact Poisson 95% CI, rate ratio to all workers ----
nonrate <- c("Military", "Not in workforce", "Not coded")                  # counted, but no rate
rate_table <- function(outcome, group_var, acs_table, yrs) {
  d <- cases %>% filter(.data[[outcome]], year %in% yrs) %>% mutate(group = .data[[group_var]])
  d <- bind_rows(d, mutate(d, sex = "T"))           # each death once under its sex and once under T (OUTPUT twice)
  counts <- bind_rows(count(d, group, sex, name = "deaths"),
                      d %>% filter(!group %in% nonrate) %>% count(sex, name = "deaths") %>% mutate(group = "All workers"))
  den %>% filter(table == acs_table) %>% select(group, sex, workers) %>% full_join(counts, by = c("group", "sex")) %>%
    mutate(outcome = outcome, table = acs_table, years = paste(min(yrs), max(yrs), sep = "-"), deaths = coalesce(deaths, 0L),
           worker_years = ifelse(group %in% nonrate, NA, workers * length(yrs)),
           rate    = deaths / worker_years * 100000,
           rate_lo = ifelse(deaths == 0, 0, qchisq(0.025, 2 * deaths) / 2) / worker_years * 100000,
           rate_hi = qchisq(0.975, 2 * deaths + 2) / 2 / worker_years * 100000) %>%
    group_by(sex) %>%
    mutate(pct_of_deaths = 100 * deaths / sum(deaths[group != "All workers"]),
           rr = rate / first(rate[group == "All workers"])) %>% ungroup() %>%   # rr is NA if that sex has no All workers row
    select(outcome, table, years, group, sex, deaths, pct_of_deaths, workers, worker_years, rate, rate_lo, rate_hi, rr) %>%
    arrange(sex, group)
}
tables <- NULL
for (o in outcomes) tables <- bind_rows(tables, rate_table(o, "ind_group", "C24030", years), rate_table(o, "occ_group", "C24010", years))
# Suicide by sector for 2020-2021 only, beside the NEVDRS sheet (84 not in workforce, 72 construction, 55 manufacturing)
recon <- rate_table("suicide", "ind_group", "C24030", 2020:2021) %>% filter(sex == "T") %>%
  mutate(nevdrs_sheet = case_when(group == "Not in workforce" ~ 84, group == "23" ~ 72, group == "31-33" ~ 55))

# ---- 8. Checks (PROC FREQ style) and output ----
print(deaths %>% group_by(year) %>% summarise(deaths_16plus = n(), suicide = sum(suicide), overdose = sum(overdose),
        overdose_text_only = sum(overdose & !od_icd), overdose_opioid = sum(overdose_opioid), opioid_ma_def = sum(opioid_ma_def)))
print(tables %>% filter(sex == "T", group != "All workers") %>% count(outcome, table, wt = deaths, name = "sum_of_rows"))
print(cases %>% summarise(across(all_of(outcomes), sum)))    # sum_of_rows above must equal these, for both tables
print(count(cases, ind_group))                               # includes Military, Not in workforce, Not coded
print(recon %>% filter(!is.na(nevdrs_sheet)) %>% select(group, deaths, rate, nevdrs_sheet))
stamp <- format(Sys.Date(), "%Y%m%d")
write_csv(tables, file.path(out_dir, paste0("io_death_rates_simple_", stamp, ".csv")), na = "")
write_csv(recon,  file.path(out_dir, paste0("suicide_2020_2021_vs_nevdrs_simple_", stamp, ".csv")), na = "")
write_csv(cases %>% select(DeathCertificateId, year, all_of(outcomes), IndustryLit, OccupationLIt, NAICSCode, SOCCode, ind_group, occ_group),
          file.path(cache_dir, paste0("cases_simple_", stamp, ".csv")), na = "")   # record level: Cache only
