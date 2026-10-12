# P23_MBF S6: Table 5 sensitivities of card §5 (items 16-24). Reported, never verdict-determining.
suppressPackageStartupMessages({
  library(tidyverse); library(haven); library(logistf); library(sandwich); library(arm)
})
root <- "."
source(file.path(root, "tools", "paths.R"))
mod <- file.path(root, "P23_MBF", "modern")
out <- file.path(mod, "output")
source(file.path(mod, "t5_common.R"))
set.seed(20261011)

d <- read_dta(dpath("P23_MBF", "original", "ld", "1_murdockanddbirth_final.dta")) |> zap_labels()
s <- t5_samples(d)
s64 <- s$s64; cc <- s$cc
rows <- list()
add <- function(item, scen, est, se = NA, lo = NA, hi = NA, p = NA, dat = NULL, note = "", extra = list()) {
  rows[[length(rows) + 1]] <<- tibble(item = item, scenario = scen, est = est, se = se, ci_lo = lo, ci_hi = hi, p = p,
                                      N = if (is.null(dat)) NA else nrow(dat), events = if (is.null(dat)) NA else sum(dat$d_birth),
                                      note = note, !!!extra)
}
add_firth <- function(item, scen, f, dat, note = "") {
  o <- firth_pl(f, dat, log_prefix = scen)
  r <- o$res
  add(item, scen, r$beta, r$wald_se, r$ci_lo, r$ci_hi, r$p, dat,
      note = paste0(note, if (note != "") "; " else "", "Firth PL; recovery ", o$recovery,
                    "; converged full/null/lo/hi ", paste(r$conv_full, r$conv_null, r$conv_lo, r$conv_hi, sep = "/")))
  invisible(o)
}

# (16) ML logit on the 64 regions, robust SEs (Stata vce(robust): HC0 x n/(n-1))
ml <- glm(F_C4, binomial, s64, control = glm.control(epsilon = 1e-14, maxit = 200))
V16 <- vcovHC(ml, type = "HC0") * nrow(s64) / (nrow(s64) - 1)
b16 <- coef(ml)[["d_mission"]]; se16 <- sqrt(V16["d_mission", "d_mission"])
add(16, "S16_ML_robust_64", b16, se16, b16 - qnorm(.975) * se16, b16 + qnorm(.975) * se16, 2 * pnorm(-abs(b16 / se16)), s64, "ML logit, robust SE (published inference)")

# (17) Firth with the printed col 1-3 specifications, 64 regions
add_firth(17, "S17_Firth_col1_spec_64", F_C1, s64)
add_firth(17, "S17_Firth_col2_spec_64", F_C2, s64)
add_firth(17, "S17_Firth_col3_spec_64", F_C3, s64, "printed col 3 (A': lat lon coast river tsi + country FE)")

# (18) Firth, surviving-code col 4 specification (without d_capital), 64 regions
add_firth(18, "S18_Firth_no_d_capital_64", F_C4_NOC, s64)

# (19) Bayesian logit, frozen prior (Gelman et al. 2008)
bg <- bayesglm(F_C4, family = binomial(link = "logit"), data = s64, prior.mean = 0, prior.scale = 2.5, prior.df = 1,
               prior.mean.for.intercept = 0, prior.scale.for.intercept = 10, prior.df.for.intercept = 1, scaled = TRUE)
b19 <- coef(bg)[["d_mission"]]; se19 <- sqrt(vcov(bg)["d_mission", "d_mission"])
add(19, "S19_bayesglm_64", b19, se19, b19 - qnorm(.975) * se19, b19 + qnorm(.975) * se19, 2 * pnorm(-abs(b19 / se19)), s64,
    "posterior mode and SE; interval and p are normal approximations, reported only")

# (20) Firth on all complete-case regions (changed population)
add_firth(20, "S20_Firth_all_complete_cases", F_C4, cc, "changed population (A4d)")

# (21) LPM with HC3 SEs, 64 and all complete cases
for (nm in c("64", "cc")) {
  dat <- if (nm == "64") s64 else cc
  lp <- lm(F_C4, data = dat)
  V <- vcovHC(lp, type = "HC3")
  b <- coef(lp)[["d_mission"]]; se <- sqrt(V["d_mission", "d_mission"])
  dfr <- df.residual(lp)
  add(21, paste0("S21_LPM_HC3_", ifelse(nm == "64", "64", "all_complete_cases")), b, se, b - qt(.975, dfr) * se, b + qt(.975, dfr) * se,
      2 * pt(-abs(b / se), dfr), dat, "probability scale (pp per unit), t reference")
}

# (22) leave-one-country-out with Firth (countries with an event), A4d
prim <- read_csv(file.path(out, "t5_primary_raw.csv"), show_col_types = FALSE)
v_or0 <- verdict_h3or(prim$beta, prim$plr_p, prim$pl_ci_lo, prim$pl_ci_hi)[1]
v_p0 <- verdict_h3p(prim$beta, prim$plr_p)[1]
ev_c <- s64 |> group_by(iso2) |> summarise(ev = sum(d_birth)) |> filter(ev > 0) |> pull(iso2)
for (c in ev_c) {
  dat <- s64 |> filter(iso2 != c)
  o <- firth_pl(F_C4, dat, log_prefix = paste0("loco_", c))
  r <- o$res
  sup_or <- r$conv_full && r$conv_null && r$conv_lo && r$conv_hi
  sup_p <- r$conv_full && r$conv_null
  vor <- verdict_h3or(r$beta, r$p, r$ci_lo, r$ci_hi, sup_or)
  vp <- verdict_h3p(r$beta, r$p, sup_p)
  add(22, paste0("S22_LOCO_drop_iso2_", c), r$beta, r$wald_se, r$ci_lo, r$ci_hi, r$p, dat,
      paste0("recovery ", o$recovery),
      extra = list(verdict_H3OR = vor[1], rule_H3OR = vor[2], verdict_H3P = vp[1], rule_H3P = vp[2],
                   meets_confirm_H3OR = r$beta > 0 && r$p < .05 && r$beta >= 4.55, meets_confirm_H3P = r$beta > 0 && r$p < .05,
                   changes_H3OR = vor[1] != v_or0, changes_H3P = vp[1] != v_p0))
}

# (23) d_mission missing treated as missing (C4): raw GIS file, merged by polygon id; complete cases of the 64 regions
raw <- read_csv(dpath("P23_MBF", "original", "ld", "1_murdock_capital_population_final.csv"), show_col_types = FALSE,
                col_select = c("FID", "NAME", "d_mission"), name_repair = "minimal")
raw <- raw |> mutate(d_mission_raw = ifelse(is.na(d_mission), NA_real_, pmin(d_mission, 1))) |> dplyr::select(FID, d_mission_raw) |> distinct()
stopifnot(!anyDuplicated(raw$FID))
s23 <- s64 |> left_join(raw, by = c("fid" = "FID"))
cat("S23: matched", sum(!is.na(match(s64$fid, raw$FID))), "of", nrow(s64), "; raw d_mission missing", sum(is.na(s23$d_mission_raw)), "\n")
cat("S23 check: recoded raw equals analysis d_mission where raw non-missing:", all(s23$d_mission_raw[!is.na(s23$d_mission_raw)] == s23$d_mission[!is.na(s23$d_mission_raw)]), "\n")
s23 <- s23 |> filter(!is.na(d_mission_raw))
if (n_distinct(s23$d_mission) < 2) {
  add(23, "S23_Firth_mission_missing_as_missing", NA, dat = s23,
      note = paste0("not estimable: the raw GIS file records mission counts >= 1 and no zeros, so once missing is treated as missing every remaining region has d_mission = 1 (",
                    nrow(s23), " of 64 regions)"))
} else {
  add_firth(23, "S23_Firth_mission_missing_as_missing", F_C4, s23, "complete cases of the 64 regions after treating missing d_mission as missing; changed population (A4d)")
}

# (24) regions in the 11 countries of Table 1
s24 <- s64 |> filter(iso2 %in% TABLE1_ISO)
add_firth(24, "S24_Firth_Table1_countries", F_C4, s24, "64 regions restricted to the 11 countries of Table 1; changed population (A4d)")

res <- bind_rows(rows)
write_csv(res, file.path(out, "t5_sensitivities_raw.csv"))
print(res |> dplyr::select(scenario, est, ci_lo, ci_hi, p, N, events), n = 50, width = 200)
