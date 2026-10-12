# P09_FIM — S3 independent recreation. 03_figures.R
# Fig. 2 (mean height by birth year, all forces) and the Table 3 cohort coefficients for the
# columns the allow-listed data support (SAC, CMP, AOF, WW1). Aggregates only.

suppressPackageStartupMessages(library(tidyverse))
source(file.path(here::here(), "tools", "paths.R"))
set.seed(20221)

root    <- file.path(here::here(), "P09_FIM", "repro_r")
out_dir <- file.path(root, "output")
s <- readRDS(dscratch("P09_FIM", "repro_r", "analysis_sample.rds"))

# ---- LEAP visual identity -------------------------------------------------------
theme_leap <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = "sans") %+replace%
    theme(
      plot.title = element_text(size = 11, face = "bold", color = "#2D2D2D",
                                margin = margin(b = 12), hjust = 0),
      axis.title = element_text(size = 10, color = "#4A4A4A"),
      axis.text = element_text(size = 9, color = "#5A5A5A"),
      legend.text = element_text(size = 9),
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
      plot.margin = margin(10, 10, 10, 10),
      strip.text = element_text(size = 10, face = "bold", color = "#2D2D2D"))
}
save_leap_fig <- function(fig_path, plot, width = 10, height = 6, dpi = 300) {
  ggsave(sub("\\.[^.]+$", ".png", fig_path), plot, width = width, height = height, dpi = dpi)
  ggsave(sub("\\.[^.]+$", ".pdf", fig_path), plot, width = width, height = height)
}

# ---- Fig. 2: mean height by birth year (cells with >= 10 recruits) ---------------
f2 <- s %>% group_by(birthyear) %>%
  summarise(n = n(), m = mean(height), se = sd(height) / sqrt(n), .groups = "drop") %>%
  filter(n >= 10)
write_csv(f2 %>% mutate(across(c(m, se), ~ round(.x, 3))), file.path(out_dir, "fig2_r.csv"))
p2 <- ggplot(f2, aes(birthyear, m)) +
  geom_ribbon(aes(ymin = m - 1.96 * se, ymax = m + 1.96 * se), fill = "#97C5B0", alpha = 0.5) +
  geom_line(colour = "#5C2346", linewidth = 0.9) +
  geom_point(colour = "#5C2346", size = 1.4) +
  labs(x = "Birth year", y = "Mean height (cm)") +
  theme_leap()
save_leap_fig(file.path(out_dir, "fig2_height_by_birthyear_r.png"), p2)

# ---- Table 3 cohort coefficients, reproducible columns ---------------------------
fits <- read_csv(file.path(out_dir, "trunc_models_r.csv"), show_col_types = FALSE)
lab <- c(c3 = "SAC (ref. 1875-84)", c4 = "CMP (ref. 1875-84)",
         c5 = "AOF (ref. 1875-84)", c6 = "WW1 (ref. 1895-1904)")
cc <- fits %>% filter(weighted, model %in% names(lab), str_detect(term, "^cohort"), se < 5) %>%
  mutate(cohort = str_replace(str_remove(term, "^cohort"), "_", "-"), col = lab[model])
p3 <- ggplot(cc, aes(cohort, est, colour = col)) +
  geom_hline(yintercept = 0, colour = "#AAAAAA") +
  geom_pointrange(aes(ymin = est - 1.96 * se, ymax = est + 1.96 * se),
                  position = position_dodge(width = 0.5)) +
  scale_colour_manual(values = c("#5C2346", "#3D8EB9", "#D4A03E", "#45808B")) +
  labs(x = "Birth cohort", y = "Coefficient (cm), 95% CI", colour = NULL) +
  theme_leap() + theme(legend.position = "bottom")
save_leap_fig(file.path(out_dir, "fig_t3_cohort_coefs_r.png"), p3)
cat("figures written\n")
