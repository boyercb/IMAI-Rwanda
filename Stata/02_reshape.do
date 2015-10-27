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

drop mental_specific* other_specific*
reshape long chief_complaint nursesis mentorsis classagree treatagree, i(id) j(complaint)
drop if chief_complaint == ""

save "IMAI_Rwanda_Complaints_Cleaned", replace
