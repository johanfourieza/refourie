# S5 check 2: refit Table 6 Panel A on the authors' stored estimation samples (_est_tobit1 = 570, _est_tobitin = 178)
suppressMessages({library(haven); library(dplyr); library(readr); library(AER)})
source(here::here("tools", "paths.R"))
a <- zap_labels(read_dta(dpath("P13_FS", "original", "MOOC 8", "DATA20141122.dta")))
cl <- read_csv(here::here("P13_FS", "claims", "claims.csv"), col_types = cols(.default = "c"), show_col_types = FALSE)
pub <- setNames(as.numeric(cl$reported_value), cl$claim_id)
a$male <- as.numeric(a$gender == "m"); a$dec <- factor(floor(a$year / 10) * 10)
# aggregate definitional checks
cat("ldebt==log(debt_value) where debt>0:", isTRUE(all.equal(a$ldebt[a$debt_value > 0 & !is.na(a$ldebt)], log(a$debt_value[a$debt_value > 0 & !is.na(a$ldebt)]))), "\n")
cat("ldebtin==log(debt_infl):", isTRUE(all.equal(a$ldebtin[!is.na(a$ldebtin)], log(a$debt_infl[!is.na(a$ldebtin)]))), "\n")
cat("summary debt_value vs total_debt1 vs debtvalue vs fi_debt: mean", sapply(a[, c("debt_value","total_debt1","debtvalue","fi_debt")], mean, na.rm=TRUE), "\n")
cat("min debt in tobit1 sample:", min(a$debt_value[a$`_est_tobit1` == 1]), " n with ldebt<0:", sum(a$ldebt[a$`_est_tobit1` == 1] < 0), "\n")
xs <- "age + male + married + children + farmer + num_slaves + num_prop + cash1 + bond + both + comp + church + wees + dec"
key <- c(slaves = "num_slaves", props = "num_prop", cash = "cash1", bonds = "bond", farmer = "farmer", age = "age", children = "children", oc = "wees")
res <- list()
for (per in c("nom", "real")) {
  mk <- if (per == "nom") "_est_tobit1" else "_est_tobitin"; y <- if (per == "nom") "ldebt" else "ldebtin"
  d <- a[a[[mk]] == 1, ]; d <- droplevels(d)
  f <- as.formula(paste(y, "~", xs))
  mt <- tobit(f, left = 0, data = d); mo <- lm(f, data = d)
  cat("\n", per, "N =", nrow(d), " tobit logLik", logLik(mt), " censored obs:", sum(d[[y]] <= 0), "\n")
  for (k in names(key)) {
    id <- paste0("T6A_", k, "_", per, "_coef")
    ct <- coef(summary(mt))
    res[[length(res) + 1]] <- tibble(scenario = paste0("marked_sample_tobit_", y), claim_id = id, published = pub[id],
      scenario_value = ct[key[[k]], 1], t = ct[key[[k]], 3], t_pub = pub[sub("_coef", "_t", id)], ols = coef(mo)[key[[k]]])
  }
}
r <- bind_rows(res); print(as.data.frame(r), digits = 4)
saveRDS(r, file.path(dscratch("P13_FS", "compare"), "s5_02.rds"))
