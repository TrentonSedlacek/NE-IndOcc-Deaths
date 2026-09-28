# Denominator spec: American Community Survey (ACS) employed workers

Decision recorded 2026-09-26: the denominator for both projects is likely ACS employed workers, matching the Massachusetts method. Not yet signed off by Derry.

## Why ACS fits this project

- It is what Massachusetts used, so Nebraska rates can be set beside theirs.
- The death certificate carries Census industry and occupation codes. ACS publishes workers by the same Census industry and occupation categories, so death certificate codes roll up to ACS groups directly. No NAICS or SOC crosswalk is needed for the published-table route. That is a real advantage over QCEW, which counts jobs by NAICS establishment and excludes most farm work.
- ACS is residence-based and counts persons. The numerators are Nebraska resident deaths of persons. The two line up.
- ACS PUMS carries usual hours worked and weeks worked. If Derry wants rates per full-time equivalent (FTE) after all, the FTE denominator can come from the same survey (see below), so the choice between "per worker" and "per FTE" does not force a change of source.

## Tables

| Table | Universe | Use |
|---|---|---|
| C24030 Sex by Industry | Civilian employed population 16 and over | Industry denominators, total and by sex |
| C24010 Sex by Occupation | Civilian employed population 16 and over | Occupation denominators, total and by sex |
| ACS PUMS, Nebraska person file | All persons; filter ESR = 1 or 2 (civilian employed) | Age-by-industry denominators if age adjustment is wanted, detailed groups, or FTE |

The by-sex split matters: suicide decedents are mostly male (the NEVDRS dashboard shows 716 of 878 for 2020 to 2022), so male-only rates by industry are the more informative comparison.

## Years and rate arithmetic

- Numerator years: 2020 to 2024 pooled, Nebraska residents, age 16 and over.
- Denominator: the ACS 5-year 2020-2024 estimate. A 5-year estimate is a period average, so worker-years = estimate x 5.
- Rate per 100,000 workers = deaths(2020-2024) / (5 x ACS estimate) x 100,000.
- Do not use single-year 2020 ACS. The 2020 1-year release was experimental because of pandemic data collection problems.
- If single-year rates are wanted later, use ACS 1-year 2021 to 2024 (and 2025 once released), one year at a time.

## Numerator rules that follow from the ACS universe

- Age 16 and over only.
- Exclude the military. ACS C24030 and C24010 cover civilians only. Massachusetts excluded military occupations for the same reason.
- Keep non-workers (homemaker, student, unemployed, disabled, retired, never worked) as a separate row with no rate. There is no ACS employed denominator for them. This is the key point against the NEVDRS three-panel figure: a "non-worker" rate needs a non-worker denominator, and it is not clear what they used.
- Keep "industry not coded" as its own row. Report its count so readers see how much of the numerator is unassigned.
- Known mismatch, accepted by Massachusetts and by CDC's NVDRS industry papers: the death certificate records usual industry and occupation, while ACS counts current employment. State it as a limitation.

## Confidence intervals

- Poisson intervals on the death count are the standard approach and match Massachusetts.
- ACS estimates carry a margin of error (the fetch script saves it). For small sectors, the denominator error can matter. Note it in the limitations, or propagate it if a sector result is going to be quoted.

## FTE option, same source

FTE by industry or occupation from PUMS:

FTE = sum over employed persons of (person weight x usual hours per week x weeks worked) / 2,000

PUMS variables: PWGTP (weight), WKHP (usual hours), WKWN (weeks worked), INDP (industry code), OCCP (occupation code), ESR (employment status), AGEP (age). INDP and OCCP are the same Census code sets as the death certificate. Rate per 100,000 FTE uses this sum in place of the worker count. Needs the PUMS file, not the published tables.

## How to get the numbers

Option A, automated: `scripts/fetch_acs_denominators.py` pulls C24030 and C24010 for Nebraska from the Census API and writes tidy CSVs with estimates, margins of error, and the Census labels to `data/denominators/`. It needs outbound access to api.census.gov, which this cloud environment currently blocks. It runs as-is on any machine with Python 3 and internet.

```
python scripts/fetch_acs_denominators.py
python scripts/fetch_acs_denominators.py --dataset acs1 --years 2021 2022 2023 2024
```

Option B, by hand: data.census.gov, search C24030 and then C24010, geography Nebraska, product "ACS 5-Year Estimates Detailed Tables", vintage 2024. Download CSV and save into `data/denominators/`.

## Open items

1. Derry's sign-off on ACS, and on per-worker versus per-FTE.
2. Confirm which Census code vintage the death certificate uses for 2020 to 2024 (2012 or 2018 Census codes). ACS switched to 2018 codes starting with 2018 data. The Death Layout 2005+ PDF on K: should say.
3. Whether age adjustment by industry is wanted. If yes, PUMS is required for age-by-industry denominators; the published tables are not enough.
