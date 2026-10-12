# P09_FIM S6 shared setup (sourced by 01-05). Card: modern/method_card.md (v3, frozen at d59616d).
# Truncated-normal likelihood generalised from repro_r/02_analysis.R `trunc_fit` (read-only original):
# observation-specific truncation points (S10), interval-rounded contributions (S6), log-sigma index (S11),
# weights (S20). Analytic scores; Hessian = numerical Jacobian of the analytic score (as in repro_r).
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(numDeriv); library(mvtnorm)
})
ROOT <- "."
source(file.path(ROOT, "tools", "paths.R"))           # A6: data root on D:
P    <- "P09_FIM"
MOD  <- file.path(ROOT, P, "modern")
OUT  <- file.path(MOD, "output"); dir.create(OUT, showWarnings = FALSE)
SCR  <- dscratch(P, "modern")                          # A6: scratch on D: only
SEED <- 20261011
C0   <- 159.385                                        # card §4B truncation point (62.75 in)
H63  <- 160.02                                         # 63 inches
EPS  <- 0.001                                          # sample rule h >= c + 0.001
NDRAW_T <- 2e6                                         # card §4B: fixed Monte Carlo draws for c_T
COH  <- c("1865_1874", "1875_1884", "1885_1894", "1895_1904", "1905_1914", "1915_1920")
B0   <- c(b65 = 1.028, b15 = 1.551)                    # published col 1 (card §1)
options(warn = 1, dplyr.summarise.inform = FALSE)

load_sample <- function() readRDS(file.path(SCR, "sample_modern.rds"))

# Prepare factors with the card's references (cohort 1885-94, force WWI) and growth dummies.
prep <- function(d, coh_ref = "1885_1894") {
  d %>% mutate(cohort = relevel(droplevels(factor(as.character(cohort))), ref = coh_ref),
               force  = droplevels(factor(as.character(force), levels = c("WWI", "SAC", "CMP", "AOF", "WWII"))),
               g21 = as.numeric(age == 21), g22 = as.numeric(age == 22),
               g23 = as.numeric(age == 23), g24 = as.numeric(age == 24))
}

# Design matrix: all-zero columns (a level with no observation) are dropped and recorded (card §4B
# non-identification); any remaining rank deficiency stops the script (implementation error).
design <- function(formula, d) {
  X <- model.matrix(formula, d)
  zero <- colnames(X)[colSums(abs(X)) == 0]
  X <- X[, colSums(abs(X)) > 0, drop = FALSE]
  if (qr(X)$rank < ncol(X)) stop("rank-deficient design beyond empty levels: ", paste(colnames(X), collapse = " "))
  list(X = X, dropped = zero)
}

# ---- Truncated-normal ML -------------------------------------------------------------------------
# y: heights; X: location design; cc: truncation point(s); Z: log-sigma design (default intercept);
# L, U: interval endpoints (interval-rounded likelihood, S6) or NULL; w: weights or NULL.
tn_parts <- function(th, X, y, cc, Z, L, U) {
  k <- ncol(X); b <- th[1:k]; g <- th[-(1:k)]
  mu <- drop(X %*% b); sg <- exp(drop(Z %*% g))
  a <- (cc - mu) / sg
  lam <- exp(dnorm(a, log = TRUE) - pnorm(a, lower.tail = FALSE, log.p = TRUE))
  lS  <- pnorm(a, lower.tail = FALSE, log.p = TRUE)
  if (is.null(L)) {
    z <- (y - mu) / sg
    ll <- dnorm(z, log = TRUE) - log(sg) - lS
    gm <- (z - lam) / sg                    # d ll / d mu
    gs <- z^2 - 1 - a * lam                 # d ll / d log sigma
  } else {
    u <- (U - mu) / sg; l <- (L - mu) / sg
    # P = Phi(u) - Phi(l), computed on the upper tail for accuracy (heights lie above the mean's lower part)
    Pr <- pnorm(l, lower.tail = FALSE) - pnorm(u, lower.tail = FALSE)
    ll <- log(Pr) - lS
    gm <- (dnorm(l) - dnorm(u)) / (sg * Pr) - lam / sg
    gs <- (l * dnorm(l) - u * dnorm(u)) / Pr - a * lam
  }
  list(ll = ll, S = cbind(X * gm, Z * gs))
}

fit_tn <- function(X, y, cc, Z = NULL, L = NULL, U = NULL, w = NULL, start = NULL, polish = TRUE) {
  n <- length(y); if (is.null(Z)) Z <- matrix(1, n, 1, dimnames = list(NULL, "lnsig_cons"))
  if (is.null(w)) w <- rep(1, n)
  k <- ncol(X); q <- ncol(Z)
  if (length(cc) == 1) cc <- rep(cc, n)
  nll <- function(th) -sum(w * tn_parts(th, X, y, cc, Z, L, U)$ll)
  ngr <- function(th) -colSums(w * tn_parts(th, X, y, cc, Z, L, U)$S)
  hess <- function(th) jacobian(function(t) colSums(w * tn_parts(t, X, y, cc, Z, L, U)$S), th)
  if (is.null(start)) {
    ols <- lm.wfit(X, y, w)
    start <- c(coef(ols), log(sqrt(sum(w * ols$residuals^2) / sum(w))), rep(0, q - 1))
  }
  one <- function(p0) {
    op <- optim(p0, nll, ngr, method = "BFGS", control = list(maxit = 5000, reltol = 1e-14))
    th <- op$par
    if (polish) for (it in 1:50) {                      # Newton polish with step halving
      g <- -ngr(th); H <- hess(th)
      st <- tryCatch(solve(H, g), error = function(e) NULL); if (is.null(st)) break
      f0 <- nll(th); s <- 1
      repeat { tn <- th - s * st; if (is.finite(nll(tn)) && nll(tn) <= f0 + 1e-12) break; s <- s / 2; if (s < 1e-8) break }
      if (s < 1e-8) break
      th <- tn; if (max(abs(s * st)) < 1e-11) break
    }
    g <- -ngr(th); H <- hess(th); H <- (H + t(H)) / 2
    ev <- eigen(H, symmetric = TRUE, only.values = TRUE)$values
    list(th = th, ll = -nll(th), maxg = max(abs(g)), H = H, conv = max(abs(g)) < 1e-5 && max(ev) < 0)
  }
  f <- one(start); retried <- FALSE
  if (!f$conv) {                                         # card §4B non-convergence rule
    retried <- TRUE; set.seed(SEED)
    cand <- lapply(1:20, function(i) tryCatch(one(f$th + rnorm(length(f$th), 0, 0.1)), error = function(e) NULL))
    cand <- Filter(function(z) !is.null(z) && z$conv, cand)
    if (length(cand)) f <- cand[[which.max(sapply(cand, `[[`, "ll"))]]
  }
  pp <- tn_parts(f$th, X, y, cc, Z, L, U)
  nm <- c(colnames(X), if (q == 1) "lnsig" else paste0("lnsig_", colnames(Z)))
  names(f$th) <- nm
  Hi <- tryCatch(solve(-f$H), error = function(e) matrix(NA, length(nm), length(nm)))
  dimnames(Hi) <- list(nm, nm)
  S <- pp$S * w; colnames(S) <- nm
  list(coef = f$th, Hi = Hi, S = S, ll = f$ll, n = n, conv = f$conv, maxg = f$maxg, retried = retried, k = k)
}

V_sand <- function(f) { n <- f$n; f$Hi %*% crossprod(f$S) %*% f$Hi * n / (n - 1) }   # Stata vce(robust) for ML
V_model <- function(f) f$Hi
V_clus <- function(f, cl) {                               # CR1, Stata ML convention G/(G-1)
  Sg <- rowsum(f$S, cl); G <- nrow(Sg)
  structure(f$Hi %*% crossprod(Sg) %*% f$Hi * G / (G - 1), G = G)
}

# ---- Family T contrasts (card §4B) ----------------------------------------------------------------
T_NAMES <- c("b65", "b15", "d1", "d2", "d3", "r")
T_DEF <- list(b65 = c(cohort1865_1874 = 1), b15 = c(cohort1915_1920 = 1),
              d1 = c(cohort1865_1874 = 1, cohort1875_1884 = -1), d2 = c(cohort1875_1884 = 1),
              d3 = c(cohort1895_1904 = -1), r = c(cohort1915_1920 = 1, cohort1895_1904 = -1))
contrasts_T <- function(coef, V) {
  ok <- sapply(T_DEF, function(dd) all(names(dd) %in% names(coef)))
  Lm <- t(sapply(T_DEF[ok], function(dd) { v <- setNames(rep(0, length(coef)), names(coef)); v[names(dd)] <- dd; v }))
  if (!is.matrix(Lm)) Lm <- matrix(Lm, nrow = 1, dimnames = list(names(T_DEF)[ok], names(coef)))
  est <- drop(Lm %*% coef); Vc <- Lm %*% V[names(coef), names(coef)] %*% t(Lm)
  list(est = est, V = Vc, ok = ok, Vcoh = V[intersect(c("cohort1865_1874", "cohort1875_1884", "cohort1895_1904",
                                                        "cohort1915_1920"), names(coef)),
                                            intersect(c("cohort1865_1874", "cohort1875_1884", "cohort1895_1904",
                                                        "cohort1915_1920"), names(coef)), drop = FALSE])
}

# c_T on the independent subspace of a (possibly singular) correlation matrix: eigenvalues below
# 1e-10 * max set to zero, Z = A W with W ~ N(0, I_r), 0.95 quantile of max |Z_j| over NDRAW_T draws.
crit_sub <- function(Vc, ndraw = NDRAW_T, seed = SEED) {
  se <- sqrt(diag(Vc)); R <- Vc / outer(se, se)
  e <- eigen((R + t(R)) / 2, symmetric = TRUE)
  keep <- e$values > 1e-10 * max(e$values)
  A <- e$vectors[, keep, drop = FALSE] %*% diag(sqrt(e$values[keep]), sum(keep))
  set.seed(seed); m <- numeric(0); chunk <- 5e5
  for (i in seq_len(ceiling(ndraw / chunk))) {
    W <- matrix(rnorm(chunk * sum(keep)), chunk, sum(keep))
    m <- c(m, apply(abs(W %*% t(A)), 1, max))
  }
  m <- sort(m); p <- 0.95; n <- length(m)
  cq <- unname(quantile(m, p))
  h <- 1.96 * sqrt(n * p * (1 - p)); lo <- m[floor(n * p - h)]; hi <- m[ceiling(n * p + h)]
  list(c = cq, mcse = (hi - lo) / (2 * 1.96), ci_lo = lo, ci_hi = hi, rank = sum(keep))
}

# Family T table for a fitted model: estimates, SE, simultaneous intervals, unadjusted p, directional p.
famT <- function(coef, V, expected_rank = NULL) {
  ct <- contrasts_T(coef, V)
  se <- sqrt(pmax(diag(ct$V), 0)); se[!is.finite(se)] <- NA
  ev <- if (ncol(ct$Vcoh)) eigen(ct$Vcoh, symmetric = TRUE, only.values = TRUE)$values else 1
  sefail <- any(!is.finite(se) | se <= 0) || min(ev) <= 1e-10 * max(ev)
  cr <- if (!sefail) crit_sub(ct$V) else list(c = NA, mcse = NA, rank = NA)
  if (!is.null(expected_rank) && !is.na(cr$rank) && cr$rank > expected_rank) stop("rank of R_T exceeds ", expected_rank)
  if (!is.null(expected_rank) && !is.na(cr$rank) && cr$rank < expected_rank) sefail <- TRUE
  tibble(contrast = names(ct$est), est = ct$est, se = se, c_T = cr$c, c_T_mcse = cr$mcse, rank = cr$rank,
         lo = est - c_T * se, hi = est + c_T * se,
         p_unadj = 2 * pnorm(-abs(est / se)), p_dir = pnorm(-est / se), se_fail = sefail) %>%
    right_join(tibble(contrast = T_NAMES), by = "contrast") %>% arrange(match(contrast, T_NAMES))
}

# ---- §8B finding rules ---------------------------------------------------------------------------
find_mag <- function(b, lo, hi, b0, ok = TRUE) {
  if (!ok || any(is.na(c(b, lo, hi)))) return(c("not computable", "0"))
  if (hi < 0) return(c("reversed", "1"))
  if (lo > -0.5 * b0 && hi < 0.5 * b0) return(c("credible null", "2"))
  if (lo > 0 && b >= 0.5 * b0) return(c("supported", "3"))
  if (lo > 0) return(c("supported, below floor", "4"))
  if (b > 0) return(c("not established", "5"))
  c("not established, direction lost", "6")
}
find_rec <- function(r, lo, hi, ok = TRUE) {
  if (!ok || any(is.na(c(r, lo, hi)))) return(c("not computable", "0"))
  if (lo > 0) return(c("supported", "1")); if (hi < 0) return(c("reversed", "2"))
  if (r > 0) return(c("not established (points hold)", "3")); c("not established, direction lost", "4")
}
find_dec <- function(est, lo, hi, nm = c("d1", "d2", "d3")) {
  if (length(est) < 3 || any(is.na(c(est, lo, hi)))) return(c("not computable", "0"))
  if (any(hi < 0)) return(c(paste0("reversed (", paste(nm[hi < 0], collapse = ", "), ")"), "1"))
  if (all(lo > 0)) return(c("supported", "2"))
  if (all(est > 0)) return(c("not established (ordering holds in points)", "3"))
  c("not established, ordering broken in points", "4")
}
findings_from <- function(ft) {
  g <- function(x) ft[ft$contrast == x, ]
  b65 <- g("b65"); b15 <- g("b15"); r <- g("r"); dd <- ft[ft$contrast %in% c("d1", "d2", "d3"), ]
  sf <- isTRUE(ft$se_fail[1])
  tibble(row = c("R-65", "R-15", "R-dec", "R-rec"),
         finding = c(find_mag(b65$est, b65$lo, b65$hi, B0["b65"], !sf)[1], find_mag(b15$est, b15$lo, b15$hi, B0["b15"], !sf)[1],
                     if (sf) "not computable" else find_dec(dd$est, dd$lo, dd$hi)[1], find_rec(r$est, r$lo, r$hi, !sf)[1]),
         rule = c(find_mag(b65$est, b65$lo, b65$hi, B0["b65"], !sf)[2], find_mag(b15$est, b15$lo, b15$hi, B0["b15"], !sf)[2],
                  if (sf) "0" else find_dec(dd$est, dd$lo, dd$hi)[2], find_rec(r$est, r$lo, r$hi, !sf)[2]))
}

# Convenience: fit a formula on a data frame with truncation point c and the sample rule h >= c + EPS
# (or a supplied keep rule), returning the fit and its Family T table under a chosen vcov.
run_tn <- function(formula, d, c = C0, keep = NULL, Zf = NULL, L = NULL, U = NULL, w = NULL, vc = "sand",
                   expected_rank = NULL) {
  d <- if (is.null(keep)) d[d$height >= c + EPS, ] else d[keep(d), ]
  ds <- design(formula, d)
  Z <- if (is.null(Zf)) NULL else design(Zf, d)$X
  cc <- if (is.function(c)) c(d) else c
  Lv <- if (is.function(L)) L(d) else NULL; Uv <- if (is.function(U)) U(d) else NULL
  wv <- if (is.null(w)) NULL else d[[w]]
  f <- fit_tn(ds$X, d$height, cc, Z = Z, L = Lv, U = Uv, w = wv)
  V <- switch(vc, sand = V_sand(f), model = V_model(f))
  list(fit = f, d = d, dropped = ds$dropped, V = V, T = famT(f$coef, V, expected_rank))
}
