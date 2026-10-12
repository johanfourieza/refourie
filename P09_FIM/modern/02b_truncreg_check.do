* P09_FIM S6 02b_truncreg_check.do. Card §4B Stata cross-check of the R primary; also S1 (anchor) and S10
* (observation-specific truncation via ll(varname)). Data on D: (A6); writes coefficients to modern/output.
version 19
clear all
set more off
do "./tools/paths.do"
local out "./P09_FIM/modern/output"
use "$DATA/P09_FIM/modern/_scratch/p09_stata_check.dta", clear
recast double height
tempname fh
file open `fh' using "`out'/stata_check.csv", write replace
file write `fh' "model,term,est,se,N,ll" _n

capture program drop dump
program define dump
    args fh model
    matrix b = e(b)
    matrix V = e(V)
    local names : colfullnames b
    local i = 1
    foreach nm of local names {
        file write `fh' "`model',`nm'," %21.0g (b[1,`i']) "," %21.0g (sqrt(V[`i',`i'])) "," (e(N)) "," %21.0g (e(ll)) _n
        local ++i
    }
end

* Primary: sample h >= c + 0.001, ll(159.385), robust
preserve
keep if height >= 159.385 + 0.001
truncreg height c65 c75 c95 c05 c15 fSAC fCMP fAOF fWWII g21 g22, ll(159.385) vce(robust)
dump `fh' primary
restore

* S1 anchor: cohort + Attestation, heights at 63 in kept, ll(160.0199)
preserve
keep if height >= 160.02 - 0.001
truncreg height c65 c75 c95 c05 c15 attest, ll(160.0199) vce(robust)
dump `fh' s1_anchor
restore

* S10 shrinkage grid: h* = h + s*max(0, age-35), c_i = 159.385 + s*max(0, age-35)
foreach s in 0.05 0.10 {
    preserve
    keep if height >= 159.385 + 0.001
    gen double hstar = height + `s' * max(0, age - 35)
    gen double ci = 159.385 + `s' * max(0, age - 35)
    truncreg hstar c65 c75 c95 c05 c15 fSAC fCMP fAOF fWWII g21 g22, ll(ci) vce(robust)
    dump `fh' s10_`s'
    restore
}
file close `fh'
