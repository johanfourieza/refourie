* ==== E1 environment header (PATCHES.md) ====
version 13
clear all
set more off
sysdir set PLUS "`c(pwd)'/ado/plus"
sysdir set PERSONAL "`c(pwd)'/ado/personal"
do "../../tools/paths.do"
* ==== E2 data path: replaces original line 1 ====
use "$DATA/P11_FJS/original/Fourie Jansen Siebrits/base.dta"
* ==== original lines 2-101 follow ====

preserve

***Correcting dataset***
drop if jaar==1663
drop if jaar==1670
drop if jaar==1685
drop if jaar==1716
drop if jaar==1752
drop if jaar==1762

***Minimum revenue***

gen tslaves = .
replace tslaves =  sm + sv + ss + sd

gen assets = .
replace assets = bste + skpe + wingst + wyn + kgs + kgw + rgs + rgw + cgs + cgw

gen sassets = .
replace sassets = tslaves + bste + skpe + wingst + wyn + kgs + kgw + rgs + rgw + cgs + cgw

gen tax = 0

***Individuals with no assets: head tax of 32 stuivers
replace tax = 32 if sassets == 0

***Individuals with only slaves (no agricultural assets), inside Cape Town: hearth money of 4 Rds (4*48 stuivers)
replace tax = 192 if tslaves > 0 & assets == 0 & ds == 1

***Individuals with only slaves (no agricultural assets), outside Cape Town: head tax of 32 stuivers
replace tax = 32 if tslaves > 0 & assets == 0 & ds != 1

***Creating a wine proxy for those with wingerd but no wine
gen wineyield = 0
replace wineyield = wyn/wingst if wyn !=0 & wingst != 0
tabstat wineyield

gen winesub = 0
replace winesub = wingst*.0008813

replace wyn = winesub if wyn == 0

***Wine tax: 1.5 Rds per leaguer before 1743, 3 Rds after(3 Rds = 48 stuivers); only 70% brought to Cape Town
gen winetax = 0
replace winetax = 72*wyn if jaar < 1743
replace winetax = 144*wyn*.7 if jaar > 1743

***Wheat tax: wheat, barley, rye: (Output - Input)*10%
***6 Rds for one muid of wheat (Fourie and Von Fintel 2011); 3 Rds for other two crops assumed.
gen yieldk = .
gen yieldr = .
gen yieldc = .
replace yieldk = kgw - kgs
replace yieldr = rgw - rgs
replace yieldc = cgw - cgs
gen yieldkpos = max(yieldk, 0)
gen yieldrpos = max(yieldr, 0)
gen yieldcpos = max(yieldc, 0)

gen wheattax = 0
replace wheattax = yieldkpos*.1*6*48 + yieldrpos*.1*3*48 + yieldcpos*.1*3*48

***Meat tax: Cattle = 1 stuiver; Sheep = 16 stuivers per 100.
gen meattax = 0
replace meattax = bste + skpe*.16

***Total tax
gen totaltax = 0
replace totaltax = tax + winetax + wheattax + meattax

***Descriptives

tabstat bste skpe wyn kgw rgw cgw, by(jaar) stat(sum)

tabstat totaltax, by(jaar) stat(n, mean, sum)
tabstat tax winetax wheattax meattax, by(jaar) stat(sum)

***Tax per capita
gen hh = vs + m + v + s + d
gen taxpp = max(totaltax/hh, 1)
tabstat taxpp, by(jaar) stat(n, mean, sum)

***Gini decomposition by tax
descogini totaltax tax winetax wheattax meattax
descogini totaltax tslaves

***Tax per wealth category
tabstat totaltax if tslaves<50, by(tslave) stat(n)
tabstat totaltax if tslaves>49, stat(n)
tabstat totaltax tax wheattax winetax meattax if tslaves<50, by(tslave) stat(mean)
tabstat totaltax tax wheattax winetax meattax if tslaves>49, stat(mean)

***Slaves per tax decile (ssc install egenmore)
egen taxdecile = xtile(totaltax), by(jaar) p(10(10)90)
tabstat taxdecile, by(jaar)

***Taxes per slave decile
egen slavesdecile = xtile(tslaves), by(jaar) p(10(10)90)
tabstat totaltax if jaar==1719, by(slavesdecile) stat(n mean)
* ==== E3 extraction footer (not analysis): keep the household file and print the decile table for every Image 9 year ====
save "$DATA/P11_FJS/repro_original/_scratch/run0_households.dta", replace
foreach y in 1700 1719 1731 1738 1741 1757 1773 {
    tabstat totaltax if jaar==`y', by(slavesdecile) stat(n mean sum)
}
