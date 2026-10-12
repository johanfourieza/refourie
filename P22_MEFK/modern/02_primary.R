# P22_MEFK S6, step 2: verification checks, primary identified sets (method card v3, §3-§4) and verdicts (§8).
# Input: modern/_scratch/shareholders_{c1,noc1}.rds from 01_clean.R (on D:). Output: modern/output/{verification,primary,verdict}.csv
suppressPackageStartupMessages({library(dplyr); library(readr); library(tidyr); library(here)})
root <- here::here(); if (basename(root) != "Fourie_ReplicateMe") root <- normalizePath(file.path(root, ".."))
source(file.path(root, "tools", "paths.R"))
out <- file.path(root, "P22_MEFK", "modern", "output"); dir.create(out, showWarnings = FALSE)
sh0 <- readRDS(dscratch("P22_MEFK", "modern", "shareholders_noc1.rds"))
sh  <- readRDS(dscratch("P22_MEFK", "modern", "shareholders_c1.rds"))
s3  <- readRDS(dscratch("P22_MEFK", "repro_r", "shareholders.rds"))

# ---- verification 1: C1 off reproduces the S3 file and the S3 numbers exactly ----
pct <- function(x) 100 * mean(x, na.rm = TRUE)
capsh <- function(d, sel) 100 * sum(d$val[sel], na.rm = TRUE) / sum(d$val, na.rm = TRUE)
s3num <- function(d) c(TX_mid_inv = pct(d$cls == "Middle class"), TX_cap_mid = capsh(d, d$cls == "Middle class"),
                       TX_cap_bus = capsh(d, d$cls == "Businessmen"), TX_cap_foreign = capsh(d, d$foreign),
                       TX_foreign_cap_8 = pct(d$foreign), TX_local = 100 - pct(d$foreign),
                       TX_africans_share = pct(d$african), TX_afr_n = sum(d$african))
rr <- read_csv(file.path(root, "P22_MEFK", "repro_r", "results_r.csv"), show_col_types = FALSE)
cols <- c("rec", "val", "a", "b", "cls", "sub", "country", "foreign", "region", "african", "key")
ver <- tibble(check = names(s3num(sh0)), s3_results_r = rr$value[match(names(s3num(sh0)), rr$claim_id)],
              c1_off = unname(s3num(sh0)), c1_on = unname(s3num(sh))) |>
  mutate(match_c1_off = abs(c1_off - s3_results_r) < 1e-3 * pmax(1, abs(s3_results_r)) | is.na(s3_results_r))
ver <- bind_rows(ver, tibble(check = "rowlevel_identical_to_S3_scratch", c1_off = as.numeric(identical(as.data.frame(sh0[cols]), as.data.frame(s3[cols]))),
                             match_c1_off = identical(as.data.frame(sh0[cols]), as.data.frame(s3[cols]))),
                 tibble(check = "C1_rows_recoded (east london, foreign under S3)", c1_off = sum(sh0$foreign & grepl("east london", sh0$a)),
                        c1_on = sum(sh$foreign & grepl("east london", sh$a))),
                 tibble(check = "C1_value_recoded", c1_off = sum(sh0$val[sh0$foreign & !sh$foreign], na.rm = TRUE)))
write_csv(ver, file.path(out, "verification.csv"))
print(as.data.frame(ver))

# ---- primary (card §3): identified sets on the C1 file ----
UNK <- c("Information not available", "Unclassified occupation")
CLS <- c(mid = "Middle class", bus = "Businessmen", farm = "Farmers", rent = "Rentiers", work = "Working class", comp = "Company investors")
okv <- is.finite(sh$val) & sh$val >= 0                       # Value rule: missing/non-finite/negative excluded from capital
N <- nrow(sh); V <- sum(sh$val[okv]); n_badval <- sum(!okv)
fail <- N == 0 || V == 0                                       # failure rule §4
cnt <- function(sel) sum(sel); cap <- function(sel) sum(sh$val[sel & okv])
bounds <- function(sel, unk, w = c("rows", "value")) {
  w <- match.arg(w); if (w == "rows") c(cnt(sel), cnt(sel) + cnt(unk)) / N else c(cap(sel), cap(sel) + cap(unk)) / V }
U <- sh$cls %in% UNK
locUL <- is.na(sh$region) | sh$region == "Unassigned"
loc <- sh$region %in% c("Other Africa", "North", "East", "West")
setI <- lapply(CLS, function(k) bounds(sh$cls == k, U, "rows"))
setC <- lapply(CLS, function(k) bounds(sh$cls == k, U, "value"))
fcap <- bounds(sh$foreign, locUL, "value"); linv <- bounds(loc, locUL, "rows")
pairD <- function(S) bind_rows(lapply(setdiff(names(CLS), "mid"), function(j)
  tibble(competitor = CLS[[j]], DL = S$mid[1] - S[[j]][2], DU = S$mid[2] - S[[j]][1])))
DI <- pairD(setI); DC <- pairD(setC)

primary <- bind_rows(
  tibble(quantity = paste0("share_rows: ", CLS), L = sapply(setI, `[`, 1), U = sapply(setI, `[`, 2)),
  tibble(quantity = paste0("share_value: ", CLS), L = sapply(setC, `[`, 1), U = sapply(setC, `[`, 2)),
  tibble(quantity = c("share_value: Foreign (C1)", "share_rows: Local (C1)"), L = c(fcap[1], linv[1]), U = c(fcap[2], linv[2])),
  tibble(quantity = paste0("D_rows: Middle class - ", DI$competitor), L = DI$DL, U = DI$DU),
  tibble(quantity = paste0("D_value: Middle class - ", DC$competitor), L = DC$DL, U = DC$DU),
  tibble(quantity = c("share_rows: African (Xhosa)", "count: African (Xhosa)"), L = c(mean(sh$african), sum(sh$african)), U = c(mean(sh$african), sum(sh$african))),
  tibble(quantity = c("N rows", "N companies", "rows unknown class", "rows unknown location", "rows bad Value (excluded from capital)", "total Value", "Value unknown class", "Value unknown location"),
         L = c(N, n_distinct(sh$rec), sum(U), sum(locUL), n_badval, V, cap(U), cap(locUL)), U = NA_real_)) |>
  mutate(across(c(L, U), ~ ifelse(grepl("^(share|D_)", quantity), 100 * .x, .x)))
write_csv(primary, file.path(out, "primary.csv"))

# ---- verdicts (card §8, mechanical; first matching rule) ----
vset <- function(L, U, lo, hi) {
  if (fail) return(c("not-testable", 0))
  if (lo <= L && U <= hi) return(c("confirmed", 1)); if (U < lo) return(c("qualified (below the stated value)", 2))
  if (L > hi) return(c("qualified (above the stated value)", 3)); c("not-testable (compatible, not identified)", 4) }
vpt <- function(x, lo, hi) {
  if (fail) return(c("not-testable", 0)); if (lo <= x && x <= hi) return(c("confirmed", 1))
  if (x < lo) return(c("qualified (below the stated value)", 2)); c("qualified (above the stated value)", 3) }
vpl <- function(D) {
  if (fail) return(c("not-testable", 0)); if (all(D$DL > 0)) return(c("confirmed", 1))
  if (any(D$DU <= 0)) return(c("overturned (strict plurality ruled out; reconstruction-conditional)", 2)); c("not-testable (compatible, not identified)", 3) }
f2 <- function(x) sprintf("%.2f", x); iv <- function(b) sprintf("[%s, %s]", f2(100 * b[1]), f2(100 * b[2]))
pl_iv <- function(D) paste0("min_j D_L=", f2(100 * min(D$DL)), "; min_j D_U=", f2(100 * min(D$DU)), " (", D$competitor[which.min(D$DU)], ")")
rows <- list(
  list("M-inv", "TX_mid_inv", 100 * setI$mid[1], iv(setI$mid), "[24.3, 29.7]", vset(100 * setI$mid[1], 100 * setI$mid[2], 24.3, 29.7)),
  list("M-inv-pl", "TX_mid_inv", 100 * min(DI$DL), pl_iv(DI), "D_j > 0 for all j", vpl(DI)),
  list("M-cap", "TX_cap_mid", 100 * setC$mid[1], iv(setC$mid), "[28.0, 34.0]", vset(100 * setC$mid[1], 100 * setC$mid[2], 28, 34)),
  list("M-cap-pl", "TX_cap_mid", 100 * min(DC$DL), pl_iv(DC), "D_j > 0 for all j", vpl(DC)),
  list("F-cap", "TX_cap_foreign", 100 * fcap[1], iv(fcap), "[9.9, 12.1]", vset(100 * fcap[1], 100 * fcap[2], 9.9, 12.1)),
  list("F-cap8", "TX_foreign_cap_8", 100 * fcap[1], iv(fcap), "[7.2, 8.8]", vset(100 * fcap[1], 100 * fcap[2], 7.2, 8.8)),
  list("L-inv", "TX_local", 100 * linv[1], iv(linv), "[92.0, 98.0]", vset(100 * linv[1], 100 * linv[2], 92, 98)),
  list("A-sh", "TX_africans_share", 100 * mean(sh$african), "direct (no unknowns)", "[0.09, 0.11]", vpt(100 * mean(sh$african), 0.09, 0.11)),
  list("A-n", "TX_afr_n", sum(sh$african), "direct (no unknowns)", "[13.5, 16.5]", vpt(sum(sh$african), 13.5, 16.5)))
verdict <- bind_rows(lapply(rows, function(r) tibble(claim = r[[1]], claim_id = r[[2]], estimate = signif(r[[3]], 6), interval = r[[4]],
  test_p = NA_real_, threshold_or_band = r[[5]], verdict = r[[6]][1], rule = as.integer(r[[6]][2])))) |>
  mutate(note = case_when(claim %in% c("M-inv", "M-cap", "F-cap", "F-cap8", "L-inv") ~ "estimate = lower bound (unknowns allocated to none); interval = identified set; reconstruction-conditional",
                          grepl("-pl$", claim) ~ "estimate = min_j D_j^L (pp); interval = sharp pairwise bounds; verdict carried to claim_id; reconstruction-conditional",
                          TRUE ~ "direct field; reconstruction-conditional"))
write_csv(verdict, file.path(out, "verdict.csv"), na = "")
print(as.data.frame(verdict[, c("claim", "estimate", "interval", "verdict", "rule")]))
print(as.data.frame(bind_rows(rows = DI, value = DC, .id = "w") |> mutate(across(c(DL, DU), ~ round(100 * .x, 2)))))
