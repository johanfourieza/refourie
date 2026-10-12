#!/bin/sh
# Builds the S2 run files from the verbatim copy of the original do-file (from original/Baten Fourie/na.zip).
# Original lines are taken unchanged by line range (sed -n 'a,bp'); every inserted line is tagged [ENV] and listed in PATCHES.md.
set -e
cd "$(dirname "$0")"
O="0redo na with origin and brazil111015.do"
HDR='version 11
clear all
set more off
sysdir set PLUS "`c(pwd)'"'"'/ado/plus"
sysdir set PERSONAL "`c(pwd)'"'"'/ado/personal"
do "`c(pwd)'"'"'/../../tools/paths.do"
global S "$DATA/P01_BF/repro_original/_scratch"
global ORIG "$DATA/P01_BF/original/Baten Fourie"
global OUT "`c(pwd)'"'"'/output"
cd "$S"   // [ENV] outreg2 files (na1, na3, numeracy) are written to D: scratch'
USE702='use "$ORIG/data.dta", clear   // [ENV] substitute for missing g:\a\na\na110702.dta'

# ---- run_D_main.do: lines 1649-1702 (analysis on na110702) with data.dta as substitute ----
{ echo "* [ENV] run_D_main.do: lines 1649-1702 verbatim; data.dta substitutes for na110702.dta (lines 1653, 1698)"
  echo "$HDR"
  sed -n '1649,1652p' "$O"
  echo "$USE702"
  sed -n '1654,1657p' "$O"
  echo '* [ENV-extract] keep T6 marginal effects'
  echo 'matrix S2_T6_b = e(Xmfx_dydx)'
  echo 'matrix S2_T6_se = e(Xmfx_se_dydx)'
  echo 'scalar S2_T6_N = e(N)'
  echo 'scalar S2_T6_r2p = e(r2_p)'
  sed -n '1658,1663p' "$O"
  echo '* [ENV-extract] keep interaction-logit marginal effects (xls col Q)'
  echo 'matrix S2_L3_b = e(Xmfx_dydx)'
  echo 'matrix S2_L3_se = e(Xmfx_se_dydx)'
  echo 'scalar S2_L3_N = e(N)'
  echo 'scalar S2_L3_r2p = e(r2_p)'
  sed -n '1664,1667p' "$O"
  echo 'estimates store S2_lpm   // [ENV-extract]'
  sed -n '1668,1697p' "$O"
  echo "$USE702"
  sed -n '1699,1702p' "$O"
  echo 'export delimited using "$OUT/T7_counts_bco_bcoh.csv", replace   // [ENV-extract]'
  cat s2_extract.do.inc
} > run_D_main.do

# ---- run_E_brazil.do: lines 1704-1712 (Brazil comparison); input br300407.dta is missing ----
{ echo "* [ENV] run_E_brazil.do: lines 1704-1712 verbatim; G:\a\hb\br300407.dta is not recovered, expected to fail at use"
  echo "$HDR"
  echo 'capture noisily {'
  sed -n '1704,1706p' "$O"
  echo '}'
  sed -n '1707,1712p' "$O"
} > run_E_brazil.do

# ---- run_C_rebuild.do: lines 1572-1648 on data.dta with the derived variables dropped (diagnostic for the na110702 substitute) ----
{ echo "* [ENV-diagnostic] run_C_rebuild.do: lines 1573-1647 verbatim, run on data.dta stripped of the variables those lines create; checks that data.dta = na110702"
  echo "$HDR"
  echo 'use "$ORIG/data.dta", clear'
  echo 'preserve'
  echo 'keep number bco b_* bcohort bd_* eu_early bcoh eur_early-za_post'
  echo 'foreach v of varlist bco b_* bcohort bd_* eu_early bcoh eur_early-za_post {'
  echo '  rename `v'"'"' o_`v'"'"''
  echo '}'
  echo 'tempfile old'
  echo 'gen long s2row = _n'
  echo 'save `old'"'"''
  echo 'restore'
  echo 'drop bco b_* bcohort bd_* eu_early bcoh eur_early-za_post'
  echo 'gen long s2row = _n'
  sed -n '1573,1647p' "$O"
  echo '* [ENV-diagnostic] compare rebuilt with stored variables'
  echo 'merge 1:1 s2row using `old'"'"', nogen'
  echo 'foreach v in bco b_cn b_eur b_id b_in b_kobc b_mz b_oth_bl b_za bcohort bd_early bd_middle bd_post1790 bcoh eur_early eur_mid eur_post id_early id_mid in_early in_mid ko_early ko_mid ko_post mz_mid mz_post otb_early otb_mid otb_post za_mid za_post {'
  echo '  quietly count if `v'"'"' != o_`v'"'"''
  echo '  display "S2CHK `v'"'"' mismatches = " r(N)'
  echo '}'
} > run_C_rebuild.do

# ---- run_F_T7diag.do: diagnostic, not original code. Counts of the line-1610..1645 interaction dummies in the line-1699 sample ----
{ echo "* [ENV-diagnostic, not original code] run_F_T7diag.do: Table 7 counts as the regression dummies define the cells (l.1610-1645), in the l.1699 sample and in the l.1662 estimation sample"
  echo "$HDR"
  echo "$USE702"
  echo 'foreach v of varlist eur_early-za_post {'
  echo '  quietly count if `v'"'"'==1 & age>22 & age<83'
  echo '  local a = r(N)'
  echo '  quietly count if `v'"'"'==1 & age>22 & age<83 & cyear~=.'
  echo '  display "S2T7 `v'"'"' " `a'"'"' " " r(N)'
  echo '}'
  echo 'count if b_cn==1 & age>22 & age<83 & cyear~=.'
  echo 'display "S2T7 b_cn_est " r(N)'
  echo 'tab bco bcoh if age>22 & age<83'
} > run_F_T7diag.do
