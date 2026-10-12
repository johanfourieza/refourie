library(tidyverse)
library(ggrepel)
library(foreign)

setwd(Sys.getenv("P05_WORK")) # [ENV P2] was: setwd("C:\\Users\\ddeka\\Dropbox\\Shared_projects\\Spanish_flu_group_folder")

data1970_african = read.dta("data\\original\\census\\census1970\\SA Census 1970 African 5% v01.2.dta")
data1970_african_sub = data1970_african[,c("ENUMAREA", "PROVINCE","POPGRP", "SEX", "AGE", "EDUC")]
data1970_african_sub$racerecode = ifelse(data1970_african_sub$POPGRP=="South African Blacks","Black (South African)",NA)
data1970_african_sub$racerecode = ifelse(data1970_african_sub$POPGRP=="Foreign Blacks","Black (Foreign)",data1970_african_sub$racerecode)

data1970_african_sub$EDUCrecode = ifelse(data1970_african_sub$EDUC=="None", 0, NA)
data1970_african_sub$EDUCrecode = ifelse(data1970_african_sub$EDUC=="Sub A"|data1970_african_sub$EDUC=="Sub B"|data1970_african_sub$EDUC=="Standard 1", 1, data1970_african_sub$EDUCrecode)
data1970_african_sub$EDUCrecode = ifelse(data1970_african_sub$EDUC=="Standard 2", 2, data1970_african_sub$EDUCrecode)
data1970_african_sub$EDUCrecode = ifelse(data1970_african_sub$EDUC=="Standard 3", 3, data1970_african_sub$EDUCrecode)
data1970_african_sub$EDUCrecode = ifelse(data1970_african_sub$EDUC=="Standard 4", 4, data1970_african_sub$EDUCrecode)
data1970_african_sub$EDUCrecode = ifelse(data1970_african_sub$EDUC=="Standard 5", 5, data1970_african_sub$EDUCrecode)
data1970_african_sub$EDUCrecode = ifelse(data1970_african_sub$EDUC=="Standard 6-7", 6, data1970_african_sub$EDUCrecode)
data1970_african_sub$EDUCrecode = ifelse(data1970_african_sub$EDUC=="Standard 8-1", 7, data1970_african_sub$EDUCrecode)
data1970_african_sub$EDUCrecode = ifelse(data1970_african_sub$EDUC=="Standard 10 (Matric)", 8, data1970_african_sub$EDUCrecode)

data1970_african_sub = subset(data1970_african_sub, select=-c(3,6))

data1970_whitecolindasian = read.csv("data\\original\\census\\census1970\\sa census 1970 whitescolouredsasians_full_v1.2.csv")
data1970_whitecolindasian_sub = data1970_whitecolindasian[,c("ENUMAREA", "PROVINCE","POPGRP", "SEX", "AGE", "EDUC")]

data1970_whitecolindasian_sub$racerecode = ifelse(data1970_whitecolindasian_sub$POPGRP==1,"White",NA)
data1970_whitecolindasian_sub$racerecode = ifelse(data1970_whitecolindasian_sub$POPGRP==2,"Coloured",data1970_whitecolindasian_sub$racerecode)
data1970_whitecolindasian_sub$racerecode = ifelse(data1970_whitecolindasian_sub$POPGRP==3,"All Other Groups",data1970_whitecolindasian_sub$racerecode)
data1970_whitecolindasian_sub$racerecode = ifelse(is.na(data1970_whitecolindasian_sub$racerecode)==T,"All Other Groups", data1970_whitecolindasian_sub$racerecode)

data1970_whitecolindasian_sub$EDUCrecode = ifelse(data1970_whitecolindasian_sub$EDUC==0, 0, NA)
data1970_whitecolindasian_sub$EDUCrecode = ifelse(data1970_whitecolindasian_sub$EDUC==1, 1, data1970_whitecolindasian_sub$EDUCrecode)
data1970_whitecolindasian_sub$EDUCrecode = ifelse(data1970_whitecolindasian_sub$EDUC==2, 2, data1970_whitecolindasian_sub$EDUCrecode)
data1970_whitecolindasian_sub$EDUCrecode = ifelse(data1970_whitecolindasian_sub$EDUC==3, 3, data1970_whitecolindasian_sub$EDUCrecode)
data1970_whitecolindasian_sub$EDUCrecode = ifelse(data1970_whitecolindasian_sub$EDUC==4, 4, data1970_whitecolindasian_sub$EDUCrecode)
data1970_whitecolindasian_sub$EDUCrecode = ifelse(data1970_whitecolindasian_sub$EDUC==5, 5, data1970_whitecolindasian_sub$EDUCrecode)
data1970_whitecolindasian_sub$EDUCrecode = ifelse(data1970_whitecolindasian_sub$EDUC==6|data1970_whitecolindasian_sub$EDUC==7, 6, data1970_whitecolindasian_sub$EDUCrecode)
data1970_whitecolindasian_sub$EDUCrecode = ifelse(data1970_whitecolindasian_sub$EDUC==8|data1970_whitecolindasian_sub$EDUC==9, 7, data1970_whitecolindasian_sub$EDUCrecode)
data1970_whitecolindasian_sub$EDUCrecode = ifelse(data1970_whitecolindasian_sub$EDUC>=10, 8, data1970_whitecolindasian_sub$EDUCrecode)
data1970_whitecolindasian_sub$EDUCrecode = ifelse(data1970_whitecolindasian_sub$EDUC==20, NA, data1970_whitecolindasian_sub$EDUCrecode)
#data1970_whitecolindasian_sub$EDUCrecode = ifelse(is.na(data1970_whitecolindasian_sub$EDUCrecode)==T, data1970_whitecolindasian_sub$EDUC, data1970_whitecolindasian_sub$EDUCrecode)

data1970_whitecolindasian_sub$SEX = ifelse(data1970_whitecolindasian_sub$SEX==1, "Male", data1970_whitecolindasian_sub$SEX)
data1970_whitecolindasian_sub$SEX = ifelse(data1970_whitecolindasian_sub$SEX==2, "Female", data1970_whitecolindasian_sub$SEX)

data1970_whitecolindasian_sub = subset(data1970_whitecolindasian_sub, select=-c(3,6))

data1970 = bind_rows(data1970_african_sub,data1970_whitecolindasian_sub)

data1970$birthyear = 1970 - data1970$AGE
data1970$count = 1

data1970$bantustan = ifelse(data1970$PROVINCE>4,1,0)

data1970$provincename = ifelse(data1970$PROVINCE==1,"Cape",NA)
data1970$provincename = ifelse(data1970$PROVINCE==2,"Natal",data1970$provincename)
data1970$provincename = ifelse(data1970$PROVINCE==3,"Transvaal",data1970$provincename)
data1970$provincename = ifelse(data1970$PROVINCE==4,"Orange Free State",data1970$provincename)
data1970$provincename = ifelse(data1970$PROVINCE==5,"Orange Free State",data1970$provincename)
data1970$provincename = ifelse(data1970$PROVINCE==6,"Transvaal",data1970$provincename)
data1970$provincename = ifelse(data1970$PROVINCE==7,"Transvaal",data1970$provincename)
data1970$provincename = ifelse(data1970$PROVINCE==8,"Transvaal",data1970$provincename)
data1970$provincename = ifelse(data1970$PROVINCE==9,"Transvaal",data1970$provincename) #Partially Transvaal, and Cape
data1970$provincename = ifelse(data1970$PROVINCE==10,"Transvaal",data1970$provincename)
data1970$provincename = ifelse(data1970$PROVINCE==11 ,"Cape",data1970$provincename)
data1970$provincename = ifelse(data1970$PROVINCE==12 ,"Cape",data1970$provincename)
data1970$provincename = ifelse(data1970$PROVINCE==13 ,"Natal",data1970$provincename)

data1970$regionname = ifelse(data1970$PROVINCE==1,"Cape",NA)
data1970$regionname = ifelse(data1970$PROVINCE==2,"Natal",data1970$regionname)
data1970$regionname = ifelse(data1970$PROVINCE==3,"Transvaal",data1970$regionname)
data1970$regionname = ifelse(data1970$PROVINCE==4,"Orange Free State",data1970$regionname)
data1970$regionname = ifelse(data1970$PROVINCE==5,"Orange Free State",data1970$regionname)
data1970$regionname = ifelse(data1970$PROVINCE==6,"Transvaal",data1970$regionname)
data1970$regionname = ifelse(data1970$PROVINCE==7,"Transvaal",data1970$regionname)
data1970$regionname = ifelse(data1970$PROVINCE==8,"Transvaal",data1970$regionname)
data1970$regionname = ifelse(data1970$PROVINCE==9,"Transvaal",data1970$regionname)
data1970$regionname = ifelse(data1970$PROVINCE==10,"Transvaal",data1970$regionname)
data1970$regionname = ifelse(data1970$PROVINCE==11 ,"Cape",data1970$regionname)
data1970$regionname = ifelse(data1970$PROVINCE==12 ,"Transkei",data1970$regionname)
data1970$regionname = ifelse(data1970$PROVINCE==13 ,"KwaZulu",data1970$regionname)

data1970$bantustanname = ifelse(data1970$PROVINCE==1,NA,NA)
data1970$bantustanname = ifelse(data1970$PROVINCE==2,NA,data1970$bantustanname)
data1970$bantustanname = ifelse(data1970$PROVINCE==3,NA,data1970$bantustanname)
data1970$bantustanname = ifelse(data1970$PROVINCE==4,NA,data1970$bantustanname)
data1970$bantustanname = ifelse(data1970$PROVINCE==5,"Qwaqwa",data1970$bantustanname)
data1970$bantustanname = ifelse(data1970$PROVINCE==6,"Lebowa",data1970$bantustanname)
data1970$bantustanname = ifelse(data1970$PROVINCE==7,"Gazankulu",data1970$bantustanname)
data1970$bantustanname = ifelse(data1970$PROVINCE==8,"KaNgwane",data1970$bantustanname)
data1970$bantustanname = ifelse(data1970$PROVINCE==9,"Bophuthatswana",data1970$bantustanname)
data1970$bantustanname = ifelse(data1970$PROVINCE==10,"Venda",data1970$bantustanname)
data1970$bantustanname = ifelse(data1970$PROVINCE==11 ,"Ciskei",data1970$bantustanname)
data1970$bantustanname = ifelse(data1970$PROVINCE==12 ,"Transkei",data1970$bantustanname)
data1970$bantustanname = ifelse(data1970$PROVINCE==13 ,"KwaZulu",data1970$bantustanname)

#Randomized reclassification
data1970$age_endszero = 0
data1970$age_endszero[grep("0",substring(as.character(data1970$birthyear),4))] = 1

data1970$birthyear_randreclass = c()
data1970$randomreclass = sample(c(0,1,-1), nrow(data1970), prob=c(0.9,0.05,0.05), replace=T)

data1970$birthyear_randreclass[data1970$age_endszero==1 & data1970$randomreclass==1] = data1970$birthyear[data1970$age_endszero==1 & data1970$randomreclass==1] + 1
data1970$birthyear_randreclass[data1970$age_endszero==1 & data1970$randomreclass==-1] = data1970$birthyear[data1970$age_endszero==1 & data1970$randomreclass==-1] - 1
data1970$birthyear_randreclass[data1970$age_endszero==1 & data1970$randomreclass==0] = data1970$birthyear[data1970$age_endszero==1 & data1970$randomreclass==0] 
data1970$birthyear_randreclass[data1970$age_endszero==0] = data1970$birthyear[data1970$age_endszero==0]


#Basic regression:
census1970_birthyearcount = 
  data1970 %>%
  group_by(birthyear) %>%
  summarise(births = sum(count, na.rm=T), bantustan = mean(bantustan, na.rm=T), education = mean(EDUCrecode, na.rm=T))

census1970_birthyearcount$zeroyear = 0
census1970_birthyearcount$zeroyear[grep("0",substring(as.character(census1970_birthyearcount$birthyear),4))] = 1

census1970_birthyearcount$nineyear = 0
census1970_birthyearcount$nineyear[grep("9",substring(as.character(census1970_birthyearcount$birthyear),4))] = 1

census1970_birthyearcount$birthyear[census1970_birthyearcount$zeroyear==1]

(census1970_birthyearcount$births[census1970_birthyearcount$zeroyear==1] - 
    census1970_birthyearcount$births[census1970_birthyearcount$nineyear==1])/census1970_birthyearcount$births[census1970_birthyearcount$nineyear==1]

census1970_birthyearcount$sflu_treated = ifelse(census1970_birthyearcount$birthyear==1919, 1, 0)
census1970_birthyearcount$timetrend = c(1:nrow(census1970_birthyearcount))
census1970_birthyearcount$timetrend_sq = census1970_birthyearcount$timetrend*census1970_birthyearcount$timetrend

summary(lm(education ~ sflu_treated, census1970_birthyearcount[census1970_birthyearcount$birthyear>1917 & census1970_birthyearcount$birthyear<1921,]))


##EITHER 1918 or 1919 would be the population of interest
ggplot(census1970_birthyearcount[census1970_birthyearcount$birthyear>1910 & census1970_birthyearcount$birthyear<1930,], 
       aes(x=birthyear, y=births)) + 
  geom_point() +
  geom_text_repel(aes(label=ifelse(birthyear==1919, birthyear, "")), 
                  alpha=.75, min.segment.length = 0, segment.size=.5, point.padding = .1) +
  geom_smooth(se=F, alpha=.75) +  
  scale_y_continuous(limits=c(20000,90000),"Number of African, Asian, Coloured, Indian, and White Individuals (Sample)") + 
  scale_x_continuous("Birth Year") +
  theme_bw() + 
  theme(legend.title = element_blank(), axis.line = element_line(colour = "black"),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.text.x = element_text(size=12),
        axis.text.y = element_text(size=12, angle=15),
        axis.title.x=element_text(size=13, vjust=.5),
        axis.title.y=element_text(size=13,angle=90,vjust=0))
ggsave("outputs\\figures\\census1970_births_20yearwindow.png", width = 9, height = 7)




#1960
load("data\\original\\census\\census1960\\SA Census 1960 Indians and Asiatics_v1.1.rdata")
load("data\\original\\census\\census1960\\SA Census 1960 Coloureds_v1.1.rdata")
load("data\\original\\census\\census1960\\SA Census 1960 Whites_v1.1.rdata")

census_all = rbind(SA_Census_1960_Whites_v1.1, SA_Census_1960_Indians_and_Asiatics_v1.1, SA_Census_1960_Coloureds_v1.1)
census_all$Age_recode = ifelse(census_all$Age==999, NA, census_all$Age)
census_all$birthyear = 1960 - census_all$Age_recode

length(unique(census_all$District))
hist(census_all$birthyear, breaks=seq(1850,1960,1))
vline(1918)

ggplot(census_all, aes(x=birthyear)) + 
  geom_histogram(binwidth = 1) + 
  geom_vline(xintercept = 1918)

census_all$count = 1
unique(census_all$Race)

census_all$Race_recode = ifelse(census_all$Race==1, "White", NA)
census_all$Race_recode = ifelse(census_all$Race==2|census_all$Race==3|census_all$Race==4|census_all$Race==5, "Coloured", census_all$Race_recode)
census_all$Race_recode = ifelse(census_all$Race==6|census_all$Race==7|census_all$Race==8, "Indian and Asian", census_all$Race_recode)
unique(census_all$Race_recode)

census_birthyearcount = 
  census_all %>%
  group_by(birthyear) %>%
  summarise(births = sum(count, na.rm=T))


##EITHER 1918 or 1919 would be the population of interest
ggplot(census_birthyearcount[census_birthyearcount$birthyear>1910 & census_birthyearcount$birthyear<1930,], 
       aes(x=birthyear, y=births)) + 
  geom_point() +
  geom_text_repel(aes(label=ifelse(birthyear==1919, birthyear, "")), 
                  alpha=.75, min.segment.length = 0, segment.size=.5, point.padding = .1, 
                  segment.curvature = 1) +
  geom_smooth(se=F, alpha=.75) +  
  scale_y_continuous(limits=c(3500,9500),"Number of Asian, Coloured, Indian, and White Individuals (Sample)") + 
  scale_x_continuous("Birth Year") +
  theme_bw() + 
  theme(legend.title = element_blank(), axis.line = element_line(colour = "black"),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.text.x = element_text(size=12),
        axis.text.y = element_text(size=12, angle=15),
        axis.title.x=element_text(size=13, vjust=.5),
        axis.title.y=element_text(size=13,angle=90,vjust=0))
ggsave("outputs\\figures\\census1960_births_20yearwindow.png", width = 9, height = 7)

