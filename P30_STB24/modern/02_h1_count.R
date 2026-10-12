# P30_STB24 S6 step 2: H1, the household count (card s3 H1, s4 check 3, s5E).
source("P30_STB24/modern/00_common.R")
hh <- as.data.table(readRDS(dpath(PAPER, "repro_r", "_scratch", "households.rds")))   # S3 rule-2 rows (repro_r/01_clean.R)
n_rule2 <- nrow(hh)
num <- setdiff(names(hh)[sapply(hh, is.numeric)], c("year", "row", "nr", "hh_id"))      # D1: hh_id is a row index, not data
noname <- function(x) is.na(x) | trimws(x) == ""
hh[, nodata := rowSums(as.matrix(.SD) != 0 & !is.na(as.matrix(.SD))) == 0, .SDcols = num]
hh[, nonobs := noname(name_men) & noname(name_women) & nodata]
N <- hh[nonobs == FALSE, .N]

raw <- read_raw(FALSE); raw[, year := as.numeric(year)]
byc <- merge(hh[, .(rule2 = .N, removed = sum(nonobs), N = sum(!nonobs)), by = year],
             raw[, .(analysis_file = .N), by = year], by = "year", all = TRUE)
byc[, diff_N_minus_file := N - analysis_file]
fwrite(byc, file.path(OUT, "h1_by_census.csv"))

# s5E item 2: rows with both names empty but some data; exact duplicate rows within a census
dcols <- setdiff(names(hh), c("row", "hh_id", "nodata", "nonobs"))
dup_s3   <- sum(duplicated(hh[, ..dcols]))
rcols <- setdiff(names(raw), "nr")
dup_file <- sum(duplicated(raw[, ..rcols]))
sheets <- readxl::excel_sheets(dpath(PAPER, "repro_r", "_scratch", "zip", "stellenbosch_panel_raw.xlsx"))
ysheets <- suppressWarnings(as.numeric(sheets)); ysheets <- ysheets[!is.na(ysheets)]

h1 <- data.table(
  quantity = c("rule2_rows (check 3: 142592)", "nonobservation_rows_removed", "N (H1 estimate)", "analysis_file_rows (published 142297)",
               "noname_rows_with_data", "exact_duplicate_rows_S3_within_census", "exact_duplicate_rows_analysisfile_within_census(excl nr)",
               "census_years_analysis_file", "census_year_sheets_raw_workbook", "census_years_paper"),
  value = c(n_rule2, sum(hh$nonobs), N, nrow(raw), hh[noname(name_men) & noname(name_women) & !nodata, .N], dup_s3, dup_file,
            uniqueN(raw$year), length(unique(ysheets)), 144))
print(h1)
fwrite(h1, file.path(OUT, "h1_count.csv"))
saveRDS(list(N = N, check3 = n_rule2 == 142592), SCR("h1.rds"))
