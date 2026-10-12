# S5 (P08): pair-B decomposition of the England (vs Boer republics) spec-4 coefficient
suppressMessages({library(tidyverse)})
source("./tools/paths.R")
L <- readRDS(dscratch("P08_SAC","compare","linked.rds"))
Lk <- L %>% filter(!is.na(a_row)) %>% mutate(
  sA = (is.na(region_a) | region_a != ".") & (is.na(age_a) | age_a > 18) & repeatlast_a == 0,
  sB = term_no == 1 & !is.na(enl_year) & enl_year <= 1907,
  regB = recode(region, "Boer republics"="5","England"="1","Americas"="2","Asia"="3","Australasia"="4","Europe"="6","Ireland"="7","Scotland"="8","Southern Africa"="9","Wales"="10"),
  regA = as.character(regiondum_a), lwage_B = log(wage), hisco_B = hisco_major, yrB = enl_year)
A_v <- c("lwage_a","afr_a","age_a","height_a","weight_a","married_a","hisco_a","regA","eyear_a")
B_v <- c("lwage_B","afrikaans","age","height_cm","weight_kg","married","hisco_B","regB","yrB")
fit <- function(d, v) { dd <- tibble(y=d[[v[1]]], afr=d[[v[2]]], age=d[[v[3]]], ht=d[[v[4]]], wt=d[[v[5]]], mar=d[[v[6]]],
  hi=relevel(factor(d[[v[7]]]),"6"), rg=relevel(factor(d[[v[8]]]),"5"), yr=factor(d[[v[9]]])); coef(lm(y ~ afr+age+ht+wt+mar+hi+rg+yr, dd))[c("afr","rg1")] }
dA <- filter(Lk, sA); dB <- filter(Lk, sB)
sw <- function(k) { v <- A_v; v[k] <- B_v[k]; fit(dA, v) }
R <- rbind(authors = fit(dA, A_v), B_all = fit(dB, B_v), swap_afr = sw(2), swap_region = sw(8), swap_hisco = sw(7), swap_afr_region = sw(c(2, 8)),
           swap_afr_region_hisco = sw(c(2, 7, 8)), swap_age = sw(3), swap_weight = sw(5))
print(round(R, 4))
