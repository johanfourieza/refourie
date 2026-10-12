#!/bin/sh
# Builds the S2 run files from the verbatim copy of the original do-file.
# Every inserted line is an environment patch (see PATCHES.md); original lines are taken unchanged by line range.
set -e
cd "$(dirname "$0")"
O="CF mobility replication.do"
HDR='version 15
clear all
sysdir set PLUS "`c(pwd)'"'"'/ado/plus"
sysdir set PERSONAL "`c(pwd)'"'"'/ado/personal"
do "`c(pwd)'"'"'/../../tools/paths.do"
global D "$DATA/P04_CF/original/CF Mobility/Data"'
USE16='use "$D/CF_mobility_replication_data_anonymized.dta", clear'
USE17='use "$D/SAF mobility data_10.08.2017.dta", clear
drop occ_group_last f_occ_group_last intra_mobility year period
capture label drop class
capture label drop per
capture label drop mobl   // [ENV] 2017 file already carries these value labels'

{ echo "* [ENV] run_0_full.do: verbatim do-file on the Oct-2016 anonymised file"; echo "$HDR"; echo "$USE16"; cat "$O"; } > run_0_full.do
{ echo "* [ENV] run_0b_full2017.do: verbatim do-file on the 2017 SAF file with pre-derived outputs dropped"; echo "$HDR"; echo "$USE17"; cat "$O"; } > run_0b_full2017.do
{ echo "* [ENV] run_A_derive2017.do: lines 1-157 on the 2017 SAF file (only file with occ_group1-8 / f_occ_group1-9 / fathers_dob)"; echo "$HDR"; echo "$USE17"; sed -n '1,157p' "$O"; } > run_A_derive2017.do
{ echo "* [ENV] run_B_tabs2016.do: lines 145-157 on the Oct-2016 anonymised analysis file (already holds the outputs of lines 14-144 incl. labels)"; echo "$HDR"; echo "$USE16"; sed -n '145,157p' "$O"
  echo '* [ENV-diagnostic, not original code] psplit tabulation that line 178 intends (data were cleared at line 167)'; echo 'bysort psplit: tab f_occ_group_last occ_group_last, row'; } > run_B_tabs2016.do
{ echo "* [ENV] run_C1_altham_prelude.do: lines 159-365 verbatim"; echo "$HDR"; sed -n '159,365p' "$O"; } > run_C1_altham_prelude.do
{ echo "* [ENV] run_C2_altham.do: lines 167-168 and 180-365 verbatim (self-contained: hard-coded frequencies); lines 170-178 fail on cleared data, see run_C1"; echo "$HDR"; sed -n '167,168p' "$O"; sed -n '180,365p' "$O"; } > run_C2_altham.do
{ echo "* [ENV] run_D_dropfarmers.do: lines 367-378 on the anonymised file"; echo "$HDR"; echo "$USE16"; sed -n '367,378p' "$O"; } > run_D_dropfarmers.do
{ echo "* [ENV] run_E_logit.do: lines 380-409 on the anonymised file"; echo "$HDR"; echo "$USE16"
cat <<'EOF'
* [ENV] regenerate missing origin_occ_group_share.dta from the analysis file itself
*       (share is constant within period x f_occ_group_last; master already holds share,
*        so the m:1 merge only checks keys and does not overwrite)
preserve
keep period f_occ_group_last share
duplicates drop
isid period f_occ_group_last
* [ENV A6] data files (.dta, outreg2 .xls) are written to the D: data root; the outreg2 .txt tables are copied back to output/
local PROJ "`c(pwd)'"
capture mkdir "$DATA/P04_CF/repro_original/output"
save "$DATA/P04_CF/repro_original/output/origin_occ_group_share.dta", replace
restore
cd "$DATA/P04_CF/repro_original/output"
* [ENV] model 2 calls i.f_gen_dad (2017 name, = gen_dad in SAF 2017 file); the 2016 file names it f_gen
gen f_gen_dad = f_gen
EOF
sed -n '380,409p' "$O"
cat <<'EOF'
* [ENV A6] copy the outreg2 text tables back to the project output folder
foreach k in 1 2 3 {
    copy "binary_mob`k'_SA.txt" "`PROJ'/output/binary_mob`k'_SA.txt", replace
    erase "binary_mob`k'_SA.txt"
}
cd "`PROJ'"
EOF
} > run_E_logit.do
