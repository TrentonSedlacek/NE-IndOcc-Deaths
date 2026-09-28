library(tidyverse)
library(tidycensus)
library(srvyr, warn.conflicts = FALSE)

#clipr::write_clip()

census_api_key("fda55d10ae1222ea2b997924b0baee5d4185a81a", install = TRUE) # may need to get a new key

# get api key at http://api.census.gov/data/key_signup.html


View(pums_variables)  ## to view all the avaialve vars

"OCCP"     #Occupation recode for 2012 and later based on 2010 OCC codes
"SOCP"   # SOC Occupation code for 2012 and later based on 2010 SOC codes
"WKHP"     # Usual hours worked per week past
"ESR"      # Employment status recode
"COW"      # Class of worker   

#########################################################
#######                                           #######
#######             2014 ACS 5y PUMS              #######
#######                                           #######
#########################################################

ne_pums_rep_weights5_2014<- get_pums(
  variables = c("AGEP", "SOCP12", "WKHP", "COW", "ESR" ),
  state = "NE",
  survey = "acs5",
  year = 2014, 
  recode = FALSE, 
  rep_weights = "person")

ne_pums_rep_weights5_2014 <- ne_pums_rep_weights5_2014%>%
  filter(ESR %in% c(1,2))   # civilian employed, this will results in ages >= 16 
ne_pums_rep_weights5_2014 <- ne_pums_rep_weights5_2014  %>% filter(SOCP12 != "N.A.//")

ne_pums_rep_weights5_soc2_2014 <- ne_pums_rep_weights5_2014 

######## 2014 NAICS 2 ##########
################################

ne_pums_rep_weights5_soc2_2014 $SOCP <- strtrim(ne_pums_rep_weights5_soc2_2014$SOCP12, 2)


### employee estimates (not fte adjusted) ###

ne_survey_pums5_soc2_2014 <- to_survey(ne_pums_rep_weights5_soc2_2014)   # create survey design object

ne_survey_pums5_soc2_2014 <- ne_survey_pums5_soc2_2014 %>% 
  survey_count(SOCP)   

ne_survey_pums5_soc2_2014 <- ne_survey_pums5_soc2_2014 %>%
  mutate(MOE = n_se * 1.96) %>%
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) %>%
  mutate(CV = (n_se / n) * 100)


######### FTE adjusted calculations  ###########

fte_ne_pums_rep_weights5_soc2_2014 <- ne_pums_rep_weights5_soc2_2014 %>%
  mutate(WKHP = as.numeric(WKHP)) %>%
  mutate(WKHP = WKHP/40) %>%                           # divided work hours by 40 
  mutate_at(vars(starts_with("PWGTP")), list( ~ . * WKHP))   # multiply PWGTP by WKHP to get estimated FTE for each respondent. 


fte_ne_survey_pums5_soc2_2014 <- to_survey(fte_ne_pums_rep_weights5_soc2_2014)   # create survey design object

fte_ne_survey_pums5_soc2_2014 <- fte_ne_survey_pums5_soc2_2014 %>% 
  survey_count(SOCP)   

fte_ne_survey_pums5_soc2_2014 <- fte_ne_survey_pums5_soc2_2014 %>%
  mutate(MOE = n_se * 1.96) %>%
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) %>%
  mutate(CV = (n_se / n) * 100)

occ_names <- read.csv("K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\ATV\\socc.csv")
library(dplyr)

fte_ne_survey_pums5_soc2_2014 <- fte_ne_survey_pums5_soc2_2014 |> 
  mutate(SOCP = as.character(SOCP))

occ_names <- occ_names |> 
  mutate(SOC = as.character(SOC))
# perform the join
merged_df <- left_join(fte_ne_survey_pums5_soc2_2014, occ_names, by = c("SOCP" = "SOC"))

merged_df <- merged_df |>
  select(1,7,2:6)

write_csv(merged_df, "K:\\Occupational Health Grant\\Jean Kwizerimana\\FTE\\FTE_2014_PUMS_5y_soc2.csv")


