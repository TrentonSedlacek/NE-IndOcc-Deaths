# Source document inventory

Text was extracted with pypdf 6.19.0 into `extracted-text/` (same relative path as `source-docs/`, `.txt` extension, with `===== Page N =====` markers between pages). All 42 PDFs yielded some text. Several 2020-2021 suicide fact sheets are scanned images with an OCR text layer; their text is noisy (broken words, stray glyphs) but readable in places, as noted below.

## Table of PDFs

Paths are relative to `source-docs/`.

| Path | Pages | What it is | Years covered |
|---|---|---|---|
| external/massachusetts/MA-opioid-related-overdose-deaths-by-industry-occupation-2018-2020.pdf | 11 | Massachusetts DPH Occupational Health Surveillance Program data brief (Sept 2022) on opioid-related overdose deaths by industry and occupation, with rates per 100,000 workers, rate ratios, race/ethnicity, paid sick leave, and a Methods section | 2018-2020 (trend figure 2011-2020) |
| ne-dhhs/dashboard-screenshots/Dashboard1.pdf | 1 | Browser print of the Nebraska Suicide Deaths Dashboard (Power BI), "Demographic Overview of Suicide Deaths" page | 2020-2022 |
| ne-dhhs/dashboard-screenshots/Dashboard2.pdf | 1 | Browser print of the same dashboard, "Incident Characteristics of Suicide Deaths" page | 2020-2022 |
| ne-dhhs/dashboard-screenshots/Dashboard3.pdf | 1 | Browser print of the same dashboard, "Geographic Distribution of Age-Adjusted Suicide Death Rates" page (map by Local Health Department) | 2020-2022 |
| ne-dhhs/dashboard-screenshots/Dashboard4.pdf | 1 | Same page as Dashboard3, printed 11 minutes later; extracted text is identical to Dashboard3 | 2020-2022 |
| ne-dhhs/factsheets/homicide/2020-and-2021-Nebraska-Behavioral-Health-Region-5-and-6-Homicide-Factsheet.pdf | 1 | NEVDRS homicide fact sheet, Behavioral Health Regions 5 and 6 (122 deaths) | 2020-2021 |
| ne-dhhs/factsheets/homicide/2020-and-2021-Nebraska-Homicide-Factsheet.pdf | 1 | NEVDRS statewide homicide fact sheet (156 deaths) | 2020-2021 |
| ne-dhhs/factsheets/homicide/2021-and-2022-Nebraska-Behavioral-Health-Region-5-and-6-Homicide-Factsheet.pdf | 1 | NEVDRS homicide fact sheet, Regions 5 and 6 | 2021-2022 |
| ne-dhhs/factsheets/homicide/2021-and-2022-Nebraska-Homicide-Factsheet.pdf | 1 | NEVDRS statewide homicide fact sheet | 2021-2022 |
| ne-dhhs/factsheets/other/2013-2022-Nebraska-Suicide-Fact-Sheet.pdf | 1 | Ten-year suicide trend fact sheet (counts, age-adjusted rates by year, age group, urbanicity) | 2013-2022 |
| ne-dhhs/factsheets/sudors/2021-and-2022-Nebraska-Behavioral-Health-Region-1-to-4-SUDORS-Fact-Sheet.pdf | 1 | SUDORS drug overdose death fact sheet, Regions 1 to 4 | 2021-2022 |
| ne-dhhs/factsheets/sudors/2021-and-2022-Nebraska-Behavioral-Health-Region-5-SUDORS-Fact-Sheet.pdf | 1 | SUDORS drug overdose death fact sheet, Region 5 (78 deaths) | 2021-2022 |
| ne-dhhs/factsheets/sudors/2021-and-2022-Nebraska-Behavioral-Health-Region-6-SUDORS-Fact-Sheet.pdf | 1 | SUDORS drug overdose death fact sheet, Region 6 | 2021-2022 |
| ne-dhhs/factsheets/sudors/2021-and-2022-Nebraska-SUDORS-Fact-Sheet.pdf | 1 | SUDORS statewide drug overdose death fact sheet (366 deaths, 9.6 per 100,000); demographics, substances, circumstances, age-adjusted regional map | 2021-2022 |
| ne-dhhs/factsheets/suicide/2020-Nebraska-Suicide-Factsheet.pdf | 1 | NEVDRS statewide suicide fact sheet | 2020 |
| ne-dhhs/factsheets/suicide/2020-and-2021-Disclosed-Suicide.pdf | 1 | Suicide deaths among those who disclosed suicidal intent (130 deaths); scanned, noisy OCR text | 2020-2021 |
| ne-dhhs/factsheets/suicide/2020-and-2021-Female-Suicide.pdf | 1 | Female suicide deaths (104 deaths); scanned, noisy OCR text | 2020-2021 |
| ne-dhhs/factsheets/suicide/2020-and-2021-Male-Suicide.pdf | 1 | Male suicide deaths (460 deaths); scanned, noisy OCR text | 2020-2021 |
| ne-dhhs/factsheets/suicide/2020-and-2021-Older-Adults-Suicide.pdf | 1 | Older adult suicide deaths (84 deaths); scanned, noisy OCR text | 2020-2021 |
| ne-dhhs/factsheets/suicide/2020-and-2021-Suicide-Means.pdf | 1 | Firearm (282 deaths) and strangulation (179 deaths) suicide summaries; scanned, noisy OCR text | 2020-2021 |
| ne-dhhs/factsheets/suicide/2020-and-2021-Various-Races-Suicide.pdf | 1 | Suicide deaths among minority races and ethnicities (78 deaths); scanned, noisy OCR text | 2020-2021 |
| ne-dhhs/factsheets/suicide/2020-and-2021-Veteran-Suicide.pdf | 1 | Veteran suicide deaths (81 deaths); scanned, noisy OCR text | 2020-2021 |
| ne-dhhs/factsheets/suicide/2020-and-2021-Working-Age-Population-Suicide.pdf | 1 | Working age population suicide deaths (440 deaths, 11.4 per 100,000); demographics, means, circumstances, census tract map | 2020-2021 |
| ne-dhhs/factsheets/suicide/2020-and-2021-Youth-and-Young-Adults-Suicide.pdf | 1 | Youth and young adult suicide deaths (98 deaths); scanned, noisy OCR text | 2020-2021 |
| ne-dhhs/factsheets/suicide/2021-Nebraska-Suicide-Factsheet.pdf | 1 | NEVDRS statewide suicide fact sheet (284 deaths, 14.6 per 100,000) | 2021 |
| ne-dhhs/factsheets/suicide/2022-Nebraska-Behavioral-Health-Region-1-to-4-Suicide-Fact-Sheet.pdf | 1 | NEVDRS suicide fact sheet, Regions 1 to 4 (106 deaths) | 2022 |
| ne-dhhs/factsheets/suicide/2022-Nebraska-Behavioral-Health-Region-5-Suicide-Fact-Sheet.pdf | 1 | NEVDRS suicide fact sheet, Region 5 (78 deaths) | 2022 |
| ne-dhhs/factsheets/suicide/2022-Nebraska-Behavioral-Health-Region-6-Suicide-Fact-Sheet.pdf | 1 | NEVDRS suicide fact sheet, Region 6 | 2022 |
| ne-dhhs/factsheets/suicide/2022-Nebraska-Suicide-Factsheet.pdf | 1 | NEVDRS statewide suicide fact sheet (305 deaths, 15.6 per 100,000) | 2022 |
| ne-dhhs/nevdrs/NEVDRS-CME-Partner-Factsheet.pdf | 2 | CDC NVDRS fact sheet for coroner/medical examiner partners | Not year specific (program since 2003) |
| ne-dhhs/nevdrs/NEVDRS-Coding-Manual.pdf | 271 | CDC NVDRS Web Coding Manual, Version 6.0 (revision date January 18, 2022) | 2022 manual version |
| ne-dhhs/nevdrs/NEVDRS-Infographic.pdf | 1 | CDC "Linking Data to Save Lives" NVDRS infographic | Cites 2019 national figures |
| ne-dhhs/nevdrs/NEVDRS-Overview.pdf | 2 | CDC NVDRS program overview | Cites 2019 national figures |
| ne-dhhs/nevdrs/NEVDRS-Vital-Statistics-Partners-Factsheet.pdf | 2 | CDC NVDRS fact sheet for vital statistics partners | Not year specific |
| ne-dhhs/nevdrs/NVDRS-Law-Enforcement-Partner-Factsheet.pdf | 2 | CDC NVDRS fact sheet for law enforcement partners | Not year specific |
| ne-dhhs/newsletters/Suicide-Prevention-Newsletter-Issue-1.pdf | 8 | NEVDRS Suicide Prevention Newsletter, Issue 1, Q1 2024 (team, fact sheets, annual frameworks, Power BI dashboard in development) | Published 2024; data 2020-2022 |
| ne-dhhs/newsletters/Suicide-Prevention-Newsletter-Issue-2.pdf | 5 | Issue 2, Q2 2024 (dashboard demonstration, annual reports, census tract maps) | Published 2024; data 2020-2022 |
| ne-dhhs/newsletters/Suicide-Prevention-Newsletter-Issue-3.pdf | 5 | Issue 3, Q3 2024 (2022 NEVDRS data published, dashboard updated) | Published 2024; data 2021-2022 |
| ne-dhhs/newsletters/Suicide-Prevention-Newsletter-Issue-4.pdf | 5 | Issue 4, Q4 2024 (2022 data, dashboard enhancements) | Published 2024; data 2021-2022 |
| ne-dhhs/newsletters/Suicide-Prevention-Newsletter-Issue-5.pdf | 5 | Issue 5, first half of 2026 (team roster, annual suicide death reports, 2022 fact sheets, live Power BI dashboard) | Published 2026; data 2020-2022 |
| ne-dhhs/sudors/SUDORS-Coding-Manual.pdf | 158 | CDC SUDORS Coding Manual, Version 6.3 (11/28/2022) | 2022 manual version |
| ne-dhhs/sudors/SUDORS-Factsheet.pdf | 2 | CDC SUDORS program fact sheet (data sources, goals, uses) | Not year specific (program since 2016) |

## Industry and occupation mentions

Search terms (case-insensitive): industry, occupation, sector, construction, manufacturing, worker, employment, job. Trivial hits are omitted ("illicitly manufactured fentanyl", "co-worker", "health care workers administered naloxone", "validation job", "DHHS employees"). Where nothing relevant was found, that is stated.

### Nebraska DHHS documents

None of the NE DHHS fact sheets (suicide, homicide, SUDORS), the 2013-2022 suicide fact sheet, the five newsletters, or the dashboard screenshots contain any industry, occupation, or sector counts or rates. No NE DHHS document in this collection states a method for producing industry or occupation numbers. The only related content is:

- **ne-dhhs/nevdrs/NEVDRS-Coding-Manual.pdf, page 44-45 (section 3.2.4 Usual Occupation Variables).** Defines the four death certificate (DC) fields NVDRS abstractors record: "Industry: Victim's usual business/industry code as recorded on the DC", "IndustryText: Victim's usual business/industry text as recorded on the DC", "UsualOccupation: Usual occupation of the victim as recorded on the DC", "OccupationText: Usual occupation text of the victim as recorded on the DC". Method statement on page 45: "Most states' registry of vital records encodes the decedent's usual occupation and industry on the DC. Usual occupation/industry is not necessarily the victim's current occupation/industry. Provide information exactly as it appears in the DC data. Sites should NOT code the information themselves, as industry and occupation coding requires special training". Code source: "Occupation codes recorded on the death certificate are based on the U.S. Census Bureau's Industry and Occupation Codes. See https://www.census.gov/topics/employment/industry-occupation/guidance/code-lists.html." Codes "999" (occupation) and "090" (industry) mean blank/unknown/N/A; "080" means text only, code not available.
- **ne-dhhs/nevdrs/NEVDRS-Coding-Manual.pdf, page 45-46 (section 3.2.5 Current occupation: OccupationCurrentText).** "Occupation is an indicator of socioeconomic status. Certain occupations may also be associated with the occurrence of suicide or homicide." Free text from any source document, or one of: Employed, specific occupation unknown; Unemployed; Homemaker; Retired; Student; Disabled; Self-employed; N/A (under age 14); Unknown. "The information can later be coded at the national level using Standard Occupational Classifications." "People who work 17.5 hours or more per week are considered employed".
- **ne-dhhs/nevdrs/NEVDRS-Coding-Manual.pdf, page 135-136 (sections 5.7.14 and 5.7.15).** Circumstance variables "Job problem: CME/LE_JobProblem" ("Job problem(s) appear to have contributed to the death") and "Job problem was crisis: CME/LE_CrisisJob". These are circumstance flags, not occupation classifications.
- **ne-dhhs/nevdrs/NEVDRS-Coding-Manual.pdf, page 251.** Public safety officer (PSO) module notes that NAICS and SOC codes can identify specific workers and refers back to the usual occupation variables and the Census code list link.
- **ne-dhhs/sudors/SUDORS-Coding-Manual.pdf, page 27.** Lists the required SUDORS demographic variables, including "Kind of Business/Industry Code", "Usual Industry Text", "Usual Occupation Code", "Usual Occupation Text", and "Current Occupation" under "Place of Residence, Birthplace, Industry, Occupation, and Education Variables", and states "Please refer to the NVDRS Coding Manual for further coding guidance if coding for a specific variable is not covered in the SUDORS Coding Manual." No coding method for these variables is given in the SUDORS manual itself.
- **ne-dhhs/dashboard-screenshots/Dashboard2.pdf, page 1.** The circumstances chart includes "Job Problems Contributed to Death" (50 deaths, 2020-2022 combined). This is the NVDRS job problem circumstance, not an occupation or industry breakdown.
- **ne-dhhs/nevdrs/NEVDRS-Infographic.pdf, page 1** ("Problems with job or finances") and **ne-dhhs/nevdrs/NEVDRS-Overview.pdf, page 1** ("recent problems with a job, finances, or physical health"): CDC descriptions of circumstance data, not I/O statistics.
- **ne-dhhs/factsheets/suicide/2020-and-2021-Working-Age-Population-Suicide.pdf, page 1.** The fact sheet is framed by working age (ages 19-64, 440 deaths, 11.4 per 100,000 population) with demographic, means, circumstance, and census tract breakdowns, but contains no industry or occupation figures. Its rate denominator is total population, not workers.

Takeaway: the industry/sector work Can Ceyhan referenced in the 2026-09-23 meeting is not represented in any document in this collection. The only I/O data pathway documented here is the death certificate usual industry and usual occupation fields (Census Bureau industry and occupation codes) that NEVDRS and SUDORS abstractors copy into the CDC system, plus the free-text current occupation field.

### External document

- **external/massachusetts/MA-opioid-related-overdose-deaths-by-industry-occupation-2018-2020.pdf** is entirely about industry and occupation; see the Massachusetts section below. Example, page 4: "The opioid-related overdose death rate for all Massachusetts workers across all industry sectors was 44.7 deaths per 100,000 workers in 2018-2019 and 48.8 deaths per 100,000 workers in 2020." Page 8: "Construction and extraction (711.7 deaths per 100,000 workers)" (among Hispanic working-age decedents, 2016-2020).

## Dashboard screenshots

All four are single-page browser prints (dated 9/24/26) of the public "Nebraska Suicide Deaths Dashboard" on app.powerbigov.us, source "Nebraska Violent Death Reporting System (NVDRS), Nebraska DHHS". The tab bar shows Demographics, Characteristics, Geography, and About the Data. Filters are Year, Sex, Race and Ethnicity, Education, Age Range. Each page notes that counts between 1 and 5 are suppressed and that NVDRS suicide counts may differ from the Vital Statistics death dashboards. None of the pages has an industry or occupation filter or chart.

- **Dashboard1.pdf: Demographic Overview of Suicide Deaths.** Deaths by year (2020: 289, 2021: 305, 2022: 284), by sex (male 716, female 162), by age group (0-19: 73, 20-29: 146, 30-39: 187, 40-49: 155, 50-59: 128, 60-69: 88, 70-79: 65, 80+: 36), by educational attainment (less than high school 119, high school or GED 365, some college or associates 245, bachelor's 86, graduate 35, unknown 28), and by race/ethnicity (White NH 761, Black NH 30, Asian/PI NH 10, American Indian NH 15, multiracial NH 8, Hispanic 54). Filters set to 2020-2022, all categories.
- **Dashboard2.pdf: Incident Characteristics of Suicide Deaths.** Deaths by means (firearm 468, hanging/strangulation/suffocation 260, poisoning 103, sharp instrument 17, fall 8, motor vehicle 8, other transport 6), by location type (house/apartment 635, street 39, natural area 32, hotel 25, park 25, parking lot 22, jail/prison 20, farm 19, and others), substances recorded (alcohol 158, other drugs 117, antidepressant 104, marijuana 70, benzodiazepines 69, opiate 67, amphetamine 59, and others), and circumstances present (appearing depressed 450, left note 265, history of suicidal ideation 251, ... job problems contributed to death 50). Footnotes: only means and location types above 1 percent shown; substances and circumstances are not mutually exclusive.
- **Dashboard3.pdf: Geographic Distribution of Age-Adjusted Suicide Death Rates.** Map of age-adjusted death rate per 100,000 by Local Health Department, 2020-2022, range 10.9 to 24.1, with a map level selector (State, Behavioral Health Regions, Local Health Departments) and rates flagged "**Unstable rate, use with caution". The individual rate labels are present in the text but not tied to LHD names.
- **Dashboard4.pdf.** Identical content to Dashboard3 (same map page, printed at 4:43 PM instead of 4:32 PM). Not empty, but adds nothing new.

## Massachusetts report: methodology for I/O rates

Source: external/massachusetts/MA-opioid-related-overdose-deaths-by-industry-occupation-2018-2020.pdf, Massachusetts Department of Public Health, Occupational Health Surveillance Program, September 2022. Methods are on pages 10-11, with per-figure footnotes on pages 3-9.

- **Numerator (case definition), page 10.** Death certificates from the Massachusetts Registry of Vital Records. Underlying cause ICD-10 codes X40-X49, X60-X69, X85-X90 and Y35.2, Y10-Y19 (all poisoning deaths regardless of intent), and multiple cause fields with T40.0, T40.1, T40.2, T40.3, T40.4, T40.6 to identify opioid involvement. Working-age is defined as residents 16 years or older (page 1).
- **Occupation and industry data source, page 10.** "Additional information obtained from the death certificates included decedent's age, sex. Race/ethnicity, residence, and usual industry and occupation." That is, the usual industry and usual occupation free-text fields on the death certificate.
- **Coding, page 10.** "Using the National Institute for Occupational Safety and Health Industry and Occupation Computerized Coding System (NIOCCS), industry and occupation were assigned North American Industry Classification System (NAICS) codes and the Standard Occupation Classification System (SOC) codes, respectively, and were further classified by manual review." Industry results are presented by 20 industry sectors (2-digit NAICS level) and occupation by major SOC occupational groups.
- **Exclusions, page 10 and figure footnotes.** Out-of-state residents; individuals not in the workforce (homemakers, unemployed or never employed, unable to work due to disability or another reason, students); deaths whose certificates lacked enough information to code industry or occupation; and military or military-specific occupations "due to lack of denominator information" (for example, 14 military and 50 uncodable-industry deaths excluded in 2018-2019, 5 and 13 in 2020).
- **Denominator, pages 3-10 and Data Sources on page 11.** "Data on the average annual number of workers employed in Massachusetts between 2011 and 2020 were obtained from the American Community Survey, 2011-2020 and served as the denominator for rates." Every figure carries "Denominator source: American Community Survey" (2020 for single-year figures, 2018-2020 or 2016-2020 for pooled figures). Rates are expressed as deaths per 100,000 workers (employed persons). The report does not use full-time equivalents (FTE) or hours-worked adjustment; the term FTE does not appear in the document.
- **Rate calculation, page 10.** Two-year average annual rates for 2018-2019 and one-year rates for 2020, "calculated as the number of deaths per 100,000 workers. 95% confidence intervals were calculated for all rates." Rate ratios by industry sector and occupation group are shown in Figures 3 and 5 (pages 5 and 7). Joinpoint regression was used for the 2011-2020 trend.
- **Additional stratifier, pages 9-11.** Industry sectors and occupation groups were categorized as high or low availability of paid sick leave using the MDPH COVID-19 Community Impact Survey (cutoffs 82.2 percent for industry and 82.5 percent for occupation).

For a Nebraska replication the analogous inputs would be: death certificate usual industry and occupation text (also carried into NEVDRS/SUDORS as the Industry, IndustryText, UsualOccupation, and OccupationText variables), NIOCCS coding to NAICS and SOC, and ACS employed-worker counts by industry sector and occupation group for Nebraska as denominators.
