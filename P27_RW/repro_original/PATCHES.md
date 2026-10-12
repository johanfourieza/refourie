# P27_RW S2 patches

No do-file or R script produced the published tables (S1). The code run here was written for S2; it is not a patched original.

| File | Change | Reason |
|---|---|---|
| `Stata/01_descriptives.do` (new) | `version 11`; paths via `do ../../tools/paths.do` and `$DATA`; writes `$DATA/P27_RW/repro_original/_scratch/stata_out.csv` | Table 3 and 4 `summarize, detail` on `numbersandwealth.dta` and `opgaafrolle.dta` (the author ran these interactively). Sample rule: `keep if !missing(slavesnumb)` (N = 2,577, as in S1); for opgaafrolle, `jaar` 1700-73, taken from the claims' population wording. |
| `R/02_excel_chain_and_results.R` (new) | tidyxl re-implementation of the `ChapterValue.xlsx` chain (Prices2 -> Value2 -> total -> decade descriptives); Table 1 totals; Tables 6-8 Cape shares; assembles `results_original.csv` | Excel-only chain (PROTOCOL S2). |
| `original_dofiles/*.do` | Verbatim copies of `Lorenzcurves.do`, `Lorenzcurves2.do`, `gini.do`, `creatingslavegroups.do`. Not run, not patched. | They use 2010 absolute paths and produce Lorenz/Gini output. No claim in `claims.csv` is a Gini or Lorenz value, so nothing to compare; `glcurve`, `descogini`, `ginidesc` were not installed. |

No ssc package was installed (`ado/` is empty). Analytic content is unchanged.

## A-prime alignment run (separate, labelled)

`R/04_aprime_total.R` -> `results_original_Aprime.csv`. Table 5 "Total" restricted to 1700-1800. Evidence: the published total N is 2,228, exactly the sum of the eleven decade Ns 1700-1800, and equal to `text_n_inv_pre1801`. Result: n 2,228, sum 3,676,654 (published 3,676,655), mean 1,650.2 (published 1,650). These rows are not in `results_original.csv`.
