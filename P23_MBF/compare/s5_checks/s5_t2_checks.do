* S5 checks, Table 2 col 4 (headlines T2_br_c4, T2_ia_c4) and Table 3 cols 3-4.
* Not original code. Reads the authors' analysis file; writes coefficient summaries only (no microdata rows).
version 16
clear all
set more off
sysdir set PLUS "./P23_MBF/compare/s5/ado/plus"
sysdir set PERSONAL "./P23_MBF/compare/s5/ado/personal"
local out "./P23_MBF/compare/s5"
use cntry_code id_birth tribe_co_1 d_primary d_birth_all d_birth_elite d_age_prim_bef age i_age_age d_female d_christian rural tse_r railway_density count_tribe slave_density d_mission d_centraliz d_capital dist_cap d_western prim_in_plus2 prim_in_plus3 perwt religion using "./P23_MBF/original/ld/1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear
gen d_birth = d_birth_all
gen d_birth_bef_indep = d_age_prim_bef*d_birth
local ctrl "age i_age_age d_female d_christian rural tse_r railway_density count_tribe slave_density d_mission d_capital dist_cap d_western"
tempname P
postfile `P' str40 scenario str20 term double b se p N nclust using "`out'/s5_t2_results.dta", replace
program drop _all
program define postit
	args P scen
	foreach t in d_birth d_birth_bef_indep {
		capture scalar bb = _b[`t']
		if _rc continue
		scalar ss = _se[`t']
		local df = cond(e(N_clust)<., e(N_clust)-1, .)
		scalar pp = 2*normal(-abs(bb/ss))
		post `P' ("`scen'") ("`t'") (bb) (ss) (pp) (e(N)) (e(N_clust))
	}
	capture lincom d_birth + d_birth_bef_indep
	if !_rc post `P' ("`scen'") ("pre_gap_b1+b3") (r(estimate)) (r(se)) (2*normal(-abs(r(estimate)/r(se)))) (e(N)) (e(N_clust))
end
tab religion if d_birth_bef_indep!=., missing
* S0 baseline (original col 4)
logit d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' i.cntry_code if d_birth_bef_indep!=., vce(cluster id_birth)
postit `P' "S0_baseline_col4"
* distinct treated clusters
preserve
keep if e(sample)
bysort id_birth: keep if _n==1
count if d_birth==1
local ntreat = r(N)
count
di "treated clusters: `ntreat' of " r(N)
restore
post `P' ("S0_baseline_col4") ("n_treated_clusters") (`ntreat') (.) (.) (.) (.)
* AME (probability scale) of BR for pre and post cohorts, manual
predict double xb0, xb
gen double pr1 = invlogit(xb0 - _b[d_birth]*d_birth - _b[d_birth_bef_indep]*d_birth_bef_indep + _b[d_birth] + _b[d_birth_bef_indep]*d_age_prim_bef) if e(sample)
gen double pr0 = invlogit(xb0 - _b[d_birth]*d_birth - _b[d_birth_bef_indep]*d_birth_bef_indep) if e(sample)
gen double dpr = pr1-pr0
su dpr if d_age_prim_bef==1
post `P' ("S0_baseline_col4") ("AME_BR_pre") (r(mean)) (.) (.) (r(N)) (.)
su dpr if d_age_prim_bef==0
post `P' ("S0_baseline_col4") ("AME_BR_post") (r(mean)) (.) (.) (r(N)) (.)
su d_primary if e(sample)
post `P' ("S0_baseline_col4") ("mean_primary") (r(mean)) (.) (.) (r(N)) (.)
drop xb0 pr1 pr0 dpr
* S1 cluster on ethnic group (paper: "results remain unchanged if clustered at the ethnic level")
logit d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' i.cntry_code if d_birth_bef_indep!=., vce(cluster tribe_co_1)
postit `P' "S1_cluster_tribe"
* S2 IPUMS person weights
logit d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' i.cntry_code [pw=perwt] if d_birth_bef_indep!=., vce(cluster id_birth)
postit `P' "S2_perwt"
* S3 religion: Muslim dummy (religion==5) and missing/unknown religion dummy added
gen d_musl = religion==5
gen d_relmiss = missing(religion) | religion==9
logit d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' d_musl d_relmiss i.cntry_code if d_birth_bef_indep!=., vce(cluster id_birth)
postit `P' "S3_religion_fixed"
* S4 Table 3 cols 3-4 as run (d_birth = d_birth_elite, carried over from col 2), without d_centraliz
replace d_birth = d_birth_elite
replace d_birth_bef_indep = d_age_prim_bef*d_birth
logit d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' i.cntry_code if prim_in_plus2!=1, vce(cluster id_birth)
postit `P' "S4_T3c3_elite_no_centraliz"
logit d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' i.cntry_code if prim_in_plus3!=1, vce(cluster id_birth)
postit `P' "S4_T3c4_elite_no_centraliz"
* S5 wild cluster score bootstrap (few treated clusters), Table 2 col 4
replace d_birth = d_birth_all
replace d_birth_bef_indep = d_age_prim_bef*d_birth
logit d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' i.cntry_code if d_birth_bef_indep!=., vce(cluster id_birth)
foreach t in d_birth d_birth_bef_indep {
	capture noisily boottest `t', reps(999) seed(20261011) weight(webb) nograph
	if !_rc post `P' ("S5_score_wildboot_webb") ("`t'") (_b[`t']) (.) (r(p)) (e(N)) (e(N_clust))
}
postclose `P'
use "`out'/s5_t2_results.dta", clear
export delimited using "`out'/s5_t2_results.csv", replace
list, clean
