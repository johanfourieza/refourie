# P28_VFF  S3 independent R recreation - 01_clean.R
# von Fintel & Fourie (2019, JCE) "The great divergence in South Africa"
# Builds the analysis frame (138 districts on 1911 boundaries) from the shared
# analysis file data.dta, maps paper variables to file variables (see
# decisions.md), adds 1911-district centroids and cross-checks Pop1911 against
# the raw 1911 census return.
suppressPackageStartupMessages({
  library(tidyverse); library(haven); library(sf); library(readxl); library(here)
})
set.seed(20261011)
root <- here::here()   # project root; paper folder below
if (!dir.exists(file.path(root, "P28_VFF"))) stop("Run from the Fourie_ReplicateMe root")
pdir <- file.path(root, "P28_VFF")
source(file.path(root, "tools", "paths.R"))   # A6: data root on D:
odir <- dpath("P28_VFF", "original", "Reversal of Fortunes")
rdir <- file.path(pdir, "repro_r")
dir.create(file.path(rdir, "output"), showWarnings = FALSE)
invisible(dscratch("P28_VFF", "repro_r"))   # A6: scratch on D:

raw  <- read_dta(file.path(odir, "data.dta"))
rcsv <- read.csv(file.path(odir, "data.csv"))
stopifnot(nrow(raw) == 138, all(raw$sample == 1),
          setequal(raw$id, rcsv$id[rcsv$sample %in% 1]))

# ---- variable mapping (paper name -> file variable; chosen by label/definition)
an <- raw |>
  transmute(
    id, district,
    Settle1830 = bl100,          # label "Settle1830"; binary (alt: settled1830 share, bl90..bl50)
    Pop1911    = l_pop1911,      # = log(popdens1911)
    Pop1996    = l_pop1996,      # = log(p_96/area)
    Pop2011    = l_pop2011,      # = log(popdens2011)
    Unem1996   = l_u1996,        # = log(u_96)   (alt: u_96_old)
    Unem2011   = l_u2011,        # = log(urate2011)  (alt: l_u11 = log(u_11), same label)
    Light1996  = l_lights96,     # = log(lig96)
    Light2011  = l_lights11,     # = log(lig11)  (alt: log(lights2011))
    Rain       = rain_level,     # label "Rain", mm (alt: l_rain)
    Rugged     = tri,            # label "Rugged" (alt: l_tri)
    Soil       = csi,            # label "Caloric Suitability" (alt: l_csi)
    Homeland   = p_homeland,     # label "Homeland", share of area
    NetMig11   = l_netmig_11,    # = asinh(nm_11_raw), label "NetMig11"
    Unem2011_alt  = l_u11,
    Unem1996_alt  = log(u_96_old),
    Light2011_alt = log(lights2011),
    lon = x_cent, lat = y_cent   # label "x/y-coordinate of area centroid" (degrees)
  )

# ---- centroid cross-check against the 1911 district polygon layer
dc <- st_read(file.path(odir, "1911_dc.shp"), quiet = TRUE)
sf_use_s2(FALSE)
cen <- suppressWarnings(st_centroid(dc)) |>
  mutate(lon_shp = st_coordinates(geometry)[, 1], lat_shp = st_coordinates(geometry)[, 2]) |>
  st_drop_geometry() |> select(NAME, lon_shp, lat_shp)
chk_c <- an |> select(district, lon, lat) |>
  inner_join(cen |> add_count(NAME) |> filter(n == 1), by = c("district" = "NAME")) |>
  mutate(dkm = sqrt(((lon - lon_shp) * 111 * cos(lat * pi / 180))^2 + ((lat - lat_shp) * 111)^2))
cat("Centroid check: matched", nrow(chk_c), "districts; median/max distance (km):",
    round(median(chk_c$dkm), 2), round(max(chk_c$dkm), 2), "\n")

# ---- Pop1911 cross-check against raw 1911 census return (Bantu persons / area)
cx <- read_excel(file.path(odir, "Census 1911.xlsx"), sheet = "Return of Population",
                 col_names = FALSE, .name_repair = "minimal")
cx <- as.data.frame(cx)[, c(2, 10:13)]
names(cx) <- c("name", "bum", "buf", "brm", "brf")
cx <- cx |> filter(!is.na(name)) |>
  mutate(across(bum:brf, ~ suppressWarnings(as.numeric(.x))),
         bantu = rowSums(across(bum:brf), na.rm = TRUE),
         name = str_trim(name)) |>
  add_count(name) |> filter(n == 1)
chk_p <- raw |> select(district, area, popdens1911) |>
  inner_join(cx, by = c("district" = "name")) |>
  mutate(dens_raw = bantu / area, rel = dens_raw / popdens1911 - 1)
cat("Pop1911 check: matched", nrow(chk_p), "of 138 by exact name; share within 1%:",
    round(mean(abs(chk_p$rel) < 0.01), 3), "\n")
write_csv(chk_p |> select(district, area, popdens1911, bantu, dens_raw, rel),
          dscratch("P28_VFF", "repro_r", "check_pop1911.csv"))

saveRDS(an, dscratch("P28_VFF", "repro_r", "analysis.rds"))
write_csv(an, file.path(rdir, "output", "analysis_frame.csv"))
