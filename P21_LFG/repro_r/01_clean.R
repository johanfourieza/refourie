# 01_clean.R -- P21_LFG S3 recreation. Loads processed.dta (conditional independence), builds translog inputs.
suppressMessages({library(haven); library(dplyr); library(here)})
source(here::here("tools", "paths.R"))
set.seed(21)
d <- read_dta(dpath("P21_LFG", "original", "Calumet Links", "processed.dta")) |> zap_labels()
# Inputs: khoe (K), slaves (S), settler family labour (F); output = livestock value x 6% (Tot_prodfl)
d <- d |> mutate(
  Q  = Tot_prodfl,
  lq = ifelse(!is.na(Q) & Q > 0, log(Q), NA_real_),
  lk = log1p(khoe), ls = log1p(slaves), lf = log1p(settlers))
dir.create(dscratch("P21_LFG", "repro_r"), showWarnings = FALSE, recursive = TRUE)
saveRDS(d, dscratch("P21_LFG", "repro_r", "clean.rds"))
cat("rows", nrow(d), "years", length(unique(d$year)), "\n")
