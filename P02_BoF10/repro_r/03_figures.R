# S3 independent recreation, P02_BoF10: medium-term (12-40y) fluctuations, ships vs agricultural series (cf. paper Fig 8)
suppressPackageStartupMessages({library(tidyverse); library(here); library(mFilter); library(zoo)})
source(here("tools","paths.R"))
d <- read_csv(dscratch("P02_BoF10","repro_r","series.csv"), show_col_types = FALSE)
cyc <- function(v) { s <- d[[v]]; ok <- which(!is.na(s)); r <- min(ok):max(ok)
  x <- log(na.approx(s[r], na.rm = FALSE)); tibble(year = d$year[r], series = v, cycle = as.numeric(cffilter(x, pl = 12, pu = 40, root = FALSE, drift = FALSE)$cycle)) }
df <- map_dfr(c("ships","wheat_reaped","wheat_brunt","wheat_exports","vines","wine","cattle"), cyc)
pal <- c(ships = "#1B365D", wheat_reaped = "#C8102E", wheat_brunt = "#E69F00", wheat_exports = "#2E8B57", vines = "#6A5ACD", wine = "#8B4513", cattle = "#708090")
p <- ggplot(df, aes(year, cycle, colour = series)) + geom_line(linewidth = 0.5) +
  facet_wrap(~series, ncol = 2) + scale_colour_manual(values = pal, guide = "none") +
  labs(x = NULL, y = "Medium-term (12-40 year) CF component of log series") + theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())
ggsave(here("P02_BoF10","repro_r","output","fig_medium_term.pdf"), p, width = 7, height = 7)
ggsave(here("P02_BoF10","repro_r","output","fig_medium_term.png"), p, width = 7, height = 7, dpi = 300)
