# S5 check 6: date variable x bond variable x Stata-style Tobit with ll() at sample minimum, stored 570 sample
suppressMessages({library(haven); library(dplyr); library(AER)})
source(here::here("tools", "paths.R"))
a <- zap_labels(read_dta(dpath("P13_FS", "original", "MOOC 8", "DATA20141122.dta")))
a$male <- as.numeric(a$gender == "m"); d <- a[a$`_est_tobit1` == 1, ]
cat("bond1 values", names(table(d$bond1)), "| cor(bond,bond1)", cor(d$bond, d$bond1, use = "c"), "\n")
out <- list()
for (yv in c("startyear", "year2", "end_year", "year_string")) for (bv in c("bond", "bond1")) for (ll in c("0", "min")) {
  yy <- suppressWarnings(as.numeric(d[[yv]])); if (all(is.na(yy))) next
  d$dec <- factor(floor(yy / 10) * 10)
  f <- as.formula(paste("ldebt ~ age + male + married + children + farmer + num_slaves + num_prop + cash1 +", bv, "+ both + comp + church + wees + dec"))
  m <- if (ll == "0") tobit(f, left = 0, data = d) else tobit(f, left = min(d$ldebt), data = d)   # Stata 'tobit, ll' censors at the sample min
  ct <- coef(summary(m))
  out[[length(out) + 1]] <- tibble(yv, bv, ll, n = nobs(m), slaves = ct["num_slaves", 1], t_sl = ct["num_slaves", 3], bonds = ct[bv, 1], t_bd = ct[bv, 3], props = ct["num_prop", 1], oc = ct["wees", 1], farmer = ct["farmer", 1])
}
r <- bind_rows(out) |> mutate(dist = abs(slaves - .087) / .087 + abs(bonds - 1.072) / 1.072 + abs(props - .193) / .193 + abs(oc - 1.253) / 1.253) |> arrange(dist)
print(as.data.frame(r), digits = 3)
