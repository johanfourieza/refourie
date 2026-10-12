# P13_FS S3 independent recreation: 01_clean.R
# Conditional independence: DATA20141122 is the authors' own analysis file.
suppressMessages({library(haven); library(dplyr)})
source(here::here("tools", "paths.R"))
od <- dpath("P13_FS", "original", "MOOC 8")
scr <- dscratch("P13_FS", "repro_r")
a <- zap_labels(read_dta(file.path(od, "DATA20141122.dta")))
p <- zap_labels(read_dta(file.path(od, "PURPOSEDATA_20141117.dta")))
a <- a |> filter(!is.na(household_iden))   # drops 128 empty (genealogy-only) rows -> 4160 inventories
stopifnot(nrow(a) == 4160, n_distinct(a$mooc) == 4160)
a$male <- as.numeric(a$gender == "m")
a$decade <- floor(a$year / 10) * 10
# transaction counts per inventory from the purpose file (one row per transaction side)
cn <- p |> group_by(mooc) |>
  summarise(ncredit = sum(!is.na(value_credits)), ndebt = sum(!is.na(value_debt)), .groups = "drop")
a <- a |> left_join(cn, by = "mooc") |>
  mutate(ncredit = coalesce(ncredit, 0L), ndebt = coalesce(ndebt, 0L))
saveRDS(a, file.path(scr, "inv.rds")); saveRDS(p, file.path(scr, "purpose.rds"))
cat("inventories", nrow(a), "debt rows", sum(cn$ndebt), "credit rows", sum(cn$ncredit), "\n")
