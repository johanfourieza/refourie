# Builds P06_FGa/compare/s5_effects.csv from scenario_results.csv (run_scenarios.R) and the other s5_checks.
suppressPackageStartupMessages({library(dplyr); library(readr)})
cl <- read_csv("P06_FGa/claims/claims.csv", show_col_types = FALSE) |> select(claim_id, published = reported_value)
r  <- read_csv("P06_FGa/compare/s5_checks/scenario_results.csv", show_col_types = FALSE)
base <- r |> filter(scenario == "base") |> select(claim_id, original_code = value)
notes <- c(wheat = "C1: V_Wheat = Wheatreaped*PWheat instead of prod(...) (l.180, 194)",
           units = "N1: Maine/Massachusetts crop quantities divided by 2.837757 (Combined sheet = raw bushels x 2.837757)",
           wheat_units = "C1 + N1 (both corrections)",
           base_va0 = "C2: desall3 keeps Virginia (crop value 0) - reproduces the printed $55.8",
           wheat_va0 = "C1 + Virginia as zeros", wheat_units_va0 = "C1 + N1 + Virginia as zeros",
           base_r03 = "C4: capitalisation 3% instead of 6% (original code otherwise)", base_r10 = "C4: 10% instead of 6%",
           wheat_units_r03 = "C1 + N1, 3%", wheat_units_r10 = "C1 + N1, 10%")
eff <- r |> filter(scenario != "base") |> inner_join(base, by = "claim_id") |>
  filter(!is.na(value), !is.na(original_code), abs(value - original_code) > 1e-9) |>
  left_join(cl, by = "claim_id") |>
  transmute(scenario, claim_id, published, original_code = signif(original_code, 6), scenario_value = signif(value, 6), note = notes[scenario])
extra <- tribble(
  ~scenario, ~claim_id, ~published, ~original_code, ~scenario_value, ~note,
  "check_110", "tx_p14_stel_total", "110.1", 59.5341, 110.092, "110.1 = obs-weighted Stellenbosch crop total for 1805 and 1815 only (check_110.R); components pool all four benchmarks",
  "check_slaveprice", "tx_p15_price_enslaved_16plus", "178.51", 512.830 / 178.51, 512.830 / 178.51, "Cape/US enslaved price ratio 2.87 (Cape 1798-1802 auction sales vs US 1782-1817 appraisals, ages 16+); conservative Cape price 126.97 = 0.71 x US",
  "breakeven_rate", "tx_p16_income_cape", "135.1", 6, 2.06, "capitalisation rate (%) at which Cape income = US income, original code, baseline prices (linear in r)",
  "breakeven_rate", "tx_p17_income_cape_cons", "92.3", 6, 3.92, "same, conservative Cape livestock prices: below ~3.9% the Cape falls below the US $72-76 in the original code",
  "breakeven_rate_fixed", "tx_p16_income_cape", "135.1", 6, 0, "after C1 + N1 the Cape exceeds the US at any rate >= 0 (crops alone $125.4 vs $25.8)",
  "farmer_filter", "T1_Stellenbosch_obs", "2962", 2962, 2867, "N2: code admits 95 wine-only households (Wine>0) as farmers; fn 45 excludes specialist viticulturalists (check_wine_only.R); explains pair-B N gaps (GR 3441, Swe 1754, Tul 1077)")
eff <- bind_rows(eff |> mutate(published = as.character(published)), extra)
write_csv(eff, "P06_FGa/compare/s5_effects.csv", na = "")
cat(nrow(eff), "rows\n")
