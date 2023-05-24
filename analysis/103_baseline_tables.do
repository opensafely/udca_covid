/*==============================================================================
DO FILE NAME:			103_baseline_tables.do
DATE: 					24/05/2023
AUTHOR:					R Costello 
DESCRIPTION OF FILE:	Produce baseline table for cohort  
==============================================================================*/
adopath + ./analysis/ado 
cap mkdir ./output/tables

* Open a log file
cap log using ./logs/baseline_tables.log, replace

import delimited using ./output/input_pbc.csv, clear

* Prepare variables for table 
replace ethnicity=6 if ethnicity==0
label define eth5 			1 "White"  					///
                            2 "Mixed"				///						
                            3 "Asian"  					///
                            4 "Black"					///
                            5 "Other"					///
                            6 "Unknown"
                    

label values ethnicity eth5
safetab ethnicity, m
*(2) IMD
replace imd=6 if imd==0

* Create age categories
egen age_cat = cut(age), at(18, 40, 60, 80, 120) icodes
label define age 0 "18 - 40 years" 1 "41 - 60 years" 2 "61 - 80 years" 3 ">80 years"
label values age_cat age
bys age_cat: sum age

* BMI categories
egen bmi_cat = cut(bmi), at(0, 1, 18.5, 24.9, 29.9, 39.9, 100) icodes
bys bmi_cat: sum bmi
* add missing . to zero category
replace bmi_cat = 0 if bmi_cat==. 
label define bmi 0 "Missing" 1 "Underweight" 2 "Healthy range" 3 "Overweight" 4 "Obese" 5 "Morbidly obese"
label values bmi_cat bmi

foreach var in gc budesonide fenofibrate {
    gen `var'_any = ()`var'_count>=1 & `var'_count!=.)
}
gen udca_any = (udca_count_fu>=1 & udca_count_fu!=.)

* Create tables 
* Characteristics whole cohort
preserve
table1_mc, vars(age_cat cat \ sex cat \ imd cat \ ethnicity cat \ severe_disease_bl cat \ smoking_status cat \ bmi_cat cat \ has_pbc bin) clear
export delimited using ./output/tables/baseline_table.csv, replace
* Rounding numbers in table to nearest 5
destring _columna_1, gen(n) force
destring _columnb_1, gen(percent) ignore("-" "%" "(" ")")  force
gen rounded_n = round(n, 5)
keep factor level rounded_n percent
export delimited using ./output/tables/baseline_table_rounded.csv
restore 

* Characteristics by any exposure
preserve 
table1_mc, vars(age_cat cat \ sex cat \ imd cat \ ethnicity cat \ severe_disease_bl cat \ smoking_status cat \ bmi_cat cat \ has_pbc bin) by(udca_any) clear
export delimited using ./output/tables/baseline_table_udca.csv, replace
* Rounding numbers in table to nearest 5
destring _columna_1, gen(n1) force
destring _columna_0, gen(n0) force
destring _columnb_1, gen(percent1) ignore("-" "%" "(" ")")  force
destring _columnb_0, gen(percent0) ignore("-" "%" "(" ")")  force
gen rounded_n1 = round(n1, 5)
gen rounded_n0 = round(n0, 5)
keep factor level rounded_n0 percent0 rounded_n1 percent1
export delimited using ./output/tables/baseline_table_udca_rounded.csv
restore 

* Additional medications by any exposure
preserve 
table1_mc, vars(budesonide_any bin \ fenofibrate_any bin \ gc_any bin \ oca_bl bin \ rituximab_bl bin) by(udca_any) clear
export delimited using ./output/tables/additional_meds_udca.csv, replace
* Rounding numbers in table to nearest 5
destring _columna_1, gen(n1) force
destring _columna_0, gen(n0) force
destring _columnb_1, gen(percent1) ignore("-" "%" "(" ")")  force
destring _columnb_0, gen(percent0) ignore("-" "%" "(" ")")  force
gen rounded_n1 = round(n1, 5)
gen rounded_n0 = round(n0, 5)
keep factor level rounded_n0 percent0 rounded_n1 percent1
export delimited using ./output/tables/additional_meds_udca_rounded.csv
restore 



