# P29_INEQ25 S6 step 3: the central analysis (card §3, §4, §8) and everything computed with the central bootstrap draws.
# - H1/H2 (+ S-a, S-b, S-c, S-g and the raw-unit Fig 2 diagnostic): household-cluster bootstrap on hhid_ext_safe.
# - H3a/H3b (+ S-h): iid household bootstrap stratified by settlement.
# - B = 9,999, seed 20261011, L'Ecuyer-CMRG; escalation to 39,999 by the card's MC SE rule.
# - §5A price factorial (points) for the supplementary display next to each verdict.
# - §5C.3 diagnostics: iid household-year resampling and year-block bootstrap (H1/H2 nodes).
# Outputs: output/primary.csv, output/verdict.csv; replicate matrices and secondary rows on D: (<SCR>).
# Run: Rscript P29_INEQ25/modern/03_central.R
source("P29_INEQ25/modern/00_functions.R")
t_start <- Sys.time()
D <- readRDS(file.path(SCR, "data.rds"))
d <- value_rows(D$panel, D$prices)
DECS <- seq(1690, 1830, 10); PERS <- seq(1680, 1820, 20); SCEN <- c("settlers", "slaveassets", "zero", "sheep12")
C_hh <- max(d$hh)

## ---- node definitions -------------------------------------------------------------------------------------
rows_h1 <- setNames(lapply(DECS, function(dn) h1_rows(d, dn)), paste0("H1_", DECS))
rows_h2 <- list(H2_1780 = h2_rows(d, 1780, "zero"))
rows_sa <- unlist(lapply(SCEN, function(s) setNames(lapply(PERS, function(p) h2_rows(d, p, s)), paste0("Sa_", s, "_", PERS))), recursive = FALSE)
rows_raw <- unlist(lapply(SCEN, function(s) setNames(lapply(PERS, function(p) raw_rows(d, p, s)), paste0("raw_", s, "_", PERS))), recursive = FALSE)
mk <- function(rl, clcol, top = FALSE) lapply(rl, function(r) make_node(r$x, r[[clcol]], top))
ND <- c(mk(rows_h1, "hh", TRUE), mk(rows_h2, "hh"), mk(rows_sa, "hh"), mk(rows_raw, "hh"))
stat_names <- unlist(lapply(names(ND), function(k) if (ND[[k]]$top) paste0(k, c("", "_top1", "_top01", "_top001")) else k))
pt <- unlist(lapply(ND, node_point)); names(pt) <- stat_names
# point checks against node_point = ineq::Gini on the rows
stopifnot(abs(pt["H2_1780"] - G(rows_h2$H2_1780$x)) < 1e-12, abs(pt["H1_1780"] - G(rows_h1$H1_1780$x)) < 1e-12)

rep_panel <- function() { cnt <- tabulate(sample.int(C_hh, C_hh, replace = TRUE), C_hh); unlist(lapply(ND, node_stats, cnt = cnt)) }

## ---- H3 data -----------------------------------------------------------------------------------------------
H3 <- list(
  BD = D$bd14 |> transmute(Cattle = cattle_breeding, Horses = horses, Oxen = cattle_oxen, Sheep = sheep),
  GK = D$gk |> transmute(Horses = horses, Oxen = cattle_oxen, Cattle = cattle_breeding, Sheep = sheep, `Wheat reaped` = wheat_reaped),
  SR = D$sr |> transmute(Horses = horses, Oxen = cattle_oxen, Cattle = cattle_breeding, Sheep = sheep, `Wheat reaped` = wheat_reaped))
H3 <- lapply(H3, as.matrix)
h3_stat <- function(M) unlist(lapply(names(M), function(s) { m <- M[[s]]; setNames(apply(m, 2, function(x) ineq::Gini(x, na.rm = TRUE)), paste(s, colnames(m))) }))
h3_pt <- h3_stat(H3)
rep_h3 <- function() { M <- lapply(H3, function(m) m[sample.int(nrow(m), nrow(m), replace = TRUE), , drop = FALSE]); h3_stat(M) }
H3A <- "BD Cattle"; H3B <- setdiff(names(h3_pt), H3A)

## ---- bootstraps with the escalation rule ---------------------------------------------------------------------
fam_panel <- function(BS) list(H1 = family_ci(BS[, paste0("H1_", DECS)], pt[paste0("H1_", DECS)], "supt"),
                                H2 = family_ci(BS[, "H2_1780", drop = FALSE], pt["H2_1780"], "pct"))
fam_h3 <- function(BS) list(H3a = family_ci(BS[, H3A, drop = FALSE], h3_pt[H3A], "pct"), H3b = family_ci(BS[, H3B], h3_pt[H3B], "supt"))
timing <- list()
t0 <- Sys.time(); BP <- run_boot(9999, rep_panel, c("ND", "C_hh"), environment()); colnames(BP) <- stat_names
timing$panel_9999 <- difftime(Sys.time(), t0, units = "mins")
FP <- fam_panel(BP)
esc_panel <- needs_escalation(FP$H1, 0.60) || needs_escalation(FP$H2, c(0.89, 0.95))
if (esc_panel) { t0 <- Sys.time(); BP <- run_boot(39999, rep_panel, c("ND", "C_hh"), environment()); colnames(BP) <- stat_names
  timing$panel_39999 <- difftime(Sys.time(), t0, units = "mins"); FP <- fam_panel(BP) }
t0 <- Sys.time(); BH <- run_boot(9999, rep_h3, c("H3", "h3_stat"), environment()); colnames(BH) <- names(h3_pt)
timing$h3_9999 <- difftime(Sys.time(), t0, units = "mins")
FH <- fam_h3(BH)
esc_h3 <- needs_escalation(FH$H3a, c(0.69, 0.75)) || needs_escalation(FH$H3b, 0.75)
if (esc_h3) { t0 <- Sys.time(); BH <- run_boot(39999, rep_h3, c("H3", "h3_stat"), environment()); colnames(BH) <- names(h3_pt)
  timing$h3_39999 <- difftime(Sys.time(), t0, units = "mins"); FH <- fam_h3(BH) }
saveRDS(list(BP = BP, BH = BH, pt = pt, h3_pt = h3_pt), file.path(SCR, "boot_central.rds"))

## ---- primary.csv -----------------------------------------------------------------------------------------------
node_diag <- function(r) { cs <- r[, .N, by = hh]$N
  tibble(n_rows = sum(!r$synth), n_synthetic_rows = sum(r$synth), n_clusters = length(cs), mean_cluster_size = mean(cs), max_cluster_size = max(cs),
         share_missing_id = 0, n_positive = sum(r$x > 0)) }
prim_rows <- function(claim, nodes, f, G0, method, diag) tibble(claim = claim, node = nodes, estimate = unname(G0), se = f$se, L = f$L, U = f$U,
  interval = method, level = 1 - ALPHA, crit_c = f$c, B = f$B, V_jointly_valid = f$V, n_undefined_draws = unname(f$n_undef_by_node),
  family_defined = f$defined, mcse_L = f$mcse_L, mcse_U = f$mcse_U) |> bind_cols(diag)
h3_diag <- function(k) { s <- sub(" .*", "", k); a <- sub("^[A-Z]+ ", "", k); x <- H3[[s]][, a]
  tibble(n_rows = length(x), n_synthetic_rows = 0L, n_clusters = sum(!is.na(x)), mean_cluster_size = 1, max_cluster_size = 1,
         share_missing_id = mean(is.na(x)), n_positive = sum(x > 0, na.rm = TRUE)) }
primary <- bind_rows(
  prim_rows("H1", paste("decade", DECS), FP$H1, pt[paste0("H1_", DECS)], "sup-t band (household-cluster bootstrap)", bind_rows(lapply(rows_h1, node_diag))),
  prim_rows("H2", "period 1780-1799, enslaved men as zero-asset rows", FP$H2, pt["H2_1780"], "percentile (household-cluster bootstrap)", node_diag(rows_h2$H2_1780)),
  prim_rows("H3a", "Bethelsdorp 1814 cattle", FH$H3a, h3_pt[H3A], "percentile (iid households, stratified)", h3_diag(H3A)),
  prim_rows("H3b", H3B, FH$H3b, h3_pt[H3B], "sup-t band (iid households, stratified)", bind_rows(lapply(H3B, h3_diag))))
primary <- primary |> mutate(node = recode(node, !!!setNames(paste(c("Bethelsdorp 1814", "Groenekloof", "Swartrivier")[match(sub(" .*", "", H3B), c("BD", "GK", "SR"))], sub("^[A-Z]+ ", "", H3B)), H3B)))
write_csv(primary |> mutate(across(where(is.double), ~ round(.x, 6))), file.path(OUT, "primary.csv"))

## ---- §5A price factorial (points; supplementary display) ---------------------------------------------------------
fac <- expand.grid(cattle = c("breeding", "mean3"), const = c(FALSE, TRUE), stringsAsFactors = FALSE)
fac_res <- bind_rows(lapply(seq_len(nrow(fac)), function(i) {
  dd <- value_rows(D$panel, D$prices, cattle = fac$cattle[i], const = fac$const[i])
  g1 <- sapply(DECS, function(dn) gpt(h1_rows(dd, dn)))
  tibble(scenario = sprintf("V3%s x V4%s", ifelse(fac$cattle[i] == "breeding", "a", "b"), ifelse(fac$const[i], "b", "a")),
         H1_min = min(g1), H1_max = max(g1), H1_all_above_060 = all(g1 > 0.60), H2_1780 = gpt(h2_rows(dd, 1780, "zero")))
})) |> mutate(H2_in_band = H2_1780 >= 0.89 & H2_1780 <= 0.95)
saveRDS(fac_res, file.path(SCR, "factorial_5A.rds"))

## ---- verdicts (card §8) -----------------------------------------------------------------------------------------
v1 <- verdict_threshold(pt[paste0("H1_", DECS)], FP$H1$L, FP$H1$U, 0.60, FP$H1$defined)
v2 <- verdict_point(pt["H2_1780"], FP$H2$L, FP$H2$U, 0.89, 0.95, FP$H2$defined)
v3a <- verdict_point(h3_pt[H3A], FH$H3a$L, FH$H3a$U, 0.69, 0.75, FH$H3a$defined)
v3b <- verdict_threshold(h3_pt[H3B], FH$H3b$L, FH$H3b$U, 0.75, FH$H3b$defined)
v3 <- if (rank_v(v3a[1]) <= rank_v(v3b[1])) v3a else v3b
h3ax <- if (!FH$H3a$defined) "not computable" else if (FH$H3a$U < 0.75) "supported" else if (FH$H3a$L >= 0.75) "refuted" else "uncertain"
f3 <- function(x) sprintf("%.3f", x)
fr <- function(lo, hi) sprintf("[%s, %s]", f3(lo), f3(hi))
fac_txt_h1 <- sprintf("5A (4 price scenarios; assumption-conditional, equal weights are not probabilities): min node %s-%s; all nodes > 0.60 in %d/4",
                      f3(min(fac_res$H1_min)), f3(max(fac_res$H1_min)), sum(fac_res$H1_all_above_060))
fac_txt_h2 <- sprintf("5A (4 price scenarios; assumption-conditional, equal weights are not probabilities): %s-%s; in [0.89, 0.95] in %d/4",
                      f3(min(fac_res$H2_1780)), f3(max(fac_res$H2_1780)), sum(fac_res$H2_in_band))
h1min <- which.min(pt[paste0("H1_", DECS)]); h1Lmin <- which.min(FP$H1$L)
h3b_undef <- FH$H3b$n_undef_by_node[FH$H3b$n_undef_by_node > 0]
verdict <- tibble(
  claim = c("H1", "H2", "H3a", "H3b", "H3 (summary)", "H3a-x (reported, no verdict)"),
  estimate = c(sprintf("min decade Gini %s (%d); range %s-%s over 1690-1830", f3(pt[paste0("H1_", DECS)][h1min]), DECS[h1min], f3(min(pt[paste0("H1_", DECS)])), f3(max(pt[paste0("H1_", DECS)]))),
               f3(pt["H2_1780"]), f3(h3_pt[H3A]), sprintf("min other computable asset %s (%s); not computable: %s", f3(min(h3_pt[H3B], na.rm = TRUE)), names(which.min(h3_pt[H3B])),
                       paste(names(h3_pt[H3B])[!is.finite(h3_pt[H3B])], collapse = ", ")),
               "weaker of H3a and H3b", f3(h3_pt[H3A])),
  interval = c(sprintf("98.75%% sup-t band; lowest lower bound %s (%d); c = %.3f", f3(FP$H1$L[h1Lmin]), DECS[h1Lmin], FP$H1$c),
               sprintf("98.75%% percentile %s", fr(FP$H2$L, FP$H2$U)), sprintf("98.75%% percentile %s", fr(FH$H3a$L, FH$H3a$U)),
               if (FH$H3b$defined) sprintf("98.75%% sup-t band; min L %s", f3(min(FH$H3b$L))) else
                 sprintf("undefined: jointly valid draws V = %d of B = %d (< 99%%); undefined draws by node: %s", FH$H3b$V, FH$H3b$B,
                         paste(sprintf("%s %d", names(h3b_undef), h3b_undef), collapse = ", ")),
               "", sprintf("98.75%% percentile %s", fr(FH$H3a$L, FH$H3a$U))),
  test_p = "NA (the card defines no test p-value; verdicts use interval rules)",
  threshold_or_band = c("G_d > 0.60 at every decade 1690-1830", "[0.89, 0.95]", "[0.69, 0.75]", "G_j > 0.75 for every other asset", "", "G < 0.75"),
  verdict = c(v1[1], v2[1], v3a[1], v3b[1], v3[1], h3ax),
  rule = c(v1[2], v2[2], v3a[2], v3b[2], paste0("weaker of H3a (rule ", v3a[2], ") and H3b (rule ", v3b[2], ")"), "card §8 H3a-x"),
  supplementary_5A = c(fac_txt_h1, fac_txt_h2, "no valuation items (card §5A)", "no valuation items (card §5A)", "", ""),
  B = c(FP$H1$B, FP$H2$B, FH$H3a$B, FH$H3b$B, NA, FH$H3a$B))
write_csv(verdict, file.path(OUT, "verdict.csv"))

## ---- secondary outputs from the central draws (S-a, S-b, S-c, S-g, raw-unit diagnostic, S-h) -----------------
sec <- list(); adds <- function(item, quantity, est, L = NA, U = NA, note = "", n_undef = NA) sec[[length(sec) + 1]] <<-
  tibble(section = item, quantity = quantity, estimate = est, L = L, U = U, n_undefined_draws = n_undef, note = note)
ci <- function(v, a = ALPHA2) pct_ci(v, a)
for (s in SCEN) for (p in PERS) { k <- paste0("Sa_", s, "_", p); q <- ci(BP[, k])
  adds("S-a Fig 2 price-weighted (all census rows)", paste(s, p), pt[[k]], q[1], q[2], "95% percentile, household-cluster bootstrap", q[3]) }
for (p in PERS) { dz <- BP[, paste0("Sa_zero_", p)] - BP[, paste0("Sa_settlers_", p)]; q <- ci(dz)
  e <- pt[[paste0("Sa_zero_", p)]] - pt[[paste0("Sa_settlers_", p)]]
  adds("S-a intro comparative: zero-asset minus settlers-only ('as large as'; similar = within +/-0.03)", paste("period", p), e, q[1], q[2],
       sprintf("95%% percentile; similar (|diff| <= 0.03, CI inside): %s", ifelse(q[1] >= -0.03 & q[2] <= 0.03, "yes", "no")), q[3]) }
s12 <- paste0("Sa_sheep12_", c(1760, 1780, 1800)); mn <- apply(BP[, s12], 1, min); mx <- apply(BP[, s12], 1, max)
adds("S-b 12-sheep scenario vs '0.89 to 0.91' (periods 1760-1800)", "min over 1760/1780/1800", min(pt[s12]), ci(mn)[1], ci(mn)[2], "95% percentile")
adds("S-b 12-sheep scenario vs '0.89 to 0.91' (periods 1760-1800)", "max over 1760/1780/1800", max(pt[s12]), ci(mx)[1], ci(mx)[2], "95% percentile")
k18 <- paste0("H1_", seq(1700, 1790, 10)); mn <- apply(BP[, k18], 1, min); mx <- apply(BP[, k18], 1, max)
adds("S-c 18th-century basket range vs '0.6-0.75' (decades 1700-1790)", "min", min(pt[k18]), ci(mn)[1], ci(mn)[2], "95% percentile")
adds("S-c 18th-century basket range vs '0.6-0.75' (decades 1700-1790)", "max", max(pt[k18]), ci(mx)[1], ci(mx)[2], "95% percentile")
for (tt in c("top1", "top01", "top001")) {
  for (rg in list(c("1800-1830", 1800, 1830), c("1700-1790", 1700, 1790), c("all decades 1690-1830", 1690, 1830))) {
    ks <- paste0("H1_", seq(as.numeric(rg[2]), as.numeric(rg[3]), 10), "_", tt)
    m <- rowMeans(BP[, ks]); q <- ci(m)
    adds("S-g top shares of the H1 basket (% of total value; mean of decade shares)", paste(tt, rg[1]), 100 * mean(pt[ks]), 100 * q[1], 100 * q[2], "95% percentile")
  }
}
for (s in SCEN) for (p in PERS) { k <- paste0("raw_", s, "_", p); q <- ci(BP[, k], ALPHA)
  adds("5C.3 diagnostic: raw-unit Fig 2 as printed (code populations), central bootstrap", paste(s, p), pt[[k]], q[1], q[2], "98.75% percentile", q[3]) }
# S-h (report only): H3b over assets with >= 10 positive holders; and the zero-replicate convention
npos <- sapply(H3B, function(k) { s <- sub(" .*", "", k); a <- sub("^[A-Z]+ ", "", k); sum(H3[[s]][, a] > 0, na.rm = TRUE) })
well <- H3B[npos >= 10]
fSh <- family_ci(BH[, well], h3_pt[well], "supt")
for (j in seq_along(well)) adds("S-h H3b on assets with >= 10 positive holders (report only)", well[j], h3_pt[[well[j]]], fSh$L[j], fSh$U[j],
  sprintf("98.75%% sup-t, joint-draw rule; V = %d/%d; c = %.3f; positive holders %d", fSh$V, fSh$B, fSh$c, npos[well[j]]))
vSh <- verdict_threshold(h3_pt[well], fSh$L, fSh$U, 0.75, fSh$defined)
adds("S-h H3b on assets with >= 10 positive holders (report only)", "rule outcome (not a verdict)", min(h3_pt[well]), min(fSh$L), NA, paste0(vSh[1], " (rule ", vSh[2], ")"))
for (k in setdiff(H3B, well)) adds("S-h excluded assets (< 10 positive holders), point only", k, h3_pt[[k]], NA, NA, sprintf("positive holders %d", npos[k]))
H3Bc <- H3B[is.finite(h3_pt[H3B])]   # DEVIATIONS D3: a node with an undefined point estimate cannot enter (SR Sheep: no holders)
BZ <- BH[, H3Bc]; BZ[!is.finite(BZ)] <- 0
fZ <- family_ci(BZ, h3_pt[H3Bc], "supt")
for (j in seq_along(H3Bc)) adds("S-h zero-replicate convention (G* = 0 for undefined draws; a convention, not an estimate)", H3Bc[j], h3_pt[[H3Bc[j]]], fZ$L[j], fZ$U[j],
  sprintf("98.75%% sup-t; c = %.3f", fZ$c))
vZ <- verdict_threshold(h3_pt[H3Bc], fZ$L, fZ$U, 0.75, fZ$defined)
adds("S-h zero-replicate convention (G* = 0 for undefined draws; a convention, not an estimate)", "rule outcome (not a verdict)", min(h3_pt[H3Bc]), min(fZ$L), NA, paste0(vZ[1], " (rule ", vZ[2], ")"))

## ---- §5C.3 diagnostics: iid household-year and year-block resampling (H1 and H2 nodes) -------------------------
rows_core <- c(rows_h1, rows_h2)
ND_iid <- lapply(names(rows_core), function(k) make_node(rows_core[[k]]$x, rows_core[[k]]$row)); names(ND_iid) <- names(rows_core)
C_row <- nrow(d)
rep_iid <- function() { cnt <- tabulate(sample.int(C_row, C_row, replace = TRUE), C_row); unlist(lapply(ND_iid, node_stats, cnt = cnt)) }
yrs <- sort(unique(d$year)); yidx <- function(y) match(y, yrs); ystr <- split(seq_along(yrs), (yrs %/% 10) * 10)
ND_yr <- lapply(rows_core, function(r) make_node(r$x, yidx(r$year)))
rep_yr <- function() { cnt <- integer(length(yrs)); for (s in ystr) { k <- s[sample.int(length(s), length(s), replace = TRUE)]; cnt <- cnt + tabulate(k, length(yrs)) }
  unlist(lapply(ND_yr, node_stats, cnt = cnt)) }
t0 <- Sys.time(); BI <- run_boot(9999, rep_iid, c("ND_iid", "C_row"), environment()); colnames(BI) <- names(rows_core)
BY <- run_boot(9999, rep_yr, c("ND_yr", "yrs", "ystr"), environment()); colnames(BY) <- names(rows_core)
timing$diag <- difftime(Sys.time(), t0, units = "mins")
for (nm in c("iid household-year", "year-block (census years within decades)")) {
  BB <- if (grepl("iid", nm)) BI else BY
  f1 <- family_ci(BB[, paste0("H1_", DECS)], pt[paste0("H1_", DECS)], "supt"); f2 <- family_ci(BB[, "H2_1780", drop = FALSE], pt["H2_1780"], "pct")
  for (j in seq_along(DECS)) adds(paste("5C.3 diagnostic:", nm, "- H1 sup-t band"), paste("decade", DECS[j]), pt[[paste0("H1_", DECS[j])]], f1$L[j], f1$U[j],
                                  sprintf("98.75%% sup-t; c = %.3f; V = %d", f1$c, f1$V))
  adds(paste("5C.3 diagnostic:", nm, "- H2"), "1780", pt[["H2_1780"]], f2$L, f2$U, sprintf("98.75%% percentile; central %s", fr(FP$H2$L, FP$H2$U)))
}
saveRDS(bind_rows(sec), file.path(SCR, "secondary_central.rds"))
saveRDS(list(timing = timing, esc_panel = esc_panel, esc_h3 = esc_h3, FP = FP, FH = FH, npos = npos), file.path(SCR, "central_meta.rds"))
cat("escalation panel:", esc_panel, " H3:", esc_h3, "\n"); print(timing)
print(as.data.frame(verdict[, c("claim", "estimate", "interval", "verdict", "rule")]))
cat("total minutes:", round(difftime(Sys.time(), t_start, units = "mins"), 1), "\n")
