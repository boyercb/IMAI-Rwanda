/*-------------------------------*
 |file:    04_desc_table2.do     |
 |project: IMAI rwanda           |
 |author:  christopher boyer     |
 |date:    26 oct 2015           |
 *-------------------------------*
  description:
    this file creates table 2, a descriptive statistics summary table.
*/

clear
version 13

// read per patient data set
cd "${cleandata}"
use "IMAI_Rwanda_Nurses_Cleaned", replace

cd "${tables}/unformatted"
// table 1: summary statistics by treatment status
#delimit ;
table1, by(imai_nurse)
  vars( level_educ cate \
        exp_opd contn \
        nobs contn \
        health_center cat \
	    )
  saving("table_01_desc_nurses.xls", replace)
  plusminus
  format(%2.1f);
#delimit cr

