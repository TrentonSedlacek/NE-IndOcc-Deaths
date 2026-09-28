# Verification of io_death_rates_v5.R

Written 2026-09-28 by an independent verifier. Script: `/home/user/NE-IndOcc-Deaths/scripts/io_death_rates_v5.R` (169 lines). While this check ran, another session committed `/home/user/NE-IndOcc-Deaths/scripts/io_death_rates_v6.R` (commit d79deec: v5 with `work_dir` as a plain setting, lines 17 to 19 replaced by one line), pointed `/home/user/NE-IndOcc-Deaths/tests/synthetic_run.R` at v6, and recorded a clean first real run of v6 in `/home/user/NE-IndOcc-Deaths/docs/v5-changes.md`. Every finding below applies to v6 too; the v6 line is the v5 line minus 2 from line 20 on.

**Verdict: SHIP** (as v6). No finding changes a number on the current real exports. Findings 1 to 4 should go into the next version (v7). No script was edited: nothing met the "clearly a bug, clearly correct one-line fix" bar, and v5 and v6 have both already been handed over, so CLAUDE.md's versioning rule means fixes belong in a new file.

CONFIRMED = reproduced in R 4.3.3 (dplyr 1.1.4, readr 2.1.5, readxl 1.4.3). PLAUSIBLE = follows from the code but needs real data or a real CDC reply. Throwaway scripts: `/tmp/claude-0/-home-user-NE-IndOcc-Deaths/696d3c6b-e08f-54f5-b70b-9a53a2b26ba7/scratchpad/` (harness.R, probe1.R to probe3.R, realistic.R, compare.R).

## Findings, most important first

**1. The test passes while sex-specific, occupation and 2020-2021 rates are wrong. MEDIUM, CONFIRMED.**
Mutation test: I ran `/home/user/NE-IndOcc-Deaths/tests/synthetic_run.R` against altered copies of v5. It still reported 0 failures when (a) M and F were swapped in the ACS denominators (line 119), (b) every occupation rate was doubled (line 140), or (c) the 2020-2021 cut used workers x 5 instead of x 2 (line 139). It only checks the rate of one row (suicide, industry, All workers, T). The real numbers are still right: on the realistic data below, v5's workers, rates and CIs equal v4's (written separately) in every row where the death counts agree, and the 2020-2021 worker-years are workers x 2.
Fix (test only): add three checks: sector 23 M workers equal the fake ACS "Male:!!Construction" estimate; occupation All workers T rate = deaths / (workers x 5) x 100,000; `recon$worker_years == 2 * recon$workers`.

**2. A column missing from one year's export is silent (line 31). MEDIUM, CONFIRMED.**
Failing input: the 2021 CSV without IndustryLit, OccupationLIt and D2SmicarAxis1-20. Death A1 (X42 with T40.4 on the entity axis only) came out overdose_opioid = FALSE and industry Not coded. There was no message, and all checks passed. If a column is missing from every year, lines 60, 70 or 74 stop with "object not found". If all 40 D2 columns are missing, `if_any()` over zero columns returns TRUE in dplyr 1.1.4 (confirmed), so every death becomes t40_any.
Fix: after line 30, `miss <- setdiff(keep, names(one)); if (length(miss)) message(yr, " export has no column: ", paste(miss, collapse = ", "))`.

**3. Dates parsed to the wrong century are not caught (lines 33 to 38). LOW on current data, CONFIRMED.**
Already listed as not fixed in `/home/user/NE-IndOcc-Deaths/docs/v5-changes.md` (item 11). A DOB of "03/14/10" becomes year 0010, so the child gets age 2011 and is counted as a 16+ suicide. A DOD of "03/14/21" (year 21) or "20210314" (read as serial 20210314, year 57233) is dropped without being counted in `unreadable_DateOfDeath`. The real exports use serials and 4-digit m/d/Y text, so the count is probably 0.
Fix: add `d[!is.na(d) & (d < as.Date("1850-01-01") | d > Sys.Date())] <- NA` before line 37 so these rows are counted in QA.

**4. Blank DateOfBirth and blank ResidingStateNchs are dropped without a count (line 51). LOW, CONFIRMED.**
Failing input: T4 (X70, DOB blank) and T5 (X70, residence blank) disappear. `unreadable_DateOfBirth` counts only non-blank text that fails to parse.
Fix: add `blank_DOB = sum(coalesce(deaths$DateOfBirth, "") == "")` and the same for residence to the print at line 155.

**5. The sums check (audit finding 13) is still close to always TRUE. LOW, CONFIRMED.** Only a row-multiplying NIOCCS join can make it fail, and line 92 prevents that. It passed with the D1, D2 and wrong-century inputs, and it does not check M + F <= T. v5-changes calls this item "Fixed"; "partly fixed" is more accurate. Fix: also stop if any group has M + F > T.

**6. A non-UTF-8 byte in the 2021 CSV stops the run (line 70, `tolower`). LOW, CONFIRMED on fake data.** One Windows-1252 "é" in ImmedCauseDeath gives "invalid input in 'utf8towcs'". The real v6 run read the same CSV cleanly, so current data does not trigger it. Fix, if a future export does: `read_csv(..., locale = locale(encoding = "windows-1252"))` at line 29.

**7. NAICS 928110 with occupation blank or 00-9900 goes to sector 92 (line 103). LOW, PLAUSIBLE.** In probe F7, the pair ("US ARMY", "") coded 928110 / 00-9900 gave industry 92. If CDC ever codes active-duty text this way, a soldier is counted against civilian workers. The notes show active duty coming back as 0096xx/0097xx. Fix: add `| (naics == "928110" & soc %in% c("", "00-9900"))` to `military`.

**8. An empty NIOCCS reply is cached for good (line 86). LOW, PLAUSIBLE.** `{"Industry":[],"Occupation":[]}` passes the `is.null(j$Industry)` test, so it is saved with blank codes and never re-sent. Fix: `length(j$Industry) == 0` in place of `is.null(j$Industry)`.

**9. `work_dir` detection (lines 17 to 19; replaced in v6). LOW, CONFIRMED.** It works with `source()` given an absolute or relative path, with `echo = TRUE`, with `local = TRUE`, and from inside a function. It stops with a clear message when the lines are sent to the console. With `source("sub/x.R", chdir = TRUE)` it sets work_dir to "sub", relative to the new folder, which is the wrong place. The RStudio Source button passes an absolute path, so it was fine. v6 makes this moot.

**10. Review-list noise (lines 69 to 71). LOW, CONFIRMED.** X64 suicides with manner blank or P and drug text (S1, S2) are listed as overdose candidates. "accidental overdose" with no drug named is not listed. "meth" also matches "methanol". No count is affected.

**11. pct_of_deaths is NaN (written "NaN") when an outcome has no deaths of one sex (line 142).** Small data only.

## Provenance (docs/provenance-audit-v4.md): what v5 copies and what is still its own

The source text was checked directly: dashboard capture line 18, MA txt lines 765 to 781, SUDORS txt lines 530 to 550.
- COPIED, correct: suicide is underlying X60-X84, Y87.0 or U03 (all U03.x), with no manner rule. SUDORS is underlying X40-X44 or Y10-Y14, text not counted. MA all-intent is X40-X49, X60-X69, X85-X90, Y10-Y19 or Y35.2, plus any of 40 fields starting T40.0-T40.4 or T40.6 (T40.5 cocaine excluded). Also: residence NE, age 16+, ACS C24030/C24010 civilian employed 16+, worker-years = workers x years, per 100,000.
- Labelled as "ours" in the header: the opioid subset on the SUDORS base, the exact Poisson CI, the ACS table choice, "retired", and the NIOCCS placeholder codes.
- Still v5's own choice but not labelled: latest export wins (the SAS keeps the earliest; this fixes a real error, but no source does it), age = trunc(days / 365.25) (the team R uses round; the SAS uses NchsAge), and sex U counted in T only. Suggest adding these three to the header.
- String ranges (`u3 >= "X60" & u3 <= "X84"`) give the same result as prefix matching for real codes. They also accept malformed codes such as "X6O" and "X8"; there is no source for either behaviour, and both are harmless.

## Readability for a SAS-only reader (v5 line numbers)
- 18: `sys.frames()` / `$ofile` (gone in v6).
- 62 and 70: `if_any(..., ~ ... .x ...)`. Plainer, like a SAS ARRAY loop: `t40_any <- FALSE; for (v in grep("^D2", names(deaths), value = TRUE)) t40_any <- t40_any | substr(nodot(deaths[[v]]), 1, 4) %in% t40`.
- 85: `j <- if (...) fromJSON(reply)` returns NULL without saying so. Plainer: `j <- NULL; if (...) j <- fromJSON(reply)`.
- 118 and 120: the regexes `sub(".*!!", ...)` and `sub("!![^!]*$", ...)` and `!label %in% parent`. The comment at 115 helps; an example label and its parent in the comment would help more.
- 131: `.data[[outcome]]`. Plainer: `d <- cases[cases[[outcome]] & cases$year %in% yrs, ]; d$group <- d[[group_var]]`.
- 151 and 153: `colSums(deaths[outcomes])` and the lookup `flagged[outcome]`.
- Silent filters: 31 (`any_of`, finding 2), 48 (year filter: out-of-range and wrong-century years uncounted), 51 (blank residence and blank DOB, finding 4), 92 (duplicate cache rows, harmless). Plainer: a SAS-log-style `message("after residence and age 16+: ", nrow(deaths))` after each filter.

## Checked and found correct
- Audit findings 1 and 2: fixed. D2 (R99 in 2021, then X42 + T40.4 in 2022) is counted once as an opioid overdose. D1 (moved across 31 December) is counted once, in 2021, and `year_moved` = 1.
- Finding 3: fixed. E1, M1, W1, S1 and S2 are not counted as overdoses. S2 is suicide and opioid_ma_def, which is right under MA.
- Finding 4: an unmapped leaf stops the run and names it (test).
- Finding 5: an HTML error page and a JSON reply with no Industry part are not saved and are re-sent next run.
- Findings 6 and 12: correctly documented as not fixed. A retired farmer is in sector 11 and an unemployed carpenter in 23 (design).
- Finding 7: fixed. 928110 with 13-2011 gives 92 / 13; SOC 55 and 0096xx/00-98xx give Military.
- Finding 8: no NchsAge route exists. On the 16th birthday the death is in; one day short it is out.
- Finding 9: fixed. Two blank-id suicides are both dropped and both counted.
- Finding 10: moot, since text is never counted.
- to_date: correct on "45291", "45291.0", "45291.75", "1/31/2021", "01/31/2021 00:00:00", "1/31/2021 12:00:00 AM" and "2021-01-31". Blank, NA, "unknown", "02/30/2021" and "31/01/2021" give NA.
- readxl with `col_types = "text"`: date cells come back as serial text, and a 12-digit numeric id comes back in full ("202100012345"), so it matches the CSV text id.
- Sex "M", "F", "1", "2" and "Male" map correctly; anything else is U, counted in T only. `read_csv` reads every column as text, so nothing is guessed. Readers turn blank cells into NA, and v5 uses `coalesce()` wherever it compares.
- Real cache: the column names and order match `IndustryLit, OccupationLIt, NAICSCode, SOCCode, raw`. `na = character()` keeps blank sides as "" so they join. v3 and v4 wrote codes with the same `parse_reply` that v4 re-ran on read, so using the stored codes changes nothing. v5 sends a pair only when it is not in the cache. Appended rows keep the column order.
- One caveat on the cache (PLAUSIBLE): v3 and v4 also ran `str_trim()`, which removes a leading or trailing non-breaking space. readr does not, so such a pair would be sent to CDC once more (allowed).
- Speed: 96,551 rows in 6 seconds.

## v4 versus v5 on the same realistic fake data (realistic.R, compare.R)
Input: 96,551 rows (96,498 ids plus 53 overlap copies). Eight overlap deaths were pending R99 in the earlier export, and three had the death date moved across 31 December. EventYear and NchsAge are 0. 2020 and 2022 to 2024 are xlsx with numeric serial cells and sex 1/2. 2021 is a CSV with m/d/Y text and sex M/F. The fake cache holds 26 pairs, one of them a cached error reply. The ACS is fake. v5 made 0 NIOCCS calls.

Workers are identical in all 600 shared rows. 196 rows differ in deaths, and every difference traces to an intended change:
- 46 R99 text-only overdoses are counted by v4 and not by v5 (decision B).
- 8 finalised deaths (6 overdoses, 2 suicides) are counted by v5 and lost by v4, which kept the pending copy (fix 1).
- 3 deaths whose date moved are counted twice by v4 and once by v5 (fix 2).
- 32 deaths with NAICS 928110 and a civilian SOC are Military in v4 and sector 92 / SOC 13 or 49 in v5 (fix 7).
- 59 deaths with INMATE or NOT EMPLOYED text and code 009990 are Not in workforce in v4 and Not coded in v5 (word list change).

Where the death counts agree, rates and CIs are identical. pct_of_deaths differs in 149 of those rows only because the sex totals changed. Rows only in v4: 16 sex U rows, the rr column, and pneumoconiosis and injury_at_work (intended drops). 2020-2021 cut, v4 to v5: Not in workforce 84 to 67, Not coded 32 to 49, sector 92 14 to 19, Military 12 to 7, All workers 402 to 407. My fake pool overweights the inmate and not-employed pairs; on the real data v6 left 84 unchanged.

No difference was a bug. The first version of my generator made birth dates before 1900 as negative serials. v5 accepts those and v4 rejects them. Real Excel cannot store such dates as serials, so the generator was fixed and those rows are not counted above.
