# S5 check: households admitted as "farmers" only through Wine > 0 (fn 45 says specialist viticulturalists are excluded)
suppressPackageStartupMessages({library(dplyr)})
source("tools/paths.R")
o <- readRDS(dscratch("P06_FGa","repro_original","objects.rds"))
f <- as.data.frame(o$fg2_V)
z <- function(x) !is.na(x) & x > 0
f <- f |> mutate(farm_code = z(Wheatreaped)|z(Barleyreaped)|z(Ryereaped)|z(Oatsreaped)|z(Cornreaped)|z(Wine)|z(Cattle)|z(Sheep),
                 farm_text = z(Wheatreaped)|z(Barleyreaped)|z(Ryereaped)|z(Oatsreaped)|z(Cornreaped)|z(Cattle)|z(Sheep))
print(f |> group_by(District) |> summarise(code = sum(farm_code), text = sum(farm_text), wine_only = code - text))
