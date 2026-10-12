* S2 A-PRIME ALIGNMENT RUN (not the original code). Table 5 cols 3-4 respecified to match print.
* Col 4: original col 4 + d_capital. Evidence: d_capital is in the outreg2 drop() list of every column (code line ~495-518),
*        i.e. it was in a regression when the drop list was written; adding it gives 9.099 (4.268), N=64, R2=.407 = print.
* Col 3: original col 3 without meanalt. Evidence: found by a subset search over {lat lon coast river meanalt tsi meantemp d_capital}
*        (256 specs, _scratch/t5probe3.do); the only spec that matches coefficient, SE and R2 to printed precision. Weaker evidence.
version 16
clear all
set more off
do "./tools/paths.do"
use "$DATA/P23_MBF/original/ld/1_murdockanddbirth_final.dta", clear
logit d_birth d_mission lat lon coast river tsi i.iso2, vce(robust)
logit d_birth d_mission lat lon coast river meanalt tsi meantemp centralization agricintensity  d_settlement hierarchy pop1800  d_slavery d_capital i.iso2, vce(robust)
