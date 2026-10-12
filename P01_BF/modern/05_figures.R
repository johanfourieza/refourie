# P01_BF S6 step 5: forest plot (LEAP palette). One panel per verdict row: published value (b0), original-code value
# (S2 Stata; T6 -pt rows only), the modern primary with its Bonferroni interval, and selected sensitivities
# (grey; reported, never verdict-setting). Shading: credible-null band (-pt/-rel rows); dashed: confirm threshold.
# Outputs: output/fig_s6_forest.{pdf,png}
source(here::here("P01_BF", "modern", "00_common.R"))
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
pr <- read_csv(file.path(out, "primary.csv"), show_col_types = FALSE)
se <- read_csv(file.path(out, "sensitivities.csv"), show_col_types = FALSE, col_types = cols(sens = "c"))
ro <- read_csv(file.path(root, "repro_original", "results_original.csv"), show_col_types = FALSE)
orig <- tibble(row = c("H1-pt", "H2-SEA-pt", "H2-IND-pt", "H2-MOZ-pt"),
               est = ro$value[match(c("T6_r4", "T6_r5", "T6_r6", "T6_r8"), ro$claim_id)])
lab <- c(`H1-pt` = "H1-pt  Europeans (ABCC points)", `H1-rel` = "H1-rel  Europeans (log ratio)",
         `H2-SEA-pt` = "H2-SEA-pt  SE Asians (ABCC points)", `H2-SEA-rel` = "H2-SEA-rel  SE Asians (log ratio)",
         `H2-IND-pt` = "H2-IND-pt  Indians (ABCC points)", `H2-IND-rel` = "H2-IND-rel  Indians (log ratio)",
         `H2-MOZ-pt` = "H2-MOZ-pt  Mozambicans (ABCC points)", `H2-MOZ-rel` = "H2-MOZ-rel  Mozambicans (log ratio)",
         H3 = "H3  Khoesan early -> middle (ABCC points)")
keep <- c("1" = "S1 coding fix, published contrast", "2" = "S2 contrast fix, original coding", "5" = "S5 AME",
          "7" = "S7 LPM", "8" = "S8 Firth", "13" = "S13 H3 controlled", "16" = "S16 H3 alternative tests")
srows <- se |> filter(sens %in% names(keep), row %in% names(lab), is.finite(est), status == "ok") |>
  group_by(sens, row) |> slice(1) |> ungroup() |> transmute(row, est, lo = ci_lo, hi = ci_hi, src = keep[sens])
pts <- bind_rows(
  pr |> transmute(row, est = b0, lo = NA, hi = NA, src = "Published"),
  orig |> mutate(lo = NA, hi = NA, src = "Original code"),
  srows,
  pr |> transmute(row, est, lo = ci_lo, hi = ci_hi, src = "Modern primary")) |>
  mutate(src = factor(src, levels = rev(c("Published", "Original code", "Modern primary", unname(keep)))), panel = factor(lab[row], levels = lab))
bands <- pr |> filter(row != "H3") |> transmute(panel = factor(lab[row], levels = lab), thr = threshold, sgn = sign(b0))
cols <- c(Published = "#D4A03E", `Original code` = "#3D8EB9", `Modern primary` = "#5C2346", setNames(rep("#AAAAAA", length(keep)), keep))
p <- ggplot(pts, aes(x = est, y = src, colour = src)) +
  geom_rect(data = bands, aes(xmin = -thr, xmax = thr, ymin = -Inf, ymax = Inf), inherit.aes = FALSE, fill = "#AAAAAA", alpha = 0.25) +
  geom_vline(xintercept = 0, colour = "#4A4A4A", linewidth = 0.3) +
  geom_vline(data = bands, aes(xintercept = sgn * thr), linetype = "dashed", colour = "#6B8E5E", linewidth = 0.5) +
  geom_errorbar(aes(xmin = lo, xmax = hi), orientation = "y", width = 0.25, linewidth = 0.6, na.rm = TRUE) +
  geom_point(size = 2.2) +
  facet_wrap(~ panel, ncol = 2, scales = "free") +
  scale_colour_manual(values = cols) +
  labs(x = NULL, y = NULL, caption = paste(
    "Modern primary: corrected origin coding and Cape-born contrast at the mean covariate profile (T6); unconditional cohort difference (H3).",
    "\nBars: Bonferroni intervals (1 - 0.05/9); CR1 by court volume, t(42) for T6; wild cluster restricted bootstrap by volume for H3 (reported only).",
    "\nGrey: sensitivities (reported; never verdict-setting). Shading: credible-null band. Dashed: confirm threshold (half the printed magnitude).")) +
  theme_leap()
ggsave(file.path(out, "fig_s6_forest.png"), p, width = 10, height = 11, dpi = 300, bg = "white")
ggsave(file.path(out, "fig_s6_forest.pdf"), p, width = 10, height = 11)
