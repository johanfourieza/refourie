#usual suspects
require(data.table)
require(reshape2)
require(ggplot2)
#require(tidyverse)
require(RColorBrewer)
library(plm)
library(lattice)
library(plotly)
library(stargazer)
library(Amelia)
library(ineq)
library(xtable)
library(stringr)

require(foreign)
require(plyr)
require(RColorBrewer)
require(readxl)
#require(dummies)  # [S2 PATCH 1] archived on CRAN, not installed; shim defined below remove()
require(gridExtra)

remove(list=ls())
# [S2 PATCH 2] environment: data paths (A6) and dummies::dummy shim
source(file.path(Sys.getenv("REFOURIE_ROOT"), "tools", "paths.R")); DATA_DIR <- dpath("P10_FI", "original", "R_CapeTownAnglican", "Data")
dummy <- function(x, data = NULL, sep = "", drop = TRUE, fun = as.integer, verbose = FALSE) { lv <- sort(unique(x)); m <- sapply(lv, function(l) fun(x == l)); m <- matrix(m, nrow = length(x)); colnames(m) <- paste0("angreg", sep, lv); m }  # dummies 1.5.6 names columns after the first argument of the outermost call (here cbind(angreg, ...)), i.e. angreg_<year>
melt <- function(data, ...) if (data.table::is.data.table(data)) data.table::melt(data, ...) else reshape2::melt(data, ...)  # [S2 PATCH 4] restore 2019 dispatch: data.table <1.14 registered melt.data.table on the reshape2::melt generic; under data.table 1.18 reshape2::melt returns a data.frame and the later dt[, ..., by=] calls fail

anglican = read_excel(file.path(DATA_DIR,Sys.getenv("P10_CT_FILE", "CT 1 March 2019.xlsx")),"Cape Town", col_names = TRUE)  # [S2 PATCH 5] file name overridable for the data-vintage diagnostic run only; default = file named in the original
ang = data.table(anglican)

sex = read_excel(file.path(DATA_DIR,"Cape Town sex ratio.xlsx"),"Ratio", col_names = TRUE)

moccu = read_excel(file.path(DATA_DIR,"Occupations.xlsx"),"uniquemnames", col_names = TRUE)
foccu = read_excel(file.path(DATA_DIR,"Occupations.xlsx"),"uniquefnames", col_names = TRUE)

#jeanne = read_excel(file.path(DATA_DIR,"jeanneshort.xls"),"Sheet1", col_names = TRUE)
#jeanne = data.table(jeanne)
#jeanne = jeanne[, .(image = jeanne$imageid, pid = jeanne$parishid, year = jeanne$year, day = jeanne$dateday_raw, mhisco = jeanne$m_hisco, fhisco = jeanne$fm_hisco,
                #msurname = jeanne$malesurname_raw, mname = jeanne$malename_raw, fsurname = jeanne$malesurname_raw, fname = jeanne$femalename_raw)]



pd = position_dodge(0.75)

#############################SummarySE#################################

summarySE <- function(data=NULL, measurevar, groupvars=NULL, na.rm=FALSE,
                      conf.interval=.95, .drop=TRUE) {
  library(plyr)
  
  # New version of length which can handle NA's: if na.rm==T, don't count them
  length2 <- function (x, na.rm=FALSE) {
    if (na.rm) sum(!is.na(x))
    else       length(x)
  }
  
  # This does the summary. For each group's data frame, return a vector with
  # N, mean, and sd
  datac <- ddply(data, groupvars, .drop=.drop,
                 .fun = function(xx, col) {
                   c(N    = length2(xx[[col]], na.rm=na.rm),
                     mean = mean   (xx[[col]], na.rm=na.rm),
                     sd   = sd     (xx[[col]], na.rm=na.rm)
                   )
                 },
                 measurevar
  )
  
  # Rename the "mean" column    
  datac <- rename(datac, c("mean" = measurevar))
  
  datac$se <- datac$sd / sqrt(datac$N)  # Calculate standard error of the mean
  
  # Confidence interval multiplier for standard error
  # Calculate t-statistic for confidence interval: 
  # e.g., if conf.interval is .95, use .975 (above/below), and use df=N-1
  ciMult <- qt(conf.interval/2 + .5, datac$N-1)
  datac$ci <- datac$se * ciMult
  
  return(datac)
}

## Gives count, mean, standard deviation, standard error of the mean, and confidence interval (default 95%).
##   data: a data frame.
##   measurevar: the name of a column that contains the variable to be summariezed
##   groupvars: a vector containing names of columns that contain grouping variables
##   na.rm: a boolean that indicates whether to ignore NA's
##   conf.interval: the percent range of the confidence interval (default is 95%)
summarySE <- function(data=NULL, measurevar, groupvars=NULL, na.rm=FALSE,
                      conf.interval=.95, .drop=TRUE) {
  library(plyr)
  
  # New version of length which can handle NA's: if na.rm==T, don't count them
  length2 <- function (x, na.rm=FALSE) {
    if (na.rm) sum(!is.na(x))
    else       length(x)
  }
  
  # This does the summary. For each group's data frame, return a vector with
  # N, mean, and sd
  datac <- ddply(data, groupvars, .drop=.drop,
                 .fun = function(xx, col) {
                   c(N    = length2(xx[[col]], na.rm=na.rm),
                     mean = mean   (xx[[col]], na.rm=na.rm),
                     sd   = sd     (xx[[col]], na.rm=na.rm)
                   )
                 },
                 measurevar
  )
  
  # Rename the "mean" column    
  datac <- rename(datac, c("mean" = measurevar))
  
  datac$se <- datac$sd / sqrt(datac$N)  # Calculate standard error of the mean
  
  # Confidence interval multiplier for standard error
  # Calculate t-statistic for confidence interval: 
  # e.g., if conf.interval is .95, use .975 (above/below), and use df=N-1
  ciMult <- qt(conf.interval/2 + .5, datac$N-1)
  datac$ci <- datac$se * ciMult
  
  return(datac)
}

###############################################

#####################Cleaning##################

trim = function (trim) gsub("^\\s+|\\s+$", "", trim)

ang = ang[, .(id = ang$IndID, image = ang$ImageID, pid = ang$ParishID, year = ang$`Date year`, month = ang$`Date month`, day = ang$`Date day`, mname = ang$`Male name`, 
              msurname = ang$`Male surname`, mage = ang$`Male age`, mcountry = ang$`Male country`, mrace = ang$`Male race`,
              mcondition = ang$`Male condition`, mrank = ang$`Male rank or profession`, mtown = ang$`Male town`,
              bol = ang$`Banns or Licence`, fname = ang$`Female name`, fsurname = ang$`Female surname`, fage = ang$`Female age`,
              ftown = ang$`Female town`, frace = ang$`Female race`, fcountry = ang$`Female country`, fcondition = ang$`Female condition`,
              frank = ang$`Female rank or profession`, msign = ang$`Male signed`, fsign = ang$`Female Signed`, mwsign = ang$`Male witness signed`,
              fwsign = ang$`Female witness signed`, racechange = ang$`Race change`)]

###Year

ang$decade = ang$year
ang$decade[ang$decade < 1871] = 1870
ang$decade[ang$decade < 1881 & ang$decade > 1870] = 1880
ang$decade[ang$decade < 1891 & ang$decade > 1880] = 1890
ang$decade[ang$decade < 1901 & ang$decade > 1890] = 1900
ang$decade[ang$decade < 1911 & ang$decade > 1900] = 1910
ang$decade[ang$decade < 1921 & ang$decade > 1910] = 1920
ang$decade[ang$decade < 1931 & ang$decade > 1920] = 1930
ang$decade[ang$decade < 1941 & ang$decade > 1930] = 1940
ang$decade[ang$decade < 1951 & ang$decade > 1940] = 1950
ang$decade[ang$decade < 1961 & ang$decade > 1950] = 1960
ang$decade[ang$decade < 1971 & ang$decade > 1960] = 1970
ang$decade[ang$decade < 1981 & ang$decade > 1970] = 1980
ang$decade[ang$decade > 1980] = 1990

###Age

ang$mage[ang$mage == "F"] = NA
ang$mage[ang$mage == "M"] = NA
ang$mage[ang$mage == "Full"] = NA
ang$mage[ang$mage == "Minor"] = NA
ang$mage[ang$mage == "."] = NA

ang$fage[ang$fage == "F"] = NA
ang$fage[ang$fage == "M"] = NA
ang$fage[ang$fage == "Full"] = NA
ang$fage[ang$fage == "Minor"] = NA
ang$fage[ang$fage == "."] = NA

ang$mage = as.numeric(ang$mage)
ang$fage = as.numeric(ang$fage)

ang$gap = ang$mage - ang$fage

###Birthdecade

ang$bdecade = ang$year - ang$fage
ang$bdecade[ang$bdecade < 1871] = 1870
ang$bdecade[ang$bdecade < 1881 & ang$bdecade > 1870] = 1880
ang$bdecade[ang$bdecade < 1891 & ang$bdecade > 1880] = 1890
ang$bdecade[ang$bdecade < 1901 & ang$bdecade > 1890] = 1900
ang$bdecade[ang$bdecade < 1911 & ang$bdecade > 1900] = 1910
ang$bdecade[ang$bdecade < 1921 & ang$bdecade > 1910] = 1920
ang$bdecade[ang$bdecade < 1931 & ang$bdecade > 1920] = 1930
ang$bdecade[ang$bdecade < 1941 & ang$bdecade > 1930] = 1940
ang$bdecade[ang$bdecade < 1951 & ang$bdecade > 1940] = 1950
ang$bdecade[ang$bdecade < 1961 & ang$bdecade > 1950] = 1960
ang$bdecade[ang$bdecade < 1971 & ang$bdecade > 1960] = 1970
ang$bdecade[ang$bdecade < 1981 & ang$bdecade > 1970] = 1980
ang$bdecade[ang$bdecade > 1980] = 1990


###Country

#############

ang$mcountrydum = ang$mcountry

ang$mcountrydum[ang$mcountrydum == "."] = NA
ang$mcountrydum[ang$mcountrydum == "?"] = NA
ang$mcountrydum[ang$mcountrydum == "Holland"] = 1
ang$mcountrydum[ang$mcountrydum == "Scotland"] = 1
ang$mcountrydum[ang$mcountrydum == "South Africa"] = 0
ang$mcountrydum[ang$mcountrydum == "Ireland"] = 1
ang$mcountrydum[ang$mcountrydum == "Amatongaland"] = 0
ang$mcountrydum[ang$mcountrydum == "England"] = 1
ang$mcountrydum[ang$mcountrydum == "Great Britain"] = 1
ang$mcountrydum[ang$mcountrydum == "St. Helena"] = 1
ang$mcountrydum[ang$mcountrydum == "Italy"] = 1
ang$mcountrydum[ang$mcountrydum == "Pondoland"] = 0
ang$mcountrydum[ang$mcountrydum == "Canada"] = 1
ang$mcountrydum[ang$mcountrydum == "Sweden"] = 1
ang$mcountrydum[ang$mcountrydum == "France"] = 1
ang$mcountrydum[ang$mcountrydum == "Northern Rhodesia"] = 1
ang$mcountrydum[ang$mcountrydum == "United Kingdom"] = 1
ang$mcountrydum[ang$mcountrydum == "Southern Rhodesia"] = 1
ang$mcountrydum[ang$mcountrydum == "South West Africa"] = 1
ang$mcountrydum[ang$mcountrydum == "Morroco"] = 1
ang$mcountrydum[ang$mcountrydum == "South Rhodesia"] = 1
ang$mcountrydum[ang$mcountrydum == "Angola"] = 1
ang$mcountrydum[ang$mcountrydum == "Germany"] = 1
ang$mcountrydum[ang$mcountrydum == "Canary Islands"] = 1
ang$mcountrydum[ang$mcountrydum == "Norway"] = 1
ang$mcountrydum[ang$mcountrydum == "Denmark"] = 1
ang$mcountrydum[ang$mcountrydum == "Nyasaland"] = 1
ang$mcountrydum[ang$mcountrydum == "Barotseland"] = 1
ang$mcountrydum[ang$mcountrydum == "Portuguese East Africa "] = 1
ang$mcountrydum[ang$mcountrydum == "Mozambique"] = 1
ang$mcountrydum[ang$mcountrydum == "Madagascar"] = 1
ang$mcountrydum[ang$mcountrydum == "Basutoland"] = 1
ang$mcountrydum[ang$mcountrydum == "Morocco"] = 1
ang$mcountrydum[ang$mcountrydum == "Barotzeland"] = 1
ang$mcountrydum[ang$mcountrydum == "East Africa"] = 1
ang$mcountrydum[ang$mcountrydum == "South Arica C"] = 0
ang$mcountrydum[ang$mcountrydum == "Rhodesia"] = 1
ang$mcountrydum[ang$mcountrydum == "Nigeria"] = 1
ang$mcountrydum[ang$mcountrydum == "U.S.A."] = 1
ang$mcountrydum[ang$mcountrydum == "West Indies"] = 1
ang$mcountrydum[ang$mcountrydum == "Switzerland"] = 1
ang$mcountrydum[ang$mcountrydum == "Wales"] = 1
ang$mcountrydum[ang$mcountrydum == "India"] = 1
ang$mcountrydum[ang$mcountrydum == "Greece"] = 1
ang$mcountrydum[ang$mcountrydum == "Australia"] = 1
ang$mcountrydum[ang$mcountrydum == "Africa"] = 1
ang$mcountrydum[ang$mcountrydum == "Northern Ireland"] = 1
ang$mcountrydum[ang$mcountrydum == "Federated Malay States"] = 1
ang$mcountrydum[ang$mcountrydum == "Zululand"] = 0
ang$mcountrydum[ang$mcountrydum == "Suriname"] = 1
ang$mcountrydum[ang$mcountrydum == "Scotland, U.K."] = 1
ang$mcountrydum[ang$mcountrydum == "Malaya"] = 1
ang$mcountrydum[ang$mcountrydum == "New Zealand"] = 1
ang$mcountrydum[ang$mcountrydum == "Madeira"] = 1
ang$mcountrydum[ang$mcountrydum == "Tanganyika"] = 1
ang$mcountrydum[ang$mcountrydum == "Wales, U.K."] = 1
ang$mcountrydum[ang$mcountrydum == "Nyassaland"] = 1
ang$mcountrydum[ang$mcountrydum == "South Seas"] = 1
ang$mcountrydum[ang$mcountrydum == "St Helena"] = 1
ang$mcountrydum[ang$mcountrydum == "Burmah"] = 1
ang$mcountrydum[ang$mcountrydum == "Kenya, East Africa"] = 1
ang$mcountrydum[ang$mcountrydum == "Egypt"] = 1
ang$mcountrydum[ang$mcountrydum == "Austria"] = 1
ang$mcountrydum[ang$mcountrydum == "Mauritius"] = 1
ang$mcountrydum[ang$mcountrydum == "North Ireland"] = 1
ang$mcountrydum[ang$mcountrydum == "Yugoslavia"] = 1
ang$mcountrydum[ang$mcountrydum == "Belgium"] = 1
ang$mcountrydum[ang$mcountrydum == "China"] = 1
ang$mcountrydum[ang$mcountrydum == "Malaysia"] = 1
ang$mcountrydum[ang$mcountrydum == "Kenya"] = 1
ang$mcountrydum[ang$mcountrydum == "Jamaica"] = 1
ang$mcountrydum[ang$mcountrydum == "India(British Descent)"] = 1
ang$mcountrydum[ang$mcountrydum == "Indonesia"] = 1
ang$mcountrydum[ang$mcountrydum == "Netherlands"] = 1
ang$mcountrydum[ang$mcountrydum == "Portuguese East Africa"] = 1
ang$mcountrydum[ang$mcountrydum == "North Wales, Great Britain"] = 1
ang$mcountrydum[ang$mcountrydum == "Eastern Indonesia"] = 1
ang$mcountrydum[ang$mcountrydum == "Tristan da Cunha"] = 1
ang$mcountrydum[ang$mcountrydum == "St Helena Island"] = 1
ang$mcountrydum[ang$mcountrydum == "United States of America"] = 1
ang$mcountrydum[ang$mcountrydum == "British East Africa"] = 1
ang$mcountrydum[ang$mcountrydum == "Damaraland"] = 1
ang$mcountrydum[ang$mcountrydum == "Wales(Great Britain)"] = 1
ang$mcountrydum[ang$mcountrydum == "South Wales, Great Britain"] = 1
ang$mcountrydum[ang$mcountrydum == "British Isles"] = 1
ang$mcountrydum[ang$mcountrydum == "Belgian Congo"] = 1
ang$mcountrydum[ang$mcountrydum == "West Africa"] = 1
ang$mcountrydum[ang$mcountrydum == "Bechuanaland"] = 1
ang$mcountrydum[ang$mcountrydum == "Gold Coast"] = 1
ang$mcountrydum[ang$mcountrydum == "Zambia"] = 1
ang$mcountrydum[ang$mcountrydum == "Malta"] = 1
ang$mcountrydum[ang$mcountrydum == "Argentine Republic"] = 1
ang$mcountrydum[ang$mcountrydum == "Tasmania"] = 1
ang$mcountrydum[ang$mcountrydum == "Seychelles"] = 1
ang$mcountrydum[ang$mcountrydum == "Western Australia"] = 1
ang$mcountrydum[ang$mcountrydum == "New South Wales"] = 1
ang$mcountrydum[ang$mcountrydum == "Borneo"] = 1
ang$mcountrydum[ang$mcountrydum == "Dutch East Indies"] = 1
ang$mcountrydum[ang$mcountrydum == "North Wales"] = 1
ang$mcountrydum[ang$mcountrydum == "Brazil"] = 1
ang$mcountrydum[ang$mcountrydum == "Sumatra"] = 1
ang$mcountrydum[ang$mcountrydum == "Russia"] = 1
ang$mcountrydum[ang$mcountrydum == "Argentina"] = 1
ang$mcountrydum[ang$mcountrydum == "South Wales"] = 1
ang$mcountrydum[ang$mcountrydum == "Malawi"] = 1
ang$mcountrydum[ang$mcountrydum == "North Wales, U K"] = 1
ang$mcountrydum[ang$mcountrydum == "Portoguese East Africa"] = 1
ang$mcountrydum[ang$mcountrydum == "Cannel Islands, Great Britain"] = 1
ang$mcountrydum[ang$mcountrydum == "Angola, Portuguese West Afica"] = 1
ang$mcountrydum[ang$mcountrydum == "Victoria, Australia"] = 1
ang$mcountrydum[ang$mcountrydum == "West Coast Africa"] = 1
ang$mcountrydum[ang$mcountrydum == "Isle of Wight, England"] = 1
ang$mcountrydum[ang$mcountrydum == "Channel Islands"] = 1
ang$mcountrydum[ang$mcountrydum == "Arabia"] = 1
ang$mcountrydum[ang$mcountrydum == "West Germany"] = 1
ang$mcountrydum[ang$mcountrydum == "Poland"] = 1
ang$mcountrydum[ang$mcountrydum == "Basutoland Protectorate"] = 1
ang$mcountrydum[ang$mcountrydum == "Kenya Colony, East Africa"] = 1
ang$mcountrydum[ang$mcountrydum == "Trinidad, British West Indies"] = 1
ang$mcountrydum[ang$mcountrydum == "Dublin, Eire"] = 1
ang$mcountrydum[ang$mcountrydum == "North Britain"] = 1
ang$mcountrydum[ang$mcountrydum == "Egypt, North Africa"] = 1
ang$mcountrydum[ang$mcountrydum == "Swaziland"] = 1
ang$mcountrydum[ang$mcountrydum == "North Wales, G. B."] = 1
ang$mcountrydum[ang$mcountrydum == "Bechuanaland Protectorate"] = 1
ang$mcountrydum[ang$mcountrydum == "Borneo, Dutch East Indies"] = 1
ang$mcountrydum[ang$mcountrydum == "Malacca, Straits Settlements"] = 1
ang$mcountrydum[ang$mcountrydum == "Malay States"] = 1
ang$mcountrydum[ang$mcountrydum == "Transkei, S.A."] = 0
ang$mcountrydum[ang$mcountrydum == "Pakistan"] = 1
ang$mcountrydum[ang$mcountrydum == "Isle of Wight, U.K."] = 1
ang$mcountrydum[ang$mcountrydum == "Finland"] = 1
ang$mcountrydum[ang$mcountrydum == "Rumania"] = 1
ang$mcountrydum[ang$mcountrydum == "East Indies"] = 1
ang$mcountrydum[ang$mcountrydum == "Singapore"] = 1
ang$mcountrydum[ang$mcountrydum == "Burma"] = 1
ang$mcountrydum[ang$mcountrydum == "Japan"] = 1
ang$mcountrydum[ang$mcountrydum == "Palastine"] = 1
ang$mcountrydum[ang$mcountrydum == "Isle of Man"] = 1
ang$mcountrydum[ang$mcountrydum == "Estonia"] = 1
ang$mcountrydum[ang$mcountrydum == "Hungary"] = 1
ang$mcountrydum[ang$mcountrydum == "Jersey, Channel Islands"] = 1
ang$mcountrydum[ang$mcountrydum == "Honolulu"] = 1
ang$mcountrydum[ang$mcountrydum == "Malla"] = 1
ang$mcountrydum[ang$mcountrydum == "Spain"] = 1
ang$mcountrydum[ang$mcountrydum == "Iceland"] = 1
ang$mcountrydum[ang$mcountrydum == "South Arica"] = 0
ang$mcountrydum = ifelse(ang$mcountrydum == 0 , 0, 1)

ang$fcountrydum = ang$fcountry

ang$fcountrydum[ang$fcountrydum == "."] = NA
ang$fcountrydum[ang$fcountrydum == "?"] = NA
ang$fcountrydum[ang$fcountrydum == "Holland"] = 1
ang$fcountrydum[ang$fcountrydum == "Scotland"] = 1
ang$fcountrydum[ang$fcountrydum == "South Africa"] = 0
ang$fcountrydum[ang$fcountrydum == "Ireland"] = 1
ang$fcountrydum[ang$fcountrydum == "Amatongaland"] = 0
ang$fcountrydum[ang$fcountrydum == "England"] = 1
ang$fcountrydum[ang$fcountrydum == "Great Britain"] = 1
ang$fcountrydum[ang$fcountrydum == "St. Helena"] = 1
ang$fcountrydum[ang$fcountrydum == "Italy"] = 1
ang$fcountrydum[ang$fcountrydum == "Pondoland"] = 0
ang$fcountrydum[ang$fcountrydum == "Canada"] = 1
ang$fcountrydum[ang$fcountrydum == "Sweden"] = 1
ang$fcountrydum[ang$fcountrydum == "France"] = 1
ang$fcountrydum[ang$fcountrydum == "Northern Rhodesia"] = 1
ang$fcountrydum[ang$fcountrydum == "United Kingdom"] = 1
ang$fcountrydum[ang$fcountrydum == "Southern Rhodesia"] = 1
ang$fcountrydum[ang$fcountrydum == "South West Africa"] = 1
ang$fcountrydum[ang$fcountrydum == "Morroco"] = 1
ang$fcountrydum[ang$fcountrydum == "South Rhodesia"] = 1
ang$fcountrydum[ang$fcountrydum == "Angola"] = 1
ang$fcountrydum[ang$fcountrydum == "Germany"] = 1
ang$fcountrydum[ang$fcountrydum == "Canary Islands"] = 1
ang$fcountrydum[ang$fcountrydum == "Norway"] = 1
ang$fcountrydum[ang$fcountrydum == "Denmark"] = 1
ang$fcountrydum[ang$fcountrydum == "Nyasaland"] = 1
ang$fcountrydum[ang$fcountrydum == "Barotseland"] = 1
ang$fcountrydum[ang$fcountrydum == "Portuguese East Africa "] = 1
ang$fcountrydum[ang$fcountrydum == "Mozambique"] = 1
ang$fcountrydum[ang$fcountrydum == "Madagascar"] = 1
ang$fcountrydum[ang$fcountrydum == "Basutoland"] = 1
ang$fcountrydum[ang$fcountrydum == "Morocco"] = 1
ang$fcountrydum[ang$fcountrydum == "Barotzeland"] = 1
ang$fcountrydum[ang$fcountrydum == "East Africa"] = 1
ang$fcountrydum[ang$fcountrydum == "South Arica C"] = 0
ang$fcountrydum[ang$fcountrydum == "Rhodesia"] = 1
ang$fcountrydum[ang$fcountrydum == "Nigeria"] = 1
ang$fcountrydum[ang$fcountrydum == "U.S.A."] = 1
ang$fcountrydum[ang$fcountrydum == "West Indies"] = 1
ang$fcountrydum[ang$fcountrydum == "Switzerland"] = 1
ang$fcountrydum[ang$fcountrydum == "Wales"] = 1
ang$fcountrydum[ang$fcountrydum == "India"] = 1
ang$fcountrydum[ang$fcountrydum == "Greece"] = 1
ang$fcountrydum[ang$fcountrydum == "Australia"] = 1
ang$fcountrydum[ang$fcountrydum == "Africa"] = 1
ang$fcountrydum[ang$fcountrydum == "Northern Ireland"] = 1
ang$fcountrydum[ang$fcountrydum == "Federated Malay States"] = 1
ang$fcountrydum[ang$fcountrydum == "Zululand"] = 0
ang$fcountrydum[ang$fcountrydum == "Suriname"] = 1
ang$fcountrydum[ang$fcountrydum == "Scotland, U.K."] = 1
ang$fcountrydum[ang$fcountrydum == "Malaya"] = 1
ang$fcountrydum[ang$fcountrydum == "New Zealand"] = 1
ang$fcountrydum[ang$fcountrydum == "Madeira"] = 1
ang$fcountrydum[ang$fcountrydum == "Tanganyika"] = 1
ang$fcountrydum[ang$fcountrydum == "Wales, U.K."] = 1
ang$fcountrydum[ang$fcountrydum == "Nyassaland"] = 1
ang$fcountrydum[ang$fcountrydum == "South Seas"] = 1
ang$fcountrydum[ang$fcountrydum == "St Helena"] = 1
ang$fcountrydum[ang$fcountrydum == "Burmah"] = 1
ang$fcountrydum[ang$fcountrydum == "Kenya, East Africa"] = 1
ang$fcountrydum[ang$fcountrydum == "Egypt"] = 1
ang$fcountrydum[ang$fcountrydum == "Austria"] = 1
ang$fcountrydum[ang$fcountrydum == "Mauritius"] = 1
ang$fcountrydum[ang$fcountrydum == "North Ireland"] = 1
ang$fcountrydum[ang$fcountrydum == "Yugoslavia"] = 1
ang$fcountrydum[ang$fcountrydum == "Belgium"] = 1
ang$fcountrydum[ang$fcountrydum == "China"] = 1
ang$fcountrydum[ang$fcountrydum == "Malaysia"] = 1
ang$fcountrydum[ang$fcountrydum == "Kenya"] = 1
ang$fcountrydum[ang$fcountrydum == "Jamaica"] = 1
ang$fcountrydum[ang$fcountrydum == "India(British Descent)"] = 1
ang$fcountrydum[ang$fcountrydum == "Indonesia"] = 1
ang$fcountrydum[ang$fcountrydum == "Netherlands"] = 1
ang$fcountrydum[ang$fcountrydum == "Portuguese East Africa"] = 1
ang$fcountrydum[ang$fcountrydum == "North Wales, Great Britain"] = 1
ang$fcountrydum[ang$fcountrydum == "Eastern Indonesia"] = 1
ang$fcountrydum[ang$fcountrydum == "Tristan da Cunha"] = 1
ang$fcountrydum[ang$fcountrydum == "St Helena Island"] = 1
ang$fcountrydum[ang$fcountrydum == "United States of America"] = 1
ang$fcountrydum[ang$fcountrydum == "British East Africa"] = 1
ang$fcountrydum[ang$fcountrydum == "Damaraland"] = 1
ang$fcountrydum[ang$fcountrydum == "Wales(Great Britain)"] = 1
ang$fcountrydum[ang$fcountrydum == "South Wales, Great Britain"] = 1
ang$fcountrydum[ang$fcountrydum == "British Isles"] = 1
ang$fcountrydum[ang$fcountrydum == "Belgian Congo"] = 1
ang$fcountrydum[ang$fcountrydum == "West Africa"] = 1
ang$fcountrydum[ang$fcountrydum == "Bechuanaland"] = 1
ang$fcountrydum[ang$fcountrydum == "Gold Coast"] = 1
ang$fcountrydum[ang$fcountrydum == "Zambia"] = 1
ang$fcountrydum[ang$fcountrydum == "Malta"] = 1
ang$fcountrydum[ang$fcountrydum == "Argentine Republic"] = 1
ang$fcountrydum[ang$fcountrydum == "Tasmania"] = 1
ang$fcountrydum[ang$fcountrydum == "Seychelles"] = 1
ang$fcountrydum[ang$fcountrydum == "Western Australia"] = 1
ang$fcountrydum[ang$fcountrydum == "New South Wales"] = 1
ang$fcountrydum[ang$fcountrydum == "Borneo"] = 1
ang$fcountrydum[ang$fcountrydum == "Dutch East Indies"] = 1
ang$fcountrydum[ang$fcountrydum == "North Wales"] = 1
ang$fcountrydum[ang$fcountrydum == "Brazil"] = 1
ang$fcountrydum[ang$fcountrydum == "Sumatra"] = 1
ang$fcountrydum[ang$fcountrydum == "Russia"] = 1
ang$fcountrydum[ang$fcountrydum == "Argentina"] = 1
ang$fcountrydum[ang$fcountrydum == "South Wales"] = 1
ang$fcountrydum[ang$fcountrydum == "Malawi"] = 1
ang$fcountrydum[ang$fcountrydum == "North Wales, U K"] = 1
ang$fcountrydum[ang$fcountrydum == "British West Indies"] = 1
ang$fcountrydum[ang$fcountrydum == "Swaziland"] = 1
ang$fcountrydum[ang$fcountrydum == "south Africa"] = 0
ang$fcountrydum[ang$fcountrydum == "South Africa  "] = 0
ang$fcountrydum[ang$fcountrydum == "On the sea"] = 1
ang$fcountrydum[ang$fcountrydum == "Estonia"] = 1
ang$fcountrydum[ang$fcountrydum == "South Sea Islands"] = 1
ang$fcountrydum[ang$fcountrydum == "Channel Isles"] = 1
ang$fcountrydum[ang$fcountrydum == "Portugal"] = 1
ang$fcountrydum[ang$fcountrydum == "Falkland Islands"] = 1
ang$fcountrydum[ang$fcountrydum == "Isle of Wight"] = 1
ang$fcountrydum[ang$fcountrydum == "United States"] = 1
ang$fcountrydum[ang$fcountrydum == "Wales, United Kingdom"] = 1
ang$fcountrydum[ang$fcountrydum == "Plumstead"] = 0
ang$fcountrydum[ang$fcountrydum == "Island of Seychelles"] = 1
ang$fcountrydum[ang$fcountrydum == "Sputh Africa"] = 0
ang$fcountrydum[ang$fcountrydum == "South America"] = 1
ang$fcountrydum[ang$fcountrydum == "Singapore"] = 1
ang$fcountrydum[ang$fcountrydum == "British Columbia"] = 1
ang$fcountrydum[ang$fcountrydum == "Java, Dutch East Indies"] = 1
ang$fcountrydum[ang$fcountrydum == "Ceylon"] = 1
ang$fcountrydum[ang$fcountrydum == "California"] = 1
ang$fcountrydum[ang$fcountrydum == "Turkey"] = 1
ang$fcountrydum[ang$fcountrydum == "Pakistan"] = 1
ang$fcountrydum[ang$fcountrydum == "South Wales, U.K."] = 1
ang$fcountrydum[ang$fcountrydum == "Argentine"] = 1
ang$fcountrydum[ang$fcountrydum == "South Australia"] = 1
ang$fcountrydum[ang$fcountrydum == "Bechuanaland Protectorate"] = 1
ang$fcountrydum[ang$fcountrydum == "Malay States"] = 1
ang$fcountrydum[ang$fcountrydum == "????"] = NA
ang$fcountrydum[ang$fcountrydum == "California, U.S.A."] = 1
ang$fcountrydum[ang$fcountrydum == "Wales, England"] = 1
ang$fcountrydum[ang$fcountrydum == "Chile, South America"] = 1
ang$fcountrydum[ang$fcountrydum == "Transkei"] = 0
ang$fcountrydum[ang$fcountrydum == "Uganda"] = 1
ang$fcountrydum[ang$fcountrydum == "Burma"] = 1
ang$fcountrydum[ang$fcountrydum == "Trinidad"] = 1
ang$fcountrydum[ang$fcountrydum == "Persia"] = 1
ang$fcountrydum[ang$fcountrydum == "Finland"] = 1
ang$fcountrydum[ang$fcountrydum == "St. Helena, South Atlantic"] = 1
ang$fcountrydum[ang$fcountrydum == "Turkey-in-Asia"] = 1
ang$fcountrydum[ang$fcountrydum == "North Borneo"] = 1
ang$fcountrydum[ang$fcountrydum == "Philippine Islands"] = 1
ang$fcountrydum[ang$fcountrydum == "Kenya, British East Africa"] = 1
ang$fcountrydum[ang$fcountrydum == "Isle of Wight, England"] = 1
ang$fcountrydum = ifelse(ang$fcountrydum == 0 , 0, 1)

ang$international = ifelse(ang$mcountrydum == ang$fcountrydum & ang$mcountrydum == 1, "Both foreign",
                           ifelse(ang$mcountrydum == ang$fcountrydum & ang$mcountrydum == 0, "Local", "Single foreign"))


#############

###Race

############

ang$mrace[ang$mrace == "."] = NA
ang$mrace[ang$mrace == "E"] = 'White'
ang$mrace[ang$mrace == "M"] = 'Coloured'
ang$mrace[ang$mrace == "C"] = 'Coloured'
ang$mrace[ang$mrace == "K"] = 'Black'
ang$mrace[ang$mrace == "Amatonga"] = 'Black'
ang$mrace[ang$mrace == "CC"] = 'Coloured'
ang$mrace[ang$mrace == "Scotch"] = 'White'
ang$mrace[ang$mrace == "British"] = 'White'
ang$mrace[ang$mrace == "English"] = 'White'
ang$mrace[ang$mrace == "St Helena"] = NA
ang$mrace[ang$mrace == "Dutch"] = 'White'
ang$mrace[ang$mrace == "Non-European"] = NA
ang$mrace[ang$mrace == "Non-European (C) "] = 'Coloured'
ang$mrace[ang$mrace == "Native"] = 'Black'
ang$mrace[ang$mrace == "Mixed"] = 'Coloured'
ang$mrace[ang$mrace == "Xhosa"] = 'Black'
ang$mrace[ang$mrace == "Fingo"] = 'Black'
ang$mrace[ang$mrace == "Sutu"] = 'Black'
ang$mrace[ang$mrace == "Tembu"] = 'Black'
ang$mrace[ang$mrace == "Sotho"] = 'Black'
ang$mrace[ang$mrace == "Bantu"] = 'Black'
ang$mrace[ang$mrace == "Native(Pondo)"] = 'Black'
ang$mrace[ang$mrace == "Native(Xhosa)"] = 'Black'
ang$mrace[ang$mrace == "Natvie"] = 'Black'
ang$mrace[ang$mrace == "Native(Fingo)"] = 'Black'
ang$mrace[ang$mrace == "Basuto"] = 'Black'
ang$mrace[ang$mrace == "Indian"] = 'Coloured'
ang$mrace[ang$mrace == "Mauritian"] = NA
ang$mrace[ang$mrace == "Zulu"] = 'Black'
ang$mrace[ang$mrace == "Cape Coloured"] = 'Coloured'
ang$mrace[ang$mrace == "Chinese"] = NA
ang$mrace[ang$mrace == "European"] = 'White'
ang$mrace[ang$mrace == "Aboriginal"] = 'Black'
ang$mrace[ang$mrace == "Indo-European"] = 'White'
ang$mrace[ang$mrace == "Indian "] = 'Coloured'
ang$mrace[ang$mrace == "Mozambique"] = 'Black'
ang$mrace[ang$mrace == "St. Helena"] = NA
ang$mrace[ang$mrace == "African"] = 'Black'
ang$mrace[ang$mrace == "Kruman"] = NA
ang$mrace[ang$mrace == "American Negro"] = NA
ang$mrace[ang$mrace == "Asiatic"] = NA
ang$mrace[ang$mrace == "Africander"] = NA

ang$frace[ang$frace == "."] = NA
ang$frace[ang$frace == "E"] = 'White'
ang$frace[ang$frace == "M"] = 'Coloured'
ang$frace[ang$frace == "C"] = 'Coloured'
ang$frace[ang$frace == "K"] = 'Black'
ang$frace[ang$frace == "Amatonga"] = 'Black'
ang$frace[ang$frace == "CC"] = 'Coloured'
ang$frace[ang$frace == "Scotch"] = 'White'
ang$frace[ang$frace == "British"] = 'White'
ang$frace[ang$frace == "English"] = 'White'
ang$frace[ang$frace == "St Helena"] = NA
ang$frace[ang$frace == "Dutch"] = 'White'
ang$frace[ang$frace == "Non-European"] = NA
ang$frace[ang$frace == "Non-European (C) "] = 'Coloured'
ang$frace[ang$frace == "Native"] = 'Black'
ang$frace[ang$frace == "Mixed"] = 'Coloured'
ang$frace[ang$frace == "Xhosa"] = 'Black'
ang$frace[ang$frace == "Fingo"] = 'Black'
ang$frace[ang$frace == "Sutu"] = 'Black'
ang$frace[ang$frace == "Tembu"] = 'Black'
ang$frace[ang$frace == "Sotho"] = 'Black'
ang$frace[ang$frace == "Bantu"] = 'Black'
ang$frace[ang$frace == "Native(Pondo)"] = 'Black'
ang$frace[ang$frace == "Native(Xhosa)"] = 'Black'
ang$frace[ang$frace == "Natvie"] = 'Black'
ang$frace[ang$frace == "Native(Fingo)"] = 'Black'
ang$frace[ang$frace == "Basuto"] = 'Black'
ang$frace[ang$frace == "Indian"] = 'Coloured'
ang$frace[ang$frace == "Mauritian"] = NA
ang$frace[ang$frace == "Zulu"] = 'Black'
ang$frace[ang$frace == "Cape Coloured"] = 'Coloured'
ang$frace[ang$frace == "Chinese"] = NA
ang$frace[ang$frace == "European"] = 'White'
ang$frace[ang$frace == "Aboriginal"] = 'Black'
ang$frace[ang$frace == "Indo-European"] = 'White'
ang$frace[ang$frace == "Indian "] = 'Coloured'
ang$frace[ang$frace == "Mozambique"] = 'Black'
ang$frace[ang$frace == "St. Helena"] = NA
ang$frace[ang$frace == "African"] = 'Black'
ang$frace[ang$frace == "Kruman"] = NA
ang$frace[ang$frace == "American Negro"] = NA
ang$frace[ang$frace == "Asiatic"] = NA
ang$frace[ang$frace == "v"] = 'Coloured'
ang$frace[ang$frace == "c"] = 'Coloured'
ang$frace[ang$frace == "Widow"] = NA
ang$frace[ang$frace == "Cape Malay"] = 'Coloured'
ang$frace[ang$frace == "Native "] = 'Black'
ang$frace[ang$frace == "Africander"] = NA
ang$frace[ang$frace == "Slightly Coloured"] = 'Coloured'

############

##Interracial type

ang$type = ifelse(ang$mrace == 'White' & ang$frace == 'White', 'ww',
                  ifelse(ang$mrace == 'White' & ang$frace == 'Coloured', 'wc',
                            ifelse(ang$mrace == 'Coloured' & ang$frace == 'White', 'cw',
                                   ifelse(ang$mrace == 'Coloured' & ang$frace == 'Coloured', 'cc',
                                      ifelse(ang$mrace == 'Black' & ang$frace == 'Coloured', 'bc',
                                             ifelse(ang$mrace == 'Black' & ang$frace == 'Black', 'bb',
                                          ifelse(ang$mrace == 'Coloured' & ang$frace == 'Black', 'cb',
                                                 ifelse(ang$mrace == 'White' & ang$frace == 'Black', 'wb',
                                                 ifelse(ang$mrace == 'Black' & ang$frace == 'White', 'bw', NA)))))))))

########

###Condition

ang$fcondition[ang$fcondition == "Divorcee"] = 'Divorced'
ang$fcondition[ang$fcondition == "Civil marriage by Magistrate"] = NA
ang$fcondition[ang$fcondition == "."] = NA
ang$fcondition[ang$fcondition == "Married de facto"] = NA

ang$mcondition[ang$mcondition == "."] = NA
ang$mcondition[ang$mcondition == "Civil marriage by Magistrate"] = NA
ang$mcondition[ang$mcondition == "Married de facto"] = NA
ang$mcondition[ang$mcondition == "Divorcee"] = 'Divorced'
ang$mcondition[ang$mcondition == "Carpenter"] = NA
ang$mcondition[ang$mcondition == "Divorcee/Widower"] = 'Divorced'

ang$mcon = ang$mcondition
ang = data.table(ang)
ang$mcon[ang$mcondition == "Bachelor"] = 0
ang$mcon[ang$mcondition == "Widower"] = 1
ang$mcon[ang$mcondition == "Divorced"] = 2

ang$fcon = ang$fcondition
ang = data.table(ang)
ang$fcon[ang$fcondition == "Spinster"] = 0
ang$fcon[ang$fcondition == "Widow"] = 1
ang$fcon[ang$fcondition == "Divorced"] = 2

###Literacy

ang$mlit = ifelse(ang$msign == "Yes", 1, 0)
ang$mwlit = ifelse(ang$mwsign == "Yes", 1, 0)
ang$flit = ifelse(ang$fsign == "Yes", 1, 0)
ang$fwlit = ifelse(ang$fwsign == "Yes", 1, 0)
ang$lit = ang$mlit + ang$mwlit + ang$flit + ang$fwlit

ang$dlit = ang$mlit - ang$flit

###Parish
#################

ang$parishdum[ang$pid == 445] = 'Athlone1'
ang$parishdum[ang$pid == 447] = 'Bellville1'
ang$parishdum[ang$pid == 449] = 'Bellville2'
ang$parishdum[ang$pid == 452] = 'CampsBay1' #hierdie is 'n foutinskrywing
ang$parishdum[ang$pid == 462] = 'CampsBay1'
ang$parishdum[ang$pid == 463] = 'Central1'
ang$parishdum[ang$pid == 464] = 'Central2'
ang$parishdum[ang$pid == 470] = 'Claremont1'
ang$parishdum[ang$pid == 472] = 'Claremont2'
ang$parishdum[ang$pid == 474] = 'Claremont3'
ang$parishdum[ang$pid == 475] = 'Constantia1'
ang$parishdum[ang$pid == 480] = 'Goodwood1'
ang$parishdum[ang$pid == 481] = 'GordonsBays1'
ang$parishdum[ang$pid == 482] = 'GreenPoint1'
ang$parishdum[ang$pid == 497] = 'KalkBay1'
ang$parishdum[ang$pid == 501] = 'Kenilworth1'
ang$parishdum[ang$pid == 503] = 'Kensington1'
ang$parishdum[ang$pid == 505] = 'Langa1'
ang$parishdum[ang$pid == 506] = 'Landsdowne1'
ang$parishdum[ang$pid == 507] = 'Landsdowne2'
ang$parishdum[ang$pid == 508] = 'Maitland1'
ang$parishdum[ang$pid == 509] = 'Maitland2'
ang$parishdum[ang$pid == 518] = 'Central3'
ang$parishdum[ang$pid == 519] = 'Mowbray1'
ang$parishdum[ang$pid == 520] = 'Muizeberg1'
ang$parishdum[ang$pid == 527] = 'Mowbray1'
ang$parishdum[ang$pid == 529] = 'Newlands1'
ang$parishdum[ang$pid == 536] = 'Papendorp1'
ang$parishdum[ang$pid == 537] = 'Parow1'
ang$parishdum[ang$pid == 539] = 'Pinelands1'
ang$parishdum[ang$pid == 540] = 'Plumstead1'
ang$parishdum[ang$pid == 543] = 'Retreat1'
ang$parishdum[ang$pid == 547] = 'Rondebosch1'
ang$parishdum[ang$pid == 549] = 'Rondebosch2'
ang$parishdum[ang$pid == 550] = 'Rondebosch3'
ang$parishdum[ang$pid == 551] = 'Rondebosch4'
ang$parishdum[ang$pid == 552] = 'Roodebloem1'
ang$parishdum[ang$pid == 554] = 'SeaPoint1'
ang$parishdum[ang$pid == 567] = 'Central4'
ang$parishdum[ang$pid == 570] = 'Wynberg1'
#################

####Rank

###########

#ang2 = merge(ang, moccu, by=c('mrank'), allow.cartesian = TRUE)


ang$mrank <- gsub("'", '', ang$mrank)
ang$mrank <- gsub('"', '', ang$mrank)
ang$mrank <- gsub('/', '', ang$mrank)

ang$moccu = ang$mrank
ang$moccu[ang$moccu == " Minister of Religion"] = 1
ang$moccu[ang$moccu == " S.A.R."] = NA
ang$moccu[ang$moccu == "."] = NA
ang$moccu[ang$moccu == "?"] = NA
ang$moccu[ang$moccu == "??"] = NA
ang$moccu[ang$moccu == "???"] = NA
ang$moccu[ang$moccu == "????"] = NA
ang$moccu[ang$moccu == "2Lt. S.A.A."] = 5
ang$moccu[ang$moccu == "2nd Blockman"] = 7
ang$moccu[ang$moccu == "2nd Lieut. S.A. Air Force"] = 5
ang$moccu[ang$moccu == "2nd Lieut. S.A. Army"] = 5
ang$moccu[ang$moccu == "2nd Lieut. S.A. Native Labour Contingent"] = 5
ang$moccu[ang$moccu == "2nd Lieut. S.A.E.C."] = 5
ang$moccu[ang$moccu == "2nd Lt. Northern Rhodesia Regiment"] = 5
ang$moccu[ang$moccu == "2nd Officer Merchant Navy"] = 5
ang$moccu[ang$moccu == "2nd. Lieutenant R.A.F."] = 5
ang$moccu[ang$moccu == "3rd Officer Walmer Castle"] = 5
ang$moccu[ang$moccu == "4th Officer Merchant Marine"] = 5
ang$moccu[ang$moccu == "4th Regiment"] = 5
ang$moccu[ang$moccu == "91st Regiment"] = 5
ang$moccu[ang$moccu == "A.A.T.C. S.A. Air Force"] = 0
ang$moccu[ang$moccu == "A.B. Royal Navy"] = 5
ang$moccu[ang$moccu == "A.B. S.A.N.F."] = 5
ang$moccu[ang$moccu == "A.B. Seaman"] = 5
ang$moccu[ang$moccu == "A.C. Clerk"] = 3
ang$moccu[ang$moccu == "A.R.M. Volksrust, Transvaal"] = NA
ang$moccu[ang$moccu == "AB S.A. Naval Forces"] = 5
ang$moccu[ang$moccu == "AC R.A.F."] = 5
ang$moccu[ang$moccu == "AC R.A.F. On Active Service"] = 5
ang$moccu[ang$moccu == "AB Seaman"] = 5
ang$moccu[ang$moccu == "Abattoir Employee"] = 9
ang$moccu[ang$moccu == "Abattoir labourer"] = 9
ang$moccu[ang$moccu == "Abattoir Worker"] = 9
ang$moccu[ang$moccu == "Abattoirs Employee"] = 9
ang$moccu[ang$moccu == "Able Seaman"] = 5
ang$moccu[ang$moccu == "Able Seaman Gunner"] = 5
ang$moccu[ang$moccu == "Able Seaman R.N."] = 5
ang$moccu[ang$moccu == "Able Seaman Royal Navy"] = 5
ang$moccu[ang$moccu == "Able Seaman S.A. Navy"] = 5
ang$moccu[ang$moccu == "Able Seaman S.A.N.F."] = 5
ang$moccu[ang$moccu == "Able Seaman, Royal Navy"] = 5
ang$moccu[ang$moccu == "Able Seaman: Class 2, S.A.D.F."] = 5
ang$moccu[ang$moccu == "Accountancy Clerk"] = 3
ang$moccu[ang$moccu == "Accountant"] = 1
ang$moccu[ang$moccu == "Accountant "] = 1
ang$moccu[ang$moccu == "Accountant (On Militray Service)"] = 1
ang$moccu[ang$moccu == "Accountant (Sergeant U.D.F.)"] = 1
ang$moccu[ang$moccu == "Accountant + Auditor"] = 1
ang$moccu[ang$moccu == "Accountant A.B.C. Bank"] = 1
ang$moccu[ang$moccu == "Accountant C.G.H. Bank"] = 1
ang$moccu[ang$moccu == "Accountant Clerk Naval Dockyard"] = 3
ang$moccu[ang$moccu == "Accountant Colonial Office"] = 1
ang$moccu[ang$moccu == "Accountant S.A. Railways"] = 1
ang$moccu[ang$moccu == "Accountant S.A.R."] = 1
ang$moccu[ang$moccu == "Accountant(C.A.S.A.)"] = 1
ang$moccu[ang$moccu == "Accountants Clerk"] = 3
ang$moccu[ang$moccu == "Accounting Clerk"] = 3
ang$moccu[ang$moccu == "Accounting Clerk S.A.A.F."] = 3
ang$moccu[ang$moccu == "Accounts Clerk"] = 3
ang$moccu[ang$moccu == "Accounts clerk"] = 3
ang$moccu[ang$moccu == "Acting Assistant Master of the High Court of South. Rhodesia"] = NA
ang$moccu[ang$moccu == "Acting Fireman S.A.R."] = 9
ang$moccu[ang$moccu == "Acting Porter S.A.R."] = 9
ang$moccu[ang$moccu == "Acting Postman"] = 3
ang$moccu[ang$moccu == "Acting-Bombardier "] = 5
ang$moccu[ang$moccu == "Acting-chef"] = 5
ang$moccu[ang$moccu == "Active Service R.N."] = 5
ang$moccu[ang$moccu == "Active Service S.A.N.F."] = 5
ang$moccu[ang$moccu == "Actor"] = 1
ang$moccu[ang$moccu == "Actor Manager, African Theatres"] = 2
ang$moccu[ang$moccu == "Actuary"] = 0
ang$moccu[ang$moccu == "Actuary (on Active Service)"] = 0
ang$moccu[ang$moccu == "Addressograph Operator"] = 3
ang$moccu[ang$moccu == "Addressographer"] = 3
ang$moccu[ang$moccu == "Administrative assistant"] = 3
ang$moccu[ang$moccu == "Administrative Assistant"] = 3
ang$moccu[ang$moccu == "Administrative Officer U.C.T."] = 3
ang$moccu[ang$moccu == "Admiralty Draughtsman"] = 0
ang$moccu[ang$moccu == "Admiralty Messenger"] = 3
ang$moccu[ang$moccu == "Adult Messenger S.A.R."] = 3
ang$moccu[ang$moccu == "Advertising"] = 4
ang$moccu[ang$moccu == "Advertising Accounts Executive"] = 1
ang$moccu[ang$moccu == "Advertising Agent"] = 4
ang$moccu[ang$moccu == "Advertising Canvasser"] = 4
ang$moccu[ang$moccu == "Advertising Consultant"] = 4
ang$moccu[ang$moccu == "Advertising Contractor"] = 4
ang$moccu[ang$moccu == "Advertising Designer"] = 4
ang$moccu[ang$moccu == "Advertising Executive"] = 4
ang$moccu[ang$moccu == "Advertising Manager"] = 2
ang$moccu[ang$moccu == "Advertising Representative"] = 4
ang$moccu[ang$moccu == "Advertising space buyer"] = 4
ang$moccu[ang$moccu == "Advocate"] = 1
ang$moccu[ang$moccu == "Advocate Attorney Geneal"] = 1
ang$moccu[ang$moccu == "Aerial Manager"] = 2
ang$moccu[ang$moccu == "Aerodrome Field Maintainer"] = 9
ang$moccu[ang$moccu == "Aero-Engineer"] = 0
ang$moccu[ang$moccu == "African Clothing"] = 7
ang$moccu[ang$moccu == "Agent"] = 4
ang$moccu[ang$moccu == "Agent for Insurance"] = 4
ang$moccu[ang$moccu == "Agent S.A. Brickfields"] = 9
ang$moccu[ang$moccu == "Agent: Nat. Industrial Council of Building Industries"] = 9
ang$moccu[ang$moccu == "Agent: National Industrial Council of Building Industries"] = 9
ang$moccu[ang$moccu == "Agricultural Assistant"] = 6
ang$moccu[ang$moccu == "Agricultural Demonstrator"] = 1
ang$moccu[ang$moccu == "Agricultural Field Officer"] = 6
ang$moccu[ang$moccu == "Agricultural Instructor, Agricultural School"] = 1
ang$moccu[ang$moccu == "Agricultural Produce Agent"] = 6
ang$moccu[ang$moccu == "Agriculturalist"] = 6
ang$moccu[ang$moccu == "Agriculturist"] = 6
ang$moccu[ang$moccu == "Aide de Camp to Governor General"] = 3
ang$moccu[ang$moccu == "Air Artificer R.N."] = 8
ang$moccu[ang$moccu == "Air Fitter R.N."] = 8
ang$moccu[ang$moccu == "Air Force"] = 5
ang$moccu[ang$moccu == "Air Force Mechanic"] = 8
ang$moccu[ang$moccu == "Air Force Officer"] = 0
ang$moccu[ang$moccu == "Air Mechanic"] = 8
ang$moccu[ang$moccu == "Air Mechanic R.A.F."] = 8
ang$moccu[ang$moccu == "Air Mechanic R.N."] = 8
ang$moccu[ang$moccu == "Air Mechanic R.N.A.S."] = 8
ang$moccu[ang$moccu == "Air Mechanic S.A. Air Force"] = 8
ang$moccu[ang$moccu == "Air Mechanic S.A.A.F."] = 8
ang$moccu[ang$moccu == "Air Sergeant S.A.A.F."] = 5
ang$moccu[ang$moccu == "Air-craft Engineer"] = 0
ang$moccu[ang$moccu == "Aircraft Mechanic"] = 8
ang$moccu[ang$moccu == "Aircraftsman R.A.F."] = 5
ang$moccu[ang$moccu == "Aircraftsman Royal Air Force"] = 5
ang$moccu[ang$moccu == "Air-fitter R.N."] = 8
ang$moccu[ang$moccu == "Airframe Mechanic"] = 8
ang$moccu[ang$moccu == "Airman"] = 5
ang$moccu[ang$moccu == "Airman S.A.A.F."] = 5
ang$moccu[ang$moccu == "Amalgamator"] = NA
ang$moccu[ang$moccu == "Amalgamator at Gold Mines"] = NA
ang$moccu[ang$moccu == "Anaesthetic Representative"] = 0
ang$moccu[ang$moccu == "Analyst"] = 0
ang$moccu[ang$moccu == "Analyst (Department of Agriculture)"] = 0
ang$moccu[ang$moccu == "Analyst, Lieut. Armoured Car Regiment"] = 0
ang$moccu[ang$moccu == "Analytical Chemist"] = 0
ang$moccu[ang$moccu == "Anchorman"] = 9
ang$moccu[ang$moccu == "Anthropologist"] = 0
ang$moccu[ang$moccu == "Anti-Aircraft Gunner"] = 5
ang$moccu[ang$moccu == "Anti-Malarial Officer"] = 0
ang$moccu[ang$moccu == "Any Occupation"] = 5
ang$moccu[ang$moccu == "Appliance Mechanic"] = 8
ang$moccu[ang$moccu == "Applied Chemist"] = 0
ang$moccu[ang$moccu == "Apprentice"] = 9
ang$moccu[ang$moccu == "Apprentice Assistant Printer"] = NA
ang$moccu[ang$moccu == "Apprentice Blacksmith"] = 8
ang$moccu[ang$moccu == "Apprentice Blockman"] = 7
ang$moccu[ang$moccu == "Apprentice Boiler-maker"] = 8
ang$moccu[ang$moccu == "Apprentice Boiler-maker"] = 8
ang$moccu[ang$moccu == "Apprentice Bricklayer"] = 9
ang$moccu[ang$moccu == "Apprentice Builder"] = 9
ang$moccu[ang$moccu == "Apprentice Cabinet Maker"] = 8
ang$moccu[ang$moccu == "Apprentice Cabinet Making"] = 8
ang$moccu[ang$moccu == "Apprentice Cabinet-maker"] = 8
ang$moccu[ang$moccu == "Apprentice Carpenter"] = 8
ang$moccu[ang$moccu == "Apprentice Cinema Operator"] = 5
ang$moccu[ang$moccu == "Apprentice Coach Builder S.A.R."] = 8
ang$moccu[ang$moccu == "Apprentice Diamond Setter"] = 8
ang$moccu[ang$moccu == "Apprentice Electrical Fitter"] = 8
ang$moccu[ang$moccu == "Apprentice Electrician"] = 8
ang$moccu[ang$moccu == "Apprentice Engineering Works"] = 0
ang$moccu[ang$moccu == "Apprentice Engraver"] = 8
ang$moccu[ang$moccu == "Apprentice Fitter"] = 8
ang$moccu[ang$moccu == "Apprentice Fitter + Turner"] = 8
ang$moccu[ang$moccu == "Apprentice Fitter S.A.R."] = 8
ang$moccu[ang$moccu == "Apprentice Furniture Polisher"] = 8
ang$moccu[ang$moccu == "Apprentice Hairdresser"] = 5
ang$moccu[ang$moccu == "Apprentice Machinist"] = 8
ang$moccu[ang$moccu == "Apprentice Mechanic"] = 8
ang$moccu[ang$moccu == "Apprentice Millwright"] = 8
ang$moccu[ang$moccu == "Apprentice Motor Mechanic"] = 8
ang$moccu[ang$moccu == "Apprentice Painter"] = 9
ang$moccu[ang$moccu == "Apprentice Panelbeater"] = 8
ang$moccu[ang$moccu == "Apprentice Plumber"] = 8
ang$moccu[ang$moccu == "Apprentice Rigger"] = 9
ang$moccu[ang$moccu == "Apprentice S.A.R."] = 9
ang$moccu[ang$moccu == "Apprentice Sheet Metal Worker"] = 8
ang$moccu[ang$moccu == "Apprentice Signal Fitter"] = 8
ang$moccu[ang$moccu == "Apprentice to Sign-writer"] = 3
ang$moccu[ang$moccu == "Apprentice Welder"] = 8
ang$moccu[ang$moccu == "Apprenticed Carpenter"] = 8
ang$moccu[ang$moccu == "Apprenticed Electrician"] = 8
ang$moccu[ang$moccu == "Apprentice-Printer"] = 9
ang$moccu[ang$moccu == "Aquarium Curator"] = 1
ang$moccu[ang$moccu == "Archaeologist"] = 1
ang$moccu[ang$moccu == "Archeologist"] = 1
ang$moccu[ang$moccu == "Architect"] = 0
ang$moccu[ang$moccu == "Architect "] = 0
ang$moccu[ang$moccu == "Architect + Surveyor"] = 0
ang$moccu[ang$moccu == "Architect and Builder"] = 0
ang$moccu[ang$moccu == "Architects Assistant"] = 0
ang$moccu[ang$moccu == "Architectural Assistant"] = 0
ang$moccu[ang$moccu == "Architectural assistant"] = 0
ang$moccu[ang$moccu == "Architectural Draughtsman"] = 0
ang$moccu[ang$moccu == "Architectural Student"] = 0
ang$moccu[ang$moccu == "Area Manager"] = 2
ang$moccu[ang$moccu == "Area Manager Florist"] = 2
ang$moccu[ang$moccu == "Armanent Fitter"] = 8
ang$moccu[ang$moccu == "Armature winder"] = 7
ang$moccu[ang$moccu == "Armature-winder"] = 7
ang$moccu[ang$moccu == "Armed Forces"] = 5
ang$moccu[ang$moccu == "Army"] = 5
ang$moccu[ang$moccu == "Army Hospital Corps"] = 5
ang$moccu[ang$moccu == "Army Officer"] = 5
ang$moccu[ang$moccu == "Army Pensioner"] = 5
ang$moccu[ang$moccu == "Army Serjeant"] = 5
ang$moccu[ang$moccu == "Army Surgeon"] = 0
ang$moccu[ang$moccu == "Art Metal Worker"] = 8
ang$moccu[ang$moccu == "Article Attorney"] = 1
ang$moccu[ang$moccu == "Articled Clerk"] = 3
ang$moccu[ang$moccu == "Articled Clerk Solicitor"] = 1
ang$moccu[ang$moccu == "Articled Clerk, Law"] = 3
ang$moccu[ang$moccu == "Artificial Flower Maker"] = 7
ang$moccu[ang$moccu == "Artillery Man"] = 5
ang$moccu[ang$moccu == "Artillery Officer"] = 5
ang$moccu[ang$moccu == "Artisan"] = 9
ang$moccu[ang$moccu == "Artisan S.A.R."] = 9
ang$moccu[ang$moccu == "Artisans Mate"] = 9
ang$moccu[ang$moccu == "Artist"] = 1
ang$moccu[ang$moccu == "Arts and Crafts"] = 1
ang$moccu[ang$moccu == "Asbestos-fixer"] = 9
ang$moccu[ang$moccu == "Asphalter"] = 9
ang$moccu[ang$moccu == "Assayer"] = 0
ang$moccu[ang$moccu == "Assembler"] = 8
ang$moccu[ang$moccu == "Assembler Atkinsons Motors"] = 8
ang$moccu[ang$moccu == "Assembler Motor Industry"] = 8
ang$moccu[ang$moccu == "Assembler of Motor Cars"] = 8
ang$moccu[ang$moccu == "Assembler Wine Co."] = 8
ang$moccu[ang$moccu == "Assistant Accountant"] = 1
ang$moccu[ang$moccu == "Assistant Architect, Public Works Deptà"] = 0
ang$moccu[ang$moccu == "Assistant Astronomer"] = 0
ang$moccu[ang$moccu == "Assistant at Butchery"] = 7
ang$moccu[ang$moccu == "Assistant at Sugar Factory"] = 7
ang$moccu[ang$moccu == "Assistant Baker"] = 7
ang$moccu[ang$moccu == "Assistant Bishop of Bloemfontein"] = 1
ang$moccu[ang$moccu == "Assistant Boiler-maker, S.A.R."] = 8
ang$moccu[ang$moccu == "Assistant Brewer (On Active Service)"] = 7
ang$moccu[ang$moccu == "Assistant Butcher"] = 7
ang$moccu[ang$moccu == "Assistant Cashier, Administration of Estates"] = 4
ang$moccu[ang$moccu == "Assistant Chemist"] = 0
ang$moccu[ang$moccu == "Assistant Clerk, Legislative Council "] = 3
ang$moccu[ang$moccu == "Assistant Confectioner"] = 7
ang$moccu[ang$moccu == "Assistant Cook"] = 5
ang$moccu[ang$moccu == "Assistant Credit Manager"] = 2
ang$moccu[ang$moccu == "Assistant Creditor Manager"] = 2
ang$moccu[ang$moccu == "Assistant Curator"] = 1
ang$moccu[ang$moccu == "Assistant cutter"] = 9
ang$moccu[ang$moccu == "Assistant Despatch Clerk"] = 3
ang$moccu[ang$moccu == "Assistant Diver"] = 9
ang$moccu[ang$moccu == "Assistant Draughtsman"] = 0
ang$moccu[ang$moccu == "Assistant Driver"] = 9
ang$moccu[ang$moccu == "Assistant Duco sprayer"] = 9
ang$moccu[ang$moccu == "Assistant Electrician"] = 8
ang$moccu[ang$moccu == "Assistant Engineer S.A.R.+H."] = 0
ang$moccu[ang$moccu == "Assistant Factory Manager"] = 2
ang$moccu[ang$moccu == "Assistant Fireman"] = 9
ang$moccu[ang$moccu == "Assistant Fitter"] = 8
ang$moccu[ang$moccu == "Assistant Foreman"] = 2
ang$moccu[ang$moccu == "Assistant Foreman Fitter"] = 8
ang$moccu[ang$moccu == "Assistant Foreman in Factory"] = 2
ang$moccu[ang$moccu == "Assistant Foreman Motor Garage"] = 2
ang$moccu[ang$moccu == "Assistant foreman National Trawling"] = 2
ang$moccu[ang$moccu == "Assistant Foreman S.A.R."] = 2
ang$moccu[ang$moccu == "Assistant Government Laboratory"] = 0
ang$moccu[ang$moccu == "Assistant Grocer"] = 4
ang$moccu[ang$moccu == "Assistant Groundsman"] = 6
ang$moccu[ang$moccu == "Assistant Imperial Secretary"] = 2
ang$moccu[ang$moccu == "Assistant in Bookstall"] = 4
ang$moccu[ang$moccu == "Assistant in Hotel"] = 5
ang$moccu[ang$moccu == "Assistant in Telephone Department"] = 3
ang$moccu[ang$moccu == "Assistant Joinery Manager"] = 2
ang$moccu[ang$moccu == "Assistant Laboratory Manager"] = 2
ang$moccu[ang$moccu == "Assistant Librarian"] = 1
ang$moccu[ang$moccu == "Assistant Lighthouse Keeper S.A.R.+H."] = 9
ang$moccu[ang$moccu == "Assistant Machinist"] = 8
ang$moccu[ang$moccu == "Assistant Magistrate"] = 2
ang$moccu[ang$moccu == "Assistant Mains Foreman (Electricity)"] = 2
ang$moccu[ang$moccu == "Assistant Manager"] = 2
ang$moccu[ang$moccu == "Assistant Manager Motor Business"] = 2
ang$moccu[ang$moccu == "Assistant Manager S.A. Breweries"] = 2
ang$moccu[ang$moccu == "Assistant Manager(Mercantile)"] = 2
ang$moccu[ang$moccu == "Assistant Marketing Manager"] = 2
ang$moccu[ang$moccu == "Assistant Mechanic"] = 8
ang$moccu[ang$moccu == "Assistant Mechanical Engineer S.A.R."] = 0
ang$moccu[ang$moccu == "Assistant Mine Secretary"] = 3
ang$moccu[ang$moccu == "Assistant Packer"] = 9
ang$moccu[ang$moccu == "Assistant Paymaster Royal Navy"] = 3
ang$moccu[ang$moccu == "Assistant Polony Maker"] = 7
ang$moccu[ang$moccu == "Assistant Printer"] = 9
ang$moccu[ang$moccu == "Assistant Purser"] = 3
ang$moccu[ang$moccu == "Assistant Purser (Merchant Navy)"] = 3
ang$moccu[ang$moccu == "Assistant Quantity Surveyor"] = 0
ang$moccu[ang$moccu == "Assistant Representative Vacuum Oil Co."] = 4
ang$moccu[ang$moccu == "Assistant Resident Commissioner"] = 4
ang$moccu[ang$moccu == "Assistant Rigger"] = 9
ang$moccu[ang$moccu == "Assistant Rivetter"] = 8
ang$moccu[ang$moccu == "Assistant Sales Manager"] = 2
ang$moccu[ang$moccu == "Assistant Sampler"] = 7
ang$moccu[ang$moccu == "Assistant Schoolmaster"] = 1
ang$moccu[ang$moccu == "Assistant Secretary"] = 3
ang$moccu[ang$moccu == "Assistant Shop Manager"] = 2
ang$moccu[ang$moccu == "Assistant Slaughterman"] = 7
ang$moccu[ang$moccu == "Assistant Station Master"] = 2
ang$moccu[ang$moccu == "Assistant Storekeeper"] = 4
ang$moccu[ang$moccu == "Assistant Storeman"] = 4
ang$moccu[ang$moccu == "Assistant to Commercial Traveller"] = 4
ang$moccu[ang$moccu == "Assistant to Marketing Manager"] = 2
ang$moccu[ang$moccu == "Assistant to Quantity Surveyor"] = 0
ang$moccu[ang$moccu == "Assistant Town Treasurer"] = 1
ang$moccu[ang$moccu == "Assistant Warehouse Manager"] = 2
ang$moccu[ang$moccu == "Assistant Works Manager"] = 2
ang$moccu[ang$moccu == "Assistant Y.M.C.A."] = 1
ang$moccu[ang$moccu == "Assistant, Cleaning Dept. City Council"] = 5
ang$moccu[ang$moccu == "Assistant-Accountant"] = 1
ang$moccu[ang$moccu == "Assistant-carpenter"] = 8
ang$moccu[ang$moccu == "Assistant-Chemist"] = 0
ang$moccu[ang$moccu == "Assistant-Deputy Accountant"] = 1
ang$moccu[ang$moccu == "Assistant-mechanic"] = 8
ang$moccu[ang$moccu == "Asst. Operator African Theatre"] = 8
ang$moccu[ang$moccu == "Asst. Paymaster R.N."] = 3
ang$moccu[ang$moccu == "Asst. to Engineer"] = 0
ang$moccu[ang$moccu == "Assurance Agent"] = 4
ang$moccu[ang$moccu == "Assurance Assessor"] = 4
ang$moccu[ang$moccu == "Assurance Clerk"] = 3
ang$moccu[ang$moccu == "Assurance Company Representative"] = 4
ang$moccu[ang$moccu == "Astronomer"] = 0
ang$moccu[ang$moccu == "Asylum Attendant"] = 5
ang$moccu[ang$moccu == "Attendant"] = 5
ang$moccu[ang$moccu == "Attendant Bottle Store"] = 4
ang$moccu[ang$moccu == "Attendant Deeds Office"] = 3
ang$moccu[ang$moccu == "Attendant Military Hospital Wynberg"] = 5
ang$moccu[ang$moccu == "Attendant O.S.H."] = 5
ang$moccu[ang$moccu == "Attendant Robben Island"] = 5
ang$moccu[ang$moccu == "Attendant S.A.R."] = 5
ang$moccu[ang$moccu == "Attorney"] = 1
ang$moccu[ang$moccu == "Attorney + Notary Public"] = 1
ang$moccu[ang$moccu == "Attorney at Law"] = 1
ang$moccu[ang$moccu == "Attorney-at-Law"] = 1
ang$moccu[ang$moccu == "Attorney-at-Law, Captain Union Defence Force"] = 1
ang$moccu[ang$moccu == "Attorneys Clerk"] = 3
ang$moccu[ang$moccu == "Auctioneer"] = 4
ang$moccu[ang$moccu == "Audit clerk"] = 3
ang$moccu[ang$moccu == "Audit Clerk"] = 3
ang$moccu[ang$moccu == "Audit Inspector"] = 2
ang$moccu[ang$moccu == "Audit Office"] = 3
ang$moccu[ang$moccu == "Audit-Clerk"] = 3
ang$moccu[ang$moccu == "Auditor"] = 1
ang$moccu[ang$moccu == "Auditor General"] = 1
ang$moccu[ang$moccu == "Auto Electrician"] = 8
ang$moccu[ang$moccu == "Auto-Carrier Driver"] = 9
ang$moccu[ang$moccu == "Auto-Electrician"] = 8
ang$moccu[ang$moccu == "Auto-electrician"] = 8
ang$moccu[ang$moccu == "Automobile Engineer"] = 0
ang$moccu[ang$moccu == "Automotive Machinist + Fitter"] = 8
ang$moccu[ang$moccu == "Automotive machinist and fitter"] = 8
ang$moccu[ang$moccu == "B R A"] = NA
ang$moccu[ang$moccu == "B.S.A. Police"] = NA
ang$moccu[ang$moccu == "Bacon Curer"] = 7
ang$moccu[ang$moccu == "Baggage Porter"] = 9
ang$moccu[ang$moccu == "Bag-maker"] = 7
ang$moccu[ang$moccu == "Baker"] = 7
ang$moccu[ang$moccu == "Baker "] = 7
ang$moccu[ang$moccu == "Baker (On Active Service)"] = 7
ang$moccu[ang$moccu == "Baker (Petty Officer)"] = 7
ang$moccu[ang$moccu == "Bakers Apprentice"] = 7
ang$moccu[ang$moccu == "Bakers assistant"] = 7
ang$moccu[ang$moccu == "Bakers Assistant"] = 7
ang$moccu[ang$moccu == "Bakers Driver"] = 9
ang$moccu[ang$moccu == "Bakers Messenger"] = 3
ang$moccu[ang$moccu == "Bakery Employee"] = 7
ang$moccu[ang$moccu == "Bakery Supervisor"] = 2
ang$moccu[ang$moccu == "Ballaster"] = 8
ang$moccu[ang$moccu == "Ballastman"] = 8
ang$moccu[ang$moccu == "Banding"] = 1
ang$moccu[ang$moccu == "Bandsman"] = 1
ang$moccu[ang$moccu == "Bandsman 99th"] = 1
ang$moccu[ang$moccu == "Bandsman Kings Royal Rifles"] = 1
ang$moccu[ang$moccu == "Bank Accountant"] = 1
ang$moccu[ang$moccu == "Bank cleaner"] = 5
ang$moccu[ang$moccu == "Bank clerk"] = 3
ang$moccu[ang$moccu == "Bank Clerk"] = 3
ang$moccu[ang$moccu == "Bank Clerk "] = 3
ang$moccu[ang$moccu == "Bank Clerk (Air Mechanic S.A.A.F.)"] = 3
ang$moccu[ang$moccu == "Bank Clerk On Active Service"] = 3
ang$moccu[ang$moccu == "Bank Inspector"] = 2
ang$moccu[ang$moccu == "Bank Manager"] = 2
ang$moccu[ang$moccu == "Bank Manager (Retired)"] = 2
ang$moccu[ang$moccu == "Bank Manager, Standard Bank"] = 2
ang$moccu[ang$moccu == "Bank messenger"] = 3
ang$moccu[ang$moccu == "Bank Messenger"] = 3
ang$moccu[ang$moccu == "Bank Official"] = 2
ang$moccu[ang$moccu == "Bank Official(Retired)"] = 2
ang$moccu[ang$moccu == "Bank Teller"] = 3
ang$moccu[ang$moccu == "Banker"] = 2
ang$moccu[ang$moccu == "Bankers accountant"] = 1
ang$moccu[ang$moccu == "Bankers Clerk"] = 3
ang$moccu[ang$moccu == "Bantu-Commissionaire"] = 2
ang$moccu[ang$moccu == "Bar Attendant"] = 5
ang$moccu[ang$moccu == "Bar attendant"] = 5
ang$moccu[ang$moccu == "Bar boy"] = 5
ang$moccu[ang$moccu == "Bar Fitter"] = 8
ang$moccu[ang$moccu == "Bar manager"] = 2
ang$moccu[ang$moccu == "Bar Steward"] = 5
ang$moccu[ang$moccu == "Barber"] = 5
ang$moccu[ang$moccu == "Barboy"] = 5
ang$moccu[ang$moccu == "Bar-boy"] = 5
ang$moccu[ang$moccu == "Bar-boy at Wine Buffet S.A.R."] = 5
ang$moccu[ang$moccu == "Bar-Boy for Hotel"] = 5
ang$moccu[ang$moccu == "Barley dresser"] = 6
ang$moccu[ang$moccu == "Barman"] = 5
ang$moccu[ang$moccu == "Barman S.A.R."] = 5
ang$moccu[ang$moccu == "Barrier attendant"] = 5
ang$moccu[ang$moccu == "Barrier Attendant S.A.R."] = 5
ang$moccu[ang$moccu == "Barrister"] = 1
ang$moccu[ang$moccu == "Barrister, Resident Magistrate"] = 1
ang$moccu[ang$moccu == "Barrister-at-Law"] = 1
ang$moccu[ang$moccu == "Basic Technician"] = 0
ang$moccu[ang$moccu == "Basic Training"] = 5
ang$moccu[ang$moccu == "Basic Training S.A.D.F."] = 5
ang$moccu[ang$moccu == "Basin Technical Trainee"] = 0
ang$moccu[ang$moccu == "Basket maker"] = 9
ang$moccu[ang$moccu == "Basket maker at Institute for the Blind"] = 9
ang$moccu[ang$moccu == "Basket-maker"] = 9
ang$moccu[ang$moccu == "Bath attendant"] = 5
ang$moccu[ang$moccu == "Battery Mechanic"] = 8
ang$moccu[ang$moccu == "BatteryDepartment"] = 8
ang$moccu[ang$moccu == "Bechuanaland Police"] = 5
ang$moccu[ang$moccu == "Bed Steward S.A.R."] = 5
ang$moccu[ang$moccu == "Bed Steward S.A.R."] = 5
ang$moccu[ang$moccu == "Bedding attendant S.A.R."] = 5
ang$moccu[ang$moccu == "Bedding Steward S.A.R."] = 5
ang$moccu[ang$moccu == "Bedding-maker"] = 5
ang$moccu[ang$moccu == "Belt-maker"] = 7
ang$moccu[ang$moccu == "Belt-sander"] = 7
ang$moccu[ang$moccu == "Bengal Civil Service"] = 2
ang$moccu[ang$moccu == "Beveller"] = 7
ang$moccu[ang$moccu == "Bicycle Repairer"] = 8
ang$moccu[ang$moccu == "Bill poster"] = 9
ang$moccu[ang$moccu == "Billiard-marker"] = 5
ang$moccu[ang$moccu == "Billiards Marker"] = 5
ang$moccu[ang$moccu == "Bill-poster"] = 9
ang$moccu[ang$moccu == "Binder"] = 9
ang$moccu[ang$moccu == "Binders assistant"] = 9
ang$moccu[ang$moccu == "Binders Assistant"] = 9
ang$moccu[ang$moccu == "Biologist"] = 0
ang$moccu[ang$moccu == "Bioscope Attendant"] = 5
ang$moccu[ang$moccu == "Bioscope Cleaner"] = 5
ang$moccu[ang$moccu == "Bioscope operator"] = 8
ang$moccu[ang$moccu == "Bioscope Operator"] = 8
ang$moccu[ang$moccu == "Biscuit baker"] = 7
ang$moccu[ang$moccu == "Biscuit Factory Employee"] = 9
ang$moccu[ang$moccu == "Biscuit maker"] = 7
ang$moccu[ang$moccu == "Biscuit Packer"] = 8
ang$moccu[ang$moccu == "Bishop of Zululand"] = 1
ang$moccu[ang$moccu == "Bitumen Factory worker"] = 9
ang$moccu[ang$moccu == "Blacksmith"] = 8
ang$moccu[ang$moccu == "Blacksmith "] = 8
ang$moccu[ang$moccu == "Blacksmith + Farrier"] = 8
ang$moccu[ang$moccu == "Blacksmith S.A.R."] = 8
ang$moccu[ang$moccu == "Blacksmith Spring-maker"] = 8
ang$moccu[ang$moccu == "Blacksmith(now S.A.F. Artillery)"] = 8
ang$moccu[ang$moccu == "Blacksmiths Striker"] = 8
ang$moccu[ang$moccu == "Blanket Drier"] = 5
ang$moccu[ang$moccu == "Blanket Examiner"] = 7
ang$moccu[ang$moccu == "Blanket Factory Machinist"] = 8
ang$moccu[ang$moccu == "Blanket factory-hand"] = 9
ang$moccu[ang$moccu == "Blanket Machinist"] = 8
ang$moccu[ang$moccu == "Blanket washer"] = 7
ang$moccu[ang$moccu == "Blanket Weaver"] = 7
ang$moccu[ang$moccu == "Blanketmaker"] = 7
ang$moccu[ang$moccu == "Blanket-maker"] = 7
ang$moccu[ang$moccu == "Blaster"] = 7
ang$moccu[ang$moccu == "Blender"] = 7
ang$moccu[ang$moccu == "Blindmaker"] = 9
ang$moccu[ang$moccu == "Block Cutter"] = 9
ang$moccu[ang$moccu == "Blocker"] = 9
ang$moccu[ang$moccu == "Blocker Millinery Trade"] = 9
ang$moccu[ang$moccu == "Blocklayer"] = 9
ang$moccu[ang$moccu == "Blockman"] = 9
ang$moccu[ang$moccu == "Blockman + Orderman"] = 7
ang$moccu[ang$moccu == "Blockman at Butcher"] = 7
ang$moccu[ang$moccu == "Blockman at Butchery"] = 7
ang$moccu[ang$moccu == "Boat Builders Employee"] = 9
ang$moccu[ang$moccu == "Boat maker"] = 9
ang$moccu[ang$moccu == "Boat-builder"] = 9
ang$moccu[ang$moccu == "Boatman"] = 9
ang$moccu[ang$moccu == "Boatsmith"] = 9
ang$moccu[ang$moccu == "Boatswain, Harbour Board"] = 2
ang$moccu[ang$moccu == "Body-builder"] = 1
ang$moccu[ang$moccu == "Boiler attendant"] = 8
ang$moccu[ang$moccu == "Boiler Attendant"] = 8
ang$moccu[ang$moccu == "Boiler Attendant for Air Force"] = 8
ang$moccu[ang$moccu == "Boiler Maker"] = 8
ang$moccu[ang$moccu == "Boiler maker S.A.R."] = 8
ang$moccu[ang$moccu == "Boilermaker"] = 8
ang$moccu[ang$moccu == "Boiler-maker"] = 8
ang$moccu[ang$moccu == "Boiler-maker "] = 8
ang$moccu[ang$moccu == "Boiler-maker (On Active Service)"] = 8
ang$moccu[ang$moccu == "Boilermaker S.A.R."] = 8
ang$moccu[ang$moccu == "Boiler-maker S.A.R."] = 8
ang$moccu[ang$moccu == "Boiler-maker S.A.R.+H."] = 8
ang$moccu[ang$moccu == "Boilermaker, presently Sailor S.A.N."] = 8
ang$moccu[ang$moccu == "Boiler-makers mate"] = 8
ang$moccu[ang$moccu == "Boilerman"] = 8
ang$moccu[ang$moccu == "Bombardier"] = 5
ang$moccu[ang$moccu == "Bombardier Cape Corps"] = 5
ang$moccu[ang$moccu == "Bombardier R. A."] = 5
ang$moccu[ang$moccu == "Bombardier Royal Garrison Artillery"] = 5
ang$moccu[ang$moccu == "Bombardier U.D.F."] = 5
ang$moccu[ang$moccu == "Book binder"] = 9
ang$moccu[ang$moccu == "Book Binder"] = 9
ang$moccu[ang$moccu == "Book checker"] = 3
ang$moccu[ang$moccu == "Book Match Maker"] = NA
ang$moccu[ang$moccu == "Book Publishers Agent"] = NA
ang$moccu[ang$moccu == "Bookbinder"] = 9
ang$moccu[ang$moccu == "Book-binder"] = 9
ang$moccu[ang$moccu == "Bookbinder(Argus Co.)"] = 9
ang$moccu[ang$moccu == "Booking Clerk"] = 3
ang$moccu[ang$moccu == "Booking Clerk S.A.R."] = 3
ang$moccu[ang$moccu == "Bookkeeper"] = 1
ang$moccu[ang$moccu == "Bookkeeper"] = 1
ang$moccu[ang$moccu == "Bookkeeper + Soldier"] = 1
ang$moccu[ang$moccu == "Book-keeping"] = 1
ang$moccu[ang$moccu == "Bookseller"] = 4
ang$moccu[ang$moccu == "Booksellers Storeman"] = 4
ang$moccu[ang$moccu == "Boot + Shoe Maker"] = 8
ang$moccu[ang$moccu == "Boot + Shoe maker"] = 8
ang$moccu[ang$moccu == "Boot Factory Canvasser"] = 8
ang$moccu[ang$moccu == "Boot Factory Hand"] = 9
ang$moccu[ang$moccu == "Boot factory-hand"] = 9
ang$moccu[ang$moccu == "Boot Manufacturer"] = 8
ang$moccu[ang$moccu == "Boot repairer"] = 8
ang$moccu[ang$moccu == "Boot Repairer"] = 8
ang$moccu[ang$moccu == "Boot Salesman"] = 4
ang$moccu[ang$moccu == "Boot-clicker"] = 8
ang$moccu[ang$moccu == "Boot-finisher"] = 8
ang$moccu[ang$moccu == "Bootmaker"] = 8
ang$moccu[ang$moccu == "Boot-maker"] = 8
ang$moccu[ang$moccu == "Bootmakers messenger"] = 3
ang$moccu[ang$moccu == "Boot-trade"] = 4
ang$moccu[ang$moccu == "Botanic Gardener"] = 6
ang$moccu[ang$moccu == "Botanical gardener"] = 6
ang$moccu[ang$moccu == "Botanist"] = 0
ang$moccu[ang$moccu == "Bottle Packer"] = 9
ang$moccu[ang$moccu == "Bottle Sorter"] = 9
ang$moccu[ang$moccu == "Bottle Store Assistant"] = 4
ang$moccu[ang$moccu == "Bottle Store assistant"] = 4
ang$moccu[ang$moccu == "Bottle Store Clerk"] = 3
ang$moccu[ang$moccu == "Bottle Store Proprietor"] = 5
ang$moccu[ang$moccu == "Bottle-labeler"] = 8
ang$moccu[ang$moccu == "Bottle-sorter"] = 8
ang$moccu[ang$moccu == "Bottlestore Assistant"] = 4
ang$moccu[ang$moccu == "Bottlestore worker"] = 4
ang$moccu[ang$moccu == "Box Machine Operator"] = 8
ang$moccu[ang$moccu == "Box-maker"] = 9
ang$moccu[ang$moccu == "Boxmaker in meat factory"] = 9
ang$moccu[ang$moccu == "Branch Manager"] = 2
ang$moccu[ang$moccu == "Branch Manager "] = 2
ang$moccu[ang$moccu == "Branch Manager Manufacturing Chemists"] = 2
ang$moccu[ang$moccu == "Branch Manager Northern Assurance Co."] = 2
ang$moccu[ang$moccu == "Branch Manager School of Accountancy"] = 2
ang$moccu[ang$moccu == "Brass Finisher"] = 8
ang$moccu[ang$moccu == "Brass finisher S.A.R."] = 8
ang$moccu[ang$moccu == "Brass Polisher"] = 8
ang$moccu[ang$moccu == "Brass-finisher"] = 8
ang$moccu[ang$moccu == "Bread Cart Driver"] = 9
ang$moccu[ang$moccu == "Bread Van Conductor"] = 3
ang$moccu[ang$moccu == "Brewer"] = 7
ang$moccu[ang$moccu == "Brewers assistant"] = 7
ang$moccu[ang$moccu == "Brewers Foreman"] = 2
ang$moccu[ang$moccu == "Brewers labourer"] = 7
ang$moccu[ang$moccu == "Brewers packer"] = 7
ang$moccu[ang$moccu == "Brewery"] = 7
ang$moccu[ang$moccu == "Brewery Employee"] = 7
ang$moccu[ang$moccu == "Brewery Foreman"] = 2
ang$moccu[ang$moccu == "Brewery Labourer"] = 7
ang$moccu[ang$moccu == "Brewery worker"] = 7
ang$moccu[ang$moccu == "Brick manufacturer"] = 9
ang$moccu[ang$moccu == "Brickfields Labourer"] = 9
ang$moccu[ang$moccu == "Brickfields Manager"] = 2
ang$moccu[ang$moccu == "Bricklayer"] = 9
ang$moccu[ang$moccu == "Bricklayer assistant"] = 9
ang$moccu[ang$moccu == "Bricklayer S.A.R."] = 9
ang$moccu[ang$moccu == "Bricklayer(On Military Service)"] = 9
ang$moccu[ang$moccu == "Bricklayers assistant"] = 9
ang$moccu[ang$moccu == "Bricklayers labourer"] = 9
ang$moccu[ang$moccu == "Bricklayers lsbourer"] = 9
ang$moccu[ang$moccu == "Brickmakder"] = 9
ang$moccu[ang$moccu == "Brickmaker"] = 9
ang$moccu[ang$moccu == "Brickmaker (On Active Service)"] = 9
ang$moccu[ang$moccu == "Brickmaker(On Active Service)"] = 9
ang$moccu[ang$moccu == "Brickman"] = 9
ang$moccu[ang$moccu == "Brickworks Manager"] = 2
ang$moccu[ang$moccu == "Brickyard-hand"] = 9
ang$moccu[ang$moccu == "Bridle fitter"] = 8
ang$moccu[ang$moccu == "Bridle-maker"] = 8
ang$moccu[ang$moccu == "Brief-case Maker"] = 8
ang$moccu[ang$moccu == "Brigade Sergt. Major S.A.M.R."] = 5
ang$moccu[ang$moccu == "British Manufacturers Agent"] = 4
ang$moccu[ang$moccu == "British S.A. Police"] = 5
ang$moccu[ang$moccu == "Broker"] = 4
ang$moccu[ang$moccu == "Brokers Clerk"] = 3
ang$moccu[ang$moccu == "Broom maker"] = 8
ang$moccu[ang$moccu == "Brush Hand"] = 8
ang$moccu[ang$moccu == "Brush maker"] = 8
ang$moccu[ang$moccu == "Brush-factory Worker"] = 8
ang$moccu[ang$moccu == "Brush-hand"] = 8
ang$moccu[ang$moccu == "Brushmaker"] = 8
ang$moccu[ang$moccu == "Brush-maker"] = 8
ang$moccu[ang$moccu == "Builder"] = 9
ang$moccu[ang$moccu == "Builder + Contractor"] = 2
ang$moccu[ang$moccu == "Builder and Constructor"] = 2
ang$moccu[ang$moccu == "Builder in Private Business"] = 9
ang$moccu[ang$moccu == "Builders apprentice"] = 9
ang$moccu[ang$moccu == "Builders Carpenter"] = 9
ang$moccu[ang$moccu == "Builders Clerk"] = 3
ang$moccu[ang$moccu == "Builders Clerk"] = 3
ang$moccu[ang$moccu == "Builders Foreman"] = 2
ang$moccu[ang$moccu == "Builders hand"] = 9
ang$moccu[ang$moccu == "Builders labourer"] = 9
ang$moccu[ang$moccu == "Builders Labourer"] = 9
ang$moccu[ang$moccu == "Builders labourer (On Military Service Cape Corps)"] = 9
ang$moccu[ang$moccu == "Builders Representative"] = 9
ang$moccu[ang$moccu == "Building"] = 9
ang$moccu[ang$moccu == "Building Contractor"] = 2
ang$moccu[ang$moccu == "Building labourer"] = 9
ang$moccu[ang$moccu == "Building Labourer"] = 9
ang$moccu[ang$moccu == "Building Society Manager"] = 2
ang$moccu[ang$moccu == "Building Supervisor"] = 2
ang$moccu[ang$moccu == "Building Surveyor"] = 2
ang$moccu[ang$moccu == "Building Trade Labourer"] = 9
ang$moccu[ang$moccu == "Building Trade Worker"] = 9
ang$moccu[ang$moccu == "Bulk-filler in Winery"] = 9
ang$moccu[ang$moccu == "Bulldozer Operator"] = 9
ang$moccu[ang$moccu == "Bunkerer"] = 9
ang$moccu[ang$moccu == "Burner"] = 9
ang$moccu[ang$moccu == "Burner Operator (Brickworks)"] = 9
ang$moccu[ang$moccu == "Bus Conductor"] = 3
ang$moccu[ang$moccu == "Bus driver"] = 9
ang$moccu[ang$moccu == "Bus Driver"] = 9
ang$moccu[ang$moccu == "Bus Driver "] = 9
ang$moccu[ang$moccu == "Bus Driver S.A.R."] = 9
ang$moccu[ang$moccu == "Bus Inspector"] = 2
ang$moccu[ang$moccu == "Bus Shunter"] = 9
ang$moccu[ang$moccu == "Bus-conductor"] = 3
ang$moccu[ang$moccu == "Bus-Conductor"] = 3
ang$moccu[ang$moccu == "Bus-driver"] = 9
ang$moccu[ang$moccu == "Business"] = NA
ang$moccu[ang$moccu == "Business Executive"] = 4
ang$moccu[ang$moccu == "Business Intermediary"] = 4
ang$moccu[ang$moccu == "Business man"] = 4
ang$moccu[ang$moccu == "Business Man"] = 4
ang$moccu[ang$moccu == "Business Manager"] = 2
ang$moccu[ang$moccu == "Business Proprietor"] = 2
ang$moccu[ang$moccu == "Business Representative"] = 4
ang$moccu[ang$moccu == "Business Secretary"] = 3
ang$moccu[ang$moccu == "Businessman"] = 4
ang$moccu[ang$moccu == "Butcer"] = 7
ang$moccu[ang$moccu == "Butcher"] = 7
ang$moccu[ang$moccu == "Butcher boy"] = 7
ang$moccu[ang$moccu == "Butcher Order Boy"] = 7
ang$moccu[ang$moccu == "Butcher-boy"] = 7
ang$moccu[ang$moccu == "Butchers assistant"] = 7
ang$moccu[ang$moccu == "Butchers Assistant"] = 7
ang$moccu[ang$moccu == "Butchers Blockman"] = 7
ang$moccu[ang$moccu == "Butchers boy"] = 7
ang$moccu[ang$moccu == "Butchers clerk"] = 3
ang$moccu[ang$moccu == "Butchers Clerk"] = 3
ang$moccu[ang$moccu == "Butchers delivery man"] = 3
ang$moccu[ang$moccu == "Butchers Deliveryman"] = 3
ang$moccu[ang$moccu == "Butchers Delivery-man"] = 3
ang$moccu[ang$moccu == "Butchers labourer"] = 7
ang$moccu[ang$moccu == "Butchers man"] = 7
ang$moccu[ang$moccu == "Butchers messenger"] = 3
ang$moccu[ang$moccu == "Butchers Orderman"] = 3
ang$moccu[ang$moccu == "Butler"] = 5
ang$moccu[ang$moccu == "Butter maker"] = 7
ang$moccu[ang$moccu == "Button-maker"] = 7
ang$moccu[ang$moccu == "Buyer"] = 4
ang$moccu[ang$moccu == "Buyer (Stuttafords Ltd.)"] = 4
ang$moccu[ang$moccu == "Buyer Salesman"] = 4
ang$moccu[ang$moccu == "C.A.W."] = NA
ang$moccu[ang$moccu == "C.G. Railway"] = 9
ang$moccu[ang$moccu == "C.G.R."] = 9
ang$moccu[ang$moccu == "C.G.R. Salt River"] = 9
ang$moccu[ang$moccu == "C.I.D., S.A. Police"] = 5
ang$moccu[ang$moccu == "C.P.O. Shipwright"] = 8
ang$moccu[ang$moccu == "Cab driver"] = 9
ang$moccu[ang$moccu == "Cab Driver"] = 9
ang$moccu[ang$moccu == "Cab Owner"] = 9
ang$moccu[ang$moccu == "Cab Proprietor"] = 9
ang$moccu[ang$moccu == "Cabdriver"] = 9
ang$moccu[ang$moccu == "Cab-driver"] = 9
ang$moccu[ang$moccu == "Cabin maker"] = 7
ang$moccu[ang$moccu == "Cabinet Machinist"] = 7
ang$moccu[ang$moccu == "Cabinet maker"] = 7
ang$moccu[ang$moccu == "Cabinet Maker"] = 7
ang$moccu[ang$moccu == "Cabinet maker for Furniture firm"] = 7
ang$moccu[ang$moccu == "Cabinet makerSoldier"] = 7
ang$moccu[ang$moccu == "Cabinet makers apprentice"] = 7
ang$moccu[ang$moccu == "Cabinet makers assistant"] = 7
ang$moccu[ang$moccu == "Cabinet Polisher (On Pension)"] = 7
ang$moccu[ang$moccu == "Cabinet stainer"] = 7
ang$moccu[ang$moccu == "Cabinet worker"] = 7
ang$moccu[ang$moccu == "Cabinetmaker"] = 7
ang$moccu[ang$moccu == "Cabinet-maker"] = 7
ang$moccu[ang$moccu == "Cabinet-maker Fitter"] = 7
ang$moccu[ang$moccu == "Cabinet-maker S.A.D.F."] = 7
ang$moccu[ang$moccu == "Cabinet-makers Labourer"] = 9
ang$moccu[ang$moccu == "Cable Assistant"] = 8
ang$moccu[ang$moccu == "Cable Clerk"] = 3
ang$moccu[ang$moccu == "Cable Co."] = 9
ang$moccu[ang$moccu == "Cable Jointer"] = 8
ang$moccu[ang$moccu == "Cable Jointer G.P.O."] = 8
ang$moccu[ang$moccu == "Cable layer"] = 8
ang$moccu[ang$moccu == "Cable Mechanic"] = 8
ang$moccu[ang$moccu == "Cable-jointer"] = 8
ang$moccu[ang$moccu == "Cable-Trencher"] = 9
ang$moccu[ang$moccu == "Cabman"] = 9
ang$moccu[ang$moccu == "Cab-proprietor"] = 9
ang$moccu[ang$moccu == "Cab-Proprietor"] = 9
ang$moccu[ang$moccu == "Cadet Fireman"] = 9
ang$moccu[ang$moccu == "Cadet Officer"] = 5
ang$moccu[ang$moccu == "Cafe worker"] = 5
ang$moccu[ang$moccu == "CafΘ Assistant"] = 5
ang$moccu[ang$moccu == "CafΘ Keeper"] = 2
ang$moccu[ang$moccu == "CafΘ Labourer"] = 5
ang$moccu[ang$moccu == "CafΘ Manager"] = 2
ang$moccu[ang$moccu == "CafΘ Owner"] = 5
ang$moccu[ang$moccu == "CafΘ Proprietor"] = 5
ang$moccu[ang$moccu == "CafΘ-keeper"] = 2
ang$moccu[ang$moccu == "Camera Operator"] = 1
ang$moccu[ang$moccu == "Cameraman"] = 1
ang$moccu[ang$moccu == "Candle-maker"] = 9
ang$moccu[ang$moccu == "Cane Farmer"] = 2
ang$moccu[ang$moccu == "Cane worker"] = 6
ang$moccu[ang$moccu == "Canner"] = 7
ang$moccu[ang$moccu == "Canning Technologist"] = 7
ang$moccu[ang$moccu == "Canvas maker"] = 7
ang$moccu[ang$moccu == "Canvas worker"] = 7
ang$moccu[ang$moccu == "Canvasser"] = 4
ang$moccu[ang$moccu == "Cape 7th Fusilier"] = 5
ang$moccu[ang$moccu == "Cape Coloured Corps Military"] = 5
ang$moccu[ang$moccu == "Cape Corps"] = 5
ang$moccu[ang$moccu == "Cape Corps Military"] = 5
ang$moccu[ang$moccu == "Cape Explosive Works"] = 9
ang$moccu[ang$moccu == "Cape Fortress Engineer"] = 0
ang$moccu[ang$moccu == "Cape Government Railway"] = 9
ang$moccu[ang$moccu == "Cape Government Railways"] = 9
ang$moccu[ang$moccu == "Cape Govt. Railways"] = 9
ang$moccu[ang$moccu == "Cape Milling Co."] = 9
ang$moccu[ang$moccu == "Cape Mounted Police"] = 5
ang$moccu[ang$moccu == "Cape Mounted Rifleman"] = 5
ang$moccu[ang$moccu == "Cape Police"] = 5
ang$moccu[ang$moccu == "Cape Province Administration"] = 3
ang$moccu[ang$moccu == "Cape Times Employee"] = 9
ang$moccu[ang$moccu == "Captain"] = 5
ang$moccu[ang$moccu == "Captain "] = 5
ang$moccu[ang$moccu == "Captain 5th Gurkha Rifles"] = 5
ang$moccu[ang$moccu == "Captain 5th Lancers"] = 5
ang$moccu[ang$moccu == "Captain A.S.C."] = 5
ang$moccu[ang$moccu == "Captain in Australian S.A. Contingent"] = 5
ang$moccu[ang$moccu == "Captain in Imperial Army"] = 5
ang$moccu[ang$moccu == "Captain in Royal Army Medical Corps"] = 5
ang$moccu[ang$moccu == "Captain in the Army"] = 5
ang$moccu[ang$moccu == "Captain Nigerian Regiment"] = 5
ang$moccu[ang$moccu == "Captain R.A.F."] = 5
ang$moccu[ang$moccu == "Captain R.N."] = 5
ang$moccu[ang$moccu == "Captain Royal Army"] = 5
ang$moccu[ang$moccu == "Captain Royal Artillery"] = 5
ang$moccu[ang$moccu == "Captain Royal Engineers"] = 5
ang$moccu[ang$moccu == "Captain Royal Marine."] = 5
ang$moccu[ang$moccu == "Captain Royal Navy"] = 5
ang$moccu[ang$moccu == "Captain S.A. Air Force"] = 5
ang$moccu[ang$moccu == "Captain S.A. Air Force "] = 5
ang$moccu[ang$moccu == "Captain S.A. Engineering Corps"] = 5
ang$moccu[ang$moccu == "Captain S.A.A.F."] = 5
ang$moccu[ang$moccu == "Captain S.A.C."] = 5
ang$moccu[ang$moccu == "Captain S.A.E.C."] = 5
ang$moccu[ang$moccu == "Captain S.A.M.C."] = 5
ang$moccu[ang$moccu == "Captain, Northumberland Fusiliers"] = 5
ang$moccu[ang$moccu == "Captain, Royal Army Medical Corps"] = 5
ang$moccu[ang$moccu == "Captain, Royal Garrison Artillery"] = 5
ang$moccu[ang$moccu == "Captain, Royal Irish Fusiliers"] = 5
ang$moccu[ang$moccu == "Captain, S.A. Medical Corps"] = 5
ang$moccu[ang$moccu == "Captain, S.A.A.F."] = 5
ang$moccu[ang$moccu == "Car Assembler"] = 8
ang$moccu[ang$moccu == "Car Driver"] = 9
ang$moccu[ang$moccu == "Car driver"] = 9
ang$moccu[ang$moccu == "Car Inspector"] = 2
ang$moccu[ang$moccu == "Car Polisher"] = 8
ang$moccu[ang$moccu == "Carbonizer"] = 9
ang$moccu[ang$moccu == "Carding Machinist"] = 8
ang$moccu[ang$moccu == "Car-driver"] = 9
ang$moccu[ang$moccu == "Caretaker"] = 5
ang$moccu[ang$moccu == "Caretaker G.P.O."] = 5
ang$moccu[ang$moccu == "Caretaker Globe House"] = 5
ang$moccu[ang$moccu == "Caretaker Golf Links"] = 5
ang$moccu[ang$moccu == "Caretaker Groote Schuur"] = 5
ang$moccu[ang$moccu == "Caretaker on Farm"] = 5
ang$moccu[ang$moccu == "Caretaker: Mission School"] = 5
ang$moccu[ang$moccu == "Careworker"] = 5
ang$moccu[ang$moccu == "Cargo Repairer Cape Town Docks"] = 9
ang$moccu[ang$moccu == "Carpenter"] = 9
ang$moccu[ang$moccu == "Carpenter (On Active Service)"] = 9
ang$moccu[ang$moccu == "Carpenter + Joiner"] = 9
ang$moccu[ang$moccu == "Carpenter and Painter"] = 9
ang$moccu[ang$moccu == "Carpenter Foreman"] = 2
ang$moccu[ang$moccu == "Carpenter man"] = 9
ang$moccu[ang$moccu == "Carpenter S.A.R."] = 9
ang$moccu[ang$moccu == "Carpenter, C T Municipality"] = 9
ang$moccu[ang$moccu == "CarpenterJoiner"] = 9
ang$moccu[ang$moccu == "Carpenter-joiner"] = 9
ang$moccu[ang$moccu == "Carpenters apprentice"] = 9
ang$moccu[ang$moccu == "Carpenters Apprentice"] = 9
ang$moccu[ang$moccu == "Carpenters assistant"] = 9
ang$moccu[ang$moccu == "Carpenters Boy"] = 9
ang$moccu[ang$moccu == "Carpenters Improver"] = 9
ang$moccu[ang$moccu == "Carpenters labourer"] = 9
ang$moccu[ang$moccu == "Carpet Fitter"] = 7
ang$moccu[ang$moccu == "Carpet Weaver"] = 7
ang$moccu[ang$moccu == "Carpet-layer"] = 7
ang$moccu[ang$moccu == "Carriage + Wagon ExaminerRepairer"] = 8
ang$moccu[ang$moccu == "Carriage and Wagon Repairer S.A.R."] = 8
ang$moccu[ang$moccu == "Carriage Builder"] = 8
ang$moccu[ang$moccu == "Carriage Builder S.A.R."] = 8
ang$moccu[ang$moccu == "Carriage cleaner"] = 5
ang$moccu[ang$moccu == "Carriage Cleaner S.A.R."] = 5
ang$moccu[ang$moccu == "Carriage Examiner S.A.R."] = 8
ang$moccu[ang$moccu == "Carriage painter"] = 9
ang$moccu[ang$moccu == "Carriage painter S.A.R."] = 9
ang$moccu[ang$moccu == "Carriage trimmer"] = 8
ang$moccu[ang$moccu == "Carriage Trimmer"] = 8
ang$moccu[ang$moccu == "Carriage-builder"] = 8
ang$moccu[ang$moccu == "Carriage-builder S.A.R."] = 8
ang$moccu[ang$moccu == "Carrier"] = 9
ang$moccu[ang$moccu == "Cart driver"] = 9
ang$moccu[ang$moccu == "Cart Driver"] = 9
ang$moccu[ang$moccu == "Cart Driver (Cape Divisional Council)"] = 9
ang$moccu[ang$moccu == "Cart Proprietor"] = 9
ang$moccu[ang$moccu == "Cart Trimmer"] = 8
ang$moccu[ang$moccu == "Cartage Contractor"] = 2
ang$moccu[ang$moccu == "Cartage Dept., S.A. Railways"] = 8
ang$moccu[ang$moccu == "Cartage Foreman S.A.R."] = 2
ang$moccu[ang$moccu == "Cartdriver"] = 9
ang$moccu[ang$moccu == "Cart-driver"] = 9
ang$moccu[ang$moccu == "Carter"] = 9
ang$moccu[ang$moccu == "Carter for Divisional Council"] = 9
ang$moccu[ang$moccu == "Carter for Municipality"] = 9
ang$moccu[ang$moccu == "Carters labourer"] = 9
ang$moccu[ang$moccu == "Carton Designer"] = 9
ang$moccu[ang$moccu == "Cartoonist"] = 1
ang$moccu[ang$moccu == "Carver"] = 9
ang$moccu[ang$moccu == "Carwasher"] = 5
ang$moccu[ang$moccu == "Cashier"] = 4
ang$moccu[ang$moccu == "Castle Brewery"] = 7
ang$moccu[ang$moccu == "Casual Clerk on S.A.R."] = 3
ang$moccu[ang$moccu == "Catechist"] = 1
ang$moccu[ang$moccu == "Caterer"] = 5
ang$moccu[ang$moccu == "Catering Manager"] = 2
ang$moccu[ang$moccu == "Cathedral Organist"] = 1
ang$moccu[ang$moccu == "Caulker"] = 9
ang$moccu[ang$moccu == "Ceiling Erector"] = 9
ang$moccu[ang$moccu == "Ceiling fixer"] = 9
ang$moccu[ang$moccu == "Ceiling-fixer"] = 9
ang$moccu[ang$moccu == "Cellarman"] = 5
ang$moccu[ang$moccu == "Cement Block Maker"] = 9
ang$moccu[ang$moccu == "Cement Worker"] = 9
ang$moccu[ang$moccu == "Cement Works Employee"] = 9
ang$moccu[ang$moccu == "Cementer(Shoe Trade)"] = 8
ang$moccu[ang$moccu == "Cemetary Curator"] = 9
ang$moccu[ang$moccu == "Cemetery Employee"] = 9
ang$moccu[ang$moccu == "Central News Agency"] = NA
ang$moccu[ang$moccu == "Chaffeur"] = 9
ang$moccu[ang$moccu == "Chair maker"] = 8
ang$moccu[ang$moccu == "Chairmaker"] = 8
ang$moccu[ang$moccu == "Chair-maker"] = 8
ang$moccu[ang$moccu == "Chandler"] = 4
ang$moccu[ang$moccu == "Chaplain R.N.V.R."] = 1
ang$moccu[ang$moccu == "Chaplain Royal Navy"] = 1
ang$moccu[ang$moccu == "Charge Male Nurse"] = 0
ang$moccu[ang$moccu == "Charge-hand"] = 2
ang$moccu[ang$moccu == "Chargeman"] = 2
ang$moccu[ang$moccu == "Chargeman at Brickfield"] = 2
ang$moccu[ang$moccu == "Chargeman Cape Town Corporation"] = 2
ang$moccu[ang$moccu == "Chargeman Fitter Salt River Works"] = 2
ang$moccu[ang$moccu == "Chartered Accountancy, Corporal Army Pay Corps"] = 1
ang$moccu[ang$moccu == "Chartered Accountant"] = 1
ang$moccu[ang$moccu == "Chartered Accountant (Captain S.A.A.)"] = 1
ang$moccu[ang$moccu == "Chartered Accountant, Basutoland Government"] = 1
ang$moccu[ang$moccu == "Chartered Civil Engineer"] = 0
ang$moccu[ang$moccu == "Chartered Physiotherapist"] = 0
ang$moccu[ang$moccu == "Chartered Secretary"] = 3
ang$moccu[ang$moccu == "Chartered Surveyor"] = 0
ang$moccu[ang$moccu == "Chauffeur"] = 9
ang$moccu[ang$moccu == "Chauffeur + Gardener"] = 9
ang$moccu[ang$moccu == "Chauffeur mechanic"] = 8
ang$moccu[ang$moccu == "ChauffeurGardener"] = 9
ang$moccu[ang$moccu == "Check Clerk"] = 3
ang$moccu[ang$moccu == "Checker"] = 3
ang$moccu[ang$moccu == "Checker "] = 3
ang$moccu[ang$moccu == "Checker (City Council)"] = 3
ang$moccu[ang$moccu == "Checker C.G.R."] = 3
ang$moccu[ang$moccu == "Checker Cold Storage"] = 3
ang$moccu[ang$moccu == "Checker Express Deliveries"] = 3
ang$moccu[ang$moccu == "Checker Factory"] = 3
ang$moccu[ang$moccu == "Checker for City Council"] = 3
ang$moccu[ang$moccu == "Checker Government Railways"] = 3
ang$moccu[ang$moccu == "Checker on Railway"] = 3
ang$moccu[ang$moccu == "Checker on S.A.R."] = 3
ang$moccu[ang$moccu == "Checker S.A.R."] = 3
ang$moccu[ang$moccu == "Checker S.A.R.+H."] = 3
ang$moccu[ang$moccu == "Checker Tobacco Co."] = 3
ang$moccu[ang$moccu == "Checker Tobacco Company"] = 3
ang$moccu[ang$moccu == "Checkman"] = 3
ang$moccu[ang$moccu == "Chef"] = 5
ang$moccu[ang$moccu == "Chef (Hospital)"] = 5
ang$moccu[ang$moccu == "Chef and labourer"] = 5
ang$moccu[ang$moccu == "Chef S.A.R."] = 5
ang$moccu[ang$moccu == "Chemical Engineer"] = 0
ang$moccu[ang$moccu == "Chemical Laboratory Assistant"] = 0
ang$moccu[ang$moccu == "Chemical technician"] = 8
ang$moccu[ang$moccu == "Chemical Technician"] = 8
ang$moccu[ang$moccu == "Chemical Technologist"] = 0
ang$moccu[ang$moccu == "Chemichal Laboratory Assistant"] = 0
ang$moccu[ang$moccu == "Chemist"] = 0
ang$moccu[ang$moccu == "Chemist (Dynamite Factory)"] = 0
ang$moccu[ang$moccu == "Chemist + Druggist"] = 0
ang$moccu[ang$moccu == "Chemist Assistant"] = 0
ang$moccu[ang$moccu == "Chemists assistant"] = 0
ang$moccu[ang$moccu == "Chemists Assistant"] = 0
ang$moccu[ang$moccu == "Chemists Boy"] = 0
ang$moccu[ang$moccu == "Chemists Labourer"] = 0
ang$moccu[ang$moccu == "Chemists servant"] = 0
ang$moccu[ang$moccu == "Chief Accountant"] = 1
ang$moccu[ang$moccu == "Chief Assistant at Royal Observatory"] = 0
ang$moccu[ang$moccu == "Chief Clerk"] = 3
ang$moccu[ang$moccu == "Chief Clerk Accounts"] = 3
ang$moccu[ang$moccu == "Chief Clerk, Insurance"] = 3
ang$moccu[ang$moccu == "Chief Constable"] = 5
ang$moccu[ang$moccu == "Chief Constable "] = 5
ang$moccu[ang$moccu == "Chief Constable Breakwater Convict Station"] = 5
ang$moccu[ang$moccu == "Chief Financial Superintendent S.A.R."] = 2
ang$moccu[ang$moccu == "Chief of the Horticultural Division, S.A."] = 2
ang$moccu[ang$moccu == "Chief Officer"] = 5
ang$moccu[ang$moccu == "Chief Officer "] = 5
ang$moccu[ang$moccu == "Chief Officer British Merchant Navy"] = 5
ang$moccu[ang$moccu == "Chief Officer on Trawler"] = 5
ang$moccu[ang$moccu == "Chief Officer S.A.E.C."] = 5
ang$moccu[ang$moccu == "Chief Petty Officer"] = 5
ang$moccu[ang$moccu == "Chief Petty Officer R.N."] = 5
ang$moccu[ang$moccu == "Chief Steward"] = 5
ang$moccu[ang$moccu == "Chief Steward Cable Ship Britannia"] = 5
ang$moccu[ang$moccu == "Chief Steward Catering Dept. S.A.R."] = 5
ang$moccu[ang$moccu == "Chief Storekeeper, C.T. Corporation"] = 4
ang$moccu[ang$moccu == "Chimney-sweep"] = 5
ang$moccu[ang$moccu == "Chiropodist"] = 0
ang$moccu[ang$moccu == "Chiropractor"] = 0
ang$moccu[ang$moccu == "Chocolate maker"] = 7
ang$moccu[ang$moccu == "Chocolate Mechanic"] = 8
ang$moccu[ang$moccu == "Choirman"] = 1
ang$moccu[ang$moccu == "Chrome Miner"] = 9
ang$moccu[ang$moccu == "Chromium Plater"] = 8
ang$moccu[ang$moccu == "Church Cleaner"] = 5
ang$moccu[ang$moccu == "Church Verger"] = 5
ang$moccu[ang$moccu == "Cicil servant"] = 3
ang$moccu[ang$moccu == "Cicil Servant"] = 3
ang$moccu[ang$moccu == "Cicil Servant (Justice)"] = 3
ang$moccu[ang$moccu == "Cigar maker"] = 7
ang$moccu[ang$moccu == "Cigarette maker"] = 7
ang$moccu[ang$moccu == "Cigar-maker"] = 7
ang$moccu[ang$moccu == "Cinema Attendant"] = 5
ang$moccu[ang$moccu == "Cinema Manager"] = 2
ang$moccu[ang$moccu == "Cinema Operator"] = 8
ang$moccu[ang$moccu == "Cinema Projectionist"] = 8
ang$moccu[ang$moccu == "Cinema Projectionist R.N."] = 8
ang$moccu[ang$moccu == "Cinema Projectionist, R.A.F."] = 8
ang$moccu[ang$moccu == "Cinemagraphic Projectionist"] = 8
ang$moccu[ang$moccu == "Cinematograph Operator"] = 8
ang$moccu[ang$moccu == "City Corporation Employee"] = 9
ang$moccu[ang$moccu == "City Coucil Labourer"] = 9
ang$moccu[ang$moccu == "City Council"] = 9
ang$moccu[ang$moccu == "City Council Employee"] = 9
ang$moccu[ang$moccu == "City Council Pensioner"] = 9
ang$moccu[ang$moccu == "City Tramway"] = 9
ang$moccu[ang$moccu == "Civil Clerk"] = 3
ang$moccu[ang$moccu == "Civil Commissioner"] = 2
ang$moccu[ang$moccu == "Civil Engineer"] = 0
ang$moccu[ang$moccu == "Civil Engineer (Divisional Council)"] = 0
ang$moccu[ang$moccu == "Civil Engineer (Municipal)"] = 0
ang$moccu[ang$moccu == "Civil Engineer S.A.R.+H. Administration"] = 0
ang$moccu[ang$moccu == "Civil Engineer, Lieut. S.A. Engineering Corps"] = 0
ang$moccu[ang$moccu == "Civil Engineer, Major S.A. Engineering Corps"] = 0
ang$moccu[ang$moccu == "Civil EngineerLieut. U.D.F."] = 0
ang$moccu[ang$moccu == "Civil Engineering Inspector"] = 0
ang$moccu[ang$moccu == "Civil Engineering Student"] = 0
ang$moccu[ang$moccu == "Civil Messenger R.N. Court"] = 3
ang$moccu[ang$moccu == "Civil servant"] = 2
ang$moccu[ang$moccu == "Civil Servant"] = 2
ang$moccu[ang$moccu == "Civil Servant (Dept. of Justice)"] = 2
ang$moccu[ang$moccu == "Civil Servant (Forestry Research)"] = 2
ang$moccu[ang$moccu == "Civil Servant (Northern Rhodesia)"] = 2
ang$moccu[ang$moccu == "Civil Servant (Retired)"] = 2
ang$moccu[ang$moccu == "Civil servant (Rhodesia)"] = 2
ang$moccu[ang$moccu == "Civil Servant Bechuanaland Protectorate"] = 2
ang$moccu[ang$moccu == "Civil Servant Clerk"] = 2
ang$moccu[ang$moccu == "Civil Servant Engineering Branch G.P.O."] = 2
ang$moccu[ang$moccu == "Civil Servant Native Affairs Department"] = 2
ang$moccu[ang$moccu == "Civil Servant On Active Service"] = 2
ang$moccu[ang$moccu == "Civil Servant Post Office"] = 2
ang$moccu[ang$moccu == "Civil Servant Southern Rhodesia"] = 2
ang$moccu[ang$moccu == "Civil Servant Southern Rhodesian Government"] = 2
ang$moccu[ang$moccu == "Civil Servant Union Education Dept., Pretoria"] = 2
ang$moccu[ang$moccu == "Civil servant(Dept. of Justice)"] = 2
ang$moccu[ang$moccu == "Civil Servant, Northern Rhodesia"] = 2
ang$moccu[ang$moccu == "Civil Service"] = 2
ang$moccu[ang$moccu == "Civil service"] = 2
ang$moccu[ang$moccu == "Civil Service (England)"] = 2
ang$moccu[ang$moccu == "Civil Service Pensioner"] = 2
ang$moccu[ang$moccu == "Civil Servsnt"] = 2
ang$moccu[ang$moccu == "Civl Servant"] = 2
ang$moccu[ang$moccu == "Claims Inspector S.A.R."] = 2
ang$moccu[ang$moccu == "Cleaner"] = 5
ang$moccu[ang$moccu == "Cleaner "] = 5
ang$moccu[ang$moccu == "Cleaner (University)"] = 5
ang$moccu[ang$moccu == "Cleaner + Caretaker"] = 5
ang$moccu[ang$moccu == "Cleaner + Dyer"] = 5
ang$moccu[ang$moccu == "Cleaner and Dyer"] = 5
ang$moccu[ang$moccu == "Cleaner at Imperial Airways"] = 5
ang$moccu[ang$moccu == "Cleaner Bus Company"] = 5
ang$moccu[ang$moccu == "Cleaner City Council"] = 5
ang$moccu[ang$moccu == "Cleaner G.P.O."] = 5
ang$moccu[ang$moccu == "Cleaner Health Dept."] = 5
ang$moccu[ang$moccu == "Cleaner in S.A. Police"] = 5
ang$moccu[ang$moccu == "Cleaner Magistrates Court"] = 5
ang$moccu[ang$moccu == "Cleaner S.A.R."] = 5
ang$moccu[ang$moccu == "Cleaner S.A.R.+H."] = 5
ang$moccu[ang$moccu == "Cleaner Tramway Co."] = 5
ang$moccu[ang$moccu == "Cleaner Tramway Company"] = 5
ang$moccu[ang$moccu == "Cleaner(Municipal Office)"] = 5
ang$moccu[ang$moccu == "Cleaning Dept. City Council"] = 5
ang$moccu[ang$moccu == "Cleansing Branch Council"] = 5
ang$moccu[ang$moccu == "Cleansing Dept. Divisional Council"] = 5
ang$moccu[ang$moccu == "Clearing Agent"] = 5
ang$moccu[ang$moccu == "Clergyman"] = 1
ang$moccu[ang$moccu == "Clerical"] = 3
ang$moccu[ang$moccu == "Clerical Assistant"] = 3
ang$moccu[ang$moccu == "Clerical Salesman"] = 3
ang$moccu[ang$moccu == "Clerk"] = 3
ang$moccu[ang$moccu == "Clerk "] = 3
ang$moccu[ang$moccu == "Clerk (Agricultural Dep.)"] = 3
ang$moccu[ang$moccu == "Clerk (City Council)"] = 3
ang$moccu[ang$moccu == "Clerk (City Hall)"] = 3
ang$moccu[ang$moccu == "Clerk (Commercial)"] = 3
ang$moccu[ang$moccu == "Clerk (Hospital Board)"] = 3
ang$moccu[ang$moccu == "Clerk (Insurance)"] = 3
ang$moccu[ang$moccu == "Clerk (On Active Seaarch)"] = 3
ang$moccu[ang$moccu == "Clerk (On Active Service)"] = 3
ang$moccu[ang$moccu == "Clerk (Signalman S.A.N.Forces)"] = 3
ang$moccu[ang$moccu == "Clerk + Distiller"] = 3
ang$moccu[ang$moccu == "Clerk + Soldier"] = 3
ang$moccu[ang$moccu == "Clerk Bank of Africa"] = 3
ang$moccu[ang$moccu == "Clerk Barclays Bank"] = 3
ang$moccu[ang$moccu == "Clerk C.G.R."] = 3
ang$moccu[ang$moccu == "Clerk Cape City Council"] = 3
ang$moccu[ang$moccu == "Clerk Cape Town Municipality"] = 3
ang$moccu[ang$moccu == "Clerk City Council"] = 3
ang$moccu[ang$moccu == "Clerk City of Cape Town"] = 3
ang$moccu[ang$moccu == "Clerk Civil Service"] = 3
ang$moccu[ang$moccu == "Clerk Electricity Dept."] = 3
ang$moccu[ang$moccu == "Clerk Forest Dept."] = 3
ang$moccu[ang$moccu == "Clerk G.P.O."] = 3
ang$moccu[ang$moccu == "Clerk General Store"] = 3
ang$moccu[ang$moccu == "Clerk Groote Schuur Hospital"] = 3
ang$moccu[ang$moccu == "Clerk H.M. Customs"] = 3
ang$moccu[ang$moccu == "Clerk Harbour"] = 3
ang$moccu[ang$moccu == "Clerk in Admiralty"] = 3
ang$moccu[ang$moccu == "Clerk in Bank"] = 3
ang$moccu[ang$moccu == "Clerk in City Corporation"] = 3
ang$moccu[ang$moccu == "Clerk in Civil Service"] = 3
ang$moccu[ang$moccu == "Clerk in Commercial Business"] = 3
ang$moccu[ang$moccu == "Clerk in Commercial Store"] = 3
ang$moccu[ang$moccu == "Clerk in G.P.O."] = 3
ang$moccu[ang$moccu == "Clerk in Gov. Service"] = 3
ang$moccu[ang$moccu == "Clerk in Harbour Dept."] = 3
ang$moccu[ang$moccu == "Clerk in Holy Order"] = 3
ang$moccu[ang$moccu == "Clerk in Holy Orders"] = 3
ang$moccu[ang$moccu == "Clerk in Holy Orders "] = 3
ang$moccu[ang$moccu == "Clerk in Market"] = 3
ang$moccu[ang$moccu == "Clerk in Post Office"] = 3
ang$moccu[ang$moccu == "Clerk in Retail Store"] = 3
ang$moccu[ang$moccu == "Clerk in S.A. Mutual"] = 3
ang$moccu[ang$moccu == "Clerk in Shipping Office"] = 3
ang$moccu[ang$moccu == "Clerk in Standard Bank"] = 3
ang$moccu[ang$moccu == "Clerk in Store"] = 3
ang$moccu[ang$moccu == "Clerk in Trust Company"] = 3
ang$moccu[ang$moccu == "Clerk in Union Castle Corp."] = 3
ang$moccu[ang$moccu == "Clerk in Wholesale Firm"] = 3
ang$moccu[ang$moccu == "Clerk Insurance Company"] = 3
ang$moccu[ang$moccu == "Clerk National Bank"] = 3
ang$moccu[ang$moccu == "Clerk of the Papers, House of Assembly"] = 3
ang$moccu[ang$moccu == "Clerk of Works"] = 3
ang$moccu[ang$moccu == "Clerk on Railway"] = 3
ang$moccu[ang$moccu == "Clerk Post Office"] = 3
ang$moccu[ang$moccu == "Clerk R.A.F."] = 3
ang$moccu[ang$moccu == "Clerk S.A.R."] = 3
ang$moccu[ang$moccu == "Clerk S.A.R. "] = 3
ang$moccu[ang$moccu == "Clerk S.A.R. (On Active Service)"] = 3
ang$moccu[ang$moccu == "Clerk S.A.R. Publicity Bureau"] = 3
ang$moccu[ang$moccu == "Clerk S.A.R.+H."] = 3
ang$moccu[ang$moccu == "Clerk S.A.R.+H. Port Goods Dept."] = 3
ang$moccu[ang$moccu == "Clerk Shell Co."] = 3
ang$moccu[ang$moccu == "Clerk Standard Bank"] = 3
ang$moccu[ang$moccu == "Clerk Telegraph Co."] = 3
ang$moccu[ang$moccu == "Clerk Temporary Sergt. U.D.F."] = 3
ang$moccu[ang$moccu == "Clerk to District Council"] = 3
ang$moccu[ang$moccu == "Clerk to Magistrate"] = 3
ang$moccu[ang$moccu == "Clerk Tobacco Co."] = 3
ang$moccu[ang$moccu == "Clerk Transportation S.A.R.+H."] = 3
ang$moccu[ang$moccu == "Clerk Treasury"] = 3
ang$moccu[ang$moccu == "Clerk Union Castle Co."] = 3
ang$moccu[ang$moccu == "Clerk United Building Society"] = 3
ang$moccu[ang$moccu == "Clerk United Tobacco Co."] = 3
ang$moccu[ang$moccu == "Clerk Vacuum Oil Co."] = 3
ang$moccu[ang$moccu == "Clerk(Commercial)"] = 3
ang$moccu[ang$moccu == "Clerk(Union Defence Force)"] = 3
ang$moccu[ang$moccu == "Clerk, City Electricity Dept."] = 3
ang$moccu[ang$moccu == "Clerk, Civil Service"] = 3
ang$moccu[ang$moccu == "Clerk, Estate Office"] = 3
ang$moccu[ang$moccu == "Clerk, Municipality"] = 3
ang$moccu[ang$moccu == "Clerk, Shell Oil Co."] = 3
ang$moccu[ang$moccu == "Clerk, Stock-keeper"] = 3
ang$moccu[ang$moccu == "Clerl"] = 3
ang$moccu[ang$moccu == "Clicker"] = 3
ang$moccu[ang$moccu == "Clicker (Shoe Factory)"] = 3
ang$moccu[ang$moccu == "Clicker Leather Industry"] = 3
ang$moccu[ang$moccu == "Clicker Shoe Trade"] = 3
ang$moccu[ang$moccu == "Clicker(shoe trade)"] = 3
ang$moccu[ang$moccu == "Clinic assistant"] = 0
ang$moccu[ang$moccu == "Cloth Examiner"] = 7
ang$moccu[ang$moccu == "Cloth Weaver"] = 7
ang$moccu[ang$moccu == "Clothier"] = 7
ang$moccu[ang$moccu == "Clothing Cutter"] = 7
ang$moccu[ang$moccu == "Clothing Factory hand"] = 7
ang$moccu[ang$moccu == "Clothing Factory Worker"] = 7
ang$moccu[ang$moccu == "Clothing Presser"] = 7
ang$moccu[ang$moccu == "Club Manager"] = 2
ang$moccu[ang$moccu == "Club Secretary"] = 2
ang$moccu[ang$moccu == "Coach builder"] = 8
ang$moccu[ang$moccu == "Coach Builder"] = 8
ang$moccu[ang$moccu == "Coach builder S.A.R."] = 8
ang$moccu[ang$moccu == "Coach painter"] = 9
ang$moccu[ang$moccu == "Coach Painter S.A.R."] = 9
ang$moccu[ang$moccu == "Coach Trimmer"] = 8
ang$moccu[ang$moccu == "Coachbuilder"] = 8
ang$moccu[ang$moccu == "Coach-builder"] = 8
ang$moccu[ang$moccu == "Coachbuilder "] = 8
ang$moccu[ang$moccu == "Coachbuilder S.A.R."] = 8
ang$moccu[ang$moccu == "Coach-builder S.A.R."] = 8
ang$moccu[ang$moccu == "Coachman"] = 9
ang$moccu[ang$moccu == "Coachman High Constantia"] = 9
ang$moccu[ang$moccu == "Coach-painter"] = 9
ang$moccu[ang$moccu == "Coal trimmer"] = 8
ang$moccu[ang$moccu == "Coastman"] = NA
ang$moccu[ang$moccu == "Coat Presser"] = 7
ang$moccu[ang$moccu == "Co-Director"] = 2
ang$moccu[ang$moccu == "Coffee Grinder"] = 7
ang$moccu[ang$moccu == "Coffee Produce Grower"] = 6
ang$moccu[ang$moccu == "Coffin Trimmer"] = 8
ang$moccu[ang$moccu == "Coffin-maker"] = 8
ang$moccu[ang$moccu == "Coffin-trimmer"] = 8
ang$moccu[ang$moccu == "Coiffeur"] = 5
ang$moccu[ang$moccu == "Coil-winder"] = 8
ang$moccu[ang$moccu == "Cold Storage Charge-hand"] = 9
ang$moccu[ang$moccu == "Cold Storage worker"] = 9
ang$moccu[ang$moccu == "Collector"] = 9
ang$moccu[ang$moccu == "Collector Mineral Water Factory"] = 9
ang$moccu[ang$moccu == "Collector of Customs"] = 3
ang$moccu[ang$moccu == "Colonel"] = 5
ang$moccu[ang$moccu == "Colonel Defence Force"] = 5
ang$moccu[ang$moccu == "Colonial Police Officer"] = 5
ang$moccu[ang$moccu == "Colonial Survey Geologist"] = 0
ang$moccu[ang$moccu == "Color Sergeant General Staff"] = 5
ang$moccu[ang$moccu == "Commander"] = 5
ang$moccu[ang$moccu == "Commander R.N."] = 5
ang$moccu[ang$moccu == "Commerce"] = NA
ang$moccu[ang$moccu == "Commercial"] = NA
ang$moccu[ang$moccu == "Commercial Accountant"] = 1
ang$moccu[ang$moccu == "Commercial Agent"] = 4
ang$moccu[ang$moccu == "Commercial Artist"] = 1
ang$moccu[ang$moccu == "Commercial Canvasser"] = 4
ang$moccu[ang$moccu == "Commercial Clerk"] = 3
ang$moccu[ang$moccu == "Commercial Clerk (On Active Service)"] = 3
ang$moccu[ang$moccu == "Commercial Clerk S.A.R."] = 3
ang$moccu[ang$moccu == "Commercial Motor Driver"] = 9
ang$moccu[ang$moccu == "Commercial Motor-Driver"] = 9
ang$moccu[ang$moccu == "Commercial Reporter"] = 1
ang$moccu[ang$moccu == "Commercial Representative"] = 4
ang$moccu[ang$moccu == "Commercial Salesman"] = 4
ang$moccu[ang$moccu == "Commercial Secretary"] = 3
ang$moccu[ang$moccu == "Commercial Traveller"] = 4
ang$moccu[ang$moccu == "Commercial Traveller (On Active Service)"] = 4
ang$moccu[ang$moccu == "Commercial Travellers Driver"] = 9
ang$moccu[ang$moccu == "Commission Agent"] = 4
ang$moccu[ang$moccu == "Commissioned Officer S.A.D.F."] = 5
ang$moccu[ang$moccu == "Commissioned Officer U.D.F."] = 5
ang$moccu[ang$moccu == "Communication Engineer"] = 0
ang$moccu[ang$moccu == "Communications Electrician"] = 8
ang$moccu[ang$moccu == "Company Director"] = 2
ang$moccu[ang$moccu == "Company Engineer"] = 0
ang$moccu[ang$moccu == "Company Executive"] = 2
ang$moccu[ang$moccu == "Company Manager"] = 2
ang$moccu[ang$moccu == "Company Representative"] = 4
ang$moccu[ang$moccu == "Company secretary"] = 3
ang$moccu[ang$moccu == "Company Secretary"] = 3
ang$moccu[ang$moccu == "Company Secretarys Assistant"] = 3
ang$moccu[ang$moccu == "Compo Mixer"] = 6
ang$moccu[ang$moccu == "Compositor"] = 6
ang$moccu[ang$moccu == "Compound Manager"] = 2
ang$moccu[ang$moccu == "Computer"] = 3
ang$moccu[ang$moccu == "Computer Programmer"] = 0
ang$moccu[ang$moccu == "Computer Supervisor"] = 2
ang$moccu[ang$moccu == "Computer Systems Analyst"] = 0
ang$moccu[ang$moccu == "Computer Technician"] = 8
ang$moccu[ang$moccu == "Computer(Royal Observatory)"] = 3
ang$moccu[ang$moccu == "Conductor"] = 3
ang$moccu[ang$moccu == "Conductor City Tramway Co."] = 3
ang$moccu[ang$moccu == "Conductor Tramway"] = 3
ang$moccu[ang$moccu == "Conductor Tramways"] = 3
ang$moccu[ang$moccu == "Conductor, City Tramways"] = 3
ang$moccu[ang$moccu == "Confectioner"] = 7
ang$moccu[ang$moccu == "Confidential Clerk Standard Bank"] = 3
ang$moccu[ang$moccu == "Conservation Officer"] = 6
ang$moccu[ang$moccu == "Constable"] = 5
ang$moccu[ang$moccu == "Constable (Volksrust)"] = 5
ang$moccu[ang$moccu == "Constable at Convict Station"] = 5
ang$moccu[ang$moccu == "Constable at the Convict Station"] = 5
ang$moccu[ang$moccu == "Constable Breakwater Convict Station"] = 5
ang$moccu[ang$moccu == "Constable Convict Station"] = 5
ang$moccu[ang$moccu == "Constable Mounted Police"] = 5
ang$moccu[ang$moccu == "Constable S.A. Police"] = 5
ang$moccu[ang$moccu == "Constable S.A.P."] = 5
ang$moccu[ang$moccu == "Constable S.A.R."] = 5
ang$moccu[ang$moccu == "Construction Works"] = 9
ang$moccu[ang$moccu == "Consulting Engineer"] = 0
ang$moccu[ang$moccu == "Contractor"] = 2
ang$moccu[ang$moccu == "Contractor On Active Service"] = 2
ang$moccu[ang$moccu == "Contractor-hand"] = 9
ang$moccu[ang$moccu == "Contractors foreman"] = 2
ang$moccu[ang$moccu == "Contracts Controller"] = 2
ang$moccu[ang$moccu == "Conveyancer"] = 1
ang$moccu[ang$moccu == "Conveyancing Clerk"] = 3
ang$moccu[ang$moccu == "Convict Guard"] = 5
ang$moccu[ang$moccu == "Convict guard"] = 5
ang$moccu[ang$moccu == "Cook"] = 5
ang$moccu[ang$moccu == "Cook + Steward"] = 5
ang$moccu[ang$moccu == "Cook and Butcher R.A.F."] = 5
ang$moccu[ang$moccu == "Cook for Divisional Council"] = 5
ang$moccu[ang$moccu == "Cook in Domestic service"] = 5
ang$moccu[ang$moccu == "Cook-General"] = 5
ang$moccu[ang$moccu == "Cooking Clerk S.A.R."] = 3
ang$moccu[ang$moccu == "Cooks mate on train"] = 3
ang$moccu[ang$moccu == "Cooldrink Mixer"] = 5
ang$moccu[ang$moccu == "Cooper"] = 8
ang$moccu[ang$moccu == "Cooperage Manager"] = 2
ang$moccu[ang$moccu == "Cooperation Worker"] = 9
ang$moccu[ang$moccu == "Copper plate Printer in Cape Times"] = 9
ang$moccu[ang$moccu == "Coppersmith"] = 8
ang$moccu[ang$moccu == "Coppersmith S.A.R."] = 8
ang$moccu[ang$moccu == "Copy Writer"] = 1
ang$moccu[ang$moccu == "Copy-holder (Printer)"] = 9
ang$moccu[ang$moccu == "Cordwainer"] = 8
ang$moccu[ang$moccu == "Core maker"] = 9
ang$moccu[ang$moccu == "Cork manufacturer"] = 9
ang$moccu[ang$moccu == "Corker(Shoe factory)"] = 8
ang$moccu[ang$moccu == "Corn-grinder"] = 6
ang$moccu[ang$moccu == "Corporal"] = 5
ang$moccu[ang$moccu == "Corporal 24th Reg."] = 5
ang$moccu[ang$moccu == "Corporal 2nd Battalion Rifle Brigade"] = 5
ang$moccu[ang$moccu == "Corporal 86th Regiment"] = 5
ang$moccu[ang$moccu == "Corporal Air Force"] = 5
ang$moccu[ang$moccu == "Corporal C.P.R."] = 5
ang$moccu[ang$moccu == "Corporal Cape Corps"] = 5
ang$moccu[ang$moccu == "Corporal Fitter Royal Air Force"] = 5
ang$moccu[ang$moccu == "Corporal General Service Corps"] = 5
ang$moccu[ang$moccu == "Corporal H.M. Royal Marines"] = 5
ang$moccu[ang$moccu == "Corporal R.A.F."] = 5
ang$moccu[ang$moccu == "Corporal R.A.F. On Active Service"] = 5
ang$moccu[ang$moccu == "Corporal Royal Air Force"] = 5
ang$moccu[ang$moccu == "Corporal Royal Artillery"] = 5
ang$moccu[ang$moccu == "Corporal Royal Engineers"] = 5
ang$moccu[ang$moccu == "Corporal S. Rhodesian Staff Corps"] = 5
ang$moccu[ang$moccu == "Corporal S.A. Cape Corps"] = 5
ang$moccu[ang$moccu == "Corporal S.A. Defence Force"] = 5
ang$moccu[ang$moccu == "Corporal S.A.A.E."] = 5
ang$moccu[ang$moccu == "Corporal S.A.A.F."] = 5
ang$moccu[ang$moccu == "Corporal S.A.E.C."] = 5
ang$moccu[ang$moccu == "Corporal S.A.M.R."] = 5
ang$moccu[ang$moccu == "Corporal S.A.Q.S.C."] = 5
ang$moccu[ang$moccu == "Corporal S.A.S.C."] = 5
ang$moccu[ang$moccu == "Corporal Union Defence Force"] = 5
ang$moccu[ang$moccu == "Corporal Water Police"] = 5
ang$moccu[ang$moccu == "Corporal, Fitter Air France"] = 5
ang$moccu[ang$moccu == "Corporal, Kings Own Yorkshire Infantry"] = 5
ang$moccu[ang$moccu == "Corporal, R.A.F. Southern Rhodesia"] = 5
ang$moccu[ang$moccu == "Corporation"] = NA
ang$moccu[ang$moccu == "Corporation drainage  labourer"] = 9
ang$moccu[ang$moccu == "Corporation Driver"] = 9
ang$moccu[ang$moccu == "Corporation Employee"] = 9
ang$moccu[ang$moccu == "Corporation Labourer"] = 9
ang$moccu[ang$moccu == "Corporation labourer"] = 9
ang$moccu[ang$moccu == "Corporation Market Porter"] = 9
ang$moccu[ang$moccu == "Corporation Market-Porter"] = 9
ang$moccu[ang$moccu == "Corporation work"] = 9
ang$moccu[ang$moccu == "Corporation Worker"] = 9
ang$moccu[ang$moccu == "Corporation worker"] = 9
ang$moccu[ang$moccu == "Correspondence Clerk"] = 3
ang$moccu[ang$moccu == "Cost Accountant"] = 1
ang$moccu[ang$moccu == "Cost Clerk"] = 3
ang$moccu[ang$moccu == "Costing Clerk"] = 3
ang$moccu[ang$moccu == "Cottage Caretaker"] = 5
ang$moccu[ang$moccu == "Council Cleansing Department"] = 5
ang$moccu[ang$moccu == "Council Employee"] = 9
ang$moccu[ang$moccu == "Council Inspectors Assistant"] = 2
ang$moccu[ang$moccu == "Council labourer"] = 9
ang$moccu[ang$moccu == "Council Labourer"] = 9
ang$moccu[ang$moccu == "Counter assistant"] = 4
ang$moccu[ang$moccu == "Counter-hand"] = 4
ang$moccu[ang$moccu == "Counter-maker"] = 7
ang$moccu[ang$moccu == "Cow forage-hand"] = 6
ang$moccu[ang$moccu == "Cowherd"] = 6
ang$moccu[ang$moccu == "Cpl. RAF(Pretoria)"] = 5
ang$moccu[ang$moccu == "Crane Driver"] = 9
ang$moccu[ang$moccu == "Crane Driver S.A.R."] = 9
ang$moccu[ang$moccu == "Crane Driver S.A.R.+H."] = 9
ang$moccu[ang$moccu == "Crane Operator"] = 9
ang$moccu[ang$moccu == "Cranedriver"] = 9
ang$moccu[ang$moccu == "Crane-driver"] = 9
ang$moccu[ang$moccu == "Credit Clerk"] = 3
ang$moccu[ang$moccu == "Credit Manager"] = 2
ang$moccu[ang$moccu == "Culler"] = 7
ang$moccu[ang$moccu == "Currier"] = 7
ang$moccu[ang$moccu == "Curriers Assistant"] = 7
ang$moccu[ang$moccu == "Curtain Hanger"] = 7
ang$moccu[ang$moccu == "Curtain-cutter"] = 7
ang$moccu[ang$moccu == "Custodian of City Hall"] = 5
ang$moccu[ang$moccu == "Custom-licence Officer"] = 3
ang$moccu[ang$moccu == "Customs"] = 3
ang$moccu[ang$moccu == "Customs and Excise"] = 3
ang$moccu[ang$moccu == "Customs Clerk"] = 3
ang$moccu[ang$moccu == "Customs messenger"] = 3
ang$moccu[ang$moccu == "Customs Officer"] = 2
ang$moccu[ang$moccu == "Customs Official"] = 2
ang$moccu[ang$moccu == "Customs sorter"] = 3
ang$moccu[ang$moccu == "Cutter"] = 7
ang$moccu[ang$moccu == "Cutter Cloting Industry"] = 7
ang$moccu[ang$moccu == "Cutter in Shirt Factory"] = 7
ang$moccu[ang$moccu == "Cutter Tobacco factory"] = 7
ang$moccu[ang$moccu == "Cutters Assistant"] = 7
ang$moccu[ang$moccu == "Cyanide worker"] = 7
ang$moccu[ang$moccu == "Cycle Assembler + Packer"] = 9
ang$moccu[ang$moccu == "Cycle Constructor"] = 8
ang$moccu[ang$moccu == "Cycle Dealer"] = 4
ang$moccu[ang$moccu == "Cycle engineer"] = 0
ang$moccu[ang$moccu == "Cycle Examiner"] = 8
ang$moccu[ang$moccu == "Cycle fitter"] = 8
ang$moccu[ang$moccu == "Cycle mechanic"] = 8
ang$moccu[ang$moccu == "Cycle Mechanic"] = 8
ang$moccu[ang$moccu == "Cycle Trade"] = 4
ang$moccu[ang$moccu == "Cylinder fitter"] = 8
ang$moccu[ang$moccu == "Dairy boy"] = 6
ang$moccu[ang$moccu == "Dairy Driver"] = 9
ang$moccu[ang$moccu == "Dairy Farmer"] = 2
ang$moccu[ang$moccu == "Dairy Farming"] = 2
ang$moccu[ang$moccu == "Dairy Foreman"] = 2
ang$moccu[ang$moccu == "Dairy worker"] = 6
ang$moccu[ang$moccu == "Dairyman"] = 6
ang$moccu[ang$moccu == "Dairyman Farmer"] = 6
ang$moccu[ang$moccu == "Dancing Teacher"] = 1
ang$moccu[ang$moccu == "Darkroom Printer"] = 9
ang$moccu[ang$moccu == "Day School Teacher"] = 1
ang$moccu[ang$moccu == "Dealer"] = 4
ang$moccu[ang$moccu == "Debt-collector"] = 3
ang$moccu[ang$moccu == "Deck Hand"] = 9
ang$moccu[ang$moccu == "Deckhand"] = 9
ang$moccu[ang$moccu == "Deck-hand S.A.R.+H."] = 9
ang$moccu[ang$moccu == "Deck-Officer Merchant Navy"] = 5
ang$moccu[ang$moccu == "Decorator"] = 1
ang$moccu[ang$moccu == "Defence Force"] = 5
ang$moccu[ang$moccu == "Delivery boy"] = 9
ang$moccu[ang$moccu == "Delivery Boy"] = 9
ang$moccu[ang$moccu == "Delivery boy "] = 9
ang$moccu[ang$moccu == "Delivery Boy for Chemist"] = 9
ang$moccu[ang$moccu == "Delivery Clerk"] = 3
ang$moccu[ang$moccu == "Delivery driver"] = 9
ang$moccu[ang$moccu == "Delivery Guard"] = 5
ang$moccu[ang$moccu == "Delivery man"] = 9
ang$moccu[ang$moccu == "Delivery Messenger"] = 3
ang$moccu[ang$moccu == "Delivery-boy"] = 9
ang$moccu[ang$moccu == "Delivery-boy in Bazaar"] = 9
ang$moccu[ang$moccu == "Deliveryman"] = 9
ang$moccu[ang$moccu == "Delivery-man"] = 9
ang$moccu[ang$moccu == "Deliveryman in Grocers Shop"] = 9
ang$moccu[ang$moccu == "Deliveryman Timber Merchant"] = 9
ang$moccu[ang$moccu == "Dental mechanic"] = 0
ang$moccu[ang$moccu == "Dental Mechanic"] = 0
ang$moccu[ang$moccu == "Dental Surgeon"] = 0
ang$moccu[ang$moccu == "Dentist"] = 0
ang$moccu[ang$moccu == "Dentist Assistant"] = 0
ang$moccu[ang$moccu == "Departmental Manager"] = 2
ang$moccu[ang$moccu == "Departmental Manager Tobacco Co."] = 2
ang$moccu[ang$moccu == "Departmental Manager, Castle, Wine & Brandy Co."] = 2
ang$moccu[ang$moccu == "Depot Manager"] = 2
ang$moccu[ang$moccu == "Design Engineer"] = 0
ang$moccu[ang$moccu == "Designer"] = 1
ang$moccu[ang$moccu == "Designer Draughtsman"] = 0
ang$moccu[ang$moccu == "Despatch Clerk"] = 3
ang$moccu[ang$moccu == "Despatch clerk"] = 3
ang$moccu[ang$moccu == "Despatch Clerk S.A.R."] = 3
ang$moccu[ang$moccu == "Despatch Clerk Soap Factory"] = 3
ang$moccu[ang$moccu == "Despatch Clerk(On Active Service)"] = 3
ang$moccu[ang$moccu == "Despatch Packer"] = 9
ang$moccu[ang$moccu == "Despatch worker"] = 9
ang$moccu[ang$moccu == "Despatcher"] = 9
ang$moccu[ang$moccu == "Detective"] = 5
ang$moccu[ang$moccu == "Detective Constable"] = 5
ang$moccu[ang$moccu == "Detective Constable S.A.P."] = 5
ang$moccu[ang$moccu == "Detective Department"] = 5
ang$moccu[ang$moccu == "Detective Officer"] = 5
ang$moccu[ang$moccu == "Detective S.A. Police"] = 5
ang$moccu[ang$moccu == "Detective Sergeant"] = 5
ang$moccu[ang$moccu == "Development Representative"] = 4
ang$moccu[ang$moccu == "Diamond Buyer"] = 4
ang$moccu[ang$moccu == "Diamond Cutter"] = 8
ang$moccu[ang$moccu == "Diamond Cutter (On Active Service)"] = 8
ang$moccu[ang$moccu == "Diamond Expert"] = 8
ang$moccu[ang$moccu == "Diamond Polisher"] = 8
ang$moccu[ang$moccu == "Diamond-classifier"] = 8
ang$moccu[ang$moccu == "Die-maker"] = NA
ang$moccu[ang$moccu == "Diesel Engineer"] = 0
ang$moccu[ang$moccu == "Diesel Fitter"] = 8
ang$moccu[ang$moccu == "Diesel Fitter S.A.N."] = 8
ang$moccu[ang$moccu == "Diesel Mechanic"] = 8
ang$moccu[ang$moccu == "Diesel mechanic"] = 8
ang$moccu[ang$moccu == "Die-stamper"] = NA
ang$moccu[ang$moccu == "Diplomatic Service"] = 2
ang$moccu[ang$moccu == "Diplomatic Service (S.A.)"] = 2
ang$moccu[ang$moccu == "Director"] = 2
ang$moccu[ang$moccu == "Director Engineer"] = 0
ang$moccu[ang$moccu == "Director of Brick Company"] = 2
ang$moccu[ang$moccu == "Director of Companies"] = 2
ang$moccu[ang$moccu == "Director of Company"] = 2
ang$moccu[ang$moccu == "Director of Leather Industries Research Institute"] = 2
ang$moccu[ang$moccu == "Dispatcher"] = 9
ang$moccu[ang$moccu == "Dispatcher in Factory"] = 9
ang$moccu[ang$moccu == "Dispenser"] = 9
ang$moccu[ang$moccu == "Dispensers assistant"] = 9
ang$moccu[ang$moccu == "Display Artist"] = 1
ang$moccu[ang$moccu == "Display Man"] = 1
ang$moccu[ang$moccu == "Display Manager"] = 2
ang$moccu[ang$moccu == "Distiller"] = 7
ang$moccu[ang$moccu == "Distribution Manager"] = 2
ang$moccu[ang$moccu == "District Foreman"] = 2
ang$moccu[ang$moccu == "District Foreman City Council"] = 2
ang$moccu[ang$moccu == "District Forest Officer"] = 2
ang$moccu[ang$moccu == "District Manager, Insurance Company"] = 2
ang$moccu[ang$moccu == "District Officer"] = 2
ang$moccu[ang$moccu == "District Representative P.W.D."] = 3
ang$moccu[ang$moccu == "District-Manager Mutual Life Assurance Society"] = 2
ang$moccu[ang$moccu == "Diver"] = 9
ang$moccu[ang$moccu == "Divisional Council"] = NA
ang$moccu[ang$moccu == "Divisional Council Forestry Employee"] = 6
ang$moccu[ang$moccu == "Divisional Council Labourer"] = 9
ang$moccu[ang$moccu == "Dock Agent"] = NA
ang$moccu[ang$moccu == "Dock Foreman"] = 2
ang$moccu[ang$moccu == "Dock labourer"] = 9
ang$moccu[ang$moccu == "Dock Labourer"] = 9
ang$moccu[ang$moccu == "Dock Labourer S.A.R."] = 9
ang$moccu[ang$moccu == "Dock labourer S.A.R.+H."] = 9
ang$moccu[ang$moccu == "Dock Official"] = 3
ang$moccu[ang$moccu == "Dock Police"] = 5
ang$moccu[ang$moccu == "Dock worker"] = 9
ang$moccu[ang$moccu == "Dock yard Policeman"] = 5
ang$moccu[ang$moccu == "Dock-hand"] = 9
ang$moccu[ang$moccu == "Dockman"] = 9
ang$moccu[ang$moccu == "Docks Foreman"] = 2
ang$moccu[ang$moccu == "Docks labourer"] = 9
ang$moccu[ang$moccu == "Docks porter"] = 9
ang$moccu[ang$moccu == "Dock-worker"] = 9
ang$moccu[ang$moccu == "Dockyard Assistant"] = 9
ang$moccu[ang$moccu == "Dockyard Labourer"] = 9
ang$moccu[ang$moccu == "Dockyard labourer"] = 9
ang$moccu[ang$moccu == "Dockyard worker"] = 9
ang$moccu[ang$moccu == "Doctor"] = 0
ang$moccu[ang$moccu == "Doctor of Medicine"] = 0
ang$moccu[ang$moccu == "Doctors assistant"] = 0
ang$moccu[ang$moccu == "Doctors Attendant"] = 0
ang$moccu[ang$moccu == "Domestic Appliance Mechanic"] = 8
ang$moccu[ang$moccu == "Domestic serva"] = 5
ang$moccu[ang$moccu == "Domestic servant"] = 5
ang$moccu[ang$moccu == "Domestic service"] = 5
ang$moccu[ang$moccu == "Domestic worker"] = 5
ang$moccu[ang$moccu == "Door-keeper G.P.O."] = 5
ang$moccu[ang$moccu == "Drafting Designer"] = 1
ang$moccu[ang$moccu == "Draftsman"] = 0
ang$moccu[ang$moccu == "Drain layer"] = 9
ang$moccu[ang$moccu == "Drainage Contractor"] = 9
ang$moccu[ang$moccu == "Drainage Foreman"] = 2
ang$moccu[ang$moccu == "Drainage labourer"] = 9
ang$moccu[ang$moccu == "Drainlayer"] = 9
ang$moccu[ang$moccu == "Draper"] = 4
ang$moccu[ang$moccu == "Draper assistant"] = 4
ang$moccu[ang$moccu == "Drapers assistant"] = 4
ang$moccu[ang$moccu == "Drapers Assistant"] = 4
ang$moccu[ang$moccu == "Draughtsman"] = 0
ang$moccu[ang$moccu == "Draughtsman Civil Service"] = 0
ang$moccu[ang$moccu == "Draughtsman in Civil Service"] = 0
ang$moccu[ang$moccu == "Draughtsman S.A.R."] = 0
ang$moccu[ang$moccu == "Dredger fireman"] = 9
ang$moccu[ang$moccu == "Dresser"] = 5
ang$moccu[ang$moccu == "Dressmaker"] = 7
ang$moccu[ang$moccu == "Dried Fruit Preserving"] = 7
ang$moccu[ang$moccu == "Drill Instructor Defence Force"] = 1
ang$moccu[ang$moccu == "Driller"] = 9
ang$moccu[ang$moccu == "Driver"] = 9
ang$moccu[ang$moccu == "Driver (Groom)"] = 9
ang$moccu[ang$moccu == "Driver and Signwriter for Undertaker"] = 9
ang$moccu[ang$moccu == "Driver Corporal"] = 9
ang$moccu[ang$moccu == "Driver for City Council"] = 9
ang$moccu[ang$moccu == "Driver Funeral Parlour"] = 9
ang$moccu[ang$moccu == "Driver G.P.O."] = 9
ang$moccu[ang$moccu == "Driver Milk Cart"] = 9
ang$moccu[ang$moccu == "Driver of Baking delivery van"] = 9
ang$moccu[ang$moccu == "Driver of Cart"] = 9
ang$moccu[ang$moccu == "Driver of Horse vehicle"] = 9
ang$moccu[ang$moccu == "Driver On Active Service"] = 9
ang$moccu[ang$moccu == "Driver R.M.T."] = 9
ang$moccu[ang$moccu == "Driver S.A.R."] = 9
ang$moccu[ang$moccu == "Driver Salesman"] = 4
ang$moccu[ang$moccu == "Driver Tramway Co."] = 9
ang$moccu[ang$moccu == "Driver Vacuum Oil Co."] = 9
ang$moccu[ang$moccu == "DriverSalesman"] = 4
ang$moccu[ang$moccu == "Driver-Mechanic"] = 9
ang$moccu[ang$moccu == "Driver-Messenger"] = 9
ang$moccu[ang$moccu == "Drivers Assistant"] = 9
ang$moccu[ang$moccu == "Druggist"] = 0
ang$moccu[ang$moccu == "Drum Major 11th Regiment"] = NA
ang$moccu[ang$moccu == "Dry Cleaner"] = 5
ang$moccu[ang$moccu == "Drycleaner"] = 5
ang$moccu[ang$moccu == "Drycleaners Agent"] = 5
ang$moccu[ang$moccu == "Dryer - Knitting Mill"] = 9
ang$moccu[ang$moccu == "Drying Operator"] = 7
ang$moccu[ang$moccu == "Duco Operator"] = 9
ang$moccu[ang$moccu == "Duco Polisher"] = 8
ang$moccu[ang$moccu == "Duco Sprayer"] = 9
ang$moccu[ang$moccu == "Duco-specialist"] = 8
ang$moccu[ang$moccu == "Duco-sprayer"] = 9
ang$moccu[ang$moccu == "Duplicator"] = 9
ang$moccu[ang$moccu == "Duplicator Operator"] = 9
ang$moccu[ang$moccu == "Dus Driver"] = 9
ang$moccu[ang$moccu == "Dustman"] = 9
ang$moccu[ang$moccu == "Dyer"] = 7
ang$moccu[ang$moccu == "Dyer + Cleaner"] = 7
ang$moccu[ang$moccu == "Dyers assistant"] = 7
ang$moccu[ang$moccu == "Dynamite mixer"] = 8
ang$moccu[ang$moccu == "Dynamite Pricker"] = 8
ang$moccu[ang$moccu == "Eastern Telegraph Co."] = 9
ang$moccu[ang$moccu == "Eastern Telegraph Company"] = 9
ang$moccu[ang$moccu == "Eastern Telegraph Company Service"] = 9
ang$moccu[ang$moccu == "Eating-house keeper"] = 5
ang$moccu[ang$moccu == "Economist"] = 0
ang$moccu[ang$moccu == "Editor"] = 1
ang$moccu[ang$moccu == "Education Dept., Tanganyika"] = 1
ang$moccu[ang$moccu == "Education Officer U.D.F."] = 1
ang$moccu[ang$moccu == "Educational"] = 1
ang$moccu[ang$moccu == "Egg Examiner"] = 7
ang$moccu[ang$moccu == "Electric bus Inspector"] = 2
ang$moccu[ang$moccu == "Electric Department"] = 8
ang$moccu[ang$moccu == "Electric Engineer"] = 0
ang$moccu[ang$moccu == "Electric Light Wireman"] = 8
ang$moccu[ang$moccu == "Electric mechanic"] = 8
ang$moccu[ang$moccu == "Electric Operator"] = 8
ang$moccu[ang$moccu == "Electric Power Station"] = 8
ang$moccu[ang$moccu == "Electric Van Attendant"] = 9
ang$moccu[ang$moccu == "Electric welder"] = 8
ang$moccu[ang$moccu == "Electric welder S.A.R."] = 8
ang$moccu[ang$moccu == "Electric Wireman"] = 8
ang$moccu[ang$moccu == "Electric Wireman(C.T. Municipality)"] = 8
ang$moccu[ang$moccu == "Electrical + Mechanical Engineer"] = 0
ang$moccu[ang$moccu == "Electrical Artificer"] = 8
ang$moccu[ang$moccu == "Electrical Artificer H.M. Navy"] = 8
ang$moccu[ang$moccu == "Electrical Contractor"] = NA
ang$moccu[ang$moccu == "Electrical Engineer"] = 0
ang$moccu[ang$moccu == "Electrical Engineer Retired"] = 0
ang$moccu[ang$moccu == "Electrical Engineers assistant"] = 0
ang$moccu[ang$moccu == "Electrical Fitter"] = 8
ang$moccu[ang$moccu == "Electrical Handyman"] = 9
ang$moccu[ang$moccu == "Electrical Inspector"] = 2
ang$moccu[ang$moccu == "Electrical labourer"] = 8
ang$moccu[ang$moccu == "Electrical Labourer"] = 8
ang$moccu[ang$moccu == "Electrical Mechanic"] = 8
ang$moccu[ang$moccu == "Electrical Wireman"] = 8
ang$moccu[ang$moccu == "Electrical Worker G.P.O."] = 8
ang$moccu[ang$moccu == "Electrician"] = 8
ang$moccu[ang$moccu == "Electrician (Leading Seaman R.N.A.S.)"] = 8
ang$moccu[ang$moccu == "Electrician (Municipality)"] = 8
ang$moccu[ang$moccu == "Electrician (On Active Service)"] = 8
ang$moccu[ang$moccu == "Electrician Apprentice"] = 8
ang$moccu[ang$moccu == "Electrician assistant"] = 8
ang$moccu[ang$moccu == "Electrician G.P.O."] = 8
ang$moccu[ang$moccu == "Electrician in S.A.D.F."] = 8
ang$moccu[ang$moccu == "Electrician Municipal Power Station"] = 8
ang$moccu[ang$moccu == "Electrician Post Office"] = 8
ang$moccu[ang$moccu == "Electrician R.A.F."] = 8
ang$moccu[ang$moccu == "Electrician R.N."] = 8
ang$moccu[ang$moccu == "Electrician Royal Navy"] = 8
ang$moccu[ang$moccu == "Electrician S.A.R."] = 8
ang$moccu[ang$moccu == "Electricians assistant"] = 8
ang$moccu[ang$moccu == "Electricians Assistant"] = 8
ang$moccu[ang$moccu == "Electricians Handyman"] = 8
ang$moccu[ang$moccu == "Electricians labourer"] = 8
ang$moccu[ang$moccu == "Electricians Labourer"] = 8
ang$moccu[ang$moccu == "Electricians labourer S.A.R."] = 8
ang$moccu[ang$moccu == "Electricians workman"] = 8
ang$moccu[ang$moccu == "Electricity Department"] = 8
ang$moccu[ang$moccu == "Electricity Dept. Labourer"] = 8
ang$moccu[ang$moccu == "Electricity Sub-Station Reader"] = 8
ang$moccu[ang$moccu == "Electro-Mechanic"] = 8
ang$moccu[ang$moccu == "Electronic Assembler"] = 8
ang$moccu[ang$moccu == "Electronics Engineer"] = 0
ang$moccu[ang$moccu == "Electro-plater"] = 8
ang$moccu[ang$moccu == "Elevator Attendant"] = 5
ang$moccu[ang$moccu == "Elevator Technician"] = 0
ang$moccu[ang$moccu == "Employed by Undertaker"] = 9
ang$moccu[ang$moccu == "Employed in H.M. Customs"] = 9
ang$moccu[ang$moccu == "Employee at Abattoir"] = 9
ang$moccu[ang$moccu == "Employee at Brewery"] = 9
ang$moccu[ang$moccu == "Employee at Sawmills"] = 9
ang$moccu[ang$moccu == "Employee Caltex Oil Co."] = 9
ang$moccu[ang$moccu == "Employee Early Morning Market Cape Town"] = 9
ang$moccu[ang$moccu == "Employee in Brewery"] = 9
ang$moccu[ang$moccu == "Employee in Hat Trade"] = 9
ang$moccu[ang$moccu == "Employee Maitland Abattoir"] = 9
ang$moccu[ang$moccu == "Employee Match Company"] = 9
ang$moccu[ang$moccu == "Employee of Cape Town City Council"] = 9
ang$moccu[ang$moccu == "Employee of Harbour Board"] = 9
ang$moccu[ang$moccu == "Employee S.A.R."] = 9
ang$moccu[ang$moccu == "Employee Sweet Factory"] = 9
ang$moccu[ang$moccu == "Employer at Docks"] = 9
ang$moccu[ang$moccu == "Employer at Ice Works"] = 9
ang$moccu[ang$moccu == "Employer of City Council"] = 9
ang$moccu[ang$moccu == "Engine cleaner"] = 8
ang$moccu[ang$moccu == "Engine Cleaner"] = 8
ang$moccu[ang$moccu == "Engine driver"] = 9
ang$moccu[ang$moccu == "Engine Driver"] = 9
ang$moccu[ang$moccu == "Engine Driver C.G.R."] = 9
ang$moccu[ang$moccu == "Engine Driver Milling Works"] = 9
ang$moccu[ang$moccu == "Engine Driver S.A.R."] = 9
ang$moccu[ang$moccu == "Engine Fireman"] = 9
ang$moccu[ang$moccu == "Engine Fitter"] = 8
ang$moccu[ang$moccu == "Engine fitter"] = 8
ang$moccu[ang$moccu == "Engine Fitter "] = 8
ang$moccu[ang$moccu == "Engine Fitter R.A.F."] = 8
ang$moccu[ang$moccu == "Engine greaser"] = 8
ang$moccu[ang$moccu == "Engine Pumper"] = 8
ang$moccu[ang$moccu == "Engine Room Artificer"] = 8
ang$moccu[ang$moccu == "Engine Room Artificer R.N."] = 8
ang$moccu[ang$moccu == "Engine Room Artificer, R.N."] = 8
ang$moccu[ang$moccu == "Engine Room Mechanic"] = 8
ang$moccu[ang$moccu == "Engine Room Rating Merchant Navy"] = 8
ang$moccu[ang$moccu == "Engine Turner"] = 8
ang$moccu[ang$moccu == "Engine-driver"] = 9
ang$moccu[ang$moccu == "Engine-Driver Dockyards"] = 9
ang$moccu[ang$moccu == "Engineer"] = 0
ang$moccu[ang$moccu == "Engineer (On Active Service)"] = 0
ang$moccu[ang$moccu == "Engineer Assistant"] = 0
ang$moccu[ang$moccu == "Engineer at Brewery"] = 0
ang$moccu[ang$moccu == "Engineer Basic Training"] = 0
ang$moccu[ang$moccu == "Engineer Divisional Council"] = 0
ang$moccu[ang$moccu == "Engineer Fitter"] = 0
ang$moccu[ang$moccu == "Engineer Lieutenant R.N.R."] = 0
ang$moccu[ang$moccu == "Engineer on Trawler"] = 0
ang$moccu[ang$moccu == "Engineer R.N."] = 0
ang$moccu[ang$moccu == "Engineer S.A.R."] = 0
ang$moccu[ang$moccu == "Engineer, Corporal S.A.P.O."] = 0
ang$moccu[ang$moccu == "Engineer-boy"] = 0
ang$moccu[ang$moccu == "Engineering Assistant"] = 0
ang$moccu[ang$moccu == "Engineering assistant"] = 0
ang$moccu[ang$moccu == "Engineering Fitter"] = 8
ang$moccu[ang$moccu == "Engineering fitter"] = 8
ang$moccu[ang$moccu == "Engineering Operator"] = 8
ang$moccu[ang$moccu == "Engineering Smith"] = 8
ang$moccu[ang$moccu == "Engineering Student"] = 0
ang$moccu[ang$moccu == "Engineering Technician"] = 0
ang$moccu[ang$moccu == "Engineering Works Employee"] = 0
ang$moccu[ang$moccu == "Engineers assistant"] = 0
ang$moccu[ang$moccu == "Engineers Assistant"] = 0
ang$moccu[ang$moccu == "Engineers Dept. S.A.R."] = 0
ang$moccu[ang$moccu == "Engineers fitter"] = 8
ang$moccu[ang$moccu == "Engineers Fitter"] = 8
ang$moccu[ang$moccu == "Engineers Labourer"] = 0
ang$moccu[ang$moccu == "Engineers labourer"] = 0
ang$moccu[ang$moccu == "Engineers Salesman"] = 4
ang$moccu[ang$moccu == "Engineroom Artificer"] = 8
ang$moccu[ang$moccu == "Engineroom Mechanic, S.A.N."] = 8
ang$moccu[ang$moccu == "Engine-smith"] = 8
ang$moccu[ang$moccu == "English Civil Service"] = 3
ang$moccu[ang$moccu == "Engraver"] = 1
ang$moccu[ang$moccu == "Entomologist"] = 0
ang$moccu[ang$moccu == "Envelope Puncher"] = 9
ang$moccu[ang$moccu == "Equipment Supervisor"] = 2
ang$moccu[ang$moccu == "Essential Services"] = NA
ang$moccu[ang$moccu == "Estate + Commercial Agent"] = 4
ang$moccu[ang$moccu == "Estate + Financial Agent"] = 4
ang$moccu[ang$moccu == "Estate Agent"] = 4
ang$moccu[ang$moccu == "Estate Foreman"] = 2
ang$moccu[ang$moccu == "Estate Office, De Beers"] = 4
ang$moccu[ang$moccu == "Estates Clerk"] = 3
ang$moccu[ang$moccu == "Estimating Clerk"] = 3
ang$moccu[ang$moccu == "Estimator"] = NA
ang$moccu[ang$moccu == "Estimator Draughtsman"] = 0
ang$moccu[ang$moccu == "European Labourer S.A.R."] = 9
ang$moccu[ang$moccu == "Examiner"] = 8
ang$moccu[ang$moccu == "Examiner Clothing Factory"] = 7
ang$moccu[ang$moccu == "Examiner S.A.R."] = 8
ang$moccu[ang$moccu == "Examiner Tobacco Factory"] = 7
ang$moccu[ang$moccu == "Examiner U.T.C."] = 8
ang$moccu[ang$moccu == "Examiner United Tobacco Factory"] = 7
ang$moccu[ang$moccu == "Excavator Operator"] = 9
ang$moccu[ang$moccu == "Excise Officer"] = 3
ang$moccu[ang$moccu == "Executive"] = 2
ang$moccu[ang$moccu == "Executive, Oil Co."] = 2
ang$moccu[ang$moccu == "Exercise Officer"] = 1
ang$moccu[ang$moccu == "Explosives Superintendent"] = 2
ang$moccu[ang$moccu == "Ex-soldier in Training"] = 5
ang$moccu[ang$moccu == "F.M. Royal Air Force"] = 5
ang$moccu[ang$moccu == "FLt. R.A.F."] = 5
ang$moccu[ang$moccu == "FSgt. R.A.F."] = 5
ang$moccu[ang$moccu == "Factory apprentice"] = 9
ang$moccu[ang$moccu == "Factory Cleaner"] = 5
ang$moccu[ang$moccu == "Factory clerk"] = 3
ang$moccu[ang$moccu == "Factory Clerk"] = 3
ang$moccu[ang$moccu == "Factory Employee"] = 9
ang$moccu[ang$moccu == "Factory Fireman"] = 9
ang$moccu[ang$moccu == "Factory Foreman"] = 2
ang$moccu[ang$moccu == "Factory Hand"] = 9
ang$moccu[ang$moccu == "Factory hand"] = 9
ang$moccu[ang$moccu == "Factory hand - Shoe trading"] = 9
ang$moccu[ang$moccu == "Factory Hand(Furniture)"] = 9
ang$moccu[ang$moccu == "Factory hand: Engineering Branch"] = 9
ang$moccu[ang$moccu == "Factory instructor"] = 1
ang$moccu[ang$moccu == "Factory labourer"] = 9
ang$moccu[ang$moccu == "Factory Labourer"] = 9
ang$moccu[ang$moccu == "Factory Machinist"] = 8
ang$moccu[ang$moccu == "Factory machinist"] = 8
ang$moccu[ang$moccu == "Factory Management Staff"] = 2
ang$moccu[ang$moccu == "Factory manager"] = 2
ang$moccu[ang$moccu == "Factory Manager"] = 2
ang$moccu[ang$moccu == "Factory Operative"] = 8
ang$moccu[ang$moccu == "Factory Operator"] = 8
ang$moccu[ang$moccu == "Factory Representative"] = 4
ang$moccu[ang$moccu == "Factory Supervisor"] = 2
ang$moccu[ang$moccu == "Factory worker"] = 9
ang$moccu[ang$moccu == "Factory Worker"] = 9
ang$moccu[ang$moccu == "Factory-hand"] = 9
ang$moccu[ang$moccu == "Factory-worker"] = 9
ang$moccu[ang$moccu == "Farm Assistant"] = 6
ang$moccu[ang$moccu == "Farm Foreman"] = 2
ang$moccu[ang$moccu == "Farm hand"] = 6
ang$moccu[ang$moccu == "Farm labourer"] = 6
ang$moccu[ang$moccu == "Farm Labourer"] = 6
ang$moccu[ang$moccu == "Farm Manager"] = 2
ang$moccu[ang$moccu == "Farm worker"] = 6
ang$moccu[ang$moccu == "Farmer"] = 6
ang$moccu[ang$moccu == "Farmer (Air mechanic S.A.A.F.)"] = 6
ang$moccu[ang$moccu == "Farmer (Sergeant Fitter S.A.A.F.)"] = 6
ang$moccu[ang$moccu == "Farmer + Cattle dealer"] = 6
ang$moccu[ang$moccu == "Farmer on Active Service"] = 6
ang$moccu[ang$moccu == "FarmerLeading Stoker S.D.F."] = 6
ang$moccu[ang$moccu == "Farmhand"] = 6
ang$moccu[ang$moccu == "Farm-hand"] = 6
ang$moccu[ang$moccu == "Farrier"] = 8
ang$moccu[ang$moccu == "Feather dresser"] = 7
ang$moccu[ang$moccu == "Feather-sorter"] = 7
ang$moccu[ang$moccu == "Fence-man"] = 9
ang$moccu[ang$moccu == "Fencer"] = 9
ang$moccu[ang$moccu == "Fencing"] = 9
ang$moccu[ang$moccu == "Field Overseer - Natal Estates Ltd."] = 2
ang$moccu[ang$moccu == "Files messenger"] = 3
ang$moccu[ang$moccu == "Filing Clerk"] = 3
ang$moccu[ang$moccu == "Filing clerk"] = 3
ang$moccu[ang$moccu == "Filler"] = 9
ang$moccu[ang$moccu == "Film Editor"] = 1
ang$moccu[ang$moccu == "Filtration Plant Operator"] = 8
ang$moccu[ang$moccu == "Finance Executive"] = 2
ang$moccu[ang$moccu == "Financial Manager"] = 2
ang$moccu[ang$moccu == "Finisher at Leatherworks"] = 8
ang$moccu[ang$moccu == "Fire Alarm Technician"] = 0
ang$moccu[ang$moccu == "Fire Brigade"] = 9
ang$moccu[ang$moccu == "Fire Clerk"] = 3
ang$moccu[ang$moccu == "Fire Engineer"] = 0
ang$moccu[ang$moccu == "Fire Insurance Manager"] = 2
ang$moccu[ang$moccu == "Fireman"] = 9
ang$moccu[ang$moccu == "Fireman "] = 9
ang$moccu[ang$moccu == "Fireman (City Council)"] = 9
ang$moccu[ang$moccu == "Fireman (Fire Brigade)"] = 9
ang$moccu[ang$moccu == "Fireman C.G.R."] = 9
ang$moccu[ang$moccu == "Fireman Cape Town Fire Brigade"] = 9
ang$moccu[ang$moccu == "Fireman City Council"] = 9
ang$moccu[ang$moccu == "Fireman in Fire Brigade"] = 9
ang$moccu[ang$moccu == "Fireman M.F.B."] = 9
ang$moccu[ang$moccu == "Fireman mechanic"] = 9
ang$moccu[ang$moccu == "Fireman on Boat"] = 9
ang$moccu[ang$moccu == "Fireman on Cable Ship"] = 9
ang$moccu[ang$moccu == "Fireman on Railway"] = 9
ang$moccu[ang$moccu == "Fireman on Railway Engine"] = 9
ang$moccu[ang$moccu == "Fireman on Ship"] = 9
ang$moccu[ang$moccu == "Fireman on ship"] = 9
ang$moccu[ang$moccu == "Fireman S.A.R."] = 9
ang$moccu[ang$moccu == "Fireman S.A.R.+H."] = 9
ang$moccu[ang$moccu == "Fireman(Trawler)"] = 9
ang$moccu[ang$moccu == "Firewood Hawker"] = 4
ang$moccu[ang$moccu == "Firm Manager"] = 2
ang$moccu[ang$moccu == "Firms Representative"] = 4
ang$moccu[ang$moccu == "Firms Representative"] = 4
ang$moccu[ang$moccu == "First Class Stoker"] = 9
ang$moccu[ang$moccu == "First Class Stoker "] = 9
ang$moccu[ang$moccu == "First Grade Checker"] = 3
ang$moccu[ang$moccu == "Fish Curer"] = 7
ang$moccu[ang$moccu == "Fish Dealer"] = 4
ang$moccu[ang$moccu == "Fish Distributor"] = 9
ang$moccu[ang$moccu == "Fish Factory hand"] = 6
ang$moccu[ang$moccu == "Fish Hawker"] = 4
ang$moccu[ang$moccu == "Fish hawker"] = 4
ang$moccu[ang$moccu == "Fish Merchant"] = 4
ang$moccu[ang$moccu == "Fish Packer"] = 9
ang$moccu[ang$moccu == "Fish shop Delivery man"] = 9
ang$moccu[ang$moccu == "Fish-dealer"] = 4
ang$moccu[ang$moccu == "Fisherman"] = 6
ang$moccu[ang$moccu == "Fishery Manager"] = 2
ang$moccu[ang$moccu == "Fishery Owner"] = 6
ang$moccu[ang$moccu == "Fishing Industry"] = 6
ang$moccu[ang$moccu == "Fishing Skipper"] = 6
ang$moccu[ang$moccu == "Fishing-rod Maker"] = 7
ang$moccu[ang$moccu == "Fishmonger"] = 4
ang$moccu[ang$moccu == "Fish-shop boy"] = 4
ang$moccu[ang$moccu == "Fish-smoker"] = 7
ang$moccu[ang$moccu == "Fitter"] = 8
ang$moccu[ang$moccu == "Fitter (Diamond Mine)"] = 8
ang$moccu[ang$moccu == "Fitter (Ground Staff R.A.F.)"] = 8
ang$moccu[ang$moccu == "Fitter (On Active Service)"] = 8
ang$moccu[ang$moccu == "Fitter + Turner"] = 8
ang$moccu[ang$moccu == "Fitter + Turner R.A.F."] = 8
ang$moccu[ang$moccu == "Fitter + Turner S.A.R."] = 8
ang$moccu[ang$moccu == "Fitter and Turner"] = 8
ang$moccu[ang$moccu == "Fitter Armourer R.A.F."] = 8
ang$moccu[ang$moccu == "Fitter Armourer, S.A.A.F."] = 8
ang$moccu[ang$moccu == "Fitter Cape Town City Council"] = 8
ang$moccu[ang$moccu == "Fitter in Power Station"] = 8
ang$moccu[ang$moccu == "Fitter Match Factory"] = 8
ang$moccu[ang$moccu == "Fitter R.A.F."] = 8
ang$moccu[ang$moccu == "Fitter R.N."] = 8
ang$moccu[ang$moccu == "Fitter S.A. Air Force"] = 8
ang$moccu[ang$moccu == "Fitter S.A.A."] = 8
ang$moccu[ang$moccu == "Fitter S.A.A.F."] = 8
ang$moccu[ang$moccu == "Fitter S.A.R."] = 8
ang$moccu[ang$moccu == "Fitter S.A.R.+H."] = 8
ang$moccu[ang$moccu == "Fitter-armourer R.A.F."] = 8
ang$moccu[ang$moccu == "Fitters assistant"] = 8
ang$moccu[ang$moccu == "Fitters Assistant"] = 8
ang$moccu[ang$moccu == "Fitters labourer"] = 8
ang$moccu[ang$moccu == "Fitters Mate C T Municipality"] = 8
ang$moccu[ang$moccu == "Fixer"] = 9
ang$moccu[ang$moccu == "Flight Lieut. R.A.F."] = 5
ang$moccu[ang$moccu == "Flight Lieutenant, Royal Canadian Air Force"] = 5
ang$moccu[ang$moccu == "Flight Lt. R.A.F."] = 5
ang$moccu[ang$moccu == "Flight Sergeant"] = 5
ang$moccu[ang$moccu == "Flight Sergeant R.A.F."] = 5
ang$moccu[ang$moccu == "Flight Sergeant R.A.F. On Active Service"] = 5
ang$moccu[ang$moccu == "Flight Sergeant R.A.F. Police"] = 5
ang$moccu[ang$moccu == "Flight Sergeant S.A. Air Force"] = 5
ang$moccu[ang$moccu == "Flight Sergeant S.A.A.F."] = 5
ang$moccu[ang$moccu == "Floor layer"] = 9
ang$moccu[ang$moccu == "Floor Layer"] = 9
ang$moccu[ang$moccu == "Floorlayer"] = 9
ang$moccu[ang$moccu == "Floorsander"] = 7
ang$moccu[ang$moccu == "Floor-sander"] = 7
ang$moccu[ang$moccu == "Florist"] = 4
ang$moccu[ang$moccu == "Florists assistant"] = 4
ang$moccu[ang$moccu == "Flour Miller"] = 7
ang$moccu[ang$moccu == "Flour-miller"] = 7
ang$moccu[ang$moccu == "Flower Farmer"] = 6
ang$moccu[ang$moccu == "Flower gardener"] = 6
ang$moccu[ang$moccu == "Flower seller"] = 4
ang$moccu[ang$moccu == "Flower Seller"] = 4
ang$moccu[ang$moccu == "Flower-hawker"] = 4
ang$moccu[ang$moccu == "Flower-seller"] = 4
ang$moccu[ang$moccu == "Flying Instructor"] = 0
ang$moccu[ang$moccu == "Flying Instructor S.A. Air Force"] = 0
ang$moccu[ang$moccu == "Flying Instructor S.A. Defence Force"] = 0
ang$moccu[ang$moccu == "Flying Instructor S.A.A.F."] = 0
ang$moccu[ang$moccu == "Flying Officer R.A.F."] = 5
ang$moccu[ang$moccu == "Flying Officer R.A.F. On Active Service"] = 5
ang$moccu[ang$moccu == "Folder Examiner"] = 9
ang$moccu[ang$moccu == "Food Manufacturer"] = 7
ang$moccu[ang$moccu == "Food Scientist"] = 0
ang$moccu[ang$moccu == "Forage Cutter"] = 6
ang$moccu[ang$moccu == "Forage Dealer"] = 4
ang$moccu[ang$moccu == "Force Publique Belgian Congo"] = 5
ang$moccu[ang$moccu == "Foreman"] = 2
ang$moccu[ang$moccu == "Foreman "] = 2
ang$moccu[ang$moccu == "Foreman  Box-maker"] = 2
ang$moccu[ang$moccu == "Foreman Cape Textiles"] = 2
ang$moccu[ang$moccu == "Foreman at Brickworks"] = 2
ang$moccu[ang$moccu == "Foreman at Docks"] = 2
ang$moccu[ang$moccu == "Foreman at Factory"] = 2
ang$moccu[ang$moccu == "Foreman at Laundry"] = 2
ang$moccu[ang$moccu == "Foreman Brewer"] = 2
ang$moccu[ang$moccu == "Foreman Brickfields"] = 2
ang$moccu[ang$moccu == "Foreman Bricklayer"] = 2
ang$moccu[ang$moccu == "Foreman Builder"] = 2
ang$moccu[ang$moccu == "Foreman C.G.R."] = 2
ang$moccu[ang$moccu == "Foreman C.S.A.R."] = 2
ang$moccu[ang$moccu == "Foreman Carpenter"] = 2
ang$moccu[ang$moccu == "Foreman Checker"] = 2
ang$moccu[ang$moccu == "Foreman City Corporation"] = 2
ang$moccu[ang$moccu == "Foreman City Council"] = 2
ang$moccu[ang$moccu == "Foreman Continental Restaurant"] = 2
ang$moccu[ang$moccu == "Foreman Electricity Department"] = 2
ang$moccu[ang$moccu == "Foreman Fitter"] = 2
ang$moccu[ang$moccu == "Foreman Forestry Dept."] = 2
ang$moccu[ang$moccu == "Foreman G.P.O."] = 2
ang$moccu[ang$moccu == "Foreman High Constantia"] = 2
ang$moccu[ang$moccu == "Foreman in Distillery"] = 2
ang$moccu[ang$moccu == "Foreman Knitting Mill"] = 2
ang$moccu[ang$moccu == "Foreman Labourer"] = 2
ang$moccu[ang$moccu == "Foreman labourer"] = 2
ang$moccu[ang$moccu == "Foreman Leatherworks"] = 2
ang$moccu[ang$moccu == "Foreman Municipal Stables"] = 2
ang$moccu[ang$moccu == "Foreman O.C.B."] = 2
ang$moccu[ang$moccu == "Foreman of Fire Brigade"] = 2
ang$moccu[ang$moccu == "Foreman of Platelayers"] = 2
ang$moccu[ang$moccu == "Foreman on Farm"] = 2
ang$moccu[ang$moccu == "Foreman on Railway"] = 2
ang$moccu[ang$moccu == "Foreman P.W.D."] = 2
ang$moccu[ang$moccu == "Foreman packer"] = 2
ang$moccu[ang$moccu == "Foreman Pipe Co."] = 2
ang$moccu[ang$moccu == "Foreman Plumber"] = 2
ang$moccu[ang$moccu == "Foreman Porter"] = 2
ang$moccu[ang$moccu == "Foreman Railway"] = 2
ang$moccu[ang$moccu == "Foreman Railway Station"] = 2
ang$moccu[ang$moccu == "Foreman Revenue Dept."] = 2
ang$moccu[ang$moccu == "Foreman Rounder"] = 2
ang$moccu[ang$moccu == "Foreman S.A.M.C."] = 2
ang$moccu[ang$moccu == "Foreman S.A.R."] = 2
ang$moccu[ang$moccu == "Foreman Shell Company"] = 2
ang$moccu[ang$moccu == "Foreman Shunter S.A.R.+H."] = 2
ang$moccu[ang$moccu == "Foreman Slaughterman"] = 2
ang$moccu[ang$moccu == "Foreman Soap Factory"] = 2
ang$moccu[ang$moccu == "Foreman Table Mountain Reservoir"] = 2
ang$moccu[ang$moccu == "Foreman(Municipality)"] = 2
ang$moccu[ang$moccu == "Foreman, Footwear Industry"] = 2
ang$moccu[ang$moccu == "Foreman, Tyre retreading factory"] = 2
ang$moccu[ang$moccu == "Foreman-Builder"] = 2
ang$moccu[ang$moccu == "Foreman-Compositor"] = 2
ang$moccu[ang$moccu == "Foreman-Ganger S.A.R."] = 2
ang$moccu[ang$moccu == "Foreman-Mechanic"] = 2
ang$moccu[ang$moccu == "Forest Attendant"] = 6
ang$moccu[ang$moccu == "Forest Officer"] = 6
ang$moccu[ang$moccu == "Forester"] = 6
ang$moccu[ang$moccu == "Forestry"] = 6
ang$moccu[ang$moccu == "Forklift Operator"] = 8
ang$moccu[ang$moccu == "Founderer"] = 2
ang$moccu[ang$moccu == "Frame Filler in Match Factory"] = 7
ang$moccu[ang$moccu == "Frame maker - furniture trade"] = 7
ang$moccu[ang$moccu == "Frame Maker Cabinet Works"] = 7
ang$moccu[ang$moccu == "Framemaker"] = 7
ang$moccu[ang$moccu == "Frame-maker"] = 7
ang$moccu[ang$moccu == "French Polisher"] = 8
ang$moccu[ang$moccu == "Fruit Agent"] = 4
ang$moccu[ang$moccu == "Fruit and vegetable Hawker"] = 4
ang$moccu[ang$moccu == "Fruit and Vegetable Hawker"] = 4
ang$moccu[ang$moccu == "Fruit Dealer"] = 4
ang$moccu[ang$moccu == "Fruit Farmer"] = 6
ang$moccu[ang$moccu == "Fruit grower"] = 6
ang$moccu[ang$moccu == "Fruit Grower"] = 6
ang$moccu[ang$moccu == "Fruit hawker"] = 4
ang$moccu[ang$moccu == "Fruit Packer"] = 9
ang$moccu[ang$moccu == "Fruitdealer"] = 4
ang$moccu[ang$moccu == "Fruiterer"] = 4
ang$moccu[ang$moccu == "Fruiterers cashier"] = 3
ang$moccu[ang$moccu == "Fruiterers packer"] = 4
ang$moccu[ang$moccu == "Fruit-packer"] = 4
ang$moccu[ang$moccu == "Fuller"] = 7
ang$moccu[ang$moccu == "Fumigator S.A.R."] = 5
ang$moccu[ang$moccu == "Funeral Director"] = 2
ang$moccu[ang$moccu == "Furnace Bricklayer"] = 9
ang$moccu[ang$moccu == "Furnace-builder"] = 9
ang$moccu[ang$moccu == "Furniture Employee"] = 8
ang$moccu[ang$moccu == "Furniture Factory Employee"] = 8
ang$moccu[ang$moccu == "Furniture Fitter"] = 8
ang$moccu[ang$moccu == "Furniture machinist"] = 8
ang$moccu[ang$moccu == "Furniture Machinist"] = 8
ang$moccu[ang$moccu == "Furniture maker"] = 7
ang$moccu[ang$moccu == "Furniture Manufacturer"] = 7
ang$moccu[ang$moccu == "Furniture Packer"] = 9
ang$moccu[ang$moccu == "Furniture Polisher"] = 7
ang$moccu[ang$moccu == "Furniture Remover"] = 7
ang$moccu[ang$moccu == "Furniture Salesman"] = 4
ang$moccu[ang$moccu == "Furniture sander"] = 7
ang$moccu[ang$moccu == "Furniture Sprayer"] = 7
ang$moccu[ang$moccu == "Furniture Stainer"] = 7
ang$moccu[ang$moccu == "Furniture Store Employee"] = 8
ang$moccu[ang$moccu == "Furniture worker"] = 8
ang$moccu[ang$moccu == "Furniture-Machinist"] = 8
ang$moccu[ang$moccu == "Furniture-maker"] = 8
ang$moccu[ang$moccu == "Furrier"] = 7
ang$moccu[ang$moccu == "G.P.O."] = 3
ang$moccu[ang$moccu == "G.P.O. Assistant"] = 3
ang$moccu[ang$moccu == "G.P.O. Cape Town"] = 3
ang$moccu[ang$moccu == "G.P.O. Carrier"] = 3
ang$moccu[ang$moccu == "G.P.O. Civil Service"] = 3
ang$moccu[ang$moccu == "G.P.O. Employee"] = 3
ang$moccu[ang$moccu == "G.P.O. Foreman"] = 2
ang$moccu[ang$moccu == "G.P.O. Labourer"] = 3
ang$moccu[ang$moccu == "G.P.O. Technician"] = 0
ang$moccu[ang$moccu == "G.P.O. Telephonist"] = 3
ang$moccu[ang$moccu == "Gambler"] = 1
ang$moccu[ang$moccu == "Ganger"] = 2
ang$moccu[ang$moccu == "Ganger (Electricity Dept.)"] = 2
ang$moccu[ang$moccu == "Ganger S.A.R."] = 2
ang$moccu[ang$moccu == "Garage Assistant"] = 8
ang$moccu[ang$moccu == "Garage attendant"] = 8
ang$moccu[ang$moccu == "Garage Attendant"] = 8
ang$moccu[ang$moccu == "Garage boy"] = 8
ang$moccu[ang$moccu == "Garage cleaner"] = 5
ang$moccu[ang$moccu == "Garage Director"] = 2
ang$moccu[ang$moccu == "Garage Employee"] = 9
ang$moccu[ang$moccu == "Garage Foreman"] = 2
ang$moccu[ang$moccu == "Garage Hand"] = 9
ang$moccu[ang$moccu == "Garage hand"] = 9
ang$moccu[ang$moccu == "Garage labourer"] = 9
ang$moccu[ang$moccu == "Garage Labourer"] = 9
ang$moccu[ang$moccu == "Garage man"] = 9
ang$moccu[ang$moccu == "Garage Manager"] = 2
ang$moccu[ang$moccu == "Garage Mechanic"] = 9
ang$moccu[ang$moccu == "Garage Proprietor"] = 8
ang$moccu[ang$moccu == "Garage Pump Hand"] = 9
ang$moccu[ang$moccu == "Garage Service Attendant"] = 8
ang$moccu[ang$moccu == "Garage Service Manager"] = 2
ang$moccu[ang$moccu == "Garage Supervisor"] = 2
ang$moccu[ang$moccu == "Garage Worker"] = 9
ang$moccu[ang$moccu == "Garage worker"] = 9
ang$moccu[ang$moccu == "Garage-boy"] = 9
ang$moccu[ang$moccu == "Garage-hand"] = 9
ang$moccu[ang$moccu == "Garden Architect"] = 6
ang$moccu[ang$moccu == "Gardener"] = 6
ang$moccu[ang$moccu == "Gardener for Municipality"] = 6
ang$moccu[ang$moccu == "Gardener Public Works Dept."] = 6
ang$moccu[ang$moccu == "Gardeners labourer"] = 6
ang$moccu[ang$moccu == "Garlicks Wholesale"] = 4
ang$moccu[ang$moccu == "Garment Cutter"] = 7
ang$moccu[ang$moccu == "Garment-worker"] = 7
ang$moccu[ang$moccu == "Gas Engineer"] = 0
ang$moccu[ang$moccu == "Gas Fitter"] = 8
ang$moccu[ang$moccu == "Gas fitter"] = 8
ang$moccu[ang$moccu == "Gas metre Inspector"] = 2
ang$moccu[ang$moccu == "Gas-fitter"] = 8
ang$moccu[ang$moccu == "Gasfitter (Corporal R.A.F.)"] = 8
ang$moccu[ang$moccu == "Gate Keeper"] = 9
ang$moccu[ang$moccu == "Gatekeeper"] = 9
ang$moccu[ang$moccu == "Gatekeeper C.G.R."] = 9
ang$moccu[ang$moccu == "General Agent"] = 9
ang$moccu[ang$moccu == "General Assistant"] = 9
ang$moccu[ang$moccu == "General assistant"] = 9
ang$moccu[ang$moccu == "General Clerk"] = 3
ang$moccu[ang$moccu == "General Contractor"] = 2
ang$moccu[ang$moccu == "General Dealer"] = 4
ang$moccu[ang$moccu == "General dealer"] = 4
ang$moccu[ang$moccu == "General dealer + Contractor"] = 4
ang$moccu[ang$moccu == "General Dealers clerk"] = 3
ang$moccu[ang$moccu == "General Employee G.P.O."] = 9
ang$moccu[ang$moccu == "General Engineer"] = 0
ang$moccu[ang$moccu == "General Farmer"] = 2
ang$moccu[ang$moccu == "General Fitter"] = 8
ang$moccu[ang$moccu == "General Hand"] = 9
ang$moccu[ang$moccu == "General Handyman"] = 9
ang$moccu[ang$moccu == "General labourer"] = 9
ang$moccu[ang$moccu == "General Labourer"] = 9
ang$moccu[ang$moccu == "General Manager"] = 2
ang$moccu[ang$moccu == "General Manager + Chief Actuary"] = 0
ang$moccu[ang$moccu == "General Manager Natal Bank"] = 2
ang$moccu[ang$moccu == "General Merchant"] = 4
ang$moccu[ang$moccu == "General messenger"] = 3
ang$moccu[ang$moccu == "General Painter"] = 9
ang$moccu[ang$moccu == "General Practitioner"] = 0
ang$moccu[ang$moccu == "General Secretary Royal Automobile Club of S.A."] = 3
ang$moccu[ang$moccu == "General Servant"] = 5
ang$moccu[ang$moccu == "General Wireman"] = 8
ang$moccu[ang$moccu == "General work"] = 9
ang$moccu[ang$moccu == "General worker"] = 9
ang$moccu[ang$moccu == "General Worker"] = 9
ang$moccu[ang$moccu == "Gentleman"] = NA
ang$moccu[ang$moccu == "Gents Hairdresser"] = 5
ang$moccu[ang$moccu == "Geologist"] = 0
ang$moccu[ang$moccu == "Glacier"] = 8
ang$moccu[ang$moccu == "Glass Beveller"] = 8
ang$moccu[ang$moccu == "Glass beveller"] = 8
ang$moccu[ang$moccu == "Glass Cutter"] = 8
ang$moccu[ang$moccu == "Glass cutter"] = 8
ang$moccu[ang$moccu == "Glass cutters labourer"] = 8
ang$moccu[ang$moccu == "Glass Fibre Laminator"] = 8
ang$moccu[ang$moccu == "Glass Merchant"] = 4
ang$moccu[ang$moccu == "Glass Polisher"] = 8
ang$moccu[ang$moccu == "Glass worker"] = 8
ang$moccu[ang$moccu == "Glassblower"] = 8
ang$moccu[ang$moccu == "Glass-cutter"] = 8
ang$moccu[ang$moccu == "Glazer"] = 8
ang$moccu[ang$moccu == "Glazier"] = 8
ang$moccu[ang$moccu == "Glaziers labourer"] = 8
ang$moccu[ang$moccu == "Goldsmith"] = 8
ang$moccu[ang$moccu == "Golf Professional"] = 1
ang$moccu[ang$moccu == "Golf-course Keeper"] = 6
ang$moccu[ang$moccu == "Goodsyard Labourer S.A.R."] = 9
ang$moccu[ang$moccu == "Government Actuary"] = 0
ang$moccu[ang$moccu == "Government Auditor"] = 1
ang$moccu[ang$moccu == "Government Auxiliary Service"] = 3
ang$moccu[ang$moccu == "Government Driver"] = 9
ang$moccu[ang$moccu == "Government Forester"] = 6
ang$moccu[ang$moccu == "Government Inspector of Mines"] = 2
ang$moccu[ang$moccu == "Government Land Surveyor"] = 0
ang$moccu[ang$moccu == "Government Messenger"] = 3
ang$moccu[ang$moccu == "Government Ranger"] = 6
ang$moccu[ang$moccu == "Government Servant"] = 2
ang$moccu[ang$moccu == "Government Service"] = 2
ang$moccu[ang$moccu == "Government Soil Erosion"] = 6
ang$moccu[ang$moccu == "Government Stationery Dept."] = 9
ang$moccu[ang$moccu == "Government Surveyor"] = 0
ang$moccu[ang$moccu == "Government Teacher"] = 1
ang$moccu[ang$moccu == "Government Veterinary Officer"] = 0
ang$moccu[ang$moccu == "Govt. Clerk"] = 3
ang$moccu[ang$moccu == "Govt. Servant S.A.R."] = 3
ang$moccu[ang$moccu == "Grader"] = 9
ang$moccu[ang$moccu == "Grader operator"] = 9
ang$moccu[ang$moccu == "Graduate-Assistant"] = 9
ang$moccu[ang$moccu == "Grain + Produce Broker"] = 4
ang$moccu[ang$moccu == "Grain Elevator Operator"] = 7
ang$moccu[ang$moccu == "Grape-juice Manufacturer"] = 7
ang$moccu[ang$moccu == "Grave Digger"] = 9
ang$moccu[ang$moccu == "Grave-digger"] = 9
ang$moccu[ang$moccu == "Gravel Contractor"] = 2
ang$moccu[ang$moccu == "Greacer on ship"] = 9
ang$moccu[ang$moccu == "Greaser"] = 9
ang$moccu[ang$moccu == "Greaser - Motor Garage"] = 9
ang$moccu[ang$moccu == "Greaser(Motor Trade)"] = 9
ang$moccu[ang$moccu == "Green grocer"] = 4
ang$moccu[ang$moccu == "Green Grocer"] = 4
ang$moccu[ang$moccu == "Greengrocer"] = 4
ang$moccu[ang$moccu == "Greengrocers assistant"] = 4
ang$moccu[ang$moccu == "Greenkeeper"] = 6
ang$moccu[ang$moccu == "Grinder"] = 9
ang$moccu[ang$moccu == "Grinder of Cutlery"] = 8
ang$moccu[ang$moccu == "Grocer"] = 4
ang$moccu[ang$moccu == "Grocers assistant"] = 4
ang$moccu[ang$moccu == "Grocers Assistant"] = 4
ang$moccu[ang$moccu == "Grocers assistnat"] = 4
ang$moccu[ang$moccu == "Grocers Delivery-man"] = 9
ang$moccu[ang$moccu == "Grocers man"] = 4
ang$moccu[ang$moccu == "Grocers messenger"] = 3
ang$moccu[ang$moccu == "Grocers Traveller"] = 4
ang$moccu[ang$moccu == "Grocery deliveryman"] = 4
ang$moccu[ang$moccu == "Grocery Manager"] = 2
ang$moccu[ang$moccu == "Grocier boy"] = 4
ang$moccu[ang$moccu == "Groom"] = 6
ang$moccu[ang$moccu == "Groom + labourer"] = 6
ang$moccu[ang$moccu == "Groomer"] = 6
ang$moccu[ang$moccu == "Groomsman"] = 6
ang$moccu[ang$moccu == "Ground Engineer"] = 0
ang$moccu[ang$moccu == "Ground Engineer S.A. Airways"] = 0
ang$moccu[ang$moccu == "Groundman"] = 6
ang$moccu[ang$moccu == "Groundsman"] = 6
ang$moccu[ang$moccu == "Groundsman Race Course"] = 6
ang$moccu[ang$moccu == "Gtoom"] = 6
ang$moccu[ang$moccu == "Guanofounder"] = 6
ang$moccu[ang$moccu == "Guard"] = 5
ang$moccu[ang$moccu == "Guard in Tram car"] = 5
ang$moccu[ang$moccu == "Guard on Lorry"] = 5
ang$moccu[ang$moccu == "Guard on Parcel Van"] = 5
ang$moccu[ang$moccu == "Guard on Railway"] = 5
ang$moccu[ang$moccu == "Guard on Tram line"] = 5
ang$moccu[ang$moccu == "Guard Rhodesia Railways"] = 5
ang$moccu[ang$moccu == "Guard S.A.R."] = 5
ang$moccu[ang$moccu == "Guard Tramway Co."] = 5
ang$moccu[ang$moccu == "Guard, C.G.R."] = 5
ang$moccu[ang$moccu == "Guard, Kimberley Jail"] = 5
ang$moccu[ang$moccu == "Guardboy S.A.R."] = 5
ang$moccu[ang$moccu == "Guideman"] = 5
ang$moccu[ang$moccu == "Gun maker"] = 8
ang$moccu[ang$moccu == "Gunner"] = 5
ang$moccu[ang$moccu == "Gunner in Royal Artillery"] = 5
ang$moccu[ang$moccu == "Gunner R.G.A."] = 5
ang$moccu[ang$moccu == "Gunner Royal Artillery"] = 5
ang$moccu[ang$moccu == "Gunner Royal Navy"] = 5
ang$moccu[ang$moccu == "Gunner S.A. Army"] = 5
ang$moccu[ang$moccu == "Gunner S.A. Artillery"] = 5
ang$moccu[ang$moccu == "Gunner U.D.F."] = 5
ang$moccu[ang$moccu == "Gunner, Cape Corps"] = 5
ang$moccu[ang$moccu == "Gunner, S.A. Artillery"] = 5
ang$moccu[ang$moccu == "Gunner, S.A. Field Artillery"] = 5
ang$moccu[ang$moccu == "Gunnery Officer, Netherlands Merchant Navy"] = 5
ang$moccu[ang$moccu == "H. M. Customs"] = 3
ang$moccu[ang$moccu == "H.M. Customs"] = 3
ang$moccu[ang$moccu == "Hairdresser"] = 5
ang$moccu[ang$moccu == "Hall Attendant"] = 5
ang$moccu[ang$moccu == "Hall Porter"] = 9
ang$moccu[ang$moccu == "Hammermaker"] = 8
ang$moccu[ang$moccu == "Hammerman"] = 8
ang$moccu[ang$moccu == "Hand Clicker"] = 8
ang$moccu[ang$moccu == "Hand Printing"] = 9
ang$moccu[ang$moccu == "Hand Sander"] = 7
ang$moccu[ang$moccu == "Hand Sandpaperer"] = 7
ang$moccu[ang$moccu == "Handbag Framer"] = 7
ang$moccu[ang$moccu == "Handbag Maker"] = 7
ang$moccu[ang$moccu == "Handclicker Leather Industry"] = 3
ang$moccu[ang$moccu == "Hand-laster"] = 8
ang$moccu[ang$moccu == "Hand-laster Leather Trade"] = 8
ang$moccu[ang$moccu == "Handsander"] = 9
ang$moccu[ang$moccu == "Hand-sander"] = 9
ang$moccu[ang$moccu == "Handsman "] = 9
ang$moccu[ang$moccu == "Handyman"] = 9
ang$moccu[ang$moccu == "Handyman at Steel Firm"] = 9
ang$moccu[ang$moccu == "Handyman Electrician"] = 9
ang$moccu[ang$moccu == "Handyman for firm"] = 9
ang$moccu[ang$moccu == "Handyman for Hotel"] = 9
ang$moccu[ang$moccu == "Handyman for Municipality"] = 9
ang$moccu[ang$moccu == "Handyman in Divisional Council"] = 9
ang$moccu[ang$moccu == "Handyman on Market"] = 9
ang$moccu[ang$moccu == "Handyman S.A.R."] = 9
ang$moccu[ang$moccu == "HandymanCarpenter"] = 9
ang$moccu[ang$moccu == "Harbour Board Employer"] = 2
ang$moccu[ang$moccu == "Harbour Board Labourer"] = 9
ang$moccu[ang$moccu == "Harbour Works Employer"] = 9
ang$moccu[ang$moccu == "Harbour Works Labourer"] = 9
ang$moccu[ang$moccu == "Hardware Manager"] = 2
ang$moccu[ang$moccu == "Hardware Salesman"] = 4
ang$moccu[ang$moccu == "Hardware Storeman"] = 4
ang$moccu[ang$moccu == "Harness Machinist"] = 8
ang$moccu[ang$moccu == "Harness maker"] = 7
ang$moccu[ang$moccu == "Harness Maker"] = 7
ang$moccu[ang$moccu == "Harness trade"] = 4
ang$moccu[ang$moccu == "Harness-maker"] = 7
ang$moccu[ang$moccu == "Hat Blocker"] = 7
ang$moccu[ang$moccu == "Hatchman: Merchant Service"] = 4
ang$moccu[ang$moccu == "Hawker"] = 4
ang$moccu[ang$moccu == "Hawker of Greens"] = 4
ang$moccu[ang$moccu == "Hawker of Vegetables"] = 4
ang$moccu[ang$moccu == "Head Cellarman O.C.B."] = 5
ang$moccu[ang$moccu == "Head Messenger"] = 3
ang$moccu[ang$moccu == "Head Office Attendant, City Council"] = 3
ang$moccu[ang$moccu == "Head Office Messenger"] = 3
ang$moccu[ang$moccu == "Head Overseer"] = 2
ang$moccu[ang$moccu == "Head Steward"] = 5
ang$moccu[ang$moccu == "Head Waiter"] = 5
ang$moccu[ang$moccu == "Head Waiter"] = 5
ang$moccu[ang$moccu == "Health Department"] = 5
ang$moccu[ang$moccu == "Health Inspector"] = 2
ang$moccu[ang$moccu == "Health Official"] = 3
ang$moccu[ang$moccu == "Heavy Vehicle Driver"] = 9
ang$moccu[ang$moccu == "Heeltrimmer Boot Trade"] = 9
ang$moccu[ang$moccu == "Hide and Skin Grader"] = 7
ang$moccu[ang$moccu == "Holder Up S.A.R."] = 9
ang$moccu[ang$moccu == "Holderup"] = 9
ang$moccu[ang$moccu == "Hollerith Operator"] = 3
ang$moccu[ang$moccu == "Home Decorator"] = 1
ang$moccu[ang$moccu == "Home servant"] = 5
ang$moccu[ang$moccu == "Homeboy"] = 5
ang$moccu[ang$moccu == "Homedresser"] = 1
ang$moccu[ang$moccu == "Horse driver"] = 9
ang$moccu[ang$moccu == "Horse keeper"] = 6
ang$moccu[ang$moccu == "Horse trainer"] = 6
ang$moccu[ang$moccu == "Horticulturist"] = 6
ang$moccu[ang$moccu == "Hosier"] = 7
ang$moccu[ang$moccu == "Hosiery Mechanic"] = 7
ang$moccu[ang$moccu == "Hospital Assistant"] = 5
ang$moccu[ang$moccu == "Hospital attendant"] = 5
ang$moccu[ang$moccu == "Hospital Attendant"] = 5
ang$moccu[ang$moccu == "Hospital cleaner"] = 5
ang$moccu[ang$moccu == "Hospital Dresser"] = 5
ang$moccu[ang$moccu == "Hospital Messenger"] = 3
ang$moccu[ang$moccu == "Hospital Orderly"] = 5
ang$moccu[ang$moccu == "Hospital Porter"] = 9
ang$moccu[ang$moccu == "Hospital Sergeant"] = 5
ang$moccu[ang$moccu == "Hospital worker"] = 5
ang$moccu[ang$moccu == "Hospital-Attendant"] = 5
ang$moccu[ang$moccu == "Hotel Bar Attendant"] = 5
ang$moccu[ang$moccu == "Hotel Bar-boy"] = 5
ang$moccu[ang$moccu == "Hotel Catering Manager"] = 2
ang$moccu[ang$moccu == "Hotel Chef"] = 5
ang$moccu[ang$moccu == "Hotel Cook"] = 5
ang$moccu[ang$moccu == "Hotel Director"] = 2
ang$moccu[ang$moccu == "Hotel Keeper"] = 5
ang$moccu[ang$moccu == "Hotel Keeper(of Kimberley)"] = 5
ang$moccu[ang$moccu == "Hotel Liftboy"] = 5
ang$moccu[ang$moccu == "Hotel Manager"] = 5
ang$moccu[ang$moccu == "Hotel Porter"] = 9
ang$moccu[ang$moccu == "Hotel Proprietor"] = 2
ang$moccu[ang$moccu == "Hotel Servant"] = 5
ang$moccu[ang$moccu == "Hotel Steward"] = 5
ang$moccu[ang$moccu == "Hotel Waiter"] = 5
ang$moccu[ang$moccu == "Hotel waiter"] = 5
ang$moccu[ang$moccu == "Hotel worker"] = 5
ang$moccu[ang$moccu == "Hotelier"] = 2
ang$moccu[ang$moccu == "Hotelkeeper"] = 2
ang$moccu[ang$moccu == "Hotel-keeper"] = 2
ang$moccu[ang$moccu == "House boy"] = 5
ang$moccu[ang$moccu == "House Boy"] = 5
ang$moccu[ang$moccu == "House painter"] = 9
ang$moccu[ang$moccu == "House Painter"] = 9
ang$moccu[ang$moccu == "House Painter + Decorator"] = 9
ang$moccu[ang$moccu == "House servant"] = 5
ang$moccu[ang$moccu == "House waiter"] = 5
ang$moccu[ang$moccu == "Houseb"] = 5
ang$moccu[ang$moccu == "Houseboy"] = 5
ang$moccu[ang$moccu == "House-boy"] = 5
ang$moccu[ang$moccu == "Houseboy waiter"] = 5
ang$moccu[ang$moccu == "HouseboyGardener"] = 5
ang$moccu[ang$moccu == "House-boyWaiter"] = 5
ang$moccu[ang$moccu == "Household servant"] = 5
ang$moccu[ang$moccu == "Housekeeper"] = 5
ang$moccu[ang$moccu == "Hydrant Cleaner"] = 9
ang$moccu[ang$moccu == "Hydrant Cleaner, Fire Brigade"] = 9
ang$moccu[ang$moccu == "Hydraulics Research Assistant"] = 1
ang$moccu[ang$moccu == "Hyster Driver"] = 9
ang$moccu[ang$moccu == "Ice Cream Factory"] = 9
ang$moccu[ang$moccu == "Ice=cream seller"] = 4
ang$moccu[ang$moccu == "Illumination Engineer"] = 0
ang$moccu[ang$moccu == "Imperial Army Officer"] = 5
ang$moccu[ang$moccu == "Imperial Civil Servant"] = 3
ang$moccu[ang$moccu == "Imperial Trades Commissioner"] = 2
ang$moccu[ang$moccu == "Importer"] = 4
ang$moccu[ang$moccu == "Importer in Electricity S.A.R. Works"] = 4
ang$moccu[ang$moccu == "Importer of Livestock"] = 4
ang$moccu[ang$moccu == "Improver in Electricity S.A.R. Works"] = 4
ang$moccu[ang$moccu == "In Business"] = 4
ang$moccu[ang$moccu == "In business of Vacuum Oil Co."] = 4
ang$moccu[ang$moccu == "In Domestic Service"] = 5
ang$moccu[ang$moccu == "In Holy Orders"] = 1
ang$moccu[ang$moccu == "In Wine Store"] = 4
ang$moccu[ang$moccu == "Incorporated Accountant"] = 1
ang$moccu[ang$moccu == "Indent Agent"] = 3
ang$moccu[ang$moccu == "Indian Army Officer"] = 5
ang$moccu[ang$moccu == "Indoor servant"] = 5
ang$moccu[ang$moccu == "Industrial Chemist"] = 0
ang$moccu[ang$moccu == "Industrial Chesmit"] = 0
ang$moccu[ang$moccu == "Industrial Inspector"] = 2
ang$moccu[ang$moccu == "Industrial Linesman"] = 8
ang$moccu[ang$moccu == "Industrial Manager"] = 2
ang$moccu[ang$moccu == "Industrial Photographer"] = 1
ang$moccu[ang$moccu == "Industrial Representative"] = 4
ang$moccu[ang$moccu == "Influx Control Officer"] = 5
ang$moccu[ang$moccu == "Information Officer, N. Rhodesian Government"] = 3
ang$moccu[ang$moccu == "Inn Keeper"] = 5
ang$moccu[ang$moccu == "Inoculator"] = 0
ang$moccu[ang$moccu == "Insepctor S.A.R."] = 2
ang$moccu[ang$moccu == "Inside servant"] = 5
ang$moccu[ang$moccu == "Inspecting Magistrate"] = 1
ang$moccu[ang$moccu == "Inspector"] = 2
ang$moccu[ang$moccu == "Inspector - Austin Motors"] = 2
ang$moccu[ang$moccu == "Inspector A.B.C. Co."] = 2
ang$moccu[ang$moccu == "Inspector of Music"] = 2
ang$moccu[ang$moccu == "Inspector of Post Offices"] = 2
ang$moccu[ang$moccu == "Inspector of Water Works"] = 2
ang$moccu[ang$moccu == "Inspector Police"] = 2
ang$moccu[ang$moccu == "Instructor"] = 1
ang$moccu[ang$moccu == "Instructor Alexandra Institute"] = 1
ang$moccu[ang$moccu == "Instructor in Chemical Engineering"] = 0
ang$moccu[ang$moccu == "Instructor R.A.F."] = 0
ang$moccu[ang$moccu == "Instructor S.A.A.F."] = 0
ang$moccu[ang$moccu == "Instrument Maker"] = 7
ang$moccu[ang$moccu == "Instrument Repairer"] = 7
ang$moccu[ang$moccu == "Insulating Foreman"] = 2
ang$moccu[ang$moccu == "Insurance"] = 4
ang$moccu[ang$moccu == "Insurance Accountant"] = 1
ang$moccu[ang$moccu == "Insurance Agent"] = 4
ang$moccu[ang$moccu == "Insurance Assessor"] = 4
ang$moccu[ang$moccu == "Insurance Broker"] = 4
ang$moccu[ang$moccu == "Insurance broker"] = 4
ang$moccu[ang$moccu == "Insurance Clerk"] = 3
ang$moccu[ang$moccu == "Insurance clerk"] = 3
ang$moccu[ang$moccu == "Insurance Collector"] = 4
ang$moccu[ang$moccu == "Insurance Inspector"] = 2
ang$moccu[ang$moccu == "Insurance Manager"] = 2
ang$moccu[ang$moccu == "Insurance Officer"] = 4
ang$moccu[ang$moccu == "Insurance Official"] = 4
ang$moccu[ang$moccu == "Insurance Representative"] = 4
ang$moccu[ang$moccu == "Insurance Secretary"] = 3
ang$moccu[ang$moccu == "Insurance Superintendent"] = 2
ang$moccu[ang$moccu == "Insurance Surveyor"] = 0
ang$moccu[ang$moccu == "Insurance Traveller"] = 4
ang$moccu[ang$moccu == "Intaglio Printer Cape Times"] = 9
ang$moccu[ang$moccu == "Interior Decorator"] = 9
ang$moccu[ang$moccu == "Interior Decorator + Signwriter"] = 9
ang$moccu[ang$moccu == "Interior Decprator"] = 9
ang$moccu[ang$moccu == "Inter-lining Cutter Clothing Industry"] = 7
ang$moccu[ang$moccu == "Interpreter"] = 1
ang$moccu[ang$moccu == "Interpreter System Manager"] = 1
ang$moccu[ang$moccu == "Invoice Clerk"] = 3
ang$moccu[ang$moccu == "Irish Linen Agent"] = 7
ang$moccu[ang$moccu == "Iron & Steel Mechanic"] = 8
ang$moccu[ang$moccu == "Iron Moulder"] = 8
ang$moccu[ang$moccu == "Iron moulder"] = 8
ang$moccu[ang$moccu == "Iron Turner S.A.R."] = 8
ang$moccu[ang$moccu == "Iron water maker"] = 8
ang$moccu[ang$moccu == "Ironer"] = 7
ang$moccu[ang$moccu == "Ironmaster"] = 4
ang$moccu[ang$moccu == "Ironmonger"] = 4
ang$moccu[ang$moccu == "Ironmonger Assistant"] = 8
ang$moccu[ang$moccu == "Ironmongers Salesman"] = 4
ang$moccu[ang$moccu == "Ironmoulder"] = 8
ang$moccu[ang$moccu == "Iron-moulder"] = 8
ang$moccu[ang$moccu == "Ironworker"] = 8
ang$moccu[ang$moccu == "Iron-works Moulder"] = 8
ang$moccu[ang$moccu == "Irrigation Engineer"] = 0
ang$moccu[ang$moccu == "Jeweler"] = 8
ang$moccu[ang$moccu == "Jeweller"] = 8
ang$moccu[ang$moccu == "Jeweller-Polisher"] = 8
ang$moccu[ang$moccu == "Jewellers Apprentice"] = 8
ang$moccu[ang$moccu == "Jewellers Mechanic"] = 8
ang$moccu[ang$moccu == "Jig + Tool Fitter AC.1. R.A.F."] = 8
ang$moccu[ang$moccu == "Jockey"] = 1
ang$moccu[ang$moccu == "Joiner"] = 9
ang$moccu[ang$moccu == "Joiner + Fitter"] = 9
ang$moccu[ang$moccu == "Joinery Manufacturer"] = 9
ang$moccu[ang$moccu == "Joint Manager, Consolidated Gold Fields, Johannesburg"] = 2
ang$moccu[ang$moccu == "Jointer"] = 9
ang$moccu[ang$moccu == "Jointers mate G.P.O. Telephones"] = 9
ang$moccu[ang$moccu == "Journalist"] = 1
ang$moccu[ang$moccu == "Journeyman"] = 9
ang$moccu[ang$moccu == "Journeyman printer"] = 9
ang$moccu[ang$moccu == "Judge"] = 1
ang$moccu[ang$moccu == "Judges Registrar"] = 1
ang$moccu[ang$moccu == "Junior Bookkeeper"] = 3
ang$moccu[ang$moccu == "Junior Clerk"] = 3
ang$moccu[ang$moccu == "Junior Executive"] = 2
ang$moccu[ang$moccu == "Junior Lecturer"] = 1
ang$moccu[ang$moccu == "Kerb-layer"] = 9
ang$moccu[ang$moccu == "Kitchen boy"] = 5
ang$moccu[ang$moccu == "Kitchen Boy"] = 5
ang$moccu[ang$moccu == "Kitchen worker"] = 5
ang$moccu[ang$moccu == "Kitchenboy"] = 5
ang$moccu[ang$moccu == "Kitchen-boy"] = 5
ang$moccu[ang$moccu == "Knitter"] = 7
ang$moccu[ang$moccu == "Knitter at a Factory"] = 7
ang$moccu[ang$moccu == "Knitting Machine Operator"] = 8
ang$moccu[ang$moccu == "Knitting Mechanic"] = 8
ang$moccu[ang$moccu == "Knocker-on"] = NA
ang$moccu[ang$moccu == "Kruman Royal Navy"] = 5
ang$moccu[ang$moccu == "L.A.C. Air Force"] = 5
ang$moccu[ang$moccu == "L.A.C. Royal Air Force"] = 5
ang$moccu[ang$moccu == "L.R.E.M. Royal Navy"] = 8
ang$moccu[ang$moccu == "LErm"] = NA
ang$moccu[ang$moccu == "Laboratory Apprentice"] = 0
ang$moccu[ang$moccu == "Laboratory Assistant"] = 0
ang$moccu[ang$moccu == "Laboratory Attendant"] = 0
ang$moccu[ang$moccu == "Laboratory labourer"] = 0
ang$moccu[ang$moccu == "Laboratory Servant"] = 0
ang$moccu[ang$moccu == "Laboratory Technician"] = 0
ang$moccu[ang$moccu == "Laboratory worker"] = 0
ang$moccu[ang$moccu == "Laboratory-assistant"] = 0
ang$moccu[ang$moccu == "Labour"] = 9
ang$moccu[ang$moccu == "Laboure"] = 9
ang$moccu[ang$moccu == "Labourer"] = 9
ang$moccu[ang$moccu == "labourer"] = 9
ang$moccu[ang$moccu == "Labourer "] = 9
ang$moccu[ang$moccu == "Labourer (Baker)"] = 5
ang$moccu[ang$moccu == "Labourer (City Council)"] = 9
ang$moccu[ang$moccu == "Labourer (Corporation)"] = 9
ang$moccu[ang$moccu == "Labourer (Lighthouse)"] = 9
ang$moccu[ang$moccu == "Labourer (Municipal Corporation)"] = 9
ang$moccu[ang$moccu == "Labourer (Presser)"] = 9
ang$moccu[ang$moccu == "Labourer + Preacher"] = 9
ang$moccu[ang$moccu == "Labourer at brickfields"] = 9
ang$moccu[ang$moccu == "Labourer at Brickworks"] = 9
ang$moccu[ang$moccu == "Labourer at furniture factory"] = 9
ang$moccu[ang$moccu == "Labourer at Gas Works"] = 9
ang$moccu[ang$moccu == "Labourer at Match Factory"] = 9
ang$moccu[ang$moccu == "Labourer at Motor Plant"] = 9
ang$moccu[ang$moccu == "Labourer at Plywoods"] = 9
ang$moccu[ang$moccu == "Labourer at Power Station"] = 9
ang$moccu[ang$moccu == "Labourer Biscuit Factory"] = 9
ang$moccu[ang$moccu == "Labourer C T Corporation"] = 9
ang$moccu[ang$moccu == "Labourer C.C. Council"] = 9
ang$moccu[ang$moccu == "Labourer Cape Corps"] = 9
ang$moccu[ang$moccu == "Labourer Cartage Contractor"] = 9
ang$moccu[ang$moccu == "Labourer Catering Dept. SAR"] = 9
ang$moccu[ang$moccu == "Labourer City Corporation"] = 9
ang$moccu[ang$moccu == "Labourer City Council"] = 9
ang$moccu[ang$moccu == "Labourer Cleansing Dept."] = 9
ang$moccu[ang$moccu == "Labourer Divisional Council"] = 9
ang$moccu[ang$moccu == "Labourer Electricity Department"] = 9
ang$moccu[ang$moccu == "Labourer Electricity Power station"] = 9
ang$moccu[ang$moccu == "Labourer Engineering Works"] = 0
ang$moccu[ang$moccu == "Labourer for Cabinet Maker"] = 8
ang$moccu[ang$moccu == "Labourer for City Council"] = 9
ang$moccu[ang$moccu == "Labourer for Corporation"] = 9
ang$moccu[ang$moccu == "Labourer for firm"] = 9
ang$moccu[ang$moccu == "Labourer for Shipping Engineers"] = 9
ang$moccu[ang$moccu == "Labourer Forestry Dept."] = 6
ang$moccu[ang$moccu == "Labourer G.P.O."] = 9
ang$moccu[ang$moccu == "Labourer Goods Station"] = 9
ang$moccu[ang$moccu == "Labourer Goods Store S.A.R."] = 9
ang$moccu[ang$moccu == "Labourer Harbour Board"] = 9
ang$moccu[ang$moccu == "Labourer Harbour Works"] = 9
ang$moccu[ang$moccu == "Labourer in Arsenal"] = 9
ang$moccu[ang$moccu == "Labourer in Brewery"] = 9
ang$moccu[ang$moccu == "Labourer in Brick Works"] = 9
ang$moccu[ang$moccu == "Labourer in Building Trade"] = 9
ang$moccu[ang$moccu == "Labourer in Cabinet Works"] = 9
ang$moccu[ang$moccu == "Labourer in Cable Dept."] = 9
ang$moccu[ang$moccu == "Labourer in Cement Works"] = 9
ang$moccu[ang$moccu == "Labourer in Engineering Works"] = 9
ang$moccu[ang$moccu == "Labourer in Factory"] = 9
ang$moccu[ang$moccu == "Labourer in Fertilizer factory"] = 9
ang$moccu[ang$moccu == "Labourer in Furniture Factory"] = 9
ang$moccu[ang$moccu == "Labourer in G.P.O."] = 9
ang$moccu[ang$moccu == "Labourer in Garage"] = 9
ang$moccu[ang$moccu == "Labourer in Gasworks"] = 9
ang$moccu[ang$moccu == "Labourer in Lead Works"] = 9
ang$moccu[ang$moccu == "Labourer in printing industry"] = 9
ang$moccu[ang$moccu == "Labourer in Sanitary Dept."] = 9
ang$moccu[ang$moccu == "Labourer in Saw Mill"] = 9
ang$moccu[ang$moccu == "Labourer in Sweet Factory"] = 9
ang$moccu[ang$moccu == "Labourer in Tannery"] = 8
ang$moccu[ang$moccu == "Labourer in Tea Factory + Soldier"] = 9
ang$moccu[ang$moccu == "Labourer in Telegraph Dept."] = 9
ang$moccu[ang$moccu == "Labourer in Timber Yard"] = 9
ang$moccu[ang$moccu == "Labourer in Tramway Co."] = 9
ang$moccu[ang$moccu == "Labourer in Tyres Ltd."] = 9
ang$moccu[ang$moccu == "Labourer in Vinegar Factory"] = 9
ang$moccu[ang$moccu == "Labourer in Wine Store"] = 9
ang$moccu[ang$moccu == "Labourer in Winery"] = 9
ang$moccu[ang$moccu == "Labourer Municipality"] = 9
ang$moccu[ang$moccu == "Labourer Ohlssons Brewery"] = 9
ang$moccu[ang$moccu == "Labourer On Active Service"] = 9
ang$moccu[ang$moccu == "Labourer on Active Service"] = 9
ang$moccu[ang$moccu == "Labourer on Poultry Farm"] = 6
ang$moccu[ang$moccu == "Labourer on Railway"] = 9
ang$moccu[ang$moccu == "Labourer on Tramway"] = 9
ang$moccu[ang$moccu == "Labourer on Trawler"] = 9
ang$moccu[ang$moccu == "Labourer Plywood Ltd."] = 9
ang$moccu[ang$moccu == "Labourer Plywoods Ltd."] = 9
ang$moccu[ang$moccu == "Labourer Power Station"] = 9
ang$moccu[ang$moccu == "Labourer Royal Navy"] = 9
ang$moccu[ang$moccu == "Labourer S.A.R."] = 9
ang$moccu[ang$moccu == "Labourer S.A.R.+H. (On Military Service)"] = 9
ang$moccu[ang$moccu == "Labourer Salt River Works"] = 9
ang$moccu[ang$moccu == "Labourer Salt River Workshops"] = 9
ang$moccu[ang$moccu == "Labourer Tennis Racquet Stringer"] = 9
ang$moccu[ang$moccu == "Labourer Tennis-racket Stringer"] = 9
ang$moccu[ang$moccu == "Labourer Timber Merchant"] = 9
ang$moccu[ang$moccu == "Labourer(Abattoir)"] = 9
ang$moccu[ang$moccu == "Labourer(Cook)"] = 9
ang$moccu[ang$moccu == "Labourer(Mechanic Hand)"] = 9
ang$moccu[ang$moccu == "Labourer(Motor driver)"] = 9
ang$moccu[ang$moccu == "Labourer(now Soldier in Cape Corps)"] = 9
ang$moccu[ang$moccu == "Labourer(Parks + Gardens)"] = 6
ang$moccu[ang$moccu == "Labourer, Cape Corps"] = 9
ang$moccu[ang$moccu == "Labourer, City Council"] = 9
ang$moccu[ang$moccu == "Labourer: Corporation stables"] = 9
ang$moccu[ang$moccu == "Labourers Council"] = NA
ang$moccu[ang$moccu == "Labourr"] = 9
ang$moccu[ang$moccu == "Ladies Hairdresser"] = 5
ang$moccu[ang$moccu == "Lamplighter"] = 9
ang$moccu[ang$moccu == "Lamp-man S.A.R."] = 9
ang$moccu[ang$moccu == "Lance Bombardier Royal Artillery"] = 5
ang$moccu[ang$moccu == "Lance Corporal"] = 5
ang$moccu[ang$moccu == "Lance Corporal Cape Corps"] = 5
ang$moccu[ang$moccu == "Lance Corporal Cyclist Corps"] = 5
ang$moccu[ang$moccu == "Lance Corporal S.A. Artillery"] = 5
ang$moccu[ang$moccu == "Lance Corporal S.A. Permanent Force"] = 5
ang$moccu[ang$moccu == "Lance Corporal S.A.T.C."] = 5
ang$moccu[ang$moccu == "Lance Corporal Yorks Regiment"] = 5
ang$moccu[ang$moccu == "Lance-Bombardier"] = 5
ang$moccu[ang$moccu == "Lance-Corporal C.T. Highlanders"] = 5
ang$moccu[ang$moccu == "Land Surveyor"] = 0
ang$moccu[ang$moccu == "Land Surveyor, Captain S.A. Engineering Corps"] = 0
ang$moccu[ang$moccu == "Landscape Gardener"] = 6
ang$moccu[ang$moccu == "Landscape gardener"] = 6
ang$moccu[ang$moccu == "Land-Surveyor"] = 0
ang$moccu[ang$moccu == "Last Slipper"] = 8
ang$moccu[ang$moccu == "Laster"] = 8
ang$moccu[ang$moccu == "Lasterer"] = 8
ang$moccu[ang$moccu == "Laundry Checker"] = 3
ang$moccu[ang$moccu == "Laundry Manager"] = 2
ang$moccu[ang$moccu == "Laundry Worker"] = 5
ang$moccu[ang$moccu == "Laundry worker"] = 5
ang$moccu[ang$moccu == "Laundryman"] = 5
ang$moccu[ang$moccu == "Law Clerk"] = 3
ang$moccu[ang$moccu == "Law Doctor"] = 1
ang$moccu[ang$moccu == "Lawyer"] = 1
ang$moccu[ang$moccu == "Layer-up"] = NA
ang$moccu[ang$moccu == "Lead Burner"] = 8
ang$moccu[ang$moccu == "Leaded Light Worker"] = 8
ang$moccu[ang$moccu == "Leader Light-maker"] = 8
ang$moccu[ang$moccu == "Leading Air Fitter"] = 8
ang$moccu[ang$moccu == "Leading Air Fitter "] = 8
ang$moccu[ang$moccu == "Leading Air Mechanic F.A.A."] = 8
ang$moccu[ang$moccu == "Leading Air Mechanic R.N.A.S."] = 8
ang$moccu[ang$moccu == "Leading Aircraftsman R.A.F."] = 5
ang$moccu[ang$moccu == "Leading Aircraftsman Royal Air Force"] = 5
ang$moccu[ang$moccu == "Leading Cleaner S.A.R."] = 5
ang$moccu[ang$moccu == "Leading Coder R.N."] = 0
ang$moccu[ang$moccu == "Leading Cook"] = 5
ang$moccu[ang$moccu == "Leading Cook R.N."] = 5
ang$moccu[ang$moccu == "Leading Cook Royal Navy"] = 5
ang$moccu[ang$moccu == "Leading Electrician R.N."] = 8
ang$moccu[ang$moccu == "Leading Engine Room Artificer"] = 8
ang$moccu[ang$moccu == "Leading Engine Room Mechanic S.A. Navy"] = 8
ang$moccu[ang$moccu == "Leading Mechanical Engineer"] = 0
ang$moccu[ang$moccu == "Leading Motor Mechanic R.N."] = 8
ang$moccu[ang$moccu == "Leading Radio Electrical Mechanic, Royal Navy"] = 8
ang$moccu[ang$moccu == "Leading Seaman"] = 5
ang$moccu[ang$moccu == "Leading Seaman R.N."] = 5
ang$moccu[ang$moccu == "Leading Seaman S.A. Navy"] = 5
ang$moccu[ang$moccu == "Leading Seaman S.A.N.F."] = 5
ang$moccu[ang$moccu == "Leading Shunter Rhodesia Railways"] = 9
ang$moccu[ang$moccu == "Leading Sickbay Attendant R.N."] = 0
ang$moccu[ang$moccu == "Leading Signalman"] = 9
ang$moccu[ang$moccu == "Leading Signalman R.N."] = 9
ang$moccu[ang$moccu == "Leading Signalman S.A. Navy"] = 9
ang$moccu[ang$moccu == "Leading Stoker"] = 9
ang$moccu[ang$moccu == "Leading Stoker R.N."] = 9
ang$moccu[ang$moccu == "Leading Stoker Royal Australian Navy"] = 9
ang$moccu[ang$moccu == "Leading Stoker Royal Navy"] = 9
ang$moccu[ang$moccu == "Leading Stoker S.A.N.F."] = 9
ang$moccu[ang$moccu == "Leading Storeman S.A. Navy"] = 4
ang$moccu[ang$moccu == "Leading Telegraphist"] = 3
ang$moccu[ang$moccu == "Leading Telegraphist R.N."] = 3
ang$moccu[ang$moccu == "Leading Telegraphist Royal Navy"] = 3
ang$moccu[ang$moccu == "Leading Writer R.N."] = 1
ang$moccu[ang$moccu == "Leading Writer, Royal Navy"] = 1
ang$moccu[ang$moccu == "Learner Barman"] = 5
ang$moccu[ang$moccu == "Learner Bricklayer"] = 9
ang$moccu[ang$moccu == "Learner Cable Jointer"] = 8
ang$moccu[ang$moccu == "Learner Carpenter"] = 8
ang$moccu[ang$moccu == "Learner Cutter"] = 7
ang$moccu[ang$moccu == "Learner Draughtsman"] = 7
ang$moccu[ang$moccu == "Learner Glass Cutter"] = 8
ang$moccu[ang$moccu == "Learner Health Inspector"] = 2
ang$moccu[ang$moccu == "Learner Linesman"] = 8
ang$moccu[ang$moccu == "Learner Motor Trade"] = 9
ang$moccu[ang$moccu == "Learner Platelayer"] = 9
ang$moccu[ang$moccu == "Learner Printer"] = 9
ang$moccu[ang$moccu == "Learner Station Foreman S.A.R."] = 2
ang$moccu[ang$moccu == "Leather Cutter"] = 8
ang$moccu[ang$moccu == "Leather Industry"] = 8
ang$moccu[ang$moccu == "Leather Sorter"] = 8
ang$moccu[ang$moccu == "Leather stainer"] = 8
ang$moccu[ang$moccu == "Leather Stainer"] = 8
ang$moccu[ang$moccu == "Leather Trade"] = 4
ang$moccu[ang$moccu == "Leather worker"] = 8
ang$moccu[ang$moccu == "Leather Worker"] = 8
ang$moccu[ang$moccu == "Leatherworker"] = 8
ang$moccu[ang$moccu == "Leather-worker"] = 8
ang$moccu[ang$moccu == "Lecturer"] = 1
ang$moccu[ang$moccu == "Lecturer in Botany"] = 1
ang$moccu[ang$moccu == "Lecturer in Engineering"] = 0
ang$moccu[ang$moccu == "Lecturer in Geology, Witwatersrand Univ."] = 1
ang$moccu[ang$moccu == "Lecturer in Zoology"] = 1
ang$moccu[ang$moccu == "Lecturer Technical College"] = 1
ang$moccu[ang$moccu == "Lecturer, U.C.T."] = 1
ang$moccu[ang$moccu == "Lecturers assistant"] = 1
ang$moccu[ang$moccu == "Ledger Clerk"] = 3
ang$moccu[ang$moccu == "Ledger-Clerk"] = 3
ang$moccu[ang$moccu == "Legal"] = NA
ang$moccu[ang$moccu == "Legal Adviser"] = 1
ang$moccu[ang$moccu == "Legal Articled Clerk"] = 3
ang$moccu[ang$moccu == "Legal Clerk, presently with H.M. Forces"] = 3
ang$moccu[ang$moccu == "Lemonade manufacturer"] = 7
ang$moccu[ang$moccu == "Lending Waiter R.N.V.R."] = 5
ang$moccu[ang$moccu == "Lens Surfacer"] = 8
ang$moccu[ang$moccu == "Leper Ward Assistant"] = 0
ang$moccu[ang$moccu == "Letter carrier"] = 3
ang$moccu[ang$moccu == "Letter Carrier"] = 3
ang$moccu[ang$moccu == "Letter Carrier G.P.O."] = 3
ang$moccu[ang$moccu == "Letter Carrier(Green Point)"] = 3
ang$moccu[ang$moccu == "Letter Sorter G.P.O."] = 3
ang$moccu[ang$moccu == "Lever Bros."] = 9
ang$moccu[ang$moccu == "Liaison"] = 9
ang$moccu[ang$moccu == "Librarian"] = 1
ang$moccu[ang$moccu == "Licence Inspector Cape Town"] = 2
ang$moccu[ang$moccu == "Licensed Victualler"] = 4
ang$moccu[ang$moccu == "Lieut. R.N.R."] = 5
ang$moccu[ang$moccu == "Lieut. R.N.V.R."] = 5
ang$moccu[ang$moccu == "Lieut. Regular Army, British"] = 5
ang$moccu[ang$moccu == "Lieut. Royal Air Force"] = 5
ang$moccu[ang$moccu == "Lieut. Royal Artillery"] = 5
ang$moccu[ang$moccu == "Lieut. Royal Marines"] = 5
ang$moccu[ang$moccu == "Lieut. Royal Naval Volunteer Reserve"] = 5
ang$moccu[ang$moccu == "Lieut. Royal Navy"] = 5
ang$moccu[ang$moccu == "Lieut. S.A. Air Force"] = 5
ang$moccu[ang$moccu == "Lieut. S.A. Army"] = 5
ang$moccu[ang$moccu == "Lieut. S.A. Corps of Marines"] = 5
ang$moccu[ang$moccu == "Lieut. S.A. Corps of Signallers"] = 5
ang$moccu[ang$moccu == "Lieut. S.A. Mounted Rifles"] = 5
ang$moccu[ang$moccu == "Lieut. S.A.A.F."] = 5
ang$moccu[ang$moccu == "Lieut. S.A.M.R. Artillery"] = 5
ang$moccu[ang$moccu == "Lieut. S.A.N.F."] = 5
ang$moccu[ang$moccu == "Lieut. South African Air Force"] = 5
ang$moccu[ang$moccu == "Lieut. South African Artillery"] = 5
ang$moccu[ang$moccu == "Lieut.-Commander S.A. Navy"] = 5
ang$moccu[ang$moccu == "Lieutenant"] = 5
ang$moccu[ang$moccu == "Lieutenant "] = 5
ang$moccu[ang$moccu == "Lieutenant 1st Battery"] = 5
ang$moccu[ang$moccu == "Lieutenant 59th Reg."] = 5
ang$moccu[ang$moccu == "Lieutenant Armed Service Corps"] = 5
ang$moccu[ang$moccu == "Lieutenant C.M.R."] = 5
ang$moccu[ang$moccu == "Lieutenant Commander R.N."] = 5
ang$moccu[ang$moccu == "Lieutenant Commander Royal Navy"] = 5
ang$moccu[ang$moccu == "Lieutenant Commander S.A.N.F."] = 5
ang$moccu[ang$moccu == "Lieutenant of General Service"] = 5
ang$moccu[ang$moccu == "Lieutenant R.G.A."] = 5
ang$moccu[ang$moccu == "Lieutenant R.N."] = 5
ang$moccu[ang$moccu == "Lieutenant Royal Field Artillery"] = 5
ang$moccu[ang$moccu == "Lieutenant Royal Fusiliers"] = 5
ang$moccu[ang$moccu == "Lieutenant Royal Naval Reserve"] = 5
ang$moccu[ang$moccu == "Lieutenant Royal Navy"] = 0
ang$moccu[ang$moccu == "Lieutenant S.A. Air Force"] = 5
ang$moccu[ang$moccu == "Lieutenant S.A. Engineering Corps"] = 0
ang$moccu[ang$moccu == "Lieutenant S.A. Naval Services"] = 5
ang$moccu[ang$moccu == "Lieutenant S.A. Tank Corps"] = 5
ang$moccu[ang$moccu == "Lieutenant S.A.A.F."] = 5
ang$moccu[ang$moccu == "Lieutenant U.D. Force"] = 5
ang$moccu[ang$moccu == "Lieutenant Union Defence Force"] = 5
ang$moccu[ang$moccu == "Lieutenant, Royal Scots Greys"] = 5
ang$moccu[ang$moccu == "Lieutenant, S.A.C."] = 5
ang$moccu[ang$moccu == "Life Assurance Manager"] = 2
ang$moccu[ang$moccu == "Life Assurance Official"] = 4
ang$moccu[ang$moccu == "Life insurance Manager"] = 2
ang$moccu[ang$moccu == "Lift Attendant"] = 5
ang$moccu[ang$moccu == "Lift Electrician"] = 8
ang$moccu[ang$moccu == "Lift Mechanic"] = 8
ang$moccu[ang$moccu == "Lift Operator"] = 8
ang$moccu[ang$moccu == "Lift-attendantWaiter"] = 5
ang$moccu[ang$moccu == "Lift-driver"] = 8
ang$moccu[ang$moccu == "Lifter"] = 9
ang$moccu[ang$moccu == "Liftman"] = 5
ang$moccu[ang$moccu == "Lift-man"] = 5
ang$moccu[ang$moccu == "Light Keeper"] = 9
ang$moccu[ang$moccu == "Lighter Coxswain"] = 9
ang$moccu[ang$moccu == "Lighterman"] = 9
ang$moccu[ang$moccu == "Lighthouse"] = 9
ang$moccu[ang$moccu == "Lighthouse Keeper"] = 9
ang$moccu[ang$moccu == "Lighting Engineer"] = 0
ang$moccu[ang$moccu == "Limeburner"] = 7
ang$moccu[ang$moccu == "Lime-burner"] = 7
ang$moccu[ang$moccu == "Linesman"] = 8
ang$moccu[ang$moccu == "Linesman "] = 8
ang$moccu[ang$moccu == "Linesman C.C.C."] = 8
ang$moccu[ang$moccu == "Linesman Electric Dept."] = 8
ang$moccu[ang$moccu == "Linesman G.P.O."] = 8
ang$moccu[ang$moccu == "Linesman Telegraph Dept"] = 8
ang$moccu[ang$moccu == "Linesman Telephone Dept. Post Office"] = 8
ang$moccu[ang$moccu == "Linesman to the Diver"] = 8
ang$moccu[ang$moccu == "Lining Cutter"] = 7
ang$moccu[ang$moccu == "Lining cutter"] = 7
ang$moccu[ang$moccu == "Lining sticker Leather Industry"] = 8
ang$moccu[ang$moccu == "Lino Operator"] = 9
ang$moccu[ang$moccu == "Lino Type Operator"] = 9
ang$moccu[ang$moccu == "Linolithic Worker"] = 9
ang$moccu[ang$moccu == "Linotype Operator"] = 9
ang$moccu[ang$moccu == "Lion-keeper"] = 6
ang$moccu[ang$moccu == "Liquor Merchant"] = 4
ang$moccu[ang$moccu == "Liquor Representative"] = 4
ang$moccu[ang$moccu == "Litho Printers assistant"] = 9
ang$moccu[ang$moccu == "Lithographer"] = 9
ang$moccu[ang$moccu == "Lithographic Artist"] = 1
ang$moccu[ang$moccu == "Litographer"] = 9
ang$moccu[ang$moccu == "Livestock Dealer"] = 4
ang$moccu[ang$moccu == "Locksmith"] = 8
ang$moccu[ang$moccu == "Loco-fireman S.A.R."] = 9
ang$moccu[ang$moccu == "Locomotive Driver"] = 9
ang$moccu[ang$moccu == "Locomotive Driver S.A.R."] = 9
ang$moccu[ang$moccu == "Locomotive Fireman"] = 9
ang$moccu[ang$moccu == "Locomotive Fitter"] = 8
ang$moccu[ang$moccu == "Locomotive Inspector"] = 2
ang$moccu[ang$moccu == "Loom Tuner"] = 2
ang$moccu[ang$moccu == "Loom Turner"] = 2
ang$moccu[ang$moccu == "Loom Turner Cape Woollen Mills"] = 2
ang$moccu[ang$moccu == "Lorry Attendant"] = 9
ang$moccu[ang$moccu == "Lorry boy"] = 9
ang$moccu[ang$moccu == "Lorry Conductor"] = 9
ang$moccu[ang$moccu == "Lorry Conductor S.A.R."] = 9
ang$moccu[ang$moccu == "Lorry driver"] = 9
ang$moccu[ang$moccu == "Lorry Driver"] = 9
ang$moccu[ang$moccu == "Lorry driver Municipality"] = 9
ang$moccu[ang$moccu == "Lorry guard"] = 9
ang$moccu[ang$moccu == "Lorry Guard"] = 9
ang$moccu[ang$moccu == "Lorry Guard "] = 9
ang$moccu[ang$moccu == "Lorry Guard for Milling Co."] = 9
ang$moccu[ang$moccu == "Lorry Guard Milling Co."] = 9
ang$moccu[ang$moccu == "Lorry hand"] = 9
ang$moccu[ang$moccu == "Lorry-boy"] = 9
ang$moccu[ang$moccu == "Lorry-driver"] = 9
ang$moccu[ang$moccu == "Lorry-guard"] = 9
ang$moccu[ang$moccu == "Lorryman"] = 9
ang$moccu[ang$moccu == "Lorry-man"] = 9
ang$moccu[ang$moccu == "Lorryman for Petrol Co."] = 9
ang$moccu[ang$moccu == "Lsbourer"] = 9
ang$moccu[ang$moccu == "Lt. S.A.A."] = 5
ang$moccu[ang$moccu == "Lubrication Mechanic"] = 8
ang$moccu[ang$moccu == "M.B."] = NA
ang$moccu[ang$moccu == "M.D."] = NA
ang$moccu[ang$moccu == "M.L.A."] = NA
ang$moccu[ang$moccu == "M.S.A."] = NA
ang$moccu[ang$moccu == "Machine Adjuster"] = 8
ang$moccu[ang$moccu == "Machine attendant"] = 8
ang$moccu[ang$moccu == "Machine Attendant"] = 8
ang$moccu[ang$moccu == "Machine Feeder"] = 8
ang$moccu[ang$moccu == "Machine Fitter"] = 8
ang$moccu[ang$moccu == "Machine Hand"] = 8
ang$moccu[ang$moccu == "Machine hand"] = 8
ang$moccu[ang$moccu == "Machine man C.G.R."] = 8
ang$moccu[ang$moccu == "Machine Mechanic"] = 8
ang$moccu[ang$moccu == "Machine Mender"] = 9
ang$moccu[ang$moccu == "Machine mender"] = 9
ang$moccu[ang$moccu == "Machine Minder"] = 9
ang$moccu[ang$moccu == "Machine minder"] = 9
ang$moccu[ang$moccu == "Machine Minder Tobacco Manufacturer"] = 7
ang$moccu[ang$moccu == "Machine Moulder"] = 8
ang$moccu[ang$moccu == "Machine Operator"] = 8
ang$moccu[ang$moccu == "Machine Sander"] = 8
ang$moccu[ang$moccu == "Machine Storekeepers Assistant"] = 4
ang$moccu[ang$moccu == "Machine Tool Fitter and Adjuster"] = 8
ang$moccu[ang$moccu == "Machine-feeder"] = 9
ang$moccu[ang$moccu == "Machine-hand"] = 9
ang$moccu[ang$moccu == "Machine-Hand Cabinet Works"] = 9
ang$moccu[ang$moccu == "Machine-minder"] = 9
ang$moccu[ang$moccu == "Machine-Sander"] = 8
ang$moccu[ang$moccu == "Machinist"] = 8
ang$moccu[ang$moccu == "Machinist (Boot Trade)"] = 8
ang$moccu[ang$moccu == "Machinist (Furniture Trade)"] = 8
ang$moccu[ang$moccu == "Machinist (Match Factory)"] = 8
ang$moccu[ang$moccu == "Machinist (On Active Service)"] = 8
ang$moccu[ang$moccu == "Machinist Assistant "] = 9
ang$moccu[ang$moccu == "Machinist Assistant Wingfield"] = 9
ang$moccu[ang$moccu == "Machinist at Cabinet maker"] = 8
ang$moccu[ang$moccu == "Machinist Canning Co."] = 8
ang$moccu[ang$moccu == "Machinist in Blanket Factory"] = 8
ang$moccu[ang$moccu == "Machinist in Macaroni Factory"] = 8
ang$moccu[ang$moccu == "Machinist Leather Industry"] = 8
ang$moccu[ang$moccu == "Machinist Match Factory"] = 8
ang$moccu[ang$moccu == "Machinist Ohlssons Brewery"] = 8
ang$moccu[ang$moccu == "Machinist Paper Factory"] = 8
ang$moccu[ang$moccu == "Machinist Post Office"] = 8
ang$moccu[ang$moccu == "Machinist S.A.R."] = 8
ang$moccu[ang$moccu == "Machinist Tobacco Co."] = 8
ang$moccu[ang$moccu == "Machinist(Blanket factory)"] = 8
ang$moccu[ang$moccu == "Machinist(Woodwork)"] = 8
ang$moccu[ang$moccu == "Machinists assistant"] = 9
ang$moccu[ang$moccu == "Macine Knitter"] = 7
ang$moccu[ang$moccu == "Magistrate"] = 1
ang$moccu[ang$moccu == "Magistrate Middleburg"] = 1
ang$moccu[ang$moccu == "Magistrates Clerk"] = 3
ang$moccu[ang$moccu == "Mail Porter"] = 9
ang$moccu[ang$moccu == "Mail Porter G.P.O."] = 9
ang$moccu[ang$moccu == "Mailporter"] = 9
ang$moccu[ang$moccu == "Mailtrain Attendant"] = 3
ang$moccu[ang$moccu == "Maintenance Electrician"] = 8
ang$moccu[ang$moccu == "Maintenance Engineer"] = 0
ang$moccu[ang$moccu == "Maintenance Fitter"] = 8
ang$moccu[ang$moccu == "Maintenance Mechanic"] = 8
ang$moccu[ang$moccu == "Maintenance mechanic"] = 8
ang$moccu[ang$moccu == "Maintenance Supervisor Oil Company"] = 2
ang$moccu[ang$moccu == "Maintenance Worker"] = 9
ang$moccu[ang$moccu == "Major"] = 5
ang$moccu[ang$moccu == "Major "] = 5
ang$moccu[ang$moccu == "Major 5th African Artillery"] = 5
ang$moccu[ang$moccu == "Major Apprentice, Instrument Mechanician"] = 5
ang$moccu[ang$moccu == "Major British Army"] = 5
ang$moccu[ang$moccu == "Major in Regular Forces"] = 5
ang$moccu[ang$moccu == "Major Royal Marines"] = 5
ang$moccu[ang$moccu == "Major S.A.A.F."] = 5
ang$moccu[ang$moccu == "Male Attendant"] = 5
ang$moccu[ang$moccu == "Male Nurse"] = 0
ang$moccu[ang$moccu == "Male Nurse Assistant"] = 0
ang$moccu[ang$moccu == "Male Officer G.P.O."] = 5
ang$moccu[ang$moccu == "Malster in Plywood factory"] = 7
ang$moccu[ang$moccu == "Maltman"] = 7
ang$moccu[ang$moccu == "Maltster"] = 7
ang$moccu[ang$moccu == "Man servant"] = 5
ang$moccu[ang$moccu == "Management Trainee"] = 2
ang$moccu[ang$moccu == "Manager"] = 2
ang$moccu[ang$moccu == "Manager (Ink Factory)"] = 2
ang$moccu[ang$moccu == "Manager African Garages"] = 2
ang$moccu[ang$moccu == "Manager at Abattoir"] = 2
ang$moccu[ang$moccu == "Manager Boarding House"] = 2
ang$moccu[ang$moccu == "Manager Boot Store"] = 2
ang$moccu[ang$moccu == "Manager Cold Storage"] = 2
ang$moccu[ang$moccu == "Manager Cycle Co."] = 2
ang$moccu[ang$moccu == "Manager General Merchant"] = 2
ang$moccu[ang$moccu == "Manager Greens Store"] = 2
ang$moccu[ang$moccu == "Manager in Carriage Manufacturer"] = 2
ang$moccu[ang$moccu == "Manager in Ford Company"] = 2
ang$moccu[ang$moccu == "Manager National Trawling + Fishing Co."] = 2
ang$moccu[ang$moccu == "Manager of Furnishing Business"] = 2
ang$moccu[ang$moccu == "Manager of Insurance Co."] = 2
ang$moccu[ang$moccu == "Manager of Rhodes Fruit Farms"] = 2
ang$moccu[ang$moccu == "Manager of Wine State"] = 2
ang$moccu[ang$moccu == "Manager Rainbow Paints"] = 2
ang$moccu[ang$moccu == "Manager Sweet Factory"] = 2
ang$moccu[ang$moccu == "Manager Timber Trade"] = 2
ang$moccu[ang$moccu == "Manager Vacuum Oil Co."] = 2
ang$moccu[ang$moccu == "Manager, Altwell Baking Company"] = 2
ang$moccu[ang$moccu == "Manager, Cabinet Works"] = 2
ang$moccu[ang$moccu == "Manager, Samuel Griffiths + Co. Printers"] = 2
ang$moccu[ang$moccu == "Manager, Standard Property Assoc."] = 2
ang$moccu[ang$moccu == "Managerial Trainee"] = 2
ang$moccu[ang$moccu == "Managing Director"] = 2
ang$moccu[ang$moccu == "Managing Director Merchant Store"] = 2
ang$moccu[ang$moccu == "Man-servant"] = 5
ang$moccu[ang$moccu == "Manufacturer"] = 8
ang$moccu[ang$moccu == "Manufacturers Agent"] = 4
ang$moccu[ang$moccu == "Manufacturers Foreman"] = 2
ang$moccu[ang$moccu == "Manufacturers Representative"] = 4
ang$moccu[ang$moccu == "Manufacturing Confectioner"] = 7
ang$moccu[ang$moccu == "Manufacturing Jeweller"] = 8
ang$moccu[ang$moccu == "Manufacturing Operator"] = 8
ang$moccu[ang$moccu == "Manufacturing Representative"] = 4
ang$moccu[ang$moccu == "Manufacurers Agent"] = 4
ang$moccu[ang$moccu == "Marine"] = 5
ang$moccu[ang$moccu == "Marine Biologist"] = 0
ang$moccu[ang$moccu == "Marine Engine Driver"] = 9
ang$moccu[ang$moccu == "Marine Engineer"] = 0
ang$moccu[ang$moccu == "Marine Engineer S.A.R."] = 0
ang$moccu[ang$moccu == "Marine Fireman"] = 9
ang$moccu[ang$moccu == "Marine Fitter"] = 8
ang$moccu[ang$moccu == "Marine Geologist"] = 0
ang$moccu[ang$moccu == "Marine Insurance Official"] = 4
ang$moccu[ang$moccu == "Marine Officer"] = 5
ang$moccu[ang$moccu == "Marine Officer S.A.R.+H."] = 5
ang$moccu[ang$moccu == "Marine R.N."] = 5
ang$moccu[ang$moccu == "Marine Representative"] = 4
ang$moccu[ang$moccu == "Marine Superintendent"] = 2
ang$moccu[ang$moccu == "Marine Surveyor"] = 0
ang$moccu[ang$moccu == "Mariner"] = 5
ang$moccu[ang$moccu == "Marker"] = 3
ang$moccu[ang$moccu == "Marker "] = 3
ang$moccu[ang$moccu == "Market Agent"] = 4
ang$moccu[ang$moccu == "Market Assistant"] = 4
ang$moccu[ang$moccu == "Market Checker"] = 3
ang$moccu[ang$moccu == "Market gardener"] = 6
ang$moccu[ang$moccu == "Market Gardener"] = 6
ang$moccu[ang$moccu == "Market Porter"] = 9
ang$moccu[ang$moccu == "Market Researcher"] = 1
ang$moccu[ang$moccu == "Market Salesman"] = 4
ang$moccu[ang$moccu == "Market worker"] = 9
ang$moccu[ang$moccu == "Marketer and Merchandiser"] = 4
ang$moccu[ang$moccu == "Marketing Assistant "] = 4
ang$moccu[ang$moccu == "Marketing Research"] = 1
ang$moccu[ang$moccu == "Mason"] = 9
ang$moccu[ang$moccu == "Mason (On Military Service)"] = 9
ang$moccu[ang$moccu == "Mason S.A.R."] = 9
ang$moccu[ang$moccu == "Masons Assistant"] = 9
ang$moccu[ang$moccu == "Masons Labourer"] = 9
ang$moccu[ang$moccu == "Masons labourer"] = 9
ang$moccu[ang$moccu == "Masons man"] = 9
ang$moccu[ang$moccu == "Master Builder"] = 2
ang$moccu[ang$moccu == "Master Butcher"] = 2
ang$moccu[ang$moccu == "Master Mariner"] = 2
ang$moccu[ang$moccu == "Master Printer"] = 2
ang$moccu[ang$moccu == "Mat maker"] = 7
ang$moccu[ang$moccu == "Match factory"] = 9
ang$moccu[ang$moccu == "Match Factory Machinist"] = 8
ang$moccu[ang$moccu == "Match-maker"] = 9
ang$moccu[ang$moccu == "Mate"] = 2
ang$moccu[ang$moccu == "Mate at Sea"] = 2
ang$moccu[ang$moccu == "Math Lecturer Transvaal University"] = 0
ang$moccu[ang$moccu == "Matress-maker"] = 7
ang$moccu[ang$moccu == "Mattress maker"] = 7
ang$moccu[ang$moccu == "Mattress Maker"] = 7
ang$moccu[ang$moccu == "Mattressmaker"] = 7
ang$moccu[ang$moccu == "Mattress-maker"] = 7
ang$moccu[ang$moccu == "Meat Cutter"] = 7
ang$moccu[ang$moccu == "Meat Trade Employee"] = 7
ang$moccu[ang$moccu == "Mechanic"] = 8
ang$moccu[ang$moccu == "Mechanic "] = 8
ang$moccu[ang$moccu == "Mechanic (Defence Force)"] = 8
ang$moccu[ang$moccu == "Mechanic (On Active Service)"] = 8
ang$moccu[ang$moccu == "Mechanic G.P.O."] = 8
ang$moccu[ang$moccu == "Mechanic in R.A.F."] = 8
ang$moccu[ang$moccu == "Mechanic Match Factory"] = 8
ang$moccu[ang$moccu == "Mechanic R.A.F."] = 8
ang$moccu[ang$moccu == "Mechanic S.A. Air Force"] = 8
ang$moccu[ang$moccu == "Mechanic S.A.A.F."] = 8
ang$moccu[ang$moccu == "Mechanic S.A.R."] = 8
ang$moccu[ang$moccu == "Mechanical + Mining Engineer"] = 0
ang$moccu[ang$moccu == "Mechanical Adjuster"] = 8
ang$moccu[ang$moccu == "Mechanical Dentist"] = 0
ang$moccu[ang$moccu == "Mechanical Department S.A.R."] = 8
ang$moccu[ang$moccu == "Mechanical Engineer"] = 0
ang$moccu[ang$moccu == "Mechanical Engineer S.A.R."] = 0
ang$moccu[ang$moccu == "Mechanical Engineer, Transportation Dept. S.A.R.+H."] = 0
ang$moccu[ang$moccu == "Mechanical Inspector"] = 2
ang$moccu[ang$moccu == "Mechanical Instrument-maker"] = 8
ang$moccu[ang$moccu == "Mechanical Transport"] = 9
ang$moccu[ang$moccu == "Mechanician"] = 8
ang$moccu[ang$moccu == "Mechanician Telegraph Dept. S.A.R.+H."] = 8
ang$moccu[ang$moccu == "Mechanics assistant"] = 8
ang$moccu[ang$moccu == "Mechanics Assistant"] = 8
ang$moccu[ang$moccu == "Mechanics Boy"] = 8
ang$moccu[ang$moccu == "Medical Doctor"] = 0
ang$moccu[ang$moccu == "Medical Laboratory Technologist"] = 8
ang$moccu[ang$moccu == "Medical Officer"] = 0
ang$moccu[ang$moccu == "Medical Officer of Health"] = 0
ang$moccu[ang$moccu == "Medical Practitioner"] = 0
ang$moccu[ang$moccu == "Medical Practitioner Royal Air Force"] = 0
ang$moccu[ang$moccu == "Medical Radiologist"] = 0
ang$moccu[ang$moccu == "Medical Representative"] = 0
ang$moccu[ang$moccu == "Medical Research"] = 0
ang$moccu[ang$moccu == "Medical Staff"] = 0
ang$moccu[ang$moccu == "Medical student"] = 0
ang$moccu[ang$moccu == "Medical Student"] = 0
ang$moccu[ang$moccu == "Medical student on Active Service"] = 0
ang$moccu[ang$moccu == "Medical Technical Officer"] = 0
ang$moccu[ang$moccu == "Medical Technologist"] = 0
ang$moccu[ang$moccu == "Member of Parliament"] = 2
ang$moccu[ang$moccu == "Mercantile Clerk"] = 3
ang$moccu[ang$moccu == "Mercantile Marine Officer"] = 5
ang$moccu[ang$moccu == "Merchant"] = 4
ang$moccu[ang$moccu == "Merchant (Retired)"] = 4
ang$moccu[ang$moccu == "Merchant clerk"] = 3
ang$moccu[ang$moccu == "Merchant Navy"] = 5
ang$moccu[ang$moccu == "Merchant Navy Officer"] = 5
ang$moccu[ang$moccu == "Merchant Seaman"] = 4
ang$moccu[ang$moccu == "Merchant Tailor"] = 7
ang$moccu[ang$moccu == "Merchants Clerk"] = 3
ang$moccu[ang$moccu == "Messenger"] = 3
ang$moccu[ang$moccu == "Messenger "] = 3
ang$moccu[ang$moccu == "Messenger (Chemist)"] = 3
ang$moccu[ang$moccu == "Messenger (University)"] = 3
ang$moccu[ang$moccu == "Messenger Bookstore"] = 3
ang$moccu[ang$moccu == "Messenger Boy"] = 3
ang$moccu[ang$moccu == "Messenger boy"] = 3
ang$moccu[ang$moccu == "Messenger C.G.R."] = 3
ang$moccu[ang$moccu == "Messenger Clerk"] = 3
ang$moccu[ang$moccu == "Messenger clerk"] = 3
ang$moccu[ang$moccu == "Messenger Export + Import Agency"] = 3
ang$moccu[ang$moccu == "Messenger G.P.O."] = 3
ang$moccu[ang$moccu == "Messenger Gas Co."] = 3
ang$moccu[ang$moccu == "Messenger H.M. Customs"] = 3
ang$moccu[ang$moccu == "Messenger H.M. Dockyards"] = 3
ang$moccu[ang$moccu == "Messenger in Shipping Company"] = 3
ang$moccu[ang$moccu == "Messenger on Railway"] = 3
ang$moccu[ang$moccu == "Messenger S.A.R."] = 3
ang$moccu[ang$moccu == "Messenger S.A.R.+H."] = 3
ang$moccu[ang$moccu == "Messenger Standard Bank"] = 3
ang$moccu[ang$moccu == "Messenger to Dentist"] = 3
ang$moccu[ang$moccu == "Messenger to Royal Observatory"] = 3
ang$moccu[ang$moccu == "Messenger Union Castle Co."] = 3
ang$moccu[ang$moccu == "Messenger Univ. of Cape Town"] = 3
ang$moccu[ang$moccu == "Messenger(On Military Service)"] = 3
ang$moccu[ang$moccu == "MessengerClerk"] = 3
ang$moccu[ang$moccu == "MessengerDriver"] = 3
ang$moccu[ang$moccu == "Messenger-boy"] = 3
ang$moccu[ang$moccu == "Metal caster"] = 8
ang$moccu[ang$moccu == "Metal mechanic"] = 8
ang$moccu[ang$moccu == "Metal Moulder"] = 7
ang$moccu[ang$moccu == "Metal Polisher"] = 7
ang$moccu[ang$moccu == "Metal Sprayer"] = 7
ang$moccu[ang$moccu == "Metal Turner"] = 8
ang$moccu[ang$moccu == "Metal worker"] = 7
ang$moccu[ang$moccu == "Metal Worker S.A.R."] = 7
ang$moccu[ang$moccu == "Metallurgist"] = 7
ang$moccu[ang$moccu == "Metal-worker"] = 7
ang$moccu[ang$moccu == "Meteorological Section S.A.A.F."] = 0
ang$moccu[ang$moccu == "Meteorologist (Civil Service)"] = 0
ang$moccu[ang$moccu == "Meter mechanic"] = 8
ang$moccu[ang$moccu == "Meter Reader Town Council"] = 3
ang$moccu[ang$moccu == "Microbiologist"] = 0
ang$moccu[ang$moccu == "Micro-Biologist"] = 0
ang$moccu[ang$moccu == "Militant Pensioner"] = 5
ang$moccu[ang$moccu == "Military"] = 5
ang$moccu[ang$moccu == "Military Butcher"] = 7
ang$moccu[ang$moccu == "Military Clerk"] = 3
ang$moccu[ang$moccu == "Military Driver Cape Corps"] = 9
ang$moccu[ang$moccu == "Military Instructor"] = 1
ang$moccu[ang$moccu == "Military Officer"] = 5
ang$moccu[ang$moccu == "Military Pensioner"] = 5
ang$moccu[ang$moccu == "Military Royal Army Medical Corps"] = 0
ang$moccu[ang$moccu == "Military Service"] = 5
ang$moccu[ang$moccu == "Military, 2nd Lieut. S.A.A.C."] = 5
ang$moccu[ang$moccu == "Military, Cape Corps"] = 5
ang$moccu[ang$moccu == "Military, Corporal R.A.F."] = 5
ang$moccu[ang$moccu == "Military, Gunner S.A.A. Barberton"] = 5
ang$moccu[ang$moccu == "Military, Indian + Malay Corps"] = 5
ang$moccu[ang$moccu == "Military, Indian Corps"] = 5
ang$moccu[ang$moccu == "Military, Private "] = 5
ang$moccu[ang$moccu == "Military, S.A.E.C."] = 5
ang$moccu[ang$moccu == "Military, Tank Corps"] = 9
ang$moccu[ang$moccu == "Milk Cart Driver"] = 9
ang$moccu[ang$moccu == "Milk cart driver"] = 9
ang$moccu[ang$moccu == "Milk dealer"] = 4
ang$moccu[ang$moccu == "Milk deliverer"] = 9
ang$moccu[ang$moccu == "Milk-carter"] = 9
ang$moccu[ang$moccu == "Milkman"] = 9
ang$moccu[ang$moccu == "Mill hand"] = 9
ang$moccu[ang$moccu == "Mill labourer"] = 9
ang$moccu[ang$moccu == "Mill Manager"] = 2
ang$moccu[ang$moccu == "Mill Wright"] = 8
ang$moccu[ang$moccu == "Miller"] = 7
ang$moccu[ang$moccu == "Millers assistant"] = 7
ang$moccu[ang$moccu == "Millers Handyman"] = 9
ang$moccu[ang$moccu == "Millers labourer"] = 9
ang$moccu[ang$moccu == "Milliners Machinist"] = 8
ang$moccu[ang$moccu == "Millinery Blocker"] = 8
ang$moccu[ang$moccu == "Millwright"] = 8
ang$moccu[ang$moccu == "Millwright "] = 8
ang$moccu[ang$moccu == "Millwright (Caltex Ltd.)"] = 8
ang$moccu[ang$moccu == "Millwright S.A.R."] = 8
ang$moccu[ang$moccu == "Minder of Rotary Machine"] = 5
ang$moccu[ang$moccu == "Mine Captain"] = 2
ang$moccu[ang$moccu == "Mine Compound Manager"] = 2
ang$moccu[ang$moccu == "Mine Foreman"] = 2
ang$moccu[ang$moccu == "Mine Machinist"] = 8
ang$moccu[ang$moccu == "Mine Manager"] = 2
ang$moccu[ang$moccu == "Mine Official"] = 2
ang$moccu[ang$moccu == "Mine Overseer"] = 2
ang$moccu[ang$moccu == "Mine Owner"] = 7
ang$moccu[ang$moccu == "Mine Sampler"] = 7
ang$moccu[ang$moccu == "Mine Secretary"] = 3
ang$moccu[ang$moccu == "Mine secretary"] = 3
ang$moccu[ang$moccu == "Mine Shift Boss"] = 2
ang$moccu[ang$moccu == "Mine Statistician"] = 0
ang$moccu[ang$moccu == "Miner"] = 7
ang$moccu[ang$moccu == "Miner City Deep, Johannesburg"] = 7
ang$moccu[ang$moccu == "Mineral factory-hand"] = 7
ang$moccu[ang$moccu == "Mineral Water Conductor"] = 7
ang$moccu[ang$moccu == "Mineral water factory"] = 7
ang$moccu[ang$moccu == "Mineral water Manufacturer"] = 7
ang$moccu[ang$moccu == "Mineral Water Manufacturer"] = 7
ang$moccu[ang$moccu == "Mine-worker"] = 7
ang$moccu[ang$moccu == "Minibus Conductor"] = 3
ang$moccu[ang$moccu == "Mining"] = 7
ang$moccu[ang$moccu == "Mining Broker"] = 4
ang$moccu[ang$moccu == "Mining Clerk"] = 3
ang$moccu[ang$moccu == "Mining Contractor"] = 2
ang$moccu[ang$moccu == "Mining Employee"] = 7
ang$moccu[ang$moccu == "Mining Engineer"] = 0
ang$moccu[ang$moccu == "Mining Engineer On Active Service"] = 0
ang$moccu[ang$moccu == "Mining Geologist"] = 0
ang$moccu[ang$moccu == "Mining Manager"] = 2
ang$moccu[ang$moccu == "Mining Official"] = 2
ang$moccu[ang$moccu == "Mining Surveyor"] = 0
ang$moccu[ang$moccu == "Minister of Religion"] = 1
ang$moccu[ang$moccu == "Mission Priest"] = 1
ang$moccu[ang$moccu == "Missionary"] = 1
ang$moccu[ang$moccu == "Missionary S.A.G.M."] = 1
ang$moccu[ang$moccu == "Mono Type Operator"] = 9
ang$moccu[ang$moccu == "Mono Type Printer"] = 9
ang$moccu[ang$moccu == "Monotype Attendant"] = 9
ang$moccu[ang$moccu == "Monotype Engineer"] = 0
ang$moccu[ang$moccu == "Monotype Operator"] = 9
ang$moccu[ang$moccu == "Monumental Mason"] = 9
ang$moccu[ang$moccu == "Mooring attendant Docks"] = 9
ang$moccu[ang$moccu == "Motion Picture Cameraman"] = 1
ang$moccu[ang$moccu == "Motor Agent"] = 4
ang$moccu[ang$moccu == "Motor Assembler"] = 8
ang$moccu[ang$moccu == "Motor assembler"] = 8
ang$moccu[ang$moccu == "Motor body Builder"] = 8
ang$moccu[ang$moccu == "Motor Car Assembler"] = 8
ang$moccu[ang$moccu == "Motor Car Driver"] = 9
ang$moccu[ang$moccu == "Motor car driver"] = 9
ang$moccu[ang$moccu == "Motor Car Salesman"] = 4
ang$moccu[ang$moccu == "Motor Conductor for Wine Co."] = 3
ang$moccu[ang$moccu == "Motor dealers Clerk"] = 3
ang$moccu[ang$moccu == "Motor Demonstrator"] = 4
ang$moccu[ang$moccu == "Motor driver"] = 9
ang$moccu[ang$moccu == "Motor Driver"] = 9
ang$moccu[ang$moccu == "Motor Driver (On Military Service)"] = 9
ang$moccu[ang$moccu == "Motor Driver Mechanic"] = 8
ang$moccu[ang$moccu == "Motor Driver S.A.R."] = 9
ang$moccu[ang$moccu == "Motor Electrician"] = 8
ang$moccu[ang$moccu == "Motor Engineer"] = 0
ang$moccu[ang$moccu == "Motor Engineer for Divisional Council"] = 0
ang$moccu[ang$moccu == "Motor Engineers Assistant"] = 8
ang$moccu[ang$moccu == "Motor fitter"] = 8
ang$moccu[ang$moccu == "Motor Fitter"] = 8
ang$moccu[ang$moccu == "Motor Fitter S.A.R."] = 8
ang$moccu[ang$moccu == "Motor Handyman"] = 9
ang$moccu[ang$moccu == "Motor Industry Employee"] = 9
ang$moccu[ang$moccu == "Motor Lorry driver"] = 9
ang$moccu[ang$moccu == "Motor man"] = 9
ang$moccu[ang$moccu == "Motor mechanic"] = 8
ang$moccu[ang$moccu == "Motor Mechanic"] = 8
ang$moccu[ang$moccu == "Motor Mechanic (On Active Service)"] = 8
ang$moccu[ang$moccu == "Motor mechanic apprentice"] = 8
ang$moccu[ang$moccu == "Motor mechanic for Queenstown Municipality"] = 8
ang$moccu[ang$moccu == "Motor Mechanic S.A.A.F."] = 8
ang$moccu[ang$moccu == "Motor Merchant"] = 4
ang$moccu[ang$moccu == "Motor Panelbeater"] = 8
ang$moccu[ang$moccu == "Motor Proprietor"] = 2
ang$moccu[ang$moccu == "Motor Sales Manager"] = 2
ang$moccu[ang$moccu == "Motor Salesman"] = 4
ang$moccu[ang$moccu == "Motor Service attendant"] = 8
ang$moccu[ang$moccu == "Motor sheetmetal worker"] = 7
ang$moccu[ang$moccu == "Motor Spares Clerk"] = 3
ang$moccu[ang$moccu == "Motor Spares Salesman"] = 4
ang$moccu[ang$moccu == "Motor Trade"] = 9
ang$moccu[ang$moccu == "Motor Transport Division"] = 9
ang$moccu[ang$moccu == "Motor Transport Driver R.A.F."] = 9
ang$moccu[ang$moccu == "Motor Trimmer"] = 8
ang$moccu[ang$moccu == "Motor Upholsterer"] = 7
ang$moccu[ang$moccu == "Motor Van Driver"] = 9
ang$moccu[ang$moccu == "Motor-car Salesman"] = 4
ang$moccu[ang$moccu == "Motor-driver"] = 9
ang$moccu[ang$moccu == "Motor-industry worker"] = 9
ang$moccu[ang$moccu == "Motorist"] = 9
ang$moccu[ang$moccu == "Motorlorry driver(Private firm)"] = 9
ang$moccu[ang$moccu == "Motorman"] = 9
ang$moccu[ang$moccu == "Motor-man"] = 9
ang$moccu[ang$moccu == "Motorman Camps Bay Tramway "] = 9
ang$moccu[ang$moccu == "Motorman Trams"] = 9
ang$moccu[ang$moccu == "Motor-mechanic"] = 8
ang$moccu[ang$moccu == "Motor-mower Operator"] = 5
ang$moccu[ang$moccu == "Motor-trimmer"] = 8
ang$moccu[ang$moccu == "Moulder"] = 7
ang$moccu[ang$moccu == "Moulder Learner"] = 7
ang$moccu[ang$moccu == "Moulder S.A.R."] = 7
ang$moccu[ang$moccu == "Mounted Police Constable"] = 5
ang$moccu[ang$moccu == "Mounted Police, Basutoland "] = 5
ang$moccu[ang$moccu == "Mounted Trooper Urban Police"] = 5
ang$moccu[ang$moccu == "Mount-maker"] = 8
ang$moccu[ang$moccu == "Multigraph Operator for Municipality"] = 3
ang$moccu[ang$moccu == "Multilith Operator"] = 3
ang$moccu[ang$moccu == "Municiapal Employee"] = 9
ang$moccu[ang$moccu == "Municipa Employee"] = 9
ang$moccu[ang$moccu == "Municipal Accountant"] = 1
ang$moccu[ang$moccu == "Municipal Cleansing Dept."] = 5
ang$moccu[ang$moccu == "Municipal Clerk"] = 3
ang$moccu[ang$moccu == "Municipal Corporation Labourer"] = 9
ang$moccu[ang$moccu == "Municipal Driver"] = 9
ang$moccu[ang$moccu == "Municipal Driver "] = 9
ang$moccu[ang$moccu == "Municipal Electrical Employee"] = 8
ang$moccu[ang$moccu == "Municipal Employee"] = 9
ang$moccu[ang$moccu == "Municipal Foreman"] = 2
ang$moccu[ang$moccu == "Municipal Gardens labourer"] = 6
ang$moccu[ang$moccu == "Municipal Health Dept. Johannesburg"] = 9
ang$moccu[ang$moccu == "Municipal labourer"] = 9
ang$moccu[ang$moccu == "Municipal Labourer"] = 9
ang$moccu[ang$moccu == "Municipal Lorry-driver"] = 9
ang$moccu[ang$moccu == "Municipal Market Porter"] = 9
ang$moccu[ang$moccu == "Municipal Mechanical handyman"] = 9
ang$moccu[ang$moccu == "Municipal Official"] = 2
ang$moccu[ang$moccu == "Municipal Ranger"] = 6
ang$moccu[ang$moccu == "Municipal Road Employee"] = 9
ang$moccu[ang$moccu == "Municipal Servant"] = 3
ang$moccu[ang$moccu == "Municipal Storekeeper"] = 4
ang$moccu[ang$moccu == "Municipal water maker"] = 9
ang$moccu[ang$moccu == "Municipal Water Works Employer"] = 9
ang$moccu[ang$moccu == "Municipal worker"] = 9
ang$moccu[ang$moccu == "Municipal Worker"] = 9
ang$moccu[ang$moccu == "Municipality Labourer"] = 9
ang$moccu[ang$moccu == "Music Assistant"] = 1
ang$moccu[ang$moccu == "Music Teacher"] = 1
ang$moccu[ang$moccu == "Musical Director"] = 1
ang$moccu[ang$moccu == "Musical Instrument Maker"] = 9
ang$moccu[ang$moccu == "Musician"] = 1
ang$moccu[ang$moccu == "Musician R.M. Band"] = 1
ang$moccu[ang$moccu == "Musician Royal Marines"] = 1
ang$moccu[ang$moccu == "Musician: Royal Marines"] = 1
ang$moccu[ang$moccu == "NA"] = NA
ang$moccu[ang$moccu == "Nachinist"] = 8
ang$moccu[ang$moccu == "Nailer (Furrier)"] = 7
ang$moccu[ang$moccu == "National Meat Co. Employee"] = 7
ang$moccu[ang$moccu == "Native Police"] = 5
ang$moccu[ang$moccu == "Natural Meat Employee"] = 7
ang$moccu[ang$moccu == "Naval Airman"] = 5
ang$moccu[ang$moccu == "Naval Artisan"] = 5
ang$moccu[ang$moccu == "Naval Officer"] = 0
ang$moccu[ang$moccu == "Naval Officer, Royal Navy"] = 0
ang$moccu[ang$moccu == "Naval Officer, S.A. Navy"] = 0
ang$moccu[ang$moccu == "Naval Pilot"] = 0
ang$moccu[ang$moccu == "Naval Rating"] = 9
ang$moccu[ang$moccu == "Naval Rating Royal Navy"] = 9
ang$moccu[ang$moccu == "Naval Tactical Operator"] = 8
ang$moccu[ang$moccu == "Navigating Officer"] = 5
ang$moccu[ang$moccu == "Navigation Instructor S.A.A.F."] = 1
ang$moccu[ang$moccu == "Netting Machinist"] = 8
ang$moccu[ang$moccu == "News Agent"] = 4
ang$moccu[ang$moccu == "Newsagent"] = 4
ang$moccu[ang$moccu == "Newspaper Agent"] = 4
ang$moccu[ang$moccu == "Newspaper Editor"] = 1
ang$moccu[ang$moccu == "Newspaper Employee"] = 9
ang$moccu[ang$moccu == "Newspaper seller"] = 4
ang$moccu[ang$moccu == "Night Foreman"] = 2
ang$moccu[ang$moccu == "Night Porter"] = 9
ang$moccu[ang$moccu == "Night Watchman"] = 5
ang$moccu[ang$moccu == "Night watchman"] = 5
ang$moccu[ang$moccu == "Night Watchman City Council"] = 5
ang$moccu[ang$moccu == "Night-watchman"] = 5
ang$moccu[ang$moccu == "No Occupation"] = NA
ang$moccu[ang$moccu == "No profession"] = NA
ang$moccu[ang$moccu == "None"] = NA
ang$moccu[ang$moccu == "Norwegian Vice-Consul"] = 2
ang$moccu[ang$moccu == "Number Taker S.A.R."] = 3
ang$moccu[ang$moccu == "Number-Taker S.A.R."] = 3
ang$moccu[ang$moccu == "Nurse"] = 0
ang$moccu[ang$moccu == "Nurse (Mental Hospital)"] = 0
ang$moccu[ang$moccu == "Nurse Aid"] = 0
ang$moccu[ang$moccu == "Nurse Mental Hospital"] = 0
ang$moccu[ang$moccu == "Nursery Garden labourer"] = 6
ang$moccu[ang$moccu == "Nursery Gardener"] = 6
ang$moccu[ang$moccu == "Nursery man"] = 6
ang$moccu[ang$moccu == "Nursery man + Florist"] = 6
ang$moccu[ang$moccu == "Nurseryman"] = 6
ang$moccu[ang$moccu == "Nursery-man"] = 6
ang$moccu[ang$moccu == "Nurserymans labourer"] = 6
ang$moccu[ang$moccu == "Nurses assistant"] = 0
ang$moccu[ang$moccu == "Nursing Assistant"] = 0
ang$moccu[ang$moccu == "Nursing Assistant Valkenburg"] = 0
ang$moccu[ang$moccu == "Nylon Processing Instructor"] = 1
ang$moccu[ang$moccu == "O.A.S."] = NA
ang$moccu[ang$moccu == "O.C. 2 Officers Mess"] = NA
ang$moccu[ang$moccu == "Observer S.A. Air Force"] = 5
ang$moccu[ang$moccu == "Oceanographer"] = 0
ang$moccu[ang$moccu == "Office Appliance Mechanic"] = 8
ang$moccu[ang$moccu == "Office Appliance Technician"] = 9
ang$moccu[ang$moccu == "Office Attendant"] = 3
ang$moccu[ang$moccu == "Office boy"] = 3
ang$moccu[ang$moccu == "Office Boy"] = 3
ang$moccu[ang$moccu == "Office Boy S.A.R."] = 3
ang$moccu[ang$moccu == "Office Cleaner"] = 5
ang$moccu[ang$moccu == "Office cleaner"] = 5
ang$moccu[ang$moccu == "Office Clerk"] = 3
ang$moccu[ang$moccu == "Office guard"] = 5
ang$moccu[ang$moccu == "Office keeper"] = 5
ang$moccu[ang$moccu == "Office Machines Mechanic"] = 8
ang$moccu[ang$moccu == "Office Manager"] = 2
ang$moccu[ang$moccu == "Office Messenger"] = 3
ang$moccu[ang$moccu == "Office worker"] = 3
ang$moccu[ang$moccu == "Office Worker"] = 3
ang$moccu[ang$moccu == "Office-Assistant"] = 3
ang$moccu[ang$moccu == "Office-boy"] = 3
ang$moccu[ang$moccu == "Office-boy S.A.R."] = 3
ang$moccu[ang$moccu == "Officer Anti-Aircraft U.D.F."] = 5
ang$moccu[ang$moccu == "Officer B.M.P."] = 5
ang$moccu[ang$moccu == "Officer B.S.A. Police"] = 5
ang$moccu[ang$moccu == "Officer British Army"] = 5
ang$moccu[ang$moccu == "Officer Defence Force"] = 5
ang$moccu[ang$moccu == "Officer Gold Coast Regiment"] = 5
ang$moccu[ang$moccu == "Officer H.M. S A Ships"] = 5
ang$moccu[ang$moccu == "Officer in Merchant Navy"] = 5
ang$moccu[ang$moccu == "Officer in Royal Navy"] = 5
ang$moccu[ang$moccu == "Officer in S.A.Permanent Force"] = 5
ang$moccu[ang$moccu == "Officer in S.A.S.C."] = 5
ang$moccu[ang$moccu == "Officer Indian Army"] = 5
ang$moccu[ang$moccu == "Officer Mercantile Marine"] = 5
ang$moccu[ang$moccu == "Officer of Constabulary"] = 5
ang$moccu[ang$moccu == "Officer of H.M. Forces"] = 5
ang$moccu[ang$moccu == "Officer of U.D.F."] = 5
ang$moccu[ang$moccu == "Officer Royal Air Force"] = 5
ang$moccu[ang$moccu == "Officer Royal Marines"] = 5
ang$moccu[ang$moccu == "Officer Royal Naval Reserve"] = 5
ang$moccu[ang$moccu == "Officer S.A. Artillery"] = 5
ang$moccu[ang$moccu == "Officer S.A. Navy"] = 5
ang$moccu[ang$moccu == "Officer S.A.A.F."] = 5
ang$moccu[ang$moccu == "Officer S.A.M.R."] = 5
ang$moccu[ang$moccu == "Officer S.A.N.F."] = 5
ang$moccu[ang$moccu == "Officer Somerset Infantry"] = 5
ang$moccu[ang$moccu == "Officer U.D.F."] = 5
ang$moccu[ang$moccu == "Officer Union Defence Force"] = 5
ang$moccu[ang$moccu == "Officer, Union Defence Force"] = 5
ang$moccu[ang$moccu == "Officers Cook"] = 5
ang$moccu[ang$moccu == "Officers Cook II"] = 5
ang$moccu[ang$moccu == "Officers Steward"] = 5
ang$moccu[ang$moccu == "Official Union Castle S.S. Co."] = 9
ang$moccu[ang$moccu == "Official Vacuum Oil"] = 9
ang$moccu[ang$moccu == "Off-Sales Assistant"] = 4
ang$moccu[ang$moccu == "Ohlssons Brewing Co."] = 7
ang$moccu[ang$moccu == "Oil Company Executive"] = 2
ang$moccu[ang$moccu == "Oil Company Representative"] = 4
ang$moccu[ang$moccu == "Oil Companys Representative"] = 4
ang$moccu[ang$moccu == "Oil Salesman"] = 4
ang$moccu[ang$moccu == "Oil-boiler"] = 7
ang$moccu[ang$moccu == "Old Age Pensioner"] = NA
ang$moccu[ang$moccu == "Omnibus Conductor"] = 3
ang$moccu[ang$moccu == "Omnibus Driver"] = 9
ang$moccu[ang$moccu == "Omnibus Inspector"] = 2
ang$moccu[ang$moccu == "On Active Service"] = 5
ang$moccu[ang$moccu == "On Active Service "] = 5
ang$moccu[ang$moccu == "On Active Service (Imperial Army)"] = 5
ang$moccu[ang$moccu == "On Active Service C.F.A."] = 5
ang$moccu[ang$moccu == "On Active Service Royal Navy"] = 5
ang$moccu[ang$moccu == "On Active Service S.A.A.F."] = 5
ang$moccu[ang$moccu == "On Active Service S.A.N.F."] = 5
ang$moccu[ang$moccu == "On Active Service U.D.F."] = 5
ang$moccu[ang$moccu == "On the Railway"] = 9
ang$moccu[ang$moccu == "Operative Unclassified S.A.R.+H."] = NA
ang$moccu[ang$moccu == "Operator"] = 8
ang$moccu[ang$moccu == "Operator - Fish Canning Factory"] = 7
ang$moccu[ang$moccu == "Operator C.C.C."] = 8
ang$moccu[ang$moccu == "Operator City Council"] = 8
ang$moccu[ang$moccu == "Operator in Cigarette Factory"] = 7
ang$moccu[ang$moccu == "Operator of Caterpillar Machine"] = 9
ang$moccu[ang$moccu == "Operator of Road Plant"] = 9
ang$moccu[ang$moccu == "Operator Oil Refinery"] = 9
ang$moccu[ang$moccu == "Operator S.A.R."] = 9
ang$moccu[ang$moccu == "Operator Winder"] = 8
ang$moccu[ang$moccu == "Ophthalmic Surgeon"] = 0
ang$moccu[ang$moccu == "Optical Fitter"] = 8
ang$moccu[ang$moccu == "Optical Mechanic"] = 8
ang$moccu[ang$moccu == "Optical mechanic"] = 8
ang$moccu[ang$moccu == "Optician"] = 0
ang$moccu[ang$moccu == "Order Clerk"] = 3
ang$moccu[ang$moccu == "Order man"] = 3
ang$moccu[ang$moccu == "Orderly"] = 5
ang$moccu[ang$moccu == "Orderman"] = 3
ang$moccu[ang$moccu == "Order-man"] = 3
ang$moccu[ang$moccu == "Ordinary Seaman"] = 5
ang$moccu[ang$moccu == "Organ Builder"] = 9
ang$moccu[ang$moccu == "Organ Tuner"] = 9
ang$moccu[ang$moccu == "Organist"] = 1
ang$moccu[ang$moccu == "Orthopaedic Technician"] = 0
ang$moccu[ang$moccu == "Ostrich Farmer"] = 2
ang$moccu[ang$moccu == "Ostrich Feather Sorter"] = 7
ang$moccu[ang$moccu == "Outfitter"] = 4
ang$moccu[ang$moccu == "Outfitter + Tailor"] = 7
ang$moccu[ang$moccu == "Outfitters Salesman"] = 4
ang$moccu[ang$moccu == "Outfitters Salesman"] = 4
ang$moccu[ang$moccu == "Outfitting Salesman"] = 4
ang$moccu[ang$moccu == "Overhead Linesman"] = 8
ang$moccu[ang$moccu == "Overseer"] = 2
ang$moccu[ang$moccu == "Overseer Breakwater Convict Station"] = 2
ang$moccu[ang$moccu == "Overseer Convict Station"] = 2
ang$moccu[ang$moccu == "Overseer Miner"] = 2
ang$moccu[ang$moccu == "Overseer of Dock Agents"] = 2
ang$moccu[ang$moccu == "Overseer of Platelayers"] = 2
ang$moccu[ang$moccu == "Overseer Railway"] = 2
ang$moccu[ang$moccu == "Overseer Railway Dept."] = 2
ang$moccu[ang$moccu == "P&T Assistant"] = NA
ang$moccu[ang$moccu == "P.+T. Assistant G.P.O."] = NA
ang$moccu[ang$moccu == "P.+T. Asst. Grade II"] = NA
ang$moccu[ang$moccu == "P.O. Engineer(Telegraph)"] = 0
ang$moccu[ang$moccu == "P.O. Official"] = 2
ang$moccu[ang$moccu == "P.O. Telephones Chargeman"] = 2
ang$moccu[ang$moccu == "P.W.D. Transvaal"] = NA
ang$moccu[ang$moccu == "Packaging Foreman"] = 2
ang$moccu[ang$moccu == "Packer"] = 9
ang$moccu[ang$moccu == "Packer (Factory)"] = 9
ang$moccu[ang$moccu == "Packer at grocers"] = 9
ang$moccu[ang$moccu == "Packer at Hardware Store"] = 9
ang$moccu[ang$moccu == "Packer C.N.A."] = 9
ang$moccu[ang$moccu == "Packer in Furniture Store"] = 9
ang$moccu[ang$moccu == "Packer in Printing Trade"] = 9
ang$moccu[ang$moccu == "Packer Standard Bank"] = 9
ang$moccu[ang$moccu == "Packer Tobacco Co."] = 9
ang$moccu[ang$moccu == "Packer Woollen Mills"] = 9
ang$moccu[ang$moccu == "Packer(Furniture removal)"] = 9
ang$moccu[ang$moccu == "Packer(Match factory)"] = 9
ang$moccu[ang$moccu == "Packer: Typewriter Co."] = 9
ang$moccu[ang$moccu == "Paediatrician"] = 0
ang$moccu[ang$moccu == "Page boy"] = 5
ang$moccu[ang$moccu == "Pain"] = NA
ang$moccu[ang$moccu == "Paint chemist"] = 0
ang$moccu[ang$moccu == "Paint mixer"] = 9
ang$moccu[ang$moccu == "Paint sprayer"] = 9
ang$moccu[ang$moccu == "Paint Sprayer"] = 9
ang$moccu[ang$moccu == "Paint Technician"] = 0
ang$moccu[ang$moccu == "Painter"] = 0
ang$moccu[ang$moccu == "Painter + Decorator"] = 0
ang$moccu[ang$moccu == "Painter On Active Service"] = 0
ang$moccu[ang$moccu == "Painter Public Works Department"] = 9
ang$moccu[ang$moccu == "Painter S.A.R."] = 9
ang$moccu[ang$moccu == "Painter(Tramways)"] = 9
ang$moccu[ang$moccu == "Painter-decorator"] = 9
ang$moccu[ang$moccu == "Painters apprentice"] = 9
ang$moccu[ang$moccu == "Painters assistant"] = 9
ang$moccu[ang$moccu == "Painters Assistant"] = 9
ang$moccu[ang$moccu == "Painters Glazier"] = 9
ang$moccu[ang$moccu == "Painters labourer"] = 9
ang$moccu[ang$moccu == "Painters labourer for private firm"] = 9
ang$moccu[ang$moccu == "Painters labourer S.A.R."] = 9
ang$moccu[ang$moccu == "Painters labourer(On Military Service)"] = 9
ang$moccu[ang$moccu == "Painting Contractor"] = 9
ang$moccu[ang$moccu == "Paintshop worker"] = 9
ang$moccu[ang$moccu == "Panelbeater"] = 8
ang$moccu[ang$moccu == "Panel-beater"] = 8
ang$moccu[ang$moccu == "Panelbeater Motor Trade"] = 8
ang$moccu[ang$moccu == "Panelbeating Foreman"] = 2
ang$moccu[ang$moccu == "Pantryman"] = 5
ang$moccu[ang$moccu == "Pantryman S.A.R."] = 5
ang$moccu[ang$moccu == "Paper Bag Machine Mechanic"] = 8
ang$moccu[ang$moccu == "Paper Clerk"] = 3
ang$moccu[ang$moccu == "Paper Machine Operator"] = 8
ang$moccu[ang$moccu == "Paper Merchant"] = 4
ang$moccu[ang$moccu == "Paper packing machinist"] = 8
ang$moccu[ang$moccu == "Paper Sack Maker"] = 7
ang$moccu[ang$moccu == "Paperbag Manufacturer"] = 7
ang$moccu[ang$moccu == "Paper-maker"] = 7
ang$moccu[ang$moccu == "Papermakers Branch Representative"] = 4
ang$moccu[ang$moccu == "Parcel Delivery"] = 9
ang$moccu[ang$moccu == "Parcels Deliverer"] = 9
ang$moccu[ang$moccu == "Park + Gardens"] = 6
ang$moccu[ang$moccu == "Park-O-Meter Attendant"] = 9
ang$moccu[ang$moccu == "Part-time Student"] = NA
ang$moccu[ang$moccu == "Passenger Agent"] = 5
ang$moccu[ang$moccu == "Past Fireman S.A.R."] = 9
ang$moccu[ang$moccu == "Paste boy, United Tobacco Co."] = NA
ang$moccu[ang$moccu == "Pastry cook"] = 5
ang$moccu[ang$moccu == "Pastry Cook"] = 5
ang$moccu[ang$moccu == "Pasture Research"] = 1
ang$moccu[ang$moccu == "Pattern Cutter"] = 7
ang$moccu[ang$moccu == "Pattern Grader"] = 7
ang$moccu[ang$moccu == "Pattern Maker"] = 7
ang$moccu[ang$moccu == "Pattern maker"] = 7
ang$moccu[ang$moccu == "Pattern Maker S.A.R."] = 7
ang$moccu[ang$moccu == "Pattern-grader"] = 7
ang$moccu[ang$moccu == "Patternmaker"] = 7
ang$moccu[ang$moccu == "Pattern-maker"] = 7
ang$moccu[ang$moccu == "Pattern-maker "] = 7
ang$moccu[ang$moccu == "Paymaster"] = 3
ang$moccu[ang$moccu == "Paymaster Lieut. Royal Navy"] = 3
ang$moccu[ang$moccu == "Paymaster Lieutenant Commander R.N."] = 3
ang$moccu[ang$moccu == "Paymaster R.N."] = 3
ang$moccu[ang$moccu == "Paymaster Royal Navy"] = 3
ang$moccu[ang$moccu == "Peasant"] = NA
ang$moccu[ang$moccu == "Pedlar"] = 4
ang$moccu[ang$moccu == "Pensioner"] = NA
ang$moccu[ang$moccu == "Pensioner Cape Civil Service"] = 3
ang$moccu[ang$moccu == "Pensioner Casual Clerk"] = 3
ang$moccu[ang$moccu == "Pensioner Civil Service"] = 3
ang$moccu[ang$moccu == "Pensioner S.A.R."] = 5
ang$moccu[ang$moccu == "Pensions Clerk"] = 3
ang$moccu[ang$moccu == "Permanent Force Bombardier"] = 5
ang$moccu[ang$moccu == "Permanent Force, U.D.F."] = 5
ang$moccu[ang$moccu == "Permanent Instructor"] = 1
ang$moccu[ang$moccu == "Permanent Invalid"] = NA
ang$moccu[ang$moccu == "Permanent labourer S.A.R."] = 9
ang$moccu[ang$moccu == "Permanent Officer"] = 5
ang$moccu[ang$moccu == "Permanentway Inspector"] = 2
ang$moccu[ang$moccu == "Personal Assistant"] = 3
ang$moccu[ang$moccu == "Personel Officer"] = 3
ang$moccu[ang$moccu == "Personnel Clerk"] = 3
ang$moccu[ang$moccu == "Personnel Officer"] = 3
ang$moccu[ang$moccu == "Petrol Attendant"] = 9
ang$moccu[ang$moccu == "Petrol attendant"] = 9
ang$moccu[ang$moccu == "Petrol Firms Employer"] = 9
ang$moccu[ang$moccu == "Petrol Pump Assembler"] = 8
ang$moccu[ang$moccu == "Petrol Pump Employee"] = 9
ang$moccu[ang$moccu == "Petrol Pump Mechanic"] = 8
ang$moccu[ang$moccu == "Petrol Salesman"] = 4
ang$moccu[ang$moccu == "Petty Officer"] = 5
ang$moccu[ang$moccu == "Petty Officer Air Fitter F.A.A."] = 5
ang$moccu[ang$moccu == "Petty Officer R.N."] = 5
ang$moccu[ang$moccu == "Petty Officer R.N.A.S."] = 5
ang$moccu[ang$moccu == "Petty Officer Royal Navy"] = 5
ang$moccu[ang$moccu == "Petty Officer S.A. Navy"] = 5
ang$moccu[ang$moccu == "Petty Officer S.A.N.F."] = 5
ang$moccu[ang$moccu == "Petty Officer Telegraphist"] = 5
ang$moccu[ang$moccu == "Petty Officer Telegraphy Royal Navy"] = 5
ang$moccu[ang$moccu == "Petty-Officer R.N."] = 5
ang$moccu[ang$moccu == "Pharmaceutical Chemist"] = 0
ang$moccu[ang$moccu == "Pharmacist"] = 0
ang$moccu[ang$moccu == "Photo Engraver"] = 9
ang$moccu[ang$moccu == "Photo Lithographer"] = 9
ang$moccu[ang$moccu == "Photo Litographer"] = 9
ang$moccu[ang$moccu == "Photo-Engraver"] = 9
ang$moccu[ang$moccu == "Photographer"] = 1
ang$moccu[ang$moccu == "Photographer - S.A.A.F."] = 1
ang$moccu[ang$moccu == "Photographers assistant"] = 1
ang$moccu[ang$moccu == "Photographic Assistant"] = 1
ang$moccu[ang$moccu == "Photographic Dealer"] = 4
ang$moccu[ang$moccu == "Photographic Developer"] = 9
ang$moccu[ang$moccu == "Photographic Lythographer"] = 9
ang$moccu[ang$moccu == "Photographic Printer"] = 9
ang$moccu[ang$moccu == "Photo-litographer"] = 9
ang$moccu[ang$moccu == "Photo-Litographer"] = 9
ang$moccu[ang$moccu == "Photo-technician"] = 0
ang$moccu[ang$moccu == "Physician"] = 0
ang$moccu[ang$moccu == "Physician + Surgeon"] = 0
ang$moccu[ang$moccu == "Physiologist"] = 0
ang$moccu[ang$moccu == "Pianist"] = 1
ang$moccu[ang$moccu == "Piano mechanic"] = 8
ang$moccu[ang$moccu == "Piano Tuner"] = 9
ang$moccu[ang$moccu == "Pianoforte maker"] = 9
ang$moccu[ang$moccu == "Pianoforte Repairer"] = 9
ang$moccu[ang$moccu == "Piano-timer"] = 9
ang$moccu[ang$moccu == "Picture Frame Maker"] = 7
ang$moccu[ang$moccu == "Picture frame maker"] = 7
ang$moccu[ang$moccu == "Picture Frame Packer"] = 9
ang$moccu[ang$moccu == "Picture framer"] = 9
ang$moccu[ang$moccu == "Pierhead-man"] = 9
ang$moccu[ang$moccu == "Pierheadmason"] = 9
ang$moccu[ang$moccu == "Pilot"] = 0
ang$moccu[ang$moccu == "Pilot in S.A. Air Force"] = 0
ang$moccu[ang$moccu == "Pilot Officer R.A.F."] = 0
ang$moccu[ang$moccu == "Pilot Officer Royal Air Force"] = 0
ang$moccu[ang$moccu == "Pilot Royal Air Force"] = 0
ang$moccu[ang$moccu == "Pilot S.A.A.F."] = 0
ang$moccu[ang$moccu == "Pipe Caulkner"] = 9
ang$moccu[ang$moccu == "Pipe-fitter"] = 8
ang$moccu[ang$moccu == "Pipe-fitter (On Active Service)"] = 8
ang$moccu[ang$moccu == "Plans Examiner"] = 3
ang$moccu[ang$moccu == "Plant Operator"] = 8
ang$moccu[ang$moccu == "Plant Operator City Council"] = 8
ang$moccu[ang$moccu == "Planter"] = 6
ang$moccu[ang$moccu == "Plasterer"] = 9
ang$moccu[ang$moccu == "Plate Glass Cutter"] = 8
ang$moccu[ang$moccu == "Platelayer"] = 9
ang$moccu[ang$moccu == "Platelayer C.G.R."] = 9
ang$moccu[ang$moccu == "Platelayer S.A.R."] = 9
ang$moccu[ang$moccu == "Platelayer S.A.R.+H."] = 9
ang$moccu[ang$moccu == "Platen Hand"] = 9
ang$moccu[ang$moccu == "Platen Pressman"] = 9
ang$moccu[ang$moccu == "Plater Pressman"] = 9
ang$moccu[ang$moccu == "Platform Alarm S.A.R.+H."] = 5
ang$moccu[ang$moccu == "Platten Hand Printing"] = 9
ang$moccu[ang$moccu == "Playground attendant"] = 5
ang$moccu[ang$moccu == "Plays Violin(Blind)"] = 1
ang$moccu[ang$moccu == "Pleater"] = 7
ang$moccu[ang$moccu == "Pliceman"] = 5
ang$moccu[ang$moccu == "Plumber"] = 8
ang$moccu[ang$moccu == "Plumber S.A.R."] = 8
ang$moccu[ang$moccu == "Plumbers apprentice"] = 8
ang$moccu[ang$moccu == "Plumbers assistant"] = 8
ang$moccu[ang$moccu == "Plumbers Assistant"] = 8
ang$moccu[ang$moccu == "Plumbers boy"] = 8
ang$moccu[ang$moccu == "Plumbers handyman"] = 9
ang$moccu[ang$moccu == "Plumbers labourer"] = 9
ang$moccu[ang$moccu == "Plumbers Labourer"] = 9
ang$moccu[ang$moccu == "Plumbers man"] = 9
ang$moccu[ang$moccu == "Plumbers Mate"] = 9
ang$moccu[ang$moccu == "Plumbers mate"] = 9
ang$moccu[ang$moccu == "Plumer"] = 8
ang$moccu[ang$moccu == "Plywood Machinist"] = 8
ang$moccu[ang$moccu == "Plywood Matcher"] = 7
ang$moccu[ang$moccu == "Pointsman C.G.R."] = 9
ang$moccu[ang$moccu == "Pointsman S.A.R."] = 9
ang$moccu[ang$moccu == "Pointsman Trams"] = 9
ang$moccu[ang$moccu == "Police"] = 5
ang$moccu[ang$moccu == "Police C.I.D."] = 5
ang$moccu[ang$moccu == "Police Constable"] = 5
ang$moccu[ang$moccu == "Police Constable Docks"] = 5
ang$moccu[ang$moccu == "Police Constable S.A.P."] = 5
ang$moccu[ang$moccu == "Police Constable S.A.R."] = 5
ang$moccu[ang$moccu == "Police Force"] = 5
ang$moccu[ang$moccu == "Police Officer"] = 5
ang$moccu[ang$moccu == "Police Sergeant"] = 5
ang$moccu[ang$moccu == "Policeman"] = 5
ang$moccu[ang$moccu == "Policeman S.A. Police"] = 5
ang$moccu[ang$moccu == "Policeman S.A.P."] = 5
ang$moccu[ang$moccu == "Policeman S.A.R."] = 5
ang$moccu[ang$moccu == "Polisher"] = 8
ang$moccu[ang$moccu == "Polisher Bedstead factory"] = 8
ang$moccu[ang$moccu == "Polisher in Cabinet Works"] = 8
ang$moccu[ang$moccu == "Political Secretary"] = 2
ang$moccu[ang$moccu == "Polony Filler"] = 7
ang$moccu[ang$moccu == "Polony maker"] = 7
ang$moccu[ang$moccu == "Polony Maker"] = 7
ang$moccu[ang$moccu == "Port boatman"] = 9
ang$moccu[ang$moccu == "Port Boatman"] = 9
ang$moccu[ang$moccu == "Port Office Clerk"] = 3
ang$moccu[ang$moccu == "Port Officer"] = 5
ang$moccu[ang$moccu == "Porter"] = 9
ang$moccu[ang$moccu == "Porter at Goods Station"] = 9
ang$moccu[ang$moccu == "Porter C.G.R."] = 9
ang$moccu[ang$moccu == "Porter Goods station"] = 9
ang$moccu[ang$moccu == "Porter in G.P.O."] = 9
ang$moccu[ang$moccu == "Porter in Railway Service"] = 9
ang$moccu[ang$moccu == "Porter S.A.R."] = 9
ang$moccu[ang$moccu == "Portman"] = 9
ang$moccu[ang$moccu == "Post + Telegraph Assistant"] = 3
ang$moccu[ang$moccu == "Post + Telegraph Assistant G.P.O."] = 3
ang$moccu[ang$moccu == "Post + Telegraph Clerk"] = 3
ang$moccu[ang$moccu == "Post + Telegraph Clerk (On Active Service)"] = 3
ang$moccu[ang$moccu == "Post + Telegraph Electrical Engineer"] = 0
ang$moccu[ang$moccu == "Post and Telegraph Assistant"] = 3
ang$moccu[ang$moccu == "Post Boy"] = 3
ang$moccu[ang$moccu == "Post Boy, G.P.O. Cape Town"] = 3
ang$moccu[ang$moccu == "Post Messenger"] = 3
ang$moccu[ang$moccu == "Post Office"] = 3
ang$moccu[ang$moccu == "Post Office Assistant"] = 3
ang$moccu[ang$moccu == "Post Office Clerk"] = 3
ang$moccu[ang$moccu == "Post Office Electrician"] = 8
ang$moccu[ang$moccu == "Post Office Employee"] = 3
ang$moccu[ang$moccu == "Post Office Mechanic"] = 8
ang$moccu[ang$moccu == "Post Office Official"] = 2
ang$moccu[ang$moccu == "Post Office Service"] = 3
ang$moccu[ang$moccu == "Post Office Sorter"] = 3
ang$moccu[ang$moccu == "Post Office Technician"] = 0
ang$moccu[ang$moccu == "Post Office worker"] = 3
ang$moccu[ang$moccu == "Postal + Telegraph Clerk"] = 3
ang$moccu[ang$moccu == "Postal Assistant"] = 3
ang$moccu[ang$moccu == "Postal Clerk"] = 3
ang$moccu[ang$moccu == "Postal Clerk S.A.B.C."] = 3
ang$moccu[ang$moccu == "Postal Driver"] = 9
ang$moccu[ang$moccu == "Postal Engineer"] = 0
ang$moccu[ang$moccu == "Postal Messenger"] = 3
ang$moccu[ang$moccu == "Postal Official"] = 2
ang$moccu[ang$moccu == "Postal servant"] = 3
ang$moccu[ang$moccu == "Postal Service"] = 3
ang$moccu[ang$moccu == "Postal Telegraph"] = 3
ang$moccu[ang$moccu == "Postal work"] = 3
ang$moccu[ang$moccu == "Postal Work"] = 3
ang$moccu[ang$moccu == "Postboy"] = 3
ang$moccu[ang$moccu == "Post-boy"] = 3
ang$moccu[ang$moccu == "Poster-boy"] = 3
ang$moccu[ang$moccu == "Postman"] = 3
ang$moccu[ang$moccu == "Postman G.P.O."] = 3
ang$moccu[ang$moccu == "Postman Grade 1"] = 3
ang$moccu[ang$moccu == "Postmaster"] = 3
ang$moccu[ang$moccu == "Postmaster of Steynsburg"] = 3
ang$moccu[ang$moccu == "Potato-chip maker"] = 7
ang$moccu[ang$moccu == "Poultry Dealer"] = 4
ang$moccu[ang$moccu == "Poultry Farmer"] = 2
ang$moccu[ang$moccu == "Power Station Labourer"] = 9
ang$moccu[ang$moccu == "Power Station Operator"] = 8
ang$moccu[ang$moccu == "Power Station Shiftsman"] = 9
ang$moccu[ang$moccu == "Press"] = 9
ang$moccu[ang$moccu == "Press Photographer"] = 1
ang$moccu[ang$moccu == "Pressed steel Maker"] = 7
ang$moccu[ang$moccu == "Presser"] = 7
ang$moccu[ang$moccu == "Presser - Clothing factory"] = 7
ang$moccu[ang$moccu == "Presser at Clothing Factory"] = 7
ang$moccu[ang$moccu == "Presser in Clothing Factory"] = 7
ang$moccu[ang$moccu == "Pressing Supervisor"] = 2
ang$moccu[ang$moccu == "Pressman"] = 7
ang$moccu[ang$moccu == "Priest"] = 1
ang$moccu[ang$moccu == "Priest Doctor"] = 1
ang$moccu[ang$moccu == "Priest in Holy Orders"] = 1
ang$moccu[ang$moccu == "Priest of English Church"] = 1
ang$moccu[ang$moccu == "Priest of the Anglican Communion"] = 1
ang$moccu[ang$moccu == "Principal of School"] = 1
ang$moccu[ang$moccu == "Principal of the Diocesan College"] = 1
ang$moccu[ang$moccu == "Print"] = 9
ang$moccu[ang$moccu == "Printer"] = 9
ang$moccu[ang$moccu == "Printer (On Active Service)"] = 9
ang$moccu[ang$moccu == "Printer (Telegrapher S.A. Naval Forces)"] = 9
ang$moccu[ang$moccu == "Printer + Soldier"] = 9
ang$moccu[ang$moccu == "Printer + Stationer"] = 9
ang$moccu[ang$moccu == "Printers Apprentice"] = 9
ang$moccu[ang$moccu == "Printers assistant"] = 9
ang$moccu[ang$moccu == "Printers Assistant"] = 9
ang$moccu[ang$moccu == "Printers Clerk"] = 3
ang$moccu[ang$moccu == "Printers Compositor"] = 9
ang$moccu[ang$moccu == "Printers Copy Holder"] = 9
ang$moccu[ang$moccu == "Printers Cutter"] = 9
ang$moccu[ang$moccu == "Printers Employer"] = 9
ang$moccu[ang$moccu == "Printers Estimator"] = 3
ang$moccu[ang$moccu == "Printers Feeder"] = 9
ang$moccu[ang$moccu == "Printers Labourer"] = 9
ang$moccu[ang$moccu == "Printers labourer"] = 9
ang$moccu[ang$moccu == "Printers machine minder"] = 9
ang$moccu[ang$moccu == "Printers Machinist"] = 8
ang$moccu[ang$moccu == "Printers messenger"] = 3
ang$moccu[ang$moccu == "Printers Operator"] = 8
ang$moccu[ang$moccu == "Printers Overseer"] = 2
ang$moccu[ang$moccu == "Printers packer"] = 9
ang$moccu[ang$moccu == "Printers Reader"] = 3
ang$moccu[ang$moccu == "Printers Representative"] = 4
ang$moccu[ang$moccu == "Printers Ruler"] = 9
ang$moccu[ang$moccu == "Printers Ruler"] = 9
ang$moccu[ang$moccu == "Printers ruler"] = 9
ang$moccu[ang$moccu == "Printers Warehouseman"] = 9
ang$moccu[ang$moccu == "Printing"] = 9
ang$moccu[ang$moccu == "Printing assistant"] = 9
ang$moccu[ang$moccu == "Printing Compositor"] = 9
ang$moccu[ang$moccu == "Printing Cutter"] = 9
ang$moccu[ang$moccu == "Printing Industry"] = 9
ang$moccu[ang$moccu == "Printing Trade"] = 9
ang$moccu[ang$moccu == "Printing worker"] = 9
ang$moccu[ang$moccu == "Printing-Ink Technician"] = 0
ang$moccu[ang$moccu == "Printing-machine hand"] = 9
ang$moccu[ang$moccu == "Prison warden"] = 5
ang$moccu[ang$moccu == "Prison Warden"] = 5
ang$moccu[ang$moccu == "Prison Warder"] = 5
ang$moccu[ang$moccu == "Prison-worker"] = 5
ang$moccu[ang$moccu == "Private"] = 5
ang$moccu[ang$moccu == "Private 11th Regiment"] = 5
ang$moccu[ang$moccu == "Private 24th Regiment"] = 5
ang$moccu[ang$moccu == "Private 2nd Hampshire Regiment"] = 5
ang$moccu[ang$moccu == "Private 58th Regiment"] = 5
ang$moccu[ang$moccu == "Private 86th"] = 5
ang$moccu[ang$moccu == "Private 86th Regiment"] = 5
ang$moccu[ang$moccu == "Private 91st Regiment"] = 5
ang$moccu[ang$moccu == "Private C.P.R."] = 5
ang$moccu[ang$moccu == "Private C.T. Highlanders"] = 5
ang$moccu[ang$moccu == "Private Cape Corps"] = 5
ang$moccu[ang$moccu == "Private Cape Rifles"] = 5
ang$moccu[ang$moccu == "Private Chauffeur"] = 5
ang$moccu[ang$moccu == "Private East Lancashire Regiment"] = 5
ang$moccu[ang$moccu == "Private Enquiry Agent"] = 5
ang$moccu[ang$moccu == "Private HMS Hermes"] = 5
ang$moccu[ang$moccu == "Private I.M.C."] = 5
ang$moccu[ang$moccu == "Private in 5th S.A. Regiment"] = 5
ang$moccu[ang$moccu == "Private in Cape Corps"] = 5
ang$moccu[ang$moccu == "Private in R.G.A."] = 5
ang$moccu[ang$moccu == "Private in the 86th Regiment"] = 5
ang$moccu[ang$moccu == "Private in the Army Hospital"] = 5
ang$moccu[ang$moccu == "Private in Yorkshire Regiment"] = 5
ang$moccu[ang$moccu == "Private Labour Contingent"] = 5
ang$moccu[ang$moccu == "Private Native Military Corps"] = 5
ang$moccu[ang$moccu == "Private of 73rd Reg."] = 5
ang$moccu[ang$moccu == "Private Parachute Regiment"] = 5
ang$moccu[ang$moccu == "Private Regiment"] = 5
ang$moccu[ang$moccu == "Private Royal Artillery"] = 5
ang$moccu[ang$moccu == "Private Royal Engineer"] = 0
ang$moccu[ang$moccu == "Private S.A. Air Force"] = 5
ang$moccu[ang$moccu == "Private S.A. Cape Corps"] = 5
ang$moccu[ang$moccu == "Private S.A. Engineering Corps"] = 5
ang$moccu[ang$moccu == "Private S.A. Medical Corps"] = 5
ang$moccu[ang$moccu == "Private S.A.A.F."] = 5
ang$moccu[ang$moccu == "Private S.A.E.C."] = 5
ang$moccu[ang$moccu == "Private Secretary"] = 2
ang$moccu[ang$moccu == "Private Soldier"] = 5
ang$moccu[ang$moccu == "Private, Cape Corps"] = 5
ang$moccu[ang$moccu == "Private, Cape Peninsula Regiment"] = 5
ang$moccu[ang$moccu == "Private, East Lancashire Regiment"] = 5
ang$moccu[ang$moccu == "Private, Royal Garrison Artillery"] = 5
ang$moccu[ang$moccu == "Private, Royal Marines"] = 5
ang$moccu[ang$moccu == "Private, S.A. Police Battalion "] = 5
ang$moccu[ang$moccu == "Probation Fireman S.A.R."] = 9
ang$moccu[ang$moccu == "Process Engineer"] = 0
ang$moccu[ang$moccu == "Process Engraver"] = 9
ang$moccu[ang$moccu == "Process hand in Dynamite Factory"] = 9
ang$moccu[ang$moccu == "Process Operator(Oil)"] = 8
ang$moccu[ang$moccu == "Process worker"] = 9
ang$moccu[ang$moccu == "Process Worker"] = 9
ang$moccu[ang$moccu == "Processing Engraver"] = 9
ang$moccu[ang$moccu == "Produce Dealer"] = 4
ang$moccu[ang$moccu == "Produce Merchant"] = 4
ang$moccu[ang$moccu == "Product Executive"] = 4
ang$moccu[ang$moccu == "Product Manager"] = 2
ang$moccu[ang$moccu == "Production Clerk"] = 3
ang$moccu[ang$moccu == "Production Controller"] = 2
ang$moccu[ang$moccu == "Production Engineer"] = 0
ang$moccu[ang$moccu == "Production Foreman"] = 2
ang$moccu[ang$moccu == "Production Manager"] = 2
ang$moccu[ang$moccu == "Production Mechanic"] = 8
ang$moccu[ang$moccu == "Production Planner"] = 3
ang$moccu[ang$moccu == "Production Planner Overseer"] = 2
ang$moccu[ang$moccu == "Production Trainer"] = 1
ang$moccu[ang$moccu == "Professional Fireman"] = 9
ang$moccu[ang$moccu == "Professional Forrester"] = 6
ang$moccu[ang$moccu == "Professional Golfer"] = 1
ang$moccu[ang$moccu == "Professional Seaman"] = 9
ang$moccu[ang$moccu == "Professional Soldier"] = 5
ang$moccu[ang$moccu == "Professor of Chemistry"] = 0
ang$moccu[ang$moccu == "Professor of History, S.A. College"] = 1
ang$moccu[ang$moccu == "Professor of Pharmacology, UCT"] = 0
ang$moccu[ang$moccu == "Professor Univ. of Cape Town"] = 1
ang$moccu[ang$moccu == "Programme Compiler S.A.B.C."] = 3
ang$moccu[ang$moccu == "Projectionist"] = 8
ang$moccu[ang$moccu == "Promotional Adviser"] = 2
ang$moccu[ang$moccu == "Proof Reader"] = 3
ang$moccu[ang$moccu == "Property Consultant"] = 4
ang$moccu[ang$moccu == "Property Economist"] = 0
ang$moccu[ang$moccu == "Property Valver"] = 4
ang$moccu[ang$moccu == "Proprietor"] = 2
ang$moccu[ang$moccu == "Proprietor - General Dealer"] = 2
ang$moccu[ang$moccu == "Proprietor Boarding House"] = 2
ang$moccu[ang$moccu == "Proprietor of Private Hotel"] = 2
ang$moccu[ang$moccu == "Proprietor of Retail Store"] = 2
ang$moccu[ang$moccu == "Prospector"] = 2
ang$moccu[ang$moccu == "Provincial Administration Employee"] = 9
ang$moccu[ang$moccu == "Provincial Traffic Officer"] = 5
ang$moccu[ang$moccu == "Pruner"] = 6
ang$moccu[ang$moccu == "Public Accountant"] = 1
ang$moccu[ang$moccu == "Public Health Training Assistant"] = 5
ang$moccu[ang$moccu == "Public Prosecutor"] = 1
ang$moccu[ang$moccu == "Public Relations Officer"] = 2
ang$moccu[ang$moccu == "Public worker"] = 9
ang$moccu[ang$moccu == "Publican"] = 5
ang$moccu[ang$moccu == "Publisher"] = 1
ang$moccu[ang$moccu == "Publishers Editor"] = 1
ang$moccu[ang$moccu == "Publishers Manager"] = 2
ang$moccu[ang$moccu == "Pump and meter mechanic"] = 8
ang$moccu[ang$moccu == "Pump Mechanic"] = 8
ang$moccu[ang$moccu == "Pump mechanic"] = 8
ang$moccu[ang$moccu == "Pumpman"] = 8
ang$moccu[ang$moccu == "Pupil"] = NA
ang$moccu[ang$moccu == "Pupil Air Observer"] = 0
ang$moccu[ang$moccu == "Pupil Engineer S.A.R."] = 0
ang$moccu[ang$moccu == "Pupil Pilot R.A.F."] = 0
ang$moccu[ang$moccu == "Pupil Technician"] = 0
ang$moccu[ang$moccu == "Pupil-Technician"] = 0
ang$moccu[ang$moccu == "Purifier"] = 5
ang$moccu[ang$moccu == "Purser"] = 3
ang$moccu[ang$moccu == "Purser - Merchant Navy"] = 3
ang$moccu[ang$moccu == "Quality Technician"] = 0
ang$moccu[ang$moccu == "Quantity Surveyor"] = 0
ang$moccu[ang$moccu == "Quantity surveyor"] = 0
ang$moccu[ang$moccu == "Quarry Manager"] = 2
ang$moccu[ang$moccu == "Quarry miner"] = 7
ang$moccu[ang$moccu == "Quarryman"] = 7
ang$moccu[ang$moccu == "Quarry-worker"] = 7
ang$moccu[ang$moccu == "Quarter Binder"] = 9
ang$moccu[ang$moccu == "Quarts-binder"] = 9
ang$moccu[ang$moccu == "Quilt-maker"] = 7
ang$moccu[ang$moccu == "R.A.F."] = 5
ang$moccu[ang$moccu == "R.A.F. Active Service"] = 5
ang$moccu[ang$moccu == "R.A.F. Police"] = 5
ang$moccu[ang$moccu == "R.D.F. Navy"] = 5
ang$moccu[ang$moccu == "R.N. Canteen Manager"] = 2
ang$moccu[ang$moccu == "R+H Tank Corps"] = 9
ang$moccu[ang$moccu == "Radar Mechanic"] = 8
ang$moccu[ang$moccu == "Radar Service Engineer"] = 0
ang$moccu[ang$moccu == "Radar Technician"] = 0
ang$moccu[ang$moccu == "Radio Electrical Mechanic"] = 8
ang$moccu[ang$moccu == "Radio Electrical Mechanic R.N."] = 8
ang$moccu[ang$moccu == "Radio Electrician"] = 8
ang$moccu[ang$moccu == "Radio Engineer"] = 0
ang$moccu[ang$moccu == "Radio mechanic"] = 8
ang$moccu[ang$moccu == "Radio Mechanic"] = 8
ang$moccu[ang$moccu == "Radio Mechanic S.A.A.F."] = 8
ang$moccu[ang$moccu == "Radio Officer"] = 8
ang$moccu[ang$moccu == "Radio Officer (Merchant Navy)"] = 8
ang$moccu[ang$moccu == "Radio Operator"] = 3
ang$moccu[ang$moccu == "Radio Serviceman"] = 3
ang$moccu[ang$moccu == "Radio Technician"] = 0
ang$moccu[ang$moccu == "Radio Telegraphist R.N."] = 3
ang$moccu[ang$moccu == "Radiographer"] = 0
ang$moccu[ang$moccu == "Radiotrician"] = 8
ang$moccu[ang$moccu == "Radio-Trician"] = 8
ang$moccu[ang$moccu == "RAF Officer"] = 5
ang$moccu[ang$moccu == "Rail Porter"] = 9
ang$moccu[ang$moccu == "Rail worker"] = 9
ang$moccu[ang$moccu == "Rail Worker"] = 9
ang$moccu[ang$moccu == "Rail Worker S.A.R."] = 9
ang$moccu[ang$moccu == "Railway"] = 9
ang$moccu[ang$moccu == "Railway + Harbour Police"] = 5
ang$moccu[ang$moccu == "Railway Attendant"] = 9
ang$moccu[ang$moccu == "Railway Barrier-attendant"] = 9
ang$moccu[ang$moccu == "Railway Bedding Boy"] = 5
ang$moccu[ang$moccu == "Railway Catering Dept."] = 5
ang$moccu[ang$moccu == "Railway Checker"] = 3
ang$moccu[ang$moccu == "Railway Cleaner"] = 5
ang$moccu[ang$moccu == "Railway Clerk"] = 3
ang$moccu[ang$moccu == "Railway Constable"] = 5
ang$moccu[ang$moccu == "Railway Dept. Messenger"] = 3
ang$moccu[ang$moccu == "Railway Dispenser"] = 0
ang$moccu[ang$moccu == "Railway Electrician"] = 8
ang$moccu[ang$moccu == "Railway Employee"] = 9
ang$moccu[ang$moccu == "Railway employee"] = 9
ang$moccu[ang$moccu == "Railway Engine Driver"] = 9
ang$moccu[ang$moccu == "Railway Engineer"] = 0
ang$moccu[ang$moccu == "Railway Fireman"] = 9
ang$moccu[ang$moccu == "Railway Foreman"] = 2
ang$moccu[ang$moccu == "Railway Ganger"] = 2
ang$moccu[ang$moccu == "Railway Goods Clerk"] = 3
ang$moccu[ang$moccu == "Railway Guard"] = 5
ang$moccu[ang$moccu == "Railway labourer"] = 9
ang$moccu[ang$moccu == "Railway Labourer"] = 9
ang$moccu[ang$moccu == "Railway man"] = 9
ang$moccu[ang$moccu == "Railway Motor Driver"] = 9
ang$moccu[ang$moccu == "Railway Official"] = 3
ang$moccu[ang$moccu == "Railway Overseer"] = 3
ang$moccu[ang$moccu == "Railway Pantryman"] = 5
ang$moccu[ang$moccu == "Railway Pensioner"] = 9
ang$moccu[ang$moccu == "Railway Pointsman"] = 9
ang$moccu[ang$moccu == "Railway Police"] = 5
ang$moccu[ang$moccu == "Railway Policeman"] = 5
ang$moccu[ang$moccu == "Railway Porter"] = 9
ang$moccu[ang$moccu == "Railway servant"] = 5
ang$moccu[ang$moccu == "Railway Servant"] = 5
ang$moccu[ang$moccu == "Railway Servant Guard"] = 5
ang$moccu[ang$moccu == "Railway Servant S.A.R."] = 5
ang$moccu[ang$moccu == "Railway Service"] = 9
ang$moccu[ang$moccu == "Railway Shunter"] = 9
ang$moccu[ang$moccu == "Railway Signalman"] = 9
ang$moccu[ang$moccu == "Railway Storeman"] = 3
ang$moccu[ang$moccu == "Railway Stores"] = 9
ang$moccu[ang$moccu == "Railway Tram Driver"] = 9
ang$moccu[ang$moccu == "Railway worker"] = 9
ang$moccu[ang$moccu == "Railway Worker"] = 9
ang$moccu[ang$moccu == "Railway-Car Builder"] = 8
ang$moccu[ang$moccu == "Railwayman"] = 9
ang$moccu[ang$moccu == "Railway-man"] = 9
ang$moccu[ang$moccu == "Railworker"] = 9
ang$moccu[ang$moccu == "Railworker S.A.R"] = 9
ang$moccu[ang$moccu == "Railworker S.A.R."] = 9
ang$moccu[ang$moccu == "Rancher"] = 6
ang$moccu[ang$moccu == "Reader"] = 3
ang$moccu[ang$moccu == "ReaderCompositor"] = 3
ang$moccu[ang$moccu == "Record Assistant"] = 3
ang$moccu[ang$moccu == "Record Clerk S.A.R."] = 3
ang$moccu[ang$moccu == "Reeder"] = 6
ang$moccu[ang$moccu == "Refrigerating Engineer"] = 0
ang$moccu[ang$moccu == "Refrigeration Mechanic"] = 8
ang$moccu[ang$moccu == "Refrigeration mechanic"] = 8
ang$moccu[ang$moccu == "Refrigerator Engineer"] = 0
ang$moccu[ang$moccu == "Refrigerator mechanic"] = 8
ang$moccu[ang$moccu == "Regional Welfare Advisor"] = 2
ang$moccu[ang$moccu == "Registered Carrier"] = 9
ang$moccu[ang$moccu == "Registering Officer"] = 3
ang$moccu[ang$moccu == "Registrar (Clerk)"] = 3
ang$moccu[ang$moccu == "Regular"] = 5
ang$moccu[ang$moccu == "Relief Clerk S.A.R."] = 3
ang$moccu[ang$moccu == "Relief Foreman"] = 2
ang$moccu[ang$moccu == "Relief Shunter"] = 9
ang$moccu[ang$moccu == "Relief Signalman S.A.R."] = 9
ang$moccu[ang$moccu == "Relief Station Master"] = 2
ang$moccu[ang$moccu == "Relieving Manager"] = 2
ang$moccu[ang$moccu == "Relieving Station-master"] = 2
ang$moccu[ang$moccu == "Repairer"] = 9
ang$moccu[ang$moccu == "Report man"] = 3
ang$moccu[ang$moccu == "Report Man Driver"] = 9
ang$moccu[ang$moccu == "Reporter"] = 1
ang$moccu[ang$moccu == "Reporter + Clerk"] = 3
ang$moccu[ang$moccu == "Reportman driver"] = 9
ang$moccu[ang$moccu == "Reportman Driver"] = 9
ang$moccu[ang$moccu == "Representative"] = 4
ang$moccu[ang$moccu == "Representative "] = 4
ang$moccu[ang$moccu == "Representative I.C.I."] = 4
ang$moccu[ang$moccu == "Representative Salesman"] = 4
ang$moccu[ang$moccu == "Representative Timber Merchant"] = 4
ang$moccu[ang$moccu == "Representative Vacuum Oil Co."] = 4
ang$moccu[ang$moccu == "Representative, Distillers Corporation"] = 4
ang$moccu[ang$moccu == "Representative, Finance Company"] = 4
ang$moccu[ang$moccu == "Research Assistant"] = 4
ang$moccu[ang$moccu == "Research Chemist"] = 0
ang$moccu[ang$moccu == "Research Marine Biologist"] = 0
ang$moccu[ang$moccu == "Research Officer"] = 1
ang$moccu[ang$moccu == "Research Physicist"] = 0
ang$moccu[ang$moccu == "Research Student"] = 0
ang$moccu[ang$moccu == "Resident Magistrate"] = 1
ang$moccu[ang$moccu == "Restaurant keeper"] = 5
ang$moccu[ang$moccu == "Restaurant Manager"] = 2
ang$moccu[ang$moccu == "Restaurant Proprietor"] = 2
ang$moccu[ang$moccu == "Retail Manager"] = 2
ang$moccu[ang$moccu == "Retail Manufacturer"] = 4
ang$moccu[ang$moccu == "Retailer"] = 4
ang$moccu[ang$moccu == "Retired"] = NA
ang$moccu[ang$moccu == "Retired "] = NA
ang$moccu[ang$moccu == "Retired (Musical Merchant)"] = 4
ang$moccu[ang$moccu == "Retired Army"] = 5
ang$moccu[ang$moccu == "Retired Army Officer"] = 5
ang$moccu[ang$moccu == "Retired Bank Inspector"] = 2
ang$moccu[ang$moccu == "Retired Bank Manager"] = 2
ang$moccu[ang$moccu == "Retired Banker"] = 4
ang$moccu[ang$moccu == "Retired Blacksmith"] = 8
ang$moccu[ang$moccu == "Retired Builder"] = 9
ang$moccu[ang$moccu == "Retired Businessman"] = 4
ang$moccu[ang$moccu == "Retired Civil Servant"] = 3
ang$moccu[ang$moccu == "Retired Engineer"] = 0
ang$moccu[ang$moccu == "Retired Executive South African Mutual"] = 2
ang$moccu[ang$moccu == "Retired Farmer"] = 6
ang$moccu[ang$moccu == "Retired Foreman"] = 2
ang$moccu[ang$moccu == "Retired Gentleman"] = NA
ang$moccu[ang$moccu == "Retired Headmaster"] = 1
ang$moccu[ang$moccu == "Retired Hotelier"] = 2
ang$moccu[ang$moccu == "Retired Imperial Civil Servant"] = 3
ang$moccu[ang$moccu == "Retired Industrial Missionary"] = 1
ang$moccu[ang$moccu == "Retired Insurance Agent"] = 4
ang$moccu[ang$moccu == "Retired Landowner"] = 6
ang$moccu[ang$moccu == "Retired Merchant"] = 4
ang$moccu[ang$moccu == "Retired Painter"] = 9
ang$moccu[ang$moccu == "Retired Police Officer"] = 3
ang$moccu[ang$moccu == "Retired Postmaster"] = 3
ang$moccu[ang$moccu == "Retired Professor"] = 1
ang$moccu[ang$moccu == "Retired Railway Official"] = 3
ang$moccu[ang$moccu == "Retired Railwayman"] = 9
ang$moccu[ang$moccu == "Retired Royal Navy"] = 5
ang$moccu[ang$moccu == "Retired S.A.R. Engine Driver"] = 9
ang$moccu[ang$moccu == "Retired S.A.R. Servant"] = 5
ang$moccu[ang$moccu == "Retired Schoolmaster"] = 1
ang$moccu[ang$moccu == "Retired Soldier"] = 5
ang$moccu[ang$moccu == "Retired WE Driver"] = 9
ang$moccu[ang$moccu == "Retort Attendant"] = 5
ang$moccu[ang$moccu == "Revenue Clerk"] = 3
ang$moccu[ang$moccu == "Rhodesia Railways"] = 9
ang$moccu[ang$moccu == "Rhodesian Govt. Service"] = 3
ang$moccu[ang$moccu == "Rhodesian Railway "] = 9
ang$moccu[ang$moccu == "Rhodesian Railways"] = 9
ang$moccu[ang$moccu == "Rhodesian Railways "] = 9
ang$moccu[ang$moccu == "Rifleman Cape Peninsula Rifles"] = 5
ang$moccu[ang$moccu == "Rifleman S.A.M.R."] = 5
ang$moccu[ang$moccu == "Rigger"] = 9
ang$moccu[ang$moccu == "Rigger (S.A. Navy)"] = 9
ang$moccu[ang$moccu == "Rigger + Diver"] = 9
ang$moccu[ang$moccu == "Rigger at elevator"] = 9
ang$moccu[ang$moccu == "Riveter"] = 8
ang$moccu[ang$moccu == "Rivetter"] = 8
ang$moccu[ang$moccu == "Road Construction"] = 9
ang$moccu[ang$moccu == "Road Construction Foreman"] = 2
ang$moccu[ang$moccu == "Road Construction Labourer"] = 9
ang$moccu[ang$moccu == "Road Contractor"] = 9
ang$moccu[ang$moccu == "Road labourer"] = 9
ang$moccu[ang$moccu == "Road maker"] = 9
ang$moccu[ang$moccu == "Road mender"] = 9
ang$moccu[ang$moccu == "Road Motor Service S.A.R.+H."] = 9
ang$moccu[ang$moccu == "Road Overseer"] = 2
ang$moccu[ang$moccu == "Road worker"] = 9
ang$moccu[ang$moccu == "Roadmaker + Soldier"] = 5
ang$moccu[ang$moccu == "Rodent Exterminator"] = 9
ang$moccu[ang$moccu == "Roller Driver S.A.R."] = 9
ang$moccu[ang$moccu == "Roof Fixer"] = 9
ang$moccu[ang$moccu == "Roof Tiler"] = 9
ang$moccu[ang$moccu == "Roofing Contractor"] = 2
ang$moccu[ang$moccu == "Roofing Employee"] = 9
ang$moccu[ang$moccu == "Roof-seater(Building Trade)"] = 9
ang$moccu[ang$moccu == "Royal Air Force"] = 5
ang$moccu[ang$moccu == "Royal Air Force Fitter"] = 8
ang$moccu[ang$moccu == "Royal Air Force Officer"] = 5
ang$moccu[ang$moccu == "Royal Army Medical Corps"] = 0
ang$moccu[ang$moccu == "Royal Army Service"] = 5
ang$moccu[ang$moccu == "Royal Artillery"] = 5
ang$moccu[ang$moccu == "Royal Engineer"] = 0
ang$moccu[ang$moccu == "Royal Garrison Artillery"] = 5
ang$moccu[ang$moccu == "Royal Marine"] = 5
ang$moccu[ang$moccu == "Royal Marine Musician"] = 1
ang$moccu[ang$moccu == "Royal Marines"] = 5
ang$moccu[ang$moccu == "Royal Naval Patrol Service"] = 5
ang$moccu[ang$moccu == "Royal Navy"] = 5
ang$moccu[ang$moccu == "Royal Navy A.B.S.T."] = 5
ang$moccu[ang$moccu == "Royal Navy H.M.S. Florida "] = 5
ang$moccu[ang$moccu == "Royal Observatory"] = NA
ang$moccu[ang$moccu == "Rubber Planter"] = 6
ang$moccu[ang$moccu == "Rubber stamp maker"] = 9
ang$moccu[ang$moccu == "Rubbertyre vulcaniser"] = 9
ang$moccu[ang$moccu == "Rule Bender"] = 9
ang$moccu[ang$moccu == "Ruler in Printing Trade"] = 9
ang$moccu[ang$moccu == "Runner"] = 5
ang$moccu[ang$moccu == "S.A. Air Force"] = 5
ang$moccu[ang$moccu == "S.A. Air Service"] = 5
ang$moccu[ang$moccu == "S.A. Artillery"] = 5
ang$moccu[ang$moccu == "S.A. Defence Force"] = 5
ang$moccu[ang$moccu == "S.A. Engineering Corps"] = 0
ang$moccu[ang$moccu == "S.A. Marines"] = 5
ang$moccu[ang$moccu == "S.A. Naval Band"] = 1
ang$moccu[ang$moccu == "S.A. Naval Force"] = 5
ang$moccu[ang$moccu == "S.A. Naval Forces"] = 5
ang$moccu[ang$moccu == "S.A. Navy"] = 5
ang$moccu[ang$moccu == "S.A. Police"] = 5
ang$moccu[ang$moccu == "S.A. Police Constable"] = 5
ang$moccu[ang$moccu == "S.A. Police Corporal"] = 5
ang$moccu[ang$moccu == "S.A. Policeman"] = 5
ang$moccu[ang$moccu == "S.A. Railway"] = 9
ang$moccu[ang$moccu == "S.A. Railway Police"] = 5
ang$moccu[ang$moccu == "S.A. Railway Works"] = 9
ang$moccu[ang$moccu == "S.A. Railways"] = 9
ang$moccu[ang$moccu == "S.A. Railways + Harbour"] = 9
ang$moccu[ang$moccu == "S.A. Tank Corps"] = 5
ang$moccu[ang$moccu == "S.A.(V.)R.N."] = NA
ang$moccu[ang$moccu == "S.A.A.F."] = 5
ang$moccu[ang$moccu == "S.A.A.F. Air Corporal"] = 5
ang$moccu[ang$moccu == "S.A.F. Infantry"] = 5
ang$moccu[ang$moccu == "S.A.M.C."] = 5
ang$moccu[ang$moccu == "S.A.M.R."] = NA
ang$moccu[ang$moccu == "S.A.N. Forces"] = 5
ang$moccu[ang$moccu == "S.A.N.F."] = 5
ang$moccu[ang$moccu == "S.A.N.S.Q."] = 5
ang$moccu[ang$moccu == "S.A.P."] = 5
ang$moccu[ang$moccu == "S.A.R."] = 9
ang$moccu[ang$moccu == "S.A.R. Catering Dept."] = 5
ang$moccu[ang$moccu == "S.A.R. Crane-driver"] = 9
ang$moccu[ang$moccu == "S.A.R. Employee"] = 9
ang$moccu[ang$moccu == "S.A.R. Guard"] = 5
ang$moccu[ang$moccu == "S.A.R. Labourer"] = 9
ang$moccu[ang$moccu == "S.A.R. Official"] = 3
ang$moccu[ang$moccu == "S.A.R. Operative"] = NA
ang$moccu[ang$moccu == "S.A.R. Rail Worker in Publicity + Travel Stores"] = 9
ang$moccu[ang$moccu == "S.A.R. Sanitary Dept."] = 5
ang$moccu[ang$moccu == "S.A.R.+H. Employee"] = 9
ang$moccu[ang$moccu == "S.A.Railways"] = 9
ang$moccu[ang$moccu == "S.B.A.(R.N.)"] = NA
ang$moccu[ang$moccu == "S.B.P. Officer"] = 5
ang$moccu[ang$moccu == "Sack mender"] = 7
ang$moccu[ang$moccu == "Saddle Maker"] = 7
ang$moccu[ang$moccu == "Saddlemaker"] = 7
ang$moccu[ang$moccu == "Saddle-maker"] = 7
ang$moccu[ang$moccu == "Saddler"] = 7
ang$moccu[ang$moccu == "Saddler + Harness-maker"] = 7
ang$moccu[ang$moccu == "Safe-painter"] = 9
ang$moccu[ang$moccu == "Sail maker"] = 7
ang$moccu[ang$moccu == "Sailmaker"] = 7
ang$moccu[ang$moccu == "Sail-maker"] = 7
ang$moccu[ang$moccu == "Sailmaker R.N."] = 7
ang$moccu[ang$moccu == "Sailmaker Royal Navy"] = 7
ang$moccu[ang$moccu == "Sailor"] = 9
ang$moccu[ang$moccu == "Sailor in Royal Navy"] = 5
ang$moccu[ang$moccu == "Sailor on Trawler"] = 9
ang$moccu[ang$moccu == "Sailor R.N."] = 5
ang$moccu[ang$moccu == "Sailor Royal Navy"] = 5
ang$moccu[ang$moccu == "Sailor S.A.N.F."] = 5
ang$moccu[ang$moccu == "Sailor Stoker R.N."] = 5
ang$moccu[ang$moccu == "Sailor-Leading Signalman"] = 5
ang$moccu[ang$moccu == "Sales analysist"] = 4
ang$moccu[ang$moccu == "Sales Assistant"] = 4
ang$moccu[ang$moccu == "Sales Clerk"] = 3
ang$moccu[ang$moccu == "Sales clerk"] = 3
ang$moccu[ang$moccu == "Sales Consultant"] = 4
ang$moccu[ang$moccu == "Sales Engineer"] = 0
ang$moccu[ang$moccu == "Sales Executive"] = 2
ang$moccu[ang$moccu == "Sales Manager"] = 2
ang$moccu[ang$moccu == "Sales Manager Shell Co."] = 2
ang$moccu[ang$moccu == "Sales Promotion Assistant"] = 4
ang$moccu[ang$moccu == "Sales Representative"] = 4
ang$moccu[ang$moccu == "Sales Supervisor"] = 2
ang$moccu[ang$moccu == "Sales, Service, Engineer"] = 0
ang$moccu[ang$moccu == "Salesman"] = 4
ang$moccu[ang$moccu == "Salesman at Wine Merchant"] = 4
ang$moccu[ang$moccu == "Salesman Clerk"] = 3
ang$moccu[ang$moccu == "Salesman in Hardware"] = 4
ang$moccu[ang$moccu == "Salesman Scott Bros."] = 4
ang$moccu[ang$moccu == "Salesman Shell Co."] = 4
ang$moccu[ang$moccu == "Salesman Shell Company"] = 4
ang$moccu[ang$moccu == "Salesman, Shell Co."] = 4
ang$moccu[ang$moccu == "Salesmanager"] = 2
ang$moccu[ang$moccu == "Sales-Manager"] = 2
ang$moccu[ang$moccu == "Salesman-clerk"] = 3
ang$moccu[ang$moccu == "Salesman-Clerk"] = 3
ang$moccu[ang$moccu == "Saloon Attendant"] = 5
ang$moccu[ang$moccu == "Saloon Attendant C.G.R."] = 5
ang$moccu[ang$moccu == "Salt River Works"] = 9
ang$moccu[ang$moccu == "Sandal Maker"] = 7
ang$moccu[ang$moccu == "Sander"] = 9
ang$moccu[ang$moccu == "Sanding Machinist"] = 8
ang$moccu[ang$moccu == "Sandpaper Hand"] = 9
ang$moccu[ang$moccu == "Sandpaperer"] = 9
ang$moccu[ang$moccu == "Sanitary Engineer"] = 0
ang$moccu[ang$moccu == "Sanitary Inspector"] = 2
ang$moccu[ang$moccu == "Sanitary Porter"] = 9
ang$moccu[ang$moccu == "Sanitary Porter S.A.R."] = 9
ang$moccu[ang$moccu == "Sanitory Inspector"] = 2
ang$moccu[ang$moccu == "Sanitory Porter S.A.R."] = 9
ang$moccu[ang$moccu == "Sapper + Miner"] = 5
ang$moccu[ang$moccu == "Sapper S.A. Engineer Corps"] = 0
ang$moccu[ang$moccu == "Sapper S.A. Engineers"] = 0
ang$moccu[ang$moccu == "Sapper S.A.E.C."] = 0
ang$moccu[ang$moccu == "Sargeant in Military Service"] = 5
ang$moccu[ang$moccu == "Saw Doctor "] = 8
ang$moccu[ang$moccu == "Saw doctor S.A.R.+H."] = 8
ang$moccu[ang$moccu == "Saw sharpener"] = 8
ang$moccu[ang$moccu == "Sawmill Operator"] = 8
ang$moccu[ang$moccu == "Sawmill Supervisor"] = 2
ang$moccu[ang$moccu == "Sawmill worker"] = 9
ang$moccu[ang$moccu == "Sawyer"] = 7
ang$moccu[ang$moccu == "Scale Fitter"] = 8
ang$moccu[ang$moccu == "Scale Mechanic"] = 8
ang$moccu[ang$moccu == "Scale-Fitter"] = 8
ang$moccu[ang$moccu == "Scaler - Ship building"] = 8
ang$moccu[ang$moccu == "Scenic Artist"] = 1
ang$moccu[ang$moccu == "School Caretaker"] = 5
ang$moccu[ang$moccu == "School cleaner"] = 5
ang$moccu[ang$moccu == "School Cleaner"] = 5
ang$moccu[ang$moccu == "School Master"] = 1
ang$moccu[ang$moccu == "School Principal"] = 1
ang$moccu[ang$moccu == "School Teacher"] = 1
ang$moccu[ang$moccu == "School teacher"] = 1
ang$moccu[ang$moccu == "Schoolmaster"] = 1
ang$moccu[ang$moccu == "Schoolmaster Catechist"] = 1
ang$moccu[ang$moccu == "Schoolmaster in Holy Orders"] = 1
ang$moccu[ang$moccu == "Scientific Expert"] = 0
ang$moccu[ang$moccu == "Scientist"] = 0
ang$moccu[ang$moccu == "Scientist (Falkland Island Service)"] = 0
ang$moccu[ang$moccu == "Scooter Driver"] = 9
ang$moccu[ang$moccu == "Scourer in shoe trade"] = 8
ang$moccu[ang$moccu == "Scourer Leather Industry"] = 8
ang$moccu[ang$moccu == "Scrap Dealer"] = 4
ang$moccu[ang$moccu == "Scrap Metal Dealer"] = 4
ang$moccu[ang$moccu == "Screen Printer"] = 9
ang$moccu[ang$moccu == "Screener in Milling Factory"] = 9
ang$moccu[ang$moccu == "Screen-worker"] = 9
ang$moccu[ang$moccu == "Scullion S.A.R."] = 5
ang$moccu[ang$moccu == "Sculptor"] = 1
ang$moccu[ang$moccu == "Sea Captain"] = 5
ang$moccu[ang$moccu == "Sealer"] = 8
ang$moccu[ang$moccu == "Sealer Shipbuilding"] = 8
ang$moccu[ang$moccu == "Seam Presser"] = 7
ang$moccu[ang$moccu == "Seaman"] = 5
ang$moccu[ang$moccu == "Seaman Engineer"] = 0
ang$moccu[ang$moccu == "Seaman M.N."] = 5
ang$moccu[ang$moccu == "Seaman Merchant Navy"] = 5
ang$moccu[ang$moccu == "Seaman R.N."] = 5
ang$moccu[ang$moccu == "Seaman S.A. Naval Forces"] = 5
ang$moccu[ang$moccu == "Seaman S.A.N.F."] = 5
ang$moccu[ang$moccu == "Seaman(Whaling Vessel)"] = 5
ang$moccu[ang$moccu == "Second Engineer"] = 0
ang$moccu[ang$moccu == "Secondhand Dealer"] = 4
ang$moccu[ang$moccu == "Secretarial Clerk"] = 3
ang$moccu[ang$moccu == "Secretary"] = 3
ang$moccu[ang$moccu == "Secretary - Manager"] = 2
ang$moccu[ang$moccu == "Secretary (F. Robb Co.)"] = 2
ang$moccu[ang$moccu == "Secretary (Tramway Co.)"] = 3
ang$moccu[ang$moccu == "Secretary Accountant"] = 1
ang$moccu[ang$moccu == "Secretary and Accountant"] = 1
ang$moccu[ang$moccu == "Secretary City Tramways Co."] = 3
ang$moccu[ang$moccu == "Secretary in Chamber of Commerce"] = 3
ang$moccu[ang$moccu == "Secretary of Kelvin Grove"] = 3
ang$moccu[ang$moccu == "Secretary of Mining Companies Johannesburg"] = 2
ang$moccu[ang$moccu == "Secretary Salt Works"] = 2
ang$moccu[ang$moccu == "Secretary to Gold Company"] = 3
ang$moccu[ang$moccu == "Secretary to Governor-General"] = 3
ang$moccu[ang$moccu == "Secretary Trade Association"] = 2
ang$moccu[ang$moccu == "Secretary, Agricultural Society"] = 2
ang$moccu[ang$moccu == "Secretary, Chamber of Industries"] = 2
ang$moccu[ang$moccu == "Secretary, Fire Insurance Council"] = 2
ang$moccu[ang$moccu == "Secretary, Royal Observatory"] = 2
ang$moccu[ang$moccu == "SecretaryAccountant"] = 1
ang$moccu[ang$moccu == "Secretarys Office, General Post Office"] = 3
ang$moccu[ang$moccu == "Section Commander S.A. Anti-Aircraft Regt."] = 5
ang$moccu[ang$moccu == "Section Man"] = 1
ang$moccu[ang$moccu == "Section man Tobacco Factory"] = 1
ang$moccu[ang$moccu == "Sectionman"] = 1
ang$moccu[ang$moccu == "Security Guard"] = 5
ang$moccu[ang$moccu == "Security Officer"] = 5
ang$moccu[ang$moccu == "Seedsman"] = 6
ang$moccu[ang$moccu == "Self-employed Boatbuilder"] = 8
ang$moccu[ang$moccu == "Senior Administrative Clerk"] = 3
ang$moccu[ang$moccu == "Senior Air Craftsman R.A.F."] = 5
ang$moccu[ang$moccu == "Senior Armament Instructor Royal Air Force"] = 1
ang$moccu[ang$moccu == "Senior Audit Clerk"] = 3
ang$moccu[ang$moccu == "Senior Chaplain"] = 1
ang$moccu[ang$moccu == "Senior Clerk"] = 1
ang$moccu[ang$moccu == "Senior Clerk, City Council"] = 1
ang$moccu[ang$moccu == "Senior Porter"] = 9
ang$moccu[ang$moccu == "Senior Post Office Clerk"] = 3
ang$moccu[ang$moccu == "Senior Research Officer"] = 1
ang$moccu[ang$moccu == "Sergeant"] = 5
ang$moccu[ang$moccu == "Sergeant "] = 5
ang$moccu[ang$moccu == "Sergeant 24th Regiment"] = 5
ang$moccu[ang$moccu == "Sergeant 7th Reg."] = 5
ang$moccu[ang$moccu == "Sergeant A.P.C."] = 5
ang$moccu[ang$moccu == "Sergeant A.S.C."] = 5
ang$moccu[ang$moccu == "Sergeant Army"] = 5
ang$moccu[ang$moccu == "Sergeant C.P."] = 5
ang$moccu[ang$moccu == "Sergeant Cape Corps"] = 5
ang$moccu[ang$moccu == "Sergeant Cape Garrison Artillery"] = 5
ang$moccu[ang$moccu == "Sergeant Commander"] = 5
ang$moccu[ang$moccu == "Sergeant in 2nd Yorkshire Regiment"] = 5
ang$moccu[ang$moccu == "Sergeant in Yorkshire Regiment"] = 5
ang$moccu[ang$moccu == "Sergeant Native Military Corps"] = 5
ang$moccu[ang$moccu == "Sergeant of Hospital"] = 5
ang$moccu[ang$moccu == "Sergeant of Police"] = 5
ang$moccu[ang$moccu == "Sergeant Police Force"] = 5
ang$moccu[ang$moccu == "Sergeant Policeman"] = 5
ang$moccu[ang$moccu == "Sergeant R.A."] = 5
ang$moccu[ang$moccu == "Sergeant R.A.F"] = 5
ang$moccu[ang$moccu == "Sergeant R.A.F. On Active Service "] = 5
ang$moccu[ang$moccu == "Sergeant Rifle Brigade"] = 5
ang$moccu[ang$moccu == "Sergeant Royal Air Force"] = 5
ang$moccu[ang$moccu == "Sergeant Royal Engineer"] = 0
ang$moccu[ang$moccu == "Sergeant Royal West African Frontier Forces"] = 5
ang$moccu[ang$moccu == "Sergeant S.A. Air Force"] = 5
ang$moccu[ang$moccu == "Sergeant S.A. Constabulary"] = 5
ang$moccu[ang$moccu == "Sergeant S.A. Engineer Corps"] = 0
ang$moccu[ang$moccu == "Sergeant S.A. Police Battalion"] = 5
ang$moccu[ang$moccu == "Sergeant S.A.A.F."] = 5
ang$moccu[ang$moccu == "Sergeant S.A.R.+H. Brigade"] = 5
ang$moccu[ang$moccu == "Sergeant U.D.F."] = 5
ang$moccu[ang$moccu == "Sergeant, 9th S.A.I."] = 5
ang$moccu[ang$moccu == "Sergeant-at-Arms"] = 5
ang$moccu[ang$moccu == "Serjeant Royal Artillery"] = 5
ang$moccu[ang$moccu == "Serjeant(Police)"] = 5
ang$moccu[ang$moccu == "Serjeant, Imperial Forces"] = 5
ang$moccu[ang$moccu == "Servant"] = 5
ang$moccu[ang$moccu == "Servant at Govt. Farm"] = 5
ang$moccu[ang$moccu == "Service Adviser"] = 1
ang$moccu[ang$moccu == "Service attendant"] = 5
ang$moccu[ang$moccu == "Service Attendant"] = 5
ang$moccu[ang$moccu == "Service Engineer"] = 0
ang$moccu[ang$moccu == "Service Manager"] = 2
ang$moccu[ang$moccu == "Service Mechanic"] = 8
ang$moccu[ang$moccu == "Service Refrigeration Mechanic"] = 8
ang$moccu[ang$moccu == "Service Station"] = 9
ang$moccu[ang$moccu == "Serviceman"] = 8
ang$moccu[ang$moccu == "Service-man"] = 8
ang$moccu[ang$moccu == "Serving in Defence Forces"] = 5
ang$moccu[ang$moccu == "Serving Officer R.A.F."] = 5
ang$moccu[ang$moccu == "Sewing Machine Mechanic"] = 8
ang$moccu[ang$moccu == "Sewing machine mechanic"] = 8
ang$moccu[ang$moccu == "Sewing-machine Mechanic"] = 8
ang$moccu[ang$moccu == "Sexton"] = 1
ang$moccu[ang$moccu == "Sgt. 2nd. C.P.R. 1st Reserve Brigade"] = 5
ang$moccu[ang$moccu == "Sgt. Infantry"] = 5
ang$moccu[ang$moccu == "Sgt. R.A.F."] = 5
ang$moccu[ang$moccu == "Sgt.-Major U.D.F."] = 5
ang$moccu[ang$moccu == "Shed Attendant"] = 9
ang$moccu[ang$moccu == "Shedman S.A.R."] = 3
ang$moccu[ang$moccu == "Sheep Expert"] = 6
ang$moccu[ang$moccu == "Sheep Skin Dresser"] = 7
ang$moccu[ang$moccu == "Sheet metal worker"] = 7
ang$moccu[ang$moccu == "Sheet Metal worker"] = 7
ang$moccu[ang$moccu == "Sheet Metal Worker"] = 7
ang$moccu[ang$moccu == "Sheet Metal worker "] = 7
ang$moccu[ang$moccu == "Sheet metal worker + Plumber"] = 7
ang$moccu[ang$moccu == "Sheet Metal Worker S.A.R."] = 7
ang$moccu[ang$moccu == "Sheet Metallist"] = 7
ang$moccu[ang$moccu == "Sheetmetal worker"] = 7
ang$moccu[ang$moccu == "Sheet-Metal worker"] = 7
ang$moccu[ang$moccu == "Shell Co."] = 9
ang$moccu[ang$moccu == "Shell Co. Representative"] = 4
ang$moccu[ang$moccu == "Shell Trainee-Representative"] = 4
ang$moccu[ang$moccu == "Shift Engineer"] = 0
ang$moccu[ang$moccu == "Shiftman"] = 9
ang$moccu[ang$moccu == "Shiftsman at Power Station"] = 9
ang$moccu[ang$moccu == "Shingle-layer"] = 9
ang$moccu[ang$moccu == "Shingler + Carpenter"] = 9
ang$moccu[ang$moccu == "Ship carpenter"] = 9
ang$moccu[ang$moccu == "Ship-fitter"] = 8
ang$moccu[ang$moccu == "Shipkeeper under Admiralty"] = 5
ang$moccu[ang$moccu == "Shipmaster"] = 0
ang$moccu[ang$moccu == "Shipper"] = 9
ang$moccu[ang$moccu == "Shippers Agent"] = 4
ang$moccu[ang$moccu == "Shippers Representative"] = 4
ang$moccu[ang$moccu == "Shipping"] = 9
ang$moccu[ang$moccu == "Shipping Agent"] = 4
ang$moccu[ang$moccu == "Shipping agent"] = 4
ang$moccu[ang$moccu == "Shipping Clerk"] = 3
ang$moccu[ang$moccu == "Shipping clerk"] = 3
ang$moccu[ang$moccu == "Shipping Consultant"] = 2
ang$moccu[ang$moccu == "Shipping Manager"] = 2
ang$moccu[ang$moccu == "Shipping Representative"] = 4
ang$moccu[ang$moccu == "Shipping Supervisor"] = 2
ang$moccu[ang$moccu == "Ships 2nd Engineer"] = 0
ang$moccu[ang$moccu == "Ships Agent"] = 4
ang$moccu[ang$moccu == "Ships Boatswain"] = 2
ang$moccu[ang$moccu == "Ships Cook"] = 5
ang$moccu[ang$moccu == "Ships Engineer"] = 0
ang$moccu[ang$moccu == "Ships Engineering Officer"] = 0
ang$moccu[ang$moccu == "Ships Fireman"] = 9
ang$moccu[ang$moccu == "Ships greaser"] = 8
ang$moccu[ang$moccu == "Ships Guard"] = 5
ang$moccu[ang$moccu == "Ships labourer"] = 9
ang$moccu[ang$moccu == "Ships lagger"] = 9
ang$moccu[ang$moccu == "Ships Officer"] = 2
ang$moccu[ang$moccu == "Ships Plumber"] = 8
ang$moccu[ang$moccu == "Ships Steward"] = 5
ang$moccu[ang$moccu == "Ships Steward S.A.N.F."] = 5
ang$moccu[ang$moccu == "Ships Writer"] = 1
ang$moccu[ang$moccu == "Shipwright"] = 8
ang$moccu[ang$moccu == "Shipwright "] = 8
ang$moccu[ang$moccu == "Shipwright S.A.R.+H."] = 8
ang$moccu[ang$moccu == "Shipwright-joiner "] = 8
ang$moccu[ang$moccu == "Shipwrights labourer"] = 9
ang$moccu[ang$moccu == "Shirt Cutter"] = 7
ang$moccu[ang$moccu == "Shirt cutter"] = 7
ang$moccu[ang$moccu == "Shoe Cleaner"] = 5
ang$moccu[ang$moccu == "Shoe designer"] = 1
ang$moccu[ang$moccu == "Shoe Factory Employee"] = 8
ang$moccu[ang$moccu == "Shoe Factory Machinist"] = 8
ang$moccu[ang$moccu == "Shoe finisher"] = 8
ang$moccu[ang$moccu == "Shoe Grade Apprentice"] = 8
ang$moccu[ang$moccu == "Shoe Industry"] = 8
ang$moccu[ang$moccu == "Shoe Machinist"] = 8
ang$moccu[ang$moccu == "Shoe maker"] = 8
ang$moccu[ang$moccu == "Shoe operative"] = 8
ang$moccu[ang$moccu == "Shoe Repairer"] = 8
ang$moccu[ang$moccu == "Shoe repairer"] = 8
ang$moccu[ang$moccu == "Shoe Scourer"] = 5
ang$moccu[ang$moccu == "Shoe scourer"] = 5
ang$moccu[ang$moccu == "Shoe Trade"] = 4
ang$moccu[ang$moccu == "Shoe Trimmer"] = 8
ang$moccu[ang$moccu == "Shoe-finisher"] = 8
ang$moccu[ang$moccu == "Shoemaker"] = 8
ang$moccu[ang$moccu == "Shoe-maker"] = 8
ang$moccu[ang$moccu == "Shoemakers Apprentice"] = 8
ang$moccu[ang$moccu == "Shoe-pounder"] = 8
ang$moccu[ang$moccu == "Shoerepairer"] = 8
ang$moccu[ang$moccu == "Shoe-repairer"] = 8
ang$moccu[ang$moccu == "Shoe-repairing Manager"] = 2
ang$moccu[ang$moccu == "Shop assistant"] = 4
ang$moccu[ang$moccu == "Shop Assistant"] = 4
ang$moccu[ang$moccu == "Shop boy"] = 4
ang$moccu[ang$moccu == "Shop delivery-man"] = 9
ang$moccu[ang$moccu == "Shop Fitter"] = 8
ang$moccu[ang$moccu == "Shop manager"] = 2
ang$moccu[ang$moccu == "Shop Manager"] = 2
ang$moccu[ang$moccu == "Shop messenger"] = 3
ang$moccu[ang$moccu == "Shop Messenger"] = 3
ang$moccu[ang$moccu == "Shop Porter"] = 9
ang$moccu[ang$moccu == "Shop Window-dresser"] = 1
ang$moccu[ang$moccu == "Shop-assistant"] = 4
ang$moccu[ang$moccu == "Shop-boy"] = 4
ang$moccu[ang$moccu == "Shop-Boy Cleaner"] = 5
ang$moccu[ang$moccu == "Shopfitter"] = 8
ang$moccu[ang$moccu == "Shop-fitter"] = 8
ang$moccu[ang$moccu == "Shop-fitter-joiner"] = 8
ang$moccu[ang$moccu == "Shopfitters Assistant Foreman"] = 2
ang$moccu[ang$moccu == "Shopkeeper"] = 4
ang$moccu[ang$moccu == "Shopkeeper (On Active Service)"] = 4
ang$moccu[ang$moccu == "Shopman"] = 4
ang$moccu[ang$moccu == "Shopworker"] = 4
ang$moccu[ang$moccu == "Showman"] = 1
ang$moccu[ang$moccu == "Shunter"] = 9
ang$moccu[ang$moccu == "Shunter "] = 9
ang$moccu[ang$moccu == "Shunter C.G.R."] = 9
ang$moccu[ang$moccu == "Shunter S. Rhodesia Railways"] = 9
ang$moccu[ang$moccu == "Shunter S.A.R."] = 9
ang$moccu[ang$moccu == "Shunter S.A.R.+H."] = 9
ang$moccu[ang$moccu == "Side laster"] = 8
ang$moccu[ang$moccu == "Sign Artist"] = 1
ang$moccu[ang$moccu == "Signal fitter"] = 8
ang$moccu[ang$moccu == "Signal Fitter"] = 8
ang$moccu[ang$moccu == "Signal Fitter S.A.R."] = 8
ang$moccu[ang$moccu == "Signal-Fitter"] = 8
ang$moccu[ang$moccu == "Signaller S.A. Corps of Signals"] = 9
ang$moccu[ang$moccu == "Signalman"] = 9
ang$moccu[ang$moccu == "Signalman "] = 9
ang$moccu[ang$moccu == "Signalman C.G.R."] = 9
ang$moccu[ang$moccu == "Signalman R. N."] = 9
ang$moccu[ang$moccu == "Signalman R.N."] = 9
ang$moccu[ang$moccu == "Signalman Royal Navy"] = 9
ang$moccu[ang$moccu == "Signalman S.A. Navy"] = 9
ang$moccu[ang$moccu == "Signalman S.A.N.F."] = 9
ang$moccu[ang$moccu == "Signalman S.A.R."] = 9
ang$moccu[ang$moccu == "Signals, S.A. Navy"] = 9
ang$moccu[ang$moccu == "Signwriter"] = 3
ang$moccu[ang$moccu == "Sign-writer"] = 3
ang$moccu[ang$moccu == "Sign-writer + Decorator"] = 3
ang$moccu[ang$moccu == "Sign-writer S.A.R."] = 3
ang$moccu[ang$moccu == "Silk Buyer"] = 4
ang$moccu[ang$moccu == "Silk Screen Worker"] = 7
ang$moccu[ang$moccu == "Silverer in Plateglass"] = 7
ang$moccu[ang$moccu == "Silversmiths assistant"] = 7
ang$moccu[ang$moccu == "Skilled Labourer"] = 9
ang$moccu[ang$moccu == "Skilled labourer"] = 9
ang$moccu[ang$moccu == "Skilled Labourer "] = 9
ang$moccu[ang$moccu == "Skilled Labourer S.A.R."] = 9
ang$moccu[ang$moccu == "Skilled labourer S.A.R."] = 9
ang$moccu[ang$moccu == "Skilled Labourer Salt River Works"] = 9
ang$moccu[ang$moccu == "Skinner"] = 8
ang$moccu[ang$moccu == "Skinsorter"] = 8
ang$moccu[ang$moccu == "Skiver Leather Industry"] = 8
ang$moccu[ang$moccu == "Slater"] = 9
ang$moccu[ang$moccu == "Slaughter man"] = 7
ang$moccu[ang$moccu == "Slaughterer"] = 7
ang$moccu[ang$moccu == "Slaughterman"] = 7
ang$moccu[ang$moccu == "Smith"] = 7
ang$moccu[ang$moccu == "Smiths Striker"] = 7
ang$moccu[ang$moccu == "Snuff-maker"] = 7
ang$moccu[ang$moccu == "Soap Boiler"] = 5
ang$moccu[ang$moccu == "Soap Cutter"] = 5
ang$moccu[ang$moccu == "Soap-maker"] = 5
ang$moccu[ang$moccu == "Social Worker"] = 1
ang$moccu[ang$moccu == "Sodawater maker"] = 9
ang$moccu[ang$moccu == "Sodawater Manufacturer"] = 9
ang$moccu[ang$moccu == "Soils Laboratory Assistant"] = 0
ang$moccu[ang$moccu == "Soldier"] = 5
ang$moccu[ang$moccu == "Soldier + Bank clerk"] = 3
ang$moccu[ang$moccu == "Soldier + Carpenter"] = 5
ang$moccu[ang$moccu == "Soldier Air Force"] = 5
ang$moccu[ang$moccu == "Soldier C.T. Higlanders"] = 5
ang$moccu[ang$moccu == "Soldier Cape Corps"] = 5
ang$moccu[ang$moccu == "Soldier formerley Welder S.A.R."] = 5
ang$moccu[ang$moccu == "Soldier of the 99th"] = 5
ang$moccu[ang$moccu == "Soldier on Active Service"] = 5
ang$moccu[ang$moccu == "Soldier R.A.F."] = 5
ang$moccu[ang$moccu == "Soldier R.A.M.C."] = 5
ang$moccu[ang$moccu == "Soldier Royal Artillery"] = 5
ang$moccu[ang$moccu == "Soldier S.A. Permanent Force"] = 5
ang$moccu[ang$moccu == "Soldier S.A.E.C."] = 5
ang$moccu[ang$moccu == "Soldier S.A.F."] = 5
ang$moccu[ang$moccu == "Soldier S.A.F.C."] = 5
ang$moccu[ang$moccu == "Soldier U.D.F."] = 5
ang$moccu[ang$moccu == "Soldier(Cape Corps)"] = 5
ang$moccu[ang$moccu == "Soldier(Gunner)"] = 5
ang$moccu[ang$moccu == "Soldier(Private)"] = 5
ang$moccu[ang$moccu == "Soldier, Private Cape Corps"] = 5
ang$moccu[ang$moccu == "Soldier, Tank Corps"] = 5
ang$moccu[ang$moccu == "SoldierTransport Driver"] = 5
ang$moccu[ang$moccu == "Sole operator"] = 8
ang$moccu[ang$moccu == "Sole Presser Footwear Factory"] = 7
ang$moccu[ang$moccu == "Sole-cutter"] = 7
ang$moccu[ang$moccu == "Solicitor"] = 1
ang$moccu[ang$moccu == "Solicitor(Johannesburg)"] = 1
ang$moccu[ang$moccu == "Solicitors Clerk"] = 3
ang$moccu[ang$moccu == "Soreman"] = 4
ang$moccu[ang$moccu == "Sorter"] = 9
ang$moccu[ang$moccu == "Sorter G.P.O."] = 9
ang$moccu[ang$moccu == "Sorter in G.P.O."] = 9
ang$moccu[ang$moccu == "Sorter S.A.R.+H."] = 9
ang$moccu[ang$moccu == "South African Air Force"] = 5
ang$moccu[ang$moccu == "South African Brewery"] = 7
ang$moccu[ang$moccu == "South African Navy"] = 5
ang$moccu[ang$moccu == "South African Police"] = 5
ang$moccu[ang$moccu == "Spares Assistant"] = 9
ang$moccu[ang$moccu == "Spares Manager"] = 2
ang$moccu[ang$moccu == "Spares Salesman"] = 4
ang$moccu[ang$moccu == "Spares-assistant"] = 9
ang$moccu[ang$moccu == "Special Constable"] = 5
ang$moccu[ang$moccu == "Special Grade School Teacher"] = 1
ang$moccu[ang$moccu == "Speculator"] = 4
ang$moccu[ang$moccu == "Spindlehand at Cabinet maker"] = 8
ang$moccu[ang$moccu == "Spinner"] = 7
ang$moccu[ang$moccu == "Spinner at Blanket Factory"] = 7
ang$moccu[ang$moccu == "Splitter"] = 7
ang$moccu[ang$moccu == "Sports Outfitter"] = 4
ang$moccu[ang$moccu == "Sports Stringer"] = 8
ang$moccu[ang$moccu == "Spot Welder"] = 8
ang$moccu[ang$moccu == "Spray Painter"] = 9
ang$moccu[ang$moccu == "Spray painter"] = 9
ang$moccu[ang$moccu == "Sprayer"] = 7
ang$moccu[ang$moccu == "Sprayer - Shoe Trade"] = 8
ang$moccu[ang$moccu == "Spray-painter"] = 9
ang$moccu[ang$moccu == "Spring mattress maker"] = 7
ang$moccu[ang$moccu == "Spring-maker"] = 8
ang$moccu[ang$moccu == "Spring-maker in Cabinet Works"] = 8
ang$moccu[ang$moccu == "Springsmith S.A.R."] = 8
ang$moccu[ang$moccu == "Stable boy"] = 6
ang$moccu[ang$moccu == "Stable Foreman (Cape Town Corporation)"] = 2
ang$moccu[ang$moccu == "Stable groom"] = 6
ang$moccu[ang$moccu == "Stable-boy"] = 6
ang$moccu[ang$moccu == "Stablekeeper"] = 6
ang$moccu[ang$moccu == "Stableman"] = 6
ang$moccu[ang$moccu == "Stable-man"] = 6
ang$moccu[ang$moccu == "Stableman S.A.R.+H."] = 6
ang$moccu[ang$moccu == "Stacker"] = 9
ang$moccu[ang$moccu == "Stacker-Truck Driver"] = 9
ang$moccu[ang$moccu == "Staff Officer Union Defence Force"] = 5
ang$moccu[ang$moccu == "Staff Permanent Defence Force"] = 5
ang$moccu[ang$moccu == "Staff Sergeant"] = 5
ang$moccu[ang$moccu == "Staff Sergeant A.S.C."] = 5
ang$moccu[ang$moccu == "Staff Sergeant D.E.O.R."] = 5
ang$moccu[ang$moccu == "Staff Sergeant S.A.M.C."] = 5
ang$moccu[ang$moccu == "Staff-Sergeant U.D.F."] = 5
ang$moccu[ang$moccu == "Stage Director"] = 1
ang$moccu[ang$moccu == "Stainer"] = 7
ang$moccu[ang$moccu == "Stainer+Polisher"] = 7
ang$moccu[ang$moccu == "Staion Foreman S.A.R."] = 2
ang$moccu[ang$moccu == "Stamper G.P.O."] = 3
ang$moccu[ang$moccu == "Stamper in Soap Factory"] = 5
ang$moccu[ang$moccu == "Stamper Shoe Industry"] = 8
ang$moccu[ang$moccu == "Standard Bank Official"] = 3
ang$moccu[ang$moccu == "Staple-laster Leather Trade"] = 8
ang$moccu[ang$moccu == "Station foreman"] = 2
ang$moccu[ang$moccu == "Station Foreman"] = 2
ang$moccu[ang$moccu == "Station Foreman S.A.R."] = 2
ang$moccu[ang$moccu == "Station Foreman, Traffic Dept. Beira and Mashonaland Railways"] = 2
ang$moccu[ang$moccu == "Station Master"] = 2
ang$moccu[ang$moccu == "Station Officer Fire Brigade"] = 2
ang$moccu[ang$moccu == "Stationary Plant Operator"] = 8
ang$moccu[ang$moccu == "Stationer"] = 4
ang$moccu[ang$moccu == "Stationery Packer, National Bank"] = 9
ang$moccu[ang$moccu == "Stationmaster"] = 2
ang$moccu[ang$moccu == "Station-master"] = 2
ang$moccu[ang$moccu == "Statistician"] = 0
ang$moccu[ang$moccu == "Steam Ship Agent"] = 4
ang$moccu[ang$moccu == "Steam-hammer Worker S.A.R."] = 8
ang$moccu[ang$moccu == "Steel bender"] = 7
ang$moccu[ang$moccu == "Steel fixer + Bender"] = 7
ang$moccu[ang$moccu == "Steel fixing"] = 7
ang$moccu[ang$moccu == "Steel furniture Assembler"] = 7
ang$moccu[ang$moccu == "Steel Metal Worker"] = 7
ang$moccu[ang$moccu == "Steel Structure"] = 7
ang$moccu[ang$moccu == "Steel window mechanic"] = 7
ang$moccu[ang$moccu == "Steel Window Operator"] = 8
ang$moccu[ang$moccu == "Steel-fixer"] = 8
ang$moccu[ang$moccu == "Steelmetal worker"] = 7
ang$moccu[ang$moccu == "Steeplejack"] = 9
ang$moccu[ang$moccu == "Stencil Cutter"] = 7
ang$moccu[ang$moccu == "Stencil-cutter"] = 7
ang$moccu[ang$moccu == "Stenciller"] = 7
ang$moccu[ang$moccu == "Stereotype labourer"] = 9
ang$moccu[ang$moccu == "Stereotyper"] = 9
ang$moccu[ang$moccu == "Stereo-typer"] = 9
ang$moccu[ang$moccu == "Stevedore"] = 9
ang$moccu[ang$moccu == "Stevedore Foreman"] = 2
ang$moccu[ang$moccu == "Steward"] = 5
ang$moccu[ang$moccu == "Steward (in CafΘ)"] = 5
ang$moccu[ang$moccu == "Steward (Seaman)"] = 5
ang$moccu[ang$moccu == "Steward at Sea"] = 5
ang$moccu[ang$moccu == "Steward C.G.R."] = 5
ang$moccu[ang$moccu == "Steward Defence"] = 5
ang$moccu[ang$moccu == "Steward on mail train"] = 5
ang$moccu[ang$moccu == "Steward Rhodesian Railways"] = 5
ang$moccu[ang$moccu == "Steward S.A.R."] = 5
ang$moccu[ang$moccu == "Steward S.A.R. (Catering Dept.)"] = 5
ang$moccu[ang$moccu == "Steward, City Club"] = 5
ang$moccu[ang$moccu == "Steward, Officers Club Simonstown"] = 5
ang$moccu[ang$moccu == "Stitcher"] = 7
ang$moccu[ang$moccu == "Stitcher Shoe Factory"] = 8
ang$moccu[ang$moccu == "Stock Assistant"] = 3
ang$moccu[ang$moccu == "Stock clerk"] = 3
ang$moccu[ang$moccu == "Stock Clerk"] = 3
ang$moccu[ang$moccu == "Stock Control Clerk"] = 3
ang$moccu[ang$moccu == "Stock Controller"] = 3
ang$moccu[ang$moccu == "Stockbroker"] = 4
ang$moccu[ang$moccu == "Stock-broker"] = 4
ang$moccu[ang$moccu == "Stock-choser"] = 3
ang$moccu[ang$moccu == "Stock-keeper"] = 3
ang$moccu[ang$moccu == "Stockman"] = 3
ang$moccu[ang$moccu == "Stoker"] = 9
ang$moccu[ang$moccu == "Stoker "] = 9
ang$moccu[ang$moccu == "Stoker 1st Class"] = 9
ang$moccu[ang$moccu == "Stoker H.M.S. Dublin"] = 9
ang$moccu[ang$moccu == "Stoker Mechanic"] = 8
ang$moccu[ang$moccu == "Stoker Petty Officer"] = 5
ang$moccu[ang$moccu == "Stoker R.N."] = 9
ang$moccu[ang$moccu == "Stoker Royal Navy"] = 9
ang$moccu[ang$moccu == "Stoker S.A. Navy"] = 9
ang$moccu[ang$moccu == "Stoker S.A.N.F."] = 9
ang$moccu[ang$moccu == "Stoker S.A.R."] = 9
ang$moccu[ang$moccu == "Stoker S.A.R.+H."] = 9
ang$moccu[ang$moccu == "Stone cutter"] = 9
ang$moccu[ang$moccu == "Stone dresser"] = 9
ang$moccu[ang$moccu == "Stone Dresser"] = 9
ang$moccu[ang$moccu == "Stone Mason"] = 9
ang$moccu[ang$moccu == "Stone mason"] = 9
ang$moccu[ang$moccu == "Stone Polisher"] = 9
ang$moccu[ang$moccu == "Stone splitter"] = 9
ang$moccu[ang$moccu == "Stone-carver Mason"] = 9
ang$moccu[ang$moccu == "Stone-cutter"] = 9
ang$moccu[ang$moccu == "Stonemason"] = 9
ang$moccu[ang$moccu == "Stone-mason"] = 9
ang$moccu[ang$moccu == "Stone-mason(On Active Service)"] = 9
ang$moccu[ang$moccu == "Stone-polisher"] = 9
ang$moccu[ang$moccu == "Storage Manager"] = 2
ang$moccu[ang$moccu == "Store Assistant"] = 4
ang$moccu[ang$moccu == "Store Boy"] = 4
ang$moccu[ang$moccu == "Store Clerk"] = 3
ang$moccu[ang$moccu == "Store Delivery-man"] = 9
ang$moccu[ang$moccu == "Store labourer"] = 9
ang$moccu[ang$moccu == "Store labourer S.A.R.+H."] = 9
ang$moccu[ang$moccu == "Store labourer Tobacco factory"] = 9
ang$moccu[ang$moccu == "Store Manager"] = 2
ang$moccu[ang$moccu == "Store messenger"] = 3
ang$moccu[ang$moccu == "Store owner"] = 4
ang$moccu[ang$moccu == "Store packer"] = 9
ang$moccu[ang$moccu == "Store Packer"] = 9
ang$moccu[ang$moccu == "Store Packer S.A.R."] = 9
ang$moccu[ang$moccu == "Store Porter"] = 9
ang$moccu[ang$moccu == "Store worker"] = 4
ang$moccu[ang$moccu == "Store Worker"] = 4
ang$moccu[ang$moccu == "Storeboy"] = 4
ang$moccu[ang$moccu == "Store-Boy"] = 4
ang$moccu[ang$moccu == "Store-boy"] = 4
ang$moccu[ang$moccu == "Storeboy Queens Hotel Sea Point"] = 4
ang$moccu[ang$moccu == "Storehouse assistant"] = 3
ang$moccu[ang$moccu == "Storekeeper"] = 4
ang$moccu[ang$moccu == "Store-keeper"] = 4
ang$moccu[ang$moccu == "Storekeepers Assistant"] = 4
ang$moccu[ang$moccu == "Storeman"] = 3
ang$moccu[ang$moccu == "Storeman "] = 3
ang$moccu[ang$moccu == "Storeman - Railways"] = 3
ang$moccu[ang$moccu == "Storeman (On Active Service )"] = 3
ang$moccu[ang$moccu == "Storeman (Railway Harbours)"] = 3
ang$moccu[ang$moccu == "Storeman City Council"] = 3
ang$moccu[ang$moccu == "Storeman Civil Service Club"] = 3
ang$moccu[ang$moccu == "Storeman G.P.O."] = 3
ang$moccu[ang$moccu == "Storeman S.A.R."] = 3
ang$moccu[ang$moccu == "Storeman Vacuum Oil Co."] = 3
ang$moccu[ang$moccu == "Storeman(Bottle Store)"] = 3
ang$moccu[ang$moccu == "Storeman-driver"] = 9
ang$moccu[ang$moccu == "Storemans assistant"] = 3
ang$moccu[ang$moccu == "Storemans labourer"] = 9
ang$moccu[ang$moccu == "Store-packer"] = 9
ang$moccu[ang$moccu == "Stores assistant"] = 3
ang$moccu[ang$moccu == "Stores Assistant"] = 3
ang$moccu[ang$moccu == "Stores Assistant S.A. Navy"] = 3
ang$moccu[ang$moccu == "Stores Clerk"] = 3
ang$moccu[ang$moccu == "Stores Issuer"] = 3
ang$moccu[ang$moccu == "Stores Labourer (Private Cape Corps)"] = 9
ang$moccu[ang$moccu == "Stores Labourer S.A.R."] = 9
ang$moccu[ang$moccu == "Stores motor driver"] = 9
ang$moccu[ang$moccu == "Stores-Clerk"] = 3
ang$moccu[ang$moccu == "Storeworker"] = 4
ang$moccu[ang$moccu == "Stowhand"] = 9
ang$moccu[ang$moccu == "Strawbag maker"] = 7
ang$moccu[ang$moccu == "Street cleaner"] = 5
ang$moccu[ang$moccu == "Streetkeeper"] = 5
ang$moccu[ang$moccu == "Striker"] = 9
ang$moccu[ang$moccu == "Striker - Tram Co."] = 9
ang$moccu[ang$moccu == "Striker Railway Works"] = 9
ang$moccu[ang$moccu == "Striker S.A.R."] = 9
ang$moccu[ang$moccu == "Stringer"] = 9
ang$moccu[ang$moccu == "Strong Room Attendant"] = NA
ang$moccu[ang$moccu == "Structural Engineer"] = 0
ang$moccu[ang$moccu == "Structural Steel Worker"] = 7
ang$moccu[ang$moccu == "Student"] = NA
ang$moccu[ang$moccu == "Student - Land Surveying"] = 0
ang$moccu[ang$moccu == "Student Geologist"] = 0
ang$moccu[ang$moccu == "Student of Biscuit ????"] = NA
ang$moccu[ang$moccu == "Student of Chartered Accounting"] = 1
ang$moccu[ang$moccu == "Student of Music"] = 1
ang$moccu[ang$moccu == "Student Quantity Surveyor"] = 0
ang$moccu[ang$moccu == "Student Teacher"] = 1
ang$moccu[ang$moccu == "Sub. Foreman"] = 2
ang$moccu[ang$moccu == "Sub. Lieut. S.A. Navy"] = 5
ang$moccu[ang$moccu == "Sub.Lt. S.A.N.F."] = 5
ang$moccu[ang$moccu == "Sub-Inspector of Police"] = 2
ang$moccu[ang$moccu == "Sub-Lieut. S.A.N.F."] = 5
ang$moccu[ang$moccu == "Sub-Lieutenant S.A.Naval Forces"] = 5
ang$moccu[ang$moccu == "Sub-station Attendant"] = 8
ang$moccu[ang$moccu == "Sugar Boiler"] = 7
ang$moccu[ang$moccu == "Sugar boiler"] = 7
ang$moccu[ang$moccu == "Sugar Farmer"] = 2
ang$moccu[ang$moccu == "Sugar-boiler"] = 7
ang$moccu[ang$moccu == "Suitcase maker"] = 7
ang$moccu[ang$moccu == "Suitcase-maker"] = 7
ang$moccu[ang$moccu == "Superintendent"] = 2
ang$moccu[ang$moccu == "Superintendent of Police"] = 2
ang$moccu[ang$moccu == "Superintendent of Smallpox Hospital"] = 2
ang$moccu[ang$moccu == "Superintendent Old Somerset Hospital"] = 2
ang$moccu[ang$moccu == "Superintendent S.A.R."] = 2
ang$moccu[ang$moccu == "Supervising Manager"] = 2
ang$moccu[ang$moccu == "Supervisor"] = 2
ang$moccu[ang$moccu == "Supervisor at Benedictine Liqueur Co."] = 2
ang$moccu[ang$moccu == "Supervisor Eastern Telegraph Company"] = 2
ang$moccu[ang$moccu == "Supply Chief Petty Officer R.N."] = 5
ang$moccu[ang$moccu == "Supply Officer R.N."] = 3
ang$moccu[ang$moccu == "Surgeon"] = 0
ang$moccu[ang$moccu == "Surgeon & Physician"] = 0
ang$moccu[ang$moccu == "Surgeon Dentist"] = 0
ang$moccu[ang$moccu == "Surgeon Lieutenant Royal Navy"] = 0
ang$moccu[ang$moccu == "Surgeon Royal Navy"] = 0
ang$moccu[ang$moccu == "Surgeon, Lieut. R.N. "] = 0
ang$moccu[ang$moccu == "Surgical instrument maker"] = 8
ang$moccu[ang$moccu == "Surgical Instrument Maker"] = 8
ang$moccu[ang$moccu == "Survey Cadastrial Technician"] = 0
ang$moccu[ang$moccu == "Surveying Assistant"] = 0
ang$moccu[ang$moccu == "Surveyor"] = 0
ang$moccu[ang$moccu == "Surveyor City Hall"] = 0
ang$moccu[ang$moccu == "Surveyor Draughtsman"] = 0
ang$moccu[ang$moccu == "Survey-Researcher"] = 0
ang$moccu[ang$moccu == "Swedish Consulate Service"] = 2
ang$moccu[ang$moccu == "Sweeper"] = 9
ang$moccu[ang$moccu == "Sweeper Docks"] = 9
ang$moccu[ang$moccu == "Sweeper S.A.R."] = 9
ang$moccu[ang$moccu == "Sweet factory-hand"] = 7
ang$moccu[ang$moccu == "Sweet Maker"] = 7
ang$moccu[ang$moccu == "Sweetmaker"] = 7
ang$moccu[ang$moccu == "Sweet-maker"] = 7
ang$moccu[ang$moccu == "Switch Adjustor"] = NA
ang$moccu[ang$moccu == "Switch Board Operator"] = 3
ang$moccu[ang$moccu == "Switchboard Attendant"] = 3
ang$moccu[ang$moccu == "Switchboard Operator"] = 3
ang$moccu[ang$moccu == "Table-hand"] = 5
ang$moccu[ang$moccu == "Tailor"] = 7
ang$moccu[ang$moccu == "Tailoring Employee"] = 7
ang$moccu[ang$moccu == "Tailors apprentice"] = 7
ang$moccu[ang$moccu == "Tailors Assistant"] = 7
ang$moccu[ang$moccu == "Tailors cutter"] = 7
ang$moccu[ang$moccu == "Tailors Cutter"] = 7
ang$moccu[ang$moccu == "Tailors Fitter"] = 7
ang$moccu[ang$moccu == "Tailors Foreman"] = 2
ang$moccu[ang$moccu == "Tailors hand"] = 7
ang$moccu[ang$moccu == "Tailors Presser"] = 7
ang$moccu[ang$moccu == "Tailors shaper"] = 7
ang$moccu[ang$moccu == "Tanner"] = 7
ang$moccu[ang$moccu == "Tannery Employee"] = 7
ang$moccu[ang$moccu == "Tannery Labourer"] = 9
ang$moccu[ang$moccu == "Tax Inspector"] = 2
ang$moccu[ang$moccu == "Taxi driver"] = 9
ang$moccu[ang$moccu == "Taxi Driver"] = 9
ang$moccu[ang$moccu == "Taxi Proprietor"] = 9
ang$moccu[ang$moccu == "Taxidermist"] = NA
ang$moccu[ang$moccu == "Taxi-owner"] = 9
ang$moccu[ang$moccu == "Tea Planter"] = 6
ang$moccu[ang$moccu == "Teacher"] = 1
ang$moccu[ang$moccu == "Teacher Machine Service"] = 1
ang$moccu[ang$moccu == "Teacher of Science"] = 1
ang$moccu[ang$moccu == "Teacher Trainee"] = 1
ang$moccu[ang$moccu == "Technical adviser"] = NA
ang$moccu[ang$moccu == "Technical Adviser"] = NA
ang$moccu[ang$moccu == "Technical Analyst"] = 0
ang$moccu[ang$moccu == "Technical Assistant"] = 8
ang$moccu[ang$moccu == "Technical Assistant in Chemical Laboratory"] = 8
ang$moccu[ang$moccu == "Technical Assistant S.A. Museum"] = 8
ang$moccu[ang$moccu == "Technical Assistant University of Cape Town"] = 8
ang$moccu[ang$moccu == "Technical Assistant Vacuum Oil Co."] = 8
ang$moccu[ang$moccu == "Technical Assistant, Engineering"] = 0
ang$moccu[ang$moccu == "Technical Assistant, Town-Planning  Office"] = 8
ang$moccu[ang$moccu == "Technical Engineer"] = 0
ang$moccu[ang$moccu == "Technical Instructor"] = 1
ang$moccu[ang$moccu == "Technical Officer"] = NA
ang$moccu[ang$moccu == "Technical Representative"] = 4
ang$moccu[ang$moccu == "Technician"] = 0
ang$moccu[ang$moccu == "Technician Medical School"] = 0
ang$moccu[ang$moccu == "Telecom Engineer"] = 0
ang$moccu[ang$moccu == "Telecommunication technician"] = 0
ang$moccu[ang$moccu == "Telecommunication Technician"] = 0
ang$moccu[ang$moccu == "Telecommunications Electrician"] = 0
ang$moccu[ang$moccu == "Telecommunications Technician"] = 0
ang$moccu[ang$moccu == "Telegraph Assistant"] = 3
ang$moccu[ang$moccu == "Telegraph Clerk"] = 3
ang$moccu[ang$moccu == "Telegraph Electrician S.A.R.+H."] = 8
ang$moccu[ang$moccu == "Telegraph Engineer"] = 0
ang$moccu[ang$moccu == "Telegraph Engineer Post Office"] = 0
ang$moccu[ang$moccu == "Telegraph Linesman"] = 8
ang$moccu[ang$moccu == "Telegraph Mechanic"] = 8
ang$moccu[ang$moccu == "Telegraphist"] = 3
ang$moccu[ang$moccu == "Telegraphist Clerk"] = 3
ang$moccu[ang$moccu == "Telegraphist G.P.O."] = 3
ang$moccu[ang$moccu == "Telegraphist R.N."] = 3
ang$moccu[ang$moccu == "Telegraphist Royal Navy"] = 3
ang$moccu[ang$moccu == "Telegraphist S.A. Naval Force"] = 3
ang$moccu[ang$moccu == "Telegraphist S.A.R.+H."] = 3
ang$moccu[ang$moccu == "Telegraphist, Royal Navy"] = 3
ang$moccu[ang$moccu == "Telephone + Telegraph Electrician"] = 8
ang$moccu[ang$moccu == "Telephone + Telegraph Mechanician"] = 8
ang$moccu[ang$moccu == "Telephone Construction G.P.O."] = 8
ang$moccu[ang$moccu == "Telephone Dept. Mechanic"] = 8
ang$moccu[ang$moccu == "Telephone Electrician"] = 8
ang$moccu[ang$moccu == "Telephone Electrician G.P.O."] = 8
ang$moccu[ang$moccu == "Telephone Engineer"] = 0
ang$moccu[ang$moccu == "Telephone Exchange Superintendent"] = 2
ang$moccu[ang$moccu == "Telephone Fitter G.P.O."] = 8
ang$moccu[ang$moccu == "Telephone Fitters Mate"] = 8
ang$moccu[ang$moccu == "Telephone Foreman"] = 2
ang$moccu[ang$moccu == "Telephone Linesman"] = 8
ang$moccu[ang$moccu == "Telephone Mechanic"] = 8
ang$moccu[ang$moccu == "Telephone mechanician"] = 8
ang$moccu[ang$moccu == "Telephone Operator"] = 3
ang$moccu[ang$moccu == "Telephone Operator."] = 3
ang$moccu[ang$moccu == "Telephone technician"] = 0
ang$moccu[ang$moccu == "Telephone Technician"] = 0
ang$moccu[ang$moccu == "Telephone Wireman"] = 8
ang$moccu[ang$moccu == "Telephone Worker"] = 8
ang$moccu[ang$moccu == "Telephone Workman"] = 8
ang$moccu[ang$moccu == "Telephone-Operator"] = 3
ang$moccu[ang$moccu == "Telephonist"] = 3
ang$moccu[ang$moccu == "Telephonist G.P.O."] = 3
ang$moccu[ang$moccu == "Teller Standard Bank"] = 3
ang$moccu[ang$moccu == "Teller, Standard Bank"] = 3
ang$moccu[ang$moccu == "Tennis Coach"] = 1
ang$moccu[ang$moccu == "Tennis Court Contractor"] = 2
ang$moccu[ang$moccu == "Tennis court-layer"] = 9
ang$moccu[ang$moccu == "Tennis Racket Specialist"] = 9
ang$moccu[ang$moccu == "Tennis raquet stringer"] = 9
ang$moccu[ang$moccu == "Tennis-racket Repairer"] = 9
ang$moccu[ang$moccu == "Tennis-racket Stringer"] = 9
ang$moccu[ang$moccu == "Tennis-stringer"] = 9
ang$moccu[ang$moccu == "Terrazzo worker"] = 9
ang$moccu[ang$moccu == "Terrazzo Worker"] = 9
ang$moccu[ang$moccu == "Textile Dyer"] = 9
ang$moccu[ang$moccu == "Textile Engineer"] = 0
ang$moccu[ang$moccu == "Textile Knitter"] = 7
ang$moccu[ang$moccu == "Textile Machinist"] = 8
ang$moccu[ang$moccu == "Textile Packer"] = 9
ang$moccu[ang$moccu == "Textile Salesman"] = 4
ang$moccu[ang$moccu == "Textile Technician"] = 0
ang$moccu[ang$moccu == "Textile Weaver"] = 7
ang$moccu[ang$moccu == "Textile worker"] = 7
ang$moccu[ang$moccu == "Textile Worker"] = 7
ang$moccu[ang$moccu == "Thatcher"] = NA
ang$moccu[ang$moccu == "Theatre"] = NA
ang$moccu[ang$moccu == "Theatre Manager"] = 2
ang$moccu[ang$moccu == "Theatre Usher"] = 5
ang$moccu[ang$moccu == "Theological student"] = 1
ang$moccu[ang$moccu == "Ticket Clerk"] = 3
ang$moccu[ang$moccu == "Ticket Collector"] = 3
ang$moccu[ang$moccu == "Ticket Collector, C.G.R."] = 3
ang$moccu[ang$moccu == "Ticket Examiner"] = 3
ang$moccu[ang$moccu == "Ticket Examiner "] = 3
ang$moccu[ang$moccu == "Ticket Examiner C.G.R."] = 3
ang$moccu[ang$moccu == "Ticket Examiner S.A.R."] = 3
ang$moccu[ang$moccu == "Ticket Inspector"] = 3
ang$moccu[ang$moccu == "Tile Manufacturer"] = 9
ang$moccu[ang$moccu == "Tile-fixer"] = 9
ang$moccu[ang$moccu == "Tilemaker"] = 9
ang$moccu[ang$moccu == "Tiler"] = 9
ang$moccu[ang$moccu == "Tiler (Building Trade)"] = 9
ang$moccu[ang$moccu == "Tilers labourer"] = 9
ang$moccu[ang$moccu == "Timber Clerk"] = 3
ang$moccu[ang$moccu == "Timber merchant"] = 4
ang$moccu[ang$moccu == "Timber Merchant"] = 4
ang$moccu[ang$moccu == "Timber Merchants Delivery-man"] = 9
ang$moccu[ang$moccu == "Timber Merchants labourer"] = 9
ang$moccu[ang$moccu == "Timber Merchants Labourer"] = 9
ang$moccu[ang$moccu == "Timber merchants labourer"] = 9
ang$moccu[ang$moccu == "Timber Store labourer"] = 9
ang$moccu[ang$moccu == "Timber Store Labourer"] = 9
ang$moccu[ang$moccu == "Timber Warehouse Labourer"] = 9
ang$moccu[ang$moccu == "Timber Works Labourer"] = 9
ang$moccu[ang$moccu == "Timberman"] = NA
ang$moccu[ang$moccu == "Timber-yard labourer"] = 9
ang$moccu[ang$moccu == "Time Keeper"] = 3
ang$moccu[ang$moccu == "Time keeper"] = 3
ang$moccu[ang$moccu == "Timekeeper"] = 3
ang$moccu[ang$moccu == "Time-keeper"] = 3
ang$moccu[ang$moccu == "Timekeeper S.A.R."] = 3
ang$moccu[ang$moccu == "Timekeeper S.A.R.+H."] = 3
ang$moccu[ang$moccu == "Timekeeper, Robinson Deap Mines"] = 3
ang$moccu[ang$moccu == "Tinsmith"] = 7
ang$moccu[ang$moccu == "Tinsmith Biscuit Factory"] = 7
ang$moccu[ang$moccu == "Tinsmith S.A.R."] = 7
ang$moccu[ang$moccu == "Tinworker"] = 7
ang$moccu[ang$moccu == "Tobacco buyer"] = 4
ang$moccu[ang$moccu == "Tobacco Buyer"] = 4
ang$moccu[ang$moccu == "Tobacco Ceperator"] = 7
ang$moccu[ang$moccu == "Tobacco factory"] = 7
ang$moccu[ang$moccu == "Tobacco Factory Clicker"] = 3
ang$moccu[ang$moccu == "Tobacco Factory Labourer"] = 9
ang$moccu[ang$moccu == "Tobacco Farmer"] = 2
ang$moccu[ang$moccu == "Tobacco Manufacturer"] = 7
ang$moccu[ang$moccu == "Tobacco Manufacturers Machine-minder "] = 8
ang$moccu[ang$moccu == "Tobacco Operator"] = 8
ang$moccu[ang$moccu == "Tobacco planter"] = 6
ang$moccu[ang$moccu == "Tobacco worker"] = 7
ang$moccu[ang$moccu == "Tobacconist"] = 7
ang$moccu[ang$moccu == "Toe-laster"] = 7
ang$moccu[ang$moccu == "Tool Fitter"] = 8
ang$moccu[ang$moccu == "Tool setter"] = 8
ang$moccu[ang$moccu == "Toolboy Tramway Co."] = 8
ang$moccu[ang$moccu == "Toolmaker"] = 8
ang$moccu[ang$moccu == "Toolsetter"] = 8
ang$moccu[ang$moccu == "Toolsmith"] = 8
ang$moccu[ang$moccu == "Topographer"] = 0
ang$moccu[ang$moccu == "Torpedo-man R.N."] = 5
ang$moccu[ang$moccu == "Tow-motor Driver"] = 9
ang$moccu[ang$moccu == "Town Engineer"] = 0
ang$moccu[ang$moccu == "Town Treasurer"] = 2
ang$moccu[ang$moccu == "Toy-maker"] = 7
ang$moccu[ang$moccu == "Tractor Assembler"] = 8
ang$moccu[ang$moccu == "Tractor Driver"] = 6
ang$moccu[ang$moccu == "Trade Apprentice"] = 9
ang$moccu[ang$moccu == "Trade Journalist"] = 1
ang$moccu[ang$moccu == "Trade Surveyor"] = 0
ang$moccu[ang$moccu == "Trader"] = 4
ang$moccu[ang$moccu == "Tradesman"] = 4
ang$moccu[ang$moccu == "Traffic Constable"] = 5
ang$moccu[ang$moccu == "Traffic Inspector"] = 2
ang$moccu[ang$moccu == "Traffic Inspector On Active Service"] = 2
ang$moccu[ang$moccu == "Traffic Officer"] = 5
ang$moccu[ang$moccu == "Traffic Policeman"] = 5
ang$moccu[ang$moccu == "Traffic-Officer"] = 5
ang$moccu[ang$moccu == "Train Cleaner S.A.R."] = 5
ang$moccu[ang$moccu == "Train Driver"] = 9
ang$moccu[ang$moccu == "Train Guard"] = 5
ang$moccu[ang$moccu == "Trainee Accountant"] = 1
ang$moccu[ang$moccu == "Trainee Conductor"] = 3
ang$moccu[ang$moccu == "Trainee Electrician"] = 8
ang$moccu[ang$moccu == "Trainee Examiner"] = 3
ang$moccu[ang$moccu == "Trainee Executive"] = 2
ang$moccu[ang$moccu == "Trainee Field Engineer"] = 0
ang$moccu[ang$moccu == "Trainee fitter"] = 8
ang$moccu[ang$moccu == "Trainee Hotel Manager"] = 2
ang$moccu[ang$moccu == "Trainee Manager"] = 2
ang$moccu[ang$moccu == "Trainee Salesman"] = 4
ang$moccu[ang$moccu == "Trainee Welder"] = 8
ang$moccu[ang$moccu == "Trainee-Manager, Woolworths"] = 2
ang$moccu[ang$moccu == "Trainer"] = 1
ang$moccu[ang$moccu == "Trainer of Race horses"] = 6
ang$moccu[ang$moccu == "Trains Foreman S.A.R."] = 2
ang$moccu[ang$moccu == "Trains Recorder S.A.R."] = 3
ang$moccu[ang$moccu == "Tram Cleaner"] = 5
ang$moccu[ang$moccu == "Tram Conductor"] = 3
ang$moccu[ang$moccu == "Tram Driver"] = 9
ang$moccu[ang$moccu == "Tram Guard"] = 5
ang$moccu[ang$moccu == "Tram guard"] = 5
ang$moccu[ang$moccu == "Tram keeper"] = 5
ang$moccu[ang$moccu == "Trams Foreman"] = 2
ang$moccu[ang$moccu == "Tramway Conductor"] = 3
ang$moccu[ang$moccu == "Tramway Employee"] = 9
ang$moccu[ang$moccu == "Tramway Guard"] = 5
ang$moccu[ang$moccu == "Tramway labourer"] = 9
ang$moccu[ang$moccu == "Tramway Labourer"] = 9
ang$moccu[ang$moccu == "Tramway mechanics boy"] = 8
ang$moccu[ang$moccu == "Tramway Motorman"] = 9
ang$moccu[ang$moccu == "Tramway Pointsman"] = 9
ang$moccu[ang$moccu == "Tramway Repair Labourer"] = 9
ang$moccu[ang$moccu == "Tramway shunter"] = 9
ang$moccu[ang$moccu == "Tramways Apprentice"] = 9
ang$moccu[ang$moccu == "Tramways Company"] = 9
ang$moccu[ang$moccu == "Tramways Labourer"] = 9
ang$moccu[ang$moccu == "Transport Assistant"] = 9
ang$moccu[ang$moccu == "Transport Driver"] = 9
ang$moccu[ang$moccu == "Transport Engineer, Fitter R.A.F."] = 0
ang$moccu[ang$moccu == "Transport Manager"] = 9
ang$moccu[ang$moccu == "Transport Supervisor"] = 2
ang$moccu[ang$moccu == "Transportation Gang S.A.R."] = 9
ang$moccu[ang$moccu == "Travel Agent"] = 4
ang$moccu[ang$moccu == "Travel Manager"] = 2
ang$moccu[ang$moccu == "Traveller"] = 4
ang$moccu[ang$moccu == "Traveller for Engineering Firm"] = 4
ang$moccu[ang$moccu == "Traveller in Shoe Trade"] = 4
ang$moccu[ang$moccu == "Traveller, Int. Correspondence School"] = 4
ang$moccu[ang$moccu == "Travellers assistant"] = 4
ang$moccu[ang$moccu == "Travellers Assistant"] = 4
ang$moccu[ang$moccu == "Travellers driver"] = 9
ang$moccu[ang$moccu == "Travelling Representative"] = 4
ang$moccu[ang$moccu == "Trawler Deck-hand"] = 9
ang$moccu[ang$moccu == "Trawler-hand"] = 9
ang$moccu[ang$moccu == "Trawlerman"] = 2
ang$moccu[ang$moccu == "Trawler-man"] = 2
ang$moccu[ang$moccu == "Tree Pruner"] = 6
ang$moccu[ang$moccu == "Tree-cutter"] = 6
ang$moccu[ang$moccu == "Tree-trimmer"] = 6
ang$moccu[ang$moccu == "Trimmer"] = 8
ang$moccu[ang$moccu == "Trimmer - Motoring Trade"] = 8
ang$moccu[ang$moccu == "Trimmer Austin Motor Works"] = 8
ang$moccu[ang$moccu == "Trimmer Leather Industry"] = 8
ang$moccu[ang$moccu == "Trimmer S.A.R."] = 8
ang$moccu[ang$moccu == "Trimmer(Goodall & Williams)"] = 7
ang$moccu[ang$moccu == "Trimmer-cutter"] = 7
ang$moccu[ang$moccu == "Trolley-bus Conductor"] = 3
ang$moccu[ang$moccu == "Trooper"] = 3
ang$moccu[ang$moccu == "Trouserfitter"] = 7
ang$moccu[ang$moccu == "Trubenizing Collars"] = 7
ang$moccu[ang$moccu == "Truck Assembler"] = 8
ang$moccu[ang$moccu == "Truck Driver"] = 9
ang$moccu[ang$moccu == "Truck driver"] = 9
ang$moccu[ang$moccu == "Trunkmaker"] = 7
ang$moccu[ang$moccu == "Trunk-maker"] = 7
ang$moccu[ang$moccu == "Turbine Operator"] = 8
ang$moccu[ang$moccu == "Turbine Operator Electrical Power Station"] = 8
ang$moccu[ang$moccu == "Turf starter"] = 6
ang$moccu[ang$moccu == "Turncock"] = 9
ang$moccu[ang$moccu == "Turner"] = 8
ang$moccu[ang$moccu == "Turner + Fitter"] = 8
ang$moccu[ang$moccu == "Turner + Machinist"] = 8
ang$moccu[ang$moccu == "Turner C.G.R."] = 8
ang$moccu[ang$moccu == "Turner Machinist"] = 8
ang$moccu[ang$moccu == "Turner S.A.R."] = 8
ang$moccu[ang$moccu == "Twiner, Waverley Blankets"] = 7
ang$moccu[ang$moccu == "Tyler"] = 9
ang$moccu[ang$moccu == "Typeprinter"] = 9
ang$moccu[ang$moccu == "Typewriter mechanic"] = 8
ang$moccu[ang$moccu == "Typewriter Mechanic"] = 8
ang$moccu[ang$moccu == "Typewriter-mechanic"] = 8
ang$moccu[ang$moccu == "Typist"] = 3
ang$moccu[ang$moccu == "Typist Cape Times"] = 3
ang$moccu[ang$moccu == "Tyre fitter"] = 8
ang$moccu[ang$moccu == "Tyre Tester"] = 8
ang$moccu[ang$moccu == "Tyre-exchange hand  "] = 9
ang$moccu[ang$moccu == "U.D.F. Bandsman"] = 1
ang$moccu[ang$moccu == "U.D.F. Brooklyn Air Station"] = 5
ang$moccu[ang$moccu == "U.D.F. Employee"] = 5
ang$moccu[ang$moccu == "U.D.F.Instrument Repairer"] = 8
ang$moccu[ang$moccu == "Under presser"] = 7
ang$moccu[ang$moccu == "Underframe Maker"] = 8
ang$moccu[ang$moccu == "Under-frame Maker"] = 8
ang$moccu[ang$moccu == "Underframe Maker S.A.R."] = 8
ang$moccu[ang$moccu == "Underframe maker S.A.R."] = 8
ang$moccu[ang$moccu == "Under-Frame Maker S.A.R."] = 8
ang$moccu[ang$moccu == "Underframe-maker S.A.R."] = 8
ang$moccu[ang$moccu == "Undergraduate"] = NA
ang$moccu[ang$moccu == "Underground labourer"] = 7
ang$moccu[ang$moccu == "Underground Mine Surveyor"] = 0
ang$moccu[ang$moccu == "Undertaker"] = 5
ang$moccu[ang$moccu == "Undertakers Employee"] = 5
ang$moccu[ang$moccu == "Underwear Coster"] = 3
ang$moccu[ang$moccu == "Underwear Factory hand"] = 7
ang$moccu[ang$moccu == "Unemployed"] = NA
ang$moccu[ang$moccu == "Union Castle Clerk"] = 3
ang$moccu[ang$moccu == "Union Defence Force"] = 5
ang$moccu[ang$moccu == "United Tobacco Company"] = 7
ang$moccu[ang$moccu == "Unit-maker"] = 7
ang$moccu[ang$moccu == "University Lecturer"] = 1
ang$moccu[ang$moccu == "University Messenger"] = 3
ang$moccu[ang$moccu == "University Professor"] = 0
ang$moccu[ang$moccu == "University student"] = NA
ang$moccu[ang$moccu == "University Student"] = NA
ang$moccu[ang$moccu == "University Teacher"] = 1
ang$moccu[ang$moccu == "Upholsterer"] = 7
ang$moccu[ang$moccu == "Upholsterer S.A.R."] = 7
ang$moccu[ang$moccu == "Upholstery assistant"] = 7
ang$moccu[ang$moccu == "Usher"] = 5
ang$moccu[ang$moccu == "Valet"] = 5
ang$moccu[ang$moccu == "Valkenburg Attendant"] = 5
ang$moccu[ang$moccu == "Valuer (Auctioneering)"] = 4
ang$moccu[ang$moccu == "Van Conductor"] = 3
ang$moccu[ang$moccu == "Van Driver"] = 9
ang$moccu[ang$moccu == "Van driver"] = 9
ang$moccu[ang$moccu == "Van Guard"] = 5
ang$moccu[ang$moccu == "Van Porter S.A.R."] = 9
ang$moccu[ang$moccu == "Van-boy"] = 9
ang$moccu[ang$moccu == "Van-driver"] = 9
ang$moccu[ang$moccu == "Vanman"] = 9
ang$moccu[ang$moccu == "Van-man"] = 9
ang$moccu[ang$moccu == "Vegetable grower"] = 6
ang$moccu[ang$moccu == "Vegetable hawker"] = 4
ang$moccu[ang$moccu == "Vegetable Hawker"] = 4
ang$moccu[ang$moccu == "Vegetable Seller"] = 4
ang$moccu[ang$moccu == "Vegetable Vendor"] = 4
ang$moccu[ang$moccu == "Venearer"] = 8
ang$moccu[ang$moccu == "Veneer Apprentice"] = 8
ang$moccu[ang$moccu == "Venetian Blind Fixer"] = 8
ang$moccu[ang$moccu == "Venitian Blind Fitter"] = 8
ang$moccu[ang$moccu == "Vet Surgeon"] = 0
ang$moccu[ang$moccu == "Veterinary Pathologist"] = 0
ang$moccu[ang$moccu == "Veterinary Representative"] = 4
ang$moccu[ang$moccu == "Veterinary Surgeon"] = 0
ang$moccu[ang$moccu == "Vinegar-maker"] = 7
ang$moccu[ang$moccu == "Violonist + Antique Clock Restorer"] = 1
ang$moccu[ang$moccu == "Volunteer"] = NA
ang$moccu[ang$moccu == "Vudu-brewer"] = 7
ang$moccu[ang$moccu == "Vulcaniser"] = 8
ang$moccu[ang$moccu == "W.O.2 U.D.F."] = 5
ang$moccu[ang$moccu == "Wage Clerk"] = 3
ang$moccu[ang$moccu == "Waggon maker"] = 7
ang$moccu[ang$moccu == "Wagon builder"] = 7
ang$moccu[ang$moccu == "Wagon driver"] = 9
ang$moccu[ang$moccu == "Wagon Driver"] = 9
ang$moccu[ang$moccu == "Wagon Guard"] = 5
ang$moccu[ang$moccu == "Wagon maker"] = 7
ang$moccu[ang$moccu == "Wagon Repairer"] = 7
ang$moccu[ang$moccu == "Wagon-builder"] = 7
ang$moccu[ang$moccu == "Wagon-driver"] = 9
ang$moccu[ang$moccu == "Wagoner"] = 9
ang$moccu[ang$moccu == "Wagon-guard"] = 5
ang$moccu[ang$moccu == "Wagonmaker"] = 7
ang$moccu[ang$moccu == "Wagon-maker"] = 7
ang$moccu[ang$moccu == "Waiter"] = 5
ang$moccu[ang$moccu == "Waiter(Boarding House)"] = 5
ang$moccu[ang$moccu == "Waitress"] = 5
ang$moccu[ang$moccu == "Wakeman"] = 5
ang$moccu[ang$moccu == "Wall-tiler"] = 9
ang$moccu[ang$moccu == "War Pensioner"] = 5
ang$moccu[ang$moccu == "Ward-boy Rondebosch Hospital"] = 5
ang$moccu[ang$moccu == "Warden"] = 5
ang$moccu[ang$moccu == "Warden Breakwater Convict Station"] = 5
ang$moccu[ang$moccu == "Warden S.A.P. "] = 5
ang$moccu[ang$moccu == "Warder"] = 5
ang$moccu[ang$moccu == "Warder S.A. Police"] = 5
ang$moccu[ang$moccu == "Warehouse assistant"] = 3
ang$moccu[ang$moccu == "Warehouse Assistant"] = 3
ang$moccu[ang$moccu == "Warehouse man"] = 3
ang$moccu[ang$moccu == "Warehouse Manager"] = 2
ang$moccu[ang$moccu == "Warehouseman"] = 3
ang$moccu[ang$moccu == "Warehouseman (On Active Service)"] = 3
ang$moccu[ang$moccu == "Warehouseman(Drapery)"] = 3
ang$moccu[ang$moccu == "Warper Textile Industry"] = 7
ang$moccu[ang$moccu == "Warrant Officer Junior Cape Corps"] = 5
ang$moccu[ang$moccu == "Washing Machine Operator"] = 5
ang$moccu[ang$moccu == "Watch + Clock maker"] = 8
ang$moccu[ang$moccu == "Watchmaker"] = 8
ang$moccu[ang$moccu == "Watch-maker"] = 8
ang$moccu[ang$moccu == "Watchmaker + Optitian"] = 8
ang$moccu[ang$moccu == "Watchman"] = 5
ang$moccu[ang$moccu == "WatchmanLabourer"] = 5
ang$moccu[ang$moccu == "Water Engineer"] = 0
ang$moccu[ang$moccu == "Water Inspector"] = 2
ang$moccu[ang$moccu == "Water man"] = 9
ang$moccu[ang$moccu == "Water Police"] = 5
ang$moccu[ang$moccu == "Water Policeman"] = 5
ang$moccu[ang$moccu == "Water seller"] = 4
ang$moccu[ang$moccu == "Water Supply Inspector"] = 2
ang$moccu[ang$moccu == "Water-Engineer"] = 0
ang$moccu[ang$moccu == "Waterman"] = 9
ang$moccu[ang$moccu == "Waterworks Labourer"] = 9
ang$moccu[ang$moccu == "Weaver"] = 7
ang$moccu[ang$moccu == "Welder"] = 8
ang$moccu[ang$moccu == "Welder S.A.R."] = 8
ang$moccu[ang$moccu == "Welder S.A.R.+H."] = 8
ang$moccu[ang$moccu == "Welder(On Military Service)"] = 8
ang$moccu[ang$moccu == "Welders assistant"] = 8
ang$moccu[ang$moccu == "Welding Engineer"] = 0
ang$moccu[ang$moccu == "Welding-machine Operator"] = 8
ang$moccu[ang$moccu == "Welfare Officer"] = 3
ang$moccu[ang$moccu == "Welt Stitcher"] = 7
ang$moccu[ang$moccu == "Wet Flatter(Motor Factory)"] = 8
ang$moccu[ang$moccu == "Whaler"] = 6
ang$moccu[ang$moccu == "Whalerman"] = 6
ang$moccu[ang$moccu == "Wharf Foreman S.A.R.+H."] = 2
ang$moccu[ang$moccu == "Wharfinger"] = 9
ang$moccu[ang$moccu == "Wheel Balancer"] = 8
ang$moccu[ang$moccu == "Wheelwright"] = 8
ang$moccu[ang$moccu == "Whitesmith"] = 7
ang$moccu[ang$moccu == "Wholesale Dealer"] = 4
ang$moccu[ang$moccu == "Wholesale Merchant"] = 4
ang$moccu[ang$moccu == "Winder"] = 8
ang$moccu[ang$moccu == "Winding Engine Driver(Mines)"] = 9
ang$moccu[ang$moccu == "Windmill Construction Employer"] = 9
ang$moccu[ang$moccu == "Windowblind maker"] = 7
ang$moccu[ang$moccu == "Window-cleaner"] = 5
ang$moccu[ang$moccu == "Window-dresser"] = 1
ang$moccu[ang$moccu == "Window-dressers Assistant"] = 1
ang$moccu[ang$moccu == "Wine Analyst"] = 7
ang$moccu[ang$moccu == "Wine Blender"] = 7
ang$moccu[ang$moccu == "Wine Farmer"] = 6
ang$moccu[ang$moccu == "Wine maker"] = 7
ang$moccu[ang$moccu == "Wine merchant"] = 4
ang$moccu[ang$moccu == "Wine Merchant"] = 4
ang$moccu[ang$moccu == "Wine Merchants labourer"] = 9
ang$moccu[ang$moccu == "Wine merchants packer"] = 9
ang$moccu[ang$moccu == "Wine steward"] = 5
ang$moccu[ang$moccu == "Wine Steward"] = 5
ang$moccu[ang$moccu == "Wine Steward S.A.R."] = 5
ang$moccu[ang$moccu == "Winery"] = 7
ang$moccu[ang$moccu == "Winery bottle washer"] = 7
ang$moccu[ang$moccu == "Winery Employee"] = 7
ang$moccu[ang$moccu == "Winery Foreman"] = 2
ang$moccu[ang$moccu == "Winery labourer"] = 7
ang$moccu[ang$moccu == "Wine-steward"] = 5
ang$moccu[ang$moccu == "Wine-StewardWaiter"] = 5
ang$moccu[ang$moccu == "Wire mattress maker"] = 7
ang$moccu[ang$moccu == "Wire worker"] = 7
ang$moccu[ang$moccu == "Wire-cutter"] = 7
ang$moccu[ang$moccu == "Wireless Mechanic"] = 8
ang$moccu[ang$moccu == "Wireless mechanic S.A.A.F."] = 8
ang$moccu[ang$moccu == "Wireless Operator"] = 8
ang$moccu[ang$moccu == "Wireless Operator R.A.F."] = 8
ang$moccu[ang$moccu == "Wireless Operator R.N."] = 8
ang$moccu[ang$moccu == "Wireless Operator, Royal Navy"] = 8
ang$moccu[ang$moccu == "Wireless Telegraphist"] = 3
ang$moccu[ang$moccu == "Wireless Telegraphy Officer"] = 3
ang$moccu[ang$moccu == "Wireman"] = 8
ang$moccu[ang$moccu == "Wireman(Municipality)"] = 8
ang$moccu[ang$moccu == "Wiremans labourer"] = 8
ang$moccu[ang$moccu == "Wireweaver"] = 8
ang$moccu[ang$moccu == "Wireworker"] = 8
ang$moccu[ang$moccu == "Wood Carver"] = 7
ang$moccu[ang$moccu == "Wood chopper"] = 6
ang$moccu[ang$moccu == "Wood Contractor"] = 2
ang$moccu[ang$moccu == "Wood cutter"] = 6
ang$moccu[ang$moccu == "Wood dealer"] = 4
ang$moccu[ang$moccu == "Wood Hawker"] = 4
ang$moccu[ang$moccu == "Wood machinist"] = 8
ang$moccu[ang$moccu == "Wood Machinist"] = 8
ang$moccu[ang$moccu == "Wood Machinist "] = 8
ang$moccu[ang$moccu == "Wood Machinist (On Active Service)"] = 8
ang$moccu[ang$moccu == "Wood machinist Furniture Factory"] = 8
ang$moccu[ang$moccu == "Wood Machinist S.A.R."] = 8
ang$moccu[ang$moccu == "Wood merchant"] = 4
ang$moccu[ang$moccu == "Wood Merchant"] = 4
ang$moccu[ang$moccu == "Wood sawyer"] = 6
ang$moccu[ang$moccu == "Wood seller"] = 4
ang$moccu[ang$moccu == "Wood Working Machinist"] = 8
ang$moccu[ang$moccu == "Wood-chopper"] = 6
ang$moccu[ang$moccu == "Woodcutter"] = 6
ang$moccu[ang$moccu == "Wood-cutter"] = 6
ang$moccu[ang$moccu == "Wood-dealer"] = 4
ang$moccu[ang$moccu == "Wood-hawker"] = 4
ang$moccu[ang$moccu == "Woodlayer"] = 9
ang$moccu[ang$moccu == "Wood-machinist"] = 8
ang$moccu[ang$moccu == "Woodman"] = 6
ang$moccu[ang$moccu == "Woodseller"] = 4
ang$moccu[ang$moccu == "Wood-Turner"] = 7
ang$moccu[ang$moccu == "Woodwork machinist"] = 8
ang$moccu[ang$moccu == "Woodwork Machinist"] = 8
ang$moccu[ang$moccu == "Woodworker"] = 7
ang$moccu[ang$moccu == "Woodworking machine Salesman"] = 4
ang$moccu[ang$moccu == "Woodworking Machinist"] = 8
ang$moccu[ang$moccu == "Woodworking machinist"] = 8
ang$moccu[ang$moccu == "Wood-working Machinist"] = 8
ang$moccu[ang$moccu == "Wool + Skin Buyer"] = 4
ang$moccu[ang$moccu == "Wool Buyer"] = 4
ang$moccu[ang$moccu == "Wool Seller"] = 4
ang$moccu[ang$moccu == "Wool Stamper"] = 7
ang$moccu[ang$moccu == "Wool Valuator"] = 4
ang$moccu[ang$moccu == "Wool, Skin and Hide Valuator"] = 4
ang$moccu[ang$moccu == "Woolbuyer"] = 4
ang$moccu[ang$moccu == "Wool-buyer"] = 4
ang$moccu[ang$moccu == "Woollen Merchant"] = 4
ang$moccu[ang$moccu == "Woollen Mill-hand"] = 7
ang$moccu[ang$moccu == "Wool-merchant"] = 4
ang$moccu[ang$moccu == "Woolspinner"] = 7
ang$moccu[ang$moccu == "Wool-weaver"] = 7
ang$moccu[ang$moccu == "Work study Engineer"] = 0
ang$moccu[ang$moccu == "Work Study Official"] = 3
ang$moccu[ang$moccu == "Worker"] = 9
ang$moccu[ang$moccu == "Worker in Explosive Works"] = 7
ang$moccu[ang$moccu == "Worker in Gas Works"] = 7
ang$moccu[ang$moccu == "Worker in Match Factory"] = 7
ang$moccu[ang$moccu == "Worker in Painting Office"] = 9
ang$moccu[ang$moccu == "Worker Military Camp"] = 9
ang$moccu[ang$moccu == "Working in a C T Garage "] = 8
ang$moccu[ang$moccu == "Working Jeweller"] = 7
ang$moccu[ang$moccu == "Workman"] = 9
ang$moccu[ang$moccu == "Works at Goods Station"] = 4
ang$moccu[ang$moccu == "Works Engineer"] = 0
ang$moccu[ang$moccu == "Works in Chemist Shop"] = 9
ang$moccu[ang$moccu == "Works in Garage(Stores Dept.)"] = 9
ang$moccu[ang$moccu == "Works in Laundry"] = 5
ang$moccu[ang$moccu == "Works in Sodawater factory"] = 9
ang$moccu[ang$moccu == "Works Manager"] = 2
ang$moccu[ang$moccu == "Works Manager Mineral Factory"] = 2
ang$moccu[ang$moccu == "Workshop Assistant"] = 8
ang$moccu[ang$moccu == "Workshop Foreman"] = 2
ang$moccu[ang$moccu == "Worsted Weaving Manager"] = 2
ang$moccu[ang$moccu == "Wrapper Tobacco Co."] = 7
ang$moccu[ang$moccu == "Writer Naval Dockyard"] = 1
ang$moccu[ang$moccu == "Writer of S.A. Naval Force"] = 1
ang$moccu[ang$moccu == "Writer S.A.N.F."] = 1
ang$moccu[ang$moccu == "Writing clerk"] = 3
ang$moccu[ang$moccu == "X-Ray Engineer"] = 0
ang$moccu[ang$moccu == "Yard Foreman at builders"] = 2
ang$moccu[ang$moccu == "Yeast Manufacturer"] = 7
ang$moccu[ang$moccu == "Yorkshire Regiment"] = 5
ang$moccu[ang$moccu == "Zoologist"] = 0
ang$moccu[ang$moccu == "Warden S.A.P."] = NA
ang$moccu[ang$moccu == "Royal Navy H.M.S. Florida"] = NA
ang$moccu[ang$moccu == "Sergeant R.A.F. On Active Service"] = NA
ang$moccu[ang$moccu == "Assistant Clerk, Legislative Council"] = NA
ang$moccu[ang$moccu == "Surgeon, Lieut. R.N."] = NA
ang$moccu[ang$moccu == "Café Assistant"] = NA
ang$moccu[ang$moccu == "Mounted Police, Basutoland"] = NA
ang$moccu[ang$moccu == "Military, Private"] = NA
ang$moccu[ang$moccu == "Café Keeper"] = NA
ang$moccu[ang$moccu == "Café Proprietor"] = NA
ang$moccu[ang$moccu == "Café Labourer"] = NA
ang$moccu[ang$moccu == "Café Owner"] = NA
ang$moccu[ang$moccu == "Machinist Assistant"] = NA
ang$moccu[ang$moccu == "Café Manager"] = NA
ang$moccu[ang$moccu == "Acting-Bombardier"] = NA
ang$moccu[ang$moccu == "Working in a C T Garage"] = NA
ang$moccu[ang$moccu == "Marketing Assistant"] = NA
ang$moccu[ang$moccu == "Steward (in Café)"] = NA
ang$moccu[ang$moccu == "Rhodesian Railway"] = NA
ang$moccu[ang$moccu == "Shipwright-joiner"] = NA
ang$moccu[ang$moccu == "Saw Doctor"] = NA
ang$moccu[ang$moccu == "Private, S.A. Police Battalion"] = NA
ang$moccu[ang$moccu == "Café-keeper"] = NA
ang$moccu[ang$moccu == "Tyre-exchange hand"] = NA
ang$moccu[ang$moccu == "Tobacco Manufacturers Machine-minder"] = NA
ang$moccu[ang$moccu == "Assistant Architect, Public Works Dept…"] = NA
ang$moccu[ang$moccu == "Handsman"] = NA
ang$moccu[ang$moccu == "Headwaiter"] = NA
ang$moccu[ang$moccu == "Motorman Camps Bay Tramway"] = NA
ang$moccu[ang$moccu == "Bedding Attendant S.A.R."] = NA

ang$foccu = ang$frank
ang$foccu[ang$foccu == "."] = NA
ang$foccu[ang$foccu == "?"] = NA
ang$foccu[ang$foccu == "??"] = NA
ang$foccu[ang$foccu == "Abattoir"] = 7
ang$foccu[ang$foccu == "Accountant"] = 1
ang$foccu[ang$foccu == "Accountant Executive"] = 1
ang$foccu[ang$foccu == "Accountant O.K. Bazaars"] = 1
ang$foccu[ang$foccu == "Accounting Clerk"] = 3
ang$foccu[ang$foccu == "Accounting Machine Operator"] = 3
ang$foccu[ang$foccu == "Accounting Machinist"] = 3
ang$foccu[ang$foccu == "Accounts clerk"] = 3
ang$foccu[ang$foccu == "Accounts Clerk"] = 3
ang$foccu[ang$foccu == "Accounts Clerk/Typist"] = 3
ang$foccu[ang$foccu == "Accounts Machine Operator"] = 3
ang$foccu[ang$foccu == "Accounts Secretary"] = 3
ang$foccu[ang$foccu == "Accounts-Clerk"] = 3
ang$foccu[ang$foccu == "Actress"] = 1
ang$foccu[ang$foccu == "Admiralty Clerk"] = 3
ang$foccu[ang$foccu == "Advertising Executive"] = 4
ang$foccu[ang$foccu == "Advertising Secretary"] = 4
ang$foccu[ang$foccu == "Advocate"] = 1
ang$foccu[ang$foccu == "Air Hostess"] = 5
ang$foccu[ang$foccu == "Airline Secretary"] = 3
ang$foccu[ang$foccu == "Airways Receptionist"] = 3
ang$foccu[ang$foccu == "Airwoman "] = 5
ang$foccu[ang$foccu == "Airwoman S.A.A.F."] = 5
ang$foccu[ang$foccu == "Airwoman W.A.A.F."] = 5
ang$foccu[ang$foccu == "Almoner"] = 3
ang$foccu[ang$foccu == "Alteration Hand"] = 7
ang$foccu[ang$foccu == "Alteration-hand"] = 7
ang$foccu[ang$foccu == "Analytical Chemist"] = 0
ang$foccu[ang$foccu == "Apprentice"] = NA
ang$foccu[ang$foccu == "Apprentice Hairdresser"] = 5
ang$foccu[ang$foccu == "Apprentice Pharmacist"] = 0
ang$foccu[ang$foccu == "Architect"] = 0
ang$foccu[ang$foccu == "Architect's Assistant"] = 0
ang$foccu[ang$foccu == "Architect's Draughtsman"] = 0
ang$foccu[ang$foccu == "Architectural Assistant"] = 0
ang$foccu[ang$foccu == "Architectural Draughtsman"] = 0
ang$foccu[ang$foccu == "Architectural Student"] = 0
ang$foccu[ang$foccu == "Army Matron Retired"] = 2
ang$foccu[ang$foccu == "Army Officer, U.D.F."] = 5
ang$foccu[ang$foccu == "Army Transport (discharged)"] = 9
ang$foccu[ang$foccu == "Army Transport (Retired)"] = 9
ang$foccu[ang$foccu == "Art student"] = 1
ang$foccu[ang$foccu == "Art Student"] = 1
ang$foccu[ang$foccu == "Art Teacher"] = 1
ang$foccu[ang$foccu == "Artist"] = 1
ang$foccu[ang$foccu == "Assistant"] = NA
ang$foccu[ang$foccu == "Assistant "] = NA
ang$foccu[ang$foccu == "Assistant at Bakery"] = 7
ang$foccu[ang$foccu == "Assistant at Shoe Factory"] = 7
ang$foccu[ang$foccu == "Assistant Binder"] = 9
ang$foccu[ang$foccu == "Assistant Bookbinder"] = 9
ang$foccu[ang$foccu == "Assistant Chemist"] = 0
ang$foccu[ang$foccu == "Assistant Clerk"] = 3
ang$foccu[ang$foccu == "Assistant Cook"] = 5
ang$foccu[ang$foccu == "Assistant Dancing Teacher"] = 1
ang$foccu[ang$foccu == "Assistant House Wife"] = 5
ang$foccu[ang$foccu == "Assistant Housing Supervisor"] = 2
ang$foccu[ang$foccu == "Assistant in Advertising Agency"] = 4
ang$foccu[ang$foccu == "Assistant in Box Factory"] = 8
ang$foccu[ang$foccu == "Assistant in Post Office"] = 3
ang$foccu[ang$foccu == "Assistant Librarian"] = 1
ang$foccu[ang$foccu == "Assistant Matron"] = 2
ang$foccu[ang$foccu == "Assistant Mechanic"] = 8
ang$foccu[ang$foccu == "Assistant Overseer Factory"] = 2
ang$foccu[ang$foccu == "Assistant Saleslady"] = 4
ang$foccu[ang$foccu == "Assistant Secretary"] = 3
ang$foccu[ang$foccu == "Assistant Shirt Factory"] = 7
ang$foccu[ang$foccu == "Assistant Shopkeeper"] = 4
ang$foccu[ang$foccu == "Assistant Supervisor - Clothing Factory"] = 2
ang$foccu[ang$foccu == "Assistant Sweet Factory"] = 7
ang$foccu[ang$foccu == "Assistant Teacher"] = 1
ang$foccu[ang$foccu == "Assistant Telegraphist"] = 3
ang$foccu[ang$foccu == "Assistant Typist"] = 3
ang$foccu[ang$foccu == "Assistant-Confectioner"] = 7
ang$foccu[ang$foccu == "Assistant-Despatch Clerk"] = 3
ang$foccu[ang$foccu == "Assistant-Hairdresser"] = 5
ang$foccu[ang$foccu == "Assurance Clerk"] = 3
ang$foccu[ang$foccu == "At home"] = 5
ang$foccu[ang$foccu == "At Home"] = 5
ang$foccu[ang$foccu == "Atlantic Smokeries Employer"] = 7
ang$foccu[ang$foccu == "Attendant"] = NA
ang$foccu[ang$foccu == "Attendant in Sweet Factory"] = 7
ang$foccu[ang$foccu == "Attendant to Aged Gentleman"] = 5
ang$foccu[ang$foccu == "Attorney"] = 1
ang$foccu[ang$foccu == "Audit Clerk"] = 3
ang$foccu[ang$foccu == "Auditor"] = 1
ang$foccu[ang$foccu == "Auxiliary Nurse"] = 5
ang$foccu[ang$foccu == "B.Sc. Medical Research"] = 0
ang$foccu[ang$foccu == "Bacteriologist"] = 0
ang$foccu[ang$foccu == "Badge Enameller"] = 8
ang$foccu[ang$foccu == "Bag maker"] = 7
ang$foccu[ang$foccu == "Bag maker in Printing Works"] = 7
ang$foccu[ang$foccu == "Bagmaker"] = 7
ang$foccu[ang$foccu == "Baker's Supervisor"] = 2
ang$foccu[ang$foccu == "Ballet Teacher"] = 1
ang$foccu[ang$foccu == "Ballet-teacher"] = 1
ang$foccu[ang$foccu == "Bank Clerk"] = 3
ang$foccu[ang$foccu == "Bank Official"] = 4
ang$foccu[ang$foccu == "Bank Teller"] = 3
ang$foccu[ang$foccu == "Bank Typist"] = 3
ang$foccu[ang$foccu == "Bank-clerk"] = 3
ang$foccu[ang$foccu == "Bar Filler"] = 5
ang$foccu[ang$foccu == "Baster"] = 5
ang$foccu[ang$foccu == "Beautician"] = 5
ang$foccu[ang$foccu == "Beauty Consultant"] = 5
ang$foccu[ang$foccu == "Beauty Culturist"] = 5
ang$foccu[ang$foccu == "Beauty Specialist"] = 5
ang$foccu[ang$foccu == "Bedding Embroiderer"] = 7
ang$foccu[ang$foccu == "Binder"] = 7
ang$foccu[ang$foccu == "Binder In Book Trade"] = 7
ang$foccu[ang$foccu == "Binder's assistant"] = 9
ang$foccu[ang$foccu == "Binder's Assistant"] = 9
ang$foccu[ang$foccu == "Biscuit Factory "] = 7
ang$foccu[ang$foccu == "Biscuit Factory Employee"] = 7
ang$foccu[ang$foccu == "Biscuit Machinist"] = 8
ang$foccu[ang$foccu == "Biscuit Maker"] = 8
ang$foccu[ang$foccu == "Biscuit Packer"] = 9
ang$foccu[ang$foccu == "Biscuit Packer at Bakery"] = 9
ang$foccu[ang$foccu == "Blood Transfusion Assistant"] = 5
ang$foccu[ang$foccu == "Book Binder's Assistant"] = 9
ang$foccu[ang$foccu == "Book Examiner"] = 9
ang$foccu[ang$foccu == "Book Keeper"] = 1
ang$foccu[ang$foccu == "Bookbinder"] = 9
ang$foccu[ang$foccu == "Bookbinder's assistant"] = 9
ang$foccu[ang$foccu == "Bookbinder's Assistant"] = 9
ang$foccu[ang$foccu == "Booker"] = 3
ang$foccu[ang$foccu == "Bookfolder"] = 9
ang$foccu[ang$foccu == "Booking-Clerk"] = 3
ang$foccu[ang$foccu == "Bookkeeper"] = 3
ang$foccu[ang$foccu == "Bookkeeper "] = 3
ang$foccu[ang$foccu == "Bookkeeper + Typist"] = 3
ang$foccu[ang$foccu == "Bookkeeper/Typist"] = 3
ang$foccu[ang$foccu == "Bookkeeping Clerk"] = 3
ang$foccu[ang$foccu == "Bookkeeping machine"] = 3
ang$foccu[ang$foccu == "Bookkeeping Machine Operator"] = 3
ang$foccu[ang$foccu == "Bookkeeping Machinist"] = 3
ang$foccu[ang$foccu == "Bookkkeeper"] = 3
ang$foccu[ang$foccu == "Bookseller's assistant"] = 4
ang$foccu[ang$foccu == "Bookstall attendant"] = 4
ang$foccu[ang$foccu == "Bookstall Attendant"] = 4
ang$foccu[ang$foccu == "Bookstall Attendant "] = 4
ang$foccu[ang$foccu == "Bookstall Attendant S.A.R."] = 4
ang$foccu[ang$foccu == "Bookstall Custodian S.A.R."] = 4
ang$foccu[ang$foccu == "Boot factory-hand"] = 7
ang$foccu[ang$foccu == "Botanist"] = 0
ang$foccu[ang$foccu == "Bottle-labeller at Winery"] = 7
ang$foccu[ang$foccu == "Box cleaner"] = 5
ang$foccu[ang$foccu == "Box factory"] = 9
ang$foccu[ang$foccu == "Box factory Machinist"] = 8
ang$foccu[ang$foccu == "Box Machinist"] = 8
ang$foccu[ang$foccu == "Box maker"] = 9
ang$foccu[ang$foccu == "Box Maker"] = 9
ang$foccu[ang$foccu == "Box making Machinist"] = 8
ang$foccu[ang$foccu == "Box-liner"] = 9
ang$foccu[ang$foccu == "Box-maker"] = 9
ang$foccu[ang$foccu == "Boxmaking Employer"] = 9
ang$foccu[ang$foccu == "Broadcaster"] = 1
ang$foccu[ang$foccu == "Broadcasting Organizer"] = 1
ang$foccu[ang$foccu == "Burroughs Machinist"] = 8
ang$foccu[ang$foccu == "Bus Conductor"] = 3
ang$foccu[ang$foccu == "Business Assistant"] = 3
ang$foccu[ang$foccu == "Butcher's Cashier"] = 3
ang$foccu[ang$foccu == "Buyer"] = 4
ang$foccu[ang$foccu == "C.T. University staff"] = 9
ang$foccu[ang$foccu == "Café assistant"] = 5
ang$foccu[ang$foccu == "Café Assistant"] = 5
ang$foccu[ang$foccu == "Cafe Attendant"] = 5
ang$foccu[ang$foccu == "Café Employee"] = 5
ang$foccu[ang$foccu == "Cafe Kitchen Staff"] = 5
ang$foccu[ang$foccu == "Cafe Proprietor"] = 2
ang$foccu[ang$foccu == "Café Supervisor"] = 2
ang$foccu[ang$foccu == "Café Waitress"] = 5
ang$foccu[ang$foccu == "Cake Machine Operator"] = 8
ang$foccu[ang$foccu == "Canvasser"] = 4
ang$foccu[ang$foccu == "Cape Hosiery Mills"] = 7
ang$foccu[ang$foccu == "Card Index Operator"] = 3
ang$foccu[ang$foccu == "Cardboard box-maker"] = 9
ang$foccu[ang$foccu == "Caretaker"] = 5
ang$foccu[ang$foccu == "Cartage Contractor"] = 2
ang$foccu[ang$foccu == "Carton-stitcher"] = 9
ang$foccu[ang$foccu == "Case Maker"] = 7
ang$foccu[ang$foccu == "Case-liner"] = 7
ang$foccu[ang$foccu == "Cashier"] = 3
ang$foccu[ang$foccu == "Cashier Clerk"] = 3
ang$foccu[ang$foccu == "Cashier/Bookkeeper"] = 3
ang$foccu[ang$foccu == "Cashier/Clerk"] = 3
ang$foccu[ang$foccu == "Cashier-Clerk"] = 3
ang$foccu[ang$foccu == "Casual Domestic service"] = 5
ang$foccu[ang$foccu == "Catering Manageress"] = 2
ang$foccu[ang$foccu == "Chaircaner"] = 7
ang$foccu[ang$foccu == "Chalet Attendant"] = 5
ang$foccu[ang$foccu == "Chambermaid"] = 5
ang$foccu[ang$foccu == "Char"] = 5
ang$foccu[ang$foccu == "Charge Sister"] = 0
ang$foccu[ang$foccu == "Charwoman"] = 5
ang$foccu[ang$foccu == "Chauffeur"] = 9
ang$foccu[ang$foccu == "Checker"] = 3
ang$foccu[ang$foccu == "Checker + Despatcher"] = 3
ang$foccu[ang$foccu == "Checker at Laundry"] = 3
ang$foccu[ang$foccu == "Checker in Dry Cleaners"] = 3
ang$foccu[ang$foccu == "Checker Laundry"] = 3
ang$foccu[ang$foccu == "Chemical Assistant"] = 0
ang$foccu[ang$foccu == "Chemical Factory worker"] = 9
ang$foccu[ang$foccu == "Chemical worker"] = 0
ang$foccu[ang$foccu == "Chemist"] = 0
ang$foccu[ang$foccu == "Chemist Assistant"] = 0
ang$foccu[ang$foccu == "Chemist, Druggist + Optician"] = 0
ang$foccu[ang$foccu == "Chemist's assistant"] = 0
ang$foccu[ang$foccu == "Chemist's Assistant"] = 0
ang$foccu[ang$foccu == "Chief Clerk"] = 3
ang$foccu[ang$foccu == "Chief Matron (Nursing)"] = 0
ang$foccu[ang$foccu == "Child-care Officer"] = 1
ang$foccu[ang$foccu == "Children's attendant"] = 5
ang$foccu[ang$foccu == "Children's Nurse"] = 5
ang$foccu[ang$foccu == "Children's nurse"] = 5
ang$foccu[ang$foccu == "Chiropodist"] = 0
ang$foccu[ang$foccu == "Chocolate Dipper"] = 7
ang$foccu[ang$foccu == "Chocolate Moulder"] = 7
ang$foccu[ang$foccu == "Cigarette Examiner"] = 7
ang$foccu[ang$foccu == "Cigarette Factory"] = 7
ang$foccu[ang$foccu == "Cigarette Factory Worker"] = 7
ang$foccu[ang$foccu == "Cigarette Machine attendant"] = 8
ang$foccu[ang$foccu == "Cigarette Machine feeder"] = 7
ang$foccu[ang$foccu == "Cigarette Machinist"] = 8
ang$foccu[ang$foccu == "Cigarette maker"] = 7
ang$foccu[ang$foccu == "Cigarette Packer"] = 7
ang$foccu[ang$foccu == "Cigarette-maker"] = 7
ang$foccu[ang$foccu == "Cinema Attendant"] = 5
ang$foccu[ang$foccu == "Cinema Caterer"] = 5
ang$foccu[ang$foccu == "Civil Servant"] = 3
ang$foccu[ang$foccu == "Civil servant"] = 3
ang$foccu[ang$foccu == "Civil Servant "] = 3
ang$foccu[ang$foccu == "Civil Servant (Education)"] = 3
ang$foccu[ang$foccu == "Civil Service"] = 3
ang$foccu[ang$foccu == "Cleaner"] = 5
ang$foccu[ang$foccu == "Cleaner at Factory"] = 5
ang$foccu[ang$foccu == "Cleaner in Factory"] = 5
ang$foccu[ang$foccu == "Cleaner of Weaving Materials"] = 5
ang$foccu[ang$foccu == "Cleaner Spotter"] = 5
ang$foccu[ang$foccu == "Cleaner(Factory)"] = 5
ang$foccu[ang$foccu == "Cleaner's Depot Assistant"] = 5
ang$foccu[ang$foccu == "Cleaner's marker"] = 5
ang$foccu[ang$foccu == "Clerical"] = 3
ang$foccu[ang$foccu == "Clerical Assistant"] = 3
ang$foccu[ang$foccu == "Clerical assistant"] = 3
ang$foccu[ang$foccu == "Clerical work"] = 3
ang$foccu[ang$foccu == "Clerical Worker"] = 3
ang$foccu[ang$foccu == "Clerical worker"] = 3
ang$foccu[ang$foccu == "Clerk"] = 3
ang$foccu[ang$foccu == "Clerk (Airwoman S.A.W.A.A.F.)"] = 3
ang$foccu[ang$foccu == "Clerk (Government Service)"] = 3
ang$foccu[ang$foccu == "Clerk + Saleslady"] = 3
ang$foccu[ang$foccu == "Clerk + Typist"] = 3
ang$foccu[ang$foccu == "Clerk and Bookkeeper"] = 3
ang$foccu[ang$foccu == "Clerk Civil Service"] = 3
ang$foccu[ang$foccu == "Clerk Deciduous Fruit Board "] = 3
ang$foccu[ang$foccu == "Clerk G.P.O."] = 3
ang$foccu[ang$foccu == "Clerk in Cape Town Gas Company"] = 3
ang$foccu[ang$foccu == "Clerk in City Council"] = 3
ang$foccu[ang$foccu == "Clerk in Municipal Employment"] = 3
ang$foccu[ang$foccu == "Clerk in S.A.N.F. (now released)"] = 3
ang$foccu[ang$foccu == "Clerk in United Building Society Cape Town"] = 3
ang$foccu[ang$foccu == "Clerk in W.A.A.F."] = 3
ang$foccu[ang$foccu == "Clerk Post Office"] = 3
ang$foccu[ang$foccu == "Clerk S.A.R."] = 3
ang$foccu[ang$foccu == "Clerk S.A.R.+H."] = 3
ang$foccu[ang$foccu == "Clerk Shell Company"] = 3
ang$foccu[ang$foccu == "Clerk Standard Bank"] = 3
ang$foccu[ang$foccu == "Clerk Technical College"] = 3
ang$foccu[ang$foccu == "Clerk Typist"] = 3
ang$foccu[ang$foccu == "Clerk W.A.A.F."] = 3
ang$foccu[ang$foccu == "Clerk, Civil Service"] = 3
ang$foccu[ang$foccu == "Clerk/Saleslady"] = 3
ang$foccu[ang$foccu == "Clerk/Teller"] = 3
ang$foccu[ang$foccu == "Clerk/Typist"] = 3
ang$foccu[ang$foccu == "Clerk-Civil Service"] = 3
ang$foccu[ang$foccu == "Clerk-Typist"] = 3
ang$foccu[ang$foccu == "Clicker"] = 8
ang$foccu[ang$foccu == "Clinic Assistant"] = 5
ang$foccu[ang$foccu == "Clinical Assistant"] = 5
ang$foccu[ang$foccu == "Cloakroom Assistant"] = 5
ang$foccu[ang$foccu == "Cloth Examiner"] = 7
ang$foccu[ang$foccu == "Clothing Examiner"] = 7
ang$foccu[ang$foccu == "Clothing Factory"] = 7
ang$foccu[ang$foccu == "Clothing Factory Employee"] = 7
ang$foccu[ang$foccu == "Clothing Factory Hand"] = 7
ang$foccu[ang$foccu == "Clothing Factory Machinist"] = 8
ang$foccu[ang$foccu == "Clothing factory worker"] = 7
ang$foccu[ang$foccu == "Clothing Factory Worker"] = 7
ang$foccu[ang$foccu == "Clothing Factory-hand"] = 7
ang$foccu[ang$foccu == "Clothing Factory-worker"] = 7
ang$foccu[ang$foccu == "Clothing Machinist"] = 8
ang$foccu[ang$foccu == "Clothing machinist"] = 8
ang$foccu[ang$foccu == "Clothing Maker"] = 7
ang$foccu[ang$foccu == "Clothing Pattern Maker"] = 7
ang$foccu[ang$foccu == "Clothing Spinster"] = 7
ang$foccu[ang$foccu == "Clothing worker"] = 7
ang$foccu[ang$foccu == "Clothing-finisher"] = 7
ang$foccu[ang$foccu == "Clothing-maker"] = 7
ang$foccu[ang$foccu == "Clothing-worker"] = 7
ang$foccu[ang$foccu == "Cloting Factory Employee"] = 7
ang$foccu[ang$foccu == "Cloting factory worker"] = 7
ang$foccu[ang$foccu == "Cloting Factory worker"] = 7
ang$foccu[ang$foccu == "Coat Finisher"] = 7
ang$foccu[ang$foccu == "Coat finisher"] = 7
ang$foccu[ang$foccu == "Coffee Merchant's filler"] = 7
ang$foccu[ang$foccu == "Coffee Packer"] = 7
ang$foccu[ang$foccu == "Collar hand"] = 7
ang$foccu[ang$foccu == "Collar presser"] = 7
ang$foccu[ang$foccu == "Collector"] = 3
ang$foccu[ang$foccu == "Colour Consultant"] = 2
ang$foccu[ang$foccu == "Commecial Typist"] = 3
ang$foccu[ang$foccu == "Commercial Artist"] = 1
ang$foccu[ang$foccu == "Commercial Traveller"] = 4
ang$foccu[ang$foccu == "Company Director"] = 2
ang$foccu[ang$foccu == "Comptometer Operator"] = 3
ang$foccu[ang$foccu == "Comptometrist"] = 3
ang$foccu[ang$foccu == "Computer Programmer"] = 0
ang$foccu[ang$foccu == "Confectioner"] = 7
ang$foccu[ang$foccu == "Confector"] = 7
ang$foccu[ang$foccu == "Confidential Typist"] = 7
ang$foccu[ang$foccu == "Conveyer feeder in factory"] = 7
ang$foccu[ang$foccu == "Conveyor Feeder"] = 7
ang$foccu[ang$foccu == "Cook"] = 5
ang$foccu[ang$foccu == "Cook general"] = 5
ang$foccu[ang$foccu == "Cookery Lecturer"] = 1
ang$foccu[ang$foccu == "Cook-general"] = 5
ang$foccu[ang$foccu == "Cook-General"] = 5
ang$foccu[ang$foccu == "Copy Holder"] = 9
ang$foccu[ang$foccu == "Copy Typist"] = 3
ang$foccu[ang$foccu == "Copywriter"] = 3
ang$foccu[ang$foccu == "Corporal S.A.A.F."] = 5
ang$foccu[ang$foccu == "Corporal S.A.W.A.A.S."] = 5
ang$foccu[ang$foccu == "Corporal U.D.F."] = 5
ang$foccu[ang$foccu == "Corporal Union Defence Force"] = 5
ang$foccu[ang$foccu == "Corporal W.A.A.F."] = 5
ang$foccu[ang$foccu == "Corporal W.A.A.S."] = 5
ang$foccu[ang$foccu == "Corporal WAAS U.D.F."] = 5
ang$foccu[ang$foccu == "Cosmetic Operator"] = 5
ang$foccu[ang$foccu == "Costing Clerk"] = 3
ang$foccu[ang$foccu == "Costume Finisher"] = 7
ang$foccu[ang$foccu == "Counter Hand"] = 9
ang$foccu[ang$foccu == "Counter hand"] = 9
ang$foccu[ang$foccu == "Counter hand in factory"] = 9
ang$foccu[ang$foccu == "Counter-hand"] = 9
ang$foccu[ang$foccu == "Counting machine operator"] = 3
ang$foccu[ang$foccu == "Counting Machine Operator"] = 3
ang$foccu[ang$foccu == "Cpl. W.A.A.F."] = 5
ang$foccu[ang$foccu == "Cream Tester"] = 7
ang$foccu[ang$foccu == "Creamer"] = 7
ang$foccu[ang$foccu == "Credit Controller"] = 3
ang$foccu[ang$foccu == "Credit-Manageress"] = 3
ang$foccu[ang$foccu == "Culler"] = 6
ang$foccu[ang$foccu == "Customs Clerk"] = 3
ang$foccu[ang$foccu == "Cutter"] = 7
ang$foccu[ang$foccu == "Cutter in Clothing Factory"] = 7
ang$foccu[ang$foccu == "Dancing Teacher"] = 1
ang$foccu[ang$foccu == "Darkroom Attendant"] = 9
ang$foccu[ang$foccu == "Data Processer"] = 0
ang$foccu[ang$foccu == "Dental Attendant"] = 0
ang$foccu[ang$foccu == "Dental Nurse"] = 0
ang$foccu[ang$foccu == "Dental Surgeon"] = 0
ang$foccu[ang$foccu == "Dentist Receptionist"] = 3
ang$foccu[ang$foccu == "Dentist's Assistant"] = 0
ang$foccu[ang$foccu == "Dentist's Attendant"] = 0
ang$foccu[ang$foccu == "Dentist's Receptionist"] = 3
ang$foccu[ang$foccu == "Depot assistant"] = 3
ang$foccu[ang$foccu == "Depot Assistant"] = 3
ang$foccu[ang$foccu == "Designer and Cutter"] = 7
ang$foccu[ang$foccu == "Designer-cutter"] = 7
ang$foccu[ang$foccu == "Despatch Clerk"] = 3
ang$foccu[ang$foccu == "Despatch Worker"] = 3
ang$foccu[ang$foccu == "Despatcher Cloting Factory"] = 3
ang$foccu[ang$foccu == "Dictaphone Typist"] = 3
ang$foccu[ang$foccu == "Dietician"] = 0
ang$foccu[ang$foccu == "Dipper"] = 9
ang$foccu[ang$foccu == "Director of Companies"] = 2
ang$foccu[ang$foccu == "Director of Education"] = 2
ang$foccu[ang$foccu == "Display Artist"] = 1
ang$foccu[ang$foccu == "Doctor"] = 0
ang$foccu[ang$foccu == "Doctor (Medical Practitioner)"] = 0
ang$foccu[ang$foccu == "Doctor of Medicine"] = 0
ang$foccu[ang$foccu == "Doctor's Attendant"] = 0
ang$foccu[ang$foccu == "Doctor's Nurse"] = 0
ang$foccu[ang$foccu == "Doctor's Receptionist"] = 3
ang$foccu[ang$foccu == "Doctor's Secretary"] = 3
ang$foccu[ang$foccu == "Domestic"] = 5
ang$foccu[ang$foccu == "domestic"] = 5
ang$foccu[ang$foccu == "Domestic "] = 5
ang$foccu[ang$foccu == "Domestic duties"] = 5
ang$foccu[ang$foccu == "Domestic Duties"] = 5
ang$foccu[ang$foccu == "Domestic Help"] = 5
ang$foccu[ang$foccu == "Domestic maid servant"] = 5
ang$foccu[ang$foccu == "Domestic nurse"] = 0
ang$foccu[ang$foccu == "Domestic Science"] = 5
ang$foccu[ang$foccu == "Domestic Science Teacher"] = 1
ang$foccu[ang$foccu == "Domestic Scientist"] = 5
ang$foccu[ang$foccu == "Domestic serva"] = 0
ang$foccu[ang$foccu == "Domestic servant"] = 0
ang$foccu[ang$foccu == "Domestic Servant"] = 0
ang$foccu[ang$foccu == "Domestic servant "] = 0
ang$foccu[ang$foccu == "Domestic service"] = 0
ang$foccu[ang$foccu == "Domestic Service"] = 0
ang$foccu[ang$foccu == "Domestic work"] = 0
ang$foccu[ang$foccu == "Domestic worker"] = 0
ang$foccu[ang$foccu == "Draftswoman"] = 0
ang$foccu[ang$foccu == "Drafts-woman"] = 0
ang$foccu[ang$foccu == "Draper's Assistant"] = 4
ang$foccu[ang$foccu == "Drapery assistant"] = 4
ang$foccu[ang$foccu == "Drapery Assistant"] = 4
ang$foccu[ang$foccu == "Draught woman"] = 0
ang$foccu[ang$foccu == "Draughtsman"] = 0
ang$foccu[ang$foccu == "Draughtswoman"] = 0
ang$foccu[ang$foccu == "Dress designer"] = 1
ang$foccu[ang$foccu == "Dress Designer"] = 1
ang$foccu[ang$foccu == "Dress Machinist"] = 8
ang$foccu[ang$foccu == "Dress maker"] = 7
ang$foccu[ang$foccu == "Dressmaker"] = 7
ang$foccu[ang$foccu == "Dressmaker Machinist"] = 7
ang$foccu[ang$foccu == "Dressmaker's assistant"] = 7
ang$foccu[ang$foccu == "Dressmaker's Assistant"] = 7
ang$foccu[ang$foccu == "Dressmaker's cutter"] = 7
ang$foccu[ang$foccu == "Dressmaker's Finisher"] = 7
ang$foccu[ang$foccu == "Dressmaking"] = 7
ang$foccu[ang$foccu == "Dry Cleaner's Assistant"] = 5
ang$foccu[ang$foccu == "Dry-cleaner"] = 5
ang$foccu[ang$foccu == "Drycleaning Depot Assistant"] = 5
ang$foccu[ang$foccu == "Education Officer"] = 3
ang$foccu[ang$foccu == "Educationist"] = 1
ang$foccu[ang$foccu == "Egg packer"] = 7
ang$foccu[ang$foccu == "Electrical Draughtsman"] = 0
ang$foccu[ang$foccu == "Electrical Engineer"] = 0
ang$foccu[ang$foccu == "Elocution Teacher"] = 0
ang$foccu[ang$foccu == "Embroiderer"] = 7
ang$foccu[ang$foccu == "Embroidress"] = 7
ang$foccu[ang$foccu == "Employee in Furrier Trade"] = 7
ang$foccu[ang$foccu == "Employee Ladies Hairdressers"] = 5
ang$foccu[ang$foccu == "Enameller in Factory"] = 8
ang$foccu[ang$foccu == "English Teacher"] = NA
ang$foccu[ang$foccu == "Enquiry Clerk Groot Schuur Hospital"] = 3
ang$foccu[ang$foccu == "Entomologist"] = 0
ang$foccu[ang$foccu == "Envelope Machinist"] = 3
ang$foccu[ang$foccu == "Estate Agent"] = 4
ang$foccu[ang$foccu == "Estate Manager"] = 2
ang$foccu[ang$foccu == "Ex Active Service W.A.A.S."] = 5
ang$foccu[ang$foccu == "Ex Active Service W.R.N.S."] = 5
ang$foccu[ang$foccu == "Ex S.A.R. Clerk"] = 3
ang$foccu[ang$foccu == "Examiner"] = 7
ang$foccu[ang$foccu == "Examiner "] = 7
ang$foccu[ang$foccu == "Examiner - Clothing factory"] = 7
ang$foccu[ang$foccu == "Examiner Ackerman's factory"] = 7
ang$foccu[ang$foccu == "Examiner Clothing Factory"] = 7
ang$foccu[ang$foccu == "Examiner Clothing Industry"] = 7
ang$foccu[ang$foccu == "Examiner Cloting Factory"] = 7
ang$foccu[ang$foccu == "Examiner in factory"] = 7
ang$foccu[ang$foccu == "Examiner in Factory"] = 7
ang$foccu[ang$foccu == "Examiner in Shoe factory"] = 7
ang$foccu[ang$foccu == "Examiner Tobacco Factory"] = 7
ang$foccu[ang$foccu == "Factory Assistant"] = 9
ang$foccu[ang$foccu == "Factory baker"] = 7
ang$foccu[ang$foccu == "Factory Box worker"] = 9
ang$foccu[ang$foccu == "Factory Canned"] = 7
ang$foccu[ang$foccu == "Factory Charge-hand"] = 9
ang$foccu[ang$foccu == "Factory Cleaner"] = 5
ang$foccu[ang$foccu == "Factory cleaner"] = 5
ang$foccu[ang$foccu == "Factory Clerk"] = 3
ang$foccu[ang$foccu == "Factory Employee"] = 9
ang$foccu[ang$foccu == "Factory Examiner"] = 7
ang$foccu[ang$foccu == "Factory Folder"] = 7
ang$foccu[ang$foccu == "Factory girl"] = 9
ang$foccu[ang$foccu == "Factory hand"] = 9
ang$foccu[ang$foccu == "Factory Hand"] = 9
ang$foccu[ang$foccu == "Factory hand Leather Industry"] = 7
ang$foccu[ang$foccu == "Factory hand(Dried Fruit)"] = 7
ang$foccu[ang$foccu == "Factory hand, Tobacco Co."] = 7
ang$foccu[ang$foccu == "Factory Laboratory Assistant"] = 0
ang$foccu[ang$foccu == "Factory Machinist"] = 8
ang$foccu[ang$foccu == "Factory machinist"] = 8
ang$foccu[ang$foccu == "Factory Operator"] = 8
ang$foccu[ang$foccu == "Factory Overseer"] = 2
ang$foccu[ang$foccu == "Factory packer"] = 9
ang$foccu[ang$foccu == "Factory sewing"] = 7
ang$foccu[ang$foccu == "Factory Sorter"] = 7
ang$foccu[ang$foccu == "Factory Supervisor"] = 2
ang$foccu[ang$foccu == "Factory work"] = 9
ang$foccu[ang$foccu == "Factory worker"] = 9
ang$foccu[ang$foccu == "Factory Worker"] = 9
ang$foccu[ang$foccu == "Factory Wrapper"] = 9
ang$foccu[ang$foccu == "Factory-hand"] = 9
ang$foccu[ang$foccu == "Factory-hand(Clothing)"] = 7
ang$foccu[ang$foccu == "Factory-worker"] = 7
ang$foccu[ang$foccu == "Family Helper"] = 7
ang$foccu[ang$foccu == "Farm duties"] = 6
ang$foccu[ang$foccu == "Farm labourer"] = 6
ang$foccu[ang$foccu == "Farm Manager"] = 2
ang$foccu[ang$foccu == "Farm worker"] = 6
ang$foccu[ang$foccu == "Farmer"] = 6
ang$foccu[ang$foccu == "Fashion Designer"] = 1
ang$foccu[ang$foccu == "Father's Help"] = 5
ang$foccu[ang$foccu == "Feather Dresser"] = 7
ang$foccu[ang$foccu == "Feeder"] = 9
ang$foccu[ang$foccu == "Feller Clothing Factory"] = 7
ang$foccu[ang$foccu == "Felt worker"] = 7
ang$foccu[ang$foccu == "Filing Clerk"] = 3
ang$foccu[ang$foccu == "Filing-Clerk"] = 3
ang$foccu[ang$foccu == "Filler in Quilt manufacturer"] = 7
ang$foccu[ang$foccu == "Film Weigher"] = 9
ang$foccu[ang$foccu == "Finisher"] = 9
ang$foccu[ang$foccu == "Finisher Clothing Factory"] = 7
ang$foccu[ang$foccu == "Finisher in Clothing Factory"] = 7
ang$foccu[ang$foccu == "Finisher in Factory"] = 9
ang$foccu[ang$foccu == "Fish Cutter"] = 7
ang$foccu[ang$foccu == "Fish Factory hand"] = 7
ang$foccu[ang$foccu == "Fish Packer"] = 7
ang$foccu[ang$foccu == "Fish-cutter"] = 7
ang$foccu[ang$foccu == "Fitter S.A.A.F."] = 8
ang$foccu[ang$foccu == "Fletcher + Cartwright's Assistant"] = 8
ang$foccu[ang$foccu == "Floral Expert"] = 4
ang$foccu[ang$foccu == "Florist"] = 4
ang$foccu[ang$foccu == "Florist Assistant"] = 4
ang$foccu[ang$foccu == "Florist's assistant"] = 4
ang$foccu[ang$foccu == "Flower Seller"] = 4
ang$foccu[ang$foccu == "Flower worker"] = 6
ang$foccu[ang$foccu == "Flower-hawker"] = 4
ang$foccu[ang$foccu == "Flowerseller"] = 4
ang$foccu[ang$foccu == "Flower-seller"] = 4
ang$foccu[ang$foccu == "Folder"] = 9
ang$foccu[ang$foccu == "Folder at Stocking Factory"] = 7
ang$foccu[ang$foccu == "Folder in Clothing Factory"] = 7
ang$foccu[ang$foccu == "Folder in Shoe Factory"] = 7
ang$foccu[ang$foccu == "Folder in Stocking Factory"] = 7
ang$foccu[ang$foccu == "Forelady"] = 2
ang$foccu[ang$foccu == "Forewoman"] = 2
ang$foccu[ang$foccu == "Forewoman Clothing Factory"] = 2
ang$foccu[ang$foccu == "Forewoman Hat Works"] = 2
ang$foccu[ang$foccu == "Fountain Hand"] = 5
ang$foccu[ang$foccu == "Fruit hawker"] = 5
ang$foccu[ang$foccu == "Fruiterer"] = 4
ang$foccu[ang$foccu == "G.P.O. Cape Town"] = 3
ang$foccu[ang$foccu == "Garment Cleaner"] = 5
ang$foccu[ang$foccu == "Garment Examiner"] = 7
ang$foccu[ang$foccu == "Garment worker"] = 7
ang$foccu[ang$foccu == "Garment-maker"] = 7
ang$foccu[ang$foccu == "Garment-repairer"] = 7
ang$foccu[ang$foccu == "Garment-worker"] = 7
ang$foccu[ang$foccu == "General Clerk"] = 3
ang$foccu[ang$foccu == "General Clerk + Telephonist"] = 3
ang$foccu[ang$foccu == "General Cook"] = 5
ang$foccu[ang$foccu == "General Housework"] = 5
ang$foccu[ang$foccu == "General Labourer"] = 9
ang$foccu[ang$foccu == "General Nurse"] = 0
ang$foccu[ang$foccu == "General Office Worker"] = 3
ang$foccu[ang$foccu == "General Operator Printing Works"] = 9
ang$foccu[ang$foccu == "General servant"] = 5
ang$foccu[ang$foccu == "General Servant"] = 5
ang$foccu[ang$foccu == "General worker"] = 9
ang$foccu[ang$foccu == "General Worker"] = 9
ang$foccu[ang$foccu == "Governess"] = 1
ang$foccu[ang$foccu == "Government Official"] = 3
ang$foccu[ang$foccu == "Government Teacher"] = 1
ang$foccu[ang$foccu == "Grader"] = 9
ang$foccu[ang$foccu == "Greengrocer's assistant"] = 4
ang$foccu[ang$foccu == "Grocer"] = 4
ang$foccu[ang$foccu == "Ground Hostess"] = 5
ang$foccu[ang$foccu == "Ground Hostess S.A.A."] = 5
ang$foccu[ang$foccu == "Hair dresser"] = 5
ang$foccu[ang$foccu == "Hair stylist"] = 5
ang$foccu[ang$foccu == "Hairdresser"] = 5
ang$foccu[ang$foccu == "Hairdresser's Apprentice"] = 5
ang$foccu[ang$foccu == "Hairdresser's Assistant"] = 5
ang$foccu[ang$foccu == "Hairdresser's Receptionist"] = 3
ang$foccu[ang$foccu == "Hair-stylist"] = 5
ang$foccu[ang$foccu == "Hand Punching"] = 1
ang$foccu[ang$foccu == "Handbag Maker"] = 8
ang$foccu[ang$foccu == "Handbag maker"] = 8
ang$foccu[ang$foccu == "Handbagmaker"] = 8
ang$foccu[ang$foccu == "Handler"] = 6
ang$foccu[ang$foccu == "Hand-packer"] = 9
ang$foccu[ang$foccu == "Hap Tracer"] = NA
ang$foccu[ang$foccu == "Harbour Maid"] = 5
ang$foccu[ang$foccu == "Haridresser"] = 5
ang$foccu[ang$foccu == "Hawker"] = 4
ang$foccu[ang$foccu == "Hawker's Assistant"] = 4
ang$foccu[ang$foccu == "Head Waitress"] = 5
ang$foccu[ang$foccu == "Health Department"] = 0
ang$foccu[ang$foccu == "Health Visitor"] = 0
ang$foccu[ang$foccu == "Heel Coverer Bally Shoe Factory"] = 8
ang$foccu[ang$foccu == "Hollerith Machine Operator"] = 3
ang$foccu[ang$foccu == "Hollerith Operator"] = 3
ang$foccu[ang$foccu == "Hollerith Punch Operator"] = 3
ang$foccu[ang$foccu == "Home duties"] = NA
ang$foccu[ang$foccu == "Home Duties"] = NA
ang$foccu[ang$foccu == "Home work"] = NA
ang$foccu[ang$foccu == "Home-help"] = NA
ang$foccu[ang$foccu == "Homekeeper"] = 2
ang$foccu[ang$foccu == "Homes Duties"] = NA
ang$foccu[ang$foccu == "Hosiery Factory Hand"] = 7
ang$foccu[ang$foccu == "Hospital attendant"] = 5
ang$foccu[ang$foccu == "Hospital cleaner"] = 5
ang$foccu[ang$foccu == "Hospital Maid"] = 5
ang$foccu[ang$foccu == "Hospital maid"] = 5
ang$foccu[ang$foccu == "Hospital Nurse"] = 0
ang$foccu[ang$foccu == "Hospital nurse"] = 0
ang$foccu[ang$foccu == "Hospital Sister"] = 0
ang$foccu[ang$foccu == "Hospital Ward-maid"] = 5
ang$foccu[ang$foccu == "Hospital worker"] = 5
ang$foccu[ang$foccu == "Hotel Manager"] = 2
ang$foccu[ang$foccu == "Hotel Manageress"] = 2
ang$foccu[ang$foccu == "Hotel Proprietor"] = 2
ang$foccu[ang$foccu == "Hotel Proprietress"] = 2
ang$foccu[ang$foccu == "Hotel Receptionist"] = 3
ang$foccu[ang$foccu == "Hotel Servant"] = 5
ang$foccu[ang$foccu == "Hotel Waitress"] = 5
ang$foccu[ang$foccu == "Hotel-maid"] = 5
ang$foccu[ang$foccu == "House duties"] = NA
ang$foccu[ang$foccu == "House Duties"] = NA
ang$foccu[ang$foccu == "House maid"] = 5
ang$foccu[ang$foccu == "House servant"] = 5
ang$foccu[ang$foccu == "House work"] = NA
ang$foccu[ang$foccu == "Household duties"] = NA
ang$foccu[ang$foccu == "Household Duties"] = NA
ang$foccu[ang$foccu == "Household servant"] = 5
ang$foccu[ang$foccu == "Housekeeper"] = 5
ang$foccu[ang$foccu == "Housekeeper for father"] = 5
ang$foccu[ang$foccu == "Housemaid"] = 5
ang$foccu[ang$foccu == "House-maid"] = 5
ang$foccu[ang$foccu == "Housemaid + Waitress"] = 5
ang$foccu[ang$foccu == "Housemaid/Waitress"] = 5
ang$foccu[ang$foccu == "Housewife"] = NA
ang$foccu[ang$foccu == "Housewife duties"] = NA
ang$foccu[ang$foccu == "Housework"] = NA
ang$foccu[ang$foccu == "House-work"] = NA
ang$foccu[ang$foccu == "Housing Assistant"] = 3
ang$foccu[ang$foccu == "Housing Manager"] = 2
ang$foccu[ang$foccu == "Housing Manageress"] = 2
ang$foccu[ang$foccu == "Hygiene"] = 5
ang$foccu[ang$foccu == "Improver in Hat Factory"] = 7
ang$foccu[ang$foccu == "In service"] = 5
ang$foccu[ang$foccu == "In Service"] = 5
ang$foccu[ang$foccu == "Indent Clerk + Typist"] = 3
ang$foccu[ang$foccu == "Independent"] = NA
ang$foccu[ang$foccu == "Inspector - Hosiery Mills"] = 2
ang$foccu[ang$foccu == "Instrument Factory Worker"] = 9
ang$foccu[ang$foccu == "Insurance Agent"] = 4
ang$foccu[ang$foccu == "Insurance Clerk"] = 3
ang$foccu[ang$foccu == "Insurance Representative"] = 4
ang$foccu[ang$foccu == "Interior Decorator Consultant"] = 1
ang$foccu[ang$foccu == "Invincible mender"] = 7
ang$foccu[ang$foccu == "Invisible mender"] = 7
ang$foccu[ang$foccu == "Invisible Mender"] = 7
ang$foccu[ang$foccu == "Invoice clerk"] = 3
ang$foccu[ang$foccu == "Invoice Clerk"] = 3
ang$foccu[ang$foccu == "Invoice Typist"] = 3
ang$foccu[ang$foccu == "Ironer"] = 5
ang$foccu[ang$foccu == "Jeweller"] = 8
ang$foccu[ang$foccu == "Joint Hotel Proprietor"] = 2
ang$foccu[ang$foccu == "Journalist"] = 1
ang$foccu[ang$foccu == "Journalist's Secretary"] = 3
ang$foccu[ang$foccu == "Junior Clerk"] = 3
ang$foccu[ang$foccu == "Junior Lecturer"] = 1
ang$foccu[ang$foccu == "Kindergarten Teacher"] = 1
ang$foccu[ang$foccu == "Kitchen Hand"] = 5
ang$foccu[ang$foccu == "Kitchenmaid"] = 5
ang$foccu[ang$foccu == "Knitter"] = 7
ang$foccu[ang$foccu == "Knitting Machine Operator"] = 8
ang$foccu[ang$foccu == "Knitting machinist"] = 8
ang$foccu[ang$foccu == "Knitting Machinist"] = 8
ang$foccu[ang$foccu == "Knotter"] = 7
ang$foccu[ang$foccu == "Label Inspector"] = 2
ang$foccu[ang$foccu == "Laboratory assistant"] = 0
ang$foccu[ang$foccu == "Laboratory Assistant"] = 0
ang$foccu[ang$foccu == "Laboratory technician"] = 0
ang$foccu[ang$foccu == "Laboratory Technician"] = 0
ang$foccu[ang$foccu == "Laboratory Technology"] = 0
ang$foccu[ang$foccu == "Laboratory Tecnician"] = 0
ang$foccu[ang$foccu == "Labourer"] = 9
ang$foccu[ang$foccu == "Ladies Hairdresser"] = 5
ang$foccu[ang$foccu == "Ladie's Hairdresser"] = 5
ang$foccu[ang$foccu == "Ladies Outfitter"] = 5
ang$foccu[ang$foccu == "Lady Clerk"] = 5
ang$foccu[ang$foccu == "Lady Doctor"] = 0
ang$foccu[ang$foccu == "Lady Tracer"] = 9
ang$foccu[ang$foccu == "Lady's Maid"] = 5
ang$foccu[ang$foccu == "Land Girl"] = 6
ang$foccu[ang$foccu == "Laundress"] = 5
ang$foccu[ang$foccu == "Laundry"] = 5
ang$foccu[ang$foccu == "Laundry Checker"] = 3
ang$foccu[ang$foccu == "Laundry Cleaner"] = 5
ang$foccu[ang$foccu == "Laundry Depot Assistant"] = 5
ang$foccu[ang$foccu == "Laundry Employee"] = 5
ang$foccu[ang$foccu == "Laundry folder"] = 5
ang$foccu[ang$foccu == "Laundry Hand"] = 5
ang$foccu[ang$foccu == "Laundry maid"] = 5
ang$foccu[ang$foccu == "Laundry presser"] = 5
ang$foccu[ang$foccu == "Laundry Work"] = 5
ang$foccu[ang$foccu == "Laundry worker"] = 5
ang$foccu[ang$foccu == "Laundryhand"] = 5
ang$foccu[ang$foccu == "Laundry-woman"] = 5
ang$foccu[ang$foccu == "Lawyer"] = 1
ang$foccu[ang$foccu == "Layer up"] = 7
ang$foccu[ang$foccu == "Layer-up"] = 7
ang$foccu[ang$foccu == "Layer-up + Ironer"] = 7
ang$foccu[ang$foccu == "Layer-up in Clothing Factory "] = 7
ang$foccu[ang$foccu == "Leading Wren W.R.N.S."] = 5
ang$foccu[ang$foccu == "Leaf Examiner"] = 7
ang$foccu[ang$foccu == "Leaf Hand"] = 7
ang$foccu[ang$foccu == "Leafsorter in Tobacco Factory"] = 7
ang$foccu[ang$foccu == "Learner Cleaner"] = 5
ang$foccu[ang$foccu == "Learner Pattern Grader"] = 7
ang$foccu[ang$foccu == "Leather factory"] = 8
ang$foccu[ang$foccu == "Leather Machinist"] = 8
ang$foccu[ang$foccu == "Leather Trade"] = 8
ang$foccu[ang$foccu == "Leather worker"] = 8
ang$foccu[ang$foccu == "Leather Worker"] = 8
ang$foccu[ang$foccu == "Leatherworker"] = 8
ang$foccu[ang$foccu == "Leather-worker"] = 8
ang$foccu[ang$foccu == "Lecturer"] = 1
ang$foccu[ang$foccu == "Lecturer in Botany"] = 1
ang$foccu[ang$foccu == "Lecturer in Commerce"] = 1
ang$foccu[ang$foccu == "Lecturer U.C.T."] = 1
ang$foccu[ang$foccu == "Ledger Clerk"] = 3
ang$foccu[ang$foccu == "Ledger Clerk, Barclay's Bank"] = 3
ang$foccu[ang$foccu == "Ledger machine operator"] = 3
ang$foccu[ang$foccu == "Ledger Machinist"] = 3
ang$foccu[ang$foccu == "Ledger-clerk"] = 3
ang$foccu[ang$foccu == "Ledger-Operator"] = 3
ang$foccu[ang$foccu == "Legal Typist"] = 3
ang$foccu[ang$foccu == "Librarian"] = 1
ang$foccu[ang$foccu == "Library Assistant"] = 1
ang$foccu[ang$foccu == "Library Book Processor"] = 1
ang$foccu[ang$foccu == "Lidder"] = 9
ang$foccu[ang$foccu == "Lieut. W.A.A.F."] = 5
ang$foccu[ang$foccu == "Lieutenant W.A.A.F."] = 5
ang$foccu[ang$foccu == "Lift Operator"] = 5
ang$foccu[ang$foccu == "Liner - Leather Industry"] = 8
ang$foccu[ang$foccu == "Lodginghouse Keeper"] = 2
ang$foccu[ang$foccu == "Lt. W.A.A.S."] = 5
ang$foccu[ang$foccu == "Machine Feeder"] = 9
ang$foccu[ang$foccu == "Machine Hand"] = 9
ang$foccu[ang$foccu == "Machine Operator"] = 8
ang$foccu[ang$foccu == "Machine-hand"] = 9
ang$foccu[ang$foccu == "Machinist"] = 8
ang$foccu[ang$foccu == "Machinist (Factory)"] = 8
ang$foccu[ang$foccu == "Machinist at Factory"] = 8
ang$foccu[ang$foccu == "Machinist at Tobacco Factory"] = 8
ang$foccu[ang$foccu == "Machinist Clothing Factory"] = 8
ang$foccu[ang$foccu == "Machinist Clothing Industry"] = 8
ang$foccu[ang$foccu == "Machinist Clothing Trade"] = 8
ang$foccu[ang$foccu == "Machinist Factory"] = 8
ang$foccu[ang$foccu == "Machinist in Brush Factory"] = 8
ang$foccu[ang$foccu == "Machinist in Clothing Factory"] = 8
ang$foccu[ang$foccu == "Machinist in Clothing factory"] = 8
ang$foccu[ang$foccu == "Machinist in Factory"] = 8
ang$foccu[ang$foccu == "Machinist in Leather Factory"] = 8
ang$foccu[ang$foccu == "Machinist Leather Trade"] = 8
ang$foccu[ang$foccu == "Machinist Match Factory"] = 8
ang$foccu[ang$foccu == "Machinist Paper Factory"] = 8
ang$foccu[ang$foccu == "Machinist Printing Trade"] = 8
ang$foccu[ang$foccu == "Machinist Shirt Factory"] = 8
ang$foccu[ang$foccu == "Machinist, African Clothing"] = 8
ang$foccu[ang$foccu == "Maid"] = 5
ang$foccu[ang$foccu == "Maid Attendant"] = 5
ang$foccu[ang$foccu == "Maid/Waitress"] = 5
ang$foccu[ang$foccu == "Maid-servant"] = 5
ang$foccu[ang$foccu == "Manageress"] = 2
ang$foccu[ang$foccu == "Manageress Caledon Baths"] = 2
ang$foccu[ang$foccu == "Manageress Saleslady"] = 2
ang$foccu[ang$foccu == "Mannequin"] = 4
ang$foccu[ang$foccu == "Mapping Assistant"] = 0
ang$foccu[ang$foccu == "Marker"] = 3
ang$foccu[ang$foccu == "Marker (Clothing)"] = 7
ang$foccu[ang$foccu == "Marker Clothing Industry"] = 8
ang$foccu[ang$foccu == "Marker Leather Industry"] = 8
ang$foccu[ang$foccu == "Marketing-Assistant in Shell Co."] = 4
ang$foccu[ang$foccu == "Masseuse"] = 5
ang$foccu[ang$foccu == "Match-sorter "] = 9
ang$foccu[ang$foccu == "Maternity Nurse"] = 0
ang$foccu[ang$foccu == "Matron, Day Nursery"] = 2
ang$foccu[ang$foccu == "Mattress maker"] = 7
ang$foccu[ang$foccu == "Mechanic"] = 8
ang$foccu[ang$foccu == "Medical Laboratory Technician"] = 0
ang$foccu[ang$foccu == "Medical Laboratory Technologist"] = 0
ang$foccu[ang$foccu == "Medical Practitioner"] = 0
ang$foccu[ang$foccu == "Medical Research Assistant"] = 0
ang$foccu[ang$foccu == "Medical Student"] = 0
ang$foccu[ang$foccu == "Medical Technician"] = 0
ang$foccu[ang$foccu == "Medical Technologist"] = 0
ang$foccu[ang$foccu == "Medicine Packer"] = NA
ang$foccu[ang$foccu == "Medicine packer"] = NA
ang$foccu[ang$foccu == "Mender"] = 7
ang$foccu[ang$foccu == "Mender at Stocking Factory"] = 7
ang$foccu[ang$foccu == "Mental Therapist"] = 0
ang$foccu[ang$foccu == "Merchant's Employee"] = 4
ang$foccu[ang$foccu == "Messenger"] = 3
ang$foccu[ang$foccu == "Meteorological Section S.A.A.F."] = 0
ang$foccu[ang$foccu == "Meteorologist"] = 0
ang$foccu[ang$foccu == "Microbiologist"] = 0
ang$foccu[ang$foccu == "Midwife"] = 0
ang$foccu[ang$foccu == "Military Nurse"] = 0
ang$foccu[ang$foccu == "Military, Sergeant W.A.A.S., Pretoria"] = 5
ang$foccu[ang$foccu == "Military,W.A.A.F."] = 5
ang$foccu[ang$foccu == "Milliner"] = 7
ang$foccu[ang$foccu == "Milliner's Apprentice"] = 7
ang$foccu[ang$foccu == "Millinery Assistant"] = 7
ang$foccu[ang$foccu == "Millinery assistant"] = 7
ang$foccu[ang$foccu == "Millinery Trimmer"] = 7
ang$foccu[ang$foccu == "Missionary"] = 1
ang$foccu[ang$foccu == "Missionary nurse"] = 0
ang$foccu[ang$foccu == "Mistress"] = 1
ang$foccu[ang$foccu == "Model"] = 1
ang$foccu[ang$foccu == "Modiste"] = 7
ang$foccu[ang$foccu == "Monotype Operator"] = 9
ang$foccu[ang$foccu == "Mother's Help"] = NA
ang$foccu[ang$foccu == "Mother's Keeper"] = NA
ang$foccu[ang$foccu == "Mould maker"] = 8
ang$foccu[ang$foccu == "Munition work"] = 9
ang$foccu[ang$foccu == "Music Operator U.T.C."] = 5
ang$foccu[ang$foccu == "Music Teacher"] = 1
ang$foccu[ang$foccu == "Musician"] = 1
ang$foccu[ang$foccu == "Music-teacher"] = 1
ang$foccu[ang$foccu == "NA"] = NA
ang$foccu[ang$foccu == "Net-Braider"] = 7
ang$foccu[ang$foccu == "Net-Braider(Fishing Industry)"] = 7
ang$foccu[ang$foccu == "No occupation"] = NA
ang$foccu[ang$foccu == "No Occupation"] = NA
ang$foccu[ang$foccu == "No Occupation (formerly Journalist)"] = 1
ang$foccu[ang$foccu == "None"] = NA
ang$foccu[ang$foccu == "Nurse"] = 0
ang$foccu[ang$foccu == "Nurse (Mental Hospital)"] = 0
ang$foccu[ang$foccu == "Nurse Aid"] = 0
ang$foccu[ang$foccu == "Nurse assistant"] = 0
ang$foccu[ang$foccu == "Nurse Attendant"] = 0
ang$foccu[ang$foccu == "Nurse girl"] = 0
ang$foccu[ang$foccu == "Nurse Military Hospital"] = 0
ang$foccu[ang$foccu == "Nurse trainee"] = 0
ang$foccu[ang$foccu == "Nurse-aid"] = 0
ang$foccu[ang$foccu == "Nurse-aide"] = 0
ang$foccu[ang$foccu == "Nurse-Companion"] = 0
ang$foccu[ang$foccu == "Nurse-girl"] = 0
ang$foccu[ang$foccu == "Nursemaid"] = 5
ang$foccu[ang$foccu == "Nurse-maid"] = 5
ang$foccu[ang$foccu == "Nursery Nurse"] = 5
ang$foccu[ang$foccu == "Nursery School Assistant"] = 1
ang$foccu[ang$foccu == "Nursery School Teacher"] = 1
ang$foccu[ang$foccu == "Nurse's assistant"] = 0
ang$foccu[ang$foccu == "Nursing"] = 0
ang$foccu[ang$foccu == "Nursing assistant"] = 0
ang$foccu[ang$foccu == "Nursing sister"] = 0
ang$foccu[ang$foccu == "Nursing Sister"] = 0
ang$foccu[ang$foccu == "Nylon Operator"] = 8
ang$foccu[ang$foccu == "Occupational Therapist"] = 0
ang$foccu[ang$foccu == "Oculist's Assistant"] = 0
ang$foccu[ang$foccu == "Office Assistant"] = 3
ang$foccu[ang$foccu == "Office cleaner"] = 5
ang$foccu[ang$foccu == "Office Cleaner"] = 5
ang$foccu[ang$foccu == "Office Clerk"] = 3
ang$foccu[ang$foccu == "Office Domestic"] = 5
ang$foccu[ang$foccu == "Office Receptionist"] = 3
ang$foccu[ang$foccu == "Office Tea Girl"] = 5
ang$foccu[ang$foccu == "Office Work"] = 3
ang$foccu[ang$foccu == "Office worker"] = 3
ang$foccu[ang$foccu == "Office-girl"] = 3
ang$foccu[ang$foccu == "Old Age Pensioner"] = NA
ang$foccu[ang$foccu == "On Active Service"] = 5
ang$foccu[ang$foccu == "On Active Service "] = 5
ang$foccu[ang$foccu == "On Active Service S.A.W.A.N.S."] = 5
ang$foccu[ang$foccu == "On Active Service U.D.F."] = 5
ang$foccu[ang$foccu == "On Active Service W.A.N.S."] = 5
ang$foccu[ang$foccu == "Operator"] = 9
ang$foccu[ang$foccu == "Operator at Factory"] = 8
ang$foccu[ang$foccu == "Operator in Cigarette Factory"] = 8
ang$foccu[ang$foccu == "Optical Operator"] = 0
ang$foccu[ang$foccu == "Optitian"] = 0
ang$foccu[ang$foccu == "Order Clerk"] = 3
ang$foccu[ang$foccu == "Orthoptist"] = 0
ang$foccu[ang$foccu == "Packaging Assistant"] = 9
ang$foccu[ang$foccu == "Packer"] = 9
ang$foccu[ang$foccu == "Packer "] = 9
ang$foccu[ang$foccu == "Packer - Biscuit Factory  "] = 9
ang$foccu[ang$foccu == "Packer + Sorter"] = 9
ang$foccu[ang$foccu == "Packer Chemical Factory"] = 9
ang$foccu[ang$foccu == "Packer Chocolate factory"] = 9
ang$foccu[ang$foccu == "Packer Clothing Factory"] = 9
ang$foccu[ang$foccu == "Packer in factory"] = 9
ang$foccu[ang$foccu == "Packer in Grocery Dept."] = 9
ang$foccu[ang$foccu == "Packer of Handbags"] = 9
ang$foccu[ang$foccu == "Packer(Factory)"] = 9
ang$foccu[ang$foccu == "Packer's Assistant"] = 9
ang$foccu[ang$foccu == "Packing Assistant"] = 9
ang$foccu[ang$foccu == "Painter"] = 9
ang$foccu[ang$foccu == "Painter's assistant"] = 9
ang$foccu[ang$foccu == "Paper Bag Maker"] = 9
ang$foccu[ang$foccu == "Paper factory hand"] = 9
ang$foccu[ang$foccu == "Paper factory worker"] = 9
ang$foccu[ang$foccu == "Paper Folder"] = 9
ang$foccu[ang$foccu == "Paper Machinist"] = 8
ang$foccu[ang$foccu == "Paper-bag maker"] = 9
ang$foccu[ang$foccu == "Paperbag-maker"] = 9
ang$foccu[ang$foccu == "Parachute Packer W.A.A.F"] = 9
ang$foccu[ang$foccu == "Parlour Maid"] = 5
ang$foccu[ang$foccu == "Parlour-maid"] = 5
ang$foccu[ang$foccu == "Pathology Technician"] = 0
ang$foccu[ang$foccu == "Pattern Grader"] = 7
ang$foccu[ang$foccu == "Pattern grader"] = 7
ang$foccu[ang$foccu == "Pattern maker"] = 7
ang$foccu[ang$foccu == "Pattern-cutter"] = 7
ang$foccu[ang$foccu == "Paymaster"] = 3
ang$foccu[ang$foccu == "Pensioner"] = NA
ang$foccu[ang$foccu == "Personel Officer"] = 3
ang$foccu[ang$foccu == "Personnel Manageress"] = 2
ang$foccu[ang$foccu == "Petty Officer W.R.N.S."] = 5
ang$foccu[ang$foccu == "Pharmaceutical Assistant"] = 0
ang$foccu[ang$foccu == "Pharmacist"] = 0
ang$foccu[ang$foccu == "Photograph Printer"] = 9
ang$foccu[ang$foccu == "Photographer"] = 1
ang$foccu[ang$foccu == "Photographer's assistant"] = 1
ang$foccu[ang$foccu == "Photographer's Assistant"] = 1
ang$foccu[ang$foccu == "Photographic Assistant"] = 1
ang$foccu[ang$foccu == "Photographic Developer"] = 9
ang$foccu[ang$foccu == "Physical Training Instructress"] = 1
ang$foccu[ang$foccu == "Physiotherapist"] = 0
ang$foccu[ang$foccu == "Placer"] = 8
ang$foccu[ang$foccu == "Plain server"] = 7
ang$foccu[ang$foccu == "Plain sewer"] = 7
ang$foccu[ang$foccu == "Plain Sewer"] = 7
ang$foccu[ang$foccu == "Plant Pathologist"] = 0
ang$foccu[ang$foccu == "Plastic Examiner"] = 7
ang$foccu[ang$foccu == "Police force"] = 5
ang$foccu[ang$foccu == "Post + Telegraph Assistant"] = 3
ang$foccu[ang$foccu == "Post Office Clerk"] = 3
ang$foccu[ang$foccu == "Post Office Worker"] = 3
ang$foccu[ang$foccu == "Post/Telegraph Assistant"] = 3
ang$foccu[ang$foccu == "Postal Assistant"] = 3
ang$foccu[ang$foccu == "Postal Service"] = 3
ang$foccu[ang$foccu == "Poster"] = 4
ang$foccu[ang$foccu == "Postmistress"] = 2
ang$foccu[ang$foccu == "Poultry dresser"] = 5
ang$foccu[ang$foccu == "Poultry farm employee"] = 6
ang$foccu[ang$foccu == "Powers A.K.P. Operator"] = 8
ang$foccu[ang$foccu == "Powers Sams Clerk"] = 3
ang$foccu[ang$foccu == "Powers-Operator"] = 8
ang$foccu[ang$foccu == "Pre-border in Hosiery Mills"] = 7
ang$foccu[ang$foccu == "Press Clerk"] = 3
ang$foccu[ang$foccu == "Presser"] = 7
ang$foccu[ang$foccu == "Presser in Clothing Factory"] = 7
ang$foccu[ang$foccu == "Primary School Mistress"] = 1
ang$foccu[ang$foccu == "Principal Teacher"] = 1
ang$foccu[ang$foccu == "Printer"] = 9
ang$foccu[ang$foccu == "Printer's assistant"] = 9
ang$foccu[ang$foccu == "Printer's Assistant"] = 9
ang$foccu[ang$foccu == "Printer's checker"] = 9
ang$foccu[ang$foccu == "Printer's cutter"] = 9
ang$foccu[ang$foccu == "Printer's Employee"] = 9
ang$foccu[ang$foccu == "Printer's Hand"] = 9
ang$foccu[ang$foccu == "Printer's Machinist"] = 8
ang$foccu[ang$foccu == "Printer's Works Assistant"] = 9
ang$foccu[ang$foccu == "Printing"] = 9
ang$foccu[ang$foccu == "Printing Assistant"] = 9
ang$foccu[ang$foccu == "Printing Trade"] = 9
ang$foccu[ang$foccu == "Printing Works"] = 9
ang$foccu[ang$foccu == "Printing Works Packer"] = 9
ang$foccu[ang$foccu == "Prison Wardress"] = 5
ang$foccu[ang$foccu == "Private S.A. Corps of Signallers  "] = 5
ang$foccu[ang$foccu == "Private secretary"] = 3
ang$foccu[ang$foccu == "Private Secretary"] = 3
ang$foccu[ang$foccu == "Private W.A.A.S."] = 5
ang$foccu[ang$foccu == "Probation Nurse"] = 0
ang$foccu[ang$foccu == "Probationer Nurse"] = 0
ang$foccu[ang$foccu == "Processor"] = NA
ang$foccu[ang$foccu == "Produce Dealer"] = 4
ang$foccu[ang$foccu == "Production Clerk"] = 3
ang$foccu[ang$foccu == "Professional Nurse"] = 0
ang$foccu[ang$foccu == "Programmer"] = 0
ang$foccu[ang$foccu == "Proof-reader"] = 1
ang$foccu[ang$foccu == "Psychologist"] = 0
ang$foccu[ang$foccu == "Public Relations Officer"] = 3
ang$foccu[ang$foccu == "Publisher's Writer"] = 1
ang$foccu[ang$foccu == "Puch Operator"] = 3
ang$foccu[ang$foccu == "Puch-card Operator"] = 3
ang$foccu[ang$foccu == "Punch Card Operator"] = 3
ang$foccu[ang$foccu == "Punch Machine Operator"] = 3
ang$foccu[ang$foccu == "Punch Operator"] = 3
ang$foccu[ang$foccu == "Punch-card Operator"] = 3
ang$foccu[ang$foccu == "Qualified Nurse"] = 0
ang$foccu[ang$foccu == "Qualified Sweet Worker"] = 7
ang$foccu[ang$foccu == "Quality Controller"] = 3
ang$foccu[ang$foccu == "Quarter Binder"] = 9
ang$foccu[ang$foccu == "Quarter Minder"] = 9
ang$foccu[ang$foccu == "Quarts-finder"] = 7
ang$foccu[ang$foccu == "Radio Operator"] = 3
ang$foccu[ang$foccu == "Radiographer"] = 0
ang$foccu[ang$foccu == "Railway Bookstall Attendant"] = 4
ang$foccu[ang$foccu == "Railway Café Employee"] = 5
ang$foccu[ang$foccu == "Reception Clerk"] = 3
ang$foccu[ang$foccu == "Receptionist"] = 3
ang$foccu[ang$foccu == "Receptionist Clerk"] = 3
ang$foccu[ang$foccu == "Receptionist S.A. Airways"] = 3
ang$foccu[ang$foccu == "Records Clerk"] = 3
ang$foccu[ang$foccu == "Red Cross Country Organizer "] = 3
ang$foccu[ang$foccu == "Registered General Nurse"] = 3
ang$foccu[ang$foccu == "Registered Nurse"] = 3
ang$foccu[ang$foccu == "Registered Nurse - Hospital Sister"] = 3
ang$foccu[ang$foccu == "Repairer (Shoe Factory)"] = 8
ang$foccu[ang$foccu == "Research Assistant"] = 1
ang$foccu[ang$foccu == "Research assistant"] = 1
ang$foccu[ang$foccu == "Research Assistant"] = 2
ang$foccu[ang$foccu == "Research Officer"] = 3
ang$foccu[ang$foccu == "Research Worker"] = 1
ang$foccu[ang$foccu == "Reservation Clerk"] = 3
ang$foccu[ang$foccu == "Retired"] = NA
ang$foccu[ang$foccu == "Retired Cashier"] = 3
ang$foccu[ang$foccu == "Retired Housewife"] = NA
ang$foccu[ang$foccu == "Retired School Teacher"] = 1
ang$foccu[ang$foccu == "Retired Teacher"] = 1
ang$foccu[ang$foccu == "Revenue Department"] = 3
ang$foccu[ang$foccu == "Rigger S.A.A.F."] = 9
ang$foccu[ang$foccu == "S.A. Broadcasting Corporation "] = 1
ang$foccu[ang$foccu == "S.A. Military Nursing Service"] = 0
ang$foccu[ang$foccu == "S.A.A.F."] = 5
ang$foccu[ang$foccu == "S.A.M.N.S."] = 5
ang$foccu[ang$foccu == "S.A.R.+H."] = 9
ang$foccu[ang$foccu == "Salaries Clerk"] = 3
ang$foccu[ang$foccu == "Sales assistant"] = 4
ang$foccu[ang$foccu == "Sales Assistant"] = 4
ang$foccu[ang$foccu == "Sales Hand"] = 4
ang$foccu[ang$foccu == "Sales lady"] = 4
ang$foccu[ang$foccu == "Sales Representative"] = 4
ang$foccu[ang$foccu == "Sales-Assistant"] = 4
ang$foccu[ang$foccu == "Saleshand"] = 4
ang$foccu[ang$foccu == "Saleslady"] = 4
ang$foccu[ang$foccu == "Saleswoman"] = 4
ang$foccu[ang$foccu == "Sampler"] = 7
ang$foccu[ang$foccu == "Scholar"] = NA
ang$foccu[ang$foccu == "School Caretaker"] = 5
ang$foccu[ang$foccu == "School Dental Nurse"] = 0
ang$foccu[ang$foccu == "School Instructress"] = 1
ang$foccu[ang$foccu == "School Matron"] = 2
ang$foccu[ang$foccu == "School Mistress"] = 1
ang$foccu[ang$foccu == "School mistress"] = 1
ang$foccu[ang$foccu == "School Teacher"] = 1
ang$foccu[ang$foccu == "School teacher"] = 1
ang$foccu[ang$foccu == "Schoolmistress"] = 1
ang$foccu[ang$foccu == "Scientist"] = 0
ang$foccu[ang$foccu == "Seamer"] = 7
ang$foccu[ang$foccu == "Seamstress"] = 7
ang$foccu[ang$foccu == "Second Officer W.R.N.S."] = 5
ang$foccu[ang$foccu == "Secretarial"] = 3
ang$foccu[ang$foccu == "Secretarial work"] = 3
ang$foccu[ang$foccu == "Secretary"] = 3
ang$foccu[ang$foccu == "Secretary/Typist"] = 3
ang$foccu[ang$foccu == "Semi-trained Nurse"] = 0
ang$foccu[ang$foccu == "Senior Probationer Nurse, S.A. Military Nursing Service"] = 0
ang$foccu[ang$foccu == "Sensamatic Operator"] = 0
ang$foccu[ang$foccu == "Sergeant S.A.A.F."] = 5
ang$foccu[ang$foccu == "Sergeant S.A.W.A.A.F."] = 5
ang$foccu[ang$foccu == "Sergeant W.A.A.F."] = 5
ang$foccu[ang$foccu == "Sergeant W.A.A.S."] = 5
ang$foccu[ang$foccu == "Sergeant W.A.A.S. (discharged)"] = 5
ang$foccu[ang$foccu == "Servant"] = 5
ang$foccu[ang$foccu == "Servant at Cape Town University"] = 5
ang$foccu[ang$foccu == "Service"] = 5
ang$foccu[ang$foccu == "Set-Leader"] = 1
ang$foccu[ang$foccu == "Sewing Machinist"] = 7
ang$foccu[ang$foccu == "Sheet metal Machinist"] = 8
ang$foccu[ang$foccu == "Sheet Metal Worker"] = 8
ang$foccu[ang$foccu == "Shipping Clerk"] = 3
ang$foccu[ang$foccu == "Shirt factory"] = 7
ang$foccu[ang$foccu == "Shirt factory assistant"] = 7
ang$foccu[ang$foccu == "Shirt Factory Assistant"] = 7
ang$foccu[ang$foccu == "Shirt Factory Employee"] = 7
ang$foccu[ang$foccu == "Shirt Factory Hand"] = 7
ang$foccu[ang$foccu == "Shirt factory Hand"] = 7
ang$foccu[ang$foccu == "Shirt factory Marker"] = 7
ang$foccu[ang$foccu == "Shirt factory worker"] = 7
ang$foccu[ang$foccu == "Shirt machinist"] = 7
ang$foccu[ang$foccu == "Shirt Machinist"] = 7
ang$foccu[ang$foccu == "Shirt maker"] = 7
ang$foccu[ang$foccu == "Shirt Presser"] = 7
ang$foccu[ang$foccu == "Shirt-maker"] = 7
ang$foccu[ang$foccu == "Shoe Examiner"] = 8
ang$foccu[ang$foccu == "Shoe Factory Employee"] = 8
ang$foccu[ang$foccu == "Shoe factory hand"] = 8
ang$foccu[ang$foccu == "Shoe Factory Hand"] = 8
ang$foccu[ang$foccu == "Shoe factory worker"] = 8
ang$foccu[ang$foccu == "Shoe Machinist"] = 8
ang$foccu[ang$foccu == "Shoe Trimmer"] = 8
ang$foccu[ang$foccu == "Shoe-examiner"] = 8
ang$foccu[ang$foccu == "Shoe-Preparer"] = 8
ang$foccu[ang$foccu == "Shop assistant"] = 4
ang$foccu[ang$foccu == "Shop Assistant"] = 4
ang$foccu[ang$foccu == "Shop Owner Florist"] = 4
ang$foccu[ang$foccu == "Shop Saleslady"] = 4
ang$foccu[ang$foccu == "Shop-assistant"] = 4
ang$foccu[ang$foccu == "Shopkeeper"] = 4
ang$foccu[ang$foccu == "Shorthand Typist"] = 3
ang$foccu[ang$foccu == "Shorthand Typist "] = 3
ang$foccu[ang$foccu == "Shorthand Typist (Corporal W.A.A.S.)"] = 3
ang$foccu[ang$foccu == "Shorthand Typist S.A. Air Force"] = 3
ang$foccu[ang$foccu == "Shorthand Typist, presently with H.M. Forces"] = 3
ang$foccu[ang$foccu == "Shorthand Typist/Bookkeeper"] = 3
ang$foccu[ang$foccu == "Shorthand Typist/On Active Service"] = 3
ang$foccu[ang$foccu == "Shorthand Writer"] = 3
ang$foccu[ang$foccu == "Shorthand Writer + Typist"] = 3
ang$foccu[ang$foccu == "Showroom Assistant"] = 4
ang$foccu[ang$foccu == "Shriven"] = 1
ang$foccu[ang$foccu == "Singer"] = 1
ang$foccu[ang$foccu == "Singing Teacher"] = 1
ang$foccu[ang$foccu == "Sister in Mental Hospital"] = 0
ang$foccu[ang$foccu == "Sister Tutor"] = 1
ang$foccu[ang$foccu == "Skin trade"] = 4
ang$foccu[ang$foccu == "Skiver"] = 8
ang$foccu[ang$foccu == "Slaughter House worker"] = 7
ang$foccu[ang$foccu == "Slide Artist"] = 1
ang$foccu[ang$foccu == "Smocking"] = 7
ang$foccu[ang$foccu == "Soap Packer"] = 9
ang$foccu[ang$foccu == "Social Investigator"] = 5
ang$foccu[ang$foccu == "Social worker"] = 1
ang$foccu[ang$foccu == "Social Worker"] = 1
ang$foccu[ang$foccu == "Sodawater Manufacturer"] = 7
ang$foccu[ang$foccu == "Solderer"] = 8
ang$foccu[ang$foccu == "Soldier, Private in W.A.A.S."] = 5
ang$foccu[ang$foccu == "Sorter"] = 9
ang$foccu[ang$foccu == "Sorter in Cavalla Factory"] = 7
ang$foccu[ang$foccu == "Sorter in Laundry"] = 5
ang$foccu[ang$foccu == "Sorter Printing Industry"] = 9
ang$foccu[ang$foccu == "Special Signals S.A. Corps of Signals"] = 8
ang$foccu[ang$foccu == "Special Signals Services"] = 8
ang$foccu[ang$foccu == "Speech Teacher"] = 1
ang$foccu[ang$foccu == "Speech Therapist"] = 0
ang$foccu[ang$foccu == "Speech Training Teacher"] = 1
ang$foccu[ang$foccu == "Spotter"] = 5
ang$foccu[ang$foccu == "St Johns"] = NA
ang$foccu[ang$foccu == "Stacker"] = 9
ang$foccu[ang$foccu == "Staff Maid"] = 5
ang$foccu[ang$foccu == "Staff Nurse"] = 0
ang$foccu[ang$foccu == "Staff Sergeant W.A.A.S."] = 5
ang$foccu[ang$foccu == "Staff-Nurse"] = 0
ang$foccu[ang$foccu == "Staff-Sergeant W.A.A.S."] = 5
ang$foccu[ang$foccu == "Stamper"] = 9
ang$foccu[ang$foccu == "Stamping Machinist in Tinsmiths"] = 8
ang$foccu[ang$foccu == "State Registered Nurse"] = 0
ang$foccu[ang$foccu == "Stationer"] = 3
ang$foccu[ang$foccu == "Stationery assistant"] = 3
ang$foccu[ang$foccu == "Statistic Clerk"] = 3
ang$foccu[ang$foccu == "Statistical Clerk"] = 3
ang$foccu[ang$foccu == "Stenographer"] = 3
ang$foccu[ang$foccu == "Stenographer Clerk"] = 3
ang$foccu[ang$foccu == "Stewardess"] = 5
ang$foccu[ang$foccu == "Stitcher"] = 7
ang$foccu[ang$foccu == "Stock Clerk"] = 3
ang$foccu[ang$foccu == "Stock clerk"] = 3
ang$foccu[ang$foccu == "Stock Control Clerk"] = 3
ang$foccu[ang$foccu == "Stockbroker's Clerk"] = 3
ang$foccu[ang$foccu == "Stockist"] = 3
ang$foccu[ang$foccu == "Store assistant"] = 4
ang$foccu[ang$foccu == "Store Assistant"] = 4
ang$foccu[ang$foccu == "Store Supervisor"] = 2
ang$foccu[ang$foccu == "Storekeeper"] = 3
ang$foccu[ang$foccu == "Storelady"] = 3
ang$foccu[ang$foccu == "Store-room Assistant"] = 3
ang$foccu[ang$foccu == "Stripper"] = 9
ang$foccu[ang$foccu == "Student"] = NA
ang$foccu[ang$foccu == "Student Cape Town University"] = NA
ang$foccu[ang$foccu == "Student Medical Technologist"] = 0
ang$foccu[ang$foccu == "Student Midwife"] = 0
ang$foccu[ang$foccu == "Student Nurse"] = 0
ang$foccu[ang$foccu == "Student nurse"] = 0
ang$foccu[ang$foccu == "Student of Music"] = 1
ang$foccu[ang$foccu == "Student Teacher"] = 1
ang$foccu[ang$foccu == "Student-Dietician"] = 0
ang$foccu[ang$foccu == "Student-Nurse"] = 0
ang$foccu[ang$foccu == "Sudent Nurse"] = 0
ang$foccu[ang$foccu == "Suitcase-maker"] = 8
ang$foccu[ang$foccu == "Supervisor"] = 2
ang$foccu[ang$foccu == "Supervisor - Cloting factory"] = 2
ang$foccu[ang$foccu == "Supervisor Clothing Factory"] = 2
ang$foccu[ang$foccu == "Supervisor Clothing Industry"] = 2
ang$foccu[ang$foccu == "Supervisor in business"] = 2
ang$foccu[ang$foccu == "Supervisor in Factory"] = 2
ang$foccu[ang$foccu == "Surgery Attendant"] = 0
ang$foccu[ang$foccu == "Surgery Receptionist"] = 3
ang$foccu[ang$foccu == "Survey Constructor"] = 3
ang$foccu[ang$foccu == "Survey Technician"] = 0
ang$foccu[ang$foccu == "Sweet box-maker"] = 7
ang$foccu[ang$foccu == "Sweet Factory"] = 7
ang$foccu[ang$foccu == "Sweet Factory Hand"] = 7
ang$foccu[ang$foccu == "Sweet Factory hand"] = 7
ang$foccu[ang$foccu == "Sweet Factory Machinist"] = 7
ang$foccu[ang$foccu == "Sweet Factory Packer"] = 7
ang$foccu[ang$foccu == "Sweet Factory Worker"] = 7
ang$foccu[ang$foccu == "Sweet factory-hand"] = 7
ang$foccu[ang$foccu == "Sweet Maker"] = 7
ang$foccu[ang$foccu == "Sweet maker"] = 7
ang$foccu[ang$foccu == "Sweet Moulder"] = 7
ang$foccu[ang$foccu == "Sweet Packer"] = 7
ang$foccu[ang$foccu == "Sweet wrapper"] = 7
ang$foccu[ang$foccu == "Sweet-Factory Employee"] = 7
ang$foccu[ang$foccu == "Sweetmaker"] = 7
ang$foccu[ang$foccu == "Sweet-maker"] = 7
ang$foccu[ang$foccu == "Sweets packer"] = 7
ang$foccu[ang$foccu == "Sweets-wrapper"] = 7
ang$foccu[ang$foccu == "Swimming Instructress"] = 1
ang$foccu[ang$foccu == "Switch Board Operator"] = 3
ang$foccu[ang$foccu == "Switchboard Operator"] = 3
ang$foccu[ang$foccu == "Table Hand"] = 9
ang$foccu[ang$foccu == "Table hand"] = 9
ang$foccu[ang$foccu == "Table hand (Shoe factory)"] = 8
ang$foccu[ang$foccu == "Table hand in Clothing Factory"] = 7
ang$foccu[ang$foccu == "Table Hand Leather Industry"] = 8
ang$foccu[ang$foccu == "Table-hand"] = 9
ang$foccu[ang$foccu == "Tablehand in Leather Industry"] = 8
ang$foccu[ang$foccu == "Tablehand Leather Industry"] = 8
ang$foccu[ang$foccu == "Tablehand Shoe Trade"] = 8
ang$foccu[ang$foccu == "Tailor"] = 7
ang$foccu[ang$foccu == "Tailoress"] = 7
ang$foccu[ang$foccu == "Tailoring"] = 7
ang$foccu[ang$foccu == "Tailor's Machinist"] = 7
ang$foccu[ang$foccu == "Tailor's Presser"] = 7
ang$foccu[ang$foccu == "Tea Girl"] = 5
ang$foccu[ang$foccu == "Tea Packer"] = 7
ang$foccu[ang$foccu == "Tea Woman"] = 5
ang$foccu[ang$foccu == "Teacher"] = 1
ang$foccu[ang$foccu == "Teacher Mission School"] = 1
ang$foccu[ang$foccu == "Teacher of Art"] = 1
ang$foccu[ang$foccu == "Teacher of Dancing"] = 1
ang$foccu[ang$foccu == "Teacher of Domestic Science"] = 1
ang$foccu[ang$foccu == "Teacher of Dramatic Art"] = 1
ang$foccu[ang$foccu == "Teacher of Education"] = 1
ang$foccu[ang$foccu == "Teacher of Eurhythnics"] = 1
ang$foccu[ang$foccu == "Teacher of Music"] = 1
ang$foccu[ang$foccu == "Tearoom Assistant"] = 5
ang$foccu[ang$foccu == "Technical Assistant"] = 8
ang$foccu[ang$foccu == "Technician"] = 0
ang$foccu[ang$foccu == "Technologist"] = 0
ang$foccu[ang$foccu == "Telecommunication Operator"] = 3
ang$foccu[ang$foccu == "Telegraphist"] = 3
ang$foccu[ang$foccu == "Telegraphist G.P.O."] = 3
ang$foccu[ang$foccu == "Telephone Exchange Operator"] = 3
ang$foccu[ang$foccu == "Telephone Operator"] = 3
ang$foccu[ang$foccu == "Telephone-Clerk"] = 3
ang$foccu[ang$foccu == "Telephonist"] = 3
ang$foccu[ang$foccu == "Telephonist Clerk"] = 3
ang$foccu[ang$foccu == "Telephonist G.P.O."] = 3
ang$foccu[ang$foccu == "Telephonist Receptionist"] = 3
ang$foccu[ang$foccu == "Telephonist Typist"] = 3
ang$foccu[ang$foccu == "Telephonist, Receptionist/Clerk"] = 3
ang$foccu[ang$foccu == "Telephonist/Clerk"] = 3
ang$foccu[ang$foccu == "Telephonist/Filing Clerk"] = 3
ang$foccu[ang$foccu == "Telephonist/Receptionist"] = 3
ang$foccu[ang$foccu == "Telephonist/Typist"] = 3
ang$foccu[ang$foccu == "Telephonist-Typist"] = 3
ang$foccu[ang$foccu == "Telex Operator"] = 3
ang$foccu[ang$foccu == "Telex-Operator"] = 3
ang$foccu[ang$foccu == "Teller"] = 3
ang$foccu[ang$foccu == "Teller Building Society"] = 3
ang$foccu[ang$foccu == "Tennis Coach"] = 1
ang$foccu[ang$foccu == "Textile Knitter"] = 7
ang$foccu[ang$foccu == "Textile machinist"] = 8
ang$foccu[ang$foccu == "Theatre Attendant"] = 5
ang$foccu[ang$foccu == "Theatre worker"] = 5
ang$foccu[ang$foccu == "Ticket Clerk"] = 3
ang$foccu[ang$foccu == "Ticket writer"] = 3
ang$foccu[ang$foccu == "Time Clerk"] = 3
ang$foccu[ang$foccu == "Tin Factory-hand"] = 8
ang$foccu[ang$foccu == "Tin worker"] = 8
ang$foccu[ang$foccu == "Tinworker"] = 8
ang$foccu[ang$foccu == "Tobacco Factory"] = 7
ang$foccu[ang$foccu == "Tobacco Factory Assistant"] = 7
ang$foccu[ang$foccu == "Tobacco Factory Employee"] = 7
ang$foccu[ang$foccu == "Tobacco Factory hand"] = 7
ang$foccu[ang$foccu == "Tobacco Factory Worker"] = 7
ang$foccu[ang$foccu == "Tobacco factory-hand"] = 7
ang$foccu[ang$foccu == "Tobacco Machine Operator"] = 8
ang$foccu[ang$foccu == "Tobacco Packer"] = 7
ang$foccu[ang$foccu == "Tobacco Worker"] = 7
ang$foccu[ang$foccu == "Tobacco Works Examiner"] = 7
ang$foccu[ang$foccu == "Touring-Clerk"] = 3
ang$foccu[ang$foccu == "Toy-maker"] = 7
ang$foccu[ang$foccu == "Tracer"] = 8
ang$foccu[ang$foccu == "Trade Union President"] = 2
ang$foccu[ang$foccu == "Trained Nurse"] = 0
ang$foccu[ang$foccu == "Translator"] = 1
ang$foccu[ang$foccu == "Transport Driver"] = 9
ang$foccu[ang$foccu == "Travel Agency Rep."] = 4
ang$foccu[ang$foccu == "Travel Agent"] = 4
ang$foccu[ang$foccu == "Travel Booking Clerk"] = 3
ang$foccu[ang$foccu == "Travel Clerk"] = 3
ang$foccu[ang$foccu == "Travel Consultant"] = 4
ang$foccu[ang$foccu == "Travel Receptionist"] = 3
ang$foccu[ang$foccu == "Treasurer-Librarian"] = 1
ang$foccu[ang$foccu == "Treblehand Leather Industry"] = 8
ang$foccu[ang$foccu == "Trimmer"] = 7
ang$foccu[ang$foccu == "Trouser Packer"] = 7
ang$foccu[ang$foccu == "Trousers maker"] = 7
ang$foccu[ang$foccu == "Turner"] = 8
ang$foccu[ang$foccu == "Tutor Sister"] = 1
ang$foccu[ang$foccu == "Typist"] = 3
ang$foccu[ang$foccu == "Typist & Telephonist"] = 3
ang$foccu[ang$foccu == "Typist + Secretary"] = 3
ang$foccu[ang$foccu == "Typist + shorthand"] = 3
ang$foccu[ang$foccu == "Typist + Wage Clerk"] = 3
ang$foccu[ang$foccu == "Typist Accountant"] = 1
ang$foccu[ang$foccu == "Typist clerk"] = 3
ang$foccu[ang$foccu == "Typist Clerk"] = 3
ang$foccu[ang$foccu == "Typist S.A.R."] = 3
ang$foccu[ang$foccu == "Typist/Advertising Clerk"] = 3
ang$foccu[ang$foccu == "Typist/Bookkeeper"] = 3
ang$foccu[ang$foccu == "Typist/Cashier"] = 3
ang$foccu[ang$foccu == "Typist/Clerk"] = 3
ang$foccu[ang$foccu == "Typist/Receptionist"] = 3
ang$foccu[ang$foccu == "Typist/Telephonist"] = 3
ang$foccu[ang$foccu == "Typist-Clerk"] = 3
ang$foccu[ang$foccu == "Underwear Machinist"] = 7
ang$foccu[ang$foccu == "Unemployed"] = NA
ang$foccu[ang$foccu == "University Lecturer"] = 1
ang$foccu[ang$foccu == "University Student"] = NA
ang$foccu[ang$foccu == "University Teacher"] = 1
ang$foccu[ang$foccu == "Upholsterer"] = 7
ang$foccu[ang$foccu == "Usherette"] = 5
ang$foccu[ang$foccu == "Usherette Orpheum Theatre"] = 5
ang$foccu[ang$foccu == "V.A.D."] = NA
ang$foccu[ang$foccu == "V.A.D. Hospital work + Home duties"] = NA
ang$foccu[ang$foccu == "Veterinary Surgeon's Receptionist"] = 3
ang$foccu[ang$foccu == "Vineyard dresser"] = 6
ang$foccu[ang$foccu == "Vineyard Employee"] = 6
ang$foccu[ang$foccu == "Vineyard labourer"] = 6
ang$foccu[ang$foccu == "Vineyard service"] = 6
ang$foccu[ang$foccu == "Vineyard work"] = 6
ang$foccu[ang$foccu == "Vineyard worker"] = 6
ang$foccu[ang$foccu == "Violin Teacher"] = 1
ang$foccu[ang$foccu == "Violinist"] = 1
ang$foccu[ang$foccu == "W A A S"] = 5
ang$foccu[ang$foccu == "W.A.A.F."] = 5
ang$foccu[ang$foccu == "W.A.A.F. (South Africa)"] = 5
ang$foccu[ang$foccu == "W.A.A.S."] = 5
ang$foccu[ang$foccu == "W.A.M.P.C."] = 5
ang$foccu[ang$foccu == "W.A.N.S."] = 5
ang$foccu[ang$foccu == "W.R.E.N."] = 5
ang$foccu[ang$foccu == "W/Sgt. W.A.A.F."] = 5
ang$foccu[ang$foccu == "Wage Clerk"] = 3
ang$foccu[ang$foccu == "Wage Machinist"] = 3
ang$foccu[ang$foccu == "Waitress"] = 5
ang$foccu[ang$foccu == "Walkers Bakery"] = 7
ang$foccu[ang$foccu == "War replacement Audit Clerk"] = 3
ang$foccu[ang$foccu == "War Supplies"] = 9
ang$foccu[ang$foccu == "Ward maid Hospital"] = 5
ang$foccu[ang$foccu == "Ward-maid"] = 5
ang$foccu[ang$foccu == "Wardmaid Groote Schuur Hospital"] = 5
ang$foccu[ang$foccu == "Warehouse Assistant"] = 3
ang$foccu[ang$foccu == "Warping machinist"] = 8
ang$foccu[ang$foccu == "Warrant Officer W.A.A.F."] = 5
ang$foccu[ang$foccu == "War-worker"] = 9
ang$foccu[ang$foccu == "Wash woman"] = 5
ang$foccu[ang$foccu == "Washer"] = 5
ang$foccu[ang$foccu == "Washerwoman"] = 5
ang$foccu[ang$foccu == "Washer-woman"] = 5
ang$foccu[ang$foccu == "Washing woman"] = 5
ang$foccu[ang$foccu == "Washwoman"] = 5
ang$foccu[ang$foccu == "Waste Clerk"] = 0
ang$foccu[ang$foccu == "Waverley Blankets Employee"] = 7
ang$foccu[ang$foccu == "Weaver"] = 7
ang$foccu[ang$foccu == "Weigher"] = 9
ang$foccu[ang$foccu == "Weigher at Crayfish Factory"] = 7
ang$foccu[ang$foccu == "Welfare Officer"] = 2
ang$foccu[ang$foccu == "Wholesale Assistant"] = 4
ang$foccu[ang$foccu == "Winder"] = 8
ang$foccu[ang$foccu == "Winder(KnittingMills)"] = 7
ang$foccu[ang$foccu == "Winding machinist"] = 8
ang$foccu[ang$foccu == "Window Dresser"] = 1
ang$foccu[ang$foccu == "Window dresser"] = 1
ang$foccu[ang$foccu == "Window-dresser"] = 1
ang$foccu[ang$foccu == "Winery Employee"] = 6
ang$foccu[ang$foccu == "Winery labourer"] = 6
ang$foccu[ang$foccu == "Wire Badge Embroiderer"] = 9
ang$foccu[ang$foccu == "Woman Assistant"] = 5
ang$foccu[ang$foccu == "Woman assistant, City Council"] = 5
ang$foccu[ang$foccu == "Woman Operative(Postal)"] = 3
ang$foccu[ang$foccu == "Woman Police Constable"] = 5
ang$foccu[ang$foccu == "Women's Army W.A.A.F."] = 5
ang$foccu[ang$foccu == "Women's Auxiliary Air Force"] = 5
ang$foccu[ang$foccu == "Women's Auxiliary Naval Service"] = 5
ang$foccu[ang$foccu == "Women's Auxiliary Naval Services"] = 5
ang$foccu[ang$foccu == "Woollen Knits Maker"] = 7
ang$foccu[ang$foccu == "Work Supervisor"] = 2
ang$foccu[ang$foccu == "Worker at Mineral water Factory"] = 7
ang$foccu[ang$foccu == "Worker in Fish Factory"] = 7
ang$foccu[ang$foccu == "Worker in Suit Case Factory"] = 8
ang$foccu[ang$foccu == "Worker in Tobacco Factory"] = 7
ang$foccu[ang$foccu == "Working in Furniture Store"] = 4
ang$foccu[ang$foccu == "Work's Supervisor"] = 2
ang$foccu[ang$foccu == "Worsted Weaving Instructress"] = 1
ang$foccu[ang$foccu == "Wrapper"] = 9
ang$foccu[ang$foccu == "Wrapper - Baumanns Biscuit Factory"] = 7
ang$foccu[ang$foccu == "Wrapper in Biscuit Factory"] = 7
ang$foccu[ang$foccu == "Wrapper in Factory"] = 9
ang$foccu[ang$foccu == "Wren"] = 5
ang$foccu[ang$foccu == "Wren H.M. Navy"] = 5
ang$foccu[ang$foccu == "Zoologist"] = 0
ang$foccu[ang$foccu == "Red Cross Country Organizer"] = NA
ang$foccu[ang$foccu == "Clerk Deciduous Fruit Board"] = NA
ang$foccu[ang$foccu == "Match-sorter"] = NA
ang$foccu[ang$foccu == "Layer-up in Clothing Factory"] = NA
ang$foccu[ang$foccu == "Research Executive"] = 0
ang$foccu[ang$foccu == "Private S.A. Corps of Signallers"] = NA
ang$foccu[ang$foccu == "Airwoman"] = NA
ang$foccu[ang$foccu == "Biscuit Factory"] = NA
ang$foccu[ang$foccu == "S.A. Broadcasting Corporation"] = NA
ang$foccu[ang$foccu == "Packer - Biscuit Factory"] = NA


####################

ang$mhisco = ang$moccu
ang$mhisco[ang$mhisco == 1] = 1
ang$mhisco[ang$mhisco == 2] = 1
ang$mhisco[ang$mhisco == 3] = 1
ang$mhisco[ang$mhisco == 4] = 2
ang$mhisco[ang$mhisco == 5] = 2
ang$mhisco[ang$mhisco == 6] = 3
ang$mhisco[ang$mhisco == 7] = 3
ang$mhisco[ang$mhisco == 8] = 3
ang$mhisco[ang$mhisco == 9] = 3
ang$mhisco[ang$mhisco == 0] = 1

ang$fhisco = ang$foccu
ang$fhisco[ang$fhisco == 1] = 1
ang$fhisco[ang$fhisco == 2] = 1
ang$fhisco[ang$fhisco == 3] = 1
ang$fhisco[ang$fhisco == 4] = 2
ang$fhisco[ang$fhisco == 5] = 2
ang$fhisco[ang$fhisco == 6] = 3
ang$fhisco[ang$fhisco == 7] = 3
ang$fhisco[ang$fhisco == 8] = 3
ang$fhisco[ang$fhisco == 9] = 3
ang$fhisco[ang$fhisco == 0] = 1

ang$mhiscodum = ang$mhisco
ang$mhiscodum[ang$mhiscodum == 1] = "Professional, managerial and administrative"
ang$mhiscodum[ang$mhiscodum == 2] = "Sales and servise workers"
ang$mhiscodum[ang$mhiscodum == 3] = "Agricultural, forestry, fisheries and hunting"
ang$mhiscodum[ang$mhiscodum == 4] = "Production, transport and general labourers"

ang$fhiscodum = ang$fhisco
ang$fhiscodum[ang$fhiscodum == 1] = "Professional, managerial and administrative"
ang$fhiscodum[ang$fhiscodum == 2] = "Sales and servise workers"
ang$fhiscodum[ang$fhiscodum == 3] = "Agricultural, forestry, fisheries and hunting"
ang$fhiscodum[ang$fhiscodum == 4] = "Production, transport and general labourers"

ang$mhisco = as.numeric(ang$mhisco)
ang$fhisco = as.numeric(ang$fhisco)
ang$doccu = ifelse(ang$mhisco == ang$fhisco, 1, 0)

####
ang$fdom = ang$frank
ang = data.table(ang)
ang$fdom[ang$frank != "Domestic servant"] = 0
ang$fdom[ang$frank == "Domestic servant"] = 1
ang$fdom[ang$frank == "domestic servant"] = 1
ang$fdom[ang$frank == "Domestic service"] = 1

ang$mlab = ang$mrank
ang = data.table(ang)
ang$mlab[ang$mrank != "Labourer"] = 0
ang$mlab[ang$mrank == "Labourer"] = 1
ang$mlab[ang$mrank == "labourer"] = 1

#############

ang$mhiscodum = ang$mhisco
ang = data.table(ang)
ang$mhiscodum[ang$mhisco < 20] = 'Professional'
ang$mhiscodum[ang$mhisco > 19 & ang$mhisco < 40] = 'Manager & clerical'
ang$mhiscodum[ang$mhisco > 39 & ang$mhisco < 60] = 'Sales & services'
ang$mhiscodum[ang$mhisco > 59 & ang$mhisco < 70] = 'Agriculture'
ang$mhiscodum[ang$mhisco > 69] = 'Production'

#Act dummy

ang$act = ifelse(ang$year > 1948, 1, 0)
ang$suffrage = ifelse(ang$year > 1930, 1, 0)
ang$election = ifelse(ang$year > 1938, 1, 0)

###Months

ang$monthnumber = ang$month
ang$monthnumber[ang$monthnumber == "January"] = 01
ang$monthnumber[ang$monthnumber == "February"] = 02
ang$monthnumber[ang$monthnumber == "March"] = 03
ang$monthnumber[ang$monthnumber == "April"] = 04
ang$monthnumber[ang$monthnumber == "May"] = 05
ang$monthnumber[ang$monthnumber == "May "] = 05
ang$monthnumber[ang$monthnumber == "Mei"] = 05
ang$monthnumber[ang$monthnumber == "June"] = 06
ang$monthnumber[ang$monthnumber == "Junie"] = 06
ang$monthnumber[ang$monthnumber == "July"] = 07
ang$monthnumber[ang$monthnumber == "August"] = 08
ang$monthnumber[ang$monthnumber == "September"] = 09
ang$monthnumber[ang$monthnumber == "October"] = 10
ang$monthnumber[ang$monthnumber == "November"] = 11
ang$monthnumber[ang$monthnumber == "December"] = 12
ang$monthnumber[ang$monthnumber == "."] = NA

ang$date = paste(ang$day, ang$monthnumber, ang$year, sep = '-')


###Intermarriage

ang$interdum = ifelse(ang$mrace == ang$frace, 0, 1)
ang$inter = ifelse(ang$interdum == 1, 'Mixed', 'Same')

year1 = aggregate(ang$interdum==1 ~ year, ang, sum)
year2 = aggregate(ang$interdum==0 ~ year, ang, sum)

years = merge(year1, year2, by='year')
years = data.table(years)
years$share = (years$`ang$interdum == 1` / (years$`ang$interdum == 0` + years$`ang$interdum == 1`)) * 100
years = years[, .(year = years$year, m = years$`ang$interdum == 1`, s = years$`ang$interdum == 0`, share = share)]

###Literacy

flit1 = aggregate(ang$flit == 1 ~ year+frace, ang, sum)
flit2 = aggregate(ang$flit ==0 ~ year+frace, ang, sum)

flit = merge(flit1, flit2, by=c('year', 'frace'))
flit = data.table(flit)
flit$total = flit$`ang$flit == 0` + flit$`ang$flit == 1`
flit$share = flit$`ang$flit == 1` / flit$total

###Literacy by decade
flit8 = aggregate(ang$flit == 1 ~ decade+frace, ang, sum)
flit9 = aggregate(ang$flit ==0 ~ decade+frace, ang, sum)

flitdec = merge(flit8, flit9, by=c('decade', 'frace'))
flitdec = data.table(flitdec)
flitdec$total = flitdec$`ang$flit == 0` + flitdec$`ang$flit == 1`
flitdec$share = flitdec$`ang$flit == 1` / flitdec$total

###Sex ratio

ang = merge(ang, sex, by=c('year', 'mrace'), all=TRUE)

####Attempt to get concentration by day
parishday1 = aggregate(ang$mrace=='Black' ~ pid+date, data=ang, FUN=sum)
parishday2 = aggregate(ang$mrace=='Coloured' ~ pid+date, data=ang, FUN=sum)
parishday3 = aggregate(ang$mrace=='White' ~ pid+date, data=ang, FUN=sum)
parishday = merge(parishday1, parishday2, by=c('pid', 'date'))
parishday = merge(parishday, parishday3, by=c('pid', 'date'))
parishday = data.table(parishday)
parishday = parishday[, .(date = parishday$date, pid = parishday$pid, black = parishday$`ang$mrace == "Black"`, coloured = parishday$`ang$mrace == "Coloured"`, white = parishday$`ang$mrace == "White"`)]
parishday = melt(parishday, id=c('pid', 'date'))
parishdaycon = parishday[, .(inequality = conc(value, type = "Herfindahl")), by=c('pid', 'date') ]

#ang = merge(ang, parishdaycon, by=c('pid', 'date'), all=TRUE)

####Concentration

parish1 = aggregate(ang$mrace=='Black' ~ pid+year, data=ang, FUN=sum)
parish2 = aggregate(ang$mrace=='Coloured' ~ pid+year, data=ang, FUN=sum)
parish3 = aggregate(ang$mrace=='White' ~ pid+year, data=ang, FUN=sum)
parish = merge(parish1, parish2, by=c('pid', 'year'))
parish = merge(parish, parish3, by=c('pid', 'year'))
parish = data.table(parish)
parish = parish[, .(year = parish$year, pid = parish$pid, black = parish$`ang$mrace == "Black"`, coloured = parish$`ang$mrace == "Coloured"`, white = parish$`ang$mrace == "White"`)]
parish = melt(parish, id=c('pid', 'year'))
parishcon = parish[, .(inequality = conc(value, type = "Herfindahl")), by=c('pid', 'year') ]

ang = merge(ang, parishcon, by=c('pid', 'year'), all=TRUE)

parishyear = data.table(parishcon)
parishyearcount = count(ang, c('pid', 'year'))
parishyear = merge(parishyear, parishyearcount, by=c('pid', 'year'))

parishyearweight = parishyear[,list(inequality = weighted.mean(inequality, freq)),by=year]

#parishyear = aggregate(parishyear$inequality ~ year, data=parishyear, FUN=weighted.mean(parishyear$inequality, w=parishyear$freq))
#parishyear[parishyear$inequality==1] = NA
parishyear = aggregate(parishyear$inequality ~ year, data=parishyear, FUN=mean)


parishgraph = aggregate(value ~ year + variable, data=parish, FUN=sum)

###Race

#raceyear = aggregate(parish$value ~ year+variable, data=parish, FUN=sum)
#raceyear = data.table(raceyear)
#raceyear = raceyear[, .(year = raceyear$year, race = raceyear$variable, number = raceyear$`parish$value`)]
#total = aggregate(parish$value ~ year, data = parish, FUN = sum)
#raceyear = merge(raceyear, total, by=c('year'))
#raceyear$share = (raceyear$number / raceyear$`parish$value`)*100
#blackshare = raceyear[race=='black', .(year, race, black = share)]
#colouredshare = raceyear[race=='coloured', .(year, race, coloured = share)]
#whiteshare = raceyear[race=='white', .(year, race, white = share)]
#blackshare$mrace[blackshare$race == 'black'] = 'Black'
#blackshare = blackshare[, .(year, mrace, black)]
#colouredshare$mrace[colouredshare$race == 'coloured'] = 'Coloured'
#colouredshare = colouredshare[, .(year, mrace, coloured)]
#whiteshare$mrace[whiteshare$race == 'white'] = 'White'
#whiteshare = whiteshare[, .(year, mrace, white)]

###



intermarriage = ang[interdum == 1, ]
intermarriage$type = ifelse(intermarriage$mrace == 'White' & intermarriage$frace == 'Coloured', 'wc',
                            ifelse(intermarriage$mrace == 'Coloured' & intermarriage$frace == 'White', 'cw',
                                   ifelse(intermarriage$mrace == 'Black' & intermarriage$frace == 'Coloured', 'bc',
                                          ifelse(intermarriage$mrace == 'Coloured' & intermarriage$frace == 'Black', 'cb',
                                                 ifelse(intermarriage$mrace == 'Black' & intermarriage$frace == 'White', 'bw', 'wb')))))

males = data.table(ang)
males$type = ifelse(males$mrace == 'White' & males$frace == 'Coloured', 'wc',
                            ifelse(males$mrace == 'Coloured' & males$frace == 'White', 'cw',
                                   ifelse(males$mrace == 'Black' & males$frace == 'Coloured', 'bc',
                                          ifelse(males$mrace == 'Coloured' & males$frace == 'Black', 'cb',
                                                 ifelse(males$mrace == 'Black' & males$frace == 'White', 'bw', 
                                                        ifelse(males$mrace =='White' & males$frace == 'Black', 'wb',
                                                               ifelse(males$mrace == 'White' & males$frace == 'White', 'ww',
                                                                      ifelse(males$mrace == 'Coloured' & males$frace == 'Coloured', 'cc', 'bb'))))))))




descriptivemale = read_excel(file.path(DATA_DIR,"Interrace.xlsx"),"DescriptivesMale", col_names = TRUE)
descriptivefemale = read_excel(file.path(DATA_DIR,"Interrace.xlsx"),"DescriptivesFemale", col_names = TRUE)

ggplot(descriptivemale, aes(type, share)) + geom_col(fill = (values = c("red", "red", "red", "blue", "blue","blue", "orange", "orange", "orange")))

ggplot(descriptivefemale, aes(type, share)) + geom_col(fill = (values = c("red", "blue", "orange", "red", "blue","orange", "red", "blue", "orange")))

#Unique towns

mtown = as.data.frame(unique(ang$mtown)) 
ftown = as.data.frame(unique(ang$ftown))
mtown = data.table(mtown)
mtown = mtown[, .(town = mtown$`unique(ang$mtown)`)]
ftown = data.table(ftown)
ftown = ftown[, .(town = ftown$`unique(ang$ftown)`)]
town = as.data.frame(unique(rbind(ftown, mtown)))

norace = data.table(ang)
norace = norace[is.na(norace$mrace), .(msurname, mname, mrace)]

race = data.table(ang)
race = race[!is.na(race$mrace), .(msurname, mname, mrace)]


############################################




###plottests

ang = ang[year>1908 & year<1964]

ggplot(ang, aes(ang$gap, fill = ang$mrace, ..count.., colour = ang$mrace)) +
  geom_density(alpha = 0.10)


ggplot(ang, aes(ang$year, fill = ang$inter, ..count.., colour = ang$inter)) +
  geom_density(alpha = 0.40) +
  ylab('Number of marriages') +
  xlab('Year') +
  theme(legend.title=element_blank())


ggplot(ang, aes(ang$year, fill = ang$mrace, ..count.., colour = ang$mrace)) +
  geom_density(alpha = 0.20) +
  ylab('Number of marriages') +
  xlab('Year') +
  theme(legend.title=element_blank())

ggplot(ang, aes(ang$year, fill = ang$mhisco, ..count.., colour = ang$mhisco)) +
  geom_density(alpha = 0.10) +
  ylab('Number of marriages') +
  xlab('Year') +
  theme(legend.title=element_blank())

ggplot(ang, aes(ang$year, fill = ang$mhiscodum, ..count.., colour = ang$mhiscodum)) +
  geom_density(alpha = 0.40) +
  ylab('Number of marriages') +
  xlab('Year') +
  theme(legend.title=element_blank())

###Share of interracial marriages

years = years[year > 1910 & year < 1966]

ggplot() + geom_line(aes(y = years$share, x = years$year), size=1, colour='red',
                     data = years, stat="identity") +
  geom_vline(aes(xintercept=1949), data=years,
             colour='black', linetype='dashed', size=1) +
  ylab('Share of interracial marriages (percentage)') +
  xlab('Year of marriage')

###

parishyear = data.table(parishyear)
parishyear = parishyear[year > 1908 & year < 1964]
ggplot() + geom_line(aes(y = parishyear$'parishyear$inequality', x = parishyear$year), size=1, colour='red',
                     data = parishyear, stat="identity") +
  geom_vline(aes(xintercept=1949), data=years,
             colour='black', linetype='dashed') +
  ylab('Racial concentration by parish') +
  xlab('Year of marriage')

###Racial concentration by parish over time - weighted results

df = data.frame(x1 = 1910, x2 = 1962, y1 = 0.65, y2 = 0.85)

parishyearweight = parishyearweight[year > 1908 & year < 1967]

ggplot() + geom_line(aes(y = parishyearweight$inequality, x = parishyearweight$year), size=1, colour='red',
                     data = parishyearweight, stat="identity") +
  geom_vline(aes(xintercept=1949), data=years,
             colour='black', linetype='dashed', size=1) +
  ylab('Racial concentration by parish') +
  xlab('Year of marriage') +
  geom_segment(
    aes(x = 1910, y = 0.65, xend = 1948, yend = 0.82),
    data = df,
    arrow = arrow(length = unit(0.03, "npc"))) +
  geom_segment(
    aes(x = 1950, y = 0.82, xend = 1966, yend = 0.82),
    data = df,
    arrow = arrow(length = unit(0.03, "npc")))

###Sex ratio over time

sex = sex[year > 1920 & year < 1961]
sex$lsex = sex$sex
sex$lsex = log(sex$sex)

ggplot(sex, aes(x=year, y=sex,
                 group=interaction(mrace),
                 colour=mrace)) + labs(colour='Male race') +
  geom_line(size=1.25) +
  geom_vline(aes(xintercept=1949), data=years,
             colour='black', linetype='dashed', size=1) +
  ylab('Sex ration in Cape Town') +
  xlab('Year')



#Literacy over time

flit = flit[year > 1908 & year < 1967]

ggplot(flit, aes(x=year, y=share,
                      group=interaction(frace),
                      colour=frace)) + labs(colour='Female Race') +
  geom_line() +
  geom_vline(aes(xintercept=1949), data=years,
             colour='black', linetype='dashed', size=1) +
  ylab('Share of literacy') +
  xlab('Year of marriage')

flitdec = flitdec[decade > 1910 & decade < 1961]

ggplot(flitdec, aes(x=decade, y=share,
                 group=interaction(frace),
                 colour=frace)) + labs(colour='Female Race') +
  geom_line() +
  ylab('Share of literacy') +
  xlab('Year of marriage')

###

missmap(intermarriage, main = "Missing values vs observed")

test1 = ang[, .(mrace, year, fage)]
test1 = ang[mrace!='Black',]
test1 = data.table(test1)
test1 = test1[,na.omit(test1)]
test1 = test1[test1$year > 1920]
test1 = test1[test1$year < 1950]
test1 = summarySE(test1, measurevar='fage', groupvars=c('year','mrace'))

ggplot(test1, aes(x=year, y=fage, colour=mrace, group=mrace)) + 
  geom_errorbar(aes(ymin=fage-ci, ymax=fage+ci), colour="black", width=.6, position=pd) +
  geom_line(position=pd) +
  geom_point(position=pd, size=5) +
  ylab('Age at marriage') +
  xlab('Marriage year') +
  labs(colour='Race')


#Literacy by interracial

test2 = ang[, .(mage, mrace, fage, frace, year, lit, decade, gap, inter, bdecade, interdum)]
test2 = data.table(test2)
test2 = test2[,na.omit(test2)]
test2 = test2[]
test2 = test2[test2$bdecade > 1910]
test2 = test2[test2$bdecade < 1965]
test2 = summarySE(test2, measurevar='lit', groupvars=c('bdecade','interdum'))

ggplot(test2, aes(x=bdecade, y=lit, colour=interdum, group=interdum)) + 
  geom_errorbar(aes(ymin=lit-ci, ymax=lit+ci), colour="black", width=.6, position=pd) +
  geom_line(position=pd) +
  geom_point(position=pd, size=5) +
  ylab('Literacy') +
  xlab('Birth year') +
  labs(colour='Interracial')


##By occupation
test2 = ang[, .(mage, mrace, fage, frace, year, lit, decade, gap, inter, bdecade, interdum, mhisco)]
test2 = data.table(test2)
test2 = test2[,na.omit(test2)]
test2 = test2[test2$bdecade > 1900]
test2 = test2[test2$bdecade < 1960]
test2 = summarySE(test2, measurevar='interdum', groupvars=c('mhisco'))

ggplot(test2, aes(x=mhisco, y=interdum, colour=mhisco, group=mhisco)) + 
  geom_errorbar(aes(ymin=interdum-ci, ymax=interdum+ci), colour="black", width=.6, position=pd) +
  geom_line(position=pd) +
  geom_point(position=pd, size=5) +
  ylab('Likelihood of interracial marriage') +
  xlab('Occupation class') +
  theme(legend.position="none")

##Occupation if male race is white

test2 = ang[, .(mage, mrace, fage, frace, year, lit, decade, gap, inter, bdecade, interdum, mhisco)]
test2 = data.table(test2)
test2 = test2[,na.omit(test2)]
test2 = test2[test2$mrace == "White"]
test2 = test2[test2$bdecade > 1900]
test2 = test2[test2$bdecade < 1960]
test2 = summarySE(test2, measurevar='interdum', groupvars=c('mhisco'))

ggplot(test2, aes(x=mhisco, y=interdum, group=mhisco)) + 
  geom_errorbar(aes(ymin=interdum-ci, ymax=interdum+ci), colour="black", width=.6, position=pd) +
  geom_line(position=pd) +
  geom_point(position=pd, size=5) +
  ylab('Share of interracial marriage') +
  xlab('Occupation class') +
  theme(legend.position="none")

##Occupation if female race is white

test2 = ang[, .(mage, mrace, fage, frace, year, lit, decade, gap, inter, bdecade, interdum, fhisco)]
test2 = data.table(test2)
test2 = test2[,na.omit(test2)]
test2 = test2[test2$frace == "White"]
test2 = test2[test2$bdecade > 1900]
test2 = test2[test2$bdecade < 1960]
test2 = summarySE(test2, measurevar='interdum', groupvars=c('fhisco'))

ggplot(test2, aes(x=fhisco, y=interdum, group=fhisco)) + 
  geom_errorbar(aes(ymin=interdum-ci, ymax=interdum+ci), colour="black", width=.6, position=pd) +
  geom_line(position=pd) +
  geom_point(position=pd, size=5) +
  ylab('Share of interracial marriage') +
  xlab('Occupation class') +
  theme(legend.position="none")

##Occupation if male race is coloured

test2 = ang[, .(mage, mrace, fage, frace, year, lit, decade, gap, inter, bdecade, interdum, mhisco)]
test2 = data.table(test2)
test2 = test2[,na.omit(test2)]
test2 = test2[test2$mrace == "Coloured"]
test2 = test2[test2$bdecade > 1900]
test2 = test2[test2$bdecade < 1960]
test2 = summarySE(test2, measurevar='interdum', groupvars=c('mhisco'))

ggplot(test2, aes(x=mhisco, y=interdum, colour=mhisco, group=mhisco)) + 
  geom_errorbar(aes(ymin=interdum-ci, ymax=interdum+ci), colour="black", width=.6, position=pd) +
  geom_line(position=pd) +
  geom_point(position=pd, size=5) +
  ylab('Likelihood of interracial marriage') +
  xlab('Occupation class') +
  theme(legend.position="none")

##Occupation if female race is coloured (and no black intermarriages)

test2 = ang[, .(mage, mrace, fage, frace, year, lit, decade, gap, inter, bdecade, interdum, fhisco, fhiscodum)]
test2 = data.table(test2)
test2 = test2[,na.omit(test2)]
test2 = test2[test2$frace == "Coloured"]
test2 = test2[test2$mrace != "Black"]
test2 = test2[test2$bdecade > 1900]
test2 = test2[test2$bdecade < 1960]
test2 = summarySE(test2, measurevar='interdum', groupvars=c('fhisco'))

ggplot(test2, aes(x=fhisco, y=interdum, group=fhisco)) + 
  geom_errorbar(aes(ymin=interdum-ci, ymax=interdum+ci), colour="black", width=.6, position=pd) +
  geom_line(position=pd) +
  geom_point(position=pd, size=5) +
  ylab('Share of interracial marriage') +
  xlab('Occupation class') +
  theme(legend.position="none")

##Occupation if female race is coloured (and no white intermarriages)

test2 = ang[, .(mage, mrace, fage, frace, year, lit, decade, gap, inter, bdecade, interdum, fhisco, fhiscodum)]
test2 = data.table(test2)
test2 = test2[,na.omit(test2)]
test2 = test2[test2$frace == "Coloured"]
test2 = test2[test2$mrace != "White"]
test2 = test2[test2$bdecade > 1900]
test2 = test2[test2$bdecade < 1960]
test2 = summarySE(test2, measurevar='interdum', groupvars=c('fhisco'))

ggplot(test2, aes(x=fhisco, y=interdum, group=fhisco)) + 
  geom_errorbar(aes(ymin=interdum-ci, ymax=interdum+ci), colour="black", width=.6, position=pd) +
  geom_line(position=pd) +
  geom_point(position=pd, size=5) +
  ylab('Share of interracial marriage') +
  xlab('Occupation class') +
  theme(legend.position="none")

##


test3 = ang[, .(mage, mrace, fage, frace, year, lit, decade, gap, inter, bdecade)]
test3 = data.table(test3)
test3 = test3[,na.omit(test3)]
test3 = test3[test3$decade > 1900]
test3 = test3[test3$decade < 1970]
test3 = summarySE(test3, measurevar='lit', groupvars=c('decade','inter'))

ggplot(test3, aes(x=decade, y=fage, colour=inter, group=inter)) + 
  geom_errorbar(aes(ymin=fage-ci, ymax=fage+ci), colour="black", width=.6, position=pd) +
  geom_line(position=pd) +
  geom_point(position=pd, size=5) +
  ylab('Age gap at marriage')

test3 = ang[, .(mage, mrace, fage, frace, year, lit, decade, gap, inter, bdecade, doccu, moccu, mhisco)]
test3 = data.table(test3)
test3 = test3[,na.omit(test3)]
test3 = test3[test3$decade > 1900]
test3 = test3[test3$decade < 1970]
test3 = summarySE(test3, measurevar='inter', groupvars=c('decade','mhisco'))

ggplot(test3, aes(x=decade, y=inter, colour=mhisco, group=mhisco)) + 
  geom_errorbar(aes(ymin=inter-ci, ymax=inter+ci), colour="black", width=.6, position=pd) +
  geom_line(position=pd) +
  geom_point(position=pd, size=5) +
  ylab('Interracial marriages')

ggplot(parishgraph, aes(x=year, y=value, fill=variable)) +
  geom_area(position="fill", colour="black", size=.2, alpha=.4)


ggplot(parishgraph, aes(x=year, y=value, fill=variable)) +
  geom_area(colour="black", size=.2, alpha=.4) +
  geom_vline(aes(xintercept=1949), data=years,
             colour='black', linetype='dashed') +
  ylab('Number of marriages') +
  xlab('Year of marriage') +
  labs(fill='Race')

test1 = data.table(males)
test1 = test1[test1$type != 'NA']
test1 = test1[test1$gap != 'NA']
test1 = test1[test1$decade > 1900]
test1 = test1[test1$decade < 1980]

test1sum = summarySE(test1, measurevar='gap', groupvars=c('type'))

pd = position_dodge(.25)

ggplot(test1sum, aes(x=type, y=gap)) + 
  geom_errorbar(aes(ymin=gap-ci, ymax=gap+ci), colour="black", width=.2, position=pd) +
  geom_line(position=pd) +
  geom_point(position=pd, size=5) +
  ylab('Age gap at marriage') +
  xlab('Marriage type')

test2 = data.table(males)
test2 = test2[test2$type != 'wb']
test2 = test2[test2$type != 'cb']
test2 = test2[test2$type != 'NA']
test2 = test2[test2$gap != 'NA']
test2 = test2[test2$decade > 1910]
test2 = test2[test2$decade < 1970]

test2sum = summarySE(test2, measurevar='flit', groupvars=c('type'))

pd = position_dodge(.25)

ggplot(test2sum, aes(x=type, y=flit)) + 
  geom_errorbar(aes(ymin=flit-ci, ymax=flit+ci), colour="black", width=.2, position=pd) +
  geom_line(position=pd) +
  geom_point(position=pd, size=5) +
  ylab('Female literacy') +
  xlab('Marriage type')


#Regressions

angreg = ang[, .(interdum = ang$interdum, mrace = ang$mrace, frace = ang$frace, mage = ang$mage, fage = ang$fage, act = ang$act, inequality = ang$inequality, mhiscodum = ang$mhiscodum, 
                 monthnumber = ang$monthnumber, year = ang$year, parishdum = ang$parishdum, mlit = ang$mlit, flit = ang$flit, 
                 dlit = ang$dlit, lit = ang$lit, agedif = ang$mage - ang$fage, mcountrydum = ang$mcountrydum, 
                 election = ang$election, fcountrydum = ang$fcountrydum)]
angreg = angreg[year > 1910 & year < 1961]

angreg = cbind(angreg, dummy(angreg$year, sep = "_"))

angreg$mrace = factor(angreg$mrace, levels = c("Coloured", "White", "Black"))
angreg$frace = factor(angreg$frace, levels = c("Coloured", "White", "Black"))


model1 = glm(interdum ~ mrace + frace, family = binomial (link='logit'), data = angreg)
model2 = glm(interdum ~ mrace + frace + mage + fage + act, family = binomial (link='logit'), data = angreg)
model3 = glm(interdum ~ mrace + frace + mage + fage + act + inequality + lit + fcountrydum + year + monthnumber + parishdum, family = binomial (link='logit'), data = angreg)
model4 = glm(interdum ~ mrace + frace + agedif + act + inequality + lit + fcountrydum + monthnumber + parishdum + angreg_1911:angreg_1960, family = binomial (link='logit'), data = angreg)
model4 = glm(interdum ~ .-mhiscodum, family = binomial (link='logit'), data = angreg)
model5 = lm(interdum ~ mrace + frace + mage + fage + act + inequality + monthnumber + year + parishdum, data = angreg)

summary(model4)

stargazer(model2, model3, model4, model5, title="Interracial marriages in Cape Town, 1910-1960",
          align=TRUE, dep.var.labels=c("Interracial dummy"),
         omit.stat=c("LL","ser","f"), no.space=TRUE)


#New regressions


angreg = ang[, .(interdum = ang$interdum, inter = ang$inter, mrace = ang$mrace, frace = ang$frace, mage = ang$mage, fage = ang$fage, act = ang$act, inequality = ang$inequality, 
                 monthnumber = ang$monthnumber, year = ang$year, parishdum = ang$parishdum, mcon = ang$mcon, fcon = ang$fcon, mlab = ang$mlab, fdom = ang$fdom,
                 dlit = ang$dlit, agedif = ang$mage - ang$fage, mcountrydum = ang$mcountrydum, fcountrydum = ang$fcountrydum,
                 election = ang$election, sex = ang$sex, mlit = ang$mlit, flit = ang$flit, lit = ang$lit, 
                 mhisco = ang$mhisco, fhisco = ang$fhisco, doccu = ang$doccu, intertype = ang$type, mhiscodum = ang$mhiscodum, fhiscodum = ang$fhiscodum)]
angreg = angreg[year > 1910 & year < 1965]

angreg = cbind(angreg, dummy(angreg$year, sep = "_"))

angreg$mrace = factor(angreg$mrace, levels = c("Coloured", "White", "Black"))
angreg$frace = factor(angreg$frace, levels = c("Coloured", "White", "Black"))


model1 = glm(interdum ~ mrace + frace + mage + fage + act + inequality + dlit + mcon + fcon + monthnumber + parishdum, family = binomial (link='logit'), data = angreg)
model2 = glm(interdum ~ mrace + frace + mage + fage + act + inequality + dlit + mcon + fcon + monthnumber + parishdum + 
               angreg_1911 + angreg_1912 + angreg_1913 + angreg_1914 + angreg_1915 + angreg_1916 + angreg_1917 + angreg_1918 +
               angreg_1919 + angreg_1920 + angreg_1921 + angreg_1922 + angreg_1923 + angreg_1924 + angreg_1925 + angreg_1926 +
               angreg_1927 + angreg_1928 + angreg_1929 + angreg_1930 + angreg_1931 + angreg_1932 + angreg_1933 + angreg_1934 +
               angreg_1935 + angreg_1936 + angreg_1937 + angreg_1938 + angreg_1939 + angreg_1940 + angreg_1941 + angreg_1942 +
               angreg_1943 + angreg_1944 + angreg_1945 + angreg_1946 + angreg_1947 + angreg_1948 + angreg_1949 + angreg_1950 +
               angreg_1951 + angreg_1952 + angreg_1953 + angreg_1954 + angreg_1955 + angreg_1956 + angreg_1957 + angreg_1958 +
               angreg_1959 + angreg_1961 + angreg_1962 + angreg_1963 + angreg_1964, family = binomial (link='logit'), data = angreg)
model3 = glm(interdum ~ mrace + frace + mage + fage + act + sex + inequality + dlit + mcon + fcon + mcountrydum + fcountrydum + monthnumber + parishdum + 
               angreg_1921 + angreg_1922 + angreg_1923 + angreg_1924 + angreg_1925 + angreg_1926 +
               angreg_1927 + angreg_1928 + angreg_1929 + angreg_1930 + angreg_1931 + angreg_1932 + angreg_1933 + angreg_1934 +
               angreg_1935 + angreg_1936 + angreg_1937 + angreg_1938 + angreg_1939 + angreg_1940 + angreg_1941 + angreg_1942 +
               angreg_1943 + angreg_1944 + angreg_1945 + angreg_1946 + angreg_1947 + angreg_1948 + angreg_1949 + angreg_1950 +
               angreg_1951 + angreg_1952 + angreg_1953 + angreg_1954 + angreg_1955 + angreg_1956 + angreg_1957 + angreg_1958 +
               angreg_1959, family = binomial (link='logit'), data = angreg)
model4 = lm(interdum ~ mrace + frace + mage + fage + act + sex + inequality + dlit + mcon + fcon + mcountrydum + fcountrydum + monthnumber + parishdum + 
              angreg_1921 + angreg_1922 + angreg_1923 + angreg_1924 + angreg_1925 + angreg_1926 +
              angreg_1927 + angreg_1928 + angreg_1929 + angreg_1930 + angreg_1931 + angreg_1932 + angreg_1933 + angreg_1934 +
              angreg_1935 + angreg_1936 + angreg_1937 + angreg_1938 + angreg_1939 + angreg_1940 + angreg_1941 + angreg_1942 +
              angreg_1943 + angreg_1944 + angreg_1945 + angreg_1946 + angreg_1947 + angreg_1948 + angreg_1949 + angreg_1950 +
              angreg_1951 + angreg_1952 + angreg_1953 + angreg_1954 + angreg_1955 + angreg_1956 + angreg_1957 + angreg_1958 +
              angreg_1959, data = angreg)

summary(model2)

stargazer(model1, model2, model3, model4, title="Interracial marriages in Cape Town, 1910-1960",
          align=TRUE, dep.var.labels=c("Interracial dummy"),
          omit.stat=c("LL","ser","f"), no.space=TRUE)

#Final regressions

model5 = glm(interdum ~ mrace + frace + mage + fage + act + inequality + dlit, family = binomial (link='logit'), data = angreg)
model6 = lm(interdum ~ mrace + frace + mage + fage + act + inequality + dlit + mcon + fcon + monthnumber + parishdum + year, data = angreg)
model7 = lm(interdum ~ mrace + frace + mage + fage + act + sex + inequality + dlit + mcon + fcon + mcountrydum + fcountrydum + monthnumber + parishdum + year, data = angreg)
model8 = lm(interdum ~ mrace + frace + mage + fage + act + sex + inequality + dlit + mcon + fcon + mcountrydum + fcountrydum + I(mhisco == 1) + I(mhisco == 2) + + I(fhisco == 1) + I(fhisco == 2) + monthnumber + parishdum + year, data = angreg)

summary(model5)

stargazer(model5, model6, model7, model8, title="Interracial marriages in Cape Town, 1910-1960",
          align=TRUE, dep.var.labels=c("Interracial dummy"),
          omit.stat=c("LL","ser","f"), no.space=TRUE)

wc = angreg[angreg$intertype=="wc" | angreg$intertype=="ww"]
bc = angreg[angreg$intertype=="bc" | angreg$intertype=="bb"]
model9 = lm(interdum ~ mage + fage + act + sex + inequality + dlit + mcon + fcon + monthnumber + parishdum + year, data = wc)
model10 = lm(interdum ~ mage + fage + act + sex + inequality + dlit + mcon + fcon + monthnumber + parishdum + year, data = bc)

summary(model9)

##Some descriptives
library(dplyr)  # [S2 PATCH 3] %>%/group_by/summarise need dplyr; never attached in script (tidyverse commented out at line 5)

with(angreg, table(mrace))
with(angreg, table(inter, year))
with(angreg, table(intertype))
prop.table(with(angreg, table(mlab, mrace)), margin =2)

white = angreg[mrace == 'White']
with(white, table(inter, year))

aggregate(cbind(interdum, agedif, inequality, dlit, mcon, mlab) ~ mrace, angreg, mean, na.rm=T)

descriptives = angreg %>%
  group_by(mrace) %>%
  summarise(interdum = mean(interdum, na.rm = T),
            mage = mean(mage, na.rm = T),
            fage = mean(fage, na.rm = T),
            mlit = mean(mlit, na.rm = T),
            flit = mean(flit, na.rm = T),
            sex = mean(sex, na.rm=T),
            inequality = mean(inequality, na.rm = T),
            dlit = mean(dlit, na.rm=T))

descriptivesnum = angreg %>%
  group_by(mrace) %>%
  summarise(interdum = count(interdum, na.rm = T),
            mage = count(mage, na.rm = T),
            fage = count(fage, na.rm = T),
            mlit = count(mlit, na.rm = T),
            flit = count(flit, na.rm = T),
            sex = count(sex, na.rm=T),
            inequality = count(inequality, na.rm = T),
            dlit = count(dlit, na.rm=T))

descriptivesnum = angreg %>%
  group_by(mrace) %>%
  summarise(n())


print(xtable(descriptives, type = "latex"), file = "descriptives.tex")

literacy = angreg %>%
  group_by(mrace, interdum) %>%
  summarise(mlit = mean(mlit, na.rm = T),
            flit = mean(flit, na.rm = T))

print(xtable(literacy, type = "latex"), file = "literacy.tex")

###Final graphs

ggplot(ang, aes(ang$year, fill = ang$mrace, ..count.., colour = ang$mrace)) +
  geom_density(alpha = 0.20) +
  ylab('Number of marriages') +
  xlab('Year') +
  theme(legend.title=element_blank())

angreg = angreg[angreg$inter != 'NA']
ggplot(angreg, aes(angreg$year, fill = angreg$inter, ..count.., colour = angreg$inter)) +
  geom_density(alpha = 0.40) +
  ylab('Number of marriages') +
  xlab('Year') +
  theme(legend.title=element_blank())


intermarriage = intermarriage[intermarriage$type != 'NA']
intermarriage = intermarriage[year > 1910 & year < 1966]
ggplot(intermarriage, aes(intermarriage$year, fill = intermarriage$type, ..count.., colour = intermarriage$type)) +
  geom_density(alpha = 0.15) +
  ylab('Number of marriages') +
  xlab('Year') +
  theme(legend.title=element_blank())

###

stargazer(model2, model3, model4, model5, title="Interracial marriages in Cape Town, 1910-1960",
          align=TRUE, dep.var.labels=c("Interracial dummy"),
          covariate.labels=c("ColouredMale", "WhiteMale", "ColouredFemale", "WhiteFemale", "MaleAge", "FemaleAge", "Act", "Concentration"),
          omit.stat=c("LL","ser","f"), no.space=TRUE)

ang2 = ang[frace!='Black',]
ang2 = ang2[year>1909 & year< 1951]
model4 = lm(gap ~ frace + fage + flit, data = ang2)
model5 = lm(gap ~ frace*suffrage + fage + flit + mhiscodum + fcountrydum, data = ang2)
model6 = lm(gap ~ frace*suffrage + fage + flit + mhiscodum + fcountrydum + parishdum + year, data = ang2)

stargazer(model4, model5, model6, title="Age gap in Cape Town, 1910-1960",
          align=TRUE, dep.var.labels=c("Age gap"),
          omit.stat=c("LL","ser","f"), no.space=TRUE)

model4 = lm(fage ~ frace  + flit, data = ang2)
model5 = lm(fage ~ frace*suffrage + flit + mhiscodum + fcountrydum, data = ang2)
model6 = lm(fage ~ frace*suffrage + flit + mhiscodum + fcountrydum + parishdum + year, data = ang2)

stargazer(model4, model5, model6, title="Female age in Cape Town, 1910-1960",
          align=TRUE, dep.var.labels=c("Age at marriage"),
          omit.stat=c("LL","ser","f"), no.space=TRUE)

ang2 = ang[, .(interdum = ang$interdum, mrace = ang$mrace, frace = ang$frace, mage = ang$mage, fage = ang$fage, act = ang$act, inequality = ang$inequality, mhiscodum = ang$mhiscodum, 
                 monthnumber = ang$monthnumber, year = ang$year, parishdum = ang$parishdum, mlit = ang$mlit, flit = ang$flit, suffrage = ang$suffrage,
                 dlit = ang$dlit, lit = ang$lit, agedif = ang$mage - ang$fage, mcountrydum = ang$mcountrydum, fcountrydum = ang$fcountrydum, gap = ang$mage - ang$fage)]
ang2 = ang2[frace!='Black',]
ang2 = ang2[year>1908 & year< 1964]
model4 = glm(fage ~ frace*suffrage  + dlit + lit + year + fcountrydum + monthnumber + parishdum, family = "poisson", data = ang2)
model4 = lm(gap ~ frace*suffrage  + dlit + lit + year + fcountrydum, data = ang2)
model6 = lm(fage ~ frace*suffrage + flit + mhiscodum + fcountrydum + parishdum + year, data = ang2)

summary(model4)

stargazer(model4, model5, model6, title="Female age in Cape Town, 1910-1960",
          align=TRUE, dep.var.labels=c("Age at marriage"),
          omit.stat=c("LL","ser","f"), no.space=TRUE)

###Graphs paired

##Occupation if male race is white

test1 = ang[, .(mage, mrace, fage, frace, year, lit, decade, gap, inter, interdum, mhisco)]
test1 = data.table(test1)
test1 = test1[,na.omit(test1)]
test1 = test1[test1$mrace == "White"]
test1 = test1[test1$year > 1936]
test1 = test1[test1$year < 1965]
test1 = summarySE(test1, measurevar='interdum', groupvars=c('mhisco'))

##Occupation if female race is white

test2 = ang[, .(mage, mrace, fage, frace, year, lit, decade, gap, inter, bdecade, interdum, fhisco)]
test2 = data.table(test2)
test2 = test2[,na.omit(test2)]
test2 = test2[test2$frace == "White"]
test2 = test2[test2$year > 1936]
test2 = test2[test2$year < 1965]
test2 = summarySE(test2, measurevar='interdum', groupvars=c('fhisco'))

##Occupation if male race is coloured and female race is white

test3 = ang[, .(mage, mrace, fage, frace, year, lit, decade, gap, inter, interdum, mhisco)]
test3 = data.table(test3)
test3 = test3[,na.omit(test3)]
test3 = test3[test3$mrace == "Coloured"]
test3 = test3[test3$frace != "Black"]
test3 = test3[test3$year > 1936]
test3 = test3[test3$year < 1965]
test3 = summarySE(test3, measurevar='interdum', groupvars=c('mhisco'))

##Occupation if female race is coloured (and no black intermarriages)

test4 = ang[, .(mage, mrace, fage, frace, year, lit, decade, gap, inter,  interdum, fhisco, fhiscodum)]
test4 = data.table(test4)
test4 = test4[,na.omit(test4)]
test4 = test4[test4$frace == "Coloured"]
test4 = test4[test4$mrace != "Black"]
test4 = test4[test4$year > 1936]
test4 = test4[test4$year < 1965]
test4 = summarySE(test4, measurevar='interdum', groupvars=c('fhisco'))

##Occupation if male race is coloured and female race is black

test5 = ang[, .(mage, mrace, fage, frace, year, lit, decade, gap, inter, interdum, mhisco)]
test5 = data.table(test5)
test5 = test5[,na.omit(test5)]
test5 = test5[test5$mrace == "Coloured"]
test5 = test5[test5$frace != "White"]
test5 = test5[test5$year > 1936]
test5 = test5[test5$year < 1965]
test5 = summarySE(test5, measurevar='interdum', groupvars=c('mhisco'))

##Occupation if female race is coloured (and no white intermarriages)

test6 = ang[, .(mage, mrace, fage, frace, year, lit, decade, gap, inter, interdum, fhisco, fhiscodum)]
test6 = data.table(test6)
test6 = test6[,na.omit(test6)]
test6 = test6[test6$frace == "Coloured"]
test6 = test6[test6$mrace != "White"]
test6 = test6[test6$year > 1936]
test6 = test6[test6$year < 1965]
test6 = summarySE(test6, measurevar='interdum', groupvars=c('fhisco'))

###

par(mfrow=c(3,2))

plot1 = ggplot(test1, aes(x=mhisco, y=interdum, group=mhisco)) + 
  geom_errorbar(aes(ymin=interdum-ci, ymax=interdum+ci), colour="black", width=.6, position=pd) +
  geom_line(position=pd) +
  geom_point(position=pd, size=5) +
  scale_y_continuous(limits = c(0, 0.025)) +
  scale_x_continuous(breaks = c(1, 2, 3), labels=c("Professional and managerial","Sales and service","Agriculture and production")) +
  ylab('Interracial marriage share') +
  xlab('White men (coloured interracial marriages)') +
  theme(legend.position="none")

plot2 = ggplot(test2, aes(x=fhisco, y=interdum, group=fhisco)) + 
  geom_errorbar(aes(ymin=interdum-ci, ymax=interdum+ci), colour="black", width=.6, position=pd) +
  geom_line(position=pd) +
  geom_point(position=pd, size=5) +
  scale_y_continuous(limits = c(0, 0.025)) +
  scale_x_continuous(breaks = c(1, 2, 3), labels=c("Professional and managerial","Sales and service","Agriculture and production")) +
  ylab('Interracial marriage share') +
  xlab('White women (coloured interracial marriages)') +
  theme(legend.position="none")

plot3 = ggplot(test3, aes(x=mhisco, y=interdum, group=mhisco)) + 
  geom_errorbar(aes(ymin=interdum-ci, ymax=interdum+ci), colour="black", width=.6, position=pd) +
  geom_line(position=pd) +
  geom_point(position=pd, size=5) +
  scale_y_continuous(limits = c(0, 0.025)) +
  scale_x_continuous(breaks = c(1, 2, 3), labels=c("Professional and managerial","Sales and service","Agriculture and production")) +
  ylab('Interracial marriage share') +
  xlab('Coloured men (white interracial marriages)') +
  theme(legend.position="none")

plot4 = ggplot(test4, aes(x=fhisco, y=interdum, group=fhisco)) + 
  geom_errorbar(aes(ymin=interdum-ci, ymax=interdum+ci), colour="black", width=.6, position=pd) +
  geom_line(position=pd) +
  geom_point(position=pd, size=5) +
  scale_y_continuous(limits = c(0, 0.025)) +
  scale_x_continuous(breaks = c(1, 2, 3), labels=c("Professional and managerial","Sales and service","Agriculture and production")) +
  ylab('Interracial marriage share') +
  xlab('Coloured women (white interracial marriages)') +
  theme(legend.position="none")

plot5 = ggplot(test5, aes(x=mhisco, y=interdum, group=mhisco)) + 
  geom_errorbar(aes(ymin=interdum-ci, ymax=interdum+ci), colour="black", width=.6, position=pd) +
  geom_line(position=pd) +
  geom_point(position=pd, size=5) +
  scale_y_continuous(limits = c(0, 0.025)) +
  scale_x_continuous(breaks = c(1, 2, 3), labels=c("Professional and managerial","Sales and service","Agriculture and production")) +
  ylab('Interracial marriage share') +
  xlab('Coloured men (black interracial marriages)') +
  theme(legend.position="none")

plot6 = ggplot(test6, aes(x=fhisco, y=interdum, group=fhisco)) + 
  geom_errorbar(aes(ymin=interdum-ci, ymax=interdum+ci), colour="black", width=.6, position=pd) +
  geom_line(position=pd) +
  geom_point(position=pd, size=5) +
  scale_y_continuous(limits = c(0, 0.025)) +
  scale_x_continuous(breaks = c(1, 2, 3), labels=c("Professional and managerial","Sales and service","Agriculture and production")) +
  ylab('Interracial marriage share') +
  xlab('Coloured women (black interracial marriages)') +
  theme(legend.position="none")

grid.arrange(plot1, plot2, plot3, plot4, plot5, plot6, ncol=2)