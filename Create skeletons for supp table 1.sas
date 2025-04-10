%let localpath=%substr(%sysget(SAS_EXECFILEPATH),1,%eval(%length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILENAME))-1));;
%inc "&localpath\Local setup pannan2.sas";
%inc "&localpath\Lookup macros.sas";
options minoperator mindelimiter=',';

data bothcohorts;
set agtx.Finaldata_long24(rename=(idnr=id) keep=idnr label predictor encounter) agtx.finaldata_reds_long24(keep=idnr label predictor encounter);

if idnr = . then idnr=compress("S"||id);
else idnr=compress("R"||idnr);
%lookuparrays;
    new_label = "Unknown key                            ";
    new_predictor = "Unknown key                           ";
if label="TROPT" then label="TROP_T";
if label="TROPI" then label="TROP_I";
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
	if predictor="meandonationtime" them new_predictor="Time of donation";

    drop i id;
run;
proc freq data=bothcohorts;
where new_predictor = "Unknown key";
tables predictor;
run;
proc freq data=bothcohorts;
where new_label = "Unknown key";
tables label;
run;
proc sql;
create table AGTXOUTP.SuppTable1 as
select a.*, coalesce(b.reds_count,0) as reds_count
from (
	select
	  new_predictor,
	  count(*) as scandat_count
	from (select distinct new_predictor, idnr, encounter from bothcohorts where idnr like "S%") 
	group by new_predictor
	) as a left join
	(
	select
	  new_predictor,
	  count(*) as reds_count
	from (select distinct new_predictor, idnr, encounter from bothcohorts where idnr like "R%") 
	group by new_predictor
	) as b
on a.new_predictor=b.new_predictor;
quit;
data _null_;
file 'K:\SCANDAT\User\Gustaf\AgnosticTx2\Output\SuppTab1.csv' delimiter=',' DSD DROPOVER lrecl=32767;
if _n_ = 1 then        /* write column names or labels */
do;
 put
    "new_predictor"
 ','
    "scandat_count"
 ','
    "reds_count"
 ;
end;
set  AGTXOUTP.SUPPTABLE1   end=EFIEOD;
 format new_predictor $38. ;
 format scandat_count best12. ;
 format reds_count best12. ;
do;
 EFIOUT + 1;
 put new_predictor $ @;
 put scandat_count @;
 put reds_count ;
 ;
end;
run;
/*
proc sql;
create table AGTXOUTP.SuppTable2 as
select a.*, coalesce(b.reds_count,0) as reds_count
from (
	select
	  new_label,
	  count(*) as scandat_count
	from (select distinct new_label, idnr, encounter from bothcohorts where idnr like "S%") 
	group by new_label
	) as a left join
	(
	select
	  new_label,
	  count(*) as reds_count
	from (select distinct new_label, idnr, encounter from bothcohorts where idnr like "R%") 
	group by new_label
	) as b
on a.new_label=b.new_label;
quit;
  data _null_;
file 'K:\SCANDAT\User\Gustaf\AgnosticTx2\Output\SuppTab2.csv' delimiter=',' DSD DROPOVER lrecl=32767;
if _n_ = 1 then        
do;
 put
    "new_label"
 ','
    "scandat_count"
 ','
    "reds_count"
 ;
end;
set  AGTXOUTP.SUPPTABLE2   end=EFIEOD;
 format new_label $60. ;
 format scandat_count best12. ;
 format reds_count best12. ;
do;
 EFIOUT + 1;
 put new_label $ @;
 put scandat_count @;
 put reds_count ;
 ;
end;
run;
*/
