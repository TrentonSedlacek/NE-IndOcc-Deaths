# CSTE Methods workgroup (team archive)

Moved from `CSTE Methods workgroup/` on 2026-09-28. Material Chris Austin (Occupational Health Epidemiologist, NE DHHS) prepared for a CSTE methods workgroup presentation on interrupted time series (ITS) analysis.

## Inventory

| File | What it is | Source | Years | Geography | Industry coding |
|---|---|---|---|---|---|
| `ITS_CSTE_METHODS.pptx` | 16-slide deck, "Analyzing Public Health Interventions Using Interrupted Time Series": ITS components, autocorrelation, seasonality, a worked single-intervention example (hypothetical smoking ban and admissions) fitted with GLS and ARMA errors, counterfactual and relative differences, references. | NE DHHS (Chris Austin) | Undated (references to 2023) | None | None |
| `interrupted_ts_analysis.R` | Script behind the deck: simulates 100 time points with an intervention at 50, fits `nlme::gls` segmented regression, compares ARMA(p,q) structures by AIC, plots fitted and counterfactual lines. Uses simulated data only. Adapted from Roberts, "A pragmatic introduction to interrupted time series" (RPubs 2023). | Simulated | None | None | None |
| `Interrupted time series regression for public health.pdf` | Bernal, Cummins, Gasparrini. Interrupted time series regression for the evaluation of public health interventions: a tutorial. Int J Epidemiol 2017;46:348-355. doi:10.1093/ije/dyw098. 8 pages. | Published article | 2017 | None | None |

## Relevance to the industry and occupation deaths project

None directly. There is no data, industry, or occupation content. It would only matter if the project later evaluates a policy change (for example, a naloxone or prescribing intervention) against a time series of worker overdose deaths.
