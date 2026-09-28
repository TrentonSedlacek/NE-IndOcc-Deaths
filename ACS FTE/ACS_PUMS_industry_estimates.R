library(tidyverse)
library(tidycensus)
library(srvyr, warn.conflicts = FALSE)

#clipr::write_clip()

census_api_key("fda55d10ae1222ea2b997924b0baee5d4185a81a", install = TRUE, overwrite=TRUE) # may need to get a new key

# get api key at http://api.census.gov/data/key_signup.html


View(pums_variables)  ## to view all the avaialve vars



"INDP"     # Industry recode for 2018 and later based on 2017 IND codes
"NAICSP"   # (NAICS) recode for 2018 and later based on 2017 NAICS codes
"WKHP"     # Usual hours worked per week past
"ESR"      # Employment status recode
"COW"      # Class of worker   

#########################################################
#######                                           #######
#######             2019 ACS 5y PUMS              #######
#######                                           #######
#########################################################

ne_pums_rep_weights5_2019 <- get_pums(
  variables = c("AGEP", "NAICSP", "INDP", "WKHP", "COW", "ESR"),
  state = "NE",
  survey = "acs5",
  year = 2019, 
  recode = TRUE, 
  rep_weights = "person")


ne_pums_rep_weights5_2019 <- ne_pums_rep_weights5_2019 |>
  filter(ESR %in% c(1,2)) |>    # civilian employed, this will results in ages >= 16 
  filter(AGEP <= 64)             # filter for working age             

ne_pums_rep_weights5_naics3_2019 <- ne_pums_rep_weights5_2019 

ne_pums_rep_weights5_naics2_2019 <- ne_pums_rep_weights5_2019 



#######    2019 NAICS 3   ########
#################################


ne_pums_rep_weights5_naics3_2019$NAICSP <- strtrim(ne_pums_rep_weights5_naics3_2019$NAICSP, 3)

ne_pums_rep_weights5_naics3_2019 <- ne_pums_rep_weights5_naics3_2019 |>
  filter(str_length(NAICSP) == 3)

ne_pums_rep_weights5_naics3_2019 <- ne_pums_rep_weights5_naics3_2019 |>
  filter(!NAICSP %in% c("33M","3MS", "4MS", "52M", "53M", "92M"))


### employee estimates (not fte adjusted) ###

ne_survey_pums5_naics3_2019 <- to_survey(ne_pums_rep_weights5_naics3_2019)   # create survey design object

ne_survey_pums5_naics3_2019 <- ne_survey_pums5_naics3_2019 |> 
  survey_count(NAICSP)       # calculate estimates w/ std errors

ne_survey_pums5_naics3_2019 <- ne_survey_pums5_naics3_2019 |>
  mutate(MOE = n_se * 1.96) |>
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) |>
  mutate(CV = (n_se / n) * 100)


######### FTE adjusted calculations  ###########

fte_ne_pums_rep_weights5_naics3_2019 <- ne_pums_rep_weights5_naics3_2019 |>
  mutate(WKHP = WKHP/40) |>                           # divided work hours by 40 
  mutate_at(vars(starts_with("PWGTP")), list( ~ . * WKHP))   # multiply PWGTP by WKHP to get estimated FTE for each respondent. 


fte_ne_survey_pums5_naics3_2019 <- to_survey(fte_ne_pums_rep_weights5_naics3_2019)   # create survey design object

fte_ne_survey_pums5_naics3_2019 <- fte_ne_survey_pums5_naics3_2019 |> 
  survey_count(NAICSP)   

fte_ne_survey_pums5_naics3_2019 <- fte_ne_survey_pums5_naics3_2019 |>
  mutate(MOE = n_se * 1.96) |>
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) |>
  mutate(CV = (n_se / n) * 100)



######## 2019 NAICS 2 ##########
################################

ne_pums_rep_weights5_naics2_2019$NAICSP <- strtrim(ne_pums_rep_weights5_naics2_2019$NAICSP, 2)


ne_pums_rep_weights5_naics2_2019 <- ne_pums_rep_weights5_naics2_2019 |> 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2019$NAICSP == "31", str_replace(NAICSP, "\\b31\\b", "31-33"), NAICSP))|> 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2019$NAICSP == "32", str_replace(NAICSP, "\\b32\\b", "31-33"), NAICSP))|> 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2019$NAICSP == "33", str_replace(NAICSP, "\\b33\\b", "31-33"), NAICSP))|> 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2019$NAICSP == "3M", str_replace(NAICSP, "\\b3M\\b", "31-33"), NAICSP)) |>
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2019$NAICSP == "44", str_replace(NAICSP, "\\b44\\b", "44-45"), NAICSP))|> 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2019$NAICSP == "45", str_replace(NAICSP, "\\b45\\b", "44-45"), NAICSP))|> 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2019$NAICSP == "4M", str_replace(NAICSP, "\\b4M\\b", "44-45"), NAICSP))|> 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2019$NAICSP == "48", str_replace(NAICSP, "\\b48\\b", "48-49"), NAICSP)) |>
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2019$NAICSP == "49", str_replace(NAICSP, "\\b49\\b", "48-49"), NAICSP))


### employee estimates (not fte adjusted) ###

ne_survey_pums5_naics2_2019 <- to_survey(ne_pums_rep_weights5_naics2_2019)   # create survey design object

ne_survey_pums5_naics2_2019 <- ne_survey_pums5_naics2_2019 |> 
  survey_count(NAICSP)   

ne_survey_pums5_naics2_2019 <- ne_survey_pums5_naics2_2019 |>
  mutate(MOE = n_se * 1.96) |>
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) |>
  mutate(CV = (n_se / n) * 100)


######### FTE adjusted calculations  ###########

fte_ne_pums_rep_weights5_naics2_2019 <- ne_pums_rep_weights5_naics2_2019 |>
  mutate(WKHP = WKHP/40) |>                           # divided work hours by 40 
  mutate_at(vars(starts_with("PWGTP")), list( ~ . * WKHP))   # multiply PWGTP by WKHP to get estimated FTE for each respondent. 


fte_ne_survey_pums5_naics2_2019 <- to_survey(fte_ne_pums_rep_weights5_naics2_2019)   # create survey design object

fte_ne_survey_pums5_naics2_2019 <- fte_ne_survey_pums5_naics2_2019 |> 
  survey_count(NAICSP)   

fte_ne_survey_pums5_naics2_2019 <- fte_ne_survey_pums5_naics2_2019 |>
  mutate(MOE = n_se * 1.96) |>
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) |>
  mutate(CV = (n_se / n) * 100)


#########################################################
#######                                           #######
#######             2020 ACS 5y PUMS              #######
#######                                           #######
#########################################################


ne_pums_rep_weights5_2020 <- get_pums(
  variables = c("AGEP", "NAICSP", "INDP", "WKHP", "COW", "ESR"),
  state = "NE",
  survey = "acs5",
  year = 2020, 
  recode = TRUE, 
  rep_weights = "person")


ne_pums_rep_weights5_2020 <- ne_pums_rep_weights5_2020 |>
  filter(ESR %in% c(1,2)) |>    # civilian employed, this will results in ages >= 16 
  filter(AGEP <= 64)             # filter for working age              

ne_pums_rep_weights5_naics3_2020 <- ne_pums_rep_weights5_2020 

ne_pums_rep_weights5_naics2_2020 <- ne_pums_rep_weights5_2020 



#### 2020 NAICS 3 ######
########################

ne_pums_rep_weights5_naics3_2020$NAICSP <- strtrim(ne_pums_rep_weights5_naics3_2020$NAICSP, 3)

ne_pums_rep_weights5_naics3_2020 <- ne_pums_rep_weights5_naics3_2020 |>
  filter(str_length(NAICSP) == 3)

ne_pums_rep_weights5_naics3_2020 <- ne_pums_rep_weights5_naics3_2020 |>
  filter(!NAICSP %in% c("33M","3MS", "4MS", "52M", "53M", "92M"))     # remove these person reposes, cant determine subsector


### employee estimates (not fte adjusted) ###

ne_survey_pums5_naics3_2020 <- to_survey(ne_pums_rep_weights5_naics3_2020)   # create survey design object

ne_survey_pums5_naics3_2020 <- ne_survey_pums5_naics3_2020 |> 
  survey_count(NAICSP)       # calculate estimates w/ std errors

ne_survey_pums5_naics3_2020 <- ne_survey_pums5_naics3_2020 |>
  mutate(MOE = n_se * 1.96) |>
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) |>
  mutate(CV = (n_se / n) * 100)


######### FTE adjusted calculations  ###########

fte_ne_pums_rep_weights5_naics3_2020 <- ne_pums_rep_weights5_naics3_2020 |>
  mutate(WKHP = WKHP/40) |>                           # divided work hours by 40 
  mutate_at(vars(starts_with("PWGTP")), list( ~ . * WKHP))   # multiply PWGTP by WKHP to get estimated FTE for each respondent. 


fte_ne_survey_pums5_naics3_2020 <- to_survey(fte_ne_pums_rep_weights5_naics3_2020)   # create survey design object

fte_ne_survey_pums5_naics3_2020 <- fte_ne_survey_pums5_naics3_2020 |> 
  survey_count(NAICSP)   

fte_ne_survey_pums5_naics3_2020 <- fte_ne_survey_pums5_naics3_2020 |>
  mutate(MOE = n_se * 1.96) |>
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) |>
  mutate(CV = (n_se / n) * 100)



#######    2020 NAICS 2   #######
################################


ne_pums_rep_weights5_naics2_2020$NAICSP <- strtrim(ne_pums_rep_weights5_naics2_2020$NAICSP, 2)


ne_pums_rep_weights5_naics2_2020 <- ne_pums_rep_weights5_naics2_2020 |>   # below mutate to replace values 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2020$NAICSP == "31", str_replace(NAICSP, "\\b31\\b", "31-33"), NAICSP))|> 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2020$NAICSP == "32", str_replace(NAICSP, "\\b32\\b", "31-33"), NAICSP))|> 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2020$NAICSP == "33", str_replace(NAICSP, "\\b33\\b", "31-33"), NAICSP))|> 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2020$NAICSP == "3M", str_replace(NAICSP, "\\b3M\\b", "31-33"), NAICSP)) |>
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2020$NAICSP == "44", str_replace(NAICSP, "\\b44\\b", "44-45"), NAICSP))|> 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2020$NAICSP == "45", str_replace(NAICSP, "\\b45\\b", "44-45"), NAICSP))|> 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2020$NAICSP == "4M", str_replace(NAICSP, "\\b4M\\b", "44-45"), NAICSP))|> 
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2020$NAICSP == "48", str_replace(NAICSP, "\\b48\\b", "48-49"), NAICSP)) |>
  mutate(NAICSP=ifelse(ne_pums_rep_weights5_naics2_2020$NAICSP == "49", str_replace(NAICSP, "\\b49\\b", "48-49"), NAICSP))

### employee estimates (not fte adjusted) ###

ne_survey_pums5_naics2_2020 <- to_survey(ne_pums_rep_weights5_naics2_2020)   # create survey design object

ne_survey_pums5_naics2_2020 <- ne_survey_pums5_naics2_2020 |> 
  survey_count(NAICSP)       # calculate estimates w/ std errors

ne_survey_pums5_naics2_2020 <- ne_survey_pums5_naics2_2020 |>
  mutate(MOE = n_se * 1.96) |>
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) |>
  mutate(CV = (n_se / n) * 100)


######### FTE adjusted calculations  ###########

fte_ne_pums_rep_weights5_naics2_2020 <- ne_pums_rep_weights5_naics2_2020 |>
  mutate(WKHP = WKHP/40) |>                           # divided work hours by 40 
  mutate_at(vars(starts_with("PWGTP")), list( ~ . * WKHP))   # multiply PWGTP by WKHP to get estimated FTE for each respondent. 


fte_ne_survey_pums5_naics2_2020 <- to_survey(fte_ne_pums_rep_weights5_naics2_2020)   # create survey design object

fte_ne_survey_pums5_naics2_2020 <- fte_ne_survey_pums5_naics2_2020 |> 
  survey_count(NAICSP)   

fte_ne_survey_pums5_naics2_2020<- fte_ne_survey_pums5_naics2_2020 |>
  mutate(MOE = n_se * 1.96) |>
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) |>
  mutate(CV = (n_se / n) * 100)


### rename columns and write to file ### 

ne_survey_pums5_naics2_2019 <- ne_survey_pums5_naics2_2019 |>
  rename(NAICSP_2 = NAICSP, estimate = n, estimate_se = n_se) 

ne_survey_pums5_naics3_2019 <- ne_survey_pums5_naics3_2019 |>
  rename(NAICSP_3 = NAICSP, estimate = n, estimate_se = n_se)

ne_survey_pums5_naics2_2020 <- ne_survey_pums5_naics2_2020 |>
  rename(NAICSP_2 = NAICSP, estimate = n, estimate_se = n_se)

ne_survey_pums5_naics3_2020 <- ne_survey_pums5_naics3_2020 |>
  rename(NAICSP_3 = NAICSP, estimate = n, estimate_se = n_se)


write_csv(ne_survey_pums5_naics2_2019, "2019_PUMS_5y_naics2.csv")

write_csv(ne_survey_pums5_naics3_2019, "2019_PUMS_5y_naics3.csv")

write_csv(ne_survey_pums5_naics2_2020, "2020_PUMS_5y_naics2.csv")

write_csv(ne_survey_pums5_naics3_2020, "2020_PUMS_5y_naics3.csv")




fte_ne_survey_pums5_naics2_2019 <- fte_ne_survey_pums5_naics2_2019 |>
  rename(NAICSP_2 = NAICSP, FTE_estimate = n, FTE_estimate_se = n_se) 

fte_ne_survey_pums5_naics3_2019 <- fte_ne_survey_pums5_naics3_2019 |>
  rename(NAICSP_3 = NAICSP, FTE_estimate = n, FTE_estimate_se = n_se)

fte_ne_survey_pums5_naics2_2020 <- fte_ne_survey_pums5_naics2_2020 |>
  rename(NAICSP_2 = NAICSP, FTE_estimate = n, FTE_estimate_se = n_se)

fte_ne_survey_pums5_naics3_2020 <- fte_ne_survey_pums5_naics3_2020 |>
  rename(NAICSP_3 = NAICSP, FTE_estimate = n, FTE_estimate_se = n_se)


write_csv(fte_ne_survey_pums5_naics2_2019, "FTE_2019_PUMS_5y_naics2.csv")

write_csv(fte_ne_survey_pums5_naics3_2019, "FTE_2019_PUMS_5y_naics3.csv")

write_csv(fte_ne_survey_pums5_naics2_2020, "FTE_2020_PUMS_5y_naics2.csv")

write_csv(fte_ne_survey_pums5_naics3_2020, "FTE_2020_PUMS_5y_naics3.csv")


