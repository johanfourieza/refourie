# S5 (P08): Table 3 sensitivity checks and pair-B decomposition.
# Data: authors' Augmented sheet (via linked.rds / augmented_vars.rds on D: scratch). Output: aggregate CSV only.
suppressMessages({library(tidyverse); library(sandwich); library(lmtest)})
PROJ <- "."
source(file.path(PROJ, "tools", "paths.R"))
av <- readRDS(dscratch("P08_SAC","compare","augmented_vars.rds"))
L  <- readRDS(dscratch("P08_SAC","compare","linked.rds"))
OUT <- file.path(PROJ, "P08_SAC/compare/s5_checks")
res <- list()
add <- function(scen, m, term = "afrikaans", note = "") {
  ct <- coeftest(m); ch <- coeftest(m, vcov. = vcovHC(m, type = "HC1"))
  i <- which(rownames(ct) == term)
  res[[length(res) + 1]] <<- tibble(scenario = scen, term = term, b = ct[i, 1], t = ct[i, 3], t_hc1 = ch[i, 3], n = nobs(m), r2 = summary(m)$r.squared, note = note)
}
# Emulate Stata: drop if region=="." ; `age>18` is TRUE for missing age
A <- av %>% filter(is.na(region_a) | region_a != ".") %>%
  mutate(c18 = is.na(age_a) | age_a > 18, base = c18 & repeatlast_a == 0,
         hisco = relevel(factor(hisco_a), "6"), reg = relevel(factor(regiondum_a), "5"),
         reg_eng = relevel(factor(regiondum_a), "1"), yr = factor(eyear_a), cls = relevel(factor(class_a), "1"))
f2 <- lwage_a ~ afr_a + age_a + height_a + weight_a + married_a
f3 <- update(f2, . ~ . + hisco + reg); f4 <- update(f3, . ~ . + yr)
s1 <- A %>% filter(base, regiondum_a %in% c(5, 9))
m1 <- lm(lwage_a ~ afr_a, s1); add("S1 published spec1 (SA-born, age>18 incl. missing)", m1, "afr_a")
cat("spec1 N", nobs(m1), " missing age in spec1 sample:", sum(is.na(s1$age_a) & !is.na(s1$lwage_a) & !is.na(s1$afr_a)), "
")
s1b <- s1 %>% filter(!is.na(age_a))
add("S1 spec1, stated age >18 required", lm(lwage_a ~ afr_a, s1b), "afr_a")
add("S1 spec1, all regions", lm(lwage_a ~ afr_a, A %>% filter(base)), "afr_a")
add("S1 spec1, SA-born, spec-4 estimation sample", lm(lwage_a ~ afr_a, A %>% filter(base, regiondum_a %in% c(5, 9)) %>%
     filter(complete.cases(age_a, height_a, weight_a, married_a, hisco_a, eyear_a))), "afr_a")
m2 <- lm(f2, A %>% filter(base)); m3 <- lm(f3, A %>% filter(base)); m4 <- lm(f4, A %>% filter(base))
add("T3 spec2 published", m2, "afr_a"); add("T3 spec3 published", m3, "afr_a"); add("T3 spec4 published", m4, "afr_a")
add("T3 spec4 published", m4, "reg1"); add("T3 spec3 published", m3, "reg1")
# spec 4 within SA-born only (the comparison the text describes: Dutch vs English-speaking compatriots)
add("spec4 restricted to SA-born", lm(update(f4, . ~ . - reg + reg), A %>% filter(base, regiondum_a %in% c(5, 9))), "afr_a")
# Superseded 'Wage regression' spec 4: England ref, class dummies, no married, no hisco
mo <- lm(lwage_a ~ afr_a + age_a + height_a + weight_a + cls + reg_eng + yr, A %>% filter(base))
add("Old sheet spec4 rebuilt (class dummies, England ref)", mo, "afr_a"); add("Old sheet spec4 rebuilt (class dummies, England ref)", mo, "reg_eng5")
# Farmer definition: class dummies instead of HISCO major; farmer dummy only
add("spec4 with class (farmer dummy ref) instead of HISCO", lm(update(f4, . ~ . - hisco + cls), A %>% filter(base)), "afr_a")
# Year coverage
add("spec4 dropping 1908-09", lm(f4, A %>% filter(base, eyear_a <= 1907)), "afr_a")
add("spec4 dropping 1907-09", lm(f4, A %>% filter(base, eyear_a <= 1906)), "afr_a")
# ---------------- pair-B decomposition on linked rows ----------------
Lk <- L %>% filter(!is.na(a_row)) %>% mutate(
  sA = (is.na(region_a) | region_a != ".") & (is.na(age_a) | age_a > 18) & repeatlast_a == 0,
  sB = term_no == 1 & !is.na(enl_year) & enl_year <= 1907,
  reg_B = recode(region, "Boer republics" = "5", "England" = "1", "Americas" = "2", "Asia" = "3", "Australasia" = "4", "Europe" = "6",
                 "Ireland" = "7", "Scotland" = "8", "Southern Africa" = "9", "Wales" = "10"))
fit <- function(d, wage, afr, age, ht, wt, mar, hi, rg, yr) {
  dd <- tibble(y = d[[wage]], afr = d[[afr]], age = d[[age]], ht = d[[ht]], wt = d[[wt]], mar = d[[mar]],
               hi = relevel(factor(d[[hi]]), "6"), rg = relevel(factor(d[[rg]]), "5"), yr = factor(d[[yr]]))
  lm(y ~ afr + age + ht + wt + mar + hi + rg + yr, dd) }
Lk <- Lk %>% mutate(lwage_B = log(wage), hisco_B = hisco_major, regB = reg_B, yrB = enl_year, regA = as.character(regiondum_a))
A_vars <- c("lwage_a","afr_a","age_a","height_a","weight_a","married_a","hisco_a","regA","eyear_a")
B_vars <- c("lwage_B","afrikaans","age","height_cm","weight_kg","married","hisco_B","regB","yrB")
nm <- c("wage","afrikaans","age","height","weight","married","hisco","region","year")
dA <- Lk %>% filter(sA); dB <- Lk %>% filter(sB)
base <- do.call(fit, c(list(dA), as.list(A_vars))); add("DEC0 authors' vars, authors' sample (linked rows)", base, "afr")
full <- do.call(fit, c(list(dB), as.list(B_vars))); add("DEC9 B vars, B sample (linked rows)", full, "afr")
add("DEC B sample, authors' vars", do.call(fit, c(list(dB), as.list(A_vars))), "afr")
add("DEC authors' sample, B vars", do.call(fit, c(list(dA), as.list(B_vars))), "afr")
for (k in seq_along(nm)) {  # one-at-a-time swap into authors' baseline
  v <- A_vars; v[k] <- B_vars[k]
  add(paste0("DEC1 swap ", nm[k], " to B (authors' sample)"), do.call(fit, c(list(dA), as.list(v))), "afr") }
for (k in seq_along(nm)) {  # one-at-a-time swap back to authors in the full-B setting
  v <- B_vars; v[k] <- A_vars[k]
  add(paste0("DEC2 restore ", nm[k], " to authors (B sample)"), do.call(fit, c(list(dB), as.list(v))), "afr") }
# spec-3 analogue (no year)
fit3 <- function(d, v) { dd <- tibble(y = d[[v[1]]], afr = d[[v[2]]], age = d[[v[3]]], ht = d[[v[4]]], wt = d[[v[5]]], mar = d[[v[6]]],
  hi = relevel(factor(d[[v[7]]]), "6"), rg = relevel(factor(d[[v[8]]]), "5")); lm(y ~ afr + age + ht + wt + mar + hi + rg, dd) }
add("DEC3-0 spec3 authors", fit3(dA, A_vars), "afr"); add("DEC3-9 spec3 B", fit3(Lk %>% filter(term_no == 1), B_vars), "afr")
for (k in c(2, 7, 8)) { v <- A_vars; v[k] <- B_vars[k]; add(paste0("DEC3 swap ", nm[k], " to B (spec3)"), fit3(dA, v), "afr") }
v <- A_vars; v[c(2, 7)] <- B_vars[c(2, 7)]; add("DEC1 swap afrikaans+hisco to B", do.call(fit, c(list(dA), as.list(v))), "afr")
v <- A_vars; v[c(2, 7, 8)] <- B_vars[c(2, 7, 8)]; add("DEC1 swap afrikaans+hisco+region to B", do.call(fit, c(list(dA), as.list(v))), "afr")
R <- bind_rows(res); print(R %>% mutate(across(where(is.numeric), ~ round(., 4))) %>% as.data.frame(), right = FALSE)
write_csv(R, file.path(OUT, "t3_checks.csv"))
# mismatch counts of afrikaans flag by region, linked first terms (aggregate)
print(with(Lk %>% filter(sA), table(afr_A = afr_a, afr_B = afrikaans, regA, useNA = "ifany"))[, , c("5", "9")])
