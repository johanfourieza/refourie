# P11_FJS S3 recreation, step 3: Images 7, 8 and 9 in LEAP style (PDF + PNG 300 dpi).

library(tidyverse)
library(here)
source(here("tools", "paths.R"))

PAPER <- "P11_FJS"
out_dir <- here(PAPER, "repro_r", "output")

LEAP_CYCLE <- c("#5C2346", "#3D8EB9", "#6B8E5E", "#D4A03E", "#A34466", "#45808B", "#8B6B3D", "#97C5B0")
theme_leap <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = "sans") %+replace%
    theme(
      plot.title = element_text(size = 11, face = "bold", color = "#2D2D2D", margin = margin(b = 12), hjust = 0),
      axis.title = element_text(size = 10, color = "#4A4A4A"),
      axis.text = element_text(size = 9, color = "#5A5A5A"),
      legend.text = element_text(size = 9), legend.title = element_blank(), legend.position = "bottom",
      axis.line.x.bottom = element_line(color = "#4A4A4A", linewidth = 0.8),
      axis.line.y.left = element_line(color = "#4A4A4A", linewidth = 0.8),
      panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5),
      panel.grid.major.x = element_blank(), panel.grid.minor = element_blank(),
      axis.ticks = element_line(color = "#4A4A4A", linewidth = 0.6),
      plot.background = element_rect(fill = "#FFFFFF", color = NA),
      plot.margin = margin(10, 10, 10, 10)
    )
}
save_fig <- function(name, p, w = 7, h = 4.5) {
  ggsave(file.path(out_dir, paste0(name, ".pdf")), p, width = w, height = h)
  ggsave(file.path(out_dir, paste0(name, ".png")), p, width = w, height = h, dpi = 300)
}

img7 <- read_csv(file.path(out_dir, "image7_components.csv"), show_col_types = FALSE)
dec <- read_csv(file.path(out_dir, "image9_decile_shares.csv"), show_col_types = FALSE)
hh <- readRDS(dpath(PAPER, "repro_r", "_scratch", "hh_tax.rds"))

# Image 7: tax streams (pacht and foreign sales not available)
p7 <- img7 |>
  select(year, `Poll tax` = poll, `Wine tax` = wine_tax, `Grain tax` = grain, `Meat tax` = meat,
         `Property tax` = property) |>
  pivot_longer(-year) |>
  mutate(name = fct_inorder(name), year = factor(year)) |>
  ggplot(aes(year, value, fill = name)) +
  geom_col(width = 0.7) +
  scale_fill_manual(values = LEAP_CYCLE) +
  scale_y_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.05))) +
  labs(x = NULL, y = "Guilders") +
  theme_leap()
save_fig("image7_tax_streams", p7)

# Image 8: four household taxes by number of slaves, Image 7 years pooled
p8 <- hh |>
  filter(year %in% img7$year, slaves <= 49) |>
  group_by(slaves) |>
  summarise(Poll = sum(poll), Wheat = sum(grain), Wine = sum(wine), Meat = sum(meat)) |>
  pivot_longer(-slaves) |>
  filter(value > 0) |>
  mutate(name = fct_inorder(name)) |>
  ggplot(aes(slaves, value, colour = name)) +
  geom_line(linewidth = 0.8) +
  scale_colour_manual(values = LEAP_CYCLE) +
  scale_y_log10(labels = scales::comma) +
  labs(x = "Number of slaves", y = "Guilders (log scale)") +
  theme_leap()
save_fig("image8_tax_by_slaves", p8)

# Image 9: shares by slave-owning decile (equal spacing of years, as in the paper)
p9 <- dec |>
  mutate(decile = factor(decile, levels = 10:1), year = factor(year)) |>
  ggplot(aes(year, share, fill = decile, group = decile)) +
  geom_area(aes(x = as.integer(year)), position = "stack", colour = "white", linewidth = 0.2) +
  scale_x_continuous(breaks = 1:7, labels = levels(factor(dec$year))) +
  scale_fill_manual(values = colorRampPalette(c("#97C5B0", "#3D8EB9", "#5C2346"))(10),
                    breaks = as.character(1:10), labels = paste("Decile", 1:10)) +
  scale_y_continuous(expand = c(0, 0)) +
  labs(x = NULL, y = "Percent of household tax") +
  theme_leap() +
  guides(fill = guide_legend(nrow = 2))
save_fig("image9_decile_shares", p9)
