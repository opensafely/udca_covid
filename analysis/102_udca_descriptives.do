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

use ./output/time_varying_udca_all_vars_60, clear 
drop last 
bys patient_id: gen last = _n==_N 

* summarise total number of prescriptions during follow-up 
sum total_no_presc if last==1, d 
file write tablecontent _tab ("Number of obervations") _tab ("Mean") _tab ("SD") _tab ("Median") _tab ("25th percentile") _tab ("75th percentile") _n 
file write tablecontent ("Number of prescriptions 60") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n 

* Summarise follow-up 
sum total_fu if last==1, d
file write tablecontent ("Total length of follow-up 60") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n 

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
file write tablecontent ("Total time on UDCA 60") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n 

sum time_off_udca if last==1, d 
file write tablecontent ("Total time off UDCA 60") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n 

bys patient_id: gen rows = _N 
sum rows if last==1, d 
file write tablecontent ("Number of rows 60") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n _n 

* Summarising switching
gen udca_bl = (udca_count_bl>=1 & udca_count_bl!=.) 
gen yr_start = year(start)
sum yr_start 
gen switch_2020_i = udca!=udca_bl & yr_start==2020
bys patient_id: egen switch_2020 = max(switch_2020_i)
bys patient_id: egen switch_2020_total = total(switch_2020_i)
gen switch_2020_start = (switch_2020==1 & udca_bl==0)
gen switch_2020_stop = (switch_2020==1 & udca_bl==1)
gen switch_2020_multi = (switch_2020_total>1 & switch_2020_total!=.)
keep if last==1
tab switch_2020  
safecount if switch_2020==1
file write tablecontent ("switching") _tab ("Number switched") _tab ("Percent switched") _tab ("Switched from unexposed") _tab ("Percent switched unexposed") _tab ("Switched from exposed") _tab ("Percent switched exposed") _n 
file write tablecontent ("2020 60") _tab %3.1f (r(N)) _tab  
local percent = (r(N)/_N)*100
safecount if switch_2020_start==1
file write tablecontent (`percent') _tab  %3.1f (r(N)) _tab 
local percent_stt = (r(N)/_N)*100
safecount if switch_2020_stop==1
file write tablecontent (`percent_stt') _tab  %3.1f (r(N)) _tab 
local percent_stp = (r(N)/_N)*100
file write tablecontent (`percent_stp') _n _n 
file write tablecontent ("Number of rows 60") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n _n 

* Summarising switching
gen udca_bl = (udca_count_bl>=1 & udca_count_bl!=.) 
gen yr_start = year(start)
sum yr_start 
gen switch_2020_i = udca!=udca_bl & yr_start==2020
bys patient_id: egen switch_2020 = max(switch_2020_i)
bys patient_id: egen switch_2020_total = total(switch_2020_i)
gen switch_2020_start = (switch_2020==1 & udca_bl==0)
gen switch_2020_stop = (switch_2020==1 & udca_bl==1)
gen switch_2020_multi = (switch_2020_total>1 & switch_2020_total!=.)
keep if last==1
tab switch_2020  
safecount if switch_2020==1
file write tablecontent ("switching") _tab ("Number switched") _tab ("Percent switched") _tab ("Switched from unexposed") _tab ("Percent switched unexposed") _tab ("Switched from exposed") _tab ("Percent switched exposed") _n 
file write tablecontent ("2020 60") _tab %3.1f (r(N)) _tab  
local percent = (r(N)/_N)*100
safecount if switch_2020_start==1
file write tablecontent (`percent') _tab  %3.1f (r(N)) _tab 
local percent_stt = (r(N)/_N)*100
safecount if switch_2020_stop==1
file write tablecontent (`percent_stt') _tab  %3.1f (r(N)) _tab 
local percent_stp = (r(N)/_N)*100
file write tablecontent (`percent_stp') _n _n 

* For 90 day prescriptions 
use ./output/time_varying_udca_all_vars_90, clear 
drop last 
bys patient_id: gen last = _n==_N 

* summarise total number of prescriptions during follow-up 
sum total_no_presc if last==1, d 
file write tablecontent _tab ("Number of obervations") _tab ("Mean") _tab ("SD") _tab ("Median") _tab ("25th percentile") _tab ("75th percentile") _n 
file write tablecontent ("Number of prescriptions 90") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n 

* Summarise follow-up 
sum total_fu if last==1, d
file write tablecontent ("Total length of follow-up 90") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n 

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
file write tablecontent ("Total time on UDCA 90") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n 

sum time_off_udca if last==1, d 
file write tablecontent ("Total time off UDCA 90") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n 

bys patient_id: gen rows = _N 
sum rows if last==1, d 
file write tablecontent ("Number of rows 90") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _n

* Summarising switching
gen udca_bl = (udca_count_bl>=1 & udca_count_bl!=.) 
gen yr_start = year(start)
sum yr_start 
gen switch_2020_i = udca!=udca_bl & yr_start==2020
bys patient_id: egen switch_2020 = max(switch_2020_i)
bys patient_id: egen switch_2020_total = total(switch_2020_i)
gen switch_2020_start = (switch_2020==1 & udca_bl==0)
gen switch_2020_stop = (switch_2020==1 & udca_bl==1)
gen switch_2020_multi = (switch_2020_total>1 & switch_2020_total!=.)
keep if last==1
tab switch_2020  
safecount if switch_2020==1
file write tablecontent ("switching") _tab ("Number switched") _tab ("Percent switched") _tab ("Switched from unexposed") _tab ("Percent switched unexposed") _tab ("Switched from exposed") _tab ("Percent switched exposed") _n 
file write tablecontent ("2020 90") _tab %3.1f (r(N)) _tab  
local percent = (r(N)/_N)*100
safecount if switch_2020_start==1
file write tablecontent (`percent') _tab  %3.1f (r(N)) _tab 
local percent_stt = (r(N)/_N)*100
safecount if switch_2020_stop==1
file write tablecontent (`percent_stt') _tab  %3.1f (r(N)) _tab 
local percent_stp = (r(N)/_N)*100
file write tablecontent (`percent_stp') _n _n 

file close tablecontent