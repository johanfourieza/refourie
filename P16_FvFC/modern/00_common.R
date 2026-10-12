# P16_FvFC S6 -- 00_common.R: shared functions for the frozen method card (v3, d59616d).
# Sourced by 01_central.R ... 06_figures.R. Index, PCA and Gini definitions are copied from
# repro_r/02_analysis.R (S3, D7-D10) and compare/s5_checks/ (S5); the household build copies
# repro_r/01_clean.R (D1-D6) so that 5B/5C variants can be rebuilt from the raw workbook.

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(purrr); library(stringi); library(parallel)
})
source(here::here("tools", "paths.R"))
MOD  <- here::here("P16_FvFC", "modern")
OUT  <- file.path(MOD, "output")
dir.create(OUT, showWarnings = FALSE)
SCR  <- dscratch("P16_FvFC", "modern")                 # ./P16_FvFC/modern/_scratch
RAW  <- dpath("P16_FvFC", "original", "Wealth inequality", "Time 1663 - 1757 ----  EDITED.xls")
HHF  <- dpath("P16_FvFC", "repro_r", "data", "households.rds")

YEARS <- c(1663, 1670, 1678, 1682, 1685, 1688, 1692, 1695, 1700, 1702, 1709, 1712, 1716, 1719,
           1723, 1731, 1738, 1741, 1752, 1757)
INIT  <- c(1663, 1670, 1678, 1682)
YR18  <- YEARS[YEARS >= 1700]                            # 12 census years 1700-1757 (H4-w)
CORE1 <- c("SM", "SV", "SS", "SD", "PD", "BSTE", "SKPE", "VK", "WINGST")
CORE2 <- c("SM", "SV", "SS", "SD", "PD", "BSTE", "SKPE", "VK")
CORE3 <- c("SM", "SV", "SS", "SD", "PD", "BSTE", "SKPE", "WINGST")
SEED  <- 20261011
ALPHA <- 0.05 / 4                                        # Bonferroni over {H2-rise, H3-rise, H4, H4-w}
NWORK <- 6                                               # <= 8; shared machine

# ---- household build (copy of repro_r/01_clean.R D1-D6; seed imputation omitted: not in core 1) ----
COUNT_VARS <- c("M", "V", "S", "D", "K", "SM", "SV", "SS", "SD", "PD", "BSTE", "SKPE",
                "VK", "WINGST", "WYN", "KGS", "KGW", "RGS", "RGW", "GGS", "GGW", "SH", "PS", "DG")
read_raw <- function() readxl::read_excel(RAW, sheet = "Data", col_types = "text")
build_hh <- function(raw, decode_letters = FALSE, keep1705 = FALSE) {
  conv <- function(x) {
    v <- suppressWarnings(as.numeric(x))
    if (decode_letters) {                                # 5C item 21: A = 10 ... Z = 35 (hypothetical)
      L <- !is.na(x) & grepl("^[A-Za-z]$", trimws(x))
      v[L] <- match(toupper(trimws(x[L])), LETTERS) + 9
    }
    v
  }
  nonnum <- Reduce(`|`, lapply(COUNT_VARS, \(v) !is.na(raw[[v]]) & is.na(suppressWarnings(as.numeric(raw[[v]])))))
  hh <- raw |>
    mutate(any_nonnum = nonnum, year = as.integer(Jaar),
           across(all_of(COUNT_VARS), conv), across(all_of(COUNT_VARS), ~ replace_na(.x, 0)),
           across(c(WED, VS, FH, DS), as.integer))
  if (!keep1705) hh <- hh |> filter(year != 1705)
  hh |> mutate(farmer = (PD + BSTE + SKPE + VK + WINGST + WYN + KGS + KGW + RGS + RGW + GGS + GGW) > 0,
               slaves = SM + SV + SS + SD, hhsize = pmax(M + V + S + D, 1),
               hhsize_k = pmax(M + V + S + D + K, 1), hid = row_number())
}

# ---- cluster keys (card §4) ---------------------------------------------------------------
norm_txt <- function(x) tolower(stri_trans_general(ifelse(is.na(x), "", x), "Latin-ASCII"))
key_coarse <- function(Van, Naam) {
  v <- norm_txt(Van)
  v <- sub("[[:space:]]+(wed|weduwee)[.]?[[:space:]]*$", "", v)   # trailing widow token removed first
  v <- gsub("[^a-z]", "", v)
  n <- trimws(norm_txt(Naam))
  first <- gsub("[^a-z]", "", sub("[[:space:]].*$", "", n))
  widow_only <- grepl("^(wed|weduwee)[.]?$", n)
  first[widow_only] <- "weduwee"
  k <- paste0(v, "|", first)
  empty <- v == "" | first == ""
  k[empty] <- paste0("singleton_", seq_along(k))[empty]
  k
}
key_exact <- function(Van, Naam) {                       # 5A item 2: case-folded raw Van + full raw Naam
  k <- paste0(tolower(ifelse(is.na(Van), "", Van)), "|", tolower(ifelse(is.na(Naam), "", Naam)))
  e <- is.na(Van) | is.na(Naam) | Van == "" | Naam == ""
  k[e] <- paste0("singleton_", seq_along(k))[e]
  k
}

# ---- reference implementations (S3, verbatim) used only in the prechecks -----------------------
gini_w <- function(y, w) {
  o <- order(y); y <- y[o]; w <- w[o]
  W <- sum(w); mu <- sum(w * y) / W; C <- cumsum(w)
  sum(y * w * (2 * C - w + 1)) / (W^2 * mu) - (W + 1) / W
}

# ---- fast pipeline ----------------------------------------------------------------------------
# Gini of y with weights w within groups g (1..20); the S3 gini_w formula, vectorised.
# zeros_w: optional weight of an extra zero-valued observation per group (slaves added as
# assetless persons). One zero of weight K equals K zeros of weight 1 in this formula.
gini_grp <- function(y, w, g, zeros_w = NULL, G = 20L) {
  if (!is.null(zeros_w)) { k <- zeros_w > 0; y <- c(y, rep(0, sum(k))); w <- c(w, zeros_w[k]); g <- c(g, which(k)) }
  o <- order(g, y); y <- y[o]; w <- w[o]; g <- g[o]
  W <- tabulate_w(g, w, G); cw <- cumsum(w); off <- c(0, cumsum(W))[g]
  C <- cw - off
  num <- tabulate_w(g, y * w * (2 * C - w + 1), G); mu <- tabulate_w(g, w * y, G) / W
  out <- num / (W^2 * mu) - (W + 1) / W
  out[W == 0] <- NA_real_
  out
}
tabulate_w <- function(g, x, G) { s <- numeric(G); r <- rowsum(x, g, reorder = TRUE); s[as.integer(rownames(r))] <- r[, 1]; s }

# PCA on X (pooled sample). Returns weights/sd, or a failure code.
pca_fit <- function(X) {
  n <- nrow(X); if (n < 3) return(list(fail = "pca_error"))
  mu <- colMeans(X); sd <- sqrt(colSums((X - rep(mu, each = n))^2) / (n - 1))
  if (any(!is.finite(sd)) || any(sd == 0)) return(list(fail = "zero_sd"))
  e <- tryCatch(eigen(cor(X), symmetric = TRUE), error = function(e) NULL)
  if (is.null(e)) return(list(fail = "pca_error"))
  if (e$values[1] - e$values[2] < 1e-8) return(list(fail = "eig_gap"))
  v <- e$vectors[, 1]; if (sum(v) < 0) v <- -v
  list(fail = NA_character_, w = v, sd = sd, share1 = e$values[1] / sum(e$values))
}
score_shift <- function(X, p) { I <- as.vector(X %*% (p$w / p$sd)); m <- min(I); if (m < 0) I <- I - m; I }
# annual weights (5B item 14; Fig 2 variant): PCA within each year, zero-SD items get weight 0 (S3)
score_annual <- function(X, g) {
  I <- numeric(nrow(X)); ok <- TRUE
  for (k in unique(g)) {
    r <- which(g == k); Xk <- X[r, , drop = FALSE]
    sd <- apply(Xk, 2, sd); keep <- is.finite(sd) & sd > 0
    if (sum(keep) < 2) { I[r] <- if (sum(keep) == 1) Xk[, keep] / sd[keep] else 0; next }
    e <- eigen(cor(Xk[, keep, drop = FALSE]), symmetric = TRUE); v <- e$vectors[, 1]; if (sum(v) < 0) v <- -v
    Ik <- as.vector(Xk[, keep, drop = FALSE] %*% (v / sd[keep])); m <- min(Ik); if (m < 0) Ik <- Ik - m
    I[r] <- Ik
  }
  I
}

# Prepare a data frame for the pipeline. in_gini = FALSE marks PCA-only rows (5B item 13: 1705).
prep <- function(d, items = CORE1, key = "key") {
  if (!"in_gini" %in% names(d)) d$in_gini <- TRUE
  list(X = as.matrix(d[, items]), g = match(d$year, YEARS), year = d$year, farmer = d$farmer,
       hh = d$hhsize, hhk = d$hhsize_k, sl = d$slaves, in_gini = d$in_gini,
       cl = as.integer(factor(d[[key]])), n = nrow(d))
}

# One evaluation of every quantity on a (possibly resampled) data set, given row indices r.
# opts: fixed_far / fixed_all (fixed PCA weights; 5A item 3), annual (5B 14), unweighted (5B 17),
#       size = "hh" or "hhk" (5B 16), extras (compute the cheap central-draw variants).
NAMES_SERIES <- c("G", "gE", "gI")
evaluate <- function(P, r = seq_len(P$n), opts = list()) {
  X <- P$X[r, , drop = FALSE]; g <- P$g[r]; fa <- P$farmer[r]; ig <- P$in_gini[r]
  hs <- if (identical(opts$size, "hhk")) P$hhk[r] else P$hh[r]; sl <- P$sl[r]
  wgt <- if (isTRUE(opts$unweighted)) rep(1, length(r)) else hs
  out <- list(fail_far = NA_character_, fail_all = NA_character_)
  # farmer pipeline
  fr <- which(fa)
  if (isTRUE(opts$annual)) { If <- score_annual(X[fr, , drop = FALSE], g[fr]); pf <- list(fail = NA) }
  else {
    pf <- if (!is.null(opts$fixed_far)) opts$fixed_far else pca_fit(X[fr, , drop = FALSE])
    if (is.na(pf$fail)) If <- score_shift(X[fr, , drop = FALSE], pf)
  }
  out$fail_far <- pf$fail
  G <- rep(NA_real_, 20)
  if (is.na(pf$fail)) {
    k <- ig[fr]; yf <- If[k] / hs[fr][k]
    G <- gini_grp(yf, wgt[fr][k], g[fr][k])
    if (isTRUE(opts$extras)) {
      z <- yf > 0                                                    # 5B item 5: zero-index farmers dropped
      out$G_drop0 <- gini_grp(yf[z], wgt[fr][k][z], g[fr][k][z])
      hk <- P$hhk[r][fr][k]                                          # 5B item 16 (farmer side)
      out$G_hhk <- gini_grp(If[k] / hk, hk, g[fr][k])
      out$G_unw <- gini_grp(yf, rep(1, sum(k)), g[fr][k])            # 5B item 17 (farmer side)
      ii <- g[fr][k] %in% match(INIT, YEARS)                         # 5B item 20a: pooled 1663-1682
      out$G_poolinit <- gini_grp(yf[ii], wgt[fr][k][ii], rep(1L, sum(ii)), G = 1L)
      out$n0 <- tabulate(g[fr][k][!z], 20)
    }
    out$nf <- tabulate(g[fr][k], 20)
  } else out$nf <- tabulate(g[fr][ig[fr]], 20)
  out$G <- G
  # whole settler pipeline
  pa <- if (!is.null(opts$fixed_all)) opts$fixed_all else if (isTRUE(opts$annual)) list(fail = NA) else pca_fit(X)
  out$fail_all <- pa$fail
  gE <- gI <- rep(NA_real_, 20)
  if (is.na(pa$fail)) {
    Ia <- if (isTRUE(opts$annual)) score_annual(X, g) else score_shift(X, pa)
    k <- ig; ya <- Ia[k] / hs[k]; gk <- g[k]; ns <- tabulate_w(gk, sl[k], 20)
    gE <- gini_grp(ya, wgt[k], gk)
    gI <- gini_grp(ya, wgt[k], gk, zeros_w = ns)
    if (isTRUE(opts$extras)) {
      kf <- k & fa                                                   # 5B item 11: whole-sample weights for farmers
      out$Gwsw <- gini_grp(Ia[kf] / hs[kf], hs[kf], g[kf])
      hk <- P$hhk[r][k]
      out$gE_hhk <- gini_grp(Ia[k] / hk, hk, gk); out$gI_hhk <- gini_grp(Ia[k] / hk, hk, gk, zeros_w = ns)
      out$gE_unw <- gini_grp(ya, rep(1, sum(k)), gk); out$gI_unw <- gini_grp(ya, rep(1, sum(k)), gk, zeros_w = ns)
      nsf <- tabulate_w(gk, (sl * fa)[k], 20)                        # 5B item 18: farmers' slaves only
      out$gI_fs <- gini_grp(ya, wgt[k], gk, zeros_w = nsf)
      out$p_sl <- ns / (ns + tabulate_w(gk, wgt[k], 20))             # 5C item 26
    }
  }
  out$gE <- gE; out$gI <- gI; out$ns <- tabulate(g[ig], 20)
  out
}

# Row quantities from series.
rows_from <- function(G, gE, gI) {
  gap <- gI - gE; yy <- (YEARS - 1700) / 10
  s <- function(idx) { if (any(!is.finite(gap[idx]))) return(NA_real_); unname(coef(lm.fit(cbind(1, yy[idx]), gap[idx]))[2]) }
  i18 <- match(YR18, YEARS)
  c(G1663 = G[1], G1709 = G[11], G1757 = G[20],
    setNames(G[11] - G[match(INIT, YEARS)], paste0("d_", INIT)),
    d = G[20] - G[17], m = if (all(is.finite(gap))) mean(gap) else NA_real_, s = s(i18), s20 = s(1:20))
}
slope_fast <- function(gap, idx) { x <- (YEARS[idx] - 1700) / 10; y <- gap[idx]; sum((x - mean(x)) * (y - mean(y))) / sum((x - mean(x))^2) }

# Flatten an evaluate() result into a named vector for storage.
flatten_eval <- function(e, extras = FALSE, track = NULL) {
  v <- c(fail_far = as.numeric(match(e$fail_far, c("zero_sd", "eig_gap", "pca_error"), nomatch = 0)),
         fail_all = as.numeric(match(e$fail_all, c("zero_sd", "eig_gap", "pca_error"), nomatch = 0)),
         setNames(e$G, paste0("G_", YEARS)), setNames(e$gE, paste0("gE_", YEARS)), setNames(e$gI, paste0("gI_", YEARS)),
         setNames(e$nf, paste0("nf_", YEARS)), setNames(e$ns, paste0("ns_", YEARS)))
  if (extras) for (nm in c("G_drop0", "G_hhk", "G_unw", "Gwsw", "gE_hhk", "gI_hhk", "gE_unw", "gI_unw", "gI_fs"))
    v <- c(v, setNames(if (is.null(e[[nm]])) rep(NA_real_, 20) else e[[nm]], paste0(nm, "_", YEARS)))
  if (extras) v <- c(v, G_poolinit = if (is.null(e$G_poolinit)) NA_real_ else e$G_poolinit)
  if (!is.null(track)) v <- c(v, track)
  v
}

# ---- bootstrap driver --------------------------------------------------------------------------
# Per-draw L'Ecuyer streams: draw b always uses stream b from SEED, so a 39,999 run contains the
# 9,999 run as a prefix and results do not depend on the number of workers.
make_streams <- function(B, seed = SEED) {
  RNGkind("L'Ecuyer-CMRG"); set.seed(seed); s <- .Random.seed
  st <- vector("list", B); for (b in seq_len(B)) { st[[b]] <- s; s <- nextRNGStream(s) }
  st
}
# design: "cluster" (equal-probability clusters, all rows of a cluster in every year) or
#         "within_year" (independent household resampling within year, n_t fixed; 5A item 1)
run_boot <- function(P, draws, streams, design = "cluster", opts = list(), extras = FALSE,
                     track_rows = NULL, label = "boot") {
  cl_rows <- split(seq_len(P$n), P$cl); nC <- length(cl_rows)
  yr_rows <- split(seq_len(P$n), P$g)
  worker <- function(bs) {
    lapply(bs, function(b) {
      assign(".Random.seed", streams[[b]], envir = globalenv())
      r <- if (design == "cluster") unlist(cl_rows[sample.int(nC, nC, replace = TRUE)], use.names = FALSE)
           else unlist(lapply(yr_rows, \(x) x[sample.int(length(x), length(x), replace = TRUE)]), use.names = FALSE)
      e <- tryCatch(evaluate(P, r, c(opts, list(extras = extras))),
                    error = function(err) list(fail_far = "pca_error", fail_all = "pca_error",
                                               G = rep(NA, 20), gE = rep(NA, 20), gI = rep(NA, 20), nf = rep(NA, 20), ns = rep(NA, 20)))
      tr <- if (!is.null(track_rows)) setNames(tabulate(match(r, track_rows), length(track_rows)), paste0("trk_", seq_along(track_rows))) else NULL
      c(b = b, flatten_eval(e, extras, tr))
    })
  }
  chunks <- split(draws, cut(seq_along(draws), NWORK * 4, labels = FALSE))
  cl <- makeCluster(NWORK)
  on.exit(stopCluster(cl))
  clusterEvalQ(cl, { suppressPackageStartupMessages(library(stats)); RNGkind("L'Ecuyer-CMRG"); NULL })
  env <- environment()
  clusterExport(cl, c("P", "streams", "design", "opts", "extras", "track_rows", "cl_rows", "nC", "yr_rows"), envir = env)
  clusterExport(cl, c("evaluate", "gini_grp", "tabulate_w", "pca_fit", "score_shift", "score_annual",
                      "flatten_eval", "YEARS", "INIT"), envir = globalenv())
  t0 <- Sys.time()
  res <- parLapply(cl, chunks, worker)
  M <- do.call(rbind, unlist(res, recursive = FALSE))
  M <- M[order(M[, "b"]), , drop = FALSE]
  message(sprintf("%s: %d draws in %.1f min", label, length(draws), as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  M
}

# Row-quantity matrix from a draw matrix (prefix selects a variant: "" central, "drop0", ...).
draw_rows <- function(M, Gp = "G_", gEp = "gE_", gIp = "gI_") {
  G <- M[, paste0(Gp, YEARS), drop = FALSE]; gE <- M[, paste0(gEp, YEARS), drop = FALSE]; gI <- M[, paste0(gIp, YEARS), drop = FALSE]
  gap <- gI - gE; i18 <- match(YR18, YEARS)
  sl <- function(idx) { x <- (YEARS[idx] - 1700) / 10; xc <- (x - mean(x)) / sum((x - mean(x))^2); as.vector(gap[, idx, drop = FALSE] %*% xc) }
  cbind(G1663 = G[, 1], G1709 = G[, 11], G1757 = G[, 20],
        d_1663 = G[, 11] - G[, 1], d_1670 = G[, 11] - G[, 2], d_1678 = G[, 11] - G[, 3], d_1682 = G[, 11] - G[, 4],
        d = G[, 20] - G[, 17], m = rowMeans(gap), s = sl(i18), s20 = sl(1:20))
}
# which draws fail for each row (any needed quantity non-finite or a needed PCA failed)
ROW_NEEDS <- list(`H2-rise` = c("d_1663", "d_1670", "d_1678", "d_1682"), `H3-rise` = "d", H4 = "m", `H4-w` = "s")

# ---- intervals ---------------------------------------------------------------------------------
q7 <- function(x, p) {                       # type-7 quantile that tolerates +/-Inf
  x <- sort(unname(x)); n <- length(x); h <- (n - 1) * p + 1; lo <- floor(h); hi <- ceiling(h); f <- h - lo
  a <- x[lo]; b <- x[hi]
  if (f == 0 || a == b) return(a)
  if (!is.finite(a) || !is.finite(b)) return(if (!is.finite(a)) a else b)
  a + f * (b - a)
}
pct_int <- function(x, alpha) c(L = q7(x, alpha / 2), U = q7(x, 1 - alpha / 2))
# sup-t band (card §4): se_t = bootstrap SD over valid draws; c = (1 - alpha) quantile of the max
# studentised deviation; failed draws (rows of Dst that are NA) can be given T = +Inf (bounded).
supt_band <- function(Dst, d0, alpha, bounded = FALSE) {
  valid <- apply(Dst, 1, \(z) all(is.finite(z)))
  V <- Dst[valid, , drop = FALSE]
  se <- apply(V, 2, sd); use <- se > 0
  Tm <- if (any(use)) apply(abs(sweep(V[, use, drop = FALSE], 2, d0[use])) / rep(se[use], each = nrow(V)), 1, max) else numeric(0)
  if (bounded && any(!valid)) Tm <- c(Tm, rep(Inf, sum(!valid)))
  cc <- if (length(Tm)) q7(Tm, 1 - alpha) else 0
  L <- ifelse(use, d0 - cc * se, d0); U <- ifelse(use, d0 + cc * se, d0)
  list(L = L, U = U, se = se, c = cc, flag_se0 = !use)
}

# ---- verdict rules (card §8) -------------------------------------------------------------------
v_point <- function(G, lo, hi) {
  if (!is.finite(G)) return(c(verdict = "not-testable", rule = "0"))
  if (G >= lo && G <= hi) return(c(verdict = "confirmed", rule = "1"))
  if (G < lo) return(c(verdict = "qualified (below the stated value)", rule = "2"))
  c(verdict = "qualified (above the stated value)", rule = "3")
}
v_h2rise <- function(d, L, U, nt = FALSE) {
  if (nt || any(!is.finite(d))) return(c(verdict = "not-testable", rule = "0"))
  if (any(U < 0)) return(c(verdict = "overturned", rule = "1"))
  if (all(L > 0)) return(c(verdict = "confirmed", rule = "2"))
  if (any(L > 0) && all(d > 0)) return(c(verdict = "qualified (significant against a subset of the initial period only)", rule = "3"))
  if (!any(L > 0) && all(d > 0)) return(c(verdict = "weakened (direction holds, not significant)", rule = "4"))
  c(verdict = "weakened (direction not held for some year)", rule = "5")
}
v_a4b <- function(X, L, L95, nt = FALSE) {
  if (nt || !is.finite(X)) return(c(verdict = "not-testable", rule = "0"))
  if (X > 0 && L > 0) return(c(verdict = "confirmed", rule = "1"))
  if (X > 0 && L <= 0 && L95 > 0) return(c(verdict = "qualified (inference-fragile)", rule = "2"))
  if (X > 0 && L95 <= 0) return(c(verdict = "weakened (direction holds, not significant)", rule = "3"))
  c(verdict = "weakened (direction not held)", rule = "4")
}
v_h4 <- function(m, L, U, L95, nt = FALSE) {
  if (nt || !is.finite(m)) return(c(verdict = "not-testable", rule = "0"))
  if (-0.10 < L && U < 0.10) return(c(verdict = "weakened (credible null under A4a; A4b cap)", rule = "1"))
  if (m >= 0.10 && L > 0) return(c(verdict = "confirmed", rule = "2"))
  if (m > 0 && m < 0.10 && L > 0) return(c(verdict = "qualified (magnitude below 50% of 0.2)", rule = "3"))
  if (m > 0 && L <= 0 && L95 > 0) return(c(verdict = "qualified (inference-fragile)", rule = "4"))
  c(verdict = "weakened", rule = "5")
}
ORDER <- c("not-testable", "overturned", "weakened", "qualified", "confirmed")
weakest <- function(v) { b <- sub(" .*", "", v); v[which.min(match(b, ORDER))] }

# ---- row assessment: intervals, failure rule, Monte Carlo precision (card §4) --------------------
THR <- list(`H2-rise` = 0, `H3-rise` = 0, H4 = c(-0.10, 0, 0.10), `H4-w` = 0)
row_fail <- function(M, R, row) {
  need <- ROW_NEEDS[[row]]
  fcode <- if (row %in% c("H2-rise", "H3-rise")) M[, "fail_far"] else M[, "fail_all"]
  nonfin <- !apply(R[, need, drop = FALSE], 1, \(z) all(is.finite(z)))
  cause <- ifelse(fcode == 1, "zero_sd", ifelse(fcode == 2, "eig_gap", ifelse(fcode == 3, "pca_error",
                  ifelse(nonfin, "empty year / non-finite", "ok"))))
  list(valid = cause == "ok", cause = cause)
}
endpoints <- function(row, x, x0, alpha = ALPHA, bounded_fail = NULL) {
  # x: matrix (H2-rise, 4 cols) or vector of valid draws; bounded_fail: number of failed draws for (b)
  if (row == "H2-rise") {
    X <- if (!is.null(bounded_fail) && bounded_fail > 0) rbind(x, matrix(NA, bounded_fail, ncol(x))) else x
    b <- supt_band(X, x0, alpha, bounded = !is.null(bounded_fail))
    return(c(setNames(b$L, paste0("L_", INIT)), setNames(b$U, paste0("U_", INIT))))
  }
  if (!is.null(bounded_fail) && bounded_fail > 0) {
    lo <- c(x, rep(-Inf, bounded_fail)); hi <- c(x, rep(Inf, bounded_fail))
    return(c(L = q7(lo, alpha / 2), U = q7(hi, 1 - alpha / 2), L95 = q7(lo, 0.025), U95 = q7(hi, 0.975)))
  }
  c(L = q7(x, alpha / 2), U = q7(x, 1 - alpha / 2), L95 = q7(x, 0.025), U95 = q7(x, 0.975))
}
verdict_row <- function(row, x0, ep, nt = FALSE) {
  switch(row,
    `H2-rise` = v_h2rise(x0, ep[paste0("L_", INIT)], ep[paste0("U_", INIT)], nt),
    `H3-rise` = v_a4b(x0, ep["L"], ep["L95"], nt),
    `H4-w`    = v_a4b(x0, ep["L"], ep["L95"], nt),
    H4        = v_h4(x0, ep["L"], ep["U"], ep["L95"], nt))
}
VR_EP <- function(row) if (row == "H2-rise") c(paste0("L_", INIT), paste0("U_", INIT)) else c("L", "U", "L95")
assess_row <- function(row, M, R, cen) {
  need <- ROW_NEEDS[[row]]; f <- row_fail(M, R, row); V <- sum(f$valid); nf <- sum(!f$valid)
  x0 <- cen[need]
  xv <- if (row == "H2-rise") R[f$valid, need, drop = FALSE] else R[f$valid, need]
  ep  <- endpoints(row, xv, x0)
  epb <- endpoints(row, xv, x0, bounded_fail = nf)
  va <- verdict_row(row, x0, ep); vb <- verdict_row(row, x0, epb)
  # Monte Carlo SE: 10 batches of floor(V/10) valid draws in draw order
  nb <- floor(V / 10)
  bat <- sapply(1:10, \(j) { i <- ((j - 1) * nb + 1):(j * nb)
    endpoints(row, if (row == "H2-rise") xv[i, , drop = FALSE] else xv[i], x0) })
  mcse <- apply(bat, 1, sd) / sqrt(10)
  vre <- VR_EP(row); thr <- THR[[row]]
  flag <- sapply(vre, \(k) mcse[k] > 0.002 || any(abs(ep[k] - thr) < 2 * mcse[k]))
  list(row = row, B = nrow(M), V = V, F = nf / nrow(M), causes = table(f$cause), x0 = x0, ep = ep, epb = epb,
       va = va, vb = vb, mcse = mcse, flag = flag,
       nt_inference = (nf / nrow(M) > 0.01) || (va["verdict"] != vb["verdict"]),
       se = if (row == "H2-rise") apply(xv, 2, sd) else sd(xv),
       c = if (row == "H2-rise") supt_band(xv, x0, ALPHA)$c else NA_real_)
}
# unresolved after escalation: all 3^k joint perturbations of flagged endpoints by {-2, 0, 2} MC SE
perturb_agree <- function(a) {
  fl <- names(a$flag)[a$flag]
  if (!length(fl)) return(list(k = 0, agree = TRUE, n = 1))
  grid <- as.matrix(expand.grid(rep(list(c(-2, 0, 2)), length(fl))))
  vs <- apply(grid, 1, \(dl) { ep <- a$ep; ep[fl] <- ep[fl] + dl * a$mcse[fl]; verdict_row(a$row, a$x0, ep)["verdict"] })
  list(k = length(fl), agree = length(unique(vs)) == 1, n = nrow(grid), verdicts = unique(vs))
}
