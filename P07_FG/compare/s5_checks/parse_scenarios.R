# S5 (P07_FG): parse scenario logs from build_scenarios.sh into scenario_results.csv
# Usage (project root): Rscript P07_FG/compare/s5_checks/parse_scenarios.R
suppressWarnings(suppressPackageStartupMessages({library(dplyr); library(stringr); library(tidyr)}))
ex <- readLines("P07_FG/repro_original/extract_results.R")
eval(parse(text = ex[grep("^read_log <- ", ex):grep("^find_cmd <- ", ex)]))  # reuse S2 log parsers unchanged
SCR <- "./P07_FG/compare/_scratch"
scen <- c("base", "stel2x", "keep0", "div_x2", "div_x05", "wheatonly", "t6male", "uniform", "keep5262")
dist <- c("1" = "Capedistrict", "2" = "Stellenbosch", "3" = "Drakenstein", Total = "Total")
res <- list(); add <- function(s, id, v) res[[length(res) + 1]] <<- tibble(scenario = s, claim_id = id, value = v)
for (s in scen) {
  L <- read_log(file.path(SCR, s, "run.log"))
  for (tt in list(list("T3", "*Table 2", c("slagprod", "labgprod")), list("T4", "*Table 3", c("slawprod", "labwprod")))) {
    tb <- parse_tab(L, find_cmd(L, tt[[2]]))
    for (g in names(dist)) { m <- tb[[g]]; if (is.null(m)) next
      add(s, paste0(tt[[1]], "_", dist[g], "_n"), m[2, 1]); add(s, paste0(tt[[1]], "_", dist[g], "_without"), m[1, 1]); add(s, paste0(tt[[1]], "_", dist[g], "_with"), m[1, 2]) }
  }
  tb5 <- parse_tab(L, find_cmd(L, "*Table 4"))
  for (g in names(dist)) { m <- tb5[[g]]
    add(s, paste0("T5_", dist[g], "_n"), m[2, "slagprod"])
    for (v in c("slagprod", "labgprod", "slawprod", "labwprod")) add(s, paste0("T5_", dist[g], "_", v), m[1, v])
    add(s, paste0("T5_", dist[g], "_wheat_pct"), (m[1, "labgprod"] - m[1, "slagprod"]) / m[1, "slagprod"] * 100)
    add(s, paste0("T5_", dist[g], "_wine_pct"), (m[1, "labwprod"] - m[1, "slawprod"]) / m[1, "slawprod"] * 100) }
  i5 <- find_cmd(L, "*Table 5"); t6a <- parse_tab(L, i5); t6b <- parse_tab(L, find_cmd(L, "slavemales>5, by(district)"))
  for (sz in list(list("s1to5", t6a), list("s6plus", t6b))) for (g in names(dist)) { m <- sz[[2]][[g]]
    add(s, paste0("T6_", dist[g], "_", sz[[1]], "_n_slagprod"), m[2, "slagprod"]); add(s, paste0("T6_", dist[g], "_", sz[[1]], "_n_labgprod"), m[2, "labgprod"])
    for (v in c("slagprod", "labgprod", "slawprod", "labwprod")) add(s, paste0("T6_", dist[g], "_", sz[[1]], "_", v), m[1, v]) }
  # Table 1 sums (X1 footer): all / csd / Swellendam by year
  ix <- which(grepl("tabstat cattlekhoe slaves slavemales", L, fixed = TRUE))
  ix <- ix[ix > find_cmd(L, "X1 extraction")]
  for (k in 1:3) { tb <- parse_tab(L, ix[k]); reg <- c("all", "csd", "swe")[k]
    for (y in names(tb)) { m <- tb[[y]]; add(s, paste0("T1_", y, "_", reg, "_khoesan"), m[1, 1]); add(s, paste0("T1_", y, "_", reg, "_slaves"), m[1, 2]); add(s, paste0("T1_", y, "_", reg, "_slavemales"), m[1, 3]) } }
  tbd <- parse_tab(L, ix[4]); for (dd in names(tbd)) add(s, paste0("T1_district", dd, "_khoesan"), tbd[[dd]][1, 1])
}
r <- bind_rows(res)
g <- function(s, id) r$value[r$scenario == s & r$claim_id == id]
for (s in scen) {
  k85 <- g(s, "T1_1685_all_khoesan"); k73 <- g(s, "T1_1773_all_khoesan")
  add(s, "tx_growth_all_1685_1773", 100 * ((k73 / k85)^(1 / 88) - 1))
  add(s, "tx_growth_csd_1685_1773", 100 * ((g(s, "T1_1773_csd_khoesan") / g(s, "T1_1685_csd_khoesan"))^(1 / 88) - 1))
  add(s, "tx_swe_ratio_allslaves", g(s, "T1_Total_swe_khoesan") / g(s, "T1_Total_swe_slaves"))
  add(s, "tx_swe_ratio_maleslaves", g(s, "T1_Total_swe_khoesan") / g(s, "T1_Total_swe_slavemales"))
}
r <- bind_rows(res)
write.csv(r, "P07_FG/compare/s5_checks/scenario_results.csv", row.names = FALSE)
w <- r |> pivot_wider(names_from = scenario, values_from = value)
keep <- c("T1_1685_all_khoesan","T1_1773_all_khoesan","T1_1773_csd_khoesan","T1_1773_swe_khoesan","T1_Total_all_khoesan","T1_Total_csd_khoesan","T1_Total_swe_khoesan","T1_Total_swe_slaves","T1_Total_swe_slavemales",
  "T1_district2_khoesan","tx_growth_all_1685_1773","tx_growth_csd_1685_1773","tx_swe_ratio_allslaves","tx_swe_ratio_maleslaves",
  grep("^T3_|^T4_", w$claim_id, value = TRUE), grep("^T5_(Stellenbosch|Drakenstein|Total)_", w$claim_id, value = TRUE), grep("^T6_Total_", w$claim_id, value = TRUE))
options(width = 220); print(as.data.frame(w |> filter(claim_id %in% keep) |> mutate(across(where(is.numeric), ~ round(.x, 3)))), row.names = FALSE)
