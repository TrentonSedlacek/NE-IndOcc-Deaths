proc import datafile = "K:\Occupational Health Grant\Jean Kwizerimana\poison\poisoncenter.poisoncasedetails.ft.substance.csv" dbms=csv out=pois replace; run;
proc import datafile = "K:\Occupational Health Grant\Jean Kwizerimana\poison\pcc data\pcc_fully.csv" dbms=csv out=poison replace; run;

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

proc contents data=poison; run;
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
if gender in (1, 2);
if age >0;
run;
data poison2;
set poison2;
if 0<age<=19 then age_cat = "Less than 19 years";
else if 19<age<=40 then age_cat = "Between 19 and 40";
else if 40<age<=60 then age_cat="Between 40 and 60";
else if 60<age<=80 then age_cat="Between 60 and 80";
 else if age > 80 then age_cat = "Over 80 years";
else age_cat="null";
run;

proc sort data=poison2;by gender; run;
proc freq data=poison2;
by gender;
tables age_cat/nocum out=agenda;
run;
data percenta; set agenda; percent =percent/100; format percent percent10.2;run;

proc sgplot data=percenta;
vbar age_cat/group=gender groupdisplay=cluster categoryorder=respdesc datalabel response=percent;
yaxis display = none; xaxis label='Age Categories'; Title 'Comparing Poison Cases by Gender and Age Group(2014-2023)'; title;
format gender gendergrp.;
run;
proc format;
  value caller_site
    1 = 'Own residence'
    2 = 'Other residence'
    3 = 'Workplace'
    4 = 'Health care facility'
    5 = 'School'
    6 = 'Restaurant / food service'
    7 = 'Public area'
    8 = 'Other'
    9 = 'Unknown';
run;

data poison3; 
set pois;
if callersite>0;
 if year in (2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023); 
run;
proc freq data=poison3; tables callersite/nocum out=caller; run;
data perc; set caller; percent =percent/100; format percent percent10.2;run;
proc sgplot data=perc;
hbar callersite/datalabel categoryorder=respdesc response=percent; xaxis display=none; format callersite caller_site.; title 'Distribution of Poison Cases Among Caller Sites (2014-2023) ';
run;

data poison3; 
set pois;

run;
proc contents data=poison3; run;
proc freq data=poison3; tables calltype*outcome; run; 
proc sgplot data=poison3; hbar calltype/ categoryorder=respdesc groupdisplay =cluster; run;
proc freq data=poison3; tables scenariocodevalue; run; 
