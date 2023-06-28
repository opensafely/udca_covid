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

merge m:1 patient_id using `tempfile', keepusing(severe_disease_fu_date severe_disease_bl covid_vacc_fu_date liver_transplant_fu_date)

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
keep patient_id covid_vacc_fu_date_update severe_disease_fu_date_update liver_transplant_fu_date_update severe_disease_bl
duplicates drop 
* Create file for each covariate to merge onto udca exposure file 
* Flag records where there is an update 
foreach var in covid_vacc liver_transplant {
    preserve
    keep patient_id `var'_fu_date_update 
    gen `var'=(`var'_fu_date_update!=.)
    gen expand = `var'+1
    tab expand
    expand expand, gen(newv)
    gen start = date("01/03/2020", "DMY") if newv==0
    replace start = `var'_fu_date_update if newv==1
    gen stop = `var'_fu_date_update if newv==0
    replace stop = date("31/12/2022", "DMY") if stop==.
    save ./output/tv_`var', replace
    restore
}

* Need to update code above so stop is end of study for individual patient i.e. death etc.
