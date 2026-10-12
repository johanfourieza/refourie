# P06_FGa S3 recreation -- 03_figures.R
# Analogues of Figure 5 (cattle per farmer, by district) and Figure 6 (crop value, Cape vs US). See D19.
suppressPackageStartupMessages({ library(tidyverse) })
PROJ <- "."
source(file.path(PROJ, "tools", "paths.R"))
PAPER <- "P06_FGa"
OUT <- file.path(PROJ, PAPER, "repro_r", "output")
SCR <- dscratch(PAPER, "repro_r")
hh <- readRDS(file.path(SCR, "households.rds")); prices <- readRDS(file.path(SCR, "prices.rds"))

LEAP_CYCLE <- c("#5C2346", "#3D8EB9", "#6B8E5E", "#D4A03E", "#A34466", "#45808B", "#8B6B3D", "#97C5B0")
theme_leap <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = "sans") %+replace%
    theme(axis.title = element_text(size = 10, color = "#4A4A4A"), axis.text = element_text(size = 9, color = "#5A5A5A"),
          axis.line.x.bottom = element_line(color = "#4A4A4A", linewidth = 0.8),
          axis.line.y.left = element_line(color = "#4A4A4A", linewidth = 0.8),
          panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5),
          panel.grid.major.x = element_blank(), panel.grid.minor = element_blank(),
          axis.ticks = element_line(color = "#4A4A4A", linewidth = 0.6), legend.position = "none",
          plot.background = element_rect(fill = "#FFFFFF", color = NA),
          strip.text = element_text(size = 10, face = "bold", color = "#2D2D2D"))
}
save_leap_fig <- function(path, plot, width = 10, height = 6, dpi = 600) {
  ggsave(sub("\\.[^.]+$", ".png", path), plot, width = width, height = height, dpi = dpi)
  ggsave(sub("\\.[^.]+$", ".pdf", path), plot, width = width, height = height)
}

P <- prices %>% filter(spec == "P1")
p <- function(ct, it) { v <- P$price[P$country == ct & P$item == it]; if (length(v) == 0) 0 else v }
f <- hh %>% filter(farmer) %>% mutate(
  crop_val = ifelse(country == "Cape Colony",
    wheat * p("Cape Colony", "wheat") + barley * p("Cape Colony", "barley") + rye * p("Cape Colony", "rye") + oats * p("Cape Colony", "oats"),
    wheat * p("United States", "wheat") + barley * p("United States", "barley") + rye * p("United States", "rye") +
      oats * p("United States", "oats") + corn * p("United States", "corn")),
  cropwine_val = crop_val + wine * p("Cape Colony", "wine") + brandy * p("Cape Colony", "brandy"))

# Figure 5 analogue
fig5 <- f %>% filter(cattle > 0) %>%
  ggplot(aes(district, cattle, fill = country)) +
  geom_violin(alpha = 0.35, colour = NA, scale = "width") +
  geom_boxplot(width = 0.18, outlier.size = 0.3, outlier.alpha = 0.3) +
  scale_y_log10() + scale_fill_manual(values = LEAP_CYCLE[1:2]) +
  labs(x = "District", y = "Cattle (logarithmic)") + theme_leap()
save_leap_fig(file.path(OUT, "fig5_cattle_by_district.png"), fig5)

# Figure 6 analogue
d6 <- f %>% filter(district != "Virginia") %>%
  pivot_longer(c(crop_val, cropwine_val), names_to = "measure") %>% filter(value > 0) %>%
  mutate(measure = recode(measure, crop_val = "Crops (US$)", cropwine_val = "Crops + wine (US$)"))
fig6 <- ggplot(d6, aes(country, value, fill = country)) +
  geom_violin(alpha = 0.35, colour = NA, scale = "width") +
  geom_boxplot(width = 0.18, outlier.size = 0.3, outlier.alpha = 0.3) +
  facet_wrap(~measure, scales = "free_y") + scale_y_log10() +
  scale_fill_manual(values = LEAP_CYCLE[1:2]) + labs(x = NULL, y = NULL) + theme_leap()
save_leap_fig(file.path(OUT, "fig6_crop_value_by_country.png"), fig6)
cat("Figures written.\n")
