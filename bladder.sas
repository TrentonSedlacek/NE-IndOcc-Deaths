PROC IMPORT 
    DATAFILE="K:\Occupational Health Grant\Jean Kwizerimana\Bladder Cancer\Derry_Stove_Request3.xlsx"
    DBMS=XLSX 
    OUT=bladder 
    REPLACE;
RUN;
Proc format; 
value $sexgrp 1="Male" 2="Female" 3="Other"; 
value race1grp 01 = "White" 02="Black/African American" 03="American Indian/Alaska Native" 98="Some Other races";
value $hips 0="Non-Spanish/Non-Hispanic";
value metro 1= "Metro >=1m" 2="Metro 250k-1m" 3="Metro <250k" 5="Non Metro >20k" 7 ="Non Metro 2500-20k" 9="Non Metro <2500" 6="Non Metro CityAdj 2500-20k" 4="Non Metro CityAdj >=20k" 8="Non Metro CityAdj <2500" 99="Unknown";
value $vital 1= "Alive" 0="Dead";
 value $pov_cat
       1= '< 5%'
       2= ' 5 -  9.9%'
       3= '10 - 19.9%'
       4= '>= 20%'
       9= 'Unknown';
Value castage 0= "In situ" 1="Localized only" 2= "Regional by extension only" 3="Regional lymph nodes only" 4="Regional (direct & lymph nodes"
				7="Distant site(s)/node(s) involved" 8="Benign, borderline" 9="Unknown";
value $behave 0="Benign" 1="Uncertain" 2="Carcinoma in situ" 3="Malignant/Invasive";
run;

PROC CONTENTS DATA=BLADDER; RUN;
/* Remove leading zeros using INPUT and PUT functions */
DATA bladder1;
    SET bladder;
    ageatdiagnosis_new = INPUT(STRIP(ageatdiagnosis), BEST12.);
    /* replacing the original variable */
    ageatdiagnosis = ageatdiagnosis_new;
	
    DROP ageatdiagnosis_new;
RUN;

DATA bladder2;
    SET bladder1;
    ageatdiagnosis_num = INPUT(ageatdiagnosis, BEST12.);
    DROP ageatdiagnosis;
    RENAME ageatdiagnosis_num=ageatdiagnosis;
	if cancer_type_use in ("URINARY BLADDER");
	dateOfLastContact_num = INPUT(dateOfLastContact, yymmdd8.);
	 FORMAT dateOfLastContact_num MMDDYY10.;
	 dateOfbirth_num = INPUT(dateOfbirth, yymmdd8.);
	 FORMAT dateOfbirth_num MMDDYY10.;
	  dateOfdiagnosis_num = INPUT(dateOfdiagnosis, yymmdd8.);
	 FORMAT dateOfdiagnosis_num MMDDYY10.;
race = input(race1, best12.);
spanishHispanicOrigin=input(spanishHispanicOrigin, best12.);
metrocity = input(ruralurbanContinuum2003, best12.); 
stages =input(stage, best12.);
RUN;
proc print data=bladder2 (obs=10); run;
data blad; set bladder2; 
*datoflast= year(dateOfLastContact_num);
*dob= year(dateofbirth_num);
foltime = INTCK('MONTH', dateOfdiagnosis_num, dateOfLastContact_num);
*if stages not in (5);
run;

proc print data=blad(obs=1000); run;
proc print data=counts; run;
*exploratory analysis;
*sex;
proc freq data=blad; 
tables years/nopercent nocum;
*format vitalstatus $vital.;
run;
proc freq data=bladder; 
tables placeOfDeathState; 
run;
proc sgplot data=bla;
   hbar years /  datalabel;
   Title 'Annual Bladder Cancer';
   format vitalstatus $vital.;
   where years in (2016, 2017, 2018, 2019, 2020);
  
run;

title;
*race; 
data bladder;
length racegroup$ 50; 
set blad; 
retain racegroup; 
select(race1); 
when ("01") racegroup = "White"; 
when ("02") racegroup = "Black"; 
when("03") racegroup = "American Indian/Alaska Native"; 
When ("96", "10", "15", "05", "16") racegroup = "Asian"; 
when ("07", "97") racegroup = "Native Hawaiian/Pacific Islander"; 
Otherwise racegroup = "Unknown"; 
end; run;
proc freq data=bladder order=freq; 
tables causeofdeath/nocum;
run;
*ethnicity;
data bladder3; length hisporigin$ 60; set bladder; 
retain hisporigin; 
select (spanishHispanicOrigin);
when (0) hisporigin = "Non-Spanish/Non-Hispanic"; 
when (1) hisporigin = "Mexican (Includes Chicano)"; 
when (6) hisporigin = "Hispanic/Spanish/Latino"; 
When (5) hisporigin = "Other Spanish (EUR)"; 
when (7) hisporigin = "Spanish Surname Only"; 
when (2,3) hisporigin = "PR/Cuban"; 
Otherwise hisporigin = "Unknown"; 
end; 
run;
proc freq data=bladder2 order=freq; 
tables causeOfDeath/nocum;
run;
*age;
proc means data=bladder MIN Q1 MEDIAN Q3 MEAN MAX MAXDEC=0; 
class sex;
var ageatdiagnosis;
format sex $sexgrp.;
run;
proc sgplot data=bladder; 
vbox ageatdiagnosis/group=sex; 
title 'Age Distribution by Sex';
format sex $sexgrp.;
run;
*rural urban continuum; 
proc freq data=bladder order=freq;
tables metrocity/nocum;
format metrocity metro.;
run;
*occcupation; 
proc freq data=bladder order=freq;
tables textUsualOccupation/nocum;
run;
*stage; 
proc freq data=bladder order=freq;
tables stages/nocum;
format stages castage.;
run;

*Poverty Indicator;
proc freq data=bladder order=freq;
tables censusTrPovertyIndictr/nocum;
format censusTrPovertyIndictr $pov_cat.;
run;
proc freq data=bladder order=freq;
tables censusTrPovertyIndictr*racegroup/norow nopercent;
format censusTrPovertyIndictr $pov_cat.;
run;
*stages by poverty rate; 
proc sgplot data=bladder; 
hbar racegroup/group= stages groupdisplay=cluster datalabel;
format  stages castage.;
run;
*Vitall Status;
proc freq data=bladder order=freq;
tables vitalstatus*sex/norow nopercent out=vital;
format vitalstatus $vital. sex $sexgrp.;
run;
proc sgplot data=vital; 
vbar vitalstatus/datalabel  response=percent ;
format vitalstatus $vital.;
title 'Vital Status of Bladder Cancer Patients (N=9446)'; 
run;
title;
proc sgplot data=vital; 
vbar sex/datalabel  response=percent group=vitalstatus groupdisplay=cluster;
format vitalstatus $vital.  sex $sexgrp.;
title 'Vital Status of Bladder Cancer Patients (N=9446)'; 
run;
title;
proc means data=bladder MIN Q1 MEDIAN Q3 MEAN MAX MAXDEC=0; 
class vitalstatus;
var ageatdiagnosis;
format vitalstatus $vital.;
run;
*year;
proc sgplot data=bladder4;
vbar year/datalabel;
title 'Trend of Bladder Cancer Diagnosis (N=9446)';
run;
proc freq data=bladder2 order=freq; 
tables causeOfDeath/nocum; 
*format behaviorCodeIcdO3 $behave.;
*format censusTrPovertyIndictr $pov_cat.;
run;
PROC CONTENTS DATA=BLADD; RUN;
data bladd; set bladder3; 
if 0<=ageatdiagnosis<=40 then age_cat="0-40Yrs"; 
*else if 15<ageatdiagnosis<=39 then age_cat= "15-39Yrs"; 
else if 40<ageatdiagnosis<=60 then age_cat= "40-60Yrs";
else if 60<ageatdiagnosis<=80 then age_cat = "60-80Yrs";
else age_cat = ">80Yrs";
if censusTrPovertyIndictr not in ("9");
if behaviorCodeIcdO3 not in ("1");
if foltime >=0;
*if stages in (0,1);
if causeofdeath = "C679" then status = 1; 
else status = 0;
run;
proc print data=blad (obs=10); run;
proc surveyselect data=blad out=sampled_blad n=500 seed=20250115; 
run;

proc means data=bladd MIN Q1 MEDIAN Q3 MEAN MAX MAXDEC=0; 
var foltime;
run;

proc lifetest data=bladd; 
time foltime*status(0); 
strata behaviorCodeIcdO3;
format behaviorCodeIcdO3 $behave.;
run;
proc phreg data= bladd plots=survival; 
class censusTrPovertyIndictr age_cat sex behaviorCodeIcdO3;
model foltime*status(0)=censusTrPovertyIndictr age_cat sex behaviorCodeIcdO3; 
format censusTrPovertyIndictr $pov_cat. sex $sexgrp. behaviorCodeIcdO3 $behave.;
assess ph/resample;
run;
data bladd_split;
    set bladd;
    if foltime <= 30 then timegroup = 1;
    else if foltime <= 60 then timegroup = 2;
    else timegroup = 3;
run;

proc phreg data=bladd_split;
    class censusTrPovertyIndictr age_cat behaviorCodeIcdO3 timegroup sex;
    model foltime*status(0) = censusTrPovertyIndictr age_cat behaviorCodeIcdO3*timegroup sex;
    format censusTrPovertyIndictr $pov_cat. behaviorCodeIcdO3 $behave. sex $sexgrp.;
	assess ph/resample;
run;

proc freq data=bladder4;
tables year/nocum;
run;
data bladder4; set bladder3; 
if behaviorCodeIcdO3 not in ("1"); 
run;
