# P01_BF S5: assemble compare/s5_effects.csv from the s5_0* check outputs (run s5_01..s5_04 first).
suppressPackageStartupMessages({library(tidyverse); library(here)})
proj <- here::here(); ck <- file.path(proj, "P01_BF", "compare", "s5_checks")
pub  <- c(T6_r4 = 51.38, T6_r5 = -28.63, T6_r6 = -20.25, T6_r8 = -21.38, T9_r5 = -43.9)
orig <- c(T6_r4 = 51.383539568749995, T6_r5 = -28.63142435775, T6_r6 = -20.25619366825, T6_r8 = -21.340409757625, T9_r5 = NA)
map6 <- c(eur = "T6_r4", id = "T6_r5", `in` = "T6_r6", mz = "T6_r8")
note1 <- c(orig_all = "R replica of l.1656 logit+mfx on data.dta (check: equals Stata S2)",
  swap_gender = "female (rebuild) instead of female2 (code)", swap_bdec = "birth decade from actual birth year (cyear-age) instead of cyear-(agegr+5) (l.83-84)",
  swap_origin = "S3 rebuild origin coding (workbook origincountry) instead of bco (l.1573-1580)",
  swap_bdec_origin = "rebuild birth decade and origin coding", rebuild_all = "all three rebuild codings (= pair B up to estimator details)",
  orig_robust = "same estimate; delta-method p with HC1-type robust vcov", orig_cluster_source = "same estimate; vcov clustered by court volume (43 clusters)",
  orig_AME = "average marginal effect (discrete change) instead of MEM", orig_LPM_HC1 = "linear probability model x125, birth-decade FE, HC1")
a <- read_csv(file.path(ck, "s5_01_T6_decomp.csv"), show_col_types = FALSE) |> filter(term %in% names(map6)) |>
  transmute(scenario, claim_id = map6[term], scenario_value = me125,
            note = paste0(note1[scenario], ifelse(is.na(p), "", sprintf("; p = %.4f", p))))
b <- read_csv(file.path(ck, "s5_02_origin_fix_T6.csv"), show_col_types = FALSE) |> filter(scenario != "orig") |>
  transmute(scenario, claim_id = map6[term], scenario_value = me125,
            note = recode(scenario, fix_kust = "original pipeline; origin Kust/Cust (Coromandel Coast, 4 obs) moved from Cape-born base to Indian",
                          fix_kust_westcoast = "as fix_kust plus Westcoast (2 obs) moved from Cape-born to slave-unknown",
                          fix_kust_westcoast_cochin = "as fix_kust_westcoast plus Coehin (Cochin, 1 obs) moved from Chinese to Indian"))
t9 <- read_csv(file.path(ck, "s5_02_T9_model_search.csv"), show_col_types = FALSE) |> filter(id == "T9_r5", spec != "OLS_ctrl_bdec") |>
  transmute(scenario = paste0("T9_", spec), claim_id = id, scenario_value = est,
            note = recode(spec, OLS_raw = "raw difference in cell ABCC (no controls) on original codings: reproduces all 10 T9 estimates within 0.09; Welch p = 0.0014",
                          OLS_ctrl = "within-Khoesan OLS with female2 and age23 (original cohorts)", OLS_ctrl_bdec = "adds birth-decade FE (collinear with cohort; not meaningful)",
                          logit_MEM_ctrl = "logit MEM x125 with female2, age23", T8_diff = "T8 col 1 ko_mid - ko_early (controlled, full-sample model)"))
t9b <- read_csv(file.path(ck, "s5_04_T9r5_pairB.csv"), show_col_types = FALSE) |> filter(cohort == "coh_r") |>
  transmute(scenario = paste0("T9_rebuildcohort_", model), claim_id = "T9_r5", scenario_value = est,
            note = sprintf("rebuild cohort assignment (actual birth year); n = %d (published 217)", n))
res <- bind_rows(a, b, t9, t9b) |> mutate(published = pub[claim_id], original_code = orig[claim_id]) |>
  select(scenario, claim_id, published, original_code, scenario_value, note) |> arrange(claim_id, scenario)
write_csv(res, file.path(proj, "P01_BF", "compare", "s5_effects.csv"), na = "")
print(res |> mutate(scenario_value = round(scenario_value, 2)) |> select(-note), n = 100)
