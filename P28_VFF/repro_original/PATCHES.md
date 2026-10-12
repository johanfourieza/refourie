# P28_VFF — S2 patches (original-code reproduction)

Software: StataNow 19.5 MP, batch (`"C:\Program Files\StataNow19\StataMP-64.exe" /e do <file>`, run from `repro_original/` via PowerShell; Git Bash rewrites `/e` to `E:/` and hangs Stata). Run 11 Oct 2026.
Entry point: `original/Reversal of Fortunes/analysis Dec 2018.do` (409 lines; no `version` statement → `version 15` added, era rule 2016–19).
User-written packages: installed from SSC into a **project-local** PLUS tree (`repro_original/ado/plus`, via `sysdir set PLUS`), so nothing is written to `C:\Users\johanf\ado`. Versions: `env/stata_ado.txt` (estout 3.33/esttab 2.1.4 2026; moransi 1.31 2025; shp2dta 1.0.9 2015; spmap 1.3.2 2018; blindschemes 2020 for `plottig`). `setup_ado.do` → `setup_ado_versions.log`.
Bundled `ols_spatial_HAC.ado` (Hsiang) loaded with `do` from `original/` as in the original, plus `adopath ++`.

| file | role | toggles | output folder |
|---|---|---|---|
| `analysis_Dec2018_runA.do` | **Run A, as found** (environment patches only) | data off, regs on, conley on, maps off | `runA/` |
| `analysis_Dec2018_runMaps.do` | Run A, maps only (Figs 1–3) | maps on only | `runMaps/` |
| `analysis_Dec2018_runAprime.do` | **Run A′, version-gap alignment — ANALYTIC, not S2** | as Run A | `runAprime/` |
| `build_results.R` | maps outputs to claim_ids, runs S4 pair A, collects Conley | | `results_original*.csv`, `conley_results.csv`, `../compare/` |

## 1. Run A — environment patches (diff vs original)

| id | line (orig) | patch | type |
|---|---|---|---|
| ENV-1 | 1 | `cd "C:\Users\dieter2\..."` disabled; preamble sets `version 15`, local PLUS/PERSONAL, `$orig` = `../original/Reversal of Fortunes`, `cd runA`, text log | path / version |
| ENV-2 | 3–5 | globals toggled: `regs on`, `conley on`, `maps off` (author's own switches; maps run separately) | toggles |
| ENV-3 | 12 | `cap do ols_spatial_HAC.ado` → `cap do "$orig/ols_spatial_HAC.ado"` | path |
| ENV-4 | 20 | `moransi ...` + `replace`: moransi 1.31 (2025) writes local-Moran variables (`splag_res_p`, `lmoran_*`) and errors (r(110)) on the second call; the 2018 versions did not. Global Moran's I unchanged; Moran stats are not in the claims | package version |
| ENV-5 | 40, 47 | `$data` block paths (`$orig/1911_ZAEast_SWA_LSO`, `$orig/data.csv`) — block off in Run A | path |
| ENV-6 | after 152 | `if "$data"!="on" use "$orig/data.dta", clear`: with `$data off` the file loads no data (it relied on an interactive session) | session state |
| CAP-1 | after 35, 237, 340, 399 | additive output capture: program `dumpest` writes every stored estimate (b, se, N, r2, df_r, e(vce)) to CSV; Table 1 matrix to `T1_corr.csv`. No estimate is altered | output only |

Maps run (`analysis_Dec2018_runMaps.do`) additionally: `shp2dta using` paths to `$orig/...` (4 lines), `merge 1:1 id using "$orig/data"`, and `$orig` resolved to an absolute path without `..` (shp2dta treats any dot in the path as a file extension → r(601)).

**Run status: ran-with-env-patches** (all three runs end without error). Run A outputs equal the surviving original outputs: `runA/T1.tex`, `T3.tex` and all 14 `conley{20..1000}_{pop,welfare}.tex` are identical (whitespace-insensitive) to `original/.../`; `T2.tex` differs only in the row label `bl100` vs `Settle1830`. Diagnostic (`_scratch/runData.do`): the `$data` block rebuilds `data.dta` from `data.csv` with `cf _all` = match on all 125 variables.

```diff
--- original/Reversal of Fortunes/analysis Dec 2018.do
+++ analysis_Dec2018_runA.do
@@ -1,15 +1,26 @@
-cd "C:\Users\dieter2\Dropbox (Personal)\Research\1. Ongoing\Reversal of Fortunes"
+* ===== S2 ENVIRONMENT PREAMBLE (P28_VFF Run A) — replaces original line 1 (cd "C:\Users\dieter2\...") =====
+version 15
+sysdir set PLUS     "`c(pwd)'/ado/plus"
+sysdir set PERSONAL "`c(pwd)'/ado/personal"
+global orig "`c(pwd)'/../original/Reversal of Fortunes"
+adopath ++ "$orig"
+cap mkdir runA
+cd runA
+cap log close
+log using runA_results.log, text replace
+* ===== end preamble =====
+* ORIGINAL LINE 1 (disabled): cd "C:\Users\dieter2\Dropbox (Personal)\Research\1. Ongoing\Reversal of Fortunes"
 global data off
-global regs off
-global maps on
-global conley off
+global regs on   // S2: toggled on (original: off)
+global maps off  // S2: toggled off (original: on; maps run separately)
+global conley on // S2: toggled on (original: off)
 
 	*Which overlap threshold for Walker (1922) map?
 global settle bl100
 
 
 	*Import program that reports Conley Standard errors
-cap do ols_spatial_HAC.ado
+cap do "$orig/ols_spatial_HAC.ado"  // S2 path patch (original: cap do ols_spatial_HAC.ado)
 	*Moran statistics
 cap program drop addmoran
 program define addmoran
@@ -17,7 +28,7 @@
 estimates store `esttitle'
 cap drop res
 predict res, res
-moransi res, lat(y_cent) lon(x_cent) swm(pow 3) dist(.) dunit(km) approx detail
+moransi res, lat(y_cent) lon(x_cent) swm(pow 3) dist(.) dunit(km) approx detail replace  // S2 ENV PATCH: moransi 1.31 (2025) creates local-Moran variables and needs replace; 2018 versions did not
 scalar moran_z = r(zI)
 scalar moran_p = r(pI)
 estimates restore `esttitle'
@@ -34,17 +45,44 @@
 estimates store `name'
 end
 
+	* S2 OUTPUT CAPTURE (additive; changes no estimate): write every stored estimate to CSV
+cap program drop dumpest
+program define dumpest
+args fname tag
+qui estimates dir
+local names `r(names)'
+tempname ph
+postfile `ph' str32 model str32 var double(b se N r2 df_r) str16 vce str32 tag using `fname'.dta, replace
+foreach m of local names {
+	qui estimates restore `m'
+	tempname B V
+	matrix `B' = e(b)
+	matrix `V' = e(V)
+	local vars : colnames `B'
+	local k = colsof(`B')
+	forvalues i = 1/`k' {
+		local v : word `i' of `vars'
+		post `ph' ("`m'") ("`v'") (`B'[1,`i']) (sqrt(`V'[`i',`i'])) (e(N)) (e(r2)) (e(df_r)) ("`e(vce)'") ("`tag'")
+	}
+}
+postclose `ph'
+preserve
+qui use `fname'.dta, clear
+qui export delimited using `fname'.csv, replace
+restore
+end
+
 
 
 if "$data"=="on"{
-shp2dta using 1911_ZAEast_SWA_LSO, database(1911_db) coordinates(1911_coord) genid(_ID2) replace gencen(cent)
+shp2dta using "$orig/1911_ZAEast_SWA_LSO", database(1911_db) coordinates(1911_coord) genid(_ID2) replace gencen(cent)
 use 1911_db, clear
 keep ID x_cent y_cent
 ren ID id
 tempfile gps
 save `gps', replace
 
-import delimited "C:\Users\dieter2\Dropbox (Personal)\Research\1. Ongoing\Reversal of Fortunes\data.csv", clear
+import delimited "$orig/data.csv", clear  // S2 path patch
 merge 1:1 id using `gps'
 
 gen l_pop1911 = log(popdens1911)
@@ -151,6 +189,10 @@
 save data, replace
 }
 
+* S2 ENV PATCH: with $data off the original relies on data.dta already being in memory
+* (interactive session after a $data run). Load the surviving analysis file explicitly.
+if "$data"!="on" use "$orig/data.dta", clear
+
 if "$regs"=="on"{
 *Correlations
 corr $settle l_pop1911 l_pop1996 l_pop2011 l_u1996 l_u2011 l_lights96  l_lights11 rain tri csi if sample==1
@@ -236,6 +278,27 @@
 estout u1996_3	u1996_4	/*u1996_6	u1996_7*/  /*inc96_3	inc96_4*/ lights96_3	lights96_4 /*lights96_6 lights96_7*/ u2011_3	u2011_4	u2011_6	u2011_7 /*inc11_3	inc11_4*/ lights11_3	lights11_4 lights11_6 lights11_7 using T3.tex, style(tex) order(l_pop1911 p_homeland l_pop1996 l_pop2011 l_netmig_11 /*csi*/ tri rain_level)  replace cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F moran_z moran_p, fmt(3 3 3 3 3) label("R-squared" "N" "F" "Moran Z" "Moran p-value")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
 }
 
+* S2 OUTPUT CAPTURE (additive; changes no estimate): Table 1 matrix and Table 2-3 estimates to CSV
+if "$regs"=="on" {
+	local rn : rownames correl
+	local cn : colnames correl
+	tempname pc
+	postfile `pc' str32 row str32 col double r using T1_corr.dta, replace
+	forvalues i = 1/`=rowsof(correl)' {
+		forvalues j = 1/`=colsof(correl)' {
+			local a : word `i' of `rn'
+			local b : word `j' of `cn'
+			post `pc' ("`a'") ("`b'") (correl[`i',`j'])
+		}
+	}
+	postclose `pc'
+	preserve
+	qui use T1_corr.dta, clear
+	qui export delimited using T1_corr.csv, replace
+	restore
+	dumpest regs_est ols_default
+}
+
 if "$maps"=="on"{
 *Maps
 
@@ -337,6 +400,7 @@
 
 esttab * using conley`distcut'_pop.tex, replace style(tex) order($settle l_pop1911 p_homeland l_pop1996 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) label
 
+dumpest conley`distcut'_pop conley`distcut'  // S2 output capture
 estimates clear
 
 	*T3
@@ -397,6 +461,7 @@
 
 
 esttab * using conley`distcut'_welfare.tex, replace style(tex) order(l_pop1911 p_homeland l_pop2011 l_netmig_11 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) label
+dumpest conley`distcut'_welfare conley`distcut'  // S2 output capture
 end
 
 
@@ -407,3 +472,5 @@
 }
 
 
+
+cap log close  // S2
```

```diff
--- analysis_Dec2018_runA.do
+++ analysis_Dec2018_runMaps.do
@@ -1,19 +1,24 @@
-* ===== S2 ENVIRONMENT PREAMBLE (P28_VFF Run A) — replaces original line 1 (cd "C:\Users\dieter2\...") =====
+* ===== S2 ENVIRONMENT PREAMBLE (P28_VFF Run Maps) — replaces original line 1 (cd "C:\Users\dieter2\...") =====
 version 15
 sysdir set PLUS     "`c(pwd)'/ado/plus"
 sysdir set PERSONAL "`c(pwd)'/ado/personal"
 global orig "`c(pwd)'/../original/Reversal of Fortunes"
+* S2 ENV PATCH (maps run): shp2dta treats any dot in the path as an extension, so resolve $orig without ".."
+local here `c(pwd)'
+qui cd "$orig"
+global orig "`c(pwd)'"
+qui cd "`here'"
 adopath ++ "$orig"
-cap mkdir runA
-cd runA
+cap mkdir runMaps
+cd runMaps
 cap log close
-log using runA_results.log, text replace
+log using runMaps_results.log, text replace
 * ===== end preamble =====
 * ORIGINAL LINE 1 (disabled): cd "C:\Users\dieter2\Dropbox (Personal)\Research\1. Ongoing\Reversal of Fortunes"
 global data off
-global regs on   // S2: toggled on (original: off)
-global maps off  // S2: toggled off (original: on; maps run separately)
-global conley on // S2: toggled on (original: off)
+global regs off  // S2 maps-only run (original: off)
+global maps on   // S2 maps-only run (original: on)
+global conley off // S2 maps-only run (original: off)
 
 	*Which overlap threshold for Walker (1922) map?
 global settle bl100
@@ -302,15 +307,15 @@
 if "$maps"=="on"{
 *Maps
 
-shp2dta using settlers_merged, database(routes_db) coordinates(routes_coords) genid(_ID) replace
-shp2dta using homeland_clipped, database(homeland_db) coordinates(homeland_coords) genid(_ID) replace
-shp2dta using Landact1913, database(landact_db) coordinates(landact_coords) genid(_ID) replace
+shp2dta using "$orig/settlers_merged", database(routes_db) coordinates(routes_coords) genid(_ID) replace
+shp2dta using "$orig/homeland_clipped", database(homeland_db) coordinates(homeland_coords) genid(_ID) replace
+shp2dta using "$orig/Landact1913", database(landact_db) coordinates(landact_coords) genid(_ID) replace
 
-shp2dta using 1911_ZAEast_SWA_LSO, database(1911_db) coordinates(1911_coord) genid(_ID2) replace gencen(cent)
+shp2dta using "$orig/1911_ZAEast_SWA_LSO", database(1911_db) coordinates(1911_coord) genid(_ID2) replace gencen(cent)
 use 1911_db, clear
 ren ID id
 keep id _ID2
-merge 1:1 id using data, nogen
+merge 1:1 id using "$orig/data", nogen  // S2 path patch
 
 
 graph drop _all
```

## 2. Standard errors used by the code

Every Table 2–3 regression is `reg y x if sample==1` with no `vce()` option: **conventional homoskedastic (iid) OLS SEs**, `e(vce) = "ols"`, t with N−k−1 df (`runA/regs_est.csv`, column `vce`). The paper never states the SE type. The online-supplement Conley SEs come from `ols_spatial_HAC` with the default **uniform** kernel (no `bartlett`), `timevar = 1`, `lag(0)`, cut-offs 20–1000 km; the stored model is `spatial` (cross-sectional Conley).

## 3. Run A′ — version-gap alignment (analytic, not environment)

These swaps are **not S2 patches**. They implement the S1 finding that the published tables come from a lost variant of the do-file that used variables already present in `data.dta`. Each swap is OUTCOME-INFORMED (chosen because it reproduces print); results are reported separately as pair A′.

| id | change | evidence | where |
|---|---|---|---|
| VG-1 | `replace l_pop1996 = log(p_96_old/area)` (data.dta: `log(p_96/area)`, verified to 1e-7) | Run A gives T2 col 4 Homeland 0.551, col 8 Pop1911 0.354, Pop1996 0.625, col 9 Pop1911 0.358 vs print 0.552/0.355/0.624/0.359; `p_96_old` gives all four exactly (`_scratch/vgap.log`). Affects Tables 1–2 (T3 has no Pop1996 regressor) | after data load |
| VG-2 | Table 1 only: `l_u1996` → `l_u1996_old = log(u_96_old)` | Run A T1 Unem1996 column 0.300/0.585/0.628/0.794 vs print 0.303/0.583/0.625/0.791; old vintage reproduces all 11 cells. **Not applied to Table 3**: Table 3 cols 1–2 print 0.063/0.522 and 0.466, which `log(u_96)` reproduces and `log(u_96_old)` does not (0.062/0.520, 0.465) | `corr` line (orig 156) |
| VG-3 | Table 1 only: `tri` → `l_tri` (log ruggedness) | Run A T1 Rugged column 0.192/0.468/0.428/0.566/0.555/-0.185/-0.356/0.451/0.618 vs print 0.223/0.503/0.405/0.503/0.497/-0.151/-0.297/0.477/0.695; `l_tri` reproduces all. Table 2–3 Rugged coefficients (0.016, -0.056, ...) match level `tri` (= TRI/10000) and are left unchanged | `corr` line |

Consequence: the published paper mixes vintages — Table 1 uses the old 1996 unemployment series, Table 3 the new one; "Rugged" is log TRI in Table 1 and level TRI/10000 in Tables 2–3.

```diff
--- analysis_Dec2018_runA.do
+++ analysis_Dec2018_runAprime.do
@@ -1,13 +1,13 @@
-* ===== S2 ENVIRONMENT PREAMBLE (P28_VFF Run A) — replaces original line 1 (cd "C:\Users\dieter2\...") =====
+* ===== S2 ENVIRONMENT PREAMBLE (P28_VFF Run Aprime) — ANALYTIC VARIANT, NOT AN S2 ENVIRONMENT RUN — replaces original line 1 (cd "C:\Users\dieter2\...") =====
 version 15
 sysdir set PLUS     "`c(pwd)'/ado/plus"
 sysdir set PERSONAL "`c(pwd)'/ado/personal"
 global orig "`c(pwd)'/../original/Reversal of Fortunes"
 adopath ++ "$orig"
-cap mkdir runA
-cd runA
+cap mkdir runAprime
+cd runAprime
 cap log close
-log using runA_results.log, text replace
+log using runAprime_results.log, text replace
 * ===== end preamble =====
 * ORIGINAL LINE 1 (disabled): cd "C:\Users\dieter2\Dropbox (Personal)\Research\1. Ongoing\Reversal of Fortunes"
 global data off
@@ -193,9 +193,19 @@
 * (interactive session after a $data run). Load the surviving analysis file explicitly.
 if "$data"!="on" use "$orig/data.dta", clear
 
+* ===== VERSION-GAP ALIGNMENT (ANALYTIC, not environment) — PATCHES.md section 3 =====
+* VG-1: published Table 1-2 Pop1996 = log(p_96_old/area) (data.dta l_pop1996 = log(p_96/area))
+replace l_pop1996 = log(p_96_old/area)
+* VG-2: published Table 1 Unem1996 = log(u_96_old); Table 3 keeps log(u_96) (it matches print), so only the correlation matrix uses it
+gen l_u1996_old = log(u_96_old)
+label var l_u1996_old "Un1996 (old vintage)"
+* ===== end version-gap alignment =====
+
 if "$regs"=="on"{
 *Correlations
-corr $settle l_pop1911 l_pop1996 l_pop2011 l_u1996 l_u2011 l_lights96  l_lights11 rain tri csi if sample==1
+* ORIGINAL (Run A): corr $settle l_pop1911 l_pop1996 l_pop2011 l_u1996 l_u2011 l_lights96  l_lights11 rain tri csi if sample==1
+* VG-2/VG-3 (ANALYTIC): l_u1996 -> l_u1996_old; tri -> l_tri (log ruggedness) in Table 1 only
+corr $settle l_pop1911 l_pop1996 l_pop2011 l_u1996_old l_u2011 l_lights96  l_lights11 rain l_tri csi if sample==1
 matrix correl = r(C)
 estout matrix(correl, fmt(3)) using T1.tex, style(tex) replace 
 
```

## 4. A6 path refactor (2026-10-11; path-only, no estimate changes)

Amendment A6 moved all P28_VFF data to `D:/Data/ReplicateMe/P28_VFF/` (same relative paths; log `registry/data_moves.csv`). Scripts were edited for paths only; `original/` untouched.

- Run files (`analysis_Dec2018_run{A,Aprime,Maps}.do`): preamble now runs `do ../../tools/paths.do`; `$orig` points to `$DATA/P28_VFF/original/Reversal of Fortunes` (data); new `$code` keeps the project copy of `original/Reversal of Fortunes` for `adopath` and `ols_spatial_HAC.ado` (code did not move); new `$out = $DATA/P28_VFF/repro_original/run<X>` receives data outputs (`dumpest` and `T1_corr` .dta, the four estout `.xls`; in runMaps the `shp2dta` database/coordinate .dta and their `use`/`spmap` reads). Logs, `.tex`, `.csv`, `.png`/`.eps` stay in `repro_original/run<X>/`. The ado tree `repro_original/ado/` did not move; `sysdir` unchanged. Unexecuted `$data on` / `$maps on` lines in runA/runA′ were left as they were.
- `compare/s5_checks/conley_bartlett.do`: same `$code`/`$orig` split; `$scr = $DATA/P28_VFF/compare/_scratch_s5` for the .dta/.csv and the explicit log (the Stata batch log stays in `s5_checks/`).
- R: `repro_r/01-03`, `compare/s5_checks/s5_checks.R`, `modern/common.R` (ORIG, SCR), `modern/00_provenance.R` (DL = `modern/_downloads` on D:, not re-downloaded), `modern/01_conley.R` (S5 scratch reads) source `tools/paths.R` and use `dpath("P28_VFF", ...)` / `dscratch("P28_VFF", "repro_r", ...)`. `build_results.R`, `modern/02-05` read no data files and were not edited.
- Re-run (runA, runA′, runMaps, build_results, repro_r 01-03, s5_checks, modern 00-05): tracked tables/CSVs byte-identical; D: data outputs content-identical to the pre-run copies (.dta differ only in the embedded timestamp; .xls and S5 scratch CSVs byte-identical to the last committed versions). Non-numeric diffs only: R PDF timestamps; `conleyreg_crosscheck.csv` SEs at the 15th significant digit (conleyreg is not bit-reproducible run to run); 3 anti-aliased pixels in the source-note text of `runMaps/geo.png` and `pop.png` (the `.eps` versions are byte-identical; the new PNGs are stable across two re-runs).
