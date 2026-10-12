# P01_BF S6 modern reanalysis: shared helpers (sourced by 01-05). Card: modern/method_card.md (frozen, d59616d).
# Data are read from ./P01_BF (A6); nothing here writes data.
suppressPackageStartupMessages({
  library(tidyverse); library(haven); library(sandwich); library(here)
})
proj <- here::here(); source(file.path(proj, "tools", "paths.R"))
root <- file.path(proj, "P01_BF")
mod  <- file.path(root, "modern"); out <- file.path(mod, "output")
dir.create(out, showWarnings = FALSE, recursive = TRUE)
SEED <- 20261011
LV   <- c("za", "cn", "eur", "id", "in", "ko", "mz", "oth_bl")        # base = Cape-born slaves
HG   <- c(eur = "H1", id = "H2-SEA", `in` = "H2-IND", mz = "H2-MOZ")   # headline groups -> row stems
B0V  <- c(eur = 51.38, id = -28.63, `in` = -20.25, mz = -21.38)        # printed T6 values (card §1)
B0_H3 <- -43.9
M_FAM <- 9; ALPHA <- 0.05
ROWS9 <- c("H1-pt", "H1-rel", "H2-SEA-pt", "H2-SEA-rel", "H2-IND-pt", "H2-IND-rel", "H2-MOZ-pt", "H2-MOZ-rel", "H3")

# ---- data ---------------------------------------------------------------------------------------------
load_raw <- function() read_dta(dpath("P01_BF", "original", "Baten Fourie", "data.dta")) |> zap_labels()
# l.1656 sample; g_orig = original coding; g = corrected coding (card §4 origin correction)
load_sample <- function(o = load_raw()) {
  o |> filter(age > 22, age < 83, !is.na(bdec), bdec >= 1650, !is.na(cyear)) |>
    mutate(origin = coalesce(origin, ""),
           g_orig = bco,
           g = case_when(origin %in% c("Kust", "Cust", "Coehin") ~ "in", origin == "Westcoast" ~ "oth_bl", TRUE ~ bco),
           g_kust = if_else(origin %in% c("Kust", "Cust"), "in", bco),
           g_west = if_else(origin == "Westcoast", "oth_bl", bco),
           g_coeh = if_else(origin == "Coehin", "in", bco),
           bdec_alt = floor((cyear - age) / 10) * 10,                    # sensitivity 10 (S5-2/F1)
           bcoh_alt = case_when(bdec_alt <= 1740 ~ 1L, bdec_alt <= 1780 ~ 2L, TRUE ~ 3L))
}

# ---- T6 model and contrasts ---------------------------------------------------------------------------
t6_frame <- function(dd, gvar = "g", fem = "female2", bd = "bdec")
  data.frame(exactage = dd$exactage, fem = dd[[fem]], age23 = dd$age23, bd = factor(dd[[bd]]),
             g = factor(dd[[gvar]], levels = LV), source = dd$source, cyear = dd$cyear)
T6_FORM <- exactage ~ fem + age23 + bd + g
t6_fit <- function(mf, method = "glm.fit", ...)
  glm(T6_FORM, family = binomial, data = mf, method = method,
      control = glm.control(epsilon = 1e-10, maxit = 100), ...)

ocols <- function(nm) grep("^g", nm, value = TRUE)
# profile x-bar^N: sample means of the non-origin regressors, origin dummies at 0
profile_N <- function(m) { x <- colMeans(model.matrix(m)); x[ocols(names(x))] <- 0; x }

# one contrast from x0 -> x1: point (x125) and log ratio, with analytic gradients
contr <- function(b, x0, x1) {
  z0 <- sum(x0 * b); z1 <- sum(x1 * b); p0 <- plogis(z0); p1 <- plogis(z1)
  list(pt = 125 * (p1 - p0), rel = log(p1) - log(p0), p0 = p0, p1 = p1,
       g_pt = 125 * (dlogis(z1) * x1 - dlogis(z0) * x0), g_rel = (1 - p1) * x1 - (1 - p0) * x0)
}
# convention "corrected" (card §3) or "published" (mfx: other origin dummies at their means)
t6_contrasts <- function(m, groups = names(HG), convention = "corrected", xN = profile_N(m)) {
  b <- coef(m); xm <- colMeans(model.matrix(m))
  map(set_names(groups), function(gr) {
    t <- paste0("g", gr)
    if (convention == "corrected") { x0 <- xN; x1 <- xN; x1[t] <- 1 }
    else { x0 <- xm; x1 <- xm; x0[t] <- 0; x1[t] <- 1 }
    x0 <- x0[names(b)]; x1 <- x1[names(b)]
    contr(b, x0, x1)
  })
}
clip_psd <- function(V) {
  e <- eigen(V, symmetric = TRUE); neg <- sum(e$values < 0)
  if (neg) V <- e$vectors %*% diag(pmax(e$values, 0)) %*% t(e$vectors)
  attr(V, "n_clipped") <- neg; attr(V, "min_eig") <- min(e$values); V
}
vcov_cr1 <- function(m, cl) { V <- vcovCL(m, cluster = cl, type = "HC1"); dn <- dimnames(V); V <- clip_psd(V); dimnames(V) <- dn; V }
# delta-method table for a list of contrasts; df = NULL -> normal reference
delta_tab <- function(cs, V, df = NULL, lvl = ALPHA / M_FAM) {
  q <- if (is.null(df)) qnorm(1 - lvl / 2) else qt(1 - lvl / 2, df)
  imap_dfr(cs, function(c, gr) {
    bind_rows(
      tibble(group = gr, scale = "pt", est = c$pt, se = sqrt(drop(t(c$g_pt) %*% V %*% c$g_pt))),
      tibble(group = gr, scale = "rel", est = c$rel, se = sqrt(drop(t(c$g_rel) %*% V %*% c$g_rel)))) |>
      mutate(p0 = c$p0, p1 = c$p1)
  }) |>
    mutate(row = paste0(HG[group], "-", scale), tstat = est / se,
           p = if (is.null(df)) 2 * pnorm(-abs(tstat)) else 2 * pt(-abs(tstat), df),
           ci_lo = est - q * se, ci_hi = est + q * se)
}

# separation (Konis LP via detectseparation): returns named vector of finite flags
sep_check <- function(mf) {
  s <- glm(T6_FORM, family = binomial, data = mf, method = detectseparation::detect_separation)
  list(outcome = s$outcome, coef = s$coefficients)
}
# which headline groups are blocked by an infinite coefficient (card §4A rule)
sep_blocked <- function(sc, groups = names(HG)) {
  inf <- names(sc$coef)[!is.finite(sc$coef)]
  if (any(!startsWith(inf, "g"))) return(set_names(rep(TRUE, length(groups)), groups))
  set_names(paste0("g", groups) %in% inf, groups)
}

# contrasts with a fixed profile for a refitted model (resampling, common rules §5)
t6_resample_est <- function(mf, xN, groups = names(HG), need_bd) {
  und <- function(why) tibble(group = groups, pt = NA_real_, rel = NA_real_, why = why)
  if (!all(need_bd %in% unique(as.character(mf$bd)))) return(und("decade level absent"))
  m <- tryCatch(suppressWarnings(t6_fit(mf)), error = function(e) NULL)
  if (is.null(m) || !m$converged) return(und("not converged"))
  cnt <- table(factor(mf$g, levels = LV))
  if (cnt["za"] == 0) return(und("no Cape-born"))
  sc <- tryCatch(sep_check(mf), error = function(e) NULL)
  if (is.null(sc)) return(und("separation check failed"))
  sb <- sep_blocked(sc, groups); nonorig <- all(sb) && any(!startsWith(names(sc$coef)[!is.finite(sc$coef)], "g"))
  b <- coef(m); xN <- xN[names(b)]
  map_dfr(groups, function(gr) {
    t <- paste0("g", gr)
    if (nonorig) return(tibble(group = gr, pt = NA_real_, rel = NA_real_, why = "separation (non-origin coefficient)"))
    if (sb[[gr]]) return(tibble(group = gr, pt = NA_real_, rel = NA_real_, why = "separation (beta_g)"))
    if (cnt[[gr]] == 0 || is.na(b[t])) return(tibble(group = gr, pt = NA_real_, rel = NA_real_, why = "group empty"))
    x1 <- xN; x1[t] <- 1; c <- contr(replace(b, is.na(b), 0), xN, x1)
    ok <- is.finite(c$pt) && is.finite(c$rel) && c$p0 > 0 && c$p1 > 0
    tibble(group = gr, pt = if (ok) c$pt else NA_real_, rel = if (ok) c$rel else NA_real_, why = if (ok) "ok" else "prediction not estimable")
  })
}

# ---- H3 ------------------------------------------------------------------------------------------------
h3_frame <- function(dd, coh = "bcoh") dd |> filter(bco == "ko", .data[[coh]] %in% 1:2) |>
  transmute(y = 125 * exactage, exactage, mid = as.integer(.data[[coh]] == 2), female2, age23, source, cyear)
h3_boot <- function(h, B, conf_int = FALSE, clustid = "source") {
  m <- lm(y ~ mid, data = h)
  dqrng::dqset.seed(SEED); set.seed(SEED)
  fwildclusterboot::boottest(m, param = "mid", clustid = clustid, B = B, type = "webb", impose_null = TRUE,
    p_val_type = "two-tailed", conf_int = conf_int, sign_level = ALPHA / M_FAM, tol = 1e-6, maxiter = 10,
    ssc = fwildclusterboot::boot_ssc(adj = TRUE, fixef.K = "none", cluster.adj = TRUE))
}
mc_near <- function(p, B) { crit <- c(ALPHA, ALPHA / (1:M_FAM)); any(abs(p - crit) <= 2 * sqrt(p * (1 - p) / B)) }

# Carter-Schnepel-Steigerwald (2017) effective number of clusters for coefficient k
g_star <- function(X, cl, k, rho) {
  XtXi <- solve(crossprod(X)); a <- XtXi[, k]
  gam <- tapply(seq_len(nrow(X)), cl, function(ix) {
    Xg <- X[ix, , drop = FALSE]; n <- length(ix)
    Om <- (1 - rho) * diag(n) + rho * matrix(1, n, n)
    drop(t(a) %*% t(Xg) %*% Om %*% Xg %*% a)
  })
  G <- length(gam); Gam <- mean((gam - mean(gam))^2) / mean(gam)^2
  G / (1 + Gam)
}

# ---- verdict ladders (card §8) -------------------------------------------------------------------------
verdict_ptrel <- function(e, b0, p, lo, hi, nt = FALSE) {
  h <- 0.5 * abs(b0); same <- e * b0 > 0; opp <- e * b0 < 0
  if (nt) return(c("not-testable", "0"))
  if (opp && p < ALPHA) return(c("overturned (reversed)", "1"))
  if (lo > -h && hi < h) return(c("overturned (credible null)", "2"))
  if (same && p < ALPHA && abs(e) >= h) return(c("confirmed", "3"))
  if (same && p < ALPHA) return(c("qualified (magnitude below half the stated value)", "4"))
  if (same) return(c("weakened", "5"))
  c("weakened (direction lost)", "6")
}
verdict_h3 <- function(p_holm, p_raw, nt = FALSE) {
  if (nt) return(c("not-testable", "0"))
  if (p_holm < ALPHA) return(c("confirmed", "1"))
  if (p_raw < ALPHA) return(c("qualified (inference-fragile)", "2"))
  c("weakened", "3")
}
b0_row <- function(row) {
  if (row == "H3") return(B0_H3)
  gr <- names(HG)[match(sub("-(pt|rel)$", "", row), HG)]
  if (endsWith(row, "-pt")) B0V[[gr]] else log(1 + B0V[[gr]] / 100)
}
