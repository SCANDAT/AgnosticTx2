%let localpath=%substr(%sysget(SAS_EXECFILEPATH),1,%eval(%length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILENAME))-1));;
libname sc3 "D:\SCANDAT3 database";
libname agtx "D:\Project data\AgnosticTx2\Raw data";
libname agtxsamp "&localpath\Sample data";
libname agtxoutp "&localpath\Output";
libname cs "D:\Clinisoft project\Clean data";
libname agtxpara "D:\Project data\AgnosticTx2\Parallel";
libname cleanr3 "D:\REDS3 public use database\Clean DB";
