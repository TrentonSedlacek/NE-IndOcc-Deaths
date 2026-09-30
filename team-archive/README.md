# Team archive: occupational health grant material relevant to denominators, FTE, and I/O coding

Uploaded 2026-09-28 by Trenton from the Occupational Health Grant team's files (much of it Chris Austin's and Jean Kwizerimana's work). Organized by four review passes on the same day; each folder has its own README with an inventory and a relevance note. Nothing here runs in the cloud: scripts read K: paths and call external APIs.

| Folder | What it holds | Relevance to the industry and occupation deaths project |
|---|---|---|
| denominators/ | ACS PUMS FTE scripts and outputs (industry NAICS 2 and 3 digit, occupation SOC 2 digit, 2013 to 2023), NIOSH ELF/CPS FTE queries (2000 to 2013, 2017 to 2019), QWI/QCEW/OEWS employment workbook, the Workforce Estimates Calculation Tool workflow | Central. This is the team's existing FTE denominator machinery. |
| io-coding/nioccs/ | NIOCCS web service caller, workflow doc, and nioccs_suicide.R (suicides coded to NAICS and SOC, rate per 1,000 FTE) | Central. This is how death certificate industry and occupation text gets coded. |
| io-coding/qwi-shiny-app/ | Two Shiny apps over Census QWI | Peripheral (employment counts by NAICS, not FTE). |
| analyses/ | 27 SAS and R scripts: suicide, ATV, cancer registry, poison control, modeling | suicide_agg.R is the direct precedent (suicide by NAICS sector and SOC group per FTE). The rest are unrelated. |
| knowledge-transfer/ | Chris Austin's knowledge transfer questionnaire (verbatim text), APHA 2021 poster, DSTT deck | Explains the FTE tool and where Chris's files live on K:. |
| bls-api-data/ | BLS API pulls: CFOI Nebraska fatality counts 2011 to 2020, SOII nonfatal rates 2014 to 2021 | No FTE denominators by industry; counts and BLS-computed rates only. |
| syndromic-nlp/ | ED syndromic surveillance NLP classifier for work-related injuries | Unrelated. |
| injury-report-supplemental/ | Hospital discharge work-related injury counts 2016 to 2020 | Unrelated (no industry field). |
| cste-methods-workgroup/ | Interrupted time series teaching material | Unrelated. |
| hpai/ | 2024 H5N1 response material | Unrelated, parked. |

## Security note

The upload contained plaintext credentials. All have been replaced with REDACTED placeholders in the working tree, but they remain in git history on the public repo until history is rewritten:

- SQL Server usernames and passwords for the ESSENCE database and the ER surveillance production database (bls-api-data/BLS_report.Rmd and syndromic-nlp/creating_SyS_dataset_NLP.R). Internal server hostnames are still present in those files.
- Three BLS API registration keys (bls-api-data/work_fatality_BLS_api.R).
- One Census API key (five ACS scripts under denominators/ and both QWI apps).

Treat every one of these as compromised: rotate the passwords, regenerate the keys, make the repository private, and purge history.

## Duplicates removed

Exact copies (same md5) were deleted, keeping one: the NIOCCS workflow docx, app.R (same as code_without_mapping.R), occupation_fte.R, the three ACS Subsector FTE Counts files, the loose FTE 2014 and 2015 SOC files, one fte_ne_naics2_5y_2022.csv. Near-duplicate pairs (bladder/bladda, pesticides, poison_control, ATV/atv_coded) are all kept and the differences are described in analyses/README.md. Office lock files and Thumbs.db were deleted.
