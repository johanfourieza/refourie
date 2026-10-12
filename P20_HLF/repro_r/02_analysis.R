# P20_HLF S3 recreation, step 2: social-saving arithmetic + claim table.
suppressPackageStartupMessages({library(tidyverse); library(here); library(sandwich)})
source(here("tools", "paths.R"))
set.seed(20)
source(here("P20_HLF", "repro_r", "01_clean.R"))
I <- inp; res <- list()
put <- function(id, v, se = NA, n = NA) res[[id]] <<- tibble(claim_id = id, source = "r", value = unname(v), se = unname(se), n = n, status_override = "")

# ---- Table 1: per-1000-pop columns (census file + printed km) ----
put("T1_r1_c3", I$km["Cape"] / (pop$pop1911[2] / 1000))
put("T1_r2_c3", I$km["South Africa"] / (pop$pop1911[1] / 1000))

# ---- Table 3: freight ----
a <- I$t3["a"]; b <- I$t3["b"]; d <- I$t3["d"]; e <- I$t3["e"]
c3 <- a * b; f3 <- d * e; SS <- f3 - c3
GDP <- I$ss_printed / (I$gdp_pct_printed / 100)   # implied GDP (printed SS / printed %); circular, see decisions.md
put("T3_c", c3); put("T3_f", f3); put("T3_SS", SS); put("T3_d", d); put("T3_pct", 100 * SS / GDP)
put("T4_r1_c1", 100 * SS / GDP); put("T4_r1_c2", 100 * c3 / GDP); put("T4_r1_c3", e / b)
put("TX_p10_ss", 100 * SS / GDP); put("TX_p8_rev05", 100 * c3 / GDP)

# ---- Road price: log cost function (text p.9-10, fig 5) ----
m <- lm(price ~ log(dist), data = road)
pr <- predict(m, data.frame(dist = 197), se.fit = TRUE)
X <- c(1, log(197)); se_hc3 <- sqrt(drop(t(X) %*% vcovHC(m, "HC3") %*% X))
put("TX_p10_ox", pr$fit, se = pr$se.fit, n = nrow(road))
put("TX_p10_alt1", mean(road$price), se = sd(road$price) / sqrt(nrow(road)), n = nrow(road))
dr <- road$price[road$source == "direct"]
put("TX_p10_alt2", mean(dr), se = sd(dr) / sqrt(length(dr)), n = length(dr))
put("TX_p9_pe", 29 / 240 * 22.4 / 80)   # 29d per 100 lb, long ton, 80 miles, no CPI adjustment
write_csv(tibble(pred197 = unname(pr$fit), se_conv = unname(pr$se.fit), se_hc3 = se_hc3,
                 slope = unname(coef(m)[2]), r2 = summary(m)$r.squared),
          here("P20_HLF", "repro_r", "output", "road_fit.csv"))

# ---- Table 5: passengers ----
P <- I$t5
for (k in c("1", "23")) {
  s <- if (k == "1") "1st" else "23"
  cc <- P$a[k] * P$b[k]; f <- 0.5 * P$a[k] / P$e[k]; g <- P$d[k] * f
  h <- P$a[k]; l <- 0.5 * h / P$k[k]; mm <- P$d[k] * l
  j <- if (k == "1") h * P$i1 else 0
  n <- j - cc; o <- mm - g; p <- n + o
  put(paste0("T5_c_", s), cc); put(paste0("T5_f_", s), f); put(paste0("T5_g_", s), g)
  put(paste0("T5_h_", s), h); put(paste0("T5_l_", s), l); put(paste0("T5_m_", s), mm)
  put(paste0("T5_n_", s), n); put(paste0("T5_o_", s), o); put(paste0("T5_p_", s), p)
  put(paste0("T5_q_", s), 100 * p / GDP)
  if (k == "1") { put("T5_j_1st", j); p1 <- unname(p); phi1 <- unname((j + mm) / (cc + g)) } else p23 <- unname(p)
}
pax <- p1 + p23
put("TX_p12_pax", 100 * pax / GDP); put("TX_p14_tot", SS + pax); put("TX_p14_totpct", 100 * (SS + pax) / GDP)

# ---- Table 6: elasticity adjustment (Fogel/Leunig ratio, fn 17) ----
ratio <- function(phi, eps) if (abs(eps - 1) < 1e-9) log(phi) / (phi - 1) else (phi^(1 - eps) - 1) / ((1 - eps) * (phi - 1))
phiF <- unname(e / b)
cs_lo <- ratio(phiF, I$elast["freight_hi"]) * SS      # eps = 0.8 -> low
cs_hi <- ratio(phiF, I$elast["freight_lo"]) * SS      # eps = 0.5 -> high
cs1 <- ratio(phi1, I$elast["first"]) * p1             # phi on full (fare + time) price ratio, see decisions.md
cs23 <- p23
put("T6_a_lo", cs_lo); put("T6_a_hi", cs_hi); put("T6_b", cs1); put("T6_c", cs23)
tl <- unname(cs_lo + cs1 + cs23); th <- unname(cs_hi + cs1 + cs23)
put("T6_tot_lo", tl); put("T6_tot_hi", th)
put("T6_pct_lo", 100 * tl / GDP); put("T6_pct_hi", 100 * th / GDP)
put("TX_p14_cslo", 100 * tl / GDP); put("TX_p14_cshi", 100 * th / GDP)

# ---- Table 7: supernormal profits ----
T7 <- I$t7
oc <- T7["r"] * T7["cap"]; dlo <- T7["dep_lo"] * T7["cap"]; dhi <- T7["dep_hi"] * T7["cap"]
tcl <- oc + dlo; tch <- oc + dhi
spl <- unname(T7["f"] - tcl + T7["e"]); sph <- unname(T7["f"] - tch + T7["e"])
put("T7_b", oc); put("T7_c_lo", dlo); put("T7_c_hi", dhi); put("T7_d_lo", tcl); put("T7_d_hi", tch)
put("T7_sp_lo", spl); put("T7_sp_hi", sph); put("T7_pct_lo", 100 * spl / GDP); put("T7_pct_hi", 100 * sph / GDP)
put("TX_p15_norpct", 100 * T7["f"] / T7["cap"])

# ---- Table 8: growth accounting ----
# low = low consumer surplus + high depreciation loss; high = high CS + low depreciation loss (post-hoc pairing, decisions.md)
tfp_lo <- tl + sph; tfp_hi <- th + spl
put("T8_a_lo", tfp_lo); put("T8_a_hi", tfp_hi)
put("TX_p16_dig_lo", tfp_lo); put("TX_p16_dig_hi", tfp_hi)
put("TX_p16_digp_lo", 100 * tfp_lo / GDP); put("TX_p16_digp_hi", 100 * tfp_hi / GDP)
put("TX_p17_sr_lo", 100 * tfp_lo / T7["cap"]); put("TX_p17_sr_hi", 100 * tfp_hi / T7["cap"])
c_lo <- 100 * tfp_lo / I$t8["b"]; c_hi <- 100 * tfp_hi / I$t8["b"]
fT8 <- I$t8["d"] * I$t8["e"] / 100; h8 <- 100 * fT8 / I$t8["g"]
put("T8_c_lo", c_lo); put("T8_c_hi", c_hi); put("T8_f", fT8); put("T8_h", h8)
put("T8_tot_lo", c_lo + h8); put("T8_tot_hi", c_hi + h8)
put("TX_abs_lo", c_lo + h8); put("TX_abs_hi", c_hi + h8); put("TX_p16_lp_lo", c_lo + h8); put("TX_p16_lp_hi", c_hi + h8)

# ---- assemble complete results_r.csv ----
cl <- read_csv(here("P20_HLF", "claims", "claims.csv"), show_col_types = FALSE) |> select(claim_id)
out <- cl |> left_join(bind_rows(res), by = "claim_id") |>
  mutate(source = "r", status_override = if_else(is.na(value), "unavailable", ""))
stopifnot(nrow(out) == nrow(cl))
write_csv(out, here("P20_HLF", "repro_r", "results_r.csv"))
write_csv(filter(out, !is.na(value)), here("P20_HLF", "repro_r", "output", "computed_values.csv"))
saveRDS(list(m = m, road = road, phiF = phiF, phi1 = phi1, ratio = ratio), file.path(sc, "fit.rds"))
cat(sum(!is.na(out$value)), "of", nrow(out), "claims computed\n")
