library(tidyverse); library(rsconnect); library(httr); library(jsonlite)
library(readxl)
##### import case inv datamart and filter out 2021 cases ####

histo <- read.csv("K:\\Occupational Health Grant\\Jean Kwizerimana\\Bladder Cancer\\Derry_Stover_Request")
blad <- read_excel("K:\\Occupational Health Grant\\Jean Kwizerimana\\Bladder Cancer\\Derry_Stove_Request.xlsx")
# Add an ID column to the dataset
blad$ID <- seq_len(nrow(blad))

id <- histo$ID

industry <- histo$industry

occupation <- histo$textUsualOccupation



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
histo_io_coded <- histo |>
  left_join(io_reponse_df, by = c("person_id" = "id"))

# Select the specified variables from histo_io_coded
selected_data <- histo_io_coded %>%
  select(person_id, industry, work, CensusOccupationTitle, CensusIndustryTitle)

write_csv(histo_io_coded, "K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\nioccs_coded_histocases.csv")


atv<- read.csv("K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\nioccs_atv.csv")
atvsoc<- read.csv("K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\socc.csv")
selected <- atv %>%
  select(DeathCertificateId, IndustryLit, OccupationLIt, CensusOccupationTitle, CensusIndustryTitle, SOCCode, SOCTitle)
library(dplyr)
#renaming subjects
atv <- atv %>%
  mutate(SOCCode = ifelse(SOCCode == "Nov-13", "11-9013", SOCCode))
atv <- atv %>%
  mutate(SOCCode = ifelse(SOCCode == "Nov-33", "11-9033", SOCCode))
atv <- atv %>%
  mutate(SOCCode = ifelse(SOCCode == "Nov-21", "11-9021", SOCCode))
atv <- atv %>%
  mutate(SOCCode = ifelse(SOCCode == "Nov-99", "11-9199", SOCCode))
atv <- atv %>%
  mutate(SOCCode = ifelse(SOCCode == "Nov-41", "11-9141", SOCCode))
atv <- atv %>%
  mutate(SOCCode = ifelse(SOCCode == "Nov-22", "11-2022", SOCCode))
atv <- atv %>%
  mutate(SOCCode = ifelse(SOCCode == "Nov-51", "11-9051", SOCCode))
atv <- atv %>%
  mutate(SOCCode = ifelse(SOCCode == "11-9013", "45-0000", SOCCode))

#striping characters from subjects; 
atv$SOC <- substr(atv$SOCCode, 1, 2)
atvsoc <- atvsoc %>%
  mutate(SOC = ifelse(SOC == "0", "00", SOC))

#  left join on SOC
atv_merge <- atv |>
  left_join(atvsoc, by = c("SOC" = "SOC"))
selected <- atv_merge %>%
  select(DeathCertificateId, IndustryLit, OccupationLIt, CensusOccupationTitle, CensusIndustryTitle, SOCCode, SOCTitle, SOC, OccCategory)
sel <- atv_merge %>% filter(age >= 19, SOC != "00")
library(dplyr)
allocc <- sel %>% filter(SOC == '00')

# Create a frequency table and convert it to a data frame
occ_category_df <- table(sel$OccCategory) %>%
  as.data.frame() %>%
  rename(OccCategory = Var1, Count = Freq) %>%
  mutate(Percentage = (Count / sum(Count)) * 100) %>%
  arrange(desc(Count))  # Sort by Count in decreasing order

# Display the result
occ_category_df

#scan statistic test
atv_merge$Period <- ifelse(atv_merge$dod_yr < 2020, "Before 2020", "After 2020")

occ_category_df <- table(sel$dod_yr) %>%
  as.data.frame() %>%
  rename(dod_yr = Var1, Count = Freq)
# Prepare inputs for the scan test
cases <- occ_category_df$Count
years <- occ_category_df$dod_yr
expected_cases <- mean(cases)  # Assuming uniform distribution as null hypothesis

occ_category_df$dod_yr <- as.numeric(occ_category_df$dod_yr)
# Convert dod_yr to a Date format, but keep just the year
occ_category_df$dod_yr <- as.Date(as.character(occ_category_df$dod_yr), format = "%Y")

# Verify the structure
str(occ_category_df$dod_yr)

# Fit a Poisson regression model
poisson_model <- glm(Count ~ dod_yr, data = occ_category_df, family = poisson())

# Summary of the model
summary(poisson_model)
dispersion <- sum(residuals(poisson_model, type = "pearson")^2) / poisson_model$df.residual
cat("Dispersion:", dispersion, "\n")
occ_category_df$Predicted <- predict(poisson_model, type = "response")
library(ggplot2)
ggplot(occ_category_df, aes(x = dod_yr, y = Count)) +
  geom_point() +
  geom_line(aes(y = Predicted), color = "blue") +
  labs(title = "Observed vs Predicted Counts", x = "Year", y = "Deaths")
quasipoisson_model <- glm(Count ~ dod_yr, family = quasipoisson(), data = occ_category_df)
summary(quasipoisson_model)
