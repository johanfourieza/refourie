# P07_FG S3 independent recreation -- 02_analysis.R
# Recreates Table 1 (Khoesan labourers), Tables 3-6 (slave productivity with and
# without Khoesan), text-anchored numbers, and an illustrative Table 7 proxy.
# Primary specification = the paper's text as stated (decisions.md D1-D8).
# Sensitivities, including the post-hoc Stellenbosch ratio (D9), go to
# output/sensitivity.csv and are NOT in results_r.csv.

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
  library(kableExtra)
})
source(here::here("tools", "paths.R"))
set.seed(20261011)

PAPER <- "P07_FG"
out_dir <- here::here(PAPER, "repro_r", "output")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
d <- readRDS(dscratch(PAPER, "repro_r", "opgaaf_clean.rds"))

res <- list()
add <- function(id, value, n = NA, status_override = NA_character_) {
  res[[length(res) + 1]] <<- tibble(claim_id = id, source = "r", value = value,
                                     se = NA_real_, n = n,
                                     status_override = status_override)
}

# =============================================================================
# Table 1: Khoesan labourers and slaves by region (farmer households, D3)
# =============================================================================
t1_years <- c(1663, 1682, 1685, 1692, 1695, 1700, 1709, 1712, 1719, 1723, 1731,
              1738, 1741, 1757, 1773)
csd <- c("Cape", "Stellenbosch", "Drakenstein")

table1_fun <- function(kvar) {
  d %>% filter(farmer, Year %in% t1_years) %>%
    group_by(Year) %>%
    summarise(
      all_khoesan = sum(.data[[kvar]]),
      all_slaves  = sum(Slaves),
      csd_khoesan = sum(.data[[kvar]][district %in% csd]),
      csd_slaves  = sum(Slaves[district %in% csd]),
      swe_khoesan = sum(.data[[kvar]][district == "Swellendam"]),
      swe_slaves  = sum(Slaves[district == "Swellendam"]),
      swe_maleslaves = sum(Slavemales[district == "Swellendam"]),
      unk_slaves  = sum(Slaves[!district %in% c(csd, "Swellendam")]),
      .groups = "drop")
}
t1 <- table1_fun("khoesan")
t1_post <- table1_fun("khoesan_posthoc")

# Integer reporting (D5): yearly sums rounded; Total = sum of rounded yearly cells
t1r <- t1 %>% mutate(across(-Year, round))
for (i in seq_len(nrow(t1r))) {
  y <- t1r$Year[i]
  add(paste0("T1_", y, "_all_khoesan"), t1r$all_khoesan[i])
  add(paste0("T1_", y, "_all_slaves"),  t1r$all_slaves[i])
  add(paste0("T1_", y, "_csd_khoesan"), t1r$csd_khoesan[i])
  add(paste0("T1_", y, "_csd_slaves"),  t1r$csd_slaves[i])
  if (y >= 1757) {
    add(paste0("T1_", y, "_swe_khoesan"), t1r$swe_khoesan[i])
    add(paste0("T1_", y, "_swe_slaves"),  t1r$swe_slaves[i])
  }
}
tot <- t1r %>% summarise(across(-Year, sum))
for (v in c("all_khoesan", "all_slaves", "csd_khoesan", "csd_slaves",
            "swe_khoesan", "swe_slaves")) add(paste0("T1_Total_", v), tot[[v]])

# =============================================================================
# Text claims anchored on the data
# =============================================================================
botha <- d %>% filter(str_detect(Surname, "BOTHA"), Name == "JACOBUS", Year == 1773,
                      Slavemales == 20)
tas <- d %>% filter(str_detect(Surname, "^TAS"), Year == 1709)
add("tx_p204_botha_maleslaves", botha$Slavemales)
add("tx_p204_botha_femaleslaves", botha$Slavefemales)
add("tx_p204_botha_horses", botha$Horses)
add("tx_p204_botha_cattle", botha$Cattle)
add("tx_p204_botha_sheep", botha$Sheep)
add("tx_p204_botha_herdvalue", round(botha$herd))
add("tx_p204_ratio_swe_gt5", round(botha$herd / 50, 1))         # clan of ~50
add("tx_p204_tas_herd", round(tas$herd))
add("tx_p204_tas_vines", tas$Vineyards)
add("tx_p204_tas_ratio", round(tas$herd / 11))                  # 11 Khoesan

# Growth 1685-1773 (D6: compound annual rate between the two endpoints)
k85 <- t1$all_khoesan[t1$Year == 1685]; k73 <- t1$all_khoesan[t1$Year == 1773]
g_kh <- 100 * ((k73 / k85)^(1 / (1773 - 1685)) - 1)
add("tx_p205_kh_1685", round(k85))
add("tx_p205_kh_1773", round(k73))
add("tx_p205_kh_growth", round(g_kh, 1))
s85 <- t1$all_slaves[t1$Year == 1685]; s73 <- t1$all_slaves[t1$Year == 1773]
g_sl <- 100 * ((s73 / s85)^(1 / 88) - 1)
# log-linear trend growth over the census years 1685-1773 (sensitivity)
tr <- t1 %>% filter(Year >= 1685)
g_kh_ols <- 100 * (exp(coef(lm(log(all_khoesan) ~ Year, tr))[2]) - 1)
g_sl_ols <- 100 * (exp(coef(lm(log(all_slaves) ~ Year, tr))[2]) - 1)

# Swellendam Khoesan : male slaves (1757 + 1773), as the text states it
swe_k <- sum(t1r$swe_khoesan[t1r$Year %in% c(1757, 1773)])
swe_m <- sum(t1$swe_maleslaves[t1$Year %in% c(1757, 1773)])
add("tx_p205_swe_khoesan", swe_k)
add("tx_p205_swe_maleslaves", swe_m)
add("tx_p205_swe_ratio", round(swe_k / swe_m, 1))
add("tx_p206_own_stel_1773", t1r$csd_khoesan[t1r$Year == 1773])

# Baseline series growth (D7): linear 50,000 (1652) -> X (1780) with 20% (1713)
# and 5% (1755) level drops, X chosen so the 1780 value is 23,000. The implied
# underlying trend growth is the 'growth rate' in the text.
x1780 <- 23000 / (0.8 * 0.95)
g_base <- 100 * log(x1780 / 50000) / (1780 - 1652)
add("tx_p203_growth", round(g_base, 1))

# =============================================================================
# Tables 3-6: slave productivity (D8)
# =============================================================================
prod_years <- c(1719, 1723, 1731, 1738, 1741, 1757, 1773)
p <- d %>%
  filter(Year %in% prod_years, district %in% csd, Slavemales > 0) %>%
  mutate(district = factor(district, levels = csd),
         wheat = Wheatreaped, wine = Wine,
         grain = Wheatreaped + Ryereaped + Barleyreaped,   # sensitivity S7 only
         viti = Vineyards > 0 | Wine > 0,
         wheatfarm = Wheatreaped > 0 | Wheatsown > 0,
         L = Slavemales, Lstar = Slavemales + khoesan,
         Lstar_post = Slavemales + khoesan_posthoc)

# Mean of farm-level ratios (primary) or ratio of sums (sensitivity)
prodtab <- function(df, y, how = "mean", lstar = "Lstar") {
  f <- function(x) {
    if (how == "mean") tibble(n = nrow(x), without = mean(x[[y]] / x$L),
                              with = mean(x[[y]] / x[[lstar]]))
    else tibble(n = nrow(x), without = sum(x[[y]]) / sum(x$L),
                with = sum(x[[y]]) / sum(x[[lstar]]))
  }
  bind_rows(df %>% group_by(district) %>% group_modify(~ f(.x)) %>% ungroup() %>%
              mutate(district = as.character(district)),
            f(df) %>% mutate(district = "Total"))
}

samples <- list(
  T3 = function(x) x %>% filter(herd <= 1000, wheat > 0, !viti),
  T4 = function(x) x %>% filter(herd <= 1000, wine > 0, !wheatfarm),
  T5 = function(x) x %>% filter(wheat > 0 | wine > 0)
)
lab <- c(Cape = "Capedistrict", Stellenbosch = "Stellenbosch",
         Drakenstein = "Drakenstein", Total = "Total")

t3 <- prodtab(samples$T3(p), "wheat")
t4 <- prodtab(samples$T4(p), "wine")
t5w <- prodtab(samples$T5(p), "wheat")
t5v <- prodtab(samples$T5(p), "wine")
for (tt in list(list("T3", t3), list("T4", t4))) {
  x <- tt[[2]]
  for (i in seq_len(nrow(x))) {
    id <- paste0(tt[[1]], "_", lab[x$district[i]])
    add(paste0(id, "_n"), x$n[i], x$n[i])
    add(paste0(id, "_without"), round(x$without[i], 1), x$n[i])
    add(paste0(id, "_with"), round(x$with[i], 1), x$n[i])
  }
}
for (i in seq_len(nrow(t5w))) {
  id <- paste0("T5_", lab[t5w$district[i]])
  add(paste0(id, "_n"), t5w$n[i], t5w$n[i])
  add(paste0(id, "_wheat_without"), round(t5w$without[i], 1), t5w$n[i])
  add(paste0(id, "_wheat_with"), round(t5w$with[i], 1), t5w$n[i])
  add(paste0(id, "_wheat_pct"), round(100 * (t5w$with[i] / t5w$without[i] - 1), 1), t5w$n[i])
  add(paste0(id, "_wine_without"), round(t5v$without[i], 1), t5v$n[i])
  add(paste0(id, "_wine_with"), round(t5v$with[i], 1), t5v$n[i])
  add(paste0(id, "_wine_pct"), round(100 * (t5v$with[i] / t5v$without[i] - 1), 1), t5v$n[i])
}
# Table 6: T5 sample split by total slaves owned (1-5 vs >5)
t6 <- list()
for (g in c("s1to5", "s6plus")) {
  sub <- samples$T5(p) %>% filter(if (g == "s1to5") Slaves <= 5 else Slaves > 5)
  w <- prodtab(sub, "wheat"); v <- prodtab(sub, "wine")
  t6[[g]] <- w %>% rename(wheat_without = without, wheat_with = with) %>%
    left_join(v %>% select(district, wine_without = without, wine_with = with), by = "district")
  for (i in seq_len(nrow(w))) {
    id <- paste0("T6_", lab[w$district[i]], "_", g)
    add(paste0(id, "_n"), w$n[i], w$n[i])
    add(paste0(id, "_wheat_without"), round(w$without[i], 1), w$n[i])
    add(paste0(id, "_wheat_with"), round(w$with[i], 1), w$n[i])
    add(paste0(id, "_wine_without"), round(v$without[i], 1), v$n[i])
    add(paste0(id, "_wine_with"), round(v$with[i], 1), v$n[i])
  }
}
# text duplicates of table cells
dup <- c(tx_p209_stel_wo = "T3_Stellenbosch_without", tx_p209_stel_w = "T3_Stellenbosch_with",
         tx_p209_drak_wo = "T3_Drakenstein_without", tx_p209_drak_w = "T3_Drakenstein_with",
         tx_p210_t5_stel_wo = "T5_Stellenbosch_wheat_without",
         tx_p210_t5_drak_wo = "T5_Drakenstein_wheat_without",
         tx_p210_t5_stel_w = "T5_Stellenbosch_wheat_with",
         tx_p210_t5_drak_w = "T5_Drakenstein_wheat_with",
         tx_p210_t6_wheat_wo_small = "T6_Total_s1to5_wheat_without",
         tx_p210_t6_wheat_wo_large = "T6_Total_s6plus_wheat_without",
         tx_p210_t6_wheat_w_small = "T6_Total_s1to5_wheat_with",
         tx_p210_t6_wheat_w_large = "T6_Total_s6plus_wheat_with",
         tx_p210_t6_wine_wo_small = "T6_Total_s1to5_wine_without",
         tx_p210_t6_wine_wo_large = "T6_Total_s6plus_wine_without",
         tx_p210_t6_wine_w_small = "T6_Total_s1to5_wine_with",
         tx_p210_t6_wine_w_large = "T6_Total_s6plus_wine_with")
cur <- bind_rows(res)
for (k in names(dup)) {
  r <- cur %>% filter(claim_id == dup[[k]])
  add(k, r$value, r$n)
}

# Worden replication, Cape district 1741, grain-only farmers (D8e)
wo <- function(cap) {
  x <- d %>% filter(Year == 1741, district == "Cape", Slavemales > 0,
                    Wheatreaped > 0, Vineyards == 0, Wine == 0, herd <= cap)
  c(n = nrow(x), v = mean(x$Wheatreaped / x$Slavemales))
}
w400 <- wo(400); w1000 <- wo(1000)
add("tx_p208_rep_400", round(w400[["v"]], 1), w400[["n"]])
add("tx_p208_rep_400_n", w400[["n"]], w400[["n"]])
add("tx_p209_rep_1000", round(w1000[["v"]], 1), w1000[["n"]])
add("tx_p209_rep_1000_n", w1000[["n"]], w1000[["n"]])
# Worden redo, Stellenbosch 1773 wine per male slave (wine farmers, no wheat)
ws <- d %>% filter(Year == 1773, district == "Stellenbosch", Slavemales > 0, Wine > 0,
                   Wheatreaped == 0, Wheatsown == 0)
add("tx_p209_redo_wine_stel", round(mean(ws$Wine / ws$Slavemales), 1), nrow(ws))

# =============================================================================
# Not reproducible from the allowed data
# =============================================================================
claims <- read_csv(here::here(PAPER, "claims", "claims.csv"), show_col_types = FALSE)
done <- bind_rows(res)$claim_id
for (id in setdiff(claims$claim_id, done)) {
  st <- if (str_detect(id, "^T7_|^tx_p213|^F3_|^tx_p214")) "unavailable" else "not-attempted"
  add(id, NA_real_, NA, st)
}
results <- bind_rows(res) %>% filter(claim_id %in% claims$claim_id) %>%
  distinct(claim_id, .keep_all = TRUE)
results <- results[match(claims$claim_id, results$claim_id), ]
stopifnot(!any(is.na(results$claim_id)))
write_csv(results, here::here(PAPER, "repro_r", "results_r.csv"), na = "")

# =============================================================================
# Sensitivities (not in results_r.csv)
# =============================================================================
sens <- list()
sadd <- function(spec, id, value, n = NA) sens[[length(sens) + 1]] <<-
  tibble(spec = spec, claim_id = id, value = value, n = n)
tp <- t1_post %>% mutate(across(-Year, round))
for (i in seq_len(nrow(tp))) {
  sadd("S1_posthoc_stel_ratio", paste0("T1_", tp$Year[i], "_all_khoesan"), tp$all_khoesan[i])
  sadd("S1_posthoc_stel_ratio", paste0("T1_", tp$Year[i], "_csd_khoesan"), tp$csd_khoesan[i])
}
sadd("S1_posthoc_stel_ratio", "T1_Total_all_khoesan", sum(tp$all_khoesan))
sadd("S1_posthoc_stel_ratio", "T1_Total_csd_khoesan", sum(tp$csd_khoesan))
sadd("S2_growth_loglinear", "tx_p205_kh_growth", round(g_kh_ols, 1))
sadd("S2_growth_loglinear", "slaves_growth", round(g_sl_ols, 1))
sadd("S2_growth_compound", "slaves_growth", round(g_sl, 1))

sens_tab <- function(spec, how = "mean", lstar = "Lstar", t5cap = Inf, yw = "wheat") {
  s3 <- prodtab(samples$T3(p), yw, how, lstar)
  s4 <- prodtab(samples$T4(p), "wine", how, lstar)
  s5 <- samples$T5(p) %>% filter(herd <= t5cap)
  s5w <- prodtab(s5, yw, how, lstar); s5v <- prodtab(s5, "wine", how, lstar)
  for (i in 1:4) {
    sadd(spec, paste0("T3_", lab[s3$district[i]], "_without"), round(s3$without[i], 1), s3$n[i])
    sadd(spec, paste0("T3_", lab[s3$district[i]], "_with"), round(s3$with[i], 1), s3$n[i])
    sadd(spec, paste0("T4_", lab[s4$district[i]], "_without"), round(s4$without[i], 1), s4$n[i])
    sadd(spec, paste0("T4_", lab[s4$district[i]], "_with"), round(s4$with[i], 1), s4$n[i])
    sadd(spec, paste0("T5_", lab[s5w$district[i]], "_n"), s5w$n[i], s5w$n[i])
    sadd(spec, paste0("T5_", lab[s5w$district[i]], "_wheat_without"), round(s5w$without[i], 1), s5w$n[i])
    sadd(spec, paste0("T5_", lab[s5w$district[i]], "_wheat_with"), round(s5w$with[i], 1), s5w$n[i])
    sadd(spec, paste0("T5_", lab[s5v$district[i]], "_wine_without"), round(s5v$without[i], 1), s5v$n[i])
    sadd(spec, paste0("T5_", lab[s5v$district[i]], "_wine_with"), round(s5v$with[i], 1), s5v$n[i])
  }
  for (g in c("s1to5", "s6plus")) {
    sub <- s5 %>% filter(if (g == "s1to5") Slaves <= 5 else Slaves > 5)
    w <- prodtab(sub, yw, how, lstar); v <- prodtab(sub, "wine", how, lstar)
    for (i in seq_len(nrow(w))) {
      id <- paste0("T6_", lab[w$district[i]], "_", g)
      sadd(spec, paste0(id, "_n"), w$n[i], w$n[i])
      sadd(spec, paste0(id, "_wheat_without"), round(w$without[i], 1), w$n[i])
      sadd(spec, paste0(id, "_wheat_with"), round(w$with[i], 1), w$n[i])
      sadd(spec, paste0(id, "_wine_without"), round(v$without[i], 1), v$n[i])
      sadd(spec, paste0(id, "_wine_with"), round(v$with[i], 1), v$n[i])
    }
  }
}
sens_tab("S3_ratio_of_sums", how = "sum")
sens_tab("S4_posthoc_stel_ratio", lstar = "Lstar_post")
sens_tab("S5_T5T6_herdcap1000", t5cap = 1000)
sens_tab("S7_grain_output", yw = "grain")
sens_tab("S8_grain_posthoc_ratio_herdcap", yw = "grain", lstar = "Lstar_post", t5cap = 1000)
# S6 (post-hoc): Table 1 'Cape, Stellenbosch, Drakenstein' = All minus Swellendam
# (district codes 0 and 5 included); Swellendam Total = displayed years only.
t1s6 <- t1r %>% mutate(csd_k = all_khoesan - swe_khoesan, csd_s = all_slaves - swe_slaves)
for (i in seq_len(nrow(t1s6))) {
  sadd("S6_csd_as_all_minus_swe", paste0("T1_", t1s6$Year[i], "_csd_khoesan"), t1s6$csd_k[i])
  sadd("S6_csd_as_all_minus_swe", paste0("T1_", t1s6$Year[i], "_csd_slaves"), t1s6$csd_s[i])
}
sadd("S6_csd_as_all_minus_swe", "T1_Total_csd_slaves", sum(t1s6$csd_s))
sadd("S6_csd_as_all_minus_swe", "T1_Total_swe_khoesan", sum(t1r$swe_khoesan[t1r$Year >= 1757]))
sadd("S6_csd_as_all_minus_swe", "T1_Total_swe_slaves", sum(t1r$swe_slaves[t1r$Year >= 1757]))
# S7 for the Worden replication: grain = wheat + rye + barley
wo_g <- function(cap) {
  x <- d %>% filter(Year == 1741, district == "Cape", Slavemales > 0, Wheatreaped > 0,
                    Vineyards == 0, Wine == 0, herd <= cap)
  c(n = nrow(x), v = mean((x$Wheatreaped + x$Ryereaped + x$Barleyreaped) / x$Slavemales))
}
g4 <- wo_g(400); g10 <- wo_g(1000)
sadd("S7_grain_output", "tx_p208_rep_400", round(g4[["v"]], 1), g4[["n"]])
sadd("S7_grain_output", "tx_p209_rep_1000", round(g10[["v"]], 1), g10[["n"]])
sensitivity <- bind_rows(sens)
write_csv(sensitivity, file.path(out_dir, "sensitivity.csv"))

# =============================================================================
# Table 7 proxy (illustrative only; FvF 2011 income data are not available)
# =============================================================================
gini <- function(x) { x <- sort(x); n <- length(x); sum((2 * seq_len(n) - n - 1) * x) / (n * sum(x)) }
theil_dec <- function(x, g) {
  mu <- mean(x); n <- length(x)
  tot <- mean((x / mu) * log(x / mu))
  gs <- split(x, g)
  between <- sum(sapply(gs, function(z) (length(z) / n) * (mean(z) / mu) * log(mean(z) / mu)))
  c(total = tot, between = between, within = tot - between)
}
# Persons: settler household members share household gross output equally;
# each slave receives a fixed 'income' equal to the 10th percentile of settler
# per-capita output (assumption); Khoesan (Table 1, 1757) receive the slave income.
s57 <- d %>% filter(Year == 1757, Output > 0, Hhsize > 0)
pc <- rep(s57$Output / s57$Hhsize, s57$Hhsize)
slave_inc <- quantile(pc, 0.10)
nsl <- sum(s57$Slaves)
nkh <- round(sum(s57$khoesan))
x0 <- c(pc, rep(slave_inc, nsl)); g0 <- c(rep("settler", length(pc)), rep("slave", nsl))
x1 <- c(x0, rep(slave_inc, nkh)); g1 <- c(g0, rep("khoesan", nkh))
t7p <- tibble(measure = c("Gini", "Theil total", "Theil between", "Theil within"),
              without_khoesan = c(gini(x0), theil_dec(x0, g0)),
              with_khoesan = c(gini(x1), theil_dec(x1, g1)))
write_csv(t7p %>% mutate(across(where(is.numeric), ~ round(.x, 3))),
          file.path(out_dir, "table7_proxy_illustrative.csv"))

# =============================================================================
# LaTeX tables
# =============================================================================
fmt1 <- function(x) formatC(x, format = "f", digits = 1)
t1_tex <- t1r %>% transmute(Year, `All: Khoesan` = all_khoesan, `All: Slaves` = all_slaves,
                            `CSD: Khoesan` = csd_khoesan, `CSD: Slaves` = csd_slaves,
                            `Swe: Khoesan` = ifelse(Year >= 1757, swe_khoesan, NA),
                            `Swe: Slaves` = ifelse(Year >= 1757, swe_slaves, NA)) %>%
  mutate(across(everything(), as.character)) %>%
  bind_rows(tot %>% transmute(Year = "Total", `All: Khoesan` = all_khoesan, `All: Slaves` = all_slaves,
                              `CSD: Khoesan` = csd_khoesan, `CSD: Slaves` = csd_slaves,
                              `Swe: Khoesan` = swe_khoesan, `Swe: Slaves` = swe_slaves) %>%
              mutate(across(everything(), as.character)))
kbl(t1_tex, format = "latex", booktabs = TRUE, na = "--",
    caption = "Number of Khoesan by region (R recreation, ratios as stated)") %>%
  save_kable(file.path(out_dir, "table1.tex"))
for (nm in c("table3", "table4")) {
  x <- if (nm == "table3") t3 else t4
  kbl(x %>% mutate(across(c(without, with), fmt1)) %>%
        rename(District = district, N = n, `Without Khoesan` = without, `With Khoesan` = with),
      format = "latex", booktabs = TRUE,
      caption = paste("R recreation of", nm)) %>% save_kable(file.path(out_dir, paste0(nm, ".tex")))
}
t5tab <- t5w %>% transmute(District = district, N = n, `Wheat without` = fmt1(without),
                           `Wheat with` = fmt1(with), `Wheat %` = fmt1(100 * (with / without - 1))) %>%
  bind_cols(t5v %>% transmute(`Wine without` = fmt1(without), `Wine with` = fmt1(with),
                              `Wine %` = fmt1(100 * (with / without - 1))))
kbl(t5tab, format = "latex", booktabs = TRUE, caption = "R recreation of table 5") %>%
  save_kable(file.path(out_dir, "table5.tex"))
t6tab <- bind_rows(t6, .id = "group") %>% mutate(across(where(is.double), ~ round(.x, 1)))
kbl(t6tab, format = "latex", booktabs = TRUE, caption = "R recreation of table 6") %>%
  save_kable(file.path(out_dir, "table6.tex"))
write_csv(t1, file.path(out_dir, "table1_unrounded.csv"))
write_csv(t1_post, file.path(out_dir, "table1_posthoc_unrounded.csv"))
cat("Done. results rows:", nrow(results), " attempted:", sum(!is.na(results$value)), "\n")
