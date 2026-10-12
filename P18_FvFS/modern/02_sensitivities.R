# P18_FvFS S6 - 02_sensitivities.R: the eight admissible sensitivities of method card s5 (exhaustive).
# None changes the verdict (card s5). Unadjusted 95% intervals; theta = exp(b) - 1 for log-link/log-outcome rows.
source("./P18_FvFS/modern/00_data.R")
suppressPackageStartupMessages(library(fwildclusterboot))
set.seed(SEED); dqrng::dqset.seed(SEED)

row_of <- function(claim_id, sid, label, m, scale = c("log", "level"), vlab, extra = list()) {
  scale <- match.arg(scale)
  b <- unname(coef(m)[WH]); se <- unname(se(m)[WH]); p <- unname(pvalue(m)[WH])
  ci <- unname(unlist(confint(m)[WH, ]))   # fixest default: normal for fepois, t(G-1) for clustered feols
  if (scale == "log") { th <- exp(b) - 1; lo <- exp(ci[1]) - 1; hi <- exp(ci[2]) - 1 }
  else { th <- NA_real_; lo <- ci[1]; hi <- ci[2] }
  tibble(claim_id, sens_id = sid, label, estimator = m$method, b, se, p, theta = th, ci95_lo = lo, ci95_hi = hi,
         N = nobs(m), vcov = vlab, boot_p = NA_real_, boot_ci_lo = NA_real_, boot_ci_hi = NA_real_) |>
    mutate(!!!extra)
}
ppml <- function(sp, data = d, w = TRUE, xset = "pub", vc = ~sur, y = "wine", offset = NULL)
  fepois(as.formula(paste(y, "~", rhs_of(sp, xset))), sample_of(sp, data), weights = if (w) ~hhsize else NULL,
         offset = offset, vcov = vc)

# exact duplicates: identical on every variable of the analysis file
orig_vars <- names(read_dta(dpath("P18_FvFS", "repro_original/extracted/results/exclpc/final_excl_1.dta"), n_max = 0))
d_dedup <- d[!duplicated(d[, orig_vars]), ]
cat("exact duplicate rows dropped:", nrow(d) - nrow(d_dedup), "\n")

out <- list(); add <- function(x) out[[length(out) + 1]] <<- x
for (i in seq_len(nrow(claims))) {
  cid <- claims$claim_id[i]; sp <- claims$spec[i]
  # S1 unweighted PPML
  add(row_of(cid, "S1", "Unweighted PPML", ppml(sp, w = FALSE), "log", "CR1 surname"))
  # S2 exposure model: household-total wine, offset ln(hhsize), no weights
  add(row_of(cid, "S2", "Exposure: household wine, offset ln(hhsize), unweighted",
             ppml(sp, w = FALSE, y = "wine_hh", offset = ~log(hhsize)), "log", "CR1 surname"))
  # S3 consistent input units (not applicable to c10: no inputs)
  if (sp != "c10") {
    add(row_of(cid, "S3a", "All inputs per household, weighted", ppml(sp, xset = "hh"), "log", "CR1 surname"))
    add(row_of(cid, "S3b", "All inputs per household, unweighted", ppml(sp, xset = "hh", w = FALSE), "log", "CR1 surname"))
    add(row_of(cid, "S3c", "All inputs per member, weighted", ppml(sp, xset = "pm"), "log", "CR1 surname"))
    add(row_of(cid, "S3d", "All inputs per member, unweighted", ppml(sp, xset = "pm", w = FALSE), "log", "CR1 surname"))
  }
  # S4 extensive margin: LPM of 1[wine > 0], CR1 surname + WCR bootstrap (Webb, 9,999)
  m <- feols(as.formula(paste("anywine ~", rhs_of(sp))), sample_of(sp), weights = ~hhsize, vcov = ~sur)
  bt <- boottest(m, param = WH, clustid = "sur", B = 9999, type = "webb", sign_level = 0.05)
  r <- row_of(cid, "S4", "Extensive margin: LPM 1[wine > 0] (descriptive)", m, "level", "CR1 surname; WCR Webb B = 9,999")
  r$boot_p <- pval(bt); r$boot_ci_lo <- confint(bt)[1]; r$boot_ci_hi <- confint(bt)[2]; add(r)
  # S5 intensive margin: OLS ln(wine per member) among producers (selected sample, descriptive)
  add(row_of(cid, "S5", "Intensive margin: OLS ln(wine) | wine > 0 (descriptive)",
             feols(as.formula(paste("lpos ~", rhs_of(sp))), sample_of(sp), weights = ~hhsize, vcov = ~sur), "log", "CR1 surname"))
  # S6 drop household-choice controls (vines, marital dummies, slaves): changes the conditioning set
  if (sp != "c10")
    add(row_of(cid, "S6", "Drop household-choice controls (vines, marital, slaves) [different conditioning set]",
               ppml(sp, xset = "nochoice"), "log", "CR1 surname"))
  # S7 drop exact duplicate records
  add(row_of(cid, "S7", "Drop exact duplicate records", ppml(sp, data = d_dedup), "log", "CR1 surname"))
  # S8 clustering alternatives
  s <- sample_of(sp)
  add(row_of(cid, "S8a", "Two-way cluster: surname and district x decade", ppml(sp, vc = ~sur + dist_dec), "log",
             sprintf("CR1 two-way (%d district x decade cells)", n_distinct(s$dist_dec))))
  add(row_of(cid, "S8b", "One-way cluster: district x decade (few clusters)", ppml(sp, vc = ~dist_dec), "log",
             sprintf("CR1 district x decade (G = %d; few-cluster caveat)", n_distinct(s$dist_dec))))
}
sens <- bind_rows(out)
write_csv(sens, file.path(od, "sensitivities.csv"))
print(as.data.frame(sens |> select(claim_id, sens_id, b, se, p, theta, ci95_lo, ci95_hi, N, boot_p, boot_ci_lo, boot_ci_hi)), digits = 3)
