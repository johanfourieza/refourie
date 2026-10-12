# P20_HLF S6, card §5: 5A scenario grid, 5B one-at-a-time items (both anchors), 5C non-headline rows. None sets a verdict.
source("./P20_HLF/modern/00_common.R")
suppressPackageStartupMessages(library(sandwich))
tidyT <- function(r, block, item, col = "T") r$Tval |> transmute(block, item, anchor, k, T = .data[[col]],
  T3_pct = r$T3_pct, T6_pct = unname(r$T6_pct[k]), p_alt = r$p_alt, phi = r$phi)
cen <- chain(); out <- list(tidyT(cen, "central", "central"))

# 5A: road price x anchor
for (pa in c(0.023, 0.024)) out[[length(out) + 1]] <- tidyT(chain(p_alt = pa), "5A", paste0("road price ", pa))
# 5B-1 Crafts (log) framing
out[[length(out) + 1]] <- tidyT(cen, "5B-1", "Crafts log growth-rate framing", "crafts")
# 5B-2 road price from the seven printed observations (OLS on log distance at 197 miles, HC3, t(5))
road <- tribble(~dist, ~price, 100, 0.031, 250, 0.026, 300, 0.014, 80, 0.033, 30, 0.024, 54, 0.026, 155, 0.013)  # repro_r/01_clean.R
m <- lm(price ~ log(dist), data = road); X <- c(1, log(197)); fit <- sum(coef(m) * X)
se3 <- sqrt(drop(t(X) %*% vcovHC(m, "HC3") %*% X)); tc <- qt(0.975, df = nrow(road) - 2)
road_ci <- c(fit = fit, lo = fit - tc * se3, hi = fit + tc * se3, se_hc3 = se3, t_crit = tc)
out[[length(out) + 1]] <- tidyT(chain(p_alt = fit), "5B-2", "road price OLS fit at 197 mi")
for (s in c("lo", "hi")) out[[length(out) + 1]] <- tidyT(chain(p_alt = road_ci[[s]]), "5B-2",
  paste0("road price HC3 95% ", s, " end (diagnostic of 7 printed points)"))
# 5B-3 2nd/3rd class unit elasticity
phi23 <- v("T5_m_23") / (v("T5_c_23") + v("T5_g_23"))
out[[length(out) + 1]] <- tidyT(chain(cs_pax = v("T6_b") + ratio(phi23, 1) * v("T5_p_23")), "5B-3", "2nd/3rd class unit elasticity")
# 5B-4 all four elasticity-depreciation combinations (central pairing = CS lo + dep hi; CS hi + dep lo)
for (combo in list(c("lo", "T7_sp_hi", "CS lo + dep hi (central lo)"), c("hi", "T7_sp_lo", "CS hi + dep lo (central hi)"),
                   c("lo", "T7_sp_lo", "CS lo + dep lo"), c("hi", "T7_sp_hi", "CS hi + dep hi"))) {
  r <- chain(sp = c(lo = v(combo[2]), hi = v(combo[2])))
  out[[length(out) + 1]] <- tidyT(r, "5B-4", combo[3]) |> filter(k == combo[1])
}
# 5B-5 first-class phi on fare-only ratio; T6_b recomputed from Table 5
phi1f <- v("T5_i_1st") / v("T5_b_1st"); T6b_f <- ratio(phi1f, 1) * v("T5_p_1st")
out[[length(out) + 1]] <- tidyT(chain(cs_pax = T6b_f + v("T6_c")), "5B-5", sprintf("first-class fare-only phi %.2f (T6_b %.3f)", phi1f, T6b_f))
# 5B-6 freight elasticity 0 and 1
out[[length(out) + 1]] <- tidyT(chain(eps = c(lo = 0, hi = 0)), "5B-6", "freight elasticity 0 (unadjusted SS)")
out[[length(out) + 1]] <- tidyT(chain(eps = c(lo = 1, hi = 1)), "5B-6", "freight elasticity 1")
# 5B-7 linear demand
out[[length(out) + 1]] <- tidyT(chain(rfun = ratio_lin), "5B-7", "linear demand")
# 5B-8 rounding re-propagated from printed rounded prices (chain of repro_r/02_analysis.R, not its outputs)
a <- v("T3_a"); c3 <- a * v("T3_b"); pax <- list()
for (s in c("1st", "23")) {
  cc <- v(paste0("T5_a_", s)) * v(paste0("T5_b_", s)); f5 <- 0.5 * v(paste0("T5_a_", s)) / v(paste0("T5_e_", s))
  g5 <- v(paste0("T5_d_", s)) * f5; h5 <- v(paste0("T5_a_", s)); l5 <- 0.5 * h5 / v(paste0("T5_k_", s))
  m5 <- v(paste0("T5_d_", s)) * l5; j5 <- if (s == "1st") h5 * v("T5_i_1st") else 0
  pax[[s]] <- c(p = j5 - cc + m5 - g5, phi = (j5 + m5) / (cc + g5))
}
cs_pax8 <- ratio(pax[["1st"]][["phi"]], 1) * pax[["1st"]][["p"]] + pax[["23"]][["p"]]
out[[length(out) + 1]] <- tidyT(chain(p_alt = v("T3_e"), rail_rev = c3, cs_pax = cs_pax8), "5B-8", "rounded printed prices")

sens <- bind_rows(out) |> left_join(select(claims_H1, claim, k, X, b_lo, b_hi), by = "k") |>
  mutate(in_band = T >= b_lo & T <= b_hi)
# 5A share (6 scenarios per claim: 3 road prices x 2 anchors)
grid <- filter(sens, block %in% c("central", "5A"))
share5A <- grid |> group_by(claim) |> summarise(n_defined = sum(!is.na(T)), n_missing = sum(is.na(T)), min_T = min(T, na.rm = TRUE),
  max_T = max(T, na.rm = TRUE), share_in_band = mean(in_band, na.rm = TRUE), .groups = "drop")
print(share5A)
# 5C: social return (central chain) gross of opportunity cost, and of opportunity cost + depreciation
dep <- c(lo = v("T7_c_hi"), hi = v("T7_c_lo"))
sr <- tibble(block = "5C", item = rep(c("social return gross of opp. cost", "social return gross of opp. cost + depreciation"), 2),
             anchor = NA_character_, k = rep(c("lo", "hi"), each = 2)) |>
  mutate(T = if_else(str_detect(item, "depreciation"), 100 * (cen$a_k[k] + v("T7_b") + dep[k]) / v("T7_a"),
                     100 * (cen$a_k[k] + v("T7_b")) / v("T7_a")))
sens_out <- bind_rows(sens, sr, tibble(block = "5C", item = "H4 present value of net returns: not computable (no NOR or interest series)"),
                      tibble(block = "5B-2", item = names(road_ci), T = unname(road_ci), anchor = "road price (GBP/ton-mile)"))
write_csv(sens_out, file.path(out_dir, "sensitivities.csv")); write_csv(share5A, file.path(out_dir, "share_5A.csv"))
print(sens |> select(block, item, anchor, claim, T, T3_pct, T6_pct, in_band) |> mutate(across(where(is.numeric), ~ round(.x, 2))), n = 80, width = 200)
print(sr); print(road_ci)
