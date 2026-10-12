# S5 check 3: deficit from primary workbook; Fig 2 point values under classified-sum denominator
suppressPackageStartupMessages({library(readxl); library(dplyr)})
source("./tools/paths.R")
x <- read.csv("P19_GF/repro_r/output/expenditure_classes.csv")
pth <- dpath("P19_GF", "original", "colonial govt fiscal", "Abel Gwaindepi CC fiscal records.xlsx")
r <- suppressMessages(read_excel(pth, sheet = "Revenue", .name_repair = "minimal"))[, 1:2]
names(r) <- c("year", "rev"); r <- mutate(r, across(everything(), as.numeric))
d <- inner_join(x, r, by = "year") |> mutate(def = total - rev, def_cls = classified - rev) |> filter(year >= 1872)
cat("max deficit (Total Exp - Total Rev):", max(d$def) / 1e6, "in", d$year[which.max(d$def)],
    "| using classified sum:", max(d$def_cls) / 1e6, "in", d$year[which.max(d$def_cls)], "\n")
x <- mutate(x, pw_c = 100 * pw / classified, debt_c = 100 * debt / classified)
print(round(filter(x, year %in% c(1874, 1876, 1904, 1905)) |> select(year, pw_c, debt_c), 1))
cat("max pw share (classified denom) 1895-1909:", max(x$pw_c[x$year >= 1895]), "\n")
