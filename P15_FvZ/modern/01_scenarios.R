# P15_FvZ  S6 modern reanalysis, step 1: scenario enumeration.
#
# Implements the FROZEN method card modern/method_card.md (commit 404b4fb):
#   central layer C1-C4 (text-consistent corrections), the unresolved layer U1-U6
#   enumerated in full (2^4 x 3 x 3 = 144 scenarios), sensitivity 1 (central layer off,
#   x 144) and the inputs for sensitivities 2 (decade means) and 3 (tornado).
#
# Engine. The faithful S2 recalculation (repro_original/01_recalc_workbook.R, lines 44-190:
# helpers, translate(), recalc_workbook()) is loaded from the original file, unchanged,
# except for (i) an 'edit' hook that rewrites the cell table before evaluation (the same
# hook used in compare/s5_checks/s5_p15_scenarios.R) and (ii) memoisation of the workbook
# read and of the formula translation (pure functions; speed only).
#
# Order of work (card section 4, implementation rule):
#   1. write modern/item_cells.csv = every cell changed by each item level (this file is
#      also what the scenarios apply, so the list is exact by construction);
#   2. verify that all items 'as coded' with C1-C4 off reproduce the S2 recalculation
#      (max abs diff < 1e-9, every formula cell, both workbooks);
#   3. enumerate the scenarios and compute the estimands.
#
# Outputs: modern/item_cells.csv; modern/output/: verification_s2.csv, scenarios.csv, scenario_series.csv, tornado.csv, comparators.csv.

suppressPackageStartupMessages({
  library(tidyxl); library(dplyr); library(tidyr); library(readr); library(stringr)
  library(purrr); library(parallel)
})

args_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- if (length(args_file)) normalizePath(file.path(dirname(args_file), "..")) else
  "./P15_FvZ"
mod <- file.path(root, "modern"); out <- file.path(mod, "output")
dir.create(out, showWarnings = FALSE); source(file.path(root, "..", "tools", "paths.R"))  # A6: data on D:
wb_paths <- c(primary = dpath("P15_FvZ", "original", "Fourie Van Zanden", "Van Duin en Ross.xlsx"),
              copy    = dpath("P15_FvZ", "original", "Fourie Van Zanden", "Copy of Van Duin en Ross.xlsx"))

# ------------------------------------------------------------- engine --------
engine_setup <- function(root) {
  suppressPackageStartupMessages({library(tidyxl); library(dplyr); library(stringr); library(purrr)})
  src <- readLines(file.path(root, "repro_original/01_recalc_workbook.R"))
  stopifnot(startsWith(src[44], "# ---"), src[190] == "}",
            grepl("^recalc_workbook <- function\\(path, label\\) \\{$", src[grep("^recalc_workbook", src)]))
  src <- src[44:190]
  src <- sub("recalc_workbook <- function(path, label) {",
             "recalc_workbook <- function(path, label, edit = identity) {", src, fixed = TRUE)
  i <- grep("select(sheet, address, row, col, data_type", src, fixed = TRUE)
  stopifnot(length(i) == 1)
  src <- append(src, "  cells <- edit(cells)", after = i)
  eval(parse(text = src), envir = globalenv())
  # memoisation (pure functions)
  assign(".xc_cache", new.env(), globalenv()); assign(".tr_cache", new.env(), globalenv())
  assign(".tr_orig", get("translate", globalenv()), globalenv())
  assign("xlsx_cells", function(path) {
    if (is.null(.xc_cache[[path]])) .xc_cache[[path]] <- tidyxl::xlsx_cells(path); .xc_cache[[path]] },
    globalenv())
  assign("translate", function(formula, sheet) {
    k <- paste0(sheet, "\r", formula)
    if (is.null(.tr_cache[[k]])) .tr_cache[[k]] <- .tr_orig(formula, sheet); .tr_cache[[k]] },
    globalenv())
  invisible(TRUE)
}
engine_setup(root)

# ---------------------------------------------------------- layout -----------
# Row-year maps (checked against the year column of each sheet below).
TE_row  <- function(y) y - 1698          # total economy, resteconomy, Livestock in possession
AG_row  <- function(y) y - 1697          # Agricultural production
VOC_row <- function(y) y - 1699          # INCOMEVOCEMPLOYEES
POP <- list(primary = list(row = function(y) y - 1697, kho = "U", slaves = "P", tot = "T", share = "W",
                           X = "X", estab = "L", keep = c("A", "W")),
            copy    = list(row = function(y) y - 1648, kho = "Z", slaves = "U", tot = "Y", share = "AB",
                           X = "AC", estab = "O", keep = c("A", "AB")))
YEARS <- 1701:1793; POPYEARS <- 1701:1795

base0 <- lapply(names(wb_paths), function(w) recalc_workbook(wb_paths[[w]], w)); names(base0) <- names(wb_paths)
val <- function(x, sheet, addr) x$recalc[match(paste0(sheet, "!", addr), x$key)]
for (w in names(wb_paths)) {
  stopifnot(all(val(base0[[w]], "Population", paste0("A", POP[[w]]$row(POPYEARS))) == POPYEARS),
            all(val(base0[[w]], "total economy", paste0("A", TE_row(YEARS))) == YEARS),
            all(val(base0[[w]], "resteconomy", paste0("A", TE_row(1703:1793))) == 1703:1793),
            all(val(base0[[w]], "INCOMEVOCEMPLOYEES", paste0("A", VOC_row(YEARS))) == YEARS))
}

# ------------------------------------------------ step 1: item cells ---------
fcell <- function(cells, sheet, col) {
  rx <- paste0("^", col, "[0-9]+$"); sh <- sheet
  y <- cells[cells$sheet == sh & str_detect(cells$address, rx) & !is.na(cells$formula), ]
  stopifnot(nrow(y) > 0)
  y
}
rec <- function(w, item, level, sheet, cell, change, old, new)
  tibble(workbook = w, item = item, level = level, sheet = sheet, cell = cell, change = change,
         old = as.character(old), new = as.character(new))
f17 <- function(x) sprintf("%.17g", x)

# Fig. 1 total population, digitised (claims rows F1_YYYY_total), interpolated linearly.
cl <- read_csv(file.path(root, "claims/claims.csv"), show_col_types = FALSE)
f1 <- cl |> filter(str_detect(claim_id, "^F1_[0-9]{4}_total$")) |>
  transmute(year = as.integer(substr(claim_id, 4, 7)), fig1_total = as.numeric(reported_value)) |> arrange(year)
stopifnot(min(f1$year) == 1701, max(f1$year) == 1795)
fig1 <- tibble(year = POPYEARS, fig1_total = approx(f1$year, f1$fig1_total, xout = POPYEARS)$y)

build_items <- function(w) {
  cells <- base0[[w]]; P <- POP[[w]]; R <- list()
  # C1 bakers' margin 0.2 -> 0.1 (resteconomy!H)
  x <- fcell(cells, "resteconomy", "H"); stopifnot(all(str_detect(x$formula, "\\*0\\.2$")))
  R$C1 <- rec(w, "C1", "on", x$sheet, x$address, "formula", x$formula, sub("\\*0\\.2$", "*0.1", x$formula))
  # C2 meat = simple average (Livestock in possession!AD)
  x <- fcell(cells, "Livestock in possession", "AD"); pat <- "^\\+\\(U([0-9]+)\\+2\\*AC([0-9]+)\\)/3$"
  stopifnot(all(str_detect(x$formula, pat)))
  R$C2 <- rec(w, "C2", "on", x$sheet, x$address, "formula", x$formula, sub(pat, "+(U\\1+AC\\2)/2", x$formula))
  # C3 wine retail margin on domestic consumption G = D - E (resteconomy!J, base column D -> G)
  x <- fcell(cells, "resteconomy", "J"); pat <- "^\\+N([0-9]+)\\*'Agricultural production'!D([0-9]+)$"
  x <- x |> filter(str_detect(formula, pat))
  gr <- as.integer(sub(pat, "\\2", x$formula))
  gf <- cells$formula[match(paste0("Agricultural production!G", gr), cells$key)]
  # G is D - E where exports are recorded and +D*0.8 in the earlier rows (logged in DEVIATIONS.md, D1)
  stopifnot(all(gf == paste0("+D", gr, "-E", gr) | gf == paste0("+D", gr, "*0.8")))
  R$C3 <- rec(w, "C3", "on", x$sheet, x$address, "formula", x$formula, sub(pat, "+N\\1*'Agricultural production'!G\\2", x$formula))
  # C4 wissel 50% of gross transfers (INCOMEVOCEMPLOYEES!I, F term -> E)
  x <- fcell(cells, "INCOMEVOCEMPLOYEES", "I"); pat <- "^\\+C([0-9]+)\\+F([0-9]+)\\*0\\.5\\+H([0-9]+)\\*1\\.05$"
  stopifnot(all(str_detect(x$formula, pat)))
  R$C4 <- rec(w, "C4", "on", x$sheet, x$address, "formula", x$formula, sub(pat, "+C\\1+E\\2*0.5+H\\3*1.05", x$formula))
  # U1 investment price contemporaneous (resteconomy!AB5:AB93: Agricultural production!AB row r-1 -> r+1)
  x <- fcell(cells, "resteconomy", "AB"); stopifnot(identical(sort(x$row), 5:93))
  new <- map2_chr(x$formula, x$row, function(f, r) {
    o <- paste0("'Agricultural production'!AB", r - 1); stopifnot(str_count(f, fixed(o)) == 2)
    gsub(o, paste0("'Agricultural production'!AB", r + 1), f, fixed = TRUE) })
  R$U1 <- rec(w, "U1", "contemporaneous", x$sheet, x$address, "formula", x$formula, new)
  # U2 vine-investment divisor /5 -> /6 (resteconomy!AA)
  x <- fcell(cells, "resteconomy", "AA"); stopifnot(all(str_detect(x$formula, "\\)\\)/5$")))
  R$U2 <- rec(w, "U2", "div6", x$sheet, x$address, "formula", x$formula, sub("\\)\\)/5$", "))/6", x$formula))
  # U3 silver content 8.04 held after 1768 (INCOMEVOCEMPLOYEES cells dividing by 9.61, incl. J44)
  x <- cells |> filter(sheet == "INCOMEVOCEMPLOYEES", !is.na(formula), str_detect(formula, fixed("/9.61")))
  stopifnot(setequal(x$address, c("J44", paste0(rep(c("H", "J"), each = 26), 70:95))))
  R$U3 <- rec(w, "U3", "silver_8.04", x$sheet, x$address, "formula", x$formula, gsub("/9.61", "/8.04", x$formula, fixed = TRUE))
  # U4 CPI 1787, 1793: typed overrides -> neighbouring formula rule (total economy!I89, I95)
  ir <- TE_row(c(1787, 1793)); stopifnot(all(is.na(cells$formula[match(paste0("total economy!I", ir), cells$key)])))
  # neighbours I88, I90 and I94 (I96 does not exist)
  for (r in c(ir - 1, ir[1] + 1)) stopifnot(cells$formula[match(paste0("total economy!I", r), cells$key)] ==
                                           paste0("+INCOMEVOCEMPLOYEES!G", r - 1, "/9.61"))
  R$U4 <- rec(w, "U4", "formula_rule", "total economy", paste0("I", ir), "typed_to_formula",
              cells$numeric[match(paste0("total economy!I", ir), cells$key)],
              paste0("+INCOMEVOCEMPLOYEES!G", ir - 1, "/9.61"))
  # U5 P0k: Khoesan = T*W/(1-W)
  pr <- P$row(POPYEARS)
  x <- fcell(cells, "Population", P$kho) |> filter(row %in% pr); stopifnot(nrow(x) == length(pr))
  stopifnot(all(x$formula == paste0("+", P$slaves, x$row, "*", P$share, x$row)))
  R$U5k <- rec(w, "U5", "P0k", x$sheet, x$address, "formula", x$formula,
               paste0("+", P$tot, x$row, "*", P$share, x$row, "/(1-", P$share, x$row, ")"))
  # U5 P1: every person count of the Population sheet, 1701-1795, rescaled by f = Fig1 / X (as coded)
  Xc <- val(cells, "Population", paste0(P$X, pr)); f <- setNames(fig1$fig1_total / Xc, pr)
  inp <- cells |> filter(sheet == "Population", row %in% pr, is.na(formula), data_type == "numeric") |>
    mutate(colL = str_remove(address, "[0-9]+$")) |> filter(!colL %in% P$keep)
  R$U5v <- rec(w, "U5", "P1", inp$sheet, inp$address, "value_scale", f17(inp$numeric),
               f17(inp$numeric * f[as.character(inp$row)]))
  # (a) the VOC-establishment link (a count read from 'Company establishment') is multiplied by f
  x <- fcell(cells, "Population", P$estab) |> filter(row %in% pr)
  pat_link <- "^\\+'Company establishment'!B[0-9]+$"
  x <- x |> filter(str_detect(formula, pat_link))
  R$U5f <- rec(w, "U5", "P1", x$sheet, x$address, "formula", x$formula,
               paste0(x$formula, "*", f17(f[as.character(x$row)])))
  # (b) count cells filled by interpolation of their neighbours, +(Ca+Cb)/2, are rewritten as
  #     +(Ca/fa+Cb/fb)/2*fr so that each equals f_r times its coded value exactly
  pat_int <- "^\\+\\(([A-Z]+)([0-9]+)\\+([A-Z]+)([0-9]+)\\)/2$"
  x <- cells |> filter(sheet == "Population", row %in% pr, !is.na(formula), str_detect(formula, pat_int))
  stopifnot(all(sub(pat_int, "\\1", x$formula) == str_remove(x$address, "[0-9]+$")),
            all(sub(pat_int, "\\3", x$formula) == str_remove(x$address, "[0-9]+$")),
            all(as.integer(sub(pat_int, "\\2", x$formula)) %in% pr), all(as.integer(sub(pat_int, "\\4", x$formula)) %in% pr))
  new <- pmap_chr(list(x$formula, x$row), function(fm, r) {
    cc <- sub(pat_int, "\\1", fm); a <- sub(pat_int, "\\2", fm); b <- sub(pat_int, "\\4", fm)
    paste0("+(", cc, a, "/", f17(f[a]), "+", cc, b, "/", f17(f[b]), ")/2*", f17(f[as.character(r)])) })
  R$U5i <- rec(w, "U5", "P1", x$sheet, x$address, "formula", x$formula, new)
  # U6 rest-of-economy level (craftsmen and construction, resteconomy!D) x 0.75 / 1.25
  x <- fcell(cells, "resteconomy", "D")
  R$U6 <- bind_rows(lapply(c(0.75, 1.25), function(m)
    rec(w, "U6", format(m, nsmall = 2), x$sheet, x$address, "formula", x$formula,
        paste0("+", m, "*(", sub("^\\+", "", x$formula), ")"))))
  bind_rows(R)
}
items <- bind_rows(lapply(names(wb_paths), build_items))
stopifnot(!anyDuplicated(items[, c("workbook", "item", "level", "cell", "sheet")]))
# no cell is touched by two different items
dup <- items |> distinct(workbook, sheet, cell, item) |> count(workbook, sheet, cell) |> filter(n > 1)
stopifnot(nrow(dup) == 0)
write_csv(items, file.path(mod, "item_cells.csv"))
cat("item_cells.csv:\n"); print(as.data.frame(items |> count(workbook, item, level, sheet, change)))

# --------------------------------------------- scenario edit function ---------
LEVELS <- list(U1 = c("lag2_coded", "contemporaneous"), U2 = c("div5_coded", "div6"),
               U3 = c("coded", "silver_8.04"), U4 = c("typed_coded", "formula_rule"),
               U5 = c("P0", "P0k", "P1"), U6 = c("1.00", "0.75", "1.25"))
active_items <- function(items_w, central, lv) {
  items_w |> filter((item %in% c("C1", "C2", "C3", "C4") & central) |
                             (item == "U1" & level == lv$U1) | (item == "U2" & level == lv$U2) |
                             (item == "U3" & level == lv$U3) | (item == "U4" & level == lv$U4) |
                             (item == "U5" & level == lv$U5) | (item == "U6" & level == lv$U6))
}
make_edit <- function(items_w, central, lv) {
  act <- active_items(items_w, central, lv)
  function(cells) {
    if (!nrow(act)) return(cells)
    k <- match(paste0(act$sheet, "!", act$cell), paste0(cells$sheet, "!", cells$address))
    stopifnot(!anyNA(k))
    isf <- act$change %in% c("formula", "typed_to_formula")
    stopifnot(all(act$change[!isf] == "value_scale"),
              all(is.na(cells$formula[k[act$change == "typed_to_formula"]])),
              all(cells$formula[k[act$change == "formula"]] == act$old[act$change == "formula"]))
    cells$formula[k[isf]] <- act$new[isf]
    cells$numeric[k[!isf]] <- as.numeric(act$new[!isf])
    attr(cells, "n_edits") <- nrow(act)
    cells
  }
}

# --------------------------------------------- step 2: S2 verification -------
s2 <- list(primary = readRDS(dpath("P15_FvZ", "repro_original/recalc_cells_primary.rds")),
           copy    = readRDS(dpath("P15_FvZ", "repro_original/recalc_cells_copy.rds")))
coded <- list(U1 = "lag2_coded", U2 = "div5_coded", U3 = "coded", U4 = "typed_coded", U5 = "P0", U6 = "1.00")
ver <- bind_rows(lapply(names(wb_paths), function(w) {
  x <- recalc_workbook(wb_paths[[w]], w, make_edit(items |> filter(workbook == w), FALSE, coded))
  j <- s2[[w]] |> filter(is_formula) |> select(key, s2 = recalc, s2_type = recalc_type) |>
    left_join(x |> select(key, m = recalc, m_type = recalc_type), by = "key")
  tibble(workbook = w, n_formula_cells = nrow(j), n_type_match = sum(j$s2_type == j$m_type),
         n_numeric = sum(!is.na(j$s2)), max_abs_diff = max(abs(j$m - j$s2), na.rm = TRUE),
         n_na_mismatch = sum(is.na(j$m) != is.na(j$s2)))
}))
print(as.data.frame(ver))
stopifnot(all(ver$max_abs_diff < 1e-9), all(ver$n_type_match == ver$n_formula_cells), all(ver$n_na_mismatch == 0))
write_csv(ver, file.path(out, "verification_s2.csv"))

# ---------------------------------------------------- comparators -------------
comp <- tibble(series = c("Holland", "Britain"), cell = c("total economy!V3", "total economy!Z3"),
               year = 1701, value = val(base0$primary, "total economy", c("V3", "Z3")),
               source = c("pasted value, van Zanden and van Leeuwen (2012) vintage", "pasted value, Broadberry et al. (2011) vintage"),
               workbook = "primary (Van Duin en Ross.xlsx)")
stopifnot(all(is.na(base0$primary$formula[match(comp$cell, base0$primary$key)])))
write_csv(comp, file.path(out, "comparators.csv"))
HOL <- comp$value[1]; GB <- comp$value[2]

# ------------------------------------------------ step 3: enumeration --------
grid <- expand.grid(U6 = LEVELS$U6, U5 = LEVELS$U5, U4 = LEVELS$U4, U3 = LEVELS$U3, U2 = LEVELS$U2,
                    U1 = LEVELS$U1, stringsAsFactors = FALSE)[, c("U1", "U2", "U3", "U4", "U5", "U6")]
stopifnot(nrow(grid) == 144)
scen <- bind_rows(grid |> mutate(central_layer = "on"), grid |> mutate(central_layer = "off")) |>
  mutate(scenario_id = row_number(), .before = 1)

n_active <- function(s, w) nrow(active_items(items |> filter(workbook == w), s$central_layer == "on",
                                               as.list(s[c("U1", "U2", "U3", "U4", "U5", "U6")])))
trend <- function(y, v) 100 * (exp(coef(lm(log(v) ~ y))[[2]]) - 1)
run_one <- function(i) {
  s <- scen[i, ]; lv <- as.list(s[c("U1", "U2", "U3", "U4", "U5", "U6")])
  get <- function(x, sheet, col, rows) {
    k <- match(paste0(sheet, "!", col, rows), x$key)
    tibble(v = x$recalc[k], t = x$recalc_type[k]) }
  xp <- recalc_workbook(wb_paths[["primary"]], "primary", make_edit(items |> filter(workbook == "primary"), s$central_layer == "on", lv))
  xc <- recalc_workbook(wb_paths[["copy"]], "copy", make_edit(items |> filter(workbook == "copy"), s$central_layer == "on", lv))
  Y <- get(xp, "total economy", "W", TE_row(YEARS)); Fr <- get(xp, "total economy", "F", TE_row(YEARS))
  Px <- get(xp, "Population", POP$primary$X, POP$primary$row(YEARS))
  B <- get(xc, "total economy", "Z", TE_row(YEARS)); Yc <- get(xc, "total economy", "X", TE_row(YEARS))
  Pc <- get(xc, "Population", POP$copy$X, POP$copy$row(POPYEARS))
  Pp95 <- get(xp, "Population", POP$primary$X, POP$primary$row(POPYEARS))
  ok <- all(c(Y$t, Fr$t, Px$t, B$t) == "numeric") && all(is.finite(c(Y$v, Fr$v, Px$v, B$v)))
  ser <- tibble(scenario_id = s$scenario_id, year = YEARS, gdppc_gk = Y$v, balanced_gk = B$v)
  y <- setNames(Y$v, YEARS)
  est <- tibble(scenario_id = s$scenario_id, finite = ok,
    Y1701 = y[["1701"]], Y1790 = y[["1790"]], R = y[["1790"]] / y[["1701"]],
    trend_gdp = if (ok) trend(YEARS, Fr$v) else NA_real_, trend_pop = if (ok) trend(YEARS, Px$v) else NA_real_,
    bal_share_in_band = mean(B$v >= 540 & B$v <= 1100), bal_min = min(B$v), bal_max = max(B$v),
    bal_share_600_1000 = mean(B$v >= 600 & B$v <= 1000),
    ratio_GB = y[["1701"]] / GB, ratio_NL = y[["1701"]] / HOL,
    Y_dec1701_10 = mean(y[as.character(1701:1710)]), Y_dec1781_90 = mean(y[as.character(1781:1790)]),
    R_decade = mean(y[as.character(1781:1790)]) / mean(y[as.character(1701:1710)]),
    pop1701 = Px$v[1], pop1790 = Px$v[YEARS == 1790],
    chk_primary_vs_copy_maxdiff = max(abs(Y$v - Yc$v)),
    chk_pop_vs_fig1_maxreldiff = if (lv$U5 == "P1") max(abs(c(Pp95$v, Pc$v) / rep(fig1$fig1_total, 2) - 1)) else NA_real_,
    n_cells_edited_primary = n_active(s, "primary"))
  list(est = est, ser = ser)
}

ncl <- 12
clu <- makeCluster(ncl)
clusterExport(clu, c("engine_setup", "root", "wb_paths", "items", "scen", "make_edit", "active_items", "n_active", "run_one", "trend",
                     "TE_row", "POP", "YEARS", "POPYEARS", "fig1", "HOL", "GB"))
invisible(clusterEvalQ(clu, { engine_setup(root); suppressPackageStartupMessages({library(dplyr); library(tibble)}); NULL }))
t0 <- Sys.time()
res <- parLapplyLB(clu, seq_len(nrow(scen)), run_one)
stopCluster(clu)
saveRDS(res, dscratch("P15_FvZ", "modern", "enumeration_res.rds"))  # temp copy, guards against a failed check below
cat("enumeration time:", format(Sys.time() - t0), "\n")

est <- bind_rows(map(res, "est")); ser <- bind_rows(map(res, "ser"))
scenarios <- scen |> left_join(est, by = "scenario_id")
cat("non-finite scenarios:", sum(!scenarios$finite), "\n")
stopifnot(max(scenarios$chk_primary_vs_copy_maxdiff, na.rm = TRUE) < 1e-6)
stopifnot(max(scenarios$chk_pop_vs_fig1_maxreldiff, na.rm = TRUE) < 1e-9)

# Tornado (sensitivity 3): each unresolved item varied alone around the central case
# (central layer on, all U items as coded).
is_coded <- function(d, nm) d[[nm]] == coded[[nm]]
cen <- scenarios |> filter(central_layer == "on", U1 == coded$U1, U2 == coded$U2, U3 == coded$U3,
                           U4 == coded$U4, U5 == coded$U5, U6 == coded$U6)
stopifnot(nrow(cen) == 1)
ests <- c("Y1701", "Y1790", "R", "trend_gdp", "trend_pop", "bal_share_in_band", "ratio_GB", "ratio_NL", "R_decade")
tornado <- bind_rows(lapply(names(LEVELS), function(it) {
  others <- setdiff(names(LEVELS), it)
  d <- scenarios |> filter(central_layer == "on", !is_coded(scenarios, it))
  for (o in others) d <- d[is_coded(d, o), ]
  d |> transmute(item = it, level = .data[[it]], scenario_id, across(all_of(ests)))
})) |>
  pivot_longer(all_of(ests), names_to = "estimand", values_to = "value") |>
  left_join(cen |> select(all_of(ests)) |> pivot_longer(everything(), names_to = "estimand", values_to = "central"),
            by = "estimand") |>
  mutate(delta = value - central, pct_delta = 100 * delta / central)
stopifnot(nrow(tornado) == 8 * length(ests))

write_csv(scenarios, file.path(out, "scenarios.csv"))
write_csv(ser, file.path(out, "scenario_series.csv"))
write_csv(tornado, file.path(out, "tornado.csv"))
writeLines(capture.output(sessionInfo()), file.path(mod, "sessionInfo.txt"))
cat("Central scenario (C on, U coded):\n"); print(as.data.frame(cen |> select(all_of(ests))))
cat("Coded scenario (C off, U coded):\n")
print(as.data.frame(scenarios |> filter(central_layer == "off", U1 == coded$U1, U2 == coded$U2, U3 == coded$U3,
                                        U4 == coded$U4, U5 == coded$U5, U6 == coded$U6) |> select(all_of(ests))))
