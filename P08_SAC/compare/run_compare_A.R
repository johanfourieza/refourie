# S4 pair A (published vs original code) for P08_SAC. Run from the project root:
#   Rscript P08_SAC/compare/run_compare_A.R
suppressPackageStartupMessages({library(readr); library(dplyr)})
source("tools/compare.R")
p <- "P08_SAC"
claims <- read_csv(file.path(p, "claims", "claims.csv"), show_col_types = FALSE,
  col_types = cols(reported_value = "d", reported_se = "d", reported_ci_lo = "d", reported_ci_hi = "d",
                   precision = "d", headline = "i", .default = "c"))
res <- read_csv(file.path(p, "repro_original", "results_original.csv"), show_col_types = FALSE,
  col_types = cols(value = "d", se = "d", n = "d", .default = "c")) |>
  mutate(status_override = na_if(status_override, ""))
cmp <- compare_claims(claims, res) |> filter(pair == "A") |>
  left_join(select(res, claim_id, note, cause), by = "claim_id")
# Supplementary inferential check under the estout default star legend the table was built with
# (* p<0.05, ** p<0.01, *** p<0.001; Occupations.do uses estout's default `star`). tools/compare.R reads
# one star as "not significant at 5%" and compares sign(0) for coefficients printed as 0.000; both are
# artefacts for this table. Keeps the tool's own column untouched.
stars <- select(claims, claim_id, reported_stars)
cmp <- cmp |> left_join(stars, by = "claim_id") |> mutate(
  pub_sig05 = ifelse(is.na(reported_stars), FALSE, nchar(gsub("[^*]", "", reported_stars)) >= 1),
  rep_sig05 = abs(rep / rep_se) >= qt(0.975, 7000),
  inferential_agree_estout = ifelse(quantity_type == "coef" & !is.na(rep_se),
    (sign(rep) == sign(ref) | ref == 0) & pub_sig05 == rep_sig05, NA)) |>
  select(-reported_stars, -pub_sig05, -rep_sig05)
write_csv(cmp, file.path(p, "compare", "comparison_A.csv"), na = "")
s <- summarise_comparison(cmp); write_csv(s, file.path(p, "compare", "comparison_A_summary.csv"))
print(as.data.frame(s))
tab <- cmp |> mutate(tbl = sub("_.*", "", claim_id)) |> count(tbl, status) |> tidyr::pivot_wider(names_from = status, values_from = n, values_fill = 0)
write_csv(tab, file.path(p, "compare", "comparison_A_by_table.csv")); print(as.data.frame(tab))
cat("\nHeadline:\n"); print(as.data.frame(cmp |> filter(headline == 1) |> select(claim_id, ref, rep, status)), digits = 5)
cat("\nInferential agreement (coef rows):\n"); print(table(cmp$inferential_agree, useNA = "ifany"))
cat("Under estout star legend:\n"); print(table(cmp$inferential_agree_estout, useNA = "ifany"))
print(as.data.frame(cmp |> filter(inferential_agree_estout == FALSE) |> select(claim_id, ref, rep, rep_se)), digits = 4)
cat("\nNon-exact numeric:\n"); print(as.data.frame(cmp |> filter(status %in% c("close", "differs")) |> select(claim_id, ref, rep, status, delta, cause)), digits = 5)
