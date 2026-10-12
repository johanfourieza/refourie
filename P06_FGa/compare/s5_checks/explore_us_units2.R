suppressPackageStartupMessages({library(readxl); library(dplyr)})
source("tools/paths.R")
d <- dpath("P06_FGa","original","20 FG Comparisons","Data")
raw <- read_excel(file.path(d,"Data for Johan - Massachusetts and Virginia.xlsx"), 1, guess_max = 30000)
print(names(raw)[1:30]); print(table(raw$State))
r <- raw |> filter(State %in% c(4,10)) |> group_by(State) |>
  summarise(n=n(), across(c(Buschels_Wheat,Buschels_Barley,Buschels_Rye,Buschels_Oats,Buschels_Corn,Total_Cattle,Total_Oxen), list(nna=~sum(is.na(.x)), mean=~mean(as.numeric(.x),na.rm=TRUE), sum=~sum(as.numeric(.x),na.rm=TRUE))))
print(t(r))
