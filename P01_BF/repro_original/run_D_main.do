* [ENV] run_D_main.do: lines 1649-1702 verbatim; data.dta substitutes for na110702.dta (lines 1653, 1698)
version 11
clear all
set more off
sysdir set PLUS "`c(pwd)'/ado/plus"
sysdir set PERSONAL "`c(pwd)'/ado/personal"
do "`c(pwd)'/../../tools/paths.do"
global S "$DATA/P01_BF/repro_original/_scratch"
global ORIG "$DATA/P01_BF/original/Baten Fourie"
global OUT "`c(pwd)'/output"
cd "$S"   // [ENV] outreg2 files (na1, na3, numeracy) are written to D: scratch
*-------------------
clear
set mem 500m
set more off
use "$ORIG/data.dta", clear   // [ENV] substitute for missing g:\a\na\na110702.dta
set more off
*it might be better to include the "oth_bl category, because otherwise the case numbers would look extremely small
xi: logit exactage female2 age23 i.bdec b_cn-b_oth_bl if age>22 & age<83  & bdec>=1650 & cyear~=.
mfx compute
* [ENV-extract] keep T6 marginal effects
matrix S2_T6_b = e(Xmfx_dydx)
matrix S2_T6_se = e(Xmfx_se_dydx)
scalar S2_T6_N = e(N)
scalar S2_T6_r2p = e(r2_p)
outreg2 using na1, mfx ctitle(numerate) nor2 addstat(Pseudo R2, e(r2_p)) addnote(Put your notes here.) word replace seeout noas pvalue
*xi: logit exactage female2 age23 bd_middle bd_post1790 b_id b_in b_oth_bl if age>22 & age<83  & bdec>=1650 & (b_mz | b_id | b_oth_bl | b_in) & cyear~=.
*mfx compute
*outreg2 using na2, mfx ctitle(numerate) nor2 addstat(Pseudo R2, e(r2_p)) addnote(Put your notes here.) word replace seeout pvalue
xi: logit exactage female2 age23 eur_early-za_post if age>22 & age<83  & cyear~=.
mfx compute
* [ENV-extract] keep interaction-logit marginal effects (xls col Q)
matrix S2_L3_b = e(Xmfx_dydx)
matrix S2_L3_se = e(Xmfx_se_dydx)
scalar S2_L3_N = e(N)
scalar S2_L3_r2p = e(r2_p)
outreg2 using na3, mfx ctitle(numerate) nor2 addstat(Pseudo R2, e(r2_p)) addnote(Put your notes here.) word replace seeout noas pvalue
*constant are chinese here
*and finally the linear prob model in order to obtain a constant:
xi: reg exactage female2 age23 eur_early-za_post if age>22 & age<83  & cyear~=.
estimates store S2_lpm   // [ENV-extract]
outreg2 using na3, ctitle(numerate) addnote(Put your notes here.) word replace seeout noas pvalue  stnum(replace coef=coef*125)
*constant are chinese here


xi: reg exactage female2 age23 eur_early-za_post if age>22 & age<83  & cyear~=., r
estimates store m1
outreg2 using numeracy, ctitle(numerate) nor2 word append seeout


*this is just to check whether the constant in fact refers to Chinese only
ta bco if eur_early	==0 & ///
eur_mid		==0 & ///
eur_post		==0 & ///
id_early		==0 & ///
id_mid		==0 & ///
in_early		==0 & ///
in_mid		==0 & ///
ko_early		==0 & ///
ko_mid		==0 & ///
ko_post		==0 & ///
mz_mid		==0 & ///
mz_post		==0 & ///
otb_early		==0 & ///
otb_mid		==0 & ///
otb_post		==0 & ///
za_mid		==0 & ///
za_post		==0 & age>22 & age~=. & cyear~=.


*------------this is for preparing the dummy variable interacting birth country and birth cohort
use "$ORIG/data.dta", clear   // [ENV] substitute for missing g:\a\na\na110702.dta
collapse (count) nc=age if age>22 & age<83, by(bco bcoh)
drop if nc<27
*edit
*reshape wide nc, i(bco) j(bcoh)
export delimited using "$OUT/T7_counts_bco_bcoh.csv", replace   // [ENV-extract]
* [ENV-extract] write all stored estimates to output/s2_estimates.csv (no analytic content)
file open fh using "$OUT/s2_estimates.csv", write replace
file write fh "model,term,b,se,n,stat" _n
foreach m in T6 L3 {
  local names : colnames S2_`m'_b
  local k = colsof(S2_`m'_b)
  forvalues j = 1/`k' {
    local t : word `j' of `names'
    file write fh "`m'_mfx,`t'," %20.12g (S2_`m'_b[1,`j']) "," %20.12g (S2_`m'_se[1,`j']) "," (S2_`m'_N) "," %12.8g (S2_`m'_r2p) _n
  }
}
foreach m in S2_lpm m1 {
  estimates restore `m'
  matrix B = e(b)
  matrix V = e(V)
  local names : colnames B
  local k = colsof(B)
  forvalues j = 1/`k' {
    local t : word `j' of `names'
    file write fh "`m',`t'," %20.12g (B[1,`j']) "," %20.12g (sqrt(V[`j',`j'])) "," (e(N)) "," %12.8g (e(r2)) _n
  }
}
file close fh
