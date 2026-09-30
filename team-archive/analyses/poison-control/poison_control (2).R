
################################################################################

##                              Load Libraries                                ##

################################################################################

# Suppress package startup messages to keep the console output clean
suppressPackageStartupMessages({
  library(DBI)          # Database interface for R
  library(odbc)         # DBI-compliant interface to database drivers
  library(tidyverse)    # Collection of packages designed for data science
  library(lubridate)    # Date and time manipulation
  library(dbplyr)       # Database backend for dplyr
  install.packages("dbplyr")
  library(arrow)        # Interface to Apache Arrow
})
options(scipen=999)  # Prevent scientific notation in output

# Load and preprocess Poison Control case details data
PoisonControlSubDet_df <- read.csv("K:\\Occupational Health Grant\\Jean Kwizerimana\\poison\\poisoncenter.poisoncasedetails.ft.substance.csv")
# Drop columns by index (perhaps sensitive or irrelevant data)
PoisonControlSubDet_df <- select(PoisonControlSubDet_df, -42, -95, -14)
# Remove commas from the formulationCode column to clean data
PoisonControlSubDet_df$formulationCode <- str_replace_all(PoisonControlSubDet_df$formulationCode, ",", "") 

# Load reference data from Excel file with different sheets
pcc_reference_gc <- readxl::read_xlsx("K:\\Occupational Health Grant\\Jean Kwizerimana\\poison\\pcc_reference_file.xlsx", sheet = 1)
pcc_reference_calllerSiteCode <- readxl::read_xlsx("K:\\Occupational Health Grant\\Jean Kwizerimana\\poison\\pcc_reference_file.xlsx", sheet = 2)

# Convert formulationCode from character to numeric after cleaning
PoisonControlSubDet_df$formulationCode <- as.numeric(PoisonControlSubDet_df$formulationCode)
PoisonControlSubDet_df$genericCode <- as.numeric(PoisonControlSubDet_df$genericCode)
pcc_reference_gc$genericCode <- as.numeric(pcc_reference_gc$genericCode)
# Convert startCalendar from character to Date format
PoisonControlSubDet_df$startCalendar <- as.Date(PoisonControlSubDet_df$startCalendar, format = "%Y-%m-%d")
pcc_reference_gc$

# Add several new columns using case_when to map codes to descriptive strings
PoisonControlSubDet_df <- PoisonControlSubDet_df |>
  mutate(
    acuityCodeValue = case_when(
      acuity == 1 ~ "Acute", 
      acuity == 2 ~ "Acute-on-chronic",
      acuity == 3 ~ "Chronic", 
      acuity == 4 ~ "Unknown"
    ),
    exposureDurationCodeValue = case_when(
      exposureDuration == 1 ~ ">8 hr <=24 hr",
      exposureDuration == 2 ~ ">24 hr <=1 week",
      # Further cases omitted for brevity
    ),
    # Other mutate functions omitted for brevity
  )

# Mapping clinical codes to descriptions
clinical_code_mapping <- c(
  "300" = "Bradycardia",
  "301" = "Cardiac arrest"
  # Further mappings omitted for brevity
)

# Assuming 'mydata' is your dataset
variable_names <- names(PoisonControlSubDet_df)
print(variable_names)


# Perform complex manipulations and join with reference data
PoisonControlSubDet_df2 <- PoisonControlSubDet_df |>
  left_join(pcc_reference_gc, by = "genericCode") |>
  left_join(pcc_reference_calllerSiteCode, by = "callersiteCode")

# Further processing to prepare for analysis or reporting
PoisonControlSubDet_df3 <- PoisonControlSubDet_df2 |>
  select(1,67,95,46,36,37,51,10,48,11,42,12,68,44,13,49,16,64,24,75,23,53,20,65,17,52,100,81,111,83,8,
         50,4,38,32,79,34,102,77,2,39,33,103,47,26,66,19, 41,35,87,88,94,90,91,97,92,93,96,99,100,101,102,103,98, 104:110,
         22,55,61,54,62,56,57,63,69,21,27:30, 1:111)

# Output processed data to CSV
write_csv(PoisonControlSubDet_df3, "PoisonControl_5_16_2024.csv")

# Example of creating time-series plots and handling NA values
pcc_form_carbdiox <- PoisonControlSubDet_df3 |>
  filter(genericCodeDesc %in% c("Carbon Dioxide", "Formaldehyde or Formalin")) |>
  group_by(startCalendar) |>
  count() |>
  ungroup() |>
  complete(startCalendar = seq.Date(as.Date("2019-01-01"), as.Date("2024-03-06"), by="day")) |>
  replace(is.na(.), 0) |> 
  ggplot(aes(startCalendar, n)) +
  geom_line(color = "#969696") +
  geom_point(color = "#33a02c", size = 2)

# The custom color palette for plotting
pal <- c("#969696", "#a6cee3","#1f78b4","#b2df8a","#33a02c","#fb9a99","#e31a1c","#fdbf6f","#ff7f00","#cab2d6","#6a3d9a","#ffff99","#b15928")

# Render an R Markdown document programmatically
rmarkdown::render("pcc_occupaitonal_ex_form_carbdiox.Rmd")




  
                                    
    












