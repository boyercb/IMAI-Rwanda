capture program drop didtable
program define didtable
    version 13
	syntax [if] [in] [fweight], ///
		treated(varname)		/// treatment variable
		period(varname)         /// time period variable
		vars(string)		    /// varname vartype [varformat], vars delimited by \
		[cluster(varname)]		/// cluster variable
		[ONEcol]			    /// only use 1 column to report categorical vars
		[Format(string)]	    /// default format for contn / conts variables
		[plusminus]			    /// report contn vars as mean ± sd instead of mean (sd)
		[percent]			    /// report categorical vars just as % (no N)
		[MISsing]			    /// don't exclude missing values
		[pdp(integer 3)]	    /// max number of decimal places in p-value
		[SAVing(string asis)]	/// optional Excel file to save output
		[title(string)]         /// title string
		[clear]

	marksample touse

	// table will be stored in temporary file called resultstable
	tempfile resultstable

	// order of rows in table
	local sortorder = 1

	if "`cluster'" != "" {
		local clust cluster(`cluster')
	}

	// treatment variable in numeric format
	tempvar groupnum1
	if "`treated'"=="" {
		gen byte `groupnum1' = 1 // 1 placeholder group
	}
	else {
		capture confirm numeric variable `treated'
		if !_rc qui clonevar `groupnum1'=`treated'
		else qui encode `treated', gen(`groupnum1')
	}

	// period variable in numeric format
	tempvar groupnum2
	if "`period'"=="" {
		gen byte `groupnum2' = 1 // 1 placeholder group
	}
	else {
		capture confirm numeric variable `period'
		if !_rc qui clonevar `groupnum2'=`period'
		else qui encode `period', gen(`groupnum2')
	}

	// determine number of groups and issue error if < 2
	qui levelsof `groupnum1' if `touse', local(levels)
	local groupcount1: word count `levels'
	if `groupcount1'< 2 & "`treated'"!="" {
		di in re "treated() variable must have at least 2 levels"
		error 498
	}

	// determine number of groups and issue error if < 2
	qui levelsof `groupnum2' if `touse', local(levels)
	local groupcount2: word count `levels'
	if `groupcount2'< 2 & "`period'"!="" {
		di in re "period() variable must have at least 2 levels"
		error 498
	}

	if "`treated'" == "" {
		di in re "treated() variable required"
		error 499
	}
	if "`period'" == "" {
		di in re "period() variable required"
		error 499
	}

	tempvar interact
	egen `interact' = group(`period' `treated'), label
	// N
	preserve
	qui keep if `touse'
	qui drop if missing(`treated') | missing(`period')
	contract `interact' [`weight'`exp']
	gen factor = "N"
	gen factor_sep = "N" // for subsequent neat output
	qui gen n=string(_freq)
	qui drop _freq
	qui reshape wide n, i(factor) j(`interact')
	rename n* `interact'*
	gen sort1 = `sortorder++'
	qui save `resultstable', replace
	restore

	// step through the variables
	gettoken arg rest : vars, parse("\")
	while `"`arg'"' != "" {
		if `"`arg'"' != "\" {
			local varname   : word 1 of `arg'
			local vartype   : word 2 of `arg'
			local varformat : word 3 of `arg'

			// check that input is valid
			// does variable exist?
			confirm variable `varname'

			// is vartype supported?
			if !inlist("`vartype'", "cont", "bin") {
				di in re "-`varname' `vartype'- not allowed in vars() option"
				di in re "Variables must be classified as cont or bin"
				error 498
			}

			// obtain variable label, or just varname if variable has no label
			local varlab: variable label `varname'
			if "`varlab'"=="" local varlab `varname'

			// if variable is continuous
			if "`vartype'"=="cont" {
				preserve
				qui keep if `touse'

				did `varname', treated(`treated') period(`period') cluster(`cluster')

				local p0 `r(p0)'
				local p1 `r(p1)'
				local p11 `r(p11)'
				local did `r(did)'
				local control0 `r(control0)'
				local control1 `r(control1)'
				local treat0 `r(treat0)'
				local treat1 `r(treat1)'
				local diff0 `r(diff0)'
				local diff1 `r(diff1)'

				// default format is specified in the format option,
				// or if that's blank, it's just the variable's display format
				if "`varformat'" == "" {
					if "`format'" == "" local varformat: format `varname'
					else local varformat `format'
				}

				// collapse to table format
				collapse (mean) mean = `varname' (sd) sd = `varname' ///
					[`weight'`exp'], by(`interact')
				if "`plusminus'"=="plusminus" {
					qui gen mean_sd=string(mean, "`varformat'") + ///
						" ± " + string(sd, "`varformat'")
				}
				else {
					qui gen mean_sd=string(mean, "`varformat'") + ///
						" (" + string(sd, "`varformat'") + ")"
				}

				if "`plusminus'" == "plusminus" gen factor="`varlab', mean ± SD"
				else gen factor="`varlab', mean (SD)"
				qui clonevar factor_sep=factor
				keep factor* `interact' mean_sd
				qui reshape wide mean_sd, i(factor) j(`interact')
				rename mean_sd* `interact'*

				* add p-values and differences, then save
				if `groupcount1' > 1 {
					qui gen p0 =`p0'
					qui gen p1 =`p1'
					qui gen p11 =`p11'
					qui gen diff0 =`diff0'
					qui gen diff1 =`diff1'
					qui gen did =`did'
				}
				gen sort1 = `sortorder++'
				qui append using `resultstable'
				qui save `resultstable', replace
				restore
			}

			// categorical variable
			if "`vartype'"=="bin" {
				preserve
				qui keep if `touse'
				qui drop if missing(`groupnum1')
				if "`missing'"!="missing" qui drop if missing(`varname')

				* categories should be numeric
				tempvar varnum
				capture confirm numeric variable `varname'
				if !_rc qui clonevar `varnum'=`varname'
				else qui encode `varname', gen(`varnum')


				did `varname', treated(`treated') period(`period') cluster(`cluster')
				noisily di "hi"

				local p0 `r(p0)'
				local p1 `r(p1)'
				local p11 `r(p11)'
				local did `r(did)'
				local control0 `r(control0)'
				local control1 `r(control1)'
				local treat0 `r(treat0)'
				local treat1 `r(treat1)'
				local diff0 `r(diff0)'
				local diff1 `r(diff1)'


				* collapse to table format
				qui contract `varnum' `interact'  [`weight'`exp'], zero
				qui egen tot=total(_freq), by(`interact')

				* default format is 0 decimal places if <100 cases, otherwise 1 dp
				* (for categorical variables, format is for % not the frequency)
				if "`varformat'"=="" {
					sum tot, meanonly
					if r(max)<100 local varformat "%1.0f"
					else local varformat "%2.1f"
				}

				* finish restructuring to table1 format
				qui gen perc=string(100*_freq/tot, "`varformat'")
				qui replace perc="<1" if _freq!=0 & real(perc)==0

				if "`percent'"=="percent" qui gen n_perc=perc + "%"
				else qui gen n_perc=string(_freq) + " (" + perc + "%)"

				drop _freq tot perc
				qui reshape wide n_perc, i(`varnum') j(`interact')
				rename n_perc* `interact'*


				* add factor and level variables, unless onecol option specified
				* in which case just add factor variable (with levels included)
				if "`onecol'"=="" {
					qui gen factor="`varlab'" if _n==1
					qui gen factor_sep="`varlab'" // allows neat sepby
					qui gen level=""
					qui levelsof `varnum', local(levels)
					foreach level of local levels {
						qui replace level="`: label (`varnum') `level''" ///
							if `varnum'==`level'
					}
				}
				else {
					* add new observation to contain name of variable and
					* p-value
					qui set obs `=_N + 1'
					tempvar reorder
					qui gen `reorder'=1 in L
					sort `reorder' `varnum'
					drop `reorder'

					qui gen factor="`varlab'" if _n==1
					qui gen factor_sep="`varlab'" // allows neat sepby
					qui levelsof `varnum', local(levels)
					foreach level of local levels {
						qui replace factor="   `: label (`varnum') `level''" ///
							if `varnum'==`level'
					}
				}

				* add p-values and differences, then save
				if `groupcount1' > 1 {
					qui gen p0 =`p0'
					qui gen p1 =`p1'
					qui gen p11 =`p11'
					qui gen diff0 =`diff0'
					qui gen diff1 =`diff1'
					qui gen did =`did'
				}
				gen sort1=`sortorder++'
				qui gen sort2=_n
				qui drop `varnum'
				qui append using `resultstable'
				qui save `resultstable', replace
				restore
			}
		}
		gettoken arg rest : rest, parse("\")
    }

	// get value labels for group if available
	local vallab: value label `interact'
	if "`vallab'"!="" {
		tempfile labels
		qui label save `vallab' using `labels'
	}

	* levels of group variable, for subsequent labelling
	qui levelsof `interact' if `touse', local(levels)

	* load results table
	preserve
	qui use `resultstable', clear

	* restore value labels if available
	capture do `labels'

	* label each group variable
	foreach level of local levels {
		if "`vallab'"=="" {
			lab var `interact'`level' "`by' = `level'"
		}
		else {
			local lab: label `vallab' `level'
			lab var `interact'`level' "`lab'"
		}
	}

	* label other variables
	lab var factor "Factor"
	capture lab var level "Level"
	capture lab var test "Test"
	if `groupcount1' == 1 lab var `interact'1 "Value"

	* format p-values
	if `groupcount1' > 1 {
		local i = 0
		foreach var in p0 p1 p11 {
			qui gen pvalue`i'=string(`var', "%3.2f") if !missing(`var')
			qui replace pvalue`i'=string(`var', "%`=`pdp'+1'.`pdp'f") if `var' < 0.10
			local pmin=10^-`pdp'
			qui replace pvalue`i' = "<" + string(`pmin', "%`=`pdp'+1'.`pdp'f") if `var' < `pmin'
			lab var pvalue`i' "p-value `i'"
			local i = `i' + 1
		}
	    local i = 0
		foreach var in diff0 diff1 did {
			qui gen dd`i' = string(`var', "%3.2f") if !missing(`var')
			if "`i'" != "2" {
				lab var dd`i' "Diff`i' (T-C)"
			}
			else {
				lab var dd`i' "DD"
			}
			local i = `i' + 1
		}
	}

	* create a row containing variable labels - for nicer output
	qui count
	local newN=r(N) + 1
	qui set obs `newN'
	qui desc, varlist
	foreach var of varlist `r(varlist)' {
		capture replace `var'="`: var lab `var''" in `newN'
	}
	qui replace sort1=0 in `newN'

	* clean up variables in preparation for display
	order factor `interact'*
*	capture order factor `by'* pvalue // won't have p-value if no group var
	capture order dd*, after(pvalue*) // won't have test if no group var
	capture order test, after(dd*) // won't have test if no group var
	capture order level, after(factor) // won't have level if no cat vars

	* sort rows and drop unneeded variables
	sort sort*
	drop sort*
	qui capture drop p0 p1 p11 diff0 diff1 did

	* left-justify the strings apart from p-value
	qui desc, varlist
	foreach var in `r(varlist)' {
		format `var' %-`=substr("`: format `var''", 2, .)'
	}
	capture format %`=`pdp'+3's pvalue

	* rename placeholder group variable if by() option not used
	* otherwise rename group variables using the specified group var (only
	*   important if using the "clear" option)
	if `groupcount1' == 1 rename `interact'1 value
	*else rename `groupnum1'* `by'*

	* finally, display the table itself
	qui ds factor_sep, not
	list `r(varlist)', sepby(factor_sep) noobs noheader table
	drop factor_sep

	* if -saving- was specified then we'll save the table as an Excel spreadsheet
	if `"`saving'"'!="" export excel using `saving', `replace'

	* restore original data unless told not to
	if "`clear'"=="clear" restore, not
	else restore
end
