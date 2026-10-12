# P15_FvZ  S2 original-code reproduction: recalculate the Excel formula chain in R.
#
# PROTOCOL S2 (Excel-only analyses): extract the formula chain with tidyxl,
# re-implement it in R and recalculate from the INPUT (non-formula) cells.
#
# Method. The workbooks use only arithmetic (+ - * / ^, unary +/-), cell and
# range references (same-sheet and cross-sheet, relative and absolute) and two
# functions, SUM and AVERAGE (checked below: the script stops if anything else
# appears). Every formula is lexed with tidyxl::xlex() and translated token by
# token into an R expression. All formula cells are cleared, the dependency graph
# is built from the parsed references, and the formulas are evaluated in
# topological order (Kahn's algorithm) starting from the input cells only.
# Excel semantics implemented: blank = 0 in arithmetic; text in arithmetic =
# #VALUE!; SUM/AVERAGE skip text and blanks; division by zero and any non-finite
# result = error; errors propagate; a formula that is a single reference (e.g.
# "+'Exports of grains'!B8") returns the referenced value, text included.
# The cached values stored in the workbook are used ONLY to verify the
# recalculation, never as inputs to formula cells.
#
# Workbooks recalculated (read-only, from original/):
#   primary : original/Fourie Van Zanden/Van Duin en Ross.xlsx           (2013-05-22)
#   copy    : original/Fourie Van Zanden/Copy of Van Duin en Ross.xlsx   (2013-08-09)
#             (needed because only this version holds the "balanced population"
#              series of Figs 3 and 7)
#
# Outputs (repro_original/):
#   recalc_cells_<wb>.rds       every cell with cached and recalculated value
#   formula_inventory.csv       the chain feeding the reported series (both workbooks)
#   recalc_fidelity.csv         recalculated vs cached, by workbook and sheet
#   recalc_series.csv           the recalculated series used for the claims

suppressPackageStartupMessages({
  library(tidyxl); library(dplyr); library(tidyr); library(readr); library(stringr); library(purrr)
})

args_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- if (length(args_file)) normalizePath(file.path(dirname(args_file), "..")) else here::here()
out_dir <- file.path(root, "repro_original"); source(file.path(root, "..", "tools", "paths.R")); data_dir <- dpath("P15_FvZ", "repro_original")  # A6: data on D:
wb_paths <- c(
  primary = dpath("P15_FvZ", "original", "Fourie Van Zanden", "Van Duin en Ross.xlsx"),
  copy    = dpath("P15_FvZ", "original", "Fourie Van Zanden", "Copy of Van Duin en Ross.xlsx")
)

# ---------------------------------------------------------------- helpers ----
col2num <- function(x) vapply(strsplit(x, ""), function(ch) {
  n <- 0; for (c in ch) n <- n * 26 + (utf8ToInt(c) - 64L); n }, numeric(1))
num2col <- function(n) vapply(n, function(k) { s <- ""; while (k > 0) { r <- (k - 1) %% 26
  s <- paste0(LETTERS[r + 1], s); k <- (k - 1) %/% 26 }; s }, character(1))
parse_addr <- function(a) {             # "$AB$12" -> c(row, col)
  a <- gsub("\\$", "", a)
  c(as.numeric(sub("^[A-Z]+", "", a)), col2num(sub("[0-9]+$", "", a)))
}

ALLOWED_FUN <- c("SUM", "AVERAGE")

# Translate one formula into R code and a list of referenced (sheet, r1, c1, r2, c2).
translate <- function(formula, sheet) {
  tk <- xlex(formula)
  code <- character(0); refs <- list(); cur_sheet <- NULL
  for (i in seq_len(nrow(tk))) {
    ty <- tk$type[i]; tok <- tk$token[i]
    if (ty == "sheet") { cur_sheet <- sub("!$", "", tok); cur_sheet <- gsub("^'|'$", "", cur_sheet)
      cur_sheet <- gsub("''", "'", cur_sheet); next }
    if (ty == "ref") {
      sh <- if (is.null(cur_sheet)) sheet else cur_sheet; cur_sheet <- NULL
      parts <- strsplit(tok, ":", fixed = TRUE)[[1]]
      if (!all(grepl("^\\$?[A-Z]+\\$?[0-9]+$", parts))) stop("unsupported ref: ", tok, " in ", formula)
      a <- parse_addr(parts[1]); b <- if (length(parts) == 2) parse_addr(parts[2]) else a
      r1 <- min(a[1], b[1]); r2 <- max(a[1], b[1]); c1 <- min(a[2], b[2]); c2 <- max(a[2], b[2])
      refs[[length(refs) + 1]] <- list(sheet = sh, r1 = r1, c1 = c1, r2 = r2, c2 = c2)
      sq <- deparse(sh)
      code <- c(code, if (length(parts) == 1) sprintf("V(%s,%d,%d)", sq, r1, c1)
                      else sprintf("RNG(%s,%d,%d,%d,%d)", sq, r1, c1, r2, c2))
      next
    }
    code <- c(code, switch(ty,
      operator = { if (!tok %in% c("+", "-", "*", "/", "^")) stop("unsupported operator ", tok); tok },
      number = tok,
      paren_open = "(", paren_close = ")",
      fun_open = "(", fun_close = ")",
      separator = ",",
      `function` = { if (!tok %in% ALLOWED_FUN) stop("unsupported function ", tok)
                     c(SUM = "XSUM", AVERAGE = "XAVG")[[tok]] },
      stop("unsupported token type ", ty, " (", tok, ") in ", formula)))
  }
  # Excel gives unary minus precedence over ^ (=-2^2 is 4); R does not. The lexer
  # folds "-2" into a number token, and no formula in these workbooks has a unary
  # minus before ^, which is checked here.
  if (any(code == "^") && grepl("(^|[-+*/(,])\\s*-\\s*[A-Za-z(0-9]", formula) && grepl("\\^", formula))
    warning("check unary minus with ^ in: ", formula)
  single <- nrow(tk) <= 3 && sum(tk$type == "ref") == 1 && all(tk$type %in% c("ref", "sheet", "operator")) &&
    all(tk$token[tk$type == "operator"] == "+") && !grepl(":", tk$token[tk$type == "ref"])
  list(code = paste(code, collapse = " "), refs = refs, single = single)
}

# ------------------------------------------------------- recalculation -------
recalc_workbook <- function(path, label) {
  cells <- xlsx_cells(path) |>
    filter(!is_blank | !is.na(formula)) |>
    select(sheet, address, row, col, data_type, numeric, character, logical, error, formula)
  funs <- unique(unlist(str_extract_all(na.omit(cells$formula), "[A-Z][A-Z0-9.]*(?=\\()")))
  if (length(setdiff(funs, ALLOWED_FUN))) stop("unsupported functions: ", paste(setdiff(funs, ALLOWED_FUN), collapse = ", "))

  sheets <- unique(cells$sheet)
  dims <- cells |> group_by(sheet) |> summarise(nr = max(row) + 5, nc = max(col) + 5)
  # value store: num (numeric value), typ (0 blank, 1 number, 2 text, 3 error)
  NUM <- new.env(); TYP <- new.env(); TXT <- new.env()
  for (s in sheets) {
    d <- dims[dims$sheet == s, ]
    NUM[[s]] <- matrix(0, d$nr, d$nc); TYP[[s]] <- matrix(0L, d$nr, d$nc); TXT[[s]] <- matrix(NA_character_, d$nr, d$nc)
  }
  inp <- cells |> filter(is.na(formula))
  for (s in sheets) {
    x <- inp[inp$sheet == s, ]
    ix <- cbind(x$row, x$col)
    isn <- x$data_type == "numeric"; ist <- x$data_type %in% c("character", "date"); ise <- x$data_type == "error"
    isb <- x$data_type == "logical"
    m <- NUM[[s]]; t <- TYP[[s]]; tx <- TXT[[s]]
    m[ix[isn, , drop = FALSE]] <- x$numeric[isn]; t[ix[isn, , drop = FALSE]] <- 1L
    m[ix[isb, , drop = FALSE]] <- as.numeric(x$logical[isb]); t[ix[isb, , drop = FALSE]] <- 1L
    t[ix[ist, , drop = FALSE]] <- 2L; tx[ix[ist, , drop = FALSE]] <- x$character[ist]
    t[ix[ise, , drop = FALSE]] <- 3L
    NUM[[s]] <- m; TYP[[s]] <- t; TXT[[s]] <- tx
  }

  # Evaluation primitives (Excel semantics; NaN marks an error value).
  V <- function(s, r, c) { ty <- TYP[[s]][r, c]
    if (ty == 2L || ty == 3L) NaN else NUM[[s]][r, c] }
  RNG <- function(s, r1, c1, r2, c2) { ty <- TYP[[s]][r1:r2, c1:c2]; v <- NUM[[s]][r1:r2, c1:c2]
    if (any(ty == 3L)) return(NaN); structure(v[ty == 1L], class = "xlrange") }
  XSUM <- function(...) { a <- list(...); s <- 0
    for (x in a) { x <- unclass(x); if (any(is.nan(x))) return(NaN); s <- s + sum(x) }; s }
  XAVG <- function(...) { a <- unlist(lapply(list(...), unclass)); if (any(is.nan(a))) return(NaN)
    if (!length(a)) return(NaN); mean(a) }
  ev <- environment()

  fcells <- cells |> filter(!is.na(formula)) |> mutate(key = paste0(sheet, "!", address))
  tr <- map2(fcells$formula, fcells$sheet, translate)
  fcells$code <- map_chr(tr, "code"); fcells$single <- map_lgl(tr, "single")
  exprs <- lapply(fcells$code, function(z) parse(text = z)[[1]])

  # dependency graph among formula cells
  fkey_index <- setNames(seq_len(nrow(fcells)), fcells$key)
  deps <- map(tr, function(t) {
    out <- integer(0)
    for (rf in t$refs) {
      rr <- rf$r1:rf$r2; cc <- rf$c1:rf$c2
      ks <- paste0(rf$sheet, "!", as.vector(outer(cc, rr, function(c, r) paste0(num2col(c), r))))
      out <- c(out, fkey_index[ks[ks %in% names(fkey_index)]])
    }
    unique(unname(out))
  })
  n <- nrow(fcells); indeg <- lengths(deps)
  rev_adj <- vector("list", n); for (i in seq_len(n)) for (j in deps[[i]]) rev_adj[[j]] <- c(rev_adj[[j]], i)
  queue <- which(indeg == 0); ord <- integer(0)
  while (length(queue)) { i <- queue[1]; queue <- queue[-1]; ord <- c(ord, i)
    for (k in rev_adj[[i]]) { indeg[k] <- indeg[k] - 1L; if (indeg[k] == 0L) queue <- c(queue, k) } }
  if (length(ord) < n) stop(label, ": circular references among ", n - length(ord), " cells")

  # evaluate in dependency order
  for (i in ord) {
    s <- fcells$sheet[i]; r <- fcells$row[i]; c <- fcells$col[i]
    if (fcells$single[i]) {            # pure reference: copy value and type
      rf <- tr[[i]]$refs[[1]]
      NUM[[s]][r, c] <- NUM[[rf$sheet]][rf$r1, rf$c1]
      ty <- TYP[[rf$sheet]][rf$r1, rf$c1]; TYP[[s]][r, c] <- if (ty == 0L) 1L else ty
      TXT[[s]][r, c] <- TXT[[rf$sheet]][rf$r1, rf$c1]
      next
    }
    v <- unclass(eval(exprs[[i]], ev))
    if (length(v) != 1) v <- NaN       # a bare multi-cell range outside a function
    if (!is.finite(v)) { NUM[[s]][r, c] <- 0; TYP[[s]][r, c] <- 3L } else { NUM[[s]][r, c] <- v; TYP[[s]][r, c] <- 1L }
  }

  fcells$recalc_type <- c("blank", "numeric", "character", "error")[1 + map2_int(fcells$sheet, seq_len(n),
    function(s, i) TYP[[s]][fcells$row[i], fcells$col[i]])]
  fcells$recalc <- map2_dbl(fcells$sheet, seq_len(n), function(s, i)
    if (TYP[[s]][fcells$row[i], fcells$col[i]] == 1L) NUM[[s]][fcells$row[i], fcells$col[i]] else NA_real_)
  fcells$eval_order <- match(seq_len(n), ord)
  all_cells <- cells |> mutate(key = paste0(sheet, "!", address)) |>
    left_join(fcells |> select(key, code, recalc, recalc_type, eval_order), by = "key") |>
    mutate(workbook = label, is_formula = !is.na(formula),
           cached = numeric,
           recalc = ifelse(is_formula, recalc, numeric),
           recalc_type = ifelse(is_formula, recalc_type, data_type),
           abs_diff = abs(recalc - cached))
  attr(all_cells, "deps") <- deps; attr(all_cells, "fkeys") <- fcells$key
  attr(all_cells, "refs") <- setNames(map(tr, "refs"), fcells$key)
  all_cells
}

# --------------------------------------------- chain extraction (ancestors) ----
chain_of <- function(all_cells, targets) {
  refs <- attr(all_cells, "refs")
  seen <- character(0); stack <- intersect(targets, all_cells$key)
  while (length(stack)) {
    k <- stack[length(stack)]; stack <- stack[-length(stack)]
    if (k %in% seen) next
    seen <- c(seen, k)
    for (rf in refs[[k]]) {
      rr <- rf$r1:rf$r2; cc <- rf$c1:rf$c2
      ks <- paste0(rf$sheet, "!", as.vector(outer(cc, rr, function(c, r) paste0(num2col(c), r))))
      ks <- ks[ks %in% all_cells$key & !ks %in% seen]
      stack <- c(stack, ks)
    }
  }
  seen
}

# ------------------------------------------------------------------ run ------
res <- imap(wb_paths, recalc_workbook)

# Fidelity: recalculated vs cached for every formula cell.
fid_cells <- bind_rows(lapply(res, function(x) x |> filter(is_formula))) |>
  mutate(type_match = case_when(
    data_type == "numeric" & recalc_type == "numeric" ~ TRUE,
    data_type == "error" & recalc_type == "error" ~ TRUE,
    data_type == "character" & recalc_type == "character" ~ TRUE,
    TRUE ~ FALSE),
    rel_diff = abs_diff / pmax(abs(cached), 1e-12))

# Target series (rows = years). Primary: total economy rows 3-99 (1701-1797 and
# the growth-rate cells in row 99), Population rows 4-98. Copy: the same plus the
# balanced-population columns.
tgt_keys <- function(sheet, cols, rows) as.vector(outer(cols, rows, function(c, r) paste0(sheet, "!", c, r)))
targets <- list(
  primary = c(tgt_keys("total economy", c("A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","Q","R","W","X","AA","AB","AC","AD"), 3:99),
              tgt_keys("Population", c("P","R","T","U","X"), 4:98)),
  copy    = c(tgt_keys("total economy", c("A","B","C","D","E","F","G","H","L","M","R","S","X","Y","Z"), 3:99),
              tgt_keys("Population", c("S"), 4:98))
)
inv <- imap_dfr(res, function(x, lab) {
  ch <- chain_of(x, targets[[lab]])
  x |> filter(key %in% ch) |>
    transmute(workbook = lab, sheet, cell = address, row, col, is_formula, formula,
              cached_type = data_type, cached_value = ifelse(data_type == "character", character, as.character(cached)),
              recalc_value = recalc, abs_diff, eval_order)
}) |> arrange(workbook, sheet, col, row)
fid_chain <- fid_cells |> semi_join(inv |> filter(is_formula), by = c("workbook", "sheet", "address" = "cell"))

fid_summary <- bind_rows(
  fid_cells |> mutate(scope = "all formula cells"),
  fid_chain |> mutate(scope = "chain formula cells")) |>
  group_by(scope, workbook) |>
  summarise(n_formula = n(), n_type_match = sum(type_match),
            n_numeric_both = sum(!is.na(abs_diff)),
            max_abs_diff = max(abs_diff, na.rm = TRUE),
            max_rel_diff = max(rel_diff[abs(cached) > 1e-9], na.rm = TRUE),
            n_absdiff_gt_1e9 = sum(abs_diff > 1e-9, na.rm = TRUE), .groups = "drop")
fid_by_sheet <- fid_cells |> group_by(workbook, sheet) |>
  summarise(n_formula = n(), n_type_match = sum(type_match),
            max_abs_diff = suppressWarnings(max(abs_diff, na.rm = TRUE)), .groups = "drop") |>
  mutate(scope = "by sheet")

# Recalculated series, long by year, for script 02.
get_col <- function(x, sheet, col, rows) {
  x |> filter(sheet == !!sheet, address %in% paste0(col, rows)) |>
    transmute(row, value = recalc, type = recalc_type)
}
te_rows <- 3:97; yr <- function(r) 1698 + r  # total economy: row 3 = 1701
pop_yr <- function(r) 1697 + r               # Population:    row 4 = 1701
series <- bind_rows(
  imap_dfr(list(agri = "B", voc = "C", rest = "D", gdp_cur = "E", gdp_const = "F", pop_k = "G",
                gdppc_cur = "H", cpi = "I", deflator = "K", gdppc_const = "L", eur_pc_real = "R",
                gk_total = "W", gk_eur = "X", inv_gross_share = "AB"),
           function(cc, nm) get_col(res$primary, "total economy", cc, te_rows) |> mutate(series = nm, year = yr(row))) |>
    mutate(workbook = "primary"),
  imap_dfr(list(pop_eur = "P", pop_slave = "R", pop_eur_slave = "T", pop_khoe = "U", pop_total = "X"),
           function(cc, nm) get_col(res$primary, "Population", cc, 4:98) |> mutate(series = nm, year = pop_yr(row))) |>
    mutate(workbook = "primary"),
  imap_dfr(list(gdppc_const = "L", balanced_const = "M", eur_pc_real = "S", gk_total = "X", gk_eur = "Y", gk_balanced = "Z"),
           function(cc, nm) get_col(res$copy, "total economy", cc, te_rows) |> mutate(series = nm, year = yr(row))) |>
    mutate(workbook = "copy"),
  imap_dfr(list(balance_ratio = "S"),
           function(cc, nm) get_col(res$copy, "Population", cc, 4:98) |> mutate(series = nm, year = pop_yr(row))) |>
    mutate(workbook = "copy")
) |> select(workbook, series, year, value, type)
# compound growth cells (row 99) of total economy
growth_cells <- res$primary |> filter(sheet == "total economy", address %in% c("F99", "G99")) |>
  select(address, formula, cached, recalc)

saveRDS(res$primary, file.path(data_dir, "recalc_cells_primary.rds"))
saveRDS(res$copy, file.path(data_dir, "recalc_cells_copy.rds"))
write_csv(inv, file.path(out_dir, "formula_inventory.csv"), na = "")
write_csv(bind_rows(fid_summary, fid_by_sheet), file.path(out_dir, "recalc_fidelity.csv"), na = "")
write_csv(series, file.path(out_dir, "recalc_series.csv"), na = "")
write_csv(growth_cells, file.path(out_dir, "recalc_growth_cells.csv"), na = "")

cat("Recalculation fidelity\n"); print(as.data.frame(fid_summary))
cat("\nType mismatches (first 20):\n")
print(as.data.frame(fid_cells |> filter(!type_match) |> select(workbook, sheet, address, data_type, recalc_type, formula) |> head(20)))
cat("\nLargest abs differences:\n")
print(as.data.frame(fid_cells |> arrange(desc(abs_diff)) |> select(workbook, sheet, address, cached, recalc, abs_diff, formula) |> head(10)))
cat("\nChain size:\n"); print(inv |> count(workbook, is_formula))
