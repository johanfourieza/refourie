# P01_BF S6 step 4: Holm over the family of nine (card §4C), mechanical verdicts (card §8), plausibility flags (§7),
# sensitivity 12 (prose magnitudes; appended to sensitivities.csv) and the verdict-category changes under
# leave-one-volume-out (sensitivity 20). Sensitivities never enter the verdicts.
# Outputs: output/primary.csv, verdict.csv, s20_verdict_changes.csv; sensitivities.csv (sens 12 rows replaced)
source(here::here("P01_BF", "modern", "00_common.R"))

t6 <- read_csv(file.path(out, "t6_primary.csv"), show_col_types = FALSE)
h3 <- read_csv(file.path(out, "h3_primary.csv"), show_col_types = FALSE)
pr <- bind_rows(t6 |> select(row, est, se, df, p, ci_lo, ci_hi, fail),
                h3 |> transmute(row, est, se = NA_real_, df = NA_real_, p, ci_lo, ci_hi, fail)) |>
  mutate(row = factor(row, levels = ROWS9)) |> arrange(row) |> mutate(row = as.character(row))
stopifnot(nrow(pr) == M_FAM)

holm_verdicts <- function(pr) {
  pr <- pr |> mutate(p_in = if_else(fail | !is.finite(p), 1, p), p_holm = p.adjust(p_in, "holm"),
                     b0 = map_dbl(row, b0_row), threshold = 0.5 * abs(b0))
  v <- pmap(pr, function(row, est, p, p_holm, ci_lo, ci_hi, fail, b0, ...)
    if (row == "H3") verdict_h3(p_holm, p, fail) else verdict_ptrel(est, b0, p_holm, ci_lo, ci_hi, fail))
  pr$verdict <- map_chr(v, 1); pr$rule <- map_chr(v, 2)
  mem <- pr |> filter(row %in% c("H2-SEA-pt", "H2-IND-pt", "H2-MOZ-pt"))
  h2 <- if (any(!mem$fail & mem$est > 0 & mem$p_holm < ALPHA)) c("overturned (reversed for that group)", "1") else
    if (any(mem$fail)) c("not-testable", "2") else
    if (all(mem$est < 0 & mem$p_holm < ALPHA)) c("confirmed", "3") else c("weakened", "4")
  list(pr = pr, h2 = h2)
}
hv <- holm_verdicts(pr); pr <- hv$pr
pr <- pr |> mutate(plausibility_flag = !fail & est * b0 > 0 & abs(est) > 1.5 * abs(b0),
                   discordant = row != "H3" & p_holm < ALPHA & ci_lo <= 0 & ci_hi >= 0)
write_csv(pr |> select(row, b0, est, se, df, p_raw = p, p_holm, ci_lo, ci_hi, threshold, plausibility_flag, discordant, fail, verdict, rule),
          file.path(out, "primary.csv"))

fmt <- function(row, x) if (row == "H3" || endsWith(row, "-pt")) sprintf("%.2f", x) else sprintf("%.3f", x)
vt <- pr |> rowwise() |> transmute(
  claim = row, estimate = fmt(row, est),
  interval = if (is.na(ci_lo)) "not inverted" else sprintf("[%s, %s] (%s)", fmt(row, ci_lo), fmt(row, ci_hi),
                                                          if (row == "H3") "WCR Bonferroni 99.44%, reported only" else "Bonferroni 99.44%"),
  test_p = sprintf("Holm %.4g (raw %.4g)", p_holm, p),
  threshold_or_band = if (row == "H3") "Holm p < 0.05 (A4b; D fixed)" else
    sprintf("|e| >= %s; null band (%s, %s); plausibility > %s", fmt(row, threshold), fmt(row, -threshold), fmt(row, threshold), fmt(row, 1.5 * abs(b0))),
  verdict, rule = paste0("§8 rule ", rule, if (plausibility_flag) "; plausibility flag (A8)" else "",
                         if (discordant) "; Holm/Bonferroni discordance" else "")) |> ungroup()
h2row <- tibble(claim = "H2-all", estimate = paste(sprintf("%.2f", pr$est[pr$row %in% c("H2-SEA-pt", "H2-IND-pt", "H2-MOZ-pt")]), collapse = " / "),
                interval = "member -pt rows", test_p = paste("Holm", paste(sprintf("%.4g", pr$p_holm[pr$row %in% c("H2-SEA-pt", "H2-IND-pt", "H2-MOZ-pt")]), collapse = " / ")),
                threshold_or_band = "all three Delta < 0 with Holm p < 0.05 (A8 strict comparative)", verdict = hv$h2[1], rule = paste0("§8 H2-all rule ", hv$h2[2]))
verdict <- bind_rows(vt[1:8, ], h2row, vt[9, ])
write_csv(verdict, file.path(out, "verdict.csv")); print(verdict, width = 250)

# ---- sensitivity 12: -rel rows judged against the literal prose magnitudes (reported only) ---------------
alt <- c(`H1-rel` = log(1.51), `H2-SEA-rel` = log(0.80), `H2-IND-rel` = log(0.71), `H2-MOZ-rel` = log(0.79))
s12 <- pr |> filter(row %in% names(alt)) |> rowwise() |>
  mutate(b0_alt = alt[[row]], v = paste(verdict_ptrel(est, b0_alt, p_holm, ci_lo, ci_hi, fail), collapse = " / rule ")) |> ungroup() |>
  transmute(sens = "12", label = "-rel rows against literal prose magnitudes (51, 20 SE Asian, 29 Indian, 21 per cent)", row, est, se, p = p_holm,
            ci_lo, ci_hi, n = 1802, G = 43, status = "ok", note = sprintf("b0_alt = %.4f; would-be verdict: %s", b0_alt, v))
sens <- read_csv(file.path(out, "sensitivities.csv"), show_col_types = FALSE, col_types = cols(sens = "c")) |> filter(sens != "12")
sens <- bind_rows(sens, s12)

# ---- sensitivity 20: verdict-category changes per deletion ------------------------------------------------
loo <- read_csv(file.path(out, "s20_loo.csv"), show_col_types = FALSE)
G <- 43; q <- qt(1 - ALPHA / M_FAM / 2, G - 2)
vc <- loo |> group_by(volume) |> group_modify(function(x, key) {
  pp <- tibble(row = ROWS9) |> left_join(x, by = "row") |>
    mutate(fail = !is.finite(est) | !is.finite(p), ci_lo = est - q * se, ci_hi = est + q * se)
  r <- holm_verdicts(pp |> select(row, est, p, ci_lo, ci_hi, fail))
  bind_rows(r$pr |> select(row, verdict), tibble(row = "H2-all", verdict = r$h2[1]))
}) |> ungroup()
base <- bind_rows(pr |> select(row, verdict), tibble(row = "H2-all", verdict = hv$h2[1])) |> rename(v0 = verdict)
chg <- vc |> left_join(base, by = "row") |> mutate(changed = verdict != v0)
s20 <- chg |> group_by(row) |> summarise(deletions = n(), to = paste(unique(verdict[changed]), collapse = "; "),
  volumes = paste(volume[changed], collapse = ","), n_changed = sum(changed), .groups = "drop")
write_csv(s20, file.path(out, "s20_verdict_changes.csv")); print(s20, width = 200)
sens <- sens |> filter(!(sens == "20" & label == "leave-one-court-volume-out: verdict-category changes")) |>
  bind_rows(s20 |> transmute(sens = "20", label = "leave-one-court-volume-out: verdict-category changes", row, status = "ok",
                             note = sprintf("%d of %d deletions change the category%s", n_changed, deletions, ifelse(n_changed > 0, paste0(" (to ", to, "; ", volumes, ")"), ""))))
write_csv(sens, file.path(out, "sensitivities.csv"))
