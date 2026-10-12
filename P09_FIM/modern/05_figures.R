# P09_FIM S6 05_figures.R. Forest plot (LEAP palette): top, Family D T2 contrasts (verdict rows T2-dec, T2-min);
# below, Family T recruit-pattern contrasts (no verdict) with the published col 1 values and selected sensitivities
# (grey; reported, never deciding). Bars are simultaneous 95% intervals. Outputs: output/fig_s6_forest.{pdf,png}
source("./P09_FIM/modern/00_common.R")
suppressPackageStartupMessages(library(ggplot2))
theme_leap <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = "sans") %+replace%
    theme(axis.title = element_text(size = 10, color = "#4A4A4A"), axis.text = element_text(size = 9, color = "#5A5A5A"),
          axis.line.x.bottom = element_line(color = "#4A4A4A", linewidth = 0.8), panel.grid.major.y = element_blank(),
          panel.grid.major.x = element_line(color = "#E0E0E0", linewidth = 0.5), panel.grid.minor = element_blank(),
          axis.ticks.x = element_line(color = "#4A4A4A", linewidth = 0.6), legend.position = "none",
          plot.background = element_rect(fill = "#FFFFFF", color = NA), panel.background = element_rect(fill = "#FFFFFF", color = NA),
          plot.margin = margin(10, 10, 10, 10), strip.text = element_text(size = 10, face = "bold", color = "#2D2D2D", hjust = 0),
          plot.caption = element_text(size = 8, colour = "#5A5A5A", hjust = 0))
}
PO <- readRDS(file.path(OUT, "primary_objects.rds"))
se <- read_csv(file.path(OUT, "sensitivities.csv"), show_col_types = FALSE)
labD <- c(e1 = "e1  1865-74 minus 1895-1904", e2 = "e2  1875-84 minus 1895-1904", e3 = "e3  1885-94 minus 1895-1904",
          e5 = "e5  1905-14 minus 1895-1904", e6 = "e6  1915-20 minus 1895-1904")
labT <- c(b65 = "R-65  b(1865-74)", b15 = "R-15  b(1915-20)", d1 = "R-dec d1 = b(1865-74) - b(1875-84)",
          d2 = "R-dec d2 = b(1875-84)", d3 = "R-dec d3 = -b(1895-1904)", r = "R-rec r = b(1915-20) - b(1895-1904)")
keep <- c(S2c = "S2c + Attestation", S4 = "S4 strict 160.02", S6a = "S6a interval-rounded", S9 = "S9 age quadratic",
          S10b = "S10b shrinkage 0.10", S11 = "S11 heteroskedastic", S15a = "S15a CR1 force x year",
          S15b = "S15b cluster bootstrap", S16 = "S16 birth year - 1")
pD <- PO$fD %>% transmute(panel = "A. T2 raw-mean contrasts (Family D; verdict rows)", item = labD[contrast], est, lo, hi, src = "Surviving vintage")
pT <- bind_rows(
  tibble(item = labT[c("b65", "b15")], est = unname(B0), lo = NA, hi = NA, src = "Published col 1"),
  se %>% filter(sens %in% names(keep), contrast %in% names(labT), is.finite(est)) %>%
    transmute(item = labT[contrast], est, lo, hi, src = keep[sens]),
  PO$ft %>% transmute(item = labT[contrast], est, lo, hi, src = "Modern primary")) %>%
  mutate(panel = "B. Recruit-pattern contrasts (Family T; no verdict)")
lev_src <- rev(c("Surviving vintage", "Published col 1", "Modern primary", unname(keep)))
pts <- bind_rows(pD, pT) %>% mutate(src = factor(src, levels = lev_src),
                                    item = factor(item, levels = c(labD, labT)))
cols <- c(`Surviving vintage` = "#3D8EB9", `Published col 1` = "#D4A03E", `Modern primary` = "#5C2346",
          setNames(rep("#AAAAAA", length(keep)), keep))
p <- ggplot(pts, aes(x = est, y = src, colour = src)) +
  geom_vline(xintercept = 0, colour = "#4A4A4A", linewidth = 0.3) +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.25, linewidth = 0.6, na.rm = TRUE) +
  geom_point(size = 2) +
  facet_wrap(~ item, ncol = 2, scales = "free_y") +
  scale_colour_manual(values = cols) +
  labs(x = "cm", y = NULL, caption = paste(
    "Surviving data vintage (S3 sample), not the published sample. A (blue): unweighted cohort mean differences, simultaneous 95% sup-t intervals (Family D).",
    "\nB: truncated-normal ML, c = 159.385 cm, force FE and age 21/22 dummies, sandwich SE; simultaneous 95% intervals (Family T, rank-4 c_T).",
    "\nGrey: sensitivities (reported; never deciding), each with its own simultaneous interval. Gold: published Table 3 col 1 (a different estimand).")) +
  theme_leap()
ggsave(file.path(OUT, "fig_s6_forest.png"), p, width = 10, height = 12, dpi = 300, bg = "white")
ggsave(file.path(OUT, "fig_s6_forest.pdf"), p, width = 10, height = 12)
