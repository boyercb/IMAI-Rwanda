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

sort date_obs
keep imai_now dx_agree tx_agree month year
collapse (mean) dx_agree tx_agree, by(month year imai_now)
g mdate = mdy(month, 1, year)

format %td mdate
save "IMAI_monthly_rates.dta", replace

