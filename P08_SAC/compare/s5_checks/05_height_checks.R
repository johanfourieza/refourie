# S5 (P08): height comparisons by region under alternative samples (aggregate output only)
suppressMessages({library(tidyverse); library(haven)})
PROJ <- "."
source(file.path(PROJ, "tools", "paths.R"))
av <- readRDS(dscratch("P08_SAC","compare","augmented_vars.rds"))
L  <- readRDS(dscratch("P08_SAC","compare","linked.rds"))
d <- av %>% filter(repeatlast_a == 0, !is.na(height_a)) %>% mutate(reg = regiondum_a)
lab <- c(`1`="England",`2`="Americas",`3`="Asia",`4`="Australasia",`5`="Boer republics",`6`="Europe",`7`="Ireland",`8`="Scotland",`9`="Southern Africa",`10`="Wales")
cmp <- function(dd, scen) {
  m <- dd %>% filter(!is.na(reg)) %>% group_by(reg) %>% summarise(n = n(), mean = mean(height_a), age = mean(age_a, na.rm = TRUE), .groups = "drop") %>% mutate(region = lab[as.character(reg)])
  tt <- function(g1, g2) { x <- dd$height_a[dd$reg %in% g1]; y <- dd$height_a[dd$reg %in% g2]; r <- t.test(x, y); c(diff = unname(diff(rev(r$estimate))), lo = r$conf.int[1], hi = r$conf.int[2], p = r$p.value) }
  # diff = mean(g1) - mean(g2)
  t1 <- tt(9, 1); t2 <- tt(c(5, 9), c(1, 8, 10)); t3 <- tt(5, 1)
  tibble(scenario = scen, n_total = nrow(dd),
         eng = m$mean[m$reg == 1], sa = m$mean[m$reg == 9], boer = m$mean[m$reg == 5], n_sa = m$n[m$reg == 9],
         age_eng = m$age[m$reg == 1], age_sa = m$age[m$reg == 9], age_boer = m$age[m$reg == 5],
         d_SA_Eng = t1["diff"], lo1 = t1["lo"], hi1 = t1["hi"], p1 = t1["p"],
         d_SAall_GB = t2["diff"], lo2 = t2["lo"], hi2 = t2["hi"], p2 = t2["p"], d_Boer_Eng = t3["diff"], p3 = t3["p"]) }
R <- bind_rows(
  cmp(d, "Table 1 sample: first terms, all ages"),
  cmp(d %>% filter(!is.na(age_a), age_a >= 20, age_a <= 50), "stated age 20-50 (missing dropped)"),
  cmp(d %>% filter(is.na(age_a) | (age_a >= 20 & age_a <= 50)), "age 20-50, missing kept"),
  cmp(d %>% filter(!is.na(age_a), age_a >= 23), "stated age >=23 (adult stature)"),
  cmp(d %>% filter(!is.na(age_a), age_a < 20), "stated age <20"))
print(R %>% mutate(across(where(is.numeric), ~ round(., 3))) %>% as.data.frame())
# age-adjusted: height ~ region + age FE (ages 16..30 single years, 31+ pooled)
dd <- d %>% filter(!is.na(age_a)) %>% mutate(ageg = factor(pmin(round(age_a), 31)), r = relevel(factor(reg), "1"))
m <- lm(height_a ~ r + ageg, dd); ct <- summary(m)$coefficients
print(round(ct[c("r9", "r5", "r8", "r10", "r2", "r4"), ], 3))
# Dutch- vs English-surname SA-born, authors' flag, Table-1 sample
s <- d %>% filter(reg %in% c(5, 9), !is.na(afr_a)); tt <- t.test(height_a ~ afr_a, s)
cat("Dutch(afr=1) vs English SA-born, authors' flag: means", round(tt$estimate, 2), " n", table(s$afr_a), " p", round(tt$p.value, 3), "\n")
s2 <- s %>% filter(!is.na(age_a), age_a >= 20, age_a <= 50); tt2 <- t.test(height_a ~ afr_a, s2)
cat("  age 20-50: means", round(tt2$estimate, 2), " n", table(s2$afr_a), " p", round(tt2$p.value, 3), "\n")
# Born outside British Isles (bar Ireland) vs England+Scotland+Wales
x <- d$height_a[d$reg %in% c(2, 3, 4, 5, 6, 9)]; y <- d$height_a[d$reg %in% c(1, 8, 10)]
r <- t.test(x, y); cat("non-British (excl. Ireland) vs GB: diff", round(diff(rev(r$estimate)), 2), " CI", round(r$conf.int, 2), "\n")
# minimum-height truncation: share of first-term heights in 1-cm bins near lower tail
cat("height p1/p5/p10:", quantile(d$height_a, c(.01, .05, .1)), "; share <167.6cm (5ft6):", round(mean(d$height_a < 167.6), 3), "\n")
write_csv(R, file.path(PROJ, "P08_SAC/compare/s5_checks/height_checks.csv"))
