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
save `tempfile' 

* Use time-varying exposure file and add in rows for the 6 monthly covariate assessment times 
use ./output/time_varying_udca_120, clear 
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

merge m:1 patient_id using `tempfile', keepusing(severe_disease_fu_date severe_disease_bl covid_vacc_fu_date liver_transplant_fu_date dereg_date died_date_ons)

* Determine end of follow-up date
gen dereg_dateA = date(dereg_date, "YMD")
format %dD/N/CY dereg_dateA
drop dereg_date
gen died_dateA = date(died_date_ons, "YMD")
format %dD/N/CY died_dateA
drop died_date_ons
gen end_study = date("31/12/2022", "DMY")
egen end_date = rowmin(dereg_dateA end_study died_dateA)

* Determine number of days between each covariate and dates 

* Format dates  and identify date nearest after covariate updates 
foreach var in covid_vacc_fu_date severe_disease_fu_date liver_transplant_fu_date {
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
}
* For severe disease only update variable if no severe disease at baseline 
replace severe_disease_fu_date_update = . if severe_disease_bl==1

* Keep only change dates to create time-varying dataset
keep patient_id covid_vacc_fu_date_update severe_disease_fu_date_update liver_transplant_fu_date_update severe_disease_bl end_date
duplicates drop 
* Create file for each covariate to merge onto udca exposure file 
* First covid vaccination and liver transplant as all people will begin at zero 
foreach var in covid_vacc liver_transplant {
    preserve
    keep patient_id `var'_fu_date_update end_date
    * Drop updates after the end of follow-up 
    replace `var'_fu_date = . if `var'_fu_date>end_date 
    * Flag if variable is updated
    gen `var'=(`var'_fu_date_update!=.)
    * Create extra row if variable is updated 
    gen expand = `var'+1
    tab expand
    expand expand, gen(newv)
    * Update variables so row for when zero and row for when updated - if not updated whole time will be zero 
    gen start = date("01/03/2020", "DMY") if newv==0
    replace start = `var'_fu_date_update if newv==1
    gen stop = `var'_fu_date_update if newv==0
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

* Merge files together 
use ./output/tv_severe_disease, clear 
tvc_merge start stop using ./output/tv_covid_vacc, id(patient_id)
tvc_merge start stop using ./output/tv_liver_transplant, id(patient_id)
tvc_merge start stop using ./output/time_varying_udca_120, id(patient_id)
save ./output/tv_vars, replace 

use `tempfile', clear 
** Need to prepare data for analysis and then merge on time-varying covariates 

log close 


