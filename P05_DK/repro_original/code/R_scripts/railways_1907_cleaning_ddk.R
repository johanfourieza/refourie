##Run after census_1904_1970_cleaning_ddk.R Requires plotdat object.
library(tidyverse)
library(readxl)
library(ggrepel)
library(sf, sp)
# [ENV P3] not installed / retired from CRAN: library(tmap)
# [ENV P3] not installed / retired from CRAN: library(rgdal)
# [ENV P3] not installed / retired from CRAN: library(raster)
# [ENV P3] not installed / retired from CRAN: library(rgeos)
# [ENV P3] not installed / retired from CRAN: library(extrafont)
# [ENV P3] not installed / retired from CRAN: library(rmapshaper)

#Global Options
options(scipen = 999) 
options(pillar.sigfig = 5)
options(warn=-1)

#Fonts
# [ENV P4] extrafont not installed: loadfonts(device = "win")

#ggplot theme
source(file.path(Sys.getenv("P05_REPRO"), "env_patch", "theme_ddk.R")) # [ENV P1] was: source("C:\\Users\\ddeka\\Dropbox\\theme_ddk.R")

#Set working directories
setwd(Sys.getenv("P05_WORK")) # [ENV P2] was: setwd("C:\\Users\\ddeka\\Dropbox\\Shared_projects\\Spanish_flu_group_folder")

mapdat = plotdat
railways_full = st_read("data\\original\\spatial\\railways_1907\\1907_TrainTracks.shp")
st_crs(railways_full) = st_crs(mapdat)
st_crs(railways_full) == st_crs(mapdat)

railways = railways_full[railways_full$Legend!="Do. under construction authorised or proposed",]
st_crs(railways) == st_crs(mapdat)

ints = st_intersection(railways, mapdat[,c("mag_dist_1918")])
ints$seg_length = st_length(ints)

raillengths = 
  ints %>%
  group_by(mag_dist_1918) %>%
    summarise(rail_length_km = sum(seg_length, na.rm=T))

raillengths_dta = as.data.frame(raillengths)

mapdat = full_join(mapdat, raillengths_dta, by="mag_dist_1918")
mapdat$rail_length_km = ifelse(is.na(mapdat$rail_length_km)==T, 0, mapdat$rail_length_km/1000)
mapdat$sq_kmetres = mapdat$sq_metres/1000000
mapdat$rail_length_km_p_sq_km = mapdat$rail_length_km/mapdat$sq_kmetres

mapdat$rail_dummy = ifelse(mapdat$rail_length_km>0, 1, 0)

mapdat_centroids =  st_transform(mapdat) %>% 
  st_centroid() 

mapdat_raildistances = st_distance(railways, mapdat_centroids)
mapdat_raildistances_min = apply(mapdat_raildistances,2,min)
#Convert to km
mapdat_raildistances_min_km = mapdat_raildistances_min/1000

#Rejoin to data
mapdat$rail_mdcentroid_to_nearestrail_km = mapdat_raildistances_min_km

#Check:
#tm_shape(mapdat) +
#  tm_polygons("railway_length_psqkm", title = "Deaths from Spanish Flu per 1000", palette = "Reds", colorNA = "honeydew3") + 
#  tm_shape(railways) + 
#  tm_lines(lwd = 4, lty=3, col="black", alpha=.8)


png("outputs\\maps\\map_railways_sfludeaths_per_1000.png",  width=2700, height=2300)
tm_shape(mapdat) +
  tm_polygons("deaths_sflu_per_1000", title = "Deaths from Spanish Flu per 1000", palette = "Reds", colorNA = "honeydew3") + 
  tm_shape(railways) + 
  tm_lines(lwd = 4, lty=3, col="black", alpha=.8) + 
  tm_add_legend(type = c("line"),title = "Railway Lines, 1907",
                lwd = 4, lty=3, col="black", alpha=.8) + 
   tm_layout(main.title = "Deaths from Spanish Flu per 1000 and 1907 Railway Lines",
            main.title.position = "center",
            main.title.color = "black",
            main.title.size = 5.5,
            inner.margins=c(.04,.03, .02, .01), 
            title = c(""),
            title.color = "red",
            #panel.labels = c(""),
            #panel.label.color = "purple",
            legend.text.color = "grey1",
            legend.title.size = 4,
            legend.text.size = 3, 
            frame = FALSE)
dev.off()

mapdata$log_rail_mdcentroid_to_nearestrail_km = log(mapdata$log_rail_mdcentroid_to_nearestrail_km)

png("outputs\\maps\\map_railway_proximity_sfludeaths_per_1000.png",  width=2700, height=2300)
tm_shape(mapdat) +
  tm_polygons("log_rail_mdcentroid_to_nearestrail_km", title = "Log(1 + Km Distance to Rail)", palette = "seq", colorNA = "honeydew3") + 
  tm_dots(size = "deaths_sflu_per_1000", scale=5, title.size="Spanish Flu Deaths Per 1000", legend.size.is.portrait=T,
          col="red", alpha = .65, shape = 19) + 
  tm_layout(main.title = "Railway Proximity and 1918 Spanish Flu Mortality",
            main.title.position = "center",
            main.title.color = "black",
            main.title.size = 5.5,
            inner.margins=c(.04,.03, .02, .01), 
            title = c(""),
            title.color = "red",
            aes.palette = list(seq = "-Greys"),
            #panel.labels = c(""),
            #panel.label.color = "purple",
            legend.text.color = "grey1",
            legend.title.size = 4,
            legend.text.size = 3, 
            frame = FALSE)
dev.off()

png("outputs\\maps\\map_railway_density_sfludeaths_per_1000.png",  width=2700, height=2300)
tm_shape(mapdat) +
  tm_polygons("rail_length_km_p_sq_km", title = "Km Rail Length Per Square Km", palette = "seq", colorNA = "honeydew3") + 
  tm_dots(size = "deaths_sflu_per_1000", scale=5, title.size="Spanish Flu Deaths Per 1000", legend.size.is.portrait=T,
          col="red", alpha = .65, shape = 19) + 
  tm_layout(main.title = "Railway Density and 1918 Spanish Flu Mortality",
            main.title.position = "center",
            main.title.color = "black",
            main.title.size = 5.5,
            inner.margins=c(.04,.03, .02, .01), 
            title = c(""),
            title.color = "red",
            aes.palette = list(seq = "-Greys"),
            #panel.labels = c(""),
            #panel.label.color = "purple",
            legend.text.color = "grey1",
            legend.title.size = 4,
            legend.text.size = 3, 
            frame = FALSE)
dev.off()


summary(lm(deaths_sflu_per_1000 ~ rail_length_km + factor(region), data=mapdat))
summary(lm(deaths_sflu_per_1000 ~ rail_length_km_p_sq_km + factor(region), data=mapdat))
summary(lm(deaths_sflu_per_1000 ~ rail_dummy + factor(region), data=mapdat))
summary(lm(deaths_sflu_per_1000 ~ rail_mdcentroid_to_nearestrail_km + factor(region), data=mapdat))

saveraildata = as.matrix(mapdat[,c("mag_dist_1918", "StndrdN", 
                     "rail_length_km", "rail_length_km_p_sq_km", 
                     "rail_dummy", "rail_mdcentroid_to_nearestrail_km")])
saveraildata = as.data.frame(saveraildata[,c(1:6)])

saveraildata$mag_dist_1918 = as.character(saveraildata$mag_dist_1918)
saveraildata$StndrdN = as.character(saveraildata$StndrdN)
saveraildata$rail_length_km = as.numeric(saveraildata$rail_length_km)
saveraildata$rail_length_km_p_sq_km = as.numeric(saveraildata$rail_length_km_p_sq_km)
saveraildata$rail_dummy = as.numeric(saveraildata$rail_dummy)
saveraildata$rail_mdcentroid_to_nearestrail_km = as.numeric(saveraildata$rail_mdcentroid_to_nearestrail_km)

write_csv(saveraildata, path = "data\\processed\\spatial\\railway_covariates_1907.csv")

