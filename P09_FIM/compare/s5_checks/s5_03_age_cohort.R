# P09_FIM S5 check 3 (Claude). Age-cohort confound: within one war, birth cohort = enlistment year - age,
# and the paper's models omit age. Aggregates only (cells with n >= 10).
suppressPackageStartupMessages({ library(tidyverse) })
root <- here::here()
source(file.path(root, "tools", "paths.R"))
out <- file.path(root, "P09_FIM", "compare", "s5_checks")
s <- readRDS(dscratch("P09_FIM", "repro_r", "analysis_sample.rds"))

ac <- s %>% filter(force %in% c("WWI", "WWII")) %>%
  group_by(force, cohort) %>%
  summarise(n = n(), mean_age = mean(age), min_age = min(age), max_age = max(age),
            mean_height = mean(height), .groups = "drop")
write_csv(ac %>% mutate(across(where(is.double), ~ round(.x, 2))), file.path(out, "s5_age_by_force_cohort.csv"))

ab <- s %>% filter(force %in% c("WWI", "WWII")) %>%
  mutate(ageband = cut(age, c(20, 22, 25, 30, 35, 40, 45, 49))) %>%
  group_by(force, ageband) %>% summarise(n = n(), mean_height = mean(height), .groups = "drop") %>%
  filter(n >= 10)
write_csv(ab %>% mutate(mean_height = round(mean_height, 2)), file.path(out, "s5_height_by_age_band.csv"))

# Pooled proxy with an age control: cohort + attest + age (identified only through cross-war overlap)
m1 <- lm(height ~ relevel(factor(cohort), "1885_1894") + I(year - 1900), data = s)
m2 <- update(m1, . ~ . + age + I(age^2))
tab <- bind_rows(broom::tidy(m1) %>% mutate(model = "ols_cohort_attest"),
                 broom::tidy(m2) %>% mutate(model = "ols_plus_age_quadratic")) %>%
  filter(str_detect(term, "cohort|age")) %>% mutate(across(where(is.double), ~ round(.x, 3)))
write_csv(tab, file.path(out, "s5_age_control_ols.csv"))
print(ac); print(ab, n = 30); print(tab, n = 30)
