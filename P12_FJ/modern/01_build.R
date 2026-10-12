# P12_FJ S6 01_build.R -- corrected analysis file (rules O and D) and the data variants of §5; rows on D: only.
# Verification: with both corrections off the build must equal the S3 rebuild file (repro_r/01_clean.R) column by column.
source(here::here("P12_FJ", "modern", "00_common.R"))
scr <- dscratch("P12_FJ", "modern"); out <- here::here("P12_FJ", "modern", "output"); dir.create(out, showWarnings = FALSE)
raw <- read_raw()
V <- list(
  main    = build(raw),
  uncorr  = build(raw, ruleO = FALSE, ruleD = FALSE),    # sens 1
  O_only  = build(raw, ruleD = FALSE),                   # sens 2
  D_only  = build(raw, ruleO = FALSE),                   # sens 2
  D_0to7  = build(raw, dwin = 0),                        # sens 3
  D_rec   = build(raw, drecorded = TRUE),                # sens 4
  win_dec = build(raw, pan_end = "1918-12-31"),          # sens 10
  docinit = build(raw, docinit = TRUE))                  # sens 17
saveRDS(V, file.path(scr, "variants.rds"))
# verification against the S3 rebuild file
s3 <- readRDS(dpath("P12_FJ", "repro_r", "_scratch", "analysis.rds")); u <- V$uncorr
cols <- intersect(c("town","date","pandemic","race","doc","signature","age","male","occgrp","bgrp","Nurse","Railway","Street_road_and_stad","Farm","Death_in_Family", ages, occs), names(s3))
ver <- tibble(column = cols, identical = sapply(cols, function(v) identical(as.vector(u[[v]]), as.vector(s3[[v]]))))
ver <- bind_rows(tibble(column = "nrow", identical = nrow(u) == nrow(s3)), ver)
write.csv(ver, file.path(out, "check_build_vs_S3.csv"), row.names = FALSE)
# how many records each rule moves (aggregate only)
m <- V$main
cnt <- tibble(
  item = c("rows", "ruleO_moved_to_Professionals", "occgrp_changed_vs_uncorr", "DiF_uncorr", "DiF_main", "DiF_changed", "DiF_0to7", "DiF_rec_nonNA", "doc_initials_only",
           "pandemic_main", "pandemic_win_dec"),
  n = c(nrow(m), sum(m$ruleO_moved), sum(coalesce(m$occgrp, "NA") != coalesce(u$occgrp, "NA")), sum(u$Death_in_Family), sum(m$Death_in_Family),
        sum(m$Death_in_Family != u$Death_in_Family), sum(V$D_0to7$Death_in_Family), sum(!is.na(V$D_rec$Death_in_Family)), sum(m$doc_initials),
        sum(m$Pandemic), sum(V$win_dec$Pandemic)))
write.csv(cnt, file.path(out, "build_counts.csv"), row.names = FALSE)
print(ver, n = 50); print(cnt)
