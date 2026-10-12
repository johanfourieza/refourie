# S5: why pair B (R rebuild) differs on Table 4, and the 623 vs 624 region count.
# Writes counts only (no microdata rows). Restricted-licence inputs read locally.
suppressMessages({library(haven); library(dplyr)})
source("./tools/paths.R")
ld <- function(f) dpath("P23_MBF", "original", "ld", f)
out <- "./P23_MBF/compare/s5_checks/s5_pairB_t4_inputs.csv"
mic <- read_dta(ld("1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta"),
                col_select = c(id_birth, d_birth_all, d_age_prim_bef, d_primary))
res <- list()
res$micro_ids_all <- n_distinct(mic$id_birth)
res$micro_ids_na <- sum(is.na(mic$id_birth))
est <- mic %>% filter(!is.na(d_age_prim_bef), !is.na(d_birth_all), !is.na(d_primary))
res$t2_sample_N <- nrow(est)
res$t2_sample_ids <- n_distinct(est$id_birth)
res$t2_treated_ids <- n_distinct(est$id_birth[est$d_birth_all == 1])
ids_micro <- unique(mic$id_birth); rm(mic, est); gc()
for (d in c(1930, 1940, 1950, 1960, 1970)) {
  f <- ld(sprintf("1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_%d.dta", d))
  if (!file.exists(f)) next
  x <- read_dta(f)
  y <- if ("yrschool" %in% names(x)) x$yrschool else NA
  res[[paste0("coll_", d, "_rows")]] <- nrow(x)
  res[[paste0("coll_", d, "_ids")]] <- n_distinct(x$id_birth)
  res[[paste0("coll_", d, "_yrschool_nonmiss")]] <- sum(!is.na(y))
  res[[paste0("coll_", d, "_ids_not_in_micro")]] <- length(setdiff(unique(x$id_birth), ids_micro))
  if ("d_centraliz" %in% names(x)) res[[paste0("coll_", d, "_centraliz_miss")]] <- sum(is.na(x$d_centraliz) & !is.na(y))
}
r <- tibble(quantity = names(res), value = unlist(res))
write.csv(r, out, row.names = FALSE); print(r, n = 50)
