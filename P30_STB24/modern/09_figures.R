# P30_STB24 S6 step 9: figures of the primary results (LEAP palette), PDF + PNG 300 dpi.
source("P30_STB24/modern/00_common.R")
suppressPackageStartupMessages(library(ggplot2))
FIG <- file.path(MOD, "figures"); dir.create(FIG, showWarnings = FALSE)
PLUM <- "#5C2346"; BLUE <- "#3D8EB9"; SAGE <- "#6B8E5E"; GOLD <- "#D4A03E"; GREY <- "#AAAAAA"
theme_leap <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(), axis.title = element_text(size = 9),
        strip.text = element_text(face = "bold", hjust = 0), legend.position = "bottom", plot.title.position = "plot")
save2 <- function(p, name, w, h) { ggsave(file.path(FIG, paste0(name, ".pdf")), p, width = w, height = h)
  ggsave(file.path(FIG, paste0(name, ".png")), p, width = w, height = h, dpi = 300, bg = "white") }
catcol <- c(C = SAGE, Q = BLUE, D = GOLD, W = GREY, O = PLUM, NT = GREY)

# H2: per-asset ratio M_L / M_E with the Family H2 interval and the A8 band
p2 <- fread(file.path(OUT, "h2_primary.csv"))
p2[, asset := factor(asset, levels = rev(ASSETS))]
g2 <- ggplot(p2, aes(y = asset)) +
  annotate("rect", xmin = 0.8, xmax = 1.25, ymin = -Inf, ymax = Inf, fill = GREY, alpha = 0.25) +
  geom_vline(xintercept = 1, colour = GREY, linewidth = 0.3) +
  geom_errorbarh(aes(xmin = ratio_lo, xmax = ratio_hi, colour = category), height = 0.2, linewidth = 0.6) +
  geom_point(aes(x = ratio, colour = category), size = 2.2) +
  scale_x_log10() + coord_cartesian(xlim = c(0.05, 20)) + scale_colour_manual(values = catcol, name = "Category (card s8)") +
  labs(x = "Mean of annual means, 1790s / 1700s (log scale; 99.17% two-stage percentile-t)", y = NULL,
       title = "H2: per-household holdings, first vs last decade of the eighteenth century",
       subtitle = "Shaded: 'stagnation or marginal decline' band [0.80, 1.25]. Axis cut at 0.05-20 (barley interval: 0.0008 to 9e11)") + theme_leap
save2(g2, "fig_h2_assets", 6.5, 3.6)

# H3: annual Ginis with the 95% sup-t band
a3 <- fread(file.path(OUT, "h3_assetyears.csv"))
g3 <- ggplot(a3, aes(x = year)) + geom_ribbon(aes(ymin = L, ymax = U), fill = BLUE, alpha = 0.3) +
  geom_line(aes(y = G), colour = PLUM, linewidth = 0.4) + geom_hline(yintercept = 0.4, colour = GOLD, linetype = 2) +
  facet_wrap(~ factor(asset, levels = ASSETS), ncol = 3) + coord_cartesian(ylim = c(0.3, 1)) +
  labs(x = NULL, y = "Gini (zeros included)", title = "H3: annual Ginis per asset with a 95% simultaneous (sup-t) band",
       subtitle = "Dashed: the stated lower bound 0.4") + theme_leap + theme(panel.grid.major.y = element_line(colour = "grey92"))
save2(g3, "fig_h3_gini", 6.5, 4.2)

# H4: annual wine Gini and window means
w4 <- fread(file.path(OUT, "h4_wine_gini_annual.csv")); p4 <- fread(file.path(OUT, "h4_primary.csv"))
seg <- data.table(x0 = c(min(w4$year), 1780, 1790), x1 = c(1779, 1789, max(w4$year)),
                  y = c(p4$Gbar_Pre[1], p4$Gbar_Peak[1], p4$Gbar_Post[1]))
g4 <- ggplot(w4, aes(year, G)) + geom_line(colour = GREY, linewidth = 0.4) + geom_point(colour = BLUE, size = 0.8) +
  geom_segment(data = seg, aes(x = x0, xend = x1, y = y, yend = y), colour = PLUM, linewidth = 1, inherit.aes = FALSE) +
  labs(x = NULL, y = "Gini of wine (leaguers; entries > 1,000 set missing)",
       title = "H4: wine-output inequality, annual Ginis and window means (Pre < 1780, Peak 1780s, Post > 1789)") +
  theme_leap + theme(panel.grid.major.y = element_line(colour = "grey92"))
save2(g4, "fig_h4_winegini", 6.5, 3.4)

# H5: contrasts with the Family H5 interval
p5 <- fread(file.path(OUT, "h5_primary.csv"))
p5[, panel := fifelse(row == "H5a", "H5a: mean men minus mean women (W) or children (C), per owner household",
                      "H5b, H5c: changes in shares")]
p5[, contrast := factor(contrast, levels = rev(contrast))]
g5 <- ggplot(p5, aes(y = contrast)) + geom_vline(xintercept = 0, colour = GREY) +
  geom_errorbarh(aes(xmin = lo, xmax = hi, colour = category), height = 0.25, linewidth = 0.6) +
  geom_point(aes(x = estimate, colour = category), size = 1.8) +
  facet_wrap(~ panel, scales = "free", ncol = 1) +
  scale_colour_manual(values = c(claimed = SAGE, includes0_pt_claimed = BLUE, includes0_pt_not = GOLD, opposite = PLUM, undefined = GREY),
                      name = "CI relative to the claimed side") +
  labs(x = "Estimate (99.74% two-stage percentile-t)", y = NULL, title = "H5: slave ownership among owner households (Fig 7 population)") +
  theme_leap
save2(g5, "fig_h5_slavery", 6.5, 6)
