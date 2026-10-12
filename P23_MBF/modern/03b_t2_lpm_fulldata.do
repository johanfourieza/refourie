* P23_MBF S6 sensitivity 10 (card §5): linear probability model with the Table 2 col 4 regressors, boottest WCR
* (OLS, Webb, B = 9,999, seed 20261011) on the 5,077,010 individual rows. Writes aggregate results only.
version 16
clear all
set more off
sysdir set PLUS "./P23_MBF/compare/s5/ado/plus"
sysdir set PERSONAL "./P23_MBF/compare/s5/ado/personal"
mata: mata mlib index
global MOD "./P23_MBF/modern"
global SCR "./P23_MBF/modern/_scratch"
local ctrl "age i_age_age d_female d_christian rural tse_r railway_density count_tribe slave_density d_mission d_capital dist_cap d_western"
use cntry_code id_birth d_primary d_birth_all d_age_prim_bef age i_age_age d_female d_christian rural tse_r railway_density count_tribe slave_density d_mission d_capital dist_cap d_western using "./P23_MBF/original/ld/1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear
gen d_birth = d_birth_all
gen d_birth_bef_indep = d_age_prim_bef*d_birth
keep if d_birth_bef_indep < .
regress d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' i.cntry_code, vce(cluster id_birth)
tempname P
postfile `P' str40 term double est se_cr1 p_cr1 p_wcr N G using "$SCR/t2_lpm.dta", replace
local hs `" "d_birth" "d_birth_bef_indep" "d_birth + d_birth_bef_indep" "d_age_prim_bef + d_birth_bef_indep" "'
foreach h of local hs {
	quietly lincom `h'
	local est = r(estimate)
	local se = r(se)
	local pc = r(p)
	boottest (`h' = 0), reps(9999) seed(20261011) weight(webb) ptype(symmetric) nograph noci
	post `P' ("`h'") (`est') (`se') (`pc') (r(p)) (e(N)) (e(N_clust))
}
postclose `P'
use "$SCR/t2_lpm.dta", clear
export delimited using "$MOD/output/t2_lpm_raw.csv", replace
list, clean
