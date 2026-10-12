# P30_STB24 S5 check 5: what the l.888-891 relabel (slave_sons <- slave_children for year <= 1737) does.
suppressPackageStartupMessages({library(dplyr)})
source("tools/paths.R")
g <- readRDS(dscratch("P30_STB24", "compare", "reads.rds"))$guess |> mutate(year = as.numeric(year))
print(g |> filter(year <= 1737) |> group_by(per = cut(year, c(1684, 1700, 1720, 1737))) |>
  summarise(rows = n(), sons_nonNA = sum(!is.na(slave_sons)), sons_pos = sum(slave_sons > 0, na.rm = TRUE),
            children_nonNA = sum(!is.na(slave_children)), children_pos = sum(slave_children > 0, na.rm = TRUE),
            daughters_pos = sum(slave_daughters > 0, na.rm = TRUE), sons_total = sum(slave_sons, na.rm = TRUE), children_total = sum(slave_children, na.rm = TRUE)))
print(g |> filter(year <= 1737, !is.na(slave_children)) |> count(year) |> as.data.frame())
