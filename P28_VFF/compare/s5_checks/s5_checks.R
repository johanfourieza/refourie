# P28_VFF S5 verification checks (Claude auditor). Diagnostics only; no S6 design.
# Reads original/ (read-only). Writes compare/_scratch_s5/*.csv and compare/s5_effects.csv.
# Run: Rscript compare/s5_checks/s5_checks.R  (from P28_VFF/)
suppressPackageStartupMessages({
  library(haven); library(dplyr); library(sandwich); library(spdep); library(sf)
})
setwd("./P28_VFF")
source("../tools/paths.R")   # A6: data root on D:
orig <- dpath("P28_VFF", "original", "Reversal of Fortunes")
out  <- dpath("P28_VFF", "compare", "_scratch_s5")   # A6: scratch on D:
dir.create(out, showWarnings = FALSE)

d <- zap_labels(read_dta(file.path(orig, "data.dta"))) |> as.data.frame()
stopifnot(nrow(d) == 138, all(d$sample == 1))

# ---- headline specifications (analysis Dec 2018.do lines 189-224) ----
hl <- list(
  T2_r2_c6  = list(f = l_pop2011 ~ l_pop1911 + p_homeland,              v = "l_pop1911",  m = "pop2011_3",  pub = 0.950, pse = 0.072),
  T2_r2_c7  = list(f = l_pop2011 ~ l_pop1911 + p_homeland + tri + rain_level, v = "l_pop1911",  m = "pop2011_4",  pub = 0.823, pse = 0.082),
  T3_r2_c1  = list(f = l_u1996 ~ l_pop1911 + p_homeland,               v = "p_homeland", m = "u1996_3",    pub = 0.522, pse = 0.067),
  T3_r2_c6  = list(f = l_u2011 ~ l_pop1911 + p_homeland + tri + rain_level, v = "p_homeland", m = "u11_4",      pub = 0.227, pse = 0.041),
  T3_r2_c9  = list(f = l_lights11 ~ l_pop1911 + p_homeland,            v = "p_homeland", m = "lights11_3", pub = -2.402, pse = 0.404),
  T3_r2_c10 = list(f = l_lights11 ~ l_pop1911 + p_homeland + tri + rain_level, v = "p_homeland", m = "lights11_4", pub = -2.025, pse = 0.354)
)
# non-headline: Settle1830 (fn 5)
extra <- list(
  T2_r1_c1 = list(f = l_pop1911 ~ bl100, v = "bl100", m = "pop1911_1a", pub = 0.333, pse = 0.193),
  T2_r1_c2 = list(f = l_pop1911 ~ bl100 + tri + rain_level, v = "bl100", m = "pop1911_1b", pub = 0.255, pse = 0.145)
)

# ---- Conley VCOV, replicating Hsiang ols_spatial_HAC (planar km, lon scaled by cos(lat_i)) ----
conley_V <- function(fit, lat, lon, cutoff, kernel = c("uniform", "bartlett")) {
  kernel <- match.arg(kernel)
  X <- model.matrix(fit); e <- resid(fit); n <- nrow(X)
  meat <- matrix(0, ncol(X), ncol(X))
  for (i in seq_len(n)) {
    dist <- sqrt((111 * (lat[i] - lat))^2 + (cos(lat[i] * pi / 180) * 111 * (lon[i] - lon))^2)
    w <- as.numeric(dist <= cutoff)
    if (kernel == "bartlett") w <- w * (1 - dist / cutoff)
    meat <- meat + (X[i, ] * e[i]) %o% colSums(X * (e * w))
  }
  B <- solve(crossprod(X))
  V <- B %*% meat %*% B; V <- (V + t(V)) / 2
  list(V = V, meat = meat)
}
se_of <- function(V, v) { x <- V[v, v]; if (x < 0) NA_real_ else sqrt(x) }

cuts <- c(20, 50, 100, 200, 300, 500, 1000)
cr <- read.csv("repro_original/conley_results.csv") |> filter(variant == "A (as found)")
all_specs <- c(hl, extra)

# Pair geometry
lat <- d$y_cent; lon <- d$x_cent
Dm <- outer(seq_len(138), seq_len(138), Vectorize(function(i, j)
  sqrt((111 * (lat[i] - lat[j]))^2 + (cos(lat[i] * pi / 180) * 111 * (lon[i] - lon[j]))^2)))
geo <- data.frame(cutoff = cuts,
  share_pairs_within = sapply(cuts, function(c) mean(Dm[upper.tri(Dm)] <= c)),
  max_dist_km = max(Dm))
write.csv(geo, file.path(out, "pair_geometry.csv"), row.names = FALSE)

se_rows <- list()
for (cid in names(all_specs)) {
  s <- all_specs[[cid]]; fit <- lm(s$f, data = d)
  b <- coef(fit)[s$v]
  iid <- sqrt(vcov(fit)[s$v, s$v]); hc1 <- sqrt(vcovHC(fit, "HC1")[s$v, s$v])
  se_rows[[length(se_rows) + 1]] <- data.frame(claim_id = cid, type = c("iid", "HC1"), cutoff = NA,
    b = b, se = c(iid, hc1), orig_ado_se = NA, min_eig_meat = NA)
  for (cu in cuts) for (k in c("uniform", "bartlett")) {
    cv <- conley_V(fit, lat, lon, cu, k)
    ref <- if (k == "uniform") cr$conley_se[cr$model == s$m & cr$var == s$v & cr$cutoff_km == cu] else NA
    se_rows[[length(se_rows) + 1]] <- data.frame(claim_id = cid, type = paste0("conley_", k), cutoff = cu,
      b = b, se = se_of(cv$V, s$v), orig_ado_se = if (length(ref)) ref[1] else NA,
      min_eig_meat = min(eigen(cv$meat, symmetric = TRUE)$values))
  }
}
se_tab <- bind_rows(se_rows); se_tab$t <- se_tab$b / se_tab$se
rownames(se_tab) <- NULL
write.csv(se_tab, file.path(out, "se_types.csv"), row.names = FALSE)

# ---- residual Moran's I ----
coords <- cbind(lon, lat)
W <- list(
  knn4  = nb2listw(knn2nb(knearneigh(coords, k = 4, longlat = TRUE)), style = "W"),
  knn8  = nb2listw(knn2nb(knearneigh(coords, k = 8, longlat = TRUE)), style = "W"),
  band100 = nb2listw(dnearneigh(coords, 0, 100, longlat = TRUE), style = "W", zero.policy = TRUE),
  band200 = nb2listw(dnearneigh(coords, 0, 200, longlat = TRUE), style = "W", zero.policy = TRUE)
)
Dgc <- st_distance(st_as_sf(data.frame(coords), coords = c("lon","lat"), crs = 4326)); Dgc <- matrix(as.numeric(Dgc)/1000, nrow(coords)); diag(Dgc) <- Inf; Wi <- 1 / Dgc^3; diag(Wi) <- 0
W$invdist3 <- mat2listw(Wi / rowSums(Wi), style = "W")   # analogue of moransi swm(pow 3)
mor <- list()
for (cid in names(all_specs)) {
  fit <- lm(all_specs[[cid]]$f, data = d)
  for (w in names(W)) {
    mt <- lm.morantest(fit, W[[w]], zero.policy = TRUE)
    mor[[length(mor) + 1]] <- data.frame(claim_id = cid, W = w, I = unname(mt$estimate[1]),
      z = unname(mt$statistic), p = mt$p.value)
  }
}
mor <- bind_rows(mor); write.csv(mor, file.path(out, "moran.csv"), row.names = FALSE)

# ---- vintage / construction swaps ----
d$tri_log <- d$l_tri
vint <- list(
  list(cid = "T3_r2_c1", sc = "u_96_old for Un1996", f = log(u_96_old) ~ l_pop1911 + p_homeland),
  list(cid = "T3_r2_c6", sc = "l_u11 (u_11) for Un2011", f = l_u11 ~ l_pop1911 + p_homeland + tri + rain_level),
  list(cid = "T2_r2_c7", sc = "l_tri for Rugged", f = l_pop2011 ~ l_pop1911 + p_homeland + l_tri + rain_level),
  list(cid = "T3_r2_c6", sc = "l_tri for Rugged", f = l_u2011 ~ l_pop1911 + p_homeland + l_tri + rain_level),
  list(cid = "T3_r2_c10", sc = "l_tri for Rugged", f = l_lights11 ~ l_pop1911 + p_homeland + l_tri + rain_level),
  list(cid = "T2_r2_c6", sc = "log(p_11/area) for Pop2011", f = log(p_11 / area) ~ l_pop1911 + p_homeland),
  list(cid = "T2_r2_c7", sc = "log(p_11/area) for Pop2011", f = log(p_11 / area) ~ l_pop1911 + p_homeland + tri + rain_level),
  list(cid = "T3_r2_c9", sc = "log(lights2011) for Lights2011", f = log(lights2011) ~ l_pop1911 + p_homeland),
  list(cid = "T3_r2_c10", sc = "log(lights2011) for Lights2011", f = log(lights2011) ~ l_pop1911 + p_homeland + tri + rain_level)
)

# ---- sample: include sample==0 districts where outcome/controls exist ----
dc <- read.csv(file.path(orig, "data.csv")) |> filter(!is.na(sample))
shp <- st_read(file.path(orig, "1911_dc.shp"), quiet = TRUE)
cen <- suppressWarnings(st_coordinates(st_centroid(st_geometry(shp))))
cen <- data.frame(id = shp$ID, x_c = cen[, 1], y_c = cen[, 2])
dc <- dc |> left_join(cen, by = "id") |>
  mutate(l_pop1911 = log(popdens1911), l_pop2011 = log(popdens2011), l_u1996 = log(u_96),
         l_u2011 = log(urate2011), l_lights11 = log(lig11), tri = tri / 10000)
# check centroid agreement on the 138
chk <- d |> select(id, x_cent, y_cent) |> left_join(cen, by = "id")
cen_maxdiff_km <- max(sqrt((111 * (chk$y_cent - chk$y_c))^2 + (111 * cos(chk$y_cent * pi / 180) * (chk$x_cent - chk$x_c))^2), na.rm = TRUE)
dropped <- dc |> filter(sample == 0) |>
  select(id, district, p_homeland, rain_level, popdens1911, urate2011, lig11)
write.csv(dropped, file.path(out, "dropped_districts.csv"), row.names = FALSE)

samp <- list()
for (cid in names(hl)) {
  s <- hl[[cid]]
  for (sc in c("all 201 districts", "201 minus districts with rain<300mm")) {
    dd <- if (sc == "all 201 districts") dc else filter(dc, rain_level >= 300 | sample == 1)
    fit <- lm(s$f, data = dd)
    b <- coef(fit)[s$v]
    c100 <- se_of(conley_V(fit, dd$y_c[as.integer(rownames(model.frame(fit)))],
                           dd$x_c[as.integer(rownames(model.frame(fit)))], 100, "bartlett")$V, s$v)
    samp[[length(samp) + 1]] <- data.frame(claim_id = cid, scenario = sc, N = nobs(fit), b = b,
      se_iid = sqrt(vcov(fit)[s$v, s$v]), se_conleyB100 = c100)
  }
}
samp <- bind_rows(samp); write.csv(samp, file.path(out, "sample_extension.csv"), row.names = FALSE)

# ---- bad / post-treatment controls ----
bad <- list(
  list(cid = "T2_r2_c6", sc = "drop Homeland (mediator of Pop1911)", f = l_pop2011 ~ l_pop1911),
  list(cid = "T2_r2_c7", sc = "drop Homeland (mediator of Pop1911)", f = l_pop2011 ~ l_pop1911 + tri + rain_level),
  list(cid = "T3_r2_c1", sc = "drop Pop1911 (Homeland only)", f = l_u1996 ~ p_homeland),
  list(cid = "T3_r2_c6", sc = "add Pop2011 (post-treatment; col 7)", f = l_u2011 ~ l_pop1911 + l_pop2011 + p_homeland + tri + rain_level),
  list(cid = "T3_r2_c6", sc = "add Pop2011+NetMig11 (post-treatment; col 8)", f = l_u2011 ~ l_pop1911 + l_pop2011 + p_homeland + l_netmig_11 + tri + rain_level),
  list(cid = "T3_r2_c10", sc = "add Pop2011 (post-treatment; col 11)", f = l_lights11 ~ l_pop1911 + l_pop2011 + p_homeland + tri + rain_level),
  list(cid = "T3_r2_c10", sc = "add Pop2011+NetMig11 (post-treatment; col 12)", f = l_lights11 ~ l_pop1911 + l_pop2011 + p_homeland + l_netmig_11 + tri + rain_level),
  list(cid = "T3_r2_c9", sc = "drop Pop1911 (Homeland only)", f = l_lights11 ~ p_homeland)
)

# ---- Settle1830 threshold used in Fig 1(a) ----
fig <- data.frame(var = c("bl100", "bl70"), n1 = c(sum(d$bl100), sum(d$bl70)),
  b_col1 = c(coef(lm(l_pop1911 ~ bl100, d))[2], coef(lm(l_pop1911 ~ bl70, d))[2]),
  se_col1 = c(sqrt(vcov(lm(l_pop1911 ~ bl100, d))[2, 2]), sqrt(vcov(lm(l_pop1911 ~ bl70, d))[2, 2])),
  b_col2 = c(coef(lm(l_pop1911 ~ bl100 + tri + rain_level, d))[2], coef(lm(l_pop1911 ~ bl70 + tri + rain_level, d))[2]),
  se_col2 = c(sqrt(vcov(lm(l_pop1911 ~ bl100 + tri + rain_level, d))[2, 2]), sqrt(vcov(lm(l_pop1911 ~ bl70 + tri + rain_level, d))[2, 2])))
fig$agree_bl100_bl70 <- mean(d$bl100 == d$bl70)
write.csv(fig, file.path(out, "settle_threshold.csv"), row.names = FALSE)

# ---- assemble s5_effects.csv ----
eff <- list()
add <- function(sc, cid, val, se, note) {
  s <- c(hl, extra)[[cid]]
  eff[[length(eff) + 1]] <<- data.frame(scenario = sc, claim_id = cid, published = s$pub,
    original_code = round(unname(coef(lm(s$f, d))[s$v]), 4), scenario_value = round(unname(val), 4),
    se = round(se, 4), note = note)
}
for (cid in names(c(hl, extra))) {
  st <- se_tab[se_tab$claim_id == cid, ]
  for (i in seq_len(nrow(st))) {
    r <- st[i, ]
    if (r$type %in% c("iid", "HC1")) add(paste0("se_", r$type), cid, r$b, r$se, sprintf("t=%.2f; published SE %.3f", r$t, c(hl, extra)[[cid]]$pse))
    else if (r$cutoff %in% c(50, 100, 200, 500, 1000))
      add(paste0("se_", r$type, "_", r$cutoff, "km"), cid, r$b, r$se,
          sprintf("t=%.2f; orig ado uniform SE=%s; min eigen(meat)=%.3g", r$t,
                  ifelse(is.na(r$orig_ado_se), "NA", sprintf("%.4f", r$orig_ado_se)), r$min_eig_meat))
  }
}
for (v in vint) { fit <- lm(v$f, d); s <- hl[[v$cid]]
  add(paste0("vintage: ", v$sc), v$cid, coef(fit)[s$v], sqrt(vcov(fit)[s$v, s$v]), "iid SE; N=138") }
for (i in seq_len(nrow(samp))) { r <- samp[i, ]
  add(paste0("sample: ", r$scenario), r$claim_id, r$b, r$se_iid, sprintf("N=%d; iid SE; Conley Bartlett 100km SE=%.4f", r$N, r$se_conleyB100)) }
for (v in bad) { fit <- lm(v$f, d); s <- hl[[v$cid]]
  add(paste0("controls: ", v$sc), v$cid, coef(fit)[s$v], sqrt(vcov(fit)[s$v, s$v]), "iid SE; N=138") }
for (k in 1:2) { cid <- c("T2_r1_c1", "T2_r1_c2")[k]
  add("Settle1830 = bl70 (Fig 1a threshold)", cid, fig[2, c("b_col1", "b_col2")[k]], fig[2, c("se_col1", "se_col2")[k]],
      sprintf("iid SE; bl70 has %d settled districts vs %d for bl100", fig$n1[2], fig$n1[1])) }
eff <- bind_rows(eff)
write.csv(eff, "compare/s5_effects.csv", row.names = FALSE)

cat("centroid max diff (km) on 138:", cen_maxdiff_km, "\n")
print(geo)
print(se_tab |> filter(type %in% c("iid", "HC1") | cutoff %in% c(50, 100, 200, 500, 1000)) |>
  mutate(across(where(is.numeric), ~ signif(.x, 4))))
print(mor |> mutate(across(where(is.numeric), ~ signif(.x, 3))))
print(samp); print(fig); print(dropped)
print(eff |> filter(grepl("vintage|controls", scenario)))

# ---- night-lights year labels: data.csv lig96/lig11 vs zonal-statistics shapefiles ----
lsh <- sf::st_drop_geometry(st_read(file.path(orig, "lights.shp"), quiet = TRUE))          # 2018-12-03, fields lig96mean/lig11mean
esh <- sf::st_drop_geometry(st_read(file.path(orig, "1911_ZAEast_SWA_LSO.shp"), quiet = TRUE)) # fields lig2011mea/lig96mean/lig11mean
dsh <- sf::st_drop_geometry(st_read(file.path(orig, "1911_dc.shp"), quiet = TRUE))          # field lights_mea (2015-era "lights2011")
dcsv <- read.csv(file.path(orig, "data.csv"))
mm <- dcsv |> select(id, lights2011, lig96, lig11) |>
  inner_join(lsh |> select(ID, L_lig96mean = lig96mean, L_lig11mean = lig11mean), by = c(id = "ID")) |>
  left_join(esh |> select(ID, E_lig2011mea = lig2011mea, E_lig96mean = lig96mean, E_lig11mean = lig11mean), by = c(id = "ID")) |>
  left_join(dsh |> select(ID, D_lights_mea = lights_mea), by = c(id = "ID"))
lightchk <- data.frame(
  comparison = c("data lig11 vs lights.shp lig96mean", "data lig96 vs lights.shp lig11mean",
                 "data lig11 vs lights.shp lig11mean", "data lig96 vs lights.shp lig96mean",
                 "data lig96 vs ZAEast lig2011mea", "data lig11 vs ZAEast lig2011mea",
                 "data lights2011 vs data lig96", "data lights2011 vs data lig11"),
  max_abs_diff = c(max(abs(mm$lig11 - mm$L_lig96mean)), max(abs(mm$lig96 - mm$L_lig11mean)),
                   max(abs(mm$lig11 - mm$L_lig11mean)), max(abs(mm$lig96 - mm$L_lig96mean)),
                   max(abs(mm$lig96 - mm$E_lig2011mea), na.rm = TRUE), max(abs(mm$lig11 - mm$E_lig2011mea), na.rm = TRUE),
                   max(abs(mm$lights2011 - mm$lig96)), max(abs(mm$lights2011 - mm$lig11))),
  cor_log = c(cor(log(mm$lig11), log(mm$L_lig96mean)), cor(log(mm$lig96), log(mm$L_lig11mean)),
              cor(log(mm$lig11), log(mm$L_lig11mean)), cor(log(mm$lig96), log(mm$L_lig96mean)),
              cor(log(mm$lig96), log(mm$E_lig2011mea), use = "c"), cor(log(mm$lig11), log(mm$E_lig2011mea), use = "c"),
              cor(log(mm$lights2011), log(mm$lig96)), cor(log(mm$lights2011), log(mm$lig11))))
lightchk$median_ratio_138 <- NA
lightchk <- rbind(lightchk, data.frame(comparison = "median over 138: lig11/lig96 (data labels)", max_abs_diff = NA, cor_log = NA,
  median_ratio_138 = median(d$lig11 / d$lig96)))
write.csv(lightchk, file.path(out, "lights_label_check.csv"), row.names = FALSE)
print(lightchk)

# Headline lights claims if the two series are relabelled (lig96 treated as 2011)
eff <- list(eff)
sw <- list(T3_r2_c9 = l_lights96 ~ l_pop1911 + p_homeland, T3_r2_c10 = l_lights96 ~ l_pop1911 + p_homeland + tri + rain_level)
swr <- list()
for (cid in names(sw)) {
  fit <- lm(sw[[cid]], d)
  cB <- sapply(c(100, 200), function(cu) se_of(conley_V(fit, lat, lon, cu, "bartlett")$V, "p_homeland"))
  add("lights relabelled: lig96 used as Lights2011", cid, coef(fit)["p_homeland"], sqrt(vcov(fit)["p_homeland", "p_homeland"]),
      sprintf("iid SE; Conley Bartlett SE 100km=%.3f, 200km=%.3f; equals published Lights96 cols 3-4", cB[1], cB[2]))
}
eff <- bind_rows(eff)
write.csv(eff, "compare/s5_effects.csv", row.names = FALSE)
print(tail(eff, 2))
