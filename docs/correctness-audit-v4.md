# Correctness audit: io_death_rates_v4.R

Audited 2026-09-28. Script: /home/user/NE-IndOcc-Deaths/scripts/io_death_rates_v4.R (on Trenton's machine C:\Users\tsedlac\Downloads\io_death_rates_v4.R, next to C:\Users\tsedlac\Downloads\acs_group_map.csv). Nothing in the script or the test was edited.

How it was tested: tests/synthetic_run.R passes (0 failures). A separate throwaway harness wrote crafted Guardian-shaped CSVs for 2020 to 2024 (DOB-based age as in the real data, NchsAge = 0, EventYear = 0), a fake NIOCCS cache with crafted replies, and the test's fake ACS, then ran the real v4 script with `run_nioccs = FALSE`. Each finding says what that run printed. No network was used.

CONFIRMED = reproduced in R. PLAUSIBLE = follows from the code but needs the real data or a real NIOCCS/Census reply to size it.

## Findings, most damaging first

### 1. Dedup keeps the EARLIEST export, so a pending-cause copy beats the final one (line 80). CONFIRMED
- Input: id D2, 2021 export `AcmeUnderlyingCode = R99, MannerDeath = P`; 2022 export same id, same DateOfDeath, `X42, A, "acute fentanyl toxicity", T40.4`.
- Result: one row kept, the R99 one; overdose = FALSE, overdose_opioid = FALSE.
- Effect: late-registered deaths are the ones waiting on toxicology or investigation, i.e. disproportionately overdoses and suicides. Of the ~53 overlap deaths, every one whose cause was finalised after the first export is lost from the numerators (and its I/O text may also be the preliminary one).
- Fix: in read_year add `src = yr`; then `arrange(desc(src)) %>% distinct(DeathCertificateId, .keep_all = TRUE)` BEFORE the year filter, so the latest export wins.

### 2. Dedup key includes the death year, so a corrected DateOfDeath double counts (line 80). CONFIRMED
- Input: id D1 in the 2020 export with DateOfDeath 12/31/2020, in the 2021 export with 01/01/2021, both X42 + T40.4.
- Result: two rows, year 2020 and year 2021; counted as two overdoses and two opioid overdoses.
- Effect: +1 death per certificate whose death date moved across a year boundary between exports. `distinct(DeathCertificateId, year)` only ever collapses copies that agree on the year, so it is strictly weaker than `distinct(DeathCertificateId)`.
- Fix: same as 1 (dedup on DeathCertificateId alone, latest export wins). Add a QA count of ids whose year differs between exports.

### 3. Overdose text rule counts non-overdose deaths (lines 36, 93, 102 to 105). CONFIRMED
The text regex and the drug word are searched across all five cause fields pasted together, and the only guard is manner. All of these came out overdose = TRUE and overdose_text_only = TRUE:
- E1: underlying X45 (alcohol), ImmedCause "acute ethanol intoxication", OtherSignificantConditions "history of drug abuse". "intoxication" and "drug" come from different fields.
- M1: underlying V89.2 (motor vehicle), OtherSignificantConditions "acute methamphetamine intoxication". A crash with a drug on board.
- W1: underlying W19 (fall), "fentanyl intoxication" as a contributing condition; also counted in overdose_opioid.
- S1: underlying X64 (suicide by drug), MannerDeath blank, "intentional overdose of oxycodone". S2: X64, manner P, "oxycodone toxicity", T40.2: counted as overdose AND overdose_opioid AND suicide.
- Effect: inflates the SUDORS-definition overdose count. The real run already has 68 text-only cases aged 16+ and a 2021-2022 total (399) above published SUDORS (366); this rule is the likely source of much of the gap. SUDORS counts unintentional and undetermined only, so S1/S2 must not count, and a death whose underlying cause is a crash, fall, or alcohol poisoning is not a drug overdose death.
- Fix: accept a text-only hit only when the underlying cause is uninformative: `& (under == "" | starts_any(under, c("R99", "R98", "R96")))`.

### 4. ACS: an unmapped leaf smaller than 0.5% of the total is silently dropped (lines 189 to 191). CONFIRMED
- Input: fake ACS where the Mining leaf label reads "...extraction industries" (not in acs_group_map.csv), 2,400 workers per sex, total adjusted.
- Result: the script ran with no error; sector 21 has deaths = 1 but workers = NA, rate = NA; that death stays in the All workers numerator while its workers left the All workers denominator. sums_ok = TRUE.
- Effect: 0.5% of 1,024,674 is 5,123 workers. Any of Mining, Utilities, Legal, Management of companies, or a single-sex leaf in Nebraska could fall under that and vanish with no warning. The v3-era audit says the script "stops on any unmapped leaf"; v4 no longer does.
- Fix: after line 189, `miss <- setdiff(acs$leaf_name[acs$table == tab & acs$is_leaf & acs$sex != "T"], acs_map$leaf_name[acs_map$table == tab]); if (length(miss)) stop(tab, " leaves not in map: ", paste(miss, collapse = "; "))`.

### 5. A NIOCCS HTTP 200 with an error body is cached forever as Not coded, and QA calls it coded (lines 141 to 146, 132 to 133, 229). CONFIRMED
- Input: cache row (AMAZON, PICKER) with raw `{"Message":"An error has occurred."}`.
- Result: NAICSCode and SOCCode blank, ind_group and occ_group = Not coded; `text_pairs_not_coded` = 0. Because the row has a non-empty raw it passes `filter(raw != "")` and anti_join keeps the pair out of `todo`, so it is never re-sent.
- Effect: every pair that hit a transient CDC error inflates Not coded and removes that death from its sector and from All workers, permanently, while the QA line says nothing is left to code.
- Fix: in the loop, `if (!grepl('"Industry"|"Occupation"', raw)) next` before writing the cache; and at line 133 filter to rows whose raw contains "Industry" or "Occupation".

### 6. Numerator and denominator are different populations (lines 83, 165 to 171, 188 to 195). PLAUSIBLE (design)
- Numerator: every resident decedent 16+ whose usual industry or occupation codes to a sector, including an 85-year-old retired farmer ("FARM", "RETIRED FARMER" gets sector 11) and an unemployed carpenter ("CONSTRUCTION", "UNEMPLOYED CARPENTER" keeps 23 because a NIOCCS sector beats the non-worker text at line 170). Denominator: civilians currently employed.
- Massachusetts (extracted-text/external/massachusetts/...2018-2020.txt, lines 773 to 781): residents 16+, excluded homemakers, unemployed, never employed, disabled and students, and excluded deaths without codable I/O; retirees are not named as excluded. So the retiree part matches MA; keeping the unemployed with a sector does not. CDC NVDRS I/O papers restrict to 16 to 64.
- Effect: all rates are biased up by the share of coded decedents who were not working, and unevenly: sectors with old decedents and few old workers (agriculture, manufacturing, railroads) are inflated most, which distorts the rate ratios, not just the level. Not coded deaths (10%+ in the fake run) bias all rates down. Neither is visible in the table.
- Fix: add an `age_band` (16 to 64, 65+) to cases and write a 16 to 64 version of each table beside the 16+ one; send "unemployed" text to Not in workforce before the sector test, as MA did.

### 7. NAICS 928110 marks DoD civilians as Military in both tables (line 168). CONFIRMED
- Input: ("US ARMY", "CIVILIAN ACCOUNTANT") with reply NAICS 928110, SOC 13-2011.
- Result: ind_group = Military, occ_group = Military.
- Effect: ACS counts DoD civilians in Public administration and in their occupation group (13 here), so sector 92 and those SOC groups lose numerator deaths but keep the workers: rates understated.
- Fix: `military = socgrp == "55" | str_detect(nc, "^009[67]") | str_detect(sc, "^00-98") | (startsWith(nc, "928110") & sc %in% c("", "00-9900"))`.

### 8. Age: the real path is untested and the other branch is wrong (line 76; tests/synthetic_run.R lines 87 to 88). CONFIRMED
- The real data uses `age_dob` (NchsAge is 0 everywhere). The synthetic test never sets DateOfBirth, so it only exercises the NchsAge branch, which the real data never takes.
- In that branch: P04 (NchsAge 999, unknown) is kept with age 999, although its comment says "out"; P03 (200 months) gets age 0 and is dropped, although its comment says "in". Neither is checked.
- The branch is picked once for the whole file by `mean(age_nchs >= 16) > 0.5`. If a later export fills NchsAge and that tips the mean, every row with NchsAge 0 becomes age 0 and is dropped. If NchsAge is missing on every row, `mean` is NaN and the script stops ("missing value where TRUE/FALSE needed", reproduced).
- Fix: `age = coalesce(age_dob, ifelse(NchsAgeUnit == "1" & age_nchs > 0 & age_nchs < 999, age_nchs, NA))`; set DateOfBirth in the synthetic rows and check P03/P04.

### 9. Blank DeathCertificateId rows collapse into one (line 80). CONFIRMED
- Input: two different suicides in 2022, both with a blank id (read as NA).
- Result: one kept ("NA-id rows kept: 1 of 2").
- Effect: every blank-id death after the first in a year is lost. Size unknown; probably 0 on real data, but nothing reports it.
- Fix: dedup only rows with an id: `bind_rows(filter(d, is.na(DeathCertificateId)), filter(d, !is.na(DeathCertificateId)) %>% distinct(...))`, and print the NA-id count.

### 10. Overdose text rule misses clear overdoses (lines 36, 103). CONFIRMED
- R99 with manner A and "accidental overdose", "acetaminophen toxicity", or "xylazine and meth toxicity": all overdose = FALSE. "overdose" alone never qualifies, and the drug list lacks acetaminophen, benzodiazepines, alprazolam, xylazine, carfentanil, morphine, hydrocodone, tramadol, gabapentin, "meth".
- Effect: undercounts text-only overdoses (partly offsets finding 3; the two errors do not cancel case by case).
- Fix: let "overdose" stand alone (`text_needs` applies only to toxicity|intoxication|poisoning), and extend drug_words; review the resulting list with finding 3's underlying-cause guard in place.

### 11. Dates that fail to parse are dropped with no count, and some parse wrongly (lines 61 to 73, 79). CONFIRMED
- "2021" (year-only DOD) becomes serial 2021 = 1905-07-13, year 1905, dropped. "03/14/21" parses as year 0021: as a DOD the death is dropped; as a DOB ("03/14/10") a child gets age about 2012 and enters the 16+ numerator. "20210314" and "14/03/2021" give NA; with EventYear 0 the year becomes 0 and the row is dropped. The message at line 84 does not report any of these.
- Effect: none if the real exports only hold serials and mm/dd/yyyy text (as the notes say), but nothing would show it if one did not.
- Fix: after to_date, `out[out < as.Date("1850-01-01")] <- NA`, and message the number of rows with NA dod and NA dob before the year filter.

### 12. 2020-2021 cut uses the 2020-2024 ACS x 2 (lines 208, 237). PLAUSIBLE
- The 5-year estimate is a 2020-2024 period average; Nebraska employment in 2020-2021 (pandemic) was below that average, so the recon rates are understated by roughly the size of that gap (a few percent). Counts, the thing being reconciled with NEVDRS, are unaffected.
- Fix: for yrs = 2020:2021 use the ACS 5-year 2021 (2017-2021) table, or label the recon rate as approximate.

### 13. sums_ok can never fail and does not look at M/F (lines 222 to 223). CONFIRMED
- The T rows are `count(group)` of the same `cs` that `sum(cases[[o]])` counts, so they are equal by construction. It stayed TRUE in the runs with the double-counted D1, the lost D2, and the dropped mining denominator.
- Fix: compare against `sum(deaths[[o]])` (before the NIOCCS join), and check M + F + U = T per group.

### 14. Smaller items
- Line 168 to 171, CONFIRMED: a non-worker word in the text never beats a NIOCCS sector (("SCHOOL", "STUDENT") with reply 611110 / 00-9100 gives industry 61, occupation Not in workforce). Harmless if NIOCCS always returns 009890 for students, as the real cache suggests; otherwise students inflate sector 61.
- Lines 90 to 95, PLAUSIBLE: entity-axis codes stored with a line/position prefix ("11T401", the NCHS AXISCD layout) never match startsWith. A T40.1 only on D2SmicarAxis1 as "11T401" gave overdose_opioid = FALSE. Harmless while the record axis (D2Acme) carries the same code. Fix: strip `^\\d{2}` in clean() for the SmicarAxis columns.
- Line 126, CONFIRMED: a reply with numeric codes loses leading zeros (9680 not 009680, so military is missed); a reply that is a bare JSON string stops the script ("$ operator is invalid for atomic vectors"). Fix: `formatC(as.integer(x), width = 6, flag = "0")` when a NAICS code arrives as a number, and return blanks unless `is.list(j)`.
- Line 89, CONFIRMED: expand() leaves a dotted range such as "T40.0-T40.4" unexpanded, so a future OUTCOMES row written that way matches nothing. Fix: call clean() on each token before str_match.
- Line 104, CONFIRMED: "carbon monoxide" anywhere in the five fields excludes a real drug overdose ("fentanyl toxicity" plus "carbon monoxide exposure" as another condition). Rare; acceptable if listed on the review sheet.
- Line 212, definitional: pct_of_deaths divides by all cases including Military, Not in workforce and Not coded, so sector percents do not sum to 100 across sectors. Name the column pct_of_all_16plus_cases.
- Lines 63 and 74, PLAUSIBLE: fractional serials (45291.75) are kept as fractional Dates; a DOB with a later time of day than the DOD would give 15 on a 16th birthday. Fix: `floor(n)`.
- Line 54, PLAUSIBLE: if the 2021 CSV was saved by Excel, long ids can be written as 1.23457E+11 and distinct() would merge different deaths. Check `n_distinct(DeathCertificateId)` against rows in that file.
- Line 81, PLAUSIBLE: rows with blank ResidingStateNchs are dropped as non-residents without a count. Print that count.

## Checked and found correct
- Age at the 16 cutoff: trunc(days / 365.25) agrees with true birthday arithmetic on 9,498 DOB/DOD pairs, including every 16th birthday and the day before in 2020-2024 (a 16-year span always holds exactly 4 leap days). In the harness, died the day before the 16th birthday: out; on the birthday: in. It is off by one at some other birthdays (17th), which the script never uses.
- to_date: "45291", "45291.0", "45291.75", "03/14/2021", "3/4/2021", "2021-03-14", "03/14/2021 13:45", "2021-03-14 00:00:00", "2021-03-14T00:00:00" all correct; blank and NA give NA; an all-NA column works.
- Filter order (year, dedup, residence, age) is fine once the dedup key is fixed; lowercase "ne" is accepted.
- ICD: expand() gives X60..X84, X40..X49, X60..X69, X85..X90, Y10..Y19 plus Y352 correctly. clean() handles "Y87.0", "y870", spaces. U03 matches U03.0 to U03.9 (all intentional terrorism, correctly suicide); "UO3" is rejected. No prefix in any list is a prefix of a code from another category. The T40 any-mention across D2Acme and D2SmicarAxis is a logical OR per record, so no double counting.
- not_manner uses the first letter, so "S", "Suicide", "H", "Homicide", "N", "Natural" all work; "C", "P", blank and "U" are allowed through (right for SUDORS undetermined, but see finding 3 for blank and P).
- opioid_ma_def matches the MA report's stated definition word for word (MA text lines 766 to 770): underlying X40-X49, X60-X69, X85-X90, Y35.2, Y10-Y19 with T40.0-T40.4 or T40.6.
- sector_of: "31-33", "44-45", "48-49", "493", "23", "42" map correctly; 1-digit, "00", "99" and placeholder codes fall to Not coded. Military placeholders (0096xx, 0097xx, 00-98xx), not-in-workforce (009890, 00-90xx, 00-91xx) and insufficient information (009990, 00-9900) route as documented.
- NIOCCS cache: `na = character()` keeps blank sides as "" so blank-side pairs join; `distinct()` after bind_rows is safe because anti_join means a pair is never fetched twice; `filter(raw != "")` only drops pre-v3 rows, which are then re-sent; trimmed text is used for both the cache key and the join.
- ACS: is_leaf is structural and correct with or without trailing colons; "!!Male" never matches "!!Female"; the Total row is sex T and excluded; leaf names match the map in the synthetic tables and the 2019-onward label set as recalled (73 and 55 variables). Real labels are still unverified against api.census.gov.
- Rates: Garwood exact limits (qchisq(0.025, 2d)/2 and qchisq(0.975, 2d+2)/2, 0 at d = 0); rr divides by the single All workers row in each sex; sex U deaths enter only T rows and have no rate; worker-years = 5-year estimate x 5 matches docs/acs-denominator-spec.md.
- Output: /Output gets group-level tables only; the case list and QA go to /Cache. No suppression anywhere, as required.
