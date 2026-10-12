* P23_MBF S6: verification of DEVIATIONS D1. Runs boottest itself (literal card §4A call) on the 5,077,010
* individual rows at the verdict-deciding points p_h(0), h = 1..6, at two interior inversion points and one
* unrestricted (nonull) call. 05_verdicts.R compares these with the cell replica (must agree exactly).
* Writes aggregate p-values only.
version 16
clear all
set more off
set matsize 11000
sysdir set PLUS "./P23_MBF/compare/s5/ado/plus"
sysdir set PERSONAL "./P23_MBF/compare/s5/ado/personal"
mata: mata mlib index
global MOD "./P23_MBF/modern"
global SCR "./P23_MBF/modern/_scratch"
args BREPS
if "`BREPS'"=="" local BREPS 9999
* hypothesis vectors from 01_t2_inference.do
use "$SCR/t2_hyp.dta", clear
local K = _N
forvalues h = 1/6 {
	local expr`h' ""
	forvalues j = 1/`K' {
		local nm = coef[`j']
		local v = R`h'[`j']
		if `v' != 0 & !(strpos("`nm'", "o.") | strpos("`nm'", "b.")) {
			local cf = strofreal(`v', "%21.0g")
			if "`expr`h''"!="" local expr`h' "`expr`h'' +"
			local expr`h' "`expr`h'' `cf'*[d_primary]`nm'"
		}
	}
}
use "$SCR/t2_hypinfo.dta", clear
forvalues h = 1/6 {
	local rhat`h' = info1[`h']
	local s`h' = info2[`h']
	local off`h' = info3[`h']
}
local ctrl "age i_age_age d_female d_christian rural tse_r railway_density count_tribe slave_density d_mission d_capital dist_cap d_western"
use cntry_code id_birth d_primary d_birth_all d_age_prim_bef age i_age_age d_female d_christian rural tse_r railway_density count_tribe slave_density d_mission d_capital dist_cap d_western using "./P23_MBF/original/ld/1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear
gen d_birth = d_birth_all
gen d_birth_bef_indep = d_age_prim_bef*d_birth
keep if d_birth_bef_indep < .
logit d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' i.cntry_code, vce(cluster id_birth) tolerance(1e-8) ltolerance(1e-10)
tempname P
postfile `P' int h double r str8 null double p B using "$SCR/t2_verify_fulldata_B`BREPS'.dta", replace
* points: (h, r, null)
local pts "1 0 null|2 0 null|3 0 null|4 0 null|5 0 null|6 0 null|6 -4 null|4 6 null|1 0 nonull"
* at 99,999 draws only the six verdict-deciding p_h(0) are verified
if `BREPS' > 9999 local pts "1 0 null|2 0 null|3 0 null|4 0 null|5 0 null|6 0 null"
local npts : word count `pts'
tokenize "`pts'", parse("|")
local i = 1
while "``i''" != "" {
	if "``i''" != "|" {
		local h : word 1 of ``i''
		local k : word 2 of ``i''
		local nl : word 3 of ``i''
		local r = cond(`k'==0, 0, `rhat`h'' + `k'*`s`h''/2)
		local c = `off`h'' + `r'
		local cs = strofreal(`c', "%21.0g")
		local opt = cond("`nl'"=="nonull", "nonull", "")
		timer clear 1
		timer on 1
		capture noisily boottest (`expr`h'' = `cs'), reps(`BREPS') seed(20261011) weight(webb) ptype(symmetric) nograph noci `opt'
		timer off 1
		quietly timer list 1
		if !_rc post `P' (`h') (`r') ("`nl'") (r(p)) (`BREPS')
		else post `P' (`h') (`r') ("`nl'") (.) (`BREPS')
		di as res "VERIFY h`h' r=`r' `nl' p=" r(p) " time=" r(t1)
	}
	local ++i
}
postclose `P'
use "$SCR/t2_verify_fulldata_B`BREPS'.dta", clear
export delimited using "$MOD/output/check_fulldata_boottest_B`BREPS'.csv", replace
list, clean
