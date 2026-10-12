# S5 (P08): Afrikaans gap estimated within SA-born recruits only (where it is identified), step by step
suppressMessages({library(tidyverse); library(sandwich); library(lmtest)})
source("./tools/paths.R")
av <- readRDS(dscratch("P08_SAC","compare","augmented_vars.rds"))
L  <- readRDS(dscratch("P08_SAC","compare","linked.rds"))
A <- av %>% filter(is.na(region_a) | region_a != ".", is.na(age_a) | age_a > 18, repeatlast_a == 0, regiondum_a %in% c(5, 9)) %>%
  filter(complete.cases(lwage_a, afr_a, age_a, height_a, weight_a, married_a, hisco_a, eyear_a)) %>%
  mutate(hisco = relevel(factor(hisco_a), "6"), reg = factor(regiondum_a), yr = factor(eyear_a))
fs <- list(s1 = lwage_a ~ afr_a, s2 = lwage_a ~ afr_a + age_a + height_a + weight_a + married_a,
  s3 = lwage_a ~ afr_a + age_a + height_a + weight_a + married_a + hisco + reg, s3y = lwage_a ~ afr_a + reg + yr,
  s4 = lwage_a ~ afr_a + age_a + height_a + weight_a + married_a + hisco + reg + yr)
out <- map_dfr(names(fs), function(k) { m <- lm(fs[[k]], A); c1 <- coeftest(m)["afr_a", ]; c2 <- coeftest(m, vcov. = vcovHC(m, "HC1"))["afr_a", ]
  tibble(spec = k, b = c1[1], t = c1[3], t_hc1 = c2[3], n = nobs(m)) })
print(out %>% mutate(across(where(is.numeric), ~ round(., 4))))
print(A %>% group_by(afr_a, eyear_a) %>% summarise(n = n(), mlw = mean(lwage_a), .groups = "drop") %>% pivot_wider(names_from = afr_a, values_from = c(n, mlw)) %>% as.data.frame())
write_csv(out, "./P08_SAC/compare/s5_checks/sa_only.csv")
