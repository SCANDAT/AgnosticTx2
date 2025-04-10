*1. Generate sample data for inclusion in GitHub repo for agnostic study of donor/component parameters and recipient laboratory changes;
*Set up local environment for #pannan2;
%let localpath=%substr(%sysget(SAS_EXECFILEPATH),1,%eval(%length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILENAME))-1));
%inc "&localpath\Local setup pannan2.sas";
dm 'odsresults; clear';
dm 'log; clear';
*Randomly pick individual patient;
proc sql noprint;
select idnr into: subject
from 
	(select idnr, ranuni(9) as rannr from (select distinct idnr from agtx.finaldata24))
having rannr=min(rannr);
quit;

proc sql;
create table sampledata as
select *
from agtx.Finaldata24
where idnr=&subject
order by firsttransdt;
quit;
/*
proc contents data=sampledata;
run;
*/
%macro RandBetween(min, max, seed=0);
	(&min + floor((1+&max-&min)*ranuni(&seed)))
%mend;
data agtxsamp.sampledata(drop=randate firstdate);
set sampledata;
drop birthdate bloodgroup deathdate migdate lasthbvalue lastlaktat idnr sampledtlasthbvalue sampledtlastlaktat sex;
retain randate firstdate;
if _n_=1 then do;
	randate=%RandBetween(min='01jan2006'd,max='01jul2018'd,seed=5);
	firstdate=datepart(firsttransdt);
	end;
format firsttransdt lasttransdt sampledtbefore sampledtafter datetime.;
firsttransdt=dhms(randate+datepart(firsttransdt)-firstdate, 0, 0, timepart(firsttransdt));  
lasttransdt=dhms(randate+datepart(lasttransdt)-firstdate, 0, 0, timepart(lasttransdt));  
sampledtbefore=dhms(randate+datepart(sampledtbefore)-firstdate, 0, 0, timepart(sampledtbefore));  
sampledtafter=dhms(randate+datepart(sampledtafter)-firstdate, 0, 0, timepart(sampledtafter));  

recipientage=5*floor(recipientage/5);
meandonorage=floor(meandonorage);
run;
proc sort data=agtx.Finaldata24 out=timingtemp nodupkey;
by idnr time_before time_after;
run;
data agtxsamp.timingdata;
set timingtemp;
keep time_before time_after;
run;
dm 'log; print file="&localpath\Logs\Generate sample data.log" replace; ';
