# P30_STB24 S6 step 3: H2, "stagnation or even marginal decline in most assets over the eighteenth century".
# r_a = ln(M_L / M_E), E = 1700-1709, L = 1790-1799; two-stage percentile-t at the Family H2 level (card s3, s4, s8).
# Also: s5B items 1, 3, 4 for H2 and the H2-anchor diagnostic.
source("P30_STB24/modern/00_common.R")
t0 <- Sys.time()
d <- readRDS(SCR("central.rds"))
Y <- prep_years(d)
yrs <- names(Y)
E <- yrs[as.numeric(yrs) %in% 1700:1709]; L <- yrs[as.numeric(yrs) %in% 1790:1799]
cat("E years:", E, "\nL years:", L, "\n")

# ---- point estimates ----------------------------------------------------------------------------
mE0 <- st_means(Y, occ_fixed(Y, E)); mL0 <- st_means(Y, occ_fixed(Y, L))
pt <- h2_stats(mE0, mL0)
minyrs_ok <- pt[, "nE"] >= 5 & pt[, "nL"] >= 5
print(cbind(pt, ME = colMeans(mE0, na.rm = TRUE), ML = colMeans(mL0, na.rm = TRUE)))

# ---- bootstrap designs --------------------------------------------------------------------------
cl_E <- make_clusters(Y, E); cl_L <- make_clusters(Y, L)
f_two   <- function(b) { s <- h2_stats(st_means(Y, occ_two_stage(Y, E)), st_means(Y, occ_two_stage(Y, L))); c(s[, 1], s[, 2]) }
f_block <- function(b) { s <- h2_stats(st_means(Y, occ_block(Y, E)), st_means(Y, occ_block(Y, L))); c(s[, 1], s[, 2]) }
f_names <- function(b) { s <- h2_stats(st_means(Y, occ_names(Y, cl_E)), st_means(Y, occ_names(Y, cl_L))); c(s[, 1], s[, 2]) }
f_within <- function(b) {
  s <- h2_stats(st_means(Y, occ_within(Y, E)), st_means(Y, occ_within(Y, L)))
  a1 <- st_means(Y, list(list(y = "1702", cnt = rcount(Y[["1702"]]$n))))[1, 6]
  a2 <- st_means(Y, list(list(y = "1795", cnt = rcount(Y[["1795"]]$n))))[1, 6]
  c(s[, 1], s[, 2], anchor = a1 / a2)
}
ex <- c("Y", "E", "L", "h2_stats", "cl_E", "cl_L")
B0 <- as.integer(Sys.getenv("B0", "19999"))
boot <- function(f, B, from = 1) do.call(rbind, run_boot(B, f, export = ex, from = from))
R_two <- boot(f_two, B0)

summarise_pt <- function(R, alpha, B) {
  rows <- lapply(1:6, function(a) {
    th <- R[, a]; se <- R[, 6 + a]
    ok <- is.finite(th) & is.finite(se) & se > 0
    nfail <- sum(!ok); tstar <- (th[ok] - pt[a, "theta"]) / se[ok]
    ci <- pt_interval(pt[a, "theta"], pt[a, "se"], tstar, alpha); mc <- pt_mcse(pt[a, "theta"], pt[a, "se"], tstar, alpha)
    data.frame(asset = ASSETS[a], theta = pt[a, "theta"], se = pt[a, "se"], lo = ci[["lo"]], hi = ci[["hi"]],
               mcse_lo = mc[["lo"]], mcse_hi = mc[["hi"]], nfail = nfail, failmax = FAILMAX("H2", B), B = B,
               nE = pt[a, "nE"], nL = pt[a, "nL"], minyrs_ok = minyrs_ok[a])
  })
  do.call(rbind, rows)
}
bnd <- c(log(0.8), log(1.25))
near <- function(s) any(sapply(bnd, function(x) abs(s$lo - x) < 2 * s$mcse_lo | abs(s$hi - x) < 2 * s$mcse_hi), na.rm = TRUE)
S <- summarise_pt(R_two, ALPHA[["H2"]], B0)
mc_escalated <- FALSE
if (near(S)) {
  mc_escalated <- TRUE
  R_two <- rbind(R_two, boot(f_two, 49999, from = 20000))
  S <- summarise_pt(R_two, ALPHA[["H2"]], 49999)
}
S$mc_escalated <- mc_escalated
S$mc_fragile <- mc_escalated & near(S)
S$defined <- S$minyrs_ok & is.finite(S$theta) & is.finite(S$se) & S$nfail <= S$failmax
S$category <- mapply(function(lo, hi, th, def) if (!def) "NT" else classify_h2(lo, hi, th), S$lo, S$hi, S$theta, S$defined)
S$ratio <- exp(S$theta); S$ratio_lo <- exp(S$lo); S$ratio_hi <- exp(S$hi)
S$fp_point_in_band <- S$theta >= bnd[1] & S$theta <= bnd[2]
print(S)
fwrite(S, file.path(OUT, "h2_primary.csv"))
fwrite(data.table(year = as.numeric(c(E, L)), window = rep(c("E", "L"), c(length(E), length(L))), rbind(mE0, mL0)),
       file.path(OUT, "h2_annual_means.csv"))
saveRDS(R_two, SCR("h2_boot_two.rds"))

# ---- diagnostics (s5B items 1, 3, 4; H2-anchor) -------------------------------------------------
R_w <- boot(f_within, B0); R_b <- boot(f_block, B0); R_n <- boot(f_names, B0)
pct <- function(x, alpha) quantile(x[is.finite(x)], c(alpha / 2, 1 - alpha / 2), names = FALSE)
diag <- rbindlist(lapply(1:6, function(a) {
  tb <- (R_b[, a] - pt[a, 1]) / R_b[, 6 + a]; okb <- is.finite(tb) & R_b[, 6 + a] > 0
  cib <- pt_interval(pt[a, 1], pt[a, 2], tb[okb], ALPHA[["H2"]])
  data.table(asset = ASSETS[a], theta = pt[a, 1], se_primary_jack = pt[a, 2], sd_two_stage = sd(R_two[, a], na.rm = TRUE),
    within_sd = sd(R_w[, a], na.rm = TRUE), within_lo = pct(R_w[, a], ALPHA[["H2"]])[1], within_hi = pct(R_w[, a], ALPHA[["H2"]])[2],
    block_sd = sd(R_b[, a], na.rm = TRUE), block_lo = cib[["lo"]], block_hi = cib[["hi"]], block_fail = sum(!okb),
    names_sd = sd(R_n[, a], na.rm = TRUE), names_lo = pct(R_n[, a], ALPHA[["H2"]])[1], names_hi = pct(R_n[, a], ALPHA[["H2"]])[2],
    block_category = classify_h2(cib[["lo"]], cib[["hi"]], pt[a, 1]),
    names_category = classify_h2(pct(R_n[, a], ALPHA[["H2"]])[1], pct(R_n[, a], ALPHA[["H2"]])[2], pt[a, 1]),
    within_category = classify_h2(pct(R_w[, a], ALPHA[["H2"]])[1], pct(R_w[, a], ALPHA[["H2"]])[2], pt[a, 1]))
}))
print(diag)
fwrite(diag, file.path(OUT, "h2_diag_inference.csv"))
clus <- data.table(window = c("E", "L"), clusters = c(cl_E$K, cl_L$K), rows = c(sum(cl_E$sizes), sum(cl_L$sizes)),
                   multi_year_clusters = c(sum(cl_E$sizes > 1), sum(cl_L$sizes > 1)), max_size = c(max(cl_E$sizes), max(cl_L$sizes)))
fwrite(clus, file.path(OUT, "h2_name_clusters.csv"))

I0 <- (mean(Y[["1702"]]$X0[, "wine"][Y[["1702"]]$R[, "wine"] == 1])) / mean(Y[["1795"]]$X0[, "wine"][Y[["1795"]]$R[, "wine"] == 1])
ai <- quantile(R_w[, 13], c(.025, .975), names = FALSE, na.rm = TRUE)
anc <- data.table(diag = "H2-anchor", I = I0, lo = ai[1], hi = ai[2], band_lo = 2.97, band_hi = 3.63,
                  label = if (ai[2] < 2.97) "below" else if (ai[1] > 3.63) "above" else if (ai[1] >= 2.97 && ai[2] <= 3.63) "inside" else "overlaps")
print(anc); fwrite(anc, file.path(OUT, "h2_anchor.csv"))
cat("runtime:", format(Sys.time() - t0), "\n")
