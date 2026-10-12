# S2 extraction for P29_INEQ25: reads the objects saved by the [S2-HOOK] lines of the patched
# InequalityScript_rev.R (./P29_INEQ25/repro_original/_scratch/hooks) and writes
# results_original.csv (one row per claim, source = "original"). Run from the project root:
#   Rscript P29_INEQ25/repro_original/extract_results.R
suppressPackageStartupMessages({library(dplyr); library(tidyr); library(readr); library(purrr)})
source("tools/paths.R")
p <- "P29_INEQ25"
H <- function(n) readRDS(dpath(p, "repro_original", "_scratch", "hooks", paste0(n, ".rds")))
claims <- read_csv(file.path(p, "claims", "claims.csv"), show_col_types = FALSE)

out <- list()
add <- function(id, value, note = "", n = NA_real_, ovr = NA_character_)
  out[[length(out) + 1]] <<- tibble(claim_id = id, source = "original", value = as.numeric(value),
                                     se = NA_real_, n = as.numeric(n), status_override = ovr, note = note)

## Fig 1: author's instruction "##Run until before slaves" (line 1020): the Fig 1 block is meant to run
## on gini_long / gini_total_production as they stand at line 694. That state is hook pre_slaves.
ps <- H("pre_slaves")
tv <- ps$gini_total_production
for (yr in c(1690, 1700, 1720, 1730, 1740, 1750, 1760, 1770, 1780, 1790, 1800, 1810, 1820, 1830))
  add(sprintf("F1_totval_%d", yr), tv$gini_total_value[tv$period == yr],
      "Fig 1 total value (5-good price-weighted basket, decade), pre-slave state per '##Run until before slaves'")
lin <- H("fig1_linear") |> filter(variable == "total_value")
gv <- H("fig1_assets_annual")$gini_values
mins <- gv |> pivot_longer(-year) |> filter(!is.na(value)) |> slice_min(value, n = 1)
add("F1_min_asset", mins$value, sprintf("min annual asset Gini: %s %d", mins$name, mins$year))
add("txt_p4_min_asset_gini", mins$value, "lower bound claim: min annual Gini over six assets (all years)")
t18 <- tv |> filter(period >= 1700, period < 1800)
add("txt_p4_tv_lo", min(t18$gini_total_value), "min of decade total-value Gini, periods 1700-1790")
add("txt_p4_tv_hi", max(t18$gini_total_value), "max of decade total-value Gini, periods 1700-1790")

## Counts
add("txt_p4_nobs", H("n_after_outliers"), sprintf("rows after outlier removal; raw rows with year = %d", H("n_year")))
oa <- H("obs_avgs")
add("txt_p4_ncensus", nrow(oa$obs_per_year), sprintf("distinct census years %d-%d", min(oa$obs_per_year$year), max(oa$obs_per_year$year)))
add("txt_p4_hh_first", oa$summary_avgs$avg_first_10, "mean rows per year, first 10 census years (line 1001)")
add("txt_p4_hh_last", oa$summary_avgs$avg_last_10, "mean rows per year, last 10 census years")
add("txt_p4_hh_avg", oa$summary_avgs$avg_overall, "mean rows per year, all census years")

## Top shares (lines 1080-1105, compute_top_shares) applied, as with Fig 1, to the pre-slave total_value
compute_top_shares <- function(x) {
  x <- sort(x[!is.na(x)], decreasing = TRUE); n <- length(x); total <- sum(x)
  tibble(top_1_share = sum(x[1:ceiling(n * 0.01)]) / total,
         top_0_1_share = sum(x[1:ceiling(n * 0.001)]) / total,
         top_0_01_share = sum(x[1:ceiling(n * 0.0001)]) / total)
}
ts <- ps$tv |> group_by(period) |> reframe(compute_top_shares(total_value))
tsl <- H("topshares_linear")$a
m <- function(d, v, f) 100 * mean(d[[v]][f(d$period)])
add("txt_p4_top1_avg", m(ts, "top_1_share", function(x) x > 0), sprintf("mean over decades of top-1%% share, pre-slave state; linear-run state (12-sheep slave households) = %.1f", m(tsl, "top_1_share", function(x) x > 0)))
add("txt_p4_top1_1800", m(ts, "top_1_share", function(x) x >= 1800), "mean top-1% share, periods 1800-1830, pre-slave state")
add("txt_p4_top01_18c", m(ts, "top_0_1_share", function(x) x < 1800), "mean top-0.1% share, periods 1690-1790")
add("txt_p4_top001_18c", m(ts, "top_0_01_share", function(x) x < 1800), "mean top-0.01% share, periods 1690-1790")
add("txt_p4_top01_19c", m(ts, "top_0_1_share", function(x) x >= 1800), "mean top-0.1% share, periods 1800-1830")
add("txt_p4_top001_19c", m(ts, "top_0_01_share", function(x) x >= 1800), "mean top-0.01% share, periods 1800-1830")
add("txt_p4_slavemen_gini", min(H("slave_gini_annual")$slave_men, na.rm = TRUE), "min annual Gini of slave_men (line 708)")

## Fig 2 (lines 1143-1270)
f2 <- H("fig2") |> filter(!is.na(period))
sc <- c(settlers = "Settlers only (no slaves)", slaveassets = "Settlers + slave assets (slaves not as households)",
        zero = "Settlers + slaves (slaves as households with zero assets)", sheep12 = "Settlers + slaves (slaves with 12 sheep/year)")
for (k in names(sc)) for (yr in seq(1680, 1820, 20))
  add(sprintf("F2_%s_%d", k, yr), f2$gini[f2$scenario == sc[k] & f2$period == yr], "Fig 2 two-decade period; total_value = unweighted sum of raw quantities")
g <- function(k, yr) f2$gini[f2$scenario == sc[k] & f2$period == yr]
add("txt_p5_zero_gini", g("zero", 1780), sprintf("zero-asset scenario, period 1780 (1760: %.3f, 1800: %.3f); settlers-only 1780 = %.3f", g("zero", 1760), g("zero", 1800), g("settlers", 1780)))
s12 <- sapply(c(1760, 1780, 1800), function(y) g("sheep12", y))
add("txt_p5_12sheep_lo", min(s12), "12-sheep scenario, min over periods 1760-1800")
add("txt_p5_12sheep_hi", max(s12), "12-sheep scenario, max over periods 1760-1800")
add("txt_p5_slave_value", 200, "hard-coded constant, line 1179")

## 1825 cross-section
add("txt_p5_n1825", H("n1825_filtered"), "rows with settler_men==1 | settler_women==1 (line 2138); after wheat_sown<=100 filter used for Fig 3: 10417")
add("txt_p3_hh1825", H("n1825_filtered"), "as txt_p5_n1825")
dp <- H("districts_pre")
add("txt_p3_districts1825", nrow(dp$district_counts), "districts read")
add("txt_p3_sd_share1825", 100 * dp$district_counts$num_observations[dp$district_counts$district == "district_sb"] / dp$n,
    "derived from district_counts (pre-filter rows). The code's own stellenbosch_share (line 2127) returns 0: it tests district=='Stellenbosch' before relabelling")
f3 <- H("fig3")
dn <- c(albany = "Albany", beaufort = "Beaufort", cape = "Cape", clanwilliam = "Clanwilliam", cradock = "Cradock", george = "George",
        graaffreinet = "Graaff-Reinet", stellenbosch = "Stellenbosch", swellendam = "Swellendam", uitenhage = "Uitenhage", worcester = "Worcester")
for (a in c("Cattle", "Horses", "Oxen", "Sheep", "Wheat", "Wine")) for (d in names(dn)) {
  id <- sprintf("F3_%s_%s", tolower(a), d)
  if (id %in% claims$claim_id) add(id, f3$gini[f3$asset == a & f3$district == dn[d]],
    if (a == "Wheat") "Fig 3 'Wheat' = wheat_sown" else if (a == "Sheep") "Fig 3 'Sheep' = sheep_breeding only" else if (a == "Cattle") "Fig 3 'Cattle' = cattle_breeding" else "")
}
f3x <- f3 |> filter(!(district == "Albany" & asset == "Wine"), !is.nan(gini))
add("txt_p5_district_min", min(f3x$gini), sprintf("min district Gini excl. Albany wine (%s)", paste(f3x$district[which.min(f3x$gini)], f3x$asset[which.min(f3x$gini)])))
add("txt_p5_wine_min", min(f3x$gini[f3x$asset == "Wine"]), "min wine Gini")

## Fig 4 probates. The legend maps labels positionally: values named horses, cattle, sheep, plough, wagon
## get labels Cattle, Horses, Sheep, Ploughs, Wagons, so the printed 'Cattle' line is horses_gini and vice versa.
f4 <- H("fig4")
lab <- c(cattle = "horses_gini", horses = "cattle_gini", sheep = "sheep_gini", ploughs = "plough_gini", wagons = "wagon_gini")
for (a in names(lab)) for (yr in seq(1700, 1830, 10))
  add(sprintf("F4_%s_%d", a, yr), f4[[lab[a]]][f4$period == yr],
      sprintf("value of the line the code's legend labels '%s' = %s%s", a, lab[a], if (a %in% c("cattle", "horses")) " (LABEL SWAP: variable and legend disagree)" else ""))
add("txt_p5_nprobates", H("n_probates"), "probates with 1700<=year<=1839")
f4l <- f4 |> pivot_longer(-period)
add("txt_p5_probate_min", min(f4l$value), "min probate Gini, all assets/periods")
add("txt_p5_probate_min1770", min(f4l$value[f4l$period >= 1770]), "min probate Gini from 1770")

## Fig 5 Slave Emancipation data (lines 2971-3116). Gini is over individual slave rows, not per owner.
sed <- H("sed"); f5 <- H("fig5")
add("txt_p6_nslave", sed$n, "rows of Slave Emancipation Dataset")
add("txt_p3_enslaved1834", sed$n, "rows of Slave Emancipation Dataset (text says 'over 37 000')")
add("txt_p3_enslaved_sd", sed$bydist$n[sed$bydist$District_name == "Stellenbosch"], "Stellenbosch district rows in SED")
add("txt_p6_nonowners", H("fig5_newsettlers")$n_new, "zero-asset settlers added = ceiling(owners*100/30) - owners per district")
add("txt_p6_owner_share", 30, "hard-coded constant 30% (line 3041)")
dn5 <- c(cape = "Cape", stellenbosch = "Stellenbosch", worcester = "Worcester", uitenhage = "Uitenhage", somerset = "Somerset",
         albany = "Albany", graaffreinet = "Graaff Reinet", george = "George", beaufort = "Beaufort")
ty <- c(owners = "Excluding non–slave-owning settlers", all = "Including non–slave-owning settlers")
for (t in names(ty)) for (d in names(dn5)) {
  r <- f5 |> filter(type == ty[t], District_name == dn5[d])
  nt <- if (d %in% c("albany", "george", "graaffreinet", "beaufort")) "district labels ambiguous in printed figure (see claims_spec e.8)" else ""
  add(sprintf("F5_%s_val_%s", t, d), r$valuation_gini, nt)
  add(sprintf("F5_%s_comp_%s", t, d), r$compensation_gini, nt)
}
fo <- f5 |> filter(type == ty["owners"]); fa <- f5 |> filter(type == ty["all"], !is.nan(valuation_gini))
add("txt_p6_val_lo", min(fo$valuation_gini, na.rm = TRUE), "owners only, min valuation Gini (Somerset 0.2905, Uitenhage 0.2911)")
add("txt_p6_val_hi", max(fo$valuation_gini, na.rm = TRUE), "owners only, max valuation Gini (Worcester)")
add("txt_p6_comp_lo", fo$compensation_gini[fo$District_name == "Somerset"], sprintf("Somerset; overall min of 11 districts = %.3f (%s)", min(fo$compensation_gini), fo$District_name[which.min(fo$compensation_gini)]))
add("txt_p6_comp_hi", max(fo$compensation_gini), "max compensation Gini (Cape)")
add("txt_p6_valall_lo", min(fa$valuation_gini), "incl. non-owners, min valuation (Stellenbosch)")
add("txt_p6_valall_hi", max(fa$valuation_gini), "incl. non-owners, max valuation (Beaufort)")
add("txt_p7_compall_lo", min(fa$compensation_gini), "incl. non-owners, min compensation over the 9 plotted districts (Somerset)")
add("txt_p7_compall_hi", max(fa$compensation_gini), "incl. non-owners, max compensation (Cape)")

## Fig 6 Khoe settlements
f6 <- H("fig6"); kc <- H("khoe_counts")
an <- c(cattle = "Cattle", horses = "Horses", oxen = "Oxen", sheep = "Sheep", wheat = "Wheat reaped")
for (a in names(an)) for (s in c("bethelsdorp", "groenekloof", "swartrivier")) {
  id <- sprintf("F6_%s_%s", a, s)
  if (id %in% claims$claim_id) add(id, f6$gini[f6$asset == an[a] & tolower(f6$region) == s])
}
add("txt_p8_beth_cattle", f6$gini[f6$asset == "Cattle" & f6$region == "Bethelsdorp"])
f6x <- f6 |> filter(!is.na(gini), !(asset == "Cattle" & region == "Bethelsdorp"))
add("txt_p8_khoe_min", min(f6x$gini), "min of other Khoe-settlement Ginis (Groenekloof horses)")
add("txt_p7_beth_hh", kc$bd, "nrow of EBTstation 'Bethelsdorp1825' sheet")
add("txt_p7_swart_hh", kc$sr, "nrow Swartrivier")
add("txt_p7_groen_hh", kc$gk, "nrow Groenekloof")
add("txt_p8_beth_sheep", kc$sheep_bd, "households with sheep_breeding>0")
add("txt_p8_groen_sheep", kc$sheep_gk, "households with sheep>0")
sw <- H("swellendam_combined")
add("txt_p8_comb_cattle", sw$combined_ginis$gini_cattle, sprintf("'combined' Swellendam Gini: settler rows = %d (filter district=='district_sw' after relabelling), Khoe rows = %d", sw$n_settlers, sw$n_khoe))
add("txt_p8_comb_other", min(sw$combined_ginis$gini_horses, sw$combined_ginis$gini_oxen, sw$combined_ginis$gini_wheat), "min of horses/oxen/wheat_sown 'combined' Ginis (Khoe rows only)")

res <- bind_rows(out)
stopifnot(!anyDuplicated(res$claim_id), all(res$claim_id %in% claims$claim_id))
# Claims the code does not compute: cited literature, source descriptions, constants not in code
miss <- setdiff(claims$claim_id, res$claim_id)
res <- bind_rows(res, tibble(claim_id = miss, source = "original", value = NA_real_, se = NA_real_, n = NA_real_,
  status_override = "unavailable",
  note = ifelse(grepl("^txt_p[12]_|alvaredo", miss), "cited literature value; not computed by the code",
                "not computed by the surviving code (source description, constant or interpretive bound)")))
res <- res |> arrange(match(claim_id, claims$claim_id))
write_csv(res, file.path(p, "repro_original", "results_original.csv"), na = "")
cat("rows:", nrow(res), " computed:", sum(!is.na(res$value)), "\n")
