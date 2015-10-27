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

drop nurseask* need*

// <=============== Section 1: Define labels for factor variables ================> //
label drop _all

#delimit ;
// yesno;
label define yesno
    1 "Yes"
	0 "No"
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
#delimit cr

// <=============== Section 2: Recode values to standardize ================> //

// replacements
replace vitals_clerk = 1 if vitals_clerk == -1
replace vitals_nurse = 1 if vitals_nurse == -1
replace vitals_other = 1 if vitals_other == -1
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

// change date to Stata internal date format
g dt = date(date_obs, "MD20Y")
drop date_obs
g date_obs = dt
drop dt
format date_obs %td

// generate nobs variable
sort nurse_id date_obs
egen nobs = count(id), by(nurse_id)

// add a dummy indicating whether the visit was before or after intervention
g endline = 0
replace endline = 1 if date_obs >= date("3/31/11", "MD20Y")

// recast imai training variable as ever trained for DiD analysis
generate imai_nurse = 0
replace imai_nurse = 1 if nurse_train_imai == "Yes"
egen imai_nurse2 = max(imai_nurse), by(nurse_id)
drop imai_nurse
g imai_nurse = imai_nurse2
drop imai_nurse2

// encone pt_sex
encode pt_sex, g(sex)
recode sex (2 = 0)
drop pt_sex
g pt_sex = sex
drop sex

// <================= Section 3: Define variable codebook ==================> //

// variable descriptions
char id[description]               "A unique identifier specifying a patient visit."
char health_center[description]    "The name of the health center in which the patient was treated."
char date_obs[description]         "The date of the patient visit."
char nurse_id[description]         "A unique identifier for the attending nurse."
char time_start[description]       "The time at which the patient visit started."
char time_end[description]         "The time at which the patient visit concluded."
char nurse_train_imai[description] "A dummny specifying whether the nurse was IMAI trained at the time."
char trainmonth[description]       "The month in which the attending nurse was trained."
char level_educ[description]       "The highest level of education attained by the attending nurse."
char exp_opd[description]          "The number of years of experience of the attending nurse."
char pt_age[description]           "The age in years of the patient."
char pt_sex[description]           "The sex of the patient."
char bp_dias[description]          "The diastolic blood pressure of the patient in mm Hg."
char bp_sys[description]           "The systolic blood pressure of the patient in mm Hg."
char temp[description]             "The temperature of the patient during visit in degrees celsius."
char weight[description]           "The weight of the patient at the time of the visit in kg."
char pulse[description]            "The patient's pulse at the time of the visit in beats per minute."
char height[description]           "The patient's height at the time of the visit in cm."
char vitals_clerk[description]     "Vital signs were taken by registration clerk."
char vitals_nurse[description]     "Vital signs were taken by nurse."
char vitals_other[description]     "Vital signs were taken by other staff."
char sign_check[description]       "Nurse conducted emergency quick check protocol."
char nurse_class[description]      "Nurse classification of emergency."
char nurse_response[description]   "What did the nurse do after finding an emergency sign?"
char mentor_class[description]     "Mentor classification of emergency."
char mentor_response[description]  "What did/would the mentor do after finding an emergency sign?"
char reason_hc[description]        "Did the nurse ask for a chief complaint(s) specifically?"
char chief_complaint1[description] "First complaint from patient history."
char chief_complaint2[description] "Second complaint from patient history."
char chief_complaint3[description] "Third complaint from patient history."
char mental_specific1[description] "Write-in first specific mental health complaint."
char mental_specific2[description] "Write-in second specific mental health complaint."
char mental_specific3[description] "Write-in third specific mental health complaint."
char other_specific1[description]  "Write-in first specific other health complaint."
char other_specific2[description]  "Write-in second specific other health complaint."
char other_specific3[description]  "Write-in third specific other health complaint."
char nursesis1[description]        "Diagnosis code selected by nurse for first complaint."
char nursesis2[description]        "Diagnosis code selected by nurse for second complaint."
char nursesis3[description]        "Diagnosis code selected by nurse for third complaint."
char mentorsis1[description]       "Diagnosis code selected by mentor for first complaint."
char mentorsis2[description]       "Diagnosis code selected by mentor for second complaint."
char mentorsis3[description]       "Diagnosis code selected by mentor for third complaint."
char dx_agree1[description]        "Did the diagnoses selected by the nurse and mentor agree?"
char dx_agree2[description]        "Did the diagnoses selected by the nurse and mentor agree?"
char dx_agree3[description]        "Did the diagnoses selected by the nurse and mentor agree?"
char tx_agree1[description]        "Did the treatment recommendations selected by the nurese and mentor agree?"
char tx_agree2[description]        "Did the treatment recommendations selected by the nurese and mentor agree?"
char tx_agree3[description]        "Did the treatment recommendations selected by the nurese and mentor agree?"
char nobs[description]             "The number of times the nurse was observed during the study."

// specify label to be added to variables
char health_center[code] healthcenter
char trainmonth[code] tmonth
char level_educ[code] educ
char nurse_train_imai[code] yesno
char vitals_clerk[code] yesno
char vitals_nurse[code] yesno
char vitals_other[code] yesno
char sign_check[code] yesno
char nurse_class[code] emclass
char mentor_class[code] emclass
char reason_hc[code] yesno
char dx_agree1[code] yesno
char dx_agree2[code] yesno
char dx_agree3[code] yesno
char tx_agree1[code] yesno
char tx_agree2[code] yesno
char tx_agree3[code] yesno
char imai_nurse[code] yesno
char endline[code] timeperiod
char pulse[code] yesno
char bp_dias[code] yesno
char bp_sys[code] yesno
char weight[code] yesno
char height[code] yesno
char temp[code] yesno
char pt_sex[code] sex

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

