/*----------------------------------*
 |file:    07_figures.do            |
 |project: IMAI rwanda              |
 |author:  christopher boyer        |
 |date:    27 oct 2015              |
 *----------------------------------*
  description:
    this file creates figure 1, a paneled chart showing the
    changes in treatment and diagnosis agreement rates over time.
*/

clear
version 13

// read per patient data set
cd "${cleandata}"
use "IMAI_Rwanda_Complaints_Cleaned", replace

generate month = month(date_obs)
generate year = year(date_obs)
generate imai_now = 0
replace imai_now = 1 if imai_mar == 1 & endline1 == 1
replace imai_now = 1 if imai_oct == 1 & endline2 == 1
g mdate = mdy(month, 1, year)
g qdate = qofd(mdate)
g quarter = quarter(mdate)
g ndate = dofq(qdate)
format %td mdate ndate
format %tq qdate

sort date_obs
keep imai_ever dx_agree tx_agree month year qdate ndate quarter
collapse (mean) dx_agree tx_agree year quarter ndate, by(qdate imai_ever)

save "IMAI_monthly_rates.dta", replace

