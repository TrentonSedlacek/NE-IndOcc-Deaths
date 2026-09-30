# io_death_rates_v5.R: what changed from v4, and the real-run log for v6 to v9

The first part records the v5 changes. The sections from "First real run of v6" on record each later real run. The current release scripts are v8 (16 to 64) and v9 (16 and over).

Script: `/home/user/NE-IndOcc-Deaths/scripts/io_death_rates_v5.R` (169 lines). It started from `/home/user/NE-IndOcc-Deaths/scripts/drafts/io_death_rates_simple_sketch.R` and applies the fixes from `/home/user/NE-IndOcc-Deaths/docs/correctness-audit-v4.md` and `/home/user/NE-IndOcc-Deaths/docs/provenance-audit-v4.md`. Test: `/home/user/NE-IndOcc-Deaths/tests/synthetic_run.R` (61 checks, 0 failures). The v4 test is now `/home/user/NE-IndOcc-Deaths/tests/synthetic_run_v4.R`, unchanged, and still passes. Nothing in v5 suppresses any count.

## What v5 drops compared with v4

- The pneumoconiosis and injury_at_work outcomes. Four outcomes remain: suicide, overdose, overdose_opioid, opioid_ma_def.
- The overdose cause-text rule. Overdose is now the SUDORS ICD codes only (underlying X40-X44, Y10-Y14). Text-only candidates are counted in the QA file and listed in `Cache\review_{date}.csv` for a person to read. They are never added to a table.
- The rate ratio column (`rr`), which no source computes this way, and the sex U rows. Deaths with sex U are still counted in the T rows.
- The generic OUTCOMES table, the NchsAge and EventYear fallbacks, the raw-reply re-parse of the NIOCCS cache, the `run_nioccs` switch, and the `test_cfg` plumbing. Two `getOption()` calls remain so the test can point the script at temp folders.
- "inmate", "incarcerated" and "not employed" from the not-in-workforce words. The words kept are the Massachusetts list plus "retired".
- New in the output: a `grouping` column (industry or occupation) and an `acs_table` column.

## Correctness findings and what v5 does about them

| # | Finding | v5 |
|---|---|---|
| 1 | Dedup kept the earliest export, so a pending R99 copy beat the final X42 | Fixed. Each row carries its export year. The script sorts latest export first and keeps one row per DeathCertificateId. Tested with D2 (R99 in 2021, X42 + T40.4 in 2022). |
| 2 | Dedup key included year, so a death date moved across a year boundary counted twice | Fixed. Dedup is on the id alone, before the year filter. QA counts the ids whose year moved. Tested with D1. |
| 3 | Text rule counted crashes, falls, alcohol and suicides | Removed from the count (decision B). The review list uses one cause field at a time. |
| 4 | An unmapped ACS leaf under 0.5 percent was silently dropped | Fixed. Any non-subtotal row with a sex that is missing from `acs_group_map.csv` stops the run and names the label. The total check is kept. |
| 5 | An HTTP 200 error page was cached forever as Not coded | Fixed for new replies: a reply that is not JSON with an Industry part is not saved, so the pair is sent again next run. Error rows already in the v3 cache are kept, because pairs are never re-sent. They show in QA as `cached_pairs_without_codes`. To re-send them, delete those rows from the cache file. |
| 6 | Numerator (all decedents 16+ with a sector) and denominator (currently employed) are different populations | Not fixed. This is a design question (a 16-64 table, or unemployed before sector) that was not among the decisions. |
| 7 | NAICS 928110 made DoD civilians Military | Fixed. 928110 stays in sector 92. Military is NIOCCS 0096xx/0097xx, 00-98xx or SOC 55. |
| 8 | The age branch the test ran was not the real one | Fixed. Age always comes from DateOfBirth and DateOfDeath. The test data now has NchsAge 0 and real birth dates, and checks the 16th birthday. |
| 9 | Blank ids collapsed into one row | Fixed. Blank-id rows are dropped and counted in QA. |
| 10 | Text rule missed some overdoses | Moot for the count. The review list's drug words were widened (morphine, hydrocodone, tramadol, xylazine, alprazolam, benzodiazepine, acetaminophen, meth). |
| 11 | Unparsed dates were dropped without a count | Partly fixed. Unreadable DateOfDeath and DateOfBirth are counted in QA, and fractional serials are floored. A date that parses to the wrong value (for example "03/14/21" read as year 21) is still not detected. |
| 12 | The 2020-2021 cut uses the 2020-2024 ACS | Not fixed. The code comment says those rates are approximate and that counts are the comparison. |
| 13 | sums_ok could never fail | Fixed. Each table's T rows are compared with the outcome's count from the flag step, which runs before NIOCCS and grouping. The run stops if they differ. |
| 14 | Smaller items | A bare-string NIOCCS reply no longer stops the run (fixed). expand() and the carbon monoxide exclusion are gone with the rules that used them. Unchanged: a NIOCCS sector still beats non-worker text; SmicarAxis line prefixes are not stripped; numeric NAICS codes are not zero-padded; pct_of_deaths still divides by all cases, including the no-rate rows; blank ResidingStateNchs is not counted; ids saved by Excel in scientific notation are not checked. |

## What should change on the real data, and in which direction

- **Overdose drops.** v4's 808 (16+, 2020-2024) included the text-only cases. v5 should come in near 808 minus v4's text-only count (the notes record 68, so about 740), plus a few from the dedup fix. overdose_opioid drops for the same reason. Those text-only cases now appear in `text_candidates_not_counted` and on the review list.
- **Dedup adds a few, mostly overdoses and suicides.** About 53 deaths appear in two exports. Where the later export finalised the cause, v5 now counts it. Any death whose date moved across 31 December is now counted once, not twice (QA: `year_moved_between_exports`).
- **Military goes down and sector 92 goes up.** DoD civilians coded 928110 move out of Military into sector 92 and their SOC group, which raises the sector 92 rate slightly.
- **Not in workforce vs Not coded.** Decedents described only as inmate or "not employed" move to Not coded unless NIOCCS gave 009890 or 00-90/00-91. No rate changes, but the NEVDRS comparison count of 84 may move slightly.
- **A few pairs may be sent to NIOCCS** where a finalised record carries new industry or occupation text. Cached pairs are never re-sent.
- **The run may stop on the ACS map.** If the real `acs_2024.csv` has a leaf label that is not in the map, the message names it. Add that label to `C:\Users\tsedlac\Downloads\acs_group_map.csv` and rerun.
- **Unchanged:** suicide definition, opioid_ma_def definition, ACS denominators, worker-years, CI method.

## How to run

1. Save `C:\Users\tsedlac\Downloads\io_death_rates_v5.R` next to `C:\Users\tsedlac\Downloads\acs_group_map.csv`.
2. Leave `C:\Users\tsedlac\Downloads\Cache\nioccs_cache_v3.csv` and `C:\Users\tsedlac\Downloads\Cache\acs_2024.csv` where they are. v5 reuses them. It sends only new text pairs to NIOCCS and pulls the ACS only if `acs_2024.csv` is missing; that pull needs the `CENSUS_API_KEY` environment variable and the tidycensus package.
3. In R or RStudio on the DHHS machine (it reads `K:\Occupational Health Grant\data\dc\{YYYY}\`), run:
   `source("C:/Users/tsedlac/Downloads/io_death_rates_v5.R")`
4. Outputs, with today's date as `{date}`:
   - Tables (group level): `C:\Users\tsedlac\Downloads\Output\io_death_rates_{date}.csv` and `C:\Users\tsedlac\Downloads\Output\suicide_2020_2021_vs_nevdrs_{date}.csv`.
   - Record level, which stays in Cache: `C:\Users\tsedlac\Downloads\Cache\qa_{date}.txt`, `C:\Users\tsedlac\Downloads\Cache\cases_{date}.csv` and `C:\Users\tsedlac\Downloads\Cache\review_{date}.csv`.
   - The table file names match v4's, so a v4 run from the same day would be overwritten.

## First real run of v6 (2026-09-28, Trenton's machine)

Ran clean; every check passed. Versus v4 on the same exports: suicide 1,362 (unchanged), overdose 776 (was 808; the 32 text-only hits are no longer counted), overdose_opioid 410 (was 415), opioid_ma_def 436 (unchanged). 38 text-only candidates written to the review list. Overlap copies dropped 66; latest-export-wins changed no suicide count. NEVDRS 2020-2021 cut unchanged: 65 / 60 / 66 against 72 / 55 / 84. Headline 2020-2024 rates per 100,000 worker-years: construction suicide 48.0 (174 deaths), agriculture 46.9, all workers 22.1; construction overdose 29.5 (107), accommodation and food 25.3, all workers 11.0.

## First real run of v7 (2026-09-28)

Suicide only, readable rewrite. Ran clean; every count and rate identical to v6: 1,362 suicides, 66 overlap copies dropped, 18 Military, 159 Not in workforce, 53 Not coded, construction 174 (48.0 per 100,000 worker-years), all workers 1,132 (22.1), 2020-2021 cut 65 / 60 / 66 against 72 / 55 / 84. Output: C:\Users\tsedlac\Downloads\Output\suicide_io_rates_20260928.csv. v7 was the release script until v8 replaced it the same day.

## First real run of v8 (2026-09-28): Derry's settings

NCHS annual files dth20 to dth24, residents 16 to 64, NIOCCS, PUMS 2020-2024 5-year denominators (persons and FTE), suicide and overdose. Ran clean; PUMS 2024 5-year pulled through tidycensus; only 150 new NIOCCS pairs (NCHS text mostly matches the Guardian text already cached). Civilian employed 16-64: 952,391 persons, 951,076 FTE.

| | Suicides | Rate, persons | Rate, FTE |
|---|---|---|---|
| Construction (23) | 148 | 42.4 | 39.6 |
| Agriculture (11) | 62 | 35.0 | 27.9 |
| Manufacturing (31-33) | 125 | 23.9 | 22.3 |
| All workers | 921 | 19.3 | 19.4 |
| Construction trades (SOC 47) | 143 | 60.8 | 57.5 |

Suicides 16-64 by year: 219 / 223 / 233 / 227 / 221 (1,123). Overdose 710, opioid 389. 2020-2021 cut: construction 56, manufacturing 51, not in workforce 62 against the sheet's 72 / 55 / 84 (the sheet is all ages; ours is 16-64. The NEVDRS dashboard page also says NEVDRS reclassifies deaths after investigation and includes residents who died out of state; either can move sheet counts away from certificate counts). Output: C:\Users\tsedlac\Downloads\Output\io_death_rates_v8_20260928.csv.

## First real run of v9 (2026-09-28)

v8 with the upper age limit removed (ages 16 and over); nothing else changed. Suicides by sector for 2020-2021 match the earlier occupational health table (Chris and Jean's suicide_agg.R outputs in team-archive/analyses/suicide/outputs/) exactly: all 20 sectors, 440 in total; construction 65, manufacturing 59. NCHS (v9) and Guardian (v7) suicide totals at 16 and over differ by 10 over 2020-2024 (reported by Trenton; the two totals are not recorded here). Details and rates: docs/three-way-comparison.md.
