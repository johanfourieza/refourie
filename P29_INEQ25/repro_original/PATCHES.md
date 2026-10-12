# P29_INEQ25 S2 patches

Source: `original/2024F_Inequality/InequalityScript_rev.R` (4,042 lines, mtime 2025-11-28). Patched copy: `repro_original/InequalityScript_rev.R` (LF line endings; original is CRLF). Diff below is `diff -u --strip-trailing-cr original patched`, collapsed to changed lines with original line numbers.

Run: R 4.5.2 (Rscript), env vars `P29_RUNDIR=D:/Data/ReplicateMe/P29_INEQ25/repro_original/_scratch/run` (holds byte-identical copies of the nine input workbooks; md5 checked for the April 2025 panel) and `P29_HOOKDIR=D:/.../_scratch/hooks`. Key package versions: ineq 0.2-13, ggplot2 4.0.2, dplyr (built 4.5.3), data.table 1.18.2.1, readxl 1.4.5, writexl 1.5.4. Log: `repro_original/run.log`, `run.log.err`.

## Environment patches (ENV)

| orig. line | change | why |
|---|---|---|
| 21, 22, 33, 34 | `library(tidygeocoder)`, `library(pacman)`, `library(ggstream)`, `library(circlize)` commented out | not installed; no function from these packages is called anywhere in the script (grep for geocode, p_load, geom_stream, chord/circos: none). Behaviour identical. |
| 39 | `require(dummies)` left unchanged | archived package not installed; `require()` only warns, and no `dummy*()` function is called. No install needed, behaviour identical. |
| 45 | `setwd("C:\\Users\\johanf\\Dropbox\\3 Cape Panel\\Research\\2024F_Inequality")` -> `setwd(Sys.getenv("P29_RUNDIR"))` | path |
| 512 | `setwd("C:\\Users\\johanf\\Dropbox\\15 Our Long Walk\\Graphs")` commented out | path; the original never resets the directory, so a top-to-bottom run would look for `1825 series.xlsx` in the OLW folder. The OLW graph is written into the run dir instead. |

## Run-flow patch (RUN)

| orig. lines | change | why |
|---|---|---|
| 2941-2966 | wrapped in `try({ ... })` | block computes the share of probate decedents owning slaves (`settlers_ratio`); it errors because `MOOC_probates.xlsx` has no `Owner_name`/`Owner_surname` columns (it has `name1t`). It feeds no figure and no claim. Without the wrap the run halts before Fig 5. |

## Extraction hooks (HOOK; non-analytic)

After line 45 a helper `.S2(name, obj)` (saveRDS to `P29_HOOKDIR`) is defined; one `.S2()` call is inserted after each of lines 65, 256, 295, 302, 394, 694, 710, 853, 970, 1016, 1034, 1131, 1232, 2130, 2150, 2237, 2474, 2749, 2810, 2853, 2892, 2971, 3056, 3085, 3145. They save already-computed objects only (counts, Gini tables, and at line 694 the pre-slave Fig 1 state). `extract_results.R` reads them and writes `results_original.csv`.

## Changed lines

```diff
-library(tidygeocoder)
-library(pacman)
+#library(tidygeocoder)  # [S2-ENV] package not installed and never called
+#library(pacman)  # [S2-ENV] package not installed and never called
-library(ggstream)
-library(circlize)
+#library(ggstream)  # [S2-ENV] package not installed and never called
+#library(circlize)  # [S2-ENV] package not installed and never called
-setwd("C:\\Users\\johanf\\Dropbox\\3 Cape Panel\\Research\\2024F_Inequality")
+#setwd("C:\\Users\\johanf\\Dropbox\\3 Cape Panel\\Research\\2024F_Inequality")  # [S2-ENV]
+setwd(Sys.getenv("P29_RUNDIR"))  # [S2-ENV] run directory on D:
+.S2DIR <- Sys.getenv("P29_HOOKDIR"); .S2 <- function(name, obj) saveRDS(obj, file.path(.S2DIR, paste0(name, ".rds")))  # [S2-HOOK extraction only]
-setwd("C:\\Users\\johanf\\Dropbox\\15 Our Long Walk\\Graphs")
+#setwd("C:\\Users\\johanf\\Dropbox\\15 Our Long Walk\\Graphs")  # [S2-ENV] Our Long Walk folder; graph saved in run directory instead
+try({  # [S2-RUN] wrap failing non-figure block (slave-owner share in probates)
+})  # [S2-RUN] end try(): block fails because MOOC_probates.xlsx has no Owner_name/Owner_surname columns; it feeds no figure
+.S2("...", ...)  # [S2-HOOK extraction only]   (x25, see list above)
```

## Not patched

- The ADDENDUM ("Previous version", from line 3175) halts with `Sheet 'sheet1' not found` in `stellenbosch_clean_july2024.xlsx`. It is the pre-R&R version of the opgaaf section, produces no published figure, and was left unpatched; all 25 hooks had already run.
- Line 2818 draws Fig 6 bubble sizes with `runif()` and no seed; left as is (sizes do not affect any Gini value).
