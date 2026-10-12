# P15_FvZ  S6 modern reanalysis, step 2: margins, s per claim and verdicts.
# Applies method card sections 7 and 8 mechanically to output/scenarios.csv (from 01_scenarios.R).
#   s = share of the 144 central-layer scenarios (equal weight) that satisfy the condition;
#   confirmed only if s >= 0.80 AND the central-layer scenario with all U items as coded
#   satisfies it (otherwise downgraded to qualified). Sensitivities (section 5) are reported
#   separately and do not determine verdicts.
# Outputs (modern/output/): verdict.csv, sensitivity.csv, ranges.csv.

suppressPackageStartupMessages({library(dplyr); library(tidyr); library(readr)})
args_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- if (length(args_file)) normalizePath(file.path(dirname(args_file), "..")) else
  "./P15_FvZ"
out <- file.path(root, "modern", "output")
sc <- read_csv(file.path(out, "scenarios.csv"), show_col_types = FALSE, col_types = cols(U6 = col_character()))
coded <- c(U1 = "lag2_coded", U2 = "div5_coded", U3 = "coded", U4 = "typed_coded", U5 = "P0", U6 = "1.00")
is_coded_row <- with(sc, U1 == coded[["U1"]] & U2 == coded[["U2"]] & U3 == coded[["U3"]] &
                         U4 == coded[["U4"]] & U5 == coded[["U5"]] & U6 == coded[["U6"]])
n_nonfinite <- sum(!sc$finite)
sc <- sc |> mutate(coded_U = is_coded_row) |> filter(finite)

# Conditions (card section 7)
cond <- list(
  I1a = function(d) d$ratio_GB >= 0.80 & d$ratio_GB <= 1.25,
  I1b = function(d) d$ratio_NL >= 0.60 & d$ratio_NL < 1.00,
  I2  = function(d) d$R <= 0.795 & d$trend_pop > d$trend_gdp,
  I3  = function(d) d$bal_share_in_band >= 0.80)
cond_text <- c(I1a = "Y1701 / Britain 1701 in [0.80, 1.25]", I1b = "Y1701 / Holland 1701 in [0.60, 1.00)",
               I2 = "R = Y1790/Y1701 <= 0.795 and population trend > GDP trend (OLS 1701-1793)",
               I3 = ">= 80% of years 1701-1793 with balanced GDP pc in [540, 1100]")
verdict_of <- function(s, coded_ok) case_when(
  s >= 0.80 & coded_ok ~ "confirmed",
  s >= 0.80 & !coded_ok ~ "qualified (downgraded: coded scenario fails)",
  s >= 0.50 ~ "qualified", s >= 0.20 ~ "weakened", TRUE ~ "overturned")

judge <- function(d, cf, label) {
  ok <- cf(d); stopifnot(!anyNA(ok))
  co <- ok[d$coded_U]; stopifnot(length(co) == 1)
  tibble(s = mean(ok), n_scenarios = nrow(d), n_satisfy = sum(ok), coded_scenario_satisfies = co,
         verdict = verdict_of(mean(ok), co), basis = label)
}
on <- sc |> filter(central_layer == "on"); off <- sc |> filter(central_layer == "off")
stopifnot(nrow(on) + nrow(off) + n_nonfinite == 288)

verdict <- bind_rows(lapply(names(cond), function(k) judge(on, cond[[k]], "primary") |> mutate(claim = k, .before = 1))) |>
  mutate(condition = cond_text[claim], n_nonfinite_excluded = sum(!is.na(on$Y1701)) * 0 + n_nonfinite)
write_csv(verdict |> select(claim, s, coded_scenario_satisfies, verdict, n_scenarios, n_satisfy, condition, n_nonfinite_excluded),
          file.path(out, "verdict.csv"))

# Sensitivities (card section 5; not verdict-determining)
cond_dec <- function(d) d$R_decade <= 0.795 & d$trend_pop > d$trend_gdp
sens <- bind_rows(
  bind_rows(lapply(names(cond), function(k) judge(off, cond[[k]], "S1: central layer off, 144 U scenarios") |> mutate(claim = k, .before = 1))),
  judge(on, cond_dec, "S2: I2 decade means 1781-90 vs 1701-10, central layer on") |> mutate(claim = "I2", .before = 1),
  judge(off, cond_dec, "S2: I2 decade means 1781-90 vs 1701-10, central layer off") |> mutate(claim = "I2", .before = 1))
write_csv(sens, file.path(out, "sensitivity.csv"))

# Unweighted view: min-max range of each estimand across the 144 central-layer scenarios
ests <- c("Y1701", "Y1790", "R", "trend_gdp", "trend_pop", "bal_share_in_band", "bal_min", "bal_max",
          "ratio_GB", "ratio_NL", "R_decade")
ranges <- bind_rows(on |> mutate(layer = "on"), off |> mutate(layer = "off")) |>
  pivot_longer(all_of(ests), names_to = "estimand") |>
  group_by(central_layer = layer, estimand) |>
  summarise(min = min(value), p10 = quantile(value, 0.1), median = median(value), p90 = quantile(value, 0.9),
            max = max(value), coded_U = value[coded_U], .groups = "drop")
write_csv(ranges, file.path(out, "ranges.csv"))

print(as.data.frame(verdict |> select(claim, s, coded_scenario_satisfies, verdict)))
print(as.data.frame(sens |> select(claim, basis, s, coded_scenario_satisfies, verdict)))
print(as.data.frame(ranges), digits = 4)
