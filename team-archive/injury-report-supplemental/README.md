# Injury Report, Occupational Health Supplemental (team archive)

Moved from `Injury Report - Occ Health Supplemental/` on 2026-09-28. Supplemental occupational health tables for a Nebraska injury report, built from Nebraska Hospital Discharge Data (HDD), inpatient files 2016 to 2020.

The script selects Nebraska-resident inpatient stays, age 16 and over, that were either paid by workers' compensation (`PAYERCD == "05"`) or carry an ICD-10-CM work-related code (Y99.0, Y99.1, Y92.6x, Y92.7x, Z04.2, Z57.6, Z57.8). It classifies them by mechanism and intent using the CDC ICD-10-CM injury cause matrices (non-poisoning and poisoning, 2021 revision) and by body region using the proposed ICD-10-CM injury diagnosis matrix, then writes the count tables below. The source SAS files (`IP16.sas7bdat` to `IP20_Old.sas7bdat`) and the matrix workbooks are not in the repo.

## Inventory

| File | What it is | Source | Years | Geography | Industry coding |
|---|---|---|---|---|---|
| `wc_injury_hdd_analysis.R` | Analysis script (1,067 lines, highly repetitive): import, work-related filter, cause-by-intent flags (unintentional, self-harm, assault, undetermined, legal intervention), body region, age by sex. Some later sections reference objects that are never created, so it does not run end to end. | NE HDD inpatient; CDC injury matrices | 2016 to 2020 | Nebraska residents | None |
| `wc_hdd_all_injuries_demo_cnt.csv` | Work-related injury stays by age group and sex (1,824 total). | Script output | 2016 to 2020 combined | Nebraska | None |
| `wc_hdd_cause_unintent_cnt.csv` | Unintentional injury stays by mechanism (first match); falls 438, machinery 103, 338 unclassified. | Script output | 2016 to 2020 | Nebraska | None |
| `wc_hdd_cause_unintent_cnt2.csv` | Same, as flag sums (a stay can count in several mechanisms), plus a hand-built summary block by intent. | Script output, hand edited | 2016 to 2020 | Nebraska | None |
| `wc_hdd_cause_unintent_body_cnt.csv` | Unintentional mechanism by body region. | Script output | 2016 to 2020 | Nebraska | None |
| `wc_hdd_cause_intent_cnt.csv` | Intentional self-harm flags by mechanism (2 stays: 1 fall, 1 unspecified). | Script output | 2016 to 2020 | Nebraska | None |
| `wc_hdd_cause_assault_cnt.csv` | Assault stays by mechanism (14 classified). | Script output | 2016 to 2020 | Nebraska | None |
| `wc_hdd_cause_undetermined_cnt.csv` | Undetermined intent stays (1 cut/pierce). | Script output | 2016 to 2020 | Nebraska | None |

## Relevance to the industry and occupation deaths project

Minimal. This is nonfatal hospital data with no industry or occupation field, and work-relatedness is inferred from payer and Y/Z codes. It does not supply numerators or denominators for suicide or overdose deaths by industry. The only overlap is methodological: it shows the team's use of the CDC ICD-10-CM intent and mechanism matrices, and it confirms that self-harm and poisoning among work-related hospital stays are very rare in this data.
