# P26_NF S6 verdicts (method card v3, §8), applied mechanically to the primary analysis only.
# Every verdict is conditional arithmetic on the published per-division cells (card §0); no CI exists (§4 C).
suppressMessages({library(tidyverse); library(here)})
source(here::here("tools", "paths.R"))
od <- here::here("P26_NF", "modern", "output")
p <- readRDS(dscratch("P26_NF", "modern", "primary.rds"))
B <- p$B; W <- p$W; Dl <- W - B
nt <- length(p$integrity) > 0 || nrow(p$D) == 0 || !p$coverage_ok   # row 0 (§4 D; |D| != 14 without reconciliation)
first <- function(conds, verdicts) { i <- which(conds)[1]; list(rule = i - 1, verdict = verdicts[i]) }
v <- list(
  `B-pt`  = first(c(nt, B <= 0, B >= 2542.5 & B <= 3107.5, B > 0 & B < 2542.5, B > 3107.5),
                  c("not-testable", "overturned (no fall)", "confirmed", "qualified (fall below the stated value)", "qualified (fall above the stated value)")),
  `B-rng` = first(c(nt, B <= 0, B >= 2800 & B <= 3000, B > 0 & B < 2800, B > 3000),
                  c("not-testable", "overturned (no fall)", "confirmed", "qualified (below the stated range)", "qualified (above the stated range)")),
  `B-lt`  = first(c(nt, B <= 0, B > 0 & B < 3000, B >= 3000),
                  c("not-testable", "overturned (no fall)", "confirmed", "qualified (threshold missed: at least a tenth of 30,000)")),
  `B-ten` = first(c(nt, B <= 0, B >= 2700 & B <= 3300, B > 0 & B < 2700, B > 3300),
                  c("not-testable", "overturned (no fall)", "confirmed", "qualified (below a tenth)", "qualified (above a tenth)")),
  `B-cmp` = first(c(nt, B <= 0, B >= 30000, B > 0 & B < 30000),
                  c("not-testable", "overturned (premise fails)", "overturned (fall as large as 30,000)", "confirmed")),
  `W-pt`  = first(c(nt, W <= 0, W >= 7140.6 & W <= 8727.4, W > 0 & W < 7140.6, W > 8727.4),
                  c("not-testable", "overturned (no fall)", "confirmed", "qualified (fall below the stated value)", "qualified (fall above the stated value)")),
  `W-cmp` = first(c(nt, W <= 0, W > 0 & B <= 0, W > 0 & B > 0 & Dl > 0, W > 0 & B > 0 & Dl < 0, W > 0 & B > 0 & Dl == 0),
                  c("not-testable", "overturned (premise fails)", "qualified (holds only because B <= 0)", "confirmed", "overturned (reversed)", "weakened (comparison not established)")))
spec <- tribble(~claim, ~headline, ~estimate, ~band,
  "B-pt", "TX_black_fall_1887", B, "2542.5 <= B <= 3107.5 (A8 point, +-10% of 2,825)",
  "B-rng", "TX_black_fall_1887", B, "2800 <= B <= 3000 (A8 threshold pair)",
  "B-lt", "TX_black_fall_1887", B, "0 < B < 3000 (A8 threshold)",
  "B-ten", "TX_black_fall_1887", B / 30000, "0.09 <= B/30000 <= 0.11, i.e. 2700 <= B <= 3300 (A8a)",
  "B-cmp", "TX_black_fall_1887", 30000 - B, "0 < B < 30000 (A8 comparative, sign only; R = 30000 - B)",
  "W-pt", "TX_white_col_fall", W, "7140.6 <= W <= 8727.4 (A8 point, +-10% of 7,934)",
  "W-cmp", "TX_white_col_fall", Dl, "W > 0, B > 0, W - B > 0 (A8 comparative, sign only; Delta = W - B)")
vt <- spec |> mutate(interval = "none (complete enumeration; A8 CI exception, card §4 C)", test_p = NA_real_,
  verdict = map_chr(claim, ~ v[[.x]]$verdict), rule = map_dbl(claim, ~ v[[.x]]$rule),
  verdict_short = word(verdict, 1))
nt_rows <- tibble(claim = c("L-B86", "L-B87", "L-W86", "L-W87", "B-causal", "W-causal"),
  headline = c("T1_Total_1886", "T1_Total_1887", "T2_Total_1886", "T2_Total_1887", "TX_black_fall_1887", "TX_white_col_fall"),
  estimate = c(7159, 4334, 35013, 27079, NA, NA), band = "none", interval = "none", test_p = NA_real_,
  verdict = "not-testable", rule = NA_real_, verdict_short = "not-testable")
s7 <- tibble(claim = "S7 proportional benchmark", headline = "extension", estimate = NA_real_, band = "none", interval = "none", test_p = NA_real_,
  verdict = "different-estimand (reported in sensitivities.csv)", rule = NA_real_, verdict_short = "different-estimand")
rank <- c(overturned = 1, weakened = 2, qualified = 3, confirmed = 4)
hl <- vt |> group_by(headline) |> summarise(
  verdict = if (any(verdict_short == "not-testable")) "not-testable" else names(rank)[min(rank[verdict_short])],
  sub_rows = paste0(claim, "=", verdict_short, collapse = "; "), .groups = "drop") |>
  bind_rows(tibble(headline = c("T1_Total_1886", "T1_Total_1887", "T2_Total_1886", "T2_Total_1887"), verdict = "not-testable", sub_rows = "level row (§4 E)"))
out <- bind_rows(vt, nt_rows, s7) |> mutate(label = "conditional arithmetic on published cells (card §0)") |>
  select(claim, headline, estimate, interval, test_p, band, verdict, rule, label)
write_csv(out, file.path(od, "verdict.csv"), na = "")
write_csv(hl, file.path(od, "verdict_headlines.csv"))
print(out |> select(claim, estimate, verdict, rule), n = 30); print(hl)
