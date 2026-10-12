# Figure 6 recreation: debt status by slave-ownership group
suppressMessages({library(dplyr); library(readr); library(ggplot2)})
od <- here::here("P13_FS", "repro_r")
r <- read_csv(file.path(od, "results_r.csv"), show_col_types = FALSE) |> filter(grepl("^F6_", claim_id), !is.na(value)) |>
  mutate(group = sub("^F6_(.*)_(nodebt|gt500)$", "\\1", claim_id), what = ifelse(grepl("nodebt", claim_id), "No debt", "Debt above 500 rds"))
g <- ggplot(r, aes(factor(group, c("0slaves", "1_5", "6_10", "11_24", "gt24")), value, fill = what)) + geom_col(position = "dodge") +
  labs(x = "Slave group", y = "Per cent of inventories", fill = NULL) + theme_minimal(base_size = 11) + theme(legend.position = "bottom")
ggsave(file.path(od, "output", "fig6_recreated.pdf"), g, width = 6, height = 4)
ggsave(file.path(od, "output", "fig6_recreated.png"), g, width = 6, height = 4, dpi = 300)
