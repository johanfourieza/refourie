* P27_RW S2: Table 3 and Table 4 descriptives. The published tables have no surviving do-file (S1);
* this file runs summarize, detail on the surviving analysis files, as the original author did interactively.
* ENV PATCH: version 11 (pre-2012 era), paths via tools/paths.do (A6). Run from P27_RW/repro_original.
version 11
clear all
set more off
do "../../tools/paths.do"
local D "$DATA/P27_RW/original/Data/Statafiles"
tempname fh
file open `fh' using "$DATA/P27_RW/repro_original/_scratch/stata_out.csv", write replace
file write `fh' "claim_id,value,n" _n

capture program drop wr
program define wr
    args fh id v n
    file write `fh' "`id'," %20.10g (`v') ",`n'" _n
end

capture program drop descr
program define descr
    * args: fh prefix var  [cond]
    args fh pre var
    quietly summarize `var', detail
    local N = r(N)
    wr `fh' "`pre'_n" r(N) `N'
    wr `fh' "`pre'_sum" r(sum) `N'
    wr `fh' "`pre'_mean" r(mean) `N'
    wr `fh' "`pre'_sd" r(sd) `N'
    wr `fh' "`pre'_min" r(min) `N'
    wr `fh' "`pre'_max" r(max) `N'
    wr `fh' "`pre'_p10" r(p10) `N'
    wr `fh' "`pre'_p25" r(p25) `N'
    wr `fh' "`pre'_p50" r(p50) `N'
    wr `fh' "`pre'_med" r(p50) `N'
    wr `fh' "`pre'_p75" r(p75) `N'
    wr `fh' "`pre'_p90" r(p90) `N'
    quietly count if `var' > 0 & !missing(`var')
    local nz = r(N)
    wr `fh' "`pre'_nonzero" `nz' `N'
    wr `fh' "`pre'_zeros" (100*(`N'-`nz')/`N') `N'
end

* ---------- Table 3: 28 items, inventories with non-missing counts (N = 2,577) ----------
use "`D'/numbersandwealth.dta", clear
keep if !missing(slavesnumb)
local items "slaves cattle horses sheep ploughs corn_sieves fishing_boats buckets spades guns brandy_stills wagons anvils bench_vices balances firetongs ovens bedsteads chairs trousers irons books timepieces snuffboxes paintings mirrors bird_cages gold_rings"
local vars  "slavesnumb beesten paarden schapen ploeg koornharp schuijt emmers graaven geweer brandewijnskeetels waagen aambeeld bankschroef balans tang stoven kadels stoel broek strijkijsters boeken horlogie snuijfdoos schilderij spiegel vogelkooi ring"
local k = 1
foreach it of local items {
    local v : word `k' of `vars'
    descr `fh' "T3_`it'" `v'
    local k = `k' + 1
}
* Table 4 inventory side
local k = 1
foreach it in slaves cattle horses sheep {
    local v : word `k' of `vars'
    descr `fh' "T4_incl_inv_`it'" `v'
    preserve
    keep if `v' > 0 & !missing(`v')
    descr `fh' "T4_excl_inv_`it'" `v'
    restore
    local k = `k' + 1
}

* ---------- Table 4 opgaafrolle side, households 1700-73 ----------
use "`D'/opgaafrolle.dta", clear
keep if jaar >= 1700 & jaar <= 1773
gen slaves = sm + sv + ss + sd
local k = 1
foreach it in slaves cattle horses sheep {
    local ov "slaves bste pd skpe"
    local v : word `k' of `ov'
    descr `fh' "T4_incl_opg_`it'" `v'
    preserve
    keep if `v' > 0 & !missing(`v')
    descr `fh' "T4_excl_opg_`it'" `v'
    restore
    local k = `k' + 1
}

* ---------- statadata.dta cross-check of overlapping items (sums) ----------
use "`D'/statadata.dta", clear
keep if !missing(slaves)
foreach v in slaves beesten paarden boeken {
    quietly summarize `v'
    wr `fh' "XCHK_statadata_`v'_sum" r(sum) r(N)
}
file close `fh'
