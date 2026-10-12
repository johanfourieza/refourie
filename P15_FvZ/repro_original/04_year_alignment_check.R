# P15_FvZ  S2 diagnostic (feeds the candidate S5 findings): year alignment of
# cross-sheet references in the primary workbook's formula chain.
#
# Most sheets are year-by-row tables with the year in column A. For every formula
# cell in the chain, compare the year in column A of its own row with the year in
# column A of each single-cell reference on another sheet. A mismatch means the
# formula reads another year's value (an off-by-one link), unless the reference is
# a deliberate fixed cell (absolute reference or a non-year row).
# Input : repro_original/recalc_cells_primary.rds, formula_inventory.csv (from 01)
# Output: repro_original/year_alignment_check.csv

suppressPackageStartupMessages({ library(dplyr); library(readr); library(purrr); library(tidyxl); library(stringr) })
args_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- if (length(args_file)) normalizePath(file.path(dirname(args_file), "..")) else here::here()
od <- file.path(root, "repro_original"); source(file.path(root, "..", "tools", "paths.R"));

cells <- readRDS(dpath("P15_FvZ", "repro_original", "recalc_cells_primary.rds"))
inv <- read_csv(file.path(od, "formula_inventory.csv"), show_col_types = FALSE) |> filter(workbook == "primary", is_formula)
refs <- attr(cells, "refs")

# year of each row: numeric value in column A between 1600 and 1900
yr <- cells |> filter(col == 1, !is.na(recalc), recalc >= 1600, recalc <= 1900, recalc == round(recalc)) |>
  select(sheet, row, year = recalc)
yr_of <- function(s, r) { y <- yr$year[yr$sheet == s & yr$row == r]; if (length(y)) y else NA_real_ }

chk <- inv |> mutate(key = paste0(sheet, "!", cell)) |> pmap_dfr(function(...) {
  x <- list(...)
  own <- yr_of(x$sheet, x$row)
  rs <- refs[[x$key]]
  absref <- str_extract_all(x$formula, "\\$?[A-Z]{1,2}\\$?[0-9]+")[[1]]
  map_dfr(rs, function(rf) {
    if (rf$sheet == x$sheet || rf$r1 != rf$r2) return(NULL)
    tibble(sheet = x$sheet, cell = x$cell, formula = x$formula, own_year = own,
           ref_sheet = rf$sheet, ref_row = rf$r1, ref_year = yr_of(rf$sheet, rf$r1))
  })
}) |>
  filter(!is.na(own_year), !is.na(ref_year)) |>
  mutate(lag = ref_year - own_year)

summ <- chk |> group_by(sheet, ref_sheet, lag) |>
  summarise(n = n(), first_cell = first(cell), example = first(formula), .groups = "drop") |>
  arrange(desc(lag != 0), sheet, ref_sheet)
write_csv(summ, file.path(od, "year_alignment_check.csv"))
print(as.data.frame(summ |> filter(lag != 0)))
cat("\nreference pairs checked:", nrow(chk), " misaligned:", sum(chk$lag != 0), "\n")
