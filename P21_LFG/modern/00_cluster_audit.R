# 00_cluster_audit.R -- P21_LFG S6, card §4: documents the fixed cluster definition (index; missing = singleton).
# Not a gate; run before any bootstrap.
source(here::here("P21_LFG", "modern", "00_common.R"))
E <- est_rows(prep_base(d0)); E$cl <- cluster_id(E)
cs <- E |> group_by(cl) |> summarise(rows = n(), years = n_distinct(year), .groups = "drop")
byy <- E |> group_by(year) |> summarise(rows = n(), idx_distinct = n_distinct(index[!is.na(index)]),
  clusters = n_distinct(cl), idx_missing_share = mean(is.na(index)),
  idx_rep_within = sum(table(index[!is.na(index)]) > 1), max_mult = max(c(0, table(index[!is.na(index)]))),
  mscore_present = sum(!is.na(mscore)), mscore_median = median(mscore, na.rm = TRUE), .groups = "drop")
ov <- tibble(year = "all", rows = nrow(E), idx_distinct = n_distinct(E$index[!is.na(E$index)]), clusters = nrow(cs),
  idx_missing_share = mean(is.na(E$index)), idx_rep_within = sum(byy$idx_rep_within), max_mult = max(byy$max_mult),
  mscore_present = sum(!is.na(E$mscore)), mscore_median = median(E$mscore, na.rm = TRUE),
  clsize_rows_mean = mean(cs$rows), clsize_rows_median = median(cs$rows), clsize_rows_max = max(cs$rows),
  clsize_years_mean = mean(cs$years), clsize_years_median = median(cs$years), clsize_years_max = max(cs$years),
  largest_cluster_share = max(cs$rows) / nrow(E), singletons = sum(cs$rows == 1),
  mscore_q10 = quantile(E$mscore, .1, na.rm = TRUE), mscore_q90 = quantile(E$mscore, .9, na.rm = TRUE))
A <- bind_rows(ov, mutate(byy, year = as.character(year)))
write_csv(A, file.path(MOD, "cluster_audit.csv"), na = "")
print(as.data.frame(ov))
