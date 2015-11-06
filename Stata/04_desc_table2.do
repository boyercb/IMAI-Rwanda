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
use "IMAI_Rwanda_Complaints_Cleaned", replace


cd "${tables}/unformatted"
// table 2: summary statistics by time period and treatment status
#delimit ;
didtable, treated(imai_ever) period(endline1)
  vars("tx_agree bin \
        dx_agree bin \
        pt_sex bin \
        pt_age cont \
        duration cont \
        pulse cont \
        bp_dias bin \
        bp_sys bin \
        weight bin \
        height bin \
        temp bin \
        vitals_check bin \
        sign_check bin \
        level_educ bin \
        exp_opd cont \
        nobs cont \
        nurseask_cough bin \
        nurseask_weightloss bin \
        nurseask_pallor bin \
        nurseask_lesions bin \
        nurseask_penile bin \
        nurseask_scrotal bin \
        nurseask_net bin \
        nurseask_smoke bin \
        nurseask_alc bin \
        nurseask_sex bin \
        nurseask_preg bin \
        nurseask_fp bin \
        nurseask_hiv bin " )
  saving("table_02_desc_stats.xls", replace)
  cluster(nurse_id)
  plusminus;
#delimit cr
