# P28_VFF S6 shared setup (sourced by 01-05). Card: modern/method_card.md (frozen 3c01885).
# Contains (a) a verbatim copy of the S5 Conley function (compare/s5_checks/s5_checks.R), used only to
# validate the copy against S5 output, and (b) the S6 implementation of the same estimator written on a
# precomputed kernel-weight matrix, with great-circle distances (card §4) and eigenvalue clipping.
suppressPackageStartupMessages({
  library(haven); library(dplyr); library(sandwich); library(sf)
})
ROOT <- "./P28_VFF"
source(file.path(ROOT, "..", "tools", "paths.R"))   # A6: data root on D:
ORIG <- dpath("P28_VFF", "original", "Reversal of Fortunes")
MOD  <- file.path(ROOT, "modern")
OUT  <- file.path(MOD, "output")
SCR  <- dpath("P28_VFF", "modern", "_scratch")   # A6: scratch on D:
dir.create(OUT, showWarnings = FALSE); dir.create(SCR, showWarnings = FALSE)

# ---------------- (a) verbatim copy of S5 conley_V (planar Hsiang distance) ----------------
conley_V_s5 <- function(fit, lat, lon, cutoff, kernel = c("uniform", "bartlett")) {
  kernel <- match.arg(kernel)
  X <- model.matrix(fit); e <- resid(fit); n <- nrow(X)
  meat <- matrix(0, ncol(X), ncol(X))
  for (i in seq_len(n)) {
    dist <- sqrt((111 * (lat[i] - lat))^2 + (cos(lat[i] * pi / 180) * 111 * (lon[i] - lon))^2)
    w <- as.numeric(dist <= cutoff)
    if (kernel == "bartlett") w <- w * (1 - dist / cutoff)
    meat <- meat + (X[i, ] * e[i]) %o% colSums(X * (e * w))
  }
  B <- solve(crossprod(X))
  V <- B %*% meat %*% B; V <- (V + t(V)) / 2
  list(V = V, meat = meat)
}

# ---------------- (b) S6 implementation ----------------
# Distance matrices (km)
dist_planar_s5 <- function(lat, lon) {   # S5/Hsiang planar approximation (row i scales lon by cos(lat_i))
  n <- length(lat)
  t(sapply(seq_len(n), function(i)
    sqrt((111 * (lat[i] - lat))^2 + (cos(lat[i] * pi / 180) * 111 * (lon[i] - lon))^2)))
}
dist_gc <- function(lat, lon, R = 6371.0088) {   # great-circle (haversine), mean Earth radius
  p <- lat * pi / 180; l <- lon * pi / 180
  dp <- outer(p, p, "-"); dl <- outer(l, l, "-")
  a <- sin(dp / 2)^2 + outer(cos(p), cos(p)) * sin(dl / 2)^2
  a[a > 1] <- 1
  2 * R * asin(sqrt(a))
}
kernel_W <- function(D, cutoff, kernel = "bartlett") {
  W <- (D <= cutoff) * 1
  if (kernel == "bartlett") W <- W * (1 - D / cutoff)
  W
}
# Conley sandwich from X, residuals and kernel matrix W (no finite-sample correction).
# Meat eigenvalues clipped at 0 (card §4: non-PSD handled by clipping).
conley_from_W <- function(X, e, W, clip = TRUE) {
  S <- X * e
  meat <- crossprod(S, W %*% S); meat <- (meat + t(meat)) / 2
  min_eig <- min(eigen(meat, symmetric = TRUE, only.values = TRUE)$values)
  if (clip && min_eig < 0) {
    ee <- eigen(meat, symmetric = TRUE); ee$values[ee$values < 0] <- 0
    meat <- ee$vectors %*% diag(ee$values, length(ee$values)) %*% t(ee$vectors)
  }
  B <- solve(crossprod(X))
  V <- B %*% meat %*% B; V <- (V + t(V)) / 2
  dimnames(V) <- list(colnames(X), colnames(X))
  list(V = V, min_eig_meat = min_eig, clipped = clip && min_eig < 0)
}
conley_fit <- function(fit, W, clip = TRUE) conley_from_W(model.matrix(fit), resid(fit), W, clip)

# ---------------- data and centroids ----------------
load_data <- function() {
  d <- zap_labels(read_dta(file.path(ORIG, "data.dta"))) |> as.data.frame()
  stopifnot(nrow(d) == 138, all(d$sample == 1))
  d
}
polygon_centroids <- function() {
  shp <- st_read(file.path(ORIG, "1911_dc.shp"), quiet = TRUE)
  stopifnot(st_crs(shp)$input == "WGS 84")
  cen <- suppressWarnings(st_coordinates(st_centroid(st_geometry(shp))))
  data.frame(id = shp$ID, lon_c = cen[, 1], lat_c = cen[, 2])
}
attach_centroids <- function(d) {
  cen <- polygon_centroids()
  d <- left_join(d, cen, by = "id")
  miss <- sum(is.na(d$lat_c))
  if (miss > 0) message("Dropping ", miss, " districts without centroid (card §6)")
  attr(d, "n_no_centroid") <- miss
  d[!is.na(d$lat_c), ]
}

# ---------------- Step 0 decision ----------------
step0_decision <- function() {
  f <- file.path(OUT, "step0.csv")
  if (!file.exists(f)) return("unresolved")
  s <- read.csv(f); s$value[s$item == "decision"]
}
# outcome used for the "Lights2011" claims under the Step 0 decision
lights2011_var <- function(dec) if (dec == "relabel") "l_lights96" else "l_lights11"
lights1996_var <- function(dec) if (dec == "relabel") "l_lights11" else "l_lights96"

# ---------------- headline specifications (analysis Dec 2018.do; claims.csv) ----------------
specs <- function(dec) {
  L11 <- lights2011_var(dec)
  list(
    T2_r2_c6  = list(y = "l_pop2011", x = c("l_pop1911", "p_homeland"), v = "l_pop1911", pub = 0.950, fam = "I1"),
    T2_r2_c7  = list(y = "l_pop2011", x = c("l_pop1911", "p_homeland", "tri", "rain_level"), v = "l_pop1911", pub = 0.823, fam = "I1"),
    T3_r2_c1  = list(y = "l_u1996",   x = c("l_pop1911", "p_homeland"), v = "p_homeland", pub = 0.522, fam = "I2"),
    T3_r2_c6  = list(y = "l_u2011",   x = c("l_pop1911", "p_homeland", "tri", "rain_level"), v = "p_homeland", pub = 0.227, fam = "I2"),
    T3_r2_c9  = list(y = L11,         x = c("l_pop1911", "p_homeland"), v = "p_homeland", pub = -2.402, fam = "I2"),
    T3_r2_c10 = list(y = L11,         x = c("l_pop1911", "p_homeland", "tri", "rain_level"), v = "p_homeland", pub = -2.025, fam = "I2")
  )
}
fml <- function(s, x = s$x) reformulate(x, response = s$y)
CUTOFF <- 100
SEED <- 20261011

# ---------------- Kelly (2019) spatial-noise placebo ----------------
cov_model <- function(D, sigma2, rho, tau2, family = "exponential") {
  C <- if (family == "exponential") sigma2 * exp(-D / rho) else {
    a <- sqrt(3) * D / rho; sigma2 * (1 + a) * exp(-a) }        # Matern nu = 1.5
  diag(C) <- diag(C) + tau2
  C
}
# ML fit of C(h) = sigma2 * k(h / rho) + tau2 * 1[h = 0] to a zero-mean residual series; rho in [1, 2000] km.
fit_cov_ml <- function(r, D, family = "exponential") {
  nll <- function(p) {
    C <- cov_model(D, exp(p[1]), p[2], exp(p[3]), family)
    L <- tryCatch(chol(C), error = function(e) NULL)
    if (is.null(L)) return(1e10)
    z <- backsolve(L, r, transpose = TRUE)
    sum(log(diag(L))) + 0.5 * sum(z^2)
  }
  v <- var(r); best <- NULL
  for (rho0 in c(25, 100, 400, 1500)) for (sh in c(0.2, 0.5, 0.8)) {
    o <- tryCatch(optim(c(log(sh * v), rho0, log((1 - sh) * v)), nll, method = "L-BFGS-B",
                        lower = c(log(v) - 15, 1, log(v) - 15), upper = c(log(v) + 5, 2000, log(v) + 5)),
                  error = function(e) NULL)
    if (!is.null(o) && (is.null(best) || o$value < best$value)) best <- o
  }
  ok <- !is.null(best) && best$convergence == 0 && best$value < 1e9
  list(ok = ok, method = "ML", sigma2 = exp(best$par[1]), rho = best$par[2], tau2 = exp(best$par[3]),
       nll = best$value, convergence = if (is.null(best)) NA else best$convergence, message = if (is.null(best)) "" else best$message)
}
# Fallback (card §4): weighted least-squares fit to the empirical semivariogram.
fit_cov_variogram <- function(r, D, family = "exponential", nbins = 15, maxd = 600) {
  ut <- upper.tri(D); h <- D[ut]; g <- 0.5 * outer(r, r, "-")[ut]^2
  br <- seq(0, maxd, length.out = nbins + 1); bin <- cut(h, br)
  hb <- tapply(h, bin, mean); gb <- tapply(g, bin, mean); nb <- tapply(h, bin, length)
  ok <- !is.na(gb)
  ss <- function(p) { s2 <- exp(p[1]); rho <- p[2]; t2 <- exp(p[3])
    k <- if (family == "exponential") exp(-hb[ok] / rho) else (1 + sqrt(3) * hb[ok] / rho) * exp(-sqrt(3) * hb[ok] / rho)
    sum(nb[ok] * (gb[ok] - (t2 + s2 * (1 - k)))^2) }
  v <- var(r)
  o <- optim(c(log(v / 2), 100, log(v / 2)), ss, method = "L-BFGS-B", lower = c(log(v) - 15, 1, log(v) - 15), upper = c(log(v) + 5, 2000, log(v) + 5))
  list(ok = o$convergence == 0, method = "variogram-LS", sigma2 = exp(o$par[1]), rho = o$par[2], tau2 = exp(o$par[3]),
       nll = NA, convergence = o$convergence, message = o$message)
}
# Placebo for one specification. The same R L'Ecuyer streams (seed 20261011) are used for every specification.
run_placebo <- function(s, data, D, W, t_obs, R = 2000, family = "exponential") {
  others <- setdiff(s$x, s$v)
  r <- resid(lm(reformulate(if (length(others)) others else "1", response = s$v), data = data))
  cf <- fit_cov_ml(r, D, family)
  if (!cf$ok) cf <- fit_cov_variogram(r, D, family)
  L <- t(chol(cov_model(D, cf$sigma2, cf$rho, cf$tau2, family)))
  X <- model.matrix(fml(s), data = data); y <- model.frame(fml(s), data = data)[[1]]
  j <- which(colnames(X) == s$v)
  RNGkind("L'Ecuyer-CMRG"); set.seed(SEED); st <- .Random.seed
  tstar <- numeric(R)
  for (k in seq_len(R)) {
    st <- parallel::nextRNGStream(st); assign(".Random.seed", st, envir = .GlobalEnv)
    X[, j] <- as.vector(L %*% rnorm(nrow(X)))
    b <- solve(crossprod(X), crossprod(X, y)); e <- as.vector(y - X %*% b)
    V <- conley_from_W(X, e, W)$V
    tstar[k] <- b[j] / sqrt(V[j, j])
  }
  RNGkind("default"); set.seed(NULL)
  p <- (1 + sum(abs(tstar) >= abs(t_obs))) / (R + 1)
  list(cov = cf, tstar = tstar, p = p, mc_se = sqrt(p * (1 - p) / R),
       q95_abs_t = unname(quantile(abs(tstar), 0.95)), share_abs_t_gt_196 = mean(abs(tstar) > 1.96))
}
