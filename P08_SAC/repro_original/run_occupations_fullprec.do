* [ENV] run_occupations_fullprec.do: as run_occupations.do, plus a full-precision estout export after line 18
version 13
clear all
set more off
sysdir set PLUS "`c(pwd)'/ado/plus"
sysdir set PERSONAL "`c(pwd)'/ado/personal"
do "`c(pwd)'/../../tools/paths.do"
* [ENV] unscripted import step: the Augmented sheet of SAC final.xlsx (only source of lwage/hisco)
import excel "$DATA/P08_SAC/original/FourieSAC2026/SAC final.xlsx", sheet("Augmented") firstrow case(lower) clear
destring, replace
cd "output/fullprec"   // [ENV] fresh folder: the original estout line has no replace option
*Descriptives

*Occupations

preserve

drop if region=="."

cibar wage, over1(regiondum)

estimates clear

eststo: quietly reg lwage afrikaans if age>18 & repeatlast==0 & (regiondum==5 | regiondum==9)
eststo: quietly reg lwage afrikaans age height weight married if age>18 & repeatlast==0
eststo: quietly reg lwage afrikaans age height weight married ib6.hisco ib5.regiondum if age>18 & repeatlast==0
eststo: quietly reg lwage afrikaans age height weight married ib6.hisco ib5.regiondum i.eyear  if age>18 & repeatlast==0
eststo: quietly reg lwage afrikaans age height weight married jewish catholic blue tattoo chestdiff black swim shoot ride ib6.hisco ib5.regiondum i.eyear  if age>18 & repeatlast==0
estout using fgm.txt, cells(b(star fmt(3)) t(par fmt(2))) stats(r2 N)
estout using fgm_fullprec.txt, cells("b(fmt(%18.0g)) se(fmt(%18.0g)) t(fmt(%18.0g))") stats(r2 N, fmt(%18.0g)) replace   // [ENV]

estimates clear

