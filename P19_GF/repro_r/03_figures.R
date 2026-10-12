# P19_GF S3 independent recreation: 03_figures.R  (Figs 2, 6 [public debt only], A2, 8; generic clean theme)
suppressPackageStartupMessages({library(ggplot2); library(dplyr); library(tidyr)})
setwd("./P19_GF")
source("./tools/paths.R")
if (!exists("x")) source("repro_r/01_clean.R")
th <- theme_minimal(base_size = 11) + theme(legend.position = "bottom", legend.title = element_blank())
sv <- function(p, nm) { ggsave(file.path("repro_r/output", paste0(nm, ".pdf")), p, width = 7, height = 4)
                        ggsave(file.path("repro_r/output", paste0(nm, ".png")), p, width = 7, height = 4, dpi = 300) }
f2 <- x |> filter(year >= 1833, year <= 1909) |>
  transmute(year, `Human resources` = hr, `Colonial admin` = adm, `Defence` = mil, `Law and order` = law,
            `Debt service` = debt, `Public works` = pw) |>
  pivot_longer(-year) |> left_join(select(x, year, total), by = "year") |> mutate(share = 100 * value / total)
sv(ggplot(f2, aes(year, share, colour = name)) + geom_line() + labs(x = NULL, y = "% of total expenditure") + th, "fig2_functional_shares")
sv(ggplot(d, aes(year, debt_gdp)) + geom_line() + labs(x = NULL, y = "Public debt / GDP (%)") + th, "fig6_public_debt_gdp")
sv(ggplot(filter(x, rail > 0), aes(year, 100 * rail / pw)) + geom_line() + labs(x = NULL, y = "Railways, % of public works") + th, "figA2_rail_share")
sv(ggplot(f, aes(year, balance / 1e6)) + geom_col() + labs(x = NULL, y = "Revenue minus expenditure (million, series units)") + th, "fig8_budget_balance")
