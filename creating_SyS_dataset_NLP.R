# Load necessary libraries
library(tidyverse) # For data manipulation and visualization
library(arrow)     # For reading and writing in Parquet format

# Read and preprocess Sys_OH_ER dataset
Sys_OH_ER <- read_csv("sys_occ_er_2023.csv") |> # Read CSV file
  select(ErRecordID,DischargeDiagnosis,ChiefComplaintParsed,TriageNotesOrig, ClinicalImpression) # Select relevant columns

Sys_OH_ER$ChiefComplaintParsed <- str_to_lower(Sys_OH_ER$ChiefComplaintParsed)
Sys_OH_ER$TriageNotesOrig <- str_to_lower(Sys_OH_ER$TriageNotesOrig)
Sys_OH_ER$ClinicalImpression <- str_to_lower(Sys_OH_ER$ClinicalImpression)
Sys_OH_ER$TriageNotesOrig <- sub(" past medical / surgical .*", "", Sys_OH_ER$TriageNotesOrig)


Sys_OH_ER <- Sys_OH_ER |>
  mutate(DischargeDiagnosis = str_replace_all(DischargeDiagnosis, ";", " "), 
         DischargeDiagnosis = str_remove_all(DischargeDiagnosis, "\\.")) |>
  unite("text", DischargeDiagnosis,ChiefComplaintParsed,TriageNotesOrig,ClinicalImpression, sep = " ------------------- ") # Combine columns into a single text column


Sys_OH_ER$ErRecordID[duplicated(Sys_OH_ER$ErRecordID)]  ## checking for any duplicates


# Read additional datasets
workPositives <- read_csv("work_ER_visits_positives.csv") # Read work positives dataset
falsePositives <- read_csv("falsepositives.csv") # Read false positives dataset

# Filter Sys_OH_ER for positive cases
Sys_OH_ER_OccPos <- Sys_OH_ER |>
  filter(ErRecordID %in% workPositives$ErRecordID) # Keep only records present in 'workPositives'



# Update Sys_OH_ER by removing false positives and sampling
Sys_OH_ER <- Sys_OH_ER |>
  filter(!ErRecordID %in% falsePositives$ErRecordID) |> # Remove false positives
  filter(!ErRecordID %in% workPositives$ErRecordID) |>
  slice_sample(n = 1535-nrow(workPositives)) # Randomly sample records

# Combine positive cases with updated Sys_OH_ER
Sys_OH_ER <-  bind_rows(Sys_OH_ER_OccPos, Sys_OH_ER) 

# Add an indicator variable for Sys_OH_ER
Sys_OH_ER$Indicator <- 1

#workPositives$ErRecordID[duplicated(workPositives$ErRecordID)]
#falsePositives$ErRecordID[duplicated(falsePositives$ErRecordID)]
#Sys_OH_ER_OccPos$ErRecordID[duplicated(Sys_OH_ER_OccPos$ErRecordID)]
#Sys_OH_ER$ErRecordID[duplicated(Sys_OH_ER$ErRecordID)]


# Read and preprocess Sys_ER dataset
Sys_ER <- read_csv("sys_er_2023.csv") |> # Read CSV file
  #filter(!PatientClass %in% c("Outpatient", "Inpatient", "Observatio", "Inbox Mess", "Preadmit", "Recurring")) |> # removing visits that might be missclassified as HasBeenE
  select(ErRecordID,DischargeDiagnosis,ChiefComplaintParsed,TriageNotesOrig,ClinicalImpression) # Select relevant columns

Sys_ER$ChiefComplaintParsed <- str_to_lower(Sys_ER$ChiefComplaintParsed)
Sys_ER$TriageNotesOrig <- str_to_lower(Sys_ER$TriageNotesOrig)
Sys_ER$ClinicalImpression <- str_to_lower(Sys_ER$ClinicalImpression)
Sys_ER$TriageNotesOrig <- sub(" past medical / surgical .*", "", Sys_ER$TriageNotesOrig)


Sys_ER <- Sys_ER |>
  mutate(DischargeDiagnosis = str_replace_all(DischargeDiagnosis, ";", " "),
  DischargeDiagnosis = str_remove_all(DischargeDiagnosis, "\\.")) |>
  unite("text", DischargeDiagnosis,ChiefComplaintParsed,TriageNotesOrig,ClinicalImpression, sep = " ------------------- ") # Combine columns into a single text column


# Filter Sys_ER for false positives
Sys_ER_OccFP <- Sys_ER |>
  filter(ErRecordID %in% falsePositives$ErRecordID)|>
  mutate(strLength = str_length(text)) |>
  group_by(ErRecordID) |>
  filter(strLength == max(strLength)) |>
  ungroup() 


# Filter Sys_ER for non-occupational cases
Sys_ER_NonOcc <- Sys_ER |>
  mutate(strLength = str_length(text)) |>
  group_by(ErRecordID) |>
  filter(strLength == max(strLength)) |>
  ungroup() |>
  filter(strLength > 86) |>
  filter(!ErRecordID %in% Sys_OH_ER$ErRecordID) |> # Exclude records present in Sys_OH_ER
  filter(!ErRecordID %in% falsePositives$ErRecordID) |>  # Remove false positives
  distinct() |>
  slice_sample(n = 1535-nrow(falsePositives)) # Randomly sample records

# Combine false positives with non-occupational cases
Sys_ER_NonOcc <- bind_rows(Sys_ER_OccFP, Sys_ER_NonOcc)

Sys_ER_NonOcc$ErRecordID[duplicated(Sys_ER_NonOcc$ErRecordID)]



# Add an indicator variable for Sys_ER_NonOcc
Sys_ER_NonOcc$Indicator <- 0

# Combine Sys_OH_ER and Sys_ER_NonOcc into one dataset
Sys_ER_combined <- bind_rows(Sys_OH_ER, Sys_ER_NonOcc) 



# Remove the first column from the combined dataset
Sys_ER_combined <- Sys_ER_combined |>
  select(-1, -4)

Sys_ER_combined$text <- str_replace_all(Sys_ER_combined$text, "\\s+", " ")


# Write the datasets to Parquet format (these lines are commented out)
#write_parquet(Sys_OH_ER, "sys_occ_er_2023.parquet")
#write_parquet(Sys_ER_NonOcc, "sys_er_NonOcc.parquet")

write_parquet(Sys_ER_combined, "K:/SYS NLP/Data/sys_er_combined.parquet")


modelResults <- read_csv("\\\\fs1.hhss.local\\edv\\SYS NLP\\Data\\model_result_reviewed.csv")
modelResults$ErRecordID <- as.character(modelResults$ErRecordID)

data_test <- readxl::read_xlsx("K:/SYS NLP/Data/test/DataTable_202_19_03_2024_16_44_55_8866_OH_NADIA.xlsx") |> # Read CSV file
  select(ErRecordID,`Discharge Diagnosis`,ChiefComplaintParsed,TriageNotesOrig,ClinicalImpression) # Select relevant columns
  
data_test$ChiefComplaintParsed <- str_to_lower(data_test$ChiefComplaintParsed)
data_test$TriageNotesOrig <- str_to_lower(data_test$TriageNotesOrig)
data_test$ClinicalImpression <- str_to_lower(data_test$ClinicalImpression)
data_test$TriageNotesOrig <- sub(" past medical / surgical .*", "", data_test$TriageNotesOrig)


data_test <- data_test |>  
  filter(ErRecordID %in% modelResults$ErRecordID) |>
  left_join(modelResults[,c(1,7)], by = "ErRecordID") |>
  rename(DischargeDiagnosis = `Discharge Diagnosis`) |>
  mutate(DischargeDiagnosis = str_replace_all(DischargeDiagnosis, ";", " "), 
         DischargeDiagnosis = str_remove_all(DischargeDiagnosis, "\\.")) |>
  unite("text", DischargeDiagnosis,ChiefComplaintParsed,TriageNotesOrig,ClinicalImpression, sep = " ------------------- ") # Combine columns into a single text column

  
data_test$text <- str_replace_all(data_test$text, "\\s+", " ")
  
data_test$Indicator <- as.numeric(data_test$Indicator)
  
 


Sys_ER_combined <- bind_rows(Sys_ER_combined, data_test[,c(2,3)])

write_parquet(Sys_ER_combined, "K:/SYS NLP/Data/sys_er_combined.parquet")  


suppressPackageStartupMessages({
  library(DBI)
  library(odbc)
  library(dbplyr)
})

####              create connection                  ####
#########################################################

#  An ODBC driver uses the Open Database Connectivity (ODBC) interface by Microsoft  #
#  that allows applications to access data in database management systems (DBMS)     #
#  using SQL as a standard for accessing the data.                                   #


con <- dbConnect(odbc(),
                 Driver   = "SQL Server",
                 Server   = "dhhsessencesql1.stone.ne.gov",
                 Database = "NE_ESSENCE5_Detection", 
                 UID    = "mssqladmin",
                 PWD    = "CPadmin!1",
                 port   = 1433)


con2 <- dbConnect(odbc(),
                  Driver   = "SQL Server",
                  Server   = "nedssqlag1.stone.ne.gov",
                  Database = "ER_SURVEILLANCE_PROD", 
                  UID    = "syndromicprod",
                  PWD    = "pE#R2dN",
                  port   = 1433)




####            query db & create df                ####
########################################################

sys_ed_df <- tbl(con, "View_Cache_ER_Base") |>
  select(Date, ErRecordID, Age, DischargeDiagnosis, ChiefComplaintParsed, TriageNotesOrig, ClinicalImpression, HasBeenE, Region) |>
  filter(between(Date, as.Date("2024-07-01"), as.Date("2024-07-31")) & HasBeenE == 1 & between(Age, 16, 80)) |>
  collect() |>
  arrange(Date) |>
  filter(Region != "OTHER_Region") |>
  select(-c(Date, HasBeenE, Region))


sys_ed_df$ChiefComplaintParsed <- str_to_lower(sys_ed_df$ChiefComplaintParsed)
sys_ed_df$TriageNotesOrig <- str_to_lower(sys_ed_df$TriageNotesOrig)
sys_ed_df$ClinicalImpression <- str_to_lower(sys_ed_df$ClinicalImpression)
sys_ed_df$TriageNotesOrig <- sub(" past medical / surgical .*", "", sys_ed_df$TriageNotesOrig)


data_test <- sys_ed_df |> 
  mutate(DischargeDiagnosis = str_replace_all(DischargeDiagnosis, ";", " "), 
         DischargeDiagnosis = str_remove_all(DischargeDiagnosis, "\\.")) |>
  unite("text", DischargeDiagnosis,ChiefComplaintParsed,TriageNotesOrig,ClinicalImpression, sep = " ------------------- ") # Combine columns into a single text column


data_test$text <- str_replace_all(data_test$text, "\\s+", " ")

data_test$Indicator <- NA

data_test$Indicator <- as.numeric(data_test$Indicator)

write_parquet(data_test, "K:/SYS NLP/Data/data_test.parquet")



ohquery_val_8_26_2024 <- read_csv("Broad Query Validation_26Aug2024.csv")

ohquery_val_8_26_2024 <- slice_sample(ohquery_val_8_26_2024, n=300)

write_csv(ohquery_val_8_26_2024, "Broad Query Validation_26Aug2024 random_sample.csv")



oc_reviewed <- readxl::read_xlsx("Broad Query Validation_26Aug2024 random_sample.xlsx", sheet = 2)
  

ohquery_val_8_26_2024 <- ohquery_val_8_26_2024 |>
  left_join(oc_reviewed[, c(1:2, 10,11)], by = c("ErRecordID", "MedRecNo")) |>
  select(-1,-2) |>
  rename(Note = Note.y, Validation = Validation.y) |>
  select(22,23,1:21)

write_csv(ohquery_val_8_26_2024, "Broad Query Validation_26Aug2024 CMA reviewed.csv")

