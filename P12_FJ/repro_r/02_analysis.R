# P12 S3 independent recreation: tables 1-5 and text numbers. SUBSAMPLE: 11 recovered districts (10 towns + Sea Point);
# Fraserburg, Riversdale, Stellenbosch, Stockenstrom are not recovered.
suppressMessages({library(readxl); library(dplyr); library(stringr); library(fixest); library(readr)})
source("tools/paths.R")
set.seed(12)
outd <- "P12_FJ/repro_r/output"; dir.create(outd, showWarnings = FALSE)
claims <- read_csv("P12_FJ/claims/claims.csv", col_types = cols(.default = "c"))
res <- tibble(claim_id = claims$claim_id, source = "r", value = NA_real_, se = NA_real_, n = NA_real_, status_override = "unavailable")
setv <- function(id, v, se = NA, n = NA) { i <- match(id, res$claim_id); if (is.na(i) || length(v) != 1 || !is.finite(v)) return(invisible()); res$value[i] <<- v; res$se[i] <<- se; res$n[i] <<- n; res$status_override[i] <<- NA_character_ }
save_res <- function() write_csv(res, "P12_FJ/repro_r/results_r.csv", na = "")
save_res()   # complete placeholder file first
d <- readRDS(dpath("P12_FJ", "repro_r", "_scratch", "analysis.rds"))
d$Pandemic <- d$pandemic
d$pre <- d$date <= as.Date("1918-09-30")

# ---------------- Table 1 (subsample) ----------------
t1d <- c("Cradock","Elliot","Fraserburg","Komga","Kuruman","Mafeking","Oudtshoorn","Paarl","Peddie","Queenstown","Riversdale","Stellenbosch","Stockenstrom","Vryburg")
ph <- suppressMessages(read_excel(list.files(dpath("P12_FJ", "original"), "^Phillips Table 13_all\\.xlsx$", recursive = TRUE, full.names = TRUE)[1], col_types = "text", col_names = FALSE))
ph <- as.data.frame(ph[, 1:7]); names(ph) <- c("name","W","B","IC","pop","deaths","rate"); ph <- ph[!is.na(ph$name) & !is.na(ph$pop), ]
t1 <- tibble()
for (i in seq_along(t1d)) {
  nm <- t1d[i]; k <- which(tolower(str_squish(ph$name)) == tolower(nm)); if (length(k) == 0) k <- which(str_sub(tolower(str_squish(ph$name)), 1, 4) == str_sub(tolower(nm), 1, 4))
  pdth <- if (length(k) == 1) as.numeric(ph$deaths[k]) else NA; ppop <- if (length(k) == 1) as.numeric(ph$pop[k]) else NA
  prate <- if (length(k) == 1) as.numeric(ph$rate[k]) else NA
  cd <- if (nm %in% d$town) sum(d$town == nm & d$flu == 1 & d$Pandemic == 1) else NA
  t1 <- bind_rows(t1, tibble(district = nm, phillips_deaths = pdth, phillips_pop = ppop, phillips_rate = prate, cert_deaths = cd, cert_rate = cd / ppop * 1000, matched = length(k)))
  setv(sprintf("T1_r%d_c1", i), pdth); setv(sprintf("T1_r%d_c3", i), prate)
  if (!is.na(cd)) { setv(sprintf("T1_r%d_c2", i), cd, n = cd); setv(sprintf("T1_r%d_c4", i), cd / ppop * 1000, n = cd) }
}
write_csv(t1, file.path(outd, "table1_subsample.csv"))

# ---------------- Table 2: doctor named, pre-pandemic, district x race ----------------
t2d <- c("Cradock","Elliot","Fraserburg","Komga","Kuruman","Mafeking","Oudtshoorn","Paarl","Peddie","Queenstown","Riversdale","Sea Point","Stellenbosch","Stockenstrom","Vryburg")
t2 <- d %>% filter(pre, !is.na(race)) %>% group_by(town, race) %>% summarise(pct = 100 * mean(doc), n = n(), .groups = "drop")
write_csv(t2, file.path(outd, "table2_subsample.csv"))
for (i in seq_along(t2d)) for (j in 1:3) { rr <- c("Black","Coloured","White")[j]; z <- t2 %>% filter(town == t2d[i], race == rr); if (nrow(z) == 1) setv(sprintf("T2_r%d_c%d", i, j), z$pct, n = z$n) }

# ---------------- Table 3 ----------------
d$period <- ifelse(d$Pandemic == 1, "pan", ifelse(d$pre, "pre", NA))
t3 <- d %>% filter(!is.na(period), !is.na(race)) %>% group_by(race, period) %>% summarise(fam = 100 * mean(Death_in_Family), addr = 100 * mean(Street_road_and_stad), n = n(), .groups = "drop")
write_csv(t3, file.path(outd, "table3_subsample.csv"))
for (i in 1:3) { rr <- c("White","Coloured","Black")[i]
  for (p in 1:2) { z <- t3 %>% filter(race == rr, period == c("pre","pan")[p]); setv(sprintf("T3_r%d_c%d", i, p), z$fam, n = z$n); setv(sprintf("T3_r%d_c%d", i, p + 2), z$addr, n = z$n) } }

# ---------------- Table 4: modified Whipple (normalised absolute deviation from uniform digits) ----------------
whip <- function(x) { x <- x[!is.na(x)]; if (length(x) < 5) return(NA_real_); p <- tabulate(x %% 10 + 1, 10) / length(x); 100 * sum(abs(p - 0.1)) / 1.8 }
docs <- c("bester","brodziak","cross","de jager","\\bdon\\b","du plessis","grobbelaar","heyn","lewin","stusser")
d$grp <- ifelse(d$race == "White", "W", ifelse(d$race %in% c("Black","Coloured"), "BC", NA))
t4 <- tibble()
for (i in seq_along(docs)) { sub <- d %>% filter(str_detect(mmn_l, docs[i]), !is.na(grp), !is.na(dur_num), !is.na(period))
  cells <- list(c("BC","pre"), c("W","pre"), c("BC","pan"), c("W","pan"))
  for (j in 1:4) { z <- sub %>% filter(grp == cells[[j]][1], period == cells[[j]][2]); w <- whip(z$dur_num)
    t4 <- bind_rows(t4, tibble(doctor = docs[i], grp = cells[[j]][1], period = cells[[j]][2], whipple = w, n = nrow(z))); setv(sprintf("T4_r%d_c%d", i, j), w, n = nrow(z)) } }
write_csv(t4, file.path(outd, "table4_subsample.csv"))

# ---------------- Table 5: pooled logit, district dummies, SE clustered by district ----------------
base <- c("Coloured","Black")
ages <- c("Age_0_4","Age_5_9","Age_10_14","Age_15_19","Age_20_24","Age_35_49","Age_50_69","Age_70")
occ <- c("Professionals_and_managers","Sales_and_service","Production","Children_and_Pensioners")
x2 <- c(ages, "male", occ, "signature")
x3 <- c(x2, "Africa","Asia","Europe","South_Africa","Death_in_Family","Nurse","Railway","Farm","Street_road_and_stad")
d$Coloured <- as.integer(d$race == "Coloured"); d$Black <- as.integer(d$race == "Black")
d$Male <- d$male; d$Signature <- d$signature
nm_fix <- function(v) c(male = "Male", signature = "Signature", Death_in_Family = "Death_in_Family")[v] %>% (function(z) ifelse(is.na(z), v, z))
mk <- function(xs) { for (v in c("Coloured","Black", xs)) d[[paste0("Pandemic_x_", v)]] <<- d$Pandemic * d[[v]]; invisible() }
mk(unique(c(x3)))
d$Pandemic_x_Male <- d$Pandemic * d$male; d$Pandemic_x_Signature <- d$Pandemic * d$signature; d$Pandemic_x_Death_in_family <- d$Pandemic * d$Death_in_Family
d$Male <- d$male; d$Signature <- d$signature
nmv <- function(v) ifelse(v == "male", "Male", ifelse(v == "signature", "Signature", v))
rhs <- function(xs) { v <- nmv(xs); px <- paste0("Pandemic_x_", ifelse(v == "Death_in_Family", "Death_in_family", v)); paste(c("Coloured","Black","Pandemic","Coloured_x_Pandemic","Black_x_Pandemic", v, px), collapse = " + ") }
d$Coloured_x_Pandemic <- d$Pandemic * d$Coloured; d$Black_x_Pandemic <- d$Pandemic * d$Black
# fix name clashes created by mk() for male/signature
d$Pandemic_x_Male <- d$Pandemic * d$male; d$Pandemic_x_Signature <- d$Pandemic * d$signature
d1 <- d %>% filter(!is.na(doc), !is.na(race))
cc <- complete.cases(d[, c("doc","race", x3)]); d3 <- d[cc, ]
fits <- list(
  c1 = feglm(as.formula("doc ~ Coloured + Black + Pandemic + Coloured_x_Pandemic + Black_x_Pandemic + factor(town)"), d1, family = "binomial"),
  c2 = feglm(as.formula(paste("doc ~", rhs(x2), "+ factor(town)")), d3, family = "binomial"),
  c3 = feglm(as.formula(paste("doc ~", rhs(x3), "+ factor(town)")), d3, family = "binomial"))
allse <- tibble()
for (k in names(fits)) { f <- fits[[k]]; cl <- summary(f, vcov = ~town); io <- summary(f, vcov = "iid")
  ct <- coeftable(cl); ci <- coeftable(io); nn <- nobs(f)
  allse <- bind_rows(allse, tibble(spec = k, term = rownames(ct), est = ct[, 1], se_cluster = ct[, 2], se_iid = ci[, 2], n = nn))
  nmz <- sub("^\\(Intercept\\)$", "Intercept", rownames(ct))
  for (r in seq_along(nmz)) if (!grepl("factor\\(town\\)", nmz[r])) setv(paste0("T5_", k, "_", nmz[r]), ct[r, 1], ct[r, 2], nn)
  setv(paste0("T5_", k, "_Observations"), nn)
  dd <- if (k == "c1") d1 else d3
  ll <- logLik(f)[1]; ll0 <- logLik(feglm(doc ~ 1, dd, family = "binomial"))[1]
  setv(paste0("T5_", k, "_Pseudo_R2"), 1 - ll / ll0, n = nn); setv(paste0("T5_", k, "_BIC"), BIC(f), n = nn)
  setv(paste0("T5_", k, "_Squared_Correlation"), cor(fitted(f), dd$doc)^2, n = nn) }
write_csv(allse, file.path(outd, "table5_all_se_subsample.csv"))
save_res()

# ---------------- Text numbers: predicted probabilities (Paarl reference person, model c3) ----------------
f3 <- fits$c3
ref <- d3[1, ] ; for (v in names(ref)) if (is.numeric(ref[[v]]) && !(v %in% c("year","month"))) ref[[v]] <- 0
ref$town <- "Paarl"
pp <- function(pan = 0, ...) { z <- ref; z$Pandemic <- pan; ch <- list(...); for (v in names(ch)) z[[v]] <- ch[[v]]
  z$Male <- z$male; z$Signature <- z$signature; z$Coloured_x_Pandemic <- z$Pandemic * z$Coloured; z$Black_x_Pandemic <- z$Pandemic * z$Black
  for (v in x3) { vv <- nmv(v); pn <- paste0("Pandemic_x_", ifelse(vv == "Death_in_Family", "Death_in_family", vv)); z[[pn]] <- z$Pandemic * z[[v]] }
  100 * predict(f3, newdata = z, type = "response") }
n3 <- nrow(d3)
P <- list(TXT_p9_a = pp(0), TXT_p9_b = pp(0, Coloured = 1), TXT_p9_c = pp(0, Black = 1), TXT_p9_d = pp(1), TXT_p9_e = pp(1, Coloured = 1), TXT_p9_f = pp(1, Black = 1),
  TXT_p9_g = pp(0), TXT_p9_h = pp(0, Age_70 = 1), TXT_p9_i = pp(1, Age_70 = 1), TXT_p9_k = pp(1, Production = 1, Professionals_and_managers = 0), TXT_p9_l = pp(0, Production = 1),
  TXT_p10_a = pp(1, signature = 0), TXT_p10_b = pp(1, signature = 1), TXT_p12_a = pp(1, Death_in_Family = 0), TXT_p12_b = pp(1, Death_in_Family = 1),
  TXT_p12_c = pp(1), TXT_p12_d = pp(1, Europe = 1), TXT_p13_a = pp(1, Railway = 0), TXT_p13_b = pp(1, Railway = 1),
  TXT_p15_a = pp(0, Street_road_and_stad = 0), TXT_p15_b = pp(0, Street_road_and_stad = 1), TXT_p15_d = pp(1, Street_road_and_stad = 0), TXT_p15_e = pp(1, Street_road_and_stad = 1))
for (k in names(P)) setv(k, unname(P[[k]]), n = n3)
setv("TXT_p9_j", unname(P$TXT_p9_i - P$TXT_p9_d), n = n3)
setv("TXT_p1_b", nrow(d), n = nrow(d)); setv("TXT_p2_c", 100 * mean(d$doc), n = nrow(d)); setv("TXT_p2_d", length(unique(d$town)), n = nrow(d))
setv("TXT_p6_a", sum(d$town == "Queenstown" & d$flu == 1 & d$Pandemic == 1), n = nrow(d))
setv("TXT_p14_b", sum(d$Nurse), n = nrow(d))
rw <- d %>% filter(Pandemic == 1); setv("TXT_p14_a", as.numeric(median(rw$date[rw$Railway == 1]) - median(rw$date[rw$Railway == 0])), n = nrow(rw))
ct3 <- coeftable(summary(f3, vcov = ~town)); ct2 <- coeftable(summary(fits$c2, vcov = ~town))
setv("TXT_p15_c", ct3["Pandemic_x_Street_road_and_stad", 1], ct3["Pandemic_x_Street_road_and_stad", 2], n3)
setv("TXT_p14_c", ct3["Pandemic_x_Nurse", 1], ct3["Pandemic_x_Nurse", 2], n3)
setv("TXT_p16_a", ct2["Black", 1], ct2["Black", 2], nobs(fits$c2)); setv("TXT_p16_b", ct3["Black", 1], ct3["Black", 2], n3)
save_res()
sink(file.path(outd, "run_summary.txt")); cat("N all:", nrow(d), " N c1:", nrow(d1), " N c2/c3:", n3, "\n"); print(t1); print(summary(res$status_override %in% NA)); sink()
