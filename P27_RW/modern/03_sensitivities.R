# 03_sensitivities.R -- P27_RW S6: the card's section 5 sensitivities (items 1-24). Reported; never verdict-determining.
source("P27_RW/modern/00_common.R")
x <- readRDS(file.path(scr, "samples.rds")); Ifull <- x$I; Ofull <- x$O
I <- Ifull[, c("y", "s", "decade", "yr", "date")]; O <- Ofull[, c("s", "yr", "key")]
res <- list(); add <- function(item, label, v, lo = NA, hi = NA, und = NA)
  res[[length(res) + 1]] <<- data.frame(item, label, quantity = names(v), estimate = unname(v), lo = unname(lo), hi = unname(hi), undef_share = unname(und))
lv <- c("w1700", "w1790", "wtot", "D90w"); lu <- c("m1700", "m1790", "mtot", "D90")
pt <- estim(I, O)

# weighting scheme (1-7)
add(1, "pooled four-class shares 1700-73", estim(I, O, list(cf = cls4, nb = 1))[lv])
add(2, "two classes, time-balanced", estim(I, O, list(cf = cls2, nb = 4))[lv])
p0 <- mean(O$s >= 1); i1 <- mean(I$s >= 1); w3 <- ifelse(I$s >= 1, p0 / i1, (1 - p0) / (1 - i1)); pre <- I$decade <= 1800
add(3, "S5 scheme: two classes, all 2,577 inventories, pooled opgaaf",
    c(w1700 = wmean(I$y[I$decade == 1700], w3[I$decade == 1700]), w1790 = wmean(I$y[I$decade == 1790], w3[I$decade == 1790]),
      wtot = wmean(I$y[pre], w3[pre])) |> (\(v) c(v, D90w = v[["w1790"]] - v[["w1700"]]))())
ci <- cls4(I$s); co <- cls4(O$s); bi <- blk(I$yr, 4); bo <- blk(O$yr, 4)
half <- function(bb, h) { r <- ifelse(bb %in% (2 * h - 1):(2 * h), bb - 2 * (h - 1), NA); as.integer(r) }
wh <- lapply(1:2, function(h) mkw(tb_share(ci, half(bi, h), 4, 2), tb_share(co, half(bo, h), 4, 2)))
w4 <- ifelse(I$decade <= 1740, wh[[1]][ci], wh[[2]][ci])
add(4, "time-varying selection: weights 1700-36 (rows to 1740), 1737-73 (rows 1750+)",
    c(w1700 = wmean(I$y[I$decade == 1700], w4[I$decade == 1700]), w1790 = wmean(I$y[I$decade == 1790], w4[I$decade == 1790]),
      wtot = wmean(I$y[pre], w4[pre])) |> (\(v) c(v, D90w = v[["w1790"]] - v[["w1700"]]))())
Ow <- O[Ofull$wife > 0, ]
add(5, "opgaaf restricted to households with a wife (col 26 > 0)", estim(I, Ow)[c(lv, "mu_opg", "R", "pi_opg", "Delta")])
add(6, "group-variable class boundaries (5 slaves in class 3)", estim(I, O, list(cf = clsG, nb = 4))[lv])
add(7, "two time blocks", estim(I, O, list(cf = cls4, nb = 2))[lv]); add(7, "eight time blocks", estim(I, O, list(cf = cls4, nb = 8))[lv])

# sample (8-12)
add(8, "10 exact duplicates dropped", estim(I[!Ifull$dup, ], O)[c(lu, lv)])
add(9, "changed sample: 49 all-zero inventories dropped", estim(I[!Ifull$allzero, ], O)[c(lu, lv)])
I10 <- I; I10$decade[I10$decade == 1806] <- 1795   # include 1801-06 in the pooled total only (1795 is no row label)
add(10, "changed population (A4d): 1801-06 included, all 2,577", estim(I10, O)[c("mtot", "wtot")])
I11 <- I; I11$y <- Ifull$yns
add(11, "changed estimand: wealth net of slave value", estim(I11, O)[c(lu, lv)])
cut99 <- quantile(I$y[pre], 0.99, type = 7)
add(12, "changed estimand: top 1% of pooled pre-1801 wealth trimmed", estim(I[!(pre & I$y > cut99), ], O)[c(lu, lv)])

# shape (13-15) from the primary bootstrap
M1 <- readRDS(file.path(scr, "boot_primary.rds"))$M1
sb <- summ_boot(M1, c("slope", "slopew", "late", "latew", "endp", "endpw"))
for (k in seq_len(nrow(sb))) { q <- sb$quantity[k]; it <- c(slope = 13, slopew = 13, late = 14, latew = 14, endp = 15, endpw = 15)[[q]]
  add(it, "shape of change (descriptive)", pt[q], sb$lo[k], sb$hi[k], sb$undef_share[k]) }
# 16: row quantiles, weighted and unweighted
wq <- function(y, w, p) { o <- order(y); cw <- cumsum(w[o]) / sum(w); y[o][which(cw >= p)[1]] }
wi <- pt[paste0("wk", 1:4)][ci]
for (d in sort(unique(I$decade))) { s <- I$decade == d
  v <- c(sapply(c(p25 = .25, p50 = .5, p75 = .75), function(p) unname(quantile(I$y[s], p, type = 7))),
         sapply(c(p25w = .25, p50w = .5, p75w = .75), function(p) wq(I$y[s], wi[s], p)))
  add(16, paste("row", d, "quantiles"), v) }

# representativeness (17-20)
Ia <- I[I$yr >= 1700 & I$yr <= 1773, ]
add(17, "changed population (A4d): inventories dated 1700-73", estim(Ia, O)[c("mu_inv", "R", "pi_inv", "Delta")])
add(18, "mean slaves incl. zeros, inventories / opgaaf", c(mean_inv = mean(I$s), mean_opg = mean(O$s), ratio = mean(I$s) / mean(O$s)))
for (it in c("cattle", "horses", "sheep")) { a <- Ifull[[it]]; b <- Ofull[[it]]
  add(19, it, setNames(c(mean(a[a > 0]), mean(b[b > 0]), mean(a[a > 0]) / mean(b[b > 0]), mean(a > 0), mean(b > 0), mean(a > 0) - mean(b > 0)),
                       paste0(it, c("_mu_inv", "_mu_opg", "_R", "_pi_inv", "_pi_opg", "_Delta")))) }
add(20, "opgaafrolle.dta (n = 15,577) in place of the workbook", estim(I, x$O2)[c(lv, "mu_opg", "R", "pi_opg", "Delta")])

# inference and dependence (21-24): alternative joint bootstraps, B = 9,999 unless stated
qQ <- c("D90", "D90w", "R", "Delta")
runs <- list(list(21, "opgaaf block length 1", "estate", "block", 1, 9999), list(21, "opgaaf block length 3", "estate", "block", 3, 9999),
             list(21, "opgaaf block length 10", "estate", "block", 10, 9999), list(21, "opgaaf household-key cluster bootstrap", "estate", "cluster", 5, 9999),
             list(22, "inventories in year clusters within rows", "year", "block", 5, 9999),
             list(23, "(a) opgaaf fixed, inventories resampled", "estate", "none", 5, 9999),
             list(23, "(b) inventories fixed, opgaaf resampled", "none", "block", 5, 9999),
             list(24, "B = 4,999 (seed 20261012)", "estate", "block", 5, 4999))
for (r in runs) { M <- run_boot(I, O, r[[6]], 20261012, r[[3]], r[[4]], r[[5]]); s <- summ_boot(M, qQ)
  add(r[[1]], r[[2]], pt[qQ], s$lo, s$hi, s$undef_share) }
M2 <- readRDS(file.path(scr, "boot_primary.rds"))$M2; s <- summ_boot(M2, qQ)
add(24, "second seed 20261013 (B = 9,999)", pt[qQ], s$lo, s$hi, s$undef_share)

S <- do.call(rbind, res); write.csv(S, "P27_RW/modern/output/sensitivities.csv", row.names = FALSE)
print(S, digits = 4)
