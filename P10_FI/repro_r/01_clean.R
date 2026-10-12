# P10_FI  S3 independent recreation  --  01_clean.R
# Fourie & Inwood (2019) "Interracial marriages in twentieth-century Cape Town"
# Builds the marriage-level analysis file from the raw transcription
# (`CT 1 March 2019.xlsx`, sheet 'Cape Town') and the census inputs
# (`Cape Town sex ratio.xlsx`). Written from the paper's description only;
# no original code was seen. See decisions.md for every choice.
#
# Rights class: personal. Names and other identifying fields are dropped on
# read; the cleaned microdata are written only to the D: scratch folder.
# Outputs under repro_r/output/ are aggregates and coding dictionaries only.

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(tidyxl)
  library(here)
})
set.seed(20191001)

proj <- here::here()
source(file.path(proj, "tools", "paths.R"))
pdir <- file.path(proj, "P10_FI", "repro_r")
odir <- file.path(pdir, "output"); dir.create(odir, showWarnings = FALSE, recursive = TRUE)
raw_dir <- dpath("P10_FI", "original", "R_CapeTownAnglican", "Data")
f_raw <- file.path(raw_dir, "CT 1 March 2019.xlsx")
f_sex <- file.path(raw_dir, "Cape Town sex ratio.xlsx")
scratch <- function(...) dscratch("P10_FI", "repro_r", ...)

# ---------------------------------------------------------------------------
# 1. Read raw transcription; keep only non-identifying fields
# ---------------------------------------------------------------------------
raw <- read_excel(f_raw, sheet = "Cape Town", guess_max = 60000)
d <- raw %>%
  transmute(
    rec       = row_number(),
    parish    = ParishID,
    year      = `Date year`,
    month_raw = `Date month`,
    m_age_raw = `Male age`,   f_age_raw = `Female age`,
    m_cty     = `Male country`, f_cty = `Female country`,
    m_race_raw = `Male race`, f_race_raw = `Female race`,
    m_cond    = `Male condition`, f_cond = `Female condition`,
    m_occ_raw = `Male rank or profession`, f_occ_raw = `Female rank or profession`,
    m_sign    = `Male signed`, f_sign = `Female Signed`,
    race_change = `Race change`
  )
rm(raw)
n_transcribed <- nrow(d)

# ---------------------------------------------------------------------------
# 2. Race: raw strings -> white / coloured / black   (paper note 17)
#    Asian groups (Indian, Chinese, Asiatic, Malay, Mauritian) -> coloured,
#    following the three-way Population Registration Act (1950) scheme in
#    which they were sub-groups of 'Coloured'. 'Non-European' (unspecified)
#    -> coloured (modal non-European group in Anglican Cape Town).
# ---------------------------------------------------------------------------
race_dict <- tribble(
  ~raw, ~race,
  "European", "white", "White", "white", "E", "white", "English", "white",
  "British", "white", "Dutch", "white", "Africander", "white", "Canadian", "white",
  "Greek", "white", "Jewish", "white", "Norwegian", "white", "Scotch", "white",
  "German", "white", "Polish Jew", "white",
  "Coloured", "coloured", "Mixed", "coloured", "C", "coloured", "c", "coloured",
  "Cape Coloured", "coloured", "Cape Coloure", "coloured", "CC", "coloured",
  "M", "coloured", "Cape Malay", "coloured", "St. Helena", "coloured",
  "St Helena", "coloured", "St. Helenian", "coloured", "Non-European (C)", "coloured",
  "Slightly Coloured", "coloured", "Non-European", "coloured", "Indian", "coloured",
  "Chinese", "coloured", "Asiatic", "coloured", "Mauritian", "coloured",
  "Indo-European", "coloured", "Egyptian", "coloured", "West Indian", "coloured",
  "Native", "black", "Natvie", "black", "Native(Fingo)", "black", "Native(Pondo)", "black",
  "Native(Xhosa)", "black", "Xhosa", "black", "Fingo", "black", "Bantu", "black",
  "Bantu (Fingo)", "black", "Basuto", "black", "Sotho", "black", "Sutu", "black",
  "Zulu", "black", "Tembu", "black", "African", "black", "Amatonga", "black",
  "Mozambique", "black", "K", "black", "Krooman", "black", "Kruman", "black",
  "West Africa", "black", "Sudanese", "black", "American Negro", "black",
  "Hanga", "black", "Aboriginal", "black"
)
stopifnot(!anyDuplicated(race_dict$raw))
code_race <- function(x) race_dict$race[match(str_trim(x), race_dict$raw)]
d <- d %>% mutate(m_race = code_race(m_race_raw), f_race = code_race(f_race_raw))

race_audit <- bind_rows(
  d %>% count(raw = m_race_raw, race = m_race) %>% mutate(spouse = "male"),
  d %>% count(raw = f_race_raw, race = f_race) %>% mutate(spouse = "female")
) %>% arrange(spouse, race, desc(n))
write_csv(race_audit, file.path(odir, "dict_race.csv"))

# ---------------------------------------------------------------------------
# 3. Other variables
# ---------------------------------------------------------------------------
num_age <- function(x) { a <- suppressWarnings(as.numeric(str_trim(x))); ifelse(a >= 10 & a <= 100, a, NA_real_) }
month_map <- c(January = 1, February = 2, March = 3, April = 4, May = 5, Mei = 5, June = 6,
               Junie = 6, Jume = 6, July = 7, August = 8, September = 9, October = 10,
               November = 11, December = 12)
sign01 <- function(x) case_when(str_trim(x) == "Yes" ~ 1, str_trim(x) == "No" ~ 0, TRUE ~ NA_real_)
sa_names <- c("South Africa", "south Africa", "South Arica", "South Arica C", "Sputh Africa",
              "Transkei", "Transkei, S.A.", "Pondoland", "Zululand", "Amatongaland", "Plumstead")
foreign01 <- function(x) {
  x <- str_trim(x)
  case_when(is.na(x) | x %in% c(".", "?", "????", "") ~ NA_real_,
            x %in% sa_names ~ 0, TRUE ~ 1)
}
cond_m <- function(x) {
  x <- str_trim(x)
  tibble(widower  = case_when(x == "Bachelor" ~ 0, str_detect(x, "Widower") ~ 1,
                              str_detect(x, "^Divorc") ~ 0, TRUE ~ NA_real_),
         divorcee = case_when(x == "Bachelor" ~ 0, str_detect(x, "Divorc") ~ 1,
                              x == "Widower" ~ 0, TRUE ~ NA_real_))
}
cond_f <- function(x) {
  x <- str_trim(x)
  tibble(widow    = case_when(x == "Spinster" ~ 0, x == "Widow" ~ 1,
                              str_detect(x, "^Divorc") ~ 0, TRUE ~ NA_real_),
         divorcee = case_when(x == "Spinster" ~ 0, str_detect(x, "^Divorc") ~ 1,
                              x == "Widow" ~ 0, TRUE ~ NA_real_))
}
cm <- cond_m(d$m_cond); cf <- cond_f(d$f_cond)

d <- d %>% mutate(
  month   = unname(month_map[str_trim(month_raw)]),
  m_age   = num_age(m_age_raw), f_age = num_age(f_age_raw),
  m_lit   = sign01(m_sign), f_lit = sign01(f_sign),
  lit_gap = abs(m_lit - f_lit),          # 1 if exactly one spouse could not sign
  lit_diff = m_lit - f_lit,              # signed difference (Table 2 column)
  m_foreign = foreign01(m_cty), f_foreign = foreign01(f_cty),
  widower = cm$widower, m_divorcee = cm$divorcee,
  widow = cf$widow, f_divorcee = cf$divorcee,
  act = as.numeric(year >= 1949),
  reclass = as.numeric(!is.na(race_change) & !str_trim(race_change) %in% c(".", ",", ""))
)

# ---------------------------------------------------------------------------
# 4. Occupations -> HISCO major-group classes (own dictionary; first match wins)
#    class: "prof" (HISCO 0-3: professional, technical, administrative,
#    managerial, clerical), "sales" (HISCO 4-5: sales and service),
#    "prod" (HISCO 6-9: agriculture, production, transport, labourers).
#    Non-occupations (household duties, none, student, retired, ...) -> NA.
# ---------------------------------------------------------------------------
occ_rules <- tribble(
  ~pattern, ~class, ~hisco_major,
  # --- non-occupations first
  "^\\.$|^-+$|^none|^nil$|no occupation|^unemployed|^out of work|not stated|^n/?a$|^\\?", NA, NA,
  "household|house ?hold|home ?duties|house ?duties|housewife|house-wife|at home|domestic duties|home$|housework|^spinster|^widow|^married|^wife|^daughter", NA, NA,
  "student(?! nurse)|scholar|school ?girl|school ?boy|^pupil|apprentice teacher", NA, NA,
  "retired|pensioner|annuitant|independent|gentleman|gentlewoman|private means|of means|^lady$|invalid|minor$|^full$", NA, NA,
  # --- early overrides
  "domestic science|science teacher|schoolmaster|schoolmistress|student nurse|probationer nurse", "prof", "1",
  "cleaner|w\\.a\\.a\\.s|\\bwaas\\b", "sales", "5",
  "merchant seaman|merchant navy", "prod", "9",
  "agent|broker|auctioneer|valuer|florist", "sales", "4",
  "nursemaid|nurse ?girl|nurse aid|nursing aid|children'?s nurse", "sales", "5",
  "market gardener|fruit grower|farm|agricult|gardener|dairy farmer|shepherd|herdsman|fisher|forester|woodcutter|poultry|horticult|vine dresser|vineyard", "prod", "6",
  # --- clerical / administrative / professional (0-3)
  "manager|manageress|director|proprietor|company secretary|administrator|superintendent|inspector|supervisor|overseer|foreman|forewoman|forelady|headmaster|principal|master mariner|official|commissioner|magistrate|mayor|councillor|executive|organiser|organizer|controller|chief ", "prof", "2",
  "clerk|typist|typiste|stenograph|secretary|bookkeeper|book-keeper|book keeper|cashier|teller|accounts?|accountant|audit|telephonist|telegraph|(telephone|switchboard|wireless|radio|teleprinter|comptometer|punch card|accounting machine|calculating machine) ?operator|receptionist|comptometer|office|stores? ?keeper|storeman|civil servant|post ?office|postal|postmaster|messenger|post ?man|postman|computor|computer|filing|ledger|tracer|librarian|records", "prof", "3",
  "teacher|lecturer|professor|tutor|governess|nurse|nursing|sister|matron|midwife|doctor|physician|surgeon|medical|dentist|dental|chemist|pharmac|engineer|architect|surveyor|draughts|draftsman|chartered|attorney|advocate|lawyer|solicitor|barrister|clergy|clergyman|minister|priest|reverend|rev\\.|pastor|missionary|evangelist|curate|vicar|rector|deacon|catechist|journalist|reporter|editor|author|artist|musician|organist|\\bactor\\b|actress|photographer|scientist|analyst|physiotherap|radiograph|dietitian|optician|optometr|veterinar|technician|laboratory|lab\\. |designer|commercial artist|social worker|welfare|interpreter|translator|pilot|navigator|officer|lieutenant|captain|major|colonel|bank|insurance|consultant|statistician|economist|quantity|draughtsman|announcer|probation", "prof", "0/1",
  # --- sales (4)
  "sales|\\bshop|\\bstore|merchant|dealer|trader|hawker|vendor|seller|commercial traveller|traveller|representative|canvasser|buyer|grocer|greengrocer|fruiterer|tobacconist|draper|stationer|newsagent|market|pedlar|peddler|hawk|business|retailer|wholesaler|counter hand|counterhand|cashier", "sales", "4",
  # --- service (5)
  "domestic|servant|maid|charwoman|char-woman|cook|chef|waiter|waitress|steward|stewardess|barman|barmaid|bar ?tender|hotel|boarding|housekeeper|house keeper|caretaker|cleaner|launder|laundress|washer|washing|ironer|hairdress|barber|beauty|valet|porter|attendant|nursemaid|nanny|child|baby|companion|usherette|usher|police|constable|detective|warder|gaoler|guard|watchman|night watch|fireman$|fire brigade|soldier|sergeant|corporal|private|sapper|gunner|trooper|army|military|active service|navy|naval|air force|s\\.a\\.a\\.f|^rating|marine$|lance corporal|bombardier|airman|signalman|sexton|verger|undertaker|hall keeper|lift|hostess|kitchen|pantry|dairy maid|nurse aid|ward maid|wardmaid|home help|help$|lady help|mother'?s help|janitor|doorman|commissionaire", "sales", "5",
  # --- production, transport, labourers (7-9)
  ".", "prod", "7-9"
)
occ_rules <- occ_rules %>% mutate(rule = row_number())

code_occ <- function(x) {
  xs <- str_to_lower(str_squish(coalesce(x, ".")))
  out_rule <- rep(NA_integer_, length(xs))
  for (r in seq_len(nrow(occ_rules))) {
    hit <- is.na(out_rule) & str_detect(xs, regex(occ_rules$pattern[r]))
    out_rule[hit] <- r
  }
  out_rule
}
d <- d %>% mutate(m_occ_rule = code_occ(m_occ_raw), f_occ_rule = code_occ(f_occ_raw),
                  m_occ = occ_rules$class[m_occ_rule], f_occ = occ_rules$class[f_occ_rule])

# Occupation dictionary output: rules + coverage, and string-level mapping for
# strings that occur at least 5 times (no individual rows).
occ_cov <- bind_rows(
  d %>% count(rule = m_occ_rule) %>% mutate(spouse = "male"),
  d %>% count(rule = f_occ_rule) %>% mutate(spouse = "female")) %>%
  left_join(occ_rules, by = "rule")
write_csv(occ_rules, file.path(odir, "dict_occupation_rules.csv"))
write_csv(occ_cov, file.path(odir, "dict_occupation_coverage.csv"))
occ_map <- bind_rows(
  d %>% count(string = m_occ_raw, rule = m_occ_rule) %>% mutate(spouse = "male"),
  d %>% count(string = f_occ_raw, rule = f_occ_rule) %>% mutate(spouse = "female")) %>%
  filter(n >= 5) %>% left_join(occ_rules %>% select(rule, class, hisco_major), by = "rule") %>%
  arrange(spouse, desc(n))
write_csv(occ_map, file.path(odir, "dict_occupation_strings_n5plus.csv"))

# ---------------------------------------------------------------------------
# 5. Sex ratio by race from census benchmarks (constant cells only)
#    Benchmarks = census years where both male and female counts are typed-in
#    constants (not formulas) in sheet 'Calculations'. Ratio = males/females,
#    linearly interpolated between benchmarks; NA outside 1921-1960 (primary).
# ---------------------------------------------------------------------------
cells <- xlsx_cells(f_sex, sheets = "Calculations")
cval <- function(col, row) {
  z <- cells %>% filter(col == !!col, row == !!row)
  if (nrow(z) == 0 || !is.na(z$formula) || is.na(z$numeric)) NA_real_ else z$numeric
}
yrs_row <- cells %>% filter(col == 1, !is.na(numeric)) %>% select(row, year = numeric)
# columns: male, female, total (total typed only for 1960, where female = total - male)
cols <- list(white = c(5, 7, 8), coloured = c(11, 12, 13), black = c(16, 17, 18))
bench <- map_dfr(names(cols), function(r) {
  map_dfr(seq_len(nrow(yrs_row)), function(i)
    tibble(race = r, year = yrs_row$year[i],
           male = cval(cols[[r]][1], yrs_row$row[i]),
           female = cval(cols[[r]][2], yrs_row$row[i]),
           total = cval(cols[[r]][3], yrs_row$row[i])))
}) %>% mutate(female = ifelse(is.na(female) & !is.na(total) & !is.na(male), total - male, female)) %>%
  filter(!is.na(male), !is.na(female)) %>% mutate(ratio = male / female)
write_csv(bench, file.path(odir, "sexratio_census_benchmarks.csv"))
interp <- function(b) {
  yy <- 1911:1964
  tibble(year = yy,
         sexratio = approx(b$year, b$ratio, xout = yy, rule = 1)$y,
         sexratio_cf = ifelse(yy < min(b$year), NA, approx(b$year, b$ratio, xout = yy, rule = 2)$y))
}
sexr <- bench %>% group_by(race) %>% group_modify(~ interp(.x)) %>% ungroup()
write_csv(sexr, file.path(odir, "sexratio_by_race_year.csv"))

# ---------------------------------------------------------------------------
# 6. Segregation: Herfindahl-Hirschman index of racial concentration by
#    parish-year. Shares = shares of the three race groups among all
#    spouses (husbands and wives) with a known race married in parish j in
#    year t. HHI = sum_r s_r^2 (1 if all white). Variant B uses husbands only.
# ---------------------------------------------------------------------------
ind <- bind_rows(d %>% select(parish, year, race = m_race),
                 d %>% select(parish, year, race = f_race)) %>% filter(!is.na(race))
seg <- ind %>% count(parish, year, race) %>% group_by(parish, year) %>%
  summarise(n_ind = sum(n), segregation = sum((n / sum(n))^2), .groups = "drop")
seg_h <- d %>% filter(!is.na(m_race)) %>% count(parish, year, m_race) %>% group_by(parish, year) %>%
  summarise(segregation_h = sum((n / sum(n))^2), .groups = "drop")
d <- d %>% left_join(seg, by = c("parish", "year")) %>% left_join(seg_h, by = c("parish", "year"))

# ---------------------------------------------------------------------------
# 7. Sample flags and final file
# ---------------------------------------------------------------------------
d <- d %>%
  left_join(sexr %>% rename(m_race = race), by = c("m_race", "year")) %>%
  mutate(
    in_period = year >= 1911 & year <= 1964,
    sample = in_period & !is.na(m_race) & !is.na(f_race),
    interracial = as.numeric(m_race != f_race),
    type = ifelse(is.na(interracial), NA, paste0(substr(m_race, 1, 1), substr(f_race, 1, 1))),
    m_white = as.numeric(m_race == "white"), m_black = as.numeric(m_race == "black"),
    f_white = as.numeric(f_race == "white"), f_black = as.numeric(f_race == "black"),
    m_manager = as.numeric(m_occ == "prof"), m_sales = as.numeric(m_occ == "sales"),
    f_manager = as.numeric(f_occ == "prof"), f_sales = as.numeric(f_occ == "sales"),
    # alternative: non-occupations kept in the reference group (when string present)
    f_occ_alt = ifelse(is.na(f_occ) & !str_trim(coalesce(f_occ_raw, ".")) %in% c(".", ""), "prod", f_occ),
    parish = factor(parish), month_f = factor(month)
  )

clean <- d %>% select(-ends_with("_raw"), -m_cty, -f_cty, -m_sign, -f_sign, -race_change,
                      -m_cond, -f_cond)
saveRDS(clean, scratch("p10_clean.rds"))

# small aggregate log
log <- tibble(
  item = c("records_in_file", "records_1911_1964", "sample_both_race", "unique_male_occ_strings_sample",
           "unique_female_occ_strings_sample", "male_occ_coded_share_sample", "female_occ_coded_share_sample",
           "reclassified_records_sample", "reclassified_records_all"),
  value = c(n_transcribed, sum(d$in_period), sum(d$sample),
            n_distinct(d$m_occ_raw[d$sample]), n_distinct(d$f_occ_raw[d$sample]),
            mean(!is.na(d$m_occ[d$sample])), mean(!is.na(d$f_occ[d$sample])),
            sum(d$reclass[d$sample]), sum(d$reclass)))
write_csv(log, file.path(odir, "clean_log.csv"))
print(log, n = Inf)
