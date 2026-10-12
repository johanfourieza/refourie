# P03_BoF17 S6 01: primary analysis for H1-H3 (annual trend correlations) and K1-K2 (Kimberley short-run), card §4
source(here::here("P03_BoF17", "modern", "00_common.R"))

## ---- H1, H2: in-sheet trends, split 1871/1872, l = 8 ----
tr <- read_trends(); stopifnot(nrow(tr) == 78, all(diff(tr$year) == 1))
pre <- subset(tr, year <= 1871); post <- subset(tr, year >= 1872)
r_pre <- cor(pre$sa, pre$uk); r_post <- cor(post$sa, post$uk)
chk_H <- c(pre = round(r_pre, 4) == 0.0530, post = round(r_post, 4) == 0.8581)
cat(sprintf("Reproduction check H: r_pre = %.6f (n=%d), r_post = %.6f (n=%d): %s\n", r_pre, nrow(pre), r_post, nrow(post), all(chk_H)))
bs_pre <- mbb(pre$sa, pre$uk, 8); bs_post <- mbb(post$sa, post$uk, 8)
saveRDS(list(pre = bs_pre, post = bs_post), file.path(scr, "bs_H.rds"))

row <- function(claim, r, N, nc, l, bs, chk) data.frame(claim, r, N, n_complete = nc, block = l, B = length(bs),
  fail_rate = mean(is.na(bs)), L99 = q7(bs, .005), U99 = q7(bs, .995), L95 = q7(bs, .025), U95 = q7(bs, .975), repro_ok = chk)
prim <- rbind(row("H1", r_pre, 36, 36, 8, bs_pre, chk_H[["pre"]]), row("H2", r_post, 42, 42, 8, bs_post, chk_H[["post"]]))

## ---- H3: MOVER with rho = -1 (L = l1 - u2, U = u1 - l2), component bounds at 0.0025 / 0.0125 one-sided ----
l1 <- q7(bs_post, .0025); u1 <- q7(bs_post, .9975); l2 <- q7(bs_pre, .0025); u2 <- q7(bs_pre, .9975)
l1b <- q7(bs_post, .0125); u1b <- q7(bs_post, .9875); l2b <- q7(bs_pre, .0125); u2b <- q7(bs_pre, .9875)
prim <- rbind(prim, data.frame(claim = "H3", r = r_post - r_pre, N = 78, n_complete = 78, block = 8, B = B,
  fail_rate = max(mean(is.na(bs_pre)), mean(is.na(bs_post))), L99 = l1 - u2, U99 = u1 - l2, L95 = l1b - u2b, U95 = u1b - l2b, repro_ok = all(chk_H)))

## ---- K1, K2: consecutive-month log differences, 120-month grid, l = 12, >= 10 pairs ----
for (k in list(c("K1", "Wheat", 0.3774, 78), c("K2", "Mealies", 0.0508, 76))) {
  y <- dl(lp("Kimberley", k[2])); x <- dl(lp("Cape Town", k[2])); na <- !(is.finite(x) & is.finite(y)); x[na] <- NA; y[na] <- NA
  r <- cor(x, y, use = "complete.obs"); n <- sum(!na); ok <- round(r, 4) == as.numeric(k[3]) && n == as.numeric(k[4])
  cat(sprintf("Reproduction check %s: r = %.6f, n = %d: %s\n", k[1], r, n, ok))
  bs <- mbb(x, y, 12, minpairs = 10); saveRDS(bs, file.path(scr, paste0("bs_", k[1], ".rds")))
  prim <- rbind(prim, row(k[1], r, 120, n, 12, bs, ok))
}
print(prim, digits = 4)
write.csv(prim, file.path(odir, "primary_corr.csv"), row.names = FALSE)
