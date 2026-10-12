# S5 checks P02_BoF10: (A) authors' MF22 series -> T4/T5; (B) filter match; (C) null size of bounds F on CF-filtered series; (D) T2a data variants
suppressPackageStartupMessages({library(tidyverse); library(readxl); library(mFilter); library(here); library(zoo)})
source(here("tools","paths.R")); set.seed(20261012)
b <- dpath("P02_BoF10","original","Boshoff Fourie Ships","Business Cycle Cape Colony")
uecm <- function(Y, X, p = 4) { ok <- !is.na(Y) & !is.na(X); r <- range(which(ok)); Y <- Y[r[1]:r[2]]; X <- X[r[1]:r[2]]
  n <- length(Y); k <- p - 1; dY <- diff(Y); dX <- diff(X); idx <- (k + 1):(n - 1)
  df <- data.frame(dy = dY[idx], ylag = Y[idx], xlag = X[idx], dx0 = dX[idx])
  for (i in seq_len(k)) { df[[paste0("dyl", i)]] <- dY[idx - i]; df[[paste0("dxl", i)]] <- dX[idx - i] }
  m1 <- lm(dy ~ ., df); m0 <- lm(dy ~ . - ylag - xlag, df); b <- coef(m1); V <- vcov(m1)[c("ylag","xlag"), c("ylag","xlag")]
  g <- c(b["xlag"]/b["ylag"]^2, -1/b["ylag"])
  c(F = anova(m0, m1)$F[2], theta = unname(-b["xlag"]/b["ylag"]), se = sqrt(drop(t(g) %*% V %*% g)), n = nrow(df)) }
# (A) authors' MF22 series
mf <- read_excel(file.path(b, "med frequency fluctuations.xls"), 1) |> mutate(across(everything(), as.numeric))
pairs <- tribble(~claim, ~dep, ~ind, ~pub,
 "T4_r3/T5 (ships->wheat)", "WHEATMF22", "SHIPSMF22", NA, "T4 (wheat->ships)", "SHIPSMF22", "WHEATMF22", NA,
 "T4_r9 ships->vines", "VINESMF22", "SHIPSMF22", 6.05, "T4_r10 vines->ships", "SHIPSMF22", "VINESMF22", 5.68,
 "T4_r11 ships->wine", "WINEMF22", "SHIPSMF22", 4.40, "T4_r12 wine->ships", "SHIPSMF22", "WINEMF22", 1.16,
 "T4_r13 ships->cattle", "CATTLEMF22", "SHIPSMF22", 0.54, "T4_r14 cattle->ships", "SHIPSMF22", "CATTLEMF22", 0.25,
 "tot vines", "TOTALVINESMF22", "SHIPSMF22", NA, "tot wine", "TOTALWINEMF22", "SHIPSMF22", NA)
pairs <- bind_rows(pairs, pairs |> mutate(claim = paste0(claim, " [shipdays]"), dep = sub("SHIPSMF22","SHIPDAYSMF22",dep), ind = sub("SHIPSMF22","SHIPDAYSMF22",ind), pub = NA))
A <- pairs |> rowwise() |> mutate(as_tibble(as.list(uecm(mf[[dep]], mf[[ind]])))) |> ungroup()
cat("\n(A) bounds F / theta on authors' MF22 series\n"); print(as.data.frame(A), digits = 3)
# (B) what filter produced SHIPSMF22? compare to CF variants on log ships
sh <- read_excel(file.path(b, "ships for eviews FROM 1652.xls"), 1, col_names = FALSE, skip = 1)[, 1:2] |> setNames(c("year","ships")) |> mutate(across(everything(), as.numeric)) |> filter(!is.na(year), ships > 0)
for (span in list(c(1701,1793), c(1652,1793))) { s <- sh |> filter(year >= span[1], year <= span[2]); x <- log(s$ships)
  v <- list(cf_I0 = cffilter(x, 12, 40, root = FALSE, drift = FALSE), cf_I1d = cffilter(x, 12, 40, root = TRUE, drift = TRUE),
            cf_I1 = cffilter(x, 12, 40, root = TRUE, drift = FALSE), cf_sym = cffilter(x, 12, 40, type = "symmetric", nfix = 12),
            bk = bkfilter(x, 12, 40, nfix = 12), cf_I0_2to40 = cffilter(x, 2, 40), cf_I0_12to20 = cffilter(x, 12, 20))
  tgt <- mf$SHIPSMF22[match(s$year, mf$OBS)]
  cat("\n(B) span", span, ": cor / sd ratio with SHIPSMF22\n")
  print(sapply(v, \(f) { y <- as.numeric(f$cycle); c(cor = cor(y, tgt, use = "c"), sdratio = sd(tgt, na.rm = T)/sd(y, na.rm = T)) }), digits = 3) }
# (C) size: independent random walks, CF 12-40, bounds F vs paper bounds 4.01 and rebuild sim 5.96
Fs <- replicate(1000, { e <- matrix(rnorm(2*93), ncol = 2); y <- cffilter(cumsum(e[,1]), 12, 40)$cycle; x <- cffilter(cumsum(e[,2]), 12, 40)$cycle; uecm(as.numeric(y), as.numeric(x))[c("F","theta")] })
cat("\n(C) null F on independent CF-filtered RWs: median", median(Fs[1,]), " P(F>4.01)", mean(Fs[1,] > 4.01), " P(F>61.77)", mean(Fs[1,] > 61.77), " P(F>24.77)", mean(Fs[1,] > 24.77), " q95", quantile(Fs[1,], .95), "\n")
cat("    null |theta| median", median(abs(Fs[2,])), " P(|theta|>2.18)", mean(abs(Fs[2,]) > 2.18), "\n")
write_csv(tibble(F = Fs[1,], theta = Fs[2,]), dscratch("P02_BoF10","compare","null_sim.csv"))
write_csv(A, here("P02_BoF10","compare","s5_checks","mf22_bounds.csv"))
saveRDS(list(cq = quantile(Fs[1,], c(.5,.95,.99))), dscratch("P02_BoF10","compare","null_q.rds"))

# (D) lag-order sensitivity on authors' series (ships->wheat) and T2a unsmoothed: ships vs shipdays, logs vs levels
cat("
(D1) MF22 ships->wheat F by p:", sapply(1:6, \(p) round(uecm(mf$WHEATMF22, mf$SHIPSMF22, p)["F"], 1)), "
")
d <- read_csv(dscratch("P02_BoF10","repro_r","series.csv"), show_col_types = FALSE)
pub2a <- c(0.73,1.17,1.18,1.03,0.29,1.88,0.40,1.70,2.76,0.42); vv <- c("wheat_sown","wheat_reaped","vines","wine","cattle")
for (sv in c("ships","shipdays")) for (tr in c("log","level")) { f <- if (tr == "log") log else identity
  F2 <- unlist(lapply(vv, \(v) c(uecm(f(d[[v]]), f(d[[sv]]))["F"], uecm(f(d[[sv]]), f(d[[v]]))["F"])))
  cat("(D2)", sv, tr, ": F =", round(F2, 2), " | cor with published", round(cor(F2, pub2a), 2), " #signif(>4.01)", sum(F2 > 4.01), "
") }
