suppressPackageStartupMessages({library(dplyr); library(tidyr)})
r <- read.csv("P06_FGa/compare/s5_checks/scenario_results.csv")
o <- read.csv("P06_FGa/repro_original/results_original.csv")
b <- r |> filter(scenario=="base") |> left_join(o, by="claim_id", suffix=c("",".orig"))
cat("base vs results_original max abs diff:", max(abs(b$value-b$value.orig), na.rm=TRUE), "\n")
ids <- c(grep("^tx_p16|^tx_p17_income", unique(r$claim_id), value=TRUE), grep("^T1_.*_(crops|cropswine)$", unique(r$claim_id), value=TRUE),
  "tx_p14_stel_total","tx_p15_mass_total","tx_p15_maine_total","A1_Massachusetts_wheat","F6_crops_cape_median","F6_crops_us_median","F6_cropswine_cape_median","F6_cropswine_us_median")
w <- r |> filter(claim_id %in% ids) |> select(-n_errors) |> pivot_wider(names_from=scenario, values_from=value)
options(width=250); print(as.data.frame(w |> mutate(across(where(is.numeric), ~round(.x,3)))), row.names=FALSE)
