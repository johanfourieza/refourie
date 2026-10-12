# P09_FIM — S3 independent recreation. 02_analysis.R
# Tables 1, 2, 3 (cols 3-6), 4 (col 1) and 5, plus text numbers, from the sample built in
# 01_clean.R. Writes aggregate tables to output/ and results_r.csv. See decisions.md.

suppressPackageStartupMessages({
  library(tidyverse)
  library(numDeriv)
  library(kableExtra)
})
source(file.path(here::here(), "tools", "paths.R"))
set.seed(20221)

root    <- file.path(here::here(), "P09_FIM", "repro_r")
out_dir <- file.path(root, "output")
s <- readRDS(dscratch("P09_FIM", "repro_r", "analysis_sample.rds"))
claims <- read_csv(file.path(here::here(), "P09_FIM", "claims", "claims.csv"),
                   show_col_types = FALSE, col_types = cols(.default = "c"))

cohorts <- levels(s$cohort)
TRUNC   <- 160.02
res     <- list()                       # rows for results_r.csv
add <- function(id, value, se = NA, n = NA, ov = "") {
  res[[length(res) + 1]] <<- tibble(claim_id = id, source = "r", value = value, se = se,
                                    n = n, status_override = ov)
}

# ---- Table 1: sample shares by cohort ----------------------------------------
N_c <- s %>% count(cohort, .drop = FALSE)
t1_force <- s %>% count(cohort, force, .drop = FALSE) %>%
  group_by(cohort) %>% mutate(pct = 100 * n / sum(n)) %>% ungroup()
for (k in seq_along(cohorts)) {
  nk <- N_c$n[N_c$cohort == cohorts[k]]
  add(sprintf("T1_obs_c%d", k), nk, n = nk)
  for (f in c("AOF", "CMP", "SAC", "WWI", "WWII")) {
    v <- t1_force %>% filter(cohort == cohorts[k], force == f) %>% pull(pct)
    add(sprintf("T1_Sourceshare_%s_c%d", f, k), round(v, 4), n = nk)
  }
}

# Covariate shares: only the colonial forces and WWI carry covariates (decisions.md D2).
# Cohorts 1-2 contain no WWII recruits; cohort 3 is computed without its WWII recruits;
# cohorts 4-6 are mostly WWII and are not assessable.
cov <- s %>% filter(force != "WWII")
share_rows <- function(var, levels_map, prefix) {
  tab <- cov %>% count(cohort, val = .data[[var]], .drop = FALSE) %>%
    group_by(cohort) %>% mutate(pct = 100 * n / sum(n), N = sum(n)) %>% ungroup()
  for (k in seq_along(cohorts)) for (lv in names(levels_map)) {
    id <- sprintf("%s_%s_c%d", prefix, levels_map[[lv]], k)
    if (k >= 4) { add(id, NA, ov = "unavailable"); next }
    r <- tab %>% filter(cohort == cohorts[k], val == lv)
    add(id, if (nrow(r)) round(r$pct, 4) else 0, n = tab$N[tab$cohort == cohorts[k]][1])
  }
}
share_rows("region", c(WCape = "WCape", ECape = "ECape", NCape = "NCape", Natal = "Natal",
                       OFS = "OFS", Tvl = "Tvl"), "T1_Region")
share_rows("occ", c(Middle_class = "Middle_class", Agriculture = "Agriculture",
                    Skilled = "Skilled", Semi_skilled = "Semi_skilled",
                    Unskilled = "Unskilled"), "T1_Occupationclass")
share_rows("town", c(gt10000 = "gt10000"), "T1_Townsize")
for (k in 1:6) for (lv in c("Rural", "lt1000", "1000_1999", "2000_9999"))
  add(sprintf("T1_Townsize_%s_c%d", lv, k), NA, ov = "unavailable")
for (k in 1:6) for (lv in c("Anglican", "DutchReformed", "Wesleyan", "Catholic", "Jewish", "Other"))
  add(sprintf("T1_Religion_%s_c%d", lv, k), NA, ov = "unavailable")

t1_out <- bind_rows(
  t1_force %>% transmute(cohort, row = paste0("Source: ", force), pct),
  cov %>% count(cohort, row = paste0("Region: ", region)) %>% group_by(cohort) %>%
    mutate(pct = 100 * n / sum(n)) %>% select(-n),
  cov %>% count(cohort, row = paste0("Occupation: ", occ)) %>% group_by(cohort) %>%
    mutate(pct = 100 * n / sum(n)) %>% select(-n),
  cov %>% count(cohort, row = paste0("Town: ", town)) %>% group_by(cohort) %>%
    mutate(pct = 100 * n / sum(n)) %>% select(-n),
  N_c %>% transmute(cohort, row = "Observations", pct = n)
) %>% ungroup() %>% pivot_wider(names_from = cohort, values_from = pct)
write_csv(t1_out, file.path(out_dir, "table1_r.csv"))

# ---- Table 2: mean (sd) height by cohort (unweighted, all heights) -----------
msd <- function(d, k) {
  h <- d$height[d$cohort == cohorts[k]]
  list(m = if (length(h)) mean(h) else NA, sd = if (length(h) > 1) sd(h) else NA, n = length(h))
}
t2_rows <- list()
t2_add <- function(group, label, d, idbase, kmax = 6) {
  for (k in 1:6) {
    st <- msd(d, k)
    t2_rows[[length(t2_rows) + 1]] <<- tibble(group, label, cohort = cohorts[k],
                                              mean = st$m, sd = st$sd, n = st$n)
    id <- sprintf("%s_c%d", idbase, k)
    if (!id %in% claims$claim_id) next
    if (k > kmax) { add(id, NA, ov = "unavailable"); add(paste0(id, "_sd"), NA, ov = "unavailable"); next }
    add(id, round(st$m, 4), n = st$n); add(paste0(id, "_sd"), round(st$sd, 4), n = st$n)
  }
}
t2_add("Total", "Total", s, "T2_Total_Total")
for (f in c("AOF", "CMP", "SAC", "WWI", "WWII")) t2_add("Force", f, filter(s, force == f), paste0("T2_Forceheight_", f))
for (r in c("WCape", "ECape", "NCape", "Natal", "OFS", "Tvl")) t2_add("Region", r, filter(cov, region == r), paste0("T2_Regionheight_", r), kmax = 3)
for (o in c("Middle_class", "Agriculture", "Skilled", "Semi_skilled", "Unskilled")) t2_add("Occupation", o, filter(cov, occ == o), paste0("T2_Occupationalclass_", o), kmax = 3)
t2_add("Town", "gt10000", filter(cov, town == "gt10000"), "T2_Townsize_gt10000", kmax = 3)
# Remaining Table 2 rows (four small town sizes, religion) cannot be built from the allow-listed files
for (id in claims$claim_id[str_detect(claims$claim_id, "^T2_(Townsize_(Rural|lt1000|1000_1999|2000_9999)|Religion)")])
  add(id, NA, ov = "unavailable")
t2_out <- bind_rows(t2_rows)
write_csv(t2_out %>% mutate(across(c(mean, sd), ~ round(.x, 2))), file.path(out_dir, "table2_r.csv"))

# ---- Weights from Table A.1 (decisions.md D7) --------------------------------
# Census shares (WWI census column: 1911, 1918, 1921) over own-sample shares, multiplied
# across province, occupation and town size (>= 10,000 vs the rest); mean-normalised.
census <- list(
  prov = c(Cape = 42.91, Natal = 8.43, Tvl = 35.60, OFS = 13.06),
  occ  = c(Middle_class = 4.45, Agriculture = 36.48, Skilled = 46.92, Semi_skilled = 6.29, Unskilled = 5.85),
  town = c(gt10000 = 56.24, lt10000 = 100 - 56.24)
)
cov <- cov %>% mutate(prov = if_else(region %in% c("WCape", "ECape", "NCape"), "Cape", region))
ratio <- function(x, target) { sh <- c(prop.table(table(x))) * 100; as.numeric(target[x] / sh[x]) }
cov <- cov %>% mutate(w = ratio(prov, census$prov) * ratio(occ, census$occ) * ratio(town, census$town),
                      w = w / mean(w))
write_csv(cov %>% group_by(prov, occ, town) %>% summarise(n = n(), w = first(w), .groups = "drop"),
          file.path(out_dir, "weights_cells.csv"))

# ---- Weighted truncated-normal regression (left truncation at 160.02) --------
trunc_fit <- function(formula, data, w = NULL, c = TRUNC) {
  data <- data %>% filter(height >= c)
  mf <- model.frame(formula, data)
  X  <- model.matrix(formula, mf)
  X  <- X[, colSums(abs(X)) > 0, drop = FALSE]
  y  <- model.response(mf)
  w  <- if (is.null(w)) rep(1, length(y)) else data[[w]][as.integer(rownames(mf))]
  if (is.null(w) || length(w) != length(y)) w <- rep(1, length(y))
  k <- ncol(X)
  ll_i <- function(th) {
    b <- th[1:k]; sg <- th[k + 1]; xb <- drop(X %*% b)
    dnorm((y - xb) / sg, log = TRUE) - log(sg) - pnorm((c - xb) / sg, lower.tail = FALSE, log.p = TRUE)
  }
  sc_i <- function(th) {
    b <- th[1:k]; sg <- th[k + 1]; xb <- drop(X %*% b)
    z <- (y - xb) / sg; a <- (c - xb) / sg
    lam <- exp(dnorm(a, log = TRUE) - pnorm(a, lower.tail = FALSE, log.p = TRUE))
    cbind(X * (z - lam) / sg, (z^2 - 1 - a * lam) / sg)
  }
  negll <- function(p) { th <- c(p[1:k], exp(p[k + 1])); -sum(w * ll_i(th)) }
  neggr <- function(p) { th <- c(p[1:k], exp(p[k + 1])); g <- colSums(w * sc_i(th)); -c(g[1:k], g[k + 1] * th[k + 1]) }
  ols <- lm.wfit(X, y, w)
  p0 <- c(coef(ols), log(sqrt(sum(w * ols$residuals^2) / sum(w))))
  p0[is.na(p0)] <- 0
  op <- optim(p0, negll, neggr, method = "BFGS", control = list(maxit = 5000, reltol = 1e-14))
  th <- c(op$par[1:k], exp(op$par[k + 1]))
  for (it in 1:20) {                                          # Newton polish of the BFGS optimum
    g <- colSums(w * sc_i(th)); H <- jacobian(function(t) colSums(w * sc_i(t)), th)
    step <- tryCatch(solve(H, g), error = function(e) rep(0, length(th)))
    th <- th - step
    if (max(abs(step)) < 1e-10) break
  }
  H  <- jacobian(function(t) colSums(w * sc_i(t)), th)        # Hessian of weighted loglik
  Hi <- solve(-H)
  S  <- sc_i(th) * w
  V_conv <- Hi                                                # model-based (fweight/iweight analogue)
  V_rob  <- Hi %*% crossprod(S) %*% Hi * length(y) / (length(y) - 1)   # sandwich (pweight analogue)
  nm <- c(colnames(X), "sigma")
  tibble(term = nm, est = th, se = sqrt(diag(V_conv)), se_rob = sqrt(diag(V_rob)),
         t = est / se, t_rob = est / se_rob, n = length(y), conv = op$convergence,
         ll = sum(w * ll_i(th)))
}

# Regressor coding follows Table 3: reference cohort per column, Western Cape, agriculture,
# rural (here: towns below 10,000), Attestation = enlistment year - 1900 (decisions.md D8).
prep <- function(d, ref) {
  d %>% mutate(
    cohort = relevel(droplevels(factor(cohort)), ref = ref),
    region = relevel(factor(region), ref = "WCape"),
    occ    = relevel(factor(occ), ref = "Agriculture"),
    town   = relevel(factor(town), ref = "lt10000"))
}
f_full <- height ~ cohort + region + occ + town + attest
f_t4   <- height ~ cohort + region + occ + town

specs <- list(
  c3 = list(d = filter(cov, force == "SAC"), ref = "1875_1884", f = f_full),
  c4 = list(d = filter(cov, force == "CMP"), ref = "1875_1884", f = f_full),
  c5 = list(d = filter(cov, force == "AOF"), ref = "1875_1884", f = f_full),
  c6 = list(d = filter(cov, force == "WWI"), ref = "1895_1904", f = f_full),
  t4c1 = list(d = filter(cov, force == "WWI", year == 1915), ref = "1885_1894", f = f_t4),
  # supplementary (not comparable to the published columns 1-2, which include WWII)
  s1_noWWII = list(d = cov, ref = "1885_1894", f = f_full),
  s2_noWWII = list(d = cov, ref = "1885_1894", f = update(f_full, . ~ . + force))
)

fits <- imap_dfr(specs, function(sp, nm) {
  d <- prep(sp$d, sp$ref)
  bind_rows(trunc_fit(sp$f, d, "w") %>% mutate(weighted = TRUE),
            trunc_fit(sp$f, d, NULL) %>% mutate(weighted = FALSE)) %>% mutate(model = nm)
})
write_csv(fits %>% mutate(across(where(is.double), ~ signif(.x, 6))), file.path(out_dir, "trunc_models_r.csv"))
stopifnot(all(fits$conv == 0))

# Cross-check the hand-written likelihood against truncreg (unweighted, WWI column)
if (requireNamespace("truncreg", quietly = TRUE)) {
  d6 <- prep(specs$c6$d, "1895_1904") %>% filter(height >= TRUNC)
  tr <- truncreg::truncreg(f_full, data = d6, point = TRUNC, direction = "left")
  own <- fits %>% filter(model == "c6", !weighted)
  chk <- max(abs(coef(tr)[1:(length(coef(tr)) - 1)] - own$est[own$term != "sigma"]))
  writeLines(sprintf("max |truncreg - own| coefficient difference (WWI, unweighted): %.2e", chk),
             file.path(out_dir, "truncreg_check.txt"))
}

# Map model terms to claim ids
term_id <- function(term) {
  case_when(
    str_detect(term, "^cohort") ~ paste0("Birthcohort_", str_remove(term, "^cohort")),
    str_detect(term, "^region") ~ paste0("Region_", str_remove(term, "^region")),
    str_detect(term, "^occ")    ~ paste0("Occupation_", str_remove(term, "^occ")),
    term == "towngt10000"       ~ "Townsize_gt10000",
    term == "attest"            ~ "x_Attestation",
    term == "(Intercept)"       ~ "x_Constant",
    term == "sigma"             ~ "x_sigma",
    TRUE ~ NA_character_)
}
pub <- fits %>% filter(weighted, model %in% c("c3", "c4", "c5", "c6", "t4c1")) %>%
  mutate(tab = if_else(model == "t4c1", "T4", "T3"), col = if_else(model == "t4c1", "c1", model),
         id = paste0(tab, "_", term_id(term), "_", col))
for (i in seq_len(nrow(pub))) {
  if (!pub$id[i] %in% claims$claim_id) next
  add(pub$id[i], pub$est[i], pub$se[i], pub$n[i])
  add(paste0(pub$id[i], "_t"), pub$t[i], NA, pub$n[i])
}
for (m in c("c3", "c4", "c5", "c6")) add(paste0("T3_obs_", m), fits$n[fits$model == m & fits$weighted][1], n = fits$n[fits$model == m & fits$weighted][1])
add("T4_obs_c1", fits$n[fits$model == "t4c1" & fits$weighted][1], n = fits$n[fits$model == "t4c1" & fits$weighted][1])

# LaTeX table of the reproducible Table 3 / 4 columns (conventional t in parentheses)
tex <- fits %>% filter(weighted, model %in% c("c3", "c4", "c5", "c6", "t4c1")) %>%
  mutate(cell = sprintf("%.3f (%.2f)", est, t)) %>%
  select(term, model, cell) %>% pivot_wider(names_from = model, values_from = cell, values_fill = "")
kbl(tex, format = "latex", booktabs = TRUE,
    col.names = c("", "SAC", "CMP", "AOF", "WW1", "WWI 1915"),
    caption = "Weighted truncated regressions (truncation 160.02 cm); t statistics (model-based) in parentheses") %>%
  writeLines(file.path(out_dir, "table3_4_r.tex"))

# ---- Table 5: decomposition (Eloundou-Enyegue et al. 2021) -------------------
decomp <- function(d, var, t) {
  g <- d %>% filter(cohort %in% cohorts[c(t - 1, t)]) %>%
    group_by(cohort, cat = .data[[var]]) %>% summarise(h = mean(height), n = n(), .groups = "drop") %>%
    group_by(cohort) %>% mutate(p = n / sum(n)) %>% ungroup() %>%
    select(cohort, cat, h, p) %>%
    pivot_wider(names_from = cohort, values_from = c(h, p))
  names(g) <- c("cat", "h0", "h1", "p0", "p1")
  g <- g %>% mutate(across(c(p0, p1), ~ replace_na(.x, 0)))
  H0 <- mean(d$height[d$cohort == cohorts[t - 1]]); H1 <- mean(d$height[d$cohort == cohorts[t]])
  gg <- g %>% filter(!is.na(h0), !is.na(h1))
  comp <- sum((gg$h1 + gg$h0) / 2 * (gg$p1 - gg$p0)) / (H1 - H0)
  act  <- sum((gg$p1 + gg$p0) / 2 * (gg$h1 - gg$h0)) / (H1 - H0)
  c(comp = comp, act = act, dH = H1 - H0)
}
t5 <- list()
for (t in 2:6) {
  r <- t - 1
  Ht <- s %>% filter(cohort %in% cohorts[c(t - 1, t)]) %>% group_by(cohort) %>% summarise(h = mean(height))
  add(sprintf("T5_Heightchange_r%d", r), diff(Ht$h))
  for (v in c(Region = "region", Class = "occ", Townsize = "town")) {
    nm <- names(c(Region = "region", Class = "occ", Townsize = "town"))[c("region", "occ", "town") == v]
    if (t <= 3) {
      dd <- decomp(cov, v, t)
      add(sprintf("T5_%sComposition_r%d", nm, r), dd[["comp"]]); add(sprintf("T5_%sActual_r%d", nm, r), dd[["act"]])
      t5[[length(t5) + 1]] <- tibble(transition = r, var = nm, comp = dd[["comp"]], act = dd[["act"]], dH_cov = dd[["dH"]])
    } else {
      add(sprintf("T5_%sComposition_r%d", nm, r), NA, ov = "unavailable"); add(sprintf("T5_%sActual_r%d", nm, r), NA, ov = "unavailable")
    }
  }
}
write_csv(bind_rows(t5), file.path(out_dir, "table5_r.csv"))

# ---- Text numbers -------------------------------------------------------------
raw <- read_csv(file.path(out_dir, "raw_counts.csv"), col_names = c("k", "v"), show_col_types = FALSE)
rc <- setNames(raw$v, raw$k)
add("X_p5_final_n", nrow(s), n = nrow(s))
m <- t2_out %>% filter(group == "Total")
add("X_p8_mean_hi", m$mean[1], n = m$n[1]); add("X_p8_mean_lo", min(m$mean), n = m$n[which.min(m$mean)])
add("X_p8_mean_end", m$mean[6], n = m$n[6])
add("X_p4_forms", rc[["raw_rows_Data"]] + rc[["raw_rows_WhitesWW2"]])
add("X_p5_sac_total", rc[["raw_SAC_rows"]]); add("X_p5_wwi_n", rc[["raw_WWI_rows"]])
add("X_p5_wwii_n", rc[["raw_rows_WhitesWW2"]])
add("X_p5_aof_town", 100 * mean(cov$town[cov$force == "AOF"] == "gt10000"), n = sum(cov$force == "AOF"))
add("X_p9_trunc", TRUNC, ov = "not-attempted")   # an input, not a result
for (id in c("X_p5_wwii_frac", "X_p8_wwi_enlist", "X_p8_wwii_enlist_lo", "X_p8_wwii_enlist_hi",
             "X_p8_dr_sample", "X_p8_dr_pop", "X_p10_urban", "X_p12_urban_lo", "X_p12_urban_hi",
             "X_p14_third", "X_p13_fn9_sa", "X_p13_fn9_oth"))
  add(id, NA, ov = "unavailable")

# ---- Everything not produced above is unavailable ------------------------------
out <- bind_rows(res) %>% distinct(claim_id, .keep_all = TRUE)
missing <- setdiff(claims$claim_id, out$claim_id)
out <- bind_rows(out, tibble(claim_id = missing, source = "r", value = NA, se = NA, n = NA,
                             status_override = "unavailable"))
out <- out %>% filter(claim_id %in% claims$claim_id) %>%
  mutate(across(c(value, se), ~ signif(.x, 7))) %>%
  arrange(match(claim_id, claims$claim_id))
write_csv(out, file.path(root, "results_r.csv"), na = "")
cat("results_r.csv rows:", nrow(out), " with value:", sum(!is.na(out$value)), "\n")
