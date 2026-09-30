# BLS API and data (team archive)

Moved from `BLS API & data/` on 2026-09-28. Work by Chris Austin (NE DHHS occupational health), roughly 2021 to 2024. Pulls Nebraska data from the U.S. Bureau of Labor Statistics (BLS) Public Data API v2 (R package `blsAPI`) for two programs: the Census of Fatal Occupational Injuries (CFOI) and the Survey of Occupational Injuries and Illnesses (SOII).

## FTE denominators by industry: NO

No file in this folder contains an FTE, hours-worked, or employment denominator by industry for Nebraska.

- The CFOI files are fatality counts only (every series has datatype code 8, "number of fatalities"). No CFOI rate series and no hours or employment series were pulled. BLS publishes CFOI rates per 100,000 FTE for the nation and some state tables, but none are in this folder.
- The SOII files contain rates per 100 or per 10,000 full-time workers, which BLS computes internally from employer-reported hours (rate = cases / total hours x 200,000,000 for per 10,000). The hours themselves are not published in these files, so the denominator cannot be recovered. These rates are for nonfatal injuries and illnesses, private industry and state/local government, 2014 to 2021.
- The "Hours (...)" categories in `cs_industry.csv` are hours on duty before the incident (a case characteristic), not hours worked by the workforce.
- The only employment series in the R script is a QCEW (ENU) pull of dairy cattle employment by county for the HPAI work (see below); its output is not saved here.

For FTE or employed-worker denominators by industry, use the ACS files elsewhere in the repo (see `docs/acs-denominator-spec.md`).

## BLS series pulled (from `work_fatality_BLS_api.R`)

| Series ID pattern | Program | Structure | Meaning | Years requested |
|---|---|---|---|---|
| `FWU` + category(3) + industry(6) + datatype(1) + case(1) + `S31` | CFOI (FW) | e.g. `FWU00X00000080S31` | Fatal work injuries, Nebraska (area S31), datatype 8 = number of fatalities | 2011 to 2020 |
| `FWU00X......8[1,6,7,8]S31` | CFOI | category 00X, case 1/6/7/8 | Total fatalities by detailed private, federal, state, local government industry | 2011 to 2020 |
| `FWU00X......8[1,6,7,8]S31` with categories E1X to E6X | CFOI | event categories | Fatalities by industry and event or exposure | 2011 to 2020 |
| `FWU{ACX..AIX,GMX,GFX,R..}...8[0,E]S31` | CFOI | age, sex, race categories | Fatalities by demographic group and by major event (1XXXXX to 6XXXXX) | 2011 to 2020 |
| `FWU00X` + `..2...` + `80S31` | CFOI | case 0, supersector level 2 codes | Total fatalities, all sectors, by NAICS sector | 2011 to 2020 |
| `FWU00XGP2AFH80S31`, `FWU00XSP2UTL80S31`, ... (19 sector IDs), `FWUGMX00000080S31`, `FWUAEX00000080S31`, ... | CFOI | hard-coded in notes section | Nebraska fatalities by NAICS sector, sex, and age group (used for 2015 to 2019 treemap/bar charts) | 2015 to 2019 in charts |
| `ISU` + supersector(3) + industry(6) + datatype(1) + case(1) + area(3) | SOII industry (IS) | e.g. `ISUTTU49300001131` | Nonfatal injury and illness counts and rates per 100 or 10,000 full-time workers, area 031/131/231/... = Nebraska by ownership | 2016 to 2020 (series span 2014 to 2021) |
| `CSU` + category(3) + industry(6) + datatype(1) + case(1) + ownership(1) + state(2) | SOII case and demographics (CS) | e.g. `CSU00XGP2AFH33100` | Datatype 3 = rate per 10,000 full-time workers, case 3 = days away from work, state 00 = U.S. national; 20 NAICS sectors | 2016 to 2020 |
| `ENU` + area(5) + datatype(1) + size(1) + ownership(1) + industry(5) | QCEW (EN) | e.g. `ENU3100010511212` | Private employment (datatype 1), NAICS 11212 dairy cattle and milk production, Nebraska statewide (31000) and 30 counties | 2016 to 2022 |

Two BLS API registration keys are hard-coded in the R script (labeled as a gmail account and a nebraska.gov account). Treat them as exposed; they should be rotated and moved to an environment variable if this script is ever reused.

## Inventory

| File | What it is | Source | Years | Geography | Industry coding level |
|---|---|---|---|---|---|
| `work_fatality_BLS_api.R` | Working script, not a clean pipeline. Filters series catalogs, batches series IDs (50 per call) to the BLS API, joins metadata, writes CSVs, then a long "notes" section with treemap, bar, donut, and lollipop charts of Nebraska fatalities by sector (share of 242 deaths, 2015 to 2019). Also the QCEW dairy employment pull. References files not in the folder (`work_fatality_2015_2019.csv`, `soii_nebraska_cs_series.csv`, `fw.series` objects). | BLS API v2 | 2011 to 2022 | Nebraska; U.S. for CS rates | NAICS sector to 6-digit |
| `BLS_report.Rmd` | "Occ Health Notes" HTML report (2023-08-02): SOII respiratory illness charts with hand-typed values, plus an ESSENCE syndromic surveillance preview of work-related ED visits. Contains plaintext SQL Server usernames and passwords for two DHHS databases; those credentials should be rotated and removed. | SOII; NE ESSENCE | 2016 to 2021 (SOII), 2019 onward (ED) | Nebraska | NAICS sector and selected subsectors; SOC major groups |
| `BLS_report_resp.Rmd` | Cleaned version: "Employer-reported respiratory illnesses" report. Hand-typed SOII values: illness cases 2016 to 2020, respiratory illness rates per 10,000 FTE for health care, manufacturing (animal slaughtering 396.5 in 2020), retail. No database code. | SOII | 2016 to 2021 | Nebraska private industry | Sector, 3- to 4-digit NAICS |
| `cfoi_nebraska_series.csv` | CFOI series catalog for Nebraska: 65,924 series with category, case, industry, event, source, occupation codes and begin/end years. All datatype 8 (counts). Includes workplace suicide series (event E1C, "Suicides (Self-inflicted injury, intentional)") but only for 2016. | BLS FW series file | series span 2011 to 2020 | Nebraska (S31) | NAICS 2- to 6-digit, BLS supersectors, SOC |
| `cfoi_nebraska_industries_allsectors.csv` | CFOI fatality counts by industry, all sectors (773 rows). Total Nebraska fatal work injuries: 39, 48, 39, 55, 50, 60, 35, 44, 53, 48 for 2011 to 2020. | BLS API | 2011 to 2020 | Nebraska | NAICS 3- to 6-digit plus GP1/GP2/SP1/SP2 supersector and sector codes |
| `cfoi_nebraska_fatalities_demo_exposure.csv` | CFOI counts by sex, age, race, and major event (421 rows). | BLS API | 2011 to 2020 | Nebraska | All industries only |
| `soii_nebraska_series.csv` | SOII industry series catalog for Nebraska: 12,092 series, 36 data types (case counts in thousands and rates per 100 or 10,000 full-time workers by establishment size class), 20 case types. | BLS IS series file | series span 2014 to 2021 | Nebraska, by ownership | Supersector, NAICS 3- to 6-digit |
| `SOII_injury_industry.csv` | SOII injury counts and rates per 100 full-time workers, total recordable cases and RSEs (3,432 rows). | BLS API | 2014 to 2020 | Nebraska, by ownership | NAICS 3- to 6-digit |
| `SOII_inj_ill_industry.csv` | SOII injury and illness counts and rates (per 100 and per 10,000 full-time workers), total recordable and DART cases (3,400 rows). | BLS API | 2016 to 2020 | Nebraska, by ownership | NAICS 3- to 6-digit |
| `cs_industry.csv` | SOII case and demographic data (27,997 rows): days-away-from-work case counts and rates per 10,000 full-time workers by characteristic (age, sex, race, event, source, nature, hours on duty, weekday) by sector or by occupation. | BLS API (CS) | 2016 to 2020 | Nebraska | 19 NAICS sectors (GP2/SP2); SOC detailed occupation |
| `SOII_industry.csv` | `cs_industry.csv` stacked with `SOII_inj_ill_industry.csv` (31,528 rows). | Derived | 2016 to 2020 | Nebraska | As above |
| `cs_industry_US.csv` | National SOII days-away-from-work rates per 10,000 full-time workers for 20 sectors (131 rows). | BLS API (CS) | 2016 to 2020 | United States | NAICS sector |

## Relevance to the industry and occupation deaths project

Low. Nothing here is a usable denominator: CFOI files are counts only, and SOII rates are nonfatal and embed hours BLS does not release. CFOI counts only deaths from injuries at work, so the handful of Nebraska workplace suicides (2016 only) and drug-related work deaths are a tiny, different population from the death-certificate suicides and overdoses the project counts by usual industry. The folder is useful for context (sector code conventions, a sanity check that BLS rates are per full-time equivalent workers, and prior team charts), and the two credential exposures above should be flagged to the team.
