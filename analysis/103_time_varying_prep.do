/*==============================================================================
DO FILE NAME:			103_time_varying_prep.do
DATE: 					26/06/2023
AUTHOR:					R Costello 
DESCRIPTION OF FILE:	Create time-varying covariates
==============================================================================*/
adopath + ./analysis/ado 

* Open a log file
cap log using ./logs/time_varying.log, replace

tempfile tempfile
import delimited using ./output/time_varying_udca_120, clear
save `tempfile'

import delimited using ./output/input_pbc.csv, clear

* Need to identify time-varying variables:
*   vaccination, disease severity, liver transplant 

keep patient_id severe_disease_fu_date severe_disease_bl covid_vacc_date liver_transplant_fu

merge 1:m patient_id using `tempfile'

* create variables of every 6 months 
gen six_mths_1 = date("01/09/2020", "DMY")
gen six_mths_2 = date("01/03/2021", "DMY")
gen six_mths_3 = date("01/09/2021", "DMY")
gen six_mths_4 = date("01/03/2022", "DMY")
gen six_mths_5 = date("01/09/2022", "DMY")

