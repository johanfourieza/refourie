* [ENV-diagnostic] diag_farmer.do: Augmented sheet, repeats dropped; farmer / class / hisco by region (not original code)
version 13
clear all
set more off
sysdir set PLUS "`c(pwd)'/ado/plus"
sysdir set PERSONAL "`c(pwd)'/ado/personal"
do "`c(pwd)'/../../tools/paths.do"
* [ENV] unscripted import step: the Augmented sheet of SAC final.xlsx (only source of lwage/hisco)
import excel "$DATA/P08_SAC/original/FourieSAC2026/SAC final.xlsx", sheet("Augmented") firstrow case(lower) clear
destring, replace
cd "output"
* ---- diagnostic block (not original code) ----
drop if repeatlast==1
tab regiondum region if regiondum<.
tabstat farmer, by(regiondum) stat(n mean)
tab regiondum class, row
tab hisco farmer, missing
tab class farmer, missing
tabstat lwage wage, stat(n mean min max)
count if age>18 & repeatlast==0 & (regiondum==5 | regiondum==9) & lwage<.
count if age>18 & repeatlast==0 & (regiondum==5 | regiondum==9) & lwage<. & region!="."
count if age>=. & repeatlast==0 & (regiondum==5 | regiondum==9) & lwage<. & region!="."
count if age<=18 & repeatlast==0 & lwage<.
count if regiondum==5 & repeatlast==0 & lwage<. & region!="." & age>18
tab afrikaans regiondum if age>18 & repeatlast==0 & (regiondum==5 | regiondum==9) & lwage<. & region!="."
