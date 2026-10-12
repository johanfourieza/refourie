# P08_SAC S2 patches

Sources, copied verbatim to `repro_original/`: `original/FGM The SAC/Occupations.do` (Feb 2015, 21 lines, Table 3) and `original/FGM The SAC/TimeToShine.do` (Sep 2014, 96 lines; date construction and height-sample restriction).
`build_runs.sh` generates every run file from these copies. Original lines are taken unchanged (`cat`, `sed -n`). The only new lines are the environment lines listed below, each marked `[ENV]` in the run file. `run_all.sh` rebuilds and reruns everything (Stata → `extract_results.R` → `compare/run_compare_A.R`). Logs: `logs/*.log`.

Software: StataNow 19.5 MP, batch mode (`StataMP-64.exe //e do`). R 4.5.2 (tidyxl, readr, dplyr) for the Excel formula chains.

## Packages (recorded here, not in `env/stata_ado.txt`, because this run may write only inside `P08_SAC/`; the coordinator should copy these lines across)

```
# P08_SAC (S2, 2026-10-11) - installed project-locally into P08_SAC/repro_original/ado/plus via `sysdir set PLUS`; system ado path untouched
estout  ssc  Distribution-Date 20260413  (estout.ado 3.33 23mar2026, Ben Jann)
cibar   ssc  Distribution-Date 20190624  (Alexander Staudt; requires Stata 13)
```
Installer: `install_ado.do` (log `logs/install_ado.log`).

## Environment patches

### E1. Header in every run file
```diff
+version 13
+clear all
+set more off
+sysdir set PLUS "`c(pwd)'/ado/plus"
+sysdir set PERSONAL "`c(pwd)'/ado/personal"
+do "`c(pwd)'/../../tools/paths.do"
```
Neither do-file has a `version` statement. Both date from 2014–15, so `version 13` applies (PROTOCOL S2).

### E2. Unscripted data import for `Occupations.do` (the do-file has no `use`/`import` line)
```diff
+import excel "$DATA/P08_SAC/original/FourieSAC2026/SAC final.xlsx", sheet("Augmented") firstrow case(lower) clear
+destring, replace
+cd "output"
```
`Occupations.do` needs `lwage` and `hisco`. `SAC_FGM.dta` (Sep 2014) has neither. The `Augmented` sheet of `SAC final.xlsx` (7 Jan 2015) is the only file that has both. `firstrow case(lower)` reproduces the lower-case names that the do-file uses (`regiondum`, `repeatlast`, `eyear`, `afrikaans`). Missing values in the workbook are the text `"."`, so `import excel` reads numeric columns as strings. A blanket `destring, replace` converts every column that is entirely numeric or `"."` (for example `lwage`, `hisco`, `regiondum`, `eyear`) and leaves text columns, including `region`, as strings. `drop if region=="."` (do-file line 7) requires `region` to be a string, and it is. This is the minimal import: no variable is recoded, renamed or created. `cd "output"` makes `estout using fgm.txt` write to `repro_original/output/`.

**Verification.** `output/fgm.txt` is byte-identical to the authors' `fgm.txt` except for a single cell: spec 5 `age` t = −2.47 against −2.46. The full-precision value is −2.46556, which sits on the rounding boundary. Spec 5 is not in the paper. All of published Table 3 (specs 1–4: coefficients, t, R², N) reproduces character for character.

### E3. Full-precision export (`run_occupations_fullprec.do`)
The same file as `run_occupations.do`, plus one line after do-file line 18:
```diff
+estout using fgm_fullprec.txt, cells("b(fmt(%18.0g)) se(fmt(%18.0g)) t(fmt(%18.0g))") stats(r2 N, fmt(%18.0g)) replace   // [ENV]
```
It runs in `output/fullprec/`. The original `estout using fgm.txt` line has no `replace` option, so it fails with r(602) whenever `fgm.txt` already exists. `run_all.sh` deletes the old `fgm.txt` before each run for that reason. The patch changes output format only. `results_original.csv` takes its Table 3 values from this file.

### E4. `TimeToShine.do` data path
```diff
-use "C:\Users\User\Dropbox\Research\ELITE\Fourie Grundlingh Mariotti\SAC_FGM.dta"
+use "$DATA/P08_SAC/original/FGM The SAC/SAC_FGM.dta"
+graph export "output/DensityDOB_repro.png", replace width(1600)   // batch mode has no graph window
+count
```
The script runs clean. Its last step leaves the height sample at N = 8,398. It computes no tabulated numbers: the paper's height means are not produced by any script.

### E5. Excel formula chains (`extract_results.R`)
`Descriptives.xlsx` holds 1,003 formula cells in four forms: `R/R`, `R-R`, `R/100` and `SUM(R:R)`. `extract_results.R` re-implements them as a recursive evaluator and recalculates every formula from its input cells. The maximum absolute difference from the cached values is 0 (`output/descriptives_recalc_check.csv`). The input cells are pasted Stata `tab`/`summarize` output; no script for them survives. Claims are mapped as follows: Table 4 → `Occupations!H26:O28`, Table 5 → `Occupations!N41:X43`, Table 7 → `Sheet2!B15:L24`, enlistment-place shares → `Enlistment!F`, the March–May share → `Enlistment!N23`, mean age → `Personal characteristis!K7`. Country-of-birth and cause-of-exit shares (`Personal characteristis!C`, `Discharge!E`) are rescale-only formulas (pasted percentage / 100) and are flagged as such in `results_original.csv`.

### Diagnostics (not original code; no claim taken from them)
- `diag_height.do`: `TimeToShine.do` lines 3–91 verbatim, then counts around the height-sample drops (lines 92–93) and height means by region and surname group.
- `diag_farmer.do`: `Augmented` import (E2), repeats dropped, then farmer, class and HISCO cross-tabs by region, and the spec 1 sample count.

## Run status
`run_status = ran-with-env-patches`. No analytic change was made.
