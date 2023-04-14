/*==============================================================================
DO FILE NAME:			drug_prep.do
DATE: 					13/04/2023
AUTHOR:					R Costello 
DESCRIPTION OF FILE:	Import UDCA drug data and clean and reformat to long form 
==============================================================================*/
adopath + ./analysis/ado 

* Open a log file
cap log using ./logs/drug_prep.log, replace

cap mkdir ./output/tables/

tempfile tempfile 
import delimited using ./output/input_pbc.csv
save `tempfile' 

** First import udca population
import delimited using ./output/input_additional.csv, clear

* Format dates 
forvalues i=1/40 {
gen udcaA`i' = date(udca_`i', "YMD")
format udcaA`i' %dD/N/CY
drop udca_`i'
}

* Reshape to long format 
reshape long udcaA, i(patient_id) j(presc_number)

* Drop rows where there is no prescription
drop if udcaA==.

* Check that prescriptions are in order
gen order_flag = (udcaA<udcaA[_n-1] & patient_id==patient_id)
tab order_flag 
* Create flag if any out of order prescriptions in the data - should only be in dummy data 
egen out_of_order = max(order_flag)

* Sort if out of order - should only apply to dummy data 
sort patient_id udcaA if out_of_order==1 

* Identify prescriptions with the same date 
bys patient_id: gen dup_presc = (udcaA==udcaA[_n-1])
tab dup_presc 
* Drop them 
drop if dup_presc 

drop order_flag out_of_order dup_presc 

* Assume end date is 60 days after prescription generated
gen stop_date = udcaA + 60 
format stop_date %dD/N/CY 

* Collapse adjacent prescriptions that are continuous prescribing into one period 
* Flag if start date is greater than assumed stop date of previous prescription 
bys patient_id (udcaA): gen spell = udcaA > stop_date[_n-1]
bys patient_id (udcaA): replace spell = 1 if _n==1
* Flag each row associated with each spell 
bys patient_id (udcaA): gen spell_sum = sum(spell) 
* Start date of spell 
bys patient_id spell_sum (udcaA): gen start = udcaA[1] 
bys patient_id spell_sum (udcaA): gen stop = stop_date[_N] 
format start stop %dD/N/CY
keep patient_id start stop 
duplicates drop 
gen udca=1

* Add in rows where there are gaps in prescriptions 
bys patient_id (start): gen to_expand = 1 + (stop < start[_n+1])*(start[_n+1]~=.)
tab to_expand 
expand to_expand 

* Flag new rows
bys patient_id start: gen new_record = (_n==2)
tab to_expand new_record 

* Updating new rows 
replace udca=0 if new_record==1
replace start = stop if new_record==1
replace stop = start[_n+1] if new_record==1
drop new_record to_expand

* Update to match follow-up time
* merge variables from original study definition 
merge m:1 patient_id using `tempfile', keep(dereg_date, died_fu) 

* Determine end of follow-up date
gen dereg_dateA = date(dereg_date, "YMD")
format %dD/N/CY dereg_dateA
drop dereg_date
gen died_fuA = date(died_fu, "YMD")
format %dD/N/CY died_fuA
drop died_fu
gen end_study = date("31/12/2022", "DMY")
egen end_date = rowmin(dereg_dateA end_study died_fu)

*** Update start and end of follow-up for cohort












