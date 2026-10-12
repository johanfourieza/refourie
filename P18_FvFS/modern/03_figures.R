# P18_FvFS S6 - 03_figures.R: coefficient plot. Effects shown as theta = exp(b) - 1 on a log(1 + theta) axis.
suppressPackageStartupMessages({library(tidyverse)})
root <- "./P18_FvFS"; od <- file.path(root, "modern", "output")
set.seed(20261011)
theme_leap <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = "sans") %+replace%
    theme(axis.title = element_text(size = 10, color = "#4A4A4A"), axis.text = element_text(size = 8.5, color = "#5A5A5A"),
          strip.text = element_text(size = 10, face = "bold", color = "#4A4A4A", hjust = 0),
          legend.text = element_text(size = 9), legend.position = "bottom",
          axis.line.x.bottom = element_line(color = "#4A4A4A", linewidth = 0.6),
          panel.grid.major.x = element_line(color = "#E0E0E0", linewidth = 0.4),
          panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
          axis.ticks.x = element_line(color = "#4A4A4A", linewidth = 0.5),
          plot.background = element_rect(fill = "#FFFFFF", color = NA), panel.background = element_rect(fill = "#FFFFFF", color = NA),
          panel.spacing = unit(1.2, "lines"), plot.margin = margin(10, 12, 10, 10))
}
pal <- c("Published / original code (OLS, ln(max(w, 0.001)))" = "#5C2346", "PPML primary (Bonferroni CI)" = "#D4A03E",
         "Sensitivity (95% CI)" = "#3D8EB9")
pr <- read_csv(file.path(od, "primary.csv"), show_col_types = FALSE)
vd <- read_csv(file.path(od, "verdict.csv"), show_col_types = FALSE)
se <- read_csv(file.path(od, "sensitivities.csv"), show_col_types = FALSE) |> filter(!is.na(theta))  # S4 (LPM, pp) not on theta scale
pub <- tibble(claim_id = c("T3_r2_c4", "T4_r1_c7", "T4_r1_c10"), b = c(0.751, 0.721, 1.992))
lab_claim <- c(T3_r2_c4 = "T3 col 4: WH vs non-Huguenots", T4_r1_c7 = "T4 col 7: WH vs other Huguenots",
               T4_r1_c10 = "T4 col 10: WH among born-abroad")
pd <- bind_rows(
  pub |> transmute(claim_id, row = "Published OLS, as theta", theta = exp(b) - 1, lo = NA, hi = NA, kind = names(pal)[1]),
  pr |> transmute(claim_id, row = "Original code, HC1", theta = ols_pub_theta,
                  lo = exp(ols_pub_b - 1.96 * ols_pub_se_hc1) - 1, hi = exp(ols_pub_b + 1.96 * ols_pub_se_hc1) - 1, kind = names(pal)[1]),
  pr |> transmute(claim_id, row = "PPML primary", theta, lo = ci_lo, hi = ci_hi, kind = names(pal)[2]),
  se |> transmute(claim_id, row = paste(sens_id, str_trunc(sub(" (\\[|\\(desc).*$", "", label), 44)), theta, lo = ci95_lo, hi = ci95_hi, kind = names(pal)[3])) |>
  mutate(claim = factor(lab_claim[claim_id], lab_claim), row = fct_rev(fct_inorder(row)))
ref <- vd |> transmute(claim = factor(lab_claim[claim_id], lab_claim), M,
                       tag = sprintf("%s (rule %d)", verdict, rule_number))
brks <- c(-0.25, 0, 0.25, 0.5, 1, 2, 4, 6)
fig <- ggplot(pd, aes(x = 1 + theta, y = row, colour = kind)) +
  geom_vline(xintercept = 1, colour = "#4A4A4A", linewidth = 0.4) +
  geom_vline(data = ref, aes(xintercept = 1 + M), linetype = "dashed", colour = "#8A8A8A", linewidth = 0.4) +
  geom_errorbar(aes(xmin = 1 + lo, xmax = 1 + hi), width = 0, orientation = "y", linewidth = 0.6, na.rm = TRUE) +
  geom_point(size = 2) +
  geom_text(data = ref, aes(x = Inf, y = Inf, label = tag), inherit.aes = FALSE, hjust = 1.05, vjust = 1.3, size = 3, colour = "#4A4A4A") +
  facet_wrap(~claim, ncol = 1, scales = "free_y") +
  scale_x_log10(breaks = 1 + brks, labels = paste0(round(100 * brks), "%")) +
  scale_colour_manual(values = pal) +
  labs(x = "Wine-region Huguenot effect, theta = exp(b) - 1 (log scale); dashed line = threshold M", y = NULL, colour = NULL) +
  guides(colour = guide_legend(nrow = 2)) + theme_leap()
ggsave(file.path(od, "coefplot.pdf"), fig, width = 8, height = 10)
ggsave(file.path(od, "coefplot.png"), fig, width = 8, height = 10, dpi = 300)
