# P11_FJS S6 06: verdicts by the card's §8 tables, applied mechanically in order (first rule that applies decides).
# Outputs: output/primary.csv, output/verdict.csv, output/summary.csv
source("./P11_FJS/modern/00_common.R")
chk  <- read_csv(file.path(OUT, "check_corrections_off.csv"), show_col_types = FALSE)
miss <- read_csv(file.path(OUT, "check_missing.csv"), show_col_types = FALSE)
h1   <- read_csv(file.path(OUT, "primary_h1.csv"), show_col_types = FALSE)
h2   <- read_csv(file.path(OUT, "primary_h2.csv"), show_col_types = FALSE)
sp   <- read_csv(file.path(OUT, "sp_rise.csv"), show_col_types = FALSE)
eb   <- read_csv(file.path(OUT, "eprog_boot.csv"), show_col_types = FALSE)

gate_ok <- all(chk$pass, na.rm = TRUE)                 # §4 corrections-off check (row 4 is the double-arithmetic diagnostic, pass = NA)
miss00 <- miss$any_tax_input_missing[miss$jaar == 1700]; miss73 <- miss$any_tax_input_missing[miss$jaar == 1773]
g <- function(d, q) d$value[d$quantity == q]
S00 <- g(h1, "S00"); S73 <- g(h1, "S73"); Dl <- g(h1, "Delta")
comp_ok <- all(is.finite(c(S00, S73, Dl)))

v_h100 <- if (!gate_ok || !comp_ok || miss00) c("not-testable", 0) else if (S00 < 50) c("confirmed", 1) else c("qualified (threshold missed)", 2)
v_h173 <- if (!gate_ok || !comp_ok || miss73) c("not-testable", 0) else if (S73 > 61) c("confirmed", 1) else c("qualified (threshold missed)", 2)
v_rise <- if (!gate_ok || !comp_ok || miss00 || miss73) c("not-testable", 0) else if (Dl > 0) c("confirmed", 1) else
  if (Dl == 0) c("weakened (no increase)", 2) else c("overturned (the burden fell)", 3)

R89 <- g(h2, "R89"); r89_ok <- h2$inputs_readable[h2$quantity == "R89"]
v_h289 <- if (!r89_ok) c("not-testable", 0) else if (R89 <= 0) c("overturned", 1) else if (R89 >= 36 && R89 <= 44) c("confirmed", 2) else
  if (R89 < 36) c("qualified (ratio below the stated value)", 3) else c("qualified (ratio above the stated value)", 4)
D <- h2 |> filter(grepl("^D_", quantity))
v_yrs <- if (!all(D$inputs_readable)) c("not-testable", 0) else if (any(D$value < 0)) c("overturned (a reported year in surplus)", 1) else
  if (any(D$value == 0)) c("qualified (a balanced year)", 2) else c("confirmed", 3)

spm <- sp |> filter(run == "main iid", quantity == "Delta")
fmt_ci <- function(lo, hi, d = 2) sprintf(paste0("[%.", d, "f, %.", d, "f]"), lo, hi)
eR <- function(q) eb |> filter(quantity == q)
ver <- tribble(
  ~claim, ~estimate, ~interval, ~test_p, ~threshold_or_band, ~verdict, ~rule,
  "H1-00 top-decile share 1700 < 50%", sprintf("S00 = %.2f", S00), "none (census reading, §1)", "n/a", "S00 < 50 (A8 threshold)", v_h100[1], paste0("H1-00 #", v_h100[2]),
  "H1-73 top-decile share 1773 > 61%", sprintf("S73 = %.2f", S73), "none (census reading, §1)", "n/a", "S73 > 61 (A8 threshold)", v_h173[1], paste0("H1-73 #", v_h173[2]),
  "H1-rise burden increased 1700-1773", sprintf("Delta = %.2f pp", Dl), "none (census reading, §1)", "n/a", "Delta > 0 on full enumerations (A8 exception)", v_rise[1], paste0("H1-rise #", v_rise[2]),
  "H1-prog tax system progressive", "", "", "", "", "not-testable", "§8 (no income measure)",
  "H1-incr progressiveness increased", "", "", "", "", "not-testable", "§8 (no income measure)",
  "H2-89 deficit/GDP 40% in 1789", sprintf("R89 = %.1f%%", R89), "none (printed inputs)", "n/a", "36 <= R89 <= 44 (A8 ratio ±10%)", v_h289[1], paste0("H2-89 #", v_h289[2]),
  "H2-yrs deficit in every Image 6 year (1777-1794)", paste(sprintf("%s = %s", sub("D_", "", D$quantity), trimws(format(D$value, big.mark = ","))), collapse = "; "),
    "none (printed inputs)", "n/a", "D_t > 0 in all 5 universe years", v_yrs[1], paste0("H2-yrs #", v_yrs[2]),
  "H2-full deficit throughout 1652-1795", "", "", "", "", "not-testable", "§8 (no expenditure data outside 1777-1794)",
  "H2-ext deficits not extractive", "", "", "", "", "not-testable", "§8",
  "SP-rise superpopulation Delta (iid bootstrap)", sprintf("Delta = %.2f pp", spm$estimate), fmt_ci(spm$lo, spm$hi), "n/a", "reported only", "different-estimand", "§8 (never votes)",
  "E-prog R = tax share / output share of top slave decile, 1700 -> 1773",
    sprintf("R00 = %.3f; R73 = %.3f; dR = %.3f", eR("R_1700")$estimate, eR("R_1773")$estimate, eR("dR")$estimate),
    sprintf("R00 %s; R73 %s; dR %s", fmt_ci(eR("R_1700")$lo, eR("R_1700")$hi, 3), fmt_ci(eR("R_1773")$lo, eR("R_1773")$hi, 3), fmt_ci(eR("dR")$lo, eR("dR")$hi, 3)),
    "n/a", "reported only", "different-estimand", "§8 (never votes)")
write_csv(ver, file.path(OUT, "verdict.csv"))

prim <- bind_rows(
  h1 |> mutate(row = c("H1-00", "H1-73", "H1-rise"), note = "full enumerations, fractional tie rule, corrected tax (§3)"),
  h2 |> filter(quantity == "R89") |> transmute(quantity, value, row = "H2-89", note = "printed Image 6 revenue, expenditure, GDP"),
  D |> transmute(quantity, value, row = "H2-yrs", note = "Exp - Rev, printed Image 6"),
  tibble(quantity = "corrections-off check passed", value = as.numeric(gate_ok), row = "gate", note = "check_corrections_off.csv"))
write_csv(prim, file.path(OUT, "primary.csv"))

ord <- c("overturned" = 1, "weakened" = 2, "qualified" = 3, "confirmed" = 4)
summ <- function(grp, rows) { v <- ver$verdict[rows]; base_v <- sub(" .*", "", v); assessed <- base_v %in% names(ord)
  tibble(group = grp, rows_assessed = sum(assessed), rows_not_testable = sum(v == "not-testable"), rows_different_estimand = sum(v == "different-estimand"),
         weakest_verdict = if (any(assessed)) names(ord)[min(ord[base_v[assessed]])] else "not-testable") }
sm <- bind_rows(summ("H1", c(1:5, 10, 11)), summ("H2", 6:9)) |>
  mutate(note = c("progressivity and its increase not assessed (not-testable); SP-rise and E-prog are different-estimand",
                  "both assessed rows re-verify printed secondary arithmetic; non-extraction and the 1652-1795 span not assessed"))
write_csv(sm, file.path(OUT, "summary.csv"))
print(ver |> select(claim, estimate, verdict, rule), width = 200); print(sm, width = 200)
