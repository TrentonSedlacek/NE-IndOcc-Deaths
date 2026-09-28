# Team analysis scripts (archive)

Analysis scripts uploaded from the occupational health team's K: drive, most of them from the working folder `K:\Occupational Health Grant\Jean Kwizerimana\` (the Rmd names Chris Austin as author). They are SAS and R, written to run interactively on a DHHS machine; none of them runs here, and several do not run as written (noted below). Filenames are unchanged from the upload; files were moved with `git mv` on 2026-09-28.

Short answer for the I/O deaths project: **only `suicide/suicide_agg.R` computes deaths by industry or occupation** (suicide, per 1,000 ACS PUMS "FTE", by NAICS sector and SOC major group). **No script here computes drug or opioid overdose deaths**, from any source. `substance.sas` and `poison.sas` are poison center call analyses, not death certificate work.

## Layout

| Folder | Contents |
|---|---|
| `suicide/` | Suicide deaths from the NCHS annual death file: county rates and the I/O rate table. |
| `atv-deaths/` | ATV (V86) deaths from death certificates, with NIOCCS-coded occupation. |
| `cancer-registry/` | Bladder, lung and mesothelioma analyses of a Nebraska Cancer Registry extract (plus NIOCCS coding of its occupation text). |
| `poison-control/` | Nebraska Regional Poison Center (PCC / NPDS case detail) cleaning scripts and topic analyses: pesticides, blue-green algae, vitamin A, occupational exposures, substances, CSTE spike detection, the 2024 formaldehyde/CO2 incident report. |
| `modeling/` | Method exercises: decision trees and descriptive/interrupted time series work on PCC data, a moving-average demo, and simulated-data mixed models. |

`popcounty.sas` was suggested for a `population/` folder but it is a cancer-registry script (lung cases per county population, mesothelioma counts), so it sits in `cancer-registry/`.

Related scripts elsewhere in the archive: `../io-coding/nioccs/nioccs_suicide.R` builds the NIOCCS-coded suicide file that `suicide_agg.R` reads (see below).

## Inventory

Data source key. **NCHS annual**: the fixed-width NCHS occurrence files read into `dth{YY}` and combined by the legacy `combine data.sas` (dc-hdd-surveillance repo, `legacy/dc/`). **Guardian**: the EDRS yearly exports. **PCC**: poison center case detail exports. **NCR**: Nebraska Cancer Registry extract ("Derry_Stove_Request3/4.xlsx").

| File | Lang | Data source | Outcome / case definition | Years | Industry / occupation use | Output |
|---|---|---|---|---|---|---|
| `suicide/suicide.sas` | SAS | NCHS annual (`mylib.suicides`), plus pre-aggregated `deathspercounty.xlsx` and `county.xlsx` population | Inherited from `suicides.sas7bdat` (see close reading) | 2013 only | None | `dpercount.xlsx`: suicides per 1,000 population by county |
| `suicide/suicide_agg.R` | R | NIOCCS-coded NCHS suicide file `suicide_coded_data.csv`; ACS PUMS FTE files | Inherited from `suicides.sas7bdat`; age 16+ | 2014 to 2023 (industry), 2016 to 2023 (occupation) | Yes: NIOCCS `NAICSCode` to 2-digit sector, `SOCCode` to 2-digit major group; ACS PUMS FTE denominators | Six CSVs of count and rate per 1,000 FTE by year |
| `atv-deaths/ATV.sas` | SAS | NCHS annual (`mylib.atv_0523`) and `nioccs_coded_atv.csv`; `2002-acs-ind-codes.xls` | ATV: any RAXSCD01-20 starting V86 (set upstream in `combine data.sas`); `ACUND_CAUSE` V860/V861/V863/V865/V866/V869 split into traffic/non-traffic, driver/passenger | 2005 to 2023 | Yes: joins DC industry code to Census 2002 industry titles on first 3 characters; freq of `OCCUPL` | Descriptive tables, charts, Poisson and t-test on traffic counts; `square.csv` |
| `atv-deaths/atv_coded.sas` | SAS | `nioccs_atv.csv` (Guardian-style names: `AcmeUnderlyingCode`, `DeathCertificateId`, `InjuryHowOccur`, `ResideInCity`) | Same V86x codes on `AcmeUnderlyingCode`; drops records whose `InjuryHowOccur` mentions UTV, utility, golf, bike or Polaris | 2005 to 2023 | Yes: NIOCCS `CensusOccupationcode` 205, 6050 = "Farmers", 9070 = "Students"; freqs of `SOCcode`, `occupationcode`, `CensusOccupationTitle` | Descriptive stats, chi-square, logistic (sex vs driver), Poisson trend, ESM and ARIMA forecasts |
| `cancer-registry/bladder.sas` | SAS | NCR `Derry_Stove_Request3.xlsx` | `cancer_type_use = "URINARY BLADDER"`; death from bladder cancer = `causeofdeath = "C679"` | Registry years (2016 to 2020 plotted) | Freq of `textUsualOccupation` only | Descriptives, Kaplan-Meier, Cox models by poverty, age, sex, behavior |
| `cancer-registry/bladda.sas` | SAS | NCR `Derry_Stove_Request4.xlsx` | As `bladder.sas`, excludes stage 5 and 9 | As above | As above | As above, with a stage grouping and a 500-record random sample |
| `cancer-registry/bladder.R` | R | NCR Request4 (lung and bladder rows) | `cancer_type_use` in LUNG & BRONCHUS, URINARY BLADDER; drops unknown usual industry/occupation text | Registry years | Yes: sends `textUsualOccupation` to the CDC NIOCCS web API, then groups SOC 2-digit codes into 22 major groups (hard-coded SOC major group list; recodes SOC 11-9013 farmers to 45) | Occupation frequency table (in memory). Does not run: `ba` is undefined, and `textUsualOccupation` is sent as the industry text too |
| `cancer-registry/lung.sas` | SAS | NCR Request4; `Lung Cancer\county.xlsx` | `cancer_type_use = "LUNG & BRONCHUS"`; status uses `causeofdeath = "C679"` (the bladder code, copied over; should be C34x) | Registry years | Freq of `textUsualOccupation` | `lungcancer.xlsx` (record-level export), descriptives, survival models |
| `cancer-registry/lung_dataset.R` | R | `lungcancer.xlsx` (from `lung.sas`) | All lung records | Registry years | Yes: NIOCCS web API on `textUsualIndustry` and `textUsualOccupation`, joined back by row ID | `lung_io_coded.csv`, `lungcoded.csv` (record-level, with county population) |
| `cancer-registry/popcounty.sas` | SAS | `casespercounty.xlsx`, `county population.xlsx`; NCR Request3 | Lung cases per county; mesothelioma = `cancer_type_use = "MESOTHELIOMA"`, histology 9050 to 9053, age 15+ | Registry years | None | `casepop_data.xlsx` (cases per 1,000 by county), mesothelioma charts |
| `poison-control/poison_control.R` | R | PCC `poisoncenter.poisoncasedetails.ft.substance.csv`, `pcc_reference_file.xlsx` | Cleaning; then generic code desc "Carbon Dioxide" or "Formaldehyde or Formalin" | 2007 to 2024 | None | `PoisonControl_7_08_2024.csv`; renders the Rmd |
| `poison-control/poison_control (2).R` | R | Same | Same | 2019 to 2024 daily | None | `PoisonControl_5_16_2024.csv` (the file most SAS scripts read); has a dangling `pcc_reference_gc$` line that stops it |
| `poison-control/poison_r.R` | R | Same, relative paths | Same | 2019 to 2024 | None | `PoisonControl_5_16_2024.csv`; likely the earliest of the three |
| `poison-control/pcc300924.R` | R | PCC case details, ft.substance, substance tables; generic code descriptions | Merge of three PCC tables on `caseID` | All | None | `pcc_fully.csv`, `pcc_finalized.xlsx` |
| `poison-control/pcc_occupaitonal_ex_form_carbdiox.Rmd` | Rmd | Objects built by `poison_control.R` | CO2 / formaldehyde exposures, reason Unintentional - Occupational or Environmental | 2018 to 2024 | None (PCC "occupational" reason, not I/O) | HTML report to the State Epidemiologist on a March 2024 NPDS alert. See PHI notes |
| `poison-control/poison.sas` | SAS | PCC ft.substance (also imports `pcc_fully.csv`, unused) | `reason = 3` (Unintentional - Occupational), `outcome` 2, 3, 4 (moderate, major, death) | 2014 to 2023 | None | Descriptive charts by route, formulation, age, sex, caller site |
| `poison-control/substance.sas` | SAS | PCC `PoisonControl_5_16_2024.csv` | (a) biguanide / sulfonylurea generic codes 0201118, 0201119, decision trees; (b) marijuana (15 generic codes), alcohol (0019140), methamphetamine (0201127) calls with moderate/major/death outcome; (c) `reason` 2, 3 environmental / occupational; (d) pesticide `major_gc_id = 193` | 2007 to 2023 | None | Charts, `reportt.xlsx`. Ends with orphaned "old code" that will not run |
| `poison-control/cste.sas` | SAS | PCC `PoisonControl_5_16_2024.csv` | `reason = 3`, human, exposure calls, acute, outcome 1 to 4 | 2007 to 2023 | None | Occupational vs all-call trend, ARIMA residual, IQR and CUSUM spike detection (comment says h = 5 SD, code uses 15 SD) |
| `poison-control/pesticides.sas` | SAS | PCC `PoisonControl_5_16_2024.csv` | Blue-green algae generic 0201107; pesticides = `major_gc_category = "Pesticides"`, human, exposure, acute, outcome 1 to 4 | 2014 to 2023 | None (exposure site 3, 4, 6 = "Workplace"; reason 3 = "Occupational") | `bluealgae.csv` (line list), `Pesticide Final.xlsx` frequency tables |
| `poison-control/pesticides_dts 8.21.26.sas` | SAS | Same file under `poison\pesticide\` | Same | Same | Same | Same, plus a symptom split of `clinicalEffectCodeValue` |
| `poison-control/nitrous oxide.sas` | SAS | PCC ft.substance 3.10.25 and code value workbook | **Vitamin A**, generic code 0045000 (not nitrous oxide, despite the name) | All | None | `vitamina.xlsx` month-by-year counts |
| `poison-control/nitrous.R` | R | `pcc_fully.xlsx` | None (two lines: read, `nrow`) | n/a | None | None |
| `modeling/decisiontrees.sas` | SAS | PCC `PoisonControl_5_16_2024.csv` | Biguanide / sulfonylurea; marijuana / methamphetamine; `root_id` trees; pesticide `major_gc_id = 193` | 2013 to 2023 | None | HPSPLIT trees, frequency tables |
| `modeling/train__clean.sas` | SAS | Same | First 91 lines identical to `substance.sas`; then a `root_id` tree on GC category | 2013 to 2023 | None | HPSPLIT trees |
| `modeling/training.sas` | SAS | PCC ft.substance and `PoisonControl_5_16_2024.csv` | First 65 lines near-identical to `poison.sas`; then species by outcome, COVID-era call volume, marijuana time series, Chow test at 12 Mar 2020 | 2011 to 2024 | None | `speciesbyoutcome.docx`, charts, regressions |
| `modeling/moving_averages.R` | R | Hard-coded annual counts and NE population | Unlabelled death series of 3 to 14 per year (years 2005 to 2023 match the ATV series) | 2005 to 2023 | None | 4-year centered moving average plot. Column is named `Rate_per_100k` but the values are per 1,000,000 |
| `modeling/simulating models.R` | R | Simulated data only | None | n/a | None | Mixed-model and Gauge R&R demos |

### Hard-coded paths

Every script except `poison_r.R`, `moving_averages.R` and `simulating models.R` uses absolute K: paths. Roots in use:

- `K:\Occupational Health Grant\Jean Kwizerimana\Deacertificate\` (suicide data, ATV, NIOCCS outputs, `socc.csv`, `2002-acs-ind-codes.xls`)
- `K:\Occupational Health Grant\Jean Kwizerimana\FTE\Occupation\` and `K:\Occupational Health Grant\Chris Austin\ACS FTE\Outputs\` (ACS PUMS FTE denominators)
- `K:\Occupational Health Grant\Jean Kwizerimana\Bladder Cancer\`, `...\Lung Cancer\`
- `K:\Occupational Health Grant\Jean Kwizerimana\poison\` (with `pcc data\` and `pesticide\` subfolders), `...\SAS projects\`

The `suicides.sas7bdat` read here sits in Jean's `Deacertificate\suicide data\` folder; the legacy builder writes it to `K:\Occupational Health Grant\data\dc\Annual\`. Confirm the two copies match before reuse.

## Duplicates checked

md5 differs for all four pairs, so all eight files are kept.

| Pair | Finding |
|---|---|
| `poison_control (2).R` vs `poison_control.R` (and `poison_r.R`) | Three versions of one cleaning script. `poison_r.R` (relative paths) and `(2)` write `PoisonControl_5_16_2024.csv` and plot daily CO2/formaldehyde counts; `poison_control.R` is the later one: K: paths, writes `PoisonControl_7_08_2024.csv`, plots by year and by `createdDate`, drops the `startCalendar` date conversion. `(2)` contains a stray `pcc_reference_gc$` line. |
| `bladda.sas` vs `bladder.sas` | Same program. `bladda.sas` is newer: reads Request4 instead of Request3, excludes stage 5 and 9, adds a stage grouping, and fits the survival models on a 500-record random sample (Kaplan-Meier stratified by sex). |
| `pesticides.sas` vs `pesticides_dts 8.21.26.sas` | Identical except the input path (`poison\pesticide\`) and a 26-line symptom-splitting block added at the end of the `_dts` version. The `_dts` file is a strict superset. |
| `ATV.sas` vs `atv_coded.sas` | Different programs on the same topic. `ATV.sas` works from the NCHS annual extract with `ACUND_CAUSE`, joins industry codes to Census 2002 titles, and has a broken data step (lines 55 to 90 have no `DATA` statement). `atv_coded.sas` is the later, cleaner version on a NIOCCS-coded file with Guardian field names, adds the UTV/golf/bike exclusion, occupation groups, forecasting and logistic models. |

Also near-duplicated, not requested: `substance.sas` lines 1 to 91 equal `train__clean.sas` lines 1 to 91; `poison.sas` lines 1 to 64 match `training.sas` lines 1 to 65 apart from one extra import.

## Directly relevant to the industry and occupation deaths project

### Where the suicide file comes from (upstream, not in this folder)

Both suicide scripts read `suicides.sas7bdat`. It is built in `legacy/dc/combine data.sas` in the dc-hdd-surveillance repo:

- Source: NCHS annual files `dth05` to `dth23` stacked into `dth05_23`, then step `dth2`, which adds `ind_code = INDUST || "0"` (the Census industry code with the dropped trailing digit restored).
- Case definition: `ACUND_CAUSE between "X60" and "X84" or ACUND_CAUSE = "Y870" or ACUND_CAUSE = "UO3"`. The last term has a letter O, so U03 (terrorism suicide) never matches. Underlying cause only; no manner-of-death check.
- Residence: `RES_ST = "NE"`. No age restriction. Occurrence file, so NE residents who died out of state are missing.
- Variables carried: all NCHS fields, including `INDUST`, `INDUSTL`, `OCCUP`, `OCCUPL`, `ind_code`, `DOD_YR`, `AGEUNITS`, `CNTYOD`.

Then `../io-coding/nioccs/nioccs_suicide.R` keeps `DOD_YR >= 2014`, sends `INDUSTL` and `OCCUPL` (the literals, not the codes) to the CDC NIOCCS web service (`https://wwwn.cdc.gov/nioccs/IOCode?`, parameter `c = 2`), and joins the returned `NAICSCode`, `SOCCode`, `CensusOccupationTitle` and related fields back by row ID. Its output is written as `suicide_coded_datac.csv`, but `suicide_agg.R` reads `suicide_coded_data.csv` (no "c"). Confirm which file is current.

### `suicide/suicide_agg.R`: suicide rates by industry and occupation

What it does, section by section.

Industry (lines 1 to 171):

1. Reads ACS PUMS "FTE" estimates by 2-digit NAICS for 2014 to 2023 from `Chris Austin\ACS FTE\Outputs\`. Vintages are mixed: 5-year for 2014 to 2017, 2019, 2020, 2022, 2023; 1-year for 2018 and 2021. Column names differ by year and are renamed to `n`, `n_se`, `NAICSP`; `a.2023` is not renamed, so its columns must already be `n`/`n_se`/`NAICSP` or 2023 comes through empty.
2. Labels 20 sectors from `NAICSP` with regexes (`^31-33`, `^44-45`, `^48-49` assume the PUMS file already stores combined sector strings).
3. Numerator: `suicide_coded_data.csv`; `NAICS = substr(NAICSCode, 1, 2)`, then 31/32/33, 44/45, 48/49 collapsed to the combined sectors. Keeps `AGEUNITS >= 16` and `NAICS != "00"`.
4. Counts deaths by `NAICSP`, `DOD_YR`, left-joins them onto the denominator rows by sector and year, and sets missing counts to 0.
5. Rate: `suicide_per_1000_fte = Count / n * 1000`; SE: `Count * 1000 / n^2 * n_se` (denominator sampling error only, by the delta method).
6. Writes `suicide_fte_year.csv` (wide "count (rate)"), `suicide_fte_year_2.csv` (wide, count and rate columns), `suicide_fte_year_long.csv`.

Occupation (lines 173 to 292): same pattern with ACS PUMS FTE by 2-digit SOC for 2016 to 2023 (all 5-year) from `Jean Kwizerimana\FTE\Occupation\`, numerator `substr(SOCCode, 1, 2)` excluding "00", major group names from `Deacertificate\ATV\socc.csv` (`SOC`, `OccCategory`). Writes `occ_suicide_fte_year.csv`, `occ_suicide_fte_year_2.csv`, `occ_suicide_fte_year_long.csv`.

It does not run as written:

- Line 102 uses `working_groups` (undefined; the object is `working_group`).
- It groups by `Ind_sector`, which exists only on the denominator table, not on the decedent table. The later references to `Ind_sector.x` show an earlier version joined the sector names onto the numerator first.
- `str_detect`, `pivot_wider`, `write_csv` are used before `library(tidyverse)` is loaded (line 250); only `dplyr` is loaded at the top.
- In the occupation section, the join from `socc.csv` onto decedents gives SOC groups with no deaths a row with `year = NA` that `n()` counts as 1. Those rows fall away at the join by year, so results survive, but only by accident.

Method issues to settle before reusing the numbers:

- The rate is per 1,000 FTE. The Massachusetts model and the brief's likely choice is per 100,000 ACS employed workers.
- Decedents with NAICS or SOC "00", and any code without a denominator row (unemployed, never worked, homemaker, student, retired, military, insufficient information), vanish silently. There is no non-worker or not-coded row, which is the part of the NEVDRS sheet that most needs checking.
- `AGEUNITS >= 16` assumes the age is in years; filter on `AGETYPE` (or the Guardian `NchsAgeUnit`) as well.
- No confidence intervals for the count (Poisson), no suppression (DHHS floor of 6, CSTE fewer than 5), no pooling of years; single-year sector counts will be small.
- Year-specific rates use mixed 1-year and 5-year denominators, so the year-to-year trend is not like-for-like.
- NIOCCS coding confidence and the "insufficient information" results are not examined.

To reuse for the project: take the numerator from 2020 to 2024 (Guardian yearly datasets or NCHS annual), with X60-X84, Y87.0 and U03 spelled correctly, NE residents, age 16+ by age unit, one row per certificate; code industry and occupation either through NIOCCS on `IndustryLit`/`OccupationLIt` (as here and as Massachusetts did) or by crosswalking `IndustryCode`/`OccupationCode` to NAICS sector and SOC major group; keep non-worker, not-coded and military as explicit rows; swap in ACS employed workers from one 5-year vintage; pool years; add Poisson 95% CIs, rate ratios and suppression; replace the K: paths. The join-and-rate skeleton (sector labels, the 31-33/44-45/48-49 collapse, count-by-group then left-join to the denominator, zero fill) is worth keeping.

### `suicide/suicide.sas`: suicides by county

- Reads `mylib.suicides` (the file above), keeps `dod_yr = 2013`, and prints it. That dataset is then discarded: the rate step uses `deathspercounty.xlsx` (already aggregated counts, variable `deaths`) joined to `county.xlsx` (population `Value`) on `Code`.
- Rate: `suicpercounty = deaths / Value * 1000` (per 1,000, not per 100,000).
- Output `dpercount.xlsx`. `proc means` on `ageunits` and a freq of `CNTYOD` (county of occurrence, not residence) run on the joined table, where those variables do not exist.
- No industry or occupation use. Nothing to reuse beyond the confirmation that `mylib.suicides` is the NCHS-based file.

### `poison-control/substance.sas` and `poison-control/poison.sas`

Both are poison center call analyses. Neither touches death certificates, NVDRS or SUDORS, and neither has industry or occupation fields (PCC records do not carry them).

- `substance.sas`: case definitions are PCC generic codes: biguanides 0201118 and sulfonylureas 0201119; marijuana 0083000, 0200617, 0200618, 0310033 to 0310035, 031003 (likely a typo for 0310036, which `training.sas` uses), 0310096, 0310097, 0310121 to 0310126; alcohol beverage 0019140; methamphetamine 0201127. Outcome 2, 3, 4 = moderate effect, major effect, death. "Occupational" means `reason = 3` (Unintentional - Occupational); `reason = 2` is environmental. Years 2007 to 2023, charts titled 2013 to 2023.
- `poison.sas`: `reason = 3`, outcome 2 to 4, 2014 to 2023, restricted to listed routes; descriptive only.
- Relevance: PCC deaths (outcome 4) are a handful per year and are not a substitute for a death certificate overdose numerator. At most, the PCC "occupational" reason could be a side check on work-related exposures. Nothing here implements the SUDORS or Massachusetts overdose definitions; that code has to be written new (the dc-hdd-surveillance template's 41-field scan and literal-text match are the starting point).

### Other scripts that touch industry or occupation fields

- `atv-deaths/ATV.sas`: the only script here that works with death certificate industry codes directly. It imports Census 2002 industry codes (`2002-acs-ind-codes.xls`), pads 3-digit codes to 4 with a leading zero, keeps ATV records whose `code_char` (renamed from `industrycode`) is 3 characters long, and joins on the first 3 characters of each. That matches the idea that the DC stores Census codes with the trailing digit dropped, but two cautions: `put(code_char, 4.)` on an imported numeric code loses leading zeros, so codes below 100 are dropped rather than matched; and 2002 Census codes will not match records coded to the 2012 or 2017/2018 Census lists. It also runs `proc freq` on `OCCUPL`.
- `atv-deaths/atv_coded.sas`: uses NIOCCS output fields `CensusOccupationcode` (205 and 6050 as farmers, 9070 as students), `SOCcode`, `occupationcode`, `CensusOccupationTitle`. Occupation grouping only, no denominator.
- `cancer-registry/bladder.R` and `lung_dataset.R`: NIOCCS web API coding of registry `textUsualIndustry` / `textUsualOccupation`, the same function as `nioccs_suicide.R`. `bladder.R` has the only hard-coded SOC 2-digit major group list in this folder (22 groups plus "00 All Occupations") and recodes SOC 11-9013 (farmers, ranchers and other agricultural managers) into group 45. Decide deliberately whether to copy that recode: it moves farm operators from Management into Farming, Fishing and Forestry, which changes the agriculture rate and would not match ACS SOC denominators unless applied to them too.
- `cancer-registry/bladder.sas`, `bladda.sas`, `lung.sas`: frequency of `textUsualOccupation` only.

## PHI and disclosure notes

No script contains names, dates of birth or copied record content in its text. The flags below are about what the scripts print or write when run.

- Record-level prints of death certificate data: `suicide.sas` (`proc print` of all 2013 suicide records and the first 10 rows of `mylib.suicides`, which carries names and dates from the NCHS file), `atv_coded.sas` (`proc print` of the whole NIOCCS-coded ATV file, and of `atv_final` with `DeathCertificateId`), `ATV.sas` (`proc print` of age and industry literal per record). Do not save SAS output or logs from these runs.
- Record-level exports: `lung.sas` writes `lungcancer.xlsx` with dates of birth, diagnosis and last contact; `lung_dataset.R` writes `lung_io_coded.csv`; `bladder.sas` prints up to 1,000 registry records; `pesticides.sas` exports the blue-green algae line list; `pesticides_dts 8.21.26.sas` keeps `caseNumber`; `training.sas` prints all records in `toxic`.
- External transmission: `bladder.R`, `lung_dataset.R` (and `nioccs_suicide.R`) send industry and occupation literals with a sequential row ID to the CDC NIOCCS web API. No direct identifiers go out, but check this is allowed under the data use agreements.
- `pcc_occupaitonal_ex_form_carbdiox.Rmd`: the narrative describes a single March 2024 workplace incident with a count of 6 people, and one person by age, sex and setting; it also renders a case-level exposure table into the HTML. Treat any rendered copy as restricted.
- `moving_averages.R` hard-codes statewide annual death counts, several below 6. Fine internally; apply the DHHS floor before publishing.
