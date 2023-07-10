/*==============================================================================
DO FILE NAME:			105_analysis_models.do.do
DATE: 					07/07/2023
AUTHOR:					R Costello 
DESCRIPTION OF FILE:	Produce cox models
==============================================================================*/
adopath + ./analysis/ado 
cap mkdir ./output/tables
cap mkdir ./output/tempdata 

* Open a log file
cap log using ./logs/analysis_models.log, replace

* Cox models and Schoenfeld residual plots 
foreach outcome in died_covid_any hosp_any composite_any {
    use ./output/an_dataset_`outcome', clear 
    * Open file to write results
    file open tablecontent using ./output/tables/`outcome'_cox_models.txt, write text replace
    file write tablecontent ("Exposure status") _tab ("denominator") _tab ("events") _tab ("total_person_wks") _tab ("Rate") _tab ("unadj_hr") _tab ///
    ("unadj_ci") _tab ("unadj_lci") _tab ("unadj_uci") _tab ("f_adj_hr") _tab ("f_adj_ci") _tab ("f_adj_lci") _tab ("f_adj_uci") _tab  _n
    describe
    gen index_date = date("01/03/2020", "DMY")
    stset stop, fail(`outcome'_flag) id(patient_id) enter(index_date) origin(index_date)
    count if `outcome'_flag==1
    if r(N) > 10 {
        * Cox model - crude
        stcox udca, strata(stp)
        estimates save "./output/tempdata/crude_`outcome'", replace 
        eststo model1
        parmest, label eform format(estimate p lb ub) saving("./output/tempdata/surv_crude_`outcome'", replace) idstr("crude_`outcome'") 
        estat phtest, plot(`outcome'_flag) ///
                    graphregion(fcolor(white)) ///
                    ylabel(, nogrid labsize(small)) ///
                    xlabel(, labsize(small)) ///
                    xtitle("Time", size(small)) ///
                    ytitle("Scaled Schoenfeld Residuals", size(small)) ///
                    msize(small) ///
                    mcolor(gs6) ///
                    msymbol(circle_hollow) ///
                    scheme(s1mono) ///
                    title ("`outcome'", position(11) size(medsmall)) ///
                    name(uni_plot_`outcome') ///
                    note("")
        * Cox model - fully adjusted
        stcox udca age_tv male any_high_risk_condition i.ethnicity i.imd bmi_cat i.smoking severe_disease covid_vacc_first liver_trans i.wave, strata(stp)
        estimates save "./output/tempdata/adj_model_`outcome'", replace 
        eststo model2
        parmest, label eform format(estimate p lb ub) saving("./output/tempdata/surv_adj_`outcome'", replace) idstr("adj_`outcome'") 
        estat phtest, plot(`outcome'_flag) ///
                    graphregion(fcolor(white)) ///
                    ylabel(, nogrid labsize(small)) ///
                    xlabel(, labsize(small)) ///
                    xtitle("Time", size(small)) ///
                    ytitle("Scaled Schoenfeld Residuals", size(small)) ///
                    msize(small) ///
                    mcolor(gs6) ///
                    msymbol(circle_hollow) ///
                    scheme(s1mono) ///
                    title ("Adjusted `outcome'", position(11) size(medsmall)) ///
                    name(adj_plot_`outcome') ///
                    note("")
        
        bys patient_id (start): gen number = _n==_N 
        tab number 
        qui safecount if udca==0 if number==1
        local denominator = r(N)
        qui safecount if udca == 0 & `outcome'_flag == 1
        local event = r(N)
        bysort udca: egen total_follow_up = total(_t) if number==1
        qui su total_follow_up if udca==0 & number==1
        local person_mth = r(mean)/30
        local rate = 100000*(`event'/`person_mth')
        if `event'>10 & `event'!=. {
            file write tablecontent  ("No UDCA") _tab (`denominator') _tab (`event') _tab %10.0f (`person_mth') _tab %3.2f (`rate') _tab
            file write tablecontent ("1.00") _tab _tab ("1.00") _tab _tab _tab _tab ("1.00") _n
            }
        else {
            file write tablecontent ("No UDCA") _tab ("redact") _n
            continue
        }
        qui safecount if udca==1 if number==1
        local denominator = r(N)
        qui safecount if udca == 1 & `outcome'_admit == 1
        local event = r(N)
        qui su total_follow_up if total(_t) if number==1
        local person_mth = r(mean)/30
        local rate = 100000*(`event'/`person_mth')
        if `event'>10 & `event'!=. {
            file write tablecontent ("UDCA") _tab (`denominator') _tab (`event') _tab %10.0f (`person_mth') _tab %3.2f (`rate') _tab  
            cap estimates use "./output/tempdata/crude_`outcome'" 
            cap lincom 1.udca, eform
            file write tablecontent  %4.2f (r(estimate)) _tab ("(") %4.2f (r(lb)) (" - ") %4.2f (r(ub)) (")") _tab %4.2f (r(lb)) _tab %4.2f (r(ub)) _tab
            cap estimates clear
        }
        else {
            file write tablecontent  ("UDCA") _tab ("redact") _n
            continue
        }
    
drop total_follow_up
    }
else { 
    file write tablecontent ("`period'") _tab ("redact") _n
    continue
}
}

file close tablecontent