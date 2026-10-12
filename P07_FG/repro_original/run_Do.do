* S2 wrapper for Do.do (Green-Fourie 2013 output regressions; no P07_FG claims). Patches E1-E2.
version 13
clear all
set more off
do "../../tools/paths.do"
capture log close
log using "logs/run_Do.log", text replace
use "$DATA/P07_FG/original/14 FG Missing People/missingpeople.dta", clear
do "Do.do"
do "Inequality.do"
tab group1 group2
log close
