%let localpath=%substr(%sysget(SAS_EXECFILEPATH),1,%eval(%length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILENAME))-1));;
%inc "&localpath\Local setup pannan2.sas";
%inc "&localpath\Lookup macros.sas";
options minoperator mindelimiter=',';
proc format;
value agecat
	low-4.999="lt 5"
	5-18="5-18"
	18-29.9999="19-29"
	30-49.9999="30-49"
	50-64.9999="50-64"
	65-79.9999="65-79"
	80-89.9999="80-89"
	90-high="90+"
	;
value enccnt 
	1="1"
	2="2"
	3-high="3+"
	;
value txcnt
	1="1"
	2="2"
	3-5="3-5"
	6-high="6+"
	;
value labcnt
	1-5="1-5"
	6-10="6-10"
	11-20="11-20"
	21-high="21+"
	;
run;
proc sort data=agtx.Finaldata24;
by idnr firsttransdt;
run;
proc sort data=agtx.Finaldata_reds24;
by idnr firsttransdt;
run;
data scandatcohort;
set agtx.Finaldata24;
where units lt 3 and recipientage ne . and recipientsex in (1,2);
by idnr;
if first.idnr;
run;
data redscohort;
set agtx.Finaldata_reds24;
where units lt 3 and recipientage ne . and recipientsex in (1,2);
by idnr;
if first.idnr;
run;
data bothcohorts;
set scandatcohort(in=s rename=(idnr=ids donorid=dids)) redscohort;
if s then cohort="SCANDAT";
else cohort="REDS";
if s then do; 
	idnr=input(put(ids,13.),$13.);
	donorid=input(put(dids,13.),$13.);
	end;
run;
ods listing;

proc freq data=bothcohorts;
by cohort notsorted;
format recipientage agecat.;
tables recipientsex recipientage;
run;
proc means data=bothcohorts median q1 q3;
by cohort notsorted;
var recipientage;
run;

data sc2;
set agtx.Finaldata24;
where units lt 3 and recipientage ne . and recipientsex in (1,2);
by idnr firsttransdt;
if first.firsttransdt;
run;
data rd2;
set agtx.Finaldata_reds24;
where units lt 3 and recipientage ne . and recipientsex in (1,2);
by idnr firsttransdt;
if first.firsttransdt;
run;
data bc2;
set sc2(in=s rename=(idnr=ids donorid=dids)) rd2;
if s then cohort="SCANDAT";
else cohort="REDS";
if s then do; 
	idnr=input(put(ids,13.),$13.);
	donorid=input(put(dids,13.),$13.);
	end;
run;
proc sql;
create table bc3 as
select cohort,
	idnr,
	count(*) as encounters,
	sum(units) as transfusions,
	sum(units=1) as singleunit,
	sum(units=2) as doubleunits
from bc2
group by cohort, idnr;
quit;
proc means data=bc3 median q1 q3 sum;
by cohort notsorted;
var encounters transfusions singleunit doubleunits;
run;
proc freq data=bc3 ;
by cohort notsorted;
format encounters enccnt. transfusions txcnt.;
tables encounters transfusions ;
run;

data bc4;
set agtx.Finaldata24(in=s rename=(idnr=ids donorid=dids)) agtx.Finaldata_reds24;
where units lt 3 and recipientage ne . and recipientsex in (1,2);
if s then cohort="SCANDAT";
else cohort="REDS";
if s then do; 
	idnr=input(put(ids,13.),$13.);
	donorid=input(put(dids,13.),$13.);
	end;
run;
proc sql;
create table bc5 as
select 
	cohort,
	idnr,
	count(distinct firsttransdt) as encounters,
	count(distinct label) as labtests
from bc4
group by cohort, idnr;
quit;
proc freq data=bc5 ;
by cohort notsorted;
format labtests labcnt.;
tables labtests ;
run;
proc means data=bc5 median q1 q3 sum;
by cohort notsorted;
var labtests;
run;
