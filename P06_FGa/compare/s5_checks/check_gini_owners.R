# S5 interpretation check: enslaved-ownership and livestock Ginis, owners only (Fig. 8 definition) and
# farmers incl. zeros (Table 1 definition), by district and pooled country; original-code objects.
suppressPackageStartupMessages({library(dplyr); library(ineq)})
source("tools/paths.R")
o <- readRDS(dscratch("P06_FGa","repro_original","objects.rds"))
f <- as.data.frame(o$fg2_V) |> filter(Wheatreaped > 0 | Barleyreaped > 0 | Ryereaped > 0 | Oatsreaped > 0 | Cornreaped > 0 | Wine > 0 | Cattle > 0 | Sheep > 0) |>
  mutate(Agric = rowSums(cbind(V_Cattle, V_Sheep), na.rm = TRUE))
g <- function(x) Gini(x, corr = FALSE, na.rm = TRUE)
print(f |> filter(District != "Maine", District != "Massachusetts") |> group_by(District) |>
  summarise(n = n(), share_owner = mean(Slaves > 0, na.rm = TRUE), G_all = g(Slaves), G_owners = g(Slaves[Slaves > 0])), digits = 3)
print(f |> filter(District != "Maine", District != "Massachusetts") |> group_by(Country) |>
  summarise(G_all = g(Slaves), G_owners = g(Slaves[Slaves > 0])), digits = 3)
print(f |> group_by(Country) |> summarise(G_live = g(Agric), G_live_owners = g(Agric[Agric > 0])), digits = 3)
