# P11_FJS S5 interpretation check: top slave-decile share of tax vs its share of slaves (the wealth proxy)
# and of farm output, A1 (published) construction, ten equal groups with random ties (200 draws).
suppressPackageStartupMessages({ library(tidyverse); library(haven) })
root <- "."; source(file.path(root, "tools", "paths.R"))
p11 <- file.path(root, "P11_FJS"); set.seed(20261011)
a1 <- read_dta(dpath("P11_FJS", "repro_original", "_scratch", "runA1_households.dta")) |> zap_labels() |>
  mutate(outval = 6 * kgw + 3 * (rgw + cgw) + 3 * wyn)   # rough gross farm output, Rd (wheat 6, other grain 3, wine 3/leaguer)
top <- function(x, v, B = 200) { n <- nrow(x); k <- ceiling(.9 * n)
  mean(replicate(B, { o <- order(x$tslaves, runif(n)); 100 * sum(v[o[(k + 1):n]]) / sum(v) })) }
out <- map_dfr(c(1700, 1719, 1731, 1738, 1741, 1757, 1773), function(y) { x <- filter(a1, jaar == y)
  tibble(year = y, n = nrow(x), zero_slave_hh = mean(x$tslaves == 0), top_tax = top(x, x$totaltax),
         top_slaves = top(x, x$tslaves), top_output = top(x, x$outval)) }) |> mutate(across(4:6, ~ round(.x, 1)))
print(out); write_csv(out, file.path(p11, "compare/s5_checks/s5_progressivity.csv"))
