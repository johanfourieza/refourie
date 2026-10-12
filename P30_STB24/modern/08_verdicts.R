# P30_STB24 S6 step 8: apply the card's s8 verdict tables mechanically; write verdict.csv, primary.csv, sensitivities.csv.
source("P30_STB24/modern/00_common.R")
h1 <- readRDS(SCR("h1.rds"))
p2 <- fread(file.path(OUT, "h2_primary.csv")); p3 <- fread(file.path(OUT, "h3_primary.csv"))
p4 <- fread(file.path(OUT, "h4_primary.csv")); p5 <- fread(file.path(OUT, "h5_primary.csv"))
f3 <- function(x) formatC(x, format = "f", digits = 3)
fp <- function(p, B = 19999) ifelse(p == 0, paste0("<", formatC(1 / B, format = "g", digits = 2)), formatC(p, format = "g", digits = 3))

# percentile-t p-value for theta = 0 (two-sided, equal-tailed), from the primary draws
pval <- function(R, i, k, th, se) { ok <- is.finite(R[, i]) & is.finite(R[, k + i]) & R[, k + i] > 0
  ts <- (R[ok, i] - th) / R[ok, k + i]; t0 <- th / se; min(1, 2 * min(mean(ts >= t0), mean(ts <= t0))) }
R4 <- readRDS(SCR("h4_boot_two.rds")); R5 <- readRDS(SCR("h5_boot_two.rds"))
p4[, p := mapply(function(i) pval(R4, i, 2, estimate[i], se[i]), seq_len(.N))]
p5[, p := mapply(function(i) pval(R5, i, nrow(p5), estimate[i], se[i]), seq_len(.N))]

# ---- H1 ----
N <- h1$N
h1v <- if (!h1$check3) c("not-testable", 0) else if (N >= 128068 && N <= 156526) c("confirmed", 1) else if (N < 128068) c("qualified (count below the stated value)", 2) else c("qualified (count above the stated value)", 3)

# ---- H2: step 2 with NT bracketing ----
h2_step2 <- function(cat) { n <- function(x) sum(cat == x)
  if (n("C") >= 4) return(c("confirmed", 1)); if (n("O") >= 3) return(c("overturned", 2))
  if (n("C") + n("D") + n("Q") >= 4) { lab <- c(if (n("D") > 0) "larger decline than stated", if (n("Q") > 0) "imprecise")
    return(c(paste0("qualified", if (length(lab)) paste0(" (", paste(lab, collapse = "; "), ")") else ""), 3)) }
  c("weakened", 4) }
cat2 <- p2$category
if (any(cat2 == "NT")) { a <- h2_step2(replace(cat2, cat2 == "NT", "C")); b <- h2_step2(replace(cat2, cat2 == "NT", "O"))
  h2v <- if (identical(a, b)) a else c("not-testable", "NT bracket") } else h2v <- h2_step2(cat2)

# ---- H3 ----
h3v <- if (any(p3$s_hi <= 0.5 & p3$T_a > 0)) c("overturned", 1) else if (length(setdiff(ASSETS, p3$asset)) > 0 || any(p3$T_a == 0)) c("not-testable", 2) else
  if (all(p3$s_lo > 0.5)) c("confirmed", 3) else if (all(p3$s_point > 0.5)) c("qualified (inference-fragile)", 4) else c("weakened", 5)

# ---- comparative rows ----
cmp_verdict <- function(cats, h5 = FALSE) {
  if (any(cats == "opposite")) return(if (h5) c("weakened (credible reversal; A4b)", 1) else c("overturned (reversed)", 1))
  if (any(cats == "undefined")) return(c("not-testable", 2))
  if (all(cats == "claimed")) return(c("confirmed", 3))
  if (all(cats %in% c("claimed", "includes0_pt_claimed"))) return(c("qualified (inference-fragile)", 4))
  c("weakened", 5) }
h4v <- cmp_verdict(p4$category)
h5a <- p5[row == "H5a"]; h5b <- p5[row == "H5b"]; h5c <- p5[row == "H5c"]
h5av <- cmp_verdict(h5a$category, TRUE); h5bv <- cmp_verdict(h5b$category, TRUE); h5cv <- cmp_verdict(h5c$category, TRUE)

rng <- function(x) paste0(f3(min(x)), " to ", f3(max(x)))
verdict <- rbindlist(list(
  data.table(claim = "H1", estimate = as.character(N), interval = "population count (no inference)", test_p = NA_character_,
             threshold_or_band = "[128068, 156526] (142,297 +/- 10%)", verdict = h1v[1], rule = h1v[2],
             finite_pop_point = if (N >= 128068 && N <= 156526) "inside band" else "outside band"),
  data.table(claim = "H2", estimate = paste0(p2$asset, " ", f3(p2$theta), collapse = "; "),
             interval = paste0(p2$asset, " [", f3(p2$lo), ", ", f3(p2$hi), "]", collapse = "; "), test_p = NA_character_,
             threshold_or_band = "ln r_a in [ln 0.80, ln 1.25] = [-0.223, 0.223]; >= 4 of 6 assets C (99.167% percentile-t)",
             verdict = h2v[1], rule = paste0("step2 #", h2v[2], "; categories ", paste0(p2$asset, "=", p2$category, collapse = ",")),
             finite_pop_point = paste0(sum(p2$fp_point_in_band), " of 6 point ratios in band")),
  data.table(claim = "H3", estimate = paste0(p3$asset, " s=", f3(p3$s_point), collapse = "; "),
             interval = paste0(p3$asset, " [", f3(p3$s_lo), ", ", f3(p3$s_hi), "]", collapse = "; "), test_p = NA_character_,
             threshold_or_band = "G >= 0.4; s_lo > 0.5 for every asset (95% sup-t band)", verdict = h3v[1], rule = h3v[2],
             finite_pop_point = paste0("min point s_a = ", f3(min(p3$s_point)))),
  data.table(claim = "H4", estimate = paste0(p4$contrast, " ", f3(p4$estimate), collapse = "; "),
             interval = paste0(p4$contrast, " [", f3(p4$lo), ", ", f3(p4$hi), "]", collapse = "; "),
             test_p = paste0("max ", fp(max(p4$p))),
             threshold_or_band = "both CIs > 0 (97.5% percentile-t)", verdict = h4v[1], rule = h4v[2],
             finite_pop_point = paste0(sum(p4$fp_point_claimed), " of 2 points > 0")),
  data.table(claim = "H5a", estimate = paste0("16 contrasts, range ", rng(h5a$estimate)),
             interval = paste0("lower ends ", rng(h5a$lo)), test_p = paste0("max ", fp(max(h5a$p))),
             threshold_or_band = "all 16 CIs > 0 (99.737% percentile-t)", verdict = h5av[1], rule = h5av[2],
             finite_pop_point = paste0(sum(h5a$fp_point_claimed), " of 16 points on claimed side")),
  data.table(claim = "H5b", estimate = paste0(h5b$contrast, " ", f3(h5b$estimate), collapse = "; "),
             interval = paste0(h5b$contrast, " [", f3(h5b$lo), ", ", f3(h5b$hi), "]", collapse = "; "),
             test_p = paste0(h5b$contrast, " ", fp(h5b$p), collapse = "; "),
             threshold_or_band = "dZ^M CI > 0 and dZ^W CI < 0 (99.737% percentile-t)", verdict = h5bv[1], rule = h5bv[2],
             finite_pop_point = paste0(sum(h5b$fp_point_claimed), " of 2 points on claimed side")),
  data.table(claim = "H5c", estimate = f3(h5c$estimate), interval = paste0("[", f3(h5c$lo), ", ", f3(h5c$hi), "]"),
             test_p = fp(h5c$p), threshold_or_band = "dC CI > 0 (99.737% percentile-t)",
             verdict = h5cv[1], rule = h5cv[2], finite_pop_point = if (h5c$fp_point_claimed) "point > 0" else "point <= 0")))
print(verdict[, .(claim, verdict, rule)])
fwrite(verdict, file.path(OUT, "verdict.csv"))

# ---- primary.csv: every primary quantity, stacked ----
prim <- rbindlist(list(
  data.table(claim = "H1", quantity = "N", estimate = N, lo = NA, hi = NA, se = NA, category = h1v[1], nfail = NA, B = NA),
  p2[, .(claim = "H2", quantity = paste0("r_", asset), estimate = theta, lo, hi, se, category, nfail, B)],
  p3[, .(claim = "H3", quantity = paste0("s_", asset), estimate = s_point, lo = s_lo, hi = s_hi, se = NA,
         category = paste0("above=", n_above, " below=", n_below, " unresolved=", n_unresolved, " of ", T_a), nfail = n_undefined_draws, B)],
  p4[, .(claim = "H4", quantity = contrast, estimate, lo, hi, se, category, nfail, B)],
  p5[, .(claim = row, quantity = contrast, estimate, lo, hi, se, category, nfail, B)]), fill = TRUE)
fwrite(prim, file.path(OUT, "primary.csv"))

# ---- sensitivities.csv: every s5 item, stacked long ----
rd <- function(f) fread(file.path(OUT, f))
long <- function(dt, item, idcols) { x <- melt(dt, id.vars = idcols, variable.factor = FALSE, value.name = "value")
  x[, value := as.character(value)]; x[, .(item = item, id = do.call(paste, c(.SD, sep = " | ")), quantity = variable, value), .SDcols = idcols] }
sens <- rbindlist(list(
  rd("supp_5A_5C_points.csv")[, .(item, id = paste(scenario, label, sep = " | "), quantity, value = as.character(value))],
  long(rd("h2_diag_inference.csv"), "5B1/5B3/5B4 H2", "asset"),
  long(rd("h4_diag_inference.csv"), "5B1/5B3/5B4 H4", "contrast"),
  long(rd("h5_diag_inference.csv"), "5B3/5B4 H5", "contrast"),
  long(rd("supp_5B2_welch.csv"), "5B2 Welch", "asset"),
  long(rd("supp_5B5_leave_one_out.csv"), "5B5 leave-one-census-out", c("claim", "contrast")),
  long(rd("h3_diag_percentile_bounds.csv"), "5B6 H3 Bonferroni percentile bounds", "asset"),
  long(rd("supp_5C5_loglinear_trend.csv")[, !c("item", "label")], "5C5 log-linear trend", "asset"),
  rd("supp_5C13_15_h5.csv")[, .(item, id = paste(scenario, label, sep = " | "), quantity, value = as.character(value))],
  long(rd("supp_5D_summary.csv")[, id := "K5"], "5D K5 evidence", "id"),
  long(rd("h1_count.csv")[, id := "H1"], "5E H1 diagnostics", c("id", "quantity")),
  long(rd("secondary_Sa.csv"), "S-a Gini slopes", c("asset", "scenario")),
  long(rd("secondary_Sb.csv"), "S-b crops vs livestock", "secondary"),
  long(rd("secondary_Sd.csv"), "S-d share >= 2 women", "row"),
  long(rd("h2_anchor.csv"), "H2-anchor", "diag"),
  long(rd("h3_lox.csv"), "H3-lo-x", "stat")), fill = TRUE)
fwrite(sens, file.path(OUT, "sensitivities.csv"))
writeLines(capture.output(sessionInfo()), file.path(MOD, "sessionInfo.txt"))
