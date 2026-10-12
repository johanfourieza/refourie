# S2 Excel recalculation for Tables 3-5 census columns (PROTOCOL S2, Excel-only analyses).
# Extracts the formula chain with tidyxl, re-evaluates every formula from the input
# (non-formula) cells, and compares with (a) the cached workbook value. Output:
# repro_original/output/census_recalc.csv. Run from repro_original/.
suppressPackageStartupMessages({ library(tidyxl); library(dplyr); library(readr) })

source(file.path(normalizePath("../.."), "tools", "paths.R"))  # [A6] data root on D:
wb_dir <- dpath("P04_CF", "original", "CF Mobility", "Results latest")

col2num <- function(l) { n <- 0; for (ch in strsplit(l, "")[[1]]) n <- n * 26 + (utf8ToInt(ch) - 64); n }
num2col <- function(n) { s <- ""; while (n > 0) { m <- (n - 1) %% 26; s <- paste0(intToUtf8(65 + m), s); n <- (n - 1) %/% 26 }; s }
split_addr <- function(a) { a <- gsub("\\$", "", a); list(col = col2num(sub("[0-9]+$", "", a)), row = as.integer(sub("^[A-Z]+", "", a))) }

make_evaluator <- function(path) {
  cells <- xlsx_cells(path)
  key <- paste(cells$sheet, cells$row, cells$col)
  memo <- new.env()
  V <- function(sheet, addr) {
    p <- split_addr(addr); k <- paste(sheet, p$row, p$col)
    if (!is.null(memo[[k]])) return(memo[[k]])
    i <- match(k, key)
    val <- if (is.na(i)) 0 else if (!is.na(cells$formula[i])) evalf(sheet, cells$formula[i]) else {
      v <- cells$numeric[i]; if (is.na(v)) 0 else v }
    memo[[k]] <- val; val
  }
  S <- function(sheet, a1, a2) {
    p1 <- split_addr(toupper(a1)); p2 <- split_addr(toupper(a2)); tot <- 0
    for (r in p1$row:p2$row) for (cc in p1$col:p2$col) tot <- tot + V(sheet, paste0(num2col(cc), r))
    tot
  }
  evalf <- function(sheet, f) {
    ref <- "(?:'([^']+)'!|([A-Za-z0-9]+)!)?\\$?([A-Z]{1,2})\\$?([0-9]+)"
    # SUM(range)
    f <- gsub(paste0("SUM\\((?:'([^']+)'!)?\\$?([A-Z]{1,2})\\$?([0-9]+):\\$?([A-Z]{1,2})\\$?([0-9]+)\\)"),
              "S('\\1','\\L\\2\\3','\\L\\4\\5')", f, perl = TRUE)
    f <- gsub(ref, "V('\\1\\2','\\3\\4')", f, perl = TRUE)
    f <- gsub("([SV])\\('',", paste0("\\1('", gsub("'", "\\\\'", sheet), "',"), f)
    eval(parse(text = f))
  }
  list(V = V, cells = cells)
}

get_cached <- function(cells, sheet, addr) { p <- split_addr(addr); cells$numeric[cells$sheet == sheet & cells$row == p$row & cells$col == p$col] }

cc <- make_evaluator(file.path(wb_dir, "Census_Comparisons.xlsx"))
oc <- make_evaluator(file.path(wb_dir, "Census_1911_occupations.xlsx"))

map <- tribble(
  ~claim_id,  ~wb, ~sheet, ~addr, ~note,
  "T3_r1_c3", "cc", "Summaries", "D11", "1865: Summaries!B3/B7*100 <- '1865 v. 1875'!K cells",
  "T3_r2_c3", "cc", "Summaries", "D12", "",
  "T3_r3_c3", "cc", "Summaries", "D13", "",
  "T3_r4_c3", "cc", "Summaries", "D14", "",
  "T3_r5_c3", "cc", "Summaries", "D15", "",
  "T3_r1_c5", "cc", "Summaries", "F11", "1875: Summaries!C3/C7*100 <- '1865 v. 1875'!M cells",
  "T3_r2_c5", "cc", "Summaries", "F12", "",
  "T3_r3_c5", "cc", "Summaries", "F13", "",
  "T3_r4_c5", "cc", "Summaries", "F14", "",
  "T3_r5_c5", "cc", "Summaries", "F15", "",
  "T3_r1_c6", "cc", "1891", "AC7", "1891: '1891'!AB/AB11*100 <- census cells (Summaries G col is pasted values)",
  "T3_r2_c6", "cc", "1891", "AC8", "",
  "T3_r3_c6", "cc", "1891", "AC9", "",
  "T3_r4_c6", "cc", "1891", "AC10", "",
  "T3_r5_c6", "cc", "1891", "AC11", "",
  "T4_r1_c2", "oc", "Occupations Sub-Orders", "R4", "1911: Census_1911_occupations R=Q/Q8*100 <- census cells",
  "T4_r2_c2", "oc", "Occupations Sub-Orders", "R5", "",
  "T4_r3_c2", "oc", "Occupations Sub-Orders", "R6", "",
  "T4_r4_c2", "oc", "Occupations Sub-Orders", "R7", "",
  "T4_r5_c2", "oc", "Occupations Sub-Orders", "R8", "",
  "T5_r1_c1", "oc", "Occupations Sub-Orders", "Q4", "European N",
  "T5_r2_c1", "oc", "Occupations Sub-Orders", "Q5", "",
  "T5_r3_c1", "oc", "Occupations Sub-Orders", "Q6", "",
  "T5_r4_c1", "oc", "Occupations Sub-Orders", "Q7", "",
  "T5_r5_c1", "oc", "Occupations Sub-Orders", "Q8", "",
  "T5_r1_c3", "oc", "Occupations Sub-Orders", "Q13", "Non-European N",
  "T5_r2_c3", "oc", "Occupations Sub-Orders", "Q14", "",
  "T5_r3_c3", "oc", "Occupations Sub-Orders", "Q15", "",
  "T5_r4_c3", "oc", "Occupations Sub-Orders", "Q16", "",
  "T5_r5_c3", "oc", "Occupations Sub-Orders", "Q17", ""
)

res <- map |> rowwise() |> mutate(
  value  = (if (wb == "cc") cc else oc)$V(sheet, addr),
  cached = get_cached((if (wb == "cc") cc else oc)$cells, sheet, addr)
) |> ungroup()

# Table 5 totals and row percentages: the workbook holds them only as pasted values
# (R+R Tables.xlsx 'Table 1+2+3' I20:K29), so they are computed from the recalculated Ns.
eu  <- setNames(res$value[grepl("_c1$", res$claim_id) & grepl("^T5", res$claim_id)], paste0("r", 1:5))
neu <- setNames(res$value[grepl("_c3$", res$claim_id) & grepl("^T5", res$claim_id)], paste0("r", 1:5))
extra <- bind_rows(lapply(1:5, function(r) tibble(
  claim_id = paste0("T5_r", r, c("_c2", "_c4", "_c5", "_c6")),
  wb = "derived", sheet = NA, addr = NA,
  note = "no formula in workbook (pasted value); computed from recalculated Ns",
  value = c(100 * eu[r] / (eu[r] + neu[r]), 100 * neu[r] / (eu[r] + neu[r]), eu[r] + neu[r], 100),
  cached = NA_real_)))
res <- bind_rows(res, extra)
res$cached_match <- ifelse(is.na(res$cached), NA, abs(res$value - res$cached) < 1e-6)

dir.create("output", showWarnings = FALSE)
write_csv(res, "output/census_recalc.csv")
print(as.data.frame(res[, c("claim_id", "value", "cached", "cached_match")]))
