# P12 S5 check 2: rebuild-data checks (aggregates only). Re-creates the S3 model frame without writing to repro_r.
suppressMessages({library(dplyr); library(fixest); library(readr)})
source("tools/paths.R"); set.seed(12)
d <- readRDS(dpath("P12_FJ", "repro_r", "_scratch", "analysis.rds")); d$Pandemic <- d$pandemic
ages <- c("Age_0_4","Age_5_9","Age_10_14","Age_15_19","Age_20_24","Age_35_49","Age_50_69","Age_70")
occ <- c("Professionals_and_managers","Sales_and_service","Production","Children_and_Pensioners")
x2 <- c(ages, "Male", occ, "Signature")
x3 <- c(x2, "Africa","Asia","Europe","South_Africa","Death_in_Family","Nurse","Railway","Farm","Street_road_and_stad")
d$Male <- d$male; d$Signature <- d$signature
d$Coloured <- as.integer(d$race == "Coloured"); d$Black <- as.integer(d$race == "Black")
for (v in c("Coloured","Black", x3)) d[[paste0("P_", v)]] <- d$Pandemic * d[[v]]
fm <- function(xs, fe = "factor(town)") as.formula(paste("doc ~", paste(c("Coloured","Black","Pandemic", "P_Coloured","P_Black", xs, paste0("P_", xs)), collapse = " + "), "+", fe))
d3 <- d[complete.cases(d[, c("doc","race", x3)]), ]
H <- c("P_Coloured","P_Black","P_Street_road_and_stad")
row <- function(f, scen, vc = ~town) { ct <- coeftable(summary(f, vcov = vc)); k <- intersect(c(H, "Pandemic"), rownames(ct))
  tibble(scenario = scen, term = k, est = ct[k, 1], se = ct[k, 2], p = ct[k, 4], n = nobs(f)) }
f2 <- feglm(fm(x2), d3, family = "binomial"); f3 <- feglm(fm(x3), d3, family = "binomial")
R <- bind_rows(row(f2, "spec2_cluster"), row(f3, "spec3_cluster"), row(f3, "spec3_iid", "iid"), row(f3, "spec3_hetero", "hetero"))
# Predicted probabilities from spec 2 (the paper's text numbers match spec 2, see check 1)
ref <- d3[d3$town == "Paarl", ][1, ]; for (v in c("Coloured","Black","Pandemic", x3)) ref[[v]] <- 0
pp <- function(f, pan, ...) { z <- ref; z$Pandemic <- pan; ch <- list(...); for (v in names(ch)) z[[v]] <- ch[[v]]
  for (v in c("Coloured","Black", x3)) z[[paste0("P_", v)]] <- z$Pandemic * z[[v]]; round(100 * predict(f, newdata = z, type = "response"), 2) }
PP <- tibble(claim = paste0("TXT_p9_", c("a","b","c","d","e","f")),
  spec2 = c(pp(f2,0), pp(f2,0,Coloured=1), pp(f2,0,Black=1), pp(f2,1), pp(f2,1,Coloured=1), pp(f2,1,Black=1)),
  spec3 = c(pp(f3,0), pp(f3,0,Coloured=1), pp(f3,0,Black=1), pp(f3,1), pp(f3,1,Coloured=1), pp(f3,1,Black=1)))
# Reference-cell support: white, female, 25-34, farming, illiterate informant (counts only)
refcell <- d3 %>% mutate(ref = race == "White" & Male == 0 & rowSums(across(all_of(c(ages, occ)))) == 0 & Signature == 0) %>%
  group_by(Pandemic) %>% summarise(n_ref = sum(ref), share_doc_ref = mean(doc[ref]), n_white = sum(race == "White"), share_doc_white = mean(doc[race == "White"]))
# Raw doctor share by race and period
raw <- d3 %>% group_by(race, Pandemic) %>% summarise(n = n(), doc = round(100 * mean(doc), 1), .groups = "drop")
# Leave-one-district-out (spec 3, clustered) and a narrower pandemic window (Oct-Dec 1918)
loo <- bind_rows(lapply(unique(d3$town), function(t) row(feglm(fm(x3), d3[d3$town != t, ], family = "binomial"), paste0("loo_", t))))
d4 <- d3; d4$Pandemic <- as.integer(d4$date >= as.Date("1918-10-01") & d4$date <= as.Date("1918-12-31"))
for (v in c("Coloured","Black", x3)) d4[[paste0("P_", v)]] <- d4$Pandemic * d4[[v]]
R <- bind_rows(R, row(feglm(fm(x3), d4, family = "binomial"), "spec3_window_OctDec1918"), loo)
# Wild cluster bootstrap on the LPM analogue (logit not supported by fwildclusterboot)
wb <- tryCatch({ library(fwildclusterboot); dqrng::dqset.seed(12)
  l3 <- feols(update(fm(x3), . ~ . - factor(town)) , d3, fixef = NULL, cluster = ~town) ; NULL }, error = function(e) NULL)
wcb <- tryCatch({ suppressMessages(library(fwildclusterboot)); dqrng::dqset.seed(12)
  l3 <- feols(as.formula(paste(deparse(fm(x3, "town"), width.cutoff = 500L), collapse = "")), d3, cluster = ~town)
  bind_rows(lapply(H, function(h) { b <- boottest(l3, param = h, clustid = ~town, B = 9999, type = "webb")
    tibble(term = h, lpm_est = coef(l3)[h], p_cluster = pvalue(l3)[h], p_wcb_webb = pvalue(b)) })) }, error = function(e) tibble(err = conditionMessage(e)))
o <- "P12_FJ/compare/s5_checks/"
write_csv(R, paste0(o, "02_models.csv")); write_csv(PP, paste0(o, "02_predprob.csv")); write_csv(refcell, paste0(o, "02_refcell.csv"))
write_csv(raw, paste0(o, "02_raw_shares.csv")); write_csv(wcb, paste0(o, "02_wcb_lpm.csv"))
print(R %>% filter(!grepl("^loo", scenario)), n = 40); print(R %>% filter(grepl("^loo", scenario)) %>% group_by(term) %>% summarise(min = min(est), max = max(est), maxp = max(p)))
print(PP); print(refcell); print(raw); print(wcb)
