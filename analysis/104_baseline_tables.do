/*==============================================================================
DO FILE NAME:			104_baseline_tables.do
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

replace oral_steroid_drugs_nhsd=. if oral_steroid_drug_nhsd_3m_count < 2 & oral_steroid_drug_nhsd_12m_count < 4
gen imid_nhsd=max(oral_steroid_drugs_nhsd, immunosuppresant_drugs_nhsd)
gen rare_neuro_nhsd = max(multiple_sclerosis_nhsd, motor_neurone_disease_nhsd, myasthenia_gravis_nhsd, huntingtons_disease_nhsd)
gen solid_organ_transplant_bin = solid_organ_transplant_nhsd_new!=""
gen any_high_risk_condition = max(learning_disability_nhsd_snomed, cancer_opensafely_snomed_new, haematological_disease_nhsd, ///
ckd_stage_5_nhsd, imid_nhsd, immunosupression_nhsd_new, hiv_aids_nhsd, solid_organ_transplant_bin, rare_neuro_nhsd)

foreach var in udca gc budesonide fenofibrate {
    gen `var'_any = (`var'_count_fu>=1 & `var'_count_fu!=.)
    gen `var'_bl = (`var'_count_bl>=1 & `var'_count_bl!=.)
}

* Generate variable with number of vaccinations 
foreach var in covid_vacc_first covid_vacc_second covid_vacc_third covid_vacc_fourth covid_vacc_fifth {
    gen `var'= (`var'_date!="")    
}

egen vacc_any = rowmax(covid_vacc_first covid_vacc_second covid_vacc_third covid_vacc_fourth covid_vacc_fifth)
egen total_vaccs = rowtotal(covid_vacc_first covid_vacc_second covid_vacc_third covid_vacc_fourth covid_vacc_fifth)
tab total_vaccs 

gen severe_disease_fu = severe_disease_fu_date!=""



* Create tables 
* Characteristics whole cohort
preserve
table1_mc, vars(age_cat cat \ sex cat \ imd cat \ ethnicity cat \ severe_disease_bl cat \ smoking_status cat \ bmi_cat cat \ has_pbc bin \ ///
any_high_risk_condition cat) clear
export delimited using ./output/tables/baseline_table.csv, replace
* Rounding numbers in table to nearest 5
destring _columna_1, gen(n) ignore(",") force
destring _columnb_1, gen(percent) ignore("-" "%" "(" ")")  force
gen rounded_n = round(n, 5)
tostring rounded_n, gen(n_rounded)
replace n_rounded = "redacted" if (rounded_n<=5)
keep factor level n_rounded percent
export delimited using ./output/tables/baseline_table_rounded.csv
restore 

* High risk conditions
preserve
table1_mc, vars(learning_disability_nhsd_snomed cat \ cancer_opensafely_snomed_new cat \ haematological_disease_nhsd cat \ ///
ckd_stage_5_nhsd cat \ imid_nhsd cat \ immunosupression_nhsd_new cat \ hiv_aids_nhsd cat \ solid_organ_transplant_bin cat \  ///
rare_neuro_nhsd cat) clear
export delimited using ./output/tables/high_risk.csv, replace
* Rounding numbers in table to nearest 5
destring _columna_1, gen(n) ignore(",") force
destring _columnb_1, gen(percent) ignore("-" "%" "(" ")")  force
gen rounded_n = round(n, 5)
tostring rounded_n, gen(n_rounded)
replace n_rounded = "redacted" if (rounded_n<=5)
keep factor level n_rounded percent
export delimited using ./output/tables/high_risk_rounded.csv
restore 



* Characteristics by exposure status at baseline 
preserve 
table1_mc, vars(age_cat cat \ sex cat \ imd cat \ ethnicity cat \ severe_disease_bl cat \ smoking_status cat \ bmi_cat cat \ has_pbc bin) by(udca_bl) clear
export delimited using ./output/tables/baseline_table_udca.csv, replace
* Rounding numbers in table to nearest 5
forvalues i=0/1 {   
    destring _columna_`i', gen(n`i') ignore(",") force
    destring _columnb_`i', gen(percent`i') ignore("-" "%" "(" ")")  force
    gen rounded_n`i' = round(n`i', 5)
    tostring rounded_n`i', gen(n`i'_rounded)
    replace n`i'_rounded = "redacted" if (rounded_n`i'<=5)
}
keep factor level n0_rounded percent0 n1_rounded percent1
export delimited using ./output/tables/baseline_table_udca_rounded.csv
restore 

* Additional medications by any exposure
preserve 
table1_mc, vars(budesonide_bl bin \ fenofibrate_bl bin \ gc_bl bin \ oca_bl bin \ rituximab_bl bin \ severe_disease_fu bin \ vacc_any bin  \ total_vaccs cat) by(udca_bl) clear
export delimited using ./output/tables/additional_meds_udca.csv, replace
* Rounding numbers in table to nearest 5
forvalues i=0/1 {   
    destring _columna_`i', gen(n`i') ignore(",") force
    destring _columnb_`i', gen(percent`i') ignore("-" "%" "(" ")")  force
    gen rounded_n`i' = round(n`i', 5)
    tostring rounded_n`i', gen(n`i'_rounded)
    tostring percent`i', gen(percent_`i')
    replace n`i'_rounded = "redacted" if (rounded_n`i'<=5)
    replace percent_`i' = "redacted" if (rounded_n`i'<=5)
}
keep factor n0_rounded percent_0 n1_rounded percent_1
export delimited using ./output/tables/additional_meds_udca_rounded.csv
restore 

* Checking outcomes 
foreach var in died_date_ons hosp_covid_primary hosp_covid_any {
    gen `var'A = date(`var', "YMD")
    format `var'A %dD/N/CY
    drop `var'
}
* Flag if died
gen died_flag = died_date_onsA!=.
* Generate date if died of covid
gen died_date_onscovid = died_date_onsA if died_ons_covid_flag_any == 1

* Flag hospitalised with covid 
gen hosp_any_flag = hosp_covid_anyA!=.

* Composite outcome 
gen hosp_died = (died_ons_covid_flag_any==1 | hosp_any_flag==1)
egen hosp_died_dateA = rowmin(died_date_onsA hosp_covid_anyA)


tab udca_bl died_ons_covid_flag_any
tab udca_bl hosp_any_flag

table1_mc, by(udca_bl) vars(died_ons_covid_flag_any bin \ hosp_any_flag bin \ hosp_died bin) clear
export delimited using ./output/tables/baseline_outcomes.csv
forvalues i=0/1 {   
    destring _columna_`i', gen(n`i') ignore(",") force
    destring _columnb_`i', gen(percent`i') ignore("-" "%" "(" ")")  force
    gen rounded_n`i' = round(n`i', 5)
    tostring rounded_n`i', gen(n`i'_rounded)
    tostring percent`i', gen(percent_`i')
    replace n`i'_rounded = "redacted" if (rounded_n`i'<=5)
    replace percent_`i' = "redacted" if (rounded_n`i'<=5)
}
keep factor rounded_n0 percent0 rounded_n1 percent1
export delimited using ./output/tables/baseline_outcomes_rounded.csv
