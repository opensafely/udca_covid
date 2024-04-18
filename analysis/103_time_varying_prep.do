/*==============================================================================
DO FILE NAME:			103_time_varying_prep.do
DATE: 					26/06/2023
AUTHOR:					R Costello 
DESCRIPTION OF FILE:	Create time-varying covariates - this script updates time-
                        varying variables every 6 months or when exposure changes.
==============================================================================*/
adopath + ./analysis/ado 

* Open a log file
cap log using ./logs/time_varying.log, replace

tempfile tempfile 
import delimited using ./output/input_pbc.csv
describe
save `tempfile' 

/* Time-varying covariates are assessed 6-monthly and at time of exposure switching.
As disease severity, covid vaccination and liver transplant will only switch once need to identify
nearest date after date identified in study definition */ 
* 120 day file: primary exposure definition 
use ./output/time_varying_udca_120, clear 
codebook patient_id
merge m:1 patient_id using `tempfile', keepusing(severe_disease_fu_date severe_disease_bl covid_vacc_first_date liver_transplant_fu_date dereg_date died_date_ons)
* Should only be required for dummy data 
keep if _merge==3
* Only using start date as this is when udca exposure or 6 monthly check occurs
drop stop
* Add in rows with each of the 6 monthly assessment dates 
gen expand=1
bys patient_id (start): replace expand=6 if _n==_N 
expand expand, generate(newv)
bys patient_id newv: gen number = _n 
replace start = date("01/09/2020", "DMY") if newv==1 & number==1
replace start = date("01/03/2021", "DMY") if newv==1 & number==2
replace start = date("01/09/2021", "DMY") if newv==1 & number==3
replace start = date("01/03/2022", "DMY") if newv==1 & number==4
replace start = date("01/09/2022", "DMY") if newv==1 & number==5

* This gives a file where start dates are either exposure switching or 6-montly assessment dates 
* These will be used to determine the closest date to time-varying covariate dates identified in study definition 
sort patient_id start 
drop newv

* Determine end of follow-up date
gen dereg_dateA = date(dereg_date, "YMD")
format %dD/N/CY dereg_dateA
drop dereg_date
gen died_dateA = date(died_date_ons, "YMD")
format %dD/N/CY died_dateA
drop died_date_ons
gen end_study = date("31/12/2022", "DMY")
egen end_date = rowmin(dereg_dateA end_study died_dateA)

* Take out assessments after end_date 
drop if start>end_date

* Determine number of days between each covariate and dates of UDCA change or 6 monthly check date 
bys patient_id (start): egen last_assess = max(start)
* Format dates  and identify date nearest after covariate updates 
foreach var in covid_vacc_first_date severe_disease_fu_date liver_transplant_fu_date {
    gen `var'A = date(`var', "YMD")
    format `var'A %dD/N/CY 
    drop `var'
    * time between date of record and change in covariate - positive values are those where record starts after 
    * covariate change date 
    gen time_`var' = start - `var'A
    * Set time variable for records prior to change as missing
    replace time_`var'=. if time_`var'<0
    * Check if any are on index date (1st March) potentially severe disease - not others
    di "Number where time-varying update same as assessment date"
    count if time_`var'==0
    di "Number where time-varying update is 1st March 2020"
    count if `var'A==date("01/03/2020", "DMY")
    * Find earliest start date after covariate update
    * Note: there are some changes that occur after the last available 6 month assessment or exposure change
    bys patient_id (time_`var'): gen `var'_updateN = start[1] if `var'A!=. & time_`var'!=.
    * Spread to all rows for patient 
    bys patient_id: egen `var'_update = max(`var'_updateN)
    format `var'_update %dD/N/CY 
    di "Number where new variable is prior to original variable (should be 0)"
    count if `var'_update < `var'A
    di "Number where time varying update is after last assessment date"
    count if `var'A > last_assess & `var'A!=.  & last_assess==start
    di "Number of time-varying changes originally" 
    * Using last_assess==start to count patients rather than rows
    count if `var'A!=. & last_assess==start 
    di "Number of dates for time-varying update"
    count if `var'_update!=. & last_assess==start & `var'A!=.
}
* For severe disease only update variable if no severe disease at baseline 
count if severe_disease_fu_date_update==date("01/03/2020", "DMY") & severe_disease_bl!=1 
tab severe_disease_bl
replace severe_disease_fu_date_update = . if severe_disease_bl==1

* Keep only change dates to create time-varying dataset
keep patient_id covid_vacc_first_date_update severe_disease_fu_date_update liver_transplant_fu_date_update severe_disease_bl end_date
* Chercking number of patient_id's 
codebook patient_id
duplicates drop 
codebook patient_id
count
* Create file for each covariate to merge onto udca exposure file 
* First covid vaccination and liver transplant as all people will begin at zero 
rename liver_transplant_fu_date_update liver_trans_date_update
foreach var in covid_vacc_first liver_trans {
    preserve
    keep patient_id `var'_date_update end_date
    * Drop updates after the end of follow-up 
    count if `var'_date>=end_date 
    replace `var'_date = . if `var'_date>=end_date 
    * Flag if variable is updated
    gen `var'=(`var'_date_update!=.)
    * Create extra row if variable is updated 
    gen expand = `var'+1
    tab expand
    expand expand, gen(newv)
    * Update variables so row for when zero and row for when updated - if not updated whole time will be zero 
    gen start = date("01/03/2020", "DMY") if newv==0
    replace start = `var'_date_update if newv==1
    gen stop = `var'_date_update if newv==0
    replace stop = end_date if stop==.
    replace `var'=0 if newv==0
    save ./output/tv_`var'_check, replace
    keep patient_id `var' start stop
    * Check data 
    count if start==stop 
    * drop where start is same as stop - should not drop any in real data 
    drop if start==stop 
    count if stop<start
    codebook patient_id
    save ./output/tv_`var', replace
    restore
}

* Same for liver disease severity, but variable can start at 1 and remain for whole of follow-up 
preserve
keep patient_id severe_disease_fu_date_update end_date severe_disease_bl
* Drop updates after the end of follow-up 
replace severe_disease_fu_date_update=. if severe_disease_fu_date_update>=end_date 
* Flag if variable is updated
gen severe_disease=(severe_disease_fu_date_update!=.)
tab severe_disease 
replace severe_disease = 0 if severe_disease_bl==1
* Create extra row if variable is updated 
gen expand = severe_disease + 1
tab expand
expand expand, gen(newv)
tab newv
* Update variables so row for when zero and row for when updated - if not updated whole time will be zero 
gen start = date("01/03/2020", "DMY") if newv==0
replace start = severe_disease_fu_date_update if newv==1
gen stop = severe_disease_fu_date_update if newv==0 & severe_disease==1
count if stop!=.
replace stop = end_date if stop==. 
count if stop==.
replace severe_disease=0 if newv==0 & severe_disease_bl==0
replace severe_disease=1 if newv==0 & severe_disease_bl==1
save ./output/tv_severe_disease_check, replace
keep patient_id severe_disease start stop
* Check data 
count if start==stop
* drop if start is same as stop - should not drop any in real data 
drop if start==stop 
count if stop<start
codebook patient_id
save ./output/tv_severe_disease, replace
restore

* Make age time-varying i.e. updating on 1st January each year
use `tempfile', clear 
* Determine end of follow-up date
gen dereg_dateA = date(dereg_date, "YMD")
format %dD/N/CY dereg_dateA
drop dereg_date
gen died_dateA = date(died_date_ons, "YMD")
format %dD/N/CY died_dateA
drop died_date_ons
* Determine end of follow-up then add rows to update age for each year of follow-up
gen end_study = date("31/12/2022", "DMY")
egen end_date = rowmin(dereg_dateA end_study died_dateA)
keep patient_id age end_date
gen yr_end = year(end_date)
* Add rows to update age
gen expand = 3 if yr_end==2022
replace expand = 2 if yr_end==2021
replace expand = 1 if yr_end==2020
tab expand, m
expand expand, gen(newv)
tab newv, nolabel
bys patient_id newv: gen number = _n 
tab newv number, nolabel
gen start = date("01/03/2020", "DMY") if newv==0
replace start = date("01/01/2021", "DMY") if newv==1 & number==1
replace start = date("01/01/2022", "DMY") if newv==1 & number==2
gen stop = date("01/01/2021", "DMY") if newv==0 
replace stop = end_date if newv==0 & end_date<stop 
replace stop = date("01/01/2022", "DMY") if newv==1 & number==1 
replace stop = end_date if newv==1 & number==1 & end_date<stop
replace stop = date("31/12/2022", "DMY") if newv==1 & number==2 
replace stop = end_date if newv==1 & number==2 & end_date<stop
gen age_tv = age if newv==0
replace age_tv = age+1 if newv==1 & number==1
replace age_tv = age+2 if newv==1 & number==2
keep patient_id start stop age_tv 
drop if start==stop
codebook patient_id
save ./output/tv_age, replace 

* COVID waves 
use `tempfile', clear
* Determine end of follow-up date
gen dereg_dateA = date(dereg_date, "YMD")
format %dD/N/CY dereg_dateA
drop dereg_date
gen died_date_onsA = date(died_date_ons, "YMD")
format %dD/N/CY died_date_onsA
drop died_date_ons
* Determine end of follow-up then add rows to update waves 
gen end_study = date("31/12/2022", "DMY")
egen end_date = rowmin(dereg_dateA end_study died_date_onsA)
gen expand = 1 if end_date <= date("31/08/2020", "DMY")
replace expand = 2 if end_date <= date("30/06/2021", "DMY") & expand==.
replace expand = 3 if end_date <= date("30/11/2021", "DMY") & expand==.
replace expand = 4 if end_date <= date("31/12/2022", "DMY") & expand==.
tab expand 
keep patient_id expand end_date
expand expand, gen(newv) 
tab newv 
bys patient_id newv: gen number = _n 
* wave 1 row 
gen start = date("01/03/2020", "DMY") if newv==0
gen wave = 1 if newv==0
gen stop = date("01/09/2020", "DMY") if newv==0 
replace stop = end_date if end_date<stop & wave==1
tab expand if stop==end_date & wave==1
* wave 2 row
replace start = date("01/09/2020", "DMY") if newv==1 & number==1
replace wave = 2 if newv==1 & number==1
replace stop = date("01/07/2021", "DMY") if newv==1 & number==1
replace stop = end_date if end_date<stop & wave==2
* wave 3 row 
replace start = date("01/07/2021", "DMY") if newv==1 & number==2
replace wave = 3 if newv==1 & number==2
replace stop = date("01/12/2021", "DMY") if newv==1 & number==2
replace stop = end_date if end_date<stop & wave==3
* wave 4 row 
replace start = date("01/12/2021", "DMY") if newv==1 & number==3
replace wave = 4 if newv==1 & number==3
replace stop = date("31/12/2022", "DMY") if newv==1 & number==3
replace stop = end_date if end_date<stop & wave==4
keep patient_id start stop wave
drop if start==stop 
codebook patient_id
save ./output/tv_waves, replace

* Create files for outcomes
use `tempfile', clear
* Determine end of follow-up date
foreach var in died_date_ons hosp_covid_primary hosp_covid_any dereg_date {
    gen `var'A = date(`var', "YMD")
    format `var'A %dD/N/CY
    drop `var'
    gen yr_`var' = year(`var'A)
    tab yr_`var'
    replace `var'A=. if yr_`var'==2023
}
gen end_study = date("31/12/2022", "DMY")
egen end_date = rowmin(dereg_dateA end_study died_date_onsA)

* Create flag indicating reason for end of follow-up 
gen end_date_flag = (end_date==dereg_dateA)
replace end_date_flag = 2 if end_date==died_date_onsA
replace end_date_flag = 3 if end_date==end_study
replace died_date_onsA=. if end_date<died_date_onsA
replace died_ons_covid_flag_any=0 if end_date<died_date_onsA & died_ons_covid_flag_any==1
replace hosp_covid_anyA=. if end_date<hosp_covid_anyA
gen hosp_any_flag = hosp_covid_anyA!=.

* Composite outcome 
gen hosp_died_composite = (died_ons_covid_flag_any==1 | hosp_any_flag==1)
egen hosp_died_dateA = rowmin(died_date_onsA hosp_covid_anyA)
replace hosp_died_dateA=. if hosp_died_composite==0

* Check how composite is made up 
tab died_ons_covid_flag_any hosp_any_flag
di "Number where composite date = death date only"
count if hosp_died_dateA==died_date_onsA & hosp_died_dateA!=. & hosp_died_dateA!=hosp_covid_anyA
di "Number where composite = hospitalisation date only"
count if hosp_died_dateA==hosp_covid_anyA & hosp_died_dateA!=. & hosp_died_dateA!=died_date_onsA
di "Number where composite = both death and hospitalisation date 
count if hosp_died_dateA==died_date_onsA & hosp_died_dateA!=. & hosp_died_dateA==hosp_covid_anyA

* Make file for each outcome: covid death, hospitalisation and composite 
* Files contain patient ID, start = start study, stop = either end date for patient or date of outcome 
* and flag for outcome 
* COVID death - covid code in any position
preserve 
keep patient_id end_date died_ons_covid_flag_any died_date_onsA
gen start = date("01/03/2020", "DMY")
egen stop = rowmin(died_date_onsA end_date)
count if died_ons_covid_flag_any ==1 & end_date<died_date_onsA
replace died_ons_covid_flag_any=0 if end_date<died_date_onsA
keep patient_id start stop died_ons_covid_flag_any
rename died_ons_covid_flag_any died_covid_any_flag
save ./output/tv_outcome_died_covid_any, replace 
tab died_covid_any_flag, m
codebook patient_id
restore 

* Hospitalisation - covid code in any position
preserve 
keep patient_id end_date hosp_any_flag hosp_covid_anyA end_date_flag
gen start = date("01/03/2020", "DMY")
egen stop = rowmin(hosp_covid_anyA end_date)
count if hosp_any_flag ==1 & end_date<hosp_covid_anyA
tab end_date_flag if hosp_any_flag ==1 & end_date<hosp_covid_anyA
replace hosp_any_flag=0 if end_date<hosp_covid_anyA
keep patient_id start stop hosp_any_flag
save ./output/tv_outcome_hosp_any, replace 
tab hosp_any_flag, m
codebook patient_id
count
bys patient_id: egen total_hosp = total(hosp_any_flag)
tab total_hosp
restore 

* Composite 
preserve 
keep patient_id hosp_died* end_date
gen start = date("01/03/2020", "DMY")
egen stop = rowmin(hosp_died_dateA end_date)
count if hosp_died_composite==1 & end_date<hosp_died_dateA
replace hosp_died_composite=0 if end_date<hosp_died_dateA
keep patient_id start stop hosp_died_composite
rename hosp_died_composite composite_any_flag
save ./output/tv_outcome_composite_any, replace 
tab composite_any_flag, m
codebook patient_id
restore 

* Merge files together for each outcome
* Composite  
use ./output/tv_severe_disease, clear 
tvc_merge start stop using ./output/tv_covid_vacc_first, id(patient_id)
tvc_merge start stop using ./output/tv_liver_trans, id(patient_id)
tvc_merge start stop using ./output/time_varying_udca_120, id(patient_id)
tvc_merge start stop using ./output/tv_age, id(patient_id)
tvc_merge start stop using ./output/tv_outcome_composite_any, id(patient_id) failure(composite_any_flag)
* Dummy drug data includes people not in cohort, so drop these - should not be any in real data 
drop if age_tv==.
codebook patient_id
* Check number of outcomes after merge  - there will be missings for rows after event
tab composite_any_flag, m
missings report
drop if composite_any_flag==.
save ./output/tv_vars_composite_any, replace 

* COVID death - covid code in any position
use ./output/tv_severe_disease, clear 
tvc_merge start stop using ./output/tv_covid_vacc_first, id(patient_id)
tvc_merge start stop using ./output/tv_liver_trans, id(patient_id)
tvc_merge start stop using ./output/time_varying_udca_120, id(patient_id)
tvc_merge start stop using ./output/tv_age, id(patient_id)
tvc_merge start stop using ./output/tv_outcome_died_covid_any, id(patient_id) failure(died_covid_any_flag)
* Dummy drug data includes people not in cohort, so drop these - should not be any in real data 
drop if age_tv==.
codebook patient_id
* Check number of outcomes after merge 
tab died_covid_any_flag, m
missings report
save ./output/tv_vars_died_covid_any, replace 

* COVID hospitalisation - covid code in any position
use ./output/tv_severe_disease, clear 
tvc_merge start stop using ./output/tv_covid_vacc_first, id(patient_id)
tvc_merge start stop using ./output/tv_liver_trans, id(patient_id)
tvc_merge start stop using ./output/time_varying_udca_120, id(patient_id)
tvc_merge start stop using ./output/tv_age, id(patient_id)
tvc_merge start stop using ./output/tv_outcome_hosp_any, id(patient_id) failure(hosp_any_flag)
* Check number of outcomes after merge 
tab hosp_any_flag, m
bys patient_id: egen total_hosp = total(hosp_any_flag)
tab total_hosp
* Dummy drug data includes people not in cohort, so drop these - should not be any in real data 
drop if age_tv==.
codebook patient_id
* Check number of outcomes after merge - there will be missings for rows after event
tab hosp_any_flag, m 
missings report
drop if hosp_any_flag==.
save ./output/tv_vars_hosp_any, replace 

/* Format file with static covariates: sex, region, covid high risk conditions, 
ethnicity, imd, bmi, smoking. */

** Need to decide on second line therapies 
use `tempfile', clear
describe 
* Format variables 
* Sex
gen male = 1 if sex == "M"
replace male = 0 if sex == "F"
* Ethnicity
replace ethnicity=6 if ethnicity==0
label define eth5 			1 "White"  					///
                            2 "Mixed"				///						
                            3 "Asian"  					///
                            4 "Black"					///
                            5 "Other"					///
                            6 "Unknown"
                    

label values ethnicity eth5
safetab ethnicity, m
* Create White vs non-White ethnicity variable
gen eth_bin = (ethnicity!=1)
replace eth_bin = 2 if ethnicity==6
label define eth_3 0 "White" 1 "Non-White" 2 "Unknown"
label values eth_bin eth_3
tab eth_bin ethnicity, m 


* IMD - should not be missing (i.e. 0) in real data
replace imd=6 if imd==0

* BMI categories
* assume BMI's less than 10 are incorrect and set to missing 
sum bmi, d 
replace bmi = . if bmi<10
egen bmi_cat = cut(bmi), at(0, 1, 18.5, 24.9, 29.9, 39.9, 100) icodes
bys bmi_cat: sum bmi
* assume missing . is healthy range BMI
replace bmi_cat = 2 if bmi_cat==. 
label define bmi 1 "Underweight" 2 "Healthy range" 3 "Overweight" 4 "Obese" 5 "Morbidly obese"
label values bmi_cat bmi
tab bmi_cat 

* Smoking status - assume missings are non-smokers 
gen smoking = 0 if smoking_status=="N"
replace smoking = 1 if smoking_status=="S"
replace smoking = 2 if smoking_status=="E"
replace smoking = 1 if smoking==.
label define smok 1 "Current smoker" 2 "Ex-smoker" 0 "Never smoked" 
label values smoking smok
tab smoking 

* High risk covid conditions
replace oral_steroid_drugs_nhsd=. if oral_steroid_drug_nhsd_3m_count < 2 & oral_steroid_drug_nhsd_12m_count < 4
gen imid_nhsd=max(oral_steroid_drugs_nhsd, immunosuppresant_drugs_nhsd)
gen rare_neuro_nhsd = max(multiple_sclerosis_nhsd, motor_neurone_disease_nhsd, myasthenia_gravis_nhsd, huntingtons_disease_nhsd)
gen solid_organ_transplant_bin = solid_organ_transplant_nhsd_new!=""
gen any_high_risk_condition = max(learning_disability_nhsd_snomed, cancer_opensafely_snomed_new, haematological_disease_nhsd, ///
ckd_stage_5_nhsd, imid_nhsd, immunosupression_nhsd_new, hiv_aids_nhsd, solid_organ_transplant_bin, rare_neuro_nhsd)

* Time from most recent vaccination on 1st March 2021
gen date_most_recent_cov_vacA = date(date_most_recent_cov_vac, "YMD")
gen time_vacc = date("01Mar2021", "DMY") - date_most_recent_cov_vacA
sum time_vacc, d
xtile time_vacc_cat = time_vacc, nq(4)
replace time_vacc_cat = 5 if time_vacc_cat == .
bys time_vacc_cat: sum time_vacc 
label define vacc_t 1 "Q1 closest vaccination" 2 "Q2" 3 "Q3" 4 "Q4 furthest vaccination" 5 "No vaccination" 
label values time_vacc_cat vacc_t 

* Exploring death by liver disease 
gen died_liver_any = died_ons_liver_flag_any==1 & died_ons_covid_flag_any!=1
gen died_liver_underlying = died_ons_liver_flag_underlying==1 & died_ons_covid_flag_any!=1

keep patient_id male stp any_high_risk_condition ethnicity imd bmi_cat smoking eth_bin time_vacc_cat has_pbc oca_bl died_liver_any died_liver_underlying
tempfile basefile
save `basefile'
foreach var in died_covid_any hosp_any composite_any {
    preserve 
    merge 1:m patient_id using ./output/tv_vars_`var' 
    drop _merge 
    save ./output/an_dataset_`var', replace
    restore
}

*****************************************
* 90 day file: sensitivity analysis 
use ./output/time_varying_udca_90, clear 
codebook patient_id
merge m:1 patient_id using `tempfile', keepusing(severe_disease_fu_date severe_disease_bl covid_vacc_first_date liver_transplant_fu_date dereg_date died_date_ons)
* Should only be required for dummy data 
keep if _merge==3
* Only using start date as this is when udca exposure or 6 monthly check occurs
drop stop
* Add in rows with each of the 6 monthly assessment dates 
gen expand=1
bys patient_id (start): replace expand=6 if _n==_N 
expand expand, generate(newv)
bys patient_id newv: gen number = _n 
replace start = date("01/09/2020", "DMY") if newv==1 & number==1
replace start = date("01/03/2021", "DMY") if newv==1 & number==2
replace start = date("01/09/2021", "DMY") if newv==1 & number==3
replace start = date("01/03/2022", "DMY") if newv==1 & number==4
replace start = date("01/09/2022", "DMY") if newv==1 & number==5

* This gives a file where start dates are either exposure switching or 6-montly assessment dates 
* These will be used to determine the closest date to time-varying covariate dates identified in study definition 
sort patient_id start 
drop newv

* Determine end of follow-up date
gen dereg_dateA = date(dereg_date, "YMD")
format %dD/N/CY dereg_dateA
drop dereg_date
gen died_dateA = date(died_date_ons, "YMD")
format %dD/N/CY died_dateA
drop died_date_ons
gen end_study = date("31/12/2022", "DMY")
egen end_date = rowmin(dereg_dateA end_study died_dateA)

* Take out assessments after end_date 
drop if start>end_date

* Determine number of days between each covariate and dates of UDCA change or 6 monthly check date 
bys patient_id (start): egen last_assess = max(start)
* Format dates  and identify date nearest after covariate updates 
foreach var in covid_vacc_first_date severe_disease_fu_date liver_transplant_fu_date {
    gen `var'A = date(`var', "YMD")
    format `var'A %dD/N/CY 
    drop `var'
    * time between date of record and change in covariate - positive values are those where record starts after 
    * covariate change date 
    gen time_`var' = start - `var'A
    * Set time variable for records prior to change as missing
    replace time_`var'=. if time_`var'<0
    * Check if any are on index date (1st March) potentially severe disease - not others
    di "Number where time-varying update same as assessment date"
    count if time_`var'==0
    di "Number where time-varying update is 1st March 2020"
    count if `var'A==date("01/03/2020", "DMY")
    * Find earliest start date after covariate update
    * Note: there are some changes that occur after the last available 6 month assessment or exposure change
    bys patient_id (time_`var'): gen `var'_updateN = start[1] if `var'A!=. & time_`var'!=.
    * Spread to all rows for patient 
    bys patient_id: egen `var'_update = max(`var'_updateN)
    format `var'_update %dD/N/CY 
    di "Number where new variable is prior to original variable (should be 0)"
    count if `var'_update < `var'A
    di "Number where time varying update is after last assessment date"
    count if `var'A > last_assess & `var'A!=.  & last_assess==start
    di "Number of time-varying changes originally" 
    * Using last_assess==start to count patients rather than rows
    count if `var'A!=. & last_assess==start 
    di "Number of dates for time-varying update"
    count if `var'_update!=. & last_assess==start & `var'A!=.
}
* For severe disease only update variable if no severe disease at baseline 
count if severe_disease_fu_date_update==date("01/03/2020", "DMY") & severe_disease_bl!=1 
tab severe_disease_bl
replace severe_disease_fu_date_update = . if severe_disease_bl==1

* Keep only change dates to create time-varying dataset
keep patient_id covid_vacc_first_date_update severe_disease_fu_date_update liver_transplant_fu_date_update severe_disease_bl end_date
* Chercking number of patient_id's 
codebook patient_id
duplicates drop 
codebook patient_id
count
* Create file for each covariate to merge onto udca exposure file 
* First covid vaccination and liver transplant as all people will begin at zero 
rename liver_transplant_fu_date_update liver_trans_date_update
foreach var in covid_vacc_first liver_trans {
    preserve
    keep patient_id `var'_date_update end_date
    * Drop updates after the end of follow-up 
    count if `var'_date>=end_date 
    replace `var'_date = . if `var'_date>=end_date 
    * Flag if variable is updated
    gen `var'=(`var'_date_update!=.)
    * Create extra row if variable is updated 
    gen expand = `var'+1
    tab expand
    expand expand, gen(newv)
    * Update variables so row for when zero and row for when updated - if not updated whole time will be zero 
    gen start = date("01/03/2020", "DMY") if newv==0
    replace start = `var'_date_update if newv==1
    gen stop = `var'_date_update if newv==0
    replace stop = end_date if stop==.
    replace `var'=0 if newv==0
    save ./output/tv_`var'_check, replace
    keep patient_id `var' start stop
    * Check data 
    count if start==stop 
    * drop where start is same as stop - should not drop any in real data 
    drop if start==stop 
    count if stop<start
    codebook patient_id
    save ./output/tv_90_`var', replace
    restore
}

* Same for liver disease severity, but variable can start at 1 and remain for whole of follow-up 
preserve
keep patient_id severe_disease_fu_date_update end_date severe_disease_bl
* Drop updates after the end of follow-up 
replace severe_disease_fu_date_update=. if severe_disease_fu_date_update>=end_date 
* Flag if variable is updated
gen severe_disease=(severe_disease_fu_date_update!=.)
tab severe_disease 
replace severe_disease = 0 if severe_disease_bl==1
* Create extra row if variable is updated 
gen expand = severe_disease + 1
tab expand
expand expand, gen(newv)
tab newv
* Update variables so row for when zero and row for when updated - if not updated whole time will be zero 
gen start = date("01/03/2020", "DMY") if newv==0
replace start = severe_disease_fu_date_update if newv==1
gen stop = severe_disease_fu_date_update if newv==0 & severe_disease==1
count if stop!=.
replace stop = end_date if stop==. 
count if stop==.
replace severe_disease=0 if newv==0 & severe_disease_bl==0
replace severe_disease=1 if newv==0 & severe_disease_bl==1
save ./output/tv_severe_disease_check, replace
keep patient_id severe_disease start stop
* Check data 
count if start==stop
* drop if start is same as stop - should not drop any in real data 
drop if start==stop 
count if stop<start
codebook patient_id
save ./output/tv_90_severe_disease, replace
restore

* Merge files together for each outcome
* Composite  
use ./output/tv_90_severe_disease, clear 
tvc_merge start stop using ./output/tv_90_covid_vacc_first, id(patient_id)
tvc_merge start stop using ./output/tv_90_liver_trans, id(patient_id)
tvc_merge start stop using ./output/time_varying_udca_90, id(patient_id)
tvc_merge start stop using ./output/tv_age, id(patient_id)
tvc_merge start stop using ./output/tv_outcome_composite_any, id(patient_id) failure(composite_any_flag)
* Dummy drug data includes people not in cohort, so drop these - should not be any in real data 
drop if age_tv==.
codebook patient_id
* Check number of outcomes after merge  - there will be missings for rows after event
tab composite_any_flag, m
missings report
drop if composite_any_flag==.
save ./output/tv_vars_90_composite_any, replace 

* COVID death - covid code in any position
use ./output/tv_90_severe_disease, clear 
tvc_merge start stop using ./output/tv_90_covid_vacc_first, id(patient_id)
tvc_merge start stop using ./output/tv_90_liver_trans, id(patient_id)
tvc_merge start stop using ./output/time_varying_udca_90, id(patient_id)
tvc_merge start stop using ./output/tv_age, id(patient_id)
tvc_merge start stop using ./output/tv_outcome_died_covid_any, id(patient_id) failure(died_covid_any_flag)
* Dummy drug data includes people not in cohort, so drop these - should not be any in real data 
drop if age_tv==.
codebook patient_id
* Check number of outcomes after merge 
tab died_covid_any_flag, m
missings report
save ./output/tv_vars_90_died_covid_any, replace 

* COVID hospitalisation - covid code in any position
use ./output/tv_90_severe_disease, clear 
tvc_merge start stop using ./output/tv_90_covid_vacc_first, id(patient_id)
tvc_merge start stop using ./output/tv_90_liver_trans, id(patient_id)
tvc_merge start stop using ./output/time_varying_udca_90, id(patient_id)
tvc_merge start stop using ./output/tv_age, id(patient_id)
tvc_merge start stop using ./output/tv_outcome_hosp_any, id(patient_id) failure(hosp_any_flag)
* Check number of outcomes after merge 
tab hosp_any_flag, m
bys patient_id: egen total_hosp = total(hosp_any_flag)
tab total_hosp
* Dummy drug data includes people not in cohort, so drop these - should not be any in real data 
drop if age_tv==.
codebook patient_id
* Check number of outcomes after merge - there will be missings for rows after event
tab hosp_any_flag, m 
missings report
drop if hosp_any_flag==.
save ./output/tv_vars_90_hosp_any, replace 

use `basefile', clear
foreach var in died_covid_any hosp_any composite_any {
    preserve 
    merge 1:m patient_id using ./output/tv_vars_90_`var' 
    drop _merge 
    save ./output/an_dataset_90_`var', replace
    restore
}

*** 120 day overlap file: sensitivity analysis 
use ./output/time_varying_udca_overlap_120, clear 
codebook patient_id
merge m:1 patient_id using `tempfile', keepusing(severe_disease_fu_date severe_disease_bl covid_vacc_first_date liver_transplant_fu_date dereg_date died_date_ons)
* Should only be required for dummy data 
keep if _merge==3
* Only using start date as this is when udca exposure or 6 monthly check occurs
drop stop
* Add in rows with each of the 6 monthly assessment dates 
gen expand=1
bys patient_id (start): replace expand=6 if _n==_N 
expand expand, generate(newv)
bys patient_id newv: gen number = _n 
replace start = date("01/09/2020", "DMY") if newv==1 & number==1
replace start = date("01/03/2021", "DMY") if newv==1 & number==2
replace start = date("01/09/2021", "DMY") if newv==1 & number==3
replace start = date("01/03/2022", "DMY") if newv==1 & number==4
replace start = date("01/09/2022", "DMY") if newv==1 & number==5

* This gives a file where start dates are either exposure switching or 6-montly assessment dates 
* These will be used to determine the closest date to time-varying covariate dates identified in study definition 
sort patient_id start 
drop newv

* Determine end of follow-up date
gen dereg_dateA = date(dereg_date, "YMD")
format %dD/N/CY dereg_dateA
drop dereg_date
gen died_dateA = date(died_date_ons, "YMD")
format %dD/N/CY died_dateA
drop died_date_ons
gen end_study = date("31/12/2022", "DMY")
egen end_date = rowmin(dereg_dateA end_study died_dateA)

* Take out assessments after end_date 
drop if start>end_date

* Determine number of days between each covariate and dates of UDCA change or 6 monthly check date 
bys patient_id (start): egen last_assess = max(start)
* Format dates  and identify date nearest after covariate updates 
foreach var in covid_vacc_first_date severe_disease_fu_date liver_transplant_fu_date {
    gen `var'A = date(`var', "YMD")
    format `var'A %dD/N/CY 
    drop `var'
    * time between date of record and change in covariate - positive values are those where record starts after 
    * covariate change date 
    gen time_`var' = start - `var'A
    * Set time variable for records prior to change as missing
    replace time_`var'=. if time_`var'<0
    * Check if any are on index date (1st March) potentially severe disease - not others
    di "Number where time-varying update same as assessment date"
    count if time_`var'==0
    di "Number where time-varying update is 1st March 2020"
    count if `var'A==date("01/03/2020", "DMY")
    * Find earliest start date after covariate update
    * Note: there are some changes that occur after the last available 6 month assessment or exposure change
    bys patient_id (time_`var'): gen `var'_updateN = start[1] if `var'A!=. & time_`var'!=.
    * Spread to all rows for patient 
    bys patient_id: egen `var'_update = max(`var'_updateN)
    format `var'_update %dD/N/CY 
    di "Number where new variable is prior to original variable (should be 0)"
    count if `var'_update < `var'A
    di "Number where time varying update is after last assessment date"
    count if `var'A > last_assess & `var'A!=.  & last_assess==start
    di "Number of time-varying changes originally" 
    * Using last_assess==start to count patients rather than rows
    count if `var'A!=. & last_assess==start 
    di "Number of dates for time-varying update"
    count if `var'_update!=. & last_assess==start & `var'A!=.
}
* For severe disease only update variable if no severe disease at baseline 
count if severe_disease_fu_date_update==date("01/03/2020", "DMY") & severe_disease_bl!=1 
tab severe_disease_bl
replace severe_disease_fu_date_update = . if severe_disease_bl==1

* Keep only change dates to create time-varying dataset
keep patient_id covid_vacc_first_date_update severe_disease_fu_date_update liver_transplant_fu_date_update severe_disease_bl end_date
* Chercking number of patient_id's 
codebook patient_id
duplicates drop 
codebook patient_id
count
* Create file for each covariate to merge onto udca exposure file 
* First covid vaccination and liver transplant as all people will begin at zero 
rename liver_transplant_fu_date_update liver_trans_date_update
foreach var in covid_vacc_first liver_trans {
    preserve
    keep patient_id `var'_date_update end_date
    * Drop updates after the end of follow-up 
    count if `var'_date>=end_date 
    replace `var'_date = . if `var'_date>=end_date 
    * Flag if variable is updated
    gen `var'=(`var'_date_update!=.)
    * Create extra row if variable is updated 
    gen expand = `var'+1
    tab expand
    expand expand, gen(newv)
    * Update variables so row for when zero and row for when updated - if not updated whole time will be zero 
    gen start = date("01/03/2020", "DMY") if newv==0
    replace start = `var'_date_update if newv==1
    gen stop = `var'_date_update if newv==0
    replace stop = end_date if stop==.
    replace `var'=0 if newv==0
    save ./output/tv_`var'_check, replace
    keep patient_id `var' start stop
    * Check data 
    count if start==stop 
    * drop where start is same as stop - should not drop any in real data 
    drop if start==stop 
    count if stop<start
    codebook patient_id
    save ./output/tv_overlap_120_`var', replace
    restore
}

* Same for liver disease severity, but variable can start at 1 and remain for whole of follow-up 
preserve
keep patient_id severe_disease_fu_date_update end_date severe_disease_bl
* Drop updates after the end of follow-up 
replace severe_disease_fu_date_update=. if severe_disease_fu_date_update>=end_date 
* Flag if variable is updated
gen severe_disease=(severe_disease_fu_date_update!=.)
tab severe_disease 
replace severe_disease = 0 if severe_disease_bl==1
* Create extra row if variable is updated 
gen expand = severe_disease + 1
tab expand
expand expand, gen(newv)
tab newv
* Update variables so row for when zero and row for when updated - if not updated whole time will be zero 
gen start = date("01/03/2020", "DMY") if newv==0
replace start = severe_disease_fu_date_update if newv==1
gen stop = severe_disease_fu_date_update if newv==0 & severe_disease==1
count if stop!=.
replace stop = end_date if stop==. 
count if stop==.
replace severe_disease=0 if newv==0 & severe_disease_bl==0
replace severe_disease=1 if newv==0 & severe_disease_bl==1
save ./output/tv_severe_disease_check, replace
keep patient_id severe_disease start stop
* Check data 
count if start==stop
* drop if start is same as stop - should not drop any in real data 
drop if start==stop 
count if stop<start
codebook patient_id
save ./output/tv_overlap_120_severe_disease, replace
restore

* Merge files together for each outcome
* Composite  
use ./output/tv_overlap_120_severe_disease, clear 
tvc_merge start stop using ./output/tv_overlap_120_covid_vacc_first, id(patient_id)
tvc_merge start stop using ./output/tv_overlap_120_liver_trans, id(patient_id)
tvc_merge start stop using ./output/time_varying_udca_overlap_120, id(patient_id)
tvc_merge start stop using ./output/tv_age, id(patient_id)
tvc_merge start stop using ./output/tv_outcome_composite_any, id(patient_id) failure(composite_any_flag)
* Dummy drug data includes people not in cohort, so drop these - should not be any in real data 
drop if age_tv==.
codebook patient_id
* Check number of outcomes after merge  - there will be missings for rows after event
tab composite_any_flag, m
missings report
drop if composite_any_flag==.
save ./output/tv_vars_overlap_120_composite_any, replace 

* COVID death - covid code in any position
use ./output/tv_overlap_120_severe_disease, clear 
tvc_merge start stop using ./output/tv_overlap_120_covid_vacc_first, id(patient_id)
tvc_merge start stop using ./output/tv_overlap_120_liver_trans, id(patient_id)
tvc_merge start stop using ./output/time_varying_udca_overlap_120, id(patient_id)
tvc_merge start stop using ./output/tv_age, id(patient_id)
tvc_merge start stop using ./output/tv_outcome_died_covid_any, id(patient_id) failure(died_covid_any_flag)
* Dummy drug data includes people not in cohort, so drop these - should not be any in real data 
drop if age_tv==.
codebook patient_id
* Check number of outcomes after merge 
tab died_covid_any_flag, m
missings report
save ./output/tv_vars_overlap_120_died_covid_any, replace 

* COVID hospitalisation - covid code in any position
use ./output/tv_overlap_120_severe_disease, clear 
tvc_merge start stop using ./output/tv_overlap_120_covid_vacc_first, id(patient_id)
tvc_merge start stop using ./output/tv_overlap_120_liver_trans, id(patient_id)
tvc_merge start stop using ./output/time_varying_udca_overlap_120, id(patient_id)
tvc_merge start stop using ./output/tv_age, id(patient_id)
tvc_merge start stop using ./output/tv_outcome_hosp_any, id(patient_id) failure(hosp_any_flag)
* Check number of outcomes after merge 
tab hosp_any_flag, m
bys patient_id: egen total_hosp = total(hosp_any_flag)
tab total_hosp
* Dummy drug data includes people not in cohort, so drop these - should not be any in real data 
drop if age_tv==.
codebook patient_id
* Check number of outcomes after merge - there will be missings for rows after event
tab hosp_any_flag, m 
missings report
drop if hosp_any_flag==.
save ./output/tv_vars_overlap_120_hosp_any, replace 

use `basefile', clear
foreach var in died_covid_any hosp_any composite_any {
    preserve 
    merge 1:m patient_id using ./output/tv_vars_overlap_120_`var' 
    drop _merge 
    save ./output/an_dataset_overlap_120_`var', replace
    restore
}

*** vaccination file: sensitivity analysis 
** Creating file where count of vaccinations updates over time
use ./output/time_varying_udca_120, clear 
codebook patient_id
merge m:1 patient_id using `tempfile', keepusing(covid_vacc* dereg_date died_date_ons date_most_recent_cov_vac)
* Should only be required for dummy data 
keep if _merge==3
* Only using start date as this is when udca exposure or 6 monthly check occurs
drop stop
* Add in rows with each of the 6 monthly assessment dates 
gen expand=1
bys patient_id (start): replace expand=6 if _n==_N 
expand expand, generate(newv)
bys patient_id newv: gen number = _n 
replace start = date("01/09/2020", "DMY") if newv==1 & number==1
replace start = date("01/03/2021", "DMY") if newv==1 & number==2
replace start = date("01/09/2021", "DMY") if newv==1 & number==3
replace start = date("01/03/2022", "DMY") if newv==1 & number==4
replace start = date("01/09/2022", "DMY") if newv==1 & number==5

* This gives a file where start dates are either exposure switching or 6-montly assessment dates 
* These will be used to determine the closest date to time-varying covariate dates identified in study definition 
sort patient_id start 
drop newv

* Determine end of follow-up date
gen dereg_dateA = date(dereg_date, "YMD")
format %dD/N/CY dereg_dateA
drop dereg_date
gen died_dateA = date(died_date_ons, "YMD")
format %dD/N/CY died_dateA
drop died_date_ons
gen end_study = date("31/12/2022", "DMY")
egen end_date = rowmin(dereg_dateA end_study died_dateA)

* Take out assessments after end_date 
drop if start>end_date

* Determine number of days between each covariate and dates of UDCA change or 6 monthly check date 
bys patient_id (start): egen last_assess = max(start)
* Format dates  and identify date nearest after covariate updates 
foreach var in covid_vacc_first_date covid_vacc_second_date covid_vacc_third_date covid_vacc_fourth_date covid_vacc_fifth_date {
    gen `var'A = date(`var', "YMD")
    format `var'A %dD/N/CY 
    drop `var'
    * time between date of record and change in covariate - positive values are those where record starts after 
    * covariate change date 
    gen time_`var' = start - `var'A
    * Set time variable for records prior to change as missing
    replace time_`var'=. if time_`var'<0
    * Check if any are on index date (1st March) potentially severe disease - not others
    di "Number where time-varying update same as assessment date"
    count if time_`var'==0
    di "Number where time-varying update is 1st March 2020"
    count if `var'A==date("01/03/2020", "DMY")
    * Find earliest start date after covariate update
    * Note: there are some changes that occur after the last available 6 month assessment or exposure change
    bys patient_id (time_`var'): gen `var'_updateN = start[1] if `var'A!=. & time_`var'!=.
    * Spread to all rows for patient 
    bys patient_id: egen `var'_update = max(`var'_updateN)
    format `var'_update %dD/N/CY 
    di "Number where new variable is prior to original variable (should be 0)"
    count if `var'_update < `var'A
    di "Number where time varying update is after last assessment date"
    count if `var'A > last_assess & `var'A!=.  & last_assess==start
    di "Number of time-varying changes originally" 
    * Using last_assess==start to count patients rather than rows
    count if `var'A!=. & last_assess==start 
    di "Number of dates for time-varying update"
    count if `var'_update!=. & last_assess==start & `var'A!=.
}

* Keep only change dates to create time-varying dataset
keep patient_id covid_vacc_first_date_update covid_vacc_second_date_update covid_vacc_third_date_update covid_vacc_fourth_date_update covid_vacc_fifth_date_update end_date date_most_recent_cov_vac
* Chercking number of patient_id's 
codebook patient_id
duplicates drop 
codebook patient_id
count
* Create dataset where rows are updated when person is vaccinated/re-vaccinated  
foreach var in covid_vacc_first covid_vacc_second covid_vacc_third covid_vacc_fourth covid_vacc_fifth {
    count if `var'_date_update>=end_date & `var'_date_update!=.
    replace `var'_date_update = . if `var'_date_update>=end_date
    * Create flag for each vaccination date 
    gen `var'_flag = (`var'_date_update!=.)
    * Create flag for if date is prior to 1st March 2021
    gen `var'_prior = `var'_date_update <= date("01Mar2021", "DMY")
    tab `var'_prior, m
}
* Check not date where prior vaccination is missing 
count if covid_vacc_first_flag==0 & covid_vacc_second_flag==1
count if covid_vacc_second_flag==0 & covid_vacc_third_flag==1
count if covid_vacc_third_flag==0 & covid_vacc_fourth_flag==1
count if covid_vacc_fourth_flag==0 & covid_vacc_fifth_flag==1

* Determine total number of vaccinations 
egen total_vaccs = rowtotal(covid_vacc_first_flag covid_vacc_second_flag covid_vacc_third_flag covid_vacc_fourth_flag covid_vacc_fifth_flag)
tab total_vaccs
egen total_vaccs_prior = rowtotal(covid_vacc_first_prior covid_vacc_second_prior covid_vacc_third_prior covid_vacc_fourth_prior covid_vacc_fifth_prior)
gen date_most_recent_cov_vacA = date(date_most_recent_cov_vac, "YMD")
count if total_vaccs_prior!=0 & date_most_recent_cov_vacA==.
count if total_vaccs_prior==0 & date_most_recent_cov_vacA!=.
* Create time varying vaccination count variable 
gen vacc_count_tv = 0
* expand row up to total number of vaccinations 
gen expand = total_vaccs + 1
tab expand 
expand expand, gen(newv)
bys patient_id newv: gen number = _n 
* Update variables so row for when zero and row for each vaccination - if not updated whole time will be zero 
gen start = date("01/03/2020", "DMY") if newv==0
replace start = covid_vacc_first_date_update if newv==1 & number == 1
gen stop = covid_vacc_first_date_update if newv==0 & covid_vacc_first_date_update!=.
replace stop = end_date if stop==. & expand==1
replace stop = covid_vacc_second_date_update if newv==1 & number==1
replace vacc_count_tv = 1 if newv==1 & number==1
* Second vaccination 
replace start = covid_vacc_second_date_update if newv==1 & number == 2
replace stop = covid_vacc_third_date_update if newv==1 & number==2 & covid_vacc_third_date_update!=.
replace stop = end_date if newv==1 & number==2 & covid_vacc_third_date_update==.
replace vacc_count_tv = 2 if newv==1 & number==2
* Third vaccination 
replace start = covid_vacc_third_date_update if newv==1 & number == 3
replace stop = covid_vacc_fourth_date_update if newv==1 & number==3 & covid_vacc_fourth_date_update!=.
replace stop = end_date if newv==1 & number==3 & covid_vacc_fourth_date_update==.
replace vacc_count_tv = 3 if newv==1 & number==3
* Fourth vaccination 
replace start = covid_vacc_fourth_date_update if newv==1 & number == 4
replace stop = covid_vacc_fifth_date_update if newv==1 & number==4 & covid_vacc_fifth_date_update!=.
replace stop = end_date if newv==1 & number==4 & covid_vacc_fifth_date_update==.
replace vacc_count_tv = 4 if newv==1 & number==4
* Fifth vaccination 
replace start = covid_vacc_fifth_date_update if newv==1 & number == 5
replace stop = end_date if newv==1 & number==5
replace vacc_count_tv = 5 if newv==1 & number==5
save ./output/tv_120_total_vaccs_check, replace
keep patient_id vacc_count_tv start stop
* Check data 
count if start==stop 
* drop where start is same as stop - should not drop any in real data 
drop if start==stop 
count if stop<start
codebook patient_id
save ./output/tv_120_total_vaccs, replace


* Merge files together for each outcome
* Composite  
use ./output/tv_severe_disease, clear 
tvc_merge start stop using ./output/tv_covid_vacc_first, id(patient_id)
tvc_merge start stop using ./output/tv_120_total_vaccs, id(patient_id)
tvc_merge start stop using ./output/tv_liver_trans, id(patient_id)
tvc_merge start stop using ./output/time_varying_udca_120, id(patient_id)
tvc_merge start stop using ./output/tv_age, id(patient_id)
tvc_merge start stop using ./output/tv_outcome_composite_any, id(patient_id) failure(composite_any_flag)
* Dummy drug data includes people not in cohort, so drop these - should not be any in real data 
drop if age_tv==.
codebook patient_id
* Check number of outcomes after merge  - there will be missings for rows after event
tab composite_any_flag, m
missings report
drop if composite_any_flag==.
save ./output/tv_vars_120_vacc_composite_any, replace 

* COVID death - covid code in any position
use ./output/tv_severe_disease, clear 
tvc_merge start stop using ./output/tv_covid_vacc_first, id(patient_id)
tvc_merge start stop using ./output/tv_120_total_vaccs, id(patient_id)
tvc_merge start stop using ./output/tv_liver_trans, id(patient_id)
tvc_merge start stop using ./output/time_varying_udca_120, id(patient_id)
tvc_merge start stop using ./output/tv_age, id(patient_id)
tvc_merge start stop using ./output/tv_outcome_died_covid_any, id(patient_id) failure(died_covid_any_flag)
* Dummy drug data includes people not in cohort, so drop these - should not be any in real data 
drop if age_tv==.
codebook patient_id
* Check number of outcomes after merge 
tab died_covid_any_flag, m
missings report
save ./output/tv_vars_120_vacc_died_covid_any, replace 

* COVID hospitalisation - covid code in any position
use ./output/tv_severe_disease, clear 
tvc_merge start stop using ./output/tv_covid_vacc_first, id(patient_id)
tvc_merge start stop using ./output/tv_120_total_vaccs, id(patient_id)
tvc_merge start stop using ./output/tv_liver_trans, id(patient_id)
tvc_merge start stop using ./output/time_varying_udca_120, id(patient_id)
tvc_merge start stop using ./output/tv_age, id(patient_id)
tvc_merge start stop using ./output/tv_outcome_hosp_any, id(patient_id) failure(hosp_any_flag)
* Check number of outcomes after merge 
tab hosp_any_flag, m
bys patient_id: egen total_hosp = total(hosp_any_flag)
tab total_hosp
* Dummy drug data includes people not in cohort, so drop these - should not be any in real data 
drop if age_tv==.
codebook patient_id
* Check number of outcomes after merge - there will be missings for rows after event
tab hosp_any_flag, m 
missings report
drop if hosp_any_flag==.
save ./output/tv_vars_120_vacc_hosp_any, replace 

use `basefile', clear
foreach var in died_covid_any hosp_any composite_any {
    preserve 
    merge 1:m patient_id using ./output/tv_vars_120_vacc_`var' 
    drop _merge 
    save ./output/an_dataset_120_vacc_`var', replace
    restore
}

* Sensitivity analysis - March 2021 cohort - vaccinations

import delimited using ./output/input_vacc.csv, clear 
describe
save `tempfile', replace 

/* Time-varying covariates are assessed 6-monthly and at time of exposure switching.
As disease severity, covid vaccination and liver transplant will only switch once need to identify
nearest date after date identified in study definition */ 
* 120 day file: primary exposure definition 
use ./output/time_varying_udca_vacc, clear 
codebook patient_id
merge m:1 patient_id using `tempfile', keepusing(severe_disease_fu_date severe_disease_bl covid_vacc_first_date liver_transplant_fu_date dereg_date died_date_ons)
* Should only be required for dummy data 
keep if _merge==3
* Only using start date as this is when udca exposure or 6 monthly check occurs
drop stop
* Add in rows with each of the 6 monthly assessment dates 
gen expand=1
bys patient_id (start): replace expand=4 if _n==_N 
expand expand, generate(newv)
bys patient_id newv: gen number = _n 
replace start = date("01/09/2021", "DMY") if newv==1 & number==1
replace start = date("01/03/2022", "DMY") if newv==1 & number==2
replace start = date("01/09/2022", "DMY") if newv==1 & number==3

* This gives a file where start dates are either exposure switching or 6-montly assessment dates 
* These will be used to determine the closest date to time-varying covariate dates identified in study definition 
sort patient_id start 
drop newv

* Determine end of follow-up date
gen dereg_dateA = date(dereg_date, "YMD")
format %dD/N/CY dereg_dateA
drop dereg_date
gen died_dateA = date(died_date_ons, "YMD")
format %dD/N/CY died_dateA
drop died_date_ons
gen end_study = date("31/12/2022", "DMY")
egen end_date = rowmin(dereg_dateA end_study died_dateA)

* Take out assessments after end_date 
drop if start>end_date

* Determine number of days between each covariate and dates of UDCA change or 6 monthly check date 
bys patient_id (start): egen last_assess = max(start)
* Format dates  and identify date nearest after covariate updates 
foreach var in covid_vacc_first_date severe_disease_fu_date liver_transplant_fu_date {
    gen `var'A = date(`var', "YMD")
    format `var'A %dD/N/CY 
    drop `var'
    * time between date of record and change in covariate - positive values are those where record starts after 
    * covariate change date 
    gen time_`var' = start - `var'A
    * Set time variable for records prior to change as missing
    replace time_`var'=. if time_`var'<0
    * Check if any are on index date (1st March) potentially severe disease - not others
    di "Number where time-varying update same as assessment date"
    count if time_`var'==0
    di "Number where time-varying update is 1st March 2021"
    count if `var'A==date("01/03/2021", "DMY")
    * Find earliest start date after covariate update
    * Note: there are some changes that occur after the last available 6 month assessment or exposure change
    bys patient_id (time_`var'): gen `var'_updateN = start[1] if `var'A!=. & time_`var'!=.
    * Spread to all rows for patient 
    bys patient_id: egen `var'_update = max(`var'_updateN)
    format `var'_update %dD/N/CY 
    di "Number where new variable is prior to original variable (should be 0)"
    count if `var'_update < `var'A
    di "Number where time varying update is after last assessment date"
    count if `var'A > last_assess & `var'A!=.  & last_assess==start
    di "Number of time-varying changes originally" 
    * Using last_assess==start to count patients rather than rows
    count if `var'A!=. & last_assess==start 
    di "Number of dates for time-varying update"
    count if `var'_update!=. & last_assess==start & `var'A!=.
}
* For severe disease only update variable if no severe disease at baseline 
count if severe_disease_fu_date_update==date("01/03/2021", "DMY") & severe_disease_bl!=1 
tab severe_disease_bl
replace severe_disease_fu_date_update = . if severe_disease_bl==1

* Keep only change dates to create time-varying dataset
keep patient_id covid_vacc_first_date_update severe_disease_fu_date_update liver_transplant_fu_date_update severe_disease_bl end_date
* Chercking number of patient_id's 
codebook patient_id
duplicates drop 
codebook patient_id
count
* Create file for each covariate to merge onto udca exposure file 
* First covid vaccination and liver transplant as all people will begin at zero 
rename liver_transplant_fu_date_update liver_trans_date_update
foreach var in covid_vacc_first liver_trans {
    preserve
    keep patient_id `var'_date_update end_date
    * Drop updates after the end of follow-up 
    count if `var'_date>=end_date 
    replace `var'_date = . if `var'_date>=end_date 
    * Flag if variable is updated
    gen `var'=(`var'_date_update!=.)
    * Create extra row if variable is updated 
    gen expand = `var'+1
    tab expand
    expand expand, gen(newv)
    * Update variables so row for when zero and row for when updated - if not updated whole time will be zero 
    gen start = date("01/03/2020", "DMY") if newv==0
    replace start = `var'_date_update if newv==1
    gen stop = `var'_date_update if newv==0
    replace stop = end_date if stop==.
    replace `var'=0 if newv==0
    save ./output/tv_`var'_check, replace
    keep patient_id `var' start stop
    * Check data 
    count if start==stop 
    * drop where start is same as stop - should not drop any in real data 
    drop if start==stop 
    count if stop<start
    codebook patient_id
    save ./output/tv_`var'_vacc, replace
    restore
}

* Same for liver disease severity, but variable can start at 1 and remain for whole of follow-up 
preserve
keep patient_id severe_disease_fu_date_update end_date severe_disease_bl
* Drop updates after the end of follow-up 
replace severe_disease_fu_date_update=. if severe_disease_fu_date_update>=end_date 
* Flag if variable is updated
gen severe_disease=(severe_disease_fu_date_update!=.)
tab severe_disease 
replace severe_disease = 0 if severe_disease_bl==1
* Create extra row if variable is updated 
gen expand = severe_disease + 1
tab expand
expand expand, gen(newv)
tab newv
* Update variables so row for when zero and row for when updated - if not updated whole time will be zero 
gen start = date("01/03/2021", "DMY") if newv==0
replace start = severe_disease_fu_date_update if newv==1
gen stop = severe_disease_fu_date_update if newv==0 & severe_disease==1
count if stop!=.
replace stop = end_date if stop==. 
count if stop==.
replace severe_disease=0 if newv==0 & severe_disease_bl==0
replace severe_disease=1 if newv==0 & severe_disease_bl==1
save ./output/tv_severe_disease_check, replace
keep patient_id severe_disease start stop
* Check data 
count if start==stop
* drop if start is same as stop - should not drop any in real data 
drop if start==stop 
count if stop<start
codebook patient_id
save ./output/tv_severe_disease_vacc, replace
restore

* Time-varying vaccination count
use ./output/time_varying_udca_vacc, clear 
codebook patient_id
merge m:1 patient_id using `tempfile', keepusing(covid_vacc* dereg_date died_date_ons date_most_recent_cov_vac)
* Should only be required for dummy data 
keep if _merge==3
* Only using start date as this is when udca exposure or 6 monthly check occurs
drop stop
* Add in rows with each of the 6 monthly assessment dates 
gen expand=1
bys patient_id (start): replace expand=4 if _n==_N 
expand expand, generate(newv)
bys patient_id newv: gen number = _n 
replace start = date("01/09/2021", "DMY") if newv==1 & number==1
replace start = date("01/03/2022", "DMY") if newv==1 & number==2
replace start = date("01/09/2022", "DMY") if newv==1 & number==3

* This gives a file where start dates are either exposure switching or 6-montly assessment dates 
* These will be used to determine the closest date to time-varying covariate dates identified in study definition 
sort patient_id start 
drop newv

* Determine end of follow-up date
gen dereg_dateA = date(dereg_date, "YMD")
format %dD/N/CY dereg_dateA
drop dereg_date
gen died_dateA = date(died_date_ons, "YMD")
format %dD/N/CY died_dateA
drop died_date_ons
gen end_study = date("31/12/2022", "DMY")
egen end_date = rowmin(dereg_dateA end_study died_dateA)

* Take out assessments after end_date 
drop if start>end_date
* Determine number of days between each covariate and dates of UDCA change or 6 monthly check date 
bys patient_id (start): egen last_assess = max(start)
* Format dates  and identify date nearest after covariate updates 
foreach var in covid_vacc_first_date covid_vacc_second_date covid_vacc_third_date covid_vacc_fourth_date covid_vacc_fifth_date {
    gen `var'A = date(`var', "YMD")
    format `var'A %dD/N/CY 
    drop `var'
    * time between date of record and change in covariate - positive values are those where record starts after 
    * covariate change date 
    gen time_`var' = start - `var'A
    * Set time variable for records prior to change as missing
    replace time_`var'=. if time_`var'<=0
    * Check if any are on index date (1st March) 
    di "Number where time-varying update same as assessment date"
    count if time_`var'==0
    di "Number where time-varying update is 1st March 2021"
    count if `var'A==date("01/03/2021", "DMY")
    * Find earliest start date after covariate update
    * Note: there are some changes that occur after the last available 6 month assessment or exposure change
    bys patient_id (time_`var'): gen `var'_updateN = start[1] if `var'A!=. & time_`var'!=.
    * Spread to all rows for patient 
    bys patient_id: egen `var'_update = max(`var'_updateN)
    format `var'_update %dD/N/CY 
    di "Number where new variable is prior to original variable (should be 0)"
    count if `var'_update < `var'A
    di "Number where time varying update is after last assessment date"
    count if `var'A > last_assess & `var'A!=.  & last_assess==start
    di "Number of time-varying changes originally" 
    * Using last_assess==start to count patients rather than rows
    count if `var'A!=. & last_assess==start 
    di "Number of dates for time-varying update"
    count if `var'_update!=. & last_assess==start & `var'A!=.
}

* Keep only change dates to create time-varying dataset
keep patient_id start covid_vacc_first_date_update covid_vacc_second_date_update covid_vacc_third_date_update covid_vacc_fourth_date_update covid_vacc_fifth_date_update end_date 
* Checking number of patient_id's 
codebook patient_id
duplicates drop 
codebook patient_id
count

foreach var in covid_vacc_first covid_vacc_second covid_vacc_third covid_vacc_fourth covid_vacc_fifth { 
    gen `var'_prior_start = (`var'_date_update <= start) 
}
* Determine number of vaccinations at each assessment point 
egen vacc_count_tv = rowtotal(covid_vacc_first_prior_start covid_vacc_second_prior_start covid_vacc_third_prior_start covid_vacc_fourth_prior_start covid_vacc_fifth_prior_start)
* Determine if no change in number of vaccinations since last assessment 
bys patient_id (start): gen no_change = vacc_count_tv==vacc_count_tv[_n-1]
* Drop records if no change 
drop if no_change==1 
drop no_change 
bys patient_id (start): gen stop = start[_n+1]
replace stop = end_date if stop==.

/* Create dataset where rows are updated when person is vaccinated/re-vaccinated  
foreach var in covid_vacc_first covid_vacc_second covid_vacc_third covid_vacc_fourth covid_vacc_fifth {
    count if `var'_date_update>=end_date & `var'_date_update!=.
    replace `var'_date_update = . if `var'_date_update>=end_date
    * Create flag for each vaccination date 
    gen `var'_flag = (`var'_date_update!=.)
    * Create flag for if date is prior to 1st March 2021
    gen `var'_prior = `var'_dateA <= date("01Mar2021", "DMY")
    tab `var'_prior, m
}
* Check not date where prior vaccination is missing 
count if covid_vacc_first_flag==0 & covid_vacc_second_flag==1
count if covid_vacc_second_flag==0 & covid_vacc_third_flag==1
count if covid_vacc_third_flag==0 & covid_vacc_fourth_flag==1
count if covid_vacc_fourth_flag==0 & covid_vacc_fifth_flag==1

* Check where more than one vaccine during a period
count if covid_vacc_first_date_update==covid_vacc_second_date_update & covid_vacc_first_date_update!=.
count if covid_vacc_second_date_update==covid_vacc_third_date_update & covid_vacc_second_date_update!=.
count if covid_vacc_third_date_update==covid_vacc_fourth_date_update & covid_vacc_third_date_update!=.
count if covid_vacc_fourth_date_update==covid_vacc_fifth_date_update & covid_vacc_fourth_date_update!=.

* Where multiple vaccinations in same period need to set earliest one to missing 
replace covid_vacc_first_date_update=. if covid_vacc_first_date_update==covid_vacc_second_date_update & covid_vacc_first_date_update!=. 
replace covid_vacc_second_date_update=. if covid_vacc_second_date_update==covid_vacc_third_date_update & covid_vacc_second_date_update!=. 
replace covid_vacc_third_date_update=. if covid_vacc_third_date_update==covid_vacc_fourth_date_update & covid_vacc_third_date_update!=.
replace covid_vacc_fourth_date_update=. if covid_vacc_fourth_date_update==covid_vacc_fifth_date_update & covid_vacc_fourth_date_update!=.

* Generate count if number of changes at each vacc 
gen change_1 = covid_vacc_first_flag 
gen change_2 = covid_vacc_first_flag + covid_vacc_second_flag
gen change_3 = covid_vacc_first_flag + covid_vacc_second_flag + covid_vacc_third_flag
gen change_4 = covid_vacc_first_flag + covid_vacc_second_flag + covid_vacc_third_flag + covid_vacc_fourth_flag
gen change_5 = covid_vacc_first_flag + covid_vacc_second_flag + covid_vacc_third_flag + covid_vacc_fourth_flag + covid_vacc_fifth_flag
forvalues i=1/5 {
    tab change_`i'
    }


* Determine total number of vaccinations 
egen total_vaccs = rowtotal(covid_vacc_first_flag covid_vacc_second_flag covid_vacc_third_flag covid_vacc_fourth_flag covid_vacc_fifth_flag)
tab total_vaccs
egen total_vaccs_prior = rowtotal(covid_vacc_first_prior covid_vacc_second_prior covid_vacc_third_prior covid_vacc_fourth_prior covid_vacc_fifth_prior)
tab total_vaccs_prior, m 
gen date_most_recent_cov_vacA = date(date_most_recent_cov_vac, "YMD")
count if total_vaccs_prior!=0 & date_most_recent_cov_vacA==.
count if total_vaccs_prior==0 & date_most_recent_cov_vacA!=.

* Create time varying vaccination count variable 
gen vacc_count_tv = total_vaccs_prior
* expand row up to total number of vaccinations 
gen expand = total_vaccs + 1
tab expand 
expand expand, gen(newv)
bys patient_id newv: gen number = _n 
* Update variables so row for when zero or initial number of vaccines and row for each vaccination - if not updated whole time will be zero 
* First row is either no to 1, one to 2 or 2 to 3 unless there are multiple vaccines on the same period
gen start = date("01/03/2020", "DMY") if newv==0
gen stop = covid_vacc_first_date_update if newv==0 & change_1==1
replace stop = covid_vacc_second_date_update if newv==0 & change_2==1 & change_1==0
replace stop = covid_vacc_third_date_update if newv==0 & change_3==1 & change_2==0
replace stop = covid_vacc_fourth_date_update if newv==0 & change_4==1 & change_3==0
replace stop = covid_vacc_fifth_date_update if newv==0 & change_5==1 & change_4==0
replace stop = end_date if total_vaccs==0
* Second update - update vacc_count_tv at end
replace start = covid_vacc_first_date_update if newv==1 & number == 1 & change_1==1
replace start = covid_vacc_second_date_update if newv==1 & number == 1 & change_2==1 & change_1==0
replace start = covid_vacc_third_date_update if newv==1 & number == 1 & change_3==1 & change_2==0
replace start = covid_vacc_fourth_date_update if newv==1 & number == 1 & change_4==1 & change_3==0
replace start = covid_vacc_fifth_date_update if newv==1 & number == 1 & change_5==1 & change_4==0

replace stop = covid_vacc_second_date_update if newv==1 & number == 1 & change_2==2
replace stop = covid_vacc_third_date_update if newv==1 & number == 1 & change_3==2 & change_2==1
replace stop= covid_vacc_fourth_date_update if newv==1 & number == 1 & change_4==2 & change_3==1
replace stop = covid_vacc_fifth_date_update if newv==1 & number == 1 & change_5==2 & change_4==1
replace stop = end_date if stop==. & newv==1 & number == 1

* Third update 
replace start = covid_vacc_second_date_update if newv==1 & number == 2 & change_2==2
replace start = covid_vacc_third_date_update if newv==1 & number == 2 & change_3==2 & change_2==1
replace start = covid_vacc_fourth_date_update if newv==1 & number == 2 & change_4==2 & change_3==1
replace start = covid_vacc_fifth_date_update if newv==1 & number == 2 & change_5==2 & change_4==1

replace stop = covid_vacc_third_date_update if newv==1 & number == 2 & change_3==3 & change_2==2
replace stop= covid_vacc_fourth_date_update if newv==1 & number == 2 & change_4==3 & change_3==2
replace stop = covid_vacc_fifth_date_update if newv==1 & number == 2 & change_5==3 & change_4==2
replace stop = end_date if stop==. & newv==1 & number == 2

* Fourth update 
replace start = covid_vacc_third_date_update if newv==1 & number == 3 & change_3==3 & change_2==2
replace start= covid_vacc_fourth_date_update if newv==1 & number == 3 & change_4==3 & change_3==2
replace start = covid_vacc_fifth_date_update if newv==1 & number == 3 & change_5==3 & change_4==2

replace stop= covid_vacc_fourth_date_update if newv==1 & number == 3 & change_4==4 & change_3==3
replace stop = covid_vacc_fifth_date_update if newv==1 & number == 3 & change_5==4 & change_4==3
replace stop = end_date if stop==. & newv==1 & number == 3

* Fifth update 
replace start = covid_vacc_fourth_date_update if newv==1 & number == 3 & change_4==4 & change_3==3
replace start = covid_vacc_fifth_date_update if newv==1 & number == 3 & change_5==4 & change_4==3

replace stop = covid_vacc_fifth_date_update if newv==1 & number == 4 & change_5==5 & change_4==4
replace stop = end_date if stop==. & newv==1 & number == 4

replace vacc_count_tv = 1 if stop==covid_vacc_first_date_update
replace vacc_count_tv = 2 if stop==covid_vacc_second_date_update
replace vacc_count_tv = 3 if stop==covid_vacc_third_date_update
replace vacc_count_tv = 4 if stop==covid_vacc_fourth_date_update
replace vacc_count_tv = 5 if stop==covid_vacc_fifth_date_update
*/
* Checks
count if start==.
count if stop==.
bys patient_id (start): gen stop_error = start < stop[_n-1] & patient_id==patient_id[_n-1]
tab stop_error 
bys patient_id (start): gen tv_vacc_error = vacc_count_tv<vacc_count_tv[_n-1] 
save ./output/tv_total_vaccs_check, replace
keep patient_id vacc_count_tv start stop
* Check data 
count if start==stop 
* drop where start is same as stop - should not drop any in real data 
drop if start==stop 
count if stop<start
count if start==. 
count if stop==1
codebook patient_id
save ./output/tv_total_vaccs, replace

* Make age time-varying i.e. updating on 1st January each year
use `tempfile', clear 
* Determine end of follow-up date
gen dereg_dateA = date(dereg_date, "YMD")
format %dD/N/CY dereg_dateA
drop dereg_date
gen died_dateA = date(died_date_ons, "YMD")
format %dD/N/CY died_dateA
drop died_date_ons
* Determine end of follow-up then add rows to update age for each year of follow-up
gen end_study = date("31/12/2022", "DMY")
egen end_date = rowmin(dereg_dateA end_study died_dateA)
keep patient_id age end_date
gen yr_end = year(end_date)
* Add rows to update age
gen expand = 2 if yr_end==2022
replace expand = 1 if yr_end==2021
tab expand, m
expand expand, gen(newv)
tab newv, nolabel
gen start = date("01/03/2021", "DMY") if newv==0
replace start = date("01/01/2022", "DMY") if newv==1 
gen stop = date("01/01/2022", "DMY") if newv==0 
replace stop = end_date if newv==0 & end_date<stop 
replace stop = date("31/12/2022", "DMY") if newv==1
replace stop = end_date if newv==1 & end_date<stop
gen age_tv = age if newv==0
replace age_tv = age+1 if newv==1 
keep patient_id start stop age_tv 
drop if start==stop
codebook patient_id
save ./output/tv_age_vacc, replace 


* Create files for outcomes
use `tempfile', clear
* Determine end of follow-up date
foreach var in died_date_ons hosp_covid_primary hosp_covid_any dereg_date {
    gen `var'A = date(`var', "YMD")
    format `var'A %dD/N/CY
    drop `var'
    gen yr_`var' = year(`var'A)
    tab yr_`var'
    replace `var'A=. if yr_`var'==2023
}
gen end_study = date("31/12/2022", "DMY")
egen end_date = rowmin(dereg_dateA end_study died_date_onsA)

* Create flag indicating reason for end of follow-up 
gen end_date_flag = (end_date==dereg_dateA)
replace end_date_flag = 2 if end_date==died_date_onsA
replace end_date_flag = 3 if end_date==end_study
replace died_date_onsA=. if end_date<died_date_onsA
replace died_ons_covid_flag_any=0 if end_date<died_date_onsA & died_ons_covid_flag_any==1
replace hosp_covid_anyA=. if end_date<hosp_covid_anyA
gen hosp_any_flag = hosp_covid_anyA!=.

* Composite outcome 
gen hosp_died_composite = (died_ons_covid_flag_any==1 | hosp_any_flag==1)
egen hosp_died_dateA = rowmin(died_date_onsA hosp_covid_anyA)
replace hosp_died_dateA=. if hosp_died_composite==0

* Check how composite is made up 
tab died_ons_covid_flag_any hosp_any_flag
di "Number where composite date = death date only"
count if hosp_died_dateA==died_date_onsA & hosp_died_dateA!=. & hosp_died_dateA!=hosp_covid_anyA
di "Number where composite = hospitalisation date only"
count if hosp_died_dateA==hosp_covid_anyA & hosp_died_dateA!=. & hosp_died_dateA!=died_date_onsA
di "Number where composite = both death and hospitalisation date 
count if hosp_died_dateA==died_date_onsA & hosp_died_dateA!=. & hosp_died_dateA==hosp_covid_anyA

* Make file for each outcome: covid death, hospitalisation and composite 
* Files contain patient ID, start = start study, stop = either end date for patient or date of outcome 
* and flag for outcome 
* COVID death - covid code in any position
preserve 
keep patient_id end_date died_ons_covid_flag_any died_date_onsA
gen start = date("01/03/2021", "DMY")
egen stop = rowmin(died_date_onsA end_date)
count if died_ons_covid_flag_any ==1 & end_date<died_date_onsA
replace died_ons_covid_flag_any=0 if end_date<died_date_onsA
keep patient_id start stop died_ons_covid_flag_any
rename died_ons_covid_flag_any died_covid_any_flag
* should be zero in real data
count if start==stop
drop if start==stop
save ./output/tv_outcome_died_covid_any_vacc, replace 
tab died_covid_any_flag, m
codebook patient_id
restore 

* Hospitalisation - covid code in any position
preserve 
keep patient_id end_date hosp_any_flag hosp_covid_anyA end_date_flag
gen start = date("01/03/2021", "DMY")
egen stop = rowmin(hosp_covid_anyA end_date)
count if hosp_any_flag ==1 & end_date<hosp_covid_anyA
tab end_date_flag if hosp_any_flag ==1 & end_date<hosp_covid_anyA
replace hosp_any_flag=0 if end_date<hosp_covid_anyA
keep patient_id start stop hosp_any_flag
* should be zero in real data
count if start==stop
drop if start==stop
save ./output/tv_outcome_hosp_any_vacc, replace 
tab hosp_any_flag, m
codebook patient_id
count
bys patient_id: egen total_hosp = total(hosp_any_flag)
tab total_hosp
restore 

* Composite 
preserve 
keep patient_id hosp_died* end_date
gen start = date("01/03/2021", "DMY")
egen stop = rowmin(hosp_died_dateA end_date)
count if hosp_died_composite==1 & end_date<hosp_died_dateA
replace hosp_died_composite=0 if end_date<hosp_died_dateA
keep patient_id start stop hosp_died_composite
rename hosp_died_composite composite_any_flag
* should be zero in real data
count if start==stop
drop if start==stop
save ./output/tv_outcome_composite_any_vacc, replace 
tab composite_any_flag, m
codebook patient_id
restore 

* Merge files together for each outcome
* Composite  
use ./output/tv_severe_disease_vacc, clear 
tvc_merge start stop using ./output/tv_covid_vacc_first_vacc, id(patient_id)
tvc_merge start stop using ./output/tv_total_vaccs, id(patient_id)
tvc_merge start stop using ./output/tv_liver_trans_vacc, id(patient_id)
tvc_merge start stop using ./output/time_varying_udca_vacc, id(patient_id)
tvc_merge start stop using ./output/tv_age_vacc, id(patient_id)
tvc_merge start stop using ./output/tv_outcome_composite_any_vacc, id(patient_id) failure(composite_any_flag)
* Dummy drug data includes people not in cohort, so drop these - should not be any in real data 
drop if age_tv==.
codebook patient_id
* Check number of outcomes after merge  - there will be missings for rows after event
tab composite_any_flag, m
missings report
drop if composite_any_flag==.
save ./output/tv_vars_composite_any_vacc, replace 

* COVID death - covid code in any position
use ./output/tv_severe_disease_vacc, clear 
tvc_merge start stop using ./output/tv_covid_vacc_first_vacc, id(patient_id)
tvc_merge start stop using ./output/tv_total_vaccs, id(patient_id)
tvc_merge start stop using ./output/tv_liver_trans_vacc, id(patient_id)
tvc_merge start stop using ./output/time_varying_udca_vacc, id(patient_id)
tvc_merge start stop using ./output/tv_age_vacc, id(patient_id)
tvc_merge start stop using ./output/tv_outcome_died_covid_any_vacc, id(patient_id) failure(died_covid_any_flag)
* Dummy drug data includes people not in cohort, so drop these - should not be any in real data 
drop if age_tv==.
codebook patient_id
* Check number of outcomes after merge 
tab died_covid_any_flag, m
missings report
save ./output/tv_vars_died_covid_any_vacc, replace 

* COVID hospitalisation - covid code in any position
use ./output/tv_severe_disease_vacc, clear 
tvc_merge start stop using ./output/tv_covid_vacc_first_vacc, id(patient_id)
tvc_merge start stop using ./output/tv_total_vaccs, id(patient_id)
tvc_merge start stop using ./output/tv_liver_trans_vacc, id(patient_id)
tvc_merge start stop using ./output/time_varying_udca_vacc, id(patient_id)
tvc_merge start stop using ./output/tv_age_vacc, id(patient_id)
tvc_merge start stop using ./output/tv_outcome_hosp_any_vacc, id(patient_id) failure(hosp_any_flag)
* Check number of outcomes after merge 
tab hosp_any_flag, m
bys patient_id: egen total_hosp = total(hosp_any_flag)
tab total_hosp
* Dummy drug data includes people not in cohort, so drop these - should not be any in real data 
drop if age_tv==.
codebook patient_id
* Check number of outcomes after merge - there will be missings for rows after event
tab hosp_any_flag, m 
missings report
drop if hosp_any_flag==.
save ./output/tv_vars_hosp_any_vacc, replace 

/* Format file with static covariates: sex, region, covid high risk conditions, 
ethnicity, imd, bmi, smoking. */

** Need to decide on second line therapies 
use `tempfile', clear
describe 
* Format variables 
* Sex
gen male = 1 if sex == "M"
replace male = 0 if sex == "F"
* Ethnicity
replace ethnicity=6 if ethnicity==0
label define eth5 			1 "White"  					///
                            2 "Mixed"				///						
                            3 "Asian"  					///
                            4 "Black"					///
                            5 "Other"					///
                            6 "Unknown"
                    

label values ethnicity eth5
safetab ethnicity, m
* Create White vs non-White ethnicity variable
gen eth_bin = (ethnicity!=1)
replace eth_bin = 2 if ethnicity==6
label define eth_3 0 "White" 1 "Non-White" 2 "Unknown"
label values eth_bin eth_3
tab eth_bin ethnicity, m 


* IMD - should not be missing (i.e. 0) in real data
replace imd=6 if imd==0

* BMI categories
* assume BMI's less than 10 are incorrect and set to missing 
sum bmi, d 
replace bmi = . if bmi<10
egen bmi_cat = cut(bmi), at(0, 1, 18.5, 24.9, 29.9, 39.9, 100) icodes
bys bmi_cat: sum bmi
* assume missing . is healthy range BMI
replace bmi_cat = 2 if bmi_cat==. 
label define bmi 1 "Underweight" 2 "Healthy range" 3 "Overweight" 4 "Obese" 5 "Morbidly obese"
label values bmi_cat bmi
tab bmi_cat 

* Smoking status - assume missings are non-smokers 
gen smoking = 0 if smoking_status=="N"
replace smoking = 1 if smoking_status=="S"
replace smoking = 2 if smoking_status=="E"
replace smoking = 1 if smoking==.
label define smok 1 "Current smoker" 2 "Ex-smoker" 0 "Never smoked" 
label values smoking smok
tab smoking 

* High risk covid conditions
replace oral_steroid_drugs_nhsd=. if oral_steroid_drug_nhsd_3m_count < 2 & oral_steroid_drug_nhsd_12m_count < 4
gen imid_nhsd=max(oral_steroid_drugs_nhsd, immunosuppresant_drugs_nhsd)
gen rare_neuro_nhsd = max(multiple_sclerosis_nhsd, motor_neurone_disease_nhsd, myasthenia_gravis_nhsd, huntingtons_disease_nhsd)
gen solid_organ_transplant_bin = solid_organ_transplant_nhsd_new!=""
gen any_high_risk_condition = max(learning_disability_nhsd_snomed, cancer_opensafely_snomed_new, haematological_disease_nhsd, ///
ckd_stage_5_nhsd, imid_nhsd, immunosupression_nhsd_new, hiv_aids_nhsd, solid_organ_transplant_bin, rare_neuro_nhsd)

* Time from most recent vaccination on 1st March 2021
gen date_most_recent_cov_vacA = date(date_most_recent_cov_vac, "YMD")
gen time_vacc = date("01Mar2021", "DMY") - date_most_recent_cov_vacA
sum time_vacc, d
xtile time_vacc_cat = time_vacc, nq(4)
replace time_vacc_cat = 5 if time_vacc_cat == .
bys time_vacc_cat: sum time_vacc 
label define vacc_t 1 "Q1 closest vaccination" 2 "Q2" 3 "Q3" 4 "Q4 furthest vaccination" 5 "No vaccination" 
label values time_vacc_cat vacc_t 

keep patient_id male stp any_high_risk_condition ethnicity imd bmi_cat smoking eth_bin time_vacc_cat has_pbc oca_bl
tempfile basefile
save `basefile', replace
foreach var in died_covid_any hosp_any composite_any {
    preserve 
    merge 1:m patient_id using ./output/tv_vars_`var'_vacc 
    drop _merge 
    save ./output/an_dataset_`var'_vacc, replace
    restore
}

* Sensitivity analysis - take out people with missing ethnicity, BMI or smoking for 120 file 
/* Format file with static covariates: sex, region, covid high risk conditions, 
ethnicity, imd, bmi, smoking. */

** Need to decide on second line therapies 
use `tempfile', clear
describe 
* Format variables 
* Sex
gen male = 1 if sex == "M"
replace male = 0 if sex == "F"
* Ethnicity
drop if ethnicity==0
label define eth5 			1 "White"  					///
                            2 "Mixed"				///						
                            3 "Asian"  					///
                            4 "Black"					///
                            5 "Other"					///
                                   

label values ethnicity eth5
safetab ethnicity, m
* Create White vs non-White ethnicity variable
gen eth_bin = (ethnicity!=1)
label define eth_3 0 "White" 1 "Non-White" 
label values eth_bin eth_3
tab eth_bin ethnicity, m 


* IMD - should not be missing (i.e. 0) in real data
replace imd=6 if imd==0

* BMI categories
* assume BMI's less than 10 are incorrect and set to missing 
sum bmi, d 
replace bmi = . if bmi<10
egen bmi_cat = cut(bmi), at(0, 1, 18.5, 24.9, 29.9, 39.9, 100) icodes
bys bmi_cat: sum bmi
* assume missing . is healthy range BMI
drop if bmi_cat==. 
label define bmi 1 "Underweight" 2 "Healthy range" 3 "Overweight" 4 "Obese" 5 "Morbidly obese"
label values bmi_cat bmi
tab bmi_cat 

* Smoking status - assume missings are non-smokers 
gen smoking = 0 if smoking_status=="N"
replace smoking = 1 if smoking_status=="S"
replace smoking = 2 if smoking_status=="E"
drop if smoking==.
label define smok 1 "Current smoker" 2 "Ex-smoker" 0 "Never smoked" 
label values smoking smok
tab smoking 

* High risk covid conditions
replace oral_steroid_drugs_nhsd=. if oral_steroid_drug_nhsd_3m_count < 2 & oral_steroid_drug_nhsd_12m_count < 4
gen imid_nhsd=max(oral_steroid_drugs_nhsd, immunosuppresant_drugs_nhsd)
gen rare_neuro_nhsd = max(multiple_sclerosis_nhsd, motor_neurone_disease_nhsd, myasthenia_gravis_nhsd, huntingtons_disease_nhsd)
gen solid_organ_transplant_bin = solid_organ_transplant_nhsd_new!=""
gen any_high_risk_condition = max(learning_disability_nhsd_snomed, cancer_opensafely_snomed_new, haematological_disease_nhsd, ///
ckd_stage_5_nhsd, imid_nhsd, immunosupression_nhsd_new, hiv_aids_nhsd, solid_organ_transplant_bin, rare_neuro_nhsd)

* Time from most recent vaccination on 1st March 2021
gen date_most_recent_cov_vacA = date(date_most_recent_cov_vac, "YMD")
gen time_vacc = date("01Mar2021", "DMY") - date_most_recent_cov_vacA
sum time_vacc, d
xtile time_vacc_cat = time_vacc, nq(4)
replace time_vacc_cat = 5 if time_vacc_cat == .
bys time_vacc_cat: sum time_vacc 
label define vacc_t 1 "Q1 closest vaccination" 2 "Q2" 3 "Q3" 4 "Q4 furthest vaccination" 5 "No vaccination" 
label values time_vacc_cat vacc_t 

* Exploring death by liver disease 
gen died_liver_any = died_ons_liver_flag_any==1 & died_ons_covid_flag_any!=1
gen died_liver_underlying = died_ons_liver_flag_underlying==1 & died_ons_covid_flag_any!=1

keep patient_id male stp any_high_risk_condition ethnicity imd bmi_cat smoking eth_bin time_vacc_cat has_pbc oca_bl died_liver_any died_liver_underlying
tempfile basefile
save `basefile'
foreach var in died_covid_any hosp_any composite_any {
    preserve 
    merge 1:m patient_id using ./output/tv_vars_`var', keep(3) 
    drop _merge 
    save ./output/an_dataset_`var'_nomiss, replace
    restore
}

log close 


