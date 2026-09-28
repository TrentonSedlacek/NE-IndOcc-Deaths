library(tidycensus)
library(tidyverse)
library(dplyr)
library(srvyr)
census_api_key("fda55d10ae1222ea2b997924b0baee5d4185a81a", install = TRUE)
pums_data <- get_pums(
  variables = c("AGEP", "ESR", "OCCP", "NAICSP", "WKHP", "COW"),
  survey = "acs5",  
  year = 2022,
  state = "NE",        # use your state or remove for all
  recode = TRUE,
  rep_weights = "person",
  show_call = TRUE
)

# Filter: Civilian Employed Population 16+
pums_filtered <- pums_data %>%
  filter(AGEP >= 16, ESR %in% c(1, 2))  # Employed civilians only


pums_filtered$NAICSP<-  strtrim(pums_filtered$NAICSP, 2)

pums_filtered <- pums_filtered |> 
  mutate(NAICSP=ifelse(pums_filtered$NAICSP == "31", str_replace(NAICSP, "\\b31\\b", "31-33"), NAICSP))|> 
  mutate(NAICSP=ifelse(pums_filtered$NAICSP == "32", str_replace(NAICSP, "\\b32\\b", "31-33"), NAICSP))|> 
  mutate(NAICSP=ifelse(pums_filtered$NAICSP == "33", str_replace(NAICSP, "\\b33\\b", "31-33"), NAICSP))|> 
  mutate(NAICSP=ifelse(pums_filtered$NAICSP == "3M", str_replace(NAICSP, "\\b3M\\b", "31-33"), NAICSP)) |>
  mutate(NAICSP=ifelse(pums_filtered$NAICSP == "44", str_replace(NAICSP, "\\b44\\b", "44-45"), NAICSP))|> 
  mutate(NAICSP=ifelse(pums_filtered$NAICSP == "45", str_replace(NAICSP, "\\b45\\b", "44-45"), NAICSP))|> 
  mutate(NAICSP=ifelse(pums_filtered$NAICSP == "4M", str_replace(NAICSP, "\\b4M\\b", "44-45"), NAICSP))|> 
  mutate(NAICSP=ifelse(pums_filtered$NAICSP == "48", str_replace(NAICSP, "\\b48\\b", "48-49"), NAICSP)) |>
  mutate(NAICSP=ifelse(pums_filtered$NAICSP == "49", str_replace(NAICSP, "\\b49\\b", "48-49"), NAICSP))

#Non-FTE adjusted 

# Convert to survey design with replicate weights
pums_survey <- to_survey(
  pums_filtered,
  type = c("person", "housing"),
  class = c("srvyr", "survey"),
  design = "rep_weights"
)

# Summarize: Employment count by Industry and Occupation
s2405_summary <- pums_survey %>%
  group_by(NAICSP) %>%
  summarize(
    estimate = survey_total(na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(estimate))
View(s2405_summary)
employees <- s2405_summary |> 
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
View(employees)
employees <- employees |> 
  select(1, 4, 2, 3)


#FTE adjusted

pums_filtered <- pums_filtered |>
  mutate(WKHP = WKHP/40) |>                           # divided work hours by 40 
  mutate_at(vars(starts_with("PWGTP")), list( ~ . * WKHP))   # multiply PWGTP by WKHP to get estimated FTE for each respondent. 

# Convert to survey design with replicate weights
pums_survey <- to_survey(
  pums_filtered,
  type = "person",
  class = "srvyr",
  design = "rep_weights"
)

# Summarize: Employment count by Industry and Occupation
s2405_sum <- pums_survey %>%
  group_by(NAICSP) %>%
  summarize(
    estimate = survey_total(na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(estimate))

employees <- s2405_sum|> 
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

employees <- employees |> 
  select(1, 4, 2, 3)

employed<- employees  %>%
  mutate(MOE = estimate_se * 1.96) %>%
  mutate(r_MOE = ((estimate_se * 1.96) / estimate) * 100) %>%
  mutate(CV = (estimate_se / estimate) * 100)
View(employed)

write_csv(employed, "K:\\Occupational Health Grant\\Jean Kwizerimana\\FTE\\fte_ne_naics2_5y_2022.csv")


acs_data <- get_pums(
  variables = c("ESR", "WAGP", "INDP", "WKHP", "WKWN", "NAICSP"),  # Use WKWN
  survey = "acs1",
  year = 2023,
  state = "NE",  # or "all" for national data
  rep_weights = "person",
  recode = TRUE
)

acs_fte <- acs_data %>%
  filter( ESR %in% c(1, 2)) %>%
  filter(as.numeric(WKHP) >= 35) %>%       # full-time: 35+ hrs/week
  filter(as.numeric(WKWN) >= 50)   # year-round: 50–52 weeks

fte_by_industry <- acs_fte %>%
  group_by(NAICSP) %>%
  summarise(FTE_estimate = sum(PWGTP, na.rm = TRUE)) %>%
  arrange(desc(FTE_estimate))

fte_by_industry$NAICSP<-  strtrim(fte_by_industry$NAICSP, 2)

pums_filter <- fte_by_industry |> 
  mutate(NAICSP=ifelse(fte_by_industry$NAICSP == "31", str_replace(NAICSP, "\\b31\\b", "31-33"), NAICSP))|> 
  mutate(NAICSP=ifelse(fte_by_industry$NAICSP == "32", str_replace(NAICSP, "\\b32\\b", "31-33"), NAICSP))|> 
  mutate(NAICSP=ifelse(fte_by_industry$NAICSP == "33", str_replace(NAICSP, "\\b33\\b", "31-33"), NAICSP))|> 
  mutate(NAICSP=ifelse(fte_by_industry$NAICSP == "3M", str_replace(NAICSP, "\\b3M\\b", "31-33"), NAICSP)) |>
  mutate(NAICSP=ifelse(fte_by_industry$NAICSP == "44", str_replace(NAICSP, "\\b44\\b", "44-45"), NAICSP))|> 
  mutate(NAICSP=ifelse(fte_by_industry$NAICSP == "45", str_replace(NAICSP, "\\b45\\b", "44-45"), NAICSP))|> 
  mutate(NAICSP=ifelse(fte_by_industry$NAICSP == "4M", str_replace(NAICSP, "\\b4M\\b", "44-45"), NAICSP))|> 
  mutate(NAICSP=ifelse(fte_by_industry$NAICSP == "48", str_replace(NAICSP, "\\b48\\b", "48-49"), NAICSP)) |>
  mutate(NAICSP=ifelse(fte_by_industry$NAICSP == "49", str_replace(NAICSP, "\\b49\\b", "48-49"), NAICSP))




employees_fte <-pums_filter  |> 
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
View(employees_fte)
employees <- employees |> 
  select(1, 2, 4, 3)
View(employees)








