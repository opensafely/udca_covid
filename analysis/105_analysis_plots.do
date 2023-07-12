/*==============================================================================
DO FILE NAME:			105_analysis.do.do
DATE: 					07/07/2023
AUTHOR:					R Costello 
DESCRIPTION OF FILE:	Produce cumulative incidence plots
==============================================================================*/
adopath + ./analysis/ado 
cap mkdir ./output/graphs

* Open a log file
cap log using ./logs/analysis.log, replace
* plot for each outcome 
* Initially just try composite outcome
foreach outcome in died_covid_any hosp_any composite_any {
    use ./output/an_dataset_`outcome', clear 
    describe
    gen index_date = date("01/03/2020", "DMY")
    stset stop, fail(`outcome'_flag) id(patient_id) enter(index_date) origin(index_date)

    * Add cumulative incidence plots 
    * Not stratifying by stp as cannot tvc and stratify 
          
    *stpm2 udca age_tv male any_high_risk_condition i.ethnicity i.imd bmi_cat i.smoking severe_disease covid_vacc_first liver_trans i.wave, ///
    * tvc(udca severe_disease covid_vacc_first liver_trans) dftvc(1) df(3) scale(hazard) eform

    stpm2 udca age_tv male, tvc(udca) dftvc(1) df(3) scale(hazard) eform
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

    *l date days _at1 _at1_lci _at1_uci _at2 _at2_lci _at2_uci if days<.

    twoway  (rarea _at1_lci _at1_uci days, color(red%25)) ///
                    (rarea _at2_lci _at2_uci days if _at2_uci<1, color(blue%25)) ///
                    (line _at1 days, sort lcolor(red)) ///
                    (line _at2 days, sort lcolor(blue) lpattern(dash)) ///
                    , legend(order(1 "No UDCA" 2 "UDCA") ring(0) cols(1) pos(11) region(lwidth(none))) ///
                    title("Time to `outcome'", justification(left) size(med) )  	   ///
                    yscale(range(0, 1)) 											///
                    ylabel(0 (0.1) 1, angle(0) format(%4.1f) labsize(small))	///
                    xlabel(0 (20) 160, labsize(small))				   				///			
                    ytitle("Cumulative mortality (%)", size(medsmall)) ///
                    xtitle("Days since 1 Mar 2020", size(medsmall))      		///
                    graphregion(fcolor(white)) saving(adjcurv_`outcome', replace)

    graph export ./output/graphs/adjcurv_`outcome'.svg", as(svg) replace

    * Close window 
    graph close

}