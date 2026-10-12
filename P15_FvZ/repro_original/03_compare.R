# P15_FvZ  S4 comparison, pair A only (published vs original-code recalculation).
# Input : claims/claims.csv, repro_original/results_original.csv, results_original_map.csv
# Output: compare/comparison_A.csv, compare/comparison_A_summary.csv

suppressPackageStartupMessages({ library(dplyr); library(readr); library(stringr) })
args_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- if (length(args_file)) normalizePath(file.path(dirname(args_file), "..")) else here::here()
source(file.path(root, "..", "tools", "compare.R")); source(file.path(root, "..", "tools", "paths.R"))

claims  <- read_csv(file.path(root, "claims", "claims.csv"), show_col_types = FALSE)
results <- read_csv(file.path(root, "repro_original", "results_original.csv"), show_col_types = FALSE,
                    col_types = cols(status_override = col_character()))
map_tbl <- read_csv(file.path(root, "repro_original", "results_original_map.csv"), show_col_types = FALSE)

cmp <- compare_claims(claims, results) |> filter(pair == "A")

# Digitisation precision stated in claims_spec.md (figure claims only).
dig_tol <- c(F1 = 300, F2 = 20, F3 = 3, F7 = 30)
cmp <- cmp |>
  mutate(fig = str_extract(claim_id, "^F[0-9]"),
         block = case_when(grepl("^A1_", claim_id) ~ "Table A1", !is.na(fig) ~ paste("Fig", substr(fig, 2, 2)), TRUE ~ "Text"),
         digitisation_tol = unname(dig_tol[fig]),
         within_digitisation_tol = ifelse(is.na(digitisation_tol) | is.na(delta), NA, abs(delta) <= digitisation_tol)) |>
  left_join(map_tbl, by = "claim_id")

# Causes (PROTOCOL S4 categories) and a free-text diagnosis for every non-exact
# attempted row. The evidence behind each diagnosis is in audit.md (S2 section).
fig_diag <- c(
  "Fig 1" = "published Fig. 1 not reproduced by Population!P/U/R: European band ~440 higher on average at every lag (text 'about 4,500 in 1701' also above workbook 3,841); population series behind the published figure not in surviving workbooks",
  "Fig 2" = "digitisation x-axis offset of one year: MAE vs workbook falls from 169 (lag 0) to 68 (lag +1) for the total; residual is stacked-area reading error",
  "Fig 3" = "digitisation error of a volatile line (lag-0 MAE 0.7/3.1/0.3 guilders for total/Europeans/balanced)",
  "Fig 7" = "digitisation error (lag-0 MAE 29 dollars Europeans, 6 balanced)")
txt_diag <- tribble(~claim_id, ~cause, ~diagnosis,
  "A1_1792_cape", "data-vintage", "printed 869.9 not produced by any surviving formula workbook (primary, Copy, CapeColonyGDPdetails, summary all give 937.85); 2014 values-only Macro file has 869.9",
  "A1_1793_cape", "data-vintage", "printed 958.7 vs 973.65 in all surviving formula workbooks; Macro values file has 958.7; 1793 CPI cell total economy!I95 is a typed 17.0",
  "TXT_p472_a", "data-vintage", "text 'about 4,500' matches published Fig. 1 but not the workbook population (Population!X4 = 3,841) used as the GDP-per-capita denominator",
  "TXT_p472_b", "rounding-or-transcription-in-paper", "'almost 50,000': workbook 49,525",
  "TXT_p469_d", "rounding-or-transcription-in-paper", "'around 50,000': workbook 49,525",
  "TXT_p472_c", "rounding-or-transcription-in-paper", "loose round shares (50/40/10) in text; workbook 1701-1795 means slaves 47.5%, Europeans 45.3%, Khoesan 7.2%",
  "TXT_p472_d", "rounding-or-transcription-in-paper", "loose round shares in text; workbook Khoesan mean 7.2%",
  "TXT_p472_f", "rounding-or-transcription-in-paper", "'about 20%': workbook mean VOC share 18.8%",
  "TXT_p473_d", "rounding-or-transcription-in-paper", "'more than 600,000': workbook 619,462 (consistent with the inequality)",
  "TXT_p473_e", "rounding-or-transcription-in-paper", "'3.2 million': workbook 1793 3,203,904",
  "TXT_p474_a", "rounding-or-transcription-in-paper", "'about 150': workbook L 1701 = 161.3 (1701-1710 range 134-200)",
  "TXT_p474_b", "rounding-or-transcription-in-paper", "'about 100': workbook L 1793 = 92.2 (1789-1793 range 89-99)",
  "TXT_p476_a", "variable-construction", "text's 65-70% matches the workbook's share of MEN in the slave population (Population!AA: IQR 66-69%, range 61-72%), not the adult share (O/P = 84-89%)",
  "TXT_p476_b", "variable-construction", "as TXT_p476_a",
  "TXT_p476_g", "rounding-or-transcription-in-paper", "'about 1.5': workbook mean 1751-1795 = 1.66 (first half 1.87 vs 'about 1.9')",
  "TXT_p478_b", "rounding-or-transcription-in-paper", "'about $1,000': workbook 1790 = 1,011.3",
  "TXT_p478_d", "rounding-or-transcription-in-paper", "OLS log-trend 1701-1793 = 2.56% (1701-1795: 2.57%); compound endpoint cell G99 = 2.73%",
  "TXT_p479_a", "rounding-or-transcription-in-paper", "'fluctuating between $600 and $1,000': 87 of 93 years inside; min 493 (1781), 579 (1782)",
  "TXT_p479_b", "rounding-or-transcription-in-paper", "max 1,167 (1708); 1707-1710 above 1,000",
  "TXT_p487_d", "unresolved", "mean 1748-1795 of Agricultural production!H (domestic wine use per Cape Town resident + sailor) = 0.42; 0.38 not reproduced for any window tried (1701-1795 mean 0.377)",
  "TXT_p488_d", "variable-construction", "butchers' margin 10% (resteconomy!G) but bakers' margin 20% (resteconomy!H, all 95 rows); text says 10% for both",
  "TXT_p489_a", "rounding-or-transcription-in-paper", "deflator base is 100 in the workbook (K3 = 100.0002, header '1701=100'); printed '1701 = 10' is a typo")
cmp <- cmp |> left_join(txt_diag, by = "claim_id") |>
  mutate(
    cause = case_when(
      !status %in% c("close", "differs") ~ NA_character_,
      !is.na(cause) ~ cause,
      grepl("^Fig", block) & within_digitisation_tol ~ "rounding-or-transcription-in-paper",
      block == "Fig 1" ~ "data-vintage",
      grepl("^Fig", block) ~ "unresolved",
      TRUE ~ "unresolved"),
    diagnosis = case_when(
      !status %in% c("close", "differs") ~ NA_character_,
      !is.na(diagnosis) ~ diagnosis,
      grepl("^Fig", block) & within_digitisation_tol ~ "within stated digitisation precision",
      grepl("^Fig", block) ~ unname(fig_diag[block]),
      TRUE ~ NA_character_))

# Fig 2 sensitivity: digitised year y against workbook year y+1.
f2 <- cmp |> filter(block == "Fig 2") |> mutate(year = as.numeric(str_extract(claim_id, "[0-9]{4}")),
                                                 col = c(agriculture = "B", voc = "C", secondary_tertiary = "D", total = "E")[sub("^F2_[0-9]{4}_", "", claim_id)])
Pw <- readRDS(dpath("P15_FvZ", "repro_original", "recalc_cells_primary.rds"))
f2$rep_lag1 <- mapply(function(y, cc) { v <- Pw$recalc[Pw$sheet == "total economy" & Pw$address == paste0(cc, y + 1 - 1698)]; if (length(v)) v else NA }, f2$year, f2$col)
f2_sens <- f2 |> summarise(n = n(), within_tol_lag0 = sum(abs(rep - ref) <= 20), within_tol_lag1 = sum(abs(rep_lag1 - ref) <= 20, na.rm = TRUE),
                           mae_lag0 = mean(abs(rep - ref)), mae_lag1 = mean(abs(rep_lag1 - ref), na.rm = TRUE))

out <- cmp |> select(claim_id, block, location, quantity_type, headline, pair, ref, rep, status, delta, rel_delta,
                     digitisation_tol, within_digitisation_tol, cause, diagnosis, workbook_source, method)
write_csv(out, file.path(root, "compare", "comparison_A.csv"), na = "")

summ <- bind_rows(
  out |> count(block, status),
  out |> count(status) |> mutate(block = "ALL")) |>
  tidyr::pivot_wider(names_from = status, values_from = n, values_fill = 0)
fig_dig <- out |> filter(grepl("^Fig", block), status %in% c("exact", "close", "differs")) |>
  group_by(block) |> summarise(attempted = n(), within_digitisation_tol = sum(within_digitisation_tol),
                               median_abs_rel_delta = median(abs(rel_delta), na.rm = TRUE), mae = mean(abs(delta)), .groups = "drop")
write_csv(summ, file.path(root, "compare", "comparison_A_summary.csv"))
write_csv(fig_dig, file.path(root, "compare", "comparison_A_figures_digitisation.csv"))
write_csv(f2_sens, file.path(root, "compare", "comparison_A_fig2_lag_sensitivity.csv"))
print(as.data.frame(f2_sens))
print(as.data.frame(summ)); print(as.data.frame(fig_dig))
cat("\nHeadline rows:\n"); print(as.data.frame(out |> filter(headline == 1) |> select(claim_id, ref, rep, status, delta)))
cat("\nTable A1 / text non-exact:\n")
print(as.data.frame(out |> filter(!grepl("^Fig", block), status %in% c("close", "differs")) |> select(claim_id, ref, rep, status, delta, rel_delta, method) |> mutate(method = substr(method, 1, 60))))
cat("\nFigure rows outside digitisation tolerance:\n")
print(out |> filter(grepl("^Fig", block), within_digitisation_tol %in% FALSE) |> count(block, cause))
cat("
causes:
"); print(out |> filter(!is.na(cause)) |> count(block, cause))
