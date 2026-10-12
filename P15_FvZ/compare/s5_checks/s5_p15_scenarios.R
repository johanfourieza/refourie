# S5 checks for P15_FvZ: re-run the verified workbook recalculation (repro_original/01_recalc_workbook.R)
# with single-formula edits, to quantify the effect of each candidate finding on Table A1 (1990 $).
# The engine is loaded from the original script text (lines 32-34 and 44-190), unchanged except for an
# 'edit' hook that rewrites formula strings before evaluation. original/ and repro_original/ are read only.
suppressPackageStartupMessages({library(dplyr); library(readr)})
root <- "./P15_FvZ"
src <- readLines(file.path(root, "repro_original/01_recalc_workbook.R"))[c(32:34, 44:190)]
src <- sub("recalc_workbook <- function(path, label) {", "recalc_workbook <- function(path, label, edit = identity) {", src, fixed = TRUE)
i <- grep("select(sheet, address, row, col, data_type", src, fixed = TRUE); src <- append(src, "  cells <- edit(cells)", after = i)
eval(parse(text = src))
source(file.path(root, "..", "tools", "paths.R")); wb <- dpath("P15_FvZ", "original/Fourie Van Zanden/Van Duin en Ross.xlsx")
wbc <- dpath("P15_FvZ", "original/Fourie Van Zanden/Copy of Van Duin en Ross.xlsx")
ed <- function(sheet, col, pattern, repl, rows = NULL) function(cells) {
  k <- cells$sheet == sheet & grepl(paste0("^", col, "[0-9]+$"), cells$address) & !is.na(cells$formula)
  if (!is.null(rows)) k <- k & cells$row %in% rows
  n0 <- sum(k & grepl(pattern, cells$formula, fixed = TRUE))
  cells$formula[k] <- gsub(pattern, repl, cells$formula[k], fixed = TRUE)
  message(sheet, "!", col, ": ", n0, " formulas edited"); cells }
compose <- function(...) { fs <- list(...); function(cells) { for (f in fs) cells <- f(cells); cells } }
getcol <- function(x, sheet, col, rows) { y <- x[x$sheet == sheet & x$col == col & x$row %in% rows, ]; y$recalc[match(rows, y$row)] }
TE <- 3:95; years <- 1701:1793
grab <- function(x) tibble(year = years,
  A1 = getcol(x, "total economy", 23, TE), eur = getcol(x, "total economy", 24, TE),
  agri = getcol(x, "total economy", 2, TE), voc = getcol(x, "total economy", 3, TE), rest = getcol(x, "total economy", 4, TE),
  gdp = getcol(x, "total economy", 5, TE), K = getcol(x, "total economy", 11, TE), pop = getcol(x, "Population", 24, TE + 1),
  wheat = getcol(x, "Agricultural production", 34, TE + 1), wine = getcol(x, "Agricultural production", 36, TE + 1),
  meat = getcol(x, "Agricultural production", 31, TE + 1), aginv = getcol(x, "Agricultural production", 37, TE + 1),
  crafts_constr = getcol(x, "resteconomy", 4, TE) / 1000, butchers = getcol(x, "resteconomy", 7, TE) / 1000,
  bakers = getcol(x, "resteconomy", 8, TE) / 1000, wine_margin = getcol(x, "resteconomy", 10, TE) / 1000,
  slave_margin = getcol(x, "resteconomy", 12, TE) / 1000, import_margin = getcol(x, "resteconomy", 13, TE) / 1000)
sil <- 1769:1794 - 1699          # INCOMEVOCEMPLOYEES rows for 1769-1794
scen <- list(
  base = identity,
  bakers_10pct = ed("resteconomy", "H", "*0.2", "*0.1"),
  meat_simple_average = ed("Livestock in possession", "AD", "+2*AC", "+AC") |> (\(f) compose(f, ed("Livestock in possession", "AD", ")/3", ")/2")))(),
  wine_margin_on_domestic_consumption = ed("resteconomy", "J", "'Agricultural production'!D", "'Agricultural production'!G"),
  silver_keep_8.04_after_1768 = compose(ed("INCOMEVOCEMPLOYEES", "H", "/9.61", "/8.04", rows = c(sil, 44)), ed("INCOMEVOCEMPLOYEES", "J", "/9.61", "/8.04", rows = c(sil, 44)),
                                        ed("total economy", "I", "/9.61", "/8.04")),
  silver_J44_only = ed("INCOMEVOCEMPLOYEES", "J", "/9.61", "/8.04", rows = 44),
  gk_unrounded_constants = ed("total economy", "W", "(2335*L", "(V3*L") |> (\(f) compose(f, ed("total economy", "W", "/177)", "/U3)")))())
# text p.475: "50% of the wissel transfers"; workbook INCOMEVOCEMPLOYEES!I takes 50% of F = E - D (wissels net of
# the wage-transfer column D), and F is a typed 0 in the early rows. Scenario: 50% of gross wissels (E).
scen$wissel_50pct_of_gross <- function(cells) {
  k <- cells$sheet == "INCOMEVOCEMPLOYEES" & grepl("^I[0-9]+$", cells$address) & !is.na(cells$formula)
  cells$formula[k] <- gsub("\\+F([0-9]+)\\*0\\.5", "+E\\1*0.5", cells$formula[k])
  message("wissel: ", sum(grepl("\\+E[0-9]+\\*0\\.5", cells$formula[k])), " formulas edited"); cells }
scen$text_consistent_all3 <-compose(scen$bakers_10pct, scen$meat_simple_average, scen$wine_margin_on_domestic_consumption)
res <- lapply(names(scen), function(s) { message("== ", s); grab(recalc_workbook(wb, "primary", scen[[s]])) |> mutate(scenario = s) })
R <- bind_rows(res)
base <- R |> filter(scenario == "base")
stopifnot(abs(base$A1[1] - 1702.652) < 0.01)
trend <- function(y, v) 100 * (exp(coef(lm(log(v) ~ y))[2]) - 1)
summ <- R |> group_by(scenario) |> summarise(A1_1701 = A1[year == 1701], A1_1790 = A1[year == 1790],
  mean_pct_vs_base = 100 * mean(A1 / base$A1 - 1), min_pct = 100 * min(A1 / base$A1 - 1), max_pct = 100 * max(A1 / base$A1 - 1),
  gdp_trend = trend(year, gdp / K), pc_trend = trend(year, A1), .groups = "drop")
print(as.data.frame(summ), digits = 5)
write_csv(summ, file.path(root, "compare/s5_checks/s5_p15_scenarios_summary.csv"))
write_csv(R, file.path(root, "compare/s5_checks/s5_p15_scenarios_series.csv"))
# shares of components in base nominal GDP
cat("\nBase component shares of nominal GDP (mean 1701-1793):\n")
print(round(colMeans(base |> transmute(across(c(agri, voc, rest, wheat, wine, meat, aginv, crafts_constr, butchers, bakers, wine_margin, slave_margin, import_margin), ~ .x / gdp))), 3))
# population denominator: Fig 1 total (digitised, every 5th year, interpolated) instead of Population!X
cl <- read_csv(file.path(root, "claims/claims.csv"), show_col_types = FALSE)
f1 <- cl |> filter(grepl("^F1_[0-9]{4}_total$", claim_id)) |> transmute(year = as.integer(substr(claim_id, 4, 7)), f1 = as.numeric(reported_value))
f1i <- approx(f1$year, f1$f1, xout = years, rule = 2)$y
cat("\nFig 1 population as denominator: A1 change % (1701, mean, 1790):", round(100 * (base$pop[1] / f1i[1] - 1), 1),
    round(100 * mean(base$pop / f1i - 1), 1), round(100 * (base$pop[years == 1790] / f1i[years == 1790] - 1), 1), "\n")
# comparators (typed values in primary total economy V = Holland $, Z = UK $)
x0 <- recalc_workbook(wb, "primary")
hol <- getcol(x0, "total economy", 22, TE); uk <- getcol(x0, "total economy", 26, TE)
cmp <- tibble(year = years, cape = base$A1, eur = base$eur, hol, uk)
cat("\nCape total / Holland: mean", round(mean(cmp$cape / cmp$hol, na.rm = TRUE), 3), " range", round(range(cmp$cape / cmp$hol, na.rm = TRUE), 3),
    "; years Cape >= Holland:", sum(cmp$cape >= cmp$hol, na.rm = TRUE), "/", sum(!is.na(cmp$hol)), "\n")
cat("Cape total / UK: mean", round(mean(cmp$cape / cmp$uk, na.rm = TRUE), 3), " range", round(range(cmp$cape / cmp$uk, na.rm = TRUE), 3),
    "; years Cape >= UK:", sum(cmp$cape >= cmp$uk, na.rm = TRUE), "/", sum(!is.na(cmp$uk)), "\n")
for (p in list(1701:1710, 1741:1750, 1781:1790)) { k <- cmp$year %in% p
  cat(range(p), ": Cape", round(mean(cmp$cape[k])), " Eur", round(mean(cmp$eur[k])), " Holland", round(mean(cmp$hol[k])), " UK", round(mean(cmp$uk[k])), "\n") }
write_csv(cmp, file.path(root, "compare/s5_checks/s5_p15_comparators.csv"))
# balanced series (copy workbook total economy Z) and its range
xc <- recalc_workbook(wbc, "copy"); bal <- getcol(xc, "total economy", 26, TE)
cat("\nBalanced $ range 1701-1793:", round(range(bal), 1), "; years inside 600-1000:", sum(bal >= 600 & bal <= 1000), "/93; mean", round(mean(bal)), "\n")
cat("years < 600:", years[bal < 600], "\n years > 1000:", years[bal > 1000], "\n")
