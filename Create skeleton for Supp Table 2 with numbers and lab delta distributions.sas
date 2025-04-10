%let localpath=%substr(%sysget(SAS_EXECFILEPATH),1,%eval(%length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILENAME))-1));;
%inc "&localpath\Local setup pannan2.sas";
%inc "&localpath\Lookup macros.sas";

options minoperator mindelimiter=',';
dm 'odsresults; clear';
dm 'log; clear';

filename output6 "&localpath\SAS Outputs\Create skeleton for Supp Table 2 with numbers and lab delta distributions.pdf";
ods pdf file=output6;

data tempdata;
set agtx.finaldata24;
length longlabel $ 50 category $ 50;
where units=1;
if _N_ = 1 then do;
        declare hash categories(dataset: 'Labelcategoryhash');
        categories.defineKey('label');
        categories.defineData('category');
        categories.defineDone();
    end;
    category="L. Others";
    rc = categories.find(); 
	drop rc;
%lookuparrays;
    /* Lookup for label */
    do i = 1 to 58;
        if label = labels_keys[i] then do;
            longlabel = labels_values[i];
            leave;
        end;
    end;

    drop i;
	if label="TPK" then longlabel='Platelet count';
	if label="TRI" then longlabel='Triglycerides';
run;
proc sort data=tempdata;
by category longlabel;
run;
title "Single-unit, full distribution width";
proc freq data=tempdata;
by category;
tables longlabel;
run;
proc univariate data=tempdata;
by category longlabel;
var deltavalue;
histogram deltavalue;
run;
title "Single-unit, extremevalues removed";
proc freq data=tempdata;
where extremevalue=0;
by category;
tables longlabel;
run;
proc univariate data=tempdata;
where extremevalue=0;
by category longlabel;
var deltavalue;
histogram deltavalue;
run;
title ;
proc summary data=tempdata nway;
by category;
where extremevalue=0;
class longlabel;
var deltavalue;
output out=labdistributions(drop=_type_ _Freq_) n=nobs mean=meandelta median=mediandelta q1=q1delta q3=q3delta;
run;
proc sql;
create table ldpers as
select
	category, longlabel, count(*) as persons
from (select distinct idnr, longlabel, category from tempdata where extremevalue=0)
group by category, longlabel;
quit;
*Then REDS;
data tempdatareds;
set agtx.finaldata_reds24;
length longlabel $ 50 category $ 50;
where units=1;
if _N_ = 1 then do;
        declare hash categories(dataset: 'Labelcategoryhash');
        categories.defineKey('label');
        categories.defineData('category');
        categories.defineDone();
    end;
    category="L. Others";
    rc = categories.find(); 
	drop rc;
%lookuparrays;
    /* Lookup for label */
    do i = 1 to 58;
        if label = labels_keys[i] then do;
            longlabel = labels_values[i];
            leave;
        end;
    end;

    drop i;
	if label="TPK" then longlabel='Platelet count';
	if label="TRI" then longlabel='Triglycerides';
run;
proc sort data=tempdatareds;
by category longlabel;
run;
proc summary data=tempdatareds nway;
by category;
where extremevalue=0;
class longlabel;
var deltavalue;
output out=labdistributionsreds(drop=_type_ _Freq_) n=nobs mean=meandelta_reds median=mediandelta_reds q1=q1delta_reds q3=q3delta_reds;
run;
proc sql;
create table ldpersreds as
select
	category, longlabel, count(*) as persons_reds
from (select distinct idnr, longlabel, category from tempdatareds where extremevalue=0)
group by category, longlabel;
quit;

data ld2;
merge ldpers labdistributions ldpersreds labdistributionsreds;
by category longlabel;

run;
proc print data=ld2;
run;
ods pdf close;
dm 'log; print file="&localpath\Logs\Investigate lab delta distributions in SCANDAT single-unit.log" replace; ';
