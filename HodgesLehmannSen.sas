/**********************************************************
Created by Sarah V. Luna
svl25@cornell.edu

This macro compares medians of two groups with the Wilcoxon 2-sided t test and the Hodges-Lehmann-Sen shift.
**********************************************************/


/*Global Variable list
%let varlist = ; */

/*Hodges Lehmann Sen macro*/
%macro hls(dataset=,     	/*name of dataset*/
			classvar=,		/*name of class level variable (ie: intervention group)*/
			path=			/*path of .rtf file with results. Leave blank if you do not want to create an .rtf file*/
			);

proc npar1way hl alpha=0.05 data=&dataset ;
	class &classvar;
	var &varlist;
	ods select WilcoxonTest HodgesLehmann;
	ods output WilcoxonTest=wt;
	ods output HodgesLehmann=hl;
run;

data wt1; 
	set wt;
	if Name1 ne 'PT2_WIL' then delete; 
run;

proc sort data=hl; by Variable; run;
proc sort data=wt1; by Variable; run;

data hl1 (rename=(Shift=HL_Shift cValue1=P_Value)) ;
	merge hl wt1 ;
	by Variable;
	drop Name1 nValue1 Midpoint StdErr Label1;
run;

data hl2; set hl1;
	if P_value le 0.05 then Significant='<0.05';
	else if 0.05 lt P_value le 0.10 then Significant='<0.10';
	else Significant='';
run;

ods rtf file="&path";
title "Medians of Selected Variables by &classvar";

proc means data=&dataset n median q1 q3 maxdec=1;
	class &classvar;
	var &varlist;
run;

title "Wilcoxon Two-Group Comparisons by &classvar and Hodges-Lehmann-Sen Shift";
proc print data=hl2;run;
ods rtf close;

%mend;


*Example;
%let varlist = baselinevariable endlinevariable changevariable;
%hls(dataset=data123,classvar=intervention,path=);
