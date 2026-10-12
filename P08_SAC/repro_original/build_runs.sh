#!/bin/sh
# Builds the S2 run files from verbatim copies of the original do-files (Occupations.do, TimeToShine.do).
# Original lines are taken unchanged (cat / sed -n); every inserted or replaced line is an [ENV] patch (PATCHES.md).
set -e
cd "$(dirname "$0")"
HDR='version 13
clear all
set more off
sysdir set PLUS "`c(pwd)'"'"'/ado/plus"
sysdir set PERSONAL "`c(pwd)'"'"'/ado/personal"
do "`c(pwd)'"'"'/../../tools/paths.do"'
IMPORT='* [ENV] unscripted import step: the Augmented sheet of SAC final.xlsx (only source of lwage/hisco)
import excel "$DATA/P08_SAC/original/FourieSAC2026/SAC final.xlsx", sheet("Augmented") firstrow case(lower) clear
destring, replace
cd "output"'
{ echo "* [ENV] run_occupations.do: Occupations.do verbatim after import of the Augmented sheet"; echo "$HDR"; echo "$IMPORT"; cat Occupations.do; } > run_occupations.do
{ echo "* [ENV] run_timetoshine.do: TimeToShine.do with the absolute use path replaced (line 2)"; echo "$HDR"
  echo 'use "$DATA/P08_SAC/original/FGM The SAC/SAC_FGM.dta"   // [ENV] replaces line 2 (C:\Users\User\Dropbox\Research\ELITE\...\SAC_FGM.dta)'
  sed -n '3,$p' TimeToShine.do
  echo '* [ENV] save graph to output/ (batch mode has no window)'; echo 'graph export "output/DensityDOB_repro.png", replace width(1600)'
  echo 'count'; } > run_timetoshine.do
# Full-precision export: identical run, plus one [ENV] line after the original estout line (output format only).
{ echo "* [ENV] run_occupations_fullprec.do: as run_occupations.do, plus a full-precision estout export after line 18"; echo "$HDR"; echo "$IMPORT" | sed "s|^cd \"output\"|cd \"output/fullprec\"   // [ENV] fresh folder: the original estout line has no replace option|"
  sed -n '1,18p' Occupations.do
  echo 'estout using fgm_fullprec.txt, cells("b(fmt(%18.0g)) se(fmt(%18.0g)) t(fmt(%18.0g))") stats(r2 N, fmt(%18.0g)) replace   // [ENV]'
  sed -n '19,$p' Occupations.do; } > run_occupations_fullprec.do
# Diagnostics (NOT original code; S5 leads only, no claim is taken from them).
{ echo "* [ENV-diagnostic] diag_height.do: TimeToShine lines 3-91 verbatim, then counts around the height-sample drops (l.92-93)"; echo "$HDR"
  echo 'use "$DATA/P08_SAC/original/FGM The SAC/SAC_FGM.dta"   // [ENV] replaces line 2'
  sed -n '3,91p' TimeToShine.do
  cat <<'EOF'
* ---- diagnostic block (not original code) ----
count
count if missing(agen)
count if missing(agen) & height<.
count if agen<7300
count if agen>18250 & !missing(agen)
count if height<.
tabstat agen1 if agen<., stat(n min p1 max)
tabstat height, by(regiondum) stat(n mean)
drop if agen < 7300
count if missing(agen)
drop if agen > 18250
count
tabstat height, by(regiondum) stat(n mean)
tabstat height if regiondum==5 | regiondum==9, by(afrikaans) stat(n mean)
tabstat height if regiondum==9, by(afrikaans) stat(n mean)
EOF
} > diag_height.do
{ echo "* [ENV-diagnostic] diag_farmer.do: Augmented sheet, repeats dropped; farmer / class / hisco by region (not original code)"; echo "$HDR"; echo "$IMPORT"
  cat <<'EOF'
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
EOF
} > diag_farmer.do
