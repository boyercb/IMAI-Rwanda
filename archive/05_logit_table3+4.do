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

g exp = 0
replace exp = 1 if exp_opd >= 4
replace exp = . if missing(exp_opd)


g end1Xever = imai_ever * endline1
xtset nurse_id
cd "${tables}/unformatted"
eststo clear
eststo: quietly xtreg dx_agree i.imai_ever i.endline1 i.end1Xever, vce(robust)
eststo: quietly xtreg dx_agree i.imai_ever i.endline1 i.end1Xever i.pt_sex pt_age i.exp nobs i.health_center, vce(robust)
eststo: quietly xtreg tx_agree i.imai_ever i.endline1 i.end1Xever, vce(robust)
eststo: quietly xtreg tx_agree i.imai_ever i.endline1 i.end1Xever i.pt_sex pt_age i.exp nobs i.health_center, vce(robust)
esttab using table_03_DiD.csv, label wide ci(2) b(2) ///
    title("Difference-in-difference estimates of effects of IMAI training of"    ///
          "nurses on odds of proper diagnosis and treatment, Rwanda 2011-2012.") ///
    replace                                    ///
    depvars
eststo clear

cd "${tables}/unformatted"
eststo clear
eststo: quietly xtreg dx_agree i.imai_ever i.endline1 i.end1Xever, cluster(health_center)
eststo: quietly xtreg dx_agree i.imai_ever i.endline1 i.end1Xever i.pt_sex pt_age i.exp nobs, cluster(health_center)
eststo: quietly xtreg tx_agree i.imai_ever i.endline1 i.end1Xever, cluster(health_center)
eststo: quietly xtreg tx_agree i.imai_ever i.endline1 i.end1Xever i.pt_sex pt_age i.exp nobs, cluster(health_center)
esttab using table_03_DiD.csv, label wide ci(2) b(2) ///
    title("Difference-in-difference estimates of effects of IMAI training of"    ///
          "nurses on odds of proper diagnosis and treatment, Rwanda 2011-2012.") ///
    replace                                    ///
    depvars
eststo clear


cd "${tables}/unformatted"
eststo clear
quietly xtlogit dx_agree i.imai_ever i.endline1 i.end1Xever, cluster(robust)
quietly xtlogit dx_agree i.imai_ever i.endline1 i.end1Xever i.pt_sex pt_age i.exp nobs, vce(robust)
quietly xtlogit tx_agree i.imai_ever i.endline1 i.end1Xever, vce(robust)
quietly xtlogit tx_agree i.imai_ever i.endline1 i.end1Xever i.pt_sex pt_age i.exp nobs, vce(robust)
esttab using table_03_DiD.csv, label wide ci(2) b(2) ///
    title("Difference-in-difference estimates of effects of IMAI training of"    ///
          "nurses on odds of proper diagnosis and treatment, Rwanda 2011-2012.") ///
    replace                                    ///
    depvars
eststo clear
g ask = nurseask_cough + nurseask_weightloss + nurseask_pallor + nurseask_lesions + nurseask_net + nurseask_smoke + nurseask_alc + nurseask_sex + nurseask_hiv
