# S5 (P07_FG): does the GDP numerator (total economy!E = agric + VOC + rest) depend on the Khoesan count?
suppressPackageStartupMessages({library(tidyxl); library(dplyr)})
f <- "./P07_FG/original/14 FG Missing People/KhoesanGDPnew.xlsx"
for (s in c("resteconomy", "INCOMEVOCEMPLOYEES")) {
  y <- xlsx_cells(f, sheets = s) |> filter(!is_blank)
  cat("\n==", s, "headers\n"); print(as.data.frame(y |> filter(row <= 2, !is.na(character)) |> select(address, character)), right = FALSE)
  cat("== row 60\n"); print(as.data.frame(y |> filter(row == 60) |> select(address, numeric, formula)), right = FALSE)
}
y <- xlsx_cells(f, sheets = "Agricultural production") |> filter(!is_blank, row == 61, col >= 35) |> select(address, numeric, formula)
print(as.data.frame(y), right = FALSE)
