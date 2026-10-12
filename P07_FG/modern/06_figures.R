# P07_FG S6 step 6: range plot of the five descriptive statistics over the 16 scenarios of A (LEAP palette).
# Writes output/fig_s6_range.pdf and .png (300 dpi).
source(file.path(here::here(), "P07_FG", "modern", "00_engine.R"))
suppressPackageStartupMessages(library(ggplot2))
sc <- read_csv(file.path(OUT, "scenarios.csv"), show_col_types = FALSE)
pal <- c(text = "#5C2346", code = "#3D8EB9", Tas = "#6B8E5E", drift = "#D4A03E")
lab <- c(gK = "I1a-mag: g_K (% p.a.)", rKS = "I1b: r_KS = g_K / g_S", I1c = "I1c: K_1773 / 6,843",
         P_T5 = "I2a: P_T5 (%)", P_T3 = "I2b: P_T3 (%)")
long <- sc |> select(scenario, lambda, S, gamma, central, all_of(names(lab))) |>
  pivot_longer(all_of(names(lab)), names_to = "stat", values_to = "value") |>
  mutate(stat = factor(lab[stat], levels = lab), S = factor(S, levels = names(pal)),
         row = factor(paste0("λ=", lambda, ", ", S, ", γ ", gamma), levels = rev(unique(paste0("λ=", sc$lambda, ", ", sc$S, ", γ ", sc$gamma)))))
bands <- tibble(stat = factor(lab, levels = lab), lo = c(1.9, 0.80, 0.90, -Inf, -Inf), hi = c(Inf, 1.25, 1.10, -21.7, -21.72))
lines <- tibble(stat = factor(lab[c(1, 2, 2, 3, 3, 4, 5)], levels = lab), x = c(1.9, 0.8, 1.25, 0.9, 1.1, -21.7, -21.72))
p <- ggplot(long, aes(value, row)) +
  geom_rect(data = bands, aes(xmin = lo, xmax = hi, ymin = -Inf, ymax = Inf), inherit.aes = FALSE, fill = "#AAAAAA", alpha = 0.18) +
  geom_vline(data = lines, aes(xintercept = x), linetype = "dashed", colour = "#AAAAAA", linewidth = 0.4) +
  geom_point(aes(colour = S, shape = factor(lambda)), size = 2.2) +
  geom_point(data = filter(long, central), shape = 21, size = 4.2, colour = "#5C2346", fill = NA, stroke = 0.9) +
  facet_wrap(~stat, nrow = 1, scales = "free_x") +
  scale_colour_manual(values = pal, name = "Stellenbosch/Drakenstein rule S") +
  scale_shape_manual(values = c("0.5" = 17, "1" = 16), name = "λ") +
  labs(x = NULL, y = NULL, caption = "Shaded: region consistent with the claim (R+). Circled: central scenario. Assumption range, not a confidence interval.") +
  theme_minimal(base_size = 9) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank(), strip.text = element_text(face = "bold", hjust = 0),
        plot.caption = element_text(colour = "grey40", hjust = 0))
ggsave(file.path(OUT, "fig_s6_range.pdf"), p, width = 11, height = 4.6, device = cairo_pdf)
ggsave(file.path(OUT, "fig_s6_range.png"), p, width = 11, height = 4.6, dpi = 300)
