# P30_STB24 S2 patches

Source, copied verbatim to `repro_original/StellenboschScript.R`: `original/2024F_Stellenbosch/StellenboschScript.R` (1,019 lines, saved 2025-05-20). The copy has LF line endings instead of CRLF; no other change except the three environment lines below (`diff --strip-trailing-cr` shows only these).
Wrapper: `run_original.R` (new file, not original code) sets `OUTDIR`/`DATAFILE`, evaluates the patched script in a child environment (so line 42 `rm(list = ls())` does not delete the two path variables), and then exports the data objects behind Figs 2–7 to `output/*.csv`. It does not alter any object the script creates. Log: `run_original.log` (failed E4 attempt: `run_E4fix_failed.log`); results built by `extract_results.R`; warnings tallied in `output/warnings_summary.txt`.

Software: R 4.5.2 (paper: R 4.3.2). Package versions are in `output/sessionInfo.txt`.

## Packages
Installed into a local library, `D:/Data/ReplicateMe/P30_STB24/repro_original/_scratch/Rlib` (system library untouched):
```
circlize      0.4.18  CRAN          (used: Fig 4 chord diagram)
pacman        0.5.1   CRAN          (loaded, unused)
tidygeocoder  1.0.6   CRAN          (loaded, unused)
ggstream      0.1.0   CRAN Archive  (loaded, unused; archived from CRAN, installed from source tarball)
```
`dummies` (archived) is not installed. The script loads it with `require()`, which only warns; no function from it is called.

## Environment patches (applied)
```diff
@@ line 1 (E1)
 #usual suspects
+.libPaths(c("D:/Data/ReplicateMe/P30_STB24/repro_original/_scratch/Rlib", .libPaths()))
@@ line 44 (E2)
-setwd("C:\\Users\\johanf\\Dropbox\\3 Cape Panel\\Research\\2024F_Inequality")
+setwd(OUTDIR)   # figures written to repro_original/output
@@ line 46 (E3)
-opgaaf <- read_excel("stellenbosch_clean.xlsx", sheet = "Sheet1", col_names = TRUE)
+opgaaf <- read_excel(DATAFILE, sheet = "Sheet1", col_names = TRUE)
```
`DATAFILE` = `D:/Data/ReplicateMe/P30_STB24/original/2024F_Stellenbosch/stellenbosch_clean.xlsx` (md5-identical to the copy in `2024F_Inequality` that the script read; S1).

## E4 (line-52 typo fix): tried, rejected
The coordinator's brief listed `stellenbosch_clea.xlsx` → `stellenbosch_clean.xlsx` (line 52) as an env patch. With E4 the script **fails** at line 168 (`non-numeric argument to binary operator`; log `run_E4fix_failed.log`). Fixing the typo makes lines 56–63 succeed, so `opgaaf` becomes the all-text read (l.63), `opgaaf_new2 <- data.table(opgaaf)` (l.142) has a character `year`, and `floor(year/10)` (l.168) errors. The published figures therefore cannot come from a session in which line 52 worked. In the authors' session, lines 56–63 errored (file not found) and `opgaaf` kept the type-guessed read of line 46. E4 was reverted: line 52 stays verbatim.

## Execution mode: interactive-session emulation (run_original.R)
An R console continues after a top-level error; `Rscript`/`source()` stops. `run_original.R` therefore parses the script and evaluates each top-level expression in turn, logging and skipping errors (`output/errors_skipped.csv`). Exactly four expressions error, all from the typo: lines 57, 58, 61, 64 (line numbers of the patched copy = original + 1). Everything else runs. No analytic line is changed; this reproduces the state the authors' session must have had. **Verification:** the regenerated `chord_diagram_cleaned.png` is pixel-identical to the authors' file; `linegraph_plot.jpg` differs in 0.03% of pixels (JPEG noise); `assets_combined.jpg`, `gini.jpg` and `slaves_plot.jpg` have identical curves and differ only in legend order/spacing (ggplot2 4.0.2 vs the authors' version); `heatmap2.jpg` has identical tiles and variable order, with thicker white tile borders.

No analytic change. No A' alignment run was needed.
