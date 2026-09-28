PROC IMPORT 
    DATAFILE="K:\Occupational Health Grant\Jean Kwizerimana\Lung Cancer\casespercounty.xlsx"
    DBMS=XLSX 
    OUT=casepercounty 
    REPLACE;
RUN;
proc print data=poppercounty; run;PROC IMPORT 
    DATAFILE="K:\Occupational Health Grant\Jean Kwizerimana\Lung Cancer\county population.xlsx"
    DBMS=XLSX 
    OUT=poppercounty 
    REPLACE;
RUN;

proc sql;
   create table combined_data as
   select a.*, b.*
   from casepercounty as a
   left join poppercounty as b
   on a.code = b.code;
quit;

proc print data=casespercounty; run;

data casespercounty; 
set combined_data; 
drop D E;
caseperpopo= (cases/value)*1000; 
run;
proc export data=casespercounty
   outfile="K:\Occupational Health Grant\Jean Kwizerimana\Lung Cancer\casepop_data.xlsx"
   dbms=xlsx
   replace;
run;

PROC IMPORT 
    DATAFILE="K:\Occupational Health Grant\Jean Kwizerimana\Bladder Cancer\Derry_Stove_Request3.xlsx"
    DBMS=XLSX 
    OUT=lung 
    REPLACE;
RUN;

data meso; 
set lung; 
hist= input(histologicTypeIcdO3, best12.);
age = input(ageatdiagnosis, best12.);
if cancer_type_use in ("MESOTHELIOMA");
run;
proc contents data=meso; run;
data mesothe; 
set meso; 
if 9050<=hist<=9053;
if age >= 15;
if 15 <= age <= 24 then age_group = '15-24';
    else if 25 <= age <= 34 then age_group = '25-34';
    else if 35 <= age <= 44 then age_group = '35-44';
    else if 45 <= age <= 54 then age_group = '45-54';
    else if 55 <= age <= 64 then age_group = '55-64';
    else if 65 <= age <= 74 then age_group = '65-74';
    else if 75 <= age <= 84 then age_group = '75-84';
    else if age >= 85 then age_group = '85+';
    else age_group = 'Unknown'; 
run;
proc freq data=mesothe order=freq; 
tables age_group  /nocum;
run;
proc sgplot data=mesothe; 
hbar year/datalabel; 
Title "Annual number of Mesothelioma Cases";
run;

proc sgplot data=mesothe; 
hbar age_group/datalabel categoryorder=RESPDESC; 
Title "Number of Mesothelioma Cases By Age Group";
run;
