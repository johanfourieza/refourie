# P11_FJS S5: verify the S2 candidates by recomputation and quantify their effect on the headline claims.
# Re-implements fiscalpolicy.do lines 5-71 in R from base.dta, checks the A1 (published) variant against the
# saved Stata household file, then varies one assumption at a time. Slave deciles are taken from the Stata
# xtile output (slavesdecile), which depends only on tslaves and so is unchanged across tax scenarios.
# Output: compare/s5_effects.csv and compare/s5_checks/s5_scenarios_detail.csv (aggregates only).
suppressPackageStartupMessages({ library(tidyverse); library(haven) })
root <- "."
source(file.path(root, "tools", "paths.R"))
p11 <- file.path(root, "P11_FJS")
set.seed(20261011)

base <- read_dta(dpath("P11_FJS", "original", "Fourie Jansen Siebrits", "base.dta")) |> zap_labels() |>
  filter(!jaar %in% c(1663, 1670, 1685, 1716, 1752, 1762))                       # do:6-11
a1 <- read_dta(dpath("P11_FJS", "repro_original", "_scratch", "runA1_households.dta")) |> zap_labels()
r0 <- read_dta(dpath("P11_FJS", "repro_original", "_scratch", "run0_households.dta")) |> zap_labels()
stopifnot(nrow(base) == nrow(a1), all(base$naam == a1$naam), all(base$jaar == a1$jaar))
base$slavesdecile <- a1$slavesdecile

# ---- tax imputation (stuivers), options mirror the candidate findings ----
imp_tax <- function(d, wine_pre = 48, post_factor = 0.7, wine_const = 0.0008813, grain = "net",
                    poll_swell = 32, ds_na_town = FALSE) {
  d |> mutate(
    tslaves = sm + sv + ss + sd,
    assets  = bste + skpe + wingst + wyn + kgs + kgw + rgs + rgw + cgs + cgw,
    sassets = tslaves + assets,
    poll = case_when(sassets == 0 ~ ifelse(!is.na(ds) & ds == 4, poll_swell, 32),
                     tslaves > 0 & assets == 0 & !is.na(ds) & ds == 1 ~ 192,
                     tslaves > 0 & assets == 0 ~ ifelse(!is.na(ds) & ds == 4, poll_swell, 32),
                     TRUE ~ 0),
    wyn2 = if (is.na(wine_const)) wyn else ifelse(wyn == 0, wingst * wine_const, wyn),   # do:40-43
    winetax = case_when(jaar < 1743 ~ wine_pre * wyn2, jaar > 1743 ~ 144 * wyn2 * post_factor, TRUE ~ 0),
    gk = if (grain == "net") pmax(kgw - kgs, 0) else kgw,
    gr = if (grain == "net") pmax(rgw - rgs, 0) else rgw,
    gc = if (grain == "net") pmax(cgw - cgs, 0) else cgw,
    wheattax = gk * .1 * 6 * 48 + gr * .1 * 3 * 48 + gc * .1 * 3 * 48,
    meattax = bste + skpe * .16,
    totaltax = poll + winetax + wheattax + meattax)
}

# Check: R re-implementation of A1 and run 0 equals the Stata household files (float precision)
chkA1 <- imp_tax(base); chk0 <- imp_tax(base, wine_pre = 72)
cat("max |R - Stata| totaltax, A1:", max(abs(chkA1$totaltax - a1$totaltax)),
    " run0:", max(abs(chk0$totaltax - r0$totaltax)), "\n")
wy <- base$wyn / base$wingst; pos <- base$wyn != 0 & base$wingst != 0
cat("wine yield: mean incl zeros", mean(ifelse(pos, wy, 0)), " mean among producers", mean(wy[pos]),
    " median among producers", median(wy[pos]), "\n")
cat("households with vines but no wine (imputed):", sum(base$wyn == 0 & base$wingst > 0),
    " in 1773:", sum(base$wyn == 0 & base$wingst > 0 & base$jaar == 1773), "\n")
cat("ds missing:", sum(is.na(base$ds)), " in Image 9 years:", sum(is.na(base$ds) & base$jaar %in% c(1700,1719,1731,1738,1741,1757,1773)), "\n")

# ---- shares ----
img9 <- c(1700, 1719, 1731, 1738, 1741, 1757, 1773)
share_wb <- function(d, y) {             # workbook Deciles!W24: mean10 / sum of 10 decile means, empty deciles filled down
  x <- d |> filter(jaar == y) |> group_by(dec = as.integer(slavesdecile)) |> summarise(m = mean(totaltax), .groups = "drop")
  full <- tibble(dec = 1:10) |> left_join(x, by = "dec") |> fill(m, .direction = "down")
  100 * full$m[10] / sum(full$m)
}
share_exact <- function(d, y) { x <- filter(d, jaar == y); 100 * sum(x$totaltax[x$slavesdecile == 10]) / sum(x$totaltax) }
share_rand <- function(d, y, B = 200) {  # ten equal groups, ties at the cut broken at random
  x <- filter(d, jaar == y); n <- nrow(x); k <- ceiling(0.9 * n)
  mean(replicate(B, { o <- order(x$tslaves, runif(n)); 100 * sum(x$totaltax[o[(k + 1):n]]) / sum(x$totaltax) }))
}
img7_1773 <- function(d) {               # guilders; typed workbook inputs: property 9216, wine pacht 32000, brandy 26975, foreign 9300
  x <- filter(d, jaar == 1773); tx <- c(poll = sum(x$poll), wine = sum(x$winetax), grain = sum(x$wheattax), meat = sum(x$meattax)) / 16
  tot <- sum(tx) + 9216 + 32000 + 26975 + 9300
  c(total = tot, direct = 100 * (sum(tx) + 9216) / tot)
}

scen <- list(
  A1_published      = list(),
  run0_wine72       = list(wine_pre = 72),
  no_0.7_factor     = list(post_factor = 1),
  wine_const_mean   = list(wine_const = 0.0008878),
  wine_const_prod   = list(wine_const = mean(wy[pos])),
  no_vine_impute    = list(wine_const = NA),
  grain_gross       = list(grain = "gross"),
  poll_swell36      = list(poll_swell = 36),
  pairB_like        = list(post_factor = 1, wine_const = NA, grain = "gross")
)
res <- imap_dfr(scen, function(o, nm) {
  d <- do.call(imp_tax, c(list(base), o))
  i7 <- img7_1773(d)
  map_dfr(c(1700, 1773), function(y) tibble(scenario = nm, year = y,
    wb = share_wb(d, y), exact = share_exact(d, y), rand = share_rand(d, y))) |>
    mutate(total1773 = i7["total"], direct1773 = i7["direct"])
})
print(res, n = 50, width = 200)
write_csv(res, file.path(p11, "compare", "s5_checks", "s5_scenarios_detail.csv"))

# ---- s5_effects.csv ----
pub  <- c(txt_p19_top10_1773 = 61, txt_p19_top10_1700 = 50, I6_1789_defgdp = 40)
orig <- c(txt_p19_top10_1773 = 61.2413, txt_p19_top10_1700 = 45.0353, I6_1789_defgdp = 42.2404)   # results_original.csv (run 0)
g <- function(s, y, m) res[[m]][res$scenario == s & res$year == y]
notes <- c(A1_published = "line :47 at 48 st (paper's 1 Rd); reproduces Image 9 pastes to all digits",
           run0_wine72 = "surviving code as is (72 st before 1743)",
           no_0.7_factor = "S2-2: drop undisclosed 0.7 factor after 1743 (A1 base)",
           wine_const_mean = "S2-3: imputation constant = printed mean 0.0008878 (A1 base)",
           wine_const_prod = "S2-3: imputation constant = mean yield among producers (A1 base)",
           no_vine_impute = "S2-3: no wine imputed for vines without wine (A1 base)",
           grain_gross = "S2-8: 10% of gross yield as the paper states (A1 base)",
           poll_swell36 = "Swellendam poll tax 36 st (p.13) (A1 base)",
           pairB_like = "S2-2+S2-3+S2-8 jointly, the pair-B construction (A1 base)")
eff <- list()
for (s in names(scen)) for (m in c("wb", "exact", "rand")) {
  lab <- if (m == "wb") s else paste0(s, "__share_", m)
  if (m != "wb" && !s %in% c("A1_published", "run0_wine72", "pairB_like")) next
  nt <- paste0(notes[s], c(wb = "; workbook share (mean10/sum of means)", exact = "; S2-4 exact share of total tax in xtile decile 10",
                           rand = "; S2-4 ten equal groups, random tie-breaking (200 draws)")[m])
  for (y in c(1773, 1700)) {
    cid <- paste0("txt_p19_top10_", y)
    eff[[length(eff) + 1]] <- tibble(scenario = lab, claim_id = cid, published = pub[cid], original_code = orig[cid],
                                     scenario_value = round(g(s, y, m), 2), note = nt)
  }
}
eff <- bind_rows(eff,
  tibble(scenario = "gdp_printed", claim_id = "I6_1789_defgdp", published = 40, original_code = orig["I6_1789_defgdp"],
         scenario_value = round(100 * 1403 / 3472, 2), note = "S2-9: printed Image 6 GDP (1,403/3,472); pair B uses this"),
  tibble(scenario = "gdp_P15", claim_id = "I6_1789_defgdp", published = 40, original_code = orig["I6_1789_defgdp"],
         scenario_value = round(orig["I6_1789_defgdp"], 2), note = "S2-9: P15 recalculated GDP (pair A); deficit still positive, bound unaffected"))
write_csv(eff, file.path(p11, "compare", "s5_effects.csv"))
print(eff, n = 60, width = 200)
