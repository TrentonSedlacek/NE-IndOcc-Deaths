# tests/synthetic_run.R
# Runs scripts/io_death_rates_v5.R end to end on FAKE data, with no network:
#   - Guardian-shaped exports 2020-2024 made to look like the real ones: EventYear and NchsAge 0 on every row,
#     dates as Excel serial strings (2020, 2023; "45291.0" style in 2022), m/d/Y text in the 2021 CSV, and a
#     2024 .xlsx with real Excel date cells; overlapping exports; a blank-id row; unreadable dates
#   - a fake NIOCCS cache with stored codes, and a fake GET() (defined here) standing in for CDC
#   - fake ACS C24030 / C24010 with the full subtotal outline
# Every record is invented. The old v4 test is tests/synthetic_run_v4.R.
# Run from the repo root:  Rscript tests/synthetic_run.R    Exits with an error if any check fails.
suppressPackageStartupMessages({ library(dplyr); library(readr) })
set.seed(20260928)

root <- file.path(tempdir(), "io_v5_synthetic"); unlink(root, recursive = TRUE)
dc_dir <- file.path(root, "dc"); work <- file.path(root, "Downloads"); cache_dir <- file.path(work, "Cache")
for (d in c(dc_dir, cache_dir)) dir.create(d, recursive = TRUE, showWarnings = FALSE)
invisible(file.copy(file.path("scripts", "acs_group_map.csv"), work))   # the map sits next to the script

# ---------------------------------------------------------------------
# 1. Fake Guardian exports
# ---------------------------------------------------------------------
cols <- c("DeathCertificateId", "StateFileNumber", "EventYear", "DateOfDeath", "DateOfBirth", "ResidingStateNchs",
          "NchsAge", "NchsAgeUnit", "Sex", "MannerDeath", "InjuryAtWork", "AcmeUnderlyingCode",
          paste0("D2Acme", 1:20), paste0("D2SmicarAxis", 1:20), "ImmedCauseDeath", "Consq1", "Consq2", "Consq3",
          "OtherSignificantConditions", "IndustryLit", "OccupationLIt", "IndustryCode", "OccupationCode",
          "FirstName", "LastName", "RecordStatus")
rows <- list()
# add(): one row in one export. Dates are given as ISO text here and written in that export's format below.
# Defaults: NE resident, male, age 40, manner A, CONSTRUCTION / CARPENTER.
add <- function(export, id, dod, ...) {
  r <- as.list(setNames(rep(NA_character_, length(cols)), cols))
  r$DeathCertificateId <- id; r$StateFileNumber <- paste0("SFN", id); r$EventYear <- "0"; r$NchsAge <- "0"; r$NchsAgeUnit <- "1"
  r$DateOfDeath <- dod; r$DateOfBirth <- if (is.na(dod)) NA else paste0(as.integer(substr(dod, 1, 4)) - 40, substr(dod, 5, 10))
  r$ResidingStateNchs <- "NE"; r$Sex <- "M"; r$MannerDeath <- "A"
  r$IndustryLit <- "CONSTRUCTION"; r$OccupationLIt <- "CARPENTER"
  r$FirstName <- "FAKE"; r$LastName <- paste0("PERSON", id); r$RecordStatus <- "Registered"
  args <- list(...); for (nm in names(args)) r[[nm]] <- args[[nm]]
  rows[[length(rows) + 1]] <<- list(export = export, r = r)
}

# Filler: 40 natural deaths per export (never a case), mixed residence, sex and age, including children.
cached_pairs <- list(c("CONSTRUCTION", "CARPENTER"), c("FARM", "FARMER"), c("SCHOOL", "TEACHER"), c("", "RETIRED"), c("", ""))
for (yr in 2020:2024) for (k in 1:40) {
  dod <- as.Date(sprintf("%d-01-01", yr)) + sample(0:364, 1); io <- cached_pairs[[sample(length(cached_pairs), 1)]]
  add(yr, sprintf("%d%04d", yr, k), format(dod), DateOfBirth = format(dod - round(sample(0:99, 1) * 365.25) - sample(0:300, 1)),
      ResidingStateNchs = sample(c(rep("NE", 8), "IA", "ne"), 1), Sex = sample(c("M", "F", "1", "2", "U"), 1), MannerDeath = "N",
      AcmeUnderlyingCode = sample(c("I21.9", "C34.1", "J44.9", "G30.9", "E11.9"), 1),
      ImmedCauseDeath = sample(c("atherosclerotic cardiovascular disease", "lung cancer", "digoxin toxicity", ""), 1),
      IndustryLit = io[1], OccupationLIt = io[2])
}
for (i in 1:3) rows[[length(rows) + 1]] <- list(export = 2021, r = rows[[i]]$r)   # 3 late 2020 deaths repeated in the 2021 export
for (k in 1:5) add(2021, paste0("ROSTER", k), NA, ResidingStateNchs = NA, Sex = NA, MannerDeath = NA)   # placeholder rows, no dates

# Planted records with a known result.
# Suicides (22 counted)
add(2022, "P01", "2022-06-15", AcmeUnderlyingCode = "X70", MannerDeath = "S")                      # suicide, 23 / 47
add(2022, "P02", "2022-06-15", AcmeUnderlyingCode = "X70", ResidingStateNchs = "IA")                # non-resident: out
add(2022, "P03", "2022-06-15", AcmeUnderlyingCode = "X74", DateOfBirth = "2006-06-15")             # 16th birthday: in
add(2022, "P05", "2022-06-15", AcmeUnderlyingCode = "X74", DateOfBirth = "2006-06-16")             # one day short of 16: out
add(2022, "P08", "2022-06-15", AcmeUnderlyingCode = "X64", MannerDeath = "S", ImmedCauseDeath = "intentional overdose of oxycodone")
add(2022, "P11", "2022-06-15", AcmeUnderlyingCode = "Y87.0")                                       # suicide
add(2022, "P12", "2022-06-15", AcmeUnderlyingCode = "U03")                                         # suicide
add(2022, "P13", "2022-06-15", AcmeUnderlyingCode = "UO3")                                         # letter O: not a suicide
add(2021, "P15", "2021-12-10", AcmeUnderlyingCode = "X72", MannerDeath = "S")
rows[[length(rows) + 1]] <- list(export = 2022, r = rows[[length(rows)]]$r)                       # P15 repeated in the 2022 export
add(2020, "P16", "2019-12-20", AcmeUnderlyingCode = "X72")                                         # 2019 death in the 2020 export: out
add(2022, "P17", "2022-06-15", AcmeUnderlyingCode = "X72", Sex = "1", IndustryLit = "US ARMY", OccupationLIt = "SOLDIER")  # SOC 55: Military
add(2022, "P18", "2022-06-15", AcmeUnderlyingCode = "X72", IndustryLit = "", OccupationLIt = "STUDENT")   # text: Not in workforce
add(2022, "P19", "2022-06-15", AcmeUnderlyingCode = "X72", IndustryLit = "", OccupationLIt = "")          # Not coded, never sent
add(2022, "P20", "2022-06-15", AcmeUnderlyingCode = "X72", IndustryLit = "CHILD CARE", OccupationLIt = "CHILD CARE WORKER")  # 62 / 39
add(2021, "P23", "2021-06-15", AcmeUnderlyingCode = "X72", IndustryLit = "USAF", OccupationLIt = "PHOTO INTERPRETER")  # 009680 / 00-9830
add(2021, "P24", "2021-06-15", AcmeUnderlyingCode = "X72", IndustryLit = "INMATE", OccupationLIt = "INMATE")          # 009890 / 00-9100
add(2023, "P25", "2023-06-15", AcmeUnderlyingCode = "X72", MannerDeath = "")                       # manner blank: still a suicide
add(2023, "P26", "2023-06-15", AcmeUnderlyingCode = "X72", Sex = "U")                              # sex U: in T only
add(2022, "P27", "2022-06-15", AcmeUnderlyingCode = "X72", IndustryLit = "US ARMY", OccupationLIt = "CIVILIAN ACCOUNTANT")  # 928110: 92 / 13
add(2020, "P28", "2020-06-15", AcmeUnderlyingCode = "X72", IndustryLit = "UNKNOWN", OccupationLIt = "UNKNOWN")        # 009990: Not coded
add(2024, "P29", "2024-06-15", AcmeUnderlyingCode = "X72", IndustryLit = "RAILROAD", OccupationLIt = "CONDUCTOR")     # not cached: sent
add(2024, "P30", "2024-06-15", AcmeUnderlyingCode = "X72", IndustryLit = "AMAZON", OccupationLIt = "PICKER")          # CDC error reply
add(2021, "P31", "2021-06-15", AcmeUnderlyingCode = "X72", IndustryLit = "", OccupationLIt = "RETIRED")               # text: Not in workforce
add(2022, "P36", "2022-06-15", AcmeUnderlyingCode = "X64", MannerDeath = "S", D2Acme2 = "T40.2")  # suicide and MA opioid
add(2022, "P40", "2022-06-15", AcmeUnderlyingCode = "X72", Sex = "F")                              # female, 23
add(2024, "P42", "2024-06-15", AcmeUnderlyingCode = "X72", IndustryLit = "HOSPITAL", OccupationLIt = "NURSE")         # cached error reply
add(2022, NA, "2022-06-15", AcmeUnderlyingCode = "X72")                                            # blank id: dropped, counted
add(2022, "P32", "2022-06-15", AcmeUnderlyingCode = "X72", DateOfBirth = "unknown")               # unreadable DOB: dropped
add(2023, "P33", "2023/13/45", AcmeUnderlyingCode = "X72", DateOfBirth = "1980-01-01")           # unreadable DOD: dropped
# Overdoses (5 counted; 4 opioid) and MA opioid (6)
add(2022, "P06", "2022-06-15", AcmeUnderlyingCode = "X42", D2Acme3 = "T40.4", ImmedCauseDeath = "acute fentanyl toxicity")
add(2020, "D1", "2020-12-31", AcmeUnderlyingCode = "X42", D2Acme1 = "T40.4")                      # date corrected across the year
add(2021, "D1", "2021-01-01", AcmeUnderlyingCode = "X42", D2Acme1 = "T40.4")                      #   boundary: counted once, in 2021
add(2021, "D2", "2021-11-20", AcmeUnderlyingCode = "R99", MannerDeath = "P", ImmedCauseDeath = "pending investigation")
add(2022, "D2", "2021-11-20", AcmeUnderlyingCode = "X42", D2Acme1 = "T40.4", ImmedCauseDeath = "acute fentanyl toxicity")  # finalized
add(2023, "P34", "2023-06-15", AcmeUnderlyingCode = "Y12", MannerDeath = "C")                      # overdose, not opioid
add(2024, "P35", "2024-06-15", AcmeUnderlyingCode = "X44", D2SmicarAxis2 = "T40.1")                # overdose + opioid (entity axis)
add(2022, "P14", "2022-06-15", AcmeUnderlyingCode = "X85", D2SmicarAxis5 = "T40.1", MannerDeath = "H")  # MA opioid only
# Text: review candidates (2) and non-candidates
add(2022, "P07", "2022-06-15", AcmeUnderlyingCode = "R99", MannerDeath = "P", ImmedCauseDeath = "Acute Fentanyl Toxicity")  # candidate
add(2023, "P38", "2023-06-15", AcmeUnderlyingCode = "W19", OtherSignificantConditions = "acute methamphetamine intoxication")  # candidate
add(2022, "P09", "2022-06-15", AcmeUnderlyingCode = "X45", ImmedCauseDeath = "acute ethanol intoxication")
add(2022, "P37", "2022-06-15", AcmeUnderlyingCode = "X45", ImmedCauseDeath = "acute ethanol intoxication",
    OtherSignificantConditions = "history of drug abuse")                                          # words in different fields
add(2022, "P10", "2022-06-15", AcmeUnderlyingCode = "X47", ImmedCauseDeath = "carbon monoxide toxicity")
add(2022, "P21", "2022-06-15", AcmeUnderlyingCode = "I21.9", MannerDeath = "N", ImmedCauseDeath = "digoxin toxicity")

# Write each export in its own date format.
for (yr in 2020:2024) {
  df <- bind_rows(lapply(Filter(function(x) x$export == yr, rows), function(x) as_tibble(x$r)))
  for (v in c("DateOfDeath", "DateOfBirth")) {
    x <- df[[v]]; ok <- !is.na(x) & grepl("^\\d{4}-\\d{2}-\\d{2}$", x)
    d <- as.Date(ifelse(ok, x, NA)); serial <- as.numeric(d - as.Date("1899-12-30"))
    if (yr == 2021) x[ok] <- format(d[ok], "%m/%d/%Y")                # text dates
    if (yr == 2022) x[ok] <- paste0(serial[ok], ".0")                 # serial with .0
    if (yr %in% c(2020, 2023)) x[ok] <- as.character(serial[ok])      # serial
    df[[v]] <- if (yr == 2024) d else x                               # real Excel date cells
  }
  df <- df[sample(ncol(df))]                                          # column order differs by export
  dir.create(file.path(dc_dir, yr), showWarnings = FALSE)
  if (yr == 2024) writexl::write_xlsx(df, file.path(dc_dir, yr, "DeathCertificates24.xlsx"))
  else write_csv(df, file.path(dc_dir, yr, sprintf("DeathCertificates%02d.csv", yr %% 100)), na = "")
}

# ---------------------------------------------------------------------
# 2. Fake NIOCCS cache (codes stored, as v3/v4 wrote them) and fake CDC GET
# ---------------------------------------------------------------------
reply <- function(naics, soc) sprintf('{"Industry":[{"NAICSCode":"%s","NAICSTitle":"x"}],"Occupation":[{"SOCCode":"%s","SOCTitle":"y"}]}', naics, soc)
cache <- tribble(~IndustryLit, ~OccupationLIt, ~NAICSCode, ~SOCCode,
  "CONSTRUCTION", "CARPENTER", "236118", "47-2031",    "FARM", "FARMER", "111998", "11-9013",
  "SCHOOL", "TEACHER", "611110", "25-2021",             "", "STUDENT", "", "00-0000",
  "", "RETIRED", "999999", "00-0000",                   "US ARMY", "SOLDIER", "928110", "55-3016",
  "US ARMY", "CIVILIAN ACCOUNTANT", "928110", "13-2011", "USAF", "PHOTO INTERPRETER", "009680", "00-9830",
  "INMATE", "INMATE", "009890", "00-9100",              "UNKNOWN", "UNKNOWN", "009990", "00-9900",
  "CHILD CARE", "CHILD CARE WORKER", "624410", "39-9011") %>% mutate(raw = reply(NAICSCode, SOCCode))
cache <- bind_rows(cache, tibble(IndustryLit = "HOSPITAL", OccupationLIt = "NURSE", NAICSCode = "", SOCCode = "",
                                 raw = '{"Message":"An error has occurred."}'))   # an error reply v4 cached
write_csv(cache, file.path(cache_dir, "nioccs_cache_v3.csv"), na = "")
nioccs_calls <- character()
GET <- function(url, query, ...) {            # found before httr::GET because it sits in the global environment
  nioccs_calls <<- c(nioccs_calls, paste(query$i, "/", query$o))
  body <- if (query$i == "RAILROAD") reply("482111", "53-4031") else "<html>An error has occurred.</html>"
  structure(list(url = url, status_code = 200L, headers = list(`content-type` = "application/json"), content = charToRaw(body)), class = "response")
}

# ---------------------------------------------------------------------
# 3. Fake ACS tables, same shape and labels as the real C24030 / C24010
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
fake_acs <- function(table_id, lines) {     # "Estimate!!Total:!!Male:!!Parent:!!Leaf"; parents are the sum of their leaves
  out <- tibble(label = "Estimate!!Total:", estimate = 0)
  for (sx in c("Male", "Female")) {
    out <- bind_rows(out, tibble(label = paste0("Estimate!!Total:!!", sx, ":"), estimate = 0))
    path <- character()
    for (ln in lines) {
      depth <- (nchar(ln) - nchar(sub("^ +", "", ln))) / 2
      path <- c(path[seq_len(depth)], sub("^ +", "", ln))
      out <- bind_rows(out, tibble(label = paste0("Estimate!!Total:!!", sx, ":!!", paste(path, collapse = "!!")), estimate = 0))
    }
  }
  is_leaf <- sapply(out$label, function(l) !any(startsWith(out$label, paste0(l, "!!"))))
  out$estimate[is_leaf] <- sample(2000:60000, sum(is_leaf), replace = TRUE)
  for (i in which(!is_leaf)) out$estimate[i] <- sum(out$estimate[is_leaf & startsWith(out$label, paste0(out$label[i], "!!"))])
  out %>% mutate(variable = sprintf("%s_%03d", table_id, row_number()), moe = round(sqrt(estimate) * 10)) %>% select(variable, label, estimate, moe)
}
acs <- bind_rows(fake_acs("C24030", c24030_lines), fake_acs("C24010", c24010_lines))
stopifnot(nrow(acs) == 55 + 73)                                   # 55 and 73 variables, as in the real tables
write_csv(acs, file.path(cache_dir, "acs_2024.csv"))

# ---------------------------------------------------------------------
# 4. Run v5 against the fake data (the options point it at the temp folders)
# ---------------------------------------------------------------------
options(io_v5_dc_dir = dc_dir, io_v5_work_dir = work)
files_before <- list.files(work, recursive = TRUE)
env <- new.env()
sys.source(file.path("scripts", "io_death_rates_v5.R"), envir = env)
stamp <- format(Sys.Date(), "%Y%m%d")

# ---------------------------------------------------------------------
# 5. Checks
# ---------------------------------------------------------------------
fails <- character()
check <- function(ok, what) { cat(ifelse(isTRUE(ok), "PASS ", "FAIL "), what, "\n"); if (!isTRUE(ok)) fails <<- c(fails, what) }
d <- env$deaths; cs <- env$cases; tb <- env$tables
row_of <- function(id) d[d$DeathCertificateId %in% id, ]
grp <- function(id, col) cs[[col]][cs$DeathCertificateId == id]
cell <- function(o, g, grp_name, sx) { x <- tb$deaths[tb$outcome == o & tb$grouping == g & tb$group == grp_name & tb$sex == sx]; if (length(x)) x else NA }

# Reading and dedup
check(all(d$year %in% 2020:2024) && !any(grepl("^ROSTER", d$DeathCertificateId)), "years come from DateOfDeath; ROSTER rows dropped")
check(env$n_blank_id == 1, "blank-id row dropped and counted (1)")
check(nrow(env$dc) - n_distinct(env$dc$DeathCertificateId) == 6, "6 overlap copies dropped (3 filler, P15, D1, D2)")
check(env$n_year_moved == 1, "1 id whose year moved between exports (D1)")
check(env$n_bad_dod == 1 && env$n_bad_dob == 1, "unreadable DateOfDeath (P33) and DateOfBirth (P32) counted")
check(nrow(row_of("D1")) == 1 && row_of("D1")$year == 2021 && row_of("D1")$export == 2021, "D1 counted once, in 2021 (latest export)")
check(nrow(row_of("D2")) == 1 && row_of("D2")$overdose && row_of("D2")$overdose_opioid, "D2 pending R99 replaced by final X42 + T40.4")
check(sum(d$DeathCertificateId == "P15") == 1, "P15 overlap copy counted once")
check(nrow(row_of(c("P02", "P05", "P16", "P32", "P33"))) == 0, "non-resident, age 15, 2019 death, unreadable dates: out")
check(nrow(row_of("P03")) == 1 && row_of("P03")$age == 16, "P03 died on 16th birthday: in, age 16")
check(all(d$year[d$export == 2021 & d$DeathCertificateId %in% c("P23", "P24", "P31")] == 2021), "m/d/Y text dates read (2021 CSV)")
check(sum(d$export == 2024) > 0 && all(!is.na(d$age[d$export == 2024])), "xlsx Excel date cells read (2024)")
# Outcomes
check(sum(d$suicide) == 22, "22 suicides")
check(sum(d$overdose) == 5, "5 overdoses (ICD only)")
check(sum(d$overdose_opioid) == 4, "4 opioid overdoses")
check(sum(d$opioid_ma_def) == 6, "6 MA-definition opioid deaths")
check(sum(d$text_candidate) == 2 && all(c("P07", "P38") %in% d$DeathCertificateId[d$text_candidate]), "2 text-only candidates (P07, P38)")
check(!row_of("P07")$overdose, "P07 text-only fentanyl toxicity is NOT counted as an overdose")
check(!any(d$text_candidate[d$DeathCertificateId %in% c("P08", "P09", "P37", "P10", "P21", "P06")]), "P08 P09 P37 P10 P21 P06 are not candidates")
check(row_of("P08")$suicide && !row_of("P08")$overdose, "P08 X64 is suicide, not overdose")
check(row_of("P25")$suicide, "P25 suicide with manner blank")
check(row_of("P11")$suicide && row_of("P12")$suicide && !row_of("P13")$suicide, "Y87.0 and U03 suicide; UO3 not")
check(row_of("P36")$suicide && row_of("P36")$opioid_ma_def && !row_of("P36")$overdose, "P36 X64 + T40.2: suicide and MA opioid, not SUDORS")
check(row_of("P14")$opioid_ma_def && !row_of("P14")$overdose, "P14 X85 + T40.1: MA opioid only")
check(!row_of("P34")$overdose_opioid && row_of("P34")$overdose, "P34 Y12 without T40: overdose, not opioid")
check(row_of("P35")$overdose_opioid, "P35 T40.1 on the entity axis: opioid overdose")
# NIOCCS and groups
check(identical(nioccs_calls, c("RAILROAD / CONDUCTOR", "AMAZON / PICKER")), "NIOCCS sent only the 2 uncached pairs")
check(env$n_unusable == 1 && env$n_cached_no_codes == 1, "error reply not usable (1); cached error reply counted (1)")
new_cache <- read_csv(file.path(cache_dir, "nioccs_cache_v3.csv"), col_types = cols(.default = "c"), na = character())
check(nrow(new_cache) == nrow(cache) + 1 && "RAILROAD" %in% new_cache$IndustryLit && !"AMAZON" %in% new_cache$IndustryLit,
      "RAILROAD reply saved; AMAZON error page not saved")
check(grp("P29", "ind_group") == "48-49" && grp("P29", "occ_group") == "53", "P29 RAILROAD = 48-49 / 53")
check(grp("P30", "ind_group") == "Not coded" && grp("P42", "ind_group") == "Not coded", "P30 and P42 (no usable reply) = Not coded")
check(grp("P01", "ind_group") == "23" && grp("P01", "occ_group") == "47", "P01 sector 23, SOC 47")
check(grp("P17", "ind_group") == "Military" && grp("P17", "occ_group") == "Military", "P17 SOC 55 = Military")
check(grp("P23", "ind_group") == "Military" && grp("P23", "occ_group") == "Military", "P23 009680 / 00-9830 = Military")
check(grp("P27", "ind_group") == "92" && grp("P27", "occ_group") == "13", "P27 DoD civilian 928110 / 13-2011 = sector 92, SOC 13")
check(grp("P24", "ind_group") == "Not in workforce" && grp("P24", "occ_group") == "Not in workforce", "P24 009890 / 00-9100 = Not in workforce")
check(grp("P18", "ind_group") == "Not in workforce" && grp("P31", "ind_group") == "Not in workforce", "STUDENT and RETIRED text = Not in workforce")
check(grp("P28", "ind_group") == "Not coded" && grp("P19", "ind_group") == "Not coded", "009990 / 00-9900 and blank text = Not coded")
check(grp("P20", "ind_group") == "62" && grp("P20", "occ_group") == "39", "P20 CHILD CARE = 62 / 39")
# Tables
check(!any(tb$sex == "U") && all(c("M", "F", "T") %in% tb$sex), "no sex U rows; M, F and T present")
check(!"rr" %in% names(tb) && all(tb$grouping %in% c("industry", "occupation")), "no rate ratio column; grouping column says industry or occupation")
check(all(env$sums$ok) && nrow(env$sums) == 8, "sums check: T rows equal flagged cases in all 8 tables")
check(cell("suicide", "industry", "All workers", "T") == 13 && cell("suicide", "industry", "All workers", "M") == 11 &&
      cell("suicide", "industry", "All workers", "F") == 1, "suicide All workers T 13, M 11, F 1 (U only in T)")
check(cell("suicide", "industry", "23", "T") == 10 && cell("suicide", "industry", "23", "M") == 8, "suicide sector 23: T 10, M 8")
check(cell("suicide", "industry", "Military", "T") == 2 && cell("suicide", "industry", "Not in workforce", "T") == 3 &&
      cell("suicide", "industry", "Not coded", "T") == 4, "suicide Military 2, Not in workforce 3, Not coded 4")
check(cell("suicide", "industry", "92", "T") == 1 && cell("suicide", "occupation", "13", "T") == 1, "DoD civilian counted in 92 and SOC 13")
check(cell("overdose", "industry", "23", "T") == 5 && cell("overdose_opioid", "occupation", "47", "T") == 4 &&
      cell("opioid_ma_def", "industry", "23", "T") == 6, "overdose 5, opioid 4, MA 6 in sector 23 / SOC 47")
t <- tb %>% filter(outcome == "suicide", grouping == "industry", sex == "T", group == "All workers")
check(abs(t$rate - 13 / (t$workers * 5) * 1e5) < 1e-9, "rate = deaths / (workers x 5) x 100,000")
check(abs(t$rate_lo - qchisq(0.025, 26) / 2 / (t$workers * 5) * 1e5) < 1e-9 && abs(t$rate_hi - qchisq(0.975, 28) / 2 / (t$workers * 5) * 1e5) < 1e-9,
      "exact Poisson 95% limits")
pct <- tb %>% filter(outcome == "suicide", grouping == "industry", sex == "T", group != "All workers") %>% pull(pct_of_deaths)
check(abs(sum(pct) - 100) < 1e-9, "percent of deaths sums to 100")
check(all(is.na(tb$rate[tb$group %in% c("Military", "Not in workforce", "Not coded")])), "no rate on Military / Not in workforce / Not coded")
check(sum(env$den$workers[env$den$group == "All workers" & env$den$sex == "T" & env$den$table == "C24030"]) ==
      acs$estimate[acs$variable == "C24030_001"], "ACS industry leaves add to C24030_001")
check(n_distinct(env$den$group[env$den$table == "C24030"]) == 21 && n_distinct(env$den$group[env$den$table == "C24010"]) == 23,
      "20 sectors and 22 SOC groups plus All workers")
r <- env$recon
check(r$deaths[r$group == "Not in workforce"] == 2 && r$deaths[r$group == "23"] == 1 && r$nevdrs_sheet[r$group == "23"] == 72,
      "2020-2021 suicide cut: Not in workforce 2, construction 1, NEVDRS 72 beside it")
# Files
new_files <- setdiff(list.files(work, recursive = TRUE), files_before)
expect <- c(paste0("Output/io_death_rates_", stamp, ".csv"), paste0("Output/suicide_2020_2021_vs_nevdrs_", stamp, ".csv"),
            paste0("Cache/qa_", stamp, ".txt"), paste0("Cache/cases_", stamp, ".csv"), paste0("Cache/review_", stamp, ".csv"))
check(setequal(new_files, expect), "wrote exactly the 2 Output tables and the QA, case and review files in Cache")
review <- read_csv(file.path(cache_dir, paste0("review_", stamp, ".csv")), col_types = cols(.default = "c"))
check(setequal(review$DeathCertificateId, c("P07", "P38")), "review list holds P07 and P38")
out <- read_csv(file.path(work, "Output", paste0("io_death_rates_", stamp, ".csv")), col_types = cols(.default = "c"))
check(any(as.numeric(out$deaths) %in% 1:5), "small counts are written, not suppressed")
check(!any(grepl("PERSON|^P[0-9]|^D[12]$", unlist(lapply(list.files(file.path(work, "Output"), full.names = TRUE), readLines)))),
      "no certificate ids or names in Output")
qa <- readLines(file.path(cache_dir, paste0("qa_", stamp, ".txt")))
check(any(grepl("text_candidates_not_counted", qa)) && !any(grepl("more variable", qa)), "QA file shows every column, including text candidates")

# ---------------------------------------------------------------------
# 6. Second run: an ACS leaf missing from the map must stop the run; no pair is re-sent
# ---------------------------------------------------------------------
nioccs_calls <- character()
acs$label <- sub("oil and gas extraction$", "oil and gas extraction industries", acs$label)
write_csv(acs, file.path(cache_dir, "acs_2024.csv"))
msg <- tryCatch({ sys.source(file.path("scripts", "io_death_rates_v5.R"), envir = new.env()); "no error" }, error = function(e) conditionMessage(e))
check(grepl("not in acs_group_map.csv", msg) && grepl("extraction industries", msg), "unmapped ACS leaf stops the run and names it")
check(identical(nioccs_calls, "AMAZON / PICKER"), "second run re-sends only the pair whose reply was not usable (RAILROAD not re-sent)")

cat("\n", length(fails), "failures\n")
if (length(fails) > 0) stop("Synthetic run failed: ", paste(fails, collapse = "; "))
