/*-------------------------------*
 |file:    01_clean_and_code.do  |
 |project: IMAI rwanda           |
 |author:  christopher boyer     |
 |date:    26 oct 2015           |
 *-------------------------------*
  description:
    this file cleans and prepares raw data for analysis.
*/

clear
version 13

// read per patient data set
cd "${rawdata}"
import delimited using "IMAI_Rwanda_Patients.csv"

drop need* nurseask_refer* nurseask_cough_days nurseask_period_date nurseask_counsel*

// <=============== Section 1: Define labels for factor variables ================> //
label drop _all

#delimit ;
// yesno;
label define yesno
	0 "No"
    1 "Yes"
;
// healthcenter;
label define healthcenter
    0 "Cyarubare"
    1 "Kabarondo"
    2 "Karama"
    3 "Ndego"
    4 "Nyamirama"
    5 "Ruramira"
    6 "Rutare"
    7 "Rwinkwavu"
;
// educ;
label define educ
    0 "A1"
    1 "A2"
;
// tmonth;
label define tmonth
    0 "None"
    1 "March"
    2 "October"
;
// sex;
label define sex
    0 "Male"
    1 "Female"
;
// emclass;
label define emclass
    0 "Airway/breathing"
    1 "Fever"
    2 "Circulation/shock"
    3 "Pain"
    4 "Unconscious/convulsing"
    5 "None"
;
label define timeperiod
    0 "baseline"
    1 "endline"
;
// testresult;
label define testresult
	0 "Negative"
    1 "Positive"
;
#delimit cr

// <=============== Section 2: Recode values to standardize ================> //
foreach var of varlist nurseask_* {
	replace `var' = "" if `var' == "N/A"
	replace `var' = "Yes asked, symptom not present" if `var' == "Yes asked symptom not present"
	encode `var', generate(tmp)
	drop `var'
	g `var' = tmp
	drop tmp
	recode `var' (1 = 0) (2/3 = 1)
}

// replacements
replace vitals_clerk = 1 if vitals_clerk == -1
replace vitals_nurse = 1 if vitals_nurse == -1
replace vitals_other = 1 if vitals_other == -1
replace vitals_clerk = 0 if vitals_clerk == .
replace vitals_nurse = 0 if vitals_nurse == .
replace vitals_other = 0 if vitals_other == .
replace trainmonth = "" if nurse_id == 303
recode classagree1 (2 = 0)
recode classagree2 (2 = 0)
recode classagree3 (2 = 0)
recode treatagree1 (2 = 0)
recode treatagree2 (2 = 0)
recode treatagree3 (2 = 0)
recode pulse (miss = 0) (nonmiss = 1)
recode bp_dias (miss = 0) (nonmiss = 1)
recode bp_sys (miss = 0) (nonmiss = 1)
recode weight (miss = 0) (nonmiss = 1)
recode height (miss = 0) (nonmiss = 1)
recode temp (miss = 0) (nonmiss = 1)

// renames
rename classagree1 dx_agree1
rename classagree2 dx_agree2
rename classagree3 dx_agree3
rename treatagree1 tx_agree1
rename treatagree2 tx_agree2
rename treatagree3 tx_agree3

// change date and times to Stata internal formats
g dt = date(date_obs, "MD20Y")
drop date_obs
g date_obs = dt
drop dt
format date_obs %td

g tstart = clock(time_start, "hm")
g tend = clock(time_end, "hm")
g duration = (tend - tstart)/60000
drop time_start time_end

// generate nobs variable
sort nurse_id date_obs
by nurse_id: generate nobs = _n

// generate vitals variable
g vitals_check = 0
replace vitals_check = 1 if inlist(1, vitals_clerk, vitals_nurse, vitals_other)

// add a dummy indicating whether the visit was before or after intervention
g endline1 = 0
replace endline1 = 1 if date_obs >= date("03/01/11", "MD20Y")
g endline2 = 0
replace endline2 = 1 if date_obs >= date("10/01/11", "MD20Y")

// recast imai training variable as ever trained for DiD analysis
g imai_ever = 0
replace imai_ever = 1 if nurse_train_imai == "Yes"
egen imai_ever2 = max(imai_ever), by(nurse_id)
drop imai_ever
g imai_ever = imai_ever2
drop imai_ever2

g imai_mar = 0
replace imai_mar = 1 if inlist(nurse_id, 201, 305, 401, 501, 502, 503, 602, 704, 804)

g imai_oct = 0
replace imai_oct = 1 if inlist(nurse_id, 102, 103, 203, 204, 306, 508, 606, 803, 806)

// encone pt_sex
encode pt_sex, g(sex)
recode sex (2 = 0)
drop pt_sex
g pt_sex = sex
drop sex

replace dx_agree1 = 1 if (nursesis1 == mentorsis1) & missing(dx_agree1) & !missing(nursesis1)
replace dx_agree1 = 0 if (nursesis1 != mentorsis1) & missing(dx_agree1) & !missing(nursesis1)
replace dx_agree2 = 1 if (nursesis2 == mentorsis2) & missing(dx_agree2) & !missing(nursesis2)
replace dx_agree2 = 0 if (nursesis2 != mentorsis2) & missing(dx_agree2) & !missing(nursesis2)
replace dx_agree3 = 1 if (nursesis3 == mentorsis3) & missing(dx_agree3) & !missing(nursesis3)
replace dx_agree3 = 0 if (nursesis3 != mentorsis3) & missing(dx_agree3) & !missing(nursesis3)

// duplicates
duplicates drop nurse_id date_obs tstart tend pt_sex pt_age chief_complaint1 chief_complaint2 chief_complaint3, force

// <================= Section 3: Define variable codebook ==================> //

// variable descriptions
char id[description]                      "A unique identifier specifying a patient visit."
char health_center[description]           "The name of the health center in which the patient was treated."
char date_obs[description]                "The date of the patient visit."
char nurse_id[description]                "A unique identifier for the attending nurse."
char nurse_train_imai[description]        "A dummny specifying whether the nurse was IMAI trained at the time."
char trainmonth[description]              "The month in which the attending nurse was trained."
char level_educ[description]              "The highest level of education attained by the attending nurse."
char exp_opd[description]                 "The number of years of experience of the attending nurse."
char pt_age[description]                  "The age in years of the patient."
char pt_sex[description]                  "The sex of the patient."
char bp_dias[description]                 "The diastolic blood pressure of the patient in mm Hg."
char bp_sys[description]                  "The systolic blood pressure of the patient in mm Hg."
char temp[description]                    "The temperature of the patient during visit in degrees celsius."
char weight[description]                  "The weight of the patient at the time of the visit in kg."
char pulse[description]                   "The patient's pulse at the time of the visit in beats per minute."
char height[description]                  "The patient's height at the time of the visit in cm."
char duration[description]                "Length of the consultation in minutes."
char vitals_check[description]            "Vital signs were taken."
char sign_check[description]              "Nurse conducted emergency quick check protocol."
char nurse_class[description]             "Nurse classification of emergency."
char nurse_response[description]          "What did the nurse do after finding an emergency sign?"
char mentor_class[description]            "Mentor classification of emergency."
char mentor_response[description]         "What did/would the mentor do after finding an emergency sign?"
char reason_hc[description]               "Did the nurse ask for a chief complaint(s) specifically?"
char chief_complaint1[description]        "First complaint from patient history."
char chief_complaint2[description]        "Second complaint from patient history."
char chief_complaint3[description]        "Third complaint from patient history."
char mental_specific1[description]        "Write-in first specific mental health complaint."
char mental_specific2[description]        "Write-in second specific mental health complaint."
char mental_specific3[description]        "Write-in third specific mental health complaint."
char other_specific1[description]         "Write-in first specific other health complaint."
char other_specific2[description]         "Write-in second specific other health complaint."
char other_specific3[description]         "Write-in third specific other health complaint."
char nursesis1[description]               "Diagnosis code selected by nurse for first complaint."
char nursesis2[description]               "Diagnosis code selected by nurse for second complaint."
char nursesis3[description]               "Diagnosis code selected by nurse for third complaint."
char mentorsis1[description]              "Diagnosis code selected by mentor for first complaint."
char mentorsis2[description]              "Diagnosis code selected by mentor for second complaint."
char mentorsis3[description]              "Diagnosis code selected by mentor for third complaint."
char dx_agree1[description]               "Did the diagnoses selected by the nurse and mentor agree?"
char dx_agree2[description]               "Did the diagnoses selected by the nurse and mentor agree?"
char dx_agree3[description]               "Did the diagnoses selected by the nurse and mentor agree?"
char tx_agree1[description]               "Did the treatment recommendations selected by the nurese and mentor agree?"
char tx_agree2[description]               "Did the treatment recommendations selected by the nurese and mentor agree?"
char tx_agree3[description]               "Did the treatment recommendations selected by the nurese and mentor agree?"
char nobs[description]                    "The number of times the nurse was observed during the study."
char imai_ever[description]               "Dummy indicating whether the nurse was ever trained in IMAI."
char imai_mar[description]                "Dummy indicating whether the nurse was trained in IMAI in the March 2011 cohort."
char imai_oct[description]                "Dummy indicating whether the nurse was trained in IMAI in the October 2011 cohort."
char nurseask_cough[description]          "Nurse asks about history of cough"
char nurseask_weightloss[description]     "Nurse asks about history of recent weight loss"
char nurseask_pallor[description]         "Nurse asks about skin pallor"
char nurseask_lesions[description]        "Nurse asks about lesions"
char nurseask_penile[description]         "Nurse asks about history of urethral discharge"
char nurseask_scrotal[description]        "Nurse asks about history of scrotal pain or swelling"
char nurseask_net[description]            "Nurse asks about mosiquito net use"
char nurseask_smoke[description]          "Nurse asks about history of smoking"
char nurseask_alc[description]            "Nurse asks about history of alcohol use"
char nurseask_sex[description]            "Nurse asks about sexual history"
char nurseask_preg[description]           "Nurse asks about history of pregnancies"
char nurseask_fp[description]             "Nurse asks about current contraceptive use"
char nurseask_hiv[description]            "Nurse asks about hiv status"
char nurseask_hivtest_result[description] "Result of hiv test"
*char nurseask_counsel_net[description]    "Nurse counsels patient on mosiquito net"
*char nurseask_counsel_smoke[description]  "Nurse counsels patient on smoking cessation"
*char nurseask_counsel_alc[description]    "Nurse counsels patient on alcohol consumption"
*char nurseask_counsel_sex[description]    "Nurse counsels patient on safe sex"

// specify label to be added to variables
char health_center[code]           healthcenter
char trainmonth[code]              tmonth
char level_educ[code]              educ
char nurse_train_imai[code]        yesno
char vitals_check[code]            yesno
char sign_check[code]              yesno
char nurse_class[code]             emclass
char mentor_class[code]            emclass
char reason_hc[code]               yesno
char dx_agree1[code]               yesno
char dx_agree2[code]               yesno
char dx_agree3[code]               yesno
char tx_agree1[code]               yesno
char tx_agree2[code]               yesno
char tx_agree3[code]               yesno
char endline1[code]                timeperiod
char endline2[code]                timeperiod
char pulse[code]                   yesno
char bp_dias[code]                 yesno
char bp_sys[code]                  yesno
char weight[code]                  yesno
char height[code]                  yesno
char temp[code]                    yesno
char pt_sex[code]                  sex
char imai_ever[code]               yesno
char imai_mar[code]                yesno
char imai_oct[code]                yesno
char nurseask_cough[code]          yesno
char nurseask_weightloss[code]     yesno
char nurseask_pallor[code]         yesno
char nurseask_lesions[code]        yesno
char nurseask_penile[code]         yesno
char nurseask_scrotal[code]        yesno
char nurseask_net[code]            yesno
char nurseask_smoke[code]          yesno
char nurseask_alc[code]            yesno
char nurseask_sex[code]            yesno
char nurseask_preg[code]           yesno
char nurseask_fp[code]             yesno
char nurseask_hiv[code]            yesno
char nurseask_hivtest_result[code] testresult
*char nurseask_counsel_net[code]    yesno
*char nurseask_counsel_smoke[code]  yesno
*char nurseask_counsel_alc[code]    yesno
*char nurseask_counsel_sex[code]    yesno

// <================ Section 4: Apply value labels to factors =================> //

ds _all, has(char code)
foreach var in `r(varlist)' {
	local list : char `var'[code]
	capture confirm string variable `var', exact
	if !_rc {
		encode `var', generate(tmp) label(`list')
		drop `var'
		g `var' = tmp
		drop tmp
	}
	label values `var' `list'
}

cd "${cleandata}"
save "IMAI_Rwanda_Patients_Cleaned", replace

