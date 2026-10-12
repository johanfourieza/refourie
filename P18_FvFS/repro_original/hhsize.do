version 11
capture log close
do "./tools/paths.do"
log using hhsize_results.log, text replace
use "$DATA/P18_FvFS/original/Statafiles/opgaafrolle.dta", clear
gen hh = m + v + s + d
generate group = .
replace group = 0 if hug == 0
replace group = 1 if hug == 1 & wyns==0
replace group = 2 if hug == 1 & wyns==1

gen slaves = sm + sv + ss + sd

drop if jaar == 1682
drop if jaar == 1716

tabstat hh slaves k  wingst wyn kgw bste pd, by(group) stat(mean sd  n)

table jaar group [pw=hh], c(mean wyn)
log close
