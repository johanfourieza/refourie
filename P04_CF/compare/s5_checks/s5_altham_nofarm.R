# S5 C8: Altham statistics excluding farmers (3x3), do-file algorithm with r = s = 3, on the 2016 analysis file
suppressMessages({library(haven); library(dplyr)})
source(file.path(normalizePath(".."), "tools", "paths.R"))  # [A6] data root on D:
dir.create(dpath("P04_CF", "compare", "_scratch_s5"), recursive = TRUE, showWarnings = FALSE)
a <- read_dta(dpath("P04_CF", "original", "CF Mobility", "Data", "CF_mobility_replication_data_anonymized.dta")) |> zap_labels()
d <- a |> filter(f_occ_group_last != 2, occ_group_last != 2)
lv <- c(1,3,4)
tb <- function(k) matrix(as.numeric(table(factor(d$f_occ_group_last[d$psplit==k], lv), factor(d$occ_group_last[d$psplit==k], lv))), 3, 3)
P <- tb(1); Q <- tb(2)
F <- factor(rep(1:3, 3)); S <- factor(rep(1:3, each=3)); rs <- 4*3*3
dd <- function(y) sqrt(sum(resid(lm(y ~ F + S))^2) * rs)
T <- factor(rep(1:2, each=9)); m <- glm(c(P,Q) ~ (factor(rep(F,2)) + factor(rep(S,2)) + T)^2, family=poisson)
gi <- function(X) glm(as.vector(X) ~ F + S, family=poisson)$deviance
cat(sprintf("d(P,I)=%.2f (p=%.4g)  d(Q,I)=%.2f (p=%.4g)  d(P,Q)=%.2f (G2=%.2f, df=%d, p=%.4f)   published 13.92*** 10.57*** 2.37*\n",
  dd(log(as.vector(P))), 1-pchisq(gi(P),4), dd(log(as.vector(Q))), 1-pchisq(gi(Q),4), dd(log(as.vector(P)/as.vector(Q))), m$deviance, m$df.residual, 1-pchisq(m$deviance, m$df.residual)))
# variants: drop farmer fathers only (3x4) / farmer sons only (4x3); also do-file r=s=4 constant left unchanged with 3x3
gen <- function(dat, rl, cl, rsK) {
  tb <- function(k) matrix(as.numeric(table(factor(dat$f_occ_group_last[dat$psplit==k], rl), factor(dat$occ_group_last[dat$psplit==k], cl))), length(rl))
  P <- tb(1); Q <- tb(2); F <- factor(row(P)); S <- factor(col(P))
  dd <- function(y) sqrt(sum(resid(lm(as.vector(y) ~ as.vector(F) + as.vector(S)))^2) * rsK)
  F <- factor(as.vector(row(P))); S <- factor(as.vector(col(P)))
  dd <- function(y) sqrt(sum(resid(lm(as.vector(y) ~ F + S))^2) * rsK)
  c(dPI=dd(log(P)), dQI=dd(log(Q)), dPQ=dd(log(P/Q)))
}
print(round(rbind(fathers_only=gen(a |> filter(f_occ_group_last!=2), c(1,3,4), 1:4, 4*3*4),
  sons_only=gen(a |> filter(occ_group_last!=2), 1:4, c(1,3,4), 4*4*3),
  both_rs16=gen(d, c(1,3,4), c(1,3,4), 4*4*4)), 2))
