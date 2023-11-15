/*==============================================================================
DO FILE NAME:			hcd_descriptives.do
DATE: 					08/11/2023
AUTHOR:					R Costello 
DESCRIPTION OF FILE:	Format variables and then output updated high cost drugs (OCA) info for baseline table
==============================================================================*/
adopath + ./analysis/ado 

cap mkdir ./output/tables/

tempfile tempfile 
import delimited using ./output/input_pbc.csv
describe
save `tempfile' 

* First import udca population
import delimited using ./output/input_hc_drugs.csv, clear
save ./output/baseline_oca_n, replace  
merge 1:1 patient_id using `tempfile', keepusing(udca_count_bl oca_bl)
tab prescribed_oca_n oca_bl, m 
tab prescribed_udca_hcd, m

gen udca_bl = (udca_count_bl>=1 & udca_count_bl!=.)
bys udca_bl: sum udca_count_bl

preserve 
table1_mc, vars(prescribed_oca_n bin) by(udca_bl) clear
export delimited using ./output/tables/baseline_oca.csv, replace
* Rounding numbers in table to nearest 5
forvalues i=0/1 {   
    destring _columna_`i', gen(n`i') ignore(",") force
    destring _columnb_`i', gen(percent`i') ignore("-" "%" "(" ")")  force
    gen rounded_n`i' = round(n`i', 5)
    tostring percent`i', gen(percent_`i')
    tostring rounded_n`i', gen(n`i'_rounded)
    replace n`i'_rounded = "redacted" if (rounded_n`i'<=5)
    replace percent_`i' = "redacted" if (rounded_n`i'<=5)
}
keep factor n0_rounded percent_0 n1_rounded percent_1
export delimited using ./output/tables/baseline_oca_rounded.csv
restore 


