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
eststo: quietly melogit dx_agree i.imai_ever##i.endline1 || nurse_id: , or
eststo: quietly melogit dx_agree i.imai_ever##i.endline1 i.pt_sex exp_opd nobs duration || nurse_id: , or
eststo: quietly melogit tx_agree i.imai_ever##i.endline1 || nurse_id: , or
eststo: quietly melogit tx_agree i.imai_ever##i.endline1 i.pt_sex exp_opd nobs duration || nurse_id: , or
esttab using table_03_DiD.csv, label wide se(2) b(2) ///
    title("Difference-in-difference estimates of effects of IMAI training of"    ///
          "nurses on odds of proper diagnosis and treatment, Rwanda 2011-2012.") ///
    replace                                    ///
    depvars
eststo clear

eststo: quietly melogit dx_agree i.imai_mar##i.endline1 i.pt_sex exp_opd nobs if imai_oct != 1 || nurse_id: , or
eststo: quietly melogit dx_agree i.imai_oct##i.endline2 i.pt_sex exp_opd nobs if imai_mar != 1 || nurse_id: , or
eststo: quietly melogit tx_agree i.imai_mar##i.endline1 i.pt_sex exp_opd nobs if imai_oct != 1 || nurse_id: , or
eststo: quietly melogit tx_agree i.imai_oct##i.endline2 i.pt_sex exp_opd nobs if imai_mar != 1 || nurse_id: , or
esttab using table_04_DiD_cohorts.csv, label wide se(2) b(2) ///
    title("Difference-in-difference estimates of effects of IMAI training of"    ///
          "nurses on odds of proper diagnosis and treatment, Rwanda 2011-2012.") ///
    replace                                    ///
    depvars
eststo clear
