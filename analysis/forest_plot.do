/*==============================================================================
DO FILE NAME:			forest_plot.do
DATE: 					14/07/2023
AUTHOR:					Ruth Costello 
DESCRIPTION OF FILE:	Produces forest plot from file created in 106_analysis_models.do
==============================================================================*/

* Run outside of OpenSAFELY environment as uses released data

import delimited "output/20231120/cox_models.txt", varnames(1) clear

* Name analysis variable
gen analysis = outcome if exposurestatus==""
* Flag first record of analysis 
gen flag_analyses=1 if analysis!=""
replace flag_analyses=1 if _n==1
* Spread so count variable for each analysis 
gen count_analyses = sum(flag_analyses)
replace analysis=analysis[_n-1] if analysis==""
* Update name of analysis for main as not listed
replace analysis="Main analysis" if count_analyses==1
* Drop rows not required (title rows)
drop if outcome==analysis | outcome=="Outcome"
* destring numbers 
destring unadj_hr - f_adj_uci, replace
* drop rows where reference 
drop if unadj_hr==1 
gen outcome_n = 1 if outcome=="composite_any"
replace outcome_n = 2 if outcome=="hosp_any"
replace outcome_n = 3 if outcome=="died_covid_any"

label define out 1 "Composite" 2 "Hospitalisation alone" 3 "Death alone"
label values outcome_n out
label var outcome_n "Outcome"
label var analysis "Analysis"

sort count_analyses outcome_n 

* log estimates 
gen f_adj_hr_log = log(f_adj_hr)
gen f_adj_lci_log = log(f_adj_lci)
gen f_adj_uci_log = log(f_adj_uci)

* Capitalisation
replace analysis = "Vaccinations sensitivity analysis" if count_analyses==7

metan f_adj_hr_log f_adj_lci_log f_adj_uci_log, eform  ///
	effect(Hazard Ratio) notable forestplot(null(1) dp(2) xlab(.25 .5 1 2 3, force) favours("Favours UDCA        "   #   "        Favours no UDCA", nosymmetric) xtitle(, size(tiny)) graphregion(margin(zero) color(white)) texts(100) astext(65)) by(analysis) nowt nosubgroup nooverall nobox scheme(sj) label(namevar=outcome_n)  

graph export "output/forest_plot.svg", replace



