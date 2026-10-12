# P26_NF S3: 02_analysis. Surname matching, division-year counts, results_r.csv
suppressMessages({library(dplyr); library(tidyr); library(readr); library(here)})
source(here::here("tools", "paths.R"))
scr <- dscratch("P26_NF", "repro_r")
r09 <- readRDS(file.path(scr, "r09.rds")); yr <- readRDS(file.path(scr, "yr.rds"))
dir.create(here::here("P26_NF", "repro_r", "output"), showWarnings = FALSE)
out <- function(...) here::here("P26_NF", "repro_r", "output", ...)
cl <- read_csv(here::here("P26_NF", "claims", "claims.csv"), show_col_types = FALSE, col_select = claim_id)
# ---- surname lists from 1909 (primary: any record with black code; K=Kaffir, F=Fingo, I=indigenous, B=Bantu/other)
build <- function(codes, rule = "any") {
  s <- r09 |> filter(!is.na(race)) |> group_by(key) |> summarise(nb = sum(race %in% codes), n = n(), .groups = "drop")
  if (rule == "any") s$key[s$nb > 0 & s$key != ""] else s$key[s$nb / s$n > 0.5 & s$key != ""]
}
variants <- list(primary = build(c("K","F","I","B")), noI = build(c("K","F","B")), KF = build(c("K","F")), majority = build(c("K","F","I","B"), "majority"))
# ---- division-year counts; when a division-year appears in two sheets keep the sheet with more rows
dy <- yr |> filter(!is.na(division)) |> group_by(division, year, k) |> mutate(n_sheet = n()) |> group_by(division, year) |>
  filter(k == k[which.max(n_sheet)][1]) |> ungroup()
cnt <- bind_rows(lapply(names(variants), function(v) dy |> mutate(black = key %in% variants[[v]]) |>
  group_by(division, year, sheet = k) |> summarise(total = n(), black = sum(black), .groups = "drop") |> mutate(variant = v)))
write_csv(cnt, out("division_year_counts.csv"))
p <- cnt |> filter(variant == "primary") |> mutate(white_col = total - black)
# ---- results_r.csv: every claim, default unavailable
res <- cl |> mutate(source = "r", value = NA_real_, se = NA_real_, n = NA_real_, status_override = "unavailable")
set <- function(id, v, n = NA) { i <- res$claim_id == id; if (any(i)) { res$value[i] <<- v; res$n[i] <<- n; res$status_override[i] <<- "" } }
for (r in seq_len(nrow(p))) {
  set(sprintf("T1_%s_%d", p$division[r], p$year[r]), p$black[r], p$total[r])
  set(sprintf("T2_%s_%d", p$division[r], p$year[r]), p$white_col[r], p$total[r])
}
w <- p |> filter(division == "Wodehous", year %in% c(1886, 1887)) |> arrange(year)
if (nrow(w) == 2) set("TX_wodehouse_drop", w$black[1] - w$black[2], sum(w$total))
set("TX_records_1909", nrow(r09), nrow(r09))
res <- res |> select(claim_id, source, value, se, n, status_override)
write_csv(res, here::here("P26_NF", "repro_r", "results_r.csv"), na = "")
# like-for-like partial totals (divisions present in both years) for the 1886-87 fall; not a claim
common <- p |> filter(year %in% c(1886, 1887)) |> group_by(division) |> filter(n_distinct(year) == 2) |> ungroup()
pt <- common |> group_by(year) |> summarise(black = sum(black), white_col = sum(white_col), total = sum(total), divs = n())
write_csv(pt, out("partial_total_1886_87_common_divisions.csv"))
sens <- cnt |> filter(year %in% c(1886, 1887), division %in% common$division) |> group_by(variant, year) |> summarise(black = sum(black), .groups = "drop") |> pivot_wider(names_from = year, values_from = black) |> mutate(fall = `1886` - `1887`)
write_csv(sens, out("sensitivity_black_fall_common_divisions.csv"))
print(pt); print(sens); print(p |> select(division, year, sheet, total, black), n = 60)
cat("1909 black-coded share of records:", mean(r09$race %in% c("K","F","I","B"), na.rm = TRUE), " by sheet east-only n:", sum(!grepl("cape|malmes|paarl|piquet|stellen|swellen|riversd|worcest|robert|mossel|bredas|montagu|ceres|ladismith|oudts|rhyns|fraser|carnarv|kenhard|gordon|hay|prieska|namaq|calacia", tolower(r09$div))), "\n")
cat("claims with values:", sum(res$status_override == ""), "of", nrow(res), "\n")
