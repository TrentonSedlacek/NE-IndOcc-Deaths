# Simplicity review of io_death_rates_v4.R

Reviewed 2026-09-28. Script under review: `/home/user/NE-IndOcc-Deaths/scripts/io_death_rates_v4.R` (244 lines). On Trenton's machine that is `C:\Users\tsedlac\Downloads\io_death_rates_v4.R`.
Draft simpler version: `/home/user/NE-IndOcc-Deaths/scripts/drafts/io_death_rates_simple_sketch.R`.

## 1. Verdict

Yes, v4 is over-engineered. The problem is not length. 244 lines is short, and much shorter than the rejected 771-line first attempt (`/home/user/NE-IndOcc-Deaths/scripts/old/io_death_rates_v1_long.R`). The problem is density. v4 is built as a general rule engine plus defensive plumbing, and it packs this into one-liners that even an R user has to decode. Derry's own programs (`/home/user/ohis/OHIs/2019 ohi_death.sas`, 74 lines; `/home/user/dc-hdd-surveillance/programs/dc/dc_condition_surveillance.sas`, 172 lines) are straight-line code: one step per block, literal code lists, and nothing to decode.

Rough measures:

| | v4 | sketch | v1 (rejected) |
|---|---|---|---|
| Lines, total | 244 | 168 | 771 |
| Lines of code (no comments or blanks) | 195 | 132 | 497 |
| Characters | 19,781 | 13,190 | 46,702 |
| Functions defined | 18 | 3 | 24 |
| Reduce / do.call / sapply / lapply / as.matrix / tryCatch / modifyList | 14 | 0 | 9 |

Each candidate, with a verdict:

| Candidate | v4 lines | Verdict |
|---|---|---|
| Generic OUTCOMES table with seven rule columns (underlying, anymention, need_mention, text, text_needs, not_manner, field_rule) | 28-46, 86-113 | **Over-engineered.** It takes about 45 lines to support "add a row to add an indicator". To make it work it needs an ICD range parser (`expand`, 87-89), a 40-column matrix (92), `do.call(paste, ...)` (93), two `Reduce` helpers (94-95), a manner parser (97), a field-rule parser that splits "Field=Value" strings (107), and a loop that builds each flag from seven switches (99-111). The same four definitions written as plain IF-style lines take about 17 lines, and a SAS reader can check each one against the case definition. |
| Text-based overdose rule | 36, 40-41, 46, 102-105 | **Keep, but inline.** The SUDORS definition requires it, and 68 of the 16+ overdoses in 2021-2022 come only from cause text. What is over-engineered is spreading one rule across four columns and a global variable. In the sketch it is two lines. |
| Six outcomes instead of two | 39-44 | **Partly over-engineered.** The analysis plan (`/home/user/NE-IndOcc-Deaths/docs/analysis-plan.md` section 3 step 2) asks for suicide, overdose, the opioid subset, and the Massachusetts all-intent opioid total. Pneumoconiosis (43) and injury at work (44) are not in the plan, and they add 4 of the 12 output tables. The sketch keeps four outcomes and drops those two. |
| ACS leaf-detection logic | 187 (plus the leaf filter in 189) | **Redundant.** The inner join to `acs_group_map.csv` on line 189 already keeps only leaf rows, because no subtotal label ("Service occupations", "Agriculture, forestry, fishing and hunting, and mining") appears in the map. The total check on line 191 would catch any slip. Line 187 is an O(n squared) `sapply` that does nothing the join does not already do. |
| Raw-JSON cache re-parse | 118-133 | **Redundant now.** It was added so that rows saved by an older parser could be fixed. But `nioccs_cache_v3.csv` was created by v3, and v3 and v4 have the same `parse_reply` (git diff v3 to v4 shows no change there). So every stored code already equals its re-parsed code. The hand unwrapping in lines 124-125 is also unnecessary: with `fromJSON`'s default simplification, `j$Industry$NAICSCode[1]` works whether CDC sends an object or a one-element array. |
| `here` / `test_cfg` plumbing | 15, 25, 161-162 | **Over-engineered for the user.** `sys.frame(1)$ofile` exists only to find the script's own folder, `getOption("io_death_rates.test_cfg")` only lets the synthetic test inject paths, and 161-162 search two places for the map. A SAS programmer expects `%let` paths at the top, and the sketch uses exactly that. The cost: `/home/user/NE-IndOcc-Deaths/tests/synthetic_run.R` cannot drive the sketch without its own copy (see section 4). |
| Date parser with four formats | 60-69 | **Half redundant.** `as.Date` ignores trailing text, so `"%m/%d/%Y"` already reads "1/31/2021 14:05" and `"%Y-%m-%d"` already reads "2021-01-31 14:05:00". The two formats with a time part never catch anything the first two missed. The sketch keeps the serial-number branch plus two text formats, as three plain lines. |

Other over-engineering the review found:

- **Line 76, the age auto-switch.** It uses NchsAge if more than half of all rows have NchsAge 16 or more, and DateOfBirth otherwise. NchsAge is 0 on every real row (`/home/user/NE-IndOcc-Deaths/docs/death-cert-data-notes.md`, "Facts learned from the first real runs"), so on real data this always takes the DateOfBirth branch. The NchsAge branch exists only because the synthetic test data still carries NchsAge and no DateOfBirth.
- **Line 73, the EventYear fallback.** EventYear is 0 on every real row, so the fallback can never supply a year in 2020-2024. It is dead code on real data, kept for the same test-data reason.
- **Line 71, `str_trim` on every column.** `read_csv` and `read_excel` already trim whitespace by default.
- **Line 57, the loop that fills missing columns.** `select(any_of(...))` plus `bind_rows` does the same thing.
- **Lines 23, 136 and 150, the `run_nioccs` switch.** NIOCCS use is approved (CLAUDE.md), so the switch only adds a way to get a silently incomplete run.
- **Lines 138-149, NIOCCS diagnostics.** `try()`, a first-call message, a first-reply dump, a success counter and progress messages add about 8 lines to a loop the team's own `GET.R` writes in about 6.
- **Lines 193-194.** A `{ bind_rows(., group_by(., sex) ...) }` pipe trick builds the All workers rows.
- **Lines 200-215, `rate_table`.** It counts four separate ways (by group and sex, by group, All workers by sex, All workers total), where one "OUTPUT twice" step (each death counted once under its sex and once under T) does the same.
- **Lines 222-231.** QA is built as a nested list with `sapply` closures.

Things in v4 that are **not** over-engineering and must stay: the SUDORS text rule, the per-pair NIOCCS cache that saves each reply as it arrives, the NIOCCS special codes for military and not in workforce (they fixed about 20 military suicides that v3 left in Not coded), the exact Poisson CI, the check that ACS groups add up to the table total, and the 2020-2021 NEVDRS cut.

## 2. Simplest design that still meets the requirements

**Recommendation: one R script, written in SAS style.** That means straight-line blocks named after the SAS step they replace, literal code lists, plain `dplyr` verbs, `%let`-style settings at the top, and no helper functions beyond three small ones (date reading, dot removal, the rate table).

Why R and not SAS, given that Derry reads SAS:

| | One R script (recommended) | One SAS program | SAS plus a small R helper |
|---|---|---|---|
| Files Derry has to run | 1 | 1 | 2, plus a hand-off file between them. Derry has said he is against two scripts. |
| NIOCCS call | Same `httr::GET` as the team's `/home/user/NE-IndOcc-Deaths/team-archive/io-coding/nioccs/CDC NIOCCS web service i_o GET.R` (team precedent) | `PROC HTTP` in a macro loop plus `LIBNAME JSON`. There is no team precedent (no `PROC HTTP` anywhere in `/home/user/dc-hdd-surveillance`, `/home/user/ohis` or the team archive). Free text containing `&`, `%`, commas or quotes has to be macro-quoted and URL-encoded, which is where this kind of code breaks. | R does the call, as the team already does. |
| Reading the exports | Reads the .csv and the .xlsx directly, so the dates and serials are handled in one place | Cannot read the Guardian .xlsx (floating point overflow; see `/home/user/NE-IndOcc-Deaths/docs/death-cert-data-notes.md`), so each year has to be saved as CSV by hand first. PROC IMPORT then guesses types per file, so a serial-number year and a text-date year need different code. | Same as SAS |
| ACS | `tidycensus`, pulled once and saved | Hand download from data.census.gov, then a mapping step | Either |
| Readability for Derry | He has to learn to read `mutate`, `filter`, `group_by`, `count`. The comments name the SAS equivalent of each block. | Best | He reads the SAS part and has to trust the R part |
| Estimated size | about 130 lines of code | about 180-220 lines, including the PROC HTTP macro | about 150 SAS lines plus about 25 R lines |

A SAS-only version is possible and would be the most familiar to Derry. It is not the simplest, though. It adds a manual xlsx-to-CSV step, per-year import handling, and a macro-driven web call that nobody on the team has written before. For illustration only (untested, and the dataset names that the JSON engine creates depend on the reply shape), the NIOCCS part would look roughly like this:

```sas
%macro nioccs(ind, occ);
  filename resp temp;
  proc http method="GET" out=resp
    url="https://wwwn.cdc.gov/nioccs/IOCode?i=%sysfunc(urlencode(%superq(ind)))%nrstr(&)o=%sysfunc(urlencode(%superq(occ)))%nrstr(&)c=2";
  run;
  libname nio json fileref=resp;
  data one; merge nio.industry(keep=NAICSCode) nio.occupation(keep=SOCCode); run;
  proc append base=cache data=one force; run;
%mend;
data _null_; set todo; call execute(cats('%nioccs(%nrstr(', IndustryLit, '),%nrstr(', OccupationLIt, '))')); run;
```

An industry text such as "FARMING, RANCHING" breaks the macro call unless it is quoted further. That fragility is the main reason not to go this route.

**The trade-off, stated plainly:** one R script means Derry reads R, but only one file to run and one place where every number comes from. SAS plus an R helper lets Derry read the part he cares about in SAS, but it is two programs and a hand-off file, which he has already said no to. SAS alone is familiar but longer, and it puts new, fragile web-service code in SAS. The sketch aims to make the one-R-script option as readable to a SAS programmer as R can be.

## 3. The sketch

File: `/home/user/NE-IndOcc-Deaths/scripts/drafts/io_death_rates_simple_sketch.R` (168 lines total: 132 lines of code, the rest comments and blanks).

Blocks, each named for its SAS counterpart:

1. Settings, like `%let`. Paths are fixed: `K:/Occupational Health Grant/data/dc` and `C:/Users/tsedlac/Downloads`, with `Output` and `Cache` under it.
2. PROC IMPORT each year (.csv, or .xlsx if there is no .csv), then SET them together.
3. DATA deaths. Year and age come from DateOfDeath and DateOfBirth. PROC SORT NODUPKEY by id and year. Keep NE residents aged 16+.
4. DATA deaths, flags. The ICD ranges are written the way the legacy SAS writes them: `u3 >= "X60" & u3 <= "X84"`. The opioid T codes are a literal list, and the 40-field ARRAY scan is a single `if_any`.
5. NIOCCS. One GET per uncached text pair, the same call as the team's GET.R, appended to the same `nioccs_cache_v3.csv`.
6. DATA cases. Codes are rolled to the 20 sectors and 22 SOC groups plus Military, Not in workforce and Not coded, like a PROC FORMAT.
7. ACS C24030 and C24010. Pulled once and saved, joined to `acs_group_map.csv`, and checked against the published totals.
8. Rates. One `rate_table` gives deaths, percent of deaths, workers, worker-years (workers x 5), rate per 100,000, exact Poisson 95% CI and rate ratio to all workers, by sex and total. It runs for 4 outcomes x 2 tables, plus the 2020-2021 NEVDRS cut.
9. Printed checks (counts by year, group rows vs case totals, non-rate rows, NEVDRS cells), then the output files.

**Check that it gives v4's numbers.** Both scripts were run in the scratch area on the same fake data. The data came from the generator in `/home/user/NE-IndOcc-Deaths/tests/synthetic_run.R`, changed to look like the real exports:

- EventYear and NchsAge are 0 on every row.
- Dates are Excel serials stored as text in 2020, "m/d/Y 14:05" in 2021, ISO in 2022, "m/d/Y" in 2023, and real Excel dates in the 2024 .xlsx.
- The NIOCCS cache has codes stored.

Results:

- Output tables: all 638 rows (4 outcomes x industry and occupation x sexes) identical.
- 2020-2021 NEVDRS cut: identical.
- Deaths (107) and cases (84): identical.

The sketch has not been run on real K: data. Before Trenton runs it, it must be renamed under the versioning rule, for example `C:\Users\tsedlac\Downloads\io_death_rates_v5.R`. It has to sit next to `C:\Users\tsedlac\Downloads\acs_group_map.csv`, and it reuses `C:\Users\tsedlac\Downloads\Cache\nioccs_cache_v3.csv` and `C:\Users\tsedlac\Downloads\Cache\acs_2024.csv` if v4 was run from Downloads.

## 4. What the sketch drops or changes versus v4, and whether a number can move

| # | Change | v4 lines | Can it change a number? |
|---|---|---|---|
| 1 | Pneumoconiosis and injury_at_work outcomes dropped (not in the analysis plan) | 43-44 | No for the remaining outcomes. Their 4 tables are gone. Fewer text pairs go to NIOCCS. |
| 2 | OUTCOMES table and generic loop replaced by literal flag lines | 28-46, 86-113 | No. Identical flags on the test data. |
| 3 | ICD ranges as string comparisons (`u3 >= "X60" & u3 <= "X84"`) instead of `expand()` into prefix lists | 87-89, 101 | No, for any real ICD-10 code (the third character is a digit). |
| 4 | Date parser cut from four text formats to two, and the serial range guard (1 to 80,000) dropped | 60-69 | No. `as.Date` already ignores a trailing time. A value below 1 or above 80,000 is not a real date in either script. |
| 5 | Age always from DateOfBirth; the NchsAge auto-switch dropped | 75-76 | No on the real exports (NchsAge is 0 on every row, so v4 already uses DateOfBirth). It would matter only if a future export had real NchsAge and blank DateOfBirth. |
| 6 | Year only from DateOfDeath; EventYear fallback dropped | 73 | No on the real exports (EventYear is 0 on every row). |
| 7 | `str_trim` on every column dropped | 71 | No. Both readers trim by default. |
| 8 | Missing-column filler replaced by `any_of` | 57 | No. |
| 9 | `here` and `test_cfg` plumbing replaced by fixed paths at the top | 15, 25, 161-162 | No. But the synthetic test cannot run the sketch without its own version. Its data also predates the real-export facts (it has NchsAge and EventYear but no DateOfBirth), which is the source of items 5 and 6. A test for the sketch should generate real-looking dates, as the scratch check above did. The existing test was not modified. |
| 10 | `run_nioccs` switch dropped (NIOCCS is approved) | 23, 136, 150 | No. |
| 11 | Raw-JSON re-parse dropped; the codes stored in the cache are used as they are. The raw reply is still saved in the cache. | 118-133 | No, because the cache was only ever written by v3 and v4 with the same parser. One-time check if in doubt: in `C:\Users\tsedlac\Downloads\Cache\nioccs_cache_v3.csv`, no row should have a blank NAICSCode while its raw column contains `"NAICSCode":"` followed by digits. v4 also dropped and re-sent cache rows with an empty raw reply, and the sketch keeps them. That could matter only if such rows exist. |
| 12 | NIOCCS reply read with `c(j$Industry$NAICSCode, "")[1]` instead of the hand-written unwrapping | 121-127 | No. Same codes for both reply shapes. |
| 13 | `try()` around GET removed | 140-141 | No. A network error now stops the run instead of skipping the pair. Nothing is lost because each reply is saved as it arrives; rerun to resume. A reply that is not JSON now stops the run instead of being cached with blank codes. That is safer, since v4 would have filed the pair under Not coded for good. |
| 14 | NIOCCS progress and diagnostic messages dropped | 137-149 | No. |
| 15 | ACS leaf detection dropped; the join to the map does the filtering | 187, 189 | No. Identical denominators on a fake ACS file with the full subtotal hierarchy. The total check is kept (stops if off by more than 0.5 percent). |
| 16 | `rate_table` rewritten with "each death counted under its sex and under T" | 200-215 | No. Identical rates, CIs, rate ratios and percents on the test data. |
| 17 | New `table` column (C24030 or C24010) in the output | 214 | No. It fixes an ambiguity: industry "23" and SOC "23" were indistinguishable in v4's single CSV. |
| 18 | Output file names get `_simple_` so they do not overwrite v4's | 235, 239, 243 | No. |
| 19 | QA list, `qa_*.txt` file and per-outcome `_text_only` columns replaced by printed checks. One overdose_text_only count per year is kept. The group-sum check is printed side by side instead of raising a warning. | 110, 222-233, 241 | No. It changes what is printed, not what is computed. A text-only count for overdose_opioid can be added back in one line if wanted. |
| 20 | Only suicide, overdose and MA-opioid cases are sent to NIOCCS | 112 | No. |

Not done by v4 or the sketch, and still open in the plan: the certificate-code cross-check (in `/home/user/NE-IndOcc-Deaths/scripts/io_death_rates_extras_v3.R`), the manual review list, and a CI on the rate ratio. The sketch has no suppression anywhere.
