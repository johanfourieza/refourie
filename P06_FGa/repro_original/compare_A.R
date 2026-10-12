# Pair A (published vs original code) for P06_FGa. Run from the project root.
suppressPackageStartupMessages({library(readr); library(dplyr)})
source("tools/compare.R")
p <- "P06_FGa"
claims <- read_csv(file.path(p, "claims", "claims.csv"), show_col_types = FALSE,
  col_types = cols(reported_value = "d", reported_se = "d", reported_ci_lo = "d", reported_ci_hi = "d",
                   precision = "d", headline = "i", .default = "c"))
res <- read_csv(file.path(p, "repro_original", "results_original.csv"), show_col_types = FALSE,
  col_types = cols(value = "d", se = "d", n = "d", .default = "c")) |> mutate(status_override = na_if(status_override, ""))
cmp <- compare_claims(claims, res) |> filter(pair == "A")
write_csv(cmp, file.path(p, "compare", "comparison_A.csv"), na = "")
s <- summarise_comparison(cmp); write_csv(s, file.path(p, "compare", "comparison_A_summary.csv"))
print(as.data.frame(s))
options(width = 200)
cat("\nHeadline:\n"); print(as.data.frame(cmp |> filter(headline == 1) |> select(claim_id, ref, rep, status)), digits = 5)
cat("\nNon-exact numeric:\n"); print(as.data.frame(cmp |> filter(status %in% c("close", "differs")) |> select(claim_id, ref, rep, status, rel_delta)), digits = 4)
