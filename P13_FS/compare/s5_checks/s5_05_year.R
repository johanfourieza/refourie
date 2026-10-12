# S5 check 5: missing year in the stored 570 sample; alternative date variables; refit with full 570 rows
suppressMessages({library(haven); library(dplyr); library(sandwich); library(lmtest)})
source(here::here("tools", "paths.R"))
a <- zap_labels(read_dta(dpath("P13_FS", "original", "MOOC 8", "DATA20141122.dta")))
a$male <- as.numeric(a$gender == "m")
for (mk in c("_est_tobit1", "_est_tobitin")) {
  d <- a[a[[mk]] == 1, ]
  yv <- grep("year|decade|dec_|^d1[6-8]", names(d), value = TRUE); yv <- yv[!grepl("spouse|married|birth|baptism|_sy$", yv)]
  cat(mk, "N", nrow(d), "| NA counts:", paste0(yv, "=", sapply(yv, function(v) sum(is.na(d[[v]]))), collapse = " "), "\n")
}
d <- a[a$`_est_tobit1` == 1, ]
cat("death_year range", range(d$death_year, na.rm = TRUE), "\n")
yr <- dplyr::coalesce(d$year, d$death_year)
cat("coalesced year NA:", sum(is.na(yr)), "\n")
for (yname in c("year", "coalesce(year,death_year)")) {
  d$dec <- factor(floor((if (yname == "year") d$year else yr) / 10) * 10)
  m <- lm(ldebt ~ age + male + married + children + farmer + num_slaves + num_prop + cash1 + bond + both + comp + church + wees + dec, data = d)
  ct <- coef(summary(m)); th <- coeftest(m, vcov = vcovHC(m, "HC1"))
  cat(yname, "nobs", nobs(m), "| slaves", round(ct["num_slaves", 1], 4), "t", round(ct["num_slaves", 3], 2), "tHC1", round(th["num_slaves", 3], 2),
      "| bonds", round(ct["bond", 1], 3), "| props", round(ct["num_prop", 1], 3), "| oc", round(ct["wees", 1], 3), "| farmer", round(ct["farmer", 1], 3), "\n")
}
