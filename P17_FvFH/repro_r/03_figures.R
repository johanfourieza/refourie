# 03_figures.R -- Proportion of Van Duin & Ross totals captured by the opgaafrolle sample (Table 2 analogue)
library(tidyverse); library(here)
source(here::here("tools", "paths.R"))
r <- read_csv(here::here("P17_FvFH", "repro_r", "results_r.csv"), show_col_types = FALSE) %>%
  filter(grepl("^T2_pc_", claim_id), !is.na(value)) %>%
  separate(claim_id, c("t", "k", "year", "cat"), sep = "_", extra = "merge")
g <- ggplot(r, aes(cat, value, fill = year)) + geom_col(position = "dodge") + geom_hline(yintercept = 1, linetype = 2) +
  labs(x = NULL, y = "Sample / Van Duin & Ross total", fill = NULL) + theme_minimal() + theme(axis.text.x = element_text(angle = 30, hjust = 1))
dir.create(here::here("P17_FvFH", "repro_r", "output"), showWarnings = FALSE)
ggsave(here::here("P17_FvFH", "repro_r", "output", "fig_proportion_captured.pdf"), g, width = 7, height = 4)
ggsave(here::here("P17_FvFH", "repro_r", "output", "fig_proportion_captured.png"), g, width = 7, height = 4, dpi = 300)
