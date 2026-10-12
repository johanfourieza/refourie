# P28_VFF S6 step 1: Bartlett Conley 100 km (great-circle, WGS84 polygon centroids), Holm across 6 coefficients.
# Also validates the copied S5 Conley code against S5 output (R) and the authors' ado bartlett option (Stata).
# Run: Rscript modern/01_conley.R   (requires output/step0.csv from 00_provenance.R)
source("./P28_VFF/modern/common.R")
dec <- step0_decision(); cat("Step 0 decision:", dec, "\n")

d0 <- load_data()
d  <- attach_centroids(d0)
n_drop <- attr(d, "n_no_centroid")
cen_diff_km <- diag(dist_gc(c(d$lat_c, d$y_cent), c(d$lon_c, d$x_cent))[seq_len(nrow(d)), nrow(d) + seq_len(nrow(d))])

# ---- cut-off rule (card §4): ~2 x median nearest-neighbour centroid distance, rounded to 100 km ----
D  <- dist_gc(d$lat_c, d$lon_c)
Dn <- D; diag(Dn) <- Inf
nn <- apply(Dn, 1, min)
geom <- data.frame(item = c("n_districts", "n_dropped_no_centroid", "median_nn_km", "twice_median_nn_km",
                            "rule_cutoff_km", "card_cutoff_km", "max_centroid_diff_vs_datafile_km", "max_pair_km"),
                   value = c(nrow(d), n_drop, median(nn), 2 * median(nn), round(2 * median(nn), -2), CUTOFF,
                             max(cen_diff_km), max(D)))
write.csv(geom, file.path(OUT, "conley_geometry.csv"), row.names = FALSE)
print(geom)

# ---- validation of the copied S5 code (original labels, data-file centroids, planar distance as in S5) ----
s5 <- read.csv(dpath("P28_VFF", "compare", "_scratch_s5", "se_types.csv")) |> filter(type == "conley_bartlett")
st <- read.csv(dpath("P28_VFF", "compare", "_scratch_s5", "conley_bartlett_stata.csv"))
mmap <- c(T2_r2_c6 = "pop2011_3", T2_r2_c7 = "pop2011_4", T3_r2_c1 = "u1996_3", T3_r2_c6 = "u2011_4",
          T3_r2_c9 = "lights11_3", T3_r2_c10 = "lights11_4")
Dp <- dist_planar_s5(d$y_cent, d$x_cent)
val <- list()
for (cid in names(specs("original"))) {
  s <- specs("original")[[cid]]; fit <- lm(fml(s), data = d)
  for (cu in c(50, 100, 200, 500)) {
    v_copy <- sqrt(conley_V_s5(fit, d$y_cent, d$x_cent, cu, "bartlett")$V[s$v, s$v])
    v_new  <- sqrt(conley_fit(fit, kernel_W(Dp, cu), clip = FALSE)$V[s$v, s$v])
    ref_r  <- s5$se[s5$claim_id == cid & s5$cutoff == cu]
    ref_st <- st$se[st$model == mmap[cid] & st$var == s$v & st$cutoff == cu]
    val[[length(val) + 1]] <- data.frame(claim_id = cid, cutoff_km = cu, se_s5_R = ref_r,
      se_stata_ado_bartlett = if (length(ref_st)) ref_st[1] else NA, se_copied_code = v_copy, se_S6_Wmatrix_planar = v_new)
  }
}
val <- bind_rows(val) |>
  mutate(maxdiff_copy_vs_s5 = abs(se_copied_code - se_s5_R), maxdiff_S6_vs_s5 = abs(se_S6_Wmatrix_planar - se_s5_R),
         diff_S6_vs_stata = abs(se_S6_Wmatrix_planar - se_stata_ado_bartlett))
write.csv(val, file.path(OUT, "conley_validation.csv"), row.names = FALSE)
cat("Validation: max |copy - S5| =", max(val$maxdiff_copy_vs_s5), "; max |S6 - S5| =", max(val$maxdiff_S6_vs_s5),
    "; max |S6 - Stata| =", max(val$diff_S6_vs_stata, na.rm = TRUE), "(", sum(!is.na(val$diff_S6_vs_stata)), "Stata cells)\n")
stopifnot(max(val$maxdiff_S6_vs_s5) < 5e-4)

# ---- primary: great-circle Bartlett 100 km on polygon centroids ----
W100 <- kernel_W(D, CUTOFF)
est_row <- function(cid, s, role, data = d, W = W100) {
  fit <- lm(fml(s), data = data)
  cv <- conley_fit(fit, W)
  b <- unname(coef(fit)[s$v])
  data.frame(claim_id = cid, family = s$fam, role = role, outcome = s$y, key_var = s$v, b0_published = s$pub,
             estimate = b, se_iid = sqrt(vcov(fit)[s$v, s$v]), se_hc1 = sqrt(vcovHC(fit, "HC1")[s$v, s$v]),
             se_conley = sqrt(cv$V[s$v, s$v]), min_eig_meat = cv$min_eig_meat, clipped = cv$clipped, N = nobs(fit))
}
sp <- specs(if (dec == "relabel") "relabel" else "original")
prim <- bind_rows(lapply(names(sp), function(cid) est_row(cid, sp[[cid]], "primary")))
prim <- prim |> mutate(t_conley = estimate / se_conley, p_conley = 2 * pnorm(-abs(t_conley)),
                       p_holm = p.adjust(p_conley, "holm"),
                       ci_bonf_lo = estimate - qnorm(1 - 0.05 / (2 * n())) * se_conley,
                       ci_bonf_hi = estimate + qnorm(1 - 0.05 / (2 * n())) * se_conley)
# alternative labelling of the lights rows (reported; card §4 "both labellings are reported")
alt_dec <- if (dec == "relabel") "original" else "relabel"
alt <- bind_rows(lapply(c("T3_r2_c9", "T3_r2_c10"), function(cid) est_row(cid, specs(alt_dec)[[cid]], paste0("alt_labelling_", alt_dec)))) |>
  mutate(t_conley = estimate / se_conley, p_conley = 2 * pnorm(-abs(t_conley)), p_holm = NA,
         ci_bonf_lo = estimate - qnorm(1 - 0.05 / 12) * se_conley, ci_bonf_hi = estimate + qnorm(1 - 0.05 / 12) * se_conley)
prim$step0_decision <- dec; alt$step0_decision <- dec
out <- bind_rows(prim, alt)
write.csv(out, file.path(OUT, "primary.csv"), row.names = FALSE)
print(out |> mutate(across(where(is.numeric), ~ signif(.x, 4))))
