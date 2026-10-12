# P07_FG S2: generic recalculation of an Excel workbook's formula chain in R (PROTOCOL S2, Excel-only analyses).
# Inputs are the workbook's non-formula cells; every formula cell is recomputed from them.
# Supported: + - * / ^, unary minus, parentheses, cell refs (with $ and 'Sheet'!), ranges, SUM, AVERAGE, ROW.
# These cover every function used in Dataset.xlsx and KhoesanGDPnew.xlsx (checked with tidyxl).
# Usage: source("excel_recalc.R"); r <- recalc_workbook(path)  -> tibble of formula cells with cached and recalculated values.
suppressWarnings(suppressPackageStartupMessages({library(tidyxl); library(dplyr); library(stringr)}))

ref_re <- "(?:('[^']+'|[A-Za-z_][A-Za-z0-9_\\.]*)!)?\\$?([A-Z]{1,3})\\$?([0-9]+)(?::\\$?([A-Z]{1,3})\\$?([0-9]+))?"

col2num <- function(x) vapply(strsplit(x, ""), function(ch) sum((match(ch, LETTERS)) * 26^(rev(seq_along(ch)) - 1)), 0)

recalc_workbook <- function(path) {
  cells <- xlsx_cells(path) |> filter(!is_blank | !is.na(formula))
  key <- function(s, r, c) paste(s, r, c, sep = "|")
  cells$k <- key(cells$sheet, cells$row, cells$col)
  val <- new.env(hash = TRUE, size = nrow(cells) * 2L)
  inp <- cells |> filter(is.na(formula))
  for (i in seq_len(nrow(inp))) {
    v <- if (!is.na(inp$numeric[i])) inp$numeric[i] else if (!is.na(inp$logical[i])) as.numeric(inp$logical[i]) else NA_real_
    assign(inp$k[i], v, envir = val)              # text -> NA (ignored by SUM, as in Excel)
  }
  fc <- cells |> filter(!is.na(formula))
  # translate each formula into an R expression and list its dependencies
  tr <- lapply(seq_len(nrow(fc)), function(i) {
    f <- fc$formula[i]; sh <- fc$sheet[i]; deps <- character(0)
    # ROW(ref) -> row number
    f <- str_replace_all(f, regex(paste0("ROW\\((", ref_re, ")\\)")), function(m) {
      mm <- str_match(m, regex(paste0("ROW\\(", ref_re, "\\)"))); mm[, 4] })
    locs <- str_locate_all(f, regex(ref_re))[[1]]
    if (nrow(locs) == 0) return(list(expr = parse(text = f)[[1]], deps = deps))
    out <- ""; last <- 1
    for (j in seq_len(nrow(locs))) {
      m <- substr(f, locs[j, 1], locs[j, 2]); mm <- str_match(m, regex(ref_re))
      s <- if (is.na(mm[1, 2])) sh else gsub("^'|'$", "", mm[1, 2])
      c1 <- col2num(mm[1, 3]); r1 <- as.integer(mm[1, 4])
      if (!is.na(mm[1, 5])) {
        c2 <- col2num(mm[1, 5]); r2 <- as.integer(mm[1, 6])
        g <- expand.grid(r = r1:r2, c = c1:c2); ks <- key(s, g$r, g$c)
        rep_txt <- paste0("RNG(c(", paste0('"', ks, '"', collapse = ","), "))")
      } else { ks <- key(s, r1, c1); rep_txt <- paste0('REF("', ks, '")') }
      deps <- c(deps, ks)
      out <- paste0(out, substr(f, last, locs[j, 1] - 1), rep_txt); last <- locs[j, 2] + 1
    }
    out <- paste0(out, substr(f, last, nchar(f)))
    out <- gsub("SUM\\(", "XSUM(", out); out <- gsub("AVERAGE\\(", "XAVG(", out)
    list(expr = parse(text = out)[[1]], deps = unique(deps))
  })
  REF <- function(k) { v <- get0(k, envir = val, inherits = FALSE); if (is.null(v) || is.na(v)) 0 else v }  # blank/text -> 0
  RNG <- function(ks) vapply(ks, function(k) { v <- get0(k, envir = val, inherits = FALSE); if (is.null(v)) NA_real_ else v }, 0)
  XSUM <- function(...) sum(unlist(list(...)), na.rm = TRUE)
  XAVG <- function(...) mean(unlist(list(...)), na.rm = TRUE)
  ev <- environment()
  fk <- fc$k; done <- rep(FALSE, length(fk)); isf <- new.env(hash = TRUE)
  for (k in fk) assign(k, TRUE, envir = isf)
  # iterative topological evaluation (text-valued formulas, e.g. esttab strings in 'Regressions', become NA)
  repeat {
    prog <- FALSE
    for (i in which(!done)) {
      d <- tr[[i]]$deps
      ready <- all(vapply(d, function(k) !exists(k, envir = isf, inherits = FALSE) || exists(k, envir = val, inherits = FALSE), TRUE))
      if (ready) { assign(fk[i], suppressWarnings(as.numeric(eval(tr[[i]]$expr, envir = ev))), envir = val); done[i] <- TRUE; prog <- TRUE }
    }
    if (all(done) || !prog) break
  }
  if (!all(done)) warning(sum(!done), " formula cells unresolved (circular?)")
  fc$recalc <- vapply(fk, function(k) { v <- get0(k, envir = val, inherits = FALSE); if (is.null(v)) NA_real_ else v }, 0)
  fc |> select(sheet, address, row, col, formula, cached = numeric, recalc) |>
    mutate(absdiff = abs(recalc - cached), reldiff = absdiff / pmax(abs(cached), 1e-12))
}

# value lookup in a recalculated workbook: formula cells -> recalc, input cells -> input value
wb_values <- function(path, rc) {
  cells <- xlsx_cells(path) |> filter(!is_blank) |> select(sheet, address, row, col, numeric, character, formula)
  cells |> left_join(rc |> select(sheet, address, recalc), by = c("sheet", "address")) |>
    mutate(value = ifelse(is.na(formula), numeric, recalc))
}
