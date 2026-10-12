* P23_MBF S6 sensitivity 12b (card §5): pairs cluster bootstrap, 624 birth-region clusters resampled with
* replacement, B = 399, seed 20261011, full logit re-estimation, theta computed nonlinearly; 99.17% percentile interval.
* Cell file with frequency weights n x (cluster multiplicity) (DEVIATIONS D1).
version 16
clear all
set more off
set matsize 11000
global MOD "./P23_MBF/modern"
global SCR "./P23_MBF/modern/_scratch"
do "$MOD/t2_lib.do"
local ctrl "age i_age_age d_female d_christian rural tse_r railway_density count_tribe slave_density d_mission d_capital dist_cap d_western"
use "$SCR/t2_cells_primary.dta", clear
sort id_birth
egen int gidx = group(id_birth)
quietly su gidx
local G = r(max)
logit d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' i.cntry_code [fw=n], tolerance(1e-8) ltolerance(1e-10)
matrix BH = e(b)
t2_xvars
local K = r(K)
local jd = r(jd)
local jp = r(jp)
local jdp = r(jdp)
gen long m = 0
gen double w = 0
gen double s1 = 0
gen double s0 = 0
gen double sb = 0
local B 399
mata:
rseed(20261011)
MULT = J(`G', `B', 0)
for (bb=1; bb<=`B'; bb++) {
	ix = runiformint(`G', 1, 1, `G')
	for (i=1; i<=`G'; i++) MULT[ix[i], bb] = MULT[ix[i], bb] + 1
}
end
tempname P
postfile `P' int b double dAME lnRRR lnRRlit b1 b3 conv using "$SCR/t2_pairs.dta", replace
forvalues bb = 1/`B' {
	mata: st_store(., "m", MULT[st_data(., "gidx"), `bb'])
	quietly replace w = n*m
	capture quietly logit d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' i.cntry_code [fw=w] if m>0, tolerance(1e-8) ltolerance(1e-10) from(BH, skip)
	if _rc {
		post `P' (`bb') (.) (.) (.) (.) (.) (0)
		continue
	}
	local cv = e(converged)
	matrix BB = e(b)
	* align with the full-sample column order (a country dummy could drop if a country vanished; it cannot, but check)
	if colsof(BB) != `K' {
		post `P' (`bb') (.) (.) (.) (.) (.) (0)
		continue
	}
	quietly replace s1 = w*(d_age_prim_bef==1)
	quietly replace s0 = w*(d_age_prim_bef==0)
	quietly replace sb = w*(d_birth==1)
	mata: st_view(X=., ., "__x1-__x`K'"); st_view(a1=., ., "s1"); st_view(a2=., ., "s0"); st_view(a3=., ., "sb"); st_matrix("TH", t2_theta_fast(X, st_matrix("BB"), a1, a2, a3, `jd', `jp', `jdp'))
	post `P' (`bb') (TH[1,1]) (TH[1,2]) (TH[1,3]) (_b[d_birth]) (_b[d_birth_bef_indep]) (`cv')
}
postclose `P'
use "$SCR/t2_pairs.dta", clear
export delimited using "$MOD/output/t2_pairs_bootstrap_draws.csv", replace
