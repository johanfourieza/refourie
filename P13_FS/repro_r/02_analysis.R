# P13_FS S3 recreation: 02_analysis.R -- writes results_r.csv covering every claim_id in claims.csv
suppressMessages({library(dplyr); library(readr); library(sandwich); library(lmtest); library(AER)})
source(here::here("tools", "paths.R"))
scr <- dscratch("P13_FS", "repro_r")
a <- readRDS(file.path(scr, "inv.rds")); p <- readRDS(file.path(scr, "purpose.rds"))
cl <- read_csv(here::here("P13_FS", "claims", "claims.csv"), col_types = cols(.default = "c"), show_col_types = FALSE)
outdir <- here::here("P13_FS", "repro_r")
R <- list()   # claim_id -> c(value, se, n)
put <- function(id, v, se = NA, n = NA) R[[id]] <<- c(v, se, n)
smp <- list(full = rep(TRUE, nrow(a)), matched = a$match == 1, unmatched = a$match == 2)

# ---- Tables 1a/1b ----
vars <- list(land_value = "prop_value", land_size = "size_prop", slaves = "num_slaves", cash = "cash1",
             credit = "credit_value", debt = "debt_value", ncredit = "ncredit", ndebt = "ndebt")
for (s in names(smp)) {
  d <- a[smp[[s]], ]
  for (tb in c("T1a", "T1b")) {
    ex <- tb == "T1a"; pre <- paste0(tb, "_", s, "_")
    put(paste0(pre, "inv_obs"), nrow(d))
    put(paste0(pre, "land_present_obs"), if (ex) sum(d$prop == 1) else nrow(d))
    put(paste0(pre, "land_present_mean"), mean(d$prop)); put(paste0(pre, "land_present_min"), min(d$prop)); put(paste0(pre, "land_present_max"), max(d$prop))
    put(paste0(pre, "both_obs"), nrow(d)); put(paste0(pre, "both_mean"), mean(d$both))
    put(paste0(pre, "both_min"), min(d$both)); put(paste0(pre, "both_max"), max(d$both))
    for (k in names(vars)) {
      x <- d[[vars[[k]]]]; x <- x[!is.na(x)]
      if (ex) x <- x[x > 0]
      nobs <- if (k %in% c("ncredit", "ndebt")) sum(d[[vars[[k]]]]) else length(x)   # paper's obs = transactions (decisions.md)
      put(paste0(pre, k, "_obs"), nobs); put(paste0(pre, k, "_mean"), mean(x)); put(paste0(pre, k, "_median"), median(x))
      put(paste0(pre, k, "_min"), min(x)); put(paste0(pre, k, "_max"), max(x))
    }
  }
}
# ---- Table 2 ----
grp <- cut(a$num_slaves, c(-1, 0, 5, 10, 24, Inf), labels = FALSE)
for (s in names(smp)) {
  g <- grp[smp[[s]]]; n <- length(g)
  for (r in 1:5) { put(sprintf("T2_r%d_%s_obs", r, s), sum(g == r)); put(sprintf("T2_r%d_%s_pct", r, s), 100 * mean(g == r)) }
  put(sprintf("T2_r6_%s_obs", s), n); put(sprintf("T2_r6_%s_pct", s), 100)
}
# ---- Table 3 (probates only; opgaafrolle not available) ----
for (s in names(smp)) {
  x <- a$num_slaves[smp[[s]]]; x <- x[x > 0]; q <- quantile(x, c(.25, .5, .75), type = 2)
  nm <- function(k) paste0("T3_probates_", s, "_", k)
  put(nm("obs"), length(x)); put(nm("mean"), mean(x)); put(nm("sd"), sd(x)); put(nm("min"), min(x)); put(nm("max"), max(x))
  put(nm("p25"), q[1]); put(nm("p50"), q[2]); put(nm("p75"), q[3])
}
# ---- Table 4 (gender / institution of counterparties, transaction rows) ----
ps <- ifelse(p$match == 1, "matched", "unmatched")
for (s in names(smp)) for (side in c("lenders", "borrowers")) {
  has <- if (side == "lenders") !is.na(p$value_credits) else !is.na(p$value_debt)
  g <- if (side == "lenders") p$gender_c[has] else p$gender_d[has]
  m <- ps[has]
  if (s != "full") g <- g[m == s]
  for (r in 1:6) { put(sprintf("T4_r%d_%s_%s_freq", r, s, side), sum(g == r, na.rm = TRUE)); put(sprintf("T4_r%d_%s_%s_pct", r, s, side), 100 * mean(g == r, na.rm = TRUE)) }
}
# ---- Table 5 (debt purposes; mapping documented in decisions.md) ----
dr <- p[!is.na(p$value_debt), ]; dr$s <- ifelse(dr$match == 1, "matched", "unmatched")
pd <- dr$purpose_debt; cg <- dr$category_debt
LB <- c("Land", "Buildings/Real Estate", "Bond", "Bonds")
rows <- list(
 r1 = pd == "Child Care", r2 = pd == "Clothing and Shoes", r3 = pd == "Food", r4 = pd == "Funeral Expenses", r5 = pd == "Household Expenditure",
 r6 = pd == "Medical Expenses", r7 = pd == "Wedding Expenses", r8 = pd == "Other" & cg == "Consumption", r9 = cg == "Consumption",
 r10 = (pd %in% LB & cg == "Production") | pd %in% c("Bond", "Bonds"), r11 = pd %in% c("Bond", "Bonds"),
 r12 = pd == "Agricultural Output", r13 = pd == "Cattle", r14 = pd == "Slaves", r15 = pd == "Wages", r16 = pd == "Working Capital",
 r17 = pd == "Other" & cg == "Production", r18 = cg == "Production", r19 = pd == "Accounts", r20 = pd == "Auctions", r21 = pd == "Taxes",
 r22 = pd == "Wares", r23 = pd == "Donations", r24 = pd == "Inheritance", r25 = pd == "Other" & cg == "Mixed", r26 = cg == "Mixed",
 r27 = cg %in% c("Consumption", "Production", "Mixed"), r28 = cg == "General Purpose Given", r29 = cg %in% c("No purpose given", "."), r30 = rep(TRUE, nrow(dr)))
for (s in names(smp)) {
  ix <- if (s == "full") rep(TRUE, nrow(dr)) else dr$s == s; tot <- sum(ix); spec <- sum(ix & rows$r27)
  for (r in 1:30) {
    k <- paste0("r", r); m <- ix & rows[[k]]; base <- if (r <= 26) spec else tot
    put(sprintf("T5_%s_%s_freq", k, s), sum(m)); put(sprintf("T5_%s_%s_pct", k, s), 100 * sum(m) / base)
    put(sprintf("T5_%s_%s_mean", k, s), if (any(m)) mean(dr$value_debt[m]) else NA, NA, sum(m))
  }
}
# ---- Table 6 ----
a$spouse <- a$married; a$bonds <- a$bond; a$voc <- a$comp; a$oc <- a$wees; a$props <- a$num_prop; a$slv <- a$num_slaves
a$dec <- factor(a$decade)
a$ly_nom <- ifelse(a$debt_value > 0, log(a$debt_value), 0)
a$ly_real <- ifelse(is.na(a$debt_infl), NA, ifelse(a$debt_infl > 0, log(a$debt_infl), 0))
base <- c("age", "male", "spouse", "children", "farmer")
xA <- c(base, "slv", "props", "cash1", "bonds", "both", "voc", "church", "oc")
nm6 <- c(age = "age", male = "male", spouse = "spouse", children = "children", farmer = "farmer", slv = "slaves", props = "props",
         cash1 = "cash", bonds = "bonds", both = "both", voc = "voc", church = "church", oc = "oc", wealth = "wealth")
# wealth index: PCA of slaves, properties, cash (sheep/cattle/horses absent from file); percentile 1-100
cc0 <- complete.cases(a[, c("num_slaves", "num_prop", "cash1")])
pc <- prcomp(a[cc0, c("num_slaves", "num_prop", "cash1")], scale. = TRUE)
sc <- pc$x[, 1] * sign(cor(pc$x[, 1], a$num_slaves[cc0]))
a$wealth <- NA_real_; a$wealth[cc0] <- ceiling(100 * rank(sc, ties.method = "average") / sum(cc0))
for (per in c("nom", "real")) for (pan in c("A", "B")) {
  yv <- paste0("ly_", per); xs <- if (pan == "A") xA else c(base, "wealth", "bonds", "both", "voc", "church", "oc")
  d <- a[a$match == 1, ]
  if (per == "real") d <- d[d$year >= 1699 & d$year <= 1793, ]
  d <- d[complete.cases(d[, c(yv, xs, "decade")]), ]
  if (pan == "B") d <- d[d[[yv]] > 0, ]
  tag <- paste0("T6", pan, "_")
  cat(tag, per, "N =", nrow(d), "\n")
  if (nrow(d) < 30) next
  f <- as.formula(paste(yv, "~", paste(xs, collapse = "+"), "+ dec"))
  if (pan == "A") {
    X <- model.matrix(f, d); X <- X[, qr(X)$pivot[seq_len(qr(X)$rank)], drop = FALSE]   # drop aliased decade dummies
    yy <- d[[yv]]; sv <- function(X) { stopifnot(nrow(X) == length(yy)); survival::survreg(survival::Surv(yy, yy > 0, type = "left") ~ X - 1, dist = "gaussian") }
    m <- sv(X); m0 <- sv(X[, "(Intercept)", drop = FALSE])
    est <- coef(m); se <- sqrt(diag(m$var))[seq_along(est)]; names(se) <- names(est) <- sub("^X", "", names(est))
    put(paste0(tag, "R2_", per), 1 - as.numeric(logLik(m)) / as.numeric(logLik(m0))); put(paste0(tag, "N_", per), nrow(d))
    for (v in c(names(nm6), "(Intercept)")) if (v %in% names(est)) {
      nn <- if (v == "(Intercept)") "const" else nm6[[v]]
      put(paste0(tag, nn, "_", per, "_coef"), est[v], se[v], nrow(d)); put(paste0(tag, nn, "_", per, "_t"), est[v] / se[v], NA, nrow(d))
    }
  } else {
    m <- lm(f, data = d); ct <- coef(summary(m)); rb <- coeftest(m, vcov = vcovHC(m, "HC1"))
    put(paste0(tag, "R2_", per), summary(m)$r.squared); put(paste0(tag, "N_", per), nrow(d))
    for (v in c(names(nm6), "(Intercept)")) if (v %in% rownames(ct)) {
      nn <- if (v == "(Intercept)") "const" else nm6[[v]]
      put(paste0(tag, nn, "_", per, "_coef"), ct[v, 1], ct[v, 2], nrow(d))
    }
    write_csv(tibble(term = rownames(rb), coef = rb[, 1], se_conv = ct[, 2], se_hc1 = rb[, 2]), file.path(outdir, "output", paste0("T6B_", per, "_robust.csv")))
    put(if (per == "nom") "TX_p23_wealth_nom" else "TX_p23_wealth_real", 100 * ct["wealth", 1])
  }
}
# ---- Figure 6 and text claims ----
f6 <- function(g, key) { d <- a[g, ]; put(paste0("F6_", key, "_nodebt"), 100 * mean(d$debt_value == 0)); put(paste0("F6_", key, "_gt500"), 100 * mean(d$debt_value > 500)) }
f6(a$num_slaves == 0, "0slaves"); f6(a$num_slaves %in% 1:5, "1_5"); f6(a$num_slaves %in% 6:10, "6_10"); f6(a$num_slaves %in% 11:24, "11_24"); f6(a$num_slaves > 24, "gt24")
dm <- a$match == 1
sp <- mean(a$avg_slaveprice[a$year %in% 1790:1793], na.rm = TRUE)
put("TX_abs_ninv", nrow(a)); put("TX_abs_ncredit", sum(a$ncredit)); put("TX_abs_ndebt", sum(a$ndebt))
put("TX_p12_matched_n", sum(dm)); put("TX_p12_match_rate", 100 * mean(dm)); put("TX_p12_land_share", 100 * mean(a$prop))
put("TX_p13_land_value", mean(a$prop_value[a$prop_value > 0])); put("TX_p13_land_size", mean(a$size_prop[a$size_prop > 0]))
put("TX_p13_land_matched", 100 * mean(a$prop[dm])); put("TX_p13_land_unmatched", 100 * mean(a$prop[!dm]))
put("TX_p13_slaves_full", mean(a$num_slaves[a$num_slaves > 0])); put("TX_p13_slaves_unmatched_share", 100 * mean(a$num_slaves[!dm] > 0))
put("TX_p14_noslaves_matched", 100 * mean(a$num_slaves[dm] == 0)); put("TX_p15_credit_involve", 100 * mean(a$ncredit > 0 | a$ndebt > 0))
put("TX_p15_avg_trans", mean(a$ncredit + a$ndebt)); put("TX_p15_both", 100 * mean(a$both)); put("TX_p15_serrurier", max(a$credit_value))
put("TX_p15_slave_price", sp); put("TX_p15_slave_equiv", max(a$credit_value) / sp)
put("TX_p16_eksteen", max(a$debt_value[dm])); put("TX_p16_ronnenkamp", max(a$debt_value[!dm]))
put("TX_p16_purpose_share", 100 * sum(rows$r27) / nrow(dr))
put("TX_p17_consumption", 100 * sum(rows$r9) / sum(rows$r27)); put("TX_p17_inheritance_n", sum(rows$r24)); put("TX_p17_land_n", sum(rows$r10))
put("TX_p17_land_mean", mean(dr$value_debt[rows$r10])); put("TX_p17_bond_n", sum(rows$r11)); put("TX_p17_bond_mean", mean(dr$value_debt[rows$r11]))
put("TX_p23_noslave_debt", 100 * mean(a$debt_value[a$num_slaves == 0] > 0)); put("TX_p23_rich_nodebt", 100 * mean(a$debt_value[a$num_slaves > 24] == 0))
put("TX_p23_poor_debt", max(a$debt_value[a$num_slaves == 0]))
inst <- (!is.na(p$value_debt) & p$gender_d %in% 3:5) | (!is.na(p$value_credits) & p$gender_c %in% 3:5)
put("TX_p16_institution_share", 100 * sum(inst) / (sum(!is.na(p$value_debt)) + sum(!is.na(p$value_credits))))

# ---- write results_r.csv: all claims ----
get <- function(id, i) { x <- R[[id]]; if (is.null(x)) NA_real_ else as.numeric(x[i]) }
out <- tibble(claim_id = cl$claim_id, source = "r",
              value = sapply(cl$claim_id, get, i = 1), se = sapply(cl$claim_id, get, i = 2), n = sapply(cl$claim_id, get, i = 3)) |>
  mutate(value = ifelse(is.nan(value), NA, value), status_override = ifelse(is.na(value), "unavailable", ""))
write_csv(out, file.path(outdir, "results_r.csv"), na = "")
cat("claims", nrow(out), "computed", sum(!is.na(out$value)), "\n")
