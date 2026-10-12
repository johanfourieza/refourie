# P07_FG S2: extract original-code results into results_original.csv.
# Run from the project root:  Rscript P07_FG/repro_original/extract_results.R
# Sources: logs/run_CreatingKhoe.log (Tables 1, 3-6), logs/run_productivity.log (text checks),
#          Excel formula chains recalculated by excel_recalc.R (Table 2, growth rate, ratios, Figure 3).
suppressWarnings(suppressPackageStartupMessages({library(dplyr); library(readr); library(stringr); library(tidyxl)}))
p <- "P07_FG"; ro <- file.path(p, "repro_original")
source(file.path(ro, "excel_recalc.R"))
DD <- "./P07_FG/original/14 FG Missing People"

# ---------- tabstat parser ----------
read_log <- function(f) { x <- readLines(f, warn = FALSE)
  # re-join Stata's wrapped command lines ("> ...")
  out <- character(0); for (l in x) { if (startsWith(l, "> ") && length(out)) out[length(out)] <- paste0(out[length(out)], substring(l, 3)) else out <- c(out, l) }; out }
# parse the first tabstat table after line index i; returns list(group -> numeric matrix [stat x var])
parse_tab <- function(L, i) {
  h <- which(grepl("^-+\\+-+$", L) & seq_along(L) > i)[1]          # header rule
  vars <- str_split(str_trim(str_split_fixed(L[h - 1], "\\|", 2)[2]), "\\s+")[[1]]
  res <- list(); g <- NULL; j <- h + 1
  while (j <= length(L) && !grepl("^-+$", L[j])) {
    if (grepl("^-+\\+", L[j])) { j <- j + 1; next }
    parts <- str_split_fixed(L[j], "\\|", 2); lab <- str_trim(parts[1])
    v <- as.numeric(str_split(str_trim(parts[2]), "\\s+")[[1]])
    if (lab != "") { g <- lab; res[[g]] <- matrix(v, nrow = 1, dimnames = list(NULL, vars)) } else res[[g]] <- rbind(res[[g]], v)
    j <- j + 1
  }
  res
}
find_cmd <- function(L, pat, k = 1) which(grepl(pat, L, fixed = TRUE))[k]

L <- read_log(file.path(ro, "logs", "run_CreatingKhoe.log"))
out <- list(); add <- function(id, value, n = NA, note = "", ovr = NA) out[[length(out) + 1]] <<- tibble(claim_id = id, value = value, n = n, note = note, status_override = ovr)
dist <- c("1" = "Capedistrict", "2" = "Stellenbosch", "3" = "Drakenstein", Total = "Total")

# ---------- Tables 3 and 4 (do-file "Table 2" and "Table 3") ----------
for (tt in list(list("T3", "*Table 2", c("slagprod", "labgprod")), list("T4", "*Table 3", c("slawprod", "labwprod")))) {
  tb <- parse_tab(L, find_cmd(L, tt[[2]]))
  for (g in names(dist)) { m <- tb[[g]]
    add(paste0(tt[[1]], "_", dist[g], "_n"), m[2, tt[[3]][1]], m[2, tt[[3]][1]], paste("CreatingKhoe.do", tt[[2]]))
    add(paste0(tt[[1]], "_", dist[g], "_without"), m[1, tt[[3]][1]], m[2, tt[[3]][1]], "slave productivity (no Khoesan)")
    add(paste0(tt[[1]], "_", dist[g], "_with"), m[1, tt[[3]][2]], m[2, tt[[3]][2]], "productivity incl. imputed Khoesan") }
}
# ---------- Table 5 (do-file "Table 4"); % change = (with-without)/without*100 as in Dataset.xlsx 'Slave productivity'!R,U ----------
tb5 <- parse_tab(L, find_cmd(L, "*Table 4"))
d0 <- "; Total row: published/Excel total (N=1096) includes one district-0 household (1773) that line 8 drops - see PATCHES.md D1"
for (g in names(dist)) { m <- tb5[[g]]; nt <- if (g == "Total") d0 else ""
  add(paste0("T5_", dist[g], "_n"), m[2, "slagprod"], m[2, "slagprod"], paste0("CreatingKhoe.do *Table 4", nt))
  add(paste0("T5_", dist[g], "_wheat_without"), m[1, "slagprod"], m[2, "slagprod"], nt)
  add(paste0("T5_", dist[g], "_wheat_with"), m[1, "labgprod"], m[2, "labgprod"], nt)
  add(paste0("T5_", dist[g], "_wheat_pct"), (m[1, "labgprod"] - m[1, "slagprod"]) / m[1, "slagprod"] * 100, m[2, "slagprod"], paste0("Excel formula (D-C)/C*100 on Stata means", nt))
  add(paste0("T5_", dist[g], "_wine_without"), m[1, "slawprod"], m[2, "slawprod"], nt)
  add(paste0("T5_", dist[g], "_wine_with"), m[1, "labwprod"], m[2, "labwprod"], nt)
  add(paste0("T5_", dist[g], "_wine_pct"), (m[1, "labwprod"] - m[1, "slawprod"]) / m[1, "slawprod"] * 100, m[2, "slawprod"], paste0("Excel formula (T-S)/S*100 on Stata means", nt)) }
# ---------- Table 6 (do-file "Table 5": two tabstats) ----------
i5 <- find_cmd(L, "*Table 5"); t6a <- parse_tab(L, i5); i5b <- find_cmd(L, "slavemales>5, by(district)"); t6b <- parse_tab(L, i5b)
for (sz in list(list("s1to5", t6a), list("s6plus", t6b))) for (g in names(dist)) { m <- sz[[2]][[g]]
  nn <- if (sz[[1]] == "s1to5") sprintf("; 'with' columns use N=%d (condition slaves!=0, so farms with female slaves only enter labgprod/labwprod but not slagprod/slawprod)", m[2, "labgprod"]) else ""
  if (g == "Total" && sz[[1]] == "s6plus") nn <- paste0(nn, "; Total row: published N=432 includes one district-0 household (PATCHES.md D1)")
  pre <- paste0("T6_", dist[g], "_", sz[[1]])
  add(paste0(pre, "_n"), m[2, "slagprod"], m[2, "slagprod"], paste0("N of slagprod", nn))
  add(paste0(pre, "_wheat_without"), m[1, "slagprod"], m[2, "slagprod"], nn); add(paste0(pre, "_wheat_with"), m[1, "labgprod"], m[2, "labgprod"], nn)
  add(paste0(pre, "_wine_without"), m[1, "slawprod"], m[2, "slawprod"], nn); add(paste0(pre, "_wine_with"), m[1, "labwprod"], m[2, "labwprod"], nn) }

# ---------- Table 1 (extraction X1: sums of imputed Khoesan and slaves by year) ----------
ix <- find_cmd(L, "X1: extraction")
t1 <- list(all = parse_tab(L, find_cmd(L, "tabstat cattlekhoe slaves slavemales, by(year)")),
           csd = parse_tab(L, find_cmd(L, "if _csd==1, by(year)")),
           swe = parse_tab(L, find_cmd(L, "if district==4, by(year)")))
for (r in names(t1)) for (g in names(t1[[r]])) { m <- t1[[r]][[g]]
  nt <- if (r != "swe") "; slaves: published value = this +39 in 1773/Total (district-0 household, PATCHES.md D1)" else ""
  add(paste0("T1_", g, "_", r, "_khoesan"), m[1, "cattle~e"], m[2, 1], "sum of cattlekhoe (CreatingKhoe.do l.25-39) on do-file sample")
  add(paste0("T1_", g, "_", r, "_slaves"), m[1, "slaves"], m[2, 1], paste0("sum of slaves on do-file sample", nt)) }

# ---------- Excel chains ----------
rcD <- recalc_workbook(file.path(DD, "Dataset.xlsx")); vD <- wb_values(file.path(DD, "Dataset.xlsx"), rcD)
rcK <- recalc_workbook(file.path(DD, "KhoesanGDPnew.xlsx")); vK <- wb_values(file.path(DD, "KhoesanGDPnew.xlsx"), rcK)
cv <- function(v, sh, a) v$value[v$sheet == sh & v$address == a]
saveRDS(list(rcD = rcD, rcK = rcK), "./P07_FG/repro_original/_scratch/recalc.rds")
chk <- bind_rows(rcD |> mutate(wb = "Dataset"), rcK |> mutate(wb = "KhoesanGDPnew")) |> filter(!is.na(cached)) |>
  group_by(wb) |> summarise(formulas = n(), max_absdiff = max(absdiff, na.rm = TRUE), n_diff_gt_1e9 = sum(absdiff > 1e-9, na.rm = TRUE))
write_csv(chk, file.path(ro, "output", "excel_recalc_check.csv"))

# Table 2 ('Khoe pop 1790': inputs + SUM formulas)
rows <- c(Christian = 4, Slaves = 5, Khoesan = 6, Totalpopulation = 7, Horses = 8, Cattle = 9, Sheep = 10, Wineleaguers = 13, Wheattarwen = 14, Barley = 15, Rye = 16)
cols <- c(Cape = "B", Stellenbosch = "C", Swellendam = "D", GraaffReinet = "E", Total = "F")
for (rn in names(rows)) for (cn in names(cols)) {
  a <- paste0(cols[cn], rows[rn]); v <- cv(vD, "Khoe pop 1790", a); if (length(v) == 0 || is.na(v)) v <- if (rn == "Khoesan" && cn == "Cape") 0 else NA
  f <- vD$formula[vD$sheet == "Khoe pop 1790" & vD$address == a]
  nt <- if (length(f) && !is.na(f)) paste0("recalculated =", f) else "input cell (General description 1790)"
  if (rn == "Khoesan" && cn == "Cape") nt <- "blank input cell (= 0)"
  if (rn == "Totalpopulation" && cn == "Total") nt <- paste(nt, "- formula omits Graaff-Reinet (E7=14173); full sum = 52317")
  if (!is.na(v)) add(paste0("T2_", rn, "_", cn), v, NA, nt) }

# Growth rate (Opgaafrol!J3 = (D17/D5)^(1/J7)-1, i.e. CSD series) recomputed from the Stata sums
csd85 <- t1$csd[["1685"]][1, "cattle~e"]; csd73 <- t1$csd[["1773"]][1, "cattle~e"]; all85 <- t1$all[["1685"]][1, "cattle~e"]; all73 <- t1$all[["1773"]][1, "cattle~e"]
gr <- ((csd73 / csd85)^(1 / 88) - 1) * 100; gr_all <- ((all73 / all85)^(1 / 88) - 1) * 100
stopifnot(abs(gr / 100 - cv(vD, "Opgaafrol", "J3")) < 1e-6)
add("tx_p205_kh_1685", all85, NA, "T1 1685 all regions"); add("tx_p205_kh_1773", all73, NA, "T1 1773 all regions")
add("tx_p205_kh_growth", gr, NA, sprintf("Opgaafrol!J3 = (D17/D5)^(1/88)-1 uses the Cape/Stell/Drak series (121.8 -> 3295.7); the text's endpoints 122 -> 6843 give %.2f%%", gr_all))
sw_k <- t1$swe$Total[1, "cattle~e"]; sw_s <- t1$swe$Total[1, "slaves"]; sw_m <- t1$swe$Total[1, "slavem~s"]
add("tx_p205_swe_khoesan", sw_k, NA, "T1 Swellendam total"); add("tx_p205_swe_maleslaves", sw_m, NA, "sum of slavemales, Swellendam 1757+1773")
add("tx_p205_swe_ratio", sw_k / sw_s, NA, sprintf("Opgaafrol!F21 = F18/G18 divides by ALL slaves (%d); Khoesan per male slave (%d) = %.2f", sw_s, sw_m, sw_k / sw_m))
add("tx_p206_own_stel_1773", csd73, NA, "T1 1773 Cape/Stell/Drak column")
add("tx_p206_gd_stel", cv(vD, "Khoe pop 1790", "C6"), NA, "input cell T2")
add("tx_p206_ratio_gr_swe", (cv(vD, "Khoe pop 1790", "D6") + cv(vD, "Khoe pop 1790", "E6")) / (cv(vD, "Khoe pop 1790", "D5") + cv(vD, "Khoe pop 1790", "E5")), NA, "(800+9083)/(2196+964) from T2 inputs; no workbook formula")
# code constants
add("tx_p204_ratio_swe_gt5", 67.5, NA, "CreatingKhoe.do l.31 (district 4)"); add("tx_p204_ratio_step", 10, NA, "CreatingKhoe.do l.29-31: 47.5/57.5/67.5")
add("tx_p204_ratio_sd_gt5", 135, NA, "CreatingKhoe.do l.35, Drakenstein only; Stellenbosch (district 2) uses 202.5 (l.39), i.e. triple not double")
add("tx_p204_ratio_sd_1to5", 115, NA, "l.34 Drakenstein; Stellenbosch uses 172.5 (l.38)"); add("tx_p204_ratio_sd_0", 95, NA, "l.33 Drakenstein; Stellenbosch uses 142.5 (l.37)")
add("tx_p208_herd1000", 1000, NA, "vherd<1000 in CreatingKhoe.do l.56-67 and productivity.do l.62")
# data lookups in missingpeople.dta (no code; checks the anecdote inputs)
dta <- haven::read_dta(file.path(DD, "missingpeople.dta")) |> mutate(vherd = vcattle + vsheep + vhorses)
bo <- dta |> filter(surname == "BOTHA SR", name == "JACOBUS", year == 1773); ta <- dta |> filter(surname == "TAS", name == "ADAM", year == 1709)
nb <- "data lookup: BOTHA SR JACOBUS, Swellendam, opgaafrol 1773 (missingpeople.dta)"
add("tx_p204_botha_maleslaves", bo$slavemales, NA, nb); add("tx_p204_botha_femaleslaves", bo$slavefemales, NA, nb); add("tx_p204_botha_horses", bo$horses, NA, nb)
add("tx_p204_botha_cattle", bo$cattle, NA, nb); add("tx_p204_botha_sheep", bo$sheep, NA, nb); add("tx_p204_botha_herdvalue", bo$vherd, NA, nb)
nt <- "data lookup: TAS ADAM, Stellenbosch, opgaafrol 1709"
add("tx_p204_tas_herd", ta$vherd, NA, nt); add("tx_p204_tas_vines", ta$vineyards, NA, nt); add("tx_p204_tas_ratio", ta$vherd / 11, NA, "Tas herd value / 11 Khoesan (text input)")
# text restatements of Tables 3, 5, 6
o <- bind_rows(out); g <- function(id) o$value[o$claim_id == id]
for (m in list(c("tx_p209_stel_wo", "T3_Stellenbosch_without"), c("tx_p209_stel_w", "T3_Stellenbosch_with"), c("tx_p209_drak_wo", "T3_Drakenstein_without"), c("tx_p209_drak_w", "T3_Drakenstein_with"),
               c("tx_p210_t5_stel_wo", "T5_Stellenbosch_wheat_without"), c("tx_p210_t5_drak_wo", "T5_Drakenstein_wheat_without"), c("tx_p210_t5_stel_w", "T5_Stellenbosch_wheat_with"), c("tx_p210_t5_drak_w", "T5_Drakenstein_wheat_with"),
               c("tx_p210_t6_wheat_wo_small", "T6_Total_s1to5_wheat_without"), c("tx_p210_t6_wheat_wo_large", "T6_Total_s6plus_wheat_without"), c("tx_p210_t6_wheat_w_small", "T6_Total_s1to5_wheat_with"), c("tx_p210_t6_wheat_w_large", "T6_Total_s6plus_wheat_with"),
               c("tx_p210_t6_wine_wo_small", "T6_Total_s1to5_wine_without"), c("tx_p210_t6_wine_wo_large", "T6_Total_s6plus_wine_without"), c("tx_p210_t6_wine_w_small", "T6_Total_s1to5_wine_with"), c("tx_p210_t6_wine_w_large", "T6_Total_s6plus_wine_with")))
  add(m[1], g(m[2]), NA, paste("=", m[2]))
# productivity.do (Fourie Slaves) checks
Lp <- read_log(file.path(ro, "logs", "run_productivity.log"))
a <- parse_tab(Lp, find_cmd(Lp, "tabstat slagprod if year==1741")); b <- parse_tab(Lp, find_cmd(Lp, "tabstat slawprod if year==1773"))
add("tx_p209_rep_1000", a[["1"]][1, "Mean"], a[["1"]][1, "N"], "productivity.do l.62: 1741, Cape district, vherd<1000, grain-only")
add("tx_p209_rep_1000_n", a[["1"]][1, "N"], a[["1"]][1, "N"], "productivity.do l.62")
add("tx_p209_redo_wine_stel", b[["2"]][1, "Mean"], b[["2"]][1, "N"], "productivity.do l.65: 1773, Stellenbosch, wine-only, vherd<1000")

# ---------- Figure 3 and GDP text claims (KhoesanGDPnew.xlsx recalculated; FvZ and England are input series) ----------
te <- vK |> filter(sheet == "total economy", col %in% c(1, 24, 27)) |> select(row, col, value) |> tidyr::pivot_wider(names_from = col, values_from = value) |> rename(year = `1`, new = `24`, eng = `27`) |> filter(!is.na(year), year >= 1701, year <= 1800)
gc <- vD |> filter(sheet == "GDPcomparison_data", col %in% c(1, 4, 5, 8), row >= 3) |> select(row, col, value) |> tidyr::pivot_wider(names_from = col, values_from = value) |> rename(year = `1`, fvz = `4`, new_cached = `5`, eng2 = `8`)
gd <- te |> inner_join(gc, by = "year")
link1 <- max(abs(gd$new - gd$new_cached), na.rm = TRUE)                                  # pasted link KhoesanGDPnew -> Dataset
gdpB <- vD |> filter(sheet == "GDP", col == 2, row >= 53) |> transmute(year = row + 1649, kh = value)
popZ <- vK |> filter(sheet == "Population", col == 26, row >= 53, row <= 147) |> transmute(year = row + 1648, z = value)
link2 <- max(abs(inner_join(gdpB, popZ, by = "year") |> with(kh - z)), na.rm = TRUE)       # pasted link Dataset GDP!B -> Population!Z
for (y in c(1701, 1708, 1711, 1721, 1751, 1773, 1781, 1791)) { r <- gd[gd$year == y, ]
  add(paste0("F3_", y, "_new"), r$new, NA, "recalculated 'total economy'!X (KhoesanGDPnew.xlsx)")
  add(paste0("F3_", y, "_fvz"), r$fvz, NA, "input series (GDPcomparison_data!D, Fourie-van Zanden 2013; no formula)")
  add(paste0("F3_", y, "_eng"), r$eng, NA, "input series ('total economy'!AA, England)") }
add("tx_p214_gdp_year_new", max(gd$year[gd$new >= gd$eng], na.rm = TRUE), NA, "last year recalculated new GDP pc >= England")
add("tx_p214_gdp_year_old", max(gd$year[gd$fvz >= gd$eng2], na.rm = TRUE), NA, "last year FvZ GDP pc >= England (GDPcomparison_data D vs H)")
add("tx_p214_khoesan_ext", 1649 + 109, NA, "GDP!B110:B186 (1759-1835) add $C$109, the 1757-1773 slope stored in the 1758 row")

# ---------- unavailable / not attempted ----------
for (id in c("T7_GiniAll_fvf", "T7_GiniAll_khoesan", "T7_TheilBetween_fvf", "T7_TheilBetween_khoesan", "T7_TheilWithin_fvf", "T7_TheilWithin_khoesan",
             "tx_p213_gini_fvf", "tx_p213_gini_kh", "tx_p213_theil_within_fvf", "tx_p213_theil_within_kh"))
  add(id, NA, NA, "no code: Dataset.xlsx 'Inequality' and Dieter.xlsx hold pasted values only (cached 0.744/0.504, Theil between 0.331/0.354, within 0.669/0.387)", "unavailable")
for (id in c("tx_p208_herd100", "tx_p208_herd400", "tx_p208_rep_400", "tx_p208_rep_400_n")) add(id, NA, NA, "Worden replication at Rds 100/400 not scripted", "unavailable")
for (id in c("tx_p203_base_1652", "tx_p203_base_1780", "tx_p203_growth", "tx_p202_fvz_1795")) add(id, NA, NA, "Khoe pop!B:C baseline/FvZ series are pasted values (no formula)", "unavailable")
for (id in c("tx_p206_1806_share", "tx_p207_1830s_lo", "tx_p207_1830s_hi")) add(id, NA, NA, "'Aggregate Hottentots' shares are pasted values; 1806 share not in files", "unavailable")
for (id in c("tx_p201_elphick_pop", "tx_p201_elphick_area", "tx_p201_elphick_density", "tx_p201_guelke_khoe", "tx_p201_guelke_san", "tx_p203_smallpox_1713", "tx_p203_smallpox_1755",
             "tx_p204_botha_clan", "tx_p204_tas_khoesan", "tx_p208_worden_1741", "tx_p208_worden_cape", "tx_p209_worden_wine_stel", "tx_p209_worden_wine_cape", "tx_p209_barrow_wine"))
  add(id, NA, NA, "literature/anecdote input, not computed by original code", "not-attempted")

res <- bind_rows(out) |> mutate(source = "original", se = NA_real_) |> select(claim_id, source, value, se, n, status_override, note)
claims <- read_csv(file.path(p, "claims", "claims.csv"), show_col_types = FALSE)
miss <- setdiff(claims$claim_id, res$claim_id); extra <- setdiff(res$claim_id, claims$claim_id)
if (length(extra)) stop("unknown claim ids: ", paste(extra, collapse = ", "))
if (length(miss)) res <- bind_rows(res, tibble(claim_id = miss, source = "original", value = NA, se = NA, n = NA, status_override = "not-attempted", note = "not mapped"))
stopifnot(!any(duplicated(res$claim_id)))
write_csv(res, file.path(ro, "results_original.csv"), na = "")
cat("rows:", nrow(res), " missing mapped:", length(miss), "\n"); print(chk)
cat(sprintf("link GDP!B vs Population!Z max diff %.2e; total economy X vs GDPcomparison E max diff %.2e\n", link2, link1))
