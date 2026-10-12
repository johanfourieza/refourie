# S5 (P07_FG): inspect KhoesanGDPnew.xlsx GDP model (headers + one row of formulas) for the GDP-per-capita claim.
suppressPackageStartupMessages({library(tidyxl); library(dplyr)})
f <- "./P07_FG/original/14 FG Missing People/KhoesanGDPnew.xlsx"
x <- xlsx_cells(f)
print(unique(x$sheet))
for (s in c("Population", "total economy")) {
  y <- x |> filter(sheet == s, !is_blank)
  cat("\n==", s, "headers rows 1-4\n"); print(as.data.frame(y |> filter(row <= 4) |> select(address, character, numeric, formula)), right = FALSE)
  cat("\n== row 60 (", s, ")\n"); print(as.data.frame(y |> filter(row == 60) |> select(address, numeric, formula)), right = FALSE)
}
