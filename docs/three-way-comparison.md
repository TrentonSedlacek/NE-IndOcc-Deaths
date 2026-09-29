# Three-way comparison: NEVDRS sheet, earlier occupational health table, v8

Written 2026-09-28. Sources: the NEVDRS sector fact sheet (Can, 2020-2021); the earlier occupational health suicide-by-industry outputs from suicide_agg.R (team-archive/analyses/suicide/outputs/, NCHS annual file, NIOCCS, ages 16 and over, per 1,000 PUMS FTE by single year); v8 (NCHS annual file, NIOCCS, ages 16 to 64, PUMS 2020-2024 persons and FTE).

## Suicides, 2020-2021

| Sector | NEVDRS sheet: deaths, rate per 100,000 population | Occ health before: deaths, per 100,000 FTE | v8: deaths, per 100,000 persons / FTE |
|---|---|---|---|
| Construction | 72, 1.8 | 65, 43.8 | 56, 40.1 / 37.4 |
| Manufacturing | 55, 1.4 | 59, 25.7 | 51, 24.4 / 22.8 |
| Not in workforce | 84, 2.1 | not tabulated | 62, no rate |
| All coded sectors | | 440 | 365 |

Reading: the earlier occ health table and v8 are the same deaths, the same coder and the same denominator tool; the difference is the age cut (16 and over vs 16 to 64). The 440 coded-sector suicides in the earlier table equals the 440 all-worker total found at 16 and over from the Guardian exports (first recorded for v4 in docs/nevdrs-sectors-factsheet-review.md; v6 and v7 gave the same counts), so the two death sources also agree. The NEVDRS rates divide by the whole population and cannot be compared with per-worker rates.

Why NEVDRS counts 72 construction suicides where the certificates give 65 (16 and over): the NE DHHS dashboard page (docs/web-captures/ne-dhhs-about-nebraska-suicide-deaths-dashboard-data.md, lines 14 to 16) gives two reasons NEVDRS counts can differ from vital statistics: deaths are reclassified after investigation (a death not first reported as a suicide may later be one), and NEVDRS includes Nebraska residents who died out of state. The statewide totals point the same way: NEVDRS fact sheets give 289 (2020) and 284 (2021) suicides, against 269 and 277 from the Guardian exports (docs/death-cert-data-notes.md). Age (the sheet includes under-16s, at least in the not-in-workforce panel) and sector assignment are the other candidates. Whether the NCHS annual files carry residents who died out of state is not documented here (docs/death-cert-data-notes.md calls them occurrence files); the 440 match with the Guardian exports suggests any gap is small.

## Suicides, 2020-2023 (the four years both tables cover)

| Sector | Occ health before: deaths, per 100,000 FTE | v8: deaths (2020-2023), per 100,000 FTE (2020-2024) |
|---|---|---|
| Construction | 133, 43.6 | 115, 39.6 |
| Manufacturing | 119, 25.7 | 101, 22.3 |
| Agriculture | 78, 37.9 | 50, 27.9 |
| Transportation and warehousing | 76, 34.1 | 56, 28.1 |
| Accommodation and food | 51, 28.6 | 48, 32.1 |
| Health care | 62, 11.0 | 59, 11.7 |

By occupation the agreement is the same: construction and extraction trades 59.7 before vs 57.5 now per 100,000 FTE, and the ranking of the 22 groups is unchanged.

## Like for like: v9 (v8 with ages 16 and over) against the earlier occupational health table, suicides 2020-2021

v9 = v8 with the upper age limit removed; same NCHS file, same NIOCCS cache, same PUMS 2020-2024 tool. The earlier table's rate is the mean of its single-year rates per 1,000 FTE, times 100.

| Sector | Before: deaths, per 100,000 FTE | v9: deaths, per 100,000 persons / FTE |
|---|---|---|
| Construction | 65, 43.8 | 65, 44.2 / 41.5 |
| Manufacturing | 59, 25.7 | 59, 26.8 / 25.1 |
| Agriculture | 41, 41.2 | 41, 48.1 / 39.0 |
| Transportation and warehousing | 34, 29.7 | 34, 34.6 / 30.9 |
| Accommodation and food | 22, 24.8 | 22, 19.3 / 25.0 |
| Health care | 33, 11.8 | 33, 11.1 / 11.8 |
| Retail | 27, 13.7 | 27, 12.6 / 14.0 |
| All coded sectors | 440 | 440 |

Every sector count matches exactly. FTE rates match within a few percent (the earlier table used a different PUMS vintage for each year, and its denominator files do not share one age range: FTE_2020_PUMS_5y_naics2.csv comes from a script that keeps AGEP <= 64, per team-archive/denominators/README.md, while v9 counts workers 16 and over). v8 (16 to 64) is therefore the same pipeline with one age setting changed.
