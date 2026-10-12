# P11_FJS S3 recreation, step 1: household tax liabilities from the opgaafrolle, loan-farm property tax,
# and the secondary-source table inputs (Images 2-6) transcribed from the paper.
# Rules follow p.17 of Fourie, Jansen & Siebrits (2013); choices are documented in decisions.md (D1-D8, D13).

library(tidyverse)
library(haven)
library(readxl)
library(here)
source(here("tools", "paths.R"))

PAPER <- "P11_FJS"
raw_dir <- dpath(PAPER, "original", "Fourie Jansen Siebrits")

# Conversions (fn 28): 1 guilder = 16 stuivers; 1 rixdollar = 48 stuivers = 3 guilders
ST_PER_GLD <- 16
GLD_PER_RD <- 3

# ---- Opgaafrolle -------------------------------------------------------------
opg <- read_dta(file.path(raw_dir, "base.dta")) |>
  zap_labels() |>
  mutate(hh_id = row_number(), year = as.integer(jaar))

hh <- opg |>
  mutate(
    slaves = sm + sv + ss + sd,
    # D3: agricultural assets exclude horses
    ag_assets = (bste + skpe + vk + wingst + wyn + kgs + kgw + rgs + rgw + cgs + cgw) > 0,
    poll_st = case_when(
      ag_assets ~ 0,
      slaves > 0 & ds %in% 1 ~ 4 * 48,   # hearth tax, Cape district as Cape Town proxy
      TRUE ~ 32
    ),
    # R1: poll on every household without cattle or sheep
    poll_r1_st = if_else(bste + skpe > 0, 0, if_else(slaves > 0 & ds %in% 1 & !ag_assets, 4 * 48, 32)),
    # D4: wine
    wine_rd = wyn * if_else(year < 1743, 1, 3),
    # D5: grain, 10% of recorded yield valued at 6 rd (wheat) and 3 rd (rye, barley) per muid
    grain_rd = 0.1 * (6 * kgw + 3 * (rgw + cgw)),
    # D6: livestock, pro rata
    meat_st = bste * 1 + skpe * 16 / 100,
    # Guilders
    poll = poll_st / ST_PER_GLD,
    poll_r1 = poll_r1_st / ST_PER_GLD,
    wine = wine_rd * GLD_PER_RD,
    grain = grain_rd * GLD_PER_RD,
    meat = meat_st / ST_PER_GLD,
    tax = poll + wine + grain + meat,
    tax_r1 = poll_r1 + wine + grain + meat
  ) |>
  select(hh_id, year, ds, slaves, ag_assets, poll, poll_r1, wine, grain, meat, tax, tax_r1)

# ---- Loan farms (D8) ---------------------------------------------------------
lf <- read_excel(file.path(raw_dir, "Loanfarms.xls"), sheet = "Loanfarms", guess_max = 10000)
lf_year <- lf |>
  mutate(year = suppressWarnings(as.integer(YEAR1))) |>
  filter(TYPE %in% c("New application", "Renewal"), !is.na(year)) |>
  count(year, name = "leases") |>
  mutate(
    property = leases * if_else(year >= 1732, 24, 12) * GLD_PER_RD,
    property_12rd = leases * 12 * GLD_PER_RD
  )

# ---- Secondary-source tables (D13), transcribed from the paper ---------------
img6 <- tribble(
  ~year, ~rev,   ~exp,    ~gdp,
  1777,  200000, 454000,  2391000,
  1787,  282000, 1586000, 4014000,
  1789,  341000, 1744000, 3472000,
  1791,  NA,     1300000, 3499000,
  1792,  416000, 758000,  3253000,
  1794,  588000, 818000,  NA
)

# ---- Write -------------------------------------------------------------------
saveRDS(hh, dscratch(PAPER, "repro_r", "hh_tax.rds"))
saveRDS(lf_year, dscratch(PAPER, "repro_r", "loanfarm_year.rds"))
saveRDS(img6, dscratch(PAPER, "repro_r", "img6_inputs.rds"))
cat("Households:", nrow(hh), " Loan-farm years:", nrow(lf_year), "\n")
