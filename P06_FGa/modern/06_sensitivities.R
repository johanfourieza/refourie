# 06: Card §5 admissible sensitivities 1-15 and diagnostics D1-D6 (reported; never verdict-determining).
# Writes output/sensitivities.csv. The "condition" column applies the §8 single-contrast table to each
# row descriptively; it does not modify any verdict.
source("P06_FGa/modern/00_helpers.R")
library(parallel)
fg <- load_raw(); cmap <- coverage_map(fg); P <- load_prices()
vb <- readRDS(SCR("va_boot.rds")); vp <- vb$point; R <- vb$reps
dc <- make_d(fg, cmap, P); ec <- enum_stats(dc)

PAIRS4 <- c("Stb", "GR", "Swe", "Tul")
PAIRS5 <- as.vector(outer(c("GR", "Stb", "Swe", "Tul"), c("Maine", "Mass"), paste, sep = "-"))
# All primary contrasts from enumerated stats e and Virginia stats v (vector or replicate matrix).
contrasts <- function(e, v, weighted = TRUE, g4col = "G4_VA", catcol = "VA_cat", wcol = "VA_w") {
  v <- if (is.matrix(v)) v else t(as.matrix(v))
  out <- cbind(H1 = rep(log(e[["H1_cape"]] / e[["H1_us"]]), nrow(v)), H2 = log(e[["H2_cape"]] / e[["H2_us"]]),
               H3 = h3_lnR(e, v[, catcol], v[, wcol], weighted))
  for (k in PAIRS4) out <- cbind(out, v[, g4col] - e[[paste0("G4_", k)]])
  for (p in PAIRS5) { s <- strsplit(p, "-")[[1]]; out <- cbind(out, e[[paste0("G5_", s[1])]] - e[[paste0("G5_", s[2])]]) }
  colnames(out) <- c("H1", "H2", "H3", paste0("H4w:VA-", PAIRS4), paste0("H5:", PAIRS5))
  out
}
CL <- function(nm) ifelse(nm == "H4w:VA-Stb", "H4/H4w", sub(":.*", "", nm))
PR <- function(nm) ifelse(grepl(":", nm), sub(".*:", "", nm), ifelse(nm == "H3", "Cape/US(Me+Ma+VA)", "Cape/US(Me+Ma)"))
BAND <- function(nm) ifelse(nm %in% c("H1", "H2", "H3"), LN_SIM, G_SIM)
VAC <- function(nm) nm == "H3" | grepl("VA-", nm)

rows <- list()
emit <- function(id, variant, e, keep, v = vp, reps = R, interval = TRUE, note = "", ...) {
  pt <- contrasts(e, v, ...)[1, ]
  rp <- if (interval && !is.null(reps)) contrasts(e, reps, ...) else NULL
  for (nm in intersect(keep, names(pt))) {
    est <- pt[[nm]]
    if (VAC(nm) && !is.null(rp)) { x <- rp[, nm]; ci <- q99(x[is.finite(x)]); it <- "Bonferroni 99% Rao-Wu (VA design)" }
    else if (VAC(nm)) { ci <- c(NA, NA); it <- "point only" }
    else { ci <- c(est, est); it <- "degenerate (enumerations)" }
    cond <- if (is.finite(est) && all(is.finite(ci))) verdict_single(ci[1], ci[2], BAND(nm))$verdict else if (is.finite(est)) paste0("point ", ifelse(est > 0, "> 0", "<= 0")) else "not-testable"
    rows[[length(rows) + 1]] <<- tibble(id = id, variant = variant, claim = CL(nm), pair = PR(nm), estimate = est,
      ci_lo = ci[1], ci_hi = ci[2], interval_type = it, condition = cond, note = note)
  }
}
ALL <- colnames(contrasts(ec, vp))
H5S <- grep("^H5", ALL, value = TRUE); H4S <- grep("^H4w", ALL, value = TRUE)
emit("central", "central scenario (reference)", ec, ALL)

# 5.1 tornado (one V-item at a time)
auc <- P$auctions
WINE <- c(auction1 = auc$Wine[auc$Auction == "Auction1"] / XRATE, auction3 = auc$Wine[auc$Auction == "Auction3"] / XRATE)
emit("5.1", "V1 = Final2 (early auctions)", enum_stats(make_d(fg, cmap, P, pset = "Final2")), "H1")
for (r in c(0.03, 0.10)) emit("5.1", paste("V2 r =", r), enum_stats(make_d(fg, cmap, P, r = r)), "H1")
for (v3 in c("B", "C")) emit("5.1", paste("V3 =", v3), enum_stats(make_d(fg, cmap, P, v3 = v3)), c("H1", "H2", H5S))
for (w in names(WINE)) emit("5.1", paste("V4 wine =", w), enum_stats(make_d(fg, cmap, P, wine = WINE[[w]])), "H2")
# 5.2 Wright decadal US grain prices
emit("5.2", "US grain prices: Wright decadal (Final fills empty cells)", enum_stats(make_d(fg, cmap, P, us_grain = "Wright")), c("H1", "H2", H5S))
# 5.3 single Cape auctions as livestock price set
for (a in paste0("Auction", 1:4)) {
  row <- auc[auc$Auction == a, ]; fin <- P$Final["Cape Colony", ]
  lv <- c(Horses = row$Horses, Cattle = row$Cattle, Sheep = row$Sheep) / XRATE
  fill <- c(Horses = fin$PHorses, Cattle = fin$PCattle, Sheep = fin$PSheep); lv[is.na(lv)] <- fill[is.na(lv)]
  emit("5.3", paste("Cape livestock prices:", a), enum_stats(make_d(fg, cmap, P, cape_live = lv)), "H1")
}
# 5.4 Rothenberg US cattle price
emit("5.4", "US cattle $15.29 (Rothenberg)", enum_stats(make_d(fg, cmap, P, us_cattle = 15.29)), "H1")
# 5.5 Cape cattle and sheep x 2; break-evens
emit("5.5", "Cape cattle and sheep x 2 (probate-opgaaf gap)", enum_stats(make_d(fg, cmap, P, cape_mult = 2)), c("H1", "H3"))
rows[[length(rows) + 1]] <- tibble(id = "5.5", variant = "break-even under-recording multiplier on US recorded output (R1 = 1)", claim = "H1",
  pair = "Cape/US(Me+Ma)", estimate = ec[["H1_cape"]] / ec[["H1_us"]], ci_lo = NA, ci_hi = NA, interval_type = "threshold", condition = "threshold", note = "multiplier m* = Cape mean / US mean")
rows[[length(rows) + 1]] <- tibble(id = "5.5", variant = "break-even omitted US output, $ per farming household (R1 = 1)", claim = "H1",
  pair = "Cape/US(Me+Ma)", estimate = ec[["H1_cape"]] - ec[["H1_us"]], ci_lo = NA, ci_hi = NA, interval_type = "threshold", condition = "threshold", note = "dollars")
# 5.6 income incl. wine and brandy; incl. horses
emit("5.6", "income incl. wine and brandy", enum_stats(dc, income_extra = c("VW", "VB")), "H1")
emit("5.6", "income incl. horses", enum_stats(dc, income_extra = "VH"), "H1")
# 5.7 eligibility
emit("5.7", "grain eligibility > 0 (code rule, wine excluded)", enum_stats(make_d(fg, cmap, P, rule = "gt0")), ALL)
emit("5.7", "Cape threshold kappa = 3.0 (0.3333 mud)", enum_stats(make_d(fg, cmap, P, kap = 3.0)), ALL)
# 5.8 H3 unweighted (published pooling)
emit("5.8", "H3 unweighted pooling", ec, "H3", weighted = FALSE)
# 5.9 like-for-like: Cape restricted to cattle-owning households
emit("5.9", "Cape restricted to cattle owners", enum_stats(dc, cattle_only = TRUE), c("H3", H4S))
# 5.10 owners-only Ginis; pooled-country; district-mean (different estimands)
eo <- enum_stats(dc, gini_mode = "owners")
emit("5.10", "owners-only Ginis (Fig 8 definition; H5: crop value > 0)", eo, c(H4S, H5S), g4col = "G4own_VA")
pc <- function(id, var, est, rp, band, cl, pr) {
  ci <- if (is.null(rp)) c(est, est) else q99(rp[is.finite(rp)])
  rows[[length(rows) + 1]] <<- tibble(id = id, variant = var, claim = cl, pair = pr, estimate = est, ci_lo = ci[1], ci_hi = ci[2],
    interval_type = if (is.null(rp)) "degenerate (enumerations)" else "Bonferroni 99% Rao-Wu (VA design)",
    condition = verdict_single(ci[1], ci[2], band)$verdict, note = "different estimand")
}
pc("5.10", "pooled-country Gini enslaved: VA - Cape pooled", vp[["G4_VA"]] - ec[["G4_capepooled"]], R[, "G4_VA"] - ec[["G4_capepooled"]], G_SIM, "H4/H4w", "VA-Cape pooled")
pc("5.10", "pooled-country Gini crops: Cape pooled - US(Me+Ma) pooled", ec[["G5_capepooled"]] - ec[["G5_uspooled"]], NULL, G_SIM, "H5", "Cape-US pooled")
mc4 <- mean(ec[paste0("G4_", PAIRS4)])
pc("5.10", "district-mean Gini enslaved: VA - mean(Cape districts)", vp[["G4_VA"]] - mc4, R[, "G4_VA"] - mc4, G_SIM, "H4/H4w", "VA-mean Cape")
pc("5.10", "district-mean Gini crops: mean(Cape) - mean(Me, Ma)", mean(ec[paste0("G5_", c("GR", "Stb", "Swe", "Tul"))]) - mean(ec[c("G5_Maine", "G5_Mass")]), NULL, G_SIM, "H5", "mean Cape-mean US")
# 5.11 crop Ginis on physical quantities (Cape mudden x kappa)
dp <- dc; dp$VG <- rowSums(dp[, GRAINS]) * ifelse(dp$is_cape, KAPPA, 1)
emit("5.11", "crop Ginis on physical quantities (bushels)", enum_stats(dp), H5S)
# 5.12 benchmark by benchmark
for (b in c(1785, 1795, 1805, 1815)) {
  eb <- suppressWarnings(enum_stats(dc[dc$Bench == b, ]))
  vcols <- c(VA_cat = paste0("VA_cat_", b), VA_w = paste0("VA_w_", b), G4_VA = paste0("G4_VA_", b))
  vpb <- vp[vcols]; names(vpb) <- names(vcols); Rb <- R[, vcols]; colnames(Rb) <- names(vcols)
  emit("5.12", paste("benchmark", b), eb, ALL, v = vpb, reps = Rb, note = "NaN/NA = no covered households or undefined Gini in that benchmark")
}
# 5.13 Gini tail influence (point estimates; Virginia trimmed on its own farmers)
vf <- dc[dc$District == "Virginia" & dc$farm & dc$cov_slaves, ]
for (m in c("top1pct", "top10")) {
  vt <- vp; vt[["G4_VA"]] <- gini_trim(vf$Slaves, m)
  emit("5.13", paste("drop", ifelse(m == "top1pct", "top 1%", "10 largest"), "households by outcome in each district"),
       enum_stats(dc, gini_mode = m), c(H4S, H5S), v = vt, interval = FALSE, note = "point estimates; no interval computed")
}
# 5.15 livestock-value Gini by district (no verdict)
for (k in c(CAPE, USENUM, "Virginia")) {
  s <- dc$District == k & dc$farm & dc$cov_cattle
  rows[[length(rows) + 1]] <- tibble(id = "5.15", variant = "livestock-value Gini (cattle + sheep, central prices)", claim = "abstract livestock clause",
    pair = k, estimate = wgini(ifelse(is.na(dc$VS[s]), 0, dc$VS[s]) + dc$VC[s]), ci_lo = NA, ci_hi = NA, interval_type = "level",
    condition = "no verdict", note = if (k == "Virginia") "Virginia: cattle only (sheep structurally missing)" else "")
}

# ---- Diagnostics D1-D6 (reintroduce known errors; never alternatives)
emit("D1", "K1 off (wheat value zero)", enum_stats(make_d(fg, cmap, P, k1 = FALSE)), c("H1", "H2", H5S), note = "diagnostic")
emit("D1", "K2 off (US grain x 2.84)", enum_stats(make_d(fg, cmap, P, k2 = FALSE)), c("H1", "H2", H5S), note = "diagnostic")
emit("D2", "original filter (> 0 incl. wine-only)", enum_stats(make_d(fg, cmap, P, rule = "code")), ALL, note = "diagnostic")
vfa <- dc[dc$District == "Virginia" & dc$farm, ]
f <- dc[dc$farm & dc$District %in% USENUM & dc$cov_crop & dc$cov_live, ]
d3_us_inc <- mean(c(f$income, vfa$VC)); d3_us_g <- mean(c(dc$VG[dc$farm & dc$District %in% USENUM & dc$cov_crop], rep(0, nrow(vfa))))
for (x in list(c("H1", log(ec[["H1_cape"]] / d3_us_inc)), c("H2", log(ec[["H2_cape"]] / d3_us_g))))
  rows[[length(rows) + 1]] <- tibble(id = "D3", variant = "Virginia farmers entered at zero crop value in the US mean (unweighted)", claim = x[1],
    pair = "Cape/US(Me+Ma+VA)", estimate = as.numeric(x[2]), ci_lo = as.numeric(x[2]), ci_hi = as.numeric(x[2]),
    interval_type = "degenerate", condition = verdict_single(as.numeric(x[2]), as.numeric(x[2]), LN_SIM)$verdict, note = "diagnostic")
h <- dc[dc$cov_cattle, ]
d4 <- log(mean(h$Cattle[h$is_cape]) / mean(h$Cattle[!h$is_cape]))
rows[[length(rows) + 1]] <- tibble(id = "D4", variant = "H3 all-household denominator, unweighted (published population)", claim = "H3",
  pair = sprintf("Cape %.3f / US %.3f", mean(h$Cattle[h$is_cape]), mean(h$Cattle[!h$is_cape])), estimate = d4, ci_lo = NA, ci_hi = NA,
  interval_type = "point", condition = paste("point", ifelse(d4 > 0, "> 0", "<= 0")), note = "diagnostic")
emit("D5", "uncovered households treated as zero (Cape GR 1787/1798, Stb 1785/1795 for H1/H2/H5; Virginia: none uncovered under K3)",
     enum_stats(make_d(fg, cmap, P, k3 = FALSE)), ALL, note = "diagnostic; generalised per DEVIATIONS D3")
vo <- readRDS(SCR("verify_objects.rds"))$a; g <- function(id) vo$value[vo$claim_id == id]
for (x in list(c("H1", log(g("tx_p16_income_cape") / g("tx_p16_income_us"))), c("H2", log(g("tx_p16_cropwine_cape") / 55.8)),
               c("H3", log(g("tx_p13_cattle_cape") / g("tx_p13_cattle_us"))), c("H4/H4w", g("T1_Virginia_enslaved") - g("T1_Stellenbosch_enslaved"))))
  rows[[length(rows) + 1]] <- tibble(id = "D6", variant = "original-code pipeline (verification target; H2 uses printed US $55.8)", claim = x[1],
    pair = ifelse(x[1] == "H4/H4w", "VA-Stb", "Cape/US"), estimate = as.numeric(x[2]), ci_lo = NA, ci_hi = NA, interval_type = "point",
    condition = "diagnostic", note = "diagnostic")

# ---- 5.14 superpopulation household bootstrap of the enumerations (model-based), paired with the VA design replicates
en <- dc[dc$District != "Virginia", ]
strat <- split(seq_len(nrow(en)), paste(en$District, en$Year))
keepc <- c("District", "is_cape", "farm", "income", "cropwine", "VG", "Cattle", "Slaves", "cov_crop", "cov_live", "cov_cattle", "cov_slaves")
en <- en[, keepc]
seeds <- make_streams(B_BOOT, SEED, skip = B_BOOT)
one <- function(b) {
  assign(".Random.seed", seeds[[b]], envir = globalenv())
  idx <- unlist(lapply(strat, function(i) i[sample.int(length(i), length(i), replace = TRUE)]), use.names = FALSE)
  contrasts(enum_stats(en[idx, ]), R[b, , drop = FALSE])[1, ]
}
t0 <- Sys.time()
cl <- makeCluster(min(16, detectCores() - 2))
invisible(clusterCall(cl, function(root) { setwd(root); source("P06_FGa/modern/00_helpers.R"); NULL }, normalizePath(".")))
clusterExport(cl, c("en", "strat", "seeds", "one", "R", "contrasts", "PAIRS4", "PAIRS5"))
SP <- do.call(rbind, parLapply(cl, seq_len(B_BOOT), one))
stopCluster(cl)
cat("5.14 runtime:", format(Sys.time() - t0), "\n")
saveRDS(SP, SCR("superpop_boot.rds"))
pt <- contrasts(ec, vp)[1, ]
for (nm in colnames(SP)) {
  x <- SP[, nm]; c99 <- q99(x[is.finite(x)]); c95 <- q95(x[is.finite(x)])
  rows[[length(rows) + 1]] <- tibble(id = "5.14", variant = "superpopulation household bootstrap (District x Year), B = 9,999; ci = 99%",
    claim = CL(nm), pair = PR(nm), estimate = pt[[nm]], ci_lo = c99[1], ci_hi = c99[2], interval_type = "percentile 99% (model-based)",
    condition = verdict_single(c99[1], c99[2], BAND(nm))$verdict,
    note = sprintf("95%%: [%.4f, %.4f]; non-finite reps %d", c95[1], c95[2], sum(!is.finite(x))))
}
sens <- bind_rows(rows)
write_csv(sens, file.path(OUT, "sensitivities.csv"))
cat("Rows:", nrow(sens), "\n")
print(as.data.frame(sens |> select(id, variant, claim, pair, estimate, ci_lo, ci_hi, condition)), digits = 4, right = FALSE)
