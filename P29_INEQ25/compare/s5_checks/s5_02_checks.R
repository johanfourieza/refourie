# S5 verification checks for P29_INEQ25 (Fourie 2025, SAJS).
# Reads the objects saved by s5_01_run_original.R (re-run of the patched original script, lines 1-3174)
# and the S2 hooks; reproduces each published quantity first (baseline = original code), then applies
# the single fix named in each check. Writes P29_INEQ25/compare/s5_effects.csv and a log.
# Run from project root: Rscript P29_INEQ25/compare/s5_checks/s5_02_checks.R
suppressPackageStartupMessages({library(dplyr); library(tidyr); library(readr); library(ineq); library(purrr); library(readxl)})
source("tools/paths.R")
S <- dscratch("P29_INEQ25", "compare")
R <- function(k) readRDS(file.path(S, "obj", paste0(k, ".rds")))
H <- function(k) readRDS(file.path(S, "hooks", paste0(k, ".rds")))
set.seed(20251126)
eff <- list()
add <- function(id, finding, quantity, published, original_code, corrected, note = "")
  eff[[length(eff) + 1]] <<- tibble(check_id = id, finding_id = finding, quantity = quantity,
                                    published = as.character(published), original_code = round(as.numeric(original_code), 4),
                                    corrected = round(as.numeric(corrected), 4), delta = round(as.numeric(corrected) - as.numeric(original_code), 4), note = note)
G <- function(x) ineq::Gini(x, na.rm = TRUE)
rng <- function(x) sprintf("%.3f-%.3f", min(x, na.rm = TRUE), max(x, na.rm = TRUE))

prices <- R("prices")
o <- as_tibble(R("opgaaf_save2"))   # opgaaf after 19-row outlier removal (line ~305), 142,274 rows
vars6 <- c("horses", "cattle", "sheep", "wheat_vol", "vines", "wine")

## ---------------------------------------------------------------- Fig 1 (F1, F2-candidates 4/5)
dec <- function(y) ifelse(y >= 1680 & y < 1840, (y %/% 10) * 10, NA)
f1 <- o |> mutate(across(all_of(vars6), ~ ifelse(is.na(.x), 0, .x)), period = dec(year)) |>
  left_join(prices, by = "period", suffix = c("", ".p")) |>
  mutate(cattle_value = cattle * cattle_breeding, sheep_value = sheep * sheep.p, horses_value = horses * horses.p,
         wheat_value = wheat_vol * wheat_vol.p, wine_value = wine * wine.p,
         tv = cattle_value + sheep_value + horses_value + wheat_value + wine_value) |>
  filter(!is.na(tv))
base1 <- f1 |> group_by(period) |> summarise(g = G(tv), .groups = "drop")
ps <- H("pre_slaves")$gini_total_production
stopifnot(isTRUE(all.equal(base1$g, ps$gini_total_value[match(base1$period, ps$period)])))
lin <- H("fig1_linear") |> filter(variable == "total_value")
p18 <- function(d) d$period >= 1700 & d$period <= 1790
add("C01", "S5-04", "Fig 1 total-value Gini, decades 1700-1830 (range)", "0.66-0.83 (digitised)", NA, NA,
    sprintf("author-instructed state (line 694) = %s; top-to-bottom run (line 962 overwrite, 12-sheep slave households) = %s",
            rng(ps$gini_total_value[ps$period >= 1700]), rng(lin$gini[lin$year >= 1700])))
add("C01b", "S5-04", "Fig 1 total-value Gini, 1780 decade", "0.73 (digitised)", ps$gini_total_value[ps$period == 1780], lin$gini[lin$year == 1780],
    "original = author-instructed state; corrected column = what a top-to-bottom run plots")
# vines valued at one year's wine yield per vine (decade aggregate wine/vines x wine price); cattle at mean of three cattle prices
vp <- f1 |> group_by(period) |> summarise(wpv = sum(wine) / sum(vines), .groups = "drop")
f1v <- f1 |> left_join(vp, by = "period") |>
  mutate(vines_value = vines * wpv * wine.p,
         cattle_value2 = cattle * (cattle_breeding + cattle_bull + cattle_work) / 3)
s_v <- f1v |> group_by(period) |> summarise(g = G(tv + vines_value), g_c = G(tv - cattle_value + cattle_value2), .groups = "drop")
add("C02", "S5-05", "Fig 1 total value 18th c. range (1700-1790): six assets incl. vines", "0.6-0.75", NA, NA,
    sprintf("code (5 assets) %s; + vines valued at decade wine-yield-per-vine x wine price %s; cattle at mean of breeding/bull/work price %s",
            rng(base1$g[p18(base1)]), rng(s_v$g[p18(s_v)]), rng(s_v$g_c[p18(s_v)])))
add("C02b", "S5-05", "Fig 1 total value, max abs change over decades 1690-1830 from adding vines", "", 0, max(abs(s_v$g - base1$g)), "sensitivity; vines have no price in price_series.xlsx")
# averaging annual Ginis (caption says 'averaged') instead of pooling household-years within a decade
ann <- f1 |> group_by(year, period) |> summarise(g = G(tv), .groups = "drop") |> group_by(period) |> summarise(g = mean(g), .groups = "drop")
add("C03", "S5-14", "Fig 1 total value: mean of annual Ginis vs decade-pooled Gini, max abs diff", "", 0, max(abs(ann$g - base1$g)),
    sprintf("pooled 1700-1790 %s; mean-of-annual 1700-1790 %s", rng(base1$g[p18(base1)]), rng(ann$g[p18(ann)])))

## ---------------------------------------------------------------- Fig 2 (S5-06, S5-07)
p20 <- function(y) ifelse(y >= 1680 & y < 1840, 1680 + ((y - 1680) %/% 20) * 20, NA)
o2 <- o |> mutate(across(c(all_of(vars6), "slave_men", "slave_women", "slave_sons", "slave_daughters", "settler_men"),
                         ~ ifelse(is.na(.x), 0, as.numeric(.x))), period = p20(year), dperiod = dec(year))
nslave_rows <- o2 |> filter(slave_men > 0) |> group_by(year, period, dperiod) |> summarise(n = sum(slave_men), .groups = "drop")
srows <- nslave_rows |> uncount(n) |> mutate(horses = 0, cattle = 0, sheep = 0, wheat_vol = 0, vines = 0, wine = 0,
                                             settler_men = 0, slave_men = 0, slave_women = 0, slave_sons = 0, slave_daughters = 0)
pr <- prices |> transmute(dperiod = period, p_h = horses, p_c = cattle_breeding, p_s = sheep, p_w = wheat_vol, p_wi = wine)
val <- function(d) d |> left_join(pr, by = "dperiod") |>
  mutate(v = horses * p_h + cattle * p_c + sheep * p_s + wheat_vol * p_w + wine * p_wi)
raw <- function(d) d |> mutate(v = horses + cattle + sheep + wheat_vol + vines + wine)
slv <- function(d) d$slave_men + d$slave_women + d$slave_sons + d$slave_daughters
fig2 <- function(f, base_all = FALSE, valued = FALSE, ann_avg = FALSE) {
  st <- if (base_all) o2 else filter(o2, settler_men > 0)
  agg <- function(d) {
    d <- filter(d, !is.na(period), !is.na(v))
    if (ann_avg) d |> group_by(period, year) |> summarise(g = G(v), .groups = "drop") |> group_by(period) |> summarise(g = mean(g), .groups = "drop")
    else d |> group_by(period) |> summarise(g = G(v), .groups = "drop")
  }
  s1 <- f(st)
  s2 <- f(st) |> mutate(v = v + (if (valued) 200 * p_s else 200) * slv(st))
  z  <- f(bind_rows(o2, srows))
  sh <- bind_rows(o2, srows |> mutate(sheep = 12)) |> f()
  bind_rows(agg(s1) |> mutate(s = "settlers"), agg(s2) |> mutate(s = "slaveassets"),
            agg(z) |> mutate(s = "zero"), agg(sh) |> mutate(s = "sheep12"))
}
f2_code <- fig2(raw)
h2 <- H("fig2") |> filter(!is.na(period)) |>
  mutate(s = recode(scenario, "Settlers only (no slaves)" = "settlers", "Settlers + slave assets (slaves not as households)" = "slaveassets",
                    "Settlers + slaves (slaves as households with zero assets)" = "zero", "Settlers + slaves (slaves with 12 sheep/year)" = "sheep12"))
chk <- inner_join(f2_code, h2, by = c("period", "s"))
stopifnot(nrow(chk) == 32, max(abs(chk$g - chk$gini)) < 1e-9)
f2_val  <- fig2(val, valued = TRUE)                        # price-weighted, same populations as code
f2_valA <- fig2(val, valued = TRUE, base_all = TRUE)       # price-weighted, consistent base (all census rows)
f2_valY <- fig2(val, valued = TRUE, ann_avg = TRUE)        # price-weighted, mean of annual Ginis (rebuild's aggregation)
f2_rawA <- fig2(raw, base_all = TRUE)
vshare <- o2 |> filter(settler_men > 0) |> raw() |> filter(v > 0) |> summarise(s = sum(vines) / sum(v), m = median(vines / v))
gp <- function(d, s, p) d$g[d$s == s & d$period == p]
for (sc in c("settlers", "slaveassets", "zero", "sheep12")) for (p in seq(1680, 1820, 20))
  add(sprintf("F2_%s_%d", sc, p), "S5-06", sprintf("Fig 2 %s, period %d", sc, p), "", gp(f2_code, sc, p), gp(f2_val, sc, p),
      sprintf("corrected = price-weighted 5-asset basket (as Fig 1), slave asset 200 x sheep price, 12 sheep x sheep price; consistent-base variant %.3f; mean-of-annual variant %.3f",
              gp(f2_valA, sc, p), gp(f2_valY, sc, p)))
add("C04", "S5-06", "Vines share of the raw Fig 2 'total_value' (settler households)", "", vshare$s, NA,
    sprintf("aggregate share; median household share %.2f", vshare$m))
lt <- function(d, s, ps) rng(d$g[d$s == s & d$period %in% ps])
add("C05", "S5-07", "Text p.5: zero-asset scenario 'reaching 0.92 by the late 18th c.' (1780 period)", "0.92", gp(f2_code, "zero", 1780), gp(f2_val, "zero", 1780),
    sprintf("plotted (raw units) %.3f; price-weighted pooled %.3f; price-weighted mean-of-annual %.3f (rebuild 0.923); raw-unit settlers-only %.3f",
            gp(f2_code, "zero", 1780), gp(f2_val, "zero", 1780), gp(f2_valY, "zero", 1780), gp(f2_code, "settlers", 1780)))
add("C06", "S5-07", "Text p.5: 12-sheep scenario 'hovering around 0.89 to 0.91' (periods 1760-1800)", "0.89-0.91", NA, NA,
    sprintf("plotted raw %s; price-weighted pooled %s; price-weighted mean-of-annual %s; raw settlers-only %s; raw slave-assets %s",
            lt(f2_code, "sheep12", c(1760, 1780, 1800)), lt(f2_val, "sheep12", c(1760, 1780, 1800)), lt(f2_valY, "sheep12", c(1760, 1780, 1800)),
            lt(f2_code, "settlers", c(1740, 1760, 1780, 1800)), lt(f2_code, "slaveassets", c(1760, 1780, 1800))))
b12 <- H("basket12")
add("C06b", "S5-07", "Price-weighted 12-sheep basket of lines 855-990 (decades 1760-1790), all rows", "0.89-0.91", NA, NA,
    sprintf("gini_total_value %s; its 'settler_men>0' subset (which includes the added slave rows, settler_men=1) %s",
            rng(b12$gini_total_value[b12$period %in% 1760:1790]), rng(b12$gini_settler_value[b12$period %in% 1760:1790])))
# within-group vs overall (intro claim)
add("C07", "interp", "Intro: settler within-group Gini 'as large as the overall Gini' (1780 period, settlers vs zero-asset overall)", "as large as",
    gp(f2_code, "zero", 1780) - gp(f2_code, "settlers", 1780), gp(f2_val, "zero", 1780) - gp(f2_val, "settlers", 1780),
    sprintf("gap overall-minus-settlers; code (raw): %.3f vs %.3f; price-weighted: %.3f vs %.3f; consistent base: %.3f vs %.3f",
            gp(f2_code, "zero", 1780), gp(f2_code, "settlers", 1780), gp(f2_val, "zero", 1780), gp(f2_val, "settlers", 1780),
            gp(f2_valA, "zero", 1780), gp(f2_valA, "settlers", 1780)))
f2gap <- f2_val |> pivot_wider(names_from = s, values_from = g) |> mutate(gap = zero - settlers)
add("C07b", "interp", "Price-weighted Fig 2: zero-asset minus settlers-only, all periods 1680-1820 (range)", "", NA, NA,
    sprintf("gap %s; settlers %s; zero %s; 12-sheep %s", rng(f2gap$gap), rng(f2gap$settlers), rng(f2gap$zero), rng(f2gap$sheep12)))

## ---------------------------------------------------------------- Top shares (S5-11)
ts <- function(x) { x <- sort(x[!is.na(x)], decreasing = TRUE); n <- length(x); t <- sum(x)
  c(t1 = sum(x[1:ceiling(n * .01)]) / t, t01 = sum(x[1:ceiling(n * .001)]) / t, t001 = sum(x[1:ceiling(n * .0001)]) / t) * 100 }
tsd <- function(d, by) d |> group_by(across(all_of(by))) |> reframe(tibble::as_tibble_row(ts(v)))
st_p <- f1 |> mutate(v = tv) |> tsd("period")
st_y <- f1 |> mutate(v = tv) |> tsd(c("year", "period")) |> group_by(period) |> summarise(across(c(t1, t01, t001), mean))
st_set <- f1 |> filter(settler_men > 0) |> mutate(v = tv) |> tsd("period")
st_raw <- o2 |> filter(settler_men > 0) |> raw() |> mutate(period = dperiod) |> filter(!is.na(period)) |> tsd("period")
tsl <- H("topshares_linear")$a |> mutate(across(-period, ~ .x * 100))
m19 <- function(d, v) mean(d[[v]][d$period >= 1800 & d$period <= 1830])
m18 <- function(d, v) mean(d[[v]][d$period >= 1700 & d$period < 1800])
mall <- function(d, v) mean(d[[v]][!is.na(d$period)])
for (cand in list(list("decade-pooled, pre-slave state (code, author order)", st_p), list("mean of annual shares", st_y),
                  list("settler_men>0 only", st_set), list("raw-unit sum (Fig 2 measure), settlers", st_raw),
                  list("top-to-bottom state (12-sheep slave households)", tsl)))
  add(paste0("C08_", substr(gsub("[^a-z]", "", cand[[1]]), 1, 12)), "S5-11", paste("Top shares:", cand[[1]]), "12 / 18 / 2->3.7 / 0.5->0.8",
      m19(cand[[2]], "t1"), NA,
      sprintf("top1 all %.1f, 1800-30 %.1f; top0.1 18c %.1f, 19c %.1f; top0.01 18c %.2f, 19c %.2f", mall(cand[[2]], "t1"), m19(cand[[2]], "t1"),
              m18(cand[[2]], "t01"), m19(cand[[2]], "t01"), m18(cand[[2]], "t001"), m19(cand[[2]], "t001")))
add("C08_maxdec", "S5-11", "Top-1% share, highest decade 1690-1830 (pre-slave state)", "about 18 (1800-1830 mean)", max(st_p$t1[!is.na(st_p$period)]), NA,
    sprintf("decade %d; R1 response to referees: 'between 9%% and 12%% ... only after the 1810s does this share rise sharply'", st_p$period[which.max(st_p$t1)]))

## ---------------------------------------------------------------- Counts (S5-12)
n_year <- H("n_year"); n_after <- H("n_after_outliers"); ny <- H("obs_avgs")$obs_per_year
cands <- c(rows_with_year = n_year, after_outliers = n_after, settler_men_pos = sum(o$settler_men > 0, na.rm = TRUE),
           fig1_priced_rows = nrow(f1), le1840 = sum(o$year < 1840), year_1685_1844 = sum(o$year >= 1685 & o$year <= 1844))
add("C09", "S5-10", "Observations (text 142,219)", "142219", n_after, NA,
    paste(sprintf("%s=%d", names(cands), cands), collapse = "; "))
add("C10", "S5-10", "Number of annual censuses (text 159)", "159", nrow(ny), NA,
    sprintf("distinct years %d-%d; 1844-1685 = 159 is the span; mean rows/year %.1f", min(ny$year), max(ny$year), mean(ny$num_obs)))

## ---------------------------------------------------------------- Khoe + settler combined (S5-01)
ad <- R("all_districts"); gk <- R("district_gk"); sr <- R("district_sr")
khoe <- bind_rows(sr, gk) |> select(horses, cattle_oxen, cattle_breeding, sheep_breeding, wheat_sown, wheat_reaped)
cg <- R("combined_ginis")
sw <- ad |> filter(district == "Swellendam")
stopifnot(sum(ad$district == "district_sw") == 0)
comb <- bind_rows(sw |> select(names(khoe)), khoe)
fx <- function(d) c(horses = G(d$horses), oxen = G(d$cattle_oxen), cattle = G(d$cattle_breeding), wheat = G(d$wheat_sown), wheat_reaped = G(d$wheat_reaped))
gc <- fx(comb); gkh <- fx(khoe); gsw <- fx(sw)
for (a in c("cattle", "horses", "oxen", "wheat"))
  add(paste0("C11_", a), "S5-01", sprintf("Khoe + settler combined Gini, %s (Groenekloof+Swartrivier+Swellendam)", a),
      ifelse(a == "cattle", "0.92", ">0.77"), cg[[paste0("gini_", a)]], gc[[a]],
      sprintf("code = Khoe only (n=%d, 0 settlers: filter 'district_sw' after relabel); corrected adds %d Swellendam settler households; Khoe-only %.3f, Swellendam settlers-only %.3f",
              nrow(khoe), nrow(sw), gkh[[a]], gsw[[a]]))
add("C11_wheatreaped", "S5-01", "Combined Gini, wheat reaped (paper's Khoe asset is wheat reaped; code uses wheat sown)", ">0.77", NA, gc[["wheat_reaped"]], "")
# per-settlement means for the 'rises sharply' claim
mw <- c(settlers = mean(sw$cattle_breeding), khoe = mean(khoe$cattle_breeding))
add("C11_means", "S5-01", "Mean breeding cattle per household: Swellendam settlers vs Khoe (GK+SR)", "settlers 'significantly wealthier'", NA, NA,
    sprintf("settlers %.1f, Khoe %.1f", mw[1], mw[2]))

## ---------------------------------------------------------------- Fig 4 (S5-02, S5-15)
pb <- R("probates"); g4 <- R("gini_by_period")
fp <- R("fig4_plot"); bb <- ggplot2::ggplot_build(fp$plot); sc <- bb$plot$scales$get_scales("colour")
map_now <- paste(sc$get_breaks(), "->", sc$get_labels(), collapse = "; ")
add("C12", "S5-02", "Fig 4 legend mapping (printed figure: 'Cattle' line = horse_nr)", "Cattle 0.90-0.98; Horses 0.67-0.84 (digitised)", NA, NA,
    sprintf("code horses_gini %s, cattle_gini %s; installed ggplot2 %s maps %s; independent rebuild (repro_r P5) also finds published 'cattle' = horse_nr",
            rng(g4$horses_gini), rng(g4$cattle_gini), fp$ggplot2, map_now))
yearlike <- function(v, y) ifelse(!is.na(v) & v >= 1690 & v <= 1845 & abs(v - y) <= 15, NA, v)
pb2 <- pb |> mutate(horse_nr = yearlike(horse_nr, year), cattle_nr = yearlike(cattle_nr, year), sheep_nr = yearlike(sheep_nr, year),
                    plough_nr = yearlike(plough_nr, year), wagon_nr = yearlike(wagon_nr, year))
nyl <- sum(is.na(pb2$horse_nr) & !is.na(pb$horse_nr)) + sum(is.na(pb2$wagon_nr) & !is.na(pb$wagon_nr)) + sum(is.na(pb2$cattle_nr) & !is.na(pb$cattle_nr))
g4b <- pb2 |> group_by(period) |> summarise(h = G(horse_nr), c = G(cattle_nr), s = G(sheep_nr), p = G(plough_nr), w = G(wagon_nr), .groups = "drop")
for (p in c(1770, 1820, 1830)) {
  add(sprintf("C13_h%d", p), "S5-15", sprintf("Probate horse_nr Gini (printed as 'Cattle'), decade %d", p), "", g4$horses_gini[g4$period == p], g4b$h[g4b$period == p],
      sprintf("%d year-like values (e.g. horse_nr 1821-1831, wagon_nr 1776/1832) set to NA", nyl))
  add(sprintf("C13_w%d", p), "S5-15", sprintf("Probate wagon_nr Gini, decade %d", p), "", g4$wagon_gini[g4$period == p], g4b$w[g4b$period == p], "")
}
add("C13_min", "S5-15", "Probate Ginis: min over 5 assets x decades (text: >0.6; >0.7 from 1770)", ">0.6 / >0.7", min(as.matrix(g4[, -1])), min(as.matrix(g4b[, -1])),
    sprintf("min from 1770: code %.3f, corrected %.3f", min(as.matrix(g4[g4$period >= 1770, -1])), min(as.matrix(g4b[g4b$period >= 1770, -1]))))

## ---------------------------------------------------------------- Fig 5 (S5-03)
sed <- R("sed") |> mutate(owner = paste(Owner_name, Owner_surname, sep = " "))
add_n <- R("settlers_to_add_per_district")
own <- sed |> group_by(District_name, owner) |>
  summarise(val = if (all(is.na(Valuation))) NA_real_ else sum(Valuation, na.rm = TRUE),
            comp = if (all(is.na(Compensation))) NA_real_ else sum(Compensation, na.rm = TRUE),
            ncomp = sum(!is.na(Compensation)), nsl = n(), .groups = "drop")
f5c <- R("gini_combined_all")
o5 <- own |> group_by(District_name) |> summarise(val_own = G(val), comp_own = G(comp), n_own = n(), n_val = sum(!is.na(val)), .groups = "drop") |>
  left_join(add_n |> select(District_name, settlers_to_add), by = "District_name")
z5 <- function(x, k) G(c(x[!is.na(x)], rep(0, k)))
o5 <- o5 |> rowwise() |> mutate(
  val_all = z5(own$val[own$District_name == District_name], settlers_to_add),
  comp_all = z5(own$comp[own$District_name == District_name], settlers_to_add)) |> ungroup()
# alternative non-owner count: district slave-owning share of 1825 settler households (Somerset uses Graaff-Reinet)
sh25 <- ad |> mutate(own = (slaves_men + slaves_women + slaves_sons + slaves_daughters) > 0) |> group_by(district) |> summarise(s = mean(own))
sh25 <- bind_rows(sh25, tibble(district = "Somerset", s = sh25$s[sh25$district == "Graaff-Reinet"])) |> mutate(District_name = recode(district, "Graaff-Reinet" = "Graaff Reinet"))
o5 <- o5 |> left_join(sh25 |> select(District_name, s), by = "District_name") |> rowwise() |>
  mutate(k25 = round(n_own * (1 - s) / s),
         val_all25 = z5(own$val[own$District_name == District_name], k25),
         comp_all25 = z5(own$comp[own$District_name == District_name], k25)) |> ungroup()
cb <- f5c |> filter(grepl("Excluding", type)); ca <- f5c |> filter(grepl("Including", type))
o5 <- o5 |> left_join(cb |> select(District_name, v0 = valuation_gini, c0 = compensation_gini), by = "District_name") |>
  left_join(ca |> select(District_name, v1 = valuation_gini, c1 = compensation_gini), by = "District_name")
pl <- o5 |> filter(!is.na(v0), !is.na(val_own))
add("C14_valown", "S5-03", "Fig 5 valuation Gini, owners only (range over 9 districts)", "0.29-0.47", NA, NA,
    sprintf("code (over enslaved individuals) %s; owner-level (sum of valuations per owner) %s", rng(pl$v0), rng(pl$val_own)))
add("C14_compown", "S5-03", "Fig 5 compensation Gini, owners only (range)", "0.45-0.55", NA, NA,
    sprintf("code %s; owner-level %s (compensation is recorded once per owner: max entries per owner = %d, share of owners with >1 entry = %.3f)",
            rng(pl$c0), rng(pl$comp_own), max(own$ncomp), mean(own$ncomp > 1)))
add("C14_valall", "S5-03", "Fig 5 valuation Gini incl. 13,033 non-owners (range)", "0.49-0.75", NA, NA,
    sprintf("code (zero owner rows appended to slave-level rows) %s; owner-level, same 30%% rule %s; owner-level, 1825 district ownership shares %s",
            rng(pl$v1), rng(pl$val_all), rng(pl$val_all25)))
add("C14_compall", "S5-03", "Fig 5 compensation Gini incl. non-owners (range)", "0.83-0.92", NA, NA,
    sprintf("code %s; owner-level, 30%% rule %s; 1825 district shares %s (share owning slaves in 1825: %s)",
            rng(pl$c1), rng(pl$comp_all), rng(pl$comp_all25), paste(sprintf("%s %.2f", sh25$district, sh25$s), collapse = ", ")))
for (i in seq_len(nrow(pl))) {
  d <- pl$District_name[i]; k <- tolower(gsub(" ", "", d))
  add(sprintf("F5_owners_val_%s", k), "S5-03", sprintf("Fig 5 owners-only valuation, %s", d), "", pl$v0[i], pl$val_own[i], "")
  add(sprintf("F5_all_val_%s", k), "S5-03", sprintf("Fig 5 incl. non-owners valuation, %s", d), "", pl$v1[i], pl$val_all[i], sprintf("1825-share variant %.3f", pl$val_all25[i]))
  add(sprintf("F5_all_comp_%s", k), "S5-03", sprintf("Fig 5 incl. non-owners compensation, %s", d), "", pl$c1[i], pl$comp_all[i], sprintf("1825-share variant %.3f", pl$comp_all25[i]))
}
add("C14_n", "S5-03", "Non-owners added (text 13,033)", "13033", sum(add_n$settlers_to_add), NA,
    "= sum over districts of ceiling(owners x 10/3) - owners: produced by the uniform 30% assumption, not an observed count")

## ---------------------------------------------------------------- Fig 6 (S5-08, S5-16)
gb <- R("gini_bubble_data"); f6 <- R("gini_long_with_totals")
bd <- R("district_bd")
tot <- bind_rows(gk |> transmute(region = "Groenekloof", Cattle = cattle_breeding, Horses = horses, Oxen = cattle_oxen, Sheep = sheep, `Wheat reaped` = wheat_reaped),
                 sr |> transmute(region = "Swartrivier", Cattle = cattle_breeding, Horses = horses, Oxen = cattle_oxen, `Wheat reaped` = wheat_reaped),
                 bd |> transmute(region = "Bethelsdorp", Cattle = cattle_breeding, Horses = horses, Oxen = cattle_oxen, Sheep = sheep_breeding)) |>
  pivot_longer(-region, names_to = "asset") |> group_by(region, asset) |> summarise(true_total = sum(value, na.rm = TRUE), .groups = "drop")
cmp <- gb |> left_join(tot, by = c("region", "asset")) |> filter(!is.na(gini))
add("C15", "S5-08", "Fig 6 bubble size: runif totals vs actual totals (Spearman)", "size = totals (implied by Fig 3 note)", NA,
    cor(cmp$total, cmp$true_total, method = "spearman"), "line 2818 total = runif(1, 100, 10000), no seed; any re-run draws new sizes")
b14 <- read_excel(file.path(S, "run", "EBTstation.xlsx"), sheet = "Bethelsdorp") |>
  mutate(across(c(horseM, horseF, cattleM, cattleF, sheep_goats), as.numeric), horses = horseM + horseF)
g14 <- c(Cattle = G(b14$cattleF), Horses = G(b14$horses), Oxen = G(b14$cattleM), Sheep = G(b14$sheep_goats))
for (a in names(g14)) add(paste0("C16_", tolower(a)), "S5-16", sprintf("Fig 6 Bethelsdorp %s: code sheet 'Bethelsdorp1825' (611 rows) vs 1814 sheet (425 rows) described in text", a),
                          "", f6$gini[f6$region == "Bethelsdorp" & f6$asset == a], g14[[a]], "corrected = same code definitions on the 1814 sheet")
add("C16_min", "S5-16", "Khoe settlements: min Gini excluding Bethelsdorp cattle (text: all others >0.75)", ">0.75", NA, NA,
    sprintf("code (1825 sheet) min %.3f; with 1814 Bethelsdorp min %.3f; Bethelsdorp cattle 1825 %.3f / 1814 %.3f",
            min(f6$gini[!(f6$region == "Bethelsdorp" & f6$asset == "Cattle")], na.rm = TRUE),
            min(c(f6$gini[f6$region != "Bethelsdorp"], g14[names(g14) != "Cattle"]), na.rm = TRUE),
            f6$gini[f6$region == "Bethelsdorp" & f6$asset == "Cattle"], g14[["Cattle"]]))

## ---------------------------------------------------------------- Fig 3 pair-B diagnostics
sh_alt <- ad |> group_by(district) |> summarise(code = G(sheep_breeding), all3 = G(sheep_wethers + sheep_breeding + sheep_spanish),
                                                max_cattle = max(cattle_breeding), n = n(), .groups = "drop")
add("C17", "pairB", "Fig 3 sheep: breeding-only (code) vs wethers+breeding+Spanish (rebuild) per district", "", NA, NA,
    paste(sprintf("%s %.2f/%.2f", sh_alt$district, sh_alt$code, sh_alt$all3), collapse = "; "))
add("C17b", "pairB", "Fig 3 Uitenhage max breeding cattle after code's settler filter", "", max(sh_alt$max_cattle[sh_alt$district == "Uitenhage"]), NA,
    "the 9,814,068-cattle row in the raw sheet is removed by the code's 'settler_men==1|settler_women==1' row filter, not by trimming")

out <- bind_rows(eff)
write_csv(out, "P29_INEQ25/compare/s5_effects.csv", na = "")
print(as.data.frame(out |> filter(!grepl("^F[25]_", check_id))), right = FALSE)
cat("\nFig 2 grid (code raw / price-weighted / consistent base / mean-annual):\n")
print(as.data.frame(f2_code |> rename(raw = g) |> left_join(rename(f2_val, val = g), by = c("period", "s")) |>
  left_join(rename(f2_valA, valAll = g), by = c("period", "s")) |> left_join(rename(f2_valY, valAnn = g), by = c("period", "s")) |>
  mutate(across(where(is.numeric) & !period, ~ round(.x, 3))) |> arrange(s, period)))
print(as.data.frame(o5 |> select(District_name, n_own, v0, val_own, c0, comp_own, v1, val_all, val_all25, c1, comp_all, comp_all25, s) |> mutate(across(where(is.double), ~ round(.x, 3)))))
print(as.data.frame(g4b |> mutate(across(-period, ~ round(.x, 3)))))
print(pb |> filter(is.na(yearlike(horse_nr, year)) & !is.na(horse_nr) | is.na(yearlike(wagon_nr, year)) & !is.na(wagon_nr) | is.na(yearlike(cattle_nr, year)) & !is.na(cattle_nr)) |>
  select(year, horse_nr, cattle_nr, wagon_nr))
