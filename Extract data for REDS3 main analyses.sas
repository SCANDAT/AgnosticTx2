%let localpath=%substr(%sysget(SAS_EXECFILEPATH),1,%eval(%length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILENAME))-1));
%inc "&localpath\Local setup pannan2.sas";

%let hours=24;
%let timewindow=%sysevalf(&hours*3600);

proc sql;
create table dons3 as
select
  a.donorid,
  a.din_random,
  a.sex,
  a.age,
  a.hbvalue,
  a.dondate,
  a.height,
  a.weight,
  a.parity,
  a.dontype,
  a.donproc,
  a.bornusa,
  a.abo_rh,
  max(b.dondate) as mostrecentdonation format=yymmdd10.,
  sum(b.donorid ne "") as numdonations
from cleanr3.donation a left join cleanr3.donation b
on a.donorid=b.donorid and a.donorid ne "" and b.dontype='H' and b.donproc in ("WB", "R1", "R2", "P3", "P4") and a.dondate gt b.dondate ge a.dondate-%sysevalf(5*365.24)
where a.dontype="H" and a.donproc in ("WB", "R1", "R2", "P3", "P4")
group by
  a.donorid,
  a.din_random,
  a.sex,
  a.age,
  a.hbvalue,
  a.dondate,
  a.height,
  a.weight,
  a.parity,
  a.dontype,
  a.donproc,
  a.bornusa,
  a.abo_rh;
  quit;
proc freq data=cleanr3.donation;
tables numdonations parity;
run;
proc univariate data=cleanr3.donation;
var mostrecentdonation;
histogram mostrecentdonation;
run;

*Extract SCANDAT data for agnostic study of donor/donation/component parameters and recipient laboratory changes;


/*
3. Extract data
3.1. Fetch transfusions
*/
data agnostic;
set cleanr3.transfusion;
where producttype="RBC";
keep idnr din_random transdt productcode divisioncode transdate transdt daysdonationtoissue ;*DINPOOLEDLINKFLAG;
run;
/*
proc freq data=agnostic;
tables DINPOOLEDLINKFLAG;
run;
*/
/*
3.2. Add persons data
*/
proc sql;
create table agnostic_2 as
select
	a.*,
	b.age,
	b.sex,
	b.bloodgroup
from agnostic as a inner join cleanr3.persons as b
on a.idnr=b.idnr;
quit;

proc sql;
select count(*) from (select distinct idnr from agnostic_2);
quit;

*3.3. Add donation data;

		proc sort data=dons3 out=donation;
		by din_random dondate;
		run;
		data donation_nodup;
		set donation;
		by din_random;
		if first.din_random and last.din_random;
		run;



proc sql;
create table agnostic_3 as
select
	a.*,
	b.donorid,
	b.sex as donorsex,
	b.age as donorage,
	b.dondate,
	b.hbvalue as donorhb,
	b.abo_rh as donorbg,
	b.bornusa,
	b.parity,
	b.mostrecentdonation,
	b.numdonations,
	b.donproc
from agnostic_2 as a left join donation_nodup as b
on a.din_random=b.din_random;
quit;
proc sort data=cleanr3.imported;
by din_random;
run;

data impnodup;
set cleanr3.imported;
by din_random;
if first.din_random and last.din_random and din_random ne "";
run;
proc sql;
create table agnostic_3b(rename=(DAYSDONATIONTOISSUE=storagetime age=recipientage sex=recipientsex)) as
select
	coalesce(a.donorid,b.donorid) as donorid,
	coalesce(a.donorsex,a.sex) as donorsex,
	coalesce(a.donorage,a.age) as donorage,
	coalesce(a.donorhb,b.hbvalue) as donorhb,
	coalesce(a.donorbg,b.abo_rh) as donorbloodgroup,
	coalesce(a.bornusa,b.bornusa) as donorbirthorigin,
	coalesce(a.donproc,b.donproc) as donproc,
	a.*
from agnostic_3 as a left join impnodup as b
on a.donorid="" and a.din_random=b.din_random;
quit;
proc freq data=agnostic_3b;
tables donproc;
run;

proc sql;
select count(*) from (select distinct idnr from agnostic_3);
quit;
/*
*3.4. Add donor data;
proc sql;
create table agnostic_4 as
select
	a.*,
	b.sex as donorsex,
	b.birthdate as donorbirthdate,
	b.bloodgroup as donorbloodgroup,
	input(put(b.birthorigin,$2.),2.) as donorbirthorigin
from agnostic_3 as a left join sc3.persons as b
on a.donorid=b.idnr and b.error=0;
quit;
proc sql;
select count(*) from (select distinct idnr from agnostic_4);
quit;
*3.4.a. fetch birth data;
proc sql;
create table births_mfr as
select 
	idnr,
	min(birthdate) as birthdate1
from sc3.mgr
group by
    idnr;
quit;

proc sql;
create table births_multigeneration as
select
    idnr,
    min(birthdate) as birthdate1
from
    (select 
    a.idnr2 as idnr,
    a.idnr_index as child,
    b.birthdate
from sc3.family a left join sc3.persons b on a.idnr_index=b.idnr where a.relationship="Mor")
group by idnr
;
run;
proc sql;
create table births as 
select 
    idnr, 
    min(birthdate1) as birthdate1 format=yymmdd10.
from
    (select * from births_mfr union select * from births_multigeneration)
group by idnr;
quit;
*3.4.b. Add birth data;
proc sql;
create table agnostic_5 as
select distinct 
	a.*,
    CASE WHEN datepart(a.dondt) GE coalesce(c.birthdate1,'01JAN2100'd) then 1 else 0 end as donorparity
from agnostic_4 a left join births c 
	on a.donorid=c.idnr and a.donorsex=2;
quit;
*/
*3.5. Add donation data to compute number of donations and time since most recent donation;
/*
proc sql;
create table agnostic_6 as
select a.donationid, a.origin, a.poolnum, a.transdt, a.idnr, a.birthdate, a.deathdate, a.migdate, a.sex, a.bloodgroup, a.donorid, a.dondt, a.donorhb, a.donorsex, a.donorbirthdate, a.donorbloodgroup, a.donorbirthorigin, a.donorparity,
	max(b.dondt) as mostrecentdonation format=datetime.,
	sum(b.idnr ne .) as numdonations
from agnostic_5 a left join sc3.donation b
on a.donorid=b.idnr and a.donorid ne . and b.xdontype='1' and b.xdondesc='N' and a.dondt gt b.dondt ge a.dondt-%sysevalf(5*365.24*24*3600)
group by
	a.donationid, a.origin, a.poolnum, a.transdt, a.idnr, a.birthdate, a.deathdate, a.migdate, a.sex, a.bloodgroup, a.donorid, a.dondt, a.donorhb, a.donorsex, a.donorbirthdate, a.donorbloodgroup, a.donorbirthorigin, a.donorparity;
quit;
*/
/*
proc sql;
select count(*) from (select distinct idnr from agnostic_6);
quit;
4. Data manipulations
4.1. Compute storage time, sime since donation, donor age, and recipient age
*/
data agnostic_7;
set agnostic_3b;
	time_since_donation=(dondate-mostrecentdonation);
	if compress(bloodgroup,'+-')='' OR compress(donorbloodgroup,'+-')='' then identicalbg=9;
	else identicalbg=(compress(bloodgroup,'+-')=compress(donorbloodgroup,'+-'));

	if donorbirthorigin='' then donorbirthorigin='99';
	if donorsex=. then donorparity=9;
	else donorparity=coalesce(parity,9);

run;
proc freq data=agnostic_7;
tables  donorbirthorigin donorparity donproc;
run;

/*
proc sql;
select count(*) from (select distinct idnr from agnostic_7);
quit;
*/
*4.2. Remove erroneous/implausible observations;
data agnostic_8;
set agnostic_7;

if donorhb < 60 or donorhb > 200 then donorhb=.;
if not donorsex in (1,2) then donorsex=9;
if donorage le 0 or donorage ge 80 then donorage=.;
if recipientage le 0 or recipientage ge 100 then recipientage=.;
if storagetime le 0 or storagetime ge 100 then storagetime=.;

run;
*4.3. Examine predictors;
data predictorvariables;
set agnostic_8;
keep din_random donorage donorhb donorsex donorbloodgroup numdonations storagetime time_since_donation identicalbg donorbirthorigin donorparity donproc;
run;

*4.3.1. Summaries;
*DESCRIPTIVE SUMMARY CATEGORICAL;
proc freq data=predictorvariables;
where donorsex in (1,2);
tables donorbloodgroup numdonations identicalbg ;
run;
*DESCRIPTIVE SUMMARY CONTINUOUS;
proc univariate data=predictorvariables;
where donorsex in (1,2);
var donorage donorhb numdonations storagetime time_since_donation;
run;

/*
5. Fetch and incorporate lab data
5.1. Get lab data
*/
%macro check_exists(dataset);
	%if %sysfunc(exist(&dataset)) %then %do;
		%put &dataset exists;
		%end;
	%else %do;
		proc sql;
			create table multilab as
			select
			    label,
			    idnr,
			    converted_value as value,
			    labdt
			from cleanr3.lab 
			where idnr in (select distinct idnr from agnostic_8);
		quit;
		data multilab;
		set multilab;
		if label="EVF" then delete;
		run;
		%end;
%mend check_exists;
%check_exists(multilab);

/*
proc freq data=multilab;
tables label;
run;
*/
*CLEAN LABVALUES;

proc sort data=multilab out= cleanmultilab nodupkey;
by label idnr value labdt;
run;


/*
proc freq data=cleanmultilab;
tables label;
run;

*/

*5.2. Add to cohort;


proc sort data=cleanmultilab;
by label idnr labdt;
run;



proc sql;
create table transfusion_lab1 as
select
    a.label,
	a.idnr,
	a.labdt as sampledtbefore,
	a.value as valuebefore,
	b.transdt,
	b.din_random
from cleanmultilab a inner join agnostic_8 b
  on a.idnr=b.idnr and b.transdt - %sysevalf(&timewindow) lt a.labdt lt b.transdt
order by a.label, a.idnr, b.din_random, a.labdt;
quit;
/*
proc freq data=transfusion_lab1;
tables label;
run;

*/
data transfusion_lab1b;
set transfusion_lab1;
by label idnr din_random sampledtbefore;
if last.din_random;
run;




proc sql;
create table transfusion_lab1c as
select
    a.label,
	a.idnr,
	a.sampledtbefore,
	a.valuebefore,
	a.transdt,
	a.din_random,
	b.labdt as sampledtafter,
	b.value as valueafter
from transfusion_lab1b a inner join cleanmultilab b
  on a.label=b.label and a.idnr=b.idnr and a.transdt + %sysevalf(&timewindow) gt b.labdt gt a.transdt
order by a.label, a.idnr, a.din_random, b.labdt;
quit;


data transfusion_lab1d;
set transfusion_lab1c;
by label idnr din_random sampledtbefore;
if first.din_random;
run;


proc sql;
create table transfusion_lab2 as
select
    label,
	idnr,
	sampledtbefore,
	min(transdt) as firsttransdt format=datetime.,
	max(transdt) as lasttransdt format=datetime.,
	sampledtafter,
	sum(transdt ne .) as units
from transfusion_lab1d
group by
    label,
	idnr,
	sampledtbefore,
	sampledtafter;
quit;

/*
*Check for overlaps;
proc sql;
create table errors as
select
  a.label,
  a.idnr,
  a.sampledtbefore as sb1,
  b.sampledtbefore as sb2,
  a.sampledtafter as sa1,
  b.sampledtafter as sa2
from transfusion_lab2 a inner join transfusion_lab2 b
  on a.label=b.label and a.idnr=b.idnr and (a.sampledtbefore lt b.sampledtbefore lt a.sampledtafter OR b.sampledtbefore lt a.sampledtafter lt b.sampledtafter);
quit;

data x;
set transfusion_lab2;
where idnr=47134;
run;
*/
proc sort data=transfusion_lab2;
by label idnr sampledtbefore sampledtafter;
run;

data transfusion_lab3;
set transfusion_lab2;
by label idnr sampledtbefore sampledtafter;
if first.sampledtbefore;
run;



/*
*Check for overlaps;
proc sql;
create table errors2 as
select
  a.label,
  a.idnr,
  a.sampledtbefore as sb1,
  b.sampledtbefore as sb2,
  a.sampledtafter as sa1,
  b.sampledtafter as sa2
from transfusion_lab3 a inner join transfusion_lab3 b
  on a.label=b.label and a.idnr=b.idnr and (a.sampledtbefore lt b.sampledtbefore lt a.sampledtafter OR a.sampledtbefore lt b.sampledtbefore lt a.sampledtafter OR (a.sampledtbefore lt b.sampledtbefore and b.sampledtafter lt a.sampledtafter));
quit;



data x;
set transfusion_lab3;
where idnr=375890;
run;
*/


proc sort data=transfusion_lab3;
by label idnr sampledtbefore sampledtafter;
run;

data transfusion_lab4;
set transfusion_lab3;
by label idnr sampledtafter sampledtbefore ;
if first.sampledtafter;
run;





*Check for overlaps;
proc sql;
create table errors3 as
select
  a.label,
  a.idnr,
  a.sampledtbefore as sb1,
  b.sampledtbefore as sb2,
  a.sampledtafter as sa1,
  b.sampledtafter as sa2
from transfusion_lab4 a inner join transfusion_lab4 b
  on a.label=b.label and a.idnr=b.idnr and (a.sampledtbefore lt b.sampledtbefore lt a.sampledtafter OR a.sampledtbefore lt b.sampledtbefore lt a.sampledtafter OR (a.sampledtbefore lt b.sampledtbefore and b.sampledtafter lt a.sampledtafter));
quit;

*Remove these!;
proc sql;
create table transfusion_lab5 as
select distinct
    a.label,
	a.idnr,
	a.sampledtbefore,
	a.firsttransdt,
	a.lasttransdt,
	a.sampledtafter,
	a.units,
	max(a.idnr=b.idnr) as bad
from transfusion_lab4 as a left join errors3 as b
  on a.label=b.label and a.idnr=b.idnr and (min(b.sb1,b.sb2) le a.sampledtbefore le max(b.sa1,b.sa2) OR min(b.sb1,b.sb2) le a.sampledtafter le max(b.sa1,b.sa2))
group by
    a.label,
	a.idnr,
	a.sampledtbefore,
	a.firsttransdt,
	a.lasttransdt,
	a.sampledtafter,
	a.units;
	quit;
proc freq data=transfusion_lab5;
tables bad;
run;

data transfusion_lab6;
set transfusion_lab5;
where not bad;
drop bad;
run;

proc sql;
create table transfusion_lab7 as
select
	a.*,
	b.value as valueafter
from transfusion_lab6 as a inner join cleanmultilab as b
on a.idnr=b.idnr and a.label=b.label and a.sampledtafter=b.labdt 
order by a.label, a.idnr, a.sampledtafter, b.value;
quit;

data transfusion_lab8;
set transfusion_lab7;
by label idnr sampledtafter;
*if not (first.sampledtafter and last.sampledtafter);
if last.sampledtafter;
run;

proc sql;
create table transfusion_lab9 as
select
	a.*,
	b.value as valuebefore
from transfusion_lab8 as a inner join cleanmultilab as b
on a.idnr=b.idnr and a.label=b.label and a.sampledtbefore=b.labdt 
order by a.label, a.idnr, a.sampledtbefore, b.value;
quit;

data transfusion_lab10;
set transfusion_lab9;
by label idnr sampledtbefore;
*if not (first.sampledtbefore and last.sampledtbefore);
if last.sampledtbefore;
deltavalue=valueafter-valuebefore;

run;


data agnostic_9;
set agnostic_8;

donorbloodgroup=compress(donorbloodgroup,'+-');

unknowndonor=(donorid="" or dondate =.);
foreigndonor=(donorbirthorigin = "N");
if donorbirthorigin="9" then foreigndonor=9;

run;



proc sql;
create table preliminarydata as
select
    b.label,
	a.idnr,
	b.sampledtbefore,
	min(a.transdt) as firsttransdt format=datetime.,
	max(a.transdt) as lasttransdt format=datetime.,
	b.sampledtafter,
	b.valuebefore,
	b.valueafter,
	b.deltavalue,
	a.recipientsex,
	a.bloodgroup,
	min(a.recipientage) as recipientage,

	max(a.unknowndonor) as unknowndonor,

	mean(a.donorhb) as meandonorhb,
	min(a.donorhb) as mindonorhb,
	max(a.donorhb) as maxdonorhb,

	mean(a.donorsex) as meandonorsex,
	min(a.donorsex) as mindonorsex,
	max(a.donorsex) as maxdonorsex,

	mean(a.donorage) as meandonorage,
	min(a.donorage) as mindonorage,
	max(a.donorage) as maxdonorage,

	mean(a.numdonations) as meannumdonations,
	min(a.numdonations) as minnumdonations,
	max(a.numdonations) as maxnumdonations,

	sum(a.donorbloodgroup="A") as donorbga,
	sum(a.donorbloodgroup="AB") as donorbgab,
	sum(a.donorbloodgroup="B") as donorbgb,
	sum(a.donorbloodgroup="O") as donorbgo,
	sum(a.donorbloodgroup=" ") as missingbloodgroup,

	sum(a.identicalbg=1) as identicalbg,

	sum(a.idnr ne '')  as units,

	mean(a.storagetime) as meanstoragetime,
	min(a.storagetime) as minstoragetime,
	max(a.storagetime) as maxstoragetime,

	mean(a.time_since_donation) as meantimesince,
	min(a.time_since_donation) as mintimesince,
	max(a.time_since_donation) as maxtimesince,

	mean(a.foreigndonor) as meanbirthorigin,
	min(a.foreigndonor) as minbirthorigin,
	max(a.foreigndonor) as maxbirthorigin,

	mean(a.donorparity) as meandonorparity,
	min(a.donorparity) as mindonorparity,
	max(a.donorparity) as maxdonorparity,

	sum(a.donproc="WB") as wholeblooddonation,
	sum(a.donproc ne "WB") as otherdonation

from agnostic_9 a inner join transfusion_lab10 b
on a.idnr=b.idnr and b.sampledtbefore lt a.transdt and b.sampledtafter gt a.transdt
group by
    b.label,
	a.idnr,
	b.sampledtbefore,
	b.valuebefore,
	b.sampledtafter,
	b.valueafter,
	b.deltavalue,
	a.recipientage,
	a.recipientsex,
	a.bloodgroup;
quit;
proc sort data=preliminarydata; 
by label idnr sampledtbefore;
run;

/*
data x;
set preliminarydata;
by label idnr sampledtbefore;
if not (first.sampledtbefore and last.sampledtbefore);
*by label idnr firsttransdt;
*if not (first.firsttransdt and last.firsttransdt);
run;
*/
proc sql;
create table pd2 as
select
  a.*,
  b.value as lasthbvalue,
  b.labdt as sampledtlasthbvalue
from preliminarydata a left join cleanmultilab b
  on a.idnr=b.idnr and a.firsttransdt gt b.labdt and b.label="HB" and b.value ne .
order by 
    a.label,
	a.idnr,
	a.sampledtbefore,
	a.valuebefore,
	a.sampledtafter,
	a.valueafter,
	a.deltavalue,
	a.recipientsex,
	a.bloodgroup,
	b.labdt;
quit;
data pd2b;
set pd2;
by label idnr sampledtbefore;
if last.sampledtbefore;
run;

proc sql;
create table pd3 as
select
  a.*,
  b.value as lastlaktat,
  b.labdt as sampledtlastlaktat
from pd2b a left join cleanmultilab b
  on a.idnr=b.idnr and a.firsttransdt gt b.labdt and b.label="LAKTAT" and b.value ne .
order by 
    a.label,
	a.idnr,
	a.sampledtbefore,
	a.valuebefore,
	a.sampledtafter,
	a.valueafter,
	a.deltavalue,
	a.recipientage,
	a.recipientsex,
	a.bloodgroup,
	b.labdt;
quit;
data pd3b;
set pd3;
by label idnr sampledtbefore;
if last.sampledtbefore;
run;
proc sql;
create table pd4 as
select
  a.*,
  b.donorid
from pd3b a left join agnostic_9 b
  on a.idnr=b.idnr and a.lasttransdt=a.firsttransdt and a.lasttransdt=b.transdt and a.units=1 and b.unknowndonor=0
order by label;
  quit;
* numdonations ;
proc summary data=pd4 nway;
by label;
var deltavalue;
output out=perc(drop=_type_ _Freq_)  p1(deltavalue)=delta_p1 p99(deltavalue)=delta_p99;
run;
data agtx.finaldata_reds&hours(drop=mindonorhb maxdonorhb mindonorsex maxdonorsex donorbga donorbgb donorbgab donorbgo identicalbg missingbloodgroup maxstoragetime minstoragetime mintimesince maxtimesince mindonorage maxdonorage meanbirthorigin maxbirthorigin minbirthorigin meandonorparity mindonorparity maxdonorparity);
merge pd4 perc;
by label;
*if unknowndonor then delete;
*if not (&startdate le datepart(firsttransdt) le &stopdate) then delete;

if deltavalue = . then delete;

time_before=(lasttransdt-sampledtbefore)/3600;
time_after=(sampledtafter-lasttransdt)/3600;


*Donor hb categorization;
if maxdonorhb lt 130 then donorhbcat=60;
else if mindonorhb ge 130 and maxdonorhb lt 145 then donorhbcat=130;
else if mindonorhb ge 145 and maxdonorhb lt 160 then donorhbcat=145;
else if mindonorhb ge 160 then donorhbcat=160;
else donorhbcat=999;

*Donor age categorization;
if maxdonorage lt 30 then donoragecat=18;
else if mindonorage ge 30 and maxdonorage lt 45 then donoragecat=30;
else if mindonorage ge 45 and maxdonorage lt 60 then donoragecat=45;
else if mindonorage ge 60 then donoragecat=60;
else donoragecat=99;

*Donor blood group categorization;
if donorbga=units then donorbloodgroup="A ";
else if donorbgb=units then donorbloodgroup="B ";
else if donorbgab=units then donorbloodgroup="AB";
else if donorbgo=units then donorbloodgroup="O ";
else donorbloodgroup="9";

*Identical blood group categorization;
if identicalbg=units then idbloodgroupcat=1;
else if missingbloodgroup > 0 then idbloodgroupcat=9;
else if identicalbg<units then idbloodgroupcat=0;

*Storage time categorization;
if meanstoragetime=. then storagecat=99;
else if maxstoragetime lt 10 then storagecat=0;
else if minstoragetime ge 10 and maxstoragetime lt 20 then storagecat=10;
else if minstoragetime ge 20 and maxstoragetime lt 30 then storagecat=20;
else if minstoragetime ge 30 and maxstoragetime lt 35 then storagecat=30;
else if minstoragetime ge 35 then storagecat=35;
else storagecat=99;

*Donorsex categorization;
if meandonorsex=. then donorsexcat=9;
else if maxdonorsex =1 then donorsexcat=1;
else if mindonorsex =2 then donorsexcat=2;
else donorsexcat=9;

*Time since donation categorization;
if meantimesince=. then timesincecat=999;
else if maxtimesince lt 180 then timesincecat=0;
else if mintimesince ge 180 and maxtimesince lt 365 then timesincecat=180;
else if mintimesince ge 365 then timesincecat=365;
else timesincecat=999;

*Donor birth origin categorization;
if meanbirthorigin=. or meanbirthorigin gt 1 then donorbirthorigin=9;
else if maxbirthorigin=minbirthorigin then donorbirthorigin=minbirthorigin;
else donorbirthorigin=9;

*Donor parity categorization;
if meandonorparity=9 then donorparity=9;
else if maxdonorparity=mindonorparity then donorparity=mindonorparity;
else donorparity=9;

*Number of donations categorization;
if meannumdonations =.  then numdoncat =99;
else if maxnumdonations = 0 then numdoncat=0;
else if maxnumdonations lt 5 then numdoncat=1;
else if minnumdonations ge 5 and maxnumdonations lt 10 then numdoncat=5;
else if minnumdonations ge 10 and maxnumdonations lt 20 then numdoncat=10;
else if minnumdonations ge 20 then numdoncat=20;
else numdoncat=99;

if wholeblooddonation=units then donationtype="Wholeblood";
else donationtype="Other";
extremevalue=(deltavalue lt delta_p1 or deltavalue gt delta_p99);
foreigndonor=(donorbirthorigin in (1));

run;
/*
proc freq data=agtx.finaldata_reds&hours;
tables storagecat donorsexcat timesincecat donoragecat weekdaycat timecat numdoncat donorbirthorigin donorparity extremevalue;
run;
proc freq data=agtx.finaldata_reds&hours;
where units=1;
tables storagecat donorsexcat timesincecat donoragecat weekdaycat timecat numdoncat donorbirthorigin donorparity;
run;

proc freq data=agtx.finaldata_reds&hours;
where units=1;
tables  timesincecat;
run;

proc ttest data=agtx.finaldata_reds&hours;
where units=1 and label="HB" and donorsexcat lt 3 and extremevalue=0;
var deltavalue;
class donorsexcat;
run;
proc glimmix data=agtx.finaldata_reds&hours;
where units=1 and label="HB" and meandonorsex lt 3 and extremevalue=0 and donationtype="Wholeblood";
class meandonorsex(ref="1");
	effect tspl1=spline(time_before / naturalcubic knotmethod=equal(3));
	effect tspl2=spline(time_after / naturalcubic knotmethod=equal(3));

model deltavalue=meandonorsex tspl1 tspl2 / dist=normal link=id s;
run;
*/
proc sort data=agtx.finaldata_reds&hours;
by idnr firsttransdt label ;
run;
data templongreds&hours(keep=label idnr time_before time_after recipientage recipientsex units predictor predictorvalue deltavalue bloodgroup donorid meandonorhb donationtype unknowndonor encounter);
set agtx.finaldata_reds&hours;
where units=1 and extremevalue=0;
by idnr firsttransdt label ;
retain encounter;
if first.idnr then encounter=0;
array pred[8] meandonorhb meandonorsex meandonorage numdoncat meanstoragetime timesincecat donorparity foreigndonor;
do _i=1 to 8;
	if pred[_i] ne . then do;
		predictor=vname(pred[_i]);
		predictorvalue=pred[_i];
		output;
		end;
	end;
run;
/*
proc freq data=templongreds&hours;
tables donationtype;
run;
proc freq data=templongreds&hours;
tables predictorvalue; where predictor='foreigndonor';
run;
*/
data agtx.finaldata_reds_long&hours;
set templongreds&hours;
where donationtype="Wholeblood";
*Cleanup for analysis purposes;
if predictor='meandonorhb' and (predictorvalue lt 100 or predictorvalue gt 190) then delete;
if predictor='meandonorsex' and (predictorvalue lt 1 or predictorvalue gt 2) then delete;
if predictor='meandonorage' and (predictorvalue lt 18 or predictorvalue gt 80) then delete;
if predictor='meanstoragetime' and (predictorvalue lt 0 or predictorvalue gt 42) then delete;
if predictor='donorparity' and (predictorvalue =9) then delete;
run;
