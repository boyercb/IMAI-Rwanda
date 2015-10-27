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
#delimit cr

// <=============== Section 2: Recode values to standardize ================> //

// replacements
replace vitals_clerk = 1 if vitals_clerk == -1
replace vitals_nurse = 1 if vitals_nurse == -1
recode classagree1 (2 = 1) (1 = 0)
recode classagree2 (2 = 1) (1 = 0)
recode classagree3 (2 = 1) (1 = 0)
recode treatagree1 (2 = 1) (1 = 0)
recode treatagree2 (2 = 1) (1 = 0)
recode treatagree3 (2 = 1) (1 = 0)

generate imai_nurse = 0
replace imai_nurse = 1 if nurse_train_imai == "Yes"

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
char classagree1[description]      "Did the diagnoses selected by the nurse and mentor agree?"
char classagree2[description]      "Did the diagnoses selected by the nurse and mentor agree?"
char classagree3[description]      "Did the diagnoses selected by the nurse and mentor agree?"
char treatagree1[description]      "Did the treatment recommendations selected by the nurese and mentor agree?"
char treatagree2[description]      "Did the treatment recommendations selected by the nurese and mentor agree?"
char treatagree3[description]      "Did the treatment recommendations selected by the nurese and mentor agree?"

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
char classagree1[code] yesno
char classagree2[code] yesno
char classagree3[code] yesno
char treatagree1[code] yesno
char treatagree2[code] yesno
char treatagree3[code] yesno
char imai_nurse[code] yesno

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

