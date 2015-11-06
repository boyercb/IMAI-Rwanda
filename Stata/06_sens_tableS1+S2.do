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
cap program drop margfx
program define margfx, rclass
	version 13
	syntax varlist(numeric min=3)
	marksample touse
	tokenize `varlist'
	tempvar Phat
	tempvar Phat_se
	predictnl Phat = (_b[`3'] + _b[`2']) * (1/ (1 + exp(-(_b[_cons] + _b[`1'] * `2' + _b[`2'] * `2' + _b[`3'] * `2')))) * (1 - (1/(1 + exp(-(_b[_cons] + _b[`1'] + _b[`2'] * `2' + _b[`3'] * `2'))))) - _b[`2'] * (1/(1 + exp(-(_b[_cons] + _b[`2'] * `2')))) * (1 - (1/(1 + exp(-(_b[_cons]+_b[`2']*`2'))))), se(Phat_se)
	quietly replace Phat = . if inlist(1, missing(tx_agree), missing(endline1), missing(imai_ever))
	quietly summ Phat
	local int_b `r(mean)'
	local int_N `r(N)'
	quietly summ Phat_se
	local int_se `r(mean)'
	local int_z = `int_b'/`int_se'
	local int_p = (1 - normal(`int_z'))*2
	return scalar b = `int_b'
	return scalar se = `int_se'
	return scalar z = `int_z'
	return scalar p = `int_p'
	drop Phat Phat_se
end


// read per patient data set
cd "${cleandata}"
use "IMAI_Rwanda_Complaints_Cleaned", replace

g end1Xever = imai_ever * endline1
preserve
// use multiple imputation to check if answers are robust to missing data
cd "${tables}/unformatted"
mi set wide
mi register imputed tx_agree dx_agree pt_age exp_opd
set seed 20151102
mi impute chained (logit) dx_agree tx_agree (regress) pt_age exp_opd = imai_ever endline1 end1Xever health_center nobs vitals_check, add(50)
mi xtset nurse_id
eststo clear
mi estimate, post: xtreg dx_agree i.imai_ever i.endline1 end1Xever i.pt_sex pt_age exp_opd i.level_educ nobs i.health_center, vce(robust)
eststo model1
mi estimate, post: xtreg tx_agree i.imai_ever i.endline1 end1Xever i.pt_sex pt_age exp_opd i.level_educ nobs i.health_center, vce(robust)
eststo model2
esttab using table_S1_MIsensitivity.csv, label wide se(2) b(2) ///
    title("Multiply imputed difference-in-difference estimates of effects of IMAI training of" ///
          "nurses on odds of proper diagnosis and treatment, Rwanda 2011-2012.") ///
    replace                                    ///
    depvars
eststo clear
restore
// use alternative model formulation (logit) to check if results are robust to functional form
xtset nurse_id

cd "${tables}/unformatted"

*erase "table_S2_logit.xml"
quietly xtlogit dx_agree imai_ever endline1 end1Xever, vce(robust)
margfx imai_ever endline1 end1Xever
matrix E=(`r(b)', `r(se)', `r(z)', `r(p)')
scalar star = cond(`r(p)' < 0.001, 1, cond(`r(p)' < 0.01, 2, cond(`r(p)' < 0.05, 3, 0)))
scalar zero = 0
matrix E_STARS = (star, zero, zero, zero)

quietly xtlogit tx_agree imai_ever endline1 end1Xever, vce(robust)
margfx imai_ever endline1 end1Xever
scalar star = cond(`r(p)' < 0.001, 1, cond(`r(p)' < 0.01, 2, cond(`r(p)' < 0.05, 3, 0)))
matrix E=nullmat(E)\(`r(b)', `r(se)', `r(z)', `r(p)')
matrix E_STARS = nullmat(E_STARS)\(star, zero, zero, zero)

quietly logit dx_agree imai_ever endline1 end1Xever, cluster(nurse_id)
margfx imai_ever endline1 end1Xever
scalar star = cond(`r(p)' < 0.001, 1, cond(`r(p)' < 0.01, 2, cond(`r(p)' < 0.05, 3, 0)))
matrix E=nullmat(E)\(`r(b)', `r(se)', `r(z)', `r(p)')
matrix E_STARS = nullmat(E_STARS)\(star, zero, zero, zero)

quietly logit tx_agree imai_ever endline1 end1Xever, cluster(nurse_id)
margfx imai_ever endline1 end1Xever
scalar star = cond(`r(p)' < 0.001, 1, cond(`r(p)' < 0.01, 2, cond(`r(p)' < 0.05, 3, 0)))
matrix E=nullmat(E)\(`r(b)', `r(se)', `r(z)', `r(p)')
matrix E_STARS = nullmat(E_STARS)\(star, zero, zero, zero)

quietly xtprobit dx_agree imai_ever endline1 end1Xever, vce(robust)
margfx imai_ever endline1 end1Xever
scalar star = cond(`r(p)' < 0.001, 1, cond(`r(p)' < 0.01, 2, cond(`r(p)' < 0.05, 3, 0)))
matrix E=nullmat(E)\(`r(b)', `r(se)', `r(z)', `r(p)')
matrix E_STARS = nullmat(E_STARS)\(star, zero, zero, zero)

quietly xtprobit tx_agree imai_ever endline1 end1Xever, vce(robust)
margfx imai_ever endline1 end1Xever
scalar star = cond(`r(p)' < 0.001, 1, cond(`r(p)' < 0.01, 2, cond(`r(p)' < 0.05, 3, 0)))
matrix E=nullmat(E)\(`r(b)', `r(se)', `r(z)', `r(p)')
matrix E_STARS = nullmat(E_STARS)\(star, zero, zero, zero)

quietly xtprobit dx_agree imai_ever endline1 end1Xever, vce(robust)
margfx imai_ever endline1 end1Xever
scalar star = cond(`r(p)' < 0.001, 1, cond(`r(p)' < 0.01, 2, cond(`r(p)' < 0.05, 3, 0)))
matrix E=nullmat(E)\(`r(b)', `r(se)', `r(z)', `r(p)')
matrix E_STARS = nullmat(E_STARS)\(star, zero, zero, zero)

quietly xtprobit tx_agree imai_ever endline1 end1Xever, vce(robust)
margfx imai_ever endline1 end1Xever
scalar star = cond(`r(p)' < 0.001, 1, cond(`r(p)' < 0.01, 2, cond(`r(p)' < 0.05, 3, 0)))
matrix E=nullmat(E)\(`r(b)', `r(se)', `r(z)', `r(p)')
matrix E_STARS = nullmat(E_STARS)\(star, zero, zero, zero)

local cnames `" "b" "SE" "z" "P-value" "'
local rnames `" "Diagnosis (logit RE robust)" "Treatment (logit RE robust)" "Diagnosis (logit clust)" "Treatment (logit clust)" "Diagnosis (probit RE robust)" "Treatment (probit RE robust)" "'

xml_tab E, save("table_S2_logit.xml") replace noisily cnames(`cnames') rnames(`rnames') font("Arial" 10) star(0.05 0.01 0.001) format((SCLR0) (SCCR0 NBCR2 NBCR2 NBCR2 NBCR2 NBCR2 NBCR2 NBCR2 NBCR2))


