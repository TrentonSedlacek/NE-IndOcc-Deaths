# QWI Shiny app

Two versions of a Shiny app that pulls Nebraska Quarterly Workforce Indicators (QWI) from `https://api.census.gov/data/timeseries/qwi/{sa|se|rh}` and plots and tables employment, job creation or earnings by year and industry level. Not NIOCCS code; moved here from the NIOCCS assignment on 2026-09-28.

| File | What it is |
|---|---|
| `code_with_mapping.R` | County level (`for=county:*&in=state:31`), loops all four quarters and averages them per year, adds a Leaflet county map (tigris). Line 277 and 280 call `as.characer` (typo), so the map tab errors. |
| `code_without_mapping.R` | Statewide (`for=state:31`), one user-selected quarter, plot and table only. The root `app.R` was a byte-identical copy (md5 `951377ede0b941762ac39e86440bd815`) and was removed. |

Both read label CSVs from `H:/My Documents/R/projects/qwi_shiny_app/` (a personal drive).

**Secret redacted.** Both files had a Census Data API key hard-coded in the request URL (`code_with_mapping.R` lines 109 and 148; `code_without_mapping.R` lines 95 and 132). The value was replaced with `REDACTED`. The key remains in git history and the same key also appears in other scripts in this repo (ACS PUMS scripts under `team-archive/denominators/`), so it should be treated as exposed and replaced. Use `Sys.getenv("CENSUS_API_KEY")` instead.
