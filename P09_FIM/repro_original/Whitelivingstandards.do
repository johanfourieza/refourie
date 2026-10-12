*Use Whitelivingstandards dataset
* --- S2 ENVIRONMENT PATCH (P09_FIM, EARLIER-VERSION run; see PATCHES.md) ---
version 13
clear all
set more off
adopath ++ "../../ado"
do "../../../../tools/paths.do"
use "$DATA/P09_FIM/repro_original/_scratch/whiteliving2015.dta", clear
* --- end patch ---

*Stata clean-up

drop if repeat==1
drop if age<20
drop if year<1890
drop if year>1920
drop if year==19.5
drop if birthyear<1858
drop if birthyear>1897


*Summary statistics: Global

tabstat height weight age sadummy afrikaans, by(birthyear) stat(mean)
tabstat height weight age sadummy afrikaans, by(birthyear) stat(n)

tabstat height weight age, by(nationalitydum) stat(mean)

tabstat height weight age, by(hisco) stat(mean)

histogram height

*Summary statistics: SA

tabstat height weight age afrikaans if age>19 & sadummy==1 & birthyear>1864 & birthyear<1891, by(birthyear) stat(mean)

*Note the heaping of birthyear!!!

twoway (scatter height birthyear if age>19 & sadummy==1 & birthyear>1864 & birthyear<1891) (lfitci height birthyear  if age>19 & sadummy==1 & birthyear>1864 & birthyear<1891), xtitle(" ") legend(order(1 "Obs" 3 "Linear fit" 2 "95% CI")) 

*No trend. Interpretation: there was no immediate impact of the discovery of minerals on white South Africans' living standards...

*Are there regional differences?

twoway (lfitci height birthyear if age>19 & regiondum==0 & birthyear>1864 & birthyear<1891) (lfitci height birthyear if age>19 & regiondum==1 & birthyear>1864 & birthyear<1891), xtitle(" ") legend(order(2 "Western Cape" 3 "Eastern Cape" 1 "95% CI")) 

*Yes! Western Cape seems to decline while Eastern Cape stays the same. Divergence in heights between the two regions...

*White South Africans were already rich, at least those that signed up for the military

*Trend is the same for British, although from a lower base

twoway (lfitci height birthyear  if age>19 & sadummy==1 & birthyear>1864 & birthyear<1891) (lfitci height birthyear  if age>19 & sadummy==0 & birthyear>1864 & birthyear<1891), xtitle(" ") legend(order(2 "Western Cape" 3 "Eastern Cape" 1 "95% CI")) 

preserve

collapse (mean) height_mean = height (semean) height_se =  height, by(regiondum)
gen height_upper = height_mean+1.96*height_se
gen height_lower = height_mean-1.96*height_se
label  define regiondum 0 "WC" 1 "EC"  2 "NC" 3 "Natal" 4 "OFS" 5 "Tvl"
label value regiondum regiondum
twoway (scatter height_mean regiondum) (rcap height_upper height_lower regiondum), xlabel(0(1)5, valuelabel) xtitle(" ") legend(order(1 "Mean" 2 "Confidence Interval (95%)"))

restore


preserve

collapse (mean) height_mean = height (semean) height_se =  height, by(nationalitydum)
gen height_upper = height_mean+1.96*height_se
gen height_lower = height_mean-1.96*height_se
drop if nationalitydum==5
label  define nationalitydum 0 "British" 1 "American"  2 "Australian" 3 "European" 4 "SA"
label value nationalitydum nationalitydum
twoway (scatter height_mean nationality) (rcap height_upper height_lower nationality), xlabel(0(1)4, valuelabel) xtitle(" ") legend(order(1 "Mean" 2 "Confidence Interval (95%)"))

restore

preserve

collapse (mean) height_mean = height (semean) height_se =  height, by(afridum)
gen height_upper = height_mean+1.96*height_se
gen height_lower = height_mean-1.96*height_se
label  define afridum 0 "British" 1 "American"  2 "Australian" 3 "European" 4 "SA English" 5 "SA Afrikaans"
label value afridum afridum
twoway (scatter height_mean afridum) (rcap height_upper height_lower afridum), xlabel(0(1)5, valuelabel) xtitle(" ") legend(order(1 "Mean" 2 "Confidence Interval (95%)"))
restore


*Regression analysis

*Farmers are tallest in South Africa, even than other occupations

*Compare occupations in England and South Africa:

truncreg height ib1880.birthyear ib6.hisco i.sourcedum i.regiondum i.year afrikaans if sadummy==1 & birthyear>1864 & birthyear<1891 & year>1887 & year<1911 & age>19, ll(167.64)

estimates clear

eststo: quietly truncreg height afrikaans i.regiondum if sadummy==1 & birthyear>1864 & birthyear<1891 & year>1887 & year<1911 & age>19, ll(167.64)
eststo: quietly truncreg height afrikaans i.regiondum i.sourcedum if sadummy==1 & birthyear>1864 & birthyear<1891 & year>1887 & year<1911 & age>19, ll(167.64)
eststo: quietly truncreg height afrikaans i.regiondum i.sourcedum ib6.hisco if sadummy==1 & birthyear>1864 & birthyear<1891 & year>1887 & year<1911 & age>19, ll(167.64)
eststo: quietly truncreg height afrikaans i.regiondum i.sourcedum ib6.hisco ib1880.birthyear  i.year if sadummy==1 & birthyear>1864 & birthyear<1891 & year>1887 & year<1911 & age>19, ll(167.64)
estout using whiteliving.txt, cells(b(star fmt(3)) t(par fmt(2))) stats(r2 N)

estimates clear


estimates clear

eststo: quietly truncreg height i.nationalitydum if birthyear>1864 & birthyear<1891 & year>1887 & year<1911 & age>19, ll(167.64)
eststo: quietly truncreg height i.nationalitydum i.sourcedum if birthyear>1864 & birthyear<1891 & year>1887 & year<1911 & age>19, ll(167.64)
eststo: quietly truncreg height i.nationalitydum i.sourcedum ib6.hisco afrikaans if birthyear>1864 & birthyear<1891 & year>1887 & year<1911 & age>19, ll(167.64)
eststo: quietly truncreg height i.nationalitydum i.sourcedum ib6.hisco afrikaans ib1880.birthyear i.year if birthyear>1864 & birthyear<1891 & year>1887 & year<1911 & age>19, ll(167.64)
estout using whiteliving2.txt, cells(b(star fmt(3)) t(par fmt(2))) stats(r2 N)

estimates clear


*Creating class
gen classdum = .
replace classdum = 1 if hisco==1 & nationalitydum==0 | hisco==2 & nationalitydum==0 | hisco==3 & nationalitydum==0 | hisco==4 & nationalitydum==0 | hisco==5 & nationalitydum==0
replace classdum = 2 if hisco==6 & nationalitydum==0
replace classdum = 3 if hisco==7 & nationalitydum==0 | hisco==8 & nationalitydum==0 | hisco==9 & nationalitydum==0
replace classdum = 4 if hisco==1 & sadummy==1 & afrikaans==0 | hisco==2 & sadummy==1 & afrikaans==0 | hisco==3 & sadummy==1 & afrikaans==0 | hisco==4 & sadummy==1 & afrikaans==0 | hisco==5 & sadummy==1 & afrikaans==0
replace classdum = 5 if hisco==6 & sadummy==1 & afrikaans==0
replace classdum = 6 if hisco==7 & sadummy==1 & afrikaans==0 | hisco==8 & sadummy==1 & afrikaans==0 | hisco==9 & sadummy==1 & afrikaans==0
replace classdum = 7 if hisco==1 & sadummy==1 & afrikaans==1 | hisco==2 & sadummy==1 & afrikaans==1 | hisco==3 & sadummy==1 & afrikaans==1 | hisco==4 & sadummy==1 & afrikaans==1 | hisco==5 & sadummy==1 & afrikaans==1
replace classdum = 8 if hisco==6 & sadummy==1 & afrikaans==1
replace classdum = 9 if hisco==7 & sadummy==1 & afrikaans==1 | hisco==8 & sadummy==1 & afrikaans==1 | hisco==9 & sadummy==1 & afrikaans==1

preserve

collapse (mean) height_mean = height (semean) height_se =  height, by(classdum)
gen height_upper = height_mean+1.96*height_se
gen height_lower = height_mean-1.96*height_se
label  define classdum 1 "UC: Britain" 2 "F: Britain"  3 "LC: Britain" 4 "UC: English SA" 5 "F: English SA"  6 "LC: English SA" 7 "UC: Afrikaans SA" 8 "F: Afrikaans SA"  9 "LC: Afrikaans SA"
label value classdum classdum
twoway (scatter height_mean classdum) (rcap height_upper height_lower classdum), xlabel(1(1)9, valuelabel) xtitle(" ") legend(order(1 "Mean" 2 "Confidence Interval (95%)"))
restore
