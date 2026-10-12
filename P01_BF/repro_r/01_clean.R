# P01_BF  Baten & Fourie (2015) — S3 independent recreation, step 1: build analysis sample
# Input : ./P01_BF/original/Baten Fourie/BatenFourie19Sept.xlsx (sheet Data)
#         ./P01_BF/original/Baten Fourie/BatenFourie.xlsx (sheet Data; gender only)
# Output: _scratch/p01_full.rds (all 2,908 rows, recoded), _scratch/p01_sample.rds (age 23-72),
#         output/crime_map.csv, output/sample_counts.csv
# See decisions.md for every coding choice.

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(here)
})
proj  <- here::here()
paper <- file.path(proj, "P01_BF")
source(file.path(proj, "tools", "paths.R"))
out   <- file.path(paper, "repro_r", "output")
dir.create(out, showWarnings = FALSE, recursive = TRUE)
src   <- dpath("P01_BF", "original", "Baten Fourie")

# ---- read --------------------------------------------------------------------
a <- suppressMessages(read_excel(file.path(src, "BatenFourie19Sept.xlsx"), sheet = "Data", guess_max = 5000))
b <- suppressMessages(read_excel(file.path(src, "BatenFourie.xlsx"),       sheet = "Data", guess_max = 5000))
stopifnot(nrow(a) == nrow(b), all(a$number == b$number), all(a$fullname == b$name, na.rm = TRUE))

d <- tibble(
  row      = seq_len(nrow(a)),
  name     = a$name,
  age      = a$`age...12`,
  knows    = a$knows,
  eth      = a$`eth...16`,
  eths     = a$eths,
  country  = a$`origincountry...10`,
  crime    = str_squish(tolower(a$crime)),
  pun      = str_squish(tolower(a$pun)),
  source   = a$source,
  cyear    = a$cyear,
  female   = b$female,
  female2  = b$female2,
  female3  = b$female3
)

# ---- crime categories (own reading of the Dutch/Afrikaans descriptions) ---------
crime_cat <- function(x) {
  viol <- paste("geweld", "aanranding", "kwetsing", "mishandeling", "verkragting", "brandstigting",
                "verset", "muitery", "hoogverraad", "ontvoering", "molestering", "resistance",
                "'n mes", "persecution", "justifiable defence", sep = "|")
  case_when(
    is.na(x) | x == "onskuldig"                          ~ NA_character_,
    x == "hulp aan drosters en moordenaars"               ~ "minor",   # aiding deserters, not murder
    str_detect(x, "moord|manslag|vergiftiging")           ~ "murder",
    str_detect(x, viol)                                   ~ "violence",
    str_detect(x, "theft|diefstal|inbraak|bedrog|vervalsing") ~ "theft",
    TRUE                                                  ~ "minor"
  )
}

# severe punishment: death sentences and capital-type punishments
sev_pun <- function(x) as.integer(str_detect(replace_na(x, ""),
  "hang|gehang|ledebraak|radbraak|verwurg|fusilleer|decapitat|verdrink|verbrand|gespit|spit|vierendeel|condemned"))

# ---- recode --------------------------------------------------------------------
d <- d |>
  mutate(
    exact   = as.integer(age %% 5 != 0),
    age23   = as.integer(age >= 23 & age <= 32),
    byear   = cyear - age,
    bdec    = pmin(floor(byear / 10) * 10, 1790),
    cohort  = case_when(bdec <= 1740 ~ "early", bdec <= 1780 ~ "middle", !is.na(bdec) ~ "late"),
    cohort  = factor(cohort, levels = c("early", "middle", "late")),
    know01  = case_when(knows == "nie" ~ 1L, knows == "gissing" ~ 0L),
    know01b = if_else(knows == "gissing", 0L, 1L, missing = 1L),   # alternative: blank = not guessing
    eu      = as.integer(eths == "eu"),
    matched = as.integer(!is.na(country)),
    group = case_when(
      eths == "eu" ~ "European",
      eths == "ko" ~ "Khoesan",
      eths == "cn" ~ "Chinese",
      country == "Cape Colony"                                   ~ "Cape-born",
      country %in% c("Mosambique", "Madagascar", "Mauritius")    ~ "Mozambican",
      country %in% c("India", "Ceilon")                          ~ "Indian",
      country %in% c("Indonesia", "Timor", "Malaysia", "Thailand") ~ "South-east Asian",
      country %in% c("China", "Macao")                           ~ "Chinese",
      TRUE                                                       ~ "Slave, unknown"
    ),
    group = factor(group, levels = c("Cape-born", "Chinese", "European", "South-east Asian",
                                     "Indian", "Khoesan", "Mozambican", "Slave, unknown")),
    crimecat = factor(crime_cat(crime), levels = c("theft", "minor", "violence", "murder")),
    severe   = as.integer(crimecat %in% c("violence", "murder")),
    severe   = if_else(is.na(crimecat), NA_integer_, severe),
    sevpun   = sev_pun(pun),
    # Table 7/8 cells: sparse cells absent from Table 7 go to "other slaves" of the same cohort
    cellgrp = case_when(
      group == "Cape-born"        & cohort == "early" ~ "Slave, unknown",
      group == "Mozambican"       & cohort == "early" ~ "Slave, unknown",
      group == "South-east Asian" & cohort == "late"  ~ "Slave, unknown",
      group == "Indian"           & cohort == "late"  ~ "Slave, unknown",
      TRUE ~ as.character(group)
    )
  )

s <- d |> filter(!is.na(age), age >= 23, age <= 72)

# share of severe crimes by birth decade (and by decade x Eu/non-Eu, alternative)
s <- s |>
  group_by(bdec) |>
  mutate(sevshare = mean(severe, na.rm = TRUE)) |>
  group_by(bdec, eu) |>
  mutate(sevshare_reg = mean(severe, na.rm = TRUE)) |>
  ungroup()

# ---- write ---------------------------------------------------------------------
saveRDS(d, dscratch("P01_BF", "repro_r", "p01_full.rds"))
saveRDS(s, dscratch("P01_BF", "repro_r", "p01_sample.rds"))

d |> filter(!is.na(age), age >= 23, age <= 72) |>
  count(crime, crimecat, name = "n_sample") |>
  arrange(crimecat, desc(n_sample)) |>
  write_csv(file.path(out, "crime_map.csv"))

bind_rows(
  tibble(item = "rows_workbook", n = nrow(d)),
  tibble(item = "age_23_72", n = nrow(s)),
  tibble(item = "age_23_72_with_bdec", n = sum(!is.na(s$bdec))),
  s |> count(group) |> transmute(item = paste0("group_", group), n),
  s |> filter(!is.na(bdec)) |> count(cellgrp, cohort) |> transmute(item = paste0("cell_", cellgrp, "_", cohort), n),
  s |> count(crimecat) |> transmute(item = paste0("crime_", crimecat), n)
) |> write_csv(file.path(out, "sample_counts.csv"))

cat("01_clean.R done: sample", nrow(s), "rows\n")
