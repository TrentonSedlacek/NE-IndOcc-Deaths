# Nebraska death certificate data: what the team's repos already hold

Written 2026-09-24 after cloning the occupational health team's mortality repos into this session. Purpose: know exactly what death certificate (DC) machinery exists before building the DC side of the industry and occupation (I/O) comparison against NEVDRS and SUDORS.

Repos cloned (read only, sibling folders under /home/user/):

| Repo | Why it matters here |
|---|---|
| DC-HDD-Surveillance | The death certificate repo. Documents both DC pipelines, the I/O fields, the case-finding patterns, and holds the working SAS template plus legacy programs. |
| OHIs | Yearly OHI death programs (OHI 10 pneumoconiosis), and the new sub-indicators scaffold with denominators by NAICS sector (QCEW), FTE, and the suppression rules. |
| NE-Heat-Excess-Mortality | Reads the NCHS annual DC files in R (read_fwf) and has a hand copy of the DC-HDD scripts. No I/O work. Useful only as a second reader of the same files. |
| Mother-Repo | Index of all children; lineage.md and pitfalls.md explain how the DC files flow and what bites. |

Not cloned but relevant (listed in Mother-Repo): BRFSS-IndOcc holds the denominator files dim_industry.csv, fact_oews.csv, fact_qcew.csv, fact_qwi.csv; CSTE-2027 uses them; ABLES has the NIOCCS coding round trip. None runs in the cloud; everything reads K:.

## The two DC pipelines (from DC-HDD-Surveillance docs/dc-data-sources.md)

1. Guardian (EDRS) yearly exports, 2018 to present, under K:\Occupational Health Grant\data\dc\{YYYY}\DeathCertificates{YY}.xlsx. Saved as CSV, then dc_build_datasets.sas imports them to yearly SAS datasets dc18 to dc26. 198 variables. The xlsx cannot be read directly by SAS (floating point overflow), hence the CSV step.
2. NCHS annual occurrence files, 1999 to present, fixed width LRECL 1951, under data\dc\Annual\{YYYY}DeathNEOccurrence.txt, read by the %ReadDTHfile macro into dth{YY}.sas7bdat. Most recent year is provisional. No written cause text.

The two pipelines read different exports of the same source and can disagree (Mother-Repo lineage.md).

## The I/O and manner fields

| Concept | Guardian export | NCHS annual file |
|---|---|---|
| Usual occupation literal | OccupationLIt | OCCUPL ($40) |
| Usual occupation code | OccupationCode | OCCUP ($3) |
| Usual industry literal | IndustryLit | INDUSTL ($40) |
| Usual industry code | IndustryCode | INDUST ($3) |
| Manner of death | MannerDeath (N/A/S/H/P/C) | MANNEROD |
| Injury at work | InjuryAtWork (Y/N/U/X) | INJ_WORK |
| Underlying cause | AcmeUnderlyingCode | ACUND_CAUSE |
| Multiple cause, record axis | D2Acme1-20 | RAXSCD01-20 |
| Multiple cause, entity axis | D2SmicarAxis1-20 | AXISCD01-20 |
| Age | NchsAge / NchsAgeUnit | AGEUNITS / AGETYPE |
| Residence state | ResidingStateNchs | RES_ST |

Facts about the codes that matter for rates:

- The codes are described as "NIOSH codes" in the DC-HDD docs and as Census Bureau I/O codes in the NVDRS Coding Manual (page 45). They are 3-character codes on the file (the 2008 file used 4). The legacy QA script check io code titles.sas appends "0" to the industry code, which suggests the file stores Census industry codes with the trailing digit dropped. Verify against the Death Layout 2005+ PDF on K: before mapping to NAICS sectors.
- About 18 percent of in-year (2026 YTD) records had no I/O code yet; coding lags filing. Finalized years should be near complete. Check missingness by year first (the legacy script already does this).
- NVDRS and SUDORS abstractors copy these same DC fields into the CDC system (NVDRS Coding Manual 3.2.4). So if NEVDRS staff used the coded fields, the death certificate numerator and the NEVDRS numerator should agree case for case, apart from manner reclassification after investigation. That is the comparison to make.
- The DC also carries occupation and industry literals, which is what Massachusetts coded with NIOCCS to NAICS and SOC. The literal route is available here too if the coded route proves too coarse.

## Case-finding patterns already in use

From DC-HDD-Surveillance (template dc_condition_surveillance.sas and legacy code):

- 41-field array scan over underlying plus both multiple-cause axes, prefix match on ICD-10 codes.
- Free-text prxmatch on ImmedCauseDeath, Consq1-3, OtherSignificantConditions (Guardian only). This is the same trick SUDORS uses to catch overdoses whose ICD coding is incomplete (SUDORS case definition: X40-44, Y10-14, or literal text such as overdose, toxicity, intoxication).
- Underlying-cause range for suicide: ACUND_CAUSE between X60 and X84 (legacy combine data.sas). The template does not do ranges; codes must be listed one by one.
- De-duplicate by DeathCertificateId and EventYear; filter to NE residents with ResidingStateNchs = NE; age from NchsAge and NchsAgeUnit.
- Yearly Guardian exports overlap (53 to 66 late-registered prior-year deaths in the 2021 to 2024 files); the template filters to requested years and keeps one row per certificate.

Case definitions to line up with the CDC systems:

| Outcome | NEVDRS/SUDORS definition | DC equivalent |
|---|---|---|
| Suicide | NVDRS manner of death assigned by abstractor; dashboard cites ICD-10 X60-X84, Y87.0, U03 | ACUND_CAUSE X60-X84 (plus Y87.0, U03), or MannerDeath = S |
| Unintentional or undetermined overdose | SUDORS: X40-44 or Y10-14, or literal overdose text, drug per ISW7 definition | Underlying X40-X44, Y10-Y14; opioid involvement via T40.0-T40.4, T40.6 in the multiple-cause fields (the Massachusetts codes) |
| Opioid-related, all intents (MA definition) | not a SUDORS concept | X40-49, X60-69, X85-90, Y35.2, Y10-19 with T40.0-.4, .6 |

## Denominators already on hand (OHIs sub-indicators/)

- fact_qcew.csv: QCEW annual average employment by NAICS sector, all ownerships, Nebraska, 2014 to 2024 (jobs, not persons; farms mostly excluded). Copied from BRFSS-IndOcc.
- strata.csv: the NAICS 2-digit sector list used as the common industry level across SOII, CFOI, QCEW, WC, ABLES and DC industry codes, plus an "Industry not coded / unknown" stratum.
- denominators.csv: names the options. EMP (BLS Geographic Profile / CPS, by industry via GP Table 20 or QCEW), FTE (NIOSH ELF, CPS hours; no industry split on the drive), FTE_HOURS (BLS SOII, published by industry), POP15 (Census, by age and sex, not by industry).
- Age adjustment by industry is not supported because no public series gives age-by-industry denominators; the scaffold reports crude rates by industry and age-adjusted rates only for totals and sex. ACS PUMS could supply age-by-industry at a cost.
- The FTE question: the OHIs scaffold notes that FTE by industry is not on the drive. Massachusetts used ACS employed workers. If the deliverable is "rates by FTE" the denominator has to come from BLS/ELF hours data or be built from ACS PUMS or CPS microdata.

## Rules that apply before any number leaves the team

- DHHS floor: rates blank when the count is 1 to 5 (floor of 6); CSTE rule: no rate on fewer than 5; counts under 20 flagged unstable. The NEVDRS dashboard suppresses 1 to 5 with complementary suppression. The DHHS floor is "not recorded anywhere in the repos; ask."
- SAS on DC data: use SUBSTRN, never SUBSTR, or the log dumps full records with PII (Mother-Repo pitfalls). Never commit logs.
- All of this runs on K: only. Nothing here can be executed in this cloud session; scripts get written here and run on a DHHS machine.
- 2025 DC data is provisional.

## What this means for the two projects

The occupational health team can produce, from the death certificate alone, the same three-panel figure NEVDRS made and the full all-sector table it should have come with:

1. Numerator: suicides (X60-X84, resident, age 16+) and overdoses (SUDORS definition, plus an opioid-specific T40 subset), 2020 to 2024 from the Guardian yearly datasets, pooled, by DC usual industry code mapped to NAICS sector and by usual occupation code mapped to SOC major group. Report non-worker and not-coded groups as separate rows, never folded into a sector.
2. Denominator: QCEW sector employment (already in fact_qcew.csv) for a first pass; ACS employed workers by industry and occupation for the Massachusetts-comparable version; FTE only if the hours data can be sourced.
3. Output: crude rate per 100,000 workers with 95 percent CIs, rate ratio against all workers, suppression applied, one row per sector, with the numerator counts shown so the NEVDRS figure can be reconciled cell by cell.

Then the meeting with Can and Mamie becomes a reconciliation of two tables built from the same certificates, instead of an argument about one number.

Open items to settle before writing the SAS: the industry code list on the DC file (Census 2012 or 2018 codes, 3 or 4 digits) and its crosswalk to NAICS sectors; whether to use MannerDeath or the ICD range for suicide; and which denominator Derry wants to stand behind.
