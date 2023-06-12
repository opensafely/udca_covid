/*==============================================================================
DO FILE NAME:			104_propensity_score.do
DATE: 					07/06/2023
AUTHOR:					R Costello 
DESCRIPTION OF FILE:	Generate propensity score  
==============================================================================*/
adopath + ./analysis/ado 
cap mkdir ./output/tempdata
cap mkdir ./output/tables

* Open a log file
cap log using ./logs/propensity_score.log, replace

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

* Sex 
gen male=(sex=="M")
replace male = 0 if sex == "F"
label define male 0"Female" 1"Male"
label values male male
safetab male, miss

* BMI categories
egen bmi_cat = cut(bmi), at(0, 1, 18.5, 24.9, 29.9, 39.9, 100) icodes
bys bmi_cat: sum bmi
* add missing . to zero category
replace bmi_cat = 0 if bmi_cat==. 
label define bmi 0 "Missing" 1 "Underweight" 2 "Healthy range" 3 "Overweight" 4 "Obese" 5 "Morbidly obese"
label values bmi_cat bmi

* Smoking status
gen smoking = 0 if smoking_status=="N"
replace smoking = 1 if smoking_status=="S"
replace smoking = 2 if smoking_status=="E"
replace smoking = 3 if smoking==.

label define smok 1 "Current smoker" 2 "Ex-smoker" 0 "Never smoked" 3 "Unknown"
label values smoking smok


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

* Determine study end date 
foreach date in dereg_date died_date_ons hosp_covid {
    gen `date'A = date(`date', "YMD")
    format %dD/N/CY `date'A
    drop `date'
}
gen end_study = date("31/12/2020", "DMY")

* End date if died 
egen end_date_died = rowmin(dereg_dateA end_study died_date_onsA)
* End date for hospital admission outcome 
egen end_date_hosp = rowmin(dereg_dateA end_study died_date_onsA hosp_covidA)
* Flag died 2020 - will match end date 
gen died_covid_2020 = (died_date_onsA<=date("31Dec2020", "DMY") & died_ons_covid_flag_any==1)

* Flag hospital admission 
gen hosp_flag = hosp_covidA!=.
gen hosp_covid_2020 = hosp_covidA<date("31Dec2020", "DMY") & hosp_flag==1 

* generate index date 
gen indexdate = date("01/03/2020", "DMY")

* Model treatment allocation on the set of confounding variables (include age and bmi as continuous variables)
* First DAG minimal adjustment set: age, sex, COVID-19 high risk conditions, ethnicity & IMD
logistic udca_bl (age male any_high_risk_condition i.ethnicity i.imd)

* Estimate propensity scores
predict propensity_dag

* Calculate ATT weights 
gen att_weight_dag = udca_bl + (1-udca_bl)*(propensity_dag/(1-propensity_dag))

* Next adjust for additional variables 
logistic udca_bl (age male any_high_risk_condition i.ethnicity i.imd bmi i.smoking severe_disease_bl oca_bl budesonide_bl)

* Estimate propensity scores
predict propensity_all

* Calculate ATT weights 
gen att_weight_all = udca_bl + (1-udca_bl)*(propensity_all/(1-propensity_all))

* Fit weighted Cox regression w/ robust standard errors
* COVID-19 death outcome and hospitalisation outcomes 
foreach outcome in died hosp { 
    file open tablecontent using ./output/tables/covid_`outcome'_cox_models.txt, write text replace
    file write tablecontent ("UDCA exposure") _tab ("denominator") _tab ("events") _tab ("total_person_wks") _tab ("Rate") _tab ("unadj_hr") _tab ///
    ("unadj_ci") _tab ("unadj_lci") _tab ("unadj_uci") _tab ("dag_adj_hr") _tab ("dag_adj_ci") _tab ("dag_adj_lci") _tab ("dag_adj_uci") _tab ("f_adj_hr") _tab ("f_adj_ci") _tab ("f_adj_lci") _tab ("f_adj_uci") _tab  _n
    stset end_date_`outcome', failure(`outcome'_covid_2020) origin(indexdate) enter(indexdate) scale(365.25) id(patient_id)
    stcox i.udca_bl, strata(stp) 
    estimates save "./output/tempdata/crude_`outcome'", replace 
    eststo model0
    parmest, label eform format(estimate p lb ub) saving("./output/tempdata/surv_crude_`outcome'", replace) idstr("crude_`outcome'") 
    estat phtest, d
    * DAG minimal adjustment set 
    stset end_date_`outcome' [pweight=att_weight_dag], failure(`outcome'_covid_2020) origin(indexdate) enter(indexdate) scale(365.25) id(patient_id)
    stcox i.udca_bl, strata(stp) vce(robust)
    estimates save "./output/tempdata/adj_dag_`outcome'", replace 
    eststo model1
    parmest, label eform format(estimate p lb ub) saving("./output/tempdata/surv_dag_adj_`outcome'", replace) idstr("adj_dag_`outcome'") 
    estat phtest, d
    * All adjustments 
    stset end_date_`outcome' [pweight=att_weight_all], failure(`outcome'_covid_2020) origin(indexdate) enter(indexdate) scale(365.25) id(patient_id)
    stcox i.udca_bl, strata(stp) vce(robust)
    estimates save "./output/tempdata/adj_all_`outcome'", replace 
    eststo model2
    parmest, label eform format(estimate p lb ub) saving("./output/tempdata/surv_adj_all_`outcome'", replace) idstr("adj_all_`outcome'") 
    estat phtest, d
    eststo clear
    bysort udca_bl: egen total_follow_up_`outcome' = total(_t)
    * Writing results to file 
    forvalues i=0/1 {
        qui safecount if udca_bl==`i'
        local denominator = r(N)
        qui safecount if udca_bl == `i'  & `outcome'_covid_2020 == 1
        local event = r(N)
        qui su total_follow_up_`outcome' if udca_bl == `i'
        local person_mth = r(mean)/30
        local rate = 100000*(`event'/`person_mth')
        if `event'>10 & `event'!=. {
                        file write tablecontent ("UDCA `i'") _tab (`denominator') _tab (`event') _tab %10.0f (`person_mth') _tab %3.2f (`rate') _tab  
                        cap estimates use "./output/tempdata/crude_`outcome'" 
                        cap lincom `i'.udca_bl, eform
                        file write tablecontent  %4.2f (r(estimate)) _tab ("(") %4.2f (r(lb)) (" - ") %4.2f (r(ub)) (")") _tab %4.2f (r(lb)) _tab %4.2f (r(ub)) _tab
                        cap estimates clear
                        cap estimates use "./output/tempdata/adj_dag_`outcome'" 
                        cap lincom `i'.udca_bl, eform
                        file write tablecontent  %4.2f (r(estimate)) _tab ("(") %4.2f (r(lb)) (" - ") %4.2f (r(ub)) (")") _tab %4.2f (r(lb)) _tab %4.2f (r(ub))  _tab
                        cap estimates clear
                        cap estimates use "./output/tempdata/adj_all_`outcome'" 
                        cap lincom `i'.udca_bl, eform
                        file write tablecontent  %4.2f (r(estimate)) _tab ("(") %4.2f (r(lb)) (" - ") %4.2f (r(ub)) (")") _tab %4.2f (r(lb)) _tab %4.2f (r(ub)) _n
                        cap estimates clear
                    }
                    else {
                        file write tablecontent ("UDCA `i'") _tab ("redact") _n
                        continue
                    }
        }
        file close tablecontent 
    }



