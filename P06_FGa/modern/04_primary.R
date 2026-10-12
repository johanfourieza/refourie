# 04: Central scenario (card §4.2), intervals (§4.3), verdicts (§8). Writes output/primary.csv,
# output/verdict.csv (range columns are added by 05_ranges.R) and output/level_checks.csv.
source("P06_FGa/modern/00_helpers.R")
fg <- load_raw(); cmap <- coverage_map(fg); P <- load_prices()
d <- make_d(fg, cmap, P)
e <- enum_stats(d)
vb <- readRDS(SCR("va_boot.rds")); vp <- vb$point; R <- vb$reps
covs <- read_csv(file.path(OUT, "coverage_summary.csv"), show_col_types = FALSE)
cs <- function(k) covs$value[covs$item == k]
va_farmers <- cs("va_covered_farmers_H4"); floor_fail <- va_farmers < 200

PUB <- list(H1 = 135.1 / 76, H2 = 190.8 / 55.8, H3 = 33 / 5)
plaus <- function(cl, est) if (cl %in% names(PUB)) est > 1.5 * log(PUB[[cl]]) else NA

rows <- list()
add <- function(claim, pair, estimand, A, B, est, lo, hi, itype, band, nA, nB, nonfin = 0, va = FALSE) {
  fail <- !is.finite(est) || (va && (floor_fail || nonfin > 0.01 * B_BOOT))
  v <- verdict_single(lo, hi, band, fail)
  rows[[length(rows) + 1]] <<- tibble(claim, pair, estimand, A_value = A, B_value = B, estimate = est,
    ci_lo = lo, ci_hi = hi, interval_type = itype, band = band, n_A = nA, n_B = nB, nonfinite_reps = nonfin,
    verdict = v$verdict, rule = v$rule, negligible_flag = negligible(lo, hi, band, v$rule),
    plausibility_flag = plaus(claim, est))
}
ENUM <- "degenerate (enumerations: interval = point)"
BONF <- "Bonferroni 99% Rao-Wu percentile (m = 5)"

# H1, H2: enumerated ratios on the log scale
l1 <- log(e[["H1_cape"]] / e[["H1_us"]])
add("H1", "Cape/US(Me+Ma)", "ln R1 income", e[["H1_cape"]], e[["H1_us"]], l1, l1, l1, ENUM, LN_SIM, e[["H1_n_cape"]], e[["H1_n_us"]])
l2 <- log(e[["H2_cape"]] / e[["H2_us"]])
add("H2", "Cape/US(Me+Ma)", "ln R2 crops+wine+brandy / US crops", e[["H2_cape"]], e[["H2_us"]], l2, l2, l2, ENUM, LN_SIM, NA, NA)
# H3: design-weighted US mean; Virginia component from the Rao-Wu replicates
l3 <- h3_lnR(e, vp[["VA_cat"]], vp[["VA_w"]])
l3r <- h3_lnR(e, R[, "VA_cat"], R[, "VA_w"])
ci <- q99(l3r[is.finite(l3r)])
us3 <- (e[["H3_mm_sum"]] + vp[["VA_cat"]]) / (e[["H3_mm_n"]] + vp[["VA_w"]])
add("H3", "Cape/US(Me+Ma+VA, weighted)", "ln R3 cattle per farming household", e[["H3_cape"]], us3, l3, ci[1], ci[2], BONF,
    LN_SIM, e[["H3_n_cape"]], e[["H3_mm_n"]] + va_farmers, sum(!is.finite(l3r)), va = TRUE)
# H4 and H4w: G(VA) - G(d)
for (k in c("Stb", "GR", "Swe", "Tul")) {
  dr <- R[, "G4_VA"] - e[[paste0("G4_", k)]]
  ci <- q99(dr[is.finite(dr)]); est <- vp[["G4_VA"]] - e[[paste0("G4_", k)]]
  for (cl in if (k == "Stb") c("H4", "H4w") else "H4w")
    add(cl, paste0("VA-", k), "Gini enslaved difference", vp[["G4_VA"]], e[[paste0("G4_", k)]], est, ci[1], ci[2], BONF,
        G_SIM, va_farmers, e[[paste0("G4n_", k)]], sum(!is.finite(dr)), va = TRUE)
}
# H5: G_crops(d) - G_crops(k), enumerated
for (k in c("GR", "Stb", "Swe", "Tul")) for (u in c("Maine", "Mass")) {
  est <- e[[paste0("G5_", k)]] - e[[paste0("G5_", u)]]
  add("H5", paste0(k, "-", u), "Gini crop value difference", e[[paste0("G5_", k)]], e[[paste0("G5_", u)]], est, est, est, ENUM,
      G_SIM, e[[paste0("G5n_", k)]], e[[paste0("G5n_", u)]])
}
prim <- bind_rows(rows)
write_csv(prim, file.path(OUT, "primary.csv"))

# Claim-level verdicts
fmt <- function(x) formatC(x, digits = 4, format = "f")
vrow <- function(cl) {
  p <- prim |> filter(claim == cl)
  if (cl %in% c("H4w", "H5")) {
    v <- verdict_universal(p$verdict)
    worst <- p[which.min(p$estimate), ]
    cex <- paste(p$pair[grepl("^overturned", p$verdict)], collapse = "; ")
    tibble(claim = cl, estimate = paste0(nrow(p), " pairs; min ", worst$pair, " = ", fmt(worst$estimate)),
           interval = paste0("[", fmt(worst$ci_lo), ", ", fmt(worst$ci_hi), "] (", worst$interval_type, ")"),
           test_p = "none (interval-only decisions, card §4.3)",
           threshold_or_band = "every pair > 0 (conjunction, §8); similarity band ±0.03",
           verdict = v$verdict, rule = paste0("universal ", v$rule),
           counterexample_pairs = cex, negligible_flag = any(p$negligible_flag), plausibility_flag = NA)
  } else {
    band <- if (cl %in% c("H1", "H2", "H3")) "ln R > 0; credible null if interval in ln[0.80,1.25]" else "Δ > 0; credible null if interval in ±0.03"
    tibble(claim = cl, estimate = fmt(p$estimate), interval = paste0("[", fmt(p$ci_lo), ", ", fmt(p$ci_hi), "] (", p$interval_type, ")"),
           test_p = "none (interval-only decisions, card §4.3)", threshold_or_band = band,
           verdict = p$verdict, rule = paste0("single ", p$rule), counterexample_pairs = "",
           negligible_flag = p$negligible_flag, plausibility_flag = p$plausibility_flag)
  }
}
verd <- bind_rows(lapply(c("H1", "H2", "H3", "H4", "H4w", "H5"), vrow)) |>
  mutate(va_coverage_share = ifelse(claim %in% c("H3", "H4", "H4w"), cs("va_coverage_share_H4"), NA),
         scope = "recorded output only (tax-census records); Virginia = cattle-owning households")
write_csv(verd, file.path(OUT, "verdict.csv"))

# Level checks (§1; reported only)
lv <- tribble(~claim_id, ~published, ~new, ~type,
  "tx_p16_income_cape", 135.1, e[["H1_cape"]], "level",
  "tx_p16_income_us", 76, e[["H1_us"]], "level",
  "tx_p16_cropwine_cape", 190.8, e[["H2_cape"]], "level",
  "tx_p13_cattle_cape", 33, e[["H3_cape"]], "level",
  "tx_p13_cattle_us", 5, us3, "level",
  "T1_Virginia_enslaved", 0.74, vp[["G4_VA"]], "gini",
  "T1_Stellenbosch_enslaved", 0.58, e[["G4_Stb"]], "gini",
  "T1_GraaffReinet_crops", 0.95, e[["G5_GR"]], "gini") |>
  mutate(band_lo = ifelse(type == "gini", published - 0.03, published * 0.9),
         band_hi = ifelse(type == "gini", published + 0.03, published * 1.1),
         within_band = new >= band_lo & new <= band_hi)
write_csv(lv, file.path(OUT, "level_checks.csv"))
saveRDS(list(e = e, d_central = NULL), SCR("primary_enum.rds"))
print(as.data.frame(prim |> select(claim, pair, A_value, B_value, estimate, ci_lo, ci_hi, verdict, negligible_flag, plausibility_flag)), digits = 4)
print(as.data.frame(verd |> select(claim, estimate, interval, verdict, rule, counterexample_pairs)))
print(as.data.frame(lv), digits = 4)
