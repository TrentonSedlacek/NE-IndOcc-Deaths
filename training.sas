proc import datafile = "K:\Occupational Health Grant\Jean Kwizerimana\poison\poisoncenter.poisoncasedetails.ft.substance.csv" dbms=csv out=pois replace; run;

data poison;
set pois;
 if year in (2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023);
 where reason = 3;
 if outcome in (2, 3,4);

   if routecodevalue in ("Ingestion", "Inhalatio", "Aspiration(with ingestion)", "Ocular", "Dermal", "Bite/stin", "Parentera", "Other", "Unknown", "Otic", "Rectal", "Vaginal");
/*where year=2020;*/
/*if year in (2019, 2020, 2021, 2022, 2023);*/
/*if formulationcode in ("1,", "2,", "3,", "4,","5,", "6,", "7,","8,");*/
/*where reason=3;
/*if species in (1,2);*/
run;


proc freq data=poison;  tables gender; run;
proc sgplot data=poison; histogram age; run;
proc sort data=poison; by gender;run;
proc means data=poison  MEAN MAXDEC=2;class gendercodevalue; var age; run;
proc freq data=poison; tables gendercodevalue; run;
proc freq data=poison; tables callTypeCategory*outcome/nocum; run;

proc sgplot data=poison; vbar outcomecodevalue/datalabel; Title 'Extreme Outcome from Unintentional Occupational Poisoning Cases (2014-2023)'; title;run;
proc sgplot data=poison;vbar Year/ datalabel ; yaxis label ='Number of Cases';  title 'Unintentional Occupational Poison Cases for the Past 10 Years (2014-2023)';run;

proc sgplot data=poison;vbar year/datalabel; title 'Unintentional Occupational Poisoning Cases for the Past 5 Years';title;run;
proc sgplot data=poison; vline year; run;
proc sgplot data=poison; vbar year/group=route groupdisplay=cluster;run;

proc freq data=poison; tables routecodevalue/nocum out=rou_per; run;
data percentage; set rou_per; percent =percent/100; format percent percent10.2;run;

proc sgplot data=percentage; hbar routecodevalue/categoryorder=respdesc response= percent datalabel; xaxis display= none; title 'Route for Unintentional Occupational Poisoning Cases (2014-2023)'; run;
proc freq data=poison; tables clinicaleffectdurationcodevalue/nocum; run;

proc freq data=poison; tables scenario/nocum; run;
proc format;
    value $substance
        "1,"= 'Solid (tablets / capsules / caplets)'
        "2," = 'Liquid'
        "3," = 'Aerosol / mist / spray / gas'
        "4," = 'Powder / granules'
        "5," = 'Cream / lotion / gel'
        "6," = 'Patch'
        "7," = 'Other'
       "8," = 'Unknown';
	   value gendergrp 1="Male" 2="Female";
run;
data poison1;
	set pois;
if formulationcode = "null" then formulationcode = "";
if formulationcode = "," then formulationcode = "";
 if year in (2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023);
run;
proc freq data=poison1; tables formulationcode/nocum out=form_per;
data percentag; set form_per; percent =percent/100; format percent percent10.2;run;


proc sgplot data=percentag; 
hbar formulationcode/ datalabel response=percent groupdisplay=cluster categoryorder=respdesc; xaxis display=none;
yaxis label='Substances'; Title 'Ranking of Poisoning Substances Over Past 10 years (2014-2023)'; title;
format formulationcode $substance.;
run;

data poison2;
set pois;
run;
data poison2;
set poison2;
if 0<age<=6 then age_cat = "Less than 6 years";
else if 6<age<=12 then age_cat = "Between 6 and 12";
else if 12<age<=19 then age_cat="Between 12 and 19";
else if 19<age<=60 then age_cat="Between 19 and 60";
 else if age > 60 then age_cat = "Over 60 years";
else age_cat= "Missing";
 where year=2024; run;

 data poison2;
 set poison2;
 if age_cat in ("Less than 6 years", "Between 6 and 12", "Between 12 and 19", "Between 19 and 60", "Over 60 years");
 if reasoncodevalue not in ("null");
 run;

proc freq data=poison2;tables age_cat*reasoncodevalue;run;
proc sort data=poison2; by age;run;
proc sgplot data=poison2;
vbar age_cat/group=gender groupdisplay=cluster datalabel categoryorder=respasc;
yaxis display=none;
run;
data poison_species; 
set pois; 

if outcomecodevalue not in ("null");
retain reasons;
select(reason); 
when (1,2,3,4,5,6,7,8)reasons = "Unintentional";
when (9,10,11,12) reasons = "Intentional";
when (13, 14,19) reasons = "Other";
When (15, 16,17) reasons = "Adverse Reaction";
when (18) reasons = "Unknown";
otherwise reasons = "";end;

if 0<age<=6 then age_cat = "Less than 6 years";
else if 6<age<=12 then age_cat = "Between 6 and 12";
else if 12<age<=19 then age_cat="Between 12 and 19";
else if 19<age<=60 then age_cat="Between 19 and 60";
 else if age > 60 then age_cat = "Over 60 years";
else age_cat= "";
if year in (2018, 2019, 2020, 2021, 2022);
run;
proc contents data=pois; run;
proc freq data=poison_species; tables speciesTypeCodeValue/nocum; run;
ods word file= "K:\Occupational Health Grant\Jean Kwizerimana\SAS projects\speciesbyoutcome.docx";
proc freq data=poison_species; tables outcomecodevalue*reasons/nocol norow; run;
proc freq data=poison_species; tables outcomecodevalue*age_cat/nocol norow; title 'Outcome by Age Categories (2018-2022'; run;
ods word close;

data pestcides;
set pois; 
if scenario in (560,561,562);
where year=2023;
run;
proc freq data=pestcides; tables scenariocodevalue;run;
proc import datafile ="K:\Occupational Health Grant\Jean Kwizerimana\poison\PoisonControl_5_16_2024.csv" dbms=csv out=poiso replace; run;
data covid; set poiso; 
if year in (2011,2012,2013);
month = month(startcalendar);
day = day(startcalendar);
run;
data covid19;
set covid; 

run;
ods graphics / discreteMax=1100;
proc sgplot data=covid19; vbar startcalendar/group=year groupdisplay=cluster datalabel;xaxis display=none ;yaxis label= "Calls"; title 'A graph showing increase of calls due to COVID-19';run;


data covid19;
    set pois;

if outcome in (2,3,4);
if genericcodedesc = "null" then genericcodedesc = " ";
if outcomecodevalue= "null" then outcomecodevalue= " ";
if reason in (11);
run;

proc freq data=covid19;tables root;run;
proc freq data=covid19 order=freq; tables genericcodedesc*outcomecodevalue/ out=subs; run;
data toxic; set pois;
if outcome in (2,3,4);
if reason in (15);
if genericcodedesc = "null" then genericcodedesc = " ";

run;
proc freq data=toxic order=freq; tables genericcodedesc*outcomecodevalue/nocol nopercent;  run;
proc print data=toxic; run;

proc contents data=timeseries;run;
data timeseries;
    set pois;
    if genericcode in (0083000, 0200617, 0200618, 0310033, 0310034, 0310035, 0310036, 0310096, 0310097, 0310121, 0310122, 0310123, 0310124, 0310125, 0310126);
    month = month(startcalendar);
    if day(startcalendar) <= 15 then half = 1;
    else half = 2;
    format startcalendar monname3.;
    if half = 1 then month_half_label = catx(' ', put(startcalendar, monname3.), '15');
    else month_half_label = catx(' ', put(startcalendar, monname3.), '30');
run;

proc sgplot data=timeseries;
    vline month_half_label; yaxis label ="Number of Calls"; xaxis label= "Date";
run;

data timeseries;
set poiso; if year in (2018,2019,2020,2021,2022); 
month = month(startcalendar); year=year(startcalendar);
run;
/* Prepare the data with a binary split variable */
data time;
set timeseries;
	keep startcalendar year month;
run;
proc print data=time (obs=10); run;
proc freq data=time;tables startcalendar/nocum out=chowtest nopercent;run;
data chowtest; set chowtest;
 break_date = '12MAR2020'd;
if startcalendar <= break_date then break=0; else break=1;run;
proc reg data=chowtest;
where break=0;
    model count=startcalendar;
    ods output parameterestimates=coefficients; /* Save coefficients */
run;

proc autoreg data=chowtest;
    model count=startcalendar/chow=802;
    ods output parameterestimates=coefficient; /* Save coefficients */
run;
proc reg data=chowtest;
where break=1;
    model count=startcalendar;
    ods output parameterestimates=coefficien; /* Save coefficients */
run;

ods graphics / discreteMax=9900;
proc sgplot data=time;
    vbar startcalendar; yaxis label ="Number of Calls"; xaxis label= "Date";
run;

proc freq data=timeseries order=freq; tables genericcodedesc*outcomecodevalue/nocol;  run;
proc print data=chowtest (obs=10);run;
