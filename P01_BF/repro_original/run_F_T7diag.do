* [ENV-diagnostic, not original code] run_F_T7diag.do: Table 7 counts as the regression dummies define the cells (l.1610-1645), in the l.1699 sample and in the l.1662 estimation sample
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
use "$ORIG/data.dta", clear   // [ENV] substitute for missing g:\a\na\na110702.dta
foreach v of varlist eur_early-za_post {
  quietly count if `v'==1 & age>22 & age<83
  local a = r(N)
  quietly count if `v'==1 & age>22 & age<83 & cyear~=.
  display "S2T7 `v' " `a' " " r(N)
}
count if b_cn==1 & age>22 & age<83 & cyear~=.
display "S2T7 b_cn_est " r(N)
tab bco bcoh if age>22 & age<83
