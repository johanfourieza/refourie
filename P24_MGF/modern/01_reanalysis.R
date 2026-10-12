# P24_MGF S6 modern reanalysis (method card v3, frozen at 3c93b12).
# Census rows (C21, C80): arithmetic on the authors' supplementary table.
# Kimberley rows (K04, K04-ex, K18-ex, KBW): sex composition of recorded deaths on the
# recovered registers, S3 crosswalk (repro_r/01_clean.R) unchanged.
# Inputs: repro_r/output/supp_population_transcribed.csv; D:/.../repro_r/kimberley_clean.rds
# Outputs (aggregates only): modern/output/*.csv
suppressMessages({library(tidyverse); library(here); library(fixest); library(fwildclusterboot)})
P <- "P24_MGF"
source(here::here("tools", "paths.R"))
out <- here::here(P, "modern", "output"); dir.create(out, showWarnings = FALSE)
SEED <- 20261012
LEV <- 1 - 0.05 / 3   # exact Bonferroni coverage, family of three (card §4)

supp   <- read_csv(here::here(P, "repro_r", "output", "supp_population_transcribed.csv"), show_col_types = FALSE)
kim0   <- readRDS(dpath(P, "repro_r", "kimberley_clean.rds"))
claims <- read_csv(here::here(P, "claims", "claims.csv"), show_col_types = FALSE)
xwalk  <- read_csv(here::here(P, "repro_r", "output", "race_crosswalk_counts.csv"), show_col_types = FALSE)

## 0. Verification checks: reproduce S3 before any change ---------------------------
t5_s3 <- read_csv(here::here(P, "repro_r", "output", "table5_rebuild.csv"), show_col_types = FALSE) |>
  filter(str_starts(spec, "main: "))
kids_s3 <- kim0 |> filter(!is.na(sex), race %in% c("black", "coloured", "white"), !is.na(age_m), age_m < 60)
chk <- kids_s3 |> mutate(band = cut(age_m, c(0, 6, 18, 60), right = FALSE,
                                    labels = c("0-5months", "6months-1p5years", "1p5-4years"))) |>
  filter(!is.na(band)) |> count(race, band, sex) |> pivot_wider(names_from = sex, values_from = n) |>
  mutate(band = as.character(band)) |> left_join(select(t5_s3, race, band, F_s3 = F, M_s3 = M), by = c("race", "band"))
fig1_s3 <- read_csv(here::here(P, "repro_r", "output", "fig1_sex_ratios_exactCI.csv"), show_col_types = FALSE)
verif <- tibble(
  check = c("S3 Table 5 band counts reproduce (12 cells)", "S3 Fig 1 SR reproduces from supp (39 points)",
            "records loaded = 12,092", "stray 1919 records under-five (dropped in S6)"),
  pass_or_value = c(all(chk$M == chk$M_s3 & chk$F == chk$F_s3),
                    isTRUE(all.equal(100 * supp$males / supp$females, fig1_s3$sr)),
                    nrow(kim0) == 12092,
                    sum(kids_s3$reg_year %in% 1919)) |> as.character())
write_csv(verif, file.path(out, "verification.csv"))
print(verif)

## 1. Analysis sample ----------------------------------------------------------------
# Register year from the file (D1: four 1926 entries sit in the 1925 register file).
kim <- kim0 |> filter(!(reg_year %in% 1919)) |>
  mutate(year = case_when(file == "Kimberley 1905 and 1910.xlsx" ~ reg_year,
                          TRUE ~ as.integer(str_extract(file, "(18|19)[0-9]{2}"))))
stopifnot(setequal(unique(kim$year), c(1895, 1900, 1905, 1910, 1925, 1930, 1935, 1940)))
excl <- kim |> summarise(records = n(), sex_missing = sum(is.na(sex)), race_missing_or_other = sum(!race %in% c("black", "white", "coloured")),
                         age_missing = sum(is.na(age_m)))
write_csv(excl, file.path(out, "exclusions.csv"))

prep <- function(k, lo18 = 18) k |> filter(!is.na(sex), !is.na(race), !is.na(age_m), age_m >= 0, age_m < 60) |>
  mutate(male = as.integer(sex == "M"), b18 = age_m >= lo18)
cellMF <- function(d) c(M = sum(d$male), F = sum(1 - d$male))

wilson <- function(x, n, lev) { z <- qnorm(1 - (1 - lev) / 2); p <- x / n
  c((p + z^2 / (2 * n) - z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2))) / (1 + z^2 / n),
    (p + z^2 / (2 * n) + z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2))) / (1 + z^2 / n)) }
newcombe <- function(x1, n1, x2, n2, lev) {
  p1 <- x1 / n1; p2 <- x2 / n2; w1 <- wilson(x1, n1, lev); w2 <- wilson(x2, n2, lev)
  c(p1 - p2 - sqrt((p1 - w1[1])^2 + (w2[2] - p2)^2), p1 - p2 + sqrt((w1[2] - p1)^2 + (p2 - w2[1])^2)) }

# The four Kimberley quantities on a given sample
kq <- function(k, lo18 = 18) {
  d <- prep(k, lo18)
  b04 <- cellMF(filter(d, race == "black")); b18 <- cellMF(filter(d, race == "black", b18)); w18 <- cellMF(filter(d, race == "white", b18))
  tibble(row = c("K04", "K04-ex", "K18-ex", "KBW"),
         M = c(b04["M"], b04["M"], b18["M"], b18["M"]), F = c(b04["F"], b04["F"], b18["F"], b18["F"]),
         M2 = c(NA, NA, NA, w18["M"]), F2 = c(NA, NA, NA, w18["F"])) |>
    mutate(p = M / (M + F), p2 = M2 / (M2 + F2), R = if_else(F > 0, 100 * M / F, NA_real_),
           est = case_when(row == "K04" ~ R, row == "KBW" ~ p - p2, TRUE ~ p - 0.5))
}

## 2. Primary --------------------------------------------------------------------------
cp <- function(x, n, lev) binom.test(x, n, conf.level = lev)$conf.int
cen <- function(yr) { r <- filter(supp, race == "black", year == yr); ci <- cp(r$males, r$males + r$females, 0.95)
  tibble(M = r$males, F = r$females, est = 100 * r$males / r$females, lo = 100 * ci[1] / (1 - ci[1]), hi = 100 * ci[2] / (1 - ci[2])) }
kp <- kq(kim)
heter <- function(d) { tb <- table(d$year, d$male); e <- suppressWarnings(chisq.test(tb))
  if (any(e$expected < 5)) c(test = "Fisher", p = fisher.test(tb, workspace = 2e8)$p.value) else c(test = "chi-square", p = e$p.value) }
dd <- prep(kim)
het <- list(K04 = heter(filter(dd, race == "black")), `K18-ex` = heter(filter(dd, race == "black", b18)),
            KBW_white = heter(filter(dd, race == "white", b18)))
het_str <- function(h) sprintf("%s p=%.3f", h["test"], as.numeric(h["p"]))

ci_row <- function(r) {
  if (r$row == "K04") { ci <- cp(r$M, r$M + r$F, 0.95); return(100 * ci / (1 - ci)) }   # reported only
  if (r$row == "KBW") return(newcombe(r$M, r$M + r$F, r$M2, r$M2 + r$F2, LEV))
  cp(r$M, r$M + r$F, LEV) - 0.5
}
kp$lo <- NA_real_; kp$hi <- NA_real_
for (i in seq_len(nrow(kp))) { ci <- ci_row(kp[i, ]); kp$lo[i] <- ci[1]; kp$hi[i] <- ci[2] }
# exact two-sided tests (reported): binomial vs 0.5; KBW two-sample test of proportions
kp$test_p <- c(binom.test(kp$M[1], kp$M[1] + kp$F[1])$p.value, binom.test(kp$M[2], kp$M[2] + kp$F[2])$p.value,
               binom.test(kp$M[3], kp$M[3] + kp$F[3])$p.value,
               prop.test(c(kp$M[4], kp$M2[4]), c(kp$M[4] + kp$F[4], kp$M2[4] + kp$F2[4]), correct = FALSE)$p.value)

primary <- bind_rows(
  cen(1921) |> mutate(row = "C21", claim_id = "F1_black_1921", published = 89.2, interval_type = "Clopper-Pearson 95% (does not vote)"),
  cen(1980) |> mutate(row = "C80", claim_id = "T4_black_1980_sr_04", published = 101.0, interval_type = "Clopper-Pearson 95% (does not vote)"),
  kp |> transmute(row, M, F, M2, F2, est, lo, hi, test_p,
                  claim_id = "T5_black_0-4years_sr", published = c(105.6, NA, NA, NA),
                  interval_type = c("Clopper-Pearson 95% on R (does not vote)", rep("Clopper-Pearson 98.33% (Bonferroni 3)", 2),
                                    "Newcombe hybrid score 98.33% (Bonferroni 3)"),
                  heterogeneity = c(het_str(het$K04), het_str(het$K04), het_str(het$`K18-ex`),
                                    paste0("black ", het_str(het$`K18-ex`), "; white ", het_str(het$KBW_white)))))
write_csv(primary, file.path(out, "primary.csv"), na = "")

## 3. Verdicts (card §8, mechanical) -----------------------------------------------------
band <- tibble(row = c("C21", "C80", "K04"), blo = c(80.28, 90.9, 95.04), bhi = c(98.12, 111.1, 116.16))
vpoint <- function(R, lo, hi) if (is.na(R)) list("not-testable", 0) else if (R >= lo && R <= hi) list("confirmed", 1) else if (R < lo) list("qualified (below the stated value)", 2) else list("qualified (above the stated value)", 3)
vcomp <- function(e, l, u) if (any(is.na(c(e, l, u)))) list("not-testable", 0) else if (l > 0) list("confirmed (reconstruction-conditional)", 1) else if (u < 0) list("overturned (reconstruction-conditional)", 2) else list("weakened", 3)
lab <- c(C21 = "arithmetic", C80 = "arithmetic", K04 = "numerical agreement on the recovered registers")
V <- list()
for (r in c("C21", "C80", "K04")) { x <- filter(primary, row == r); b <- filter(band, row == r); v <- vpoint(x$est, b$blo, b$bhi)
  V[[r]] <- tibble(claim = r, claim_id = x$claim_id, estimate = x$est, interval = sprintf("[%.2f, %.2f] (reported only)", x$lo, x$hi),
                   test_p = x$test_p, threshold_or_band = sprintf("[%.2f, %.2f]", b$blo, b$bhi),
                   verdict = if (v[[2]] == 1) paste0(v[[1]], " (", lab[r], ")") else v[[1]], rule = v[[2]]) }
for (r in c("C21e", "C80d")) V[[r]] <- tibble(claim = c(C21e = "C21e", C80d = "D80")[r],
  claim_id = c(C21e = "TX_p130_black_1921_est_a", C80d = "T4_black_1980_sr_death")[r], estimate = NA, interval = NA, test_p = NA,
  threshold_or_band = c(C21e = "< 91 (90.61)", C80d = "115.3")[r], verdict = "not-testable (inputs not recovered)", rule = 0)
for (r in c("K04-ex", "K18-ex", "KBW")) { x <- filter(primary, row == r); v <- vcomp(x$est, x$lo, x$hi)
  V[[r]] <- tibble(claim = r, claim_id = "T5_black_0-4years_sr (interpretation)", estimate = x$est,
                   interval = sprintf("[%.4f, %.4f] (98.33%%)", x$lo, x$hi), test_p = x$test_p,
                   threshold_or_band = "adjusted interval excludes 0, estimate > 0", verdict = v[[1]], rule = v[[2]]) }
verdict <- bind_rows(V)
write_csv(verdict, file.path(out, "verdict.csv"), na = "")
print(verdict, width = 200)

## 4. Sensitivities (never verdict-setting) ----------------------------------------------
S <- list()
add_s <- function(sens, spec, q) S[[length(S) + 1]] <<- q |> transmute(sensitivity = sens, spec = spec, row, M, F, M2, F2, est, p, p2, R)
# 1. leave one register year out
for (y in sort(unique(kim$year))) add_s("1 leave-one-year-out", paste("drop", y), kq(filter(kim, year != y)))
# 3. race recoding
kim3a <- kim |> mutate(race = if_else(str_to_lower(str_squish(race_raw)) %in% c("american negro", "ndebele"), "black", race))
add_s("3a recode American Negro, Ndebele -> black", "3a", kq(kim3a))
top20 <- xwalk |> arrange(desc(n)) |> slice_head(n = 20) |> pull(race_raw)
add_s("3b top-20 raw race strings only", "3b", kq(filter(kim, race_raw %in% top20)))
# 4. age boundary 17 months
add_s("4 lower bound of 18-59m band at 17m", "17-59m", kq(kim, lo18 = 17))
sens <- bind_rows(S)

# 5. missing-record bounds against the published Table 5 N
npub <- function(id) as.numeric(claims$reported_value[claims$claim_id == id])
mB04 <- max(0, npub("T5_black_0-4years_n") - (kp$M[1] + kp$F[1]))
mB18 <- max(0, npub("T5_black_1p5-4years_n") - (kp$M[3] + kp$F[3]))
mW18 <- max(0, npub("T5_white_1p5-4years_n") - (kp$M2[4] + kp$F2[4]))
b5 <- function(row, M, F, M2 = NA, F2 = NA, spec) tibble(sensitivity = "5 missing-record bounds", spec = spec, row, M, F, M2, F2) |>
  mutate(p = M / (M + F), p2 = M2 / (M2 + F2), R = 100 * M / F, est = case_when(row == "K04" ~ R, row == "KBW" ~ p - p2, TRUE ~ p - 0.5))
k <- kp
s5 <- bind_rows(
  b5("K04", k$M[1] + mB04, k$F[1], spec = sprintf("deficit %d all male", mB04)), b5("K04", k$M[1], k$F[1] + mB04, spec = sprintf("deficit %d all female", mB04)),
  b5("K04-ex", k$M[1] + mB04, k$F[1], spec = sprintf("deficit %d all male", mB04)), b5("K04-ex", k$M[1], k$F[1] + mB04, spec = sprintf("deficit %d all female", mB04)),
  b5("K18-ex", k$M[3] + mB18, k$F[3], spec = sprintf("deficit %d all male", mB18)), b5("K18-ex", k$M[3], k$F[3] + mB18, spec = sprintf("deficit %d all female", mB18)),
  b5("KBW", k$M[3] + mB18, k$F[3], k$M2[4], k$F2[4] + mW18, spec = sprintf("black +%d male, white +%d female", mB18, mW18)),
  b5("KBW", k$M[3], k$F[3] + mB18, k$M2[4] + mW18, k$F2[4], spec = sprintf("black +%d female, white +%d male", mB18, mW18)))

# 2. year-cluster wild bootstrap, Webb weights (unreliable: eight clusters)
dfmt <- function(fit, param, B = 9999) { set.seed(SEED)
  bt <- boottest(fit, param = param, clustid = "year", B = B, type = "webb", sign_level = 1 - LEV)
  c(p = pval(bt), lo = confint(bt)[1], hi = confint(bt)[2]) }
dB <- dd |> filter(race == "black") |> mutate(y = male - 0.5)
dB18 <- dB |> filter(b18)
dBW <- dd |> filter(race %in% c("black", "white"), b18) |> mutate(black = as.integer(race == "black"))
wb <- rbind(`K04-ex` = dfmt(feols(y ~ 1, dB, cluster = ~year), "(Intercept)"),
            `K18-ex` = dfmt(feols(y ~ 1, dB18, cluster = ~year), "(Intercept)"),
            KBW = dfmt(feols(male ~ black, dBW, cluster = ~year), "black"))
s2 <- tibble(sensitivity = "2 year-cluster wild bootstrap (Webb, 8 clusters; unreliable)", spec = "B=9999, 98.33% CI",
             row = rownames(wb), est = filter(kp, row != "K04")$est, boot_p = wb[, "p"], boot_lo = wb[, "lo"], boot_hi = wb[, "hi"])

# 6. census context: under-five points 1904-1946, black
s6 <- supp |> filter(race == "black", year %in% c(1904, 1911, 1921, 1936, 1946)) |>
  transmute(sensitivity = "6 census context", spec = paste(year, if_else(year < 1911, "(Cape)", "(Union)"), if_else(year == 1921, "under-one proxy", "under-five")),
            row = "C21", M = males, F = females, R = 100 * males / females, est = R)

sens_all <- bind_rows(sens, s5, s2, s6)
write_csv(sens_all, file.path(out, "sensitivities.csv"), na = "")
# ranges for the report
rng <- sens_all |> filter(sensitivity == "1 leave-one-year-out") |> group_by(row) |>
  summarise(est_min = min(est), est_max = max(est), R_min = min(R), R_max = max(R))
print(rng); print(filter(sens_all, !str_starts(sensitivity, "1 ")), n = 50, width = 200)
writeLines(capture.output(sessionInfo()), here::here(P, "modern", "sessionInfo.txt"))
