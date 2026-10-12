# Builds P07_FG/compare/s5_effects.csv from scenario_results.csv (build_scenarios.sh + parse_scenarios.R) and the other s5_checks.
suppressPackageStartupMessages({library(dplyr); library(readr); library(stringr)})
cl <- read_csv("P07_FG/claims/claims.csv", show_col_types = FALSE) |> select(claim_id, published = reported_value) |> mutate(published = as.character(published))
r <- read_csv("P07_FG/compare/s5_checks/scenario_results.csv", show_col_types = FALSE) |>
  mutate(claim_id = claim_id |> str_replace("_slagprod$", "_wheat_without") |> str_replace("_labgprod$", "_wheat_with") |>
           str_replace("_slawprod$", "_wine_without") |> str_replace("_labwprod$", "_wine_with") |> str_replace("_n_wheat_without$", "_n"),
         claim_id = ifelse(claim_id == "tx_growth_all_1685_1773", "tx_p205_kh_growth", claim_id),
         claim_id = ifelse(claim_id == "tx_swe_ratio_maleslaves", "tx_p205_swe_ratio", claim_id)) |>
  filter(!str_detect(claim_id, "_n_wheat_with$"))
base <- r |> filter(scenario == "base") |> select(claim_id, original_code = value)
notes <- c(stel2x = "C1: Stellenbosch divisors 95/115/135 (text: 'double' the Swellendam rates) instead of code 142.5/172.5/202.5 (CK:37-39)",
           keep0 = "C5: CK:8 'drop if district==0' disabled (reproduces the published Totals)",
           div_x2 = "C8: all herd-value-per-Khoesan divisors x2 (half the Khoesan)", div_x05 = "C8: all divisors x0.5 (twice the Khoesan)",
           wheatonly = "N1: 'wheat' productivity on wheat only instead of wheat+rye+barley (CK:51)",
           t6male = "C6: T6 1-5 split on slavemales!=0 instead of slaves!=0 (CK:66)",
           uniform = "C8/T6: one divisor per district (no slave-category gradient)",
           keep5262 = "C12: keep the 1752 and 1762 censuses dropped at CK:6")
eff <- r |> filter(scenario != "base") |> inner_join(base, by = "claim_id") |>
  filter(!is.na(value), !is.na(original_code), abs(value - original_code) > 1e-6) |>
  left_join(cl, by = "claim_id") |>
  filter(!is.na(published) | str_detect(claim_id, "district2|growth_csd|swe_ratio_allslaves")) |>
  transmute(scenario, claim_id, published, original_code = signif(original_code, 6), scenario_value = signif(value, 6), note = notes[scenario])
gdp <- read_csv("P07_FG/compare/s5_checks/gdp_numerator_check.csv", show_col_types = FALSE)
extra <- tribble(
  ~scenario, ~claim_id, ~published, ~original_code, ~scenario_value, ~note,
  "recompute", "tx_p205_kh_growth", "3.8", 3.819, 4.685, "C2: 3.8% is the Cape/Stellenbosch/Drakenstein series (121.8 -> 3,295.7); the stated endpoints 122 -> 6,843 (All regions) give 4.68%. All-region slaves 222 -> 7,101 grow 4.02%, so Khoesan grew faster than slaves, not 'equivalent'",
  "recompute", "tx_p205_swe_ratio", "6.6", 6.598, 9.191, "C3: 6,783 / 1,028 (all slaves) = 6.6; per male slave as the text says (738) = 9.2. 6.6 is the right comparator for Viljoen's 'per slave'",
  "recompute", "T2_Totalpopulation_Total", "38144", 38144, 52317, "C4: Dataset.xlsx 'Khoe pop 1790'!F7 = SUM(B7:D7) omits Graaff-Reinet (14,173); other Total cells include it",
  "share_not_level", "T7_TheilBetween_khoesan", "0.35", 0.3538, 0.4775, "C7: Khoesan-added Theil between/within are levels summing to the total 0.741 (Inequality!D12); as a share between = 0.48 (FvF share 0.33)",
  "share_not_level", "T7_TheilWithin_khoesan", "0.39", 0.3872, 0.5225, "C7: as a share within = 0.52 (FvF share 0.67), not 0.39",
  "gdp_numerator", "tx_p214_gdp_year_new", "1710", NA, NA, sprintf("N2: in KhoesanGDPnew.xlsx the Khoesan count also raises the numerator (resteconomy!C,D craftsmen = f(Population!AC)); vs a pure denominator rescaling, model GDP pc is %.1f%%-%.1f%% higher (1701-1795). Crossing years unaffected (S2)", min(gdp$gap_pct), max(gdp$gap_pct)))
eff <- bind_rows(eff, extra)
write_csv(eff, "P07_FG/compare/s5_effects.csv", na = "")
cat(nrow(eff), "rows\n")
