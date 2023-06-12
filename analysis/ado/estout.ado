*! version 2.65, Ben Jann, 29may2007

program define estout, rclass
	version 8.2
	syntax [anything] [using] [ , ///
	 Cells(string asis) ///
	 Drop(string asis)  ///
	 Keep(string asis) ///
	 Order(string asis) ///
	 Indicate(string asis) ///
	 TRansform(string asis) ///
	 EQuations(passthru) ///
	 NOEFORM eform EFORM2(string) ///
	 NOMargin Margin Margin2(string) ///
	 NODIscrete DIscrete(string asis) ///
	 MEQs(string) ///
	 NODROPPED dropped DROPPED2(string) ///
	 level(numlist max=1 int >=10 <=99) ///
	 Stats(string asis) ///
	 STARLevels(string asis) ///
	 NOSTARDetach STARDetach ///
	 VARwidth(numlist max=1 int >=0) ///
	 MODELwidth(numlist max=1 int >=0) ///
	 NOABbrev ABbrev ///
	 NOUNStack UNStack ///
	 EXTRAcols(numlist sort) ///
	 BEGin(string asis) ///
	 DELimiter(string asis) ///
	 end(string asis) ///
	 DMarker(string) ///
	 MSign(string) ///
	 NOLZ lz ///
	 SUBstitute(string asis) ///
	 TItle(string) ///
	 NOLEgend LEgend ///
	 PREHead(string asis) ///
	 POSTHead(string asis) ///
	 PREFoot(string asis) ///
	 POSTFoot(string asis) ///
	 HLinechar(string) ///
	 NOLabel Label ///
	 VARLabels(string asis) ///
	 REFcat(string asis) ///
	 MLabels(string asis) ///
	 NONUMbers NUMbers NUMbers2(string asis) ///
	 COLLabels(string asis) ///
	 EQLabels(string asis) ///
	 MGRoups(string asis) ///
	 NOReplace Replace ///
	 NOAppend Append ///
	 NOTYpe TYpe ///
	 NOSHOWTABS showtabs ///
	 STYle(string) ///
	 DEFaults(string) ///
	 * ///
	 ]
	MoreOptions, `options'
	if "`style'"!="" local defaults "`style'"

*Parse suboptions
	if `"`cells'"'!="none" {
		gettoken row rest: cells, bind qed(qed)
		local cells
		while `"`row'"'!="" {
			local newrow
			gettoken opt row: row, parse(" (")
			if `"`macval(row)'"'=="" & `qed'==0 {
				local row0
				gettoken trash: rest, match(par)
				if `"`par'"'=="(" {
					gettoken opt2 rest: rest, match(par)
				}
				else local opt2
			}
			else {
				gettoken trash row0: row, match(par)
				gettoken opt2: row, match(par)
			}
			while "`opt'"!="" {
				local newrow: list newrow | opt
				if `"`par'"'!="(" {
					gettoken opt row: row, parse(" (")
				}
				else {
					ParseValueSubopts `opt', `macval(opt2)'
					gettoken opt row: row0, parse(" (")
				}
				gettoken trash row0: row, match(par)
				gettoken opt2: row, match(par)
			}
			if `qed' local cells `"`cells'"`newrow'" "'
			else local cells `"`cells'`newrow' "'
			gettoken row rest: rest, bind qed(qed)
		}
		local cells: list retok cells
	}
	if "`eform2'"!="" {
		local eform "`eform2'"
		local eform2
	}
	if `"`transform'"'!="" {
		ParseTransformSubopts `transform'
	}
	if "`margin2'"!="" {
		local margin "`margin2'"
		local margin2
	}
	if `"`dropped'"'!="" local dropped "(dropped)"
	if `"`macval(dropped2)'"'!="" {
		local dropped `"`macval(dropped2)'"'
		local dropped2
	}
	if `"`macval(stats)'"'!="" {
		ParseStatsSubopts `macval(stats)'
		if `"`macval(statslabels)'"'!="" {
			ParseLabelsSubopts statslabels `macval(statslabels)'
		}
	}
	foreach opt in mgroups mlabels eqlabels collabels varlabels {
		if `"`macval(`opt')'"'!="" {
			ParseLabelsSubopts `opt' `macval(`opt')'
		}
	}
	if `"`macval(numbers2)'"'!="" {
		local numbers `"`macval(numbers2)'"'
		local numbers2
	}
	if `"`macval(indicate)'"'!="" {
		ParseIndicateOpts `macval(indicate)'
	}
	if `"`macval(refcat)'"'!="" {
		ParseRefcatOpts `macval(refcat)'
	}
	if `"`macval(starlevels)'"'!="" {
		ParseStarlevels `macval(starlevels)'
	}

*Process No-Options
	foreach opt in unstack eform margin dropped discrete stardetach wrap ///
	 legend label numbers lz abbrev replace append type showtabs smcltags asis {
		if "`no`opt''"!="" local `opt'
	}

*Defaults
	if inlist("`defaults'", "", "smcl", "tab", "fixed", "tex", "html")  {
		if "`nostatslabelsfirst'"=="" local statslabelsfirst first
		if "`nostatslabelslast'"==""  local statslabelslast last
		if "`novarlabelsfirst'"==""   local varlabelsfirst first
		if "`novarlabelslast'"==""    local varlabelslast last
		if "`noeqlabelsfirst'"==""    local eqlabelsfirst first
		if "`noeqlabelslast'"==""     local eqlabelslast last
		if "`notype'"==""             local type type
		if "`nolz'"==""               local lz lz
		if `"`macval(discrete)'"'=="" & "`nodiscrete'"=="" {
			local discrete `"" (d)" for discrete change of dummy variable from 0 to 1"'
		}
		if `"`macval(indicatelabels)'"'=="" local indicatelabels "Yes No"
		if `"`macval(refcatlabel)'"'==""    local refcatlabel "ref."
		if inlist("`defaults'", "", "tab") {
			if `"`macval(delimiter)'"'=="" local delimiter _tab
		}
		else if "`defaults'"=="smcl" {
			if "`varwidth'"==""            local varwidth = cond("`label'"=="", 12, 20)
			if "`modelwidth'"==""          local modelwidth 12
			if "`noabbrev'"==""            local abbrev abbrev
			if `"`macval(delimiter)'"'=="" local delimiter `"" ""'
			if "`nosmcltags'"==""          local smcltags smcltags
			if `"`macval(prehead)'"'==""   local prehead `""{hline @width}""'
			if `"`macval(posthead)'"'==""  local posthead `""{hline @width}""'
			if `"`macval(prefoot)'"'==""   local prefoot `""{hline @width}""'
			if `"`stats'"'!="" & `"`macval(postfoot)'"'=="" local postfoot `""{hline @width}""'
		}
		else if "`defaults'"=="fixed" {
			if "`varwidth'"==""            local varwidth = cond("`label'"=="", 12, 20)
			if "`modelwidth'"==""          local modelwidth 12
			if "`noabbrev'"==""            local abbrev abbrev
			if `"`macval(delimiter)'"'=="" local delimiter `"" ""'
		}
		else if "`defaults'"=="tex" {
			if "`varwidth'"==""            local varwidth = cond("`label'"=="", 12, 20)
			if "`modelwidth'"==""          local modelwidth 12
			if `"`macval(delimiter)'"'=="" local delimiter &
			if `"`macval(end)'"'=="" {
				local end \\\
			}
		}
		else if "`defaults'"=="html" {
			if "`varwidth'"==""            local varwidth = cond("`label'"=="", 12, 20)
			if "`modelwidth'"==""          local modelwidth 12
			if `"`macval(begin)'"'==""     local begin <tr><td>
			if `"`macval(delimiter)'"'=="" local delimiter </td><td>
			if `"`macval(end)'"'==""       local end </td></tr>
		}
	}
	else {
		capture findfile estout_`defaults'.def
		if _rc {
			di as error `"`defaults' style not available "' ///
			 `"(file estout_`defaults'.def not found)"'
			exit 601
		}
		else {
			tempname file
			file open `file' using `"`r(fn)'"', read text
			if c(SE) local max 244
			else local max 80
			while 1 {
				ReadLine `max' `file'
				if `"`line'"'=="" continue, break
				gettoken opt line: line
				if `"`macval(`opt')'"'=="" & `"`no`opt''"'=="" {
					local line: list retok line
					local `opt' `"`macval(line)'"'
				}
			}
			file close `file'
		}
	}
	if "`smcltags'"=="" & "`noasis'"=="" local asis asis
	if "`asis'"!="" local asis "_asis"

*title option
	if `"`macval(prehead)'`macval(posthead)'`macval(prefoot)'`macval(postfoot)'"'=="" ///
	 & `"`macval(title)'"'!="" {
		local prehead `"`"`macval(title)'"'"'
	}

*Generate/clean-up cell contents
	if `"`:list clean cells'"'=="" {
		local cells b
	}
	else if `"`:list clean cells'"'=="none" {
		local cells
	}
	CellsCheck `"`cells'"'

*Special treatment of confidence intervalls
	if "`level'"=="" local level $S_level
	if `level'<10 | `level'>99 {
		di as error "level(`level') invalid"
		exit 198
	}
	if `: list posof "ci" in values' {
		if `"`macval(ci_label)'"'=="" {
			local ci_label "ci`level'"
		}
		if `"`macval(ci_par)'"'=="" {
			if "`ci_separate'"=="" local ci_par `""" , """'
		}
		tokenize `"`macval(ci_par)'"'
		local ci_l_par `""`macval(1)'" "`macval(2)'""'
		local ci_u_par `""" "`macval(3)'""'
	}
	if `: list posof "ci_l" in values' & `"`macval(ci_l_label)'"'=="" {
		local ci_l_label "min`level'"
	}
	if `: list posof "ci_u" in values' & `"`macval(ci_u_label)'"'=="" {
		local ci_u_label "max`level'"
	}

*Formats
	local firstv: word 1 of `values'
	if "`firstv'"=="" local firstv "b"
	if "``firstv'_fmt'"=="" local `firstv'_fmt %9.0g
	foreach v of local values {
		if "``v'_fmt'"=="" local `v'_fmt "``firstv'_fmt'"
		if `"`macval(`v'_label)'"'=="" {
			local `v'_label "`v'"
		}
	}

*Check margin option / prepare discrete option / prepare dropped option
	if "`margin'"!="" {
		if !inlist("`margin'","margin","u","c","p") {
			di as error "margin(`margin') invalid"
			exit 198
		}
		if `"`macval(discrete)'"'!="" {
			gettoken discrete discrete2: discrete
		}
	}
	else local discrete
	local droppedison = (`"`macval(dropped)'"'!="")

*Formats/labels/stars for statistics
	if "`statsfmt'"=="" local statsfmt: word 1 of ``firstv'_fmt'
	ProcessStatslayout `"`stats'"' `"`statsfmt'"' `"`statsstar'"' ///
	 `"`statslayout'"' `"`statspchar'"'
	local stats: list uniq stats
	local p: list posof "p" in stats
	if "`statsstar'"!="" | `p' local p "p df_m F chi2"
	else local p

*Significance stars
	local tablehasstars 0
	foreach v of local values {
		if "``v'_star'"!="" | inlist("`v'","_star","_sigsign") {
			if "``v'_pvalue'"=="" local `v'_pvalue p
			local tablehasstars 1
		}
	}

*Check/define starlevels/make levelslegend
	if `tablehasstars' | `"`statsstar'"'!="" {
		if `"`macval(starlevels)'"'=="" ///
		 local starlevels "* 0.05 ** 0.01 *** 0.001"
		CheckStarvals `"`macval(starlevels)'"' `"`macval(starlevelslabel)'"' ///
		 `"`macval(starlevelsdelimiter)'"'
	}

*Get coefficients/variances/statistics: est_table
	if `"`anything'"'=="" {
		capt est_expand $eststo
		if !_rc {
			local anything `"$eststo"'
		}
	}
	qui estimates table `anything', stats(df_r `p' `stats') `equations'
	if `"`equations'"'=="" & "`unstack'"=="" { // specify equations("") to deactivate
		TableIsAMess
		if `value' {
			qui estimates table `anything', stats(df_r `p' `stats') equations(main=1)
		}
	}
	local models `r(names)'
	local nmodels: word count `models'
	tempname B D St
	mat `St'=r(stats)
	mat `B'=r(coef)
	local nindicate 0
	foreach indi of local indicate {
		local ++nindicate
		ProcessIndicateGrp `nindicate' `B' "`unstack'" ///
		 `"`macval(indicatelabels)'"' `"`macval(indi)'"'
	}
	if `"`keep'"' != "" {
		ExpandEqVarlist `"`keep'"' `B'
		DropOrKeep 1 `B' `"`value'"'
		capt confirm matrix r(result)
		if _rc {
			di as err "all coefficients dropped"
			exit 498
		}
		mat `B' = r(result)
	}
	if `"`drop'"' != "" {
		ExpandEqVarlist `"`drop'"' `B'
		DropOrKeep 0 `B' `"`value'"'
		capt confirm matrix r(result)
		if _rc {
			di as err "all coefficients dropped"
			exit 498
		}
		mat `B' = r(result)
	}
	if `"`order'"' != "" {
		ExpandEqVarlist `"`order'"' `B'
		local order `"`value'"'
		Order `B' `"`order'"'
		mat `B' = r(result)
	}
	local R=rowsof(`B')
	local varlist: rownames `B'
	local eqlist: roweq `B', q
	local eqlist: list clean eqlist
	UniqEqsAndDims `"`eqlist'"'
	MakeQuotedFullnames `"`varlist'"' `"`eqlist'"'
	local fullvarlist `"`value'"'
	mat `D' = J(`R',1,0)
	mat rown `D' = `fullvarlist'

*Calculate p-value
	if "`p'"!="" {
		forv m = 1/`nmodels' {
			if `St'[2,`m']==.z {
				if `St'[4,`m']<.z {
					mat `St'[2,`m'] = Ftail(`St'[3,`m'],`St'[1,`m'],`St'[4,`m'])
				}
				else if `St'[5,`m']<.z {
					mat `St'[2,`m'] = chi2tail(`St'[3,`m'],`St'[5,`m'])
				}
			}
		}
	}

*Make dictionary of matched equations
	if `"`equations'"'!="" {
		ParseEquations, eqs(`eqs') m(`nmodels') `equations'
	}

*Prepare keep/drop
	foreach v of local values {
		local temp `"`fullvarlist'"'
		if `"``v'_keep'"'!="" {
			ExpandEqVarlist `"``v'_keep'"' `B'
			DropOrKeep 1 `B' `"`value'"'
			capt confirm matrix r(result)
			if _rc local temp
			else {
				MakeQuotedFullnames `"`: rownames r(result)'"' `"`: roweq r(result), q'"'
				local temp: list temp & value
			}
		}
		if `"``v'_drop'"'!="" {
			ExpandEqVarlist `"``v'_drop'"' `B'
			DropOrKeep 0 `B' `"`value'"'
			capt confirm matrix r(result)
			if _rc local temp
			else {
				MakeQuotedFullnames `"`: rownames r(result)'"' `"`: roweq r(result), q'"'
				local temp: list temp & value
			}
		}
		local `v'_drop: list fullvarlist - temp
	}

*Prepare unstack
	if "`unstack'"!="" {
		local varlist: list uniq varlist
		GetVarnamesFromOrder `"`order'"'
		local temp: list value & varlist
		local varlist: list temp | varlist
		local cons _cons
		if `:list cons in value'==0 {
			if `:list cons in varlist' {
				local varlist: list varlist - cons
				local varlist: list varlist | cons
			}
		}
		local R: word count `varlist'
		local eqswide: list uniq eqs
		forv i=1/`nindicate' {
			ReorderEqsInIndicate `"`nmodels'"' `"`eqswide'"' ///
			 `"`indicate_`nindicate'_eqs'"' `"`macval(indicate_`nindicate'_lbls)'"'
			local indicate_`nindicate'_lbls `"`macval(value)'"'
		}
	}
	else local eqswide "_"

*RestoreEstimates: mlabelsdepvars, marginals, cell stats, overall stats
	local values: subinstr local values "ci" "ci_l ci_u", word
	if `tablehasstars' {
		local temp
		foreach v of local values {
			local temp: list temp | `v'_pvalue
		}
		local values: list values | temp
	}
	if `"`transform'"'=="" {  // i.e., transform() overwrites eform()
		if "`eform'"!="" {
			local transform "exp(@) exp(@)"
			if "`eform'"!="eform" {
				local transformpattern "`eform'"
			}
		}
	}
	foreach m of local transformpattern {
		if !( "`m'"=="1" | "`m'"=="0" ) {
			di as error "invalid pattern in transform(,pattern()) or eform()"
			exit 198
		}
	}
	local transformf
	local transformdf
	if `"`transform'"'!="" {
		MakeTransformList `B' `"`transform'"' // returns: valuef, valuedf
		if "`transformpattern'"!="" {
			foreach m of local transformpattern {
				if "`m'"=="1" {
					local transformf `"`transformf'`"`valuef'"' "'
					local transformdf `"`transformdf'`"`valuedf'"' "'
				}
				else {
					local transformf `"`transformf'"" "'
					local transformdf `"`transformdf'"" "'
				}
			}
		}
		else {
			forv i = 1/`nmodels' {
				local transformf `"`transformf'`"`valuef'"' "'
				local transformdf `"`transformdf'`"`valuedf'"' "'
			}
		}
	}
	foreach v of local values {
		tempname _`v'
		mat `_`v''=J(rowsof(`B'),`nmodels',.z)
		mat rown `_`v'' = `fullvarlist'
		mat coln `_`v'' = `models'
		if !inlist("`v'","b","se","t","p","ci_l","ci_u","_star","_sign","_sigsign") {
			local xvalues: list xvalues | v
			local x_v: list x_v | _`v'
		}
	}
	if "`unstack'"!="" {
		if "`p'"!="" local p p
		local p: list stats | p
		local aicbicrank "aic bic rank"
		local p: list p - aicbicrank
	}
	else local p
	if "`p'"!="" {
		local value
		foreach eq of local eqswide {
			foreach v of local p {
				local value `"`value'`"`eq':`v'"' "'
			}
		}
		tempname mestats
		mat `mestats' = J(`:list sizeof value',`nmodels',.z)
		mat rown `mestats' = `value'
		mat coln `mestats' = `models'
	}
	if "`mlabelsdepvars'`margin'`xvalues'`p'`label'"!="" {
		RestoreEstimates `B' `D' "`models'" "`eqnames'" `"`eqspec'"' ///
		 "`mlabelsdepvars'" `"`macval(mlabels)'"' "`label'" "`margin'" ///
		 `"`meqs'"' "`xvalues'" "`x_v'" "`St'" "`p'" "`mestats'"
	}
	foreach v of local values {
		if "`v'"=="b" {
			_estout_b `B' `_b' `"`transformf'"' //"`eform'"
		}
		else if "`v'"=="se" {
			_estout_se `B' `_se' `"`transformdf'"' //"`eform'"
		}
		else if "`v'"=="t" {
			_estout_t `B' `_t' `t_abs'
		}
		else if "`v'"=="p" {
			_estout_p `B' `_p' `St'
		}
		else if "`v'"=="ci_l" {
			_estout_ci_l `B' `_ci_l' `St' `level' `"`transformf'"' //"`eform'"
		}
		else if "`v'"=="ci_u" {
			_estout_ci_u `B' `_ci_u' `St' `level' `"`transformf'"' //"`eform'"
		}
		if inlist("`v'","_star","_sign","_sigsign") {
			_estout_b `B' `_`v'' // `"`transformf'"' (do not transform)
		}
	}

*Model labels
	if `"`macval(mlabels)'"'=="" {
		local mlabels "`models'"
	}
	else {
		local temp: list sizeof mlabels
		if `temp'<`nmodels' {
			forv i = `=`temp'+1'/`nmodels' {
				local model: word `i' of `models'
				local mlabels `"`macval(mlabels)' `model'"'
			}
		}
	}
	if "`mlabelsnumbers'"!="" {
		NumberMlabels `nmodels' `"`macval(mlabels)'"'
	}

*Equations labels
	local numeqs: list sizeof eqs
	if `"`macval(eqlabels)'"'=="" {
		if "`label'"!="" {
			foreach eq of local eqs {
				local value
				capture confirm variable `eq'
				if !_rc {
					local value: var l `eq'
				}
				if `"`value'"'=="" local value "`eq'"
				local eqlabels `"`eqlabels'`"`value'"' "'
			}
		}
		else local eqlabels `"`eqs'"'
	}
	else {
		local temp: list sizeof eqlabels
		if `temp'<`numeqs' {
			forv i = `=`temp'+1'/`numeqs' {
				local eq: word `i' of `eqs'
				local value
				if "`label'"!="" {
					capture confirm variable `eq'
					if !_rc {
						local value: var l `eq'
					}
				}
				if `"`value'"'=="" local value "`eq'"
				local eqlabels `"`macval(eqlabels)' `"`value'"'"'
			}
		}
	}
	if "`eqlabelsnone'"!="" & `numeqs'>1 & "`unstack'"=="" {
		EqReplaceCons `"`varlist'"' `"`eqlist'"' `"`eqlabels'"'
		if `"`macval(value)'"'!="" {
			local varlabels `"`macval(value)' `macval(varlabels)'"'
		}
	}

*Column labels
	if `"`macval(collabels)'"'=="" {
		forv j = 1/`ncols' {
			local temp
			forv i = 1/`nrows' {
				local v: word `i' of `cells'
				local v: word `j' of `v'
				if "`v'"!="" {  // required because n. of elements in row may be < ncols
					if `"`macval(temp)'"'!="" {
						local temp `"`macval(temp)'/"'
					}
					local temp `"`macval(temp)'`macval(`v'_label)'"'
				}
			}
			local collabels `"`macval(collabels)'`"`macval(temp)'"' "'
		}
	}

*Prepare refcat()
	if `"`macval(refcat)'"'!="" {
		PrepareRefcat `"`macval(refcat)'"'
	}

*Determine table layout
	local m 1
	local starcol 0
	foreach model of local models {
		local e 0
		foreach eq of local eqswide {
		local stc 0
			local ++e
			if "`unstack'"!="" {
				ModelEqCheck `B' "`eq'" `m'
				if !`value' continue
			}
			local eqsrow "`eqsrow'`e' "
			local modelsrow "`modelsrow'`m' "
			local k 0
			local something 0
			forv j = 1/`ncols' {
				local col
				forv i = 1/`nrows' {
					local row: word `i' of `cells'
					local v: word `j' of `row'
					if `"``v'_star'"'!="" local starcol 1
					if "`v'"=="" local v "." // required because n. of elements in row may be < ncols
					else {
						if "`:word `m' of ``v'_pattern''"=="0" local v ".`v'"
					}
					local col "`col'`v' "
				}
				local nocol 1
				foreach v of local col {
					if index("`v'",".")!=1 {
						local nocol 0
						continue, break
					}
				}
				if !`nocol' {
					local colsrow "`colsrow'`j' "
					if `++k'>1 {
						local modelsrow "`modelsrow'`m' "
						local eqsrow "`eqsrow'`e' "
					}
					if `"`: word `++stc' of `statscolstar''"'=="1" local starcol 1
					local starsrow "`starsrow'`starcol' "
					local starcol 0
					Add2Vblock `"`vblock'"' "`col'"
					local something 1
				}
			}
			if !`something' {
				local col
				forv i = 1/`nrows' {
					local col "`col'. "
				}
				Add2Vblock `"`vblock'"' "`col'"
				local colsrow "`colsrow'1 "
				if `"`: word `++stc' of `statscolstar''"'=="1" local starcol 1
				local starsrow "`starsrow'`starcol' "
				local starcol 0
			}
		}
		local ++m
	}
	VblockCheck `"`vblock'"'
	CountNofEqs "`modelsrow'" "`eqsrow'"
	local neqs `value'
	if `"`extracols'"'!="" {
		foreach row in model eq col star {
			InsertAtCols `"`extracols'"' `"``row'srow'"'
			local `row'srow `"`value'"'
		}
		foreach row of local vblock {
			InsertAtCols `"`extracols'"' `"`row'"'
			local nvblock `"`nvblock' `"`value'"'"'
		}
		local vblock: list clean nvblock
	}
	local ncols = `: word count `starsrow'' + 1

*Modelwidth/varwidth/starwidth
	if "`modelwidth'"=="" local modelwidth 0
	if "`varwidth'"=="" local varwidth 0
	local starwidth 0
	if `modelwidth'>0 {
		if `tablehasstars' | `"`statsstar'"'!="" {
			Starwidth `"`macval(starlevels)'"'
			local starwidth `value'
		}
	}
	if `varwidth'<2 local wrap

* totcharwidth / hline
	local totcharwidth `varwidth'
	capture {
		local delwidth = length(`macval(delimiter)')
	}
	if _rc {
		local delwidth = length(`"`macval(delimiter)'"')
	}
	foreach i of local starsrow {
		local totcharwidth = `totcharwidth' + `delwidth' + `modelwidth'
		if `i' {
			if "`stardetach'"!="" {
				local ++ncols
				local totcharwidth = `totcharwidth' + `delwidth'
			}
			local totcharwidth = `totcharwidth' + `starwidth'
		}
	}
	IsInString "@hline" `"`0'"'
	if `value' {
		local hline `totcharwidth'
		if `hline'>400 local hline 400 // _dup(400) is limit
		if `"`macval(hlinechar)'"'=="" local hlinechar "-"
		local hline: di _dup(`hline') `"`macval(hlinechar)'"'
	}
	else local hline

* check begin, delimiter, end
	tempfile tfile
	tempname file
	file open `file' using `"`tfile'"', write text
	foreach opt in begin delimiter end {
		capture file write `file' `macval(`opt')'
		if _rc {
			local `opt' `"`"`macval(`opt')'"'"'
		}
	}
	file close `file'

* RTF support: set macros rtfrowdef, rtfrowdefbrdrt, rtfrowdefbrdrb, rtfemptyrow
	local hasrtfbrdr 0
	local rtfbrdron 0
	IsInString "@rtfrowdef" `"`begin'"'
	local hasrtf `value'
	if `hasrtf' {
		MakeRtfRowdefs `"`macval(begin)'"' `"`starsrow'"' "`stardetach'" ///
		 `varwidth' `modelwidth'
		local varwidth 0
		local wrap
		local modelwidth 0
		local starwidth 0
		IsInString "@rtfrowdefbrdr" `"`begin'"'
		if `value' {
			local hasrtfbrdr 1
			local rtfbeginbak `"`macval(begin)'"'
			local begin: subinstr local rtfbeginbak "@rtfrowdefbrdr" `"`rtfrowdefbrdrt'"'
			local rtfbrdron 1
		}
		else {
			local begin: subinstr local begin "@rtfrowdef" `"`rtfrowdef'"'
		}
	}

* set widths
	if `modelwidth'>0 local fmt_m "%`modelwidth's"
	if `starwidth'>0 local fmt_star "%-`starwidth's"
	if `varwidth'>0 local fmt_v "%-`varwidth's"
	if "`mgroupsspan'`mlabelsspan'`eqlabelsspan'`collabelsspan'"!="" {
		if `modelwidth'>0 {
			file open `file' using `"`tfile'"', write text replace
			file write `file' `macval(delimiter)'
			file close `file'
			file open `file' using `"`tfile'"', read text
			file read `file' delwidth
			file close `file'
			local delwidth = length(`"`macval(delwidth)'"')
		}
		else local delwidth 0
	}
	if "`stardetach'"!="" {
		local stardetach `"`macval(delimiter)'"'
	}

*Prepare @-Variables
	local atvars2 `""`nmodels'" "`neqs'" "`totcharwidth'" `"`macval(hline)'"' `hasrtf' `"`rtfrowdefbrdrt'"' `"`rtfrowdefbrdrb'"' `"`rtfemptyrow'"'"'
	local atvars3 `"`"`macval(title)'"' `"`macval(discrete)'`macval(discrete2)'"' `"`macval(starlegend)'"'"'

*Open output file
	file open `file' using `"`tfile'"', write text replace

*Write prehead
	foreach line of local prehead {
		if "`smcltags'"!="" file write `file' "{txt}"
		InsertAtVariables `"`macval(line)'"' 0 "`ncols'" `macval(atvars2)' `macval(atvars3)'
		file write `file' `"`macval(value)'"' _n
	}

*Write head: Models groups
	if "`mgroupsnone'"=="" & `"`macval(mgroups)'"'!="" {
		if "`smcltags'"!="" file write `file' "{txt}"
		InsertAtVariables `"`macval(mgroupsbegin)'"' 2 "`ncols'" `macval(atvars2)'
		local mgroupsbegin `"`macval(value)'"'
		InsertAtVariables `"`macval(mgroupsend)'"' 2 "`ncols'" `macval(atvars2)'
		local mgroupsend `"`macval(value)'"'
		local tmpbegin `"`macval(begin)'"'
		local tmpend `"`macval(end)'"'
		if "`mgroupsreplace'"!="" {
			if `"`macval(mgroupsbegin)'"'!="" local tmpbegin
			if `"`macval(mgroupsend)'"'!=""  local tmpend
		}
		MgroupsPattern "`modelsrow'" "`mgroupspattern'"
		Abbrev `varwidth' `"`macval(mgroupslhs)'"' "`abbrev'"
		WriteBegin `"`file'"' `"`macval(mgroupsbegin)'"' `"`macval(tmpbegin)'"' ///
		 `"`fmt_v' (`"`macval(value)'"')"'
		WriteCaption `"`file'"' `"`macval(delimiter)'"' ///
		 `"`macval(stardetach)'"' "`mgroupspattern'" "`mgroupspattern'" ///
		 `"`macval(mgroups)'"' "`starsrow'" "`mgroupsspan'" "`abbrev'" ///
		 "`modelwidth'" "`fmt_m'" "`delwidth'" "`starwidth'" ///
		 `"`macval(mgroupserepeat)'"' `"`macval(mgroupsprefix)'"' ///
		 `"`macval(mgroupssuffix)'"'
		WriteEnd `"`file'"' `"`macval(tmpend)'"' `"`macval(mgroupsend)'"' ///
		 `"`macval(value)'"'
		if `hasrtfbrdr' & `rtfbrdron' {
			local begin: subinstr local rtfbeginbak "@rtfrowdefbrdr" `"`rtfrowdef'"'
			local rtfbrdron 0
		}
	}

*Write head: Models numbers
	if `"`macval(numbers)'"'!="" {
		if "`smcltags'"!="" file write `file' "{txt}"
		if `"`macval(numbers)'"'=="numbers" local numbers "( )"
		file write `file' `macval(begin)' `fmt_v' (`""')
		tokenize `"`macval(numbers)'"'
		numlist `"1/`nmodels'"'
		WriteCaption `"`file'"' `"`macval(delimiter)'"' ///
		 `"`macval(stardetach)'"' "`modelsrow'" "`modelsrow'"  ///
		 "`r(numlist)'" "`starsrow'" "`mlabelsspan'" "`abbrev'"  ///
		 "`modelwidth'" "`fmt_m'" "`delwidth'" "`starwidth'" ///
		 `""' `"`macval(1)'"' `"`macval(2)'"'
		file write `file' `macval(end)' _n
		if `hasrtfbrdr' & `rtfbrdron' {
			local begin: subinstr local rtfbeginbak "@rtfrowdefbrdr" `"`rtfrowdef'"'
			local rtfbrdron 0
		}
	}

*Write head: Models captions
	if "`mlabelsnone'"=="" {
		if "`smcltags'"!="" file write `file' "{txt}"
		InsertAtVariables `"`macval(mlabelsbegin)'"' 2 "`ncols'" `macval(atvars2)'
		local mlabelsbegin `"`macval(value)'"'
		InsertAtVariables `"`macval(mlabelsend)'"' 2 "`ncols'" `macval(atvars2)''
		local mlabelsend `"`macval(value)'"'
		local tmpbegin `"`macval(begin)'"'
		local tmpend `"`macval(end)'"'
		if "`mlabelsreplace'"!="" {
			if `"`macval(mlabelsbegin)'"'!="" local tmpbegin
			if `"`macval(mlabelsend)'"'!=""  local tmpend
		}
		Abbrev `varwidth' `"`macval(mlabelslhs)'"' "`abbrev'"
		WriteBegin `"`file'"' `"`macval(mlabelsbegin)'"' `"`macval(tmpbegin)'"' ///
		 `"`fmt_v' (`"`macval(value)'"')"'
		WriteCaption `"`file'"' `"`macval(delimiter)'"' ///
		 `"`macval(stardetach)'"' "`modelsrow'" "`modelsrow'"  ///
		 `"`macval(mlabels)'"' "`starsrow'" "`mlabelsspan'" "`abbrev'"  ///
		 "`modelwidth'" "`fmt_m'" "`delwidth'" "`starwidth'" ///
		 `"`macval(mlabelserepeat)'"' `"`macval(mlabelsprefix)'"' ///
		 `"`macval(mlabelssuffix)'"'
		WriteEnd `"`file'"' `"`macval(tmpend)'"' `"`macval(mlabelsend)'"' ///
		 `"`macval(value)'"'
		if `hasrtfbrdr' & `rtfbrdron' {
			local begin: subinstr local rtfbeginbak "@rtfrowdefbrdr" `"`rtfrowdef'"'
			local rtfbrdron 0
		}
	}

*Write head: Equations captions
	if "`eqlabelsnone'"=="" {
		InsertAtVariables `"`macval(eqlabelsbegin)'"' 2 "`ncols'" `macval(atvars2)'
		local eqlabelsbegin `"`macval(value)'"'
		InsertAtVariables `"`macval(eqlabelsend)'"' 2 "`ncols'" `macval(atvars2)'
		local eqlabelsend `"`macval(value)'"'
	}
	if `"`eqswide'"'!="_" & "`eqlabelsnone'"=="" {
		local tmpbegin `"`macval(begin)'"'
		local tmpend `"`macval(end)'"'
		if "`eqlabelsreplace'"!="" {
			if `"`macval(eqlabelsbegin)'"'!="" local tmpbegin
			if `"`macval(eqlabelsend)'"'!=""  local tmpend
		}
		if "`smcltags'"!="" file write `file' "{txt}"
		Abbrev `varwidth' `"`macval(eqlabelslhs)'"' "`abbrev'"
		WriteBegin `"`file'"' `"`macval(eqlabelsbegin)'"' `"`macval(tmpbegin)'"' ///
		 `"`fmt_v' (`"`macval(value)'"')"'
		WriteCaption `"`file'"' `"`macval(delimiter)'"' ///
		 `"`macval(stardetach)'"' "`eqsrow'" "`modelsrow'" ///
		 `"`macval(eqlabels)'"' "`starsrow'" "`eqlabelsspan'"  "`abbrev'" ///
		 "`modelwidth'" "`fmt_m'" "`delwidth'" "`starwidth'" ///
		 `"`macval(eqlabelserepeat)'"' `"`macval(eqlabelsprefix)'"' ///
		 `"`macval(eqlabelssuffix)'"'
		WriteEnd `"`file'"' `"`macval(tmpend)'"' `"`macval(eqlabelsend)'"' ///
		 `"`macval(value)'"'
		if `hasrtfbrdr' & `rtfbrdron' {
			local begin: subinstr local rtfbeginbak "@rtfrowdefbrdr" `"`rtfrowdef'"'
			local rtfbrdron 0
		}
	}

*Write head: Columns captions
	if `"`macval(collabels)'"'!="" & "`collabelsnone'"=="" {
		if "`smcltags'"!="" file write `file' "{txt}"
		InsertAtVariables `"`macval(collabelsbegin)'"' 2 "`ncols'" `macval(atvars2)'
		local collabelsbegin `"`macval(value)'"'
		InsertAtVariables `"`macval(collabelsend)'"' 2 "`ncols'" `macval(atvars2)'
		local collabelsend `"`macval(value)'"'
		local tmpbegin `"`macval(begin)'"'
		local tmpend `"`macval(end)'"'
		if "`collabelsreplace'"!="" {
			if `"`macval(collabelsbegin)'"'!="" local tmpbegin
			if `"`macval(collabelsend)'"'!=""  local tmpend
		}
		Abbrev `varwidth' `"`macval(collabelslhs)'"' "`abbrev'"
		WriteBegin `"`file'"' `"`macval(collabelsbegin)'"' `"`macval(tmpbegin)'"' ///
		 `"`fmt_v' (`"`macval(value)'"')"'
		WriteCaption `"`file'"' `"`macval(delimiter)'"' ///
		 `"`macval(stardetach)'"' "`colsrow'" "" `"`macval(collabels)'"' ///
		 "`starsrow'" "`collabelsspan'" "`abbrev'" "`modelwidth'" "`fmt_m'" ///
		 "`delwidth'" "`starwidth'" `"`macval(collabelserepeat)'"' ///
		 `"`macval(collabelsprefix)'"' `"`macval(collabelssuffix)'"'
		WriteEnd `"`file'"' `"`macval(tmpend)'"' `"`macval(collabelsend)'"' ///
		 `"`macval(value)'"'
		if `hasrtfbrdr' & `rtfbrdron' {
			local begin: subinstr local rtfbeginbak "@rtfrowdefbrdr" `"`rtfrowdef'"'
			local rtfbrdron 0
		}
	}

*Write posthead
	foreach line of local posthead {
		if "`smcltags'"!="" file write `file' "{txt}"
		InsertAtVariables `"`macval(line)'"' 0 "`ncols'" `macval(atvars2)' `macval(atvars3)'
		file write `file' `"`macval(value)'"' _n
	}

*Write body of table
*Loop over table rows
	InsertAtVariables `"`macval(varlabelsbegin)'"' 2 "`ncols'" `macval(atvars2)'
	local varlabelsbegin `"`macval(value)'"'
	InsertAtVariables `"`macval(varlabelsend)'"' 2 "`ncols'" `macval(atvars2)'
	local varlabelsend `"`macval(value)'"'
	tempname first
	if `"`vblock'"'!="" {
		local RI = `R' + `nindicate'
		local e 0
		local eqdim = `R' + `nindicate'
		local weqcnt 0
		if `hasrtfbrdr' {
			local begin: subinstr local rtfbeginbak "@rtfrowdefbrdr" `"`rtfrowdefbrdrt'"'
			local rtfbrdron 1
		}
		local varlabelsbegin0 `"`macval(varlabelsbegin)'"'
		local eqlabelsbegin0 `"`macval(eqlabelsbegin)'"'
		if "`eqlabelsfirst'"=="" local eqlabelsbegin0
		forv r = 1/`R' {
			local varlabelsend0 `"`macval(varlabelsend)'"'
			local var: word `r' of `varlist'

*Write equation name/label
			if "`unstack'"=="" {
				local eqvar: word `r' of `fullvarlist'
				if `"`eqs'"'!="_" {
					local eqrlast `"`eqr'"'
					local eqr: word `r' of `eqlist'
					if `"`eqr'"'!=`"`eqrlast'"' & "`eqlabelsnone'"=="" {
					local value: word `++e' of `macval(eqlabels)'
					local eqdim: word `e' of `macval(eqsdims)'
					local weqcnt 0
					if `e'==`numeqs' {
						if "`eqlabelslast'"=="" local eqlabelsend
						local eqdim = `eqdim' + `nindicate'
					}
					local tmpbegin `"`macval(begin)'"'
					local tmpend `"`macval(end)'"'
					if "`eqlabelsreplace'"!="" {
						if `"`macval(eqlabelsbegin0)'"'!="" local tmpbegin
						if `"`macval(eqlabelsend)'"'!=""  local tmpend
					}
					WriteBegin `"`file'"' `"`macval(eqlabelsbegin0)'"' `"`macval(tmpbegin)'"'
					if "`smcltags'"!="" file write `file' "{res}"
					WriteEqrow `"`file'"' `"`macval(delimiter)'"' ///
					 `"`macval(stardetach)'"' `"`macval(value)'"' "`starsrow'" ///
					 "`eqlabelsspan'" "`varwidth'" "`fmt_v'" "`abbrev'" ///
					 "`modelwidth'" "`fmt_m'" "`delwidth'" "`starwidth'" ///
					 `"`macval(eqlabelsprefix)'"' `"`macval(eqlabelssuffix)'"'
					if "`smcltags'"!="" file write `file' "{txt}"
					WriteEnd `"`file'"' `"`macval(tmpend)'"' `"`macval(eqlabelsend)'"'
					if `hasrtfbrdr' & `rtfbrdron' {
						local begin: subinstr local rtfbeginbak "@rtfrowdefbrdr" `"`rtfrowdef'"'
						local rtfbrdron 0
					}
					local eqlabelsbegin0 `"`macval(eqlabelsbegin)'"'
					}
				}
			}
			local ++weqcnt
			if `weqcnt'==1 {
				if "`varlabelsfirst'"=="" local varlabelsbegin0
			}

*Determine rows to be written
			local rvblock
			foreach row of local vblock {
				local c 0
				local skiprow 1
				foreach v of local row {
					local ++c
					if index("`v'",".")==1 continue
					if "`unstack'"!="" {
						local eqr: word `:word `c' of `eqsrow'' of `eqs'
						if `"`eqr'"'!="" local eqvar `"`eqr':`var'"'
						else local eqvar "`var'"
					}
					if rownumb(`B',`"`eqvar'"')<. {
						if `: list eqvar in `v'_drop' continue
						local skiprow 0
						continue, break
					}
				}
				if `skiprow' continue
				local rvblock `"`rvblock'"`row'" "'
			}
			local nrvblock: list sizeof rvblock

*Insert refcat() (unless refcatbelow)
			if `"`macval(refcat)'"'!="" {
				local isref: list posof "`var'" in refcatcoefs
				if `isref' {
					if "`unstack'"=="" {
						local temp `"`eqr'"'
						if `"`temp'"'=="" local temp "_"
					}
					else local temp `"`eqswide'"'
					GenerateRefcatRow `B' "`var'" `"`temp'"' `"`macval(refcatlabel)'"'
					local refcatrow `"`macval(value)'"'
				}
			}
			else local isref 0
			if `isref' & `"`refcatbelow'"'=="" {
				if "`smcltags'"!="" file write `file' "{txt}"
				local tmpbegin `"`macval(begin)'"'
				local tmpend `"`macval(end)'"'
				if "`varlabelsreplace'"!="" {
					if `"`macval(varlabelsbegin0)'"'!="" local tmpbegin
					if `"`macval(varlabelsend0)'"'!=""  local tmpend
				}
				if "`varlabelsnone'"=="" {
					local value: word `isref' of `macval(refcatnames)'
					Abbrev `varwidth' `"`macval(value)'"' "`abbrev'"
				}
				else local value
				WriteBegin `"`file'"' `"`macval(varlabelsbegin0)'"' `"`macval(tmpbegin)'"' ///
				 `"`fmt_v' (`"`macval(varlabelsprefix)'`macval(value)'`macval(varlabelssuffix)'"')"'
				if "`smcltags'"!="" file write `file' "{res}"
				WriteStrRow `"`file'"' "`modelsrow'" `"`eqsrow'"' `"`: list sizeof eqswide'"' ///
				 `"`macval(refcatrow)'"' `"`macval(delimiter)'"' ///
				 `"`macval(stardetach)'"' "`starsrow'" "`abbrev'"  ///
				 "`modelwidth'" "`fmt_m'" "`delwidth'" "`starwidth'"
				if "`smcltags'"!="" file write `file' "{txt}"
				WriteEnd `"`file'"' `"`macval(tmpend)'"' `"`macval(varlabelsend0)'"'
				if `hasrtfbrdr' & `rtfbrdron' {
					local begin: subinstr local rtfbeginbak "@rtfrowdefbrdr" `"`rtfrowdef'"'
					local rtfbrdron 0
				}
				local varlabelsbegin0 `"`macval(varlabelsbegin)'"'
			}

*Write variable name/label
			if "`smcltags'"!="" file write `file' "{txt}"
			local tmpbegin `"`macval(begin)'"'
			if "`varlabelsnone'"=="" {
				VarInList "`var'" "`unstack'" `"`eqvar'"' ///
				 `"`eqr'"' `"`macval(varlabelsblist)'"'
				if `"`macval(value)'"'!="" {
					InsertAtVariables `"`macval(value)'"' 2 "`ncols'" `macval(atvars2)'
					file write `file' `"`macval(value)'"'
					if "`varlabelsreplace'"!="" {
						local tmpbegin
						local varlabelsbegin0
					}
				}
				if "`label'"!="" {
					local temp = index("`var'",".")
					capture local varl: var l `=substr("`var'",`temp'+1,.)'
					if _rc | `"`varl'"'=="" {
						local varl `=substr("`var'",`temp'+1,.)'
					}
					local varl `"`=substr("`var'",1,`temp')'`macval(varl)'"'
				}
				else local varl `var'
				VarInList "`var'" "`unstack'" `"`eqvar'"' ///
				 `"`eqr'"' `"`macval(varlabels)'"'
				if `"`macval(value)'"'!="" {
					local varl `"`macval(value)'"'
				}
				if `"`macval(discrete)'"'!="" {
					local temp 0
					if "`unstack'"=="" {
						if `D'[`r',1]==1 local temp 1
					}
					else {
						foreach eqr of local eqswide {
							if `D'[rownumb(`D',`"`eqr':`var'"'),1]==1 local temp 1
						}
					}
					if `temp'==1 & `temp'<. {
						local varl `"`macval(varl)'`macval(discrete)'"'
					}
				}
			}
			else local varl
			if `hasrtfbrdr' & `r'==`RI' & !(`isref' & `"`refcatbelow'"'!="") {
				if `:list sizeof rvblock'==1 {
					local begin: subinstr local rtfbeginbak "@rtfrowdefbrdr" `"`rtfrowdefbrdrb'"'
					local rtfbrdron 1
				}
			}
			if "`varlabelsreplace'"!="" {
				if `"`macval(varlabelsbegin0)'"'!="" local tmpbegin
			}
			if "`wrap'"!="" & `nrvblock'>1 {
				local wrap_i 1
				local value: piece `wrap_i' `varwidth' of `"`macval(varl)'"', nobreak
				Abbrev `varwidth' `"`macval(value)'"' "`abbrev'"
			}
			else {
				Abbrev `varwidth' `"`macval(varl)'"' "`abbrev'"
			}
			WriteBegin `"`file'"' `"`macval(varlabelsbegin0)'"' `"`macval(tmpbegin)'"' ///
			 `"`fmt_v' (`"`macval(varlabelsprefix)'`macval(value)'`macval(varlabelssuffix)'"')"'
			if `hasrtfbrdr' & `rtfbrdron' {
				local begin: subinstr local rtfbeginbak "@rtfrowdefbrdr" `"`rtfrowdef'"'
				local rtfbrdron 0
			}
			local varlabelsbegin0 `"`macval(varlabelsbegin)'"'

*Write table cells
			if "`smcltags'"!="" file write `file' "{res}"
			local newrow 0
			mat `first'=J(1,`nmodels',1)
			foreach row of local rvblock {
				if `hasrtfbrdr' & `r'==`RI' & !(`isref' & `"`refcatbelow'"'!="") {
					if `"`ferest()'"'=="" {
						local begin: subinstr local rtfbeginbak "@rtfrowdefbrdr" `"`rtfrowdefbrdrb'"'
						local rtfbrdron 1
					}
				}
				local c 0
				foreach v of local row {
					local m: word `++c' of `modelsrow'
					if "`unstack'"!="" {
						capt local eqr: word `:word `c' of `eqsrow'' of `eqs'
						local rr=rownumb(`B',`"`eqr':`var'"')
						if `"`eqr'"'!="" local eqvar `"`eqr':`var'"'
						else local eqvar "`var'"
						if `rr'>=. local v ".`v'"
					}
					else local rr `r'
					if index("`v'",".")!=1 {
						local temp = substr("`v'",index("`v'",".")+1,.)
						if `: list eqvar in `temp'_drop' local v ".`temp'"
					}
					if `newrow' & `c'==1 {
						if "`smcltags'"!="" file write `file' "{txt}"
						if "`wrap'"!="" & `nrvblock'>1 {
							local value
							local space
							while (1) {
								local temp: piece `++wrap_i' `varwidth' of `"`macval(varl)'"', nobreak
								if `"`macval(temp)'"'=="" continue, break
								local value `"`macval(value)'`space'`macval(temp)'"'
								if `wrap_i'<`nrvblock' continue, break
								local space " "
							}
							Abbrev `varwidth' `"`macval(value)'"' "`abbrev'"
							local value `"`fmt_v' (`"`macval(varlabelsprefix)'`macval(value)'`macval(varlabelssuffix)'"')"'
						}
						else local value "_skip(`varwidth')"
						file write `file' `macval(end)' _n `macval(begin)' `value'
						if "`smcltags'"!="" file write `file' "{res}"
					}
					if index("`v'",".")==1 local value
					else if `B'[`rr',`m'*2-1]==0 & `B'[`rr',`m'*2]==0 & `droppedison' {
						if `first'[1,`m'] {
							local value `"`macval(dropped)'"'
							mat `first'[1,`m']=0
						}
						else local value
					}
					else if "`v'"=="ci" {
						if `_ci_l'[`rr',`m']==.z local value `"``v'_vacant'"'
						else if `B'[`rr',`m'*2-1]<. & `_ci_l'[`rr',`m']>=. local value .
						else if `_ci_l'[`rr',`m']<. {
							local format: word `r' of `ci_fmt'
							if "`format'"=="" local format: word `:word count `ci_fmt'' of `ci_fmt'
							local value = `_ci_l'[`rr',`m']
							vFormat `value' `format' "`lz'" `"`macval(dmarker)'"' ///
							 `"`macval(msign)'"' `"`macval(ci_l_par)'"'
							local temp "`macval(value)'"
							local value = `_ci_u'[`rr',`m']
							vFormat `value' `format' "`lz'" `"`macval(dmarker)'"' ///
							 `"`macval(msign)'"' `"`macval(ci_u_par)'"'
							local value `"`macval(temp)'`macval(value)'"'
						}
					}
					else if `_`v''[`rr',`m']==.z local value `"``v'_vacant'"'
					else if `_`v''[`rr',`m']>=.  {
						local value .
					}
					else if "`v'"=="_star" {
						CellStars `"`macval(starlevels)'"' `_``v'_pvalue''[`rr',`m'] `"`macval(`v'_par)'"'
					}
					else if "`v'"=="_sign" {
						MakeSign `_`v''[`rr',`m'] `"`macval(msign)'"' `"`macval(`v'_par)'"'
					}
					else if "`v'"=="_sigsign" {
						MakeSign `_`v''[`rr',`m'] `"`macval(msign)'"' `"`macval(`v'_par)'"' ///
						 `"`macval(starlevels)'"' `_``v'_pvalue''[`rr',`m']
					}
					else {
						local format: word `r' of ``v'_fmt'
						if "`format'"=="" local format: word `:word count ``v'_fmt'' of ``v'_fmt'
						local value = `_`v''[`rr',`m']
						vFormat `value' `format' "`lz'" `"`macval(dmarker)'"' ///
						 `"`macval(msign)'"' `"`macval(`v'_par)'"'
					}
					file write `file' `macval(delimiter)' `fmt_m' (`"`macval(value)'"')
					if index("`v'",".")!=1 & `"``v'_star'"'!="" {
						Stars `"`macval(starlevels)'"' `_``v'_pvalue''[`rr',`m']
						file write `file' `macval(stardetach)' `fmt_star' (`"`macval(value)'"')
					}
					else if `:word `c' of `starsrow''==1 {
						file write `file' `macval(stardetach)' _skip(`starwidth')
					}
				}
				local newrow 1
			}

*End of table row
			if "`smcltags'"!="" file write `file' "{txt}"
			if `weqcnt'==`eqdim' & "`varlabelslast'"=="" ///
			 & !(`isref' & `"`refcatbelow'"'!="") local varlabelsend0
			local tmpend `"`macval(end)'"'
			if "`varlabelsreplace'"!="" {
				if `"`macval(varlabelsend0)'"'!=""  local tmpend
			}
			VarInList "`var'" "`unstack'" `"`eqvar'"' `"`eqr'"' ///
			 `"`macval(varlabelselist)'"'
			InsertAtVariables `"`macval(value)'"' 2 "`ncols'" `macval(atvars2)'
			if "`varlabelsreplace'"!="" {
				if `"`macval(value)'"'!="" local varlabelsend0
			}
			WriteEnd `"`file'"' `"`macval(tmpend)'"' `"`macval(varlabelsend0)'"' ///
			 `"`macval(value)'"'
* insert refcat() (if refcatbelow)
			if `isref' & `"`refcatbelow'"'!="" {
			if "`smcltags'"!="" file write `file' "{txt}"
				if `hasrtfbrdr' & `r'==`RI' {
					local begin: subinstr local rtfbeginbak "@rtfrowdefbrdr" `"`rtfrowdefbrdrb'"'
					local rtfbrdron 1
				}
				if `weqcnt'==`eqdim' & "`varlabelslast'"=="" local varlabelsend0
				local tmpbegin `"`macval(begin)'"'
				local tmpend `"`macval(end)'"'
				if "`varlabelsreplace'"!="" {
					if `"`macval(varlabelsbegin0)'"'!="" local tmpbegin
					if `"`macval(varlabelsend0)'"'!=""  local tmpend
				}
				if "`varlabelsnone'"=="" {
					local value: word `isref' of `macval(refcatnames)'
					Abbrev `varwidth' `"`macval(value)'"' "`abbrev'"
				}
				else local value
				WriteBegin `"`file'"' `"`macval(varlabelsbegin0)'"' `"`macval(tmpbegin)'"' ///
				 `"`fmt_v' (`"`macval(varlabelsprefix)'`macval(value)'`macval(varlabelssuffix)'"')"'
				if "`smcltags'"!="" file write `file' "{res}"
				WriteStrRow `"`file'"' "`modelsrow'" `"`eqsrow'"' `"`: list sizeof eqswide'"' ///
				 `"`macval(refcatrow)'"' `"`macval(delimiter)'"' ///
				 `"`macval(stardetach)'"' "`starsrow'" "`abbrev'"  ///
				 "`modelwidth'" "`fmt_m'" "`delwidth'" "`starwidth'"
				if "`smcltags'"!="" file write `file' "{txt}"
				WriteEnd `"`file'"' `"`macval(tmpend)'"' `"`macval(varlabelsend0)'"'
			}
* end insert refcat()
		}
	}

*Write indicator sets
	forv i=1/`nindicate' {
		if `hasrtfbrdr' & `i'==`nindicate' {
			local begin: subinstr local rtfbeginbak "@rtfrowdefbrdr" `"`rtfrowdefbrdrb'"'
			local rtfbrdron 1
		}
		if `i'==`nindicate' & "`varlabelslast'"=="" local varlabelsend
		local tmpbegin `"`macval(begin)'"'
		local tmpend `"`macval(end)'"'
		if "`varlabelsreplace'"!="" {
			if `"`macval(varlabelsbegin0)'"'!="" local tmpbegin
			if `"`macval(varlabelsend)'"'!=""  local tmpend
		}
		if "`varlabelsnone'"=="" {
			Abbrev `varwidth' `"`macval(indicate_`i'_name)'"' "`abbrev'"
		}
		else local value
		if "`smcltags'"!="" file write `file' "{txt}"
		WriteBegin `"`file'"' `"`macval(varlabelsbegin0)'"' `"`macval(tmpbegin)'"' ///
		 `"`fmt_v' (`"`macval(varlabelsprefix)'`macval(value)'`macval(varlabelssuffix)'"')"'
		if "`smcltags'"!="" file write `file' "{res}"
		WriteStrRow `"`file'"' "`modelsrow'" `"`eqsrow'"' `"`: list sizeof eqswide'"' ///
		 `"`macval(indicate_`i'_lbls)'"' `"`macval(delimiter)'"' ///
		 `"`macval(stardetach)'"' "`starsrow'" "`abbrev'"  ///
		 "`modelwidth'" "`fmt_m'" "`delwidth'" "`starwidth'"
		if "`smcltags'"!="" file write `file' "{txt}"
		WriteEnd `"`file'"' `"`macval(tmpend)'"' `"`macval(varlabelsend)'"'
	}

*Write prefoot
	foreach line of local prefoot {
		if "`smcltags'"!="" file write `file' "{txt}"
		InsertAtVariables `"`macval(line)'"' 0 "`ncols'" `macval(atvars2)' `macval(atvars3)'
		file write `file' `"`macval(value)'"' _n
	}

*Write foot of table (statistics)
	InsertAtVariables `"`macval(statslabelsbegin)'"' 2 "`ncols'" `macval(atvars2)'
	local statslabelsbegin `"`macval(value)'"'
	InsertAtVariables `"`macval(statslabelsend)'"' 2 "`ncols'" `macval(atvars2)'
	local statslabelsend `"`macval(value)'"'
	local statslabelsbegin0 `"`macval(statslabelsbegin)'"'
	local S: list sizeof statsarray
	cap confirm matrix `mestats'
	local hasmestats = (_rc==0)
	local eqr "_"
	if `hasrtfbrdr' {
		local begin: subinstr local rtfbeginbak "@rtfrowdefbrdr" `"`rtfrowdefbrdrt'"'
		local rtfbrdron 1
	}
	forv r = 1/`S' {
		if `r'==`S' & `hasrtfbrdr' {
			local begin: subinstr local rtfbeginbak "@rtfrowdefbrdr" `"`rtfrowdefbrdrb'"'
			local rtfbrdron 1
		}
		local stat: word `r' of `macval(statslabels)'
		if `"`stat'"'=="" local stat: word `r' of `statsrowlbls'
		if "`statslabelsnone'"!="" local stat
		if "`smcltags'"!="" file write `file' "{txt}"
		if `r'==1 & "`statslabelsfirst'"=="" local statslabelsbegin0
		local tmpbegin `"`macval(begin)'"'
		if "`statslabelsreplace'"!="" {
			if `"`macval(statslabelsbegin0)'"'!="" local tmpbegin
		}
		Abbrev `varwidth' `"`macval(stat)'"' "`abbrev'"
		WriteBegin `"`file'"' `"`macval(statslabelsbegin0)'"' `"`macval(tmpbegin)'"' ///
		 `"`fmt_v' (`"`macval(statslabelsprefix)'`macval(value)'`macval(statslabelssuffix)'"')"'
		if `r'==1 & "`statslabelsfirst'"=="" {
			local statslabelsbegin0 `"`macval(statslabelsbegin)'"'
		}
		if "`smcltags'"!="" file write `file' "{res}"
		local strow: word `r' of `statsarray'
		local strowlay: word `r' of `macval(statslayout)'
		local strowfmt: word `r' of  `statsrowfmt'
		local strowstar: word `r' of  `statsrowstar'
		local lastm
		local lasteq
		local c 0
		foreach m of local modelsrow {
			local ++c
			if "`m'"=="." {
				file write `file' `macval(delimiter)' `fmt_m' (`""')
				continue
			}
			local value
			local eq: word `:word `c' of `eqsrow'' of `eqs'
			if "`m'"!="`lastm'" local stc 0
			if "`m'"!="`lastm'" | `"`eq'"'!="`lasteq'"  local stc_eq 0
			local usemestats 0
			local ++stc_eq
			local stcell: word `++stc' of `strow'
			local stcelllay: word `stc' of `macval(strowlay)'
			local stcellfmt: word `stc' of `strowfmt'
			local stcellstar: word `stc' of `strowstar'
			local cellhasstat 0
			foreach stat of local stcell {
				gettoken format stcellfmt: stcellfmt
				local rr = rownumb(`St',`"`stat'"')
				local value = `St'[`rr',`m']
				if `value'!=.z {
					local cellhasstat 1
					vFormat `value' "`format'" "`lz'" `"`macval(dmarker)'"' ///
					 `"`macval(msign)'"'
					local stcelllay: subinstr local stcelllay `"`statspchar'"' `"`macval(value)'"'
				}
			}
			if `cellhasstat'==0 & `hasmestats' {
				local stcell: word `stc_eq' of `strow'
				local stcelllay: word `stc_eq' of `macval(strowlay)'
				local stcellfmt: word `stc_eq' of `strowfmt'
				local stcellstar: word `stc_eq' of `strowstar'
				local cellhasstat 0
				foreach stat of local stcell {
					gettoken format stcellfmt: stcellfmt
					local rr = rownumb(`mestats',`"`eq':`stat'"')
					local value = `mestats'[`rr',`m']
					if `value'!=.z {
						local cellhasstat 1
						vFormat `value' "`format'" "`lz'" `"`macval(dmarker)'"' ///
						 `"`macval(msign)'"'
						local stcelllay: subinstr local stcelllay `"`statspchar'"' `"`macval(value)'"'
					}
				}
				if `cellhasstat' local usemestats 1
			}
			if `cellhasstat'==0 local stcelllay
			file write `file' `macval(delimiter)' `fmt_m' (`"`macval(stcelllay)'"')
			if `:word `c' of `starsrow''==1 {
				if "`stcellstar'"=="1" & `cellhasstat' {
					if `usemestats' {
						local rr=rownumb(`mestats',`"`eq':p"')
						Stars `"`macval(starlevels)'"' `mestats'[`rr',`m']
					}
					else {
						Stars `"`macval(starlevels)'"' `St'[2,`m']
					}
					file write `file' `macval(stardetach)' `fmt_star' (`"`macval(value)'"')
				}
				else {
					file write `file' `macval(stardetach)' _skip(`starwidth')
				}
			}
			local lastm "`m'"
			local lasteq `"`eq'"'
		}
		if `r'==`S' & "`statslabelslast'"=="" local statslabelsend
		local tmpend `"`macval(end)'"'
		if "`statslabelsreplace'"!="" {
			if `"`macval(statslabelsend)'"'!="" local tmpend
		}
		if "`smcltags'"!="" file write `file' "{txt}"
		WriteEnd `"`file'"' `"`macval(tmpend)'"' `"`macval(statslabelsend)'"'
		if `hasrtfbrdr' & `rtfbrdron' {
			local begin: subinstr local rtfbeginbak "@rtfrowdefbrdr" `"`rtfrowdef'"'
			local rtfbrdron 0
		}
	}

*Write postfoot
	local discrete: list retok discrete
	foreach line of local postfoot {
		if "`smcltags'"!="" file write `file' "{txt}"
		InsertAtVariables `"`macval(line)'"' 0 "`ncols'" `macval(atvars2)' `macval(atvars3)'
		file write `file' `"`macval(value)'"' _n
	}

*Write legend (starlevels, marginals)
	if "`legend'"!="" {
		if `"`macval(discrete2)'"'!="" {
			mat `D' = `D''*`D'
			if `D'[1,1]!=0 {
				if "`smcltags'"!="" file write `file' "{txt}"
				file write `file' `"`macval(discrete)'`macval(discrete2)'"' _n
			}
		}
		if `"`macval(starlegend)'"'!="" {
			if "`smcltags'"!="" file write `file' "{txt}"
			file write `file' `"`macval(starlegend)'"' _n
		}
	}

*Finish: copy tempfile to user file / type to screen
	file close `file'
	local S: word count `macval(substitute)'
	if `"`using'"'!="" {
		tempname file2
		file open `file2' `using', write text `replace' `append'
	}
	file open `file' using `"`tfile'"', read text
	file read `file' temp
	if "`type'"!="" di as res ""
	while r(eof)==0 {
		forv s = 1(2)`S' {
			local from: word `s' of `macval(substitute)'
			local to:  word `=`s'+1' of `macval(substitute)'
			local temp: subinstr local temp `"`macval(from)'"' `"`macval(to)'"', all
		}
		if `"`using'"'!="" {
			file write `file2' `"`macval(temp)'"' _n
		}
		if "`type'"!="" {
			if "`showtabs'"!="" {
				local temp: subinstr local temp "`=char(9)'" "<T>", all
			}
			di `asis' `"`macval(temp)'"'
		}
		file read `file' temp
	}
	file close `file'
	if `"`using'"'!="" {
		file close `file2'
	}

end

program MoreOptions // estout has more options than -syntax- can handle
	local theoptions ///  MoreOptions is intended for options without arguments only
	 NOASIS asis ///
	 NOWRAP wrap ///
	 NOSMCLTAGS smcltags
	syntax [, `theoptions' ]
	foreach opt of local theoptions {
		local opt = lower("`opt'")
		c_local `opt' "``opt''"
	}
	c_local options
end

program ParseValueSubopts
	syntax anything [ , NOStar Star PVALue(string) fmt(string) Label(string) Vacant(string) ///
	 NOPAR par PAR2(string asis) Keep(string) Drop(string) PATtern(string) NOABS abs ]
	CheckPattern `"`pattern'"' "`anything'"
	if `"`macval(par2)'"'!="" {
		local par `"`macval(par2)'"'
	}
	else if "`par'"!="" {
		if "`anything'"=="ci" local par "[ , ]"
		else if "`anything'"=="ci_l" local par `"[ """'
		else if "`anything'"=="ci_u" local par `""" ]"'
		else local par "( )"
	}
	foreach opt in star par abs {
		if "`no`opt''"!="" c_local no`anything'_`opt' 1
		else c_local `anything'_`opt' `"`macval(`opt')'"'
	}
	foreach opt in pvalue fmt label vacant keep drop pattern {
		c_local `anything'_`opt' `"`macval(`opt')'"'
	}
end

program CheckPattern
	args pattern option
	foreach p of local pattern {
		if !( "`p'"=="1" | "`p'"=="0" ) {
			di as error `""`pattern'" invalid in `option'(... pattern())"'
			exit 198
		}
	}
end

program ParseStatsSubopts
	syntax [anything] [ , fmt(string) Labels(string asis) ///
	 NOStar Star Star2(string) LAYout(string asis) PChar(string) ]
	foreach opt in fmt labels layout pchar {
		c_local stats`opt' `"`macval(`opt')'"'
	}
	if "`nostar'"!="" c_local nostatsstar 1
	else if "`star2'"!="" {
		local anything: list anything | star2
		c_local statsstar "`star2'"
	}
	else if "`star'"!="" {
		local star2: word 1 of `anything'
		c_local statsstar "`star2'"
	}
	c_local stats "`anything'"
	c_local stats2
end

prog ProcessStatslayout // returns statsarray, -rowlbls, -rowfmt, -rowstar, -colstar, -layout
	args stats statsfmt statsstar statslayout statspchar
	local format "%9.0g"
	if `"`statspchar'"'=="" {
		local statspchar "@"
		c_local statspchar "@"
	}
	local statsarray
	local statsrowlbls
	local statsrowfmt
	local statsrowstar
	local space1
	local i 0
	local wmax 0
	foreach row of local statslayout {
		local statsrow
		local statsrowlbl
		local statsrfmt
		local statsrstar
		local space2
		local w = 0
		foreach cell of local row {
			local ++w
			local statscell
			local statsclbl `"`cell'"'
			local statscfmt
			local statscstar 0
			local space3
			local trash: subinstr local cell `"`statspchar'"' "", all count(local cnt)
			forv j=1/`cnt' {
				local stat: word `++i' of `stats'
				local statscell `"`statscell'`space3'`stat'"'
				local statsclbl: subinstr local statsclbl `"`statspchar'"' "`stat'"
				local tmp: word `i' of `statsfmt'
				if `"`tmp'"'!="" local format `"`tmp'"'
				local statscfmt `"`statscfmt'`space3'`format'"'
				if `:list stat in statsstar' {
					local statscstar 1
					local statscol_`w' 1
				}
				local space3 " "
			}
			local statsrow `"`statsrow'`space2'"`statscell'""'
			local statsrowlbl `"`statsrowlbl'`space2'`statsclbl'"'
			local statsrfmt `"`statsrfmt'`space2'"`statscfmt'""'
			local statsrstar "`statsrstar'`space2'`statscstar'"
			local space2 " "
		}
		local statsarray `"`statsarray'`space1'`"`statsrow'"'"'
		local statsrowlbls `"`statsrowlbls'`space1'`"`statsrowlbl'"'"'
		local statsrowfmt `"`statsrowfmt'`space1'`"`statsrfmt'"'"'
		local statsrowstar `"`statsrowstar'`space1'`"`statsrstar'"'"'
		local space1 " "
		local wmax = max(`w',`wmax')
	}
	while (1) {
		local stat: word `++i' of `stats'
		if `"`stat'"'=="" continue, break
		local tmp: word `i' of `statsfmt'
		if `"`tmp'"'!="" local format `"`tmp'"'
		local statscstar: list stat in statsstar
		local statsarray `"`statsarray'`space1'`"`stat'"'"'
		local statsrowlbls `"`statsrowlbls'`space1'`"`stat'"'"'
		local statsrowfmt `"`statsrowfmt'`space1'`"`format'"'"'
		local statsrowstar `"`statsrowstar'`space1'`"`statscstar'"'"'
		local statslayout `"`statslayout'`space1'`statspchar'"'
		local space1 " "
		local wmax = max(1,`wmax')
	}
	local statscolstar
	local space
	forv w = 1/`wmax' {
		if "`statscol_`w''"=="" local statscol_`w' 0
		local statscolstar "`statscolstar'`space'`statscol_`w''"
		local space " "
	}
	c_local statsarray   `"`statsarray'"'
	c_local statsrowlbls `"`statsrowlbls'"'
	c_local statsrowfmt  `"`statsrowfmt'"'
	c_local statsrowstar `"`statsrowstar'"'
	c_local statscolstar `"`statscolstar'"'
	c_local statslayout  `"`statslayout'"'
end

program ParseLabelsSubopts
	gettoken type 0: 0
	syntax [anything] [ , NONUMbers NUMbers NODEPvars DEPvars NONONE NONE ///
	 NOSPAN span Prefix(string) Suffix(string) Begin(string asis) ///
	 End(string asis) NOReplace Replace BList(string asis) EList(string asis) ///
	 ERepeat(string) NOFirst First NOLast Last lhs(string) PATtern(string)  ]
	CheckPattern `"`pattern'"' "`type'"
	foreach opt in prefix suffix begin end blist elist erepeat lhs pattern {
		c_local `type'`opt' `"`macval(`opt')'"'
	}
	foreach opt in numbers depvars span replace none first last {
		if "`no`opt''"!="" c_local no`type'`opt' 1
		else c_local `type'`opt' "``opt''"
	}
	c_local `type' `"`macval(anything)'"'
end

program ReadLine
	args max file
	local end 0
	file read `file' temp1
	while r(eof)==0 {
		local j 1
		local temp2
		local temp3: piece `j++' `max' of `"`macval(temp1)'"'
		if `"`temp3'"'=="" | index(`"`temp3'"',"*")==1 ///
		 | index(`"`temp3'"',"//")==1 {
			file read `file' temp1
			continue
		}
		while `"`temp3'"'!="" {
			local comment=index(`"`macval(temp3)'"'," ///")
			if `comment' {
				local temp3=substr(`"`macval(temp3)'"',1,`comment')
				local temp2 `"`macval(temp2)'`macval(temp3)'"'
				local end 0
				continue, break
			}
			local comment=index(`"`macval(temp3)'"'," //")
			if `comment' {
				local temp3=substr(`"`macval(temp3)'"',1,`comment')
				local temp2 `"`macval(temp2)'`macval(temp3)'"'
				local end 1
				continue, break
			}
			local temp2 `"`macval(temp2)'`macval(temp3)'"'
			local temp3: piece `j++' `max' of `"`macval(temp1)'"'
			local end 1
		}
		if `end' {
			local line `"`macval(line)'`macval(temp2)'"'
			continue, break
		}
		else {
			local line `"`macval(line)'`macval(temp2)'"'
			file read `file' temp1
		}
	}
	c_local line `"`macval(line)'"'
end

program CellsCheck
	args cells
	local ncols 0
	local nrows 0
	foreach row of local cells {
		local newrow
		foreach col of local row {
			if !`:list col in values' {
				local newrow: list newrow | col
				local values: list values | col
			}
		}
		if "`newrow'"!="" {
			local ncols = max(`ncols',`:list sizeof newrow')
			local newcells `"`newcells'"`newrow'" "'
			local ++nrows
		}
	}
	local newcells: list retok newcells
	c_local cells `"`newcells'"'
	c_local ncols `ncols'
	c_local nrows `nrows'
	c_local values `values'
end

program Star2Cells
	args cells star
	local newcells
	foreach row of local cells {
		local newrow
		foreach col of local row {
			if "`col'"=="`star'" {
				local col "`col'star"
			}
			local newrow: list newrow | col
		}
		local newcells `"`newcells'"`newrow'" "'
	}
	local newcells: list retok newcells
	c_local cells `"`newcells'"'
end

prog ParseStarlevels
	syntax [anything(equalok)] [ , Label(str) Delimiter(str) ]
	c_local starlevels `"`macval(anything)'"'
	c_local starlevelslabel `"`macval(label)'"'
	c_local starlevelsdelimiter `"`macval(delimiter)'"'
end

program CheckStarvals
	args starlevels label del
	if `"`macval(label)'"'=="" local label " p<"
	if `"`macval(del)'"'=="" local del ", "
	local nstar: word count `macval(starlevels)'
	local nstar = `nstar'/2
	capture confirm integer number `nstar'
	if _rc {
		di as error "unmatched list of significance symbols and levels"
		exit 198
	}
	local istar 1
	forv i = 1/`nstar' {
		local iistar: word `=`i'*2' of `macval(starlevels)'
		confirm number `iistar'
		if `iistar'>`istar' | `iistar'<=0 {
			di as error "significance levels out of order or out of range (0,1]"
			exit 198
		}
		local istar `iistar'
		local isym: word `=`i'*2-1' of `macval(starlevels)'
		if `"`macval(legend)'"'!="" {
			local legend `"`macval(legend)'`macval(del)'"'
		}
		local ilabel: subinstr local label "@" "`istar'", count(local hasat)
		if `hasat'==0 {
			local ilabel `"`macval(label)'`istar'"'
		}
		local legend `"`macval(legend)'`macval(isym)'`macval(ilabel)'"'
	}
	c_local starlegend `"`macval(legend)'"'
end

program Starwidth
	args starlevels
	local nstar: word count `macval(starlevels)'
	forv i = 2(2)`nstar' {
		local istar: word `=`i'-1' of `macval(starlevels)'
		local width = max(length("`width'"),length(`"`macval(istar)'"'))
	}
	c_local value `width'
end

program ParseEquations
	syntax, eqs(string asis) m(numlist int max=1 >0) EQuations(string asis)
	local eqspec  : subinstr local equations ":" " ", all
	local eqspec0 : subinstr local eqspec "#" "" , all
	local iterm 0
	gettoken term eqspec : eqspec0 , parse(",")
	local eqspec0
	while "`term'" != "" {
		local ++iterm
		gettoken eqname oprest: term, parse("=")
		gettoken op rest : oprest, parse("=")
		if trim(`"`op'"') != "=" {
			local op "="
			local rest "`eqname'"
			local eqname #`iterm'
		}
		if `:list eqname in eqs' {
			if `:list sizeof rest'==1 {
				local temp `rest'
				forv i = 2/`m' {
					local rest `rest' `temp'
				}
			}
			local eqnames `eqnames' `eqname'
			local eqspec0 `"`eqspec0'"`rest'" "'
		}
		if "`eqspec'" == "" {
			continue, break
		}
		gettoken term eqspec: eqspec , parse(",")
		assert "`term'" == ","
		gettoken term eqspec: eqspec , parse(",")
	}
	local eqspec0: list retok eqspec0
	c_local eqspec   `"`eqspec0'"'
	c_local eqnames  `eqnames'
end

program RestoreEstimates
	args B D models eqnames eqspec mldepv labels label margin meqs ///
	 xv x_v St stats mestats
	local elab = "`mldepv'"=="" & "`label'"!=""
	local nlabels: list sizeof labels
	tempname hcurrent
	_est hold `hcurrent', restore nullok estsystem
	nobreak {
		if "`mldepv'"!="" local labels
		local j 1
		foreach m of local models {
			if "`m'"=="." _est unhold `hcurrent'
			else {
				capt confirm new var _est_`m'                   // fix e(sample) if obs
				if _rc qui replace _est_`m' = 0 if _est_`m' >=. // have been added
				_est unhold `m'
//				capt confirm new var _est_`m'
//				if _rc drop _est_`m'
			}
			MatchEqlist "`B'" `j' "`eqnames'" `"`eqspec'"'
			if "`mldepv'"!="" {
				local var: word 1 of `e(depvar)'
				if "`label'"!="" {
					local temp = index("`var'",".")
					capture local lab: var l `=substr("`var'",`temp'+1,.)'
					if _rc | `"`lab'"'=="" {
						local lab `=substr("`var'",`temp'+1,.)'
					}
					local lab `"`=substr("`var'",1,`temp')'`macval(lab)'"'
				}
				else local lab "`var'"
				local labels `"`labels'`"`lab'"' "'
			}
			if `elab' & `j'>`nlabels' {
				local lab `"`e(_estimates_title)'"'
				if `"`lab'"'=="" local lab "`m'"
				local labels `"`labels' `"`lab'"'"'
			}
			if "`margin'"!="" GetMarginals  `B' `D' `j' "`margin'" `"`meqs'"'
			if "`xv'"!="" {
				local x 0
				foreach v of local xv {
					local ++x
					local _v: word `x' of `x_v'
					local options: word `x' of `macval(xoptions)'
					GetValues `v' `j' `B' `_v' `"`eqmatch'"'
				}
			}
			if ( e(cmd)=="reg3" | e(cmd)=="sureg" | e(cmd)=="mvreg" ) ///
			 & "`stats'"!="" {
				GetStats `j' `mestats' `"`eqmatch'"' "`stats'"
			}
			if "`m'"=="." _est hold `hcurrent', restore estsystem
			else _est hold `m', estimates varname(_est_`m')
			local ++j
		}
		_est unhold `hcurrent'
	}
	c_local mlabels `"`macval(labels)'"'
end

program MatchEqlist
	args B j eqnames eqspec
	local eqs1: coleq e(b), q
	local eqs1: list uniq eqs1
	local eqs1: list clean eqs1
	local rest `"`eqs1'"'
	local eqs2: roweq `B', q
	local eqs2: list uniq eqs2
	local eqs2: list clean eqs2
	local i 0
	foreach eq of local eqs2 {
		if `:list eq in eqnames' {
			local ieq: word `++i' of `eqspec'
			local ieq: word `j' of `ieq'
			if `ieq'<. {
				local ieq: word `ieq' of `eqs1'
				if `:list ieq in rest' {
					local eqmatch `"`eqmatch'`"`ieq' `eq'"' "'
					local rest: list rest - ieq
				}
			}
		}
		else if `:list eq in rest' {
			local eqmatch `"`eqmatch'`"`eq' `eq'"' "'
			local rest: list rest - eq
		}
	}
	local eqmatch: list clean eqmatch
	c_local eqmatch `"`eqmatch'"'
end

program GetMarginals
	args B D j margin meqs
		tempname dfdx
		local type `e(Xmfx_type)'
		if "`type'"!="" {
			mat `dfdx' = e(Xmfx_`type')
			capture confirm matrix e(Xmfx_se_`type')
			if _rc==0 {
				mat `dfdx' = `dfdx' \ e(Xmfx_se_`type')
			}
			if "`e(Xmfx_discrete)'"=="discrete" local dummy `e(Xmfx_dummy)'
		}
		else if "`e(cmd)'"=="dprobit" {
			mat `dfdx' = e(dfdx) \ e(se_dfdx)
			local dummy `e(dummy)'
		}
		else if "`e(cmd)'"=="tobit" & inlist("`margin'","u","c","p") {
			capture confirm matrix e(dfdx_`margin')
			if _rc==0 {
				mat `dfdx' = e(dfdx_`margin') \ e(se_`margin')
			}
			local dummy `e(dummy)'
		}
		else if "`e(cmd)'"=="truncreg" {
			capture confirm matrix e(dfdx)
			if _rc==0 {
				tempname V se
				mat `V' = e(V_dfdx)
				forv k= 1/`=rowsof(`V')' {
					mat `se' = nullmat(`se') , sqrt(`V'[`k',`k'])
				}
				mat `dfdx' = e(dfdx) \ `se'
			}
		}
		capture confirm matrix `dfdx'
		if _rc==0 {
			local rnames: rownames `B'
			if `"`meqs'"'!="" local reqs: roweq `B', q
			local i 1
			foreach row of loc rnames {
				if `"`meqs'"'!="" {
					local eq: word `i' of `reqs'
				}
				local col = colnumb(`dfdx',"`row'")
				if `col'>=. | !`:list eq in meqs' {
					mat `B'[`i',`j'*2-1] = .z
					mat `B'[`i',`j'*2] = .z
				}
				else {
					mat `B'[`i',`j'*2-1] =`dfdx'[1,`col']
					mat `B'[`i',`j'*2] = (`dfdx'[2,`col'])^2
					if "`:word `col' of `dummy''"=="1" mat `D'[`i',1] = 1
				}
				local ++i
			}
		}
end

program GetValues
	args v j B _v eqmatch
	capture confirm matrix e(`v')
	if !_rc {
		tempname V
		matrix `V' = e(`v')
		local eqs: coleq `V', q
		local eqs: list clean eqs
		local eqs: list uniq eqs
		if `"`eqs'"'=="_" {
			local useeqs 0
		}
		else {
			local useeqs 1
			local eqs: roweq `_v', q
			foreach eqm of local eqmatch {
				local eq1: word 1 of `eqm'
				local eq2: word 2 of `eqm'
				local eqs: subinstr local eqs `"`eq2'"' `"`eq1'"', word all
			}
		}
		local vars: rownames `_v'
		local i 0
		foreach var of local vars {
			local ++i
			if `useeqs' local eq: word `i' of `eqs'
			else local eq "_"
			local c=colnumb(`V',`"`eq':`var'"')
			if `c'<. & `B'[`i',`j'*2-1]<.z {
				mat `_v'[`i',`j'] = `V'[1,`c']
			}
		}
	}
end

program GetStats
	args j mestats eqmatch stats
	local eqs: coleq e(b), q
	local eqs: list clean eqs
	local eqs: list uniq eqs
	foreach eqm of local eqmatch {
		local eq1: word 1 of `eqm'
		local eq2: word 2 of `eqm'
		local eqs: subinstr local eqs `"`eq1'"' `"`eq2'"', word
	}
	local e 0
	foreach eq of local eqs {
		local ++e
		foreach stat of local stats {
			local r = rownumb(`mestats',`"`eq':`stat'"')
			if `r'==. continue, break
			if e(cmd)=="mvreg" {
				if "`stat'"=="p" local value: word `e' of `e(p_F)'
				else local value: word `e' of `e(`stat')'
			}
			else if "`stat'"=="df_m" {
				local value "`e(`stat'`e')'"
			}
			else {
				local value "`e(`stat'_`e')'"
			}
			capture confirm number `value'
			if !_rc mat `mestats'[`r',`j'] = `value'
		}
	}
end

program _estout_b
	args B _v transform
	local C = colsof(`_v')
	local R = rowsof(`_v')
	local transform: subinstr local transform "@" "\`b'", all
	forv c = 1/`C' {
		gettoken trans transform : transform
		forv r = 1/`R' {
			gettoken tr trans : trans
			local b `B'[`r',`c'*2-1]
			if `"`tr'"'!="" & `b'<. mat `_v'[`r',`c'] = `tr'
			else mat `_v'[`r',`c'] = `b'
		}
	}
end

program _estout_se
	args B _v transform // transform should contain first derivatives
	local C = colsof(`_v')
	local R = rowsof(`_v')
	local transform: subinstr local transform "@" "\`b'", all
	forv c = 1/`C' {
		gettoken trans transform : transform
		forv r = 1/`R' {
			gettoken tr trans : trans
			local b `B'[`r',`c'*2-1]
			local var `B'[`r',`c'*2]
			if `b'>0 & `var'==0 mat `_v'[`r',`c'] = .
			else if `var'>=. mat `_v'[`r',`c'] = `var'
			else if `"`tr'"'!="" mat `_v'[`r',`c'] = sqrt(`var') * `tr'
			else mat `_v'[`r',`c'] = sqrt(`var')
		}
	}
end

program _estout_t
	args B _v abs
	local C = colsof(`_v')
	local R = rowsof(`_v')
	forv c = 1/`C' {
		forv r = 1/`R' {
			local b `B'[`r',`c'*2-1]
			local var `B'[`r',`c'*2]
			if `var'==0 mat `_v'[`r',`c'] = .
			else if `var'>=. mat `_v'[`r',`c'] = `var'
			else mat `_v'[`r',`c'] = `abs'(`b'/sqrt(`var'))
		}
	}
end

program _estout_p
	args B _v df_r
	local C = colsof(`_v')
	local R = rowsof(`_v')
	forv c = 1/`C' {
		forv r = 1/`R' {
			local b `B'[`r',`c'*2-1]
			local var `B'[`r',`c'*2]
			if `var'==0 mat `_v'[`r',`c'] = .
			else if `var'>=. mat `_v'[`r',`c'] = `var'
			else if `df_r'[1,`c']<. ///
			 mat `_v'[`r',`c'] = ttail(`df_r'[1,`c'],abs(`b'/sqrt(`var'))) * 2
			else mat `_v'[`r',`c'] = (1-norm(abs(`b'/sqrt(`var')))) * 2
		}
	}
end

program _estout_ci
	args sign B _v df_r level transform
	local C = colsof(`_v')
	local R = rowsof(`_v')
	local transform: subinstr local transform "@" "\`_v'[\`r',\`c']", all
	forv c = 1/`C' {
		gettoken trans transform : transform
		forv r = 1/`R' {
			gettoken tr trans : trans
			local b `B'[`r',`c'*2-1]
			local var `B'[`r',`c'*2]
			if `var'==0 mat `_v'[`r',`c'] = .
			else if `var'>=. mat `_v'[`r',`c'] = `var'
			else if `df_r'[1,`c']<. mat `_v'[`r',`c'] = `b' `sign' ///
			 invttail(`df_r'[1,`c'],(100-`level')/200) * sqrt(`var')
			else mat `_v'[`r',`c'] = `b' `sign' ///
			 invnorm(1-(100-`level')/200) * sqrt(`var')
			if `"`tr'"'!="" & `_v'[`r',`c']<. mat `_v'[`r',`c'] = `tr'
		}
	}
end

program _estout_ci_l
	_estout_ci - `0'
end

program _estout_ci_u
	_estout_ci + `0'
end

program NumberMlabels
	args M mlabels
	forv m = 1/`M' {
		local num "(`m')"
		local lab: word `m' of `macval(mlabels)'
		if `"`macval(lab)'"'!="" {
			local lab `"`num' `macval(lab)'"'
		}
		else local lab `num'
		local labels `"`macval(labels)'`"`macval(lab)'"' "'
	}
	c_local mlabels `"`macval(labels)'"'
end

program ModelEqCheck
	args B eq m
	tempname Bsub
	mat `Bsub' = `B'["`eq':",`m'*2-1]
	local R = rowsof(`Bsub')
	local value 0
	forv r = 1/`R' {
		if `Bsub'[`r',1]<. {
			local value 1
			continue, break
		}
	}
	c_local value `value'
end

program Add2Vblock
	args block col
	foreach v of local col {
		gettoken row block: block
		local row "`row' `v'"
		local row: list retok row
		local vblock `"`vblock'"`row'" "'
	}
	c_local vblock `"`vblock'"'
end

program VblockCheck
	args block
	foreach row of local block {
		local norow 1
		foreach v of local row {
			if index("`v'",".")!=1 {
				local norow 0
				continue, break
			}
		}
		if !`norow' {
			local vblock `"`vblock'"`row'" "'
		}
	}
	local vblock: list retok vblock
	c_local vblock `"`vblock'"'
end

program CountNofEqs
	args ms es
	local m0 0
	local e0 0
	local i 0
	local eqs 0
	foreach m of local ms {
		local ++i
		local e: word `i' of `es'
		if `m'!=`m0' | `e'!=`e0' {
			local ++eqs
		}
		local m0 `m'
		local e0 `e'
	}
	c_local value `eqs'
end


program InsertAtVariables
	args value type span M E width hline rtf rtfrowdefbrdrt rtfrowdefbrdrb rtfemptyrow title discrete starlegend
	if `type'==1 local atvars span
	else {
		local atvars span M E width hline
		if `rtf' local atvars `atvars' rtfrowdefbrdrt rtfrowdefbrdrb rtfemptyrow
		if `type'!=2  local atvars `atvars' title discrete starlegend
	}
	foreach atvar of local atvars {
		capt local value: subinstr local value "@`atvar'" `"`macval(`atvar')'"', all
		 // note: returns error if length of <to> is more than 502 characters
	}
	c_local value `"`macval(value)'"'
end

program Abbrev
	args width value abbrev
	if "`abbrev'"!="" {
		if `width'>32 {
			local value = substr(`"`macval(value)'"',1,`width')
		}
		else if `width'>0 {
			local value = abbrev(`"`macval(value)'"',`width')
		}
	}
	c_local value `"`macval(value)'"'
end

program MgroupsPattern
	args mrow pattern
	local i 0
	local m0 0
	local j 0
	foreach m of local mrow {
		if `m'!=`m0' {
			local p: word `++i' of `pattern'
			if `i'==1 local p 1
			if "`p'"=="1" local j = `j' + 1
		}
	local newpattern `newpattern' `j'
	local m0 `m'
	}
	c_local mgroupspattern `newpattern'
end

program WriteCaption
	args file delimiter stardetach row rowtwo labels starsrow span  ///
	 abbrev colwidth colfmt delwidth starwidth repeat prefix suffix
	local c 0
	local nspan 0
	local c0 2
	local spanwidth -`delwidth'
	local spanfmt
	foreach r of local row {
		local rtwo: word `++c' of `rowtwo'
		if "`r'"=="." {
			local ++c0
			file write `file' `macval(delimiter)' `colfmt' (`""')
		}
		else if `"`span'"'=="" {
			if ( "`r'"!="`lastr'" | "`rtwo'"!="`lastrtwo'" | `"`rowtwo'"'=="" ) {
				local value: word `r' of `macval(labels)'
				Abbrev `colwidth' `"`macval(value)'"' "`abbrev'"
				local value `"`macval(prefix)'`macval(value)'`macval(suffix)'"'
				InsertAtVariables `"`macval(value)'"' 1 "1"
			}
			else local value
			file write `file' `macval(delimiter)' `colfmt' (`"`macval(value)'"')
			if `:word `c' of `starsrow''==1 {
				file write `file' `macval(stardetach)' _skip(`starwidth')
			}
			local lastr "`r'"
			local lastrtwo "`rtwo'"
		}
		else {
			local ++nspan
			local spanwidth=`spanwidth'+`colwidth'+`delwidth'
			if `:word `c' of `starsrow''==1 {
				local spanwidth = `spanwidth' + `starwidth'
				if `"`macval(stardetach)'"'!="" {
					local ++nspan
					local spanwidth = `spanwidth' + `delwidth'
				}
			}
			local nextrtwo: word `=`c'+1' of `rowtwo'
			local nextr: word `=`c'+1' of `row'
			if "`r'"!="." & ///
			 ("`r'"!="`nextr'" | "`rtwo'"!="`nextrtwo'" | `"`rowtwo'"'=="") {
				local value: word `r' of `macval(labels)'
				Abbrev `spanwidth' `"`macval(value)'"' "`abbrev'"
				local value `"`macval(prefix)'`macval(value)'`macval(suffix)'"'
				InsertAtVariables `"`macval(value)'"' 1 "`nspan'"
				if `spanwidth'>0 local spanfmt "%-`spanwidth's"
				file write `file' `macval(delimiter)' `spanfmt' (`"`macval(value)'"')
				InsertAtVariables `"`macval(repeat)'"' 1 "`c0'-`=`c0'+`nspan'-1'"
				local repeatlist `"`macval(repeatlist)'`macval(value)'"'
				local c0 = `c0' + `nspan'
				local nspan 0
				local spanwidth -`delwidth'
			}
		}
	}
	c_local value `"`macval(repeatlist)'"'
end

program WriteBegin
	args file pre begin post
	foreach line of local pre {
		file write `file' `newline' `"`macval(line)'"'
		local newline _n
	}
	file write `file' `macval(begin)' `macval(post)'
end

program WriteEnd
	args file end post post2
	file write `file' `macval(end)'
	foreach line of local post {
		file write `file' `newline' `"`macval(line)'"'
		local newline _n
	}
	file write `file' `"`macval(post2)'"' _n
end

program WriteEqrow
	args file delimiter stardetach value row span vwidth fmt_v ///
	 abbrev mwidth fmt_m delwidth starwidth prefix suffix
	local nspan 1
	local spanwidth `vwidth'
	local spanfmt
	if `"`span'"'=="" {
		Abbrev `vwidth' `"`macval(value)'"' "`abbrev'"
		local value `"`macval(prefix)'`macval(value)'`macval(suffix)'"'
		InsertAtVariables `"`macval(value)'"' 1 "1"
		file write `file' `fmt_v' (`"`macval(value)'"')
		foreach r of local row {
			file write `file' `macval(delimiter)' `fmt_m' ("")
			if `r'==1 {
				file write `file' `macval(stardetach)' _skip(`starwidth')
			}
		}
	}
	else {
		foreach r of local row {
			local ++nspan
			local spanwidth = `spanwidth' + `mwidth' + `delwidth'
			if `r'==1 {
				local spanwidth = `spanwidth' + `starwidth'
				if `"`macval(stardetach)'"'!="" {
					local ++nspan
					local spanwidth = `spanwidth' + `delwidth'
				}
			}
		}
		Abbrev `spanwidth' `"`macval(value)'"' "`abbrev'"
		local value `"`macval(prefix)'`macval(value)'`macval(suffix)'"'
		InsertAtVariables `"`macval(value)'"' 1 "`nspan'"
		if `spanwidth'>0 local spanfmt "%-`spanwidth's"
		file write `file' `spanfmt' (`"`macval(value)'"')
	}
end

prog WriteStrRow
	args file mrow eqrow neq labels delimiter stardetach starsrow  ///
	 abbrev colwidth colfmt delwidth starwidth
	local c 0
	foreach mnum of local mrow {
		local eqnum: word `++c' of `eqrow'
		if "`mnum'"=="." {
			file write `file' `macval(delimiter)' `colfmt' (`""')
			continue
		}
		if ( "`mnum'"!="`lastmnum'" | "`eqnum'"!="`lasteqnum'" ) {
			local value: word `=(`mnum'-1)*`neq'+`eqnum'' of `macval(labels)'
			Abbrev `colwidth' `"`macval(value)'"' "`abbrev'"
		}
		else local value
		file write `file' `macval(delimiter)' `colfmt' (`"`macval(value)'"')
		if `:word `c' of `starsrow''==1 {
			file write `file' `macval(stardetach)' _skip(`starwidth')
		}
		local lastmnum "`mnum'"
		local lasteqnum "`eqnum'"
	}
end

program VarInList
	args var unstack eqvar eq list
	local value
	local L: word count `macval(list)'
	forv l = 1(2)`L' {
		local lvar: word `l' of `macval(list)'
		local lab: word `=`l'+1' of `macval(list)'
		if "`unstack'"!="" {
			if "`var'"==`"`lvar'"' {
				local value `"`macval(lab)'"'
				continue, break
			}
		}
		else {
			if inlist(`"`lvar'"',"`var'",`"`eqvar'"',`"`eq':"') {
				local value `"`macval(lab)'"'
				continue, break
			}
		}
	}
	c_local value `"`macval(value)'"'
end

program vFormat
	args value fmt lz dmarker msign par
	if substr(`"`fmt'"',1,1)=="a" {
		SignificantDigits `fmt' `value'
	}
	else {
		capt confirm integer number `fmt'
		if !_rc {
			local fmt %`=`fmt'+9'.`fmt'f
		}
	}
	local value: di `fmt' `value'
	local value: list retok value
	if "`lz'"=="" {
		if index("`value'","0.")==1 | index("`value'","-0.") {
			local value: subinstr local value "0." "."
		}
	}
	if `"`macval(dmarker)'"'!="" {
		if "`: set dp'"=="comma" local dp ,
		else local dp .
		local val: subinstr local value "`dp'" `"`macval(dmarker)'"'
	}
	else local val `"`value'"'
	if `"`msign'"'!="" {
		if index("`value'","-")==1 {
			local val: subinstr local val "-" `"`macval(msign)'"'
		}
	}
	if `"`par'"'!="" {
		tokenize `"`macval(par)'"'
		local val `"`macval(1)'`macval(val)'`macval(2)'"'
	}
	c_local value `"`macval(val)'"'
end

program SignificantDigits // idea stolen from outreg2.ado
	args fmt value
	local d = substr("`fmt'", 2, .)
	capt confirm integer number `d'
	if _rc {
		di as err `"`fmt' not allowed"'
		exit 198
	}
// missing: format does not matter
	if `value'>=. local fmt "%9.0g"
// integer: print no decimal places
	else if (`value'-int(`value'))==0 {
		local fmt "%12.0f"
	}
// value in (-1,1): display up to 9 decimal places with d significant
// digits, then switch to e-format with d-1 decimal places
	else if abs(`value')<1 {
		local right = -int(log10(abs(`value'-int(`value')))) // zeros after dp
		local dec = max(1,`d' + `right')
		if `dec'<=9 {
			local fmt "%12.`dec'f"
		}
		else {
			local fmt "%12.`=min(9,`d'-1)'e"
		}
	}
// |values|>=1: display d+1 significant digits or more with at least one
// decimal place and up to nine digits before the decimal point, then
// switch to e-format
	else {
		local left = int(log10(abs(`value'))+1) // digits before dp
		if `left'<=9 {
			local fmt "%12.`=max(1,`d' - `left' + 1)'f"
		}
		else {
			local fmt "%12.0e" // alternatively: "%12.`=min(9,`d'-1)'e"
		}
	}
	c_local fmt "`fmt'"
end

program Stars
	args starlevels P
	if inrange(`P',0,1) {
		local nstar: word count `macval(starlevels)'
		forv i=1(2)`nstar' {
			local istarsym: word `i' of `macval(starlevels)'
			local istar: word `=`i'+1' of `macval(starlevels)'
			if `istar'<=`P' continue, break
			local value "`macval(istarsym)'"
		}
	}
	c_local value `"`macval(value)'"'
end

program CellStars
	args starlevels P par
	Stars `"`macval(starlevels)'"' `P'
	if `"`par'"'!="" {
		tokenize `"`macval(par)'"'
		local value `"`macval(1)'`macval(value)'`macval(2)'"'
	}
	c_local value `"`macval(value)'"'
end

prog MakeSign
	args value msign par starlevels P
	if "`P'"!="" {
		local factor = 0
		while 1 {
			gettoken istar starlevels : starlevels
			gettoken istar starlevels : starlevels
			if `"`istar'"'=="" continue, break
			if `P'<`istar' local factor = `factor' + 1
			else if `istar'==1 local factor = 1
		}
	}
	else local factor 1
	if `"`macval(msign)'"'=="" local msign "-"
	if `value'<0 {
		local val: di _dup(`factor') `"`macval(msign)'"'
	}
	else if `value'==0 local val: di _dup(`factor') "0"
	else if `value'>0 & `value'<. local val: di _dup(`factor') "+"
	else local val `value'
	if `"`par'"'!="" {
		tokenize `"`macval(par)'"'
		local val `"`macval(1)'`macval(val)'`macval(2)'"'
	}
	c_local value `"`macval(val)'"'
end

program DropOrKeep, rclass
	args type b spec // type=0: drop; type=1: keep
	tempname res bt
	local R = rowsof(`b')
	forv i=1/`R' {
		local hit 0
		mat `bt' = `b'[`i',1...]
		foreach sp of local spec {
			if rownumb(`bt', `"`sp'"')==1 {
				local hit 1
				continue, break
			}
		}
		if `hit'==`type' mat `res' = nullmat(`res') \ `bt'
	}
	capt ret mat result `res'
end

program Order, rclass
	args b spec
	tempname bt res
	local eqlist: roweq `b', q
	local eqlist: list uniq eqlist
	mat `bt' = `b'
	gettoken spi rest : spec
	while `"`spi'"'!="" {
		gettoken spinext rest : rest
		if !index(`"`spi'"',":") {
			local vars `"`vars'`"`spi'"' "'
			if `"`spinext'"'!="" & !index(`"`spinext'"',":") {
				local spi `"`spinext'"'
				continue
			}
			foreach eq of local eqlist {
				foreach var of local vars {
					local splist `"`splist'`"`eq':`var'"' "'
				}
				local splist `"`splist'`"`eq':"' "' // rest
			}
			local vars
		}
		else local splist `"`spi'"'
		gettoken sp splist : splist
		while `"`sp'"'!="" {
			local isp = rownumb(`bt', "`sp'")
			if `isp' >= . {
				gettoken sp splist : splist
				continue
			}
			while `isp' < . {
				mat `res' = nullmat(`res') \ `bt'[`isp',1...]
				local nb = rowsof(`bt')
				if `nb' == 1 { // no rows left in `bt'
					capt ret mat result `res'
					exit
				}
				if `isp' == 1 {
					mat `bt' = `bt'[2...,1...]
				}
				else if `isp' == `nb' {
					mat `bt' = `bt'[1..`=`nb'-1',1...]
				}
				else {
					mat `bt' = `bt'[1..`=`isp'-1',1...] \ `bt'[`=`isp'+1'...,1...]
				}
				local isp = rownumb(`bt', "`sp'")
			}
			gettoken sp splist : splist
		}
		local spi `"`spinext'"'
	}
	capt mat `res' = nullmat(`res') \ `bt'
	capt ret mat result `res'
end

prog MakeQuotedFullnames
	args names eqs
	foreach name of local names {
		gettoken eq eqs : eqs
		local value `"`value'`"`eq':`name'"' "'
	}
	c_local value: list clean value
end

prog EqReplaceCons
	args names eqlist eqlabels
	local deqs: list dups eqlist
	local deqs: list uniq deqs
	local i 0
	foreach eq of local eqlist {
		local ++i
		if `"`eq'"'!=`"`last'"' {
			gettoken eqlab eqlabels : eqlabels
		}
		local last `"`eq'"'
		if `:list eq in deqs' continue
		local name: word `i' of `names'
		if `"`name'"'=="_cons" & `"`eq'"'!="_" {
			local value `"`value'`space'`"`eq':`name'"' `"`eqlab'"'"'
			local space " "
		}
	}
	c_local value `"`value'"'
end

prog UniqEqsAndDims
	local n 0
	foreach el of local 1 {
		if `"`macval(el)'"'!=`"`macval(last)'"' {
			if `n'>0 local eqsdims "`eqsdims' `n'"
			local eqs `"`macval(eqs)' `"`macval(el)'"'"'
			local n 0
		}
		local ++n
		local last `"`macval(el)'"'
	}
	local eqsdims "`eqsdims' `n'"
	c_local eqsdims: list clean eqsdims
	c_local eqs: list clean eqs
end

prog InsertAtCols
	args colnums row symb
	if `"`symb'"'=="" local symb .
	gettoken c rest : colnums
	local i 0
	foreach r of local row {
		local ++i
		while `"`c'"'!="" {
			if `c'<=`i' {
				local value `"`value' `symb'"'
				gettoken c rest : rest
			}
			else continue, break
		}
		local value `"`value' `"`r'"'"'
	}
	while `"`c'"'!="" {
		local value `"`value' `symb'"'
		gettoken c rest : rest
	}
	c_local value: list clean value
end

prog GetVarnamesFromOrder
	foreach sp of local 1 {
		if index(`"`sp'"', ":") {
			gettoken trash sp: sp, parse(:)
			if `"`trash'"'!=":" {
				gettoken trash sp: sp, parse(:)
			}
		}
		local value `"`value'`space'`sp'"'
		local space " "
	}
	c_local value `"`value'"'
end

prog ParseIndicateOpts
	syntax [anything(equalok)] [, Labels(str asis) ]
	gettoken tok rest : anything, parse(" =")
	while `"`macval(tok)'"'!="" {
		if `"`macval(tok)'"'=="=" {
			local anything `"`"`macval(anything)'"'"'
			continue, break
		}
		gettoken tok rest : rest, parse(" =")
	}
	c_local indicate `"`macval(anything)'"'
	c_local indicatelabels `"`macval(labels)'"'
end

prog ProcessIndicateGrp
	args i B unstack yesno indicate
	tokenize `"`macval(yesno)'"'
	local yes `"`macval(1)'"'
	local no `"`macval(2)'"'
	gettoken tok rest : indicate, parse(=)
	while `"`macval(tok)'"'!="" {
		if `"`macval(rest)'"'=="" {
			local vars `"`indicate'"'
			continue, break
		}
		if `"`macval(tok)'"'=="=" {
			local vars `"`rest'"'
			continue, break
		}
		local name `"`macval(name)'`space'`macval(tok)'"'
		local space " "
		gettoken tok rest : rest, parse(=)
	}
	if `"`macval(name)'"'=="" {
		local name: word 1 of `"`vars'"'
	}
	ExpandEqVarlist `"`vars'"' `B'
	local evars `"`value'"'
	IsInModels `B' "`unstack'" `"`macval(yes)'"' `"`macval(no)'"' `"`evars'"'
	local lbls `"`macval(value)'"'
	DropOrKeep 0 `B' `"`evars'"'
	capt confirm matrix r(result)
	if _rc {
		di as err "all coefficients dropped"
		exit 498
	}
	mat `B' = r(result)
	c_local indicate_`i'_name `"`macval(name)'"'
	c_local indicate_`i'_lbls `"`macval(lbls)'"'
	c_local indicate_`i'_eqs `"`eqs'"'
end

prog IsInModels
	args B unstack yes no vars
	local models: coleq `B', q
	local models: list uniq models
	local eqs: roweq `B', q
	local eqs: list uniq eqs
	tempname Bt Btt Bttt
	foreach model of local models {
		local stop 0
		mat `Bt' = `B'[1...,"`model':"]
		foreach eq of local eqs {
			mat `Btt' = `Bt'[`"`eq':"',1]
			if `"`unstack'"'!="" local stop 0
			foreach var of local vars {
				if !index(`"`var'"',":") {
					local var `"`eq':`var'"'
				}
				capt mat `Bttt' = `Btt'["`var'",1]
				if _rc continue
				forv i = 1/`= rowsof(`Bttt')' {
					if `Bttt'[`i',1]<.z {
						local lbls `"`macval(lbls)' `"`macval(yes)'"'"'
						local stop 1
						continue, break
					}
				}
				if `stop' continue, break
			}
			if `"`unstack'"'!="" {
				if `stop'==0 {
					local lbls `"`macval(lbls)' `"`macval(no)'"'"'
				}
			}
			else if `stop' continue, break
		}
		if `"`unstack'"'=="" & `stop'==0 {
			local lbls `"`macval(lbls)' `"`macval(no)'"'"'
		}
	}
	c_local value `"`macval(lbls)'"'
	if `"`unstack'"'!="" {
		c_local eqs `"`eqs'"'
	}
end

prog ReorderEqsInIndicate
	args nmodels eqs ieqs lbls
	local neq: list sizeof ieqs
	foreach eq of local eqs {
		local i: list posof `"`eq'"' in ieqs
		if `i' {
			local pos `pos' `i'
		}
	}
	forv m=1/`nmodels' {
		foreach i of local pos {
			local mi = (`m'-1)*`neq' + `i'
			local lbl: word `mi' of `macval(lbls)'
			local value `"`macval(value)'`"`macval(lbl)'"' "'
		}
	}
	c_local value `"`macval(value)'"'
end

prog ParseRefcatOpts
	syntax [anything(equalok)] [, Label(str) Below ]
	c_local refcatbelow "`below'"
	c_local refcatlabel `"`macval(label)'"'
	c_local refcat `"`macval(anything)'"'
end

prog PrepareRefcat
	gettoken coef rest : 1
	gettoken name rest : rest
	while `"`macval(coef)'"'!="" {
		local coefs `"`coefs'`coef' "'
		local names `"`macval(names)'`"`macval(name)'"' "'
		gettoken coef rest : rest
		gettoken name rest : rest
	}
	c_local refcatcoefs `"`coefs'"'
	c_local refcatnames `"`macval(names)'"'
end

prog GenerateRefcatRow
	args B var eqs label
	local models: coleq `B', q
	local models: list uniq models
	local col -1
	foreach model of local models {
		local col = `col'+2
		foreach eq of local eqs {
			local eqvar `"`eq':`var'"'
			local row = rownumb(`B',"`eqvar'")
			if `B'[`row', `col']<. {
				local value `"`macval(value)'`"`macval(label)'"' "'
			}
			else {
				local value `"`macval(value)'`""' "'
			}
		}
	}
	c_local value `"`macval(value)'"'
end

prog ParseTransformSubopts
	syntax anything(equalok) [, Pattern(string) ]
	c_local transform `"`anything'"'
	c_local transformpattern "`pattern'"
end

prog MakeTransformList
	args B transform
	local R = rowsof(`B')
	if `:list sizeof transform'<=2 {
		gettoken f rest : transform
		gettoken df : rest
		forv i = 1/`R' {
			local valuef `"`valuef'`f' "'
			local valuedf `"`valuedf'`df' "'
		}
		c_local valuef: list retok valuef
		c_local valuedf: list retok valuedf
		exit
	}
	gettoken coef rest : transform
	gettoken f rest : rest
	gettoken df rest : rest
	while (`"`coef'"'!="") {
		if (`"`df'`rest'"'!="") { // last element of list may be without coef
			ExpandEqVarlist `"`coef'"' `B'
			local coef `"`value'"'
		}
		local coefs `"`coefs'`"`coef'"' "'
		local fs `"`fs'`"`f'"' "'
		local dfs `"`dfs'`"`df'"' "'
		gettoken coef rest : rest
		gettoken f rest : rest
		gettoken df rest : rest
	}
	tempname b
	local value
	forv i = 1/`R' {
		mat `b' = `B'[`i',1...]
		local i 0
		local hit 0
		foreach coef of local coefs {
			local f: word `++i' of `fs'
			local df: word `i' of `dfs'
			if (`"`df'`rest'"'=="") {
				local valuef `"`valuef'`"`coef'"' "'  // sic! (see above)
				local valuedf `"`valuedf'`"`f'"' "'
				local hit 1
				continue, break
			}
			foreach c of local coef {
				if rownumb(`b', `"`c'"')==1 {
					local valuef `"`valuef'`"`f'"' "'
					local valuedf `"`valuedf'`"`df'"' "'
					local hit 1
					continue, break
				}
			}
			if `hit' continue, break
		}
		if `hit'==0 {
			local valuef `"`valuef'"" "'
			local valuedf `"`valuedf'"" "'
		}
	}
	c_local valuef: list retok valuef
	c_local valuedf: list retok valuedf
end

prog TableIsAMess
	local eq: roweq r(coef), q
	local eq: list uniq eq
	if `: list sizeof eq'<=1 {
		c_local value 0
		exit
	}
	tempname b bt
	mat `b' = r(coef)
	gettoken eq : eq
	mat `b' = `b'[`"`eq':"', 1...]
	local R = rowsof(`b')
	local models: coleq `b', q
	local models: list uniq models
	local value 0
	local i -1
	foreach model of local models {
		local i = `i'+2
		if `i'==1 continue // skip first model
		mat `bt' = `b'[1...,`i']
		local allz 1
		forv r = 1/`R' {
			if `bt'[`r',1]<.z {
				local allz 0
				continue, break
			}
		}
		if `allz' {
			local value 1
			continue, break
		}
	}
	c_local value `value'
end

prog ExpandEqVarlist
	args list B
	ParseEqVarlistRelax `list'
	local coefs: rownames `B'
	local ucoefs: list uniq coefs
	local eqs: roweq `B', q
	local ueqs: list uniq eqs
	while `"`list'"'!="" {
// get next element
		gettoken eqx list : list
// separate eq and x
		gettoken eq x : eqx, parse(:)
		local eq: list clean eq
		if `"`eq'"'==":" {    // case 1: ":[varname]"
			local eq
		}
		else if `"`x'"'=="" { // case 2: "varname"
			local x `"`eq'"'
			local eq
		}
		else {                // case 3. "eqname:[varname]"
			gettoken colon x : x, parse(:)
			local x: list clean x
		}
// match equations
		local eqmatch
		if `:list eq in ueqs' { // (note: evaluates to 1 if eq empty)
			local eqmatch `"`eq'"'
		}
		else {
			foreach e of local ueqs {
				if match(`"`e'"', `"`eq'"') {
					local eqmatch `"`eqmatch' `"`e'"'"'
				}
			}
			if `"`eqmatch'"'=="" & "`relax'"=="" {
				di as err `"equation `eq' not found"'
				exit 111
			}
			local eqmatch: list clean eqmatch
		}
		if `"`x'"'=="" {
			foreach e of local eqmatch {
				local value `"`value' `"`e':"'"'
			}
			continue
		}
// match coefficients
		local vlist
// - without equation
		if `"`eq'"'=="" {
			if `:list x in ucoefs' {
				local value `"`value' `"`x'"'"'
				continue
			}
			foreach coef of local ucoefs {
				if match(`"`coef'"', `"`x'"') {
					local vlist `"`vlist' `"`coef'"'"'
				}
			}
			if `"`vlist'"'=="" {
				if "`relax'"=="" {
					di as err `"coefficient `x' not found"'
					exit 111
				}
			}
			else {
				local value `"`value' `vlist'"'
			}
			continue
		}
// - within equations
		local rest `"`eqs'"'
		foreach coef of local coefs {
			gettoken e rest : rest
			if !`:list e in eqmatch' {
				continue
			}
			if match(`"`coef'"', `"`x'"') {
				local vlist `"`vlist' `"`e':`coef'"'"'
			}
		}
		if `"`vlist'"'=="" {
			if "`relax'"=="" {
				di as err `"coefficient `eq':`x' not found"'
				exit 111
			}
		}
		else {
			local value `"`value' `vlist'"'
		}
	}
	c_local value: list clean value
end

program ParseEqVarlistRelax
	syntax [anything] [, Relax ]
	c_local list `"`anything'"'
	c_local relax `relax'
end

program IsInString
	args needle haystack
	local trash: subinstr local haystack `"`needle'"' "", count(local count)
	c_local value `count'
end

program MakeRtfRowdefs
	args str srow sdetach vwidth mwidth
	local factor 120
	ParseRtfcmdNum `"`str'"' "trgaph" 0
	ParseRtfcmdNum `"`str'"' "trleft" 0
	if `vwidth'<=0 local vwidth 12
	if `mwidth'<=0 local mwidth 12
	if real(`"`trgaph'"')>=. local trgaph 0
	if real(`"`trleft'"')>=. local trleft 0
	local swidth = 3
	local vtwips = `vwidth'*`factor'
	local mtwips = `mwidth'*`factor'
	local stwips = `swidth'*`factor'
	local ipos = `vtwips' + 2*`trgaph' + (`trleft')
	local brdrt "\clbrdrt\brdrw10\brdrs"
	local brdrb "\clbrdrb\brdrw10\brdrs"
	local emptycell "\cell" //"\pard\intbl\cell"
	local rtfdef "\cellx`ipos'"
	local rtfdefbrdrt "`brdrt'\cellx`ipos'"
	local rtfdefbrdrb "`brdrb'\cellx`ipos'"
	local rtfrow "`emptycell'"
	foreach i of local srow {
		local ipos = `ipos' + `mtwips' + 2*`trgaph'
		if `i' & "`sdetach'"=="" local ipos = `ipos' + `stwips'
		local rtfdef "`rtfdef'\cellx`ipos'"
		local rtfdefbrdrt "`rtfdefbrdrt'`brdrt'\cellx`ipos'"
		local rtfdefbrdrb "`rtfdefbrdrb'`brdrb'\cellx`ipos'"
		local rtfrow "`rtfrow'`emptycell'"
		if `i' & "`sdetach'"!="" {
			local ipos = `ipos' + `stwips' + 2*`trgaph'
			local rtfdef "`rtfdef'\cellx`ipos'"
			local rtfdefbrdrt "`rtfdefbrdrt'`brdrt'\cellx`ipos'"
			local rtfdefbrdrb "`rtfdefbrdrb'`brdrb'\cellx`ipos'"
			local rtfrow "`rtfrow'`emptycell'"
		}
	}
	c_local rtfrowdef "`rtfdef'"
	c_local rtfrowdefbrdrt "`rtfdefbrdrt'"
	c_local rtfrowdefbrdrb "`rtfdefbrdrb'"
	c_local rtfemptyrow "`rtfdef'`rtfrow'"
end

prog ParseRtfcmdNum
	args str cmd default
	local pos = index(`"`str'"', `"\\`cmd'"')
	if `pos' {
		local pos = `pos' + strlen(`"`cmd'"') + 1
		local digit = substr(`"`str'"',`pos',1)
		if `"`digit'"'=="-" {
			local value "`digit'"
			local digit = substr(`"`str'"',`++pos',1)
		}
		while real(`"`digit'"')<. {
			local value "`value'`digit'"
			local digit = substr(`"`str'"',`++pos',1)
		}
	}
	local value = real(`"`value'"')
	if `value'>=. local value = `default'
	c_local `cmd' `"`value'"'
end
