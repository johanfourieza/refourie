# 01: K3 structural-missingness map and K5 coverage (written before any estimate), plus the
# Virginia county inspection required by card §4.3.
source("P06_FGa/modern/00_helpers.R")
fg <- load_raw()
cmap <- coverage_map(fg)
cmap <- cmap |> mutate(card_note = ifelse(District == "Virginia" & variable %in% GRAINS,
  "card K5/C7: Virginia grain treated as structurally missing (mechanical K3 status shown)", ""))
write_csv(cmap, file.path(OUT, "coverage.csv"))
cat("Structurally missing cells:\n"); print(as.data.frame(cmap |> filter(status != "recorded") |> select(District, Year, variable, na_share)))
cat("Intermediate NA shares (0 < share < 1):\n"); print(as.data.frame(cmap |> filter(na_share > 0, na_share < 1)))

# --- Virginia county identification: Source / Veldcornet / Sourcenumber
va <- fg |> filter(District == "Virginia")
cat("Virginia rows:", nrow(va), "| distinct Source:", n_distinct(va$Source), "Veldcornet:", n_distinct(va$Veldcornet),
    "Sourcenumber:", n_distinct(va$Sourcenumber), "\n")
# Cross-check Veldcornet against the raw US tax-list file's County field (State code 3 = Virginia)
raw <- read_excel(file.path(ORIG, "Data", "Data for Johan - Massachusetts and Virginia.xlsx"), 1, guess_max = 50000)
rv <- raw |> filter(State == 3)
same_order <- nrow(rv) == nrow(va) && all(as.character(rv$County) == as.character(va$Veldcornet)) &&
  all(rv$Year == va$Year) && mean(rv$Last_Name == va$Husband, na.rm = TRUE)
cat("Raw Virginia rows:", nrow(rv), "| row-by-row County == Veldcornet and Year equal:",
    all(as.character(rv$County) == as.character(va$Veldcornet)) && all(rv$Year == va$Year),
    "| surname match share:", round(mean(rv$Last_Name == va$Husband, na.rm = TRUE), 4), "\n")
d <- prep(fg, cmap)
d$farm <- farmer(d)
vs <- d |> filter(District == "Virginia") |> group_by(County, Year, Bench) |>
  summarise(n_households = n(), covered_H3 = sum(cov_cattle), covered_H4 = sum(cov_slaves),
            farmers_covered = sum(farm & cov_slaves), .groups = "drop") |> arrange(Year, County)
write_csv(vs, file.path(OUT, "va_strata.csv"))
cat("Virginia counties:", n_distinct(vs$County), "| county-year strata:", nrow(vs),
    "| strata with < 2 covered households:", sum(vs$covered_H4 < 2), "\n")
print(as.data.frame(vs))
cov <- tibble(
  item = c("va_sampled_households", "va_households_in_covered_cells_H3", "va_households_in_covered_cells_H4",
           "va_coverage_share_H3", "va_coverage_share_H4", "va_covered_farmers_H3", "va_covered_farmers_H4",
           "cape_households_uncovered_H1H2H5", "cape_households_total"),
  value = c(nrow(va), sum(d$cov_cattle[d$District == "Virginia"]), sum(d$cov_slaves[d$District == "Virginia"]),
            mean(d$cov_cattle[d$District == "Virginia"]), mean(d$cov_slaves[d$District == "Virginia"]),
            sum(d$farm & d$cov_cattle & d$District == "Virginia"), sum(d$farm & d$cov_slaves & d$District == "Virginia"),
            sum(d$is_cape & !d$cov_crop), sum(d$is_cape)))
write_csv(cov, file.path(OUT, "coverage_summary.csv"))
print(cov)
print(as.data.frame(d |> filter(is_cape) |> group_by(District, Year) |> summarise(n = n(), covered_H1 = sum(cov_crop & cov_live), farmers = sum(farm), farmers_covered_H1 = sum(farm & cov_crop & cov_live), .groups = "drop")))
