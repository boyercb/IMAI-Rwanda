/*-------------------------------*
 |file:    00_master.do          |
 |project: IMAI rwanda           |
 |author:  christopher boyer     |
 |date:    26 oct 2015           |
 *-------------------------------*
  description:
    this is the master do-file for the analysis of the impact of IMAI training
  on the odds of proper diagnosis and treatment by Rwandan nurses. running 
  the program replicates every step from cleaning the raw .dta files through 
  merging, reshaping, and analysis. for privacy purposes the only change made
  to the raw data not reflected here is the removal of personally identifiable
  information.
*/

clear
version 13

// <================== Section 1: Define global variables ==================> //

global proj "~/Dropbox/ARCHeS/IMAI_Rwanda"
global rawdata "${proj}/data/raw"
global cleandata "${proj}/data/clean"
global bin "${proj}/Stata"
global figures "${proj}/figures"
global tables "${proj}/tables"

// <================== Section 2: Clean and reshape data  ==================> //
cd "${bin}"
run 01_clean_and_code.do
cd "${bin}"
run 02_reshape.do

// <================== Section 3: Descriptive statistics  ==================> //

cd "${bin}"
do 03_desc_table1.do
cd "${bin}"
run 04_desc_table2.do

// <================ Section 4: Formal statistical analysis ================> //

cd "${bin}"
run 05_analysis_logistic.do
cd "${bin}"
run 06_analysis_multilevel.do
