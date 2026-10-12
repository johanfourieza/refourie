# P16_FvFC S2: no analysis code survives. Check whether Ginis.xls holds a series behind Figs 4-5c,
# recalculating its formula chain with tidyxl, and write results_original.csv.
# Input: Ginis.xls converted to xlsx (Excel COM SaveAs, format 51; see PATCHES.md), on D: scratch.
suppressPackageStartupMessages({library(tidyxl); library(dplyr); library(readr)})
setwd(here::here()); source("tools/paths.R")
f <- dpath("P16_FvFC", "repro_original", "_scratch", "Ginis_conv.xlsx")
cl <- read_csv("P16_FvFC/claims/claims.csv", show_col_types = FALSE)
x <- xlsx_cells(f, sheets = "Sheet1")
cell <- function(col, rows) { z <- x[x$col == col & x$row %in% rows, ]; z[order(z$row), ] }

# Formula chain: the only formulas are F3:F22 = G{r}*100; G3:G22 are typed constants (no upstream chain).
fm <- x[!is.na(x$formula), c("address", "formula")]
stopifnot(nrow(fm) == 20, all(grepl("^G[0-9]+[*]100$", fm$formula)), all(is.na(cell(7, 3:22)$formula)))
yr <- cell(5, 3:22)$numeric; G <- cell(7, 3:22)$numeric
stopifnot(max(abs(G * 100 - cell(6, 3:22)$numeric)) < 1e-9)   # recalculated == cached

# Cape series vs digitised figure series
rv <- function(p) cl$reported_value[match(paste0(p, yr), cl$claim_id)]
diag <- bind_rows(lapply(c("F5c_", "F4_excl_", "F4_incl_"), function(p) tibble(series = p, year = yr, xls = G, fig = rv(p))))
diag_s <- diag |> group_by(series) |> summarise(r = cor(xls, fig), mean_abs_diff = mean(abs(xls - fig)),
  max_abs_diff = max(abs(xls - fig)), n_within_0.01 = sum(abs(xls - fig) <= 0.01))
print(diag_s)

# External comparison Ginis (cols A-C, typed constants): authors' own source table for p.29
ext <- tibble(country = cell(1, 2:30)$character, year = cell(2, 2:30)$numeric, gini = cell(3, 2:30)$numeric)
pick <- function(cn, y) ext$gini[ext$country == cn & ext$year == y] / 100
note_ext <- "Ginis.xls Sheet1 cols A-C, typed constant (authors' transcription of Milanovic et al.); not a computation"
res <- tibble(claim_id = cl$claim_id, source = "original", value = NA_real_, se = NA_real_, n = NA_real_,
  status_override = "unavailable",
  note = "No original code survives (S1); Ginis.xls Cape series matches no figure series (see ginis_xls_vs_figures.csv)")
setv <- function(r, id, v, so = NA, nt = note_ext) { i <- r$claim_id == id; r$value[i] <- v; r$status_override[i] <- so; r$note[i] <- nt; r }
res <- setv(res, "text_p29_eng_1688", pick("England and Wales", 1688))
res <- setv(res, "text_p29_hol_1732", pick("Holland", 1732))
res <- setv(res, "text_p29_bihar_1807", pick("Bihar (India)", 1807))
res <- setv(res, "text_p29_nspain_1780", pick("Nueva Espana", 1790), "ambiguous",
  "Ginis.xls row is Nueva Espana 1790 (63.5), not 1780 as the paper states; year label differs")

write_csv(diag, "P16_FvFC/repro_original/ginis_xls_vs_figures.csv")
write_csv(res, "P16_FvFC/repro_original/results_original.csv", na = "")
