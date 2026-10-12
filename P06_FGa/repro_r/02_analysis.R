# P06_FGa S3 recreation -- 02_analysis.R
# Table 1, Tables A1-A2, text numbers, results_r.csv. See decisions.md (D3, D8, D11-D18).
suppressPackageStartupMessages({ library(tidyverse); library(kableExtra) })
PROJ <- "."
source(file.path(PROJ, "tools", "paths.R"))
PAPER <- "P06_FGa"
RR  <- file.path(PROJ, PAPER, "repro_r"); OUT <- file.path(RR, "output")
SCR <- dscratch(PAPER, "repro_r")
hh <- readRDS(file.path(SCR, "households.rds"))
prices <- readRDS(file.path(SCR, "prices.rds"))
R <- 0.06

gini <- function(x) { x <- sort(x[!is.na(x)]); n <- length(x); s <- sum(x)
  if (n == 0 || s == 0) return(NA_real_); sum((2 * seq_len(n) - n - 1) * x) / (n * s) }
did <- function(d) str_remove_all(d, "[^A-Za-z]")

value_hh <- function(hh, spec) {
  P <- prices %>% filter(spec == !!spec)
  p <- function(ct, it) { v <- P$price[P$country == ct & P$item == it]; if (length(v) == 0) 0 else v }
  hh %>% mutate(
    pw = ifelse(country == "Cape Colony", p("Cape Colony", "wheat"),  p("United States", "wheat")),
    pb = ifelse(country == "Cape Colony", p("Cape Colony", "barley"), p("United States", "barley")),
    pr = ifelse(country == "Cape Colony", p("Cape Colony", "rye"),    p("United States", "rye")),
    po = ifelse(country == "Cape Colony", p("Cape Colony", "oats"),   p("United States", "oats")),
    pc = ifelse(country == "Cape Colony", 0,                          p("United States", "corn")),
    crop_val = wheat * pw + barley * pb + rye * pr + oats * po + corn * pc,
    wine_val = wine * p("Cape Colony", "wine") + brandy * p("Cape Colony", "brandy"),
    cropwine_val = crop_val + wine_val,
    live_val = ifelse(country == "Cape Colony",
                      cattle * p("Cape Colony", "cattle") + sheep * p("Cape Colony", "sheep"),
                      cattle * p("United States", "cattle") + sheep * p("United States", "sheep")),
    live_val_cons = ifelse(country == "Cape Colony",
                      cattle * p("Cape Colony", "cattle_cons") + sheep * p("Cape Colony", "sheep_cons"), live_val),
    live_inc = R * live_val, live_inc_cons = R * live_val_cons,
    income = crop_val + live_inc, income_cons = crop_val + live_inc_cons,
    income_cons_wine = cropwine_val + live_inc_cons,
    ens_val = ifelse(country == "Cape Colony", slaves * p("Cape Colony", "slaves"),
                     slaves16 * p("United States", "slaves16") + slaves_u16 * p("United States", "slaves_u16")),
    ens_val_cons = ifelse(country == "Cape Colony", slaves * p("Cape Colony", "slaves_cons"), ens_val),
    ens_inc = R * ens_val, ens_inc_cons = R * ens_val_cons)
}

run_spec <- function(spec) {
  v <- value_hh(hh, spec); f <- filter(v, farmer)
  # ---- Table 1
  t1 <- f %>% group_by(country, district) %>% summarise(
    obs = n(),
    crops = ifelse(first(crops_recorded), gini(crop_val), NA),
    cropswine = ifelse(first(crops_recorded), gini(cropwine_val), NA),
    livestock = gini(live_val),
    enslaved = ifelse(district[1] %in% c("Maine", "Massachusetts"), NA, gini(slaves)), .groups = "drop")
  # ---- Table A1
  a1 <- f %>% group_by(country, district) %>% summarise(obs = n(),
    across(c(wheat, barley, rye, oats, corn, wine, horses, cattle, sheep, crops_bu), mean), .groups = "drop")
  # ---- Table A2 (all households)
  a2 <- v %>% group_by(country, district, year) %>%
    summarise(obs = n(), mean = mean(slaves), max = max(slaves), own_share = 100 * mean(slaves > 0), .groups = "drop")
  # ---- text numbers
  cape_f <- filter(f, country == "Cape Colony"); nema <- filter(f, district %in% c("Maine", "Massachusetts"))
  dm <- function(var, d) mean(f[[var]][f$district == d])
  owners <- filter(v, slaves > 0)
  tx <- tribble(~claim_id, ~value, ~n,
    "tx_p12_obs", nrow(f), nrow(f),
    "tx_p13_cattle_cape", mean(cape_f$cattle), nrow(cape_f),
    "tx_p13_cattle_us", mean(f$cattle[f$country == "United States"]), sum(f$country == "United States"),
    "tx_p13_cattle_us_owners", mean(f$cattle[f$country == "United States" & f$cattle > 0]), sum(f$country == "United States" & f$cattle > 0),
    "tx_p14_share_mass", 100 * mean(v$farmer[v$district == "Massachusetts"]), sum(v$district == "Massachusetts"),
    "tx_p14_share_gr", 100 * mean(v$farmer[v$district == "Graaff-Reinet"]), sum(v$district == "Graaff-Reinet"),
    "tx_p14_share_stel", 100 * mean(v$farmer[v$district == "Stellenbosch"]), sum(v$district == "Stellenbosch"),
    "tx_p16_cropval_mass", dm("crop_val", "Massachusetts"), NA,
    "tx_p16_cropval_tulb", dm("crop_val", "Tulbagh"), NA,
    "tx_p16_cropval_stel", dm("crop_val", "Stellenbosch"), NA,
    "tx_p16_cropval_maine", dm("crop_val", "Maine"), NA,
    "tx_p16_cropval_gr", dm("crop_val", "Graaff-Reinet"), NA,
    "tx_p16_cropval_cape", mean(cape_f$crop_val), nrow(cape_f),
    "tx_p16_cropval_us", mean(nema$crop_val), nrow(nema),
    "tx_p16_cropwine_stel", dm("cropwine_val", "Stellenbosch"), NA,
    "tx_p16_cropwine_tulb", dm("cropwine_val", "Tulbagh"), NA,
    "tx_p16_cropwine_us", mean(nema$cropwine_val), nrow(nema),
    "tx_p16_cropwine_cape", mean(cape_f$cropwine_val), nrow(cape_f),
    "tx_p16_livinc_gr", dm("live_inc", "Graaff-Reinet"), NA,
    "tx_p16_livinc_maine", dm("live_inc", "Maine"), NA,
    "tx_p16_livinc_mass", dm("live_inc", "Massachusetts"), NA,
    "tx_p16_income_cape", mean(cape_f$income), nrow(cape_f),
    "tx_p16_income_us", mean(nema$income), nrow(nema),
    "tx_p17_income_cape_cons", mean(cape_f$income_cons), nrow(cape_f),
    "tx_p17_income_us_cons", mean(nema$income_cons), nrow(nema),
    "tx_p17_income_cape_cons_wine", mean(cape_f$income_cons_wine), nrow(cape_f),
    "tx_p17_ensinc_stel_med", median(owners$ens_inc_cons[owners$district == "Stellenbosch"]), sum(owners$district == "Stellenbosch"),
    "tx_p17_ensinc_va_med", median(owners$ens_inc[owners$district == "Virginia"]), sum(owners$district == "Virginia"),
    "tx_p17_ensinc_va_mean", mean(owners$ens_inc[owners$district == "Virginia"]), sum(owners$district == "Virginia"),
    "tx_p17_ensinc_stel_mean", mean(owners$ens_inc_cons[owners$district == "Stellenbosch"]), sum(owners$district == "Stellenbosch"))
  # alternatives (not claims)
  alt <- tribble(~quantity, ~value,
    "cattle mean, all Cape households", mean(v$cattle[v$country == "Cape Colony"]),
    "cattle mean, all US households", mean(v$cattle[v$country == "United States"]),
    "cattle mean, US households with cattle>0", mean(v$cattle[v$country == "United States" & v$cattle > 0]),
    "US crop value per farmer incl. Virginia farmers as zero", sum(nema$crop_val) / sum(f$country == "United States"),
    "Stellenbosch fig7 income median, baseline Cape price", median(owners$ens_inc[owners$district == "Stellenbosch"]),
    "Stellenbosch fig7 income mean, baseline Cape price", mean(owners$ens_inc[owners$district == "Stellenbosch"]))
  list(v = v, t1 = t1, a1 = a1, a2 = a2, tx = tx, alt = alt)
}

res <- map(c(P1 = "P1", P2 = "P2", P3 = "P3"), run_spec)
m <- res$P1

# ---------------------------------------------------------------- outputs
write_csv(m$t1, file.path(OUT, "table1_gini.csv"))
write_csv(m$a1, file.path(OUT, "tableA1.csv"))
write_csv(m$a2, file.path(OUT, "tableA2.csv"))
write_csv(bind_rows(m$tx %>% mutate(quantity = claim_id), m$alt) %>% select(quantity, value, n),
          file.path(OUT, "text_numbers.csv"))
sens <- imap_dfr(res, function(r, s) bind_rows(
  r$tx %>% select(claim_id, value),
  r$t1 %>% pivot_longer(c(crops, cropswine, livestock), names_to = "k") %>%
    transmute(claim_id = paste0("T1_", did(district), "_", k), value)) %>% mutate(spec = s)) %>%
  pivot_wider(names_from = spec, values_from = value)
write_csv(sens, file.path(OUT, "sensitivity_price_specs.csv"))

fmt <- function(d, cap, file) {
  d %>% mutate(across(where(is.numeric), ~ round(.x, 2))) %>%
    kbl(format = "latex", booktabs = TRUE, caption = cap) %>% save_kable(file.path(OUT, file))
}
fmt(m$t1 %>% select(-country), "Gini coefficients by type of ownership (S3 recreation, farmers, pooled years)", "table1_gini.tex")
fmt(m$a1, "Agricultural output per producer by district, years pooled (S3 recreation)", "tableA1.tex")
fmt(m$a2, "Ownership of enslaved people per household by district and year (S3 recreation)", "tableA2.tex")

# ---------------------------------------------------------------- results_r.csv
rows <- list()
add <- function(id, value, n = NA, status = "") rows[[length(rows) + 1]] <<- tibble(claim_id = id, source = "r", value = value, se = NA_real_, n = n, status_override = status)
for (i in seq_len(nrow(m$t1))) { r <- m$t1[i, ]; d <- did(r$district)
  add(paste0("T1_", d, "_obs"), r$obs, r$obs)
  for (k in c("crops", "cropswine", "livestock", "enslaved")) if (!is.na(r[[k]])) add(paste0("T1_", d, "_", k), r[[k]], r$obs) }
a1map <- c(wheat = "wheat", barley = "barley", rye = "rye", oats = "oats", corn = "corn", wine = "wine",
           horses = "horses", cattle = "cattle", sheep = "sheep", crops = "crops_bu")
for (i in seq_len(nrow(m$a1))) { r <- m$a1[i, ]; d <- did(r$district)
  add(paste0("A1_", d, "_obs"), r$obs, r$obs)
  for (k in names(a1map)) add(paste0("A1_", d, "_", k), r[[a1map[k]]], r$obs) }
for (i in seq_len(nrow(m$a2))) { r <- m$a2[i, ]; d <- paste0("A2_", did(r$district), "_", r$year)
  add(paste0(d, "_obs"), r$obs, r$obs); add(paste0(d, "_mean"), r$mean, r$obs); add(paste0(d, "_max"), r$max, r$obs) }
for (i in seq_len(nrow(m$tx))) add(m$tx$claim_id[i], m$tx$value[i], m$tx$n[i])
a1 <- m$a1; a2 <- m$a2
g <- function(d, k) a1[[k]][a1$district == d]
for (k in c("wheat", "barley", "rye", "oats")) add(paste0("tx_p14_stel_", k), g("Stellenbosch", k))
add("tx_p14_stel_total", g("Stellenbosch", "crops_bu"))
for (k in c("wheat", "barley", "rye", "oats", "corn")) { add(paste0("tx_p15_mass_", k), g("Massachusetts", k)); add(paste0("tx_p15_maine_", k), g("Maine", k)) }
add("tx_p15_mass_total", g("Massachusetts", "crops_bu")); add("tx_p15_maine_total", g("Maine", "crops_bu"))
e <- function(d, y, k) a2[[k]][a2$district == d & a2$year == y]
add("tx_p17_ens_stel_1785", e("Stellenbosch", 1785, "mean")); add("tx_p17_ens_stel_1795", e("Stellenbosch", 1795, "mean"))
add("tx_p17_ens_stel_1805", e("Stellenbosch", 1805, "mean")); add("tx_p17_ens_va_1785", e("Virginia", 1785, "mean"))
add("tx_p17_ens_va_1795", e("Virginia", 1795, "mean")); add("tx_p17_ens_va_1805", e("Virginia", 1805, "mean"))
add("tx_p17_own_stel_1785", e("Stellenbosch", 1785, "own_share")); add("tx_p17_own_stel_1805", e("Stellenbosch", 1805, "own_share"))
add("tx_p17_own_va_1785", e("Virginia", 1785, "own_share")); add("tx_p17_own_va_1815", e("Virginia", 1815, "own_share"))
t1 <- m$t1
add("tx_p19_gini_live_gr", t1$livestock[t1$district == "Graaff-Reinet"])
add("tx_p19_gini_live_approx", mean(t1$livestock))
add("tx_p19_gini_ens_stel", t1$enslaved[t1$district == "Stellenbosch"])
add("tx_p19_gini_ens_va", t1$enslaved[t1$district == "Virginia"])
# prices
cauc <- read_csv(file.path(OUT, "cape_auction_prices.csv"), show_col_types = FALSE)
cp <- function(k) cauc$price_usd[cauc$cat == k]
add("tx_p16_cape_horse_base", cp("horses")); add("tx_p16_cape_cattle_base", cp("cattle")); add("tx_p16_cape_sheep_base", cp("sheep"))
add("tx_p16_xrate", 5 / 4.53)
for (id in c("tx_p15_price_horse_us", "tx_p15_price_cattle_us", "tx_p15_price_sheep_us",
             "tx_p15_price_enslaved_16plus", "tx_p15_price_enslaved_12_16", "tx_p16_interest")) {
  val <- c(tx_p15_price_horse_us = 94.93, tx_p15_price_cattle_us = 16.32, tx_p15_price_sheep_us = 3.11,
           tx_p15_price_enslaved_16plus = 178.51, tx_p15_price_enslaved_12_16 = 162.95, tx_p16_interest = 6)[id]
  add(id, unname(val), NA, "input") }
for (id in c("tx_p16_cape_horse_alt", "tx_p16_cape_cattle_alt", "tx_p16_cape_sheep_alt"))
  add(id, c(tx_p16_cape_horse_alt = 20.24, tx_p16_cape_cattle_alt = 9.37, tx_p16_cape_sheep_alt = 1.18)[[id]], NA, "input")
for (id in c("tx_p15_price_cattle_rothenberg", "tx_p15_appraisals_n", "tx_p20_va_sample", "tx_p21_pop_us", "tx_p21_pop_cape"))
  add(id, NA_real_, NA, "not_assessed")
# figure medians
fv <- filter(m$v, farmer)
f5 <- fv %>% filter(cattle > 0) %>% group_by(district) %>% summarise(n = n(), median = median(cattle), mean = mean(cattle))
write_csv(f5, file.path(OUT, "fig5_medians.csv"))
for (i in seq_len(nrow(f5))) add(paste0("F5_", did(f5$district[i]), "_median"), f5$median[i], f5$n[i])
f6 <- fv %>% filter(district != "Virginia") %>%
  pivot_longer(c(crop_val, cropwine_val), names_to = "measure") %>% filter(value > 0) %>%
  group_by(country, measure) %>% summarise(n = n(), median = median(value), mean = mean(value), .groups = "drop") %>%
  mutate(claim_id = paste0("F6_", ifelse(measure == "crop_val", "crops", "cropswine"), "_",
                           ifelse(country == "Cape Colony", "cape", "us"), "_median"))
write_csv(f6, file.path(OUT, "fig6_medians.csv"))
for (i in seq_len(nrow(f6))) add(f6$claim_id[i], f6$median[i], f6$n[i])

# ---------------------------------------------------------------- post-hoc diagnostics (decisions.md D21; NOT in results_r.csv)
pp <- function(x) if (any(x > 0)) mean(x[x > 0]) else NA_real_
diag_a1 <- fv %>% group_by(district) %>%
  summarise(across(c(wheat, barley, rye, oats, corn, wine, horses, cattle, sheep, crops_bu), pp), .groups = "drop")
write_csv(diag_a1, file.path(OUT, "diag_A1_per_commodity_producer.csv"))
Pus <- prices %>% filter(spec == "P1", country == "United States")
pu <- setNames(Pus$price, Pus$item)
diag_cv <- fv %>% filter(district != "Virginia") %>%
  mutate(crop_val_usp = wheat * pu["wheat"] + barley * pu["barley"] + rye * pu["rye"] + oats * pu["oats"] + corn * pu["corn"]) %>%
  group_by(district) %>%
  summarise(per_farmer = mean(crop_val), per_crop_producer = pp(crop_val),
            cape_at_US_prices_per_farmer = mean(crop_val_usp), cape_at_US_prices_per_crop_producer = pp(crop_val_usp),
            n_crop_producers = sum(crop_val > 0), .groups = "drop")
write_csv(diag_cv, file.path(OUT, "diag_crop_value_definitions.csv"))

results <- bind_rows(rows) %>% mutate(value = signif(value, 8))
stopifnot(!any(duplicated(results$claim_id)))
write_csv(results, file.path(RR, "results_r.csv"), na = "")
cat("results_r.csv rows:", nrow(results), "\n")
print(m$t1, width = 200); print(m$tx, n = 40)
