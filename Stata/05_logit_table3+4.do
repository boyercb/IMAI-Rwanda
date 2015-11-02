/*--------------------------------*
 |file:    05_logistic_tableS1.do |
 |project: IMAI rwanda            |
 |author:  christopher boyer      |
 |date:    27 oct 2015            |
 *--------------------------------*
  description:
    this file creates table 1, a descriptive statistics summary table.
*/

clear
version 13

// read per patient data set
cd "${cleandata}"
use "IMAI_Rwanda_Complaints_Cleaned", replace

cd "${tables}/unformatted"
eststo clear
eststo: quietly logit dx_agree i.imai_ever##i.endline1, cluster(nurse_id) or
eststo: quietly logit dx_agree i.imai_ever##i.endline1 i.pt_sex pt_age exp_opd nobs, cluster(nurse_id) or
eststo: quietly logit tx_agree i.imai_ever##i.endline1, cluster(nurse_id) or
eststo: quietly logit tx_agree i.imai_ever##i.endline1 i.pt_sex pt_age exp_opd nobs, cluster(nurse_id) or
esttab using table_03_DiD.csv, label wide ci(2) b(2) ///
    title("Difference-in-difference estimates of effects of IMAI training of"    ///
          "nurses on odds of proper diagnosis and treatment, Rwanda 2011-2012.") ///
    eform replace                                    ///
    scalars(ll_0 ll chi2)                            ///
    depvars
eststo clear

g end1Xmar = imai_mar * endline1
g end2Xmar = imai_mar * endline2
g end1Xoct = imai_oct * endline1
g end2Xoct = imai_oct * endline2
eststo: quietly logit dx_agree imai_mar imai_oct endline1 endline2 end1Xmar end1Xoct end2Xmar end2Xoct, cluster(nurse_id) or
eststo: quietly logit tx_agree imai_mar imai_oct endline1 endline2 end1Xmar end1Xoct end2Xmar end2Xoct, cluster(nurse_id) or
esttab using table_04_DiD_cohorts.csv, label wide ci(2) b(2) ///
    title("Difference-in-difference estimates of effects of IMAI training of"    ///
          "nurses on odds of proper diagnosis and treatment, Rwanda 2011-2012.") ///
    eform replace                                    ///
    depvars
eststo clear
