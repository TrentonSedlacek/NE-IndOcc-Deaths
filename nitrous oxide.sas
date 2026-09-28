proc import datafile = "K:\Occupational Health Grant\Jean Kwizerimana\poison\pcc data\poisoncenter.poisoncasedetails.ft.substance 3.10.25.csv"
dbms=csv 
out=poison 
replace; 
run;

proc import datafile = "K:\Occupational Health Grant\Jean Kwizerimana\poison\Code values for NE Case Detail Web Service.xlsx"
dbms=xlsx
out=reference
replace; 
sheet="Generic Codes";
 getnames=no;
datarow=4;
run;

proc print data=reference (obs=10);
run;

proc contents data=poison; run;
data vitamin_a; 
set poison; 
 startDate = datepart(startCalendar);
 format startDate MMDDYY10.;
run; 
data vitamin_a;
	set vitamin_a; 
	if genericcode in ("0045000");
month = month(startdate); 
run;
proc freq data= vitamin_a; 
tables year/nopercent norow nocol; 
run; 

/* First, check what variables are in the dataset */
proc contents data=vitamin_a;
run;

/* Create a frequency count of month-year combinations */
proc freq data=vitamin_a noprint;
   tables month*year / out=vitamin_a_counts;
run;

/* Rename and format the count variable */
data vitamin_a_counts;
   set vitamin_a_counts;
   rename count=count;
   /* If you need to ensure all combinations exist */
run;

/* Now run the report on the count dataset */
/* Export the table to Excel */
ods excel file="K:\Occupational Health Grant\Jean Kwizerimana\vitamina.xlsx" style=statistical;

proc report data=vitamin_a_counts nowd;
   columns year month count;
   define year / group 'Year';
   define month / group 'Month';
   define count / display 'Count';
run;

ods excel close;


proc sgplot data=vitamin_a; 
vbar year/datalabel; 
run;









dm 'odsresults; clear';
