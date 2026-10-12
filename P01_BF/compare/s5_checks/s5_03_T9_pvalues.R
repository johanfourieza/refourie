# P01_BF S5 check 3: which test gives the Table 9 p-values? (estimates = raw ABCC cell differences, see s5_02)
# Output: compare/s5_checks/s5_03_T9_pvalues.csv
suppressPackageStartupMessages({library(tidyverse); library(haven); library(here)})
proj <- here::here(); source(file.path(proj, "tools", "paths.R"))
d <- read_dta(dpath("P01_BF", "original", "Baten Fourie", "data.dta")) |> zap_labels() |> filter(age > 22, age < 83, !is.na(cyear))
pub9 <- tribble(~id, ~g, ~c0, ~c1, ~pub, ~pub_p,
  "T9_r1","in",1,2,-12.5,.286, "T9_r2","id",1,2,-18.3,.011, "T9_r3","eur",1,2,0.5,.925, "T9_r4","eur",2,3,1.4,.872,
  "T9_r5","ko",1,2,-43.9,.000, "T9_r6","ko",2,3,26.5,.000, "T9_r7","mz",2,3,35.5,.005, "T9_r8","za",2,3,9.5,.363,
  "T9_r9","otb",1,2,-14.8,.005, "T9_r10","otb",2,3,10.8,.172)
cv <- function(g, c) paste0(g, "_", c("early", "mid", "post")[c])
res <- pmap_dfr(pub9, function(id, g, c0, c1, pub, pub_p) {
  a <- d$exactage[d[[cv(g, c0)]] == 1]; b <- d$exactage[d[[cv(g, c1)]] == 1]
  tibble(id, est = 125 * (mean(b) - mean(a)), pub, pub_p,
         p_ttest_eq = t.test(b, a, var.equal = TRUE)$p.value, p_welch = t.test(b, a)$p.value,
         p_chi2 = suppressWarnings(prop.test(c(sum(b), sum(a)), c(length(b), length(a)), correct = FALSE)$p.value),
         p_chi2_yates = suppressWarnings(prop.test(c(sum(b), sum(a)), c(length(b), length(a)))$p.value),
         p_fisher = fisher.test(matrix(c(sum(b), length(b) - sum(b), sum(a), length(a) - sum(a)), 2))$p.value)
})
write_csv(res, file.path(proj, "P01_BF", "compare", "s5_checks", "s5_03_T9_pvalues.csv"))
print(res |> mutate(across(where(is.numeric), ~ round(., 3))))
