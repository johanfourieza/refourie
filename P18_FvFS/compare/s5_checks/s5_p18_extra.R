# S5 extra checks P18: star changes under surname clustering; slaves per member; PPML variants
suppressPackageStartupMessages({library(haven); library(fixest); library(dplyr)})
root <- "./P18_FvFS"; source("./tools/paths.R")
d <- read_dta(dpath("P18_FvFS", "repro_original/extracted/results/exclpc/final_excl_1.dta")) |> zap_labels() |>
  filter(year >= 1700, year != 1716) |>
  mutate(vpc = vines_planted / hhsize, spc = total_slaves / hhsize, g = factor(group), dist = factor(district),
         yr = factor(year), mar = factor(marital), sur = toupper(trimws(surname)))
F <- "firstarrivals + i(dist, ref = 1) + i(yr)"
st <- function(p) ifelse(p < .01, "***", ifelse(p < .05, "**", ifelse(p < .1, "*", "")))
specs <- list(
  T3c1 = list("l_wine_zero", "i(g, ref=1)", d), T3c2 = list("l_wine_zero", "i(g, ref=1) + total_slaves + knechts", d),
  T3c3 = list("l_wine_zero", "i(g, ref=1) + total_slaves + knechts + cattle + horses + vpc + i(mar, ref=0)", d),
  T3c4 = list("l_wine_zero", "i(g, ref=1) + total_slaves + knechts + cattle + horses + vpc + i(mar, ref=0) + wheat_reaped", d),
  T4c5 = list("l_wine_zero", "i(g, ref=2)", d[d$group > 1, ]), T4c6 = list("l_wine_zero", "i(g, ref=2) + total_slaves + knechts", d[d$group > 1, ]),
  T4c7 = list("l_wine_zero", "i(g, ref=2) + total_slaves + knechts + cattle + horses + vpc + i(mar, ref=0)", d[d$group > 1, ]),
  T5c11 = list("l_wheat_reaped_zero", "i(g, ref=1)", d), T5c12 = list("l_wheat_reaped_zero", "i(g, ref=1) + total_slaves + knechts", d),
  T5c13 = list("l_wheat_reaped_zero", "i(g, ref=1) + total_slaves + knechts + cattle + horses", d),
  T5c14 = list("l_wheat_reaped_zero", "i(g, ref=1) + total_slaves + knechts + cattle + horses + i(mar, ref=0)", d),
  T5c15 = list("l_wheat_reaped_zero", "i(g, ref=1) + total_slaves + knechts + cattle + horses + i(mar, ref=0) + wheat_sown", d))
rows <- list()
for (nm in names(specs)) { s <- specs[[nm]]
  m <- feols(as.formula(paste(s[[1]], "~", s[[2]], "+", F)), s[[3]], weights = ~hhsize, vcov = "hetero")
  mc <- summary(m, vcov = ~sur); mu <- feols(as.formula(paste(s[[1]], "~", s[[2]], "+", F)), s[[3]], vcov = ~sur)
  for (t in grep("^g::", names(coef(m)), value = TRUE))
    rows[[length(rows) + 1]] <- data.frame(spec = nm, term = t, b = round(coef(m)[t], 3), se_hc1 = round(se(m)[t], 3),
      star_hc1 = st(pvalue(m)[t]), se_cl_sur = round(se(mc)[t], 3), star_cl_sur = st(pvalue(mc)[t]),
      b_unw = round(coef(mu)[t], 3), star_unw_cl_sur = st(pvalue(mu)[t])) }
r <- do.call(rbind, rows); print(r, row.names = FALSE)
write.csv(r, file.path(root, "compare/s5_checks/s5_p18_cluster_stars.csv"), row.names = FALSE)
# slaves per member (consistent units)
m <- feols(as.formula(paste("l_wine_zero ~ i(g, ref=1) + spc + knechts + cattle + horses + vpc + i(mar, ref=0) + wheat_reaped +", F)), d, weights = ~hhsize, vcov = "hetero")
cat("T3c4 with slaves per member: WH", round(coef(m)["g::3"], 4), "se", round(se(m)["g::3"], 4), "\n")
m <- feols(as.formula(paste("l_wine_zero ~ i(g, ref=2) + spc + knechts + cattle + horses + vpc + i(mar, ref=0) +", F)), d[d$group > 1, ], weights = ~hhsize, vcov = "hetero")
cat("T4c7 with slaves per member: WH", round(coef(m)["g::3"], 4), "se", round(se(m)["g::3"], 4), "\n")
# no input controls at all except FE (T3 spec 1 analogue) vs post-treatment: drop vines
m <- feols(as.formula(paste("l_wine_zero ~ i(g, ref=2) + total_slaves + knechts + cattle + horses + i(mar, ref=0) +", F)), d[d$group > 1, ], weights = ~hhsize, vcov = "hetero")
cat("T4c7 without vines: WH", round(coef(m)["g::3"], 4), "\n")
m <- feols(as.formula(paste("l_wine_zero ~ i(g, ref=2) + total_slaves + knechts + cattle + horses + vpc +", F)), d[d$group > 1, ], weights = ~hhsize, vcov = "hetero")
cat("T4c7 without marital dummies: WH", round(coef(m)["g::3"], 4), "\n")
# PPML variants with surname clustering
for (sp in c("T3c4", "T4c7")) {
  s <- specs[[sp]]
  for (w in c(TRUE, FALSE)) {
    m <- fepois(as.formula(paste("wine ~", s[[2]], "+", F)), s[[3]], weights = if (w) ~hhsize else NULL, vcov = ~sur)
    cat(sp, "PPML weighted =", w, ": WH", round(coef(m)["g::3"], 4), "se(cl sur)", round(se(m)["g::3"], 4),
        "p", signif(pvalue(m)["g::3"], 3), " exp-1 =", round(100 * (exp(coef(m)["g::3"]) - 1), 1), "%\n") } }
# extensive margin, clustered
for (sp in c("T3c4", "T4c7")) { s <- specs[[sp]]; s[[3]]$any <- as.numeric(s[[3]]$wine > 0)
  m <- feols(as.formula(paste("any ~", s[[2]], "+", F)), s[[3]], weights = ~hhsize, vcov = ~sur)
  cat(sp, "LPM any wine: WH", round(coef(m)["g::3"], 4), "se", round(se(m)["g::3"], 4), "\n")
  s[[3]]$lp <- ifelse(s[[3]]$wine > 0, log(s[[3]]$wine), NA)
  m <- feols(as.formula(paste("lp ~", s[[2]], "+", F)), s[[3]], weights = ~hhsize, vcov = ~sur)
  cat(sp, "intensive: WH", round(coef(m)["g::3"], 4), "se", round(se(m)["g::3"], 4), "N", nobs(m), "\n") }
# share of the log coefficient that is the extensive margin: 6.908 * LPM approx
