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

#Census data
nonwhite_ages_1936 = read_excel("data\\original\\census\\census1936\\Table 3 Ages in years of Native population by gender at MD level.xlsx")

nonwhite_ages_1936 = subset(nonwhite_ages_1936, is.na(nonwhite_ages_1936[,2])!=T)
nonwhite_ages_1936 = subset(nonwhite_ages_1936, select= -c(42,43))

colnames(nonwhite_ages_1936) = c("mag_dist_1936", "sex", as.character(c(seq(0,21,1),25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100)), "unknown", "total_pop")

nonwhite_ages_1936 =
  nonwhite_ages_1936 %>%
  fill(mag_dist_1936, .direction="down")

nonwhite_ages_1936 = nonwhite_ages_1936[-grep("TOTAL", nonwhite_ages_1936$mag_dist_1936),]

nonwhite_ages_1936[,is.na(c(3:41))] = 0 

#Census data
european_ages_1936 = read_excel("data\\original\\census\\census1936\\Table 7; Ages in years of Europeans, by gender, at MD level..xlsx")

european_ages_1936 = subset(european_ages_1936, is.na(european_ages_1936[,2])!=T)
#european_ages_1936 = subset(european_ages_1936, is.na(european_ages_1936[,3])!=T)
european_ages_1936 = subset(european_ages_1936, select= -c(42,43))

colnames(european_ages_1936) = c("mag_dist_1936", "sex", as.character(c(seq(0,21,1),25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100)), "unknown", "total_pop")

european_ages_1936 =
  european_ages_1936 %>%
  fill(mag_dist_1936, .direction="down")

european_ages_1936 = european_ages_1936[-grep("TOTAL", european_ages_1936$mag_dist_1936),]

european_ages_1936[,is.na(c(3:41))] = 0 

duplicatetable = summarise(group_by(european_ages_1936,mag_dist_1936),length(mag_dist_1936))
duplicatetable$mag_dist_1936[duplicatetable$`length(mag_dist_1936)`>3]

european_ages_1936[,3:ncol(european_ages_1936)] = as.numeric(unlist(european_ages_1936[,3:ncol(european_ages_1936)]))

european_ages_1936_national = european_ages_1936[european_ages_1936$sex=="P",]
european_ages_1936_national = colSums(european_ages_1936_national[,3:ncol(european_ages_1936_national)], na.rm=T)
european_ages_1936_national_births = european_ages_1936_national[-c(39,40)]

european_ages_1936_national_yob = 1936 - c(seq(0,21,1),25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100)

european_ages_1936_national  = as.data.frame(cbind(european_ages_1936_national_births, european_ages_1936_national_yob))
colnames(european_ages_1936_national) = c("births", "yob")

ggplot(european_ages_1936_national[european_ages_1936_national$yob>1915,], aes(x=yob, y=births)) +
  geom_point() + 
  geom_text_repel(aes(label=ifelse(yob==1918 | yob==1919, yob, "")), 
                  alpha=.75, min.segment.length = 0) +
  geom_smooth(se=F, alpha=.75) +  
  scale_y_continuous("Total Number of Births", limits = c(40000,60000)) + 
  scale_x_continuous("Birth Year (1918 and 1919 are the Birth Years of Spanish Flu)") +
  theme_bw() + 
  theme(legend.title = element_blank(), axis.line = element_line(colour = "black"),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.text.x = element_text(size=12),
        axis.text.y = element_text(size=12, angle=15),
        axis.title.x=element_text(size=13, vjust=.5),
        axis.title.y=element_text(size=13,angle=90,vjust=0))
ggsave("outputs\\figures\\census1936_births_whites.png", width = 9, height = 7)

#Men
european_ages_1936_national = european_ages_1936[european_ages_1936$sex=="M",]
european_ages_1936_national = colSums(european_ages_1936_national[,3:ncol(european_ages_1936_national)], na.rm=T)
european_ages_1936_national_births = european_ages_1936_national[-c(39,40)]

european_ages_1936_national_yob = 1936 - c(seq(0,21,1),25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100)

european_ages_1936_national  = as.data.frame(cbind(european_ages_1936_national_births, european_ages_1936_national_yob))
colnames(european_ages_1936_national) = c("births", "yob")

ggplot(european_ages_1936_national[european_ages_1936_national$yob>1915,], aes(x=yob, y=births)) +
  geom_point() + 
  geom_text_repel(aes(label=ifelse(yob==1918 | yob==1919, yob, "")), 
                  alpha=.75, min.segment.length = 0) +
  geom_smooth(se=F, alpha=.75) +  
  scale_y_continuous("Total Number of Male Births") + 
  scale_x_continuous("Birth Year (1918 and 1919 are the Birth Years of Spanish Flu)") +
  theme_bw() + 
  theme(legend.title = element_blank(), axis.line = element_line(colour = "black"),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.text.x = element_text(size=12),
        axis.text.y = element_text(size=12, angle=15),
        axis.title.x=element_text(size=13, vjust=.5),
        axis.title.y=element_text(size=13,angle=90,vjust=0))
ggsave("outputs\\figures\\census1936_births_white_men.png", width = 9, height = 7)

#Women
european_ages_1936_national = european_ages_1936[european_ages_1936$sex=="F",]
european_ages_1936_national = colSums(european_ages_1936_national[,3:ncol(european_ages_1936_national)], na.rm=T)
european_ages_1936_national_births = european_ages_1936_national[-c(39,40)]

european_ages_1936_national_yob = 1936 - c(seq(0,21,1),25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100)

european_ages_1936_national  = as.data.frame(cbind(european_ages_1936_national_births, european_ages_1936_national_yob))
colnames(european_ages_1936_national) = c("births", "yob")

ggplot(european_ages_1936_national[european_ages_1936_national$yob>1915,], aes(x=yob, y=births)) +
  geom_point() + 
  geom_text_repel(aes(label=ifelse(yob==1918 | yob==1919, yob, "")), 
                  alpha=.75, min.segment.length = 0) +
  geom_smooth(se=F, alpha=.75) +  
  scale_y_continuous("Total Number of Female Births") + 
  scale_x_continuous("Birth Year (1918 and 1919 are the Birth Years of Spanish Flu)") +
  theme_bw() + 
  theme(legend.title = element_blank(), axis.line = element_line(colour = "black"),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.text.x = element_text(size=12),
        axis.text.y = element_text(size=12, angle=15),
        axis.title.x=element_text(size=13, vjust=.5),
        axis.title.y=element_text(size=13,angle=90,vjust=0))
ggsave("outputs\\figures\\census1936_births_white_women.png", width = 9, height = 7)



#Total population
european_ages_1936_p = european_ages_1936_merged[european_ages_1936_merged$sex=="P",]
european_ages_1936_yob = 1936 - c(seq(0,21,1),25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100)

colnames(european_ages_1936_p)[3:length(european_ages_1936_yob)]  = european_ages_1936_yob

european_ages_1936_p$sflu_birth_deviations = (european_ages_1936_p$`1918` + european_ages_1936_p$`1919`) - (european_ages_1936_p$`1917` + european_ages_1936_p$`1920`)
european_ages_1936_p$sflu_birth_deviations = european_ages_1936_p$sflu_birth_deviations/(european_ages_1936_p$`1917` + european_ages_1936_p$`1920`)

lm_robust(european_ages_1936_p$`1918` ~ deaths_sflu_per_1000 + european_ages_1936_p$`1917`, data = european_ages_1936_p)


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



european_ages_1936_merged = full_join(european_ages_1936, first_merge_29_36, by ="mag_dist_1936")
european_ages_1936_merged$mag_dist_1929 = ifelse(european_ages_1936_merged$mag_dist_1929=="FIX ME"|
                                                   european_ages_1936_merged$mag_dist_1929=="NO MATCH", 
                                                 NA, european_ages_1936_merged$mag_dist_1929)

european_ages_1936_merged = full_join(european_ages_1936_merged, reconciliation_1929_1936, by="mag_dist_1936")
european_ages_1936_merged$mag_dist_1929_correction = as.character(european_ages_1936_merged$mag_dist_1929_correction)

european_ages_1936_merged = 
  european_ages_1936_merged %>%  unite("mag_dist_1929", mag_dist_1929:mag_dist_1929_correction, na.rm = TRUE, remove = FALSE, sep="")

european_ages_1936_merged = full_join(european_ages_1936_merged, mag19181929_key, by = "mag_dist_1929")

european_ages_1936_merged$mag_dist_1929
colnames(european_ages_1936_merged)[48] = "StndrdN"

###Unemployment: 
unemployment_1936_merged = full_join(unemployment_1936, first_merge_29_36, by ="mag_dist_1936")
unemployment_1936_merged$mag_dist_1929 = ifelse(unemployment_1936_merged$mag_dist_1929=="FIX ME"|
                                                  unemployment_1936_merged$mag_dist_1929=="NO MATCH", 
                                                NA, unemployment_1936_merged$mag_dist_1929)

unemployment_1936_merged = full_join(unemployment_1936_merged, reconciliation_1929_1936, by="mag_dist_1936")
unemployment_1936_merged$mag_dist_1929_correction = as.character(unemployment_1936_merged$mag_dist_1929_correction)

unemployment_1936_merged = 
  unemployment_1936_merged %>%unite("mag_dist_1929", mag_dist_1929:mag_dist_1929_correction, na.rm = TRUE, remove = FALSE, sep="")

unemployment_1936_merged = full_join(unemployment_1936_merged, mag19181929_key, by = "mag_dist_1929")

unemployment_1936_merged$mag_dist_1929
colnames(unemployment_1936_merged)[19] = "StndrdN"

#Mortality data
mortality_data = 
  findat %>%
  dplyr::select(mag_dist_1918, StndrdN, total_deaths_sflu, deaths_sflu_per_1000, region)

#Merging
european_ages_1936_merged_p = european_ages_1936_merged[european_ages_1936_merged$sex=="P",]
european_ages_1936_merged_p$StndrdN = as.character(european_ages_1936_merged_p$StndrdN)

unemployment_1936_merged$StndrdN = as.character(unemployment_1936_merged$StndrdN)

census_1936_merged = full_join(unemployment_1936_merged, european_ages_1936_merged_p, by= "mag_dist_1936")
census_1936_merged$StndrdN = census_1936_merged$StndrdN.x
census_1936_merged = full_join(census_1936_merged, mortality_data, by="StndrdN")
census_1936_merged = full_join(census_1936_merged, covariates, by="StndrdN")

census_1936_merged$unemployment_rate_w = census_1936_merged$unemployed_w_t/census_1936_merged$total_pop

lm_robust(unemployment_rate_w ~ deaths_sflu_per_1000 + black_share1911 + col_share1911 + 
            log(1 + density_1911) + log(1 + rail_mdcentroid_to_nearestrail_km) + 
            rainfall_sepoctmean19101950 + factor(region.x), census_1936_merged, clusters = StndrdN)




region dummies

