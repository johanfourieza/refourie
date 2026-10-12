# Adds notes to the scenario table from s5_verify.R and writes compare/s5_effects.csv.
suppressPackageStartupMessages(library(tidyverse))
root <- "."; source(file.path(root, "tools", "paths.R"))
notes <- c(
  baseline_printed_chain = "Printed inputs through eq.1, fn17 ratio (unrounded phi), T7, T8: reproduces printed cells; no original code survives (original_code NA)",
  road_price_rebuild_fit_0.0213 = "Counterfactual ox-wagon rate from S3 log-distance fit on the 7 printed observations (paper sample unavailable)",
  road_price_fn12_simple_avg_0.023 = "Paper's own fn12 alternative (simple average of all figures); text calls the result 'only slightly higher'",
  road_price_fn12_direct_0.024 = "Paper's own fn12 alternative (direct price evidence only)",
  denominator_b_consistent_with_g = "T8 b recomputed as GDP1905*(1-(1+g)^-32) with printed g=2.21%; printed b=25.612 implies 2.94%/yr (S5-1)",
  pax23_unit_elasticity = "2nd/3rd class walking counterfactual with elasticity 1 instead of 0 (phi=1.414 full price)",
  crafts_growth_rate_framing = "TFP level gain converted to yearly growth points (log) over 32 years, divided by g=2.21%, plus h",
  social_return_gross_of_opportunity_cost = "Social return defined as (TFP gain + 3.7% opportunity cost)/capital; printed figure is net of the cost of capital (S5-2)")
read_csv(dscratch("P20_HLF", "compare", "p20_s5_raw.csv"), show_col_types = FALSE) |>
  mutate(note = notes[scenario], across(c(scenario_value), ~ round(.x, 3))) |>
  select(scenario, claim_id, published, original_code, scenario_value, note) |>
  write_csv(file.path(root, "P20_HLF/compare/s5_effects.csv"), na = "")
