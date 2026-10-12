# P19_GF S6: range plot of annual shares and bounds against the 70% threshold (LEAP palette)
suppressPackageStartupMessages({library(dplyr); library(readr); library(ggplot2)})
OUT <- "./P19_GF/modern/output"
MOD <- dirname(OUT)
set.seed(19)
a <- read_csv(file.path(OUT, "annual_shares.csv"), show_col_types = FALSE) |>
  mutate(panel = recode(claim, H1 = "H1: railways / Fig A2 public works, 1880-1909",
                               H2 = "H2: (public works + debt) / GE, 1870-1909"),
         state = factor(state, c("above", "indeterminate", "counterexample")))
pal <- c(above = "#6B8E5E", indeterminate = "#D4A03E", counterexample = "#5C2346")
p <- ggplot(a, aes(year)) +
  geom_hline(yintercept = 70, colour = "#AAAAAA", linetype = "dashed") +
  geom_linerange(aes(ymin = s_lo, ymax = s_hi, colour = state), linewidth = 0.9) +
  geom_point(aes(y = s0, colour = state), size = 1.6) +
  facet_wrap(~panel, ncol = 1) +
  scale_colour_manual(values = pal, name = "Year state", drop = FALSE) +
  labs(x = NULL, y = "Share (%)",
       caption = "Points: unknown items set to 0. Bars: bounds with each unknown item in [0, column maximum]. Dashed line: 70%.") +
  theme_minimal(base_size = 10) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank(), strip.text = element_text(hjust = 0, face = "bold"),
        plot.caption = element_text(hjust = 0, colour = "grey30"))
ggsave(file.path(MOD, "fig_annual_shares.pdf"), p, width = 7, height = 6)
ggsave(file.path(MOD, "fig_annual_shares.png"), p, width = 7, height = 6, dpi = 300)
writeLines(capture.output(sessionInfo()), file.path(MOD, "sessionInfo.txt"))
