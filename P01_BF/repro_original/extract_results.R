# P01_BF S2: builds results_original.csv from the Stata run outputs (output/s2_estimates.csv, logs/run_F_T7diag.log).
# Pure bookkeeping: values x125 as the paper does (Juif-Baten scaling); p-values from mfx z = b/se.
suppressPackageStartupMessages({library(readr); library(dplyr); library(stringr)})
root <- here::here("P01_BF")
est <- read_csv(file.path(root, "repro_original/output/s2_estimates.csv"), show_col_types = FALSE) |>
  mutate(across(c(model, term), str_trim))
claims <- read_csv(file.path(root, "claims/claims.csv"), show_col_types = FALSE, col_types = cols(.default = "c"))
g <- function(m, t, w = "b") est[[w]][est$model == m & est$term == t]
out <- list(); add <- function(id, value, se = NA, n = NA, ovr = NA, note = "") out[[length(out) + 1]] <<- tibble(claim_id = id, source = "original", value = value, se = se, n = n, status_override = ovr, note = note)

# Table 6: logit, mfx x125 (run_D_main.do = original l.1656-1657)
t6 <- c(r1 = "female2", r2 = "age23", r3 = "b_cn", r4 = "b_eur", r5 = "b_id", r6 = "b_in", r7 = "b_kobc", r8 = "b_mz", r9 = "b_oth_bl")
for (r in names(t6)) {
  b <- g("T6_mfx", t6[[r]]); s <- g("T6_mfx", t6[[r]], "se")
  add(paste0("T6_", r), 125 * b, 125 * s, 1802, note = paste0("mfx dy/dx x125, ", t6[[r]], "; l.1656-1657"))
  add(paste0("T6_", r, "_p"), 2 * pnorm(-abs(b / s)), NA, 1802, note = "mfx p-value (normal)")
}
add("T6_n", g("T6_mfx", "female2", "n"), note = "e(N) l.1656")
add("T6_rsq", g("T6_mfx", "female2", "stat"), n = 1802, note = "e(r2_p) l.1656")

# Table 8 col 1: coefficients from OLS l.1667 x125 (outreg2 stnum, l.1668); SEs: robust OLS l.1672 (unscaled in print), reported here x125
t8 <- c(r1 = "age23", r2 = "eur_early", r3 = "eur_mid", r4 = "eur_post", r5 = "id_early", r6 = "id_mid", r7 = "in_early", r8 = "in_mid",
        r9 = "ko_early", r10 = "ko_mid", r11 = "ko_post", r12 = "mz_mid", r13 = "mz_post", r14 = "otb_early", r15 = "otb_mid", r16 = "otb_post",
        r17 = "za_mid", r18 = "za_post", r20 = "_cons")
for (r in names(t8)) add(paste0("T8_", r, "_c1"), 125 * g("S2_lpm", t8[[r]]), 125 * g("m1", t8[[r]], "se"), 1802,
  note = sprintf("OLS coef x125 (l.1667-1668); se = robust (l.1672) x125; printed unscaled robust se = %.4f", g("m1", t8[[r]], "se")))
add("T8_orphse_c1", g("m1", "female2", "se"), n = 1802, note = "equals robust SE of female2 (l.1672), coefficient not printed")
add("T8_rsq_c1", g("S2_lpm", "_cons", "stat"), n = 1802, note = "e(r2) l.1667")
add("T8_n_c1", g("S2_lpm", "_cons", "n"), note = "e(N) l.1667")

# Figure 4: level = (constant + interaction) x125, OLS l.1667
cons <- g("S2_lpm", "_cons")
f4 <- c("eur_early", "eur_mid", "eur_post", "id_early", "id_mid", "in_early", "in_mid", "_cons", "ko_early", "ko_mid", "ko_post",
        "mz_mid", "mz_post", "za_mid", "za_post", "otb_early", "otb_mid", "otb_post")
for (i in seq_along(f4)) add(paste0("F4_", i), 125 * (cons + if (f4[i] == "_cons") 0 else g("S2_lpm", f4[i])), n = 1802,
  note = paste0("125*(_cons + ", f4[i], ") from l.1667"))

# Table 7: counts of the interaction dummies (l.1610-1645) in the estimation sample (run_F_T7diag.do)
lg <- readLines(file.path(root, "repro_original/logs/run_F_T7diag.log"))
t7c <- str_match(lg[str_detect(lg, "^S2T7 ")], "^S2T7 ([^ ]+) ([0-9]+)(?: ([0-9]+))?")
cnt <- setNames(as.numeric(ifelse(is.na(t7c[, 4]), t7c[, 3], t7c[, 4])), t7c[, 2])
t7 <- c(r1_c1 = "eur_early", r1_c2 = "eur_mid", r1_c3 = "eur_post", r2_c1 = "id_early", r2_c2 = "id_mid", r3_c1 = "in_early", r3_c2 = "in_mid",
        r4_c1 = "ko_early", r4_c2 = "ko_mid", r4_c3 = "ko_post", r5_c2 = "mz_mid", r5_c3 = "mz_post", r6_c2 = "za_mid", r6_c3 = "za_post",
        r7_c1 = "otb_early", r7_c2 = "otb_mid", r7_c3 = "otb_post")
l1699 <- read_csv(file.path(root, "repro_original/output/T7_counts_bco_bcoh.csv"), show_col_types = FALSE)
for (r in names(t7)) add(paste0("T7_", r), cnt[[t7[[r]]]], n = cnt[[t7[[r]]]],
  note = paste0("sum of dummy ", t7[[r]], " in est. sample; ", if (t7[[r]] %in% c("id_mid", "in_mid", "otb_early")) "l.1699 bco x bcoh collapse gives a different cell (50/27/346), see audit" else "equals l.1699 collapse"))

# Text claims computable from the same runs
eu <- 125 * (cons + sapply(c("eur_early", "eur_mid", "eur_post"), function(v) g("S2_lpm", v)))
add("TXT_p633_a", 1802, n = 1802, note = "e(N) l.1656")
add("TXT_p639_a", sum(cnt[c("eur_early", "eur_mid", "eur_post")]), note = "Europeans in est. sample")
add("TXT_p639_b", sum(cnt[c("ko_early", "ko_mid", "ko_post")]), note = "Khoesan in est. sample")
add("TXT_p639_c", 1802 - 392 - 368 - cnt[["b_cn_est"]], note = "1802 minus Europeans, Khoesan and 16 Chinese")
add("TXT_p645_a", 125 * g("T6_mfx", "b_eur"), 125 * g("T6_mfx", "b_eur", "se"), 1802, note = "T6 European")
add("TXT_p645_b", 125 * g("T6_mfx", "b_in"), 125 * g("T6_mfx", "b_in", "se"), 1802, note = "text says Indians -29; code Indian = -20.26 (SE Asian = -28.63)")
add("TXT_p645_c", 125 * g("T6_mfx", "b_id"), 125 * g("T6_mfx", "b_id", "se"), 1802, note = "text says SE Asians -20; code SE Asian = -28.63 (Indian = -20.26)")
add("TXT_p645_d", 125 * g("T6_mfx", "b_mz"), 125 * g("T6_mfx", "b_mz", "se"), 1802, note = "T6 Mozambican")
add("TXT_p646_a", min(eu), note = "min European cohort level (F4)")
add("TXT_p646_b", max(eu), note = "max European cohort level (F4)")
add("TXT_p650_c", 125 * cons, note = "T8 constant = Chinese level")
add("TXT_p650_d", 125 * (cons + g("S2_lpm", "mz_mid")), note = "Mozambique 1750s-80s level (F4_12)")

res <- bind_rows(out)
# Everything else: no surviving code
why <- function(id) case_when(
  str_detect(id, "^T1_|^T10_") ~ "comparison with literature; no code",
  str_detect(id, "^T2_") ~ "no code for Table 2 (2013 revision); l.801-856 ABCC-by-decade blocks need missing na110421a.dta and do not output T2",
  str_detect(id, "^T3_|^T4_|^T5_") ~ "2013 revision table; no surviving code",
  str_detect(id, "^T8_.*_c[23]$") ~ "T8 cols 2-3 (severe-crime controls/sample) are 2013 revision; no surviving code",
  str_detect(id, "^T9_") ~ "T9 cohort tests: model not in code; no surviving code",
  id == "TXT_p652_a" ~ "Brazil data G:/a/hb/br300407.dta not recovered (run_E fails r(601)); code comments give 83.6-60.2=23.4",
  TRUE ~ "no surviving code for this number")
rest <- tibble(claim_id = setdiff(claims$claim_id, res$claim_id)) |>
  mutate(source = "original", value = NA_real_, se = NA_real_, n = NA_real_, status_override = "unavailable", note = why(claim_id))
res <- bind_rows(res, rest) |> arrange(match(claim_id, claims$claim_id))
stopifnot(all(res$claim_id %in% claims$claim_id), !anyDuplicated(res$claim_id))
write_csv(res, file.path(root, "repro_original/results_original.csv"), na = "")
cat(nrow(res), "rows;", sum(is.na(res$status_override)), "with values\n")
