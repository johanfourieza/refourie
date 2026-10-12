# P29_INEQ25 S6 step 1: build analysis data from the raw input files (card §0: "computed from the data, not from
# the script's run-order state"). The opgaaf cleaning follows original l.54-305 exactly, and is verified against
# the S5 re-run object opgaaf_save2 (patched original code). Adds hhid_ext_safe (cluster id) and settler_women.
# Output (D: only): <SCR>/data.rds. Run: Rscript P29_INEQ25/modern/01_data.R
source("P29_INEQ25/modern/00_functions.R")
suppressPackageStartupMessages(library(readxl))
O <- function(...) dpath(PAPER, "original", "2024F_Inequality", ...)
S5 <- function(k) readRDS(dpath(PAPER, "compare", "_scratch", "obj", paste0(k, ".rds")))

## ---- opgaaf panel (l.54-305) ---------------------------------------------------------------------------
f <- O("stellenbosch_clean_april2025.xlsx"); sh <- "stellenbosch_long_linked_apr202"
nc <- ncol(read_excel(f, sheet = sh, n_max = 1))
raw <- data.table(read_excel(f, sheet = sh, col_types = rep("text", nc)))
conv1 <- c("cattle_bull", "cattle_breeding", "cattle_work", "cattle_cows", "cattle_heifers", "cattle_calves", "horses", "horse_foals",
  "horse_work", "horse_breeding", "horse_pleasure", "donkeys", "sheep", "sheep_breeding", "sheep_wool", "sheep_wether", "goats",
  "sheep_goats", "pigs", "sheep_goats_pigs", "wheat_seed", "wheat_vol", "barley_seed", "barley_vol", "rye_seed", "rye_vol", "oat_seed",
  "oat_vol", "hay_vol", "maize_vol", "potatoes_vol", "peas_vol", "barleyryeoat_vol", "grains_vol", "zkoorn", "wheat_bz", "rye_bz",
  "barleyzk_vol", "bzkoorn", "bzkoorn1", "vines", "wine", "brandy")
horse_c <- c("horse_foals", "horse_work", "horse_breeding", "horse_pleasure")
cattle_c <- c("cattle_bull", "cattle_breeding", "cattle_work", "cattle_cows", "cattle_heifers", "cattle_calves")
sheep_c <- c("sheep_breeding", "sheep_wool", "sheep_wether", "sheep_goats")
# raw-blank flags for the missingness report (§5C.1): an asset is blank when the source has no entry in any of its columns
blank <- function(cols) rowSums(!is.na(raw[, ..cols])) == 0
rawna <- data.table(na_horses = blank(c("horses", horse_c)), na_cattle = blank(cattle_c), na_sheep = blank(c("sheep", sheep_c)),
                    na_wheat_vol = blank("wheat_vol"), na_vines = blank("vines"), na_wine = blank("wine"))
op <- copy(raw)
num <- function(v) suppressWarnings(as.numeric(gsub("[^0-9.]", "", as.character(v))))
for (cc in conv1) set(op, j = cc, value = num(op[[cc]]))
conv2 <- c("settler_men", "settler_women", "settler_sons", "settler_daughters", "slave_men", "slave_women", "slave_sons", "slave_daughters",
           "khoe_men", "khoe_women", "khoe_sons", "khoe_daughters", setdiff(conv1, c("wheat_seed")) , "wheat_seed")
# replace_na_with_zero (l.103-116): within each (text) year in which a column has any non-NA entry, NA -> 0.
# (Applied in the code to a longer list; only the columns used below matter. On text columns 0 is stored as "0".)
yr <- op$year
for (cc in unique(conv2)) {
  v <- op[[cc]]; yrs <- unique(yr[!is.na(v)]); idx <- which(is.na(v) & yr %in% yrs)
  if (length(idx)) { if (is.character(v)) v[idx] <- "0" else v[idx] <- 0; set(op, j = cc, value = v) }
}
op[is.na(horses), horses := rowSums(.SD, na.rm = TRUE), .SDcols = horse_c]
op[, cattle := rowSums(.SD, na.rm = TRUE), .SDcols = cattle_c]
op[is.na(sheep), sheep := rowSums(.SD, na.rm = TRUE), .SDcols = sheep_c]
for (cc in c("slave_men", "slave_women", "slave_sons", "slave_daughters", "khoe_men", "khoe_women", "khoe_sons", "khoe_daughters",
             "settler_men", "settler_women", "settler_sons", "settler_daughters")) set(op, j = cc, value = num(op[[cc]]))
op[, slaves := rowSums(.SD, na.rm = TRUE), .SDcols = c("slave_men", "slave_women", "slave_sons", "slave_daughters")]
op[, khoe := rowSums(.SD, na.rm = TRUE), .SDcols = c("khoe_men", "khoe_women", "khoe_sons", "khoe_daughters")]
op[, settlers := rowSums(.SD, na.rm = TRUE), .SDcols = c("settler_men", "settler_women", "settler_sons", "settler_daughters")]
op[, year := suppressWarnings(as.numeric(year))]
keep_y <- !is.na(op$year)
op <- op[keep_y]; rawna <- rawna[keep_y]
op[, decade := (year %/% 10) * 10]
op[, original_row := seq_len(.N)]
drop19 <- c(9802, 21124, 15515, 41686, 137633, 50115, 87634, 115473, 7082, 17822, 18358, 35500, 35534, 36546, 36548, 41765, 90267, 107007, 128102)
op <- op[-drop19]; rawna <- rawna[-drop19]
cols18 <- c("year", "decade", "names_men", "settler_men", "settlers", "slave_men", "slaves", "khoe", "slave_women", "slave_sons",
            "slave_daughters", "horses", "cattle", "sheep", "wheat_vol", "vines", "wine", "original_row")
panel <- cbind(op[, c(cols18, "settler_women", "hhid_ext_safe"), with = FALSE], rawna)
ref <- S5("opgaaf_save2")
chk_panel <- isTRUE(all.equal(as.data.frame(panel[, ..cols18]), as.data.frame(ref[, ..cols18]), check.attributes = FALSE))
stopifnot(chk_panel)
panel[, hh := as.integer(factor(hhid_ext_safe))]   # cluster index; missing ids would be singleton clusters
n_missing_id <- sum(is.na(panel$hhid_ext_safe) | panel$hhid_ext_safe == "")
if (n_missing_id > 0) panel[is.na(hhid_ext_safe) | hhid_ext_safe == "", hh := max(panel$hh, na.rm = TRUE) + seq_len(.N)]
cat("panel rows", nrow(panel), "| clusters", uniqueN(panel$hh), "| missing ids", n_missing_id, "| matches opgaaf_save2:", chk_panel, "\n")

prices <- as.data.frame(read_excel(O("price_series.xlsx")))
stopifnot(isTRUE(all.equal(prices, as.data.frame(S5("prices")), check.attributes = FALSE)))

## ---- Khoe settlements (l.2512-2717) -----------------------------------------------------------------------
gk0 <- read_excel(O("Groenekloof.xlsx"), sheet = "1825", col_names = FALSE, .name_repair = "minimal")
names(gk0) <- paste0("c", seq_along(gk0))
cn <- gk0 |> slice(1:3) |> t() |> as.data.frame(stringsAsFactors = FALSE) |> unite("col_name", sep = "_", na.rm = TRUE) |> pull(col_name)
cn[cn == ""] <- "Unnamed"; cn <- make.unique(cn); colnames(gk0) <- cn
gk_rawna <- gk0 |> slice(-1:-3)
gk <- gk_rawna |> mutate_all(~ ifelse(is.na(.), 0, .)) |>
  transmute(horses_saddle = `Horses_Saddle`, horses_breeding = `Breeding`, cattle_oxen = `Cattle_Draught Oxen`, cattle_breeding = `Breeding stock`,
            sheep_wethers = `Wethers`, sheep_breeding = `Sheep_Breeding`, sheep_spanish = `Spanish`, wheat_sown = `Quantity of Muids sown_Wheat`,
            wheat_reaped = `Quantity of Muids reaped_Wheat`) |>
  mutate(across(everything(), ~ suppressWarnings(as.numeric(as.character(.))))) |>
  mutate(horses = horses_saddle + horses_breeding, sheep = sheep_wethers + sheep_breeding + sheep_spanish)
gk_na <- gk_rawna |> transmute(horses = is.na(`Horses_Saddle`) & is.na(`Breeding`), oxen = is.na(`Cattle_Draught Oxen`), cattle = is.na(`Breeding stock`),
                               sheep = is.na(`Wethers`) & is.na(`Sheep_Breeding`) & is.na(`Spanish`), wheat = is.na(`Quantity of Muids reaped_Wheat`))
sr0 <- read_excel(O("Swartrivier.xlsx"), sheet = "Data", col_names = TRUE, .name_repair = "unique_quiet")
sr_na <- sr0 |> transmute(horses = is.na(`Wagon and Saddle Horses`) & is.na(`Breeding Horses`), oxen = is.na(Oxen), cattle = is.na(`Breeding cattle`),
                          sheep = is.na(Wethers) & is.na(`Breeding Sheep`), wheat = is.na(Wheat))
sr <- sr0 |> mutate_all(~ ifelse(is.na(.), 0, .)) |>
  transmute(horses_saddle = `Wagon and Saddle Horses`, horses_breeding = `Breeding Horses`, cattle_oxen = Oxen, cattle_breeding = `Breeding cattle`,
            sheep_wethers = Wethers, sheep_breeding = `Breeding Sheep`, wheat_sown = `Wheat sown`, wheat_reaped = Wheat) |>
  mutate(across(everything(), ~ suppressWarnings(as.numeric(as.character(.))))) |> mutate(across(everything(), ~ replace_na(., 0))) |>
  mutate(horses = horses_saddle + horses_breeding, sheep = sheep_wethers + sheep_breeding)
bd_read <- function(s) read_excel(O("EBTstation.xlsx"), sheet = s) |>
  transmute(horses_saddle = as.numeric(horseM), horses_breeding = as.numeric(horseF), cattle_oxen = as.numeric(cattleM),
            cattle_breeding = as.numeric(cattleF), sheep = as.numeric(sheep_goats), wheat_reaped = suppressWarnings(as.numeric(wheat_reaped))) |>
  mutate(horses = horses_saddle + horses_breeding)
bd14 <- bd_read("Bethelsdorp"); bd25 <- bd_read("Bethelsdorp1825")
# sanity against S5 objects (code-built)
stopifnot(isTRUE(all.equal(gk$horses, S5("district_gk")$horses)), isTRUE(all.equal(sr$cattle_breeding, S5("district_sr")$cattle_breeding)),
          isTRUE(all.equal(bd25$cattle_breeding, S5("district_bd")$cattle_breeding)))

## ---- secondary inputs ---------------------------------------------------------------------------------------
sed <- read_excel(O("Slave Emancipation Dataset.xlsx"), sheet = "Sheet1")
probates <- read_excel(O("MOOC_probates.xlsx"), sheet = "Sheet1") |> filter(year >= 1700 & year <= 1839) |> mutate(period = (year %/% 10) * 10)
# 1825 cross-section: the cleaning (l.1286-2500) is long and was validated at S2/S5; reuse the S5 re-run object (read-only copy).
f_ad <- dpath(PAPER, "compare", "_scratch", "obj", "all_districts.rds")
all_districts <- readRDS(f_ad)
md5_ad <- unname(tools::md5sum(f_ad))

saveRDS(list(panel = panel, prices = prices, gk = gk, sr = sr, bd14 = bd14, bd25 = bd25, gk_na = gk_na, sr_na = sr_na,
             sed = sed, probates = probates, all_districts = all_districts, md5_all_districts = md5_ad),
        file.path(SCR, "data.rds"))
writeLines(c(sprintf("panel_rows=%d", nrow(panel)), sprintf("clusters=%d", uniqueN(panel$hh)), sprintf("missing_ids=%d", n_missing_id),
             sprintf("panel_equals_opgaaf_save2=%s", chk_panel), sprintf("all_districts.rds md5=%s", md5_ad),
             sprintf("GK=%d SR=%d BD1814=%d BD1825=%d SED=%d probates=%d", nrow(gk), nrow(sr), nrow(bd14), nrow(bd25), nrow(sed), nrow(probates))),
           file.path(OUT, "01_data_log.txt"))
cat("done\n")
