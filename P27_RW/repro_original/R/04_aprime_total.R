# A' alignment run (labelled): Table 5 "Total" restricted to pre-1801 decades (1700-1800), as in text_n_inv_pre1801 = 2228.
# Evidence: published total n = 2,228 = sum of the eleven decade Ns 1700-1800 (excludes the 1806 decade).
suppressMessages({library(readr);library(dplyr)})
r <- read_csv("P27_RW/repro_original/results_original.csv", show_col_types=FALSE, col_types=cols(.default="c"))
dec <- seq(1700, 1800, 10); g <- function(d, q) as.numeric(r$value[r$claim_id == paste0("T5_", d, "_", q)])
n <- sum(sapply(dec, g, q="n")); s <- sum(sapply(dec, g, q="sum"))
cat("A' total n", n, "sum", s, "mean", s/n, "\n")
