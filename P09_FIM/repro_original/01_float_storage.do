* P09_FIM S2 (EARLIER-VERSION run): environment step 2 of 2.
* haven writes numeric variables as double; Stata's default storage type for data
* entered by paste/import (set type float) is float. The 2015 .dta does not survive.
* Evidence that the 2015 runs used float: their truncreg N equals the OLS N
* (Martine sheet 3917/3917; Regressionfinal spec 5 5490 vs OLS 5502 with age),
* which happens only if the 218 heights of exactly 160.02 cm (63 in) are stored
* as float(160.02) > 160.02 and so lie above ll(160.02). See PATCHES.md E5.
* Run from P09_FIM/repro_original/logs
do "../../../tools/paths.do"
use "$DATA/P09_FIM/repro_original/_scratch/whiteliving2015.dta", clear
foreach v of varlist _all {
    capture confirm numeric variable `v'
    if !_rc recast float `v', force
}
describe, short
save "$DATA/P09_FIM/repro_original/_scratch/whiteliving2015.dta", replace
