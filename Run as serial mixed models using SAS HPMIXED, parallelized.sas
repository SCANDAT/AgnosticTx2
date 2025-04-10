%macro runallmixed(sf=, rt=, timewindow=24);
data local(index=(step));
set agtx.finaldata_long&timewindow;
by label predictor notsorted;
retain step;

if _n_=1 then step=0;
step+(first.predictor);
run;
%do iter=&sf %to &rt;
	proc sql noprint;
	select count(*) into: observations from local where step=&iter;
	select distinct label into: label from local where step=&iter;
	select distinct predictor into: predictor from local where step=&iter;
	quit;
	data current;
	set local(where=(step=&iter)) MAINWORK.scoredata(in=a where=(predictor="&predictor"));
	forplot=a;
	run;
	proc hpmixed data=current;
	%if &predictor = donorparity %then %do;
		where predictorvalue ne 0;
		%end;
	effect tspl1=spline(time_before / naturalcubic knotmethod=equal(3));
	effect tspl2=spline(time_after / naturalcubic knotmethod=equal(3));
	%if &predictor = donorparity OR
			&predictor = idbloodgroupcat OR
			&predictor = meandonorsex OR
			&predictor = meanweekday OR
			&predictor = numdoncat OR
			&predictor = timesincecat OR
			&predictor = foreigndonor %then %do;
		class predictorvalue recipientsex idnr;
		model deltavalue=predictorvalue tspl1 tspl2 / s;
		random intercept / subject = idnr type=un;
		test predictorvalue / chisq htype=3;
		%end;
	%if &predictor = meandonationtime OR
			&predictor = meandonorage OR
			&predictor = meandonorhb OR
			&predictor = meanstoragetime %then %do;
		class recipientsex idnr;
		effect predspline=spline(predictorvalue / naturalcubic knotmethod=equal(3));
		model deltavalue=predspline tspl1 tspl2 / s;
		random intercept / subject = idnr type=un;
		test predspline / chisq htype=3;
		%end;
	output out=predsn(where=(forplot=1)) pred(noblup)=predicted lcl(noblup)=lower ucl(noblup)=upper;
	ods output parameterestimates=solfn ConvergenceStatus=csn tests3=type3n;
	run;
	
	%if not(&predictor = meandonorhb) %then %do;
		proc hpmixed data=current;
		%if &predictor = donorparity %then %do;
			where predictorvalue ne 0;
			%end;
		effect tspl1=spline(time_before / naturalcubic knotmethod=equal(3));
		effect tspl2=spline(time_after / naturalcubic knotmethod=equal(3));
		effect hbspl=spline(meandonorhb / naturalcubic knotmethod=equal(3));
		%if &predictor = donorparity OR
				&predictor = idbloodgroupcat OR
				&predictor = meandonorsex OR
				&predictor = meanweekday OR
				&predictor = numdoncat OR
				&predictor = timesincecat OR
				&predictor = foreigndonor %then %do;
			class predictorvalue recipientsex idnr;
			model deltavalue=predictorvalue tspl1 tspl2 hbspl / s;
			random intercept / subject = idnr type=un;
			test predictorvalue / chisq htype=3;
			%end;
		%if &predictor = meandonationtime OR
				&predictor = meandonorage OR
				&predictor = meanstoragetime %then %do;
			class recipientsex idnr;
			effect predspline=spline(predictorvalue / naturalcubic knotmethod=equal(3));
			model deltavalue=predspline tspl1 tspl2 hbspl/ s;
			random intercept / subject = idnr type=un;
			test predspline / chisq htype=3;
			%end;
		output out=predsn_hb(where=(forplot=1)) pred(noblup)=predicted lcl(noblup)=lower ucl(noblup)=upper;
		ods output parameterestimates=solfn_hb ConvergenceStatus=csn_hb tests3=type3n_hb;
		run;
		%end;
	data solfn;
	predictor="&predictor";
	label="&label";
	set solfn %if not(&predictor = meandonorhb) %then %do; solfn_hb(in=a)%end; ;
	%if not(&predictor = meandonorhb) %then %do;
		adjusted=a;
		%end;
	%else %do;
		adjusted=0;
		%end;
	run;		
	data csn;
	predictor="&predictor";
	label="&label";
	set csn %if not(&predictor = meandonorhb) %then %do; csn_hb(in=a)%end; ;
	%if not(&predictor = meandonorhb) %then %do;
		adjusted=a;
		%end;
	%else %do;
		adjusted=0;
		%end;
	run;
	data type3n;
	predictor="&predictor";
	label="&label";
	set type3n %if not(&predictor = meandonorhb) %then %do; type3n_hb(in=a)%end; ;
	%if not(&predictor = meandonorhb) %then %do;
		adjusted=a;
		%end;
	%else %do;
		adjusted=0;
		%end;
	run;
	data predsn;
	set predsn %if not(&predictor = meandonorhb) %then %do; predsn_hb(in=a)%end; ;	
	predictor="&predictor";
	label="&label";
	drop idnr--recipientsex step--forplot;
	%if not(&predictor = meandonorhb) %then %do;
		adjusted=a;
		%end;
	%else %do;
		adjusted=0;
		%end;
	run;
	%let nobs_SOLF=0; %let nobs_CS=0; %let nobs_TYPE3=0; %let nobs_PLOTDATA=0; %let nobs_SOLFn=0; %let nobs_CSn=0; %let nobs_TYPE3n=0; %let nobs_predsn=0;
	proc sql noprint; 
	select nobs into: nobs_SOLF from sashelp.vtable where libname="WORK" and memname="SOLF";
	select nobs into: nobs_SOLFN from sashelp.vtable where libname="WORK" and memname="SOLFN";
	select nobs into: nobs_CS from sashelp.vtable where libname="WORK" and memname="CS";
	select nobs into: nobs_CSN from sashelp.vtable where libname="WORK" and memname="CSN";
	select nobs into: nobs_TYPE3 from sashelp.vtable where libname="WORK" and memname="TYPE3";
	select nobs into: nobs_TYPE3N from sashelp.vtable where libname="WORK" and memname="TYPE3N";
	select nobs into: nobs_PLOTDATA from sashelp.vtable where libname="WORK" and memname="PLOTDATA";
	select nobs into: nobs_PREDSN from sashelp.vtable where libname="WORK" and memname="PREDSN";
	quit;

	%if %eval(&nobs_SOLF = 0 AND &nobs_SOLFN > 0) %then %do;
		data solf;
		set solfn;
		run;
		%end;
	%if %eval(&nobs_CS = 0 AND &nobs_CSN > 0) %then %do;
		data cs;
		set csn;
		run;
		%end;
	%if %eval(&nobs_TYPE3 = 0 AND &nobs_TYPE3N > 0) %then %do;
		data type3;
		set type3n;
		run;
		%end;
	%if %eval(&nobs_PLOTDATA = 0 AND &nobs_PREDSN > 0) %then %do;
		data plotdata;
		set predsn;
		run;		
		%end;
	%if %eval(&nobs_SOLF >= 1 AND &nobs_SOLFN > 0) %then %do;
		data solf;
		set solf solfn;
		run;
		%end;
	%if %eval(&nobs_CS >= 1 AND &nobs_CSN > 0) %then %do;
		data cs;
		set cs csn;
		run;
		%end;
	%if %eval(&nobs_TYPE3 >= 1 AND &nobs_TYPE3N > 0) %then %do;
		data type3;
		set type3 type3n;
		run;
		%end;
	%if %eval(&nobs_PLOTDATA >= 1 AND &nobs_PREDSN > 0) %then %do;
		data plotdata;
		set plotdata predsn;
		run;
		%end;
	%end;
%mend;
