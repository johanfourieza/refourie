# S5 check 2: headline arithmetic, like-for-like falls, roll totals (paper T1+T2 vs rebuild), attrition benchmark
suppressMessages(library(tidyverse))
setwd(here::here()); if (!dir.exists("claims")) setwd("P26_NF")
cl <- read_csv("claims/claims.csv", show_col_types = FALSE)
tab <- cl |> filter(str_detect(claim_id, "^T[12]_")) |>
  separate(claim_id, c("t", "div", "year"), sep = "_") |>
  mutate(v = as.numeric(gsub(",", "", reported_value))) |> select(t, div, year, v) |>
  pivot_wider(names_from = t, values_from = v)
cat("Column sums vs printed Total:\n")
print(tab |> filter(div != "Total") |> group_by(year) |> summarise(T1 = sum(T1, na.rm = TRUE), T2 = sum(T2, na.rm = TRUE)) |>
  left_join(tab |> filter(div == "Total") |> select(year, T1p = T1, T2p = T2), by = "year"))
d <- tab |> filter(div != "Total")
s <- function(y, drop = character()) d |> filter(year == y, !div %in% drop) |> summarise(b = sum(T1, na.rm = TRUE), w = sum(T2, na.rm = TRUE))
na86 <- c("Griquala", "Thembula"); sw <- c("Uitenhag", "Victoria")   # N/A in 1886; formula->manual switch 1886->87
for (sc in list(list("published", character(), character()), list("like_for_like", na86, na86), list("lfl_no_method_switch", c(na86, sw), c(na86, sw)))) {
  a <- s("1886", sc[[2]]); b <- s("1887", sc[[3]])
  cat(sprintf("%-22s black %d->%d fall %d | whcol %d->%d fall %d | black rate %.3f whcol rate %.3f | excess black fall %.0f\n",
    sc[[1]], a$b, b$b, a$b - b$b, a$w, b$w, a$w - b$w, 1 - b$b / a$b, 1 - b$w / a$w, (a$b - b$b) - a$b * (1 - b$w / a$w)))
}
# roll totals: paper (T1+T2) vs rebuild total
rb <- read_csv("repro_r/output/division_year_counts.csv", show_col_types = FALSE) |> filter(variant == "primary") |> mutate(year = as.character(year))
tt <- d |> mutate(ptot = T1 + T2, pshare = T1 / ptot) |> inner_join(rb, by = c("div" = "division", "year")) |>
  mutate(dtot = total - ptot, rshare = black / total)
print(tt |> select(div, year, ptot, total, dtot, pshare, rshare), n = 50)
cat("median |dtot|/ptot:", median(abs(tt$dtot) / tt$ptot), "; cells within 2%:", sum(abs(tt$dtot) / tt$ptot < .02), "of", nrow(tt), "\n")
c5 <- c("Kimberle", "KingWill", "PortEliz", "Queensto", "Wodehous")
p5 <- d |> filter(div %in% c5, year %in% c("1886", "1887")) |> group_by(year) |> summarise(b = sum(T1), w = sum(T2))
print(p5)
