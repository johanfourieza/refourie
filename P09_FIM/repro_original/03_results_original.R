# P09_FIM S2: results_original.csv. No surviving code or data produce any quantity in
# the 2022 paper (births 1865-1920, five forces incl. WWII, 10-year cohorts, census
# weights, Whites only, Table 3 N = 6,896). The surviving 2015 do-files (births
# 1865-1895, AOF/CMP/SAC/WWI, single-year or 5-year cohorts, unweighted, 15 July
# version includes Black recruits) estimate none of the claimed quantities.
# Every claim is therefore unavailable; the EARLIER-VERSION results are in
# compare_2015_sheets.csv (2015 rerun vs the authors' 2015 output sheets).
suppressMessages({library(readr); library(dplyr); library(here)})
cl <- read_csv(here::here("P09_FIM", "claims", "claims.csv"), show_col_types = FALSE, col_types = cols(.default = "c"))
note_for <- function(id) case_when(
  grepl("^T1_|^T2_", id) ~ "no code/data for 2022 version; 2015 do-files tabulate single birth years 1865-95 without WWII (not the 10-year-cohort shares/means)",
  grepl("^T3_|^T4_", id) ~ "no code/data for 2022 version; 2015 truncreg uses 1-yr or 5-yr cohorts, no weights, no WWII; no equivalent coefficient",
  grepl("^T5_", id)      ~ "no code for decomposition in any surviving file",
  grepl("^F8_|^F9_|^F10_", id) ~ "no code/data for international comparison (AUS/CAN/NZ/ENG) in any surviving file",
  TRUE ~ "no code/data for 2022 version")
out <- cl %>% transmute(claim_id, source = "original", value = NA_real_, se = NA_real_, n = NA_real_,
                        status_override = "unavailable", note = note_for(claim_id),
                        cause = "code_status: final code missing; only 2015 earlier-version do-files survive (EARLIER-VERSION run documented in PATCHES.md and compare_2015_sheets.csv)")
write_csv(out, here::here("P09_FIM", "repro_original", "results_original.csv"), na = "")
cat(nrow(out), "rows written\n")
