

#########################################################
#######                                           #######
#######             Industry ACS 5y PUMS          #######
#######                                           #######
#########################################################


setwd("K:\\Occupational Health Grant\\Chris Austin\\ACS FTE\\Outputs")
a.2014<- read.csv("fte5y_ne_naics2_2014.csv")
a.2015<- read.csv("fte5y_ne_naics2_2015.csv")
a.2016<- read.csv("fte5y_ne_naics2_2016.csv")
a.2017<- read.csv("fte5y_ne_naics2_2017.csv")
a.2018<- read.csv("FTE_2018_PUMS_1y_naics2.csv")
a.2019<- read.csv("FTE_2019_PUMS_5y_naics2.csv")
a.2020<- read.csv("FTE_2020_PUMS_5y_naics2.csv")
a.2021<- read.csv("FTE_2021_PUMS_1y_naics2.csv")
a.2022<- read.csv("fte_ne_naics2_5y_2022.csv")
a.2023<- read.csv("fte_ne_naics2_5y_2023.csv")
library(dplyr)

a.2018 <- a.2018 %>% rename(n = FTE_estimate)
a.2019 <- a.2019 %>% rename(n = FTE_estimate)
a.2020 <- a.2020 %>% rename(n = FTE_estimate)
a.2021 <- a.2021 %>% rename(n = FTE_estimate)
a.2022 <- a.2022 %>% rename(n =estimate)


a.2018 <- a.2018 %>% rename(NAICSP = NAICSP_2)
a.2019 <- a.2019 %>% rename(NAICSP = NAICSP_2)
a.2020 <- a.2020 %>% rename(NAICSP = NAICSP_2)
a.2021 <- a.2021 %>% rename(NAICSP = NAICSP_2)


a.2018 <- a.2018 %>% rename(n_se = FTE_estimate_se)
a.2019 <- a.2019 %>% rename(n_se = FTE_estimate_se)
a.2020 <- a.2020 %>% rename(n_se = FTE_estimate_se)
a.2021 <- a.2021 %>% rename(n_se = FTE_estimate_se)
a.2022 <- a.2022 %>% rename(n_se = estimate_se)


# Add year column and store in list
datasets <- list(
  mutate(a.2014, year = 2014),
  mutate(a.2015, year = 2015),
  mutate(a.2016, year = 2016),
  mutate(a.2017, year = 2017),
  mutate(a.2018, year = 2018),
  mutate(a.2019, year = 2019),
  mutate(a.2020, year = 2020),
  mutate(a.2021, year = 2021),
  mutate(a.2022, year = 2022),
  mutate(a.2023, year = 2023)
)

# Combine all into one dataset
combined_data <- bind_rows(datasets)

combined_data <- combined_data|> 
  mutate(Ind_sector = case_when(
    str_detect(NAICSP, "^11") ~ "Agriculture, Forestry, Fishing and Hunting",
    str_detect(NAICSP, "^21") ~ "Mining, Quarrying, and Oil and Gas Extraction",
    str_detect(NAICSP, "^22") ~ "Utilities",
    str_detect(NAICSP, "^23") ~ "Construction",
    str_detect(NAICSP, "^31-33") ~ "Manufacturing",
    str_detect(NAICSP, "^42") ~ "Wholesale Trade",
    str_detect(NAICSP, "^44-45") ~ "Retail Trade",
    str_detect(NAICSP, "^48-49") ~ "Transportation and Warehousing",
    str_detect(NAICSP, "^51") ~ "Information",
    str_detect(NAICSP, "^52") ~ "Finance and Insurance",
    str_detect(NAICSP, "^53") ~ "Real Estate and Rental and Leasing",
    str_detect(NAICSP, "^54") ~ "Professional, Scientific, and Technical Services",
    str_detect(NAICSP, "^55") ~ "Management of Companies and Enterprises",
    str_detect(NAICSP, "^56") ~ "Administrative and Support and Waste Management and Remediation Services",
    str_detect(NAICSP, "^61") ~ "Educational Services",
    str_detect(NAICSP, "^62") ~ "Health Care and Social Assistance",
    str_detect(NAICSP, "^71") ~ "Arts, Entertainment, and Recreation",
    str_detect(NAICSP, "^72") ~ "Accommodation and Food Services",
    str_detect(NAICSP, "^81") ~ "Other Services (except Public Administration)",
    str_detect(NAICSP, "^92") ~ "Public Administration"))

data_io_coded<- read.csv("K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\suicide data\\suicide_coded_data.csv")
data_io_coded$NAICS <- substr(data_io_coded$NAICSCode, 1, 2)
# Modify SOC column with specific replacements
data_io_coded <- data_io_coded %>%
  mutate(NAICS = case_when(
    NAICS %in% c(31, 32, 33) ~ "31-33",
    NAICS %in% c(44, 45) ~ "44-45",
    NAICS %in% c(48, 49) ~ "48-49",
    TRUE ~ as.character(NAICS)  # Keep other values unchanged
  ))
working_group <- data_io_coded %>% filter(AGEUNITS >= 16, NAICS != "00")

#  left join on NAICS
# Convert FTE_2023$SOC to character
working_group<- working_group %>% mutate(NAICSP = as.character(NAICS))
a.2014_c <- a.2014%>% mutate(NAICSP = as.character(NAICSP))
working_group$NAICSP <- working_group$NAICS

#industry category count by year
ind_suici_count_yr <- working_groups %>%
  group_by(NAICSP, DOD_YR, Ind_sector) %>%
  summarise(Count = n(), .groups = "drop") %>%
  arrange(DOD_YR, Ind_sector)

ind_suici_count_yr<-ind_suici_count_yr %>% rename(year=DOD_YR)

# Perform the left join
suicide_fte <- combined_data %>%
  left_join(ind_suici_count_yr, by = c("NAICSP", "year"))
#set NAs to Zero for no suicide
suicide_fte <- suicide_fte %>%
  mutate(Count = ifelse(is.na(Count), 0, Count))

#calculate count per 1000 fte
suicide_fte <- suicide_fte %>%
  mutate(
    suicide_per_1000_fte = round((Count / n) * 1000, 3),
    suicide_per_1000_fte_se = round(abs((Count * 1000) / (n^2)) * n_se, 3)
  )


# create wide table for suicide_per_1000_fte
# Step 1: create a combined column like "Count (Rate)"
suicide_fte <- suicide_fte %>%
  mutate(count_and_rate = paste0(Count, " (", suicide_per_1000_fte, ")"))

# Step 2: pivot wider using the combined column
wide_table <- suicide_fte %>%
  select(Ind_sector.x, year, count_and_rate) %>%
  pivot_wider(
    names_from = year,
    values_from = count_and_rate
  )

wide_table <- wide_table %>% rename(Industry =Ind_sector.x)

w_table <- suicide_fte %>%
  select(Ind_sector.x, year, Count, suicide_per_1000_fte) %>%
  pivot_wider(
    names_from = year,
    values_from = c(Count, suicide_per_1000_fte)
  )
cols <- colnames(w_table)[-1]
years <- unique(gsub(".*_(\\d+)", "\\1", cols))

ordered_cols <- as.vector(rbind(
  paste0("Count_", years),
  paste0("suicide_per_1000_fte_", years)
))

final_cols <- c("Ind_sector.x", ordered_cols)
w_table <- w_table[, final_cols]

write_csv(wide_table, "K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\suicide data\\suicide_fte_year.csv")
write_csv(w_table, "K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\suicide data\\suicide_fte_year_2.csv")

long_table <- w_table %>%
  pivot_longer(
    cols = -Ind_sector.x,
    names_to = c("metric", "year"),
    names_pattern = "(.*)_(\\d+)"
  ) %>%
  pivot_wider(
    names_from = metric,
    values_from = value
  ) %>%
  mutate(year = as.integer(year))

write_csv(long_table, "K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\suicide data\\suicide_fte_year_long.csv")

#########################################################
#######                                           #######
#######            Occupation ACS 5y PUMS         #######
#######                                           #######
#########################################################

setwd("K:\\Occupational Health Grant\\Jean Kwizerimana\\FTE\\Occupation")
b.2016<-read.csv("FTE_2016_PUMS_5y_soc2.csv")
b.2017<-read.csv("FTE_2017_PUMS_5y_soc2.csv")
b.2018<-read.csv("FTE_2018_PUMS_5y_soc2.csv")
b.2019<- read.csv("FTE_2019_PUMS_5y_soc2.csv")
b.2020 <- read.csv("FTE_2020_PUMS_5y_soc2.csv")
b.2021 <- read.csv("FTE_2021_PUMS_5y_soc2.csv")
b.2022 <- read.csv("FTE_2022_PUMS_5y_soc2.csv")
b.2023 <- read.csv("FTE_2023_PUMS_5y_soc2.csv")

# Add year column and store in list
datasets <- list(
  mutate(b.2016, year = 2016),
  mutate(b.2017, year = 2017),
  mutate(b.2018, year = 2018),
  mutate(b.2019, year = 2019),
  mutate(b.2020, year = 2020),
  mutate(b.2021, year = 2021),
  mutate(b.2022, year = 2022),
  mutate(b.2023, year = 2023)
)

# Combine all into one dataset
combined_data <- bind_rows(datasets)

#suicide dataset
data_io_coded<- read.csv("K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\suicide data\\suicide_coded_data.csv")
data_io_coded$SOCCode <- substr(data_io_coded$SOCCode, 1, 2)
working_group <- data_io_coded %>% filter(AGEUNITS >= 16, SOCCode != "00")

#  left join on NAICS
# Convert FTE_2023$SOC to character
working_group<- working_group %>% mutate(SOCCode = as.character(SOCCode))
occ_names <- read.csv("K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\ATV\\socc.csv")
occ_names<- occ_names%>% filter(SOC != "0")
occ_names <- occ_names %>% rename(SOCCode = SOC)
occ_names<- occ_names %>% mutate(SOCCode = as.character(SOCCode))

Occ_work <- occ_names %>%
  left_join(working_group, by = "SOCCode")
Occ_work<-Occ_work %>% rename(year=DOD_YR)

#industry category count by year
occ_suici_count_yr <- Occ_work %>%
  group_by(SOCCode, year, OccCategory) %>%
  summarise(Count = n(), .groups = "drop") %>%
  arrange(year, OccCategory)

combined_data <- combined_data %>% rename(SOCCode = SOCP)
combined_data<- combined_data %>% mutate(SOCCode = as.character(SOCCode))
# Perform the left join
occ_suicide_fte <- combined_data %>%
  left_join(occ_suici_count_yr, by = c("SOCCode", "year"))

#set NAs to Zero for no suicide
occ_suicide_fte <- occ_suicide_fte %>%
  mutate(Count = ifelse(is.na(Count), 0, Count))

#calculate count per 1000 fte
occ_suicide_fte <- occ_suicide_fte %>%
  mutate(
    suicide_per_1000_fte = round((Count / n) * 1000, 3),
    suicide_per_1000_fte_se = round(abs((Count * 1000) / (n^2)) * n_se, 3)
  )

# create wide table for suicide_per_1000_fte
# Step 1: create a combined column like "Count (Rate)"
occ_suicide_fte <- occ_suicide_fte %>%
  mutate(count_and_rate = paste0(Count, " (", suicide_per_1000_fte, ")"))

# Step 2: pivot wider using the combined column
library(tidyverse)
wide_table <- occ_suicide_fte %>%
  select(OccCategory.x, year, count_and_rate) %>%
  pivot_wider(
    names_from = year,
    values_from = count_and_rate
  )

wide_table <- wide_table %>% rename(Occupation =OccCategory.x)

w_table <- occ_suicide_fte %>%
  select(OccCategory.x, year, Count, suicide_per_1000_fte) %>%
  pivot_wider(
    names_from = year,
    values_from = c(Count, suicide_per_1000_fte)
  )
cols <- colnames(w_table)[-1]
years <- unique(gsub(".*_(\\d+)", "\\1", cols))

ordered_cols <- as.vector(rbind(
  paste0("Count_", years),
  paste0("suicide_per_1000_fte_", years)
))

final_cols <- c("OccCategory.x", ordered_cols)
w_table <- w_table[, final_cols]

write_csv(wide_table, "K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\suicide data\\occ_suicide_fte_year.csv")
write_csv(w_table, "K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\suicide data\\occ_suicide_fte_year_2.csv")

occ_long_table <- w_table %>%
  pivot_longer(
    cols = -OccCategory.x,
    names_to = c("metric", "year"),
    names_pattern = "(.*)_(\\d+)"
  ) %>%
  pivot_wider(
    names_from = metric,
    values_from = value
  ) %>%
  mutate(year = as.integer(year))

write_csv(occ_long_table, "K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\suicide data\\occ_suicide_fte_year_long.csv")

