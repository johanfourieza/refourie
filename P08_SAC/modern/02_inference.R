# =============================================================================
# P08_SAC  S6 modern reanalysis  --  02_inference.R
# Primary and secondary inference for the five inferential hypotheses
# (card §4, §8): I4 (Afrikaans, spec 4), I5 (England, spec 4), I3a, I3b, I6-C.
#   I4/I5: primary = WCR bootstrap (Webb, B = 9,999, clusters EYear x EMonth,
#          seed 20261011, null imposed, two-sided, 99% CI by test inversion);
#          secondary = HC3 with t(N-k). Diagnostics: G, cluster sizes, G1,
#          largest-treated-cluster share, G* (CSS), CR2 + BM df, max leverage,
#          HC1 and conventional SEs.
#   I3a/I3b/I6-C: primary = HC2 (Welch) difference in means with Satterthwaite
#          df; secondary = CR2 by EYear x EMonth with BM df.
# Level 0.01 (Bonferroni, m = 5); every CI is the 99% inversion of its test.
# Output: D: scratch inference.rds / primary_inferential.csv (aggregates; merged into output/primary.csv by 04).
# =============================================================================
suppressMessages({library(tidyverse); library(sandwich); library(clubSandwich)
  library(fwildclusterboot); library(dqrng)})
PROJ <- "."
source(file.path(PROJ, "tools", "paths.R"))
MOD <- file.path(PROJ, "P08_SAC", "modern"); OUT <- file.path(MOD, "output")
SCR <- dscratch("P08_SAC", "modern")
d <- readRDS(file.path(SCR, "sac_all.rds")); W <- readRDS(file.path(SCR, "wage_sample.rds"))
ver <- readRDS(file.path(SCR, "verification.rds"))
ALPHA <- 0.01; SEED <- 20261011; SEED2 <- 20261012; B <- 9999

# ---------------------------------------------------------------- helpers ---
# Carter-Schnepel-Steigerwald effective number of clusters, rho = 1 (DEVIATIONS D4)
gstar <- function(m, term, cl, rho = 1) {
  X <- model.matrix(m); keep <- !is.na(coef(m)); X <- X[, keep, drop = FALSE]
  a <- solve(crossprod(X))[, which(colnames(X) == term)]
  s <- as.vector(X %*% a); gam <- if (rho == 1) tapply(s, cl, sum)^2 else tapply(s^2, cl, sum)
  G <- length(gam); Gam <- mean((gam - mean(gam))^2) / mean(gam)^2
  G / (1 + Gam) }
tdf_test <- function(b, se, df, level = 1 - ALPHA) {
  q <- qt(1 - (1 - level) / 2, df)
  c(se = se, df = df, p = 2 * pt(-abs(b / se), df), lo = b - q * se, hi = b + q * se) }
run_wcr <- function(m, param, clustid, data, type = "webb", seed = SEED, bootcluster = "max") {
  set.seed(seed); dqrng::dqset.seed(seed)
  out <- tryCatch(boottest(m, param = param, B = B, clustid = clustid, bootcluster = bootcluster,
                           type = type, sign_level = ALPHA, impose_null = TRUE,
                           p_val_type = "two-tailed", conf_int = TRUE),
                  error = function(e) e)
  if (inherits(out, "error")) return(list(ok = FALSE, msg = conditionMessage(out)))
  tb <- out$t_boot; ci <- out$conf_int
  ok <- is.finite(out$t_stat) && is.finite(out$p_val) && length(unique(round(tb, 10))) >= 399
  list(ok = ok, p = out$p_val, t = out$t_stat, lo = ci[1], hi = ci[2], n_distinct = length(unique(round(tb, 10))),
       msg = if (ok) "" else "non-finite or <399 distinct bootstrap statistics") }
wcr_with_retry <- function(...) {
  r <- run_wcr(..., seed = SEED); r$seed <- SEED; r$attempts <- 1
  if (!isTRUE(r$ok)) { r2 <- run_wcr(..., seed = SEED2); r2$seed <- SEED2; r2$attempts <- 2; r <- r2 }
  r }

# ------------------------------------------------- I4 / I5: wage spec 4 ---
f4 <- lwage ~ afr + age + height + weight + married + hisco_f + reg_f + yr_f
W <- W %>% mutate(ym = factor(ym))
m4 <- lm(f4, data = W)
k <- sum(!is.na(coef(m4))); N <- nobs(m4); dfr <- N - k
V_conv <- vcov(m4); V_hc1 <- vcovHC(m4, type = "HC1"); V_hc3 <- vcovHC(m4, type = "HC3")
lev <- hatvalues(m4)
cs <- table(W$ym)
CR2 <- coef_test(m4, vcov = "CR2", cluster = W$ym, test = "Satterthwaite",
                 coefs = c("afr", "reg_f1"))

wage_rows <- list()
for (rw in list(list(id = "I4", term = "afr", treat = W$afr == 1),
                list(id = "I5", term = "reg_f1", treat = W$regiondum == 1))) {
  b <- unname(coef(m4)[rw$term])
  tr_cl <- table(W$ym[rw$treat]); tr_cl <- tr_cl[tr_cl > 0]
  G1 <- length(tr_cl); shmax <- max(tr_cl) / sum(tr_cl)
  Gs <- gstar(m4, rw$term, W$ym)
  flag <- (G1 < 10) | (shmax > 0.5) | (Gs < 10)
  w <- wcr_with_retry(m4, param = rw$term, clustid = "ym", data = W)
  hc3 <- tdf_test(b, sqrt(V_hc3[rw$term, rw$term]), dfr)
  cr2 <- CR2[CR2$Coef == rw$term, ]
  wage_rows[[rw$id]] <- tibble(
    hyp = rw$id, estimand = paste0("spec 4 OLS coefficient on ", ifelse(rw$id == "I4", "Afrikaans", "England (ref. Boer republics)")),
    estimate = b, n = N, primary_test = "WCR (Webb, B=9999, clusters EYear x EMonth)",
    p1 = if (isTRUE(w$ok)) w$p else NA_real_, ci99_lo = if (isTRUE(w$ok)) w$lo else NA_real_,
    ci99_hi = if (isTRUE(w$ok)) w$hi else NA_real_, wcr_ok = isTRUE(w$ok), wcr_attempts = w$attempts,
    wcr_seed = w$seed, wcr_t = if (isTRUE(w$ok)) w$t else NA_real_, wcr_n_distinct = if (!is.null(w$n_distinct)) w$n_distinct else NA_integer_,
    secondary_test = "HC3, t(N-k)", p2 = hc3[["p"]], se2 = hc3[["se"]], ci2_lo = hc3[["lo"]], ci2_hi = hc3[["hi"]],
    G = length(cs), cl_min = min(cs), cl_med = median(as.numeric(cs)), cl_max = max(cs),
    G1_treated = G1, share_largest_treated = shmax, Gstar_rho1 = Gs, Gstar_rho0_reported_only = gstar(m4, rw$term, W$ym, rho = 0), validity_flag = flag,
    se_cr2 = cr2$SE, df_cr2_bm = cr2$df_Satt, p_cr2 = cr2$p_Satt,
    se_hc1 = sqrt(V_hc1[rw$term, rw$term]), se_conv = sqrt(V_conv[rw$term, rw$term]),
    max_leverage = max(lev), wcr_msg = w$msg)
}
wage_tab <- bind_rows(wage_rows)
print(wage_tab %>% select(hyp, estimate, p1, ci99_lo, ci99_hi, p2, G, G1_treated, share_largest_treated, Gstar_rho1, validity_flag,
                          se_cr2, df_cr2_bm, se_hc1, se_conv, max_leverage) %>% as.data.frame(), digits = 5)

# --------------------------------- I3a, I3b, I6-C: differences in means ---
first <- d %>% filter(repeatlast == 0, !is.na(regiondum)) %>% mutate(ym = factor(ym))
diff_test <- function(dat, y, g1, label, hyp, estimand) {
  # g1: logical, TRUE = first group (the claimed-higher or claimed-lower group); Delta = mean(g1) - mean(g0)
  dd <- dat %>% mutate(.y = .data[[y]], .g = as.numeric(g1)) %>% filter(!is.na(.y), !is.na(.g))
  x1 <- dd$.y[dd$.g == 1]; x0 <- dd$.y[dd$.g == 0]
  n1 <- length(x1); n0 <- length(x0)
  undefined <- n1 < 2 || n0 < 2 || var(x1) == 0 || var(x0) == 0
  D <- mean(x1) - mean(x0)
  if (undefined) { pr <- c(se = NA, df = NA, p = NA, lo = NA, hi = NA); s2 <- list(SE = NA, df_Satt = NA, p_Satt = NA); ci2 <- c(NA, NA) } else {
    v1 <- var(x1) / n1; v0 <- var(x0) / n0; se <- sqrt(v1 + v0)
    df <- (v1 + v0)^2 / (v1^2 / (n1 - 1) + v0^2 / (n0 - 1))
    pr <- tdf_test(D, se, df)
    m <- lm(.y ~ .g, data = dd)
    # check HC2 regression SE equals Welch SE
    stopifnot(abs(sqrt(vcovHC(m, type = "HC2")[".g", ".g"]) - se) < 1e-8)
    s2 <- coef_test(m, vcov = "CR2", cluster = dd$ym, test = "Satterthwaite", coefs = ".g")
    ci2 <- unlist(conf_int(m, vcov = "CR2", cluster = dd$ym, level = 1 - ALPHA, coefs = ".g")[, c("CI_L", "CI_U")])
  }
  tibble(hyp = hyp, estimand = estimand, estimate = D, n = n1 + n0, n_group1 = n1, n_group0 = n0,
         mean_group1 = mean(x1), mean_group0 = mean(x0),
         primary_test = "HC2 (Welch) difference in means, Satterthwaite df",
         p1 = pr[["p"]], se1 = pr[["se"]], df1 = pr[["df"]], ci99_lo = pr[["lo"]], ci99_hi = pr[["hi"]],
         secondary_test = "CR2 by EYear x EMonth, BM df", p2 = s2$p_Satt, se2 = s2$SE, df2 = s2$df_Satt,
         ci2_lo = ci2[1], ci2_hi = ci2[2], undefined = undefined)
}
h <- first %>% filter(regiondum %in% c(1, 9))
I3a <- diff_test(h, "height", h$regiondum == 9, hyp = "I3a", estimand = "mean height Cape/Natal-born minus England-born, Table 1 sample (cm)")
coh <- first %>% filter(regiondum %in% c(5, 9, 1, 8, 10), !is.na(birthyear), birthyear >= 1860, birthyear <= 1885)
I3b <- diff_test(coh, "height", coh$regiondum %in% c(5, 9), hyp = "I3b",
                 estimand = "mean height SA-territory-born minus GB-born, born 1860-1885 (cm)")
I6 <- diff_test(first, "wage", first$regiondum == 5, hyp = "I6-C",
                estimand = "mean wage Boer-republic-born minus all other first-term recruits (shillings/day)")
diff_tab <- bind_rows(I3a, I3b, I6)
print(diff_tab %>% select(hyp, estimate, n_group1, n_group0, p1, ci99_lo, ci99_hi, p2, ci2_lo, ci2_hi) %>% as.data.frame(), digits = 5)

# ------------------------------------------------------- verdict rules ---
vpass <- ver$verification
pub_ok_wage <- all(vpass$pass[vpass$check %in% c("spec4 b(Afrikaans)", "spec4 N", "spec4 b(England)")])
t1_ok <- all(vpass$pass[grepl("^T1", vpass$check)])
sec_flag <- function(p1, p2) !is.na(p1) & !is.na(p2) & ((p1 < ALPHA) != (p2 < ALPHA))

verdict_wage <- function(r, est, floor, dir) {
  # dir: +1 if 'at or above the floor' means est >= floor; -1 if est <= floor
  if (!pub_ok_wage || !r$wcr_ok) return(c("not-testable", "0"))
  if (r$validity_flag && r$p1 >= ALPHA) return(c("not-testable (primary inference unreliable: few treated clusters)", "1"))
  if (r$p1 >= ALPHA) return(c("weakened", "2"))
  above <- if (dir > 0) est >= floor else est <= floor
  if (!above) return(c("qualified (magnitude)", "3"))
  c("confirmed", "4") }
w4 <- wage_tab[wage_tab$hyp == "I4", ]; w5 <- wage_tab[wage_tab$hyp == "I5", ]
pct4 <- function(b) 100 * (1 - exp(b)); pct5 <- function(b) 100 * (1 - exp(-b))
rows <- list(
  tibble(claim = "I4-LP", estimate = w4$estimate, ci_lo = w4$ci99_lo, ci_hi = w4$ci99_hi, p1 = w4$p1, p2 = w4$p2,
         band = "b <= -0.0285 (50% floor of -0.057)", v = list(verdict_wage(w4, w4$estimate, -0.0285, -1)),
         plaus = abs(w4$estimate) > 0.0855, vflag = w4$validity_flag),
  tibble(claim = "I4-PCT", estimate = pct4(w4$estimate), ci_lo = pct4(w4$ci99_hi), ci_hi = pct4(w4$ci99_lo), p1 = w4$p1, p2 = w4$p2,
         band = "100(1-exp(b)) >= 2.55 (50% floor of 5.1%)", v = list(verdict_wage(w4, pct4(w4$estimate), 2.55, 1)),
         plaus = pct4(w4$estimate) > 7.65, vflag = w4$validity_flag),
  tibble(claim = "I5-LP", estimate = w5$estimate, ci_lo = w5$ci99_lo, ci_hi = w5$ci99_hi, p1 = w5$p1, p2 = w5$p2,
         band = "b >= 0.039 (50% floor of 0.078)", v = list(verdict_wage(w5, w5$estimate, 0.039, 1)),
         plaus = abs(w5$estimate) > 0.117, vflag = w5$validity_flag),
  tibble(claim = "I5-PCT", estimate = pct5(w5$estimate), ci_lo = pct5(w5$ci99_lo), ci_hi = pct5(w5$ci99_hi), p1 = w5$p1, p2 = w5$p2,
         band = "100(1-exp(-b)) >= 4.3 (50% floor of 8.6%)", v = list(verdict_wage(w5, pct5(w5$estimate), 4.3, 1)),
         plaus = pct5(w5$estimate) > 12.9, vflag = w5$validity_flag))

verdict_diff <- function(r, claim_sign, magfloor = NULL) {
  if (!t1_ok || r$undefined || r$estimate == 0 || sign(r$estimate) != claim_sign) return(c("not-testable (reproduction failure; refer to S4)", "0"))
  if (r$p1 >= ALPHA) return(c("weakened", "1"))
  if (!is.null(magfloor) && r$estimate < magfloor) return(c("qualified (magnitude)", "2"))
  c("confirmed", "3") }
verdict_I3b <- function(r) {
  if (r$undefined) return(c("not-testable", "0"))
  if (r$estimate < 0 && r$p1 < ALPHA) return(c("overturned (reversed)", "1"))
  if (r$estimate <= 0 && r$p1 >= ALPHA) return(c("weakened (direction lost)", "2"))
  if (r$estimate > 0 && r$p1 >= ALPHA) return(c("weakened", "3"))
  c("confirmed", "4") }
rows <- c(rows, list(
  tibble(claim = "I3a-C", estimate = I3a$estimate, ci_lo = I3a$ci99_lo, ci_hi = I3a$ci99_hi, p1 = I3a$p1, p2 = I3a$p2,
         band = "Delta > 0 and 99% CI excludes 0", v = list(verdict_diff(I3a, 1)), plaus = NA, vflag = NA),
  tibble(claim = "I3a-M", estimate = I3a$estimate, ci_lo = I3a$ci99_lo, ci_hi = I3a$ci99_hi, p1 = I3a$p1, p2 = I3a$p2,
         band = "Delta >= 1.06 cm and p1 < 0.01", v = list(verdict_diff(I3a, 1, 1.06)), plaus = I3a$estimate > 3.18, vflag = NA),
  tibble(claim = "I3b-C", estimate = I3b$estimate, ci_lo = I3b$ci99_lo, ci_hi = I3b$ci99_hi, p1 = I3b$p1, p2 = I3b$p2,
         band = "Delta > 0 and 99% CI excludes 0", v = list(verdict_I3b(I3b)), plaus = NA, vflag = NA),
  tibble(claim = "I6-C", estimate = I6$estimate, ci_lo = I6$ci99_lo, ci_hi = I6$ci99_hi, p1 = I6$p1, p2 = I6$p2,
         band = "Delta < 0 and 99% CI excludes 0", v = list(verdict_diff(I6, -1)), plaus = NA, vflag = NA)))
inf_verdicts <- bind_rows(rows) %>% mutate(verdict = map_chr(v, 1), rule = map_chr(v, 2), secondary_disagreement = sec_flag(p1, p2)) %>% select(-v)
print(inf_verdicts %>% as.data.frame(), digits = 5)

write_csv(bind_rows(wage_tab, diff_tab), file.path(SCR, "primary_inferential.csv"))  # merged into output/primary.csv by 04
saveRDS(list(wage = wage_tab, diff = diff_tab, verdicts = inf_verdicts), file.path(SCR, "inference.rds"))
write_csv(inf_verdicts, file.path(SCR, "inf_verdicts.csv"))
