library(tidyverse)
library(tidycensus)
library(srvyr, warn.conflicts = FALSE)

#clipr::write_clip()

census_api_key("fda55d10ae1222ea2b997924b0baee5d4185a81a", install = TRUE) # may need to get a new key

# get api key at http://api.census.gov/data/key_signup.html


View(pums_variables)  ## to view all the avaialve vars

"INDP"     # Industry recode for 2018 and later based on 2017 IND codes
"NAICSP"   # (NAICS) recode for 2018 and later based on 2017 NAICS codes
"WKHP"     # Usual hours worked per week past
"ESR"      # Employment status recode
"COW"      # Class of worker   

#########################################################
#######                                           #######
#######             2023 ACS 5y PUMS              #######
#######                                           #######
#########################################################
set.seed(2023)
ne_pums_rep_weights5_2023 <- get_pums(
  variables = c("AGEP", "NAICSP", "INDP", "WKHP", "COW", "ESR"),
  state = "NE",
  survey = "acs1",
  year = 2023, 
  recode = TRUE, 
  rep_weights = "person")

ne_pums_rep_weights5_2023 <- ne_pums_rep_weights5_2023

ne_pums_rep_weights5_2023 <- ne_pums_rep_weights5_2023 |>
  filter(ESR %in% c(1,2))    # civilian employed, this will results in ages >= 16 
                   

ne_pums_rep_weights5_naics3_2023 <- ne_pums_rep_weights5_2023 

ne_pums_rep_weights5_naics2_2023 <- ne_pums_rep_weights5_2023



#######    2023 NAICS 3   ########
#################################

ne_pums_rep_weights5_naics3_2023$NAICSP <- strtrim(ne_pums_rep_weights5_naics3_2023$NAICSP, 3)

ne_pums_rep_weights5_naics3_2023 <- ne_pums_rep_weights5_naics3_2023 |>
  filter(str_length(NAICSP) == 3)

ne_pums_rep_weights5_naics3_2023 <- ne_pums_rep_weights5_naics3_2023 |>
  filter(!NAICSP %in% c("33M","3MS", "4MS", "52M", "53M", "92M"))


### employee estimates (not fte adjusted) ###

ne_survey_pums5_naics3_2023 <- to_survey(ne_pums_rep_weights5_naics3_2023)   # create survey design object

ne_survey_pums5_naics3_2023 <- ne_survey_pums5_naics3_2023 |> 
  survey_count(NAICSP)       # calculate estimates w/ std errors

ne_survey_pums5_naics3_2023 <- ne_survey_pums5_naics3_2023 |>
  mutate(MOE = n_se * 1.96) |>
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) |>
  mutate(CV = (n_se / n) * 100)


######### FTE adjusted calculations  ###########

fte_ne_pums_rep_weights5_naics3_2023 <- ne_pums_rep_weights5_naics3_2023 |>
  mutate(WKHP = WKHP/40) |>                           # divided work hours by 40 
  mutate_at(vars(starts_with("PWGTP")), list( ~ . * WKHP))   # multiply PWGTP by WKHP to get estimated FTE for each respondent. 


fte_ne_survey_pums5_naics3_2023 <- to_survey(fte_ne_pums_rep_weights5_naics3_2023)   # create survey design object

fte_ne_survey_pums5_naics3_2023 <- fte_ne_survey_pums5_naics3_2023 |> 
  survey_count(NAICSP)   

fte_ne_survey_pums5_naics3_2023 <- fte_ne_survey_pums5_naics3_2023 |>
  mutate(MOE = n_se * 1.96) |>
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) |>
  mutate(CV = (n_se / n) * 100)



######## 2023 NAICS 2 ##########
################################

ne_pums_rep_weights5_naics2_2023$NAICSP <- strtrim(ne_pums_rep_weights5_naics2_2023$NAICSP, 2)


ne_pums_rep_weights5_naics2_2023 <- ne_pums_rep_weights5_naics2_2023 |> 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2023$NAICSP == "31", str_replace(NAICSP, "\\b31\\b", "31-33"), NAICSP))|> 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2023$NAICSP == "32", str_replace(NAICSP, "\\b32\\b", "31-33"), NAICSP))|> 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2023$NAICSP == "33", str_replace(NAICSP, "\\b33\\b", "31-33"), NAICSP))|> 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2023$NAICSP == "3M", str_replace(NAICSP, "\\b3M\\b", "31-33"), NAICSP)) |>
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2023$NAICSP == "44", str_replace(NAICSP, "\\b44\\b", "44-45"), NAICSP))|> 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2023$NAICSP == "45", str_replace(NAICSP, "\\b45\\b", "44-45"), NAICSP))|> 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2023$NAICSP == "4M", str_replace(NAICSP, "\\b4M\\b", "44-45"), NAICSP))|> 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2023$NAICSP == "48", str_replace(NAICSP, "\\b48\\b", "48-49"), NAICSP)) |>
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2023$NAICSP == "49", str_replace(NAICSP, "\\b49\\b", "48-49"), NAICSP))


### employee estimates (not fte adjusted) ###

ne_survey_pums5_naics2_2023 <- to_survey(ne_pums_rep_weights5_naics2_2023)   # create survey design object

ne_survey_pums5_naics2_2023 <- ne_survey_pums5_naics2_2023 |> 
  survey_count(NAICSP)
##my search
library(srvyr)

# Convert to srvyr object
ne_survey_srvyr <- as_survey(ne_survey_pums5_naics2_2023)

# Use survey_count without specifying weights (they're already in the object)
naics_counts <- ne_survey_srvyr %>%
  group_by(NAICSP) %>%
  survey_count()

naics_counts <- ne_survey_srvyr %>%
  group_by(NAICSP) %>%
  survey_count()


ne_survey_pums5_naics2_2023 <- ne_survey_pums5_naics2_2023 |>
  mutate(MOE = n_se * 1.96) |>
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) |>
  mutate(CV = (n_se / n) * 100)


######### FTE adjusted calculations  ###########

fte_ne_pums_rep_weights5_naics2_2023 <- ne_pums_rep_weights5_naics2_2023 |>
  mutate(WKHP = WKHP/40) |>                           # divided work hours by 40 
  mutate_at(vars(starts_with("PWGTP")), list( ~ . * WKHP))   # multiply PWGTP by WKHP to get estimated FTE for each respondent. 


fte_ne_survey_pums5_naics2_2023 <- to_survey(fte_ne_pums_rep_weights5_naics2_2023, class="survey", type="person", design="rep_weights")   # create survey design object
##my search
library(srvyr)

# Convert to srvyr object
ne_survey_srvyr <- as_survey(fte_ne_survey_pums5_naics2_2023)

# Use survey_count without specifying weights 
naics_counts <- ne_survey_srvyr %>%
  group_by(NAICSP) %>%
  survey_count()

naics_counts <- ne_survey_srvyr %>%
  group_by(NAICSP) %>%
  survey_count()

fte_ne_survey_pums5_naics2_2023 <- fte_ne_survey_pums5_naics2_2023 |> 
  survey_count(NAICSP)   

fte_ne_survey_pums5_naics2_2023 <- fte_ne_survey_pums5_naics2_2023 |>
  mutate(MOE = n_se * 1.96) |>
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) |>
  mutate(CV = (n_se / n) * 100)

employees <- naics_counts |> 
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

fte_ne_survey_pums5_naics2_2023 <- fte_ne_survey_pums5_naics2_2023 |>
  select(1,7,2:6)

write_csv(fte_ne_survey_pums5_naics2_2023, "K:\\Occupational Health Grant\\Jean Kwizerimana\\FTE\\fte_ne_naics2_5y_2023.csv")
write_csv(fte_ne_survey_pums5_naics3_2023, "K:\\Occupational Health Grant\\Jean Kwizerimana\\FTE\\FTE_2023_PUMS_5y_naics3.csv")

