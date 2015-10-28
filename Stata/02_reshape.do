/*-------------------------------*
 |file:    02_reshape.do         |
 |project: IMAI rwanda           |
 |author:  christopher boyer     |
 |date:    26 oct 2015           |
 *-------------------------------*
  description:
    this file reshapes the data to per complaint level observations.
*/

clear
version 13

// read per patient data set
cd "${cleandata}"
use "IMAI_Rwanda_Patients_Cleaned", replace

// reshape data set to per complaint
drop mental_specific* other_specific*
reshape long chief_complaint nursesis mentorsis dx_agree tx_agree, i(id) j(complaint)
drop if chief_complaint == ""

// save result
save "IMAI_Rwanda_Complaints_Cleaned", replace

// create nurse-level data set
use "IMAI_Rwanda_Patients_Cleaned", replace
keep nurse_id imai_ever imai_mar imai_oct level_educ trainmonth exp_opd health_center nobs
duplicates drop

save "IMAI_Rwanda_Nurses_Cleaned", replace
