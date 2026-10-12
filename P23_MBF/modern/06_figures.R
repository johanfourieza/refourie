# P23_MBF S6 figures (LEAP palette): Table 2 primary confidence sets; Table 5 estimates across primary and sensitivities.
suppressPackageStartupMessages({ library(tidyverse) })
root <- "."
mod <- file.path(root, "P23_MBF", "modern")
out <- file.path(mod, "output"); fig <- file.path(mod, "figures"); dir.create(fig, showWarnings = FALSE)
PLUM <- "#5C2346"; BLUE <- "#3D8EB9"; SAGE <- "#6B8E5E"; GOLD <- "#D4A03E"; GREY <- "#AAAAAA"
ASTAR <- 0.05 / 6; BAND <- 0.5 * log(1.32)
theme_leap <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(), legend.position = "bottom",
        strip.text = element_text(face = "bold", hjust = 0))

# ---- Figure 1: Table 2, six hypotheses: WCR 99.17% confidence set vs analytic CR1 99.17% interval
t2 <- read_csv(file.path(out, "t2_primary_raw.csv"), show_col_types = FALSE)
lab <- c("1" = "Birth region, post-independence (b1): H1-OR", "2" = "Interaction (b3): H2-OR",
         "3" = "Birth region, pre-independence (b1 + b3): H1-P", "4" = "Change in AME, pre minus post (pp): H2-Pd",
         "5" = "ln ratio of risk ratios: H2-RRR (reconstructed)", "6" = "ln risk ratio within birth regions: H2-lit")
floor_h <- c("1" = 0.19, "2" = 0.14, "3" = NA, "4" = NA, "5" = BAND, "6" = BAND)
segs <- bind_rows(lapply(seq_len(nrow(t2)), function(i) {
  r <- t2[i, ]
  bind_rows(lapply(1:3, function(j) if (!is.na(r[[paste0("lo", j)]])) tibble(h = r$h, lo = r[[paste0("lo", j)]], hi = r[[paste0("hi", j)]], type = "Wild cluster restricted score bootstrap")))
}))
cr1 <- t2 |> transmute(h, lo = rhat - qnorm(1 - ASTAR / 2) * s, hi = rhat + qnorm(1 - ASTAR / 2) * s, type = "Analytic CR1 (published inference)")
iv <- bind_rows(segs, cr1) |> mutate(lab = factor(lab[as.character(h)], levels = lab),
                                     y = ifelse(type == "Analytic CR1 (published inference)", -0.18, 0.18))
pts <- t2 |> mutate(lab = factor(lab[as.character(h)], levels = lab))
fl <- tibble(h = names(floor_h), fl = floor_h) |> filter(!is.na(fl)) |> mutate(lab = factor(lab[h], levels = lab))
bands <- tibble(h = c("5", "6")) |> mutate(lab = factor(lab[h], levels = lab))
p1 <- ggplot() +
  geom_rect(data = bands, aes(xmin = -BAND, xmax = BAND, ymin = -Inf, ymax = Inf), fill = GREY, alpha = 0.18) +
  geom_vline(xintercept = 0, colour = GREY) +
  geom_vline(data = fl, aes(xintercept = fl), colour = GOLD, linetype = "longdash") +
  geom_segment(data = iv, aes(x = lo, xend = hi, y = y, yend = y, colour = type), linewidth = 1.6) +
  geom_point(data = pts, aes(x = rhat, y = 0), colour = PLUM, size = 2.4) +
  facet_wrap(~lab, ncol = 1, scales = "free_x") +
  scale_colour_manual(values = c("Wild cluster restricted score bootstrap" = BLUE, "Analytic CR1 (published inference)" = GREY), name = NULL) +
  scale_y_continuous(limits = c(-0.6, 0.6), breaks = NULL) +
  labs(x = NULL, y = NULL, caption = "Bonferroni 99.17% intervals (Family M, six tests). Gold: 50% floor; grey band: credible-null band.") +
  theme_leap
ggsave(file.path(fig, "fig_t2_primary.pdf"), p1, width = 6.5, height = 8)
ggsave(file.path(fig, "fig_t2_primary.png"), p1, width = 6.5, height = 8, dpi = 300)

# ---- Figure 2: Table 5 mission coefficient (log-odds), primary and sensitivities
t5 <- read_csv(file.path(out, "t5_primary_raw.csv"), show_col_types = FALSE)
s5 <- read_csv(file.path(out, "t5_sensitivities_raw.csv"), show_col_types = FALSE) |>
  filter(!str_detect(scenario, "LPM"), !is.na(est))
iso <- c("5" = "CIV", "8" = "GHA", "11" = "KEN", "13" = "MLI", "15" = "MWI", "19" = "SEN", "20" = "SLE", "24" = "UGA", "25" = "ZMB")
d5 <- bind_rows(
  tibble(scenario = "Primary: Firth, printed col 4, 64 regions", est = t5$beta, lo = t5$pl_ci_lo, hi = t5$pl_ci_hi, grp = "Primary"),
  s5 |> mutate(grp = case_when(str_detect(scenario, "S16") ~ "ML", str_detect(scenario, "S19") ~ "Bayes", str_detect(scenario, "S22") ~ "Leave one country out", TRUE ~ "Firth sensitivity")) |>
    transmute(grp, scenario = case_when(
    str_detect(scenario, "S16") ~ "ML logit, robust SE (published)",
    str_detect(scenario, "col1") ~ "Firth, col 1 specification",
    str_detect(scenario, "col2") ~ "Firth, col 2 specification",
    str_detect(scenario, "col3") ~ "Firth, col 3 specification",
    str_detect(scenario, "S18") ~ "Firth, without d_capital",
    str_detect(scenario, "S19") ~ "Bayesian logit (Cauchy prior)",
    str_detect(scenario, "S20") ~ "Firth, all 124 complete cases",
    str_detect(scenario, "S24") ~ "Firth, Table 1 countries",
    str_detect(scenario, "S22") ~ paste("Firth, drop", iso[str_extract(scenario, "[0-9]+$")]),
    TRUE ~ scenario), est, lo = ci_lo, hi = ci_hi)
) |> mutate(scenario = fct_rev(fct_inorder(scenario)), hi_c = pmin(hi, 20), lo_c = pmax(lo, -5))
p2 <- ggplot(d5, aes(y = scenario)) +
  annotate("rect", xmin = -4.55, xmax = 4.55, ymin = -Inf, ymax = Inf, fill = GREY, alpha = 0.15) +
  geom_vline(xintercept = 0, colour = GREY) +
  geom_vline(xintercept = 4.55, colour = GOLD, linetype = "longdash") +
  geom_vline(xintercept = 9.10, colour = PLUM, linetype = "dotted") +
  geom_segment(aes(x = lo_c, xend = hi_c, yend = scenario, colour = grp), linewidth = 1.1) +
  geom_point(aes(x = est, colour = grp), size = 2.2) +
  scale_colour_manual(values = c("Primary" = PLUM, "ML" = GREY, "Firth sensitivity" = BLUE, "Bayes" = SAGE, "Leave one country out" = GOLD), name = NULL) +
  coord_cartesian(xlim = c(-5, 20)) +
  labs(x = "Mission coefficient (log-odds), 95% interval (truncated at 20)", y = NULL,
       caption = "Dotted: published 9.10. Gold dashed: 50% floor 4.55. Grey band: credible-null band (-4.55, 4.55).") +
  theme_leap
ggsave(file.path(fig, "fig_t5_range.pdf"), p2, width = 6.5, height = 5.5)
ggsave(file.path(fig, "fig_t5_range.png"), p2, width = 6.5, height = 5.5, dpi = 300)
