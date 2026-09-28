proc import datafile = "K:\Occupational Health Grant\Jean Kwizerimana\poison\PoisonControl_5_16_2024.csv" dbms=csv out=clean replace;run;
proc contents data=clean; run;
/*biguanide and sulfonylurea poisoning (2018-2023)*/
data poiso;
    set clean;
	if reason = "null" then delete;
	if clinicaleffect = "null" then delete;
	if genericcode in(0201118, 0201119);
	if gender in(1,2);

	if 0<age<=6 then age_cat = "Less than 6 years";
else if 6<age<=12 then age_cat = "Between 6 and 12";
else if 12<age<=19 then age_cat="Between 12 and 19";
else if 19<age<=60 then age_cat="Between 19 and 60";
 else if age > 60 then age_cat = "Over 60 years";
else age_cat= "";

run;
proc sgplot data=poiso; hbar age_cat/group=genericcode groupdisplay=cluster categoryorder=respdesc; run;
proc print data=clini ; run;
data clini; set poiso;
if clinicaleffect in ("411 - 5", "323 - 3", "400 - 5", "406 - 5", "370 - 6", "338 - 3", "327 - 3");
retain reasons;
select(reason);
when (1,2,3,4,5,6,7,8) reasons = 1; 
when (9,10,11,12) reasons=2;
when (15,16,17) reasons = 3; 
otherwise reasons=4; 
end;
if genericcode = 0201118 then generic =1; else generic = 0;
keep age_cat reasons clinicaleffect gender generic;
run;

proc hpsplit data=clini cvmethod=random(5);
class  clinicaleffect generic gender age_cat reasons;
model generic (event='1') = clinicaleffect gender age_cat reasons;
grow entropy; prune costcomplexity; run;

proc freq data=clini;
    tables generic clinicaleffect gender age_cat reasons;
run;


proc hpsplit data=clini cvmethod=random(5) maxdepth=5;
    class  clinicaleffect generic gender age_cat reasons;
    model generic (event='1') = clinicaleffect gender age_cat reasons;
    grow gini; prune costcomplexity;
run;

data poiso;
    set clean;
    if reason = "null" then delete;
    if clinicaleffect = "null" then delete;
    if genericcode in(0201118, 0201119);
    if gender in(1,2);
    
    if 0<age<=6 then age_cat = "Less than 6 years";
    else if 6<age<=12 then age_cat = "Between 6 and 12";
    else if 12<age<=19 then age_cat = "Between 12 and 19";
    else if 19<age<=60 then age_cat = "Between 19 and 60";
    else if age > 60 then age_cat = "Over 60 years";
    else age_cat= "";
run;

proc sgplot data=poiso;
    hbar age_cat / group=genericcode groupdisplay=cluster categoryorder=respdesc;
run;

data clini;
    set poiso;
    if clinicaleffect in ("411 - 5", "323 - 3", "400 - 5", "406 - 5", "370 - 6", "338 - 3", "327 - 3");
    
    select(reason);
        when (1,2,3,4,5,6,7,8) reasons = 1;
        when (9,10,11,12) reasons = 2;
        when (15,16,17) reasons = 3;
        otherwise reasons = 4;
    end;
    
    if genericcode = 0201118 then generic = 1;
    else generic = 0;
    
    keep age_cat reasons clinicaleffect gender generic;
run;

proc hpsplit data=clini cvmethod=random(5) maxdepth=5;
    class clinicaleffect generic gender age_cat reasons;
    model generic (event='1') = clinicaleffect gender age_cat reasons;
    grow entropy;
    prune costcomplexity;
run;
proc format; value subs 1= "Marijuana" 2= "Alcohol" 3= "Methamphetamine"; value sex 1= "Male" 2="Female"; value effect 2= "Moderate Effect" 3="Major Effect" 4="Death";run;
data bev; set clean; if age>0;run;
 data beverages; set bev; 
 if gender in (1,2);
if 2007<=year<=2023;
if outcome in (2,3,4);
retain Substance;
select (genericcode);
when (0083000,0200617,0200618,0310033,0310034,0310035,031003,0310096,0310097,0310121,0310122,0310123,0310124,0310125,0310126) Substance = 1; 
when (0019140) Substance = 2;
when (0201127) Substance = 3;
otherwise Substance = 0;end; 

	 if 1<age<=6 then age_cat = "Less than 6 years";
    else if 6<age<=12 then age_cat = "Between 6 and 12";
    else if 12<age<=19 then age_cat = "Between 12 and 19";
    else if 19<age<=60 then age_cat = "Between 19 and 60";
    else if age > 60 then age_cat = "Over 60 years";
	else if age = 0 then age_cat = "";
    else age_cat= "";
	run;
	data beverage; set beverages; if substance in (1); if age_cat in ("Between 12 and 19"); run;
	proc contents data=beverages; run;
proc sgplot data=beverage; vline year/ group=Substance lineattrs=(thickness=2);
Title 'Alcohol (Beverage), Methamphetamine, and Marijuana Poisoning Calls (2013-2023) Which Resulted into Moderate, Major Effecet, and Death';
yaxis label= "Number of Cases";
format substance subs.;
run;
proc sgplot data=beverage; vbar substance/datalabel group=outcome groupdisplay=cluster; 
Title 'Alcohol (Beverage),Methamphetamine  and Marijuana Poisoning Calls (2013-2023)by Gender'; 
yaxis display=none; 
format substance subs. gender sex.;
run;
proc freq data=beverage; tables substance*outcome/nocol nopercent;format substance subs. outcome effect.; run;

proc freq data=beverage; tables substance*year/out=area_graph nocol norow nopercent; proc print data= area_graph; format substance subs.;run;

proc sgplot data=area_graph;
    title ' Methamphetamine and Marijuana Poisoning Calls (2013-2023)';
    
    /* Create an area chart for each substance */
    band x=year lower=0 upper=count / group=Substance transparency=0.5;
    
    /* Customize the y-axis */
    yaxis label= 'Cases Count';
format substance subs.;
run;
proc means data=bev MIN MAX MEAN;
var age; run;
proc freq data=beverage; tables age_cat*outcome; run;

proc sgplot data=beverage  noautolegend; vline year/ group=age_cat lineattrs=(thickness=2);
Title 'Teenage (12-19) Marijuana Poisoning Calls Which Resulted into Moderate, Major Effect, and Death';
yaxis label= "Number of Cases";
format substance subs.;

run;
data scan; set clean; 
if 2013<=year<=2023;
if outcome in (2,3,4); if reason in(2,3); /*if genericcode in (0106000);*/
run;
proc contents data=scan; run;
proc freq data=scan order=freq; tables minor_gc_category*outcomecodevalue/ nocol nopercent norow out=monoxide;run;
proc sgplot data=scan; vbar outcome/ datalabel group=gender groupdisplay=cluster; format outcome outcomes. reason reasons. gender sex.; 
 title 'Unintentional- Envrionmental Poisoning Calls (2013-2023) that Resulted into Moderate,Major Effect, or Death');run;
proc freq data=scan order=freq; tables reason*outcome/out=area nocol nopercent; format outcome outcomes. reason reasons.;run;
proc print data=scan(obs=20);run;
proc sort data=area; by year; run;
proc sgplot data=scan;
 vline year/group=genericcodedesc;
run;
proc format; value Reasons 2= "Unintentional - Environmental" 3="Unintentional - Occupational"; value sex 1="Male" 2="Female"; value outcomes 2="Moderate Effect" 3= "Major Effect" 4="Death";
proc sgplot data=area;
    title 'Unintentional-Occupational Poisoning Calls (2013-2023) that Resulted into Moderate,Major Effect, or Death';

    /* Assign custom colors to the categories in reason */
    styleattrs datacolors=(red green); /* Specify colors in order */

    /* Create an area chart with customized colors */
    band x=year lower=0 upper=percent / group=reason transparency=0.5;
      
    /* Customize the y-axis */
    yaxis label= 'Cases Count';
	format reason reasons.;
run;

proc sgplot data=areaa; vbar outcome/ datalabel group=reason response= percent groupdisplay=cluster; yaxis label = "Percentage of Total Calls";format outcome outcomes. reason reasons. gender sex.; run;

proc sgplot data=area; vline year/ datalabel group=reason response=count; format reason reasons.; 
 title 'Unintentional- Envrionmental Poisoning Calls (2013-2023) that Resulted into Moderate,Major Effect, or Death');title;run;

 data scan; set clean;
 if reason in (2,3); if outcome in (2,3,4);
run;
proc sgplot data=scan; vline year/ lineattrs=(thickness=3) group=reason; yaxis label = "Cases Count" min=0;title'Overall Pesticides Poisoning Trend';run;

ods excel file="K:\Occupational Health Grant\Jean Kwizerimana\poison\reportt.xlsx";

proc sql;
    create table scan_counts as
    select 
        major_gc_category, 
        minor_gc_category, 
        genericcodedesc, 
		outcomecodevalue,
        count(*) as genericcodedesc_count
    from 
        scan
    group by 
        major_gc_category, 
        minor_gc_category, 
        genericcodedesc,
		outcomecodevalue;
quit;

proc report data=scan_counts;
    column major_gc_category minor_gc_category outcomecodevalue genericcodedesc genericcodedesc_count;
    define major_gc_category / group;
    define minor_gc_category / group;
	 
    define genericcodedesc / group;
	define outcomecodevalue / group;
    define genericcodedesc_count / 'Count' ;
run;

ods excel close;

proc sql;
    create table scan_counts as
    select 
        reasoncodevalue, 
        outcomecodevalue, 
        genericcodedesc, 
        count(*) as genericcodedesc_count
    from 
        scan
    group by 
        reasoncodevalue, 
        outcomecodevalue, 
        genericcodedesc;
quit;

proc report data=scan_counts;
    column reasoncodevalue outcomecodevalue genericcodedesc genericcodedesc_count;
    define reasoncodevalue / group;
    define outcomecodevalue/ group;
	 
    define genericcodedesc / group;
    define genericcodedesc_count / 'Count' ;
run;


 data scan; set clean;
 *select pesticide calls;
 if major_gc_id in (193);
 if managementsitecodevalue = "NA" then managementsitecodevalue = " ";
*select only exposure calls;
if calltype in (0);

*clean age;
*separate out numeric age, calculate by year;
if ageUnit=15 then age_year=age;
if ageUnit=16 then age_year=age/12;
if ageUnit=17 then age_year=age/365;

*if  1<= ageUnit <=11 then age_cat = ageUnitCodeValue;

length age_cat $10.;
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

run;

proc report data=scan;
    column species callTypeCodeValue  n ;
	define species / group;
    define callTypeCodeValue / group;
run;

proc freq data=clean;
	table callTypeCodeValue;
	run;

    define outcomecodevalue/ group;
	 
    define genericcodedesc / group;
    define genericcodedesc_count / 'Count' ;
run;



*old code below;
    else if 12<age<=19 then age_cat = "Between 12 and 19";
    else if 19<age<=60 then age_cat = "Between 19 and 60";
    else if age > 60 then age_cat = "Over 60 years";
	else if age = 0 then age_cat = "";
    else age_cat= ""; run;

 
  if 1<age<=5 then age_cat = "Less than 5 years";
    else if 6<age<=12 then age_cat = "Between 6 and 12";
    else if 12<age<=19 then age_cat = "Between 12 and 19";
    else if 19<age<=60 then age_cat = "Between 19 and 60";
    else if age > 60 then age_cat = "Over 60 years";
	else if age = 0 then age_cat = "";
    else age_cat= ""; run;
	if routecodevalue = "null" then routecodevalue = "";
	if  acuityCodeValue= "NA" then acuityCodeValue = "";
	if 2007<=year<=2023;
	if reason in (3); if gender in (1,2);
	run;

proc contents data=scan; run;
proc freq data=scan order=freq; 
	tables managementsitecodevalue/nocum; 
	run;
proc sgplot data=scan; vbar age_cat/group=gendercodevalue groupdisplay=cluster categoryorder=respdesc datalabel;run;
data veterinary; set scan;
if outcome in (2,3,4); run;
proc sgplot data=scan; vline year; title 'Trend of Pesticides Poisoning Calls'; yaxis label = "No. of Calls";run;
