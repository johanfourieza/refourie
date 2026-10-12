# P25_MCF S3 rebuild, step 1: owner-level valuation/compensation file from the Ekama et al. (2021)
# Slave Emancipation Dataset (the only surviving input that needs no linkage).
# Input : ./P25_MCF/original/Slawerekords/Slave Emancipation Dataset.xlsx (36,417 slave rows)
# Output: ./P25_MCF/repro_r/derived/owners.rds (owner-level; stays on D:, A6)
#         repro_r/output/owner_coverage_by_district.csv (aggregates only)
suppressMessages({library(readxl); library(dplyr); library(readr); library(here)})
source(here::here("tools", "paths.R"))
set.seed(20231)

f <- dpath("P25_MCF", "original", "Slawerekords", "Slave Emancipation Dataset.xlsx")
d <- read_excel(f, guess_max = 50000)
stopifnot(nrow(d) == 36417)

# Owner = district x UCL (claim number) x owner surname x forename. Compensation is recorded once per
# owner (on one slave row); Valuation is recorded per slave (D2 in decisions.md).
owners <- d |>
  group_by(District_name, UCL, Owner_surname, Owner_name) |>
  summarise(n_slaves = n(),
            n_valued = sum(!is.na(Valuation)),
            n_comp_rows = sum(!is.na(Compensation)),
            V = sum(Valuation, na.rm = TRUE),
            C = sum(Compensation, na.rm = TRUE),
            .groups = "drop") |>
  mutate(stell = District_name == "Stellenbosch",
         has_comp = n_comp_rows >= 1,
         all_valued = n_valued == n_slaves,
         AS = (V - C) / n_slaves,          # average shortfall per slave, Eq. (IV): (pS - C)/S
         comp_share = ifelse(V > 0, C / V, NA_real_))

dir.create(dpath("P25_MCF", "repro_r", "derived"), recursive = TRUE, showWarnings = FALSE)
saveRDS(owners, dpath("P25_MCF", "repro_r", "derived", "owners.rds"))

cov <- owners |>
  group_by(District_name) |>
  summarise(owners = n(), slaves = sum(n_slaves), slaves_valued = sum(n_valued),
            owners_with_comp = sum(has_comp),
            owners_comp_any_valued = sum(has_comp & n_valued >= 1),
            owners_comp_all_valued = sum(has_comp & all_valued), .groups = "drop")
write_csv(bind_rows(cov, summarise(cov, District_name = "Total", across(where(is.numeric), sum))),
          here::here("P25_MCF", "repro_r", "output", "owner_coverage_by_district.csv"))
