# P01_BF  Baten & Fourie (2015) — S3 independent recreation, step 2: tables and headline numbers
# Input : _scratch/p01_full.rds, _scratch/p01_sample.rds (from 01_clean.R)
# Output: output/*.csv, output/*.tex, results_r.csv
# Choices are documented in decisions.md. Conventional SEs are primary; HC1 and
# clustered-by-court-volume SEs are reported alongside in output/.

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
  library(sandwich)
  library(kableExtra)
})
set.seed(20151)
proj  <- here::here()
paper <- file.path(proj, "P01_BF")
source(file.path(proj, "tools", "paths.R"))
out   <- file.path(paper, "repro_r", "output")
dir.create(out, showWarnings = FALSE, recursive = TRUE)

full <- readRDS(dscratch("P01_BF", "repro_r", "p01_full.rds"))
s0   <- readRDS(dscratch("P01_BF", "repro_r", "p01_sample.rds"))
s    <- s0 |> filter(!is.na(bdec))                       # 1,802
claims <- read_csv(file.path(paper, "claims", "claims.csv"), show_col_types = FALSE)

res <- list()
add <- function(id, value, se = NA, n = NA, status = NA) {
  res[[length(res) + 1]] <<- tibble(claim_id = id, source = "r", value = value, se = se, n = n,
                                    status_override = status)
}

# helpers ---------------------------------------------------------------------------
ols_tab <- function(fit, cl) {
  b  <- coef(fit)
  vc <- list(conv = vcov(fit), hc1 = vcovHC(fit, type = "HC1"), cl = vcovCL(fit, cluster = cl, type = "HC1"))
  map_dfr(names(vc), function(k) {
    se <- sqrt(diag(vc[[k]]))[names(b)]
    tibble(term = names(b), vcov = k, coef125 = 125 * b, se_unscaled = se, se125 = 125 * se,
           p = 2 * pt(-abs(b / se), df = fit$df.residual))
  })
}
r2 <- function(fit) summary(fit)$r.squared

# =============================================================================
# Table 2: by birth decade
# =============================================================================
t2 <- s |>
  group_by(bdec) |>
  summarise(N = n(), age = mean(age), knows = mean(know01, na.rm = TRUE),
            knows_blank1 = mean(know01b), abcc = 125 * mean(exact), eu = mean(eu), .groups = "drop") |>
  mutate(bdec = as.character(bdec))
t2tot <- s |> summarise(bdec = "Total", N = n(), age = mean(age), knows = mean(know01, na.rm = TRUE),
                        knows_blank1 = mean(know01b), abcc = 125 * mean(exact), eu = mean(eu))
t2 <- bind_rows(t2, t2tot)
write_csv(t2, file.path(out, "table2.csv"))
for (i in seq_len(nrow(t2))) {
  if (t2$bdec[i] != "Total") {
    add(paste0("T2_r", i, "_n"), t2$N[i], n = t2$N[i])
    add(paste0("T2_r", i, "_age"), t2$age[i], n = t2$N[i])
    add(paste0("T2_r", i, "_knows"), t2$knows[i], n = t2$N[i])
    add(paste0("T2_r", i, "_abcc"), t2$abcc[i], n = t2$N[i])
    add(paste0("T2_r", i, "_eur"), t2$eu[i], n = t2$N[i])
  } else {
    add("T2_r16_n", t2$N[i], n = t2$N[i]); add("T2_r16_age", t2$age[i], n = t2$N[i])
    add("T2_r16_knows", t2$knows[i], n = t2$N[i]); add("T2_r16_eur", t2$eu[i], n = t2$N[i])
  }
}
stopifnot(nrow(t2) == 16)

# correlation not guessing vs European (p.640)
ct  <- cor.test(s$know01, s$eu)
ctd <- cor.test(t2$knows[t2$bdec != "Total"], t2$eu[t2$bdec != "Total"])
write_csv(tibble(level = c("individual", "birth decade"), r = c(ct$estimate, ctd$estimate),
                 p = c(ct$p.value, ctd$p.value), n = c(sum(!is.na(s$know01)), 15)),
          file.path(out, "corr_knows_european.csv"))
add("TXT_p640_a", unname(ct$estimate), n = sum(!is.na(s$know01)))

# =============================================================================
# Table 3: ABCC by Eu / non-Eu for theft and murder
# =============================================================================
t3 <- s |> filter(crimecat %in% c("theft", "murder")) |>
  mutate(ethn = if_else(eu == 1, "European", "Non-European")) |>
  group_by(crimecat, ethn) |> summarise(abcc = 125 * mean(exact), N = n(), .groups = "drop")
write_csv(t3, file.path(out, "table3.csv"))
g3 <- function(c, e) t3 |> filter(crimecat == c, ethn == e)
add("T3_r1_abcc", g3("theft", "Non-European")$abcc, n = g3("theft", "Non-European")$N)
add("T3_r2_abcc", g3("theft", "European")$abcc, n = g3("theft", "European")$N)
add("T3_r3_diff", g3("theft", "European")$abcc - g3("theft", "Non-European")$abcc,
    n = g3("theft", "European")$N + g3("theft", "Non-European")$N)
add("T3_r4_abcc", g3("murder", "Non-European")$abcc, n = g3("murder", "Non-European")$N)
add("T3_r5_abcc", g3("murder", "European")$abcc, n = g3("murder", "European")$N)
add("T3_r6_diff", g3("murder", "European")$abcc - g3("murder", "Non-European")$abcc,
    n = g3("murder", "European")$N + g3("murder", "Non-European")$N)
add("TXT_p640_b", g3("murder", "Non-European")$abcc - g3("theft", "Non-European")$abcc)
add("TXT_p640_c", g3("murder", "European")$abcc - g3("theft", "European")$abcc)
add("TXT_p640_d", min(g3("theft", "European")$abcc - g3("theft", "Non-European")$abcc,
                      g3("murder", "European")$abcc - g3("murder", "Non-European")$abcc))

# =============================================================================
# Table 4: OLS of exact x125 on crime categories
# =============================================================================
s4 <- s |> filter(!is.na(crimecat)) |> mutate(bdec_f = factor(bdec), group_f = group)
m4a <- lm(exact ~ crimecat + bdec_f + eu, data = s4)                 # primary: world region = Eu/non-Eu
m4b <- lm(exact ~ crimecat, data = s4)
m4c <- lm(exact ~ crimecat + bdec_f + group_f, data = s4)            # alternative: eight groups
t4  <- bind_rows(ols_tab(m4a, s4$source) |> mutate(model = "c1_euFE"),
                 ols_tab(m4b, s4$source) |> mutate(model = "c2_none"),
                 ols_tab(m4c, s4$source) |> mutate(model = "c1alt_groupFE")) |>
  filter(str_detect(term, "crimecat|Intercept"))
t4 <- t4 |> left_join(tibble(model = c("c1_euFE", "c2_none", "c1alt_groupFE"),
                             r2 = c(r2(m4a), r2(m4b), r2(m4c)), N = nobs(m4a)), by = "model")
write_csv(t4, file.path(out, "table4.csv"))
for (m in c("c1_euFE", "c2_none")) {
  k  <- if (m == "c1_euFE") "c1" else "c2"
  tt <- t4 |> filter(model == m, vcov == "conv")
  for (j in 1:4) {
    trm <- c("crimecatminor", "crimecatviolence", "crimecatmurder", "(Intercept)")[j]
    r <- tt |> filter(term == trm)
    add(paste0("T4_r", j, "_", k), r$coef125, r$se125, nobs(m4a))
    add(paste0("T4_r", j, "_", k, "_p"), r$p, n = nobs(m4a))
  }
  add(paste0("T4_n_", k), nobs(m4a), n = nobs(m4a))
  add(paste0("T4_rsq_", k), if (k == "c1") r2(m4a) else r2(m4b), n = nobs(m4a))
}
add("TXT_p641_a", (t4 |> filter(model == "c1_euFE", vcov == "conv", term == "crimecatmurder"))$coef125)

# =============================================================================
# Table 5: crime counts by Eu / Slave x cohort x category
# =============================================================================
t5 <- s |> filter(eths %in% c("eu", "bl"), !is.na(crimecat)) |>
  mutate(grp = if_else(eths == "eu", "European", "Slave")) |>
  count(grp, cohort, crimecat) |>
  pivot_wider(names_from = crimecat, values_from = n, values_fill = 0) |>
  mutate(ratio = theft / murder) |> arrange(grp, cohort)
t5s <- t5 |> group_by(grp) |>
  summarise(cohort = "Sum/avg.", minor = sum(minor), theft = sum(theft), violence = sum(violence),
            murder = sum(murder), ratio = mean(ratio), .groups = "drop")
t5 <- bind_rows(t5 |> mutate(cohort = as.character(cohort)), t5s) |> arrange(grp)
write_csv(t5, file.path(out, "table5.csv"))
rowid <- c(European_early = 1, European_middle = 2, European_late = 3, `European_Sum/avg.` = 4,
           Slave_early = 5, Slave_middle = 6, Slave_late = 7, `Slave_Sum/avg.` = 8)
for (i in seq_len(nrow(t5))) {
  r <- rowid[paste0(t5$grp[i], "_", t5$cohort[i])]
  add(paste0("T5_r", r, "_c1"), t5$minor[i]); add(paste0("T5_r", r, "_c2"), t5$theft[i])
  add(paste0("T5_r", r, "_c3"), t5$violence[i]); add(paste0("T5_r", r, "_c4"), t5$murder[i])
  for (cc in 5:8) add(paste0("T5_r", r, "_c", cc), NA, status = "unavailable")
  add(paste0("T5_r", r, "_c9"), t5$ratio[i])
}
add("TXT_p643_a", t5$ratio[t5$grp == "European" & t5$cohort == "Sum/avg."])
add("TXT_p643_b", t5$ratio[t5$grp == "Slave" & t5$cohort == "Sum/avg."])

# =============================================================================
# Table 6: logit with marginal effects x125
# =============================================================================
m6  <- glm(exact ~ female + age23 + group + factor(bdec), family = binomial, data = s)
m6n <- glm(exact ~ 1, family = binomial, data = s)
pr2 <- 1 - as.numeric(logLik(m6)) / as.numeric(logLik(m6n))
X   <- model.matrix(m6); b <- coef(m6)
gcols <- grep("^group", colnames(X), value = TRUE)
vlist <- list(conv = vcov(m6), hc1 = vcovHC(m6, type = "HC1"), cl = vcovCL(m6, cluster = s$source, type = "HC1"))

me_fun <- function(var, type) {
  set_x <- function(M, val) {
    M[, var] <- val
    if (var %in% gcols && type == "ame") M[, setdiff(gcols, var)] <- 0   # factor-style switch from base
    M
  }
  if (type == "mem") {
    xb <- matrix(colMeans(X), nrow = 1, dimnames = list(NULL, colnames(X)))
    x1 <- set_x(xb, 1); x0 <- set_x(xb, 0)
  } else { x1 <- set_x(X, 1); x0 <- set_x(X, 0) }
  z1 <- drop(x1 %*% b); z0 <- drop(x0 %*% b)
  est  <- mean(plogis(z1) - plogis(z0))
  grad <- colMeans(dlogis(z1) * x1 - dlogis(z0) * x0)
  map_dfr(names(vlist), \(k) tibble(var = var, type = type, vcov = k, me125 = 125 * est,
                                    se125 = 125 * sqrt(drop(t(grad) %*% vlist[[k]] %*% grad))))
}
mem_deriv <- function(var) {   # derivative at means: lambda(xbar b) * b_j
  xb <- colMeans(X); z <- sum(xb * b); est <- dlogis(z) * b[var]
  grad <- dlogis(z) * (1 - 2 * plogis(z)) * b[var] * xb; grad[var] <- grad[var] + dlogis(z)
  map_dfr(names(vlist), \(k) tibble(var = var, type = "mem_deriv", vcov = k, me125 = 125 * est,
                                    se125 = 125 * sqrt(drop(t(grad) %*% vlist[[k]] %*% grad))))
}
vars6 <- c("female", "age23", gcols)
t6 <- bind_rows(map_dfr(vars6, me_fun, type = "mem"), map_dfr(vars6, me_fun, type = "ame"),
                map_dfr(vars6, mem_deriv)) |>
  mutate(p = 2 * pnorm(-abs(me125 / se125)), N = nobs(m6), pseudo_r2 = pr2)
write_csv(t6, file.path(out, "table6_logit_me.csv"))

# gender sensitivity (primary ME type, conventional)
sens6 <- map_dfr(c("female", "female2", "female3"), function(fv) {
  d6 <- s |> mutate(fem = .data[[fv]])
  f  <- glm(exact ~ fem + age23 + group + factor(bdec), family = binomial, data = d6)
  Xs <- model.matrix(f); bs <- coef(f); xb <- colMeans(Xs)
  map_dfr(grep("^group", names(bs), value = TRUE), function(v) {
    x1 <- x0 <- xb; x1[v] <- 1; x0[v] <- 0
    tibble(gender_var = fv, var = v, me125 = 125 * (plogis(sum(x1 * bs)) - plogis(sum(x0 * bs))))
  })
})
write_csv(sens6, file.path(out, "table6_gender_sensitivity.csv"))

t6p <- t6 |> filter(type == "mem", vcov == "conv")
map6 <- c(T6_r1 = "female", T6_r2 = "age23", T6_r3 = "groupChinese", T6_r4 = "groupEuropean",
          T6_r5 = "groupSouth-east Asian", T6_r6 = "groupIndian", T6_r7 = "groupKhoesan",
          T6_r8 = "groupMozambican", T6_r9 = "groupSlave, unknown")
for (id in names(map6)) {
  r <- t6p |> filter(var == map6[[id]])
  add(id, r$me125, r$se125, nobs(m6)); add(paste0(id, "_p"), r$p, n = nobs(m6))
}
add("T6_n", nobs(m6), n = nobs(m6)); add("T6_rsq", pr2, n = nobs(m6))
add("TXT_p645_a", t6p$me125[t6p$var == "groupEuropean"])
add("TXT_p645_b", t6p$me125[t6p$var == "groupIndian"])
add("TXT_p645_c", t6p$me125[t6p$var == "groupSouth-east Asian"])
add("TXT_p645_d", t6p$me125[t6p$var == "groupMozambican"])

# =============================================================================
# Table 7: cell counts; Table 8: OLS with group x cohort cells (ref = Chinese)
# =============================================================================
s <- s |> mutate(cell = if_else(cellgrp == "Chinese", "Chinese", paste(cellgrp, cohort, sep = "_")),
                 cell = relevel(factor(cell), ref = "Chinese"))
t7 <- s |> filter(cellgrp != "Chinese") |> count(cellgrp, cohort)
write_csv(t7, file.path(out, "table7.csv"))
map7 <- tribble(~id, ~g, ~c,
  "T7_r1_c1", "European", "early", "T7_r1_c2", "European", "middle", "T7_r1_c3", "European", "late",
  "T7_r2_c1", "South-east Asian", "early", "T7_r2_c2", "South-east Asian", "middle",
  "T7_r3_c1", "Indian", "early", "T7_r3_c2", "Indian", "middle",
  "T7_r4_c1", "Khoesan", "early", "T7_r4_c2", "Khoesan", "middle", "T7_r4_c3", "Khoesan", "late",
  "T7_r5_c2", "Mozambican", "middle", "T7_r5_c3", "Mozambican", "late",
  "T7_r6_c2", "Cape-born", "middle", "T7_r6_c3", "Cape-born", "late",
  "T7_r7_c1", "Slave, unknown", "early", "T7_r7_c2", "Slave, unknown", "middle", "T7_r7_c3", "Slave, unknown", "late")
for (i in seq_len(nrow(map7))) {
  v <- t7$n[t7$cellgrp == map7$g[i] & t7$cohort == map7$c[i]]
  add(map7$id[i], v, n = v)
}

m8_1 <- lm(exact ~ cell + female + age23, data = s)
m8_2 <- lm(exact ~ cell + female + age23 + sevshare, data = s |> filter(!is.na(sevshare)))
s8_3 <- s |> filter(crimecat %in% c("minor", "theft"))
m8_3 <- lm(exact ~ cell + female + age23, data = s8_3)
m8_2b <- lm(exact ~ cell + female + age23 + sevshare_reg, data = s)          # alternative severity share
t8 <- bind_rows(ols_tab(m8_1, s$source) |> mutate(col = 1, N = nobs(m8_1), r2 = r2(m8_1)),
                ols_tab(m8_2, s$source) |> mutate(col = 2, N = nobs(m8_2), r2 = r2(m8_2)),
                ols_tab(m8_3, s8_3$source) |> mutate(col = 3, N = nobs(m8_3), r2 = r2(m8_3)),
                ols_tab(m8_2b, s$source) |> mutate(col = 22, N = nobs(m8_2b), r2 = r2(m8_2b)))
write_csv(t8, file.path(out, "table8.csv"))
rows8 <- c(r1 = "age23", r2 = "cellEuropean_early", r3 = "cellEuropean_middle", r4 = "cellEuropean_late",
           r5 = "cellSouth-east Asian_early", r6 = "cellSouth-east Asian_middle",
           r7 = "cellIndian_early", r8 = "cellIndian_middle",
           r9 = "cellKhoesan_early", r10 = "cellKhoesan_middle", r11 = "cellKhoesan_late",
           r12 = "cellMozambican_middle", r13 = "cellMozambican_late",
           r14 = "cellSlave, unknown_early", r15 = "cellSlave, unknown_middle", r16 = "cellSlave, unknown_late",
           r17 = "cellCape-born_middle", r18 = "cellCape-born_late", r19 = "sevshare", r20 = "(Intercept)")
for (k in 1:3) {
  tt <- t8 |> filter(col == k, vcov == "conv")
  for (r in names(rows8)) {
    if (r == "r19" && k != 2) next
    x <- tt |> filter(term == rows8[[r]])
    add(paste0("T8_", r, "_c", k), x$coef125, x$se_unscaled, tt$N[1])
  }
  add(paste0("T8_orphse_c", k), (tt |> filter(term == "female"))$se_unscaled, n = tt$N[1])
  add(paste0("T8_rsq_c", k), tt$r2[1], n = tt$N[1]); add(paste0("T8_n_c", k), tt$N[1], n = tt$N[1])
}

# Figure 4 levels: constant + cell coefficient (col 1)
c1 <- coef(m8_1)
f4 <- tribble(~id, ~grp, ~coh, ~term,
  "F4_1", "Europe", "1650s-1740s", "cellEuropean_early", "F4_2", "Europe", "1750s-1780s", "cellEuropean_middle",
  "F4_3", "Europe", "1790s", "cellEuropean_late",
  "F4_4", "South-east Asia", "1650s-1740s", "cellSouth-east Asian_early", "F4_5", "South-east Asia", "1750s-1780s", "cellSouth-east Asian_middle",
  "F4_6", "India", "1650s-1740s", "cellIndian_early", "F4_7", "India", "1750s-1780s", "cellIndian_middle",
  "F4_8", "China", "1650s-1740s", NA,
  "F4_9", "Khoesan", "1650s-1740s", "cellKhoesan_early", "F4_10", "Khoesan", "1750s-1780s", "cellKhoesan_middle",
  "F4_11", "Khoesan", "1790s", "cellKhoesan_late",
  "F4_12", "Mozambique", "1750s-1780s", "cellMozambican_middle", "F4_13", "Mozambique", "1790s", "cellMozambican_late",
  "F4_14", "Cape", "1750s-1780s", "cellCape-born_middle", "F4_15", "Cape", "1790s", "cellCape-born_late",
  "F4_16", "Slaves, unknown", "1650s-1740s", "cellSlave, unknown_early", "F4_17", "Slaves, unknown", "1750s-1780s", "cellSlave, unknown_middle",
  "F4_18", "Slaves, unknown", "1790s", "cellSlave, unknown_late") |>
  mutate(abcc = 125 * (c1["(Intercept)"] + if_else(is.na(term), 0, c1[term])))
write_csv(f4, file.path(out, "figure4_levels.csv"))
for (i in seq_len(nrow(f4))) add(f4$id[i], f4$abcc[i])
fv <- setNames(f4$abcc, f4$id)
add("TXT_p646_a", min(fv[c("F4_1", "F4_2", "F4_3")])); add("TXT_p646_b", max(fv[c("F4_1", "F4_2", "F4_3")]))
add("TXT_p650_c", fv["F4_8"]); add("TXT_p650_d", fv["F4_12"])
add("TXT_p650_e", fv["F4_11"]); add("TXT_p650_f", fv["F4_15"])
for (r in 1:5) add(paste0("T10_r", r, "_our"), fv["F4_6"])
add("T10_r6_our", fv["F4_8"]); add("T10_r7_our", fv["F4_12"]); add("T10_r8_our", fv["F4_15"])
add("T10_r9_our", fv["F4_11"]); add("T10_r10_our", fv["F4_3"])

# =============================================================================
# Table 9: cohort differences within group (separate OLS)
# =============================================================================
pairs9 <- tribble(~id, ~g, ~c0, ~c1,
  "T9_r1", "Indian", "early", "middle", "T9_r2", "South-east Asian", "early", "middle",
  "T9_r3", "European", "early", "middle", "T9_r4", "European", "middle", "late",
  "T9_r5", "Khoesan", "early", "middle", "T9_r6", "Khoesan", "middle", "late",
  "T9_r7", "Mozambican", "middle", "late", "T9_r8", "Cape-born", "middle", "late",
  "T9_r9", "Slave, unknown", "early", "middle", "T9_r10", "Slave, unknown", "middle", "late")
t9 <- pmap_dfr(pairs9, function(id, g, c0, c1) {
  d9 <- s |> filter(cellgrp == g, cohort %in% c(c0, c1)) |> mutate(later = as.integer(cohort == c1))
  f  <- lm(exact ~ later + female + age23, data = d9)
  ols_tab(f, d9$source) |> filter(term == "later") |> mutate(id = id, group = g, from = c0, to = c1, N = nobs(f))
})
write_csv(t9, file.path(out, "table9.csv"))
for (i in which(t9$vcov == "conv")) {
  add(t9$id[i], t9$coef125[i], t9$se125[i], t9$N[i]); add(paste0(t9$id[i], "_p"), t9$p[i], n = t9$N[i])
}
add("TXT_p646_c", t9$coef125[t9$id == "T9_r1" & t9$vcov == "conv"])

# =============================================================================
# Table 1 and other text numbers
# =============================================================================
imp <- full |> filter(!is.na(country), !country %in% c("Cape Colony", "Europe")) |>
  mutate(reg = case_when(country %in% c("Mosambique", "Angola", "Kenya", "Natal", "St Helena") ~ "Africa",
                         country %in% c("Madagascar", "Mauritius") ~ "Madagascar and Mauritius",
                         country %in% c("India", "Ceilon") ~ "India and Ceylon",
                         country %in% c("Indonesia", "Timor", "Malaysia", "Thailand") ~ "South-east Asia",
                         TRUE ~ "Other"))
t1 <- imp |> count(reg) |> mutate(share = 100 * n / sum(n))
write_csv(t1, file.path(out, "table1.csv"))
shell <- c(Africa = 26.4, `Madagascar and Mauritius` = 25.1, `India and Ceylon` = 25.9, `South-east Asia` = 22.7)
for (j in 1:4) {
  sh <- t1$share[t1$reg == names(shell)[j]]
  add(paste0("T1_r", j, "_c1"), NA, status = "not-attempted")
  add(paste0("T1_r", j, "_c2"), sh, n = nrow(imp))
  add(paste0("T1_r", j, "_c3"), sh - shell[[j]], n = nrow(imp))
}

add("TXT_p633_a", nrow(s), n = nrow(s))
add("TXT_p639_a", sum(s$group == "European")); add("TXT_p639_b", sum(s$group == "Khoesan"))
add("TXT_p639_c", sum(s$eths == "bl" & s$group != "Chinese"))
ab <- cut(s0$age, c(22, 32, 42, 52, 62, 72))
for (j in 1:5) add(paste0("TXT_p639_", letters[3 + j]), sum(as.integer(ab) == j))
add("TXT_p644_a", sum(full$matched), n = nrow(full))
dri <- s |> filter(eths == "bl") |> mutate(notRI = 1 - matched)
mri <- lm(exact ~ notRI + cohort, data = dri)
rri <- ols_tab(mri, dri$source) |> filter(term == "notRI")
write_csv(rri |> mutate(N = nobs(mri)), file.path(out, "robben_island_check.csv"))
add("TXT_p644_b", rri$coef125[rri$vcov == "conv"], rri$se125[rri$vcov == "conv"], nobs(mri))

# =============================================================================
# LaTeX tables (T6 and T8 col 1-3)
# =============================================================================
t6tex <- t6p |> transmute(Variable = str_remove(var, "^group"),
                          `ME x 125` = sprintf("%.2f", me125), `p` = sprintf("(%.2f)", p))
kbl(t6tex, format = "latex", booktabs = TRUE,
    caption = "Recreated Table 6: logit marginal effects at means (x125), conventional p-values") |>
  footnote(general = sprintf("N = %d; pseudo R2 = %.3f; birth-decade fixed effects included.", nobs(m6), pr2)) |>
  save_kable(file.path(out, "table6.tex"))
t8tex <- t8 |> filter(vcov == "conv", col %in% 1:3, term != "female") |>
  transmute(term = str_remove(term, "^cell"), col = paste0("(", col, ")"),
            cell = sprintf("%.2f (%.4f)", coef125, se_unscaled)) |>
  pivot_wider(names_from = col, values_from = cell, values_fill = "")
kbl(t8tex, format = "latex", booktabs = TRUE,
    caption = "Recreated Table 8: OLS x125, reference Chinese; SEs unscaled, conventional") |>
  save_kable(file.path(out, "table8.tex"))

# =============================================================================
# results_r.csv: one row per claim
# =============================================================================
rr <- bind_rows(res)
stopifnot(!any(duplicated(rr$claim_id)))
rr <- claims |> select(claim_id) |> left_join(rr, by = "claim_id") |>
  mutate(source = "r",
         status_override = case_when(!is.na(status_override) ~ status_override,
                                     is.na(value) ~ "not-attempted", TRUE ~ NA_character_))
write_csv(rr, file.path(paper, "repro_r", "results_r.csv"), na = "")
cat("02_analysis.R done:", sum(!is.na(rr$value)), "of", nrow(rr), "claims computed\n")
