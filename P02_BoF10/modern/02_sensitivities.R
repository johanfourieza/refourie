# P02_BoF10 S6 sensitivities 1-13 (card §5); reported, never verdict-determining. B = 999, seed 20261012 unless stated.
source(here::here("P02_BoF10", "modern", "00_common.R"))
cz <- read_cz(); ag <- read_ag(); sh <- read_ships()
d <- read_csv(dscratch("P02_BoF10", "repro_r", "series.csv"), show_col_types = FALSE)
y <- cz$WHEATMF22; x <- cz$SHIPSMF22; w <- win(y, x); yrs <- cz$OBS[w$i]; yw <- y[w$i]; xw <- x[w$i]
B <- 999; SEED <- 20261012; res <- list()
add <- function(id, label, obs, sims, B = 999, use = "F", note = "") res[[length(res) + 1]] <<- pvals(obs, sims, B, use) |>
  mutate(sens = id, label = label, use = use, n_reg = obs["n"], theta_obs = obs["theta"], note = note, .before = 1)
notrun <- function(id, label, note) res[[length(res) + 1]] <<- tibble(sens = id, label = label, note = note)
sims_of <- function(gen) { set.seed(SEED); t(vapply(seq_len(B), \(b) gen(), numeric(5))) }
at_win <- function(yr, v) v[match(yrs, yr)]          # align a raw-year vector to the primary window years
gapcheck <- function(v) any(is.na(v))

# 1. lag order p = 3, 4, 6
for (p in c(3, 4, 6)) { o <- uecm_chk(yw, xw, p, TRUE); add("1", paste0("lag order p=", p), o, sims_of(\() uecm_chk(phase_sur(yw), xw, p))) }
# 2. AIC / BIC lag selection over 1-6 lagged differences (p = 2..7) on a common sample, repeated inside each draw
sel <- function(Y, crit) { ic <- sapply(2:7, \(p) { dd <- design(Y, xw, p, kmax = 6); f <- lm.fit(dd$X, dd$y); n <- length(dd$y); K <- ncol(dd$X)
  n * log(sum(f$residuals^2) / n) + (if (crit == "AIC") 2 else log(n)) * K }); p <- (2:7)[which.min(ic)]; c(uecm_chk(Y, xw, p, TRUE, kmax = 6), p = p) }
for (cr in c("AIC", "BIC")) { o <- sel(yw, cr); set.seed(SEED); S <- t(vapply(seq_len(B), \(b) sel(phase_sur(yw), cr), numeric(6)))
  tb <- table(S[, 6]); add("2", paste0(cr, " lag selection in null"), o, S[, 1:5],
    note = paste0("observed p=", o["p"], "; null p counts ", paste(names(tb), tb, sep = ":", collapse = " "))) }
# 3. randomise x (ships) with y fixed; independent surrogates of both
o <- uecm_chk(yw, xw, 5, TRUE)
add("3", "surrogates of x (ships), y fixed", o, sims_of(\() uecm_chk(yw, phase_sur(xw), 5)))
add("3", "independent surrogates of y and x", o, sims_of(\() { ys <- phase_sur(yw); uecm_chk(ys, phase_sur(xw), 5) }))
# 4. IAAFT surrogates of y
set.seed(SEED); disc <- iters <- numeric(B)
S <- t(vapply(seq_len(B), \(b) { s <- iaaft(yw); disc[b] <<- attr(s, "disc"); iters[b] <<- attr(s, "iter"); uecm_chk(as.numeric(s), xw, 5) }, numeric(5)))
add("4", "IAAFT surrogates of y", o, S, note = sprintf("final spectral discrepancy median %.2e, max %.2e; draws at 100-iteration cap: %d", median(disc), max(disc), sum(iters >= 100)))
# 5. sieve null on raw series (dlog ships 1701-93; dlog corrected VDR WHEAT column), R-refiltered observed and null
ar_fit_q <- function(z, q) { n <- length(z); Y <- z[(q + 1):n]; M <- cbind(rep(1, n - q), if (q > 0) sapply(1:q, \(l) z[(q + 1 - l):(n - l)]) else NULL)
  f <- lm.fit(M, Y); list(q = q, coef = f$coefficients, res = f$residuals, aic = (n - q) * log(sum(f$residuals^2) / (n - q)) + 2 * (q + 1)) }
ar_roots <- function(m) if (m$q > 0) Mod(polyroot(c(1, -m$coef[-1]))) else numeric(0)
fit_ar <- function(z) { fits <- lapply(0:4, \(q) ar_fit_q(z, q)); m <- fits[[which.min(sapply(fits, `[[`, "aic"))]]
  while (m$q > 0 && any(ar_roots(m) <= 1)) m <- ar_fit_q(z, m$q - 1)       # reduce q until stable
  m$roots <- ar_roots(m); m$z <- z; m }
sim_ar <- function(m, n, lev0) { q <- m$q; e <- sample(m$res - mean(m$res), n - 1 - q, replace = TRUE); z <- numeric(n - 1)
  if (q > 0) z[1:q] <- m$z[1:q]
  for (t in (q + 1):(n - 1)) z[t] <- m$coef[1] + (if (q > 0) sum(m$coef[-1] * z[(t - 1):(t - q)]) else 0) + e[t - q]
  exp(lev0 + cumsum(c(0, z))) }
wr <- ag |> filter(!is.na(WHEAT), !is.na(YEAR))
cat("WHEAT years", range(wr$YEAR), " n", nrow(wr), " contiguous:", all(diff(wr$YEAR) == 1), "| ships years", range(sh$year), " NA", sum(is.na(sh$ships)), "\n")
mS <- fit_ar(diff(log(sh$ships))); mW <- fit_ar(diff(log(wr$WHEAT)))
saveRDS(list(mS = mS, mW = mW, sh = sh, wr = wr), dscratch("P02_BoF10", "modern", "sieve_fits.rds"))
SR <- at_win(sh$year, cfz(sh$ships)); WR <- at_win(wr$YEAR, cfz(wr$WHEAT))
sv_note <- sprintf("ships q=%d roots %s; wheat q=%d roots %s", mS$q, paste(round(mS$roots, 3), collapse = "/"), mW$q, paste(round(mW$roots, 3), collapse = "/"))
if (gapcheck(SR) || gapcheck(WR) || !all(diff(wr$YEAR) == 1)) notrun("5", "sieve null, raw series", "not run: gap") else {
  o5 <- uecm_chk(WR, SR, 5, TRUE)
  add("5", "sieve AR null on raw series (R-refiltered observed)", o5, sims_of(\() { s <- sim_ar(mS, nrow(sh), log(sh$ships[1])); ww <- sim_ar(mW, nrow(wr), log(wr$WHEAT[1]))
    uecm_chk(at_win(wr$YEAR, cfz(ww)), at_win(sh$year, cfz(s)), 5) }), note = sv_note) }
# 6. reverse direction (T4_r4_F, published 91.67): ships dependent, surrogates of ships
o6 <- uecm_chk(xw, yw, 5, TRUE); add("6", "reverse: wheat -> ships (T4_r4_F, pub 91.67)", o6, sims_of(\() uecm_chk(phase_sur(xw), yw, 5)))
# 7. long-run coefficient T5_r1 (pub 4.53): surrogate p for |theta|, Newey-West (4) and conventional delta SEs
o7 <- uecm_chk(yw, xw, 5, TRUE); S7 <- sims_of(\() uecm_chk(phase_sur(yw), xw, 5, theta = TRUE))
dd <- design(yw, xw, 5); df7 <- as.data.frame(dd$X[, -1]); names(df7)[1:3] <- c("ylag", "xlag", "dx0"); df7$dy <- dd$y
m7 <- lm(dy ~ ., df7); b <- coef(m7)
Vnw <- sandwich::NeweyWest(m7, lag = 4, prewhite = FALSE)[c("ylag", "xlag"), c("ylag", "xlag")]; g <- c(b["xlag"] / b["ylag"]^2, -1 / b["ylag"])
se_nw <- sqrt(drop(t(g) %*% Vnw %*% g))
add("7", "long-run theta T5_r1 (pub 4.53), surrogate p for |theta|", o7, S7, use = "abstheta",
  note = sprintf("theta %.3f; conventional delta SE %.3f; Newey-West(4) delta SE %.3f", o7["theta"], o7["se"], se_nw))
# 8. conventional benchmarks
res[[length(res) + 1]] <- tibble(sens = "8", label = "bounds benchmarks", stat = unname(o["F"]),
  note = sprintf("F %.2f > PSS k=1 case III 5%% upper 5.73: %s; > 1%% upper 7.84: %s; > paper 4.01: %s", o["F"], o["F"] > 5.73, o["F"] > 7.84, o["F"] > 4.01))
# 9. uncorrected VDR wheat reaped (rebuild series.csv from the raw VDR sheet), R-refiltered, SHIPSMF22 regressor
U <- at_win(d$year, cfz(d$wheat_reaped))
if (gapcheck(U)) notrun("9", "uncorrected VDR wheat", "not run: gap") else { o9 <- uecm_chk(U, xw, 5, TRUE)
  add("9", "uncorrected VDR wheat (R-refiltered), SHIPSMF22", o9, sims_of(\() uecm_chk(phase_sur(U), xw, 5))) }
# 10. band 12-20 y, R-refiltered ships and wheat
S10 <- at_win(sh$year, cfz(sh$ships, 12, 20)); W10 <- at_win(wr$YEAR, cfz(wr$WHEAT, 12, 20))
if (gapcheck(S10) || gapcheck(W10)) notrun("10", "band 12-20", "not run: gap") else { o10 <- uecm_chk(W10, S10, 5, TRUE)
  add("10", "band 12-20 y, R-refiltered wheat and ships", o10, sims_of(\() uecm_chk(phase_sur(W10), S10, 5))) }
# 11. exports reconstruction (H4 context): 11 internal gaps interpolated, log, R CF 12-40 I(1)+drift; F and |theta|
ex <- d$wheat_exports; r <- range(which(!is.na(ex))); cat("exports", d$year[r], " gaps interpolated:", sum(is.na(ex[r[1]:r[2]])), "\n")
ex[r[1]:r[2]] <- zoo::na.approx(ex[r[1]:r[2]]); EX <- at_win(d$year, cfz(ex))
for (rg in list(list("SHIPSMF22", xw), list("R-refiltered ships", SR))) { w11 <- win(EX, rg[[2]]); Ey <- EX[w11$i]; Xs <- rg[[2]][w11$i]
  o11 <- uecm_chk(Ey, Xs, 5, TRUE); S11 <- sims_of(\() uecm_chk(phase_sur(Ey), Xs, 5, theta = TRUE))
  add("11", paste0("exports reconstruction, ", rg[[1]], ": F"), o11, S11, note = "H4 context only; never votes")
  add("11", paste0("exports reconstruction, ", rg[[1]], ": |theta| (pub 2.88)"), o11, S11, use = "abstheta", note = sprintf("theta %.3f (delta SE %.3f)", o11["theta"], o11["se"])) }
# 12. endpoints: drop the first and last 5 years of the filtered window
yt <- yw[6:(length(yw) - 5)]; xt <- xw[6:(length(xw) - 5)]; o12 <- uecm_chk(yt, xt, 5, TRUE)
add("12", "primary, first and last 5 years dropped", o12, sims_of(\() uecm_chk(phase_sur(yt), xt, 5)))
# 13. S3 rebuild numbers (pair B), reference only
res[[length(res) + 1]] <- tibble(sens = "13", label = "S3 rebuild (pair B): I(0) filter, 3 lagged differences, mislabelled series",
  note = "T4_r3_F 235.40; T4_r4_F 136.68; T4_r5_F ('Brunt' = VDR corrected) 182.80; T5_r1 theta 1.465; T5_r3 theta 2.90; T5_r5 (exports) theta 1.514")
out <- bind_rows(res); write_csv(out, file.path(OUT, "sensitivities.csv"))
print(as.data.frame(out |> select(sens, label, stat, B_def, f, p_s, q95, q99, note)), digits = 4, right = FALSE)
