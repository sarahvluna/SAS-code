/* Macro for Normality Tests
Created by Sarah Luna (svl25@cornell.edu) on June 24, 2013

This macro creates a table with normality tests for each specified variable.*/

/* Example dataset can be downloaded from http://www.ats.ucla.edu/stat/data/hsb2.sas7bdat */

/* Tests for Normality

W = Shapiro-Wilk
D = Kolmogorov-Smirnov

*/

%macro normality(dataset,   	/*name of dataset*/
				test			/*test of normality (W or D)*/
				);

ods output TestsforNormality=normal;
proc univariate data=&dataset normaltest;
	var &contvars;
run;

data normal1 ; set normal;
	if testlab ne "&test" then delete; 
	drop testlab ptype psign;
	rename stat=Statistic;
	rename varname=Variable;
	if pvalue le 0.05 then Normal="N"; /*not normal*/
	else Normal="Y"; /*normal*/
run;

proc print data=normal1; run;

%mend normality;

* Set up global variables to include all variables of interest ;
* Continuous variables ;
%let contvars=
;

%normality (dataset=act,test=W);
