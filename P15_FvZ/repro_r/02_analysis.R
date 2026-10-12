# P15_FvZ S3 recreation -- 02_analysis.R
# Builds population, output components, nominal/real GDP, per-capita series, 1990$ conversion,
# trend growth; writes output/series_annual.csv and repro_r/results_r.csv.
# Every parameter below is documented in decisions.md.
suppressPackageStartupMessages(library(tidyverse))

args <- commandArgs(FALSE)
this <- normalizePath(sub("--file=", "", args[grep("--file=", args)]))
root <- dirname(dirname(this))
out  <- file.path(root, "repro_r", "output")
d    <- read_csv(file.path(out, "clean_annual.csv"), show_col_types = FALSE)
claims <- read_csv(file.path(root, "claims", "claims.csv"), show_col_types = FALSE)

# ---------------- parameters (decisions.md) ----------------
STUIVERS_PER_GUILDER <- 16; GUILDERS_PER_RDS <- 3; AAM_PER_LEGGER <- 3.75
LODGE_SLAVES <- 600; KHOE_ADULT <- 0.6; KHOE_MEN <- 0.3; LODGE_MEN <- 0.6
WHEAT_ADULT <- 2.5; WHEAT_CHILD <- 1.25; WHEAT_SHIP <- 40
WINE_RURAL <- 0.30; WINE_URBAN <- 0.38
K_LIVESTOCK <- 1.5; OFFTAKE_SHEEP <- 0.25; OFFTAKE_CATTLE <- 0.10
LB_SHEEP <- 42; LB_COW <- 300; MEAT_PER_SHIP <- 5000
HORSE_COWS <- 4; VINE_PRICE <- 0.03; LAND_SEED_MULT <- 2
WISSEL_SHARE <- 0.5; VOC_TRADE_VA <- 0.10; BAKER_VA <- 0.10
SLAVE_TRADE_MARGIN <- 0.20; RETAIL_MARKUP <- 1.0
BUILD_URBAN <- 400; BUILD_FARM <- 1000; REST_LF_SHARE <- 0.25
SUBS_WHEAT <- 2.0; SUBS_MEAT <- 20; SUBS_FOOD_SHARE <- 0.70; ADULT_MEN_BAL <- 0.30
USD_PER_1701G <- 1702.7 / 161            # typed: A1_1701_cape / F3_1701_GDPpc
GDP_YEARS <- 1701:1793

interp <- function(x, y) { ok <- !is.na(x); approx(y[ok], x[ok], xout = y, rule = 2)$y }
fdiff  <- function(x) { dx <- c(NA, diff(x)); dx[1] <- dx[2]; dx }   # 1701 uses forward difference

# ---------------- prices ----------------
d <- d %>% mutate(
  p_wheat_raw = ifelse(year %in% 1749:1793 & (exp_grain_mud + replace_na(exp_peas_mud, 0)) > 0 & !is.na(exp_grain_val),
                       exp_grain_val / (exp_grain_mud + replace_na(exp_peas_mud, 0)), NA),
  p_wine_raw  = ifelse(year %in% 1749:1793 & exp_wine_aam > 0 & !is.na(exp_wine_val),
                       exp_wine_val / exp_wine_aam * AAM_PER_LEGGER, NA))
pw0 <- mean(d$p_wheat_raw[d$year %in% 1749:1753], na.rm = TRUE)
pv0 <- mean(d$p_wine_raw[d$year %in% 1749:1753], na.rm = TRUE)
d <- d %>% mutate(
  p_wheat = ifelse(year < 1749, pw0, interp(p_wheat_raw, year)),
  p_wine  = ifelse(year < 1749, pv0, interp(p_wine_raw, year)),
  sheep_price = interp(sheep_stuivers, year) / STUIVERS_PER_GUILDER,   # guilders per sheep
  p_meat  = sheep_price / LB_SHEEP)                                     # guilders per lb

# ---------------- population ----------------
d <- d %>% mutate(
  free = men + women + boys + girls + kn,
  europeans = free + voc_est,
  slaves_opg = slm + slw + slb + slg,
  slaves = slaves_opg + LODGE_SLAVES,
  total = europeans + slaves + khoesan,
  adults = men + women + kn + slm + slw + voc_est + LODGE_SLAVES + KHOE_ADULT * khoesan,
  children = boys + girls + slb + slg + (1 - KHOE_ADULT) * khoesan,
  adult_men = men + kn + slm + voc_est + LODGE_MEN * LODGE_SLAVES + KHOE_MEN * khoesan,
  balanced = adult_men / ADULT_MEN_BAL,
  lf = men + kn + slm + slw + voc_est + LODGE_SLAVES + KHOE_ADULT * khoesan)
sh_lo <- with(d, ct_pop_raw[year == 1706] / total[year == 1706])
sh_hi <- with(d, ct_pop_raw[year == 1791] / total[year == 1791])
d <- d %>% mutate(ct_pop = case_when(year < 1706 ~ sh_lo * total, year > 1791 ~ sh_hi * total, TRUE ~ ct_pop_raw),
                  rural = total - ct_pop)

# ---------------- agriculture ----------------
d <- d %>% mutate(
  exp_grain = ifelse(year < 1706, 0, interp(ifelse(exp_grain_na, NA, exp_grain_mud), year)),
  exp_grain = replace_na(exp_grain, 0),
  wheat_s1 = coef * ((wheat_reaped - wheat_sown) + (barley_reaped - barley_sown) + (rye_reaped - rye_sown)),
  wheat_dom = WHEAT_ADULT * adults + WHEAT_CHILD * children,
  wheat_s2 = wheat_dom + WHEAT_SHIP * ships + exp_grain,
  wheat_q = (wheat_s1 + wheat_s2) / 2,
  wheat_val = wheat_q * p_wheat,
  wine_q = wine_leggers + WINE_RURAL * rural,
  wine_val = wine_q * p_wine,
  meat_ls = K_LIVESTOCK * (OFFTAKE_SHEEP * sheep * LB_SHEEP + OFFTAKE_CATTLE * cattle * LB_COW))
bm <- d %>% filter(year %in% c(1780, 1790))
c_pc <- (mean(bm$meat_ls) - MEAT_PER_SHIP * mean(bm$ships)) / mean(bm$total)   # lb per head per year
d <- d %>% mutate(
  meat_cons = c_pc * total + MEAT_PER_SHIP * ships,
  meat_dom = c_pc * total,
  meat_q = (meat_ls + meat_cons) / 2,
  meat_val = meat_q * p_meat,
  inv_cattle = K_LIVESTOCK * fdiff(cattle) * LB_COW * p_meat,
  inv_sheep  = K_LIVESTOCK * fdiff(sheep) * sheep_price,
  inv_horses = K_LIVESTOCK * fdiff(horses) * HORSE_COWS * LB_COW * p_meat,
  sown_corr  = coef * (wheat_sown + barley_sown + rye_sown),
  inv_land   = fdiff(sown_corr) * LAND_SEED_MULT * p_wheat,
  inv_vines  = fdiff(vines) * VINE_PRICE,
  ag_inv = inv_cattle + inv_sheep + inv_horses + inv_land + inv_vines,
  agriculture = wheat_val + wine_val + meat_val + ag_inv)

# ---------------- VOC ----------------
rec_pc <- with(d, mean((receipts / total)[!is.na(receipts)]))
rec_obs <- range(d$year[!is.na(d$receipts)])
d <- d %>% mutate(
  subs = (SUBS_WHEAT * p_wheat + SUBS_MEAT * p_meat) / SUBS_FOOD_SHARE,   # guilders per person per year
  wpe = interp(nominal / voc_est, year),
  voc_wages = wpe * voc_est,
  voc_kind = subs * (voc_est + LODGE_SLAVES),
  voc_wissel = WISSEL_SHARE * wissel,
  imports = ifelse(year >= rec_obs[1] & year <= rec_obs[2], interp(receipts, year), rec_pc * total),
  exports = ifelse(year >= 1749, exp_total, exp_grain * p_wheat),
  voc_trade = VOC_TRADE_VA * (imports + exports),
  voc = voc_wages + voc_kind + voc_wissel + voc_trade)

# ---------------- rest of the economy ----------------
d <- d %>% mutate(
  slave_trade = SLAVE_TRADE_MARGIN * pmax(0, fdiff(slaves_opg)) * price_rds * GUILDERS_PER_RDS,
  wine_retail = WINE_URBAN * ct_pop * p_wine * RETAIL_MARKUP,
  bakers = BAKER_VA * (wheat_dom * p_wheat + meat_dom * p_meat),
  construction = BUILD_URBAN * pmax(0, fdiff(ct_pop)) + BUILD_FARM * pmax(0, fdiff(men)),
  crafts = REST_LF_SHARE * lf * (wpe + subs),
  rest = slave_trade + wine_retail + bakers + construction + crafts,
  gdp_nom = agriculture + voc + rest)

# ---------------- deflator, real GDP, per capita ----------------
b <- d %>% filter(year == 1701)
d <- d %>% mutate(
  p_ag = (b$wheat_q * p_wheat + b$wine_q * p_wine + b$meat_q * p_meat) /
         (b$wheat_q * b$p_wheat + b$wine_q * b$p_wine + b$meat_q * b$p_meat),
  cpi = subs / b$subs,
  s_ag = agriculture / gdp_nom,
  deflator = s_ag * p_ag + (1 - s_ag) * cpi,
  gdp_real = gdp_nom / deflator,
  gdppc = gdp_real / total,
  gdppc_eur = (gdp_real - b$subs * (slaves + khoesan)) / europeans,
  gdppc_bal = gdp_real / balanced,
  usd = gdppc * USD_PER_1701G, usd_eur = gdppc_eur * USD_PER_1701G, usd_bal = gdppc_bal * USD_PER_1701G)
gdpcols <- c("agriculture","voc","rest","gdp_nom","gdp_real","gdppc","gdppc_eur","gdppc_bal","usd","usd_eur","usd_bal",
             "deflator","p_ag","cpi","s_ag","wheat_val","wine_val","meat_val","ag_inv","voc_wages","voc_kind","voc_wissel",
             "voc_trade","slave_trade","wine_retail","bakers","construction","crafts")
d <- d %>% mutate(across(all_of(gdpcols), ~ ifelse(year %in% GDP_YEARS, .x, NA)))
write_csv(d, file.path(out, "series_annual.csv"))

# ---------------- summary statistics ----------------
g  <- d %>% filter(year %in% GDP_YEARS)
tr_gdp <- 100 * coef(lm(log(gdp_real) ~ year, data = g))[2]
tr_pop <- 100 * coef(lm(log(total) ~ year, data = d))[2]
dec <- d %>% mutate(dec = floor((year - 1) / 10)) %>% group_by(dec) %>%
  summarise(ad = mean((slm + slw) / slaves_opg))
urban_wine <- d %>% filter(year %in% 1748:1793, !is.na(exp_wine_aam)) %>%
  summarise(v = mean((wine_leggers - exp_wine_aam / AAM_PER_LEGGER) / ct_pop)) %>% pull(v)
svm <- (d$slaves + d$voc_est) / (d$slm + d$voc_est + LODGE_MEN * LODGE_SLAVES)
txt <- tribble(~claim_id, ~value,
  "TXT_p472_a", d$total[d$year == 1701],
  "TXT_p472_b", d$total[d$year == 1795],
  "TXT_p469_d", d$total[d$year == 1795],
  "TXT_p472_c", 100 * mean(d$europeans / d$total),
  "TXT_p472_f", 100 * mean(g$voc / g$gdp_nom),
  "TXT_p472_g", 100 * mean(g$agriculture / g$gdp_nom),
  "TXT_p473_d", g$gdp_nom[g$year == 1701],
  "TXT_p473_e", g$gdp_nom[g$year == 1793],
  "TXT_p474_a", g$gdppc[g$year == 1701],
  "TXT_p474_b", g$gdppc[g$year == 1793],
  "TXT_p476_a", 100 * min(dec$ad),
  "TXT_p476_b", 100 * max(dec$ad),
  "TXT_p476_c", 100 * mean((d$men + d$kn) / d$free),
  "TXT_p476_d", mean(d$free / (d$men + d$kn)),
  "TXT_p476_e", mean(svm),
  "TXT_p476_f", mean((d$balanced / d$total)[d$year <= 1750]),
  "TXT_p476_g", mean((d$balanced / d$total)[d$year > 1750]),
  "TXT_p478_b", g$usd[g$year == 1790],
  "TXT_p478_c", tr_gdp,
  "TXT_p478_d", tr_pop,
  "TXT_p479_a", min(g$usd_bal),
  "TXT_p479_b", max(g$usd_bal),
  "TXT_p487_d", urban_wine)

# ---------------- map to claims ----------------
yr <- function(id) as.integer(str_extract(id, "(?<=_)\\d{4}(?=_)"))
val_of <- function(id) {
  y <- yr(id); if (is.na(y)) return(NA_real_); r <- d[d$year == y, ]
  if (nrow(r) == 0) return(NA_real_)
  case_when(
    str_detect(id, "^A1_\\d{4}_cape$")         ~ r$usd,
    str_detect(id, "^F1_\\d{4}_european$")     ~ r$europeans,
    str_detect(id, "^F1_\\d{4}_slaves$")       ~ r$slaves,
    str_detect(id, "^F1_\\d{4}_total$")        ~ r$total,
    str_detect(id, "^F2_\\d{4}_agriculture$")  ~ r$agriculture / 1000,
    str_detect(id, "^F2_\\d{4}_voc$")          ~ r$voc / 1000,
    str_detect(id, "^F2_\\d{4}_secondary_tertiary$") ~ r$rest / 1000,
    str_detect(id, "^F2_\\d{4}_total$")        ~ r$gdp_nom / 1000,
    str_detect(id, "^F3_\\d{4}_GDPpc$")        ~ r$gdppc,
    str_detect(id, "^F3_\\d{4}_Europeans$")    ~ r$gdppc_eur,
    str_detect(id, "^F3_\\d{4}_Balanced$")     ~ r$gdppc_bal,
    str_detect(id, "^F7_\\d{4}_CapeEuropeans$")~ r$usd_eur,
    str_detect(id, "^F7_\\d{4}_Balanced$")     ~ r$usd_bal,
    TRUE ~ NA_real_)
}
unavail_pat <- "^A1_\\d{4}_sa$|^F1_\\d{4}_khoesan$|^F7_\\d{4}_(Holland|GB)$|^TXT_p472_d$|^TXT_p473_[abc]$|^TXT_p478_[aefgh]$"
res <- claims %>% select(claim_id) %>%
  mutate(value = map_dbl(claim_id, val_of)) %>%
  left_join(txt %>% rename(tv = value), by = "claim_id") %>%
  mutate(value = coalesce(value, tv), tv = NULL,
         status_override = case_when(
           str_detect(claim_id, unavail_pat) ~ "unavailable",
           str_detect(claim_id, "^A1_\\d{4}_cape$") & yr(claim_id) > 1793 ~ "unavailable",
           TRUE ~ NA_character_)) %>%
  filter(!is.na(value) | !is.na(status_override)) %>%
  transmute(claim_id, source = "r", value = round(value, 3), se = NA, n = NA, status_override)
write_csv(res, file.path(root, "repro_r", "results_r.csv"), na = "")
write_csv(txt, file.path(out, "text_quantities.csv"))
cat(sprintf("02_analysis.R done. meat c_pc=%.1f lb; trend GDP %.2f%%, pop %.2f%%; %d result rows (%d with values)\n",
            c_pc, tr_gdp, tr_pop, nrow(res), sum(!is.na(res$value))))
