# 02_sensitivities.R -- P21_LFG S6 sensitivities (card §5 items 1-12, 15, 17). Reported, never verdict-setting.
# Items 13, 14 and 16 come from the primary draws in 01_primary.R.
source(here::here("P21_LFG", "modern", "00_common.R"))
library(parallel)
NW <- 6
band_verdict <- readRDS(file.path(SCR, "band_verdict_fn.rds"))
RULE <- c("0" = "not available", "1" = "supported nonpositive year", "2" = "all years supported positive",
  "3" = "positive points, not all supported", "4" = "some nonpositive point, not excluded")
Eb <- est_rows(prep_base(d0)); Ez <- est_rows(prep_zd(d0)); Eo <- est_rows(prep_ord(d0))

summ <- function(C, item, label, cls, n, drop = NULL) {
  ok <- !(YEARS %in% drop); G <- pooled(C, drop)
  tibble(item = item, label = label, class = cls, n_rows = n, F7 = G["F7"], F8 = G["F8"], F9 = G["F9"],
    negyrs_FS = sum(C[ok, "FS"] <= 0, na.rm = TRUE), negyrs_FK = sum(C[ok, "FK"] <= 0, na.rm = TRUE),
    negyrs_SK = sum(C[ok, "SK"] <= 0, na.rm = TRUE), not_computable = sum(is.na(C[ok, ])))
}
ann <- function(C, item) as_tibble(C) |> mutate(year = as.numeric(rownames(C)), item = item, .before = 1)
S <- list(); A <- list()
add <- function(C, item, label, cls, n, drop = NULL) {
  S[[item]] <<- summ(C, item, label, cls, n, drop); A[[item]] <<- ann(if (is.null(drop)) C else C[!(YEARS %in% drop), , drop = FALSE], item) }

C0 <- centres(Eb); add(C0, "0", "primary (annual, ln(1+x), median)", "primary", nrow(Eb))
## 5A
C1 <- centres(Ez, dummies = TRUE); add(C1, "1", "zero dummies (Battese), ln(max(x,1))", "5A", nrow(Ez))
allpos <- function(e) e$khoe > 0 & e$slaves > 0 & e$settlers > 0
C1p <- centres(Ez, dummies = TRUE, keep = allpos); add(C1p, "1b", "zero dummies; centres over all-positive-input rows", "5A", sum(allpos(Ez)))
C2 <- centres(Eb, window = 2); add(C2, "2", "five-year window regression (year dummies)", "5A", nrow(Eb))
C3 <- C0; for (i in seq_along(YEARS)) C3[i, ] <- colMeans(C0[abs(YEARS - YEARS[i]) <= 2, , drop = FALSE])
add(C3, "3", "five-year moving average of annual centres", "5A", nrow(Eb))
add(centres(Eb, stat = "tmean"), "4", "5%-trimmed mean of household HEC", "5A", nrow(Eb))
add(centres(Eb, stat = "mean"), "5", "untrimmed mean of household HEC (unstable where M_i M_j ~ 0)", "5A", nrow(Eb))
C7 <- centres(Ez, dummies = TRUE, window = 2); add(C7, "7", "joint: zero dummies + five-year window regression", "5A", nrow(Ez))
## 5B
add(C0, "8", "1828 excluded", "5B", sum(Eb$year != 1828), drop = 1828)
Eow <- filter(Eb, slaves > 0); add(centres(Eow), "9", "slave-owning households only", "5B", nrow(Eow))
add(centres(Eo), "10", "ordinary logs (file's l_ variables; zeros missing)", "5B", nrow(Eo))
# item 11: monotone evaluation points only, per pair (drop rows with M_i <= 0 or M_j <= 0)
C11 <- matrix(NA_real_, 22, 3, dimnames = list(YEARS, PAIRS))
for (i in seq_along(YEARS)) { e <- Eb[Eb$year == YEARS[i], ]; r <- hec_fit(e, rep(TRUE, nrow(e)), full = TRUE); M <- r$M
  C11[i, ] <- c(cstat(r$H[M[, "Ms"] > 0 & M[, "Mf"] > 0, "FS"]), cstat(r$H[M[, "Mk"] > 0 & M[, "Mf"] > 0, "FK"]),
                cstat(r$H[M[, "Ms"] > 0 & M[, "Mk"] > 0, "SK"])) }
add(C11, "11", "monotone evaluation points only (M_i, M_j > 0)", "5B", nrow(Eb))
pp <- d0 |> filter(!is.na(index)) |> group_by(index) |> filter(any(year < 1814), any(year > 1814)) |> ungroup()
cat("pre/post-1814 linked rows (all years):", nrow(pp), "\n")
E12 <- est_rows(prep_base(pp)); add(centres(E12), "12", "households linked before and after 1814", "5B", nrow(E12))

## Item 6: cluster bootstrap, B = 199, on items 1 and 2 (same band and failure rule)
boot_band <- function(E, dummies, window, B, seed, item) {
  E$cl <- cluster_id(E); rbc <- split(seq_len(nrow(E)), E$cl); G <- length(rbc)
  set.seed(seed, kind = "L'Ecuyer-CMRG"); draws <- lapply(seq_len(B), function(b) sample.int(G, G, replace = TRUE))
  c0 <- centres(E, dummies = dummies, window = window)
  cl <- makeCluster(NW); clusterExport(cl, c("E", "rbc", "dummies", "window", "YEARS", "PAIRS", "hec_fit", "design", "cstat", "centres", "replicate_rows"), envir = environment())
  res <- parLapply(cl, draws, function(dr) c(centres(E[replicate_rows(rbc, dr), , drop = FALSE], dummies = dummies, window = window)))
  stopCluster(cl); R <- do.call(rbind, res); Cs <- array(R, c(B, 22, 3))
  bind_rows(lapply(1:3, function(j) { bv <- band_verdict(c0[, j], Cs[, , j], Z_BAND, B)
    tibble(item = item, pair = PAIRS[j], B = B, V = bv$V, shown = bv$V >= 0.99 * B, n_supported_pos = sum(bv$L > 0),
      n_supported_nonpos = sum(bv$U <= 0), n_point_nonpos = sum(c0[, j] <= 0), pattern = RULE[as.character(bv$rule)],
      min_L = if (bv$V >= 0.99 * B) min(bv$L) else NA) })) }
t0 <- Sys.time()
I6 <- bind_rows(boot_band(Ez, TRUE, 0, 199, 20261012 + 61, "6a (item 1, zero dummies)"),
                boot_band(Eb, FALSE, 2, 199, 20261012 + 62, "6b (item 2, window regression)"))
## Item 15: S5 design, iid household resampling within years, B = 999
rby <- split(seq_len(nrow(Eb)), Eb$year)
set.seed(20261012 + 15, kind = "L'Ecuyer-CMRG")
dr15 <- lapply(1:999, function(b) unlist(lapply(rby, function(r) r[sample.int(length(r), length(r), replace = TRUE)]), use.names = FALSE))
cl <- makeCluster(NW); clusterExport(cl, c("Eb", "YEARS", "PAIRS", "hec_fit", "design", "cstat", "centres"))
R15 <- do.call(rbind, parLapply(cl, dr15, function(r) c(centres(Eb[r, , drop = FALSE])))); stopCluster(cl)
Cs15 <- array(R15, c(999, 22, 3))
I15 <- bind_rows(lapply(1:3, function(j) { bv <- band_verdict(C0[, j], Cs15[, , j], Z_BAND, 999)
  tibble(item = "15 (iid within year)", pair = PAIRS[j], B = 999, V = bv$V, shown = bv$V >= 990, n_supported_pos = sum(bv$L > 0),
    n_supported_nonpos = sum(bv$U <= 0), n_point_nonpos = sum(C0[, j] <= 0), pattern = RULE[as.character(bv$rule)], min_L = min(bv$L)) }))
I15y <- bind_rows(lapply(1:3, function(j) tibble(pair = PAIRS[j], year = YEARS, se_iid = apply(Cs15[, , j], 2, sd, na.rm = TRUE))))
cat("item 6 + 15 minutes:", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 2), "\n")

## Item 17: per-year HC1 Wald test of the six second-order coefficients (exploratory, unadjusted)
I17 <- bind_rows(lapply(YEARS, function(t) { e <- Eb[Eb$year == t, ]; r <- hec_fit(e, rep(TRUE, nrow(e)), full = TRUE)
  X <- r$X; u <- r$y - X %*% r$b; n <- nrow(X); k <- ncol(X); XtXi <- solve(crossprod(X))
  V <- XtXi %*% crossprod(X * as.vector(u)) %*% XtXi * n / (n - k); idx <- 5:10
  W <- as.numeric(t(r$b[idx]) %*% solve(V[idx, idx]) %*% r$b[idx])
  tibble(year = t, n = n, W = W, p = pchisq(W, 6, lower.tail = FALSE)) }))
cat("Item 17: years rejecting Cobb-Douglas (in 1+x) at 5%, unadjusted:", sum(I17$p < .05), "of 22\n")

SS <- bind_rows(S); boots <- bind_rows(I6, I15)
write_csv(SS, file.path(OUT, "sensitivities.csv")); write_csv(bind_rows(A), file.path(OUT, "sensitivities_annual.csv"))
write_csv(boots, file.path(OUT, "sens_bootstrap_items6_15.csv")); write_csv(I15y, file.path(OUT, "item15_se_by_year.csv"))
write_csv(I17, file.path(OUT, "item17_cd_wald.csv"))
print(as.data.frame(SS |> select(-class)), digits = 3); print(as.data.frame(boots), digits = 3)
