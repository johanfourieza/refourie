* P23_MBF S6, step 0: build frequency-weighted cell files for Table 2 (DEVIATIONS D1) and the full-data benchmark.
* Reads the restricted IPUMS analysis file once; writes cell files to D: only and aggregate numbers to Dropbox.
version 16
clear all
set more off
set maxvar 10000
sysdir set PLUS "./P23_MBF/compare/s5/ado/plus"
sysdir set PERSONAL "./P23_MBF/compare/s5/ado/personal"
mata: mata mlib index
global MOD "./P23_MBF/modern"
global SCR "./P23_MBF/modern/_scratch"
local ctrl "age i_age_age d_female d_christian rural tse_r railway_density count_tribe slave_density d_mission d_capital dist_cap d_western"
use cntry_code id_birth tribe_co_1 d_primary d_birth_all d_age_prim_bef age i_age_age d_female d_christian rural tse_r railway_density count_tribe slave_density d_mission d_capital dist_cap d_western perwt religion yr_birth prim_in_plus2 prim_in_plus3 using "./P23_MBF/original/ld/1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear
gen d_birth = d_birth_all
gen d_birth_bef_indep = d_age_prim_bef*d_birth
keep if d_birth_bef_indep < .
drop d_birth_all
compress
* ---- full-data benchmark: published fit, tight tolerance, and two boottest calls (999 reps) used to verify the cell files
tempname P
postfile `P' str24 what double v using "$SCR/fulldata_bench.dta", replace
timer on 1
logit d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' i.cntry_code, vce(cluster id_birth) tolerance(1e-8) ltolerance(1e-10)
timer off 1
post `P' ("b1") (_b[d_birth])
post `P' ("b3") (_b[d_birth_bef_indep])
post `P' ("b2") (_b[d_age_prim_bef])
post `P' ("se1") (_se[d_birth])
post `P' ("se3") (_se[d_birth_bef_indep])
post `P' ("ll") (e(ll))
post `P' ("N") (e(N))
post `P' ("Nclust") (e(N_clust))
matrix B0 = e(b)
gen byte esamp = e(sample)
timer on 2
boottest d_birth, reps(999) seed(20261011) weight(webb) nograph noci
timer off 2
post `P' ("p_b1_999") (r(p))
boottest (d_birth_bef_indep = 0.1), reps(999) seed(20261011) weight(webb) nograph noci
post `P' ("p_b3eq0.1_999") (r(p))
timer list
post `P' ("t_fit") (r(t1))
post `P' ("t_boot") (r(t2))
postclose `P'
* ---- cell files (estimation sample only)
keep if esamp
drop esamp
gen byte one = 1
preserve
collapse (sum) n=one, by(d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' cntry_code id_birth) fast
compress
count
save "$SCR/t2_cells_primary.dta", replace
restore
collapse (sum) n=one sumperwt=perwt, by(d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' cntry_code id_birth tribe_co_1 religion yr_birth prim_in_plus2 prim_in_plus3) fast
compress
count
save "$SCR/t2_cells_ext.dta", replace
use "$SCR/fulldata_bench.dta", clear
export delimited using "$MOD/output/check_fulldata_bench.csv", replace
list, clean noobs
