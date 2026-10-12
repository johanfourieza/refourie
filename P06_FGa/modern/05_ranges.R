# 05: Assumption ranges (card §4.4; reported, not probabilities, never verdict-determining).
# H1: V1 x V2 x V3 = 18; H2: V3 x V4 = 9; H5: V3 = 3. Adds range columns to output/verdict.csv and
# writes output/ranges_scenarios.csv.
source("P06_FGa/modern/00_helpers.R")
fg <- load_raw(); cmap <- coverage_map(fg); P <- load_prices()
auc <- P$auctions
WINE <- c(final_mean = P$Final["Cape Colony", "PWine"],
          auction1 = auc$Wine[auc$Auction == "Auction1"] / XRATE,
          auction3 = auc$Wine[auc$Auction == "Auction3"] / XRATE)
cat("Wine prices ($):", round(WINE, 5), "\n")

cond <- function(est) {   # verdict condition met by a degenerate (enumerated) interval
  if (!is.finite(est)) return("failed (non-finite)")
  verdict_single(est, est, 0)$verdict
}
sc <- list()
for (v1 in c("Final", "Final2")) for (r in c(0.03, 0.06, 0.10)) for (v3 in c("A", "B", "C")) {
  e <- enum_stats(make_d(fg, cmap, P, pset = v1, r = r, v3 = v3))
  est <- log(e[["H1_cape"]] / e[["H1_us"]])
  sc[[length(sc) + 1]] <- tibble(claim = "H1", pair = "Cape/US", V1 = v1, V2 = r, V3 = v3, V4 = NA, estimate = est,
                                 condition = cond(est), central = v1 == "Final" & r == 0.06 & v3 == "A")
}
for (v3 in c("A", "B", "C")) for (w in names(WINE)) {
  e <- enum_stats(make_d(fg, cmap, P, v3 = v3, wine = WINE[[w]]))
  est <- log(e[["H2_cape"]] / e[["H2_us"]])
  sc[[length(sc) + 1]] <- tibble(claim = "H2", pair = "Cape/US", V1 = NA, V2 = NA, V3 = v3, V4 = w, estimate = est,
                                 condition = cond(est), central = v3 == "A" & w == "final_mean")
}
for (v3 in c("A", "B", "C")) {
  e <- enum_stats(make_d(fg, cmap, P, v3 = v3))
  for (k in c("GR", "Stb", "Swe", "Tul")) for (u in c("Maine", "Mass")) {
    est <- e[[paste0("G5_", k)]] - e[[paste0("G5_", u)]]
    sc[[length(sc) + 1]] <- tibble(claim = "H5", pair = paste0(k, "-", u), V1 = NA, V2 = NA, V3 = v3, V4 = NA,
                                   estimate = est, condition = cond(est), central = v3 == "A")
  }
}
sc <- bind_rows(sc)
write_csv(sc, file.path(OUT, "ranges_scenarios.csv"))

share <- function(x, lev) mean(x == lev)
summ <- function(cl) {
  s <- sc |> filter(claim == cl)
  if (cl == "H5") {
    uv <- s |> group_by(V3) |> summarise(v = verdict_universal(condition)$verdict, .groups = "drop")
    tibble(claim = cl, n_scenarios = nrow(uv),
           range_min = min(s$estimate), range_median = median(s$estimate), range_max = max(s$estimate),
           share_confirmed = share(uv$v, "confirmed"), share_overturned = mean(grepl("^overturned", uv$v)),
           share_weakened = share(uv$v, "weakened"), share_failed = 0,
           sensitivity_line = paste0("central verdict condition (universal: at least one pair overturned) holds in ",
             c("none", "some", "all")[1 + (mean(grepl("^overturned", uv$v)) > 0) + (mean(grepl("^overturned", uv$v)) == 1)],
             " of ", nrow(uv), " scenarios (assumption-conditional, equal weights, not a probability); pair range = min/median/max over 8 pairs x 3 scenarios"))
  } else {
    sh <- share(s$condition, "confirmed")
    tibble(claim = cl, n_scenarios = nrow(s),
           range_min = min(s$estimate), range_median = median(s$estimate), range_max = max(s$estimate),
           share_confirmed = sh, share_overturned = mean(grepl("^overturned", s$condition)),
           share_weakened = share(s$condition, "weakened"), share_failed = mean(grepl("failed", s$condition)),
           sensitivity_line = paste0("central verdict condition (I > 0) holds in ", c("none", "some", "all")[1 + (sh > 0) + (sh == 1)],
             " of ", nrow(s), " scenarios (assumption-conditional, equal weights, not a probability)"))
  }
}
rng <- bind_rows(lapply(c("H1", "H2", "H5"), summ))
print(as.data.frame(rng), digits = 4)
verd <- read_csv(file.path(OUT, "verdict.csv"), show_col_types = FALSE) |> select(-any_of(names(rng)[-1]))
verd <- verd |> left_join(rng, by = "claim") |>
  mutate(sensitivity_line = ifelse(is.na(sensitivity_line), "no valuation assumptions (H3/H4 involve none)", sensitivity_line))
write_csv(verd, file.path(OUT, "verdict.csv"))
print(as.data.frame(sc |> group_by(claim, V3) |> summarise(min = min(estimate), max = max(estimate), .groups = "drop")), digits = 4)
