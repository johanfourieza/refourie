# P16_FvFC S3 independent recreation -- 01_clean.R
# Fourie & von Fintel (2010, Cliometrica): build the household file from the raw
# opgaafrollen compilation 'Time 1663 - 1757 ----  EDITED.xls'.
# Output: ./P16_FvFC/repro_r/data/households.rds (data stay off Dropbox, A6)

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(tidyr)
  library(readr)
})
source(here::here("tools", "paths.R"))
root <- here::here("P16_FvFC", "repro_r")

raw_file <- dpath("P16_FvFC", "original", "Wealth inequality", "Time 1663 - 1757 ----  EDITED.xls")
raw <- read_excel(raw_file, sheet = "Data", col_types = "text")

# ---- column dictionary (opgaafrol codes) ------------------------------------
# M man, V vrou (wife), S seuns, D dogters, K knegte (hired hands)
# SM/SV/SS/SD slaves: men, women, boys, girls
# PD perde (horses), BSTE beeste (cattle), SKPE skape (sheep), VK varke (pigs)
# WINGST wingerdstokke (vines), WYN wine (leaguers)
# KGS/KGW koring gesaai/gewin (wheat sown/harvested); RGS/RGW rye; GGS/GGW gars (barley)
# SH snaphane (flintlocks), PS pistols, DG degens (swords)
count_vars <- c("M", "V", "S", "D", "K", "SM", "SV", "SS", "SD", "PD", "BSTE", "SKPE",
                "VK", "WINGST", "WYN", "KGS", "KGW", "RGS", "RGW", "GGS", "GGW",
                "SH", "PS", "DG")

# Non-numeric cells (single letters, occupation words, '2 1'-style double entries)
# are set to missing; missing counts are treated as zero (decisions.md, D2).
nonnum <- raw |>
  select(all_of(count_vars)) |>
  pivot_longer(everything(), values_to = "cell") |>
  filter(!is.na(cell), is.na(suppressWarnings(as.numeric(cell)))) |>
  count(name, cell, name = "n_cells")
write_csv(nonnum, file.path(root, "output", "nonnumeric_cells.csv"))

hh <- raw |>
  mutate(year = as.integer(Jaar),
         across(all_of(count_vars), ~ suppressWarnings(as.numeric(.x))),
         across(all_of(count_vars), ~ replace_na(.x, 0)),
         across(c(WED, VS, FH, DS), as.integer)) |>
  filter(year != 1705)                                    # fn 8: no weapons recorded in 1705

# ---- fn 7: impute seed sown where a harvest is reported without seed ----------
# OLS of seed on harvest over observations with both positive, per grain (D3).
impute_seed <- function(sown, harvest) {
  ok  <- sown > 0 & harvest > 0
  fit <- lm(sown[ok] ~ harvest[ok])
  need <- sown == 0 & harvest > 0
  sown[need] <- pmax(coef(fit)[1] + coef(fit)[2] * harvest[need], 0)
  list(sown = sown, n_imputed = sum(need), coef = coef(fit))
}
imp <- list(wheat  = impute_seed(hh$KGS, hh$KGW),
            rye    = impute_seed(hh$RGS, hh$RGW),
            barley = impute_seed(hh$GGS, hh$GGW))
hh <- hh |> mutate(KGS_i = imp$wheat$sown, RGS_i = imp$rye$sown, GGS_i = imp$barley$sown)
imp_log <- tibble(grain = names(imp),
                  n_imputed = sapply(imp, `[[`, "n_imputed"),
                  intercept = sapply(imp, \(z) z$coef[1]),
                  slope     = sapply(imp, \(z) z$coef[2]))
write_csv(imp_log, file.path(root, "output", "seed_imputation.csv"))

# ---- farmer flag, household size, slaves ------------------------------------
# Non-farmer = zero on all agricultural items: horses, cattle, sheep, pigs, vines,
# grains (sown or harvested) and wine (D4).
hh <- hh |>
  mutate(farmer   = (PD + BSTE + SKPE + VK + WINGST + WYN +
                     KGS + KGW + RGS + RGW + GGS + GGW) > 0,
         slaves   = SM + SV + SS + SD,
         hhsize   = pmax(M + V + S + D, 1),            # free family members (D5)
         hhsize_k = pmax(M + V + S + D + K, 1),        # sensitivity: include knegte
         hid      = row_number()) |>
  select(hid, ID, Van, Naam, year, WED, VS, FH, DS, farmer, hhsize, hhsize_k, slaves,
         SM, SV, SS, SD, PD, BSTE, SKPE, VK, WINGST, WYN,
         KGS = KGS_i, RGS = RGS_i, GGS = GGS_i, KGW, RGW, GGW, SH, PS, DG)

# ---- appendix Table 3 analogue (unweighted means; N) ------------------------
t3 <- bind_rows(
  hh |> mutate(grp = ifelse(farmer, "farmers", "nonfarmers")),
  hh |> mutate(grp = "whole")) |>
  group_by(year, grp) |>
  summarise(n = n(), slaves = mean(slaves), flintlocks = mean(SH), swords = mean(DG),
            pistols = mean(PS), .groups = "drop")
write_csv(t3, file.path(root, "output", "table3_check.csv"))

dir.create(dpath("P16_FvFC", "repro_r", "data"), recursive = TRUE, showWarnings = FALSE)
saveRDS(hh, dpath("P16_FvFC", "repro_r", "data", "households.rds"))
cat("Households (1705 excluded):", nrow(hh), " farmers:", sum(hh$farmer), "\n")
