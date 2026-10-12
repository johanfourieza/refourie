# 00_common.R -- P21_LFG S6. Shared data and fast translog/HEC engine (method card v3, §3).
# Same estimand as repro_r/02_analysis.R (hec_year, window = 0): lm replaced by lm.fit on the same design
# so that the ~22,000 bootstrap fits run quickly; the reproduction check in 01_primary.R verifies equality.
suppressMessages({library(haven); library(dplyr); library(tidyr); library(readr); library(here)})
source(here::here("tools", "paths.R"))
MOD <- here::here("P21_LFG", "modern"); OUT <- file.path(MOD, "output")
dir.create(OUT, showWarnings = FALSE)
SCR <- dscratch("P21_LFG", "modern")

d0 <- read_dta(dpath("P21_LFG", "original", "Calumet Links", "processed.dta")) |> zap_labels()
d0$row_id <- seq_len(nrow(d0))
# §3 inputs (identical to repro_r/01_clean.R)
prep_base <- function(d) d |> mutate(lq = ifelse(!is.na(Tot_prodfl) & Tot_prodfl > 0, log(Tot_prodfl), NA_real_),
  lk = log1p(khoe), ls = log1p(slaves), lf = log1p(settlers), zk = 0, zs = 0, zf = 0)
# §5 item 1: Battese (1997) zero dummies, ln(max(x,1))
prep_zd <- function(d) d |> mutate(lq = ifelse(!is.na(Tot_prodfl) & Tot_prodfl > 0, log(Tot_prodfl), NA_real_),
  lk = log(pmax(khoe, 1)), ls = log(pmax(slaves, 1)), lf = log(pmax(settlers, 1)),
  zk = 1 * (khoe == 0), zs = 1 * (slaves == 0), zf = 1 * (settlers == 0))
# §5 item 10: the file's ordinary log variables (missing at zero)
prep_ord <- function(d) d |> mutate(lq = l_Tot_prodfl, lk = l_khoe, ls = l_slaves, lf = l_settlers, zk = 0, zs = 0, zf = 0)
est_rows <- function(d) d |> filter(year >= 1805, !is.na(lq), !is.na(lk), !is.na(ls), !is.na(lf))

YEARS <- c(1805:1807, 1809:1826, 1828); PAIRS <- c("FS", "FK", "SK")
Z_BAND <- qnorm(1 - 0.05 / (2 * 66)); Z_PT <- qnorm(1 - 0.05 / 6)

# Design matrix: intercept, lk, ls, lf, .5 squares, cross terms [, zero dummies with zeros in sample][, year dummies]
design <- function(e, dummies = FALSE, yeardum = FALSE) {
  X <- cbind(1, e$lk, e$ls, e$lf, .5 * e$lk^2, .5 * e$ls^2, .5 * e$lf^2, e$lk * e$ls, e$lk * e$lf, e$ls * e$lf)
  if (dummies) for (z in c("zk", "zs", "zf")) if (any(e[[z]] == 1)) X <- cbind(X, e[[z]])
  if (yeardum) { yy <- sort(unique(e$year)); if (length(yy) > 1) for (v in yy[-1]) X <- cbind(X, 1 * (e$year == v)) }
  X
}
# One year's fit and household HECs. e = fit rows (window already applied); ev = logical, evaluation rows.
# Returns NULL if no rows or rank deficient (§4: any NA coefficient).
hec_fit <- function(e, ev, dummies = FALSE, yeardum = FALSE, full = FALSE) {
  if (nrow(e) == 0 || !any(ev)) return(NULL)
  X <- design(e, dummies, yeardum); f <- lm.fit(X, e$lq)
  if (f$rank < ncol(X) || any(is.na(f$coefficients))) return(NULL)
  b <- f$coefficients; lk <- e$lk[ev]; ls <- e$ls[ev]; lf <- e$lf[ev]
  Mk <- b[2] + b[5] * lk + b[8] * ls + b[9] * lf
  Ms <- b[3] + b[6] * ls + b[8] * lk + b[10] * lf
  Mf <- b[4] + b[7] * lf + b[9] * lk + b[10] * ls
  H <- cbind(FS = (b[10] + Ms * Mf) / (Ms * Mf), FK = (b[9] + Mk * Mf) / (Mk * Mf), SK = (b[8] + Ms * Mk) / (Ms * Mk))
  if (full) return(list(H = H, M = cbind(Mk = Mk, Ms = Ms, Mf = Mf), b = b, f = f, X = X, y = e$lq))
  H
}
# Centre statistics of household HECs (finite only)
cstat <- function(h, stat = "median") { h <- h[is.finite(h)]; if (!length(h)) return(NA_real_)
  switch(stat, median = median(h), tmean = mean(h, trim = .05), mean = mean(h)) }
# Annual centres for all 22 years; spec: annual / window; returns 22 x 3 matrix (NA = undefined)
centres <- function(e, dummies = FALSE, window = 0, stat = "median", keep = NULL) {
  yr <- e$year; out <- matrix(NA_real_, length(YEARS), 3, dimnames = list(YEARS, PAIRS))
  for (i in seq_along(YEARS)) { t <- YEARS[i]
    w <- abs(yr - t) <= window; if (!any(w)) next
    ee <- e[w, , drop = FALSE]; H <- hec_fit(ee, ee$year == t, dummies, yeardum = window > 0)
    if (is.null(H)) next
    if (!is.null(keep)) { kp <- keep(ee[ee$year == t, , drop = FALSE]); H <- H[kp, , drop = FALSE] }
    out[i, ] <- apply(H, 2, cstat, stat = stat) }
  out
}
pooled <- function(C, drop = NULL) { ok <- !(YEARS %in% drop)
  c(F7 = median(C[ok, "FS"]), F8 = median(C[ok, "FK"]), F9 = median(C[YEARS %in% 1811:1817, "SK"])) }
# Cluster ids (§4): index; missing index = own singleton
cluster_id <- function(e) ifelse(is.na(e$index), paste0("s", e$row_id), paste0("i", e$index))
# Draw-level replicate from a cluster draw (multiplicities preserved)
replicate_rows <- function(rows_by_cl, draw) unlist(rows_by_cl[draw], use.names = FALSE)
