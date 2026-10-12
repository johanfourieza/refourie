# P04_CF  S6 modern reanalysis, step 3: admissible sensitivities (method card §5; reported, never verdict-setting, A4d).
#   S1a grazier correction only; S1b century correction only;
#   S2  both corrections, one record of each duplicate pair dropped (key as in s5_duplicates.R / s5_clusters.R);
#   S3  order-free class: highest class on Farmer < Unskilled < Semi/skilled < White collar (changes the definition);
#   S4  both corrections, 1910 births included;
#   S5  migrant (I3) in Models 2 and 3, OR and RR, primary sample;
#   S6  diagnostic only: original (2016-file) occupational coding with the primary sample, shares and inference.
# Every bootstrap uses the primary inference (B = 4,999, nested 199, seed 20261011). CIs are Bonferroni (1 - 0.05/6),
# as in the primary; p_raw unadjusted; p_holm_within = Holm over the six claims within the sensitivity.
# Outputs: output/sensitivities.csv; appends rows to output/cluster_diagnostics.csv and output/bootstrap_failures.csv.
args_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- if (length(args_file)) normalizePath(file.path(dirname(args_file), "..")) else
  "./P04_CF"
source(file.path(root, "modern", "00_functions.R"))
out <- file.path(root, "modern", "output")
B_RUN <- as.integer(Sys.getenv("P04_B", B_OUT)); B_IN_RUN <- as.integer(Sys.getenv("P04_BIN", B_IN))
source(file.path(dirname(root), "tools", "paths.R"))  # [A6] data root on D:
d <- readRDS(dscratch("P04_CF", "modern", "analysis.rds"))

variants <- list(
  S1a_grazier_only   = list(coding = "grazier", desc = "grazier -> Farmer only (century kept as White collar)"),
  S1b_century_only   = list(coding = "century", desc = "century removed only (grazier kept as Unskilled)"),
  S2_dedup           = list(coding = "both", drop_dups = TRUE, desc = "both corrections; second record of 159 duplicate pairs dropped"),
  S3_highest_class   = list(coding = "highest_both", desc = "both corrections; highest class (F < U < S < W), not last listed: different definition"),
  S4_with_1910       = list(coding = "both", include1910 = TRUE, desc = "both corrections; 106 sons born 1910 included"),
  S6_original_coding = list(coding = "orig2016", desc = "DIAGNOSTIC: 2016-file (published) coding, primary sample/shares/inference"))

sens <- list(); cdiag <- list(); fails <- list()
for (nm in names(variants)) {
  v <- variants[[nm]]
  x <- prep(d, v$coding, include1910 = isTRUE(v$include1910), drop_dups = isTRUE(v$drop_dups))
  cat(nm, ": N =", nrow(x), " clusters =", n_distinct(x$clus), "\n")
  r <- run_claims(x, nm, B = B_RUN, B_in = B_IN_RUN)
  sens[[nm]] <- bind_rows(
    r$res |> transmute(sensitivity = nm, description = v$desc, claim, estimate, se, ci_lo, ci_hi, p_raw, p_holm_within = p_holm,
                       n_obs, n_clusters, B_used),
    r$extra |> transmute(sensitivity = nm, description = v$desc, claim = paste("component:", quantity), estimate = value))
  cdiag[[nm]] <- cluster_diag(x, nm); fails[[nm]] <- r$fails
}
# S5: migrant father in Models 2 and 3 (primary sample; CR1)
x <- prep(d, "both")
s5 <- bind_rows(lapply(list(c(2, "OR"), c(2, "RR"), c(3, "OR"), c(3, "RR")), function(m) {
  fit_reg(x, as.integer(m[1]), m[2], "I(f_gen == 1)TRUE") |>
    transmute(sensitivity = "S5_migrant_models_2_3", description = "migrant father in Models 2 (+ father class) and 3 (+ share + father class)",
              claim = paste0("I3-", m[2], " Model ", m[1]), estimate, se, ci_lo, ci_hi, p_raw, p_holm_within = NA, n_obs, n_clusters, B_used)
}))
S <- bind_rows(c(sens, list(s5)))
S$exp_estimate <- ifelse(grepl("-(OR|RR)", S$claim), exp(S$estimate), NA)
write.csv(S, file.path(out, "sensitivities.csv"), row.names = FALSE)

cd0 <- read.csv(file.path(out, "cluster_diagnostics.csv")) |> filter(sample == "primary")
write.csv(bind_rows(cd0, bind_rows(cdiag)), file.path(out, "cluster_diagnostics.csv"), row.names = FALSE)
bf0 <- read.csv(file.path(out, "bootstrap_failures.csv")) |> filter(sample == "primary")
write.csv(bind_rows(bf0, bind_rows(fails)), file.path(out, "bootstrap_failures.csv"), row.names = FALSE)
print(S |> filter(!grepl("component", claim)) |> select(sensitivity, claim, estimate, ci_lo, ci_hi, p_raw) |>
        mutate(across(where(is.numeric), ~ signif(.x, 4))))
