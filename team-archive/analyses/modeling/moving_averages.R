# Create data frame
data <- data.frame(
  Year = 2005:2023,
  Deaths = c(9,9,10,8,12,3,10,6,7,4,6,9,12,6,5,6,11,10,14),
  Population = c(1751721,1760435,1769912,1781949,1796619,1829542,1840672,1853303,
                 1865279,1879321,1891277,1905616,1915947,1925614,1934408,1923826,
                 1951480,1967923,1978379),
  Rate_per_100k = c(5.14,5.11,5.65,4.49,6.68,1.64,5.43,3.24,3.75,2.13,3.17,4.72,
                    6.26,3.12,2.58,3.12,5.64,5.08,7.08)
)

# Function to calculate moving average with customizable window
calculate_ma <- function(data, window_size = 4) {
  # Calculate moving average for death rates
  ma_rates <- stats::filter(data$Rate_per_100k, 
                            rep(1/window_size, window_size), 
                            sides = 2)
  
  # Create output dataframe
  result <- data.frame(
    Year = data$Year,
    Original_Rate = data$Rate_per_100k,
    Moving_Average = round(ma_rates, 2)
  )
  
  return(result)
}

# Calculate 3-year moving average
ma_4year <- calculate_ma(data, 4)

# Print first few rows of result
head(ma_4year)

# Optional: Plot the results
# If using ggplot2:
 library(ggplot2)
ggplot(ma_4year, aes(x = Year)) +
  geom_line(aes(y = Original_Rate, color = "Original Rate"), size = 1.5) +  # Increase size for bold line
  geom_line(aes(y = Moving_Average, color = "4-Year Moving Average"), size = 1.5) +  # Increase size for bold line
  theme_minimal() +
  labs(title = "Death Rates: Original vs 4-Year Moving Average",
       y = "Deaths per 1,000,000",
       color = "Series")+
  theme(plot.title = element_text(hjust = 0.5)) 