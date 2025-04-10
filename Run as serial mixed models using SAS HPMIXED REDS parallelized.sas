%macro runallmixed(sf=, rt=, timewindow=24);
data local(index=(step));
set agtx.finaldata_reds_long&timewindow;
by label predictor;
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
	%if %eval(&iter = &sf) %then %do;
		data solf;
		set solfn;
		run;
		data cs;
		set csn;
		run;
		data type3;
		set type3n;
		run;
		data plotdata;
		set predsn;
		run;		
		%end;
	%if %eval(&iter gt &sf) %then %do;
		data solf;
		set solf solfn;
		run;
		data cs;
		set cs csn;
		run;
		data type3;
		set type3 type3n;
		run;
		data plotdata;
		set plotdata predsn;
		run;
		%end;
	%end;
%mend;
