*1. Set up local environment for #pannan2;
%let localpath=%substr(%sysget(SAS_EXECFILEPATH),1,%eval(%length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILENAME))-1));;
%inc "&localpath\Local setup pannan2.sas";
%inc "&localpath\Lookup macros.sas";

*2. Run sequence of programs;
*2.a. Data extractions;
%inc "&localpath\Extract data for Swedish main analyses.sas";
%inc "&localpath\Extract data for REDS3 main analyses.sas";

*2.b. Execute the data extractions wih different time windows;
%inc "&localpath\Execute the data extractions wih different time windows.sas";

*3.a. Main analyses SCANDAT;
%inc "&localpath\Run initial mixed effects models in parallel.sas";
*3.b. Main analyses REDS;
%inc "&localpath\Run initial mixed effects models in parallel REDS.sas";
*3.c. Run 6h-analyses with SCANDAT;
%inc "&localpath\Run initial mixed effects models in parallel 6h.sas";

*4. Main analyses;
%inc "&localpath\Create table 1.sas";
%inc "&localpath\Summarize SCANDAT-REDS replications and run SCANDAT-internal replications and prepare Table 2.sas";
%inc "&localpath\Create skeletons for supp table 1.sas";
%inc "&localpath\Investigate distributions of timing and lab values.sas";
%inc "&localpath\Create skeleton for Supp Table 2 with numbers and lab delta distributions.sas";

*5. Plot replicated associations;
%inc "&localpath\Plot replicated associations.sas";

*6. Examine effect of adjustments;
%inc "&localpath\Summarize analyses for effect of Hb adjustment.sas";

*7. Cleanup and housekeeping;
%inc "&localpath\Generate sample anonymized data.sas";
