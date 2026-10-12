* S5 check: wild cluster score bootstrap (Kline-Santos) for Table 2 col 4; 29 treated of 624 clusters. Not original code.
version 16
clear all
set more off
sysdir set PLUS "./P23_MBF/compare/s5/ado/plus"
sysdir set PERSONAL "./P23_MBF/compare/s5/ado/personal"
mata: mata mlib index
local out "./P23_MBF/compare/s5"
use cntry_code id_birth d_primary d_birth_all d_age_prim_bef age i_age_age d_female d_christian rural tse_r railway_density count_tribe slave_density d_mission d_capital dist_cap d_western using "./P23_MBF/original/ld/1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear
gen d_birth = d_birth_all
gen d_birth_bef_indep = d_age_prim_bef*d_birth
keep if d_birth_bef_indep!=.
local ctrl "age i_age_age d_female d_christian rural tse_r railway_density count_tribe slave_density d_mission d_capital dist_cap d_western"
tempname P
postfile `P' str40 scenario str24 term double b p N nclust using "`out'/s5_t2_wildboot.dta", replace
logit d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' i.cntry_code, vce(cluster id_birth)
foreach h in "d_birth" "d_birth_bef_indep" "d_birth + d_birth_bef_indep" {
	capture noisily boottest `h', reps(999) seed(20261011) weight(webb) nograph
	if !_rc post `P' ("S5_score_wildboot_webb") ("`h'") (.) (r(p)) (e(N)) (e(N_clust))
}
postclose `P'
use "`out'/s5_t2_wildboot.dta", clear
export delimited using "`out'/s5_t2_wildboot.csv", replace
list, clean
