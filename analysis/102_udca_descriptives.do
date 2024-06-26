/*==============================================================================
DO FILE NAME:			udca_descriptives.do
DATE: 					25/04/2023
AUTHOR:					R Costello 
DESCRIPTION OF FILE:	Produce descriptives of UDCA prescribing  
==============================================================================*/
adopath + ./analysis/ado 
cap mkdir ./output/tables

* Open a log file
cap log using ./logs/udca_descriptives.log, replace

tempfile tempfile 
import delimited using ./output/input_pbc.csv
save `tempfile' 

file open tablecontent using ./output/tables/udca_descriptives.txt, write text replace
* Loop through each dataset with different lengths of days of prescriptions
forvalues i=60(30)180 {
    use ./output/time_varying_udca_all_vars_`i', clear 
    drop last _merge 
    merge m:1 patient_id using `tempfile', keepusing(stp has_pbc)
    drop if stp==""
    tab udca, m
    bys patient_id: gen last = _n==_N 
    bys patient_id (start): gen udca_bl_check = udca[1]
    tab udca_count_bl udca_bl_check  
    file write tablecontent _tab ("Number of obervations") _tab ("Mean") _tab ("SD") _tab ("Median") _tab ("25th percentile") _tab ("75th percentile") _n 

    * summarise total number of prescriptions during follow-up 
    sum total_no_presc if last==1, d 
    file write tablecontent ("Number of prescriptions `i'") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n 

    * Summarise follow-up 
    sum total_fu if last==1, d
    file write tablecontent ("Total length of follow-up `i'") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n 

    * Summarise proportion of time on udca 
    * First generate time for each row 
    *gen time = stop - start 
    * Generate total time on & off udca 
    * First calculate time for both on and off within one variable 
    bys patient_id udca: egen time_udca = total(time)
    * From this generate variable with time off udca 
    bys patient_id: egen time_off_udca = max(time_udca) if udca==0
    bys patient_id (time_off_udca): replace time_off_udca = time_off_udca[_n-1] if time_off_udca==. & time_off_udca[_n-1]!=.
    * Update time_udca to only contain time on udca 
    replace time_udca=. if udca==0
    bys patient_id: egen time_on_udca = max(time_udca)
    * Check on and off equals total time of follow-up 
    count if time_on_udca + time_off_udca!=total_fu

    sum time_on_udca if last==1, d 
    file write tablecontent ("Total time on UDCA `i'") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n 

    sum time_off_udca if last==1, d 
    file write tablecontent ("Total time off UDCA `i'") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n 

    bys patient_id: gen rows = _N 
    sum rows if last==1, d 
    file write tablecontent ("Number of rows `i'") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n _n 

    * Summarising switching
    gen udca_bl = (udca_count_bl>=1 & udca_count_bl!=.) 
    gen yr_start = year(start)
    sum yr_start 
    gen switch_`i'_i = udca!=udca_bl
    bys patient_id: egen switch_`i' = max(switch_`i'_i)
    bys patient_id: egen switch_`i'_total = total(switch_`i'_i)
    gen switch_`i'_start = (switch_`i'==1 & udca_bl==0)
    gen switch_`i'_stop = (switch_`i'==1 & udca_bl==1)
    gen switch_`i'_multi = (switch_`i'_total>1 & switch_`i'_total!=.)
    keep if last==1
    tab switch_`i'  
    safecount if switch_`i'==1
    file write tablecontent ("switching") _tab ("Number switched") _tab ("Percent switched") _tab ("Switched from unexposed") _tab ("Percent switched unexposed") _tab ("Switched from exposed") _tab ("Percent switched exposed") _n 
    file write tablecontent ("`i'") _tab %3.1f (r(N)) _tab  
    local percent = (r(N)/_N)*100
    safecount if switch_`i'_start==1
    file write tablecontent (`percent') _tab  %3.1f (r(N)) _tab 
    local percent_stt = (r(N)/_N)*100
    safecount if switch_`i'_stop==1
    file write tablecontent (`percent_stt') _tab  %3.1f (r(N)) _tab 
    local percent_stp = (r(N)/_N)*100
    file write tablecontent (`percent_stp') _n _n 
}

use ./output/time_varying_udca_overlap_all_vars_120, clear 
drop last _merge 
merge m:1 patient_id using `tempfile', keepusing(stp)
drop if stp==""
bys patient_id: gen last = _n==_N 
file write tablecontent _tab ("Number of obervations") _tab ("Mean") _tab ("SD") _tab ("Median") _tab ("25th percentile") _tab ("75th percentile") _n 

* summarise total number of prescriptions during follow-up 
sum total_no_presc if last==1, d 
file write tablecontent ("Number of prescriptions overlap 120") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n 

* Summarise follow-up 
sum total_fu if last==1, d
file write tablecontent ("Total length of follow-up overlap 120") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n 

* Summarise proportion of time on udca 
* First generate time for each row 
*gen time = stop - start 
* Generate total time on & off udca 
* First calculate time for both on and off within one variable 
bys patient_id udca: egen time_udca = total(time)
* From this generate variable with time off udca 
bys patient_id: egen time_off_udca = max(time_udca) if udca==0
bys patient_id (time_off_udca): replace time_off_udca = time_off_udca[_n-1] if time_off_udca==. & time_off_udca[_n-1]!=.
* Update time_udca to only contain time on udca 
replace time_udca=. if udca==0
bys patient_id: egen time_on_udca = max(time_udca)
* Check on and off equals total time of follow-up 
count if time_on_udca + time_off_udca!=total_fu

sum time_on_udca if last==1, d 
file write tablecontent ("Total time on UDCA overlap 120") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n 

sum time_off_udca if last==1, d 
file write tablecontent ("Total time off UDCA overlap 120") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n 

bys patient_id: gen rows = _N 
sum rows if last==1, d 
file write tablecontent ("Number of rows overlap 120") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n _n 

* Summarising switching
gen udca_bl = (udca_count_bl>=1 & udca_count_bl!=.) 
gen yr_start = year(start)
sum yr_start 
gen switch_o_120_i = udca!=udca_bl
bys patient_id: egen switch_o_120 = max(switch_o_120_i)
bys patient_id: egen switch_o_120_total = total(switch_o_120_i)
gen switch_o_120_start = (switch_o_120==1 & udca_bl==0)
gen switch_o_120_stop = (switch_o_120==1 & udca_bl==1)
gen switch_o_120_multi = (switch_o_120_total>1 & switch_o_120_total!=.)
keep if last==1
tab switch_o_120  
safecount if switch_o_120==1
file write tablecontent ("switching") _tab ("Number switched") _tab ("Percent switched") _tab ("Switched from unexposed") _tab ("Percent switched unexposed") _tab ("Switched from exposed") _tab ("Percent switched exposed") _n 
file write tablecontent ("o_120") _tab %3.1f (r(N)) _tab  
local percent = (r(N)/_N)*100
safecount if switch_o_120_start==1
file write tablecontent (`percent') _tab  %3.1f (r(N)) _tab 
local percent_stt = (r(N)/_N)*100
safecount if switch_o_120_stop==1
file write tablecontent (`percent_stt') _tab  %3.1f (r(N)) _tab 
local percent_stp = (r(N)/_N)*100
file write tablecontent (`percent_stp') _n _n 

file close tablecontent

* New output for release with switching only 
file open tablecontent using ./output/tables/udca_descriptives_switch_only.txt, write text replace

use ./output/time_varying_udca_all_vars_120, clear 
drop last _merge 
merge m:1 patient_id using `tempfile', keepusing(stp has_pbc)
drop if stp==""
tab udca, m
bys patient_id: gen last = _n==_N 
bys patient_id (start): gen udca_bl_check = udca[1]
tab udca_count_bl udca_bl_check  

* Summarise proportion of time on udca 
* First generate time for each row 
*gen time = stop - start 
* Generate total time on & off udca 
* First calculate time for both on and off within one variable 
bys patient_id udca: egen time_udca = total(time)
* From this generate variable with time off udca 
bys patient_id: egen time_off_udca = max(time_udca) if udca==0
bys patient_id (time_off_udca): replace time_off_udca = time_off_udca[_n-1] if time_off_udca==. & time_off_udca[_n-1]!=.
* Update time_udca to only contain time on udca 
replace time_udca=. if udca==0
bys patient_id: egen time_on_udca = max(time_udca)
* Check on and off equals total time of follow-up 
count if time_on_udca + time_off_udca!=total_fu

* Summarising switching
gen udca_bl = (udca_count_bl>=1 & udca_count_bl!=.) 
gen yr_start = year(start)
sum yr_start 
gen switch_120_i = udca!=udca_bl
bys patient_id: egen switch_120 = max(switch_120_i)
bys patient_id: egen switch_120_total = total(switch_120_i)
gen switch_120_start = (switch_120==1 & udca_bl==0)
gen switch_120_stop = (switch_120==1 & udca_bl==1)
gen switch_120_multi = (switch_120_total>1 & switch_120_total!=.)
keep if last==1
tab switch_120  
safecount if switch_120==1
file write tablecontent ("switching") _tab ("Number switched") _tab ("Percent switched") _tab ("Switched from unexposed") _tab ("Percent switched unexposed") _tab ("Switched from exposed") _tab ("Percent switched exposed") _n 
file write tablecontent ("120") _tab %3.1f (round(r(N),5)) _tab  
local percent = (r(N)/_N)*100
safecount if switch_120_start==1
file write tablecontent (`percent') _tab  %3.1f (round(r(N),5)) _tab 
local percent_stt = (r(N)/_N)*100
safecount if switch_120_stop==1
file write tablecontent (`percent_stt') _tab  %3.1f (round(r(N),5)) _tab 
local percent_stp = (r(N)/_N)*100
file write tablecontent (`percent_stp') _n 
* Switching by PBC/PSC status 
*PBC
safecount if switch_120==1 & has_pbc==1
file write tablecontent ("PBC") _tab %3.1f (round(r(N),5)) _tab 
local percent_pbc = (r(N)/_N)*100
safecount if switch_120==1 & has_pbc==1
file write tablecontent (`percent_pbc') _tab  %3.1f (round(r(N),5)) _tab 
local percent_stt_pbc = (r(N)/_N)*100
safecount if switch_120_stop==1 & has_pbc==1
file write tablecontent (`percent_stt_pbc') _tab  %3.1f (round(r(N),5)) _tab 
local percent_stp_pbc = (r(N)/_N)*100
file write tablecontent (`percent_stp_pbc') _n 
*PSC
safecount if switch_120==1 & has_pbc==0
file write tablecontent ("PSC") _tab %3.1f (round(r(N),5)) _tab 
local percent_psc = (r(N)/_N)*100
safecount if switch_120==1 & has_pbc==0
file write tablecontent (`percent_psc') _tab  %3.1f (round(r(N),5)) _tab 
local percent_stt_psc = (r(N)/_N)*100
safecount if switch_120_stop==1 & has_pbc==0
file write tablecontent (`percent_stt_psc') _tab  %3.1f (round(r(N),5)) _tab 
local percent_stp_psc = (r(N)/_N)*100
file write tablecontent (`percent_stp_psc') _n _n
file close tablecontent