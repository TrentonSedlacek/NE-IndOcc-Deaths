library(tidyverse); library(rsconnect); library(httr); library(jsonlite)
library(readxl)
##### import case inv datamart and filter out 2021 cases ####
lung <- read_excel("K:\\Occupational Health Grant\\Jean Kwizerimana\\Lung Cancer\\lungcancer.xlsx")
popcount <- read_excel("K:\\Occupational Health Grant\\Jean Kwizerimana\\Lung Cancer\\county.xlsx")
# Add an ID column to the dataset
lung$ID <- seq_len(nrow(lung))

id <- lung$ID

industry <- lung$textUsualIndustry

occupation <- lung$textUsualOccupation

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
lung_io_coded <- lung |>
  left_join(io_reponse_df, by = c("ID" = "id"))

colnames(lung_io_coded)[colnames(lung_io_coded) == "Codes"] <- "CountyCodes"
colnames(lung_io_coded)[colnames(lung_io_coded) == "ruralurban_fmt"] <- "ruralurbanContinuum2003_num"
colnames(lung_io_coded)[colnames(lung_io_coded) == "ruralurban_fmt"] <- "ruralurban_fmt(2003)"
lung_io_coded$ruralurbanContinuum2003_num <- NULL
write.csv(lung_io_coded, "K://Occupational Health Grant//Jean Kwizerimana//Lung Cancer//lung_io_coded.csv ", row.names = FALSE)

#  left join on id with initial df
lung_coded <- lung_io_coded |>
  left_join(popcount, by = c("countyAtDx" = "Codes"))
colnames(lung_coded)[colnames(lung_coded) == "Value"] <- "poppercounty"
write.csv(lung_coded, "K://Occupational Health Grant//Jean Kwizerimana//Lung Cancer//lungcoded.csv ", row.names = FALSE)
