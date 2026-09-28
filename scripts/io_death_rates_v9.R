# io_death_rates_v9.R
# Suicide and drug overdose death rates by industry and occupation.
# Nebraska residents aged 16 and over, deaths 2020 to 2024.
#
# v9 (2026-09-28): v8 with age_hi = 120, so ages 16 and over, to compare like for like with the earlier
#   occupational health table (suicide_agg.R, ages 16 and over). Nothing else changed.
# v8 (2026-09-28): settings agreed with Derry. Every step copies a team program or a published method:
#   1. Deaths come from the NCHS annual files the team's SAS reads
#      (K:/Occupational Health Grant/data/dc/Annual/dth20.sas7bdat ... dth24; "combine data.sas").
#   2. Nebraska residents: RES_ST = "NE" (ohi deaths 2018-2025.sas line 728). Ages 16 to 64 (NIOSH working age;
#      Chris Austin's occupation FTE script filters AGEP <= 64).
#   3. Suicide = underlying cause X60 to X84 ("combine data.sas" line 195) plus Y87.0 and U03 (NCHS injury
#      mortality definition; these add at most one or two deaths).
#      Drug overdose = underlying X40 to X44 or Y10 to Y14 (SUDORS ICD definition).
#      Opioid overdose = overdose with T40.0 to T40.4 or T40.6 on the record axis (Massachusetts DPH list).
#   4. Industry and occupation text coded by CDC NIOCCS (Chris's GET call; Jean's nioccs_suicide.R).
#   5. NAICS sector and SOC major group (Chris's 2-digit rules: 3M = 31-33, 4M = 44-45, 48 and 49 = 48-49).
#   6. Denominators from ACS 5-year PUMS with Chris's Workforce Estimates tool:
#      civilian employed (ESR 1 or 2), ages 16 to 64, persons = sum of PWGTP, FTE = sum of PWGTP x WKHP / 40.
#   7. Crude rates per 100,000 worker-years, by sex and by age band, persons and FTE side by side.
#      Exact Poisson 95% CI on the person rate (Massachusetts DPH reports CIs); Derry does not use them.
#   8. Checks, then write. No suppression anywhere. Record-level files stay in Cache.
#
# How to run:  source("C:/Users/tsedlac/Downloads/io_death_rates_v9.R")
# Needs: R packages haven, tidycensus, dplyr, readr, httr, jsonlite; a Census API key installed for tidycensus.
# Reuses if present: Cache/nioccs_cache_v3.csv (NIOCCS replies) and Cache/pums_ne_5y_2024.csv (PUMS pull).

library(haven)
library(readr)
library(dplyr)
library(httr)
library(jsonlite)


# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------

years     <- 2020:2024
pums_year <- 2024                     # ACS 5-year PUMS ending year (2020-2024); falls back to 2023 if not released
age_lo    <- 16
age_hi    <- 120                    # v8 used 64; 120 = no upper limit
age_bands <- c(16, 30, 40, 50, 60, 65, 121) # 16-29, 30-39, 40-49, 50-59, 60-64, 65+

nchs_dir <- getOption("io_v8_nchs_dir", "K:/Occupational Health Grant/data/dc/Annual")
work_dir <- getOption("io_v8_work_dir", "C:/Users/tsedlac/Downloads")

out_dir   <- file.path(work_dir, "Output")
cache_dir <- file.path(work_dir, "Cache")
stamp     <- format(Sys.Date(), "%Y%m%d")

dir.create(out_dir,   showWarnings = FALSE)
dir.create(cache_dir, showWarnings = FALSE)


# ---------------------------------------------------------------------------
# 1. Read the NCHS annual death files (one SAS dataset per year of death)
#    Variables named as in the team's ReadDthFile layout.
# ---------------------------------------------------------------------------

keep <- c("DOD_YR", "CERTNUM", "SEX", "AGETYPE", "AGEUNITS", "RES_ST", "MANNEROD",
          "ACUND_CAUSE", paste0("RAXSCD", sprintf("%02d", 1:20)), "INDUSTL", "OCCUPL")

dc <- NULL
for (yr in years) {
  stem <- file.path(nchs_dir, paste0("dth", yr %% 100))
  if (file.exists(paste0(stem, ".sas7bdat"))) {
    one <- read_sas(paste0(stem, ".sas7bdat"))
  } else {
    one <- read_csv(paste0(stem, ".csv"), col_types = cols(.default = "c"), na = "")   # same layout as a csv
  }
  names(one) <- toupper(names(one))
  missing <- setdiff(keep, names(one))
  if (length(missing) > 0) stop("dth", yr %% 100, " has no column: ", paste(missing, collapse = ", "))
  one <- one[keep]
  one <- mutate(one, across(everything(), as.character))
  one$file_year <- yr
  dc <- bind_rows(dc, one)
}


# ---------------------------------------------------------------------------
# 2. One row per certificate; Nebraska residents; ages 16 to 64
#    AGETYPE 1 = age in years. Any other AGETYPE is under one year old.
# ---------------------------------------------------------------------------

n_rows_read <- nrow(dc)

deaths <- dc %>%
  mutate(across(all_of(keep), ~ trimws(coalesce(.x, "")))) %>%
  arrange(DOD_YR, CERTNUM, desc(file_year)) %>%
  distinct(DOD_YR, CERTNUM, .keep_all = TRUE)

n_duplicates <- n_rows_read - nrow(deaths)

deaths <- mutate(deaths,
                 year = as.integer(DOD_YR),
                 age  = ifelse(AGETYPE == "1", suppressWarnings(as.integer(AGEUNITS)), 0),
                 sex  = case_when(toupper(substr(SEX, 1, 1)) %in% c("M", "1") ~ "M",
                                  toupper(substr(SEX, 1, 1)) %in% c("F", "2") ~ "F",
                                  TRUE ~ "U"),
                 age_band = cut(age, breaks = age_bands, right = FALSE,
                                labels = paste0(head(age_bands, -1), "-", tail(age_bands, -1) - 1)))

n_unknown_age <- sum(is.na(deaths$age) | deaths$age >= 999)

deaths <- filter(deaths,
                 year %in% years,
                 toupper(RES_ST) == "NE",
                 !is.na(age), age >= age_lo, age <= age_hi)


# ---------------------------------------------------------------------------
# 3. Flag outcomes
#    Codes lose their dot first, so "Y87.0" and "Y870" both match.
# ---------------------------------------------------------------------------

nodot <- function(x) toupper(gsub("[. ]", "", coalesce(x, "")))
t40   <- c("T400", "T401", "T402", "T403", "T404", "T406")

deaths <- mutate(deaths,
                 ucod = nodot(ACUND_CAUSE),
                 u3   = substr(ucod, 1, 3),
                 # any of the 20 record-axis codes starts with an opioid T code (the SAS ARRAY loop)
                 t40_any = if_any(starts_with("RAXSCD"), ~ substr(nodot(.x), 1, 4) %in% t40),
                 suicide         = (u3 >= "X60" & u3 <= "X84") | substr(ucod, 1, 4) == "Y870" | u3 == "U03",
                 overdose        = (u3 >= "X40" & u3 <= "X44") | (u3 >= "Y10" & u3 <= "Y14"),
                 overdose_opioid = overdose & t40_any)

outcomes <- c("suicide", "overdose", "overdose_opioid")

cases <- deaths %>%
  filter(suicide | overdose) %>%
  mutate(IndustryLit   = INDUSTL,
         OccupationLIt = OCCUPL)

flagged <- colSums(deaths[outcomes])


# ---------------------------------------------------------------------------
# 4. Code industry and occupation text with CDC NIOCCS
#    One web call per text pair not already in the cache. Each reply is saved as it arrives.
#    A reply that is not JSON is not saved, so it is retried next run.
# ---------------------------------------------------------------------------

cache_file <- file.path(cache_dir, "nioccs_cache_v3.csv")

if (file.exists(cache_file)) {
  cache <- read_csv(cache_file, col_types = cols(.default = "c"), na = character())
} else {
  cache <- tibble(IndustryLit = character(), OccupationLIt = character(),
                  NAICSCode = character(), SOCCode = character(), raw = character())
}

todo <- cases %>%
  distinct(IndustryLit, OccupationLIt) %>%
  filter(IndustryLit != "" | OccupationLIt != "") %>%
  anti_join(cache, by = c("IndustryLit", "OccupationLIt"))

if (nrow(todo) > 0) message("NIOCCS: sending ", nrow(todo), " new text pairs")

n_unusable <- 0
for (i in seq_len(nrow(todo))) {
  r     <- GET("https://wwwn.cdc.gov/nioccs/IOCode?",
               query = list(i = todo$IndustryLit[i], o = todo$OccupationLIt[i], c = 2))
  reply <- content(r, as = "text", encoding = "UTF-8")

  usable <- status_code(r) == 200 && validate(reply)
  if (usable) j <- fromJSON(reply)
  if (!usable || length(j$Industry) == 0) {
    message("NIOCCS reply not usable, not saved: ", substr(reply, 1, 80))
    n_unusable <- n_unusable + 1
    next
  }

  row <- tibble(IndustryLit   = todo$IndustryLit[i],
                OccupationLIt = todo$OccupationLIt[i],
                NAICSCode     = as.character(c(j$Industry$NAICSCode, "")[1]),
                SOCCode       = as.character(c(j$Occupation$SOCCode, "")[1]),
                raw           = reply)
  write_csv(row, cache_file, append = file.exists(cache_file))
  cache <- bind_rows(cache, row)
  if (i %% 200 == 0) message("  ", i, " of ", nrow(todo))
  Sys.sleep(0.2)
}

cache <- cache %>%
  distinct(IndustryLit, OccupationLIt, .keep_all = TRUE) %>%
  select(IndustryLit, OccupationLIt, NAICSCode, SOCCode)


# ---------------------------------------------------------------------------
# 5. Group the codes (Chris's 2-digit rules, applied to both the deaths and the PUMS workers)
#    NIOCCS placeholder codes seen in our replies:
#      industry 0096xx or 0097xx, occupation 00-98xx      = armed forces
#      industry 009890, occupation 00-90xx or 00-91xx     = not in workforce (homemaker, student, retired, never worked)
#      industry 009990, occupation 00-9900                 = insufficient information
#    Military, Not in workforce and Not coded get counts but no rate.
# ---------------------------------------------------------------------------

sector_of <- function(code) {
  two <- substr(code, 1, 2)
  case_when(two %in% c("31", "32", "33", "3M") ~ "31-33",
            two %in% c("44", "45", "4M")       ~ "44-45",
            two %in% c("48", "49")             ~ "48-49",
            TRUE                               ~ two)
}

sectors <- c("11", "21", "22", "23", "31-33", "42", "44-45", "48-49", "51", "52",
             "53", "54", "55", "56", "61", "62", "71", "72", "81", "92")
socgrps <- c("11", "13", "15", "17", "19", "21", "23", "25", "27", "29", "31",
             "33", "35", "37", "39", "41", "43", "45", "47", "49", "51", "53")

nonwork_words <- "homemaker|housewife|student|retired|unemployed|never worked|never employed|disabled|disability"

cases <- left_join(cases, cache, by = c("IndustryLit", "OccupationLIt"))

cases <- mutate(cases,
                naics  = coalesce(NAICSCode, ""),
                soc    = coalesce(SOCCode, ""),
                sector = sector_of(naics),
                socgrp = substr(soc, 1, 2),
                military  = substr(naics, 1, 4) %in% c("0096", "0097") |
                            substr(soc, 1, 5) == "00-98" |
                            socgrp == "55",
                nonworker = !military & (naics == "009890" |
                                         substr(soc, 1, 5) %in% c("00-90", "00-91") |
                                         grepl(nonwork_words, tolower(paste(IndustryLit, OccupationLIt)))),
                ind_group = case_when(military            ~ "Military",
                                      sector %in% sectors ~ sector,
                                      nonworker           ~ "Not in workforce",
                                      TRUE                ~ "Not coded"),
                occ_group = case_when(military            ~ "Military",
                                      socgrp %in% socgrps ~ socgrp,
                                      nonworker           ~ "Not in workforce",
                                      TRUE                ~ "Not coded"))

nonrate <- c("Military", "Not in workforce", "Not coded")


# ---------------------------------------------------------------------------
# 6. Denominators: ACS 5-year PUMS, Nebraska, civilian employed aged 16 to 64
#    Chris's Workforce Estimates tool: get_pums, ESR in 1 or 2, persons = PWGTP, FTE = PWGTP x WKHP / 40.
#    Pulled once and saved to Cache; point estimates only (no replicate weights).
# ---------------------------------------------------------------------------

pums_file <- file.path(cache_dir, paste0("pums_ne_5y_", pums_year, ".csv"))

if (!file.exists(pums_file)) {
  pull <- tryCatch(
    tidycensus::get_pums(variables = c("AGEP", "SEX", "NAICSP", "SOCP", "WKHP", "ESR"),
                         state = "NE", survey = "acs5", year = pums_year),
    error = function(e) NULL)
  if (is.null(pull)) {
    message("PUMS ", pums_year, " 5-year not available through tidycensus; using ", pums_year - 1)
    pums_year <- pums_year - 1
    pums_file <- file.path(cache_dir, paste0("pums_ne_5y_", pums_year, ".csv"))
    pull <- tidycensus::get_pums(variables = c("AGEP", "SEX", "NAICSP", "SOCP", "WKHP", "ESR"),
                                 state = "NE", survey = "acs5", year = pums_year)
  }
  write_csv(select(pull, AGEP, SEX, NAICSP, SOCP, WKHP, ESR, PWGTP), pums_file)
}

pums <- read_csv(pums_file, col_types = cols(.default = "c", AGEP = "i", WKHP = "d", PWGTP = "d"))

workers <- pums %>%
  filter(ESR %in% c("1", "2"), AGEP >= age_lo, AGEP <= age_hi) %>%
  mutate(sex      = ifelse(SEX == "1", "M", "F"),
         age_band = cut(AGEP, breaks = age_bands, right = FALSE,
                        labels = paste0(head(age_bands, -1), "-", tail(age_bands, -1) - 1)),
         persons  = PWGTP,
         fte      = PWGTP * WKHP / 40,
         ind_group = sector_of(NAICSP),
         occ_group = substr(SOCP, 1, 2))

n_workers_unmapped_ind <- sum(workers$persons[!workers$ind_group %in% sectors])
n_workers_unmapped_occ <- sum(workers$persons[!workers$occ_group %in% socgrps])

# Denominator table: one row per group x stratum, where stratum is a sex (M, F, T) or an age band.
den_for <- function(group_var) {
  w <- mutate(workers, group = .data[[group_var]])
  by_sex  <- w %>% group_by(group, stratum = sex) %>% summarise(persons = sum(persons), fte = sum(fte), .groups = "drop")
  total   <- w %>% group_by(group) %>% summarise(stratum = "T", persons = sum(persons), fte = sum(fte), .groups = "drop")
  by_age  <- w %>% group_by(group, stratum = as.character(age_band)) %>% summarise(persons = sum(persons), fte = sum(fte), .groups = "drop")
  d <- bind_rows(by_sex, total, by_age)
  all_workers <- d %>% group_by(stratum) %>% summarise(group = "All workers", persons = sum(persons), fte = sum(fte), .groups = "drop")
  bind_rows(d, all_workers)
}


# ---------------------------------------------------------------------------
# 7. Rates per 100,000 worker-years (persons x years, and FTE x years)
#    Exact Poisson 95% CI on the person rate.
# ---------------------------------------------------------------------------

rate_table <- function(outcome, group_var, yrs) {

  d <- cases %>%
    filter(.data[[outcome]], year %in% yrs) %>%
    mutate(group = .data[[group_var]])

  # Each death counted under its sex, under T, and under its age band.
  d <- bind_rows(mutate(d, stratum = sex),
                 mutate(d, stratum = "T"),
                 mutate(d, stratum = as.character(age_band))) %>%
    filter(stratum != "U")                      # unknown sex is in the T rows only

  by_group <- count(d, group, stratum, name = "deaths")

  all_workers <- d %>%
    filter(!group %in% nonrate) %>%
    count(stratum, name = "deaths") %>%
    mutate(group = "All workers")

  counts <- bind_rows(by_group, all_workers)

  den <- den_for(group_var) %>%
    filter(group %in% c(sectors, socgrps, "All workers"))

  out <- full_join(den, counts, by = c("group", "stratum"))

  out <- mutate(out,
                outcome  = outcome,
                grouping = ifelse(group_var == "ind_group", "industry", "occupation"),
                years    = paste(min(yrs), max(yrs), sep = "-"),
                deaths   = coalesce(deaths, 0L),
                persons  = ifelse(group %in% nonrate, NA, persons),
                fte      = ifelse(group %in% nonrate, NA, fte),
                person_years = persons * length(yrs),
                fte_years    = fte * length(yrs),
                rate     = deaths / person_years * 100000,
                rate_lo  = ifelse(deaths == 0, 0, qchisq(0.025, 2 * deaths) / 2) / person_years * 100000,
                rate_hi  = qchisq(0.975, 2 * deaths + 2) / 2 / person_years * 100000,
                rate_fte = deaths / fte_years * 100000)

  out %>%
    select(outcome, grouping, years, group, stratum, deaths, persons, fte,
           person_years, fte_years, rate, rate_lo, rate_hi, rate_fte) %>%
    arrange(stratum, group)
}

tables <- NULL
for (o in outcomes) {
  tables <- bind_rows(tables,
                      rate_table(o, "ind_group", years),
                      rate_table(o, "occ_group", years))
}

# Suicide by sector for 2020-2021 only, beside the NEVDRS sector sheet counts (84 / 72 / 55).
recon <- rate_table("suicide", "ind_group", 2020:2021) %>%
  filter(stratum == "T") %>%
  mutate(nevdrs_sheet = case_when(group == "Not in workforce" ~ 84,
                                  group == "23"               ~ 72,
                                  group == "31-33"            ~ 55))


# ---------------------------------------------------------------------------
# 8. Checks, then write
# ---------------------------------------------------------------------------

sums <- tables %>%
  filter(stratum == "T", group != "All workers") %>%
  count(outcome, grouping, wt = deaths, name = "table_rows") %>%
  mutate(flagged = flagged[outcome], ok = table_rows == flagged)

sink(file.path(cache_dir, paste0("qa_", stamp, ".txt")), split = TRUE)

print(c(rows_read = n_rows_read, duplicate_certificates_dropped = n_duplicates, unknown_age = n_unknown_age,
        nioccs_replies_not_usable = n_unusable,
        text_pairs_not_in_cache = nrow(anti_join(todo, cache, by = c("IndustryLit", "OccupationLIt")))))
print(deaths %>% group_by(year) %>% summarise(deaths_16plus = n(), suicide = sum(suicide),
                                              overdose = sum(overdose), overdose_opioid = sum(overdose_opioid)))
print(count(cases, ind_group), n = 30)
print(c(pums_year = pums_year, civilian_employed_16plus = sum(workers$persons), fte_16plus = round(sum(workers$fte)),
        workers_with_unmapped_industry = n_workers_unmapped_ind, workers_with_unmapped_occupation = n_workers_unmapped_occ))
print(sums)
print(recon %>% filter(!is.na(nevdrs_sheet)) %>% select(group, deaths, rate, rate_fte, nevdrs_sheet))

sink()

if (!all(sums$ok)) stop("Table rows do not add up to the flagged cases; see Cache/qa_", stamp, ".txt")

write_csv(tables, file.path(out_dir, paste0("io_death_rates_v9_", stamp, ".csv")), na = "")
write_csv(recon,  file.path(out_dir, paste0("suicide_2020_2021_vs_nevdrs_v9_", stamp, ".csv")), na = "")

# Record level: Cache only.
cases %>%
  select(DOD_YR, CERTNUM, sex, age, all_of(outcomes), IndustryLit, OccupationLIt, NAICSCode, SOCCode, ind_group, occ_group) %>%
  write_csv(file.path(cache_dir, paste0("cases_v9_", stamp, ".csv")), na = "")

message("Done. Tables in ", out_dir, "; QA and case list in ", cache_dir)
