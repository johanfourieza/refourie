# P04_CF  S6 modern reanalysis, step 2: primary pipeline (method card §3-§4, §7-§8; frozen at 3c01885).
#   Sample: sons born 1800-1909, both corrections (grazier -> Farmer, century removed), codable son and father class.
#   I1 Delta = d(P,I) - d(Q,I) and I4 D (Gold minus Slavery marginal-adjusted farmer->farmer %): father-cluster
#   bootstrap, B = 4,999, nested 199, studentised percentile-t, seed 20261011 (L'Ecuyer-CMRG stream per outer draw).
#   I2 (Model 3, Gold) and I3 (Model 1, migrant father): logit ln OR and modified-Poisson ln RR, father CR1.
#   Holm over six tests; I4 tested by TOST against +/-5 pp; CIs Bonferroni (1 - 0.05/6).
# Outputs: output/primary.csv, output/verdict.csv, output/cluster_diagnostics.csv (primary rows),
#          output/bootstrap_failures.csv (primary rows), output/validation.csv. Aggregates only.
args_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- if (length(args_file)) normalizePath(file.path(dirname(args_file), "..")) else
  "./P04_CF"
source(file.path(root, "modern", "00_functions.R"))
out <- file.path(root, "modern", "output")
B_RUN <- as.integer(Sys.getenv("P04_B", B_OUT)); B_IN_RUN <- as.integer(Sys.getenv("P04_BIN", B_IN))
source(file.path(dirname(root), "tools", "paths.R"))  # [A6] data root on D:
d <- readRDS(dscratch("P04_CF", "modern", "analysis.rds"))

## ---- validation of the engine against the original algorithm (do-file l.184-251) ----
pH <- c(432, 286, 104, 55, 257, 2170, 147, 223, 70, 143, 139, 33, 35, 209, 30, 137)
qH <- c(684, 614, 176, 86, 270, 2187, 92, 189, 126, 244, 132, 45, 17, 100, 7, 55)
lmd <- function(y) { F <- factor(rep(1:4, 4)); S <- factor(rep(1:4, each = 4)); sqrt(sum(resid(lm(y ~ F + S))^2) * 64) }
pa_h <- point_altham(c(pH, qH, rep(1, 32)))
x16 <- prep(d, "orig2016", include1910 = TRUE)
st16 <- stats64(colSums(cell_matrix(x16)))
val <- data.frame(check = c("d(P,I) hard-coded, closed form", "d(P,I) hard-coded, lm (do-file)", "d(Q,I) hard-coded, closed form",
                            "d(P,Q) hard-coded", "d(P,Q) G2 p hard-coded", "2016 file: d(P,I)", "2016 file: d(Q,I)",
                            "2016 file: T9 Slavery F->F", "2016 file: T9 Gold F->F (raked)", "2016 file N"),
                  value = c(dfun(matrix(pH, 4)), lmd(log(pH)), dfun(matrix(qH, 4)), pa_h[["dpq"]], pa_h[["g2_p"]],
                            st16[["dpi"]], st16[["dqi"]], st16[["slav_ff"]], st16[["gold_ff"]], nrow(x16)),
                  target = c(19.2079, 19.2079, 18.7846, 3.7030, 0.0662, 19.2079, 18.7846, 78.1358, 77.7322, 9494))
val$pass <- abs(val$value - val$target) < 1e-3 * pmax(1, abs(val$target))
fr <- fit_reg(x16 |> mutate(share_num = d$share_label_code[match(x16$id, d$id)]), 3, "OR")
fr1 <- fit_reg(x16, 1, "OR", "I(f_gen == 1)TRUE")
val <- rbind(val, data.frame(check = c("2016 file: Gold OR Model 3 (share as label code)", "2016 file: migrant OR Model 1"),
                             value = c(exp(fr$estimate), exp(fr1$estimate)), target = c(1.3030, 1.4974),
                             pass = c(abs(exp(fr$estimate) - 1.3030) < 1e-3, abs(exp(fr1$estimate) - 1.4974) < 1e-3)))
print(val); stopifnot(all(val$pass))
write.csv(val, file.path(out, "validation.csv"), row.names = FALSE)

## ---- primary ----
x <- prep(d, "both")
cat("primary N =", nrow(x), " clusters =", n_distinct(x$clus), " B =", B_RUN, " nested =", B_IN_RUN, "\n")
r <- run_claims(x, "primary", B = B_RUN, B_in = B_IN_RUN)
pr <- r$res |> mutate(scale = c("Altham Delta", "ln OR", "ln RR", "ln OR", "ln RR", "pp"),
                      model = c("d(P,I) - d(Q,I)", "logit Model 3, Gold vs Slavery", "modified Poisson Model 3, Gold vs Slavery",
                                "logit Model 1, migrant father", "modified Poisson Model 1, migrant father",
                                "Gold minus Slavery farmer->farmer %, Gold raked to Slavery margins"),
                      inference = c("cluster bootstrap percentile-t", "CR1 father", "CR1 father", "CR1 father", "CR1 father",
                                    "cluster bootstrap percentile-t; p_raw = TOST +/-5 pp"),
                      exp_estimate = ifelse(scale %in% c("ln OR", "ln RR"), exp(estimate), NA),
                      b0 = B0[claim], threshold = THR[claim])
write.csv(pr, file.path(out, "primary.csv"), row.names = FALSE)
write.csv(r$extra, file.path(out, "primary_components.csv"), row.names = FALSE)

vd <- do.call(rbind, lapply(seq_len(nrow(pr)), function(i) {
  v <- verdict_row(pr$claim[i], pr$estimate[i], pr$ci_lo[i], pr$ci_hi[i], pr$p_holm[i])
  data.frame(claim = pr$claim[i], estimate = round(pr$estimate[i], 3), ci_lo = round(pr$ci_lo[i], 3), ci_hi = round(pr$ci_hi[i], 3),
             p_holm = signif(pr$p_holm[i], 4), threshold = pr$threshold[i], verdict = v[1], rule = v[2])
}))
print(vd)
write.csv(vd, file.path(out, "verdict.csv"), row.names = FALSE)
write.csv(cluster_diag(x, "primary"), file.path(out, "cluster_diagnostics.csv"), row.names = FALSE)
write.csv(r$fails, file.path(out, "bootstrap_failures.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(root, "modern", "sessionInfo.txt"))
