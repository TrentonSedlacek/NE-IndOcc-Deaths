library(tidyverse); library(rsconnect); library(httr); library(jsonlite)
library(readxl)
library(tidyverse); library(rsconnect); library(httr); library(jsonlite)
library(readxl)

# Install haven if not already installed
install.packages("haven")
# Load haven package
library(haven)
# Read the SAS dataset
data <- read_sas("K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\suicide data\\suicides.sas7bdat")
data <- data[data$DOD_YR >= 2014, ]
data$ID <- seq_len(nrow(data))
id <- data$ID

industry <- data$INDUSTL

occupation <- data$OCCUPL

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
data_io_coded <- data |>
  left_join(io_reponse_df, by = c("ID" = "id"))


write_csv(data_io_coded, "K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\suicide_coded_datac.csv")

data_io_coded<- read.csv("K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\suicide data\\suicide_coded_data.csv")

atvsoc<- read.csv("K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\socc.csv")
FTE_2023 <- read.csv("K:\\Occupational Health Grant\\Jean Kwizerimana\\FTE\\FTE_2023_PUMS_5y_soc2.csv")
fte_2023_ind <-read.csv("K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\suicide data\\suicide_counts_industry (2014-2023).csv")
FTE_2023 <- FTE_2023 %>% rename(SOC = SOCP)
# Remove rows where SOC is "0"
atvsoc <- atvsoc[atvsoc$SOC != "0", ]

selected <- atv %>%
  select(DeathCertificateId, IndustryLit, OccupationLIt, CensusOccupationTitle, CensusIndustryTitle, SOCCode, SOCTitle)
library(dplyr)
#renaming subjects
data_io_code <- data_io_coded %>%
  mutate(SOCCode = ifelse(SOCCode == "11-9013", "45-0000", SOCCode))

#striping characters from subjects; 
data_io_code$SOC <- substr(data_io_code$SOCCode, 1, 2)

data_io_coded$NAICS <- substr(data_io_coded$NAICSCode, 1, 2)

# Modify SOC column with specific replacements
data_io_code <- data_io_code %>%
  mutate(NAICS = case_when(
    NAICS %in% c(31, 32, 33) ~ "31-33",
    NAICS %in% c(44, 45) ~ "44-45",
    NAICS %in% c(48, 49) ~ "48-49",
    TRUE ~ as.character(NAICS)  # Keep other values unchanged
  ))
working_group <- data_io_code %>% filter(AGEUNITS >= 16, SOC != "00")
#  left join on SOC
# Convert FTE_2023$SOC to character
atvsoc<- atvsoc %>% mutate(SOC = as.character(SOC))
working_group <- working_group %>% mutate(SOC = as.character(SOC))
# Perform the left join
data_io_occ <- working_group %>% left_join(atvsoc, by = "SOC")

#Create a frequency table and convert it to a data frame
occ_df_yr <- table(data_io_occ$OccCategory) %>%
  as.data.frame() %>%
  rename(OccCategory = Var1, Count = Freq) %>%
  #mutate(Percentage = (Count / sum(Count)) * 100) %>%
  arrange(desc(Count))  # Sort by Count in decreasing order

#occupation category count by year
occ_count_yr <- data_io_occ %>%
  group_by(DOD_YR, OccCategory) %>%
  summarise(Count = n(), .groups = "drop") %>%
  arrange(DOD_YR, OccCategory)

# Transform data to wide format with years as columns
occ_count_yr <- data_io_occ %>%
  group_by(DOD_YR, OccCategory) %>%
  summarise(Count = n(), .groups = "drop") %>%
  pivot_wider(names_from = DOD_YR, values_from = Count, values_fill = list(Count = 0)) %>%
  arrange(OccCategory)

#industry category count by year
ind_count_yr <- data_io_ind %>%
  group_by(DOD_YR, Ind_sector) %>%
  summarise(Count = n(), .groups = "drop") %>%
  arrange(DOD_YR, Ind_sector)

# Transform data to wide format with years as columns
ind_count_yr <- data_io_ind %>%
  group_by(DOD_YR, Ind_sector) %>%
  summarise(Count = n(), .groups = "drop") %>%
  pivot_wider(names_from = DOD_YR, values_from = Count, values_fill = list(Count = 0)) %>%
  arrange(Ind_sector)
write_csv(ind_count_yr, "K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\suicide_ind_count_yr.csv")

data_fte_occ <- occ_fte_df %>% left_join(FTE_2023, by = "OccCategory")

# Calculate the percentage of suicides per FTE employees
data_fte_occ <- data_fte_occ %>%
  mutate(suicidesper1000fte = (Count / n) * 1000)

data_fte<- data_fte_occ%>%
  relocate(suicidesper1000fte, .after=Count)%>%
  relocate(SOC, .before=OccCategory)

write_csv(data_fte, "K:\\Occupational Health Grant\\Jean Kwizerimana\\Deacertificate\\suicide data\\suicide_counts_occ.csv")

library(ggplot2)

# Create the horizontal bar plot, sort the bars, and add data labels
ggplot(data_fte_occ, aes(x = reorder(OccCategory, suicidesper1000fte), y = suicidesper1000fte)) +
  geom_bar(stat = "identity", fill = "steelblue") +  # Uniform color (steelblue)
  geom_text(aes(label = round(suicidesper1000fte, 2)), 
            hjust = -0.1,  # Move the text to the right outside the bar
            color = "black") +  # Add labels at the end of the bars
  labs(
    title = "Suicides per 1000 FTE Employees by Occupation Sector (2014-2023)",  # Main title
    x = "Industry Sector",  # x-axis label
    y = "Suicides per 1000 FTE Employees"  # y-axis label
  ) +
  theme_minimal() +
  coord_flip()  # Flip to make the bar graph horizontal

# Create graph for counts
ggplot(data_fte, aes(x = reorder(Ind_sector, Count), y = Count)) +
  geom_bar(stat = "identity", fill = "steelblue") +  # Uniform color (steelblue)
  geom_text(aes(label = round(Count, 0)), 
            hjust = -0.1,  # Move the text to the right outside the bar
            color = "black") +  # Add labels at the end of the bars
  labs(
    title = "Suicides Counts by Industry Sector (2014-2023)",  # Main title
    x = "Industry Sector",  # x-axis label
    y = "Suicides per 1000 FTE Employees"  # y-axis label
  ) +
  theme_minimal() +
  coord_flip()  # Flip to make the bar graph horizontal
