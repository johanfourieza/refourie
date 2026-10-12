library(tidyverse)
library(readxl)
library(ggrepel)
library(sf)
# [ENV P3] not installed / retired from CRAN: library(tmap)
# [ENV P3] not installed / retired from CRAN: library(rgdal)
# [ENV P3] not installed / retired from CRAN: library(raster)
# [ENV P3] not installed / retired from CRAN: library(rgeos)
# [ENV P3] not installed / retired from CRAN: library(extrafont)
library(estimatr)

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

##########EUROPEAN POPULATION DATA###########
european_ages_1936 = read_excel("data\\original\\census\\census1936\\Table 7; Ages in years of Europeans, by gender, at MD level..xlsx", col_types = "text")

european_ages_1936 = subset(european_ages_1936, is.na(european_ages_1936[,2])!=T)
#european_ages_1936 = subset(european_ages_1936, is.na(european_ages_1936[,3])!=T)
european_ages_1936 = subset(european_ages_1936, select= -c(42,43))

colnames(european_ages_1936) = c("mag_dist_1936", "sex", as.character(c(seq(0,21,1),25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100)), "unknown", "total_pop")

european_ages_1936 =
  european_ages_1936 %>%
  fill(mag_dist_1936, .direction="down")

european_ages_1936 = european_ages_1936[-grep("TOTAL", european_ages_1936$mag_dist_1936),]

european_ages_1936[,is.na(c(3:41))] = 0 

european_ages_1936_keepers = european_ages_1936[,c(1, 2, 18:33)]

#Check for no issues:
duplicatetable = summarise(group_by(european_ages_1936,mag_dist_1936),length(mag_dist_1936))
duplicatetable$mag_dist_1936[duplicatetable$`length(mag_dist_1936)`>3]

european_ages_1936_p = european_ages_1936_keepers[european_ages_1936_keepers$sex=="P",]
european_ages_1936_p[,c(3:18)] = unlist(european_ages_1936_p[,c(3:18)])
european_ages_1936_p$total_workingage_pop_w = NA
for(i in 1:nrow(european_ages_1936_p)){
  european_ages_1936_p$total_workingage_pop_w[i] = sum(as.numeric(as.character(european_ages_1936_p[i,c(3:18)])), na.rm=T)
}
  
european_ages_1936_p = european_ages_1936_p[,c(1, 19)]

european_ages_1936_f = european_ages_1936_keepers[european_ages_1936$sex=="F",]
european_ages_1936_f[,c(3:18)] = unlist(european_ages_1936_f[,c(3:18)])
european_ages_1936_f$total_workingage_pop_w_f = NA
for(i in 1:nrow(european_ages_1936_f)){
  european_ages_1936_f$total_workingage_pop_w_f[i] = sum(as.numeric(as.character(european_ages_1936_f[i,c(3:18)])), na.rm=T)
}
european_ages_1936_f = european_ages_1936_f[,c(1, 19)]

european_ages_1936_m = european_ages_1936_keepers[european_ages_1936$sex=="M",]
european_ages_1936_m[,c(3:18)] = unlist(european_ages_1936_m[,c(3:18)])
european_ages_1936_m$total_workingage_pop_w_m = NA
for(i in 1:nrow(european_ages_1936_f)){
  european_ages_1936_m$total_workingage_pop_w_m[i] = sum(as.numeric(as.character(european_ages_1936_m[i,c(3:18)])), na.rm=T)
}
european_ages_1936_m = european_ages_1936_m[,c(1, 19)]

##########ECONOMIC DATA###########
unemployment_1936 = read_excel("data\\original\\census\\census1936\\Table 1_ Unemployment, by gender and race, at MD level.xlsx")

unemployment_1936 = subset(unemployment_1936, is.na(unemployment_1936[,1])!=T)
unemployment_1936 = subset(unemployment_1936, is.na(unemployment_1936[,2])!=T)
unemployment_1936 = unemployment_1936[-c(1:5),]

colnames(unemployment_1936) = c("mag_dist_1936", "unemployed_w_m", "unemployed_w_f", "unemployed_w_t",
                                "unemployed_c_m", "unemployed_c_f", "unemployed_c_t",
                                "unemployed_a_m", "unemployed_a_f", "unemployed_a_t",
                                "unemployed_tot_m", "unemployed_tot_f", "unemployed_tot_t")

unemployment_1936 = unemployment_1936[-grep("TOTAL", unemployment_1936$mag_dist_1936),]

unemployment_1936[,c(2:ncol(unemployment_1936))] = as.numeric(unlist(unemployment_1936[,c(2:ncol(unemployment_1936))]))

unemployment_1936 = unemployment_1936 %>% replace(is.na(.), 0)

##########MERGING############
census_1936 = full_join(unemployment_1936, european_ages_1936_p , by="mag_dist_1936")
census_1936 = full_join(census_1936, european_ages_1936_f, by="mag_dist_1936")
census_1936 = full_join(census_1936, european_ages_1936_m, by="mag_dist_1936")

#########SPATIAL MERGE#######
#### MERGING DATASETS
##Spatial join to reconcile geographies
mag1937_shp = st_read("data\\original\\spatial\\1937.shp")
mag1937_shp$OrgnlNm = as.character(mag1937_shp$OrgnlNm)

mag1937_shp$OrgnlNm[mag1937_shp$StndrdN=="middelburg c"] = "Middleburg C"
mag1937_shp$OrgnlNm[mag1937_shp$StndrdN=="middelburg t"] = "Middleburg T"
mag1937_shp$OrgnlNm[mag1937_shp$StndrdN=="richmond c"] = "Richmond C"
mag1937_shp$OrgnlNm[mag1937_shp$StndrdN=="richmond n"] = "Richmond N"

mag1918_shp = st_read("data\\original\\spatial\\SA_1918.shp")
mag1918_shp$OrgnlNm = as.character(mag1918_shp$OrgnlNm)
mag1918_shp$StndrdN = as.character(mag1918_shp$StndrdN)

mag1918_shp = st_transform(mag1918_shp, st_crs(mag1937_shp))
st_crs(mag1937_shp) == st_crs(mag1918_shp)

tm_shape(mag1937_shp) +
  tm_borders(alpha=1, col="red") + 
  tm_shape(mag1929_shp) +
  tm_borders(alpha=.5, col="blue", lty=3) 

mag19181937_shp = st_join(mag1937_shp, mag1918_shp, join = st_intersects, largest=T)

mag19181937_key = as_tibble(cbind(as.character(mag19181937_shp$OrgnlNm.x), as.character(mag19181937_shp$OrgnlNm.y), as.character(mag19181937_shp$StndrdN.y)))
colnames(mag19181937_key) = c("mag_dist_1937", "mag_dist_1918", "StndrdN")

###MATCHING NAMES
distinct_OrgnlNm = unique(census_1936$mag_dist_1936)

mag19181937_key$mag_dist_1937 = as.character(mag19181937_key$mag_dist_1937)

matchnum = list()
multiples = c()
for(i in 1:length(distinct_OrgnlNm)){
  matchnum[[i]] = agrep(distinct_OrgnlNm[i], mag19181937_key$mag_dist_1937)
  multiples[i] = length(matchnum[[i]])
}

distinct_OrgnlNm = data.frame(distinct_OrgnlNm)
colnames(distinct_OrgnlNm) = "OrgnlNm"
distinct_OrgnlNm$OrgnlNm = as.character(distinct_OrgnlNm$OrgnlNm)
distinct_OrgnlNm$mag_dist_1937 = NA

multiples_index = which(multiples>1)
distinct_OrgnlNm$multi_index = ifelse(distinct_OrgnlNm$OrgnlNm %in% distinct_OrgnlNm$OrgnlNm[multiples_index], 1, 0)

for(i in 1:nrow(distinct_OrgnlNm)){
  if(distinct_OrgnlNm$multi_index[i] == 1 ){
    distinct_OrgnlNm$mag_dist_1937[i] = "FIX ME"
  } else if(length(matchnum[[i]])==0){
    distinct_OrgnlNm$mag_dist_1937[i] = "NO MATCH"
  } else{distinct_OrgnlNm$mag_dist_1937[i] = mag19181937_key$mag_dist_1937[matchnum[[i]]]
  }
}

census_1936 = full_join(census_1936, distinct_OrgnlNm, by = c("mag_dist_1936" = "OrgnlNm"))

#fix = (distinct_OrgnlNm$OrgnlNm[distinct_OrgnlNm$mag_dist_1937=="FIX ME"|distinct_OrgnlNm$mag_dist_1937=="NO MATCH"])[order(distinct_OrgnlNm$OrgnlNm[distinct_OrgnlNm$mag_dist_1937=="FIX ME"|distinct_OrgnlNm$mag_dist_1937=="NO MATCH"])]
#write.csv(fix, "data\\temporary\\spatial\\1936_census_mds_corrections.csv")

corrections_1936 = read.csv("data\\temporary\\spatial\\1936_census_mds_corrections_ddk.csv")

census_1936_merge = full_join(census_1936, corrections_1936, by="mag_dist_1936")
census_1936_merge$mag_dist_1937 = as.character(census_1936_merge$mag_dist_1937)
census_1936_merge$mag_dist_1936_correction = as.character(census_1936_merge$mag_dist_1936_correction)

census_1936_merge$mag_dist_1937[!is.na(census_1936_merge$mag_dist_1936_correction)] = NA
census_1936_merge$mag_dist_1936_correction[is.na(census_1936_merge$mag_dist_1936_correction)] = NA

census_1936_merge = 
  census_1936_merge %>% unite("mag_dist_1937", mag_dist_1937, mag_dist_1936_correction, na.rm = T, remove = FALSE, sep="")

census_1936_merge = inner_join(census_1936_merge, mag19181937_key, by="mag_dist_1937")

#Mortality data
mortality_data = 
  findat %>%
  dplyr::select(mag_dist_1918, StndrdN, total_deaths_sflu, deaths_sflu_per_1000, region)

census_1936_reduced =
  census_1936_merge %>%
    group_by(StndrdN) %>%
      summarise(total_workingage_pop_w = sum(total_workingage_pop_w), 
                total_workingage_pop_w_m = sum(total_workingage_pop_w_m), 
                total_workingage_pop_w_f = sum(total_workingage_pop_w_f), 
                unemployed_w_t = sum(unemployed_w_t),
                unemployed_w_m = sum(unemployed_w_m),
                unemployed_w_f = sum(unemployed_w_f))
  
census_1936_reduced = full_join(census_1936_reduced, mortality_data, by="StndrdN")
census_1936_reduced = full_join(census_1936_reduced, covariates, by="StndrdN")
census_1936_reduced$unemployment_rate_w = census_1936_reduced$unemployed_w_t/census_1936_reduced$total_workingage_pop_w
census_1936_reduced$unemployment_rate_w_f = census_1936_reduced$unemployed_w_f/census_1936_reduced$total_workingage_pop_w_f
census_1936_reduced$unemployment_rate_w_m = census_1936_reduced$unemployed_w_m/census_1936_reduced$total_workingage_pop_w_m



total_model = lm(unemployment_rate_w ~ log(deaths_sflu_per_1000) + 
            black_share1911 + col_share1911 + 
            log(1 + density_1911) + log(1 + rail_mdcentroid_to_nearestrail_km) + 
            rainfall_sepoctmean19101950 + factor(region.x), census_1936_reduced)

female_model = lm(unemployment_rate_w_f ~ log(deaths_sflu_per_1000) + 
            black_share1911 + col_share1911 + 
            log(1 + density_1911) + log(1 + rail_mdcentroid_to_nearestrail_km) + 
            rainfall_sepoctmean19101950 + factor(region.x), census_1936_reduced)

male_model = lm(unemployment_rate_w_m ~ log(deaths_sflu_per_1000) + 
            black_share1911 + col_share1911 + 
            log(1 + density_1911) + log(1 + rail_mdcentroid_to_nearestrail_km) + 
            rainfall_sepoctmean19101950 + factor(region.x), census_1936_reduced)

meansy = c(mean(census_1936_reduced$unemployment_rate_w,na.rm=T), mean(census_1936_reduced$unemployment_rate_w_f,na.rm=T), mean(census_1936_reduced$unemployment_rate_w_m,na.rm=T))

stargazer(total_model, female_model, male_model,  
          out="outputs\\tables\\reg_unemployment.tex",
          title            = "1918 Spanish Flu Mortality and Medium-Term Unemployment",
          covariate.labels = c("Log(Deaths/1000)",
                               "Black Pop. Share  (1911)", "Coloured Pop.  Share  (1911)", "Log(1 + Pop. Density (1911))",
                               "Log(1 + Distance to Rail in Km (1907))", "Avg. Sept/Oct Rain in Cm (1910-1950)"),
          dep.var.caption  = "Dependent Variable:",
          dep.var.labels   = c("U. Rate (Total)", "U. Rate (Women)", "U. Rate (Men)"),
          model.numbers    = FALSE, 
          add.lines = list(c("Dependent Variable Means", round(meansy,3)), 
                           c("Region Fixed Effects?", "Yes", "Yes", "Yes")),
          digits = 3,
          digits.extra=0,
          omit="region",
          omit.stat = c("adj.rsq", "ser"), 
          notes = c("HC2 Robust standard errors in parentheses."), 
          notes.align = "l")


