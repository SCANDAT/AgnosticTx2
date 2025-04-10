*1. Set up local environment for #pannan2;
%let localpath=%substr(%sysget(SAS_EXECFILEPATH),1,%eval(%length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILENAME))-1));;
%inc "&localpath\Local setup pannan2.sas";
%inc "&localpath\Lookup macros.sas";

%let nosessions=25;
%let tw=24;
%let workpath = %sysfunc(pathname(WORK));
%put &workpath;

*2. Preparations;
*Clear output;
dm 'odsresults; clear';
dm 'log; clear';
filename output3 "&localpath\SAS Outputs\Run initial mixed effects models in parallel, &tw hours.pdf";
ods pdf file=output3;

proc freq data=agtx.finaldata_long&tw;
tables label predictor;
run;
*3. Fetch data;
proc sort data=agtx.finaldata_long&tw;
by label predictor;
run;
data agtx.finaldata_long&tw;
set agtx.finaldata_long&tw;
by label predictor;
retain rannr;
if first.predictor then rannr=ranuni(4);
run;
proc sort data=agtx.finaldata_long&tw;
by rannr label predictor;
run;

/*
proc means data=agtx.finaldata_long&tw min p1 q1 median mean q3 p99;
var deltavalue;
where label="EVF";
run;
proc freq data=local;
by label;
where predictor=: "foreign";
tables predictor predictor*predictorvalue;
run;
*/
*4. Create scoring dataset for plotresults;
proc summary data=agtx.finaldata_long&tw;
where label="HB" ;
by label predictor notsorted;
var predictorvalue recipientsex recipientage time_before time_after ;
output out=sd
	min(predictorvalue)=pv_min max(predictorvalue)=pv_max mode(predictorvalue)=pv_mode median(predictorvalue)=pv_median
	median(recipientage)=recipientage
	median(meandonorhb)=meandonorhb
	median(time_before)=time_before
	median(time_after)=time_after
	mode(recipientsex)=recipientsex
	;
run;
data scoredata(drop=label _type_--pv_median);
set sd;

recipientsex=2;
recipientage=round(recipientage,0.1);
time_before=3;*round(time_before,0.1);
time_after=3;*round(time_after,0.1);
if predictor="donorparity" then do;
	do predictorvalue=1 to 2;
	    output;
	    end;
	end;
if predictor="meandonationtime" then do;
	do predictorvalue=floor(pv_min) to ceil(pv_max) by 0.1;
	    output;
	    end;
	end; 
if predictor="meandonorage" then do;
	do predictorvalue=floor(pv_min) to ceil(pv_max) by 1;
	    output;
	    end;
	end; 
if predictor="meandonorhb" then do;
	do predictorvalue=floor(pv_min) to ceil(pv_max) by 1;
	    output;
	    end;
	end; 
if predictor="meandonorsex" then do;
	do predictorvalue=1 to 2;
	    output;
	    end;
	end;
if predictor="meanstoragetime" then do;
	do predictorvalue=floor(pv_min) to ceil(pv_max) by 0.5;
	    output;
	    end;
	end; 
if predictor="meanweekday" then do;
	do predictorvalue=pv_min to pv_max by 1;
	    output;
	    end;
	end; 
if predictor="numdoncat" then do;
	do predictorvalue=0,1,5,10,20;
	    output;
	    end;
	end; 
if predictor="timesincecat" then do;
	do predictorvalue=0,180,365,999;
	    output;
	    end;
	end; 
if predictor="foreigndonor" then do;
	do predictorvalue=0,1;
	    output;
	    end;
	end; 
run;
data agtx.scoredata24;
set scoredata;
run;
/*
proc freq data=scoredata;
where predictor=: "foreign";
tables predictor predictor*predictorvalue;
run;
*/
*5. Count runs;
proc sql;
select count(*) into: noruns from (select distinct label, predictor from agtx.finaldata_long&tw);
quit;

*6. Define parallel macro;
options nosymbolgen mprint=0;
options sascmd="sas";
%macro parallel(sessions,runs,tw=24);

/* Current datetime */
%let _start_dt = %sysfunc(datetime());

/*spread out runs over sessions evenly*/
%let persession=%sysfunc(floor(&runs/&sessions));
%let lastsession=%sysfunc(mod(&runs,&sessions));

%PUT WARNING: Starting &sessions sessions with &runs  runs. %sysevalf(&sessions-1) session(s) with &persession run(s) and 1 session with %sysevalf(&persession+&lastsession) run(s).; 

/*Do loop to create multiple sessions*/
%do i=1 %to &sessions;
%if &i=&sessions %then %let runto=%sysevalf((&i*&persession)+&lastsession); %else %let runto=%sysevalf(&i*&persession);
%if &i=1 %then %let startfrom=1; %else %let startfrom=%sysevalf((&i-1)*&persession+1);
%put NOTE: Session &i starting at run &startfrom to &runto;

/*create sessions*/

signon task&i connectwait=NO;
%syslput runto=&runto / remote=task&i;
%syslput startfrom=&startfrom / remote=task&i;
%syslput current=&i / remote=task&i;
%syslput workpath=&workpath / remote=task&i;
%syslput localpath=&localpath / remote=task&i;
%syslput tw=&tw / remote=task&i;

rsubmit task&i wait=no;

/*Setup paths*/
libname MAINWORK "&workpath";
%inc "&localpath\Local setup pannan2.sas";

/*run actual macro from sas file*/
%inc "&localpath\Run as serial mixed models using SAS HPMIXED, parallelized.sas";
%runallmixed(sf=&startfrom, rt=&runto, timewindow=&tw);
*options notes MSGLEVEL=N source;
data MAINWORK.fixedeffects_&current;
set solf;
run;
data MAINWORK.convergence_&current;
set cs;
run;
data MAINWORK.type3tests_&current;
set type3;
run;
data MAINWORK.plotdata_&current;
set plotdata;
run;
endrsubmit;
%end;

waitfor _all_;
signoff _all_;

/*Output total run time*/
data _null_;
   dur = datetime() - &_start_dt;
   put 30*'-' / ' TOTAL DURATION:' dur time13.2 / 30*'-';
run;
%mend;

*7. Execute parallel macro and collect results;
%let tw2=&tw;
%parallel(sessions=&nosessions,runs=&noruns, tw=&tw2);


data agtxoutp.univariate&tw._plotdata;
set plotdata_1-plotdata_&nosessions;
run;
data agtxoutp.univariate&tw._modelfit;
set convergence_1-convergence_&nosessions;
run;
data agtxoutp.univariate&tw._parmests;
set fixedeffects_1-fixedeffects_&nosessions;
run;
data agtxoutp.univariate&tw._type3;
set type3tests_1-type3tests_&nosessions;
run;

*Summarize fit results;
proc freq data=agtxoutp.Univariate&tw._modelfit;
tables reason adjusted*reason;
run;

*8. Perform FDR adjustment;
*Perform FDR adjustment;
*5. Count runs;
proc sql;
select count(*)  from (select distinct label, predictor from agtxoutp.univariate&tw._type3 where effect like 'pred%' and probf lt 0.05 and adjusted=0);
quit;
proc sort data=agtxoutp.univariate&tw._type3 out=crude_pvals;
where effect =: 'pred';
by adjusted probf;
format probf probchisq;
run;
/*
data x;
set crude_pvals;
where label="EVF";
run;
*/
data crude_pvals2;
set crude_pvals;
idnr=_n_;
format probF e14.;
run;

proc multtest inpvalues(probF)=crude_pvals2 fdr out=multtest plots=all;
by adjusted;
id idnr;
run;

proc sql;
create table agtxoutp.univariate&tw._fdr(drop=idnr) as
select
  b.*,
  a.fdr_p
from multtest a, crude_pvals2 b
where a.idnr=b.idnr;
quit;

*Finally export as CSV-files for use in plot;
data _null_;
file "K:\SCANDAT\User\Gustaf\AgTxFigure1\src\data\plotdata&tw..csv" delimiter=',' DSD DROPOVER lrecl=32767;
if _n_ = 1 then        /* write column names or labels */
do;
 put
    "label"
 ','
    "predictor"
 ','
    "predictorvalue"
 ','
    "predicted"
 ','
    "lower"
 ','
    "upper"
 ','
    "adjusted"
 ;
end;
set  AGTXOUTP.Univariate&tw._plotdata   end=EFIEOD;
 format label $13. ;
 format predictor $200. ;
 format predictorvalue best12. ;
 format predicted best12. ;
 format lower best12. ;
 format upper best12. ;
 format adjusted best12. ;
do;
 EFIOUT + 1;
 put label $ @;
 put predictor $ @;
 put predictorvalue @;
 put predicted @;
 put lower @;
 put upper @;
 put adjusted ;
 ;
end;
run;
data _null_;
file "K:\SCANDAT\User\Gustaf\AgTxFigure1\src\data\fdr&tw..csv" delimiter=',' DSD DROPOVER lrecl=32767;
if _n_ = 1 then        /* write column names or labels */
do;
 put
    "predictor"
 ','
    "label"
 ','
    "Effect"
 ','
    "NumDF"
 ','
    "DenDF"
 ','
    "ChiSq"
 ','
    "FValue"
 ','
    "ProbChiSq"
 ','
    "ProbF"
 ','
    "adjusted"
 ','
    "fdr_p"
 ;
end;
set  AGTXOUTP.Univariate&tw._fdr   end=EFIEOD;
 format predictor $200. ;
 format label $13. ;
 format Effect $14. ;
 format NumDF 4. ;
 format DenDF best5. ;
 format ChiSq 7.2 ;
 format FValue 7.2 ;
 format ProbChiSq best12. ;
 format ProbF e14. ;
 format adjusted best12. ;
 format fdr_p best12. ;
do;
 EFIOUT + 1;
 put predictor $ @;
 put label $ @;
 put Effect $ @;
 put NumDF @;
 put DenDF @;
 put ChiSq @;
 put FValue @;
 put ProbChiSq @;
 put ProbF @;
 put adjusted @;
 put fdr_p ;
 ;
end;
run;

proc sql;
create table obs as
select
 predictor, label,
 count(*) as observations
from agtx.finaldata_long&tw
group by predictor, label;
quit;
proc sql;
create table fdr_obs as
select a.label, a.predictor, a.observations, b.ProbF, b.fdr_p
from AGTXOUTP.Univariate&tw._fdr b, obs a
where a.predictor=b.predictor and a.label=b.label and b.adjusted=0
order by b.fdr_p, b.ProbF;
quit;
data agtxoutp.Supptable3;
set fdr_obs;
%lookuparrays;
    new_label = "Unknown key                            ";
    new_predictor = "Unknown key                           ";

    /* Lookup for label */
    do i = 1 to 58;
        if label = labels_keys[i] then do;
            new_label = labels_values[i];
            leave;
        end;
    end;

    /* Lookup for predictor */
    do i = 1 to 11;
        if predictor = predictors_keys[i] then do;
            new_predictor = predictors_values[i];
            leave;
        end;
    end;

    drop i;
run;
data _null_;
file "&localpath\Output\Supp table 3.csv" delimiter=',' DSD DROPOVER lrecl=32767;
if _n_ = 1 then        /* write column names or labels */
do;
 put
    "Label"
 ','
    "Predictor"
 ','
    "Number of observations"
 ','
    "Crude p-value"
 ','
    "FDR adjusted p-value"
 ;
end;
set  agtxoutp.Supptable3   end=EFIEOD;
   format new_label $50. ;
   format new_predictor $200. ;
 format observations best5. ;
 format ProbF e14. ;
 format fdr_p e14. ;
do;
 EFIOUT + 1;
 put new_label $ @;
 put new_predictor $ @;
 put observations @;
 put ProbF @;
 put fdr_p ;
 ;
end;
run;

dm 'log; print file="&localpath\Logs\Run initial mixed effects models in parallel, &tw hours.log" replace; ';
ods pdf close;
ods html;


