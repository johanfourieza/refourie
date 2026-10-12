#!/bin/bash
# Re-runs the full P08_SAC S2 chain from Git Bash. Run from anywhere.
set -e
cd "$(dirname "$0")"
S="/c/Program Files/StataNow19/StataMP-64.exe"
sh build_runs.sh
rm -f output/fgm.txt output/fullprec/fgm.txt output/fullprec/fgm_fullprec.txt   # the original estout line has no `replace`
for f in run_occupations run_occupations_fullprec run_timetoshine diag_height diag_farmer; do
  "$S" //e do $f.do; mv $f.log logs/
done
diff <(tr -d '\r' < output/fgm.txt) <(tr -d '\r' < "./P08_SAC/original/FGM The SAC/fgm.txt") || true
cd ../..
"/c/Program Files/R/R-4.5.2/bin/Rscript.exe" P08_SAC/repro_original/extract_results.R
"/c/Program Files/R/R-4.5.2/bin/Rscript.exe" P08_SAC/compare/run_compare_A.R
