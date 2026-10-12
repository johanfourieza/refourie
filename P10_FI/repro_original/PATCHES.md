# P10_FI S2 patches (environment only)

Source: `original/R_CapeTownAnglican/Scripts/CapeTownAnglicanScript.R` (4 Apr 2019, 8,451 lines, SHA-256 2e1a6681…).
Patched copy: `repro_original/CapeTownAnglicanScript.R`. Runner: `repro_original/run_original.R`. Extraction: `repro_original/extract_results.R`.
R 4.5.2 (Windows, UCRT, UTF-8); package versions in `logs/sessionInfo_main.txt`. The original was last run under R 3.3.3 (xtable stamp in `descriptives.tex`, 13 Jun 2018).

Reproduce from the project root:

```
Rscript P10_FI/repro_original/run_original.R          # main run, ~90 s
Rscript P10_FI/repro_original/run_original.R v2018    # diagnostic: March 2018 data vintage
Rscript P10_FI/repro_original/extract_results.R       # -> results_original.csv
Rscript P10_FI/repro_original/extract_results.R v2018 # -> results_original_v2018.csv
Rscript P10_FI/compare/run_compare_A.R
```

## Patches

`diff --strip-trailing-cr original/.../CapeTownAnglicanScript.R repro_original/CapeTownAnglicanScript.R` (line endings CRLF -> LF, otherwise unchanged):

```diff
20c20
< require(dummies)
---
> #require(dummies)  # [S2 PATCH 1] archived on CRAN, not installed; shim defined below remove()
23a24,27
> # [S2 PATCH 2] environment: data paths (A6) and dummies::dummy shim
> source(file.path(Sys.getenv("REFOURIE_ROOT"), "tools", "paths.R")); DATA_DIR <- dpath("P10_FI", "original", "R_CapeTownAnglican", "Data")
> dummy <- function(x, data = NULL, sep = "", drop = TRUE, fun = as.integer, verbose = FALSE) { lv <- sort(unique(x)); m <- sapply(lv, function(l) fun(x == l)); m <- matrix(m, nrow = length(x)); colnames(m) <- paste0("angreg", sep, lv); m }
> melt <- function(data, ...) if (data.table::is.data.table(data)) data.table::melt(data, ...) else reshape2::melt(data, ...)  # [S2 PATCH 4]
25c29
< anglican = read_excel(file.path("Data","CT 1 March 2019.xlsx"),"Cape Town", col_names = TRUE)
---
> anglican = read_excel(file.path(DATA_DIR,Sys.getenv("P10_CT_FILE", "CT 1 March 2019.xlsx")),"Cape Town", col_names = TRUE)  # [S2 PATCH 5]
28,31c32,35  (and 33, 7746-7747)
< ... file.path("Data", ...
---
> ... file.path(DATA_DIR, ...
8210a8215
> library(dplyr)  # [S2 PATCH 3]
```

| # | Patch | Reason | Analytic effect |
|---|---|---|---|
| 1 | `require(dummies)` commented out | `dummies` was archived on CRAN (2020) and is not installed; installing archived packages needs approval. | None |
| 2a | `file.path("Data", …)` -> `file.path(DATA_DIR, …)`; `DATA_DIR = dpath(...)` defined after the script's `remove(list=ls())` | Data live on D: (Amendment A6). | None |
| 2b | `dummy()` shim | Reproduces `dummies::dummy(x)` for a vector: one 0/1 column per sorted unique value, named `<first argument of outermost call>_<value>`. The package takes the prefix from `sys.call(1)`, i.e. `cbind(angreg, …)` -> `angreg_1911` etc., which is how the script refers to them. Used only by the exploratory year-dummy models (not by Tables 1-4 or Figure 3). | None on published outputs |
| 3 | `library(dplyr)` before "##Some descriptives" | The script uses `%>%`, `group_by`, `summarise` for Table 2 (`descriptives`) and Table 4 (`literacy`) but never attaches dplyr (`#require(tidyverse)` is commented out at line 5); the author's session must have had it attached. Placed late so that `plyr::count`/`rename` used earlier are not masked. | None |
| 4 | `melt()` dispatcher | Under data.table < 1.14 (2019), `reshape2::melt()` on a data.table dispatched to `melt.data.table` and returned a data.table. Under data.table 1.18.2.1 it returns a data.frame, and the next line `parish[, .(inequality = conc(...)), by = c('pid','year')]` fails ("unused argument (by = …)"), so the Segregation (Herfindahl) variable `inequality` was never created and every regression failed. The shim restores the 2019 dispatch. | Restores the original behaviour |
| 5 | Data file name overridable by env var `P10_CT_FILE` | Lets the same code run on the March 2018 vintage (`Anglican Cape Town.xlsx`) as a data-vintage diagnostic. Default = file named in the script. | None for the main run |

Runner (not a patch to the script): evaluates the script expression by expression in the global environment, as an interactive session would, logging each error/warning with its line (`logs/conditions_<tag>.csv`) and continuing. `setwd()` to `D:/Data/ReplicateMe/P10_FI/repro_original/_scratch/<tag>/` so `descriptives.tex`, `literacy.tex` and `Rplots.pdf` land in scratch. Snapshots of models 5–8 (`summary(model5)` line, before the age-gap section overwrites `model5`/`model6`) and of `descriptives`, `literacy`, `years` are saved to scratch as `.rds` (microdata; never in Dropbox).

## Remaining errors in the main run (all outside the published outputs)

| line (patched) | error | object / section | published output affected? |
|---|---|---|---|
| 7857 | `sex[year > 1920 …]` on a tibble | sex-ratio plot | no |
| 7904 | `summarySE` after `na.omit` | exploratory age plot | no |
| 8138 | `glm(interdum ~ . - mhiscodum)` contrasts error | first exploratory regression block | no |
| 8165 | `angreg_1964` not found (no 1964 records exist) | "New regressions" model2 (year dummies) | no; stargazer then prints the stale `model2` |
| 8238 | `count(interdum, na.rm=T)` | `descriptivesnum` (overwritten next line) | no |
| 8337–8391 | `rename` on missing column | "Graphs paired" occupation plots | no |
| 8457 | ggplot `ci` not found | last plot | no |

The readxl warnings at line 28 concern non-numeric `IndID` values (e.g. "474 a"), which become NA; `IndID` is not used in any analysis. `trim_ws = TRUE` (readxl default) means the recode `"Non-European (C) "` (trailing space) no longer matches (1 record; trailing-space keys appear elsewhere in the recode lists too).
