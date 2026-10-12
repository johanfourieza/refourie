# P09_FIM S6 01_sample.R. Card §4 "Common data".
# (1) Loads the S3 analysis sample (repro_r/01_clean.R, commit d0fbc1c) from D: and checks that it
#     reproduces repro_r/output/table2_r.csv (T2 total means) before any estimate.
# (2) Rebuilds the same sample from the raw workbooks with the 01_clean.R rules (copied, unchanged) while
#     carrying a row id and names, verifies identity with the S3 sample, and attaches the flags needed by
#     §4B (candidate repeat pairs), S15c, S17 (S2-8 unflagged repeats) and S19 (relaxed complete-case rule).
# Microdata stay on D:; only aggregate checks are written to output/.
source("./P09_FIM/modern/00_common.R")
suppressPackageStartupMessages({ library(readxl); library(stringr) })

s3 <- readRDS(dpath(P, "repro_r", "_scratch", "analysis_sample.rds"))

# ---- (1) T2 reproduction check -------------------------------------------------------------------
t2 <- s3 %>% group_by(cohort) %>% summarise(mean = mean(height), sd = sd(height), n = n()) %>%
  mutate(cohort = as.character(cohort))
ref2 <- read_csv(file.path(ROOT, P, "repro_r", "output", "table2_r.csv"), show_col_types = FALSE) %>%
  filter(group == "Total") %>% select(cohort, mean_ref = mean, sd_ref = sd, n_ref = n)
ref4 <- read_csv(file.path(ROOT, P, "repro_r", "results_r.csv"), show_col_types = FALSE) %>%
  filter(grepl("^T2_Total_Total_c[1-6]$", claim_id)) %>%
  transmute(cohort = COH[as.integer(sub(".*_c", "", claim_id))], mean_ref4 = value)
chk <- t2 %>% left_join(ref2, by = "cohort") %>% left_join(ref4, by = "cohort") %>%
  mutate(d_tab2 = abs(round(mean, 2) - mean_ref), d_res4 = abs(round(mean, 4) - mean_ref4),
         d_sd = abs(round(sd, 2) - sd_ref), d_n = abs(n - n_ref))
chk$pass <- with(chk, d_tab2 < 1e-6 & d_res4 < 1e-6 & d_sd < 1e-6 & d_n == 0)
write_csv(chk %>% select(cohort, n, mean_ref, mean_ref4, d_tab2, d_res4, d_sd, d_n, pass),
          file.path(OUT, "check_t2_reproduction.csv"))
REPRO_OK <- all(chk$pass)
cat("T2 reproduction check:", REPRO_OK, "\n")

# ---- (2) Rebuild with ids and names (01_clean.R rules, verbatim logic) ----------------------------
src_dir <- dpath(P, "original", "FM White living standards")
num <- function(v) suppressWarnings(as.numeric(v))
raw <- read_excel(file.path(src_dir, "Whitelivingstandards_7July.xlsx"), sheet = "Data", col_types = "text")
regions <- c("Western Cape" = "WCape", "Eastern Cape" = "ECape", "Northern Cape" = "NCape",
             "Natal" = "Natal", "Orange Free State" = "OFS", "Transvaal" = "Tvl")
a <- raw %>% transmute(
  rid = paste0("D", row_number()),
  nm = str_to_lower(str_squish(paste(Names, Surname))),
  force = Source, year = num(Year), age = num(Age), birthyear = num(Birthyear), height = num(Height),
  calling = str_squish(str_to_lower(Calling)), hisco1 = num(HISCO), region = unname(regions[Region]),
  urban = num(Urban), black = num(Black), natdum = num(Nationalitydum), repeat_ = num(Repeat)) %>%
  mutate(white = case_when(force == "WWI" ~ natdum == 4, TRUE ~ is.na(black) | black == 0))

# S2-8 unflagged repeats, defined exactly as compare/s5_checks/s5_02_rebuild_checks.R (6)
dup <- a %>% filter(!is.na(birthyear), nchar(nm) > 3) %>% group_by(nm, birthyear) %>%
  mutate(k = n(), ord = row_number()) %>% ungroup()
unfl_ids <- dup %>% filter(k > 1, ord > 1, is.na(repeat_) | repeat_ != 1, !is.na(region)) %>% pull(rid)

w2raw <- read_excel(file.path(src_dir, "WhitesWWII.xlsx"), sheet = "WhitesWW2", col_types = "text")
w2 <- w2raw %>% transmute(rid = paste0("W", row_number()), biryr = num(biryr), age = num(age), newyr = num(newyr),
                          birco = str_squish(str_to_lower(birco)), htft = num(htft), htin = num(htin)) %>%
  mutate(year = if_else(newyr >= 39 & newyr <= 46, 1900 + newyr, NA_real_),
         by_a = 1800 + biryr, by_b = 1900 + biryr,
         birthyear = case_when(!is.na(year) & !is.na(age) & abs(year - by_b - age) <= 1 ~ by_b,
                               !is.na(year) & !is.na(age) & abs(year - by_a - age) <= 1 ~ by_a, TRUE ~ NA_real_),
         htft = if_else(htft %in% c(4, 5, 6), htft, NA_real_),
         htin = if_else(htin >= 0 & htin < 12, htin, NA_real_),
         height = (htft * 12 + htin) * 2.54, force = "WWII", region = NA_character_, urban = NA_real_,
         calling = NA_character_, hisco1 = NA_real_, white = TRUE, repeat_ = 0, sa_born = birco %in% c("rsa"),
         nm = NA_character_)
pool <- bind_rows(a %>% mutate(sa_born = !is.na(region)),
                  w2 %>% select(rid, nm, force, year, age, birthyear, height, calling, hisco1, region, urban,
                                white, repeat_, sa_born))
base <- pool %>% filter(sa_born, white, is.na(repeat_) | repeat_ != 1, between(year, 1890, 1945),
                        between(birthyear, 1865, 1920), age > 20, age < 50, !is.na(height))
occ_rules <- read_csv(file.path(ROOT, P, "repro_r", "occupation_rules.csv"), show_col_types = FALSE)
classify_occ <- function(calling, hisco1) {
  out <- rep(NA_character_, length(calling))
  for (i in seq_len(nrow(occ_rules))) {
    hit <- is.na(out) & !is.na(calling) & str_detect(calling, regex(occ_rules$pattern[i])); out[hit] <- occ_rules$class[i]
  }
  fb <- case_when(hisco1 == 6 ~ "Agriculture", hisco1 %in% c(0, 1, 2) ~ "Middle_class",
                  hisco1 %in% c(3, 4, 7, 8, 9) ~ "Skilled", hisco1 == 5 ~ "Semi_skilled", TRUE ~ NA_character_)
  out[is.na(out)] <- fb[is.na(out)]; out[out == "NONE"] <- NA_character_; out
}
base <- base %>% mutate(
  cohort = cut(birthyear, c(1864, 1874, 1884, 1894, 1904, 1914, 1920), labels = COH),
  attest = year - 1900, occ = classify_occ(calling, hisco1),
  town = case_when(urban == 1 ~ "gt10000", urban == 0 ~ "lt10000", TRUE ~ NA_character_),
  force = factor(force, levels = c("WWI", "SAC", "CMP", "AOF", "WWII")),
  complete = force == "WWII" | (!is.na(region) & !is.na(occ) & !is.na(town)))
rb <- base %>% filter(complete)

# Identity with the S3 sample (same row order by construction)
cols <- c("force", "year", "age", "birthyear", "height", "calling", "hisco1", "region", "urban", "repeat_",
          "cohort", "attest", "occ", "town")
same <- nrow(rb) == nrow(s3) && all(sapply(cols, function(v) identical(as.vector(rb[[v]]), as.vector(s3[[v]]))))
cat("Rebuilt sample identical to S3 sample:", same, "\n")
if (!same) stop("rebuilt sample differs from the S3 analysis sample")

# Flags: candidate repeat pairs (forename + surname + birth year, across rows; WWII carries no names)
flag_pairs <- function(d) d %>% group_by(key = if_else(!is.na(nm) & nchar(nm) > 3, paste(nm, birthyear), NA_character_)) %>%
  mutate(pair_k = if_else(is.na(key), 1L, n())) %>% ungroup() %>%
  mutate(pair_cl = if_else(pair_k > 1, paste0("P_", key), rid)) %>% select(-key)
smp <- rb %>% mutate(unfl_repeat = rid %in% unfl_ids) %>% flag_pairs()
rel <- base %>% mutate(unfl_repeat = rid %in% unfl_ids, added_s19 = !complete) %>% flag_pairs()
saveRDS(smp, file.path(SCR, "sample_modern.rds"))
saveRDS(rel, file.path(SCR, "sample_relaxed_s19.rds"))

ck <- tibble(check = c("T2 totals reproduce table2_r.csv (2 dp) and results_r.csv (4 dp)",
                       "rebuilt sample identical to S3 analysis_sample.rds", "N S3 sample",
                       "S2-8 unflagged repeats in Data (SA-born)", "of which in the S3 sample",
                       "S19 records added back (missing occupation or town only)"),
             value = c(REPRO_OK, same, nrow(smp), length(unfl_ids), sum(smp$unfl_repeat), sum(rel$added_s19)))
write_csv(ck, file.path(OUT, "check_sample.csv"))
print(ck)
