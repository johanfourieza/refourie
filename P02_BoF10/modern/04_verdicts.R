# P02_BoF10 S6 verdicts: card §8 applied mechanically (rules checked in order; first applicable decides)
source(here::here("P02_BoF10", "modern", "00_common.R"))
pr <- read_csv(file.path(OUT, "primary.csv"), show_col_types = FALSE); dec <- pr |> filter(deciding)
cal <- read_csv(file.path(OUT, "calibration.csv"), show_col_types = FALSE)
rule0 <- is.na(dec$F_obs) || !is.finite(dec$F_obs) || dec$B_def == 0 || vrow(dec$p_lo) != vrow(dec$p_hi)
rule <- if (rule0) 0L else vrow(dec$p_s)
verd <- c("0" = "not-testable", "1" = "confirmed", "2" = "qualified", "3" = "weakened")[as.character(rule)]
calnote <- with(cal |> filter(alpha == 0.01), paste0("calibration (report-only) size at 1%: ", paste0(dgp, " ", sprintf("%.3f", rej), collapse = ", ")))
v <- tibble(
  claim = c("T4_r3_F (H1)", "T4_r5_F (H2)", "T5_r3_coef (H3)", "T5_r5_coef (H4)"),
  estimate = c(sprintf("F = %.3f (n_w = %d, regression n = %d; %s)", dec$F_obs, dec$n_w, dec$n_reg, dec$impl), "24.77 (published)", "2.18 (published)", "2.88 (published)"),
  interval = c(sprintf("p_s +/- 3.29 MC SE [%.5f, %.5f]; p_lo-p_hi [%.5f, %.5f]; surrogate F 99th pct %.2f", max(0, dec$p_s - 3.29 * dec$mcse), dec$p_s + 3.29 * dec$mcse, dec$p_lo, dec$p_hi, dec$q99), "", "", ""),
  test_p = c(sprintf("%.5f (stage %d, B_def = %d, f = %d)", dec$p_s, dec$stage, dec$B_def, dec$f), "", "", ""),
  threshold_or_band = c("p_s < 0.01 confirmed; 0.01-0.05 qualified; >= 0.05 weakened", "none", "none", "none"),
  verdict = c(paste0(verd, " [", dec$impl, "]"), "not-testable", "not-testable", "not-testable"),
  rule = c(paste0("§8 H1 rule ", rule, "; ", calnote), "§8 H2 (no Brunt series survives)", "§8 H3 incl. 'equally large'/'above exports' (no Brunt series)", "§8 H4 (published exports series not recoverable)"))
write_csv(v, file.path(OUT, "verdict.csv")); write_csv(v, file.path(OUT, "verdicts.csv"))
cat(sprintf("H1 %s; coverage %s/4\n", verd, if (rule == 0) 0 else 1)); print(as.data.frame(v[, c("claim", "estimate", "verdict")]))
writeLines(capture.output(sessionInfo(), cat("RNGkind:", RNGkind(), "\n")), here("P02_BoF10", "modern", "sessionInfo.txt"))
