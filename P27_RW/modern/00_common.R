# 00_common.R -- P27_RW S6: shared functions (weights, estimands, bootstrap). Sourced by 02-04.
suppressMessages({library(dplyr)})
source("tools/paths.R")
scr <- dscratch("P27_RW", "modern")
LEV <- 1 - 0.05 / 4                         # Family Q Bonferroni level, 98.75%
QL <- c((1 - LEV) / 2, 1 - (1 - LEV) / 2)   # 0.625%, 99.375%
UNDEF_MAX <- 0.000625                        # undefined-draw gate (card section 4)

# slave classes: stated 0 / 1-5 / 6-15 / 16+ (card section 3); "group" boundaries 0 / 1-4 / 5-15 / 16+ (sens 6); two classes
cls4 <- function(s) findInterval(s, c(0, 1, 6, 16))
clsG <- function(s) findInterval(s, c(0, 1, 5, 16))
cls2 <- function(s) 1L + (s >= 1)
# time blocks of the overlap 1700-73; nb = 1 pooled, 2, 4 (card), 8 (sens 7)
blk <- function(y, nb) {
  b <- switch(as.character(nb), "1" = rep(1L, length(y)), "2" = findInterval(y, c(1700, 1737)),
              "4" = findInterval(y, c(1700, 1719, 1737, 1755)), "8" = floor((y - 1700) * 8 / 74) + 1L)
  b[y < 1700 | y > 1773] <- NA; as.integer(b)
}
# time-balanced class shares: average over blocks of within-block shares; NA if a block is empty
tb_share <- function(cls, b, K, nb) {
  ok <- !is.na(b); n <- tabulate((b[ok] - 1L) * K + cls[ok], nb * K)
  m <- matrix(n, nrow = nb, byrow = TRUE); rs <- rowSums(m)
  if (any(rs == 0)) return(rep(NA_real_, K))
  colMeans(m / rs)
}
mkw <- function(Pinv, Popg) {
  if (anyNA(Pinv) || anyNA(Popg) || any(Pinv == 0 & Popg > 0)) return(rep(NA_real_, length(Pinv)))
  ifelse(Pinv == 0, 0, Popg / Pinv)
}
wmean <- function(y, w) sum(w * y) / sum(w)
wslope <- function(x, y, w) { xb <- wmean(x, w); yb <- wmean(y, w); sum(w * (x - xb) * (y - yb)) / sum(w * (x - xb)^2) }

# all estimands for one (possibly resampled) pair of samples.
# I: y, s, decade, yr (calendar year), date; O: s, yr. cfg: class function, number of blocks
estim <- function(I, O, cfg = list(cf = cls4, nb = 4)) {
  K <- if (identical(cfg$cf, cls2)) 2L else 4L
  ci <- cfg$cf(I$s); co <- cfg$cf(O$s)
  w <- mkw(tb_share(ci, blk(I$yr, cfg$nb), K, cfg$nb), tb_share(co, blk(O$yr, cfg$nb), K, cfg$nb))
  wi <- w[ci]; pre <- I$decade <= 1800
  r <- function(d) I$decade == d
  m <- function(sel) mean(I$y[sel]); mw <- function(sel) if (anyNA(w)) NA_real_ else wmean(I$y[sel], wi[sel])
  own_i <- I$s >= 1; own_o <- O$s >= 1
  mu_i <- if (any(own_i)) mean(I$s[own_i]) else NA_real_; mu_o <- if (any(own_o)) mean(O$s[own_o]) else NA_real_
  out <- c(m1700 = m(r(1700)), m1790 = m(r(1790)), m1800 = m(r(1800)), mtot = m(pre),
           w1700 = mw(r(1700)), w1790 = mw(r(1790)), w1800 = mw(r(1800)), wtot = mw(pre),
           slope = wslope(I$date[pre], I$y[pre], rep(1, sum(pre))),
           slopew = if (anyNA(w)) NA_real_ else wslope(I$date[pre], I$y[pre], wi[pre]),
           mu_inv = mu_i, mu_opg = mu_o, R = mu_i / mu_o, pi_inv = mean(own_i), pi_opg = mean(own_o))
  c(out, D90 = out[["m1790"]] - out[["m1700"]], D90w = out[["w1790"]] - out[["w1700"]],
    late = out[["m1800"]] - out[["m1790"]], latew = out[["w1800"]] - out[["w1790"]],
    endp = out[["m1800"]] - out[["m1700"]], endpw = out[["w1800"]] - out[["w1700"]],
    Delta = out[["pi_inv"]] - out[["pi_opg"]], setNames(c(w, rep(NA, 4 - K)), paste0("wk", 1:4)))
}

# resamplers -------------------------------------------------------------
# inventories: independent estates within decade rows (fixed n), year clusters within rows, or none
inv_sampler <- function(I, mode = "estate") {
  rows <- split(seq_len(nrow(I)), I$decade)
  if (mode == "none") return(function() seq_len(nrow(I)))
  if (mode == "estate") return(function() unlist(lapply(rows, function(ix) ix[sample.int(length(ix), length(ix), TRUE)]), use.names = FALSE))
  yc <- lapply(rows, function(ix) split(ix, I$yr[ix]))
  function() unlist(lapply(yc, function(cl) cl[sample.int(length(cl), length(cl), TRUE)]), use.names = FALSE)
}
# opgaaf: circular moving-block over calendar years 1700-1773 (block length L), household-key clusters, or none
opg_sampler <- function(O, mode = "block", L = 5) {
  if (mode == "none") return(function() seq_len(nrow(O)))
  if (mode == "cluster") { cl <- split(seq_len(nrow(O)), O$key); return(function() unlist(cl[sample.int(length(cl), length(cl), TRUE)], use.names = FALSE)) }
  yrs <- 1700:1773; ny <- length(yrs); byr <- split(seq_len(nrow(O)), factor(O$yr, levels = yrs))
  nbk <- ceiling(ny / L)
  function() {
    st <- sample.int(ny, nbk, TRUE)
    idx <- as.vector(sapply(st, function(s0) ((s0 - 1L + 0:(L - 1L)) %% ny) + 1L))[1:ny]
    unlist(byr[idx], use.names = FALSE)
  }
}
run_boot <- function(I, O, B, seed, imode = "estate", omode = "block", L = 5, cfg = list(cf = cls4, nb = 4)) {
  set.seed(seed); fi <- inv_sampler(I, imode); fo <- opg_sampler(O, omode, L)
  t(vapply(seq_len(B), function(b) estim(I[fi(), ], O[fo(), ], cfg), estim(I, O, cfg)))
}
summ_boot <- function(M, q = c("D90", "D90w", "R", "Delta")) {
  bind_rows(lapply(q, function(v) { x <- M[, v]; d <- x[is.finite(x)]
    data.frame(quantity = v, lo = unname(quantile(d, QL[1], type = 7)), hi = unname(quantile(d, QL[2], type = 7)),
               undef_share = mean(!is.finite(x)), n_def = length(d)) }))
}
