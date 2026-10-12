# P06_FGa – S2 environment patches

Entry point: `original/Settlers 2021/FG Replication Code.txt` (data copy at `D:/Data/ReplicateMe/P06_FGa/original/Settlers 2021/`; the `.txt` was routed to D: by `copy_source.py`). Verbatim copy: `FG_Replication_Code.orig.R`; patched copy: `FG_Replication_Code.R`. Runner: `run_original.R`. No analytic line was changed.

| id | line(s) | patch | reason |
|---|---|---|---|
| P1 | 25 | none (`require(dummies)` left as is) | `dummies` is archived on CRAN and not installed; `require()` only warns, and no function from it is used. Not installed. |
| P2 | 26 | `pacman::p_load(labeling)` -> `library(labeling)` | `pacman` not installed; identical effect. |
| P3 | 34, 67, 158, 161 | `"FG Maddison"`, `"FG Opgaaf"`, `"FG Prices"` (no extension, relative) and the hard-coded `C:\Users\johanf\Dropbox\1 Research\2 CAPE PANEL\...\Prices.xlsx` -> `file.path(Sys.getenv("P06_ORIG"), "20 FG Comparisons", ...)` pointing at `Data/Analysis.xlsx`, `Data/FourieGarmenApril2020.xlsx`, `Prices.xlsx` | Paths. S1 established SHA-256 identity: `FG Maddison.xlsx` = `Data/Analysis.xlsx`, `FG Opgaaf.xlsx` = `Data/FourieGarmenApril2020.xlsx`, `FG Prices.xlsx` = `Prices.xlsx`. `P06_ORIG` is set by the runner to `dpath("P06_FGa","original")` (an env var, because the script calls `remove(list=ls())`). |
| P4 | 167–170 | `rstudioapi::getActiveDocumentContext()` path discovery -> `dir <- <data copy of "20 FG Comparisons">/`; `setwd()` -> scratch | rstudioapi unavailable under Rscript; all `ggsave()` TIFFs go to `D:/Data/ReplicateMe/P06_FGa/repro_original/_scratch/`. |
| P5 | 175 | `paste0(dir,"Data/Prices.xlsx")` -> `paste0(dir,"Prices.xlsx")` | `Data/Prices.xlsx` does not exist in the archived `20 FG Comparisons`. The only `Data/Prices.xlsx` found in S1 is the older `Tim Johan` copy (24 Aug 2021, differs, not copied). Used the 26 Aug 2021 file that was submitted as `FG Prices.xlsx`. Every price-dependent claim (incomes, crop values, Fig. 7 values) then matches the paper, which supports this choice. |
| P6 | runner | Each top-level expression is evaluated in turn with `tryCatch`; errors are logged and execution continues | Emulates line-by-line RStudio execution. Three expressions fail in the original code and produce no claimed output: l.101 (`cor()` on non-numeric columns), l.217 (typo `Districy`), l.219 (`Crops` absent from `fg_V`). |

Run status: **ran-with-env-patches** (R 4.5.2; package versions in `sessionInfo.txt`; log `run_log.txt`; 118 expressions, 3 in-script errors, all in dead code).

Claim extraction (`extract_results.R`) reads the code's own objects. Two mechanical aggregations of code output were needed where the code has no pooled object: Table A1 horses/cattle/sheep/crop-bushels = obs-weighted pooling of `descriptives` (District x Year, same farmer filter); farmer shares (text p.14) = `gini1$obs` / sum of `sample$Obs`. Figure medians come from `ggplot2::layer_data()` of the code's plot objects `fig5`, `a`, `b`.

## Unified diff

```diff
--- FG_Replication_Code.orig.R	2026-10-11 10:46:22.878727300 +0200
+++ FG_Replication_Code.R	2026-10-11 10:46:59.452968400 +0200
@@ -23,7 +23,7 @@
 require(RColorBrewer)
 require(readxl)
 require(dummies)
-pacman::p_load(labeling)
+library(labeling)  # PATCH P2: pacman not installed; p_load(labeling) == library(labeling)
 #require(gridExtra)
 
 
@@ -31,7 +31,7 @@
 
 remove(list=ls())
 
-comparisons = read_excel("FG Maddison", "Comparisons", col_names = TRUE)
+comparisons = read_excel(file.path(Sys.getenv("P06_ORIG"), "20 FG Comparisons", "Data/Analysis.xlsx"), "Comparisons", col_names = TRUE)
 com = data.table(comparisons)
 
 
@@ -64,7 +64,7 @@
 
 remove(list=ls())
 
-fouriegarmen = read_excel("FG Opgaaf", "Combined", col_names = TRUE)
+fouriegarmen = read_excel(file.path(Sys.getenv("P06_ORIG"), "20 FG Comparisons", "Data/FourieGarmenApril2020.xlsx"), "Combined", col_names = TRUE)
 fg = data.table(fouriegarmen)
 
 trim = function (trim) gsub("^\\s+|\\s+$", "", trim)
@@ -155,24 +155,24 @@
 
 ########################################PRICES!
 
-fgprices = read_excel("FG Prices", "Final", col_names = TRUE)
+fgprices = read_excel(file.path(Sys.getenv("P06_ORIG"), "20 FG Comparisons", "Prices.xlsx"), "Final", col_names = TRUE)
 fgprices = data.table(fgprices)
 
-fgprices2 = read_excel("C:\\Users\\johanf\\Dropbox\\1 Research\\2 CAPE PANEL\\20 FG Comparisons\\Prices.xlsx", "Final2", col_names = TRUE)
+fgprices2 = read_excel(file.path(Sys.getenv("P06_ORIG"), "20 FG Comparisons", "Prices.xlsx"), "Final2", col_names = TRUE)
 fgprices2 = data.table(fgprices2)
 
 
 #Reading files 
 ## working dorectory
-thisFile <- rstudioapi::getActiveDocumentContext()$path
-dirChar <- paste0(unlist(strsplit(thisFile, "/")),'/')
-dir <- paste0(dirChar[1:(length(dirChar)-2)], collapse= "")
-setwd(dir)
+# PATCH P4: rstudioapi path discovery replaced; dir = data copy of "20 FG Comparisons/", cwd = scratch
+dir <- paste0(file.path(Sys.getenv("P06_ORIG"), "20 FG Comparisons"), "/")
+setwd(Sys.getenv("P06_SCRATCH"))
 
 #Data 
 fg <- read_excel(paste0(dir,"Data/FourieGarmenApril2020.xlsx"),"Combined", col_names = TRUE)
 fg = data.table(fg)
-fgprices <- read_excel(paste0(dir,"Data/Prices.xlsx"),"Final", col_names = TRUE) 
+fgprices <- read_excel(paste0(dir,"Prices.xlsx"),  # PATCH P5: Data/Prices.xlsx not in archive; = FG Prices.xlsx
+                      "Final", col_names = TRUE) 
 
 
 fgp <- fg %>% left_join(fgprices, by= "Country") 
```
