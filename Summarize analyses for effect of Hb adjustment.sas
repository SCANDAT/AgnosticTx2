%let localpath=%substr(%sysget(SAS_EXECFILEPATH),1,%eval(%length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILENAME))-1));;
%inc "&localpath\Local setup pannan2.sas";
%inc "&localpath\Lookup macros.sas";
options minoperator mindelimiter=',';
proc sql;
create table signals as
select label, predictor, availableinreds, fdr_p, bon_p
from agtxoutp.table2_results
where bon_p lt 0.05;
quit;

proc sql;
create table agtxoutp.sig_type3 as
select
  a.*,
  b.*
from signals a left join agtxoutp.univariate24_type3 b
  on a.label=b.label and a.predictor=b.predictor and b.adjusted=1;
  quit;
