# P18_FvFS S6 - 01_primary.R: primary analysis of method card s4 and verdicts of s8 (card frozen at 404b4fb)
# Weighted PPML (fepois, aw = hhsize) of wine per household member on the published regressors,
# CR1 by normalised surname; CV3 jackknife if < 30 WH clusters; Holm p, Bonferroni CI (1 - 0.05/3).
source("./P18_FvFS/modern/00_data.R")
set.seed(SEED)

# ---- 0. Outcome construction check: ln(max(wine_pm, 0.001)) == published l_wine_zero ----
chk_y <- log(pmax(d$wine, 0.001))
diff_y <- abs(chk_y - d$l_wine_zero)
outcome_check <- tibble(n = nrow(d), n_zero = sum(d$wine == 0), n_pos_below_0.001 = sum(d$wine > 0 & d$wine < 0.001),
  n_missing_wine = sum(is.na(d$wine)), max_abs_diff = max(diff_y), n_diff_gt_1e6 = sum(diff_y > 1e-6),
  stored_type_note = "l_wine_zero stored as Stata float; diffs at float precision only")
print(outcome_check)
stopifnot(outcome_check$n_diff_gt_1e6 == 0, outcome_check$n_missing_wine == 0)
write_csv(outcome_check, file.path(od, "outcome_check.csv"))

# ---- 1. Original-code baseline (OLS on l_wine_zero, aw, HC1): must equal published_spec_est ----
fit_ols_pub <- function(spec) {
  m <- feols(as.formula(paste("l_wine_zero ~", rhs_of(spec))), sample_of(spec), weights = ~hhsize, vcov = "hetero")
  c(b = unname(coef(m)[WH]), se = unname(se(m)[WH]), N = nobs(m))
}

# ---- 2. Primary PPML ----
fit_ppml <- function(spec, data = d, w = TRUE, xset = "pub", vc = ~sur, y = "wine", offset = NULL) {
  s <- sample_of(spec, data)
  fepois(as.formula(paste(y, "~", rhs_of(spec, xset))), s, weights = if (w) ~hhsize else NULL,
         offset = offset, vcov = vc)
}

clus_diag <- function(spec, m) {
  s <- sample_of(spec)
  keep <- if (is.null(m$obs_selection$obsRemoved)) seq_len(nrow(s)) else setdiff(seq_len(nrow(s)), -m$obs_selection$obsRemoved)
  e <- s[keep, ]
  wh <- e |> filter(group == 3) |> count(sur, name = "n_wh")
  all <- e |> count(sur)
  tibble(claim_id = claims$claim_id[claims$spec == spec], N_sample = nrow(s), N_est = nobs(m),
         n_removed_fe_sep = nrow(s) - nobs(m), n_wh_est = sum(e$group == 3),
         n_clusters = n_distinct(e$sur), n_wh_clusters = nrow(wh),
         largest_cluster_n = max(all$n), largest_cluster_share_all = max(all$n) / nrow(e),
         largest_wh_cluster = wh$sur[which.max(wh$n_wh)], largest_wh_cluster_share_of_wh = max(wh$n_wh) / sum(wh$n_wh),
         small_cluster_rule = nrow(wh) < 30)
}

# CV3 leave-one-cluster-out jackknife by re-estimation (MacKinnon, Nielsen and Webb 2023)
jack_cv3 <- function(spec, m) {
  s <- sample_of(spec); b0 <- unname(coef(m)[WH]); cl <- unique(s$sur)
  bj <- vapply(cl, function(k) {
    mm <- try(fit_ppml(spec, data = d[d$sur != k, ], vc = "iid"), silent = TRUE)
    if (inherits(mm, "try-error") || !WH %in% names(coef(mm))) NA_real_ else unname(coef(mm)[WH]) }, 0)
  G <- sum(!is.na(bj))
  list(se = sqrt((G - 1) / G * sum((bj - b0)^2, na.rm = TRUE)), G = G, n_fail = sum(is.na(bj)))
}

zB <- qnorm(1 - 0.05 / 6)   # Bonferroni two-sided at 1 - 0.05/3
res <- list(); diag <- list()
for (i in seq_len(nrow(claims))) {
  sp <- claims$spec[i]
  o <- fit_ols_pub(sp)
  m <- fit_ppml(sp)
  dg <- clus_diag(sp, m)
  est_ok <- WH %in% names(coef(m)) && !is.na(coef(m)[WH])
  b <- unname(coef(m)[WH]); se_cr1 <- unname(se(m)[WH]); p_cr1 <- unname(pvalue(m)[WH])
  if (dg$small_cluster_rule) {
    jk <- jack_cv3(sp, m); se_use <- jk$se; dfj <- jk$G - 1
    p_use <- 2 * pt(abs(b / se_use), dfj, lower.tail = FALSE); q <- qt(1 - 0.05 / 6, dfj); inf <- sprintf("CV3 jackknife (G = %d, t(G-1))", jk$G)
    dg$cv3_se <- jk$se; dg$cv3_G <- jk$G; dg$cv3_failed <- jk$n_fail
  } else {
    se_use <- se_cr1; p_use <- p_cr1; q <- zB; inf <- "CR1 surname (fixest default ssc, normal)"
    dg$cv3_se <- NA; dg$cv3_G <- NA; dg$cv3_failed <- NA
  }
  diag[[i]] <- dg
  res[[i]] <- tibble(claim_id = claims$claim_id[i], estimable = est_ok,
    ols_pub_b = o["b"], ols_pub_se_hc1 = o["se"], ols_pub_N = o["N"], ols_pub_theta = exp(o["b"]) - 1,
    ppml_b = b, se_cr1 = se_cr1, p_cr1 = p_cr1, se_primary = se_use, p_raw = p_use, inference = inf,
    ci95_lo = exp(b - qnorm(0.975) * se_use) - 1, ci95_hi = exp(b + qnorm(0.975) * se_use) - 1,
    b_lo_bonf = b - q * se_use, b_hi_bonf = b + q * se_use,
    N_sample = dg$N_sample, N_est = dg$N_est, n_removed_fe_sep = dg$n_removed_fe_sep)
}
primary <- bind_rows(res) |> mutate(p_holm = p.adjust(p_raw, "holm"), theta = exp(ppml_b) - 1,
  ci_lo = exp(b_lo_bonf) - 1, ci_hi = exp(b_hi_bonf) - 1)
diagnostics <- bind_rows(diag)

# check that the original-code baseline equals the S2/A' published-spec run
pse <- read_csv(file.path(root, "repro_original/published_spec_est.csv"), show_col_types = FALSE) |>
  filter(term == "3.group", (tab == "T3" & col == "4") | (tab == "T4" & col %in% c("7", "10")))
stopifnot(max(abs(sort(pse$b) - sort(primary$ols_pub_b))) < 1e-6)

# ---- 3. Verdict table (card s8), applied in order ----
verdict_rule <- function(est, th, p, hi, M) {
  if (!est) return(c("not-testable", 0))
  if (th < 0 && p < 0.05) return(c("overturned", 1))
  if (hi < 0.10) return(c("overturned", 2))
  if (p < 0.05 && th > 0 && th >= M) return(c("confirmed", 3))
  if (p < 0.05 && th > 0 && th < M) return(c("qualified", 4))
  if (p >= 0.05 && th > 0) return(c("weakened", 5))
  c("weakened", 6)
}
verdict <- primary |> left_join(claims |> select(claim_id, M), by = "claim_id") |> rowwise() |>
  mutate(v = list(verdict_rule(estimable, theta, p_holm, ci_hi, M)), verdict = v[1], rule_number = as.integer(v[2])) |>
  ungroup() |> select(claim_id, theta, ci_lo, ci_hi, p_holm, M, verdict, rule_number)

write_csv(primary, file.path(od, "primary.csv"))
write_csv(diagnostics, file.path(od, "cluster_diagnostics.csv"))
write_csv(verdict, file.path(od, "verdict.csv"))
print(as.data.frame(primary), digits = 4); print(as.data.frame(diagnostics), digits = 4); print(as.data.frame(verdict), digits = 4)
writeLines(c(capture.output(sessionInfo()), "", paste("fixest", packageVersion("fixest")),
             paste("fwildclusterboot", packageVersion("fwildclusterboot"))), file.path(root, "modern", "sessionInfo.txt"))
