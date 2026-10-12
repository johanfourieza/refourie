# P23_MBF S6 primary analysis B (card §4B): Table 5 col 4, Firth penalised logit with profile penalised-likelihood
# inference, on the 64 regions of the printed col 4 (A'). Open data (Murdock/ALTT/GIS region file).
suppressPackageStartupMessages({
  library(tidyverse); library(haven); library(logistf); library(parallel)
})
root <- "."
source(file.path(root, "tools", "paths.R"))
mod <- file.path(root, "P23_MBF", "modern")
out <- file.path(mod, "output"); dir.create(out, showWarnings = FALSE)
fig <- file.path(mod, "figures"); dir.create(fig, showWarnings = FALSE)
SEED <- 20261011
source(file.path(mod, "t5_common.R"))

d <- read_dta(dpath("P23_MBF", "original", "ld", "1_murdockanddbirth_final.dta")) |> zap_labels()
s <- t5_samples(d)
s64 <- s$s64

# ---- precondition: ML logit, printed specification, N = 64, 15 events, beta = 9.099 to 1e-3
ml <- glm(F_C4, binomial, s64, control = glm.control(epsilon = 1e-14, maxit = 200))
b_ml <- unname(coef(ml)["d_mission"])
pre_ok <- nrow(s64) == 64 && sum(s64$d_birth) == 15 && abs(b_ml - 9.099) < 1e-3 && ml$converged
cat("Precondition: N", nrow(s64), "events", sum(s64$d_birth), "ML beta", b_ml, "ok", pre_ok, "\n")
if (!pre_ok) stop("Table 5 precondition failed; 02a_t5_sample.do path not implemented because not needed if this passes")

# ---- primary: Firth with PL inference, prespecified recovery (R1, R2)
fit_out <- firth_pl(F_C4, s64, log_prefix = "primary")
r <- fit_out$res

# ---- profile penalised log-likelihood for beta (reported plot)
grid <- seq(r$ci_lo - 2, r$ci_hi + 2, length.out = 101)
# restricted penalised log-likelihood at beta = b0 (full Jeffreys penalty), from logistftest
prof_ll <- function(b0) {
  tt <- tryCatch(logistftest(fit_out$fit, test = ~ d_mission, values = b0, control = logistf.control(maxit = 1000)),
                 error = function(e) NULL, warning = function(w) NULL)
  if (is.null(tt)) NA_real_ else tt$loglik[["null"]]
}
pll <- sapply(grid, prof_ll)
prof <- tibble(beta = grid, pen_loglik = pll) |> filter(!is.na(pen_loglik))
write_csv(prof, file.path(out, "t5_profile_pll.csv"))
crit <- fit_out$fit$loglik[["full"]] - qchisq(0.95, 1) / 2
p_prof <- ggplot(prof, aes(beta, pen_loglik)) +
  geom_line(colour = "#5C2346", linewidth = 0.8) +
  geom_hline(yintercept = crit, colour = "#AAAAAA", linetype = "dashed") +
  geom_vline(xintercept = c(r$ci_lo, r$ci_hi), colour = "#3D8EB9", linetype = "dotted") +
  geom_vline(xintercept = 0, colour = "#AAAAAA") +
  geom_vline(xintercept = 4.55, colour = "#D4A03E", linetype = "longdash") +
  labs(x = "Mission coefficient (log-odds)", y = "Profile penalised log-likelihood") +
  theme_minimal(base_size = 11) + theme(panel.grid.minor = element_blank())
ggsave(file.path(fig, "fig_t5_profile.pdf"), p_prof, width = 6, height = 4)
ggsave(file.path(fig, "fig_t5_profile.png"), p_prof, width = 6, height = 4, dpi = 300)

# ---- FLIC discrete effect of mission presence, with stratified bootstrap (B = 1,999; reported only)
# FLIC (Puhr et al. 2017): Firth slopes, intercept re-estimated by ML with the Firth linear predictor as offset
flic_effect <- function(dat) {
  fx <- logistf::logistf(F_C4, data = dat, firth = TRUE, pl = FALSE, control = logistf::logistf.control(maxit = 1000))
  b <- coef(fx)[-1]
  X <- model.matrix(F_C4, dat)[, names(b), drop = FALSE]
  eta <- drop(X %*% b)
  a <- coef(glm(dat$d_birth ~ 1, offset = eta, family = binomial))[[1]]
  X1 <- X; X1[, "d_mission"] <- 1
  X0 <- X; X0[, "d_mission"] <- 0
  mean(plogis(a + drop(X1 %*% b)) - plogis(a + drop(X0 %*% b)))
}
flic_hat <- flic_effect(s64)
B <- 1999
RNGkind("L'Ecuyer-CMRG"); set.seed(SEED)
strata <- split(seq_len(nrow(s64)), s64$iso2)
idx <- lapply(seq_len(B), function(b) unlist(lapply(strata, function(ix) ix[sample.int(length(ix), length(ix), replace = TRUE)]), use.names = FALSE))
cl <- makeCluster(4)
clusterEvalQ(cl, suppressPackageStartupMessages({library(logistf); library(dplyr)}))
clusterExport(cl, c("s64", "F_C4", "flic_effect"))
bt <- parLapply(cl, idx, function(ix) tryCatch(flic_effect(s64[ix, ]), error = function(e) NA_real_, warning = function(w) NA_real_))
stopCluster(cl)
bt <- unlist(bt)
n_fail <- sum(is.na(bt))
flic_ci <- quantile(bt, c(0.025, 0.975), na.rm = TRUE)

prim <- tibble(
  claim_rows = "H3-OR,H3-P", estimator = "Firth penalised logit (logistf, PL)",
  N = nrow(s64), events = sum(s64$d_birth), n_param = length(coef(fit_out$fit)),
  beta = r$beta, pl_ci_lo = r$ci_lo, pl_ci_hi = r$ci_hi, plr_p = r$p, wald_se = r$wald_se,
  conv_full = r$conv_full, conv_null = r$conv_null, conv_ci_lo = r$conv_lo, conv_ci_hi = r$conv_hi,
  recovery = fit_out$recovery,
  ml_beta_same_sample = b_ml,
  flic_discrete_effect = flic_hat, flic_ci_lo = flic_ci[[1]], flic_ci_hi = flic_ci[[2]], flic_boot_B = B, flic_boot_failed = n_fail,
  logistf_version = as.character(packageVersion("logistf"))
)
write_csv(prim, file.path(out, "t5_primary_raw.csv"))
print(t(prim))
