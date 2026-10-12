# P29_INEQ25 S6: shared helpers (sourced by 01-05). Implements the frozen method card (commit 17a056d).
# Run every script from the project root: Rscript P29_INEQ25/modern/0X_*.R

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(purrr); library(data.table); library(ineq); library(parallel)
})
source("tools/paths.R")
PAPER <- "P29_INEQ25"
SCR <- dscratch(PAPER, "modern")                      # ./P29_INEQ25/modern/_scratch
OUT <- file.path("P29_INEQ25", "modern", "output"); dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
SEED <- 20261011L
ALPHA <- 0.0125                                        # Bonferroni over {H1, H2, H3a, H3b} (card §4)
ALPHA2 <- 0.05                                         # secondary outputs (not in the family; reported only)
dec <- function(y) ifelse(y >= 1680 & y < 1840, (y %/% 10) * 10, NA)          # decades as coded (prices 1690-1830)
p20 <- function(y) ifelse(y >= 1680 & y < 1840, 1680 + ((y - 1680) %/% 20) * 20, NA)

# ineq::Gini with integer frequency weights; x must be sorted ascending. Identical to ineq::Gini(rep(x, w)).
# Returns NaN when the weighted total is 0 (no positive holder) -> "undefined" (card §4).
wgini <- function(x, w) {
  n <- sum(w); if (n == 0) return(NaN)
  tot <- sum(w * x); if (!is.finite(tot) || tot <= 0) return(NaN)
  S <- cumsum(w)
  (2 * sum(x * w * (S - w + (w + 1) / 2)) / tot - (n + 1)) / n
}
# share of the weighted total held by the top ceiling(n*p) units (as in S5 `ts`); x sorted ascending
wtop <- function(x, w, p) {
  n <- sum(w); tot <- sum(w * x); if (n == 0 || tot <= 0) return(NaN)
  k <- ceiling(n * p); xr <- rev(x); wr <- rev(w); cw <- cumsum(wr)
  i <- which(cw >= k)[1]; prev <- if (i > 1) cw[i - 1] else 0
  ((if (i > 1) sum(xr[1:(i - 1)] * wr[1:(i - 1)]) else 0) + xr[i] * (k - prev)) / tot
}
G <- function(x) ineq::Gini(x, na.rm = TRUE)

# node = list(x = sorted values, cl = cluster index of each value, top = TRUE/FALSE)
make_node <- function(x, cl, top = FALSE) { o <- order(x); list(x = x[o], cl = cl[o], top = top) }
node_stats <- function(nd, cnt) {
  w <- cnt[nd$cl]
  g <- wgini(nd$x, w)
  if (!nd$top) return(g)
  c(g, wtop(nd$x, w, .01), wtop(nd$x, w, .001), wtop(nd$x, w, .0001))
}
node_point <- function(nd) node_stats(nd, rep(1L, max(nd$cl)))

# Parallel bootstrap with L'Ecuyer-CMRG streams: one stream per chunk of 250 draws, so the first B draws of a
# larger run are identical to a smaller run with the same seed (prefix property used by the 39,999 escalation).
run_boot <- function(B, rep_fun, export, envir, ncores = min(30, detectCores() - 2), chunk = 250L, seed = SEED) {
  RNGkind("L'Ecuyer-CMRG"); set.seed(seed)
  nch <- ceiling(B / chunk); s <- .Random.seed; streams <- vector("list", nch)
  for (k in seq_len(nch)) { s <- nextRNGStream(s); streams[[k]] <- s }
  sizes <- c(rep(chunk, nch - 1), B - chunk * (nch - 1))
  cl <- makeCluster(ncores); on.exit(stopCluster(cl))
  clusterExport(cl, c(export, "wgini", "wtop", "node_stats"), envir = envir)
  clusterEvalQ(cl, suppressPackageStartupMessages(library(ineq)))
  res <- parLapply(cl, seq_len(nch), function(k, streams, sizes, rep_fun) {
    assign(".Random.seed", streams[[k]], envir = globalenv())
    do.call(rbind, lapply(seq_len(sizes[k]), function(i) rep_fun()))
  }, streams = streams, sizes = sizes, rep_fun = rep_fun)
  do.call(rbind, res)
}

# ---- interval machinery (card §4) -------------------------------------------------------------------------
endpoints <- function(Gv, G0, type, alpha) {
  if (type == "pct") {
    q <- quantile(Gv[, 1], c(alpha / 2, 1 - alpha / 2), type = 7, names = FALSE)
    return(list(L = q[1], U = q[2], se = sd(Gv[, 1]), c = NA_real_))
  }
  se <- apply(Gv, 2, sd); pos <- se > 0
  if (!any(pos)) return(list(L = G0, U = G0, se = se, c = NA_real_))
  t <- apply(abs(sweep(Gv[, pos, drop = FALSE], 2, G0[pos])) / matrix(se[pos], nrow(Gv), sum(pos), byrow = TRUE), 1, max)
  cc <- quantile(t, 1 - alpha, type = 7, names = FALSE)
  L <- G0 - cc * se; U <- G0 + cc * se; L[!pos] <- G0[!pos]; U[!pos] <- G0[!pos]
  list(L = L, U = U, se = se, c = cc)
}
# Gs: B x K replicate matrix of one family; G0: K point estimates. Joint-draw rule + 1% failure policy + batch MC SE.
family_ci <- function(Gs, G0, type, alpha = ALPHA) {
  Gs <- as.matrix(Gs); B <- nrow(Gs); K <- ncol(Gs)
  valid <- rowSums(!is.finite(Gs)) == 0; V <- sum(valid)
  out <- list(B = B, V = V, n_undef_by_node = colSums(!is.finite(Gs)), defined = V >= 0.99 * B && all(is.finite(G0)))
  if (!out$defined) return(c(out, list(L = rep(NA_real_, K), U = rep(NA_real_, K), se = rep(NA_real_, K), c = NA_real_,
                                        mcse_L = rep(NA_real_, K), mcse_U = rep(NA_real_, K))))
  Gv <- Gs[valid, , drop = FALSE]
  ep <- endpoints(Gv, G0, type, alpha)
  m <- floor(V / 10)
  bt <- lapply(1:10, function(k) endpoints(Gv[((k - 1) * m + 1):(k * m), , drop = FALSE], G0, type, alpha))
  mcL <- apply(matrix(sapply(bt, `[[`, "L"), nrow = K), 1, sd) / sqrt(10)
  mcU <- apply(matrix(sapply(bt, `[[`, "U"), nrow = K), 1, sd) / sqrt(10)
  c(out, list(L = ep$L, U = ep$U, se = ep$se, c = ep$c, mcse_L = mcL, mcse_U = mcU))
}
needs_escalation <- function(f, bounds) {
  if (!f$defined) return(FALSE)
  e <- c(f$L, f$U); s <- c(f$mcse_L, f$mcse_U)
  any(s > 0.002) || any(sapply(bounds, function(b) any(abs(e - b) < 2 * s)))
}
# plain percentile intervals for secondary outputs (columns independent; NaN draws dropped and counted)
pct_ci <- function(v, alpha = ALPHA2) {
  ok <- is.finite(v)
  if (!any(ok)) return(c(L = NA, U = NA, n_undef = sum(!ok)))
  q <- quantile(v[ok], c(alpha / 2, 1 - alpha / 2), type = 7, names = FALSE)
  c(L = q[1], U = q[2], n_undef = sum(!ok))
}

# ---- verdict rules (card §8) -------------------------------------------------------------------------------
verdict_point <- function(G0, L, U, lo, hi, defined = TRUE) {
  if (!is.finite(G0) || !defined || !is.finite(L) || !is.finite(U)) return(c("not-testable", "0"))
  if (lo <= L && U <= hi) return(c("confirmed", "1"))
  if (U < lo) return(c("overturned (credibly below the stated value)", "2"))
  if (L > hi) return(c("overturned (credibly above the stated value)", "3"))
  if (G0 >= lo && G0 <= hi) return(c("qualified (consistent but imprecise)", "4"))
  c("weakened", "5")
}
verdict_threshold <- function(G0, L, U, Tt, defined = TRUE) {
  if (!defined || any(!is.finite(G0)) || any(!is.finite(L)) || any(!is.finite(U))) return(c("not-testable", "0"))
  if (any(U <= Tt)) return(c("overturned", "1"))
  if (all(L > Tt)) return(c("confirmed", "2"))
  if (all(G0 > Tt)) return(c("qualified (inference-fragile)", "3"))
  c("weakened", "4")
}
rank_v <- function(v) match(sub(" .*", "", v), c("not-testable", "overturned", "weakened", "qualified", "confirmed"))

# ---- panel valuation (card §3, §4; variants of §5A/§5B) -----------------------------------------------------
prep_prices <- function(prices, cattle = "breeding", const = FALSE) {
  pr <- data.table(pdec = prices$period, ph = prices$horses, ps = prices$sheep, pw = prices$wheat_vol, pwi = prices$wine,
                   pc = if (cattle == "breeding") prices$cattle_breeding else (prices$cattle_breeding + prices$cattle_bull + prices$cattle_work) / 3,
                   psm = prices$slave_men, psw = prices$slave_women, pss = prices$slave_sons, psd = prices$slave_daughters)
  if (const) for (cc in setdiff(names(pr), "pdec")) set(pr, j = cc, value = mean(pr[[cc]][pr$pdec >= 1690 & pr$pdec <= 1830]))
  pr
}
# One row per census row: v = five-asset basket value (NA when the year has no price), NA counts -> 0 as coded.
# vines: "none" (central), "yield" (V2b), "half" (V2c, 0.5 rxd per vine), "cap6" (yield value capitalised at 6%).
# cover = TRUE (V1): 1685-89 priced at 1690 and 1840-44 at 1830.
value_rows <- function(pn, prices, cattle = "breeding", const = FALSE, vines = "none", cover = FALSE) {
  vv <- c("horses", "cattle", "sheep", "wheat_vol", "vines", "wine", "slave_men", "slave_women", "slave_sons", "slave_daughters", "settler_men", "settler_women")
  d <- pn[, c("hh", "year", "original_row", vv), with = FALSE]
  d[, row := .I]
  for (cc in vv) set(d, j = cc, value = fifelse(is.na(d[[cc]]), 0, as.numeric(d[[cc]])))
  d[, dnode := (year %/% 10) * 10]
  d[, pdec := dnode]
  if (cover) { d[pdec == 1680, pdec := 1690]; d[pdec == 1840, pdec := 1830] }
  pr <- prep_prices(prices, cattle, const)
  d <- pr[d, on = "pdec"]; setorder(d, row)
  d[, v := horses * ph + cattle * pc + sheep * ps + wheat_vol * pw + wine * pwi]
  if (vines != "none") {
    yv <- d[is.finite(v), .(wpv = sum(wine) / sum(vines)), by = dnode]
    d <- yv[d, on = "dnode"]; setorder(d, row)
    if (vines == "yield") d[, v := v + vines * wpv * pwi]
    if (vines == "half")  d[, v := v + vines * 0.5]
    if (vines == "cap6")  d[, v := v + vines * wpv * pwi / 0.06]
  }
  d[, pnode := fifelse(year >= 1680 & year < 1840, 1680 + ((year - 1680) %/% 20) * 20, NA_real_)]
  d[]
}
# rows of one Fig 2 / H2 node (20-year period p). scen: settlers | slaveassets | zero | sheep12 | V7b | V7c.
# zero_def: "men" (central: one zero row per enslaved man) or "adults" (men + women, §5B item 8).
h2_rows <- function(d, p, scen = "zero", zero_def = "men") {
  o <- d[pnode == p & is.finite(v)]
  slv <- o$slave_men + o$slave_women + o$slave_sons + o$slave_daughters
  own <- switch(scen, settlers = , zero = , sheep12 = o$v, slaveassets = , V7b = o$v + 200 * o$ps * slv,
                V7c = o$v + o$slave_men * o$psm + o$slave_women * o$psw + o$slave_sons * o$pss + o$slave_daughters * o$psd)
  res <- data.table(x = own, row = o$row, hh = o$hh, year = o$year, synth = FALSE)
  if (scen %in% c("zero", "sheep12", "V7b", "V7c")) {
    nz <- if (zero_def == "men") o$slave_men else o$slave_men + o$slave_women
    stopifnot(all(nz == round(nz)))
    i <- rep(seq_len(nrow(o)), nz)
    res <- rbind(res, data.table(x = if (scen == "sheep12") 12 * o$ps[i] else 0, row = o$row[i], hh = o$hh[i], year = o$year[i], synth = TRUE))
  }
  res
}
h1_rows <- function(d, dn) { o <- d[dnode == dn & is.finite(v)]; data.table(x = o$v, row = o$row, hh = o$hh, year = o$year, synth = FALSE) }
# raw-unit Fig 2 exactly as coded (l.1143-1247): six raw quantities summed; settlers/slave-asset lines on settler_men > 0
raw_rows <- function(d, p, scen) {
  base <- if (scen %in% c("settlers", "slaveassets")) d[settler_men > 0] else d
  o <- base[pnode == p]
  vr <- o$horses + o$cattle + o$sheep + o$wheat_vol + o$vines + o$wine
  if (scen == "slaveassets") vr <- vr + 200 * (o$slave_men + o$slave_women + o$slave_sons + o$slave_daughters)
  res <- data.table(x = vr, row = o$row, hh = o$hh, year = o$year, synth = FALSE)
  if (scen %in% c("zero", "sheep12")) {
    i <- rep(seq_len(nrow(o)), o$slave_men)
    res <- rbind(res, data.table(x = if (scen == "sheep12") 12 else 0, row = o$row[i], hh = o$hh[i], year = o$year[i], synth = TRUE))
  }
  res
}
gpt <- function(r) G(r$x)
