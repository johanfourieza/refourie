# P12_FJ S6 00_common.R -- shared build and estimation functions (method card v3, frozen d240e89).
# build() copies repro_r/01_clean.R logic and adds the card's rules O and D (§4A) as switches; rows stay on D:.
suppressMessages({library(readxl); library(dplyr); library(stringr); library(data.table); library(fixest)})
source(here::here("tools", "paths.R"))
SCOPE <- "11 of 15 districts; outcome = a doctor named on the death certificate, among decedents; not the 15-district estimand, not population access to healthcare, not mortality"
ages <- c("Age_0_4","Age_5_9","Age_10_14","Age_15_19","Age_20_24","Age_35_49","Age_50_69","Age_70")
occs <- c("Professionals_and_managers","Sales_and_service","Production","Children_and_Pensioners")
X2 <- c(ages, "Male", occs, "Signature")
X3 <- c(X2, "Africa","Asia","Europe","South_Africa","Death_in_Family","Nurse","Railway","Farm","Street_road_and_stad")
TARGETS <- c("Coloured_x_Pandemic","Black_x_Pandemic","Pandemic_x_Street_road_and_stad","Street_road_and_stad")

read_raw <- function() {
  od <- dpath("P12_FJ", "original")
  f1 <- list.files(od, "^New 10 towns 1915-1920\\.xlsx$", recursive = TRUE, full.names = TRUE)[1]
  f2 <- list.files(od, "^2020-05 JB Sea Point 1915-1920\\.xlsx$", recursive = TRUE, full.names = TRUE)[1]
  a <- read_excel(f1, col_types = "text"); b <- read_excel(f2, col_types = "text"); b$Town[is.na(b$Town) | b$Town == "."] <- "Sea Point"
  bind_rows(a, b)
}

# ruleO, ruleD: card corrections. dwin: lower day bound of the death-in-family window (1 = card, 0 = sens 3).
# drecorded: sens 4 (rule D only on certificates with a recorded day). docinit: sens 17 (initials-only doctor -> NA).
build <- function(raw, ruleO = TRUE, ruleD = TRUE, dwin = 1, drecorded = FALSE, docinit = FALSE, pan_end = "1919-01-31") {
  d <- raw %>% transmute(
    town = str_trim(Town), surname = Surname, sex = Sex, resid = `Usual Place Of Residence`,
    age_raw = Age, race_raw = Race, birth = Birthplace, occ = Occupation,
    day = as.integer(str_extract(`Day of death`, "\\d+")),
    month_raw = `Month of death`, year = as.integer(str_extract(`Year of death`, "\\d{4}")),
    mmn = `Medical man's name`, sign_raw = `Signed, yes or no?`)
  mn <- c(january=1,february=2,march=3,april=4,may=5,june=6,july=7,august=8,september=9,october=10,november=11,december=12)
  m <- tolower(str_trim(d$month_raw))
  d$month <- ifelse(m %in% names(mn), mn[m], suppressWarnings(as.integer(str_extract(m, "^\\d+$"))))
  d <- d %>% filter(year %in% 1915:1920, month %in% 1:12)
  d$date <- as.Date(sprintf("%d-%02d-%02d", d$year, d$month, pmin(pmax(ifelse(is.na(d$day), 15L, d$day), 1L), 28L)))
  d$pandemic <- as.integer(d$date >= as.Date("1918-10-01") & d$date <= as.Date(pan_end))
  rl <- tolower(str_trim(d$race_raw))
  d$race <- case_when(
    str_detect(rl, "europ|hebrew|jew|irish|english|white|dutch|scot") ~ "White",
    str_detect(rl, "mixed|hotto|hotte|colou|gemeng|malay|bushm|griqua|baster") ~ "Coloured",
    str_detect(rl, "kaffir|kafir|fingo|vingo|vengo|xosa|xhosa|bechu|becoa|tembu|morolo|mocwana|mochuana|native|basuto|baralong|barolong|damara|zulu|pondo|bantu|bacoana|mfengu|sotho|tswana|batlaro|bantoe|african|black|batlhaping|korana") ~ "Black",
    TRUE ~ NA_character_)
  mm <- tolower(str_squish(str_replace_all(coalesce(d$mmn, ""), "[[:punct:]]", " ")))
  d$doc <- as.integer(!(mm %in% c("", "none", "nil", "blank", "no doctor", "no", "nobody", "unknown", "not given", "not stated", "na", "n a", "no medical attendant", "no medical man", "not attended", "no medical attendance", "not known")))
  d$doc_initials <- as.integer(str_detect(mm, "^([a-z] )*[a-z]$"))
  if (docinit) d$doc[d$doc_initials == 1] <- NA
  sl <- tolower(coalesce(d$sign_raw, ""))
  d$signature <- ifelse(str_detect(sl, "mark|merk|maark|makr|mekr|^no"), 0L, ifelse(str_detect(sl, "^\\W*yes"), 1L, NA_integer_))
  al <- tolower(coalesce(d$age_raw, "")); num <- as.numeric(str_extract(al, "\\d+(\\.\\d+)?"))
  d$age <- ifelse(str_detect(al, "month|week|day|hour|min|mnd|dag|weke"), 0, num)
  sx <- tolower(coalesce(d$sex, ""))
  d$male <- ifelse(str_detect(sx, "^\\W*(male|mann|manl)"), 1L, ifelse(str_detect(sx, "^\\W*(female|vrou|jong meid)"), 0L, NA_integer_))
  ag <- cut(d$age, c(-Inf, 4, 9, 14, 19, 24, 34, 49, 69, Inf), labels = c("Age_0_4","Age_5_9","Age_10_14","Age_15_19","Age_20_24","Age_25_34","Age_35_49","Age_50_69","Age_70"))
  for (l in levels(ag)[-6]) d[[l]] <- as.integer(ag == l)
  o <- tolower(str_squish(coalesce(d$occ, ""))); noocc <- o %in% c("", "none", "nil", ".", "-", "[blank]")
  farmer <- str_detect(o, "\\bfarmers?\\b|farm ?owner|\\bboer\\b|landowner|grazier") & !str_detect(o, "labour|worker|hand|servant|boy|bywoner|wife|daughter|son\\b")
  farmlab <- str_detect(o, "farm") & str_detect(o, "labour|worker|hand|servant|boy|bywoner")
  if (!ruleO) { farmer[] <- FALSE; farmlab[] <- FALSE }
  d$occgrp <- case_when(
    farmer ~ "Professionals_and_managers",                       # rule O (card §4A), placed before the rebuild's rules
    farmlab ~ "Farming",
    str_detect(o, "scholar|school|pension|retired|child|infant|minor") ~ "Children_and_Pensioners",
    noocc & !is.na(d$age) & (d$age < 15 | d$age >= 65) ~ "Children_and_Pensioners",
    str_detect(o, "farm|shepherd|herd|plough|agric|peasant|gardener|ostrich|stock") ~ "Farming",
    str_detect(o, "doctor|teacher|clergy|minister|priest|attorney|lawyer|clerk|manager|magistrate|accountant|nurse|engineer|merchant|chemist|surveyor|bank|official|director|principal|missionary|evangelist|dentist|secretary") ~ "Professionals_and_managers",
    str_detect(o, "shop|store|trader|hawker|dealer|salesm|hotel|waiter|servant|domestic|cook|housewife|housekeep|police|soldier|launder|washer|barman|messenger|wife|maid|canteen|licen|innkeeper|butler|constable") ~ "Sales_and_service",
    str_detect(o, "labour|mason|carpent|smith|miner|mine|driver|rail|plate|paint|tailor|shoemak|bricklay|wagon|brick|baker|butcher|fitter|machin|factory|worker|weaver|cooper|print|stone|saddler|wheelwright|fireman|stoker|porter|work|dressmak|seamstress|mechanic|contractor|plumber|leather|tanner|sawyer|boilermaker|bootmaker|joiner|builder|cart|ganger|signalman|shunter|guard") ~ "Production",
    TRUE ~ NA_character_)
  d$ruleO_moved <- as.integer(farmer)
  for (l in occs) d[[l]] <- ifelse(is.na(d$occgrp), NA_integer_, as.integer(d$occgrp == l))
  d$Nurse <- as.integer(str_detect(o, "nurse") & !str_detect(o, "wet nurse"))
  d$Railway <- as.integer(str_detect(o, "railway|plate ?layer|locomotive|engine ?driver|shunter|ganger|signalman"))
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
  d$sn <- str_replace_all(tolower(coalesce(d$surname, "")), "[^a-z]", ""); d$id <- seq_len(nrow(d))
  if (!ruleD) {   # rebuild rule, verbatim (S3)
    dt <- as.data.table(d[, c("id","town","sn","date")])[sn != ""]; setorder(dt, town, sn, date)
    dt[, lagd := shift(date), by = .(town, sn)]
    dt[, Death_in_Family := as.integer(!is.na(lagd) & as.numeric(date - lagd) <= 7)]
    d <- left_join(d, as.data.frame(dt[, .(id, Death_in_Family)]), by = "id"); d$Death_in_Family[is.na(d$Death_in_Family)] <- 0L
  } else {        # rule D: recorded day (clamped to month length), missing day = 15, any other certificate 1(dwin)-7 days earlier
    dd <- ifelse(is.na(d$day), 15L, pmax(d$day, 1L)); first <- as.Date(sprintf("%d-%02d-01", d$year, d$month))
    nxt <- as.Date(sprintf("%d-%02d-01", ifelse(d$month == 12, d$year + 1L, d$year), ifelse(d$month == 12, 1L, d$month + 1L)))
    mlen <- as.integer(nxt - first)
    d$dateD <- first + pmin(dd, mlen) - 1L
    pool <- d$sn != "" & (!drecorded | !is.na(d$day))
    dt <- as.data.table(d[pool, c("id","town","sn","dateD")])
    pr <- merge(dt, dt, by = c("town","sn"), allow.cartesian = TRUE, suffixes = c("", ".o"))[id != id.o]
    pr[, gap := as.numeric(dateD - dateD.o)]
    hit <- unique(pr[gap >= dwin & gap <= 7, id])
    d$Death_in_Family <- as.integer(d$id %in% hit)
    if (drecorded) d$Death_in_Family[is.na(d$day)] <- NA_integer_
  }
  d$Coloured <- as.integer(d$race == "Coloured"); d$Black <- as.integer(d$race == "Black")
  d$Male <- d$male; d$Signature <- d$signature; d$Pandemic <- d$pandemic
  d %>% select(-surname, -sn, -resid, -birth, -occ, -mmn, -sex, -sign_raw, -age_raw, -race_raw, -month_raw)
}

# interactions recomputed from current race / Pandemic (used for counterfactuals as well)
add_int <- function(d, xs = X3) {
  d$Coloured_x_Pandemic <- d$Coloured * d$Pandemic; d$Black_x_Pandemic <- d$Black * d$Pandemic
  for (v in xs) d[[paste0("Pandemic_x_", v)]] <- d$Pandemic * d[[v]]
  d
}
fml <- function(xs, fe = "factor(town)", drop = character(0), pan = TRUE) {
  xs <- setdiff(xs, drop)
  rhs <- c("Coloured","Black", if (pan) "Pandemic", "Coloured_x_Pandemic","Black_x_Pandemic", xs, paste0("Pandemic_x_", xs))
  as.formula(paste("doc ~", paste(rhs, collapse = " + "), "+", fe))
}
fit1 <- function(f, data, lpm = FALSE) {
  if (lpm) return(feols(f, data, nthreads = 1))
  feglm(f, data, family = "binomial", glm.tol = 1e-08, glm.iter = 25, fixef.tol = 1e-06, fixef.iter = 10000, collin.tol = 1e-09, nthreads = 1, notes = FALSE, warn = FALSE)
}
# failure diagnostics per target (card §4D)
fail_check <- function(fit, data, targets = TARGETS) {
  cf <- coef(fit); se <- tryCatch(se(fit, vcov = "iid"), error = function(e) cf * NA)
  conv <- isTRUE(fit$convStatus) || is.null(fit$convStatus)
  removed <- nobs(fit) != nrow(data)
  p <- fitted(fit)
  sapply(targets, function(t) {
    if (!(t %in% names(cf)) || !is.finite(cf[t]) || !is.finite(se[t])) return(TRUE)
    rel <- data[[t]] != 0
    ext <- any(p[rel] < 1e-10 | p[rel] > 1 - 1e-10)
    !conv || removed || ext
  })
}
# CV3 jackknife: theta full, loo matrix (G x k)
cv3 <- function(theta, loo, m, centre = c("full","mean")) {
  centre <- match.arg(centre); G <- nrow(loo)
  cc <- if (centre == "full") theta else colMeans(loo)
  V <- (G - 1) / G * colSums(sweep(loo, 2, cc)^2); se <- sqrt(V)
  t <- theta / se; p <- 2 * pt(-abs(t), G - 1); q <- qt(1 - 0.05 / (2 * m), G - 1)
  data.frame(term = names(theta), est = theta, se = se, t = t, p = p, lo = theta - q * se, hi = theta + q * se, G = G, m = m, row.names = NULL)
}
# standardised cross-difference DiD_k (§3), spec 2, in pp
pcf <- function(fit, data, r, q, xs) {
  z <- data; z$Coloured <- as.integer(r == "C"); z$Black <- as.integer(r == "B"); z$Pandemic <- q
  predict(fit, newdata = add_int(z, xs), type = "response")
}
did <- function(fit, data, xs) {
  P <- list(); for (r in c("W","C","B")) for (q in 0:1) P[[paste0(r, q)]] <- pcf(fit, data, r, q, xs)
  ch <- function(r) P[[paste0(r, 1)]] - P[[paste0(r, 0)]]
  100 * c(DiD_C = mean(ch("C") - ch("W")), DiD_B = mean(ch("B") - ch("W")), chg_W = mean(ch("W")), chg_C = mean(ch("C")), chg_B = mean(ch("B")))
}
# full fit + leave-one-district-out for a spec; returns estimates, failure flags, optional DiD
run_spec <- function(data, xs, fe = "factor(town)", pan = TRUE, drop = character(0), want_did = FALSE, lpm = FALSE, extra = list()) {
  xs2 <- setdiff(xs, drop); f <- fml(xs, fe, drop, pan)
  tg <- intersect(TARGETS, c("Coloured_x_Pandemic","Black_x_Pandemic", xs2, paste0("Pandemic_x_", xs2)))
  lc <- function(cf) { out <- cf[tg]; if (all(c("Street_road_and_stad","Pandemic_x_Street_road_and_stad") %in% tg)) out["theta_U"] <- cf["Street_road_and_stad"] + cf["Pandemic_x_Street_road_and_stad"]
    for (nm in names(extra)) out[nm] <- sum(cf[extra[[nm]]]); out }
  fit <- fit1(f, data, lpm); th <- lc(coef(fit)); fl <- if (lpm) setNames(rep(FALSE, length(tg)), tg) else fail_check(fit, data, tg)
  D <- if (want_did && !lpm) did(fit, data, xs2) else NULL
  towns <- sort(unique(data$town)); loo <- matrix(NA, length(towns), length(th), dimnames = list(towns, names(th))); Dl <- NULL; fl_l <- fl * 0
  for (g in towns) { dg <- data[data$town != g, ]; fg <- tryCatch(fit1(f, dg, lpm), error = function(e) NULL)
    if (is.null(fg)) { fl_l[] <- 1; next }
    loo[g, ] <- lc(coef(fg))[names(th)]
    if (!lpm) fl_l <- fl_l + fail_check(fg, dg, tg)
    if (!is.null(D)) Dl <- rbind(Dl, did(fg, dg, xs2)) }
  list(fit = fit, theta = th, loo = loo, fail_full = fl, fail_loo = fl_l, did = D, did_loo = Dl, n = nobs(fit), G = length(towns), towns = towns)
}
