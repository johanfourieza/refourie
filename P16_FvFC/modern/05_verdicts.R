# P16_FvFC S6 -- 05_verdicts.R: card §8 applied mechanically to the central analysis.
# Point rows (H1, H2-pt, H3-pt): A8 bands, no inference. Family rows: the central cluster bootstrap,
# with the 39,999-draw run for any row flagged at 9,999, the failure-bounded check, the F > 0.01 cap,
# and the 3^k joint-perturbation rule for endpoints still flagged after escalation.
# Outputs: output/verdict.csv, output/primary.csv, output/claim_summary.csv, output/failures.csv

source(here::here("P16_FvFC", "modern", "00_common.R"))
C  <- readRDS(file.path(SCR, "central.rds")); cen <- C$cen
BC <- readRDS(file.path(SCR, "boot_central.rds"))
sens <- read_csv(file.path(OUT, "sensitivities.csv"), show_col_types = FALSE)
cls  <- read_csv(file.path(OUT, "classification.csv"), show_col_types = FALSE)

prim <- list(); verd <- list(); fails <- list()
R1 <- draw_rows(BC$M)
# ---- point rows -----------------------------------------------------------------------------
pts <- list(H1 = list(q = "G1663", lo = 0.471, hi = 0.531, claim = "text_p26_gini_initial", stated = 0.501),
            `H2-pt` = list(q = "G1709", lo = 0.62, hi = 0.68, claim = "text_p26_gini_1709", stated = 0.65),
            `H3-pt` = list(q = "G1757", lo = 0.59, hi = 0.65, claim = "text_p26_gini_1757", stated = 0.62))
for (r in names(pts)) {
  p <- pts[[r]]; G <- cen[p$q]; ci <- pct_int(R1[, p$q], 0.05); v <- v_point(G, p$lo, p$hi)
  verd[[r]] <- tibble(claim = p$claim, row = r, class = cls$class[cls$row == r], quantity = p$q, stated = p$stated,
                      estimate = G, interval = sprintf("[%.3f, %.3f] 95%% percentile (reported, not used)", ci["L"], ci["U"]),
                      test_p = NA_real_, threshold_or_band = sprintf("[%.3f, %.3f] (A8)", p$lo, p$hi),
                      verdict = v["verdict"], rule = paste0("§8 point #", v["rule"]), B = nrow(BC$M), note = "")
  prim[[r]] <- tibble(row = r, quantity = p$q, estimate = G, L = ci["L"], U = ci["U"], level = "95% percentile", se = sd(R1[, p$q]),
                      mcse = NA, flagged = NA, B = nrow(BC$M))
}
# ---- family rows ----------------------------------------------------------------------------
claims <- c(`H2-rise` = "text_p26_gini_1709", `H3-rise` = "text_p26_gini_1757", H4 = "text_p23_slave_gap", `H4-w` = "text_p23_slave_gap")
thr <- c(`H2-rise` = "L_t > 0 for all t in {1663,1670,1678,1682} (98.75% sup-t)", `H3-rise` = "L > 0 (98.75%); L95 > 0 for fragile tier",
         H4 = "L > 0 and m >= 0.10; A4a null (-0.10, 0.10)", `H4-w` = "L > 0 (98.75%); L95 > 0 for fragile tier")
for (r in names(ROW_NEEDS)) {
  Mu <- if (r %in% BC$escalated) BC$M2 else BC$M
  R <- draw_rows(Mu); a <- assess_row(r, Mu, R, cen)
  pa <- perturb_agree(a)
  mc_unres <- (r %in% BC$escalated) && !pa$agree
  nt <- a$nt_inference || mc_unres
  v <- verdict_row(r, a$x0, a$ep, nt)
  fails[[r]] <- tibble(row = r, B = a$B, valid = a$V, F = a$F, causes = paste(names(a$causes), a$causes, sep = ":", collapse = " "),
                       verdict_valid = a$va["verdict"], verdict_bounded = a$vb["verdict"], escalated = r %in% BC$escalated,
                       flagged_after = paste(names(a$flag)[a$flag], collapse = " "), perturb_k = pa$k, perturb_combos = pa$n, perturb_agree = pa$agree)
  need <- ROW_NEEDS[[r]]
  if (r == "H2-rise") {
    L <- a$ep[paste0("L_", INIT)]; U <- a$ep[paste0("U_", INIT)]
    prim[[r]] <- tibble(row = r, quantity = need, estimate = a$x0, L = L, U = U, level = sprintf("98.75%% sup-t (c = %.3f)", a$c),
                        se = a$se, mcse = pmax(a$mcse[paste0("L_", INIT)], a$mcse[paste0("U_", INIT)]),
                        flagged = need %in% sub("^[LU]_", "d_", names(a$flag)[a$flag]), B = a$B)
    est <- paste(sprintf("%s %.4f", need, a$x0), collapse = "; ")
    int <- paste(sprintf("[%.4f, %.4f]", L, U), collapse = "; ")
    pv <- NA_real_
  } else {
    xv <- R[is.finite(R[, need]), need]
    pv <- min(1, 2 * min(mean(xv <= 0), mean(xv >= 0)))      # bootstrap percentile p for X = 0 (reported only)
    prim[[r]] <- tibble(row = r, quantity = need, estimate = a$x0, L = a$ep["L"], U = a$ep["U"], level = "98.75% percentile",
                        se = a$se, mcse = max(a$mcse[c("L", "U")]), flagged = any(a$flag), B = a$B) |>
      bind_rows(tibble(row = r, quantity = paste0(need, " (95%)"), estimate = a$x0, L = a$ep["L95"], U = a$ep["U95"],
                       level = "95% percentile (unadjusted)", se = a$se, mcse = a$mcse["L95"], flagged = a$flag["L95"], B = a$B))
    est <- sprintf("%.4f", a$x0); int <- sprintf("[%.4f, %.4f] 98.75%%; L95 %.4f", a$ep["L"], a$ep["U"], a$ep["L95"])
  }
  note <- c(if (r != "H2-rise" && is.finite(a$ep["U"]) && a$ep["U"] < 0) "interval reversed; A4b caps the verdict at weakened",
            if (r == "H4" && a$x0 > 0.30) "plausibility flag m > 0.30",
            if (r %in% BC$escalated) sprintf("escalated to B = %d; flagged after escalation: %s; %d-combination perturbation %s",
                                              a$B, ifelse(pa$k > 0, paste(names(a$flag)[a$flag], collapse = " "), "none"), pa$n,
                                              ifelse(pa$agree, "agrees", "disagrees")))
  verd[[r]] <- tibble(claim = claims[r], row = r, class = cls$class[cls$row == r], quantity = paste(need, collapse = ";"),
                      stated = c(`H2-rise` = NA, `H3-rise` = NA, H4 = 0.2, `H4-w` = NA)[r], estimate = NA_real_, estimate_txt = est,
                      interval = int, test_p = pv, threshold_or_band = thr[r], verdict = v["verdict"],
                      rule = paste0("§8 ", r, " #", v["rule"]), B = a$B, note = paste(note, collapse = "; "))
  if (r != "H2-rise") verd[[r]]$estimate <- a$x0
}
# not-testable rows
for (r in c("H4-ES", "W-lvl", "W-cause"))
  verd[[r]] <- tibble(claim = ifelse(r == "H4-ES", "text_p23_slave_gap", "wording"), row = r, class = "—", quantity = "", stated = NA,
                      estimate = NA, interval = "", test_p = NA, threshold_or_band = "", verdict = "not-testable",
                      rule = "§8 (H4-ES, W-lvl, W-cause)", B = NA, note = "card §1")
V <- bind_rows(verd) |> mutate(estimate_txt = coalesce(estimate_txt, ifelse(is.na(estimate), "", sprintf("%.4f", estimate))))
# sensitivities beside each verdict (reported, not verdict-determining)
sb <- sens |> filter(!is.na(row), !is.na(would_be)) |> distinct(item, row, would_be) |>
  group_by(row) |> summarise(sens_would_be = paste(sprintf("%s: %s", item, sub(" \\(.*", "", would_be)), collapse = "; "), .groups = "drop")
V <- V |> left_join(sb, by = "row")
write_csv(V |> select(claim, row, class, quantity, stated, estimate = estimate_txt, interval, test_p, threshold_or_band, verdict, rule, B, note,
                      sensitivities_reported_not_verdict_determining = sens_would_be), file.path(OUT, "verdict.csv"))
write_csv(bind_rows(prim), file.path(OUT, "primary.csv"))
write_csv(bind_rows(fails), file.path(OUT, "failures.csv"))

# per-claim summaries (weakest of the rows; not-testable < overturned < weakened < qualified < confirmed)
vv <- setNames(V$verdict, V$row)
cs <- tibble(claim = c("text_p26_gini_initial (H1)", "text_p26_gini_1709 (H2)", "text_p26_gini_1757 (H3)", "text_p23_slave_gap (H4)"),
             rows = c("H1", "H2-pt + H2-rise", "H3-pt + H3-rise", "H4 + H4-w"),
             verdict = c(vv["H1"], weakest(vv[c("H2-pt", "H2-rise")]), weakest(vv[c("H3-pt", "H3-rise")]), weakest(vv[c("H4", "H4-w")])))
write_csv(cs, file.path(OUT, "claim_summary.csv"))
cat(sprintf("Coverage: %d verdict rows assessed, %d not-testable (incl. H4-ES, W-lvl, W-cause)\n", nrow(V), sum(V$verdict == "not-testable")))
print(V |> select(row, estimate_txt, interval, verdict, rule), width = 250)
print(bind_rows(fails), width = 250); print(cs)
