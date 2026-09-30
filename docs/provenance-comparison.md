# Provenance of every suicide and drug overdose analysis in view

Written 2026-09-28. Purpose: see, side by side, how each analysis that touches Nebraska suicide or overdose deaths gets from raw records to a number, so that the sub-indicator suicide-by-industry measure and the Can/Mamie check can share one provenance instead of adding a tenth variant.

Status (2026-09-29): section C's recommendation (Guardian numerator, published ACS tables) was followed by scripts v3 to v7. The release scripts v8 and v9 instead follow A5 to A7: NCHS annual files, NIOCCS, ACS PUMS persons and FTE (docs/v5-changes.md, docs/three-way-comparison.md).

"Provenance" here means: numerator source, case definition, residency, years, age range, where industry and occupation (I/O) come from, how they are coded and to what level, denominator source and unit, standardization, uncertainty, suppression, and what the output is.

## A. The analyses

### A1. NEVDRS published suicide fact sheets (2020, 2021, 2022; regional; 2020-2021 topic sheets)
- Numerator: NEVDRS abstraction (death certificate plus coroner and law enforcement reports), manner of death assigned by the abstractor.
- Case definition: suicide manner; dashboard "About" page cites ICD-10 X60-X84, Y87.0, U03.
- Residency: Nebraska residents (dashboard says so; sheets do not state it).
- Years: single year or two pooled years. Age: all ages.
- I/O: none.
- Denominator: total Nebraska population (Census estimates). Unit: per 100,000 population.
- Standardization: crude on the sheets; age-adjusted (2000 US standard, 18 bands) on the dashboard maps.
- Uncertainty: none printed. Suppression: counts 1 to 5 suppressed, complementary suppression.
- Output: one-page sheet, census tract maps.
- Where: source-docs/ne-dhhs/factsheets/suicide/, docs/web-captures/ne-dhhs-about-nebraska-suicide-deaths-dashboard-data.md

### A2. NEVDRS unpublished sector sheet (Can Ceyhan, original)
- Same as A1 except: three groups (not in workforce, construction, manufacturing).
- I/O source and coding: not stated. Most likely the death certificate industry text or code carried into NVDRS (Coding Manual 3.2.4).
- Denominator: total Nebraska population, also for each sector. Unit: per 100,000 population. This is the defect.
- Years: 2020-2021 pooled. Age: all ages (not-in-workforce panel is 46 percent aged 10-19).
- Uncertainty: none. Suppression: 1 to 5 suppressed in charts, but tract maps of 72 and 55 deaths.
- Revision: Derry reports a later FTE-based version with Chris Austin; not seen. If it used the team's files, its provenance becomes A6 or A7 below.
- Where: source-docs/ne-dhhs/unpublished/, docs/nevdrs-sectors-factsheet-review.md

### A3. NEVDRS/SUDORS published overdose fact sheets (2020-2021, 2021-2022, regional)
- Numerator: SUDORS abstraction (death certificate, coroner/ME, toxicology).
- Case definition: SUDORS: unintentional or undetermined intent, ICD-10 X40-X44 or Y10-Y14, or literal cause-of-death text indicating acute overdose; drug per ISW7 definition.
- Residency: CDC dashboard uses occurrent deaths; Nebraska sheets do not state resident vs occurrent.
- Years: two pooled. Age: all ages. I/O: none.
- Denominator: total Nebraska population. Unit: per 100,000 population; regional map age-adjusted to 2000 US standard.
- Uncertainty: none. Suppression: small numbers suppressed; rates on fewer than 20 deaths starred on the CDC dashboard.
- Where: source-docs/ne-dhhs/factsheets/sudors/, docs/web-captures/cdc-sudors-dashboard-fatal-overdose-data.md

### A4. Vital Statistics 2013-2022 suicide fact sheet
- Numerator: death certificates (Office of Vital Records). Case definition: ICD-10 underlying cause (not stated on the sheet; presumably X60-X84, Y87.0, U03). Residents.
- Years: 2013 to 2022 by year. Age: all ages, and by age group. I/O: none.
- Denominator: population; age-adjusted rate per 100,000. Uncertainty and suppression: not stated.
- Where: source-docs/ne-dhhs/factsheets/other/

### A5. Legacy team suicide file (dc-hdd-surveillance, legacy/dc/combine data.sas) and suicide.sas
- Numerator: NCHS annual occurrence files dth05 to dth23 (fixed width, LRECL 1951).
- Case definition: ACUND_CAUSE between X60 and X84, or Y870, or "UO3" (typo with letter O, so U03 never matches). Underlying cause only; MANNEROD not used.
- Residency: RES_ST = NE, applied to an occurrence file, so residents who died out of state are missing.
- Years: 2005 to 2023. Age: none. I/O: INDUST with a "0" appended (ind_code), INDUSTL, OCCUP, OCCUPL carried; a crude ind_code by year frequency.
- Denominator: none in the file. suicide.sas divides 2013 county counts by county population per 1,000.
- Output: sui.suicides SAS dataset on K:, the input to A6.
- Where: /home/user/dc-hdd-surveillance/legacy/dc/, team-archive/analyses/suicide/

### A6. Team suicide by occupation per FTE (nioccs_suicide.R, Jean Kwizerimana adaptation of Chris Austin's tools)
- Numerator: A5's suicides file, DOD_YR 2014 onward.
- I/O source: INDUSTL and OCCUPL text. Coding: CDC NIOCCS web service, one GET per record, c = 2. Level: SOC major group and NAICS 2-digit sector (31-33, 44-45, 48-49 combined). SOC 11-9013 recoded into group 45. Group "00" dropped.
- Age: filter AGEUNITS >= 16. In the NCHS layout AGEUNITS holds the age number and AGETYPE its unit (scripts/io_death_rates_v8.R reads it that way, AGETYPE 1 = years), so this is effectively 16 and over, with no AGETYPE check. v9 reproduces A7's 2020-2021 sector counts exactly at 16 and over. Residency: inherited from A5.
- Denominator: ACS PUMS 2023 5-year FTE by SOC 2-digit (FTE = PWGTP x WKHP / 40, civilian employed). Unit: per 1,000 FTE. Ten years of deaths over one year of FTE.
- Standardization: none. Uncertainty: none. Suppression: none. Non-workers: dropped.
- Output: suicide_counts_occ.csv on K:. Does not run as saved.
- Where: team-archive/io-coding/nioccs/

### A7. Team suicide by industry and occupation per FTE (suicide_agg.R)
- Numerator: A6's coded file (suicide_coded_data.csv). Case definition, residency inherited from A5.
- I/O: NIOCCS NAICS 2-digit and SOC 2-digit as in A6. Age: AGEUNITS >= 16.
- Years: 2014 to 2023, year by year.
- Denominator: ACS PUMS FTE by NAICS 2-digit (mixed 1-year and 5-year vintages) and SOC 2-digit (5-year). Unit: per 1,000 FTE, annual.
- Uncertainty: SE from the denominator's sampling error only (delta method), no Poisson term. Suppression: none. Non-workers and "00": dropped.
- Output: suicide_fte_year*.csv, occ_suicide_fte_year*.csv. Does not run as saved.
- Where: team-archive/analyses/suicide/, team-archive/denominators/acs-pums-fte/

### A8. OHIs sub-indicators death block (subindicators.sas, S02 and S03; no suicide measure yet)
- Numerator: Guardian EDRS yearly exports saved as CSV (DeathCertificatesYY.csv), one row per DeathCertificateId, EventYear = file year.
- Case definition: S02 InjuryAtWork = Y, all manners; S03 pneumoconiosis any mention across D2SmicarAxis1-20. Residency: ResidingStateNchs = NE. Age: from NchsAge and NchsAgeUnit; 16+ for S02, 15+ for S03.
- I/O source: IndustryCode (the certificate's own Census code, 3-digit truncation), indc*10 mapped through the cind2sec format (2022 Census industry code list crosswalk) to NAICS 2-digit sector; UNK when missing. No NIOCCS, no occupation.
- Denominator: QCEW annual average employment by NAICS sector (fact_qcew.csv, 2014 to 2024); statewide employed 16+ from BLS Geographic Profile. Unit: per 100,000 employed (jobs for QCEW). FTE only for CFOI published rates.
- Standardization: age-adjusted for totals and sex only (S03), crude by industry. Uncertainty: not yet. Suppression: DHHS floor of 6 (rates blank on 1 to 5), fewer than 20 flagged unstable.
- Output: long fact table (sub-indicator x year x stratum x measure), subindicator_facts.xlsx.
- Where: /home/user/ohis/sub-indicators/

### A9. Massachusetts DPH opioid-related overdose deaths by I/O, 2018-2020 (the model)
- Numerator: death certificates, MA Registry of Vital Records. Case definition: underlying X40-X49, X60-X69, X85-X90, Y35.2, Y10-Y19 with multiple-cause T40.0-T40.4, T40.6 (all intents, opioid-involved). Residents, age 16+.
- I/O source: usual industry and occupation text. Coding: NIOCCS to NAICS and SOC plus manual review. Level: 20 NAICS sectors, SOC major groups.
- Exclusions: non-workforce (homemakers, unemployed, disabled, students), uncodable, military.
- Denominator: ACS average annual employed workers by sector and group. Unit: per 100,000 workers. Not FTE.
- Standardization: none by industry. Uncertainty: 95 percent CIs on rates, rate ratios vs all workers; Joinpoint for trend. Suppression: small cells suppressed.
- Where: source-docs/external/massachusetts/, source-docs/INVENTORY.md

### A10. CDC NVDRS suicide by industry and occupation (Peterson et al., MMWR 2020, 32 states, 2016)
- From memory, not re-read here; verify before citing. Numerator: NVDRS suicides, decedents aged 16-64 with a usual industry and occupation coded (NIOCCS to Census codes, rolled to NAICS sector and SOC major group). Denominator: Current Population Survey employed persons. Unit: per 100,000 civilian noninstitutionalized working population, by sex. 95 percent CIs. Excludes military, non-workers, and unpaid or unknown.
- Where: cited in docs/web-captures/cdc-nvdrs-resources.md

## B. Comparison table

| | A1 NEVDRS sheets | A2 NEVDRS sector sheet | A3 SUDORS sheets | A4 Vital Stats 10-yr | A5 legacy suicide file | A6 nioccs_suicide.R | A7 suicide_agg.R | A8 OHIs sub-indicators | A9 Massachusetts | A10 CDC NVDRS I/O |
|---|---|---|---|---|---|---|---|---|---|---|
| Numerator source | NVDRS abstraction | NVDRS abstraction | SUDORS abstraction | Death certificates | NCHS annual DC files | A5 | A6 | Guardian DC exports | Death certificates | NVDRS |
| Case definition | manner = suicide (X60-X84, Y87.0, U03) | same | X40-44, Y10-14 or overdose text | ICD underlying (unstated) | X60-X84, Y870, "UO3" typo | inherits A5 | inherits A5 | InjuryAtWork = Y; J60-J66 | opioid T40 with poisoning underlying | manner = suicide |
| Residency | residents | residents | not stated (CDC: occurrent) | residents | RES_ST = NE on occurrence file | inherits | inherits | ResidingStateNchs = NE | residents | residents |
| Age | all | all | all | all, by group | none | 16+ (AGEUNITS, no AGETYPE check) | 16+ (AGEUNITS, no AGETYPE check) | 16+ / 15+ | 16+ | 16-64 |
| Years | 1 or 2 | 2020-21 pooled | 2 pooled | 2013-22 by year | 2005-23 | 2014-23 pooled | 2014-23 by year | by year 2021-25 | 2018-19, 2020 | 2016 |
| I/O source | none | unstated | none | none | DC codes carried | DC text | DC text | DC industry code | DC text | NVDRS (DC) text |
| I/O coding | | unstated | | | none | NIOCCS | NIOCCS | Census code crosswalk | NIOCCS + manual | NIOCCS |
| I/O level | | sector | | | Census 4-digit | NAICS 2, SOC 2 | NAICS 2, SOC 2 | NAICS 2 | NAICS 2, SOC 2 | NAICS 2, SOC 2 |
| Non-workers | | own panel, pop denominator | | | | dropped | dropped | UNK row | excluded, stated | excluded, stated |
| Denominator | population | population | population | population | none / county pop | ACS PUMS FTE | ACS PUMS FTE | QCEW jobs, BLS employed | ACS employed workers | CPS employed |
| Unit | per 100,000 pop | per 100,000 pop | per 100,000 pop | per 100,000 pop | per 1,000 pop | per 1,000 FTE | per 1,000 FTE | per 100,000 employed | per 100,000 workers | per 100,000 workers |
| Age standardization | maps only | none | maps only | yes | none | none | none | totals and sex only | none | none |
| Uncertainty | none | none | none | none | none | none | denominator SE only | none yet | 95% CI, rate ratios | 95% CI |
| Suppression | 1-5 | 1-5 (not on maps) | small numbers | not stated | none | none | none | floor 6, <20 unstable | small cells | small cells |
| Runs today | published | unpublished | published | published | on K: | no | no | yes (first run 9/24) | published | published |

## C. What is most common, and what to adopt

Counting across the ten:

- Numerator: death certificates in some form in 8 of 10 (NVDRS and SUDORS are death certificates plus investigative reports; the abstractor's manner can reclassify a handful of cases). The team's own work always starts from the certificate.
- Suicide case definition: X60-X84 plus Y87.0 and U03 everywhere it is spelled out. The one in-house typo (UO3) should be fixed at the source.
- Residency: Nebraska residents in every analysis that states it.
- Age floor: 16+ in every analysis that has an I/O denominator (A6 to A10). The all-ages NEVDRS sheets are the odd ones out, and A2's not-in-workforce panel shows why that matters.
- I/O source: the death certificate's usual industry and occupation text, coded by NIOCCS, in 4 of the 5 I/O analyses (A6, A7, A9, A10). The OHIs block (A8) is the one that uses the certificate's own Census code with a crosswalk. Both land on NAICS 2-digit sector and SOC major group.
- Denominator: three camps. Population (A1 to A4, wrong for sector rates). Employed workers (A8 QCEW, A9 ACS, A10 CPS). FTE (A6, A7, and Derry's stated preference). The published, citable analyses (A9, A10) both use employed workers per 100,000.
- Uncertainty and suppression: only the two external publications have confidence intervals; only the OHIs block has a coded suppression rule.

Recommended shared provenance for both the sub-indicator and the Can/Mamie check (one pipeline, two outputs):

1. Numerator: Guardian yearly death certificate datasets (A8's loader), residents, one row per certificate, age 16+ computed from NchsAge and NchsAgeUnit. Suicide: AcmeUnderlyingCode X60-X84, Y87.0, U03. Overdose: SUDORS definition (X40-X44, Y10-Y14, plus literal text) with an opioid subset on T40.0-T40.4, T40.6 in the multiple-cause fields, and the Massachusetts all-intent opioid definition as a second column for comparability. Years 2020 to 2024 pooled, and by year for the sub-indicator trend.
2. I/O: code IndustryLit and OccupationLIt through NIOCCS to NAICS sector and SOC major group (the majority method, and Massachusetts's), and also carry the certificate's IndustryCode crosswalk (A8's method) so the two can be compared on the same deaths. Keep explicit rows for not in workforce, not coded, and military; never drop them.
3. Denominator: ACS employed workers by sector and group (published C24030 and C24010, or PUMS with ESR 1 or 2), 2020-2024 5-year, times five for pooled rates; per 100,000 workers, matching A9 and A10. Add a second column per FTE from the team's PUMS tool (hours/40) if Derry wants it, computed from the same PUMS vintage so the two rates differ only in the hours weighting. QCEW stays as a cross-check, not the headline, because it counts jobs and drops most farm work.
4. Statistics: Poisson 95 percent CIs on counts, rate ratio against all workers, crude by sector (age-by-industry denominators are not available from published tables). No suppression during analysis (CLAUDE.md): every count is shown; the DHHS floor is applied once, to a final table, at public release.
5. Reconciliation with NEVDRS: before any rate, match the pooled 2020-2021 counts against the sector sheet (84, 72, 55) using both I/O methods. Agreement on counts isolates the denominator as the only difference.

## D. The two-for-one

Add S11 "Suicide deaths by industry and occupation" to the OHIs sub-indicator set. It reuses A8's loader, residency, age and dedupe (not its suppression, which belongs only to the release step), adds the suicide case definition and the NIOCCS coding step, and takes its denominator from the ACS files in this repo rather than QCEW. Its by-year rows feed the sub-indicator trend; its 2020-2021 pooled rows are the Can/Mamie comparison. An overdose measure (S12) is the same code with the SUDORS definition swapped in. The strata list (NAICS 2-digit plus UNK) already exists in ohis/sub-indicators/strata.csv; SOC major groups would be added.

Open decisions this does not settle: per worker vs per FTE as the headline (Derry), NIOCCS vs certificate code as the headline I/O method (recommend NIOCCS, report both), and whether the ACS denominator comes from published tables or PUMS (PUMS if FTE is wanted; either otherwise).
