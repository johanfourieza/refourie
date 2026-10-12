# P12_FJ S6 03_sensitivities.R -- card §5 sensitivities 1-4, 6-21 (5 is 03b_score_boot.do). Reported, never verdict-determining.
suppressMessages({library(tidyr); library(fwildclusterboot); library(haven)})
source(here::here("P12_FJ", "modern", "00_common.R"))
scr <- dscratch("P12_FJ", "modern"); out <- here::here("P12_FJ", "modern", "output")
V <- readRDS(file.path(scr, "variants.rds"))
prep <- function(d, xs = X3) { d <- add_int(d); d[complete.cases(d[, c("doc","race", xs)]), ] }
d <- prep(V$main)
B0 <- c(Coloured_x_Pandemic.c2 = -0.7167, Black_x_Pandemic.c2 = -1.215, Coloured_x_Pandemic.c3 = -0.6029, Black_x_Pandemic.c3 = -1.222, Pandemic_x_Street_road_and_stad.c3 = -1.168)
cat_rule <- function(b, lo, hi, b0) { if (is.na(b0)) return(NA); L <- 0.5 * abs(b0); ex <- lo > 0 | hi < 0
  if (b > 0 && ex) "overturned (reversed)" else if (lo > -L && hi < L) "overturned (credible null)" else if (b < 0 && ex && abs(b) >= L) "confirmed" else if (b < 0 && ex) "qualified" else if (b < 0) "weakened" else "weakened (direction lost)" }
comp_cat <- function(term, lo, hi) { if (term == "Street_road_and_stad") { if (lo > 0) "supports" else if (hi < 0) "contradicts" else "uncertain" }
  else if (term == "theta_U") { if (hi < 0) "supports" else if (lo > 0) "contradicts" else "uncertain" } else NA }
tabulate_spec <- function(s, sp, label, centre = "full") {
  rt <- intersect(c("Coloured_x_Pandemic","Black_x_Pandemic"), names(s$theta)); ut <- intersect(c("Pandemic_x_Street_road_and_stad","Street_road_and_stad","theta_U"), names(s$theta))
  r <- NULL
  if (length(rt)) r <- rbind(r, cbind(family = "R", cv3(s$theta[rt], s$loo[, rt, drop = FALSE], 4, centre)))
  if (sp == "c3" && length(ut)) r <- rbind(r, cbind(family = "U", cv3(s$theta[ut], s$loo[, ut, drop = FALSE], 3, centre)))
  ex <- setdiff(names(s$theta), c(rt, ut)); if (length(ex)) r <- rbind(r, cbind(family = "none", cv3(s$theta[ex], s$loo[, ex, drop = FALSE], 1, centre)))
  r$spec <- sp; r$sens <- label; r$n <- s$n
  r$category <- mapply(function(t, b, lo, hi) { b0 <- B0[paste0(t, ".", sp)]; if (!is.na(b0)) cat_rule(b, lo, hi, b0) else comp_cat(t, lo, hi) }, r$term, r$est, r$lo, r$hi)
  r$fail <- sapply(r$term, function(t) { tt <- if (t == "theta_U") c("Street_road_and_stad","Pandemic_x_Street_road_and_stad") else t; tt <- intersect(tt, names(s$fail_full)); any(s$fail_full[tt]) || any(s$fail_loo[tt] > 0) })
  r
}
paarl <- function(fit, data, xs) { ref <- data[1, ]; for (v in c("Coloured","Black","Pandemic", X3)) ref[[v]] <- 0; ref$town <- "Paarl"
  sapply(list(c("W",0),c("C",0),c("B",0),c("W",1),c("C",1),c("B",1)), function(a) { z <- ref; z$Coloured <- as.integer(a[1] == "C"); z$Black <- as.integer(a[1] == "B"); z$Pandemic <- as.integer(a[2])
    100 * predict(fit, newdata = add_int(z), type = "response") }) |> setNames(paste0("P-", letters[1:6])) }
COEF <- list(); DESC <- list()
desc_rows <- function(s, label, xs) { G <- s$G; jk <- sqrt((G - 1) / G * colSums(sweep(s$did_loo, 2, s$did)^2))
  rbind(data.frame(sens = label, quantity = names(s$did), est = s$did, jk_se = jk, loo_min = apply(s$did_loo, 2, min), loo_max = apply(s$did_loo, 2, max)),
        data.frame(sens = label, quantity = paste0("P-", letters[1:6]), est = paarl(s$fit, d, xs), jk_se = NA, loo_min = NA, loo_max = NA)) }
variant <- function(dd, label, specs = c("c2","c3"), x2 = X2, x3 = X3, fe = "factor(town)", pan = TRUE, drop = character(0)) {
  if ("c2" %in% specs) { s <- run_spec(dd, x2, fe = fe, pan = pan, want_did = pan); COEF[[paste(label, "c2")]] <<- tabulate_spec(s, "c2", label); if (pan) DESC[[label]] <<- desc_rows(s, label, x2) }
  if ("c3" %in% specs) { s <- run_spec(dd, x3, fe = fe, pan = pan, drop = drop); COEF[[paste(label, "c3")]] <<- tabulate_spec(s, "c3", label) }
}
t0 <- Sys.time()
variant(d, "0 primary")
variant(prep(V$uncorr), "1 uncorrected S3 coding")
variant(prep(V$O_only), "2a rule O only"); variant(prep(V$D_only), "2b rule D only")
variant(prep(V$D_0to7), "3 DiF window 0-7 days")
variant(prep(V$D_rec), "4 rule D on recorded days only")
variant(prep(V$win_dec), "10 pandemic window Oct-Dec 1918")
variant(prep(add_int(V$main), X2), "11 spec 2 own complete cases", specs = "c2")
variant(d, "12 spec 3 without Death_in_Family", specs = "c3", drop = "Death_in_Family")
variant(d, "14 calendar-year FE", fe = "factor(town) + factor(year)")
variant(d, "15 district x pandemic FE", fe = "factor(town):factor(Pandemic)", pan = FALSE)
variant(prep(V$docinit), "17 initials-only doctor = missing")
variant(d[d$town != "Sea Point", ], "18 Sea Point excluded")
# 13: spec 3 as the model for H2-P and P rows
s13 <- run_spec(d, X3, want_did = TRUE); DESC[["13"]] <- desc_rows(s13, "13 spec 3 for H2-P and P", X3)
# 7: CV3J; 19: occupation pandemic contrasts (spec 3, lambda + mu)
s3x <- run_spec(d, X3, extra = list(Prod_pandemic = c("Production","Pandemic_x_Production"), Sales_pandemic = c("Sales_and_service","Pandemic_x_Sales_and_service"),
                                     Prof_pandemic = c("Professionals_and_managers","Pandemic_x_Professionals_and_managers")))
s2p <- run_spec(d, X2)
COEF[["7 c2"]] <- tabulate_spec(s2p, "c2", "7 CV3J (jackknife-mean centred)", "mean"); COEF[["7 c3"]] <- tabulate_spec(s3x, "c3", "7 CV3J (jackknife-mean centred)", "mean") |> subset(family != "none")
COEF[["19"]] <- tabulate_spec(s3x, "c3", "19 occupation pandemic contrasts (lambda + mu)") |> subset(family == "none")
# collinearity log for primary leave-one-out fits
coll <- NULL; for (sp in c("c2","c3")) for (g in sort(unique(d$town))) { f <- fit1(fml(if (sp == "c2") X2 else X3), d[d$town != g, ]); if (length(f$collin.var)) coll <- rbind(coll, data.frame(spec = sp, dropped_town = g, collinear = paste(f$collin.var, collapse = ";"))) }
write.csv(coll, file.path(out, "loo_collinearity_log.csv"), row.names = FALSE)
# 6: CR1, t(G-1) and normal
cr1 <- NULL; for (sp in c("c2","c3")) { f <- fit1(fml(if (sp == "c2") X2 else X3), d); V1 <- vcov(f, vcov = ~town); b <- coef(f)
  tt <- c("Coloured_x_Pandemic","Black_x_Pandemic", if (sp == "c3") c("Pandemic_x_Street_road_and_stad","Street_road_and_stad","theta_U"))
  for (t in tt) { if (t == "theta_U") { a <- c("Street_road_and_stad","Pandemic_x_Street_road_and_stad"); e <- sum(b[a]); se <- sqrt(sum(V1[a, a])) } else { e <- b[t]; se <- sqrt(V1[t, t]) }
    m <- ifelse(grepl("Street|theta", t), 3, 4); G <- 11
    cr1 <- rbind(cr1, data.frame(sens = "6 CR1 t(G-1)", spec = sp, term = t, est = e, se = se, p = 2 * pt(-abs(e / se), G - 1), lo = e - qt(1 - .05 / (2 * m), G - 1) * se, hi = e + qt(1 - .05 / (2 * m), G - 1) * se),
                 data.frame(sens = "6 CR1 normal", spec = sp, term = t, est = e, se = se, p = 2 * pnorm(-abs(e / se)), lo = e - qnorm(1 - .05 / (2 * m)) * se, hi = e + qnorm(1 - .05 / (2 * m)) * se)) } }
cr1$category <- mapply(function(t, sp, b, lo, hi) { b0 <- B0[paste0(t, ".", sp)]; if (!is.na(b0)) cat_rule(b, lo, hi, b0) else comp_cat(t, lo, hi) }, cr1$term, cr1$spec, cr1$est, cr1$lo, cr1$hi)
# 8: leave-one-district-out, nested CV3 (G = 10) -> number of drops that change the verdict category
s8 <- NULL; prim_cat <- rbind(COEF[["0 primary c2"]], COEF[["0 primary c3"]])
for (g in sort(unique(d$town))) { dg <- d[d$town != g, ]
  for (sp in c("c2","c3")) { s <- run_spec(dg, if (sp == "c2") X2 else X3); r <- tabulate_spec(s, sp, paste("8 drop", g)); s8 <- rbind(s8, r) } }
s8 <- merge(s8, prim_cat[, c("spec","term","category")], by = c("spec","term"), suffixes = c("", "_primary"))
s8_sum <- s8 |> group_by(spec, term) |> summarise(loo_min = min(est), loo_max = max(est), n_changed = sum(category != category_primary), changed_by = paste(sub("8 drop ", "", sens[category != category_primary]), collapse = ";"),
                                                   categories = paste(unique(category), collapse = "/"), .groups = "drop")
write.csv(s8, file.path(out, "sens08_loo_nested.csv"), row.names = FALSE); print(s8_sum)
# 9: LPM analogue, WCR bootstrap (Webb, B = 999)
wcb <- NULL; set.seed(20261012); dqrng::dqset.seed(20261012)
for (sp in c("c2","c3")) { f <- feols(fml(if (sp == "c2") X2 else X3), d, cluster = ~town)
  hy <- list(Coloured_x_Pandemic = "Coloured_x_Pandemic", Black_x_Pandemic = "Black_x_Pandemic")
  if (sp == "c3") hy <- c(hy, list(Pandemic_x_Street_road_and_stad = "Pandemic_x_Street_road_and_stad", Street_road_and_stad = "Street_road_and_stad", theta_U = c("Street_road_and_stad","Pandemic_x_Street_road_and_stad")))
  for (h in names(hy)) { m <- ifelse(grepl("Street|theta", h), 3, 4)
    bt <- boottest(f, param = hy[[h]], R = rep(1, length(hy[[h]])), clustid = "town", B = 999, type = "webb", sign_level = 0.05 / m)
    wcb <- rbind(wcb, data.frame(sens = "9 LPM WCR Webb B=999", spec = sp, term = h, est = sum(coef(f)[hy[[h]]]), p = pval(bt), lo = confint(bt)[1], hi = confint(bt)[2], level = 1 - 0.05 / m)) } }
print(wcb)
# 16: support and overlap
refcell <- d |> filter(town == "Paarl", Male == 0, rowSums(across(all_of(ages))) == 0, rowSums(across(all_of(occs))) == 0, Signature == 0) |> count(race, Pandemic)
raw <- d |> group_by(race, Pandemic) |> summarise(doc_share = 100 * mean(doc), n = n(), .groups = "drop")
f2 <- s2p$fit; cellv <- c("town", X2); d$cell <- do.call(paste, d[, cellv])
top <- d |> count(race, Pandemic, cell) |> group_by(race, Pandemic) |> slice_max(n, n = 1, with_ties = FALSE) |> ungroup()
top$pred <- sapply(seq_len(nrow(top)), function(i) 100 * predict(f2, newdata = d[d$cell == top$cell[i] & d$race == top$race[i] & d$Pandemic == top$Pandemic[i], ][1, ], type = "response"))
top$raw <- sapply(seq_len(nrow(top)), function(i) 100 * mean(d$doc[d$cell == top$cell[i] & d$race == top$race[i] & d$Pandemic == top$Pandemic[i]]))
top$cell <- NULL
ov <- NULL; for (r in c("W","C","B")) for (q in 0:1) { p <- pcf(f2, d, r, q, X2); ov <- rbind(ov, data.frame(race = r, pandemic = q, p05 = quantile(p, .05), p50 = median(p), p95 = quantile(p, .95), share_lt01 = mean(p < .01), share_gt99 = mean(p > .99))) }
# 20: race-specific trends by quarter (spec-1 sample: doc and race observed)
d1 <- V$main |> filter(!is.na(doc), !is.na(race)) |> mutate(q = year + (ceiling(month / 3) - 1) / 4)
qtr <- d1 |> group_by(race, q) |> summarise(share = 100 * mean(doc), n = n(), .groups = "drop")
tr <- d1 |> group_by(race) |> summarise(pre_slope_pp_per_year = 100 * coef(lm(doc ~ q, data = pick(everything()) |> filter(date < as.Date("1918-10-01"))))[2],
                                         pre_level = 100 * mean(doc[date < as.Date("1918-10-01")]), pandemic_level = 100 * mean(doc[pandemic == 1]), post_level = 100 * mean(doc[date > as.Date("1919-01-31")]))
cat("sensitivities runtime:", format(Sys.time() - t0), "\n")
# write
coef_all <- bind_rows(lapply(COEF, function(x) mutate(x, across(everything(), as.character))))
desc_all <- bind_rows(DESC)
write.csv(coef_all, file.path(out, "sens_coefficients.csv"), row.names = FALSE)
write.csv(desc_all, file.path(out, "sens_H2P_P_descriptive.csv"), row.names = FALSE)
write.csv(cr1, file.path(out, "sens06_cr1.csv"), row.names = FALSE); write.csv(s8_sum, file.path(out, "sens08_summary.csv"), row.names = FALSE)
write.csv(wcb, file.path(out, "sens09_lpm_wcb.csv"), row.names = FALSE)
write.csv(refcell, file.path(out, "sens16_refcell.csv"), row.names = FALSE); write.csv(raw, file.path(out, "sens16_raw_shares.csv"), row.names = FALSE)
write.csv(top, file.path(out, "sens16_top_cells.csv"), row.names = FALSE); write.csv(ov, file.path(out, "sens16_overlap.csv"), row.names = FALSE)
write.csv(qtr, file.path(out, "sens20_quarterly.csv"), row.names = FALSE); write.csv(tr, file.path(out, "sens20_trends.csv"), row.names = FALSE)
sens <- bind_rows(coef_all |> select(sens, spec, term, est, se, p, lo, hi, category),
                  cr1 |> mutate(across(everything(), as.character)), wcb |> mutate(across(everything(), as.character)) |> select(-level),
                  s8_sum |> transmute(sens = "8 LOO (nested CV3, G = 10)", spec, term, est = NA, lo = as.character(loo_min), hi = as.character(loo_max), category = paste0(n_changed, " drops change category: ", changed_by)),
                  desc_all |> transmute(sens, spec = ifelse(grepl("^13", sens), "c3", "c2"), term = quantity, est = as.character(est), se = as.character(jk_se), lo = as.character(loo_min), hi = as.character(loo_max), category = "descriptive"))
write.csv(sens, file.path(out, "sensitivities.csv"), row.names = FALSE)
print(refcell); print(raw); print(tr); print(ov)
# export for 03b_score_boot.do (short names; Stata 32-char limit)
sn <- function(v) { v <- sub("^Pandemic_x_", "P_", v); v <- sub("Professionals_and_managers", "Prof", v); v <- sub("Children_and_Pensioners", "Child", v); v <- sub("Sales_and_service", "Sales", v)
  v <- sub("Street_road_and_stad", "Street", v); v <- sub("Death_in_Family", "DiF", v); v <- sub("South_Africa", "SAfr", v); v <- sub("Coloured_x_Pandemic", "CxP", v); sub("Black_x_Pandemic", "BxP", v) }
ex <- d[, c("doc","town","Coloured","Black","Pandemic","Coloured_x_Pandemic","Black_x_Pandemic", X3, paste0("Pandemic_x_", X3))]; names(ex) <- sn(names(ex))
ex$towni <- as.integer(factor(ex$town)); ex$town <- NULL
write_dta(ex, file.path(scr, "primary.dta"))
writeLines(c(sprintf('global X2 "%s"', paste(c(sn(X2), sn(paste0("Pandemic_x_", X2))), collapse = " ")),
             sprintf('global X3 "%s"', paste(c(sn(X3), sn(paste0("Pandemic_x_", X3))), collapse = " "))), file.path(scr, "vars.do"))
