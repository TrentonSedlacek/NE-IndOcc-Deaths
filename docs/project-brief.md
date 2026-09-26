# Project brief: Nebraska opioid/drug overdose deaths and suicides by industry and occupation

Last updated: 2026-09-24

## The ask

Two last-minute projects, both rates by industry and occupation (I/O):

1. Opioid-related (possibly wider drug overdose) deaths by industry and occupation.
2. Suicide deaths by industry and occupation.

Data sources to examine first: SUDORS (overdose) and NVDRS/NEVDRS (suicide), as published and held by the NE DHHS Office of Injury Surveillance. Nebraska death certificate data by I/O will be compared against them. The team's death certificate repos were reviewed on 2026-09-24; see docs/death-cert-data-notes.md for what they hold and the plan.

The README describes the rates as "by FTE." Note that the Massachusetts report the team is using as a model does not use FTE; it uses employed workers from the American Community Survey (ACS) as the denominator (deaths per 100,000 workers). See source-docs/INVENTORY.md, Massachusetts section. Whether to use FTE (hours-adjusted) or employed-worker denominators is an open decision. As of 2026-09-26 the likely choice is ACS employed workers (per Trenton), matching Massachusetts; see docs/acs-denominator-spec.md. ACS PUMS can also supply an FTE denominator if needed.

## People

- Derry Stover: user's boss (occupational health team). Asked in the 2026-09-23 meeting to be looped in on the NEVDRS industry/sector work.
- Trenton Sedlacek: user. Robin Williams said in the meeting that anyone doing industry/occupation data should get in touch with Trenton to review it.
- Can Ceyhan: NEVDRS/SUDORS Data Analyst, NE DHHS. Said in the meeting they are working with Mamie on "industry slash sector data" for a combined four-year suicide report.
- Mamie Lush: NEVDRS/SUDORS Epidemiologist I, NE DHHS.
- Rishad Ahmed, Robin Williams: also in the meeting.

## Why the meeting with Can and Mamie

Derry's concern: NEVDRS staff produced industry/occupation figures (for example construction or manufacturing deaths) without looping in the occupational health team, and could not explain how the numbers were derived. Trenton is to schedule a meeting and sort out the method.

## What the collected materials show (as of this date)

- None of the public NE DHHS fact sheets, newsletters, or the Power BI suicide dashboard contain any industry or occupation counts or rates. The I/O work Can mentioned is not published in anything collected here. Source: source-docs/INVENTORY.md.
- The only documented I/O pathway in NEVDRS/SUDORS is the set of death certificate fields the abstractors copy into the CDC system: Industry, IndustryText, UsualOccupation, OccupationText (Census Bureau I/O codes, copied as they appear on the death certificate, not coded by the state), plus a free-text OccupationCurrentText field. NVDRS Coding Manual v6.0 pages 44 to 46; SUDORS Coding Manual v6.3 page 27.
- "Job problems contributed to death" on the dashboard is an NVDRS circumstance flag, not an occupation breakdown.
- The Massachusetts model: death certificate numerator, usual I/O text coded with NIOCCS to NAICS and SOC, ACS employed workers as denominator, per 100,000 workers with 95% CIs, exclusions for non-workforce, uncodable, and military.
- CDC precedent for suicide by I/O using NVDRS: Peterson et al., MMWR 2020;69:57-62 (32 states, 2016). Listed on the CDC NVDRS resources page (docs/web-captures/cdc-nvdrs-resources.md).

## What is known about the unpublished NEVDRS I/O work (from Trenton, 2026-09-24)

- Not published; the occupational health team does not have access to it.
- It is a three-panel comparison: non-workers, construction, and manufacturing. Not all-industry rates.
- Construction was reported at roughly 70 to 72 deaths per 100,000. Nothing else about the numbers is known (which outcome, which years, which denominator).
- Derry does not trust the number because it did not come from the occupational health team and the method is unexplained.

Things the three-panel design leaves open: how "non-worker" was defined and what its denominator was (not in labor force, unemployed, or everyone without a coded occupation), why construction and manufacturing were singled out, and whether the 70 to 72 figure is suicide, overdose, or combined.

## Questions to bring to Can and Mamie

1. Which fields did you use for industry and occupation: the death certificate coded fields, the text fields, or the NVDRS current occupation free text?
2. Who coded them and with what system (NIOCCS, manual, Census codes from Vital Records)? To what level (NAICS sector, SOC major group, Census 2018 codes)?
3. What was the denominator for any rates (population, ACS employed workers, FTE, something else)? Which years of ACS?
4. What exclusions were applied (age range, non-workforce, unknown/uncodable, military, non-residents)?
5. Which case definition: NVDRS manner of death or death certificate ICD-10? For overdose, SUDORS case definition (X40-44, Y10-14 plus literal text) or something else?
6. Which years, and are the numbers resident or occurrent deaths?
7. For the three-panel figure (non-workers, construction, manufacturing): what outcome and years does the 70 to 72 per 100,000 construction figure cover, what is the numerator count, and how was the non-worker group defined?
8. Can we get the case-level extract (or at least the I/O crosstab) so the occupational health team can reproduce the figures?

## Repo layout

- docs/web-captures/: verbatim saves of the NE DHHS and CDC web pages pasted on 2026-09-24 (duplicates removed).
- docs/meetings/: meeting transcript from 2026-09-23.
- source-docs/: all PDFs, sorted by source and topic. INVENTORY.md describes each one and lists every I/O mention.
- extracted-text/: plain-text extraction of every PDF (pypdf), one .txt per PDF with page markers, for grepping.
