# P10_FI S6 step 2: H2-ITS, descriptive and labelled different-estimand (card §4 B).
# Run from the project root: Rscript P10_FI/modern/02_its.R
source(file.path("P10_FI", "modern", "00_functions.R"))
L <- load_angreg("v2018"); b <- desc_universe(L$a)
s <- annual_series(b)
stopifnot(isTRUE(all.equal(as.integer(s$year), YEARS)))                       # T = 53
f <- its_fit(s, brk = 1949, K = 2, lag = 3)

# Circular moving-block residual bootstrap, block length 5, B = 9,999, seed 20261011
cmb_index <- function(Tn, len, B) {
  nb <- ceiling(Tn / len); idx <- matrix(0L, Tn, B)
  for (j in seq_len(B)) { st <- sample.int(Tn, nb, replace = TRUE)
    idx[, j] <- (as.vector(outer(0:(len - 1), st, "+")) - 1L)[seq_len(Tn)] %% Tn + 1L }
  idx
}
RNGkind("L'Ecuyer-CMRG"); set.seed(SEED)
e <- residuals(f$m); yhat <- fitted(f$m)
idx <- cmb_index(length(e), 5, B_BOOT)
Ystar <- yhat + matrix(e[idx], nrow = length(e))
cf <- qr.coef(qr(f$X), Ystar)                              # columns = draws
th_b <- colSums(f$cc$theta * cf); sl_b <- colSums(f$cc$dslope * cf)
q <- function(x) quantile(x, c(0.025, 0.975), type = 7)
its <- data.table(quantity = c("theta", "dslope"),
                  estimate = c(f$theta["est"], f$dslope["est"]),
                  hac_se = c(f$theta["se"], f$dslope["se"]), hac_t = c(f$theta["t"], f$dslope["t"]),
                  hac_p = c(f$theta["p"], f$dslope["p"]), hac_lo = c(f$theta["lo"], f$dslope["lo"]), hac_hi = c(f$theta["hi"], f$dslope["hi"]),
                  block_lo = c(q(th_b)[1], q(sl_b)[1]), block_hi = c(q(th_b)[2], q(sl_b)[2]),
                  df = f$df, T = nrow(s), note = "K = 2; NW Bartlett lag 3 prewhite = FALSE adjust = TRUE, t(T-5); circular MBB block 5, B = 9,999, 95% percentile")
print(its); print(round(coef(f$m), 4))
fwrite(its, file.path(OUT, "its_primary.csv"))
fwrite(data.table(year = s$year, N = s$N, share = round(s$y, 4), fitted = round(yhat, 4)), file.path(OUT, "its_series.csv"))
