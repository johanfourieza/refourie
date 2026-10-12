# P19_GF S3 independent recreation: 02_analysis.R
# Descriptive paper: no estimators, SEs or clustering exist; se is NA everywhere.
suppressPackageStartupMessages({library(dplyr); library(readr)})
setwd("./P19_GF")
source("./tools/paths.R")
set.seed(19)
if (!exists("x")) source("repro_r/01_clean.R")
cl <- read_csv("claims/claims.csv", show_col_types = FALSE)
res <- tibble(claim_id = cl$claim_id, source = "r", value = NA_real_, se = NA_real_,
              n = NA_real_, status_override = "unavailable")
put <- function(id, v, n = NA, status = "") {
  i <- match(id, res$claim_id); stopifnot(!is.na(i))
  res$value[i] <<- v; res$n[i] <<- n; res$status_override[i] <<- status
}
x <- x |> mutate(pw_s = 100 * pw / total, debt_s = 100 * debt / total, rail_pw = 100 * rail / pw,
                 pwdebt_s = pw_s + debt_s, pwdebt_alt = 100 * (pw + debt) / classified,
                 pw_alt = 100 * pw / classified)
yr <- function(df, v, y) df[[v]][df$year == y]

# Text claims on expenditure shares ------------------------------------------------
a <- filter(x, year >= 1870, year <= 1909)
put("TX_p351_pwdebt70", mean(a$pwdebt_s, na.rm = TRUE), nrow(a))       # mean 1870-1909; min/frac>70 in output
b <- filter(x, year >= 1880, year <= 1909, rail > 0)
put("TX_abs_rail70", mean(b$rail_pw), nrow(b))                         # mean 1880-1909
put("FA2_rail_min", min(b$rail_pw), nrow(b)); put("FA2_rail_max", max(b$rail_pw), nrow(b))
put("F2_pw_1905", yr(x, "pw_s", 1905), 1)
put("F2_pw_1876", yr(x, "pw_s", 1876), 1)
put("F2_debt_1874", yr(x, "debt_s", 1874), 1)
put("TX_p352_railexp", max(x$rail, na.rm = TRUE) / 1e6, sum(x$rail > 0))   # million, series units
put("TX_p352_otherinfra", max(unlist(items[-1]), na.rm = TRUE) / 1e6, ncol(items) - 1)

# Debt/GDP (public debt only; Stone private debt unavailable) -----------------------
put("F6_pub_1885", yr(d, "debt_gdp", 1885), 1)
put("F6_pub_1900", yr(d, "debt_gdp", 1900), 1)
put("F6_pub_1909", yr(d, "debt_gdp", 1909), 1)
put("TX_p357_pubpeak", max(d$debt_gdp[d$year %in% 1880:1889]), 10)
put("TX_p341_debt1899", max(d$debt_gdp[d$year %in% 1898:1900]), 3)   # public series; see decisions.md
# Deficits
put("TX_p360_deficit", -min(x_f <- f$balance[f$year >= 1872], na.rm = TRUE) / 1e6, sum(f$year >= 1872))

write_csv(res, "repro_r/results_r.csv", na = "")

# Supplementary diagnostics (not claims) --------------------------------------------
diag <- tribble(~item, ~value,
  "pwdebt_share_min_1870_1909", min(a$pwdebt_s, na.rm = TRUE),
  "pwdebt_share_frac_years_gt70_1870_1909", mean(a$pwdebt_s > 70, na.rm = TRUE),
  "pwdebt_share_alt_denominator_mean", mean(a$pwdebt_alt, na.rm = TRUE),
  "pwdebt_share_alt_denominator_min", min(a$pwdebt_alt, na.rm = TRUE),
  "rail_pw_share_1877", yr(x, "rail_pw", 1877),
  "rail_pw_frac_years_gt70_1880_1909", mean(b$rail_pw > 70),
  "pw_share_max_1895_1909", max(x$pw_s[x$year >= 1895], na.rm = TRUE),
  "pw_share_max_1895_1909_year", x$year[x$year >= 1895][which.max(x$pw_s[x$year >= 1895])],
  "debt_gdp_1899", yr(d, "debt_gdp", 1899), "debt_gdp_1900", yr(d, "debt_gdp", 1900),
  "debt_gdp_max_all", max(d$debt_gdp), "debt_gdp_max_year", d$year[which.max(d$debt_gdp)],
  "max_abs_resid_share_of_total", max(abs(x$resid) / x$total, na.rm = TRUE),
  "rail_max_year", x$year[which.max(x$rail)],
  "deficit_max_year", f$year[f$year >= 1872][which.min(f$balance[f$year >= 1872])])
write_csv(diag, "repro_r/output/diagnostics.csv")
# Table 2 analogue shares by class (per capita not computable without population)
t2y <- c(1853, 1865, 1875, 1891, 1904)
t2 <- x |> filter(year %in% t2y) |>
  transmute(year, adm_law = 100 * (adm + law) / total, debt = debt_s, hr = 100 * hr / total, pw = pw_s,
            defence = 100 * mil / total, total_level = total)
write_csv(t2, "repro_r/output/table2_shares_analogue.csv")
print(as.data.frame(res)); print(as.data.frame(diag)); print(as.data.frame(t2))
