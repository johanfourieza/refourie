# P13_FS S6 04_verdicts.R -- verdict tables of card section 8 applied mechanically; primary.csv, sensitivities.csv, figure.
suppressMessages({library(dplyr); library(readr); library(ggplot2)})
source(here::here("tools", "paths.R"))
scr <- dscratch("P13_FS", "modern"); md <- here::here("P13_FS", "modern"); out <- file.path(md, "output")
h1 <- readRDS(file.path(scr, "h1.rds")); h2 <- read_csv(file.path(out, "H2_primary.csv"), show_col_types = FALSE)
h3 <- read_csv(file.path(out, "H3_ext.csv"), show_col_types = FALSE)
band <- function(x, lo, hi) if (!is.finite(x)) c("not-testable", 0) else if (x >= lo && x <= hi) c("confirmed", 1) else if (x < lo) c("qualified", 2) else c("qualified", 3)
vc <- band(h1$C, 18.801, 22.979); vl <- band(h1$L, 23.202, 28.358)
pm <- h1$prim
nt <- function(cl, why) tibble(claim = cl, estimate = NA_character_, interval = NA_character_, test_p = NA_character_, threshold_or_band = why, verdict = "not-testable", rule = "§1/§8")
V <- bind_rows(
  tibble(claim = "H1-cons (T5_r9_full_pct = 20.89)", estimate = sprintf("C = %.2f%%", h1$C), interval = "point (no inference)", test_p = "",
         threshold_or_band = "A8a band [18.801, 22.979]", verdict = vc[1], rule = vc[2]),
  tibble(claim = "H1-land (T5_r10_full_pct = 25.78)", estimate = sprintf("L = %.2f%%", h1$L), interval = "point (no inference)", test_p = "",
         threshold_or_band = "A8a band [23.202, 28.358]", verdict = vl[1], rule = vl[2]),
  tibble(claim = "H1-main (land largest purpose, purpose-recorded rows, bonds as land)",
         estimate = sprintf("min Delta_c = %.2f pp (vs %s)", min(pm$delta), pm$competitor[which.min(pm$delta)]),
         interval = sprintf("smallest simultaneous lower bound %.2f (vs %s); all 21 lower bounds > 0", min(pm$lo), pm$competitor[which.min(pm$lo)]),
         test_p = "", threshold_or_band = "all 21 Bonferroni intervals (0.0125/21 per tail) > 0; B = 49,999, undefined draws 0",
         verdict = h1$v_main, rule = as.character(h1$rule_main)),
  tibble(claim = "H2-mag (T6A_slaves_nom_coef = 0.087)", estimate = sprintf("b = %.4f (N %d)", h2$b, h2$N),
         interval = "HC3 undefined (h_ii = 1 for MOOC8/2.33, sole 1700s obs)", test_p = "HC3 undefined",
         threshold_or_band = "same sign, p < 0.025, b >= 0.0435; null if CI in (-0.0435, 0.0435)", verdict = h2$verdict, rule = as.character(h2$rule)),
  nt("H1-all (shares of all borrowing)", "65% of debt-side rows lack a purpose"),
  nt("H1-bond (land debts contracted through bonds)", "bond purpose not recorded; paper allocation"),
  nt("H2-causal (slave ownership a driver)", "no exogenous variation"),
  nt("H3-mag (T6B_wealth_nom_coef = 0.0185)", "6-variable PCA and N 251 sample unrecoverable"),
  nt("H3-pct (1.85% per percentage point)", "as H3-mag"),
  nt("H3-benefit (rich, not poor, benefited)", "welfare not measured"),
  tibble(claim = "H3-ext (3-variable wealth index)", estimate = sprintf("b = %.4f (N %d)", h3$b, h3$N), interval = "HC3 undefined (max leverage 1)",
         test_p = "", threshold_or_band = "never votes", verdict = "different-estimand", rule = "§8"))
write_csv(V, file.path(out, "verdict.csv")); write_csv(V, file.path(md, "verdicts.csv"))
prim <- bind_rows(
  tibble(row = c("H1-cons", "H1-land"), quantity = c("C", "L"), estimate = c(h1$C, h1$L), lo = NA, hi = NA, n = h1$n_spec, note = "share of purpose-recorded rows"),
  tibble(row = "H1-main", quantity = paste("Delta vs", pm$competitor), estimate = pm$delta, lo = pm$lo, hi = pm$hi, n = h1$n_spec, note = "simultaneous percentile CI"),
  tibble(row = "H2-mag", quantity = "b_slaves", estimate = h2$b, lo = h2$ci_lo, hi = h2$ci_hi, n = h2$N,
         note = sprintf("HC3 SE %s; t_conv %.2f, t_HC1 %.2f; max leverage %.4f", h2$se_hc3, h2$t_conv, h2$t_hc1, h2$max_leverage)),
  tibble(row = "H3-ext", quantity = "b_wealth_pct", estimate = h3$b, lo = h3$ci_lo, hi = h3$ci_hi, n = h3$N, note = "different-estimand; HC3 undefined"))
write_csv(prim, file.path(out, "primary.csv"))
s1 <- read_csv(file.path(out, "sensitivities_H1.csv"), show_col_types = FALSE) |> mutate(across(everything(), as.character))
s2 <- read_csv(file.path(out, "sensitivities_H2H3.csv"), show_col_types = FALSE) |> mutate(across(everything(), as.character))
write_csv(bind_rows(mutate(s1, block = "H1"), mutate(s2, block = "H2/H3")), file.path(out, "sensitivities.csv"))
# figure: H1-main contrasts with simultaneous intervals (LEAP palette)
pm$competitor <- factor(pm$competitor, levels = pm$competitor[order(pm$delta)])
g <- ggplot(pm, aes(y = competitor, x = delta)) + geom_vline(xintercept = 0, colour = "#AAAAAA") +
  geom_errorbar(aes(xmin = lo, xmax = hi), width = 0, orientation = "y", colour = "#3D8EB9", linewidth = 0.7) +
  geom_point(colour = "#5C2346", size = 2) +
  labs(x = "Land share minus competitor share (percentage points)", y = NULL,
       caption = "Purpose-recorded debt rows (n = 4,122), bonds allocated to land. Bars: simultaneous 97.5% intervals (Bonferroni over 21 contrasts),\ninventory-cluster bootstrap, B = 49,999.") +
  theme_minimal(base_size = 10) + theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(), plot.caption = element_text(hjust = 0, size = 7), plot.caption.position = "plot")
ggsave(file.path(out, "fig_H1_contrasts.pdf"), g, width = 6.5, height = 4.5); ggsave(file.path(out, "fig_H1_contrasts.png"), g, width = 6.5, height = 4.5, dpi = 300)
writeLines(capture.output(sessionInfo()), file.path(md, "sessionInfo.txt"))
print(as.data.frame(V[, c("claim", "estimate", "verdict", "rule")]))
