/*Crouter, Freedson, Santos-Lozano Macro*/

%macro CFS(			indata, 	/*name of input dataset*/
					rawfinal, 	/*name of computed MET/min LONG dataset*/
					baseorend,  /*0 for baseline, 1 for endline*/
					wear,		/*wear variable*/
					weight,		/*weight variable*/
					final       /*name of final dataset*/
);

proc expand data=&indata out=data1;

	convert axis1=movsum / transformout=(movsum 6);
	convert axis1=movmean / transformout=(movave 6);
	convert axis1=movstd / transformout=(movstd 6);

	convert axis1=cmovmean / transformout=(cmovave 6);
	convert axis1=cmovstd / transformout=(cmovstd 6);
	convert axis1=cmovsum / transformout=(cmovsum 6);

	convert axis1=bmovmean / transformout=(movave 6 reverse);
	convert axis1=bmovstd / transformout=(movstd 6 reverse);
	convert axis1=bmovsum / transformout=(movsum 6 reverse);

	convert vm=vmmean / transformout=(movave 6);
	convert vm=cvmmean / transformout=(cmovave 6);
	convert vm=bvmmean / transformout=(movave 6 reverse);

run; 

data data1; set data1;
if vm lt 1 then vm=0;
cv = (100*movstd)/movmean;
ccv = (100*cmovstd)/cmovmean;
bcv = (100*bmovstd)/bmovmean;

mincv = min(cv,ccv,bcv);
if mincv lt 0 then abcv=mincv*(-1);
	else abcv=mincv;


minmean = min(movmean,cmovmean,bmovmean);

meansum = mean(movsum,cmovsum,bmovsum);

/*************************************************************************/

*Crouter 2010;
if axis1 lt 10 then mets1=1;
	else if abcv le 10 then mets1 = 2.294275*(exp(0.00084679*axis1)) ;
	else if abcv gt 10 then mets1 = 0.749395+(0.716431*(Log(axis1)))-(0.179874*(Log(axis1))**2)+(0.033173*(Log(axis1))**3);

vmm=mean(vmmean,cvmmean,bvmmean);

if wear=0 then type=0;
else if abcv le 10 then type=2;
	else type=1;

*Saski/Freedson 2010;
if wear=0 then freedson=5;
	else if meansum lt 2690 then freedson=1;
	else if 2690 le meansum le 6166 then freedson=2;
	else if 6167 le meansum le 9642 then freedson=3;
	else freedson = 4;

*Santos Lozano 2013;
if vmm lt 1 then vmm=0;
slmets1=2.8323+0.00054*vmm-0.059123*weight+1.4410;

/*************************************************************************/

drop time orig_obs n movmean movstd cv ccv bcv cmovmean bmovmean mincv bmovstd cmovstd movsum
bmovsum cmovsum;
run;

proc expand data=data1 out=data1;
	convert mets1=bmets / transformout=(movave 6);
	convert mets1=cmets / transformout=(cmovave 6);
	convert mets1=fmets / transformout=(movave 6 reverse);
	convert slmets1=bslmets / transformout=(movave 6);
	convert slmets1=cslmets / transformout=(cmovave 6);
	convert slmets1=fslmets / transformout=(movave 6 reverse);
run; 

data &rawfinal; set data1;
mets=mean(bmets,cmets,fmets);
slmets=mean(bslmets,cslmets,fslmets);

if wear=0 then level=4;
else if mets =1 then level=0;
else if 1 lt mets le 3 then level =1;
else if 3 lt mets le 6 then level =2;
else if mets gt 6 then level =3;

if wear=0 then slevel=4;
else if slmets le 1 then slevel=0;
else if 1 lt slmets le 3 then slevel =1;
else if 3 lt slmets le 6 then slevel =2;
else slevel =3;

label
	minmean ="Moving Average of 6 Observations of Axis 1"
	movstd ="Back Standard Deviation of 6 Observations of Axis 1"
	abcv ="Coefficient of Variation of Axis 1"
	mets ="METs: Crouter 2-regression adult model (2012)"
	type="Type of Activity (1=Life Style (variable); 2=Walk/Run (consistent))"
	timepoint="0=Baseline;1=Endline"
	inc="Inclinometer"
	vm="Vector Magnitude"
	id="Participant ID"
	epoch="Epoch"
	freedson="Classification by Freedson Cutpoints (1=Light;2=Moderate;3=Hard;4=Very Hard,5=Nonwear)"
	meansum="Mean of the Forward, Backward, and Centered Moving Sums of 6 Observations"
	slmets="METs: Santos-Lozano adult women model (2013)"
	level ="Crouter Level of Activity (0=Sedentary,1=Light,2=Moderate,3=Vigorous, 4=Nonwear)"
	slevel="Santos-Lozano Level of Activity (0=Sedentary,1=Light,2=Moderate,3=Vigorous,4=Nonwear)"
	day="Day of the Week (1=Tues,2=Wed,3=Thurs,4=Fri,5=Sat,6=Sun)"
	&wear="Wear 1=yes,0=no"
	;

orig_obs = n;
if mod(_n_,6) eq 1 then output;

keep date epoch id axis1 axis2 axis3 inc vm mets slmets type timepoint freedson level day &wear slevel;

run;

proc freq data=&rawfinal;
ods output OneWayFreqs=level;
by id date;
tables level;
run;

data level; set level;
drop table percent f_level cumfrequency cumpercent;
run;

proc sort data=level; by id; run;

proc transpose data=level out=level; 
id level;
by id date;
run;

data finallevel (rename=(_0=sedentary
					_1=light
					_2=moderate
					_3=vigorous
					_4=nonwear));
set level;
drop _name_;
label
	sedentary="Minutes Spent at MET=1 (Crouter 2010)"
	light="Minutes Spent at MET 1-3 (Crouter 2010)"
	moderate="Minutes Spent at MET 3-6 (Crouter 2010)"
	vigorous="Minutes Spent at MET>6 (Crouter 2010)"
	nonwear="Minutes Not Wearing Actigraph"
	wear="Minutes Wearing Actigraph"
	;
run;

proc freq data=&rawfinal;
ods output OneWayFreqs=type;
by id date;
tables type;
run;

data type; set type;
drop table percent f_type cumfrequency cumpercent;
run;

proc sort data=type; by id; run;

proc transpose data=type out=type; 
id type;
by id date;
run;

data finaltype(rename=(_1=lifestyle
					_2=walkrun
					_0=nonweartype
					));
set type;
drop _name_;
label
	lifestyle="Minutes spent in Lifestyle Activities"
	walkrun="Minutes Spent in Walk/run Activities"
	;
run;

proc freq data=&rawfinal;
ods output OneWayFreqs=freedson;
by id date;
tables freedson;
run;

data freedson; set freedson;
drop table percent f_freedson cumfrequency cumpercent;
run;

proc sort data=freedson; by id; run;

proc transpose data=freedson out=freedson; 
id freedson;
by id date;
run;

data finalfreedson(rename=(_1=sedentaryF
					_2=lightF
					_3=moderateF
					_4=vigorousF
					_5=nonwearF
					));
set freedson;
drop _name_;
label
	lightF="Minutes Spent at Count <2690 (Freedson 2011)"
	moderateF="Minutes Spent at Count 2690-6166 (Freedson 2011)"
	hardF="Minutes Spent at Count 6167-9642 (Freedson 2011)"
	veryhardF="Minutes Spent at Count >9643 (Freedson 2011)"
	;
run;

proc freq data=&rawfinal;
ods output OneWayFreqs=slevel;
by id date;
tables slevel;
run;

data slevel; set slevel;
drop table percent f_slevel cumfrequency cumpercent;
run;

proc sort data=slevel; by id; run;

proc transpose data=slevel out=slevel; 
id slevel;
by id date;
run;

data finalslevel (rename=(_0=sedentarySL
					_1=lightSL
					_2=moderateSL
					_3=vigorousSL
					_4=nonwearSL));
set slevel;
drop _name_;
label
	sedentarySL="Minutes Spent at MET=1 (Santos-Lozano 2013)"
	lightSL="Minutes Spent at MET 1-3 (Santos-Lozano 2013)"
	moderateSL="Minutes Spent at MET 3-6 (Santos-Lozano 2013)"
	vigorousSL="Minutes Spent at MET>6 (Santos-Lozano 2013)"
	;
run;

data &final;
merge finallevel finaltype finalfreedson finalslevel;
by id;
timepoint=&baseorend;
if nonwear lt 0 then nonwear=0; else nonwear=nonwear;
if sedentary lt 1 then sedentary=0;
else sedentary=sedentary;
if light lt 1 then light=0; else light=light;
if moderate lt 1 then moderate=0; else moderate=moderate;
if vigorous lt 1 then vigorous=0; else vigorous=vigorous;
total=sedentary+light+moderate+vigorous+nonwear;
wear=sedentary+light+moderate+vigorous;
notwear=1440-wear;
if notwear lt 0 then notwear=0; else notwear=notwear;
percentwear=(wear/1440)*100;

if lightF lt 1 then lightF=0; else lightF=lightF;
if moderateF lt 1 then moderateF=0; else moderateF=moderateF;
if vigorousF lt 1 then vigorousF=0; else vigorousF=vigorousF;

if lightSL lt 1 then lightSL=0; else lightSL=lightSL;
if moderateSL lt 1 then moderateSL=0; else moderateSL=moderateSL;
if vigorousSL lt 1 then vigorousSL=0; else vigorousSL=vigorousSL;

if sedentaryF lt 1 then sedentaryF=0;
else sedentaryF=sedentaryF;

if sedentarySL lt 1 then sedentarySL=0;
else sedentarySL=sedentarySL;
wearhr=wear/60;
notwearhr=notwear/60;

label
	sedentary="Minutes Spent at MET=1 (Crouter 2010)"
	light="Minutes Spent at MET 1-3 (Crouter 2010)"
	moderate="Minutes Spent at MET 3-6 (Crouter 2010)"
	vigorous="Minutes Spent at MET>6 (Crouter 2010)"
	notwear="Minutes Not Wearing Actigraph"
	wear="Minutes Wearing Actigraph"
	sedentaryF="Minutes Spent at Count <1951 (Freedson 2011)"
	lightF="Minutes Spent at Count 1952-5274 (Freedson 2011)"
	moderateF="Minutes Spent at Count 5275-9498 (Freedson 2011)"
	vigorousF="Minutes Spent at Count >9499 (Freedson 2011)"
	sedentarySL="Minutes Spent at MET=1 (Santos-Lozano 2013)"
	lightSL="Minutes Spent at MET 1-3 (Santos-Lozano 2013)"
	moderateSL="Minutes Spent at MET 3-6 (Santos-Lozano 2013)"
	vigorousSL="Minutes Spent at MET>6 (Santos-Lozano 2013)"
	lifestyle="Minutes Spent in Lifestyle Activities"
	walkrun="Minutes Spent in Walk/Run Activities"
	percentwear="Percent of Time Wearing Actigraph"
	total="Total Minutes Accounted For"
	timepoint="Study Timepoint"
	wearhr="Hours Wearing Actigraph"
	notwearhr="Hours Not Wearing Actigraph"
	;
drop nonwear nonweartype nonwearF nonwearSL;
run;
%mend;

%CFS(annie,longannie,.,wear,weight,anniefinal);
