# P20_HLF S3 recreation, step 3: figures (plain theme; /leapstyle not on the allow-list for this run)
suppressPackageStartupMessages({library(tidyverse); library(here)})
source(here("tools", "paths.R"))
sc <- dscratch("P20_HLF", "repro_r"); z <- readRDS(file.path(sc, "fit.rds"))
od <- here("P20_HLF", "repro_r", "output")
th <- theme_minimal(base_size = 11) + theme(panel.grid.minor = element_blank())
g <- tibble(dist = seq(20, 350, 2)); g$fit <- predict(z$m, g)
p1 <- ggplot(z$road, aes(dist, price)) + geom_point(aes(shape = source), size = 2) + geom_line(data = g, aes(y = fit)) +
  geom_vline(xintercept = 197, linetype = 2) + labs(x = "Distance (miles)", y = "GBP (1905) per ton-mile", shape = NULL) + th
ggsave(file.path(od, "fig5_road_costs.pdf"), p1, width = 6, height = 4)
ggsave(file.path(od, "fig5_road_costs.png"), p1, width = 6, height = 4, dpi = 300)
e <- seq(0, 1.2, 0.01); r <- tibble(eps = e, ratio = map_dbl(e, ~ z$ratio(z$phiF, .x)))
p2 <- ggplot(r, aes(eps, ratio)) + geom_line() + geom_vline(xintercept = c(0.5, 0.8), linetype = 2) +
  labs(x = "Absolute demand elasticity", y = "Consumer surplus / social saving (freight)") + th
ggsave(file.path(od, "cs_ratio.pdf"), p2, width = 6, height = 4)
ggsave(file.path(od, "cs_ratio.png"), p2, width = 6, height = 4, dpi = 300)
