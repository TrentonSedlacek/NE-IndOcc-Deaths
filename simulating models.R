# Load necessary library
library(dplyr)

# Define parameters
regions <- c("Northeast", "Southwest", "West", "Southeast", "Midwest")
cities_per_region <- 3
outcomes <- c("income", "education_years", "unmet_health_need", "quality_of_life")
races <- c("Black", "White")
time_periods <- c("1990-1994", "1995-1999", "2000-2004", "2005-2009", "2010-2014", "2015-2020")
individuals_per_group <- 100

# Generate data
set.seed(123) # For reproducibility
data <- expand.grid(
  Region = regions,
  City = paste0("City", 1:cities_per_region),
  TimePeriod = time_periods,
  Race = races,
  ID = 1:individuals_per_group
) %>%
  mutate(
    # Generate outcomes as random scores between 0 and 1
    income = runif(n(), 0, 1),
    education_years = runif(n(), 0, 1),
    unmet_health_need = runif(n(), 0, 1),
    quality_of_life = runif(n(), 0, 1)
  )

# Combine region and city information to match structure
city_list <- expand.grid(Region = regions, City = paste0("City", 1:cities_per_region))
data <- data %>%
  left_join(city_list, by = c("Region", "City"))

# Preview the dataset
head(data)
# Load necessary library
library(lme4)
library(lmerTest)

# Filter dataset for unmet health need
unmet_health_data <- data %>%
  select(Region, City, TimePeriod, Race, unmet_health_need)

# Fit the linear mixed-effects model
# Random effects: City nested within Region
model <- lmer(unmet_health_need ~ Race * TimePeriod + (1 | Region/City), data = unmet_health_data)

# Summary of the model
summary(model)

# Post-hoc analysis for interactions and pairwise comparisons
library(emmeans)

# Racial disparity across time periods
emmeans_race_time <- emmeans(model, ~ Race | TimePeriod)
pairs(emmeans_race_time)

# Regional variation in racial disparity
emmeans_race_region <- emmeans(model, ~ Race | Region)
pairs(emmeans_race_region)

# City-level variation within regions
emmeans_city <- emmeans(model, ~ Race | Region/City)
pairs(emmeans_city)

# To address all outcomes together, use multivariate analysis of mixed-effects models
library(MASS)

# Reshape data for multivariate analysis
all_outcomes_data <- data %>%
  select(Region, City, TimePeriod, Race, income, education_years, unmet_health_need, quality_of_life) %>%
  pivot_longer(cols = income:quality_of_life, names_to = "Outcome", values_to = "Score")

# Fit a multivariate mixed-effects model
multi_model <- lmer(Score ~ Race * Outcome * TimePeriod + (1 | Region/City), data = all_outcomes_data)

# Summary for multivariate analysis
summary(multi_model)

# Post-hoc comparisons for outcomes
emmeans_outcome <- emmeans(multi_model, ~ Race | Outcome)
pairs(emmeans_outcome)

#gauge r&r; 
# Load required libraries
library(tidyverse)
library(ggplot2)
library(lme4)

# Function to generate sample data for Gauge R&R study
generate_grr_data <- function(n_parts = 10, 
                              n_operators = 3, 
                              n_replicates = 3, 
                              part_sd = 2, 
                              operator_sd = 0.5, 
                              measurement_sd = 0.3) {
  
  # Create all combinations of parts, operators, and replicates
  grr_data <- expand.grid(
    part = 1:n_parts,
    operator = paste("Operator", 1:n_operators),
    replicate = 1:n_replicates
  )
  
  # Add true part values
  set.seed(123)
  part_values <- rnorm(n_parts, mean = 10, sd = part_sd)
  grr_data$true_value <- part_values[grr_data$part]
  
  # Add operator and measurement variation
  grr_data$measurement <- grr_data$true_value + 
    rnorm(nrow(grr_data), mean = 0, sd = operator_sd) +
    rnorm(nrow(grr_data), mean = 0, sd = measurement_sd)
  
  return(grr_data)
}

# Function to calculate Gauge R&R components
calculate_grr <- function(data) {
  # Fit linear mixed effects model
  model <- lmer(measurement ~ (1|part) + (1|operator) + (1|part:operator),
                data = data)
  
  # Extract variance components
  vc <- as.data.frame(VarCorr(model))
  
  # Calculate components
  part_var <- vc$vcov[1]  # Part-to-Part variation
  oper_var <- vc$vcov[2]  # Operator variation (Reproducibility)
  interaction_var <- vc$vcov[3]  # Part-Operator interaction
  residual_var <- vc$vcov[4]  # Equipment variation (Repeatability)
  
  # Calculate total variations
  total_grr <- sqrt(oper_var + residual_var)  # Total Gauge R&R
  total_var <- sqrt(part_var + oper_var + residual_var)  # Total Variation
  
  # Calculate percentages
  grr_percent <- (total_grr / total_var) * 100
  
  # Create results list
  results <- list(
    Part_Variation = sqrt(part_var),
    Reproducibility = sqrt(oper_var),
    Repeatability = sqrt(residual_var),
    Total_GRR = total_grr,
    Total_Variation = total_var,
    GRR_Percentage = grr_percent
  )
  
  return(results)
}

# Function to create visualization plots
create_grr_plots <- function(data) {
  # Average by Part and Operator
  avg_data <- data %>%
    group_by(part, operator) %>%
    summarize(avg_measurement = mean(measurement),
              sd_measurement = sd(measurement),
              .groups = 'drop')
  
  # Create plots
  p1 <- ggplot(avg_data, aes(x = factor(part), y = avg_measurement, color = operator)) +
    geom_point(size = 3) +
    geom_line(aes(group = operator)) +
    labs(title = "Part-by-Operator Interaction Plot",
         x = "Part Number",
         y = "Average Measurement") +
    theme_minimal()
  
  p2 <- ggplot(data, aes(x = operator, y = measurement)) +
    geom_boxplot(aes(fill = operator)) +
    labs(title = "Measurement by Operator",
         x = "Operator",
         y = "Measurement") +
    theme_minimal()
  
  return(list(interaction_plot = p1, boxplot = p2))
}

# Example usage
# Generate sample data
grr_data <- generate_grr_data()

# Calculate Gauge R&R components
results <- calculate_grr(grr_data)

# Create visualization
plots <- create_grr_plots(grr_data)

# Print results
print("Gauge R&R Analysis Results:")
print(results)

# Display plots
print(plots$interaction_plot)
print(plots$boxplot)

# Function to assess measurement system acceptability
assess_measurement_system <- function(results) {
  grr_percent <- results$GRR_Percentage
  
  if (grr_percent < 10) {
    return("Measurement system is acceptable")
  } else if (grr_percent < 30) {
    return("Measurement system may be acceptable depending on application")
  } else {
    return("Measurement system needs improvement")
  }
}

# Assess the measurement system
assessment <- assess_measurement_system(results)
print(paste("Assessment:", assessment))
