# P11_FJS S6 07: range plot of the top-decile shares, 1700 and 1773: primary (votes), §5A sensitivities, the
# hearth-allocation bounds (S11) and the SP-rise 95% interval (different-estimand), against the claim thresholds.
# Output: output/fig_top_decile_range.pdf / .png (300 dpi). LEAP style.
source("./P11_FJS/modern/00_common.R")
suppressPackageStartupMessages(library(ggplot2))
LEAP <- c(plum = "#5C2346", blue = "#3D8EB9", sage = "#6B8E5E", gold = "#D4A03E", grey = "#AAAAAA")
theme_leap <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = "sans") %+replace%
    theme(text = element_text(family = "sans"),
          axis.title = element_text(size = 10, color = "#4A4A4A"), axis.text = element_text(size = 8, color = "#5A5A5A"),
          axis.line.x.bottom = element_line(color = "#4A4A4A", linewidth = 0.8),
          axis.line.y.left = element_line(color = "#4A4A4A", linewidth = 0.8),
          panel.grid.major.y = element_line(color = "#E0E0E0", linewidth = 0.5),
          panel.grid.major.x = element_blank(), panel.grid.minor = element_blank(),
          axis.ticks = element_line(color = "#4A4A4A", linewidth = 0.6), axis.ticks.length = unit(3, "pt"),
          legend.background = element_blank(), legend.key = element_blank(), legend.position = "bottom",
          plot.background = element_rect(fill = "#FFFFFF", color = NA), panel.background = element_rect(fill = "#FFFFFF", color = NA),
          plot.margin = margin(10, 10, 10, 10), strip.text = element_text(size = 10, face = "bold", color = "#2D2D2D"))
}
sens <- read_csv(file.path(OUT, "sensitivities.csv"), show_col_types = FALSE)
sp   <- read_csv(file.path(OUT, "sp_rise.csv"), show_col_types = FALSE)

lab <- c(`0` = "Primary (corrected tax, fractional ties)", `1` = "S1 Published construction (workbook share)",
         `2` = "S2 xtile group 10, exact sums", `3` = "S3 Ties kept together", `4a` = "S4a Ties broken by tax, desc.",
         `4b` = "S4b Ties broken by tax, asc.", `5` = "S5 Tax corrections off", `6` = "S6 0.7 wine factor",
         `7` = "S7 Grain net of seed", `8a` = "S8a Imputation, coded constant", `8b` = "S8b Imputation, donor mean",
         `8c` = "S8c Imputation, donor median", `8d` = "S8d Imputation, pooled mean", `9` = "S9 Wine 72 st before 1743",
         `10` = "S10 Swellendam poll 36 st", `11c` = "S11c No hearth tax", `11d` = "S11d Missing ds pays hearth",
         `12` = "S12 Pigs as assets", `13` = "S13 Duplicates dropped")
pts <- sens |> filter(item %in% names(lab), quantity %in% c("S00", "S73")) |>
  transmute(item, label = lab[item], year = ifelse(quantity == "S00", "1700 (claim: < 50%)", "1773 (claim: > 61%)"), value,
            type = ifelse(item == "0", "Primary (votes)", "Sensitivity (§5A)"))
rng <- bind_rows(
  sens |> filter(item %in% c("11a", "11b"), quantity %in% c("S00", "S73")) |> group_by(quantity) |>
    summarise(lo = min(value), hi = max(value)) |> mutate(label = "S11 Hearth allocation bounds", type = "Bounds (S11)"),
  sp |> filter(run == "main iid", quantity %in% c("S00", "S73")) |> transmute(quantity, lo, hi,
    label = "SP-rise 95% interval (different-estimand)", type = "SP-rise 95% CI (different-estimand)")) |>
  mutate(year = ifelse(quantity == "S00", "1700 (claim: < 50%)", "1773 (claim: > 61%)"))
lev <- rev(c(lab, "S11 Hearth allocation bounds", "SP-rise 95% interval (different-estimand)"))
pts$label <- factor(pts$label, levels = lev); rng$label <- factor(rng$label, levels = lev)
thr <- tibble(year = c("1700 (claim: < 50%)", "1773 (claim: > 61%)"), x = c(50, 61))
cols <- c("Primary (votes)" = LEAP[["plum"]], "Sensitivity (§5A)" = LEAP[["blue"]], "Bounds (S11)" = LEAP[["sage"]],
          "SP-rise 95% CI (different-estimand)" = LEAP[["gold"]])
p <- ggplot() +
  geom_vline(data = thr, aes(xintercept = x), colour = LEAP[["grey"]], linetype = "dashed", linewidth = 0.6) +
  geom_segment(data = rng, aes(x = lo, xend = hi, y = label, yend = label, colour = type), linewidth = 1.6) +
  geom_point(data = pts, aes(x = value, y = label, colour = type), size = 2.2) +
  facet_wrap(~year, scales = "free_x") + scale_colour_manual(values = cols, name = NULL) +
  labs(x = "Top slave decile's share of household tax (%)", y = NULL) + theme_leap() +
  guides(colour = guide_legend(nrow = 2))
ggsave(file.path(OUT, "fig_top_decile_range.pdf"), p, width = 8, height = 6)
ggsave(file.path(OUT, "fig_top_decile_range.png"), p, width = 8, height = 6, dpi = 300)
cat("Saved fig_top_decile_range.pdf/.png\n")
