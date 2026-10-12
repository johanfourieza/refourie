# P15_FvZ  S2: map the RECALCULATED workbook series to the frozen claims.
#
# Input : repro_original/recalc_cells_primary.rds, recalc_cells_copy.rds (from 01)
#         claims/claims.csv (frozen; read only)
#         values-only files in original/ (for cached_values_only.csv only)
# Output: repro_original/results_original.csv  (claim_id, source, value, se, n, status_override)
#         repro_original/results_original_map.csv (claim_id -> workbook cell / method)
#         repro_original/cached_values_only.csv  (typed values that match claims but
#                                                 have no formula chain: not a reproduction)
#
# Every value in results_original.csv is a recalculated value from 01 (or a
# statistic computed from recalculated values); none is a cached workbook value.

suppressPackageStartupMessages({ library(dplyr); library(tidyr); library(readr); library(purrr); library(tidyxl); library(stringr) })
args_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- if (length(args_file)) normalizePath(file.path(dirname(args_file), "..")) else here::here()
od <- file.path(root, "repro_original"); source(file.path(root, "..", "tools", "paths.R")); dd <- dpath("P15_FvZ", "repro_original")  # A6

claims <- read_csv(file.path(root, "claims", "claims.csv"), show_col_types = FALSE)
P <- readRDS(file.path(dd, "recalc_cells_primary.rds"))
C <- readRDS(file.path(dd, "recalc_cells_copy.rds"))

# recalculated value of a column by year. total economy: row = year - 1698;
# Population: row = year - 1697 (both workbooks); ships: row = year - 1650.
rowyr <- c("total economy" = 1698, "Population" = 1697, "ships" = 1650, "Agricultural production" = 1697)
col_series <- function(wb, sheet, col, years, offset = rowyr[[sheet]]) {
  rows <- years - offset
  addr <- paste0(col, rows); sh <- sheet
  x <- wb |> filter(.data$sheet == sh, .data$address %in% addr)
  tibble(year = years, row = rows) |>
    left_join(x |> select(row, value = recalc, type = recalc_type), by = "row") |>
    mutate(value = ifelse(type == "numeric", value, NA_real_), cell = paste0(sh, "!", addr))
}
yrs <- 1701:1795

# ------------------------------------------------------------ series -------
S <- list(
  gk_total     = col_series(P, "total economy", "W", yrs),   # Table A1 Cape, Fig 7 Cape
  gk_eur       = col_series(P, "total economy", "X", yrs),   # Fig 7 Europeans
  gk_bal       = col_series(C, "total economy", "Z", yrs),   # Fig 7 balanced (copy wb only)
  pc_const     = col_series(P, "total economy", "L", yrs),   # Fig 3 total
  pc_eur       = col_series(P, "total economy", "R", yrs),   # Fig 3 Europeans
  pc_bal       = col_series(C, "total economy", "M", yrs),   # Fig 3 balanced (copy wb only)
  agri         = col_series(P, "total economy", "B", yrs),   # Fig 2
  voc          = col_series(P, "total economy", "C", yrs),
  rest         = col_series(P, "total economy", "D", yrs),
  gdp_cur      = col_series(P, "total economy", "E", yrs),
  gdp_const    = col_series(P, "total economy", "F", yrs),
  sh_agri      = col_series(P, "total economy", "M", yrs),
  sh_voc       = col_series(P, "total economy", "N", yrs),
  deflator     = col_series(P, "total economy", "K", yrs),
  pop_slave    = col_series(P, "Population", "P", yrs),      # Fig 1 (chart series P, U, R)
  pop_eur      = col_series(P, "Population", "R", yrs),
  pop_khoe     = col_series(P, "Population", "U", yrs),
  pop_total    = col_series(P, "Population", "X", yrs),
  slave_adult  = col_series(P, "Population", "O", yrs),
  bal_ratio    = col_series(C, "Population", "S", yrs, offset = 1648),  # copy wb: row 53 = 1701      # balanced / actual population
  wine_urban   = col_series(P, "Agricultural production", "H", yrs),
  ship_days    = col_series(P, "ships", "F", 1652:1700)
)
check_copy_same <- function(a, b) max(abs(a$value - b$value), na.rm = TRUE)
copy_vs_primary <- c(
  W_vs_X = check_copy_same(S$gk_total, col_series(C, "total economy", "X", yrs)),
  L_vs_L = check_copy_same(S$pc_const, col_series(C, "total economy", "L", yrs)))

trend <- function(d, from, to) {               # OLS of ln(y) on year; % per year
  d <- d |> filter(year >= from, year <= to, !is.na(value), value > 0)
  b <- unname(coef(lm(log(value) ~ year, data = d))[2])
  c(pct = 100 * (exp(b) - 1), n = nrow(d))
}
cagr <- function(d, from, to) {
  a <- d$value[d$year == from]; b <- d$value[d$year == to]; 100 * ((b / a)^(1 / (to - from)) - 1)
}
mean_y <- function(d, from, to) mean(d$value[d$year >= from & d$year <= to], na.rm = TRUE)
val_y <- function(d, y) d$value[d$year == y]
cell_y <- function(d, y) d$cell[d$year == y]

res <- list(); mp <- list()
add <- function(id, value, src, method, n = NA_real_, ovr = NA_character_) {
  res[[length(res) + 1]] <<- tibble(claim_id = id, source = "original", value = value, se = NA_real_, n = n, status_override = ovr)
  mp[[length(mp) + 1]] <<- tibble(claim_id = id, workbook_source = src, method = method)
}

# ------------------------------------------------------------ Table A1 -----
for (id in claims$claim_id[grepl("^A1_", claims$claim_id)]) {
  y <- as.numeric(str_extract(id, "[0-9]{4}")); grp <- str_extract(id, "[a-z]+$")
  if (grp == "cape" && y <= 1793) {
    add(id, val_y(S$gk_total, y), paste0("primary ", cell_y(S$gk_total, y)), "recalculated (2335*L/177)*7.69/9.61")
  } else if (grp == "cape" && y <= 1800) {
    # paper prints N/A; workbook W96 (1794) has a different formula and evaluates to 0, 1795+ blank
    add(id, NA_real_, "primary total economy!W96:W98", "paper N/A; W96 = 2335*L96/U96 = 0 (L96 blank), W97+ blank",
        ovr = "unavailable")
  } else {
    add(id, NA_real_, "values only (CapeColonyGDPdetails.xlsx Sheet2; Macro/GDP South Africa 1700-2008.xlsx)",
        "no formula chain survives; see cached_values_only.csv", ovr = "unavailable")
  }
}

# ------------------------------------------------------------ figures ------
fig_map <- list(
  F1 = list(slaves = "pop_slave", khoesan = "pop_khoe", european = "pop_eur", total = "pop_total"),
  F2 = list(agriculture = "agri", voc = "voc", secondary_tertiary = "rest", total = "gdp_cur"),
  F3 = list(GDPpc = "pc_const", Europeans = "pc_eur", Balanced = "pc_bal"),
  F7 = list(CapeEuropeans = "gk_eur", Balanced = "gk_bal"))
for (id in claims$claim_id[grepl("^F[1237]_", claims$claim_id)]) {
  fig <- substr(id, 1, 2); y <- as.numeric(str_extract(id, "[0-9]{4}")); key <- sub("^F[0-9]_[0-9]{4}_", "", id)
  if (fig == "F7" && key %in% c("Holland", "GB")) {
    add(id, NA_real_, paste0("primary total economy!", ifelse(key == "Holland", "V", "Z"), y - 1698),
        "comparator pasted as values; no formula chain", ovr = "unavailable"); next
  }
  s <- S[[fig_map[[fig]][[key]]]]
  wb <- if (fig_map[[fig]][[key]] %in% c("gk_bal", "pc_bal")) "copy " else "primary "
  add(id, val_y(s, y), paste0(wb, cell_y(s, y)), "recalculated cell, same year")
}

# ------------------------------------------------------------ text ---------
na_txt <- function(id, why) add(id, NA_real_, "none", why, ovr = "unavailable")
add("TXT_p472_a", val_y(S$pop_total, 1701), paste0("primary ", cell_y(S$pop_total, 1701)), "total population incl. Khoesan, 1701")
add("TXT_p472_b", val_y(S$pop_total, 1795), paste0("primary ", cell_y(S$pop_total, 1795)), "total population incl. Khoesan, 1795")
add("TXT_p469_d", val_y(S$pop_total, 1795), paste0("primary ", cell_y(S$pop_total, 1795)), "total population incl. Khoesan, 1795")
add("TXT_p472_c", 100 * mean(S$pop_eur$value / S$pop_total$value), "primary Population!R4:R98 / X4:X98",
    "mean over 1701-1795 of European share (R/X), %", n = 95)
add("TXT_p472_d", 100 * mean(S$pop_khoe$value / S$pop_total$value), "primary Population!U4:U98 / X4:X98",
    "mean over 1701-1795 of Khoesan share (U/X), %", n = 95)
add("TXT_p472_f", 100 * mean_y(S$sh_voc, 1701, 1793), "primary total economy!N3:N95", "mean VOC share of GDP 1701-1793, %", n = 93)
add("TXT_p472_g", 100 * mean_y(S$sh_agri, 1701, 1793), "primary total economy!M3:M95", "mean agriculture share of GDP 1701-1793, %", n = 93)
add("TXT_p473_d", 1000 * val_y(S$gdp_cur, 1701), paste0("primary ", cell_y(S$gdp_cur, 1701)), "GDP current prices 1701, guilders (E x 1000)")
add("TXT_p473_e", 1000 * val_y(S$gdp_cur, 1793), paste0("primary ", cell_y(S$gdp_cur, 1793)),
    "GDP current prices 1793 (last year of complete chain), guilders; 1794 (E96, VOC typed as 200) = 3,176,093")
add("TXT_p474_a", val_y(S$pc_const, 1701), paste0("primary ", cell_y(S$pc_const, 1701)), "GDP per capita, 1701 prices, 1701")
add("TXT_p474_b", val_y(S$pc_const, 1793), paste0("primary ", cell_y(S$pc_const, 1793)), "GDP per capita, 1701 prices, 1793 (last year)")
adult_sh <- 100 * S$slave_adult$value / S$pop_slave$value
add("TXT_p476_a", min(adult_sh), "primary Population!O4:O98 / P4:P98", "minimum over 1701-1795 of adult share of slaves (O/P), %", n = 95)
add("TXT_p476_b", max(adult_sh), "primary Population!O4:O98 / P4:P98", "maximum over 1701-1795 of adult share of slaves (O/P), %", n = 95)
add("TXT_p476_f", mean_y(S$bal_ratio, 1701, 1750), "copy Population!S53:S102", "mean balanced/actual population ratio 1701-1750", n = 50)
add("TXT_p476_g", mean_y(S$bal_ratio, 1751, 1795), "copy Population!S103:S147", "mean balanced/actual population ratio 1751-1795", n = 45)
add("TXT_p477_c", 20, "primary total economy!W3 constant 7.69/9.61", "Cape/Dutch guilder silver ratio 7.69/9.61 = 0.800 = 16/20; 20 guilders per Rixdollar at the Cape")
add("TXT_p477_d", 16, "primary total economy!W3 constant 7.69/9.61", "as above: 16 guilders per Rixdollar in Holland")
add("TXT_p478_b", val_y(S$gk_total, 1790), paste0("primary ", cell_y(S$gk_total, 1790)), "Cape GK-dollar GDP pc, 1790")
tg <- trend(S$gdp_const, 1701, 1793); tp <- trend(S$pop_total, 1701, 1793)
add("TXT_p478_c", tg[["pct"]], "primary total economy!F3:F95",
    "OLS of ln(real GDP, col F) on year, 1701-1793; 100*(exp(b)-1)", n = tg[["n"]])
add("TXT_p478_d", tp[["pct"]], "primary Population!X4:X96",
    "OLS of ln(total population, col X) on year, 1701-1793; 100*(exp(b)-1)", n = tp[["n"]])
add("TXT_p479_a", min(S$gk_bal$value[S$gk_bal$year <= 1793]), "copy total economy!Z3:Z95", "minimum of balanced GK-dollar series 1701-1793", n = 93)
add("TXT_p479_b", max(S$gk_bal$value[S$gk_bal$year <= 1793]), "copy total economy!Z3:Z95", "maximum of balanced GK-dollar series 1701-1793", n = 93)
add("TXT_p481_u", mean(S$ship_days$value), "primary ships!F2:F50", "mean ship days (all nationalities, col F = B+E) 1652-1700", n = 49)
add("TXT_p487_a", 2.5, "primary Agricultural production!S4:S98", "constant in formula 2.5*Population!S+1.25*(T-S)")
add("TXT_p487_b", 1.25, "primary Agricultural production!S4:S98", "constant in formula 2.5*Population!S+1.25*(T-S)")
add("TXT_p487_c", 40, "primary Agricultural production!U", "constant in formula +Z*40 (ships passing x 40 mud)")
add("TXT_p487_d", mean_y(S$wine_urban, 1748, 1795), "primary Agricultural production!H51:H98",
    "mean 1748-1795 of urban wine consumption per head, G/(Population!AE+AH), leggers", n = sum(!is.na(S$wine_urban$value[S$wine_urban$year >= 1748])))
add("TXT_p487_f", 0.30, "primary Agricultural production!I", "constant in formula +D+(Population!T-Population!AE)*0.3")
add("TXT_p487_h", 80, "primary Agricultural production!AB", "meat price weight: Q*0.2 + R*0.8 (mutton weight 0.8)")
add("TXT_p487_i", 42, "primary Livestock in possession!AC,Z", "constant: J*42*0.2 (lbs per sheep)")
add("TXT_p487_j", 300, "primary Livestock in possession!AC,Z", "constant: I*300*0.033 (lbs per cow)")
add("TXT_p488_a", 2, "primary resteconomy!Y", "constant: (change in sown area)*Y*2*AG/5 (land = 2 x seed value)")
add("TXT_p488_b", 50, "primary INCOMEVOCEMPLOYEES!I", "constant: I = C + F*0.5 + H*1.05, F = wissel transfers - regular transfers")
add("TXT_p488_c", 10, "primary INCOMEVOCEMPLOYEES!S5:S97", "constant 0.1 (1704-1795); NB S2:S4 (1701-1703) use E/17.15 instead")
add("TXT_p488_d", 20, "primary resteconomy!G,H", "butchers G = meat value x 0.1 (10%), bakers H = wheat value x 0.2 (20%); reported value = bakers' 20%; text says 10% for both")
add("TXT_p489_a", 100, "primary total economy!K3", "deflator K3 = 100.0002 (1701 = 100); header 'K2 1701=100'")
not_in_wb <- c(
  TXT_p469_a = "average days in Table Bay: not computed in the workbook",
  TXT_p469_b = "1732 occupational survey: not in workbook", TXT_p469_c = "area: not in workbook",
  TXT_p470_a = "probate inventories: not in workbook", TXT_p470_b = "probate inventories: not in workbook",
  TXT_p470_c = "probate inventories: not in workbook", TXT_p470_d = "opgaafrolle households: not in workbook",
  TXT_p472_e = "Feinstein estimate: literature", TXT_p473_a = "1732 labour force: not in workbook",
  TXT_p473_b = "1732 labour force: not in workbook", TXT_p473_c = "1732 labour force: not in workbook",
  TXT_p476_c = "adult-men share of burghers: no matching column", TXT_p476_d = "dependency ratio: no matching column",
  TXT_p476_e = "dependency ratio: no matching column",
  TXT_p477_a = "PPP ratio total economy!T3 is a typed value (see cached_values_only.csv)",
  TXT_p477_b = "England price level: not in workbook",
  TXT_p478_a = "GB series total economy!Z is typed values (see cached_values_only.csv)",
  TXT_p478_e = "Holland series total economy!U/V is typed values (see cached_values_only.csv)",
  TXT_p478_f = "GB series typed values (see cached_values_only.csv)",
  TXT_p478_g = "British population: not in workbook", TXT_p478_h = "British GDP: not in workbook",
  TXT_p481_a = "17th-century counts: not in workbook", TXT_p481_b = "17th-century counts: not in workbook",
  TXT_p481_c = "17th-century counts: not in workbook", TXT_p481_d = "17th-century counts: not in workbook",
  TXT_p481_e = "17th-century counts: not in workbook", TXT_p481_f = "17th-century counts: not in workbook",
  TXT_p481_g = "17th-century counts: not in workbook", TXT_p481_h = "17th-century counts: not in workbook",
  TXT_p481_i = "17th-century counts: not in workbook", TXT_p481_j = "17th-century counts: not in workbook",
  TXT_p481_k = "17th-century counts: not in workbook", TXT_p481_l = "17th-century counts: not in workbook",
  TXT_p481_m = "17th-century counts: not in workbook", TXT_p481_n = "17th-century counts: not in workbook",
  TXT_p481_o = "17th-century counts: not in workbook", TXT_p481_p = "17th-century counts: not in workbook",
  TXT_p481_q = "17th-century counts: not in workbook", TXT_p481_r = "17th-century counts: not in workbook",
  TXT_p481_s = "17th-century counts: not in workbook",
  TXT_p481_t = "ship counts not in workbook chain", TXT_p482_a = "not computed in workbook",
  TXT_p482_b = "not in workbook", TXT_p482_c = "not in workbook",
  TXT_p486_a = "1817 opgaafrolle: not in workbook", TXT_p486_b = "1817: not in workbook", TXT_p486_c = "1817: not in workbook",
  TXT_p487_e = "litre conversion: not in workbook", TXT_p487_g = "litre conversion: not in workbook")
iwalk(not_in_wb, function(why, id) na_txt(id, why))

results <- bind_rows(res); map_tbl <- bind_rows(mp)
stopifnot(!anyDuplicated(results$claim_id), setequal(results$claim_id, claims$claim_id))

# --------------------------------------------- cached (typed) values only ---
b <- dpath("P15_FvZ", "original")
s2 <- xlsx_cells(file.path(b, "Fourie Van Zanden", "CapeColonyGDPdetails.xlsx"), sheets = "Sheet2")
s2v <- s2 |> filter(col %in% 1:2, !is_blank) |> select(row, col, numeric) |> pivot_wider(names_from = col, values_from = numeric) |>
  transmute(year = `1`, value = `2`, cell = paste0("Sheet2!B", row)) |> filter(!is.na(year))
mac <- xlsx_cells(file.path(b, "Macro", "GDP South Africa 1700-2008.xlsx"))
macv <- bind_rows(lapply(list(c(1, 2, "cape"), c(3, 4, "cape"), c(5, 7, "cape"), c(5, 6, "sa"), c(8, 9, "sa")), function(z) {
  yc <- as.integer(z[1]); vc <- as.integer(z[2])
  yv <- mac |> filter(col == yc, row > 1) |> select(row, year = numeric)
  vv <- mac |> filter(col == vc, row > 1) |> select(row, value = numeric)
  inner_join(yv, vv, by = "row") |> mutate(grp = z[3], cell = paste0("Sheet1!", LETTERS[vc], row))
})) |> filter(!is.na(value))
te_typed <- P |> filter(sheet == "total economy", col %in% c(20, 21, 22, 26), !is_formula) |>
  transmute(row, col, value = numeric, year = row + 1698)

prec_ok <- function(rep, val, p) ifelse(is.na(rep) | is.na(val), NA, abs(val - rep) <= 0.5 * 10^(-p) + 1e-9)
a1 <- claims |> filter(grepl("^A1_", claim_id)) |>
  mutate(year = as.numeric(str_extract(claim_id, "[0-9]{4}")), grp = str_extract(claim_id, "[a-z]+$")) |>
  filter(!(grp == "cape" & year <= 1800))
cv <- bind_rows(
  a1 |> filter(grp == "cape") |> left_join(s2v, by = "year") |>
    transmute(claim_id, reported_value, precision, cached_value = value,
              source_file = "Fourie Van Zanden/CapeColonyGDPdetails.xlsx", cell),
  a1 |> left_join(macv, by = c("year", "grp")) |>
    transmute(claim_id, reported_value, precision, cached_value = value,
              source_file = "Macro/GDP South Africa 1700-2008.xlsx", cell),
  claims |> filter(grepl("^F7_.*_(Holland|GB)$", claim_id)) |>
    mutate(year = as.numeric(str_extract(claim_id, "[0-9]{4}")), col = ifelse(grepl("Holland", claim_id), 22, 26)) |>
    left_join(te_typed, by = c("year", "col")) |>
    transmute(claim_id, reported_value, precision, cached_value = value,
              source_file = "Fourie Van Zanden/Van Duin en Ross.xlsx",
              cell = paste0("total economy!", ifelse(col == 22, "V", "Z"), row))
)
hol <- te_typed |> filter(col == 22, year <= 1793) |> select(year, value)
gb <- te_typed |> filter(col == 26, year <= 1793) |> select(year, value)
t3 <- te_typed$value[te_typed$col == 20 & te_typed$year == 1701]
extra <- tribble(
  ~claim_id, ~cached_value, ~cell,
  "TXT_p478_a", te_typed$value[te_typed$col == 26 & te_typed$year == 1790], "total economy!Z92 (GB 1790)",
  "TXT_p477_a", 100 * (1 / t3 - 1), "total economy!T3 (Cape/Amsterdam price ratio 0.994): Holland 0.6% higher",
  "TXT_p478_e", trend(hol, 1701, 1793)[["pct"]], "total economy!V3:V95 (Holland $): OLS ln-trend 1701-1793, %/yr",
  "TXT_p478_f", trend(gb, 1701, 1793)[["pct"]], "total economy!Z3:Z95 (GB $): OLS ln-trend 1701-1793, %/yr"
) |> left_join(claims |> select(claim_id, reported_value, precision), by = "claim_id") |>
  mutate(source_file = "Fourie Van Zanden/Van Duin en Ross.xlsx (typed values)")
cv <- bind_rows(cv, extra) |>
  mutate(agree_at_print_precision = prec_ok(reported_value, cached_value, precision),
         delta = cached_value - reported_value,
         # digitised Fig. 7 comparator values carry +/-30 dollars (claims_spec.md)
         within_digitisation_tol = ifelse(grepl("^F7_", claim_id), abs(delta) <= 30, NA)) |>
  select(claim_id, reported_value, cached_value, delta, agree_at_print_precision, within_digitisation_tol, source_file, cell)

write_csv(results, file.path(od, "results_original.csv"), na = "")
write_csv(map_tbl, file.path(od, "results_original_map.csv"), na = "")
write_csv(cv, file.path(od, "cached_values_only.csv"), na = "")

cat("copy vs primary, max |diff| of shared series:\n"); print(copy_vs_primary)
cat("results rows:", nrow(results), " with value:", sum(!is.na(results$value)), "\n")
cat("cached-only agreement:\n"); print(cv |> mutate(f = sub("_[0-9]{4}_?", "_", claim_id)) |>
  group_by(src = source_file, grp = str_extract(f, "^[A-Z0-9]+_[a-zA-Z]+")) |>
  summarise(n = n(), n_val = sum(!is.na(cached_value)), agree = sum(agree_at_print_precision, na.rm = TRUE),
            within_dig = sum(within_digitisation_tol, na.rm = TRUE), .groups = "drop") |> as.data.frame())
cat("compound growth (cells F99, G99): GDP", cagr(S$gdp_const, 1701, 1793), " pop", cagr(S$pop_total, 1701, 1793), "\n")
cat("trend 1701-1795 pop:", trend(S$pop_total, 1701, 1795), "\n")
