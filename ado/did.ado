capture program drop did
program define did, rclass
	version 10.0
	syntax varlist(min = 1) [in] [if] [fweight], ///
		Treated(string)			/// treatment variable
		Period(string)          /// time period variable
		[ Cluster(string)		/// cluster variable
		  robust			    /// use robust standard errors
		  LOgit					/// model response using logistic regression
		  export				/// export results to csv
		  NOStar ]                

	// initialize variables
	marksample touse
	tokenize `varlist'
	tempvar output
	qui: gen `output' = `1'

	
	// warnings
	if "`period'" == "" {
		di as err "Option period() not specified"
		exit 198
	}
	else if "`treated'" == "" {
		di as err "Option treated() not specified"
		exit 198
	}
	// define cluster
	if "`cluster'" != "" {
		local clust cluster(`cluster')
	}
	quietly {
		tempvar interact
		generate `interact' = `period' * `treated'
		
		local slist "fc0 ft0 f0 fc1 ft1 f1 f11 sec0 se0 sec1 set0 set1 se1 se11 tc0 tt0 td0 tc1 tt1 td1 t11 pc0 pt0 p0 pc1 pt1 p1 p11"
		tempname `slist'
		if "`logit'" == "" {
			reg `output' `period' `treated' `interact' `if' `in' [`fweight'], `robust' `clust'
			tempvar samp
			gen `samp' = e(sample)
		}
		else {
			logit `output' `period' `treated' `interact' `if' `in' [`fweight'], `robust' `clust'
			tempvar samp
			gen `samp' = e(sample)
		}

		local time _b[`cf'`period']
		local timetr _b[`cf'`interact']
		if "`logit'" == "" {
			// calculate probabilities
			local control0 _b[`cc'_cons]
			local treat0 (_b[`cc'_cons]+_b[`cf'`treated'])
			local diff0 _b[`cf'`treated']
			local control1  (_b[`cc'_cons]+`time')
		    local treatment1 (`control0'+`time'+`diff0'+`timetr')
		    local diff1 (`diff0'+`timetr')
			local did = (`diff1' - `diff0')

			local est r(F)
			local inf t
	
			// baseline tests
			test `control0' == 0
			scalar `fc0' = `est'
			scalar `sec0' = abs(`control0') / sqrt(`fc0')
			scalar `tc0' = `control0' / `sec0'
			scalar `pc0' = r(p)

			test `treat0' == 0
			scalar `ft0' = `est'
			scalar `set0' = abs(`treat0') / sqrt(`ft0')
			scalar `tt0' = `treat0' / `set0'
			scalar `pt0' = r(p)

			test `diff0' == 0
			scalar `f0' = `est'
			scalar `se0' = abs(`diff0') / sqrt(`f0')
			scalar `td0' = `diff0' / `se0'
			scalar `p0' = r(p)
			
			// follow up tests
			test `control1' == 0
			scalar `fc1' = `est'
			scalar `sec1' = abs(`control1') / sqrt(`fc1')
			scalar `tc1' = `control1' / `sec1'
			scalar `pc1' = r(p)

			test `treatment1' == 0
			scalar `ft1' = `est'
			scalar `set1' = abs(`treatment1') / sqrt(`ft1')
			scalar `tt1' = `treatment1' / `set1'
			scalar `pt1' = r(p)

			test `diff1' == 0
			scalar `f1' = `est'
			scalar `se1' = abs(`diff1') / sqrt(`f1')
			scalar `td1' = `diff1' / `se1'
			scalar `p1' = r(p)
		
			// diff-in-diff
			test `timetr' == 0
			scalar `f11' = `est'
			scalar `se11' = abs(`timetr') / sqrt(`f11')
			scalar `t11' = `timetr' / `se11'
			scalar `p11' = r(p)
		} 
		else {
			local control0 = 1 / (1 + exp(- _b[`cc'_cons]))
			local treat0 = 1 / (1 + exp(-(_b[`cc'_cons]+_b[`cf'`treated'])))
			local diff0 = `treat0' - `control0'
			local control1 = 1 / (1 + exp(-(_b[`cc'_cons]+`time')))
		    local treatment1 = 1 / (1 + exp(-(_b[`cc'_cons]+_b[`cf'`treated']+`time'+`timetr')))
		    local diff1 = (`treatment1'-`control1')
		    local did = (`diff1' - `diff0')

			local est r(chi2)
			local inf t
			
			// baseline tests
			local c0 _b[`cc'_cons]
			test `c0' == 0
			scalar `fc0' = `est'
			scalar `sec0' = abs(`c0') / sqrt(`fc0')
			scalar `tc0' = `c0' / `sec0'
			scalar `pc0' = r(p)
			
			local t0 _b[`cc'_cons] + _b[`cf'`treated']
			test `t0' == 0
			scalar `ft0' = `est'
			scalar `set0' = abs(`t0') / sqrt(`ft0')
			scalar `tt0' = `t0' / `set0'
			scalar `pt0' = r(p)

			local d0 _b[`cf'`treated']
			test `d0' == 0
			scalar `f0' = `est'
			scalar `se0' = abs(`d0') / sqrt(`f0')
			scalar `td0' = `d0' / `se0'
			scalar `p0' = r(p)
			
			// follow up tests
			local c1 _b[`cc'_cons] + _b[`cf'`period']
			test `c1' == 0
			scalar `fc1' = `est'
			scalar `sec1' = abs(`c1') / sqrt(`fc1')
			scalar `tc1' = `c1' / `sec1'
			scalar `pc1' = r(p)

			local t1 _b[`cc'_cons] + _b[`cf'`period'] + _b[`cf'`treated'] + _b[`cf'`interact']
			test `t1' == 0
			scalar `ft1' = `est'
			scalar `set1' = abs(`t1') / sqrt(`ft1')
			scalar `tt1' = `t1' / `set1'
			scalar `pt1' = r(p)

			local d1 _b[`cf'`treated'] + _b[`cf'`interact']
			test `d1'  == 0
			scalar `f1' = `est'
			scalar `se1' = abs(`d1') / sqrt(`f1')
			scalar `td1' = `d1' / `se1'
			scalar `p1' = r(p)
		
			// diff-in-diff
			local dd _b[`cf'`interact']
			test `dd' == 0
			scalar `f11' = `est'
			scalar `se11' = abs(`dd') / sqrt(`f11')
			scalar `t11' = `dd' / `se11'
			scalar `p11' = r(p)
		}
		local df e(df_r)

		// stars p0
		if `p0' < 0.01 & "`nostar'" == "" {
			local starp0 "***"
		}
		else if `p0' >= 0.01 & `p0' < 0.05 & "`nostar'" == "" {
			local starp0 "**"
		}
		else if `p0' >= 0.05 & `p0' < 0.1 & "`nostar'" == "" {
			local starp0 "*"
		}

		// stars p1
		if `p1' < 0.01 & "`nostar'" == "" {
			local starp1 "***"
		}
		else if `p1' >= 0.01 & `p1' < 0.05 & "`nostar'" == "" {
			local starp1 "**"
		}
		else if `p1' >= 0.05 & `p1' < 0.1 & "`nostar'" == "" {
			local starp1 "*"
		}

		// stars p11
		if `p11' < 0.01 & "`nostar'" == "" {
			local starp11 "***"
		}
		else if `p11' >= 0.01 & `p11' < 0.05 & "`nostar'" == "" {
			local starp11 "**"
		}
		else if `p11' >= 0.05 & `p11' < 0.1 & "`nostar'" == "" {
			local starp11 "*"
		}

	}

	// display tables
	local r2 = 1 - (e(sum_adev)/e(sum_rdev))
	tempname totobs
	qui: summ `samp' if `samp'
	scalar `totobs' = r(N)
	tempname blo0
	qui: summ `samp' if `period' == 0 & `treated' == 0 & `samp'
	scalar `blo0' = r(N)
	tempname blo1
	qui: summ `samp' if `period' == 0 & `treated' == 1 & `samp'
	scalar `blo1' = r(N)
	tempname flo0
	qui: summ `samp' if `period' == 1 & `treated' == 0 & `samp'
	scalar `flo0' = r(N)
	tempname flo1
	qui: summ `samp' if `period' == 1 & `treated' == 1 & `samp'
	scalar `flo1' = r(N)
	return clear

	di in smcl in gr _n "{title:DIFFERENCE-IN-DIFFERENCES ESTIMATION RESULTS}"
	di in gr "{p}Number of observations in the DIFF-IN-DIFF:" in ye " " `totobs' "{p_end}"
	di in gr "            Baseline       Follow-up"
	di in gr "   Control:" in ye _col(13) `blo0' _col(28) `flo0' in gr _col(40) `flo0' + `blo0'
	di in gr "   Treated:" in ye _col(13) `blo1' _col(28) `flo1' in gr _col(40) `flo1' + `blo1'
	di _col(13) `blo0' + `blo1' in gr _col(28) `flo0' + `flo1'

	// output
	#delimit ;
	di in gr "{hline 54}" _n
	" Outcome var.   {c |} " in ye  abbrev("`1'",12) _col(27) in gr "{c |} S. Err. {c |}   t   {c |}"/*;
	*/"  P>|t|"_n

	"{hline 16}{c +}{hline 9}{c +}{hline 9}{c +}{hline 7}{c +}"/*;
	*/"{hline 9}"_n

	in gr "Baseline"
	_col(17) in gr "{c |} "
	_col(27) in gr "{c |} "
	_col(37) in gr "{c |} "
	_col(45) in gr "{c |} " _n
	in gr "   Control"
	_col(17) in gr "{c |} " in wh %5.3f `control0'
	_col(27) in gr "{c |} " in wh %4.3f `'
	_col(37) in gr "{c |} " in wh %4.2f `'
	_col(45) in gr "{c |} " in wh %4.3f `' _n
	in gr "   Treated"
	_col(17) in gr "{c |} " in wh %5.3f `treat0'
	_col(27) in gr "{c |} " in wh %4.3f `'
	_col(37) in gr "{c |} " in wh %4.2f `'
	_col(45) in gr "{c |} " in wh %4.3f `' _n
	in gr "   Diff (T-C)"
	_col(17) in gr "{c |} " in ye %5.3f `diff0'
	_col(27) in gr "{c |} " in ye %4.3f `se0'
	_col(37) in gr "{c |} " in ye %4.2f `td0'
	_col(45) in gr "{c |} " in ye %4.3f `p0' "`starp0'" _n

	in gr "Follow-up"
	_col(17) in gr "{c |} "
	_col(27) in gr "{c |} "
	_col(37) in gr "{c |} "
	_col(45) in gr "{c |} " _n
	in gr "   Control"
	_col(17) in gr "{c |} " in wh %5.3f `control1'
	_col(27) in gr "{c |} " in wh %4.3f `'
	_col(37) in gr "{c |} " in wh %4.2f `'
	_col(45) in gr "{c |} " in wh %4.3f `' _n
	in gr "   Treated"
	_col(17) in gr "{c |} " in wh %5.3f `treatment1'
	_col(27) in gr "{c |} " in wh %4.3f `'
	_col(37) in gr "{c |} " in wh %4.2f `'
	_col(45) in gr "{c |} " in wh %4.3f `' _n
	in gr "   Diff (T-C)"
	_col(17) in gr "{c |} " in ye %5.3f `diff1'
	_col(27) in gr "{c |} " in ye %4.3f `se1'
	_col(37) in gr "{c |} " in ye %4.2f `td1'
	_col(45) in gr "{c |} " in ye %4.3f `p1' "`starp1'" _n

	_col(17) in gr "{c |} "
	_col(27) in gr "{c |} "
	_col(37) in gr "{c |} "
	_col(45) in gr "{c |} " _n

	in gr "Diff-in-Diff"
	_col(17) in gr "{c |} " in ye %5.3f `did'
	_col(27) in gr "{c |} " in ye %4.3f `se11'
	_col(37) in gr "{c |} " in ye %4.2f `t11'
	_col(45) in gr "{c |} " in ye %4.3f `p11' "`starp11'"  _n

	in gr "{hline 54}"
	;
	di in gr "R-square:" in ye %8.2f `r2';
	#delimit cr

	// notes
	if "`logit'" == "" {
		di in gr "* Means and Standard Errors are estimated by linear regression"
	}
	else {
		di in gr "* Means and Standard Errors are estimated by logistic regression"
	}
	if "`robust'" != "" {
		di in gr "**Robust Std. Errors"
	}
	if "`cluster'" != "" {
		di in gr "**Clustered Std. Errors"
	}
	if "`nostar'" == "" {
		di in gr "**Inference: *** p<0.01; ** p<0.05; * p<0.1"
	}

	// export
	if "`export'" != "" {
		preserve
		clear
		qui: set obs 4
		qui: gen str Outcome = "`1'" 			in 1
		qui: replace Outcome = "Std. Error" 	in 2
		qui: replace Outcome = "t" 				in 3
		qui: replace Outcome = "P>|t|" 			in 4

		qui: gen float ControlBL = `control0' 	in 1
		qui: replace ControlBL = `sec0'			in 2
		qui: replace ControlBL = `tc0' 			in 3
		qui: replace ControlBL = `pc0' 			in 4

		qui: gen float TreatedBL = `treat0' 	in 1
		qui: replace TreatedBL = `set0'			in 2
		qui: replace TreatedBL = `tt0' 			in 3
		qui: replace TreatedBL = `pt0' 			in 4

		qui: gen float DifferenceBL = `diff0'	in 1
		qui: replace DifferenceBL = `se0'		in 2
		qui: replace DifferenceBL = `td0' 		in 3
		qui: replace DifferenceBL = `p0' 		in 4

		qui: gen float ControlFU = `control1' 	in 1
		qui: replace ControlFU = `sec1'			in 2
		qui: replace ControlFU = `tc1' 			in 3
		qui: replace ControlFU = `pc1' 			in 4

		qui: gen float TreatedFU = `treatment1' 	in 1
		qui: replace TreatedFU = `set1'			in 2
		qui: replace TreatedFU = `tt1' 			in 3
		qui: replace TreatedFU = `pt1' 			in 4

		qui: gen float DifferenceFU = `diff1'	in 1
		qui: replace DifferenceFU = `se1'		in 2
		qui: replace DifferenceFU = `td1' 		in 3
		qui: replace DifferenceFU = `p1' 		in 4

		qui: gen float DID = `timetr'			in 1
		qui: replace DID = `se11'				in 2
		qui: replace DID = `t11' 				in 3
		qui: replace DID = `p11' 				in 4

		qui: outsheet using "`export'.csv", comma replace
		restore
	}

	// saved results
	return scalar mean_c0 = `control0'
	return scalar mean_t0 = `treat0'
	return scalar diff0 = `diff0'
	return scalar mean_c1 = `control1'
	return scalar mean_t1 = `treatment1'
	return scalar diff1 = `diff1'
	return scalar did = `did'
	return scalar p0 = `p0'
	return scalar p1 = `p1'
	return scalar p11 = `p11'
	return scalar se_c0 = `sec0'
	return scalar se_t0 = `set0'
	return scalar se_d0 = `se0'
	return scalar se_c1 = `sec1'
	return scalar se_t1 = `set1'
	return scalar se_d1 = `se1'
	return scalar se_dd = `se11'

end
