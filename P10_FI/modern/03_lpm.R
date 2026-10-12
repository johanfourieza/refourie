# P10_FI S6 step 3: LPM rows (card §4 C). Family E = published spec (signed dlit), inference only;
# Family L = literacy-corrected spec (ilit = |mlit - flit|). Two-way WCR by parish and year.
# Run from the project root: Rscript P10_FI/modern/03_lpm.R
source(file.path("P10_FI", "modern", "00_functions.R"))
L <- load_angreg("v2018"); a <- L$a
s2 <- fread(file.path("P10_FI", "repro_original", "results_original_v2018.csv"))

# ---- Verification: published specification refit = S2 (coefficients and iid SEs) ---------------
ver <- rbindlist(lapply(c("c2", "c4"), function(sp) {
  m <- fit_lm(formula(L$models[[sp]]), a); ct <- summary(m)$coefficients
  rbindlist(lapply(c(act = "act", segregation = "inequality", literacygap = "dlit"), function(tm) {
    id <- sprintf("T3_%s_%s", names(which(c(act = "act", segregation = "inequality", literacygap = "dlit") == tm)), sp)
    data.table(check = paste("refit", sp, tm), coef = ct[tm, 1], coef_S2 = s2[claim_id == id, value],
               se_iid = ct[tm, 2], se_S2 = s2[claim_id == id, se], N = nobs(m), N_S2 = s2[claim_id == id, n])
  }))
}))
ver[, pass := abs(coef - coef_S2) < 1e-10 & abs(se_iid - se_S2) < 1e-10 & N == N_S2]
print(ver); fwrite(ver, file.path(OUT, "verification_lpm.csv"))

# ---- Primary and correction rows -----------------------------------------------------------------
rows <- data.table(row = c("H2-c2", "H2-c4", "H3-c2", "H3-c4", "H2-c2L", "H2-c4L", "H3-c2L", "H3-c4L"),
                   spec = rep(c("c2", "c4", "c2", "c4"), 2), hyp = rep(c("H2", "H2", "H3", "H3"), 2),
                   corrected = rep(c(FALSE, TRUE), each = 4), family = rep(c("E", "L"), each = 4),
                   b0 = rep(c(0.0003, -0.006, -0.027, -0.014), 2))
res <- list(); diag <- list()
for (i in seq_len(nrow(rows))) {
  r <- rows[i]; prm <- PARAM[r$hyp]
  x <- lpm_row(spec_formula(L$models, r$spec, r$corrected), a, prm)
  res[[i]] <- data.table(r, param = prm, estimate = x$est, p = x$p, lo = x$lo, hi = x$hi, source = x$source, N = x$N, degenerate = x$degenerate)
  dd <- as.data.table(x$dd); dd[, py := paste(parishdum, year)]
  cs <- dd[, .N, by = parishdum]$N; ys <- dd[, .N, by = year]$N
  sc_p <- summclust(x$m, params = prm, cluster = ~parishdum); sc_y <- summclust(x$m, params = prm, cluster = ~year)
  diag[[i]] <- data.table(row = r$row, N = x$N, G_parish = uniqueN(dd$parishdum), G_year = uniqueN(dd$year), G_parish_year = uniqueN(dd$py),
    bootcluster = ifelse(uniqueN(dd$parishdum) <= uniqueN(dd$year), "parishdum", "year"),
    parish_min = min(cs), parish_median = median(cs), parish_max = max(cs), parish_max_share = max(cs) / x$N,
    year_min = min(ys), year_median = median(ys), year_max = max(ys), year_max_share = max(ys) / x$N,
    max_partial_leverage_parish = max(sc_p$partial_leverage[prm, ]), max_partial_leverage_year = max(sc_y$partial_leverage[prm, ]),
    degenerate_draws = x$degenerate, inference = x$source)
}
res <- rbindlist(res); diag <- rbindlist(diag)
res[, p_holm := holm(p), by = family]
print(res[, .(row, estimate = signif(estimate, 4), p = signif(p, 3), p_holm = signif(p_holm, 3), lo = signif(lo, 3), hi = signif(hi, 3), source, N)])
print(diag)
fwrite(res, file.path(OUT, "lpm_primary.csv")); fwrite(diag, file.path(OUT, "cluster_diagnostics.csv"))
