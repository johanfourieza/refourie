# 07: Figures (LEAP palette). Forest plot of the primary contrasts and range plot of the assumption
# enumerations. Writes figures/*.pdf and *.png (300 dpi) and sessionInfo.txt.
source("P06_FGa/modern/00_helpers.R")
library(ggplot2)
FIG <- file.path(MOD, "figures"); dir.create(FIG, showWarnings = FALSE)
theme_leap <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = "sans") %+replace%
    theme(plot.title = element_text(size = 11, face = "bold", colour = "#2D2D2D", hjust = 0, margin = margin(b = 8)),
          axis.title = element_text(size = 10, colour = "#4A4A4A"), axis.text = element_text(size = 9, colour = "#5A5A5A"),
          axis.line.x.bottom = element_line(colour = "#4A4A4A", linewidth = 0.8), axis.line.y.left = element_line(colour = "#4A4A4A", linewidth = 0.8),
          panel.grid.major.y = element_line(colour = "#E0E0E0", linewidth = 0.5), panel.grid.major.x = element_blank(),
          panel.grid.minor = element_blank(), axis.ticks = element_line(colour = "#4A4A4A", linewidth = 0.6),
          legend.position = "bottom", legend.title = element_blank(), legend.key = element_blank(),
          plot.background = element_rect(fill = "#FFFFFF", colour = NA), panel.background = element_rect(fill = "#FFFFFF", colour = NA),
          strip.text = element_text(size = 10, face = "bold", colour = "#2D2D2D"), plot.margin = margin(10, 10, 10, 10))
}
save_fig <- function(name, p, w, h) {
  ggsave(file.path(FIG, paste0(name, ".png")), p, width = w, height = h, dpi = 300)
  ggsave(file.path(FIG, paste0(name, ".pdf")), p, width = w, height = h)
}
VCOL <- c("confirmed" = "#3D8EB9", "overturned (reversed)" = "#5C2346",
          "overturned (credible null: similar)" = "#D4A03E", "weakened" = "#6B8E5E", "not-testable" = "#AAAAAA")

pr <- read_csv(file.path(OUT, "primary.csv"), show_col_types = FALSE) |>
  filter(!(claim == "H4w" & pair == "VA-Stb")) |>
  mutate(label = paste0(claim, ": ", pair),
         panel = ifelse(claim %in% c("H1", "H2", "H3"), "Ratios, ln(Cape / US)", "Gini differences"),
         label = factor(label, levels = rev(unique(label))))
band <- tibble(panel = c("Ratios, ln(Cape / US)", "Gini differences"), b = c(LN_SIM, G_SIM))
p1 <- ggplot(pr, aes(y = label, x = estimate, colour = verdict)) +
  geom_rect(data = band, aes(xmin = -b, xmax = b, ymin = -Inf, ymax = Inf), inherit.aes = FALSE, fill = "#AAAAAA", alpha = 0.18) +
  geom_vline(xintercept = 0, colour = "#4A4A4A", linewidth = 0.4) +
  geom_errorbar(aes(xmin = ci_lo, xmax = ci_hi), orientation = "y", width = 0.12, linewidth = 0.7) +
  geom_point(size = 2.2) +
  facet_wrap(~panel, scales = "free", ncol = 2) +
  scale_colour_manual(values = VCOL, drop = TRUE) +
  labs(x = "Central-scenario estimate (Virginia contrasts: Bonferroni 99% Rao-Wu interval; enumerations: point)", y = NULL,
       title = "P06 settlers' fortunes: primary contrasts and verdicts (grey band = A8 similarity band)") +
  theme_leap() + theme(panel.grid.major.y = element_blank(), panel.grid.major.x = element_line(colour = "#E0E0E0", linewidth = 0.5))
save_fig("fig_s6_forest", p1, 10, 6)

sc <- read_csv(file.path(OUT, "ranges_scenarios.csv"), show_col_types = FALSE) |>
  mutate(label = ifelse(claim == "H5", paste0("H5: ", pair), paste0(claim, ": ln R")),
         panel = ifelse(claim == "H5", "H5 crop-Gini differences (V3 = A, B, C)", "H1 (18 scenarios), H2 (9 scenarios)"))
rg <- sc |> group_by(panel, label) |> summarise(lo = min(estimate), hi = max(estimate), cen = estimate[central][1], .groups = "drop")
p2 <- ggplot(rg, aes(y = label)) +
  geom_vline(xintercept = 0, colour = "#4A4A4A", linewidth = 0.4) +
  geom_segment(aes(x = lo, xend = hi, yend = label), colour = "#3D8EB9", linewidth = 2.2, alpha = 0.6) +
  geom_point(data = sc, aes(x = estimate), colour = "#6B8E5E", size = 1.2, alpha = 0.8) +
  geom_point(aes(x = cen), colour = "#5C2346", size = 2.6) +
  facet_wrap(~panel, scales = "free", ncol = 2) +
  labs(x = "Estimate across valuation scenarios (plum = central scenario; assumption-conditional, not probabilities)", y = NULL,
       title = "P06 assumption ranges (card §4.4; never verdict-determining)") +
  theme_leap() + theme(panel.grid.major.y = element_blank(), panel.grid.major.x = element_line(colour = "#E0E0E0", linewidth = 0.5))
save_fig("fig_s6_ranges", p2, 10, 6)

writeLines(c(capture.output(sessionInfo()), paste("ineq version:", packageVersion("ineq"))), file.path(MOD, "sessionInfo.txt"))
cat("Figures written\n")
