# P02_BoF10 S6 figures (LEAP palette): (1) surrogate null of F with F_obs; (2) range plot of surrogate p across primary, sensitivities and calibration size
source(here::here("P02_BoF10", "modern", "00_common.R"))
LEAP <- c(plum = "#5C2346", blue = "#3D8EB9", sage = "#6B8E5E", gold = "#D4A03E", grey = "#AAAAAA")
th <- theme_minimal(base_size = 10) + theme(panel.grid.minor = element_blank(), plot.title = element_text(face = "bold", colour = LEAP[["plum"]]))
dr <- readRDS(dscratch("P02_BoF10", "modern", "primary_draws.rds")); pr <- read_csv(file.path(OUT, "primary.csv"), show_col_types = FALSE) |> filter(deciding)
nulls <- read_csv(here("P02_BoF10", "compare", "s5_checks", "null_authors_filter_p5.csv"), show_col_types = FALSE)
dd <- bind_rows(tibble(F = dr$F, null = "Phase surrogates of WHEATMF22 (primary)"), tibble(F = nulls$F, null = "Independent filtered random walks (S5)"))
g1 <- ggplot(dd, aes(F, fill = null)) + geom_density(alpha = .6, colour = NA) + scale_x_log10() +
  geom_vline(xintercept = pr$F_obs, colour = LEAP[["plum"]], linewidth = .8) + geom_vline(xintercept = c(4.01, 7.84), colour = LEAP[["grey"]], linetype = 2) +
  annotate("text", x = pr$F_obs, y = Inf, vjust = 1.5, hjust = -.05, label = sprintf("F = %.2f", pr$F_obs), colour = LEAP[["plum"]], size = 3) +
  scale_fill_manual(values = unname(LEAP[c("blue", "gold")])) + labs(x = "Bounds F (log scale)", y = "Density", fill = NULL,
  title = "Ships -> wheat (T4_r3): F against two independence nulls") + th + theme(legend.position = "bottom")
ggsave(here("P02_BoF10", "modern", "fig_null.pdf"), g1, width = 6.5, height = 4); ggsave(here("P02_BoF10", "modern", "fig_null.png"), g1, width = 6.5, height = 4, dpi = 300)
se <- read_csv(file.path(OUT, "sensitivities.csv"), show_col_types = FALSE) |> filter(!is.na(p_s))
pp <- bind_rows(tibble(label = "Primary: phase surrogates, p = 5 (B = 9,999)", p_s = pr$p_s, lo = pr$p_lo, hi = pr$p_hi, grp = "Primary"),
  se |> transmute(label = paste0("S", sens, ": ", label), p_s, lo = p_lo, hi = p_hi, grp = ifelse(sens == "11", "H4 context (never votes)", "Sensitivity")))
pp$label <- factor(pp$label, levels = rev(pp$label))
g2 <- ggplot(pp, aes(p_s, label, colour = grp)) + geom_vline(xintercept = c(.01, .05), colour = LEAP[["grey"]], linetype = 2) +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0) + geom_point(size = 2) + scale_x_log10(limits = c(5e-5, 1)) +
  scale_colour_manual(values = c(Primary = LEAP[["plum"]], Sensitivity = LEAP[["blue"]], `H4 context (never votes)` = LEAP[["sage"]])) +
  labs(x = "Surrogate p-value (log scale)", y = NULL, colour = NULL, title = "Surrogate p-values: primary and sensitivities",
       caption = "Calibration (report-only): the B = 199 surrogate test rejects in about 47% of independent-series replications at 1%.") + th + theme(legend.position = "bottom")
ggsave(here("P02_BoF10", "modern", "fig_pvalues.pdf"), g2, width = 7.5, height = 5); ggsave(here("P02_BoF10", "modern", "fig_pvalues.png"), g2, width = 7.5, height = 5, dpi = 300)
