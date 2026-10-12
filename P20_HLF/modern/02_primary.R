# P20_HLF S6, card §4: central analysis (two-anchor conditional scenario envelope) and §8 verdicts.
source("./P20_HLF/modern/00_common.R")
r <- chain()
# §4 failure rules: missing inputs or undefined anchor -> not-testable, no single-anchor fallback
anchor_ok <- all(is.finite(unlist(r$A))) && all(unlist(r$A) > 0)
prim <- r$Tval |> left_join(select(claims_H1, claim, k), by = "k") |>
  mutate(GDP1905 = r$GDP, phi = r$phi, SS = r$SS, f = r$f, CS = unname(r$CS[k]),
         share_tfp = 100 * a_k / b_j, share_capital = 100 * f / g_j)
write_csv(prim, file.path(out_dir, "primary.csv"))

env <- prim |> group_by(claim, k) |> summarise(L = if (anchor_ok) min(T) else NA_real_, U = if (anchor_ok) max(T) else NA_real_,
                                                T_Ab = T[anchor == "A_b"], T_Ag = T[anchor == "A_g"], .groups = "drop") |>
  left_join(claims_H1, by = c("claim", "k"))
vd <- env |> rowwise() |> mutate(vr = list(verdict_rule(L, U, X, b_lo, b_hi)), verdict = vr[1], rule = vr[2],
                                 printed_in_E = X >= L & X <= U, H1r_in_22_25 = L >= 22 & U <= 25, plaus_flag = U > 1.5 * X) |>
  ungroup() |> select(-vr)
print(vd, width = 250)
h1 <- vd$verdict[which.min(ord[sub(" .*", "", vd$verdict)])]

f2 <- function(x) sprintf("%.2f", x)
verdict <- bind_rows(
  vd |> transmute(claim = paste0(claim, " (", id, " = ", X, ")"),
                  estimate = paste0("A_b ", f2(T_Ab), "; A_g ", f2(T_Ag)),
                  interval = paste0("scenario envelope [", f2(L), ", ", f2(U), "] (deterministic)"),
                  test_p = NA_character_, threshold_or_band = paste0("A8/A8a band [", b_lo, ", ", b_hi, "]; A3 floor ", 0.5 * X),
                  verdict, rule),
  tibble(claim = "H1 (summary, 22-25%)", estimate = "weaker of H1a, H1b", interval = NA, test_p = NA,
         threshold_or_band = "ordering §8", verdict = h1, rule = "§8 H1 summary"),
  tibble(claim = c("H2 (T3_pct = 12.01)", "H3a (T6_pct_lo = 10.0)", "H3b (T6_pct_hi = 11.4)", "H4 (TX_p19_pv = 0.99)"),
         estimate = c(f2(r$T3_pct), f2(r$T6_pct[["lo"]]), f2(r$T6_pct[["hi"]]), "not computable"),
         interval = NA, test_p = NA, threshold_or_band = c("[10.809, 13.211]", "[9.00, 11.00]", "[10.26, 12.54]", "[0.891, 1.089]"),
         verdict = "not-testable", rule = c("§8 / §10.2", "§8 / §10.2", "§8 / §10.2", "§8 / §10.3")))
write_csv(verdict, file.path(out_dir, "verdict.csv"))
write_csv(vd, file.path(out_dir, "envelope.csv"))
print(verdict, width = 250)
