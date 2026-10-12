# P16_FvFC S6 -- 04_secondary.R: card §5D secondary outputs S-0 ... S-7 (reported; no verdicts).
# Output: output/secondary.csv, output/secondary_theil_by_year.csv

source(here::here("P16_FvFC", "modern", "00_common.R"))
C  <- readRDS(file.path(SCR, "central.rds")); hh <- C$hh; cen <- C$cen; e0 <- C$e
BC <- readRDS(file.path(SCR, "boot_central.rds")); M <- BC$M
G  <- e0$G; Gd <- M[, paste0("G_", YEARS)]
sec <- list(); add <- function(id, stat, value, L = NA, U = NA, note = "") sec[[length(sec) + 1]] <<- tibble(id, stat, value, L, U, note)

# S-0: the "maximum" in H2
o <- order(G, decreasing = TRUE)
add("S-0", "rank of G1709 in the central series", match(11, o))
add("S-0", "gap G1709 - runner-up", G[11] - G[o[o != 11][1]], note = sprintf("runner-up year %d (%.4f)", YEARS[o[o != 11][1]], G[o[o != 11][1]]))
add("S-0", "share of central draws in which 1709 has the highest Gini", mean(max.col(Gd, ties.method = "first") == 11),
    note = "bootstrap frequency, not a probability that the claim is true")
# S-1: the 1738 fall and the 1716 dip, central-bootstrap 95% percentile intervals
for (p in list(c(1738, 1709), c(1716, 1712))) {
  i <- match(p, YEARS); x <- Gd[, i[1]] - Gd[, i[2]]; ci <- pct_int(x, 0.05)
  add("S-1", sprintf("G%d - G%d", p[1], p[2]), G[i[1]] - G[i[2]], ci["L"], ci["U"])
}
# S-2: stable until 1682 -- initial-year Ginis and pairwise differences against +/-0.03 (descriptive)
for (y in INIT) add("S-2", sprintf("G%d", y), G[match(y, YEARS)])
cb <- combn(INIT, 2)
for (j in seq_len(ncol(cb))) { dd <- G[match(cb[2, j], YEARS)] - G[match(cb[1, j], YEARS)]
  add("S-2", sprintf("G%d - G%d", cb[2, j], cb[1, j]), dd, note = ifelse(abs(dd) <= 0.03, "within +/-0.03", "outside +/-0.03")) }
# S-3: "above 0.70" with slaves
add("S-3", "minimum incl-slaves Gini", min(e0$gI), note = sprintf("year %d", YEARS[which.min(e0$gI)]))
add("S-3", "years with incl-slaves Gini <= 0.70", sum(e0$gI <= 0.70))
# S-4: H4 under the A8 point reading, band [0.18, 0.22]
gap <- e0$gI - e0$gE
add("S-4", "m against [0.18, 0.22]", cen["m"], 0.18, 0.22, note = ifelse(cen["m"] >= 0.18 && cen["m"] <= 0.22, "inside", "outside"))
add("S-4", "years with g_t in [0.18, 0.22] (throughout reading)", sum(gap >= 0.18 & gap <= 0.22), note = "of 20")
# S-5: Theil T with zeros at their limiting contribution (0 log 0 = 0), whole settler sample, incl/excl slaves
theil0 <- function(y, w) { mu <- sum(w * y) / sum(w); k <- y > 0; sum(w[k] * (y[k] / mu) * log(y[k] / mu)) / sum(w) }
pa <- pca_fit(as.matrix(hh[, CORE1])); Ia <- score_shift(as.matrix(hh[, CORE1]), pa)
th <- bind_rows(lapply(YEARS, \(y) { j <- hh$year == y; yv <- Ia[j] / hh$hhsize[j]; w <- hh$hhsize[j]; ns <- sum(hh$slaves[j])
  tibble(year = y, theil_excl = theil0(yv, w), theil_incl = theil0(c(yv, rep(0, ns)), c(w, rep(1, ns)))) }))
write_csv(th, file.path(OUT, "secondary_theil_by_year.csv"))
add("S-5", "Theil T 1709 excl slaves", th$theil_excl[th$year == 1709])
add("S-5", "Theil T 1709 incl slaves (zeros at limit)", th$theil_incl[th$year == 1709])
add("S-5", "mean Theil T incl - excl over 20 years", mean(th$theil_incl - th$theil_excl))
# S-6: Phillips-Perron on the central series, Stata pperron defaults (constant, no trend, NW lags 2),
#      MacKinnon (1994) p with the corrected small-p coefficient (S5 C7: 0.038269, not 0.038269e-2)
pp <- function(y) {
  n <- length(y) - 1; yt <- y[-1]; yl <- y[-length(y)]; fit <- lm(yt ~ yl); u <- resid(fit)
  s2 <- sum(u^2) / (n - 2); se_rho <- coef(summary(fit))["yl", "Std. Error"]; q <- floor(4 * (n / 100)^(2 / 9))
  g <- sapply(0:q, \(j) sum(u[(j + 1):n] * u[1:(n - j)]) / n); lam2 <- g[1] + 2 * sum((1 - (1:q) / (q + 1)) * g[-1])
  tr <- (coef(fit)["yl"] - 1) / se_rho
  zt <- unname(sqrt(g[1] / lam2) * tr - 0.5 * (lam2 - g[1]) / sqrt(lam2) * (n * se_rho / sqrt(s2)))
  small <- c(2.1659, 1.4412, 0.038269); large <- c(1.7339, 0.93202e-1, -0.12745e-1, -0.010368e-2)
  p <- if (zt > 2.74) 1 else if (zt < -18.83) 0 else if (zt <= -1.61) pnorm(sum(small * zt^(0:2))) else pnorm(sum(large * zt^(0:3)))
  c(zt = zt, p = p, lags = q)
}
ppr <- pp(G)
add("S-6", "Phillips-Perron Z(t), central series", ppr["zt"], note = sprintf("lags %d; S5 Stata on the same series: -1.983", ppr["lags"]))
add("S-6", "MacKinnon approximate p", ppr["p"], note = "S5 Stata pperron: 0.2939")
stopifnot(abs(ppr["zt"] - (-1.983)) < 0.001, abs(ppr["p"] - 0.2939) < 0.0005)
# S-7: Table 1 raw-unit ratios w_j / sd_j relative to male slaves (farmer pooled weights)
far <- hh |> filter(farmer); pf <- pca_fit(as.matrix(far[, CORE1])); ru <- (pf$w / pf$sd) / (pf$w[1] / pf$sd[1])
for (j in seq_along(CORE1)) add("S-7", sprintf("raw-unit ratio %s / SM", CORE1[j]), ru[j], note = sprintf("PCA weight %.4f", pf$w[j]))

sec <- bind_rows(sec) |> mutate(across(c(value, L, U), as.numeric))
write_csv(sec, file.path(OUT, "secondary.csv"))
print(sec, n = 60, width = 200)
