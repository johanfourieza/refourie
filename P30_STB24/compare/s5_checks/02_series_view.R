# P30_STB24 S5 check 2: series and Gini patterns underlying the p.440-442 claims, by scenario (reads 01 outputs).
suppressPackageStartupMessages({library(readr); library(dplyr); library(tidyr)})
o <- "P30_STB24/compare/s5_checks/output"
yrs <- c(1685, 1700, 1702, 1710, 1715, 1716, 1717, 1730, 1745, 1760, 1780, 1795, 1800, 1803, 1804, 1806, 1810, 1820, 1840)
for (s in c("S0_baseline_as_run", "S1_types_fixed", "S5_all_fixes_base1795")) {
  cat("\n== index", s, "\n"); print(as.data.frame(read_csv(file.path(o, paste0("fig5_index_", s, ".csv")), show_col_types = FALSE) |> filter(year %in% yrs) |> mutate(across(-year, ~ signif(., 3)))))
  g <- read_csv(file.path(o, paste0("fig6_gini_", s, ".csv")), show_col_types = FALSE)
  cat("== gini by period", s, "\n")
  print(as.data.frame(g |> mutate(per = cut(year, c(1684, 1720, 1760, 1795, 1806, 1844), labels = c("1685-1720", "1721-60", "1761-95", "1796-1806", "1807-44"))) |>
    group_by(per) |> summarise(across(c(horses, cattle, sheep, wheat_vol, barley_vol, wine), ~ round(mean(., na.rm = TRUE), 3)))))
  cat("wine gini by decade:\n"); print(g |> mutate(dec = year %/% 10 * 10) |> group_by(dec) |> summarise(w = round(mean(wine, na.rm = TRUE), 3)) |> filter(!is.na(w)) |> pull(w, dec))
  slope <- sapply(c("horses", "cattle", "sheep", "wheat_vol", "barley_vol", "wine"), function(v) { d <- g[is.finite(g[[v]]), ]; coef(lm(d[[v]] ~ I(d$year / 100)))[2] })
  cat("OLS gini slope per century:\n"); print(round(slope, 3))
}
