# Writes the 20-year core 1 Gini series (published digitised and rebuilt) for the Stata pperron check.
suppressPackageStartupMessages({library(readr); library(dplyr)})
setwd(here::here())
cl <- read_csv("P16_FvFC/claims/claims.csv", show_col_types = FALSE)
f5 <- read_csv("P16_FvFC/repro_r/output/fig5c_core1_gini_ci.csv", show_col_types = FALSE)
d <- tibble(t = 1:20, year = f5$year, g_pub = cl$reported_value[match(paste0("F5c_", f5$year), cl$claim_id)], g_reb = f5$gini)
write_csv(d, "P16_FvFC/compare/s5_checks/pp_series.csv")
