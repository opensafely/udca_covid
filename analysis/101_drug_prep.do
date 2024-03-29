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

describe 

*Some records identified in study_definition_additional 
*missings report, minimum(12400)
missings dropvars udca_*, force

* Format dates
* First count number of variables for loop
describe 
local var = r(k)-1
forvalues i=1/`var' {
    gen udcaA`i' = date(udca_`i', "YMD")
    format udcaA`i' %dD/N/CY
    drop udca_`i'
}

* Reshape to long format 
reshape long udcaA, i(patient_id) j(presc_number)

* Drop rows where there is no prescription
drop if udcaA==.

* Check that prescriptions are in order
gen order_flag = (udcaA<udcaA[_n-1] & patient_id==patient_id[_n-1])
tab order_flag 
* Create flag if any out of order prescriptions in the data - should only be in dummy data 
egen out_of_order = max(order_flag)
tab out_of_order

* Sort if out of order - should only apply to dummy data 
sort patient_id udcaA 

drop order_flag
* Check in order
gen order_flag = (udcaA<udcaA[_n-1] & patient_id==patient_id[_n-1])
tab order_flag

* Identify prescriptions with the same date 
bys patient_id (udcaA): gen dup_presc = (udcaA==udcaA[_n-1])
tab dup_presc 
* Drop them 
drop if dup_presc 

drop order_flag out_of_order dup_presc presc_number

* Re-count number of prescriptions 
gen udca=1
bys patient_id: egen total_no_presc = total(udca)
sum total_no_presc, d

* Determine length of time from previous prescription 
bys patient_id (udcaA): gen time_previous = udcaA - udcaA[_n-1]
sum time_previous, d 
gen year = year(udcaA)
bys year: sum time_previous, d

* Drop records in 2023 as this is after end of study
drop if year==2023
* Loop through assuming end date is 60 up to 180 days after prescription generated
forvalues i = 60(30)180 {
    preserve
    gen stop_date = udcaA + `i'
    format stop_date %dD/N/CY 

    * Drop rows where prescriptions ends prior to March 2020
    count if stop_date <= date("01March2020", "DMY")
    drop if stop_date <= date("01March2020", "DMY")

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
    keep patient_id start stop udca total_no_presc
    duplicates drop 

    * Add in rows where there are gaps between prescriptions 
    bys patient_id (start): gen to_expand = 1 + (stop < start[_n+1])*(start[_n+1]~=.)
    tab to_expand 
    expand to_expand 

    * Flag new rows
    bys patient_id start: gen new_record = (_n==2)
    tab to_expand new_record 

    * Updating new rows 
    sort patient_id start
    replace udca=0 if new_record==1
    replace start = stop if new_record==1
    bys patient_id (start): replace stop = start[_n+1] if new_record==1
    drop new_record to_expand

    * Checks 
    count if stop<start 
    sort patient_id start
    count if stop[_n-1]>start & patient_id==patient_id[_n-1]

    * Update rows to match follow-up time
    * merge variables from original study definition 
    merge m:1 patient_id using `tempfile', keepusing(dereg_date died_date_ons udca_count_bl) 
    tab _merge

    * Update variables for people without any prescriptions 
    replace start = date("01/03/2020", "DMY") if _merge==2
    replace udca = 0 if _merge==2
    replace stop = date("31/12/2022", "DMY") if _merge==2
    replace total_no_presc = 0 if _merge==2

    * Determine end of follow-up date
    gen dereg_dateA = date(dereg_date, "YMD")
    format %dD/N/CY dereg_dateA
    drop dereg_date
    gen died_dateA = date(died_date_ons, "YMD")
    format %dD/N/CY died_dateA
    drop died_date_ons
    gen end_study = date("31/12/2022", "DMY")
    egen end_date = rowmin(dereg_dateA end_study died_dateA)
    * Create flag indicating reason for end of follow-up 
    gen end_date_flag = (end_date==dereg_dateA)
    replace end_date_flag = 2 if end_date==died_dateA
    replace end_date_flag = 3 if end_date==end_study
    
    * Count number of days of follow-up 
    gen total_fu = end_date - date("01/03/2020", "DMY")

    ** Update start and end of follow-up for cohort
    * Identify prescriptions that start prior to March 2020
    gen start_prior = (start < date("01/03/2020", "DMY"))
    replace start = date("01/03/2020", "DMY") if start_prior==1

    * Identify first prescriptions that start after March 2020
    bys patient_id (start): gen start_after = 1 + (start > date("01/03/2020", "DMY") & _n==1)
    tab start_after
    expand start_after

    * Flag new rows
    bys patient_id start: gen new_record = (_n==2)
    tab start_after new_record 

    * Updating new rows 
    sort patient_id start
    replace udca=0 if new_record==1
    replace stop = start if new_record==1
    replace start = date("01/03/2020", "DMY") if new_record==1
    drop new_record start_after

    tab end_date_flag if start==date("01/03/2020", "DMY"), m 
    * Identify rows that end after study end date for person 
    gen end_after = (stop > end_date )
    gen end_before = (start > end_date) 

    tab end_after
    tab end_after end_date_flag
    tab end_before 

    * Drop whole rows that are after end_date 
    drop if end_before 

    * Check years of stop dates 
    gen yr_stop = year(stop)
    tab yr_stop end_after 

    * Check those flagged as ending after are last row only 
    bys patient_id (start): gen last = _n==_N
    tab last end_after 
    * Check how many records end after end date - should just be one
    bys patient_id: egen tot_end_after = total(end_after)

    replace stop = end_date if end_after==1 & end_before==0

    * Identify prescriptions that end prior to end of follow-up 
    bys patient_id (start): gen stop_prior = 1 + (stop < end_date & _n==_N)
    tab stop_prior
    expand stop_prior

    * Flag new rows
    bys patient_id start: gen new_record = (_n==2)
    tab stop_prior new_record 

    * Updating new rows 
    sort patient_id start
    replace udca=0 if new_record==1
    replace start =  stop if new_record==1
    replace stop = end_date if new_record==1
    drop new_record stop_prior

    di "number where start after stop date"
    count if start > stop 
    di "Number where start equals stop"
    count if start==stop 
    drop if start==stop 
    * Check that time covered by prescriptions equals total follow-up
    gen time = stop - start 
    sum time, d  
    bys patient_id: egen total_time = total(time)

    gen total_time_unequal = total_time!=total_fu
    tab total_time_unequal, m

    save ./output/time_varying_udca_all_vars_`i'
    * Drop unnecessary variables
    keep patient_id start stop udca 

    save ./output/time_varying_udca_`i'
    restore
}

* Sensitivity analysis - add on overlapping days to the next unexposed period up to 120 days. 120 exposure only.

gen stop_date = udcaA + 120
format stop_date %dD/N/CY 

* Drop rows where prescriptions ends prior to March 2020
count if stop_date <= date("01March2020", "DMY")
drop if stop_date <= date("01March2020", "DMY")

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
* Determine number of overlapping days 
bys patient_id (udcaA): gen overlap = stop_date - udcaA[_n+1]
* Set to missing if no overlap
replace overlap=. if overlap<=0
bys patient_id spell_sum: egen total_overlap = total(overlap)
sum total_overlap, d
* Only want to add up to 120 days so create variable cut to 120 days if over 120 days overlap
gen overlap_add = total_overlap
replace overlap_add = 120 if total_overlap>120 & total_overlap!=.
keep patient_id start stop udca total_no_presc overlap_add
duplicates drop 
sum overlap_add, d 

* Add on overlapping days 
* Generate new stop date with 120 days added
gen new_stop = stop + overlap_add
* Update stop date with this date if there is an overlap 
replace stop = new_stop if overlap_add!=0
* Identify spells where prescriptions overlap and combine rows
bys patient_id (start): gen spell = start > stop[_n-1]
bys patient_id (start): replace spell = 1 if _n==1
bys patient_id (start): gen spell_sum = sum(spell) 
sum spell_sum
* Start date of spell 
bys patient_id spell_sum (start): gen start_n = start[1] 
bys patient_id spell_sum (start): gen stop_n = stop[_N] 
format start_n stop_n %dD/N/CY
keep patient_id start_n stop_n udca total_no_presc
rename start_n start 
rename stop_n stop
duplicates drop 

* Add in rows where there are gaps between prescriptions 
bys patient_id (start): gen to_expand = 1 + (stop < start[_n+1])*(start[_n+1]~=.)
tab to_expand 
expand to_expand 

* Flag new rows
bys patient_id start: gen new_record = (_n==2)
tab to_expand new_record 

* Updating new rows 
sort patient_id start
replace udca=0 if new_record==1
replace start = stop if new_record==1
bys patient_id (start): replace stop = start[_n+1] if new_record==1
drop new_record to_expand

* Checks 
count if stop<start 
sort patient_id start
count if stop[_n-1]>start & patient_id==patient_id[_n-1]

* Update rows to match follow-up time
* merge variables from original study definition 
merge m:1 patient_id using `tempfile', keepusing(dereg_date died_date_ons udca_count_bl) 
tab _merge

* Update variables for people without any prescriptions 
replace start = date("01/03/2020", "DMY") if _merge==2
replace udca = 0 if _merge==2
replace stop = date("31/12/2022", "DMY") if _merge==2
replace total_no_presc = 0 if _merge==2

* Determine end of follow-up date
gen dereg_dateA = date(dereg_date, "YMD")
format %dD/N/CY dereg_dateA
drop dereg_date
gen died_dateA = date(died_date_ons, "YMD")
format %dD/N/CY died_dateA
drop died_date_ons
gen end_study = date("31/12/2022", "DMY")
egen end_date = rowmin(dereg_dateA end_study died_dateA)
* Create flag indicating reason for end of follow-up 
gen end_date_flag = (end_date==dereg_dateA)
replace end_date_flag = 2 if end_date==died_dateA
replace end_date_flag = 3 if end_date==end_study

* Count number of days of follow-up 
gen total_fu = end_date - date("01/03/2020", "DMY")

** Update start and end of follow-up for cohort
* Identify prescriptions that start prior to March 2020
gen start_prior = (start < date("01/03/2020", "DMY"))
replace start = date("01/03/2020", "DMY") if start_prior==1

* Identify first prescriptions that start after March 2020
bys patient_id (start): gen start_after = 1 + (start > date("01/03/2020", "DMY") & _n==1)
tab start_after
expand start_after

* Flag new rows
bys patient_id start: gen new_record = (_n==2)
tab start_after new_record 

* Updating new rows 
sort patient_id start
replace udca=0 if new_record==1
replace stop = start if new_record==1
replace start = date("01/03/2020", "DMY") if new_record==1
drop new_record start_after

tab end_date_flag if start==date("01/03/2020", "DMY"), m 
* Identify rows that end after study end date for person 
gen end_after = (stop > end_date )
gen end_before = (start > end_date) 

tab end_after
tab end_after end_date_flag
tab end_before 

* Drop whole rows that are after end_date 
drop if end_before 

* Check years of stop dates 
gen yr_stop = year(stop)
tab yr_stop end_after 

* Check those flagged as ending after are last row only 
bys patient_id (start): gen last = _n==_N
tab last end_after 
* Check how many records end after end date - should just be one
bys patient_id: egen tot_end_after = total(end_after)

replace stop = end_date if end_after==1 & end_before==0

* Identify prescriptions that end prior to end of follow-up 
bys patient_id (start): gen stop_prior = 1 + (stop < end_date & _n==_N)
tab stop_prior
expand stop_prior

* Flag new rows
bys patient_id start: gen new_record = (_n==2)
tab stop_prior new_record 

* Updating new rows 
sort patient_id start
replace udca=0 if new_record==1
replace start =  stop if new_record==1
replace stop = end_date if new_record==1
drop new_record stop_prior

di "number where start after stop date"
count if start > stop 
di "Number where start equals stop"
count if start==stop 
drop if start==stop 
* Check that time covered by prescriptions equals total follow-up
gen time = stop - start 
sum time, d  
bys patient_id: egen total_time = total(time)

gen total_time_unequal = total_time!=total_fu
tab total_time_unequal, m

save ./output/time_varying_udca_overlap_all_vars_120
* Drop unnecessary variables
keep patient_id start stop udca 

save ./output/time_varying_udca_overlap_120

* Sensitivity analysis - March 2021 cohort - vaccinations

import delimited using ./output/input_vacc.csv, clear 
save `tempfile', replace 

** First import udca population
import delimited using ./output/input_addvacc.csv, clear

describe 

*Some records identified in study_definition_additional 
*missings report, minimum(12400)
missings dropvars udca_*, force

* Format dates
* First count number of variables for loop
describe 
local var = r(k)-1
forvalues i=1/`var' {
    gen udcaA`i' = date(udca_`i', "YMD")
    format udcaA`i' %dD/N/CY
    drop udca_`i'
}

* Reshape to long format 
reshape long udcaA, i(patient_id) j(presc_number)

* Drop rows where there is no prescription
drop if udcaA==.

* Check that prescriptions are in order
gen order_flag = (udcaA<udcaA[_n-1] & patient_id==patient_id[_n-1])
tab order_flag 
* Create flag if any out of order prescriptions in the data - should only be in dummy data 
egen out_of_order = max(order_flag)
tab out_of_order

* Sort if out of order - should only apply to dummy data 
sort patient_id udcaA 

drop order_flag
* Check in order
gen order_flag = (udcaA<udcaA[_n-1] & patient_id==patient_id[_n-1])
tab order_flag

* Identify prescriptions with the same date 
bys patient_id (udcaA): gen dup_presc = (udcaA==udcaA[_n-1])
tab dup_presc 
* Drop them 
drop if dup_presc 

drop order_flag out_of_order dup_presc presc_number

* Re-count number of prescriptions 
gen udca=1
bys patient_id: egen total_no_presc = total(udca)
sum total_no_presc, d

* Determine length of time from previous prescription 
bys patient_id (udcaA): gen time_previous = udcaA - udcaA[_n-1]
sum time_previous, d 
gen year = year(udcaA)
bys year: sum time_previous, d

* Drop records in 2023 as this is after end of study
drop if year==2023
* assume end date of prescription is 120 days to match primary analysis 

gen stop_date = udcaA + 120
format stop_date %dD/N/CY 

* Drop rows where prescriptions ends prior to March 2020
count if stop_date <= date("01March2021", "DMY")
drop if stop_date <= date("01March2021", "DMY")

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
keep patient_id start stop udca total_no_presc
duplicates drop 

* Add in rows where there are gaps between prescriptions 
bys patient_id (start): gen to_expand = 1 + (stop < start[_n+1])*(start[_n+1]~=.)
tab to_expand 
expand to_expand 

* Flag new rows
bys patient_id start: gen new_record = (_n==2)
tab to_expand new_record 

* Updating new rows 
sort patient_id start
replace udca=0 if new_record==1
replace start = stop if new_record==1
bys patient_id (start): replace stop = start[_n+1] if new_record==1
drop new_record to_expand

* Checks 
count if stop<start 
sort patient_id start
count if stop[_n-1]>start & patient_id==patient_id[_n-1]

* Update rows to match follow-up time
* merge variables from original study definition 
merge m:1 patient_id using `tempfile', keepusing(dereg_date died_date_ons udca_count_bl) 
tab _merge

* Update variables for people without any prescriptions 
replace start = date("01/03/2021", "DMY") if _merge==2
replace udca = 0 if _merge==2
replace stop = date("31/12/2022", "DMY") if _merge==2
replace total_no_presc = 0 if _merge==2

* Determine end of follow-up date
gen dereg_dateA = date(dereg_date, "YMD")
format %dD/N/CY dereg_dateA
drop dereg_date
gen died_dateA = date(died_date_ons, "YMD")
format %dD/N/CY died_dateA
drop died_date_ons
gen end_study = date("31/12/2022", "DMY")
egen end_date = rowmin(dereg_dateA end_study died_dateA)
* Create flag indicating reason for end of follow-up 
gen end_date_flag = (end_date==dereg_dateA)
replace end_date_flag = 2 if end_date==died_dateA
replace end_date_flag = 3 if end_date==end_study

* Count number of days of follow-up 
gen total_fu = end_date - date("01/03/2020", "DMY")

** Update start and end of follow-up for cohort
* Identify prescriptions that start prior to March 2020
gen start_prior = (start < date("01/03/2021", "DMY"))
replace start = date("01/03/2021", "DMY") if start_prior==1

* Identify first prescriptions that start after March 2021
bys patient_id (start): gen start_after = 1 + (start > date("01/03/2021", "DMY") & _n==1)
tab start_after
expand start_after

* Flag new rows
bys patient_id start: gen new_record = (_n==2)
tab start_after new_record 

* Updating new rows 
sort patient_id start
replace udca=0 if new_record==1
replace stop = start if new_record==1
replace start = date("01/03/2021", "DMY") if new_record==1
drop new_record start_after

tab end_date_flag if start==date("01/03/2021", "DMY"), m 
* Identify rows that end after study end date for person 
gen end_after = (stop > end_date )
gen end_before = (start > end_date) 

tab end_after
tab end_after end_date_flag
tab end_before 

* Drop whole rows that are after end_date 
drop if end_before 

* Check years of stop dates 
gen yr_stop = year(stop)
tab yr_stop end_after 

* Check those flagged as ending after are last row only 
bys patient_id (start): gen last = _n==_N
tab last end_after 
* Check how many records end after end date - should just be one
bys patient_id: egen tot_end_after = total(end_after)

replace stop = end_date if end_after==1 & end_before==0

* Identify prescriptions that end prior to end of follow-up 
bys patient_id (start): gen stop_prior = 1 + (stop < end_date & _n==_N)
tab stop_prior
expand stop_prior

* Flag new rows
bys patient_id start: gen new_record = (_n==2)
tab stop_prior new_record 

* Updating new rows 
sort patient_id start
replace udca=0 if new_record==1
replace start =  stop if new_record==1
replace stop = end_date if new_record==1
drop new_record stop_prior

di "number where start after stop date"
count if start > stop 
di "Number where start equals stop"
count if start==stop 
drop if start==stop 
* Check that time covered by prescriptions equals total follow-up
gen time = stop - start 
sum time, d  
bys patient_id: egen total_time = total(time)

gen total_time_unequal = total_time!=total_fu
tab total_time_unequal, m

save ./output/time_varying_udca_all_vars_vacc
* Drop unnecessary variables
keep patient_id start stop udca 

save ./output/time_varying_udca_vacc





