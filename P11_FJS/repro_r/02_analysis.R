# P11_FJS S3 recreation, step 2: Image 7 revenue streams, Image 9 decile shares, Image 6 derived cells,
# and results_r.csv. Choices: decisions.md (D8-D15).

library(tidyverse)
library(kableExtra)
library(here)
source(here("tools", "paths.R"))

PAPER <- "P11_FJS"
out_dir <- here(PAPER, "repro_r", "output")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
set.seed(20131201)

hh <- readRDS(dpath(PAPER, "repro_r", "_scratch", "hh_tax.rds"))
lf_year <- readRDS(dpath(PAPER, "repro_r", "_scratch", "loanfarm_year.rds"))
img6 <- readRDS(dpath(PAPER, "repro_r", "_scratch", "img6_inputs.rds"))

YEARS7 <- c(1700, 1705, 1712, 1719, 1723, 1731, 1738, 1741, 1757, 1773)
YEARS9 <- c(1700, 1719, 1731, 1738, 1741, 1757, 1773)

# ---- Image 7: revenue streams recoverable from the supplied data -------------
img7 <- hh |>
  filter(year %in% YEARS7) |>
  group_by(year) |>
  summarise(n = n(), poll = sum(poll), wine_tax = sum(wine), grain = sum(grain), meat = sum(meat),
            .groups = "drop") |>
  left_join(lf_year, by = "year") |>
  mutate(across(c(leases, property, property_12rd), \(x) replace_na(x, 0)),
         household_taxes = poll + wine_tax + grain + meat,
         direct_subtotal = household_taxes + property)
write_csv(img7, file.path(out_dir, "image7_components.csv"))

# ---- Image 9: slave-owning deciles -------------------------------------------
decile_shares <- function(slaves, tax, tiebreak) {
  dec <- ntile(order(order(slaves, tiebreak)), 10)
  s <- tapply(tax, factor(dec, levels = 1:10), sum)
  100 * s / sum(tax)
}

N_DRAW <- 500
dec_main <- hh |>
  filter(year %in% YEARS9) |>
  group_by(year) |>
  group_modify(\(d, k) {
    m <- replicate(N_DRAW, decile_shares(d$slaves, d$tax, runif(nrow(d))))
    tibble(decile = 1:10, share = rowMeans(m), n = nrow(d))
  }) |>
  ungroup()
write_csv(dec_main, file.path(out_dir, "image9_decile_shares.csv"))

# Robustness for the top decile
top_robust <- hh |>
  filter(year %in% YEARS9) |>
  group_by(year) |>
  summarise(
    n = n(),
    top_main = mean(replicate(N_DRAW, decile_shares(slaves, tax, runif(n()))[10])),
    top_r1_poll_all = mean(replicate(N_DRAW, decile_shares(slaves, tax_r1, runif(n()))[10])),
    top_r2_ties_together = 100 * sum(tax[slaves >= quantile(slaves, 0.9, type = 7)]) / sum(tax),
    share_hh_r2 = mean(slaves >= quantile(slaves, 0.9, type = 7)),
    top_r3_ties_tax_asc = decile_shares(slaves, tax, tax)[10],
    top_r4_ties_tax_desc = decile_shares(slaves, tax, -tax)[10],
    bottom_half = mean(replicate(50, sum(decile_shares(slaves, tax, runif(n()))[1:5]))),
    .groups = "drop"
  )

# Household bootstrap SE (D11)
N_BOOT <- 500
boot_se <- hh |>
  filter(year %in% YEARS9) |>
  group_by(year) |>
  summarise(se_boot = sd(replicate(N_BOOT, {
    i <- sample.int(n(), n(), replace = TRUE)
    decile_shares(slaves[i], tax[i], runif(n()))[10]
  })), .groups = "drop")
top_robust <- left_join(top_robust, boot_se, by = "year")
write_csv(top_robust, file.path(out_dir, "image9_top_decile_robustness.csv"))

# ---- Image 6: derived cells --------------------------------------------------
img6d <- img6 |>
  mutate(def = exp - rev, revgdp = 100 * rev / gdp, expgdp = 100 * exp / gdp, defgdp = 100 * def / gdp)
write_csv(img6d, file.path(out_dir, "image6_derived.csv"))

# ---- Tables (.tex) -----------------------------------------------------------
img7 |>
  transmute(Year = year, Households = n, Poll = poll, `Wine tax` = wine_tax, `Grain tax` = grain,
            `Meat tax` = meat, `Property tax` = property, Subtotal = direct_subtotal) |>
  kbl(format = "latex", booktabs = TRUE, digits = 0, format.args = list(big.mark = ","),
      caption = "Company revenue from household and property taxes, guilders (R recreation of Image 7, tax streams only)") |>
  save_kable(file.path(out_dir, "image7_components.tex"))

dec_main |>
  select(year, decile, share) |>
  pivot_wider(names_from = decile, values_from = share, names_prefix = "D") |>
  rename(Year = year) |>
  kbl(format = "latex", booktabs = TRUE, digits = 1,
      caption = "Share of household tax by slave-owning decile, percent (R recreation of Image 9)") |>
  save_kable(file.path(out_dir, "image9_decile_shares.tex"))

# ---- results_r.csv -----------------------------------------------------------
claims <- read_csv(here(PAPER, "claims", "claims.csv"), show_col_types = FALSE)

top <- top_robust |> select(year, top_main, se_boot, n)
gt <- function(y) top |> filter(year == y)
i7 <- function(y, v) img7 |> filter(year == y) |> pull(all_of(v))
i6 <- function(y, v) img6d |> filter(year == y) |> pull(all_of(v))

res <- list()
add <- function(id, value = NA, se = NA, n = NA, status = "") {
  res[[length(res) + 1]] <<- tibble(claim_id = id, source = "r", value = value, se = se, n = n,
                                     status_override = status)
}

for (id in claims$claim_id) {
  if (str_detect(id, "^I6_")) {
    y <- as.integer(str_extract(id, "\\d{4}"))
    v <- str_remove(id, "^I6_\\d{4}_")
    if (v %in% c("def", "revgdp", "expgdp", "defgdp")) add(id, i6(y, v)) else add(id, status = "unavailable")
  } else if (str_detect(id, "^I9_")) {
    y <- as.integer(str_extract(id, "\\d{4}"))
    add(id, gt(y)$top_main, gt(y)$se_boot, gt(y)$n)
  } else if (id %in% c("I7_1773_poll", "I7_1773_winetax", "I7_1773_grain", "I7_1773_meat", "I7_1773_property")) {
    v <- c(I7_1773_poll = "poll", I7_1773_winetax = "wine_tax", I7_1773_grain = "grain",
           I7_1773_meat = "meat", I7_1773_property = "property")[[id]]
    add(id, i7(1773, v), n = i7(1773, "n"))
  } else if (id == "txt_p16_defgdp_1789") {
    add(id, i6(1789, "defgdp"))
  } else if (id == "txt_p16_defgdp_1792") {
    add(id, i6(1792, "defgdp"))
  } else if (id %in% c("txt_p19_top10_1700")) {
    add(id, gt(1700)$top_main, gt(1700)$se_boot, gt(1700)$n)
  } else if (id %in% c("txt_p19_top10_1773", "txt_p21_top10_1773")) {
    add(id, gt(1773)$top_main, gt(1773)$se_boot, gt(1773)$n)
  } else if (str_detect(id, "^txt_p17_|^txt_fn28_|^txt_p10_")) {
    add(id, status = "not-attempted")
  } else {
    add(id, status = "unavailable")   # secondary tables, totals and non-tax streams (D9, D13)
  }
}
res <- bind_rows(res)
stopifnot(nrow(res) == nrow(claims))
write_csv(res, here(PAPER, "repro_r", "results_r.csv"), na = "")
print(top_robust, width = 200)
print(img7, width = 200)
