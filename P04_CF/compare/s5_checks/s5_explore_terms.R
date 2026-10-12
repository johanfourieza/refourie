# S5: structure of occup terms vs occ_group codes in the 2017 file (aggregates only)
suppressMessages({library(haven); library(dplyr); library(tidyr)})
source(file.path(normalizePath(".."), "tools", "paths.R"))  # [A6] data root on D:
dir.create(dpath("P04_CF", "compare", "_scratch_s5"), recursive = TRUE, showWarnings = FALSE)
r <- read_dta(dpath("P04_CF", "original", "CF Mobility", "Data", "SAF mobility data_10.08.2017.dta")) |> zap_labels()
cat("occup (combined) example structure: n distinct", n_distinct(r$occup), "\n")
oc <- paste0("occup",1:15); og <- paste0("occ_group",1:8)
nterm <- rowSums(!is.na(r[oc]) & r[oc]!="")
ngrp  <- rowSums(!is.na(r[og]))
print(table(nterm, ngrp))
# relation between term class and group: single-term rows
s1 <- r |> filter(nterm==1) |> count(occup1, occ_group1) |> group_by(occup1) |> mutate(k=n()) 
cat("terms with >1 group among single-term rows:", sum(s1$k>1),"\n")
print(s1 |> filter(occup1 %in% c("farmer","grazier","century","smith","prisoner")))
# two-term rows: what groups?
s2 <- r |> filter(nterm==2) |> count(occup1, occup2, occ_group1, occ_group2, sort=TRUE)
print(head(s2, 25))
# Is 'occup' the concatenated string?
print(head(table(nchar(r$occup))))
