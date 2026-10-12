# P02_BoF10 S6: shared functions (method card v3, frozen d240e89).
# uecm_chk() is compare/s5_checks/uecm_fn.R (copied verbatim as uecm_fn_s5.R) with only the card's §4 validity checks added
# and F computed in explicit Wald form on the checked fit. Same window rule, same column construction.
suppressPackageStartupMessages({library(tidyverse); library(readxl); library(mFilter); library(here)})
source(here("tools", "paths.R"))
B_DIR <- dpath("P02_BoF10", "original", "Boshoff Fourie Ships", "Business Cycle Cape Colony")
OUT <- here("P02_BoF10", "modern", "output")

# window: first to last jointly non-missing obs (uecm_fn.R); returns indices and an internal-gap flag
win <- function(Y, X) { ok <- !is.na(Y) & !is.na(X); r <- range(which(ok)); i <- r[1]:r[2]; list(i = i, gap = any(!ok[i])) }

# design of the case-III UECM, p = lag order (p - 1 lagged differences), as in uecm_fn.R; kmax fixes a common sample
design <- function(Y, X, p, kmax = p - 1) {
  n <- length(Y); k <- p - 1; dY <- diff(Y); dX <- diff(X); idx <- (kmax + 1):(n - 1)
  M <- cbind(const = 1, ylag = Y[idx], xlag = X[idx], dx0 = dX[idx])
  for (i in seq_len(k)) M <- cbind(M, dY[idx - i], dX[idx - i])
  list(y = dY[idx], X = M) }

# checked fit: validity (i)-(v) of card §4; F = Wald F for b_ylag = b_xlag = 0; theta = -b_x/b_y with OLS delta SE
fitF <- function(d, theta = FALSE) {
  X <- d$X; K <- ncol(X); n <- nrow(X); bad <- c(F = NA_real_, theta = NA_real_, se = NA_real_, n = n, valid = 0)
  if (n - K <= 0) return(bad)
  q <- qr(X); if (q$rank != K) return(bad)
  kap <- tryCatch(kappa(X, exact = FALSE), error = function(e) Inf); if (!is.finite(kap) || kap >= 1 / .Machine$double.eps) return(bad)
  b <- qr.coef(q, d$y); if (any(!is.finite(b))) return(bad)
  e <- d$y - X %*% b; s2 <- sum(e^2) / (n - K); XtXi <- chol2inv(qr.R(q)); V <- s2 * XtXi[2:3, 2:3]
  Rb <- b[2:3]; Fw <- tryCatch(drop(t(Rb) %*% solve(V, Rb)) / 2, error = function(e) NA_real_)
  if (!is.finite(Fw)) return(bad)
  out <- c(F = Fw, theta = NA_real_, se = NA_real_, n = n, valid = 1)
  if (theta) { g <- c(b[3] / b[2]^2, -1 / b[2]); out["theta"] <- -b[3] / b[2]; out["se"] <- sqrt(drop(t(g) %*% V %*% g)) }
  out }
uecm_chk <- function(Yw, Xw, p = 5, theta = FALSE, kmax = p - 1) fitF(design(Yw, Xw, p, kmax), theta)

# phase-randomised surrogate (card §4 steps 1-4); preserves mean and circular periodogram exactly
phase_sur <- function(y) {
  n <- length(y); m <- mean(y); Z <- fft(y - m); Zs <- Z; J <- floor((n - 1) / 2)
  if (J >= 1) { ph <- runif(J, 0, 2 * pi); j <- 1:J; Zs[j + 1] <- Z[j + 1] * exp(1i * ph); Zs[n - j + 1] <- Conj(Zs[j + 1]) }
  if (n %% 2 == 0) Zs[n / 2 + 1] <- sample(c(-1, 1), 1) * Z[n / 2 + 1]
  m + Re(fft(Zs, inverse = TRUE)) / n }

# IAAFT (Schreiber-Schmitz 1996): max 100 iterations, stop when the relative spectral discrepancy changes by < 1e-8
iaaft <- function(y, maxit = 100, tol = 1e-8) {
  A <- Mod(fft(y)); ys <- sort(y); s <- sample(y); dprev <- Inf; it <- 0
  repeat { it <- it + 1; S <- fft(s); s <- Re(fft(A * exp(1i * Arg(S)), inverse = TRUE)) / length(y); s <- ys[rank(s, ties.method = "first")]
    dcur <- sum((Mod(fft(s)) - A)^2) / sum(A^2); if (abs(dprev - dcur) < tol || it >= maxit) break; dprev <- dcur }
  attr(s, "disc") <- dcur; attr(s, "iter") <- it; s }

# generic surrogate test: stat_fun(b) returns c(F=..., theta=..., valid=...) for draw b; obs = observed c(F, theta)
# returns p_s, p_lo, p_hi, f, MC SE, percentiles; use = "F" or "abstheta"
pvals <- function(obs, sims, B, use = "F") {
  v <- sims[, "valid"] == 1; s <- if (use == "F") sims[v, "F"] else abs(sims[v, "theta"]); o <- if (use == "F") obs["F"] else abs(obs["theta"])
  Bd <- sum(v); f <- B - Bd; E <- sum(s >= o)
  ps <- (1 + E) / (1 + Bd); tibble(stat = unname(o), B = B, B_def = Bd, f = f, E = E, p_s = ps, p_lo = (1 + E) / (1 + B), p_hi = (1 + E + f) / (1 + B),
    mcse = sqrt(ps * (1 - ps) / Bd), q50 = quantile(s, .5), q90 = quantile(s, .9), q95 = quantile(s, .95), q99 = quantile(s, .99)) }
vrow <- function(p) ifelse(p < 0.01, 1L, ifelse(p < 0.05, 2L, 3L))

# data
read_cz <- function() suppressWarnings(read_excel(file.path(B_DIR, "causality for med freq.XLS"), 1) |> mutate(across(everything(), as.numeric)))
read_ag <- function() suppressWarnings(read_excel(file.path(B_DIR, "agricultural output data for eviews.xls"), 1) |> mutate(across(everything(), as.numeric)))
read_ships <- function() suppressMessages(read_excel(file.path(B_DIR, "ships for eviews FROM 1652.xls"), 1, col_names = FALSE, skip = 1))[, 1:2] |>
  setNames(c("year", "ships")) |> mutate(across(everything(), as.numeric)) |> filter(year %in% 1701:1793)
cfz <- function(v, pl = 12, pu = 40) { ok <- !is.na(v); out <- rep(NA_real_, length(v)); out[ok] <- cffilter(log(v[ok]), pl, pu, root = TRUE, drift = TRUE)$cycle; out }
