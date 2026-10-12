# S5 checks for Tables 1 and 3 (P05_DK). Loads the workspace saved by 02_rerun_session.R (D: scratch) and the
# S3 unit file (D: scratch), and writes aggregate results only (coefficients, SEs, counts; no microdata rows).
# Usage (project root): Rscript P05_DK/compare/s5_checks/03_checks.R
suppressPackageStartupMessages({ library(dplyr); library(sf); library(sandwich) })
source(file.path("tools", "paths.R"))
sf_use_s2(FALSE)
outdir <- file.path("P05_DK", "compare", "s5_checks")
k <- readRDS(dscratch("P05_DK", "compare", "s5_session.rds"))
ad <- as.data.frame(k$t1$analysis_data); ad$geometry <- NULL
r36 <- as.data.frame(k$census_1936_reduced); r36$geometry <- NULL

t1f <- deaths_sflu_per_1000 ~ black_share1911.x + col_share1911.x + log_density_1911 + log_rail_mdcentroid_to_nearestrail_km +
  rainfall_sepoctmean19101950 + as.factor(region.x)
t1lf <- update(t1f, log_deaths_sflu_per_1000 ~ .)
t3f <- unemployment_rate_w ~ log(deaths_sflu_per_1000) + black_share1911 + col_share1911 + log(1 + density_1911) +
  log(1 + rail_mdcentroid_to_nearestrail_km) + rainfall_sepoctmean19101950 + factor(region.x)
est <- function(m, term, type = "const") {
  v <- if (type == "const") vcov(m) else vcovHC(m, type = type)
  b <- unname(coef(m)[term]); se <- sqrt(v[term, term]); df <- df.residual(m)
  c(coef = b, se = se, p = 2 * pt(-abs(b / se), df), n = nobs(m))
}
rows <- list()
add <- function(scenario, claim_id, published, original_code, e, note) {
  rows[[length(rows) + 1]] <<- data.frame(scenario, claim_id, published, original_code = original_code,
    scenario_value = sprintf("%.6g (se %.4g; p %.4f; N %d)", e["coef"], e["se"], e["p"], as.integer(e["n"])), note)
}
pub <- c(T1_r1_c1 = "39.432 (10.933)", T1_r1_c2 = "1.490 (0.599)", T1_r1_c3 = "32.854 (9.782)", T1_r1_c4 = "1.374 (0.483)",
         T3_r1_c1 = "-0.007 (0.002)", T3_r1_c2 = "0.001 (0.001)", T3_r1_c3 = "-0.011 (0.003)")
m1 <- k$t1$model1; m2 <- k$t1$model2; m3 <- k$t1$model1excl; m4 <- k$t1$model2excl
T3m <- k$t3; tl <- "log(deaths_sflu_per_1000)"; bl <- "black_share1911.x"
oc <- function(e) sprintf("%.6g (%.4g)", e["coef"], e["se"])
base <- list(T1_r1_c1 = est(m1, bl, "HC2"), T1_r1_c2 = est(m2, bl, "HC2"), T1_r1_c3 = est(m3, bl), T1_r1_c4 = est(m4, bl),
             T3_r1_c1 = est(T3m$total_model, tl), T3_r1_c2 = est(T3m$female_model, tl), T3_r1_c3 = est(T3m$male_model, tl))
for (cid in names(base)) add("baseline_as_printed", cid, pub[cid], oc(base[[cid]]), base[[cid]], "original code, SE as printed")

# ---- C1/C2: SE type versus the HC2 note
for (ty in c("HC2", "HC1", "HC3")) {
  add(paste0("se_", ty), "T1_r1_c1", pub["T1_r1_c1"], oc(base$T1_r1_c1), est(m1, bl, ty), "C1: col 1 already HC2 in print")
  add(paste0("se_", ty), "T1_r1_c3", pub["T1_r1_c3"], oc(base$T1_r1_c3), est(m3, bl, ty), "C1: printed SE is classical")
  add(paste0("se_", ty), "T1_r1_c4", pub["T1_r1_c4"], oc(base$T1_r1_c4), est(m4, bl, ty), "C1: printed SE is classical")
  add(paste0("se_", ty), "T3_r1_c1", pub["T3_r1_c1"], oc(base$T3_r1_c1), est(T3m$total_model, tl, ty), "C2: printed SE is classical")
  add(paste0("se_", ty), "T3_r1_c2", pub["T3_r1_c2"], oc(base$T3_r1_c2), est(T3m$female_model, tl, ty), "C2")
  add(paste0("se_", ty), "T3_r1_c3", pub["T3_r1_c3"], oc(base$T3_r1_c3), est(T3m$male_model, tl, ty), "C2")
}

# ---- C5: outlier rule. Which rows have the largest |rstudent| and Cook's D in model1 / model2?
mf1 <- model.frame(m1); key1 <- ad$StndrdN[as.integer(rownames(mf1))]
rs <- data.frame(StndrdN = key1, rstud1 = rstudent(m1), cook1 = cooks.distance(m1), rstud2 = rstudent(m2))
cat("Rows dropped by position c(6,85,96):", ad$StndrdN[c(6, 85, 96)], "\n")
cat("Top-3 |rstudent| model1:", head(rs$StndrdN[order(-abs(rs$rstud1))], 3), "\n")
cat("Top-3 Cook's D model1:", head(rs$StndrdN[order(-rs$cook1)], 3), "\n")
cat("Top-3 |rstudent| model2 (log):", head(rs$StndrdN[order(-abs(rs$rstud2))], 3), "\n")
top2 <- head(rs$StndrdN[order(-abs(rs$rstud2))], 3)
m4b <- lm(t1lf, data = ad[!ad$StndrdN %in% top2, ])
add("outliers_from_log_model", "T1_r1_c4", pub["T1_r1_c4"], oc(base$T1_r1_c4), est(m4b, bl, "HC2"),
    paste("C5: col 4 drops the top-3 |rstudent| of the log model instead (", paste(top2, collapse = ", "), "); HC2"))
add("no_outlier_exclusion", "T1_r1_c4", pub["T1_r1_c4"], oc(base$T1_r1_c4), est(m2, bl, "HC2"), "C5: = col 2")

# ---- C6: dependent-variable means on the estimation sample
cat(sprintf("C6 means: T1 c1 all-rows %.3f est %.3f | c3 est %.3f | T3 c1 all %.4f est %.4f\n",
  mean(ad$deaths_sflu_per_1000, na.rm = TRUE), mean(model.frame(m1)[, 1]), mean(model.frame(m3)[, 1]),
  mean(r36$unemployment_rate_w, na.rm = TRUE), mean(model.frame(T3m$total_model)[, 1])))

# ---- C7: district matching. Duplicate mortality, unmatched Phillips rows, units without covariates.
dupm <- ad$mag_dist_1918.x[duplicated(ad$mag_dist_1918.x) & !is.na(ad$mag_dist_1918.x)]
cat("Phillips rows used twice:", dupm, "\n")
cat("Phillips rows not in analysis_data:", setdiff(k$mortality$mag_dist_1918, c(ad$mag_dist_1918.x, "Kimberey", "Umvoti (Greytown(")), "\n")
cat("1918 polygons in analysis_data without 1911 covariates:", ad$StndrdN[is.na(ad$black_share1911.x)], "\n")
inest1 <- ad$StndrdN %in% key1
cat("Duplicated-mortality rows in T1 estimation sample:", ad$StndrdN[ad$mag_dist_1918.x %in% dupm & inest1], "\n")

# ---- Density: authors' density_1911 = unweighted mean of 1970-district densities (census_1904_1970_cleaning_ddk.R:183),
# and 1970 districts are assigned whole to the 1918 district of largest overlap (:65). Alternative: 1911 total / 1918 area.
s18 <- st_read(dpath("P05_DK", "repro_original", "work", "data", "original", "spatial", "SA_1918.shp"), quiet = TRUE)
s18 <- st_make_valid(s18); s18$area_km2 <- as.numeric(st_area(s18)) / 1e6
ar <- st_drop_geometry(s18)[, c("StndrdN", "area_km2")] |> group_by(StndrdN) |> summarise(area_km2 = sum(area_km2))
ad2 <- left_join(ad, ar, by = "StndrdN")
ad2$log_density_1911 <- log(1 + ad2$total_1911.x / ad2$area_km2)
cat(sprintf("density: cor(log authors, log total/area) = %.3f\n", cor(ad$log_density_1911, ad2$log_density_1911, use = "complete")))
add("density_total_over_1918_area", "T1_r1_c1", pub["T1_r1_c1"], oc(base$T1_r1_c1), est(lm(t1f, ad2), bl, "HC2"),
    "density = 1911 total / 1918 polygon area instead of mean of 1970-district densities; HC2")
r36b <- left_join(r36, transmute(ad2, StndrdN, dens_alt = total_1911.x / area_km2), by = "StndrdN")
r36b$density_1911 <- r36b$dens_alt
add("density_total_over_1918_area", "T3_r1_c1", pub["T3_r1_c1"], oc(base$T3_r1_c1), est(lm(t3f, r36b), tl), "as above; classical SE as printed")

# ---- T3 working-age denominator: code sums Table 7 cols 18:33 = ages 15-69 (col 33 = "65-"); text says 15-64.
ea <- as.data.frame(k$european_ages_1936)
cat("Table 7 columns kept for working age:", names(ea)[18:33], "\n")
a65 <- ea |> transmute(mag_dist_1936, sex, a65 = suppressWarnings(as.numeric(as.character(`65`)))) |>
  mutate(a65 = ifelse(is.na(a65), 0, a65)) |> filter(sex %in% c("P", "M", "F"))
cat("Table 7 district-sex duplicates:", sum(duplicated(a65[, c("mag_dist_1936", "sex")])), "\n")
w65 <- tidyr::pivot_wider(a65, names_from = sex, values_from = a65, names_prefix = "a65_", values_fn = sum)
cm <- left_join(as.data.frame(k$census_1936_merge), w65, by = "mag_dist_1936")
cat("1936 merge rows", nrow(k$census_1936_merge), "->", nrow(cm), "; unmatched 65+ rows:", sum(is.na(cm$a65_P)), "\n")
red <- cm |> group_by(StndrdN) |> summarise(wa_p = sum(total_workingage_pop_w - a65_P), wa_f = sum(total_workingage_pop_w_f - a65_F),
  wa_m = sum(total_workingage_pop_w_m - a65_M), wa69 = sum(total_workingage_pop_w), u_t = sum(unemployed_w_t), u_f = sum(unemployed_w_f), u_m = sum(unemployed_w_m))
cat(sprintf("share of 65-69 in the 15-69 denominator: %.4f\n", 1 - sum(red$wa_p, na.rm = TRUE) / sum(red$wa69, na.rm = TRUE)))
r64 <- left_join(r36, red, by = "StndrdN")
r64$unemployment_rate_w <- r64$u_t / r64$wa_p; r64$unemployment_rate_w_f <- r64$u_f / r64$wa_f; r64$unemployment_rate_w_m <- r64$u_m / r64$wa_m
m64 <- lm(t3f, r64); m64f <- lm(update(t3f, unemployment_rate_w_f ~ .), r64); m64m <- lm(update(t3f, unemployment_rate_w_m ~ .), r64)
add("t3_workingage_15_64", "T3_r1_c1", pub["T3_r1_c1"], oc(base$T3_r1_c1), est(m64, tl), "denominator ages 15-64 as stated; classical SE")
add("t3_workingage_15_64_hc2", "T3_r1_c1", pub["T3_r1_c1"], oc(base$T3_r1_c1), est(m64, tl, "HC2"), "15-64 and HC2 as stated")
add("t3_workingage_15_64_hc2", "T3_r1_c2", pub["T3_r1_c2"], oc(base$T3_r1_c2), est(m64f, tl, "HC2"), "15-64 and HC2 as stated")
add("t3_workingage_15_64_hc2", "T3_r1_c3", pub["T3_r1_c3"], oc(base$T3_r1_c3), est(m64m, tl, "HC2"), "15-64 and HC2 as stated")
cat(sprintf("T3 mean 15-64 (est sample) %.4f vs 15-69 %.4f\n", mean(model.frame(m64)[, 1]), mean(model.frame(T3m$total_model)[, 1])))
# 1936 districts that never enter (inner_join at census_1936_cleanedversion_ddk.R:171)
u36 <- k$unemployment_1936$mag_dist_1936
cat("1936 unemployment rows:", length(u36), "; not in final merge:", sum(!u36 %in% k$census_1936_merge$mag_dist_1936), "->",
    paste(setdiff(u36, k$census_1936_merge$mag_dist_1936), collapse = "; "), "\n")
cat("white unemployed total in Table 1:", sum(k$unemployment_1936$unemployed_w_t), "; in merge:", sum(k$census_1936_merge$unemployed_w_t, na.rm = TRUE), "\n")

# ---- footnote-11 conversions at full precision
for (nm in c("total_model", "male_model")) cat(sprintf("%s: beta*log2*100 = %.3f pp\n", nm, coef(T3m[[nm]])[tl] * log(2) * 100))
cat(sprintf("15-64: total %.3f pp, men %.3f pp\n", coef(m64)[tl] * log(2) * 100, coef(m64m)[tl] * log(2) * 100))

# ---- Pair-B decomposition: swap S3 (independent rebuild) variables into the authors' analysis data, one at a time.
u <- readRDS(dpath("P05_DK", "repro_r", "_scratch", "districts_1918.rds")) |> st_drop_geometry()
u$first <- sub("\\|.*$", "", u$polys)
cat("S3 units not matched to an authors' StndrdN:", setdiff(u$first, ad$StndrdN), "\n")
cat("S3 units:", nrow(u), "; S3 units absent from authors' T1 sample:", paste(setdiff(u$first, key1), collapse = ", "),
    "; authors' T1 units absent from S3:", paste(setdiff(key1, u$first), collapse = ", "), "\n")
j <- left_join(ad, u, by = c("StndrdN" = "first"))
j <- j[ad$StndrdN %in% key1, ]
swaps <- list(
  shares = function(d) { d$black_share1911.x <- d$black_sh; d$col_share1911.x <- d$col_sh; d },
  density = function(d) { d$log_density_1911 <- d$ldens; d },
  rail = function(d) { d$log_rail_mdcentroid_to_nearestrail_km <- d$lrail; d },
  rain = function(d) { d$rainfall_sepoctmean19101950 <- d$rain_so_cm * 10; d },
  mortality = function(d) { d$deaths_sflu_per_1000 <- d$rate; d })
b0 <- lm(t1f, j)
dec <- list(data.frame(step = "authors (common units)", type = "base", coef = coef(b0)[bl], se_hc2 = est(b0, bl, "HC2")["se"], n = nobs(b0)))
cum <- j
for (s in names(swaps)) {
  one <- lm(t1f, swaps[[s]](j)); cum <- swaps[[s]](cum); cm_ <- lm(t1f, cum)
  dec[[length(dec) + 1]] <- data.frame(step = s, type = "one-at-a-time", coef = coef(one)[bl], se_hc2 = est(one, bl, "HC2")["se"], n = nobs(one))
  dec[[length(dec) + 1]] <- data.frame(step = s, type = "cumulative", coef = coef(cm_)[bl], se_hc2 = est(cm_, bl, "HC2")["se"], n = nobs(cm_))
}
uu <- u; uu$black_share1911.x <- uu$black_sh; uu$col_share1911.x <- uu$col_sh; uu$log_density_1911 <- uu$ldens
uu$log_rail_mdcentroid_to_nearestrail_km <- uu$lrail; uu$rainfall_sepoctmean19101950 <- uu$rain_so_cm * 10
uu$deaths_sflu_per_1000 <- uu$rate; uu$region.x <- uu$region
mS3 <- lm(t1f, uu)
dec[[length(dec) + 1]] <- data.frame(step = "S3 full", type = "S3", coef = coef(mS3)[bl], se_hc2 = est(mS3, bl, "HC2")["se"], n = nobs(mS3))
dec <- do.call(rbind, dec); rownames(dec) <- NULL; print(dec, digits = 5)
write.csv(dec, file.path(outdir, "03_pairB_decomposition_T1.csv"), row.names = FALSE)
cat(sprintf("cor authors vs S3: black %.4f col %.4f ldens %.4f lrail %.4f rain %.4f rate %.4f\n",
  cor(j$black_share1911.x, j$black_sh), cor(j$col_share1911.x, j$col_sh), cor(j$log_density_1911, j$ldens),
  cor(j$log_rail_mdcentroid_to_nearestrail_km, j$lrail), cor(j$rainfall_sepoctmean19101950, j$rain_so_cm), cor(j$deaths_sflu_per_1000, j$rate)))
cat(sprintf("mean abs diff black share %.4f; max %.3f (%s)\n", mean(abs(j$black_share1911.x - j$black_sh)),
  max(abs(j$black_share1911.x - j$black_sh)), j$StndrdN[which.max(abs(j$black_share1911.x - j$black_sh))]))
# T3: swap S3 outcome
j3 <- left_join(r36, u, by = c("StndrdN" = "first")); key3 <- r36$StndrdN[as.integer(rownames(model.frame(T3m$total_model)))]
j3 <- j3[j3$StndrdN %in% key3, ]
fit3 <- function(x, lab) { m <- lm(t3f, x); data.frame(step = lab, coef = coef(m)[tl], se_hc2 = est(m, tl, "HC2")["se"], n = nobs(m)) }
d3 <- list(fit3(j3, "authors (common units)"))
x <- j3; x$unemployment_rate_w <- x$ur_total; d3[[2]] <- fit3(x, "S3 outcome (15-64, area-weighted)")
x <- left_join(j3, red, by = "StndrdN"); x$unemployment_rate_w <- x$u_t / x$wa_p; d3[[3]] <- fit3(x, "authors outcome rebuilt 15-64")
x <- j3; x$black_share1911 <- x$black_sh; x$col_share1911 <- x$col_sh; x$density_1911 <- x$dens11; x$rail_mdcentroid_to_nearestrail_km <- x$rail_km
x$rainfall_sepoctmean19101950 <- x$rain_so_cm * 10; x$deaths_sflu_per_1000 <- x$rate
d3[[4]] <- fit3(x, "S3 regressors, authors outcome")
x$unemployment_rate_w <- x$ur_total; d3[[5]] <- fit3(x, "S3 regressors and outcome, common units")
d3 <- do.call(rbind, d3); rownames(d3) <- NULL; print(d3, digits = 5)
cat(sprintf("cor T3 outcome authors vs S3: %.4f; mean authors %.4f S3 %.4f\n", cor(j3$unemployment_rate_w, j3$ur_total, use = "complete"),
  mean(j3$unemployment_rate_w), mean(j3$ur_total, na.rm = TRUE)))
write.csv(d3, file.path(outdir, "03_pairB_decomposition_T3.csv"), row.names = FALSE)

res <- do.call(rbind, rows); rownames(res) <- NULL
write.csv(res, file.path(outdir, "03_scenarios.csv"), row.names = FALSE)
print(res[, c("scenario", "claim_id", "scenario_value")])
