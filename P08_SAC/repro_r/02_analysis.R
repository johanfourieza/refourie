# =============================================================================
# P08_SAC  S3 independent R recreation  --  02_analysis.R
# Recreates Tables 1-7 (incl. Table 3 wage regressions) and the text numbers in
# claims.csv from the cleaned data of 01_clean.R. Writes aggregate outputs only.
# =============================================================================

suppressMessages({
  library(tidyverse)
  library(sandwich)
  library(lmtest)
  library(modelsummary)
  library(kableExtra)
})
set.seed(20171)

PROJ <- Sys.getenv("REPLICATEME_ROOT",
                   ".")
source(file.path(PROJ, "tools", "paths.R"))
RR   <- file.path(PROJ, "P08_SAC", "repro_r")
OUT  <- file.path(RR, "output"); dir.create(OUT, showWarnings = FALSE)
SCR  <- dscratch("P08_SAC", "repro_r")

terms   <- readRDS(file.path(SCR, "sac_terms.rds"))
persons <- readRDS(file.path(SCR, "sac_persons.rds"))   # first term per person
claims  <- read_csv(file.path(PROJ, "P08_SAC", "claims", "claims.csv"), show_col_types = FALSE)

REG <- c("Americas","Asia","Australasia","Boer republics","England","Europe",
         "Ireland","Scotland","Southern Africa","Wales")
reg_key <- c(Americas="Americas", Asia="Asia", Australasia="Australasia",
             `Boer republics`="Boerrepublics", England="England", Europe="Europe",
             Ireland="Ireland", Scotland="Scotland", `Southern Africa`="SouthernAfrica",
             Wales="Wales", Total="Total")
res <- list()
add <- function(id, value, se = NA, n = NA, status = NA) {
  res[[length(res) + 1]] <<- tibble(claim_id = id, source = "r", value = as.numeric(value),
                                    se = as.numeric(se), n = as.numeric(n),
                                    status_override = as.character(status))
}
mean_na <- function(x) mean(x, na.rm = TRUE)
p <- persons %>% filter(!is.na(region))

# -----------------------------------------------------------------------------
# Table 1: means by region of birth, first terms only (repeats dropped)
# -----------------------------------------------------------------------------
t1vars <- c(wage="wage", age="age", height="height_cm", weight="weight_kg", married="married",
            farmer="farmer", rc="rc", chest="chest", died="died", tenure="tenure")
t1 <- bind_rows(
  p %>% group_by(region) %>% summarise(across(all_of(unname(t1vars)), mean_na), .groups = "drop"),
  persons %>% summarise(across(all_of(unname(t1vars)), mean_na)) %>% mutate(region = "Total"))
t1n <- persons %>% summarise(across(all_of(unname(t1vars)), ~ sum(!is.na(.x))))
for (r in c(REG, "Total")) for (v in names(t1vars))
  add(paste0("T1_", reg_key[[r]], "_", v), t1[[t1vars[[v]]]][t1$region == r],
      n = if (r == "Total") t1n[[t1vars[[v]]]] else
        sum(!is.na(p[[t1vars[[v]]]][p$region == r])))
for (v in names(t1vars)) add(paste0("T1_nobs_", v), t1n[[t1vars[[v]]]], n = t1n[[t1vars[[v]]]])
t1_out <- t1 %>% mutate(region = factor(region, c(REG, "Total"))) %>% arrange(region) %>%
  rename(Wage = wage, Age = age, Height = height_cm, Weight = weight_kg, Married = married,
         Farmer = farmer, RC = rc, Chest = chest, Died = died, Tenure = tenure)
write_csv(t1_out, file.path(OUT, "table1.csv"))
kbl(t1_out %>% mutate(across(where(is.numeric), ~ round(.x, 2))), format = "latex",
    booktabs = TRUE, caption = "Personal characteristics by region of birth (R recreation)") %>%
  save_kable(file.path(OUT, "table1.tex"))

# -----------------------------------------------------------------------------
# Table 2: additional characteristics (%), first terms
# -----------------------------------------------------------------------------
t2vars <- c(blueeyes="blue_eyes", redorruddyhair="red_hair", speaksblacklang="black_lang",
            speaksfrench="french", hastattoo="tattoo", canride="ride", canshoot="shoot", canswim="swim")
t2 <- bind_rows(
  p %>% group_by(region) %>% summarise(across(all_of(unname(t2vars)), ~ 100 * mean_na(.x)), .groups = "drop"),
  persons %>% summarise(across(all_of(unname(t2vars)), ~ 100 * mean_na(.x))) %>% mutate(region = "Total"))
for (r in c(REG, "Total")) for (v in names(t2vars))
  add(paste0("T2_", reg_key[[r]], "_", v), t2[[t2vars[[v]]]][t2$region == r],
      n = if (r == "Total") sum(!is.na(persons[[t2vars[[v]]]])) else sum(!is.na(p[[t2vars[[v]]]][p$region == r])))
write_csv(t2, file.path(OUT, "table2.csv"))
kbl(t2 %>% mutate(across(where(is.numeric), ~ round(.x, 1))), format = "latex", booktabs = TRUE,
    caption = "Additional characteristics (%) (R recreation)") %>% save_kable(file.path(OUT, "table2.tex"))

# -----------------------------------------------------------------------------
# Table 3: OLS of log wage. Conventional (published analogue) and HC1 SEs.
#   Spec 1: Afrikaans only, SA-born recruits (Boer republics + Southern Africa)
#   Spec 2: + age, height, weight, married (all regions)
#   Spec 3: + HISCO major groups (6 = ref) + region of birth (Boer republics = ref)
#   Spec 4: + enlistment-year dummies 1901-1907 (1900 = ref; 1908-09 excluded)
# -----------------------------------------------------------------------------
rd <- persons %>%
  mutate(lwage = log(wage),
         hisco = relevel(factor(hisco_major), ref = "6"),
         reg = relevel(factor(region), ref = "Boer republics"),
         yr = factor(enl_year))
m1 <- lm(lwage ~ afrikaans, data = rd %>% filter(sa_born, !is.na(lwage)))
m2 <- lm(lwage ~ afrikaans + age + height_cm + weight_kg + married, data = rd)
m3 <- lm(lwage ~ afrikaans + age + height_cm + weight_kg + married + hisco + reg, data = rd)
m4 <- lm(lwage ~ afrikaans + age + height_cm + weight_kg + married + hisco + reg + yr,
         data = rd %>% filter(enl_year <= 1907))
mods <- list(`Spec (1)` = m1, `Spec (2)` = m2, `Spec (3)` = m3, `Spec (4)` = m4)
term_key <- c(afrikaans="afrikaans", age="age", height_cm="height", weight_kg="weight",
              married="married", `(Intercept)`="constant",
              setNames(paste0("hisco", c(0:5, 7:9)), paste0("hisco", c(0:5, 7:9))),
              regAmericas="americas", regAsia="asia", regAustralasia="australasia",
              regEngland="england", regEurope="europe", regIreland="ireland",
              regScotland="scotland", `regSouthern Africa`="capecolonynatal", regWales="wales",
              setNames(as.character(1901:1907), paste0("yr", 1901:1907)))
t3 <- map2_dfr(mods, seq_along(mods), function(m, s) {
  ct  <- coeftest(m)                                  # conventional
  ch  <- coeftest(m, vcov. = vcovHC(m, type = "HC1"))
  tibble(spec = s, term = rownames(ct), coef = ct[, 1], se = ct[, 2], t = ct[, 3],
         se_hc1 = ch[, 2], t_hc1 = ch[, 3], n = nobs(m), r2 = summary(m)$r.squared)
})
write_csv(t3, file.path(OUT, "table3_long.csv"))
for (i in seq_len(nrow(t3))) {
  k <- term_key[t3$term[i]]; if (is.na(k)) next
  id <- paste0("T3_", k, "_s", t3$spec[i])
  add(id, t3$coef[i], se = t3$se[i], n = t3$n[i])
  add(paste0(id, "_t"), t3$t[i], n = t3$n[i])
}
for (s in 1:4) {
  add(paste0("T3_r2_s", s), summary(mods[[s]])$r.squared, n = nobs(mods[[s]]))
  add(paste0("T3_n_s", s), nobs(mods[[s]]), n = nobs(mods[[s]]))
}
modelsummary(mods, output = file.path(OUT, "table3.tex"), statistic = "statistic",
             stars = c(`*` = .05, `**` = .01, `***` = .001), fmt = 3,
             gof_map = c("nobs", "r.squared"),
             title = "Log wage regressions, conventional t-statistics (R recreation)")
modelsummary(mods, output = file.path(OUT, "table3_hc1.tex"), statistic = "statistic",
             vcov = "HC1", stars = c(`*` = .05, `**` = .01, `***` = .001), fmt = 3,
             gof_map = c("nobs", "r.squared"),
             title = "Log wage regressions, HC1 t-statistics (R recreation)")

# -----------------------------------------------------------------------------
# Table 4: occupational class by year of enrolment (%), first terms
# -----------------------------------------------------------------------------
cl_key <- c(Farmers = "farmers", `Upper, middle` = "whitecollar", Lower = "bluecollar")
t4 <- persons %>% filter(!is.na(occ_class), !is.na(enl_year)) %>%
  mutate(yr = if_else(enl_year <= 1906, as.character(enl_year), NA_character_))
t4y <- t4 %>% filter(!is.na(yr)) %>% count(yr, occ_class) %>% group_by(yr) %>% mutate(pct = 100 * n / sum(n)) %>% ungroup()
t4t <- persons %>% filter(!is.na(occ_class)) %>% count(occ_class) %>% mutate(pct = 100 * n / sum(n), yr = "total")
t4all <- bind_rows(t4y, t4t)
for (i in seq_len(nrow(t4all))) add(paste0("T4_", cl_key[[t4all$occ_class[i]]], "_", t4all$yr[i]), t4all$pct[i])
write_csv(t4all %>% select(-n) %>% pivot_wider(names_from = yr, values_from = pct), file.path(OUT, "table4.csv"))

# -----------------------------------------------------------------------------
# Table 5: occupational class by region (%), first terms
# -----------------------------------------------------------------------------
cl5 <- c(Farmers = "farmers", `Upper, middle` = "uppermiddle", Lower = "lower")
t5 <- bind_rows(p %>% filter(!is.na(occ_class)) %>% count(region, occ_class),
                persons %>% filter(!is.na(occ_class)) %>% count(occ_class) %>% mutate(region = "Total")) %>%
  group_by(region) %>% mutate(pct = 100 * n / sum(n)) %>% ungroup()
for (i in seq_len(nrow(t5))) add(paste0("T5_", reg_key[[t5$region[i]]], "_", cl5[[t5$occ_class[i]]]), t5$pct[i])
write_csv(t5 %>% select(-n) %>% pivot_wider(names_from = occ_class, values_from = pct), file.path(OUT, "table5.csv"))

# -----------------------------------------------------------------------------
# Table 6: HISCO minor groups (first terms with a calling)
# -----------------------------------------------------------------------------
t6 <- persons %>% filter(!is.na(hisco2)) %>% count(hisco2) %>% mutate(pct = 100 * n / sum(n))
N6 <- sum(t6$n)
pub6 <- claims %>% filter(str_detect(claim_id, "^T6_[0-9]{2}_freq")) %>% mutate(h = substr(claim_id, 4, 5)) %>% pull(h)
for (h in pub6) {
  r <- t6 %>% filter(hisco2 == h)
  add(paste0("T6_", h, "_freq"), if (nrow(r)) r$n else 0, n = N6)
  add(paste0("T6_", h, "_pct"), if (nrow(r)) r$pct else 0, n = N6)
}
add("T6_total_freq", N6, n = N6); add("T6_total_pct", 100, n = N6)
write_csv(t6, file.path(OUT, "table6.csv"))
kbl(t6 %>% mutate(pct = round(pct, 2)), format = "latex", booktabs = TRUE,
    caption = "HISCO minor groups (R recreation; own coding)") %>% save_kable(file.path(OUT, "table6.tex"))

# -----------------------------------------------------------------------------
# Table 7: HISCO major group by region (column %)
# -----------------------------------------------------------------------------
r7 <- c(Americas="america", Asia="asia", Australasia="australasia", `Boer republics`="boerrep",
        England="england", Europe="europe", Ireland="ireland", Scotland="scotland",
        `Southern Africa`="capecolonynatal", Wales="wales", Total="total")
t7 <- bind_rows(p %>% filter(!is.na(hisco_major)) %>% count(region, hisco_major),
                persons %>% filter(!is.na(hisco_major)) %>% count(hisco_major) %>% mutate(region = "Total")) %>%
  complete(region, hisco_major, fill = list(n = 0)) %>%
  group_by(region) %>% mutate(pct = 100 * n / sum(n)) %>% ungroup()
for (i in seq_len(nrow(t7))) add(paste0("T7_h", t7$hisco_major[i], "_", r7[[t7$region[i]]]), t7$pct[i])
write_csv(t7 %>% select(-n) %>% pivot_wider(names_from = region, values_from = pct), file.path(OUT, "table7.csv"))

# -----------------------------------------------------------------------------
# Text claims
# -----------------------------------------------------------------------------
NA_ATT <- function(id) add(id, NA, status = "not-attempted")
add("tx_p580_terms", nrow(terms)); add("tx_p583_terms", nrow(terms))
add("tx_p582_men", nrow(persons)); add("tx_p583_individuals", nrow(persons))
add("tx_p583_second", sum(persons$n_terms >= 2)); add("tx_p583_third", sum(persons$n_terms >= 3))
add("tx_p583_fourth", sum(persons$n_terms >= 4))
for (id in c("tx_p581_months","tx_p581_districts","tx_p581_subdistricts","tx_p581_posts",
             "tx_p581_peak","tx_p581_1908","tx_p591_ht_ww1","tx_p591_ht_ww2")) NA_ATT(id)
ty <- terms %>% filter(!is.na(enl_year))
add("tx_p584_1904", 100 * mean(ty$enl_year == 1904), n = nrow(ty))
tl <- terms %>% filter(!is.na(term_len_yrs))
add("tx_p584_3yr", 100 * mean(tl$term_len_yrs == 3), n = nrow(tl))
tm <- terms %>% filter(!is.na(enl_month))
add("tx_p584_autumn", 100 * mean(tm$enl_month %in% 3:5), n = nrow(tm))
tp <- terms %>% filter(!is.na(place_enl))
add("tx_p584_heidelberg", 100 * mean(tp$place_enl == "Heidelberg"), n = nrow(tp))
add("tx_p584_pretoria", 100 * mean(tp$place_enl == "Pretoria"), n = nrow(tp))
add("tx_p584_modder", 100 * mean(tp$place_enl == "Modderfontein"), n = nrow(tp))
add("tx_p584_towns", n_distinct(tp$place_enl))
pc <- persons %>% filter(!is.na(country_std)); Nc <- nrow(pc)
sh <- function(cs) 100 * mean(pc$country_std %in% cs)
cn <- function(cs) sum(pc$country_std %in% cs)
add("tx_p584_england", sh("England"), n = Nc); add("tx_p584_scotland", sh("Scotland"), n = Nc)
add("tx_p584_ireland", sh("Ireland"), n = Nc); add("tx_p585_wales", sh("Wales"), n = Nc)
add("tx_p585_uk", sh(c("England","Scotland","Ireland","Wales")), n = Nc)
loc <- c("Cape Colony","Natal","Transvaal","Orange Free State","Boer republic (unspecified)","South Africa")
add("tx_p585_locals_pct", sh(loc), n = Nc); add("tx_p585_locals_n", cn(loc))
add("tx_p585_cape", sh("Cape Colony"), n = Nc); add("tx_p585_natal", sh("Natal"), n = Nc)
add("tx_p585_ofs", sh("Orange Free State"), n = Nc); add("tx_p585_tvl", sh("Transvaal"), n = Nc)
add("tx_p585_sa_n", cn("South Africa")); add("tx_p585_sa_pct", sh("South Africa"), n = Nc)
add("tx_p585_otherSA", cn("Other southern Africa"))
add("tx_p585_aus_n", cn("Australia")); add("tx_p585_aus_pct", sh("Australia"), n = Nc)
add("tx_p585_can_n", cn("Canada")); add("tx_p585_can_pct", sh("Canada"), n = Nc)
add("tx_p585_india", cn("India")); add("tx_p585_nz", cn("New Zealand")); add("tx_p585_us", cn("USA"))
add("tx_p585_boers", sum(persons$afrikaans))
tv <- persons %>% filter(country_std == "Transvaal"); cp <- persons %>% filter(country_std == "Cape Colony")
add("tx_p585_tvl_boer_n", sum(tv$afrikaans)); add("tx_p585_tvl_boer_pct", 100 * mean(tv$afrikaans), n = nrow(tv))
add("tx_p585_tvl_n", nrow(tv))
add("tx_p585_cape_boer_n", sum(cp$afrikaans)); add("tx_p585_cape_boer_pct", 100 * mean(cp$afrikaans), n = nrow(cp))
add("tx_p585_cape_n", nrow(cp))
add("tx_p586_youngest", min(terms$age_reported, na.rm = TRUE))
add("tx_p586_oldest", max(terms$age_reported, na.rm = TRUE))
gm <- function(v, regs) mean(p[[v]][p$region %in% regs], na.rm = TRUE)
add("tx_p588_wage_csa", gm("wage", "Southern Africa")); add("tx_p588_wage_boer", gm("wage", "Boer republics"))
add("tx_p588_wage_all", mean_na(persons$wage))
add("tx_p588_age_boer", gm("age", "Boer republics")); add("tx_p588_age_all", mean_na(persons$age))
col_regs <- c("Americas","Australasia","Asia","Southern Africa","Boer republics")
for (pg in c("p588", "p591")) {
  add(paste0("tx_", pg, "_ht_col"), gm("height_cm", col_regs))
  add(paste0("tx_", pg, "_ht_engsco"), gm("height_cm", c("England","Scotland")))
  add(paste0("tx_", pg, "_ht_wales"), gm("height_cm", "Wales"))
}
dt <- terms %>% filter(died == 1)
add("tx_p588_died", nrow(dt))
add("tx_p588_died_unknown", sum(dt$died_cause == "unknown")); add("tx_p588_died_battle", sum(dt$died_cause == "battle"))
add("tx_p588_died_enteric", sum(dt$died_cause == "enteric")); add("tx_p588_died_drown", sum(dt$died_cause == "drowning"))
add("tx_p588_died_suicide", sum(dt$died_cause == "suicide"))
add("tx_p588_died_wales", 100 * gm("died", "Wales"))
add("tx_p588_tenure_all", mean_na(persons$tenure), n = sum(!is.na(persons$tenure)))
add("tx_p588_tenure_boer", gm("tenure", "Boer republics")); add("tx_p599_tenure_boer", gm("tenure", "Boer republics"))
add("tx_p588_tenure_sco", gm("tenure", "Scotland")); add("tx_p588_tenure_eng", gm("tenure", "England"))
add("tx_p599_tenure_gap", gm("tenure", c("England","Scotland","Ireland","Wales","Europe")) - gm("tenure", "Boer republics"))
ex <- terms %>% filter(!is.na(exit)); Ne <- nrow(ex)
exs <- function(k) 100 * mean(ex$exit == k)
add("tx_p588_exit_expired", exs("expired"), n = Ne); add("tx_p588_exit_purchase", exs("purchase"), n = Ne)
add("tx_p588_exit_free", exs("free"), n = Ne); add("tx_p588_exit_dismiss", exs("dismissal"), n = Ne)
add("tx_p588_exit_unfit", exs("unfit"), n = Ne); add("tx_p588_exit_retrench", exs("retrenchment"), n = Ne)
add("tx_p588_exit_transfer", exs("transfer"), n = Ne); add("tx_p588_exit_desert_pct", exs("desertion"), n = Ne)
add("tx_p588_exit_desert_n", sum(ex$exit == "desertion"))
add("tx_p589_french", 100 * mean_na(persons$french)); add("tx_p589_tattoo_wales", 100 * gm("tattoo", "Wales"))
sa <- persons %>% filter(sa_born, !is.na(height_cm))
add("tx_p591_ht_dutch", mean(sa$height_cm[sa$afrikaans == 1])); add("tx_p591_ht_dutch_n", sum(sa$afrikaans == 1))
add("tx_p591_ht_eng", mean(sa$height_cm[sa$afrikaans == 0])); add("tx_p591_ht_eng_n", sum(sa$afrikaans == 0))
tt <- t.test(height_cm ~ afrikaans, data = sa)
write_csv(tibble(test = "Welch t, height Dutch- vs English-surname SA-born", t = unname(tt$statistic), p = tt$p.value),
          file.path(OUT, "height_dutch_english_test.csv"))
pw <- persons %>% filter(!is.na(wage))
add("tx_p592_5s", 100 * mean(pw$wage == 5), n = nrow(pw))
add("tx_p592_4s", sum(pw$wage >= 4 & pw$wage < 5)); add("tx_p592_3s", sum(pw$wage < 4))
add("tx_p593_wage_dutch_col", mean_na(persons$wage[persons$afrikaans == 1 & persons$region %in% "Southern Africa"]))
add("tx_p593_wage_dutch_rep", mean_na(persons$wage[persons$afrikaans == 1 & persons$region %in% "Boer republics"]))
add("tx_p593_wage_nonSA", mean_na(persons$wage[!persons$sa_born & !is.na(persons$region)]))
b_afr <- coef(m4)["afrikaans"]; b_eng <- coef(m4)["regEngland"]
add("tx_p594_gap_dutch", -100 * (exp(b_afr) - 1))
add("tx_p594_gap_boer", 100 * (1 - exp(-b_eng)))
f4 <- t4y %>% filter(occ_class == "Farmers")
add("tx_p594_farmer_peak", max(f4$pct)); add("tx_p594_farmer_1906", f4$pct[f4$yr == "1906"])
add("tx_p596_boer_farm", t5$pct[t5$region == "Boer republics" & t5$occ_class == "Farmers"])
add("tx_p596_othersa_farm", t5$pct[t5$region == "Southern Africa" & t5$occ_class == "Farmers"])
add("tx_p596_eng_farm", t5$pct[t5$region == "England" & t5$occ_class == "Farmers"])
add("tx_p596_occs", n_distinct(terms$calling_norm, na.rm = TRUE))
g7 <- function(h, r) sum(t7$pct[t7$hisco_major %in% h & t7$region == r])
add("tx_p597_farm", g7("6", "Total") / 100)
add("tx_p597_clerical", t6$pct[t6$hisco2 == "30"]); add("tx_p597_protective", t6$pct[t6$hisco2 == "58"])
NA_ATT("tx_p597_5each")
add("tx_p597_asia_prof", g7(c("0","1"), "Asia") / 100); add("tx_p597_boer_prof", g7(c("0","1"), "Boer republics"))
add("tx_p597_boer_ag", g7("6", "Boer republics")); add("tx_p597_wales_ag", g7("6", "Wales")); add("tx_p597_asia_ag", g7("6", "Asia"))
add("tx_p597_cape_cler", g7("3", "Southern Africa")); add("tx_p597_irish_sales", g7("4", "Ireland"))
pwl <- persons %>% filter(region == "Wales", !is.na(hisco2))
add("tx_p597_welsh_miners", 100 * mean(pwl$hisco2 == "71"))
add("tx_p597_golfers", sum(grepl("golf", terms$calling_norm) & !grepl("club maker", terms$calling_norm)))
add("tx_p597_bushmen", sum(grepl("bushman", terms$calling_norm)))
add("tx_p597_cowboys", sum(grepl("cowboy", terms$calling_norm)))

# -----------------------------------------------------------------------------
# Write results_r.csv (one row per claim, in claims.csv order)
# -----------------------------------------------------------------------------
R_all <- bind_rows(res) %>% distinct(claim_id, .keep_all = TRUE)
out <- claims %>% select(claim_id) %>% left_join(R_all, by = "claim_id") %>%
  mutate(source = "r",
         status_override = if_else(is.na(value) & is.na(status_override), "not-attempted", status_override))
extra <- setdiff(R_all$claim_id, claims$claim_id)
if (length(extra)) message("Computed but not in claims.csv: ", paste(extra, collapse = ", "))
write_csv(out, file.path(RR, "results_r.csv"), na = "")
cat("results_r.csv rows:", nrow(out), " attempted:", sum(!is.na(out$value)), "\n")
