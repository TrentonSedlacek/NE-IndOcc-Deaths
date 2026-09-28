# =====================================================================
# tests/synthetic_run.R
# Runs scripts/io_death_rates.R end to end on FAKE data, with no network:
#   - Guardian-shaped exports for 2020-2024 (CSV, and xlsx for 2024)
#   - a fake NIOCCS cache (run_nioccs = FALSE, so no CDC calls)
#   - fake ACS C24030 / C24010 CSVs in the fetch_acs_denominators.py format
# Every record is invented. Nothing here comes from a real certificate.
#
# Run from the repo root:  Rscript tests/synthetic_run.R
# Exits with an error if any check fails.
# =====================================================================
suppressPackageStartupMessages({ library(dplyr); library(readr); library(jsonlite) })
set.seed(20260928)

root <- file.path(tempdir(), "io_synthetic")
unlink(root, recursive = TRUE)
dirs <- list(dc = file.path(root, "dc"), out = file.path(root, "Output"),
             cache = file.path(root, "Cache"), acs = file.path(root, "Denominators"))
for (d in dirs) dir.create(d, recursive = TRUE, showWarnings = FALSE)

# ---------------------------------------------------------------------
# 1. Fake Guardian exports
# ---------------------------------------------------------------------
keep_vars <- c("DeathCertificateId", "StateFileNumber", "EventYear", "DateOfDeath",
               "ResidingStateNchs", "NchsAge", "NchsAgeUnit", "Sex", "MannerDeath",
               "AcmeUnderlyingCode", paste0("D2Acme", 1:20), paste0("D2SmicarAxis", 1:20),
               "ImmedCauseDeath", "Consq1", "Consq2", "Consq3", "OtherSignificantConditions",
               "IndustryLit", "OccupationLIt", "IndustryCode", "OccupationCode")
extra_vars <- c("FirstName", "LastName", "DateOfBirth", "ResidingCity", "ResidenceCounty",
                "InjuryAtWork", "RecordStatus", "Education", "CountyCode")

io_pool <- tribble(~IndustryLit, ~OccupationLIt, ~IndustryCode,
  "CONSTRUCTION", "CARPENTER", "077",   "MEAT PACKING", "MEAT CUTTER", "118",
  "FARM", "FARMER", "017",              "HOSPITAL", "NURSE", "819",
  "", "STUDENT", "",                    "", "RETIRED", "",
  "US ARMY", "SOLDIER", "967",          "", "", "",
  "NEVER WORKED", "NEVER WORKED", "",   "TRUCKING", "TRUCK DRIVER", "617",
  "RETAIL", "CASHIER", "499",           "SCHOOL", "TEACHER", "786",
  "HOMEMAKER", "HOMEMAKER", "",         "UNKNOWN", "UNKNOWN", "",
  "RAILROAD", "CONDUCTOR", "607",       "CHILD CARE", "CHILD CARE WORKER", "847")
ucod_pool <- c("X70", "X72", "X74", "X84", "Y87.0", "U03", "X42", "X44", "Y12", "X64", "X45",
               "I21.9", "C34.1", "J44.9", "V89.2", "X47", "X85", "W19", "X60", "Y14")
text_pool <- c("acute fentanyl toxicity", "mixed drug intoxication", "carbon monoxide poisoning",
               "acute ethanol intoxication", "gunshot wound of head", "hanging",
               "atherosclerotic cardiovascular disease", "", NA)
tcode_pool <- c("T40.1", "T40.4", "T43.6", "T51.0", "T58", "T40.2", "T42.4")

blank_row <- function() as.list(setNames(rep(NA_character_, length(c(keep_vars, extra_vars))), c(keep_vars, extra_vars)))

make_row <- function(id, yr) {
  r <- blank_row()
  io <- io_pool[sample(nrow(io_pool), 1), ]
  unit <- sample(c(1, 1, 1, 1, 1, 1, 2, 3, 4, 5, 6, 9), 1)
  r$DeathCertificateId <- id; r$StateFileNumber <- paste0("SFN", id); r$EventYear <- as.character(yr)
  r$DateOfDeath <- sprintf("%d-06-15", yr)
  r$ResidingStateNchs <- sample(c(rep("NE", 17), "IA", "KS", "ne"), 1)
  r$NchsAgeUnit <- as.character(unit)
  r$NchsAge <- as.character(switch(as.character(unit), "1" = sample(c(10:95, 999), 1), "2" = sample(1:230, 1),
                                   "3" = sample(1:60, 1), "9" = 999, sample(1:20, 1)))
  r$Sex <- sample(c("M", "M", "F", "U", "1", "2"), 1)
  r$MannerDeath <- sample(c("A", "N", "S", "H", "C", "P"), 1)
  r$AcmeUnderlyingCode <- sample(ucod_pool, 1)
  n_t <- sample(0:3, 1)
  if (n_t > 0) for (k in seq_len(n_t)) {
    r[[paste0("D2Acme", k)]] <- sample(tcode_pool, 1)
    r[[paste0("D2SmicarAxis", k + 1)]] <- sample(tcode_pool, 1)
  }
  r$ImmedCauseDeath <- sample(text_pool, 1); r$Consq1 <- sample(text_pool, 1)
  r$IndustryLit <- io$IndustryLit; r$OccupationLIt <- io$OccupationLIt; r$IndustryCode <- io$IndustryCode
  r$FirstName <- "FAKE"; r$LastName <- paste0("PERSON", id); r$RecordStatus <- "Registered"
  r
}

# Planted records with a known expected result (id -> expectation checked below).
planted <- list()
plant <- function(id, yr, ...) {
  r <- blank_row()
  r$DeathCertificateId <- id; r$EventYear <- as.character(yr); r$ResidingStateNchs <- "NE"
  r$NchsAge <- "40"; r$NchsAgeUnit <- "1"; r$Sex <- "M"; r$MannerDeath <- "A"
  r$IndustryLit <- "CONSTRUCTION"; r$OccupationLIt <- "CARPENTER"; r$IndustryCode <- "077"
  args <- list(...)
  for (nm in names(args)) r[[nm]] <- args[[nm]]
  planted[[id]] <<- list(row = r, file_year = yr)
}
plant("P01", 2022, AcmeUnderlyingCode = "X70", MannerDeath = "S")                       # suicide, sector 23, SOC 47
plant("P02", 2022, AcmeUnderlyingCode = "X70", ResidingStateNchs = "IA")                 # non-resident: out
plant("P03", 2022, AcmeUnderlyingCode = "X74", NchsAge = "200", NchsAgeUnit = "2")       # 16 years by months: in
plant("P04", 2022, AcmeUnderlyingCode = "X74", NchsAge = "999")                          # unknown age: out
plant("P05", 2022, AcmeUnderlyingCode = "X74", NchsAge = "15")                           # 15: out of 16+
plant("P06", 2022, AcmeUnderlyingCode = "X42", D2Acme3 = "T40.4")                        # overdose + opioid
plant("P07", 2022, AcmeUnderlyingCode = "", MannerDeath = "P", ImmedCauseDeath = "Acute Fentanyl Toxicity") # text-only overdose
plant("P08", 2022, AcmeUnderlyingCode = "X64", MannerDeath = "S", ImmedCauseDeath = "intentional overdose") # suicide, not overdose
plant("P09", 2022, AcmeUnderlyingCode = "X45", ImmedCauseDeath = "acute ethanol intoxication")   # not overdose
plant("P10", 2022, AcmeUnderlyingCode = "X47", ImmedCauseDeath = "carbon monoxide toxicity")     # not overdose
plant("P11", 2022, AcmeUnderlyingCode = "Y87.0")                                         # suicide
plant("P12", 2022, AcmeUnderlyingCode = "U03")                                           # suicide
plant("P13", 2022, AcmeUnderlyingCode = "UO3")                                           # letter O: not suicide
plant("P14", 2022, AcmeUnderlyingCode = "X85", D2SmicarAxis5 = "T40.1", MannerDeath = "H") # MA opioid only
plant("P15", 2021, AcmeUnderlyingCode = "X72", MannerDeath = "S")                        # also copied into 2022 file
plant("P16", 2020, AcmeUnderlyingCode = "X72", EventYear = "2019")                       # 2019 in 2020 file: out
plant("P17", 2022, AcmeUnderlyingCode = "X72", Sex = "1", IndustryLit = "US ARMY", OccupationLIt = "SOLDIER", IndustryCode = "967") # military
plant("P18", 2022, AcmeUnderlyingCode = "X72", IndustryLit = "", OccupationLIt = "STUDENT", IndustryCode = "") # not in workforce
plant("P19", 2022, AcmeUnderlyingCode = "X72", IndustryLit = "", OccupationLIt = "", IndustryCode = "")        # not coded
plant("P20", 2022, AcmeUnderlyingCode = "X72", IndustryLit = "CHILD CARE", OccupationLIt = "CHILD CARE WORKER", IndustryCode = "847") # sector 62, not NIW
plant("P21", 2022, AcmeUnderlyingCode = "I21.9", MannerDeath = "N", ImmedCauseDeath = "digoxin toxicity") # natural: not overdose

rows_by_file <- list()
for (yr in 2020:2024) {
  rows <- lapply(sprintf("%d%04d", yr, 1:40), make_row, yr = yr)
  rows_by_file[[as.character(yr)]] <- rows
}
for (p in planted) rows_by_file[[as.character(p$file_year)]] <- c(rows_by_file[[as.character(p$file_year)]], list(p$row))
# Overlap: 3 late 2020 deaths repeated in the 2021 file, and planted P15 repeated in 2022.
rows_by_file[["2021"]] <- c(rows_by_file[["2021"]], rows_by_file[["2020"]][1:3])
rows_by_file[["2022"]] <- c(rows_by_file[["2022"]], list(planted$P15$row))
# ROSTER placeholder rows with EventYear 0 in the 2021 export.
for (k in 1:5) { r <- blank_row(); r$DeathCertificateId <- paste0("ROSTER", k); r$EventYear <- "0"
  rows_by_file[["2021"]] <- c(rows_by_file[["2021"]], list(r)) }

for (yr in 2020:2024) {
  df <- bind_rows(lapply(rows_by_file[[as.character(yr)]], as_tibble))
  df <- df[sample(ncol(df))]                               # column order differs from the keep list
  dir.create(file.path(dirs$dc, yr), showWarnings = FALSE)
  if (yr == 2024) {
    writexl::write_xlsx(df, file.path(dirs$dc, yr, "DeathCertificates24.xlsx"))   # exercises the xlsx branch
  } else {
    write_csv(df, file.path(dirs$dc, yr, sprintf("DeathCertificates%02d.csv", yr %% 100)), na = "")
  }
}

# ---------------------------------------------------------------------
# 2. Fake NIOCCS cache (field names as the team's scripts use them)
# ---------------------------------------------------------------------
nioccs_reply <- tribble(~IndustryLit, ~OccupationLIt, ~NAICSCode, ~SOCCode,
  "CONSTRUCTION", "CARPENTER", "236118", "47-2031",   "MEAT PACKING", "MEAT CUTTER", "311611", "51-3023",
  "FARM", "FARMER", "111998", "11-9013",               "HOSPITAL", "NURSE", "622110", "29-1141",
  "", "STUDENT", "", "00-0000",                         "", "RETIRED", "999999", "00-0000",
  "US ARMY", "SOLDIER", "928110", "55-3016",            "NEVER WORKED", "NEVER WORKED", "", "",
  "TRUCKING", "TRUCK DRIVER", "484121", "53-3032",     "RETAIL", "CASHIER", "445110", "41-2011",
  "SCHOOL", "TEACHER", "611110", "25-2021",             "HOMEMAKER", "HOMEMAKER", "", "",
  "UNKNOWN", "UNKNOWN", "", "",                         "CHILD CARE", "CHILD CARE WORKER", "624410", "39-9011")
# RAILROAD / CONDUCTOR is left out on purpose: it should be reported as not yet coded.
cache <- nioccs_reply %>% rowwise() %>%
  mutate(raw = as.character(toJSON(list(Industry = list(list(NAICSCode = NAICSCode, Title = "x")),
                                        Occupation = list(SOCCode = SOCCode, Title = "y")), auto_unbox = TRUE))) %>% ungroup() %>%
  mutate(NAICSCode = "", SOCCode = "") %>% select(IndustryLit, OccupationLIt, NAICSCode, SOCCode, raw)   # codes blank on purpose: re-parsed from raw
write_csv(cache, file.path(dirs$cache, "nioccs_cache.csv"), na = "")

# ---------------------------------------------------------------------
# 3. Fake ACS tables, same shape and labels as the real C24030 / C24010
#    (labels as believed correct; see docs/script-audit.md)
# ---------------------------------------------------------------------
c24030_lines <- c("Agriculture, forestry, fishing and hunting, and mining:",
  "  Agriculture, forestry, fishing and hunting", "  Mining, quarrying, and oil and gas extraction",
  "Construction", "Manufacturing", "Wholesale trade", "Retail trade",
  "Transportation and warehousing, and utilities:", "  Transportation and warehousing", "  Utilities",
  "Information", "Finance and insurance, and real estate, and rental and leasing:",
  "  Finance and insurance", "  Real estate and rental and leasing",
  "Professional, scientific, and management, and administrative, and waste management services:",
  "  Professional, scientific, and technical services", "  Management of companies and enterprises",
  "  Administrative and support and waste management services",
  "Educational services, and health care and social assistance:", "  Educational services", "  Health care and social assistance",
  "Arts, entertainment, and recreation, and accommodation and food services:",
  "  Arts, entertainment, and recreation", "  Accommodation and food services",
  "Other services, except public administration", "Public administration")
c24010_lines <- c("Management, business, science, and arts occupations:",
  "  Management, business, and financial occupations:", "    Management occupations", "    Business and financial operations occupations",
  "  Computer, engineering, and science occupations:", "    Computer and mathematical occupations",
  "    Architecture and engineering occupations", "    Life, physical, and social science occupations",
  "  Education, legal, community service, arts, and media occupations:", "    Community and social service occupations",
  "    Legal occupations", "    Educational instruction, and library occupations",
  "    Arts, design, entertainment, sports, and media occupations",
  "  Healthcare practitioners and technical occupations:",
  "    Health diagnosing and treating practitioners and other technical occupations", "    Health technologists and technicians",
  "Service occupations:", "  Healthcare support occupations", "  Protective service occupations:",
  "    Firefighting and prevention, and other protective service workers including supervisors",
  "    Law enforcement workers including supervisors", "  Food preparation and serving related occupations",
  "  Building and grounds cleaning and maintenance occupations", "  Personal care and service occupations",
  "Sales and office occupations:", "  Sales and related occupations", "  Office and administrative support occupations",
  "Natural resources, construction, and maintenance occupations:", "  Farming, fishing, and forestry occupations",
  "  Construction and extraction occupations", "  Installation, maintenance, and repair occupations",
  "Production, transportation, and material moving occupations:", "  Production occupations",
  "  Transportation occupations", "  Material moving occupations")

# Build "Estimate!!Total:!!Male:!!Parent:!!Leaf" labels from the indented
# outline, give each leaf a random estimate, and make parents the sum.
fake_acs <- function(table_id, lines) {
  out <- tibble(label = "Estimate!!Total:", estimate = 0)
  for (sx in c("Male", "Female")) {
    out <- bind_rows(out, tibble(label = paste0("Estimate!!Total:!!", sx, ":"), estimate = 0))
    path <- character()
    for (ln in lines) {
      depth <- (nchar(ln) - nchar(sub("^ +", "", ln))) / 2
      name <- sub("^ +", "", ln)
      path <- c(path[seq_len(depth)], name)
      out <- bind_rows(out, tibble(label = paste0("Estimate!!Total:!!", sx, ":!!", paste(path, collapse = "!!")), estimate = 0))
    }
  }
  is_leaf <- sapply(out$label, function(l) !any(startsWith(out$label, paste0(l, "!!"))))
  out$estimate[is_leaf] <- sample(2000:60000, sum(is_leaf), replace = TRUE)
  for (i in which(!is_leaf)) out$estimate[i] <- sum(out$estimate[is_leaf & startsWith(out$label, paste0(out$label[i], "!!"))])
  out %>% mutate(table = table_id, dataset = "acs5", year = 2024,
                 variable = sprintf("%s_%03dE", table_id, row_number()), moe = round(sqrt(estimate) * 10)) %>%
    select(table, dataset, year, variable, label, estimate, moe)
}
acs_c24030 <- fake_acs("C24030", c24030_lines)
acs_c24010 <- fake_acs("C24010", c24010_lines)
stopifnot(nrow(acs_c24030) == 55, nrow(acs_c24010) == 73)   # 55 and 73 variables, as in the real tables
bind_rows(acs_c24030, acs_c24010) %>% mutate(variable = sub("E$", "", variable)) %>%
  select(variable, label, estimate, moe) %>% write_csv(file.path(dirs$cache, "acs_2024.csv"))

# ---------------------------------------------------------------------
# 4. Run the real script against the fake data
# ---------------------------------------------------------------------
options(io_death_rates.test_cfg = list(dc_dir = dirs$dc, out_dir = dirs$out, cache_dir = dirs$cache,
                                       acs_dir = dirs$acs, run_nioccs = FALSE))
files_before <- list.files(root, recursive = TRUE)
env <- new.env()
sys.source(file.path("scripts", "io_death_rates.R"), envir = env)

# ---------------------------------------------------------------------
# 5. Checks
# ---------------------------------------------------------------------
fails <- character()
check <- function(ok, what) { cat(ifelse(isTRUE(ok), "PASS ", "FAIL "), what, "\n"); if (!isTRUE(ok)) fails <<- c(fails, what) }
d <- env$deaths; cs <- env$cases
row_of <- function(id) d[d$DeathCertificateId == id, ]
grp <- function(id, col) cs[[col]][cs$DeathCertificateId == id]

check(nrow(row_of("P01")) == 1 && row_of("P01")$suicide, "P01 X70 is a suicide")
check(nrow(row_of("P02")) == 0, "P02 non-resident dropped")
check(nrow(row_of("P05")) == 0, "P05 age 15 dropped")
check(row_of("P06")$overdose && row_of("P06")$overdose_opioid, "P06 X42 + T40.4 = overdose, opioid")
check(row_of("P07")$overdose && row_of("P07")$overdose_text_only, "P07 text-only overdose counted and flagged")
check(row_of("P08")$suicide && !row_of("P08")$overdose, "P08 X64 suicide by overdose is suicide, not SUDORS overdose")
check(!row_of("P09")$overdose, "P09 ethanol only is not an overdose")
check(!row_of("P10")$overdose, "P10 carbon monoxide is not an overdose")
check(row_of("P11")$suicide, "P11 Y87.0 with a dot is a suicide")
check(row_of("P12")$suicide, "P12 U03 is a suicide")
check(!row_of("P13")$suicide, "P13 UO3 (letter O) is not a suicide")
check(sum(d$DeathCertificateId == "P15") == 1, "P15 overlap copy counted once")
check(nrow(row_of("P16")) == 0, "P16 year 2019 dropped")
check(!any(grepl("^ROSTER", d$DeathCertificateId)), "ROSTER rows dropped")
check(row_of("P17")$sex == "M", "P17 Sex 1 = M")
check(grp("P17", "ind_group") == "Military", "P17 US ARMY = Military")
check(grp("P18", "ind_group") == "Not in workforce", "P18 STUDENT = Not in workforce")
check(grp("P19", "ind_group") == "Not coded", "P19 blank text = Not coded")
check(grp("P20", "ind_group") == "62", "P20 CHILD CARE = sector 62, not Not in workforce")
check(!row_of("P21")$overdose, "P21 natural digoxin toxicity is not an overdose")
check(grp("P01", "ind_group") == "23" && grp("P01", "occ_group") == "47", "P01 sector 23, SOC 47")
check(env$qa$text_pairs_not_yet_coded >= 1, "uncached pair (RAILROAD) reported as not yet coded")
check(isTRUE(env$qa$group_rows_sum_to_totals), "group rows add up to case totals in every table")
check(n_distinct(env$den_ind$group) == 21 && n_distinct(env$den_occ$group) == 23, "20 sectors and 22 SOC groups plus All workers")
check(env$den_ind$workers[env$den_ind$group == "All workers" & env$den_ind$sex == "T"] == env$acs_total_ind, "ACS industry leaves add to C24030_001")
check(env$den_occ$workers[env$den_occ$group == "All workers" & env$den_occ$sex == "T"] == env$acs_total_occ, "ACS occupation leaves add to C24010_001")
t <- env$tables_raw$suicide_industry %>% filter(sex == "T", group == "All workers")
check(abs(t$rate - t$deaths / (t$workers * 5) * 1e5) < 1e-9, "rate = deaths / (workers x 5) x 100,000")
check(abs(t$rate_lo - qchisq(0.025, 2 * t$deaths) / 2 / (t$workers * 5) * 1e5) < 1e-9, "exact Poisson lower limit")
pct <- env$tables_raw$suicide_industry %>% filter(sex == "M", group != "All workers") %>% pull(pct_of_deaths)
check(abs(sum(pct) - 100) < 1e-9, "percent of deaths sums to 100 within a sex")
check("injury_at_work_industry" %in% names(env$tables) && "pneumoconiosis_occupation" %in% names(env$tables), "extra outcomes from the table are produced")

outs <- list.files(dirs$out, pattern = "\\.csv$", full.names = TRUE)
all_out <- bind_rows(lapply(outs, read_csv, show_col_types = FALSE, col_types = cols(.default = "c")))
dn <- suppressWarnings(as.numeric(all_out$deaths))
check(any(dn >= 1 & dn <= 5, na.rm = TRUE), "small counts are written, not suppressed")
check(all(is.na(all_out$rate[all_out$group %in% c("Military", "Not in workforce", "Not coded")])), "no rate on non-rate rows")
new_files <- setdiff(list.files(root, recursive = TRUE), files_before)
check(all(startsWith(new_files, "Cache/") | startsWith(new_files, "Output/")), "script wrote only to Output and Cache")
check(!any(grepl("DeathCertificateId|PERSON", unlist(lapply(outs, readLines)))), "no certificate ids or names in Output")

cat("\n", length(fails), "failures\n")
if (length(fails) > 0) stop("Synthetic run failed: ", paste(fails, collapse = "; "))
