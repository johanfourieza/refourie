# 03_figures.R -- P21_LFG S6 figure: annual HEC centres with the Bonferroni cluster-bootstrap band (LEAP palette).
suppressMessages({library(dplyr); library(readr); library(ggplot2); library(here)})
MOD <- here::here("P21_LFG", "modern")
P <- read_csv(file.path(MOD, "output", "primary.csv"), show_col_types = FALSE) |>
  mutate(panel = factor(claim, c("F7", "F8", "F9"),
    c("F7: family labour and slaves", "F8: family labour and khoe", "F9: slaves and khoe")))
pal <- c("F7" = "#5C2346", "F8" = "#3D8EB9", "F9" = "#6B8E5E")
g <- ggplot(P, aes(year, centre, colour = claim)) +
  geom_hline(yintercept = 0, colour = "#AAAAAA", linewidth = .4) +
  geom_errorbar(aes(ymin = L, ymax = U), width = 0, linewidth = .5, alpha = .8) +
  geom_point(aes(shape = status), size = 1.9) +
  scale_shape_manual(values = c("supported positive" = 16, "unsupported" = 1, "supported nonpositive" = 4), name = NULL) +
  scale_colour_manual(values = pal, guide = "none") +
  facet_wrap(~panel, ncol = 1, scales = "free_y") +
  labs(x = NULL, y = "Annual median household HEC") +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(), legend.position = "bottom",
        strip.text = element_text(hjust = 0, face = "bold"), axis.line.x = element_line(colour = "#AAAAAA"))
ggsave(file.path(MOD, "fig_annual_bands.pdf"), g, width = 6.5, height = 7.5)
ggsave(file.path(MOD, "fig_annual_bands.png"), g, width = 6.5, height = 7.5, dpi = 300)
writeLines(capture.output(sessionInfo()), file.path(MOD, "sessionInfo.txt"))
