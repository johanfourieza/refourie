# P04_CF  S6 shared engine, sourced by 02_primary.R and 03_sensitivities.R (method card §3-§8, frozen 3c01885).
# Altham statistics follow do-file l.207-251 (re-implemented and validated in compare/s5_checks/s5_scenarios.R):
#   d(X, I) = sqrt(4rs * RSS) of the additive row + column model for log X, r = s = 4; the RSS of a saturated
#   two-way additive fit on a full 4x4 table equals the sum of squared double-centred log counts.
# Deming-Stephan raking follows the S5 T9 reproduction (row step, then column step), tolerance 1e-10, max 1,000.
suppressPackageStartupMessages({library(dplyr); library(sandwich); library(parallel)})

SEED <- 20261011L; B_OUT <- 4999L; B_IN <- 199L; ALPHA <- 0.05; M_TESTS <- 6L
CLAIMS <- c("I1", "I2-OR", "I2-RR", "I3-OR", "I3-RR", "I4")
B0 <- c(I1 = 19.20 - 18.78, `I2-OR` = log(1.303), `I2-RR` = log(1.30), `I3-OR` = log(1.497), `I3-RR` = log(1.497), I4 = 77.7 - 78.1)
THR <- c(I1 = 0.21, `I2-OR` = 0.132, `I2-RR` = round(0.5 * log(1.30), 3), `I3-OR` = 0.202, `I3-RR` = round(0.5 * log(1.497), 3), I4 = 5)

## ---- analysis sample (card §4.2-4.4) ----
prep <- function(d, coding = "both", include1910 = FALSE, drop_dups = FALSE) {
  x <- d
  x$sl <- x[[paste0("sl_", coding)]]; x$fl <- x[[paste0("fl_", coding)]]
  if (!include1910) x <- x[x$year <= 1909, ]
  if (drop_dups) x <- x[x$dupflag == 0, ]
  x <- x[!is.na(x$sl) & !is.na(x$fl), ]
  x <- x[stats::complete.cases(x[, c("period", "origin", "f_gen", "first_son", "prov", "clus")]), ]
  x$mob <- as.integer(x$sl != x$fl)
  x$psplit2 <- ifelse(x$period <= 2, 1L, 2L)
  # class-size share rebuilt on the analysed sample (origin_occ_group_share logic, decoded to the numeric %)
  x <- x |> group_by(period) |> mutate(np = n()) |> group_by(period, fl) |>
    mutate(share_num = round(100 * n() / np, 2)) |> ungroup() |> select(-np)
  as.data.frame(x)
}

## ---- cluster x cell count matrix: P (pre-1868), Q (post-1868), Slavery, Gold; father varies fastest ----
cell_matrix <- function(x) {
  cl <- as.integer(factor(x$clus)); G <- max(cl)
  cell <- (x$fl - 1) + 4 * (x$sl - 1) + 1
  blocks <- list(ifelse(x$psplit2 == 1, cell, NA), ifelse(x$psplit2 == 2, cell + 16, NA),
                 ifelse(x$period == 1, cell + 32, NA), ifelse(x$period == 4, cell + 48, NA))
  C <- matrix(0, G, 64)
  for (bl in blocks) { ok <- !is.na(bl); C <- C + matrix(tabulate((bl[ok] - 1) * G + cl[ok], G * 64), G, 64) }
  C
}

dfun <- function(X) { L <- log(X); R <- L - outer(rowMeans(L), colMeans(L), "+") + mean(L); sqrt(64 * sum(R^2)) }
altham_zero <- function(X) { z <- any(X == 0); if (z) X <- X + 0.5; list(X = X, z = z) }
ipf <- function(X, rt, ct, tol = 1e-10, maxit = 1000L) {
  for (it in seq_len(maxit)) {
    X <- X * rt / rowSums(X); X <- t(t(X) * ct / colSums(X))
    dev <- max(abs(rowSums(X) - rt))
    if (!is.finite(dev)) return(list(ok = FALSE, X = X, it = it))
    if (dev < tol) return(list(ok = TRUE, X = X, it = it))
  }
  list(ok = FALSE, X = X, it = maxit)
}
# statistics from a 64-vector of counts
stats64 <- function(cnt) {
  P <- matrix(cnt[1:16], 4, 4); Q <- matrix(cnt[17:32], 4, 4); S <- matrix(cnt[33:48], 4, 4); Gd <- matrix(cnt[49:64], 4, 4)
  aP <- altham_zero(P); aQ <- altham_zero(Q)
  dpi <- dfun(aP$X); dqi <- dfun(aQ$X)
  rt <- rowSums(S); ct <- colSums(S)
  r <- if (all(rt > 0) && all(ct > 0)) ipf(Gd, rt, ct) else list(ok = FALSE)
  D <- if (r$ok) 100 * (r$X[2, 2] / rt[2] - S[2, 2] / rt[2]) else NA_real_
  c(Delta = dpi - dqi, D = D, dpi = dpi, dqi = dqi, ipf_ok = as.numeric(r$ok), zero = as.numeric(aP$z || aQ$z),
    gold_ff = if (r$ok) 100 * r$X[2, 2] / rt[2] else NA_real_, slav_ff = 100 * S[2, 2] / rt[2])
}
point_altham <- function(cnt) {
  P <- matrix(cnt[1:16], 4, 4); Q <- matrix(cnt[17:32], 4, 4)
  aP <- altham_zero(P)$X; aQ <- altham_zero(Q)$X
  dpq <- dfun(aP / aQ)  # log(P/Q) double-centred = d(P,Q) (do-file l.237-239)
  F <- factor(rep(1:4, 4)); S <- factor(rep(1:4, each = 4)); T <- factor(rep(1:2, each = 16))
  m <- glm(c(aP, aQ) ~ (factor(rep(S, 2)) + factor(rep(F, 2)) + T)^2, family = poisson)
  c(dpq = dpq, g2 = m$deviance, g2_df = m$df.residual, g2_p = 1 - pchisq(m$deviance, m$df.residual), minPQ = min(P, Q))
}

## ---- family-cluster bootstrap with nested SE (card §4.5) ----
boot_one <- function(b, C, streams, B_in) {
  assign(".Random.seed", streams[[b]], envir = .GlobalEnv)
  G <- nrow(C)
  idx <- sample.int(G, G, replace = TRUE)
  so <- stats64(drop(tabulate(idx, G) %*% C))
  inn <- matrix(NA_real_, B_in, 3)
  for (j in seq_len(B_in)) {
    i2 <- idx[sample.int(G, G, replace = TRUE)]
    si <- stats64(drop(tabulate(i2, G) %*% C)); inn[j, ] <- si[c("Delta", "D", "zero")]
  }
  c(so[c("Delta", "D", "ipf_ok", "zero")], se_Delta = sd(inn[, 1]), se_D = sd(inn[, 2], na.rm = TRUE),
    n_in_D = sum(!is.na(inn[, 2])), inner_ipf_fail = sum(is.na(inn[, 2])), inner_zero = sum(inn[, 3]))
}
make_streams <- function(n, seed = SEED) {
  old <- RNGkind()[1]; RNGkind("L'Ecuyer-CMRG"); set.seed(seed)
  s <- vector("list", n); s[[1]] <- .Random.seed
  for (i in seq_len(n)[-1]) s[[i]] <- nextRNGStream(s[[i - 1]])
  RNGkind(old); s
}
run_boot <- function(C, B = B_OUT, B_in = B_IN, ncores = max(1L, min(30L, detectCores() - 2L))) {
  streams <- make_streams(B)
  cl <- makeCluster(ncores); on.exit(stopCluster(cl))
  clusterExport(cl, c("stats64", "dfun", "altham_zero", "ipf"), envir = environment(stats64))
  t0 <- Sys.time()
  res <- parLapply(cl, seq_len(B), boot_one, C = C, streams = streams, B_in = B_in)
  attr_rt <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
  out <- as.data.frame(do.call(rbind, res)); attr(out, "minutes") <- attr_rt; out
}

## percentile-t interval, two-sided p (inversion), TOST
pt_summary <- function(theta, bt, se_star, a_ci = ALPHA / M_TESTS, tost_band = NULL) {
  ok <- is.finite(bt) & is.finite(se_star) & se_star > 0
  bt <- bt[ok]; se_star <- se_star[ok]; Bv <- length(bt)
  se_hat <- sd(bt)  # first-level bootstrap SE of the original estimate
  ts <- (bt - theta) / se_star  # studentised with the nested-bootstrap SE of each draw
  q <- function(p) unname(quantile(ts, p, type = 6))
  t0 <- theta / se_hat
  p2 <- min(1, 2 * min(1 + sum(ts >= t0), 1 + sum(ts <= t0)) / (Bv + 1))
  r <- data.frame(estimate = theta, se = se_hat, ci_lo = theta - q(1 - a_ci / 2) * se_hat, ci_hi = theta - q(a_ci / 2) * se_hat,
                  ci95_lo = theta - q(0.975) * se_hat, ci95_hi = theta - q(0.025) * se_hat, p_raw = p2, B_used = Bv)
  if (!is.null(tost_band)) {
    pL <- (1 + sum(ts >= (theta + tost_band) / se_hat)) / (Bv + 1)
    pU <- (1 + sum(ts <= (theta - tost_band) / se_hat)) / (Bv + 1)
    r$p_tost_lower <- pL; r$p_tost_upper <- pU; r$p_tost <- max(pL, pU); r$p_diff0 <- p2; r$p_raw <- max(pL, pU)
  }
  r
}

## ---- regressions with father CR1 (card §4.5) ----
RHS1 <- "factor(period) + factor(origin) + I(f_gen == 1) + factor(first_son) + factor(prov)"
fit_reg <- function(x, model = 3, type = c("OR", "RR"), term = "factor(period)4", a_ci = ALPHA / M_TESTS) {
  type <- match.arg(type)
  rhs <- switch(as.character(model), `1` = RHS1, `2` = paste(RHS1, "+ factor(fl)"), `3` = paste(RHS1, "+ share_num + factor(fl)"))
  f <- as.formula(paste("mob ~", rhs))
  r <- tryCatch({
    m <- if (type == "OR") glm(f, family = binomial, data = x) else
      glm(f, family = poisson(link = "log"), data = x, control = glm.control(maxit = 200))
    if (!m$converged) stop("no convergence")
    V <- vcovCL(m, cluster = ~clus, type = "HC1")
    est <- unname(coef(m)[term]); se <- sqrt(V[term, term]); z <- est / se; zc <- qnorm(1 - a_ci / 2)
    data.frame(estimate = est, se = se, ci_lo = est - zc * se, ci_hi = est + zc * se, ci95_lo = est - 1.96 * se,
               ci95_hi = est + 1.96 * se, p_raw = 2 * pnorm(-abs(z)), B_used = NA, n_obs = nobs(m), n_clusters = n_distinct(x$clus))
  }, error = function(e) data.frame(estimate = NA, se = NA, ci_lo = NA, ci_hi = NA, ci95_lo = NA, ci95_hi = NA, p_raw = NA,
                                    B_used = NA, n_obs = nrow(x), n_clusters = n_distinct(x$clus), note = conditionMessage(e)))
  r
}

## ---- all six claims for one sample ----
run_claims <- function(x, label, B = B_OUT, B_in = B_IN) {
  C <- cell_matrix(x); pt <- stats64(colSums(C)); pa <- point_altham(colSums(C))
  bs <- run_boot(C, B, B_in)
  sI1 <- pt_summary(pt[["Delta"]], bs$Delta, bs$se_Delta)
  sI4 <- pt_summary(pt[["D"]], ifelse(bs$ipf_ok == 1, bs$D, NA), bs$se_D, tost_band = THR[["I4"]])
  nob <- nrow(x); ncl <- n_distinct(x$clus)
  res <- bind_rows(
    cbind(claim = "I1", sI1, n_obs = nob, n_clusters = ncl),
    cbind(claim = "I2-OR", fit_reg(x, 3, "OR", "factor(period)4")),
    cbind(claim = "I2-RR", fit_reg(x, 3, "RR", "factor(period)4")),
    cbind(claim = "I3-OR", fit_reg(x, 1, "OR", "I(f_gen == 1)TRUE")),
    cbind(claim = "I3-RR", fit_reg(x, 1, "RR", "I(f_gen == 1)TRUE")),
    cbind(claim = "I4", sI4, n_obs = nob, n_clusters = ncl))
  res$p_holm <- p.adjust(res$p_raw, method = "holm"); res$sample <- label
  extra <- data.frame(sample = label, quantity = c("d(P,I)", "d(Q,I)", "d(P,Q)", "d(P,Q) G2", "d(P,Q) G2 df", "d(P,Q) G2 p (model-based, unclustered)",
                                                    "min cell P,Q", "Slavery farmer->farmer %", "Gold farmer->farmer % (Slavery margins)"),
                      value = c(pt[["dpi"]], pt[["dqi"]], pa[["dpq"]], pa[["g2"]], pa[["g2_df"]], pa[["g2_p"]], pa[["minPQ"]],
                                pt[["slav_ff"]], pt[["gold_ff"]]))
  cat(label, "bootstrap minutes:", round(attr(bs, "minutes"), 1), "\n")
  fails <- data.frame(sample = label, B_outer = B, B_inner = B_in,
                      outer_ipf_fail = sum(bs$ipf_ok == 0), outer_zero_cell_adj = sum(bs$zero),
                      inner_ipf_fail = sum(bs$inner_ipf_fail), inner_zero_cell_adj = sum(bs$inner_zero),
                      outer_se_invalid_I1 = sum(!is.finite(bs$se_Delta) | bs$se_Delta <= 0),
                      outer_se_invalid_I4 = sum(!is.finite(bs$se_D) | bs$se_D <= 0),
                      B_used_I1 = sI1$B_used, B_used_I4 = sI4$B_used)
  list(res = res, extra = extra, fails = fails)
}

cluster_diag <- function(x, label) {
  sz <- as.integer(table(x$clus))
  data.frame(sample = label, n_obs = nrow(x), n_clusters = length(sz), n_singletons = sum(sz == 1),
             n_unlinked_singletons = sum(!x$linked), mean_size = mean(sz), median_size = median(sz), max_size = max(sz),
             clusters_size_2_4 = sum(sz >= 2 & sz <= 4), clusters_size_5plus = sum(sz >= 5),
             share_obs_in_multi_son_clusters = mean(x$clus %in% as.integer(names(which(table(x$clus) > 1)))))
}

## ---- verdict tables (card §8), applied mechanically on 3-dp rounded values ----
verdict_row <- function(claim, e, lo, hi, p) {
  r3 <- function(v) round(v, 3); thr <- THR[[claim]]; b0 <- B0[[claim]]
  if (claim != "I4") {
    if (any(is.na(c(e, lo, hi, p)))) return(c("not-testable", "0: estimation fails"))
    e <- r3(e); lo <- r3(lo); hi <- r3(hi); same <- sign(e) == sign(b0)
    if (!same && p < 0.05) return(c("overturned (reversed)", "1: opposite sign to b0 and p_holm < 0.05"))
    if (lo > -thr && hi < thr) return(c("overturned (credible null)", "2: Bonferroni CI within credible-null band"))
    if (same && p < 0.05 && abs(e) >= thr) return(c("confirmed", "3: same sign, p_holm < 0.05, |e| >= threshold"))
    if (same && p < 0.05) return(c("qualified", "4: same sign, p_holm < 0.05, |e| < threshold"))
    if (same) return(c("weakened", "5: p_holm >= 0.05, same sign"))
    return(c("weakened (direction lost)", "6: p_holm >= 0.05, opposite sign"))
  }
  if (any(is.na(c(e, lo, hi, p)))) return(c("not-testable", "0: estimation fails"))
  e <- r3(e); lo <- r3(lo); hi <- r3(hi)
  if (p < 0.05) return(c("confirmed", sprintf("1: TOST rejects at Holm level (Bonferroni CI within +/-5 pp: %s)", lo > -thr && hi < thr)))
  if ((lo > 0 || hi < 0) && (lo >= thr || hi <= -thr)) return(c("overturned", "2: CI excludes 0 and lies entirely outside +/-5 pp"))
  if (lo > 0 || hi < 0) return(c("qualified (change detected, magnitude unclear)", "3: CI excludes 0, not entirely outside +/-5 pp"))
  c("weakened (inconclusive)", "4: CI includes 0, TOST does not reject")
}
