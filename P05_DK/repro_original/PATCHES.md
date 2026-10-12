# PATCHES — P05_DK S2 (original-code reproduction)

All patches are environment-only. No analytic line was changed and no A' alignment run was needed: the regenerated
`reg_predicting_mortality.tex` (Table 1) and `reg_unemployment.tex` (Table 3) are identical to the authors' saved
outputs apart from the two-line stargazer header (version 5.2.2 → 5.2.3, timestamp). The four intermediate files in
`data/processed/` are also reproduced (`all.equal` TRUE against the authors' copies).

| id | where | what | why |
|---|---|---|---|
| P0 | all copied `.R` | line endings CRLF → LF | side-effect of the patch tools; no effect on R |
| P1 | every `source(".../theme_ddk.R")` | sources `env_patch/theme_ddk.R` (`theme_ddk <- theme_bw`) | author's personal theme file not recovered; no claim-bearing output calls it |
| P2 | every `setwd("C:\Users\ddeka\...")` | `setwd(Sys.getenv("P05_WORK"))` = `D:/Data/ReplicateMe/P05_DK/repro_original/work` (A6) | path; the work tree holds copies of `data/original` (minus microdata) and `data/temporary`, so the authors' `data/processed` and `outputs` are never overwritten |
| P3 | `library(tmap/rgdal/raster/rgeos/extrafont/texreg/rmapshaper)` | commented out | rgdal/rgeos retired from CRAN (2023); the others are not installed and the global rules forbid installing without asking. They serve maps and fonts only. `raster` would mask `dplyr::select`; no unqualified `select()` occurs in the pipeline scripts |
| P4 | `loadfonts(device = "win")` | commented out | extrafont not installed; fonts only |
| P5 | `run_all.R` | `sf::sf_use_s2(FALSE)` | the authors ran sf 0.9 (2020–Jan 2021), which used planar GEOS; sf ≥ 1.0 defaults to s2. `RSA_Pop_1904_70` and `1937` are long/lat layers |
| P6 | `run_all.R` | evaluates each top-level expression in one global session; logs errors with line and continues | the scripts were run interactively in one RStudio session (later scripts use `findat`/`plotdat` from earlier ones) and contain dead lines that error (`railways_1907_cleaning_ddk.R:92` uses non-existent `mapdata`; `census_1936_cleanedversion_ddk.R:117` uses non-existent `mag1929_shp`); all `tm_shape()` calls error because of P3. Errors: `logs/run_errors.csv` (7, all maps/dead lines) |
| P7 | `run_all.R` | global-env `[<-.tbl_df` shim that applies `[<-.data.frame` semantics | tibble 3.0.0 (20 Apr 2020) introduced a strict `[<-.tbl_df`; before it, tibbles fell through to `[<-.data.frame`. `census_1936_cleanedversion_ddk.R:41,50,59,67,88` assign a vector of length nrow×ncol to several columns (and at :41 a 39-long all-FALSE logical column index, a no-op under base rules). Without the shim line 88 fails and Table 3 is never estimated; with it Table 3 is reproduced exactly. Package code is unaffected (S3 lookup from a namespace skips the global env) |
| P8 | `run_all.R` | after each `stargazer(...)` expression the model objects are copied into a snapshot (`D:/…/_scratch/s2_snapshot.rds`) | harness only: `predicting_mortality_analysis_ddk.R:94` overwrites `model1`/`model2` with square-term variants after the table is written |

Excel inputs: `excel_recalc.R` recalculates the formula chain of the two 1936 census workbooks with tidyxl
(6,804 `SUM()`/`A+B+…` cells) and compares with the cached values that `read_excel()` passes to the script:
0 mismatches (`logs/excel_recalc.csv`). Phillips Table 13 and the 1936 Native ages workbook contain no formulas.

Stata: no claim depends on the ELIE do-files. No do-file producing Table 2 (`voter_roll_1920s.tex`) exists in
`P05_DK/original` or in the Dropbox source `Spanish_flu_group_folder/spanishflu_ELIE` (searched for `voter`,
`conception`, `birth`); Stata was therefore not run and no ado packages were installed.

Software: R 4.5.2; sf 1.0-24 (GEOS 3.13.1), stargazer 5.2.3, estimatr 1.0.6, tidyverse 2.0.0 (`logs/sessionInfo.txt`).

## Diffs

```diff
--- original/census_1904_1970_cleaning_ddk.R
+++ repro_original/census_1904_1970_cleaning_ddk.R
@@ -2,11 +2,11 @@
 library(readxl)
 library(ggrepel)
 library(sf)
-library(tmap)
-library(rgdal)
-library(raster)
-library(rgeos)
-library(extrafont)
+# [ENV P3] not installed / retired from CRAN: library(tmap)
+# [ENV P3] not installed / retired from CRAN: library(rgdal)
+# [ENV P3] not installed / retired from CRAN: library(raster)
+# [ENV P3] not installed / retired from CRAN: library(rgeos)
+# [ENV P3] not installed / retired from CRAN: library(extrafont)
 
 #Global Options
 options(scipen = 999) 
@@ -14,13 +14,13 @@
 options(warn=-1)
 
 #Fonts
-loadfonts(device = "win")
+# [ENV P4] extrafont not installed: loadfonts(device = "win")
 
 #ggplot theme
-source("C:\\Users\\ddeka\\Dropbox\\theme_ddk.R")
+source(file.path(Sys.getenv("P05_REPRO"), "env_patch", "theme_ddk.R")) # [ENV P1] was: source("C:\\Users\\ddeka\\Dropbox\\theme_ddk.R")
 
 #Set working directories
-setwd("C:\\Users\\ddeka\\Dropbox\\Shared_projects\\Spanish_flu_group_folder")
+setwd(Sys.getenv("P05_WORK")) # [ENV P2] was: setwd("C:\\Users\\ddeka\\Dropbox\\Shared_projects\\Spanish_flu_group_folder")
 
 mortality = read_excel("data\\original\\mortality\\Phillips Table 13_all.xlsx")
 colnames(mortality) = c("mag_dist_1918", "white_pop_1918", "black_pop_1911", "ind_col_pop_1911", "total_pop_1918", "total_deaths_sflu", "deaths_sflu_per_1000")
--- original/railways_1907_cleaning_ddk.R
+++ repro_original/railways_1907_cleaning_ddk.R
@@ -3,12 +3,12 @@
 library(readxl)
 library(ggrepel)
 library(sf, sp)
-library(tmap)
-library(rgdal)
-library(raster)
-library(rgeos)
-library(extrafont)
-library(rmapshaper)
+# [ENV P3] not installed / retired from CRAN: library(tmap)
+# [ENV P3] not installed / retired from CRAN: library(rgdal)
+# [ENV P3] not installed / retired from CRAN: library(raster)
+# [ENV P3] not installed / retired from CRAN: library(rgeos)
+# [ENV P3] not installed / retired from CRAN: library(extrafont)
+# [ENV P3] not installed / retired from CRAN: library(rmapshaper)
 
 #Global Options
 options(scipen = 999) 
@@ -16,13 +16,13 @@
 options(warn=-1)
 
 #Fonts
-loadfonts(device = "win")
+# [ENV P4] extrafont not installed: loadfonts(device = "win")
 
 #ggplot theme
-source("C:\\Users\\ddeka\\Dropbox\\theme_ddk.R")
+source(file.path(Sys.getenv("P05_REPRO"), "env_patch", "theme_ddk.R")) # [ENV P1] was: source("C:\\Users\\ddeka\\Dropbox\\theme_ddk.R")
 
 #Set working directories
-setwd("C:\\Users\\ddeka\\Dropbox\\Shared_projects\\Spanish_flu_group_folder")
+setwd(Sys.getenv("P05_WORK")) # [ENV P2] was: setwd("C:\\Users\\ddeka\\Dropbox\\Shared_projects\\Spanish_flu_group_folder")
 
 mapdat = plotdat
 railways_full = st_read("data\\original\\spatial\\railways_1907\\1907_TrainTracks.shp")
--- original/rainfall_1910_1950_cleaning_ddk.R
+++ repro_original/rainfall_1910_1950_cleaning_ddk.R
@@ -2,25 +2,25 @@
 library(readxl)
 library(ggrepel)
 library(sf)
-library(tmap)
-library(rgdal)
-library(raster)
-library(rgeos)
+# [ENV P3] not installed / retired from CRAN: library(tmap)
+# [ENV P3] not installed / retired from CRAN: library(rgdal)
+# [ENV P3] not installed / retired from CRAN: library(raster)
+# [ENV P3] not installed / retired from CRAN: library(rgeos)
 library(ggpubr)
-library(extrafont)
+# [ENV P3] not installed / retired from CRAN: library(extrafont)
 
 #Global Options
 options(scipen = 999) 
 options(pillar.sigfig = 5)
 
 #Fonts
-loadfonts(device = "win")
+# [ENV P4] extrafont not installed: loadfonts(device = "win")
 
 #ggplot theme
-source("C:\\Users\\ddeka\\Dropbox\\theme_ddk.R")
+source(file.path(Sys.getenv("P05_REPRO"), "env_patch", "theme_ddk.R")) # [ENV P1] was: source("C:\\Users\\ddeka\\Dropbox\\theme_ddk.R")
 
 #Set working direction
-setwd("C:\\Users\\ddeka\\Dropbox\\Shared_projects\\Spanish_flu_group_folder")
+setwd(Sys.getenv("P05_WORK")) # [ENV P2] was: setwd("C:\\Users\\ddeka\\Dropbox\\Shared_projects\\Spanish_flu_group_folder")
 
 #Call data
 rainfall = read_csv("data\\original\\rainfall\\rain_monthly_1910-1950.csv")
--- original/covariates_building_ddk.R
+++ repro_original/covariates_building_ddk.R
@@ -2,11 +2,11 @@
 library(readxl)
 library(ggrepel)
 library(sf)
-library(tmap)
-library(rgdal)
-library(raster)
-library(rgeos)
-library(extrafont)
+# [ENV P3] not installed / retired from CRAN: library(tmap)
+# [ENV P3] not installed / retired from CRAN: library(rgdal)
+# [ENV P3] not installed / retired from CRAN: library(raster)
+# [ENV P3] not installed / retired from CRAN: library(rgeos)
+# [ENV P3] not installed / retired from CRAN: library(extrafont)
 
 #Global Options
 options(scipen = 999) 
@@ -14,13 +14,13 @@
 options(warn=-1)
 
 #Fonts
-loadfonts(device = "win")
+# [ENV P4] extrafont not installed: loadfonts(device = "win")
 
 #ggplot theme
-source("C:\\Users\\ddeka\\Dropbox\\theme_ddk.R")
+source(file.path(Sys.getenv("P05_REPRO"), "env_patch", "theme_ddk.R")) # [ENV P1] was: source("C:\\Users\\ddeka\\Dropbox\\theme_ddk.R")
 
 #Set working directories
-setwd("C:\\Users\\ddeka\\Dropbox\\Shared_projects\\Spanish_flu_group_folder")
+setwd(Sys.getenv("P05_WORK")) # [ENV P2] was: setwd("C:\\Users\\ddeka\\Dropbox\\Shared_projects\\Spanish_flu_group_folder")
 
 censusdata = read.csv("data\\processed\\census\\census_covariates_1911.csv")
 raildata = read.csv("data\\processed\\spatial\\railway_covariates_1907.csv")
--- original/predicting_mortality_analysis_ddk.R
+++ repro_original/predicting_mortality_analysis_ddk.R
@@ -2,15 +2,15 @@
 library(readxl)
 library(ggrepel)
 library(sf)
-library(tmap)
-library(rgdal)
-library(raster)
-library(rgeos)
+# [ENV P3] not installed / retired from CRAN: library(tmap)
+# [ENV P3] not installed / retired from CRAN: library(rgdal)
+# [ENV P3] not installed / retired from CRAN: library(raster)
+# [ENV P3] not installed / retired from CRAN: library(rgeos)
 library(estimatr)
-library(extrafont)
+# [ENV P3] not installed / retired from CRAN: library(extrafont)
 library(stargazer)
 library(magrittr)
-library(texreg)
+# [ENV P3] not installed / retired from CRAN: library(texreg)
 library(ggfortify)
 
 #Global Options
@@ -19,13 +19,13 @@
 options(warn=-1)
 
 #Fonts
-loadfonts(device = "win")
+# [ENV P4] extrafont not installed: loadfonts(device = "win")
 
 #ggplot theme
-source("C:\\Users\\ddeka\\Dropbox\\theme_ddk.R")
+source(file.path(Sys.getenv("P05_REPRO"), "env_patch", "theme_ddk.R")) # [ENV P1] was: source("C:\\Users\\ddeka\\Dropbox\\theme_ddk.R")
 
 #Set working directories
-setwd("C:\\Users\\ddeka\\Dropbox\\Shared_projects\\Spanish_flu_group_folder")
+setwd(Sys.getenv("P05_WORK")) # [ENV P2] was: setwd("C:\\Users\\ddeka\\Dropbox\\Shared_projects\\Spanish_flu_group_folder")
 
 covariates = read.csv("data\\processed\\all_covariates.csv")
 
--- original/census_1936_cleanedversion_ddk.R
+++ repro_original/census_1936_cleanedversion_ddk.R
@@ -2,11 +2,11 @@
 library(readxl)
 library(ggrepel)
 library(sf)
-library(tmap)
-library(rgdal)
-library(raster)
-library(rgeos)
-library(extrafont)
+# [ENV P3] not installed / retired from CRAN: library(tmap)
+# [ENV P3] not installed / retired from CRAN: library(rgdal)
+# [ENV P3] not installed / retired from CRAN: library(raster)
+# [ENV P3] not installed / retired from CRAN: library(rgeos)
+# [ENV P3] not installed / retired from CRAN: library(extrafont)
 library(estimatr)
 
 #Global Options
@@ -15,13 +15,13 @@
 options(warn=-1)
 
 #Fonts
-loadfonts(device = "win")
+# [ENV P4] extrafont not installed: loadfonts(device = "win")
 
 #ggplot theme
-source("C:\\Users\\ddeka\\Dropbox\\theme_ddk.R")
+source(file.path(Sys.getenv("P05_REPRO"), "env_patch", "theme_ddk.R")) # [ENV P1] was: source("C:\\Users\\ddeka\\Dropbox\\theme_ddk.R")
 
 #Set working directories
-setwd("C:\\Users\\ddeka\\Dropbox\\Shared_projects\\Spanish_flu_group_folder")
+setwd(Sys.getenv("P05_WORK")) # [ENV P2] was: setwd("C:\\Users\\ddeka\\Dropbox\\Shared_projects\\Spanish_flu_group_folder")
 
 ##########EUROPEAN POPULATION DATA###########
 european_ages_1936 = read_excel("data\\original\\census\\census1936\\Table 7; Ages in years of Europeans, by gender, at MD level..xlsx", col_types = "text")
```
