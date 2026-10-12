# 01_primary.R -- P21_LFG S6 primary (card §4, §8): reproduction check, linked-household cluster bootstrap
# (B = 999), Bonferroni band over 66 annual comparisons, sign-row verdicts, point comparisons, MC precision,
# §5C items 13, 14 and 16 from the primary draws.
source(here::here("P21_LFG", "modern", "00_common.R"))
library(parallel)
B <- 999; NW <- 6
E <- est_rows(prep_base(d0)); E$cl <- cluster_id(E)

## Reproduction check (§4): full-data centres vs repro_r/results_r.csv and s5 annual_base_aux.csv (< 1e-6)
C0 <- centres(E); G0 <- pooled(C0)
rr <- read_csv(here::here("P21_LFG", "repro_r", "results_r.csv"), show_col_types = FALSE)
ax <- read_csv(here::here("P21_LFG", "compare", "s5_checks", "annual_base_aux.csv"), show_col_types = FALSE)
d_pool <- abs(G0 - rr$value[match(c("F7_all_median", "F8_all_median", "F9_1812_1817_median"), rr$claim_id)])
d_ann <- abs(C0 - as.matrix(ax[match(YEARS, ax$year), PAIRS]))
REPRO_OK <- max(d_pool) < 1e-6 && max(d_ann) < 1e-6 && all(is.finite(C0))
cat(sprintf("Reproduction check: max |pooled diff| = %.2e, max |annual diff| = %.2e -> %s\n",
  max(d_pool), max(d_ann), ifelse(REPRO_OK, "PASS", "FAIL")))
write_csv(tibble(check = c("pooled_F7_F8_F9", "annual_66"), max_abs_diff = c(max(d_pool), max(d_ann)),
  tol = 1e-6, pass = c(max(d_pool) < 1e-6, max(d_ann) < 1e-6)), file.path(OUT, "repro_check.csv"))
# full-data non-finite household HEC counts and M <= 0 counts (item 16)
i16 <- bind_rows(lapply(YEARS, function(t) { e <- E[E$year == t, ]; r <- hec_fit(e, rep(TRUE, nrow(e)), full = TRUE)
  tibble(year = t, n = nrow(e), Mk_le0 = sum(r$M[, "Mk"] <= 0), Ms_le0 = sum(r$M[, "Ms"] <= 0), Mf_le0 = sum(r$M[, "Mf"] <= 0),
    nonfin_FS = sum(!is.finite(r$H[, "FS"])), nonfin_FK = sum(!is.finite(r$H[, "FK"])), nonfin_SK = sum(!is.finite(r$H[, "SK"]))) }))

## Cluster bootstrap: draws generated sequentially from one L'Ecuyer stream; fits distributed across workers
rows_by_cl <- split(seq_len(nrow(E)), E$cl); G <- length(rows_by_cl)
set.seed(20261012, kind = "L'Ecuyer-CMRG")
draws <- lapply(seq_len(B), function(b) sample.int(G, G, replace = TRUE))
boot_one <- function(dr) { e <- E[replicate_rows(rows_by_cl, dr), , drop = FALSE]
  C <- matrix(NA_real_, 22, 3); NF <- matrix(NA_real_, 22, 3)
  for (i in 1:22) { ee <- e[e$year == YEARS[i], , drop = FALSE]; H <- hec_fit(ee, rep(TRUE, nrow(ee)))
    if (is.null(H)) next; C[i, ] <- apply(H, 2, cstat); NF[i, ] <- colSums(!is.finite(H)) }
  c(C, NF) }
t0 <- Sys.time()
cl <- makeCluster(NW); clusterExport(cl, c("E", "rows_by_cl", "YEARS", "hec_fit", "design", "cstat", "replicate_rows"))
res <- parLapply(cl, draws, boot_one); stopCluster(cl)
cat("bootstrap minutes:", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 2), "\n")
R <- do.call(rbind, res)
Cs <- array(R[, 1:66], c(B, 22, 3), dimnames = list(NULL, YEARS, PAIRS)); NFs <- array(R[, 67:132], c(B, 22, 3))
saveRDS(list(Cs = Cs, NFs = NFs, C0 = C0), file.path(SCR, "primary_draws.rds"))

## Valid draws, bands, verdicts
claims <- c(F7 = "FS", F8 = "FK", F9 = "SK")
band_verdict <- function(c0, Cd, z, Bn) {     # c0: 22 centres; Cd: Bn x 22 draws
  valid <- rowSums(is.na(Cd)) == 0; V <- sum(valid)
  se <- apply(Cd[valid, , drop = FALSE], 2, sd); L <- c0 - z * se; U <- c0 + z * se
  rule <- if (any(!is.finite(c0)) || V < 0.99 * Bn) 0 else if (any(U <= 0)) 1 else if (all(L > 0)) 2 else if (all(c0 > 0)) 3 else 4
  list(valid = valid, V = V, se = se, L = L, U = U, rule = rule) }
saveRDS(band_verdict, file.path(SCR, "band_verdict_fn.rds"))
VERD <- c("0" = "not-testable", "1" = "weakened", "2" = "confirmed", "3" = "qualified", "4" = "weakened")
prim <- list(); vt <- list(); pt <- list(); mc <- list(); dg <- list(); pc <- list()
bands <- list(F7 = c(.765, .935), F8 = c(.72, .88), F9 = c(.81, .99)); stated <- c(F7 = .85, F8 = .8, F9 = .9)
for (k in names(claims)) { p <- claims[k]; c0 <- C0[, p]; Cd <- Cs[, , p]
  bv <- band_verdict(c0, Cd, Z_BAND, B); if (!REPRO_OK) bv$rule <- 0
  pval <- pnorm(-c0 / bv$se)                        # one-sided normal p for c_t <= 0, per year (unadjusted)
  prim[[k]] <- tibble(claim = k, pair = p, year = YEARS, centre = c0, se = bv$se, L = bv$L, U = bv$U,
    status = ifelse(bv$U <= 0, "supported nonpositive", ifelse(bv$L > 0, "supported positive", "unsupported")),
    se_zero = bv$se == 0, p_one_sided = pval, V = bv$V,
    fail_draws = colSums(is.na(Cd)), nonfin_full = i16[[paste0("nonfin_", p)]], nonfin_mean_draws = colMeans(NFs[, , match(p, PAIRS)], na.rm = TRUE))
  # Point comparison (§8C): pooled centre G with z_pt interval from the same valid draws
  Gd <- if (k == "F9") apply(Cd[bv$valid, YEARS %in% 1811:1817, drop = FALSE], 1, median) else apply(Cd[bv$valid, , drop = FALSE], 1, median)
  G <- unname(G0[k]); seG <- sd(Gd); lo <- bands[[k]][1]; hi <- bands[[k]][2]; IL <- G - Z_PT * seG; IU <- G + Z_PT * seG
  st <- if (!REPRO_OK || bv$V < 990) 0 else if (G >= lo && G <= hi && IL >= lo && IU <= hi) 1 else if (G >= lo && G <= hi) 2 else if (G < lo) 3 else 4
  pt[[k]] <- tibble(row = paste0(k, "-pt"), G = G, se = seG, I_lo = IL, I_hi = IU, band_lo = lo, band_hi = hi, status_rule = st,
    status = c("not computable", "within band, interval inside", "within band, interval wider than band", "below band", "above band")[st + 1],
    flag = if (st == 3 && IU < lo) "supported" else if (st == 4 && IL > hi) "supported" else "", plaus_flag = G > 1.5 * stated[[k]])
  # MC precision: 10 consecutive batches of valid draws
  vi <- which(bv$valid); nb <- floor(length(vi) / 10)
  bL <- bU <- matrix(NA, 10, 22)
  for (j in 1:10) { s <- apply(Cd[vi[((j - 1) * nb + 1):(j * nb)], , drop = FALSE], 2, sd); bL[j, ] <- c0 - Z_BAND * s; bU[j, ] <- c0 + Z_BAND * s }
  mcL <- apply(bL, 2, sd) / sqrt(10); mcU <- apply(bU, 2, sd) / sqrt(10)
  mc[[k]] <- tibble(claim = k, year = YEARS, L = bv$L, mcse_L = mcL, U = bv$U, mcse_U = mcU,
    mc_fragile = abs(bv$L) < 2 * mcL | abs(bv$U) < 2 * mcU)
  # Item 13 diagnostics
  Dv <- Cd[bv$valid, , drop = FALSE]
  dg[[k]] <- tibble(claim = k, year = YEARS, skew = apply(Dv, 2, function(x) mean((x - mean(x))^3) / sd(x)^3),
    exkurt = apply(Dv, 2, function(x) mean((x - mean(x))^4) / sd(x)^4 - 3), sd_over_madn = bv$se / (1.4826 * apply(Dv, 2, mad, constant = 1)),
    share_gt5se = colMeans(abs(sweep(Dv, 2, c0)) > 5 * rep(bv$se, each = nrow(Dv))), n_abs_gt10 = colSums(abs(Dv) > 10))
  # Item 14 percentile intervals and sup-t band
  a <- 0.05 / 66; pos <- bv$se > 0
  tstat <- abs(sweep(Dv[, pos, drop = FALSE], 2, c0[pos])) / rep(bv$se[pos], each = nrow(Dv))
  cst <- if (any(pos)) quantile(apply(tstat, 1, max), 1 - 0.05 / 3, type = 7) else NA
  pc[[k]] <- tibble(claim = k, year = YEARS, pct_lo = apply(Dv, 2, quantile, a / 2, type = 7), pct_hi = apply(Dv, 2, quantile, 1 - a / 2, type = 7),
    supt_c = unname(cst), supt_lo = c0 - cst * bv$se, supt_hi = c0 + cst * bv$se, se_zero_excluded = sum(!pos))
  dec <- which.min(bv$L)
  vt[[k]] <- tibble(claim = k, row = paste0(k, "-s"), estimate = sprintf("min c_t = %.3f (%d); pooled %.3f", min(c0), YEARS[which.min(c0)], G),
    interval = sprintf("decisive year %d: [%.3f, %.3f] (Bonferroni z = %.3f, V = %d/999)", YEARS[dec], bv$L[dec], bv$U[dec], Z_BAND, bv$V),
    test_p = sprintf("max_t one-sided p = %.3g (unadjusted; band decides)", max(pval)),
    threshold = "c_t > 0 in all 22 years (T = 0 strict)",
    n_supported_pos = sum(bv$L > 0), n_supported_nonpos = sum(bv$U <= 0), n_point_nonpos = sum(c0 <= 0),
    verdict = paste0(VERD[as.character(bv$rule)], if (bv$rule %in% 1:3) " (on the S3 reconstruction)" else "",
      if (bv$rule == 1) "; flag: supported nonpositive year; overturned unreachable under A4b" else ""), rule = bv$rule)
}
P <- bind_rows(prim); PT <- bind_rows(pt); VT <- bind_rows(vt)
VT <- bind_rows(VT, tibble(claim = "INT", row = "INT", estimate = "", interval = "", test_p = "", threshold = "HEC > 0 read as non-substitutability",
  verdict = "not-testable", rule = NA))
write_csv(P, file.path(OUT, "primary.csv")); write_csv(PT, file.path(OUT, "point_comparisons.csv"))
write_csv(VT, file.path(OUT, "verdict.csv")); write_csv(bind_rows(mc), file.path(OUT, "mc_precision.csv"))
write_csv(bind_rows(dg), file.path(OUT, "diag_item13.csv")); write_csv(bind_rows(pc), file.path(OUT, "diag_item14_pct_supt.csv"))
write_csv(i16, file.path(OUT, "item16_counts.csv"))
print(as.data.frame(VT[, c("claim", "estimate", "interval", "verdict", "rule")])); print(as.data.frame(PT))
print(as.data.frame(P |> select(claim, year, centre, se, L, U, status, fail_draws)), digits = 3)
cat("MC-fragile bounds:", sum(bind_rows(mc)$mc_fragile), "\n")
print(bind_rows(mc) |> filter(mc_fragile))
