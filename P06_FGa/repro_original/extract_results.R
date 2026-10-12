# Map objects produced by the patched original code (saved by run_original.R) to claim_ids.
# Writes P06_FGa/repro_original/results_original.csv. Run from the project root.
suppressPackageStartupMessages({library(data.table); library(dplyr); library(readr); library(ggplot2); library(ggpubr)})
source("tools/paths.R")
o <- readRDS(dscratch("P06_FGa", "repro_original", "objects.rds"))
claims <- read_csv("P06_FGa/claims/claims.csv", show_col_types = FALSE)

df  <- function(x) as.data.frame(x)
get <- function(tab, key, keyval, col) { t <- df(tab); v <- t[[col]][t[[key]] == keyval]; if (length(v) != 1) NA_real_ else v }
dist_code <- c(GraaffReinet = "Graaff Reinet", Stellenbosch = "Stellenbosch", Swellendam = "Swellendam",
               Tulbagh = "Tulbagh", Maine = "Maine", Massachusetts = "Massachusetts", Virginia = "Virginia")
res <- list(); add <- function(id, v, n = NA_real_, ovr = NA_character_) res[[length(res) + 1]] <<- tibble(claim_id = id, value = v, n = n, status_override = ovr)

# ---- Table 1: gini1 (livestock value Gini, enslaved Gini, obs) and gini2 (crop-value Ginis) ----
for (k in names(dist_code)) {
  d <- dist_code[[k]]; n <- get(o$gini1, "District", d, "obs")
  add(paste0("T1_", k, "_obs"), n, n)
  add(paste0("T1_", k, "_livestock"), get(o$gini1, "District", d, "Agric"), n)
  add(paste0("T1_", k, "_enslaved"), get(o$gini1, "District", d, "Slaves"), n)
  add(paste0("T1_", k, "_crops"), get(o$gini2, "District", d, "Crops_V"), n)
  add(paste0("T1_", k, "_cropswine"), get(o$gini2, "District", d, "CropsW_V"), n)
}

# ---- Table A1: grains and wine from desall (district, farmer filter, pooled);
#      horses/cattle/sheep/crop bushels have no pooled object: obs-weighted pooling of `descriptives`
#      (same filter, by District x Year). ----
pool <- df(o$descriptives) |> group_by(District) |>
  summarise(across(c(Horses, Cattle, Sheep, Crops), ~ weighted.mean(.x, obs, na.rm = TRUE)), .groups = "drop")
for (k in names(dist_code)) {
  d <- dist_code[[k]]; n <- get(o$desall, "District", d, "obs")
  add(paste0("A1_", k, "_obs"), n, n)
  for (v in c("Wheat", "Barley", "Rye", "Oats", "Corn", "Wine")) add(paste0("A1_", k, "_", tolower(v)), get(o$desall, "District", d, v), n)
  for (v in c("Horses", "Cattle", "Sheep", "Crops")) add(paste0("A1_", k, "_", tolower(v)), get(pool, "District", d, v), n)
}

# ---- Table A2: slavesdes (all households, District x Year) ----
sd <- df(o$slavesdes)
for (k in names(dist_code)) for (y in c(1785, 1795, 1805, 1815)) {
  r <- sd[sd$District == dist_code[[k]] & sd$Year == y, ]
  if (nrow(r) == 1) {
    add(sprintf("A2_%s_%d_obs", k, y), r$Obs, r$Obs)
    add(sprintf("A2_%s_%d_mean", k, y), r$Average, r$Obs)
    add(sprintf("A2_%s_%d_max", k, y), r$Max, r$Obs)
  }
}

# ---- Text ----
add("tx_p12_obs", sum(df(o$gini1)$obs))
add("tx_p13_cattle_cape", get(o$cattletot, "Country", "Cape Colony", "Average"))
add("tx_p13_cattle_us", get(o$cattletot, "Country", "United States", "Average"))
add("tx_p13_cattle_us_owners", NA, ovr = "unavailable")
allobs <- df(o$sample) |> group_by(District) |> summarise(all = sum(Obs))
share <- function(d) 100 * get(o$gini1, "District", d, "obs") / get(allobs, "District", d, "all")
add("tx_p14_share_mass", share("Massachusetts")); add("tx_p14_share_gr", share("Graaff Reinet")); add("tx_p14_share_stel", share("Stellenbosch"))
for (v in c("wheat", "barley", "rye", "oats")) add(paste0("tx_p14_stel_", v), get(o$desall, "District", "Stellenbosch", tools::toTitleCase(v)))
add("tx_p14_stel_total", get(pool, "District", "Stellenbosch", "Crops"))
for (st in c("mass", "maine")) {
  d <- if (st == "mass") "Massachusetts" else "Maine"
  add(paste0("tx_p15_", st, "_total"), get(pool, "District", d, "Crops"))
  for (v in c("wheat", "barley", "rye", "oats", "corn")) add(paste0("tx_p15_", st, "_", v), get(o$desall, "District", d, tools::toTitleCase(v)))
}
pr <- df(o$fgprices); pr2 <- df(o$fgprices2)
gp <- function(p, c, col) p[[col]][p$Country == c]
add("tx_p15_price_horse_us", gp(pr, "United States", "PHorses"))
add("tx_p15_price_cattle_us", gp(pr, "United States", "PCattle"))
add("tx_p15_price_sheep_us", gp(pr, "United States", "PSheep"))
add("tx_p15_price_cattle_rothenberg", NA, ovr = "unavailable")
add("tx_p15_price_enslaved_16plus", gp(pr, "United States", "PSlaves"))
add("tx_p15_price_enslaved_12_16", NA, ovr = "unavailable")
add("tx_p15_appraisals_n", NA, ovr = "unavailable")
add("tx_p16_xrate", NA, ovr = "unavailable")
for (k in c(mass = "Massachusetts", tulb = "Tulbagh", stel = "Stellenbosch", maine = "Maine", gr = "Graaff Reinet")) NULL
cv <- c(mass = "Massachusetts", tulb = "Tulbagh", stel = "Stellenbosch", maine = "Maine", gr = "Graaff Reinet")
for (k in names(cv)) add(paste0("tx_p16_cropval_", k), get(o$desall, "District", cv[[k]], "Crops_V"), get(o$desall, "District", cv[[k]], "obs"))
add("tx_p16_cropval_cape", get(o$desall3, "Country", "Cape Colony", "Crops_V"), get(o$desall3, "Country", "Cape Colony", "obs"))
add("tx_p16_cropval_us", get(o$desall3, "Country", "United States", "Crops_V"), get(o$desall3, "Country", "United States", "obs"))
add("tx_p16_cropwine_stel", get(o$desall, "District", "Stellenbosch", "CropsW_V"))
add("tx_p16_cropwine_tulb", get(o$desall, "District", "Tulbagh", "CropsW_V"))
add("tx_p16_cropwine_us", get(o$desall3, "Country", "United States", "CropsW_V"))
add("tx_p16_cropwine_cape", get(o$desall3, "Country", "Cape Colony", "CropsW_V"))
add("tx_p16_interest", 6)  # hard-coded multiplier 0.06 (FG Replication Code.txt l.186-190)
add("tx_p16_livinc_gr", get(o$desall, "District", "Graaff Reinet", "Stock"))
add("tx_p16_livinc_maine", get(o$desall, "District", "Maine", "Stock"))
add("tx_p16_livinc_mass", get(o$desall, "District", "Massachusetts", "Stock"))
add("tx_p16_income_cape", get(o$desall3, "Country", "Cape Colony", "Agric"), get(o$desall3, "Country", "Cape Colony", "obs"))
add("tx_p16_income_us", get(o$desall3, "Country", "United States", "Agric"), get(o$desall3, "Country", "United States", "obs"))
add("tx_p16_cape_horse_alt", gp(pr2, "Cape Colony", "PHorses")); add("tx_p16_cape_horse_base", gp(pr, "Cape Colony", "PHorses"))
add("tx_p16_cape_cattle_alt", gp(pr2, "Cape Colony", "PCattle")); add("tx_p16_cape_cattle_base", gp(pr, "Cape Colony", "PCattle"))
add("tx_p16_cape_sheep_alt", gp(pr2, "Cape Colony", "PSheep")); add("tx_p16_cape_sheep_base", gp(pr, "Cape Colony", "PSheep"))
add("tx_p17_income_cape_cons", get(o$desall4, "Country", "Cape Colony", "Agric"))
add("tx_p17_income_us_cons", get(o$desall4, "Country", "United States", "Agric"))
add("tx_p17_income_cape_cons_wine", get(o$desall4, "Country", "Cape Colony", "AgricW"))
ens <- function(d, y) sd$Average[sd$District == d & sd$Year == y]
add("tx_p17_ens_stel_1785", ens("Stellenbosch", 1785)); add("tx_p17_ens_va_1785", ens("Virginia", 1785))
add("tx_p17_ens_stel_1795", ens("Stellenbosch", 1795)); add("tx_p17_ens_stel_1805", ens("Stellenbosch", 1805))
add("tx_p17_ens_va_1795", ens("Virginia", 1795)); add("tx_p17_ens_va_1805", ens("Virginia", 1805))
for (id in c("tx_p17_own_stel_1785", "tx_p17_own_stel_1805", "tx_p17_own_va_1785", "tx_p17_own_va_1815")) add(id, NA, ovr = "unavailable")
add("tx_p17_ensinc_stel_med", get(o$desslaves2, "District", "Stellenbosch", "SlavesmV"))
add("tx_p17_ensinc_va_med", get(o$desslaves2, "District", "Virginia", "SlavesmV"))
add("tx_p17_ensinc_va_mean", get(o$desslaves2, "District", "Virginia", "SlavesV"))
add("tx_p17_ensinc_stel_mean", get(o$desslaves2, "District", "Stellenbosch", "SlavesV"))
add("tx_p19_gini_live_gr", get(o$gini1, "District", "Graaff Reinet", "Agric"))
add("tx_p19_gini_live_approx", mean(df(o$gini1)$Agric))
add("tx_p19_gini_ens_stel", get(o$gini1, "District", "Stellenbosch", "Slaves"))
add("tx_p19_gini_ens_va", get(o$gini1, "District", "Virginia", "Slaves"))
for (id in c("tx_p20_va_sample", "tx_p21_pop_us", "tx_p21_pop_cape")) add(id, NA, ovr = "unavailable")

# ---- Figures: medians from ggplot_build of the code's own plot objects (log10 scale -> back-transformed) ----
med <- function(p) { ld <- layer_data(p, 2); x <- p$data[[rlang::as_name(p$mapping$x)]]; setNames(10^ld$middle, levels(factor(x))) }
m5 <- med(o$fig5); for (k in names(dist_code)) add(paste0("F5_", k, "_median"), m5[[dist_code[[k]]]])
ma <- med(o$a); mb <- med(o$b)
add("F6_crops_cape_median", ma[["Cape Colony"]]); add("F6_crops_us_median", ma[["United States"]])
add("F6_cropswine_cape_median", mb[["Cape Colony"]]); add("F6_cropswine_us_median", mb[["United States"]])

out <- bind_rows(res) |> mutate(source = "original", se = NA_real_, value = ifelse(is.nan(value), NA, value)) |>
  select(claim_id, source, value, se, n, status_override)
missing <- setdiff(claims$claim_id, out$claim_id); extra <- setdiff(out$claim_id, claims$claim_id)
if (length(missing)) { cat("No mapping for:", missing, "\n"); out <- bind_rows(out, tibble(claim_id = missing, source = "original", value = NA, se = NA, n = NA, status_override = "unavailable")) }
out <- out |> filter(claim_id %in% claims$claim_id)
cat("Extra (dropped):", extra, "\n")
out <- out[match(claims$claim_id, out$claim_id), ]
write_csv(out, "P06_FGa/repro_original/results_original.csv", na = "")
cat("Wrote", nrow(out), "rows\n")
