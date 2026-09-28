library(tidyverse)


######################################################################## 

#/                   import hdd data                                 /#

########################################################################

hdd_ip_16 <- haven::read_sas("IP16.sas7bdat")
hdd_ip_17 <- haven::read_sas("IP17_Old.sas7bdat")
hdd_ip_18 <- haven::read_sas("IP18_Old.sas7bdat")
hdd_ip_19 <- haven::read_sas("IP19_Old.sas7bdat")
hdd_ip_20 <- haven::read_sas("IP20_Old.sas7bdat")


hdd_ip_16 <- hdd_ip_16 |>
  select(PAYERCD, PATYRS, PATSEX, starts_with(c("DIAG", "ECODE")), STATE) |> 
  filter(PAYERCD == "05" | if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., "Y990|Y991|Y9261|Y9262|Y9263|Y9263|Y9264|Y9265|Y9269|Y9271|Y9272|Y9273|Y9274|Y9279|Z042|Z576|Z578"))) |>
  filter(STATE == "NE")

hdd_ip_17 <- hdd_ip_17 |>
  select(PAYERCD, PATYRS, PATSEX, starts_with(c("DIAG", "ECODE")), STATE) |> 
  filter(PAYERCD == "05" | if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., "Y990|Y991|Y9261|Y9262|Y9263|Y9263|Y9264|Y9265|Y9269|Y9271|Y9272|Y9273|Y9274|Y9279|Z042|Z576|Z578"))) |>
  mutate(year = "2017") |>
  filter(STATE == "NE")

hdd_ip_18 <- hdd_ip_18 |>
  select(PAYERCD, PATYRS, PATSEX, starts_with(c("DIAG", "ECODE")), STATE) |> 
  filter(PAYERCD == "05" | if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., "Y990|Y991|Y9261|Y9262|Y9263|Y9263|Y9264|Y9265|Y9269|Y9271|Y9272|Y9273|Y9274|Y9279|Z042|Z576|Z578"))) |>
  mutate(year = "2018") |>
  filter(STATE == "NE")

hdd_ip_19 <- hdd_ip_19 |>
  select(PAYERCD, PATYRS, PATSEX, starts_with(c("DIAG", "ECODE")), STATE) |> 
  filter(PAYERCD == "05" | if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., "Y990|Y991|Y9261|Y9262|Y9263|Y9263|Y9264|Y9265|Y9269|Y9271|Y9272|Y9273|Y9274|Y9279|Z042|Z576|Z578"))) |>
  mutate(year = "2019") |>
  filter(STATE == "NE")


hdd_ip_20 <- rename(hdd_ip_20, DIAG1 = DXP, DIAG2 = DX_2, DIAG3 = DX_3, DIAG4 = DX_4, DIAG5 = DX_5, DIAG6 = DX_6, DIAG7 = DX_7, DIAG8 = DX_8, DIAG9 = DX_9, DIAG10 = DX_10, 
                    DIAG11 = DX_11, DIAG12 = DX_12, DIAG13 = DX_13, DIAG14 = DX_14, DIAG15 = DX_15, DIAG16 = DX_16, DIAG17 = DX_17, DIAG18 = DX_18, DIAG19 = DX_19, 
                    DIAG20 = DX_20, DIAG21 = DX_21, DIAG22 = DX_22,  DIAG23 = DX_23, DIAG24 = DX_24, DIAG25 = DX_25, ECODE1 = DXE1, ECODE2 = DXE2, ECODE3 = DXE3,
                    PATYRS = AGE_YEARS, PATSEX = SEX, PAYERCD = SOP1, STATE = ST) 

hdd_ip_20 <- hdd_ip_20 |>
  select(PAYERCD, PATYRS, PATSEX, starts_with(c("DIAG", "ECODE")), STATE) |> 
  filter(PAYERCD == "05" | if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., "Y990|Y991|Y9261|Y9262|Y9263|Y9263|Y9264|Y9265|Y9269|Y9271|Y9272|Y9273|Y9274|Y9279|Z042|Z576|Z578"))) |>
  mutate(year = "2020") |> 
  filter(STATE == "NE")


hdd_ip_bind <- hdd_ip_16 |>
  bind_rows(hdd_ip_17, hdd_ip_18, hdd_ip_19, hdd_ip_20) |>
  #na_if("") |>
  filter(PATYRS >= 16) 



######################################################################

#/              Unintentional injury analysis   

######################################################################

#/ import ICD-10-CM codes for unintentional injuries
injury_icd10_unintent <- readxl::read_xlsx("2021 ICD-10-CM_Non-Poisoning_Cause_Matrix  ALL codes 112021.xlsx", sheet = "Unintentional") 
#injury_icd10_unintent$ICD10CM <- str_trunc(injury_icd10_unintent$ICD10CM, 3, side = c("right"), ellipsis = "") 

injury_icd10_poison_unintent <- readxl::read_xlsx("2021 ICD-10-CM_Poisoning_Matrix ALL codes 112021.xlsx", sheet = "Unintentional")

#/ import ICD-10-CM codes for unintentional injuries
injury_matrix <- readxl::read_xlsx("112021 2021 revisions to 2016 Proposed ICD10CM Inj Dx Matrix.xlsx")

injury_matrix$ICD_Full <- str_replace_all(injury_matrix$ICD_Full, "\\.", "")

matrix_codes <- injury_matrix$ICD_Full

poison <- injury_icd10_poison_unintent$ICD10CM

#poison <- unique(str_trunc(injury_icd10_poison_unintent$ICD10CM, 3, side = c("right"), ellipsis = ""))


cut_pierce <- injury_icd10_unintent |>
  filter(MECHANISM == "Cut/Pierce") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


drowning <- injury_icd10_unintent |>
  filter(MECHANISM == "Drowning/Submersion") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


falls <- injury_icd10_unintent |>
  filter(MECHANISM == "Fall") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


machinery <- injury_icd10_unintent |>
  filter(MECHANISM == "Machinery") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


fireburns <- injury_icd10_unintent |>
  filter(MECHANISM %in% c("Fire/Flame", "Hot Object/Substance")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

firearm <- injury_icd10_unintent |>
  filter(MECHANISM == "Firearm") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

struck <- injury_icd10_unintent |>
  filter(MECHANISM == "Struck by/against") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

mvt <- injury_icd10_unintent |>
  filter(MECHANISM %in% c("MVT-Occupant", "MVT-Motorcyclist", "MVT-Pedal Cyclist", "MVT-Pedestrian", "MVT-Other")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

mvt_nontraffic <- injury_icd10_unintent |>
  filter(MECHANISM == "Motor Vehicle-Nontraffic") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

other_transport <- injury_icd10_unintent |>
  filter(MECHANISM %in% c("Other Land Transport", "Other Transport")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

ped_cyclist_other <- injury_icd10_unintent |>
  filter(MECHANISM == "Pedal cyclist, other") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

pedestrian_other <- injury_icd10_unintent |>
  filter(MECHANISM == "Pedestrian, other") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

bites_stings <- injury_icd10_unintent |>
  filter(MECHANISM %in% c("Bites and Stings, nonvenomous", "Bites and Stings, venomous")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

nature_environment <- injury_icd10_unintent |>
  filter(MECHANISM == "Natural/Environmental, Other") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

overexertion <- injury_icd10_unintent |>
  filter(MECHANISM == "Overexertion") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

suffocation <- injury_icd10_unintent |>
  filter(MECHANISM == "Suffocation") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


other_specified <- injury_icd10_unintent |>
  filter(MECHANISM %in% c("Other Specified, Foreign Body", "Other Specified, Classifiable")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

unspecified <- injury_icd10_unintent |>
  filter(MECHANISM == "Unspecified") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

### inury matrix ######


head_neck <- injury_matrix |>
  filter(Body_Level_1 == "Head and Neck") |>
  pull(ICD_Full)


spine_back <- injury_matrix |>
  filter(Body_Level_1 == "Spine and Back") |>
  pull(ICD_Full)


torso <- injury_matrix |>
  filter(Body_Level_1 == "Torso") |>
  pull(ICD_Full)

extremities <- injury_matrix |>
  filter(Body_Level_1 == "Extremities") |>
  pull(ICD_Full)


unclassified <- injury_matrix |>
  filter(Body_Level_1 == "Unclassifiable by body region") |>
  pull(ICD_Full)


unspecified <- injury_matrix |>
  filter(Body_Level_1 == "Unspecified") |>
  pull(ICD_Full)

#########
#########


hdd_ip_bind_unintent <- hdd_ip_bind |>
  mutate(cause = case_when(
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(cut_pierce, collapse = "|^"))) ~ "Cut/Pierce",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(drowning, collapse = "|^"))) ~ "Drowning/Submersion",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(falls, collapse = "|^"))) ~ "Fall", 
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(machinery, collapse = "|^"))) ~ "Machinery", 
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(fireburns, collapse = "|^"))) ~ "Fire/Burn",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(firearm, collapse = "|^"))) ~ "Firearm",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(struck, collapse = "|^"))) ~ "Struck by/against", 
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(mvt, collapse = "|^"))) ~ "Motor Vehicle Traffic",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(mvt_nontraffic, collapse = "|^"))) ~ "Motor Vehicle-Nontraffic",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(other_transport, collapse = "|^"))) ~ "Other Transport",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(overexertion, collapse = "|^"))) ~ "Overexertion",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(suffocation, collapse = "|^"))) ~ "Suffocation",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(ped_cyclist_other, collapse = "|^"))) ~ "Pedal cyclist, other",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(pedestrian_other, collapse = "|^"))) ~ "Pedestrian, other",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(nature_environment, collapse = "|^"))) ~ "Natural/Environmental, Other",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(bites_stings, collapse = "|^"))) ~ "Bites and Stings",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(other_specified, collapse = "|^"))) ~ "Other Specified",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(unspecified, collapse = "|^"))) ~ "Unspecified", 
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(poison, collapse = "|^"))) ~ "Poisoning"
    )
  ) 

hdd_ip_bind_unintent_cnt <- hdd_ip_bind_unintent |>
  count(cause)





hdd_ip_bind_unintent <- hdd_ip_bind |>
  mutate(Cut_Pierce = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(cut_pierce, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Drowning_Submersion = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(drowning, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Falls = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(falls, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Machinery = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(machinery, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Fire_Burns = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(fireburns, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Firearm = case_when(if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(firearm, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Struck_by_against = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(struck, collapse = "|^"))) ~ 1, TRUE ~ 0)) |> 
  mutate(Motor_Vehicle_Traffic = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(mvt, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Motor_Vehicle_Nontraffic = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(mvt_nontraffic, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Other_Transport = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(other_transport, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Overexertion = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(overexertion, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Suffocation = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(suffocation, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Ped_Cyclist_Other = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(ped_cyclist_other, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Pedestrian_Other = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(pedestrian_other, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Nature_Environment = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(nature_environment, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Bites_Stings = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(bites_stings, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Other_Specified = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(other_specified, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Unspecified = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(unspecified, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Poison = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(poison, collapse = "|^"))) ~ 1, TRUE ~ 0))
 



hdd_ip_bind_unintent_cnt <- hdd_ip_bind_unintent |>
  select(35:53) |>                                 # select columns only needed  
  #group_by(cause)  |>
  summarise(across(everything(), sum)) 







intent_causes <- c(injury_icd10_unintent$ICD10CM, injury_icd10_poison_unintent$ICD10CM)


hdd_ip_bind_unintent2 <- hdd_ip_bind |>
  filter(if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(intent_causes , collapse = "|^"))))

 
 hdd_ip_bind_unintent_body <- hdd_ip_bind_unintent |>
    mutate(head_neck = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(head_neck, collapse = "|^"))) ~ 1, TRUE ~ 0)) |> 
    mutate(spine_back = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(spine_back, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>       
    mutate(torso = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(torso, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>         
    mutate(extremities = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(extremities, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
    mutate(unclassified_body = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(unclassified, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
    mutate(unspecified_body = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(unspecified, collapse = "|^"))) ~ 1, TRUE ~ 0))
 

 
 hdd_ip_bind_unintent_body_cnt <- hdd_ip_bind_unintent_body |>
  select(35:40) |>                                 # select columns only needed  
  group_by(cause)  |>
  summarise(across(everything(), sum)) |>               # summaries data to get sum of drugs by grouping
  rowwise() |>
  ungroup()
  
    





write_csv(hdd_ip_bind_unintent_cnt, "wc_hdd_cause_unintent_cnt2.csv")

write_csv(hdd_ip_bind_unintent_body_cnt, "wc_hdd_cause_unintent_body_cnt.csv")



#hdd_ip_bind_wc_matrix <- hdd_ip_bind_wc |>
  #filter(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(matrix_codes, collapse = "|^"))))






################################################################################
################################################################################


injury_icd10_intent <- readxl::read_xlsx("2021 ICD-10-CM_Non-Poisoning_Cause_Matrix  ALL codes 112021.xlsx", sheet = "Intentional Self-harm")
#injury_icd10_intent$ICD10CM <- str_trunc(injury_icd10_intent$ICD10CM, 3, side = c("right"), ellipsis = "") 

injury_icd10_poison_intent <- readxl::read_xlsx("2021 ICD-10-CM_Poisoning_Matrix ALL codes 112021.xlsx", sheet = "Intentional Self-harm")


poison <- injury_icd10_poison_intent$ICD10CM
  
#unique(str_trunc(injury_icd10_poison_intent$ICD10CM, 3, side = c("right"), ellipsis = "")) 


cut_pierce <- injury_icd10_intent |>
  filter(MECHANISM == "Cut/Pierce") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


drowning <- injury_icd10_intent |>
  filter(MECHANISM == "Drowning/Submersion") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


falls <- injury_icd10_intent |>
  filter(MECHANISM == "Fall") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


machinery <- injury_icd10_intent |>
  filter(MECHANISM == "Machinery") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


fireburns <- injury_icd10_intent |>
  filter(MECHANISM %in% c("Fire/Flame", "Hot Object/Substance")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

firearm <- injury_icd10_intent |>
  filter(MECHANISM == "Firearm") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

struck <- injury_icd10_intent |>
  filter(MECHANISM == "Struck by/against") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

mvt <- injury_icd10_intent |>
  filter(MECHANISM %in% c("MVT-Occupant", "MVT-Motorcyclist", "MVT-Pedal Cyclist", "MVT-Pedestrian", "MVT-Other")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

mvt_nontraffic <- injury_icd10_intent |>
  filter(MECHANISM == "Motor Vehicle-Nontraffic") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

other_transport <- injury_icd10_intent |>
  filter(MECHANISM %in% c("Other Land Transport", "Other Transport")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

ped_cyclist_other <- injury_icd10_intent |>
  filter(MECHANISM == "Pedal cyclist, other") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

pedestrian_other <- injury_icd10_intent |>
  filter(MECHANISM == "Pedestrian, other") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

bites_stings <- injury_icd10_intent |>
  filter(MECHANISM %in% c("Bites and Stings, nonvenomous", "Bites and Stings, venomous")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

nature_environment <- injury_icd10_intent |>
  filter(MECHANISM == "Natural/Environmental, Other") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

overexertion <- injury_icd10_intent |>
  filter(MECHANISM == "Overexertion") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

suffocation <- injury_icd10_intent |>
  filter(MECHANISM == "Suffocation") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


other_specified <- injury_icd10_intent |>
  filter(MECHANISM %in% c("Other Specified, Foreign Body", "Other Specified, Classifiable")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

unspecified <- injury_icd10_intent |>
  filter(MECHANISM == "Unspecified") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


hdd_ip_bind_wc_na <- hdd_ip_bind_unintent |>
  filter(is.na(cause))


hdd_ip_bind_intent <-hdd_ip_bind_wc_na |>
  mutate(cause = case_when(
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(cut_pierce, collapse = "|^"))) ~ "Cut/Pierce",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(drowning, collapse = "|^"))) ~ "Drowning/Submersion",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(falls, collapse = "|^"))) ~ "Fall", 
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(machinery, collapse = "|^"))) ~ "Machinery", 
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(fireburns, collapse = "|^"))) ~ "Fire/Burn",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(firearm, collapse = "|^"))) ~ "Firearm",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(struck, collapse = "|^"))) ~ "Struck by/against", 
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(mvt, collapse = "|^"))) ~ "Motor Vehicle Traffic",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(mvt_nontraffic, collapse = "|^"))) ~ "Motor Vehicle-Nontraffic",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(other_transport, collapse = "|^"))) ~ "Other Transport",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(overexertion, collapse = "|^"))) ~ "Overexertion",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(suffocation, collapse = "|^"))) ~ "Suffocation",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(ped_cyclist_other, collapse = "|^"))) ~ "Pedal cyclist, other",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(pedestrian_other, collapse = "|^"))) ~ "Pedestrian, other",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(nature_environment, collapse = "|^"))) ~ "Natural/Environmental, Other",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(bites_stings, collapse = "|^"))) ~ "Bites and Stings",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(other_specified, collapse = "|^"))) ~ "Other Specified",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(unspecified, collapse = "|^"))) ~ "Unspecified", 
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(poison, collapse = "|^"))) ~ "Poisoning"
  )
  ) 


hdd_ip_bind_intent_cnt <- hdd_ip_bind_intent |>
  count(cause)

hdd_ip_bind_intent <- hdd_ip_bind |>
  mutate(Cut_Pierce = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(cut_pierce, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Drowning_Submersion = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(drowning, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Falls = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(falls, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Machinery = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(machinery, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Fire_Burns = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(fireburns, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Firearm = case_when(if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(firearm, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Struck_by_against = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(struck, collapse = "|^"))) ~ 1, TRUE ~ 0)) |> 
  mutate(Motor_Vehicle_Traffic = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(mvt, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Motor_Vehicle_Nontraffic = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(mvt_nontraffic, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Other_Transport = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(other_transport, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Overexertion = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(overexertion, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Suffocation = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(suffocation, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Ped_Cyclist_Other = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(ped_cyclist_other, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Pedestrian_Other = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(pedestrian_other, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Nature_Environment = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(nature_environment, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Bites_Stings = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(bites_stings, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Other_Specified = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(other_specified, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Unspecified = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(unspecified, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Poison = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(poison, collapse = "|^"))) ~ 1, TRUE ~ 0))



hdd_ip_bind_intent_cnt <- hdd_ip_bind_intent |>
  select(35:47) |>                                 # select columns only needed  
  #group_by(cause)  |>
  summarise(across(everything(), sum)) 




write_csv(hdd_ip_bind_intent_cnt, "wc_hdd_cause_intent_cnt.csv")

#######################

injury_icd10_assault <- readxl::read_xlsx("2021 ICD-10-CM_Non-Poisoning_Cause_Matrix  ALL codes 112021.xlsx", sheet = "Assault")
#injury_icd10_assault$ICD10CM <- str_trunc(injury_icd10_assault$ICD10CM, 3, side = c("right"), ellipsis = "") 


injury_icd10_poison_assault <- readxl::read_xlsx("2021 ICD-10-CM_Poisoning_Matrix ALL codes 112021.xlsx", sheet = "Assault")

poison <- injury_icd10_poison_assault$ICD10CM
  
#str_trunc(injury_icd10_poison_assault$ICD10CM, 3, side = c("right"), ellipsis = "") 


cut_pierce <- injury_icd10_assault |>
  filter(MECHANISM == "Cut/Pierce") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


drowning <- injury_icd10_assault |>
  filter(MECHANISM == "Drowning/Submersion") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


falls <- injury_icd10_assault |>
  filter(MECHANISM == "Fall") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


machinery <- injury_icd10_assault |>
  filter(MECHANISM == "Machinery") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


fireburns <- injury_icd10_assault |>
  filter(MECHANISM %in% c("Fire/Flame", "Hot Object/Substance")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

firearm <- injury_icd10_assault |>
  filter(MECHANISM == "Firearm") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

struck <- injury_icd10_assault |>
  filter(MECHANISM == "Struck by/against") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

mvt <- injury_icd10_assault |>
  filter(MECHANISM %in% c("MVT-Occupant", "MVT-Motorcyclist", "MVT-Pedal Cyclist", "MVT-Pedestrian", "MVT-Other")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

mvt_nontraffic <- injury_icd10_assault |>
  filter(MECHANISM == "Motor Vehicle-Nontraffic") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

other_transport <- injury_icd10_assault |>
  filter(MECHANISM %in% c("Other Land Transport", "Other Transport")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

ped_cyclist_other <- injury_icd10_assault |>
  filter(MECHANISM == "Pedal cyclist, other") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

pedestrian_other <- injury_icd10_assault |>
  filter(MECHANISM == "Pedestrian, other") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

bites_stings <- injury_icd10_assault |>
  filter(MECHANISM %in% c("Bites and Stings, nonvenomous", "Bites and Stings, venomous")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

nature_environment <- injury_icd10_assault |>
  filter(MECHANISM == "Natural/Environmental, Other") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

overexertion <- injury_icd10_assault |>
  filter(MECHANISM == "Overexertion") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

suffocation <- injury_icd10_assault |>
  filter(MECHANISM == "Suffocation") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


other_specified <- injury_icd10_assault |>
  filter(MECHANISM %in% c("Other Specified, Foreign Body", "Other Specified, Classifiable")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

unspecified <- injury_icd10_assault |>
  filter(MECHANISM == "Unspecified") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


hdd_ip_bind_wc_na <- hdd_ip_bind_intent |>
  filter(is.na(cause))




hdd_ip_bind_wc_assault <- hdd_ip_bind_wc_na |>
  mutate(cause = case_when(
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(cut_pierce, collapse = "|^"))) ~ "Cut/Pierce",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(drowning, collapse = "|^"))) ~ "Drowning/Submersion",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(falls, collapse = "|^"))) ~ "Fall", 
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(machinery, collapse = "|^"))) ~ "Machinery", 
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(fireburns, collapse = "|^"))) ~ "Fire/Burn",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(firearm, collapse = "|^"))) ~ "Firearm",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(struck, collapse = "|^"))) ~ "Struck by/against", 
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(mvt, collapse = "|^"))) ~ "Motor Vehicle Traffic",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(mvt_nontraffic, collapse = "|^"))) ~ "Motor Vehicle-Nontraffic",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(other_transport, collapse = "|^"))) ~ "Other Transport",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(overexertion, collapse = "|^"))) ~ "Overexertion",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(suffocation, collapse = "|^"))) ~ "Suffocation",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(ped_cyclist_other, collapse = "|^"))) ~ "Pedal cyclist, other",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(pedestrian_other, collapse = "|^"))) ~ "Pedestrian, other",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(nature_environment, collapse = "|^"))) ~ "Natural/Environmental, Other",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(bites_stings, collapse = "|^"))) ~ "Bites and Stings",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(other_specified, collapse = "|^"))) ~ "Other Specified",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(unspecified, collapse = "|^"))) ~ "Unspecified", 
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(poison, collapse = "|^"))) ~ "Poisoning"
  )
  ) 



hdd_ip_bind_assault_cnt <- hdd_ip_bind_wc_assault |>
  count(cause)


hdd_ip_bind_assault <- hdd_ip_bind |>
  mutate(Cut_Pierce = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(cut_pierce, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Drowning_Submersion = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(drowning, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Falls = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(falls, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Machinery = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(machinery, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Fire_Burns = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(fireburns, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Firearm = case_when(if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(firearm, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Struck_by_against = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(struck, collapse = "|^"))) ~ 1, TRUE ~ 0)) |> 
  mutate(Motor_Vehicle_Traffic = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(mvt, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Motor_Vehicle_Nontraffic = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(mvt_nontraffic, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Other_Transport = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(other_transport, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Overexertion = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(overexertion, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Suffocation = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(suffocation, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Ped_Cyclist_Other = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(ped_cyclist_other, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Pedestrian_Other = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(pedestrian_other, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Nature_Environment = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(nature_environment, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Bites_Stings = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(bites_stings, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Other_Specified = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(other_specified, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Unspecified = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(unspecified, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Poison = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(poison, collapse = "|^"))) ~ 1, TRUE ~ 0))

hdd_ip_bind_assault_cnt <- hdd_ip_bind_assault |>
  select(35:47) |>                                 # select columns only needed  
  #group_by(cause)  |>
  summarise(across(everything(), sum))

write_csv(hdd_ip_bind_assault_cnt, "wc_hdd_cause_assault_cnt.csv")


###################################################################

injury_icd10_undetermined <- readxl::read_xlsx("2021 ICD-10-CM_Non-Poisoning_Cause_Matrix  ALL codes 112021.xlsx", sheet = "Undetermined")
#injury_icd10_undetermined$ICD10CM <- str_trunc(injury_icd10_undetermined$ICD10CM, 3, side = c("right"), ellipsis = "") 


injury_icd10_poison_undetermined <- readxl::read_xlsx("2021 ICD-10-CM_Poisoning_Matrix ALL codes 112021.xlsx", sheet = "Undetermined")

poison <- injury_icd10_poison_undetermined$ICD10CM
  
#str_trunc(injury_icd10_poison_undetermined$ICD10CM, 3, side = c("right"), ellipsis = "") 


cut_pierce <- injury_icd10_undetermined |>
  filter(MECHANISM == "Cut/Pierce") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


drowning <- injury_icd10_undetermined |>
  filter(MECHANISM == "Drowning/Submersion") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


falls <- injury_icd10_undetermined |>
  filter(MECHANISM == "Fall") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


machinery <- injury_icd10_undetermined |>
  filter(MECHANISM == "Machinery") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


fireburns <- injury_icd10_undetermined |>
  filter(MECHANISM %in% c("Fire/Flame", "Hot Object/Substance")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

firearm <- injury_icd10_undetermined |>
  filter(MECHANISM == "Firearm") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

struck <- injury_icd10_undetermined |>
  filter(MECHANISM == "Struck by/against") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

mvt <- injury_icd10_undetermined |>
  filter(MECHANISM %in% c("MVT-Occupant", "MVT-Motorcyclist", "MVT-Pedal Cyclist", "MVT-Pedestrian", "MVT-Other")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

mvt_nontraffic <- injury_icd10_undetermined |>
  filter(MECHANISM == "Motor Vehicle-Nontraffic") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

other_transport <- injury_icd10_undetermined |>
  filter(MECHANISM %in% c("Other Land Transport", "Other Transport")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

ped_cyclist_other <- injury_icd10_undetermined |>
  filter(MECHANISM == "Pedal cyclist, other") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

pedestrian_other <- injury_icd10_undetermined |>
  filter(MECHANISM == "Pedestrian, other") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

bites_stings <- injury_icd10_undetermined |>
  filter(MECHANISM %in% c("Bites and Stings, nonvenomous", "Bites and Stings, venomous")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

nature_environment <- injury_icd10_undetermined |>
  filter(MECHANISM == "Natural/Environmental, Other") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

overexertion <- injury_icd10_undetermined |>
  filter(MECHANISM == "Overexertion") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

suffocation <- injury_icd10_undetermined |>
  filter(MECHANISM == "Suffocation") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


other_specified <- injury_icd10_undetermined |>
  filter(MECHANISM %in% c("Other Specified, Foreign Body", "Other Specified, Classifiable")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

unspecified <- injury_icd10_undetermined |>
  filter(MECHANISM == "Unspecified") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 



hdd_ip_bind_wc_na <- hdd_ip_bind_wc_assault |>
  filter(is.na(cause))



hdd_ip_bind_undetermined <-hdd_ip_bind_wc_na |>
  mutate(cause = case_when(
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(cut_pierce, collapse = "|^"))) ~ "Cut/Pierce",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(drowning, collapse = "|^"))) ~ "Drowning/Submersion",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(falls, collapse = "|^"))) ~ "Fall", 
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(machinery, collapse = "|^"))) ~ "Machinery", 
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(fireburns, collapse = "|^"))) ~ "Fire/Burn",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(firearm, collapse = "|^"))) ~ "Firearm",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(struck, collapse = "|^"))) ~ "Struck by/against", 
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(mvt, collapse = "|^"))) ~ "Motor Vehicle Traffic",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(mvt_nontraffic, collapse = "|^"))) ~ "Motor Vehicle-Nontraffic",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(other_transport, collapse = "|^"))) ~ "Other Transport",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(overexertion, collapse = "|^"))) ~ "Overexertion",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(suffocation, collapse = "|^"))) ~ "Suffocation",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(ped_cyclist_other, collapse = "|^"))) ~ "Pedal cyclist, other",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(pedestrian_other, collapse = "|^"))) ~ "Pedestrian, other",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(nature_environment, collapse = "|^"))) ~ "Natural/Environmental, Other",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(bites_stings, collapse = "|^"))) ~ "Bites and Stings",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(other_specified, collapse = "|^"))) ~ "Other Specified",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(unspecified, collapse = "|^"))) ~ "Unspecified", 
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(poison, collapse = "|^"))) ~ "Poisoning"
  )
  ) 


hdd_ip_bind_undetermined_cnt <- hdd_ip_bind_undetermined |>
   count(cause)


hdd_ip_bind_undetermined <- hdd_ip_bind |>
  mutate(Cut_Pierce = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(cut_pierce, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Drowning_Submersion = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(drowning, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Falls = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(falls, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Machinery = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(machinery, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Fire_Burns = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(fireburns, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Firearm = case_when(if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(firearm, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Struck_by_against = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(struck, collapse = "|^"))) ~ 1, TRUE ~ 0)) |> 
  #mutate(Motor_Vehicle_Traffic = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(mvt, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Motor_Vehicle_Nontraffic = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(mvt_nontraffic, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Other_Transport = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(other_transport, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Overexertion = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(overexertion, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Suffocation = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(suffocation, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Ped_Cyclist_Other = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(ped_cyclist_other, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Pedestrian_Other = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(pedestrian_other, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Nature_Environment = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(nature_environment, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Bites_Stings = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(bites_stings, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Other_Specified = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(other_specified, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Unspecified = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(unspecified, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Poison = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(poison, collapse = "|^"))) ~ 1, TRUE ~ 0))

hdd_ip_bind_undetermined_cnt <- hdd_ip_bind_undetermined |>
  select(35:45) |>                                 # select columns only needed  
  summarise(across(everything(), sum))


write_csv(hdd_ip_bind_wc_undetermined_cnt, "wc_hdd_cause_undetermined_cnt.csv")

#####################################################

injury_icd10_legal <- readxl::read_xlsx("2021 ICD-10-CM_Non-Poisoning_Cause_Matrix  ALL codes 112021.xlsx", sheet = "Legal Intervention-War")
#injury_icd10_legal$ICD10CM <- str_trunc(injury_icd10_legal$ICD10CM, 3, side = c("right"), ellipsis = "") 


injury_icd10_poison_legal <- readxl::read_xlsx("2021 ICD-10-CM_Poisoning_Matrix ALL codes 112021.xlsx", sheet = "Legal Intervention-War")


poison <- injury_icd10_poison_legal$ICD10CM
  
#unique(str_trunc(injury_icd10_poison_legal$ICD10CM, 3, side = c("right"), ellipsis = ""))

cut_pierce <- injury_icd10_legal |>
  filter(MECHANISM == "Cut/Pierce") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


drowning <- injury_icd10_legal |>
  filter(MECHANISM == "Drowning/Submersion") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


falls <- injury_icd10_legal |>
  filter(MECHANISM == "Fall") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


machinery <- injury_icd10_legal |>
  filter(MECHANISM == "Machinery") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


fireburns <- injury_icd10_legal |>
  filter(MECHANISM %in% c("Fire/Flame", "Hot Object/Substance")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

firearm <- injury_icd10_legal |>
  filter(MECHANISM == "Firearm") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

struck <- injury_icd10_legal |>
  filter(MECHANISM == "Struck by/against") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

mvt <- injury_icd10_legal |>
  filter(MECHANISM %in% c("MVT-Occupant", "MVT-Motorcyclist", "MVT-Pedal Cyclist", "MVT-Pedestrian", "MVT-Other")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

mvt_nontraffic <- injury_icd10_legal |>
  filter(MECHANISM == "Motor Vehicle-Nontraffic") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

other_transport <- injury_icd10_legal |>
  filter(MECHANISM %in% c("Other Land Transport", "Other Transport")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

ped_cyclist_other <- injury_icd10_legal |>
  filter(MECHANISM == "Pedal cyclist, other") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

pedestrian_other <- injury_icd10_legal |>
  filter(MECHANISM == "Pedestrian, other") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

bites_stings <- injury_icd10_legal |>
  filter(MECHANISM %in% c("Bites and Stings, nonvenomous", "Bites and Stings, venomous")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

nature_environment <- injury_icd10_legal |>
  filter(MECHANISM == "Natural/Environmental, Other") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

overexertion <- injury_icd10_legal |>
  filter(MECHANISM == "Overexertion") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

suffocation <- injury_icd10_legal |>
  filter(MECHANISM == "Suffocation") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


other_specified <- injury_icd10_legal |>
  filter(MECHANISM %in% c("Other Specified, Foreign Body", "Other Specified, Classifiable")) |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 

unspecified <- injury_icd10_legal |>
  filter(MECHANISM == "Unspecified") |>
  distinct(ICD10CM) |>
  pull(ICD10CM) 


hdd_ip_bind_wc_na <- hdd_ip_bind_wc_undetermined |>
  filter(is.na(cause))


hdd_ip_bind_legal <- hdd_ip_bind_wc_na |>
  mutate(cause = case_when(
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(cut_pierce, collapse = "|^"))) ~ "Cut/Pierce",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(drowning, collapse = "|^"))) ~ "Drowning/Submersion",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(falls, collapse = "|^"))) ~ "Fall", 
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(machinery, collapse = "|^"))) ~ "Machinery", 
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(fireburns, collapse = "|^"))) ~ "Fire/Burn",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(firearm, collapse = "|^"))) ~ "Firearm",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(struck, collapse = "|^"))) ~ "Struck by/against", 
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(mvt, collapse = "|^"))) ~ "Motor Vehicle Traffic",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(mvt_nontraffic, collapse = "|^"))) ~ "Motor Vehicle-Nontraffic",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(other_transport, collapse = "|^"))) ~ "Other Transport",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(overexertion, collapse = "|^"))) ~ "Overexertion",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(suffocation, collapse = "|^"))) ~ "Suffocation",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(ped_cyclist_other, collapse = "|^"))) ~ "Pedal cyclist, other",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(pedestrian_other, collapse = "|^"))) ~ "Pedestrian, other",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(nature_environment, collapse = "|^"))) ~ "Natural/Environmental, Other",
    #if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(bites_stings, collapse = "|^"))) ~ "Bites and Stings",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(other_specified, collapse = "|^"))) ~ "Other Specified",
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(unspecified, collapse = "|^"))) ~ "Unspecified", 
    if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(poison, collapse = "|^"))) ~ "Poisoning"
  )
  ) 

hdd_ip_bind_legal_cnt <- hdd_ip_bind_legal |>
  count(cause)


hdd_ip_bind_legal <- hdd_ip_bind |>
  mutate(Cut_Pierce = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(cut_pierce, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Drowning_Submersion = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(drowning, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Falls = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(falls, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Machinery = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(machinery, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Fire_Burns = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(fireburns, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Firearm = case_when(if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(firearm, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Struck_by_against = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(struck, collapse = "|^"))) ~ 1, TRUE ~ 0)) |> 
  #mutate(Motor_Vehicle_Traffic = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(mvt, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Motor_Vehicle_Nontraffic = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(mvt_nontraffic, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Other_Transport = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(other_transport, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Overexertion = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(overexertion, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Suffocation = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(suffocation, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Ped_Cyclist_Other = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(ped_cyclist_other, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Pedestrian_Other = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(pedestrian_other, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Nature_Environment = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(nature_environment, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  #mutate(Bites_Stings = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(bites_stings, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Other_Specified = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(other_specified, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Unspecified = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(unspecified, collapse = "|^"))) ~ 1, TRUE ~ 0)) |>
  mutate(Poison = case_when(if_any(contains(c("DIAG", "ECODE")), ~str_detect(., paste(poison, collapse = "|^"))) ~ 1, TRUE ~ 0))



hdd_ip_bind_undetermined_cnt <- hdd_ip_bind_undetermined |>
  select(35:43) |>                                 # select columns only needed  
  summarise(across(everything(), sum))






hdd_ip_bind_wc_na <-  hdd_ip_bind_unitent_legal |>
  filter(is.na(cause))

write_csv(hdd_ip_bind_wc_na, "hdd_no_cause.csv")



################################################################################

#                                 Demo analysis                               #

################################################################################


injury_icd10_all <- readxl::read_xlsx("2021 ICD-10-CM_Non-Poisoning_Cause_Matrix  ALL codes 112021.xlsx", sheet = "all_icd_10_cm_demo")

injury_icd10_poison_all <- readxl::read_xlsx("2021 ICD-10-CM_Poisoning_Matrix ALL codes 112021.xlsx", sheet = "all_icd_10_cm_demo")


cause_matrix_codes <- c(injury_icd10_all$ICD10CM, injury_icd10_poison_all$ICD10CM)



hdd_ip_bind_injuries <- hdd_ip_bind |>
  filter(if_any(starts_with(c("DIAG", "ECODE")), ~str_detect(., paste(cause_matrix_codes, collapse = "|^"))))


hdd_ip_bind_injuries <- hdd_ip_bind_injuries |>
  mutate(age_group = case_when(
    PATYRS >= 16 & PATYRS <= 19 ~ "16-19", 
    PATYRS >= 20 & PATYRS <= 24 ~ "20-24",
    PATYRS >= 25 & PATYRS <= 34 ~ "25-34",
    PATYRS >= 35 & PATYRS <= 44 ~ "35-44", 
    PATYRS >= 45 & PATYRS <= 54 ~ "45-54", 
    PATYRS >= 55 & PATYRS <= 64 ~ "55-64", 
    TRUE ~ "65+")) |>
  mutate(Sex = case_when(
    PATSEX == "F" ~ "Female",
    PATSEX == "M" ~ "Male"))
  

hdd_ip_bind_injuries_cnt <- hdd_ip_bind_injuries |>
  group_by(age_group, Sex) |>
  count()



write_csv(hdd_ip_bind_injuries_cnt, "wc_hdd_all_injuries_demo_cnt.csv")

    