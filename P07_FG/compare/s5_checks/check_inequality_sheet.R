# S5 (P07_FG): dump Dataset.xlsx 'Inequality' and 'Khoe pop 1790' cells (values and formulas) for C4/C7.
suppressPackageStartupMessages({library(tidyxl); library(dplyr)})
f <- "./P07_FG/original/14 FG Missing People/Dataset.xlsx"
for (s in c("Inequality", "Khoe pop 1790")) {
  x <- xlsx_cells(f, sheets = s) |> filter(!is_blank) |> select(address, numeric, character, formula)
  cat("\n==", s, "\n"); print(as.data.frame(x), right = FALSE)
}
