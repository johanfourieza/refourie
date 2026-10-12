# P09_FIM S6 02_primary.R. Card §4A (T2 verdict rows, Family D) and §4B (recruit-pattern primary, Family T).
# Order: verification checks first (T2 reproduction from 01_sample.R; S1 anchor against the S5 proxy p1),
# then the primary estimates. Writes aggregate output only; the Stata extract goes to D: scratch.
source("./P09_FIM/modern/00_common.R")
suppressPackageStartupMessages(library(haven))

ck <- read_csv(file.path(OUT, "check_sample.csv"), show_col_types = FALSE)
REPRO_OK <- ck$value[1] == 1
if (!REPRO_OK) stop("§4 reproduction check failed: T2 rows not-testable, R rows not computable (log in DEVIATIONS.md)")
s <- prep(load_sample())

# ---- Verification: S1 anchor (published col 1 analogue) must reproduce s5_headline_proxies p1 to 1e-3 ----
anc <- run_tn(height ~ cohort + attest, s, c = H63, keep = function(d) d$height >= H63 - EPS)
p1 <- read_csv(file.path(ROOT, P, "compare", "s5_checks", "s5_headline_proxies.csv"), show_col_types = FALSE) %>%
  filter(variant == "p1_cohort_attest")
own <- tibble(term = names(anc$fit$coef), est = anc$fit$coef, se_rob = sqrt(diag(anc$V))) %>%
  mutate(est = if_else(term == "lnsig", exp(est), est), term = if_else(term == "lnsig", "sigma", term))
av <- p1 %>% select(term, est_s5 = est, se_s5 = se_rob, n_s5 = n) %>% left_join(own, by = "term") %>%
  mutate(d_est = abs(est - est_s5), pass = d_est <= 1e-3 + 5e-4)   # S5 file rounded to 3 dp: tolerance 1e-3 + rounding
av$n <- anc$fit$n
write_csv(av %>% mutate(across(where(is.double), ~ signif(.x, 7))), file.path(OUT, "check_s1_anchor.csv"))
cat("S1 anchor reproduces S5 p1:", all(av$pass), " max |d| =", max(av$d_est), " N =", anc$fit$n, "\n")

# ---- §4A Family D (T2 verdict rows) --------------------------------------------------------------
m <- s %>% group_by(cohort = as.character(cohort)) %>% summarise(m = mean(height), s2 = var(height), n = n()) %>%
  arrange(match(cohort, COH))
famD <- function(m) {
  v <- m$s2 / m$n; j <- c(1, 2, 3, 5, 6)
  e <- m$m[j] - m$m[4]; se <- sqrt(v[j] + v[4])
  V <- matrix(v[4], 5, 5); diag(V) <- v[j] + v[4]; R <- cov2cor(V)
  # qmvnorm reports no error estimate; the error is the GenzBretz absolute error of P(max|Z| <= c_D) at the solution
  qerr <- function(mp) {
    set.seed(SEED)
    q <- qmvnorm(0.95, tail = "both.tails", corr = R, algorithm = GenzBretz(maxpts = mp, abseps = 1e-6))
    set.seed(SEED)
    pp <- pmvnorm(lower = rep(-q$quantile, 5), upper = rep(q$quantile, 5), corr = R,
                  algorithm = GenzBretz(maxpts = mp, abseps = 1e-6))
    list(q = q, err = attr(pp, "error"))
  }
  maxpts <- 250000; z <- qerr(maxpts)
  if (z$err > 1e-5) { maxpts <- 2500000; z <- qerr(maxpts) }
  q <- z$q; err <- z$err
  cD <- q$quantile
  tibble(contrast = paste0("e", j), cohort = m$cohort[j], est = e, se = se, c_D = cD, c_D_err = err, maxpts = maxpts,
         lo = e - cD * se, hi = e + cD * se, p_unadj = 2 * pnorm(-abs(e / se)))
}
fD <- famD(m)
fail_D <- any(m$n < 2) || !is.finite(fD$c_D[1])

# ---- §4B primary --------------------------------------------------------------------------------
f_prim <- height ~ cohort + force + g21 + g22
pr <- run_tn(f_prim, s, expected_rank = 4)
fit <- pr$fit; d <- pr$d
cat("Primary: N =", fit$n, " converged =", fit$conv, " max|g| =", signif(fit$maxg, 3), " retried =", fit$retried, "\n")
coefs <- tibble(term = names(fit$coef), est = fit$coef, se_sand = sqrt(diag(pr$V)), se_model = sqrt(diag(V_model(fit)))) %>%
  mutate(z = est / se_sand, p = 2 * pnorm(-abs(z)))
ft <- pr$T
fnd <- findings_from(ft)

# Boundary-sensitivity flag (card §10.15): a CI endpoint within c_T's Monte Carlo error (x se) of a boundary
bflag <- ft %>% mutate(err = c_T_mcse * se,
  near0 = pmin(abs(lo), abs(hi)) < err,
  nearnull = contrast %in% c("b65", "b15") &
    (abs(lo + 0.5 * B0[ifelse(contrast == "b15", "b15", "b65")]) < err | abs(hi - 0.5 * B0[ifelse(contrast == "b15", "b15", "b65")]) < err))
iu_p <- max(ft$p_dir[ft$contrast %in% c("d1", "d2", "d3")])

# ---- §4B reported items --------------------------------------------------------------------------
agegrp <- function(a) case_when(a == 21 ~ "21", a == 22 ~ "22", TRUE ~ "23-49")
n_fc <- d %>% count(force, cohort) %>% mutate(table = "force x cohort", lt30 = n < 30) %>% rename(cell = cohort)
n_fa <- d %>% count(force, cell = agegrp(age)) %>% mutate(table = "force x age group", lt30 = n < 30)
cells <- bind_rows(n_fc %>% mutate(cell = as.character(cell)), n_fa) %>% select(table, force, cell, n, lt30)
write_csv(cells, file.path(OUT, "primary_cells.csv"))
heap <- s %>% group_by(force) %>% summarise(n_all = n(), at_63in = sum(abs(height - H63) < 1e-6),
  between_c_and_63in = sum(height > C0 & height < H63 - 1e-6), at_or_below_c = sum(height <= C0 + 1e-9),
  in_primary = sum(height >= C0 + EPS))
write_csv(heap, file.path(OUT, "primary_heaping.csv"))
grp <- d %>% count(force, year)
grp_sum <- tibble(item = c("force x enlistment-year groups", "group size min", "group size median", "group size max",
                           "largest group share of N", "candidate repeat pairs (name + surname + birth year) in sample",
                           "records in candidate repeat pairs"),
                  value = c(nrow(grp), min(grp$n), median(grp$n), max(grp$n), max(grp$n) / nrow(d),
                            n_distinct(d$pair_cl[d$pair_k > 1]), sum(d$pair_k > 1)))
write_csv(grp_sum, file.path(OUT, "primary_grouping.csv"))

# ---- Outputs -------------------------------------------------------------------------------------
prim <- bind_rows(
  coefs %>% transmute(block = "T3 primary coefficient", item = term, est, se = se_sand, lo = NA, hi = NA, p = p,
                      note = sprintf("model-based se %.4f", se_model)),
  ft %>% transmute(block = "Family T contrast", item = contrast, est, se, lo, hi, p = p_unadj,
                   note = sprintf("c_T %.5f (MC se %.5f; rank %d); one-sided p(H0: <= 0) %.4g", c_T, c_T_mcse, rank, p_dir)),
  tibble(block = "T3 primary fit", item = c("N", "sigma", "loglik", "max|gradient|", "converged", "c_T", "c_T MC se",
                                            "R-dec intersection-union p"),
         est = c(fit$n, exp(fit$coef["lnsig"]), fit$ll, fit$maxg, fit$conv, ft$c_T[1], ft$c_T_mcse[1], iu_p)),
  m %>% transmute(block = "T2 cohort mean", item = cohort, est = m, se = sqrt(s2 / n), note = paste("n", n)),
  fD %>% transmute(block = "Family D contrast", item = paste(contrast, cohort, "minus 1895_1904"), est, se, lo, hi,
                   p = p_unadj, note = sprintf("c_D %.5f (GenzBretz error %.2e, maxpts %d)", c_D, c_D_err, maxpts))
)
write_csv(prim %>% mutate(across(where(is.double), ~ signif(.x, 7))), file.path(OUT, "primary.csv"), na = "")
write_csv(fnd, file.path(OUT, "primary_findings.csv"))
write_csv(bflag %>% select(contrast, lo, hi, err, near0, nearnull), file.path(OUT, "primary_boundary_flags.csv"))
saveRDS(list(m = m, fD = fD, fail_D = fail_D, ft = ft, fnd = fnd, coefs = coefs, iu_p = iu_p, fit_n = fit$n,
             sigma = exp(fit$coef["lnsig"]), ll = fit$ll, conv = fit$conv, bflag = bflag),
        file.path(OUT, "primary_objects.rds"))

# ---- Stata extract (D: only) for 02b_truncreg_check.do --------------------------------------------
st <- s %>% transmute(id = rid, height = as.double(height), age, attest,
  c65 = as.numeric(cohort == "1865_1874"), c75 = as.numeric(cohort == "1875_1884"), c95 = as.numeric(cohort == "1895_1904"),
  c05 = as.numeric(cohort == "1905_1914"), c15 = as.numeric(cohort == "1915_1920"),
  fSAC = as.numeric(force == "SAC"), fCMP = as.numeric(force == "CMP"), fAOF = as.numeric(force == "AOF"),
  fWWII = as.numeric(force == "WWII"), g21, g22)
write_dta(st, file.path(SCR, "p09_stata_check.dta"))
write_csv(tibble(term = names(fit$coef), est = fit$coef, se = sqrt(diag(pr$V))), file.path(SCR, "r_primary_coef.csv"))
print(ft); print(fnd); print(fD)
