library(tidyverse); library(blsAPI); library(jsonlite); library(tidyjson)
library(treemapify); library(ggfittext); library(scales); library(lessR); library(ggthemes)


### import CFOI series for Nebraska ####
########################################

cfoi_nebraska <- read_csv("cfoi_nebraska_series.csv")



##### Total fatalities for industry private and gov sectors #########

# Using BLS API to get fatality numbers 

# case code "1" indicates all sectors (private
#
#
# federal, state, and local government)

##########################################################################


industry_fat <- cfoi_nebraska |>
  filter(case_code %in% c("1", "6", "7", "8") & category_code == "00X") |>
  mutate(rank = ntile(series_id, ceiling(length(series_id)/50)))


list_df <- split(industry_fat, industry_fat$rank) 

ntile <- ceiling(length(industry_fat$series_id)/50)


for (i in list_df[c(1:ntile)]) {
  
  payload <- list(
    'seriesid'= i$series_id,
    'startyear'= 2011,
    'endyear'= 2020,
    'registrationKey'='538da0aa9c4e48e1b550ba89ea975150')
  
  response <- blsAPI(payload, api_version = 2) 
  
  json <- fromJSON(response)
  
  
  if (!exists("results")) {
    results <- json$Results |>  bind_rows()
    fatalities_industry <- results |> unnest(data)
  
  }
  
  else {
    results <- json$Results |>  bind_rows()
    fatalities_industry <-  results |> unnest(data) |>  bind_rows() |>
      bind_rows(fatalities_industry) 
  
  }
  
}

fatalities_industry <- fatalities_industry |>
  left_join(industry_fat[, c(1,7:9)], by = c("seriesID" = "series_id"))



######## industry fatalities by exposure ###############

# Using BLS API to get fatality numbers 

# case code "1" indicates all sectors (private
#
#
# federal, state, and local government)

#########################################################

industry_fat_exposure <- cfoi_nebraska |>
  filter(case_code %in% c("1", "6", "7", "8") & category_code %in% c("E1X", "E2X", "E3X", "E4X", "E5X", "E6x")) |>
  mutate(rank = ntile(series_id, 9))


list_df <- split(industry_fat_exposure, industry_fat_exposure$rank) 

for (i in list_df[c(1:9)]) {
  
  payload <- list(
    'seriesid'= i$series_id,
    'startyear'= 2011,
    'endyear'= 2020,
    'registrationKey'='538da0aa9c4e48e1b550ba89ea975150')
  
  response <- blsAPI(payload, api_version = 2) 
  json <- fromJSON(response)
  
  if (!exists("results")) {
    results <- json$Results |>  bind_rows()
    fatalities_ind_exposure <- results |> unnest(data)
  } else {
    results <- json$Results |>  bind_rows()
    fatalities_ind_exposure <-  results |> unnest(data) |>  bind_rows() |>
      bind_rows(fatalities_ind_exposure) 
    
  }
  
}


######## industry fatalities by exposure ###############

# Using BLS API to get fatality numbers 

# case code "1" indicates all sectors (private
#
#
# federal, state, and local government)

#########################################################

   
demo_fat <- cfoi_nebraska |>
  filter(category_code %in% c("ACX","ADX","AEX","AFX","AGX","AHX","AIX","GMX","GFX",'RBN',"RBT","RFT","RHF","RHT","RNT","RWN","RWT") &
           case_code %in% c("0", "E"))  |>
  filter(industry_code == "000000" | 
           event_code %in% c("1XXXXX","2XXXXX","3XXXXX","4XXXXX","5XXXXX","6XXXXX")) |>
  mutate(rank = ntile(series_id, 2))


list_df <- split(demo_fat, demo_fat$rank) 

for (i in list_df[c(1:2)]) {
  
  payload <- list(
    'seriesid'= i$series_id,
    'startyear'= 2011,
    'endyear'= 2020,
    'registrationKey'='538da0aa9c4e48e1b550ba89ea975150')
  
  response <- blsAPI(payload, api_version = 2) 
  json <- fromJSON(response)
  
  if (!exists("results")) {
    results <- json$Results |>  bind_rows()
    fatalities_demo_exposure <- results |> unnest(data)
  } else {
    results <- json$Results |>  bind_rows()
    fatalities_demo_exposure <-  results |> unnest(data) |>  bind_rows() |>
      bind_rows(fatalities_demo_exposure) 
    
  }
  
}


fatalities_demo_exposure <- fatalities_demo_exposure |>
  left_join(demo_fat[, c(1,4,7:11)], by = c("seriesID" = "series_id"))




#WAX




##### Total fatalities for industry private and gov sectors #########

# Using BLS API to get fatality numbers 

# case code "0" indicates all sectors 
#
#
# 

#########################################################


industry_fat_mainsub <- cfoi_nebraska |>
  filter(case_code == "0" & category_code == "00X") |>
  filter(str_detect(industry_code, regex("[A-Z]{2}2[A-Z]{3}"))) |>
  mutate(rank = ntile(series_id, ceiling(length(series_id)/50)))


list_df <- split(industry_fat_mainsub, industry_fat_mainsub$rank) 

ntile <- ceiling(length(industry_fat_mainsub$series_id)/50)


for (i in list_df[c(1:ntile)]) {
  
  payload <- list(
    'seriesid'= i$series_id,
    'startyear'= 2011,
    'endyear'= 2020,
    'registrationKey'='538da0aa9c4e48e1b550ba89ea975150')
  
  response <- blsAPI(payload, api_version = 2) 
  
  json <- fromJSON(response)
  
  
  if (!exists("results")) {
    results <- json$Results |>  bind_rows()
    fatalities_industry_mainsub  <- results |> unnest(data)
    
  }
  
  else {
    results <- json$Results |>  bind_rows()
    fatalities_industry_main  <-  results |> unnest(data) |>  bind_rows() |>
      bind_rows(fatalities_industry_mainsub) 
    
  }
  
}

fatalities_industry_mainsub <- fatalities_industry_mainsub  |>
  left_join(industry_fat_mainsub[, c(1,7:9)], by = c("seriesID" = "series_id"))




################################################################################

#                           Injury data                                       #

################################################################################


soii_nebraska <- read_csv("soii_nebraska_series.csv")

industry_inj_ill <- soii_nebraska |>
  filter(data_type_code  %in% c("0", "1", "3", "4", "5") & case_type_code %in% c("1", "2")) |>
  mutate(rank = ntile(series_id, ceiling(length(series_id)/50)))


list_df <- split(industry_inj_ill, industry_inj_ill$rank) 

ntile <- ceiling(length(industry_inj_ill$series_id)/50)


for (i in list_df[c(1:ntile)]) {
  
  payload <- list(
    'seriesid'= i$series_id,
    'startyear'= 2016,
    'endyear'= 2020,
    'registrationKey'='538da0aa9c4e48e1b550ba89ea975150')
  
  response <- blsAPI(payload, api_version = 2) 
  
  json <- fromJSON(response)
  
  
  if (!exists("results")) {
    results <- json$Results |>  
      bind_rows()
    inj_ill_industry <- results |> 
      unnest(data)
  }
  
  else {
    results <- json$Results |> 
      bind_rows()
    inj_ill_industry <-  results |> unnest(data) |>  bind_rows() |>
      bind_rows(inj_ill_industry) 
    
  }
  
}


inj_ill_industry <- inj_ill_industry |>
  left_join(industry_inj_ill, by = c("seriesID" = "series_id"))



inj_ill_industry <- inj_ill_industry |>
  select(1:2, 5:6, 10:20)

write_csv(cs_industry2, "SOII_industry.csv")

inj_ill_industry <- read_csv("SOII_inj_ill_industry.csv")


inj_ill_industry$value <- as.double(inj_ill_industry$value)
inj_ill_industry$case_code <- as.character(inj_ill_industry$case_code)



cs_industry2 <- cs_industry2 |> 
  mutate(industry_text = ifelse(cs_industry2$category_code == "UTL", replace_na(industry_text, "Utilities"), industry_text)) |>
  mutate(industry_text = ifelse(cs_industry2$category_code == "WHT", replace_na(industry_text, "Wholesale trade"), industry_text)) |>
  mutate(industry_text = ifelse(cs_industry2$category_code == "TRW", replace_na(industry_text, "Transportation and warehousing"), industry_text)) |>
  mutate(industry_text = ifelse(cs_industry2$category_code == "PST", replace_na(industry_text, "Professional, scientific, and technical services"), industry_text)) |>
  mutate(industry_text = ifelse(cs_industry2$category_code == "RET", replace_na(industry_text, "Retail trade"), industry_text)) |>
  mutate(industry_text = ifelse(cs_industry2$category_code == "RRL", replace_na(industry_text, "Real estate and rental and leasing"), industry_text)) |>
  mutate(industry_text = ifelse(cs_industry2$category_code == "OTS", replace_na(industry_text, "Other services except public administration"), industry_text)) |>
  mutate(industry_text = ifelse(cs_industry2$category_code == "PAD", replace_na(industry_text, "Public administration"), industry_text)) |>
  mutate(industry_text = ifelse(cs_industry2$category_code == "MFG", replace_na(industry_text, "Manufacturing"), industry_text)) |>
  mutate(industry_text = ifelse(cs_industry2$category_code == "HAS", replace_na(industry_text, "Health care and social assistance"), industry_text)) |>
  mutate(industry_text = ifelse(cs_industry2$category_code == "INF", replace_na(industry_text, "Information"), industry_text)) |>
  mutate(industry_text = ifelse(cs_industry2$category_code == "MCE", replace_na(industry_text, "Management of companies and enterprises"), industry_text)) |>
  mutate(industry_text = ifelse(cs_industry2$category_code == "FIN", replace_na(industry_text, "Finance and insurance"), industry_text)) |>
  mutate(industry_text = ifelse(cs_industry2$category_code == "EDS", replace_na(industry_text, "Educational services"), industry_text)) |>
  mutate(industry_text = ifelse(cs_industry2$category_code == "CON", replace_na(industry_text, "Construction"), industry_text)) |>
  mutate(industry_text = ifelse(cs_industry2$category_code == "ADW", replace_na(industry_text, "Administrative and support and waste management and remediation services"), industry_text)) |>
  mutate(industry_text = ifelse(cs_industry2$category_code == "AER", replace_na(industry_text, "Arts, entertainment, and recreation"), industry_text)) |>
  mutate(industry_text = ifelse(cs_industry2$category_code == "AFH", replace_na(industry_text, "Agriculture, forestry, fishing and hunting"), industry_text)) |>
  mutate(industry_text = ifelse(cs_industry2$category_code == "AFS", replace_na(industry_text, "Accommodation and food services"), industry_text))
  
cs_industry2 <- cs_industry2 |> 
  mutate(industry_code = ifelse(cs_industry2$category_code == "UTL", replace_na(industry_code, "SP2"), industry_code)) |>
  mutate(industry_code = ifelse(cs_industry2$category_code == "WHT", replace_na(industry_code, "SP2"), industry_code)) |>
  mutate(industry_code = ifelse(cs_industry2$category_code == "TRW", replace_na(industry_code, "SP2"), industry_code)) |>
  mutate(industry_code = ifelse(cs_industry2$category_code == "PST", replace_na(industry_code, "SP2"), industry_code)) |>
  mutate(industry_code = ifelse(cs_industry2$category_code == "RET", replace_na(industry_code, "SP2"), industry_code)) |>
  mutate(industry_code = ifelse(cs_industry2$category_code == "RRL", replace_na(industry_code, "SP2"), industry_code)) |>
  mutate(industry_code = ifelse(cs_industry2$category_code == "OTS", replace_na(industry_code, "SP2"), industry_code)) |>
  mutate(industry_code = ifelse(cs_industry2$category_code == "PAD", replace_na(industry_code, "SP2"), industry_code)) |>
  mutate(industry_code = ifelse(cs_industry2$category_code == "MFG", replace_na(industry_code, "GP2"), industry_code)) |>
  mutate(industry_code = ifelse(cs_industry2$category_code == "HAS", replace_na(industry_code, "SP2"), industry_code)) |>
  mutate(industry_code = ifelse(cs_industry2$category_code == "INF", replace_na(industry_code, "SP2"), industry_code)) |>
  mutate(industry_code = ifelse(cs_industry2$category_code == "MCE", replace_na(industry_code, "SP2"), industry_code)) |>
  mutate(industry_code = ifelse(cs_industry2$category_code == "FIN", replace_na(industry_code, "SP2"), industry_code)) |>
  mutate(industry_code = ifelse(cs_industry2$category_code == "EDS", replace_na(industry_code, "SP2"), industry_code)) |>
  mutate(industry_code = ifelse(cs_industry2$category_code == "CON", replace_na(industry_code, "GP2"), industry_code)) |>
  mutate(industry_code = ifelse(cs_industry2$category_code == "ADW", replace_na(industry_text, "SP2"), industry_code)) |>
  mutate(industry_code = ifelse(cs_industry2$category_code == "AER", replace_na(industry_code, "SP2"), industry_code)) |>
  mutate(industry_code = ifelse(cs_industry2$category_code == "AFH", replace_na(industry_code, "GP2"), industry_code)) |>
  mutate(industry_code = ifelse(cs_industry2$category_code == "AFS", replace_na(industry_code, "SP2"), industry_code))

cs_industry2 <- bind_rows(cs_industry2, inj_ill_industry)

  

UTL ~ "Utilities"
WHT ~ "Wholesale trade"
TRW ~ "Transportation and warehousing"
PST ~ "Professional, scientific, and technical services"
RET ~ "Retail trade"
RRL ~ "Real estate and rental and leasing"
OTS ~ "Other services except public administration"
PAD ~ "Public administration"
MFG ~ "Manufacturing"
HAS ~ "Health care and social assistance"
INF ~ "Information"
MCE ~ "Management of companies and enterprises"
FIN ~ "Finance and insurance"
EDS ~ "Educational services"
CON ~ "Construction"
ADW ~ "Administrative and support and waste management and remediation services"
AER ~ "Arts, entertainment, and recreation"
AFH ~ "Agriculture, forestry, fishing and hunting"
AFS ~ "Accommodation and food services"


###################################################

 #                  SAVE                    #


##                Notes below            ######

###################################################
















fatalities_industry <- fatalities_industry1 |>
  bind_rows(fatalities_industry2, fatalities_industry3,fatalities_industry4,fatalities_industry5,fatalities_industry6)

fatalities_industry <- fatalities_industry |>
  left_join(industry_id[, c(1,8,9)], by = c("seriesID" = "series_id")) |>
  mutate(demographics = case_when(
    seriesID == 'FWUGMX00000080S31' ~ 'Male',
    seriesID == 'FWUGFX00000080S31' ~ 'Female', 
    seriesID == 'FWUABX00000080S31' ~ '16 to 17 years',
    seriesID == 'FWUACX00000080S31' ~ '18 to 19 years',
    seriesID == 'FWUADX00000080S31' ~ '20 to 24 years',
    seriesID == 'FWUAEX00000080S31' ~ '25 to 34 years',
    seriesID == 'FWUAFX00000080S31' ~ '35 to 44 years',
    seriesID == 'FWUAGX00000080S31' ~ '45 to 54 years',
    seriesID == 'FWUAHX00000080S31' ~ '55 to 64 years',
    seriesID == 'FWUAIX00000080S31' ~ '65 years and over', 
    TRUE ~ NA))


test5 <- test5 |>
  mutate(Category = case_when(
    seriesID == 'FWUGMX00000080S31' ~ "Sex", 
    seriesID == 'FWUGFX00000080S31' ~ "Sex",  
    seriesID == 'FWUABX00000080S31' ~ "Age_Group",  
    seriesID == 'FWUACX00000080S31' ~ "Age_Group",   
    seriesID == 'FWUADX00000080S31' ~ "Age_Group",   
    seriesID == 'FWUAEX00000080S31' ~ "Age_Group",   
    seriesID == 'FWUAFX00000080S31' ~ "Age_Group",   
    seriesID == 'FWUAGX00000080S31' ~ "Age_Group",   
    seriesID == 'FWUAHX00000080S31' ~ "Age_Group",   
    seriesID == 'FWUAIX00000080S31' ~ "Age_Group",   
    seriesID == 'FWU00XGP2AFH80S31' ~ "Industry",
    seriesID == 'FWU00XGP2MIN80S31' ~ "Industry",
    seriesID == 'FWU00XSP2UTL80S31' ~ "Industry",   
    seriesID == 'FWU00XGP1CON80S31' ~ "Industry",
    seriesID == 'FWU00XGP1MFG80S31' ~ "Industry",
    seriesID == 'FWU00XSP2WHT80S31' ~ "Industry",
    seriesID == 'FWU00XSP2RET80S31' ~ "Industry",
    seriesID == 'FWU00XSP2TRW80S31' ~ "Industry",
    seriesID == 'FWU00XSP1INF80S31' ~ "Industry",
    seriesID == 'FWU00XSP2FIN80S31' ~ "Industry",
    seriesID == 'FWU00XSP2RRL80S31' ~ "Industry",
    seriesID == 'FWU00XSP2PST80S31' ~ "Industry",
    seriesID == 'FWU00XSP2ADW80S31' ~ "Industry",
    seriesID == 'FWU00XSP2EDS80S31' ~ "Industry",
    seriesID == 'FWU00XSP2HSA80S31' ~ "Industry",
    seriesID == 'FWU00XSP2AER80S31' ~ "Industry",
    seriesID == 'FWU00XSP2AFS80S31' ~ "Industry",
    seriesID == 'FWU00XSP1OTS80S31' ~ "Industry",
    seriesID == 'FWU00XSP1PAD80S31' ~ "Industry"
  )) |>
  mutate(Name = case_when(
    seriesID == 'FWUGMX00000080S31' ~ 'Male',
    seriesID == 'FWUGFX00000080S31' ~ 'Female', 
    seriesID == 'FWUABX00000080S31' ~ '16 to 17 years',
    seriesID == 'FWUACX00000080S31' ~ '18 to 19 years',
    seriesID == 'FWUADX00000080S31' ~ '20 to 24 years',
    seriesID == 'FWUAEX00000080S31' ~ '25 to 34 years',
    seriesID == 'FWUAFX00000080S31' ~ '35 to 44 years',
    seriesID == 'FWUAGX00000080S31' ~ '45 to 54 years',
    seriesID == 'FWUAHX00000080S31' ~ '55 to 64 years',
    seriesID == 'FWUAIX00000080S31' ~ '65 years and over',
    seriesID == 'FWU00XGP2AFH80S31' ~ 'Agriculture, forestry, fishing and hunting',
    seriesID == 'FWU00XGP2MIN80S31' ~ 'Mining, quarrying, and oil and gas extraction',
    seriesID == 'FWU00XSP2UTL80S31' ~ 'Utilities',
    seriesID == 'FWU00XGP1CON80S31' ~ 'Construction',
    seriesID == 'FWU00XGP1MFG80S31' ~ 'Manufacturing',
    seriesID == 'FWU00XSP2WHT80S31' ~ 'Wholesale trade',
    seriesID == 'FWU00XSP2RET80S31' ~ 'Retail trade', 
    seriesID == 'FWU00XSP2TRW80S31' ~ 'Transportation and warehousing',
    seriesID == 'FWU00XSP1INF80S31' ~ 'Information',
    seriesID == 'FWU00XSP2FIN80S31' ~ 'Finance and insurance',
    seriesID == 'FWU00XSP2RRL80S31' ~ 'Real estate and rental and leasing',
    seriesID == 'FWU00XSP2PST80S31' ~ 'Professional, scientific, and technical services', 
    seriesID == 'FWU00XSP2ADW80S31' ~ 'Administrative and support and waste management and remediation services',
    seriesID == 'FWU00XSP2EDS80S31' ~ 'Educational services',
    seriesID == 'FWU00XSP2HSA80S31' ~ 'Health care and social assistance',
    seriesID == 'FWU00XSP2AER80S31' ~ 'Arts, entertainment, and recreation',
    seriesID == 'FWU00XSP2AFS80S31' ~ 'Accommodation and food services',
    seriesID == 'FWU00XSP1OTS80S31' ~ 'Other services, except public administration',
    seriesID == 'FWU00XSP1PAD80S31' ~ 'Public administration')) |>
  select(1,6,7,2:5)

glimpse(test5)

test5$value <- as.numeric(test5$value)

test8 <- test5 |>
  group_by(seriesID, Category, Name)|>
  summarise(deaths = sum(value))

test8 <- test8 |>
  mutate(pect_total = (deaths/242)*100)|>
  mutate_if(is.numeric, ~round(., 0)) 

test9 <- test8 |>
  filter(Category == "Industry" & pect_total >=1)





NEworker_fat_df <- read_csv("work_fatality_2015_2019.csv")


NEworker_fat_df <- NEworker_fat_df |>
  group_by(Category, Name)|>
  summarise(deaths = sum(value))


NEworker_fat_df <- NEworker_fat_df |>
  mutate(pect_total = (deaths/242)*100)|>
  mutate_if(is.numeric, ~round(., 0)) 

NEworker_fat_df_filtered <- NEworker_fat_df |>
  filter(Category == "Industry" & pect_total >=1)

NEworker_fat_df_filtered$pect_total <- as.numeric(NEworker_fat_df_filtered$pect_total)



NEworker_fat_df_agg <- read_csv("work_fatality_2015_2019_aggergated.csv")

colourCount = length(unique(NEworker_fat_df_agg$Name))
getPalette = colorRampPalette(carto_pal(12, "Vivid"))

ggplot(NEworker_fat_df_agg, aes(area = pect_total, fill = Name, label = paste(Name, percent(pect_total/100, accuracy = 1), sep = "\n")))+
  geom_treemap(color = "black") +
  geom_treemap_text(fontface = "italic", color = "white", place = "topleft",
                    grow = FALSE, reflow = TRUE) +
  scale_fill_viridis_d() + 
  theme(legend.position = "none")
  
  scale_fill_manual(values = getPalette(colourCount)) +
  

c("gray30", rep("white", 13)
)
NEworker_fat_df_agg$Name <- factor(NEworker_fat_df_agg$Name, levels = rev(c("Agriculture, forestry, fishing and hunting",	"Construction",	"Transportation and warehousing",	"Unknown", "Administrative and support and waste management and remediation services",	"Wholesale trade",	"Manufacturing",	"Retail trade",	"Real estate and rental and leasing",	"Educational services",	"Finance and insurance", "Healthcare and social assistance", "Information", "Other Sectors")),
labels = rev(c("Agriculture, forestry, fishing and hunting",	"Construction",	"Transportation and warehousing",	"Unknown", "Administrative and support and waste management and remediation services",	"Wholesale trade",	"Manufacturing",	"Retail trade",	"Real estate and rental and leasing",	"Educational services",	"Finance and insurance", "Healthcare and social assistance", "Information", "Other Sectors")))


ggplot(NEworker_fat_df_agg, aes(fill=Name, y=pect_total, x=Category)) + 
  geom_bar(position="stack", stat="identity", color = "gray22") +
  scale_fill_manual(values = getPalette(colourCount)) + 
  coord_flip() +
  labs(x=NULL, y= "Percentage") +
  guides(fill = guide_legend(reverse = TRUE, title="Industry Sectors")) +
  theme_bw()  +
  theme(
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        panel.grid.major.y = element_blank(),
        axis.line.y = element_blank(),
        legend.key = ,
        legend.key.size = 
        
        
        )

  
  





ggplot(NEworker_fat_df_filtered, aes(x = 3, y = pect_total, fill = Name)) +
  geom_col(color = "white") +
  coord_polar(theta = "y") +
  geom_text(aes(label = paste(percent(pect_total/100, accuracy = 1), sep = "")),
            position = position_stack(vjust = 0.5), size = 5, colour = c(rep("white", 12),
                                                                         1)) +
  geom_text(aes(y = pect_total + 0.5,label = Name)) +
  scale_fill_viridis_d() + 
  xlim(c(0.2, 3 + 0.5)) +
  theme(panel.background = element_rect(fill = "white"),
        panel.grid = element_blank(),
        axis.title = element_blank(),
        axis.ticks = element_blank(),
        axis.text = element_blank(),
        legend.position="none") 



  

geom_text(aes(label = paste(percent(pect_total/100, accuracy = 1), sep = "")),
          position = position_stack(vjust = 0.5), size = 5, colour = c(rep("white", 11),
                                                                       1,rep("white", 1))) +



test9 |>
  arrange(pect_total) |>    # First sort by val. This sort the dataframe but NOT the factor levels
  mutate(name=factor(Name, levels=Name)) |>   # This trick update the factor levels
  ggplot( aes(x=Name, y=pect_total)) +
  geom_segment( aes(xend=Name, yend=0)) +
  geom_point( size=4, color="orange") +
  coord_flip() +
  theme_bw() +
  xlab("")


################################################################################

#                               building tables 
 
################################################################################


cs_series_ne <- read_csv("soii_nebraska_cs_series.csv")


cs_ind_text <- cs_series_ne |>
  filter(case_code %in% c("O", "3")) |>
  filter(str_detect(occupation_code, regex("[1-9]{3}000")) | str_detect(occupation_text, regex("All occupations")) |
           str_detect(industry_code, regex("[A-Z]{2}2[A-Z]{3}")) | str_detect(industry_code, regex("^000000$"))) |>
  #filter(!str_detect(category_text, regex("Part -"))) |>
  #filter(!str_detect(category_text, regex("Hours"))) |>
  #filter(!str_detect(category_text, regex("Age group"))) |>
  filter(!str_detect(category_text, regex("Musculoskeletal disorders"))) |>
  #filter(!str_detect(category_text, regex("Source -"))) |>
  #filter(!str_detect(category_text, regex("Time"))) |>
  #filter(!str_detect(category_text, regex("Race"))) |>
  #filter(!str_detect(category_text, regex("Gender"))) |>
  filter(!str_detect(category_text, regex("LOS"))) |>
  #filter(!str_detect(category_text, regex("Weekday"))) |>
  filter(datatype_text !="Median days lost") |>
  mutate(rank = ntile(series_id, ceiling(length(series_id)/50)))

#str_detect(industry_code, regex("[A-Z]{2}2[A-Z]{3}")) | 



list_df <- split(cs_ind_text, cs_ind_text$rank) 

ntile <- ceiling(length(cs_ind_text$series_id)/50)


for (i in list_df[c(1:ntile)]) {
  
  payload <- list(
    'seriesid'= c("CSU00XGP2AFH33100", "CSU00XGP2AFH33100", "CSU00XGP2MIN33100", "CSU00XGP2CON33100", "CSU00XGP2MFG33100",	
                  "CSU00XSP2WHT33100", "CSU00XSP2RET33100",	"CSU00XSP2TRW33100", "CSU00XSP2UTL33100",	"CSU00XSP2INF33100",	
                  "CSU00XSP2FIN33100", "CSU00XSP2RRL33100",	"CSU00XSP2PST33100", "CSU00XSP2MCE33100",	"CSU00XSP2ADW33100",	
                  "CSU00XSP2EDS33100", "CSU00XSP2HSA33100",	"CSU00XSP2AER33100", "CSU00XSP2AFS33100",	"CSU00XSP2OTS33100",	
                  "CSU00XGP2CON33700", "CSU00XSP2EDS33700",	"CSU00XSP2HSA33700", "CSU00XSP2PAD33700",	"CSU00XGP2CON33800",
                  "CSU00XSP2TRW33800", "CSU00XSP2UTL33800",	"CSU00XSP2EDS33800", "CSU00XSP2HSA33800",	"CSU00XSP2PAD33800")
  ,
    'startyear'= 2016,
    'endyear'= 2020,
    'registrationKey'='63250c09f8e941a2a468d84a775ab14b')
    #63250c09f8e941a2a468d84a775ab14b   -- gmail acct
    #538da0aa9c4e48e1b550ba89ea975150   -- nebraska.gov acct 
  response <- blsAPI(payload, api_version = 2) 
  
  json <- fromJSON(response)
  
  
  if (!exists("results")) {
    results <- json$Results |>  bind_rows()
    cs_industry <- results |> unnest(data)
    
  }
  
  else {
    results <- json$Results |>  bind_rows()
    cs_industry <-  results |> unnest(data) |>  bind_rows() |>
      bind_rows(cs_industry) 
    
  }
  
}


cs_industry <- cs_industry |>
  left_join(cs_ind_text, by = c("seriesID" = "series_id"))

cs_industry2 <- cs_industry |> 
  select(1:2, 5:6, 9:14, 25:26, 29:34, 42:43)

cs_industry <- cs_industry |> 
  filter()

  
write_csv(cs_industry, "cs_industry_US.csv")

cs_industry2 <- read_csv("cs_industry.csv")


########################## building fatality table ############################# 
################################################################################


fw.series$series_id <- str_trim(fw.series$series_id, side = "both")


fw_series_ne <- fw.series |>
  filter(str_detect(series_id, "S31$"))

fw_series_ne <- fw_series_ne |>
  mutate(case_code_text = case_when(
  case_code == "0" ~ "Fatalities in all sectors",
  case_code == "1" ~ "Fatalities by detailed private industry",
  case_code == "6" ~ "Fatalities by detailed federal government industry",
  case_code == "7" ~ "Fatalities by detailed state government industry",
  case_code == "8" ~ "Fatalities by detailed local government industry",
  case_code == "9" ~ "Fatalities by detailed government industry",
  case_code == "E" ~ "Fatalities by detailed event or exposure",
  case_code == "G" ~ "Fatalities by detailed government occupation",
  case_code == "O" ~ "Fatalities by detailed occupation (all sectors)",
  case_code == "P" ~ "Fatalities by detailed private occupation",
  case_code == "S" ~ "Fatalities by primary source of injury",
  case_code == "T" ~ "Fatalities by secondary source of injury")) |>
  select(1:5, 16, 6:15)


fw_series_ne <- fw_series_ne |>
  left_join(fw.category2, by = "category_code") |>
  select(1:3, 17, 4:16)


fw_series_ne <- fw_series_ne |>
  left_join(fw.industry[, c(1,2)], by = "industry_code") |>
  select(1:8, 18, 9:17)

fw_series_ne <- fw_series_ne |>
  left_join(fw.event[, c(1,2)], by = "event_code") |>
  select(1:10, 19, 11:18)

fw_series_ne <- fw_series_ne |>
  left_join(fw.source[, c(1,2)], by = "source_code") |>
  select(1:12, 20, 13:19)

fw_series_ne <- fw_series_ne |>
  left_join(fw.occupation[, c(1,2)], by = "occupation_code") |>
  select(1:14, 21, 15:20) 


  
write_csv(fatalities_demo_exposure, "cfoi_nebraska_fatalities_demo_exposure.csv")


df <- fatalities_industry_main |>
  filter(year %in% c("2016", "2017", "2018", "2019", "2020")) |>
  group_by(industry_text) |>
  arrange(year) |>
  summarise(year = year, deaths = value) |>
  print(n = 60)

clipr::write_clip(df)





payload <- list(
  'seriesid'= c("ENU3100010511212",
                "ENU3100310511212",
                "ENU3101910511212",
                "ENU3102310511212",
                "ENU3102710511212",
                "ENU3103510511212",
                "ENU3103710511212",
                "ENU3103910511212",
                "ENU3104110511212",
                "ENU3104310511212",
                "ENU3105310511212",
                "ENU3105510511212",
                "ENU3106510511212",
                "ENU3106710511212",
                "ENU3108910511212",
                "ENU3109510511212",
                "ENU3109910511212",
                "ENU3110310511212",
                "ENU3110710511212",
                "ENU3110910511212",
                "ENU3111910511212",
                "ENU3113110511212",
                "ENU3113910511212",
                "ENU3114110511212",
                "ENU3114310511212",
                "ENU3114510511212",
                "ENU3114710511212",
                "ENU3115910511212",
                "ENU3117310511212",
                "ENU3117710511212",
                "ENU3117910511212")
  ,
  'startyear'= 2016,
  'endyear'= 2022,
  'registrationKey'='7683a2eda3284492939d639f0a51ff7e')
#63250c09f8e941a2a468d84a775ab14b   -- gmail acct
#7683a2eda3284492939d639f0a51ff7e   -- nebraska.gov acct 
response <- blsAPI(payload, api_version = 2) 

json <- fromJSON(response)



results <- json$Results |>   unnest(data)
dairy_employment <- results |> unnest(data) |>  bind_rows() 
