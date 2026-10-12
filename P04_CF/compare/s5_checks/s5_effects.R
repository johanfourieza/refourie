# S5: assemble compare/s5_effects.csv from s5_results.csv (s5_scenarios.R) plus values read from
# compare/_scratch_s5/s5_cluster.log (s5_cluster.do), s5_census_cols.R and s5_altham_nofarm.R (typed below, cited).
# Run from P04_CF/.
suppressMessages({library(dplyr)})
source(file.path(normalizePath(".."), "tools", "paths.R"))  # [A6] data root on D:
dir.create(dpath("P04_CF", "compare", "_scratch_s5"), recursive = TRUE, showWarnings = FALSE)
r <- read.csv(dpath("P04_CF", "compare", "_scratch_s5", "s5_results.csv"), stringsAsFactors = FALSE)
get <- function(s, q) { v <- r$value[r$scenario == s & r$quantity == q]; if (length(v)) v[1] else NA }
H <- list(  # quantity label, s5_results quantity, published value
  c("Altham d(P,I)", "dpi", 19.20), c("Altham d(Q,I)", "dqi", 18.78), c("Altham d(P,Q)", "dpq", 3.70),
  c("Altham d(P,Q) G2 p-value", "ppq", NA), c("Altham di(P,Q)", "dipq", 2.39),
  c("Gold OR Model 3", "Gold OR M3", 1.303), c("Gold p Model 3", "Gold p M3", NA),
  c("Gold OR Model 3 (true share)", "Gold OR M3trueshare", NA), c("Gold p Model 3 (true share)", "Gold p M3trueshare", NA),
  c("Diamonds OR Model 3", "Diamonds OR M3", 1.009), c("Diamonds p Model 3", "Diamonds p M3", NA),
  c("Diamonds OR Model 2", "Diamonds OR M2", 1.119), c("Gold OR Model 1", "Gold OR M1", 1.297),
  c("Migrant-father OR Model 1", "migrant-father OR M1", 1.497),
  c("Origin class size OR Model 3 (as coded)", "share OR M3 (label code)", 1.033),
  c("Farmer-father OR Model 3", "farmer-father OR M3", 0.444),
  c("T9 Gold farmer->farmer (marginals adjusted)", "T9 Gold farmer->farmer (adj)", 77.7),
  c("T9 Slavery farmer->farmer", "T9 Slavery farmer->farmer", 78.1),
  c("T6 farmer share Slavery", "T6 farmer share Slavery", 64.6), c("T6 farmer share Gold", "T6 farmer share Gold", 49.7),
  c("T6 unskilled share Slavery", "T6 unskilled share Slavery", 8.3), c("N pairs", "N pairs", 9494))
scen <- c(grazier_to_farmer = "grazier coded Farmer instead of Unskilled (term always follows 'farmer'; 1,056 last-class records)",
          century_dropped = "'century' treated as non-occupation instead of White collar (419 last-class records; 158 pairs lose their only code and drop out)",
          grazier_farmer_and_century_dropped = "both recodes",
          first_listed_occupation = "first listed coded term instead of last (term lists are in fixed dictionary order, not chronological)",
          no_1910_births = "C9: drop 106 sons born in 1910 (paper says Gold = 1887-1909)",
          duplicates_dropped = "drop 159 second records of duplicated sons (identical first names, dob, dod, birthplace, occupation strings, father dob; different surname/father id)")
rows <- list()
for (s in names(scen)) for (h in H) {
  pubv <- suppressWarnings(as.numeric(h[3]))
  rows[[length(rows) + 1]] <- data.frame(scenario = s, quantity = h[1], published = pubv,
    original_code = get("published_data_2016", h[2]), scenario_value = get(s, h[2]),
    note = paste0(scen[[s]], if (s %in% c("grazier_to_farmer", "century_dropped", "grazier_farmer_and_century_dropped", "first_listed_occupation"))
      sprintf("; rebuilt-from-2017-terms baseline = %.4f", get("base_2017terms", h[2])) else ""))
}
e <- bind_rows(rows)
# C1, C3, C4 from s5_cluster.log (Stata, 2016 file, father clusters = 5,261)
man <- tribble(
  ~scenario, ~quantity, ~published, ~original_code, ~scenario_value, ~note,
  "C1_true_share", "Origin class size OR Model 3", 1.033, 1.0330, 0.9714, "share entered as decoded % instead of value-label code 1-16; p 0.014 -> 0.025 (conventional)",
  "C1_true_share", "Gold OR Model 3", 1.303, 1.3030, 1.2628, "p 0.0008 -> 0.0038 (conventional)",
  "C1_true_share", "Diamonds OR Model 3", 1.009, 1.1559, 1.0237, "p 0.075 -> 0.79",
  "C1_true_share", "Farmer-father OR Model 3", 0.444, 0.4445, 1.8248, "p <0.001 -> 0.28 (conventional)",
  "C3_relative_risk", "Gold RR Model 1 (modified Poisson)", 1.297, 1.2969, 1.1776, "table note says 'relative risks'; code reports odds ratios",
  "C3_relative_risk", "Gold RR Model 3 (modified Poisson)", 1.303, 1.3030, 1.1601, "",
  "C3_relative_risk", "Migrant-father RR Model 1", 1.497, 1.4974, 1.2608, "",
  "C4_father_cluster", "Diamonds p Model 1", NA, 0.0081, 0.0283, "father-clustered SE (5,261 clusters); star *** -> **",
  "C4_father_cluster", "Gold p Model 1", NA, 0.0005, 0.0040, "stays ***",
  "C4_father_cluster", "Gold p Model 2", NA, 0.0010, 0.0055, "stays ***",
  "C4_father_cluster", "Gold p Model 3", NA, 0.0008, 0.0048, "stays ***",
  "C4_father_cluster", "Diamonds p Model 3 (code value 1.156)", NA, 0.0745, 0.1281, "* -> none",
  "C4_father_cluster", "Origin class size p Model 3", NA, 0.0138, 0.0264, "stays **",
  "C4_father_cluster", "Migrant-father p Model 1", NA, 0.0000, 0.0001, "stays ***",
  "C4_father_cluster", "Gold p Model 3 (true share)", NA, 0.0038, 0.0153, "clustered + true share; stays **",
  "C8_altham_no_farmers", "d(P,I) excl. farmers", 13.92, NA, 12.45, "3x3 table, do-file algorithm with r=s=3 (s5_altham_nofarm.R); no original code",
  "C8_altham_no_farmers", "d(Q,I) excl. farmers", 10.57, NA, 12.21, "",
  "C8_altham_no_farmers", "d(P,Q) excl. farmers", 2.37, NA, 2.73, "G2 = 10.23, df 4, p = 0.037 (published *)",
  "C13_census_Q5", "T4 Census 1911 farmer share (white)", 47.8, 47.8, 39.5, "Q5 uses D41:44 (urban total, all races, both sexes) instead of E41:44 (European male): 236,057 -> 168,073",
  "C13_census_Q5", "T4 Census 1911 white collar share", 29.3, 29.3, 34.0, "",
  "C13_census_Q5", "T4 Census 1911 skilled share", 19.0, 19.0, 22.1, "",
  "C13_census_Q5", "T4 Census 1911 unskilled share", 3.8, 3.8, 4.4, "",
  "C13_census_Q5", "T5 non-white share of farmers", 79.4, 79.4, 84.4, "text p.9 says 80%",
  "C14_census_Q15", "T5 non-European skilled N", 84346, 84346, 353119, "Q15 uses F (European female) instead of G (non-European male) for urban rows",
  "C14_census_Q15", "T5 non-white share of skilled", 47.3, 47.3, 79.0, "")
e <- bind_rows(e, man)
write.csv(e, "compare/s5_effects.csv", row.names = FALSE)
cat("rows:", nrow(e), "\n")
