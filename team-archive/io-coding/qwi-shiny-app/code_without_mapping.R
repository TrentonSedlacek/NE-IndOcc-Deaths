library(tidyverse)
library(shiny)
library(httr)
library(jsonlite)
library(plotly)
library(DT)
library(openxlsx)

# Load industry labels (assuming it's a CSV file you can load)
industry_labels <- read_csv("H:/My Documents/R/projects/qwi_shiny_app/label_industry.csv")
age_labels <- read_csv("H:/My Documents/R/projects/qwi_shiny_app/label_agegrp.csv")
sex_labels <- read_csv("H:/My Documents/R/projects/qwi_shiny_app/label_sex.csv")


# Define UI
ui <- fluidPage(
  titlePanel("Nebraska QWI Data"),
  sidebarLayout(
    sidebarPanel(
      selectInput("data_type", "Select Data Type:", 
                  choices = c("Sex and Age" = "sa", "Sex and Education" = "se", "Race and Ethnicity" = "rh")),
      selectInput("indicator", "Select Indicator:", 
                  choices = c("Employment" = "Emp", "Job Creation" = "FrmJbGn", "Average Monthly Earnings" = "EarnS")),
      selectInput("years", "Select Years:", 
                  choices = 2023:2010, multiple = TRUE, selected = 2023),
      selectInput("quarter", "Select Quarter:", 
                  choices = 1:4, selected = 1),
      radioButtons("industry_level", "Select Industry Level:", 
                   choices = c("All" = "A", "Sector" = "S", "Subsector" = "3", "4-digit Industry" = "4")),
      uiOutput("industry_selection"),
      uiOutput("dynamic_inputs"),
      downloadButton("downloadData", "Download Table")
    ),
    mainPanel(
      plotlyOutput("qwiPlot"),
      DTOutput("qwiTable")
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  # Dynamic UI for selecting industries based on industry level
  output$industry_selection <- renderUI({
    req(input$industry_level)
    selected_level <- input$industry_level
    if (selected_level != "A") {
      industries <- subset(industry_labels, ind_level == selected_level)
      checkboxGroupInput("industries", "Select Industries:", 
                         choices = setNames(industries$industry_code, industries$industry_label))
    } else {
      return(NULL)
    }
  })
  
  # Dynamic UI for selecting characteristics based on data type
  output$dynamic_inputs <- renderUI({
    switch(input$data_type,
           "sa" = tagList(
             selectInput("sex", "Select Sex:", 
                         choices = c("All Sexes" = "0", "Male" = "1", "Female" = "2")),
             selectInput("agegrp", "Select Age Group:", 
                         choices = c("All Ages (14-99)" = "A00", "14-18" = "A01", "19-21" = "A02", "22-24" = "A03", 
                                     "25-34" = "A04", "35-44" = "A05", "45-54" = "A06", "55-64" = "A07", "65-99" = "A08"))
           ),
           "se" = tagList(
             selectInput("sex", "Select Sex:", 
                         choices = c("All Sexes" = "0", "Male" = "1", "Female" = "2")),
             selectInput("education", "Select Education:", 
                         choices = c("All Education Categories" = "E0", "Less than high school" = "E1", 
                                     "High school or equivalent, no college" = "E2", "Some college or Associate degree" = "E3", 
                                     "Bachelor's degree or advanced degree" = "E4", "Educational attainment not available" = "E5"))
           ),
           "rh" = tagList(
             selectInput("race", "Select Race:", 
                         choices = c("All Races" = "A0", "White Alone" = "A1", "Black or African American Alone" = "A2", 
                                     "American Indian or Alaska Native Alone" = "A3", "Asian Alone" = "A4", 
                                     "Native Hawaiian or Other Pacific Islander Alone" = "A5", "Some Other Race Alone (Not Used)" = "A6", 
                                     "Two or More Race Groups" = "A7")),
             selectInput("ethnicity", "Select Ethnicity:", 
                         choices = c("All Ethnicities" = "A0", "Not Hispanic or Latino" = "A1", "Hispanic or Latino" = "A2"))
           )
    )
  })
  
  # Reactive data fetching
  fetchData <- reactive({
    all_data <- data.frame()
    
    for (year in input$years) {
      if (input$industry_level == "A" || is.null(input$industries)) {
        # Construct base API call for each selected year without industry-specific parameters
        base_url <- paste0("https://api.census.gov/data/timeseries/qwi/", input$data_type, "?get=", 
                           input$indicator, "&for=state:31", "&year=", year, "&quarter=", input$quarter, 
                           "&key=fda55d10ae1222ea2b997924b0baee5d4185a81a")
        
        # Add dynamic parameters based on data type
        if (input$data_type == "sa") {
          url <- paste0(base_url, "&sex=", input$sex, "&agegrp=", input$agegrp)
        } else if (input$data_type == "se") {
          url <- paste0(base_url, "&sex=", input$sex, "&education=", input$education)
        } else if (input$data_type == "rh") {
          url <- paste0(base_url, "&race=", input$race, "&ethnicity=", input$ethnicity)
        } else {
          url <- base_url
        }
        
        response <- GET(url)
        
        if (response$status_code == 200) {
          data <- fromJSON(content(response, "text"))
          
          if (length(data) > 1) {
            df <- as.data.frame(data[-1,, drop = FALSE])
            colnames(df) <- data[1,]
            
            # Ensure that the indicator column is numeric for plotting
            df[[input$indicator]] <- as.numeric(df[[input$indicator]])
            
            # Add the year column to the data frame
            df$year <- year
            
            # Combine with the main data frame
            all_data <- rbind(all_data, df)
          }
        }
      } else {
        for (industry in input$industries) {
          # Construct base API call for each selected year and industry
          base_url <- paste0("https://api.census.gov/data/timeseries/qwi/", input$data_type, "?get=", 
                             input$indicator, "&for=state:31", "&year=", year, "&quarter=", input$quarter, 
                             "&industry=", industry, "&key=fda55d10ae1222ea2b997924b0baee5d4185a81a")
          
          # Add dynamic parameters based on data type
          if (input$data_type == "sa") {
            url <- paste0(base_url, "&sex=", input$sex, "&agegrp=", input$agegrp)
          } else if (input$data_type == "se") {
            url <- paste0(base_url, "&sex=", input$sex, "&education=", input$education)
          } else if (input$data_type == "rh") {
            url <- paste0(base_url, "&race=", input$race, "&ethnicity=", input$ethnicity)
          } else {
            url <- base_url
          }
          
          response <- GET(url)
          
          if (response$status_code == 200) {
            data <- fromJSON(content(response, "text"))
            
            if (length(data) > 1) {
              df <- as.data.frame(data[-1,, drop = FALSE])
              colnames(df) <- data[1,]
              
              # Ensure that the indicator column is numeric for plotting
              df[[input$indicator]] <- as.numeric(df[[input$indicator]])
              
              # Add the year and industry columns to the data frame
              df$year <- year
              df$industry <- industry
              
              # Combine with the main data frame
              all_data <- rbind(all_data, df)
            }
          }
        }
      }
    }
    
    return(all_data)
  })
  
  # Plot data using plotly
  output$qwiPlot <- renderPlotly({
    all_data <- fetchData()
    
    if (nrow(all_data) > 0) {
      if (input$industry_level == "A" || is.null(input$industries)) {
        # Plot data for all industries combined
        plot_ly(all_data, x = ~year, y = as.formula(paste0("~", input$indicator)), 
                type = 'bar', text = ~year, hoverinfo = 'text') |>
          layout(title = paste("QWI Data for Nebraska -", input$indicator),
                 xaxis = list(title = "Year"),
                 yaxis = list(title = input$indicator),
                 showlegend = FALSE)
      } else {
        # Convert industry codes to labels
        all_data$industry_label <- industry_labels$industry_label[match(all_data$industry, industry_labels$industry_code)]
        
        # Plot data using plotly with grouped bars
        plot_ly(all_data, x = ~year, y = as.formula(paste0("~", input$indicator)), 
                type = 'bar', color = ~industry_label, text = ~industry_label, hoverinfo = 'text') |>
          layout(title = paste("QWI Data for Nebraska -", input$indicator),
                 barmode = 'group',
                 xaxis = list(title = "Year"),
                 yaxis = list(title = input$indicator), showlegend = FALSE)
      }
    } else {
      plot_ly() |>
        add_annotations(text = "No data available", x = 1, y = 1, showarrow = FALSE) |>
        layout(xaxis = list(showticklabels = FALSE, zeroline = FALSE),
               yaxis = list(showticklabels = FALSE, zeroline = FALSE))
    }
  })
  
  # Render data table
  output$qwiTable <- renderDT({
    all_data <- fetchData()
    
    # Convert age and sex codes to labels for display in the table
    if ("agegrp" %in% colnames(all_data) && "code" %in% colnames(age_labels)) {
      all_data <- merge(all_data, age_labels, by.x = "agegrp", by.y = "code", all.x = TRUE)
      all_data <- all_data |> rename(age_label = label)
    }
    if ("sex" %in% colnames(all_data) && "code" %in% colnames(sex_labels)) {
      all_data <- merge(all_data, sex_labels, by.x = "sex", by.y = "code", all.x = TRUE)
      all_data <- all_data |> rename(sex_label = label)
    }
    
    datatable(all_data, extensions = 'Buttons', options = list(
      dom = 'Bfrtip',
      buttons = c('csv', 'excel')
    ))
  })
  
  # Download handler for data
  output$downloadData <- downloadHandler(
    filename = function() {
      paste("QWI_data_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      write_csv(fetchData(), file)
    }
  )
}

# Run the application 
shinyApp(ui = ui, server = server)