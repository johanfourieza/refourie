# P30_STB24 S6 step 5: H4, "Inequality in wine output seems to increase until the 1780s and then on average declines".
# D_rise = Gbar_Peak - Gbar_Pre, D_fall = Gbar_Peak - Gbar_Post; two-stage percentile-t at the Family H4 level (card s3, s4, s8).
# Also: s5B items 1, 3, 4 for H4.
source("P30_STB24/modern/00_common.R")
t0 <- Sys.time()
d <- readRDS(SCR("central.rds"))
Y <- prep_years(d)
G0 <- year_ginis(d)[is.finite(wine), .(year, G = wine)]           # T_wine
W <- list(Pre = as.character(G0[year < 1780, year]), Peak = as.character(G0[year >= 1780 & year <= 1789, year]),
          Post = as.character(G0[year > 1789, year]))
print(sapply(W, length))

pt <- h4_stats(lapply(W, function(w) st_gini(Y, occ_fixed(Y, w), "wine")))
minyrs_ok <- all(sapply(W, length) >= 5)
print(pt)

cls <- lapply(W, function(w) make_clusters(Y, w))
f_two   <- function(b) h4_stats(lapply(W, function(w) st_gini(Y, occ_two_stage(Y, w), "wine")))
f_block <- function(b) h4_stats(lapply(W, function(w) st_gini(Y, occ_block(Y, w), "wine")))
f_names <- function(b) h4_stats(lapply(cls, function(cl) st_gini(Y, occ_names(Y, cl), "wine")))
ex <- c("Y", "W", "h4_stats", "cls")
B0 <- as.integer(Sys.getenv("B0", "19999"))
boot <- function(f, B, from = 1) do.call(rbind, run_boot(B, f, export = ex, from = from))
R <- boot(f_two, B0)

summ <- function(R, B) rbindlist(lapply(1:2, function(k) {
  th <- R[, k]; se <- R[, 2 + k]; ok <- is.finite(th) & is.finite(se) & se > 0
  ts <- (th[ok] - pt[k]) / se[ok]
  ci <- pt_interval(pt[k], pt[2 + k], ts, ALPHA[["H4"]]); mc <- pt_mcse(pt[k], pt[2 + k], ts, ALPHA[["H4"]])
  data.table(contrast = c("D_rise", "D_fall")[k], estimate = pt[k], se = pt[2 + k], lo = ci[["lo"]], hi = ci[["hi"]],
             mcse_lo = mc[["lo"]], mcse_hi = mc[["hi"]], nfail = sum(!ok), failmax = FAILMAX("H4", B), B = B)
}))
S <- summ(R, B0)
near <- function(S) any(abs(S$lo) < 2 * S$mcse_lo | abs(S$hi) < 2 * S$mcse_hi)
mc_escalated <- FALSE
if (near(S)) { mc_escalated <- TRUE; R <- rbind(R, boot(f_two, 49999, from = 20000)); S <- summ(R, 49999) }
S[, `:=`(mc_escalated = mc_escalated, mc_fragile = mc_escalated & near(S), minyrs_ok = minyrs_ok,
         n_Pre = length(W$Pre), n_Peak = length(W$Peak), n_Post = length(W$Post))]
S[, defined := minyrs_ok & is.finite(estimate) & is.finite(se) & nfail <= failmax]
S[, category := mapply(function(lo, hi, e, def) if (!def) "undefined" else classify_cmp(lo, hi, e, 1), lo, hi, estimate, defined)]
S[, fp_point_claimed := estimate > 0]
gbar <- sapply(W, function(w) mean(G0[year %in% as.numeric(w), G]))
S[, `:=`(Gbar_Pre = gbar[["Pre"]], Gbar_Peak = gbar[["Peak"]], Gbar_Post = gbar[["Post"]])]
print(S); fwrite(S, file.path(OUT, "h4_primary.csv"))
fwrite(G0, file.path(OUT, "h4_wine_gini_annual.csv"))
saveRDS(R, SCR("h4_boot_two.rds"))

# ---- diagnostics: s5B items 1 (within-year, from the H3 draws), 3 (blocks), 4 (name clusters) ----
hw <- readRDS(SCR("h3_wine_draws.rds"))
wi <- lapply(W, function(w) match(as.numeric(w), hw$years))
Dw <- cbind(rise = rowMeans(hw$draws[, wi$Peak]) - rowMeans(hw$draws[, wi$Pre]),
            fall = rowMeans(hw$draws[, wi$Peak]) - rowMeans(hw$draws[, wi$Post]))
Rb <- boot(f_block, B0); Rn <- boot(f_names, B0)
a <- ALPHA[["H4"]]; pct <- function(x) quantile(x[is.finite(x)], c(a / 2, 1 - a / 2), names = FALSE)
diag <- rbindlist(lapply(1:2, function(k) {
  tb <- (Rb[, k] - pt[k]) / Rb[, 2 + k]; okb <- is.finite(tb) & Rb[, 2 + k] > 0
  cb <- pt_interval(pt[k], pt[2 + k], tb[okb], a)
  data.table(contrast = c("D_rise", "D_fall")[k], estimate = pt[k], se_primary_jack = pt[2 + k], sd_two_stage = sd(R[, k], na.rm = TRUE),
             within_sd = sd(Dw[, k]), within_lo = pct(Dw[, k])[1], within_hi = pct(Dw[, k])[2],
             block_sd = sd(Rb[, k], na.rm = TRUE), block_lo = cb[["lo"]], block_hi = cb[["hi"]], block_fail = sum(!okb),
             names_sd = sd(Rn[, k], na.rm = TRUE), names_lo = pct(Rn[, k])[1], names_hi = pct(Rn[, k])[2],
             block_category = classify_cmp(cb[["lo"]], cb[["hi"]], pt[k], 1),
             names_category = classify_cmp(pct(Rn[, k])[1], pct(Rn[, k])[2], pt[k], 1),
             within_category = classify_cmp(pct(Dw[, k])[1], pct(Dw[, k])[2], pt[k], 1))
}))
print(diag); fwrite(diag, file.path(OUT, "h4_diag_inference.csv"))
fwrite(data.table(window = names(cls), clusters = sapply(cls, `[[`, "K"), rows = sapply(cls, function(x) sum(x$sizes)),
                  multi_year_clusters = sapply(cls, function(x) sum(x$sizes > 1)), max_size = sapply(cls, function(x) max(x$sizes))),
       file.path(OUT, "h4_name_clusters.csv"))
cat("runtime:", format(Sys.time() - t0), "\n")
