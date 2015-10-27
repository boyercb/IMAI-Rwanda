/*-------------------------------*
 |file:    03_desc_table1.do     |
 |project: IMAI rwanda           |
 |author:  christopher boyer     |
 |date:    26 oct 2015           |
 *-------------------------------*
  description:
    this file creates table 1, a descriptive statistics summary table.
*/

clear
version 13

// read per patient data set
cd "${cleandata}"
use "IMAI_Rwanda_Complaints_Cleaned", replace

cd "${tables}/unformatted"
// table 1: summary statistics by treatment status
#delimit ;
table1 if endline == 0, by(imai_nurse)
  vars( tx_agree cate \
        dx_agree cate \
        pt_sex cate \
        pt_age contn \
        pulse cate \
        bp_dias cate \
        bp_sys cate \
        weight cate \
        temp cate \
        vitals_clerk cate \
        vitals_nurse cate \
        sign_check cate \
        level_educ cate \
        exp_opd contn \
        nobs contn \
        health_center cat \
	  )
  saving("table_01_desc_stats.xls", sheet("baseline") replace)
  plusminus
  format(%2.1f);
table1 if endline == 1, by(imai_nurse)
  vars( tx_agree cate \
        dx_agree cate \
        pt_sex cate \
        pt_age contn \
        pulse cate \
        bp_dias cate \
        bp_sys cate \
        weight cate \
        temp cate \
        vitals_clerk cate \
        vitals_nurse cate \
        sign_check cate \
        level_educ cate \
        exp_opd contn \
        nobs contn \
        health_center cat \
      )
  saving("table_01_desc_stats.xls", sheet("endline") replace)
  plusminus
  format(%2.1f);
#delimit cr

