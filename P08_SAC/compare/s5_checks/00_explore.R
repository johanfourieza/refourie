suppressMessages({library(readxl); library(dplyr)})
source("./tools/paths.R")
X <- dpath("P08_SAC","original","FourieSAC2026","SAC final.xlsx")
a <- read_excel(X, sheet="Augmented", col_types="text"); o <- read_excel(X, sheet="Original", col_types="text")
o2 <- o %>% filter(!is.na(Names) | !is.na(Surname))
for (f in c("Register","Surname","Names","Wage","Calling","IMG","Country","Age")) {
  n <- 10399; cat(f, "same-pos", round(mean(a[[f]][1:n] == o2[[f]][1:n], na.rm=TRUE),3), " a-in-o", round(mean(a[[f]] %in% o2[[f]]),3), "\n") }
k <- function(df) paste(df$Register, df$Surname, df$Names, df$IMG, sep="|")
ka <- k(a); ko <- k(o2)
cat("key dup a", sum(duplicated(ka)), "o", sum(duplicated(ko)), " match", mean(ka %in% ko), "\n")
