libname mylib "K:\Occupational Health Grant\Jean Kwizerimana\Deacertificate\suicide data";
proc import datafile= 'K:\Occupational Health Grant\Jean Kwizerimana\Deacertificate\suicide data\county.xlsx'
dbms=xlsx
out=countpop
replace;
run;
proc import datafile= 'K:\Occupational Health Grant\Jean Kwizerimana\Deacertificate\suicide data\deathspercounty.xlsx'
dbms=xlsx
out=dpercounty
replace;
run;
proc contents data=suicide; run; 
proc contents data=dpercounty; run;
data suicide; 
set mylib.suicides;
if dod_yr in (2013);
run;

proc sql;
  create table joined as
  select a.*, b.*
  from countpop as a
  inner join dpercounty as b
  on a.Code = b.Code;
quit;
proc print data=suicide ; run;
data suicide; 
set joined; 
suicpercounty = (deaths/Value)*1000;
run;

proc export data=suicide
    outfile= "K:\Occupational Health Grant\Jean Kwizerimana\Deacertificate\suicide data\dpercount.xlsx"
    dbms=xlsx 
    replace;
run;
proc contents data=mylib.suicides; /* Check dataset structure */
run;
proc print data=mylib.suicides (obs=10); /* Print first 10 rows */
run;
proc means data=suicide; 
var ageunits; 
run;
proc freq data=suicide order=freq; 
tables CNTYOD/nocum nopercent; 
run;

