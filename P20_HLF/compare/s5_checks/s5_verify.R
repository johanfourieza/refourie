# P20_HLF S5: verify the social-saving chain from printed inputs and propagate scenarios to the headline (T8_tot, T3_pct, T6_pct).
# No original code survives; "original_code" in s5_effects.csv is therefore NA. Inputs are the printed table cells (claims.csv).
suppressPackageStartupMessages(library(tidyverse))
root <- "."; source(file.path(root, "tools", "paths.R"))
cl <- read_csv(file.path(root, "P20_HLF/claims/claims.csv"), show_col_types = FALSE)
v <- function(id) as.numeric(cl$reported_value[cl$claim_id == id])
ratio <- function(phi, eps) if (abs(eps - 1) < 1e-9) log(phi) / (phi - 1) else (phi^(1 - eps) - 1) / ((1 - eps) * (phi - 1))

GDP <- v("T3_SS") / (v("T3_pct") / 100)                 # 41.98, consistent with T6/T7/TX_p16 % rows
a <- v("T3_a"); rev <- v("T3_c"); b_un <- rev / a          # unrounded rail price
oc <- v("T7_b"); cap <- v("T7_a"); sp_lo <- v("T7_sp_lo"); sp_hi <- v("T7_sp_hi")
cs_pax <- v("T6_b") + v("T6_c"); B <- v("T8_b"); h <- v("T8_h"); g <- v("T8_g") / 100; Tn <- 1905 - 1873

chain <- function(e = v("T3_f") / a, csp = cs_pax, Bd = B, hh = h) {
  SS <- a * e - rev; phi <- e / b_un
  cl_ <- ratio(phi, 0.8) * SS + csp; ch_ <- ratio(phi, 0.5) * SS + csp
  tl <- cl_ + sp_hi; th <- ch_ + sp_lo
  c(T3_pct = 100 * SS / GDP, T6_pct_lo = 100 * cl_ / GDP, T6_pct_hi = 100 * ch_ / GDP,
    T8_tot_lo = 100 * tl / Bd + hh, T8_tot_hi = 100 * th / Bd + hh, tfp_lo = tl, tfp_hi = th)
}
base <- chain()
# Denominator scenarios for T8 b
B_g <- GDP * (1 - (1 + g)^(-Tn))                           # level change implied by printed g and GDP1905
impl_g <- -log(1 - B / GDP) / Tn                           # yearly growth implied by printed b
# Crafts growth-rate framing: TFP level gain as yearly growth points, divided by g
crafts <- function(tfp) 100 * (log(GDP / (GDP - tfp)) / Tn) / g + h
# 2nd/3rd class with unit elasticity instead of zero (walking counterfactual)
phi23 <- v("T5_m_23") / (v("T5_c_23") + v("T5_g_23"))
csp_e1 <- v("T6_b") + ratio(phi23, 1) * v("T5_p_23")

sc <- list(
  baseline_printed_chain = chain(),
  road_price_rebuild_fit_0.0213 = chain(e = 0.02126),
  road_price_fn12_simple_avg_0.023 = chain(e = 0.023),
  road_price_fn12_direct_0.024 = chain(e = 0.024),
  denominator_b_consistent_with_g = chain(Bd = B_g),
  pax23_unit_elasticity = chain(csp = csp_e1))
out <- imap_dfr(sc, ~ tibble(scenario = .y, claim_id = names(.x), scenario_value = unname(.x)))
cr <- tibble(scenario = "crafts_growth_rate_framing", claim_id = c("T8_tot_lo", "T8_tot_hi"),
             scenario_value = c(crafts(base["tfp_lo"]), crafts(base["tfp_hi"])))
sr <- tibble(scenario = "social_return_gross_of_opportunity_cost", claim_id = c("TX_p17_sr_lo", "TX_p17_sr_hi"),
             scenario_value = 100 * (base[c("tfp_lo", "tfp_hi")] + oc) / cap)
out <- bind_rows(out, cr, sr) |> filter(!str_starts(claim_id, "tfp")) |>
  mutate(published = map_dbl(claim_id, v), original_code = NA_real_)
cat(sprintf("GDP1905=%.2f  B_g=%.2f  growth implied by b=%.2f%%  printed g=%.2f%%  phi23=%.3f\n", GDP, B_g, 100*impl_g, 100*g, phi23))
cat(sprintf("T7 check: %.3f %.3f | T8 h from d*e/g: %.3f | sr: %.2f %.2f\n", v("T7_f")-v("T7_d_lo")+v("T7_e"), v("T7_f")-v("T7_d_hi")+v("T7_e"),
            v("T8_d")*v("T8_e")/100/v("T8_g")*100, 100*v("T8_a_lo")/cap, 100*v("T8_a_hi")/cap))
print(out |> mutate(across(where(is.numeric), ~ round(.x, 2))), n = 50)
write_csv(out, dscratch("P20_HLF", "compare", "p20_s5_raw.csv"))
