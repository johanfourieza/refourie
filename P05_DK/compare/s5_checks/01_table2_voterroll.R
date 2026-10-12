# S5 check C3/C4: re-estimate Table 2 from the aggregate voter_roll_birth.dta (month-year counts; no personal rows).
# Tests which conception-month offset reproduces the published coefficients, and the denominator of the "25%".
suppressPackageStartupMessages({ library(haven); library(dplyr); library(sandwich) })
source(file.path("tools", "paths.R"))
d <- read_dta(dpath("P05_DK", "original", "Spanish_flu_group_folder", "spanishflu_ELIE", "voter_roll_birth.dta"))
cat("vars:", names(d), "\n"); print(dim(d))
d <- as.data.frame(d)
mcol <- intersect(c("monthbirth", "month", "mob"), names(d))[1]
cat("month var:", mcol, "\n")
d$mob <- as.integer(d[[mcol]]); d$yob <- as.integer(d$yearbirth)
cat(sprintf("mean all cells %.6f (n=%d); sum %d\n", mean(d$p), nrow(d), sum(d$p)))
s <- subset(d, yob >= 1915 & yob <= 1923)
cat(sprintf("mean 1915-23 %.4f (n=%d)\n", mean(s$p), nrow(s)))
pub <- c(Aug = 55.489, Sep = -253.102, Oct = -460.648, Nov = -140.057)
out <- list()
# birth month b = conception month c + k ; published labels Aug-Nov 1918 conception
for (k in 8:10) for (cm in 7:12) {
  bm <- cm + k; by <- 1918 + (bm - 1) %/% 12; bm <- (bm - 1) %% 12 + 1
  s$D <- as.integer(s$yob == by & s$mob == bm)
  m <- lm(p ~ D + factor(yob) + factor(mob), data = s)
  out[[length(out) + 1]] <- data.frame(offset = k, concep_month = cm, birth = sprintf("%d-%02d", by, bm),
    coef = coef(m)["D"], se_ols = sqrt(vcov(m)["D", "D"]), se_hc1 = sqrt(vcovHC(m, "HC1")["D", "D"]),
    se_hc2 = sqrt(vcovHC(m, "HC2")["D", "D"]), r2 = summary(m)$r.squared, n = nobs(m))
}
res <- do.call(rbind, out); rownames(res) <- NULL
print(res, digits = 6)
write.csv(res, file.path("P05_DK", "compare", "s5_checks", "01_table2_offsets.csv"), row.names = FALSE)

# Placebo: one-cell dummy for every birth month 1915-23. With year and month FE, a single-cell dummy has leverage 1
# (HC SEs undefined); its coefficient equals that cell's deviation from the additive FE fit. Rank the July 1919 cell.
pl <- sapply(seq_len(nrow(s)), function(i) { s$D <- as.integer(seq_len(nrow(s)) == i); coef(lm(p ~ D + factor(yob) + factor(mob), data = s))["D"] })
s$placebo <- pl
jul <- s$placebo[s$yob == 1919 & s$mob == 7]
cat(sprintf("July 1919 cell coef %.3f; rank (most negative) %d of %d; share of cells with |coef| >= |jul|: %.3f\n",
            jul, rank(s$placebo)[s$yob == 1919 & s$mob == 7], nrow(s), mean(abs(s$placebo) >= abs(jul))))
cat("five most negative cells:\n"); print(head(s[order(s$placebo), c("yob", "mob", "p", "placebo")], 5))
cat("five most positive cells:\n"); print(head(s[order(-s$placebo), c("yob", "mob", "p", "placebo")], 5))
cat(sprintf("25%% claim: 460.648/1787.016 = %.3f ; 460.648/%.3f (1915-23 mean) = %.3f\n", 460.648/1787.016, mean(s$p), 460.648/mean(s$p)))
# predicted July 1919 count without the dip
cat(sprintf("July 1919 observed %d; counterfactual = observed - coef = %.1f; dip as share of counterfactual %.3f\n",
            s$p[s$yob == 1919 & s$mob == 7], s$p[s$yob == 1919 & s$mob == 7] - jul, -jul / (s$p[s$yob == 1919 & s$mob == 7] - jul)))
write.csv(s[, c("yob", "mob", "placebo")], dscratch("P05_DK", "compare", "t2_placebo_cells.csv"), row.names = FALSE)
