# P28_VFF S6 step 3: I3 (divergence since democracy) from one interacted model on the stacked 138 x 2 panel,
# T3 col-10 specification fully interacted with year; Conley Bartlett 100 km with same-district cross-year weight 1.
# Then applies the card §8 verdict tables mechanically. Writes output/I3.csv and output/verdict.csv.
source("./P28_VFF/modern/common.R")
dec <- step0_decision(); cat("Step 0 decision:", dec, "\n")
d <- attach_centroids(load_data())
D <- dist_gc(d$lat_c, d$lon_c); W <- kernel_W(D, CUTOFF)
Wst <- kronecker(matrix(1, 2, 2), W)            # pair (i,j): w(h_ij) in any year combination; same district: 1
Z <- c("l_pop1911", "p_homeland", "tri", "rain_level")

# b0: published 2011 coefficient (col 10) minus the corresponding 1996 coefficient (col 4) from original run A
ra <- read.csv(file.path(ROOT, "repro_original/runA/regs_est.csv"))
b96_runA <- ra$b[ra$model == "lights96_4" & ra$var == "p_homeland"]
b11_runA <- ra$b[ra$model == "lights11_4" & ra$var == "p_homeland"]
b0 <- -2.025 - b96_runA
cat(sprintf("b0 = -2.025 - (%.4f) = %.4f  [run A col 10 = %.4f]\n", b96_runA, b0, b11_runA))

i3_fit <- function(y96, y11, label, W2 = Wst) {
  Zm <- cbind(1, as.matrix(d[, Z])); colnames(Zm) <- c("const", Z)
  X <- rbind(cbind(Zm, 0 * Zm), cbind(0 * Zm, Zm))
  colnames(X) <- c(paste0(colnames(Zm), "_96"), paste0(colnames(Zm), "_11"))
  y <- c(y96, y11)
  stopifnot(all(is.finite(y)))
  b <- solve(crossprod(X), crossprod(X, y)); e <- as.vector(y - X %*% b)
  cv <- conley_from_W(X, e, W2)
  a <- setNames(rep(0, ncol(X)), colnames(X)); a["p_homeland_11"] <- 1; a["p_homeland_96"] <- -1
  con <- sum(a * b); se <- sqrt(as.numeric(t(a) %*% cv$V %*% a))
  data.frame(version = label, b_H96 = b["p_homeland_96", 1], b_H11 = b["p_homeland_11", 1], contrast = con,
             se_conley = se, z = con / se, p_conley = 2 * pnorm(-abs(con / se)),
             se_conley_H96 = sqrt(cv$V["p_homeland_96", "p_homeland_96"]), se_conley_H11 = sqrt(cv$V["p_homeland_11", "p_homeland_11"]),
             min_eig_meat = cv$min_eig_meat, clipped = cv$clipped, N = length(y), b0 = b0)
}

ext <- if (file.exists(file.path(OUT, "lights_extracted.csv"))) read.csv(file.path(OUT, "lights_extracted.csv")) else NULL
rows <- list()
# data-file series under each labelling (always reported)
rows[[1]] <- i3_fit(d$l_lights96, d$l_lights11, "datafile_original_labels")
rows[[2]] <- i3_fit(d$l_lights11, d$l_lights96, "datafile_relabelled")
if (!is.null(ext)) {
  e <- left_join(d[, "id", drop = FALSE], ext, by = "id"); stopifnot(!anyNA(e$ext96_raw))
  rows[[3]] <- i3_fit(log(e$ext96_raw), log(e$ext11_raw), "reextracted_uncalibrated")
  rows[[4]] <- i3_fit(log(e$ext96_cal), log(e$ext11_cal), "reextracted_calibrated")
}
i3 <- bind_rows(rows)
i3$role <- ifelse(i3$version == "reextracted_calibrated", "primary_calibrated",
           ifelse((dec == "original" & i3$version == "datafile_original_labels") | (dec == "relabel" & i3$version == "datafile_relabelled"),
                  "primary_uncalibrated", "reported"))
rownames(i3) <- NULL; i3$step0_decision <- dec
write.csv(i3, file.path(OUT, "I3.csv"), row.names = FALSE)
print(i3 |> mutate(across(where(is.numeric), ~ signif(.x, 4))))

# ---------------- verdicts (card §8, mechanical; first rule that applies) ----------------
prim <- read.csv(file.path(OUT, "primary.csv")) |> filter(role == "primary")
pla  <- read.csv(file.path(OUT, "placebo.csv"))
v <- left_join(prim, pla[, c("claim_id", "placebo_p", "mc_se")], by = "claim_id")
claim_txt <- c(T2_r2_c6 = "I1 Pop1911 -> Pop2011 (col 6)", T2_r2_c7 = "I1 Pop1911 -> Pop2011 (col 7, geo controls)",
               T3_r2_c1 = "I2 Homeland -> Un1996 (col 1)", T3_r2_c6 = "I2 Homeland -> Un2011 (col 6)",
               T3_r2_c9 = "I2 Homeland -> Lights2011 (col 9)", T3_r2_c10 = "I2 Homeland -> Lights2011 (col 10)")
is_lights <- v$claim_id %in% c("T3_r2_c9", "T3_r2_c10")
verd <- character(nrow(v)); rule <- character(nrow(v))
for (i in seq_len(nrow(v))) {
  r <- v[i, ]; b0i <- r$b0_published; same <- sign(r$estimate) == sign(b0i)
  if (is_lights[i] && dec == "unresolved") { verd[i] <- "not-testable (provenance)"; rule[i] <- "relabel table #0"; next }
  if (!is_lights[i] || dec == "original") {           # inference-only ladder (A4b)
    if (r$p_holm < 0.05 && r$placebo_p < 0.05) { verd[i] <- "confirmed"; rule[i] <- "inference-only #1" }
    else if (r$p_holm < 0.05) { verd[i] <- "qualified (spatial-noise fragile)"; rule[i] <- "inference-only #2" }
    else { verd[i] <- "weakened"; rule[i] <- "inference-only #3" }
  } else {                                            # relabelled lights rows
    if (!same && r$p_holm < 0.05 && r$placebo_p < 0.05) { verd[i] <- "overturned (reversed)"; rule[i] <- "relabel table #1" }
    else if (r$ci_bonf_lo > -0.5 * abs(b0i) && r$ci_bonf_hi < 0.5 * abs(b0i)) { verd[i] <- "overturned (credible null)"; rule[i] <- "relabel table #2" }
    else if (same && abs(r$estimate) >= 0.5 * abs(b0i) && r$p_holm < 0.05 && r$placebo_p < 0.05) { verd[i] <- "confirmed"; rule[i] <- "relabel table #3" }
    else if (same && r$p_holm < 0.05 && r$placebo_p < 0.05 && abs(r$estimate) < 0.5 * abs(b0i)) { verd[i] <- "qualified"; rule[i] <- "relabel table #4" }
    else if (same && r$p_holm < 0.05 && r$placebo_p >= 0.05) { verd[i] <- "qualified (spatial-noise fragile)"; rule[i] <- "relabel table #5" }
    else { verd[i] <- "weakened"; rule[i] <- "relabel table #6" }
  }
}
vt <- data.frame(claim_id = v$claim_id, family = v$family, claim = claim_txt[v$claim_id], b0 = v$b0_published,
                 estimate = v$estimate, se_conley = v$se_conley, p_conley = v$p_conley, p_holm = v$p_holm,
                 ci_bonf_lo = v$ci_bonf_lo, ci_bonf_hi = v$ci_bonf_hi,
                 placebo_p = v$placebo_p, mc_se = v$mc_se, verdict = verd, rule = rule)

# I3
if (dec == "unresolved") { i3v <- "not-testable"; i3r <- "I3 #0"; pu <- i3[i3$version == "datafile_original_labels", ]; pc <- pu[0, ] } else {
  pu <- i3[i3$role == "primary_uncalibrated", ]; pc <- i3[i3$role == "primary_calibrated", ]
  if (nrow(pc) == 0) { i3v <- "not-testable"; i3r <- "I3: calibrated arm unavailable" } else {
    sig <- c(pu$p_conley < 0.05, pc$p_conley < 0.05); con <- c(pu$contrast, pc$contrast)
    if (all(con > 0 & sig)) { i3v <- "overturned"; i3r <- "I3 #1" }
    else if (all(con < 0 & abs(con) >= 0.5 * abs(b0) & sig)) { i3v <- "confirmed"; i3r <- "I3 #2" }
    else if (sum(sig) == 1) { i3v <- "qualified (calibration-sensitive)"; i3r <- "I3 #3" }
    else { i3v <- "weakened"; i3r <- "I3 #4" }
  }
}
vt <- bind_rows(vt, data.frame(claim_id = "I3", family = "I3",
  claim = "I3 divergence: beta_H(2011) - beta_H(1996), log lights, col-10 spec interacted with year",
  b0 = b0, estimate = pu$contrast, se_conley = pu$se_conley, p_conley = pu$p_conley, p_holm = NA,
  ci_bonf_lo = NA, ci_bonf_hi = NA, placebo_p = NA, mc_se = NA, verdict = i3v,
  rule = paste0(i3r, if (nrow(pc)) sprintf("; calibrated contrast %.3f (SE %.3f, p %.3g)", pc$contrast, pc$se_conley, pc$p_conley) else "")))
# family summaries: weakest member
ord <- c("not-testable", "overturned", "weakened", "qualified", "confirmed")
base <- function(x) sapply(x, function(s) ord[which(startsWith(s, ord))[1]])
for (fam in c("I1", "I2")) {
  m <- vt[vt$family == fam & vt$claim_id != fam, ]
  k <- which.min(match(base(m$verdict), ord))
  vt <- bind_rows(vt, data.frame(claim_id = paste0(fam, "_summary"), family = fam,
    claim = paste(fam, "summary (weakest member)"), verdict = m$verdict[k],
    rule = paste0("weakest member: ", m$claim_id[k])))
}
rownames(vt) <- NULL; vt$step0_decision <- dec
write.csv(vt, file.path(OUT, "verdict.csv"), row.names = FALSE)
print(vt[, c("claim_id", "estimate", "se_conley", "p_holm", "placebo_p", "verdict", "rule")])
