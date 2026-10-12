# 03: Virginia design-based bootstrap (card §4.3). Rao-Wu rescaling, strata = county x census year,
# m_h = n_h - 1 draws with replacement, FPC f = 0.20, B = 9,999, seed 20261011 (L'Ecuyer-CMRG; one
# stream per replicate, so results do not depend on the number of workers). Coverage map fixed; resampling
# over all sampled Virginia households in covered cells; farmers/weights/statistics recomputed per replicate.
source("P06_FGa/modern/00_helpers.R")
library(parallel)
fg <- load_raw(); cmap <- coverage_map(fg); P <- load_prices()
d <- make_d(fg, cmap, P)
va <- d[d$District == "Virginia" & d$cov_slaves, c("County", "Year", "Bench", "Cattle", "Slaves", "farm")]
va$stratum <- paste(va$County, va$Year)

# Singleton strata (frozen rule): collapse with the next county (ascending id) in the same census year,
# or the previous one if last; repeat until n_h >= 2; drop a census year with a single covered household.
collapse_log <- character(0)
repeat {
  nh <- table(va$stratum); single <- names(nh)[nh < 2]
  if (!length(single)) break
  s <- single[1]; yr <- va$Year[va$stratum == s][1]
  cand <- sort(unique(va$stratum[va$Year == yr]))
  if (length(cand) == 1) { collapse_log <- c(collapse_log, paste("dropped year", yr)); va <- va[va$Year != yr, ]; next }
  j <- match(s, cand); tgt <- if (j < length(cand)) cand[j + 1] else cand[j - 1]
  collapse_log <- c(collapse_log, paste(s, "->", tgt)); va$stratum[va$stratum == s] <- tgt
}
cat("Strata:", length(unique(va$stratum)), "| collapses:", if (length(collapse_log)) collapse_log else "none", "\n")
writeLines(c(paste("strata:", length(unique(va$stratum))), paste("households resampled:", nrow(va)),
             paste("covered farmers:", sum(va$farm)), paste("collapses:", if (length(collapse_log)) collapse_log else "none")),
           file.path(OUT, "va_bootstrap_design.txt"))

va$h <- as.integer(factor(va$stratum)); w0 <- rep(VA_W, nrow(va))
vf <- va[va$farm, ]; fi <- which(va$farm)
point <- va_stats(vf, w0[fi])

seeds <- make_streams(B_BOOT, SEED)
one <- function(b) {
  assign(".Random.seed", seeds[[b]], envir = globalenv())
  w <- raowu_weights(va$h, w0)
  va_stats(vf, w[fi])
}
t0 <- Sys.time()
cl <- makeCluster(min(16, detectCores() - 2))
clusterExport(cl, c("va", "vf", "fi", "w0", "seeds", "one"))
invisible(clusterCall(cl, function(root) { setwd(root); source("P06_FGa/modern/00_helpers.R"); NULL }, normalizePath(".")))
reps <- parLapply(cl, seq_len(B_BOOT), one)
stopCluster(cl)
R <- do.call(rbind, reps)
cat("Runtime:", format(Sys.time() - t0), "\n")
saveRDS(list(point = point, reps = R, collapse = collapse_log), SCR("va_boot.rds"))
nf <- colSums(!is.finite(R[, c("VA_cat", "VA_w", "G4_VA", "G4own_VA")]))
cat("Non-finite replicates:", nf, "\n")
print(round(point, 4))
