# S4 pair A (published vs original code) for P04_CF. Run from the project root:
#   Rscript P04_CF/compare/run_compare_A.R
suppressPackageStartupMessages({library(readr); library(dplyr)})
source("tools/compare.R")
p <- "P04_CF"
claims <- read_csv(file.path(p, "claims", "claims.csv"), show_col_types = FALSE,
  col_types = cols(reported_value = "d", reported_se = "d", reported_ci_lo = "d", reported_ci_hi = "d",
                   precision = "d", headline = "i", .default = "c"))
res <- read_csv(file.path(p, "repro_original", "results_original.csv"), show_col_types = FALSE,
  col_types = cols(value = "d", se = "d", n = "d", .default = "c")) |>
  mutate(status_override = na_if(status_override, ""))
cmp <- compare_claims(claims, res) |> filter(pair == "A") |>
  left_join(select(res, claim_id, note), by = "claim_id")
write_csv(cmp, file.path(p, "compare", "comparison_A.csv"), na = "")
s <- summarise_comparison(cmp); write_csv(s, file.path(p, "compare", "comparison_A_summary.csv"))
print(as.data.frame(s))
tab <- cmp |> mutate(tbl = sub("_.*", "", claim_id)) |> count(tbl, status) |> tidyr::pivot_wider(names_from = status, values_from = n, values_fill = 0)
write_csv(tab, file.path(p, "compare", "comparison_A_by_table.csv")); print(as.data.frame(tab))
cat("\nHeadline:\n"); print(as.data.frame(cmp |> filter(headline == 1) |> select(claim_id, ref, rep, status)), digits = 5)
cat("\nNon-exact numeric:\n"); print(as.data.frame(cmp |> filter(status %in% c("close", "differs")) |> select(claim_id, ref, rep, status, delta)), digits = 5)
