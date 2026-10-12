# S3 independent recreation, P02_BoF10: ARDL(4) bounds tests on log series, raw / 5y MA / band-pass
suppressPackageStartupMessages({library(tidyverse); library(here); library(mFilter); library(zoo); library(sandwich); library(readxl)})
source(here("tools","paths.R")); set.seed(20101012)
d <- read_csv(dscratch("P02_BoF10","repro_r","series.csv"), show_col_types = FALSE)
claims <- read_csv(here("P02_BoF10","claims","claims.csv"), show_col_types = FALSE)
out_dir <- here("P02_BoF10","repro_r","output")

# series builder: log, interpolate internal gaps, trim to first/last observed year
mk <- function(v) { s <- d[[v]]; ok <- which(!is.na(s)); rng <- min(ok):max(ok)
  tibble(year = d$year[rng], x = log(na.approx(s[rng], na.rm = FALSE))) }
S <- list(ships = "ships", wheat_sown = "wheat_sown", wheat_reaped = "wheat_reaped", wheat_brunt = "wheat_brunt",
          wheat_exports = "wheat_exports", vines = "vines", wine = "wine", cattle = "cattle") |> map(mk)

cf <- function(x, pl, pu) as.numeric(cffilter(x, pl = pl, pu = pu, root = FALSE, drift = FALSE)$cycle)  # Christiano-Fitzgerald, asymmetric
transf <- function(s, how) {
  x <- s$x
  s$x <- switch(how, raw = x,
    ma5 = as.numeric(stats::filter(x, rep(1/5, 5), sides = 2)),     # centred 5-year MA
    ma5t = as.numeric(stats::filter(x, rep(1/5, 5), sides = 1)),    # trailing (EViews @movav) sensitivity
    hfrem = x - cf(x, 2, 12),                                       # 2-12 year fluctuations removed
    med = cf(x, 12, 40),                                            # 12-40 year component
    med1220 = cf(x, 12, 20), short = cf(x, 2, 8))
  s |> filter(!is.na(x))
}

# UECM bounds F (case III: unrestricted intercept, no trend); dep y, regressor x; p = 4 -> 3 lagged differences
uecm <- function(y, x, p = 4) {
  m <- inner_join(y, x, by = "year", suffix = c("y", "x")) |> arrange(year)
  Y <- m$xy; X <- m$xx; n <- length(Y); k <- p - 1
  dY <- diff(Y); dX <- diff(X)
  idx <- (k + 1):(n - 1)                       # differences index t (dY[t] = Y[t+1]-Y[t])
  df <- tibble(dy = dY[idx], ylag = Y[idx], xlag = X[idx])
  for (i in seq_len(k)) { df[[paste0("dyl", i)]] <- dY[idx - i]; df[[paste0("dxl", i)]] <- dX[idx - i] }
  df$dx0 <- dX[idx]
  mod <- lm(dy ~ ., data = df)
  R <- c("ylag", "xlag"); rss1 <- sum(resid(mod)^2)
  r0 <- lm(update(formula(mod), . ~ . - ylag - xlag), data = df)
  Fst <- ((sum(resid(r0)^2) - rss1) / 2) / (rss1 / mod$df.residual)
  b <- coef(mod); th <- -b["xlag"] / b["ylag"]
  g <- c(b["xlag"] / b["ylag"]^2, -1 / b["ylag"]); nm <- c("ylag", "xlag")
  se_c <- sqrt(drop(t(g) %*% vcov(mod)[nm, nm] %*% g))
  se_h <- sqrt(drop(t(g) %*% sandwich::NeweyWest(mod, lag = 4, prewhite = FALSE)[nm, nm] %*% g))
  se_r <- sqrt(drop(t(g) %*% sandwich::vcovHC(mod, "HC1")[nm, nm] %*% g))
  list(F = Fst, theta = unname(th), se = se_c, se_hac = se_h, se_hc1 = se_r, n = nrow(df), first = min(m$year), last = max(m$year))
}

# Table specification. "Ships -> X" = conditional equation with X as dependent variable (claims_spec (d)).
# rows: (variable, dependent-is-variable?) alternating  Ships -> v (dep v), v -> Ships (dep ships)
arrows <- function(vars) map_dfr(seq_along(vars), \(i) tibble(r = 2*i - 1:0, dep = c(vars[i], "ships"), ind = c("ships", vars[i])) |> arrange(r))
t2 <- arrows(c("wheat_sown","wheat_reaped","vines","wine","cattle"))
t3 <- arrows(c("wheat_sown","wheat_reaped","wheat_exports","vines","wine","cattle"))
t4 <- arrows(c("wheat_sown","wheat_reaped","wheat_brunt","wheat_exports","vines","wine","cattle"))
spec <- bind_rows(
  t2 |> crossing(h = c(a = "raw", b = "ma5")) |> mutate(id = paste0("T2", names(h), "_r", r, "_F")),
  t3 |> mutate(h = "hfrem", id = paste0("T3_r", r, "_F")),
  t4 |> mutate(h = "med", id = paste0("T4_r", r, "_F"))) |> rename(how = h)

run <- function(dep, ind, how, p = 4) uecm(transf(S[[dep]], how), transf(S[[ind]], how), p)
res <- pmap_dfr(spec, \(r, dep, ind, how, id) { u <- run(dep, ind, how); tibble(claim_id = id, value = u$F, n = u$n, window = paste(u$first, u$last, sep = "-")) })
# sensitivity: p = 5 (4 lagged differences) for Table 4
sens5 <- t4 |> mutate(how = "med", id = paste0("T4_r", r, "_F")) |> pmap_dfr(\(r, dep, ind, how, id) tibble(claim_id = id, F_p5 = run(dep, ind, how, 5)$F))
write_csv(res |> left_join(sens5, by = "claim_id"), file.path(out_dir, "bounds_F_all.csv"))

# Table 5 long-run coefficients (medium term); same rows as T4 r3..r8 style but claims use their own numbering
t5 <- tribble(~id, ~dep, ~ind,
  "T5_r1_coef","wheat_reaped","ships", "T5_r2_coef","ships","wheat_reaped",
  "T5_r3_coef","wheat_brunt","ships",  "T5_r4_coef","ships","wheat_brunt",
  "T5_r5_coef","wheat_exports","ships","T5_r6_coef","ships","wheat_exports",
  "T5_r7_coef","vines","ships",        "T5_r8_coef","ships","vines")
r5 <- pmap_dfr(t5, \(id, dep, ind) { u <- run(dep, ind, "med"); tibble(claim_id = id, value = u$theta, se = u$se, se_hac = u$se_hac, se_hc1 = u$se_hc1, n = u$n) })
write_csv(r5, file.path(out_dir, "table5_longrun.csv"))

# Sensitivity: bands 2-8 and 12-20 on the three headline pairs; trailing MA
sensb <- crossing(how = c("short","med1220","ma5t"), t4[t4$r %in% c(3,5) | t4$r %in% 4,][,c("r","dep","ind")]) |>
  pmap_dfr(\(how, r, dep, ind) tibble(how, dep, ind, F = run(dep, ind, how)$F))
write_csv(sensb, file.path(out_dir, "sensitivity_bands.csv"))

# Critical values by simulation: bivariate case III, p = 4, n = 90; I(0) bound (stationary AR(1) 0.5) and I(1) bound (random walks)
sim <- function(kind, R = 4000, n = 90) {
  # null: y is a random walk (beta1 = 0, no relation); x is I(0) (AR 0.5) for the lower bound, I(1) for the upper bound
  f <- function() { e <- matrix(rnorm(2*(n+50)), ncol = 2)
    y <- cumsum(e[,1]); x <- if (kind == "I1") cumsum(e[,2]) else as.numeric(stats::filter(e[,2], 0.5, "recursive"))
    uecm(tibble(year = 1:n, x = y[-(1:50)]), tibble(year = 1:n, x = x[-(1:50)]), 4)$F }
  quantile(replicate(R, f()), 0.95) }
cv <- c(lo = sim("I0"), up = sim("I1")); print(cv)
write_csv(tibble(bound = c("I0","I1"), cv95_sim = cv, paper = c(2.86, 4.01)), file.path(out_dir, "crit_values_sim.csv"))

# Population / other text claims from van Duin and Ross sheets
b <- "./P02_BoF10/original/Boshoff Fourie Ships/Business cycle 1652 - 1793/Van Duin en Ross.xls"
pop <- suppressMessages(read_excel(b, sheet = "Population", skip = 3, col_names = FALSE)) |>
  transmute(year = suppressWarnings(as.numeric(...1)), burgh = suppressWarnings(as.numeric(...2) + as.numeric(...3) + as.numeric(...4) + as.numeric(...5))) |> filter(!is.na(year))
pb <- \(y) pop$burgh[pop$year == y]
write_csv(pop |> filter(year %in% c(1720, 1770, 1795)), file.path(out_dir, "burghers_check.csv"))
ex <- d |> filter(year >= 1740, year <= 1780, !is.na(wheat_exports))
exshare <- 100 * sum(ex$wheat_exports) / sum(d$wheat_reaped[d$year %in% ex$year])

# results_r.csv
ids <- claims$claim_id
rr <- bind_rows(res |> select(claim_id, value, n), r5 |> select(claim_id, value, se, n)) |> mutate(status_override = NA_character_)
extra <- tribble(~claim_id, ~value, ~status_override,
  "text_p22_crit_lo", unname(cv["lo.95%"]), NA, "text_p22_crit_up", unname(cv["up.95%"]), NA,
  "text_p22_lag", 4, NA, "text_p20_short", NA, NA, "text_p20_medium", NA, NA,
  "text_p28_exports10", 10 * r5$value[r5$claim_id == "T5_r5_coef"], NA,
  "text_p29_vines10", 10 * r5$value[r5$claim_id == "T5_r7_coef"], NA,
  "text_p4_exportshare", exshare, NA,
  "text_p7_burghers1720", pb(1720), NA, "text_p7_burghers1770", pb(1770), NA, "text_p7_burghers1795", pb(1795), NA)
rr <- bind_rows(rr, extra) |> mutate(value = as.character(value))
rr$value[rr$claim_id == "text_p20_short"] <- "2-12"; rr$value[rr$claim_id == "text_p20_medium"] <- "12-40"
rr <- tibble(claim_id = ids) |> left_join(rr, by = "claim_id") |>
  mutate(source = "r", status_override = ifelse(is.na(value), "unavailable", status_override)) |>
  select(claim_id, source, value, se, n, status_override)
write_csv(rr, here("P02_BoF10","repro_r","results_r.csv"))
print(as.data.frame(rr |> filter(!grepl("^T1", claim_id))), digits = 4)
