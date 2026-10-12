* P12_FJ S6 03b_score_boot.do -- sensitivity 5: score wild cluster bootstrap (Kline-Santos) after logit, vce(cluster town),
* null imposed, Webb weights, B = 999, seed 20261012, Bonferroni levels (98.75 family R; 98.333 family U). Reads D: export of 03_sensitivities.R.
clear all
set more off
local md "./P12_FJ/modern"
local scr "./P12_FJ/modern/_scratch"
net set ado "`md'/ado"
adopath ++ "`md'/ado"
cap which boottest
if _rc ssc install boottest
which boottest
do "`scr'/vars.do"
use "`scr'/primary.dta", clear
tempname h
postfile `h' str4 spec str40 hyp double(est p lo hi level) using "`scr'/score_boot.dta", replace
foreach sp in 2 3 {
    logit doc Coloured Black Pandemic CxP BxP ${X`sp'} i.towni, vce(cluster towni)
    foreach t in CxP BxP {
        local b = _b[`t']
        boottest `t', weight(webb) reps(999) seed(20261012) level(98.75) nograph
        matrix C = r(CI)
        post `h' ("c`sp'") ("`t'") (`b') (r(p)) (C[1,1]) (C[1,2]) (98.75)
    }
    if `sp' == 3 {
        foreach t in P_Street Street {
            local b = _b[`t']
            boottest `t', weight(webb) reps(999) seed(20261012) level(98.3333) nograph
            matrix C = r(CI)
            post `h' ("c3") ("`t'") (`b') (r(p)) (C[1,1]) (C[1,2]) (98.3333)
        }
        local b = _b[Street] + _b[P_Street]
        boottest (Street + P_Street = 0), weight(webb) reps(999) seed(20261012) level(98.3333) nograph
        matrix C = r(CI)
        post `h' ("c3") ("theta_U") (`b') (r(p)) (C[1,1]) (C[1,2]) (98.3333)
    }
}
postclose `h'
use "`scr'/score_boot.dta", clear
list
export delimited using "`md'/output/sens05_score_boot.csv", replace
