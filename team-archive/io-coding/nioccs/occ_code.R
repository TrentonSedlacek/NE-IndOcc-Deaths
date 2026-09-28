library(readxl)
library(dplyr)
occ <- read_excel("K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\2002-census-occupation-codes.xls", sheet = "Sheet1")
atv<- read_excel("K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\atv_output.xls")
non_na_count <- sum(!is.na(atv$OccupationCode))
# Add a zero at the end of each value in atv$OccupationCode
# Add zero at the end of non-NA OccupationCode values
atv$OccupationCode <- ifelse(!is.na(atv$OccupationCode), paste0(atv$OccupationCode, "0"), atv$OccupationCode)

# Rename the column OccupationCode to Code
colnames(atv)[colnames(atv) == "OccupationCode"] <- "code"
colnames(occ)[colnames(occ) == "specific occupation"] <- "jobdescription"
# Left join to keep all rows from atv
merged_data <- merge(atv, occ, by = "code", all.x = TRUE)
non_na_count <- sum(!is.na(merged_data$code))
# Filter merged_data to keep only Code, occupation, and occupationlit
filtered_data <- merged_data %>%
  select(code, jobdescription, OccupationLIt)

filtered_atv <- atv %>%
  select(code, OccupationLIt) %>%
  filter(!is.na(code))

filtered_occ <- occ%>%
  select(code, jobdescription, occupation)

merged <- merge(filtered_atv, filtered_occ, by = "code", all.x = TRUE)

#coded dataset

coded_atv <- read.csv("K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\nioccs_atv.csv")
library(lubridate)

# Method 1: Using lubridate
date_converted <- format(as.Date("1956-01-04T00:00:00Z"), "%m/%d/%y")

# Method 2: Using base R
date_converted <- format(as.POSIXct("1956-01-04T00:00:00Z", format="%Y-%m-%dT%H:%M:%SZ"), "%m/%d/%y")

coded_atv <- coded_atv %>%
  mutate(
    dob = format(as.Date(DateOfBirth, format="%Y-%m-%dT%H:%M:%SZ"), "%m/%d/%Y"),
    dod = format(as.Date(DateOfDeath, format="%Y-%m-%dT%H:%M:%SZ"), "%m/%d/%Y")
  )
coded_atv$dob <- as.Date(coded_atv$dob, format = "%m/%d/%Y")
coded_atv$dod <- as.Date(coded_atv$dod, format = "%m/%d/%Y")

library(lubridate)

# Calculate age in years
# Calculate age in years and round to whole number
coded_atv$age <- round(as.numeric(difftime(coded_atv$dod, coded_atv$dob, units = "days") / 365.25), 0)
write_csv(coded_atv, "nioccs_atv.csv")
