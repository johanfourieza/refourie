# S5 check 3: dependent-variable definition (inheritance exclusion) and t-stat type on the stored Panel A samples
suppressMessages({library(haven); library(dplyr); library(readr); library(AER); library(sandwich); library(lmtest)})
source(here::here("tools", "paths.R"))
od <- dpath("P13_FS", "original", "MOOC 8")
a <- zap_labels(read_dta(file.path(od, "DATA20141122.dta"))); p <- zap_labels(read_dta(file.path(od, "PURPOSEDATA_20141117.dta")))
cl <- read_csv(here::here("P13_FS", "claims", "claims.csv"), col_types = cols(.default = "c"), show_col_types = FALSE)
pub <- setNames(as.numeric(cl$reported_value), cl$claim_id)
a$male <- as.numeric(a$gender == "m"); a$dec <- factor(floor(a$year / 10) * 10)
s <- a$`_est_tobit1` == 1
dd <- a$ldebt[s] - log(a$debt_value[s]); cat("ldebt - log(debt_value) in sample: quantiles", quantile(dd, c(0,.1,.5,.9,1), na.rm=TRUE), "\n")
cat("cor(exp(ldebt), debt_value) =", cor(exp(a$ldebt[s]), a$debt_value[s]), " exp(ldebt)/debtvalue ratio median", median(exp(a$ldebt[s]) / a$debtvalue[s], na.rm=TRUE), "\n")
inh <- p |> filter(!is.na(value_debt)) |> group_by(mooc) |>
  summarise(d_all = sum(value_debt), d_noinh = sum(value_debt[purpose_debt != "Inheritance"]), n_inh = sum(purpose_debt == "Inheritance"), .groups = "drop")
a <- left_join(a, inh, by = "mooc")
cat("in sample: n with inheritance debt", sum(a$n_inh[s] > 0, na.rm=TRUE), " cor(d_all, debt_value)", cor(a$d_all[s], a$debt_value[s], use="c"),
    " ldebt vs log(d_noinh) mean abs diff", mean(abs(a$ldebt[s] - log(a$d_noinh[s])), na.rm=TRUE), " vs log(d_all)", mean(abs(a$ldebt[s] - log(a$d_all[s])), na.rm=TRUE), "\n")
a$ly_noinh <- log(a$d_noinh)
xs <- "age + male + married + children + farmer + num_slaves + num_prop + cash1 + bond + both + comp + church + wees + dec"
out <- list()
for (y in c("ldebt", "ly_noinh")) {
  d <- droplevels(a[s & is.finite(a[[y]]), ]); m <- lm(as.formula(paste(y, "~", xs)), data = d)
  t_conv <- coef(summary(m))[, 3]; t_hc1 <- coeftest(m, vcov = vcovHC(m, "HC1"))[, 3]
  for (k in c(slaves = "num_slaves", bonds = "bond", props = "num_prop", oc = "wees", farmer = "farmer")) {
    nm <- names(which(c(slaves = "num_slaves", bonds = "bond", props = "num_prop", oc = "wees", farmer = "farmer") == k))
    id <- paste0("T6A_", nm, "_nom_coef")
    out[[length(out) + 1]] <- tibble(y = y, N = nrow(d), claim = id, pub = pub[id], coef = coef(m)[k], t_conv = t_conv[k], t_hc1 = t_hc1[k], t_pub = pub[sub("_coef", "_t", id)])
  }
}
print(as.data.frame(bind_rows(out)), digits = 4)
