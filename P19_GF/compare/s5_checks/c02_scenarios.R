# S5 check 2: Fig A2 denominator, pw+debt definitions, Table 2 composition, residual, deficit
suppressPackageStartupMessages({library(readxl); library(dplyr)})
source("./tools/paths.R")
x <- read.csv("P19_GF/repro_r/output/expenditure_classes.csv")
pth <- dpath("P19_GF", "original", "colonial govt fiscal", "Abel Gwaindepi CC fiscal records.xlsx")
e <- suppressMessages(read_excel(pth, sheet = "Expenditure", .name_repair = "minimal"))
names(e) <- make.unique(trimws(gsub("[[:space:]]+", " ", names(e))))
e <- e |> select(-starts_with("YEAR."), year = YEAR) |> mutate(across(everything(), as.numeric))
z <- function(v) ifelse(is.na(v), 0, v)
a2 <- e |> transmute(year, rail = z(`Total Railways`), rb = z(`Roads & Bridges`), wb = z(`Works & Buildings`),
                     ph = z(`Ports and Harbours`), tel = z(Telegraph)) |>
  mutate(pwA2 = rail + rb + wb + ph + tel, rail_sh = 100 * rail / pwA2)
b <- filter(a2, year >= 1880, year <= 1909)
cat("A2 def rail share 1880-1909: mean", mean(b$rail_sh), "min", min(b$rail_sh), "(", b$year[which.min(b$rail_sh)], ") max", max(b$rail_sh),
    "frac>70", mean(b$rail_sh > 70), "\n")
cat("A2 def rail share 1877", a2$rail_sh[a2$year == 1877], " 1876", a2$rail_sh[a2$year == 1876], "\n")
print(round(filter(a2, year >= 1874)$rail_sh, 1))
cat("years<70 1880-1909:", b$year[b$rail_sh < 70], "\n")
# rebuild def (all Table 1 pw items)
bb <- filter(x, year >= 1880, year <= 1909)
cat("Rebuild def rail/pw: mean", mean(100 * bb$rail / bb$pw), "\n")
# pw+debt share variants, 1870-1909 and 1880-1909
xx <- x |> left_join(select(a2, year, pwA2), by = "year") |>
  mutate(s_tot = 100 * (pw + debt) / total, s_cls = 100 * (pw + debt) / classified,
         s_nodef = 100 * (pw + debt) / (classified - mil), s_A2 = 100 * (pwA2 + debt) / total)
for (lo in c(1870, 1880)) { w <- filter(xx, year >= lo, year <= 1909)
  cat(lo, "-1909 pw+debt: total-denom mean", mean(w$s_tot), "frac>70", mean(w$s_tot > 70),
      "| classified mean", mean(w$s_cls), "frac>70", mean(w$s_cls > 70),
      "| excl.defence mean", mean(w$s_nodef), "frac>70", mean(w$s_nodef > 70),
      "| A2-pw mean", mean(w$s_A2), "\n") }
print(round(filter(xx, year >= 1870) |> select(year, s_tot, s_cls, s_nodef), 1))
# residual by year
cat("Years with |resid|/total > 0.15:\n"); print(round(filter(x, abs(resid / total) > 0.15) |> transmute(year, ratio = classified / total), 2))
# Table 2 published composition vs workbook
t2 <- data.frame(year = c(1853, 1865, 1875, 1891, 1904), adm = c(.58, .44, .4, .59, 1.32), debt = c(.11, .56, .33, .83, .69),
                 hr = c(.16, .13, .14, .21, .34), pw = c(1.3, 1.57, 1.44, 2.87, 4.46), tot = c(2.15, 2.7, 2.31, 4.5, 6.81))
w <- filter(x, year %in% t2$year) |> mutate(den = adm + law + debt + hr + pw)
cmp <- data.frame(year = t2$year, pub_pw = 100 * t2$pw / t2$tot, wb_pw = 100 * w$pw / w$den,
                  pub_debt = 100 * t2$debt / t2$tot, wb_debt = 100 * w$debt / w$den,
                  pub_hr = 100 * t2$hr / t2$tot, wb_hr = 100 * w$hr / w$den,
                  pub_adm = 100 * t2$adm / t2$tot, wb_adm = 100 * (w$adm + w$law) / w$den,
                  pub_pwdebt = 100 * (t2$pw + t2$debt) / t2$tot, nominal_total = w$total)
print(round(cmp, 1))
cat("Published real per-capita growth 1853-1904:", 6.81 / 2.15, "; nominal total growth:", w$total[5] / w$total[1], "\n")
# deficit from primary workbook revenue sheet
r <- suppressMessages(read_excel(pth, sheet = "Revenue", .name_repair = "minimal")); print(names(r)[1:6])
