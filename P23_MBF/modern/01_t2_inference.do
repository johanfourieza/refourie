* P23_MBF S6 primary analysis A (card §4A): Table 2 col 4 logit, wild cluster restricted score bootstrap,
* six hypotheses (Family M), Bonferroni, CI by explicit test inversion. Runs on the frequency-weighted cell file
* built by 00_t2_collapse.do (DEVIATIONS D1); the bootstrap is the boottest replica in sb_lib.do.
* Usage (batch): do 01_t2_inference.do setup        precondition, statistics, diagnostics, Monte Carlo check -> final B
*                do 01_t2_inference.do invert "h.."  inversion of the listed hypotheses at the final B (parallel workers)
*                do 01_t2_inference.do combine      assemble the six inversions and write the outputs
* The Monte Carlo rule of card §4A needs only p_h(0) for all h and p_h(+-0.5 ln 1.32) for h5, h6 at 9,999 draws; the
* inversions are then run once, at the final B (DEVIATIONS D8). The 9,999-draw inversions would be superseded anyway.
version 16
clear all
set more off
set matsize 11000
sysdir set PLUS "./P23_MBF/compare/s5/ado/plus"
sysdir set PERSONAL "./P23_MBF/compare/s5/ado/personal"
mata: mata mlib index
global MOD "./P23_MBF/modern"
global SCR "./P23_MBF/modern/_scratch"
args MODE HLIST
if "`MODE'"=="" local MODE setup
local SUF = cond("`MODE'"=="setup", "", "_w" + subinstr("`HLIST'", " ", "", .))
do "$MOD/sb_lib.do"
do "$MOD/t2_lib.do"
do "$MOD/inv_lib.do"
* record boottest version (card §4A)
file open fh using "$MOD/env_stata_ado.txt", write replace
file write fh "StataNow 19.5 MP; ado path ./P23_MBF/compare/s5/ado/plus" _n
file open bt using "./P23_MBF/compare/s5/ado/plus/b/boottest.ado", read
file read bt line
file write fh `"`line'"' _n
file close bt
file close fh

local ctrl "age i_age_age d_female d_christian rural tse_r railway_density count_tribe slave_density d_mission d_capital dist_cap d_western"
use "$SCR/t2_cells_primary.dta", clear
sort id_birth
global FIT "logit d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' i.cntry_code [fw=n], vce(cluster id_birth) tolerance(1e-8) ltolerance(1e-10)"
$FIT
estimates store UNR
matrix BH = e(b)
matrix VCR = e(V)
matrix VMB = e(V_modelbased)

* ---------------- precondition (card §4A)
local ok = abs(_b[d_birth]-0.3802291)<1e-6 & abs(_b[d_birth_bef_indep]-0.2809717)<1e-6 & abs(_b[d_age_prim_bef]-0.0207078)<1e-6 ///
	& abs(_se[d_birth]-0.1116197)<1e-6 & abs(_se[d_birth_bef_indep]-0.1269793)<1e-6 & e(N)==5077010 & e(N_clust)==624
tempname PC
postfile `PC' str32 item double value using "$SCR/t2_precondition`SUF'.dta", replace
post `PC' ("b1") (_b[d_birth])
post `PC' ("b3") (_b[d_birth_bef_indep])
post `PC' ("b2") (_b[d_age_prim_bef])
post `PC' ("se1_CR1") (_se[d_birth])
post `PC' ("se3_CR1") (_se[d_birth_bef_indep])
post `PC' ("N") (e(N))
post `PC' ("N_clust") (e(N_clust))
post `PC' ("coef_and_se_match_1e-6") (`ok')

* ---------------- probability statistics and analytic gradients (card §3)
t2_xvars
local K = r(K)
local jd = r(jd)
local jp = r(jp)
local jdp = r(jdp)
gen double s_pre  = n*(d_age_prim_bef==1)
gen double s_post = n*(d_age_prim_bef==0)
gen double s_br   = n*(d_birth==1)
mata {
	st_view(X=., ., "__x1-__x`K'")
	st_view(spre=., ., "s_pre"); st_view(spost=., ., "s_post"); st_view(sbr=., ., "s_br")
	b = st_matrix("BH")
	G = .
	S = t2_stats(X, b, spre, spost, sbr, 1, 0, `jd', `jp', `jdp', G)
	st_matrix("STATS", S)
	st_matrix("GRAD", G)
	// central finite differences for every non-fixed column.
	// (1) literal card check: absolute step 1e-5; (2) diagnostic: absolute step 5e-6 (truncation error should fall by 4);
	// (3) DEVIATIONS D2: step 1e-5/max(1, sd(x_k)), scale-invariant, used for the precondition decision
	Vd = diagonal(st_matrix("VCR"))'
	act = selectindex(Vd :> 0)
	nn0 = st_data(., "n")
	sdx = J(1, cols(b), 1)
	for (k=1; k<=cols(b); k++) {
		mu = sum(nn0 :* X[,k]) / sum(nn0)
		sdx[k] = max((1, sqrt(sum(nn0 :* (X[,k] :- mu):^2) / sum(nn0))))
	}
	names = st_matrixcolstripe("BH")[act, 2]
	REL = J(3, 3, .)
	for (m=1; m<=3; m++) {
		FD = J(3, cols(b), 0)
		for (k=1; k<=cols(b); k++) {
			if (Vd[k]==0) continue
			hk = (m==1? 1e-5 : (m==2? 5e-6 : 1e-5/sdx[k]))
			bp = b
			bp[k] = bp[k] + hk
			bm = b
			bm[k] = bm[k] - hk
			FD[,k] = ((t2_theta(X, bp, spre, spost, sbr, 1, 0, `jd', `jp', `jdp') - t2_theta(X, bm, spre, spost, sbr, 1, 0, `jd', `jp', `jdp')) / (2*hk))'
		}
		Ga = G[, act]
		Fa = FD[, act]
		relc = abs(Ga - Fa) :/ abs(Ga)
		REL[,m] = rowmax(relc)
		printf("FD step mode %g (1 = abs 1e-5, 2 = abs 5e-6, 3 = 1e-5/sd)\n", m)
		for (k=1; k<=cols(act); k++) printf("FD %-22s sd %10.3g  %12.4e %12.4e %12.4e\n", names[k], sdx[act[k]], relc[1,k], relc[2,k], relc[3,k])
	}
	st_matrix("FDREL_COMP", REL[,1])
	st_matrix("FDREL_HALF", REL[,2])
	st_matrix("FDREL_NORM", REL[,3])
}
matrix list FDREL_COMP
matrix list FDREL_HALF
matrix list FDREL_NORM
local fdok = FDREL_COMP[1,1]<=1e-6 & FDREL_COMP[2,1]<=1e-6 & FDREL_COMP[3,1]<=1e-6
local fdokn = FDREL_NORM[1,1]<=1e-6 & FDREL_NORM[2,1]<=1e-6 & FDREL_NORM[3,1]<=1e-6
post `PC' ("FD_absstep1e-5_maxrel_dAME") (FDREL_COMP[1,1])
post `PC' ("FD_absstep1e-5_maxrel_lnRRR") (FDREL_COMP[2,1])
post `PC' ("FD_absstep1e-5_maxrel_lnRRlit") (FDREL_COMP[3,1])
post `PC' ("FD_absstep5e-6_maxrel_dAME") (FDREL_HALF[1,1])
post `PC' ("FD_absstep5e-6_maxrel_lnRRR") (FDREL_HALF[2,1])
post `PC' ("FD_absstep5e-6_maxrel_lnRRlit") (FDREL_HALF[3,1])
post `PC' ("FD_scaledstep_maxrel_dAME") (FDREL_NORM[1,1])
post `PC' ("FD_scaledstep_maxrel_lnRRR") (FDREL_NORM[2,1])
post `PC' ("FD_scaledstep_maxrel_lnRRlit") (FDREL_NORM[3,1])
post `PC' ("FD_ok_literal_absstep1e-5") (`fdok')
post `PC' ("FD_ok_scaledstep_D2") (`fdokn')
local snames "dAME lnRRR lnRRlit AMEpre AMEpost RRpre RRpost RRlit m1pre m0pre m1post m0post mL1 mL0"
forvalues j = 1/14 {
	post `PC' ("`: word `j' of `snames''") (STATS[1,`j'])
}
quietly su d_primary [fw=n]
post `PC' ("mean_primary") (r(mean))
* treated clusters
preserve
quietly collapse (sum) n (max) d_birth cntry_code, by(id_birth)
quietly count if d_birth==1
local ntreat = r(N)
restore
post `PC' ("n_treated_clusters") (`ntreat')
postclose `PC'
* D2: the precondition decision uses the scale-invariant finite-difference step
local ok = `ok' & `fdokn'
if !`ok' {
	di as error "PRECONDITION FAILED: all Table 2 rows not-testable"
	use "$SCR/t2_precondition`SUF'.dta", clear
	if "`MODE'"=="setup" export delimited using "$MOD/output/t2_precondition.csv", replace
	exit 0
}

* ---------------- hypothesis vectors (Family M): R_h * beta = c_h(r)
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
* rhat, s_h (CR1), offset so that c_h(r) = off_h + r
matrix INFO = J(6, 4, .)
forvalues h = 1/6 {
	matrix tmp = R`h'*VCR*R`h''
	local s`h' = sqrt(tmp[1,1])
	if `h'<=3 {
		matrix tmp = R`h'*BH'
		local rhat`h' = tmp[1,1]
		local off`h' = 0
	}
	else {
		local rhat`h' = STATS[1, `=`h'-3']
		matrix tmp = R`h'*BH'
		local off`h' = tmp[1,1] - `rhat`h''
	}
	matrix INFO[`h',1] = `rhat`h''
	matrix INFO[`h',2] = `s`h''
	matrix INFO[`h',3] = `off`h''
	matrix INFO[`h',4] = 2*normal(-abs(`rhat`h''/`s`h''))
}
matrix list INFO, format(%14.8g)
* save hypothesis vectors (coefficient space; aggregate) for the full-data verification (01b)
preserve
clear
matrix RR = R1 \ R2 \ R3 \ R4 \ R5 \ R6
matrix RRt = RR'
svmat double RRt, names(R)
gen str40 coef = ""
local cn : colnames BH
forvalues j = 1/`K' {
	quietly replace coef = "`: word `j' of `cn''" in `j'
}
save "$SCR/t2_hyp`SUF'.dta", replace
clear
svmat double INFO, names(info)
save "$SCR/t2_hypinfo`SUF'.dta", replace
restore

* ---------------- cluster leverage and influence diagnostics (card §4A; reported only)
quietly predict double __sc, score
mata {
	st_view(X=., ., "__x1-__x`K'")
	st_view(sc=., ., "__sc"); st_view(nn=., ., "n"); st_view(cid=., ., "id_birth"); st_view(dd=., ., "d_birth"); st_view(cc=., ., "cntry_code")
	info = panelsetup(cid, 1)
	Sg = panelsum((nn:*sc) :* X, info)              // G x K cluster scores at bhat
	Vmb = st_matrix("VMB")
	Dg = -(Sg * Vmb)                                // one-step leave-cluster-out change (G x K)
	RR = st_matrix("RR")
	DH = Dg * RR'                                   // G x 6
	Ng = panelsum(nn, info)
	trt = panelsum(dd:*nn, info) :> 0
	cty = cc[info[,1]]
	ids = cid[info[,1]]
	st_matrix("INFL", (ids, cty, trt, Ng, DH))
}
preserve
clear
svmat double INFL, names(c)
rename (c1 c2 c3 c4) (id_birth cntry_code treated n_obs)
forvalues h = 1/6 {
	rename c`=`h'+4' delta_h`h'
}
save "$SCR/t2_influence`SUF'.dta", replace
* cluster-size and concentration summary
tempname DG
postfile `DG' str48 item double value using "$SCR/t2_diag`SUF'.dta", replace
quietly su n_obs, detail
post `DG' ("cluster_size_min") (r(min))
post `DG' ("cluster_size_median") (r(p50))
post `DG' ("cluster_size_max") (r(max))
quietly su n_obs
local Ntot = r(sum)
quietly su n_obs if treated
post `DG' ("treated_clusters") (r(N))
post `DG' ("treated_share_of_N") (r(sum)/`Ntot')
local Ntr = r(sum)
post `DG' ("largest_treated_cluster_share_of_treated_obs") (r(max)/`Ntr')
levelsof cntry_code, local(cl)
foreach c of local cl {
	quietly su n_obs if treated & cntry_code==`c'
	post `DG' ("treated_clusters_cntry_`c'") (r(N))
	post `DG' ("treated_obs_share_cntry_`c'") (cond(r(N)>0, r(sum)/`Ntr', 0))
}
forvalues h = 1/6 {
	gen double absd = abs(delta_h`h')
	quietly su absd
	post `DG' ("max_abs_delta_over_CR1se_h`h'") (r(max)/`s`h'')
	gsort -absd
	forvalues k = 1/10 {
		post `DG' ("h`h'_top`k'_id_birth") (id_birth[`k'])
		post `DG' ("h`h'_top`k'_delta") (delta_h`h'[`k'])
		post `DG' ("h`h'_top`k'_treated") (treated[`k'])
		post `DG' ("h`h'_top`k'_cntry") (cntry_code[`k'])
	}
	drop absd
}
postclose `DG'
use "$SCR/t2_diag`SUF'.dta", clear
if "`MODE'"=="setup" export delimited using "$MOD/output/t2_diagnostics.csv", replace
restore
drop __sc

* ---------------- inversion machinery (card §4A steps 1-7; inv_lib.do)
global FITCUR "$FIT"
global CLUSCUR "id_birth"
global WVARCUR "n"
global PROGTAG "01`SUF'"
global ASTAR "(0.05/6)"
global BAND "(0.5*ln(1.32))"

if "`MODE'"=="setup" {
	* Monte Carlo precision rule at 9,999 draws (card §4A)
	tempname MC
	postfile `MC' int h double p0 p_mband p_pband using "$SCR/t2_mc_B9999.dta", replace
	forvalues h = 1/6 {
		mata: st_numscalar("PX", sb_eval(`h', 0, 9999, 0))
		local pm = .
		local pp = .
		if `h' >= 5 {
			mata: st_numscalar("PM", sb_eval(`h', -(0.5*ln(1.32)), 9999, 0)); st_numscalar("PP", sb_eval(`h', 0.5*ln(1.32), 9999, 0))
			local pm = PM
			local pp = PP
		}
		post `MC' (`h') (PX) (`pm') (`pp')
	}
	postclose `MC'
	use "$SCR/t2_mc_B9999.dta", clear
	gen double mcse = sqrt(p0*(1-p0)/9999)
	gen byte near = abs(p0 - $ASTAR) <= 2*mcse | abs(p0 - 0.05) <= 2*mcse
	replace near = 1 if h>=5 & ((p_mband < . & abs(p_mband - $ASTAR) <= 2*sqrt(p_mband*(1-p_mband)/9999)) | (p_pband < . & abs(p_pband - $ASTAR) <= 2*sqrt(p_pband*(1-p_pband)/9999)))
	quietly count if near
	gen byte escalate = r(N) > 0
	gen long B_final = cond(escalate, 99999, 9999)
	list, clean
	save "$SCR/t2_mc_B9999.dta", replace
	export delimited using "$MOD/output/t2_mc_check_B9999.csv", replace
	exit 0
}

if "`MODE'"=="invert" {
	preserve
	use "$SCR/t2_mc_B9999.dta", clear
	local BF = B_final[1]
	restore
	tempname PR
	postfile `PR' int h double rhat s p0 cr1p B nseg lo1 hi1 lo2 hi2 lo3 hi3 lo_res hi_res any_unres disjoint contains0 consistent unsupported n_unsup_pts cn_status p_mband p_pband n_evals reruns using "$SCR/t2_primary_part`SUF'.dta", replace
	foreach h of local HLIST {
		local rerun = 0
		mata: FL = .; SEG = sb_invert(`h', `BF', FL); st_matrix("SEG", (rows(SEG) ? SEG : J(1,4,.))); st_numscalar("NSEG", rows(SEG)); st_matrix("FL", FL)
		mata: st_numscalar("P0", select(EV[,3], (EV[,1]:==`h') :& (EV[,2]:==0) :& (EV[,5]:==`BF'))[1])
		local nseg = NSEG
		local c0 = 0
		forvalues j = 1/`nseg' {
			if SEG[`j',1] <= 0 & SEG[`j',2] >= 0 local c0 = 1
		}
		local cons = (`c0' == (P0 >= $ASTAR)) & P0 < .
		if !`cons' & P0 < . {
			* step 5: one rerun of the inversion
			local rerun = 1
			mata: FL = .; SEG = sb_invert(`h', `BF', FL); st_matrix("SEG", (rows(SEG) ? SEG : J(1,4,.))); st_numscalar("NSEG", rows(SEG)); st_matrix("FL", FL)
			local nseg = NSEG
			local c0 = 0
			forvalues j = 1/`nseg' {
				if SEG[`j',1] <= 0 & SEG[`j',2] >= 0 local c0 = 1
			}
			local cons = (`c0' == (P0 >= $ASTAR))
		}
		* the set is unsupported if p_h(0) is unavailable or the consistency check fails twice (step 5)
		local uns = (P0 >= .) | !`cons'
		local cn = FL[1,2]
		if `h' >= 5 & `uns' local cn = -1
		local anyun = 0
		forvalues j = 1/`nseg' {
			if SEG[`j',3]==0 | SEG[`j',4]==0 local anyun = 1
		}
		local pm = .
		local pp = .
		if `h' >= 5 {
			mata: st_numscalar("PM", select(EV[,3], (EV[,1]:==`h') :& (abs(EV[,2]:+(0.5*ln(1.32))):<1e-15) :& (EV[,5]:==`BF'))[1]); st_numscalar("PP", select(EV[,3], (EV[,1]:==`h') :& (abs(EV[,2]:-(0.5*ln(1.32))):<1e-15) :& (EV[,5]:==`BF'))[1])
			local pm = PM
			local pp = PP
		}
		forvalues j = 1/3 {
			local l`j' = cond(`nseg'>=`j', SEG[`j',1], .)
			local u`j' = cond(`nseg'>=`j', SEG[`j',2], .)
		}
		local lr = cond(`nseg'>0, SEG[1,3], .)
		local hr = cond(`nseg'>0, SEG[`nseg',4], .)
		post `PR' (`h') (INFO[`h',1]) (INFO[`h',2]) (P0) (INFO[`h',4]) (`BF') (`nseg') (`l1') (`u1') (`l2') (`u2') (`l3') (`u3') (`lr') (`hr') (`anyun') (`nseg'>1) (`c0') (`cons') (`uns') (FL[1,1]) (`cn') (`pm') (`pp') (FL[1,3]) (`rerun')
	}
	postclose `PR'
	mata: st_matrix("EVM", EV)
	clear
	svmat double EVM, names(ev)
	rename (ev1 ev2 ev3 ev4 ev5 ev6) (h r p conv B stage)
	save "$SCR/t2_evals_part`SUF'.dta", replace
	exit 0
}

if "`MODE'"=="combine" {
	clear
	local fl : dir "$SCR" files "t2_primary_part_w*.dta"
	foreach f of local fl {
		append using "$SCR/`f'"
	}
	sort h
	gen double mcse = sqrt(p0*(1-p0)/B)
	gen double padj = min(1, 6*p0)
	merge 1:1 h using "$SCR/t2_mc_B9999.dta", keepusing(escalate B_final) nogen
	export delimited using "$MOD/output/t2_primary_raw.csv", replace
	clear
	local fl : dir "$SCR" files "t2_evals_part_w*.dta"
	foreach f of local fl {
		append using "$SCR/`f'"
	}
	sort h r stage
	export delimited using "$MOD/output/t2_inversion_evals.csv", replace
	use "$SCR/t2_precondition.dta", clear
	export delimited using "$MOD/output/t2_precondition.csv", replace
}
