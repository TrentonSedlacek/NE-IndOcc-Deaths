# Load necessary libraries
library(tidyverse)   # For data manipulation and visualization
library(janitor)     # For cleaning variable names
library(incidence2)  # For calculating incidence of events over time
library(ggthemes)
library(gridExtra)

# Read the CSV file containing data about Highly Pathogenic Avian Influenza (HPAI) detections in livestock
HPAI_detect <- read_csv("Table Details by Date.csv")

# Clean column names to ensure they are consistent and easy to use (replacing spaces with underscores, etc.)
HPAI_detect <- HPAI_detect |> clean_names()

# Convert the 'date_confirmed_by_nvsl' column to a Date object for proper time series analysis
HPAI_detect$date_confirmed_by_nvsl <- as.Date(HPAI_detect$date_confirmed_by_nvsl, format = "%m/%d/%Y")

# Calculate incidence rates of HPAI detections, grouping by state and indexing by the date confirmed
HPAI_detect <- incidence(HPAI_detect, date_index= "date_confirmed_by_nvsl", groups = "state")

HPAI_detect$state <- factor(HPAI_detect$state, levels =  c("Texas", "Kansas", "Michigan", "Idaho", "New Mexico", "Ohio", "North Carolina", "South Dakota", "Colorado"))


# Define a theme for plotting using ggplot2 to ensure clear visualization with minimal grid lines and appropriately angled x-axis text
my_theme <- theme_bw(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        axis.text.x = element_text(angle = 45, hjust = 1, color = "black"),
        plot.title = element_text(size = 22))

# Plot the incidence data with states distinguished by different colors, and x-axis labels formatted to show date breaks daily
p1 <- plot(HPAI_detect, show_cases = TRUE, border = "black", angle = 45, fill = "state", alpha = 0.8, width = .93) +
  
  scale_fill_manual(values = c("#4E79A7", "#F28E2B", "#E15759", "#76B7B2", "#59A14F", "#EDC948", "#B07AA1", "#FF9DA7", "#9C755F"), labels = c("Texas", "Kansas", "Michigan", "Idaho", "New Mexico", "Ohio", "North Carolina", "South Dakota", "Colorado")) +
  scale_x_date(breaks = '1 day',  # Set x-axis breaks to be daily
               limits = c(as.Date('2024-03-24'),  Sys.Date()-0.5)) +  # Limit x-axis to show data starting from a specific date
  ylim(0, 8) +
  labs(x = NULL, y = "Confirmed Herds", fill = "State", title = paste("Confirmed Cases of HPAI in Domestic Catttle Herds, as of ", Sys.Date()," (n=84)")) +  # Set labels for y-axis and legend, remove x-axis label
  my_theme  # Apply the custom theme defined earlier




# Read the CSV file containing data about Highly Pathogenic Avian Influenza (HPAI) detections in livestock
HPAI_detect <- read_csv("Highly Pathogenic Avian Influenza (HPAI) Detections in Livestock  Animal and Plant Health Inspection Service.csv")

# Clean column names to ensure they are consistent and easy to use (replacing spaces with underscores, etc.)
HPAI_detect <- HPAI_detect |> clean_names()

# Convert the 'date_confirmed_by_nvsl' column to a Date object for proper time series analysis
HPAI_detect$date_confirmed_by_nvsl <- as.Date(HPAI_detect$date_confirmed_by_nvsl, format = "%m/%d/%Y")



HPAI_detect <- HPAI_detect |>
  arrange(date_confirmed_by_nvsl) |>
  mutate(Count = as.integer(1)) |>
  group_by(state) |>
  mutate(Count = cumsum(Count))

HPAI_detect$state <- factor(HPAI_detect$state, levels =  c("Texas", "Kansas", "Michigan", "Idaho", "New Mexico", "Ohio", "North Carolina", "South Dakota", "Colorado"))


my_theme <- theme_bw(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        axis.text.x = element_text(angle = 45, hjust = 1, color = "black"),
        plot.title = element_text(size = 22))


p2 <- ggplot(HPAI_detect, aes(x = date_confirmed_by_nvsl, y = Count, group = state, color = state)) +
  geom_line() +
  geom_point() +
  scale_color_manual(values = c("#4E79A7", "#F28E2B", "#E15759", "#76B7B2", "#59A14F", "#EDC948", "#B07AA1", "#FF9DA7", "#9C755F"), labels = c("Texas", "Kansas", "Michigan", "Idaho", "New Mexico", "Ohio", "North Carolina", "South Dakota", "Colorado")) +
  scale_x_date(breaks = '1 day',  # Set x-axis breaks to be daily
               limits = c(as.Date('2024-03-24'),  Sys.Date()-0.5)) +  # Limit x-axis to show data starting from a specific date
  
  scale_y_continuous(n.breaks=7) +
  ylim(0, 20) +
  labs(x = "Date Confirmed by NVSL", y = "Confirmed Herds", color = "State", title = paste("Cumulative Cases of HPAI in Domestic Catttle Herds, as of ",Sys.Date()," (n=84)"), caption = "Source: USDA") +  # Set labels for y-axis and legend, remove x-axis label
  my_theme  # Apply the custom theme defined earlier



grid.arrange(p1, p2, nrow = 2)




