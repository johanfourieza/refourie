# S5 check C3/N1: is Combined US crop quantity = raw US bushels x constant?
suppressPackageStartupMessages({library(readxl); library(dplyr)})
source("tools/paths.R")
d <- dpath("P06_FGa","original","20 FG Comparisons","Data")
fg <- read_excel(file.path(d,"FourieGarmenApril2020.xlsx"),"Combined", guess_max=30000)
raw <- read_excel(file.path(d,"Data for Johan - Massachusetts and Virginia.xlsx"), 1, guess_max = 30000)
for (st in list(c("Massachusetts",4), c("Maine",10))) {
  a <- fg |> filter(District==st[1]); b <- raw |> filter(State==as.numeric(st[2]))
  cat(st[1], nrow(a), nrow(b), "\n")
  # aggregate by year to compare
  for (v in list(c("Wheatreaped","Buschels_Wheat"),c("Cornreaped","Buschels_Corn"),c("Ryereaped","Buschels_Rye"),c("Oatsreaped","Buschels_Oats"),c("Barleyreaped","Buschels_Barley"),c("Sheep","Total_Sheep"),c("Horses","Total_Horses"))) {
    sa <- sum(as.numeric(a[[v[1]]]), na.rm=TRUE); sb <- sum(as.numeric(b[[v[2]]]), na.rm=TRUE)
    cat(sprintf("  %-13s combined %10.1f raw %10.1f ratio %.5f\n", v[1], sa, sb, sa/sb))
  }
  ya <- a |> group_by(Year) |> summarise(n=n(), c=sum(Cornreaped,na.rm=TRUE), cat=sum(Cattle,na.rm=TRUE))
  yb <- b |> group_by(Year) |> summarise(n=n(), c=sum(as.numeric(Buschels_Corn),na.rm=TRUE), cat=sum(as.numeric(Total_Cattle)+as.numeric(Total_Oxen),na.rm=TRUE))
  print(full_join(ya,yb,by="Year",suffix=c("_comb","_raw")) |> mutate(rc=c_comb/c_raw, rcat=cat_comb/cat_raw))
}
# row-level: sorted nonzero corn values
a <- fg |> filter(District=="Massachusetts"); b <- raw |> filter(State==4)
x <- sort(as.numeric(a$Cornreaped[a$Cornreaped>0])); y <- sort(as.numeric(b$Buschels_Corn[b$Buschels_Corn>0]))
cat("nonzero corn rows", length(x), length(y), "\n"); if (length(x)==length(y)) print(summary(x/y))
print(head(cbind(x,y),10))
