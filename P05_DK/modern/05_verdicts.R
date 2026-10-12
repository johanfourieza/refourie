# P05_DK S6 step 5: verdict tables of card §8 applied mechanically; primary.csv, verdict.csv and the range plot.
# Usage (project root): Rscript P05_DK/modern/05_verdicts.R
source("./P05_DK/modern/common.R")
suppressPackageStartupMessages(library(ggplot2))
cs <- read.csv(file.path(SCR, "primary_cross_section.csv")); t2 <- read.csv(file.path(SCR, "primary_t2.csv"))
cal <- read.csv(file.path(OUT, "t2_calibration_item25.csv"))
gates <- c(H1 = all(read.csv(file.path(OUT, "gate_cross_section.csv"))$pass[1]), H3 = read.csv(file.path(OUT, "gate_cross_section.csv"))$pass[2],
           H2 = read.csv(file.path(OUT, "gate_t2.csv"))$pass)

# Holm (non-voting), family {H1, H2-n, H3}
pf <- c(H1 = cs$p[cs$row == "H1"], `H2-n` = t2$p0[1], H3 = cs$p[cs$row == "H3"])
holm <- p.adjust(pf, "holm")

# ---------------------------------------------------------------- H1 and H3
v <- list()
for (rw in c("H1", "H3")) {
  r <- cs[cs$row == rw, ]; b0 <- B0[rw]
  failed <- !gates[rw] || r$inference == "not-testable" || r$fail_rule
  vd <- verdict_h13(r$b, b0, r$p, r$ci_lo, r$ci_hi, failed)
  v[[rw]] <- data.frame(claim = rw, source = c(H1 = "T1_r1_c1", H3 = "T3_r1_c1")[rw], estimate = r$b,
    interval = sprintf("[%.6g, %.6g]", r$ci_lo, r$ci_hi), ci_lo = r$ci_lo, ci_hi = r$ci_hi, test_p = r$p,
    threshold_or_band = sprintf("p < %.5f; same sign; |b| >= %.6g (0.5|b0|, b0 = %g); credible null: CI within (-%.6g, %.6g)",
                                ALPHA, 0.5 * abs(b0), b0, 0.5 * abs(b0), 0.5 * abs(b0)),
    verdict = vd[1], rule = paste0("§8 H1/H3 rule ", vd[2]), n = r$n, holm_p_nonvoting = holm[rw],
    width_ratio_nonvoting = r$width_ratio_vs_published, plausibility_flag = abs(r$b) > 1.5 * abs(b0),
    scope = c(H1 = "partial association across 1918 districts (unweighted)", H3 = "association; H3-causal not tested")[rw])
}
# ---------------------------------------------------------------- H2-n (A4b ladder) and H2-pct
calflag <- any(cal$size_above_nominal_flag)
sc2 <- "survivor count on the 1984 voters' roll; non-causal design; 'October 1918' = conceptions (July 1919 births)"
p0 <- t2$p0[1]
vn <- if (!gates["H2"] || !is.finite(p0)) c("not-testable", 0) else if (p0 < ALPHA) c("confirmed", 1) else if (p0 < 0.05) c("qualified (inference-fragile)", 2) else c("weakened", 3)
P <- t2$estimate[2]; lo <- t2$ci_lo[2]; hi <- t2$ci_hi[2]; yb <- t2$ybar[2]
vp <- if (!gates["H2"] || !is.finite(p0) || !is.finite(yb) || yb <= 0) c("not-testable", 0) else
  if (P > 0 && p0 < ALPHA) c("overturned (reversed)", 1) else if (lo > -12.5 && hi < 12.5) c("overturned (credible null)", 2) else
  if (P < 0 && p0 < ALPHA && P <= -12.5) c("confirmed", 3) else if (P < 0 && p0 < ALPHA) c("qualified (magnitude below the floor)", 4) else
  if (P < 0) c("weakened", 5) else c("weakened (direction lost)", 6)
v[["H2-n"]] <- data.frame(claim = "H2-n", source = "T2_r3_c3", estimate = t2$estimate[1], interval = sprintf("[%.6g, %.6g]", t2$ci_lo[1], t2$ci_hi[1]),
  ci_lo = t2$ci_lo[1], ci_hi = t2$ci_hi[1], test_p = p0, threshold_or_band = sprintf("randomization p(0) < %.5f (A4b ladder; estimate fixed)", ALPHA),
  verdict = vn[1], rule = paste0("§8 H2-n rule ", vn[2]), n = 108, holm_p_nonvoting = holm["H2-n"], width_ratio_nonvoting = NA,
  plausibility_flag = NA, scope = paste0(sc2, if (calflag) "; CALIBRATION FLAG: size above nominal under AR(1)" else "; item 25 calibration: no size flag"))
v[["H2-pct"]] <- data.frame(claim = "H2-pct", source = "T2_r3_c3 (text 25%)", estimate = P, interval = sprintf("[%.6g, %.6g]", lo, hi), ci_lo = lo, ci_hi = hi,
  test_p = p0, threshold_or_band = sprintf("P < 0; p(0) < %.5f; P <= -12.5%%; credible null: set within (-12.5, 12.5)", ALPHA),
  verdict = vp[1], rule = paste0("§8 H2-pct rule ", vp[2]), n = 108, holm_p_nonvoting = holm["H2-n"], width_ratio_nonvoting = NA,
  plausibility_flag = abs(P) > 37.5, scope = paste0(sc2, "; inference for theta conditional on observed ybar = ", sprintf("%.3f", yb),
                                                  if (calflag) "; CALIBRATION FLAG" else "; item 25 calibration: no size flag"))
ord <- c("not-testable", "overturned", "weakened", "qualified", "confirmed")
rk <- function(x) match(sub(" .*", "", x), ord)
h2s <- if (rk(vn[1]) <= rk(vp[1])) vn[1] else vp[1]
v[["H2"]] <- data.frame(claim = "H2 (summary)", source = "T2_r3_c3", estimate = NA, interval = "", ci_lo = NA, ci_hi = NA, test_p = p0,
  threshold_or_band = "weaker of H2-n and H2-pct", verdict = h2s, rule = "§8 Summaries", n = 108, holm_p_nonvoting = NA,
  width_ratio_nonvoting = NA, plausibility_flag = NA, scope = sc2)
for (nt in c("H2-large", "H2-short", "H3-small", "H3-causal"))
  v[[nt]] <- data.frame(claim = nt, source = "interpretation", estimate = NA, interval = "", ci_lo = NA, ci_hi = NA, test_p = NA,
    threshold_or_band = "declared not-testable at freeze (§1)", verdict = "not-testable", rule = "§8 (declared)", n = NA,
    holm_p_nonvoting = NA, width_ratio_nonvoting = NA, plausibility_flag = NA, scope = "")
verdict <- do.call(rbind, v); rownames(verdict) <- NULL
write.csv(verdict, file.path(OUT, "verdict.csv"), row.names = FALSE)
print(verdict[, c("claim", "estimate", "interval", "test_p", "verdict", "rule")], digits = 5)

# ---------------------------------------------------------------- primary.csv
prim <- rbind(
  data.frame(claim = cs$row, term = cs$term, n = cs$n, k = cs$k, estimate = cs$b, se = cs$se, df = cs$df_bm, p = cs$p, ci_lo = cs$ci_lo,
             ci_hi = cs$ci_hi, ci_level = 1 - ALPHA, inference = cs$inference, max_leverage = cs$max_leverage, se_hc2 = cs$se_hc2,
             width_ratio_vs_published = cs$width_ratio_vs_published, ybar = NA, n_components = NA, gate_pass = gates[cs$row]),
  data.frame(claim = t2$row, term = c("1[July 1919 births]", "100*theta/ybar"), n = 108, k = 21, estimate = t2$estimate, se = c(t2$se_classical[1], NA),
             df = NA, p = t2$p0, ci_lo = t2$ci_lo, ci_hi = t2$ci_hi, ci_level = 1 - ALPHA,
             inference = "randomization test, one treated cell, exact inversion (set; hull reported)", max_leverage = 1, se_hc2 = NA,
             width_ratio_vs_published = NA, ybar = t2$ybar, n_components = t2$n_components, gate_pass = gates["H2"]))
prim$holm_p_nonvoting <- c(holm["H1"], holm["H3"], holm["H2-n"], holm["H2-n"])
write.csv(prim, file.path(OUT, "primary.csv"), row.names = FALSE)

# ---------------------------------------------------------------- range plot (LEAP palette), estimates scaled by b0
sens <- read.csv(file.path(OUT, "sensitivities.csv"))
keep <- sens[sens$row %in% c("H1", "H3") & is.finite(sens$ci_lo) & sens$item != 12 & !grepl("^7$", sens$item) &
              sens$item != 13 & !grepl("log model", sens$label), ]   # log-scale coefficients are not comparable with b0
pl <- rbind(
  data.frame(row = verdict$claim[1:4], label = "Primary (corrected; Bonferroni)", est = verdict$estimate[1:4], lo = verdict$ci_lo[1:4],
             hi = verdict$ci_hi[1:4], type = "Primary"),
  data.frame(row = keep$row, label = paste0("§5.", keep$item, " ", keep$label), est = keep$estimate, lo = keep$ci_lo, hi = keep$ci_hi,
             type = ifelse(keep$a4d, "Sensitivity (A4d)", "Sensitivity")),
  data.frame(row = c("H1", "H3", "H2-n", "H2-pct"), label = "Published", est = B0[c("H1", "H3", "H2n", "H2pct")], lo = NA, hi = NA, type = "Published"))
b0m <- c(H1 = B0[["H1"]], H3 = B0[["H3"]], `H2-n` = B0[["H2n"]], `H2-pct` = B0[["H2pct"]])
pl$s <- b0m[pl$row]; pl$est_r <- pl$est / pl$s; pl$lo_r <- pmin(pl$lo, pl$hi) / pl$s; pl$hi_r <- pmax(pl$lo, pl$hi) / pl$s
pl$lo_r2 <- pmin(pl$lo_r, pl$hi_r); pl$hi_r2 <- pmax(pl$lo_r, pl$hi_r)
pl$row <- factor(pl$row, levels = c("H1", "H3", "H2-n", "H2-pct"))
pl$id <- ave(seq_len(nrow(pl)), pl$row, FUN = function(z) rev(seq_along(z)))
theme_leap <- function(base_size = 10) theme_minimal(base_size = base_size, base_family = "sans") %+replace% theme(
  plot.title = element_text(size = 11, face = "bold", color = "#2D2D2D", hjust = 0, margin = margin(b = 8)),
  axis.title = element_text(size = 10, color = "#4A4A4A"), axis.text = element_text(size = 7.5, color = "#5A5A5A"),
  axis.line.x.bottom = element_line(color = "#4A4A4A", linewidth = 0.8), axis.line.y.left = element_line(color = "#4A4A4A", linewidth = 0.8),
  panel.grid.major.y = element_blank(), panel.grid.major.x = element_line(color = "#E0E0E0", linewidth = 0.5), panel.grid.minor = element_blank(),
  axis.ticks = element_line(color = "#4A4A4A", linewidth = 0.6), legend.title = element_blank(), legend.position = "bottom",
  plot.background = element_rect(fill = "#FFFFFF", color = NA), strip.text = element_text(size = 10, face = "bold", color = "#2D2D2D", hjust = 0),
  strip.text.y = element_text(angle = 0, size = 10, face = "bold", color = "#2D2D2D", hjust = 0))
g <- ggplot(pl, aes(y = reorder(paste(row, label), id), x = est_r, colour = type)) +
  geom_vline(xintercept = 0, colour = "#4A4A4A", linewidth = 0.4) +
  geom_vline(xintercept = c(0.5, -0.5), colour = "#D4A03E", linetype = "dashed", linewidth = 0.5) +
  geom_vline(xintercept = 1, colour = "#AAAAAA", linetype = "dotted", linewidth = 0.5) +
  geom_errorbar(aes(xmin = lo_r2, xmax = hi_r2), width = 0, orientation = "y", linewidth = 0.6, na.rm = TRUE) +
  geom_point(aes(shape = type), size = 1.8) +
  scale_colour_manual(values = c(Primary = "#5C2346", Sensitivity = "#3D8EB9", `Sensitivity (A4d)` = "#6B8E5E", Published = "#AAAAAA")) +
  scale_shape_manual(values = c(Primary = 16, Sensitivity = 16, `Sensitivity (A4d)` = 17, Published = 4)) +
  scale_y_discrete(labels = function(z) sub("^(H1|H3|H2-n|H2-pct) ", "", z)) +
  facet_grid(row ~ ., scales = "free_y", space = "free_y") +
  labs(x = "Estimate / published value (1 = published; dashed = 50% floor; intervals at Bonferroni level 1 - 0.05/3)", y = NULL) +
  theme_leap()
ggsave(file.path(OUT, "fig_range_plot.png"), g, width = 10, height = 9, dpi = 300)
ggsave(file.path(OUT, "fig_range_plot.pdf"), g, width = 10, height = 9)
cat("05_verdicts done\n")
