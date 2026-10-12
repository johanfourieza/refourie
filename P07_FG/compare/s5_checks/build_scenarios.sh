#!/bin/sh
# S5 (P07_FG): builds scenario run files from the verbatim repro_original/CreatingKhoe.do (never edited) by
# sed substitutions, runs them in Stata (batch) with logs on D:, one directory per scenario.
# Usage (Git Bash): sh P07_FG/compare/s5_checks/build_scenarios.sh
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/../../repro_original/CreatingKhoe.do"
SCR="./P07_FG/compare/_scratch"
STATA="C:/Program Files/StataNow19/StataMP-64.exe"
run() { # $1 = scenario name, $2 = sed script applied to lines 1-67
  d="$SCR/$1"; mkdir -p "$d"
  {
    echo 'version 13'; echo 'clear all'; echo 'set more off'
    echo 'use "./P07_FG/original/14 FG Missing People/missingpeople.dta", clear'
    sed -n '1,67p' "$SRC" | sed -e "$2"
    echo ''
    echo '* ==== X1 extraction (as build_runs.sh) ===='
    echo 'gen _csd = district<4'
    echo 'tabstat cattlekhoe slaves slavemales, by(year) stat(sum n) format(%12.4f)'
    echo 'tabstat cattlekhoe slaves slavemales if _csd==1, by(year) stat(sum n) format(%12.4f)'
    echo 'tabstat cattlekhoe slaves slavemales if district==4, by(year) stat(sum n) format(%12.4f)'
    echo 'tabstat cattlekhoe slaves slavemales, by(district) stat(sum n) format(%12.4f)'
  } > "$d/run.do"
  (cd "$d" && "$STATA" //e do run.do)
  echo "$1 done: $(grep -c '^r(' "$d/run.log" || true) r() errors"
}
run base       's/^XXXX//'
# C1: Stellenbosch at "double" the Swellendam rates as the text states (135/115/95), not 3x (202.5/172.5/142.5)
run stel2x     's#vherd/142.5 if slaves==0 \& district==2#vherd/95 if slaves==0 \& district==2#; s#vherd/172.5 if slaves>0 \& slaves<6 \& district==2#vherd/115 if slaves>0 \& slaves<6 \& district==2#; s#vherd/202.5 if slaves>5 \& district==2#vherd/135 if slaves>5 \& district==2#'
# D1 (S2): keep district 0 (published Totals)
run keep0      's#^drop if district==0$#* S5: line 8 disabled#'
# C8 calibration sensitivity: all herd-value-per-Khoesan divisors x2 (half the Khoesan) and x0.5 (double)
run div_x2     's#vherd/\([0-9.]*\) #vherd/(2*\1) #'
run div_x05    's#vherd/\([0-9.]*\) #vherd/(0.5*\1) #'
# Pair-B check: "wheat" productivity uses wheat only instead of wheat+rye+barley
run wheatonly  's#^gen grainreaped = wheatreaped + ryereaped + barleyreaped$#gen grainreaped = wheatreaped#'
# Pair-B check: T6 1-5 slave split on adult male slaves (slavemales) as in the "without" columns
run t6male     's#slavemales<6 \& slaves!=0#slavemales<6 \& slavemales!=0#'
# C8/T6 circularity check: one divisor per district (the 1-5 slave value), no slave-category gradient
run uniform    's#vherd/47.5 #vherd/57.5 #; s#vherd/67.5 #vherd/57.5 #; s#vherd/95 #vherd/115 #; s#vherd/135 #vherd/115 #; s#vherd/142.5 #vherd/172.5 #; s#vherd/202.5 #vherd/172.5 #'
# C12: keep the 1752 and 1762 censuses (dropped at CK:6 without a stated reason; both are >= 1719 so they could enter T3-T6)
run keep5262   's#^drop if year == 1752 | year==1702 | year==1678 | year==1670 | year == 1762 | year==1705 | year == 1716 | year ==1688$#drop if year==1702 | year==1678 | year==1670 | year==1705 | year == 1716 | year ==1688#'
