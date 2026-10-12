# S5 checks for P18_FvFS: toggles on the verified published specification (pair A')
# Data: repro_original/extracted/results/exclpc/final_excl_1.dta (read only)
suppressPackageStartupMessages({library(haven); library(fixest); library(dplyr)})
root <- "./P18_FvFS"; source("./tools/paths.R")
d <- read_dta(dpath("P18_FvFS", "repro_original/extracted/results/exclpc/final_excl_1.dta")) |> zap_labels()
d <- d |> filter(year >= 1700, year != 1716) |>
  mutate(vpc = vines_planted / hhsize,
         g = factor(group), dist = factor(district), yr = factor(year), mar = factor(marital),
         id_cl = ifelse(is.na(id) | id == "", paste0("row", row_number()), id),
         sur = toupper(trimws(surname)),
         # household totals (final_excl_1 stores knechts, cattle, horses, wheat, wine per member)
         kn_h = knechts * hhsize, ca_h = cattle * hhsize, ho_h = horses * hhsize, wr_h = wheat_reaped * hhsize,
         anywine = as.numeric(wine > 0))
lw <- function(c, how = "replace") if (how == "replace") ifelse(d$wine > 0, log(d$wine), log(c)) else log(d$wine + c)
stopifnot(max(abs(lw(0.001) - d$l_wine_zero)) < 1e-6)
d$y0 <- d$l_wine_zero
F <- "firstarrivals + i(dist, ref = 1) + i(yr)"
X3 <- "total_slaves + knechts + cattle + horses + vpc + i(mar, ref = 0)"
X3h <- "total_slaves + kn_h + ca_h + ho_h + vines_planted + i(mar, ref = 0)"
fit <- function(spec, y = "y0", w = TRUE, X = "pm", vc = "hetero", data = d, c4wheat = TRUE) {
  if (spec == "T3c4") { rhs <- paste("i(g, ref = 1) +", if (X == "pm") X3 else if (X == "vh") sub("vpc", "vines_planted", X3) else X3h,
                                     "+", if (X == "hh") "wr_h" else "wheat_reaped", "+", F); dd <- data; ref <- "g::3" }
  if (spec == "T4c7") { rhs <- paste("i(g, ref = 2) +", if (X == "pm") X3 else if (X == "vh") sub("vpc", "vines_planted", X3) else X3h, "+", F)
                        dd <- data[data$group > 1, ]; ref <- "g::3" }
  if (spec == "T4c10") { rhs <- "i(g, ref = 2)"; dd <- data[data$group > 1 & data$firstarrivals == 1, ]; ref <- "g::3" }
  if (y == "pois") {
    m <- fepois(as.formula(paste("wine ~", rhs)), dd, weights = if (w) ~hhsize else NULL, vcov = if (is.character(vc)) vc else vc)
  } else {
    dd$yy <- dd[[y]]
    m <- feols(as.formula(paste("yy ~", rhs)), dd, weights = if (w) ~hhsize else NULL, vcov = vc)
  }
  c(b = unname(coef(m)[ref]), se = unname(se(m)[ref]), N = nobs(m))
}
out <- list(); add <- function(lab, spec, ...) out[[length(out) + 1]] <<- c(variant = lab, spec = spec, round(fit(spec, ...), 4))
for (s in c("T3c4", "T4c7", "T4c10")) {
  add("0 published (aw=hhsize, HC1, per-member inputs, zeros->0.001)", s)
  add("1 unweighted", s, w = FALSE)
  add("2 iid SE (weighted)", s, vc = "iid")
  add("3 cluster id (household; missing id = own cluster)", s, vc = ~id_cl)
  add("4 cluster surname", s, vc = ~sur)
  if (s != "T4c10") {
    add("5 vines per household (other inputs per member)", s, X = "vh")
    add("6 all inputs per household (B convention)", s, X = "hh")
    add("7 unweighted + all inputs per household", s, X = "hh", w = FALSE)
  }
  for (c in c(0.01, 0.05, 0.1, 1)) { d[[paste0("yr", c)]] <- lw(c); add(paste0("8 zeros -> ", c), s, y = paste0("yr", c)) }
  d$ya <- lw(0.001, "add"); add("9 log(w + 0.001) (B convention)", s, y = "ya")
  if (s != "T4c10") add("10 B-like: unweighted, hh inputs, log(w+0.001)", s, y = "ya", X = "hh", w = FALSE)
  add("11 LPM: any wine (weighted)", s, y = "anywine")
  d$ypos <- ifelse(d$wine > 0, log(d$wine), NA); add("12 intensive margin: log wine | wine>0", s, y = "ypos")
  add("13 PPML on wine per member (weighted, HC)", s, y = "pois")
}
res <- as.data.frame(do.call(rbind, out))
res$b <- as.numeric(res$b); res$exp_b_minus1_pct <- round(100 * (exp(res$b) - 1), 1)
print(res, right = FALSE)
write.csv(res, file.path(root, "compare/s5_checks/s5_p18_toggles.csv"), row.names = FALSE)
# duplicates
dup <- d |> count(sur, name, year, wine, wheat_reaped, cattle) |> filter(n > 1)
cat("duplicate household-year groups:", nrow(dup), " surplus rows:", sum(dup$n - 1), "\n")
dd <- d |> group_by(sur, name, year, wine, wheat_reaped, cattle) |> slice(1) |> ungroup()
cat("deduplicated N:", nrow(dd), "\n")
for (s in c("T3c4", "T4c7", "T4c10")) print(c(s, round(fit(s, data = dd), 4)))
cat("n clusters id:", n_distinct(d$id_cl), " surname:", n_distinct(d$sur), " surname (Huguenot):", n_distinct(d$sur[d$group > 1]), "\n")
cat("share zero wine by group:\n"); print(tapply(d$wine == 0, d$group, mean))
