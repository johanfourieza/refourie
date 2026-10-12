* P23_MBF S6: wild cluster score bootstrap on frequency-weighted cells (DEVIATIONS D1).
* Replicates boottest 4.5.3's ML score bootstrap (boottest.ado l.583-700; boottest.mata _MakeInterpolables,
* MakeWildWeights, MakeNonWREStats, getp) step by step, with one change: the observation scores are multiplied
* by the row weight before they are summed by cluster. boottest omits this weight for ML models, so on cells it
* would be wrong; on the 5.08M individual rows (weight 1) the two coincide. Exact agreement with boottest on the
* full data is verified in 01b_verify_fulldata.do.
*
* sb_test, rmat(R) r(#) clus(var) fitcmd(logit ... [fw=n], vce(cluster ...) ...) [wvar(var) nonull dist(webb|rademacher) b(#) seed(#)]
*   Requires: the unrestricted fit stored as estimates UNR; data sorted by clus.
*   R is a 1xK matrix in the column order of e(b) (unrestricted fit). Null: R*beta = r.
*   Returns r(p), r(t), r(conv) (1 if the restricted fit converged), r(G) (number of clusters), r(rc).
*   The wild-weight matrix depends only on (G, B, seed, dist) and is cached across calls (identical draws).

* sb_repar_start: constrained MLE of the logit under R*b = r by substitution (unconstrained logit with an offset),
* on the sample and weights of the current estimates (UNR). Writes the full coefficient vector into out().
capture program drop sb_repar_start
program sb_repar_start, rclass
	syntax , rmat(name) r(real) bh(name) out(name)
	local names : colnames `bh'
	local K = colsof(`bh')
	local wt = cond("`e(wtype)'"=="", "", "[`e(wtype)' `e(wexp)']")
	local y = e(depvar)
	tempvar es off
	quietly gen byte `es' = e(sample)
	* regressor columns (free columns only)
	local best = 0
	local jp = 0
	forvalues k = 1/`K' {
		local nm : word `k' of `names'
		local free`k' = !(strpos("`nm'", "o.") | strpos("`nm'", "b."))
		if !`free`k'' continue
		tempvar x`k'
		if "`nm'"=="_cons" quietly gen double `x`k'' = 1
		else if ustrregexm("`nm'", "^([0-9]+)\.(.+)$") {
			local lev = ustrregexs(1)
			local fv = ustrregexs(2)
			quietly gen double `x`k'' = (`fv' == `lev')
		}
		else quietly gen double `x`k'' = `nm'
		if `rmat'[1,`k'] != 0 {
			quietly su `x`k'' if `es'
			local sdk = cond("`nm'"=="_cons", 1, r(sd))
			if `sdk' > 0 & abs(`rmat'[1,`k'])/`sdk' > `best' {
				local best = abs(`rmat'[1,`k'])/`sdk'
				local jp = `k'
			}
		}
	}
	if `jp'==0 {
		return scalar repar = 0
		exit
	}
	local zl ""
	local g0 ""
	forvalues k = 1/`K' {
		if !`free`k'' | `k'==`jp' continue
		tempvar z`k'
		quietly gen double `z`k'' = `x`k'' - (`rmat'[1,`k']/`rmat'[1,`jp'])*`x`jp''
		local zl "`zl' `z`k''"
		local g0 "`g0', `=`bh'[1,`k']'"
	}
	quietly gen double `off' = (`r'/`rmat'[1,`jp'])*`x`jp''
	local g0 = substr("`g0'", 2, .)
	tempname G0 G
	matrix `G0' = (`g0')
	tempname hold
	_estimates hold `hold', copy
	capture quietly logit `y' `zl' `wt' if `es', noconstant offset(`off') from(`G0', copy) iterate(100) tolerance(1e-8) ltolerance(1e-10)
	local ok = !_rc
	if `ok' local ok = e(converged)
	if `ok' {
		matrix `G' = e(b)
		local i = 0
		local sumr = 0
		forvalues k = 1/`K' {
			if !`free`k'' | `k'==`jp' continue
			local ++i
			matrix `out'[1,`k'] = `G'[1,`i']
			local sumr = `sumr' + `rmat'[1,`k']*`G'[1,`i']
		}
		matrix `out'[1,`jp'] = (`r' - `sumr')/`rmat'[1,`jp']
	}
	_estimates unhold `hold'
	return scalar repar = `ok'
end

capture program drop sb_test
program sb_test, rclass
	syntax , Rmat(name) R(real) CLus(varname) FITcmd(string asis) [Wvar(varname) NONULL DIST(string) B(integer 9999) SEED(integer 20261011) RECOVER]
	if "`dist'"=="" local dist webb
	tempname bh btil V VR cn
	tempvar sc z u w
	quietly estimates restore UNR
	matrix `bh' = e(b)
	local conv 1
	local rc 0
	if "`nonull'"=="" {
		* constraint R*b = r, written from R
		local names : colnames `bh'
		local K = colsof(`bh')
		local str ""
		forvalues j = 1/`K' {
			local nm : word `j' of `names'
			if `rmat'[1,`j'] != 0 & !(strpos("`nm'", "o.") | strpos("`nm'", "b.")) {
				local coef = strofreal(`rmat'[1,`j'], "%21.0g")
				if "`str'"!="" local str "`str' +"
				local str "`str' `coef'*[d_primary]`nm'"
			}
		}
		local rr = strofreal(`r', "%21.0g")
		constraint drop 990
		constraint define 990 `str' = `rr'
		* start values for the first attempt (DEVIATIONS D9): the exact solution of the constrained problem obtained by
		* substituting the constraint out (pivot coefficient j with the largest |R_j|/sd(x_j); offset form). Stata's
		* constrained logit started at the infeasible bhat can stall on a saturated plateau although the constrained
		* maximum exists. The refit below is still the card's constrained logit; only its start values change.
		tempname bst
		matrix `bst' = `bh'
		sb_repar_start, rmat(`rmat') r(`r') bh(`bh') out(`bst')
		local repar = r(repar)
		* first attempt capped at 100 iterations (DEVIATIONS D8); Stata's default cap is 16,000
		capture quietly `fitcmd' constraints(990) from(`bst') iterate(100)
		local rc = _rc
		if !`rc' local conv = e(converged)
		if (`rc' | !`conv') & "`recover'"!="" {
			di as txt "sb_test: recovery R1 (difficult iterate(1000) from(bhat))"
			capture quietly `fitcmd' constraints(990) from(`bh') difficult iterate(1000)
			local rc = _rc
			if !`rc' local conv = e(converged)
			return local recovered "R1"
		}
		if `rc' | !`conv' {
			return scalar p = .
			return scalar conv = 0
			return scalar rc = `rc'
			constraint drop 990
			quietly estimates restore UNR
			exit
		}
		matrix `btil' = e(b)
		matrix `cn' = `rmat'*`btil''
		return scalar cnscheck = `cn'[1,1] - `r'
		quietly `fitcmd' from(`btil') iterate(0)
		constraint drop 990
	}
	matrix `V' = e(V_modelbased)
	quietly predict double `sc' if e(sample), score
	matrix `VR' = (`V' * `rmat'')'
	matrix colnames `VR' = `: colfullnames e(b)'
	quietly matrix score double `z' = `VR' if e(sample)
	if "`wvar'"=="" quietly gen double `w' = 1 if e(sample)
	else quietly gen double `w' = `wvar' if e(sample)
	quietly gen double `u' = `w'*`sc'*`z'
	tempname num0
	if "`nonull'"!="" {
		matrix `num0' = `rmat'*`bh''
		scalar `num0' = `num0'[1,1] - `r'
	}
	else scalar `num0' = .
	quietly count if e(sample)
	mata: _sb_core("`u'", "`w'", "`clus'", "`dist'", `b', `seed', "`nonull'"!="", st_numscalar("`num0'"))
	return scalar p = r_p
	return scalar t = r_t
	return scalar G = r_G
	return scalar conv = `conv'
	return scalar rc = 0
	quietly estimates restore UNR
end

mata:
mata set matastrict off
// wild weights exactly as boottest::MakeWildWeights (non-WRE branch), first column = v_sd, then divided by v_sd
real matrix _sb_weights(real scalar G, real scalar B, real scalar seed, string scalar dist)
{
	real matrix v
	real scalar v_sd
	rseed(seed)
	if (dist=="webb") {
		v = sqrt(ceil(runiform(G, B+1) * 3)) :* ((runiform(G, B+1):>=.5):-.5)
		v_sd = sqrt(.5)
	}
	else if (dist=="rademacher") {
		v = (runiform(G, B+1) :>= .5) :- .5
		v_sd = .5
	}
	else _error("unknown dist")
	v[,1] = J(G, 1, v_sd)
	return(v / v_sd)
}

// cached weights: regenerated only when (G, B, seed, dist) changes
pointer(real matrix) scalar _sb_vcache(real scalar G, real scalar B, real scalar seed, string scalar dist)
{
	external real matrix _SBV
	external string scalar _SBKEY
	string scalar key
	key = sprintf("%g|%g|%g|%s", G, B, seed, dist)
	if (_SBKEY != key) {
		_SBV = _sb_weights(G, B, seed, dist)
		_SBKEY = key
	}
	return(&_SBV)
}

void _sb_core(string scalar uname, string scalar wname, string scalar cname, string scalar dist, real scalar B, real scalar seed, real scalar nonull, real scalar num0)
{
	real colvector u, w, id, a, sh, numer, den, t
	real matrix info, D
	pointer(real matrix) scalar pv
	real scalar G, t0, p, c0, c1, CH
	// one joint view: rows with missing u (outside e(sample)) are dropped from all three columns together
	st_view(D, ., (uname, wname, cname), 0)
	u = D[,1]; w = D[,2]; id = D[,3]
	info = panelsetup(id, 1)
	a  = panelsum(u, info)
	sh = panelsum(w, info) / sum(w)
	G = rows(a)
	pv = _sb_vcache(G, B, seed, dist)
	numer = J(B+1, 1, .); den = J(B+1, 1, .)
	CH = 5000
	// J_cb = -a_c v_cb + sh_c * numer_b ; den_b = sum_c J_cb^2 (computed in column chunks)
	for (c0=1; c0<=B+1; c0=c0+CH) {
		c1 = min((c0+CH-1, B+1))
		numer[|c0\c1|] = ((a' * (*pv)[|1,c0 \ G,c1|])')
		den[|c0\c1|] = colsum(((-a) :* (*pv)[|1,c0 \ G,c1|] + sh * numer[|c0\c1|]') :^ 2)'
	}
	t = numer :/ sqrt(den)
	if (nonull) {
		t[1] = num0 / sqrt(den[1])
	}
	t0 = t[1]
	p = sum(abs(t[|2\.|]) :> abs(t0)) / B
	st_numscalar("r_p", p)
	st_numscalar("r_t", t0)
	st_numscalar("r_G", G)
}
end
