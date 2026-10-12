# P18_FvFS - S3 independent recreation - 03_figures.R
# Figure 2 analogue: mean household per capita wine output by group, 1700-73
# (household-size weighted: sum wine / sum household members), LEAP style.

suppressPackageStartupMessages({ library(tidyverse); library(here) })
set.seed(20261011)
root <- here("P18_FvFS"); od <- file.path(root, "repro_r", "output"); source(here("tools", "paths.R"))
s <- readRDS(dpath("P18_FvFS", "repro_r", "data", "farmers.rds"))

theme_leap <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = "sans") %+replace%
    theme(axis.title = element_text(size = 10, color = "#4A4A4A"),
          axis.text = element_text(size = 9, color = "#5A5A5A"),
          legend.text = element_text(size = 9), legend.position = "bottom",
          axis.line.x.bottom = element_line(color = "#4A4A4A", linewidth = 0.8),
          axis.line.y.left = element_line(color = "#4A4A4A", linewidth = 0.8),
          panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5),
          panel.grid.major.x = element_blank(), panel.grid.minor = element_blank(),
          axis.ticks = element_line(color = "#4A4A4A", linewidth = 0.6),
          plot.background = element_rect(fill = "#FFFFFF", color = NA),
          panel.background = element_rect(fill = "#FFFFFF", color = NA),
          plot.margin = ggplot2::margin(10, 10, 10, 10))
}
save_leap_fig <- function(fig_path, plot, width, height, dpi = 600) {
  ggsave(sub("\\.[^.]+$", ".png", fig_path), plot, width = width, height = height, dpi = dpi)
  ggsave(sub("\\.[^.]+$", ".pdf", fig_path), plot, width = width, height = height)
}

f2 <- s %>% group_by(jaar, group) %>% summarise(wine = sum(wine) / sum(hhsize), .groups = "drop") %>%
  mutate(group = recode(group, NH = "Non-Huguenot", NWH = "Huguenot from non-wine region",
                        WH = "Huguenot from wine region"))
write_csv(f2, file.path(od, "figure2_series.csv"))
fig <- ggplot(f2, aes(jaar, wine, colour = group, linetype = group)) +
  geom_line(linewidth = 1) + geom_point(size = 2) +
  scale_colour_manual(values = c("Non-Huguenot" = "#5C2346", "Huguenot from non-wine region" = "#3D8EB9",
                                 "Huguenot from wine region" = "#D4A03E")) +
  scale_x_continuous(breaks = seq(1700, 1780, 10), limits = c(1690, 1780)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
  labs(x = NULL, y = "Leaguers per household member", colour = NULL, linetype = NULL) +
  theme_leap()
save_leap_fig(file.path(od, "figure2_recreation.png"), fig, width = 10, height = 6)
