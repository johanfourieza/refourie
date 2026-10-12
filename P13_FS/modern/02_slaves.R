# P13_FS S6 02_slaves.R -- H2-mag primary (card section 4B): OLS reconstruction of the Table 6 Panel A "Tobit" on the
# authors' stored sample (_est_tobit1 == 1) restricted to positive economic debt, y = log(D_noinh), HC3 inference.
# Dependent-variable construction copied from compare/s5_checks/s5_03_depvar.R; covariates from s5_09_t6_effects.R.
suppressMessages({library(haven); library(dplyr); library(readr); library(sandwich); library(lmtest)})
source(here::here("tools", "paths.R"))
od <- dpath("P13_FS", "original", "MOOC 8"); scr <- dscratch("P13_FS", "modern"); out <- here::here("P13_FS", "modern", "output")
a <- zap_labels(read_dta(file.path(od, "DATA20141122.dta"))); a <- a[!is.na(a$household_iden), ]
p <- zap_labels(read_dta(file.path(od, "PURPOSEDATA_20141117.dta")))
stopifnot(!anyDuplicated(a$mooc))                                               # rule 2
U <- p[!is.na(p$value_debt) | !(p$purpose_debt %in% c(".", "")), ]
inh <- U$purpose_debt == "Inheritance"
dv <- U |> mutate(inh = inh) |> group_by(mooc) |>
  summarise(n_noinh = sum(!inh), n_noinh_val = sum(!inh & !is.na(value_debt)),
            D_noinh = sum(value_debt[!inh & !is.na(value_debt)]), D_inh = sum(value_debt[inh & !is.na(value_debt)]),
            D_all = sum(value_debt, na.rm = TRUE), n_inh = sum(inh), .groups = "drop")
stopifnot(isTRUE(all.equal(dv$D_noinh + dv$D_inh, dv$D_all)))                  # rule 4
a <- left_join(a, dv, by = "mooc")                                              # many-to-one: one dv row per mooc
a$male <- as.numeric(a$gender == "m")
a$dec <- factor(floor(suppressWarnings(as.numeric(a$year_string)) / 10) * 10)
a$dec_y <- factor(floor(a$year / 10) * 10)
a$status <- with(a, case_when(is.na(n_noinh) ~ "no U rows", n_noinh == 0 ~ "inheritance-only", n_noinh_val == 0 ~ "D-missing",
                              D_noinh == 0 ~ "genuine zero", TRUE ~ "positive"))
a$y <- ifelse(a$status == "positive", log(a$D_noinh), NA)
s570 <- a$`_est_tobit1` == 1 & !is.na(a$`_est_tobit1`)
XS <- c("age", "male", "married", "children", "farmer", "num_slaves", "num_prop", "cash1", "bond1", "both", "comp", "church", "wees", "dec")
fml <- function(y, xs = XS) as.formula(paste(y, "~", paste(xs, collapse = " + ")))
# ---- verification checks (S5 reproductions) ----
v1 <- lm(fml("ldebt"), data = droplevels(a[s570, ]))
xs_s3 <- replace(replace(XS, XS == "bond1", "bond"), XS == "dec", "dec_y")
d2 <- droplevels(a[s570 & is.finite(log(a$D_noinh)) & a$D_noinh > 0, ]); v2 <- lm(fml("log(D_noinh)", xs_s3), data = d2)
r_s3 <- read_csv(here::here("P13_FS", "repro_r", "results_r.csv"), show_col_types = FALSE)
ver <- tibble(check = c("stored 570, ldebt, bond1/year_string: slaves = 0.0826", "  conventional t = 8.65", "  HC1 t = 7.12", "  N = 570",
                        "inheritance excluded, bond/year decades: slaves = 0.0712", "  N = 564", "S3 rebuild locked Tobit slaves = 0.0454"),
              target = c(0.0826, 8.65, 7.12, 570, 0.0712, 564, 0.0454),
              got = c(coef(v1)["num_slaves"], coef(summary(v1))["num_slaves", 3], coeftest(v1, vcovHC(v1, "HC1"))["num_slaves", 3], nobs(v1),
                      coef(v2)["num_slaves"], nobs(v2), r_s3$value[r_s3$claim_id == "T6A_slaves_nom_coef"])) |>
  mutate(pass = abs(got - target) <= ifelse(target > 100, 0.5, 0.006))
print(ver); write_csv(ver, file.path(out, "verification_H2.csv"))
# ---- sample S_A and counts (rule 1) ----
cnt570 <- as.data.frame(table(a$status[s570])); names(cnt570) <- c("status", "n_in_570")
dropped <- a |> filter(s570, status != "positive") |> select(mooc, status, debt_value, D_all, D_inh)
SA <- s570 & a$status == "positive"
d <- droplevels(a[SA, c("mooc", "household_iden", "y", "D_noinh", "debt_value", "D_all", XS, "dec_y", "bond", "year", "year_string")])
d <- d[complete.cases(d[, c("y", XS)]), ]
m <- lm(fml("y"), data = d)
h <- hatvalues(m); k <- length(coef(m)); n <- nobs(m); dfr <- df.residual(m)
fail <- any(abs(h - 1) < 1e-8) || any(is.na(coef(m)[c("num_slaves")]))
V3 <- vcovHC(m, type = "HC3"); se3 <- sqrt(V3["num_slaves", "num_slaves"])
fail <- fail || !is.finite(se3) || se3 == 0
b <- unname(coef(m)["num_slaves"]); tt <- b / se3; pv <- 2 * pt(-abs(tt), dfr); cr <- qt(0.9875, dfr)
ci <- c(b - cr * se3, b + cr * se3)
v_h2 <- if (fail) "not-testable" else if (b < 0 && pv < 0.025) "overturned" else if (ci[1] > -0.0435 && ci[2] < 0.0435) "overturned" else
  if (b > 0 && pv < 0.025 && b >= 0.0435) "confirmed" else if (b > 0 && pv < 0.025) "qualified" else "weakened"
rule_h2 <- if (fail) 0 else if (b < 0 && pv < 0.025) 1 else if (ci[1] > -0.0435 && ci[2] < 0.0435) 2 else if (b > 0 && pv < 0.025 && b >= 0.0435) 3 else
  if (b > 0 && pv < 0.025) 4 else if (b > 0) 5 else 6
tc <- coef(summary(m))["num_slaves", 3]; t1 <- b / sqrt(vcovHC(m, "HC1")["num_slaves", "num_slaves"])
smallcells <- names(which(table(d$dec) < 5))
prim <- tibble(row = "H2-mag", estimand = "OLS reconstruction, y = log(D_noinh), stored 570 sample with positive economic debt",
               b = b, se_hc3 = se3, t_hc3 = tt, p = pv, ci_lo = ci[1], ci_hi = ci[2], df = dfr, N = n, k = k,
               t_conv = tc, t_hc1 = t1, max_leverage = max(h), n_y_le0 = sum(d$y <= 0), small_decade_cells = paste(smallcells, collapse = ";"),
               n_dropped_from_570 = sum(s570) - n, plaus_flag_gt_0.1305 = b > 0.1305, verdict = v_h2, rule = rule_h2)
print(as.data.frame(prim)); print(cnt570); print(dropped)
write_csv(prim, file.path(out, "H2_primary.csv")); write_csv(cnt570, file.path(out, "H2_sample_counts.csv")); write_csv(dropped, file.path(out, "H2_dropped_from_570.csv"))
saveRDS(list(a = a, d = d, m = m, s570 = s570, XS = XS, prim = prim), file.path(scr, "h2.rds"))
