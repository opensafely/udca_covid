/*==============================================================================
DO FILE NAME:			105_analysis.do.do
DATE: 					07/07/2023
AUTHOR:					Ruth Costello (adapted from Christopher Rentsch)
DESCRIPTION OF FILE:	Produce cumulative incidence plots
==============================================================================*/
adopath + ./analysis/ado 
cap mkdir ./output/graphs
cap mkdir ./output/tables

* Open a log file
cap log using ./logs/analysis.log, replace
* Open file to write results to 
file open tablecontent using ./output/tables/cum_incidence.txt, write text replace
file write tablecontent ("Outcome") _tab ("Exposure") _tab ("Cumulative incidence") _tab ("95% confidence interval") _n


/* plot for each outcome - age and sex adjusted only
foreach outcome in hosp_any composite_any {
    use ./output/an_dataset_`outcome', clear 
    drop if stp==""
    describe
    gen index_date = date("01/03/2020", "DMY")
    bys patient_id (start): gen last = _N==_n 
    tab died_liver_any `outcome'_flag if last==1
    * For sensitivity: generate new stop and update last record to end of study period if died of liver disease 
    gen stop_new = stop 
    replace stop_new = date("31/12/2022", "DMY") if last==1 & died_liver_any==1
    stset stop, fail(`outcome'_flag) id(patient_id) enter(index_date) origin(index_date)

    * Add cumulative incidence plots 
    * Not stratifying by stp as cannot use tvc and stratify  
    
    * Age and sex adjusted model 
    * Setting df (degrees of freedom for restricted cubic splines) as 3 as this is default 
    * Setting dftvc (degrees of freedom for time-dependent effects) as 1 = linear effect of log time 
    stpm2 udca age_tv male, tvc(udca) dftvc(1) df(2) scale(hazard) eform
    summ _t
    local tmax=r(max)
    local tmaxplus1=r(max)+1

    range days 0 `tmax' `tmaxplus1'
    stpm2_standsurv if udca == 1, at1(udca 0) at2(udca 1) timevar(days) ci contrast(difference) fail

    gen date = d(1/3/2020)+ days
    format date %tddd_Month

    for var _at1 _at2 _at1_lci _at1_uci _at2_lci _at2_uci _contrast2_1 _contrast2_1_lci _contrast2_1_uci: replace X=100*X

    *cumulative mortality at last day of follow-up - write to file 
    file write tablecontent ("`outcome'") _tab ("No UDCA") _tab  
    * cumulative outcome - no UDCA 
    sum _at1 if days==`tmax'
    file write tablecontent (r(mean)) _tab 
    sum _at1_lci if days==`tmax'
    file write tablecontent (r(mean)) _tab 
    sum _at1_uci if days==`tmax'
    file write tablecontent (r(mean)) _tab _n 
    * cumulative outcome - UDCA 
    file write tablecontent ("`outcome'") _tab ("UDCA") _tab  
    sum _at2 if days==`tmax'
    file write tablecontent (r(mean)) _tab 
    sum _at2_lci if days==`tmax'
    file write tablecontent (r(mean)) _tab 
    sum _at2_uci if days==`tmax'
    file write tablecontent (r(mean)) _tab _n 
    
    *l date days _at1 _at1_lci _at1_uci _at2 _at2_lci _at2_uci if days<.

    twoway  (rarea _at1_lci _at1_uci days, color(red%25)) ///
                    (rarea _at2_lci _at2_uci days, color(blue%25)) ///
                    (line _at1 days, sort lcolor(red)) ///
                    (line _at2 days, sort lcolor(blue) lpattern(dash)) ///
                    , legend(order(1 "No UDCA" 2 "UDCA") ring(0) cols(1) pos(11) region(lwidth(none))) ///
                    title("Time to `outcome'", justification(left) size(med) )  	   ///
                    yscale(range(0, 1)) 											///
                    ylabel(0 (1) 10, angle(0) format(%4.1f) labsize(small))	///
                    xlabel(0 (200) 1035, labsize(small))				   				///			
                    ytitle("Cumulative outcomes (%)", size(medsmall)) ///
                    xtitle("Days since 1 Mar 2020", size(medsmall))      		///
                    graphregion(fcolor(white)) saving(adjcurv_`outcome', replace)

    graph export "./output/graphs/adjcurv_`outcome'.svg", as(svg) replace

    * Close window 
    graph close

    * Post-hoc analysis: Model with liver deaths not censored
    use ./output/an_dataset_`outcome', clear 
    drop if stp==""
    describe
    gen index_date = date("01/03/2020", "DMY")
    bys patient_id (start): gen last = _N==_n 
    tab died_liver_any `outcome'_flag if last==1
    * For sensitivity: generate new stop and update last record to end of study period if died of liver disease 
    gen stop_new = stop 
    replace stop_new = date("31/12/2022", "DMY") if last==1 & died_liver_any==1
    stset stop_new, fail(`outcome'_flag) id(patient_id) enter(index_date) origin(index_date)

    * Add cumulative incidence plots 
    * Not stratifying by stp as cannot use tvc and stratify  
    
    * Age and sex adjusted model 
    * Setting df (degrees of freedom for restricted cubic splines) as 3 as this is default 
    * Setting dftvc (degrees of freedom for time-dependent effects) as 1 = linear effect of log time 
    stpm2 udca age_tv male, tvc(udca) dftvc(1) df(2) scale(hazard) eform
    summ _t
    local tmax=r(max)
    local tmaxplus1=r(max)+1

    range days_ph 0 `tmax' `tmaxplus1'
    stpm2_standsurv if udca == 1, at1(udca 0) at2(udca 1) timevar(days_ph) ci contrast(difference) fail

    gen date = d(1/3/2020)+ days_ph
    format date %tddd_Month

    for var _at1 _at2 _at1_lci _at1_uci _at2_lci _at2_uci _contrast2_1 _contrast2_1_lci _contrast2_1_uci: replace X=100*X

    *cumulative mortality at last day of follow-up - write to file 
    file write tablecontent ("Post-hoc: `outcome'") _tab ("No UDCA") _tab  
    * cumulative outcome - no UDCA 
    sum _at1 if days_ph==`tmax'
    file write tablecontent (r(mean)) _tab 
    sum _at1_lci if days_ph==`tmax'
    file write tablecontent (r(mean)) _tab 
    sum _at1_uci if days_ph==`tmax'
    file write tablecontent (r(mean)) _tab _n 
    * cumulative outcome - UDCA 
    file write tablecontent ("`outcome'") _tab ("UDCA") _tab  
    sum _at2 if days_ph==`tmax'
    file write tablecontent (r(mean)) _tab 
    sum _at2_lci if days_ph==`tmax'
    file write tablecontent (r(mean)) _tab 
    sum _at2_uci if days_ph==`tmax'
    file write tablecontent (r(mean)) _tab _n 
    
    *l date days_ph _at1 _at1_lci _at1_uci _at2 _at2_lci _at2_uci if days_ph<.

    twoway  (rarea _at1_lci _at1_uci days_ph, color(red%25)) ///
                    (rarea _at2_lci _at2_uci days_ph, color(blue%25)) ///
                    (line _at1 days_ph, sort lcolor(red)) ///
                    (line _at2 days_ph, sort lcolor(blue) lpattern(dash)) ///
                    , legend(order(1 "No UDCA" 2 "UDCA") ring(0) cols(1) pos(11) region(lwidth(none))) ///
                    title("Time to `outcome'", justification(left) size(med) )  	   ///
                    yscale(range(0, 1)) 											///
                    ylabel(0 (1) 10, angle(0) format(%4.1f) labsize(small))	///
                    xlabel(0 (200) 1035, labsize(small))				   				///			
                    ytitle("Cumulative outcomes (%)", size(medsmall)) ///
                    xtitle("days since 1 Mar 2020", size(medsmall))      		///
                    graphregion(fcolor(white)) saving(adjcurv_`outcome', replace)

    graph export "./output/graphs/adjcurv_`outcome'_post_hoc.svg", as(svg) replace

    * Close window 
    graph close
}

use ./output/an_dataset_died_covid_any, clear 
drop if stp==""
describe
gen index_date = date("01/03/2020", "DMY")
bys patient_id (start): gen last = _N==_n 
tab died_liver_any died_covid_any_flag if last==1
* For sensitivity: generate new stop and update last record to end of study period if died of liver disease 
gen stop_new = stop 
replace stop_new = date("31/12/2022", "DMY") if last==1 & died_liver_any==1
stset stop, fail(died_covid_any_flag) id(patient_id) enter(index_date) origin(index_date)

* Add cumulative incidence plots 
* Not stratifying by stp as cannot use tvc and stratify 

* Age and sex adjusted model 
* Setting df (degrees of freedom for restricted cubic splines) as 3 as this is default 
* Setting dftvc (degrees of freedom for time-dependent effects) as 1 = linear effect of log time 
stpm2 udca age_tv male, tvc(udca age_tv) dftvc(1) df(2) scale(hazard) eform
summ _t
local tmax=r(max)
local tmaxplus1=r(max)+1

range days 0 `tmax' `tmaxplus1'
stpm2_standsurv if udca == 1, at1(udca 0) at2(udca 1) timevar(days) ci contrast(difference) fail

gen date = d(1/3/2020)+ days
format date %tddd_Month

for var _at1 _at2 _at1_lci _at1_uci _at2_lci _at2_uci _contrast2_1 _contrast2_1_lci _contrast2_1_uci: replace X=100*X

*cumulative mortality at last day of follow-up - write to file 
file write tablecontent ("Death") _tab ("No UDCA") _tab  
* cumulative outcome - no UDCA 
sum _at1 if days==`tmax'
file write tablecontent (r(mean)) _tab 
sum _at1_lci if days==`tmax'
file write tablecontent (r(mean)) _tab 
sum _at1_uci if days==`tmax'
file write tablecontent (r(mean)) _tab _n 
* cumulative outcome - UDCA 
file write tablecontent ("Death") _tab ("UDCA") _tab  
sum _at2 if days==`tmax'
file write tablecontent (r(mean)) _tab 
sum _at2_lci if days==`tmax'
file write tablecontent (r(mean)) _tab 
sum _at2_uci if days==`tmax'
file write tablecontent (r(mean)) _tab _n 

*l date days _at1 _at1_lci _at1_uci _at2 _at2_lci _at2_uci if days<.

twoway  (rarea _at1_lci _at1_uci days, color(red%25)) ///
                (rarea _at2_lci _at2_uci days, color(blue%25)) ///
                (line _at1 days, sort lcolor(red)) ///
                (line _at2 days, sort lcolor(blue) lpattern(dash)) ///
                , legend(order(1 "No UDCA" 2 "UDCA") ring(0) cols(1) pos(11) region(lwidth(none))) ///
                title("Time to COVID-19 death", justification(left) size(med) )  	   ///
                yscale(range(0, 1)) 											///
                ylabel(0 (1) 10, angle(0) format(%4.1f) labsize(small))	///
                xlabel(0 (200) 1035, labsize(small))				   				///			
                ytitle("Cumulative mortality (%)", size(medsmall)) ///
                xtitle("Days since 1 Mar 2020", size(medsmall))      		///
                graphregion(fcolor(white)) saving(adjcurv_`outcome', replace)

graph export "./output/graphs/adjcurv_died_covid_any.svg", as(svg) replace

* Close window 
graph close

* Post-hoc analysis: Model with liver deaths not censored
use ./output/an_dataset_died_covid_any, clear 
drop if stp==""
describe
gen index_date = date("01/03/2020", "DMY")
bys patient_id (start): gen last = _N==_n 
tab died_liver_any died_covid_any_flag if last==1
* For sensitivity: generate new stop and update last record to end of study period if died of liver disease 
gen stop_new = stop 
replace stop_new = date("31/12/2022", "DMY") if last==1 & died_liver_any==1
stset stop_new, fail(died_covid_any_flag) id(patient_id) enter(index_date) origin(index_date)

* Add cumulative incidence plots 
* Not stratifying by stp as cannot use tvc and stratify  

* Age and sex adjusted model 
* Setting df (degrees of freedom for restricted cubic splines) as 3 as this is default 
* Setting dftvc (degrees of freedom for time-dependent effects) as 1 = linear effect of log time 
stpm2 udca age_tv male, tvc(udca) dftvc(1) df(2) scale(hazard) eform
summ _t
local tmax=r(max)
local tmaxplus1=r(max)+1

range days_ph 0 `tmax' `tmaxplus1'
stpm2_standsurv if udca == 1, at1(udca 0) at2(udca 1) timevar(days_ph) ci contrast(difference) fail

gen date = d(1/3/2020)+ days_ph
format date %tddd_Month

for var _at1 _at2 _at1_lci _at1_uci _at2_lci _at2_uci _contrast2_1 _contrast2_1_lci _contrast2_1_uci: replace X=100*X

*cumulative mortality at last day of follow-up - write to file 
file write tablecontent ("Post-hoc: died_covid_any") _tab ("No UDCA") _tab  
* cumulative outcome - no UDCA 
sum _at1 if days_ph==`tmax'
file write tablecontent (r(mean)) _tab 
sum _at1_lci if days_ph==`tmax'
file write tablecontent (r(mean)) _tab 
sum _at1_uci if days_ph==`tmax'
file write tablecontent (r(mean)) _tab _n 
* cumulative outcome - UDCA 
file write tablecontent ("`outcome'") _tab ("UDCA") _tab  
sum _at2 if days_ph==`tmax'
file write tablecontent (r(mean)) _tab 
sum _at2_lci if days_ph==`tmax'
file write tablecontent (r(mean)) _tab 
sum _at2_uci if days_ph==`tmax'
file write tablecontent (r(mean)) _tab _n 

*l date days_ph _at1 _at1_lci _at1_uci _at2 _at2_lci _at2_uci if days_ph<.

twoway  (rarea _at1_lci _at1_uci days_ph, color(red%25)) ///
                (rarea _at2_lci _at2_uci days_ph, color(blue%25)) ///
                (line _at1 days_ph, sort lcolor(red)) ///
                (line _at2 days_ph, sort lcolor(blue) lpattern(dash)) ///
                , legend(order(1 "No UDCA" 2 "UDCA") ring(0) cols(1) pos(11) region(lwidth(none))) ///
                title("Time to `outcome'", justification(left) size(med) )  	   ///
                yscale(range(0, 1)) 											///
                ylabel(0 (1) 10, angle(0) format(%4.1f) labsize(small))	///
                xlabel(0 (200) 1035, labsize(small))				   				///			
                ytitle("Cumulative outcomes (%)", size(medsmall)) ///
                xtitle("Days since 1 Mar 2020", size(medsmall))      		///
                graphregion(fcolor(white)) saving(adjcurv_died_covid_any_post_hoc, replace)

graph export "./output/graphs/adjcurv_died_covid_any_post_hoc.svg", as(svg) replace

* Close window 
graph close    
*/

* plot for each outcome - fully adjusted 
local a "hosp_any composite_any"
local b "c a"
forvalues i=1/2 {
    local outcome: word `i' of `a'
    local title: word `i' of `b'
    
    use ./output/an_dataset_`outcome', clear 
    drop if stp==""
    describe
    gen index_date = date("01/03/2020", "DMY")
    bys patient_id (start): gen last = _N==_n 
    tab died_liver_any `outcome'_flag if last==1
    * For sensitivity: generate new stop and update last record to end of study period if died of liver disease 
    gen stop_new = stop 
    replace stop_new = date("31/12/2022", "DMY") if last==1 & died_liver_any==1
    stset stop, fail(`outcome'_flag) id(patient_id) enter(index_date) origin(index_date)

    * Add cumulative incidence plots 
    * Not stratifying by stp as cannot use tvc and stratify 
    * Fully adjusted model (though not including wave as not right in main model)
    * Setting df (degrees of freedom for restricted cubic splines) as 3 as this is default 
    * Setting dftvc (degrees of freedom for time-dependent effects) as 1 = linear effect of log time
    * stpm2_standsurv cannot use factor variables so creating dummy variables:
    tab imd, gen(imd) 
    tab bmi_cat, gen(bmi_cat)
    tab smoking, gen(smoking)
    * Check all binary 
    foreach vars in udca male any_high_risk_condition eth_bin imd1 imd2 imd3 imd4 imd5 bmi_cat1 bmi_cat2 bmi_cat3 ///
    bmi_cat4 bmi_cat5 smoking1 smoking2 smoking3 severe_disease covid_vacc_first liver_trans {
        tab `vars', m nolabel
        } 
      
    * fully adjusted model to fit 
    stpm2 udca male age_tv any_high_risk_condition eth_bin imd2 imd3 imd4 imd5 bmi_cat1 bmi_cat3 ///
    bmi_cat4 bmi_cat5 smoking2 smoking3 severe_disease covid_vacc_first liver_trans, ///
     tvc(udca severe_disease covid_vacc_first liver_trans age_tv) dftvc(1) df(2) scale(hazard) eform
    
    summ _t
    local tmax=r(max)
    local tmaxplus1=r(max)+1

    range days 0 `tmax' `tmaxplus1'
    stpm2_standsurv if udca == 1, at1(udca 0) at2(udca 1) timevar(days) ci contrast(difference) fail
    gen date = d(1/3/2020)+ days
    format date %tddd_Month

    for var _at1 _at2 _at1_lci _at1_uci _at2_lci _at2_uci _contrast2_1 _contrast2_1_lci _contrast2_1_uci: replace X=100*X

    *cumulative mortality at last day of follow-up
    list _at1* if days==`tmax', noobs
    list _at2* if days==`tmax', noobs
    list _contrast* if days==`tmax', noobs

    *cumulative mortality at last day of follow-up - write to file 
    file write tablecontent ("`outcome' fully adjusted") _tab ("No UDCA") _tab  
    * cumulative outcome - no UDCA 
    sum _at1 if days==`tmax'
    file write tablecontent (r(mean)) _tab 
    sum _at1_lci if days==`tmax'
    file write tablecontent (r(mean)) _tab 
    sum _at1_uci if days==`tmax'
    file write tablecontent (r(mean)) _tab _n 
    * cumulative outcome - UDCA 
    file write tablecontent ("`outcome'") _tab ("UDCA") _tab  
    sum _at2 if days==`tmax'
    file write tablecontent (r(mean)) _tab 
    sum _at2_lci if days==`tmax'
    file write tablecontent (r(mean)) _tab 
    sum _at2_uci if days==`tmax'
    file write tablecontent (r(mean)) _tab _n 
    
    *l date days _at1 _at1_lci _at1_uci _at2 _at2_lci _at2_uci if days<.

    twoway  (rarea _at1_lci _at1_uci days, color(red%25)) ///
                    (rarea _at2_lci _at2_uci days, color(blue%25)) ///
                    (line _at1 days, sort lcolor(red)) ///
                    (line _at2 days, sort lcolor(blue) lpattern(dash)) ///
                    , legend(order(1 "No UDCA" 2 "UDCA") ring(0) cols(1) pos(11) region(lwidth(none))) ///
                    title("`title'", justification(left) size(med) )  	   ///
                    yscale(range(0, 1)) 											///
                    ylabel(0 (1) 10, angle(0) format(%4.1f) labsize(small))	///
                    xlabel(0 (200) 1035, labsize(small))				   				///			
                    ytitle("Cumulative outcomes (%)", size(medsmall)) ///
                    xtitle("Days since 1 Mar 2020", size(medsmall))      		///
                    graphregion(fcolor(white)) name(adjcurv_f_`outcome', replace)

    graph export "./output/graphs/adjcurv_f_`outcome'.svg", as(svg) replace


    * Post-hoc analysis: Model with liver deaths not censored
    use ./output/an_dataset_`outcome', clear 
    drop if stp==""
    describe
    gen index_date = date("01/03/2020", "DMY")
    bys patient_id (start): gen last = _N==_n 
    tab died_liver_any `outcome'_flag if last==1
    * For sensitivity: generate new stop and update last record to end of study period if died of liver disease 
    gen stop_new = stop 
    replace stop_new = date("31/12/2022", "DMY") if last==1 & died_liver_any==1
    stset stop_new, fail(`outcome'_flag) id(patient_id) enter(index_date) origin(index_date)

    * Add cumulative incidence plots 
    * Not stratifying by stp as cannot use tvc and stratify  
    
    * Age and sex adjusted model 
    * Setting df (degrees of freedom for restricted cubic splines) as 3 as this is default 
    * Setting dftvc (degrees of freedom for time-dependent effects) as 1 = linear effect of log time 
    * fully adjusted model to fit 
    tab imd, gen(imd) 
    tab bmi_cat, gen(bmi_cat)
    tab smoking, gen(smoking)
    * Check all binary 
    foreach vars in udca male any_high_risk_condition eth_bin imd1 imd2 imd3 imd4 imd5 bmi_cat1 bmi_cat2 bmi_cat3 ///
    bmi_cat4 bmi_cat5 smoking1 smoking2 smoking3 severe_disease covid_vacc_first liver_trans {
        tab `vars', m nolabel
        } 
    stpm2 udca male age_tv any_high_risk_condition eth_bin imd2 imd3 imd4 imd5 bmi_cat1 bmi_cat3 ///
    bmi_cat4 bmi_cat5 smoking2 smoking3 severe_disease covid_vacc_first liver_trans, ///
     tvc(udca severe_disease covid_vacc_first liver_trans age_tv) dftvc(1) df(2) scale(hazard) eform
    
    summ _t
    local tmax=r(max)
    local tmaxplus1=r(max)+1

    range days_ph 0 `tmax' `tmaxplus1'
    stpm2_standsurv if udca == 1, at1(udca 0) at2(udca 1) timevar(days_ph) ci contrast(difference) fail

    gen date = d(1/3/2020)+ days_ph
    format date %tddd_Month

    for var _at1 _at2 _at1_lci _at1_uci _at2_lci _at2_uci _contrast2_1 _contrast2_1_lci _contrast2_1_uci: replace X=100*X

    *cumulative mortality at last day of follow-up - write to file 
    file write tablecontent ("Post-hoc: `outcome'") _tab ("No UDCA") _tab  
    * cumulative outcome - no UDCA 
    sum _at1 if days_ph==`tmax'
    file write tablecontent (r(mean)) _tab 
    sum _at1_lci if days_ph==`tmax'
    file write tablecontent (r(mean)) _tab 
    sum _at1_uci if days_ph==`tmax'
    file write tablecontent (r(mean)) _tab _n 
    * cumulative outcome - UDCA 
    file write tablecontent ("`outcome'") _tab ("UDCA") _tab  
    sum _at2 if days_ph==`tmax'
    file write tablecontent (r(mean)) _tab 
    sum _at2_lci if days_ph==`tmax'
    file write tablecontent (r(mean)) _tab 
    sum _at2_uci if days_ph==`tmax'
    file write tablecontent (r(mean)) _tab _n 
    
    *l date days_ph _at1 _at1_lci _at1_uci _at2 _at2_lci _at2_uci if days_ph<.

    twoway  (rarea _at1_lci _at1_uci days_ph, color(red%25)) ///
                    (rarea _at2_lci _at2_uci days_ph, color(blue%25)) ///
                    (line _at1 days_ph, sort lcolor(red)) ///
                    (line _at2 days_ph, sort lcolor(blue) lpattern(dash)) ///
                    , legend(order(1 "No UDCA" 2 "UDCA") ring(0) cols(1) pos(11) region(lwidth(none))) ///
                    title("Time to `outcome'", justification(left) size(med) )  	   ///
                    yscale(range(0, 1)) 											///
                    ylabel(0 (1) 10, angle(0) format(%4.1f) labsize(small))	///
                    xlabel(0 (200) 1035, labsize(small))				   				///			
                    ytitle("Cumulative outcomes (%)", size(medsmall)) ///
                    xtitle("Days since 1 Mar 2020", size(medsmall))      		///
                    graphregion(fcolor(white)) saving(adjcurv_`outcome'_posthoc, replace)

    graph export "./output/graphs/adjcurv_f_`outcome'_post_hoc.svg", as(svg) replace

}

use ./output/an_dataset_died_covid_any, clear 
drop if stp==""
describe
gen index_date = date("01/03/2020", "DMY")
bys patient_id (start): gen last = _N==_n 
tab died_liver_any died_covid_any_flag if last==1
* For sensitivity: generate new stop and update last record to end of study period if died of liver disease 
gen stop_new = stop 
replace stop_new = date("31/12/2022", "DMY") if last==1 & died_liver_any==1
stset stop, fail(died_covid_any_flag) id(patient_id) enter(index_date) origin(index_date)

* Add cumulative incidence plots 
* Not stratifying by stp as cannot use tvc and stratify 
* Fully adjusted model - currently not running     
* Setting df (degrees of freedom for restricted cubic splines) as 3 as this is default 
* Setting dftvc (degrees of freedom for time-dependent effects) as 1 = linear effect of log time
    * stpm2_standsurv cannot use factor variables so creating dummy variables:
tab imd, gen(imd) 
tab bmi_cat, gen(bmi_cat)
tab smoking, gen(smoking)
* Check all binary 
foreach vars in udca male any_high_risk_condition eth_bin imd1 imd2 imd3 imd4 imd5 bmi_cat1 bmi_cat2 bmi_cat3 ///
bmi_cat4 bmi_cat5 smoking1 smoking2 smoking3 severe_disease covid_vacc_first liver_trans {
    tab `vars', m nolabel
    } 
stpm2 udca male age_tv any_high_risk_condition eth_bin imd2 imd3 imd4 imd5 bmi_cat1 bmi_cat3 ///
bmi_cat4 bmi_cat5 smoking2 smoking3 severe_disease covid_vacc_first liver_trans, ///
    tvc(udca severe_disease covid_vacc_first liver_trans age_tv) dftvc(1) df(2) scale(hazard) eform

summ _t
local tmax=r(max)
local tmaxplus1=r(max)+1

range days 0 `tmax' `tmaxplus1'
stpm2_standsurv if udca == 1, at1(udca 0) at2(udca 1) timevar(days) ci contrast(difference) fail

gen date = d(1/3/2020)+ days
format date %tddd_Month

for var _at1 _at2 _at1_lci _at1_uci _at2_lci _at2_uci _contrast2_1 _contrast2_1_lci _contrast2_1_uci: replace X=100*X

*cumulative mortality at last day of follow-up
list _at1* if days==`tmax', noobs
list _at2* if days==`tmax', noobs
list _contrast* if days==`tmax', noobs

*cumulative mortality at last day of follow-up - write to file 
file write tablecontent ("Death fully adjusted") _tab ("No UDCA") _tab  
* cumulative outcome - no UDCA 
sum _at1 if days==`tmax'
file write tablecontent (r(mean)) _tab 
sum _at1_lci if days==`tmax'
file write tablecontent (r(mean)) _tab 
sum _at1_uci if days==`tmax'
file write tablecontent (r(mean)) _tab _n 
* cumulative outcome - UDCA 
file write tablecontent ("Death") _tab ("UDCA") _tab  
sum _at2 if days==`tmax'
file write tablecontent (r(mean)) _tab 
sum _at2_lci if days==`tmax'
file write tablecontent (r(mean)) _tab 
sum _at2_uci if days==`tmax'
file write tablecontent (r(mean)) _tab _n 

*l date days _at1 _at1_lci _at1_uci _at2 _at2_lci _at2_uci if days<.

twoway  (rarea _at1_lci _at1_uci days, color(red%25)) ///
                (rarea _at2_lci _at2_uci days, color(blue%25)) ///
                (line _at1 days, sort lcolor(red)) ///
                (line _at2 days, sort lcolor(blue) lpattern(dash)) ///
                , legend(order(1 "No UDCA" 2 "UDCA") ring(0) cols(1) pos(11) region(lwidth(none))) ///
                title("b", justification(left) size(med) )  	   ///
                yscale(range(0, 1)) 											///
                ylabel(0 (1) 10, angle(0) format(%4.1f) labsize(small))	///
                xlabel(0 (200) 1035, labsize(small))				   				///			
                ytitle("Cumulative mortality (%)", size(medsmall)) ///
                xtitle("Days since 1 Mar 2020", size(medsmall))      		///
                graphregion(fcolor(white)) ///
                name(adjcurv_f_died, replace)

graph export "./output/graphs/adjcurv_f_died_covid_any.svg", as(svg) replace

* Post-hoc analysis: Model with liver deaths not censored
use ./output/an_dataset_died_covid_any, clear 
drop if stp==""
describe
gen index_date = date("01/03/2020", "DMY")
bys patient_id (start): gen last = _N==_n 
tab died_liver_any died_covid_any_flag if last==1
* For sensitivity: generate new stop and update last record to end of study period if died of liver disease 
gen stop_new = stop 
replace stop_new = date("31/12/2022", "DMY") if last==1 & died_liver_any==1
stset stop_new, fail(died_covid_any_flag) id(patient_id) enter(index_date) origin(index_date)

* Add cumulative incidence plots 
* Not stratifying by stp as cannot use tvc and stratify  

* Fully adjusted model 
* Setting df (degrees of freedom for restricted cubic splines) as 3 as this is default 
* Setting dftvc (degrees of freedom for time-dependent effects) as 1 = linear effect of log time 
tab imd, gen(imd) 
tab bmi_cat, gen(bmi_cat)
tab smoking, gen(smoking)
* Check all binary 
foreach vars in udca male any_high_risk_condition eth_bin imd1 imd2 imd3 imd4 imd5 bmi_cat1 bmi_cat2 bmi_cat3 ///
bmi_cat4 bmi_cat5 smoking1 smoking2 smoking3 severe_disease covid_vacc_first liver_trans {
    tab `vars', m nolabel
    } 
stpm2 udca male age_tv any_high_risk_condition eth_bin imd2 imd3 imd4 imd5 bmi_cat1 bmi_cat3 ///
bmi_cat4 bmi_cat5 smoking2 smoking3 severe_disease covid_vacc_first liver_trans, ///
tvc(udca severe_disease covid_vacc_first liver_trans age_tv) dftvc(1) df(2) scale(hazard) eform

summ _t
local tmax=r(max)
local tmaxplus1=r(max)+1

range days_ph 0 `tmax' `tmaxplus1'
stpm2_standsurv if udca == 1, at1(udca 0) at2(udca 1) timevar(days_ph) ci contrast(difference) fail

gen date = d(1/3/2020)+ days_ph
format date %tddd_Month

for var _at1 _at2 _at1_lci _at1_uci _at2_lci _at2_uci _contrast2_1 _contrast2_1_lci _contrast2_1_uci: replace X=100*X

*cumulative mortality at last day of follow-up - write to file 
file write tablecontent ("Post-hoc: died_covid_any") _tab ("No UDCA") _tab  
* cumulative outcome - no UDCA 
sum _at1 if days_ph==`tmax'
file write tablecontent (r(mean)) _tab 
sum _at1_lci if days_ph==`tmax'
file write tablecontent (r(mean)) _tab 
sum _at1_uci if days_ph==`tmax'
file write tablecontent (r(mean)) _tab _n 
* cumulative outcome - UDCA 
file write tablecontent ("`outcome'") _tab ("UDCA") _tab  
sum _at2 if days_ph==`tmax'
file write tablecontent (r(mean)) _tab 
sum _at2_lci if days_ph==`tmax'
file write tablecontent (r(mean)) _tab 
sum _at2_uci if days_ph==`tmax'
file write tablecontent (r(mean)) _tab _n 

*l date days_ph _at1 _at1_lci _at1_uci _at2 _at2_lci _at2_uci if days_ph<.

twoway  (rarea _at1_lci _at1_uci days_ph, color(red%25)) ///
                (rarea _at2_lci _at2_uci days_ph, color(blue%25)) ///
                (line _at1 days_ph, sort lcolor(red)) ///
                (line _at2 days_ph, sort lcolor(blue) lpattern(dash)) ///
                , legend(order(1 "No UDCA" 2 "UDCA") ring(0) cols(1) pos(11) region(lwidth(none))) ///
                title("Time to `outcome'", justification(left) size(med) )  	   ///
                yscale(range(0, 1)) 											///
                ylabel(0 (1) 10, angle(0) format(%4.1f) labsize(small))	///
                xlabel(0 (200) 1035, labsize(small))				   				///			
                ytitle("Cumulative outcomes (%)", size(medsmall)) ///
                xtitle("Days since 1 Mar 2020", size(medsmall))      		///
                graphregion(fcolor(white)) saving(adjcurv_died_covid_any_post_hoc, replace)

graph export "./output/graphs/adjcurv_f_died_covid_any_post_hoc.svg", as(svg) replace

graph combine adjcurv_f_composite_any adjcurv_f_died adjcurv_f_hosp_any, graphregion(color(white))
graph export "./output/graphs/adjcurv_f_combine.svg", as(svg) replace 

file close tablecontent