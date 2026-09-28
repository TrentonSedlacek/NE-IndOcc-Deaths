# Denominators archive (FTE and employment)

Denominator work inherited from the occupational health team: ACS PUMS full-time equivalent (FTE) estimates by industry and occupation, NIOSH Employed Labor Force (ELF) queries built on the Current Population Survey (CPS), and a 2023 comparison of QWI, QCEW and OEWS job counts. All Nebraska, state level.

Authorship is not stated in most files. The R scripts write to `K:\Occupational Health Grant\Jean Kwizerimana\FTE\` (for example `industry/scripts/ACS_2023.R` lines 193-194, `occupation/scripts/occupation_fte 2014.R` line 91), so at least the `FTE/` folder material ran under Jean Kwizerimana's K: folder. `FTEs.rtf` carries Derry Stover as author and a query date of 8 July 2014. The `ACS FTE/` folder (scripts, outputs, Workflow docx) is the material attributed to Chris Austin.

## Layout

```
denominators/
  denominators.csv                      reference list of denominator types (not data)
  acs-pums-fte/
    Workforce Estimates Calculation Tool Workflow.docx
    industry/
      scripts/                          5 R scripts (tidycensus + srvyr)
      outputs/                          from the old "ACS FTE/Outputs" folder
      outputs-FTE-folder/               from the old "FTE/Industry" folder (2023 1y and 5y)
    occupation/
      scripts/                          2 R scripts
      outputs/                          SOC major group FTE, 5-year PUMS, 2014 to 2023
    meatpacking-2008-2012/              ACS vs CPS FTE for animal slaughter and processing
  niosh-elf-cps/                        NIOSH ELF (CPS) FTE queries
  qwi-qcew-oews/                        QWI/QCEW/OEWS 2023 job counts and QWI API notes
```

Where the files came from: `ACS FTE/` (scripts, Outputs, Workflow docx), `ACS Subsector FTE Counts/`, `FTE/` (Industry, Occupation, two loose csvs), and root files `ACS_2023.R`, `occupation_fte.R`, the two meatpacking xlsx files, `FTEs NIOSH ELF Query - 2000-2012.xlsx`, `FTEs.rtf`, `elf fte estimates 2017-2019.csv`, `nebraska FTEs for certain industries.csv`, `denominators.csv`, `QWI QCEW OEWS Denominators.xlsx`, `Parameters_Variables in a QWI API Call.docx`, `QWI_101.pdf`.

### Exact duplicates removed (identical md5)

| Removed | Kept |
|---|---|
| `ACS Subsector FTE Counts/FTE_2018_PUMS_1y_naics3.csv` | `acs-pums-fte/industry/outputs/FTE_2018_PUMS_1y_naics3.csv` |
| `ACS Subsector FTE Counts/FTE_2019_PUMS_1y_naics3.csv` | `acs-pums-fte/industry/outputs/FTE_2019_PUMS_1y_naics3.csv` |
| `ACS Subsector FTE Counts/FTE_2021_PUMS_1y_naics3.csv` | `acs-pums-fte/industry/outputs/FTE_2021_PUMS_1y_naics3.csv` |
| `FTE/FTE_2014_PUMS_5y_soc2.csv` (loose) | `acs-pums-fte/occupation/outputs/FTE_2014_PUMS_5y_soc2.csv` |
| `FTE/FTE_2015_PUMS_5y_soc2.csv` (loose) | `acs-pums-fte/occupation/outputs/FTE_2015_PUMS_5y_soc2.csv` |
| `FTE/Industry/fte_ne_naics2_5y_2022.csv` | `acs-pums-fte/industry/outputs/fte_ne_naics2_5y_2022.csv` |
| `occupation_fte.R` (root) | `acs-pums-fte/occupation/scripts/occupation_fte 2014.R` |

The whole `ACS Subsector FTE Counts/` folder was copies of files in `ACS FTE/Outputs/`.

Kept on purpose although identical:
- `outputs/FTE_2018_PUMS_1y_naics3.csv` and `outputs/FTE_2019_PUMS_1y_naics3.csv` have the same md5, and so do `outputs/2018_PUMS_1y_naics3.csv` and `outputs/2019_PUMS_1y_naics3.csv`. These are not copies of one file. They claim to be different years, so one year is mislabeled. The NAICS 2-digit files for the same two years do differ. Both are kept as evidence; do not use either NAICS 3-digit 1-year 2018/2019 file until it is rerun.
- `outputs/fte_ne_naics2_5y_2023.csv` and `outputs-FTE-folder/fte_ne_naics2_5y_2023.csv` hold the same numbers (max difference 5e-7). The `outputs/` copy is sorted by size and rounded, probably resaved through Excel. Not byte-identical, so both are kept.

## Inventory

Key column patterns:
- A: `NAICSP_2` or `NAICSP_3`, `estimate`, `estimate_se`, `MOE`, `r_MOE`, `CV` (employed persons, not FTE)
- B: `NAICSP_2` or `NAICSP_3`, `FTE_estimate`, `FTE_estimate_se`, `MOE`, `r_MOE`, `CV`
- C: `NAICSP`, `Ind_sector`, `n`, `n_se`, `MOE`, `r_MOE`, `CV` (FTE)
- D: `SOCP`, `OccCategory`, `n`, `n_se`, `MOE`, `r_MOE`, `CV` (FTE)

MOE in all ACS outputs is `1.96 x SE`, a 95% margin, not the 90% margin Census publishes. SE comes from the 80 person replicate weights through `srvyr`.

### ACS PUMS scripts (`acs-pums-fte/`)

| Path | What it is | Source / years | Coding level | Notes |
|---|---|---|---|---|
| `Workforce Estimates Calculation Tool Workflow.docx` | Written method for the PUMS FTE tool (6 steps with code) | ACS PUMS 1-year (`survey = "acs1"`), any state/year | NAICS 3-digit (`NAICSP` trimmed) | FTE = PWGTP x WKHP/40. Drops mixed codes 22S, 33M, 3MS, 4MS, 42S, 52M, 53M, 92M. |
| `industry/scripts/ACS_PUMS_industry_estimates.R` | Script: employed and FTE counts | PUMS 5-year 2019 and 2020 | NAICS 2 and 3 | Filters ESR 1,2 and AGEP <= 64. Writes the `2019_/2020_PUMS_5y_*` and `FTE_2019_/FTE_2020_PUMS_5y_*` files. |
| `industry/scripts/ACS_PUMS_FTE_industry_estimates_demo.R` | Script: FTE by sector crossed with sex, age group, race/ethnicity, education | PUMS 5-year 2021 | NAICS 2 | Filters ESR 1,2 and AGEP <= 70. Writes the `fte_ne_naics2_2021_*` files. |
| `industry/scripts/ACS_2023.R` | Script: employed and FTE counts | PUMS **1-year** 2023 (line 29), despite "5y" in object and output names | NAICS 2 and 3 | No age cap. Writes `fte_ne_naics2_5y_2023.csv` and `FTE_2023_PUMS_5y_naics3.csv` to K: (lines 193-194). Contains broken exploratory code (lines 114-128, 144-157); likely did not run clean. |
| `industry/scripts/ACS.R` | Script: employed and FTE counts; plus a full-time/full-year experiment | PUMS 5-year 2022; 1-year 2023 for the experiment | NAICS 2 | AGEP >= 16, ESR 1,2. Writes `fte_ne_naics2_5y_2022.csv` (line 135). Lines 138-155 use WKWN (see below); that result is never written. |
| `industry/scripts/asc_find.R` | Script: employed and FTE counts | PUMS 5-year 2023 | NAICS 2 | AGEP >= 16, ESR 1,2. No `write_csv`; its FTE block matches `fte_ne_naics2_5y_2023.csv`. |
| `occupation/scripts/ACS_PUMS_occupation_estimates.R` | Script: employed and FTE counts by SOC | PUMS 5-year 2019; "2020" block actually pulls **2014** (line 137) | SOC 2 and 3 (`SOCP` trimmed) | AGEP <= 64. Output names (`*_soc_major.csv`, `*_soc3.csv`, `FTE_2019/2020_PUMS_5y_soc2/3.csv`) are mostly not in the archive. |
| `occupation/scripts/occupation_fte 2014.R` | Script: FTE by SOC major group | PUMS 5-year 2014, variable `SOCP12`, `recode = FALSE` | SOC 2 | ESR 1,2, no age cap. Joins labels from `K:\...\Deacertificate\ATV\socc.csv` (line 77). Writes `FTE_2014_PUMS_5y_soc2.csv` (line 91). Template for the other soc2 files. |

### ACS PUMS outputs, industry (`acs-pums-fte/industry/outputs/` unless noted)

| File(s) | What it is | PUMS product, ACS year | Level | Columns | State total |
|---|---|---|---|---|---|
| `2018_PUMS_1y_naics2.csv`, `2019_PUMS_1y_naics2.csv`, `2021_PUMS_1y_naics2.csv` | Employed persons | 1-year 2018, 2019, 2021 | NAICS 2 (20 sectors) | A | 1.00M, 1.01M, 1.02M |
| `2018_PUMS_1y_naics3.csv`, `2019_PUMS_1y_naics3.csv`, `2021_PUMS_1y_naics3.csv` | Employed persons | 1-year | NAICS 3 | A | 2018 and 2019 identical (mislabel) |
| `FTE_2018_PUMS_1y_naics2.csv`, `FTE_2019_PUMS_1y_naics2.csv`, `FTE_2021_PUMS_1y_naics2.csv` | FTE | 1-year 2018, 2019, 2021 | NAICS 2 | B | 1,000,683; 999,101; 1,014,046 |
| `FTE_2018_PUMS_1y_naics3.csv`, `FTE_2019_PUMS_1y_naics3.csv`, `FTE_2021_PUMS_1y_naics3.csv` | FTE | 1-year | NAICS 3 | B | 2018 and 2019 identical (mislabel) |
| `2019_PUMS_5y_naics2.csv`, `2019_PUMS_5y_naics3.csv`, `2020_PUMS_5y_naics2.csv`, `2020_PUMS_5y_naics3.csv` | Employed persons | 5-year 2015-2019, 2016-2020 | NAICS 2, 3 | A | 2019: 933,547 (age cap 64); 2020: 999,331 |
| `FTE_2019_PUMS_5y_naics2.csv`, `FTE_2019_PUMS_5y_naics3.csv` | FTE | 5-year 2015-2019 | NAICS 2, 3 | B | 936,249 (ages 16-64) |
| `FTE_2020_PUMS_5y_naics2.csv`, `FTE_2020_PUMS_5y_naics3.csv` | FTE | 5-year 2016-2020 | NAICS 2, 3 | B | 991,601 (see caveat on age cap) |
| `FTE_2021_ACS5y_naics2.csv`, `FTE_2021_ACS5y_naics3.csv` | FTE | 5-year 2017-2021 | NAICS 2, 3 | B | 1,003,576 |
| `fte5y_ne_naics2_2013.csv` ... `fte5y_ne_naics2_2017.csv` | FTE | 5-year, ending 2013 to 2017 | NAICS 2 | C | 0.94M to 0.98M; no script retained |
| `fte_ne_naics2_2021_sex.csv`, `_age_grps.csv`, `_race_ethnicity.csv`, `_education.csv` | FTE by sector x demographic | 5-year 2017-2021, ages 16-70 | NAICS 2 | C plus `SEX_label` / `age_group` / `race_ethnicity` / `education` | 986,771 each |
| `fte_ne_naics2_5y_2022.csv` | FTE | 5-year 2018-2022 | NAICS 2 | `NAICSP, Ind_sector, estimate, estimate_se, MOE, r_MOE, CV` | 1,009,261 |
| `fte_ne_naics2_5y_2023.csv` (both folders) | FTE | 5-year 2019-2023 | NAICS 2 | C | 1,011,341 |
| `outputs-FTE-folder/fte_ne_naics2_1y_2023.csv` | FTE | 1-year 2023 (probably from `ACS_2023.R`) | NAICS 2 | C | 1,005,906 |

No script was retained for the 1-year 2018, 2019 and 2021 files, `FTE_2021_ACS5y_*`, or `fte5y_ne_naics2_2013` to `2017`. All follow the same column pattern, so the same method is presumed.

### ACS PUMS outputs, occupation (`acs-pums-fte/occupation/outputs/`)

| File(s) | What it is | PUMS product | Level | Columns | State total |
|---|---|---|---|---|---|
| `FTE_2014_PUMS_5y_soc2.csv` | FTE | 5-year 2010-2014 | SOC major group (22 groups, 11 to 53) | D | 576,652: **undercounted**, see caveats |
| `FTE_2015_PUMS_5y_soc2.csv` | FTE | 5-year 2011-2015 | SOC 2 | D | 189,119: **undercounted**, see caveats |
| `FTE_2016_PUMS_5y_soc2.csv` ... `FTE_2023_PUMS_5y_soc2.csv` (8 files) | FTE | 5-year ending 2016 to 2023 | SOC 2 | D | 966,749 (2016) to 1,011,341 (2023) |

The 2016, 2017, 2020, 2021, 2022 and 2023 soc2 totals equal the matching NAICS 2-digit FTE totals exactly, which confirms the same universe (ESR 1 or 2, age 16+, no upper age cap) for those years. No military group (SOC 55); ESR 1,2 excludes the armed forces.

### Meatpacking comparison (`acs-pums-fte/meatpacking-2008-2012/`)

| File | What it is | Source / years | Coding | Notes |
|---|---|---|---|---|
| `ACS-PUMS- FTE based meatpacking data from US Census Bureau.xlsx` | Derived table: animal slaughter and processing workers, total and by sex and age group | ACS PUMS 5-year 2008-2012 | Census industry, animal slaughtering and processing (1180) | Columns: sample, population estimate, average annual hours per worker, total hours (formula), FTE = total hours / 2,000 (formula). Total 22,338 workers, 1,993 hours/yr, FTE about 22,263. The only file here that uses annual hours / 2,000. |
| `CPS - FTE based meatpacking data from NIOSH elf.xlsx` | Raw ELF query export plus a few formulas | CPS via NIOSH ELF, 2008-2012, "Full Time Equivalents - All Jobs" | Census 2002 industry code 1180 | By sex x 5-year age group x year. Totals 28,140 to 41,280 per year. Cells H43 to J46 compute a 5-year sum and rates per 100 FTE for unlabeled numerators 9,338, 8,310, 7,908 and 402. |
| `FTEs.rtf` | Word/RTF export of an ELF query, author Derry Stover, dated 8 July 2014 | Same ELF query as above, by year only | 1180 | 2008-2012: 28,140; 33,431; 39,748; 41,857; 41,278 (total 184,454). |

CPS/ELF gives about 36,900 FTE a year for 2008-2012 against about 22,300 from ACS PUMS for the same industry and period.

### NIOSH ELF / CPS (`niosh-elf-cps/`)

| File | What it is | Years | Coding | Key content |
|---|---|---|---|---|
| `FTEs NIOSH ELF Query - 2000-2012.xlsx` | Raw ELF export | 2000-2012 | All industries (state total) | NE FTE, primary job, age 16+: 877,334 (2000) to 951,931 (2012). |
| `elf fte estimates 2017-2019.csv` | Raw ELF export | 2017-2019 | All industries | 947,716; 964,588; 977,428. |
| `nebraska FTEs for certain industries.csv` | Raw ELF export | 2003-2013 | Census 2002 industry codes: agriculture 0170-0290, construction 0770, transportation and warehousing 6070-6390, with sector subtotals | FTE, primary job, by code and year. |

### QWI / QCEW / OEWS (`qwi-qcew-oews/`)

| File | What it is | Source / years | Coding | Notes |
|---|---|---|---|---|
| `QWI QCEW OEWS Denominators.xlsx` | Sheet "2023 SexAge": raw QWI API pull (31,401 rows). Sheet1: scratch comparison of totals. Sheet2: partial NAICS subsector list. | QWI `sa` endpoint, NE, 2023 Q1-Q4; QCEW and OEWS 2023 | NAICS sector, 3- and 4-digit; OEWS also SOC 2- and 6-digit | Jobs by place of work, not persons or FTE. Sheet1 annual averages: QWI 990,755; QCEW 1,008,194; OEWS 1,000,870. Also shows how sums fall at finer NAICS levels because of nondisclosure. A "Reported Wisconsin" cell (2,895,945) suggests a template from another state. |
| `Parameters_Variables in a QWI API Call.docx` | Reference: how to build QWI API calls (endpoints, indicators, industry levels, limits) | Census LEHD documentation copy | n/a | Reference only. |
| `QWI_101.pdf` | Census "Quarterly Workforce Indicators 101" (20 pp., April 2019) | Census LEHD | n/a | Reference only. |

### Other

| File | What it is |
|---|---|
| `denominators.csv` | 6-row reference list of denominator types for occupational health indicators: EMP (CPS / QCEW), FTE (NIOSH ELF, CPS hours), FTE_HOURS (BLS SOII rate base), WC (NASI), POP15 (Census population), BRFSS_WEIGHTED. Columns `denominator_type, label, source, cste_number, industry_split`. No Nebraska numbers. |

## How the FTE denominators were built

All ACS PUMS files were made in R with `tidycensus::get_pums()` (person replicate weights) and `srvyr`.

1. **Pull.** Nebraska person records with at least `AGEP, NAICSP, INDP, WKHP, COW, ESR` for industry (`industry/scripts/ACS_PUMS_industry_estimates.R` lines 28-34 and 148-154) or `SOCP`/`SOCP12` for occupation (`occupation/scripts/occupation_fte 2014.R` lines 26-32). The Workflow docx, section 1, gives the same call with `survey = "acs1"`.
2. **Universe.** `ESR %in% c(1,2)`, civilian employed (industry script lines 38 and 158; Workflow section 1). Age caps differ by script: `AGEP <= 64` (industry script lines 39 and 159; occupation script line 39), `AGEP <= 70` (`ACS_PUMS_FTE_industry_estimates_demo.R` line 28), `AGEP >= 16` with no cap (`ACS.R` line 18, `asc_find.R` line 14), no age filter at all (`ACS_2023.R` line 37, `occupation_fte 2014.R` line 35).
3. **Industry and occupation grouping.** `NAICSP` (the PUMS NAICS recode derived from the Census industry code) is cut to 2 or 3 characters with `strtrim`. At 2 digits, 31/32/33/3M become "31-33", 44/45/4M become "44-45", 48/49 become "48-49" (industry script lines 95-107; demo script lines 71-79). At 3 digits, codes that are not 3 characters and the mixed codes 33M, 3MS, 4MS, 52M, 53M, 92M are dropped (industry script lines 51-57; Workflow section 2 also drops 22S and 42S). Occupation uses `SOCP` cut to 2 characters (SOC major group) (`ACS_PUMS_occupation_estimates.R` line 92; `occupation_fte 2014.R` line 43).
4. **FTE.** Each person's weight and all 80 replicate weights are multiplied by `WKHP / 40`:
   ```r
   mutate(WKHP = WKHP/40) |>
   mutate_at(vars(starts_with("PWGTP")), list(~ . * WKHP))
   ```
   (`industry/scripts/ACS_PUMS_industry_estimates.R` lines 75-77 and 125-127; `ACS_PUMS_FTE_industry_estimates_demo.R` lines 93-95; `ACS_2023.R` lines 73-75; `ACS.R` lines 82-84; `asc_find.R` lines 68-70; `occupation_fte 2014.R` lines 61-64; Workflow section 4.) So

   **FTE = sum over employed persons of PWGTP x (WKHP / 40)**

   where WKHP is usual hours worked per week in the past 12 months. A 40-hour worker counts 1.0, a 20-hour worker 0.5, a 60-hour worker 1.5. Weeks worked (WKWN or WKW) is **not** used. There is no division by 2,000.
5. **Estimate and error.** `to_survey()` then `survey_count()` (or `survey_total()` in `ACS.R` lines 95-101) gives the weighted total and replicate SE; MOE = 1.96 x SE, r_MOE = MOE / estimate x 100, CV = SE / estimate x 100 (industry script lines 85-88; Workflow sections 3 and 5). Sector names are attached with a `case_when` (demo script lines 106-127) and occupation names by a join to `socc.csv` (`occupation_fte 2014.R` lines 77-86).
6. **Alternative tried, not used.** `ACS.R` lines 138-155 pull 1-year 2023 with `WKWN` and count only full-time, year-round workers (`WKHP >= 35` and `WKWN >= 50`) as an unweighted-SE sum of PWGTP. That is a headcount of full-time full-year workers, not an FTE, and it is not written to any file. `asc_find.R` lines 15-17 has the same idea commented out.

ELF/CPS FTE (files in `niosh-elf-cps/` and the CPS meatpacking file) comes from NIOSH's ELF query system. It is hours-based from CPS, with "Primary Job" or "All Jobs" variants; the exact ELF formula is not in these files. The ACS meatpacking workbook is the only file computing FTE as annual hours / 2,000 (formulas in columns E and F).

## Coverage for this project (Nebraska, 2020 to 2024)

**Industry, NAICS 2-digit FTE**

| Data year(s) | 1-year PUMS | 5-year PUMS |
|---|---|---|
| 2020 | none (2020 1-year was experimental) | `industry/outputs/FTE_2020_PUMS_5y_naics2.csv` (2016-2020) |
| 2021 | `industry/outputs/FTE_2021_PUMS_1y_naics2.csv` | `industry/outputs/FTE_2021_ACS5y_naics2.csv` (2017-2021); by sex/age/race/education in `fte_ne_naics2_2021_*.csv` (ages 16-70 only) |
| 2022 | **missing** | `industry/outputs/fte_ne_naics2_5y_2022.csv` (2018-2022) |
| 2023 | `industry/outputs-FTE-folder/fte_ne_naics2_1y_2023.csv` | `industry/outputs/fte_ne_naics2_5y_2023.csv` = `outputs-FTE-folder/fte_ne_naics2_5y_2023.csv` (2019-2023) |
| 2024 | **missing** | **missing** (the 2020-2024 5-year file named in the spec does not exist here) |

NAICS 3-digit FTE exists only for 5-year 2019, 2020, 2021 and 1-year 2018, 2019 (mislabeled pair), 2021. `ACS_2023.R` wrote a 2023 NAICS 3-digit file to K: that is not in this archive.

**Occupation, SOC 2-digit (major group) FTE**

| Data year(s) | 1-year PUMS | 5-year PUMS |
|---|---|---|
| 2020 | none | `occupation/outputs/FTE_2020_PUMS_5y_soc2.csv` (2016-2020) |
| 2021 | none | `occupation/outputs/FTE_2021_PUMS_5y_soc2.csv` |
| 2022 | none | `occupation/outputs/FTE_2022_PUMS_5y_soc2.csv` |
| 2023 | none | `occupation/outputs/FTE_2023_PUMS_5y_soc2.csv` |
| 2024 | none | **missing** |

No occupation file breaks out sex or age.

**1-year vs 5-year.** Mostly 5-year PUMS: every occupation file and the main industry series (2019 to 2023). 1-year PUMS was used for the industry files for 2018, 2019, 2021 and 2023, and the Workflow docx describes a 1-year method. `ACS_2023.R` pulls 1-year data but names its outputs "5y", so check provenance before trusting a filename.

**What the spec needs and is not here:** the ACS 5-year 2020-2024 PUMS FTE (or employed) estimate by NAICS sector and SOC major group, by sex. None of the pooled 2020-2024 windows exists, and no file here covers data year 2024 at all. Rebuilding it is a rerun of `asc_find.R` with `year = 2024`, plus `SEX` in the variables and the numerator-matching code choice below.

**Nothing here is the published C24030 / C24010 employed-worker count** that the spec prefers. The non-FTE PUMS employed counts (`2019_/2020_/2021_PUMS_*` pattern A files) stop at 2021.

## Caveats

1. **FTE definition differs from the spec.** The spec (`docs/acs-denominator-spec.md`, "FTE option") defines FTE as PWGTP x WKHP x WKWN / 2,000, i.e. annual hours. These files use PWGTP x WKHP / 40, i.e. usual weekly hours, and ignore weeks worked. A part-year worker (for example a 40-hour seasonal worker employed 20 weeks) counts as 1.0 FTE here and 0.4 under the spec. Industries with seasonal or part-year work (agriculture, construction, accommodation and food, education) will have higher FTE here than under the spec, and their rates will be lower.
2. **Code system mismatch with the death certificate.** Denominators are grouped by `NAICSP` and `SOCP`, the PUMS NAICS and SOC recodes, not by Census `INDP` / `OCCP`. The death certificate carries Census industry and occupation codes. Using these files means mapping each death certificate Census code to its NAICS sector or SOC major group (Census publishes the equivalents in its industry and occupation code lists), which the spec was hoping to avoid. At 2-digit level the mapping is mostly clean, but check codes that straddle sectors. A rerun grouping by `INDP` / `OCCP` ranges would match the death certificate directly.
3. **Code vintage.** PUMS from data year 2018 on uses 2018 Census codes, 2017 NAICS and 2018 SOC. The 5-year windows ending 2019 to 2022 mix pre-2018 and post-2018 records, and tidycensus returns the harmonized recode for that release. Confirm which Census code vintage the death certificate uses for 2020-2024 (spec open item 2).
4. **Age universe varies by file.** Ages 16-64 (5-year 2019 industry files), 16-70 (2021 demographic files), 16+ (2022 and 2023 files, all 2016+ occupation files). The spec numerator is age 16+ with no cap, so the capped files undercount the denominator. `FTE_2020_PUMS_5y_naics2.csv` totals 991,601, identical to the uncapped occupation 2020 total, although the retained script (`ACS_PUMS_industry_estimates.R` line 159) caps at 64. So the saved 2020 file was probably produced by a different version of the script, without the cap.
5. **Suspect or mislabeled files.**
   - 1-year NAICS 3-digit 2018 and 2019 files are byte-identical (both employed and FTE). One year is wrong.
   - `FTE_2014_PUMS_5y_soc2.csv` (total 576,652) and `FTE_2015_PUMS_5y_soc2.csv` (189,119) are far below the 0.95M NAICS totals for the same windows. `occupation_fte 2014.R` keeps only records with a `SOCP12` code (line 36), so records coded under the older SOC (`SOCP10`) are dropped without reweighting. Do not use either file.
   - `ACS_PUMS_occupation_estimates.R` labels as "2020" a pull of year 2014 (line 137). Its "2020" outputs are not in the archive, but any copy elsewhere with that name is 2010-2014 data.
   - `ACS_2023.R` pulls 1-year data (line 29) and writes files named "5y" (lines 193-194).
6. **2020 ACS.** The 2020 1-year release was experimental and no 1-year 2020 file exists here, which is correct. The 5-year windows 2016-2020 onward include 2020 data collected under pandemic conditions; Census released the 2016-2020 5-year as standard, but it carries the same collection issues.
7. **5-year arithmetic.** A 5-year FTE estimate is an average annual FTE for the window. For pooled 2020-2024 deaths, person-years of FTE = 5 x the 2020-2024 5-year estimate (spec, "Years and rate arithmetic").
8. **MOE level.** These outputs report 95% MOE (1.96 x SE). Census published tables use 90% (1.645 x SE). Do not mix the two without converting.
9. **ELF/CPS vs PUMS.** ELF FTE is built from CPS hours and is labeled "Primary Job" or "All Jobs"; PUMS WKHP is usual hours at all jobs in the past 12 months. CPS has a much smaller state sample. For 2008-2012 meatpacking, CPS/ELF gave about 36,900 FTE a year and ACS PUMS about 22,300, so the two sources are not interchangeable. ELF files here use Census 2002 industry codes and end in 2013 (plus a state total for 2017-2019); none covers 2020-2024.
10. **QWI/QCEW/OEWS count jobs, not people.** They are by place of work (not residence), exclude or undercount self-employed and most farm work (QCEW), and have no hours or FTE. They are not suitable as denominators for resident deaths by usual industry, as the spec notes.
11. **Hard-coded Census API key.** Five scripts contain a Census API key in plain text (`ACS.R` line 5; `ACS_2023.R`, `ACS_PUMS_industry_estimates.R`, `ACS_PUMS_occupation_estimates.R`, `occupation_fte 2014.R` line 7). If this repository is or will be shared, get a new key and move it to an environment variable (`Sys.getenv("CENSUS_API_KEY")`).
12. **Scripts that will not run as-is.** `ACS_2023.R` has leftover exploratory blocks that reference objects in the wrong class (lines 114-128, 144-157) and a `select(1,7,2:6)` on a 6-column table (line 191). `ACS_PUMS_FTE_industry_estimates_demo.R` ends with a dangling `summarise` (lines 416-419). All scripts write to K: paths or the working directory.
