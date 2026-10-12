# 03_figures.R -- mean household wealth by year with 5-year moving average and linear trend (Fig 5 analogue)
suppressMessages({library(dplyr); library(ggplot2)})
source("tools/paths.R")
scr <- dscratch("P27_RW", "repro_r"); inv <- readRDS(file.path(scr, "clean.rds"))$inv
ann <- inv %>% filter(date >= 1700, date <= 1795) %>% group_by(date) %>% summarise(m = mean(wealth), .groups = "drop") %>%
  mutate(ma5 = as.numeric(stats::filter(m, rep(1 / 5, 5), sides = 2)))
p <- ggplot(ann, aes(date, m)) + geom_line(colour = "grey60") + geom_line(aes(y = ma5), colour = "#00467F", linewidth = 1) +
  geom_smooth(method = "lm", se = FALSE, colour = "#B22222", linewidth = .6) +
  labs(x = NULL, y = "Mean household wealth (rijksdaalders)") + theme_minimal(base_size = 11)
ggsave("P27_RW/repro_r/output/fig5_wealth.pdf", p, width = 6.5, height = 4); ggsave("P27_RW/repro_r/output/fig5_wealth.png", p, width = 6.5, height = 4, dpi = 300)
