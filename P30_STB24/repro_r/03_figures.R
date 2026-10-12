# P30_STB24 — S3 independent recreation, step 3: figures (LEAP style)
# Input : aggregate CSVs from 02_analysis.R; households.rds (D: scratch) for Figure 7
# Output: repro_r/output/fig*.pdf and .png (300 dpi)

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
  library(patchwork)
  library(ggridges)
  library(igraph)
  library(ggraph)
})
here::i_am("P30_STB24/repro_r/03_figures.R")
source(here("tools", "paths.R"))
set.seed(20261011)

PAPER <- "P30_STB24"
OUT   <- here(PAPER, "repro_r", "output")

# ---- LEAP visual identity ------------------------------------------------------
LEAP_CYCLE <- c("#5C2346", "#3D8EB9", "#6B8E5E", "#D4A03E", "#A34466", "#45808B", "#8B6B3D", "#97C5B0")
theme_leap <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = "sans") %+replace%
    theme(
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
      plot.background = element_rect(fill = "#FFFFFF", color = NA),
      panel.background = element_rect(fill = "#FFFFFF", color = NA),
      plot.margin = ggplot2::margin(10, 10, 10, 10),
      strip.text = element_text(size = 10, face = "bold", color = "#2D2D2D")
    )
}
save_leap_fig <- function(name, plot, width = 10, height = 6, dpi = 300) {
  ggsave(file.path(OUT, paste0(name, ".png")), plot, width = width, height = height, dpi = dpi)
  ggsave(file.path(OUT, paste0(name, ".pdf")), plot, width = width, height = height)
}
ASSET_LAB <- c(horses = "Horses", sheep = "Sheep", cattle = "Cattle",
               wheat = "Wheat", barley = "Barley", wine = "Wine")
ASSET_COL <- setNames(LEAP_CYCLE[1:6], ASSET_LAB)

# ---- Figure 2: coverage by harmonised variable ----------------------------------
cov <- read_csv(file.path(OUT, "fig2_coverage.csv"), show_col_types = FALSE)
ord <- cov |> group_by(variable) |> summarise(tot = sum(count)) |> arrange(tot) |> pull(variable)
f2 <- ggplot(cov |> mutate(variable = factor(variable, levels = ord)),
             aes(year, variable, fill = count)) +
  geom_tile(height = 0.9) +
  scale_fill_gradient(low = "#F3E9EF", high = "#5C2346", trans = "sqrt", name = "Count") +
  scale_x_continuous(breaks = seq(1685, 1845, 20), expand = c(0, 0)) +
  labs(x = "Year", y = NULL) + theme_leap() + theme(legend.title = element_text(size = 9))
save_leap_fig("fig2_coverage", f2, height = 7)

# ---- Figure 3: top-twelve surnames by decade ------------------------------------
f3d <- read_csv(file.path(OUT, "fig3_surname_shares.csv"), show_col_types = FALSE)
f3 <- ggplot(f3d, aes(decade, share_all, colour = surname)) +
  geom_line(linewidth = 0.8) + geom_point(size = 1.4) +
  scale_colour_manual(values = c(LEAP_CYCLE, "#7A0019", "#AAAAAA", "#2D2D2D", "#C9B37E")) +
  scale_x_continuous(breaks = seq(1700, 1830, 10)) +
  labs(x = "Decade", y = "Percentage of all households with a surname", colour = NULL) +
  theme_leap() + theme(legend.position = "right")
save_leap_fig("fig3_surnames", f3)
f3b <- f3 + aes(y = share_top12) + labs(y = "Percentage within the twelve surnames")
save_leap_fig("fig3_surnames_within_top12", f3b)

# ---- Figure 4: marriage-pair network ---------------------------------------------
p100 <- read_csv(file.path(OUT, "fig4_top100_pairs.csv"), show_col_types = FALSE)
g <- graph_from_data_frame(p100 |> transmute(from = hk, to = wk, weight = n), directed = FALSE)
f4 <- ggraph(g, layout = "fr") +
  geom_edge_link(aes(width = weight), colour = "#3D8EB9", alpha = 0.5) +
  geom_edge_loop(aes(width = weight), colour = "#5C2346", alpha = 0.7) +
  geom_node_point(colour = "#5C2346", size = 2) +
  geom_node_text(aes(label = name), size = 2.6, repel = TRUE) +
  scale_edge_width(range = c(0.2, 2.5), name = "Couples") +
  theme_void() + theme(plot.background = element_rect(fill = "white", colour = NA))
save_leap_fig("fig4_marriage_network", f4, height = 8)

# ---- Figure 5: observations and per-household index (1795 = 1) -------------------
f5d <- read_csv(file.path(OUT, "fig5_index.csv"), show_col_types = FALSE)
f5a <- ggplot(f5d, aes(year, n_obs)) + geom_col(fill = "#5C2346", width = 0.8) +
  scale_x_continuous(limits = c(1683, 1846), breaks = seq(1685, 1845, 20)) +
  labs(x = NULL, y = "Number of obs") + theme_leap()
f5b <- f5d |> select(year, all_of(names(ASSET_LAB))) |>
  pivot_longer(-year, names_to = "asset") |> filter(!is.na(value), value > 0) |>
  mutate(asset = ASSET_LAB[asset]) |>
  ggplot(aes(year, value, colour = asset)) + geom_line(linewidth = 0.6) +
  geom_hline(yintercept = 1, colour = "#AAAAAA", linetype = "dashed") +
  scale_y_log10(labels = scales::label_number(drop0trailing = TRUE)) +
  scale_colour_manual(values = ASSET_COL) +
  scale_x_continuous(limits = c(1683, 1846), breaks = seq(1685, 1845, 20)) +
  labs(x = "Year", y = "Indexed value (log scale, 1795 = 1)", colour = NULL) +
  theme_leap() + theme(legend.position = "bottom")
save_leap_fig("fig5_index", f5a / f5b + plot_layout(heights = c(1, 2.2)), height = 7)

# ---- Figure 6: Gini by year --------------------------------------------------------
f6d <- read_csv(file.path(OUT, "fig6_gini.csv"), show_col_types = FALSE) |>
  filter(!is.na(gini)) |> mutate(asset = ASSET_LAB[asset])
f6 <- ggplot(f6d, aes(year, gini, colour = asset)) + geom_line(linewidth = 0.6) +
  scale_colour_manual(values = ASSET_COL) +
  scale_x_continuous(breaks = seq(1685, 1845, 20)) +
  coord_cartesian(ylim = c(0.3, 1)) +
  labs(x = "Year", y = "Gini coefficient", colour = NULL) +
  theme_leap() + theme(legend.position = "bottom")
save_leap_fig("fig6_gini", f6)
f6s <- f6 + aes(y = gini_pos) + coord_cartesian(ylim = c(0, 1)) +
  labs(y = "Gini coefficient (positive values only)")
save_leap_fig("fig6_gini_positive_only", f6s)

# ---- Figure 7: enslaved people per household, two-decade bins (log scale) --------
hh <- readRDS(dscratch(PAPER, "repro_r", "households.rds"))
f7d <- hh |> filter(year <= 1838) |>
  mutate(bin = 1680 + floor((year - 1680) / 20) * 20) |>
  select(bin, slave_men, slave_women, slave_boys, slave_girls) |>
  pivot_longer(-bin, names_to = "type", values_to = "n") |> filter(!is.na(n)) |>
  mutate(type = factor(type, levels = c("slave_men", "slave_women", "slave_boys", "slave_girls"),
                       labels = c("Enslaved men", "Enslaved women", "Enslaved boys", "Enslaved girls")))
f7 <- ggplot(f7d, aes(x = n + 1, y = factor(bin), height = after_stat(density))) +
  geom_density_ridges(stat = "binline", bins = 25, scale = 0.95, fill = "#5C2346",
                      colour = "white", alpha = 0.85) +
  scale_x_log10(breaks = c(1, 2, 3, 6, 11, 31, 101), labels = c(0, 1, 2, 5, 10, 30, 100)) +
  facet_wrap(~ type, ncol = 2) +
  labs(x = "Number of enslaved people per household (log scale)", y = "Two-decade period") +
  theme_leap()
save_leap_fig("fig7_slave_ridges", f7, height = 8)
cat("Figures written to", OUT, "\n")
