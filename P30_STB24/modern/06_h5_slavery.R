# P30_STB24 S6 step 6: H5a-H5c, slave ownership (Fig 7 population: owner households, census years < 1830).
# 16 H5a contrasts, Delta Z^M, Delta Z^W, Delta C; two-stage percentile-t at the Family H5 level (card s3, s4, s8).
# Also: s5B items 3, 4 for H5, set sizes per window, S-d.
source("P30_STB24/modern/00_common.R")
t0 <- Sys.time()
d <- readRDS(SCR("central.rds"))
Y <- prep_years(d)
WIN <- h5_windows(names(Y))
CS <- h5_contrasts(grep("^R", names(WIN), value = TRUE))
print(sapply(WIN, length))

U0 <- lapply(WIN, function(w) st_slave(Y, occ_fixed(Y, w)))
pt <- h5_stats(U0, CS)
# minimum years: each mean of a contrast rests on >= 5 census years with its category recorded among owners
minyrs <- sapply(CS, function(c0) all(sapply(c0$req, function(r) sum(U0[[r[1]]][, r[2]] > 0) >= 5)))
print(cbind(pt, minyrs))

# set sizes per window (s3 H5 reporting)
sets <- rbindlist(lapply(names(WIN), function(w) { u <- U0[[w]]
  data.table(window = w, census_years = length(WIN[[w]]), owner_rows_men = sum(u[, "men_n"]), years_men = sum(u[, "men_n"] > 0),
             owner_rows_women = sum(u[, "wom_n"]), years_women = sum(u[, "wom_n"] > 0), owner_rows_children = sum(u[, "chi_n"]),
             years_children = sum(u[, "chi_n"] > 0), owner_rows_complete = sum(u[, "cc_n"]), years_complete = sum(u[, "cc_n"] > 0),
             mean_men = sum(u[, "men_s"]) / sum(u[, "men_n"]), mean_women = sum(u[, "wom_s"]) / sum(u[, "wom_n"]),
             mean_children = sum(u[, "chi_s"]) / sum(u[, "chi_n"]), share_zero_men = sum(u[, "zm"]) / sum(u[, "men_n"]),
             share_zero_women = sum(u[, "zw"]) / sum(u[, "wom_n"]),
             child_share = sum(u[, "cc_c"]) / sum(u[, c("cc_m", "cc_w", "cc_c")]),
             share_ge2_women = sum(u[, "w2"]) / sum(u[, "wom_n"])) }))
fwrite(sets, file.path(OUT, "h5_window_sets.csv"))
fwrite(sets[grepl("^R", window), .(row = sub("R", "", window), share_ge2_women, owner_rows_women)], file.path(OUT, "secondary_Sd.csv"))

cls <- lapply(WIN, function(w) make_clusters(Y, w))
f_two   <- function(b) { s <- h5_stats(lapply(WIN, function(w) st_slave(Y, occ_two_stage(Y, w))), CS); c(s[, 1], s[, 2]) }
f_block <- function(b) { s <- h5_stats(lapply(WIN, function(w) st_slave(Y, occ_block(Y, w))), CS); c(s[, 1], s[, 2]) }
f_names <- function(b) { s <- h5_stats(lapply(cls, function(cl) st_slave(Y, occ_names(Y, cl))), CS); c(s[, 1], s[, 2]) }
ex <- c("Y", "WIN", "CS", "cls", "h5_stats", "rat")
B0 <- as.integer(Sys.getenv("B0", "19999"))
boot <- function(f, B, from = 1) do.call(rbind, run_boot(B, f, export = ex, from = from))
R <- boot(f_two, B0)
k <- length(CS); side <- sapply(CS, `[[`, "side")
summ <- function(R, B) rbindlist(lapply(seq_len(k), function(i) {
  th <- R[, i]; se <- R[, k + i]; ok <- is.finite(th) & is.finite(se) & se > 0
  ts <- (th[ok] - pt[i, 1]) / se[ok]
  ci <- pt_interval(pt[i, 1], pt[i, 2], ts, ALPHA[["H5"]]); mc <- pt_mcse(pt[i, 1], pt[i, 2], ts, ALPHA[["H5"]])
  data.table(contrast = names(CS)[i], side = side[i], estimate = pt[i, 1], se = pt[i, 2], lo = ci[["lo"]], hi = ci[["hi"]],
             mcse_lo = mc[["lo"]], mcse_hi = mc[["hi"]], nfail = sum(!ok), failmax = FAILMAX("H5", B), B = B)
}))
S <- summ(R, B0)
near <- function(S) any(abs(S$lo) < 2 * S$mcse_lo | abs(S$hi) < 2 * S$mcse_hi)
mc_escalated <- FALSE
if (near(S)) { mc_escalated <- TRUE; R <- rbind(R, boot(f_two, 49999, from = 20000)); S <- summ(R, 49999) }
S[, `:=`(mc_escalated = mc_escalated, mc_fragile = mc_escalated & near(S), minyrs_ok = minyrs)]
S[, defined := minyrs_ok & is.finite(estimate) & is.finite(se) & nfail <= failmax]
S[, category := mapply(function(lo, hi, e, s, def) if (!def) "undefined" else classify_cmp(lo, hi, e, s), lo, hi, estimate, side, defined)]
S[, fp_point_claimed := sign(estimate) == side]
S[, row := sub("_.*", "", contrast)]
print(S); fwrite(S, file.path(OUT, "h5_primary.csv"))
saveRDS(R, SCR("h5_boot_two.rds"))

# ---- diagnostics: s5B items 3 (blocks), 4 (name clusters) ----
Rb <- boot(f_block, B0); Rn <- boot(f_names, B0)
a <- ALPHA[["H5"]]; pct <- function(x) quantile(x[is.finite(x)], c(a / 2, 1 - a / 2), names = FALSE)
diag <- rbindlist(lapply(seq_len(k), function(i) {
  tb <- (Rb[, i] - pt[i, 1]) / Rb[, k + i]; okb <- is.finite(tb) & Rb[, k + i] > 0
  cb <- pt_interval(pt[i, 1], pt[i, 2], tb[okb], a)
  data.table(contrast = names(CS)[i], estimate = pt[i, 1], se_primary_jack = pt[i, 2], sd_two_stage = sd(R[, i], na.rm = TRUE),
             block_sd = sd(Rb[, i], na.rm = TRUE), block_lo = cb[["lo"]], block_hi = cb[["hi"]], block_fail = sum(!okb),
             names_sd = sd(Rn[, i], na.rm = TRUE), names_lo = pct(Rn[, i])[1], names_hi = pct(Rn[, i])[2], names_fail = sum(!is.finite(Rn[, i])),
             block_category = classify_cmp(cb[["lo"]], cb[["hi"]], pt[i, 1], side[i]),
             names_category = classify_cmp(pct(Rn[, i])[1], pct(Rn[, i])[2], pt[i, 1], side[i]))
}))
print(diag); fwrite(diag, file.path(OUT, "h5_diag_inference.csv"))
fwrite(data.table(window = names(cls), clusters = sapply(cls, `[[`, "K"), rows = sapply(cls, function(x) sum(x$sizes)),
                  multi_year_clusters = sapply(cls, function(x) sum(x$sizes > 1)), max_size = sapply(cls, function(x) max(x$sizes))),
       file.path(OUT, "h5_name_clusters.csv"))
cat("runtime:", format(Sys.time() - t0), "\n")
