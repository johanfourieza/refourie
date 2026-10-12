# P09_FIM S2 patches: EARLIER-VERSION run (2015 do-files on the 2015 workbook)

**Label.** Nothing here reproduces the 2022 EHB paper. No code or data for the 2022 version survives (audit.md, S1). These runs execute the 2015 working-paper do-files (births 1865–1895; AOF, CMP, SAC, WWI; no WWII; no weights) on the only matching data, sheet `Data` of `Whitelivingstandards_7July.xlsx`. The test is whether the 2015 code reproduces the 2015 authors' own output sheets, which are saved in the same workbook.

Software: StataNow 19.5 MP, batch mode, under `version 13`. R 4.5.2. Versions are in `stata_ado.txt`.

## Run order
```
Rscript 00_recalc_xlsx.R                     # E3: recalculate the workbook formula chain -> _scratch/whiteliving2015.dta
cd logs;            StataMP-64 /e do ../00_setup_ado.do          # E2: ssc estout, coefplot -> ./ado
cd logs;            StataMP-64 /e do ../01_float_storage.do      # E5: float storage
cd logs/wls8July;   StataMP-64 /e do ../../Whitelivingstandards.do
cd logs/wls15July;  StataMP-64 /e do "../../Second round/Whitelivingstandards15July.do"
cd logs/wls26July;  StataMP-64 /e do "../../Second round/Whitelivingstandards26July.do"
cd logs/wls8July_Aprime;  StataMP-64 /e do ../../aprime/Whitelivingstandards_Aprime.do      # A'
cd logs/wls26July_Aprime; StataMP-64 /e do ../../aprime/Whitelivingstandards26July_Aprime.do # A'
Rscript 02_compare_2015_sheets.R             # rerun vs 2015 output sheets -> compare_2015_sheets.csv
Rscript 03_results_original.R                # results_original.csv (all claims unavailable)
```
Data: `D:/Data/ReplicateMe/P09_FIM/repro_original/_scratch/whiteliving2015.dta` (A6; not in Dropbox).

## Environment patches (E)

**E1. Header block, identical in all three do-files** (inserted after line 1, `*Use Whitelivingstandards dataset`):
```diff
 *Use Whitelivingstandards dataset
+* --- S2 ENVIRONMENT PATCH (P09_FIM, EARLIER-VERSION run; see PATCHES.md) ---
+version 13
+clear all
+set more off
+adopath ++ "../../ado"
+do "../../../../tools/paths.do"
+use "$DATA/P09_FIM/repro_original/_scratch/whiteliving2015.dta", clear
+* --- end patch ---
```
- The do-files have no `version` statement. Following PROTOCOL S2, `version 13` is used for files dated 2012–15 (July 2015).
- The do-files have no load statement. Line 1 is a comment naming a "Whitelivingstandards dataset" (.dta) that does not survive; the `use` replaces it (see E3).
- Apart from this block, `diff original/ repro_original/` is empty for all three files. Line endings (CRLF) are preserved.

**E2. Packages.** `ssc install estout` (estout, eststo) and `coefplot` go into `repro_original/ado` (`00_setup_ado.do`), and each run prepends that folder to the adopath.

**E3. Rebuilding the input dataset from the workbook (`00_recalc_xlsx.R`).**
- Sheet `Data` has 24,542 rows, and 212,042 of its cells are formulas.
- The formula chain is re-evaluated in R from the raw inputs with tidyxl, not read from cached values. It covers:
  - Afrikaans (surname VLOOKUP into `Afrikaans!B`, which is itself `PROPER(A)`);
  - Repeat (an adjacent-row name match);
  - Birthyear (`Year − ROUNDDOWN(Age)`);
  - HISCO (calling VLOOKUP into `Occu!C`, which is itself `INT(B/10)`);
  - Class, Farmer and Region (`Place!C`, also self-referencing);
  - Urban (`Towns 2`) and Black.
- Excel semantics are reproduced: VLOOKUP exact match is case-insensitive and type-sensitive, with `*`/`?` wildcards (6 surname keys and 31 calling keys contain them); a blank result returns 0; text sorts above numbers in comparisons; text equality is case-insensitive.
- **Result: 0 mismatches against the cached values in all 12 formula columns** (`recalc_check.csv`).
- Variables are lower-cased as the do-files expect. Text "." becomes Stata missing, as a paste into the Stata data editor would do.
- The columns names, surname, signed-at, calling and place of birth are not used by any do-file and are dropped (data minimisation). This changes no analysis.

**E4. Working directories.** Each run executes in its own `logs/<run>/` folder, so the same-named estout outputs (`whiteliv.txt` in the 15 July and 26 July files) do not overwrite each other.

**E5. Float storage (`01_float_storage.do`).** haven writes numeric variables as double, but Stata's default storage type for data entered by paste or import is float, so all numeric variables are recast to float.
- **Why this matters.** 218 heights are exactly 160.02 cm (63 in), which is the truncation point `ll(160.02)`.
  - As float, 160.02 is stored as 160.0200043 > 160.02, so these heights stay in the truncated sample.
  - As double, they equal the limit and truncreg drops them.
- **Evidence that the 2015 authors had float storage.**
  - In the 2015 `Martine` sheet the truncreg N equals the OLS N (3,917 and 3,917).
  - With double storage the rerun gives truncreg N = 3,893 and AOF/SAC/CMP coefficients 5.406/… against the sheet's 5.616/….
  - With float storage every coefficient matches to 3 dp.
- **Double run kept.** The double-storage run is kept as `logs_double/` (superseded; documents the sensitivity).

## A' alignment runs (labelled; not original code)
The original 8 July and 26 July files halt with a Stata error before any regression. The A' copies in `aprime/` make only the changes below, and each change is marked `*A-PRIME*` in the file.

**A1. `Whitelivingstandards.do`, original lines 71–79** (the `collapse … by(afridum)` graph block) are commented out.
- `afridum` exists in no sheet of the surviving workbook, so the run halts with r(111) at line 73.
- The block only draws a graph. The regressions follow it.

**A2. `Whitelivingstandards26July.do`, original lines 46–56** (the black-only graph block) are commented out.
- Line 17 (`drop if black == 1`), added on 26 July, empties the sample, so `collapse` halts with r(2000) at line 49.

**A3. `Whitelivingstandards26July.do`, original line 98:** the typo `urbanib6.hisco` becomes `urban ib6.hisco`.
- The same line in the 15 July file (line 96) reads `urban black ib6.hisco`.
- Unfixed, it would halt with r(111), and the Western Cape/Boer republic coefplot and the later tables would not run.

```diff
--- Second round/Whitelivingstandards26July.do
+++ aprime/Whitelivingstandards26July_Aprime.do
-quietly truncreg height ib3.sourcedum	i.regiondum	age	afrikaans urbanib6.hisco by2-by6 if boer==1, ll(160.02)
+* A-PRIME ALIGNMENT (see PATCHES.md A3): typo urbanib6.hisco -> urban ib6.hisco, as in the 15 July line
+quietly truncreg height ib3.sourcedum	i.regiondum	age	afrikaans urban ib6.hisco by2-by6 if boer==1, ll(160.02)
```

## Run status
| run | status | outputs |
|---|---|---|
| 8 July (original) | **failed** at line 73, r(111) `afridum` not found | descriptives only |
| 15 July (original) | **completed** | whiteliv.txt, whitebirthyears.txt |
| 26 July (original) | **failed** at line 49, r(2000) no observations | descriptives only |
| 8 July A' | completed | whiteliving.txt, whiteliving2.txt |
| 26 July A' | completed | whiteliv.txt, whitebirthyears.txt, martine.txt |

## Rerun vs 2015 output sheets (`compare_2015_sheets.csv`; birth-year and year FE rows excluded)
| 2015 sheet | rerun | match |
|---|---|---|
| Regressionfinal, specs 1–6 | 15 July whiteliv.txt (original) | **104/104 exact to 3 dp** (incl. N 6287/5585/5585/5490/5490/5502, sigma) |
| Sheet1 (tabstat by birthyear) | 15 July log | totals match (N 6,317; mean height 172.538; AOF 375) |
| Sheet3, specs 1–5 | 26 July whiteliv.txt (A' run; not reached in the original run) | **77/77 exact** |
| Sheet3, spec 6 (OLS) | 26 July line 85 | differs: the sheet's OLS includes `age`, which the surviving line 85 omits. The code was edited after the sheet was made |
| Sheet4, est1–4 | 26 July whitebirthyears.txt (A') | **116/116 exact** |
| Martine, est1–2 | 26 July martine.txt (A') | **44/44 exact** |
| Regression 1 / 2 | 8 July whiteliving/whiteliving2 (A') | close, not exact: N 937 vs 940 and 9,698 vs 9,858; Afrikaans 1.592 vs 1.504. The 8 July code ran on an earlier data vintage (the 13 June or 1 July workbooks, which were not copied) |
| WithWithout, Sheet2 | — | no surviving code line produces these specifications |
