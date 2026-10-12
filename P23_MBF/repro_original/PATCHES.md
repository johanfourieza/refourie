# P23_MBF S2 patches

Software: StataNow 19.5 MP (batch, `/e`), `version 16` (the do-files carry no version statement; era 2020+ → 16 per PROTOCOL S2). SSC packages are installed in `repro_original/ado/plus` (`code/00_setup_ado.do`, `code/01_setup_ado_corrtex.do`); versions are in `env_stata_ado.txt`. Built-in `spregress`, `spmatrix`, `spshape2dta`, `spbalance` and `logit` are used.

The authors' do-files are working scratchpads (1,800–2,300 lines; several variants of each table, `edit` commands, syntax fragments such as `replace migrant=1 if id_birth!=` at line 161 of the regression file), so they cannot run top to bottom. Each run file below executes **a verbatim contiguous line range** of the copied do-file (copies in `code/`), with a short environment header. Apart from the use/cd/memory lines, every patch was checked with `diff` against the source range.

Common header in every run file (environment only):
```stata
version 16
clear all
set more off
sysdir set PLUS     ".../P23_MBF/repro_original/ado/plus"
sysdir set PERSONAL ".../P23_MBF/repro_original/ado/personal"
do ".../tools/paths.do"                          // $DATA = D:/Data/ReplicateMe (A6)
cd ".../P23_MBF/repro_original/out_t#"            // replaces Laura's cd "C:\Users\orxlm01\Dropbox\...\ld"
```

## P1 `code/run_t2.do`: Table 2
Source: `1_micro_all_primary_idbirth_regression_analysis_220131.do` lines 44–104 ("Table 2, coefficientes, no controls", cols 1–4).
```diff
-use "1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear  /* ... */
+use cntry_code cntry_name id_birth tribe_co_1 d_primary d_birth d_birth_all d_birth_coup d_birth_elite d_age_prim_bef d_ethnic age i_age_age d_female d_christian rural tse_r railway_density count_tribe slave_density d_mission d_centraliz d_capital dist_cap d_western lat_id_bir lon_id_bir prim_in_plus2 prim_in_plus3 using "$DATA/P23_MBF/original/ld/1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta", clear  /* ... */
```
Reason: path (A6), plus memory. The file has 5.73M rows × 156 vars (4.8 GB) and only ~4.6 GB of RAM was free. Loading the 30 variables referenced in the block does not change any estimate, because every variable used in an estimation command or `if` condition is loaded. `suit_cerea` is listed in the outreg2 `drop()` options but does not exist in the file, so it was removed from the load list (outreg2 ignores absent names).

## P2 `code/run_t3.do`: Table 3
Source: same file, lines 282–356 ("Table 3, coefficientes, + coup and elite", cols 1–4). Patch identical to P1. Lines 282–356 are byte-identical to lines 319–396 of `1_micro_all_primary_idbirth_correlations_230131.do`, so the two named entry files give the same Table 3.

## P3 `code/run_t4.do`: Table 4 (spatial GS2SLS)
Source: `1_spatial_analysis_test_all_MATRIX_200519_new (no ethnic regression).do` lines 128–1226 (line ~1226: "END (the rest is not presented in the paper)").
- Runs in a **work copy** `D:/Data/ReplicateMe/P23_MBF/repro_original/t4work/` (the collapsed-panel .dta files, `birth_region_sample_master_for_stata_*` files and `id_birth_largest_tribe.dta` copied from `original/ld`), because the code `save ..., replace`s its own inputs (e.g. lines 203, 217, 251) and re-creates the spshape2dta files.
- **Lines 1–127 are not run.** They generate variables from `ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo.dta` and save `1_ipumsi_africa_all_..._geo.dta`. The surviving input was re-saved on 6 Jun 2022 with 48 variables and no `d_lead_eth`, so line 33 fails (`d_lead_eth not found`; first attempt in an earlier version of `logs/run_t4.log`, since overwritten). The block's saved output `1_ipumsi_africa_all_..._geo.dta` (27 Feb 2022, 85 vars, all generated variables present) is used as the entry point at line 130, where the code itself loads it.
- Lines 128–129: `set max_memory 32g, permanently` / `set matsize 11000, permanently` → without `, permanently` (no change to the system's Stata settings).
- Line 307 (`corrtex yrschool gini ...`) → `capture noisily corrtex ...`. In sequence, this line runs on the shapefile attribute file in memory (no `yrschool`), so it errors (r(111)). It writes a descriptive correlation table only, not part of Table 4.
- Shapefile companions (`birth_region_sample_master_for_stata_*.shp/.shx/.dbf/.prj/.cpg/.qpj/_shp.dta`, and `..._all_wa.dta`) were not copied in S1. They were copied from `Dropbox\ld` with `tools/copy_source.py` (appended to `original/MANIFEST.csv`; data on D: per A6).

## P4 `code/run_t5.do`: Table 5
Source: `1.4_leaders and murdock (not included).do` lines 484–535 (the four `logit d_birth d_mission ...` columns) on the surviving `1_murdockanddbirth_final.dta` (7 Jun 2022). The `use` path is changed to `$DATA/...`. The construction lines 1–483 are not run: they rebuild and overwrite that file from raw CSVs, which is out of scope.

## A' alignment runs (NOT original code; labelled separately, results in `results_original_Aprime.csv`)
- **A'1 `code/run_t3_Aprime.do`**: `run_t3.do` with `vce(cluster tribe_co_1)` → `vce(cluster id_birth)` in all four columns. Evidence: (i) print reports 602/609/609/609 clusters, while the original code gives 147/149/149/149 `tribe_co_1` clusters; (ii) Table 2 clusters on `id_birth` (624); (iii) the ethnicity variant of Table 3 in the same file (lines ~430–500) uses `vce(cluster id_birth)`; (iv) the A' run reproduces every printed SE, star and cluster count (see audit). The comment "* same reuslts clustered at tribe_co_1" (lines 45, 158, 283) is boilerplate repeated above blocks that cluster on id_birth, so it suggests that the cluster variable was later switched to tribe_co_1 for Table 3. Coefficients are unchanged by construction.
- **A'2 `code/run_t5_Aprime.do`**: Table 5 col 4 = original col 4 + `d_capital`. Evidence: `d_capital` is in every column's outreg2 `drop()` list (lines 495, 502, 510, 518). The result matches print exactly (9.099, SE 4.268, N 64, R² .407). Col 3 = original col 3 without `meanalt`. Evidence (weaker): it was found by a search over all 256 subsets of {lat lon coast river meanalt tsi meantemp d_capital} (`_scratch/t5probe3.do`, on D:). Of the four subsets whose coefficient is within ±0.006 of 2.54, it is the only one that also matches the printed SE (1.26) and R² (.185) (2.544, 1.259, .1849).

## Not patched / not run
Raw IPUMS extracts and all construction do-files (`1_Calculate…`, `1.2_*`, `…datasetconstruction_210927.do`) are out of scope. Table 1 has no code.
