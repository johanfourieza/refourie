# P12 S3: figures from aggregate model output only (no row-level data). Subsample of 11 recovered districts.
suppressMessages({library(dplyr); library(ggplot2); library(readr); library(stringr)})
outd <- "P12_FJ/repro_r/output"
cols <- c(White = "#1f3b73", Coloured = "#d98324", Black = "#a62b2b")
th <- theme_minimal(base_size = 11) + theme(panel.grid.minor = element_blank(), legend.position = "bottom")
# Fig A: pre-pandemic doctor-named share by race and district (Table 2 analogue)
t2 <- read_csv(file.path(outd, "table2_subsample.csv"), show_col_types = FALSE)
p1 <- ggplot(t2, aes(reorder(town, pct), pct, colour = race)) + geom_point() + coord_flip() + scale_colour_manual(values = cols) +
  labs(x = NULL, y = "Percent of certificates naming a doctor, Jan 1915-Sep 1918", colour = NULL, caption = "Subsample: 11 recovered districts") + th
ggsave(file.path(outd, "fig_doctor_share_by_race.pdf"), p1, width = 6, height = 4.5); ggsave(file.path(outd, "fig_doctor_share_by_race.png"), p1, width = 6, height = 4.5, dpi = 300)
# Fig B: pandemic interactions, spec 3, 83% CIs (district-clustered SE)
a <- read_csv(file.path(outd, "table5_all_se_subsample.csv"), show_col_types = FALSE) %>% filter(spec == "c3", str_detect(term, "Pandemic_x|_x_Pandemic")) %>%
  mutate(lo = est - 1.385 * se_cluster, hi = est + 1.385 * se_cluster)
p2 <- ggplot(a, aes(reorder(term, est), est, ymin = lo, ymax = hi)) + geom_pointrange(colour = cols["White"], size = 0.25) + geom_hline(yintercept = 0, linetype = 2) + coord_flip() +
  labs(x = NULL, y = "Logit coefficient (83% CI), spec (3)", caption = "Subsample: 11 recovered districts; clustered by district") + th
ggsave(file.path(outd, "fig_pandemic_interactions.pdf"), p2, width = 6.5, height = 6); ggsave(file.path(outd, "fig_pandemic_interactions.png"), p2, width = 6.5, height = 6, dpi = 300)
