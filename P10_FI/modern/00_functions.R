# P10_FI S6: shared helpers for the frozen method card (modern/method_card.md, commit 17a056d).
# Sourced by 01_-05_ scripts, which are run from the project root:
#   Rscript P10_FI/modern/01_descriptive.R   (and so on)
# Microdata are read from the S2 snapshots on D: (A6); only aggregates are written to Dropbox.
suppressPackageStartupMessages({
  library(data.table); library(sandwich); library(fwildclusterboot); library(summclust)
})
source(file.path("tools", "paths.R"))
OUT <- file.path("P10_FI", "modern", "output")
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
SEED <- 20261011
ALPHA_FAM <- 0.05 / 4                         # Bonferroni level within each family of four
QLO <- ALPHA_FAM / 2; QHI <- 1 - ALPHA_FAM / 2 # percentile points of the Bonferroni interval
FAIL_MAX <- 0.000625                          # 0.0625% failure-rate threshold (card §4 A-B)
B_BOOT <- 9999
UNION <- 0.9                                  # von Scholtz Union share, fixed external figure

# ---- data ------------------------------------------------------------------------------
# angreg from the S2 snapshot (v2018 = published vintage, or main = 2019 file), with pid attached.
# angreg = ang[year > 1910 & year < 1965] in the script, so row order matches ang filtered the same way.
load_angreg <- function(vintage = "v2018") {
  s3 <- readRDS(dpath("P10_FI", "repro_original", "_scratch", vintage, "snap_table3.rds"))
  s24 <- readRDS(dpath("P10_FI", "repro_original", "_scratch", vintage, "snap_tables24.rds"))
  a <- as.data.table(s3$angreg); g <- as.data.table(s24$ang)
  g2 <- g[year > 1910 & year < 1965]
  stopifnot(nrow(g2) == nrow(a), isTRUE(all.equal(g2$interdum, a$interdum)))
  a[, pid := g2$pid]
  a[, ilit := abs(mlit - flit)]                 # corrected literacy gap (C8)
  list(a = a, ang = g, years = as.data.table(s24$years), models = list(c1 = s3$model5, c2 = s3$model6, c3 = s3$model7, c4 = s3$model8))
}

# Descriptive universe (card §4): both races in the three-level coding, 1911-1963.
desc_universe <- function(a) {
  b <- a[!is.na(mrace) & !is.na(frace) & year >= 1911 & year <= 1963]
  b[, inter := as.integer(mrace != frace)]
  b[, inter_wn := as.integer((mrace == "White") != (frace == "White"))]   # white-nonwhite (S2)
  b[, parish := as.character(parishdum)]
  b
}

# ---- H1 count machinery -------------------------------------------------------------------
YEARS <- 1911:1963
# Parish x year count matrices; `def` picks the interracial definition.
h1_counts <- function(b, def = "inter") {
  P <- sort(unique(b$parish))
  mk <- function(x) { m <- matrix(0, length(P), length(YEARS), dimnames = list(P, YEARS))
    if (nrow(x)) { ag <- x[, .N, by = .(parish, year)]; m[cbind(match(ag$parish, P), match(ag$year, YEARS))] <- ag$N }; m }
  b2 <- copy(b); b2[, I := get(def)]
  list(P = P, N = mk(b2), I = mk(b2[I == 1]),
       WH = mk(b2[year == 1925 & mrace == "White"])[, "1925"],
       WHI = mk(b2[year == 1925 & mrace == "White" & frace != "White"])[, "1925"])
}
WIN_PRIMARY <- list(s1 = 1911:1919, L30 = 1930:1939, s3 = 1939:1948, s4 = 1949:1963)

# Quantities for a weight matrix W (rows = draws, cols = parishes; the identity row = point estimate).
# I and N can be supplied as year-level matrices directly (for year-block bootstraps).
h1_quant <- function(It, Nt, WH, WHI, win = WIN_PRIMARY) {
  sh <- function(yy) { cols <- as.character(yy); n <- rowSums(Nt[, cols, drop = FALSE]); ifelse(n > 0, 100 * rowSums(It[, cols, drop = FALSE]) / n, NA_real_) }
  s1 <- sh(win$s1); L30 <- sh(win$L30); s3 <- sh(win$s3); s4 <- sh(win$s4)
  S25 <- ifelse(WH > 0, 100 * WHI / WH, NA_real_)
  D <- s1 - s4; G <- 0.5 * s1 - s3 + 0.5 * s4
  data.table(L30 = L30, s1 = s1, s3 = s3, s4 = s4, S25 = S25, R25 = S25 / UNION, d30 = s1 - L30,
             E25 = S25 - UNION, G = G, D = D, A = s1 - s3, F = ifelse(D != 0, (s1 - s3) / D, NA_real_))
}
h1_from_W <- function(cnt, W, win = WIN_PRIMARY)
  h1_quant(W %*% cnt$I, W %*% cnt$N, as.vector(W %*% cnt$WH), as.vector(W %*% cnt$WHI), win)

# Parish-cluster bootstrap weight matrix (multiplicities), one RNG stream, seed 20261011.
parish_W <- function(P, B = B_BOOT, seed = SEED) {
  RNGkind("L'Ecuyer-CMRG"); set.seed(seed)
  idx <- matrix(sample.int(P, P * B, replace = TRUE), nrow = B)
  W <- matrix(0, B, P); for (j in seq_len(P)) W[, j] <- rowSums(idx == j)
  W
}

# Bonferroni percentile CI on defined draws, failure rate, and the Fieller-type set for F.
pct_ci <- function(x) { ok <- is.finite(x)
  c(lo = unname(quantile(x[ok], QLO, type = 7)), hi = unname(quantile(x[ok], QHI, type = 7)), fail = mean(!ok), n_def = sum(ok)) }
fieller_F <- function(A, D, grid = seq(-3, 4, by = 0.0005)) {
  ok <- is.finite(A) & is.finite(D); A <- A[ok]; D <- D[ok]
  acc <- vapply(grid, function(f) { q <- quantile(A - f * D, c(QLO, QHI), type = 7); q[1] <= 0 && q[2] >= 0 }, logical(1))
  if (!any(acc)) return(c(lo = NA, hi = NA, bounded = NA, convex = NA))
  r <- range(grid[acc]); conv <- all(acc[grid >= r[1] & grid <= r[2]])
  c(lo = r[1], hi = r[2], bounded = as.numeric(!acc[1] && !acc[length(acc)]), convex = as.numeric(conv))
}

# ---- ITS (card §4 B) ----------------------------------------------------------------------------
annual_series <- function(b, def = "inter") {
  s <- b[, .(I = sum(get(def)), N = .N), by = year][order(year)]
  s[, y := 100 * I / N]; s
}
its_design <- function(s, brk = 1949, K = 2, second = NA) {
  d <- copy(s); d[, u := (year - brk) / 10]; d[, post := as.numeric(year >= brk)]; d[, pre := 1 - post]
  X <- cbind(pre = d$pre)
  for (k in seq_len(K)) X <- cbind(X, d$pre * d$u^k)
  colnames(X)[-1] <- paste0("pre_u", seq_len(K))
  X <- cbind(X, post = d$post, post_u = d$post * d$u)
  if (!is.na(second)) X <- cbind(X, pre_d39 = d$pre * (d$year >= second), pre_d39u = d$pre * (d$year >= second) * (d$year - second) / 10)
  list(d = d, X = X)
}
# Contrast vectors for theta = a - extrapolated pre level at u = 0, dslope = (b - pre slope at u = 0)/10.
its_contrasts <- function(X, brk = 1949, second = NA) {
  cn <- colnames(X); th <- setNames(numeric(length(cn)), cn); sl <- th
  th["post"] <- 1; th["pre"] <- -1; sl["post_u"] <- 1; sl["pre_u1"] <- -1
  if (!is.na(second)) { th["pre_d39"] <- -1; th["pre_d39u"] <- -(brk - second) / 10; sl["pre_d39u"] <- -1 }
  list(theta = th, dslope = sl / 10)
}
its_fit <- function(s, brk = 1949, K = 2, w = NULL, lag = 3, second = NA, yvar = "y") {
  ds <- its_design(s, brk, K, second); y <- ds$d[[yvar]]; X <- ds$X
  m <- if (is.null(w)) lm(y ~ 0 + X) else lm(y ~ 0 + X, weights = w)
  names(m$coefficients) <- colnames(X)
  V <- NeweyWest(m, lag = lag, prewhite = FALSE, adjust = TRUE)
  cc <- its_contrasts(X, brk, second); df <- nrow(X) - ncol(X)
  est <- function(L) { e <- sum(L * coef(m)); se <- sqrt(drop(t(L) %*% V %*% L)); tt <- e / se
    c(est = e, se = se, t = tt, p = 2 * pt(-abs(tt), df), lo = e - qt(0.975, df) * se, hi = e + qt(0.975, df) * se) }
  list(m = m, X = X, y = y, theta = est(cc$theta), dslope = est(cc$dslope), df = df, cc = cc)
}
# Prais-Winsten AR(1) (iterated to convergence), conventional SEs from the transformed regression.
its_pw <- function(s, brk = 1949, K = 2) {
  ds <- its_design(s, brk, K); y <- ds$d$y; X <- ds$X; n <- length(y)
  b <- qr.coef(qr(X), y); rho <- 0
  for (it in 1:100) {
    e <- y - X %*% b; rho_new <- sum(e[-1] * e[-n]) / sum(e[-n]^2)
    ys <- c(sqrt(1 - rho_new^2) * y[1], y[-1] - rho_new * y[-n])
    Xs <- rbind(sqrt(1 - rho_new^2) * X[1, ], X[-1, ] - rho_new * X[-n, ])
    b <- qr.coef(qr(Xs), ys); if (abs(rho_new - rho) < 1e-10) { rho <- rho_new; break }; rho <- rho_new
  }
  m <- lm(ys ~ 0 + Xs); names(m$coefficients) <- colnames(X); V <- vcov(m); dimnames(V) <- list(colnames(X), colnames(X))
  cc <- its_contrasts(X); df <- n - ncol(X) - 1
  est <- function(L) { e <- sum(L * coef(m)); se <- sqrt(drop(t(L) %*% V %*% L)); tt <- e / se
    c(est = e, se = se, t = tt, p = 2 * pt(-abs(tt), df), lo = e - qt(0.975, df) * se, hi = e + qt(0.975, df) * se) }
  list(theta = est(cc$theta), dslope = est(cc$dslope), rho = rho)
}

# ---- LPM inference (card §4 C) ------------------------------------------------------------------
# Two-way WCR by parish and year; returns unadjusted p, the Bonferroni (1 - 0.05/4) CI and diagnostics.
wcr <- function(m, param, clustid = c("parishdum", "year"), bootcluster = "min", sign_level = ALPHA_FAM) {
  dqrng::dqset.seed(SEED); set.seed(SEED)
  bt <- tryCatch(boottest(m, param = param, clustid = clustid, bootcluster = bootcluster, B = B_BOOT, type = "webb",
                          impose_null = TRUE, p_val_type = "two-tailed", engine = "R",
                          ssc = boot_ssc(adj = TRUE, fixef.K = "none", cluster.adj = TRUE, cluster.df = "min"),
                          conf_int = TRUE, sign_level = sign_level, tol = 1e-6, maxiter = 10),
                 error = function(e) { message("boottest failed: ", conditionMessage(e)); NULL })
  if (is.null(bt)) return(list(ok = FALSE, p = NA, lo = NA, hi = NA, t = NA, degenerate = NA, N_G = NA))
  ci <- tryCatch(confint(bt), error = function(e) c(NA, NA))
  ok <- is.finite(pval(bt)) && all(is.finite(ci))
  list(ok = ok, p = pval(bt), lo = ci[1], hi = ci[2], t = bt$t_stat, degenerate = sum(!is.finite(bt$t_boot)), N_G = bt$N_G)
}
# Two-way CR1 fallback (card §4 C): vcovCL multi0 = FALSE, negative eigenvalues clipped, t on min(G) - 1 df.
cr1_twoway <- function(m, param, d) {
  V <- vcovCL(m, cluster = ~ parishdum + year, type = "HC1", multi0 = FALSE)
  ev <- eigen(V, symmetric = TRUE); V <- ev$vectors %*% diag(pmax(ev$values, 0)) %*% t(ev$vectors)
  dimnames(V) <- list(names(coef(m)), names(coef(m)))
  se <- sqrt(V[param, param]); G <- min(uniqueN(d$parishdum), uniqueN(d$year)); df <- G - 1
  b <- coef(m)[param]; tq <- qt(1 - ALPHA_FAM / 2, df)
  list(ok = is.finite(se) && se > 0, p = 2 * pt(-abs(b / se), df), lo = b - tq * se, hi = b + tq * se, se = se)
}
# Primary inference with failure rule.
lpm_infer <- function(m, param, d) {
  w <- wcr(m, param)
  if (isTRUE(w$ok)) return(c(w, source = "WCR two-way"))
  f <- cr1_twoway(m, param, d)
  if (!isTRUE(f$ok)) return(list(ok = FALSE, p = NA, lo = NA, hi = NA, source = "failed"))
  c(f, source = "fallback CR1 two-way")
}
# One-way CR1 with t(G-1).
cr1_oneway <- function(m, param, cl) {
  V <- vcovCL(m, cluster = cl, type = "HC1"); se <- sqrt(V[param, param]); G <- length(unique(cl)); b <- coef(m)[param]
  c(se = se, p = 2 * pt(-abs(b / se), G - 1), G = G)
}

# Model-frame rows used by an lm (rownames are angreg row indices because the data are a data.frame).
used_rows <- function(m) as.integer(rownames(model.frame(m)))
# Refit an lm formula on a data.frame (so boottest can find the data).
fit_lm <- function(f, d) { dd <- as.data.frame(d); m <- lm(f, data = dd); m$call$data <- dd; m }

# ---- LPM row machinery --------------------------------------------------------------------------
PARAM <- c(H2 = "act", H3 = "inequality")
spec_formula <- function(models, spec, corrected = FALSE) {
  f <- formula(models[[spec]]); if (corrected) f <- update(f, . ~ . - dlit + ilit); f
}
# One LPM row: estimate + primary inference (two-way WCR, CR1 fallback). infer = "primary" | custom function.
lpm_row <- function(f, d, param, infer = NULL) {
  m <- fit_lm(f, d); dd <- as.data.frame(d)[used_rows(m), ]
  r <- if (is.null(infer)) lpm_infer(m, param, dd) else infer(m, param, dd)
  list(m = m, dd = dd, est = unname(coef(m)[param]), p = unname(r$p), lo = unname(r$lo), hi = unname(r$hi),
       source = r$source, degenerate = if (is.null(r$degenerate)) NA else r$degenerate, N = nobs(m))
}
holm <- function(p) p.adjust(p, method = "holm")

# ---- Verdict tables (card §8), applied in order; returns c(verdict, rule) ---------------------------
V <- function(v, r) c(verdict = v, rule = as.character(r))
v_h130 <- function(x) if (!is.finite(x)) V("not-testable", 0) else if (x < 2.5) V("confirmed", 1) else V("qualified (threshold missed)", 2)
v_band <- function(x, lo, hi, what) if (!is.finite(x)) V("not-testable", 0) else if (x >= lo && x <= hi) V("confirmed", 1) else
  if (x < lo) V(paste0("qualified (", what, " below the stated value)"), 2) else V(paste0("qualified (", what, " above the stated value)"), 3)
v_h125s <- function(x) v_band(x, 3.24, 3.96, "share")
v_h125r <- function(x) v_band(x, 3.6, 4.4, "multiple")
v_comp <- function(lo, hi, fail) if (!is.finite(lo) || !is.finite(hi) || fail > FAIL_MAX) V("not-testable", 0) else
  if (lo > 0) V("confirmed", 1) else if (hi < 0) V("overturned (reversed)", 2) else V("weakened", 3)
v_F <- function(Dlo, Dhi, Glo, Ghi, failD, failG) {
  if (!all(is.finite(c(Dlo, Dhi, Glo, Ghi))) || failD > FAIL_MAX || failG > FAIL_MAX) return(V("not-testable", 0))
  if (Dhi < 0) return(V("overturned (share rose; F undefined)", 1))
  if (Dlo <= 0) return(V("weakened (decline not established; F unstable)", 2))
  if (Glo > 0) return(V("confirmed", 3))
  if (Ghi < 0) return(V("overturned (most of the pooled decline at or after 1949)", 4))
  V("weakened", 5)
}
v_null_E <- function(p, ph) if (!is.finite(p) || !is.finite(ph)) V("not-testable", 0) else if (ph >= 0.05 && p >= 0.05) V("confirmed", 1) else
  if (ph >= 0.05) V("qualified (inference-fragile)", 2) else V("weakened (\"loses its significance\" not supported)", 3)
v_mag_E <- function(p, ph) if (!is.finite(p) || !is.finite(ph)) V("not-testable", 0) else if (ph < 0.05) V("confirmed", 1) else
  if (p < 0.05) V("qualified (inference-fragile)", 2) else V("weakened", 3)
v_null_L <- function(ph) if (!is.finite(ph)) V("not-testable", 0) else if (ph >= 0.05) V("confirmed", 1) else
  V("weakened (a detectable coefficient)", 2)
v_mag_L <- function(b, b0, lo, hi, ph) {
  if (!all(is.finite(c(b, lo, hi, ph)))) return(V("not-testable", 0))
  h <- 0.5 * abs(b0); same <- b != 0 && sign(b) == sign(b0); opp <- b != 0 && sign(b) == -sign(b0)
  if (opp && ph < 0.05) return(V("overturned (reversed)", 1))
  if (lo >= -h && hi <= h) return(V("overturned (credible null)", 2))
  if (same && ph < 0.05 && abs(b) >= h) return(V("confirmed", 3))
  if (same && ph < 0.05) return(V("qualified", 4))
  if (same) return(V("weakened", 5))
  V("weakened (direction lost)", 6)
}
lpm_verdict <- function(row, b, b0, lo, hi, p, ph) switch(row,
  "H2-c2" = v_null_E(p, ph), "H2-c4" = , "H3-c2" = , "H3-c4" = v_mag_E(p, ph),
  "H2-c2L" = v_null_L(ph), v_mag_L(b, b0, lo, hi, ph))
