* P23_MBF S6: probability-scale statistics for Table 2 col 4 and their analytic gradients (card §3, §4A).
* t2_xvars: after the logit, builds variables __x1..__xK holding the regressor of each column of e(b)
*   (0 for base/omitted columns, 1 for _cons); returns the column indices of d_birth, d_age_prim_bef, d_birth_bef_indep.
* Mata t2_stats(b, wsel, pre, d) returns a struct of all statistics and gradients, from the cell data.

capture program drop t2_xvars
program t2_xvars, rclass
	capture drop __x*
	local names : colnames e(b)
	local K : word count `names'
	forvalues j = 1/`K' {
		local nm : word `j' of `names'
		if "`nm'"=="_cons" quietly gen byte __x`j' = 1
		else if (strpos("`nm'", "o.") | strpos("`nm'", "b.")) quietly gen byte __x`j' = 0
		else if ustrregexm("`nm'", "^([0-9]+)\.(.+)$") {
			local lev = ustrregexs(1)
			local fv = ustrregexs(2)
			quietly gen byte __x`j' = (`fv' == `lev')
		}
		else quietly gen double __x`j' = `nm'
		if "`nm'"=="d_birth" return scalar jd = `j'
		if "`nm'"=="d_age_prim_bef" return scalar jp = `j'
		if "`nm'"=="d_birth_bef_indep" return scalar jdp = `j'
	}
	return scalar K = `K'
end

mata:
mata set matastrict off

// mean over selection weights s of p_i(dval, c_i) and its gradient wrt b
// X: N x K design; xb0 = X*b' with the d, pre, d*pre terms removed; c: N x 1 (or scalar) cohort indicator value
void _t2_meanp(real matrix X, real colvector xb0, real rowvector b, real colvector s, real scalar dval, real colvector c,
               real scalar jd, real scalar jp, real scalar jdp, real scalar m, real rowvector g)
{
	real colvector eta, p, w
	real scalar S
	eta = xb0 :+ b[jd]*dval :+ b[jp]*c :+ b[jdp]*dval*c
	p = invlogit(eta)
	S = quadsum(s)
	m = quadsum(s :* p) / S
	w = s :* p :* (1 :- p)
	g = quadcross(X, w)' / S
	g[jd]  = dval * quadsum(w) / S
	g[jp]  = quadsum(w :* c) / S
	g[jdp] = dval * quadsum(w :* c) / S
}

// all statistics. spre, spost, sbr: selection weights (frequency x subset); cpre/cpost: cohort value used for each group
// mode "own": c = own Pre (1 for pre group, 0 for post group). Returns rowvector:
// (dAME, lnRRR, lnRRlit, AMEpre, AMEpost, RRpre, RRpost, RRlit, m1pre, m0pre, m1post, m0post, mL1, mL0) and G (3 x K gradients)
real rowvector t2_stats(real matrix X, real rowvector b, real colvector spre, real colvector spost, real colvector sbr,
                        real scalar cpre, real scalar cpost, real scalar jd, real scalar jp, real scalar jdp, real matrix G)
{
	real colvector xb0
	real scalar m1pre, m0pre, m1post, m0post, mL1, mL0
	real rowvector g1pre, g0pre, g1post, g0post, gL1, gL0
	pragma unset m1pre; pragma unset m0pre; pragma unset m1post; pragma unset m0post; pragma unset mL1; pragma unset mL0
	pragma unset g1pre; pragma unset g0pre; pragma unset g1post; pragma unset g0post; pragma unset gL1; pragma unset gL0
	xb0 = X*b' - X[,jd]*b[jd] - X[,jp]*b[jp] - X[,jdp]*b[jdp]
	_t2_meanp(X, xb0, b, spre,  1, cpre,  jd, jp, jdp, m1pre,  g1pre)
	_t2_meanp(X, xb0, b, spre,  0, cpre,  jd, jp, jdp, m0pre,  g0pre)
	_t2_meanp(X, xb0, b, spost, 1, cpost, jd, jp, jdp, m1post, g1post)
	_t2_meanp(X, xb0, b, spost, 0, cpost, jd, jp, jdp, m0post, g0post)
	if (rows(sbr)>1) {
		_t2_meanp(X, xb0, b, sbr, 1, 1, jd, jp, jdp, mL1, gL1)
		_t2_meanp(X, xb0, b, sbr, 1, 0, jd, jp, jdp, mL0, gL0)
	}
	else {
		mL1 = mL0 = 1; gL1 = gL0 = J(1, cols(b), 0)
	}
	G = ((g1pre - g0pre) - (g1post - g0post)) \
	    (g1pre/m1pre - g0pre/m0pre - g1post/m1post + g0post/m0post) \
	    (gL1/mL1 - gL0/mL0)
	return(((m1pre-m0pre)-(m1post-m0post), ln(m1pre)-ln(m0pre)-ln(m1post)+ln(m0post), ln(mL1)-ln(mL0),
	        m1pre-m0pre, m1post-m0post, m1pre/m0pre, m1post/m0post, mL1/mL0, m1pre, m0pre, m1post, m0post, mL1, mL0))
}

// theta only (3-vector), for finite differences and nonlinear bootstraps
real rowvector t2_theta(real matrix X, real rowvector b, real colvector spre, real colvector spost, real colvector sbr,
                        real scalar cpre, real scalar cpost, real scalar jd, real scalar jp, real scalar jdp)
{
	real matrix G
	real rowvector s
	pragma unset G
	s = t2_stats(X, b, spre, spost, sbr, cpre, cpost, jd, jp, jdp, G)
	return(s[1..3])
}
// theta only, without gradients (for the one-step bootstrap of sensitivity 12a); own-cohort mode
real rowvector t2_theta_fast(real matrix X, real rowvector b, real colvector spre, real colvector spost, real colvector sbr,
                             real scalar jd, real scalar jp, real scalar jdp)
{
	real colvector xb0
	real scalar m1pre, m0pre, m1post, m0post, mL1, mL0
	xb0 = X*b' - X[,jd]*b[jd] - X[,jp]*b[jp] - X[,jdp]*b[jdp]
	m1pre  = quadsum(spre  :* invlogit(xb0 :+ b[jd] :+ b[jp] :+ b[jdp])) / quadsum(spre)
	m0pre  = quadsum(spre  :* invlogit(xb0 :+ b[jp])) / quadsum(spre)
	m1post = quadsum(spost :* invlogit(xb0 :+ b[jd])) / quadsum(spost)
	m0post = quadsum(spost :* invlogit(xb0)) / quadsum(spost)
	mL1 = quadsum(sbr :* invlogit(xb0 :+ b[jd] :+ b[jp] :+ b[jdp])) / quadsum(sbr)
	mL0 = quadsum(sbr :* invlogit(xb0 :+ b[jd])) / quadsum(sbr)
	return(((m1pre-m0pre)-(m1post-m0post), ln(m1pre)-ln(m0pre)-ln(m1post)+ln(m0post), ln(mL1)-ln(mL0)))
}
end
