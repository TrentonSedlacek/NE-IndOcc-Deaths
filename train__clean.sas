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
proc format; value subs 1= "Marijuana" 2= "Alcohol" 3= "Methamphetamine"; run;
 data beverages; set clean; 

 if gender in (1,2);
if 2013<=year<=2023;
retain Substance;
select (genericcode);
when (0083000,0200617,0200618,0310033,0310034,0310035,031003,0310096,0310097,0310121,0310122,0310123,0310124,0310125,0310126) Substance = 1; 
when (0019140) Substance = 2;
when (0201127) Substance = 3;
otherwise Substance = 0;end; 

  if 0<age<=6 then age_cat = "Less than 6 years";
    else if 6<age<=12 then age_cat = "Between 6 and 12";
    else if 12<age<=19 then age_cat = "Between 12 and 19";
    else if 19<age<=60 then age_cat = "Between 19 and 60";
    else if age > 60 then age_cat = "Over 60 years";
    else age_cat= "";
	run;
	data beverage; set beverages; if substance in (1,3); run;
	proc contents data=beverages; run;
proc sgplot data=beverage; vline year/datalabel group=Substance lineattrs=(thickness=2); Title 'Alcohol (Beverage) and Marijuana Poisoning Calls (2013-2023)'; yaxis display=none;run;
proc sgplot data=beverage; vbar year/datalabel group=Substance groupdisplay=cluster; Title 'Alcohol (Beverage) and Marijuana Poisoning Calls (2013-2023)'; yaxis display=none;run;
proc freq data=beverage; tables substance*year/out=area_graph nocol norow nopercent; proc print data= area_graph; format substance subs.;run;

proc sgplot data=area_graph;
    title ' Methamphetamine and Marijuana Poisoning Calls (2013-2023)';
    
    /* Create an area chart for each substance */
    band x=year lower=0 upper=count / group=Substance transparency=0.5;
    
    /* Customize the y-axis */
    yaxis label= 'Cases Count';
format substance subs.;
run;
 
data root; set clean;  ;run;
proc sgplot data=root; vline year/lineattrs=(thickness=2);run;
proc freq data=root; tables root_id/nocum;run;
proc freq data=root order=freq; tables major_GC_Category/nocum;run;
proc freq data=root order=freq; tables year/nocum out=opioids;run;

proc hpsplit data=root cvmethod=random(5) maxdepth=10;
    class root_id major_GC_ID minor_GC_ID ;
    model root_id (event='100') =  major_GC_ID minor_GC_ID;
    grow gini;
    prune costcomplexity;
run;
