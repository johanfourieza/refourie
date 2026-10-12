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
drop if birthyear<1865
drop if birthyear>1895
keep if sadummy==1
drop if age>55
gen boer = 0
replace boer = 1 if regiondum==4 | regiondum==5
keep if sadummy==1
drop if black == 1

*Summary statistics

tab birthyear source
tabstat height afrikaans age urban black, by(birthyear)
histogram height

tabstat height weight age sadummy afrikaans, by(birthyear) stat(mean)
tabstat height weight age sadummy afrikaans, by(birthyear) stat(n)

tabstat height weight age, by(nationalitydum) stat(mean)

tabstat height weight age, by(hisco) stat(mean)


*Only whites
preserve

drop if black == 1
collapse (mean) height_mean = height (semean) height_se =  height, by(regiondum)
gen height_upper = height_mean+1.96*height_se
gen height_lower = height_mean-1.96*height_se
label  define regiondum 0 "WC" 1 "EC"  2 "NC" 3 "Natal" 4 "OFS" 5 "Tvl"
label value regiondum regiondum
twoway (scatter height_mean regiondum) (rcap height_upper height_lower regiondum), xlabel(0(1)5, valuelabel) xtitle(" ") legend(order(1 "Mean" 2 "Confidence Interval (95%)"))

restore

preserve

drop if black == 0
collapse (mean) height_mean = height (semean) height_se =  height, by(regiondum)
gen height_upper = height_mean+1.96*height_se
gen height_lower = height_mean-1.96*height_se
label  define regiondum 0 "WC" 1 "EC"  2 "NC" 3 "Natal" 4 "OFS" 5 "Tvl"
label value regiondum regiondum
twoway (scatter height_mean regiondum) (rcap height_upper height_lower regiondum), xlabel(0(1)5, valuelabel) xtitle(" ") legend(order(1 "Mean" 2 "Confidence Interval (95%)"))

restore

*Only Afrikaans and white

preserve

drop if black == 1
keep if urban == 0
collapse (mean) height_mean = height (semean) height_se =  height, by(regiondum)
gen height_upper = height_mean+1.96*height_se
gen height_lower = height_mean-1.96*height_se
label  define regiondum 0 "WC" 1 "EC"  2 "NC" 3 "Natal" 4 "OFS" 5 "Tvl"
label value regiondum regiondum
twoway (scatter height_mean regiondum) (rcap height_upper height_lower regiondum), xlabel(0(1)5, valuelabel) xtitle(" ") legend(order(1 "Mean" 2 "Confidence Interval (95%)"))

restore

twoway (lfitci height birthyear if regiondum==0) (lfitci height birthyear  if boer==1), xtitle(" ") legend(order(2 "Western Cape" 3 "Boer Republics" 1 "95% CI")) 


*Regression

estimates clear

eststo: quietly truncreg height ib3.sourcedum, ll(160.02)
eststo: quietly truncreg height ib3.sourcedum	i.regiondum, ll(160.02)
eststo: quietly truncreg height ib3.sourcedum	i.regiondum	age	afrikaans urban, ll(160.02)
eststo: quietly truncreg height ib3.sourcedum	i.regiondum	age	afrikaans urban ib6.hisco, ll(160.02)
eststo: quietly truncreg height ib3.sourcedum	i.regiondum	age	afrikaans urban ib6.hisco ib1880.birthyear ib1900.year, ll(160.02)
eststo: quietly reg height ib3.sourcedum	i.regiondum	afrikaans urban	ib6.hisco ib1880.birthyear ib1900.year
estout using whiteliv.txt, cells(b(star fmt(3)) t(par fmt(2))) stats(r2 N)

estimates clear


*Change over time


estimates clear

quietly truncreg height ib3.sourcedum	i.regiondum	age	afrikaans urban ib6.hisco by2-by6 if regiondum==0, ll(160.02)
estimates store westerncape
quietly truncreg height ib3.sourcedum	i.regiondum	age	afrikaans urbanib6.hisco by2-by6 if boer==1, ll(160.02)
estimates store boerrepublics

coefplot westerncape boerrepublics, keep(by2 by3 by4 by5 by6) level(90) vertical cismooth grid(none) scheme(s2mono) ytitle(Additional height advantage) yline(0) plotregion(fcolor(white)) graphregion(fcolor(white)) legend(row(1)) xlabel(1 "1871-1875" 2 "1876-1880" 3 "1881-1885" 4 "1886-1890" 5 "1891-1895")

estimates clear

eststo: quietly truncreg height	i.regiondum	age	afrikaans urban ib6.hisco by2-by6, ll(160.02)
eststo: quietly truncreg height	i.regiondum	age	afrikaans urban ib6.hisco by2-by6 i.year, ll(160.02)
eststo: quietly truncreg height	ib3.sourcedum i.regiondum	age	afrikaans urban ib6.hisco by2-by6, ll(160.02)
eststo: quietly truncreg height ib3.sourcedum	i.regiondum	age	afrikaans urban ib6.hisco by2-by6 i.year, ll(160.02)
estout using whitebirthyears.txt, cells(b(star fmt(3)) t(par fmt(2))) stats(r2 N)

estimates clear


*Martine request
eststo: quietly truncreg height ib3.sourcedum i.regiondum afrikaans urban ib6.hisco ib1880.birthyear ib1900.year, ll(160.02)
eststo: quietly reg height ib3.sourcedum i.regiondum afrikaans urban ib6.hisco ib1880.birthyear ib1900.year
estout using martine.txt, cells(b(star fmt(3)) t(par fmt(2))) stats(r2 N)
