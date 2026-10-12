# P11_FJS S2 patches

Source: `original/Fourie Jansen Siebrits/fiscalpolicy.do` (5 Mar 2013, 101 lines, CRLF), copied verbatim to `repro_original/fiscalpolicy.do`.
`build_runs.sh` generates both run files from that copy. Original lines are taken **unchanged by line range** (`sed -n 'a,bp'`). The only new lines are the environment lines E1–E3 below, plus, in the separately labelled A' run only, line A1.
Logs: `logs/run_0_original.log`, `logs/run_A1_wine48.log`, `logs/install_ado.log`. Software: StataNow 19.5 MP (batch, `//e` from Git Bash); R 4.5.2 (tidyxl, haven).

## Environment patches (run_0_original.do = the S2 run)

### E1. Header (version, project-local ado path, data root)
```diff
+version 13
+clear all
+set more off
+sysdir set PLUS "`c(pwd)'/ado/plus"
+sysdir set PERSONAL "`c(pwd)'/ado/personal"
+do "../../tools/paths.do"
```
`version 13`: the do-file has no `version` statement and is dated 2013 (PROTOCOL S2: 13 for 2012–15).

### E2. Data path (original line 1)
```diff
-use "C:\Users\johanf\Dropbox\Research\Fourie Jansen and Siebrits\base.dta"
+use "$DATA/P11_FJS/original/Fourie Jansen Siebrits/base.dta"
```
The data path follows A6 (`D:/Data/ReplicateMe`). `base.dta` is the verbatim copy (sha256 69ae7239…, MANIFEST.csv).

### E3. Extraction footer (appended after original line 101; it adds no analysis)
```diff
+save "$DATA/P11_FJS/repro_original/_scratch/run0_households.dta", replace
+foreach y in 1700 1719 1731 1738 1741 1757 1773 {
+    tabstat totaltax if jaar==`y', by(slavesdecile) stat(n mean sum)
+}
```
Original line 101 prints the decile table for 1719 only, but the workbook (`Deciles!Q11:W21`) holds it for all seven Image 9 years. The footer repeats line 101 for each year and saves the household file so that `extract_results.R` can map the output to the claims. No variable is created or changed.

### E4. Packages (project-local; the system ado folder is untouched)
`install_ado.do` → `ado/plus`: `descogini` (SSC Distribution-Date 20080922, file header "Version: January 2008", Lopez-Feldman) and `egenmore` (SSC Distribution-Date 20190124; `_gxtile` 2.1, 14 Jan 2019). The 2013 run would have used an older `_gxtile` (2.0 at the latest). The decile group sizes from the current version match the workbook cell for cell (e.g. 1741: 666/88/160/109/114/110 = `Deciles!I16:J21`; 1773: 1563/188/144/294/245/268 = `Deciles!J39:K44`), so the version change has no effect. The versions are recorded in `ado_versions.txt`. `env/stata_ado.txt` was not edited, because this agent may not write outside P11_FJS.

## A' alignment run (separately labelled; not used for pair A)

### A1. Wine-tax rate before 1743 (original line 47) — `run_A1_wine48.do`
```diff
-replace winetax = 72*wyn if jaar < 1743
+replace winetax = 48*wyn if jaar < 1743   // A1 alignment: was 72*wyn (original line 47)
```
Evidence that the published figures used 48 stuivers (1 Rd):
1. The paper (p.17) says "one rixdollar per leaguer before 1743". Line 47 uses 72 stuivers, which is 1.5 Rd, and the comment on line 45 says "1.5 Rds".
2. The workbook holds two pasted Stata blocks. The later one has `Tables!J81:J93` (winetax sums 1688–1741), which equals `Tables!M40:M52` × 2/3 exactly in every year, while the other taxes are identical. For 1757 and 1773, `J94:J95` = `M53:M54` × 0.7, the factor on line 48.
3. Image 7's pasted wine-tax series (`Tables!AB61:AB70`) equals the later block (`O84:O95`). The Image 9 decile means (`Deciles!Q12:W21`) and the 1773 mean (`Deciles!L46` = 490.3576) match run A1 to every printed digit, whereas run 0 matches only 1757 and 1773.

All other lines are unchanged. Run 0 reproduces an earlier 1700 decile table in the workbook (`Deciles!B14:D20`, mean 566.2402), so the surviving do-file sits between the two pasted versions.

## Excel layer
`Fiscal policy.xlsx` was not edited. `extract_results.R` clears every formula cell, recalculates all 382 formulas from the input cells (tidyxl; the operations are arithmetic, cell and range references, SUM and AVERAGE) and compares each result with the cached value (`recalc_fidelity.csv`). All 278 recalculable formulas match. 93 formulas in `VOC Income (VD&R)!F5:F97` point to an external workbook (`[1]Agricultural production`) that does not survive, and 11 cells (`N14:N24`) depend on them. None of these feeds a claim.
