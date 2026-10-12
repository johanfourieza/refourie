# P24_MGF S6 figures: (1) comparative rows, primary and sensitivities; (2) census context (sens. 6).
suppressMessages({library(tidyverse); library(here)})
P <- "P24_MGF"
out <- here::here(P, "modern", "output")
pal <- c(plum = "#5C2346", blue = "#3D8EB9", sage = "#6B8E5E", gold = "#D4A03E", grey = "#AAAAAA")
prim <- read_csv(file.path(out, "primary.csv"), show_col_types = FALSE)
sens <- read_csv(file.path(out, "sensitivities.csv"), show_col_types = FALSE)
lev_rows <- c("K04-ex" = "Black, 0-59 months:\nmale share - 0.5", "K18-ex" = "Black, 18-59 months:\nmale share - 0.5",
              "KBW" = "18-59 months:\nblack - white male share")

cr <- c("K04-ex", "K18-ex", "KBW")
d <- bind_rows(
  prim |> filter(row %in% cr) |> transmute(row, what = "Primary (98.33%, independence)", est, lo, hi),
  sens |> filter(str_starts(sensitivity, "2 ")) |> transmute(row, what = "Wild cluster bootstrap (8 years)", est, lo = boot_lo, hi = boot_hi),
  sens |> filter(str_starts(sensitivity, "1 "), row %in% cr) |> group_by(row) |>
    summarise(lo = min(est), hi = max(est), est = NA_real_) |> mutate(what = "Leave-one-year-out range"),
  sens |> filter(str_starts(sensitivity, "5 "), row %in% cr) |> group_by(row) |>
    summarise(lo = min(est), hi = max(est), est = NA_real_) |> mutate(what = "Missing-record bounds"),
  sens |> filter(str_detect(sensitivity, "^(3a|3b|4) "), row %in% cr) |> transmute(row, what = "Recoding / 17-month boundary", est, lo = NA, hi = NA)) |>
  mutate(row = factor(lev_rows[row], levels = rev(lev_rows)),
         what = factor(what, levels = c("Primary (98.33%, independence)", "Wild cluster bootstrap (8 years)",
                                        "Leave-one-year-out range", "Missing-record bounds", "Recoding / 17-month boundary")))
g <- ggplot(d, aes(y = row, colour = what)) +
  geom_vline(xintercept = 0, colour = "grey40", linewidth = 0.3) +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.25, position = position_dodge(0.6), na.rm = TRUE) +
  geom_point(aes(x = est), position = position_dodge(0.6), size = 1.8, na.rm = TRUE) +
  scale_colour_manual(values = unname(pal)) +
  labs(x = "Difference in the male share of recorded deaths", y = NULL, colour = NULL) +
  theme_minimal(base_size = 10) +
  theme(legend.position = "bottom", legend.direction = "vertical", panel.grid.minor = element_blank(), panel.grid.major.y = element_blank())
ggsave(here::here(P, "modern", "fig_s6_kimberley.pdf"), g, width = 6.5, height = 4.5)
ggsave(here::here(P, "modern", "fig_s6_kimberley.png"), g, width = 6.5, height = 4.5, dpi = 300)

c6 <- sens |> filter(str_starts(sensitivity, "6 ")) |> mutate(year = as.integer(str_sub(spec, 1, 4)),
                                                              type = if_else(year == 1921, "Under-one proxy", "Under-five"))
g2 <- ggplot(c6, aes(year, R)) +
  geom_vline(xintercept = 1910, linetype = "dashed", colour = pal["grey"]) +
  annotate("text", x = 1909, y = 96.3, label = "Cape | Union", hjust = 0.5, size = 3, colour = "grey30") +
  geom_line(colour = pal["grey"]) + geom_point(aes(colour = type), size = 2.4) +
  scale_colour_manual(values = c("Under-five" = unname(pal["blue"]), "Under-one proxy" = unname(pal["plum"]))) +
  labs(x = NULL, y = "Black boys per 100 girls (census)", colour = NULL) +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom", panel.grid.minor = element_blank())
ggsave(here::here(P, "modern", "fig_s6_census_context.pdf"), g2, width = 5.5, height = 3.5)
ggsave(here::here(P, "modern", "fig_s6_census_context.png"), g2, width = 5.5, height = 3.5, dpi = 300)
