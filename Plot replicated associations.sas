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
create table scandat_single as
select
   a.*,
   b.fdr_p,
   b.bon_p
from agtxoutp.Univariate24_plotdata a inner join signals b
  on a.label=b.label and a.predictor=b.predictor and a.adjusted=0;
  quit;
 proc sql;
create table reds_single as
select
   a.*,
   b.fdr_p,
   b.bon_p
from agtxoutp.Univariate_reds24_plotdata a inner join signals b
  on a.label=b.label and a.predictor=b.predictor and a.adjusted=0;
  quit;
 proc sql;
create table scandat_multi as
select
   a.*,
   b.fdr_p,
   b.bon_p
from agtxoutp.Plotdata_scandat_multi24 a inner join signals b
  on a.label=b.label and a.predictor=b.predictor;
  quit;

data plotdata_all;
set scandat_single(in=ss) reds_single(in=rs) scandat_multi(in=sm);
if ss then source="SCANDAT single";
if rs then source="REDS3 single";
if sm then source="SCANDAT 2-unit";
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
proc sort data=plotdata_all;
by label predictor source;
run;
/*
proc sgplot data=plotdata_all noborder nowall;
by label predictor notsorted;
styleattrs datasymbols=(circlefilled trianglefilled) datacolors=(%rgbhex(49,80,130) %rgbhex(122,0,0) %rgbhex(150,0,0) ) datacontrastcolors=(%rgbhex(49,80,130) %rgbhex(122,0,0) %rgbhex(150,0,0) );
scatter x=predictorvalue y=predcat / YERRORLOWER=lowcat YERRORUPPER=upcat group=source JITTER jitterwidth=0.1 markerattrs=(size=10) ERRORBARATTRS=(thickness=2);
band x=predictorvalue  lower=lower upper=upper / group=source  fillattrs=(transparency=0.5 color=%rgbhex(211,211,211));
series x=predictorvalue y=predicted / group=source;
xaxis offsetmin=0.05 offsetmax=0.05 integer;
run;		
*/
proc format;
value donorsex
	1="Male"
	2="Female"
	;
value donorparity
	0="Male donor"
	1="Nulliparous"
	2="Parous"
	;
value aboid
	0="ABO compatible, non-identical"
	1="ABO identical"
	;
run;

%macro RGBHex(rr,gg,bb); 
%sysfunc(compress(CX%sysfunc(putn(&rr,hex2.)) %sysfunc(putn(&gg,hex2.)) %sysfunc(putn(&bb,hex2.)))) 
%mend RGBHex;
ods graphics / attrpriority=none;
%macro plotall(data, from=1, to=&nr);
proc sql noprint;
select count(*) into: nr from (select distinct label, predictor from &data);
quit;
%let first=9999;
%do iter=&from %to &to;
	data currentplot;
	set &data;
	by label predictor notsorted;
	retain step;
	if _n_=1 then step=0;
	step+(first.predictor);
	if step=&iter;
	run;
	proc sql noprint;
	select distinct upcase(label) into: label from currentplot;
	select distinct lowcase(predictor) into: predictor from currentplot;
	select distinct bon_p into: pvalue from currentplot;
	select (max(predcat) ne .) into: categorical from currentplot;
	select (max(predicted) ne .) into: spline from currentplot;
	quit;

	proc sgplot data=currentplot noborder nowall;
	title j=center h=7pt "&iter.. %trim(%predictor_lookup2(&predictor)) vs. %trim(%label_lookup2(&label)) change";
	styleattrs datasymbols=(circlefilled trianglefilled) datacolors=(%rgbhex(49,80,130) %rgbhex(122,0,0) %rgbhex(150,0,0) ) datacontrastcolors=(%rgbhex(49,80,130) %rgbhex(122,0,0) %rgbhex(150,0,0) );
	%if %eval(&predictor=donorparity) %then %do; format predictorvalue donorparity.; %end;
	%if %eval(&predictor=idbloodgroupcat) %then %do; format predictorvalue aboid.; %end;
	%if %eval(&predictor=meandonorsex) %then %do; format predictorvalue donorsex.; %end;
	%if %eval(&spline=1) %then %do;
		band x=predictorvalue  lower=lower upper=upper / group=source  fillattrs=(transparency=0.85 color=%rgbhex(211,211,211));
		series x=predictorvalue y=predicted / group=source name="series" lineattrs=(thickness=1.5);
		%end;
	%if %eval(&categorical=1) %then %do;
		scatter x=predictorvalue y=predcat / YERRORLOWER=lowcat YERRORUPPER=upcat group=source JITTER jitterwidth=0.15 markerattrs=(size=9) ERRORBARATTRS=(thickness=1.5) name="scatter";
		%end;
	yaxis 
		label="Delta %trim(%label_lookup(&label))"
		labelattrs=(size=8pt)
		valueattrs=(size=8pt)
		;
	xaxis 
		label="%trim(%predictor_lookup(&predictor))"
		offsetmin=0.05 offsetmax=0.05
		labelattrs=(size=8pt)
		valueattrs=(size=8pt)
		integer
		/*%if &predictor in (donorparity,idbloodgroupcat,meandonorsex) %then %do;
			type=discrete
			%end;*/
		;
	keylegend %if %eval(&categorical=1) %then %do; "scatter" %end; %if %eval(&spline=1) %then %do; "series" %end; / valueattrs=(size=8pt) down=2 noborder title="" location=inside;
	run;		
	%end;
%mend;
proc sort data=plotdata_all;
by bon_p label predictor;
run;

proc sql;
create table plotdata_all2 as
select
  a.*,
  b.reds3replicated
from plotdata_all a
  inner join
  (select label, predictor, max(source="REDS3 single") as reds3replicated from plotdata_all group by label, predictor) as b
on a.label=b.label and a.predictor=b.predictor
order by b.reds3replicated desc, a.bon_p, a.label, a.predictorvalue;
quit;
proc sort data=plotdata_all2;
by descending reds3replicated bon_p label predictor source predictorvalue;
run;
proc template;
 define style pdfcustom;
 parent = Styles.Pearl ;
	class graphaxislines / linethickness=4px;
   end;
run;
/*
goptions reset=all device=SASPRTC noborder papersize=a4;
options orientation=landscape nodate nonumber topmargin=1.5cm leftmargin=0.5cm rightmargin=0.5cm bottommargin=1.5cm;
ods graphics / noborder;
ODS PDF  FILE = "&localpath\Output\Replicated plots SCANDAT+REDS3.pdf" dpi=400 nopdfnote nogtitle ;
ods layout gridded columns=4 rows=3 advance=table column_widths=(7cm 7cm 7cm 7cm) row_heights=(6cm 6cm 6cm) column_gutter=0cm row_gutter=0cm;
%plotall(data=plotdata_all, from=1, to=12);
title1;
ods layout end;
ods layout gridded columns=4 rows=3 advance=table column_widths=(7cm 7cm 7cm 7cm) row_heights=(6cm 6cm 6cm) column_gutter=0cm row_gutter=0cm;
%plotall(data=plotdata_all, from=13, to=22);
title1;
ods layout end;
ODS PDF CLOSE; 
*/


goptions reset=all device=SASPRTC noborder papersize=a4;
options orientation=portrait nodate nonumber topmargin=0.5cm leftmargin=0.5cm rightmargin=0.5cm bottommargin=0.5cm;
ods graphics / noborder;
ODS PDF  FILE = "&localpath\Output\Replicated plots SCANDAT+REDS3.pdf" dpi=400 nopdfnote nogtitle ;
ods layout gridded columns=3 rows=4 advance=table column_widths=(6.5cm 6.5cm 6.5cm) row_heights=(7cm 7cm 7cm 7cm) column_gutter=0cm row_gutter=0cm;
%plotall(data=plotdata_all2, from=1, to=12);
title1;
ods layout end;
ods pdf startpage=now;
ods layout gridded columns=3 rows=4 advance=table column_widths=(6.5cm 6.5cm 6.5cm) row_heights=(7cm 7cm 7cm 7cm) column_gutter=0cm row_gutter=0cm;
%plotall(data=plotdata_all2, from=13, to=22);
title1;
ods layout end;
ODS PDF CLOSE; 
