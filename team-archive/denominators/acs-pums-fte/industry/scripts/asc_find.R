library(tidycensus)
library(dplyr)
# Download microdata
ne_pums <- get_pums(
  variables = c("OCCP", "INDP", "AGEP", "ESR", "PWGTP", "NAICSP", "WKHP"),
  state = "NE",
  survey = "acs5",
  year = 2023, 
  rep_weights= "person"
)

# Keep employed civilians 16 and older
ne_employed <- ne_pums %>%
  filter(AGEP >= 16, ESR %in% c(1, 2))
#%>%
  #filter(WKHP>=35)%>%
  #filter(WKW %in% c(1,2))
fte <- ne_employed
fte$NAICSP<-  strtrim(fte$NAICSP, 2)
fte_table<- fte |> 
  mutate(NAICSP=ifelse(fte$NAICSP == "31", str_replace(NAICSP, "\\b31\\b", "31-33"), NAICSP))|> 
  mutate(NAICSP=ifelse(fte$NAICSP == "32", str_replace(NAICSP, "\\b32\\b", "31-33"), NAICSP))|> 
  mutate(NAICSP=ifelse(fte$NAICSP == "33", str_replace(NAICSP, "\\b33\\b", "31-33"), NAICSP))|> 
  mutate(NAICSP=ifelse(fte$NAICSP == "3M", str_replace(NAICSP, "\\b3M\\b", "31-33"), NAICSP)) |>
  mutate(NAICSP=ifelse(fte$NAICSP == "44", str_replace(NAICSP, "\\b44\\b", "44-45"), NAICSP))|> 
  mutate(NAICSP=ifelse(fte$NAICSP == "45", str_replace(NAICSP, "\\b45\\b", "44-45"), NAICSP))|> 
  mutate(NAICSP=ifelse(fte$NAICSP == "4M", str_replace(NAICSP, "\\b4M\\b", "44-45"), NAICSP))|> 
  mutate(NAICSP=ifelse(fte$NAICSP == "48", str_replace(NAICSP, "\\b48\\b", "48-49"), NAICSP)) |>
  mutate(NAICSP=ifelse(fte$NAICSP == "49", str_replace(NAICSP, "\\b49\\b", "48-49"), NAICSP))

### employee estimates (not fte adjusted) ###
employ <- to_survey(fte_table) |> 
  survey_count(NAICSP) |> 
  mutate(
    MOE = n_se * 1.96,
    r_MOE = (n_se * 1.96 / n) * 100,
    CV = (n_se / n) * 100
  )

employed <- employ |> 
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

employees<- employed |> 
  select(1, 7, 2, 3, 4, 5, 6)


# FTE adjusted calculations for total workers per industry sectors
ne_fte <- fte_table |> 
  mutate(WKHP = WKHP / 40) |>                           # Convert work hours to FTE
  mutate_at(vars(starts_with("PWGTP")), list(~ . * WKHP))   # Adjust weights for FTE
# Create survey design object and calculate FTE adjusted estimates
fte <- to_survey(ne_fte ) |> 
  survey_count(NAICSP) |> 
  mutate(
    MOE = n_se * 1.96,
    r_MOE = (n_se * 1.96 / n) * 100,
    CV = (n_se / n) * 100
  )

fte_employees <- fte  |> 
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

employees_fte <- fte_employees |> 
  select(1, 7, 2, 3, 4, 5, 6)

