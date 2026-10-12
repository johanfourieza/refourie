# P18_FvFS S6 modern reanalysis - shared data loading and specification (sourced by 01-03).
# Mirrors repro_original/published_spec_attempt.do (Tables 3-4, specs 4, 7, 10) exactly.
suppressPackageStartupMessages({library(haven); library(fixest); library(dplyr); library(readr)})
root <- "./P18_FvFS"; source("./tools/paths.R")
od <- file.path(root, "modern", "output"); dir.create(od, showWarnings = FALSE)
SEED <- 20261011
setFixest_nthreads(1)  # deterministic

d <- read_dta(dpath("P18_FvFS", "repro_original/extracted/results/exclpc/final_excl_1.dta")) |> zap_labels() |>
  filter(year >= 1700, year != 1716) |>                       # ALIGN-3
  mutate(vpc = vines_planted / hhsize,                         # ALIGN-4
         g = factor(group), dist = factor(district), yr = factor(year), mar = factor(marital),
         # card s4: normalised surname = lower-case, trimmed, diacritics stripped; missing -> singleton
         sur0 = tolower(trimws(iconv(surname, to = "ASCII//TRANSLIT"))),
         sur = ifelse(is.na(sur0) | sur0 == "", paste0("_row", row_number()), sur0),
         decade = floor(year / 10) * 10, dist_dec = paste(district, decade, sep = "_"),
         wine_hh = wine * hhsize,                              # household-total wine (s5.2)
         # consistent units (s5.3): dta stores knechts, cattle, horses, wheat, wine per member
         kn_h = knechts * hhsize, ca_h = cattle * hhsize, ho_h = horses * hhsize, wr_h = wheat_reaped * hhsize,
         sl_pm = total_slaves / hhsize,
         anywine = as.numeric(wine > 0),
         lpos = ifelse(wine > 0, log(wine), NA_real_))

# published regressors (published_spec_attempt.do lines 106-111)
X <- list(
  pub  = list(c4 = "total_slaves + knechts + cattle + horses + vpc + i(mar, ref = 0) + wheat_reaped",
              c7 = "total_slaves + knechts + cattle + horses + vpc + i(mar, ref = 0)"),
  hh   = list(c4 = "total_slaves + kn_h + ca_h + ho_h + vines_planted + i(mar, ref = 0) + wr_h",
              c7 = "total_slaves + kn_h + ca_h + ho_h + vines_planted + i(mar, ref = 0)"),
  pm   = list(c4 = "sl_pm + knechts + cattle + horses + vpc + i(mar, ref = 0) + wheat_reaped",
              c7 = "sl_pm + knechts + cattle + horses + vpc + i(mar, ref = 0)"),
  nochoice = list(c4 = "knechts + cattle + horses + wheat_reaped",   # drop vines, marital, slaves
                  c7 = "knechts + cattle + horses"))
claims <- tibble(claim_id = c("T3_r2_c4", "T4_r1_c7", "T4_r1_c10"), spec = c("c4", "c7", "c10"),
                 pub_b = c(0.751, 0.721, 1.992), stated = c(0.75, 0.72, 2.00), M = c(0.375, 0.36, 1.00))

sample_of <- function(spec, data = d) switch(spec,
  c4 = data, c7 = data[data$group > 1, ], c10 = data[data$group > 1 & data$firstarrivals == 1, ])
ref_of <- function(spec) if (spec == "c4") 1 else 2
# right-hand side: c4/c7 = group + controls + born-abroad dummy | year + district FE; c10 = group only (ALIGN-6)
rhs_of <- function(spec, xset = "pub") {
  if (spec == "c10") return(sprintf("i(g, ref = %d)", ref_of(spec)))
  sprintf("i(g, ref = %d) + %s + firstarrivals | yr + dist", ref_of(spec), X[[xset]][[spec]])
}
WH <- "g::3"
