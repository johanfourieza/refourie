# P10_FI  S3 independent recreation  --  03_figures.R
# Figure 3 (annual share of interracial marriages, dashed line at 1949) and,
# for reference, Figure 6 (mean parish segregation by year). LEAP style.
# Uses only aggregate files written by 01/02 plus the scratch microdata for Fig 6.

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})
set.seed(20191001)
proj <- here::here()
source(file.path(proj, "tools", "paths.R"))
pdir <- file.path(proj, "P10_FI", "repro_r")
odir <- file.path(pdir, "output")

LEAP_COLORS <- c(plum = "#5C2346", blue = "#3D8EB9", sage = "#6B8E5E", gold = "#D4A03E")
theme_leap <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = "sans") %+replace%
    theme(
      plot.title = element_text(size = 11, face = "bold", color = "#2D2D2D", margin = margin(b = 12), hjust = 0),
      axis.title = element_text(size = 10, color = "#4A4A4A"),
      axis.text = element_text(size = 9, color = "#5A5A5A"),
      axis.line.x.bottom = element_line(color = "#4A4A4A", linewidth = 0.8),
      axis.line.y.left = element_line(color = "#4A4A4A", linewidth = 0.8),
      panel.border = element_blank(),
      panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5),
      panel.grid.major.x = element_blank(), panel.grid.minor = element_blank(),
      axis.ticks = element_line(color = "#4A4A4A", linewidth = 0.6),
      axis.ticks.length = unit(3, "pt"),
      legend.background = element_blank(), legend.key = element_blank(),
      plot.background = element_rect(fill = "#FFFFFF", color = NA),
      panel.background = element_rect(fill = "#FFFFFF", color = NA),
      plot.margin = margin(10, 10, 10, 10))
}
save_leap_fig <- function(fig_path, plot, width = 10, height = 6, dpi = 600) {
  ggsave(sub("\\.[^.]+$", ".png", fig_path), plot, width = width, height = height, dpi = dpi)
  ggsave(sub("\\.[^.]+$", ".pdf", fig_path), plot, width = width, height = height)
}

# Figure 3
ann <- read_csv(file.path(odir, "fig3_annual_share.csv"), show_col_types = FALSE)
f3 <- ggplot(ann, aes(year, share)) +
  geom_line(colour = "#5C2346", linewidth = 0.9) +
  geom_point(colour = "#5C2346", size = 1.6) +
  geom_vline(xintercept = 1949, linetype = "dashed", colour = "#AAAAAA") +
  scale_x_continuous(breaks = seq(1910, 1960, 10)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05)), limits = c(0, NA)) +
  labs(x = "Year of marriage", y = "Interracial marriages (% of all marriages)") +
  theme_leap()
save_leap_fig(file.path(odir, "fig3_share_interracial.png"), f3)

# Figure 6 (reference): mean parish segregation by year, unweighted across parishes
d <- readRDS(dscratch("P10_FI", "repro_r", "p10_clean.rds"))
seg <- d %>% filter(year >= 1909, year <= 1973, !is.na(segregation)) %>%
  distinct(parish, year, segregation) %>% group_by(year) %>%
  summarise(mean_seg = mean(segregation), n_parish = n(), .groups = "drop")
write_csv(seg, file.path(odir, "fig6_mean_segregation.csv"))
f6 <- ggplot(seg, aes(year, mean_seg)) +
  geom_line(colour = "#5C2346", linewidth = 0.9) +
  geom_vline(xintercept = 1949, linetype = "dashed", colour = "#AAAAAA") +
  labs(x = "Year of marriage", y = "Racial concentration by parish (HHI)") +
  theme_leap()
save_leap_fig(file.path(odir, "fig6_mean_segregation.png"), f6)
cat("Figures written.\n")
