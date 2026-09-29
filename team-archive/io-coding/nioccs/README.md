# NIOCCS industry and occupation autocoding scripts

Scripts and documentation for sending free-text industry and occupation (I/O) entries to NIOSH's NIOCCS autocoder and turning the results into NAICS, SOC and Census codes. Collected from the former `NIOCCS Autocoder/` folder and the repo root on 2026-09-28.

Authorship: the workflow document and `CDC NIOCCS web service i_o GET.R` are Chris Austin's (the questionnaire in `../../knowledge-transfer/` describes this tool as his). `nioccs.R`, `nioccs_suicide.R` and `occ_code.R` read and write under `K:\Occupational Health Grant\Jean Kwizerimana\...`, so they appear to be Jean Kwizerimana's adaptations of Chris's function to death certificate data. None of the files carry an author or date.

## Inventory

| File | What it is |
|---|---|
| `NIOCCS Autocoder Workflow for Industry and Occupation Coding.docx` | Chris's written workflow: data prep, the `NIOCCS_WebService()` GET function, `pmap_dfr` over rows, `unnest_wider`, output. Example uses `covid_deaths$customID`, `IndustryLit`, `OccupationLIt`. |
| `CDC NIOCCS web service i_o GET.R` | Chris's original function applied to 2021 COVID case investigation I/O (`covid_2021_io`, joined on `inv_local_id`, written to `nioccs_coded_covid_2021_io.csv`). The `id`, `industry`, `occupation` vectors are built outside this file. |
| `nioccs.R` | Same function applied to a bladder cancer extract for Derry (`histo`, lines 5 to 53), then post-processing of an already coded ATV (all-terrain vehicle) death certificate file `nioccs_atv.csv`: SOC repair, SOC major group join, age 19+ frequency table, Poisson/quasi-Poisson trend by death year (lines 56 to 135). |
| `nioccs_suicide.R` | NIOCCS coding of Nebraska death certificate suicides 2014 onward, then SOC/NAICS grouping and suicides per 1,000 FTE by occupation group. Details below. |
| `occ_code.R` | ATV deaths: joins the death certificate's own Census occupation code (`OccupationCode`, with a "0" appended to reach 4 digits) to a 2002 Census occupation code list, and computes age from DOB/DOD on the NIOCCS-coded ATV file. Does not call NIOCCS. |

Duplicates resolved:
- `NIOCCS Autocoder Workflow for Industry and Occupation Coding.docx` existed at the repo root and in `NIOCCS Autocoder/`. Identical (md5 `b4352c600e4a3d67c4558fb5a08de318`); one copy kept here.
- `app.R` at the root was byte-identical to `code_without_mapping.R` (md5 `951377ede0b941762ac39e86440bd815`); `app.R` was removed.
- `code_with_mapping.R` and `code_without_mapping.R` were in this assignment but are not NIOCCS code: they are Shiny apps for the Census QWI API. They were moved to `../qwi-shiny-app/`. They contained a hard-coded Census API key, now replaced with `REDACTED` (see that folder's README).

## How NIOCCS is used here

**Endpoint and call.** Every script uses the same function (`CDC NIOCCS web service i_o GET.R` lines 6 to 21; `nioccs.R` lines 18 to 33; `nioccs_suicide.R` lines 20 to 35):

```r
httr::GET(url = "https://wwwn.cdc.gov/nioccs/IOCode?",
          query = list(i = industry, o = occupation, c = 2))
```

- `i`: industry free text; `o`: occupation free text, one record per request.
- `c = 2`: the workflow docx (section 4) says "2 represents the Census I/O codes in the NIOCCS system". This is the team's reading; confirm against current NIOCCS web service documentation (the code set version it selects, for example Census 2010 or 2012 based schemes, is not stated anywhere in these files).
- No API key, token or login is used for NIOCCS. The call is an anonymous public GET. (`library(rsconnect)` is loaded but never used.)

**Single record, not batch.** `pmap_dfr(list(id, industry, occupation), NIOCCS_WebService)` sends one GET per row, sequentially (`GET.R` line 24, `nioccs.R` line 36, `nioccs_suicide.R` line 38). There is no NIOCCS batch upload, no rate limiting, no retry, and no check of `status_code`; one failed or non-JSON response stops the whole run. The questionnaire's "batching" remark refers to the BLS API tool, not NIOCCS.

**Parsing and output fields.** The JSON response is parsed with `fromJSON`, the caller's `id` is attached, then only the `Industry` and `Occupation` list elements are kept and widened with `unnest_wider(c(Industry, Occupation))` (`GET.R` lines 28 to 30). Downstream code references these returned columns: `NAICSCode`, `CensusIndustryTitle`, `SOCCode`, `SOCTitle`, `CensusOccupationTitle` (`nioccs.R` lines 51, 59; `nioccs_suicide.R` lines 64, 71, 73). Other fields NIOCCS returns (for example Census codes and any confidence or score fields) are kept in the wide output but never used. The coded frame is left-joined back to the source data on the row ID and written to CSV.

**Known handling issues in the coded files:**
- `nioccs.R` lines 62 to 77: `SOCCode` values such as `Nov-13`, `Nov-22` show the CSV was opened and saved in Excel, which turned codes like `11-9013` into dates. The script maps them back by hand; the mapping is a guess (for example `Nov-22` is set to `11-2022`, but `11-9022` would display the same way). Always read NIOCCS output with SOC and NAICS as text.
- `nioccs.R` line 77 and `nioccs_suicide.R` line 68 recode SOC `11-9013` (Farmers, Ranchers, and Other Agricultural Managers) to `45-0000`, moving farm managers into the Farming, Fishing, and Forestry major group.
- Records with SOC major group `00` are dropped before analysis (`nioccs.R` line 89, `nioccs_suicide.R` line 83). What NIOCCS puts in `00` (not in labor force, uncodable, or similar) is not documented here and should be checked.

## What `nioccs_suicide.R` does, end to end

1. **Input** (line 11): `K:\Occupational Health Grant\Jean Kwizerimana\Deacertificate\suicide data\suicides.sas7bdat`, a SAS extract of Nebraska death certificate suicides. How the suicide case definition was applied (ICD-10 underlying cause or manner of death) is not in this script; it happened upstream in SAS (compare `team-archive/analyses/suicide/suicide.sas`).
2. **Filter** (line 12): death year `DOD_YR >= 2014`. No residency or age filter at this step.
3. **I/O fields** (lines 16, 18): `INDUSTL` (usual industry literal text) and `OCCUPL` (usual occupation literal text) from the death certificate. The death certificate's own coded Census I/O fields are not used; the text is recoded by NIOCCS.
4. **Coding** (lines 20 to 44): one NIOCCS GET per decedent as described above, joined back on a sequential row `ID` (line 49).
5. **Output 1** (line 52): writes `...\Deacertificate\suicide_coded_datac.csv`, then immediately reads a different file, `...\suicide data\suicide_coded_data.csv` (line 54), so the analysis runs on a previously saved coded file, not on the fresh run.
6. **Grouping**: SOC 2-digit major group from `SOCCode` (line 71); NAICS 2-digit sector from `NAICSCode` with 31-33, 44-45, 48-49 combined (lines 73 to 82); SOC major group labels (`OccCategory`) from `socc.csv` (lines 56, 89).
7. **Working-age filter** (line 83): `AGEUNITS >= 16` and `SOC != "00"`. In the NCHS annual file layout `AGEUNITS` holds the age number and `AGETYPE` its unit (`scripts/io_death_rates_v8.R` reads it that way, AGETYPE 1 = years), so this filter keeps ages 16 and over; it does not check `AGETYPE`. `scripts/io_death_rates_v9.R` reproduces the saved 2020-2021 sector counts exactly at 16 and over.
8. **Counts**: occupation group counts overall and by year (lines 92 to 109); industry sector counts by year (lines 112 to 123, written to `...\Deacertificate\suicide_ind_count_yr.csv`).
9. **Denominator and rate** (lines 57, 125 to 135): FTE by SOC group from `K:\...\Jean Kwizerimana\FTE\FTE_2023_PUMS_5y_soc2.csv` (ACS PUMS 2023 5-year, FTE adjusted; column `n`). Rate = `Count / n * 1000`, labelled "Suicides per 1000 FTE Employees by Occupation Sector (2014-2023)". Written to `...\suicide data\suicide_counts_occ.csv`. Only an occupation (SOC) rate is computed; no industry rate.

**The script does not run as saved.** Objects are used before they exist or never exist: `atv` (line 63), `NAICS` is created on `data_io_coded` (line 73) but `case_when` runs on `data_io_code` (line 77), `data_io_ind` and `Ind_sector` (lines 112 to 122) and `occ_fte_df` (line 125) are never created, and the second plot (line 154) uses `Ind_sector` on the occupation table. `fte_2023_ind` (line 58), read from `suicide_counts_industry (2014-2023).csv`, is never used. The saved CSVs on K: were therefore produced by code that is not fully in this file.

**Method concerns for the current project:**
- The numerator is 10 years of deaths (2014 to 2023) divided by one year's FTE, so the "per 1,000 FTE" figure is a cumulative 10-year ratio, not an annual rate. Dividing by 10 (or summing annual denominators) would be needed for an annual rate.
- The denominator is FTE (hours adjusted), not employed workers. The Massachusetts model and the likely project choice use ACS employed workers per 100,000.
- Relevance to NEVDRS: this is the occupational health team's own death certificate pipeline (text recoded with NIOCCS, NAICS sectors with 31-33 grouped, FTE denominator). The NEVDRS sector sheet's later "FTE-based" revision attributed to Can and Chris could plausibly have used this pipeline or its FTE files, but nothing here names NEVDRS, construction or manufacturing specifically. Ask Can whether their sector assignment came from this script's outputs.
