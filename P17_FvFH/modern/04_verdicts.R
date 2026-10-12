# P17_FvFH S6 -- 04_verdicts.R: verdict summary, coverage, forest figure (LEAP palette), sessionInfo
source(here::here("P17_FvFH", "modern", "00_functions.R"))
v <- read_csv(file.path(OUT, "verdict.csv"), show_col_types = FALSE)
prim <- read_csv(file.path(OUT, "primary.csv"), show_col_types = FALSE)
sens <- read_csv(file.path(OUT, "sensitivities.csv"), show_col_types = FALSE)
# Coverage (card §8): assessed farm-income rows out of 6, plus 5 structurally not-testable rows
farm <- v[1:6, ]; ord <- c("overturned", "weakened", "qualified", "confirmed")
assessed <- farm %>% filter(rule != 0)
weakest <- ord[min(match(sub(" .*", "", assessed$verdict), ord))]
write_csv(tibble(assessed_farm_rows = nrow(assessed), farm_rows = 6, structural_not_testable = 5, weakest_assessed = weakest),
          file.path(OUT, "coverage.csv"))
# Forest plot: nine contrasts, Bonferroni percentile CIs (primary) with the loc-cluster bootstrap (S17) beside them
lab <- c(Delta = "Gini 1757 - 1700", Da = "Gini 1723 - 1700", Db = "Gini 1757 - 1723", E = "Wine: contribution - share",
         D_grain = "Wine - grain", D_cattle = "Wine - cattle", D_sheep = "Wine - sheep", D_pigs = "Wine - pigs", D_horses = "Wine - horses")
fd <- bind_rows(prim %>% filter(quantity %in% FAM) %>% transmute(quantity, estimate, lo, hi, type = "Household bootstrap (primary)"),
                sens %>% filter(sens == "S17", quantity %in% FAM) %>% transmute(quantity, estimate, lo, hi, type = "Cluster bootstrap by location (S17)")) %>%
  mutate(label = factor(lab[quantity], levels = rev(lab)), type = factor(type, levels = c("Household bootstrap (primary)", "Cluster bootstrap by location (S17)")))
p <- ggplot(fd, aes(x = estimate, y = label, colour = type)) +
  geom_vline(xintercept = 0, colour = "#AAAAAA", linewidth = 0.4) +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.25, linewidth = 0.6, position = position_dodge(width = 0.6)) +
  geom_point(size = 2, position = position_dodge(width = 0.6)) +
  scale_colour_manual(values = c("#5C2346", "#AAAAAA"), name = NULL) +
  labs(x = "Estimate with 99.44% percentile interval (Bonferroni, 9 contrasts)", y = NULL) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        axis.line.x = element_line(colour = "black", linewidth = 0.3))
ggsave(file.path(OUT, "fig_contrasts.pdf"), p, width = 7, height = 4.5)
ggsave(file.path(OUT, "fig_contrasts.png"), p, width = 7, height = 4.5, dpi = 300)
writeLines(capture.output(sessionInfo()), here::here("P17_FvFH", "modern", "sessionInfo.txt"))
print(as.data.frame(v[, c("claim", "estimate", "verdict", "rule", "mc_flag")])); cat("weakest assessed:", weakest, "\n")
