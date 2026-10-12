# P10_FI S5: decompose pair-B (independent R rebuild) gaps for the headline Table 3 coefficients.
# Run from project root: Rscript P10_FI/compare/s5_checks/s5_pairB_decomp.R
# Uses the S3 cleaned file on D: (read-only). Writes aggregate coefficients only.
suppressPackageStartupMessages({library(dplyr); library(tidyr); library(sandwich); library(data.table)})
source(file.path("tools", "paths.R"))
d_all <- readRDS(dscratch("P10_FI", "repro_r", "p10_clean.rds"))
s <- d_all %>% filter(sample)
x1 <- c("m_white", "m_black", "f_white", "f_black", "m_age", "f_age", "act", "segregation", "lit_gap")
x2 <- c(x1, "widower", "m_divorcee", "widow", "f_divorcee")
x3 <- c(x2[1:7], "sexratio", x2[8:13], "m_foreign", "f_foreign")
x4 <- c(x3, "m_manager", "m_sales", "f_manager", "f_sales")
fit <- function(x, data, lbl, spec) {
  dd <- data %>% drop_na(all_of(c(x, "month_f", "parish", "year"))) %>% droplevels()
  m <- lm(as.formula(paste("interracial ~", paste(x, collapse = " + "), "+ year + month_f + parish")), data = dd)
  V <- vcovCL(m, cluster = dd$parish, type = "HC1")
  data.frame(step = lbl, spec = spec, term = c("act", "segregation"), coef = coef(m)[c("act", "segregation")],
             se_iid = sqrt(diag(vcov(m)))[c("act", "segregation")], se_parishCL = sqrt(diag(V))[c("act", "segregation")], n = nobs(m))
}
un <- c(555, 557, 565, 566, 568, 569)
s1 <- s %>% filter(!parish %in% un)
s2 <- s1 %>% mutate(lit_gap = lit_diff)                       # signed literacy difference, as in original dlit
s3 <- s2 %>% mutate(segregation = segregation_h)              # husbands-only HHI, as in original
s4 <- s3 %>% filter(year <= 1960)
steps <- list(`B as built (all 46 parishes)` = s, `B excl. pid 557 only` = s %>% filter(parish != 557),
              `B excl. six unmapped parishes` = s1, `+ signed literacy diff` = s2,
              `+ husbands-only segregation` = s3, `+ years <= 1960` = s4)
res <- list()
for (nm in names(steps)) for (sp in c("c2", "c3", "c4")) {
  x <- switch(sp, c2 = x2, c3 = x3, c4 = x4)
  res[[length(res) + 1]] <- fit(x, steps[[nm]], nm, sp)
}
res <- rbindlist(res)
fwrite(res, file.path("P10_FI", "compare", "s5_checks", "s5_pairB_decomp.csv"))
print(res[, .(step, spec, term, coef = signif(coef, 3), se_iid = signif(se_iid, 2), se_parishCL = signif(se_parishCL, 2), n)])
