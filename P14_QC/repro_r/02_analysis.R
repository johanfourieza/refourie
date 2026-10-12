# P14_QC S3 rebuild, step 2: recompute every claim the workbook's series permit, from the
# underlying series cells (not from the workbook's own result cells), and run internal checks.
# Run from the project root. Inputs: D:/.../P14_QC/repro_r/derived/workbook_cells.rds (01_clean.R),
# P14_QC/claims/claims.csv, P27_RW/claims/claims.csv (published EHR 2013 values, source check only).
suppressMessages({ library(dplyr); library(readr); library(tidyr) })
source(file.path("tools", "paths.R"))
out <- file.path("P14_QC", "repro_r", "output")
cells  <- readRDS(dpath("P14_QC", "repro_r", "derived", "workbook_cells.rds"))
claims <- read_csv(file.path("P14_QC", "claims", "claims.csv"), show_col_types = FALSE)

cell <- function(s, a) { v <- cells$numeric[cells$sheet == s & cells$address == a]; if (length(v) == 0) NA_real_ else v }
# Series by year: year in column ycol, value in column vcol of sheet s
series <- function(s, ycol, vcol) {
  y <- cells |> filter(sheet == s, col == ycol, row > 1, !is.na(numeric)) |> select(row, year = numeric)
  v <- cells |> filter(sheet == s, col == vcol, row > 1, !is.na(numeric)) |> select(row, value = numeric)
  inner_join(y, v, by = "row") |> select(year, value)
}
at   <- function(d, y) d$value[d$year == y]
cagr <- function(a, b, t) 100 * ((b / a)^(1 / t) - 1)          # compound annual growth, per cent

# --- Series (column letters as in the workbook) ---
pop_vdr  <- series("Population", 1, 2)          # B  Opgaafrolle (Van Duin and Ross 1987)
pop_fvf  <- series("Population", 1, 3)          # C  Opgaafrolle (Fourie and Von Fintel 2010)
pop_prob <- series("Population", 1, 4)          # D  Probate inventories per year (Fourie 2013)
pop_gisa <- series("Population", 1, 5)          # E  GISA (Cilliers and Fourie 2012)
pg <- function(c) series("PopulationGroups", 1, c)
eur <- pg(2); voc <- pg(3); sl_vdr <- pg(4); sl_shell <- pg(5); kh_bf <- pg(6); kh_gf <- pg(7)

r <- list()
add <- function(id, v, note = "") r[[id]] <<- tibble(claim_id = id, value = v, note = note)

# Population (text p.148)
add("TX148_pop1663", at(pop_fvf, 1663), "Population!C13 (Fourie-Von Fintel series)")
add("TX148_pop1795", at(pop_vdr, 1795), "Population!B (Van Duin-Ross series), 1795")
add("TX148_popgr",   cagr(at(pop_fvf, 1663), at(pop_vdr, 1795), 1795 - 1663), "splices FvF 1663 with VD&R 1795")
add("TX148_popgr18", cagr(at(eur, 1701), at(eur, 1795), 94), "PopulationGroups!B 1701-1795")
# VOC employees (p.149)
add("TX149_voc_gr",  cagr(at(voc, 1701), at(voc, 1795), 94))
add("TX149_voc1708", at(voc, 1708)); add("TX149_voc1789", at(voc, 1789))
add("TX149_voc_gr2", cagr(at(voc, 1708), at(voc, 1789), 81), "correct base 1708; workbook W8 uses 1701 value 531")
# Slaves (p.149): the series the text uses is the column labelled 'Slaves (Shell)'
add("TX149_slave1701", at(sl_shell, 1701), "PopulationGroups!E (labelled Shell, cited as Van Duin-Ross)")
add("TX149_slave1795", at(sl_shell, 1795), "PopulationGroups!E")
add("TX149_slavegr",   cagr(at(sl_shell, 1701), at(sl_shell, 1795), 94))
# Khoesan (p.150)
add("TX150_khoe1795", at(kh_bf, 1795), "PopulationGroups!F (Baten-Fourie proxy)")
add("TX150_khoegr",   cagr(at(kh_bf, 1701), at(kh_bf, 1795), 94), "1701 base = 36.76 (non-integer proxy)")
# GISA births 1890s (p.151): Demographic!B26 is decade 1890-1899 (row label 1899)
add("TX151_births1890s", cell("Demographic", "B26"), "hard-coded; lookup, no formula")
# Table 1 Obs. recomputed from the table's own SD and SE: N = (SD/SE)^2
per <- c("1650", "1700", "1750", "1800", "1850", "1900")
for (i in seq_along(per)) {
  rr <- i + 1
  nimp <- (cell("Demographic", paste0("N", rr)) / cell("Demographic", paste0("O", rr)))^2
  for (t in c("T1", "T2")) add(paste0(t, "_", per[i], "_obs"), nimp, "N implied by SD/SE in Demographic!N:O")
}
# Text rounding of table means (p.151)
add("TX151_ls_first", round(cell("Demographic", "L2")), "round(Demographic!L2)")
add("TX151_ls_last",  round(cell("Demographic", "L7")), "round(Demographic!L7 = 66.49991)")
res <- bind_rows(r)

# --- Original (workbook) values: cells that hold the published number ---
orig_cells <- tribble(~claim_id, ~sheet, ~address,
  "TX148_pop1663", "Population", "I2", "TX148_pop1795", "Population", "I3", "TX148_popgr", "Population", "I5",
  "TX148_popgr18", "PopulationGroups", "T5", "TX149_voc_gr", "PopulationGroups", "V8",
  "TX149_voc_gr2", "PopulationGroups", "W8", "TX149_voc1708", "PopulationGroups", "V4",
  "TX149_voc1789", "PopulationGroups", "V5", "TX149_slave1701", "PopulationGroups", "Y3",
  "TX149_slave1795", "PopulationGroups", "Y4", "TX149_slavegr", "PopulationGroups", "Y5",
  "TX150_khoe1795", "PopulationGroups", "AB4", "TX150_khoegr", "PopulationGroups", "AB5",
  "TX151_births1890s", "Demographic", "B26",
  "TX152_med_first", "Demographic", "M2", "TX152_med_last", "Demographic", "M7")
for (t in c("T1", "T2")) for (i in seq_along(per)) {
  rr <- i + 1
  orig_cells <- bind_rows(orig_cells, tibble(
    claim_id = paste0(t, "_", per[i], c("_obs", "_mean", "_median")), sheet = "Demographic",
    address = paste0(c("K", "L", "M"), rr)))
}
pct <- c("TX148_popgr", "TX148_popgr18", "TX149_voc_gr", "TX149_voc_gr2", "TX149_slavegr", "TX150_khoegr")
orig_cells$value   <- mapply(cell, orig_cells$sheet, orig_cells$address) * ifelse(orig_cells$claim_id %in% pct, 100, 1)
orig_cells$formula <- mapply(function(s, a) { f <- cells$formula[cells$sheet == s & cells$address == a]; if (length(f) && !is.na(f)) f else "" },
                             orig_cells$sheet, orig_cells$address)

# --- Write results files with every claim ---
na_note <- "Not held in the workbook; no code or data survive for this number (S1)"
results_r <- claims |> select(claim_id) |> left_join(res, by = "claim_id") |>
  transmute(claim_id, source = "r", value, se = NA_real_, n = NA_real_,
            status_override = ifelse(is.na(value), "unavailable", ""))
write_csv(results_r, file.path("P14_QC", "repro_r", "results_r.csv"), na = "")
results_o <- claims |> select(claim_id) |> left_join(orig_cells, by = "claim_id") |>
  transmute(claim_id, source = "original", value, se = NA_real_, n = NA_real_,
            status_override = ifelse(is.na(value), "unavailable", ""),
            note = ifelse(is.na(value), na_note,
                          paste0(sheet, "!", address, ifelse(formula == "", " (hard-coded)", paste0(" =", formula)))))
write_csv(results_o, file.path("P14_QC", "repro_original", "results_original.csv"), na = "")
claims |> select(claim_id, reported_value) |>
  left_join(res, by = "claim_id") |> rename(r_value = value) |>
  left_join(orig_cells |> transmute(claim_id, wb_cell = paste0(sheet, "!", address), wb_value = value), by = "claim_id") |>
  write_csv(file.path(out, "recompute_vs_workbook.csv"), na = "")

# --- Internal and provenance checks ---
chk <- tibble(check = character(), value = character())
ck <- function(k, v) chk <<- bind_rows(chk, tibble(check = k, value = as.character(v)))
ck("Slaves VD&R column D: 1701, 1795", paste(at(sl_vdr, 1701), at(sl_vdr, 1795)))
ck("Slave growth 1701-1795 with VD&R column D (%)", round(cagr(at(sl_vdr, 1701), at(sl_vdr, 1795), 94), 2))
ck("Khoe growth 1701-1795, Green-Fourie column G (%)", round(cagr(at(kh_gf, 1701), at(kh_gf, 1795), 94), 2))
ck("Khoe Green-Fourie column G: 1701, 1795", paste(round(at(kh_gf, 1701), 1), round(at(kh_gf, 1795), 1)))
ck("VOC growth 1708-1789 as in workbook W8 (base 1701=531) (%)", round(cagr(at(voc, 1701), at(voc, 1789), 81), 3))
v18 <- voc |> filter(year < 1800)
ck("VOC maximum 1701-1799 (value year)", paste(max(v18$value), v18$year[which.max(v18$value)]))
ck("Settler growth 1663-1773 within FvF series only (%)", round(cagr(at(pop_fvf, 1663), at(pop_fvf, 1773), 110), 2))
ov <- inner_join(pop_vdr, pop_fvf, by = "year", suffix = c("_vdr", "_fvf"))
ck("FvF/VD&R ratio in overlap years: mean min max", paste(round(mean(ov$value_fvf / ov$value_vdr), 3), round(min(ov$value_fvf / ov$value_vdr), 3), round(max(ov$value_fvf / ov$value_vdr), 3)))
ck("Probate inventories per year (Population!D): total, years", paste(sum(pop_prob$value), paste(range(pop_prob$year), collapse = "-")))
ck("GISA settlers 1795 vs opgaafrolle 1795", paste(at(pop_gisa, 1795), at(pop_vdr, 1795)))
ck("Table 1 SD by half-century (Demographic!N2:N7)", paste(sapply(2:7, function(rr) round(cell("Demographic", paste0("N", rr)), 2)), collapse = ", "))
ck("Demographic!L7 mean 1900-1949 unrounded", cell("Demographic", "L7"))

# --- Figure 5 (Growth sheet): moving-average construction and comparison with Fourie (2013) ---
gL <- series("Growth", 11, 12)                                   # K year, L yearly mean value (zero-slave households)
gB <- series("Growth", 1, 2)                                     # A year, B plotted 5-yr centred MA
ma <- sapply(gB$year, function(y) { i <- which(gL$year == y); if (!length(i)) NA else mean(gL$value[max(1, i - 2):min(nrow(gL), i + 2)]) })
fig5 <- gB |> mutate(ma_recomputed = ma, diff = value - ma_recomputed)
write_csv(fig5, file.path(out, "fig5_ma_check.csv"), na = "")
ck("Fig 5 MA: max abs diff B vs recomputed; years with no data row", paste(signif(max(abs(fig5$diff), na.rm = TRUE), 3), sum(is.na(fig5$ma_recomputed))))
ck("Fig 5 Growth!K years: n, range, missing", paste(nrow(gL), paste(range(gL$year), collapse = "-"), paste(setdiff(min(gL$year):max(gL$year), gL$year), collapse = ";")))
ck("Fig 5 yearly mean (Growth!L): min max", paste(round(min(gL$value), 1), round(max(gL$value), 1)))
p27 <- read_csv(file.path("P27_RW", "claims", "claims.csv"), show_col_types = FALSE)
dec <- gL |> filter(year >= 1700) |> mutate(decade = 10 * floor(year / 10)) |> group_by(decade) |>
  summarise(zero_slave_mean_of_yearly_means = mean(value), years = n(), .groups = "drop") |>
  left_join(p27 |> filter(grepl("^T5_1[0-9]{3}_mean$", claim_id)) |>
              transmute(decade = as.numeric(substr(claim_id, 4, 7)), ehr_T5_all_households_mean = as.numeric(reported_value)), by = "decade") |>
  mutate(ratio = zero_slave_mean_of_yearly_means / ehr_T5_all_households_mean)
write_csv(dec, file.path(out, "fig5_vs_P27_T5.csv"))
ck("EHR T5 total n (28-item wealth)", p27$reported_value[p27$claim_id == "T5_total_n"])
ck("EHR F4 shares slaves cattle sheep (auction rolls 1693-1748)", paste(p27$reported_value[p27$claim_id %in% c("F4_slaves", "F4_cattle", "F4_sheep")], collapse = " "))
ck("EHR T8 pictures: Cape 1711-50 by class; Cape 1740-82; Leeuwarderadeel classes; Amsterdam",
   paste(paste(p27$reported_value[grepl("^T8_cape_colony_c[1-4]_1711_50$", p27$claim_id)], collapse = "/"),
         p27$reported_value[p27$claim_id == "T8_cape_colony_1740_82"],
         paste(p27$reported_value[grepl("^T8_leeuwarderadeel", p27$claim_id)], collapse = "/"),
         p27$reported_value[p27$claim_id == "T8_amsterdambwh_1740_82"], sep = "; "))
write_csv(chk, file.path(out, "internal_checks.csv"))
