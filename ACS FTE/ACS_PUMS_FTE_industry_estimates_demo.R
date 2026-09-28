library(tidyverse)
library(tidycensus)
library(srvyr, warn.conflicts = FALSE)

# Variables used
"INDP"     # Industry recode for 2018 and later based on 2017 IND codes
"NAICSP"   # (NAICS) recode for 2018 and later based on 2017 NAICS codes
"WKHP"     # Usual hours worked per week past
"ESR"      # Employment status recode
"COW"      # Class of worker   



# Fetch ACS microdata for Nebraska
ne_pums_rep_weights5_2021 <- get_pums(
  variables = c("AGEP", "SEX", "RAC1P", "HISP", "SCHL", "WKL", "NAICSP", "INDP", "WKHP", "COW", "ESR"),
  state = "NE",
  survey = "acs5",
  year = 2021, 
  recode = TRUE, 
  rep_weights = "person"
)


# Filter for civilian employed (ages 16-70)
ne_pums_rep_weights5_2021 <- ne_pums_rep_weights5_2021 |>
  filter(ESR %in% c(1,2)) |>    # Civilian employed
  filter(AGEP <= 70)            # Working age


# calc age group variable
ne_pums_rep_weights5_2021 <- ne_pums_rep_weights5_2021 |> 
  mutate(age_group = case_when(
    AGEP %in% 16:29 ~ "16-29",
    AGEP %in% 30:39 ~ "30-39",
    AGEP %in% 40:49 ~ "40-49",
    AGEP %in% 50:59 ~ "50-59",
    AGEP %in% 60:70 ~ "60-70"
  )
)


# calc race-ethnicity
ne_pums_rep_weights5_2021 <- ne_pums_rep_weights5_2021 |> 
  mutate(race_ethnicity = case_when(
    RAC1P_label == "White alone" & HISP_label == "Not Spanish/Hispanic/Latino" ~ "White, non-Hispanic",
    RAC1P_label == "Black or African American alone" & HISP_label == "Not Spanish/Hispanic/Latino" ~ "Black, non-Hispanic",
    HISP_label != "Not Spanish/Hispanic/Latino" ~ "Hispanic",
    TRUE ~  "Other"
  )
)    
    
# calc education level
ne_pums_rep_weights5_2021 <- ne_pums_rep_weights5_2021 |> 
  mutate(education = case_when(
    SCHL_label %in% c("Regular high school diploma", "GED or alternative credential") ~ "High School",
    SCHL_label %in% c("Associate's degree", "Bachelor's degree", "Master's degree", "Doctorate degree", "Professional degree beyond a bachelor's degree",
           "Some college, but less than 1 year", "1 or more years of college credit, no degree") ~ "Some College Credits or Higher",
    TRUE  ~ "Less than High School"
  )
  )    


  


# Create a copy for NAICS 2-digit sector FTE calculations
ne_pums_rep_weights5_naics2_2021 <- ne_pums_rep_weights5_2021

# Adjust NAICS codes to 2-digit sectors
ne_pums_rep_weights5_naics2_2021$NAICSP <- strtrim(ne_pums_rep_weights5_naics2_2021$NAICSP, 2)

ne_pums_rep_weights5_naics2_2021 <- ne_pums_rep_weights5_naics2_2021 |> 
  mutate(NAICSP = case_when(
    NAICSP %in% c("31", "32", "33", "3M") ~ "31-33",
    NAICSP %in% c("44", "45", "4M") ~ "44-45",
    NAICSP %in% c("48", "49") ~ "48-49",
    TRUE ~ NAICSP
  ))


# Create survey design object and calculate employee estimates
ne_survey_pums5_naics2_2021 <- to_survey(ne_pums_rep_weights5_naics2_2021) |> 
  survey_count(NAICSP) |> 
  mutate(
    MOE = n_se * 1.96,
    r_MOE = (n_se * 1.96 / n) * 100,
    CV = (n_se / n) * 100
  )


# FTE adjusted calculations for total workers per industry sectors
fte_ne_pums_rep_weights5_naics2_2021 <- ne_pums_rep_weights5_naics2_2021 |> 
  mutate(WKHP = WKHP / 40) |>                           # Convert work hours to FTE
  mutate_at(vars(starts_with("PWGTP")), list(~ . * WKHP))   # Adjust weights for FTE

# Create survey design object and calculate FTE adjusted estimates
fte_ne_survey_pums5_naics2_2021 <- to_survey(fte_ne_pums_rep_weights5_naics2_2021) |> 
  survey_count(NAICSP) |> 
  mutate(
    MOE = n_se * 1.96,
    r_MOE = (n_se * 1.96 / n) * 100,
    CV = (n_se / n) * 100
  )

fte_ne_survey_pums5_naics2_2021 <- fte_ne_survey_pums5_naics2_2021 |> 
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

fte_ne_survey_pums5_naics2_2021 <- fte_ne_survey_pums5_naics2_2021 |>
  select(1,7,2:6)


write_csv(fte_ne_survey_pums5_naics2_2021, "fte_ne_naics2_2021.csv")






# fte calculations for industry and sex

ne_pums_rep_weights5_naics2_2021_sex <- ne_pums_rep_weights5_2021

# Adjust NAICS codes to 2-digit sectors
ne_pums_rep_weights5_naics2_2021_sex$NAICSP <- strtrim(ne_pums_rep_weights5_naics2_2021_sex$NAICSP, 2)

ne_pums_rep_weights5_naics2_2021_sex <- ne_pums_rep_weights5_naics2_2021_sex |> 
  mutate(NAICSP = case_when(
    NAICSP %in% c("31", "32", "33", "3M") ~ "31-33",
    NAICSP %in% c("44", "45", "4M") ~ "44-45",
    NAICSP %in% c("48", "49") ~ "48-49",
    TRUE ~ NAICSP
  ))

# Create survey design object and calculate employee estimates
ne_survey_pums5_naics2_2021_sex <- to_survey(ne_pums_rep_weights5_naics2_2021_sex) |> 
  survey_count(NAICSP, SEX_label) |> 
  mutate(
    MOE = n_se * 1.96,
    r_MOE = (n_se * 1.96 / n) * 100,
    CV = (n_se / n) * 100
  )

# FTE adjusted calculations
fte_ne_pums_rep_weights5_naics2_2021_sex <- ne_pums_rep_weights5_naics2_2021_sex |> 
  mutate(WKHP = WKHP / 40) |>                           # Convert work hours to FTE
  mutate_at(vars(starts_with("PWGTP")), list(~ . * WKHP))   # Adjust weights for FTE

# Create survey design object and calculate FTE adjusted estimates
fte_ne_survey_pums5_naics2_2021_sex <- to_survey(fte_ne_pums_rep_weights5_naics2_2021_sex) |> 
  survey_count(NAICSP, SEX_label) |> 
  mutate(
    MOE = n_se * 1.96,
    r_MOE = (n_se * 1.96 / n) * 100,
    CV = (n_se / n) * 100
  )

fte_ne_survey_pums5_naics2_2021_sex <- fte_ne_survey_pums5_naics2_2021_sex |> 
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

fte_ne_survey_pums5_naics2_2021_sex <- fte_ne_survey_pums5_naics2_2021_sex |>
  select(1,8,2:7)


write_csv(fte_ne_survey_pums5_naics2_2021_sex, "fte_ne_naics2_2021_sex.csv")




# fte calculations for industry and age groups

ne_pums_rep_weights5_naics2_age_grps <- ne_pums_rep_weights5_2021

# Adjust NAICS codes to 2-digit sectors
ne_pums_rep_weights5_naics2_age_grps$NAICSP <- strtrim(ne_pums_rep_weights5_naics2_age_grps$NAICSP, 2)

ne_pums_rep_weights5_naics2_age_grps <- ne_pums_rep_weights5_naics2_age_grps |> 
  mutate(NAICSP = case_when(
    NAICSP %in% c("31", "32", "33", "3M") ~ "31-33",
    NAICSP %in% c("44", "45", "4M") ~ "44-45",
    NAICSP %in% c("48", "49") ~ "48-49",
    TRUE ~ NAICSP
  ))

# Create survey design object and calculate employee estimates
ne_survey_pums5_naics2_2021_age_grps <- to_survey(ne_pums_rep_weights5_naics2_age_grps) |> 
  survey_count(NAICSP, age_group) |> 
  mutate(
    MOE = n_se * 1.96,
    r_MOE = (n_se * 1.96 / n) * 100,
    CV = (n_se / n) * 100
  )

# FTE adjusted calculations
fte_ne_pums_rep_weights5_naics2_age_grps <- ne_pums_rep_weights5_naics2_age_grps |> 
  mutate(WKHP = WKHP / 40) |>                           # Convert work hours to FTE
  mutate_at(vars(starts_with("PWGTP")), list(~ . * WKHP))   # Adjust weights for FTE

# Create survey design object and calculate FTE adjusted estimates
fte_ne_survey_pums5_naics2_2021_age_grps <- to_survey(fte_ne_pums_rep_weights5_naics2_age_grps) |> 
  survey_count(NAICSP, age_group) |> 
  mutate(
    MOE = n_se * 1.96,
    r_MOE = (n_se * 1.96 / n) * 100,
    CV = (n_se / n) * 100
  )

fte_ne_survey_pums5_naics2_2021_age_grps <- fte_ne_survey_pums5_naics2_2021_age_grps |> 
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

fte_ne_survey_pums5_naics2_2021_age_grps <-fte_ne_survey_pums5_naics2_2021_age_grps |>
  select(1,8,2:7)

write_csv(fte_ne_survey_pums5_naics2_2021_age_grps, "fte_ne_naics2_2021_age_grps.csv")




# fte calculations for industry and race-ethnicity

ne_pums_rep_weights5_naics2_race_ethn <- ne_pums_rep_weights5_2021

# Adjust NAICS codes to 2-digit sectors
ne_pums_rep_weights5_naics2_race_ethn$NAICSP <- strtrim(ne_pums_rep_weights5_naics2_race_ethn$NAICSP, 2)

ne_pums_rep_weights5_naics2_race_ethn <- ne_pums_rep_weights5_naics2_race_ethn |> 
  mutate(NAICSP = case_when(
    NAICSP %in% c("31", "32", "33", "3M") ~ "31-33",
    NAICSP %in% c("44", "45", "4M") ~ "44-45",
    NAICSP %in% c("48", "49") ~ "48-49",
    TRUE ~ NAICSP
  ))

# Create survey design object and calculate employee estimates
ne_survey_pums5_naics2_2021_race_ethn <- to_survey(ne_pums_rep_weights5_naics2_race_ethn) |> 
  survey_count(NAICSP, race_ethnicity) |> 
  mutate(
    MOE = n_se * 1.96,
    r_MOE = (n_se * 1.96 / n) * 100,
    CV = (n_se / n) * 100
  )

# FTE adjusted calculations
fte_ne_pums_rep_weights5_naics2_race_ethn <- ne_pums_rep_weights5_naics2_race_ethn |> 
  mutate(WKHP = WKHP / 40) |>                           # Convert work hours to FTE
  mutate_at(vars(starts_with("PWGTP")), list(~ . * WKHP))   # Adjust weights for FTE

# Create survey design object and calculate FTE adjusted estimates
fte_ne_survey_pums5_naics2_2021_race_ethn <- to_survey(fte_ne_pums_rep_weights5_naics2_race_ethn) |> 
  survey_count(NAICSP, race_ethnicity) |> 
  mutate(
    MOE = n_se * 1.96,
    r_MOE = (n_se * 1.96 / n) * 100,
    CV = (n_se / n) * 100
  )

fte_ne_survey_pums5_naics2_2021_race_ethn <- fte_ne_survey_pums5_naics2_2021_race_ethn |> 
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


fte_ne_survey_pums5_naics2_2021_race_ethn <- fte_ne_survey_pums5_naics2_2021_race_ethn |>
  select(1,8,2:7)

write_csv(fte_ne_survey_pums5_naics2_2021_race_ethn, "fte_ne_naics2_2021_race_ethnicity.csv")



# fte calculations for industry and education level

ne_pums_rep_weights5_naics2_educ <- ne_pums_rep_weights5_2021

# Adjust NAICS codes to 2-digit sectors
ne_pums_rep_weights5_naics2_educ$NAICSP <- strtrim(ne_pums_rep_weights5_naics2_educ$NAICSP, 2)

ne_pums_rep_weights5_naics2_educ <- ne_pums_rep_weights5_naics2_educ |> 
  mutate(NAICSP = case_when(
    NAICSP %in% c("31", "32", "33", "3M") ~ "31-33",
    NAICSP %in% c("44", "45", "4M") ~ "44-45",
    NAICSP %in% c("48", "49") ~ "48-49",
    TRUE ~ NAICSP
  ))

# Create survey design object and calculate employee estimates
ne_survey_pums5_naics2_2021_educ <- to_survey(ne_pums_rep_weights5_naics2_educ) |> 
  survey_count(NAICSP, education) |> 
  mutate(
    MOE = n_se * 1.96,
    r_MOE = (n_se * 1.96 / n) * 100,
    CV = (n_se / n) * 100
  )

# FTE adjusted calculations
fte_ne_pums_rep_weights5_naics2_educ <- ne_pums_rep_weights5_naics2_educ |> 
  mutate(WKHP = WKHP / 40) |>                           # Convert work hours to FTE
  mutate_at(vars(starts_with("PWGTP")), list(~ . * WKHP))   # Adjust weights for FTE

# Create survey design object and calculate FTE adjusted estimates
fte_ne_survey_pums5_naics2_2021_educ <- to_survey(fte_ne_pums_rep_weights5_naics2_educ) |> 
  survey_count(NAICSP, education) |> 
  mutate(
    MOE = n_se * 1.96,
    r_MOE = (n_se * 1.96 / n) * 100,
    CV = (n_se / n) * 100
  )

fte_ne_survey_pums5_naics2_2021_educ <- fte_ne_survey_pums5_naics2_2021_educ |> 
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

fte_ne_survey_pums5_naics2_2021_educ <- fte_ne_survey_pums5_naics2_2021_educ |>
  select(1,8,2:7)

write_csv(fte_ne_survey_pums5_naics2_2021_educ, "fte_ne_naics2_2021_education.csv")



ne_pums_rep_weights5_2021 |>
  group_by(COW_label) |>
  count()
  summarise(freq = sum(n))


