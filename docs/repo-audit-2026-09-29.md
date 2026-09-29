# Repository audit, 2026-09-29

Scope: CLAUDE.md, README.md, everything in docs/ (including docs/web-captures/ and docs/meetings/), scripts/ (io_death_rates.R, v3 to v9, extras_v3, acs_group_map.csv, drafts/, old/), tests/, team-archive/README.md and the per-folder READMEs, team-archive/analyses/suicide/outputs/, source-docs/INVENTORY.md. Nothing in scripts/ or tests/ was edited. Line numbers are for the file as it was before this audit's edits unless marked "now". Every edit made is listed at the end.

Numbers checked against data files: the three-way comparison tables were recomputed from /home/user/NE-IndOcc-Deaths/team-archive/analyses/suicide/outputs/ind_suicide_fte_year_long.csv and occ_suicide_fte_year_long.csv. All match: 2020-2021 all 20 sectors sum to 440; construction 65 (43.8), manufacturing 59 (25.7), agriculture 41 (41.2); 2020-2023 construction 133 (43.6); construction trades 2020-2023 mean 59.7.

## 1. Factual contradictions (most important first)

1.1 NEVDRS counts misassigned to sectors. docs/analysis-plan.md line 49: "compare the construction, manufacturing and not-in-workforce counts with 84, 72, 55". The sheet is construction 72, manufacturing 55, not in workforce 84: docs/nevdrs-sectors-factsheet-review.md lines 11 to 13, and scripts/io_death_rates_v8.R lines 350 to 352 (`"Not in workforce" ~ 84`, `"23" ~ 72`, `"31-33" ~ 55`). Fixed.

1.2 NEVDRS yearly suicide totals swapped. docs/analysis-plan.md line 64: "2020: about 289, 2021: about 305, 2022: about 284"; source-docs/INVENTORY.md line 82: "2020: 289, 2021: 305, 2022: 284". The fact sheets say 2021 = 284 and 2022 = 305: extracted-text/ne-dhhs/factsheets/suicide/2021-Nebraska-Suicide-Factsheet.txt line 64 "284 Total Deaths"; 2022-Nebraska-Suicide-Factsheet.txt line 53 "305 Total Deaths"; INVENTORY.md lines 35 and 39 agree with the sheets. The dashboard text extraction (Dashboard1.txt lines 10 to 11, "289 305 / 284") has no year order. Fixed in both files.

1.3 How the earlier table divides deaths by FTE. docs/project-brief.md line 55: "both mix ten years of deaths with one year of FTE". Only nioccs_suicide.R does that. suicide_agg.R reads one FTE file per year (team-archive/analyses/suicide/suicide_agg.R lines 11 to 20) and divides year by year; docs/provenance-comparison.md lines 66 to 67 say so. Fixed.

1.4 FTE outputs on hand. docs/project-brief.md line 53: "Outputs exist for NAICS 2-digit 2020 to 2023". The archive holds NAICS 2-digit files for 2013 to 2023 (team-archive/denominators/acs-pums-fte/industry/outputs/fte5y_ne_naics2_2013.csv to fte_ne_naics2_5y_2023.csv), and team-archive/README.md line 7 says "2013 to 2023". Fixed.

1.5 What AGEUNITS means. docs/provenance-comparison.md line 57: "AGEUNITS >= 16 (probably the age-unit code, not age)"; line 100: "16+ (wrong variable)"; team-archive/io-coding/nioccs/README.md line 52: "may not do what was intended". scripts/io_death_rates_v8.R line 96 reads AGEUNITS as the age and AGETYPE as its unit, and v9 reproduces the earlier table's 2020-2021 sector counts exactly at 16 and over, which only works if AGEUNITS is the age. Fixed in both docs. team-archive/analyses/README.md ("filter on AGETYPE as well") is correct as written.

1.6 script-audit.md said the long script suppressed counts. docs/script-audit.md line 23 (finding 1: "Counts, percents, rates and RRs are all blanked for 1 to 5 deaths") and line 44 (finding 22: "Output gets suppressed tables") against scripts/old/io_death_rates_v1_long.R line 697: "# 7. NO SUPPRESSION. Full counts and rates everywhere, on purpose." The note at the top (line 3) said the findings "still describe the rules both versions share". Fixed with a status note, and the suppression items are marked withdrawn.

1.7 Script header dates. scripts/io_death_rates_v8.R line 5: "v8 (2026-09-29)"; scripts/io_death_rates_v9.R line 7: "v8 (2026-09-28)"; commit df44a0e (2026-09-28) and docs/v5-changes.md "First real run of v8 (2026-09-28)". Also scripts/io_death_rates_v3.R line 1: "(v3, 2026-09-29 ...)", though v3 was committed 2026-09-28 (750c3f3) and v4's header (line 2) already refers to v3. Not fixed (scripts are never edited). Record the correct dates in the next version's header.

1.8 Was the earlier table's denominator like for like? The v9 header (lines 5 and 6) calls the comparison "like for like ... ages 16 and over". The numerators match, but the earlier table's FTE files do not share one age range. suicide_agg.R line 17 reads FTE_2020_PUMS_5y_naics2.csv, which team-archive/denominators/acs-pums-fte/industry/scripts/ACS_PUMS_industry_estimates.R writes (line 303) after `filter(AGEP <= 64)` (line 159). team-archive/denominators/README.md line 136 lists the other age limits used (none, 16 and over, 70 and under). This is a likely part of the few-percent FTE rate gaps in docs/three-way-comparison.md. A caveat was added there.

1.9 PDF count. source-docs/INVENTORY.md line 3: "All 42 PDFs"; 43 PDFs are in source-docs/ and 43 texts in extracted-text/, and the table has 43 rows. Fixed.

1.10 Test descriptions disagree. docs/script-audit.md line 13 ("40 of 40 checks") and docs/v5-changes.md line 3 ("61 checks" for v5) against tests/synthetic_run.R line 2, which now runs scripts/io_death_rates_v6.R. tests/synthetic_run_v4.R line 2 still calls itself "tests/synthetic_run.R". The docs now point to the current test. The test headers were not edited.

## 2. Stale statements

2.1 README.md line 3 described the project as using "SUDORS and NVDRS/NEVDRS data, with Nebraska death certificate data to be added later". Line 18 called scripts/io_death_rates.R "The analysis", and line 19 listed scripts/io_death_rates_extras.R, which does not exist (the file is scripts/io_death_rates_extras_v3.R). v3 to v9, the tests and six docs were not listed. Fixed. scripts/io_death_rates.R differs from v3 only in line 1 and the cache file name (line 116).

2.2 docs/analysis-plan.md still named the Guardian exports as the numerator. Line 25 says "Do not use the NCHS annual occurrence file as the primary source", but v8 and v9 use exactly that. Line 43 gives C24030 and C24010 as denominators; v8 uses PUMS persons and FTE. Line 60 still asks whether NIOCCS use is allowed, which was approved on 2026-09-29. Fixed with a status note, the corrected decision row and the corrected step 9.

2.3 docs/acs-denominator-spec.md line 3 says "likely ACS employed workers ... Not yet signed off by Derry". Its FTE formula (line 47, hours x weeks / 2,000) is not the one v8 uses (PWGTP x WKHP / 40, scripts/io_death_rates_v8.R line 270). Fixed with a status line, keeping line numbers unchanged because docs/provenance-audit-v4.md cites them.

2.4 docs/project-brief.md line 14 said "the likely choice is ACS employed workers", and line 53 said "2024 and the 2020-2024 5-year window are missing". v8 pulls the 2020-2024 PUMS itself (docs/v5-changes.md line 64). Fixed; a status paragraph was added at the top.

2.5 docs/script-audit.md: its line 3 note, finding 25 and decision 5 (run_nioccs FALSE until the data use question is answered) were stale. Fixed with the status note.

2.6 docs/v5-changes.md: the title covered v5 only, but the file records the v6, v7 and v8 runs. Line 60 said "v7 is the release script". The v9 run was not recorded. Fixed: new title, a lead paragraph, the release line corrected, and a v9 section added.

2.7 docs/provenance-comparison.md section C and docs/death-cert-data-notes.md "What this means" still recommend the Guardian and ACS-table route. v3 to v7 took that route; v8 and v9 do not. Status lines were added.

2.8 docs/provenance-audit-v4.md lines 19, 21, 35, 43 and 67 cited docs/analysis-plan.md lines 98 to 111. Those lines do not exist: the plan has 77 lines, and the numbers came from a concatenated read. Re-pointed to the real lines (now 34, 35, 36, 41, 47).

2.9 docs/v5-verification.md line 5: "Findings 1 to 4 should go into the next version (v7)". v7 did not include findings 2 to 4. It still selects columns with `any_of` and says nothing when a column is missing (scripts/io_death_rates_v7.R line 64), has no date-range check, and has no blank-DOB count. v8 does stop on a missing column (lines 71 to 72). Also, line 9 of that doc points to throwaway scripts in a session scratchpad outside the repo. Not edited: the doc is a dated review.

2.10 There is no test for v7, v8 or v9. The release scripts have only been checked by real runs.

## 3. Rule violations

3.1 Em dashes. There were 95 in docs/web-captures/: cdc-overdose-prevention-mmwr-articles.md (86), cdc-nvdrs-resources.md (8, one of them in our own note on line 4) and census-bureau-data-and-maps.md (1). All were replaced with hyphens, and each capture's "Captured:" line now says so. Still present and not edited, because they are machine or verbatim extractions of source PDFs and forms: 38 in six extracted-text/ files (NEVDRS-Coding-Manual.txt 21, SUDORS-Coding-Manual.txt 10, NEVDRS-Overview.txt 4, three others with 1 each) and 1 in team-archive/knowledge-transfer/Chris-Austin-Knowledge-Transfer-Questionnaire.txt line 32. Decision for Trenton: replace them there too, or accept verbatim extractions as the exception. No scripts, tests, CLAUDE.md or other docs contain an em dash.

3.2 Suppression. No script or test implements it. Every script header says "No suppression", and tests/synthetic_run.R line 292 checks that small counts are written. Wording that recommended suppression inside the analysis, or treated its absence as a defect, is now fixed:
- docs/provenance-comparison.md line 130 ("DHHS floor of 6 and the under-20 unstable flag") and line 135 ("reuses A8's ... suppression").
- docs/death-cert-data-notes.md line 85 ("suppression applied").
- docs/project-brief.md line 55 ("neither has confidence intervals or suppression").
- team-archive/analyses/README.md line 119 ("no suppression (DHHS floor of 6 ...)") and line 123 ("add ... suppression").
- docs/script-audit.md findings 1 and 22, and decision 6.
Left as is because they only describe other bodies' practice or the release rule: docs/analysis-plan.md step 8, docs/death-cert-data-notes.md line 74, docs/nevdrs-sectors-factsheet-review.md line 28, docs/provenance-comparison.md sections A and B, docs/people-nevdrs-sudors.md line 25, and team-archive/analyses/README.md line 155.

3.3 Credentials. The working tree is clean: every key and password reads REDACTED, and scripts take the Census key from the environment or tidycensus. Git history still holds two plaintext SQL Server passwords, a Census API key and BLS API keys. They are removed in commits 5307cf3 and 220db72 but still visible in earlier commits (5a35f1b and its parents). team-archive/README.md lines 18 to 26 already say so, and also that internal server hostnames remain. Still to do (not done here): rotate every credential, then purge history and force push. This needs Trenton's go-ahead.

3.4 Record-level data. None is committed. The header of every tracked CSV was checked: all are aggregates (counts by sector, occupation or year; FTE estimates; BLS series; HDD cause counts). No Output/ or Cache/ file is tracked. The v8 and v9 case lists (CERTNUM, age, sex) go only to Cache (scripts/io_death_rates_v8.R lines 385 to 387). The binary xlsx, docx and pptx files were not opened. team-archive/analyses/README.md already flags that pcc_occupaitonal_ex_form_carbdiox.Rmd describes a single incident.

## 4. Script headers (v8 and v9)

4.1 scripts/io_death_rates_v9.R contradicts itself on age. Line 3 says "aged 16 and over" and line 42 sets `age_hi <- 120`. But the header's step 2 (line 10) and step 6 (line 19), and the section comments at line 83 ("ages 16 to 64") and line 242 ("civilian employed aged 16 to 64"), still say 16 to 64. The comment at line 43 says "65+", but the label the code builds is "65-120". The code is right; the comments are copied from v8. Fix these in the next version.

4.2 scripts/io_death_rates_v8.R: the header matches the code for residents (line 107), dedupe on DOD_YR and CERTNUM (lines 89 to 90), ages (lines 40 and 108), outcome codes (lines 124 to 126), NIOCCS (lines 162 to 163), sector rules (lines 199 to 205), PUMS universe and FTE (lines 265 and 270), the Poisson CI (lines 330 to 331) and no suppression. The date on line 5 is wrong (see 1.7).

4.3 Provenance claims against the team archive:
- The 3M, 4M and 48/49 sector rules match ACS.R lines 27 to 32 and the demo script lines 75 to 76.
- The age bands match ACS_PUMS_FTE_industry_estimates_demo.R lines 34 to 38 (top band 60-70, cut at 64 in v8).
- The GET call matches `CDC NIOCCS web service i_o GET.R` lines 8 to 11.
- "Chris Austin's occupation FTE script filters AGEP <= 64" (line 9) is accurate for ACS_PUMS_occupation_estimates.R line 39. But team-archive/denominators/README.md line 5 says authorship is not stated in most files, and line 136 shows the team's scripts use several different age limits, so 64 is one team choice, not the team rule.
- "combine data.sas line 195" and "ohi deaths 2018-2025.sas line 728" are in other repos and cannot be checked here. So cannot "these add at most one or two deaths" (line 11).

4.4 Code note, not a header issue: v8 lines 124 to 125 compare ICD ranges as strings (`u3 >= "X60"`). docs/script-audit.md finding 6 had replaced this pattern as locale-dependent. It is harmless for uppercase letter-plus-digit codes in common locales, but the next version could list the codes.

4.5 v3 to v7 headers describe their code. v7 (line 2) says 16 and over and computes age as trunc(days / 365.25) (line 103).

## 5. Attribution

Consistent everywhere. The earlier FTE and NIOCCS work is attributed to Chris Austin (tools, GET call, Workforce Estimates tool) and Jean Kwizerimana (the death certificate adaptations, nioccs_suicide.R and suicide_agg.R, run from Jean's K: folder). Places checked: docs/project-brief.md line 51, docs/provenance-comparison.md line 54, team-archive/README.md line 3, team-archive/io-coding/nioccs/README.md line 5, team-archive/knowledge-transfer/README.md line 31, and the v8 and v9 headers. docs/three-way-comparison.md names no one, which is compatible. Nothing contradicts "Chris and Jean's work". The later FTE revision of the NEVDRS sheet is attributed to "Can and Chris" on Derry's word in four places (project-brief.md line 38, nevdrs-sectors-factsheet-review.md line 3, provenance-comparison.md line 27, nioccs README line 61). That is consistent, and separate from the earlier table.

## 6. docs/people-nevdrs-sudors.md: inference stated as fact

Everything below was relabeled as (LinkedIn) or (inference), or corrected to what the captures say:
- LinkedIn facts are not captured in the repo, so they cannot be checked here: Mamie's "Lush-Denny", her 2019 start, FungiSurv lead, the September 2024 move, her tools, and awards; Can's contractor status (Matthew Associates), remote work, GIS, Apple, MBA and tool list.
- "FungiSurv sits with the environmental health epidemiology work Derry supervises. So she knows the occupational health team" (line 9). The TRIX capture (line 23) shows only that the two co-teach the Fungi Surveillance course.
- "he built the sector fact sheet's maps and dashboards; the denominator choice ... is the kind of thing a mapping and dashboard analyst would default to" (line 18). The sheet has no author line, and the reason for its denominator is unknown. The transcript (lines 9 to 10) shows only that Can said he was working with Mamie on the sector data.
- "she is the case-level owner ... She is SAS-first" (line 11) is inference.
- "Mamie was in MCH Epidemiology ... until 2024 per the HRSA narrative" (line 30). The narrative gives no end date.
- "(Rishad Ahmed on the call)" (line 29) implied a role. No capture states one.
- The 72 vs 65 gap. Line 24 named reclassification as "a likely source". Line 22 noted out-of-state residents but did not link them to the gap. Both are now given as possible sources. The same two explanations were missing from docs/nevdrs-sectors-factsheet-review.md, docs/three-way-comparison.md and the v8 run notes in docs/v5-changes.md (docs/analysis-plan.md step 9 said only "residency, manner versus ICD"). All were added. Supporting figures: the NEVDRS sheets give 289 + 284 = 573 suicides for 2020-2021, against 269 + 277 = 546 in the Guardian exports (docs/death-cert-data-notes.md line 98).

## 7. Open items for Trenton (not fixable in docs)

1. Do the NCHS dth files include residents who died out of state? docs/death-cert-data-notes.md line 19 calls them occurrence files. The exact 440 match with the Guardian exports suggests any gap is small, but it is not documented.
2. The NCHS vs Guardian difference of 10 suicides (16 and over, 2020-2024) is now noted in docs/v5-changes.md, but the two totals themselves are recorded nowhere.
3. The next script version should fix: the v9 age comments (4.1), the header dates (1.7), the v5-verification findings 2 to 4 (2.9), and optionally the string ICD ranges (4.4).
4. Rotate the credentials and purge git history (3.3).
5. Decide on em dashes in extracted-text/ and the questionnaire text (3.1).

## Edits made in this audit

- README.md: new intro naming v8 and v9 and where results are; replaced the stale script rows (removed the nonexistent io_death_rates_extras.R); added rows for v3 to v9, the tests and six docs; updated the web-captures, analysis-plan and acs-denominator-spec rows.
- docs/analysis-plan.md: status note after line 3; step 9 order corrected to 72, 55, 84 and reasons expanded (age, out-of-state residents, reclassification); quality-check totals corrected to 289 / 284 / 305 (and 306 from Vital Statistics); NIOCCS decision row marked settled.
- docs/acs-denominator-spec.md: status added to line 3 (line count unchanged).
- docs/project-brief.md: status paragraph; denominator sentence updated; NAICS outputs 2013 to 2023; 2024 PUMS now pulled by v8; the FTE-division sentence corrected; "or suppression" removed; the v9 reproduction noted.
- docs/script-audit.md: line 3 replaced with a historical status note; findings 1 and 22 and decisions 5 and 6 updated (line count unchanged).
- docs/v5-changes.md: title and lead paragraph; "v7 was the release script until v8"; reasons NEVDRS counts differ added to the v8 run; new v9 run section.
- docs/three-way-comparison.md: 440 provenance clarified; paragraph on the 72 vs 65 gap; denominator age-range caveat.
- docs/nevdrs-sectors-factsheet-review.md: reclassification and out-of-state added as gap candidates, with pointers to the v8 and v9 counts.
- docs/provenance-comparison.md: status note; A6 age sentence and table row corrected; C4 and D suppression wording replaced.
- docs/death-cert-data-notes.md: status sentence on line 3; "suppression applied" replaced (line count unchanged).
- docs/provenance-audit-v4.md: five analysis-plan line references re-pointed.
- docs/people-nevdrs-sudors.md: sources and inferences labeled as in section 6.
- docs/web-captures/cdc-overdose-prevention-mmwr-articles.md, cdc-nvdrs-resources.md, census-bureau-data-and-maps.md: em dashes replaced with hyphens, noted on each "Captured:" line.
- source-docs/INVENTORY.md: 42 changed to 43 PDFs; Dashboard1 year mapping corrected.
- team-archive/analyses/README.md: suppression removed from the list of defects and from the reuse recipe.
- team-archive/io-coding/nioccs/README.md: AGEUNITS sentence corrected.
- New: docs/repo-audit-2026-09-29.md (this file).
