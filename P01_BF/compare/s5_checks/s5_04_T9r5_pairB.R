# P01_BF S5 check 4: pair-B gap for headline T9_r5 (Khoesan early -> middle).
# Crosses cohort construction (original age-group-midpoint bdec vs rebuild actual birth year) with model (raw vs controls).
suppressPackageStartupMessages({library(tidyverse); library(haven); library(here)})
proj <- here::here(); source(file.path(proj, "tools", "paths.R"))
o <- read_dta(dpath("P01_BF", "original", "Baten Fourie", "data.dta")) |> zap_labels()
f <- readRDS(dscratch("P01_BF", "repro_r", "p01_full.rds"))
d <- tibble(age = o$age, cyear = o$cyear, ko = o$bco == "ko", y = 125 * o$exactage, female2 = o$female2, female_r = f$female,
            age23 = o$age23, coh_o = o$bcoh, coh_r = as.integer(f$cohort)) |>
  filter(age > 22, age < 83, !is.na(cyear), ko)
res <- expand_grid(coh = c("coh_o", "coh_r"), model = c("raw", "ctrl_female2", "ctrl_female_r")) |>
  pmap_dfr(function(coh, model) {
    dd <- d |> filter(.data[[coh]] %in% 1:2) |> mutate(later = as.integer(.data[[coh]] == 2))
    rhs <- switch(model, raw = "later", ctrl_female2 = c("later", "female2", "age23"), ctrl_female_r = c("later", "female_r", "age23"))
    m <- lm(reformulate(rhs, "y"), data = dd)
    tibble(cohort = coh, model, est = coef(m)["later"], se = coef(summary(m))["later", 2], n = nrow(dd), n_early = sum(dd$later == 0))
  })
write_csv(res, file.path(proj, "P01_BF", "compare", "s5_checks", "s5_04_T9r5_pairB.csv"))
print(res)
