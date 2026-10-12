# P12 S3 independent recreation: build the analysis file from raw transcriptions (10 towns + Sea Point).
# Individual rows stay on D: scratch; nothing row-level is written to the project.
suppressMessages({library(readxl); library(dplyr); library(stringr); library(data.table)})
source("tools/paths.R")
set.seed(12)
od <- dpath("P12_FJ", "original")
f1 <- list.files(od, "^New 10 towns 1915-1920\\.xlsx$", recursive = TRUE, full.names = TRUE)[1]
f2 <- list.files(od, "^2020-05 JB Sea Point 1915-1920\\.xlsx$", recursive = TRUE, full.names = TRUE)[1]
a <- read_excel(f1, col_types = "text")
b <- read_excel(f2, col_types = "text"); b$Town[is.na(b$Town) | b$Town == "."] <- "Sea Point"
d <- bind_rows(a, b) %>% transmute(
  town = str_trim(Town), surname = Surname, sex = Sex, resid = `Usual Place Of Residence`,
  age_raw = Age, race_raw = Race, birth = Birthplace, occ = Occupation,
  day = as.integer(str_extract(`Day of death`, "\\d+")),
  month_raw = `Month of death`, year = as.integer(str_extract(`Year of death`, "\\d{4}")),
  cod = `Causes of death`, dur = `Duration of last illness`, mmn = `Medical man's name`, sign_raw = `Signed, yes or no?`)
mn <- c(january=1,february=2,march=3,april=4,may=5,june=6,july=7,august=8,september=9,october=10,november=11,december=12)
m <- tolower(str_trim(d$month_raw))
d$month <- ifelse(m %in% names(mn), mn[m], suppressWarnings(as.integer(str_extract(m, "^\\d+$"))))
d <- d %>% filter(year %in% 1915:1920, month %in% 1:12)
d$date <- as.Date(sprintf("%d-%02d-%02d", d$year, d$month, pmin(pmax(ifelse(is.na(d$day), 15L, d$day), 1L), 28L)))
d$pandemic <- as.integer(d$date >= as.Date("1918-10-01") & d$date <= as.Date("1919-01-31"))
# race (white / coloured / black); Indian and unclassified -> NA
rl <- tolower(str_trim(d$race_raw))
d$race <- case_when(
  str_detect(rl, "europ|hebrew|jew|irish|english|white|dutch|scot") ~ "White",
  str_detect(rl, "mixed|hotto|hotte|colou|gemeng|malay|bushm|griqua|baster") ~ "Coloured",
  str_detect(rl, "kaffir|kafir|fingo|vingo|vengo|xosa|xhosa|bechu|becoa|tembu|morolo|mocwana|mochuana|native|basuto|baralong|barolong|damara|zulu|pondo|bantu|bacoana|mfengu|sotho|tswana|batlaro|bantoe|african|black|batlhaping|korana") ~ "Black",
  TRUE ~ NA_character_)
# doctor named
mm <- tolower(str_squish(str_replace_all(coalesce(d$mmn, ""), "[[:punct:]]", " ")))
d$doc <- as.integer(!(mm %in% c("", "none", "nil", "blank", "no doctor", "no", "nobody", "unknown", "not given", "not stated", "na", "n a", "no medical attendant", "no medical man", "not attended", "no medical attendance", "not known")))
# signature
sl <- tolower(coalesce(d$sign_raw, ""))
d$signature <- ifelse(str_detect(sl, "mark|merk|maark|makr|mekr|^no"), 0L, ifelse(str_detect(sl, "^\\W*yes"), 1L, NA_integer_))
# age in years
al <- tolower(coalesce(d$age_raw, "")); num <- as.numeric(str_extract(al, "\\d+(\\.\\d+)?"))
d$age <- ifelse(str_detect(al, "month|week|day|hour|min|mnd|dag|weke"), 0, num)
sx <- tolower(coalesce(d$sex, ""))
d$male <- ifelse(str_detect(sx, "^\\W*(male|mann|manl)"), 1L, ifelse(str_detect(sx, "^\\W*(female|vrou|jong meid)"), 0L, NA_integer_))
ag <- cut(d$age, c(-Inf, 4, 9, 14, 19, 24, 34, 49, 69, Inf), labels = c("Age_0_4","Age_5_9","Age_10_14","Age_15_19","Age_20_24","Age_25_34","Age_35_49","Age_50_69","Age_70"))
for (l in levels(ag)[-6]) d[[l]] <- as.integer(ag == l)
# occupation groups (own keyword classification; farming is the reference)
o <- tolower(str_squish(coalesce(d$occ, ""))); noocc <- o %in% c("", "none", "nil", ".", "-", "[blank]")
d$occgrp <- case_when(
  str_detect(o, "scholar|school|pension|retired|child|infant|minor") ~ "Children_and_Pensioners",
  noocc & !is.na(d$age) & (d$age < 15 | d$age >= 65) ~ "Children_and_Pensioners",
  str_detect(o, "farm|shepherd|herd|plough|agric|peasant|gardener|ostrich|stock") ~ "Farming",
  str_detect(o, "doctor|teacher|clergy|minister|priest|attorney|lawyer|clerk|manager|magistrate|accountant|nurse|engineer|merchant|chemist|surveyor|bank|official|director|principal|missionary|evangelist|dentist|secretary") ~ "Professionals_and_managers",
  str_detect(o, "shop|store|trader|hawker|dealer|salesm|hotel|waiter|servant|domestic|cook|housewife|housekeep|police|soldier|launder|washer|barman|messenger|wife|maid|canteen|licen|innkeeper|butler|constable") ~ "Sales_and_service",
  str_detect(o, "labour|mason|carpent|smith|miner|mine|driver|rail|plate|paint|tailor|shoemak|bricklay|wagon|brick|baker|butcher|fitter|machin|factory|worker|weaver|cooper|print|stone|saddler|wheelwright|fireman|stoker|porter|work|dressmak|seamstress|mechanic|contractor|plumber|leather|tanner|sawyer|boilermaker|bootmaker|joiner|builder|cart|ganger|signalman|shunter|guard") ~ "Production",
  TRUE ~ NA_character_)
for (l in c("Professionals_and_managers","Sales_and_service","Production","Children_and_Pensioners")) d[[l]] <- ifelse(is.na(d$occgrp), NA_integer_, as.integer(d$occgrp == l))
d$Nurse <- as.integer(str_detect(o, "nurse") & !str_detect(o, "wet nurse"))
d$Railway <- as.integer(str_detect(o, "railway|plate ?layer|locomotive|engine ?driver|shunter|ganger|signalman"))
# birthplace
bl <- tolower(str_squish(coalesce(d$birth, ""))); bunk <- bl %in% c("", ".", "-", "none", "nil", "unknown", "[blank]") | str_detect(bl, "not included|not given|unknown")
d$bgrp <- case_when(
  bunk ~ NA_character_,
  str_detect(bl, "england|scotland|ireland|wales|holland|netherland|german|norway|sweden|denmark|russia|poland|lithuan|latvia|ital|france|greece|portug|spain|switzerl|belgi|europe|austria|finland|britain|london|united kingdom|glasgow|edinburgh|liverpool|cornwall|yorkshire") ~ "Europe",
  str_detect(bl, "india|ceylon|china|japan|asia|arab|syria|java|persia|turkey|palestine") ~ "Asia",
  str_detect(bl, "rhodesia|mozambique|basuto|swazi|nyasa|angola|portuguese east|east africa|congo|protectorate|mauritius|helena|zambesi") ~ "Africa",
  str_detect(bl, "transvaal|orange free|natal|zulu|free state|johannesburg|pretoria|south africa|union") & !str_detect(bl, "cape") ~ "South_Africa",
  TRUE ~ "Cape")
for (l in c("Africa","Asia","Europe","South_Africa")) d[[l]] <- ifelse(is.na(d$bgrp), NA_integer_, as.integer(d$bgrp == l))
rs <- tolower(coalesce(d$resid, ""))
d$Street_road_and_stad <- as.integer(str_detect(rs, "street|road|stad|straat|avenue|laan|\\bst\\b|\\brd\\b|lane"))
d$Farm <- as.integer(str_detect(rs, "farm|plaas"))
# death in family: another certificate with the same surname and town dated 0-7 days earlier
d$sn <- str_replace_all(tolower(coalesce(d$surname, "")), "[^a-z]", ""); d$id <- seq_len(nrow(d))
dt <- as.data.table(d[, c("id","town","sn","date")])[sn != ""]; setorder(dt, town, sn, date)
dt[, lagd := shift(date), by = .(town, sn)]
dt[, Death_in_Family := as.integer(!is.na(lagd) & as.numeric(date - lagd) <= 7)]
d <- left_join(d, as.data.frame(dt[, .(id, Death_in_Family)]), by = "id"); d$Death_in_Family[is.na(d$Death_in_Family)] <- 0L
# influenza classification (text based, footnote 4)
d$flu <- as.integer(str_detect(tolower(coalesce(d$cod, "")), "influenz|influens|spanish|grippe|\\bflu\\b"))
# duration of last illness: number as written
d$dur_num <- as.numeric(str_extract(tolower(coalesce(d$dur, "")), "\\d+"))
d$mmn_l <- mm
d <- d %>% select(-surname, -sn, -resid, -birth, -occ, -cod, -mmn, -sex, -sign_raw, -age_raw, -race_raw, -day, -month_raw, -dur)
dir.create(dpath("P12_FJ", "repro_r", "_scratch"), recursive = TRUE, showWarnings = FALSE)
saveRDS(d, dpath("P12_FJ", "repro_r", "_scratch", "analysis.rds"))
# aggregate diagnostics only (no rows)
diag <- list(n_total = nrow(d), n_by_town = table(d$town), race = table(d$race, useNA = "ifany"), occ = table(d$occgrp, useNA = "ifany"),
             birth = table(d$bgrp, useNA = "ifany"), doc_share = mean(d$doc), sig = table(d$signature, useNA = "ifany"), pandemic = table(d$pandemic),
             complete_c3 = sum(complete.cases(d[, c("doc","race","age","male","occgrp","signature","bgrp")])))
sink("P12_FJ/repro_r/output/clean_diagnostics.txt"); print(diag); sink()
