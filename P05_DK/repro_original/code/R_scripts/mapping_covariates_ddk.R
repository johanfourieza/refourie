##Run after predicting_mortality_analysis_ddk.R. Requires analysis_data object.
library(tidyverse)
library(sf)
# [ENV P3] not installed / retired from CRAN: library(tmap)
# [ENV P3] not installed / retired from CRAN: library(rgdal)
# [ENV P3] not installed / retired from CRAN: library(raster)
# [ENV P3] not installed / retired from CRAN: library(rgeos)

setwd("C:\\Users\\Daniel\\Dropbox (Personal)\\Shared_projects\\Spanish_flu_group_folder")

mapdat = analysis_data
railways_full = st_read("data\\original\\spatial\\railways_1907\\1907_TrainTracks.shp")
st_crs(railways_full) = st_crs(mapdat)
st_crs(railways_full) == st_crs(mapdat)

railways = railways_full[railways_full$Legend!="Do. under construction authorised or proposed",]
st_crs(railways) == st_crs(mapdat)

mapdat = mapdat[is.na(mapdat$mag_dist_1918.x)==F,]

#Black Share
png("outputs\\maps\\map_black_share_1911_sfludeaths_per_1000.png",  width=2700, height=2300)
tm_shape(mapdat) +
  tm_polygons("black_share1911.x", title = "Black Pop. Share (1911)", palette = "Greys", colorNA = "honeydew3") + 
  tm_dots(size = "deaths_sflu_per_1000", scale=5, title.size="Influenza Deaths Per 1000", legend.size.is.portrait=T,
          col="red", alpha = .65, shape = 19) + 
  tm_layout(main.title = "1911 Black Pop. Share and 1918 Influenza Mortality",
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

#Coloured Share
png("outputs\\maps\\map_coloured_share_1911_sfludeaths_per_1000.png",  width=2700, height=2300)
tm_shape(mapdat) +
  tm_polygons("col_share1911.x", title = "Coloured Pop.  Share  (1911)", palette = "Greys", colorNA = "honeydew3") + 
  tm_dots(size = "deaths_sflu_per_1000", scale=5, title.size="Influenza Deaths Per 1000", legend.size.is.portrait=T,
          col="red", alpha = .65, shape = 19) + 
  tm_layout(main.title = "1911 Coloured Pop. Share and 1918 Influenza Mortality",
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

#Density
png("outputs\\maps\\map_pop_density_1911_sfludeaths_per_1000.png",  width=2700, height=2300)
tm_shape(mapdat) +
  tm_polygons("log_density_1911", title = "Log(1 + Pop. Density (1911))", palette = "Purples", colorNA = "honeydew3") + 
  tm_dots(size = "deaths_sflu_per_1000", scale=5, title.size="Influenza Deaths Per 1000", legend.size.is.portrait=T,
          col="red", alpha = .65, shape = 19) + 
  tm_layout(main.title = "1911 Pop. Density and 1918 Influenza Mortality",
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

#Rain
png("outputs\\maps\\map_rainfall_19101950_sfludeaths_per_1000.png",  width=2700, height=2300)
tm_shape(mapdat) +
  tm_polygons("rainfall_sepoctmean19101950", title = "Avg. Sept/Oct Rain in Cm (1910-1950)", palette = "Blues", colorNA = "honeydew3") + 
  tm_dots(size = "deaths_sflu_per_1000", scale=5, title.size="Influenza Deaths Per 1000", legend.size.is.portrait=T,
          col="red", alpha = .65, shape = 19) + 
  tm_layout(main.title = "Average Sept/Oct Rainfall and 1918 Influenza Mortality",
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

#Railways
png("outputs\\maps\\map_railways_1907_sfludeaths_per_1000.png",  width=2700, height=2300)
tm_shape(mapdat) +
  tm_polygons("log_rail_mdcentroid_to_nearestrail_km", title = "Log(1 + Distance to Rail in Km (1907))", palette = "seq", colorNA = "honeydew3") + 
  tm_dots(size = "deaths_sflu_per_1000", scale=5, title.size="Influenza Deaths Per 1000", legend.size.is.portrait=T,
          col="red", alpha = .65, shape = 19) + 
  tm_shape(railways) + 
  tm_lines(lwd = 4, lty=3, col="black", alpha=.8) + 
  tm_add_legend(type = c("line"),title = "Railway Lines, 1907",
                lwd = 4, lty=3, col="black", alpha=.8) +
  tm_layout(main.title = "1907 Railways and 1918 Influenza Mortality",
            main.title.position = "center",
            main.title.color = "black",
            main.title.size = 5.5,
            inner.margins=c(.04,.03, .02, .01), 
            title = c(""),
            title.color = "red",
            #panel.labels = c(""),
            #panel.label.color = "purple",
            aes.palette = list(seq = "-Greens"),
            legend.text.color = "grey1",
            legend.title.size = 4,
            legend.text.size = 3, 
            frame = FALSE)
dev.off()


#Regions
png("outputs\\maps\\map_regions_19101950_sfludeaths_per_1000.png",  width=2700, height=2300)
tm_shape(mapdat) +
  tm_polygons("region.x", title = "South African Regions in 1918", colorNA = "honeydew3", alpha=.15, 
              palette="Set1") +
  tm_dots(size = "deaths_sflu_per_1000", scale=5, title.size="Influenza Deaths Per 1000", legend.size.is.portrait=T,
          col="red", alpha = .65, shape = 16) + 
  tm_layout(#main.title = "South African 1918 Spanish Flu Mortality",
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


#Regions for Johan, custom 3 Jan 2022
mapdat$cape = ifelse(mapdat$region.x=='Cape', "Cape Province", "Rest of South Africa")
mapdat$mag_dist_1918.x[mapdat$sq_metres== min(mapdat$sq_metres[mapdat$mag_dist_1918.x=='Paarl/ Wellington'])] = 'Wellington'
mapdat$highlight = ifelse(mapdat$mag_dist_1918.x %in% c("Oudtshoorn/ Calitzdorp", 
                                                        "Queenstown/ Sterkstroom",
                                                        "Paarl/ Wellington", 
                                                        "Stellenbosch/ Somerset West", 
                                                        "Cradock", 
                                                        "Stockenstrom", 
                                                        "Peddie",
                                                        "Mafeking", 
                                                        "Komgha", 
                                                        "Riversdale", 
                                                        "Kuruman", 
                                                        "Fraserburg/ Williston", 
                                                        "Vryburg", 
                                                        "Elliot", 
                                                        "Sea Point",
                                                        "Cape Town (incl. Durbanville)"), 1, 0)

sum(mapdat$highlight) #Should equal 15 -- for some reason Paarl/Wellington is duped

png("outputs\\maps\\map_regions_19101950_sfludeaths_per_1000_custom.png",  width=2700, height=2300)
tm_shape(mapdat) +
  tm_polygons("cape", title="Region", colorNA = "honeydew3", alpha=.15) +
  tm_dots(size = "deaths_sflu_per_1000", scale=5, title.size="Influenza Deaths Per 1000", legend.size.is.portrait=T,
          col="red", alpha = .65, shape = 16) + 
tm_shape(mapdat[mapdat$highlight==1,]) +
  tm_borders(lwd=5) +
 # tm_text("mag_dist_1918.x") +
  tm_layout(main.title = "South African 1918 Flu Mortality",
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

