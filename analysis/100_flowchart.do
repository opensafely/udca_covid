/*==============================================================================
DO FILE NAME:			100_flowchart.do.do
DATE: 					14/07/2023
AUTHOR:					Ruth Costello 
DESCRIPTION OF FILE:	Produces numbers for flowchart 
==============================================================================*/
adopath + ./analysis/ado 
cap mkdir ./output/flowchart

cap log using ./logs/flowchart.log, replace

import delimited using ./output/input_flowchart.csv, clear
 *  has_follow_up 
 * (NOT died) AND
 * (age >=18 AND age <= 115) AND
 * (sex = 'M' OR sex = 'F') AND
 * (imd != 0) AND
 * (has_pbc=1 OR has_psc=1) AND
 * (NOT liver_transplant_bl)

* Open file to write values to 
file open table using ./output/flowchart/values.txt, write text replace  
file write table ("Total start") _tab 

describe

safecount
file write table ("`r(N)'") _n ("Has follow-up") _tab 
safetab has_follow_up, m
keep if has_follow_up
safecount
file write table ("`r(N)'") _n ("Died") _tab 
safetab died, m
keep if died!=1
safecount
file write table ("`r(N)'") _n ("Age ineligible") _tab  
sum age
keep if (age>=18 & age<=115)
safecount
file write table ("`r(N)'") _n ("Missing/ineligible sex") _tab 
safetab sex, m
keep if (sex=="F" | sex=="M")
safecount 
file write table ("`r(N)'") _n ("IMD missing") _tab 
safetab imd 
drop if imd==0
safecount
file write table ("`r(N)'") _n ("No PBC or PSC") _tab 
gen pbc_psc = (has_pbc==1 | has_psc==1)
safetab pbc_psc, m
keep if pbc_psc
safecount
file write table ("`r(N)'") _n ("Liver transplant prior to index") _tab
safetab liver_transplant_bl, m
drop if liver_transplant_bl
safecount
file write table ("`r(N)'") _N

/* Determine number censored
import delimited using ./output/input_pbc.csv, clear
* Determine end of follow-up date
gen dereg_dateA = date(dereg_date, "YMD")
format %dD/N/CY dereg_dateA
drop dereg_date
gen died_dateA = date(died_date_ons, "YMD")
format %dD/N/CY died_dateA
drop died_date_ons
gen end_study = date("31/12/2022", "DMY")
egen end_date = rowmin(dereg_dateA end_study died_dateA)

gen censored = end_date!=end_study 

file write table ("Censoring information") _tab ("No UDCA BL") _tab ("UDCA BL") _N 
safecount if censored==1 & udca_bl==0
file write table ("Censored") _tab ("`r(N)'") 




file close table 