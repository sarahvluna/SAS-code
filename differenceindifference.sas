/*This macro can be used for comparing group means and creating a difference in difference analysis.

From SAS: "If you want to compare values obtained from two different groups,
and if the groups are independent of each other and the data are normally or lognormally distributed in each group,
then a group test can be used."


Created by Sarah Luna (svl25@cornell.edu) on May 17, 2012

Updated July 16, 2013------------------------------------------------ */

%macro didiff (data=,
				treat=,
				base=,
				end=,
				delta=
				) ;
/*	data=name of dataset
	treat=treatment variable (control=0 v intervention=1) <---IMPORTANT, MUST BE CODED AS 0,1
	base=baseline variable (baseline hemoglobin)
	end=endline variable (endline hemoglobin)
	delta=delta variable (delta hemoglobin)
*/

ods graphics on;
title 'Difference between time points in CONTROL';
ods output Statistics=stat;
ods output TTests=pv;

proc ttest data=&data ; *by sex;
	where &treat=0; /*control group*/
	paired &end*&base;
run;

data stat; set stat;
keep Variable1 Variable2 N Mean StdDev; run;

data control;
	merge stat pv;
	by Variable1;
	drop Difference tValue DF;
run;

title 'Difference between time points in INTERVENTION';
ods output Statistics=stattx;
ods output TTests=pvtx;
proc ttest data=&data ; *by sex;
	where &treat=1; /*intervention group*/
	paired &end*&base;
run;

data stattx; set stattx;
keep Variable1 Variable2 N Mean StdDev; run;

data tx;
	merge stattx pvtx;
	by Variable1;
	drop Difference tValue DF;
run;

title 'Differences between groups at BASELINE';
ods output Statistics=base;
ods output TTests=basepv;
proc ttest data=&data cochran ci=equal umpu ; /*Add Cochran for unequal variances*/*by sex;
	class &treat;
	var &base ;
run;

data base; set base;
keep Variable N Class Mean StdDev; run;

data base1;
	merge base basepv;
	by Variable;
	drop Difference tValue DF;
run;

title 'Differences between groups at ENDLINE';
ods output Statistics=end;
ods output TTests=endpv;
proc ttest data=&data cochran ci=equal umpu ; /*Add Cochran for unequal variances*/*by sex;
	class &treat;
	var &end;
run;

data end; set end;
keep Variable N Class Mean StdDev; run;

data end1;
	merge end endpv;
	by Variable;
	drop Difference tValue DF;
run;

title 'Difference in Difference';
ods output Statistics=delta;
ods output TTests=deltapv;
proc ttest data=&data cochran ci=equal umpu ; /*Add Cochran for unequal variances*/*by sex;
	class &treat;
	var &delta;
run;

data delta; set delta;
keep Variable N Class Mean StdDev; run;

data delta1;
	merge delta deltapv;
	by Variable;
	drop Difference tValue DF;
run;

ods graphics off;

data base; set base;
	if class= 'Control' then or=0;
	else if class='High Iron' then or=1;
	else if class='Diff (1-2)' then or=2;
	drop n class;
run;

data end; set end;
	if class= 'Control' then or=0;
	else if class='High Iron' then or=1;
	else if class='Diff (1-2)' then or=2;
	drop n class;
	rename variable=end;
	rename mean=mean1;
	rename stddev=stddev1;
run;

data delta; set delta;
	if class= 'Control' then or=0;
	else if class='High Iron' then or=1;
	else if class='Diff (1-2)' then or=2;
	drop n class;
	rename variable=delta;
	rename mean=mean2;
	rename stddev=stddev2;
run;
proc sort data=base; by or; run;
proc sort data=end; by or; run;
proc sort data=delta; by or; run;

proc format;
	value orfmt 1 = 'High Iron' 0 = 'Control' 2='Diff (1-2)';
run;

data all;
	merge base end delta;
	by or;
	format or orfmt.;
	drop variable end delta;
run;

data all1; array fixorder or mean stddev mean1 stddev1 mean2 stddev2;
	set all;
	label
    	or='Group'
    	mean='Baseline Means'
    	stddev = 'Baseline StdDev'    
    	mean1= 'Endline Means'
    	stddev1='Endline StdDev'
    	mean2= 'Delta Means'
    	stddev='Delta StdDev'
    ;
	rename or=group;
run;

data basepv; set basepv;
	rename probt=BasePV;
	drop variable variances tvalue df;
run;

data endpv; set endpv;
	rename probt=EndPV;
	drop variable variances tvalue df;
run;

data deltapv; set deltapv;
	rename probt=DeltaPV;
	drop variable variances tvalue df;
run;

proc sort data=basepv; by method; run;
proc sort data=endpv; by method; run;
proc sort data=deltapv; by method; run;

data pv;
	merge basepv endpv deltapv;
	by method;
	label 
    	basePV='Baseline P Values'
    	endPV = 'Endline P Values'
    	deltaPV = 'Delta P Values'
    ;
run;

title 'Means and Standard Deviations';
proc print data=all1; run;

title 'P Values for Group Differences';
proc print data=pv; run;

title 'Difference between time points in CONTROL';
proc print data=control; run;

title 'Difference between time points in INTERVENTION';
proc print data=TX; run;

%mend;
