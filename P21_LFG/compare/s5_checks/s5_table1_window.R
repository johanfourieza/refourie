# Table 1 on the stated window (1805-1828) vs all years in processed.dta
suppressMessages({library(haven); library(dplyr); library(here)}); source(here::here("tools", "paths.R"))
d <- read_dta(dpath("P21_LFG", "original", "Calumet Links", "processed.dta")) |> zap_labels()
cat("years:", range(d$year), " rows 1805+:", sum(d$year >= 1805), "\n")
f <- function(x) round(c(mean = mean(x, na.rm = TRUE), sd = sd(x, na.rm = TRUE), max = max(x, na.rm = TRUE)), 2)
for (v in c("sheep", "cattle", "settlers", "khoe", "slaves")) cat(v, " all:", f(d[[v]]), " 1805+:", f(d[[v]][d$year >= 1805]), "\n")
