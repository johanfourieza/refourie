* published_spec_attempt.do  (pair A' : "original lineage, published specification")
* Starts from settlers_from_log.do (Nov 2010 lineage: final_excl_1.dta, l_*_zero dependent
* variables, [aw=hhsize] weights, robust SEs) and hhsize.do, and changes ONLY what the published
* tables/notes/text specify differently. Every change is logged in PATCHES.md as an ANALYTIC
* change ("spec-alignment, not environment"). This is not a pure S2 reproduction.
version 11
clear all
set more off
capture log close
do "./tools/paths.do"
log using published_spec_attempt_results.log, text replace
local DATA "$DATA/P18_FvFS/repro_original/extracted/results/exclpc/final_excl_1.dta"

tempname P
postfile `P' str6 tab str6 col str40 term double b se N r2 F using "$DATA/P18_FvFS/repro_original/published_spec_est.dta", replace
capture program drop postit
program define postit
    args P tab col
    tempname B V
    matrix `B' = e(b)
    matrix `V' = e(V)
    local names : colfullnames `B'
    local k = 0
    foreach t of local names {
        local ++k
        post `P' ("`tab'") ("`col'") ("`t'") (`B'[1,`k']) (sqrt(`V'[`k',`k'])) (e(N)) (e(r2)) (e(F))
    }
end

* ---------------------------------------------------------------------------------------
* Table 1 and Table 2 (ALIGN-1, ALIGN-2): hhsize.do lineage on opgaafrolle.dta, restricted to
* the published sample: farming households, census years 1700-1773 excluding 1716.
* ---------------------------------------------------------------------------------------
use "$DATA/P18_FvFS/original/Statafiles/opgaafrolle.dta", clear
gen hh = m + v + s + d
generate group = .
replace group = 0 if hug == 0
replace group = 1 if hug == 1 & wyns==0
replace group = 2 if hug == 1 & wyns==1
gen slaves = sm + sv + ss + sd
drop if jaar == 1682
drop if jaar == 1716
* ALIGN-1: published sample = farmers (non-zero on any agricultural variable), 1700-1773
keep if jaar >= 1700
egen agri = rowtotal(pd bste skpe vk wingst wyn kgs kgw rgs rgw cgs cgw)
keep if agri > 0
gen vines1000 = wingst/1000
tabstat hh slaves k vines1000 wyn kgw bste pd, by(group) stat(mean sd n)
foreach g in 0 1 2 9 {
    foreach v in hh slaves k vines1000 wyn kgw bste pd {
        if `g'==9 qui su `v'
        else qui su `v' if group==`g'
        post `P' ("T1") ("g`g'") ("`v'_mean") (r(mean)) (.) (r(N)) (.) (.)
        post `P' ("T1") ("g`g'") ("`v'_sd") (r(sd)) (.) (r(N)) (.) (.)
    }
}
* ALIGN-2: Table 2 is per-capita output weighted by household size (= sum(output)/sum(hh))
gen wyn_pc = wyn/hh
gen kgw_pc = kgw/hh
foreach y in 1700 1709 1719 1731 1741 1752 1757 1773 {
    foreach g in 0 1 2 {
        foreach v in wyn_pc kgw_pc {
            qui su `v' [aw=hh] if jaar==`y' & group==`g'
            post `P' ("T2") ("`y'") ("`v'_g`g'") (r(mean)) (.) (r(N)) (.) (.)
        }
    }
}

* ---------------------------------------------------------------------------------------
* Tables 3-5, A1, A3-A5: Nov 2010 lineage (final_excl_1.dta, l_*_zero, aw=hhsize, robust)
* ---------------------------------------------------------------------------------------
use "`DATA'", clear
* ALIGN-3: pooled 14 census years 1700-1773 (Nov 2010 run used 8 years, year by year)
keep if year>=1700 & year!=1716
* ALIGN-4: vines per household member (the Nov 2010 code used vines per household).
*          OUTCOME-INFORMED: chosen because it reproduces T3 col 3; the notes say only
*          "Vines planted are numbered in 1,000s".
gen vpc = vines_planted/hhsize
local W [aw=hhsize]

* ALIGN-1b / ALIGN-2b: Tables 1-2 recomputed on the analysis file (same sample as Tables 3-5).
* Inputs in final_excl_1.dta are per household member (except hhsize, total_slaves, vines);
* Table 1 reports household totals, so x*hhsize restores them.
foreach v in knechts wine wheat_reaped cattle horses {
    gen T_`v' = `v'*hhsize
}
gen v1000 = vines_planted
foreach g in 1 2 3 9 {
    foreach v in hhsize total_slaves T_knechts v1000 T_wine T_wheat_reaped T_cattle T_horses {
        if `g'==9 qui su `v'
        else qui su `v' if group==`g'
        post `P' ("T1b") ("g`g'") ("`v'_mean") (r(mean)) (.) (r(N)) (.) (.)
        post `P' ("T1b") ("g`g'") ("`v'_sd") (r(sd)) (.) (r(N)) (.) (.)
    }
}
foreach y in 1700 1709 1719 1731 1741 1752 1757 1773 {
    foreach g in 1 2 3 {
        foreach v in wine wheat_reaped {
            qui su `v' [aw=hhsize] if year==`y' & group==`g'
            post `P' ("T2b") ("`y'") ("`v'_g`g'") (r(mean)) (.) (r(N)) (.) (.)
        }
    }
}
drop T_* v1000
* ALIGN-5: no group x input interactions; district base Cape Town; marital base not married;
*          year dummies (base 1700); born-abroad dummy (all as printed in Tables 3-5)
local c2 total_slaves knechts
local c3 total_slaves knechts cattle horses vpc i.marital
local c4 total_slaves knechts cattle horses vpc i.marital wheat_reaped
local F firstarrivals ib1.district i.year

* Table 3 (full sample, base NH)
reg l_wine_zero i.group `F' `W', robust
postit `P' T3 1
reg l_wine_zero i.group `c2' `F' `W', robust
postit `P' T3 2
reg l_wine_zero i.group `c3' `F' `W', robust
postit `P' T3 3
reg l_wine_zero i.group `c4' `F' `W', robust
postit `P' T3 4

* Table 4 (Huguenot sample, base NWH)
reg l_wine_zero ib2.group `F' if group>1 `W', robust
postit `P' T4 5
reg l_wine_zero ib2.group `c2' `F' if group>1 `W', robust
postit `P' T4 6
reg l_wine_zero ib2.group `c3' `F' if group>1 `W', robust
postit `P' T4 7
* specs 8-9 add numeracy (variable nonnumeracy; printed as "Numeracy")
reg l_wine_zero ib2.group `c3' nonnumeracy `F' if group>1 `W', robust
postit `P' T4 8
reg l_wine_zero ib2.group `c4' nonnumeracy `F' if group>1 `W', robust
postit `P' T4 9
* ALIGN-6: spec 10 = Huguenots born abroad. Only the WH dummy and constant are printed;
*          the bivariate regression reproduces print (adding year/district/inputs does not).
reg l_wine_zero ib2.group if group>1 & firstarrivals==1 `W', robust
postit `P' T4 10

* Table 5 (log wheat reaped per household member, full sample, base NH)
local w12 total_slaves knechts
local w13 total_slaves knechts cattle horses
local w14 total_slaves knechts cattle horses i.marital
local w15 total_slaves knechts cattle horses i.marital wheat_sown
reg l_wheat_reaped_zero i.group `F' `W', robust
postit `P' T5 11
reg l_wheat_reaped_zero i.group `w12' `F' `W', robust
postit `P' T5 12
reg l_wheat_reaped_zero i.group `w13' `F' `W', robust
postit `P' T5 13
reg l_wheat_reaped_zero i.group `w14' `F' `W', robust
postit `P' T5 14
reg l_wheat_reaped_zero i.group `w15' `F' `W', robust
postit `P' T5 15
* spec 16: numeracy on the full sample with N = 9,078. The paper does not say how missing
* numeracy (all non-Huguenots) enters. Literal attempt: missing set to the sample mean.
* (Reported as ambiguous.)
qui su nonnumeracy
gen nn_imp = cond(nonnumeracy==., r(mean), nonnumeracy)
reg l_wheat_reaped_zero i.group `w15' nn_imp `F' `W', robust
postit `P' T5 16

* Table A5 (col 28 = T5 col 15; 29 excl. Netherlands; 30 excl. Netherlands, Germany, Italy)
reg l_wheat_reaped_zero i.group `w15' `F' `W', robust
postit `P' A5 28
reg l_wheat_reaped_zero i.group `w15' `F' if prov!="Nederland" `W', robust
postit `P' A5 29
reg l_wheat_reaped_zero i.group `w15' `F' if !inlist(prov,"Nederland","Deutschland","Italia") `W', robust
postit `P' A5 30

* Table A3 (Huguenot sample with known sending region)
preserve
keep if group>1 & prov!=""
* ALIGN-7: A2 classification (latitude base South, longitude base West, F-test grouping base 1)
gen lat = ""
replace lat = "Central" if inlist(prov,"Aunis","Poitou")
replace lat = "South" if inlist(prov,"Bearn","Dauphine","Italia","Lanquedoc","Provence")
replace lat = "North" if lat==""
gen lon = ""
replace lon = "West" if inlist(prov,"Aunis","Bearn","Bretagne","Normandie","Poitou")
replace lon = "East" if inlist(prov,"Dauphine","Deutschland","Italia","Provence")
replace lon = "Central" if lon==""
* ALIGN-8 (OUTCOME-INFORMED): A2 puts Germany and Italy in groups 1 AND 2 and the text calls
*   them group 1; only group 2 for both reproduces print col 20, so group 2 is used.
gen fgrp = 2
replace fgrp = 1 if inlist(prov,"Aunis","Bretagne")
replace fgrp = 3 if inlist(prov,"Bearn","Lanquedoc","Nederland")
gen latc = (lat=="Central")
gen latn = (lat=="North")
gen lonc = (lon=="Central")
gen lone = (lon=="East")
reg l_wine_zero ib2.group `c3' `F' `W', robust
postit `P' A3 17
reg l_wine_zero ib2.group latc latn lonc lone `c3' `F' `W', robust
postit `P' A3 18
* col 19 interactions: print labels them "North x Central" and "Central x Central"; no region is
* Central x Central in A2. North x Central and North x East (Germany) reproduce print exactly, so
* the second label is a typo for North x East (OUTCOME-INFORMED reading of the label).
gen latn_lonc = latn*lonc
gen latn_lone = latn*lone
reg l_wine_zero ib2.group latc latn lonc lone latn_lonc latn_lone `c3' `F' `W', robust
postit `P' A3 19
reg l_wine_zero ib2.group ib1.fgrp `c3' `F' `W', robust
postit `P' A3 20
reg l_wine_zero ib2.group `c3' `F' if prov!="Nederland" `W', robust
postit `P' A3 21
reg l_wine_zero ib2.group `c3' `F' if !inlist(prov,"Nederland","Aunis","Dauphine") `W', robust
postit `P' A3 22
reg l_wine_zero ib2.group `c3' `F' if !inlist(prov,"Nederland","Aunis","Dauphine","Deutschland","Italia") `W', robust
postit `P' A3 23
reg l_wine_zero ib2.group `c3' `F' if !inlist(prov,"Nederland","Deutschland","Italia") `W', robust
postit `P' A3 24
* cols 25-27 need sending-region soldier heights: not in any surviving file (unavailable)

* Table A1 / A4: pairwise region differences, region dummies replacing the WH dummy.
encode prov, gen(pv)
label list pv
reg l_wine_zero ibn.pv `c3' `F' `W', robust noconstant
postit `P' A1 pv
* A4: controls not stated; T5 col 15 controls used (reported as ambiguous)
reg l_wheat_reaped_zero ibn.pv `w15' `F' `W', robust noconstant
postit `P' A4 pv
restore

postclose `P'
use "$DATA/P18_FvFS/repro_original/published_spec_est.dta", clear
export delimited using published_spec_est.csv, replace
log close
