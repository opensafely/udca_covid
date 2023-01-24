/*==============================================================================
DO FILE NAME:			feasibility.do
DATE: 					20/01/2023
AUTHOR:					R Costello adaped from C Rentsch 00_cr_create_dataset.do
DESCRIPTION OF FILE:	Format variables and then check feasibility of study
==============================================================================*/
adopath + ./analysis/ado 

* Open a log file
cap log using ./logs/feasibility.log, replace

cap mkdir ./output/tables/

** First import udca population
import delimited using ./output/input.csv

* Format dates 
foreach var in udca_last_date udca_first_after udca_first_history died_date_ons {
    gen `var'A = date(`var', "YMD")
    format `var'A %dD/N/CY
    *list `var' `var'A in  1/5
    drop `var'
}

/* DEMOGRAPHICS */ 

* Sex
gen male = 1 if sex == "M"
replace male = 0 if sex == "F"

/*  Age variables  */ 

* Create categorised age
recode age 18/39.9999 = 1 /// 
           40/49.9999 = 2 ///
		   50/59.9999 = 3 ///
	       60/69.9999 = 4 ///
		   70/79.9999 = 5 ///
		   80/max = 6, gen(agegroup) 

label define agegroup 	1 "18-<40" ///
						2 "40-<50" ///
						3 "50-<60" ///
						4 "60-<70" ///
						5 "70-<80" ///
						6 "80+"
						
label values agegroup agegroup

/* EXPOSURE INFORMATION ====================================================*/
rename udca_last_date udca_date
gen udca = 1 if udca_count != . & udca_count >= 2
recode udca .=0

gen udca_sa = 1 if udca_count != . & udca_count >= 1 & udca_date != . & udca_date >= mdy(12,1,2019)
recode udca_sa .=0

tab1 udca udca_sa, m
tab udca udca_sa, m

*tab  udca_count udca, m

* when was first udca Rx before index date
gen udca_first = 0 if udca == 0
replace udca_first = 1 if udca == 1 & udca_first_history >= mdy(9,1,2019) & udca_first_history < mdy(3,1,2020) 
replace udca_first = 2 if udca == 1 & udca_first_history >= mdy(3,1,2019) & udca_first_history < mdy(9,1,2019) 
replace udca_first = 3 if udca == 1 & udca_first_history >= mdy(9,1,2018) & udca_first_history < mdy(3,1,2019) 
replace udca_first = 4 if udca == 1 & udca_first_history >= mdy(9,1,2017) & udca_first_history < mdy(9,1,2018) 
replace udca_first = 5 if udca == 1 & udca_first_history >= mdy(9,1,2016) & udca_first_history < mdy(9,1,2017) 
replace udca_first = 6 if udca == 1 & udca_first_history >= mdy(9,1,2015) & udca_first_history < mdy(9,1,2016) 
replace udca_first = 7 if udca == 1 & udca_first_history >= mdy(9,1,2014) & udca_first_history < mdy(9,1,2015) 
replace udca_first = 8 if udca == 1 & 										  udca_first_history < mdy(9,1,2014) 

label define udca_first 	0 "unexposed"								///
						1 "within exposure window"					///
						2 "up to 6 mos before exposure window"		///
						3 "6 mos to 1 yr before exposure window"	///
						4 "1 to 2 yr before exposure window"		///
						5 "2 to 3 yr before exposure window"		///
						6 "3 to 4 yr before exposure window"		///
						7 "4 to 5 yr before exposure window"		///
						8 "5+ yr before exposure window"
label values udca_first udca_first

* Flag if died
gen died_flag = died_date_onsA!=.
* Generate date if died of covid
gen died_date_onscovid = died_date_onsA if died_ons_covid_flag_any == 1

gen died_covid_2020 = (died_date_onscovid<date("31Dec2020", "DMY") & died_flag==1)

**** Summary INFORMATION
** Currently dataset includes all people with at least one udca prescription
* Tabulate pbc diagnosis vs those with 2+ prescriptions in 6 months prior
tab has_pbc udca, m 

* Tabulating time since first prescription by whether have 2+ prescriptions in the last 6 months
tab udca_first udca, m col

bys udca: sum udca_count

* Export to table 
preserve
table1_mc, by(udca) vars(has_pbc bin \ udca_first cate) saving(./output/tables/udca_all.xlsx, replace)
restore 

* How many COVID-19 deaths in those with pbc and 2+ prescriptions
tab died_ons_covid_flag_any has_pbc if udca==1, row
tab died_covid_2020 has_pbc if udca==1, row col
tab died_flag has_pbc if udca==1, row col

* Summary demographics
tab agegroup has_pbc if udca==1, row col m 
tab sex has_pbc if udca==1, row col m 

* Export to table 
keep if udca==1
table1_mc, by(has_pbc) vars(died_ons_covid_flag_any bin \ died_covid_2020 bin \ died_flag bin \ agegroup cate \ male bin) saving(./output/tables/udca_only.xlsx, replace)

** Next import the PBC population

import delimited using ./output/input_pbc.csv, clear

* Format dates 
foreach var in udca_last_date udca_first_after udca_first_history died_date_ons {
    gen `var'A = date(`var', "YMD")
    format `var'A %dD/N/CY
    *list `var' `var'A in  1/5
    drop `var'
}

/* DEMOGRAPHICS */ 

* Sex
gen male = 1 if sex == "M"
replace male = 0 if sex == "F"

/*  Age variables  */ 

* Create categorised age
recode age 18/39.9999 = 1 /// 
           40/49.9999 = 2 ///
		   50/59.9999 = 3 ///
	       60/69.9999 = 4 ///
		   70/79.9999 = 5 ///
		   80/max = 6, gen(agegroup) 

label define agegroup 	1 "18-<40" ///
						2 "40-<50" ///
						3 "50-<60" ///
						4 "60-<70" ///
						5 "70-<80" ///
						6 "80+"
						
label values agegroup agegroup

/* EXPOSURE INFORMATION ====================================================*/
rename udca_last_date udca_date
gen udca = 1 if udca_count != . & udca_count >= 2
recode udca .=0

gen udca_sa = 1 if udca_count != . & udca_count >= 1 & udca_date != . & udca_date >= mdy(12,1,2019)
recode udca_sa .=0

tab1 udca udca_sa, m
tab udca udca_sa, m

*tab  udca_count udca, m

* when was first udca Rx before index date
gen udca_first = 0 if udca == 0
replace udca_first = 1 if udca == 1 & udca_first_history >= mdy(9,1,2019) & udca_first_history < mdy(3,1,2020) 
replace udca_first = 2 if udca == 1 & udca_first_history >= mdy(3,1,2019) & udca_first_history < mdy(9,1,2019) 
replace udca_first = 3 if udca == 1 & udca_first_history >= mdy(9,1,2018) & udca_first_history < mdy(3,1,2019) 
replace udca_first = 4 if udca == 1 & udca_first_history >= mdy(9,1,2017) & udca_first_history < mdy(9,1,2018) 
replace udca_first = 5 if udca == 1 & udca_first_history >= mdy(9,1,2016) & udca_first_history < mdy(9,1,2017) 
replace udca_first = 6 if udca == 1 & udca_first_history >= mdy(9,1,2015) & udca_first_history < mdy(9,1,2016) 
replace udca_first = 7 if udca == 1 & udca_first_history >= mdy(9,1,2014) & udca_first_history < mdy(9,1,2015) 
replace udca_first = 8 if udca == 1 & 										  udca_first_history < mdy(9,1,2014) 

label define udca_first 	0 "unexposed"								///
						1 "within exposure window"					///
						2 "up to 6 mos before exposure window"		///
						3 "6 mos to 1 yr before exposure window"	///
						4 "1 to 2 yr before exposure window"		///
						5 "2 to 3 yr before exposure window"		///
						6 "3 to 4 yr before exposure window"		///
						7 "4 to 5 yr before exposure window"		///
						8 "5+ yr before exposure window"
label values udca_first udca_first

* Flag if died
gen died_flag = died_date_onsA!=.
* Generate date if died of covid
gen died_date_onscovid = died_date_onsA if died_ons_covid_flag_any == 1
gen died_covid_2020 = (died_date_onscovid<date("31Dec2020", "DMY") & died_flag==1)

**** Summary INFORMATION
** Currently dataset includes all people with a pbc diagnosis, how many have 2+ udca prescription
* Tabulate pbc diagnosis vs those with 2+ prescriptions in 6 months prior
tab udca, m 

* Tabulating time since first prescription by whether have 2+ prescriptions in the last 6 months
tab udca_first udca, col m

* Check number of prescriptions
bys udca: sum udca_count

* How many COVID-19 deaths by whether had 2+ prescriptions
tab died_ons_covid_flag_any udca, row col 
tab died_covid_2020 udca, row col 
tab died_flag udca, row col 


* Summary demographics
tab agegroup udca, row col m 
tab sex udca, row col m 

* Export to table 
table1_mc, by(udca) vars(udca_first cate \ died_ons_covid_flag_any bin \ died_covid_2020 bin \ died_flag bin \ agegroup cate \ male bin) saving(./output/tables/udca_pbc.xlsx, replace)

foreach var in all only pbc {
	import excel using ./output/tables/udca_`var'.xlsx, clear
	export delimited using ./output/tables/udca_`var'.csv, replace 
}




