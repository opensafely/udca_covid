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

* Use time-varying exposure file and add in rows for the 6 monthly covariate assessment times 
use ./output/time_varying_udca_120, clear 
codebook patient_id
merge m:1 patient_id using `tempfile', keepusing(severe_disease_fu_date severe_disease_bl covid_vacc_first_date liver_transplant_fu_date dereg_date died_date_ons)
* Only using start date as this is when udca exposure or 6 monthly check occurs
drop stop
gen expand=1
bys patient_id (start): replace expand=6 if _n==_N 
expand expand, generate(newv)
bys patient_id newv: gen number = _n 
replace start = date("01/09/2020", "DMY") if newv==1 & number==1
replace start = date("01/03/2021", "DMY") if newv==1 & number==2
replace start = date("01/09/2021", "DMY") if newv==1 & number==3
replace start = date("01/03/2022", "DMY") if newv==1 & number==4
replace start = date("01/09/2022", "DMY") if newv==1 & number==5

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

* Determine number of days between each covariate and dates of UDCA change or 6 monthly check date 

* Format dates  and identify date nearest after covariate updates 
foreach var in covid_vacc_first_date severe_disease_fu_date liver_transplant_fu_date {
    gen `var'A = date(`var', "YMD")
    format `var'A %dD/N/CY 
    drop `var'
    * time between date of record and change in covariate
    gen time_`var' = start - `var'A
    * Set time variable for records prior to change as missing
    replace time_`var'=. if time_`var'<0
    * Find earliest start date after covariate update
    bys patient_id (time_`var'): gen `var'_update = start[1] if `var'A!=.
    format `var'_update %dD/N/CY 
    count if `var'_update < `var'A
}
* For severe disease only update variable if no severe disease at baseline 
replace severe_disease_fu_date_update = . if severe_disease_bl==1

* Keep only change dates to create time-varying dataset
keep patient_id covid_vacc_first_date_update severe_disease_fu_date_update liver_transplant_fu_date_update severe_disease_bl end_date
* Chercking number of patient_id's 
codebook patient_id
duplicates drop 
codebook patient_id
* Create file for each covariate to merge onto udca exposure file 
* First covid vaccination and liver transplant as all people will begin at zero 
foreach var in covid_vacc_first liver_transplant_fu {
    preserve
    keep patient_id `var'_date_update end_date
    * Drop updates after the end of follow-up 
    replace `var'_date = . if `var'_date>end_date 
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
    * drop start==stop but should not drop any in real data 
    drop if start==stop 
    count if stop<start
    save ./output/tv_`var', replace
    restore
}

* Same for liver disease severity, but variable can start at 1 so remains as this for whole of follow-up 
preserve
keep patient_id severe_disease_fu_date_update end_date severe_disease_bl
* Drop updates after the end of follow-up 
replace severe_disease_fu_date_update=. if severe_disease_fu_date_update>end_date 
* Flag if variable is updated
gen severe_disease=(severe_disease_fu_date_update!=.)
tab severe_disease 
replace severe_disease = 0 if severe_disease_bl==1
* Create extra row if variable is updated 
gen expand = severe_disease + 1
tab expand
expand expand, gen(newv)
* Update variables so row for when zero and row for when updated - if not updated whole time will be zero 
gen start = date("01/03/2020", "DMY") if newv==0
replace start = severe_disease_fu_date_update if newv==1
gen stop = severe_disease_fu_date_update if newv==0
replace stop = end_date if stop==.
replace severe_disease=0 if newv==0 & severe_disease_bl==0
replace severe_disease=1 if newv==0 & severe_disease_bl==1
save ./output/tv_severe_disease_check, replace
keep patient_id severe_disease start stop
* Check data 
count if start==stop
* drop start==stop but should not drop any in real data 
drop if start==stop 
count if stop<start
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
save ./output/tv_waves, replace

* Outcomes 
use `tempfile', clear
* Determine end of follow-up date
gen dereg_dateA = date(dereg_date, "YMD")
format %dD/N/CY dereg_dateA
drop dereg_date
gen died_date_onsA = date(died_date_ons, "YMD")
format %dD/N/CY died_date_onsA
drop died_date_ons
gen end_study = date("31/12/2022", "DMY")
egen end_date = rowmin(dereg_dateA end_study died_date_onsA)
gen hosp_covid_anyA = date(hosp_covid_any, "YMD")
* Flag hospitalised with covid 
gen hosp_any_flag = hosp_covid_anyA!=.

* Composite outcome 
gen hosp_died_composite = (died_ons_covid_flag_any==1 | hosp_any_flag==1)
egen hosp_died_dateA = rowmin(died_date_onsA hosp_covid_anyA)

* Make file for each outcome: covid death, hospitalisation and composite 
* Files contain patient ID, start = start study, stop = either end date for patient or date of outcome and flag for outcome 
* COVID death - any position
preserve 
keep patient_id end_date died_ons_covid_flag_any died_date_onsA
gen start = date("01/03/2020", "DMY")
egen stop = rowmin(died_date_onsA end_date)
count if died_ons_covid_flag_any ==1 & end_date<died_date_onsA
replace died_ons_covid_flag_any=0 if end_date<died_date_onsA
keep patient_id start stop died_ons_covid_flag_any
rename died_ons_covid_flag_any died_covid_any_flag
save ./output/tv_outcome_died_any, replace 
tab died_covid_any_flag
restore 

* Hospitalisation - any position
preserve 
keep patient_id end_date hosp_any_flag hosp_covid_anyA
gen start = date("01/03/2020", "DMY")
egen stop = rowmin(hosp_covid_anyA end_date)
count if hosp_any_flag ==1 & end_date<hosp_covid_anyA
replace hosp_any_flag=0 if end_date<hosp_covid_anyA
keep patient_id start stop hosp_any_flag
save ./output/tv_outcome_hosp_any, replace 
tab hosp_any_flag, m
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
save ./output/tv_outcome_composite, replace 
tab composite_any_flag
restore 

* Merge files together for each outcome
* Composite  
use ./output/tv_severe_disease, clear 
tvc_merge start stop using ./output/tv_covid_vacc_first, id(patient_id)
tvc_merge start stop using ./output/tv_liver_transplant_fu, id(patient_id)
tvc_merge start stop using ./output/time_varying_udca_120, id(patient_id)
tvc_merge start stop using ./output/tv_age, id(patient_id)
tvc_merge start stop using ./output/tv_waves, id(patient_id)
tvc_merge start stop using ./output/tv_outcome_composite, id(patient_id) failure(hosp_died_composite)
save ./output/tv_vars_composite, replace 
* Check number of outcomes after merge 
tab composite_any_flag

* COVID death - any position
use ./output/tv_severe_disease, clear 
tvc_merge start stop using ./output/tv_covid_vacc_first, id(patient_id)
tvc_merge start stop using ./output/tv_liver_transplant_fu, id(patient_id)
tvc_merge start stop using ./output/time_varying_udca_120, id(patient_id)
tvc_merge start stop using ./output/tv_age, id(patient_id)
tvc_merge start stop using ./output/tv_waves, id(patient_id)
tvc_merge start stop using ./output/tv_outcome_died_any, id(patient_id) failure(died_ons_covid_flag_any)
save ./output/tv_vars_died_any, replace 
tab died_covid_any_flag

* COVID hospitalisation - any position
use ./output/tv_severe_disease, clear 
tvc_merge start stop using ./output/tv_covid_vacc_first, id(patient_id)
tvc_merge start stop using ./output/tv_liver_transplant_fu, id(patient_id)
tvc_merge start stop using ./output/time_varying_udca_120, id(patient_id)
tvc_merge start stop using ./output/tv_age, id(patient_id)
tvc_merge start stop using ./output/tv_waves, id(patient_id)
tvc_merge start stop using ./output/tv_outcome_hosp_any, id(patient_id) failure(hosp_any_flag)
save ./output/tv_vars_hosp_any, replace 
* Check number of outcomes after merge 
tab hosp_any_flag, m
/* Format file with static covariates: sex, region, covid high risk conditions, 
ethnicity, imd, bmi, smoking. */

** Need to decide on second line therapies 
use `tempfile', clear
describe 
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
* IMD
replace imd=6 if imd==0

* BMI categories
egen bmi_cat = cut(bmi), at(0, 1, 18.5, 24.9, 29.9, 39.9, 100) icodes
bys bmi_cat: sum bmi
* add missing . to zero category
replace bmi_cat = 0 if bmi_cat==. 
label define bmi 0 "Missing" 1 "Underweight" 2 "Healthy range" 3 "Overweight" 4 "Obese" 5 "Morbidly obese"
label values bmi_cat bmi

* Smoking status
gen smoking = 0 if smoking_status=="N"
replace smoking = 1 if smoking_status=="S"
replace smoking = 2 if smoking_status=="E"
replace smoking = 3 if smoking==.

* High risk covid conditions
replace oral_steroid_drugs_nhsd=. if oral_steroid_drug_nhsd_3m_count < 2 & oral_steroid_drug_nhsd_12m_count < 4
gen imid_nhsd=max(oral_steroid_drugs_nhsd, immunosuppresant_drugs_nhsd)
gen rare_neuro_nhsd = max(multiple_sclerosis_nhsd, motor_neurone_disease_nhsd, myasthenia_gravis_nhsd, huntingtons_disease_nhsd)
gen solid_organ_transplant_bin = solid_organ_transplant_nhsd_new!=""
gen any_high_risk_condition = max(learning_disability_nhsd_snomed, cancer_opensafely_snomed_new, haematological_disease_nhsd, ///
ckd_stage_5_nhsd, imid_nhsd, immunosupression_nhsd_new, hiv_aids_nhsd, solid_organ_transplant_bin, rare_neuro_nhsd)

keep patient_id age male stp any_high_risk_condition ethnicity imd bmi_cat smoking 

foreach var in died_any hosp_any composite {
    preserve 
    merge 1:m patient_id using ./output/tv_vars_`var' 
    drop _merge 
    save ./output/an_dataset_`var', replace
    restore
}

log close 


