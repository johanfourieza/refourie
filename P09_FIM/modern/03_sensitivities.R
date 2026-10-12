# P09_FIM S6 03_sensitivities.R. (a) R-vs-Stata reconciliation of the primary (card §4B), S1 and S10;
# (b) the exhaustive sensitivity list of card §5 (S1-S25). Reported; none votes. Aggregate output only.
source("./P09_FIM/modern/00_common.R")
suppressPackageStartupMessages({ library(sandwich); library(quantreg); library(parallel) })
t_start <- Sys.time()
s <- prep(load_sample())
PO <- readRDS(file.path(OUT, "primary_objects.rds"))
f_prim <- height ~ cohort + force + g21 + g22
prim <- run_tn(f_prim, s, expected_rank = 4)
NW <- 6                                                    # workers (card cap 8; shared machine)

res <- list(); fnd <- list(); extra <- list()
add_T <- function(id, label, target, ft, n, note = "") {
  res[[length(res) + 1]] <<- ft %>% transmute(sens = id, label, target, contrast, est, se, lo, hi, c_crit = c_T, n = n, note = note)
  fnd[[length(fnd) + 1]] <<- findings_from(ft) %>% mutate(sens = id, label = label, target = target)
}
add_run <- function(id, label, target, r, note = "") {
  note <- paste0(note, if (length(r$dropped)) paste0(" dropped empty: ", paste(r$dropped, collapse = " ")) else "",
                 if (!r$fit$conv) " NOT CONVERGED" else "")
  add_T(id, label, target, r$T, r$fit$n, trimws(note))
}

# ---- (a) Stata reconciliation ---------------------------------------------------------------------
st <- read_csv(file.path(OUT, "stata_check.csv"), show_col_types = FALSE) %>%
  mutate(term = sub("^eq1:", "", term), est = as.numeric(est), se = as.numeric(se))
map <- c(c65 = "cohort1865_1874", c75 = "cohort1875_1884", c95 = "cohort1895_1904", c05 = "cohort1905_1914",
         c15 = "cohort1915_1920", fSAC = "forceSAC", fCMP = "forceCMP", fAOF = "forceAOF", fWWII = "forceWWII",
         g21 = "g21", g22 = "g22", attest = "attest", `_cons` = "(Intercept)")
anc <- run_tn(height ~ cohort + attest, s, c = H63, keep = function(d) d$height >= H63 - EPS)
s10 <- lapply(c(0.05, 0.10), function(sh) {
  d2 <- s %>% mutate(h_orig = height, height = height + sh * pmax(0, age - 35))
  run_tn(f_prim, d2, c = function(d) C0 + sh * pmax(0, d$age - 35), keep = function(d) d$h_orig >= C0 + EPS, expected_rank = 4)
})
rfits <- list(primary = prim, s1_anchor = anc, s10_0.05 = s10[[1]], s10_0.10 = s10[[2]])
recon <- bind_rows(lapply(names(rfits), function(mn) {
  rr <- rfits[[mn]]; sm <- st %>% filter(model == mn, term %in% names(map)) %>% mutate(rterm = map[term])
  ctS <- contrasts_T(setNames(sm$est, sm$rterm), diag(length(sm$est)) %>% `dimnames<-`(list(sm$rterm, sm$rterm)))$est
  ctR <- rr$T$est[match(names(ctS), rr$T$contrast)]
  bind_rows(
    tibble(model = mn, item = sm$rterm, stata = sm$est, r = rr$fit$coef[sm$rterm], se_stata = sm$se, se_r = sqrt(diag(rr$V))[sm$rterm]),
    tibble(model = mn, item = paste0("contrast_", names(ctS)), stata = ctS, r = ctR, se_stata = NA, se_r = NA),
    tibble(model = mn, item = "N", stata = sm$N[1], r = rr$fit$n, se_stata = NA, se_r = NA),
    tibble(model = mn, item = "loglik", stata = sm$ll[1], r = rr$fit$ll, se_stata = NA, se_r = NA))
})) %>% mutate(abs_diff = abs(stata - r))
write_csv(recon %>% mutate(across(where(is.double), ~ signif(.x, 9))), file.path(OUT, "check_stata_reconciliation.csv"))
mx <- recon %>% filter(grepl("^cohort|^contrast_", item)) %>% group_by(model) %>% summarise(max_diff = max(abs_diff))
print(mx)
if (mx$max_diff[mx$model == "primary"] > 0.001) stop("R vs Stata primary differs by > 0.001: reconcile per card §4B")

# ---- (b) Sensitivities ----------------------------------------------------------------------------
add_run("S1", "Anchor: cohort + Attestation, c = 160.02 with 63-in heights kept", "diagnostic", anc)
add_run("S2a", "Drop force FE", "same target", run_tn(height ~ cohort + g21 + g22, s, expected_rank = 4))
add_run("S2b", "Drop growth dummies", "same target", run_tn(height ~ cohort + force, s, expected_rank = 4))
add_run("S2c", "Add Attestation (relaxes R2)", "same target", run_tn(height ~ cohort + force + g21 + g22 + attest, s, expected_rank = 4))
add_run("S2d", "Truncation at 160.02 with 63-in heights kept", "diagnostic",
        run_tn(f_prim, s, c = H63, keep = function(d) d$height >= H63 - EPS, expected_rank = 4))
add_run("S3", "c = 159.71 (quarter-inch rounding)", "same target", run_tn(f_prim, s, c = 159.71, expected_rank = 4))
add_run("S4", "Strict c = 160.02 (63-in heights dropped)", "same target", run_tn(f_prim, s, c = H63, expected_rank = 4))
add_run("S5", "Higher cut c = 164.465", "changed target", run_tn(f_prim, s, c = 164.465, expected_rank = 4))
for (w in c(a = 1.27, b = 0.635)) {
  dd <- s[s$height >= C0 + EPS, ]
  empty <- sum(dd$height + w / 2 <= C0)
  if (empty > 0) stop("S6: records with empty support on the §4B sample (implementation error)")
  r <- run_tn(f_prim, s, L = function(d) pmax(C0, d$height - w / 2), U = function(d) d$height + w / 2, expected_rank = 4)
  add_run(if (w > 1) "S6a" else "S6b", sprintf("Interval-rounded likelihood, w = %.3f cm", w), "same target", r,
          sprintf("empty intersections: %d", empty))
}
add_run("S7", "Growth dummies ages 21-24", "same target", run_tn(height ~ cohort + force + g21 + g22 + g23 + g24, s, expected_rank = 4))
add_run("S8", "Ages 23-39 only", "changed target", run_tn(f_prim, filter(s, age >= 23, age <= 39), expected_rank = 4))
add_run("S9", "age + age^2 instead of growth dummies", "same target", run_tn(height ~ cohort + force + age + I(age^2), s, expected_rank = 4))
add_run("S10a", "Shrinkage s = 0.05 cm/yr after 35, observation-specific truncation", "same target", s10[[1]])
add_run("S10b", "Shrinkage s = 0.10 cm/yr after 35, observation-specific truncation", "same target", s10[[2]])
r11 <- run_tn(f_prim, s, Zf = ~ force + cohort, expected_rank = 4)
add_run("S11", "Heteroskedastic truncated normal (log sigma by force and cohort)", "same target", r11)
extra$s11_sigma <- tibble(term = names(r11$fit$coef), est = r11$fit$coef, se = sqrt(diag(r11$V))) %>% filter(grepl("^lnsig", term))

d4 <- s[s$height >= C0 + EPS, ]
ols <- lm(f_prim, data = d4)
add_T("S12", "OLS on the §4B sample, HC1 (no truncation correction)", "diagnostic", famT(coef(ols), vcovHC(ols, "HC1"), 4), nobs(ols))
add_T("S14", "Model-based (-H^-1) SE for the primary", "same target", famT(prim$fit$coef, V_model(prim$fit), 4), prim$fit$n)

# S15a / S15c: CR1
d4 <- prim$d %>% mutate(fy = paste(force, year))
V15a <- V_clus(prim$fit, d4$fy)
add_T("S15a", "CR1 by force x enlistment year", "same target", famT(prim$fit$coef, V15a, 4), prim$fit$n,
      sprintf("G = %d", attr(V15a, "G")))
V15c <- V_clus(prim$fit, d4$pair_cl)
add_T("S15c", "CR1 with candidate repeat pairs merged", "same target", famT(prim$fit$coef, V15c, 4), prim$fit$n,
      sprintf("G = %d; merged pairs %d", attr(V15c, "G"), n_distinct(d4$pair_cl[d4$pair_k > 1])))

# ---- Bootstraps (S13 median regression; S15b pairs cluster bootstrap); L'Ecuyer streams per replicate ----
B <- as.integer(Sys.getenv("P09_B", "999"))   # 999 per card; env override only for debugging
RNGkind("L'Ecuyer-CMRG"); set.seed(SEED)
streams <- vector("list", B); st0 <- .Random.seed
for (b in 1:B) { st0 <- nextRNGStream(st0); streams[[b]] <- st0 }
RNGkind("Mersenne-Twister")
cl <- makeCluster(NW); on.exit(stopCluster(cl), add = TRUE)
clusterExport(cl, c("d4", "streams", "f_prim"))
clusterEvalQ(cl, { source("./P09_FIM/modern/00_common.R")
  suppressPackageStartupMessages(library(quantreg)); NULL })

rq0 <- rq(f_prim, tau = 0.5, data = d4, method = "br")
rq_b <- parLapply(cl, 1:B, function(b) {
  assign(".Random.seed", streams[[b]], envir = .GlobalEnv)
  i <- sample.int(nrow(d4), replace = TRUE)
  cf <- tryCatch(coef(quantreg::rq(f_prim, tau = 0.5, data = d4[i, ], method = "br")), error = function(e) NULL)
  cf
})
rqm <- do.call(rbind, lapply(rq_b, function(z) if (is.null(z) || length(z) != length(coef(rq0))) rep(NA, length(coef(rq0))) else z))
colnames(rqm) <- names(coef(rq0))
ok13 <- complete.cases(rqm)
ft13 <- famT(coef(rq0), cov(rqm[ok13, ]), 4)
Lc <- function(M) { out <- sapply(T_DEF, function(dd) drop(M[, names(dd), drop = FALSE] %*% dd)); out }
pc13 <- apply(Lc(rqm[ok13, ]), 2, quantile, c(0.025, 0.975))
add_T("S13", "Median regression on the §4B sample, pairs bootstrap B = 999", "changed target", ft13, nrow(d4),
      sprintf("defined draws %d; percentile 95%%: %s", sum(ok13),
              paste(sprintf("%s [%.3f, %.3f]", colnames(pc13), pc13[1, ], pc13[2, ]), collapse = "; ")))

groups <- unique(d4$fy)
th0 <- prim$fit$coef
clusterExport(cl, c("groups", "th0"))
bt <- parLapply(cl, 1:B, function(b) {
  assign(".Random.seed", streams[[b]], envir = .GlobalEnv)
  g <- sample(groups, length(groups), replace = TRUE)
  idx <- unlist(lapply(g, function(x) which(d4$fy == x)))
  db <- d4[idx, ]
  out <- tryCatch({
    ds <- design(f_prim, db)
    st <- th0[c(colnames(ds$X), "lnsig")]
    f <- fit_tn(ds$X, db$height, C0, start = st)
    if (!f$conv) NULL else f$coef
  }, error = function(e) NULL)
  out
})
cn <- names(th0)
btm <- do.call(rbind, lapply(bt, function(z) { v <- setNames(rep(NA, length(cn)), cn); if (!is.null(z)) v[names(z)] <- z; v }))
need <- c("cohort1865_1874", "cohort1875_1884", "cohort1895_1904", "cohort1915_1920")
ok15 <- complete.cases(btm[, need])
ft15 <- famT(th0[need] %>% c(), cov(btm[ok15, need]), 4)
pc15 <- apply(Lc(btm[ok15, need]), 2, quantile, c(0.025, 0.975))
add_T("S15b", "Pairs cluster bootstrap over force x enlistment-year groups, B = 999", "same target", ft15, prim$fit$n,
      sprintf("G = %d; defined draws %d; percentile 95%%: %s", length(groups), sum(ok15),
              paste(sprintf("%s [%.3f, %.3f]", colnames(pc15), pc15[1, ], pc15[2, ]), collapse = "; ")))
stopCluster(cl); on.exit()

# ---- Data construction ----------------------------------------------------------------------------
s16 <- load_sample() %>% mutate(birthyear = if_else(force != "WWII", birthyear - 1, birthyear)) %>%
  filter(between(birthyear, 1865, 1920)) %>%
  mutate(cohort = cut(birthyear, c(1864, 1874, 1884, 1894, 1904, 1914, 1920), labels = COH)) %>% prep()
add_run("S16", "Birth year - 1 for colonial and WWI records", "same target", run_tn(f_prim, s16, expected_rank = 4))
add_run("S17", "Drop later copies of unflagged name + birth-year repeats (S2-8)", "same target",
        run_tn(f_prim, filter(s, !unfl_repeat), expected_rank = 4), sprintf("dropped from S3 sample: %d", sum(s$unfl_repeat)))
coh5 <- c("1865_1869", "1870_1874", "1875_1879", "1880_1884", "1885_1889", "1890_1894", "1895_1899", "1900_1904",
          "1905_1909", "1910_1914", "1915_1920")
s18 <- s %>% mutate(cohort = cut(birthyear, c(1864, seq(1869, 1914, 5), 1920), labels = coh5)) %>% prep(coh_ref = "1890_1894")
r18 <- run_tn(f_prim, s18)
extra$s18 <- tibble(term = names(r18$fit$coef), est = r18$fit$coef, se = sqrt(diag(r18$V))) %>% filter(grepl("^cohort", term)) %>%
  left_join(r18$d %>% count(term = paste0("cohort", cohort)), by = "term")
rel <- readRDS(file.path(SCR, "sample_relaxed_s19.rds")) %>% prep()
add_run("S19", "Relaxed complete-case rule (records missing only occupation/town added back)", "changed target",
        run_tn(f_prim, rel, expected_rank = 4), sprintf("added: %d", sum(rel$added_s19)))
extra$s19_added <- rel %>% filter(added_s19) %>% count(force, cohort)

# S20: colonial forces + WWI only, published covariates; unweighted, D7 weights, and without occupation
cov <- s %>% filter(force != "WWII") %>% mutate(prov = if_else(region %in% c("WCape", "ECape", "NCape"), "Cape", region))
census <- list(prov = c(Cape = 42.91, Natal = 8.43, Tvl = 35.60, OFS = 13.06),
               occ = c(Middle_class = 4.45, Agriculture = 36.48, Skilled = 46.92, Semi_skilled = 6.29, Unskilled = 5.85),
               town = c(gt10000 = 56.24, lt10000 = 100 - 56.24))
ratio <- function(x, target) { sh <- c(prop.table(table(x))) * 100; as.numeric(target[x] / sh[x]) }
cov <- cov %>% mutate(w = ratio(prov, census$prov) * ratio(occ, census$occ) * ratio(town, census$town), w = w / mean(w),
                      region = relevel(factor(region), ref = "WCape"), occ = relevel(factor(occ), ref = "Agriculture"),
                      town = relevel(factor(town), ref = "lt10000"))
f20 <- height ~ cohort + force + g21 + g22 + region + occ + town + attest
add_run("S20a", "Colonial + WWI, published covariates, unweighted", "changed target", run_tn(f20, cov, expected_rank = 3))
add_run("S20b", "Colonial + WWI, published covariates, D7 post-stratification weights", "changed target",
        run_tn(f20, cov, w = "w", expected_rank = 3))
add_run("S20c", "Colonial + WWI, published covariates without occupation, unweighted", "changed target",
        run_tn(update(f20, . ~ . - occ), cov, expected_rank = 3))
add_run("S20d", "Colonial + WWI, published covariates without occupation, D7 weights", "changed target",
        run_tn(update(f20, . ~ . - occ), cov, w = "w", expected_rank = 3))
for (fo in c("WWI", "SAC", "CMP", "AOF", "WWII")) {
  er <- if (fo == "WWII") 3 else 4
  add_run(paste0("S21_", fo), paste("Leave out", fo), "changed target", run_tn(f_prim, prep(filter(s, force != fo)), expected_rank = er))
}
add_run("S22", "Drop horse-riding forces SAC and CMP", "changed target", run_tn(f_prim, prep(filter(s, !force %in% c("SAC", "CMP"))), expected_rank = 4))

sens <- bind_rows(res)
lev <- sens %>% filter(grepl("^S21_", sens)) %>% left_join(PO$ft %>% select(contrast, est0 = est), by = "contrast") %>%
  group_by(contrast) %>% summarise(max_abs_change = max(abs(est - est0), na.rm = TRUE),
                                   force_left_out = sub("S21_", "", sens[which.max(abs(est - est0))]))
extra$s21_leverage <- lev

# ---- Descriptive (T2): S23-S25 ------------------------------------------------------------------
famD_on <- function(dd) {
  m <- dd %>% group_by(cohort = as.character(cohort)) %>% summarise(m = mean(height), s2 = var(height), n = n()) %>% arrange(match(cohort, COH))
  v <- m$s2 / m$n; j <- c(1, 2, 3, 5, 6); e <- m$m[j] - m$m[4]; se <- sqrt(v[j] + v[4])
  V <- matrix(v[4], 5, 5); diag(V) <- v[j] + v[4]
  set.seed(SEED); q <- qmvnorm(0.95, tail = "both.tails", corr = cov2cor(V), algorithm = GenzBretz(maxpts = 250000, abseps = 1e-6))$quantile
  list(m = m, D = tibble(contrast = paste0("e", j), est = e, se = se, lo = e - q * se, hi = e + q * se, c_D = q))
}
s23 <- famD_on(filter(s, age >= 23))
t2res <- bind_rows(
  s23$m %>% transmute(sens = "S23", label = "T2 means, ages 23-49", target = "changed target", contrast = paste("mean", cohort),
                      est = m, se = sqrt(s2 / n), lo = NA, hi = NA, c_crit = NA, n = n, note = ""),
  s23$D %>% transmute(sens = "S23", label = "Family D contrasts on ages 23-49 means", target = "changed target",
                      contrast, est, se, lo, hi, c_crit = c_D, n = sum(s23$m$n),
                      note = case_when(lo > 0 ~ "CI > 0", hi < 0 ~ "CI < 0", TRUE ~ "CI includes 0")),
  tibble(sens = "S24", label = "Is the 1865-74 mean the maximum of the six cohort means?", target = "diagnostic",
         contrast = "m1 is max", est = as.numeric(which.max(PO$m$m) == 1), se = NA, lo = NA, hi = NA, c_crit = NA, n = sum(PO$m$n),
         note = sprintf("max cohort: %s (%.3f)", PO$m$cohort[which.max(PO$m$m)], max(PO$m$m))))
band <- function(a) cut(a, c(20, 21, 22, 24, 29, 34, 39, 44, 49), labels = c("21", "22", "23-24", "25-29", "30-34", "35-39", "40-44", "45-49"))
s25 <- s %>% filter(force %in% c("WWI", "WWII")) %>% group_by(force, age_band = band(age)) %>%
  summarise(n = n(), mean_height = mean(height), sd = sd(height)) %>%
  mutate(mean_height = if_else(n < 5, NA_real_, mean_height), sd = if_else(n < 5, NA_real_, sd))   # no individual values
write_csv(s25 %>% mutate(across(where(is.double), ~ round(.x, 3))), file.path(OUT, "s25_height_by_age.csv"), na = "")

sens_all <- bind_rows(sens, t2res)
write_csv(sens_all %>% mutate(across(where(is.double), ~ signif(.x, 6))), file.path(OUT, "sensitivities.csv"), na = "")
write_csv(bind_rows(fnd) %>% select(sens, label, target, row, finding, rule), file.path(OUT, "sensitivity_findings.csv"))
write_csv(extra$s18 %>% mutate(across(where(is.double), ~ signif(.x, 6))), file.path(OUT, "s18_five_year_profile.csv"))
write_csv(extra$s11_sigma %>% mutate(across(where(is.double), ~ signif(.x, 6))), file.path(OUT, "s11_lnsigma.csv"))
write_csv(extra$s19_added, file.path(OUT, "s19_added_by_force_cohort.csv"))
write_csv(extra$s21_leverage %>% mutate(across(where(is.double), ~ signif(.x, 6))), file.path(OUT, "s21_force_leverage.csv"))
write_csv(tibble(item = c("S13 defined draws", "S15b defined draws", "runtime minutes"),
                 value = c(sum(ok13), sum(ok15), as.numeric(difftime(Sys.time(), t_start, units = "mins")))),
          file.path(OUT, "sensitivity_run_info.csv"))
cat("Runtime (min):", round(as.numeric(difftime(Sys.time(), t_start, units = "mins")), 1), "\n")
