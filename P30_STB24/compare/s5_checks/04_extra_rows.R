# P30_STB24 S5 check 4: which rows does the S3 rebuild count in 1719-1737 that the cleaned analysis file lacks?
suppressPackageStartupMessages({library(dplyr); library(stringr)})
source("tools/paths.R")
hh <- readRDS(dpath("P30_STB24", "repro_r", "_scratch", "households.rds"))
g  <- readRDS(dscratch("P30_STB24", "compare", "reads.rds"))$guess
print(names(hh)[1:15])
norm <- function(x) str_to_lower(str_replace_all(coalesce(x, ""), "[^A-Za-z]", ""))
for (y in c(1731, 1719)) {
  a <- hh |> filter(year == y) |> mutate(k = norm(name_men), pos = row_number())
  b <- g |> filter(as.numeric(year) == y) |> mutate(k = norm(names_men))
  ex <- a |> filter(!(k %in% b$k))
  cat("\n", y, ": S3 rows", nrow(a), " original", nrow(b), " S3 names not in original:", nrow(ex), "\n")
  print(head(ex |> select(pos, name_men, name_women), 40))
}
ex <- hh |> group_by(year) |> mutate(pos = row_number()) |> ungroup() |> filter(year %in% c(1719, 1727, 1730:1737), is.na(name_men), is.na(name_women))
cat("\nunnamed S3 rows in 1719-1737 censuses:", nrow(ex), "\n"); print(table(ex$year))
num <- setdiff(names(hh)[sapply(hh, is.numeric)], c("row", "year", "nr"))
cat("unnamed rows with any positive asset/person entry:", sum(rowSums(ex[, num] > 0, na.rm = TRUE) > 0), "\n")
print(head(ex |> select(year, nr, pos, cattle, sheep, wheat, wine, slave_men), 8))
pos <- colSums(ex[, num] > 0, na.rm = TRUE); print(pos[pos > 0])
