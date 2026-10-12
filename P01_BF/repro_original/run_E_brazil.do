* [ENV] run_E_brazil.do: lines 1704-1712 verbatim; G:\a\hb\br300407.dta is not recovered, expected to fail at use
version 11
clear all
set more off
sysdir set PLUS "`c(pwd)'/ado/plus"
sysdir set PERSONAL "`c(pwd)'/ado/personal"
do "`c(pwd)'/../../tools/paths.do"
global S "$DATA/P01_BF/repro_original/_scratch"
global ORIG "$DATA/P01_BF/original/Baten Fourie"
global OUT "`c(pwd)'/output"
cd "$S"   // [ENV] outreg2 files (na1, na3, numeracy) are written to D: scratch
capture noisily {
use "G:\a\hb\br300407.dta", clear
ta mult5 if slave & africa==0 & age>22 & age<83
ta mult5 if africa==1 & age>22 & age<83
}
disp 125-125*0.5184
*60.2 (N=326)
disp 125-125*0.3310
*83.6 (N=429)
*the ABCC is relatively high due to the urban nature of the criminal sample, but it is remarkable that Brazilian
*born slaves had 23% more basic numeracy than African born slaves in mid-19th C Brazil