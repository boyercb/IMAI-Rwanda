PROC IMPORT
DATAFILE= “~/ashwin/imaiblfuq32012_final_v3.xls”
OUT= work.tmp;
SHEET= “Data”;
GETNAMES= Yes ;
RUN;

DATA imaiblfuq32012_final_v3_rest;
SET work.tmp;
RUN;