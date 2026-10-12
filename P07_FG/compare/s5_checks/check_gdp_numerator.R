# S5 (P07_FG): test the paper's statement that the revised Khoesan series was added "only to the denominator".
# Recalculate KhoesanGDPnew.xlsx (S2 evaluator, unchanged logic) with Population!Z (Khoesan) as is, and with Z = 0,
# then compare model GDP per capita ('total economy'!X) with a pure denominator rescaling of the Z = 0 run.
suppressWarnings(suppressPackageStartupMessages({library(dplyr); library(tidyxl)}))
txt <- readLines("P07_FG/repro_original/excel_recalc.R")
txt <- sub("recalc_workbook <- function(path) {", "recalc_workbook <- function(path, override = NULL) {", txt, fixed = TRUE)
i <- grep("fc <- cells |> filter(!is.na(formula))", txt, fixed = TRUE)[1]
txt <- append(txt, "  if (!is.null(override)) for (k in names(override)) assign(k, override[[k]], envir = val)", after = i - 1)
eval(parse(text = txt))
f <- "./P07_FG/original/14 FG Missing People/KhoesanGDPnew.xlsx"
z <- xlsx_cells(f, sheets = "Population") |> filter(col == 26, is.na(formula), !is.na(numeric), row >= 50)
cat("Population!Z input cells:", nrow(z), "rows", min(z$row), "-", max(z$row), "\n")
ov0 <- setNames(as.list(rep(0, nrow(z))), paste("Population", z$row, 26, sep = "|"))
r1 <- recalc_workbook(f); r0 <- recalc_workbook(f, ov0)
get <- function(r, s, cc) r |> filter(sheet == s, col == cc) |> select(row, v = recalc)
yr <- xlsx_cells(f, sheets = "total economy") |> filter(col == 1, !is.na(numeric)) |> select(row, year = numeric)
X1 <- get(r1, "total economy", 24); X0 <- get(r0, "total economy", 24)
E1 <- get(r1, "total economy", 5);  E0 <- get(r0, "total economy", 5)
G1 <- get(r1, "total economy", 7);  G0 <- get(r0, "total economy", 7)
d <- yr |> inner_join(X1, by = "row") |> rename(X_new = v) |> inner_join(X0, by = "row") |> rename(X_noKh = v) |>
  inner_join(E1, by = "row") |> rename(E_new = v) |> inner_join(E0, by = "row") |> rename(E_noKh = v) |>
  inner_join(G1, by = "row") |> rename(pop_new = v) |> inner_join(G0, by = "row") |> rename(pop_noKh = v) |>
  mutate(X_denominator_only = X_noKh * pop_noKh / pop_new, numerator_change_pct = 100 * (E_new / E_noKh - 1),
         gap_pct = 100 * (X_new / X_denominator_only - 1))
print(as.data.frame(d |> filter(year %in% c(1701, 1710, 1720, 1730, 1740, 1750, 1760, 1773, 1780, 1790)) |> mutate(across(-year, ~ round(.x, 2)))))
write.csv(d, "P07_FG/compare/s5_checks/gdp_numerator_check.csv", row.names = FALSE)
