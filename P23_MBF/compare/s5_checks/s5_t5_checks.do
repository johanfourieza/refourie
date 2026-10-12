* S5 checks, Table 5 (headline T5_mission_c4). Not original code. Open data (Murdock/ALTT/GIS aggregates).
version 16
clear all
set more off
sysdir set PLUS "./P23_MBF/compare/s5/ado/plus"
local out "./P23_MBF/compare/s5"
import delimited "./P23_MBF/original/ld/1_murdock_capital_population_final.csv", clear
count
count if missing(d_mission)
tab d_mission, missing
use "./P23_MBF/original/ld/1_murdockanddbirth_final.dta", clear
count
tab iso2, missing
tab d_birth d_mission, missing
tab d_birth d_capital, missing
tempname P
postfile `P' str48 scenario double b se p N n_pos using "`out'/s5_t5_results.dta", replace
local geo4 "lat lon coast river meanalt tsi meantemp"
local pre "centralization agricintensity d_settlement hierarchy pop1800 d_slavery"
* original col 4 and A' col 4
logit d_birth d_mission `geo4' `pre' i.iso2, vce(robust)
count if e(sample) & d_birth==1
post `P' ("T5c4_original_code") (_b[d_mission]) (_se[d_mission]) (2*normal(-abs(_b[d_mission]/_se[d_mission]))) (e(N)) (r(N))
logit d_birth d_mission `geo4' `pre' d_capital i.iso2, vce(robust)
gen byte s4 = e(sample)
count if s4 & d_birth==1
local npos = r(N)
post `P' ("T5c4_Aprime_with_d_capital") (_b[d_mission]) (_se[d_mission]) (2*normal(-abs(_b[d_mission]/_se[d_mission]))) (e(N)) (`npos')
tab d_birth d_mission if s4
tab iso2 d_birth if s4
margins, dydx(d_mission)
matrix M = r(table)
post `P' ("T5c4_Aprime_AME_prob") (M[1,1]) (M[2,1]) (M[4,1]) (e(N)) (`npos')
* sample-restriction decomposition: col 1 and col 2 specs on col 4 sample
logit d_birth d_mission if s4, vce(robust)
post `P' ("T5c1_spec_on_c4_sample") (_b[d_mission]) (_se[d_mission]) (2*normal(-abs(_b[d_mission]/_se[d_mission]))) (e(N)) (`npos')
logit d_birth d_mission i.iso2 if s4, vce(robust)
post `P' ("T5c2_spec_on_c4_sample") (_b[d_mission]) (_se[d_mission]) (2*normal(-abs(_b[d_mission]/_se[d_mission]))) (e(N)) (`npos')
* LPM on same sample
reg d_birth d_mission `geo4' `pre' d_capital i.iso2 if s4, vce(robust)
post `P' ("T5c4_LPM_same_sample") (_b[d_mission]) (_se[d_mission]) (2*ttail(e(df_r),abs(_b[d_mission]/_se[d_mission]))) (e(N)) (`npos')
* LPM on all regions with complete controls (no perfect-prediction drops)
reg d_birth d_mission `geo4' `pre' d_capital i.iso2, vce(robust)
count if e(sample) & d_birth==1
post `P' ("T5c4_LPM_all_complete") (_b[d_mission]) (_se[d_mission]) (2*ttail(e(df_r),abs(_b[d_mission]/_se[d_mission]))) (e(N)) (r(N))
* Firth penalised logit
quietly tab iso2, gen(cty_)
local ctys ""
foreach v of varlist cty_* {
	quietly su `v' if s4
	if r(max)>0 & r(min)==0 local ctys "`ctys' `v'"
}
capture noisily firthlogit d_birth d_mission `geo4' `pre' d_capital `ctys' if s4
if !_rc post `P' ("T5c4_Firth_same_sample") (_b[d_mission]) (_se[d_mission]) (2*normal(-abs(_b[d_mission]/_se[d_mission]))) (e(N)) (`npos')
* Firth on all complete-case regions (country dummies that predict failure kept)
egen cc = rownonmiss(d_birth d_mission `geo4' `pre' d_capital)
local ctys2 ""
foreach v of varlist cty_* {
	quietly su `v' if cc==16
	if r(max)>0 & r(min)==0 local ctys2 "`ctys2' `v'"
}
capture noisily firthlogit d_birth d_mission `geo4' `pre' d_capital `ctys2' if cc==16
if !_rc {
	quietly count if e(sample) & d_birth==1
	post `P' ("T5c4_Firth_all_complete") (_b[d_mission]) (_se[d_mission]) (2*normal(-abs(_b[d_mission]/_se[d_mission]))) (e(N)) (r(N))
}
* leave-one-country-out on A' col 4
levelsof iso2 if s4 & d_birth==1, local(cs)
foreach c of local cs {
	capture noisily logit d_birth d_mission `geo4' `pre' d_capital i.iso2 if iso2!=`c', vce(robust)
	if !_rc post `P' ("T5c4_Aprime_drop_iso2_`c'") (_b[d_mission]) (_se[d_mission]) (2*normal(-abs(_b[d_mission]/_se[d_mission]))) (e(N)) (.)
}
postclose `P'
use "`out'/s5_t5_results.dta", clear
export delimited using "`out'/s5_t5_results.csv", replace
list, clean
