*Extract SCANDAT data for agnostic study of donor/donation/component parameters and recipient laboratory changes;


/*
3. Extract data
3.1. Fetch transfusions
*/
%macro check_exists(dataset);
	%if %sysfunc(exist(&dataset)) %then %do;
		%put &dataset exists;
		%end;
	%else %do;
		data agnostic;
		set sc3.transfusion;
		where year(datepart(transdt)) >= 1995 and xprodtype="E";
		keep idnr poolnum transdt donationid origin;
		run;
		%end;
%mend check_exists;

%check_exists(agnostic);

proc sql;
select count(*) from (select distinct idnr from agnostic);
quit;
/*
3.2. Add persons data
*/
proc sql;
create table agnostic_2 as
select
	a.*,
	b.birthdate,
	b.deathdate,
	b.migdate,
	b.sex,
	b.bloodgroup
from agnostic as a inner join sc3.persons as b
on a.idnr=b.idnr
where b.error=0;
quit;

proc sql;
select count(*) from (select distinct idnr from agnostic_2);
quit;

*3.3. Add donation data;
%macro check_exists(dataset);
	%if %sysfunc(exist(&dataset)) %then %do;
		%put &dataset exists;
		%end;
	%else %do;
		proc sort data=sc3.donation out=donation;
		by donationid dondt;
		run;
		data donation_nodup;
		set donation;
		by donationid;
		if first.donationid and last.donationid;
		run;
		%end;
%mend check_exists;

%check_exists(donation_nodup);



proc sql;
create table agnostic_3 as
select
	a.*,
	b.idnr as donorid,
	b.dondt,
	b.hbvalue as donorhb
from agnostic_2 as a left join donation_nodup as b
on a.donationid=b.donationid;
quit;
proc sql;
select count(*) from (select distinct idnr from agnostic_3);
quit;

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
*3.5. Add donation data to compute number of donations and time since most recent donation;
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

/*
proc sql;
select count(*) from (select distinct idnr from agnostic_6);
quit;
4. Data manipulations
4.1. Compute storage time, sime since donation, donor age, and recipient age
*/
data agnostic_7;
set agnostic_6;
	storagetime=(transdt-dondt)/(60*60*24);
	time_since_donation=(dondt-mostrecentdonation)/(3600*24);
	donorage=(datepart(dondt)-donorbirthdate)/365.24;
	recipientage=(datepart(transdt)-birthdate)/365.24;
	if compress(bloodgroup,'+-')='' OR compress(donorbloodgroup,'+-')='' then identicalbg=9;
	else identicalbg=(compress(bloodgroup,'+-')=compress(donorbloodgroup,'+-'));
	wdy_donation = weekday(datepart(dondt));
	if dondt=. or wdy_donation=. then wdy_donation=9;
	donationtime=timepart(dondt)/3600;
	if donorbirthorigin='' then donorbirthorigin=99;
	if donorsex=. then donorparity=9;
	else if donorsex=1 then donorparity=0;
	else if donorsex=2 and donorparity=0 then donorparity=1;
	else if donorsex=2 and donorparity=1 then donorparity=2;

run;
proc freq data=agnostic_7;
tables wdy_donation donationtime donorbirthorigin donorparity;
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
if donationtime=0 then donationtime=.;
run;
*4.3. Examine predictors;
data predictorvariables;
set agnostic_8;
keep donationid donorage donorhb donorsex donorbloodgroup numdonations storagetime time_since_donation identicalbg wdy_donation donationtime donorbirthorigin donorparity;
run;

*4.3.1. Summaries;
*DESCRIPTIVE SUMMARY CATEGORICAL;
proc freq data=predictorvariables;
where donorsex in (1,2);
tables donorbloodgroup numdonations identicalbg wdy_donation donationtime;
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
			    value,
			    sampledt,
				analysis
			from sc3.lab 
			where idnr in (select distinct idnr from agnostic_8);
		quit;
		%end;
%mend check_exists;
%check_exists(multilab);
%macro check_exists(dataset);
	%if %sysfunc(exist(&dataset)) %then %do;
		%put &dataset exists;
		%end;
	%else %do;
		proc sql;
		create table cslab as	
		select
		    label,
		    idnr,
		    value,
		    sampledt
		from cs.Labdata_scandat
		where idnr in (select distinct idnr from agnostic_8);
		quit;		
	%end;
%mend check_exists;
%check_exists(cslab);
/*
proc freq data=cslab;
tables label;
run;
*/
*CLEAN LABVALUES;

data cleanmultilab(drop=analysis);
set multilab cslab;

if substr(label,1,4) = "AGAP" then label="AGAP";
if label=:"FO2" then label="SO2";
if label in ("PO2","PCO2") and
	(
	substr(upcase(analysis),1,2) in ("VB" "KB" "CV" "MV")
	OR find(upcase(analysis),"VEN")>0
	OR find(upcase(analysis),"VB")>0
	) then delete;	

if label="O2HB" and find(upcase(analysis),"AB")>0 then label="SO2";
else if label="O2HB" OR label="OHB" then delete;

if label in ('EOSINO_P' 'MONO_P' 'EOSINO_P' 'NEUTRO_P' 'PROMYELO' 'PEEP' 'MYELO_P' 'META_P' 'SO2' "O2" 'BLAST') then delete;
if label in ('APT', 'CA_ALB', 'ERYTROBL', 'HB_A', 'HB_A2', 'HB_F', 'HDL', 'KOLEST', 'KREA_CL', 'LDL', 'LDL_HDL', 'LPK_X', 'MCH_RET', 'NEUTRO_SEG', 'NEUTRO_STAV', 'PLASMA', 'PLASMA_P', 'PROMYELO_P', 'TRANSF_SAT', 'TROPT', 'UREA') then delete;

if label="HCT" then label="EVF";

if label="EVF" then delete;
if label="EGFR" and value gt 150 then delete;

if label="SR" and (value lt 0 or value gt 150) then delete;
if value lt 0 then delete;

run;

proc sort data=cleanmultilab nodupkey;
by label idnr value sampledt;
run;

/*
proc freq data=cleanmultilab;
tables label;
run;

*/

*5.2. Add to cohort;


proc sort data=cleanmultilab;
by label idnr sampledt;
run;



proc sql;
create table transfusion_lab1 as
select
    a.label,
	a.idnr,
	a.sampledt as sampledtbefore,
	a.value as valuebefore,
	b.transdt,
	b.donationid
from cleanmultilab a inner join agnostic_8 b
  on a.idnr=b.idnr and b.transdt - %sysevalf(&timewindow) lt a.sampledt lt b.transdt
order by a.label, a.idnr, b.donationid, a.sampledt;
quit;
/*
proc freq data=transfusion_lab1;
tables label;
run;

*/
data transfusion_lab1b;
set transfusion_lab1;
by label idnr donationid sampledtbefore;
if last.donationid;
run;




proc sql;
create table transfusion_lab1c as
select
    a.label,
	a.idnr,
	a.sampledtbefore,
	a.valuebefore,
	a.transdt,
	a.donationid,
	b.sampledt as sampledtafter,
	b.value as valueafter
from transfusion_lab1b a inner join cleanmultilab b
  on a.label=b.label and a.idnr=b.idnr and a.transdt + %sysevalf(&timewindow) gt b.sampledt gt a.transdt
order by a.label, a.idnr, a.donationid, b.sampledt;
quit;


data transfusion_lab1d;
set transfusion_lab1c;
by label idnr donationid sampledtbefore;
if first.donationid;
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
on a.idnr=b.idnr and a.label=b.label and a.sampledtafter=b.sampledt 
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
on a.idnr=b.idnr and a.label=b.label and a.sampledtbefore=b.sampledt 
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

unknowndonor=(donorid=. or dondt =.);
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
	a.birthdate,
	a.deathdate,
	a.migdate,
	a.sex,
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

	sum(a.idnr ne .)  as units,

	mean(a.storagetime) as meanstoragetime,
	min(a.storagetime) as minstoragetime,
	max(a.storagetime) as maxstoragetime,

	mean(a.time_since_donation) as meantimesince,
	min(a.time_since_donation) as mintimesince,
	max(a.time_since_donation) as maxtimesince,

	mean(a.wdy_donation) as meanweekday,
	min(a.wdy_donation) as minweekday,
	max(a.wdy_donation) as maxweekday,

	mean(a.donationtime) as meandonationtime,
	min(a.donationtime) as mindonationtime,
	max(a.donationtime) as maxdonationtime,

	mean(a.donorbirthorigin) as meanbirthorigin,
	min(a.donorbirthorigin) as minbirthorigin,
	max(a.donorbirthorigin) as maxbirthorigin,

	mean(a.donorparity) as meandonorparity,
	min(a.donorparity) as mindonorparity,
	max(a.donorparity) as maxdonorparity
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
	a.birthdate,
	a.deathdate,
	a.migdate,
	a.sex,
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
  b.sampledt as sampledtlasthbvalue
from preliminarydata a left join cleanmultilab b
  on a.idnr=b.idnr and a.firsttransdt gt b.sampledt and b.label="HB" and b.value ne .
order by 
    a.label,
	a.idnr,
	a.sampledtbefore,
	a.valuebefore,
	a.sampledtafter,
	a.valueafter,
	a.deltavalue,
	a.birthdate,
	a.deathdate,
	a.migdate,
	a.sex,
	a.bloodgroup,
	b.sampledt;
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
  b.sampledt as sampledtlastlaktat
from pd2b a left join cleanmultilab b
  on a.idnr=b.idnr and a.firsttransdt gt b.sampledt and b.label="LAKTAT" and b.value ne .
order by 
    a.label,
	a.idnr,
	a.sampledtbefore,
	a.valuebefore,
	a.sampledtafter,
	a.valueafter,
	a.deltavalue,
	a.birthdate,
	a.deathdate,
	a.migdate,
	a.sex,
	a.bloodgroup,
	b.sampledt;
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
data agtx.finaldata&hours(drop=mindonorhb maxdonorhb mindonorsex maxdonorsex unknowndonor donorbga donorbgb donorbgab donorbgo identicalbg missingbloodgroup maxstoragetime minstoragetime mintimesince maxtimesince mindonorage maxdonorage minweekday maxweekday mindonationtime maxdonationtime meanbirthorigin maxbirthorigin minbirthorigin meandonorparity mindonorparity maxdonorparity deathdate birthdate migdate sex);
merge pd4 perc;
by label;
if unknowndonor then delete;
if not (&startdate le datepart(firsttransdt) le &stopdate) then delete;
if label in ("AGAP" "AGAP+K" "CELLER" "DIFF" "ERYTROMORF" "HBF" "HBFR" "HBX" "HDLTRI" "HYPOKR" "TIBC" "X") then delete;
if deltavalue = . then delete;

time_before=(lasttransdt-sampledtbefore)/3600;
time_after=(sampledtafter-lasttransdt)/3600;
recipientsex=sex;

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

*Weekday categorization;
if meanweekday=. then weekdaycat=9;
else if maxweekday=minweekday then weekdaycat=minweekday;
else weekdaycat=9;
if weekdaycat in (1,7) then weekdaycat=9;

*Donor birth origin categorization;
if meanbirthorigin=. then donorbirthorigin=99;
else if maxbirthorigin=minbirthorigin then donorbirthorigin=minbirthorigin;
else donorbirthorigin=99;

*Donor parity categorization;
if meandonorparity=9 then donorparity=9;
else if maxdonorparity=mindonorparity then donorparity=mindonorparity;
else donorparity=9;

*Donationtime categorization;
if meandonationtime=.  or maxdonationtime lt 7 or mindonationtime gt 20 then timecat =99;
else if maxdonationtime lt 12 then timecat=7;
else if mindonationtime ge 12 and maxdonationtime lt 16 then timecat=12;
else if mindonationtime ge 16 and maxdonationtime le 20 then timecat=16;
else timecat=99;


*Number of donations categorization;
if meannumdonations =.  then numdoncat =99;
else if maxnumdonations = 0 then numdoncat=0;
else if maxnumdonations lt 5 then numdoncat=1;
else if minnumdonations ge 5 and maxnumdonations lt 10 then numdoncat=5;
else if minnumdonations ge 10 and maxnumdonations lt 20 then numdoncat=10;
else if minnumdonations ge 20 then numdoncat=20;
else numdoncat=99;

extremevalue=(deltavalue lt delta_p1 or deltavalue gt delta_p99);
foreigndonor=(donorbirthorigin in ("11" "12"));

run;

proc freq data=agtx.finaldata&hours;
tables storagecat donorsexcat timesincecat donoragecat weekdaycat timecat numdoncat donorbirthorigin donorparity extremevalue;
run;
proc freq data=agtx.finaldata&hours;
where units=1;
tables storagecat donorsexcat timesincecat donoragecat weekdaycat timecat numdoncat donorbirthorigin donorparity foreigndonor;
run;

proc freq data=agtx.finaldata24;
where units=1;
tables  timesincecat;
run;

