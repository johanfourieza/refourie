# P18_FvFS — S2 patches and extraction record

Software: StataNow 19.5 MP (batch, `"C:\Program Files\StataNow19\StataMP-64.exe" /e do <file>`), run 11 Oct 2026. R 4.5.2 for mapping and comparison. No ssc packages were installed (outreg2/esttab are absent; estimates are exported with `postfile` instead, which changes no number).

## 0. Archive extraction (`repro_original/extracted/`)

| archive | tool | contents |
|---|---|---|
| `original/French Huguenots/results.zip` | `unzip` (Git Bash) | `results/exclpc/` and `results/exclpc_novines/`: each has `settlers_excl_1.smcl` (log, 22 Nov 2010), `final_excl_1.dta` (10,243 x 113), 20 outreg2 `.xls` + 20 `.tex` (wine/wheat x anova/capital x full, q, f, fq, nf, nfq) and 16 `.wmf` graphs (wine/wheat by year). The two folders' logs are identical apart from path and timestamp; the `exclpc_novines` outputs drop the vines terms. |
| `original/French Huguenots/ee.7z` | Windows `C:\Windows\System32\tar.exe` (bsdtar 3.8.8 / libarchive, reads 7z); no pip install needed | `data for Figure 1.xls`, `data for Figure 2.xls`, `data for Figure 3.xls`, `Data for Figure 4.xls`, `Data for Figure 5.xls`, `data for Figure 6.xls` (Dec 2008). These are the Cliometrica-paper figure data, not P18 material. |

## 1. `hhsize.do` (environment patches only; pure S2)

Copied from `original/French Huguenots/hhsize.do`. Diff:

```diff
-use "C:\Documents and Settings\johanf\My Documents\Navorsing\Economic History\PhD Utrecht\1. Wealth in the Cape economy\opgaafrolle.dta", clear
+version 11
+capture log close
+log using hhsize_results.log, text replace
+use "../original/Statafiles/opgaafrolle.dta", clear
 ...
+log close
```

- Path patch to the copied `Statafiles/opgaafrolle.dta`.
- `version 11` added (file dated Dec 2010; protocol rule "11 for files before 2012"). Needed also because the old `table ..., c(mean wyn)` syntax was replaced in Stata 17.
- A named text log (`hhsize_results.log`), because batch mode already writes `hhsize.log`.

## 2. `settlers_from_log.do` (reconstruction; environment patches only)

The surviving log `settlers_excl_1.smcl` **echoes no commands**: `settlers.do` was run quietly, so the log holds only `(n real changes made)`, `(n observations deleted)`, five `summarize` tables and outreg2 file notes. A file "containing exactly the commands echoed in the log" therefore cannot be written. The regression block was rebuilt instead from:
- the log's observation counts: 4,305 deleted leaves the 8 census years of Table 2 (N = 5,938 = 270+372+404+568+759+801+1,139+1,625); 4,455 deleted leaves the Huguenot sub-sample (N = 1,483);
- the regressor labels, column names and N of the 40 outreg2 files (an `_IgroXvines_2` label shows `xi: i.group*vines_planted`);
- the variables in `final_excl_1.dta`.

Specification found: `reg l_<y>_zero <regressors> if year==Y [aw=hhsize], robust` year by year, with `l_<y>_zero = ln(y per household member, zeros set to 0.001)`, group x (slaves, knechts, vines or wheat sown) interactions, district base Drakenstein, marital dummies, and in the Huguenot files base NWH and marital base "married to WH". **Verification:** `verify_2010log.R` compares all 1,113 numeric cells (coefficients, SEs, R², N, F) of the 10 estimable families x 8 years with the outreg2 output: 1,113/1,113 coefficients and 887/887 SEs agree to the printed 3 dp (`compare_2010log.csv`). The weights and robust SEs are pinned down by the F statistics (e.g. 1700 wine_anova F = 17.064 only with `[aw=hhsize], robust`).

Environment patches: paths; `xi:` replaced by factor-variable notation (same columns); outreg2 replaced by `postfile`. Not re-run: the data-construction block (its raw input is not in results.zip) and the `q*`, `fq*`, `nfq*` files, which contain no estimates of their own: every column repeats the stored 1773 wheat estimates (e.g. `qwine_capital_1.xls` = `wheat_capital_1.xls` col `W_y1773`), so the commands behind them failed or were never run (code bug in the 2010 run, no bearing on the paper).

## 3. `published_spec_attempt.do` — ANALYTIC changes (pair A'; "spec-alignment, not environment")

Starts from the Nov 2010 lineage (data `final_excl_1.dta`, dependent variables `l_wine_zero`, `l_wheat_reaped_zero`, `[aw=hhsize]`, `robust`) and changes only what print specifies differently. Changes marked OUTCOME-INFORMED were selected because they reproduce print; the paper text alone does not determine them.

| id | change | basis | line |
|---|---|---|---|
| ALIGN-1 | Table 1-2 on `opgaafrolle.dta` (hhsize.do lineage): keep farmers (non-zero on any agricultural variable) and 1700-1773 | text p.940 and T1 note "Only farming households" | 42-47 |
| ALIGN-2 | Table 2 = per-capita output weighted by household size (hhsize.do weights household totals) | T2 note | 56-66 |
| ALIGN-1b/2b | Tables 1-2 recomputed on the analysis file (sample identical to Tables 3-5); totals restored as x*hhsize | T1 N = 9,078 equals the regression N | 80-102 |
| ALIGN-3 | pooled 14 census years 1700-1773, excluding 1716 (2010 run: 8 years, year by year) | text p.937, T3 notes (base 1700), N = 9,078 | 72-73 |
| ALIGN-4 | vines per household member (2010 code: vines per household). OUTCOME-INFORMED: the notes say only "numbered in 1,000s"; per-member vines reproduces T3 col 3 exactly, per-household vines does not (WH 0.610 vs 0.752) | T3-T4 | 74-77 |
| ALIGN-5 | no group x input interactions; district base Cape Town; marital base "not married to a Huguenot"; year dummies; born-abroad dummy; spec-by-spec control sets as printed (COERTZEN1, used in Dec 2010, dropped) | T3-T5 rows and notes; referee response round 3 ("not shown in the latest version") | 104-114 |
| ALIGN-6 | spec 10 = bivariate regression of the WH dummy on the born-abroad Huguenot sample (N = 368) | only WH and constant printed; the bivariate model reproduces print exactly | 133-135 |
| ALIGN-7 | A3 latitude/longitude/grouping dummies coded from Table A2 (bases South, West, group 1); col 19 interactions North x Central and North x East (print's "Central x Central" cannot exist under A2; OUTCOME-INFORMED reading of the label) | Table A2, A3 | 172-199 |
| ALIGN-8 | Germany and Italy in F-test group 2 (A2 lists both 1 and 2; text says 1). OUTCOME-INFORMED: group 2 reproduces col 20 exactly | A2, A3 col 20 | 181-185 |
| — | T5 col 16: numeracy is missing for all non-Huguenots, yet N = 9,078; how it entered is not stated. Mean imputation used; reported as `ambiguous` (it does not reproduce print) | T5 | 153-159 |
| — | A1/A4: region dummies replace the WH dummy, T4 col 7 controls (A1, as stated) / T5 col 15 controls (A4, controls not stated -> `ambiguous`); sample = known region (N = 2,045) | A1/A4 notes | 213-220 |
| — | A3 cols 25-27 not run: sending-region soldier heights are in no surviving file (`unavailable`) | | |

Standard errors: every surviving original-code output (Nov and Dec 2010) uses `reg ..., robust` (HC1) with `[aw=hhsize]`; neither is stated in the paper. `published_spec_attempt.do` keeps both. With HC1 the stars of all 639 reproduced coefficients match print.

## 4. A6 path refactor (2026-10-11) — ENVIRONMENT only, no analytic change

Under Amendment A6 all P18 data moved, with unchanged relative paths, to `D:/Data/ReplicateMe/P18_FvFS/` (log: `registry/data_moves.csv`). Path-only edits: the three `.do` files run `do ".../tools/paths.do"` and read/write `$DATA/P18_FvFS/...` (`opgaafrolle.dta`, `extracted/results/exclpc/final_excl_1.dta`, `published_spec_est.dta`, `settlers_from_log_est.dta`); `verify_2010log.R`, `repro_r/01-03`, `compare/s5_checks/*` and `modern/00_data.R`, `02_sensitivities.R` source `tools/paths.R` and use `dpath("P18_FvFS", ...)` (`repro_r/data/*.rds` now written on D:). CSV, `.tex`, `.pdf` and `.png` outputs stay in the project. `build_results.R`, `modern/01_primary.R` and `03_figures.R` read no data files and are unchanged. Re-run in order (Stata, repro_original R, repro_r, s5_checks, modern 00-03): every tracked CSV and `.tex` output is byte-identical; `coefplot.pdf` and `figure2_recreation.pdf` differ only in CreationDate/ModDate (restored from git); `farmers.rds` and `mooc.rds` are byte-identical; the two posted `.dta` files differ only in their Stata header timestamps (their exported CSVs are identical). One output drift not caused by the refactor: re-running `build_results.R` fills `inferential_agree` = TRUE in all 529 coefficient rows of `compare/comparison_A.csv`, which was committed (0a58e02, 07:17:06) before `tools/compare.R` gained stars-only inference (d6608f3, 07:17:45). All other columns are identical; the committed file was restored, pending a decision to regenerate it.
