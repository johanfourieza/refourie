# 02_primary.R -- P27_RW S6 primary analysis (card section 4): full-sample point estimates, weight diagnostics,
# joint bootstrap B = 9,999 (seed 20261012) and the precision rerun (seed 20261013).
source("P27_RW/modern/00_common.R")
x <- readRDS(file.path(scr, "samples.rds"))
I <- x$I[, c("y", "s", "decade", "yr", "date")]; O <- x$O[, c("s", "yr", "key")]
B <- 9999
pt <- estim(I, O)

# diagnostics: class counts by source, block and row; weights; ESS; class means; 16+ share; concentration
ci <- cls4(I$s); co <- cls4(O$s); bi <- blk(I$yr, 4); bo <- blk(O$yr, 4); w <- pt[paste0("wk", 1:4)]; wi <- w[ci]
cc <- bind_rows(
  data.frame(source = "inventory", as.data.frame(table(block = bi, class = ci))),
  data.frame(source = "opgaaf", as.data.frame(table(block = bo, class = co))),
  data.frame(source = "inventory_row", as.data.frame(table(block = I$decade, class = ci))))
write.csv(cc, "P27_RW/modern/output/class_counts.csv", row.names = FALSE)
diag <- I |> mutate(cls = ci, w = wi) |> filter(decade <= 1800 | decade == 1806) |> group_by(decade) |>
  summarise(n = n(), ess = sum(w)^2 / sum(w^2), m = mean(y), mw = wmean(y, w),
            ybar_k1 = mean(y[cls == 1]), ybar_k2 = mean(y[cls == 2]), ybar_k3 = mean(y[cls == 3]), ybar_k4 = mean(y[cls == 4]),
            n_k4 = sum(cls == 4), share16_of_mw = sum((w * y)[cls == 4]) / sum(w * y),
            max_w = max(w), largest_class_share_of_sumw = max(tapply(w, cls, sum)) / sum(w), .groups = "drop")
write.csv(diag, "P27_RW/modern/output/row_diagnostics.csv", row.names = FALSE)
wt <- data.frame(class = c("0", "1-5", "6-15", "16+"),
                 P_inv = tb_share(ci, bi, 4, 4), P_opg = tb_share(co, bo, 4, 4), w = unname(w))
write.csv(wt, "P27_RW/modern/output/weights.csv", row.names = FALSE); print(wt); print(as.data.frame(diag))

# joint bootstrap
t0 <- Sys.time()
M1 <- run_boot(I, O, B, 20261012)
M2 <- run_boot(I, O, B, 20261013)
cat("bootstrap minutes:", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 2), "\n")
saveRDS(list(M1 = M1, M2 = M2), file.path(scr, "boot_primary.rds"))
qs <- c("m1700", "m1790", "mtot", "w1700", "w1790", "wtot", "mu_inv", "D90", "D90w", "R", "Delta", "pi_inv", "pi_opg", "mu_opg")
s1 <- summ_boot(M1, qs); s2 <- summ_boot(M2, qs)
prim <- data.frame(quantity = qs, estimate = unname(pt[qs]), lo = s1$lo, hi = s1$hi, undef_share = s1$undef_share,
                   lo_seed2 = s2$lo, hi_seed2 = s2$hi, undef_share_seed2 = s2$undef_share, B = B, level = LEV)
# why undefined: which block is empty in the drawn opgaaf
write.csv(prim, "P27_RW/modern/output/primary.csv", row.names = FALSE); print(prim)
# bootstrap sample-size of the opgaaf draws (years carry all their households)
set.seed(20261012); fo <- opg_sampler(O, "block", 5)
nn <- replicate(2000, { j <- fo(); c(n = length(j), emptyblocks = sum(tabulate(blk(O$yr[j], 4), 4) == 0)) })
print(summary(t(nn)))
write.csv(data.frame(stat = c("opg_draw_n_min", "opg_draw_n_med", "opg_draw_n_max", "share_draws_empty_block"),
                     value = c(min(nn[1, ]), median(nn[1, ]), max(nn[1, ]), mean(nn[2, ] > 0))),
          "P27_RW/modern/output/opg_draw_profile.csv", row.names = FALSE)
writeLines(capture.output(sessionInfo()), "P27_RW/modern/sessionInfo.txt")
