# P28_VFF S6 step 4: the card §5 admissible sensitivities (reported, not verdict-determining).
# 1 Conley 50/200/500 km; 2 HC1; 3 Run A' vintages; 4 I1 without homeland share; 5 Matern(1.5) placebo;
# 6 quadratic lat/lon trend (changes conditioning set); 7 all 201 districts (changed population, A4d).
source("./P28_VFF/modern/common.R")
dec <- step0_decision()
d <- attach_centroids(load_data())
D <- dist_gc(d$lat_c, d$lon_c)
sp <- specs(if (dec == "relabel") "relabel" else "original")
rows <- list()
add <- function(sens, cid, b, se, se_type, N, note = "", placebo_p = NA, mc_se = NA, extra = list()) {
  rows[[length(rows) + 1]] <<- data.frame(sensitivity = sens, claim_id = cid, estimate = b, se = se, se_type = se_type,
    t = b / se, p = 2 * pnorm(-abs(b / se)), N = N, placebo_p = placebo_p, mc_se = mc_se, note = note)
}
cfit <- function(s, data, Dm, cu = CUTOFF, x = s$x) {
  fit <- lm(fml(s, x), data = data); cv <- conley_fit(fit, kernel_W(Dm, cu))
  list(b = unname(coef(fit)[s$v]), se = sqrt(cv$V[s$v, s$v]), N = nobs(fit), fit = fit, clipped = cv$clipped)
}

# 1. Conley cut-offs
for (cid in names(sp)) for (cu in c(50, 200, 500)) {
  r <- cfit(sp[[cid]], d, D, cu); add("1 Conley cut-off", cid, r$b, r$se, paste0("Bartlett ", cu, " km"), r$N,
                                      if (r$clipped) "meat eigenvalues clipped" else "")
}
# I3 at other cut-offs (source the I3 helper by re-running its fit on the stacked panel)
Zv <- c("l_pop1911", "p_homeland", "tri", "rain_level")
i3_con <- function(y96, y11, cu) {
  Zm <- cbind(1, as.matrix(d[, Zv])); X <- rbind(cbind(Zm, 0 * Zm), cbind(0 * Zm, Zm)); y <- c(y96, y11)
  b <- solve(crossprod(X), crossprod(X, y)); e <- as.vector(y - X %*% b)
  V <- conley_from_W(X, e, kronecker(matrix(1, 2, 2), kernel_W(D, cu)))$V
  a <- rep(0, ncol(X)); a[3] <- -1; a[ncol(Zm) + 3] <- 1
  c(sum(a * b), sqrt(as.numeric(t(a) %*% V %*% a)))
}
if (dec != "unresolved") {
  y96 <- d[[lights1996_var(dec)]]; y11 <- d[[lights2011_var(dec)]]
  ext <- if (file.exists(file.path(OUT, "lights_extracted.csv"))) left_join(d[, "id", drop = FALSE], read.csv(file.path(OUT, "lights_extracted.csv")), by = "id") else NULL
  for (cu in c(50, 200, 500)) {
    r <- i3_con(y96, y11, cu); add("1 Conley cut-off", "I3 (uncalibrated)", r[1], r[2], paste0("Bartlett ", cu, " km"), 276)
    if (!is.null(ext)) { r <- i3_con(log(ext$ext96_cal), log(ext$ext11_cal), cu)
      add("1 Conley cut-off", "I3 (calibrated)", r[1], r[2], paste0("Bartlett ", cu, " km"), 276) }
  }
}
# 2. HC1 (benchmark only)
for (cid in names(sp)) { fit <- lm(fml(sp[[cid]]), d); v <- sp[[cid]]$v
  add("2 HC1", cid, unname(coef(fit)[v]), sqrt(vcovHC(fit, "HC1")[v, v]), "HC1", nobs(fit)) }
# 3. Run A' vintages (VG-1 l_pop1996 = log(p_96_old/area); VG-2 u_96_old and VG-3 l_tri apply to Table 1 only)
dA <- d; dA$l_pop1996 <- log(dA$p_96_old / dA$area)
for (cid in names(sp)) { r <- cfit(sp[[cid]], dA, D)
  add("3 Run A' vintages", cid, r$b, r$se, "Bartlett 100 km", r$N,
      "Run A' swaps do not enter the headline specifications (VG-1 affects T2 cols 4-5; VG-2/VG-3 Table 1 only): identical by construction") }
# 4. I1 without the homeland-share control (possibly post-treatment, S5 C5-6)
for (cid in c("T2_r2_c6", "T2_r2_c7")) { s <- sp[[cid]]; r <- cfit(s, d, D, x = setdiff(s$x, "p_homeland"))
  add("4 I1 drop Homeland", cid, r$b, r$se, "Bartlett 100 km", r$N) }
# 5. Matern (nu = 1.5) covariance for the placebo
prim <- read.csv(file.path(OUT, "primary.csv")) |> filter(role == "primary")
W100 <- kernel_W(D, CUTOFF)
for (cid in names(sp)) {
  pl <- run_placebo(sp[[cid]], d, D, W100, prim$t_conley[prim$claim_id == cid], R = 2000, family = "matern")
  add("5 Matern(1.5) placebo", cid, prim$estimate[prim$claim_id == cid], prim$se_conley[prim$claim_id == cid], "Bartlett 100 km", 138,
      sprintf("%s fit: rho=%.1f km, sigma2=%.4g, tau2=%.4g", pl$cov$method, pl$cov$rho, pl$cov$sigma2, pl$cov$tau2), pl$p, pl$mc_se)
}
# 6. Quadratic spatial trend (changes the conditioning set)
d$lat2 <- d$lat_c^2; d$lon2 <- d$lon_c^2; d$latlon <- d$lat_c * d$lon_c
for (cid in names(sp)) { s <- sp[[cid]]; r <- cfit(s, d, D, x = c(s$x, "lat_c", "lon_c", "lat2", "lon2", "latlon"))
  add("6 Quadratic lat/lon trend (changed conditioning set)", cid, r$b, r$se, "Bartlett 100 km", r$N) }
# 7. All 201 districts (changed population, A4d; cannot determine a verdict)
dc <- read.csv(file.path(ORIG, "data.csv")) |> filter(!is.na(sample)) |>
  mutate(l_pop1911 = log(popdens1911), l_pop2011 = log(popdens2011), l_u1996 = log(u_96), l_u2011 = log(urate2011),
         l_lights11 = log(lig11), l_lights96 = log(lig96), tri = tri / 10000)
chk <- inner_join(d[, c("id", "l_pop1911", "l_pop2011", "l_u1996", "l_u2011", "l_lights11", "l_lights96", "tri")],
                  dc[, c("id", "l_pop1911", "l_pop2011", "l_u1996", "l_u2011", "l_lights11", "l_lights96", "tri")], by = "id")
maxdiff <- max(sapply(c("l_pop1911", "l_pop2011", "l_u1996", "l_u2011", "l_lights11", "l_lights96", "tri"),
                      function(v) max(abs(chk[[paste0(v, ".x")]] - chk[[paste0(v, ".y")]]), na.rm = TRUE)))
dc <- attach_centroids(dc)
for (cid in names(sp)) { s <- sp[[cid]]
  dd <- dc[complete.cases(dc[, c(s$y, s$x)]), ]
  r <- cfit(s, dd, dist_gc(dd$lat_c, dd$lon_c))
  add("7 All 201 districts (changed population)", cid, r$b, r$se, "Bartlett 100 km", r$N,
      sprintf("data.csv rebuild matches data.dta on the 138 to %.1e", maxdiff)) }

out <- bind_rows(rows); out$step0_decision <- dec
write.csv(out, file.path(OUT, "sensitivities.csv"), row.names = FALSE)
print(out |> mutate(across(where(is.numeric), ~ signif(.x, 4))) |> select(-note))
