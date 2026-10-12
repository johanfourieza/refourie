# P05_DK S6 step 1 (card §4A): geometry, eligibility, area-weighted interpolation under the missing-source rule,
# construction safeguards, and the corrected 1936 outcome. Writes the unit files to D: scratch (A6) and aggregate
# district-level diagnostics (open-class published aggregates) to output/.
# Usage (project root): Rscript P05_DK/modern/01_build.R
source("./P05_DK/modern/common.R")
suppressPackageStartupMessages(library(tidyxl))
log_lines <- character()
say <- function(...) { s <- paste0(...); cat(s, "\n"); log_lines <<- c(log_lines, s) }
SLIVER <- 1e-3
stopf <- function(...) stop(paste0("SAFEGUARD STOP: ", ...), call. = FALSE)

# ---------------------------------------------------------------- authors' objects (S2/S5 harness snapshots)
s5 <- readRDS(dscratch(P, "compare", "s5_session.rds"))   # same harness as repro_original/run_all.R (P1-P8)
findat <- as.data.frame(s5$findat); mortality <- as.data.frame(s5$mortality); covs <- as.data.frame(s5$covariates)
c36m <- as.data.frame(s5$census_1936_merge)
stopifnot(!anyDuplicated(covs$StndrdN), nrow(mortality) == 207)

# ---------------------------------------------------------------- geometry (card §4A "Geometry")
sp <- file.path(SRC, "spatial")
s18_raw <- st_read(file.path(sp, "SA_1918.shp"), quiet = TRUE)
s70_raw <- st_read(file.path(sp, "RSA_Pop_1904_70.shp"), quiet = TRUE)
s37_raw <- st_read(file.path(sp, "1937.shp"), quiet = TRUE)
s18_raw$StndrdN <- as.character(s18_raw$StndrdN)
if (anyDuplicated(s18_raw$StndrdN)) stopf("duplicate StndrdN in SA_1918")
if (anyDuplicated(s70_raw$DISTRICT)) stopf("duplicate DISTRICT in RSA_Pop_1904_70")
s18 <- s18_raw |> st_make_valid() |> st_transform(ALB) |> select(StndrdN, OrgnlNm)
s18 <- s18[order(s18$StndrdN), ]

# Overlaps among 1918 polygons: list pairwise positive-area intersections, then assign each overlap to the
# alphabetically first StndrdN (st_difference in that order).
ov <- st_intersection(s18 |> select(a = StndrdN), s18 |> select(b = StndrdN)) |> filter(a < b)
ov$area_km2 <- as.numeric(st_area(ov)) / 1e6
ov <- st_drop_geometry(ov) |> filter(area_km2 > 0) |> arrange(desc(area_km2))
write.csv(ov, file.path(OUT, "build_overlaps_1918.csv"), row.names = FALSE)
say("1918 polygon pairs with positive-area overlap: ", nrow(ov), "; total overlap area ", signif(sum(ov$area_km2), 4), " km2")
g <- st_difference(st_geometry(s18))
if (length(g) != nrow(s18)) stopf("st_difference dropped polygons (", length(g), ")")
s18_nov <- st_set_geometry(st_drop_geometry(s18), st_make_valid(g))
ov2 <- st_intersection(s18_nov |> select(a = StndrdN), s18_nov |> select(b = StndrdN)) |> filter(a < b)
say("Overlap area remaining after the rule: ", signif(sum(as.numeric(st_area(ov2))) / 1e6, 4), " km2")

# ---------------------------------------------------------------- eligibility (card §4A "Eligibility")
mortality$key <- mortality$mag_dist_1918
mortality$key[mortality$key == "Umvoti (Greytown("] <- "Umvoti (Greytown)"   # authors' spelling fixes (findat)
mortality$key[mortality$key == "Kimberey"] <- "Kimberley"
if (anyDuplicated(mortality$key)) stopf("duplicate Phillips key")
map <- findat |> filter(!is.na(mag_dist_1918), !is.na(StndrdN)) |> distinct(StndrdN, mag_dist_1918)
if (anyDuplicated(map$StndrdN)) stopf("polygon mapped to two Phillips rows")
# Polygons that the authors' matching never reached (no 1970 district assigned): apply the authors' agrep rule.
miss_poly <- setdiff(s18$StndrdN, map$StndrdN)
for (sn in miss_poly) {
  nm <- s18$OrgnlNm[s18$StndrdN == sn]; hit <- agrep(nm, mortality$key, value = TRUE)
  say("Polygon not reached by the authors' matching: ", sn, " (", nm, ") -> agrep: ", paste(hit, collapse = "; "))
  if (length(hit) == 1) map <- rbind(map, data.frame(StndrdN = sn, mag_dist_1918 = hit))
}
multi <- map |> group_by(mag_dist_1918) |> filter(n() > 1) |> arrange(mag_dist_1918, StndrdN) |> ungroup()
say("Phillips rows mapped to more than one polygon: ",
    paste(sprintf("%s -> {%s}", unique(multi$mag_dist_1918),
                  tapply(multi$StndrdN, multi$mag_dist_1918, paste, collapse = ", ")[unique(multi$mag_dist_1918)]), collapse = "; "))
# Card §4A: Lower Umzimkulu (Natal) receives Umzimkulu's (Transkei) rate without being part of that territory ->
# borrowed, ineligible. Every other listed case is a combined rate and is dissolved.
borrowed <- "lower umzimkulu"
map$eligible <- !map$StndrdN %in% borrowed
dissolve <- multi |> filter(!StndrdN %in% borrowed) |> group_by(mag_dist_1918) |> filter(n() > 1) |> ungroup()
map$unit_id <- map$StndrdN
for (r in unique(dissolve$mag_dist_1918)) {
  mem <- sort(dissolve$StndrdN[dissolve$mag_dist_1918 == r])
  map$unit_id[map$StndrdN %in% mem] <- paste(gsub(" ", "", mem), collapse = "_")
}
say("Dissolved units: ", paste(unique(map$unit_id[map$unit_id != map$StndrdN]), collapse = ", "),
    " | borrowed (ineligible): ", paste(borrowed, collapse = ", "))
if (!"paarl_wellington" %in% map$unit_id) stopf("paarl_wellington key not created")
no_rate <- setdiff(s18$StndrdN, map$StndrdN)
say("1918 polygons without any Phillips rate: ", if (length(no_rate)) paste(no_rate, collapse = ", ") else "none")
say("Phillips rows without a 1918 polygon: ", paste(setdiff(mortality$key, map$mag_dist_1918), collapse = ", "))
map <- left_join(map, mortality |> select(key, deaths = deaths_sflu_per_1000, region,
                                          ph_b = black_pop_1911, ph_ic = ind_col_pop_1911, ph_tot = total_pop_1918),
                 by = c("mag_dist_1918" = "key"), relationship = "many-to-one")
for (v in c("deaths", "ph_b", "ph_ic", "ph_tot")) map[[v]] <- as.numeric(map[[v]])
# region must be shared within a dissolved unit (asserted)
rg <- map |> filter(eligible) |> group_by(unit_id) |> summarise(nreg = n_distinct(region))
if (any(rg$nreg > 1)) stopf("dissolved unit with members in different regions: ", paste(rg$unit_id[rg$nreg > 1], collapse = ", "))

# Unit geometries: all 1918 polygons after the overlap rule; dissolved units unioned. Two target sets:
#   U  = primary units (eligible + the borrowed polygon kept as its own target so that mass is conserved);
#   PG = every undissolved 1918 polygon (for the one-correction-at-a-time sensitivities, card §5 item 2).
pg <- s18_nov |> left_join(map |> select(StndrdN, unit_id, eligible), by = "StndrdN")
pg$unit_id[is.na(pg$unit_id)] <- pg$StndrdN[is.na(pg$unit_id)]
pg$eligible[is.na(pg$eligible)] <- FALSE
U <- pg |> group_by(unit_id) |> summarise(eligible = all(eligible), members = paste(sort(StndrdN), collapse = "|"), .groups = "drop") |>
  st_make_valid()
if (anyDuplicated(U$unit_id)) stopf("duplicate unit_id")
U$area_km2 <- as.numeric(st_area(U)) / 1e6
PG <- pg |> transmute(unit_id = StndrdN, eligible) ; PG$area_km2 <- as.numeric(st_area(PG)) / 1e6
say("Units: ", nrow(U), " (eligible ", sum(U$eligible), "); polygons: ", nrow(PG))

# ---------------------------------------------------------------- 1911 sources, missing-source rule
s70 <- s70_raw |> filter(DISTRICT != "Lesotho") |> st_make_valid() |> st_transform(ALB) |>
  transmute(src = as.character(DISTRICT), T = T1911, B = B_1911, C = C_1911)
for (v in c("T", "B", "C")) { neg <- s70[[v]] < 0; s70[[v]][neg] <- NA }   # negative sentinel (-9999) = missing
say("1970 source polygons (Lesotho excluded): ", nrow(s70), "; missing T/B/C: ", sum(is.na(s70$T)), "/", sum(is.na(s70$B)), "/", sum(is.na(s70$C)),
    "; Lesotho was the only polygon with the -9999 sentinel: ", all(s70_raw$T1911[s70_raw$DISTRICT != "Lesotho"] >= 0))

# Area-weighted extensive interpolation of `vars` from the sources complete on `need` (the support), onto targets.
# Returns interpolated counts, the area of each target covered by the support and by missing sources.
interp <- function(src, tgt, vars, need, label) {
  ok <- stats::complete.cases(st_drop_geometry(src)[need])
  s <- src[ok, vars]
  aw <- suppressWarnings(st_interpolate_aw(s, tgt, extensive = TRUE, keep_NA = TRUE))
  if (nrow(aw) != nrow(tgt)) stopf("interpolate_aw row count for ", label)
  cov_int <- suppressWarnings(st_intersection(tgt |> select(unit_id), st_union(s)))
  cov_a <- tapply(as.numeric(st_area(cov_int)) / 1e6, cov_int$unit_id, sum)
  out <- st_drop_geometry(aw)[vars]
  out$covered_km2 <- unname(cov_a[tgt$unit_id]); out$covered_km2[is.na(out$covered_km2)] <- 0
  if (any(!ok)) {
    mi <- suppressWarnings(st_intersection(tgt |> select(unit_id), st_union(src[!ok, ])))
    ma <- tapply(as.numeric(st_area(mi)) / 1e6, mi$unit_id, sum)
    out$missing_km2 <- unname(ma[tgt$unit_id]); out$missing_km2[is.na(out$missing_km2)] <- 0
  } else out$missing_km2 <- 0
  # mass conservation: total over targets vs source mass apportioned by the share of each source inside some target
  inside <- suppressWarnings(st_intersection(s |> mutate(.sid = seq_len(nrow(s))), st_union(tgt)))
  frac <- numeric(nrow(s)); fa <- tapply(as.numeric(st_area(inside)), inside$.sid, sum)
  frac[as.integer(names(fa))] <- fa / as.numeric(st_area(s))[as.integer(names(fa))]
  mc <- lapply(vars, function(v) {
    tot_t <- sum(out[[v]], na.rm = TRUE); tot_s <- sum(st_drop_geometry(s)[[v]] * frac)
    rel <- abs(tot_t - tot_s) / max(1, abs(tot_s))
    data.frame(quantity = label, var = v, total_targets = tot_t, total_source_inside = tot_s,
               total_source_all = sum(st_drop_geometry(s)[[v]]), rel_discrepancy = rel)
  })
  mc <- do.call(rbind, mc)
  if (any(mc$rel_discrepancy > TOL_MASS)) stopf("mass conservation failed for ", label, ": ", paste(signif(mc$rel_discrepancy, 3), collapse = ", "))
  # empty support -> missing (DEVIATIONS D2: support below 0.1% of the target's area is a boundary sliver = empty);
  # applied after the mass check, which tests geometry and double counting
  empty <- out$covered_km2 <= SLIVER * tgt$area_km2; out[empty, vars] <- NA
  outside <- data.frame(quantity = label, src = if ("src" %in% names(s)) s$src else NA, share_outside = 1 - frac,
                        mass_outside = (1 - frac) * st_drop_geometry(s)[[vars[1]]])
  list(v = out, mc = mc, outside = outside, support_n = sum(ok))
}
# Strict alternative (card §5 item 26): any overlapping missing source -> missing; density on the full unit area.
build_1911 <- function(tgt, tag) {
  iB <- interp(s70, tgt, c("B", "T"), c("B", "T"), paste0(tag, ":1911 black share"))
  iC <- interp(s70, tgt, c("C", "T"), c("C", "T"), paste0(tag, ":1911 coloured share"))
  iT <- interp(s70, tgt, "T", "T", paste0(tag, ":1911 density"))
  d <- data.frame(unit_id = tgt$unit_id, area_km2 = tgt$area_km2,
    black_share = ifelse(iB$v$T > 0, iB$v$B / iB$v$T, NA), col_share = ifelse(iC$v$T > 0, iC$v$C / iC$v$T, NA),
    T1911 = iT$v$T, covered_T_km2 = iT$v$covered_km2,
    missing_share_B = iB$v$missing_km2 / tgt$area_km2, missing_share_C = iC$v$missing_km2 / tgt$area_km2,
    missing_share_T = iT$v$missing_km2 / tgt$area_km2)
  d$density <- ifelse(d$covered_T_km2 > 0, d$T1911 / d$covered_T_km2, NA)
  d$coverage_1970 <- d$covered_T_km2 / d$area_km2
  d$black_share_strict <- ifelse(d$missing_share_B > 0, NA, d$black_share)
  d$col_share_strict <- ifelse(d$missing_share_C > 0, NA, d$col_share)
  d$density_strict <- ifelse(d$missing_share_T > 0, NA, d$T1911 / d$area_km2)
  list(d = d, mc = rbind(iB$mc, iC$mc, iT$mc), outside = iT$outside)
}
b1911_U <- build_1911(U, "units"); b1911_PG <- build_1911(PG, "polygons")

# ---------------------------------------------------------------- rail (authors' algorithm, railways_1907_cleaning_ddk.R)
crs70 <- st_crs(s70_raw)
rail_full <- st_read(file.path(sp, "railways_1907", "1907_TrainTracks.shp"), quiet = TRUE)
st_crs(rail_full) <- crs70                                                   # as at :29 (assignment, not transform)
rail_exist <- rail_full[rail_full$Legend != "Do. under construction authorised or proposed", ]   # :32
authors_rail_km <- function(geom70) {                                         # :52-58
  cen <- suppressWarnings(st_centroid(geom70))
  apply(st_distance(rail_exist, cen), 2, min) / 1000
}
# Validation: the authors' md geometry is the union of the 1970 districts assigned by largest overlap (:65, :169-184).
s18_70 <- s18_raw |> st_transform(crs70); s18_70$OrgnlNm <- as.character(s18_70$OrgnlNm)
j70 <- suppressWarnings(st_join(s70_raw, s18_70, join = st_intersects, largest = TRUE)) |> filter(DISTRICT != "Lesotho")
auth_geom <- j70 |> group_by(StndrdN) |> summarise(T1911 = sum(T1911), dens_mean = mean(TDENS_11), B = sum(B_1911), C = sum(C_1911), .groups = "drop")
chk <- inner_join(st_drop_geometry(auth_geom), covs |> select(StndrdN, total_1911, density_1911, black_1911), by = "StndrdN")
say("Authors' 1970->1918 assignment re-run: ", nrow(chk), " polygons; max |T diff| ", max(abs(chk$T1911 - chk$total_1911)),
    "; max |density diff| ", signif(max(abs(chk$dens_mean - chk$density_1911)), 3))
if (max(abs(chk$T1911 - chk$total_1911)) > 0) stopf("authors' assignment not reproduced")
val <- auth_geom |> filter(StndrdN %in% c("paarl", "wellington", "cape", "durban"))
val$rail_rerun <- authors_rail_km(st_geometry(val))
val <- left_join(st_drop_geometry(val), covs |> select(StndrdN, rail_auth = rail_mdcentroid_to_nearestrail_km), by = "StndrdN")
say("Rail algorithm validation (authors' geometry): ", paste(sprintf("%s %.6f vs %.6f", val$StndrdN, val$rail_rerun, val$rail_auth), collapse = "; "))
if (any(abs(val$rail_rerun - val$rail_auth) > 1e-6)) stopf("authors' rail algorithm not reproduced")
# Re-run on the 1918 geometry for units without an authors' value (dissolved units; Port Shepstone, see DEVIATIONS D1)
U70 <- st_transform(U, crs70)
rail_km_auth <- covs$rail_mdcentroid_to_nearestrail_km[match(U$unit_id, covs$StndrdN)]
rerun <- U$eligible & (U$unit_id != U$members | is.na(rail_km_auth))
U$rail_source <- ifelse(rerun, "authors' algorithm re-run on 1918 unit centroid", "authors' value")
rail_km_auth[rerun] <- authors_rail_km(st_geometry(U70)[rerun])
say("Rail re-run for: ", paste(U$unit_id[rerun], sprintf("(%.3f km)", rail_km_auth[rerun]), collapse = ", "))
# S3 rail (card §5 item 5): equal-area projection, existing lines; and all features
rail_alb <- rail_full; st_crs(rail_alb) <- 4326; rail_alb <- st_transform(rail_alb, ALB)
cenU <- suppressWarnings(st_centroid(st_geometry(U)))
rail_s3 <- apply(st_distance(cenU, rail_alb[!grepl("under construction", rail_alb$Legend), ]), 1, min) / 1000
rail_s3_all <- apply(st_distance(cenU, rail_alb), 1, min) / 1000

# ---------------------------------------------------------------- rain, mortality, region
rain_by <- setNames(covs$rainfall_sepoctmean19101950, covs$StndrdN)
memb <- strsplit(U$members, "\\|")
pg_area <- setNames(PG$area_km2, PG$unit_id)
U$rain <- sapply(memb, function(m) { r <- rain_by[m]; a <- pg_area[m]; k <- !is.na(r); if (!any(k)) NA else sum(r[k] * a[k]) / sum(a[k]) })
um <- map |> filter(eligible) |> group_by(unit_id) |> summarise(deaths = first(deaths), region = first(region),
  ph_b = first(ph_b), ph_ic = first(ph_ic), ph_tot = first(ph_tot), phillips_row = first(mag_dist_1918), .groups = "drop")
U <- left_join(U, um, by = "unit_id", relationship = "one-to-one")

# ---------------------------------------------------------------- 1936 census read cell by cell (tidyxl)
c36dir <- file.path(SRC, "census", "census1936")
DASH <- c("-", "\u2013", "\u2014", "--", "\u2012")
read_grid <- function(f) {                       # emulates read_excel(col_types = "text"), header in row 1
  x <- xlsx_cells(f); x <- x[x$sheet == unique(x$sheet)[1], ]
  val <- ifelse(x$data_type == "numeric", format(x$numeric, scientific = FALSE, trim = TRUE, digits = 15),
         ifelse(x$data_type == "character", trimws(x$character), NA))
  val[!is.na(val) & val == ""] <- NA
  G <- matrix(NA_character_, max(x$row), max(x$col)); G[cbind(x$row, x$col)] <- val
  G[-1, , drop = FALSE]
}
num_cell <- function(v) {                         # card: 0 only for 0 or a dash; empty/NA = missing
  out <- suppressWarnings(as.numeric(v)); out[!is.na(v) & v %in% DASH] <- 0
  bad <- !is.na(v) & is.na(out); if (any(bad)) say("Non-numeric count cells set missing: ", paste(unique(v[bad]), collapse = " | "))
  out
}
# Table 1 (authors' row selection, census_1936_cleanedversion_ddk.R:77-86)
G1 <- read_grid(file.path(c36dir, "Table 1_ Unemployment, by gender and race, at MD level.xlsx"))
G1 <- G1[!is.na(G1[, 1]) & !is.na(G1[, 2]), ]; G1 <- G1[-(1:5), ]; G1 <- G1[!grepl("TOTAL", G1[, 1]), ]
t1 <- data.frame(mag_dist_1936 = G1[, 1], u_m = num_cell(G1[, 2]), u_f = num_cell(G1[, 3]), u_t = num_cell(G1[, 4]))
if (anyDuplicated(t1$mag_dist_1936)) stopf("duplicate district in Table 1")
say("Table 1 districts: ", nrow(t1), "; missing white unemployed (P/M/F): ", sum(is.na(t1$u_t)), "/", sum(is.na(t1$u_m)), "/", sum(is.na(t1$u_f)),
    "; dash cells: ", sum(G1[, 2:4] %in% DASH, na.rm = TRUE))
ua <- as.data.frame(s5$unemployment_1936)
cmp <- inner_join(t1, ua |> select(mag_dist_1936, a_t = unemployed_w_t), by = "mag_dist_1936")
say("Table 1 read check vs authors (NA->0 as authors): ", nrow(cmp), "/", nrow(ua), " districts matched; max |diff| ",
    max(abs(ifelse(is.na(cmp$u_t), 0, cmp$u_t) - cmp$a_t)))
# Table 7 (authors' steps :29-39; ages 15-64 = cols 18:32, 65-69 = col 33)
G7 <- read_grid(file.path(c36dir, "Table 7; Ages in years of Europeans, by gender, at MD level..xlsx"))
G7 <- G7[!is.na(G7[, 2]), ]
for (i in seq_len(nrow(G7))[-1]) if (is.na(G7[i, 1])) G7[i, 1] <- G7[i - 1, 1]
G7 <- G7[!grepl("TOTAL", G7[, 1]), ]
G7 <- G7[G7[, 2] %in% c("P", "M", "F"), ]
age <- apply(G7[, 18:33], 2, num_cell)
t7 <- data.frame(mag_dist_1936 = G7[, 1], sex = G7[, 2],
                 n_missing_1564 = rowSums(is.na(age[, 1:15])),
                 wa1564 = ifelse(rowSums(is.na(age[, 1:15])) > 0, NA, rowSums(age[, 1:15])),
                 wa1569 = ifelse(rowSums(is.na(age)) > 0, NA, rowSums(age)),
                 wa1569_narm = rowSums(age, na.rm = TRUE), a65_narm = ifelse(is.na(age[, 16]), 0, age[, 16]))
if (anyDuplicated(t7[c("mag_dist_1936", "sex")])) stopf("duplicate district-sex in Table 7")
say("Table 7 district-sex rows: ", nrow(t7), "; rows with >=1 missing 15-64 cell: ", sum(t7$n_missing_1564 > 0),
    " (P rows: ", sum(t7$n_missing_1564 > 0 & t7$sex == "P"), ")")
w7 <- t7 |> select(mag_dist_1936, sex, wa1564, wa1569, wa1569_narm, a65_narm) |>
  pivot_wider(names_from = sex, values_from = c(wa1564, wa1569, wa1569_narm, a65_narm))
ea <- c36m |> select(mag_dist_1936, total_workingage_pop_w) |> filter(!is.na(total_workingage_pop_w))
cmp7 <- inner_join(w7, ea, by = "mag_dist_1936")
say("Table 7 read check vs authors (15-69, na.rm as authors): ", nrow(cmp7), " districts; max |diff| ", max(abs(cmp7$wa1569_narm_P - cmp7$total_workingage_pop_w)))

# ---------------------------------------------------------------- 1936 districts -> 1937 polygons (authors' matching kept)
s37 <- s37_raw |> st_make_valid() |> st_transform(ALB)
s37$OrgnlNm <- as.character(s37$OrgnlNm); s37$StndrdN <- as.character(s37$StndrdN)
s37$OrgnlNm[s37$StndrdN == "middelburg c"] <- "Middleburg C"; s37$OrgnlNm[s37$StndrdN == "middelburg t"] <- "Middleburg T"
s37$OrgnlNm[s37$StndrdN == "richmond c"] <- "Richmond C"; s37$OrgnlNm[s37$StndrdN == "richmond n"] <- "Richmond N"
if (anyDuplicated(s37$OrgnlNm)) stopf("duplicate 1937 polygon name after cleaning")
xw36 <- c36m |> distinct(mag_dist_1936, mag_dist_1937)
if (anyDuplicated(xw36$mag_dist_1936)) stopf("1936 district with two 1937 names")
d36 <- full_join(t1, w7, by = "mag_dist_1936") |> left_join(xw36, by = "mag_dist_1936", relationship = "one-to-one")
d36$n_poly <- sapply(d36$mag_dist_1937, function(n) if (is.na(n)) 0L else sum(s37$OrgnlNm == n))
unm <- d36$mag_dist_1936[d36$n_poly == 0]
say("1936 districts matching no 1937 polygon (listed; not attached): ", paste(unm, collapse = "; "))
say("1936 districts matching >1 polygon: ", sum(d36$n_poly > 1))
say("1936 districts (P row) with a missing 15-64 age cell: ", paste(t7$mag_dist_1936[t7$sex == "P" & t7$n_missing_1564 > 0], collapse = "; "))
say("1937 polygons with no 1936 district: ", paste(setdiff(s37$OrgnlNm, d36$mag_dist_1937[d36$n_poly > 0]), collapse = "; "))
cnt <- c("u_t", "u_m", "u_f", "wa1564_P", "wa1564_M", "wa1564_F", "wa1569_P", "wa1569_M", "wa1569_F")
# authors' treatment for sensitivity 2(f): 15-69 with na.rm, unemployment NA -> 0
d36 <- d36 |> mutate(ua_t = ifelse(is.na(u_t), 0, u_t), wa_auth_P = wa1569_narm_P)
cnt_all <- c(cnt, "ua_t", "wa_auth_P")
att <- d36 |> filter(n_poly > 0)
pa <- setNames(as.numeric(st_area(s37)), s37$OrgnlNm)
long <- do.call(rbind, lapply(seq_len(nrow(att)), function(i) {
  pol <- s37$OrgnlNm[s37$OrgnlNm == att$mag_dist_1937[i]]; w <- pa[pol] / sum(pa[pol])
  data.frame(OrgnlNm = pol, mag_dist_1936 = att$mag_dist_1936[i], sapply(cnt_all, function(v) att[[v]][i] * w, simplify = FALSE), check.names = FALSE)
}))
p37 <- long |> group_by(OrgnlNm) |> summarise(n_1936 = n(), across(all_of(cnt_all), ~ if (any(is.na(.x))) NA_real_ else sum(.x)), .groups = "drop")
s37c <- s37 |> select(OrgnlNm) |> left_join(p37, by = "OrgnlNm", relationship = "one-to-one")
say("1937 polygons: ", nrow(s37c), "; with no 1936 district (counts missing): ", sum(is.na(s37c$n_1936)),
    "; with >1 1936 district: ", sum(s37c$n_1936 > 1, na.rm = TRUE),
    "; missing u_t / wa1564_P among attached: ", sum(is.na(s37c$u_t) & !is.na(s37c$n_1936)), "/", sum(is.na(s37c$wa1564_P) & !is.na(s37c$n_1936)))
build_1936 <- function(tgt, tag) {
  r <- function(num, den, lab) {
    i <- interp(s37c, tgt, c(num, den), c(num, den), paste0(tag, ":", lab))
    list(rate = ifelse(i$v[[den]] > 0, i$v[[num]] / i$v[[den]], NA), miss = i$v$missing_km2 / tgt$area_km2,
         cov = i$v$covered_km2 / tgt$area_km2, mc = i$mc)
  }
  a <- r("u_t", "wa1564_P", "urate 15-64"); b <- r("u_t", "wa1569_P", "urate 15-69")
  m <- r("u_m", "wa1564_M", "urate men 15-64"); f <- r("u_f", "wa1564_F", "urate women 15-64")
  au <- r("ua_t", "wa_auth_P", "urate authors' counts (15-69, NA->0)")
  d <- data.frame(unit_id = tgt$unit_id, urate = a$rate, urate_1569 = b$rate, urate_m = m$rate, urate_f = f$rate,
                  urate_authcounts = au$rate, coverage_1937 = a$cov, missing_share_urate = a$miss)
  d$urate_strict <- ifelse(d$missing_share_urate > 0, NA, d$urate)
  list(d = d, mc = rbind(a$mc, b$mc, m$mc, f$mc, au$mc))
}
b1936_U <- build_1936(U, "units"); b1936_PG <- build_1936(PG, "polygons")

# ---------------------------------------------------------------- assemble
units <- U |> left_join(b1911_U$d |> select(-area_km2), by = "unit_id") |> left_join(b1936_U$d, by = "unit_id")
units$rail_km <- rail_km_auth; units$log_rail <- log1p(units$rail_km)
units$log_rail_s3 <- log1p(rail_s3); units$log_rail_s3_all <- log1p(rail_s3_all)
units$region <- factor(units$region, levels = reg_levels)
units$deaths_pos <- !is.na(units$deaths) & units$deaths > 0
units$phillips_black_share <- units$ph_b / units$ph_tot; units$phillips_col_share <- units$ph_ic / units$ph_tot
cc <- st_coordinates(suppressWarnings(st_centroid(st_transform(st_geometry(units), 4326))))
units$lon <- cc[, 1]; units$lat <- cc[, 2]
polys <- PG |> left_join(b1911_PG$d |> select(-area_km2), by = "unit_id") |> left_join(b1936_PG$d, by = "unit_id")

# Analysis samples (listwise deletion over every variable of each specification)
el <- st_drop_geometry(units) |> filter(eligible)
v1 <- c("deaths", "black_share", "col_share", "density", "log_rail", "rain", "region")
el$in_H1 <- stats::complete.cases(el[v1])
el$in_H3 <- stats::complete.cases(el[c(v1, "urate")]) & el$deaths_pos
el$why_out_H1 <- apply(el[v1], 1, function(r) paste(v1[is.na(r)], collapse = "+"))
el$why_out_H3 <- apply(el[c(v1, "urate")], 1, function(r) paste(c(v1, "urate")[is.na(r)], collapse = "+"))
say("Analysis sample: H1 N = ", sum(el$in_H1), "; H3 N = ", sum(el$in_H3), "; non-positive mortality: ", sum(!el$deaths_pos))

# Unit-list differences against the published samples (S2 snapshot models)
s2 <- readRDS(dpath(P, "repro_original", "_scratch", "s2_snapshot.rds"))
ad <- s2$analysis_data; r36 <- s2$census_1936_reduced
pub1 <- ad$StndrdN[as.integer(rownames(model.frame(s2$predicting_mortality_analysis_ddk$model1)))]
pub3 <- r36$StndrdN[as.integer(rownames(model.frame(s2$census_1936_cleanedversion_ddk$total_model)))]
stopifnot(length(pub1) == 205, length(pub3) == 205)
unit_of <- setNames(map$unit_id, map$StndrdN)
diff_list <- function(pub, inS, why, row) {
  cor_units <- el$unit_id[inS]; pub_units <- unit_of[pub]
  a <- union(setdiff(pub, names(unit_of)[unit_of %in% cor_units]), pub[!is.na(unit_of[pub]) & unit_of[pub] != pub])
  b <- union(setdiff(cor_units, pub_units), grep("_", cor_units, value = TRUE))
  rbind(
    if (length(a)) data.frame(row = row, unit = a, direction = "published only", reason = sapply(a, function(s) {
      u <- unit_of[s]; if (is.na(u)) "no Phillips rate" else if (!map$eligible[map$StndrdN == s]) "ineligible (borrowed rate)"
      else if (u != s) paste0("dissolved into ", u) else paste0("missing: ", why[el$unit_id == u]) })),
    if (length(b)) data.frame(row = row, unit = b, direction = "corrected only", reason = sapply(b, function(u) {
      if (grepl("_", u)) paste0("dissolved unit (members ", el$members[el$unit_id == u], ")")
      else if (!u %in% ad$StndrdN[!is.na(ad$black_share1911.x)]) "restored: no 1911 covariates in the authors' construction"
      else if (!u %in% pub) "restored" else "other" })))
}
dl <- rbind(diff_list(pub1, el$in_H1, el$why_out_H1, "H1"), diff_list(pub3, el$in_H3, el$why_out_H3, "H3"))
oth <- el |> filter(!in_H1) |> transmute(row = "H1", unit = unit_id, direction = "eligible but excluded", reason = paste0("missing: ", why_out_H1))
dl <- rbind(dl, oth, el |> filter(!in_H3) |> transmute(row = "H3", unit = unit_id, direction = "eligible but excluded", reason = paste0("missing: ", why_out_H3)))
dl <- rbind(dl, data.frame(row = "both", unit = c(no_rate, borrowed), direction = "ineligible",
                           reason = c(rep("no Phillips rate", length(no_rate)), "borrowed rate (Umzimkulu, Transkei)")))
write.csv(dl, file.path(OUT, "build_unit_differences.csv"), row.names = FALSE)

# Diagnostics (district-level open aggregates)
diag <- el |> transmute(unit_id, members, area_km2, coverage_1970, coverage_1937, missing_share_B, missing_share_C,
                        missing_share_T, missing_share_urate, rail_source, in_H1, in_H3)
write.csv(diag, file.path(OUT, "build_coverage_by_unit.csv"), row.names = FALSE)
mcs <- rbind(b1911_U$mc, b1911_PG$mc, b1936_U$mc, b1936_PG$mc)
write.csv(mcs, file.path(OUT, "build_mass_conservation.csv"), row.names = FALSE)
outs <- b1911_U$outside |> filter(share_outside > 1e-4) |> arrange(desc(mass_outside))
write.csv(outs, file.path(OUT, "build_mass_outside_1918.csv"), row.names = FALSE)
q <- function(x) sprintf("min %.4f p05 %.4f median %.4f max %.4f", min(x, na.rm = TRUE), quantile(x, .05, na.rm = TRUE), median(x, na.rm = TRUE), max(x, na.rm = TRUE))
say("Coverage 1970 layer (eligible units): ", q(el$coverage_1970))
say("Coverage 1937 layer (eligible units): ", q(el$coverage_1937))
say("Units with any missing-source area: B ", sum(el$missing_share_B > 0), ", C ", sum(el$missing_share_C > 0), ", T ", sum(el$missing_share_T > 0),
    ", urate ", sum(el$missing_share_urate > 0, na.rm = TRUE), " (max share ", signif(max(el$missing_share_urate, na.rm = TRUE), 3), ")")
say("Mass conservation: max relative discrepancy ", signif(max(mcs$rel_discrepancy), 3), " (stop above 1e-6)")
# Corrected vs authors' regressors (common units)
cmpv <- el |> filter(in_H1, unit_id %in% pub1) |> left_join(ad |> select(StndrdN, a_b = black_share1911.x, a_d = density_1911.x), by = c("unit_id" = "StndrdN"))
say(sprintf("Corrected vs authors' (common %d units): cor black share %.4f, mean |diff| %.4f, max |diff| %.3f; cor log1p density %.4f",
            nrow(cmpv), cor(cmpv$black_share, cmpv$a_b), mean(abs(cmpv$black_share - cmpv$a_b)), max(abs(cmpv$black_share - cmpv$a_b)),
            cor(log1p(cmpv$density), log1p(cmpv$a_d))))
summ <- el |> filter(in_H1) |> summarise(across(c(deaths, black_share, col_share, density, rail_km, rain), list(mean = mean, sd = sd, min = min, max = max)))
write.csv(tidyr::pivot_longer(summ, everything()), file.path(OUT, "build_summary_H1_sample.csv"), row.names = FALSE)

saveRDS(list(units = units, polys = polys, map = map, el = el, pub1 = pub1, pub3 = pub3, unit_of = unit_of,
             auth_dens_groups = j70 |> st_drop_geometry() |> select(DISTRICT, StndrdN, TDENS_11, T1911, B_1911, C_1911)),
        file.path(SCR, "units.rds"))
writeLines(log_lines, file.path(OUT, "build_log.txt"))
cat("01_build done\n")
