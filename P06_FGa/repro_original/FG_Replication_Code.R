#usual suspects
require(data.table)
require(reshape2)
require(ggplot2)
require(tidyverse)
require(RColorBrewer)
library(plm)
library(lattice)
library(plotly)
library(stargazer)
library(Amelia)
library(ineq)
library(xtable)
library(stringr)
library(gglorenz)
library(ggpubr)
#library(xlsx)
#library(dplyr)


require(foreign)

require(RColorBrewer)
require(readxl)
require(dummies)
library(labeling)  # PATCH P2: pacman not installed; p_load(labeling) == library(labeling)
#require(gridExtra)


#

remove(list=ls())

comparisons = read_excel(file.path(Sys.getenv("P06_ORIG"), "20 FG Comparisons", "Data/Analysis.xlsx"), "Comparisons", col_names = TRUE)
com = data.table(comparisons)


theme1 = theme_set(theme_minimal(base_size = 15)) +
  theme_update(legend.position="bottom", legend.title=element_blank()) +
  theme_update(axis.text.y = element_text(colour="black"), axis.ticks.y= element_line(colour="grey"))

com %>%
  ggplot(aes(x=year, y=cgdppc, shape=countrycode)) +
  geom_line() +
  geom_point() +
  scale_y_log10() +
  xlim(1650, 2020) +
  ylab('log(CGDPPC)') +
  xlab('Year') +
  theme1

com %>%
  ggplot(aes(x=year, y=cgdppc, shape=countrycode)) +
  geom_line() +
  geom_point() +
  xlim(1750, 1850) +
  ylim(0,4000) +
  ylab('CGDPPC') +
  xlab('Year') +
  theme1


###########################Opgaafrolle

remove(list=ls())

fouriegarmen = read_excel(file.path(Sys.getenv("P06_ORIG"), "20 FG Comparisons", "Data/FourieGarmenApril2020.xlsx"), "Combined", col_names = TRUE)
fg = data.table(fouriegarmen)

trim = function (trim) gsub("^\\s+|\\s+$", "", trim)

theme = theme_set(theme_minimal(base_size = 15)) +
  theme_update(legend.position="bottom", legend.title=element_blank(), panel.grid.major.x=element_blank()) +
  theme_update(axis.line.y = element_blank(), axis.title.y=element_blank(), axis.text.y = element_text(colour="grey"), axis.ticks.y= element_line(colour="grey"))


fg$Year[fg$Year == 1787] = 1785
fg$Year[fg$Year == 1784] = 1785
fg$Year[fg$Year == 1806] = 1805
fg$Year[fg$Year == 1798] = 1795
fg$Year[fg$Year == 1814] = 1815
fg$Year[fg$Year == 1792] = 1795
fg$Year[fg$Year == 1787] = 1785
fg$Year[fg$Year == 1801] = 1805
fg$Year[fg$Year == 1811] = 1815
fg$Year[fg$Year == 1806] = 1805

fg$Country = fg$District

fg$Country[fg$Country == "Graaff Reinet"] = 'Cape Colony'
fg$Country[fg$Country == "Stellenbosch"] = 'Cape Colony'
fg$Country[fg$Country == "Swellendam"] = 'Cape Colony'
fg$Country[fg$Country == "Tulbagh"] = 'Cape Colony'
fg$Country[fg$Country == "Maine"] = 'United States'
fg$Country[fg$Country == "Massachusetts"] = 'United States'
fg$Country[fg$Country == "Virginia"] = 'United States'

fg[ , Crops :=rowSums(.SD, na.rm = TRUE), .SDcols = c("Wheatreaped","Barleyreaped","Oatsreaped","Ryereaped","Cornreaped")]
fg[ , WheatCorn :=rowSums(.SD, na.rm = TRUE), .SDcols = c("Wheatreaped","Cornreaped")]

fg[ , Corr := list(list(cor(fg[,10:15]))), by = Country]

nfg = fg[, .(Men = fg$Men, Women = fg$Women, Khoe = fg$Khoe, Slaves = fg$Slaves, Horses = fg$Horses,
             Cattle = fg$Cattle, Sheep = fg$Sheep, Wheat = fg$Wheatreaped, Wine = fg$Wine)]

vfg = fg[, .(Men = fg$Men, Slaves = fg$Slaves, Horses = fg$Horses,
             Cattle = fg$Cattle, Sheep = fg$Sheep, Wheat = fg$Wheatreaped, Barley = fg$Barleyreaped, 
             Rye = fg$Ryereaped, Oats = fg$Oatsreaped, Corn = fg$Cornreaped, Wine = fg$Wine, Brandy = fg$Brandy)]

vfg = vfg[, .(Men = vfg$Men, Slaves = vfg$Slaves, Horses = fg$Horses,
             Cattle = fg$Cattle, Sheep = fg$Sheep, Wheat = fg$Wheatreaped, Barley = fg$Barleyreaped, 
             Rye = fg$Ryereaped, Oats = fg$Oatsreaped, Corn = fg$Cornreaped, Wine = fg$Wine, Brandy = fg$Brandy)]



#cfg = round(cor(nfg, method = c("pearson"), use = "complete.obs"), 2)

descriptives = 
  fg %>%
  group_by(District, Year) %>%
  filter(Wheatreaped > 0 | Barleyreaped > 0 | Ryereaped > 0 | Oatsreaped > 0 | Cornreaped > 0 | Wine > 0 | Cattle > 0 | Sheep > 0) %>%
  #filter(!is.na(Cornreaped | Wheatreaped | Barleyreaped | Ryereaped | Oatsreaped)) %>%
  summarise(obs = n(),
            Wheat = mean(Wheatreaped, na.rm = T),
            Barley = mean(Barleyreaped, na.rm = T),
            Rye = mean(Ryereaped, na.rm = T),
            Oats = mean(Oatsreaped, na.rm = T),
            Corn = mean(Cornreaped, na.rm = T),
            Wine = mean(Wine, na.rm = T),
            Horses = mean(Horses, na.rm = T),
            Cattle = mean(Cattle, na.rm = T),
            Sheep = mean(Sheep, na.rm = T),
            Crops = mean(Crops, na.rm = T))

sample = 
  fg %>%
  group_by(Year, District) %>%
  #mutate(freq = n / sum(n)) %>%
  #filter(Wheatreaped > 0 | Barleyreaped > 0 | Ryereaped > 0 | Oatsreaped > 0 | Cornreaped > 0 | Wine > 0 | Cattle > 0 | Sheep > 0) %>%
  #filter(!is.na(Cornreaped | Wheatreaped | Barleyreaped | Ryereaped | Oatsreaped)) %>%
  summarise(Obs = n())


slavesdes = fg[, .(Obs = .N, Average=mean(Slaves, na.rm=TRUE), Median=median(Slaves, na.rm = TRUE), Max=max(Slaves, na.rm = TRUE)), by=.(District, Year)]

cattledes = fg[, .(Obs = .N, Average=mean(Cattle, na.rm=TRUE), Median=median(Cattle, na.rm = TRUE), Max=max(Cattle, na.rm = TRUE)), by=.(District, Year)]

horsedes = fg[, .(Obs = .N, Average=mean(Horses, na.rm=TRUE), Median=median(Horses, na.rm = TRUE), Max=max(Horses, na.rm = TRUE)), by=.(District, Year)]

grainsdes = fg[, .(Obs = .N, Wheat=mean(Wheatreaped, na.rm=TRUE), Barley=mean(Barleyreaped, na.rm=TRUE), Rye=mean(Ryereaped, na.rm=TRUE), Oats=mean(Oatsreaped, na.rm=TRUE)), by=.(District)]

cattletot = fg[, .(Obs = .N, Average=mean(Cattle, na.rm=TRUE), Median=median(Cattle, na.rm = TRUE), Max=max(Cattle, na.rm = TRUE)), by=.(Country)]

gini = fg[, .(Obs = .N, Cattle=Gini(Cattle, na.rm=TRUE), Crops=Gini(Crops, na.rm = TRUE), Slaves=Gini(Slaves, na.rm = TRUE)), by=.(Country, Year)]

########################################PRICES!

fgprices = read_excel(file.path(Sys.getenv("P06_ORIG"), "20 FG Comparisons", "Prices.xlsx"), "Final", col_names = TRUE)
fgprices = data.table(fgprices)

fgprices2 = read_excel(file.path(Sys.getenv("P06_ORIG"), "20 FG Comparisons", "Prices.xlsx"), "Final2", col_names = TRUE)
fgprices2 = data.table(fgprices2)


#Reading files 
## working dorectory
# PATCH P4: rstudioapi path discovery replaced; dir = data copy of "20 FG Comparisons/", cwd = scratch
dir <- paste0(file.path(Sys.getenv("P06_ORIG"), "20 FG Comparisons"), "/")
setwd(Sys.getenv("P06_SCRATCH"))

#Data 
fg <- read_excel(paste0(dir,"Data/FourieGarmenApril2020.xlsx"),"Combined", col_names = TRUE)
fg = data.table(fg)
fgprices <- read_excel(paste0(dir,"Prices.xlsx"),  # PATCH P5: Data/Prices.xlsx not in archive; = FG Prices.xlsx
                      "Final", col_names = TRUE) 


fgp <- fg %>% left_join(fgprices, by= "Country") 

fg_V<- fgp %>% mutate(V_Wheat = prod(Wheatreaped*PWheat,na.rm = T),
                      V_Barley = Barleyreaped*PBarley,
                      V_Rye = Ryereaped*PRye,
                      V_Oats = Oatsreaped*POats,
                      V_Corn = Cornreaped*PCorn,
                      V_Wine = Wine*PWine,
                      V_Horses = Horses*PHorses*0.06,
                      V_Cattle = Cattle*PCattle*0.06,
                      V_Sheep = Sheep*PSheep*0.06,
                      V_Brandy = Brandy*PBrandy,
                      V_Slaves = Slaves*PSlaves*0.06)

fgp2 <- fg %>% left_join(fgprices2, by= "Country") 

fg2_V<- fgp2 %>% mutate(V_Wheat = prod(Wheatreaped*PWheat,na.rm = T),
                    V_Barley = Barleyreaped*PBarley,
                    V_Rye = Ryereaped*PRye,
                    V_Oats = Oatsreaped*POats,
                    V_Corn = Cornreaped*PCorn,
                    V_Wine = Wine*PWine,
                    V_Horses = Horses*PHorses*0.06,
                    V_Cattle = Cattle*PCattle*0.06,
                    V_Sheep = Sheep*PSheep*0.06,
                    V_Brandy = Brandy*PBrandy,
                    V_Slaves = Slaves*PSlaves*0.06)

fg_V[ , V_Crops :=rowSums(.SD, na.rm = TRUE), .SDcols = c("V_Wheat","V_Barley","V_Oats","V_Rye","V_Corn")]


V_slavesdes = fg_V[, .(Obs = .N, Average=mean(V_Slaves, na.rm=TRUE), Median=median(V_Slaves, na.rm = TRUE), Max=max(V_Slaves, na.rm = TRUE)), by=.(Country,District, Year)]

V_cattledes = fg_V[, .(Obs = .N, Average=mean(V_Cattle, na.rm=TRUE), Median=median(V_Cattle, na.rm = TRUE), Max=max(V_Cattle, na.rm = TRUE)), by=.(District,Country, Year)]

V_horsedes = fg_V[, .(Obs = .N, Average=mean(V_Horses, na.rm=TRUE), Median=median(V_Horses, na.rm = TRUE), Max=max(V_Horses, na.rm = TRUE)), by=.(District,Country, Year)]

V_grainsdes = fg_V[, .(Obs = .N, Wheat=mean(V_Wheat, na.rm=TRUE), Barley=mean(V_Barley, na.rm=TRUE), Rye=mean(V_Rye, na.rm=TRUE), Oats=mean(V_Oats, na.rm=TRUE)), by=.(District, Country, Year)]

V_cattletot = fg_V[, .(Obs = .N, Average=mean(V_Cattle, na.rm=TRUE), Median=median(V_Cattle, na.rm = TRUE), Max=max(V_Cattle, na.rm = TRUE)), by=.(Country, Districy, Year)]

V_gini = fg_V[, .(Obs = .N, Cattle=Gini(Cattle, na.rm=TRUE), Crops=Gini(Crops, na.rm = TRUE), Slaves=Gini(Slaves, na.rm = TRUE)), by=.(Country, Year)]



#######################################FIGURES###########################################################

###FIGURE 4

fig4 <- fg %>%
  #group_by(District) %>%
  ggplot(aes(Year)) +
  geom_bar() +
  #geom_violin(colour='black') +
  facet_wrap(~District) +
  #scale_fill_grey() +
  labs(x = 'District',
       y = 'Number of observations') +
  #scale_shape_manual(values=c(1,2,3,4,5,6,7))+
  #scale_x_discrete(labels = abbreviate) +
  scale_x_continuous(breaks = c(1785, 1795, 1805, 1815)) +
  scale_colour_grey() +
  theme

fig4
ggsave("fig4.tiff", width = 12, height = 8, dpi = 300)

###FIGURE 5

fig5 <- fg %>%
  ggplot(aes(District, Cattle)) +
  geom_violin(alpha = 0.8) +
  geom_boxplot(alpha = 0.8) +
  scale_y_log10() +
  scale_fill_grey() +
  #coord_cartesian(ylim = c(15, 50)) +
  labs(x = 'District',
       y = 'Cattle (logorithmic)') +
  theme

fig5
ggsave("fig5.tiff", width = 12, height = 8, dpi = 300)

###FIGURE 6

a = fg_V %>%
  mutate(Crops_V = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn), na.rm = TRUE)) %>%
  ggplot(aes(Country, Crops_V)) +
  geom_violin(alpha = 0.8) +
  geom_boxplot(alpha = 0.8) +
  scale_y_log10() +
  scale_fill_grey() +
  #coord_cartesian(ylim = c(15, 50)) +
  labs(x = 'Country',
       y = 'Crops (US$)') +
  theme

b = fg_V %>%
  mutate(CropsW_V = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn, V_Wine), na.rm = TRUE)) %>%
  ggplot(aes(Country, CropsW_V)) +
  geom_violin(alpha = 0.8) +
  geom_boxplot(alpha = 0.8) +
  scale_y_log10() +
  scale_fill_grey() +
  #coord_cartesian(ylim = c(15, 50)) +
  labs(x = 'Country',
       y = 'Crops + wine (US$)') +
  theme

fig6 <- ggarrange(a + rremove("x.title"), b + rremove("x.title"))

fig6
ggsave("fig6.tiff", width = 12, height = 8, dpi = 300)

descrops = fg_V %>%
  mutate(Crops_V = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn), na.rm = TRUE)) %>%
  mutate(CropsW_V = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn, V_Wine), na.rm = TRUE)) %>%
  group_by(Country) %>%
  summarise(obs = n(),
          Crops_V = mean(Crops_V, na.rm = T),
          CropsW_V = mean(CropsW_V, na.rm = T))

desall = fg_V %>%
  filter(Wheatreaped > 0 | Barleyreaped > 0 | Ryereaped > 0 | Oatsreaped > 0 | Cornreaped > 0 | Wine > 0 | Cattle > 0 | Sheep > 0) %>%
  mutate(Crops_V = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn), na.rm = TRUE)) %>%
  mutate(CropsW_V = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn, V_Wine, V_Brandy), na.rm = TRUE)) %>%
  mutate(Stock = rowSums(dplyr::select(., V_Cattle, V_Sheep), na.rm = TRUE)) %>%
  mutate(Agric = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn, V_Cattle, V_Sheep), na.rm = TRUE)) %>%
  mutate(AgricW = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn, V_Wine, V_Brandy, V_Cattle, V_Sheep), na.rm = TRUE)) %>%
  mutate(Total = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn, V_Wine, V_Brandy, V_Cattle, V_Sheep, V_Horses, V_Slaves), na.rm = TRUE)) %>%
  group_by(District) %>%
  summarise(obs = n(),
            Wheat = mean(Wheatreaped, na.rm = T),
            Barley = mean(Barleyreaped, na.rm = T),
            Rye = mean(Ryereaped, na.rm = T),
            Oats = mean(Oatsreaped, na.rm = T),
            Corn = mean(Cornreaped, na.rm = T),
            Wine = mean(Wine, na.rm = T),
            Brandy = mean(Brandy, na.rm = T),
            Crops_V = mean(Crops_V, na.rm = T),
            CropsW_V = mean(CropsW_V, na.rm = T),
            Stock = mean(Stock, na.rm = T),
            Agric = mean(Agric, na.rm = T),
            AgricW = mean(AgricW, na.rm = T),
            Slaves = mean(Slaves, na.rm = T),
            Total = mean(Total, na.rm = T))

desall3 = fg_V %>%
  filter(District != 'Virginia') %>%
  filter(Wheatreaped > 0 | Barleyreaped > 0 | Ryereaped > 0 | Oatsreaped > 0 | Cornreaped > 0 | Wine > 0 | Cattle > 0 | Sheep > 0) %>%
  mutate(Crops_V = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn), na.rm = TRUE)) %>%
  mutate(CropsW_V = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn, V_Wine, V_Brandy), na.rm = TRUE)) %>%
  mutate(Stock = rowSums(dplyr::select(., V_Cattle, V_Sheep), na.rm = TRUE)) %>%
  mutate(Agric = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn, V_Cattle, V_Sheep), na.rm = TRUE)) %>%
  mutate(AgricW = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn, V_Wine, V_Brandy, V_Cattle, V_Sheep), na.rm = TRUE)) %>%
  mutate(Total = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn, V_Wine, V_Brandy, V_Cattle, V_Sheep, V_Horses, V_Slaves), na.rm = TRUE)) %>%
  group_by(Country) %>%
  summarise(obs = n(),
            Wheat = mean(Wheatreaped, na.rm = T),
            Barley = mean(Barleyreaped, na.rm = T),
            Rye = mean(Ryereaped, na.rm = T),
            Oats = mean(Oatsreaped, na.rm = T),
            Corn = mean(Cornreaped, na.rm = T),
            Wine = mean(Wine, na.rm = T),
            Brandy = mean(Brandy, na.rm = T),
            Crops_V = mean(Crops_V, na.rm = T),
            CropsW_V = mean(CropsW_V, na.rm = T),
            Stock = mean(Stock, na.rm = T),
            Agric = mean(Agric, na.rm = T),
            AgricW = mean(AgricW, na.rm = T),
            Slaves = mean(Slaves, na.rm = T),
            Total = mean(Total, na.rm = T))

desall2 = fg2_V %>%
  filter(Wheatreaped > 0 | Barleyreaped > 0 | Ryereaped > 0 | Oatsreaped > 0 | Cornreaped > 0 | Wine > 0 | Cattle > 0 | Sheep > 0) %>%
  mutate(Crops_V = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn), na.rm = TRUE)) %>%
  mutate(CropsW_V = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn, V_Wine, V_Brandy), na.rm = TRUE)) %>%
  mutate(Stock = rowSums(dplyr::select(., V_Cattle, V_Sheep), na.rm = TRUE)) %>%
  mutate(Agric = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn, V_Wine, V_Brandy, V_Cattle, V_Sheep), na.rm = TRUE)) %>%
  mutate(Total = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn, V_Wine, V_Brandy, V_Cattle, V_Sheep, V_Horses, V_Slaves), na.rm = TRUE)) %>%
  group_by(District) %>%
  summarise(obs = n(),
            Wheat = mean(Wheatreaped, na.rm = T),
            Barley = mean(Barleyreaped, na.rm = T),
            Rye = mean(Ryereaped, na.rm = T),
            Oats = mean(Oatsreaped, na.rm = T),
            Corn = mean(Cornreaped, na.rm = T),
            Wine = mean(Wine, na.rm = T),
            Brandy = mean(Brandy, na.rm = T),
            Crops_V = mean(Crops_V, na.rm = T),
            CropsW_V = mean(CropsW_V, na.rm = T),
            Stock = mean(Stock, na.rm = T),
            Agric = mean(Agric, na.rm = T),
            Total = mean(Total, na.rm = T))

desall4 = fg2_V %>%
  filter(District != 'Virginia') %>%
  filter(Wheatreaped > 0 | Barleyreaped > 0 | Ryereaped > 0 | Oatsreaped > 0 | Cornreaped > 0 | Wine > 0 | Cattle > 0 | Sheep > 0) %>%
  mutate(Crops_V = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn), na.rm = TRUE)) %>%
  mutate(CropsW_V = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn, V_Wine, V_Brandy), na.rm = TRUE)) %>%
  mutate(Stock = rowSums(dplyr::select(., V_Cattle, V_Sheep), na.rm = TRUE)) %>%
  mutate(Agric = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn, V_Cattle, V_Sheep), na.rm = TRUE)) %>%
  mutate(AgricW = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn, V_Wine, V_Brandy, V_Cattle, V_Sheep), na.rm = TRUE)) %>%
  mutate(Total = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn, V_Wine, V_Brandy, V_Cattle, V_Sheep, V_Horses, V_Slaves), na.rm = TRUE)) %>%
  group_by(Country) %>%
  summarise(obs = n(),
            Wheat = mean(Wheatreaped, na.rm = T),
            Barley = mean(Barleyreaped, na.rm = T),
            Rye = mean(Ryereaped, na.rm = T),
            Oats = mean(Oatsreaped, na.rm = T),
            Corn = mean(Cornreaped, na.rm = T),
            Wine = mean(Wine, na.rm = T),
            Brandy = mean(Brandy, na.rm = T),
            Crops_V = mean(Crops_V, na.rm = T),
            CropsW_V = mean(CropsW_V, na.rm = T),
            Stock = mean(Stock, na.rm = T),
            Agric = mean(Agric, na.rm = T),
            AgricW = mean(AgricW, na.rm = T),
            Slaves = mean(Slaves, na.rm = T),
            Total = mean(Total, na.rm = T))

###FIGURE 7

desslaves2 = fg2_V %>%
  filter(District != 'Maine') %>%
  filter(District != 'Massachusetts') %>%
  filter(Slaves > 0) %>%
  filter(Wheatreaped > 0 | Barleyreaped > 0 | Ryereaped > 0 | Oatsreaped > 0 | Cornreaped > 0 | Wine > 0 | Cattle > 0 | Sheep > 0) %>%
  group_by(District) %>%
  summarise(obs = n(),
            Slaves = mean(Slaves, na.rm = T),
            SlavesV = mean(V_Slaves, na.rm = T),
            SlavesmV = median(V_Slaves, na.rm = T))

desslaves1 = fg_V %>%
  filter(District != 'Maine') %>%
  filter(District != 'Massachusetts') %>%
  filter(Slaves > 0) %>%
  filter(Wheatreaped > 0 | Barleyreaped > 0 | Ryereaped > 0 | Oatsreaped > 0 | Cornreaped > 0 | Wine > 0 | Cattle > 0 | Sheep > 0) %>%
  group_by(District) %>%
  summarise(obs = n(),
            Slaves = mean(Slaves, na.rm = T),
            SlavesV = mean(V_Slaves, na.rm = T),
            SlavesmV = median(V_Slaves, na.rm = T))

c = fg_V %>%
  filter(District != 'Maine') %>%
  filter(District != 'Massachusetts') %>%
  filter(Slaves > 0) %>%
  filter(Wheatreaped > 0 | Barleyreaped > 0 | Ryereaped > 0 | Oatsreaped > 0 | Cornreaped > 0 | Wine > 0 | Cattle > 0 | Sheep > 0) %>%
  ggplot(aes(District, V_Slaves)) +
  geom_violin(alpha = 0.8) +
  geom_boxplot(alpha = 0.8) +
  scale_y_log10() +
  scale_fill_grey() +
  geom_hline(yintercept = 53.55300, linetype = "longdash") +
  #coord_cartesian(ylim = c(15, 50)) +
  labs(x = 'District',
       y = 'US$ (log)') +
  theme

d = fg2_V %>%
  filter(District != 'Maine') %>%
  filter(District != 'Massachusetts') %>%
  filter(Slaves > 0) %>%
  filter(Wheatreaped > 0 | Barleyreaped > 0 | Ryereaped > 0 | Oatsreaped > 0 | Cornreaped > 0 | Wine > 0 | Cattle > 0 | Sheep > 0) %>%
  ggplot(aes(District, V_Slaves)) +
  geom_violin(alpha = 0.8) +
  geom_boxplot(alpha = 0.8) +
  scale_y_log10() +
  scale_fill_grey() +
  geom_hline(yintercept = 53.55300, linetype = "longdash") +
  #coord_cartesian(ylim = c(15, 50)) +
  labs(x = 'District',
       y = 'US$ (log)') +
  theme

fig7 <- ggarrange(c + rremove("x.text") + rremove("x.title"), d , 
          labels = c("A", "B"),
          ncol = 1, nrow = 2)

fig7
ggsave("fig7.tiff", width = 12, height = 8, dpi = 300)

fg %>%
  filter(District != 'Maine') %>%
  filter(District != 'Massachusetts') %>%
  filter(District != 'Swellendam') %>%
  filter(District != 'Tulbagh') %>%
  filter(District != 'Graaff Reinet') %>%
  ggplot(aes(District, Slaves)) +
  geom_violin(alpha = 0.8) +
  geom_boxplot(alpha = 0.8) +
  scale_y_log10() +
  scale_fill_grey() +
  facet_wrap(~Year) +
  #coord_cartesian(ylim = c(15, 50)) +
  labs(x = 'District',
       y = 'Number of slaves per household (logorithmic)') +
  theme

fg_V %>%
  filter(District != 'Maine') %>%
  filter(District != 'Massachusetts') %>%
  filter(District != 'Swellendam') %>%
  filter(District != 'Tulbagh') %>%
  filter(District != 'Graaff Reinet') %>%
  ggplot(aes(District, V_Slaves)) +
  geom_violin(alpha = 0.8) +
  geom_boxplot(alpha = 0.8) +
  scale_y_log10() +
  scale_fill_grey() +
  facet_wrap(~Year) +
  #coord_cartesian(ylim = c(15, 50)) +
  labs(x = 'District',
       y = 'Value of slaves per household (logorithmic)') +
  theme



###FIGURE 8


fg %>%
  filter(District != 'Maine') %>%
  filter(District != 'Massachusetts') %>%
  filter(District != 'Tulbagh') %>%
  filter(District != 'Swellendam') %>%
  filter(District != 'Graaff Reinet') %>%
  mutate(District = as.factor(District)) %>%
  mutate(Year = as.factor(Year)) %>%
  ggplot(aes(x = Slaves, linetype = Year)) +
  stat_lorenz(desc = FALSE) +
  geom_abline(color = "grey") +
  scale_fill_grey() +
  facet_wrap(~District) +
  #coord_cartesian(ylim = c(15, 50)) +
  labs(x = 'Cumulative percentage of settler households',
       y = 'Cumulative percentage of slave ownership') +
  theme



f = fg_V %>%
  filter(District != 'Maine') %>%
  filter(District != 'Massachusetts') %>%
  #filter(District != 'Tulbagh') %>%
  #filter(District != 'Swellendam') %>%
  #filter(District != 'Graaff Reinet') %>%
  filter(Slaves > 0) %>%
  mutate(Country = as.factor(Country)) %>%
  #mutate(Year = as.factor(Year)) %>%
  ggplot(aes(x = Slaves, linetype = Country)) +
  stat_lorenz(desc = FALSE) +
  geom_abline(color = "grey") +
  scale_fill_grey() +
  #facet_wrap(~District) +
  #coord_cartesian(ylim = c(15, 50)) +
  labs(x = 'Cumulative % of settler households',
       y = 'Slaves') +
  theme

e = fg_V %>%
  #filter(District != 'Maine') %>%
  #filter(District != 'Massachusetts') %>%
  #filter(District != 'Tulbagh') %>%
  #filter(District != 'Swellendam') %>%
  #filter(District != 'Graaff Reinet') %>%
  filter(Cattle > 0 | Sheep > 0) %>%
  mutate(Agric = rowSums(dplyr::select(., V_Cattle, V_Sheep), na.rm = TRUE)) %>%
  #filter(Slaves > 0) %>%
  mutate(Country = as.factor(Country)) %>%
  #mutate(Year = as.factor(Year)) %>%
  ggplot(aes(x = Agric, linetype = Country)) +
  stat_lorenz(desc = FALSE) +
  geom_abline(color = "grey") +
  scale_fill_grey() +
  #facet_wrap(~District) +
  #coord_cartesian(ylim = c(15, 50)) +
  labs(x = 'Cumulative % of settler households',
       y = 'Livestock') +
  theme

g = ggarrange(e + rremove("x.title"), f + rremove("x.title"), 
          ncol = 2, nrow = 1)

h = fg_V %>%
  #filter(District != 'Maine') %>%
  #filter(District != 'Massachusetts') %>%
  #filter(District != 'Tulbagh') %>%
  #filter(District != 'Swellendam') %>%
  #filter(District != 'Graaff Reinet') %>%
  filter(District != 'Virginia') %>%
  filter(Wheatreaped > 0 | Barleyreaped > 0 | Ryereaped > 0 | Oatsreaped > 0 | Cornreaped > 0) %>%
  mutate(Crops_V = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn), na.rm = TRUE)) %>%
  #filter(Slaves > 0) %>%
  mutate(Country = as.factor(Country)) %>%
  #mutate(Year = as.factor(Year)) %>%
  ggplot(aes(x = Crops_V, linetype = Country)) +
  stat_lorenz(desc = FALSE) +
  geom_abline(color = "grey") +
  scale_fill_grey() +
  #facet_wrap(~District) +
  #coord_cartesian(ylim = c(15, 50)) +
  labs(x = 'Cumulative % of settler households',
       y = 'Crops') +
  theme

fig8 <- ggarrange(g + rremove("x.title"), h + rremove("x.title"), 
              ncol = 1, nrow = 2)

fig8
ggsave("fig8.tiff", width = 12, height = 8, dpi = 300)

###GINI

gini1 = fg2_V %>%
  #filter(District != 'Maine') %>%
  #filter(District != 'Massachusetts') %>%
  #filter(Slaves > 0) %>%
  filter(Wheatreaped > 0 | Barleyreaped > 0 | Ryereaped > 0 | Oatsreaped > 0 | Cornreaped > 0 | Wine > 0 | Cattle > 0 | Sheep > 0) %>%
  mutate(Agric = rowSums(dplyr::select(., V_Cattle, V_Sheep), na.rm = TRUE)) %>%
  group_by(District) %>%
  summarise(obs = n(),
            Agric = Gini(Agric,corr = FALSE, na.rm = TRUE),
            Slaves = Gini(Slaves,corr = FALSE, na.rm = TRUE))

gini2 = fg2_V %>%
  filter(District != 'Virginia') %>%
  #filter(Slaves > 0) %>%
  mutate(Crops_V = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn), na.rm = TRUE)) %>%
  mutate(CropsW_V = rowSums(dplyr::select(., V_Wheat, V_Barley, V_Rye, V_Oats, V_Corn, V_Wine, V_Brandy), na.rm = TRUE)) %>%
  filter(Wheatreaped > 0 | Barleyreaped > 0 | Ryereaped > 0 | Oatsreaped > 0 | Cornreaped > 0 | Wine > 0 | Cattle > 0 | Sheep > 0) %>%
  mutate(Agric = rowSums(dplyr::select(., V_Cattle, V_Sheep), na.rm = TRUE)) %>%
  group_by(District) %>%
  summarise(obs = n(),
            Crops_V = Gini(Crops_V,corr = FALSE, na.rm = TRUE),
            CropsW_V = Gini(CropsW_V,corr = FALSE, na.rm = TRUE))

