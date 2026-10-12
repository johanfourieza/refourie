# P10_FI S6 step 1: verification checks and the H1 primary analyses (card §4 A and A-B).
# Run from the project root: Rscript P10_FI/modern/01_descriptive.R
source(file.path("P10_FI", "modern", "00_functions.R"))
L <- load_angreg("v2018"); a <- L$a; b <- desc_universe(a)
s2 <- fread(file.path("P10_FI", "repro_original", "results_original_v2018.csv"))
s2v <- function(id) s2[claim_id == id, value]

# ---- Verification: corrections off -> S2 ----------------------------------------------------------
yrs_orig <- L$years[year >= 1911 & year <= 1963]                     # Figure 3 definition (script, on ang)
f3 <- s2[grepl("^F3_", claim_id)][, year := as.integer(sub("F3_", "", claim_id))]
f3m <- merge(f3[, .(year, s2 = value)], yrs_orig[, .(year, share)], by = "year")
ser <- annual_series(b)
cmp_def <- merge(ser[, .(year, corrected = y)], yrs_orig[, .(year, fig3 = share)], by = "year")
osh <- function(yy) yrs_orig[year %in% yy, 100 * sum(m) / sum(m + s)]
ver <- rbindlist(list(
  data.table(check = "V1 descriptive universe N = S2 Table 1 total", value = nrow(b), target = s2v("t1_cnt_tt")),
  data.table(check = "V2 Figure-3 definition (corrections off): max |diff| vs S2 F3 values, all years", value = max(abs(f3m$s2 - f3m$share)), target = 0),
  data.table(check = "V2 Figure-3 definition: number of S2 F3 years matched", value = nrow(f3m), target = nrow(f3)),
  data.table(check = "V3 S25 (white-husband 1925) vs S2 txt_p637_1925_share", value = 100 * b[year == 1925 & mrace == "White", mean(frace != "White")], target = s2v("txt_p637_1925_share")),
  data.table(check = "V3 Figure-3 definition 1925 share vs S2 txt_fn15_1925_all", value = yrs_orig[year == 1925, share], target = s2v("txt_fn15_1925_all")),
  data.table(check = "V4 Figure-3 definition pooled 1930-39 vs S2 note", value = osh(1930:1939), target = 2.00),
  data.table(check = "V4 Figure-3 definition pooled 1911-13 vs S2 note", value = osh(1911:1913), target = 7.29),
  data.table(check = "V5 corrected vs Figure-3 definition: years that differ", value = sum(abs(cmp_def$corrected - cmp_def$fig3) > 1e-9), target = NA),
  data.table(check = "V5 corrected vs Figure-3 definition: max |diff| (pp)", value = max(abs(cmp_def$corrected - cmp_def$fig3)), target = NA),
  data.table(check = "V5 corrected vs Figure-3 definition: total couples difference", value = sum(yrs_orig$m + yrs_orig$s) - nrow(b), target = NA)))
ver[, pass := ifelse(is.na(target), NA, abs(value - target) < ifelse(grepl("V4", check), 0.005, 1e-6))]
print(ver)
fwrite(ver, file.path(OUT, "verification_h1.csv"))

# ---- H1 primary --------------------------------------------------------------------------------
cnt <- h1_counts(b, "inter"); P <- length(cnt$P)
pt_est <- h1_from_W(cnt, matrix(1, 1, P))
W <- parish_W(P)
bs <- h1_from_W(cnt, W)
saveRDS(list(bs = bs), dscratch("P10_FI", "modern", "h1_boot_primary.rds"))   # aggregate draws, D: scratch
ci <- rbindlist(lapply(c("d30", "E25", "G", "D", "L30", "s1", "s3", "s4", "S25", "F"), function(q) data.table(quantity = q, t(pct_ci(bs[[q]])))))
fi <- fieller_F(bs$A, bs$D)
prim <- data.table(quantity = names(pt_est), estimate = unlist(pt_est))
prim <- merge(prim, ci, by = "quantity", all.x = TRUE)
prim[quantity == "F", `:=`(fieller_lo = fi["lo"], fieller_hi = fi["hi"], fieller_bounded = fi["bounded"], fieller_convex = fi["convex"])]
prim[, `:=`(block = "H1", B = B_BOOT, ci_level = 1 - ALPHA_FAM, note = "parish-cluster bootstrap (parishdum), percentile CI on defined draws")]
# Undefined-draw failure rate for each quantity used by a Family Q row
fail <- data.table(quantity = c("d30", "E25", "G", "D"), fail_rate = sapply(c("d30", "E25", "G", "D"), function(q) mean(!is.finite(bs[[q]]))))
fail[, not_testable := fail_rate > FAIL_MAX]
print(prim[, .(quantity, estimate = round(estimate, 4), lo = round(lo, 4), hi = round(hi, 4), fail)]); print(fi); print(fail)
fwrite(prim, file.path(OUT, "h1_primary.csv")); fwrite(fail, file.path(OUT, "bootstrap_failures.csv"))

# Parish counts (card §4 A-B)
pc <- data.table(item = c("parishes (parishdum) in descriptive universe", paste("parishes with marriages", names(WIN_PRIMARY)), "parishes with white-husband marriages in 1925", "white-husband marriages 1925", "couples in descriptive universe"),
                 value = c(P, sapply(WIN_PRIMARY, function(yy) sum(rowSums(cnt$N[, as.character(yy), drop = FALSE]) > 0)), sum(cnt$WH > 0), sum(cnt$WH), sum(cnt$N)))
print(pc); fwrite(pc, file.path(OUT, "h1_parish_counts.csv"))
writeLines(capture.output(sessionInfo()), file.path("P10_FI", "modern", "sessionInfo.txt"))
