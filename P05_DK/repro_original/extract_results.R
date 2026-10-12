# Builds results_original.csv from the S2 run (run_all.R) and writes SE diagnostics to logs/.
# Values are full-precision versions of what the authors' stargazer() calls print: for Table 1, cols 1-2 carry
# starprep() HC2 SEs and cols 3-4 the default lm SEs (stargazer receives only two SE vectors); Table 3 carries the
# default lm SEs. Usage (from P05_DK/repro_original):  Rscript extract_results.R
suppressPackageStartupMessages({ library(dplyr); library(sandwich); library(lmtest) })
source(file.path("..", "..", "tools", "paths.R"))
snap <- readRDS(dpath("P05_DK", "repro_original", "_scratch", "s2_snapshot.rds"))
t1 <- snap$predicting_mortality_analysis_ddk
t3 <- snap$census_1936_cleanedversion_ddk
claims <- read.csv(file.path("..", "claims", "claims.csv"))
note_run <- "R pipeline run via run_all.R (R 4.5.2, sf s2 off, tibble-subassignment shim); regenerated .tex identical to authors' outputs/tables"

hc2 <- function(m) sqrt(diag(vcovHC(m, type = "HC2")))
cls <- function(m) sqrt(diag(vcov(m)))
fstat <- function(m) unname(summary(m)$fstatistic[1])

# ---- Table 1 ----
t1m <- list(t1$model1, t1$model2, t1$model1excl, t1$model2excl)
t1se <- list(hc2(t1m[[1]]), hc2(t1m[[2]]), cls(t1m[[3]]), cls(t1m[[4]]))   # as printed (stargazer se = starprep(model1, model2))
t1terms <- c("black_share1911.x", "col_share1911.x", "log_density_1911", "log_rail_mdcentroid_to_nearestrail_km",
             "rainfall_sepoctmean19101950", "as.factor(region.x)Natal", "as.factor(region.x)Orange Free State",
             "as.factor(region.x)Transkei", "as.factor(region.x)Transvaal", "as.factor(region.x)Zululand", "(Intercept)")
rows <- list()
for (c in 1:4) {
  m <- t1m[[c]]; n <- nobs(m)
  for (r in seq_along(t1terms)) {
    rows[[length(rows) + 1]] <- data.frame(claim_id = sprintf("T1_r%d_c%d", r, c), value = unname(coef(m)[t1terms[r]]),
                                           se = unname(t1se[[c]][t1terms[r]]), n = n)
  }
  rows[[length(rows) + 1]] <- data.frame(claim_id = c(sprintf("T1_mean_c%d", c), sprintf("T1_n_c%d", c), sprintf("T1_rsq_c%d", c), sprintf("T1_F_c%d", c)),
                                         value = c(t1$meansy[c], n, summary(m)$r.squared, fstat(m)), se = NA, n = n)
}

# ---- Table 3 ----
t3m <- list(t3$total_model, t3$female_model, t3$male_model)
t3terms <- c("log(deaths_sflu_per_1000)", "black_share1911", "col_share1911", "log(1 + density_1911)",
             "log(1 + rail_mdcentroid_to_nearestrail_km)", "rainfall_sepoctmean19101950", "(Intercept)")
for (c in 1:3) {
  m <- t3m[[c]]; n <- nobs(m); s <- cls(m)
  for (r in seq_along(t3terms)) {
    rows[[length(rows) + 1]] <- data.frame(claim_id = sprintf("T3_r%d_c%d", r, c), value = unname(coef(m)[t3terms[r]]),
                                           se = unname(s[t3terms[r]]), n = n)
  }
  rows[[length(rows) + 1]] <- data.frame(claim_id = c(sprintf("T3_mean_c%d", c), sprintf("T3_n_c%d", c), sprintf("T3_rsq_c%d", c), sprintf("T3_F_c%d", c)),
                                         value = c(t3$meansy[c], n, summary(m)$r.squared, fstat(m)), se = NA, n = n)
}
res <- bind_rows(rows) |> mutate(status_override = NA_character_, note = note_run, cause = NA_character_)
res$note[grepl("^T1_r.*_c[34]$", res$claim_id)] <- paste(note_run, "| SE = default OLS (stargazer gets HC2 only for cols 1-2), table note says HC2")
res$note[grepl("^T3_r", res$claim_id)] <- paste(note_run, "| SE = default OLS (no se= passed to stargazer), table note says HC2")

# ---- Text claims computable from original-code objects ----
ad <- snap$analysis_data
b1 <- coef(t1$model1)["black_share1911.x"]
bt <- coef(t3$total_model)["log(deaths_sflu_per_1000)"]; bm <- coef(t3$male_model)["log(deaths_sflu_per_1000)"]
q <- quantile(ad$deaths_sflu_per_1000, c(.25, .75), na.rm = TRUE)
txt <- data.frame(
  claim_id = c("txt_p181_black40", "txt_p190_u_total", "txt_p190_u_men", "txt_p189_iqr_p25", "txt_p189_iqr_p75", "txt_p174_ndistricts"),
  value = c(b1, bt * log(2) * 100, bm * log(2) * 100, q[1], q[2], snap$n_mortality_rows),
  se = NA, n = c(nobs(t1$model1), nobs(t3$total_model), nobs(t3$male_model), sum(!is.na(ad$deaths_sflu_per_1000)), sum(!is.na(ad$deaths_sflu_per_1000)), NA),
  status_override = NA_character_,
  note = c("T1 col 1 Black share coefficient (original code)", "T3 col 1 coef x log(2) x 100 (original code)",
           "T3 col 3 coef x log(2) x 100 (original code)",
           "quantile(type 7) of deaths/1,000 across district rows of the authors' analysis_data; no authors' code computes it",
           "quantile(type 7) of deaths/1,000 across district rows of the authors' analysis_data; no authors' code computes it",
           "rows of Phillips Table 13 kept by census_1904_1970_cleaning_ddk.R (nrow(mortality) after drop_na)"),
  cause = NA_character_)

# ---- Everything else: unavailable ----
txt$cause[txt$claim_id == "txt_p190_u_total"] <- "rounding: paper uses printed -0.007 x log2 x 100 = -0.485; full-precision coef -0.00728 gives -0.505"
txt$cause[txt$claim_id == "txt_p190_u_men"] <- "rounding: paper uses printed -0.011 x log2 x 100 = -0.762; full-precision coef -0.01067 gives -0.740"
txt$cause[txt$claim_id == "txt_p181_black40"] <- "wording: 'nearly 40' for 39.43"
# The code never counts districts: Phillips Table 13 yields 207 district rows, SA_1918.shp has 208 polygons.
txt$status_override[txt$claim_id == "txt_p174_ndistricts"] <- "ambiguous"
txt$cause[txt$claim_id == "txt_p174_ndistricts"] <- "no code computes n; 207 Phillips rows vs 208 polygons in SA_1918.shp (the probable source of n = 208)"

done <- c(res$claim_id, txt$claim_id)
rest <- claims |> filter(!claim_id %in% done) |> transmute(claim_id, value = NA_real_, se = NA_real_, n = NA_real_, status_override = "unavailable", note = NA_character_, cause = NA_character_)
rest$note[grepl("^T2_", rest$claim_id)] <- "No code: no do-file or script producing voter_roll_1920s.tex exists in any recovered folder; saved .tex matches published coefficients"
rest$note[grepl("^T4_|maize", rest$claim_id)] <- "No code or output for Table 4 (maize yields) recovered"
rest$note[grepl("^F6a|nwomen|beta1880|iqr_effect", rest$claim_id)] <- "No code or data for Figure 6 (lifetime fertility, 1980/1996/2011 censuses) recovered"
rest$note[grepl("oct460|oct25pct", rest$claim_id)] <- "Depends on Table 2, which has no code"
rest$note[is.na(rest$note)] <- "External source quoted in text (not produced by the paper's code)"
out <- bind_rows(res, txt, rest) |> mutate(source = "original") |>
  select(claim_id, source, value, se, n, status_override, note, cause)
stopifnot(setequal(out$claim_id, claims$claim_id), !anyDuplicated(out$claim_id))
out <- out[match(claims$claim_id, out$claim_id), ]
write.csv(out, "results_original.csv", row.names = FALSE, na = "")

# ---- Diagnostics: SE type actually printed vs HC2 stated in the notes ----
diag <- bind_rows(
  lapply(1:4, function(c) data.frame(table = "T1", col = c, term = t1terms, coef = coef(t1m[[c]])[t1terms],
                                      se_printed = t1se[[c]][t1terms], se_ols = cls(t1m[[c]])[t1terms], se_hc2 = hc2(t1m[[c]])[t1terms])),
  lapply(1:3, function(c) data.frame(table = "T3", col = c, term = t3terms, coef = coef(t3m[[c]])[t3terms],
                                      se_printed = cls(t3m[[c]])[t3terms], se_ols = cls(t3m[[c]])[t3terms], se_hc2 = hc2(t3m[[c]])[t3terms]))) |>
  mutate(p_printed = 2 * pt(-abs(coef / se_printed), df = 193), p_hc2 = 2 * pt(-abs(coef / se_hc2), df = 193))
diag$p_printed[diag$table == "T1" & diag$col > 2] <- with(diag[diag$table == "T1" & diag$col > 2, ], 2 * pt(-abs(coef / se_printed), df = 190))
diag$p_hc2[diag$table == "T1" & diag$col > 2] <- with(diag[diag$table == "T1" & diag$col > 2, ], 2 * pt(-abs(coef / se_hc2), df = 190))
write.csv(diag, file.path("logs", "se_diagnostics.csv"), row.names = FALSE)

# Outliers dropped by position at predicting_mortality_analysis_ddk.R:64 (district names are public aggregates)
ol <- as.data.frame(ad)[c(6, 85, 96), c("mag_dist_1918.x", "StndrdN", "region.x", "deaths_sflu_per_1000")]
write.csv(ol, file.path("logs", "t1_outliers_dropped.csv"), row.names = FALSE)
cat("rows:", nrow(out), " available:", sum(is.na(out$status_override)), "\n"); print(ol)
print(diag |> filter(term %in% c("black_share1911.x", "log(deaths_sflu_per_1000)")) |> select(table, col, coef, se_printed, se_hc2, p_printed, p_hc2), digits = 3)
