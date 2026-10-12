# P01_BF  Baten & Fourie (2015) — S3 independent recreation, step 3: figures (LEAP style)
# Input : _scratch/p01_sample.rds, output/figure4_levels.csv
# Output: output/fig2_severe_crime.{pdf,png}, output/fig3_severe_punishment.{pdf,png},
#         output/fig4_abcc_levels.{pdf,png}, output/fig2_fig3_data.csv

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})
proj  <- here::here()
paper <- file.path(proj, "P01_BF")
source(file.path(proj, "tools", "paths.R"))
out   <- file.path(paper, "repro_r", "output")

# LEAP theme --------------------------------------------------------------------------
LEAP_CYCLE <- c("#5C2346", "#3D8EB9", "#6B8E5E", "#D4A03E", "#A34466", "#45808B", "#8B6B3D", "#97C5B0")
theme_leap <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = "sans") %+replace%
    theme(
      plot.title = element_text(size = 11, face = "bold", color = "#2D2D2D", margin = margin(b = 12), hjust = 0),
      axis.title = element_text(size = 10, color = "#4A4A4A"),
      axis.text = element_text(size = 9, color = "#5A5A5A"),
      legend.text = element_text(size = 9),
      axis.line.x.bottom = element_line(color = "#4A4A4A", linewidth = 0.8),
      axis.line.y.left = element_line(color = "#4A4A4A", linewidth = 0.8),
      panel.border = element_blank(),
      panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5),
      panel.grid.major.x = element_blank(), panel.grid.minor = element_blank(),
      axis.ticks = element_line(color = "#4A4A4A", linewidth = 0.6), axis.ticks.length = unit(3, "pt"),
      legend.background = element_blank(), legend.key = element_blank(), legend.position = "bottom",
      plot.background = element_rect(fill = "#FFFFFF", color = NA),
      panel.background = element_rect(fill = "#FFFFFF", color = NA),
      plot.margin = margin(10, 10, 10, 10)
    )
}
save_leap_fig <- function(fig_path, plot, width, height, dpi = 300) {
  ggsave(sub("\\.[^.]+$", ".png", fig_path), plot, width = width, height = height, dpi = dpi)
  ggsave(sub("\\.[^.]+$", ".pdf", fig_path), plot, width = width, height = height)
}

s <- readRDS(dscratch("P01_BF", "repro_r", "p01_sample.rds")) |> filter(!is.na(bdec), bdec >= 1670)

# Figures 2 and 3: share severe crime / severe punishment by birth decade and world region
f23 <- s |>
  mutate(region = if_else(eu == 1, "European", "Non-European")) |>
  group_by(bdec, region) |>
  summarise(sev_crime = mean(severe, na.rm = TRUE), sev_pun = mean(sevpun), n = n(), .groups = "drop")
write_csv(f23, file.path(out, "fig2_fig3_data.csv"))

line_fig <- function(var, ylab) {
  ggplot(f23, aes(bdec, .data[[var]], colour = region)) +
    geom_line(linewidth = 0.9) + geom_point(size = 1.8) +
    scale_colour_manual(values = c("Non-European" = "#5C2346", "European" = "#3D8EB9")) +
    scale_x_continuous(breaks = seq(1670, 1790, 10)) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
    labs(x = "Birth decade", y = ylab, colour = NULL) + theme_leap()
}
save_leap_fig(file.path(out, "fig2_severe_crime.pdf"), line_fig("sev_crime", "Share of severe crimes"), 8, 4.5)
save_leap_fig(file.path(out, "fig3_severe_punishment.pdf"), line_fig("sev_pun", "Share of severe punishments"), 8, 4.5)

# Figure 4: ABCC by birth region and cohort
f4 <- read_csv(file.path(out, "figure4_levels.csv"), show_col_types = FALSE) |>
  mutate(grp = factor(grp, levels = c("Europe", "South-east Asia", "India", "China", "Khoesan",
                                      "Mozambique", "Cape", "Slaves, unknown")),
         coh = factor(coh, levels = c("1650s-1740s", "1750s-1780s", "1790s")))
p4 <- ggplot(f4, aes(coh, abcc, fill = grp)) +
  geom_col(position = position_dodge2(preserve = "single", width = 0.85), width = 0.85,
           colour = "white", linewidth = 0.3) +
  scale_fill_manual(values = setNames(LEAP_CYCLE, levels(f4$grp))) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 10), expand = expansion(mult = c(0, 0.02))) +
  labs(x = NULL, y = "ABCC", fill = NULL) + theme_leap()
save_leap_fig(file.path(out, "fig4_abcc_levels.pdf"), p4, 10, 6)
cat("03_figures.R done\n")
