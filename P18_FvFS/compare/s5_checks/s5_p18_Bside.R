# S5: reverse check. Apply the original's conventions (aw = household size; inputs per household member)
# to the S3 recreation's own data (repro_r/data/farmers.rds), to isolate the residual coding/sample gap.
suppressPackageStartupMessages({library(fixest); library(dplyr)})
root <- "./P18_FvFS"; source("./tools/paths.R")
s <- readRDS(dpath("P18_FvFS", "repro_r/data/farmers.rds"))
yrs <- c(1700, 1702, 1705, 1709, 1712, 1719, 1723, 1731, 1738, 1741, 1752, 1757, 1762, 1773)
s <- s |> filter(jaar %in% yrs) |> mutate(den = ifelse(hhsize > 0, hhsize, 1), lw = log(wine_pc + 0.001),
  kn_pc = knechts / den, ca_pc = cattle / den, ho_pc = horses / den, vi_pc = vines / den, wh_pc = wheat / den,
  yr = factor(jaar), dist = factor(ds))
F <- "born_abroad + i(dist, ref = 1) + i(yr)"
X_h <- "slaves + knechts + cattle + horses + vines + mar_nw + mar_w"
X_p <- "slaves + kn_pc + ca_pc + ho_pc + vi_pc + mar_nw + mar_w"
run <- function(lab, X, wt, wheatv) {
  a <- feols(as.formula(paste("lw ~ nwh + wh +", X, "+", wheatv, "+", F)), s, weights = if (wt) ~den else NULL, vcov = "hetero")
  b <- feols(as.formula(paste("lw ~ wh +", X, "+", F)), s |> filter(hug == 1), weights = if (wt) ~den else NULL, vcov = "hetero")
  c <- feols(lw ~ wh, s |> filter(hug == 1, born_abroad == 1), weights = if (wt) ~den else NULL, vcov = "hetero")
  data.frame(variant = lab, T3c4 = round(coef(a)["wh"], 3), T4c7 = round(coef(b)["wh"], 3), T4c10 = round(coef(c)["wh"], 3), N = nobs(a), N_hug = nobs(b), N_ba = nobs(c))
}
r <- rbind(run("B as run (unweighted, household inputs)", X_h, FALSE, "wheat"),
           run("B + aw=hhsize", X_h, TRUE, "wheat"),
           run("B + per-member inputs", X_p, FALSE, "wh_pc"),
           run("B + aw=hhsize + per-member inputs (original conventions)", X_p, TRUE, "wh_pc"))
print(r, row.names = FALSE)
write.csv(r, file.path(root, "compare/s5_checks/s5_p18_Bside.csv"), row.names = FALSE)
