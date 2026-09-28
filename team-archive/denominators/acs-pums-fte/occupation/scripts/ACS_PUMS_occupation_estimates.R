library(tidyverse)
library(tidycensus)
library(srvyr, warn.conflicts = FALSE)

#clipr::write_clip()

census_api_key("<REDACTED_CENSUS_API_KEY>", install = TRUE) # may need to get a new key

# get api key at http://api.census.gov/data/key_signup.html


View(pums_variables)  ## to view all the available vars



"OCCP"     #Occupation recode for 2012 and later based on 2010 OCC codes
"SOCP"   # SOC Occupation code for 2012 and later based on 2010 SOC codes
"WKHP"     # Usual hours worked per week past
"ESR"      # Employment status recode
"COW"      # Class of worker   

#########################################################
#######                                           #######
#######             2019 ACS 5y PUMS              #######
#######                                           #######
#########################################################

ne_pums_rep_weights5_2019 <- get_pums(
  #variables = c("AGEP", "SOCP", "OCCP", "WKHP", "COW", "ESR"),
  state = "NE",
  survey = "acs5",
  year = 2019, 
  recode = TRUE, 
  rep_weights = "person")


ne_pums_rep_weights5_2019 <- ne_pums_rep_weights5_2019 %>%
  filter(ESR %in% c(1,2)) %>%    # civilian employed, this will results in ages >= 16 
  filter(AGEP <= 64)             # filter for working age              

ne_pums_rep_weights5_soc3_2019 <- ne_pums_rep_weights5_2019 

ne_pums_rep_weights5_soc2_2019 <- ne_pums_rep_weights5_2019 



#######    2019 NAICS 3   ########
#################################


ne_pums_rep_weights5_soc3_2019$SOCP <- strtrim(ne_pums_rep_weights5_soc3_2019$SOCP, 3)

ne_pums_rep_weights5_soc3_2019 <- ne_pums_rep_weights5_soc3_2019 %>%
  filter(str_length(SOCP) == 3)


### employee estimates (not fte adjusted) ###

ne_survey_pums5_soc3_2019 <- to_survey(ne_pums_rep_weights5_soc3_2019)   # create survey design object

ne_survey_pums5_soc3_2019 <- ne_survey_pums5_soc3_2019 %>% 
  survey_count(SOCP)       # calculate estimates w/ std errors

ne_survey_pums5_soc3_2019 <- ne_survey_pums5_soc3_2019 %>%
  mutate(MOE = n_se * 1.96) %>%
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) %>%
  mutate(CV = (n_se / n) * 100)


######### FTE adjusted calculations  ###########

fte_ne_pums_rep_weights5_soc3_2019 <- ne_pums_rep_weights5_soc3_2019 %>%
  mutate(WKHP = WKHP/40) %>%                           # divided work hours by 40 
  mutate_at(vars(starts_with("PWGTP")), list( ~ . * WKHP))   # multiply PWGTP by WKHP to get estimated FTE for each respondent. 


fte_ne_survey_pums5_soc3_2019 <- to_survey(fte_ne_pums_rep_weights5_soc3_2019)   # create survey design object

fte_ne_survey_pums5_soc3_2019 <- fte_ne_survey_pums5_soc3_2019 %>% 
  survey_count(SOCP)   

fte_ne_survey_pums5_soc3_2019 <- fte_ne_survey_pums5_soc3_2019 %>%
  mutate(MOE = n_se * 1.96) %>%
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) %>%
  mutate(CV = (n_se / n) * 100)



######## 2019 NAICS 2 ##########
################################

ne_pums_rep_weights5_soc2_2019$SOCP <- strtrim(ne_pums_rep_weights5_soc2_2019$SOCP, 2)


### employee estimates (not fte adjusted) ###

ne_survey_pums5_soc2_2019 <- to_survey(ne_pums_rep_weights5_soc2_2019)   # create survey design object

ne_survey_pums5_soc2_2019 <- ne_survey_pums5_soc2_2019 %>% 
  survey_count(SOCP)   

ne_survey_pums5_soc2_2019 <- ne_survey_pums5_soc2_2019 %>%
  mutate(MOE = n_se * 1.96) %>%
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) %>%
  mutate(CV = (n_se / n) * 100)


######### FTE adjusted calculations  ###########

fte_ne_pums_rep_weights5_soc2_2019 <- ne_pums_rep_weights5_soc2_2019 %>%
  mutate(WKHP = WKHP/40) %>%                           # divided work hours by 40 
  mutate_at(vars(starts_with("PWGTP")), list( ~ . * WKHP))   # multiply PWGTP by WKHP to get estimated FTE for each respondent. 


fte_ne_survey_pums5_soc2_2019 <- to_survey(fte_ne_pums_rep_weights5_soc2_2019)   # create survey design object

fte_ne_survey_pums5_soc2_2019 <- fte_ne_survey_pums5_soc2_2019 %>% 
  survey_count(SOCP)   

fte_ne_survey_pums5_soc2_2019 <- fte_ne_survey_pums5_soc2_2019 %>%
  mutate(MOE = n_se * 1.96) %>%
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) %>%
  mutate(CV = (n_se / n) * 100)


#########################################################
#######                                           #######
#######             2020 ACS 5y PUMS              #######
#######                                           #######
#########################################################


ne_pums_rep_weights5_2020 <- get_pums(
  variables = c("AGEP", "SOCP", "INDP", "WKHP", "COW", "ESR"),
  state = "NE",
  survey = "acs5",
  year = 2014, 
  recode = TRUE, 
  rep_weights = "person")


ne_pums_rep_weights5_2020 <- ne_pums_rep_weights5_2020 %>%
  filter(ESR %in% c(1,2)) %>%    # civilian employed, this will results in ages >= 16 
  filter(AGEP <= 64)             # filter for working age              

ne_pums_rep_weights5_soc3_2020 <- ne_pums_rep_weights5_2020 

ne_pums_rep_weights5_soc2_2020 <- ne_pums_rep_weights5_2020 



#### 2020 SOC minor group 3 ######
#################################

ne_pums_rep_weights5_soc3_2020$SOCP <- strtrim(ne_pums_rep_weights5_soc3_2020$SOCP, 3)

ne_pums_rep_weights5_soc3_2020 <- ne_pums_rep_weights5_soc3_2020 %>%
  filter(str_length(SOCP) == 3)


### employee estimates (not fte adjusted) ###

ne_survey_pums5_soc3_2020 <- to_survey(ne_pums_rep_weights5_soc3_2020)   # create survey design object

ne_survey_pums5_soc3_2020 <- ne_survey_pums5_soc3_2020 %>% 
  survey_count(SOCP)       # calculate estimates w/ std errors

ne_survey_pums5_soc3_2020 <- ne_survey_pums5_soc3_2020 %>%
  mutate(MOE = n_se * 1.96) %>%
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) %>%
  mutate(CV = (n_se / n) * 100)


######### FTE adjusted calculations  ###########

fte_ne_pums_rep_weights5_soc3_2020 <- ne_pums_rep_weights5_soc3_2020 %>%
  mutate(WKHP = WKHP/40) %>%                           # divided work hours by 40 
  mutate_at(vars(starts_with("PWGTP")), list( ~ . * WKHP))   # multiply PWGTP by WKHP to get estimated FTE for each respondent. 


fte_ne_survey_pums5_soc3_2020 <- to_survey(fte_ne_pums_rep_weights5_soc3_2020)   # create survey design object

fte_ne_survey_pums5_soc3_2020 <- fte_ne_survey_pums5_soc3_2020 %>% 
  survey_count(SOCP)   

fte_ne_survey_pums5_soc3_2020 <- fte_ne_survey_pums5_soc3_2020 %>%
  mutate(MOE = n_se * 1.96) %>%
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) %>%
  mutate(CV = (n_se / n) * 100)



#######    2020 SOC major group 2   #######
###########################################


ne_pums_rep_weights5_soc2_2020$SOCP <- strtrim(ne_pums_rep_weights5_soc2_2020$SOCP, 2)



### employee estimates (not fte adjusted) ###

ne_survey_pums5_soc2_2020 <- to_survey(ne_pums_rep_weights5_soc2_2020)   # create survey design object

ne_survey_pums5_soc2_2020 <- ne_survey_pums5_soc2_2020 %>% 
  survey_count(SOCP)       # calculate estimates w/ std errors

ne_survey_pums5_soc2_2020 <- ne_survey_pums5_soc2_2020 %>%
  mutate(MOE = n_se * 1.96) %>%
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) %>%
  mutate(CV = (n_se / n) * 100)


######### FTE adjusted calculations  ###########

fte_ne_pums_rep_weights5_soc2_2020 <- ne_pums_rep_weights5_soc2_2020 %>%
  mutate(WKHP = WKHP/40) %>%                           # divided work hours by 40 
  mutate_at(vars(starts_with("PWGTP")), list( ~ . * WKHP))   # multiply PWGTP by WKHP to get estimated FTE for each respondent. 


fte_ne_survey_pums5_soc2_2020 <- to_survey(fte_ne_pums_rep_weights5_soc2_2020)   # create survey design object

fte_ne_survey_pums5_soc2_2020 <- fte_ne_survey_pums5_soc2_2020 %>% 
  survey_count(SOCP)   

fte_ne_survey_pums5_soc2_2020<- fte_ne_survey_pums5_soc2_2020 %>%
  mutate(MOE = n_se * 1.96) %>%
  mutate(r_MOE = ((n_se * 1.96) / n) * 100) %>%
  mutate(CV = (n_se / n) * 100)


##### correct SOC major occ codes ##### 


fte_ne_survey_pums5_soc2_2019$SOCP <- str_pad(fte_ne_survey_pums5_soc2_2019$SOCP, 3, side =  "right", pad = "-")
fte_ne_survey_pums5_soc2_2019$SOCP <- str_pad(fte_ne_survey_pums5_soc2_2019$SOCP, 7, side =  "right", pad = "0")

fte_ne_survey_pums5_soc2_2020$SOCP <- str_pad(fte_ne_survey_pums5_soc2_2020$SOCP, 3, side =  "right", pad = "-")
fte_ne_survey_pums5_soc2_2020$SOCP <- str_pad(fte_ne_survey_pums5_soc2_2020$SOCP, 7, side =  "right", pad = "0")



### rename columns and write to file ### 

ne_survey_pums5_soc2_2019 <- ne_survey_pums5_soc2_2019 %>%
  rename(SOC_major_code = SOCP, estimate = n, estimate_se = n_se) 

ne_survey_pums5_soc3_2019 <- ne_survey_pums5_soc3_2019 %>%
  rename(SOCP_3 = SOCP, estimate = n, estimate_se = n_se)

ne_survey_pums5_soc2_2020 <- ne_survey_pums5_soc2_2020 %>%
  rename(SOC_major_code = SOCP, estimate = n, estimate_se = n_se)

ne_survey_pums5_soc3_2020 <- ne_survey_pums5_soc3_2020 %>%
  rename(SOCP_3 = SOCP, estimate = n, estimate_se = n_se)


write_csv(ne_survey_pums5_soc2_2019, "2019_PUMS_5y_soc_major.csv")

write_csv(ne_survey_pums5_soc3_2019, "2019_PUMS_5y_soc3.csv")

write_csv(ne_survey_pums5_soc2_2020, "2020_PUMS_5y_soc_major.csv")

write_csv(ne_survey_pums5_soc3_2020, "2020_PUMS_5y_soc3.csv")




fte_ne_survey_pums5_soc2_2019 <- fte_ne_survey_pums5_soc2_2019 %>%
  rename(SOCP_2 = SOCP, FTE_estimate = n, FTE_estimate_se = n_se) 

fte_ne_survey_pums5_soc3_2019 <- fte_ne_survey_pums5_soc3_2019 %>%
  rename(SOCP_3 = SOCP, FTE_estimate = n, FTE_estimate_se = n_se)

fte_ne_survey_pums5_soc2_2020 <- fte_ne_survey_pums5_soc2_2020 %>%
  rename(SOCP_2 = SOCP, FTE_estimate = n, FTE_estimate_se = n_se)

fte_ne_survey_pums5_soc3_2020 <- fte_ne_survey_pums5_soc3_2020 %>%
  rename(SOCP_3 = SOCP, FTE_estimate = n, FTE_estimate_se = n_se)


write_csv(fte_ne_survey_pums5_soc2_2019, "FTE_2019_PUMS_5y_soc2.csv")

write_csv(fte_ne_survey_pums5_soc3_2019, "FTE_2019_PUMS_5y_soc3.csv")

write_csv(fte_ne_survey_pums5_soc2_2020, "FTE_2020_PUMS_5y_soc2.csv")

write_csv(fte_ne_survey_pums5_soc3_2020, "FTE_2020_PUMS_5y_soc3.csv")





11-0000  Management Occupations
13-0000  Business and Financial Operations Occupations
15-0000  Computer and Mathematical Occupations
17-0000  Architecture and Engineering Occupations
19-0000  Life, Physical, and Social Science Occupations
21-0000  Community and Social Service Occupations
23-0000  Legal Occupations
25-0000  Education, Training, and Library Occupations
27-0000  Arts, Design, Entertainment, Sports, and Media Occupations
29-0000  Healthcare Practitioners and Technical Occupations
31-0000  Healthcare Support Occupations
33-0000  Protective Service Occupations
35-0000  Food Preparation and Serving Related Occupations
37-0000  Building and Grounds Cleaning and Maintenance Occupations
39-0000  Personal Care and Service Occupations
41-0000  Sales and Related Occupations
43-0000  Office and Administrative Support Occupations
45-0000  Farming, Fishing, and Forestry Occupations
47-0000  Construction and Extraction Occupations
49-0000  Installation, Maintenance, and Repair Occupations
51-0000  Production Occupations
53-0000  Transportation and Material Moving Occupations
55-0000  Military Specific Occupations



11-1000  Top Executives
11-2000  Advertising, Marketing, Promotions, Public Relations, and Sales Managers
11-3000  Operations Specialties Managers
11-9000  Other Management Occupations
13-1000  Business Operations Specialists
13-2000  Financial Specialists
15-1000  Computer Occupations
15-2000  Mathematical Science Occupations
17-1000  Architects, Surveyors, and Cartographers
17-2000  Engineers
17-3000  Drafters, Engineering Technicians, and Mapping Technicians
19-1000  Life Scientists
19-2000  Physical Scientists 
19-3000  Social Scientists and Related Workers
19-4000  Life, Physical, and Social Science Technicians

21-1000
21-2000
23-1000
23-2000
25-1000
25-2000
25-3000
25-4000
25-9000
27-1000
27-2000
27-3000
27-4000
29-1000
29-2000
29-9000


31-0000  Healthcare Support Occupations
33-0000  Protective Service Occupations
35-0000  Food Preparation and Serving Related Occupations
37-0000  Building and Grounds Cleaning and Maintenance Occupations
39-0000  Personal Care and Service Occupations
41-0000  Sales and Related Occupations
43-0000  Office and Administrative Support Occupations
45-0000  Farming, Fishing, and Forestry Occupations
47-0000  Construction and Extraction Occupations
49-0000  Installation, Maintenance, and Repair Occupations
51-0000  Production Occupations
53-0000  Transportation and Material Moving Occupations
55-0000  Military Specific Occupations