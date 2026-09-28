suppressPackageStartupMessages({
  
  install.packages("DBI")
  library(DBI)          # Database interface for R
  library(odbc)         # DBI-compliant interface to database drivers
  library(tidyverse)    # Collection of packages designed for data science
  library(lubridate)    # Date and time manipulation
  library(dbplyr)       # Database backend for dplyr
  install.packages("dbplyr")
  library(arrow)        # Interface to Apache Arrow
  library(ggplot2)
  install.packages("readxl")
  library(readxl)
})
setwd("K:/Occupational Health Grant/Jean Kwizerimana/poison/pcc data")
pcc1<-read_excel("pcc_finalized.xlsx")
pcc<-read.csv("poisoncenter.poisoncasedetails.csv")
pcc2<-read.csv("poisoncenter.poisoncasedetails.ft.substance.csv")
pcc3<-read.csv("poisoncenter.substance.csv")
codedesc <- read_xlsx("Code values for NE Case Detail Web Service.xlsx",  sheet = "Generic Codes", skip = 2)
codedesc <- codedesc %>% select(-`...12`, -`...13`)
old_data <-read.csv("K:\\Occupational Health Grant\\Jean Kwizerimana\\poison\\poisoncenter.poisoncasedetails.ft.substance.csv")

names(codedesc)[names(codedesc) == "Generic Code"] <- "genericCode"
codedesc$genericCode <- as.integer(codedesc$genericCode)

names_pcc <- names(pcc)
names_pcc2 <- names(pcc2)
names_pcc3 <- names(pcc3)
names_pccfull <-names(pcc_full)
names_pccfully <-names(pcc_fully)
names_codedesc <- names(codedesc)
names_final <- names(pcc_final)
#finding common variables
common_var <- Reduce(intersect, list(names_pcc3, names_pccfully))
# Convert both to character, for example:
pcc_full$caseID <- as.character(pcc_full$caseID)
pcc3$caseID <- as.character(pcc3$caseID)




#joining datasets

pcc_full <- full_join(pcc, pcc2, by = "caseID")
length(pcc_full)

pcc_full <- pcc_full %>%
  select(caseID, everything(), -ends_with(".y")) %>% # Keep .x or original columns
  rename_with(~ gsub("\\.x$", "", .), ends_with(".x"))

diff_pcc_to_pcc2 <- setdiff(  names_pcc,names_pccfull)


# Check for duplicates in pcc3
duplicates_pcc3 <- pcc3 %>%
  group_by(caseID) %>%
  filter(n() > 1) %>%
  summarize(Count = n())

# Check for duplicates in pcc_full
duplicates_pcc_full <- pcc_full %>%
  group_by(caseID) %>%
  filter(n() > 1) %>%
  summarize(Count = n())

#  keep the first occurrence in pcc_full
pcc3_unique <- pcc3 %>%
  distinct(caseID, .keep_all = TRUE)
pcc_ful <- full_join(pcc_full,pcc3_unique,  by = "caseID")


# Select columns and keep only one instance of duplicates
pcc_fully <- pcc_ful %>%
  select(caseID, everything(), -ends_with(".y")) %>%  # Keep .x or original columns
  rename_with(~ gsub("\\.x$", "", .), ends_with(".x"))

pcc_final <- left_join(pcc_fully,codedesc,  by = "genericCode")

common_var <- intersect(names_codedesc, names_final)
diff_pcc_to_pcc2 <- setdiff( names_pccfully, names_final)

write.csv(pcc_final, file = "K:/Occupational Health Grant/Jean Kwizerimana/poison/pcc_fully.csv", row.names = FALSE)

install.packages("openxlsx")
library(openxlsx)
write.xlsx(pcc_final, "K:/Occupational Health Grant/Jean Kwizerimana/poison/pcc data/pcc_finalized.xlsx")

library(ggplot2)
library(lubridate)

# Ensure startCalendar is a date type
pcc_final$startCalendar <- as.Date(pcc_final$startCalendar)

# Extract the year
pcc_final$year <- year(pcc_final$startCalendar)

# Plot the frequency by year
ggplot(pcc_final, aes(x = year)) +
  geom_bar() +
  geom_text(stat='count', aes(label=..count..), vjust=-0.5) +
  labs(title = "Frequency of startCalendar by Year",
       x = "Year",
       y = "Frequency") +
  theme_minimal()

pcc3$startCalendar <- as.Date(pcc3$startCalendar)

# Find the last date
first_date <- max(pcc3$startCalendar, na.rm = TRUE)
print(first_date)





pcc2<-read.csv("poisoncenter.poisoncasedetails.ft.substance.csv")
pcc2$startCalendar <- as.Date(pcc2$startCalendar)

# Find the last date
last_date <- max(pcc2$startCalendar)
print(last_date)


sorted <- pcc2 %>% arrange(desc(startCalendar))




































