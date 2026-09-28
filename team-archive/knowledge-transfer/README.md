# Knowledge transfer: Chris Austin

Material left by Chris Austin (former Occupational Health Epidemiologist, NE DHHS Public Health, Epidemiology; supervisor Derry Stover), plus two slide decks from the same uploads. Collected from the repo root on 2026-09-28.

## Inventory

| File | What it is |
|---|---|
| `Chris Austin Knowledge Transfer Questionnaire.pdf` | State HRSS knowledge transfer form, 5 pages, filled in as a fillable PDF. Undated. |
| `Chris-Austin-Knowledge-Transfer-Questionnaire.txt` | Full text of the form with every typed answer, verbatim (read from the PDF form fields, not OCR). |
| `APHA2021_poster_presentation_CMA.pptx` | Chris Austin and Derry Stover, APHA October 2021 poster: "Distribution of COVID-19 Cases by Industry Sector, Nebraska, 2020". |
| `APHA2021_poster_presentation_CMA.txt` | Slide text, speaker notes, and the numbers behind the two embedded charts. |
| `DSTT Nebraska.pptx` | CSTE Data Science Team Training (DSTT) presentation, 14 Dec 2022, "Using NLP to Identify Reportability of Cancer Reports" (Lifeng Li, Bhavana Srinivas, Qianru Wu, Remy Poudel, Yi Du). Chris is not listed; it is the origin of the NLP method reused in `../syndromic-nlp/`. |
| `DSTT Nebraska.txt` | Slide text. Most slides also contain images that are not captured. |

## What the questionnaire says (summary)

The answers are almost entirely about tools. Questions 7 to 14 are mostly blank: the only contact listed is Derry Stover; no ongoing projects, deadlines, outside contacts, vendor logins or access codes are given. No secrets were in the form.

**Denominators, FTE and ACS.** Chris calls his "Workforce Estimates (FTE) Calculation Tool" a core resource (Q1 item 5, Q3 item 2, Q5, Q15). As described:
- Built in R from ACS PUMS (pulled with tidycensus), using tidyverse and `srvyr` for survey weights.
- Extracts employment status, industry codes and usual hours worked per week.
- Produces employment estimates by industry, then an FTE version by "standardizing work hours to a 40-hour workweek and multiplying person weights accordingly" (that is, person weight times hours/40).
- Reports MOE, relative MOE and CV for each estimate.
- Q15: a successor needs to understand the survey weights and "how to interpret employment estimates both in their raw form and when adjusted for FTE". He treats the raw employed count and the FTE count as two outputs of the same tool, which fits the project's option of using ACS employed workers with FTE as a sensitivity check.
- The form does not say which ACS years, 1-year vs. 5-year, age range, or whether class of worker or military were excluded. Those details would be in the scripts (see `team-archive/denominators/`).
- The APHA 2021 poster used ACS PUMS as the sector denominator for COVID-19 case rates "per 100,000 employed workers" (employed, not FTE).

**NIOCCS.** Q1 item 2, Q3 item 1 and Q5 describe the NIOCCS Auto-Coder he built in R: automated calls to the NIOCCS web API turning free-text I/O into NAICS, SOC and Census codes, used on large datasets "such as COVID-19 surveillance data". He stresses structuring the API queries and handling responses correctly. References he used: census.gov/naics, the NIOCCS support page, and the NIOCCS autocoder site (Q2). The code and workflow are in `../io-coding/nioccs/`. No NIOCCS credentials are mentioned (the scripts use none).

**Death certificates, suicide, NEVDRS, overdose.** Not mentioned anywhere in the questionnaire. Nothing in it explains the NEVDRS sector fact sheet or an FTE-based revision with Can. The death certificate suicide coding script (`../io-coding/nioccs/nioccs_suicide.R`) sits in Jean Kwizerimana's K: folder, not Chris's.

**Other duties described.** BLS API retrieval of work fatality data (CFOI/SOII); NLP and machine learning (logistic regression performed best) to flag work-related injuries in syndromic surveillance data, which he says few others know how to do; RMarkdown report templates; a syndromic surveillance occupational health query; an occupational health tribal guidance document; eCR work coordinated with Kaniska FNU (DHHS eCR epidemiologist). Q15 lists the data sources he managed: syndromic surveillance, ACS PUMS, I/O coding, BLS, and workers' compensation.

**Where things live.**
- Team files and his own files: `K:\Occupational Health Grant\Chris Austin` (Q4).
- Paper files: file cabinet in cubicle 125 (Q4).
- Confidential material: "will stay securely on internal drives and folders controlled by NDHHS" (Q12).
- Related locations seen in the scripts, not in the form: `K:\Occupational Health Grant\Jean Kwizerimana\Deacertificate\` (death certificate coding and suicide outputs), `K:\Occupational Health Grant\Jean Kwizerimana\FTE\` (FTE files such as `FTE_2023_PUMS_5y_soc2.csv`), and `K:\SYS NLP\Data\` (syndromic NLP).

## APHA 2021 poster: relevant method points

120,000 working-age COVID-19 cases in 2020; 56,878 (47%) had codable employer data; 63,474 (53%) were excluded for insufficient employer data, retired, unemployed or military. Employment text from case interviews was coded with NIOCCS to NAICS sectors; ACS PUMS gave sector denominators and the total workforce; rates per 100,000 employed workers (manufacturing highest at about 9,807). In the first chart the positive series is each sector's share of the workforce and the negative series is its share of cases (the series are unnamed in the file; this reading matches the speaker notes).
