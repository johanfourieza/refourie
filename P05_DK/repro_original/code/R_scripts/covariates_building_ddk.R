library(tidyverse)
library(readxl)
library(ggrepel)
library(sf)
# [ENV P3] not installed / retired from CRAN: library(tmap)
# [ENV P3] not installed / retired from CRAN: library(rgdal)
# [ENV P3] not installed / retired from CRAN: library(raster)
# [ENV P3] not installed / retired from CRAN: library(rgeos)
# [ENV P3] not installed / retired from CRAN: library(extrafont)

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

censusdata = read.csv("data\\processed\\census\\census_covariates_1911.csv")
raildata = read.csv("data\\processed\\spatial\\railway_covariates_1907.csv")
raindata = read.csv("data\\processed\\rainfall\\rainfall_septoct_1918.csv")

covariates = full_join(censusdata, raildata, by="StndrdN")
covariates = full_join(covariates, raindata, by="StndrdN")
colnames(covariates)[1] = "mag_dist_1918"
covariates =  subset(covariates, select = -c(mag_dist_1918.y))

write_csv(covariates, path = "data\\processed\\all_covariates.csv")



