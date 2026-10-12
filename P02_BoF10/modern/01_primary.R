# P02_BoF10 S6 primary (card §4): H1 T4_r3_F, phase-randomised surrogate null for the authors' F on WHEATMF22 / SHIPSMF22, p = 5
source(here::here("P02_BoF10", "modern", "00_common.R"))
cz <- read_cz(); y <- cz$WHEATMF22; x <- cz$SHIPSMF22
w <- win(y, x); yw <- y[w$i]; xw <- x[w$i]; nw <- length(yw)
cat("window", range(cz$OBS[w$i]), " n_w", nw, " internal gap", w$gap, "\n")
stopifnot(!w$gap)
# verification: copied S5 function vs checked Wald fit
source(here::here("P02_BoF10", "modern", "uecm_fn_s5.R")); s5 <- uecm(y, x, 5)
obs <- uecm_chk(yw, xw, 5, theta = TRUE)
cat("S5 uecm F", s5["F"], " checked Wald F", obs["F"], " valid", obs["valid"], " n", obs["n"], " theta", obs["theta"], "\n")
impl <- if (obs["F"] >= 61.765 && obs["F"] <= 61.775) "reproduced" else "unreproduced"
# residual diagnostics: lag-1 autocorrelation, Breusch-Godfrey LM(4) (lagged residuals filled with 0, as lmtest::bgtest)
d <- design(yw, xw, 5); e <- lm.fit(d$X, d$y)$residuals; ne <- length(e)
L <- sapply(1:4, \(l) c(rep(0, l), e[1:(ne - l)])); aux <- lm.fit(cbind(d$X, L), e)
bg <- ne * (1 - sum(aux$residuals^2) / sum((e - mean(e))^2)); rho1 <- cor(e[-1], e[-ne])
run_stage <- function(B, seed) { set.seed(seed); t(vapply(seq_len(B), \(b) uecm_chk(phase_sur(yw), xw, 5), numeric(5))) }
t0 <- Sys.time(); S1 <- run_stage(9999, 20261012); r1 <- pvals(obs, S1, 9999) |> mutate(stage = 1)
cat("stage 1:", format(Sys.time() - t0), "\n"); print(as.data.frame(r1))
need2 <- any(abs(c(0.01, 0.05) - r1$p_s) <= 3.29 * r1$mcse)
r <- r1; if (need2) { S2 <- run_stage(99999, 20261013); r2 <- pvals(obs, S2, 99999) |> mutate(stage = 2); r <- bind_rows(r1, r2) }
dec <- r |> slice_tail(n = 1)
prim <- r |> mutate(claim = "T4_r3_F", n_w = nw, window = paste(range(cz$OBS[w$i]), collapse = "-"), n_reg = obs["n"], F_obs = obs["F"],
  theta_obs = obs["theta"], s5_F = s5["F"], impl = impl, resid_rho1 = rho1, bg_lm4 = bg, bg_p = pchisq(bg, 4, lower.tail = FALSE),
  deciding = stage == dec$stage, rngkind = paste(RNGkind(), collapse = "/"))
write_csv(prim, file.path(OUT, "primary.csv"))
saveRDS(list(F = S1[S1[, "valid"] == 1, "F"], Fobs = obs["F"]), dscratch("P02_BoF10", "modern", "primary_draws.rds"))
print(as.data.frame(prim), digits = 5)
