*! version 2.0.6, Ben Jann, 28feb2007
*  1. estadd
*  2. confirm_new_ename
*  3. confirm_esample
*  4. estadd_local
*  5. estadd_scalar
*  6. estadd_matrix
*  7. estadd_mean
*  8. estadd_sd
*  9. estadd_beta
* 10. estadd_coxsnell
* 11. estadd_nagelkerke
* 12. estadd_ysumm
* 13. estadd_summ
* 14. estadd_vif
* 15. estadd_ebsd
* 16. estadd_expb
* 17. estadd_pcorr
* 18. estadd_lrtest

program estadd
	version 8.2
	capt _on_colon_parse `0'
	if !_rc {
		local 0 `"`s(before)'"'
		local names `"`s(after)'"'
	}
	syntax anything(equalok) [if] [in] [, * ]
	if `"`options'"'!="" local options `", `options'"'

//expand estimates names and backup current estimates if necessary
	tempname rcurrent ecurrent
	_return hold `rcurrent'
	local names: list retok names
	if "`names'"=="" local names "."
	foreach name of local names {
		if "`name'"=="." {
			capt est_expand "`name'"
			if _rc local enames "`enames'`name' "
			else local enames "`enames'`r(names)' "
		}
		else {
			capt n est_expand "`name'" //=> error if estimates not found
			local rc = _rc
			if `rc' {
				_return restore `rcurrent'
				exit `rc'
			}
			local enames "`enames'`r(names)' "
		}
	}
	local names: list uniq enames
	if "`names'"=="." local active
	else {
		capt est_expand .
		if _rc local active "."
		else local active "`r(names)'"
		if "`active'"=="." | `:list posof "`active'" in names'==0 {
			local active
			_est hold `ecurrent', restore estsystem nullok
		}
	}
	_return restore `rcurrent', hold
	if `:list sizeof names'>1 local qui quietly
	else local qui

// cases:
// - if active estimates not stored yet and "`names'"==".": simply execute
//   estadd_subcmd to active estimates
// - else if active estimates not stored yet: backup/restore active estimates
// - else if active estimates stored but not in `names': backup/restore active estimates
// - else if active estimates stored: no backup but restore at end

//loop over estimates names and run subcommand
	nobreak {
		foreach m of local names {
			if "`names'"!="." {
				if "`m'"=="." _est unhold `ecurrent'
				else {
					capt confirm new var _est_`m' // fix e(sample)
					if _rc qui replace _est_`m' = 0 if _est_`m' >=.
					_est unhold `m'
					Toggle_estimates_name
				}
			}
			capt n `qui' estadd_`anything' `if' `in' `options'
			local rc = _rc
			if "`names'"!="." {
				if "`m'"=="." _est hold `ecurrent', restore estsystem nullok
				else {
					Toggle_estimates_name `m'
					_est hold `m', estimates varname(_est_`m')
				}
			}
			if `rc' continue, break
		}
		if "`active'"!="" estimates restore `active', noh
	}
	_return restore `rcurrent'
	if `rc' exit `rc'
end

program confirm_new_ename
	capture confirm existence `e(`0')'
	if !_rc {
		di as err "e(`0') already defined"
		exit 110
	}
end

program confirm_esample
	local efun: e(functions)
	if `:list posof "sample" in efun'==0 {
		di as err "e(sample) information not available"
		exit 498
	}
end

program define Toggle_estimates_name, eclass
	local thename `"`e(_estadd_estimates_name)'"'
	ereturn local _estadd_estimates_name `"`e(_estimates_name)'"'
	ereturn local _estimates_name `"`thename'"'
end

* -estadd- subroutine: add local
program estadd_loc
	estadd_local `0'
end
program estadd_loca
	estadd_local `0'
end
program estadd_local, eclass
	version 8.2
	syntax anything(equalok) [, Prefix(name) Replace ]
	if "`replace'"=="" {
		gettoken name : anything , parse(" =:")
		confirm_new_ename `prefix'`name'
	}
	ereturn local `prefix'`anything'
end

* -estadd- subroutine: add scalar
program estadd_sca
	estadd_scalar `0'
end
program estadd_scal
	estadd_scalar `0'
end
program estadd_scala
	estadd_scalar `0'
end
program estadd_scalar, eclass
	version 8.2
	syntax anything(equalok) [, Prefix(name) Replace ]
	if "`replace'"=="" {
		gettoken name : anything , parse(" =")
		confirm_new_ename `prefix'`name'
	}
	ereturn scalar `prefix'`anything'
end

* -estadd- subroutine: add matrix
program estadd_mat
	estadd_matrix `0'
end
program estadd_matr
	estadd_matrix `0'
end
program estadd_matri
	estadd_matrix `0'
end
program estadd_matrix, eclass
	version 8.2
	syntax anything(equalok) [, Prefix(name) Replace * ]
	if "`options'"!="" local options ", `options'"
	if "`replace'"=="" {
		gettoken name : anything , parse(" =")
		confirm_new_ename `prefix'`name'
	}
	ereturn matrix `prefix'`anything' `options'
end

* -estadd- subroutine: means of regressors
program define estadd_mean, eclass
	version 8.2
	syntax [, Prefix(name) Replace ]
//check availability of e(sample)
	confirm_esample
//check e()-names
	if "`replace'"=="" confirm_new_ename `prefix'mean
//use aweights with -summarize-
	local wtype `e(wtype)'
	if "`wtype'"=="pweight" local wtype aweight
//subpop?
	local subpop "`e(subpop)'"
	if "`subpop'"=="" local subpop 1
//copy coefficients matrix and determine varnames
	tempname results
	mat `results' = e(b)
	local vars: colnames `results'
//loop over variables: calculate -mean-
	local j 0
	foreach var of local vars {
		local ++j
		capture confirm numeric variable `var'
		if _rc mat `results'[1,`j'] = .z
		else {
			su `var' [`wtype'`e(wexp)'] if e(sample) & `subpop', meanonly
			mat `results'[1,`j'] = r(mean)
		}
	}
//return the results
	ereturn matrix `prefix'mean = `results'
end

* -estadd- subroutine: standard deviations of regressors
program define estadd_sd, eclass
	version 8.2
	syntax [, noBinary Prefix(name) Replace ]
//check availability of e(sample)
	confirm_esample
//check e()-names
	if "`replace'"=="" confirm_new_ename `prefix'sd
//use aweights with -summarize-
	local wtype `e(wtype)'
	if "`wtype'"=="pweight" local wtype aweight
//subpop?
	local subpop "`e(subpop)'"
	if "`subpop'"=="" local subpop 1
//copy coefficients matrix and determine varnames
	tempname results
	mat `results' = e(b)
	local vars: colnames `results'
//loop over variables: calculate -mean-
	local j 0
	foreach var of local vars {
		local ++j
		capture confirm numeric variable `var'
		if _rc mat `results'[1,`j'] = .z
		else {
			capture assert `var'==0 | `var'==1 if e(sample) & `subpop'
			if _rc | "`binary'"=="" {
				qui su `var' [`wtype'`e(wexp)'] if e(sample) & `subpop'
				mat `results'[1,`j'] = r(sd)
			}
			else mat `results'[1,`j'] = .z
		}
	}
//return the results
	ereturn matrix `prefix'sd = `results'
end

* -estadd- subroutine: standardized coefficients
program define estadd_beta, eclass
	version 8.2
	syntax [, Prefix(name) Replace ]
//check availability of e(sample)
	confirm_esample
//check e()-names
	if "`replace'"=="" confirm_new_ename `prefix'beta
//use aweights with -summarize-
	local wtype `e(wtype)'
	if "`wtype'"=="pweight" local wtype aweight
//subpop?
	local subpop "`e(subpop)'"
	if "`subpop'"=="" local subpop 1
//copy coefficients matrix and determine varnames
	tempname results sddep
	mat `results' = e(b)
	local vars: colnames `results'
	local eqs: coleq `results', q
	local depv "`e(depvar)'"
//loop over variables: calculate -beta-
	local j 0
	local lastdepvar
	foreach var of local vars {
		local depvar: word `++j' of `eqs'
		if "`depvar'"=="_" local depvar "`depv'"
		capture confirm numeric variable `depvar'
		if _rc mat `results'[1,`j'] = .z
		else {
			if "`depvar'"!="`lastdepvar'" {
				qui su `depvar' [`wtype'`e(wexp)'] if e(sample) & `subpop'
				scalar `sddep' = r(sd)
			}
			capture confirm numeric variable `var'
			if _rc mat `results'[1,`j'] = .z
			else {
				qui su `var' [`wtype'`e(wexp)'] if e(sample) & `subpop'
				mat `results'[1,`j'] = `results'[1,`j'] * r(sd) / `sddep'
			}
		}
		local lastdepvar "`depvar'"
	}
//return the results
	ereturn matrix `prefix'beta = `results'
end

* -estadd- subroutine: Cox & Snell Pseudo R-Squared
program define estadd_coxsnell, eclass
	version 8.2
	syntax [, Prefix(name) Replace ]
//check e()-names
	if "`replace'"=="" confirm_new_ename `prefix'coxsnell
//compute statistic
	tempname results
	scalar `results' = 1 - exp( e(ll_0) - e(ll) )^( 2 / e(N) )
//return the results
	di as txt "Cox & Snell Pseudo R2 = " as res `results'
	ereturn scalar `prefix'coxsnell = `results'
end

* -estadd- subroutine: Nagelkerke Pseudo R-Squared
program define estadd_nagelkerke, eclass
	version 8.2
	syntax [, Prefix(name) Replace ]
//check e()-names
	if "`replace'"=="" confirm_new_ename `prefix'nagelkerke
//compute statistic
	tempname results
	scalar `results' = ( 1 - exp( e(ll_0) - e(ll) )^( 2 / e(N) ) ) ///
	 / ( 1 - exp( e(ll_0) )^( 2 / e(N) ) )
//return the results
	di as txt "Nagelkerke Pseudo R2 = " as res `results'
	ereturn scalar `prefix'nagelkerke = `results'
end

* -estadd- subroutine: summary statistics for dependent variable
program define estadd_ysumm, eclass
	version 8.2
	syntax [, MEan SUm MIn MAx RAnge sd Var cv SEMean SKewness ///
	 Kurtosis MEDian p1 p5 p10 p25 p50 p75 p90 p95 p99 iqr q all ///
	 Prefix(passthru) Replace ]
//check availability of e(sample)
	confirm_esample
//default prefix
	if `"`prefix'"'=="" local prefix y
	else {
		local 0 ", `prefix'"
		syntax [, prefix(name) ]
	}
//use aweights with -summarize-
	local wtype `e(wtype)'
	if "`wtype'"=="pweight" local wtype aweight
//subpop?
	local subpop "`e(subpop)'"
	if "`subpop'"=="" local subpop 1
//determine list of stats
	tempname results
	local Stats p99 p95 p90 p75 p50 p25 p10 p5 p1 kurtosis ///
	 skewness var sd max min sum mean
	if "`all'"!="" {
		local stats `Stats'
		local range range
		local cv cv
		local semean semean
		local iqr iqr
		local sumtype detail
	}
	else {
		if "`q'"!="" {
			local p25 p25
			local p50 p50
			local p75 p75
		}
		if "`median'"!="" local p50 p50
		foreach stat of local Stats {
			if "``stat''"!="" {
				local stats: list stats | stat
			}
		}
		if "`stats'"=="" & "`range'"=="" & "`cv'"=="" & ///
		 "`semean'"=="" & "`iqr'"=="" local stats sd max min mean
		local sumtype sum mean min max
		if "`:list stats - sumtype'"=="" & "`cv'"=="" & ///
		 "`semean'"=="" & "`iqr'"=="" local sumtype meanonly
		else {
			local sumtype `sumtype' Var sd
			if "`:list stats - sumtype'"=="" & "`iqr'"=="" local sumtype
			else local sumtype detail
		}
	}
	local Stats: subinstr local stats "var" "Var"
	local nstats: word count `iqr' `semean' `cv' `range' `stats'
	if "`replace'"=="" {
		foreach stat in `iqr' `semean' `cv' `range' `stats' {
			confirm_new_ename `prefix'`=lower("`stat'")'
		}
	}
//calculate stats
	local var: word 1 of `e(depvar)'
	mat `results' = J(`nstats',1,.z)
	qui su `var' [`wtype'`e(wexp)'] if e(sample) & `subpop', `sumtype'
	local i 0
	if "`iqr'"!="" {
		mat `results'[`++i',1] = r(p75) - r(p25)
	}
	if "`semean'"!="" {
		mat `results'[`++i',1] = r(sd) / sqrt(r(N))
	}
	if "`cv'"!="" {
		mat `results'[`++i',1] = r(sd) / r(mean)
	}
	if "`range'"!="" {
		mat `results'[`++i',1] = r(max) - r(min)
	}
	foreach stat of local Stats {
		mat `results'[`++i',1] = r(`stat')
	}
//return the results
	local i 0
	foreach stat in `iqr' `semean' `cv' `range' `stats' {
		ereturn scalar `prefix'`=lower("`stat'")' = `results'[`++i',1]
	}
end

* -estadd- subroutine: various summary statistics
program define estadd_summ, eclass
	version 8.2
	syntax [, MEan SUm MIn MAx RAnge sd Var cv SEMean SKewness ///
	 Kurtosis MEDian p1 p5 p10 p25 p50 p75 p90 p95 p99 iqr q all ///
	 Prefix(name) Replace ]
//check availability of e(sample)
	confirm_esample
//use aweights with -summarize-
	local wtype `e(wtype)'
	if "`wtype'"=="pweight" local wtype aweight
//subpop?
	local subpop "`e(subpop)'"
	if "`subpop'"=="" local subpop 1
//determine list of stats
	tempname results results2
	local Stats p99 p95 p90 p75 p50 p25 p10 p5 p1 kurtosis ///
	 skewness var sd max min sum mean
	if "`all'"!="" {
		local stats `Stats'
		local range range
		local cv cv
		local semean semean
		local iqr iqr
		local sumtype detail
	}
	else {
		if "`q'"!="" {
			local p25 p25
			local p50 p50
			local p75 p75
		}
		if "`median'"!="" local p50 p50
		foreach stat of local Stats {
			if "``stat''"!="" {
				local stats: list stats | stat
			}
		}
		if "`stats'"=="" & "`range'"=="" & "`cv'"=="" & ///
		 "`semean'"=="" & "`iqr'"=="" local stats sd max min mean
		local sumtype sum mean min max
		if "`:list stats - sumtype'"=="" & "`cv'"=="" & ///
		 "`semean'"=="" & "`iqr'"=="" local sumtype meanonly
		else {
			local sumtype `sumtype' Var sd
			if "`:list stats - sumtype'"=="" & "`iqr'"=="" local sumtype
			else local sumtype detail
		}
	}
	local Stats: subinstr local stats "var" "Var"
	local nstats: word count `iqr' `semean' `cv' `range' `stats'
	if "`replace'"=="" {
		foreach stat in `iqr' `semean' `cv' `range' `stats' {
			confirm_new_ename `prefix'`=lower("`stat'")'
		}
	}
//copy coefficients matrix and determine varnames
	mat `results' = e(b)
	local vars: colnames `results'
	if `nstats'>1 {
		mat `results' = `results' \ J(`nstats'-1,colsof(`results'),.z)
	}
//loop over variables: calculate stats
	local j 0
	foreach var of local vars {
		local ++j
		capture confirm numeric variable `var'
		if _rc mat `results'[1,`j'] = .z
		else {
			qui su `var' [`wtype'`e(wexp)'] if e(sample) & `subpop', `sumtype'
			local i 0
			if "`iqr'"!="" {
				mat `results'[`++i',`j'] = r(p75) - r(p25)
			}
			if "`semean'"!="" {
				mat `results'[`++i',`j'] = r(sd) / sqrt(r(N))
			}
			if "`cv'"!="" {
				mat `results'[`++i',`j'] = r(sd) / r(mean)
			}
			if "`range'"!="" {
				mat `results'[`++i',`j'] = r(max) - r(min)
			}
			foreach stat of local Stats {
				mat `results'[`++i',`j'] = r(`stat')
			}
		}
	}
//return the results
	local i 0
	foreach stat in `iqr' `semean' `cv' `range' `stats' {
		mat `results2' = `results'[`++i',1...]
		ereturn matrix `prefix'`=lower("`stat'")' = `results2'
	}
end

* -estadd- subroutine: variance inflation factors
program define estadd_vif, eclass
	version 8.2
	syntax [, TOLerance SQRvif Prefix(name) Replace ]
//check availability of e(sample)
	confirm_esample
//check e()-names
	if "`replace'"=="" {
		confirm_new_ename `prefix'vif
		if "`tolerance'"!="" confirm_new_ename `prefix'tolerance
		if "`sqrvif'"!="" confirm_new_ename `prefix'sqrvif
	}
//copy coefficients matrix and set to .z
	tempname results results2 results3
	matrix `results' = e(b)
	forv j = 1/`=colsof(`results')' {
		mat `results'[1,`j'] = .z
	}
	if "`tolerance'"!="" mat `results2' = `results'
	if "`sqrvif'"!="" mat `results3' = `results'
//compute VIF and add to results vector
	capt n vif
	if _rc {
		if _rc == 301 di as err "-estadd:vif- can only be used after -regress-"
		exit _rc
	}
	local i 0
	local name "`r(name_`++i')'"
	while "`name'"!="" {
		local j = colnumb(`results',"`name'")
		if `j'<. {
			matrix `results'[1,`j'] = r(vif_`i')
			if "`tolerance'"!="" matrix `results2'[1,`j'] = 1 / r(vif_`i')
			if "`sqrvif'"!="" matrix `results3'[1,`j'] = sqrt( r(vif_`i') )
		}
		local name "`r(name_`++i')'"
	}
//return the results
	if "`sqrvif'"!="" ereturn matrix `prefix'sqrvif = `results3'
	if "`tolerance'"!="" ereturn matrix `prefix'tolerance = `results2'
	ereturn matrix `prefix'vif = `results'
end

* -estadd- subroutine: standardized factor change coefficients
program define estadd_ebsd, eclass
	version 8.2
	syntax [, Prefix(name) Replace ]
//check availability of e(sample)
	confirm_esample
//check e()-names
	if "`replace'"=="" confirm_new_ename `prefix'ebsd
//use aweights with -summarize-
	local wtype `e(wtype)'
	if "`wtype'"=="pweight" local wtype aweight
//subpop?
	local subpop "`e(subpop)'"
	if "`subpop'"=="" local subpop 1
//copy coefficients matrix and determine varnames
	tempname results
	mat `results' = e(b)
	local vars: colnames `results'
//loop over variables: calculate -mean-
	local j 0
	foreach var of local vars {
		local ++j
		capture confirm numeric variable `var'
		if _rc mat `results'[1,`j'] = .z
		else {
			qui su `var' [`wtype'`e(wexp)'] if e(sample) & `subpop'
			mat `results'[1,`j'] = exp( `results'[1,`j'] * r(sd) )
		}
	}
//return the results
	ereturn matrix `prefix'ebsd = `results'
end

* -estadd- subroutine: exponentiated coefficients
program define estadd_expb, eclass
	version 8.2
	syntax [, noCONStant Prefix(name) Replace ]
//check e()-names
	if "`replace'"=="" confirm_new_ename `prefix'expb
//copy coefficients matrix and determine names of coefficients
	tempname results
	mat `results' = e(b)
	local coefs: colnames `results'
//loop over coefficients
	local j 0
	foreach coef of local coefs {
		local ++j
		if `"`constant'"'!="" & `"`coef'"'=="_cons" {
			mat `results'[1,`j'] = .z
		}
		else {
			mat `results'[1,`j'] = exp(`results'[1,`j'])
		}
	}
//return the results
	ereturn matrix `prefix'expb = `results'
end

* -estadd- subroutine: partial and semi-partial correlations
program define estadd_pcorr, eclass
	version 8.2
	syntax [, semi Prefix(name) Replace ]
//check availability of e(sample)
	confirm_esample
//check e()-names
	if "`replace'"=="" {
		if "`semi'"!="" confirm_new_ename `prefix'spcorr
		confirm_new_ename `prefix'pcorr
	}
//copy coefficients matrix and set to .z
	tempname results results2
	matrix `results' = e(b)
	forv j = 1/`=colsof(`results')' {
		mat `results'[1,`j'] = .z
	}
	local eqs: coleq `results', quoted
	local eq: word 1 of `eqs'
	mat `results2' = `results'[1,"`eq':"]
	local vars: colnames `results2'
	foreach var of local vars {
		capt confirm numeric var `var'
		if !_rc local temp "`temp'`var' "
	}
	local vars "`temp'"
	if "`semi'"!="" mat `results2' = `results'
	else {
		mat drop `results2'
		local results2
	}
	local depv: word 1 of `e(depvar)'
//compute statistics and add to results vector
	local wtype `e(wtype)'
	if inlist("`wtype'","pweight","iweight") local wtype aweight
	_estadd_pcorr_compute `depv' `vars' [`wtype'`e(wexp)'] if e(sample), ///
	 eq(`eq') results(`results') results2(`results2')
//return the results
	if "`semi'"!="" {
		ereturn matrix `prefix'spcorr = `results2'
	}
	ereturn matrix `prefix'pcorr = `results'
end
program define _estadd_pcorr_compute // based on pcorr.ado by StataCorp
                                     // and pcorr2.ado by Richard Williams
	syntax varlist(min=1) [aw fw] [if], eq(str) results(str) [ results2(str) ]
	marksample touse
	tempname hcurrent
	_est hold `hcurrent', restore
	quietly reg `varlist' [`weight'`exp'] if `touse'
	if (e(N)==0 | e(N)>=.) error 2000
	local NmK = e(df_r)
	local R2 = e(r2)
	gettoken depv varlist: varlist
	foreach var of local varlist {
		quietly test `var'
		if r(F)<. {
			local s "1"
			if _b[`var']<0 local s "-1"
			local c = colnumb(`results',"`eq':`var'")
			mat `results'[1,`c'] = `s' * sqrt(r(F)/(r(F)+`NmK'))
			if "`results2'"!="" {
				mat `results2'[1,`c'] = `s' * sqrt(r(F)*((1-`R2')/`NmK'))
			}
		}
	}
end

* -estadd- subroutine: Likelihood-ratio test
program define estadd_lrtest, eclass
	version 8.2
	syntax anything(id="model") [, Name(name) Prefix(name) Replace * ]
	if "`name'"=="" local name lrtest_
//check e()-names
	if "`replace'"=="" {
		confirm_new_ename `prefix'`name'p
		confirm_new_ename `prefix'`name'chi2
		confirm_new_ename `prefix'`name'df
	}
//compute statistics
	lrtest `anything', `options'
//return the results
	ereturn scalar `prefix'`name'p = r(p)
	ereturn scalar `prefix'`name'chi2 = r(chi2)
	ereturn scalar `prefix'`name'df = r(df)
end
