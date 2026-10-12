# 02: Card §4.1 verification rule, run before any modern output.
# (a) K1-K5 off, code filter (> 0 incl. wine), all households for cattle, unweighted, Final / r = 0.06 / V3 = A
#     -> repro_original/results_original.csv, eight headline rows, |diff| < 1e-9.
# (b) K1 + K2 only -> S5 `wheat_units` values, |diff| < 1e-6.
source("P06_FGa/modern/00_helpers.R")
fg <- load_raw(); cmap <- coverage_map(fg); P <- load_prices()

# Original-code pipeline with switchable K1/K2 (D6 = this function with k1 = k2 = FALSE).
code_claims <- function(k1, k2, k2fac = K2FAC) {
  d <- prep(fg, cmap, k2 = k2, k3 = FALSE, k2fac = k2fac)
  d$farm <- farmer(d, "code")
  v1 <- value_hh(d, P, "Final", k1 = k1, na0 = TRUE)
  v2 <- value_hh(d, P, "Final2", k1 = k1, na0 = TRUE)
  f1 <- v1[v1$farm, ]; f2 <- v2[v2$farm, ]
  ctry <- function(x) ifelse(x$is_cape, "Cape", "US")
  m <- function(x, sel, col) mean(x[[col]][sel])
  out <- list()
  a <- function(id, v) out[[id]] <<- v
  # income, crops+wine (desall3: farmers, Virginia excluded, by country); conservative (desall4, Final2)
  nv1 <- f1$District != "Virginia"; nv2 <- f2$District != "Virginia"
  for (cc in c("Cape", "US")) {
    s1 <- nv1 & ctry(f1) == cc; s2 <- nv2 & ctry(f2) == cc
    lc <- tolower(cc)
    a(paste0("tx_p16_income_", lc), m(f1, s1, "income"))
    a(paste0("tx_p16_cropval_", lc), m(f1, s1, "VG"))
    a(paste0("tx_p16_cropwine_", lc), m(f1, s1, "cropwine"))
    a(paste0("tx_p17_income_", lc, "_cons"), m(f2, s2, "income"))
  }
  a("tx_p17_income_cape_cons_wine", mean((f2$income + f2$VW + f2$VB)[nv2 & f2$is_cape]))
  # cattle: all households incl. Virginia, by country
  a("tx_p13_cattle_cape", mean(v1$Cattle[v1$is_cape])); a("tx_p13_cattle_us", mean(v1$Cattle[!v1$is_cape]))
  # Table 1 Ginis (gini1/gini2 use fg2_V; crop prices identical in Final and Final2)
  code <- c(GraaffReinet = "Graaff Reinet", Stellenbosch = "Stellenbosch", Swellendam = "Swellendam",
            Tulbagh = "Tulbagh", Maine = "Maine", Massachusetts = "Massachusetts", Virginia = "Virginia")
  for (k in names(code)) {
    s <- f2$District == code[[k]]
    if (k != "Virginia") {
      a(paste0("T1_", k, "_crops"), wgini(f2$VG[s]))
      a(paste0("T1_", k, "_cropswine"), wgini(f2$cropwine[s]))
    }
    if (!k %in% c("Maine", "Massachusetts")) a(paste0("T1_", k, "_enslaved"), wgini(f2$Slaves_raw[s]))
  }
  # Table A1 / p.15 quantities (Maine, Massachusetts): farmer means; crops = row sum of quantities
  for (st in c(Maine = "Maine", Massachusetts = "Massachusetts")) {
    s <- f1$District == st; tag <- if (st == "Maine") "maine" else "mass"
    tot <- mean(rowSums(f1[s, GRAINS], na.rm = TRUE))
    a(paste0("A1_", st, "_crops"), tot); a(paste0("tx_p15_", tag, "_total"), tot)
    for (g in GRAINS) {
      nm <- tolower(sub("reaped", "", g)); val <- mean(f1[[g]][s])
      a(paste0("A1_", st, "_", nm), val); a(paste0("tx_p15_", tag, "_", nm), val)
    }
  }
  for (k in c(mass = "Massachusetts", tulb = "Tulbagh", stel = "Stellenbosch", maine = "Maine", gr = "Graaff Reinet"))
    a(paste0("tx_p16_cropval_", names(which(c(mass = "Massachusetts", tulb = "Tulbagh", stel = "Stellenbosch", maine = "Maine", gr = "Graaff Reinet") == k))), mean(f1$VG[f1$District == k]))
  a("tx_p16_cropwine_stel", mean(f1$cropwine[f1$District == "Stellenbosch"]))
  a("tx_p16_cropwine_tulb", mean(f1$cropwine[f1$District == "Tulbagh"]))
  # Fig 6 medians: all households, by country, log10 boxplot middle (zeros dropped as non-finite)
  md <- function(x) 10^unname(quantile(log10(x[x > 0]), 0.5, type = 7))
  a("F6_crops_cape_median", md(v1$VG[v1$is_cape])); a("F6_crops_us_median", md(v1$VG[!v1$is_cape]))
  a("F6_cropswine_cape_median", md((v1$VG + v1$VW)[v1$is_cape])); a("F6_cropswine_us_median", md((v1$VG + v1$VW)[!v1$is_cape]))
  tibble(claim_id = names(out), value = unlist(out))
}

# (a)
ra <- code_claims(k1 = FALSE, k2 = FALSE)
orig <- read_csv("P06_FGa/repro_original/results_original.csv", show_col_types = FALSE)
heads <- c("tx_p16_income_cape", "tx_p16_income_us", "tx_p16_cropwine_cape", "tx_p13_cattle_cape",
           "tx_p13_cattle_us", "T1_Virginia_enslaved", "T1_Stellenbosch_enslaved", "T1_GraaffReinet_crops")
va <- ra |> filter(claim_id %in% heads) |> inner_join(orig |> select(claim_id, target = value), by = "claim_id") |>
  mutate(check = "a", abs_diff = abs(value - target), tol = 1e-9, pass = abs_diff < tol)
# (b) against the unrounded S5 scenario values (source of s5_effects.csv) and the rounded s5_effects.csv
rb <- code_claims(k1 = TRUE, k2 = TRUE)
s5e <- read_csv("P06_FGa/compare/s5_effects.csv", show_col_types = FALSE) |> filter(scenario == "wheat_units")
s5r <- read_csv("P06_FGa/compare/s5_checks/scenario_results.csv", show_col_types = FALSE) |> filter(scenario == "wheat_units") |>
  distinct(claim_id, .keep_all = TRUE)
vb <- rb |> filter(claim_id %in% s5e$claim_id) |>
  inner_join(s5r |> select(claim_id, target = value), by = "claim_id") |>
  left_join(s5e |> distinct(claim_id, .keep_all = TRUE) |> select(claim_id, s5_effects_printed = scenario_value), by = "claim_id") |>
  mutate(check = "b", abs_diff = abs(value - target), tol = 1e-6, pass = abs_diff < tol,
         rel_diff_printed = abs(value - s5_effects_printed) / abs(s5_effects_printed))
# (b') the same check with S5's rounded factor 2.837757 (run_scenarios.R), to attribute any residual
rb2 <- code_claims(k1 = TRUE, k2 = TRUE, k2fac = 2.837757)
vb2 <- rb2 |> filter(claim_id %in% s5e$claim_id) |> inner_join(s5r |> select(claim_id, target = value), by = "claim_id") |>
  mutate(check = "b_s5factor", abs_diff = abs(value - target), tol = 1e-6, pass = abs_diff < tol)
cat("(b') S5 factor:", sum(vb2$pass), "/", nrow(vb2), "pass; max |diff| =", signif(max(vb2$abs_diff), 3), "
")
cat("(b) rows:", nrow(vb), "of", n_distinct(s5e$claim_id), "s5_effects wheat_units rows\n")
ver <- bind_rows(va, vb, vb2)
write_csv(ver, file.path(OUT, "verification.csv"))
cat("(a)", sum(va$pass), "/", nrow(va), "pass; max |diff| =", signif(max(va$abs_diff), 3), "\n")
cat("(b)", sum(vb$pass), "/", nrow(vb), "pass; max |diff| =", signif(max(vb$abs_diff), 3),
    "; max rel diff vs printed s5_effects =", signif(max(vb$rel_diff_printed, na.rm = TRUE), 3), "\n")
print(as.data.frame(ver |> filter(!pass)))
saveRDS(list(a = ra, b = rb), SCR("verify_objects.rds"))
# Stop rule: (a) must pass; (b) must pass with the card factor, or (DEVIATIONS D1) every card-factor
# residual must vanish under S5's own factor and be < 1e-6 relative.
ok_b <- all(vb$pass) || (all(vb2$pass) && max(vb2$abs_diff) < 1e-9 && max(vb$abs_diff / abs(vb$target)) < 1e-6)
if (!all(va$pass) || !ok_b) stop("Verification failed: see output/verification.csv and DEVIATIONS.md")
cat("Verification passed (see DEVIATIONS D1 for (b)).
")
