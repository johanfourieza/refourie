# P07_FG S6 step 3: the admissible sensitivities of card section 5 (exhaustive; none decides a verdict).
# 1 tornado (+ full 16-scenario table in scenarios.csv); 2 no T5 herd cap; 3 wheat only; 4 ratio of means;
# 5 labour allocation alpha in {0.5, 0} (central and A); 6 Cape Khoesan at the Drakenstein divisor;
# 7 concave herd scaling; 8 1752 and 1762 restored; 9 published-run totals (district 0 kept);
# 10 CSD series for g_K and g_S. Sensitivity 11 (total Theil level) is in 04_theil.R.
# Writes output/sensitivities.csv (long: sensitivity, variant, statistic, value).
source(file.path(here::here(), "P07_FG", "modern", "00_engine.R"))
d <- load_data(); tas <- tas_lookup(d); a <- tas$a
STATS <- c("K1685", "K1773", "gK", "gS", "rKS", "I1c", "T3_without", "T3_with", "P_T3", "T3_n_with", "T5_without", "T5_with", "P_T5", "T5_n_with",
           "T3_Stel_with", "T3_Drak_with", "P_T5_Stel", "P_T5_Drak")
long <- function(x, sens, variant, stats = STATS) x |> select(any_of(stats)) |>
  pivot_longer(everything(), names_to = "statistic", values_to = "value") |> mutate(sensitivity = sens, variant = variant, .before = 1)
res <- list(); add <- function(x) res[[length(res) + 1]] <<- x
central <- run_scenario(d, a_tas = a)
add(long(central, "0 central", "lambda 1, S text, gamma stated"))

# 1 tornado: each factor of A alone around the central scenario
add(long(run_scenario(d, lambda = 0.5, a_tas = a), "1 tornado", "lambda = 0.5"))
for (s in c("code", "Tas", "drift")) add(long(run_scenario(d, S = s, a_tas = a), "1 tornado", paste0("S = ", s)))
add(long(run_scenario(d, gamma = "none", a_tas = a), "1 tornado", "gamma = none"))
sc <- read_csv(file.path(OUT, "scenarios.csv"), show_col_types = FALSE)
for (st in c("gK", "rKS", "I1c", "P_T3", "P_T5")) {
  add(tibble(sensitivity = "1 A range (16 scenarios)", variant = "min", statistic = st, value = min(sc[[st]])))
  add(tibble(sensitivity = "1 A range (16 scenarios)", variant = "max", statistic = st, value = max(sc[[st]]))) }

# 2 no herd cap in T5 (population change, A4d)
add(long(run_scenario(d, cap5 = FALSE, a_tas = a), "2 no herd cap in T5", "central", c("T5_without", "T5_with", "P_T5", "T5_n_with")))
# 3 wheat only (different outcome)
add(long(run_scenario(d, out = "wheat", a_tas = a), "3 wheat only", "central", c("T3_without", "T3_with", "P_T3", "T5_without", "T5_with", "P_T5", "T3_Stel_with", "T3_Drak_with")))
# 4 ratio of means (different estimand)
add(long(run_scenario(d, rom = TRUE, a_tas = a), "4 ratio of means", "central", c("T3_without", "T3_with", "P_T3", "T5_without", "T5_with", "P_T5")))
# 5 labour allocation alpha, central and across A
for (al in c(0.5, 0)) {
  add(long(run_scenario(d, alpha = al, a_tas = a), "5 labour allocation", paste0("alpha = ", al, ", central"), c("T3_with", "P_T3", "T5_with", "P_T5")))
  sa <- bind_rows(lapply(seq_len(nrow(grid_A)), function(i) { g <- grid_A[i, ]; run_scenario(d, g$lambda, g$S, g$gamma, a, alpha = al) }))
  for (st in c("P_T3", "P_T5")) {
    add(tibble(sensitivity = "5 labour allocation", variant = paste0("alpha = ", al, ", A min"), statistic = st, value = min(sa[[st]])))
    add(tibble(sensitivity = "5 labour allocation", variant = paste0("alpha = ", al, ", A max"), statistic = st, value = max(sa[[st]]))) } }
# 6 Cape district Khoesan at the Drakenstein divisor
add(long(run_scenario(d, cape = TRUE, a_tas = a), "6 Cape Khoesan at Drakenstein divisor", "central"))
# 7 concave herd scaling
add(long(run_scenario(d, concave = TRUE, a_tas = a), "7 concave herd scaling (exponent 0.75)", "central"))
# 8 census years 1752 and 1762 restored (population change, A4d)
add(long(run_scenario(load_data(keep5262 = TRUE), a_tas = a), "8 1752 and 1762 restored", "central"))
# 9 published-run totals: district 0 kept (C5); Totals include district 0, as in the published run
d0 <- load_data(keep0 = TRUE)
add(long(run_scenario(d0, a_tas = a, dists = c(0, 1:3)), "9 published-run totals (district 0 kept)", "central"))
add(long(run_scenario(d0, S = "code", a_tas = a, dists = c(0, 1:3)), "9 published-run totals (district 0 kept)", "coded reference (S = code)"))
# 10 CSD series (Cape, Stellenbosch, Drakenstein) for g_K and g_S
x <- central |> transmute(gK = gK_csd, gS = gS_csd, rKS = rKS_csd, K1685 = K1685_csd, K1773 = K1773_csd)
add(long(x, "10 CSD series", "central", c("K1685", "K1773", "gK", "gS", "rKS")))
x <- run_scenario(d, S = "code", a_tas = a) |> transmute(gK = gK_csd, gS = gS_csd, rKS = rKS_csd, K1685 = K1685_csd, K1773 = K1773_csd)
add(long(x, "10 CSD series", "coded reference (S = code; basis of the published 3.82)", c("K1685", "K1773", "gK", "gS", "rKS")))

out <- bind_rows(res)
write_csv(out, file.path(OUT, "sensitivities_I1I2.csv"))
options(width = 200)
print(as.data.frame(out |> filter(statistic %in% c("gK", "gS", "rKS", "I1c", "P_T3", "P_T5")) |> mutate(value = round(value, 3)) |>
  pivot_wider(names_from = statistic, values_from = value)))
