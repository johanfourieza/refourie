# S5 check 9: Table 6 Panel A best-match spec on stored samples; proper censored Tobit incl. zero-debt inventories
suppressMessages({library(haven); library(dplyr); library(AER); library(sandwich); library(lmtest)})
source(here::here("tools", "paths.R"))
a <- zap_labels(read_dta(dpath("P13_FS", "original", "MOOC 8", "DATA20141122.dta")))
a <- a[!is.na(a$household_iden), ]
a$male <- as.numeric(a$gender == "m"); a$dec <- factor(floor(suppressWarnings(as.numeric(a$year_string)) / 10) * 10)
a$y_nom <- ifelse(a$debt_value > 0, log(a$debt_value), 0)
xs <- "age + male + married + children + farmer + num_slaves + num_prop + cash1 + bond1 + both + comp + church + wees + dec"
fit <- function(d, y, lab) {
  m <- tobit(as.formula(paste(y, "~", xs)), left = 0, data = droplevels(d)); ct <- coef(summary(m))
  mo <- lm(as.formula(paste(y, "~", xs)), data = droplevels(d)); th <- coeftest(mo, vcov = vcovHC(mo, "HC1"))
  cat(sprintf("%-40s N %4d cens %4d | slaves %.4f t %.2f (OLS HC1 t %.2f) | bonds %.3f t %.2f | farmer %.3f t %.2f\n", lab, nobs(m), sum(d[[y]] <= 0, na.rm = TRUE),
      ct["num_slaves", 1], ct["num_slaves", 3], th["num_slaves", 3], ct["bond1", 1], ct["bond1", 3], ct["farmer", 1], ct["farmer", 3]))
}
fit(a[a$`_est_tobit1` == 1, ], "ldebt", "stored570, bond1, year_string decades")
fit(a[a$`_est_tobitin` == 1, ], "ldebtin", "stored178 real, bond1, year_string")
d <- a[a$match == 1, ]; d <- d[complete.cases(d[, c("age", "male", "married", "children", "farmer", "num_slaves", "num_prop", "cash1", "bond1", "both", "comp", "church", "wees", "dec")]), ]
fit(d, "y_nom", "matched all, zeros censored (true Tobit)")
cat("share of complete-case matched inventories with zero debt:", round(100 * mean(d$debt_value == 0), 1), "%\n")
