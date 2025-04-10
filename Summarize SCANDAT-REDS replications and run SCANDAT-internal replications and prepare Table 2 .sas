%let localpath=%substr(%sysget(SAS_EXECFILEPATH),1,%eval(%length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILENAME))-1));;
%inc "&localpath\Local setup pannan2.sas";
%inc "&localpath\Lookup macros.sas";
proc sql;
select count(*)
from (select distinct label from agtxoutp.Univariate24_fdr);
quit;
proc sql;
select count(*)
from (select distinct predictor from agtxoutp.Univariate24_fdr);
quit;
proc sql;
select count(*)
from agtxoutp.Univariate24_fdr
where adjusted=0;
quit;
*First fetch SCANDAT FDR results;
proc sql;
create table SCANDATFDRsig as
select *
from agtxoutp.Univariate24_fdr
where fdr_p lt 0.05 and adjusted=0;
quit;

*Check which are replicable in REDS3;
proc sql;
create table SCANDATFDRsig2 as
select distinct
	a.predictor, 
	a.label, 
	a.probf, 
	a.fdr_p, 
	(a.label=b.label) as availableinreds,
	b.probf as reds3_probf
from SCANDATFDRsig a left join agtxoutp.Univariate_reds24_fdr b
  on a.predictor=b.predictor and a.label=b.label and b.adjusted=0
order by a.fdr_p;
  quit;

*Split dataset into two parts for SCANDAT-internal  vs REDS-external replication;
data sfs_internal sfs_external;
set SCANDATFDRsig2;
if availableinreds then output sfs_external;
else output sfs_internal;
run;



*Fetch SCANDAT multi-unit cohort data;
*Restructure to long format;
data templongmulti24(keep=label idnr time_before time_after recipientage recipientsex units predictor predictorvalue deltavalue bloodgroup donorid meandonorhb);
set agtx.finaldata24;
where units=2 and extremevalue=0;
array pred[10] meandonorhb donorsexcat donoragecat numdoncat storagecat timesincecat weekdaycat meandonationtime donorparity donorbirthorigin;
do _i=1 to 10;
	if pred[_i] ne . then do;
		predictor=vname(pred[_i]);
		predictorvalue=pred[_i];
		output;
		end;
	end;
run;
data finaldata_multilong24;
set templongmulti24;
*Cleanup for analysis purposes;
/*
if predictor='meandonorhb' and (predictorvalue lt 100 or predictorvalue gt 190) then delete;
if predictor='meandonorsex' and (predictorvalue lt 1 or predictorvalue gt 2) then delete;
if predictor='meandonorage' and (predictorvalue lt 18 or predictorvalue gt 80) then delete;
if predictor='meanstoragetime' and (predictorvalue lt 0 or predictorvalue gt 42) then delete;
if predictor='meanweekday' and predictorvalue=1 then delete;
if predictor='meandonationtime' and (predictorvalue lt 6 or predictorvalue gt 20) then delete;
if predictor='donorparity' and (predictorvalue =9) then delete;
if predictor='idbloodgroupcat' and (predictorvalue =9) then delete;
if predictor='meanweekday' then predictorvalue=predictorvalue-1;
*/
if predictor='donorbirthorigin' then predictor='foreigndonor';
if predictor='donoragecat' then predictor='meandonorage';
if predictor='donorsexcat' then predictor='meandonorsex';
if predictor='storagecat' then predictor='meanstoragetime';
if predictor='weekdaycat' then predictor='meanweekday';

if label="SO2" then delete;
run;










proc freq data=sfs_internal;
tables predictor;
run;
proc sql;
create table multiunitcohort(drop=availableinreds reds3_probf) as
select *
from sfs_internal a inner join finaldata_multilong24 b
  on a.label=b.label and a.predictor=b.predictor
order by a.label, a.predictor;
  quit;
  *Remove observations with unknown/unefinable values;
data muc2;
set multiunitcohort;
if predictor='meandonorhb' and predictorvalue gt 200 then delete;
if predictor='meandonorsex' and predictorvalue = 9 then delete;
if predictor='meandonorage' and predictorvalue = 99 then delete;
if predictor='numdoncat' and predictorvalue = 99 then delete;
if predictor='meanstoragetime' and predictorvalue = 99 then delete;
if predictor='timesincecat' and predictorvalue = 999 then delete;
if predictor='meanweekday' and predictorvalue = 9 then delete;
if predictor='timecat' and predictorvalue = 99 then delete;
if predictor='donorparity' and predictorvalue = 9 then delete;
if predictor='donorparity' and predictorvalue = 0 then delete;
if predictor='foreigndonor' and predictorvalue = 99 then delete;
if predictor='foreigndonor' then predictorvalue=(predictorvalue in ("11" "12"));
deltavalue_units=deltavalue/units;
run;
proc sql;
create table scoredata_local as
select distinct a.label, b.*
from muc2 a inner join agtx.scoredata24 b
  on a.predictor=b.predictor
order by a.label, b.predictor, b.predictorvalue;
quit;

data muc3;
set muc2(in=a) scoredata_local(in=b);
by label predictor;
forplot=b;
if b and predictor='meanstoragetime' then do;
	if not (predictorvalue in (0 10 20 30 35)) then delete;
	end;
if b and predictor='meandonorage' then do;
	if not (predictorvalue in (18 30 45 60)) then delete;
	end;
if predictor='foreigndonor' and predictorvalue = 99 then delete;
if predictor='timesincecat' and predictorvalue = 999 then delete;
run;

ods output Tests3=type3_cat;
proc glimmix data=muc3;
by label predictor;
where predictor ne "meandonorhb";
effect tspl1=spline(time_before / naturalcubic knotmethod=equal(3));
effect tspl2=spline(time_after / naturalcubic knotmethod=equal(3));
class predictorvalue recipientsex idnr;
model deltavalue_units=predictorvalue tspl1 tspl2 / s link=id dist=normal;
random intercept / subject = idnr type=un;
output out=preds1(where=(forplot=1)) pred(noblup)=predicted lcl(noblup)=lower ucl(noblup)=upper;
run;

ods output Tests3=type3_spl;
proc glimmix data=muc3;
by label predictor;
where predictor = "meandonorhb";
effect tspl1=spline(time_before / naturalcubic knotmethod=equal(3));
effect tspl2=spline(time_after / naturalcubic knotmethod=equal(3));
effect predspline=spline(predictorvalue / naturalcubic knotmethod=equal(3));
class  recipientsex idnr;
model deltavalue_units=predspline tspl1 tspl2 / s link=id dist=normal;
random intercept / subject = idnr type=un;
output out=preds2(where=(forplot=1)) pred(noblup)=predicted lcl(noblup)=lower ucl(noblup)=upper;
run;

data type3_all;
set type3_cat type3_spl;
where effect=:"pred";
run;

data agtxoutp.Plotdata_scandat_multi24;
set preds1 preds2;
run;

proc sql;
create table sfs3 as
select
  a.*,
  b.ProbF as internal_probf,
  coalesce(a.reds3_probf,b.probf) as repl_pvalue
from Scandatfdrsig2 a left join agtxoutp.Plotdata_scandat_multi24 b
  on a.label=b.label and a.predictor=b.predictor
  order by calculated repl_pvalue;
  quit;


proc sql;
create table signals as
select label, predictor, availableinreds, repl_pvalue
from sfs3
where repl_pvalue lt 0.05;
quit;

proc sql;
create table scandat_single as
select
   a.*,
   b.repl_pvalue
from agtxoutp.Univariate24_plotdata a inner join signals b
  on a.label=b.label and a.predictor=b.predictor and a.adjusted=0;
  quit;
 proc sql;
create table reds_single as
select
   a.*,
   b.repl_pvalue
from agtxoutp.Univariate_reds24_plotdata a inner join signals b
  on a.label=b.label and a.predictor=b.predictor and a.adjusted=0;
  quit;
 proc sql;
create table scandat_multi as
select
   a.*,
   b.repl_pvalue
from agtxoutp.Plotdata_scandat_multi24 a inner join signals b
  on a.label=b.label and a.predictor=b.predictor;
  quit;

data plotdata_all;
set scandat_single(in=ss) reds_single(in=rs) scandat_multi(in=sm);
if ss then source="SCANDAT single";
if rs then source="REDS3 single";
if sm then source="SCANDAT multi";
if sm and predictor in ("meandonorage" "meanstoragetime") then do;
	predcat=predicted;lowcat=lower;upcat=upper;
	predicted=.;lower=.;upper=.;
	end; 
if predictor in ("donorparity" "idbloodgroupcat" "meandonorsex") then do;
	predcat=predicted;lowcat=lower;upcat=upper;
	predicted=.;lower=.;upper=.;
	end;
*Fix some x-axes;
if sm and predictor='meanstoragetime' then do;
	if predictorvalue lt 30 then predictorvalue=predictorvalue+5;
	else if predictorvalue =30 then predictorvalue=32.5;
	else if predictorvalue =35 then predictorvalue=38.5;
	end;
if sm and predictor='meandonorage' then do;
	if predictorvalue = 18 then predictorvalue=18+0.5*(30-18);
	else if predictorvalue = 30 then predictorvalue=30+0.5*(45-30);
	else if predictorvalue = 45 then predictorvalue=45+0.5*(60-45);
	else if predictorvalue = 60 then predictorvalue=60+0.5*(80-60);
	end;
run;
proc freq data=plotdata_all;
tables predictor*source;
run;
proc freq data=plotdata_all;
tables source*predictor*predictorvalue;
run;


proc sql;
create table pda2 as
select a.*, b.cat, b.spl
from plotdata_all a left join (select label, predictor, max(predcat ne .) as cat, max(predicted ne .) as spl from plotdata_all group by label, predictor) b
  on a.label=b.label and a.predictor=b.predictor
order by a.label, a.predictor, a.predictorvalue, a.source;
quit;
%macro RGBHex(rr,gg,bb); 
%sysfunc(compress(CX%sysfunc(putn(&rr,hex2.)) %sysfunc(putn(&gg,hex2.)) %sysfunc(putn(&bb,hex2.)))) 
%mend RGBHex;
proc format;
value donorsex
	1="Male donor"
	2="Female donor"
	;
value donorparity
	0="Male donor"
	1="Nulliparous female donor"
	2="Parous female donor"
	;
value aboid
	0="ABO compatible, non-identical"
	1="ABO identical"
	;
run;

%macro plotall;
proc sql noprint;
select count(*) into: nr from (select distinct label, predictor from pda2);
quit;
%let first=9999;
%do iter=1 %to &nr;
	data currentplot;
	set pda2;
	by label predictor notsorted;
	retain step;
	if _n_=1 then step=0;
	step+(first.predictor);
	if step=&iter;
	run;
	proc sql noprint;
	select distinct upcase(label) into: label from currentplot;
	select distinct lowcase(predictor) into: predictor from currentplot;
	select (max(predcat) ne .) into: categorical from currentplot;
	select (max(predicted) ne .) into: spline from currentplot;
	quit;

	proc sgplot data=currentplot noborder nowall;
	title  "&iter.. %trim(%predictor_lookup2(&predictor)) vs. Delta %trim(%label_lookup2(&label))";
	styleattrs datasymbols=(circlefilled trianglefilled)  datacolors=(%rgbhex(49,80,130) %rgbhex(122,0,0) %rgbhex(150,0,0) ) datacontrastcolors=(%rgbhex(49,80,130) %rgbhex(122,0,0) %rgbhex(150,0,0) );
	%if %eval(&predictor=donorparity) %then %do; format predictorvalue donorparity.; %end;
	%if %eval(&predictor=idbloodgroupcat) %then %do; format predictorvalue aboid.; %end;
	%if %eval(&predictor=meandonorsex) %then %do; format predictorvalue donorsex.; %end;
	%if %eval(&categorical=1) %then %do;
		scatter x=predictorvalue y=predcat / YERRORLOWER=lowcat YERRORUPPER=upcat group=source JITTER jitterwidth=0.1 markerattrs=(size=10) ERRORBARATTRS=(thickness=2) ;
		%end;
	%if %eval(&spline=1) %then %do;
		series x=predictorvalue y=predicted / group=source lineattrs=(thickness=3);
		band x=predictorvalue  lower=lower upper=upper / group=source  fillattrs=(transparency=0.5 color=%rgbhex(211,211,211));
		%end;
	yaxis 
		label="Delta %trim(%label_lookup(&label)) (95% CI)"
		offsetmax=0.15
		;
	xaxis 
		label="%trim(%predictor_lookup(&predictor))"
		offsetmin=0.05 offsetmax=0.05
		integer
		/*%if &predictor in (donorparity,idbloodgroupcat,meandonorsex) %then %do;
			type=discrete
			%end;*/
		;
	run;		
	%end;
%mend;
dm 'odsresults; clear';
options orientation=landscape nodate nonumber topmargin=0.25cm leftmargin=0.5cm rightmargin=0.5cm bottommargin=0.25cm;
goptions reset=all device=SASPRTC noborder papersize=a4;
ods graphics / noborder width=25cm height=20cm;
ODS PDF FILE = "&localpath\Output\Plots for assessment of coherence.pdf" dpi=400 nopdfnote nogtitle ;
%plotall;
ods pdf close;
title;




data sfs4;
set sfs3;

/*coherent=1;
if label="APTT" and predictor="meanstoragetime" then do;
	repl_pvalue=.;
	coherent=0;
	end;
if label="ERYTRO" and predictor="meanstoragetime" then do;
	repl_pvalue=.;
	coherent=0;
	end;
if label="HB" and predictor="timesincecat" then do;
	repl_pvalue=.;
	coherent=0;
	end;*/
id=_n_;
run;
*Then perform Bonferroni adjustment;
proc multtest inpvalues(repl_pvalue)=sfs4 bon out=sfs5 plots=all;
*where coherent;
id id;
run;

proc sql;
create table sfse6(drop=id) as
select
  a.*,
  coalesce(b.bon_p,1) as bon_p
from sfs4 a left join sfs5 b
on a.id=b.id
order by a.label, a.predictor;
quit;

proc sql;
create table reds_obs as
select 
label, predictor, count(*) as obs
from agtx.finaldata_reds_long24
group by label, predictor;
quit;

proc sql;
create table sasmulti_obs as
select 
label, predictor, count(*) as obs
from multiunitcohort
group by label, predictor;
quit;

data agtxoutp.table2_results;
merge sfse6(in=a) reds_obs(in=r) sasmulti_obs;
by label predictor;
if a;
if r then cohort=	"REDS3         ";
else cohort=		"SCANDAT 2-unit";
drop reds3_probf internal_probf;
run;

data temp;
    set AGTXOUTP.Table2_results;
%lookuparrays;
    new_label = "Unknown key                            ";
    new_predictor = "Unknown key                           ";

    /* Lookup for label */
    do i = 1 to 55;
        if label = labels_keys[i] then do;
            new_label = labels_values[i];
            leave;
        end;
    end;

    /* Lookup for predictor */
    do i = 1 to 10;
        if predictor = predictors_keys[i] then do;
            new_predictor = predictors_values[i];
            leave;
        end;
    end;

    drop i;
run;
proc sort data=temp;
by bon_p;
run;
data _null_;
file 'K:\SCANDAT\User\Gustaf\AgnosticTx2\Output\Table 2 data.csv' delimiter=',' DSD DROPOVER lrecl=32767;
if _n_ = 1 then        /* write column names or labels */
 do;
   put
      "label"
   ','
      "predictor"
   ','
      "fdr_p"
   ','
      "cohort"
   ','
      "obs"
   ','
      "repl_pvalue"
   ','
      "bon_p"
   ','
      "coherent"
   ;
 end;
set  temp   end=EFIEOD;
   format new_label $50. ;
   format new_predictor $200. ;
   format fdr_p e14. ;
   format obs best12. ;
   format repl_pvalue e14. ;
   format bon_p e14. ;
   format coherent best12. ;
do;
   EFIOUT + 1;
   put new_label $ @;
   put new_predictor $ @;
   put fdr_p @;
   put cohort $ @;
   put obs @;
   put repl_pvalue @;
   put bon_p @;
   put coherent ;
   ;
 end;
run;
