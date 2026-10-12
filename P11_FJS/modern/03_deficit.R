# P11_FJS S6 03: H2 primary (card §3, §4C-D). Arithmetic on the printed Image 6 values frozen in claims/claims.csv.
# Output: output/primary_h2.csv
source("./P11_FJS/modern/00_common.R")
claims <- read_csv(file.path(ROOT, P, "claims", "claims.csv"), show_col_types = FALSE)
pv <- function(id) { v <- claims$reported_value[claims$claim_id == id]; if (length(v) == 1) as.numeric(v) else NA_real_ }

UNIV <- c(1777, 1787, 1789, 1792, 1794)                  # years with revenue and expenditure printed (§3)
h2 <- tibble(year = UNIV, rev = sapply(UNIV, function(y) pv(sprintf("I6_%d_rev", y))),
             exp = sapply(UNIV, function(y) pv(sprintf("I6_%d_exp", y))),
             gdp = sapply(UNIV, function(y) pv(sprintf("I6_%d_gdp", y)))) |>
  mutate(D = exp - rev, inputs_readable = !is.na(rev) & !is.na(exp))
R89 <- with(filter(h2, year == 1789), 100 * D / gdp)
r89_readable <- with(filter(h2, year == 1789), !is.na(rev) & !is.na(exp) & !is.na(gdp))
out <- bind_rows(
  h2 |> transmute(quantity = paste0("D_", year), value = D, inputs_readable),
  tibble(quantity = "R89", value = R89, inputs_readable = r89_readable),
  tibble(quantity = "GDP_1789_printed", value = pv("I6_1789_gdp"), inputs_readable = !is.na(pv("I6_1789_gdp"))))
write_csv(out, file.path(OUT, "primary_h2.csv"))
print(out)
