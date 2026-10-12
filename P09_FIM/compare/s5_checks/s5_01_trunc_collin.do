* P09_FIM S5 check 1 (Claude): truncation heaping (S2-2) and source/year collinearity (S2-3)
* on the 2015 code path (15 July cleaning, Regressionfinal specs 4-5 and the 26 July Martine spec).
* Aggregates only. Run from P09_FIM/compare/s5_checks:  StataMP-64 //e do s5_01_trunc_collin.do
version 13
clear all
set more off
do "../../../tools/paths.do"
use "$DATA/P09_FIM/repro_original/_scratch/whiteliving2015.dta", clear
* 15 July cleaning, lines 5-15 verbatim
drop if repeat==1
drop if age<20
drop if year<1890
drop if year>1920
drop if year==19.5
drop if birthyear<1865
drop if birthyear>1895
keep if sadummy==1
drop if age>55
gen double hd = round(height, 0.01)
count if abs(hd-160.02)<1e-6
count if hd<160.02
* (a) support of enlistment year by source
tab year sourcedum
* (b) spec 5 of Regressionfinal under three truncation treatments
local X "ib3.sourcedum i.regiondum age afrikaans urban black ib6.hisco ib1880.birthyear ib1900.year"
quietly truncreg height `X', ll(160.02)
estimates store f_float
quietly truncreg hd `X', ll(160.02)
estimates store f_double
quietly truncreg hd `X', ll(159.385)
estimates store f_below
* (c) spec 4 (no birth-year/year FE) and spec 5 without year FE, float
quietly truncreg height ib3.sourcedum i.regiondum age afrikaans urban black ib6.hisco, ll(160.02)
estimates store s4
quietly truncreg height ib3.sourcedum i.regiondum age afrikaans urban black ib6.hisco ib1880.birthyear, ll(160.02)
estimates store s5_noyear
estimates table f_float f_double f_below s4 s5_noyear, keep(0.sourcedum 1.sourcedum 2.sourcedum urban afrikaans 1865.birthyear 1870.birthyear 1890.birthyear 1895.birthyear) b(%9.3f) se(%9.3f) stats(N ll)
* (d) White-only (26 July) Martine spec, three truncation treatments
drop if black==1
local M "ib3.sourcedum i.regiondum afrikaans urban ib6.hisco ib1880.birthyear ib1900.year"
quietly truncreg height `M', ll(160.02)
estimates store m_float
quietly truncreg hd `M', ll(160.02)
estimates store m_double
quietly truncreg hd `M', ll(159.385)
estimates store m_below
estimates table m_float m_double m_below, keep(0.sourcedum 1.sourcedum 2.sourcedum urban afrikaans 1865.birthyear 1870.birthyear 1890.birthyear 1895.birthyear) b(%9.3f) se(%9.3f) stats(N ll)
