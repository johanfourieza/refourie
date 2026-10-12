# P30_STB24 S5 check 1: re-implements the Fig 5 / Fig 6 data path of StellenboschScript.R (l.46, 236-281, 344-405,
# 513-540, 631-638) and varies one defect at a time. Baseline must reproduce repro_original/output exactly.
# Run from project root: Rscript P30_STB24/compare/s5_checks/01_types_scenarios.R
suppressPackageStartupMessages({library(readxl); library(data.table); library(ineq); library(dplyr); library(readr)})
source("tools/paths.R")
f <- dpath("P30_STB24", "original", "2024F_Stellenbosch", "stellenbosch_clean.xlsx")
cache <- dscratch("P30_STB24", "compare", "reads.rds")
if (!file.exists(cache)) {
  guess <- read_excel(f, sheet = "Sheet1", col_names = TRUE)                    # l.46 as run (guess_max = 1000)
  full  <- read_excel(f, sheet = "Sheet1", col_names = TRUE, guess_max = 200000)  # same file, types from all rows
  saveRDS(list(guess = guess, full = full), cache)
}
r <- readRDS(cache); guess <- r$guess; full <- r$full
out <- "P30_STB24/compare/s5_checks/output"; dir.create(out, showWarnings = FALSE)

# Type audit: columns read as logical under the default guess but with non-0/1 values in the full read
ty <- tibble(col = names(guess), type_guess = sapply(guess, function(x) class(x)[1]), type_full = sapply(full, function(x) class(x)[1]),
             n_nonmiss = sapply(full, function(x) sum(!is.na(x))),
             n_gt1 = sapply(full, function(x) { y <- suppressWarnings(as.numeric(x)); sum(y > 1, na.rm = TRUE) }),
             mean_pos = sapply(full, function(x) { y <- suppressWarnings(as.numeric(x)); mean(y[y > 0], na.rm = TRUE) }))
write_csv(ty, file.path(out, "type_audit.csv"))
cat("columns logical under guess:", sum(ty$type_guess == "logical" & ty$n_nonmiss > 0),
    "; of which carry counts >1:", sum(ty$type_guess == "logical" & ty$n_gt1 > 0), "\n")

assets <- c("horses", "cattle", "sheep", "wheat_vol", "barley_vol", "wine")
hc <- c("horses", "horse_foals", "horse_work", "horse_riding", "horse_breeding", "horse_pleasure")
cc <- c("cattle_bull", "cattle_breeding", "cattle_work", "cattle_cows", "cattle_heifers", "cattle_calves")
sc <- c("sheep", "sheep_breeding", "sheep_wool", "sheep_wether", "sheep_goats")
need <- unique(c("year", hc, cc, sc, "wheat_vol", "barley_vol", "wine"))

pipeline <- function(raw, base_year = 1780, horse_riding = FALSE, wine_cap = Inf, fill_after_fallback = FALSE) {
  dt <- as.data.table(raw)[, ..need]
  numify <- function(dt) { for (v in setdiff(need, "year")) if (!is.numeric(dt[[v]])) set(dt, j = v, value = as.numeric(dt[[v]])); dt }
  zfill <- function(dt, cols) { for (col in cols) { yrs <- dt[!is.na(get(col)), unique(year)]
      for (y in yrs) dt[year == y & is.na(get(col)), (col) := 0] }; dt }        # l.236-247
  fallback <- function(dt) {
    hcols <- c("horse_foals", "horse_work", "horse_breeding", "horse_pleasure", if (horse_riding) "horse_riding")
    dt[, hs := rowSums(.SD, na.rm = TRUE), .SDcols = hcols][is.na(horses), horses := hs][, hs := NULL]   # l.362-369
    dt$cattle <- rowSums(dt[, ..cc], na.rm = TRUE)                                                        # l.378-384
    dt[, ss := rowSums(.SD, na.rm = TRUE), .SDcols = setdiff(sc, "sheep")][is.na(sheep), sheep := ss][, ss := NULL]  # l.393-405
    dt }
  if (is.logical(dt$wine)) { dt <- zfill(dt, setdiff(need, "year")) } else { dt <- numify(dt); dt <- zfill(dt, setdiff(need, "year")) }
  dt <- numify(dt)                                                              # l.357 as.numeric (logical -> 0/1)
  dt <- fallback(dt)
  dt[wine > wine_cap, wine := NA]
  dt[, year := as.numeric(year)]
  m <- dt[, lapply(.SD, mean, na.rm = TRUE), by = year, .SDcols = assets][order(year)]          # l.513-518
  b <- unlist(m[year == base_year, ..assets])
  idx <- copy(m); for (v in assets) set(idx, j = v, value = m[[v]] / b[[v]])                    # l.529-537
  keep <- rowSums(is.na(dt[, ..assets])) != length(assets)                                      # l.631-633
  g <- dt[keep, lapply(.SD, function(x) Gini(x, na.rm = TRUE)), by = year, .SDcols = assets][order(year)]
  list(m = m, idx = idx, g = g, n = nrow(dt))
}

summ <- function(res, label) {
  gl <- unlist(res$g[, ..assets]); gl <- gl[is.finite(gl)]
  w <- res$idx[year %in% c(1700, 1702, 1703, 1745, 1780, 1795, 1820), .(year, wine, cattle, horses)]
  tibble(scenario = label, rows = res$n, wine_1702 = res$idx[year == 1702, wine],
         gini_min = min(gl), gini_p10 = unname(quantile(gl, .1)), share_04_1 = mean(gl >= 0.4 & gl <= 1),
         n_assetyears = length(gl), wine_gini_peak_year = res$g[which.max(wine), year],
         cattle_gini_min = min(res$g$cattle, na.rm = TRUE),
         wine_1702_level = res$m[year == 1702, wine], wine_1780_level = res$m[year == 1780, wine], wine_1795_level = res$m[year == 1795, wine])
}

sc_list <- list(
  S0_baseline_as_run       = pipeline(guess),
  S1_types_fixed           = pipeline(full),
  S2_types_fixed_base1795  = pipeline(full, base_year = 1795),
  S3_types_fixed_horseride = pipeline(full, horse_riding = TRUE),
  S4_types_fixed_winecap   = pipeline(full, wine_cap = 1000),
  S5_all_fixes_base1795    = pipeline(full, base_year = 1795, horse_riding = TRUE, wine_cap = 1000),
  S6_baseline_base1795     = pipeline(guess, base_year = 1795))
res <- bind_rows(Map(summ, sc_list, names(sc_list)))
print(as.data.frame(res))
write_csv(res, file.path(out, "scenario_summary.csv"))
for (s in names(sc_list)) { write_csv(sc_list[[s]]$idx, file.path(out, paste0("fig5_index_", s, ".csv")))
                            write_csv(sc_list[[s]]$g,   file.path(out, paste0("fig6_gini_", s, ".csv"))) }

# Validation against the S2 run
o5 <- read_csv("P30_STB24/repro_original/output/fig5_mean_values.csv", show_col_types = FALSE)
o6 <- read_csv("P30_STB24/repro_original/output/fig6_gini_values.csv", show_col_types = FALSE)
b <- sc_list$S0_baseline_as_run
cat("max |diff| baseline vs S2 means:", max(abs(as.matrix(b$m[, ..assets]) - as.matrix(o5[, assets])), na.rm = TRUE),
    " ginis:", max(abs(as.matrix(b$g[, ..assets]) - as.matrix(o6[, assets])), na.rm = TRUE), "\n")

# Eighteenth-century trend (claim p.440): log-index change 1702-1795 per asset, per scenario
tr <- bind_rows(lapply(names(sc_list), function(s) { m <- sc_list[[s]]$m
  bind_rows(lapply(assets, function(v) tibble(scenario = s, asset = v,
    mean_1700s_first = mean(m[year >= 1700 & year <= 1720][[v]], na.rm = TRUE),
    mean_1780_1795 = mean(m[year >= 1780 & year <= 1795][[v]], na.rm = TRUE)))) })) |>
  mutate(ratio_late_early = mean_1780_1795 / mean_1700s_first)
write_csv(tr, file.path(out, "c18_trend.csv"))
print(as.data.frame(filter(tr, scenario %in% c("S0_baseline_as_run", "S1_types_fixed", "S5_all_fixes_base1795"))))
