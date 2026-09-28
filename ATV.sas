proc import datafile= "K:\Occupational Health Grant\Jean Kwizerimana\Deacertificate\2002-acs-ind-codes.xls" dbms=excel out=codes replace;run;
LIBNAME mylib "K:\Occupational Health Grant\Jean Kwizerimana\Deacertificate";

proc import datafile="K:\Occupational Health Grant\Jean Kwizerimana\Deacertificate\nioccs_coded_atv.csv" 
dbms=csv 
out= atv_coded 
replace; 
run; 
proc contents data=atv_coded; run;
proc format; 
value pofd 1 = 'Inpatient'
        2 = 'Emergency Room/Outpatient'
        3 = 'Dead on Arrival'
        4 = "Decedent's Home"
        5 = 'Hospice Facility'
        6 = 'Nursing Home/Long Term Care Facility'
        7 = 'Other'
        9 = 'Unknown';
 value education_fmt
        1 = '8th grade or less'
        2 = '9th through 12th grade; no diploma'
        3 = 'High School Graduate or GED Completed'
        4 = 'Some college credit, but no degree'
        5 = 'Associate Degree'
        6 = "Bachelor\'s Degree"
        7 = "Master\'s Degree"
        8 = 'Doctorate Degree or Professional Degree'
        9 = 'Unknown'; 

value $manner_fmt
        'N' = 'Natural'
        'A' = 'Accident'
        'S' = 'Suicide'
        'H' = 'Homicide'
        'P' = 'Pending Investigation'
        'C' = 'Could not be determined'
        ' ' = 'Blank';
VALUE $RACEGRP 
		"01"= "White"
		"03" = "American Indian"
		"15" = "Other"; 
run;
DATA atv;
set atv_coded;
    *SET mylib.atv_0523new;
 *rename industrycode=code_char;
*if industrycode= "" then delete;
run;
DATA atvv;
    SET mylib.atv_0523;
 rename industrycode=code_char;
*if industrycode= "" then delete;
run;
    
    /* Create date from month, day, year components */
    date = mdy(DOI_MNTH, DOI_DAY, DOI_YR);
    format date date9.;
    
    /* Get day of week */
    day_of_week = weekday(date);
    format day_of_week downame.;
    
    /* Handle time conversion */
    length clean_time 8 time_period $25;
    
    if DOI_TIME = '9999' then clean_time = .;
    else if DOI_TIME = '' then clean_time = .;
    else do;
        /* Extract hours and minutes */
        hours = input(substr(DOI_TIME,1,2), 2.);
        minutes = input(substr(DOI_TIME,3,2), 2.);
        
        /* Validate hours and minutes */
        if 0 <= hours <= 23 and 0 <= minutes <= 59 then
            clean_time = (hours * 100) + minutes;
        else clean_time = .;
        
        /* Categorize time periods */
        if 0 <= hours <= 6 then time_period = 'Midnight to 6 AM';
        else if 7 <= hours <= 12 then time_period = '7 AM to Noon';
        else if 13 <= hours <= 18 then time_period = '1 PM to 6 PM';
        else if 19 <= hours <= 23 then time_period = '7 PM to 11 PM';
    end;
    
    /* Handle missing values for time_period */
    if clean_time = . then time_period = 'Unknown';
    
    format clean_time z4.;
	if 2005<=dod_yr<=2023;
RUN;
proc contents data=atv_mod; run;
proc print data=joined_dataset;
    var code_char code industrylit Description;
run;
proc print data=codes_updated; 
run;

data codes_updated;
    set codes;
    /* Convert code to character if it is numeric */
    code_char = put(code, 4.);  /* Convert to string */
 run;

data codes_updated;
   set codes_updated;
   if length(strip(code_char)) = 3 then
   code_char = put(input(strip(code_char), 3.), z4.); /* Add leading zero */
 
run;
data atv_mod;
    set atv;
    /* Convert code to character if it is numeric */
    code_char = put(code_char, 4.);  /* Convert to string */
 run;
data atv_mod;
   set atv_mod;
   if length(strip(code_char)) = 3;
   
run;

proc sql;
    create table joined_dataset as
    select 
        b.*,  /* All columns from atv_mod */
        a.*   /* All columns from codes_updates */
    from codes_updated as a
    right join atv_mod as b
    on substr(a.code_char, 1, 3) = substr(b.code_char, 1, 3); /* Join on the first 3 characters */
quit;
proc contents data=joined_dataset; run;
data clean; 
set joined_dataset; 
keep nchsage nchsageunit code_char industrylit description;
run;
proc print data= clean;  
run;
ods results off;




















proc sgplot data=atv;
vbar dod_yr/datalabel; 
title 'ATV Death by Year (New Data)';
run;
proc freq data=atvv; 
tables dod_yr; 
run;
proc freq data=atv;
    tables dod_yr/nocum out=year_data;
run;
proc freq data=atv order=freq;
    tables age_cat/nocum;
run;
proc means data= year_data MIN MEAN MAX MAXDEC=2; 
var count; 
run;

data atv;
length age_cat $ 50;
length cause $ 50;
	set atv; 
if 0 <ageunits <=19 then age_cat ="<=19 Years";
else if 20<ageunits<=39 then age_cat = "20- 39years";
else if 40<ageunits<=69 then age_cat = "40-69 Years";
else age_cat ="70+ Years";

retain cause; 
select (ACUND_CAUSE);
when ("V865") cause = "Driver (Non-Traffic)"; 
when ("V860") cause = "Driver (Traffic)";
when ("V869") cause = "Unknwn (Non-Traffic)";
when ("V861") cause = "Passenger(Traffic)";
when ("V866") cause = "Passenger (Non-traffic)";
when ("V863") cause = "Unknown (Traffic)";
otherwise cause = "Other";
end;

*if doi_yr = 9999 then delete;
run;
data tra_stat; 
set atv; 
retain traffic; 
select (cause); 
when ("Driver (Non-Traffic)", "Unknwn (Non-Traffic)", "Passenger (Non-traffic)" ) traffic = "Non - Traffic";
when ( "Driver (Traffic)", "Passenger(Traffic)", "Unknown (Traffic)") traffic = ("Traffic"); 
otherwise traffic = "Other";
end; 
if 2005<=dod_yr<=2023;
run;
data tra_sta; 
set atv; 
retain driv_stat; 
select (cause); 
when ("Driver (Non-Traffic)", "Driver (Traffic)" ) driv_stat = "Driver";
when ( "Passenger (Non-traffic)", "Passenger(Traffic)") driv_stat = ("Passenger"); 
otherwise driv_stat= "Other";
end; 
if 2005<=dod_yr<=2023;
run;
proc freq data=tra_sta; 
tables driv_stat*sex/ nopercent;
run;
data chi; 
set tra_sta; 
*if traffic in ("Traffic", "Non - Traffic"); 
if age_cat in ("70+ Years", "<=19 Years");run;
proc freq data=chi; 
   tables age_cat*traffic/fisher;
run;
proc sgplot data=chi; 
histogram ageunits;
run;
proc sgplot data=chi; 
vbar age_cat/group=traffic groupdisplay=cluster;
run;
proc freq data=chi; 
   tables traffic*sex/fisher;
run;
proc sgplot data=chi; 
vbar age_cat/group=sex groupdisplay=cluster datalabel;
run;
proc sgplot data=chi; 
vline dod_yr/group=traffic groupdisplay=cluster datalabel; 
Title 'Traffic vs. Non-Traffic ATV Deaths (2014-2023)';
run; 
proc freq data = chi; 
tables dod_yr*traffic/out=square nocol norow nopercent;
run; 
/* Save the 'square' dataset as a CSV file */
proc export data=square
   outfile="K:\Occupational Health Grant\Jean Kwizerimana\Deacertificate\square.csv"  /* specify your file path */
   dbms=csv 
   replace;
run;
*t-test; 
proc ttest data=square; 
class traffic; 
var percent; 
run; 
*poison; 
proc genmod data=square;
   class traffic;
   model COUNT = traffic DOD_YR / dist=poisson link=log;
run;

proc contents data=atv; run;
proc print data=square; 
run;
proc sgplot data=square; 
histogram count;
run;
*Which month is deadliest;
proc sgplot data=atv; 
vbar doi_mnth/datalabel; 
yaxis label= "Number of Deaths";
title "Which month was deadliest?";
run;
*which year is deadly;
proc sgplot data=atv; 
vline doi_yr/lineattrs=(thickness=2); 
yaxis label = "Number of Deaths";
title "Which year was deadliest?";
run;
*which day is deadly;
proc sgplot data=atv; 
hbar  day_of_week/datalabel categoryorder=respdesc; 
title "Which day was deadliest?";
run;
proc sgplot data=atv; 
hbar  DOI_DAY/datalabel categoryorder=respdesc; 
title "Which day was deadliest?";
run;

proc freq data=atv order=freq; 
tables age_cat/out=age; 
run;
*which age category is affected the most?;
proc format;
    picture pctfmt (round)
        low-high = '009.9%' (mult=10);
run;

proc sgplot data=age; 
hbar age_cat/ response=percent categoryorder=respdesc datalabel;
title "Which age group is affected the most?";
yaxis label= "Age Groups"; xaxis label = "Percent of Total Deaths";
format percent pctfmt.;
run;

proc sgplot data=atv; 
vline doi_yr/datalabel; 
yaxis label= "Number of Deaths";
title "ATV Deaths for the past 5 years (2018-2023)";
run;


*which gender was affected the most?;
proc freq data=atv order=freq; 
tables sex/nocum out=sex; 
run; 
proc gchart data=sex;
    pie sex / sumvar=percent  percent=inside;
    title "Which sex was mostly affected?";
run;
quit;
 
proc freq data=atv order=freq; 
tables TRANSACC/nocum;
 
run;
proc freq data=atv order=freq; 
tables race/nocum;
 format race $RACEGRP.;
run;
proc freq data=atv order=freq; 
tables hispanic/nocum;
 
run;

proc freq data=atv order=freq; 
tables ARMEDFORCE/nocum;
 
run;
proc freq data=chi order=freq; 
tables POD/nocum;
 format pod pofd.;
run;
proc freq data=atv order=freq; 
tables EDUC/nocum;
format educ education_fmt.;     
run;

proc freq data=chi order=freq; 
tables RES_INCILIM*driv_stat/nopercent nocol;
 
run;
proc freq data=atv order=freq; 
tables MANNEROD/nocum;
 format mannerod $manner_fmt.;
run;

proc freq data=atv order=freq; 
tables time/nocum;
run;

proc freq data=atv order=freq; 
tables INJ_WORK/nocum;
run;

proc freq data=atv order=freq; 
tables ACUND_CAUSE/nocum;
run;
proc freq data=atv order=freq; 
tables ACT_TM_DTH/nocum;
run;
proc freq data=atv order=freq; 
tables cause*sex/nocum out=cause;
run;
proc sgplot data=atv; 
hbar cause/categoryorder=respdesc groupdisplay= cluster datalabel;
title "Who was mostly affected?";
run;

proc freq data=atv order=freq; 
tables cause*dod_yr/nocol nopercent;
run;

dm 'odsresults; clear';
proc contents data=atv; run;

proc freq data=atv order=freq; 
tables OCCUPL/nocum;
run;
proc freq data=chi order=freq; 
tables traffic/nocum;
run;
data day; 
set atv; 
keep  DOI_DAY DOD_DAY;
run;
proc glm data=atv; 
class age_cat;
model count= age_cat;
run;

proc npar1way data=chi wilcoxon;
   class traffic;    /* Specify the grouping variable */
   var ageunits;      /* Specify the variable to compare */
run;



proc freq data=atv; 
tables age_cat/ nocum out=age;
title "Who was mostly affected?";
run;
proc  freq data=age; 
tables age_cat/chisq;
weight count; 
run;
proc genmod data=age;
   class age_cat;
   model COUNT = age_cat / dist=poisson link=log;
run;

proc print data=age; 
run;
proc freq data=tra_stat; 
tables traffic*RES_INCILIM; 
run;

proc sgplot data=chi; 
vline dod_yr/datalabel group=age_cat; 
yaxis label= "Number of Deaths";
title "ATV Deaths for the past 5 years (2018-2023)";
run;
