# P28_VFF S6 step 5: coefficient plot (iid / Conley / Bonferroni-Conley / placebo-calibrated intervals) and
# a map of the change in re-extracted log lights 1996-2011. LEAP style. PDF + PNG (300 dpi).
source("./P28_VFF/modern/common.R")
suppressPackageStartupMessages({ library(ggplot2); library(tidyr) })
theme_leap <- function(base_size = 10) {
  theme_minimal(base_size = base_size, base_family = "sans") %+replace%
    theme(axis.title = element_text(size = 10, color = "#4A4A4A"), axis.text = element_text(size = 8.5, color = "#5A5A5A"),
          strip.text = element_text(size = 9.5, face = "bold", color = "#4A4A4A", hjust = 0),
          legend.text = element_text(size = 9), legend.position = "bottom",
          axis.line.x.bottom = element_line(color = "#4A4A4A", linewidth = 0.6),
          panel.grid.major.x = element_line(color = "#E0E0E0", linewidth = 0.4),
          panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
          axis.ticks.x = element_line(color = "#4A4A4A", linewidth = 0.5),
          plot.background = element_rect(fill = "#FFFFFF", color = NA), panel.background = element_rect(fill = "#FFFFFF", color = NA),
          panel.spacing = unit(1.0, "lines"), plot.margin = margin(10, 12, 10, 10))
}
pal <- c("iid OLS (95%)" = "#8A8A8A", "Conley Bartlett 100 km (95%)" = "#5C2346",
         "Conley, Bonferroni (1 - 0.05/6)" = "#D4A03E", "Placebo-calibrated (b +/- q95|t*| SE)" = "#3D8EB9")
pr <- read.csv(file.path(OUT, "primary.csv")); pl <- read.csv(file.path(OUT, "placebo.csv"))
vd <- read.csv(file.path(OUT, "verdict.csv")); i3 <- read.csv(file.path(OUT, "I3.csv"))
lab <- c(T2_r2_c6 = "I1  T2 col 6: Pop1911 on Pop2011", T2_r2_c7 = "I1  T2 col 7: Pop1911 on Pop2011 (geo controls)",
         T3_r2_c1 = "I2  T3 col 1: Homeland on Un1996", T3_r2_c6 = "I2  T3 col 6: Homeland on Un2011",
         T3_r2_c9 = "I2  T3 col 9: Homeland on Lights2011", T3_r2_c10 = "I2  T3 col 10: Homeland on Lights2011",
         I3 = "I3  beta_H(2011) - beta_H(1996), log lights")
p <- pr |> filter(role == "primary") |> left_join(pl[, c("claim_id", "q95_abs_tstar")], by = "claim_id")
z <- qnorm(0.975); zb <- qnorm(1 - 0.05 / 12)
pd <- bind_rows(
  p |> transmute(claim_id, kind = names(pal)[1], b = estimate, lo = estimate - z * se_iid, hi = estimate + z * se_iid),
  p |> transmute(claim_id, kind = names(pal)[2], b = estimate, lo = estimate - z * se_conley, hi = estimate + z * se_conley),
  p |> transmute(claim_id, kind = names(pal)[3], b = estimate, lo = ci_bonf_lo, hi = ci_bonf_hi),
  p |> transmute(claim_id, kind = names(pal)[4], b = estimate, lo = estimate - q95_abs_tstar * se_conley, hi = estimate + q95_abs_tstar * se_conley),
  i3 |> filter(role != "reported" | version == "reextracted_uncalibrated") |>
    transmute(claim_id = "I3", kind = names(pal)[2], b = contrast, lo = contrast - z * se_conley, hi = contrast + z * se_conley,
              row = c(primary_uncalibrated = "uncalibrated (data file)", primary_calibrated = "intercalibrated (re-extracted)",
                      reported = "uncalibrated (re-extracted)")[role]))
pd$row[is.na(pd$row)] <- pd$kind[is.na(pd$row)]
pd <- pd |> mutate(claim = factor(lab[claim_id], lab), row = factor(row, rev(unique(row))))
ref <- vd |> filter(claim_id %in% names(lab)) |>
  transmute(claim = factor(lab[claim_id], lab), b0, tag = paste0(verdict, " (", rule, ")"))
ref$tag <- sub(";.*\\)$", ")", ref$tag)
fig <- ggplot(pd, aes(x = b, y = row, colour = kind)) +
  geom_vline(xintercept = 0, colour = "#4A4A4A", linewidth = 0.4) +
  geom_vline(data = ref, aes(xintercept = b0), linetype = "dashed", colour = "#8A8A8A", linewidth = 0.4) +
  geom_vline(data = ref, aes(xintercept = 0.5 * b0), linetype = "dotted", colour = "#8A8A8A", linewidth = 0.4) +
  geom_errorbar(aes(xmin = lo, xmax = hi), width = 0, orientation = "y", linewidth = 0.7) +
  geom_point(size = 1.8) +
  geom_text(data = pd |> filter(claim_id == "I3"), aes(label = row), vjust = -0.7, size = 2.5, show.legend = FALSE) +
  geom_text(data = ref, aes(x = -Inf, y = Inf, label = tag), inherit.aes = FALSE, hjust = -0.02, vjust = 1.2, size = 2.6, colour = "#4A4A4A") +
  facet_wrap(~claim, ncol = 1, scales = "free") +
  scale_colour_manual(values = pal) +
  labs(x = "Coefficient (dashed = published b0; dotted = 0.5 b0)", y = NULL, colour = NULL) +
  guides(colour = guide_legend(nrow = 2)) + theme_leap() + theme(axis.text.y = element_blank())
ggsave(file.path(OUT, "coefplot.pdf"), fig, width = 7.5, height = 11)
ggsave(file.path(OUT, "coefplot.png"), fig, width = 7.5, height = 11, dpi = 300)

# Map: change in re-extracted (intercalibrated) log district lights, 1996 -> 2011, 138 analysis districts
if (file.exists(file.path(OUT, "lights_extracted.csv"))) {
  ex <- read.csv(file.path(OUT, "lights_extracted.csv"))
  d <- load_data()
  shp <- st_read(file.path(ORIG, "1911_dc.shp"), quiet = TRUE) |> select(id = ID) |>
    left_join(ex, by = "id") |> mutate(in_sample = id %in% d$id, dlog = log(ext11_cal) - log(ext96_cal),
                                        homeland = id %in% d$id[d$p_homeland > 0.5])
  m <- ggplot(shp) + geom_sf(aes(fill = ifelse(in_sample, dlog, NA)), colour = "#FFFFFF", linewidth = 0.1) +
    geom_sf(data = shp |> filter(homeland), fill = NA, colour = "#4A4A4A", linewidth = 0.35) +
    scale_fill_gradient2(low = "#5C2346", mid = "#F2F2F2", high = "#3D8EB9", midpoint = 0, na.value = "#E0E0E0",
                         name = "Change in log mean DN,\n1996 to 2011 (intercalibrated)") +
    labs(caption = "Grey: outside the 138-district sample. Dark outline: homeland share > 0.5. DMSP-OLS F121996.v4b, F182011.v4c.") +
    theme_void(base_size = 9) + theme(legend.position = "right", plot.background = element_rect(fill = "#FFFFFF", colour = NA))
  ggsave(file.path(OUT, "map_lights_change.pdf"), m, width = 7, height = 5.5)
  ggsave(file.path(OUT, "map_lights_change.png"), m, width = 7, height = 5.5, dpi = 300)
}
