library(tidyverse); library(rsconnect); library(httr); library(jsonlite)
library(readxl)
##### import case inv datamart and filter out 2021 cases ####

histo <- read.csv("K:\\Occupational Health Grant\\Jean Kwizerimana\\Bladder Cancer\\Derry_Stover_Request")
blad <- read_excel("K:\\Occupational Health Grant\\Jean Kwizerimana\\Bladder Cancer\\Derry_Stove_Request4.xlsx")
occ_coded <- read_excel("K:\\Occupational Health Grant\\Jean Kwizerimana\\Bladder Cancer\\occuindcoded.xlsx")
lung <- blad %>%
  filter(cancer_type_use %in% c("LUNG & BRONCHUS", "URINARY BLADDER"))
lung.1 <- lung %>%
  filter(!is.na(textUsualOccupation))
lung.2 <- lung.1 %>%
  filter(!is.na(textUsualIndustry) & !textUsualIndustry %in% c("UNKNOWN", "UNK", "X", "UNKNOWN NOT REPORTED"))

lung.1 <- lung %>%
  filter(!is.na(textUsualIndustry))
lung.2 <- lung.1 %>%
  filter(!is.na(textUsualOccupation) & !textUsualOccupation %in% c("UNKNOWN", "UNK", "X"))

# Add an ID column to the dataset
lung.2$ID <- seq_len(nrow(lung.2))

id <- lung.2$ID

industry <- lung.2$textUsualOccupation

occupation <- lung.2$textUsualOccupation

NIOCCS_WebService <- function(id, industry, occupation){
  # send GET request
  response <- httr::GET(url = "https://wwwn.cdc.gov/nioccs/IOCode?",
                        query = list(i = industry,
                                     o = occupation,
                                     c = 2)
  )
  
  # parse response to JSON
  response_df <- httr::content(response, as="text") 
  
  json_results <- fromJSON(response_df)
  json_results$id <- id
  return(json_results)
  
}

## Purr pmap to map and bind by row 
io_reponse_df <- pmap_dfr(list(id, industry, occupation), NIOCCS_WebService) 


## unnest list columns 
io_reponse_df <- io_reponse_df |>
  select(id, Industry, Occupation) |>
  unnest_wider(c(Industry, Occupation)) 


#  left join on id with initial df
ba_io_code <- ba |>
  left_join(io_reponse_df, by = c("ID" = "id"))

Occupations <- sort(table(ba_io_coded$CensusOccupationTitle), decreasing = TRUE)
occ_df <- table(ba_io_coded$CensusOccupationTitle) %>%
  as.data.frame() %>%
  rename(CensusOccupationTitle = Var1, Count = Freq) %>%
  mutate(Percentage = (Count / sum(Count)) * 100) %>%
  arrange(desc(Count))  # Sort by Count in decreasing order

select <- ba_io_coded %>%
  select(ID,textUsualOccupation, CensusOccupationTitle, CensusIndustryTitle, SOCCode, SOCTitle)


# Create the dataframe
occupation_data <- data.frame(
  SOCCode = c("00", "11", "13", "15", "17", "19", "21", "23", "25", "27", "29", "31", "33", "35", "37", "39", "41", "43", "45", "47", "49", "51", "53"),
  Description = c(
    "All Occupations",
    "Management Occupations",
    "Business and Financial Operations Occupations",
    "Computer and Mathematical Occupations",
    "Architecture and Engineering Occupations",
    "Life, Physical, and Social Science Occupations",
    "Community and Social Service Occupations",
    "Legal Occupations",
    "Educational Instruction and Library Occupations",
    "Arts, Design, Entertainment, Sports, and Media Occupations",
    "Healthcare Practitioners and Technical Occupations",
    "Healthcare Support Occupations",
    "Protective Service Occupations",
    "Food Preparation and Serving Related Occupations",
    "Building and Grounds Cleaning and Maintenance Occupations",
    "Personal Care and Service Occupations",
    "Sales and Related Occupations",
    "Office and Administrative Support Occupations",
    "Farming, Fishing, and Forestry Occupations",
    "Construction and Extraction Occupations",
    "Installation, Maintenance, and Repair Occupations",
    "Production Occupations",
    "Transportation and Material Moving Occupations"
  )
)
# Modify the SOCCode variable in ba_io_coded
ba_io_coded <- ba_io_code %>%
  mutate(SOCCode = ifelse(SOCCode == "11-9013", "45", SOCCode))

ba_io_coded <- ba_io_coded %>%
  mutate(SOCCode = substr(SOCCode, 1, 2))

# Perform the left join
result <- ba_io_coded %>%
  left_join(occupation_data, by = "SOCCode")

results <- result %>%
  filter(!CensusOccupationTitle %in% c("Insufficient Information") & !SOCCode %in% c("00"))



Occupations <- sort(table(results$Description), decreasing = TRUE)
occ_df <- table(results$Description) %>%
  as.data.frame() %>%
  rename(Description = Var1, Count = Freq) %>%
  mutate(Percentage = (Count / sum(Count)) * 100) %>%
  arrange(desc(Count))  # Sort by Count in decreasing order
occ_df 

select <- ba_io_coded %>%
  select(ID,textUsualOccupation, CensusOccupationTitle, CensusIndustryTitle, SOCCode, SOCTitle)