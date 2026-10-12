suppressMessages({library(readr);library(dplyr)})
x <- read_csv("P27_RW/compare/comparison_ABC.csv", show_col_types=FALSE) |> filter(pair=="A", status %in% c("differs","close"))
options(width=220); print(as.data.frame(x |> select(claim_id, ref, rep, status)), row.names=FALSE)
