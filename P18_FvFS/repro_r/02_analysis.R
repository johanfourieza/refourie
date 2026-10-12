# P18_FvFS - S3 independent recreation - 02_analysis.R
# Tables 1-5, A1, A3 (cols 17-24), A4, A5, text checks; writes .tex tables,
# output/coefs_long.csv, output/sensitivity.csv and repro_r/results_r.csv.

suppressPackageStartupMessages({
  library(tidyverse); library(fixest); library(modelsummary); library(here); library(readxl)
})
set.seed(20261011)
root <- here("P18_FvFS"); source(here("tools", "paths.R"))
rr   <- file.path(root, "repro_r")
od   <- file.path(rr, "output"); dir.create(od, showWarnings = FALSE)
s    <- readRDS(dpath("P18_FvFS", "repro_r", "data", "farmers.rds"))
mo   <- readRDS(dpath("P18_FvFS", "repro_r", "data", "mooc.rds"))
claims <- read.csv(file.path(root, "claims", "claims.csv"), stringsAsFactors = FALSE)

yrs <- c(1700, 1702, 1705, 1709, 1712, 1719, 1723, 1731, 1738, 1741, 1752, 1757, 1762, 1773)
# explicit dummies so that coefficients and the constant are reported as in the paper
for (y in yrs[-1]) s[[paste0("y", y)]] <- as.integer(s$jaar == y)
s$dStel <- as.integer(s$ds == 2); s$dDrak <- as.integer(s$ds == 3); s$dSwel <- as.integer(s$ds == 4)
FE <- c("dStel", "dDrak", "dSwel", paste0("y", yrs[-1]))

# ------------------------------------------------ B3: choose c (pre-committed rule)
f_spec1 <- function(c) {
  s$lw <- log(s$wine_pc + c)
  m <- feols(as.formula(paste("lw ~ nwh + wh + born_abroad +", paste(FE, collapse = "+"))), s, vcov = "iid")
  coef(m)[["(Intercept)"]]
}
cgrid <- c(1, 0.1, 0.01, 0.001)
cons  <- sapply(cgrid, f_spec1)
csel  <- tibble(c = cgrid, constant_spec1 = cons, dist = abs(cons - (-2.987)))
print(csel)
C <- csel$c[which.min(csel$dist)]
cat("Selected c =", C, "\n")
write_csv(csel, file.path(od, "c_selection.csv"))

mk_y <- function(df, c = C) df %>% mutate(lwine = log(wine_pc + c), lwheat = log(wheat_pc + c))
s <- mk_y(s)

# ------------------------------------------------ estimation helpers
est <- function(rhs, data, dv = "lwine") {
  feols(as.formula(paste(dv, "~", paste(c(rhs, FE), collapse = " + "))), data, vcov = "iid")
}
est_nofe <- function(rhs, data, dv = "lwine")
  feols(as.formula(paste(dv, "~", paste(rhs, collapse = " + "))), data, vcov = "iid")
tidy_m <- function(m, table, col) {
  b <- coef(m); V <- vcov(m, vcov = "iid"); Vr <- vcov(m, vcov = "hc1")
  tibble(table = table, col = col, term = names(b), b = unname(b),
         se_iid = sqrt(diag(V)), se_hc1 = sqrt(diag(Vr)),
         p_iid = 2 * pt(-abs(b / se_iid), df = degrees_freedom(m, "resid")),
         p_hc1 = 2 * pt(-abs(b / se_hc1), df = degrees_freedom(m, "resid")),
         n = nobs(m), r2 = r2(m, "r2"), F = fitstat(m, "f")$f$stat)
}

ctrl2 <- c("slaves", "knechts")
ctrl3 <- c(ctrl2, "cattle", "horses", "vines", "mar_nw", "mar_w")

# ------------------------------------------------ Table 3 (full sample, wine)
T3 <- list(
  `1` = est(c("nwh", "wh", "born_abroad"), s),
  `2` = est(c("nwh", "wh", ctrl2, "born_abroad"), s),
  `3` = est(c("nwh", "wh", ctrl3, "born_abroad"), s),
  `4` = est(c("nwh", "wh", ctrl3, "wheat", "born_abroad"), s))

# ------------------------------------------------ Table 4 (Huguenot sample, base NWH)
h  <- s %>% filter(hug == 1)
hn <- h %>% filter(!is.na(numeracy))
hb <- h %>% filter(born_abroad == 1)
T4 <- list(
  `5`  = est(c("wh", "born_abroad"), h),
  `6`  = est(c("wh", ctrl2, "born_abroad"), h),
  `7`  = est(c("wh", ctrl3, "born_abroad"), h),
  `8`  = est(c("wh", ctrl3, "born_abroad", "numeracy"), hn),
  `9`  = est(c("wh", ctrl3, "wheat", "born_abroad", "numeracy"), hn),
  `10` = est_nofe("wh", hb))

# ------------------------------------------------ Table 5 (full sample, wheat)
T5 <- list(
  `11` = est(c("nwh", "wh", "born_abroad"), s, "lwheat"),
  `12` = est(c("nwh", "wh", ctrl2, "born_abroad"), s, "lwheat"),
  `13` = est(c("nwh", "wh", ctrl2, "cattle", "horses", "born_abroad"), s, "lwheat"),
  `14` = est(c("nwh", "wh", ctrl2, "cattle", "horses", "mar_nw", "mar_w", "born_abroad"), s, "lwheat"),
  `15` = est(c("nwh", "wh", ctrl2, "cattle", "horses", "sown", "mar_nw", "mar_w", "born_abroad"), s, "lwheat"),
  `16` = est(c("nwh", "wh", ctrl2, "cattle", "horses", "sown", "mar_nw", "mar_w", "numeracy0", "born_abroad"), s, "lwheat"))

# ------------------------------------------------ Table A3 (Huguenots with known region)
hr <- h %>% filter(!is.na(region)) %>%
  mutate(latC = as.integer(lat == "Central"), latN = as.integer(lat == "North"),
         lonC = as.integer(long == "Central"), lonE = as.integer(long == "East"),
         NxC = latN * lonC, CxC = latC * lonC,
         gMod = as.integer(grp == "Moderate"), gPoor = as.integer(grp == "Poor"))
spec7 <- c("wh", "born_abroad", ctrl3)
A3 <- list(
  `17` = est(spec7, hr),
  `18` = est(c("wh", "latC", "latN", "lonC", "lonE", "born_abroad", ctrl3), hr),
  `19` = est(c("wh", "latC", "latN", "lonC", "lonE", "NxC", "CxC", "born_abroad", ctrl3), hr),
  `20` = est(c("wh", "gMod", "gPoor", "born_abroad", ctrl3), hr),
  `21` = est(spec7, hr %>% filter(region != "Netherlands")),
  `22` = est(spec7, hr %>% filter(!region %in% c("Netherlands", "Aunis", "Dauphine"))),
  `23` = est(spec7, hr %>% filter(!region %in% c("Netherlands", "Aunis", "Dauphine", "Germany", "Italy"))),
  `24` = est(spec7, hr %>% filter(!region %in% c("Netherlands", "Germany", "Italy"))))

# ------------------------------------------------ Table A5 (full sample, wheat, exclusions)
sp15 <- c("nwh", "wh", ctrl2, "cattle", "horses", "sown", "mar_nw", "mar_w", "born_abroad")
A5 <- list(
  `28` = est(sp15, s, "lwheat"),
  `29` = est(sp15, s %>% filter(is.na(region) | region != "Netherlands"), "lwheat"),
  `30` = est(sp15, s %>% filter(is.na(region) | !region %in% c("Netherlands", "Germany", "Italy")), "lwheat"))

# ------------------------------------------------ Tables A1 / A4 (pairwise region differences)
regs <- c("Aunis", "Bearn", "Brittany", "Champagne", "Dauphine", "Germany", "Flanders", "IledeFrance",
          "Italy", "Languedoc", "Netherlands", "Normandy", "Orleanais", "Picardy", "Poitou", "Provence")
pairwise <- function(dv, ctrls) {
  d <- hr %>% mutate(region = factor(region, levels = regs))
  m <- feols(as.formula(paste(dv, "~ i(region, ref = 'Aunis') +", paste(c(ctrls, FE), collapse = "+"))), d, vcov = "iid")
  b <- coef(m); V <- vcov(m); dfr <- degrees_freedom(m, "resid")
  nm <- function(r) paste0("region::", r)
  out <- list()
  for (i in 2:16) for (j in 1:(i - 1)) {
    ri <- regs[i]; rj <- regs[j]
    gi <- if (ri == "Aunis") 0 else b[[nm(ri)]]; gj <- if (rj == "Aunis") 0 else b[[nm(rj)]]
    vi <- if (ri == "Aunis") 0 else V[nm(ri), nm(ri)]; vj <- if (rj == "Aunis") 0 else V[nm(rj), nm(rj)]
    cij <- if (ri == "Aunis" || rj == "Aunis") 0 else V[nm(ri), nm(rj)]
    dd <- gi - gj; se <- sqrt(vi + vj - 2 * cij)
    out[[length(out) + 1]] <- tibble(row = ri, col = rj, b = dd, se_iid = se,
                                     p_iid = 2 * pt(-abs(dd / se), dfr), n = nobs(m))
  }
  bind_rows(out)
}
A1 <- pairwise("lwine", c("born_abroad", ctrl3))
A4 <- pairwise("lwheat", c(ctrl2, "cattle", "horses", "sown", "mar_nw", "mar_w", "born_abroad"))

# ------------------------------------------------ long coefficient file
coefs <- bind_rows(
  imap_dfr(T3, ~ tidy_m(.x, "T3", .y)), imap_dfr(T4, ~ tidy_m(.x, "T4", .y)),
  imap_dfr(T5, ~ tidy_m(.x, "T5", .y)), imap_dfr(A3, ~ tidy_m(.x, "A3", .y)),
  imap_dfr(A5, ~ tidy_m(.x, "A5", .y)))
write_csv(coefs, file.path(od, "coefs_long.csv"))
write_csv(bind_rows(A1 %>% mutate(table = "A1"), A4 %>% mutate(table = "A4")), file.path(od, "pairwise_A1_A4.csv"))

# ------------------------------------------------ .tex tables (modelsummary)
cmap <- c(nwh = "Huguenot: non-wine-producing", wh = "Huguenot: wine-producing", slaves = "Slaves",
          knechts = "Knechts", cattle = "Cattle", horses = "Horses", vines = "Vines (1,000s)",
          sown = "Wheat sown", mar_nw = "Married: non-wine", mar_w = "Married: wine", wheat = "Wheat reaped",
          latC = "Latitude: Central", latN = "Latitude: North", lonC = "Longitude: Central", lonE = "Longitude: East",
          NxC = "North x Central", CxC = "Central x Central", gMod = "Grouping: Moderate", gPoor = "Grouping: Poor",
          born_abroad = "Born abroad", numeracy = "Numeracy", numeracy0 = "Numeracy (0 if missing)",
          dStel = "Stellenbosch", dDrak = "Drakenstein", dSwel = "Swellendam",
          setNames(as.character(yrs[-1]), paste0("y", yrs[-1])), `(Intercept)` = "Constant")
stars <- c("*" = .1, "**" = .05, "***" = .01)
gof <- tribble(~raw, ~clean, ~fmt, "r.squared", "R2", 3, "nobs", "N", 0, "statistic", "F statistic", 3)
write_tab <- function(ml, file, title, vc) {
  modelsummary(ml, output = file.path(od, file), vcov = vc, stars = stars, coef_map = cmap,
               gof_map = gof, fmt = 3, title = title,
               notes = paste0("OLS. SEs in parentheses: ", ifelse(vc == "iid", "conventional (iid)", "heteroskedasticity-robust (HC1)"),
                              ". Base: Cape Town, 1700. log(y + ", C, ")."))
}
for (vc in c("iid", "hc1")) {
  write_tab(T3, paste0("table3_", vc, ".tex"), "Table 3 recreation: log(wine per household member), full sample", vc)
  write_tab(T4, paste0("table4_", vc, ".tex"), "Table 4 recreation: log(wine per household member), Huguenot sample", vc)
  write_tab(T5, paste0("table5_", vc, ".tex"), "Table 5 recreation: log(wheat reaped per household member), full sample", vc)
  write_tab(A3, paste0("tableA3_", vc, ".tex"), "Table A3 recreation (cols 17-24)", vc)
  write_tab(A5, paste0("tableA5_", vc, ".tex"), "Table A5 recreation", vc)
}

# ------------------------------------------------ Table 1 and Table 2
t1vars <- c(c1 = "hhsize", c2 = "slaves", c3 = "knechts", c4 = "vines", c5 = "wine", c6 = "wheat", c7 = "cattle", c8 = "horses")
T1 <- bind_rows(s %>% mutate(g = as.character(group)), s %>% mutate(g = "Total")) %>%
  group_by(g) %>% summarise(n = n(), across(all_of(unname(t1vars)), list(mean = mean, sd = sd))) %>%
  mutate(r = c(NH = "r1", NWH = "r2", WH = "r3", Total = "r4")[g])
T2 <- s %>% group_by(jaar, group) %>%
  summarise(wine = sum(wine) / sum(hhsize), wheat = sum(wheat) / sum(hhsize), n = n(), .groups = "drop")
write_csv(T1, file.path(od, "table1.csv")); write_csv(T2, file.path(od, "table2_fig2_series.csv"))
t1tex <- T1 %>% select(g, n, ends_with("_mean"), ends_with("_sd"))
datasummary_df(t1tex %>% mutate(across(where(is.numeric), ~ round(.x, 2))),
               output = file.path(od, "table1.tex"), title = "Table 1 recreation: means and SDs by group")
datasummary_df(T2 %>% filter(jaar %in% c(1700, 1709, 1719, 1731, 1741, 1752, 1757, 1773)) %>%
                 select(-n) %>% pivot_wider(names_from = group, values_from = c(wine, wheat)) %>%
                 mutate(across(-jaar, ~ round(.x, 2)), jaar = as.character(jaar)),
               output = file.path(od, "table2.tex"), title = "Table 2 recreation: household-size-weighted per capita production")

# ------------------------------------------------ text checks
# elite wine farmers: wine > 0 and >= 16 slaves
elite <- s %>% filter(wine > 0, slaves >= 16) %>% group_by(jaar) %>%
  summarise(n = n(), hug = sum(hug), wh = sum(wh))
print(elite %>% filter(jaar %in% c(1700, 1731, 1773)))
# probate
mp <- mo %>% filter(year >= 1673, year <= 1844, !is.na(slaves))
mp2 <- mo %>% filter(year >= 1800, year <= 1834, !is.na(slaves))
pm <- mp %>% group_by(group) %>% summarise(mean = mean(slaves), n = n())
pm2 <- mp2 %>% mutate(hg = ifelse(group == "NH", "NH", "HUG")) %>% group_by(hg) %>% summarise(mean = mean(slaves), n = n())
print(pm); print(pm2)
tt <- list(
  WH_vs_NH = t.test(mp$slaves[mp$group == "WH"], mp$slaves[mp$group == "NH"])$p.value,
  WH_vs_NWH = t.test(mp$slaves[mp$group == "WH"], mp$slaves[mp$group == "NWH"])$p.value,
  HUG_vs_NH_1800 = t.test(mp2$slaves[mp2$group != "NH"], mp2$slaves[mp2$group == "NH"])$p.value)
print(tt)
lh <- read_excel(dpath("P18_FvFS", "original", "French Huguenots", "List of Huguenots.xlsx"), "Sheet1", .name_repair = "unique_quiet")
n_arr <- sum(suppressWarnings(as.numeric(lh$`Date of arrival`)) %in% c(1688, 1689))

# ------------------------------------------------ sensitivity (headline coefficients)
sens_run <- function(label, data) {
  hh <- data %>% filter(hug == 1)
  m4 <- est(c("nwh", "wh", ctrl3, "wheat", "born_abroad"), data)
  m7 <- est(c("wh", ctrl3, "born_abroad"), hh)
  m10 <- est_nofe("wh", hh %>% filter(born_abroad == 1))
  tibble(variant = label, T3c4_wh = coef(m4)[["wh"]], T3c4_se = se(m4)[["wh"]],
         T4c7_wh = coef(m7)[["wh"]], T4c7_se = se(m7)[["wh"]], T4c7_n = nobs(m7),
         T4c10_wh = coef(m10)[["wh"]], T4c10_n = nobs(m10))
}
sens <- bind_rows(
  sens_run(paste0("primary (c=", C, ")"), s),
  map_dfr(setdiff(cgrid, C), ~ sens_run(paste0("c=", .x), mk_y(s, .x))),
  sens_run("WH = xlsx WYN flag", s %>% mutate(wh = wh_flag, nwh = nwh_flag)),
  sens_run("WH = .dta wyns", s %>% mutate(wh = wh_dta, nwh = nwh_dta, hug = as.integer(wh_dta + nwh_dta > 0))),
  sens_run("born abroad = assist OR first seen <=1692", s %>% mutate(born_abroad = born_abroad_alt)))
print(sens)
write_csv(sens, file.path(od, "sensitivity.csv"))

# ------------------------------------------------ map to claims -> results_r.csv
termrows <- list(
  T3 = c("nwh", "wh", "slaves", "knechts", "cattle", "horses", "vines", "mar_nw", "mar_w", "wheat", "born_abroad",
         "dStel", "dDrak", "dSwel", paste0("y", yrs[-1]), "(Intercept)", "R2", "N", "F"),
  T4 = c("wh", "slaves", "knechts", "cattle", "horses", "vines", "mar_nw", "mar_w", "wheat", "born_abroad", "numeracy",
         "dStel", "dDrak", "dSwel", paste0("y", yrs[-1]), "(Intercept)", "R2", "N", "F"),
  T5 = c("nwh", "wh", "slaves", "knechts", "cattle", "horses", "sown", "mar_nw", "mar_w", "numeracy0", "born_abroad",
         "dStel", "dDrak", "dSwel", paste0("y", yrs[-1]), "(Intercept)", "R2", "N", "F"),
  A3 = c("wh", "latC", "latN", "lonC", "lonE", "NxC", "CxC", "gMod", "gPoor", "height", "born_abroad",
         "slaves", "knechts", "cattle", "horses", "vines", "mar_nw", "mar_w",
         "dStel", "dDrak", "dSwel", paste0("y", yrs[-1]), "(Intercept)", "R2", "N", "F"),
  A5 = c("nwh", "wh", "slaves", "knechts", "cattle", "horses", "sown", "mar_nw", "mar_w", "born_abroad",
         "dStel", "dDrak", "dSwel", paste0("y", yrs[-1]), "(Intercept)", "R2", "N", "F"))

res <- claims %>% select(claim_id, location, quantity_type) %>%
  mutate(source = "r", value = NA_real_, se = NA_real_, n = NA_real_, status_override = "")
setv <- function(id, v, se = NA, n = NA, st = "") {
  i <- which(res$claim_id == id)
  if (length(i) == 1) { res$value[i] <<- v; res$se[i] <<- se; res$n[i] <<- n; res$status_override[i] <<- st }
}
for (i in seq_len(nrow(res))) {
  id <- res$claim_id[i]
  mm <- str_match(id, "^(T3|T4|T5|A3|A5)_r(\\d+)_c(\\d+)")
  if (!is.na(mm[1])) {
    tb <- mm[2]; r <- as.integer(mm[3]); cl <- mm[4]; term <- termrows[[tb]][r]
    if (tb == "A3" && cl %in% c("25", "26", "27")) { res$status_override[i] <- "unavailable"; next }
    cc <- coefs %>% filter(table == tb, col == cl)
    if (nrow(cc) == 0) { res$status_override[i] <- "unavailable"; next }
    if (term == "R2") { res$value[i] <- cc$r2[1]; res$n[i] <- cc$n[1] }
    else if (term == "N") { res$value[i] <- cc$n[1]; res$n[i] <- cc$n[1] }
    else if (term == "F") { res$value[i] <- cc$F[1]; res$n[i] <- cc$n[1] }
    else if (term == "height") res$status_override[i] <- "unavailable"
    else {
      row <- cc %>% filter(term == !!term)
      if (nrow(row) == 1) { res$value[i] <- row$b; res$se[i] <- row$se_iid; res$n[i] <- row$n }
      else res$status_override[i] <- "unavailable"
    }
    if (tb == "T5" && term == "numeracy0") res$status_override[i] <- "ambiguous"
    next
  }
  mm <- str_match(id, "^(A1|A4)_([A-Za-z]+)_([A-Za-z]+)$")
  if (!is.na(mm[1])) {
    pw <- if (mm[2] == "A1") A1 else A4
    row <- pw %>% filter(row == mm[3], col == mm[4])
    if (nrow(row) == 1) { res$value[i] <- row$b; res$se[i] <- row$se_iid; res$n[i] <- row$n }
    else res$status_override[i] <- "unavailable"
    next
  }
  mm <- str_match(id, "^T1_(r\\d)_(n|c(\\d)_(mean|sd))$")
  if (!is.na(mm[1])) {
    tr <- T1 %>% filter(r == mm[2])
    if (mm[3] == "n") res$value[i] <- tr$n else res$value[i] <- tr[[paste0(t1vars[paste0("c", mm[4])], "_", mm[5])]]
    res$n[i] <- tr$n; next
  }
  mm <- str_match(id, "^T2_(\\d{4})_(wine|wheat)_(NH|NWH|WH)$")
  if (!is.na(mm[1])) {
    tr <- T2 %>% filter(jaar == as.numeric(mm[2]), group == mm[4])
    res$value[i] <- tr[[mm[3]]]; res$n[i] <- tr$n; next
  }
  if (grepl("^A2_", id)) { res$status_override[i] <- "not-attempted"; next }  # classification input read from paper
}
coefv <- function(tb, cl, tm) coefs %>% filter(table == tb, col == cl, term == tm)
txt <- function(id, v, se = NA, n = NA, st = "") setv(id, v, se, n, st)
k <- coefv("T3", "4", "wh"); txt("TXT_p943_a", 100 * k$b, 100 * k$se_iid, k$n)
k <- coefv("T4", "7", "wh"); txt("TXT_p944_a", 100 * k$b, 100 * k$se_iid, k$n)
k <- coefv("T4", "10", "wh"); txt("TXT_p948_a", 100 * k$b, 100 * k$se_iid, k$n)
txt("TXT_p935_a", n_arr, st = "ambiguous")
txt("TXT_p937_a", length(unique(s$jaar)))
txt("TXT_p940_a", 17282, st = "ambiguous")   # .dta household rows, all 23 years
txt("TXT_p949_a", nrow(mp), n = nrow(mp))
txt("TXT_p949_b", pm$mean[pm$group == "WH"], n = pm$n[pm$group == "WH"])
txt("TXT_p949_c", pm$mean[pm$group == "NH"], n = pm$n[pm$group == "NH"])
txt("TXT_p949_d", pm$mean[pm$group == "NWH"], n = pm$n[pm$group == "NWH"])
txt("TXT_p949_e", pm2$mean[pm2$hg == "NH"], n = pm2$n[pm2$hg == "NH"])
txt("TXT_p949_f", pm2$mean[pm2$hg == "HUG"], n = pm2$n[pm2$hg == "HUG"])
e <- function(y, v) elite[[v]][elite$jaar == y]
txt("TXT_p953_a", e(1700, "n")); txt("TXT_p953_b", e(1731, "n")); txt("TXT_p953_c", e(1731, "wh"))
txt("TXT_p953_d", e(1773, "n")); txt("TXT_p953_e", e(1773, "hug")); txt("TXT_p953_f", e(1773, "wh"))
for (id in c("TXT_p946_a", "TXT_p952_a", "TXT_p952_b", "TXT_p952_c")) txt(id, NA, st = "unavailable")
for (id in c("TXT_p954_a", "TXT_p959_a", "TXT_p961_a", "TXT_p961_b")) txt(id, NA, st = "not-attempted")
res$status_override[is.na(res$value) & res$status_override == ""] <- "unavailable"

write_csv(res %>% select(claim_id, source, value, se, n, status_override), file.path(rr, "results_r.csv"), na = "")
cat("\nresults_r.csv rows:", nrow(res), " with value:", sum(!is.na(res$value)), "\n")
print(table(res$status_override))
