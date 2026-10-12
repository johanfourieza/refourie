# =============================================================================
# P08_SAC  S3 independent R recreation  --  03_figures.R
# Figures 2-6 of the paper (descriptive) from the cleaned data. LEAP style.
# =============================================================================

suppressMessages(library(tidyverse))

PROJ <- Sys.getenv("REPLICATEME_ROOT",
                   ".")
source(file.path(PROJ, "tools", "paths.R"))
FIG <- file.path(PROJ, "P08_SAC", "repro_r", "output", "figures")
dir.create(FIG, showWarnings = FALSE, recursive = TRUE)
SCR <- dscratch("P08_SAC", "repro_r")
terms   <- readRDS(file.path(SCR, "sac_terms.rds"))
persons <- readRDS(file.path(SCR, "sac_persons.rds"))

# ---- LEAP visual identity ----------------------------------------------------
theme_leap <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = "sans") %+replace%
    theme(plot.title = element_text(size = 11, face = "bold", color = "#2D2D2D", hjust = 0,
                                    margin = ggplot2::margin(b = 12)),
          axis.title = element_text(size = 10, color = "#4A4A4A"),
          axis.text = element_text(size = 9, color = "#5A5A5A"),
          axis.line.x.bottom = element_line(color = "#4A4A4A", linewidth = 0.8),
          axis.line.y.left = element_line(color = "#4A4A4A", linewidth = 0.8),
          panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5),
          panel.grid.major.x = element_blank(), panel.grid.minor = element_blank(),
          axis.ticks = element_line(color = "#4A4A4A", linewidth = 0.6),
          plot.background = element_rect(fill = "#FFFFFF", color = NA),
          panel.background = element_rect(fill = "#FFFFFF", color = NA),
          plot.margin = ggplot2::margin(10, 10, 10, 10))
}
save_leap_fig <- function(name, plot, width = 10, height = 6, dpi = 600) {
  ggsave(file.path(FIG, paste0(name, ".png")), plot, width = width, height = height, dpi = dpi)
  ggsave(file.path(FIG, paste0(name, ".pdf")), plot, width = width, height = height)
}
PLUM <- "#5C2346"; BLUE <- "#3D8EB9"

# Fig 2: enlistments by year (all service terms)
f2 <- terms %>% filter(!is.na(enl_year)) %>% count(enl_year) %>%
  ggplot(aes(factor(enl_year), n)) + geom_col(fill = PLUM, width = 0.7) +
  geom_text(aes(label = n), vjust = -0.4, size = 3) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  labs(x = NULL, y = "Service terms") + theme_leap()
save_leap_fig("fig2_enlistments_by_year", f2)

# Fig 3: birth-year density (first terms)
f3 <- persons %>% filter(!is.na(birth_year), birth_year >= 1840, birth_year <= 1892) %>%
  ggplot(aes(birth_year)) + geom_density(fill = PLUM, colour = NA, alpha = 0.8) +
  labs(x = "Year of birth", y = "Density") + theme_leap()
save_leap_fig("fig3_birth_year", f3)

# Figs 4-6: means by region with 95% CIs
by_region <- function(v) persons %>% filter(!is.na(region), !is.na(.data[[v]])) %>%
  group_by(region) %>% summarise(m = mean(.data[[v]]), se = sd(.data[[v]]) / sqrt(n()), n = n(), .groups = "drop")
bar_ci <- function(df, ylab, lims) ggplot(df, aes(region, m)) +
  geom_col(fill = PLUM, width = 0.7) +
  geom_errorbar(aes(ymin = m - 1.96 * se, ymax = m + 1.96 * se), width = 0.2, colour = BLUE) +
  coord_cartesian(ylim = lims) + labs(x = NULL, y = ylab) + theme_leap() +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))
t4 <- by_region("tenure"); t5 <- by_region("height_cm"); t6 <- by_region("wage")
save_leap_fig("fig4_tenure_by_region", bar_ci(t4, "Mean length of service (days)", c(0, max(t4$m + 2 * t4$se))))
save_leap_fig("fig5_height_by_region", bar_ci(t5, "Mean height (cm)", c(168, 179)))
save_leap_fig("fig6_wage_by_region", bar_ci(t6, "Mean wage (shillings)", c(4, 5.4)))
write_csv(bind_rows(tenure = t4, height = t5, wage = t6, .id = "variable"),
          file.path(FIG, "figure_region_means.csv"))
