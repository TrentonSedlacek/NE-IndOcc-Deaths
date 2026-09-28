library(tidyverse); library(rsconnect); library(httr); library(jsonlite)

##### import case inv datamart and filter out 2021 cases ####


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



io_reponse_df <- covid_2021_io |>
  left_join(io_reponse_df, by = c("inv_local_id" = "id"))



write_csv(io_reponse_df, "nioccs_coded_covid_2021_io.csv")




