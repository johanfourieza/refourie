# P14_QC S3 rebuild, step 1: read the released workbook cell by cell (tidyxl).
# The workbook is the article's only surviving "code": hard-coded series plus Excel formulas.
# Sheets are read one at a time: reading the whole file at once crashes R (chart sheets with a
# broken relationship). Output: a tidy cell table on D: and a formula inventory in output/.
suppressMessages({ library(tidyxl); library(dplyr); library(readr); library(here) })

source(file.path("tools", "paths.R"))

wb <- dpath("P14_QC", "original", "Fourie Kronos", "Fourie Quantitative Cape.xlsx")
sheets <- xlsx_sheet_names(wb)

cells <- bind_rows(lapply(sheets, function(s) {
  d <- xlsx_cells(wb, sheets = s)
  d[!d$is_blank, c("sheet", "address", "row", "col", "data_type", "numeric", "character", "formula")]
}))

out_d <- dpath("P14_QC", "repro_r", "derived"); dir.create(out_d, recursive = TRUE, showWarnings = FALSE)
saveRDS(cells, file.path(out_d, "workbook_cells.rds"))

dir.create(file.path("P14_QC", "repro_r", "output"), showWarnings = FALSE)
cells |> filter(!is.na(formula)) |> select(sheet, address, numeric, formula) |>
  write_csv(file.path("P14_QC", "repro_r", "output", "formula_inventory.csv"))
cells |> count(sheet, has_formula = !is.na(formula)) |>
  write_csv(file.path("P14_QC", "repro_r", "output", "sheet_summary.csv"))
cat("Sheets:", paste(sheets, collapse = " | "), "\nCells:", nrow(cells), " formulas:", sum(!is.na(cells$formula)), "\n")
