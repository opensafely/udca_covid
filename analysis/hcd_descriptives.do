/*==============================================================================
DO FILE NAME:			hcd_descriptives.do
DATE: 					08/11/2023
AUTHOR:					R Costello 
DESCRIPTION OF FILE:	Format variables and then check high cost drugs
==============================================================================*/
adopath + ./analysis/ado 

* Open a log file
cap log using ./logs/hcd_descriptives.log, replace

cap mkdir ./output/tables/

* First import udca population
import delimited using ./output/input_hc_drugs.csv
tab prescribed_oca_n, m 
tab prescribed_udca_hcd, m

log close 
