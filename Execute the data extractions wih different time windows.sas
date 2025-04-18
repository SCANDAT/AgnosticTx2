*1. Set up local environment for #pannan2;
%let localpath=%substr(%sysget(SAS_EXECFILEPATH),1,%eval(%length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILENAME))-1));;
%inc "&localpath\Local setup pannan2.sas";

*2. Preparations;
*Clear output;
dm 'odsresults; clear';
dm 'log; clear';
filename output1 "&localpath\SAS Outputs\Extract data for Swedish, main analyses.pdf";
ods pdf file=output1;
*3. Definitions;
%let startdate='01jan2006'd;
%let stopdate='01jul2018'd;
*4. Execute code for 24 and 6 hour windows;
%let hours=24;
%let timewindow=%sysevalf(&hours*3600);
%put Now assessing with &hours hours pre-post-transfusion windows;
title "Now assessing with &hours hours pre-post-transfusion windows";
%inc "&localpath\Extract data for Swedish main analyses.sas";
proc sort data=agtx.finaldata24;
by idnr firsttransdt label ;
run;
data templong24(keep=label idnr time_before time_after recipientage recipientsex units predictor predictorvalue deltavalue bloodgroup donorid meandonorhb encounter);
set agtx.finaldata24;
by idnr firsttransdt label ;
retain encounter;
where units=1 and extremevalue=0;
if first.idnr then encounter=0;
encounter+(first.firsttransdt);
array pred[10] meandonorhb meandonorsex meandonorage numdoncat meanstoragetime timesincecat meanweekday meandonationtime donorparity foreigndonor;
do _i=1 to 10;
	if pred[_i] ne . then do;
		predictor=vname(pred[_i]);
		predictorvalue=pred[_i];
		output;
		end;
	end;
run;
/*
proc freq data=templong24;
tables predictorvalue; where predictor='idbloodgroupcat';
run;
proc freq data=templong24;
tables predictorvalue; where predictor='foreigndonor';
run;
*/
data agtx.finaldata_long24;
set templong24;
*Cleanup for analysis purposes;
if predictor='meandonorhb' and (predictorvalue lt 100 or predictorvalue gt 190) then delete;
if predictor='meandonorsex' and (predictorvalue lt 1 or predictorvalue gt 2) then delete;
if predictor='meandonorage' and (predictorvalue lt 18 or predictorvalue gt 80) then delete;
if predictor='meanstoragetime' and (predictorvalue lt 0 or predictorvalue gt 42) then delete;
if predictor='meanweekday' and predictorvalue=1 then delete;
if predictor='meandonationtime' and (predictorvalue lt 6 or predictorvalue gt 20) then delete;
if predictor='donorparity' and (predictorvalue =9) then delete;
if predictor='meanweekday' then predictorvalue=predictorvalue-1;
if label="SO2" then delete;
run;
/*
proc freq data=agtx.finaldata_long24;
tables label*predictor /norow nocol nopercent;
run;
*/
%let hours=6;
%let timewindow=%sysevalf(&hours*3600);
%put Now assessing with &hours hours pre-post-transfusion windows;
title "Now assessing with &hours hours pre-post-transfusion windows";
%inc "&localpath\Extract data for Swedish main analyses.sas";
proc sort data=agtx.finaldata6;
by idnr firsttransdt label ;
run;
data templong6(keep=label idnr time_before time_after recipientage recipientsex units predictor predictorvalue deltavalue bloodgroup donorid meandonorhb encounter);
set agtx.finaldata6;
where units=1 and extremevalue=0;
by idnr firsttransdt label ;
retain encounter;
if first.idnr then encounter=0;
array pred[10] meandonorhb meandonorsex meandonorage numdoncat meanstoragetime timesincecat meanweekday meandonationtime donorparity foreigndonor;
do _i=1 to 10;
	if pred[_i] ne . then do;
		predictor=vname(pred[_i]);
		predictorvalue=pred[_i];
		output;
		end;
	end;
run;
data agtx.finaldata_long6;
set templong6;
*Cleanup for analysis purposes;
if predictor='meandonorhb' and (predictorvalue lt 100 or predictorvalue gt 190) then delete;
if predictor='meandonorsex' and (predictorvalue lt 1 or predictorvalue gt 2) then delete;
if predictor='meandonorage' and (predictorvalue lt 18 or predictorvalue gt 80) then delete;
if predictor='meanstoragetime' and (predictorvalue lt 0 or predictorvalue gt 42) then delete;
if predictor='meanweekday' and predictorvalue=1 then delete;
if predictor='meandonationtime' and (predictorvalue lt 6 or predictorvalue gt 20) then delete;
if predictor='meanweekday' then predictorvalue=predictorvalue-1;
if label="SO2" then delete;
run;
dm 'log; print file="&localpath\Logs\Extract data for Swedish, main analyses.log" replace; ';
ods pdf close;
ods listing;

