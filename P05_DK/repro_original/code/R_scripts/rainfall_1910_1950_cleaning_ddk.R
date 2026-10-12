library(tidyverse)
library(readxl)
library(ggrepel)
library(sf)
# [ENV P3] not installed / retired from CRAN: library(tmap)
# [ENV P3] not installed / retired from CRAN: library(rgdal)
# [ENV P3] not installed / retired from CRAN: library(raster)
# [ENV P3] not installed / retired from CRAN: library(rgeos)
library(ggpubr)
# [ENV P3] not installed / retired from CRAN: library(extrafont)

#Global Options
options(scipen = 999) 
options(pillar.sigfig = 5)

#Fonts
# [ENV P4] extrafont not installed: loadfonts(device = "win")

#ggplot theme
source(file.path(Sys.getenv("P05_REPRO"), "env_patch", "theme_ddk.R")) # [ENV P1] was: source("C:\\Users\\ddeka\\Dropbox\\theme_ddk.R")

#Set working direction
setwd(Sys.getenv("P05_WORK")) # [ENV P2] was: setwd("C:\\Users\\ddeka\\Dropbox\\Shared_projects\\Spanish_flu_group_folder")

#Call data
rainfall = read_csv("data\\original\\rainfall\\rain_monthly_1910-1950.csv")

rainfall_tosave = 
  rainfall %>%
  group_by(StndrdN) %>%
  summarise(rainfall_sep1918 = as.numeric(rain[year=="1918" & month=="9"]),
            rainfall_oct1918 = as.numeric(rain[year=="1918" & month=="10"]),
            rainfall_sepoct1918 = mean(as.numeric(rain[year=="1918" & (month=="9"|month=="10")])),
            rainfall_sepmean19101950 = mean(as.numeric(rain[month=="9"])),
            rainfall_octmean19101950 = mean(as.numeric(rain[month=="10"])), 
            rainfall_sepoctmean19101950 = mean(as.numeric(rain[month=="9"|month=="10"])))

write_csv(rainfall_tosave, path = "data\\processed\\rainfall\\rainfall_septoct_1918.csv")

mapdat = full_join(mapdat, rainfall_tosave, by="StndrdN")

summary(lm(deaths_sflu_per_1000 ~ rainfall_sepoct1918 + factor(region), data=mapdat))
summary(lm(deaths_sflu_per_1000 ~ rainfall_sep1918 + factor(region), data=mapdat))
summary(lm(deaths_sflu_per_1000 ~ rainfall_oct1918 + factor(region), data=mapdat))


