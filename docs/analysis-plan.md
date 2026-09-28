# Analysis plan: Nebraska suicide and drug overdose death rates by industry and occupation

Version 1, 2026-09-28. Method follows the Massachusetts DPH report (2022) and the CDC NVDRS industry paper (Peterson 2020). Everything below runs on a DHHS machine with K: access; nothing runs in the cloud.

## 1. What we are producing

Two tables, same layout, one per outcome:

- Suicide deaths by industry sector and by occupation group, Nebraska residents aged 16 and over, 2020 to 2024 pooled.
- Drug overdose deaths (SUDORS definition), same strata, same years, with an opioid-involved subset.

Each row: sector or group, deaths, workers, rate per 100,000 workers, 95 percent confidence interval, rate ratio versus all workers, and a flag for suppressed or unstable. Plus three rows that are never dropped: not in workforce, industry not coded, military. Plus one column each for male and female where the counts allow.

Secondary output: the same suicide table for 2020 to 2021 only, so it can be laid next to Can's 84 / 72 / 55.

## 2. Inputs

| Input | Where | Fields used |
|---|---|---|
| Death certificates, Guardian yearly exports 2020 to 2024 | K:\Occupational Health Grant\data\dc\{YYYY}\DeathCertificates{YY}.xlsx, saved as CSV (the xlsx cannot be read by SAS) | DeathCertificateId, EventYear, ResidingStateNchs, NchsAge, NchsAgeUnit, Sex, MannerDeath, AcmeUnderlyingCode, D2Acme1-20, D2SmicarAxis1-20, ImmedCauseDeath, Consq1-3, OtherSignificantConditions, IndustryLit, OccupationLIt, IndustryCode, OccupationCode |
| NIOCCS web service | https://wwwn.cdc.gov/nioccs/IOCode? (GET, i = industry text, o = occupation text, c = 2), per team-archive/io-coding/nioccs/ | returns NAICSCode, SOCCode, Census codes and titles |
| ACS 2020-2024 5-year, Nebraska | Published tables C24030 (sex by industry) and C24010 (sex by occupation), or PUMS if an FTE column is wanted | civilian employed 16+, by sex |
| Reference lists | 2022 Census industry code list with NAICS crosswalk (already on K: under ABLES crosswalks); SOC major group list (team-archive, socc.csv) | for the cross-check in step 5 |

Do not use: QCEW, QWI, OEWS (jobs, not people; no self-employed; no occupation). Do not use the NCHS annual occurrence file as the primary source (residents who died out of state are missing; the Guardian export includes them through the interstate exchange). Do not use the 2020 ACS 1-year (experimental).

## 3. Steps

1. Load and clean deaths. Stack the five Guardian CSVs, keep EventYear 2020 to 2024, one row per DeathCertificateId, ResidingStateNchs = NE. Compute age in years from NchsAge and NchsAgeUnit (unit 1 = years; 2 = months / 12; 3 = weeks / 52; 4 to 6 = 0; 999 = unknown). Keep age 16 and over. Use SUBSTRN, never SUBSTR, and never print records or save logs.

2. Flag outcomes.
   - Suicide: AcmeUnderlyingCode begins X60 to X84, or equals Y870 or U03. Report separately how many have MannerDeath = S but a different code, and the reverse, as a data note.
   - Overdose (SUDORS): underlying X40 to X44 or Y10 to Y14, or any of the five cause-of-death text fields matches overdose, toxicity, intoxication, poisoning by drug terms (reuse the DC-HDD template's text scan). Exclude alcohol-only and carbon monoxide.
   - Opioid subset: any D2Acme or D2SmicarAxis field begins T400, T401, T402, T403, T404, T406.
   - Also compute the Massachusetts all-intent opioid definition (X40-49, X60-69, X85-90, Y35.2, Y10-19 with those T codes) as one extra total, so the Nebraska number can be set beside theirs.

3. Code industry and occupation. Send IndustryLit and OccupationLIt for every flagged death to NIOCCS. Keep the returned NAICS code, SOC code, and the coding confidence field. Roll NAICS to 2-digit sector with 31-33, 44-45, 48-49 combined (20 sectors). Roll SOC to major group (22 groups). Manually review every record NIOCCS returns as insufficient information or low confidence, plus every record in the sectors that end up in the top three, because those drive the headline. Log every manual decision in a CSV.

4. Assign the three non-rate rows before anything is dropped. Not in workforce: literal text or NIOCCS result of homemaker, student, retired, unemployed, never worked, disabled, child. Not coded: blank or uncodable text. Military: NAICS 928110 or a military SOC. These rows get counts and percent of all deaths, no rate.

5. Cross-check the coding. Roll the certificate's own IndustryCode and OccupationCode (3-digit Census codes, trailing digit dropped; append 0 and match the 2022 Census list) to the same sectors and groups. Report percent agreement with NIOCCS by sector. Disagreements above a few percent in any sector get reviewed. This is also the answer to how Can's sheet assigned sectors, whichever route it used.

6. Denominators. From C24030 and C24010: workers by sector and group, total and by sex. Multiply by 5 for worker-years. If an FTE column is wanted, compute FTE from the same 2020-2024 PUMS as sum of PWGTP x WKHP / 40 over ESR 1 or 2 (the team's existing formula) and present it as a second rate column, never as a replacement.

7. Rates. Rate = deaths / (workers x 5) x 100,000. Poisson exact 95 percent CI on the death count. Rate ratio = sector rate / all-worker rate with its CI. Crude only; no age adjustment by sector (no age-by-sector denominators from published tables). Sex-specific rates where the male or female count is 6 or more.

8. Suppression and flags. Blank the rate when deaths are 1 to 5 (DHHS floor). Flag unstable when deaths are under 20. Never show a census tract map.

9. Reconcile with NEVDRS. Run the suicide table for 2020-2021 and compare the construction, manufacturing and not-in-workforce counts with 84, 72, 55. Differences will come from age (Can used all ages), residency, manner versus ICD, and sector assignment. Document each.

10. Write up. One methods page (this plan, updated with what actually happened), the two tables, the reconciliation table, and a limitations list: usual versus current industry, NIOCCS coding error, ACS sampling error in small sectors, 2020 pandemic year, occurrent deaths of non-residents excluded.

## 4. Decisions needed before step 6

| Decision | Recommendation | Who |
|---|---|---|
| Headline denominator: workers or FTE | Workers per 100,000, matching MA and CDC; FTE as a second column if wanted | Derry |
| Headline coding: NIOCCS or certificate code | NIOCCS, with the certificate code as the cross-check | Derry, Trenton |
| Years | 2020 to 2024 pooled; by-year only for statewide totals | Trenton |
| Is sending I/O text to the CDC NIOCCS service allowed under the data use agreement | Confirm; the text carries no identifiers but the question has to be asked once | Derry |

## 5. Quality checks that must pass before numbers leave the team

- Statewide suicide total by year within a few percent of the Vital Statistics 10-year sheet (2020: about 289, 2021: about 305, 2022: about 284 on the NEVDRS dashboard).
- Statewide overdose total by year within a few percent of the SUDORS sheets (2021-2022 combined: 366).
- Sector counts sum to the total plus not-in-workforce plus not-coded plus military, exactly.
- ACS worker total by sector matches the published Nebraska C24030 total.
- Every rate reproduces from the counts and denominators in the table by hand.
- No cell under 6 is printed with a rate; no record-level output exists outside K:.

## 6. Effort

Steps 1, 2, 6, 7, 8 are one SAS or R program and about two days once the CSVs are saved. Step 3 is a few hours of API time plus a day of manual review. Step 5 is half a day. Step 9 and the write-up are a day. Allow a week of working time, plus whatever the decisions in section 4 take.

## 7. What to ask Can and Mamie, in one line each

Which fields and years produced 84 / 72 / 55; how was not in workforce defined; what denominator did the FTE revision use; can we see the all-sector table; may we have the case list to reconcile.
