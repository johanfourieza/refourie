# P02_BoF10 S6 calibration study (card §4a; report-only, never verdict-determining).
# Size of the surrogate test (B = 199, single stage) under two independent-series DGPs, R CF 12-40 I(1)+drift, length 93, central n_w kept, p = 5.
source(here::here("P02_BoF10", "modern", "00_common.R"))
cz <- read_cz(); w <- win(cz$WHEATMF22, cz$SHIPSMF22); nw <- length(w$i)
sv <- readRDS(dscratch("P02_BoF10", "modern", "sieve_fits.rds"))           # written by 02_sensitivities.R (sensitivity 5 fits)
N <- 93; R <- 1000; Bc <- 199; drop0 <- floor((N - nw) / 2); keep <- (drop0 + 1):(drop0 + nw)
dS <- diff(log(sv$sh$ships)); dW <- diff(log(sv$wr$WHEAT))
parA <- list(x = c(mean(dS), sd(dS)), y = c(mean(dW), sd(dW)))           # OLS drift and innovation SD of dlog (constant-only regression)
sim_ar_log <- function(m, n, lev0) { q <- m$q; e <- sample(m$res - mean(m$res), n - 1 - q, replace = TRUE); z <- numeric(n - 1)
  if (q > 0) z[1:q] <- m$z[1:q]
  for (t in (q + 1):(n - 1)) z[t] <- m$coef[1] + (if (q > 0) sum(m$coef[-1] * z[(t - 1):(t - q)]) else 0) + e[t - q]
  lev0 + cumsum(c(0, z)) }
cf <- function(l) as.numeric(cffilter(l, 12, 40, root = TRUE, drift = TRUE)$cycle)[keep]
gen <- list(
  A = function() list(y = cumsum(c(0, rnorm(N - 1, parA$y[1], parA$y[2]))), x = cumsum(c(0, rnorm(N - 1, parA$x[1], parA$x[2])))),
  B = function() list(y = sim_ar_log(sv$mW, N, log(sv$wr$WHEAT[1])), x = sim_ar_log(sv$mS, N, log(sv$sh$ships[1]))))
set.seed(20261014); t0 <- Sys.time()
reps <- map_dfr(names(gen), \(g) map_dfr(seq_len(R), \(r) { s <- gen[[g]](); yy <- cf(s$y); xx <- cf(s$x); o <- uecm_chk(yy, xx, 5)
  if (o["valid"] != 1) return(tibble(dgp = g, rep = r, invalid = TRUE))
  S <- t(vapply(seq_len(Bc), \(b) uecm_chk(phase_sur(yy), xx, 5), numeric(5)))
  pvals(o, S, Bc) |> transmute(dgp = g, rep = r, invalid = FALSE, F_obs = stat, f, p_s, p_lo, p_hi) }))
cat("calibration runtime", format(Sys.time() - t0), "\n")
write_csv(reps, dscratch("P02_BoF10", "modern", "calibration_reps.csv"))
cal <- reps |> group_by(dgp) |> summarise(R = n(), invalid = sum(invalid), failed_draws = sum(f, na.rm = TRUE), medF = median(F_obs, na.rm = TRUE),
  across(c(), identity), .groups = "drop") |>
  left_join(map_dfr(c(0.01, 0.05), \(a) reps |> filter(!invalid) |> group_by(dgp) |>
    summarise(alpha = a, Rv = n(), rej = mean(p_hi < a), ambiguous = mean(p_lo < a & p_hi >= a), rej_cc = mean(p_s < a), .groups = "drop")), by = "dgp") |>
  mutate(mcse_rej = sqrt(rej * (1 - rej) / Rv), mcse_cc = sqrt(rej_cc * (1 - rej_cc) / Rv), B = Bc, n_w = nw, design = c(A = "indep. log RW with drift", B = "indep. AR sieve in dlog")[dgp])
write_csv(cal, file.path(OUT, "calibration.csv")); print(as.data.frame(cal), digits = 3)
