# Note (2026-09-29)

Historical. This audit covers the first, long version of the script, now at scripts/old/io_death_rates_v1_long.R, as it stood on 2026-09-28. Superseded since: (a) every suppression item below (findings 1 and 22, the "floor 6" line, decision 6) is withdrawn; per CLAUDE.md no script suppresses, and scripts/old/io_death_rates_v1_long.R line 697 and every later version say "No suppression"; the DHHS floor is applied only at public release. (b) The data use question (finding 25, decision 5) is settled: NIOCCS use was approved by Trenton on 2026-09-29. (c) tests/synthetic_run.R now tests scripts/io_death_rates_v6.R (see docs/v5-changes.md), not the 40-check test described here. (d) The release scripts are now scripts/io_death_rates_v8.R and scripts/io_death_rates_v9.R.

# Audit of scripts/io_death_rates.R

Audited and fixed 2026-09-28. Checked against docs/analysis-plan.md, docs/provenance-comparison.md section C, the DC template (dc_condition_surveillance.sas), OHIs subindicators.sas (lines 360 to 470 and 894 to 1000), dc-data-sources.md, the team's NIOCCS scripts, the denominators README and docs/acs-denominator-spec.md.

## How it was tested

- R 4.3.3 was installed in the cloud container (apt). The script parses.
- `tests/synthetic_run.R` makes fake data and runs the whole script (sections 0 to 9) with no network. The fake data has 5 yearly Guardian exports (CSV for 2020 to 2023, xlsx for 2024), about 225 rows with the 61 plan fields plus 9 others (names, DOB, county), and random codes and text. It also includes non-residents, overlap copies, ROSTER rows with EventYear 0, age units 1 to 6 and 9, age 999, and blank, "STUDENT", "RETIRED", "US ARMY" and "CHILD CARE" industry text. 21 planted records each have a known expected result. The NIOCCS input is a fake cache in which one pair is missing and one reply is FAILED. The ACS input is fake C24030 and C24010 CSVs in the `fetch_acs_denominators.py` format, 55 and 73 variables, with the label outline listed below.
- Result: 40 of 40 checks pass. They cover the case definitions, filters, dedupe, non-rate groups, ACS leaf mapping and totals, rate and Poisson arithmetic, worker-years x 5 and x 2, percent columns, suppression, and where files are written.
- The ORIGINAL script was also run on the same fake data, with tidycensus stubbed. It ran without an error but gave wrong results. The findings marked "confirmed" below were seen in that run.
- Not tested: the live NIOCCS call, the tidycensus branch (tidycensus could not be installed for R 4.3 here), the real Census labels (api.census.gov is blocked), and real Guardian files.

## Findings

Severity: High = wrong numbers or a disclosure risk. Medium = wrong in some cases, or does not match the SAS or the plan. Low = robustness or readability.

| # | Sev | Section | What was wrong | What changed |
|---|---|---|---|---|
| 1 | High | 7 | Suppression blanked the rate but left the 1 to 5 count in the `deaths` column (and `pct_of_all_deaths`) of every written table. The fake run printed 183 cells with 1 to 5 deaths (confirmed). | Withdrawn (see note at top): no script suppresses; full counts are written. |
| 2 | High | 6 | `pct_of_all_deaths` compared `counts$sex == sex` across vectors of different lengths (recycling), so the percents were wrong. Male percents summed to 105.9 (confirmed). | Now computed per sex with group_by. The test checks that they sum to 100. |
| 3 | High | 2 | The overdose text branch took any text hit. That included suicides by overdose (X64), homicides, and natural "digoxin toxicity" deaths (confirmed on planted records). SUDORS covers unintentional and undetermined intent only. | A text-only hit counts only when the manner is not S, H or N. Text-only cases go on the review list and are counted in QA. This needs a human decision (see below). |
| 4 | High | 3 | Cache keys: `read_csv` turns "" into NA, so every pair with a blank side ("" / "STUDENT", "" / "RETIRED", "" / "") missed the cache on every run. They were re-sent to CDC and never joined back (confirmed). The "" / "" pair was also sent to CDC. A duplicate key in the cache would have duplicated deaths in the join. | The cache is read with `na = character()`, blank-blank pairs are never sent, and the cache is deduplicated before the join. |
| 5 | Medium | 3 | `review_flag` was NA for most records (`NA | FALSE`), so `filter()` dropped them from the review list: 62 of 89 in the fake run (confirmed). The plan's "every record in the top three sectors" review was not implemented. | `review_reason` is built with case_when and has no NA. The top three sectors for suicide and for overdose are added. |
| 6 | Medium | 2 | The suicide, overdose and MA ranges used string comparison (`code3 >= "X60"`), which depends on locale collation. The DC-HDD docs say ranges must be spelled out code by code. | Code lists are spelled out: `icd_list("X", 60, 84)`, used with `%in%`. |
| 7 | Medium | 2 | The alcohol-only exclusion checked T40 to T50. Drug poisoning is T36 to T50. | Changed to T36 to T50. |
| 8 | Medium | 1 | The dedupe key was DeathCertificateId alone. DC template line 28 uses DeathCertificateId and EventYear. | Now matches the SAS. QA reports how many ids appear in two event years (expect 0). |
| 9 | Medium | 1 | The script read the xlsx only. The plan and all the SAS read the saved CSV. | Reads the CSV when present and falls back to the xlsx. |
| 10 | Medium | 4 | The cross-check read the Census code-list xlsx and guessed its columns by regex. The published list has title rows above the header, so this would probably have failed silently. It also did not match OHIs, which uses the hard-coded format `cind2sec` (lines 87 to 91). | Uses the OHIs `cind2sec` ranges directly. Code x 10, as in OHIs line 393. |
| 11 | Medium | 4 (SAS) | Bug in OHIs `cind2sec`: real estate is 7071-7190, so certificate code 707 (x10 = 7070) falls to UNK. | R uses 7070. **Fix subindicators.sas line 88 too.** |
| 12 | Medium | 8 | `sum_check` compared two figures that are equal by construction, so it could never fail. | Now compares the table rows against the case count taken straight from the data (plan section 5). |
| 13 | Medium | 5 | ACS rows were matched by regex on leaf text, with no check that every leaf was mapped or that the leaves added up to the table total. Parents were excluded only because their labels end in ":". | Leaves are detected structurally (no row under them) and matched on exact names. The script stops on any unmapped leaf, on a group count other than 20 or 22, or on a leaf sum more than 0.5% off `_001`. |
| 14 | Medium | 3 | The military rule included "sector 92 and text says army" (not in the plan) and gave NA when there was no code. | Plan rule: NAICS 928110 or SOC 55. Never NA. |
| 15 | Medium | 3 | The non-worker regex also matched "child" inside "child care", "minor", "inmate" and "prisoner", and applied only when the record was uncoded. A bare "RETIRED" occupation with a codable industry kept its sector. | Uses the plan's word list (plus housewife and disability) with word boundaries. A field that is only a non-worker word always makes the record Not in workforce, in the table that field belongs to. |
| 16 | Medium | 3 | NIOCCS field names were guessed (`CensusIndustryCode`, `CensusCode`, `Score`, `Confidence`). | Uses only the names the team's scripts use: NAICSCode, CensusIndustryTitle, SOCCode, SOCTitle, CensusOccupationTitle. The full JSON reply is cached. The confidence field names are config items set to NA, with a comment saying they are unknown. |
| 17 | Low | 6 | Codes outside the 20 sectors or 22 groups (for example 00, 99, 10) became their own rows with no denominator but were still counted in All workers. | They go to Not coded. |
| 18 | Low | 6 | Rate ratio CI for 0 deaths came out as 0 or NaN (confirmed). | NA when deaths = 0. |
| 19 | Low | 2 | `paste` turned NA text into "NA". `sapply` returned a vector, not a matrix, for 1 row. | coalesce to "". The matrix is built with as.matrix. |
| 20 | Low | 1 | Sex codes "1" and "2" were not mapped. OHIs `$sexf` maps them. | Mapped. Age uses trunc (SAS int). Non-numbers become missing quietly, as `?? 8.` does in SAS. |
| 21 | Low | 0, 5 | Required a Census key at the top even when it was not needed, and called `census_api_key()`. | The key is read only in the tidycensus branch and passed as `key=`. A saved `fetch_acs_denominators.py` CSV is used when present. |
| 22 | Low | 8, 9 | The QA file (unsuppressed counts) was written to Output. | Written to Cache. Output gets group-level tables (full counts, no suppression) and the methods note only. |
| 23 | Low | 8 | By-year totals were 16+ only. The plan compares them with all-ages Vital Statistics and SUDORS sheets. | Adds all-ages resident totals by year. |
| 24 | Low | 6 | The MA all-intent definition was only a console message. | Added as table `ma_opioid_ind`. |
| 25 | Info | 0 | `run_nioccs = TRUE` by default, before the data use agreement question (plan section 4) is answered. | Default is FALSE, with a comment. |

Checked and correct in the original, and kept: the age recode, the year filter, the resident filter, the 41-field compress and prefix scan, the 5-field text scan, the suicide set (X60-X84, Y87.0, U03, with the UO3 typo avoided), the opioid T40.0-.4 and T40.6 subset on the 40 multiple-cause fields, the MA definition, the NAICS sector collapse, the exact Poisson limits, worker-years = estimate x years, and floor 6 / unstable under 20 (OHIs lines 931 and 932; 0 deaths is "unstable" as in SAS).

## ACS mapping verification

api.census.gov could not be reached, so none of these names were checked against the live metadata. The status below is from recall of the 2019-onward labels (post-2018 SOC). The script is protected either way: it stops and names any leaf it cannot map, and it checks that the leaves add up to the total.

**C24030** (55 variables: total, then 27 rows per sex). Every pair the brief asked about has its own leaf, and the parent rows are not leaves, so nothing is double counted.

| Leaf | Sector | Parent (excluded) | Status |
|---|---|---|---|
| Agriculture, forestry, fishing and hunting | 11 | Agriculture, forestry, fishing and hunting, and mining: | UNVERIFIED, high confidence |
| Mining, quarrying, and oil and gas extraction | 21 | same | UNVERIFIED, high confidence |
| Construction; Manufacturing; Wholesale trade; Retail trade | 23; 31-33; 42; 44-45 | none | UNVERIFIED, high confidence |
| Transportation and warehousing / Utilities | 48-49 / 22 | Transportation and warehousing, and utilities: | UNVERIFIED, high confidence |
| Information | 51 | none | UNVERIFIED, high confidence |
| Finance and insurance / Real estate and rental and leasing | 52 / 53 | Finance and insurance, and real estate, and rental and leasing: | UNVERIFIED, high confidence |
| Professional, scientific, and technical services / Management of companies and enterprises / Administrative and support and waste management services | 54 / 55 / 56 | Professional, scientific, and management, and administrative, and waste management services: | UNVERIFIED, high confidence |
| Educational services / Health care and social assistance | 61 / 62 | Educational services, and health care and social assistance: | UNVERIFIED, high confidence |
| Arts, entertainment, and recreation / Accommodation and food services | 71 / 72 | Arts, entertainment, and recreation, and accommodation and food services: | UNVERIFIED, high confidence |
| Other services, except public administration; Public administration | 81; 92 | none | UNVERIFIED, high confidence |

**C24010** (73 variables: total, then 36 rows per sex). Yes: Healthcare practitioners is split into two leaves, Protective service into two, and Transportation vs Material moving into two. The script sums each pair into SOC 29, 33 and 53. That gives 25 leaves for 22 groups.

| Leaf | SOC | Status |
|---|---|---|
| Management occupations; Business and financial operations occupations | 11; 13 | UNVERIFIED, high confidence |
| Computer and mathematical; Architecture and engineering; Life, physical, and social science occupations | 15; 17; 19 | UNVERIFIED, high confidence |
| Community and social service; Legal; Arts, design, entertainment, sports, and media occupations | 21; 23; 27 | UNVERIFIED, high confidence |
| Educational instruction, and library occupations | 25 | UNVERIFIED, medium (the comma after "instruction" is from recall) |
| Health diagnosing and treating practitioners and other technical occupations | 29 | UNVERIFIED, medium |
| Health technologists and technicians | 29 | UNVERIFIED, high confidence |
| Healthcare support occupations | 31 | UNVERIFIED, high confidence |
| Firefighting and prevention, and other protective service workers including supervisors | 33 | UNVERIFIED, medium |
| Law enforcement workers including supervisors | 33 | UNVERIFIED, medium |
| Food preparation and serving related; Building and grounds cleaning and maintenance; Personal care and service occupations | 35; 37; 39 | UNVERIFIED, high confidence |
| Sales and related; Office and administrative support occupations | 41; 43 | UNVERIFIED, high confidence |
| Farming, fishing, and forestry; Construction and extraction; Installation, maintenance, and repair occupations | 45; 47; 49 | UNVERIFIED, high confidence |
| Production occupations | 51 | UNVERIFIED, high confidence |
| Transportation occupations; Material moving occupations | 53 | UNVERIFIED, high confidence |

To close this out: run `python scripts/fetch_acs_denominators.py` on a machine with internet access, save the two CSVs in `cfg$acs_dir`, and run the script. It either runs or names the leaf to fix.

## Needs a human decision

1. **Text-only overdose cases.** They count only when the manner is not suicide, homicide or natural, and they are listed for review. Should a text-only case whose underlying cause is coded to something else also be dropped? (Trenton or Derry, against the SUDORS abstraction rules.)
2. **Non-worker word list and the "RETIRED" rule.** Now: homemaker, housewife, student, retired, unemployed, never worked, disabled, disability, child. Infant, minor, inmate and prisoner were dropped. Should "NONE" be Not coded or Not in workforce?
3. **Military = NAICS 928110.** This also catches civilian Department of Defense employees, who are in the ACS civilian denominator. This is the plan's rule; confirm it.
4. **NIOCCS confidence.** Look up the field name in one cached `raw_json` and set `nioccs_ind_conf_field`, `nioccs_occ_conf_field` and `nioccs_conf_min`.
5. **Data use agreement** for sending I/O text to CDC. Settled: approved by Trenton, 2026-09-29.
6. **Complementary suppression.** Withdrawn from the analysis. It is a question for the one-time public release step only, when Trenton asks for it.
7. **Rate ratio CI.** It treats the sector count and the all-worker count as independent, which makes it slightly wide. Acceptable for a crude table, but say so in the methods.
8. **Not done:** the occupation cross-check (plan step 5, second half; no SAS rule exists for Census occupation code ranges) and the FTE column (plan step 6; needs a PUMS 2020-2024 rerun).
9. **SAS fix at source:** subindicators.sas line 88, 7071 should be 7070.
