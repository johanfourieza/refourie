# P29_INEQ25 S6 step 5: figures (LEAP palette) and sessionInfo. Run after 03 and 04.
# Run: Rscript P29_INEQ25/modern/05_figures.R
source("P29_INEQ25/modern/00_functions.R")
suppressPackageStartupMessages(library(ggplot2))
plum <- "#5C2346"; blue <- "#3D8EB9"; sage <- "#6B8E5E"; gold <- "#D4A03E"; grey <- "#AAAAAA"
th <- theme_minimal(base_size = 11) + theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
  axis.line = element_line(colour = "black", linewidth = 0.3), legend.position = "bottom", plot.title = element_blank())
save2 <- function(p, f, w, h) { ggsave(file.path(OUT, paste0(f, ".pdf")), p, width = w, height = h, device = cairo_pdf)
  ggsave(file.path(OUT, paste0(f, ".png")), p, width = w, height = h, dpi = 300) }
pr <- read_csv(file.path(OUT, "primary.csv"), show_col_types = FALSE)
se <- read_csv(file.path(OUT, "sensitivities.csv"), show_col_types = FALSE)

# Figure 1: H1 decade Ginis with the 98.75% sup-t band (household-cluster bootstrap) against the 0.60 threshold
h1 <- pr |> filter(claim == "H1") |> mutate(decade = as.numeric(sub("decade ", "", node)))
p1 <- ggplot(h1, aes(decade, estimate)) +
  geom_hline(yintercept = 0.60, colour = gold, linewidth = 0.7, linetype = "dashed") +
  geom_ribbon(aes(ymin = L, ymax = U), fill = blue, alpha = 0.25) +
  geom_line(colour = plum, linewidth = 0.8) + geom_point(colour = plum, size = 1.8) +
  annotate("text", x = 1692, y = 0.607, label = "Threshold 0.60", hjust = 0, vjust = 0, colour = "black", size = 3.2) +
  scale_x_continuous(breaks = seq(1690, 1830, 20)) + scale_y_continuous(limits = c(0.55, 0.9), breaks = seq(0.55, 0.9, 0.05)) +
  labs(x = "Decade", y = "Gini, five-asset basket (household-years pooled)") + th
save2(p1, "fig1_H1_supt_band", 7, 4.2)

# Figure 2: point claims (H2, H3a) with 98.75% percentile intervals and their bands; H3b assets as points
# (H3b family undefined under the card's 1% rule; the S-h bands for assets with >= 10 holders are report-only, in grey)
pts <- bind_rows(
  pr |> filter(claim %in% c("H2", "H3a")) |> transmute(label = c("H2: zero-asset scenario, 1780-99", "H3a: Bethelsdorp 1814 cattle"), estimate, L, U,
                                                     lo = c(0.89, 0.69), hi = c(0.95, 0.75), type = "Verdict interval (98.75%)"),
  se |> filter(grepl("^S-h H3b on assets", section), quantity != "rule outcome (not a verdict)") |>
    transmute(label = paste("H3b:", recode(sub(" .*", "", quantity), BD = "Bethelsdorp", GK = "Groenekloof", SR = "Swartrivier"), sub("^[A-Z]+ ", "", quantity)),
              estimate, L, U, lo = NA, hi = NA, type = "S-h band, report only (98.75% sup-t)"),
  se |> filter(grepl("^S-h excluded", section), is.finite(estimate)) |>
    transmute(label = paste("H3b:", recode(sub(" .*", "", quantity), BD = "Bethelsdorp", GK = "Groenekloof", SR = "Swartrivier"), sub("^[A-Z]+ ", "", quantity), "(< 10 holders)"),
              estimate, L = NA, U = NA, lo = NA, hi = NA, type = "Point only (< 10 positive holders)"))
pts$label <- factor(pts$label, levels = rev(pts$label))
p2 <- ggplot(pts, aes(y = label)) +
  geom_tile(data = filter(pts, !is.na(lo)), aes(x = (lo + hi) / 2, width = hi - lo), height = 0.7, fill = gold, alpha = 0.35) +
  geom_vline(xintercept = 0.75, colour = grey, linetype = "dashed") +
  geom_errorbar(aes(xmin = L, xmax = U, colour = type), width = 0.25, orientation = "y", na.rm = TRUE) +
  geom_point(aes(x = estimate, colour = type), size = 2) +
  scale_colour_manual(values = c("Verdict interval (98.75%)" = plum, "S-h band, report only (98.75% sup-t)" = blue, "Point only (< 10 positive holders)" = sage), name = NULL) +
  scale_x_continuous(limits = c(0.6, 1.02), breaks = seq(0.6, 1, 0.05)) +
  labs(x = "Gini coefficient", y = NULL) + th + theme(panel.grid.major.y = element_blank()) + guides(colour = guide_legend(nrow = 2))
save2(p2, "fig2_point_claims_H2_H3", 7.5, 5.5)

writeLines(capture.output(sessionInfo()), file.path("P29_INEQ25", "modern", "sessionInfo.txt"))
cat("figures written\n")
