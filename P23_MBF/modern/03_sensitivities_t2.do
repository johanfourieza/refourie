* P23_MBF S6: Table 2 sensitivities of card §5 (items 1-9, 11, 12a, 13, 14, 15). Reported, never verdict-determining.
* Item 10 (LPM) is 03b_t2_lpm_fulldata.do; item 12b (pairs cluster bootstrap) is 03c_t2_pairs_bootstrap.do.
* Runs on the extended frequency-weighted cell file (DEVIATIONS D1). Inference: the boottest replica (sb_lib.do),
* Webb, 9,999 draws, null imposed, seed 20261011, p at r = 0 for each hypothesis (DEVIATIONS D3).
* Usage: do 03_sensitivities_t2.do <B for item 12a: 9999 or 99999, = final primary B>
version 16
clear all
set more off
set matsize 11000
sysdir set PLUS "./P23_MBF/compare/s5/ado/plus"
sysdir set PERSONAL "./P23_MBF/compare/s5/ado/personal"
mata: mata mlib index
global MOD "./P23_MBF/modern"
global SCR "./P23_MBF/modern/_scratch"
args B12
if "`B12'"=="" local B12 9999
do "$MOD/sb_lib.do"
do "$MOD/t2_lib.do"
do "$MOD/inv_lib.do"
global PROGTAG "03"
local ctrl "age i_age_age d_female d_christian rural tse_r railway_density count_tribe slave_density d_mission d_capital dist_cap d_western"
use "$SCR/t2_cells_ext.dta", clear
gen byte d_musl = religion==5
gen byte d_relmiss = missing(religion) | religion==9
gen double one_w = 1

tempname P
postfile `P' str40 scen str12 stat double est p p_mband p_pband cnull N G using "$SCR/t2_sens.dta", replace

* ------------------------------------------------------------------
* fit_and_test: fits the model, builds R1..R6 and INFO, posts the six estimates and bootstrap p-values
*   args: scen, regressors (excluding the 3 key terms), weight expression, clus var, if-condition, dist, nonull, wsel var, cnull flag
capture program drop fit_and_test
program fit_and_test
	syntax , scen(string) ctrl(string) wt(string) clus(name) [cond(string) dist(string) nonull wsel(name) cnull reps(integer 9999) post(name)]
	if "`dist'"=="" local dist webb
	if "`wsel'"=="" local wsel n
	local ifc = cond("`cond'"=="", "", "if `cond'")
	sort `clus'
	global FITCUR "logit d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' i.cntry_code [`wt'] `ifc', vce(cluster `clus') tolerance(1e-8) ltolerance(1e-10)"
	global CLUSCUR "`clus'"
	global WVARCUR "`wsel'"
	quietly $FITCUR
	estimates store UNR
	matrix BH = e(b)
	matrix VCR = e(V)
	local N = e(N)
	local G = e(N_clust)
	tempvar es sp sq sb
	gen byte `es' = e(sample)
	t2_xvars
	local K = r(K)
	local jd = r(jd)
	local jp = r(jp)
	local jdp = r(jdp)
	quietly gen double `sp' = `wsel'*(d_age_prim_bef==1)*`es'
	quietly gen double `sq' = `wsel'*(d_age_prim_bef==0)*`es'
	quietly gen double `sb' = `wsel'*(d_birth==1)*`es'
	mata: st_view(X=., ., "__x1-__x`K'"); st_view(a1=., ., "`sp'"); st_view(a2=., ., "`sq'"); st_view(a3=., ., "`sb'"); G = .; S = t2_stats(X, st_matrix("BH"), a1, a2, a3, 1, 0, `jd', `jp', `jdp', G); st_matrix("STATS", S); st_matrix("GRAD", G)
	matrix Z = BH*0
	matrix R1 = Z
	matrix R1[1,`jd'] = 1
	matrix R2 = Z
	matrix R2[1,`jdp'] = 1
	matrix R3 = R1 + R2
	forvalues h = 4/6 {
		matrix R`h' = GRAD[`=`h'-3', 1...]
		matrix colnames R`h' = `: colfullnames BH'
	}
	matrix INFO = J(6, 3, .)
	forvalues h = 1/6 {
		matrix tmp = R`h'*VCR*R`h''
		matrix INFO[`h',2] = sqrt(tmp[1,1])
		matrix tmp = R`h'*BH'
		if `h'<=3 {
			matrix INFO[`h',1] = tmp[1,1]
			matrix INFO[`h',3] = 0
		}
		else {
			matrix INFO[`h',1] = STATS[1,`=`h'-3']
			matrix INFO[`h',3] = tmp[1,1] - STATS[1,`=`h'-3']
		}
	}
	local names "b1 b3 b1+b3 dAME lnRRR lnRRlit"
	forvalues h = 1/6 {
		local pm = .
		local pp = .
		local cn = .
		quietly sb_test, rmat(R`h') r(`=INFO[`h',3]') clus(`clus') fitcmd($FITCUR) wvar(`wsel') b(`reps') dist(`dist') `nonull' recover
		local p0 = r(p)
		if "`cnull'"!="" & `h'>=5 {
			* band endpoints through the cached evaluator; a missing p (unsupported refit) is not "accepted"
			mata: st_numscalar("PM", sb_eval(`h', -(0.5*ln(1.32)), `reps', 0)); st_numscalar("PP", sb_eval(`h', 0.5*ln(1.32), `reps', 0))
			local pm = PM
			local pp = PP
			* step 6(a): an accepted band endpoint means "not inside"; otherwise run the full frozen inversion
			if (`pm' < . & `pm' >= 0.05/6) | (`pp' < . & `pp' >= 0.05/6) local cn = 0
			else {
				mata: FL = .; SEGX = sb_invert(`h', `reps', FL); st_numscalar("CN", FL[2])
				local cn = CN
			}
		}
		post `post' ("`scen'") ("`: word `h' of `names''") (INFO[`h',1]) (`p0') (`pm') (`pp') (`cn') (`N') (`G')
	}
	* AMEs and ratios behind the probability statistics
	local sn "AMEpre AMEpost RRpre RRpost RRlit"
	forvalues j = 4/8 {
		post `post' ("`scen'") ("`: word `=`j'-3' of `sn''") (STATS[1,`j']) (.) (.) (.) (.) (`N') (`G')
	}
	quietly estimates restore UNR
end

* (1) analytic CR1 by id_birth: from the main fit, delta method for the probability statistics
fit_and_test, scen("S0_primary_spec_check") ctrl(`ctrl') wt(fw=n) clus(id_birth) post(`P')
forvalues h = 1/6 {
	local names "b1 b3 b1+b3 dAME lnRRR lnRRlit"
	post `P' ("S1_CR1_analytic") ("`: word `h' of `names''") (INFO[`h',1]) (2*normal(-abs(INFO[`h',1]/INFO[`h',2]))) (.) (.) (.) (5077010) (624)
	post `P' ("S1_CR1_analytic_se") ("`: word `h' of `names''") (INFO[`h',2]) (.) (.) (.) (.) (5077010) (624)
}
* (2) clustering on ethnic group
fit_and_test, scen("S2_cluster_tribe") ctrl(`ctrl') wt(fw=n) clus(tribe_co_1) post(`P')
post `P' ("S2_cluster_tribe_CR1") ("b1") (INFO[1,1]) (2*normal(-abs(INFO[1,1]/INFO[1,2]))) (.) (.) (.) (.) (.)
post `P' ("S2_cluster_tribe_CR1") ("b3") (INFO[2,1]) (2*normal(-abs(INFO[2,1]/INFO[2,2]))) (.) (.) (.) (.) (.)
post `P' ("S2_cluster_tribe_CR1") ("b1+b3") (INFO[3,1]) (2*normal(-abs(INFO[3,1]/INFO[3,2]))) (.) (.) (.) (.) (.)
* (3) score bootstrap clustered by country (11 clusters), diagnostic
fit_and_test, scen("S3_cluster_country") ctrl(`ctrl') wt(fw=n) clus(cntry_code) post(`P')
* (4) Rademacher weights
fit_and_test, scen("S4_rademacher") ctrl(`ctrl') wt(fw=n) clus(id_birth) dist(rademacher) post(`P')
* (5) wild cluster unrestricted score bootstrap
fit_and_test, scen("S5_WCU_nonull") ctrl(`ctrl') wt(fw=n) clus(id_birth) nonull post(`P')
* (6) IPUMS person weights (pweights summed within cells; perwt-weighted means)
fit_and_test, scen("S6_perwt") ctrl(`ctrl') wt(pw=sumperwt) clus(id_birth) wsel(sumperwt) post(`P')
* (7) religion fixed
fit_and_test, scen("S7_religion_fixed") ctrl(`ctrl' d_musl d_relmiss) wt(fw=n) clus(id_birth) post(`P')
* (8) leave-one-country-out, with the credible-null decision for H2-lit and H2-RRR
levelsof cntry_code, local(cl)
foreach c of local cl {
	fit_and_test, scen("S8_drop_cntry_`c'") ctrl(`ctrl') wt(fw=n) clus(id_birth) cond(cntry_code!=`c') cnull post(`P')
}
* (9) mediators and downstream controls removed
local c9a = subinstr(" `ctrl' ", " d_mission ", " ", .)
local c9a = subinstr("`c9a'", " d_capital ", " ", .)
local c9b = subinstr(" `ctrl' ", " rural ", " ", .)
local c9b = subinstr("`c9b'", " d_christian ", " ", .)
local c9c = subinstr("`c9a'", " rural ", " ", .)
local c9c = subinstr("`c9c'", " d_christian ", " ", .)
fit_and_test, scen("S9a_no_mission_capital") ctrl(`c9a') wt(fw=n) clus(id_birth) post(`P')
fit_and_test, scen("S9b_no_rural_christian") ctrl(`c9b') wt(fw=n) clus(id_birth) post(`P')
fit_and_test, scen("S9c_both") ctrl(`c9c') wt(fw=n) clus(id_birth) post(`P')

* (11) standardised probability contrasts, main fit, primary inference
sort id_birth
global FITCUR "logit d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' i.cntry_code [fw=n], vce(cluster id_birth) tolerance(1e-8) ltolerance(1e-10)"
quietly $FITCUR
estimates store UNR
matrix BH = e(b)
matrix VCR = e(V)
t2_xvars
local K = r(K)
local jd = r(jd)
local jp = r(jp)
local jdp = r(jdp)
quietly su yr_birth [fw=n] if d_age_prim_bef==1
local lo1 = r(min)
local hi1 = r(max)
quietly su yr_birth [fw=n] if d_age_prim_bef==0
local lo0 = r(min)
local hi0 = r(max)
local cslo = max(`lo1', `lo0')
local cshi = min(`hi1', `hi0')
gen double s_all = n
gen double s_cs = n*inrange(yr_birth, `cslo', `cshi')
quietly su n if s_cs>0
post `P' ("S11b_common_support_N") ("N") (r(sum)) (.) (.) (.) (.) (`cslo') (`cshi')
foreach v in all cs {
	mata: st_view(X=., ., "__x1-__x`K'"); st_view(a1=., ., "s_`v'"); G = .; S = t2_stats(X, st_matrix("BH"), a1, a1, J(1,1,0), 1, 0, `jd', `jp', `jdp', G); st_matrix("STATS", S); st_matrix("GRAD", G)
	forvalues j = 1/2 {
		matrix RS = GRAD[`j', 1...]
		matrix colnames RS = `: colfullnames BH'
		matrix tmp = RS*BH'
		local off = tmp[1,1] - STATS[1,`j']
		matrix tmp = RS*VCR*RS'
		local se = sqrt(tmp[1,1])
		quietly sb_test, rmat(RS) r(`off') clus(id_birth) fitcmd($FITCUR) wvar(n) b(9999) recover
		local nm = cond(`j'==1, "dAME_std", "lnRRR_std")
		post `P' ("S11`=cond("`v'"=="all","a_all","b_common_support")'") ("`nm'") (STATS[1,`j']) (r(p)) (.) (.) (.) (.) (.)
		post `P' ("S11`=cond("`v'"=="all","a_all","b_common_support")'_CR1") ("`nm'") (`se') (2*normal(-abs(STATS[1,`j']/`se'))) (.) (.) (.) (.) (.)
	}
	local sn "AMEpre_std AMEpost_std RRpre_std RRpost_std"
	forvalues j = 4/7 {
		post `P' ("S11`=cond("`v'"=="all","a_all","b_common_support")'") ("`: word `=`j'-3' of `sn''") (STATS[1,`j']) (.) (.) (.) (.) (.) (.)
	}
}

* (14) raw within-birth-region ratio, no model
quietly su d_primary [fw=n] if d_birth==1 & d_age_prim_bef==1
local m1 = r(mean)
quietly su d_primary [fw=n] if d_birth==1 & d_age_prim_bef==0
local m0 = r(mean)
post `P' ("S14_raw_ratio") ("ratio") (`m1'/`m0') (.) (.) (.) (.) (.) (.)
post `P' ("S14_raw_ratio") ("ln_ratio") (ln(`m1'/`m0')) (.) (.) (.) (.) (.) (.)

* (12a) one-step score-perturbation bootstrap with the primary Webb draws (B = final primary B)
quietly predict double __sc, score
mata {
	st_view(X=., ., "__x1-__x`K'"); st_view(sc=., ., "__sc"); st_view(nn=., ., "n"); st_view(cid=., ., "id_birth")
	st_view(spre=., ., "s_all")
	pre = st_data(., "d_age_prim_bef"); dd = st_data(., "d_birth"); nv = st_data(., "n")
	s1 = nv :* (pre:==1); s0 = nv :* (pre:==0); sb = nv :* (dd:==1)
	info = panelsetup(cid, 1)
	Sg = panelsum((nn:*sc) :* X, info)
	Vmb = st_matrix("e(V_modelbased)")
	bh = st_matrix("BH")
	v = _sb_weights(rows(Sg), `B12', 20261011, "webb")
	v = v[|1,2 \ .,.|]
	TH = J(`B12', 3, .)
	for (bb=1; bb<=`B12'; bb++) {
		bs = bh + (Vmb * (Sg' * v[,bb]))'
		TH[bb,] = t2_theta_fast(X, bs, s1, s0, sb, `jd', `jp', `jdp')
	}
	st_matrix("TH12", TH)
	q = J(3, 4, .)
	for (j=1; j<=3; j++) {
		tj = sort(TH[,j], 1)
		lo = tj[max((1, floor((0.05/12)*`B12')))]
		hi = tj[min((`B12', ceil((1-0.05/12)*`B12')))]
		q[j,] = (lo, hi, mean(TH[,j]:<=0), mean(TH[,j]))
	}
	st_matrix("Q12", q)
}
local nm "dAME lnRRR lnRRlit"
forvalues j = 1/3 {
	post `P' ("S12a_onestep_lo") ("`: word `j' of `nm''") (Q12[`j',1]) (.) (.) (.) (.) (`B12') (.)
	post `P' ("S12a_onestep_hi") ("`: word `j' of `nm''") (Q12[`j',2]) (.) (.) (.) (.) (`B12') (.)
	post `P' ("S12a_onestep_share_le0") ("`: word `j' of `nm''") (Q12[`j',3]) (.) (.) (.) (.) (`B12') (.)
}
drop __sc

* (13) exact leave-one-treated-cluster-out: point estimates
levelsof id_birth if d_birth==1, local(tl)
foreach g of local tl {
	quietly logit d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' i.cntry_code [fw=n] if id_birth!=`g', tolerance(1e-8) ltolerance(1e-10) from(BH, skip)
	matrix B13 = e(b)
	tempvar es sp sq sb
	gen byte `es' = e(sample)
	t2_xvars
	local K = r(K)
	quietly gen double `sp' = n*(d_age_prim_bef==1)*`es'
	quietly gen double `sq' = n*(d_age_prim_bef==0)*`es'
	quietly gen double `sb' = n*(d_birth==1)*`es'
	mata: st_view(X=., ., "__x1-__x`K'"); st_view(a1=., ., "`sp'"); st_view(a2=., ., "`sq'"); st_view(a3=., ., "`sb'"); G = .; S = t2_stats(X, st_matrix("B13"), a1, a2, a3, 1, 0, `=r(jd)', `=r(jp)', `=r(jdp)', G); st_matrix("STATS", S)
	post `P' ("S13_drop_cluster_`g'") ("b1") (_b[d_birth]) (.) (.) (.) (.) (e(N)) (.)
	post `P' ("S13_drop_cluster_`g'") ("b3") (_b[d_birth_bef_indep]) (.) (.) (.) (.) (e(N)) (.)
	post `P' ("S13_drop_cluster_`g'") ("b1+b3") (_b[d_birth]+_b[d_birth_bef_indep]) (.) (.) (.) (.) (e(N)) (.)
	post `P' ("S13_drop_cluster_`g'") ("dAME") (STATS[1,1]) (.) (.) (.) (.) (e(N)) (.)
	post `P' ("S13_drop_cluster_`g'") ("lnRRR") (STATS[1,2]) (.) (.) (.) (.) (e(N)) (.)
	post `P' ("S13_drop_cluster_`g'") ("lnRRlit") (STATS[1,3]) (.) (.) (.) (.) (e(N)) (.)
	drop `es' `sp' `sq' `sb'
}

* (15) Table 3 cols 3-4 corrected to all leaders (C8) and without d_centraliz (C9); primary inference on b1, b3, b1+b3
foreach w in 2 3 {
	sort id_birth
	global FITCUR "logit d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' i.cntry_code [fw=n] if prim_in_plus`w'!=1, vce(cluster id_birth) tolerance(1e-8) ltolerance(1e-10)"
	quietly $FITCUR
	estimates store UNR
	local N = e(N)
	local G = e(N_clust)
	matrix BH = e(b)
	matrix Z = BH*0
	matrix R1 = Z
	matrix R1[1,colnumb(BH,"d_birth")] = 1
	matrix R2 = Z
	matrix R2[1,colnumb(BH,"d_birth_bef_indep")] = 1
	matrix R3 = R1 + R2
	local names "b1 b3 b1+b3"
	forvalues h = 1/3 {
		matrix tmp = R`h'*BH'
		local est = tmp[1,1]
		quietly sb_test, rmat(R`h') r(0) clus(id_birth) fitcmd($FITCUR) wvar(n) b(9999) recover
		post `P' ("S15_T3c`=`w'+1'_all_leaders_no_centraliz") ("`: word `h' of `names''") (`est') (r(p)) (.) (.) (.) (`N') (`G')
	}
}
postclose `P'
use "$SCR/t2_sens.dta", clear
export delimited using "$MOD/output/t2_sensitivities_raw.csv", replace
