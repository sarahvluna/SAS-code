/* This macro that will complete PROC TTEST with all of the variables in chosen global variable*/

%macro ttest(dataset,  		/*name of dataset*/
			catvar			/*categorical group variable*/
			);

proc sort data=&dataset; by &catvar; run;

ods output ttests=tt;
ods output statistics=stat;
proc ttest data=&dataset;
class &catvar;
var &contvars;
run;

data stat1; set stat;
drop variable1 variable2 n  lowerCLstddev upperCLstddev umpulowerclstddev umpuupperclstddev minimum maximum  stderr;
run; 

data tt1; set tt;
drop df tvalue;
rename probt=pValue;
run;

proc sort data=stat1; by variable; run;
title "T-Test Analysis Summary";
proc print data=stat1; run;
proc print data=tt1; run;
%mend ttest;

*Global Change variables;
%let delta = /*list variables here*/
;

/* Run macro that will complete PROC TTEST with all of the variables in chosen global variable*/
%ttest(dataset=,catvar=);

 
