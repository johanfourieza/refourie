# P16_FvFC S3 independent recreation -- 02_analysis.R
# PCA asset indices (pooled and annual weights), household-size-weighted Gini and
# Theil of per capita index, bootstrap 95% CIs (Fig 5c), Phillips-Perron test (fn 13).
# Inputs : D:/.../P16_FvFC/repro_r/data/households.rds (01_clean.R)
# Outputs: output/*.csv, output/table1_pca_weights.tex, results_r.csv

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(readr)
  library(kableExtra)
})
source(here::here("tools", "paths.R"))
root <- here::here("P16_FvFC", "repro_r")
out  <- file.path(root, "output")
set.seed(20100301)

hh <- readRDS(dpath("P16_FvFC", "repro_r", "data", "households.rds"))

# ---- index definitions (appendix Table 2) -----------------------------------
slv <- c("SM", "SV", "SS", "SD")
liv <- c("PD", "BSTE", "SKPE", "VK")
wpn <- c("SH", "PS", "DG")
indices <- list(
  "ST & LT" = c(slv, liv, "WINGST", "KGS", "RGS", "GGS", wpn),
  "LT"      = c(slv, liv, "WINGST", wpn),
  "Core (1)" = c(slv, liv, "WINGST"),
  "Core (2)" = c(slv, liv),
  "Core (3)" = c(slv, setdiff(liv, "VK"), "WINGST"),
  "Common"  = c(slv, wpn),
  "Slaves"  = slv)

# ---- PCA: scale by SD, do not demean; first eigenvector of correlation matrix --
pca_weights <- function(df, vars) {
  X  <- as.matrix(df[, vars])
  sd <- apply(X, 2, sd)
  keep <- sd > 0                               # annual PCA: drop items absent in a year
  w  <- setNames(rep(0, length(vars)), vars)
  e  <- eigen(cor(X[, keep, drop = FALSE]), symmetric = TRUE)
  v  <- e$vectors[, 1]
  if (sum(v) < 0) v <- -v                      # sign: positive asset loadings
  w[keep] <- v
  list(w = w, sd = ifelse(keep, sd, 1), eig = e$values, share1 = e$values[1] / sum(e$values))
}
score <- function(df, p) as.vector(as.matrix(df[, names(p$w)]) %*% (p$w / p$sd))

# ---- inequality measures (weights = persons) -----------------------------------
# Gini: replication-equivalent formula for integer weights (each household counts
# hhsize persons with the same per capita value); zeros included.
gini_w <- function(y, w) {
  o <- order(y); y <- y[o]; w <- w[o]
  W <- sum(w); mu <- sum(w * y) / W; C <- cumsum(w)
  sum(y * w * (2 * C - w + 1)) / (W^2 * mu) - (W + 1) / W
}
# Theil T = GE(1); undefined at zero, so computed over positive values (D8).
theil_w <- function(y, w) {
  k <- y > 0; y <- y[k]; w <- w[k]
  mu <- sum(w * y) / sum(w)
  sum(w * (y / mu) * log(y / mu)) / sum(w)
}

# per capita index for a sample, optionally adding slaves as 1-person zero households
ineq_by_year <- function(df, idx, incl_slaves = FALSE, size = "hhsize") {
  df |>
    mutate(pc = idx / .data[[size]], wt = .data[[size]]) |>
    group_by(year) |>
    group_modify(\(d, k) {
      y <- d$pc; w <- d$wt
      if (incl_slaves) { ns <- sum(d$slaves); y <- c(y, rep(0, ns)); w <- c(w, rep(1, ns)) }
      tibble(gini = gini_w(y, w), theil = theil_w(y, w), n_hh = nrow(d),
             n_slavehh = if (incl_slaves) sum(d$slaves) else 0L)
    }) |>
    ungroup()
}

far <- hh |> filter(farmer)

# ---- pooled PCA weights: farmers (main) and whole settler sample (Fig 3/4) ------
pca_far <- map(indices, \(v) pca_weights(far, v))
pca_all <- map(indices, \(v) pca_weights(hh, v))

pca_tab <- imap_dfr(indices, \(v, nm) bind_rows(
  tibble(index = nm, sample = "farmers", item = v, weight = pca_far[[nm]]$w,
         sd = pca_far[[nm]]$sd, share_pc1 = pca_far[[nm]]$share1),
  tibble(index = nm, sample = "whole", item = v, weight = pca_all[[nm]]$w,
         sd = pca_all[[nm]]$sd, share_pc1 = pca_all[[nm]]$share1)))
write_csv(pca_tab, file.path(out, "pca_weights_all.csv"))

# ---- Table 1: core 1 pooled weights (farmers) ----------------------------------
lab <- c(SM = "Male slaves", SV = "Female slaves", SS = "Boy slaves", SD = "Girl slaves",
         PD = "Horses", BSTE = "Cattle", SKPE = "Sheep", VK = "Pigs", WINGST = "Number of vines")
t1 <- pca_tab |> filter(index == "Core (1)") |>
  group_by(sample) |> mutate(rel = 100 * weight / weight[item == "SM"]) |> ungroup() |>
  mutate(label = lab[item])
write_csv(t1, file.path(out, "table1_pca_weights.csv"))
t1 |> filter(sample == "farmers") |>
  transmute(` ` = label, `PCA weight` = sprintf("%.4f", weight),
            `Relative to male slave (%)` = sprintf("%.2f", rel)) |>
  kbl(format = "latex", booktabs = TRUE, align = "lrr",
      caption = "PCA weights for `core 1' (pooled, farmers; R recreation)") |>
  save_kable(file.path(out, "table1_pca_weights.tex"))

# ---- inequality series ---------------------------------------------------------
series <- list()
for (nm in names(indices)) {
  series[[length(series) + 1]] <- ineq_by_year(far, score(far, pca_far[[nm]])) |>
    mutate(index = nm, weights = "pooled", sample = "farmers", slaves = "excl")
  series[[length(series) + 1]] <- ineq_by_year(hh, score(hh, pca_all[[nm]])) |>
    mutate(index = nm, weights = "pooled", sample = "whole", slaves = "excl")
  series[[length(series) + 1]] <- ineq_by_year(hh, score(hh, pca_all[[nm]]), incl_slaves = TRUE) |>
    mutate(index = nm, weights = "pooled", sample = "whole", slaves = "incl")
  # annual weights (Fig 2): PCA re-estimated within each year
  for (smp in c("farmers", "whole")) {
    base <- if (smp == "farmers") far else hh
    ann <- base |> group_by(year) |> group_modify(\(d, k) {
      p <- pca_weights(d, indices[[nm]]); tibble(hid = d$hid, idx = score(d, p))
    }) |> ungroup()
    b2 <- base |> left_join(ann |> select(hid, idx), by = "hid")
    series[[length(series) + 1]] <- ineq_by_year(b2, b2$idx) |>
      mutate(index = nm, weights = "annual", sample = smp, slaves = "excl")
  }
}
# sensitivity: household size incl. knegte; slaves of farmers only in Fig 4
c1_all <- score(hh, pca_all[["Core (1)"]])
series[[length(series) + 1]] <- ineq_by_year(far, score(far, pca_far[["Core (1)"]]), size = "hhsize_k") |>
  mutate(index = "Core (1)", weights = "pooled", sample = "farmers", slaves = "excl_hhsizeK")
hh_fs <- hh |> mutate(slaves = ifelse(farmer, slaves, 0))
series[[length(series) + 1]] <- ineq_by_year(hh_fs, c1_all, incl_slaves = TRUE) |>
  mutate(index = "Core (1)", weights = "pooled", sample = "whole", slaves = "incl_farmerslaves")
# sensitivity: Table 1 / Fig 5c with core 1 weights from the whole sample
series[[length(series) + 1]] <- ineq_by_year(far, score(far, pca_all[["Core (1)"]])) |>
  mutate(index = "Core (1)", weights = "pooled_wholesampleW", sample = "farmers", slaves = "excl")
series <- bind_rows(series)
write_csv(series, file.path(out, "inequality_series.csv"))

# ---- Fig 5c: bootstrap CI for core 1 Gini (farmers) ---------------------------
B <- 999
c1_far <- score(far, pca_far[["Core (1)"]])
far_c1 <- far |> mutate(pc = c1_far / hhsize)
boot_fixed <- far_c1 |> group_by(year) |> group_modify(\(d, k) {
  g <- replicate(B, { i <- sample.int(nrow(d), replace = TRUE); gini_w(d$pc[i], d$hhsize[i]) })
  tibble(se_boot = sd(g), p025 = unname(quantile(g, .025)), p975 = unname(quantile(g, .975)))
}) |> ungroup()

# variant: PCA weights re-estimated in each replicate (resampling within years)
B2 <- 499
yrs <- sort(unique(far$year))
rows_by_year <- split(seq_len(nrow(far)), far$year)
boot_pca <- replicate(B2, {
  i <- unlist(lapply(rows_by_year, \(r) r[sample.int(length(r), replace = TRUE)]), use.names = FALSE)
  d <- far[i, ]
  p <- pca_weights(d, indices[["Core (1)"]])
  pc <- score(d, p) / d$hhsize
  sapply(split(seq_len(nrow(d)), d$year), \(r) gini_w(pc[r], d$hhsize[r]))
})
boot_pca_se <- tibble(year = yrs, se_boot_pca = apply(boot_pca, 1, sd))

f5c <- series |> filter(index == "Core (1)", weights == "pooled", sample == "farmers", slaves == "excl") |>
  select(year, gini, n_hh) |>
  left_join(boot_fixed, by = "year") |> left_join(boot_pca_se, by = "year") |>
  mutate(ci_lo = gini - 1.96 * se_boot, ci_hi = gini + 1.96 * se_boot,
         ci_lo_pca = gini - 1.96 * se_boot_pca, ci_hi_pca = gini + 1.96 * se_boot_pca,
         sig_vs_prev = case_when(gini > lag(ci_hi) ~ "up", gini < lag(ci_lo) ~ "down", TRUE ~ "no"))
write_csv(f5c, file.path(out, "fig5c_core1_gini_ci.csv"))

# the text's specific fn-14 comparisons (p.24-26)
cmp <- \(a, b) { A <- f5c[f5c$year == a, ]; Bq <- f5c[f5c$year == b, ]
  tibble(year = a, vs = b, gini = A$gini, vs_lo = Bq$ci_lo, vs_hi = Bq$ci_hi,
         verdict = ifelse(A$gini > Bq$ci_hi, "above", ifelse(A$gini < Bq$ci_lo, "below", "inside"))) }
write_csv(bind_rows(cmp(1709, 1663), cmp(1709, 1670), cmp(1709, 1678), cmp(1709, 1682),
                    cmp(1738, 1709), cmp(1757, 1738), cmp(1716, 1712)),
          file.path(out, "fig5c_text_comparisons.csv"))

# ---- fn 13: Phillips-Perron test (Stata pperron default: constant, no trend,
# Newey-West lags int(4*(T/100)^(2/9)), Z(t), MacKinnon 1994 approximate p) -------
pperron_zt <- function(y) {
  n <- length(y) - 1
  yt <- y[-1]; yl <- y[-length(y)]
  fit <- lm(yt ~ yl)
  u <- resid(fit); k <- 2
  s2 <- sum(u^2) / (n - k)
  se_rho <- coef(summary(fit))["yl", "Std. Error"]
  q <- floor(4 * (n / 100)^(2 / 9))
  g <- sapply(0:q, \(j) sum(u[(j + 1):n] * u[1:(n - j)]) / n)
  lam2 <- g[1] + 2 * sum((1 - (1:q) / (q + 1)) * g[-1])
  tr <- (coef(fit)["yl"] - 1) / se_rho
  zt <- sqrt(g[1] / lam2) * tr - 0.5 * (lam2 - g[1]) / sqrt(lam2) * (n * se_rho / sqrt(s2))
  # MacKinnon (1994) response surface, one variable, constant ('c')
  small <- c(2.1659, 1.4412, 0.038269 * 1e-2)
  large <- c(1.7339, 0.93202 * 1e-1, -0.12745 * 1e-1, -0.010368 * 1e-2)
  p <- if (zt > 2.74) 1 else if (zt < -18.83) 0 else if (zt <= -1.61)
    pnorm(sum(small * zt^(0:2))) else pnorm(sum(large * zt^(0:3)))
  c(zt = unname(zt), p = p, lags = q, nobs = n)
}
pp <- pperron_zt(f5c$gini)
pp_trend <- tseries::pp.test(f5c$gini, type = "Z(t_alpha)")   # R default (with trend), for reference
write_csv(tibble(test = c("pperron_const_Zt", "tseries_trend_Zt"),
                 stat = c(pp["zt"], unname(pp_trend$statistic)),
                 p = c(pp["p"], pp_trend$p.value), lags = c(pp["lags"], pp_trend$parameter),
                 nobs = pp["nobs"]),
          file.path(out, "pp_test.csv"))

# ---- results_r.csv -------------------------------------------------------------
c1f  <- series |> filter(index == "Core (1)", weights == "pooled", sample == "farmers", slaves == "excl")
f4i  <- series |> filter(index == "Core (1)", weights == "pooled", sample == "whole", slaves == "incl")
f4e  <- series |> filter(index == "Core (1)", weights == "pooled", sample == "whole", slaves == "excl")
t1f  <- t1 |> filter(sample == "farmers")
gap  <- f4i$gini - f4e$gini
fy   <- \(y) f5c[f5c$year == y, ]

res <- bind_rows(
  tibble(claim_id = paste0("T1_r", 1:9, "_c1"), value = t1f$weight, n = nrow(far)),
  tibble(claim_id = paste0("T1_r", 1:9, "_c2"), value = t1f$rel,    n = nrow(far)),
  tibble(claim_id = paste0("F5c_", f5c$year), value = f5c$gini, se = f5c$se_boot, n = f5c$n_hh),
  tibble(claim_id = paste0("F4_incl_", f4i$year), value = f4i$gini, n = f4i$n_hh + f4i$n_slavehh),
  tibble(claim_id = paste0("F4_excl_", f4e$year), value = f4e$gini, n = f4e$n_hh),
  tibble(claim_id = c("text_p13_pigs", "text_p17_horse_rel", "text_p17_pig_rel",
                      "text_p23_slave_gap", "text_p24_pp_pvalue", "text_p24_gini_early",
                      "text_p26_gini_1709", "text_p26_gini_1738", "text_p26_gini_1757",
                      "text_p26_gini_initial", "text_p29_gini_inclslaves"),
         value = c(100 * mean(hh$VK > 0), t1f$rel[t1f$item == "PD"], t1f$rel[t1f$item == "VK"],
                   mean(gap), pp["p"], mean(c1f$gini[c1f$year <= 1682]),
                   fy(1709)$gini, fy(1738)$gini, fy(1757)$gini, fy(1663)$gini, min(f4i$gini)),
         se = c(NA, NA, NA, NA, NA, NA, fy(1709)$se_boot, fy(1738)$se_boot, fy(1757)$se_boot,
                fy(1663)$se_boot, NA),
         n = c(nrow(hh), nrow(far), nrow(far), NA, 20, NA, fy(1709)$n_hh, fy(1738)$n_hh,
               fy(1757)$n_hh, fy(1663)$n_hh, NA)),
  tibble(claim_id = c("text_p8_gentry_1731", "text_p11_slaveown_1to5", "text_p11_slaveown_6to10",
                      "text_p29_eng_1688", "text_p29_hol_1732", "text_p29_nspain_1780",
                      "text_p29_bihar_1807", "text_p30_sa_modern"),
         status_override = "not-attempted")) |>
  mutate(source = "r") |>
  select(claim_id, source, value, se, n, status_override)
write_csv(res, file.path(root, "results_r.csv"), na = "")

# slave-gap detail for the text claim
write_csv(tibble(year = f4i$year, gini_incl = f4i$gini, gini_excl = f4e$gini, gap = gap),
          file.path(out, "fig4_slave_gap.csv"))
cat("Done. PP p =", round(pp["p"], 4), "\n")
