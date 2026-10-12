# P12 S5 check 3: support of the reference person and wild cluster bootstrap (LPM analogue). Aggregates only.
suppressMessages({library(dplyr); library(fixest); library(readr); library(fwildclusterboot)})
source("tools/paths.R"); set.seed(12); dqrng::dqset.seed(12)
d <- readRDS(dpath("P12_FJ", "repro_r", "_scratch", "analysis.rds")); d$Pandemic <- d$pandemic
ages <- c("Age_0_4","Age_5_9","Age_10_14","Age_15_19","Age_20_24","Age_35_49","Age_50_69","Age_70")
occ <- c("Professionals_and_managers","Sales_and_service","Production","Children_and_Pensioners")
x3 <- c(ages, "Male", occ, "Signature", "Africa","Asia","Europe","South_Africa","Death_in_Family","Nurse","Railway","Farm","Street_road_and_stad")
d$Male <- d$male; d$Signature <- d$signature; d$Coloured <- as.integer(d$race == "Coloured"); d$Black <- as.integer(d$race == "Black")
for (v in c("Coloured","Black", x3)) d[[paste0("P_", v)]] <- d$Pandemic * d[[v]]
d3 <- d[complete.cases(d[, c("doc","race", x3)]), ]
farm <- rowSums(d3[, occ]) == 0; a2534 <- rowSums(d3[, ages]) == 0
sup <- d3 %>% mutate(farm = farm, a2534 = a2534) %>% group_by(race, Pandemic) %>%
  summarise(n = n(), farming = sum(farm), farming_female = sum(farm & Male == 0), farming_female_2534 = sum(farm & Male == 0 & a2534),
            ref_cell = sum(farm & Male == 0 & a2534 & Signature == 0), .groups = "drop")
write_csv(sup, "P12_FJ/compare/s5_checks/03_refcell_support.csv")
rhs <- paste(c("Coloured","Black","Pandemic","P_Coloured","P_Black", x3, paste0("P_", x3)), collapse = " + ")
d3$town <- factor(d3$town); l3 <- lm(as.formula(paste("doc ~", rhs, "+ town")), d3); V <- sandwich::vcovCL(l3, cluster = ~town, type = "HC1")
w <- bind_rows(lapply(c("P_Coloured","P_Black","P_Street_road_and_stad"), function(h) { b <- boottest(l3, param = h, clustid = "town", B = 9999, type = "webb")
  tibble(term = h, lpm_est = unname(coef(l3)[h]), p_cluster = 2 * pt(-abs(coef(l3)[h] / sqrt(V[h, h])), 10), p_wcb_webb = b$p_val) }))
print(w); write_csv(w, "P12_FJ/compare/s5_checks/03_wcb_lpm.csv")
