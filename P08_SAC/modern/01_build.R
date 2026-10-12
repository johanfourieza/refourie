# =============================================================================
# P08_SAC  S6 modern reanalysis  --  01_build.R
# Method card: P08_SAC/modern/method_card.md (FROZEN, commit 17a056d)
#
# Builds the analysis files and runs the card's verification checks (§4 Data):
#   wage spec 4 must reproduce b(Afrikaans) = -0.0568 and N = 7,389;
#   Table 1 means must reproduce 172.91 (England height), 175.03 (Cape/Natal
#   height) and 4.46 (Boer-republic wage) to 2 dp.
# Import follows S2 patch E2 (Augmented sheet of SAC final.xlsx, numeric
# destring); the wage-sample rules follow Occupations.do and the validated S5
# script compare/s5_checks/04_table3_checks.R (Stata missing-age emulation).
#
# Rights: personal. Microdata (incl. surnames) are written ONLY to
# ./P08_SAC/modern/_scratch/. output/ receives aggregates only.
# =============================================================================
suppressMessages({library(tidyverse); library(readxl); library(haven)})
PROJ <- "."
source(file.path(PROJ, "tools", "paths.R"))
MOD <- file.path(PROJ, "P08_SAC", "modern"); OUT <- file.path(MOD, "output")
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
SCR <- dscratch("P08_SAC", "modern")
num <- function(x) suppressWarnings(as.numeric(x))

# ---- 1. Import the Augmented sheet (S2 patch E2: all columns read, destring) ----
X <- dpath("P08_SAC", "original", "FourieSAC2026", "SAC final.xlsx")
a <- read_excel(X, sheet = "Augmented", col_types = "text")
stopifnot(nrow(a) == 10399)

d <- a %>% transmute(
  a_row = row_number(),
  surname = Surname,                                   # stays on D: only
  lwage = num(Lwage), wage = num(Wage), afr = num(Afrikaans), age = num(Age),
  height = num(Height), weight = num(Weight), married = num(Married),
  hisco = num(HISCO), class = num(Class), farmer = num(Farmer), region = Region, regiondum = num(RegionDum),
  country = Country, eyear = num(EYear), emonth = num(EMonth), eday = num(EDay),
  bday = num(Birthday), bmonth = num(Birthmonth), birthyear = num(Birthyear),
  repeatlast = num(Repeatlast), place = Place,
  howlong = `How long in South Africa?`, lang = Languages, lang_other = `Other languages?`)

# ---- 2. Derived variables ----
# Enlistment cluster: EYear x EMonth (card §4). Missing month -> 'year_NA' cell (DEVIATIONS D2).
d <- d %>% mutate(
  ym = if_else(is.na(eyear), "NA_NA", paste(eyear, coalesce(as.character(emonth), "NA"), sep = "_")),
  # Place clusters (sensitivity §5.2): light spelling normalisation; missing '.' = one 'unknown' cluster (D3)
  place_c = tolower(gsub("[^A-Za-z]", "", coalesce(place, ""))),
  place_c = case_when(place_c %in% c("", "na") ~ "unknown",
                      place_c == "namahasha" ~ "nomahasha",
                      grepl("^sydenham", place_c) ~ "sydenham",
                      TRUE ~ place_c),
  sa = as.numeric(regiondum %in% c(5, 9)),
  # age from dates, 365.25-day years (sensitivity §5.9a)
  dob = suppressWarnings(as.Date(sprintf("%04d-%02d-%02d", as.integer(birthyear), as.integer(bmonth), as.integer(bday)))),
  doe = suppressWarnings(as.Date(sprintf("%04d-%02d-%02d", as.integer(eyear), as.integer(emonth), as.integer(eday)))),
  age_dates = as.numeric(doe - dob) / 365.25,
  age_dates = if_else(!is.na(age_dates) & age_dates > 0 & age_dates < 100, age_dates, NA_real_),
  age_adult = coalesce(age_dates, age))

# S3 surname rule, sourced unchanged from repro_r/01_clean.R (afr_list + boer_surname)
ex <- parse(file.path(PROJ, "P08_SAC", "repro_r", "01_clean.R"), keep.source = FALSE)
pick <- Filter(function(e) is.call(e) && identical(e[[1]], as.name("<-")) &&
                 deparse(e[[2]]) %in% c("afr_list", "boer_surname"), as.list(ex))
stopifnot(length(pick) == 2)
s3env <- new.env(); for (e in pick) eval(e, s3env)
d <- d %>% mutate(boer_sn_S3 = s3env$boer_surname(surname),
                  afr_S3 = as.numeric(sa == 1 & coalesce(boer_sn_S3, FALSE)))

# Normalised surname N(s) for the score sensitivity (§5.3b)
normsn <- function(s) {
  s <- tolower(s); s <- iconv(s, to = "ASCII//TRANSLIT"); s <- gsub("[^a-z]", "", s)
  s <- gsub("ij", "y", s); s[is.na(s)] <- ""; s }
d <- d %>% mutate(nsn = normsn(surname))

# Years in South Africa (§5.6): parse 'How long in South Africa?'
parse_howlong <- function(x, age) {
  z <- tolower(trimws(x)); z[z %in% c(".", "")] <- NA
  frac <- function(p) { m <- str_match(z, p); v <- num(m[, 2]); fr <- m[, 3]
    fv <- ifelse(is.na(fr), 0, num(sub("/.*", "", fr)) / num(sub(".*/", "", fr))); ifelse(is.na(v), NA, v + fv) }
  y <- frac("([0-9.]+)(?: ([0-9]+/[0-9]+))? ?(?:years?|yrs?|yr)\\b")
  mo <- num(str_match(z, "([0-9.]+) ?(?:months?|mths?|mos?)\\b")[, 2])
  w <- num(str_match(z, "([0-9.]+) ?(?:weeks?|wks?)\\b")[, 2])
  dd <- num(str_match(z, "([0-9.]+) ?days?\\b")[, 2])
  out <- ifelse(is.na(y) & is.na(mo) & is.na(w) & is.na(dd), NA,
                coalesce(y, 0) + coalesce(mo, 0) / 12 + coalesce(w, 0) / 52.18 + coalesce(dd, 0) / 365.25)
  life <- !is.na(z) & grepl("born|whole life|all (my|his) life|life ?time|always", z)
  out[life & is.na(out)] <- age[life & is.na(out)]
  out }
d <- d %>% mutate(yrs_sa = parse_howlong(howlong, age))

# Language diagnostic (§5.3): recorded Dutch in Languages / Other languages?
lp <- tolower(paste(coalesce(d$lang, ""), coalesce(d$lang_other, "")))
d <- d %>% mutate(lang_any = !(coalesce(lang, ".") %in% c(".", "") & coalesce(lang_other, ".") %in% c(".", "")),
                  dutch_rec = as.numeric(grepl("dutch|hollan|afrik|\\btaal\\b", lp)))

# ---- 3. Samples ----
first <- d %>% filter(repeatlast == 0)
# Wage sample (Occupations.do spec 4): region != "." (NA kept, as Stata ""), repeatlast==0, age>18 incl. missing
W0 <- d %>% filter(is.na(region) | region != ".", is.na(age) | age > 18, repeatlast == 0)
W <- W0 %>% filter(complete.cases(lwage, afr, age, height, weight, married, hisco, regiondum, eyear)) %>%
  mutate(hisco_f = relevel(factor(hisco), "6"), reg_f = relevel(factor(regiondum), "5"), yr_f = factor(eyear),
         england = as.numeric(regiondum == 1))
m4 <- lm(lwage ~ afr + age + height + weight + married + hisco_f + reg_f + yr_f, data = W)

# ---- 4. Verification checks (card §4) ----
b_afr <- unname(coef(m4)["afr"]); b_eng <- unname(coef(m4)["reg_f1"]); N4 <- nobs(m4)
t_conv <- summary(m4)$coefficients["afr", 3]
t_hc1 <- unname(coef(m4)["afr"] / sqrt(diag(sandwich::vcovHC(m4, type = "HC1")))["afr"])
t1 <- first %>% filter(!is.na(regiondum)) %>% group_by(regiondum) %>%
  summarise(h = mean(height, na.rm = TRUE), w = mean(wage, na.rm = TRUE), .groups = "drop")
h_eng <- t1$h[t1$regiondum == 1]; h_cap <- t1$h[t1$regiondum == 9]; w_boer <- t1$w[t1$regiondum == 5]
ver <- tibble(
  check = c("spec4 b(Afrikaans)", "spec4 N", "spec4 b(England)", "spec4 conventional t(Afrikaans)",
            "spec4 HC1 t(Afrikaans) [S5 C7]", "T1 England height", "T1 Cape/Natal height", "T1 Boer-republic wage"),
  target = c(-0.0568, 7389, 0.0777, -12.45, -3.69, 172.91, 175.03, 4.46),
  value = c(b_afr, N4, b_eng, t_conv, t_hc1, h_eng, h_cap, w_boer),
  dp = c(4, 0, 4, 2, 2, 2, 2, 2)) %>%
  mutate(pass = round(value, dp) == target)
print(ver %>% as.data.frame(), digits = 7)
write_csv(ver, file.path(OUT, "verification.csv"))

# ---- 5. Stock A (SAF genealogy) for the score sensitivity; D: only ----
saf <- read_dta(dpath("P04_CF", "original", "CF Mobility", "Data", "SAF mobility data_10.08.2017.dta"),
                col_select = c(individual_id, family_id, surname, year))
stockA <- saf %>% mutate(year = as.numeric(year)) %>% filter(!is.na(individual_id), year >= 1840, year <= 1888) %>%
  distinct(individual_id, .keep_all = TRUE) %>%
  transmute(family_id = as.character(family_id), nsn = normsn(as.character(as_factor(surname))))
cat("Stock A persons:", nrow(stockA), " families:", n_distinct(stockA$family_id), " empty N(s):", sum(stockA$nsn == ""), "\n")

saveRDS(d, file.path(SCR, "sac_all.rds"))
saveRDS(W, file.path(SCR, "wage_sample.rds"))
saveRDS(stockA, file.path(SCR, "stockA.rds"))
saveRDS(list(verification = ver, all_pass = all(ver$pass)), file.path(SCR, "verification.rds"))
cat("All verification checks pass:", all(ver$pass), "\n")
cat("Wage-sample rows with missing EMonth:", sum(is.na(W$emonth)), "; first terms with missing EMonth:", sum(is.na(first$emonth)), "\n")
cat("First terms: yrs_sa non-missing", sum(!is.na(first$yrs_sa)), " of howlong recorded", sum(!(first$howlong %in% c(NA, ".")), na.rm = TRUE), "\n")
cat("age_dates computable (first terms):", sum(!is.na(first$age_dates)), "\n")
