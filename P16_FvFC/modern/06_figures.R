# P16_FvFC S6 -- 06_figures.R: (1) forest plot of the family rows, (2) the central farmer Gini series
# with central-bootstrap intervals and the settler-slave gap. LEAP palette.
# Outputs: output/fig_s6_forest.{pdf,png}, output/fig_s6_series.{pdf,png}

source(here::here("P16_FvFC", "modern", "00_common.R"))
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
pr <- read_csv(file.path(OUT, "primary.csv"), show_col_types = FALSE) |> filter(!grepl("95%", level), row %in% names(ROW_NEEDS))
se <- read_csv(file.path(OUT, "sensitivities.csv"), show_col_types = FALSE)
cs <- read_csv(file.path(OUT, "central_series.csv"), show_col_types = FALSE)
lab <- c(d_1663 = "H2-rise  G1709 - G1663", d_1670 = "H2-rise  G1709 - G1670", d_1678 = "H2-rise  G1709 - G1678",
         d_1682 = "H2-rise  G1709 - G1682", d = "H3-rise  G1757 - G1738", m = "H4  mean slave gap",
         s = "H4-w  gap slope 1700-1757 (per decade)")
keep <- c("5A-1" = "5A-1 within-year bootstrap", "5A-2" = "5A-2 exact-name clusters", "5A-3" = "5A-3 fixed PCA weights",
          "5B-5" = "5B-5 zero-index farmers dropped", "5B-6" = "5B-6 districts DS1-3", "5B-7" = "5B-7 Cape district only")
pts <- bind_rows(
  cs |> filter(quantity %in% names(lab)) |> transmute(quantity, est = original, lo = NA, hi = NA, src = "Original analysis (ineqdeco zero rule)"),
  tibble(quantity = "m", est = 0.2, lo = NA, hi = NA, src = "Stated in text"),
  se |> filter(item %in% names(keep), quantity %in% names(lab)) |> transmute(quantity, est = estimate, lo = L, hi = U, src = keep[item]),
  pr |> transmute(quantity, est = estimate, lo = L, hi = U, src = "Modern primary (98.75%)")) |>
  mutate(src = factor(src, levels = rev(c("Stated in text", "Original analysis (ineqdeco zero rule)", "Modern primary (98.75%)", unname(keep)))),
         panel = factor(lab[quantity], levels = lab))
thr <- tibble(panel = factor(lab, levels = lab), t0 = 0, t1 = ifelse(names(lab) == "m", 0.10, NA))
cols <- c(`Stated in text` = "#D4A03E", `Original analysis (ineqdeco zero rule)` = "#3D8EB9", `Modern primary (98.75%)` = "#5C2346",
          setNames(rep("#AAAAAA", length(keep)), keep))
p <- ggplot(pts, aes(x = est, y = src, colour = src)) +
  geom_vline(data = thr, aes(xintercept = t0), colour = "#4A4A4A", linewidth = 0.3) +
  geom_vline(data = thr, aes(xintercept = t1), linetype = "dashed", colour = "#6B8E5E", linewidth = 0.5, na.rm = TRUE) +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.25, linewidth = 0.6, na.rm = TRUE) +
  geom_point(size = 2.2) +
  facet_wrap(~ panel, ncol = 2, scales = "free_x") +
  scale_colour_manual(values = cols) +
  labs(x = NULL, y = NULL, caption = paste(
    "Modern primary: zeros kept, pooled PCA re-estimated per draw, name-key cluster bootstrap (B = 9,999; H2-rise 39,999).",
    "\nBars: Bonferroni 98.75% intervals (sup-t band for the four H2-rise contrasts; percentile otherwise).",
    "\nGrey: sensitivities (reported; never verdict-setting). Dashed: H4 magnitude floor 0.10.")) +
  theme_leap()
ggsave(file.path(OUT, "fig_s6_forest.png"), p, width = 10, height = 9, dpi = 300, bg = "white")
ggsave(file.path(OUT, "fig_s6_forest.pdf"), p, width = 10, height = 9)

# ---- series figure ---------------------------------------------------------------------------
C <- readRDS(file.path(SCR, "central.rds")); BC <- readRDS(file.path(SCR, "boot_central.rds")); M <- BC$M; e0 <- C$e
ci <- t(apply(M[, paste0("G_", YEARS)], 2, \(z) pct_int(z, 0.05)))
cig <- t(apply(M[, paste0("gI_", YEARS)] - M[, paste0("gE_", YEARS)], 2, \(z) pct_int(z, 0.05)))
df <- bind_rows(
  tibble(year = YEARS, est = e0$G, lo = ci[, "L"], hi = ci[, "U"], series = "Farmer Gini, core 1 (zeros kept)"),
  tibble(year = YEARS, est = e0$gI - e0$gE, lo = cig[, "L"], hi = cig[, "U"], series = "Settler-slave gap g(t)"))
orig <- tibble(year = YEARS, est = e0$G_drop0, series = "Farmer Gini, core 1 (zeros kept)") |> filter(abs(est - e0$G) > 1e-6)
p2 <- ggplot(df, aes(year, est)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), fill = "#5C2346", alpha = 0.15) +
  geom_line(colour = "#5C2346", linewidth = 0.8) + geom_point(colour = "#5C2346", size = 1.6) +
  geom_point(data = orig, colour = "#D4A03E", size = 1.8, shape = 17) +
  facet_wrap(~ series, ncol = 1, scales = "free_y") +
  labs(x = NULL, y = NULL, caption = paste("Plum: central estimate with 95% percentile interval from the name-key cluster bootstrap (B = 9,999).",
                                           "\nGold triangles: original analysis (zero-index farmers dropped), shown where it differs.")) +
  theme_leap() + theme(panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5))
ggsave(file.path(OUT, "fig_s6_series.png"), p2, width = 8, height = 7, dpi = 300, bg = "white")
ggsave(file.path(OUT, "fig_s6_series.pdf"), p2, width = 8, height = 7)
