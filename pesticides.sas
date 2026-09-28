proc import datafile = "K:\Occupational Health Grant\Jean Kwizerimana\poison\PoisonControl_5_16_2024.csv" dbms=csv out=clean replace;run;
data alga; 
set clean; 
if genericcode in (0201107); run;
/* Exporting the line list to a CSV file */
proc export data=alga
   outfile="K:\Occupational Health Grant\Jean Kwizerimana\poison\bluealgae.csv" /* Specify the full path */
   dbms=csv
   replace;
run;

proc sgplot data=alga; 
vbar year/datalabel stat=sum;
inset "n = 222" / position=topright;
title 'Blue Algae Exposure (2007-2023)'; 
run;
proc freq data=alga order=freq; 
tables calltypecodevalue/nocum; 
run;
proc sgplot data=alga; 
hbar calltypecodevalue/datalabel categoryorder=rescdesc;
title 'Blue Algae Exposure (2007-2023)'; 
run;
proc contents data=clean; run;
data scan; set clean;
 *select pesticide calls;
if major_gc_category in ("Pesticides");
*select only exposure calls;
if calltype in (0);
*select only human exposure;
if species in (1);
*select cases with at leat minor outcome;
if outcome in (1,2,3,4);
*select only acute cases;
if acuity in (1);
*remove null calls;
*if exposuresitecodevalue = "null" then exposuresitecodevalue = "";
*if routecodevalue = "null" then routecodevalue = "";
*selecting calls from 2014 to 2023;
if 2014<=year<=2023;
*changing variable route to numeric;
routee = input(route, 8.);

*clean age;
*separate out numeric age, calculate by year;

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
routee = input(route, 8.);
run;

*collapsing the age categories;
data pest; set scan; 
month = month(startcalendar);
year = year(startcalendar);
length age_category $50.;
retain age_category;
select(age_cat);
when ("<=5 yrs") age_category= "Less than 5 Years";
when ("6-12 yrs", "13-19 yrs") age_category= "6-19 Years";
when ("20-29 yrs", "30-39 yrs","40-49 yrs", "50-59 yrs") age_category = "20-59 Years";
when ("60-69 yrs","70-79 yrs", "80-89 yrs", ">=90 yrs") age_category = "60+ Years";
when ("Unknown Child (<=19 Yrs)","Unknown Adult (>=20 Yrs)", "Unknown Age") age_category = "Unknown Age";
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

ods excel file="K:\Occupational Health Grant\Jean Kwizerimana\SAS projects\Pesticide Final.xlsx" options(sheet_interval="none"); *exporting frequency table to excel;
*generating frequency table for multiple variables;
proc freq data=pest order=freq;
	ods excel options;
	table age_category / nocum;
	
	ods excel options;
	table gendercodevalue / nocum;
	
	ods excel options;
	table exposure / nocum;
	
	ods excel options;
	table routes / nocum;
	
	ods excel options;
	table outcomecodevalue / nocum;
	
	ods excel options;
	table managementsitecodevalue / nocum;
	
	ods excel options;
	table minor_gc_category / nocum;
	ods excel options;
	table reasons / nocum;
run;

ods excel close;

data hcf; set clean; 
if minor_gc_id in (131, 133);
if outcome in (1,2,3,4);
if calltype in (0);
if species in (1);
if acuity in (1);
run;

*cases by month;
proc freq data=pest; 
tables month/nocum nopercent;
run;

*symptoms;
proc freq data=pest order=freq; 
tables clinicalEffectCodeValue/nocum;
run;
*list of instecticide substance;
proc freq data=pest order=freq; 
tables genericcodedesc;
run;



