# P09_FIM — S3 independent recreation. 01_clean.R
# Builds the pooled analysis sample (AOF, CMP, SAC, WWI, WWII) from the allow-listed
# workbooks. See decisions.md for every choice. Microdata stay on D: (_scratch); only
# aggregate counts are written to output/.

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
})
source(file.path(here::here(), "tools", "paths.R"))
set.seed(20221)

src_dir <- dpath("P09_FIM", "original", "FM White living standards")
out_dir <- file.path(here::here(), "P09_FIM", "repro_r", "output")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
scr <- dscratch("P09_FIM", "repro_r")

num <- function(v) suppressWarnings(as.numeric(v))

# ---- 1. Colonial forces and WWI (sheet Data) ---------------------------------
raw <- read_excel(file.path(src_dir, "Whitelivingstandards_7July.xlsx"),
                  sheet = "Data", col_types = "text")

regions <- c("Western Cape" = "WCape", "Eastern Cape" = "ECape", "Northern Cape" = "NCape",
             "Natal" = "Natal", "Orange Free State" = "OFS", "Transvaal" = "Tvl")

a <- raw %>%
  transmute(
    force     = Source,
    year      = num(Year),
    age       = num(Age),
    birthyear = num(Birthyear),
    height    = num(Height),
    calling   = str_squish(str_to_lower(Calling)),
    hisco1    = num(HISCO),              # HISCO major group only (0-9)
    region    = unname(regions[Region]), # NA when born outside the four colonies
    urban     = num(Urban),              # 1 = town of >= 10,000 (see decisions.md D6)
    black     = num(Black),
    natdum    = num(Nationalitydum),
    repeat_   = num(Repeat)
  )

n_raw_data <- nrow(a)

a <- a %>%
  mutate(white = case_when(force == "WWI" ~ natdum == 4,   # RACE == W
                           TRUE ~ is.na(black) | black == 0))

# ---- 2. WWII (sheet WhitesWW2) -----------------------------------------------
w2raw <- read_excel(file.path(src_dir, "WhitesWWII.xlsx"),
                    sheet = "WhitesWW2", col_types = "text")
n_raw_wwii <- nrow(w2raw)

w2 <- w2raw %>%
  transmute(
    biryr = num(biryr), age = num(age), newyr = num(newyr),
    birco = str_squish(str_to_lower(birco)),
    htft = num(htft), htin = num(htin)
  ) %>%
  mutate(
    year = if_else(newyr >= 39 & newyr <= 46, 1900 + newyr, NA_real_),
    # two-digit birth year: choose the century that agrees with age at enlistment (+/- 1)
    by_a = 1800 + biryr, by_b = 1900 + biryr,
    birthyear = case_when(
      !is.na(year) & !is.na(age) & abs(year - by_b - age) <= 1 ~ by_b,
      !is.na(year) & !is.na(age) & abs(year - by_a - age) <= 1 ~ by_a,
      TRUE ~ NA_real_),
    htft = if_else(htft %in% c(4, 5, 6), htft, NA_real_),
    htin = if_else(htin >= 0 & htin < 12, htin, NA_real_),
    height = (htft * 12 + htin) * 2.54,
    force = "WWII", region = NA_character_, urban = NA_real_, calling = NA_character_,
    hisco1 = NA_real_, white = TRUE, repeat_ = 0,
    sa_born = birco %in% c("rsa")
  )

# ---- 3. Pool and apply the paper's sample rules (p.5) ------------------------
pool <- bind_rows(
  a %>% mutate(sa_born = !is.na(region)),
  w2 %>% select(force, year, age, birthyear, height, calling, hisco1, region, urban,
                white, repeat_, sa_born)
)

flow <- tibble(step = "raw rows (Data + WhitesWW2)", n = nrow(pool))
step <- function(d, lab) { force(d); flow <<- bind_rows(flow, tibble(step = lab, n = nrow(d))); d }

sample <- pool %>%
  filter(sa_born)                              %>% step("born in Cape/Natal/OFS/Tvl") %>%
  filter(white)                                %>% step("White") %>%
  filter(is.na(repeat_) | repeat_ != 1)        %>% step("drop repeat enlistments") %>%
  filter(between(year, 1890, 1945))            %>% step("recruited 1890-1945") %>%
  filter(between(birthyear, 1865, 1920))       %>% step("born 1865-1920") %>%
  filter(age > 20, age < 50)                   %>% step("aged 21-49 at enlistment (older than 20, younger than 50)") %>%
  filter(!is.na(height))                       %>% step("height observed")

# ---- 4. Derived variables -----------------------------------------------------
cohort_lab <- c("1865_1874", "1875_1884", "1885_1894", "1895_1904", "1905_1914", "1915_1920")

occ_rules <- read_csv(file.path(here::here(), "P09_FIM", "repro_r", "occupation_rules.csv"),
                      show_col_types = FALSE)
classify_occ <- function(calling, hisco1) {
  out <- rep(NA_character_, length(calling))
  for (i in seq_len(nrow(occ_rules))) {
    hit <- is.na(out) & !is.na(calling) & str_detect(calling, regex(occ_rules$pattern[i]))
    out[hit] <- occ_rules$class[i]
  }
  # Fallback on the HISCO major group where no keyword fires (decisions.md D5)
  fb <- case_when(hisco1 == 6 ~ "Agriculture",
                  hisco1 %in% c(0, 1, 2) ~ "Middle_class",
                  hisco1 %in% c(3, 4, 7, 8, 9) ~ "Skilled",
                  hisco1 == 5 ~ "Semi_skilled",
                  TRUE ~ NA_character_)
  out[is.na(out)] <- fb[is.na(out)]
  out[out == "NONE"] <- NA_character_
  out
}

sample <- sample %>%
  mutate(
    cohort = cut(birthyear, c(1864, 1874, 1884, 1894, 1904, 1914, 1920), labels = cohort_lab),
    attest = year - 1900,
    occ    = classify_occ(calling, hisco1),
    town   = case_when(urban == 1 ~ "gt10000", urban == 0 ~ "lt10000", TRUE ~ NA_character_),
    force  = factor(force, levels = c("WWI", "SAC", "CMP", "AOF", "WWII"))
  )

# Table 1 shares sum to 100 within every cohort with no "missing" category, so the
# colonial and WWI records must be complete on region, occupation and town size
# (decisions.md D3). WWII records carry none of these covariates in the allow-listed files.
sample <- sample %>%
  filter(force == "WWII" | (!is.na(region) & !is.na(occ) & !is.na(town))) %>%
  step("complete on region, occupation, town (colonial + WWI)")

write_csv(flow, file.path(out_dir, "sample_flow.csv"))
write_csv(sample %>% count(force, cohort), file.path(out_dir, "n_force_cohort.csv"))
saveRDS(sample, file.path(scr, "analysis_sample.rds"))
cat("Final sample:", nrow(sample), "\n"); print(flow)
cat("Raw rows: Data", n_raw_data, " WhitesWW2", n_raw_wwii, "\n")
writeLines(c(paste0("raw_rows_Data,", n_raw_data), paste0("raw_rows_WhitesWW2,", n_raw_wwii),
             paste0("raw_SAC_rows,", sum(raw$Source == "SAC")),
             paste0("raw_WWI_rows,", sum(raw$Source == "WWI"))),
           file.path(out_dir, "raw_counts.csv"))
