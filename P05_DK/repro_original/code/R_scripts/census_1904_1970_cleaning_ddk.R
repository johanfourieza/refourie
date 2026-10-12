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

mortality = read_excel("data\\original\\mortality\\Phillips Table 13_all.xlsx")
colnames(mortality) = c("mag_dist_1918", "white_pop_1918", "black_pop_1911", "ind_col_pop_1911", "total_pop_1918", "total_deaths_sflu", "deaths_sflu_per_1000")

which(is.na(mortality$mag_dist_1918)==T)

mortality$region = NA
mortality$region[which(is.na(mortality$mag_dist_1918)==T)[1]:which(is.na(mortality$mag_dist_1918)==T)[3]] = "Cape"
mortality$region[(which(is.na(mortality$mag_dist_1918)==T)[3]+1):which(is.na(mortality$mag_dist_1918)==T)[4]] = "Transkei"
mortality$region[(which(is.na(mortality$mag_dist_1918)==T)[4]+1):which(is.na(mortality$mag_dist_1918)==T)[5]] = "Natal"
mortality$region[(which(is.na(mortality$mag_dist_1918)==T)[5]+1):which(is.na(mortality$mag_dist_1918)==T)[6]] = "Zululand"
mortality$region[(which(is.na(mortality$mag_dist_1918)==T)[6]+1):which(is.na(mortality$mag_dist_1918)==T)[7]] = "Transvaal"
mortality$region[(which(is.na(mortality$mag_dist_1918)==T)[7]+1):nrow(mortality)] = "Orange Free State"

#Remove unwanted rows
mortality =
  mortality %>%
  drop_na()

#Recode the duplicated names:
mortality$mag_dist_1918 = as.character(mortality$mag_dist_1918)

mortality$mag_dist_1918[duplicated(mortality$mag_dist_1918)==T]
mortality$mag_dist_1918 = ifelse(mortality$region=="Cape" & mortality$mag_dist_1918=="Richmond", "Richmond (Cape)", mortality$mag_dist_1918)
mortality$mag_dist_1918 = ifelse(mortality$region=="Natal" & mortality$mag_dist_1918=="Richmond", "Richmond (Natal)", mortality$mag_dist_1918)
mortality$mag_dist_1918 = ifelse(mortality$region=="Cape" & mortality$mag_dist_1918=="Middelburg", "Middelburg (Cape)", mortality$mag_dist_1918)
mortality$mag_dist_1918 = ifelse(mortality$region=="Transvaal" & mortality$mag_dist_1918=="Middelburg", "Middelburg (Transvaal)", mortality$mag_dist_1918)

#Call in population data
mag1970_shp = st_read("data\\original\\spatial\\RSA_Pop_1904_70.shp")
mag1918_shp = st_read("data\\original\\spatial\\SA_1918.shp")

mag1918_shp = st_transform(mag1918_shp, st_crs(mag1970_shp))
st_crs(mag1970_shp) == st_crs(mag1918_shp)

mag1918_shp$OrgnlNm = as.character(mag1918_shp$OrgnlNm)
mag1918_shp$StndrdN = as.character(mag1918_shp$StndrdN)

mag1918_shp$OrgnlNm[mag1918_shp$StndrdN=="middelburg c"] = "Middelburg (Cape)"
mag1918_shp$OrgnlNm[mag1918_shp$StndrdN=="middelburg t"] = "Middelburg (Transvaal)"

mag19181970_shp = st_join(mag1970_shp, mag1918_shp, join = st_intersects, largest=T)
mag19181970_shp = subset(mag19181970_shp, mag19181970_shp$DISTRICT!="Lesotho")


#png("outputs\\maps\\join_check_maps\\1918_1970_MD_join_names.png",  width=4000, height=3000)
#tm_shape(mag19181970_shp) + 
#  tm_polygons() + 
#  tm_text("OrgnlNm")
#dev.off()

#png("outputs\\maps\\join_check_maps\\1970_MD_original_names.png",  width=4000, height=3000)
#tm_shape(mag1970_shp) + 
#  tm_polygons() + 
#  tm_text("DISTRICT")
#dev.off()

#png("outputs\\maps\\join_check_maps\\1918_MD_original_names.png",  width=4000, height=3000)
#tm_shape(mag1918_shp) + 
#  tm_polygons() + 
#  tm_text("OrgnlNm")
#dev.off()

#Set population object
population = mag19181970_shp
population$OrgnlNm = as.character(population$OrgnlNm)

unique(as.character(population$OrgnlNm))
unique(as.character(mortality$mag_dist_1918))

distinct_OrgnlNm = unique(population$OrgnlNm)

matchnum = list()
multiples = c()
for(i in 1:length(distinct_OrgnlNm)){
matchnum[[i]] = agrep(distinct_OrgnlNm[i], mortality$mag_dist_1918)
multiples[i] = length(matchnum[[i]])
}

distinct_OrgnlNm = data.frame(distinct_OrgnlNm)
colnames(distinct_OrgnlNm) = "OrgnlNm"
distinct_OrgnlNm$OrgnlNm = as.character(distinct_OrgnlNm$OrgnlNm)
distinct_OrgnlNm$mag_dist_1918 = NA

multiples_index = which(multiples>1)
distinct_OrgnlNm$multi_index = ifelse(distinct_OrgnlNm$OrgnlNm %in% distinct_OrgnlNm$OrgnlNm[multiples_index], 1, 0)

for(i in 1:nrow(distinct_OrgnlNm)){
  if(distinct_OrgnlNm$multi_index[i] == 1 ){
    distinct_OrgnlNm$mag_dist_1918[i] = "FIX ME"
  } else if(length(mortality$mag_dist_1918[matchnum[[i]]])==0){
    distinct_OrgnlNm$mag_dist_1918[i] = "NO MATCH"
  } else{distinct_OrgnlNm$mag_dist_1918[i] = mortality$mag_dist_1918[matchnum[[i]]]
  }
}

#Manual corrections for multiple matches: #No correction for Richmond, there are two options, don't know which.
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Albert", "Albert & Venterstad", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Alexandria", "Alexandria", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Barkly East", "Barkly East", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Barkly West", "Barkly West/ Klipdam", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Durban", "Durban & Pinetown", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Elliot", "Elliot", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Hanover", "Hanover", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Hay", "Hay", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Ladismith", "Ladismith", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Somerset East", "Somerset East", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Tsolo", "Tsolo", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Tsomo", "Tsomo", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Alexandra", "Alexandra (Umzinto)", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Victoria East", "Victoria East", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Victoria West", "Victoria West", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Bethal", "Bethal", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Edenburg", "Edenburg", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Pietersburg", "Pietersburg", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Vrede", "Vrede", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Richmond", "Richmond (Cape)", distinct_OrgnlNm$mag_dist_1918)

#Manual corrections for no match: 
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Cape (Kaap)", "Cape Town (incl. Durbanville)", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Flag Staff", "Flagstaff", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Hopetown", "Hope Town", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="King William Town", "Kingwilliamstown & Keiskamahoek & Middeldrift", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Kranskop", "Krantzkop", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Maplimulo", "Mapumulo", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Middleburg", "Middelburg", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Mount Ayliff", "Mt Ayliff", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Mount Currie", "Mt Curie (Kokstad)", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Mount Faere", "Mt Frere", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Mount Fletcher", "Mt Fletcher", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Impofana", "Mpofana", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Nkandlha", "Nkandhla", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Philpstown", "Phillipstown", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Lower Umzimkulu", "Umzimkulu", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Simonstown (Simonstad)", "Simonstown", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Johansburg", "Johannesburg", distinct_OrgnlNm$mag_dist_1918)
distinct_OrgnlNm$mag_dist_1918 = ifelse(distinct_OrgnlNm$OrgnlNm=="Thabanchu", "Thaba 'Nchu", distinct_OrgnlNm$mag_dist_1918)

#Check that everything is good
distinct_OrgnlNm$mag_dist_1918[distinct_OrgnlNm$mag_dist_1918=="NO MATCH"]
distinct_OrgnlNm$mag_dist_1918[distinct_OrgnlNm$mag_dist_1918=="FIX ME"]

#Merge
combined = full_join(population, distinct_OrgnlNm, by="OrgnlNm")

combined =
  combined %>%
  group_by(mag_dist_1918, StndrdN) %>%
  summarise(sq_metres = mean(AREA), 
            total_1911 = sum(T1911), total_1921 = sum(T1921), total_1936 = sum(T1936), total_1946 = sum(T1946), 
            total_1951 = sum(T1951), total_1960 = sum(T1960), total_1970 = sum(T1970), 
            white_1911 = sum(W_1911), white_1921 = sum(W_1921), white_1936 = sum(W_1936), white_1946 = sum(W_1946), 
            white_1951 = sum(W_1951), white_1960 = sum(W_1960), white_1970 = sum(W_1970),
            black_1911 = sum(B_1911), black_1921 = sum(B_1921), black_1936 = sum(B_1936), black_1946 = sum(B_1946), 
            black_1951 = sum(B_1951), black_1960 = sum(B_1960), black_1970 = sum(B_1970), 
            col_1911 = sum(C_1911), col_1921 = sum(C_1921), col_1936 = sum(C_1936), col_1946 = sum(C_1946), 
            col_1951 = sum(C_1951), 
            asian_1911 = sum(A_1911), asian_1921 = sum(A_1921), asian_1936 = sum(A_1936), asian_1946 = sum(A_1946), 
            asian_1951 = sum(A_1951), asian_1960 = sum(A_1960), asian_1970 = sum(A_1970), 
            density_1911 = mean(TDENS_11), density_1921 = mean(TDENS_21), density_1936 = mean(TDENS_36), 
            density_1946 = mean(TDENS_46), density_1951 = mean(TDENS_51), density_1960 = mean(TDENS_60), density_1970 = mean(TDENS_70))

findat = left_join(combined, mortality, by="mag_dist_1918")
#Spelling mistakes to fix
findat$mag_dist_1918 = ifelse(findat$mag_dist_1918=="Umvoti (Greytown(", "Umvoti (Greytown)", findat$mag_dist_1918)
findat$mag_dist_1918 = ifelse(findat$mag_dist_1918=="Kimberey", "Kimberley", findat$mag_dist_1918)

findat$nonwhite_share1911 = (findat$black_1911 + findat$asian_1911 + findat$col_1911)/findat$total_1911
findat$nonwhite_share1921 = (findat$black_1921 + findat$asian_1921 + findat$col_1921)/findat$total_1921
findat$nonwhite_share1936 = (findat$black_1936 + findat$asian_1936 + findat$col_1936)/findat$total_1936
findat$nonwhite_share1960 = (findat$black_1960 + findat$asian_1960 + findat$col_1951)/findat$total_1960

findat$black_share1911 = findat$black_1911/findat$total_1911
findat$asian_share1911 = findat$asian_1911/findat$total_1911
findat$col_share1911 = findat$col_1911/findat$total_1911
findat$white_share1911 = findat$white_1911/findat$total_1911

findat$deaths_sflu_per_1000 = as.numeric(findat$deaths_sflu_per_1000)

findat$change_1121 = findat$total_1921 - findat$total_1911
findat$change_1136 = findat$total_1936 - findat$total_1911
findat$change_1160 = findat$total_1960 - findat$total_1911

findat$black_change_1121 = findat$black_1921 - findat$black_1911
findat$black_change_1136 = findat$black_1936 - findat$black_1911
findat$black_change_1160 = findat$black_1960 - findat$black_1911

findat$white_change_1121 = findat$white_1921 - findat$white_1911
findat$white_change_1136 = findat$white_1936 - findat$white_1911
findat$white_change_1160 = findat$white_1960 - findat$white_1911


findat$nonwhite_share_change_1121 = findat$nonwhite_share1921 - findat$nonwhite_share1911
findat$nonwhite_share_change_1136 = findat$nonwhite_share1936 - findat$nonwhite_share1911
findat$nonwhite_share_change_1160 = findat$nonwhite_share1960 - findat$nonwhite_share1911

findat$density_change_1121 = findat$density_1921  - findat$density_1911
findat$density_change_1160 = findat$density_1960  - findat$density_1911


tm_shape(findat) +
  tm_polygons("black_share1911", title = "Black Population Share 1911", palette = "Greys", colorNA = "honeydew3") + 
  tm_dots(size = "deaths_sflu_per_1000", scale=5, title.size="Spanish Flu Deaths Per 1000", legend.size.is.portrait=T,
          col="red", alpha = .65, shape = 19) + 
  tm_layout(main.title = "South African 1911 Nonwhite Pop. Share and 1918 Spanish Flu Mortality",
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

tm_shape(findat) +
  tm_polygons("col_share1911", title = "Coloured Population Share 1911", palette = "Greys", colorNA = "honeydew3") + 
  tm_dots(size = "deaths_sflu_per_1000", scale=5, title.size="Spanish Flu Deaths Per 1000", legend.size.is.portrait=T,
          col="red", alpha = .65, shape = 19) + 
  tm_layout(main.title = "South African 1911 Nonwhite Pop. Share and 1918 Spanish Flu Mortality",
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

summary(lm(deaths_sflu_per_1000 ~ black_share1911 + col_share1911 + log(1 + density_1911) +  as.factor(region), data=findat))



savedata = as.matrix(findat[,c("mag_dist_1918", "StndrdN", 
                     "black_1911", "col_1911", "white_1911", "total_1911", 
                     "black_share1911", "col_share1911", "white_share1911", "density_1911", "region")])
savedata = as.data.frame(savedata[,c(1:11)])

savedata$mag_dist_1918 = as.character(savedata$mag_dist_1918)
savedata$StndrdN = as.character(savedata$StndrdN)
savedata$black_1911 = as.numeric(savedata$black_1911)
savedata$col_1911 = as.numeric(savedata$col_1911)
savedata$white_1911 = as.numeric(savedata$white_1911)
savedata$total_1911 = as.numeric(savedata$total_1911)
savedata$black_share1911 = as.numeric(savedata$black_share1911)
savedata$col_share1911 = as.numeric(savedata$col_share1911)
savedata$white_share1911 = as.numeric(savedata$white_share1911)
savedata$density_1911 = as.numeric(savedata$density_1911)
savedata$region = as.character(savedata$region)

write_csv(savedata, path = "data\\processed\\census\\census_covariates_1911.csv")

#Create plotdat
plotdat = findat
