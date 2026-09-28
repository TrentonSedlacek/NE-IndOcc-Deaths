# Review: "CDC NEVDRS - Suicide Deaths by Sectors in 2020 and 2021" (Can Ceyhan, original version)

Reviewed 2026-09-28. File: source-docs/ne-dhhs/unpublished/Suicide-Deaths-by-Sectors-2020-2021-Final-1.pdf (one page, three panels; text in extracted-text/ne-dhhs/unpublished/). Forwarded by Derry Stover, who says Can later worked with Chris to revise it, including a move to FTE-based rates. This review is of the original only. The revised version has not been seen.

## What the sheet shows

Three panels, each with the same layout as the published NEVDRS fact sheets: headline count and rate, demographics with percent of deaths and rate per 100,000, cause of death, month or quarter, decedent circumstances, and a census tract rate map.

| Panel | Deaths, 2020 + 2021 | Headline rate as printed | Circumstance base |
|---|---|---|---|
| Not in workforce | 84 | 2.1 per 100,000 population | 76 cases |
| Construction sector workers | 72 | 1.8 per 100,000 population | 68 cases |
| Manufacturing sector workers | 55 | 1.4 per 100,000 population | 46 cases |

The 70 to 72 figure Trenton recalled is the construction death count, not a rate.

## The denominator is total population, not workers

Every rate on the sheet is per 100,000 of the whole Nebraska population (the legend reads "2020 and 2021 Nebraska Population"). Check: 72 deaths over two years divided by roughly 1.96 million residents times 2 gives 1.8 per 100,000. The subgroup rates use the matching population strata: the construction 30-39 rate of 4.2 is construction deaths aged 30-39 divided by all Nebraskans aged 30-39.

That makes the sector rates meaningless as risk measures. A construction rate of 1.8 per 100,000 population sits below the statewide suicide rate of about 14 to 15 only because the denominator includes everyone who is not a construction worker. Per worker, the same 72 deaths give a rate many times higher; the exact figure depends on the worker count used, which is the ACS or FTE question already open in docs/acs-denominator-spec.md. Derry's note that the revision moved to FTE-based rates says this was recognized.

## Other things to raise

1. Sector assignment is not stated anywhere on the sheet. No data source line, no note on whether "construction" came from the death certificate industry code, the industry text, or the NVDRS current occupation free text, and no code list. The NVDRS Coding Manual says abstractors copy the death certificate industry code and text as-is (section 3.2.4), so the certificate is the likely source, but that needs confirming.
2. "Not in workforce" is mostly children and students. 46.4 percent of that panel is aged 10-19 and 45.2 percent had less than a high school education. This panel is largely youth suicide relabeled by employment status, and its comparison with two working sectors is not like for like. If a non-worker group is kept, it needs its own denominator (ACS not-in-labor-force, 16 and over) and should exclude ages under 16.
3. Why these two sectors. No all-sector table accompanies the sheet, so there is no way to tell whether construction and manufacturing were the highest, the largest, or chosen in advance. Ask for the sector table with counts.
4. Census tract maps of 72 and 55 deaths. Tract-level rates from this few deaths are close to individual case locations. The NEVDRS dashboard suppresses counts of 1 to 5, and the tract maps cannot meet that rule. This is a disclosure question, separate from the denominator question.
5. Age bands differ by panel (10-19 through 50+ for not in workforce; 20-29 through 70+ for construction; 10-29 through 60+ for manufacturing). Fine for a single panel, but it blocks side-by-side comparison, and 10-29 in manufacturing suggests a decedent under 16 or a band chosen to hide a small cell.
6. Rates for some very small cells are printed. For example, the construction 70+ rate of 2.6 comes from 13.9 percent of 72, so 10 deaths, and the not-in-workforce Black NH rate of 5.4 comes from 10 deaths. These are at or below the 20-death instability threshold the CDC dashboards and the OHIs scaffold both flag.
7. Narrative text looks templated. Each cause of death paragraph opens "In the fourth quarter of 2020 and 2021" even where it is not about the fourth quarter. Worth a light edit before anything goes out.
8. Circumstance percentages use different bases (76, 68, 46 cases) than the headline counts, which is standard NVDRS practice (circumstances known), but the sheet does not say so beyond a small footnote.

## What this changes in the plan

Nothing in the plan changes; it confirms it. The occupational health team should produce the sector table from the same death certificates with an employed-worker denominator (ACS, or FTE from PUMS if that is the direction Chris took) and set it beside whatever the revised NEVDRS sheet says. The numerator counts (84, 72, 55) are the first thing to reconcile: if the DC pull, using the certificate industry code, reproduces 72 construction suicides for 2020-2021 among residents, the only remaining difference is the denominator.

## Questions to add for Can and Mamie

- Which version is current, and what did the FTE-based revision use as the FTE source and as the sector assignment?
- How was "not in workforce" defined, and what denominator did the revision use for it?
- Can we have the sector-by-sector counts behind the two chosen sectors?
- Were the census tract maps reviewed for small-number disclosure?

## Reconciliation run (io_death_rates_v4.R, 2026-09-28, residents 16+, NIOCCS coding, ACS 5-year 2020-2024 denominators)

| Group | Ours 2020-2021 | Can's sheet | Our rate per 100,000 worker-years |
|---|---|---|---|
| Construction (23) | 65 | 72 | 44.8 |
| Manufacturing (31-33) | 60 | 55 | 28.1 |
| Not in workforce | 66 | 84 | none (no ACS denominator) |
| All workers | 440 | | 21.5 |

Counts agree to within about 10 percent for the two sectors. The not-in-workforce gap (66 vs 84) is unexplained; candidates are all ages vs 16+, certificate Census industry code vs NIOCCS, and the 23 not-coded 2020-2021 suicides. The sheet's "72 per 100,000" for construction was a count, not a rate.
