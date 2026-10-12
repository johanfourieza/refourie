# S5: decompose the level gap between the S3 independent rebuild (pair B, repro_r) and the workbook (pair A)
suppressPackageStartupMessages({library(dplyr); library(readr); library(tidyr)})
root <- "./P15_FvZ"
W <- read_csv(file.path(root, "compare/s5_checks/s5_p15_scenarios_series.csv"), show_col_types = FALSE) |> filter(scenario == "base")
B <- read_csv(file.path(root, "repro_r/output/series_annual.csv"), show_col_types = FALSE) |> filter(year <= 1793)
d <- W |> inner_join(B, by = "year", suffix = c("_w", "_b"))
k <- 1000
comp <- tibble(year = d$year,
  wheat = (d$wheat_val / k - d$wheat), wine = (d$wine_val / k - d$wine), meat = (d$meat_val / k - d$meat), ag_investment = (d$ag_inv / k - d$aginv),
  voc = (d$voc_b / k - d$voc_w),
  crafts_construction = ((d$crafts + d$construction) / k - d$crafts_constr), bakers_butchers = (d$bakers_b / k - (d$bakers_w + d$butchers)),
  wine_retail = (d$wine_retail / k - d$wine_margin), slave_trade = (d$slave_trade / k - d$slave_margin), import_margin = (0 - d$import_margin)) |>
  mutate(gdp_w = d$gdp, gdp_b = d$gdp_nom / k)
comp$check <- comp$gdp_w + rowSums(comp[, 2:11]) - comp$gdp_b
cat("max abs residual of component accounting (thousand guilders):", round(max(abs(comp$check)), 2), "\n")
per <- function(y) cut(y, c(1700, 1750, 1793), labels = c("1701-1750", "1751-1793"))
gap <- comp |> mutate(period = per(year)) |> group_by(period) |>
  summarise(across(wheat:import_margin, ~ mean(.x / gdp_w) * 100), nominal_gdp_ratio = mean(gdp_b / gdp_w), .groups = "drop")
print(as.data.frame(gap), digits = 3)
# per-capita decomposition: log(pc_B/pc_W) = log(GDPnom ratio) - log(pop ratio) - log(deflator ratio)
Lw <- d$A1 / ((2335 / 177) * 7.69 / 9.61)                       # workbook L (1701 guilders, 1701=100 deflator)
dec <- tibble(year = d$year, l_pc = log(d$gdppc / Lw), l_gdp = log(d$gdp_nom / k / d$gdp),
              l_pop = -log(d$total / d$pop), l_defl = -log(d$deflator / (d$K / 100)))
dec$resid <- dec$l_pc - dec$l_gdp - dec$l_pop - dec$l_defl
s <- dec |> mutate(period = per(year)) |> group_by(period) |>
  summarise(pc_ratio = exp(mean(l_pc)), from_nominal_gdp = exp(mean(l_gdp)), from_population = exp(mean(l_pop)),
            from_deflator = exp(mean(l_defl)), resid = exp(mean(resid)), .groups = "drop")
s2 <- dec |> summarise(period = "1701-1793", pc_ratio = exp(mean(l_pc)), from_nominal_gdp = exp(mean(l_gdp)), from_population = exp(mean(l_pop)),
            from_deflator = exp(mean(l_defl)), resid = exp(mean(resid)))
print(as.data.frame(bind_rows(s |> mutate(period = as.character(period)), s2)), digits = 3)
cat("pc ratio range:", round(range(exp(dec$l_pc)), 2), "\n")
cat("1701: B pop", d$total[1], "W pop", round(d$pop[1]), "; B nominal", round(d$gdp_nom[1] / k), "W", round(d$gdp[1]), "\n")
write_csv(gap, file.path(root, "compare/s5_checks/s5_p15_Bgap_components.csv"))
write_csv(bind_rows(s |> mutate(period = as.character(period)), s2), file.path(root, "compare/s5_checks/s5_p15_Bgap_percapita.csv"))
