# NE-IndOcc-Deaths

Nebraska opioid-related (possibly wider drug overdose) deaths and suicides, by industry and occupation, using SUDORS and NVDRS/NEVDRS data, with Nebraska death certificate data to be added later for comparison.

Start with docs/project-brief.md for context, the people involved, what the collected materials show, and the questions for the NEVDRS team.

## Layout

| Path | Contents |
|---|---|
| docs/project-brief.md | Project context, open questions, meeting prep |
| docs/web-captures/ | Verbatim saves of NE DHHS, CDC, WISQARS, and Census web pages (one file per page, duplicates removed, source URL and capture date at top) |
| docs/meetings/ | Meeting transcripts |
| docs/nevdrs-sectors-factsheet-review.md | Review of Can's unpublished suicide-by-sector fact sheet (population denominators, unstated sector method, tract maps) |
| docs/analysis-plan.md | The plan: inputs, ten steps, decisions needed, quality checks, effort |
| docs/provenance-comparison.md | Provenance of all ten suicide and overdose analyses in view, side-by-side table, what is most common, and the shared pipeline for the OHIs sub-indicator and the NEVDRS check |
| docs/acs-denominator-spec.md | Denominator decision (likely ACS employed workers): tables, years, rate arithmetic, numerator rules, FTE option |
| scripts/io_death_rates.R | The analysis, one R script: deaths from Guardian exports, NIOCCS coding, ACS denominators, Poisson CIs, suppression, QA checks. Audited against the plan and SAS sources; passes a 40-check synthetic test (tests/synthetic_run.R); ACS labels and live NIOCCS still unverified, see docs/script-audit.md |
| docs/script-audit.md | Audit findings on the R script: what was wrong, what changed, what is unverified, decisions still needed |
| tests/synthetic_run.R | Offline test: fake Guardian rows with planted answers, fake NIOCCS cache and ACS tables; runs every section with no network |
| scripts/fetch_acs_denominators.py | Pulls Nebraska ACS C24030 and C24010 into data/denominators/ (needs api.census.gov access) |
| docs/death-cert-data-notes.md | What the team's death certificate repos (DC-HDD-Surveillance, OHIs, NE-Heat-Excess-Mortality, Mother-Repo) hold: DC pipelines, I/O fields, case-finding patterns, denominators, suppression rules, and the plan for the DC side of the comparison |
| source-docs/INVENTORY.md | Table of every PDF with description and years, every industry/occupation mention with page numbers, dashboard screenshot descriptions, and the Massachusetts report methodology |
| source-docs/ne-dhhs/nevdrs/ | NEVDRS overview, infographic, coding manual, partner fact sheets |
| source-docs/ne-dhhs/sudors/ | SUDORS fact sheet and coding manual |
| source-docs/ne-dhhs/factsheets/ | NE fact sheets: suicide/, homicide/, sudors/, other/ |
| source-docs/ne-dhhs/unpublished/ | Unpublished NEVDRS material shared internally (sector fact sheet) |
| source-docs/ne-dhhs/newsletters/ | Suicide Prevention Newsletter issues 1 to 5 |
| source-docs/ne-dhhs/dashboard-screenshots/ | Browser prints of the Nebraska Suicide Deaths Dashboard (Power BI) |
| source-docs/external/massachusetts/ | MA DPH report on opioid-related overdose deaths by industry and occupation, 2018-2020 (methodology model) |
| team-archive/ | The occupational health team's own denominator, FTE, NIOCCS, and analysis files, organized with a README per folder; start at team-archive/README.md |
| extracted-text/ | Plain-text extraction of every PDF, mirrored paths, page markers, for grepping |

## Key links

- NE DHHS NEVDRS/SUDORS page: https://dhhs.ne.gov/Pages/Violent-Death-Reporting.aspx
- Nebraska Suicide Deaths Dashboard (Power BI): linked from the page above
- CDC SUDORS dashboard: https://www.cdc.gov/overdose-prevention/data-research/facts-stats/sudors-dashboard-fatal-overdose-data.html
- CDC WISQARS NVDRS module: https://wisqars.cdc.gov/nvdrs/
- NVDRS Restricted Access Database: https://www.cdc.gov/nvdrs/about/nvdrs-data-access.html
