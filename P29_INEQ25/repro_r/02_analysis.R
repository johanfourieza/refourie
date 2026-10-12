# P29_INEQ25 -- S3 independent recreation, step 2: Ginis and summary statistics
# Reads the clean files written by 01_clean.R; writes output/*.csv and results_r.csv.
# Gini: own implementation (zeros included), checked against ineq::Gini if installed.
# Bootstrap SEs (households resampled within year/cell, B = 200, seed 20251126)
# are a by-product: the paper reports no SEs.

suppressPackageStartupMessages(library(tidyverse))
PROJ <- "."
source(file.path(PROJ, "tools", "paths.R"))
SCR  <- dscratch("P29_INEQ25", "repro_r")
OUT  <- file.path(PROJ, "P29_INEQ25", "repro_r", "output")
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
set.seed(20251126)
B <- 200

gini <- function(x) {
  x <- x[!is.na(x)]; n <- length(x); s <- sum(x)
  if (n < 2 || s <= 0) return(NA_real_)
  x <- sort(x)
  2 * sum(seq_len(n) * x) / (n * s) - (n + 1) / n
}
if (requireNamespace("ineq", quietly = TRUE)) {
  z <- c(0, 0, 1, 5, 9, 30); stopifnot(abs(gini(z) - ineq::Gini(z, corr = FALSE)) < 1e-12)
}
boot_rep <- function(x, B) {
  x <- x[!is.na(x)]
  if (length(x) < 2 || sum(x) <= 0) return(rep(NA_real_, B))
  vapply(seq_len(B), function(b) gini(sample(x, replace = TRUE)), numeric(1))
}
gini_se <- function(x) { r <- boot_rep(x, B); c(g = gini(x), se = sd(r, na.rm = TRUE), n = sum(!is.na(x))) }
top_share <- function(x, p) {          # share of the top p (fractional households interpolated)
  x <- sort(x[!is.na(x)], decreasing = TRUE); n <- length(x); s <- sum(x)
  if (s <= 0) return(NA_real_)
  k <- n * p; kf <- floor(k)
  (sum(x[seq_len(kf)]) + (k - kf) * ifelse(kf + 1 <= n, x[kf + 1], 0)) / s
}

res <- list()
add <- function(id, value, se = NA, n = NA, status = NA) {
  res[[length(res) + 1]] <<- tibble(claim_id = id, source = "r", value = value, se = se, n = n,
                                    status_override = status)
}

# ============================================================================
# A. Stellenbosch-Drakenstein tax censuses (Fig 1, Fig 2, text p.4-5)
# ============================================================================
S  <- readRDS(file.path(SCR, "clean_stellenbosch.rds"))
hh <- S$hh

# Counts
yrs <- hh %>% count(year)
add("txt_p4_nobs", nrow(hh), n = nrow(hh))
add("txt_p4_ncensus", nrow(yrs))
add("txt_p4_hh_first", mean(yrs$n[yrs$year <= 1694]))
add("txt_p4_hh_last",  mean(yrs$n[yrs$year >= 1835]))
add("txt_p4_hh_avg",   mean(yrs$n))

# Annual Ginis with per-year bootstrap replicates (for period-average SEs)
annual <- function(var, data = hh) {
  data %>% filter(!is.na(.data[[var]])) %>% group_by(year) %>%
    group_modify(~ {
      x <- .x[[var]]
      if (sum(x) <= 0) return(tibble())
      tibble(gini = gini(x), n = length(x), rep = list(boot_rep(x, B)))
    }) %>% ungroup() %>% mutate(series = var)
}
assets6 <- c("q_horses", "q_cattle", "q_sheep", "q_wheat", "q_vines", "q_wine")
ann <- map_dfr(c(assets6, "total_value", "q_slaves_men"), annual)

period_avg <- function(a, width) {
  a %>% mutate(period = width * floor(year / width)) %>% group_by(series, period) %>%
    summarise(gini_avg = mean(gini), n_years = n(), n_obs = sum(n),
              se = sd(Reduce(`+`, rep) / n(), na.rm = TRUE), .groups = "drop")
}
fig1_annual <- ann %>% select(series, year, gini, n)
fig1_dec    <- period_avg(ann, 10)
write_csv(fig1_annual, file.path(OUT, "fig1_annual_gini.csv"))
write_csv(fig1_dec,    file.path(OUT, "fig1_decade_gini.csv"))

tv <- fig1_dec %>% filter(series == "total_value")
for (p in c(1690, 1700, seq(1720, 1830, 10))) {
  r <- tv %>% filter(period == p)
  add(paste0("F1_totval_", p), r$gini_avg, r$se, r$n_obs)
}
a6 <- ann %>% filter(series %in% assets6)
imin <- which.min(a6$gini)
add("F1_min_asset", a6$gini[imin], sd(a6$rep[[imin]]), a6$n[imin])
add("txt_p4_min_asset_gini", a6$gini[imin], sd(a6$rep[[imin]]), a6$n[imin])
tv18 <- tv %>% filter(period >= 1700, period <= 1790)
add("txt_p4_tv_lo", min(tv18$gini_avg), tv18$se[which.min(tv18$gini_avg)])
add("txt_p4_tv_hi", max(tv18$gini_avg), tv18$se[which.max(tv18$gini_avg)])
add("txt_p8_concl_gini", min(tv$gini_avg), tv$se[which.min(tv$gini_avg)])
sm <- ann %>% filter(series == "q_slaves_men")
add("txt_p4_slavemen_gini", min(sm$gini), sd(sm$rep[[which.min(sm$gini)]]), sm$n[which.min(sm$gini)])

# Top shares of total value (annual, then averaged)
tops <- hh %>% filter(!is.na(total_value)) %>% group_by(year) %>%
  summarise(top1 = top_share(total_value, 0.01), top01 = top_share(total_value, 0.001),
            top001 = top_share(total_value, 0.0001), n = n(), .groups = "drop") %>%
  filter(!is.na(top1))
write_csv(tops, file.path(OUT, "top_shares_annual.csv"))
add("txt_p4_top1_avg",  100 * mean(tops$top1))
add("txt_p4_top1_1800", 100 * mean(tops$top1[tops$year >= 1800 & tops$year <= 1830]))
add("txt_p4_top01_18c",  100 * mean(tops$top01[tops$year >= 1700 & tops$year <= 1799]))
add("txt_p4_top001_18c", 100 * mean(tops$top001[tops$year >= 1700 & tops$year <= 1799]))
add("txt_p4_top01_19c",  100 * mean(tops$top01[tops$year >= 1800 & tops$year <= 1830]))
add("txt_p4_top001_19c", 100 * mean(tops$top001[tops$year >= 1800 & tops$year <= 1830]))

# Fig 2 scenarios (D8-D9): 20-year periods, average of annual Ginis
base <- hh %>% filter(!is.na(total_value))
scen_data <- function(s) {
  if (s == "settlers")    return(base %>% transmute(year, x = total_value))
  if (s == "slaveassets") return(base %>% transmute(year, x = total_value + slave_asset))
  sl <- base %>% group_by(year) %>% summarise(m = sum(coalesce(q_slaves_men, 0)), p = first(p_sheep), .groups = "drop")
  val <- if (s == "zero") 0 else 12          # D9: 12 sheep a year, valued at sheep price
  extra <- sl %>% filter(m > 0) %>% rowwise() %>%
    reframe(year = year, x = rep(val * p, m))
  bind_rows(base %>% transmute(year, x = total_value), extra)
}
f2 <- map_dfr(c("settlers", "slaveassets", "zero", "sheep12"), function(s) {
  d <- scen_data(s)
  annual("x", d) %>% mutate(series = s)
})
fig2 <- period_avg(f2, 20)
write_csv(f2 %>% select(series, year, gini, n), file.path(OUT, "fig2_annual_gini.csv"))
write_csv(fig2, file.path(OUT, "fig2_period_gini.csv"))
for (s in c("settlers", "slaveassets", "zero", "sheep12")) for (p in seq(1680, 1820, 20)) {
  r <- fig2 %>% filter(series == s, period == p)
  add(paste0("F2_", s, "_", p), r$gini_avg, r$se, r$n_obs)
}
z <- fig2 %>% filter(series == "zero", period == 1780)
add("txt_p5_zero_gini", z$gini_avg, z$se, z$n_obs)
s12 <- fig2 %>% filter(series == "sheep12", period >= 1700, period <= 1820)
add("txt_p5_12sheep_lo", min(s12$gini_avg), s12$se[which.min(s12$gini_avg)])
add("txt_p5_12sheep_hi", max(s12$gini_avg), s12$se[which.max(s12$gini_avg)])

# ============================================================================
# B. c.1825 district cross-section (Fig 3)
# ============================================================================
d25 <- readRDS(file.path(SCR, "clean_1825.rds"))
add("txt_p3_hh1825", nrow(d25), n = nrow(d25))
add("txt_p5_n1825",  nrow(d25), n = nrow(d25))
add("txt_p3_districts1825", n_distinct(d25$district))
add("txt_p3_sd_share1825", 100 * mean(d25$district == "Stellenbosch"))
f3 <- d25 %>% pivot_longer(c(horses, oxen, cattle, sheep, wheat, wine), names_to = "asset") %>%
  group_by(district, asset) %>%
  summarise(total = sum(value), g = list(gini_se(value)), .groups = "drop") %>%
  mutate(gini = map_dbl(g, 1), se = map_dbl(g, 2), n = map_dbl(g, 3)) %>% select(-g) %>%
  group_by(asset) %>% mutate(rel_size = total / max(total)) %>% ungroup()
write_csv(f3, file.path(OUT, "fig3_district_gini.csv"))
key <- function(d) tolower(gsub("[^A-Za-z]", "", d))
for (i in seq_len(nrow(f3))) {
  id <- paste0("F3_", f3$asset[i], "_", key(f3$district[i]))
  if (!(f3$asset[i] == "wine" && f3$district[i] == "Albany")) add(id, f3$gini[i], f3$se[i], f3$n[i])
}
f3v <- f3 %>% filter(!is.na(gini))
add("txt_p5_district_min", min(f3v$gini), f3v$se[which.min(f3v$gini)])
w <- f3v %>% filter(asset == "wine")
add("txt_p5_wine_min", min(w$gini), w$se[which.min(w$gini)])

# ============================================================================
# C. Probate inventories (Fig 4)
# ============================================================================
mo <- readRDS(file.path(SCR, "clean_probates.rds"))
add("txt_p5_nprobates", nrow(mo), n = nrow(mo))
f4 <- mo %>% pivot_longer(c(cattle, horses, sheep, ploughs, wagons), names_to = "asset") %>%
  group_by(asset, decade) %>% summarise(g = list(gini_se(value)), .groups = "drop") %>%
  mutate(gini = map_dbl(g, 1), se = map_dbl(g, 2), n = map_dbl(g, 3)) %>% select(-g)
write_csv(f4, file.path(OUT, "fig4_probate_gini.csv"))
for (i in seq_len(nrow(f4))) add(paste0("F4_", f4$asset[i], "_", f4$decade[i]), f4$gini[i], f4$se[i], f4$n[i])
add("txt_p5_probate_min", min(f4$gini), f4$se[which.min(f4$gini)])
f4b <- f4 %>% filter(decade >= 1770)
add("txt_p5_probate_min1770", min(f4b$gini), f4b$se[which.min(f4b$gini)])

# ============================================================================
# D. Slave emancipation, 1834 (Fig 5) -- D14-D16
# ============================================================================
E  <- readRDS(file.path(SCR, "clean_emancipation.rds"))
ow <- E$owners
add("txt_p6_nslave", E$n_slaves, n = E$n_slaves)
add("txt_p3_enslaved1834", E$n_slaves)
add("txt_p3_enslaved_sd", sum(ow$n_sl[ow$district == "Stellenbosch"]))
NONOWN <- 13033                                   # stated in the paper; used as an input
# D16: allocate non-owners across districts in proportion to 1825 households
# holding no slaves; Somerset (not in the 1825 rolls) takes a share of
# Graaff-Reinet's count in proportion to 1834 slave owners in the two districts.
no25 <- d25 %>% group_by(district) %>% summarise(non = sum(slaves == 0), .groups = "drop") %>%
  mutate(district = recode(district, "Graaff-Reinet" = "Graaff Reinet"))
own_n <- ow %>% count(district, name = "owners")
gr  <- no25$non[no25$district == "Graaff Reinet"]
sh_s <- own_n$owners[own_n$district == "Somerset"] / sum(own_n$owners[own_n$district %in% c("Somerset", "Graaff Reinet")])
no25 <- no25 %>% mutate(non = if_else(district == "Graaff Reinet", gr * (1 - sh_s), as.numeric(non))) %>%
  bind_rows(tibble(district = "Somerset", non = gr * sh_s)) %>%
  mutate(alloc = round(NONOWN * non / sum(non)))
write_csv(no25, file.path(OUT, "fig5_nonowner_allocation.csv"))

f5 <- map_dfr(sort(unique(ow$district)), function(d) {
  o <- ow %>% filter(district == d)
  k <- no25$alloc[no25$district == d]
  v <- o$valuation[o$n_val > 0]
  cmp <- o$compensation[o$n_comp > 0]
  out <- list(
    owners_val  = gini_se(v), owners_comp = gini_se(cmp),
    all_val     = gini_se(c(v, rep(0, k))), all_comp = gini_se(c(cmp, rep(0, k))),
    owners_comp_zeros = gini_se(o$compensation))     # sensitivity: unrecorded = 0
  imap_dfr(out, ~ tibble(district = d, measure = .y, gini = .x[1], se = .x[2], n = .x[3]))
}) %>% mutate(gini = if_else(district %in% c("Clanwilliam", "Swellendam") & grepl("val", measure), NA_real_, gini))
write_csv(f5, file.path(OUT, "fig5_emancipation_gini.csv"))
f5p <- f5 %>% filter(!district %in% c("Clanwilliam", "Swellendam"))
for (i in seq_len(nrow(f5p))) if (f5p$measure[i] != "owners_comp_zeros")
  add(paste0("F5_", f5p$measure[i], "_", key(f5p$district[i])), f5p$gini[i], f5p$se[i], f5p$n[i])
rng <- function(m, id_lo, id_hi) {
  r <- f5p %>% filter(measure == m)
  add(id_lo, min(r$gini), r$se[which.min(r$gini)]); add(id_hi, max(r$gini), r$se[which.max(r$gini)])
}
rng("owners_val", "txt_p6_val_lo", "txt_p6_val_hi")
rng("owners_comp", "txt_p6_comp_lo", "txt_p6_comp_hi")
rng("all_val", "txt_p6_valall_lo", "txt_p6_valall_hi")
rng("all_comp", "txt_p7_compall_lo", "txt_p7_compall_hi")
add("txt_p6_owner_share", 100 * nrow(ow) / (nrow(ow) + NONOWN))
add("txt_p6_nonowners", NONOWN, status = "input-from-paper")

# ============================================================================
# E. Khoe settlements (Fig 6, text p.7-8) -- D17-D19
# ============================================================================
kh <- readRDS(file.path(SCR, "clean_khoe.rds"))
add("txt_p7_beth_hh",  sum(kh$settlement == "Bethelsdorp"))
add("txt_p7_swart_hh", sum(kh$settlement == "Swartrivier"))
add("txt_p7_groen_hh", sum(kh$settlement == "Groenekloof"))
f6 <- kh %>% pivot_longer(c(cattle, horses, oxen, sheep, wheat), names_to = "asset") %>%
  group_by(settlement, asset) %>%
  summarise(owners = sum(value > 0), g = list(gini_se(value)), .groups = "drop") %>%
  mutate(gini = map_dbl(g, 1), se = map_dbl(g, 2), n = map_dbl(g, 3)) %>% select(-g)
write_csv(f6, file.path(OUT, "fig6_khoe_gini.csv"))
for (i in seq_len(nrow(f6))) add(paste0("F6_", f6$asset[i], "_", key(f6$settlement[i])), f6$gini[i], f6$se[i], f6$n[i])
bc <- f6 %>% filter(settlement == "Bethelsdorp", asset == "cattle")
add("txt_p8_beth_cattle", bc$gini, bc$se, bc$n)
oth <- f6 %>% filter(!(settlement == "Bethelsdorp" & asset == "cattle"), !is.na(gini),
                     !(settlement == "Bethelsdorp" & asset == "wheat"),
                     !(settlement == "Swartrivier" & asset == "sheep"))
add("txt_p8_khoe_min", min(oth$gini), oth$se[which.min(oth$gini)])
add("txt_p8_beth_sheep", f6$owners[f6$settlement == "Bethelsdorp" & f6$asset == "sheep"])
add("txt_p8_groen_sheep", f6$owners[f6$settlement == "Groenekloof" & f6$asset == "sheep"])
# D19: combined = Groenekloof + Swartrivier Khoe households + Swellendam 1825 settlers
comb <- bind_rows(kh %>% filter(settlement %in% c("Groenekloof", "Swartrivier")) %>% select(horses, oxen, cattle, wheat),
                  d25 %>% filter(district == "Swellendam") %>% select(horses, oxen, cattle, wheat))
cg <- map(c(cattle = "cattle", horses = "horses", oxen = "oxen", wheat = "wheat"), ~ gini_se(comb[[.x]]))
write_csv(imap_dfr(cg, ~ tibble(asset = .y, gini = .x[1], se = .x[2], n = .x[3])), file.path(OUT, "khoe_settler_combined.csv"))
add("txt_p8_comb_cattle", cg$cattle[1], cg$cattle[2], cg$cattle[3])
mo3 <- which.min(c(cg$horses[1], cg$oxen[1], cg$wheat[1]))
add("txt_p8_comb_other", min(cg$horses[1], cg$oxen[1], cg$wheat[1]), list(cg$horses, cg$oxen, cg$wheat)[[mo3]][2])

# ============================================================================
# G. Post-hoc sensitivities (logged in decisions.md; NOT in results_r.csv)
# ============================================================================
sens <- list()
adds <- function(tag, id, g) sens[[length(sens) + 1]] <<- tibble(sensitivity = tag, claim_id = id, value = g[1], se = g[2], n = g[3])
# P1: apply the D4 trimming rule (10 x district p99 of positives) to the 1825 cross-section
trim10 <- function(x) { p <- quantile(x[x > 0], 0.99, names = FALSE); x[x > 10 * p] <- NA; x }
for (d in unique(d25$district)) for (a in c("horses", "oxen", "cattle", "sheep", "wheat", "wine")) {
  x <- d25[[a]][d25$district == d]
  if (sum(x) > 0) adds("P1_trim1825", paste0("F3_", a, "_", key(d)), gini_se(trim10(x)))
}
# P2: Cape and Swellendam with every named entry as a household
rows <- readRDS(file.path(SCR, "clean_1825_rows_cape_swellendam.rds")) %>% filter(has_name)
for (d in c("Cape", "Swellendam")) for (a in c("horses", "oxen", "cattle", "sheep", "wheat", "wine"))
  adds("P2_rows_as_households", paste0("F3_", a, "_", key(d)), gini_se(rows[[a]][rows$district == d]))
adds("P2_rows_as_households", "txt_p3_hh1825", c(nrow(d25) - sum(d25$district %in% c("Cape", "Swellendam")) + nrow(rows), NA, NA))
# P3: Fig 5 valuation Gini over individual enslaved persons (not owners)
sl <- E$slaves %>% filter(!is.na(valuation))
for (d in setdiff(unique(sl$district), c("Clanwilliam", "Swellendam"))) {
  v <- sl$valuation[sl$district == d]; k <- no25$alloc[no25$district == d]
  adds("P3_slave_level_valuation", paste0("F5_owners_val_", key(d)), gini_se(v))
  adds("P3_slave_level_valuation", paste0("F5_all_val_", key(d)), gini_se(c(v, rep(0, k))))
}
# P4: Bethelsdorp cattle = male + female cattle
ba <- readRDS(file.path(SCR, "clean_beth_alt.rds"))
adds("P4_beth_cattle_all", "F6_cattle_bethelsdorp", gini_se(ba$cattle_all))
# P5: Fig 4 with cattle and horses labels exchanged (Fig 4 values match the other series)
for (i in which(f4$asset %in% c("cattle", "horses")))
  adds("P5_fig4_swap_cattle_horses", paste0("F4_", ifelse(f4$asset[i] == "cattle", "horses", "cattle"), "_", f4$decade[i]),
       c(f4$gini[i], f4$se[i], f4$n[i]))
write_csv(bind_rows(sens) %>% mutate(across(c(value, se), ~ round(.x, 4))), file.path(OUT, "sensitivity_posthoc.csv"))

# ============================================================================
# F. Inputs and literature numbers
# ============================================================================
pr <- readxl::read_excel(dpath("P29_INEQ25", "original", "2024F_Inequality", "price_series.xlsx"))
add("txt_p4_ox_price", max(pr$cattle_work[pr$period < 1780]))
add("txt_p5_slave_value", 12 / 0.06, status = "input-from-paper")
for (id in c("txt_p5_slave_income", "txt_p5_interest", "txt_p4_mooc10_vols"))
  add(id, NA, status = "not-attempted")

results <- bind_rows(res)
claims <- read_csv(file.path(PROJ, "P29_INEQ25", "claims", "claims.csv"), show_col_types = FALSE)
missing <- setdiff(claims$claim_id, results$claim_id)
results <- bind_rows(results, tibble(claim_id = missing, source = "r", value = NA, se = NA, n = NA,
                                     status_override = "not-attempted")) %>%
  filter(claim_id %in% claims$claim_id) %>%
  mutate(status_override = if_else(is.na(value) & is.na(status_override), "not-attempted", status_override),
         value = round(value, 4), se = round(se, 4))
results <- results[match(claims$claim_id, results$claim_id), ]
write_csv(results, file.path(PROJ, "P29_INEQ25", "repro_r", "results_r.csv"), na = "")
cat("02_analysis.R done:", sum(!is.na(results$value)), "claims with values of", nrow(results), "\n")
