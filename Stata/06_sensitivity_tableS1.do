/*------------------------------------*
 |file:    06_sensitivity_table_S1.do |
 |project: IMAI rwanda                |
 |author:  christopher boyer          |
 |date:    27 oct 2015                |
 *------------------------------------*
  description:
    this file creates table S1, an analysis of the sensitivity of the results
    to missing data using multiple imputations.
*/

clear
version 13

// read per patient data set
cd "${cleandata}"
use "IMAI_Rwanda_Complaints_Cleaned", replace

cd "${tables}/unformatted"
mi set wide
mi register imputed tx_agree dx_agree
set seed 20151102
mi impute mvn dx_agree tx_agree = imai_ever endline1, add(10)

eststo clear
mi estimate, or post: logit dx_agree i.imai_ever##i.endline1, cluster(nurse_id)
eststo model1
mi estimate, or post: logit tx_agree i.imai_ever##i.endline1, cluster(nurse_id)
eststo model2
esttab using table_S1_MIsensitivity.csv, label wide ci(2) b(2) ///
    title("Multiply imputed difference-in-difference estimates of effects of IMAI training of" ///
          "nurses on odds of proper diagnosis and treatment, Rwanda 2011-2012.") ///
    eform replace                                    ///
    depvars
eststo clear