# S4 pair A (published vs original code) for P10_FI. Run from the project root:
#   Rscript P10_FI/compare/run_compare_A.R
# Official pair A = main run (script as written: CT 1 March 2019.xlsx).
# Diagnostic = same code on the March 2018 data vintage (Anglican Cape Town.xlsx); reported separately.
suppressPackageStartupMessages({library(readr); library(dplyr); library(tidyr)})
source("tools/compare.R")
p <- "P10_FI"
claims <- read_csv(file.path(p, "claims", "claims.csv"), show_col_types = FALSE,
  col_types = cols(reported_value = "d", reported_se = "d", reported_ci_lo = "d", reported_ci_hi = "d",
                   precision = "d", headline = "i", .default = "c"))
run1 <- function(f, suffix) {
  res <- read_csv(file.path(p, "repro_original", f), show_col_types = FALSE,
    col_types = cols(value = "d", se = "d", n = "d", .default = "c")) |> mutate(status_override = na_if(status_override, ""))
  cmp <- compare_claims(claims, res) |> filter(pair == "A") |> left_join(select(res, claim_id, note), by = "claim_id")
  write_csv(cmp, file.path(p, "compare", paste0("comparison_A", suffix, ".csv")), na = "")
  s <- summarise_comparison(cmp); write_csv(s, file.path(p, "compare", paste0("comparison_A", suffix, "_summary.csv")))
  tab <- cmp |> mutate(tbl = sub("_.*", "", claim_id)) |> count(tbl, status) |> pivot_wider(names_from = status, values_from = n, values_fill = 0)
  write_csv(tab, file.path(p, "compare", paste0("comparison_A", suffix, "_by_table.csv")))
  cat("\n==== ", f, "\n"); print(as.data.frame(s)); print(as.data.frame(tab))
  cat("\nHeadline:\n"); print(as.data.frame(cmp |> filter(headline == 1) |> select(claim_id, ref, rep, rep_se, status, inferential_agree)), digits = 5)
  cat("\nT3 inferential agreement (coef rows):\n"); print(table(cmp$inferential_agree[cmp$quantity_type == "coef"], useNA = "ifany"))
  invisible(cmp)
}
a <- run1("results_original.csv", "")
d <- run1("results_original_v2018.csv", "_diag_v2018")
cat("\nNon-exact numeric, main run:\n")
print(as.data.frame(a |> filter(status %in% c("close", "differs")) |> select(claim_id, ref, rep, status, delta)), digits = 5)
cat("\nNon-exact numeric, v2018 diagnostic:\n")
print(as.data.frame(d |> filter(status %in% c("close", "differs")) |> select(claim_id, ref, rep, status, delta)), digits = 5)
