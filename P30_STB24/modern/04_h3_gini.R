# P30_STB24 S6 step 4: H3, "Gini coefficients ... ranging between 0.4 and 1 across all assets for most of the period".
# Within-year bootstrap, 95% sup-t band over all asset-years, bounds [s_lo, s_hi] per asset (card s3, s4, s8).
# Also: H3-lo-x, s5B item 6, S-b; saves the draws for s5B item 1 of H4 (05).
source("P30_STB24/modern/00_common.R")
t0 <- Sys.time()
d <- readRDS(SCR("central.rds"))
Y <- prep_years(d)
G0 <- year_ginis(d)
rec <- year_means(d)                                          # recorded = some non-missing aggregate value
ay <- rbindlist(lapply(ASSETS, function(a) data.table(asset = a, year = G0$year, G = G0[[a]], recorded = is.finite(rec[[a]]))))
zero_sum <- ay[recorded & !is.finite(G)]                      # recorded, sum = 0: Gini undefined, excluded from T_a
fwrite(zero_sum, file.path(OUT, "h3_zero_sum_assetyears.csv"))
ay <- ay[recorded & is.finite(G)]
ay[, key := as.character(year)]
setorder(ay, asset, year)
K <- nrow(ay); cat("asset-years in T:", K, "\n"); print(ay[, .N, by = asset])
ay_a <- ay$asset; ay_k <- ay$key

f_h3 <- function(b) {
  cnts <- lapply(Y, function(y) rcount(y$n))
  vapply(seq_len(K), function(i) { y <- Y[[ay_k[i]]]; a <- ay_a[i]; gini_w(y$xs[[a]], cnts[[ay_k[i]]][y$ord[[a]]]) }, 0)
}
ex <- c("Y", "K", "ay_a", "ay_k")
B0 <- as.integer(Sys.getenv("B0", "19999"))
draw <- function(B, from = 1) do.call(rbind, run_boot(B, f_h3, export = ex, from = from))
Gs <- draw(B0)

suptband <- function(Gs) {
  undefined <- colSums(!is.finite(Gs)) > 0
  se <- apply(Gs, 2, sd)
  inR <- !undefined; use <- inR & se > 0
  z <- abs(sweep(Gs[, use, drop = FALSE], 2, ay$G[use])) / rep(se[use], each = nrow(Gs))
  cc <- quantile(apply(z, 1, max), 0.95, type = 7, names = FALSE)
  L <- ifelse(inR, ay$G - cc * ifelse(use, se, 0), NA); U <- ifelse(inR, ay$G + cc * ifelse(use, se, 0), NA)
  list(c = cc, se = se, L = L, U = U, undefined = undefined, se0 = inR & se == 0)
}
band <- suptband(Gs)
mc_check <- function(Gs) {
  bt <- split(seq_len(nrow(Gs)), cut(seq_len(nrow(Gs)), 10, labels = FALSE))
  bb <- lapply(bt, function(ii) suptband(Gs[ii, , drop = FALSE]))
  list(c = sd(sapply(bb, `[[`, "c")) / sqrt(10),
       L = apply(sapply(bb, `[[`, "L"), 1, sd) / sqrt(10), U = apply(sapply(bb, `[[`, "U"), 1, sd) / sqrt(10))
}
mc <- mc_check(Gs)
near <- function(band, mc) any(abs(band$L - 0.4) < 2 * mc$L | abs(band$U - 0.4) < 2 * mc$U, na.rm = TRUE)
mc_escalated <- FALSE
if (near(band, mc)) {
  mc_escalated <- TRUE
  Gs <- rbind(Gs, draw(49999, from = 20000)); band <- suptband(Gs); mc <- mc_check(Gs)
}
ay[, `:=`(se = band$se, L = band$L, U = band$U, unresolved_undefined = band$undefined, se0 = band$se0,
          mcse_L = mc$L, mcse_U = mc$U)]
ay[, cls := fifelse(unresolved_undefined, "unresolved", fifelse(L >= 0.4, "above", fifelse(U < 0.4, "below", "unresolved")))]
per <- ay[, .(T_a = .N, n_above = sum(cls == "above"), n_below = sum(cls == "below"), n_unresolved = sum(cls == "unresolved"),
              n_undefined_draws = sum(unresolved_undefined), n_se0 = sum(se0), s_point = mean(G >= 0.4),
              G_min = min(G), G_p10 = quantile(G, .1, names = FALSE), L_min = min(L, na.rm = TRUE),
              first_year = min(year), last_year = max(year)), by = asset]
per[, `:=`(s_lo = n_above / T_a, s_hi = (T_a - n_below) / T_a)]
per[, `:=`(c_supt = band$c, mcse_c = mc$c, size_R = sum(!band$undefined), B = nrow(Gs), mc_escalated = mc_escalated,
           mc_fragile = mc_escalated & near(band, mc))]
print(per)
fwrite(per, file.path(OUT, "h3_primary.csv"))
fwrite(ay, file.path(OUT, "h3_assetyears.csv"))
# positive holders per asset-year (s4 reporting)
pos <- rbindlist(lapply(ASSETS, function(a) d[!is.na(get(a)), .(asset = a, rows = .N, positive = sum(get(a) > 0)), by = year]))
fwrite(pos, file.path(OUT, "h3_positive_holders.csv"))

# H3-lo-x (reported)
lox <- data.table(stat = c("min", "p10"), value = c(min(ay$G), quantile(ay$G, .1, type = 7, names = FALSE)))
lox[, label := fifelse(value < 0.37, "below", fifelse(value > 0.43, "above", "inside"))]
print(lox); fwrite(lox, file.path(OUT, "h3_lox.csv"))

# s5B item 6: pointwise percentile bounds at the Bonferroni level over |R|
nR <- sum(!band$undefined); a6 <- 0.05 / nR
pb <- t(apply(Gs, 2, function(x) if (any(!is.finite(x))) c(NA, NA) else quantile(x, c(a6 / 2, 1 - a6 / 2), names = FALSE)))
ay[, `:=`(pL = pb[, 1], pU = pb[, 2])]
s6 <- ay[, .(T_a = .N, s_lo_pct = sum(pL >= 0.4, na.rm = TRUE) / .N, s_hi_pct = (.N - sum(pU < 0.4, na.rm = TRUE)) / .N,
             s_finite_pop = mean(G >= 0.4)), by = asset]
fwrite(s6, file.path(OUT, "h3_diag_percentile_bounds.csv"))

# S-b: crops minus livestock, year-paired, over years with all five recorded (H3 draws, 95% percentile)
five <- c("wheat", "barley", "horses", "sheep", "cattle")
yy <- Reduce(intersect, lapply(five, function(a) ay[asset == a, year]))
col_of <- function(a) match(paste(a, yy), paste(ay$asset, ay$year))
sb_fun <- function(M) rowMeans((M[, col_of("wheat"), drop = FALSE] + M[, col_of("barley"), drop = FALSE]) / 2 -
                               (M[, col_of("horses"), drop = FALSE] + M[, col_of("sheep"), drop = FALSE] + M[, col_of("cattle"), drop = FALSE]) / 3)
sb0 <- sb_fun(matrix(ay$G, nrow = 1)); sbs <- sb_fun(Gs)
sb <- data.table(secondary = "S-b", estimate = sb0, lo = quantile(sbs, .025, names = FALSE, na.rm = TRUE),
                 hi = quantile(sbs, .975, names = FALSE, na.rm = TRUE), years = length(yy))
sb[, a8 := fifelse(lo > 0, "crops > livestock (CI excludes 0)", fifelse(estimate > 0, "point > 0, CI includes 0", "not >"))]
print(sb); fwrite(sb, file.path(OUT, "secondary_Sb.csv"))

wcols <- which(ay$asset == "wine")
saveRDS(list(years = ay$year[wcols], G = ay$G[wcols], draws = Gs[, wcols]), SCR("h3_wine_draws.rds"))
cat("runtime:", format(Sys.time() - t0), "\n")
