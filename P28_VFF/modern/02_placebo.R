# P28_VFF S6 step 2: Kelly (2019) spatial-noise placebo, R = 2,000, exponential covariance fitted by ML,
# L'Ecuyer streams seed 20261011, |t*| with Bartlett Conley 100 km SEs. Writes output/placebo.csv.
source("./P28_VFF/modern/common.R")
dec <- step0_decision()
d <- attach_centroids(load_data())
D <- dist_gc(d$lat_c, d$lon_c); W <- kernel_W(D, CUTOFF)
prim <- read.csv(file.path(OUT, "primary.csv")) |> filter(role == "primary")
sp <- specs(if (dec == "relabel") "relabel" else "original")
R <- 2000
res <- list(); draws <- list()
for (cid in names(sp)) {
  t_obs <- prim$t_conley[prim$claim_id == cid]
  pl <- run_placebo(sp[[cid]], d, D, W, t_obs, R = R, family = "exponential")
  res[[cid]] <- data.frame(claim_id = cid, outcome = sp[[cid]]$y, key_var = sp[[cid]]$v, covariance = "exponential",
    fit_method = pl$cov$method, fit_converged = pl$cov$ok, sigma2 = pl$cov$sigma2, rho_km = pl$cov$rho, tau2 = pl$cov$tau2,
    nugget_share = pl$cov$tau2 / (pl$cov$tau2 + pl$cov$sigma2), R = R, t_obs = t_obs,
    n_ge = sum(abs(pl$tstar) >= abs(t_obs)), placebo_p = pl$p, mc_se = pl$mc_se,
    q95_abs_tstar = pl$q95_abs_t, share_abs_tstar_gt_1.96 = pl$share_abs_t_gt_196)
  draws[[cid]] <- data.frame(claim_id = cid, rep = seq_len(R), tstar = pl$tstar)
  print(res[[cid]])
}
out <- bind_rows(res); out$step0_decision <- dec
write.csv(out, file.path(OUT, "placebo.csv"), row.names = FALSE)
write.csv(bind_rows(draws), file.path(OUT, "placebo_draws.csv"), row.names = FALSE)
