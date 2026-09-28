proc import datafile = "K:\Occupational Health Grant\Jean Kwizerimana\poison\PoisonControl_5_16_2024.csv" dbms=csv out=clean replace;run;
proc contents data=clean; run;
data scan; set clean; 
if reason = 3; /*or exposuresite in (3,6);*/
if 2007<=year<=2023;
if species in (1);
if calltype in (0);
if acuity in (1);
if route = "null" then delete;
if outcome in (1,2,3,4);
months= month(startcalendar);
*routee = input(route, 8.); run;
*clean age;
*separate out numeric age, calculate by year;
data age_clean;
set scan;
length age_cat $50.;
if ageUnit=15 then age_year=age;
if ageUnit=16 then age_year=age/12;
if ageUnit=17 then age_year=age/365;
*age categories using age unit;
if  ageUnit =1 then age_cat = "<=5 yrs";
if  ageUnit =2 then age_cat = "6-12 yrs";
if  ageUnit =3 then age_cat = "13-19 yrs";
if  ageUnit =4 then age_cat = "20-29 yrs";
if  ageUnit =5 then age_cat = "30-39 yrs";
if  ageUnit =6 then age_cat = "40-49 yrs";
if  ageUnit =7 then age_cat = "50-59 yrs";
if  ageUnit =8 then age_cat = "60-69 yrs";
if  ageUnit =9 then age_cat = "70-79 yrs";
if  ageUnit =10 then age_cat = "80-89 yrs";
if  ageUnit =11 then age_cat = ">=90 yrs";
if ageUnit=12 then age_cat ="Unknown Child (<=19 Yrs)";*handling unknown age;
if ageUnit=13 then age_cat = "Unknown Adult (>=20 Yrs)";*handling unknown age;
if ageUnit=14 then age_cat = "Unknown Age";*handling unknown age;
*age categories using numeric age;
if 0 <= age_year <=5 then age_cat= "<=5 yrs";
if 6 <= age_year <=12 then age_cat= "6-12 yrs";
if 13 <= age_year <=19 then age_cat="13-19 yrs";
if 20 <= age_year <=29 then age_cat="20-29 yrs";
if 30 <= age_year <=39 then age_cat="30-39 yrs";
if 40 <= age_year <=49 then age_cat="40-49 yrs";
if 50 <= age_year <=59 then age_cat="50-59 yrs";
if 60 <= age_year <=69 then age_cat="60-69 yrs";
if 70 <= age_year <=79 then age_cat="70-79 yrs";
if 80 <= age_year <=89 then age_cat="80-89 yrs";
if age_year >=90 then age_cat=">=90 yrs";
route_clean = compress(route, ','); /* Remove commas */
routee = input(route_clean, 8.);    /* Convert to numeric */
run;

*collapsing the age categories;
data pest; set age_clean; 
month = month(startcalendar);
year = year(startcalendar);
length age_category $50.;
retain age_category;
select(age_cat);
when ("<=5 yrs") age_category= "Less than 5 Years";
when ("6-12 yrs", "13-19 yrs") age_category= "6-19 Years";
when ("20-29 yrs", "30-39 yrs","40-49 yrs", "50-59 yrs") age_category = "20-59 Years";
when ("60-69 yrs","70-79 yrs", "80-89 yrs", ">=90 yrs") age_category = "60+ Years";
when ("Unknown Adult (>=20 Yrs)") age_category= "Unknown Adult (>=20 Years)";
when ("Unknown Child (<=19 Yrs)", "Unknown Age") age_category = "Unknown Age";
otherwise age_category = " ";end;
*Collapsing route of exposure;

length routes $50.;
retain routes;
select (routee);
when (70) routes = "Ingestion";
when (71,72) routes = "Inhalation/Nasal";
when (73) routes = "Ocular";
when (74) routes = "Dermal";
when (75,76,77,78,524,525,526) routes="Other/Unknown";
otherwise routes = " "; end;
*Collapsing exposure site;
length exposure $55;

retain exposure; 
select (exposuresite); 
when(1,2) exposure = "Residence";
when (3, 4,6) exposure = "Workplace";
when (5) exposure = "School";
when (7,8,9) exposure = "Other/Unknown";
otherwise exposure = " ";end;

length reasons $100; 
retain reasons; 
select (reason); 
when(1) reasons = "General";
when (2) reasons = "Environmental";
when (3) reasons = "Occupational";
when (5) reasons = "Misuse";
When (4, 6,7,8,9,10,11,12,13,14,15,16,17,18,19) reasons = "Other";
Otherwise reasons = " "; end;
run;

*age distribution;
 proc freq data=age_clean order=freq; 
 tables age_cat; 
 run;
 *Gender distribution;
proc freq data=pest order=freq; 
 tables gendercodevalue; 
 run;
 *top substances; 
 proc freq data=pest order=freq; 
 tables outcomecodevalue; 
 run;
*level of healthcare;
proc freq data=pest order=freq; 
 tables levelofHCFCareCodeValue*managementSiteCodeValue; 
 run;
*management site;
proc freq data=manage_out order=freq; 
 tables managementsite*out/chisq;
 run;
data manage_out;
	set pest; 
retain out; 
select(outcome);
when (1) out = "Minor";
when (2) out = "Moderate";
when (3,4) out = "Major & Death";
end; 

if managementsite in (1,2,3);
run;

proc sgplot data=manage_out; 
vbar managementsite/group=out groupdisplay=cluster datalabel; 
title;
run;




*route of exposure;
 proc freq data=pest order=freq; 
 tables routes;
 run;
*scenario distribution;
  proc freq data=pest order=freq; 
 tables scenarioCodeValue;
 run;
 *major_gc_category; 
   proc freq data=pest order=freq; 
 tables major_gc_category;
 run;
proc freq data=pest order=freq; 
 tables managementSiteCodeValue*outcomecodevalue/norow nopercent fisher;
 run;
 *trend; 
 proc sgplot data=pest; 
 vline year; 
 run;
  proc sgplot data=clean; 
 vline year; 
 run;


dm 'odsresults; clear';


/* Step 1: Calculate percentages in pest dataset */
proc sql;
    create table pest_labeled as
    select year, count(year) as count, "Occ" as dataset
    from pest
    group by year;
quit;

/* Step 2: Calculate percentages in clean dataset */
proc sql;
    create table clean_labeled as
    select year, count(year) as count, "All" as dataset
    from clean
    group by year;
quit;

/* Step 3: Normalize by converting to percentages */
proc sql;
    select sum(count) into :total_pest from pest_labeled;
    select sum(count) into :total_clean from clean_labeled;
quit;

data pest_labeled;
    set pest_labeled;
    percentage = (count / &total_pest) * 100;  /* Convert counts to percentage */
run;

data clean_labeled;
    set clean_labeled;
    percentage = (count / &total_clean) * 100;  /* Convert counts to percentage */
run;

/* Step 4: Combine the datasets */
data combined;
    set pest_labeled clean_labeled;
run;

/* Step 5: Plot both datasets using percentages */
proc sgplot data=combined;
    vline year / response=percentage group=dataset stat=sum;
    xaxis label="Year";
    yaxis label="Percentage";
	Title 'Comparing Trends of Occupational Cases to All cases';
run;


*ARIMA model for identifying spikes; 

/* Step 1: Aggregate data by year to get total exposures per year */
proc freq data=pest; 
tables startcalendar/nopercent nocum out=ann_exposure;
run;
proc print data=monthly_data (obs=100); 
run;

/* Step 1: Fit ARIMA model and save residuals */
proc arima data=ann_exposure;
    identify var=count nlag=12;
     estimate p=1 q=1; /* ARIMA(1,0,1) model */
    forecast lead=0 out=forecast_results; /* Output fitted values and residuals */
run;
/* Step 3: Merge year and total_exposure back into forecast_yearly */
proc sort data=ann_exposure;
by count; 
run;
proc sort data=forecast_results;
by count; 
run;
data forecast_results;
    merge ann_exposure forecast_results;
    by count;
run;

*std;
proc means data=forecast_results noprint;
    var residual;
    output out=residual_stats std=residual_std;
run;
/* Step 3: Calculate residuals and set threshold for anomaly detection */
data yearly_anomalies;
 if _n_ = 1 then set residual_stats;
    set forecast_results;
    /* Define threshold for anomalies as 3 standard deviations from residual mean */
    threshold = 3 * residual_std; 
    if abs(residual) > threshold then is_anomaly = 1;
    else is_anomaly = 0;
run;

/* Step 5: Print the years with anomalies */
proc print data=yearly_anomalies;
    where is_anomaly=1;
    var startcalendar count forecast residual;
    title "Detected Years with Anomalous Exposures";
run;
/* Create dataset with threshold bands */
data yearly_anomalies_plot;
    set yearly_anomalies;
    lower_bound = forecast - threshold;
    upper_bound = forecast + threshold;
run;
/* Create the plot */
proc sgplot data=yearly_anomalies_plot;
    /* Add bands for threshold regions */
    band x=startcalendar lower=lower_bound upper=upper_bound / 
         fillattrs=(color=lightgray transparency=0.7)
         name="Threshold"
         legendlabel="±3 Std Dev Threshold";
    
    /* Plot the actual time series */
    series x=startcalendar y=count / 
           lineattrs=(color=blue thickness=2) 
           name="Actual"
           legendlabel="Actual Exposures";
    
    /* Add forecast line */
    series x=startcalendar y=forecast / 
           lineattrs=(color=darkgreen thickness=2 pattern=dash)
           name="Forecast"
           legendlabel="Forecast";
    
    /* Highlight anomalies */
    scatter x=startcalendar y=count / 
           group=is_anomaly
           markerattrs=(symbol=circlefilled size=12)
           grouporder=descending
           name="Anomalies"
           legendlabel="Anomalies"
           datalabel=count
           datalabelattrs=(size=8 weight=bold)
           datalabelpos=top;
    
    /* Customize the appearance */
    xaxis label="Year" grid;
    yaxis label="Number of Exposures" grid;
    keylegend "Actual" "Forecast" "Threshold" "Anomalies" / 
             position=bottom across=2;
    title "Poison Exposure Time Series with Anomaly Detection";
    title2 "Anomalies Defined as Points Beyond ±3 Standard Deviations";
run;

proc print data=yearly_anomalies_plot; run 

proc sort data=ann_exposure;
   by count;
run;

/* Step 2: Calculate quartiles and IQR */
proc means data=ann_exposure noprint;
   var count;
   output out=stats
          Q1=Q1
          Q3=Q3
          qrange=IQR
          mean=mean_cases
          std=std_cases;
run;

/* Step 3: Identify outliers using IQR method */
data outliers;
   if _n_=1 then set stats;
   set ann_exposure;
   
   /* Calculate bounds */
   lower_bound = Q1 - 0.1*IQR;
   upper_bound = Q3 + 0.1*IQR;
   
   /* Extreme bounds (3*IQR) */
   extreme_lower = Q1 - IQR;
   extreme_upper = Q3 + IQR;
   
   /* Flag outliers */
   is_outlier = (count < lower_bound or count > upper_bound);
   is_extreme = (count < extreme_lower or count > extreme_upper);
   
   /* Calculate z-score for additional context */
   z_score = (count - mean_cases) / std_cases;
   
   /* Distance from median in terms of IQR */
   iqr_distance = abs(count - (Q1 + IQR/2)) / IQR;
run;

/* Step 4: Create summary report of statistical boundaries */
proc print data=stats noobs;
   var Q1 Q3 IQR;
   title "Summary Statistics for Poison Exposure Data";
run;

/* Step 5: Print detailed outlier report */
proc print data=outliers;
   where is_outlier=1;
   var year count z_score iqr_distance is_extreme;
   format z_score iqr_distance 6.2;
   title "Detected Spikes in Poison Exposure Data";
run;

/* Step 6: Create visualization */
proc sgplot data=outliers;
   scatter x=year y=count / markerattrs=(size=6)
          group=is_outlier name="scatter";
   series x=year y=count / lineattrs=(color=grey thickness=1)
          transparency=0.5;
   refline upper_bound / axis=y lineattrs=(pattern=dash color=red)
          label="Upper Bound";
   refline lower_bound / axis=y lineattrs=(pattern=dash color=red)
          label="Lower Bound";
   xaxis label="Date";
   yaxis label="Number of Cases";
   title "Poison Exposure Cases with IQR-based Outlier Detection";
   keylegend "scatter" / title="Outlier Status";
run;

/* Step 7: Optional - Create monthly summary of spikes */
proc freq data=outliers;
   where is_outlier=1;
   tables year / out=spike_freq;
   title "Monthly Distribution of Spikes";
run;

*CUSUM;
/* Step 1: Calculate baseline statistics */
proc means data=ann_exposure noprint;
    var count;
    output out=stats mean=mean_count std=std_count;
run;

/* Step 2: Implement CUSUM calculations */
data cusum;
    if _n_ = 1 then set stats;    /* Get baseline statistics */
    set ann_exposure end=last;     /* Read main dataset */
    
    /* Initialize CUSUM parameters */
    retain Cp Cn;                 /* Retain CUSUM values */
    if _n_ = 1 then do;
        Cp = 0;
        Cn = 0;
    end;
    
    /* Set CUSUM parameters */
    k = 0.5 * std_count;         /* Reference value (usually 0.5 standard deviations) */
    h = 15 * std_count;           /* Decision interval (usually 5 standard deviations) */
    
    /* Standardize the observation */
    z = (count - mean_count) / std_count;
    
    /* Calculate upper and lower CUSUM */
    Cp = max(0, Cp + (z - k));   /* Upper CUSUM */
    Cn = max(0, Cn + (-z - k));  /* Lower CUSUM */
    
    /* Detect signals */
    signal_high = (Cp > h);
    signal_low = (Cn > h);
    any_signal = (signal_high or signal_low);
    
    /* Calculate additional metrics */
    distance_from_mean = count - mean_count;
    std_distance = abs(distance_from_mean) / std_count;
    
    format Cp Cn 8.2;
run;

/* Step 3: Create summary reports */
/* Print signals detected */
proc print data=cusum;
    where any_signal=1;
    var startcalendar count distance_from_mean std_distance Cp Cn;
    title "CUSUM Signals Detected";
run;

/* First create indicator variables for plotting */
data cusum_plot;
    set cusum;
    /* Create variables for scatter plots */
    if signal_high then Cp_signal = Cp;
    else Cp_signal = .;
    
    if signal_low then Cn_signal = Cn;
    else Cn_signal = .;
run;

/* Main CUSUM chart */
proc sgplot data=cusum_plot;
    /* Plot upper CUSUM */
    series x=startcalendar y=Cp /
           lineattrs=(color=red thickness=2)
           name="Upper"
           legendlabel="Upper CUSUM";
    
    /* Plot lower CUSUM */
    series x=startcalendar y=Cn /
           lineattrs=(color=blue thickness=2)
           name="Lower"
           legendlabel="Lower CUSUM";
    
    /* Add threshold reference line */
    refline h / axis=y
               lineattrs=(pattern=dash color=darkgray)
               name="Threshold"
               legendlabel="Decision Interval (h)";
    
    /* Add markers for signals using new variables */
    scatter x=startcalendar y=Cp_signal /
            markerattrs=(symbol=trianglefilled color=red size=9)
            name="HighSignal"
            legendlabel="Upper Signal";
    
    scatter x=startcalendar y=Cn_signal /
            markerattrs=(symbol=triangledownfilled color=blue size=9)
            name="LowSignal"
            legendlabel="Lower Signal";
    
    /* Customize appearance */
    xaxis label="Date" grid;
    yaxis label="CUSUM Statistic" grid;
    keylegend "Upper" "Lower" "Threshold" "HighSignal" "LowSignal" /
              position=bottom across=3;
    title "CUSUM Control Chart for Poison Exposures";
    title2 "k = 0.5s, h = 5s";
run;
