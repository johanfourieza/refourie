library(tidyverse)
library(readxl)
library(ggrepel)
library(sf)
# [ENV P3] not installed / retired from CRAN: library(tmap)
# [ENV P3] not installed / retired from CRAN: library(rgdal)
# [ENV P3] not installed / retired from CRAN: library(raster)
# [ENV P3] not installed / retired from CRAN: library(rgeos)
library(estimatr)
# [ENV P3] not installed / retired from CRAN: library(extrafont)
library(stargazer)
library(magrittr)
# [ENV P3] not installed / retired from CRAN: library(texreg)
library(ggfortify)

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

covariates = read.csv("data\\processed\\all_covariates.csv")

analysis_data = full_join(findat, covariates, by = "StndrdN")
analysis_data$log_deaths_sflu_per_1000 = log(analysis_data$deaths_sflu_per_1000)
analysis_data$log_density_1911 = log(1 + analysis_data$density_1911.x)
analysis_data$log_rail_mdcentroid_to_nearestrail_km = log(1 + analysis_data$rail_mdcentroid_to_nearestrail_km)

#WORK ON THIS
analysis_data %>% 
  mutate_at(vars(black_share1911.x), list(cut = function(x) cut(percent_rank(x), c(0,.25,.5,.75,1), labels = c(1:4))))

analysis_data$cut
#UP TO HERE

model1 = lm(deaths_sflu_per_1000 ~ black_share1911.x + col_share1911.x + 
              log_density_1911 + log_rail_mdcentroid_to_nearestrail_km + rainfall_sepoctmean19101950 +
                     as.factor(region.x), data=analysis_data)
model2 = lm(log_deaths_sflu_per_1000 ~ black_share1911.x + col_share1911.x + 
              log_density_1911 + log_rail_mdcentroid_to_nearestrail_km + rainfall_sepoctmean19101950 +
              as.factor(region.x), data=analysis_data)

#Linearity plot
saveplot = autoplot(model1) +
  theme_bw() + 
  theme(legend.title = element_blank(),          axis.line = element_line(colour = "black"),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.text.x = element_text(size=12),
        axis.text.y = element_text(size=12, angle=15),
        axis.title.x=element_text(size=13, vjust=.5),
        axis.title.y=element_text(size=13,angle=90,vjust=0))
ggsave("outputs\\figures\\regression_diagnostics.png", saveplot, width = 13, height = 10)

#6, 85, 96 are outliers. Exclude them below: 
analysis_data_excloutliers = analysis_data[-c(6,85,96),]
meansy = c(mean(analysis_data$deaths_sflu_per_1000, na.rm=T), mean(analysis_data$log_deaths_sflu_per_1000, na.rm=T), 
          mean(analysis_data_excloutliers$deaths_sflu_per_1000, na.rm=T), mean(analysis_data_excloutliers$log_deaths_sflu_per_1000, na.rm=T))

model1excl = lm(deaths_sflu_per_1000 ~ black_share1911.x + col_share1911.x + 
              log_density_1911 + log_rail_mdcentroid_to_nearestrail_km + rainfall_sepoctmean19101950 +
              as.factor(region.x), data=analysis_data_excloutliers)
model2excl = lm(log_deaths_sflu_per_1000 ~ black_share1911.x + col_share1911.x + 
              log_density_1911 + log_rail_mdcentroid_to_nearestrail_km + rainfall_sepoctmean19101950 +
              as.factor(region.x), data=analysis_data_excloutliers)

stargazer(model1, model2, model1excl, model2excl, se = starprep(model1, model2), out="outputs\\tables\\reg_predicting_mortality.tex",
          title            = "What Correlates with 1918 Spanish Flu Mortality in South Africa?",
          covariate.labels = c("Black Pop. Share  (1911)", "Coloured Pop.  Share  (1911)", "Log(1 + Pop. Density (1911))",
                               "Log(1 + Distance to Rail in Km (1907))", "Avg. Sept/Oct Rain in Cm (1910-1950)", "Region = Natal",
                               "Region = Orange Free State", "Region = Transkei", "Region = Transvaal", "Region = Zululand"),
          dep.var.caption  = "Dependent Variable:",
          dep.var.labels   = c("Deaths/1000", "Log(Deaths/1000)"),
          model.numbers    = FALSE, 
          add.lines = list(c("Dependent Variable Means", round(meansy,3))),
          digits = 3,
          digits.extra=0,
          omit.stat = c("adj.rsq", "ser"), 
          notes = c("HC2 Robust standard errors in parentheses.","Omitted region = Cape."), 
          notes.align = "l")

#Adding square terms
analysis_data$log_density_1911_sq = analysis_data$log_density_1911 * analysis_data$log_density_1911
analysis_data$log_rail_mdcentroid_to_nearestrail_km_sq = analysis_data$log_rail_mdcentroid_to_nearestrail_km * analysis_data$log_rail_mdcentroid_to_nearestrail_km

model1 = lm(deaths_sflu_per_1000 ~ black_share1911.x + col_share1911.x + 
              log_density_1911 + log_density_1911_sq + log_rail_mdcentroid_to_nearestrail_km + 
              rainfall_sepoctmean19101950 +
              as.factor(region.x), data=analysis_data)
summary(model1)
model2 = lm(log_deaths_sflu_per_1000 ~ black_share1911.x + col_share1911.x + 
              log_density_1911 + log_rail_mdcentroid_to_nearestrail_km_sq + log_rail_mdcentroid_to_nearestrail_km + 
              rainfall_sepoctmean19101950 +
              as.factor(region.x), data=analysis_data)
summary(model2)


#Bivariate plots
ggplot(analysis_data,
       aes(x=black_share1911.x, y=deaths_sflu_per_1000)) +
  geom_point(colour="deepskyblue") + 
  geom_smooth(se=T, span =2, colour="darkorchid1", alpha=.3, fill="darkorchid1") + 
  scale_y_continuous("Spanish Flu Deaths Per 1000") +
  scale_x_continuous("Black Population Share, 1911") +
  ggtitle(label = "South African 1911 Black Population Share and 1918 Flu Mortality", 
          subtitle = "Loess Fit Shown in Purple") +
  theme_bw() + 
  theme(legend.title = element_blank(),          axis.line = element_line(colour = "black"),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.text.x = element_text(size=12),
        axis.text.y = element_text(size=12, angle=15),
        axis.title.x=element_text(size=13, vjust=.5),
        axis.title.y=element_text(size=13,angle=90,vjust=0))
ggsave("outputs\\figures\\black_share_1911_sfludeaths_per_1000.png", width = 9, height = 7)

ggplot(analysis_data,
       aes(x=col_share1911.x, y=deaths_sflu_per_1000)) +
  geom_point(colour="deepskyblue") + 
  geom_smooth(se=T, span =2, colour="darkorchid1", alpha=.3, fill="darkorchid1") + 
  scale_y_continuous("Spanish Flu Deaths Per 1000") +
  scale_x_continuous("Coloured Population Share, 1911") +
  ggtitle(label = "South African 1911 Coloured Population Share and 1918 Flu Mortality", 
          subtitle = "Loess Fit Shown in Purple") +
  theme_bw() + 
  theme(legend.title = element_blank(),          axis.line = element_line(colour = "black"),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.text.x = element_text(size=12),
        axis.text.y = element_text(size=12, angle=15),
        axis.title.x=element_text(size=13, vjust=.5),
        axis.title.y=element_text(size=13,angle=90,vjust=0))
ggsave("outputs\\figures\\coloured_share_1911_sfludeaths_per_1000.png", width = 9, height = 7)

ggplot(analysis_data,
       aes(x=log_density_1911, y=deaths_sflu_per_1000)) +
  geom_point(colour="deepskyblue") + 
  geom_smooth(se=T, span =2, colour="darkorchid1", alpha=.3, fill="darkorchid1") + 
  scale_y_continuous("Spanish Flu Deaths Per 1000") +
  scale_x_continuous("Log Population Density, 1911") +
  ggtitle(label = "South African 1911 Population Density and 1918 Flu Mortality", 
          subtitle = "Loess Fit Shown in Purple") +
  theme_bw() + 
  theme(legend.title = element_blank(),          axis.line = element_line(colour = "black"),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.text.x = element_text(size=12),
        axis.text.y = element_text(size=12, angle=15),
        axis.title.x=element_text(size=13, vjust=.5),
        axis.title.y=element_text(size=13,angle=90,vjust=0))
ggsave("outputs\\figures\\popdens_1911_sfludeaths_per_1000.png", width = 9, height = 7)

ggplot(analysis_data,
       aes(x=log_rail_mdcentroid_to_nearestrail_km, y=deaths_sflu_per_1000)) +
  geom_point(colour="deepskyblue") + 
  geom_smooth(se=T, span =2, colour="darkorchid1", alpha=.3, fill="darkorchid1") + 
  scale_y_continuous("Spanish Flu Deaths Per 1000") +
  scale_x_continuous("Log Km to Railway, 1907") +
  ggtitle(label = "South African 1907 Distance to Railway and 1918 Flu Mortality", 
          subtitle = "Loess Fit Shown in Purple") +
  theme_bw() + 
  theme(legend.title = element_blank(),          axis.line = element_line(colour = "black"),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.text.x = element_text(size=12),
        axis.text.y = element_text(size=12, angle=15),
        axis.title.x=element_text(size=13, vjust=.5),
        axis.title.y=element_text(size=13,angle=90,vjust=0))
ggsave("outputs\\figures\\railway_1907_sfludeaths_per_1000.png", width = 9, height = 7)

ggplot(analysis_data,
       aes(x=rainfall_sepoctmean19101950, y=deaths_sflu_per_1000)) +
  geom_point(colour="deepskyblue") + 
  geom_smooth(se=T, span =2, colour="darkorchid1", alpha=.3, fill="darkorchid1") + 
  scale_y_continuous("Spanish Flu Deaths Per 1000") +
  scale_x_continuous("Sept-Oct Mean Rainfall, 1910-1950") +
  ggtitle(label = "South African Rainfall and 1918 Flu Mortality", 
          subtitle = "Loess Fit Shown in Purple") +
  theme_bw() + 
  theme(legend.title = element_blank(),          axis.line = element_line(colour = "black"),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.text.x = element_text(size=12),
        axis.text.y = element_text(size=12, angle=15),
        axis.title.x=element_text(size=13, vjust=.5),
        axis.title.y=element_text(size=13,angle=90,vjust=0))
ggsave("outputs\\figures\\rainfall_sfludeaths_per_1000.png", width = 9, height = 7)
