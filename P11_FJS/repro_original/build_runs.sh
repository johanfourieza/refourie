#!/bin/sh
# Builds the run files from the verbatim copy fiscalpolicy.do (101 lines).
# Original lines are taken unchanged by line range; the only new lines are the
# environment header (E1), the data path (E2) and the extraction footer (E3). See PATCHES.md.
set -e
cd "$(dirname "$0")"
hdr() {
cat <<'H'
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
H
}
ftr() {
cat <<F
* ==== E3 extraction footer (not analysis): keep the household file and print the decile table for every Image 9 year ====
save "\$DATA/P11_FJS/repro_original/_scratch/$1_households.dta", replace
foreach y in 1700 1719 1731 1738 1741 1757 1773 {
    tabstat totaltax if jaar==\`y', by(slavesdecile) stat(n mean sum)
}
F
}
# run_0: original code, environment patches only
{ hdr; sed -n '2,101p' fiscalpolicy.do; ftr run0; } > run_0_original.do
# run_A1 (A' alignment, separately labelled): original line 47 with 48 (1 Rd) instead of 72 (1.5 Rd) stuivers per leaguer before 1743.
# Evidence: Fiscal policy.xlsx Tables!J81:J93 = Tables!M40:M52 x 2/3 exactly; paper p.17 says 1 Rd before 1743. All other lines unchanged.
{ hdr; sed -n '2,46p' fiscalpolicy.do; echo 'replace winetax = 48*wyn if jaar < 1743   // A1 alignment: was 72*wyn (original line 47)'; sed -n '48,101p' fiscalpolicy.do; ftr runA1; } > run_A1_wine48.do
