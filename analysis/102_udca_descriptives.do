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

use ./output/time_varying_udca, clear 
bys patient_id: gen last = _n==_N 

* summarise total number of prescriptions during follow-up 
sum total_no_presc if last==1, d 
file write tablecontent _tab ("Number of obervations") _tab ("Mean") _tab ("SD") _tab ("Median") _tab ("25th percentile") _tab ("75th percentile") _tab ("minimum") _tab ("maximum") _n 
file write tablecontent ("Number of prescriptions") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _tab %3.1f (r(min)) _tab %3.1f (r(max)) _n 

* Summarise follow-up 
sum total_fu if last==1, d
file write tablecontent ("Total length of follow-up") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _tab %3.1f (r(min)) _tab %3.1f (r(max)) _n 

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
file write tablecontent ("Total time on UDCA") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _tab %3.1f (r(min)) _tab %3.1f (r(max)) _n 

sum time_off_udca if last==1, d 
file write tablecontent ("Total time off UDCA") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _tab %3.1f (r(min)) _tab %3.1f (r(max)) _n 

bys patient_id: gen rows = _N 
sum rows if last==1, d 
file write tablecontent ("Number of rows") _tab %3.1f (r(N)) _tab %3.1f (r(mean)) _tab %3.1f (r(sd)) _tab %3.1f (r(p50)) _tab %3.1f (r(p25)) _tab %3.1f (r(p75)) _tab %3.1f (r(min)) _tab %3.1f (r(max)) _n

file close tablecontent