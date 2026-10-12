# P28_VFF  S3 independent R recreation - 03_figures.R (optional maps)
# Choropleths of Homeland share, logged 2011 unemployment and logged 2011 lights
# on 1911 district polygons (cf. Figs 1-3). Districts are linked to polygons by
# point-in-polygon of the analysis-file centroids.
suppressPackageStartupMessages({ library(tidyverse); library(sf); library(here) })
set.seed(20261011)
root <- here::here()
if (!dir.exists(file.path(root, "P28_VFF"))) stop("Run from the Fourie_ReplicateMe root")
pdir <- file.path(root, "P28_VFF"); rdir <- file.path(pdir, "repro_r")
source(file.path(root, "tools", "paths.R"))   # A6: data root on D:
an <- readRDS(dscratch("P28_VFF", "repro_r", "analysis.rds"))
sf_use_s2(FALSE)
dc <- st_read(dpath("P28_VFF", "original", "Reversal of Fortunes", "1911_dc.shp"), quiet = TRUE) |>
  mutate(poly_id = row_number())
pts <- st_as_sf(an, coords = c("lon", "lat"), crs = st_crs(dc))
lk <- suppressMessages(st_join(pts, dc |> select(poly_id), join = st_within)) |>
  st_drop_geometry() |> distinct(id, .keep_all = TRUE)
mp <- dc |> left_join(lk |> select(poly_id, Homeland, Unem2011, Light2011), by = "poly_id")

leap_theme <- theme_void(base_size = 10) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold"))
vars <- c(Homeland = "Homeland share", Unem2011 = "log broad unemployment 2011",
          Light2011 = "log night lights 2011")
for (v in names(vars)) {
  g <- ggplot(mp) + geom_sf(aes(fill = .data[[v]]), colour = "grey70", linewidth = 0.1) +
    scale_fill_viridis_c(option = "cividis", na.value = "grey95", name = NULL) +
    labs(title = vars[[v]], caption = "1911 districts; grey = outside 138-district sample") + leap_theme
  ggsave(file.path(rdir, "output", paste0("map_", v, ".pdf")), g, width = 6, height = 5)
  ggsave(file.path(rdir, "output", paste0("map_", v, ".png")), g, width = 6, height = 5, dpi = 300)
}
cat("Linked", sum(!is.na(lk$poly_id)), "of", nrow(an), "districts to polygons\n")
