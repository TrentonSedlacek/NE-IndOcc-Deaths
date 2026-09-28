# Syndromic surveillance NLP: work-related ED visit classification

Chris Austin's (and collaborators') code and documentation for classifying Nebraska ESSENCE emergency department visits as work-related or not, using NLP and scikit-learn. Also includes the cancer pathology reportability NLP code it was adapted from. Not directly part of the overdose and suicide I/O rate project; archived here for continuity. Collected from the repo root on 2026-09-28.

## Inventory

| File | What it is |
|---|---|
| `Occupational Health Data Processing for Syndromic Surveillance.docx` | Chris's checklist for preprocessing SyS data in R: import (SQL or ESSENCE CSV), missing values, types, duplicates, NLP work-relatedness flag, I/O mapping by left join to NAICS/SOC reference tables, outliers, aggregation, export. |
| `Machine Learning Workflow Documentation for Classifying Work-Related Injuries.docx` | Chris's ML workflow: tokenization, stop words, POS tagging, lemmatization; presence/absence, count and TF-IDF vectors; Naive Bayes, SVM (SGD), logistic regression; metrics; pipelines; joblib saving; retraining. |
| `creating_SyS_dataset_NLP.R` | Builds the labeled training set: 2023 ED visits, work-related positives vs. sampled non-occupational visits and known false positives (1,535 per class), concatenates DischargeDiagnosis, ChiefComplaintParsed, TriageNotesOrig, ClinicalImpression into one `text` field, writes `K:/SYS NLP/Data/sys_er_combined.parquet`. Later sections build a test set, pull July 2024 ED visits (age 16 to 80) directly from the ESSENCE and ER surveillance SQL Servers, and sample a "Broad Query Validation" file (26 Aug 2024). |
| `NLP_SyS_OccHealth_ModelAnalysis.py` | Main model script (pandas): preprocessing, Naive Bayes (count and TF-IDF), SGD linear SVM and logistic regression pipelines, confusion matrices. Reads `\\fs1.hhss.local\edv\SYS NLP\Data\sys_er_combined.parquet`. |
| `NLP_SyS_OccHealth_ModelAnalysis_polars.py` | Same analysis rewritten with polars. |
| `NLP_SyS_OccHealth_ModelAnalysis.ipynb` | Notebook version of the model analysis, with saved outputs. |
| `NLP_SyS_OccHealth_ClusterAnalysis.py` | Unsupervised check: KMeans (k = 2) on presence/absence, count and TF-IDF vectors. |
| `NLP_SyS_OccHealth_ICD10check.py` | Rule-based baseline: flags a visit as work-related if its text contains codes from `keywords_oh.txt` (ICD-10 work-related list), compares with labels. |
| `model_performance_test.py` | Accuracy, precision, recall, F1 for each model against a manually reviewed file `model_result_reviewed.csv`. |
| `NLP_AmieCode.py` | Cancer pathology report reportability NLP (HL7 OBX-5 text, reportable vs. non-reportable, SEER ICD-10 case-finding list). This is the DSTT cancer registry project code (see `../knowledge-transfer/DSTT Nebraska.pptx`) that the SyS scripts were built from; the helper functions are the same. Writes to the SYS NLP share. |

No duplicates were found in this set (`ModelAnalysis.py`, `_polars.py` and the `.ipynb` are related versions, not copies).

Data locations referenced: `K:\SYS NLP\Data\` and `\\fs1.hhss.local\edv\SYS NLP\Data\` (apparently the same share), plus working-directory CSVs such as `sys_occ_er_2023.csv`, `work_ER_visits_positives.csv`, `falsepositives.csv`.

## Security and privacy notes

- **Passwords redacted.** `creating_SyS_dataset_NLP.R` lines 166 to 180 opened ODBC connections to two DHHS SQL Servers (ESSENCE detection database and ER surveillance production) with the passwords typed in the script. Both `PWD` values were replaced with `REDACTED`. Server names and user IDs were left in place. The same two passwords are still in git history and also appear unredacted in `team-archive/bls-api-data/BLS_report.Rmd` (outside this folder). They should be treated as exposed and rotated by whoever owns those accounts.
- **Possible patient-level text in outputs.** `NLP_SyS_OccHealth_ModelAnalysis.ipynb` has saved cell outputs that print rows of ED visit text (discharge diagnosis codes and chief complaint fragments). No names or record IDs were seen in the printed rows, but consider clearing notebook outputs before sharing this repo more widely.
