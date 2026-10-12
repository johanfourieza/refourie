# P16_FvFC S3 independent recreation -- 03_figures.R
# Recreates Figs 1-6 (LEAP style). Inputs: households.rds, output/*.csv from 02_analysis.R.
# Outputs: output/fig*.pdf and .png (300 dpi)

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ggplot2)
  library(patchwork)
})
source(here::here("tools", "paths.R"))
root <- here::here("P16_FvFC", "repro_r")
out  <- file.path(root, "output")

LEAP_CYCLE <- c("#5C2346", "#3D8EB9", "#6B8E5E", "#D4A03E", "#A34466", "#45808B", "#8B6B3D", "#97C5B0")
theme_leap <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = "sans") %+replace%
    theme(plot.title = element_text(size = 11, face = "bold", color = "#2D2D2D",
                                    margin = margin(b = 12), hjust = 0),
          axis.title = element_text(size = 10, color = "#4A4A4A"),
          axis.text = element_text(size = 9, color = "#5A5A5A"),
          legend.text = element_text(size = 9), legend.position = "bottom",
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
save_leap_fig <- function(name, plot, width = 10, height = 6) {
  ggsave(file.path(out, paste0(name, ".png")), plot, width = width, height = height, dpi = 300)
  ggsave(file.path(out, paste0(name, ".pdf")), plot, width = width, height = height)
}

hh  <- readRDS(dpath("P16_FvFC", "repro_r", "data", "households.rds"))
s   <- read_csv(file.path(out, "inequality_series.csv"), show_col_types = FALSE)
f5c <- read_csv(file.path(out, "fig5c_core1_gini_ci.csv"), show_col_types = FALSE)
pw  <- read_csv(file.path(out, "pca_weights_all.csv"), show_col_types = FALSE)
far <- hh |> filter(farmer)

# ---- Fig 1: slave ownership, farmers, log scale ---------------------------------
yrs6 <- c(1678, 1692, 1700, 1731, 1757)
p1 <- far |> filter(year %in% yrs6, slaves > 0) |>
  ggplot(aes(slaves, colour = factor(year))) +
  geom_density(linewidth = 0.8) + scale_x_log10() +
  scale_colour_manual(values = LEAP_CYCLE) +
  labs(x = "Total slaves (log scale; owners only)", y = "Density", colour = NULL)
save_leap_fig("fig1_slave_density", p1 + theme_leap())

# ---- Fig 2: annual vs pooled weights, core 1 -------------------------------------
p2 <- s |> filter(index == "Core (1)", slaves == "excl", weights %in% c("pooled", "annual")) |>
  pivot_longer(c(gini, theil), names_to = "measure") |>
  mutate(sample = ifelse(sample == "farmers", "Farmers only", "Incl. non-farmers"),
         series = paste(toupper(substr(measure, 1, 1)), substring(measure, 2), "-", weights)) |>
  ggplot(aes(year, value, colour = series)) + geom_line(linewidth = 0.8) + geom_point(size = 1.2) +
  facet_wrap(~sample) + scale_colour_manual(values = LEAP_CYCLE) +
  labs(x = "Year", y = "Inequality", colour = NULL)
save_leap_fig("fig2_annual_vs_pooled_core1", p2 + theme_leap())

# ---- Fig 3a: incl vs excl non-farmers, core 1 ---------------------------------------
p3 <- s |> filter(index == "Core (1)", weights == "pooled", slaves == "excl") |>
  pivot_longer(c(gini, theil), names_to = "measure") |>
  mutate(series = paste0(measure, ": ", ifelse(sample == "farmers", "excl non-farmers", "incl non-farmers"))) |>
  ggplot(aes(year, value, colour = series)) + geom_line(linewidth = 0.8) + geom_point(size = 1.2) +
  scale_colour_manual(values = LEAP_CYCLE) + labs(x = "Year", y = "Inequality", colour = NULL)
save_leap_fig("fig3a_nonfarmers_core1", p3 + theme_leap())

# ---- Fig 4: incl vs excl slaves (whole settler sample) -------------------------------
p4 <- s |> filter(index == "Core (1)", weights == "pooled", sample == "whole", slaves %in% c("incl", "excl")) |>
  pivot_longer(c(gini, theil), names_to = "measure") |>
  mutate(series = paste0(measure, ": ", slaves, " slaves")) |>
  ggplot(aes(year, value, colour = series, linetype = measure)) +
  geom_line(linewidth = 0.8) + geom_point(size = 1.2) +
  scale_colour_manual(values = LEAP_CYCLE) + guides(linetype = "none") +
  labs(x = "Year", y = "Gini / Theil", colour = NULL)
save_leap_fig("fig4_slaves", p4 + theme_leap())

# ---- Fig 5a/b: all indices, farmers, pooled; 5c: core 1 with 95% CI ------------------
f5 <- s |> filter(sample == "farmers", weights == "pooled", slaves == "excl", index != "Slaves")
p5a <- ggplot(f5, aes(year, gini, colour = index)) + geom_line(linewidth = 0.8) +
  scale_colour_manual(values = LEAP_CYCLE) + labs(title = "a", x = "Year", y = "Gini", colour = NULL)
p5b <- ggplot(f5, aes(year, theil, colour = index)) + geom_line(linewidth = 0.8) +
  scale_colour_manual(values = LEAP_CYCLE) + labs(title = "b", x = "Year", y = "Theil", colour = NULL)
p5c <- ggplot(f5c, aes(year, gini)) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "#97C5B0", alpha = 0.5) +
  geom_line(colour = "#5C2346", linewidth = 0.9) + geom_point(colour = "#5C2346", size = 1.5) +
  labs(title = "c", x = "Year", y = "Gini coefficient (core 1, 95% CI)")
p5 <- (p5a + theme_leap()) / (p5b + theme_leap()) / (p5c + theme_leap())
save_leap_fig("fig5_farmers_pooled", p5, width = 8, height = 11)
save_leap_fig("fig5c_core1_ci", p5c + theme_leap(), width = 8, height = 5)

# ---- Fig 6: distribution of per capita core 1, farmers --------------------------------
w <- pw |> filter(index == "Core (1)", sample == "farmers")
far$c1 <- as.vector(as.matrix(far[, w$item]) %*% (w$weight / w$sd)) / far$hhsize
p6 <- far |> filter(year %in% yrs6) |>
  ggplot(aes(c1, colour = factor(year), weight = hhsize)) + geom_density(linewidth = 0.8) +
  coord_cartesian(xlim = c(0, quantile(far$c1, 0.99))) +
  scale_colour_manual(values = LEAP_CYCLE) +
  labs(x = "Per capita core 1 index", y = "Density (person-weighted)", colour = NULL)
save_leap_fig("fig6_core1_distribution", p6 + theme_leap())
cat("Figures written to", out, "\n")
