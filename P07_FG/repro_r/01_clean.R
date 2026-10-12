# P07_FG S3 independent recreation -- 01_clean.R
# Fourie & Green (2015, JAH) "The missing people".
# Reads the rawest opgaaf extraction (Data.xlsx), builds herd value and the
# household-level Khoesan imputation. Writes a cleaned .rds to the D: scratch.
# Choices are documented in repro_r/decisions.md (D1-D8).

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(here)
})
source(here::here("tools", "paths.R"))

PAPER <- "P07_FG"
f_in  <- dpath(PAPER, "original", "14 FG Missing People", "Data.xlsx")
f_out <- dscratch(PAPER, "repro_r", "opgaaf_clean.rds")

raw <- read_excel(f_in, sheet = "Data")
stopifnot(nrow(raw) == 17292)

# District codes (D2): 1 Cape, 2 Stellenbosch, 3 Drakenstein, 4 Swellendam.
# Identified from the paper's two anecdotes: Jacobus Botha (1773, Swellendam)
# is District 4; Adam Tas (1709, Stellenbosch) is District 2. Code 5 (1688
# only) and code 0 (12 households in 1773) are not identifiable; they are
# treated as outside the three western districts and get no Khoesan.
dist_lab <- c(`0` = "Unknown", `1` = "Cape", `2` = "Stellenbosch",
              `3` = "Drakenstein", `4` = "Swellendam", `5` = "Code5")

d <- raw %>%
  mutate(
    district = recode(as.character(District), !!!dist_lab),
    # Herd value (D1): value of horses, cattle and sheep at the workbook's
    # constant prices (Rds 15.8, 8.7, 1.0). Botha check: 19, 250, 900 -> 3375.2.
    herd = Vhorses + Vcattle + Vsheep,
    # 'Farmer' (D3): household produced any opgaaf commodity (Output > 0).
    farmer = Output > 0,
    # Slave-holding category for the ratio (D4): total slaves owned.
    slave_cat = case_when(Slaves > 5 ~ "gt5", Slaves >= 1 ~ "1to5", TRUE ~ "0"),
    # Ratios as stated in the text (p.204): Swellendam 67.5/57.5/47.5;
    # Stellenbosch and Drakenstein 'double': 135/115/95; Cape: none.
    ratio_stated = case_when(
      district == "Swellendam" ~ c(gt5 = 67.5, `1to5` = 57.5, `0` = 47.5)[slave_cat],
      district %in% c("Stellenbosch", "Drakenstein") ~
        c(gt5 = 135, `1to5` = 115, `0` = 95)[slave_cat],
      TRUE ~ NA_real_),
    # POST-HOC variant (D9, logged in decisions.md): Stellenbosch at 1.5x the
    # Drakenstein ratios (202.5/172.5/142.5). Found by least squares against
    # the published Table 1; NOT stated in the paper. Sensitivity only.
    ratio_posthoc = case_when(
      district == "Stellenbosch" ~ 1.5 * c(gt5 = 135, `1to5` = 115, `0` = 95)[slave_cat],
      TRUE ~ ratio_stated),
    khoesan        = if_else(farmer & !is.na(ratio_stated),  herd / ratio_stated,  0),
    khoesan_posthoc = if_else(farmer & !is.na(ratio_posthoc), herd / ratio_posthoc, 0)
  )

# Anchor checks against the paper's anecdotes
botha <- d %>% filter(str_detect(Surname, "BOTHA"), Name == "JACOBUS", Year == 1773,
                      Slavemales == 20)
tas   <- d %>% filter(str_detect(Surname, "^TAS"), Year == 1709)
stopifnot(nrow(botha) == 1, abs(botha$herd - 3375.2) < 0.01,
          nrow(tas) == 1, abs(tas$herd - 2041.2) < 0.01)

saveRDS(d, f_out)
cat("Wrote", f_out, "rows:", nrow(d), "\n")
