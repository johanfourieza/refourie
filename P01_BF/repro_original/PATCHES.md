# P01_BF S2 patches

Source: `original/Baten Fourie/na.zip` › `0redo na with origin and brazil111015.do` (15 Oct 2011, 1,712 lines, sha256 `d4e5a711…47599`), copied verbatim to `repro_original/0redo na with origin and brazil111015.do`. Unzipped on D: (`$DATA/P01_BF/repro_original/_scratch/na_unzip/`).
All run files are generated from that copy by `build_runs.sh`. Original lines are taken **unchanged by line range** (`sed -n 'a,bp'`); every new line carries an `[ENV]`, `[ENV-extract]` or `[ENV-diagnostic]` tag and is listed below. Logs: `logs/run_*.log`. Software: StataNow 19.5 MP (batch), `outreg2` 2.3.2 (17aug2014) from SSC into `repro_original/ado/plus` (`install_ado.do`, `logs/install_ado.log`); system ado path untouched. (`env/stata_ado.txt` lies outside P01_BF and was not edited; this line is the record.)

## Environment patches

### E1. Header in every run file
```diff
+version 11
+clear all
+set more off
+sysdir set PLUS "`c(pwd)'/ado/plus"
+sysdir set PERSONAL "`c(pwd)'/ado/personal"
+do "`c(pwd)'/../../tools/paths.do"
+global S "$DATA/P01_BF/repro_original/_scratch"
+global ORIG "$DATA/P01_BF/original/Baten Fourie"
+global OUT "`c(pwd)'/output"
+cd "$S"
```
`version 11`: no `version` statement in the file; 2011 file (PROTOCOL S2). `set mem` lines are left in place (ignored by Stata ≥12 under version 11, no error). `cd "$S"` replaces the role of l.16 `cd "g:\a\na"`, so `outreg2` writes na1/na3/numeracy to D: scratch (copies of the .txt in `output/`).

### E2. Substitute input for the missing `na110702.dta` (l.1653, l.1698)
```diff
-use g:\a\na\na110702.dta,clear
+use "$ORIG/data.dta", clear   // [ENV] substitute for missing g:\a\na\na110702.dta
```
`na110702.dta` is not recovered (S1). `data.dta` (Sept 2011, N = 2,908) holds every variable l.1572–1647 create. Evidence that it is the l.1648 output: `run_C_rebuild.do` drops the 31 derived variables (`bco`, `b_*`, `bcohort`, `bd_*`, `bcoh`, `eur_early`–`za_post`), re-runs l.1573–1647 verbatim on the remainder (`origin`, `origindum`, `cn`, `ko`, `bl`, `eu`, `bdec`), and gets **0 mismatches on all 31** (`logs/run_C_rebuild.log`, lines `S2CHK`). Table 6 then reproduces to every printed digit (see audit).

### E3. Section split
| run file | original lines | data | result |
|---|---|---|---|
| — | 1–1566 | needs `na110421.dta` (l.18), `origin2.do` (l.1568) | **not run**: inputs missing. No claim comes from these lines (the l.801–861 descriptive blocks produce ABCC by decade × group in the Data Editor, not a paper table). |
| — | 1567–1572 | `origin2.do`, `bf110611.dta` | not run: missing |
| `run_C_rebuild.do` | 1573–1647 | data.dta minus derived variables | diagnostic for E2, 0 mismatches |
| `run_D_main.do` | 1649–1702 | data.dta (E2) | runs clean; T6, T8 col 1, F4, T7 |
| `run_E_brazil.do` | 1704–1712 | `G:\a\hb\br300407.dta` | **fails** r(601), file not recovered (wrapped in `capture noisily` so that the hard-coded `disp` lines 1707–1710 still run) |

### E4. Extraction lines (no analytic content)
`run_D_main.do` inserts, after l.1657 and l.1663, `matrix S2_* = e(Xmfx_dydx)` / `e(Xmfx_se_dydx)` and `scalar` copies of `e(N)`, `e(r2_p)`; after l.1667 `estimates store S2_lpm`; after l.1701 `export delimited` of the l.1699–1700 collapse; and at the end `s2_extract.do.inc`, which writes `output/s2_estimates.csv` from the stored results. `extract_results.R` turns that file into `results_original.csv` (×125 scaling as in the paper; mfx p-values from z = b/se).

### E5. Diagnostic run (not original code): `run_F_T7diag.do`
Counts, in the l.1699 sample (age 23–82) and in the l.1662 estimation sample, the observations with each interaction dummy (l.1610–1645) equal to 1, plus `tab bco bcoh`. Needed because the l.1699 collapse groups by `bco × bcoh`, whereas Table 7 counts the dummy cells (which pool some cells, see audit). This is a count of regressors already in the model, not an analytic change. No A′ alignment run was needed.
