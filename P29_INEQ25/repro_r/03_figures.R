# P29_INEQ25 -- S3 independent recreation, step 3: figures 1-6 (LEAP style)
# Reads output/*.csv written by 02_analysis.R; writes output/fig*_r.pdf/.png (300 dpi).

suppressPackageStartupMessages(library(tidyverse))
PROJ <- "."
OUT  <- file.path(PROJ, "P29_INEQ25", "repro_r", "output")

LEAP_CYCLE <- c("#5C2346", "#3D8EB9", "#6B8E5E", "#D4A03E", "#A34466", "#45808B", "#8B6B3D", "#97C5B0")
theme_leap <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = "sans") %+replace%
    theme(axis.line.x.bottom = element_line(color = "#4A4A4A", linewidth = 0.8),
          axis.line.y.left = element_line(color = "#4A4A4A", linewidth = 0.8),
          panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5),
          panel.grid.major.x = element_blank(), panel.grid.minor = element_blank(),
          axis.ticks = element_line(color = "#4A4A4A", linewidth = 0.6),
          legend.position = "bottom", legend.title = element_blank(),
          plot.background = element_rect(fill = "#FFFFFF", color = NA),
          strip.text = element_text(size = 10, face = "bold", color = "#2D2D2D"))
}
save_fig <- function(name, p, w = 10, h = 6) {
  ggsave(file.path(OUT, paste0(name, ".png")), p, width = w, height = h, dpi = 300)
  ggsave(file.path(OUT, paste0(name, ".pdf")), p, width = w, height = h)
}
ylim01 <- scale_y_continuous(limits = c(0, 1), expand = expansion(mult = c(0, 0.02)))

# Fig 1: annual single-asset Ginis + decade total value
f1a <- read_csv(file.path(OUT, "fig1_annual_gini.csv"), show_col_types = FALSE) %>%
  filter(series %in% c("q_horses", "q_cattle", "q_sheep", "q_wheat", "q_vines", "q_wine")) %>%
  mutate(series = str_to_title(sub("q_", "", series)))
f1d <- read_csv(file.path(OUT, "fig1_decade_gini.csv"), show_col_types = FALSE) %>%
  filter(series == "total_value") %>% mutate(series = "Total value")
p1 <- ggplot() +
  geom_line(data = f1a, aes(year, gini, colour = series), linewidth = 0.4) +
  geom_line(data = f1d, aes(period, gini_avg, colour = series), linewidth = 1.2) +
  geom_point(data = f1d, aes(period, gini_avg, colour = series), size = 1.8) +
  scale_colour_manual(values = c(LEAP_CYCLE[2:7], LEAP_CYCLE[1]) |>
                        setNames(c("Horses", "Cattle", "Sheep", "Wheat", "Vines", "Wine", "Total value"))) +
  ylim01 + labs(x = "Year", y = "Gini coefficient") + theme_leap()
save_fig("fig1_r", p1)

# Fig 2: scenarios, 20-year periods
f2 <- read_csv(file.path(OUT, "fig2_period_gini.csv"), show_col_types = FALSE) %>% filter(period <= 1820) %>%
  mutate(series = recode(series, settlers = "Settlers only (no slaves)",
                         slaveassets = "Settlers + slave assets (slaves not as households)",
                         zero = "Settlers + slaves (slaves as households with zero assets)",
                         sheep12 = "Settlers + slaves (slaves with 12 sheep/year)"))
p2 <- ggplot(f2, aes(period, gini_avg, colour = series, linetype = series)) +
  geom_line(linewidth = 1) + geom_point(size = 1.8) +
  scale_colour_manual(values = LEAP_CYCLE[c(1, 2, 3, 4)]) + ylim01 +
  labs(x = "Period", y = "Gini coefficient") + theme_leap() +
  guides(colour = guide_legend(ncol = 2), linetype = guide_legend(ncol = 2))
save_fig("fig2_r", p2)

# Fig 3: district cross-section c.1825
f3 <- read_csv(file.path(OUT, "fig3_district_gini.csv"), show_col_types = FALSE) %>% filter(!is.na(gini)) %>%
  mutate(asset = factor(str_to_title(asset), levels = c("Cattle", "Horses", "Oxen", "Sheep", "Wheat", "Wine")))
p3 <- ggplot(f3, aes(district, gini, size = rel_size)) +
  geom_point(colour = LEAP_CYCLE[1], alpha = 0.8) + facet_wrap(~asset, ncol = 2) + ylim01 +
  scale_size_area(max_size = 6, guide = "none") + labs(x = "District", y = "Gini coefficient") +
  theme_leap() + theme(axis.text.x = element_text(angle = 45, hjust = 1))
save_fig("fig3_r", p3, h = 8)

# Fig 4: probates
f4 <- read_csv(file.path(OUT, "fig4_probate_gini.csv"), show_col_types = FALSE) %>% mutate(asset = str_to_title(asset))
p4 <- ggplot(f4, aes(decade, gini, colour = asset, linetype = asset)) + geom_line(linewidth = 1) +
  scale_colour_manual(values = LEAP_CYCLE[1:5]) + ylim01 + labs(x = "Period", y = "Gini coefficient") + theme_leap()
save_fig("fig4_r", p4)

# Fig 5: emancipation valuation vs compensation
f5 <- read_csv(file.path(OUT, "fig5_emancipation_gini.csv"), show_col_types = FALSE) %>%
  filter(!district %in% c("Clanwilliam", "Swellendam"), measure != "owners_comp_zeros") %>%
  separate(measure, c("grp", "what"), sep = "_") %>% select(district, grp, what, gini) %>%
  pivot_wider(names_from = what, values_from = gini) %>%
  mutate(grp = recode(grp, owners = "Excluding non-slave-owning settlers", all = "Including non-slave-owning settlers"))
p5 <- ggplot(f5, aes(val, comp, colour = grp, shape = grp)) + geom_point(size = 2.5) +
  geom_text(aes(label = district), size = 2.8, vjust = -0.8, show.legend = FALSE) +
  scale_colour_manual(values = c("#2D2D2D", LEAP_CYCLE[2])) + ylim01 + scale_x_continuous(limits = c(0, 1)) +
  labs(x = "Gini coefficient (Valuation)", y = "Gini coefficient (Compensation)") + theme_leap()
save_fig("fig5_r", p5)

# Fig 6: Khoe settlements
f6 <- read_csv(file.path(OUT, "fig6_khoe_gini.csv"), show_col_types = FALSE) %>% filter(!is.na(gini)) %>%
  mutate(asset = recode(str_to_title(asset), Wheat = "Wheat reaped"))
p6 <- ggplot(f6, aes(settlement, gini)) + geom_point(colour = LEAP_CYCLE[1], size = 3) +
  facet_wrap(~asset, ncol = 2) + ylim01 + labs(x = "Settlement", y = "Gini coefficient") + theme_leap()
save_fig("fig6_r", p6, h = 8)
cat("03_figures.R done\n")
