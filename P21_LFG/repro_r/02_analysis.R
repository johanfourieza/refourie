# 02_analysis.R -- Table 1, text numbers, annual translog + HEC (eqs 1-2). Conventional OLS.
suppressMessages({library(dplyr); library(tidyr); library(here); library(readr)})
source(here::here("tools", "paths.R"))
source(here::here("P21_LFG", "repro_r", "01_clean.R"))
out <- here::here("P21_LFG", "repro_r")
cl <- read_csv(here::here("P21_LFG", "claims", "claims.csv"), show_col_types = FALSE)
res <- tibble(claim_id = cl$claim_id, source = "r", value = NA_real_, se = NA_real_, n = NA_real_,
              status_override = "unavailable")
setv <- function(id, v, n = NA, se = NA) {
  i <- match(id, res$claim_id); if (is.na(i)) stop(id)
  res$value[i] <<- v; res$n[i] <<- n; res$se[i] <<- se; res$status_override[i] <<- NA_character_ }
save_res <- function() write_csv(res, file.path(out, "results_r.csv"), na = "")
save_res()

## Table 1 (pooled, all 42,180 rows; NAs dropped per variable)
t1 <- list(r1 = "sheep", r2 = "cattle", r3 = "settlers", r4 = "khoe", r5 = "slaves")
for (k in names(t1)) { x <- d[[t1[[k]]]]; nn <- sum(!is.na(x))
  setv(paste0("T1_", k, "_c1_mean"), mean(x, na.rm = TRUE), nn)
  setv(paste0("T1_", k, "_c2_stddev"), sd(x, na.rm = TRUE), nn)
  setv(paste0("T1_", k, "_c3_min"), min(x, na.rm = TRUE), nn)
  setv(paste0("T1_", k, "_c4_max"), max(x, na.rm = TRUE), nn) }
for (p in c("sheep","cattle")) setv(paste0("TX_p11_", p), mean(d[[p]], na.rm = TRUE), sum(!is.na(d[[p]])))
setv("TX_p11_family", mean(d$settlers, na.rm = TRUE)); setv("TX_p11_khoe", mean(d$khoe, na.rm = TRUE))
setv("TX_p11_slaves", mean(d$slaves, na.rm = TRUE))
vw <- d |> filter(year == 1820, grepl("WALT", lastnamemen), grepl("ANDRIES", firstnamemen))
setv("TX_p11_vdwalt", max(vw$khoe, na.rm = TRUE), nrow(vw))
vh <- d |> filter(year == 1826, grepl("HEERDEN", lastnamemen), grepl("CAREL", firstnamemen))
setv("TX_p11_vheerden", max(vh$slaves, na.rm = TRUE), nrow(vh))

## Quintiles of livestock wealth (pooled, all years)
d <- d |> mutate(q5 = ntile(livestock, 5))
qm <- d |> filter(!is.na(q5)) |> group_by(q5) |>
  summarise(sl = mean(slaves, na.rm = TRUE), kh = mean(khoe, na.rm = TRUE), n = n())
setv("TX_p12_slaves_q1", qm$sl[1], qm$n[1]); setv("TX_p12_slaves_q5", qm$sl[5], qm$n[5])
setv("TX_p13_khoe_q1", qm$kh[1], qm$n[1]); setv("TX_p13_khoe_q5", qm$kh[5], qm$n[5])

## Observation counts per annual regression (1805-1828)
yn <- d |> filter(year >= 1805) |> count(year)
setv("TX_p15_nobs_mean", mean(yn$n), nrow(yn)); setv("TX_p15_nobs_max", max(yn$n)); setv("TX_p15_nobs_min", min(yn$n))
setv("TX_p17_nobs_all", nrow(d), nrow(d))
write_csv(yn, file.path(out, "output", "obs_by_year.csv"))

## 1814 population decline (totals, 1813 -> 1814)
tot <- d |> group_by(year) |> summarise(across(c(settlers, khoe, slaves), ~sum(.x, na.rm = TRUE)))
write_csv(tot, file.path(out, "output", "pop_totals.csv"))
g <- function(v) 100 * (1 - tot[[v]][tot$year == 1814] / tot[[v]][tot$year == 1813])
setv("TX_p17_settler_decline", g("settlers")); setv("TX_p17_khoe_decline", g("khoe")); setv("TX_p17_slave_decline", g("slaves"))

## Robustness samples
setv("TX_p19_nobs_owners", sum(d$slaves > 0, na.rm = TRUE), sum(d$slaves > 0, na.rm = TRUE))
# households (linkage index) observed both before and after 1814
pp <- d |> filter(!is.na(index)) |> group_by(index) |> filter(any(year < 1814), any(year > 1814)) |> ungroup()
cat("pre/post-1814 linked obs:", nrow(pp), "\n")
setv("TX_p17_nobs_1814", nrow(pp), nrow(pp))
save_res()

## Translog by year; HEC_ij = (b_ij + M_i M_j)/(M_i M_j), M_i = b_i + sum_j b_ij lnX_j (squares carry 1/2)
hec_year <- function(dat, yr, window = 0) {
  fitd <- dat |> filter(abs(year - yr) <= window, !is.na(lq), !is.na(lk), !is.na(ls), !is.na(lf))
  ev <- fitd |> filter(year == yr)
  fm <- if (window > 0) lq ~ lk + ls + lf + I(.5*lk^2) + I(.5*ls^2) + I(.5*lf^2) + I(lk*ls) + I(lk*lf) + I(ls*lf) + factor(year)
        else lq ~ lk + ls + lf + I(.5*lk^2) + I(.5*ls^2) + I(.5*lf^2) + I(lk*ls) + I(lk*lf) + I(ls*lf)
  f <- lm(fm, data = fitd)
  b <- coef(f); names(b)[5:10] <- c("kk","ss","ff","ks","kf","sf")
  Mk <- b["lk"] + b["kk"]*ev$lk + b["ks"]*ev$ls + b["kf"]*ev$lf
  Ms <- b["ls"] + b["ss"]*ev$ls + b["ks"]*ev$lk + b["sf"]*ev$lf
  Mf <- b["lf"] + b["ff"]*ev$lf + b["kf"]*ev$lk + b["sf"]*ev$ls
  H <- function(bij, Mi, Mj) unname((bij + Mi*Mj)/(Mi*Mj))
  list(meta = tibble(year = yr, n = nrow(fitd), r2 = summary(f)$r.squared),
       hec = tibble(year = yr, HEC_FS = H(b["sf"], Ms, Mf), HEC_FK = H(b["kf"], Mk, Mf), HEC_SK = H(b["ks"], Ms, Mk)))
}
yrs <- sort(unique(d$year[d$year >= 1805]))
run <- function(window) lapply(yrs, function(y) hec_year(d, y, window))
r0 <- run(0); r2 <- run(2)
sumr <- function(r, tag) {
  H <- bind_rows(lapply(r, `[[`, "hec")); M <- bind_rows(lapply(r, `[[`, "meta"))
  H |> pivot_longer(-year, names_to = "pair", values_to = "hec") |> filter(is.finite(hec)) |>
    group_by(year, pair) |> summarise(median = median(hec), mean = mean(hec), q25 = quantile(hec, .25),
      q75 = quantile(hec, .75), n_hh = n(), .groups = "drop") |>
    left_join(M, by = "year") |> mutate(spec = tag)
}
S <- bind_rows(sumr(r0, "annual"), sumr(r2, "ma5_window"))
write_csv(S, file.path(out, "output", "hec_summary_by_year.csv"))
saveRDS(bind_rows(lapply(r0, `[[`, "hec")), file.path(out, "output", "hec_household_annual.rds"))
saveRDS(bind_rows(lapply(r2, `[[`, "hec")), file.path(out, "output", "hec_household_ma5.rds"))

A <- S |> filter(spec == "annual")
m <- function(p, ys) median(A$median[A$pair == p & A$year %in% ys])
get <- function(p, y) A$median[A$pair == p & A$year == y]
nn <- function(p, y) A$n[A$pair == p & A$year == y]
setv("F7_all_median", m("HEC_FS", 1805:1828)); setv("F7_1805_median", get("HEC_FS", 1805), nn("HEC_FS", 1805))
setv("F8_all_median", m("HEC_FK", 1805:1828))
setv("F9_1812_1817_median", m("HEC_SK", 1811:1817))
for (y in c(1821, 1823, 1828)) setv(paste0("F9_", y, "_median"), get("HEC_SK", y), nn("HEC_SK", y))
hh <- readRDS(file.path(out, "output", "hec_household_annual.rds")) |> filter(year == 1823, is.finite(HEC_SK))
qq <- quantile(hh$HEC_SK, c(.25, .75)); lw <- min(hh$HEC_SK[hh$HEC_SK >= qq[1] - 1.5*diff(qq)])
setv("F9_1823_lowwhisk", lw, nrow(hh))
save_res()
print(A |> select(year, pair, median) |> pivot_wider(names_from = pair, values_from = median), n = 30)
print(S |> filter(spec == "ma5_window") |> select(year, pair, median) |> pivot_wider(names_from = pair, values_from = median), n = 30)
print(res |> filter(!is.na(value)) |> select(claim_id, value, n), n = 60)
