# P30_STB24 — S3 independent recreation, step 2: analysis
# Builds the aggregate series behind Figures 2-7 and the text counts, and writes results_r.csv.
# Input : households.rds (D: scratch, from 01_clean.R)
# Output: aggregate CSVs in repro_r/output/, repro_r/results_r.csv

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
  library(ineq)
  library(zoo)
})
here::i_am("P30_STB24/repro_r/02_analysis.R")
source(here("tools", "paths.R"))
set.seed(20261011)

PAPER <- "P30_STB24"
OUT   <- here(PAPER, "repro_r", "output")
hh    <- readRDS(dscratch(PAPER, "repro_r", "households.rds"))
cmap  <- read_csv(file.path(OUT, "column_map.csv"), show_col_types = FALSE)

ASSETS <- c("horses", "sheep", "cattle", "wheat", "barley", "wine")
BASE   <- 1795L

# ---- helpers ----------------------------------------------------------------
# value at a target year: the census value if it exists, else linear interpolation
# between the adjacent censuses (the paper's figures are line plots over census years)
at_year <- function(df, yr, col) {
  d <- df |> filter(!is.na(.data[[col]])) |> arrange(year)
  if (yr %in% d$year) return(d[[col]][d$year == yr])
  lo <- max(d$year[d$year < yr]); hi <- min(d$year[d$year > yr])
  approx(c(lo, hi), d[[col]][d$year %in% c(lo, hi)], xout = yr)$y
}

# ---- 1. counts ----------------------------------------------------------------
n_rows     <- nrow(hh)
n_censuses <- n_distinct(hh$year)
span_years <- max(hh$year) - min(hh$year)
nobs <- hh |> count(year, name = "n_obs")

# ---- 2. Figure 5: per-household mean index, base 1795 = 1 --------------------
means <- hh |>
  group_by(year) |>
  summarise(across(all_of(ASSETS), ~ if (all(is.na(.x))) NA_real_ else mean(.x, na.rm = TRUE)),
            .groups = "drop")
base  <- means |> filter(year == BASE)
index <- means |> mutate(across(all_of(ASSETS), ~ .x / base[[cur_column()]]))
# sensitivity: drop implausible wine entries (> 1000 leaguers; vine counts entered in the wine column)
means_s <- hh |> mutate(wine = if_else(wine > 1000, NA_real_, wine)) |>
  group_by(year) |> summarise(wine = mean(wine, na.rm = TRUE), .groups = "drop") |>
  mutate(wine = ifelse(is.nan(wine), NA, wine))
index_s <- means_s |> mutate(wine_trim = wine / wine[year == BASE]) |> select(year, wine_trim)
fig5 <- nobs |> left_join(index, by = "year") |> left_join(index_s, by = "year")
write_csv(fig5, file.path(OUT, "fig5_index.csv"))
write_csv(means, file.path(OUT, "fig5_means_levels.csv"))

# ---- 3. Figure 6: annual Gini per asset ---------------------------------------
gini_tab <- function(d, drop_zero = FALSE) {
  d |> select(year, all_of(ASSETS)) |>
    pivot_longer(-year, names_to = "asset") |>
    filter(!is.na(value), value >= 0) |>
    filter(!drop_zero | value > 0) |>
    group_by(year, asset) |>
    summarise(n = n(), gini = if (sum(value) > 0 && n() > 1) ineq::Gini(value) else NA_real_,
              .groups = "drop")
}
g_all <- gini_tab(hh)                       # primary: zeros included (missing-data rule)
g_pos <- gini_tab(hh, drop_zero = TRUE)     # sensitivity: owners/producers only
fig6 <- g_all |> select(year, asset, gini) |>
  left_join(g_pos |> select(year, asset, gini_pos = gini, n_pos = n), by = c("year", "asset"))
write_csv(fig6, file.path(OUT, "fig6_gini.csv"))

g_w <- g_all |> select(year, asset, gini) |> pivot_wider(names_from = asset, values_from = gini)
pooled <- g_all |> filter(!is.na(gini)) |> pull(gini)
gini_p10  <- unname(quantile(pooled, 0.10))
gini_max  <- max(pooled)
share_in  <- mean(pooled >= 0.4 & pooled <= 1)
by_asset  <- g_all |> group_by(asset) |> summarise(mean_gini = mean(gini, na.rm = TRUE),
  share_ge_04 = mean(gini >= 0.4, na.rm = TRUE), min = min(gini, na.rm = TRUE), .groups = "drop")
write_csv(by_asset, file.path(OUT, "gini_by_asset_summary.csv"))
# trend: OLS slope of Gini on year per asset (conventional and HC1 SEs; descriptive only)
trend <- g_all |> filter(!is.na(gini)) |> group_by(asset) |>
  group_modify(~ {
    m <- lm(gini ~ I((year - 1700) / 100), data = .x)
    tibble(slope_per_century = coef(m)[2],
           se_conv = sqrt(diag(vcov(m)))[2],
           se_hc1  = sqrt(diag(sandwich::vcovHC(m, type = "HC1")))[2],
           n = nobs(m))
  }) |> ungroup()
write_csv(trend, file.path(OUT, "gini_trend.csv"))

# wine Gini turning point: peak of the centred 11-census rolling mean
wg <- g_all |> filter(asset == "wine", !is.na(gini)) |> arrange(year) |>
  mutate(roll = zoo::rollmean(gini, 11, fill = NA, align = "center"))
wine_peak_year <- wg$year[which.max(wg$roll)]
wine_peak_dec  <- floor(wine_peak_year / 10) * 10

# ---- 4. Figure 2: coverage of harmonised variables, structural break ----------
vars <- setdiff(names(hh), c("row", "year", "nr", "name_men", "name_women", "hh_id"))
cover <- hh |> group_by(year) |>
  summarise(across(all_of(vars), ~ sum(!is.na(.x) & .x != 0)), .groups = "drop") |>
  pivot_longer(-year, names_to = "variable", values_to = "count")
write_csv(cover, file.path(OUT, "fig2_coverage.csv"))
recset <- hh |> group_by(year) |> summarise(across(all_of(vars), ~ any(!is.na(.x))), .groups = "drop")
# raw-column structure: number of distinct mapped variables plus raw column labels entering/leaving
rawlab <- cmap |> filter(is.na(name_col)) |> group_by(year) |> summarise(labs = list(unique(L)), .groups = "drop")
chg <- tibble(year = recset$year[-1],
              harmonised_change = map_int(2:nrow(recset), ~ sum(unlist(recset[.x, vars]) != unlist(recset[.x - 1, vars]))))
write_csv(chg, file.path(OUT, "fig2_structure_change.csv"))
break_year <- chg$year[which.max(chg$harmonised_change)]

# ---- 5. Figure 3: surnames ------------------------------------------------------
surname_of <- function(x) {
  x <- str_squish(str_remove_all(coalesce(x, ""), "\\(.*?\\)|\\[.*?\\]|\\?"))
  x <- str_remove(x, ";.*$")
  out <- if_else(str_detect(x, ","), str_trim(str_remove(x, ",.*$")), NA_character_)
  nocomma <- !str_detect(x, ",") & x != ""
  tok <- str_split(x[nocomma], " ")
  out[nocomma] <- map_chr(tok, function(t) {
    t <- t[t != ""]; if (!length(t)) return(NA_character_)
    k <- length(t)
    while (k > 1 && tolower(t[k - 1]) %in% c("de", "du", "le", "la", "van", "der", "den", "von", "v.d.", "vd")) k <- k - 1
    paste(t[k:length(t)], collapse = " ")
  })
  out[out == ""] <- NA
  out
}
keyify <- function(s) str_remove_all(tolower(s), "[^a-z]")

TOP12 <- c("De Villiers", "Du Plessis", "Du Toit", "Joubert", "Le Roux", "Louw", "Marais",
           "Rossouw", "Roux", "Smit", "Swart", "Van der Merwe")
sn <- hh |>
  mutate(name_hh = if_else(!is.na(name_men) & name_men != "", name_men, name_women),
         surname = surname_of(name_hh), key = keyify(surname),
         decade = floor(year / 10) * 10) |>
  filter(year >= 1700, year <= 1839, !is.na(key), key != "")
tot <- sn |> count(decade, name = "n_named")
top12_keys <- keyify(TOP12)
fig3 <- sn |> filter(key %in% top12_keys) |> count(decade, key) |>
  complete(decade = sort(unique(sn$decade)), key = top12_keys, fill = list(n = 0)) |>
  left_join(tot, by = "decade") |>
  group_by(decade) |> mutate(share_all = 100 * n / n_named, share_top12 = 100 * n / sum(n)) |> ungroup() |>
  mutate(surname = TOP12[match(key, top12_keys)])
write_csv(fig3, file.path(OUT, "fig3_surname_shares.csv"))
# data-driven top 12 (exact spelling key), whole period 1700-1839
top12_data <- sn |> count(key, sort = TRUE) |> slice_head(n = 12)
write_csv(top12_data, file.path(OUT, "fig3_top12_datadriven.csv"))
# De Villiers: decade from which the share rises without interruption to its peak (share of all)
dv <- fig3 |> filter(key == "devilliers") |> arrange(decade)
pk <- which.max(dv$share_all)
st <- pk; while (st > 1 && dv$share_all[st - 1] < dv$share_all[st]) st <- st - 1
dv_rise_dec <- dv$decade[st]

# ---- 6. Figure 4: marriage pairs ------------------------------------------------
pairs <- hh |> filter(year >= 1700, year <= 1839,
                      !is.na(name_men), !is.na(name_women), name_women != "", name_men != "") |>
  mutate(h = surname_of(name_men), w = surname_of(name_women),
         couple = paste(keyify(name_men), keyify(name_women))) |>
  filter(!is.na(h), !is.na(w), str_detect(name_women, ","))     # wife's surname recorded
couples <- pairs |> distinct(couple, .keep_all = TRUE)             # primary: distinct couples
pair_n  <- couples |> mutate(hk = keyify(h), wk = keyify(w)) |>
  count(hk, wk, name = "n") |> arrange(desc(n))
top100 <- pair_n |> slice_head(n = 100)
write_csv(top100, file.path(OUT, "fig4_top100_pairs.csv"))
endog <- couples |> mutate(hk = keyify(h), wk = keyify(w)) |>
  filter(hk %in% c("devilliers", "dutoit")) |>
  group_by(hk) |> summarise(couples = n(), within = mean(wk == hk),
                            n_partner_surnames = n_distinct(wk), .groups = "drop")
write_csv(endog, file.path(OUT, "fig4_endogamy_DV_DT.csv"))

# ---- 7. Louis Fourie trace -------------------------------------------------------
# post-hoc (decisions.md, change 1): given name Lou*/Ludovicus, surname F*/V* spelling variants
lf <- hh |> filter(year >= 1685, year <= 1760) |>
  mutate(l = tolower(name_men),
         given = if_else(str_detect(l, ","), str_trim(str_remove(l, "^[^,]*,")), word(l, 1)),
         fam   = if_else(str_detect(l, ","), str_remove(l, ",.*$"), word(l, -1))) |>
  filter(str_detect(given, "^(lou|luc?dovicus|ludovicus)"),
         str_detect(fam, "^(f|v)(a|l|o|e|u)"), !str_detect(fam, "verbrug|verburg|^van ")) |>
  select(year, name_men) |> distinct()
write_csv(lf, dscratch(PAPER, "repro_r", "louis_fourie_rows.csv"))
lf_first <- min(lf$year); lf_last <- max(lf$year)
exact <- function(x) str_detect(x, "^Louis Fourie$|^Fourie, Louis$")
lf_settled_strict <- {           # pre-registered: first year from which every later entry is spelt exactly
  sy <- lf |> group_by(year) |> summarise(ok = any(exact(name_men)), .groups = "drop") |> arrange(year)
  cand <- sy$year[map_lgl(seq_len(nrow(sy)), ~ all(sy$ok[.x:nrow(sy)]))]
  if (length(cand)) min(cand) else NA
}
# post-hoc (decisions.md, change 2): first year spelt exactly 'Louis Fourie'
lf_settled <- min(lf$year[exact(lf$name_men)])
# census years with an entry strictly between the paper's anchor (1700) and lf_settled
lf_variants_before <- lf |> filter(year > 1700, year < lf_settled) |> distinct(year) |> nrow()
lf_years_after_exact_variant <- lf |> filter(year > lf_settled) |> group_by(year) |>
  summarise(all_exact = all(exact(name_men)), .groups = "drop") |> summarise(sum(!all_exact)) |> pull()

# ---- 8. Figure 7: enslaved people per household by sex/age, two-decade bins -----
sl <- hh |> filter(year <= 1838) |>
  mutate(bin = 1680 + floor((year - 1680) / 20) * 20) |>
  select(year, bin, slave_men, slave_women, slave_boys, slave_girls) |>
  pivot_longer(starts_with("slave_"), names_to = "type", values_to = "n") |>
  filter(!is.na(n))
fig7 <- sl |> group_by(bin, type) |>
  summarise(households = n(), mean = mean(n), share_zero = mean(n == 0),
            share_gt1 = mean(n > 1), p90 = quantile(n, 0.9), .groups = "drop")
write_csv(fig7, file.path(OUT, "fig7_slave_distribution.csv"))

# ---- 9. results_r.csv -------------------------------------------------------------
n_at <- function(y) { v <- nobs$n_obs[nobs$year == y]; if (length(v)) v else NA_real_ }
first_or_na <- function(x) if (length(x)) x[1] else NA_real_
claims <- read_csv(here(PAPER, "claims", "claims.csv"), show_col_types = FALSE)
r <- list()
add <- function(id, value, n = NA, status = NA_character_) r[[length(r) + 1]] <<- tibble(
  claim_id = id, source = "r", value = as.numeric(value), se = NA_real_, n = as.numeric(n), status_override = as.character(status))

add("TX_rows", n_rows, n_rows)
add("TX_censuses", n_censuses)
add("TX_volumes", NA, status = "not-attempted")
add("TX_vars", NA, status = "not-attempted")
add("TX_cols50", NA, status = "not-attempted")
add("TX_fn31_drop20", NA, status = "not-attempted")
add("TX_top12", NA, status = "not-attempted")
add("TX_pairs100", NA, status = "not-attempted")
add("TX_years159", span_years)
add("TX_gini_lo", round(gini_p10, 3), length(pooled))
add("TX_gini_hi", round(gini_max, 3), length(pooled))
add("TX_wineGini_peak", wine_peak_dec)
add("TX_shift_lo", NA, status = "not-attempted")
add("TX_shift_hi", NA, status = "not-attempted")
add("TX_break1804", break_year)
add("TX_frag1830", NA, status = "not-attempted")
add("TX_fourie_1700", lf_first)
add("TX_fourie_17", lf_variants_before)
add("TX_fourie_1718", lf_settled)
add("TX_fourie_1750", lf_last)
add("TX_DV_rise", dv_rise_dec)
add("TX_const1750", NA, status = "not-attempted")
add("TX_var3dec", NA, status = "not-attempted")

for (id in claims$claim_id[str_starts(claims$claim_id, "F3_")]) {
  p <- str_match(id, "F3_(.+)_(\\d{4})")
  k <- keyify(p[2]); d <- as.integer(p[3])
  row <- fig3 |> filter(key == k, decade == d)
  add(id, first_or_na(round(row$share_all, 2)), first_or_na(row$n_named))
}
for (id in claims$claim_id[str_starts(claims$claim_id, "F5_")]) {
  p <- str_match(id, "F5_(.+)_(\\d{4})"); a <- p[2]; y <- as.integer(p[3])
  if (a == "nobs") add(id, round(at_year(fig5, y, "n_obs")), round(at_year(fig5, y, "n_obs")))
  else add(id, round(at_year(fig5, y, a), 3), n_at(y))
}
for (id in claims$claim_id[str_starts(claims$claim_id, "F6_")]) {
  p <- str_match(id, "F6_(.+)_(\\d{4})"); a <- p[2]; y <- as.integer(p[3])
  add(id, round(at_year(g_w, y, a), 3), n_at(y))
}
res <- bind_rows(r)
stopifnot(setequal(res$claim_id, claims$claim_id))
res <- res[match(claims$claim_id, res$claim_id), ]
write_csv(res, here(PAPER, "repro_r", "results_r.csv"), na = "")

# headline diagnostics to log
diag <- list(n_rows = n_rows, n_censuses = n_censuses, gini_p10 = gini_p10, gini_max = gini_max,
             share_gini_in_04_1 = share_in, wine_peak_year = wine_peak_year, break_year = break_year,
             dv_rise_dec = dv_rise_dec, lf_first = lf_first, lf_settled = lf_settled, lf_last = lf_last,
             lf_variants_before = lf_variants_before,
             lf_settled_strict = lf_settled_strict, lf_years_after_exact_variant = lf_years_after_exact_variant)
write_csv(enframe(diag) |> mutate(value = map_chr(value, as.character)), file.path(OUT, "diagnostics.csv"))
print(enframe(diag) |> mutate(value = map_chr(value, as.character)), n = 50)
print(trend)
print(endog)
print(top12_data)
