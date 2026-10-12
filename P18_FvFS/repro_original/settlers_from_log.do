* settlers_from_log.do
* Reconstruction of the regression block of Dieter von Fintel's settlers.do (run 22 Nov 2010,
* log results.zip/exclpc/settlers_excl_1.smcl).
*
* IMPORTANT: the surviving log does NOT echo commands (settlers.do was run quietly; the log
* contains only "(n real changes made)", "(n observations deleted)" and outreg2 file notes).
* The commands below are therefore reconstructed from (i) the observation counts in the log
* (4,305 deleted -> 8 census years, N = 5,938; 4,455 deleted -> Huguenot sub-sample, N = 1,483),
* (ii) the regressor lists and column names of the 40 outreg2 .xls/.tex files, and
* (iii) the variables in final_excl_1.dta (saved by the run). Every specification choice was
* verified against the outreg2 output (see compare_2010log.csv); none was tuned to the paper.
* Not reconstructed: the data-construction block that built final_excl_1.dta (raw input absent).
* The q*/fq*/nfq* outputs contain no estimates of their own (each column repeats the stored
* 1773 wheat estimates; see PATCHES.md), so they are not re-run.
* Environment patches: paths; outreg2 replaced by postfile export (outreg2 not installed).
version 11
clear all
set more off
capture log close
do "./tools/paths.do"
log using settlers_from_log_results.log, text replace
local DATA "$DATA/P18_FvFS/repro_original/extracted/results/exclpc/final_excl_1.dta"

tempname P
postfile `P' str20 family int year str40 term double b se N r2 F using "$DATA/P18_FvFS/repro_original/settlers_from_log_est.dta", replace
capture program drop postit
program define postit
    args P family year
    tempname B V
    matrix `B' = e(b)
    matrix `V' = e(V)
    local names : colfullnames `B'
    local k = 0
    foreach t of local names {
        local ++k
        post `P' ("`family'") (`year') ("`t'") (`B'[1,`k']) (sqrt(`V'[`k',`k'])) (e(N)) (e(r2)) (e(F))
    }
end

use "`DATA'", clear
* log: "(4305 observations deleted)" -> keep the eight census years of Table 2
keep if inlist(year,1700,1709,1719,1731,1741,1752,1757,1773)
foreach y in 1700 1709 1719 1731 1741 1752 1757 1773 {
    * wine_anova / wheat_anova: group dummies only, household-size analytic weights, robust SE
    qui reg l_wine_zero i.group if year==`y' [aw=hhsize], robust
    postit `P' wine_anova `y'
    qui reg l_wheat_reaped_zero i.group if year==`y' [aw=hhsize], robust
    postit `P' wheat_anova `y'
    * wine_capital: xi: i.group*total_slaves i.group*knechts i.group*vines_planted + controls
    qui reg l_wine_zero i.group##c.total_slaves i.group##c.knechts i.group##c.vines_planted ///
        cattle wheat_reaped horses ib3.district i.marital if year==`y' [aw=hhsize], robust
    postit `P' wine_capital `y'
    qui reg l_wheat_reaped_zero i.group##c.total_slaves i.group##c.knechts i.group##c.wheat_sown ///
        cattle wine horses ib3.district i.marital if year==`y' [aw=hhsize], robust
    postit `P' wheat_capital `y'
}
* log: "(4455 observations deleted)" -> Huguenot sub-sample (base = NWH; marital base = married to WH)
keep if group>1
foreach y in 1700 1709 1719 1731 1741 1752 1757 1773 {
    qui reg l_wine_zero ib2.group if year==`y' [aw=hhsize], robust
    postit `P' fwine_anova `y'
    qui reg l_wheat_reaped_zero ib2.group if year==`y' [aw=hhsize], robust
    postit `P' fwheat_anova `y'
    qui reg l_wine_zero ib2.group##c.total_slaves ib2.group##c.knechts ib2.group##c.vines_planted ///
        cattle wheat_reaped horses ib3.district ib2.marital if year==`y' [aw=hhsize], robust
    postit `P' fwine_capital `y'
    qui reg l_wheat_reaped_zero ib2.group##c.total_slaves ib2.group##c.knechts ib2.group##c.wheat_sown ///
        cattle wine horses ib3.district ib2.marital if year==`y' [aw=hhsize], robust
    postit `P' fwheat_capital `y'
    * nf*: adds non-numeracy and born abroad (sample shrinks to non-missing numeracy)
    qui reg l_wine_zero ib2.group##c.total_slaves ib2.group##c.knechts ib2.group##c.vines_planted ///
        cattle wheat_reaped horses ib3.district ib2.marital nonnumeracy firstarrivals if year==`y' [aw=hhsize], robust
    postit `P' nfwine_capital `y'
    qui reg l_wheat_reaped_zero ib2.group##c.total_slaves ib2.group##c.knechts ib2.group##c.wheat_sown ///
        cattle wine horses ib3.district ib2.marital nonnumeracy firstarrivals if year==`y' [aw=hhsize], robust
    postit `P' nfwheat_capital `y'
}
postclose `P'
use "$DATA/P18_FvFS/repro_original/settlers_from_log_est.dta", clear
export delimited using settlers_from_log_est.csv, replace
log close
