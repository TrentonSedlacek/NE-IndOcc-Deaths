# io_death_rates_v7.R
# Suicide rates by industry and occupation, Nebraska residents aged 16 and over, 2020 to 2024.
#
# v7 (2026-09-28): suicide only, and rewritten for readability. Same numbers as v6.
#
# What it does, step by step:
#   1. Reads the yearly death certificate exports.
#   2. Keeps one row per certificate, Nebraska residents, aged 16 and over.
#   3. Flags suicides (underlying cause X60 to X84, Y87.0, or U03; NE DHHS suicide dashboard definition).
#   4. Sends each distinct industry and occupation text to CDC NIOCCS for a NAICS and SOC code.
#      Replies are saved in Cache/nioccs_cache_v3.csv so each text pair is sent only once.
#   5. Groups the codes into the 20 NAICS sectors and 22 SOC major groups used by the ACS.
#   6. Gets ACS 2020-2024 5-year civilian employed workers by sex (tables C24030 and C24010).
#   7. Rates per 100,000 worker-years (workers x 5 years) with exact Poisson 95% confidence intervals,
#      as in the Massachusetts DPH industry and occupation reports.
#   8. Prints checks, writes the tables.
#
# No suppression anywhere. Record-level files go to Cache only; Output has group tables only.
#
# How to run:  source("C:/Users/tsedlac/Downloads/io_death_rates_v7.R")
# Needs in C:/Users/tsedlac/Downloads:  acs_group_map.csv
# Reuses if present:  Cache/nioccs_cache_v3.csv  and  Cache/acs_2024.csv

library(readxl)
library(readr)
library(dplyr)
library(httr)
library(jsonlite)


# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------

years    <- 2020:2024
dc_dir   <- getOption("io_v5_dc_dir",   "K:/Occupational Health Grant/data/dc")
work_dir <- getOption("io_v5_work_dir", "C:/Users/tsedlac/Downloads")

out_dir   <- file.path(work_dir, "Output")
cache_dir <- file.path(work_dir, "Cache")
stamp     <- format(Sys.Date(), "%Y%m%d")

dir.create(out_dir,   showWarnings = FALSE)
dir.create(cache_dir, showWarnings = FALSE)


# ---------------------------------------------------------------------------
# 1. Read the yearly exports
#    Each year is K:/.../dc/{YYYY}/DeathCertificates{YY}.csv or .xlsx.
#    Every column is read as text. The export year is kept for step 2.
# ---------------------------------------------------------------------------

keep <- c("DeathCertificateId", "DateOfDeath", "DateOfBirth", "ResidingStateNchs",
          "Sex", "MannerDeath", "AcmeUnderlyingCode", "IndustryLit", "OccupationLIt")

dc <- NULL
for (yr in years) {
  stem <- file.path(dc_dir, yr, paste0("DeathCertificates", yr %% 100))
  if (file.exists(paste0(stem, ".csv"))) {
    one <- read_csv(paste0(stem, ".csv"), col_types = cols(.default = "c"), na = "")
  } else {
    one <- read_excel(paste0(stem, ".xlsx"), col_types = "text")
  }
  one <- select(one, any_of(keep))
  one$export <- yr
  dc <- bind_rows(dc, one)
}

# Dates arrive as Excel serial numbers (45291 = 2023-12-31) in some years and as text in others.
to_date <- function(x) {
  serial <- suppressWarnings(as.numeric(x))
  d <- as.Date(floor(serial), origin = "1899-12-30")
  d[is.na(d)] <- as.Date(x[is.na(d)], format = "%m/%d/%Y")     # 1/31/2021
  d[is.na(d)] <- as.Date(x[is.na(d)], format = "%Y-%m-%d")     # 2021-01-31
  d
}


# ---------------------------------------------------------------------------
# 2. One row per certificate; Nebraska residents; aged 16 and over
#    Exports overlap (late registrations appear again next year). The later
#    export has the final cause of death, so it wins.
#    EventYear and NchsAge are 0 in these exports, so year and age come from the dates.
# ---------------------------------------------------------------------------

n_blank_id <- sum(is.na(dc$DeathCertificateId) | dc$DeathCertificateId == "")
dc <- filter(dc, !is.na(DeathCertificateId), DeathCertificateId != "")

dc <- mutate(dc,
             dod  = to_date(DateOfDeath),
             dob  = to_date(DateOfBirth),
             year = as.integer(format(dod, "%Y")))

deaths <- dc %>%
  arrange(DeathCertificateId, desc(export)) %>%
  distinct(DeathCertificateId, .keep_all = TRUE)

n_overlap  <- nrow(dc) - nrow(deaths)
n_bad_dod  <- sum(is.na(deaths$dod) & !is.na(deaths$DateOfDeath))
n_bad_dob  <- sum(is.na(deaths$dob) & !is.na(deaths$DateOfBirth))

deaths <- mutate(deaths,
                 age = trunc(as.numeric(dod - dob) / 365.25),
                 sex = case_when(toupper(substr(Sex, 1, 1)) %in% c("M", "1") ~ "M",
                                 toupper(substr(Sex, 1, 1)) %in% c("F", "2") ~ "F",
                                 TRUE ~ "U"))

deaths <- filter(deaths,
                 year %in% years,
                 toupper(ResidingStateNchs) == "NE",
                 age >= 16)


# ---------------------------------------------------------------------------
# 3. Flag suicides
#    Underlying cause X60 to X84, Y87.0 (sequelae of self harm), or U03 (terrorism, self harm).
#    Codes lose their dot first, so "Y87.0" and "Y870" both match.
# ---------------------------------------------------------------------------

deaths <- mutate(deaths,
                 ucod = toupper(gsub("[. ]", "", coalesce(AcmeUnderlyingCode, ""))),
                 u3   = substr(ucod, 1, 3),
                 suicide = (u3 >= "X60" & u3 <= "X84") | substr(ucod, 1, 4) == "Y870" | u3 == "U03")

cases <- deaths %>%
  filter(suicide) %>%
  mutate(IndustryLit   = coalesce(IndustryLit, ""),
         OccupationLIt = coalesce(OccupationLIt, ""))

n_suicides <- nrow(cases)


# ---------------------------------------------------------------------------
# 4. Code industry and occupation text with CDC NIOCCS
#    One web call per text pair not already in the cache (the team's GET.R call).
#    Each reply is saved as it arrives. A reply that is not JSON is not saved, so it is retried next run.
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

n_unusable <- 0
for (i in seq_len(nrow(todo))) {
  r     <- GET("https://wwwn.cdc.gov/nioccs/IOCode?",
               query = list(i = todo$IndustryLit[i], o = todo$OccupationLIt[i], c = 2))
  reply <- content(r, as = "text", encoding = "UTF-8")

  usable <- status_code(r) == 200 && validate(reply)
  if (usable) j <- fromJSON(reply)
  if (!usable || is.null(j$Industry)) {
    message("NIOCCS reply not usable, not saved: ", substr(reply, 1, 80))
    n_unusable <- n_unusable + 1
    next
  }

  row <- tibble(IndustryLit   = todo$IndustryLit[i],
                OccupationLIt = todo$OccupationLIt[i],
                NAICSCode     = as.character(c(j$Industry$NAICSCode, "")[1]),    # first code, or "" if none
                SOCCode       = as.character(c(j$Occupation$SOCCode, "")[1]),
                raw           = reply)
  write_csv(row, cache_file, append = file.exists(cache_file))
  cache <- bind_rows(cache, row)
  Sys.sleep(0.2)
}

cache <- cache %>%
  distinct(IndustryLit, OccupationLIt, .keep_all = TRUE) %>%
  select(IndustryLit, OccupationLIt, NAICSCode, SOCCode)


# ---------------------------------------------------------------------------
# 5. Group the codes
#    Industry sector = first 2 digits of NAICS (31-33, 44-45, 48-49 combined, as the ACS does).
#    Occupation group = first 2 digits of SOC.
#    NIOCCS placeholder codes (seen in our replies):
#      industry 0096xx or 0097xx, occupation 00-98xx        = armed forces
#      industry 009890, occupation 00-90xx or 00-91xx       = not in workforce (homemaker, student, retired, never worked)
#      industry 009990, occupation 00-9900                   = insufficient information
#    Military, Not in workforce and Not coded get counts but no rate (no ACS denominator).
# ---------------------------------------------------------------------------

acs_map <- read_csv(file.path(work_dir, "acs_group_map.csv"), col_types = cols(.default = "c"))
sectors <- acs_map$group[acs_map$table == "C24030"]
socgrps <- acs_map$group[acs_map$table == "C24010"]

nonwork_words <- "homemaker|housewife|student|retired|unemployed|never worked|never employed|disabled|disability"

cases <- left_join(cases, cache, by = c("IndustryLit", "OccupationLIt"))

cases <- mutate(cases,
                naics  = coalesce(NAICSCode, ""),
                soc    = coalesce(SOCCode, ""),
                n2     = substr(naics, 1, 2),
                socgrp = substr(soc, 1, 2),
                sector = case_when(n2 %in% c("31", "32", "33") ~ "31-33",
                                   n2 %in% c("44", "45")       ~ "44-45",
                                   n2 %in% c("48", "49")       ~ "48-49",
                                   TRUE                        ~ n2),
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
# 6. ACS denominators: civilian employed aged 16 and over, Nebraska, 2020-2024 5-year
#    C24030 = sex by industry, C24010 = sex by occupation. Pulled once with tidycensus
#    (key from the CENSUS_API_KEY environment variable), then reused from Cache/acs_2024.csv.
#    Each ACS row label ends in a name such as "Construction"; acs_group_map.csv maps that name to a group.
# ---------------------------------------------------------------------------

acs_file <- file.path(cache_dir, "acs_2024.csv")

if (!file.exists(acs_file)) {
  vars <- tidycensus::load_variables(2024, "acs5")
  vars <- filter(vars, substr(name, 1, 7) %in% c("C24030_", "C24010_"))
  pull <- tidycensus::get_acs("state", state = "NE", variables = vars$name,
                              year = 2024, survey = "acs5", key = Sys.getenv("CENSUS_API_KEY"))
  pull <- left_join(pull, vars, by = c("variable" = "name"))
  write_csv(select(pull, variable, label, estimate, moe), acs_file)
}

acs <- read_csv(acs_file, col_types = cols(.default = "c", estimate = "d"))

acs <- mutate(acs,
              table     = substr(variable, 1, 6),
              leaf_name = sub(":$", "", sub(".*!!", "", label)),   # last piece of the label
              parent    = sub("!![^!]*$", "", label),              # label with the last piece removed
              sex       = case_when(grepl("!!Male", label)   ~ "M",
                                    grepl("!!Female", label) ~ "F",
                                    TRUE                     ~ "T"))

# A leaf is a row that no other row hangs under. Every leaf must be in the map, or the run stops.
leaves   <- filter(acs, !label %in% parent, sex != "T")
unmapped <- anti_join(leaves, acs_map, by = c("table", "leaf_name"))
if (nrow(unmapped) > 0) {
  stop("ACS rows not in acs_group_map.csv: ", paste(unique(unmapped$leaf_name), collapse = "; "))
}

den <- leaves %>%
  inner_join(acs_map, by = c("table", "leaf_name")) %>%
  group_by(table, group, sex) %>%
  summarise(workers = sum(estimate), .groups = "drop")

den_total_sex <- den %>%
  group_by(table, group) %>%
  summarise(sex = "T", workers = sum(workers), .groups = "drop")

den <- bind_rows(den, den_total_sex)

den_all_workers <- den %>%
  group_by(table, sex) %>%
  summarise(group = "All workers", workers = sum(workers), .groups = "drop")

den <- bind_rows(den, den_all_workers)

# The mapped groups must add back to the ACS table totals.
acs_totals <- acs %>%
  filter(variable %in% c("C24030_001", "C24010_001")) %>%
  select(table, acs_total = estimate)

acs_check <- den %>%
  filter(group == "All workers", sex == "T") %>%
  left_join(acs_totals, by = "table")


# ---------------------------------------------------------------------------
# 7. Rates per 100,000 worker-years, exact Poisson 95% CI, by sex M, F and T
# ---------------------------------------------------------------------------

rate_table <- function(group_var, acs_table, yrs) {

  d <- cases %>%
    filter(year %in% yrs) %>%
    mutate(group = .data[[group_var]])

  # Each death is counted once under its own sex and once under T.
  d <- bind_rows(d, mutate(d, sex = "T"))

  by_group <- count(d, group, sex, name = "deaths")

  all_workers <- d %>%
    filter(!group %in% nonrate) %>%
    count(sex, name = "deaths") %>%
    mutate(group = "All workers")

  counts <- bind_rows(by_group, all_workers) %>%
    filter(sex != "U")                                  # sex U deaths are in the T rows only

  workers <- den %>%
    filter(table == acs_table) %>%
    select(group, sex, workers)

  out <- full_join(workers, counts, by = c("group", "sex"))

  out <- mutate(out,
                grouping     = ifelse(acs_table == "C24030", "industry", "occupation"),
                years        = paste(min(yrs), max(yrs), sep = "-"),
                deaths       = coalesce(deaths, 0L),
                worker_years = ifelse(group %in% nonrate, NA, workers * length(yrs)),
                rate         = deaths / worker_years * 100000,
                rate_lo      = ifelse(deaths == 0, 0, qchisq(0.025, 2 * deaths) / 2) / worker_years * 100000,
                rate_hi      = qchisq(0.975, 2 * deaths + 2) / 2 / worker_years * 100000)

  out <- out %>%
    group_by(sex) %>%
    mutate(pct_of_deaths = 100 * deaths / sum(deaths[group != "All workers"])) %>%
    ungroup()

  out %>%
    select(grouping, years, group, sex, deaths, pct_of_deaths, workers, worker_years, rate, rate_lo, rate_hi) %>%
    arrange(sex, group)
}

by_industry   <- rate_table("ind_group", "C24030", years)
by_occupation <- rate_table("occ_group", "C24010", years)
tables        <- bind_rows(by_industry, by_occupation)

# Suicide by sector for 2020-2021 only, beside the NEVDRS sector sheet (84 not in workforce, 72 construction,
# 55 manufacturing). Compare the counts; the rates here use the 2020-2024 ACS, so they are approximate.
recon <- rate_table("ind_group", "C24030", 2020:2021) %>%
  filter(sex == "T") %>%
  mutate(nevdrs_sheet = case_when(group == "Not in workforce" ~ 84,
                                  group == "23"               ~ 72,
                                  group == "31-33"            ~ 55))


# ---------------------------------------------------------------------------
# 8. Checks, then write
# ---------------------------------------------------------------------------

sums <- tables %>%
  filter(sex == "T", group != "All workers") %>%
  count(grouping, wt = deaths, name = "table_rows") %>%
  mutate(flagged = n_suicides, ok = table_rows == flagged)

sink(file.path(cache_dir, paste0("qa_", stamp, ".txt")), split = TRUE)

print(c(blank_id_rows_dropped   = n_blank_id,
        overlap_copies_dropped  = n_overlap,
        unreadable_DateOfDeath  = n_bad_dod,
        unreadable_DateOfBirth  = n_bad_dob,
        nioccs_replies_not_usable = n_unusable,
        text_pairs_not_in_cache = nrow(anti_join(todo, cache, by = c("IndustryLit", "OccupationLIt")))))

print(deaths %>% group_by(year) %>% summarise(deaths_16plus = n(), suicides = sum(suicide)))
print(count(cases, ind_group), n = 30)
print(acs_check)
print(sums)
print(recon %>% filter(!is.na(nevdrs_sheet)) %>% select(group, deaths, rate, nevdrs_sheet))

sink()

acs_ok <- all(abs(acs_check$workers - acs_check$acs_total) < 0.5)
if (!acs_ok || !all(sums$ok)) {
  stop("A check failed; see Cache/qa_", stamp, ".txt")
}

write_csv(tables, file.path(out_dir, paste0("suicide_io_rates_", stamp, ".csv")), na = "")
write_csv(recon,  file.path(out_dir, paste0("suicide_2020_2021_vs_nevdrs_", stamp, ".csv")), na = "")

# Record level: Cache only.
cases %>%
  select(DeathCertificateId, year, sex, age, IndustryLit, OccupationLIt, NAICSCode, SOCCode, ind_group, occ_group) %>%
  write_csv(file.path(cache_dir, paste0("suicide_cases_", stamp, ".csv")), na = "")

message("Done. Tables in ", out_dir, "; QA and case list in ", cache_dir)
