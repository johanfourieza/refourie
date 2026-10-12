# A' alignment comparison (separately labelled): results_original_A1.csv vs claims, pair A logic only.
# Writes repro_original/compare_A1_pairA.csv. Does not touch compare/ (pair A official = run 0).
suppressPackageStartupMessages({library(readr); library(dplyr)})
source("tools/compare.R")
p <- "P11_FJS"
sf <- file.path(p, "claims", "stars05.txt"); if (file.exists(sf)) STARS05 <- as.integer(readLines(sf, n = 1))
claims <- read_csv(file.path(p, "claims", "claims.csv"), show_col_types = FALSE,
  col_types = cols(reported_value = "d", reported_se = "d", reported_ci_lo = "d", reported_ci_hi = "d",
                   precision = "d", headline = "i", .default = "c"))
res <- read_csv(file.path(p, "repro_original", "results_original_A1.csv"), show_col_types = FALSE,
  col_types = cols(value = "d", se = "d", n = "d", .default = "c")) |>
  mutate(source = "original", status_override = na_if(status_override, ""))
cmp <- compare_claims(claims, res) |> filter(pair == "A")
write_csv(cmp, file.path(p, "repro_original", "compare_A1_pairA.csv"), na = "")
print(table(cmp$status))
print(as.data.frame(cmp |> filter(grepl("^I7|^I9|^txt_p1[89]|txt_p21|wine_pre", claim_id)) |> select(claim_id, ref, rep, status)), digits = 6)
