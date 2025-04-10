*1. Set up local environment for #pannan2;
%let localpath=%substr(%sysget(SAS_EXECFILEPATH),1,%eval(%length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILENAME))-1));;
%inc "&localpath\Local setup pannan2.sas";
%inc "&localpath\Lookup macros.sas";
dm 'odsresults; clear';
dm 'log; clear';
filename output3 "&localpath\SAS Outputs\Examine coherence of 24 and 6 hour results.pdf";
ods pdf file=output3;

proc sql;
create table fdr24_6 as
select distinct
  a.*,
  b.ProbF as ProbF_6,
  b.fdr_p as fdr_p_6
from agtxoutp.Table2_results a left join agtxoutp.Univariate6_fdr b
  on a.predictor=b.predictor and a.label=b.label and b.adjusted=0
order by a.fdr_p;
quit;

/*
proc sort data=fdr24_6;
by predictor label;
run;
data dups;
set fdr24_6;
by predictor label;
if not (first.label and last.label);
run;
*/

proc sort data=fdr24_6;
by bon_p ProbF_6;
run;
data fdr24_6b;
set fdr24_6;
fdr_sig24=(fdr_p<0.05);
bon_p24=(bon_p<0.05);
sig6=(ProbF_6<0.05);
fdr_sig6=(fdr_p_6<0.05);
run;


proc sql;
create table plotm24 as
select
  a.*,
  b.bon_p,
  b.ProbF_6,
  24 as timewindow
from agtxoutp.Univariate24_plotdata a inner join fdr24_6b b
  on a.label=b.label and a.predictor=b.predictor and a.adjusted=0
order by a.label, a.predictor;
create table plotm6 as
select
  a.*,
  b.bon_p,
  b.ProbF_6,
  6 as timewindow
from agtxoutp.Univariate6_plotdata a inner join fdr24_6b b
  on a.label=b.label and a.predictor=b.predictor and a.adjusted=0
order by a.label, a.predictor;
quit;
data plotdata_all;
set plotm24 plotm6;
where bon_p lt 0.05;
if predictor in ("donorparity" "idbloodgroupcat" "meandonorsex") then do;
	predcat=predicted;lowcat=lower;upcat=upper;
	predicted=.;lower=.;upper=.;
	end;
*Fix some x-axes;
run;
proc sort datA=plotdata_all;
by bon_p probf_6 timewindow label predictor predictorvalue;
run;
%macro RGBHex(rr,gg,bb); 
%sysfunc(compress(CX%sysfunc(putn(&rr,hex2.)) %sysfunc(putn(&gg,hex2.)) %sysfunc(putn(&bb,hex2.)))) 
%mend RGBHex;
options orientation=portrait nodate nonumber topmargin=0.25cm leftmargin=0.5cm rightmargin=0.5cm bottommargin=0.25cm;
goptions reset=all device=SASPRTC noborder papersize=a4;
ods graphics / noborder width=25cm height=20cm;
ODS PDF FILE = "&localpath\Output\Plots for assessment of coherence betwen 24- and 6-hour timw window analyses.pdf" dpi=400 nopdfnote nogtitle ;
proc freq data=fdr24_6b;
title "Coherence between 24h and 6h analyses";
tables bon_p24*sig6 /*fdr_sig24*fdr_sig6*/ / nocol ;
run;
proc sgplot data=plotdata_all noborder nowall;
where probf_6 < 0.05;
title "Significant also in 6h";
by label predictor notsorted;
styleattrs datasymbols=(circlefilled trianglefilled) datacolors=(%rgbhex(49,80,130) %rgbhex(122,0,0) %rgbhex(150,0,0) ) datacontrastcolors=(%rgbhex(49,80,130) %rgbhex(122,0,0) %rgbhex(150,0,0) );
scatter x=predictorvalue y=predcat / YERRORLOWER=lowcat YERRORUPPER=upcat group=timewindow JITTER jitterwidth=0.1 markerattrs=(size=10) ERRORBARATTRS=(thickness=2);
band x=predictorvalue  lower=lower upper=upper / group=timewindow  fillattrs=(transparency=0.5 color=%rgbhex(211,211,211));
series x=predictorvalue y=predicted / group=timewindow;
xaxis offsetmin=0.05 offsetmax=0.05 integer;
run;	
proc sgplot data=plotdata_all noborder nowall;
by label predictor notsorted;
where probf_6 ge 0.05;
title "Not significant in 6h";
styleattrs datasymbols=(circlefilled trianglefilled) datacolors=(%rgbhex(49,80,130) %rgbhex(122,0,0) %rgbhex(150,0,0) ) datacontrastcolors=(%rgbhex(49,80,130) %rgbhex(122,0,0) %rgbhex(150,0,0) );
scatter x=predictorvalue y=predcat / YERRORLOWER=lowcat YERRORUPPER=upcat group=timewindow JITTER jitterwidth=0.1 markerattrs=(size=10) ERRORBARATTRS=(thickness=2);
band x=predictorvalue  lower=lower upper=upper / group=timewindow  fillattrs=(transparency=0.5 color=%rgbhex(211,211,211));
series x=predictorvalue y=predicted / group=timewindow;
xaxis offsetmin=0.05 offsetmax=0.05 integer;
run;
ods pdf close;
title;
dm 'log; print file="&localpath\Logs\Run initial mixed effects models in parallel, &tw hours.log" replace; ';
ods pdf close;
ods html;


