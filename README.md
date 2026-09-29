# NE-IndOcc-Deaths

Nebraska suicide and drug overdose deaths by industry and occupation, from Nebraska death certificates (NCHS annual files dth20 to dth24 on K:), coded with CDC NIOCCS, with ACS PUMS 2020-2024 5-year denominators (persons and FTE). Results are compared with the NEVDRS sector sheet and with Chris and Jean's earlier suicide-by-industry table.

Current release scripts: scripts/io_death_rates_v8.R (residents 16 to 64) and scripts/io_death_rates_v9.R (v8 with ages 16 and over). Real-run results: docs/v5-changes.md and docs/three-way-comparison.md. Scripts are never edited after they are sent; fixes go in a new version.

Start with docs/project-brief.md for context, the people involved, what the collected materials show, and the questions for the NEVDRS team.

## Layout

| Path | Contents |
|---|---|
| docs/project-brief.md | Project context, open questions, meeting prep |
| docs/web-captures/ | Verbatim saves of NE DHHS, CDC, WISQARS, Census and HRSA web pages, the DHHS TRIX course list and the Lancaster coroner MOU (one file per page, duplicates removed, source URL and capture date at top) |
| docs/meetings/ | Meeting transcripts |
| docs/nevdrs-sectors-factsheet-review.md | Review of Can's unpublished suicide-by-sector fact sheet (population denominators, unstated sector method, tract maps) |
| docs/analysis-plan.md | The original plan (2026-09-28); see its status note for what v8 changed |
| docs/provenance-comparison.md | Provenance of all ten suicide and overdose analyses in view, side-by-side table, what is most common, and the shared pipeline for the OHIs sub-indicator and the NEVDRS check |
| docs/acs-denominator-spec.md | Early denominator spec (ACS published tables, used by v3 to v7); v8 and v9 use PUMS persons and FTE instead |
| scripts/io_death_rates_v8.R | Release script: NCHS annual files dth20 to dth24, residents 16 to 64, NIOCCS, PUMS 2020-2024 persons and FTE, suicide and overdose, by sex and age band |
| scripts/io_death_rates_v9.R | v8 with ages 16 and over (like-for-like check against the earlier occupational health table) |
| scripts/io_death_rates_v7.R | Earlier release: suicide only, Guardian exports, ACS C24030 and C24010 denominators. Needs scripts/acs_group_map.csv next to it |
| scripts/io_death_rates_v3.R to v6.R | Earlier steps (Guardian exports, ACS table denominators, suicide and overdose). Change notes in docs/v5-changes.md |
| scripts/io_death_rates.R, scripts/io_death_rates_extras_v3.R | Pre-versioning copy of v3 (differs only in the cache file name) and its optional add-ons |
| scripts/acs_group_map.csv | ACS C24030 and C24010 category names mapped to NAICS sectors and SOC major groups (used by v3 to v7) |
| scripts/drafts/, scripts/old/ | The simple sketch that became v5, and the first long version |
| docs/script-audit.md | Audit of the first long script (historical; see its status note) |
| docs/correctness-audit-v4.md, docs/provenance-audit-v4.md, docs/simplicity-review-v4.md, docs/v5-verification.md | Reviews of v4 and v5 (historical) |
| docs/v5-changes.md | v5 change notes plus the real-run log for v6, v7, v8 and v9 |
| docs/three-way-comparison.md | NEVDRS sheet vs the earlier occupational health table vs v8 and v9 |
| docs/people-nevdrs-sudors.md | Who runs NEVDRS and SUDORS, from public pages |
| docs/repo-audit-2026-09-29.md | Repository consistency audit |
| tests/synthetic_run.R | Offline test of scripts/io_death_rates_v6.R on fake data (no test exists for v7, v8 or v9); tests/synthetic_run_v4.R tests v4 |
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
