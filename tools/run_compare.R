# Usage: Rscript tools/run_compare.R P18_FvFS [original_results_file] [r_results_file]
# Runs all three pairs (A, B, C) and writes compare/comparison_ABC.csv and comparison_ABC_summary.csv.
suppressPackageStartupMessages({library(readr); library(dplyr)})
source("tools/compare.R")
a <- commandArgs(TRUE); p <- a[1]
sf <- file.path(p, "claims", "stars05.txt"); if (file.exists(sf)) STARS05 <- as.integer(readLines(sf, n = 1))
fo <- if (length(a) >= 2) a[2] else file.path(p, "repro_original", "results_original.csv")
fr <- if (length(a) >= 3) a[3] else file.path(p, "repro_r", "results_r.csv")
claims <- read_csv(file.path(p, "claims", "claims.csv"), show_col_types = FALSE,
  col_types = cols(reported_value = "d", reported_se = "d", reported_ci_lo = "d", reported_ci_hi = "d",
                   precision = "d", headline = "i", .default = "c"))
rd <- function(f) if (file.exists(f)) read_csv(f, show_col_types = FALSE,
  col_types = cols(value = "d", se = "d", n = "d", .default = "c")) else NULL
res <- bind_rows(rd(fo), rd(fr)) |> mutate(status_override = na_if(status_override, ""))
cmp <- compare_claims(claims, res)
write_csv(cmp, file.path(p, "compare", "comparison_ABC.csv"), na = "")
s <- summarise_comparison(cmp); write_csv(s, file.path(p, "compare", "comparison_ABC_summary.csv"))
cat("\n==", p, "\n"); print(as.data.frame(s))
cat("\nHeadline rows:\n")
print(as.data.frame(cmp |> filter(headline == 1) |> select(claim_id, pair, ref, rep, rep_se, status, inferential_agree)), digits = 4)
