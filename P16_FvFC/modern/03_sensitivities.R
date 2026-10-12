# P16_FvFC S6 -- 03_sensitivities.R: card §5A, §5B and §5C (reported, never verdict-determining).
# Every bootstrap here uses B = 9,999 and the same per-draw streams as the central run.
# Outputs: output/sensitivities.csv, output/diag_*.csv, figures of the bootstrap distributions

source(here::here("P16_FvFC", "modern", "00_common.R"))
C  <- readRDS(file.path(SCR, "central.rds")); hh <- C$hh; cen <- C$cen; e0 <- C$e
BC <- readRDS(file.path(SCR, "boot_central.rds")); M <- BC$M            # first 9,999 central draws
B  <- 9999; streams <- make_streams(B)
raw <- read_raw()

POINT_BANDS <- list(H1 = c("G1663", 0.471, 0.531), `H2-pt` = c("G1709", 0.62, 0.68), `H3-pt` = c("G1757", 0.59, 0.65))
# Summarise one variant: point rows + family rows with the central §4 interval machinery and
# the §8 rule applied as a would-be verdict (labelled not verdict-determining).
summ_variant <- function(item, label, block, x0, R = NULL, Mv = NULL, rows = c(names(POINT_BANDS), names(ROW_NEEDS)), note = "") {
  out <- list()
  for (r in intersect(rows, names(POINT_BANDS))) {
    pb <- POINT_BANDS[[r]]; q <- pb[1]; G <- x0[q]
    ci <- if (!is.null(R)) pct_int(R[is.finite(R[, q]), q], 0.05) else c(L = NA, U = NA)
    out[[r]] <- tibble(item = item, label = label, block = block, row = r, quantity = q, estimate = G,
                       L = ci["L"], U = ci["U"], L95 = NA, interval = "95% percentile (reported only)",
                       would_be = v_point(G, as.numeric(pb[2]), as.numeric(pb[3]))["verdict"], note = note)
  }
  for (r in intersect(rows, names(ROW_NEEDS))) {
    need <- ROW_NEEDS[[r]]
    if (is.null(R)) {
      out[[r]] <- tibble(item = item, label = label, block = block, row = r, quantity = paste(need, collapse = ";"),
                         estimate = NA, L = NA, U = NA, L95 = NA, interval = "point only",
                         would_be = NA_character_, note = paste(note, paste(sprintf("%s=%.4f", need, x0[need]), collapse = " ")))
      next
    }
    a <- assess_row(r, Mv, R, x0)
    if (r == "H2-rise") {
      out[[r]] <- tibble(item = item, label = label, block = block, row = r, quantity = need, estimate = x0[need],
                         L = a$ep[paste0("L_", INIT)], U = a$ep[paste0("U_", INIT)], L95 = NA,
                         interval = "98.75% sup-t", would_be = a$va["verdict"], note = note)
    } else {
      wb <- a$va["verdict"]
      out[[r]] <- tibble(item = item, label = label, block = block, row = r, quantity = need, estimate = x0[need],
                         L = a$ep["L"], U = a$ep["U"], L95 = a$ep["L95"], interval = "98.75% percentile",
                         would_be = wb, note = note)
    }
  }
  bind_rows(out)
}
S <- list()

# =============================================================================================
# 5A. Same estimand, different inference
# =============================================================================================
P0 <- prep(hh, key = "key")
M_wy <- run_boot(P0, 1:B, streams, "within_year", label = "5A-1 within-year")
S$a1 <- summ_variant("5A-1", "independent within-year household bootstrap", "5A", cen, draw_rows(M_wy), M_wy)
P_x <- prep(hh, key = "key_x")
M_x <- run_boot(P_x, 1:B, streams, "cluster", label = "5A-2 exact-name clusters")
S$a2 <- summ_variant("5A-2", "exact-name clusters", "5A", cen, draw_rows(M_x), M_x)
far <- hh |> filter(farmer)
fix_far <- pca_fit(as.matrix(far[, CORE1])); fix_all <- pca_fit(as.matrix(hh[, CORE1]))
M_fx <- run_boot(P0, 1:B, streams, "cluster", opts = list(fixed_far = fix_far, fixed_all = fix_all), label = "5A-3 fixed PCA")
S$a3 <- summ_variant("5A-3", "PCA weights held fixed", "5A", cen, draw_rows(M_fx), M_fx)
# 5A-4: normal approximation X +/- z SE from the central draws (z at 98.75%; L95 at 95%)
Rc <- draw_rows(M); z <- qnorm(1 - ALPHA / 2)
na <- list()
for (r in names(ROW_NEEDS)) for (q in ROW_NEEDS[[r]]) {
  se <- sd(Rc[, q])
  na[[length(na) + 1]] <- tibble(item = "5A-4", label = "normal approximation X +/- z SE (central draws)", block = "5A", row = r,
    quantity = q, estimate = cen[q], L = cen[q] - z * se, U = cen[q] + z * se, L95 = cen[q] - 1.96 * se,
    interval = "98.75% normal (pointwise)", would_be = NA_character_, note = sprintf("SE %.4f", se))
}
na <- bind_rows(na)
for (r in names(ROW_NEEDS)) {
  k <- na$row == r; ep <- if (r == "H2-rise") c(setNames(na$L[k], paste0("L_", INIT)), setNames(na$U[k], paste0("U_", INIT)))
                         else c(L = unname(na$L[k]), U = unname(na$U[k]), L95 = unname(na$L95[k]))
  na$would_be[k] <- verdict_row(r, cen[ROW_NEEDS[[r]]], ep)["verdict"]
}
S$a4 <- na

# =============================================================================================
# 5B. Changed population, index or target (A4d)
# =============================================================================================
# items derived from the central draws (same PCA, different Gini population/weights/target)
pt <- \(G, gE, gI) rows_from(G, gE, gI)
S$b5  <- summ_variant("5B-5", "zero-index farmers dropped from farmer Ginis (ineqdeco)", "5B",
                      pt(e0$G_drop0, e0$gE, e0$gI), draw_rows(M, "G_drop0_"), M, rows = c("H1", "H2-pt", "H3-pt", "H2-rise", "H3-rise"))
S$b11 <- summ_variant("5B-11", "whole-sample PCA weights for the farmer Ginis", "5B",
                      pt(e0$Gwsw, e0$gE, e0$gI), draw_rows(M, "Gwsw_"), M, rows = c("H1", "H2-pt", "H3-pt", "H2-rise", "H3-rise"))
S$b16 <- summ_variant("5B-16", "household size incl knegte", "5B",
                      pt(e0$G_hhk, e0$gE_hhk, e0$gI_hhk), draw_rows(M, "G_hhk_", "gE_hhk_", "gI_hhk_"), M)
S$b17 <- summ_variant("5B-17", "unweighted Gini (household unit)", "5B",
                      pt(e0$G_unw, e0$gE_unw, e0$gI_unw), draw_rows(M, "G_unw_", "gE_unw_", "gI_unw_"), M)
S$b18 <- summ_variant("5B-18", "only farmers' slaves added", "5B",
                      pt(e0$G, e0$gE, e0$gI_fs), draw_rows(M, "G_", "gE_", "gI_fs_"), M, rows = c("H4", "H4-w"))
# 5B-19: H4-w over all 20 census years (A4b rule applied as would-be verdict)
x19 <- cen["s20"]; r19 <- Rc[, "s20"]; ep19 <- endpoints("H4-w", r19, x19)
S$b19 <- tibble(item = "5B-19", label = "H4-w slope over all 20 census years 1663-1757", block = "5B", row = "H4-w",
                quantity = "s20", estimate = x19, L = ep19["L"], U = ep19["U"], L95 = ep19["L95"], interval = "98.75% percentile",
                would_be = v_a4b(x19, ep19["L"], ep19["L95"])["verdict"], note = "")
# 5B-20: H2-rise against (a) pooled 1663-1682 farmer Gini, (b) mean of the four initial Ginis; single contrasts
c20 <- c(pool = unname(e0$G[11] - e0$G_poolinit), mean = unname(e0$G[11] - mean(e0$G[1:4])))
D20 <- cbind(pool = M[, "G_1709"] - M[, "G_poolinit"], mean = M[, "G_1709"] - rowMeans(M[, paste0("G_", INIT)]))
S$b20 <- bind_rows(lapply(names(c20), \(k) { b <- supt_band(D20[, k, drop = FALSE], c20[k], ALPHA)
  q <- pct_int(D20[, k], ALPHA)
  tibble(item = paste0("5B-20", ifelse(k == "pool", "a", "b")), label = paste("H2-rise vs", ifelse(k == "pool", "pooled 1663-1682 farmer Gini", "mean of the four initial-year Ginis")),
         block = "5B", row = "H2-rise", quantity = paste0("d_", k), estimate = c20[k], L = b$L, U = b$U, L95 = NA,
         interval = "98.75% sup-t (one contrast)",
         would_be = if (b$U < 0) "overturned" else if (b$L > 0) "confirmed" else if (c20[k] > 0) "weakened (direction holds, not significant)" else "weakened (direction not held for some year)",
         note = sprintf("98.75%% percentile [%.4f, %.4f]", q["L"], q["U"])) }))

# items that need their own data set or index: a fresh point estimate and a B = 9,999 cluster bootstrap
var_run <- function(item, label, d, items = CORE1, opts = list(), keep_all = FALSE) {
  d$key <- key_coarse(d$Van, d$Naam)
  Pv <- prep(d, items = items, key = "key")
  ev <- evaluate(Pv, opts = opts); x0 <- rows_from(ev$G, ev$gE, ev$gI)
  Mv <- run_boot(Pv, 1:B, streams, "cluster", opts = opts, label = item)
  summ_variant(item, label, "5B", x0, draw_rows(Mv), Mv)
}
hb <- build_hh(raw)                                      # equals hh (checked in 01)
S$b6  <- var_run("5B-6", "districts DS1-DS3 only", hb |> filter(DS %in% 1:3))
S$b7  <- var_run("5B-7", "Cape district (DS1) only", hb |> filter(DS == 1))
S$b8  <- var_run("5B-8", "households with any non-numeric count cell dropped", hb |> filter(!any_nonnum))
# 5B-9: 1723 same-name records merged within year (S5 rule: sum assets and slaves, max household size)
m23 <- hb |> filter(year == 1723) |> group_by(year, Van, Naam) |>
  summarise(across(c(all_of(CORE1), slaves), sum), hhsize = max(hhsize), hhsize_k = max(hhsize_k),
            farmer = any(farmer), DS = first(DS), WED = max(WED), .groups = "drop")
S$b9  <- var_run("5B-9", "1723 same-name records merged", bind_rows(hb |> filter(year != 1723), m23))
rawcols <- setdiff(names(raw), "ID")
dupl <- duplicated(raw[raw$Jaar != "1705", rawcols])
S$b10 <- var_run("5B-10", "exact duplicate rows removed", hb[!dupl, ], opts = list())
S$b10$note <- paste0(sum(dupl), " exact duplicate rows (all columns except ID) removed")
qv <- quantile(hb$WINGST[hb$farmer & hb$WINGST > 0], 0.999)
S$b12 <- var_run("5B-12", "vines winsorised at the 99.9th percentile", hb |> mutate(WINGST = pmin(WINGST, qv)))
S$b12$note <- sprintf("cap %.0f vines (99.9th pct of positive farmer counts, as S5)", qv)
h05 <- build_hh(raw, keep1705 = TRUE) |> mutate(in_gini = year != 1705)
S$b13 <- var_run("5B-13", "1705 rows included in both PCA estimations, not in the Ginis", h05)
S$b14 <- var_run("5B-14", "annual PCA weights (Fig 2 variant)", hb, opts = list(annual = TRUE))
S$b15a <- var_run("5B-15a", "Core 2 index (no vines)", hb, items = CORE2)
S$b15b <- var_run("5B-15b", "Core 3 index (no pigs)", hb, items = CORE3)

# =============================================================================================
# 5C. Diagnostics and stress tests
# =============================================================================================
# 21: single letters decoded A = 10 ... Z = 35 (hypothetical); point estimates only
hd <- build_hh(raw, decode_letters = TRUE); hd$key <- key_coarse(hd$Van, hd$Naam)
ed <- evaluate(prep(hd)); x21 <- rows_from(ed$G, ed$gE, ed$gI)
S$c21 <- summ_variant("5C-21", "stress test: single-letter cells decoded A=10..Z=35 (hypothetical)", "5C", x21,
                      note = sprintf("1723 farmer Gini %.4f (central %.4f).", ed$G[15], e0$G[15]))
# 22: H4-w by OLS over the 12 year-points, HC1 and Newey-West (1 lag)
gap <- e0$gI - e0$gE; i18 <- match(YR18, YEARS)
dd <- tibble(gap = gap[i18], x = (YR18 - 1700) / 10); fit <- lm(gap ~ x, dd)
vc <- list(HC1 = sandwich::vcovHC(fit, type = "HC1"), NW1 = sandwich::NeweyWest(fit, lag = 1, prewhite = FALSE))
S$c22 <- imap_dfr(vc, \(V, nm) { se <- sqrt(V[2, 2]); tq <- qt(1 - ALPHA / 2, 10)
  tibble(item = "5C-22", label = paste("H4-w OLS over 12 year-points,", nm), block = "5C", row = "H4-w", quantity = "s",
         estimate = coef(fit)[2], L = coef(fit)[2] - tq * se, U = coef(fit)[2] + tq * se, L95 = coef(fit)[2] - qt(0.975, 10) * se,
         interval = "98.75% t(10)", would_be = v_a4b(coef(fit)[2], coef(fit)[2] - tq * se, coef(fit)[2] - qt(0.975, 10) * se)["verdict"],
         note = sprintf("SE %.5f; different stochastic model", se)) })
# 23: published fn-14 rule on the central series (later point outside the earlier year's 95% CI);
#     CI = central-draw 95% percentile interval of G_t
ci <- t(apply(M[, paste0("G_", YEARS)], 2, \(z) pct_int(z, 0.05)))
fn14 <- tibble(year = YEARS, G = e0$G, lo = ci[, "L"], hi = ci[, "U"])
cmp <- \(a, b) { A <- fn14[fn14$year == a, ]; Bq <- fn14[fn14$year == b, ]
  tibble(item = "5C-23", label = sprintf("fn-14 rule: %d vs %d CI", a, b), block = "5C", row = NA_character_, quantity = sprintf("G%d", a),
         estimate = A$G, L = Bq$lo, U = Bq$hi, L95 = NA, interval = sprintf("%d 95%% percentile CI", b),
         would_be = NA_character_, note = ifelse(A$G > Bq$hi, "above", ifelse(A$G < Bq$lo, "below", "inside"))) }
S$c23 <- bind_rows(cmp(1709, 1663), cmp(1709, 1670), cmp(1709, 1678), cmp(1709, 1682), cmp(1738, 1709), cmp(1757, 1738), cmp(1716, 1712))
# 24: leave-one-household-out for 1663 and 1709 (pooled PCA weights held at the central values)
If <- score_shift(as.matrix(far[, CORE1]), fix_far)
loo <- bind_rows(lapply(c(1663, 1709), \(y) { k <- which(far$year == y); pc <- If[k] / far$hhsize[k]; w <- far$hhsize[k]
  G0 <- gini_w(pc, w); dG <- sapply(seq_along(k), \(j) gini_w(pc[-j], w[-j]) - G0)
  tibble(year = y, Van = far$Van[k], Naam = far$Naam[k], hhsize = w, index = If[k], dG = dG) |> arrange(desc(abs(dG))) |> mutate(rank = row_number()) }))
write_csv(loo |> filter(rank <= 10), file.path(OUT, "diag_loo_top10.csv"))
S$c24 <- loo |> group_by(year) |> summarise(maxabs = max(abs(dG)), .groups = "drop") |>
  transmute(item = "5C-24", label = sprintf("leave-one-household-out %d: max |dG|", year), block = "5C", row = NA_character_,
            quantity = sprintf("G%d", year), estimate = maxabs, L = NA, U = NA, L95 = NA, interval = "", would_be = NA_character_,
            note = "ten most influential households in diag_loo_top10.csv")
# 25: bootstrap-distribution diagnostics (central draws)
M2 <- if (is.null(BC$M2)) M else BC$M2; R2 <- draw_rows(M2)
qs <- c(0.00625, 0.025, 0.5, 0.975, 0.99375)
skew <- \(x) mean((x - mean(x))^3) / sd(x)^3
dg <- bind_rows(lapply(c("G1663", "G1709", paste0("d_", INIT), "d", "m", "s"), \(q) {
  x <- if (q %in% paste0("d_", INIT)) R2[, q] else Rc[, q]
  tibble(quantity = q, draws = length(x), central = cen[q], mean = mean(x), sd = sd(x), skewness = skew(x),
         !!!setNames(as.list(sapply(qs, \(p) q7(x, p))), paste0("q", qs * 100))) }))
write_csv(dg, file.path(OUT, "diag_boot_distribution.csv"))
n63 <- M2[, "nf_1663"]
trk <- BC$trk; TT <- M2[, paste0("trk_", seq_along(trk))]
lo <- R2[, "d_1663"] <= q7(R2[, "d_1663"], 0.025); hi <- R2[, "d_1663"] >= q7(R2[, "d_1663"], 0.975)
ovr <- bind_rows(lapply(list(lower = lo, upper = hi), \(k) tibble(farmer = seq_along(trk), Van = hh$Van[trk], Naam = hh$Naam[trk],
  index = If[match(hh$hid[trk], far$hid)], ratio = colMeans(TT[k, , drop = FALSE]) / colMeans(TT))), .id = "tail") |>
  group_by(tail) |> arrange(desc(ratio), .by_group = TRUE) |> slice_head(n = 10) |> ungroup()
write_csv(ovr, file.path(OUT, "diag_1663_tail_overrep.csv"))
S$c25 <- tibble(item = "5C-25", label = c("replicate 1663 farmer count: minimum", "share of draws with < 20 farmers in 1663"),
                block = "5C", row = NA_character_, quantity = "nf_1663", estimate = c(min(n63), mean(n63 < 20)),
                L = NA, U = NA, L95 = NA, interval = "", would_be = NA_character_,
                note = "quantiles/skewness in diag_boot_distribution.csv; tail over-representation in diag_1663_tail_overrep.csv")
pdf(file.path(OUT, "diag_boot_hist.pdf"), 9, 6); par(mfrow = c(2, 4))
for (q in c("G1663", "G1709", paste0("d_", INIT), "d", "m")) { x <- if (q %in% paste0("d_", INIT)) R2[, q] else Rc[, q]; hist(x, 60, main = q, xlab = ""); abline(v = cen[q], col = "#5C2346", lwd = 2) }
dev.off()
# 26: gap identity g_t = p_t (1 - G^S_t)
gid <- tibble(year = YEARS, gap = gap, identity = e0$p_sl * (1 - e0$gE), diff = gap - identity)
write_csv(gid, file.path(OUT, "diag_gap_identity.csv"))
S$c26 <- tibble(item = "5C-26", label = "gap identity g_t = p_t(1 - G^S_t): max |discrepancy|", block = "5C", row = "H4-ES",
                quantity = "g_t", estimate = max(abs(gid$diff)), L = NA, U = NA, L95 = NA, interval = "", would_be = NA_character_,
                note = sprintf("correlation %.6f", cor(gid$gap, gid$identity)))

sens <- bind_rows(S) |> mutate(across(c(estimate, L, U, L95), as.numeric))
write_csv(sens, file.path(OUT, "sensitivities.csv"))
print(sens |> select(item, row, quantity, estimate, L, U, would_be), n = 200, width = 200)
