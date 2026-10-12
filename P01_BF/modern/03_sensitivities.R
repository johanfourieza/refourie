# P01_BF S6 step 3: admissible sensitivities (card §5; reported, never verdict-setting).
# Numbering follows the card: 1-4 decomposition, 5-10 and 13 alternative estimators/codings, 14-17 and 21
# alternative inference, 18-20 changed populations/influence, 11 audit decomposition. Sensitivity 12 (prose
# magnitudes) needs the primary Holm p-values and is appended by 04_verdicts.R.
# T6 intervals: est +/- t(G-1, 1 - 0.05/18) SE (normal quantile for the non-cluster vcovs of 14); H3 at 1 - 0.05/9.
# Outputs: output/sensitivities.csv, s15_pairs_boot_summary.csv, s20_loo.csv
source(here::here("P01_BF", "modern", "00_common.R"))
library(parallel)

o <- load_raw() |> mutate(rowid = row_number()); d <- load_sample(o)
G <- n_distinct(d$source); LVL <- ALPHA / M_FAM
mf0 <- t6_frame(d, "g"); m0 <- t6_fit(mf0); xN0 <- profile_N(m0); need_bd <- levels(mf0$bd)
prim <- read_csv(file.path(out, "t6_primary.csv"), show_col_types = FALSE)
h3p  <- read_csv(file.path(out, "h3_primary.csv"), show_col_types = FALSE)
h0 <- h3_frame(d)
res <- list(); add <- function(x) res[[length(res) + 1]] <<- x

# generic T6 runner: refits on mf (own profile), separation check, chosen vcov; rows of the headline groups present
run_t6 <- function(mf, sens, label, convention = "corrected", vtype = "CR1", cl = mf$source, type = c("pt", "rel")) {
  mf$bd <- droplevels(mf$bd); present <- LV[LV %in% unique(as.character(mf$g))]
  if (!"za" %in% present) return(tibble(sens, label, status = "failed: no Cape-born reference"))
  mf$g <- factor(as.character(mf$g), levels = present)
  m <- tryCatch(t6_fit(mf), error = function(e) e)
  if (inherits(m, "error")) return(tibble(sens, label, status = paste("failed:", conditionMessage(m))))
  sc <- tryCatch(sep_check(mf), error = function(e) NULL)
  grs <- intersect(names(HG), present)
  blk <- if (is.null(sc)) set_names(rep(NA, length(grs)), grs) else sep_blocked(sc, grs)
  V <- switch(vtype, CR1 = vcov_cr1(m, cl), conv = vcov(m), HC1 = vcovHC(m, type = "HC1"))
  df <- if (vtype == "CR1") n_distinct(cl) - 1 else NULL
  delta_tab(t6_contrasts(m, grs, convention), V, df) |> filter(scale %in% type) |>
    mutate(sens, label, n = nobs(m), G = n_distinct(cl),
           status = case_when(!m$converged ~ "not converged", is.na(blk[group]) ~ "ok (separation check failed)",
                              blk[group] ~ "separation: coefficient infinite", TRUE ~ "ok"),
           note = paste0("missing groups: ", paste(setdiff(names(HG), present), collapse = ","),
                         "; infinite coefs: ", if (is.null(sc)) "check failed" else paste(names(sc$coef)[!is.finite(sc$coef)], collapse = ",")))
}

# ---- A. decomposition ---------------------------------------------------------------------------------
add(run_t6(mf0, "1", "coding correction only, published mfx convention", convention = "published"))
add(run_t6(t6_frame(d, "g_orig"), "2", "contrast correction only, original coding"))
add(run_t6(t6_frame(d, "g_kust"), "3a", "Kust/Cust fix alone, corrected contrast"))
add(run_t6(t6_frame(d, "g_west"), "3b", "Westcoast fix alone, corrected contrast"))
add(run_t6(t6_frame(d, "g_coeh"), "3c", "Coehin fix alone, corrected contrast"))
add(run_t6(t6_frame(d, "g_orig"), "4", "published coding and convention, primary inference (CR1, t(G-1))", convention = "published"))

# ---- B. alternative estimators and estimands ----------------------------------------------------------
avg_contr <- function(m, idx) {
  X <- model.matrix(m)[idx, , drop = FALSE]; b <- coef(m); oc <- ocols(colnames(X)); X0 <- X; X0[, oc] <- 0
  map(set_names(names(HG)), function(gr) {
    X1 <- X0; X1[, paste0("g", gr)] <- 1; z0 <- drop(X0 %*% b); z1 <- drop(X1 %*% b); p0 <- plogis(z0); p1 <- plogis(z1)
    list(pt = 125 * mean(p1 - p0), rel = log(mean(p1)) - log(mean(p0)), p0 = mean(p0), p1 = mean(p1),
         g_pt = 125 * colMeans(dlogis(z1) * X1 - dlogis(z0) * X0),
         g_rel = colMeans(dlogis(z1) * X1) / mean(p1) - colMeans(dlogis(z0) * X0) / mean(p0))
  })
}
V0 <- vcov_cr1(m0, d$source)
add(delta_tab(avg_contr(m0, seq_len(nrow(d))), V0, G - 1) |> mutate(sens = "5", label = "AME over the estimation sample (different estimand)", n = nrow(d), G = G, status = "ok"))
add(map_dfr(names(HG), function(gr) delta_tab(avg_contr(m0, which(mf0$g == gr))[gr], V0, G - 1)) |>
      mutate(sens = "6", label = "contrast averaged over members of group g (different estimand)", n = nrow(d), G = G, status = "ok"))
# 7 LPM
lpm <- lm(I(125 * exactage) ~ fem + age23 + bd + g, data = mf0); Vl <- vcovCL(lpm, cluster = d$source, type = "HC1")
bl <- coef(lpm); xl <- xN0[names(bl)]
add(map_dfr(names(HG), function(gr) {
  t <- paste0("g", gr); x1 <- xl; x1[t] <- 1; L0 <- sum(xl * bl); L1 <- sum(x1 * bl)
  gp <- setNames(rep(0, length(bl)), names(bl)); gp[t] <- 1; gr_rel <- x1 / L1 - xl / L0
  tibble(group = gr, scale = c("pt", "rel"), est = c(bl[[t]], log(L1 / L0)),
         se = c(sqrt(Vl[t, t]), sqrt(drop(t(gr_rel) %*% Vl %*% gr_rel))))
}) |> mutate(row = paste0(HG[group], "-", scale), tstat = est / se, p = 2 * pt(-abs(tstat), G - 1),
             ci_lo = est - qt(1 - LVL / 2, G - 1) * se, ci_hi = est + qt(1 - LVL / 2, G - 1) * se,
             sens = "7", label = "LPM, CR1 by source, t(G-1) (rel = ratio of LPM levels at the profile)", n = nrow(d), G = G, status = "ok"))
# 8 Firth
mfF <- tryCatch(glm(T6_FORM, family = binomial, data = mf0, method = brglm2::brglmFit, type = "AS_mean"), error = function(e) e)
if (inherits(mfF, "error")) add(tibble(sens = "8", label = "Firth (AS_mean)", status = paste("failed:", conditionMessage(mfF)))) else {
  VF <- tryCatch(vcov_cr1(mfF, d$source), error = function(e) e)
  if (inherits(VF, "error")) add(tibble(sens = "8", label = "Firth (AS_mean)", status = paste("failed (vcov):", conditionMessage(VF)))) else
    add(delta_tab(t6_contrasts(mfF, xN = profile_N(mfF)), VF, G - 1) |>
          mutate(sens = "8", label = "Firth bias-reduced logit (AS_mean), approximate CR1", n = nrow(d), G = G,
                 status = if (isTRUE(mfF$converged)) "ok" else "not converged"))
}
add(run_t6(t6_frame(d, "g", fem = "female"), "9a", "gender coding female"))
add(run_t6(t6_frame(d, "g", fem = "female3"), "9b", "gender coding female3"))
add(run_t6(t6_frame(d, "g", bd = "bdec_alt"), "10", "birth decade from cyear - age (T6 time controls)"))

# H3 helpers for sensitivities: WCR p (B = 9,999, seeds reset) + Bonferroni CI
h3_sens <- function(h, sens, label, clustid = "source") {
  if (sum(h$mid == 0) == 0 || sum(h$mid == 1) == 0) return(tibble(sens, label, row = "H3", status = "failed: empty cohort", n = nrow(h)))
  D <- unname(coef(lm(y ~ mid, data = h))["mid"])
  bp <- tryCatch(h3_boot(h, 9999, conf_int = FALSE, clustid = clustid), error = function(e) e)
  bc <- tryCatch(h3_boot(h, 9999, conf_int = TRUE, clustid = clustid), error = function(e) e)
  ok <- !inherits(bp, "error"); okc <- !inherits(bc, "error") && all(is.finite(bc$conf_int))
  tibble(sens, label, row = "H3", est = D, p = if (ok) bp$p_val else NA, ci_lo = if (okc) min(bc$conf_int) else NA,
         ci_hi = if (okc) max(bc$conf_int) else NA, n = nrow(h), G = n_distinct(h[[clustid]]),
         status = if (ok) "ok" else paste("failed:", conditionMessage(bp)), note = paste0("n_early=", sum(h$mid == 0), "; WCR Webb B=9999"))
}
add(h3_sens(h3_frame(d, "bcoh_alt"), "10", "H3 cohorts from cyear - age (changed population, A4d)"))

# 13 H3 conditional estimands
hc <- lm(y ~ mid + female2 + age23, data = h0); Vh <- vcovCL(hc, cluster = h0$source, type = "HC1"); Gh <- n_distinct(h0$source)
ml <- glm(exactage ~ mid + female2 + age23, family = binomial, data = h0); Vml <- vcov_cr1(ml, h0$source)
xm <- colMeans(model.matrix(ml)); x1 <- replace(xm, "mid", 1); x0 <- replace(xm, "mid", 0); cm <- contr(coef(ml), x0, x1)
m8 <- lm(reformulate(c("female2", "age23", "eur_early", "eur_mid", "eur_post", "id_early", "id_mid", "in_early", "in_mid", "ko_early",
                      "ko_mid", "ko_post", "mz_mid", "mz_post", "otb_early", "otb_mid", "otb_post", "za_mid", "za_post"), "I(125 * exactage)"),
         data = d); V8 <- vcovCL(m8, cluster = d$source, type = "HC1"); L <- setNames(rep(0, length(coef(m8))), names(coef(m8)))
L[c("ko_mid", "ko_early")] <- c(1, -1)
add(tibble(sens = "13", row = "H3",
           label = c("H3 within-Khoesan OLS + female2 + age23, CR1 t(G-1)", "H3 logit MEM + female2 + age23, CR1 delta t(G-1)",
                     "H3 T8 col 1 difference ko_mid - ko_early, CR1 t(G-1) (G = 43)"),
           est = c(coef(hc)[["mid"]], cm$pt, sum(L * coef(m8))),
           se = c(sqrt(Vh["mid", "mid"]), sqrt(drop(t(cm$g_pt) %*% Vml %*% cm$g_pt)), sqrt(drop(t(L) %*% V8 %*% L))),
           G = c(Gh, Gh, G), n = c(nrow(h0), nrow(h0), nrow(d)), status = "ok") |>
      mutate(tstat = est / se, p = 2 * pt(-abs(tstat), G - 1), ci_lo = est - qt(1 - LVL / 2, G - 1) * se, ci_hi = est + qt(1 - LVL / 2, G - 1) * se))

# ---- C. alternative inference -------------------------------------------------------------------------
add(run_t6(mf0, "14a", "conventional logit vcov (normal)", vtype = "conv"))
add(run_t6(mf0, "14b", "HC1 (normal)", vtype = "HC1"))
# 16 H3
wt <- t.test(h0$y[h0$mid == 1], h0$y[h0$mid == 0])
wilson <- function(x, n, z) { p <- x / n; c0 <- (p + z^2 / (2 * n)) / (1 + z^2 / n); hw <- z / (1 + z^2 / n) * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)); c(c0 - hw, c0 + hw) }
z <- qnorm(1 - LVL / 2); x2 <- sum(h0$exactage[h0$mid == 1]); n2 <- sum(h0$mid == 1); x1e <- sum(h0$exactage[h0$mid == 0]); n1 <- sum(h0$mid == 0)
w2 <- wilson(x2, n2, z); w1 <- wilson(x1e, n1, z); p2 <- x2 / n2; p1 <- x1e / n1
nc <- 125 * c(p2 - p1 - sqrt((p2 - w2[1])^2 + (w1[2] - p1)^2), p2 - p1 + sqrt((w2[2] - p2)^2 + (p1 - w1[1])^2))
h3lm <- lm(y ~ mid, data = h0); Vc1 <- vcovCL(h3lm, cluster = h0$source, type = "HC1"); se1 <- sqrt(Vc1["mid", "mid"])
add(tibble(sens = "16", row = "H3", label = c("H3 Welch t-test", "H3 Newcombe hybrid score interval", "H3 CR1 by source, t(G-1)"),
           est = 125 * (p2 - p1), se = c(unname(wt$stderr), NA, se1),
           p = c(wt$p.value, NA, 2 * pt(-abs(coef(h3lm)[["mid"]] / se1), Gh - 1)),
           ci_lo = c(unname(wt$estimate[1] - wt$estimate[2]) - qt(1 - LVL / 2, wt$parameter) * wt$stderr, nc[1], coef(h3lm)[["mid"]] - qt(1 - LVL / 2, Gh - 1) * se1),
           ci_hi = c(unname(wt$estimate[1] - wt$estimate[2]) + qt(1 - LVL / 2, wt$parameter) * wt$stderr, nc[2], coef(h3lm)[["mid"]] + qt(1 - LVL / 2, Gh - 1) * se1),
           n = nrow(h0), G = c(NA, NA, Gh), status = "ok"))
# 17 court-year clustering
add(run_t6(mf0, "17", "CR1 clustered by court year, t(G-1)", cl = d$cyear))
add(h3_sens(h0, "17", "H3 WCR clustered by court year", clustid = "cyear"))

# ---- D. changed populations ---------------------------------------------------------------------------
dk <- d |> filter(knowsage == 1)
add(run_t6(t6_frame(dk, "g"), "18", "knowsage == 1 (changed population, A4d)"))
add(h3_sens(h3_frame(dk), "18", "H3 knowsage == 1 (changed population, A4d)"))
dm <- d |> filter(origin != "")
add(run_t6(t6_frame(dm, "g"), "19", "non-blank origin only (changed population, A4d)"))
add(h3_sens(h3_frame(dm), "19", "H3 non-blank origin only (changed population, A4d)"))

# ---- E. audit decomposition (11) ----------------------------------------------------------------------
f <- readRDS(dscratch("P01_BF", "repro_r", "p01_full.rds")); stopifnot(nrow(f) == nrow(o))
grp_r <- c("Cape-born" = "za", "Chinese" = "cn", "European" = "eur", "South-east Asian" = "id", "Indian" = "in", "Khoesan" = "ko",
           "Mozambican" = "mz", "Slave, unknown" = "oth_bl")
d11 <- d |> mutate(g_reb = unname(grp_r[as.character(f$group[rowid])]), female_reb = f$female[rowid], bdec_reb = f$bdec[rowid])
add(run_t6(t6_frame(d11, "g_reb", fem = "female_reb", bd = "bdec_reb"), "11",
           "AUDIT ONLY: S3 rebuild codings jointly (origin, bdec, female), corrected contrast; reproduces rebuild errors"))

# ---- 15 cluster pairs bootstrap (parallel, L'Ecuyer streams per draw) ---------------------------------
B15 <- as.integer(Sys.getenv("P01_B15", "9999")); vols <- unique(d$source)
RNGkind("L'Ecuyer-CMRG"); set.seed(SEED)
seeds <- vector("list", B15); s <- .Random.seed; for (b in seq_len(B15)) { seeds[[b]] <- s; s <- nextRNGStream(s) }
cl <- makeCluster(8); on.exit(stopCluster(cl), add = TRUE)
invisible(clusterEvalQ(cl, { suppressMessages(source(here::here("P01_BF", "modern", "00_common.R"))); NULL }))
clusterExport(cl, c("mf0", "xN0", "need_bd", "vols"))
t15 <- Sys.time()
bt <- parLapply(cl, seq_len(B15), function(b, seeds) {
  assign(".Random.seed", seeds[[b]], envir = .GlobalEnv)
  pick <- sample(vols, length(vols), replace = TRUE)
  mfb <- do.call(rbind, lapply(pick, function(v) mf0[mf0$source == v, ]))
  r <- t6_resample_est(mfb, xN0, need_bd = need_bd); r$draw <- b; r
}, seeds = seeds) |> bind_rows()
stopCluster(cl); on.exit()
cat("pairs bootstrap minutes:", round(as.numeric(difftime(Sys.time(), t15, units = "mins")), 1), "\n")
bs <- bt |> pivot_longer(c(pt, rel), names_to = "scale", values_to = "val") |> mutate(row = paste0(HG[group], "-", scale)) |>
  group_by(row) |> summarise(B = n(), undefined = sum(is.na(val)), share_undef = undefined / B,
                             q_lo = quantile(val, LVL / 2, na.rm = TRUE), q_hi = quantile(val, 1 - LVL / 2, na.rm = TRUE),
                             boot_sd = sd(val, na.rm = TRUE), .groups = "drop") |>
  mutate(available = share_undef <= LVL / 2, ci_lo = if_else(available, q_lo, NA_real_), ci_hi = if_else(available, q_hi, NA_real_))
write_csv(bs, file.path(out, "s15_pairs_boot_summary.csv"))
write_csv(count(bt, group, why), file.path(out, "s15_undefined_reasons.csv"))
add(bs |> left_join(prim |> select(row, est), by = "row") |>
      transmute(sens = "15", label = "cluster pairs bootstrap over source, B = 9,999, percentile (Bonferroni)", row, est, se = boot_sd,
                ci_lo, ci_hi, n = nrow(d), G = G, status = if_else(available, "ok", "interval unavailable (undefined share > 0.28%)"),
                note = sprintf("undefined %d of %d (%.2f%%)", undefined, B, 100 * share_undef)))

# ---- 20 leave-one-volume-out and 21 CV3 jackknife -----------------------------------------------------
loo_t6 <- function(v) {
  mf <- mf0[mf0$source != v, ]
  base <- tibble(group = rep(names(HG), each = 2), scale = rep(c("pt", "rel"), 4), est = NA_real_, se = NA_real_)
  if (!all(need_bd %in% unique(as.character(mf$bd)))) return(base |> mutate(why = "decade level absent"))
  m <- tryCatch(t6_fit(mf), error = function(e) NULL)
  if (is.null(m) || !m$converged) return(base |> mutate(why = "not converged"))
  cnt <- table(factor(mf$g, levels = LV)); if (cnt["za"] == 0) return(base |> mutate(why = "no Cape-born"))
  blk <- setNames(as.vector(sep_blocked(sep_check(mf)) | cnt[names(HG)] == 0), names(HG))
  V <- vcov_cr1(m, mf$source); b <- coef(m); xN <- xN0[names(b)]
  cs <- map(set_names(names(HG)), function(gr) { x1 <- xN; x1[paste0("g", gr)] <- 1; contr(b, xN, x1) })
  delta_tab(cs, V, n_distinct(mf$source) - 1) |> select(group, scale, est, se) |>
    mutate(est = if_else(blk[group], NA_real_, est), se = if_else(blk[group], NA_real_, se), why = if_else(blk[group], "separation/empty group", "ok"))
}
loo <- map_dfr(vols, function(v) {
  t6 <- loo_t6(v) |> mutate(row = paste0(HG[group], "-", scale), df = G - 2, p = 2 * pt(-abs(est / se), G - 2))
  if (v %in% h0$source) {
    h <- h0[h0$source != v, ]
    if (sum(h$mid == 0) == 0 || sum(h$mid == 1) == 0) h3 <- tibble(row = "H3", est = NA_real_, p = NA_real_, why = "empty cohort") else {
      D <- unname(coef(lm(y ~ mid, data = h))["mid"]); bb <- tryCatch(h3_boot(h, 9999), error = function(e) NULL)
      p <- if (is.null(bb)) NA_real_ else bb$p_val; Bf <- 9999
      if (is.finite(p) && mc_near(p, 9999)) { bb <- tryCatch(h3_boot(h, 99999), error = function(e) NULL); p <- if (is.null(bb)) NA_real_ else bb$p_val; Bf <- 99999 }
      h3 <- tibble(row = "H3", est = D, p = p, why = if (is.finite(p)) paste0("ok B=", Bf) else "boot failed")
    }
  } else h3 <- tibble(row = "H3", est = h3p$est, p = h3p$p, why = "volume has no Khoesan cohort 1-2: unchanged")
  bind_rows(t6 |> select(row, est, se, p, why), h3) |> mutate(volume = v)
})
write_csv(loo, file.path(out, "s20_loo.csv"))

cv3 <- function(r) {
  if (r == "H3") { th <- loo$est[loo$row == "H3" & loo$volume %in% unique(h0$source)]; Gr <- Gh; e0 <- h3p$est }
  else { th <- loo$est[loo$row == r]; Gr <- G; e0 <- prim$est[prim$row == r] }
  und <- sum(!is.finite(th)); sh <- und / length(th); ok <- sh <= LVL / 2
  thd <- th[is.finite(th)]; se <- sqrt((Gr - 1) / Gr * sum((thd - mean(thd))^2))
  q <- qt(1 - LVL / 2, Gr - 1)
  tibble(sens = "21", label = "cluster jackknife CV3 by source, t(G-1)", row = r, est = e0, se = if (ok) se else NA,
         p = if (ok) 2 * pt(-abs(e0 / se), Gr - 1) else NA, ci_lo = if (ok) e0 - q * se else NA, ci_hi = if (ok) e0 + q * se else NA,
         n = NA, G = Gr, status = if (ok) "ok" else "unavailable (undefined share > 0.28%)",
         note = sprintf("undefined deletions %d of %d", und, length(th)))
}
add(map_dfr(ROWS9, cv3))
add(loo |> group_by(row) |> summarise(lo = min(est, na.rm = TRUE), hi = max(est, na.rm = TRUE), und = sum(!is.finite(est)), k = n(), .groups = "drop") |>
      transmute(sens = "20", label = "leave-one-court-volume-out: range of estimates", row, ci_lo = lo, ci_hi = hi, G = G,
                status = "ok", note = sprintf("range over defined deletions; undefined %d of %d (verdict changes in 04)", und, k)))

sens <- bind_rows(res) |> select(any_of(c("sens", "label", "row", "est", "se", "p", "ci_lo", "ci_hi", "n", "G", "status", "note")))
write_csv(sens, file.path(out, "sensitivities.csv"))
print(sens |> select(sens, row, est, p, ci_lo, ci_hi, status) |> mutate(across(where(is.numeric), ~ signif(., 4))), n = 200)
