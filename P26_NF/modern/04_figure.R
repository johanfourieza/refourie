# P26_NF S6 figure: net 1886-87 falls B and W under the primary analysis and the count sensitivities, against the A8 bands.
suppressMessages({library(tidyverse); library(here)})
source(here::here("tools", "paths.R"))
od <- here::here("P26_NF", "modern")
pr <- read_csv(file.path(od, "output", "primary.csv"), show_col_types = FALSE)
se <- read_csv(file.path(od, "output", "sensitivities.csv"), show_col_types = FALSE)
pv <- setNames(pr$value, pr$quantity)
lab <- c(S1 = "S1 published sets (16 vs 14)", S2 = "S2 method-consistent (12)", S4a = "S4a imputed, no change (16)", S4b = "S4b imputed, D-ratio (16)")
pts <- bind_rows(
  tibble(row = "Primary: comparable set D (14)", type = "Primary", q = c("B", "W"), value = c(pv[["B"]], pv[["W"]])),
  se |> filter(sens %in% names(lab), quantity %in% c("B", "W")) |> transmute(row = lab[sens], type = "Sensitivity", q = quantity, value))
rng <- se |> filter(sens == "S3", quantity %in% c("B", "W")) |> group_by(q = quantity) |> summarise(lo = min(value), hi = max(value)) |> mutate(row = "S3 leave-one-out range (13)")
lev <- c("S4b imputed, D-ratio (16)", "S4a imputed, no change (16)", "S3 leave-one-out range (13)", "S2 method-consistent (12)", "S1 published sets (16 vs 14)", "Primary: comparable set D (14)")
bands <- tibble(q = c("B", "B", "W"), lo = c(2542.5, 2800, 7140.6), hi = c(3107.5, 3000, 8727.4), what = c("point band", "authors' range", "point band"))
ql <- c(B = "B: fall in black registrations", W = "W: fall in white/coloured registrations")
g <- ggplot() +
  geom_rect(data = filter(bands, what == "point band"), aes(xmin = lo, xmax = hi, ymin = -Inf, ymax = Inf), fill = "#D4A03E", alpha = 0.25) +
  geom_rect(data = filter(bands, what == "authors' range"), aes(xmin = lo, xmax = hi, ymin = -Inf, ymax = Inf), fill = "#D4A03E", alpha = 0.35) +
  geom_segment(data = rng, aes(x = lo, xend = hi, y = factor(row, lev), yend = factor(row, lev)), colour = "#3D8EB9", linewidth = 1.2) +
  geom_point(data = pts, aes(value, factor(row, lev), colour = type), size = 3) +
  scale_colour_manual(values = c(Primary = "#5C2346", Sensitivity = "#3D8EB9"), name = NULL) +
  facet_wrap(~ q, scales = "free_x", labeller = as_labeller(ql)) +
  scale_x_continuous(labels = scales::comma) +
  labs(x = "Net fall in registrations, 1886-87", y = NULL,
       caption = "Gold: A8 point band (±10% of the stated fall); darker gold: the authors' 2,800-3,000 range.\nConditional arithmetic on the published per-division cells; no sampling interval exists.") +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom", panel.spacing = unit(2, "lines"), panel.grid.minor = element_blank(), plot.caption = element_text(hjust = 0, colour = "#555555"))
ggsave(file.path(od, "fig_falls.pdf"), g, width = 8, height = 3.6)
ggsave(file.path(od, "fig_falls.png"), g, width = 8, height = 3.6, dpi = 300)
writeLines(capture.output(sessionInfo()), file.path(od, "sessionInfo.txt"))
