program define tvc_merge

*! Version:   3.0.0
*! Author:    Mark Lunt
*! Date:      November 14, 2018 @ 13:55:52

  // If failure contains variables from both files, chaos ensues
  // need to split it into fail1 and fail2                          DONE
  
  syntax varlist(min=2 max=2) using/, id(varlist) [FAILurevars(string) ///
			merge(string) EVENTvars(string) ENDonlyvars(string)]
  local start : word 1 of `varlist'
  local stop  : word 2 of `varlist'

	foreach opt in failurevars merge eventvars endonlyvars {
		if "``opt''" != "" {
			local tuoptions `tuoptions'`opt',
		}
	}
   capture trackuse , progname("tvc_merge") av("3.0.0") aid("NA") ///
      options("`tuoptions'")
   if _rc != 0 {
      capture net install ga_fragment, force replace from("http://personalpages.manchester.ac.uk/staff/mark.lunt")
      if _rc == 0 {
         capture trackuse , progname("tvc_merge") av("3.0.0") aid("NA") ///
           options("`tuoptions'")
      }
   }
         
  // varlists of the form var1 - var9 must be changed to a single word
  // in order to work with unab later
  while regexm("`failurevars'", " - ") {
    local failurevars : subinstr local failurevars " - " "-", all
  }

  while regexm("`eventvars'", " - ") {
    local failurevars : subinstr local failurevars " - " "-", all
  }

  while regexm("`endonlyvars'", " - ") {
    local failurevars : subinstr local missingvars " - " "-", all
  }

	capture which isvar
	if (_rc == 111) {
		noi di as error "This command needs {cmd:isvar} to be installed"
		noi di as error `"Click {net "describe isvar, from(http://fmwww.bc.edu/RePEc/bocode/i)": here} to install it"'
			exit 111
		}
		qui isvar _merge
		if "_merge" == "`r(varlist)'" {
			noi di in red "The variable _merge already exists in master file: unable to proceed."
			exit 110
		}

		qui {
			tempvar diff mindiff
			local stype : type start
			gen `stype' `diff' = abs(`stop' - `start')
			egen `mindiff' = min(`diff')
			local md = `mindiff'[1]
			if `md' == 0 {
				noi di in red "You have records with `stop' == `start', which will confuse tvc_merge"
				noi di in red "Please add a small constant to the `stop' value for these records before continuing"
				exit 459
			}
			else if `md' < 0 {
				noi di in red "You have records with `stop' < `start', which will confuse tvc_merge"
				noi di in red "Please fix this before continuing"
				exit 459
			}
		}
		local fail1
		local miss1

		foreach var in `failurevars' `eventvars' {
			capture unab thisvar : `var'
			if _rc == 0 {
				local fail1 `fail1' `thisvar'
			}
		}

		foreach var in `endonlyvars' {
			capture unab thisvar : `var'
			if _rc == 0 {
				local miss1 `miss1' `thisvar'
			}
		}
		
		preserve
		use "`using'", clear
		qui {
			tempvar diff mindiff
			gen `diff' = abs(`stop' - `start')
			egen `mindiff' = min(`diff')
			local md = `mindiff'[1]
			if `md' == 0 {
				noi di in red "You have records with `stop' == `start', which will confuse tvc_merge"
				noi di in red "Please add a small constant to the `stop' value for these records before continuing"
				exit 459
			}
			else if `md' < 0 {
				noi di in red "You have records with `stop' < `start', which will confuse tvc_merge"
				noi di in red "Please fix this before continuing"
				exit 459
			}
		}
		
		local fail2
		local miss2

		foreach var in `failurevars' `eventvars' {
			capture unab thisvar : `var'
			if _rc == 0 {
				local fail2 `fail2' `thisvar'
			}
		}

		foreach var in `endonlyvars' {
			capture unab thisvar : `var'
			if _rc == 0 {
				local miss2 `miss2' `thisvar'
			}
		}
		
		qui isvar _merge
		if "_merge" == "`r(varlist)'" {
			noi di in red "The variable _merge already exists in using file: unable to proceed."
			exit 110
		}
		restore
	
		quietly {
		
			tempfile file1 dates1 temp1
			tempvar infile1 infile2
			gen `infile1' = 1
			sort `id' `start' `stop'
			save "`file1'"
			keep `start' `stop' `id'
			save "`dates1'"
			tempvar x
			gen `x' = _n
			rename `start' s1
			rename `stop'  s2
			tempvar type
			reshape long s, i(`x') j(`type')
			sort `id' s
			by `id' s: egen _X_start1 = max(`type' == 1)
			by `id' s: egen _X_stop1  = max(`type' == 2)
			by `id' s: keep if _n == 1
			drop `x'
			tempfile temp1
			save "`temp1'", replace
		
			use "`using'"
			tempfile file2 dates2 temp2
			gen `infile2' = 1
			sort `id' `start' `stop'
			save "`file2'"
			keep `id' `start' `stop'
			save "`dates2'"
			tempvar x
			gen `x' = _n
			rename `start' s1 
			rename `stop'  s2
			reshape long s, i(`x') j(`type')
			sort `id' s
			by `id' s: egen _X_start2 = max(`type' == 1)
			by `id' s: egen _X_stop2  = max(`type' == 2)
			by `id' s: keep if _n == 1
			drop `x'
				
			append using "`temp1'"
			foreach i in start stop {
				foreach j of numlist 1/2 {
					tempvar temp
					bys `id' s: egen `temp' = max(_X_`i'`j')
					drop _X_`i'`j'
					rename `temp' _X_`i'`j'
				}
			}
			sort `id' s
			by `id' s: keep if _n == 1
			local stype : type s
			by `id': gen `stype' stop = s[_n + 1]
			local nstart _X_start
			local nstop _X_stop
			rename s `nstart'
			rename stop `nstop'

//			drop if `nstop' == .
			gen `stype' `start' = `nstart' if _X_start1     == 1
			gen `stype' `stop'  = `nstop' if _X_stop1[_n+1] == 1

			by `id': replace `start' = `start'[_n-1] if `start' == . & _X_stop1 != 1
			// do the same for stops
			gsort `id' -`nstart'
			by `id': replace `stop' = `stop'[_n-1] if `stop' == .
			sort `id' `start' `stop'
			tempfile temp2
//			local temp2 "D:/temp/temp2"
			save "`temp2'", replace

			merge `id' `start' using "`file1'", update
			if "`fail1'" ~= "" {
				foreach var in `fail1' {
					local type : type `var'
					if (substr("`type'", 1, 3) == "str") {
						replace `var' = "" if `stop' ~= `nstop' & `start' != .
					}
					else {
						replace `var' = 0 if `stop' ~= `nstop' & `start' != .
					}
				}
			}
			if "`miss1'" ~= "" {
				foreach var in `miss1' {
					local type : type `var'
					if (substr("`type'", 1, 3) == "str") {
						replace `var' = "" if `stop' ~= `nstop' & `start' != .
					}
					else {
						replace `var' = . if `stop' ~= `nstop' & `start' != .
					}
				}
			}

			
			drop `start' `stop' _merge
			rename _X_start `start'
			rename _X_stop `stop'
			drop if `start' == . & `stop' == .
			sort `id' `start'
			tempfile temp3
			save "`temp3'", replace
		
			use "`temp2'"
			sort `id' _X_start
			replace `start' = .
			replace `stop' = .
			replace `start' = `nstart' if _X_start2     == 1
			replace `stop'  = `nstop' if _X_stop2[_n+1] == 1
			by `id': replace `start' = `start'[_n-1] if `start' == . & _X_stop2 != 1
			// do the same for stops
			gsort `id' -`nstart'
			by `id': replace `stop' = `stop'[_n-1] if `stop' == .
			sort `id' `start' `stop'
			tempfile temp4
			save "`temp4'", replace

			merge `id' `start' using "`file2'", update
			if "`fail2'" ~= "" {
				foreach var in `fail2' {
					local type : type `var'
					if (substr("`type'", 1, 3) == "str") {
						replace `var' = "" if `stop' ~= `nstop' & `start' != .
					}
					else {
						replace `var' = 0 if `stop' ~= `nstop' & `start' != .
					}
				}
			}
			if "`miss2'" ~= "" {
				foreach var in `miss2' {
					local type : type `var'
					if (substr("`type'", 1, 3) == "str") {
						replace `var' = "" if `stop' ~= `nstop' & `start' != .
					}
					else {
						replace `var' = . if `stop' ~= `nstop' & `start' != .
					}
				}
			}

			drop `start' `stop' _merge
			rename _X_start `start'
			rename _X_stop `stop'
			drop if `start' == . & `stop' == .
			sort `id' `start' 
			merge `id' `start' using "`temp3'", update
			drop if `stop' == .
			drop _merge _X_*
			tempfile  temp5
			save "`temp5'", replace

			if "`merge'" != "" {
				gen `merge' = (`infile1'==1) + 2*(`infile2'==1)
			}
		}
	end
  
		
