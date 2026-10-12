* S5 check: leave-one-country-out, Table 2 col 4. Not original code. Coefficient summaries only.
version 16
clear all
set more off
local out "./P23_MBF/compare/s5"
use cntry_code id_birth d_primary d_birth_all d_age_prim_bef age i_age_age d_female d_christian rural tse_r railway_density count_tribe slave_density d_mission d_capital dist_cap d_western using "./P23_MBF/original/ld/1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear
gen d_birth = d_birth_all
gen d_birth_bef_indep = d_age_prim_bef*d_birth
keep if d_birth_bef_indep!=.
local ctrl "age i_age_age d_female d_christian rural tse_r railway_density count_tribe slave_density d_mission d_capital dist_cap d_western"
tempname P
postfile `P' int dropped str20 term double b se N nclust using "`out'/s5_t2_loco.dta", replace
levelsof cntry_code, local(cs)
foreach c of local cs {
	capture noisily logit d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' i.cntry_code if cntry_code!=`c', vce(cluster id_birth)
	if _rc continue
	foreach t in d_birth d_birth_bef_indep {
		post `P' (`c') ("`t'") (_b[`t']) (_se[`t']) (e(N)) (e(N_clust))
	}
	lincom d_birth + d_birth_bef_indep
	post `P' (`c') ("pre_gap") (r(estimate)) (r(se)) (e(N)) (e(N_clust))
}
postclose `P'
use "`out'/s5_t2_loco.dta", clear
export delimited using "`out'/s5_t2_loco.csv", replace
list, clean
