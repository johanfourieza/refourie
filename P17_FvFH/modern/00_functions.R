# P17_FvFH S6 -- shared functions (method card v3, §3-§4). Sourced by 01-04.
suppressPackageStartupMessages({ library(tidyverse); library(haven); library(here) })
source(here::here("tools", "paths.R"))
OUT <- here::here("P17_FvFH", "modern", "output")
SCR <- dscratch("P17_FvFH", "modern")
SRC <- c("grain", "wine", "cattle", "sheep", "pigs", "horses")
YRS <- c(1700, 1723, 1757)
cl <- read_csv(here::here("P17_FvFH", "claims", "claims.csv"), show_col_types = FALSE)
pv <- setNames(cl$reported_value, cl$claim_id)
# Table 1 prices as printed; period 1724 is used for the 1723 roll (card §3)
price_tab <- function(py) c(grain = pv[[paste0("T1_grain_", py)]], wine = pv[[paste0("T1_wine_", py)]],
  cattle = pv[[paste0("T1_cattle_", py)]], sheep = pv[[paste0("T1_sheep_", py)]],
  pigs = pv[[paste0("T1_pig_", py)]], horses = pv[[paste0("T1_horses_", py)]])
PER <- c(`1700` = 1700, `1723` = 1724, `1757` = 1757)
# Table 2 prints one burgher factor (burgher total); 1702 factors serve 1700 (DEVIATIONS D1)
WF <- c(`1700` = pv[["T2_wf_1702_burgher_total"]], `1723` = pv[["T2_wf_1723_burgher_total"]], `1757` = pv[["T2_wf_1757_burgher_total"]])

load_roll <- function() {
  o <- read_dta(dpath("P17_FvFH", "original", "Statafiles", "opgaafrolle.dta")) %>% filter(jaar %in% YRS)
  zap_labels(o) %>% mutate(across(c(m, v, s, d, kgw, rgw, cgw, wyn, bste, skpe, vk, pd), ~ replace_na(as.numeric(.), 0)))
}
# Build source incomes, n, w and the farming flag. price_year(jaar) -> Table 1 period.
build <- function(o, rate_c = 0.15, rate_h = 0.05, grain = c("kgw", "rgw", "cgw"),
                  price_year = function(j) PER[as.character(j)], wf = WF) {
  P <- t(sapply(o$jaar, function(j) price_tab(price_year(j))))
  o %>% mutate(n = m + v + s + d, w = n * wf[as.character(jaar)],
    grain = rowSums(across(all_of(grain))) * P[, "grain"], wine = wyn * P[, "wine"],
    cattle = rate_c * bste * P[, "cattle"], sheep = rate_c * skpe * P[, "sheep"],
    pigs = rate_c * vk * P[, "pigs"], horses = rate_h * pd * P[, "horses"],
    A = grain + wine + cattle + sheep + pigs + horses, farm = n > 0 & A > 0)
}
# Per capita matrices by year: col 1 = weight, cols 2-7 = per capita source incomes
mats <- function(b, keep = b$farm, percap = TRUE, wcol = "w") {
  lapply(setNames(YRS, YRS), function(t) { x <- b[b$jaar == t, ]; k <- keep[b$jaar == t]
    div <- if (percap) x$n else 1
    M <- cbind(w = x[[wcol]], as.matrix(x[, SRC]) / div); list(M = M, farm = k) })
}
midF <- function(y, w) {  # weighted mid-rank CDF, ties share one value
  o <- order(y); ys <- y[o]; cw <- cumsum(w[o]); W <- cw[length(cw)]
  e <- which(c(ys[-1] != ys[-length(ys)], TRUE)); hi <- cw[e]; gw <- diff(c(0, hi))
  g <- rep(seq_along(e), diff(c(0, e))); F <- numeric(length(y)); F[o] <- ((hi - gw / 2) / W)[g]; F
}
covw <- function(a, b, w) { W <- sum(w); sum(w * (a - sum(w * a) / W) * (b - sum(w * b) / W)) / W }
gini <- function(y, w) { m <- sum(w * y) / sum(w); if (!is.finite(m) || m <= 0) return(NA_real_); 2 * covw(y, midF(y, w), w) / m }
# Lerman-Yitzhaki decomposition: S, C (card §3), plus G_k, R_k, elasticity diagnostics if full = TRUE
decomp <- function(M, full = FALSE) {
  w <- M[, 1]; Y <- M[, -1, drop = FALSE]; y <- rowSums(Y); tot <- sum(w * y)
  F <- midF(y, w); cy <- covw(y, F, w)
  S <- colSums(w * Y) / tot; C <- apply(Y, 2, function(k) covw(k, F, w)) / cy
  if (tot <= 0 || cy == 0) { S[] <- NA; C[] <- NA }
  G <- if (tot > 0) 2 * cy / (tot / sum(w)) else NA_real_
  r <- list(G = G, S = S, C = C)
  if (full) { Gk <- apply(Y, 2, gini, w = w)
    Rk <- sapply(colnames(Y), function(k) { d <- covw(Y[, k], midF(Y[, k], w), w); if (d == 0) NA else covw(Y[, k], F, w) / d })
    r <- c(r, list(Gk = Gk, Rk = Rk, elast = C - S)) }
  r
}
# Statistic vector from three year-matrices (farming rows only)
stat <- function(L) {
  g <- sapply(L, function(x) { M <- x$M[x$farm, , drop = FALSE]; gini(rowSums(M[, -1, drop = FALSE]), M[, 1]) })
  d <- decomp(L[["1757"]]$M[L[["1757"]]$farm, , drop = FALSE])
  c(G1700 = g[[1]], G1723 = g[[2]], G1757 = g[[3]], setNames(d$S, paste0("S_", SRC)), setNames(d$C, paste0("C_", SRC)),
    Delta = g[[3]] - g[[1]], Da = g[[2]] - g[[1]], Db = g[[3]] - g[[2]], E = d$C[["wine"]] - d$S[["wine"]],
    setNames(d$C[["wine"]] - d$C[SRC[-2]], paste0("D_", SRC[-2])))
}
FAM <- c("Delta", "Da", "Db", "E", paste0("D_", SRC[-2]))
TAIL <- 0.05 / 18
# Stratified household bootstrap (card §4C): resample every row of each year's roll; R default RNG
boot_draws <- function(L, B = 9999, seed = 20261012) {
  set.seed(seed)
  t(vapply(seq_len(B), function(b) stat(lapply(L, function(x) { i <- sample.int(nrow(x$M), nrow(x$M), replace = TRUE)
    list(M = x$M[i, , drop = FALSE], farm = x$farm[i]) })), numeric(length(stat(L)))))
}
ci_tab <- function(pt, D, q = FAM) tibble(quantity = q, estimate = pt[q],
  lo = apply(D[, q, drop = FALSE], 2, quantile, TAIL, type = 6, na.rm = TRUE),
  hi = apply(D[, q, drop = FALSE], 2, quantile, 1 - TAIL, type = 6, na.rm = TRUE),
  se = apply(D[, q, drop = FALSE], 2, sd, na.rm = TRUE), failed = colSums(is.na(D[, q, drop = FALSE])))
side <- function(lo, hi) ifelse(lo > 0, "pos", ifelse(hi < 0, "neg", "incl0"))
# §8 verdict tables, applied mechanically. ci: ci_tab output; pt: point vector
verdicts <- function(pt, ci) {
  g <- function(q) ci[ci$quantity == q, ]
  usable <- function(q) { r <- g(q); is.finite(r$estimate) && r$failed < 3 }
  pt_row <- function(id, x, lo, hi) { r <- if (!is.finite(x)) 0 else if (x >= lo && x <= hi) 1 else if (x < lo) 2 else 3
    tibble(claim = id, estimate = x, interval = NA_character_, test_p = NA_real_, threshold = sprintf("[%.3f, %.3f]", lo, hi),
      verdict = c("not-testable", "confirmed", "qualified (below stated value)", "qualified (above stated value)")[r + 1], rule = r) }
  ivl <- function(q) sprintf("[%.3f, %.3f]", g(q)$lo, g(q)$hi)
  cmp_row <- function(id, q, rev) { r <- if (!usable(q)) 0 else switch(side(g(q)$lo, g(q)$hi), pos = 1, neg = 2, incl0 = 3)
    tibble(claim = id, estimate = g(q)$estimate, interval = ivl(q), test_p = NA_real_, threshold = paste0(q, " > 0; CI 1-0.05/9"),
      verdict = c("not-testable", "confirmed", paste0("overturned (", rev, ")"), "weakened")[r + 1], rule = r) }
  conj_row <- function(id, qs, rev) { s <- sapply(qs, function(q) side(g(q)$lo, g(q)$hi))
    r <- if (!all(sapply(qs, usable))) 0 else if (all(s == "pos")) 1 else if (any(s == "neg")) 2 else 3
    tibble(claim = id, estimate = min(ci$estimate[match(qs, ci$quantity)]), interval = paste(qs, sapply(qs, ivl), collapse = "; "),
      test_p = NA_real_, threshold = paste0("all of ", paste(qs, collapse = ","), " > 0; CI 1-0.05/9"),
      verdict = c("not-testable", "confirmed", paste0("overturned (", rev, ")"), "weakened")[r + 1], rule = r) }
  nt <- function(id) tibble(claim = id, estimate = NA_real_, interval = NA_character_, test_p = NA_real_,
    threshold = "structurally not-testable (card §0, §1)", verdict = "not-testable", rule = 0)
  bind_rows(pt_row("FB-pt (T6_fb_defl_1757)", pt[["G1757"]], 0.659, 0.719),
    cmp_row("FB-rise", "Delta", "the Gini fell"),
    conj_row("FB-steady", c("Da", "Db"), "a step falls"),
    pt_row("W-pt (T8_1757_wine_contrib)", pt[["C_wine"]], 0.489, 0.549),
    cmp_row("W-cmp", "E", "wine contributes less than its share"),
    conj_row("W-max", paste0("D_", SRC[-2]), "another source contributes more than wine"),
    nt("W-causal"), nt("WP-all-defl (T6_wp_all_defl_1700)"), nt("WP-all-p57 (T6_wp_all_p1757_1700)"),
    nt("WP-xp-defl (T6_wp_xp_defl_1700)"), nt("WP-xp-p57 (T6_wp_xp_p1757_1700)"))
}
