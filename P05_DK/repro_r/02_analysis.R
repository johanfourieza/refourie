# P05_DK -- S3 independent recreation
# 02_analysis.R: Table 1 (correlates of 1918 flu mortality) and Table 3 (1936 white unemployment).
# Table 2 (voters' roll), Table 4 (maize) and Fig. 6 (1980/96/2011 censuses) are unavailable on the allow-list.
# Outputs: output/T1_recreated.tex, output/T3_recreated.tex, output/T1_se_both.csv, output/T3_se_both.csv,
#          output/sensitivity.csv, results_r.csv

suppressPackageStartupMessages({
  library(tidyverse); library(sf); library(sandwich); library(lmtest); library(modelsummary)
})
root <- here::here("P05_DK")
source(here::here("tools", "paths.R"))
out_dir <- file.path(root, "repro_r", "output"); dir.create(out_dir, showWarnings = FALSE)

d <- readRDS(dscratch("P05_DK", "repro_r", "districts_1918.rds")) |> st_drop_geometry()
aux <- readRDS(dscratch("P05_DK", "repro_r", "aux_counts.rds"))
claims <- read_csv(file.path(root, "claims", "claims.csv"), show_col_types = FALSE)

covs <- "black_sh + col_sh + ldens + lrail + rain_so_cm + region"
f_lvl <- as.formula(paste("rate ~", covs))
f_log <- as.formula(paste("log_rate ~", covs))

# ---------------------------------------------------------------- Table 1
m1 <- lm(f_lvl, d)
m2 <- lm(f_log, d)
out3 <- order(abs(rstudent(m1)), decreasing = TRUE)[1:3]          # pre-declared rule
cat("Outliers dropped (col 1 rstudent):", d$name[out3], "\n")
d_x <- d[-out3, ]
m3 <- lm(f_lvl, d_x)
m4 <- lm(f_log, d_x)
# sensitivity: col 4 with outliers chosen from the log model
out3_log <- order(abs(rstudent(m2)), decreasing = TRUE)[1:3]
cat("Outliers by col 2 rstudent:", d$name[out3_log], "\n")
m4b <- lm(f_log, d[-out3_log, ])

# ---------------------------------------------------------------- Table 3
f_u <- function(y) as.formula(paste(y, "~ log_rate +", covs))
u1 <- lm(f_u("ur_total"), d); u2 <- lm(f_u("ur_women"), d); u3 <- lm(f_u("ur_men"), d)

# ---------------------------------------------------------------- helpers
tidy_both <- function(m, tab, col) {
  b <- coef(m); se_c <- sqrt(diag(vcov(m))); se_h <- sqrt(diag(vcovHC(m, type = "HC2")))
  tibble(table = tab, col = col, term = names(b), estimate = b, se_conv = se_c, se_hc2 = se_h,
         p_hc2 = 2 * pt(-abs(b / se_h), df.residual(m)), n = nobs(m))
}
fstat <- function(m) unname(summary(m)$fstatistic[1])

coefs <- bind_rows(tidy_both(m1, "T1", 1), tidy_both(m2, "T1", 2), tidy_both(m3, "T1", 3),
                   tidy_both(m4, "T1", 4), tidy_both(u1, "T3", 1), tidy_both(u2, "T3", 2),
                   tidy_both(u3, "T3", 3))
write_csv(coefs |> filter(table == "T1"), file.path(out_dir, "T1_se_both.csv"))
write_csv(coefs |> filter(table == "T3"), file.path(out_dir, "T3_se_both.csv"))

# ---------------------------------------------------------------- tables (.tex)
cm1 <- c(black_sh = "Black Pop. Share (1911)", col_sh = "Coloured Pop. Share (1911)",
         ldens = "Log (1 + Pop. Density (1911))", lrail = "Log (1 + Distance to Rail in Km (1907))",
         rain_so_cm = "Avg. Sept/Oct Rain in Cm (1910-1950)", regionNatal = "Region = Natal",
         regionOFS = "Region = Orange Free State", regionTranskei = "Region = Transkei",
         regionTransvaal = "Region = Transvaal", regionZululand = "Region = Zululand",
         `(Intercept)` = "Constant")
hc2 <- function(m) vcovHC(m, type = "HC2")
modelsummary(list("Deaths/1,000" = m1, "Log (Deaths/1,000)" = m2,
                  "Deaths/1,000 (excl. outliers)" = m3, "Log (Deaths/1,000) (excl. outliers)" = m4),
             vcov = lapply(list(m1, m2, m3, m4), hc2), coef_map = cm1, stars = c("*" = .1, "**" = .05, "***" = .01),
             fmt = 3, gof_map = c("nobs", "r.squared", "F"), output = file.path(out_dir, "T1_recreated.tex"),
             title = "Recreated Table 1. Correlates of 1918 influenza mortality (HC2 SEs)")
cm3 <- c(log_rate = "Log (Deaths/1,000)", cm1[c(1:5, 11)])
modelsummary(list("U. Rate (Total)" = u1, "U. Rate (Women)" = u2, "U. Rate (Men)" = u3),
             vcov = lapply(list(u1, u2, u3), hc2), coef_map = cm3, stars = c("*" = .1, "**" = .05, "***" = .01),
             fmt = 3, gof_map = c("nobs", "r.squared", "F"), output = file.path(out_dir, "T3_recreated.tex"),
             title = "Recreated Table 3. 1918 influenza mortality and 1936 white unemployment (HC2 SEs; region FE)")

# ---------------------------------------------------------------- sensitivity (not primary)
sens_mod <- function(label, f, data) {
  m <- lm(f, data); se <- sqrt(diag(vcovHC(m, type = "HC2")))
  tibble(spec = label, term = names(coef(m)), estimate = coef(m), se_hc2 = se, n = nobs(m))
}
covs_ph <- "black_sh_ph + col_sh_ph + ldens_ph + lrail + rain_so_cm + region"
covs_ra <- "black_sh + col_sh + ldens + lrail_all + rain_so_cm + region"
sens <- bind_rows(
  sens_mod("T1c1_phillips_shares", as.formula(paste("rate ~", covs_ph)), d),
  sens_mod("T1c2_phillips_shares", as.formula(paste("log_rate ~", covs_ph)), d),
  sens_mod("T1c1_rail_incl_proposed", as.formula(paste("rate ~", covs_ra)), d),
  sens_mod("T1c4_outliers_from_log_model", f_log, d[-out3_log, ]),
  sens_mod("T3c1_phillips_shares", as.formula(paste("ur_total ~ log_rate +", covs_ph)), d),
  sens_mod("T3c3_phillips_shares", as.formula(paste("ur_men ~ log_rate +", covs_ph)), d),
  sens_mod("T1c1_rain_sum_sepoct", as.formula("rate ~ black_sh + col_sh + ldens + lrail + I(2*rain_so_cm) + region"), d)
) |> filter(term %in% c("black_sh", "black_sh_ph", "log_rate", "lrail", "lrail_all", "rain_so_cm", "I(2 * rain_so_cm)"))
write_csv(sens, file.path(out_dir, "sensitivity.csv"))

# ---------------------------------------------------------------- results_r.csv
term_of <- c("Black" = "black_sh", "Coloured" = "col_sh", "Density" = "ldens", "Rail" = "lrail",
             "Rain" = "rain_so_cm", "Natal" = "regionNatal", "Orange" = "regionOFS",
             "Transkei" = "regionTranskei", "Transvaal" = "regionTransvaal", "Zululand" = "regionZululand",
             "Constant" = "(Intercept)", "Log (Deaths" = "log_rate", "Growing" = NA)
mods <- list(T1 = list(m1, m2, m3, m4), T3 = list(u1, u2, u3))
rows <- list()
for (i in seq_len(nrow(claims))) {
  cl <- claims[i, ]; id <- cl$claim_id
  r <- tibble(claim_id = id, source = "r", value = NA_real_, se = NA_real_, n = NA_real_, status_override = "")
  tab <- str_extract(id, "^T\\d"); col <- as.integer(str_extract(id, "(?<=_c)\\d+$"))
  if (tab %in% c("T1", "T3")) {
    m <- mods[[tab]][[col]]
    if (str_detect(id, "_r\\d+_")) {
      key <- names(term_of)[str_detect(cl$location, fixed(names(term_of)))][1]
      trm <- term_of[[key]]
      ct <- coefs |> filter(table == tab, col == !!col, term == trm)
      r$value <- ct$estimate; r$se <- ct$se_hc2; r$n <- ct$n
    } else if (str_detect(id, "_mean_")) { r$value <- mean(model.frame(m)[[1]]); r$n <- nobs(m)
    } else if (str_detect(id, "_n_"))    { r$value <- nobs(m); r$n <- nobs(m)
    } else if (str_detect(id, "_rsq_"))  { r$value <- summary(m)$r.squared; r$n <- nobs(m)
    } else if (str_detect(id, "_F_"))    { r$value <- fstat(m); r$n <- nobs(m) }
  } else if (tab %in% c("T2", "T4") || str_detect(id, "^F6a")) {
    r$status_override <- "unavailable"
  } else {
    b1 <- coef(m1)[["black_sh"]]; bu <- coef(u1)[["log_rate"]]; bm <- coef(u3)[["log_rate"]]
    r <- switch(id,
      txt_p174_ndistricts = mutate(r, value = aux$n_polygons_1918),
      txt_p174_commission = mutate(r, value = aux$phillips_total_deaths),
      txt_p181_black40    = mutate(r, value = b1, se = coefs$se_hc2[coefs$table == "T1" & coefs$col == 1 & coefs$term == "black_sh"], n = nobs(m1)),
      txt_p189_iqr_p25    = mutate(r, value = unname(quantile(d$rate, .25)), n = nrow(d)),
      txt_p189_iqr_p75    = mutate(r, value = unname(quantile(d$rate, .75)), n = nrow(d)),
      txt_p190_u_total    = mutate(r, value = bu * log(2) * 100, n = nobs(u1)),
      txt_p190_u_men      = mutate(r, value = bm * log(2) * 100, n = nobs(u3)),
      txt_p187_oct460 = , txt_p187_oct25pct = , txt_p187_nwomen = , txt_p188_beta1880 = ,
      txt_p189_iqr_effect = , txt_p191_maize1922 = , txt_p191_maize1922pct = , txt_p191_maize1918 = ,
      txt_p191_maize1937 = , txt_p191_maize1946 = mutate(r, status_override = "unavailable"),
      mutate(r, status_override = "not-attempted"))
  }
  rows[[i]] <- r
}
res <- bind_rows(rows)
stopifnot(nrow(res) == nrow(claims))
write_csv(res, file.path(root, "repro_r", "results_r.csv"), na = "")

# Console comparison snapshot (for the log only; the formal comparison is S4)
print(coefs |> filter(term %in% c("black_sh", "log_rate")) |> mutate(across(where(is.numeric), \(x) round(x, 4))))
cat("N:", nobs(m1), nobs(m3), nobs(u1), " R2:", round(sapply(list(m1, m2, m3, m4, u1, u2, u3), \(m) summary(m)$r.squared), 3), "\n")
