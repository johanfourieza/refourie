# P10_FI  S3 independent recreation  --  02_analysis.R
# Tables 1-4, text numbers and Table 3 regressions from the cleaned file.
# Conventional (iid) SEs are the published analogue; parish-clustered SEs
# are reported alongside. Writes aggregate outputs only.

suppressPackageStartupMessages({
  library(tidyverse)
  library(sandwich)
  library(lmtest)
  library(modelsummary)
  library(kableExtra)
  library(here)
})
set.seed(20191001)

proj <- here::here()
source(file.path(proj, "tools", "paths.R"))
pdir <- file.path(proj, "P10_FI", "repro_r")
odir <- file.path(pdir, "output"); dir.create(odir, showWarnings = FALSE, recursive = TRUE)
d_all <- readRDS(dscratch("P10_FI", "repro_r", "p10_clean.rds"))
s <- d_all %>% filter(sample)
N <- nrow(s)
res <- list()
add <- function(id, value, se = NA, n = NA, status = NA) {
  res[[length(res) + 1]] <<- tibble(claim_id = id, source = "r", value = value, se = se, n = n,
                                    status_override = status)
}

# ---------------------------------------------------------------------------
# Table 1: husband race x wife race
# ---------------------------------------------------------------------------
lv <- c("coloured", "white", "black"); ab <- c(coloured = "c", white = "w", black = "b")
t1 <- s %>% mutate(m = factor(m_race, lv), f = factor(f_race, lv)) %>% count(m, f, .drop = FALSE)
for (i in seq_len(nrow(t1))) {
  k <- paste0(ab[as.character(t1$m[i])], ab[as.character(t1$f[i])])
  add(paste0("t1_cnt_", k), t1$n[i], n = N); add(paste0("t1_shr_", k), 100 * t1$n[i] / N, n = N)
}
for (r in lv) {
  nm <- sum(t1$n[t1$m == r]); nf <- sum(t1$n[t1$f == r])
  add(paste0("t1_cnt_", ab[r], "t"), nm, n = N); add(paste0("t1_shr_", ab[r], "t"), 100 * nm / N, n = N)
  add(paste0("t1_cnt_t", ab[r]), nf, n = N)
}
add("t1_cnt_tt", N, n = N)
t1_wide <- t1 %>% pivot_wider(names_from = f, values_from = n) %>%
  mutate(Total = coloured + white + black)
t1_wide <- bind_rows(t1_wide, tibble(m = "Total", coloured = sum(t1_wide$coloured),
                                     white = sum(t1_wide$white), black = sum(t1_wide$black), Total = N))
write_csv(t1_wide, file.path(odir, "table1.csv"))
kbl(t1_wide, format = "latex", booktabs = TRUE, caption = "Number of marriages in sample, 1911--1964 (R recreation)") %>%
  save_kable(file.path(odir, "table1.tex"))

# text p.636-637, 639
for (r in lv) {
  nm <- sum(s$m_race == r)
  key <- c(coloured = "col", white = "wh", black = "bl")[r]
  add(paste0("txt_p636_", key, "husb_n"), nm, n = N); add(paste0("txt_p636_", key, "husb_sh"), 100 * nm / N, n = N)
}
for (k in c("wc", "bc", "cw", "cb", "wb", "bw")) add(paste0("txt_p637_", k), sum(s$type == k), n = N)
add("txt_p629_n23000", N, n = N); add("txt_p634_n_used", N, n = N)
add("txt_p634_n_transcribed", nrow(d_all))
add("txt_p639_black_inter", 100 * mean(s$interracial[s$m_race == "black"]), n = sum(s$m_race == "black"))
add("txt_p639_col_inter", 100 * mean(s$interracial[s$m_race == "coloured"]), n = sum(s$m_race == "coloured"))
add("txt_p639_reclass", sum(s$reclass), n = N)

# annual shares (Figure 3) and period shares
ann <- s %>% group_by(year) %>%
  summarise(n = n(), inter = sum(interracial), share = 100 * inter / n,
            w_inter = sum(m_race == "white" & interracial == 1), ww = sum(type == "ww"),
            share_wh = 100 * w_inter / (w_inter + ww), .groups = "drop")
write_csv(ann, file.path(odir, "fig3_annual_share.csv"))
for (y in 1911:1963) { z <- ann %>% filter(year == y); add(paste0("F3_", y), z$share, n = z$n) }
per <- function(y0, y1) { z <- s %>% filter(year >= y0, year <= y1); c(100 * mean(z$interracial), nrow(z)) }
p <- per(1911, 1913); add("txt_p629_share_preWWI", p[1], n = p[2])
p <- per(1930, 1939); add("txt_p629_share_1930s", p[1], n = p[2])
p <- per(1950, 1964); add("txt_p630_share_post1949", p[1], n = p[2])
z <- ann %>% filter(year == 1925)
add("txt_p637_1925_whinter", z$w_inter); add("txt_p637_1925_inter", z$inter); add("txt_p637_1925_ww", z$ww)
add("txt_p637_1925_share", z$share_wh, n = z$w_inter + z$ww)
add("txt_p637_1925_ratio", z$share_wh / 0.9)
add("txt_fn15_1925_all", z$share, n = z$n)
add("txt_p638_1935", ann$share_wh[ann$year == 1935]); add("txt_p638_1945", ann$share_wh[ann$year == 1945])
# number of distinct raw race strings that map to a race group (whole file; from the race audit)
ra <- read_csv(file.path(odir, "dict_race.csv"), show_col_types = FALSE)
add("txt_p638_racecats", n_distinct(ra$raw[!is.na(ra$race)]))
occ_u <- read_csv(file.path(odir, "clean_log.csv"), show_col_types = FALSE)
um <- occ_u$value[occ_u$item == "unique_male_occ_strings_sample"]
uf <- occ_u$value[occ_u$item == "unique_female_occ_strings_sample"]
add("txt_p638_occ_male", um); add("txt_p640_occ_male", um)
add("txt_p638_occ_female", uf); add("txt_p641_occ_female", uf)
for (id in c("txt_p635_angl_white", "txt_p635_angl_col", "txt_p635_afr_white", "txt_p635_afr_col",
             "txt_p635_jewish", "txt_p637_vs_inter1925", "txt_p637_vs_ww1925", "txt_p637_vs_sh1925",
             "txt_p637_vs_1935", "txt_p638_vs_1945"))
  add(id, NA, status = "not-attempted")   # census / secondary-source numbers, not in the data

# ---------------------------------------------------------------------------
# Table 2: means by male race (NA row = husband race missing, 1911-1964)
# ---------------------------------------------------------------------------
t2_vars <- c(interracial = "interracial", maleage = "m_age", femaleage = "f_age",
             maleliteracy = "m_lit", femaleliteracy = "f_lit", sexratio = "sexratio",
             segregation = "segregation", literacydifference = "lit_diff")
t2src <- bind_rows(s %>% mutate(grp = m_race),
                   d_all %>% filter(in_period, is.na(m_race)) %>% mutate(grp = "NA", interracial = NA, sexratio = NA))
t2 <- t2src %>% group_by(grp) %>%
  summarise(n = n(), across(all_of(unname(t2_vars)), ~ mean(.x, na.rm = TRUE)), .groups = "drop") %>%
  mutate(across(where(is.numeric), ~ ifelse(is.nan(.x), NA, .x)))
write_csv(t2, file.path(odir, "table2.csv"))
kbl(t2 %>% mutate(across(where(is.double), ~ round(.x, 2))), format = "latex", booktabs = TRUE,
    caption = "Selected statistics by male race, 1911--1964 (R recreation)") %>% save_kable(file.path(odir, "table2.tex"))
gk <- c(coloured = "co", white = "wh", black = "bl", "NA" = "na")
for (g in names(gk)) for (v in names(t2_vars)) {
  if (g == "NA" && v %in% c("interracial", "sexratio")) next
  col <- t2_vars[[v]]; z <- t2src %>% filter(grp == g)
  add(paste0("T2_", gk[g], "_", v), t2[[col]][t2$grp == g], n = sum(!is.na(z[[col]])))
}

# ---------------------------------------------------------------------------
# Table 4: literacy by male race and same/inter
# ---------------------------------------------------------------------------
t4 <- s %>% mutate(Type = ifelse(interracial == 1, "inter", "same")) %>%
  group_by(m_race, Type) %>%
  summarise(n = n(), male_lit = mean(m_lit, na.rm = TRUE), female_lit = mean(f_lit, na.rm = TRUE), .groups = "drop")
write_csv(t4, file.path(odir, "table4.csv"))
kbl(t4 %>% mutate(across(c(male_lit, female_lit), ~ round(.x, 2))), format = "latex", booktabs = TRUE,
    caption = "Literacy rates between same and interracial marriages (R recreation)") %>% save_kable(file.path(odir, "table4.tex"))
for (i in seq_len(nrow(t4))) {
  k <- paste0("T4_", gk[t4$m_race[i]], "_", t4$Type[i])
  add(paste0(k, "_male"), t4$male_lit[i], n = t4$n[i]); add(paste0(k, "_female"), t4$female_lit[i], n = t4$n[i])
}
g4 <- function(r, ty, v) 100 * t4[[v]][t4$m_race == r & t4$Type == ty]
add("txt_p645_bl_same_lit", g4("black", "same", "male_lit")); add("txt_p645_bl_inter_lit", g4("black", "inter", "male_lit"))
# coloured women married to coloured men / to white men
add("txt_p645_colw_colm_lit", 100 * mean(s$f_lit[s$type == "cc"], na.rm = TRUE), n = sum(s$type == "cc"))
add("txt_p645_colw_whm_lit", 100 * mean(s$f_lit[s$type == "wc"], na.rm = TRUE), n = sum(s$type == "wc"))

# ---------------------------------------------------------------------------
# Table 3: regressions
#   (1) logit; (2)-(4) OLS LPM. All: month dummies, parish dummies, linear year
#   (table notes). Listwise deletion on included regressors.
# ---------------------------------------------------------------------------
x1 <- c("m_white", "m_black", "f_white", "f_black", "m_age", "f_age", "act", "segregation", "lit_gap")
x2 <- c(x1, "widower", "m_divorcee", "widow", "f_divorcee")
x3 <- c(x2[1:7], "sexratio", x2[8:13], "m_foreign", "f_foreign")
x4 <- c(x3, "m_manager", "m_sales", "f_manager", "f_sales")
fe <- "year + month_f + parish"
fml <- function(x, fe_ = fe) as.formula(paste("interracial ~", paste(x, collapse = " + "), "+", fe_))
fit_ols <- function(x, data, fe_ = fe) {
  dd <- data %>% drop_na(all_of(c(x, "month_f", "parish", "year"))) %>% droplevels()
  list(m = lm(fml(x, fe_), data = dd), data = dd)
}
m1d <- s %>% drop_na(all_of(c(x1, "month_f", "parish", "year"))) %>% droplevels()
m1 <- glm(fml(x1), data = m1d, family = binomial())
o2 <- fit_ols(x2, s); o3 <- fit_ols(x3, s); o4 <- fit_ols(x4, s)
mods <- list(`(1) Logit` = m1, `(2) OLS` = o2$m, `(3) OLS` = o3$m, `(4) OLS` = o4$m)
datas <- list(m1d, o2$data, o3$data, o4$data)
vc_iid <- lapply(mods, vcov)
vc_cl <- mapply(function(m, dd) vcovCL(m, cluster = dd$parish, type = "HC1"), mods, datas, SIMPLIFY = FALSE)

name_map <- c(m_white = "whitemale", m_black = "blackmale", f_white = "whitefemale", f_black = "blackfemale",
              m_age = "maleage", f_age = "femaleage", act = "act", sexratio = "sexratio",
              segregation = "segregation", lit_gap = "literacygap", widower = "widower",
              m_divorcee = "maledivorcee", widow = "widow", f_divorcee = "femaledivorcee",
              m_foreign = "foreignbornmale", f_foreign = "foreignbornfemale", m_manager = "malemanager",
              m_sales = "malesales", f_manager = "femalemanager", f_sales = "femalesales",
              year = "year", `(Intercept)` = "constant")
coef_long <- map_dfr(seq_along(mods), function(j) {
  b <- coef(mods[[j]])
  tibble(spec = j, term = names(b), coef = unname(b),
         se_iid = sqrt(diag(vc_iid[[j]]))[names(b)], se_cl = sqrt(diag(vc_cl[[j]]))[names(b)],
         n = nobs(mods[[j]]))
}) %>% filter(term %in% names(name_map)) %>%
  mutate(p_iid = 2 * pnorm(-abs(coef / se_iid)), p_cl = 2 * pnorm(-abs(coef / se_cl)))
write_csv(coef_long, file.path(odir, "table3_coefs_long.csv"))
for (i in seq_len(nrow(coef_long))) {
  add(paste0("T3_", name_map[[coef_long$term[i]]], "_c", coef_long$spec[i]),
      coef_long$coef[i], se = coef_long$se_iid[i], n = coef_long$n[i])
}
for (j in 1:4) add(paste0("T3_obs_c", j), nobs(mods[[j]]))
for (j in 2:4) { sm <- summary(mods[[j]]); add(paste0("T3_r2_c", j), sm$r.squared, n = nobs(mods[[j]]))
                 add(paste0("T3_adjr2_c", j), sm$adj.r.squared, n = nobs(mods[[j]])) }
add("T3_aic_c1", AIC(m1), n = nobs(m1))

keep <- names(name_map)[names(name_map) != "(Intercept)"]
cm <- c(setNames(c("White male", "Black male", "White female", "Black female", "Male age", "Female age", "Act",
                   "Sex ratio", "Segregation", "Literacy gap", "Widower", "Male divorcee", "Widow",
                   "Female divorcee", "Foreign-born male", "Foreign-born female", "Male manager", "Male sales",
                   "Female manager", "Female sales", "Year"), keep), `(Intercept)` = "Constant")
gof <- tribble(~raw, ~clean, ~fmt, "nobs", "Observations", 0, "r.squared", "R-squared", 3,
               "adj.r.squared", "Adjusted R-sq", 3, "aic", "AIC", 3)
add_rows <- tibble(term = c("Month dummies", "Parish dummies"), a = "Yes", b = "Yes", c = "Yes", d = "Yes")
for (vt in c("iid", "cluster")) {
  vl <- if (vt == "iid") vc_iid else vc_cl
  modelsummary(mods, vcov = vl, coef_map = cm, gof_map = gof, stars = c("*" = .1, "**" = .05, "***" = .01),
               fmt = 4, add_rows = add_rows, output = file.path(odir, paste0("table3_", vt, ".tex")),
               title = paste0("Interracial marriages in Cape Town, 1911--1964 (R recreation; ",
                              ifelse(vt == "iid", "conventional", "parish-clustered"), " SEs)"))
}

# ---------------------------------------------------------------------------
# Alternative specifications (recorded; not the primary results)
# ---------------------------------------------------------------------------
alt <- list()
alt_add <- function(label, m, terms, vc = vcov(m)) {
  b <- coef(m); se <- sqrt(diag(vc))
  alt[[length(alt) + 1]] <<- tibble(variant = label, term = terms, coef = b[terms], se_iid = se[terms], n = nobs(m))
}
# A. Year fixed effects (eq. (1)); Act is collinear with year FE and drops out
oA <- fit_ols(x2, s, fe_ = "factor(year) + month_f + parish")
alt_add("A_spec2_yearFE", oA$m, c("segregation", "lit_gap", "act"))
# B. Logit spec 1 without linear year (table prints no Year row for col 1)
m1b <- glm(fml(x1, "month_f + parish"), data = m1d, family = binomial())
alt_add("B_spec1_logit_noyear", m1b, c("act", "segregation", "lit_gap", "m_white"))
# C. Sex ratio carried forward 1961-64
s_cf <- s %>% mutate(sexratio = sexratio_cf)
oC3 <- fit_ols(x3, s_cf); oC4 <- fit_ols(x4, s_cf)
alt_add("C_spec3_sexratio_cf", oC3$m, c("sexratio", "segregation", "act")); alt_add("C_spec4_sexratio_cf", oC4$m, c("sexratio", "segregation", "act"))
# D. Segregation from husbands only
s_h <- s %>% mutate(segregation = segregation_h)
oD <- fit_ols(x2, s_h); alt_add("D_spec2_seg_husbands", oD$m, c("segregation", "act"))
# E. Female non-occupations kept as reference group in spec 4
s_e <- s %>% mutate(f_manager = as.numeric(f_occ_alt == "prof"), f_sales = as.numeric(f_occ_alt == "sales"))
oE <- fit_ols(x4, s_e); alt_add("E_spec4_female_nonocc_in_ref", oE$m, c("segregation", "act", "f_manager", "f_sales"))
# F. Logit versions of specs 2-4 (note 19)
for (j in 2:4) {
  xx <- list(x2, x3, x4)[[j - 1]]
  dd <- s %>% drop_na(all_of(c(xx, "month_f", "parish", "year"))) %>% droplevels()
  mm <- suppressWarnings(glm(fml(xx), data = dd, family = binomial()))
  alt_add(paste0("F_spec", j, "_logit"), mm, intersect(c("act", "segregation", "lit_gap", "sexratio"), xx))
}
# G. POST-HOC (added after seeing the sign of lit_gap differ from the paper):
#    signed literacy difference (male minus female) in place of the absolute gap
s_g <- s %>% mutate(lit_gap = lit_diff)
oG <- fit_ols(x2, s_g); alt_add("G_posthoc_spec2_litgap_signed", oG$m, c("lit_gap", "segregation"))
alt_tab <- bind_rows(alt)
write_csv(alt_tab, file.path(odir, "alt_specs.csv"))

# headline clustered SEs for convenience
write_csv(coef_long %>% filter(term %in% c("act", "segregation")), file.path(odir, "table3_headline_iid_vs_cluster.csv"))

# ---------------------------------------------------------------------------
# results_r.csv (all claims; missing ones flagged)
# ---------------------------------------------------------------------------
out <- bind_rows(res) %>% distinct(claim_id, .keep_all = TRUE)
claims <- read_csv(file.path(proj, "P10_FI", "claims", "claims.csv"), show_col_types = FALSE)
miss <- setdiff(claims$claim_id, out$claim_id)
out <- bind_rows(out, tibble(claim_id = miss, source = "r", value = NA, se = NA, n = NA,
                             status_override = "not-attempted"))
out <- out %>% filter(claim_id %in% claims$claim_id) %>%
  mutate(status_override = ifelse(is.na(value) & is.na(status_override), "not-attempted", status_override))
out <- claims %>% select(claim_id) %>% left_join(out, by = "claim_id")
write_csv(out, file.path(pdir, "results_r.csv"), na = "")
cat("claims:", nrow(claims), " results rows:", nrow(out), " attempted:", sum(!is.na(out$value)), "\n")
cat("unmatched result ids:", paste(setdiff(bind_rows(res)$claim_id, claims$claim_id), collapse = ", "), "\n")
