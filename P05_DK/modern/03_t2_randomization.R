# P05_DK S6 step 3 (card §4B): reproduction gate, randomization test for one treated cell (July 1919 births),
# exact inversion for the Bonferroni confidence set, H2-pct, and the serial-dependence calibration (§5 item 25).
# Data: aggregate month-year counts of white voters by month of birth (no individual rows are read or written).
# Usage (project root): Rscript P05_DK/modern/03_t2_randomization.R
source("./P05_DK/modern/common.R")
suppressPackageStartupMessages(library(haven))

vr <- as.data.frame(zap_labels(read_dta(file.path(ELIE, "voter_roll_birth.dta"))))
s <- vr |> filter(yearbirth >= 1915, yearbirth <= 1923) |> transmute(year = as.integer(yearbirth), month = as.integer(monthbirth), y = p)
s <- s[order(s$year, s$month), ]
if (nrow(s) != 108 || anyDuplicated(s[c("year", "month")]) || !all(table(s$year) == 12) || !all(s$month %in% 1:12) || anyNA(s$y))
  stop("SAFEGUARD STOP: the 1915-1923 grid is not a complete 9 x 12 grid")
n <- nrow(s); Tt <- which(s$year == 1919 & s$month == 7)
s$D <- as.integer(seq_len(n) == Tt)

# ---------------------------------------------------------------- point estimate and gate
m <- lm(y ~ D + factor(year) + factor(month), data = s)
theta <- unname(coef(m)["D"]); se_cl <- sqrt(vcov(m)["D", "D"])
off <- read.csv(file.path(ROOT, P, "compare", "s5_checks", "01_table2_offsets.csv"))
g <- off[off$birth == "1919-07", ][1, ]
gate <- data.frame(row = "H2", theta = theta, se_classical = se_cl, theta_S5 = g$coef, se_S5 = g$se_ols,
                   theta_card = -460.647727272724, se_card = 110.832058437886)
gate$pass <- gate_ok(theta, gate$theta_card) && gate_ok(se_cl, gate$se_card)
print(gate, digits = 15); write.csv(gate, file.path(OUT, "gate_t2.csv"), row.names = FALSE)
if (!gate$pass) stop("REPRODUCTION GATE FAILED (H2): H2-n and H2-pct not-testable")

# ---------------------------------------------------------------- randomization test, card §4B
X <- model.matrix(~ factor(year) + factor(month), data = s)
H <- X %*% solve(crossprod(X), t(X)); M <- diag(n) - H
a <- as.vector(M %*% s$y); cvec <- M[, Tt]
tol <- TOL_TIE * max(abs(a))
pfun <- function(th) { u <- abs(a - th * cvec); mean(u >= u[Tt] - tol) }   # ties resolved for non-rejection
p0 <- pfun(0)
stopifnot(abs(cvec[Tt] - (1 - 20 / 108)) < 1e-12)
if (!(cvec[Tt] > max(abs(cvec[-Tt])))) stop("SAFEGUARD STOP: boundedness condition c_T > max|c_t| fails")
# exact inversion: breakpoints where |a_t - th c_t| = |a_T - th c_T|
bp <- c()
for (t in seq_len(n)[-Tt]) {
  if (abs(cvec[t] - cvec[Tt]) > 0) bp <- c(bp, (a[t] - a[Tt]) / (cvec[t] - cvec[Tt]))
  if (abs(cvec[t] + cvec[Tt]) > 0) bp <- c(bp, (a[t] + a[Tt]) / (cvec[t] + cvec[Tt]))
}
bp <- sort(unique(bp)); nb <- length(bp)
mids <- c(bp[1] - 1, (bp[-1] + bp[-nb]) / 2, bp[nb] + 1)
p_bp <- sapply(bp, pfun); p_mid <- sapply(mids, pfun)
stopifnot(p_mid[1] < ALPHA, p_mid[nb + 1] < ALPHA)                      # bounded set
# step function: pieces in order mid0, bp1, mid1, bp2, ..., bpn, midn
pieces <- data.frame(kind = c("open", rep(c("point", "open"), nb)),
                     lo = c(-Inf, as.vector(rbind(bp, bp))), hi = c(as.vector(rbind(bp, bp)), Inf),
                     p = c(p_mid[1], as.vector(rbind(p_bp, p_mid[-1]))))
pieces$acc <- pieces$p >= ALPHA
# merge accepted consecutive pieces into closed intervals
comp <- list(); cur <- NULL
for (i in seq_len(nrow(pieces))) {
  if (pieces$acc[i]) { if (is.null(cur)) cur <- c(pieces$lo[i], pieces$hi[i]) else cur[2] <- pieces$hi[i] }
  else if (!is.null(cur)) { comp[[length(comp) + 1]] <- cur; cur <- NULL }
}
if (!is.null(cur)) comp[[length(comp) + 1]] <- cur
comp <- do.call(rbind, comp); colnames(comp) <- c("lo", "hi")
C_lo <- min(comp[, "lo"]); C_hi <- max(comp[, "hi"])
stopifnot(pfun(theta) == 1, theta >= C_lo, theta <= C_hi)
stopifnot((p0 < ALPHA) == !any(comp[, "lo"] <= 0 & comp[, "hi"] >= 0))
cat(sprintf("theta %.4f | p(0) = %.6f (%d/108) | C components %d | hull [%.4f, %.4f]\n", theta, p0, round(p0 * n), nrow(comp), C_lo, C_hi))

# ---------------------------------------------------------------- H2-pct (card §3, §4B)
ybar <- mean(s$y)
if (!is.finite(ybar) || ybar <= 0) stop("H2-pct not-testable (ybar)")
Pct <- 100 * theta / ybar
cat(sprintf("ybar %.4f | P = %.4f%% | set hull [%.4f, %.4f]%%\n", ybar, Pct, 100 * C_lo / ybar, 100 * C_hi / ybar))

# reported: five largest |u_t(0)| with their cells; the full step function
top5 <- data.frame(year = s$year, month = s$month, resid0 = a)[order(-abs(a)), ][1:5, ]
write.csv(top5, file.path(OUT, "t2_top5_null_residuals.csv"), row.names = FALSE)
write.csv(pieces[, c("kind", "lo", "hi", "p", "acc")], file.path(OUT, "t2_pvalue_step_function.csv"), row.names = FALSE)
write.csv(data.frame(component = seq_len(nrow(comp)), lo = comp[, "lo"], hi = comp[, "hi"],
                     lo_pct = 100 * comp[, "lo"] / ybar, hi_pct = 100 * comp[, "hi"] / ybar),
          file.path(OUT, "t2_confidence_set_components.csv"), row.names = FALSE)

# ---------------------------------------------------------------- §5 item 25: serial-dependence calibration (never votes)
u0 <- a                                       # null residuals in calendar order (s is sorted by year, month)
ac <- acf(u0, lag.max = 24, plot = FALSE)$acf[, 1, 1]
lb12 <- Box.test(u0, lag = 12, type = "Ljung-Box"); lb24 <- Box.test(u0, lag = 24, type = "Ljung-Box")
rho_hat <- ac[2]
sig2 <- sum(u0^2) / (n - qr(X)$rank)          # residual variance of the null model (marginal variance of u)
gam <- coef(lm(s$y ~ X - 1)); mu <- as.vector(X %*% gam)
R <- 5000
sim_p0 <- function(rho, seed_stream) {
  assign(".Random.seed", seed_stream, envir = .GlobalEnv)
  sd_e <- sqrt(sig2 * (1 - rho^2))
  rej1 <- rej2 <- logical(R)
  for (r in seq_len(R)) {
    e <- rnorm(n); u <- numeric(n); u[1] <- sqrt(sig2) * e[1]
    for (t in 2:n) u[t] <- rho * u[t - 1] + sd_e * e[t]
    ar <- as.vector(M %*% (mu + u)); pp <- mean(abs(ar) >= abs(ar[Tt]) - TOL_TIE * max(abs(ar)))
    rej1[r] <- pp < ALPHA; rej2[r] <- pp < 0.05
  }
  c(rej_alpha_prime = mean(rej1), mcse_alpha_prime = sqrt(mean(rej1) * (1 - mean(rej1)) / R),
    rej_05 = mean(rej2), mcse_05 = sqrt(mean(rej2) * (1 - mean(rej2)) / R))
}
RNGkind("L'Ecuyer-CMRG"); set.seed(SEED); st <- .Random.seed
rhos <- c(0, 0.25, 0.5, rho_hat); cal <- list()
for (i in seq_along(rhos)) { st <- parallel::nextRNGStream(st); cal[[i]] <- c(rho = rhos[i], sim_p0(rhos[i], st)) }
RNGkind("default")
cal <- as.data.frame(do.call(rbind, cal)); cal$label <- c("0", "0.25", "0.5", "rho_hat")
cal$size_above_nominal_flag <- cal$rej_alpha_prime - 2 * cal$mcse_alpha_prime > ALPHA
print(cal)
calib <- list(acf1 = ac[2], acf12 = ac[13], lb12_stat = unname(lb12$statistic), lb12_p = lb12$p.value,
              lb24_stat = unname(lb24$statistic), lb24_p = lb24$p.value, rho_hat = rho_hat)
write.csv(cbind(cal, as.data.frame(calib)), file.path(OUT, "t2_calibration_item25.csv"), row.names = FALSE)

res <- data.frame(row = c("H2-n", "H2-pct"), estimate = c(theta, Pct), p0 = p0, p0_count = round(p0 * n),
                  ci_lo = c(C_lo, 100 * C_lo / ybar), ci_hi = c(C_hi, 100 * C_hi / ybar), n_components = nrow(comp),
                  ybar = ybar, se_classical = se_cl, n_breakpoints = nb, c_T = cvec[Tt], max_abs_c_other = max(abs(cvec[-Tt])),
                  calibration_flag = any(cal$size_above_nominal_flag))
write.csv(res, file.path(SCR, "primary_t2.csv"), row.names = FALSE)
saveRDS(list(s = s, a = a, cvec = cvec, M = M, Tt = Tt, theta = theta, ybar = ybar, comp = comp), file.path(SCR, "t2.rds"))
print(res)
cat("03_t2_randomization done\n")
