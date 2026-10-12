# S5 check 4: small specification grid on the stored 570 sample to locate the published Panel A spec (aggregates only)
suppressMessages({library(haven); library(dplyr); library(readr)})
source(here::here("tools", "paths.R"))
a <- zap_labels(read_dta(dpath("P13_FS", "original", "MOOC 8", "DATA20141122.dta")))
cat(grep("bond|marr|spou|church|comp|wees|dec|period|cent|prop|cash|both|gender|male", names(a), value = TRUE), "\n")
a$male <- as.numeric(a$gender == "m")
d <- a[a$`_est_tobit1` == 1, ]
cat("bond values:", names(table(d$bond)), " married values:", names(table(d$married)), " decade from year span", range(d$year), "\n")
decs <- list(dec10 = factor(floor(d$year / 10) * 10), dec20 = factor(floor(d$year / 20) * 20), dec25 = factor(floor(d$year / 25) * 25), dec50 = factor(floor(d$year / 50) * 50), none = NULL)
bondv <- intersect(c("bond", "bonds", "bond_present", "num_bond", "prop_debt"), names(d)); cashv <- intersect(c("cash1", "cash", "cash_infl"), names(d))
res <- list()
for (dn in names(decs)) for (bv in bondv) for (cv in cashv) {
  X <- d[, c("age", "male", "married", "children", "farmer", "num_slaves", "num_prop", cv, bv, "both", "comp", "church", "wees")]
  if (!is.null(decs[[dn]])) X$dec <- decs[[dn]]
  m <- lm(d$ldebt ~ ., data = X); co <- coef(m)
  res[[length(res) + 1]] <- tibble(dec = dn, bond = bv, cash = cv, slaves = co["num_slaves"], props = co["num_prop"], bonds = co[bv], oc = co["wees"], farmer = co["farmer"], const = co["(Intercept)"])
}
r <- bind_rows(res) |> mutate(dist = abs(slaves - .087) / .087 + abs(bonds - 1.072) / 1.072 + abs(props - .193) / .193 + abs(oc - 1.253) / 1.253) |> arrange(dist)
print(as.data.frame(head(r, 8)), digits = 3)
