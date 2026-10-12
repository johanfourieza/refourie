# P07_FG S3 independent recreation -- 03_figures.R
# Figure 2 analogue: baseline Khoesan population series (text p.203) and the
# opgaaf-based estimate of Khoesan farm labourers (Table 1), plus a Table 1
# Khoesan-vs-slaves chart. LEAP style.

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})
source(here::here("tools", "paths.R"))

PAPER <- "P07_FG"
out_dir <- here::here(PAPER, "repro_r", "output")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- LEAP visual identity ---------------------------------------------------
theme_leap <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = "sans") %+replace%
    theme(
      text = element_text(family = "sans"),
      plot.title = element_text(size = 11, face = "bold", color = "#2D2D2D",
                                margin = ggplot2::margin(b = 12), hjust = 0),
      axis.title = element_text(size = 10, color = "#4A4A4A"),
      axis.text = element_text(size = 9, color = "#5A5A5A"),
      legend.text = element_text(size = 9),
      axis.line.x.bottom = element_line(color = "#4A4A4A", linewidth = 0.8),
      axis.line.y.left = element_line(color = "#4A4A4A", linewidth = 0.8),
      panel.border = element_blank(),
      panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5),
      panel.grid.major.x = element_blank(),
      panel.grid.minor = element_blank(),
      axis.ticks = element_line(color = "#4A4A4A", linewidth = 0.6),
      axis.ticks.length = unit(3, "pt"),
      legend.background = element_blank(), legend.key = element_blank(),
      legend.position = "bottom",
      plot.background = element_rect(fill = "#FFFFFF", color = NA),
      panel.background = element_rect(fill = "#FFFFFF", color = NA),
      plot.margin = ggplot2::margin(10, 10, 10, 10))
}
save_leap_fig <- function(fig_path, plot, width, height, dpi = 600) {
  ggsave(sub("\\.[^.]+$", ".png", fig_path), plot, width = width, height = height, dpi = dpi)
  ggsave(sub("\\.[^.]+$", ".pdf", fig_path), plot, width = width, height = height)
}

# ---- data -------------------------------------------------------------------
t1   <- read_csv(file.path(out_dir, "table1_unrounded.csv"), show_col_types = FALSE)
t1ph <- read_csv(file.path(out_dir, "table1_posthoc_unrounded.csv"), show_col_types = FALSE)

# Baseline (D7): linear trend 50,000 (1652) -> 23,000/(0.8*0.95) (1780), level
# cut by 20% from 1713 and a further 5% from 1755; after 1780 the implied
# trend rate (about -0.4% p.a.) is applied.
x1780 <- 23000 / (0.8 * 0.95)
g <- log(x1780 / 50000) / (1780 - 1652)
base <- tibble(Year = 1652:1835) %>%
  mutate(trend = if_else(Year <= 1780, 50000 + (x1780 - 50000) * (Year - 1652) / 128,
                         x1780 * exp(g * (Year - 1780))),
         value = trend * if_else(Year >= 1713, 0.8, 1) * if_else(Year >= 1755, 0.95, 1),
         series = "Baseline population")

est <- bind_rows(
  t1 %>% transmute(Year, value = all_khoesan, series = "Farm labourers (ratios as stated)"),
  t1ph %>% transmute(Year, value = all_khoesan, series = "Farm labourers (post-hoc Stellenbosch ratio)"))

fig2 <- ggplot() +
  geom_line(data = base, aes(Year, value, colour = series), linewidth = 0.9) +
  geom_line(data = est, aes(Year, value, colour = series), linewidth = 0.9) +
  geom_point(data = est, aes(Year, value, colour = series), size = 1.6) +
  scale_colour_manual(values = c("Baseline population" = "#AAAAAA",
                                 "Farm labourers (ratios as stated)" = "#5C2346",
                                 "Farm labourers (post-hoc Stellenbosch ratio)" = "#3D8EB9")) +
  scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.05))) +
  labs(x = NULL, y = "Khoesan", colour = NULL) +
  theme_leap()
save_leap_fig(file.path(out_dir, "fig2_khoesan_estimates.pdf"), fig2, width = 10, height = 6)

ts <- t1 %>% select(Year, Khoesan = all_khoesan, Slaves = all_slaves) %>%
  pivot_longer(-Year, names_to = "group", values_to = "n")
figt1 <- ggplot(ts, aes(Year, n, colour = group)) +
  geom_line(linewidth = 0.9) + geom_point(size = 1.6) +
  scale_colour_manual(values = c(Khoesan = "#5C2346", Slaves = "#3D8EB9")) +
  scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.05))) +
  labs(x = NULL, y = "Persons on settler farms", colour = NULL) +
  theme_leap()
save_leap_fig(file.path(out_dir, "fig_table1_khoesan_slaves.pdf"), figt1, width = 10, height = 6)
cat("Figures written to", out_dir, "\n")
