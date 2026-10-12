* P23_MBF S6: the cell replica (sb_lib.do) at the same points as 01b_verify_fulldata.do (DEVIATIONS D1).
* 05_verdicts.R compares the two files; agreement must be exact.
* Usage: do 01c_replica_checkpoints.do <B>
version 16
clear all
set more off
set matsize 11000
global MOD "./P23_MBF/modern"
global SCR "./P23_MBF/modern/_scratch"
args BREPS
if "`BREPS'"=="" local BREPS 9999
do "$MOD/sb_lib.do"
use "$SCR/t2_hypinfo.dta", clear
mkmat info1 info2 info3, matrix(INFO)
use "$SCR/t2_hyp.dta", clear
mkmat R1 R2 R3 R4 R5 R6, matrix(RR)
local ctrl "age i_age_age d_female d_christian rural tse_r railway_density count_tribe slave_density d_mission d_capital dist_cap d_western"
use "$SCR/t2_cells_primary.dta", clear
sort id_birth
global FIT "logit d_primary d_birth d_birth_bef_indep d_age_prim_bef `ctrl' i.cntry_code [fw=n], vce(cluster id_birth) tolerance(1e-8) ltolerance(1e-10)"
quietly $FIT
estimates store UNR
forvalues h = 1/6 {
	matrix R`h' = RR[1...,`h']'
	matrix colnames R`h' = `: colfullnames e(b)'
}
tempname P
postfile `P' int h double r str8 null double p B using "$SCR/t2_replica_checkpoints_B`BREPS'.dta", replace
local pts "1 0 null|2 0 null|3 0 null|4 0 null|5 0 null|6 0 null|6 -4 null|4 6 null|1 0 nonull"
if `BREPS' > 9999 local pts "1 0 null|2 0 null|3 0 null|4 0 null|5 0 null|6 0 null"
tokenize "`pts'", parse("|")
local i = 1
while "``i''" != "" {
	if "``i''" != "|" {
		local h : word 1 of ``i''
		local k : word 2 of ``i''
		local nl : word 3 of ``i''
		local r = cond(`k'==0, 0, INFO[`h',1] + `k'*INFO[`h',2]/2)
		local opt = cond("`nl'"=="nonull", "nonull", "")
		quietly sb_test, rmat(R`h') r(`=INFO[`h',3] + `r'') clus(id_birth) fitcmd($FIT) wvar(n) b(`BREPS') `opt' recover
		post `P' (`h') (`r') ("`nl'") (r(p)) (`BREPS')
	}
	local ++i
}
postclose `P'
use "$SCR/t2_replica_checkpoints_B`BREPS'.dta", clear
export delimited using "$MOD/output/check_replica_B`BREPS'.csv", replace
list, clean
