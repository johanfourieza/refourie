# S5 (P07_FG): which formulas use the Khoesan count (Population!Z / AC) -> numerator or only denominator?
suppressPackageStartupMessages({library(tidyxl); library(dplyr); library(stringr)})
f <- "./P07_FG/original/14 FG Missing People/KhoesanGDPnew.xlsx"
x <- xlsx_cells(f) |> filter(!is.na(formula))
pz <- x |> filter(sheet == "Population", col %in% c(26, 27, 28, 29)) |> select(address, formula) |> slice(c(1:3, 60:62))
print(as.data.frame(pz), right = FALSE)
hit <- x |> filter(str_detect(formula, "Population![$]?(Z|AA|AB|AC|AR)[$]?[0-9]")) |> group_by(sheet, col) |> slice(1) |> select(sheet, address, formula)
print(as.data.frame(hit), right = FALSE)
te <- x |> filter(sheet == "total economy", row == 60) |> select(address, formula)
print(as.data.frame(te), right = FALSE)
h <- xlsx_cells(f, sheets = "total economy") |> filter(row <= 3, !is_blank) |> select(address, character)
print(as.data.frame(h), right = FALSE)
