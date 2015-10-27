libname ash '~/ashwin/';


/* recode variables that need recoding*/
 
data test;
set ash.imaiblfuq32012_final_v2;
ID_new = _N_;

length timeperiod $4.;
if date_obs le '31MAR2011'd then timeperiod='pre'; else timeperiod='post';

array a(*) reg_clerk imai_nurse other_staff;
do i=1 to dim(a);
if a(i)=-1 then a(i)=1;
end;
drop i;

if classagree1 ne . and classagree2 ne . then do;
if classagree1 ne classagree2 then noclassagree=2;
end;

bp_sys_yes=0;
if bp_sys ne . then do;
bp_sys_yes=1;
if bp_sys < 60 then bp_sys60=1; else if bp_sys ge 60 then bp_sys60=0;
if bp_sys >140 then bp_sys140=1; else if bp_sys le 140 then bp_sys140=0;
end;

bp_dias_yes=0;
if bp_dias ne . then do;
bp_dias_yes=1; 
if bp_dias < 40 then bp_dias40=1; else if bp_dias ge 40 then bp_dias40=0;
if bp_dias > 100 then bp_dias100=1; else if bp_dias le 100 then bp_dias100=0;
end;

if height ne . then height_Rec=1; else height_rec=0;
if weight ne . then weight_rec=1; else weight_rec=0;
if pulse ne . then pulse_rec=1; else pulse_rec=0;
if temp ne . then temp_rec=1; else temp_rec=0;
if temp >38 then temp38=1;

if nurseSIS1 = '-' then nurseSIS1=' ';
if mentorSIS1 = '-' then mentorSIS1=' ';

if nurseSIS2 = '-' then nurseSIS2=' ';
if mentorSIS2 = '-' then mentorSIS2=' ';

if nurseSIS3 = '-' then nurseSIS3=' ';
if mentorSIS3 = '-' then mentorSIS3=' ';

if nurseask_period_date > ' ' then nurseask_period_yn = 'Yes'; 

if date_obs = . then delete;

/*Consultation time*/
Constn_time = time_start - time_end;

/*Years of Experience*/
if exp_opd < 5.6 then  expgr=1;
else expgr= 2;

Time_int =time_end -Time_start;

Month = Month(date_obs);
run;

run;
ods html close; /* close previous */
ods html; /* open new */
proc print data=test (obs=500); var bp_sys bp_sys140;run;

proc sort data=test;
by timeperiod id_new;
run;

ods html close; /* close previous */
ods html; /* open new */
proc freq data=test;
tables (_all_)*timeperiod;
run;

*table 1 - patient characteristics;
proc freq data=test order=data;
tables timeperiod (pt_sex bp_sys60 bp_sys140 bp_dias40 bp_dias100 chief_complaint1)*timeperiod/chisq;
run;

proc ttest data=test;
class timeperiod;
var pt_age;
run;

*table 2 - nurse characteristics;
proc sort data=test out=test_nurse nodupkey; by nurse_name nurseid; run;
proc freq data=test_nurse;
tables nurse_name nurseid;
run;
ods html close; /* close previous */
ods html; /* open new */
proc freq data=test order=data;
tables (nurse_train_imai level_educ reg_clerk imai_nurse other_staff sign_check bp_sys_yes bp_dias_yes height_rec weight_rec pulse_rec temp_rec temp38)*timeperiod/chisq missing;
run;

*screening variables;
proc freq data=test order=data;
tables (nurseask_cough nurseask_weightloss nurseask_pallor nurseask_lesions nurseask_penile nurseask_scrotal
nurseask_net nurseask_counsel_net nurseask_smoke nurseask_counsel_smoke nurseask_alc nurseask_counsel_alc nurseask_sex
nurseask_counsel_sex nurseask_preg nurseask_refer_anc nurseask_fp nurseask_refer_fpclinic nurseask_hiv nurseask_refer_hivtest)*timeperiod/chisq missing;
run;

proc print data=test; var bp_sys bp_dias; run;

*t-test for differences in mean experience by time period;
proc ttest data=test;
class timeperiod;
var exp_opd diff;
run;

proc print data=ash.imaiblfuq32012_final_v3_rest;
var id diag_nurse diag_mentor diag_agree tx_agree;
where diag_nurse = diag_mentor and diag_agree=2;
run;

data time (keep=id id_new timeperiod time_end time_start);
set test;
run;

*table y;
data comp (keep=timeperiod chief_complaint1-chief_complaint3 classagree1-classagree3 treatagree1-treatagree3);
set test;
run;
ods html close; /* close previous */
ods html; /* open new */

*diagnosis;
proc print data=ash.for_table_y; where chief_complaint ne ' '; run;
proc freq data=ash.for_table_y; tables chief_complaint;run;
proc freq data=ash.for_table_y order=data;
tables classagree*timeperiod/chisq missing;
where chief_complaint ne ' ';
run;
%macro comp(var1);
proc freq data=ash.for_table_y order=data;
tables classagree*timeperiod/ missing;
where chief_complaint=&var1;
run;
%mend;
%comp('Cough/difficulty breathing');
%comp('FEMALE with GU symptoms or pelvic pain');
%comp('Epigastric pain');
%comp('Fever');
%comp('Headache or neurological condition');
%comp('Mouth or throat problem');
%comp('Skin problem or lump');
%comp('Back or joint pain');
%comp('MALE with GU symptoms of lower abdominal pain');
%comp('Diarrhea');
%comp('Hypertension');
%comp('Genital or anal sore, ulcer or wart');
%comp('Mental problem (write-in specific complaint)');
%comp('Lower extremity edema');
%comp('Other problem (write-in specific complaint)');


*treatment;
proc freq data=ash.for_table_y order=data;
tables treatagree*timeperiod/chisq missing;
where chief_complaint ne ' ';
run;
%macro comp2(var1);
proc freq data=ash.for_table_y order=data;
tables treatagree*timeperiod/chisq missing;
where chief_complaint=&var1;
run;
%mend;
%comp2('Cough/difficulty breathing');
%comp2('FEMALE with GU symptoms or pelvic pain');
%comp2('Epigastric pain');
%comp2('Fever');
%comp2('Headache or neurological condition');
%comp2('Mouth or throat problem');
%comp2('Skin problem or lump');
%comp2('Back or joint pain');
%comp2('MALE with GU symptoms of lower abdominal pain');
%comp2('Diarrhea');
%comp2('Hypertension');
%comp2('Genital or anal sore, ulcer or wart');
%comp2('Mental problem (write-in specific complaint)');
%comp2('Lower extremity edema');
%comp2('Other problem (write-in specific complaint)');


*table z;
data ash.for_table_z;
set ash.for_table_z;
length timeperiod $4.;
if date_obs le '31MAR2011'd then timeperiod='pre'; else timeperiod='post';
run;
proc freq data=ash.for_table_z order=data;
tables diag_agree*timeperiod tx_agree*timeperiod/missing;
where diag_mentor not in (' ', '-');
run;
proc freq data=ash.for_table_z;
tables diag_mentor;
run;
proc print data=ash.for_table_z;
where diag_nurse = 'Abscess' or diag_mentor = 'Abscess';
run;
proc print data=ash.for_table_z;
where diag_mentor = '-';
run;

%macro comp3(var1);
proc freq data=ash.for_table_z order=data;
tables diag_agree*timeperiod tx_agree*timeperiod/missing;
where diag_mentor=&var1;
run;
%mend;

%comp3('Abscess');
%comp3('Arthritis');
%comp3('Bloody diarrhea');
%comp3('Bronchitis'); *none;
%comp3('Chronic cough');
%comp3('Dental Oral Disorders');
%comp3('Digestive disorder');
%comp3('Epilepsy');
%comp3('Eye disorder');
%comp3('Fever');
%comp3('GYN disorder');
%comp3('Gastritis');
%comp3('Genital Ulcer');
%comp3('HTN');
%comp3('Headache');
%comp3('Hemorrhoids');
%comp3('Intestinal parasite');
%comp3('LRTI');
%comp3('Lumbago');
%comp3('Malaria');
%comp3('Neurological disorder');
%comp3('Non-bloody diarrhea');
%comp3('Other');
%comp3('Pneumonia');
%comp3('STI');
%comp3('Skin disorder');
%comp3('Suspect TB');
%comp3('TB');
%comp3('Trauma');
%comp3('URTI');
%comp3('UTI');
%comp3('Vaginal discharge');

*test agreement? - no kappa;
proc freq data=ash.for_table_z;
tables diag_agree tx_agree/chisq;
run;

*Table A;
data temp;
set ash.imaiblfuq32012_final_v3_rest;
length timeperiod $4.;
if date_obs le '31MAR2011'd then timeperiod='pre'; else timeperiod='post';
run;



*dx;
proc freq data=temp order=data;
tables (health_center nurse_train_imai pt_sex)*timeperiod/chisq;
where diag_agree=1;
run;
proc ttest data=temp;
class timeperiod;
var exp_opd;
where diag_agree=1;
run;

*tx;
proc freq data=temp order=data;
tables (health_center nurse_train_imai pt_sex)*timeperiod/chisq;
where tx_agree=1;
run;
proc ttest data=temp;
class timeperiod;
var exp_opd;
where tx_agree=1;
run;


*totals to assess time trend;
data post (keep=timeperiod date_obs date_new diag_agree tx_agree);
set temp;
date_new= date_obs;
format date_new MONYY7.;
where timeperiod='post';
run;
proc print data=post (obs=50);run;
proc freq data=post; tables date_new*diag_agree;run;
proc means data=post n ; *export to excel to make graphs;
class date_new diag_agree;
var diag_agree;
run;

/* recode variables that need recoding*/

data test;
set ash.imaiblfuq32012_final_v3_rest;
ID_new = _N_;
length timeperiod $4.;
if date_obs le '31MAR2011'd then timeperiod='pre'; else timeperiod='post';

array a(*) reg_clerk imai_nurse other_staff;
do i=1 to dim(a);
if a(i)=-1 then a(i)=1;
end;
drop i;

if 0<= exp_opd < 4 then  expgr= '0-4';
else if exp_opd >=4 then expgr='>=4';



Cons_time = (time_end - time_start)/60;

if nurse_train_imai = 'Yes' then IMAI_train= 'Yes';
else if nurse_train_imai = 'No' then IMAI_train = 'No';

label Cons_time="Consultation time(mins)";

run;



/* Kappa analysis*/

/* Structure data to have square table*/

%macro Kappa2(per, trn);
data test1&trn;
set test;
where timeperiod = "&per" and nurse_train_imai = "&trn";
run;

proc sql;
select quote(diag_nurse)  into: nur
separated by ' '
from test1&trn;
select quote(diag_mentor)  into: ment
separated by ' '
from test1&trn
quit;

Data b&per&trn;
set test1&trn;
if diag_nurse not in (&ment) then do;
diag_nurseb = diag_mentor;
diag_mentorb = diag_nurse;
wt=0;
timeperiod="&per";
nurse_train_imai="&trn";
end;

where diag_nurse not in (&ment);
keep diag_nurseb diag_mentorb wt timeperiod;
run; 

Data c&per&trn;
set test1&trn;
if diag_mentor not in (&nur) then do;
diag_nurseb = diag_mentor;
diag_mentorb = diag_nurse;
wt=0;
end;

timeperiod="&per";

nurse_train_imai="&trn";
where diag_mentor not in (&nur);
keep diag_nurseb diag_mentorb wt timeperiod;

run; 

Data Kappa&per&trn;

set test1&trn (keep = diag_nurse diag_mentor timeperiod nurse_train_imai) b&per&trn (rename=(diag_nurseb = diag_nurse diag_mentorb = diag_mentor )) c&per&trn (rename=(diag_nurseb = diag_nurse diag_mentorb = diag_mentor ));

if wt=. then wt=1;
run;
%mend Kappa2;

%Kappa2(per=post, trn=Ye);
%Kappa2(per=post, trn=No);

/* Kappa analysis*/
proc  freq data=KappapostYe;
title1 "Second bullet";
title2 "Kappa for Post period for those who took training";
weight wt/zeros;
table diag_nurse*diag_mentor/agree nocol nopercent norow ;
ods select  KappaStatistics  SymmetryTest;
run;

proc  freq data=KappapostNo;
title1 "Second bullet";
title2 "Kappa for Post Period";
weight wt/zeros;
table diag_nurse*diag_mentor/agree nocol nopercent norow ;
ods select  KappaStatistics  SymmetryTest;
run;

/*%let trn= Ye;*/
/*%Let yn = Yes*/

data Train_no0;
set test;
keep nurseid;
where timeperiod = "post" and nurse_train_imai = "No";
run;



proc sql;
create table Train_no as
select * 
from test

where nurseid in (select nurseid from Train_no0) and timeperiod="pre";
quit;

data Train_yes0;
set test;
keep nurseid;
where timeperiod = "post" and nurse_train_imai = "Ye";
run;

proc sql;
create table Train_Yes as
select * 

from test
where nurseid in (select nurseid from Train_yes0) and timeperiod="pre";
quit;
/* Kappa analysis by training and no training*/

%macro Kappa3(per, trn,yn);

proc sql;
select quote(diag_nurse)  into: nur
separated by ' '
from Train_&yn;
select quote(diag_mentor)  into: ment
separated by ' '
from Train_&yn
quit;


Data b2&per&trn;
set Train_&yn;
if diag_nurse not in (&ment) then do;
diag_nurseb = diag_mentor;
diag_mentorb = diag_nurse;
wt=0;
timeperiod="&per";
nurse_train_imai="&trn";
end;

where diag_nurse not in (&ment);
keep diag_nurseb diag_mentorb wt timeperiod;
run; 


Data c2&per&trn;
set Train_&yn;
if diag_mentor not in (&nur) then do;
diag_nurseb = diag_mentor;
diag_mentorb = diag_nurse;

wt=0;
end;

timeperiod="&per";
nurse_train_imai="&trn";
where diag_mentor not in (&nur);
keep diag_nurseb diag_mentorb wt timeperiod;
run;


Data Kappa2&per&yn;
set Train_&yn (keep = diag_nurse diag_mentor timeperiod nurse_train_imai) b2&per&trn (rename=(diag_nurseb = diag_nurse diag_mentorb = diag_mentor )) c2&per&trn (rename=(diag_nurseb = diag_nurse diag_mentorb = diag_mentor ));
if wt=. then wt=1;
run;

%mend Kappa3;
%Kappa3(per=pre, trn=No, yn=Yes);
%Kappa3(per=pre, trn=No, yn=No)


/*This macro runs the logistic model for diag_agree and tx_agree and extracts their ORs*/

%macro logis(resp, suf);
ods output "Odds Ratios" = timeperiod_&suf;
proc logistic data=test;
class timeperiod;
model &resp (event='1')= timeperiod;
run;

proc sort data=test;by timeperiod;run;
ods output "Odds Ratios" = IMAI_train_&suf;
proc logistic data=test;
class IMAI_train;
model &resp (event='1')= IMAI_train;
by timeperiod;
run;

proc sort data=test;by timeperiod;run;
ods output "Odds Ratios" = expgr_&suf;
proc logistic data=test;
class expgr;
model &resp (event='1')= expgr;
by timeperiod;
run;

ods output "Odds Ratios" = pt_sex_&suf;
proc logistic data=test;
class pt_sex;
model &resp (event='1')= pt_sex;
by timeperiod;
run;

ods output "Odds Ratios" = TRAINMONTH_&suf;
proc logistic data=test;
class TRAINMONTH;
model &resp (event='1')= TRAINMONTH;
by timeperiod;

run;

ods output "Odds Ratios" = level_educ_&suf;
proc logistic data=test;
class level_educ;
model &resp (event='1')= level_educ;
by timeperiod;
run;

ods output "Odds Ratios" = Mult_&suf;
proc logistic data=test;
class timeperiod IMAI_train expgr pt_sex TRAINMONTH level_educ;
model &resp (event='1')= timeperiod IMAI_train expgr pt_sex TRAINMONTH level_educ;
by timeperiod;
run;

data orci_&suf;
set timeperiod_&suf IMAI_train_&suf  expgr_&suf pt_sex_&suf TRAINMONTH_&suf level_educ_&suf;
run;

data orci_&suf;set orci_&suf;
effect=upcase(effect);
run;

data Mult_&suf;
set Mult_&suf;
effect=upcase(effect);
run;
%mend logis;

%logis(resp=diag_agree, suf=dg);
%logis(resp=tx_agree, suf=tx);

/* Prepare odds ratio data for plots*/

data orci_dg;
set orci_dg;

If effect = 'TIMEPERIOD POST VS PRE' and timeperiod= ' ' then Factor= 'Time period: Post vs Pre' ;  
If effect = 'IMAI_TRAIN NO VS YES' and timeperiod= 'post' then Factor= 'IMAI training: No vs Yes';
else If effect = 'EXPGR 0-4 VS >=4' and timeperiod= 'post' then Factor= 'Experience: <4 vs >=4.';
else If effect = 'EXPGR 0-4 VS >=4' and timeperiod= 'pre'  then Factor= 'Experience: <4 vs >=4';
else If effect = 'PT_SEX FEMALE VS MALE' and timeperiod= 'post'  then Factor= 'Pt sex, F vs M. ';
else If effect = 'PT_SEX FEMALE VS MALE' and timeperiod= 'pre'  then Factor=  'Pt sex, F vs M';
else if effect = 'LEVEL_EDUC A1 VS A2' then factor ='LEVEL EDUC A1 VS A2';
else factor=effect;

Agreement='Diagnosis';
run;

data orci_tx;
set orci_tx;

If effect = 'TIMEPERIOD POST VS PRE' and timeperiod= ' ' then Factor= 'Time period: Post vs Pre' ;  
If effect = 'IMAI_TRAIN NO VS YES' and timeperiod= 'post' then Factor= 'IMAI training: No vs Yes';
else If effect = 'EXPGR 0-4 VS >=4' and timeperiod= 'post' then Factor= 'Experience: <4 vs >=4.';
else If effect = 'EXPGR 0-4 VS >=4' and timeperiod= 'pre'  then Factor= 'Experience: <4 vs >=4';
else If effect = 'PT_SEX FEMALE VS MALE' and timeperiod= 'post'  then Factor= 'Pt sex, F vs M. ';
else If effect = 'PT_SEX FEMALE VS MALE' and timeperiod= 'pre'  then Factor=  'Pt sex, F vs M';
else if effect = 'LEVEL_EDUC A1 VS A2' then factor ='LEVEL EDUC A1 VS A2';
else factor=effect;
Agreement='Treatment';
run;

data Mult_dg;
set Mult_dg;
If effect = 'TIMEPERIOD POST VS PRE' and timeperiod= ' ' then Factor= 'Time period: Post vs Pre' ;  
If effect = 'IMAI_TRAIN NO VS YES' and timeperiod= 'post' then Factor= 'IMAI training: No vs Yes';
else If effect = 'EXPGR 0-4 VS >=4' and timeperiod= 'post' then Factor= 'Experience: <4 vs >=4.';
else If effect = 'EXPGR 0-4 VS >=4' and timeperiod= 'pre'  then Factor= 'Experience: <4 vs >=4';
else If effect = 'PT_SEX FEMALE VS MALE' and timeperiod= 'post'  then Factor= 'Pt sex, F vs M. ';
else If effect = 'PT_SEX FEMALE VS MALE' and timeperiod= 'pre'  then Factor=  'Pt sex, F vs M';
else if effect = 'LEVEL_EDUC A1 VS A2' then factor ='LEVEL EDUC A1 VS A2';
else factor=effect;
Agreement='Diagnosis';
run;

data Mult_tx;
set Mult_tx;
If effect = 'TIMEPERIOD POST VS PRE' and timeperiod= ' ' then Factor= 'Time period: Post vs Pre' ;  
If effect = 'IMAI_TRAIN NO VS YES' and timeperiod= 'post' then Factor= 'IMAI training: No vs Yes';
else If effect = 'EXPGR 0-4 VS >=4' and timeperiod= 'post' then Factor= 'Experience: <4 vs >=4.';
else If effect = 'EXPGR 0-4 VS >=4' and timeperiod= 'pre'  then Factor= 'Experience: <4 vs >=4';
else If effect = 'PT_SEX FEMALE VS MALE' and timeperiod= 'post'  then Factor= 'Pt sex, F vs M. ';
else If effect = 'PT_SEX FEMALE VS MALE' and timeperiod= 'pre'  then Factor=  'Pt sex, F vs M';
else if effect = 'LEVEL_EDUC A1 VS A2' then factor ='LEVEL EDUC A1 VS A2';
else factor=effect;
Agreement='Treatment';
run;

/*by Health center and nurse id*/

%macro logis2(resp, suf);

proc sort data=test;by Health_Center timeperiod;run;
ods output "Odds Ratios" = IMAI_train2_&suf;
proc logistic data=test;
class IMAI_train;
model &resp (event='1')= IMAI_train;
by Health_Center  timeperiod;
run;

proc sort data=test;by nurseid timeperiod;run;
ods output "Odds Ratios" = IMAI_train3_&suf;
proc logistic data=test;
class IMAI_train ;
model &resp (event='1')= IMAI_train;
by nurseid;
*where timeperiod=post;
run;

data orcitr_&suf;set IMAI_train2_&suf;
effect=upcase(effect);
run;

data orcitr3_&suf;set IMAI_train3_&suf;
effect=upcase(effect);
run;

%mend logis2;
%logis2(resp=diag_agree, suf=dg);
%logis2(resp=tx_agree, suf=tx);

proc sql;
create table dt as
select nurseid,date_obs,  min(date_obs) as start_dt format=MMDDYY10., month(date_obs) as start_mth, max(date_obs) as end_dt format=MMDDYY10.,Cons_time,
 max(date_obs)- min(date_obs) as MaxDur label='Max duration (days)', date_obs- min(date_obs) as Dur label='Duration (days)',
count(nurseid) as numvist, trainmonth, timeperiod, health_center, diag_agree, tx_agree, IMAI_train
from test
where nurseid in (select nurseid from test where IMAI_train='Yes') and timeperiod='post'
group by nurseid
order by nurseid, date_obs;
quit;
data dt;
set dt;
vistnm + 1;
by nurseid date_obs;
if first.nurseid then vistnm =1;
run;

proc sql;
create table dt as
select *, Cons_time,numvist/Dur as intDur_rat label="Numberof Interventions-Duration ratio"
from dt
order by nurseid, date_obs;
quit;

/* outputs*/

ods graphics off;
proc  freq data=KappapostYe;
title1 "Kappa analysis: Diagnosis agree";
title2 "Kappa for Post period for those who took training";
weight wt/zeros;
table diag_nurse*diag_mentor/agree nocol nopercent norow ;
ods select  KappaStatistics  SymmetryTest;
run;
proc  freq data=Kappa2preyes;
title1 "Kappa analysis: Diagniosis agree";
title2 "Kappa for Pre period for those who took training";
weight wt/zeros;
table diag_nurse*diag_mentor/agree nocol nopercent norow ;
ods select  KappaStatistics  SymmetryTest;
run;

proc  freq data=KappapostNo;

title1 "Kappa analysis: Diagnosis agree";
title2 "Kappa for Post period for those with no training";
weight wt/zeros;
table diag_nurse*diag_mentor/agree nocol nopercent norow ;
ods select  KappaStatistics  SymmetryTest;
run;

proc  freq data=Kappa2preNo;
title1 "Kappa analysis: Diagniosis agree";
title2 "Kappa for Pre period for those who did not take training";
weight wt/zeros;
table diag_nurse*diag_mentor/agree nocol nopercent norow ;
ods select  KappaStatistics  SymmetryTest;
run;






proc print data=orci_dg noobs label;
title 'Odds ratios, Diagnosis agree';
title2 'Univariate analysis';
var Factor timeperiod OddsRatioEst LowerCL UpperCL;
run;

ods graphics on;
title " Forest Plot: Diagnosis agree";
proc sgplot data=orci_dg noautolegend;
scatter x=oddsratioest y=Factor/ xerrorlower=lowercl
xerrorupper=uppercl
markerattrs=or
(symbol=DiamondFilled size=8);
scatter y=factor x=timeperiod/ markerchar=timeperiod x2axis ;
refline 1 / axis=x;
xaxis label="OR and 95% CI " min=0 max=3 offsetmin=.1;
yaxis label="Factor";
x2axis display=(noticks nolabel);
run;

proc print data=orci_tx noobs label;
title 'Odds ratios, Treatment agree';
title2 'Univariate analysis';
var Factor timeperiod OddsRatioEst LowerCL UpperCL;
run;

title2;
title " Forest Plot: Treatment agree";
proc sgplot data=orci_tx noautolegend;
scatter x=oddsratioest y=Factor/ xerrorlower=lowercl
xerrorupper=uppercl
markerattrs=or
(symbol=DiamondFilled size=8);
scatter y=factor x=timeperiod/ markerchar=timeperiod x2axis ;
refline 1 / axis=x;
xaxis label="OR and 95% CI " min=0 max=3 offsetmin=.1;
yaxis label="Factor";
x2axis display=(noticks nolabel);
run;

proc print data=Mult_dg noobs label;
title 'Odds ratios, Diagnosis agree';
title2 'Multivariate analysis';
var Factor timeperiod OddsRatioEst LowerCL UpperCL;
run;

ods graphics on;
title "Diagnosis agree, Multivariate analysis";
proc sgplot data=Mult_dg noautolegend;
scatter x=oddsratioest y=Factor/ xerrorlower=lowercl
xerrorupper=uppercl
markerattrs=or
(symbol=DiamondFilled size=8);

refline 1 / axis=x;
xaxis label="OR and 95% CI " min=0 max=3 offsetmin=.1;
yaxis label="Factor";
x2axis display=(noticks nolabel);
run;

proc print data=Mult_tx noobs label;
title 'Odds ratios, Treatment agree';
title2 'Multivariate analysis';
var Factor timeperiod OddsRatioEst LowerCL UpperCL;
run;

title2;
title "Treatment agree, Multivariate analysis";
proc sgplot data=Mult_tx noautolegend;
scatter x=oddsratioest y=Factor/ xerrorlower=lowercl
xerrorupper=uppercl
markerattrs=or
(symbol=DiamondFilled size=8);
refline 1 / axis=x;
xaxis label="OR and 95% CI " min=0 max=3 offsetmin=.1;
yaxis label="Factor";
x2axis display=(noticks nolabel);
run;

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

proc print data=orcitr_dg noobs label;
title 'Odds ratios, Diagnosis agree by health center';
title2 'Effect of taining';
var Health_Center timeperiod OddsRatioEst LowerCL UpperCL;
run;

proc sgplot data=orcitr_dg noautolegend;
title "Diagnosis agree, IMAI training ";
title2 "Post period, No training vs training ";
scatter x=oddsratioest y=Health_Center/ xerrorlower=lowercl
xerrorupper=uppercl
markerattrs=or
(symbol=DiamondFilled size=8);
refline 1 / axis=x;
xaxis label="OR and 95% CI " min=0 max=3 offsetmin=.1;
yaxis label="Health Center";
run;

proc print data=orcitr_tx noobs label;
title 'Odds ratios, Treatment agree by health center';
title2 'Effect of taining';
var Health_Center timeperiod OddsRatioEst LowerCL UpperCL;
run;

proc sgplot data=orcitr_tx noautolegend;
title "Treatment agree, IMAI training ";
title2 "Post period, No training  vs training ";

scatter x=oddsratioest y=Health_Center/ xerrorlower=lowercl
xerrorupper=uppercl
markerattrs=or
(symbol=DiamondFilled size=8);
refline 1 / axis=x;
xaxis label="OR and 95% CI " min=0 max=3 offsetmin=.1;
yaxis label="Health Center";
run;

proc print data=orcitr3_dg noobs label;
title 'Odds ratios, Diagnosis agree by NurseID';
title2 'Effect of taining';
var Nurseid OddsRatioEst LowerCL UpperCL;
run;

proc sgplot data=orcitr3_dg noautolegend;
title "Diagnosis agree, IMAI training ";
title2 "Post period, No training vs training ";
scatter x=oddsratioest y=nurseid/ xerrorlower=lowercl
xerrorupper=uppercl
markerattrs=or
(symbol=DiamondFilled size=8);
refline 1 / axis=x;
xaxis label="OR and 95% CI " min=0 max=3 ;
yaxis label="Nurse ID";
where OddsRatioEst>.02;
run;

proc print data=orcitr3_tx noobs label;
title 'Odds ratios, Treatment agree by nurseid';
title2 'Effect of taining';
var nurseid OddsRatioEst LowerCL UpperCL;
run;

proc sgplot data=orcitr3_tx noautolegend;
title "Treatment agree, IMAI training ";
title2 "Post period, No training  vs training ";
scatter x=oddsratioest y=nurseid/ xerrorlower=lowercl
xerrorupper=uppercl
markerattrs=or
(symbol=DiamondFilled size=8);
refline 1 / axis=x;
xaxis label="OR and 95% CI " min=0 max=3 ;
yaxis label="Nurse ID";
where OddsRatioEst>.02;
run;

ods rtf file='U:\Guo\SAS ProjectJuly2014\duration.doc' bodytitle;
proc logistic data=dt;
title 'Effect of frequency and durarion of intervention on Dianosis agreement';
title2;
class IMAI_train timeperiod;
model diag_agree =  Dur vistnm;
ods select   ParameterEstimates;
run;
proc logistic data=dt;
title 'Effect of ratio frequency and duration of intervention on Diagnosis agreement';
title2;
model diag_agree =  intDur_rat  ;
where timeperiod= 'post';
ods select   ParameterEstimates;
run;

proc logistic data=dt;
title 'Effect of frequency and duration of intervention on treatment agreement';
title2;
model tx_agree =  Dur vistnm;
ods select   ParameterEstimates;
run;

proc logistic data=dt;
title 'Effect of ratio frequency and durarion of intervention on treamentagreement';
title2;
model tx_agree =  intDur_rat ;
where timeperiod= 'post';
ods select   ParameterEstimates;
run;

ods rtf close;
%Macro byvar(resp);
proc sort data=test; by health_center;
proc logistic data=dt;
title 'Effect of frequency and durarion of intervention on Dianosis agreement';
title2;
class IMAI_train timeperiod;
model &resp =  Dur vistnm;
by health_center;
ods output   ParameterEstimates=&resp._dg;
run;

data &resp._dg;
length significance $8. variable $30;
set &resp._dg;
if ProbChiSq >0.05  then Significance='NS';
else if ProbChiSq =. then Significance='N/A';
else Significance='S';

if variable ='Dur' then do;
Variable= 'Duration';
end;

if variable ='vistnm' then do;
Variable= 'Frequency of Intervention';
end;

run;



proc sort data=test; by nurseid;
proc logistic data=dt;
title 'Effect of frequency and durarion of intervention on Dianosis agreement';
title2;
class IMAI_train timeperiod;
model &resp =  Dur vistnm;
by nurseid;
ods output   ParameterEstimates=&resp._dgn;
run;

data &resp._dgn;
length significance $8. variable $30;
set &resp._dgn;
if ProbChiSq >0.05  then Significance='NS';
else if ProbChiSq =. then Significance='N/A';
else Significance='S';
if variable ='Dur' then do;
Variable= 'Duration';
end;

if variable ='vistnm' then do;
Variable= 'Frequency of Intervention';
end;
run;

%mend byvar;
%Byvar(resp=diag_agree);
%Byvar(resp=tx_agree);

proc sql;
create table dt as
select nurseid,date_obs,  min(date_obs) as start_dt format=MMDDYY10., month(date_obs) as start_mth, max(date_obs) as end_dt format=MMDDYY10.,Cons_time,
max(date_obs)- min(date_obs) as MaxDur label='Max duration (days)', date_obs- min(date_obs) as Dur label='Duration (days)',
count(nurseid) as numvist, trainmonth, timeperiod, health_center, diag_agree, tx_agree, IMAI_train
from test
where nurseid in (select nurseid from test where IMAI_train='Yes') and timeperiod='post'
group by nurseid
order by nurseid, date_obs;
quit;

data dt;
set dt;
vistnm + 1;
by nurseid date_obs;
if first.nurseid then vistnm =1;
run;

proc sql;
create table dt as
select *, put(month(date_obs), monname3.) as month, year(date_obs) as year, put(date_obs, year2.) as yy, Cons_time,numvist/Dur as intDur_rat label="Numberof Interventions-Duration ratio"
from dt
order by nurseid, date_obs;
quit;

proc sql;
create table dtt as
select nurseid,date_obs, month(date_obs) as mnth, put(month(date_obs), monname3.) as month, year(date_obs) as year, put(date_obs, year2.) as yy,
Diag_agree, tx_agree, health_center
from test;
quit;

data dtt1;
set dtt;
if mnth = 1  then mth ='Jan'; 
else if mnth = 2 then mth ='Feb';
else if mnth = 3 then mth ='Mar';
else if mnth = 4 then mth ='Apr';
else if mnth = 6 then mth ='Jun';
else if mnth = 7 then mth ='Jul';
else if mnth = 8 then mth ='Aug';
else if mnth = 9 then mth ='Sep';
else if mnth = 10 then mth ='Oct';
else if mnth = 11 then mth ='Nov';

Date_new = compress( mth||'-'||yy);
run;

proc freq data=dtt1;
table date_new*diag_agree/nopercent nocol;
ods output crosstabfreqs=ct_dg (where=(_TYPE_='11'));
where date_new^='-.';
run;

proc freq data=dtt1;
table date_new*tx_agree/nopercent nocol;
ods output crosstabfreqs=ct_tx (where=(_TYPE_='11'));
where date_new^='-.';
run;

proc sort data=dtt1; by health_center; run;
proc freq data=dtt1;
table date_new*diag_agree/nopercent nocol;
ods output crosstabfreqs=byhc_dg (where=(_TYPE_='11'));
by health_center;
where date_new^='-.';
run;

proc freq data=dtt1;
table date_new*tx_agree/nopercent nocol;
ods output crosstabfreqs=byhc_tx (where=(_TYPE_='11'));
by health_center;
where date_new^='-.';
run;

%Macro Trp(Dat);
proc sort data=&Dat; by date_new;run;

proc transpose data=&Dat out=&Dat.1;
by  Date_new;
var Frequency ;
run;

proc transpose data=&Dat out=&Dat.2;
by  Date_new;
var RowPercent;
run;

Proc sql;
create table &Dat.3 as
select a.date_new, a.col1 as Agree, a.col2 as Disagree, b.Col1/100 as Pctagree format=percent8.0
  from &Dat.1 as a left join
  &Dat.2 as b
  on a.date_new = b.date_new;
  quit;

Proc sql;
create table &dat.4 as
select *, 
case 
when date_new ='Feb-11' then 1
when date_new ='Mar-11' then 2
when date_new ='Sep-11' then 3
when date_new ='Oct-11' then 4
when date_new ='Nov-11' then 5
when date_new ='Jan-12' then 6
when date_new ='Feb-12' then 7
when date_new ='Mar-12' then 8
when date_new ='Apr-12' then 9
when date_new ='Jun-12' then 10
when date_new ='Jul-12'  then 11
when date_new ='Aug-12'  then 12
when date_new ='Sep-12'  then 13
 end as dtn
 from &dat.3
order by dtn;
quit;

%mend trp;
%Macro Trp2(Dat);
proc sort data=&Dat; by health_center date_new;run;

proc transpose data=&Dat out=&Dat.1;
by health_center Date_new;
var Frequency ;
run;

proc transpose data=&Dat out=&Dat.2;
by health_center Date_new;
var RowPercent;
run;

Proc sql;
create table &Dat.3 as
select a.health_center, a.date_new, a.col1 as Agree, a.col2 as Disagree, b.Col1/100 as Pctagree format=percent8.0
  from &Dat.1 as a left join
  &Dat.2 as b
  on a.health_center= b.health_center and a.date_new = b.date_new;
  quit;

Proc sql;
create table &dat.4 as
select *, 
case 
 when date_new ='Feb-11' then 1
when date_new ='Mar-11' then 2
when date_new ='Sep-11' then 3
when date_new ='Oct-11' then 4
when date_new ='Nov-11' then 5
when date_new ='Jan-12' then 6
when date_new ='Feb-12' then 7
when date_new ='Mar-12' then 8
when date_new ='Apr-12' then 9
when date_new ='Jun-12' then 10
when date_new ='Jul-12'  then 11
when date_new ='Aug-12'  then 12
when date_new ='Sep-12'  then 13
 end as dtn
 from &dat.3
order by health_center , dtn;
quit;

%mend trp2;

%Trp(Dat = Ct_dg);
%Trp(Dat = Ct_tx);
%Trp2(Dat = Byhc_dg);
%Trp2(Dat = Byhc_tx);

proc report data=diag_agree_dg nowd;
title 'Model for Diagnosis agreement by health center';
column health_center variable DF  Estimate ProbChiSq significance;
Define health_center/ group 'Health Center' width=12;
define variable/ display 'Independent variable' width=130;
define ProbChiSq/ display 'Pvalue';
run;

proc report data=diag_agree_dgn nowd;
title 'Model for Diagnosis agreement by nurseid';
column nurseid variable DF  Estimate ProbChiSq significance;
Define nurseid/ group 'Health Center' width=15;
define variable/ display 'Independent variable' width=30;
define ProbChiSq/ display 'Pvalue';
run;

proc report data=tx_agree_dg nowd;
title 'Model for treatment agreement by health center';
column health_center variable DF  Estimate ProbChiSq significance;
Define health_center/ group 'Health Center' width=15;
define variable/ display 'Independent variable' width=30;
define ProbChiSq/ display 'Pvalue';
run;

proc report data=tx_agree_dgn nowd;
title 'Model for treatment agreement by nurseid';
column nurseid variable DF  Estimate ProbChiSq significance;
Define nurseid/ group 'Health Center' width=15;
define variable/ display 'Independent variable' width=30;
define ProbChiSq/ display 'Pvalue';
run;

options orientation = landscape;
goptions hsize=10  vsize=7;
ods rtf file='U:\Guo\SAS ProjectJuly2014\lineplots.doc' bodytitle;
proc print data=ct_dg4 noobs;
 title 'Percent Diagnosis Agree';
 Var date_new agree disagree Pctagree;
 label date_new = 'Month';
 run;

symbol i=join v=star c= blue;
axis1   label=none order= ( 'Feb-11' 'Mar-11' 'Sep-11' 'Oct-11' 'Nov-11' 'Jan-12' 'Feb-12' 'Mar-12' 'Apr-12' 'Jun-12' 'Jul-12' 'Aug-12' 'Sep-12');
axis2 label = (angle=90 'Percent agree') order =(0.3 to .9 by .1);
proc gplot data=ct_dg4;
title 'Percent Diagnosis Agree';
plot pctagree*date_new/ haxis=axis1 vaxis=axis2;
run;

proc print data=ct_tx4 noobs;
 title 'Percent Diagnosis Agree';
 Var date_new agree disagree Pctagree;
 label date_new = 'Month';

 run;
symbol i=join v=star c= blue;
axis1 label=none  order= ('Feb-11' 'Mar-11' 'Sep-11' 'Oct-11' 'Nov-11' 'Jan-12' 'Feb-12' 'Mar-12' 'Apr-12' 'Jun-12' 'Jul-12' 'Aug-12' 'Sep-12');
axis2 label = (angle=90 'Percent agree') order =(0.3 to .8 by .1);
proc gplot data=ct_tx4;
title 'Percent Treatment Agree';
plot pctagree*date_new/ haxis=axis1 vaxis=axis2;
run;

proc print data=Byhc_dg4 noobs;
 title 'Percent Diagnosis Agree';
 Var health_center date_new agree disagree Pctagree;
 label date_new = 'Month';
 run;

symbol1 i=join v=star ;
symbol2 i=join v=star ;
axis1 label=none order= ('Feb-11' 'Mar-11' 'Sep-11' 'Oct-11' 'Nov-11' 'Jan-12' 'Feb-12' 'Mar-12' 'Apr-12' 'Jun-12' 'Jul-12' 'Aug-12' 'Sep-12');
axis2 label = (angle=90 'Percent agree') order =(0.3 to 1 by .1);
proc gplot data=Byhc_dg4;
title 'Percent Diagnosis Agree by health center';
plot pctagree*date_new=health_center/ haxis=axis1 vaxis=axis2;
label health_center = '';
run;

proc print data=Byhc_dg4 noobs;
 title 'Percent Diagnosis Agree';
 Var health_center date_new agree disagree Pctagree;
 label date_new = 'Month';
 run;

symbol1 i=join v=star ;
symbol2 i=join v=star ;
axis1 label=none order= ('Feb-11' 'Mar-11' 'Sep-11' 'Oct-11' 'Nov-11' 'Jan-12' 'Feb-12' 'Mar-12' 'Apr-12' 'Jun-12' 'Jul-12' 'Aug-12' 'Sep-12');

axis2 label = (angle=90 'Percent agree') order =(0.3 to 1 by .1);
proc gplot data=Byhc_tx4;
title 'Percent Treatment Agree by health center';
plot pctagree*date_new=health_center/ haxis=axis1 vaxis=axis2;

label health_center = '';
run;

proc sort data=test;by Health_Center timeperiod;run;
ods output "Odds Ratios" = HCdg;
proc logistic data=test;
title 'Logistic model Diagnosis agree vs health center';
class Health_center;
model diag_agree (event='1')= health_center;
ods select  Type3;
run;

ods output "Odds Ratios" = HCtx;
proc logistic data=test;
title 'Logistic model Diagnosis agree vs health center';
class Health_center;
model tx_agree (event='1')= health_center;
ods select  Type3;
run;

ods rtf close;
/*
data orcitr3_dg;
set orcitr3_dg;
nurse =put(nurseid, best12.);
run;

data orcitr3_tx;
set orcitr3_tx;
nurse =put(nurseid, best12.);
run;

ods rtf file='gp.doc';
proc sgplot data=orcitr3_dg noautolegend;
title "Diagnosis agree, IMAI training ";
title2 "Post period, No training  vs training ";
scatter x=oddsratioest y=nurse/ xerrorlower=lowercl
xerrorupper=uppercl;
refline 1 / axis=x;
xaxis label="OR and 95% CI " min=0 max=3 offsetmin=.1;
yaxis label="Nurse";
x2axis display=(noticks nolabel);
run;

proc sgplot data=orcitr3_tx noautolegend;
title "Treatment agree, IMAI training ";
title2 "Post period, No training  vs training ";
scatter x=oddsratioest y=nurse/ xerrorlower=lowercl
xerrorupper=uppercl;
refline 1 / axis=x;
xaxis label="OR and 95% CI " min=0 max=3 offsetmin=.1;
yaxis label="Nurse";
x2axis display=(noticks nolabel);
run;

ods rtf close;

/*mixed effect model logistic regression*/
proc glimmix empirical data=test;
class nurseid trainmonth;
model diag_agree = trainmonth /solution dist=binary oddsratio;
random _residual_/subject=nurseid type=vc;
run;

proc glimmix empirical data=test;
class nurseid IMAI_train;
model diag_agree = IMAI_train /solution dist=binary oddsratio;
random _residual_/subject=nurseid type=vc;
run;

proc glimmix empirical data=test;
class nurseid level_educ;
model diag_agree = level_educ /solution dist=binary oddsratio;
random _residual_/subject=nurseid type=vc;
run;

proc glimmix empirical data=test;
class nurseid pt_sex;
model diag_agree = pt_sex/solution dist=binary oddsratio;
random _residual_/subject=nurseid type=vc;
run;

proc glimmix empirical data=test;
class nurseid  expgr;
model diag_agree =  expgr/solution dist=binary oddsratio;
random _residual_/subject=nurseid type=vc;
run;

proc glimmix empirical data=test;
class nurseid   health_center;
model diag_agree =  health_center/solution dist=binary oddsratio;
random _residual_/subject=nurseid type=vc;
run;

ods rtf file='aa.doc';
proc freq data=test;
table diag_agree * timeperiod;
run;

proc freq data=test;
table diag_agree * trainmonth;
run;

proc freq data=test;
table diag_agree * IMAI_train ;
run;

proc freq data=test;
table diag_agree * level_educ ;
run;

proc freq data=test;
table diag_agree *  pt_sex ;
run;

proc freq data=test;
table diag_agree * expgr ;
run;

proc freq data=test;
table diag_agree * health_center ;
run;

proc glimmix empirical data=test;
class nurseid pt_sex expgr level_educ trainmonth health_center;
model diag_agree = pt_sex  expgr level_educ trainmonth health_center/solution dist=binary oddsratio;
random _residual_/subject=nurseid type=vc;
run;
