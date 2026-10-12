# P13_FS S6 01_purpose.R -- Table 5 rows H1-cons, H1-land (point shares) and H1-main (inventory-cluster bootstrap
# of K = 21 fixed contrasts L - s_c, Bonferroni-simultaneous percentile intervals), plus sensitivities 1-12.
# Mapping copied from compare/s5_checks/s5_08_t5_mapping.R; method card sections 3, 4A, 4A-B, 5.
suppressMessages({library(haven); library(dplyr); library(readr); library(tidyr)})
source(here::here("tools", "paths.R"))
od <- dpath("P13_FS", "original", "MOOC 8"); scr <- dscratch("P13_FS", "modern"); out <- here::here("P13_FS", "modern", "output")
dir.create(out, showWarnings = FALSE)
p <- zap_labels(read_dta(file.path(od, "PURPOSEDATA_20141117.dta")))
a <- zap_labels(read_dta(file.path(od, "DATA20141122.dta"))); a <- a[!is.na(a$household_iden), ]
stopifnot(!anyDuplicated(a$mooc))                                    # rule 2: unique join key
cons_l <- c("Child Care", "Clothing and Shoes", "Food", "Funeral Expenses", "Household Expenditure", "Medical Expenses", "Wedding Expenses")
prod_l <- c("Agricultural Output", "Cattle", "Slaves", "Wages", "Working Capital")
mixd_l <- c("Accounts", "Auctions", "Taxes", "Wares", "Donations", "Inheritance")
classify <- function(d) {
  pd <- d$purpose_debt; cg <- d$category_debt
  land <- pd %in% c("Land", "Bond", "Bonds") | (pd == "Buildings/Real Estate" & cg != "General Purpose Given")
  cons <- pd %in% cons_l | (pd == "Other" & cg == "Consumption")
  prod <- land | pd %in% prod_l | (pd == "Other" & cg == "Production")
  mixd <- pd %in% mixd_l | (pd == "Other" & cg %in% c("Mixed", "."))
  comp <- case_when(land ~ "LAND", pd %in% cons_l ~ pd, pd == "Other" & cg == "Consumption" ~ "Other consumption",
                    pd %in% prod_l ~ pd, pd == "Other" & cg == "Production" ~ "Other production",
                    pd %in% mixd_l ~ pd, pd == "Other" & cg %in% c("Mixed", ".") ~ "Other mixed", TRUE ~ NA_character_)
  tibble(land, cons, prod, mixd, spec = cons | prod | mixd, comp, bond = pd %in% c("Bond", "Bonds"))
}
U <- p[!is.na(p$value_debt) | !(p$purpose_debt %in% c(".", "")), ]
U <- bind_cols(U, classify(U))
U$matched <- U$mooc %in% a$mooc
stopifnot(all(U$cons + U$land + (U$prod & !U$land) + U$mixd <= 1))  # rule 3: mutually exclusive
COMP <- c(cons_l, "Other consumption", prod_l, "Other production", mixd_l, "Other mixed")
K <- length(COMP); stopifnot(K == 21)
n_spec <- sum(U$spec)
stopifnot(sum(U$comp %in% COMP) + sum(U$land) == n_spec, all(is.na(U$comp) == !U$spec))
C <- 100 * sum(U$cons) / n_spec; L <- 100 * sum(U$land) / n_spec
chk <- tibble(item = c("U rows", "U rows unmatched to inventory file", "U moocs (clusters)", "U rows matching no category (outside n_spec)",
                       "n_spec", "cons", "land", "bonds", "inheritance", "value-missing U rows"),
              value = c(nrow(U), sum(!U$matched), n_distinct(U$mooc), sum(!U$spec), n_spec, sum(U$cons), sum(U$land), sum(U$bond),
                        sum(U$purpose_debt == "Inheritance"), sum(is.na(U$value_debt))))
# ---- verification checks: S5 counts and S3-rebuild mapping ----
dr <- p[!is.na(p$value_debt), ]; pd <- dr$purpose_debt; cg <- dr$category_debt
r9 <- cg == "Consumption"; r10 <- (pd %in% c("Land", "Buildings/Real Estate", "Bond", "Bonds") & cg == "Production") | pd %in% c("Bond", "Bonds")
r27 <- cg %in% c("Consumption", "Production", "Mixed")
ver <- tibble(check = c("cons count = 923 (published)", "land count = 1139 (published)", "inheritance count = 238 (published)",
                        "n_spec = 4122 (S5)", "C on data base = 22.39 (S5)", "L on data base = 27.63 (S5)",
                        "C on base 4418 = 20.89 (published)", "L on base 4418 = 25.78 (published)",
                        "S3 rebuild mapping C = 22.16 (S4)", "S3 rebuild mapping L = 23.35 (S4)"),
              target = c(923, 1139, 238, 4122, 22.39, 27.63, 20.89, 25.78, 22.16, 23.35),
              got = c(sum(U$cons), sum(U$land), sum(U$purpose_debt == "Inheritance"), n_spec, C, L,
                      100 * sum(U$cons) / 4418, 100 * sum(U$land) / 4418, 100 * sum(r9) / sum(r27), 100 * sum(r10) / sum(r27))) |>
  mutate(pass = abs(got - target) < ifelse(target > 100, 0.5, 0.006))
print(ver); write_csv(ver, file.path(out, "verification_H1.csv"))
# ---- point estimates and contrasts ----
s_c <- sapply(COMP, function(k) 100 * sum(U$comp %in% k) / n_spec)
pt <- tibble(competitor = COMP, n_c = sapply(COMP, function(k) sum(U$comp %in% k)), s_c = s_c, delta = L - s_c)
# ---- cluster bootstrap on a cluster-by-category count matrix ----
cnt <- function(d, g) {
  M <- tibble(g = g, LAND = d$land, cons = d$cons, prod = d$prod, spec = d$spec, bond = d$bond, landnb = d$land & !d$bond)
  for (k in COMP) M[[k]] <- d$comp %in% k
  M <- M |> mutate(across(-g, as.numeric)) |> group_by(g) |> summarise(across(everything(), sum), .groups = "drop")
  as.matrix(M[, -1])
}
boot_counts <- function(M, B, seed, chunk = 5000) {
  RNGkind("L'Ecuyer-CMRG"); set.seed(seed); G <- nrow(M); res <- list(); done <- 0
  while (done < B) {
    b <- min(chunk, B - done)
    W <- matrix(0, b, G); for (r in seq_len(b)) W[r, ] <- tabulate(sample.int(G, G, replace = TRUE), G)
    res[[length(res) + 1]] <- W %*% M; done <- done + b
  }
  do.call(rbind, res)
}
B <- 49999; a_tail <- 0.0125 / K
summ <- function(S, lab) {
  ns <- S[, "spec"]; undef <- sum(ns == 0); S <- S[ns > 0, , drop = FALSE]; ns <- ns[ns > 0]
  Lb <- 100 * S[, "LAND"] / ns
  D <- sapply(COMP, function(k) Lb - 100 * S[, k] / ns)
  list(undef = undef, Beff = nrow(S), Lb = Lb, D = D, ns = ns, S = S,
       ci = tibble(design = lab, competitor = COMP, lo = apply(D, 2, quantile, a_tail, type = 7), hi = apply(D, 2, quantile, 1 - a_tail, type = 7)))
}
Minv <- cnt(U, U$mooc); stopifnot(sum(Minv[, "spec"]) == n_spec)
t0 <- Sys.time(); Sinv <- boot_counts(Minv, B, 20261012); cat("bootstrap secs", round(as.numeric(Sys.time() - t0, units = "secs")), "\n")
bi <- summ(Sinv, "inventory (primary)")
prim <- left_join(pt, bi$ci, by = "competitor") |> mutate(lo_gt0 = lo > 0, hi_lt0 = hi < 0)
rpi <- U |> group_by(mooc) |> summarise(rows = n(), spec = sum(spec))
clus <- tibble(stat = c("inventories resampled", paste0("debt rows/inv q", c(0, 25, 50, 75, 100)), paste0("purpose rows/inv q", c(0, 25, 50, 75, 100)), "undefined draws", "B_eff"),
               value = c(nrow(rpi), quantile(rpi$rows, c(0, .25, .5, .75, 1)), quantile(rpi$spec, c(0, .25, .5, .75, 1)), bi$undef, bi$Beff))
v_main <- if (bi$undef > 2 || K != 21) "not-testable" else if (any(prim$hi < 0)) "overturned" else if (all(prim$lo > 0)) "confirmed" else "weakened"
rule_main <- c("not-testable" = 0, overturned = 1, confirmed = 2, weakened = 3)[[v_main]]
# ---- sensitivities 1-12 (reported, never voting) ----
S <- list(); add <- function(no, what, est, lo = NA, hi = NA, note = "") S[[length(S) + 1]] <<- tibble(sens = no, what, est, lo = unname(lo), hi = unname(hi), note)
q1 <- function(x) quantile(x, a_tail, type = 7); q2 <- function(x) quantile(x, 1 - a_tail, type = 7)
add(1, "C on published base 4418", 100 * sum(U$cons) / 4418, note = "diagnostic; reproduces by construction"); add(1, "L on published base 4418", 100 * sum(U$land) / 4418)
L2 <- 100 * sum(U$land & !U$bond) / n_spec                         # 2: bonds left in Mixed (n_spec unchanged)
add(2, "L, bonds in Mixed", L2); add(2, "C, bonds in Mixed", C, note = "unchanged")
Ln <- 100 * bi$S[, "landnb"] / bi$ns
for (k in COMP) { d2 <- Ln - 100 * bi$S[, k] / bi$ns; add(2, paste("Delta (bonds in Mixed) vs", k), L2 - s_c[[k]], q1(d2), q2(d2)) }
d2 <- Ln - 100 * bi$S[, "bond"] / bi$ns
add(2, "Delta (bonds in Mixed) vs Bond/Bonds as own mixed row", L2 - 100 * sum(U$bond) / n_spec, q1(d2), q2(d2), note = "bond rows exceed land if listed separately")
add(2, "min Delta over 21 competitors, bonds in Mixed", min(L2 - s_c), note = paste("argmax", names(which.max(s_c))))
V <- U[!is.na(U$value_debt), ]; nv <- sum(V$spec)                   # 3: rows with a value
add(3, "C, valued rows", 100 * sum(V$cons) / nv); add(3, "L, valued rows", 100 * sum(V$land) / nv)
add(3, "min Delta, valued rows", min(sapply(COMP, function(k) 100 * (sum(V$land) - sum(V$comp %in% k)) / nv)))
add(4, "C, S3 rebuild mapping", 100 * sum(r9) / sum(r27)); add(4, "L, S3 rebuild mapping", 100 * sum(r10) / sum(r27))
vs <- sum(V$value_debt[V$spec]); vc <- sapply(COMP, function(k) 100 * sum(V$value_debt[V$comp %in% k]) / vs)   # 5
add(5, "C value-weighted", 100 * sum(V$value_debt[V$cons]) / vs, note = "different-estimand"); add(5, "L value-weighted", 100 * sum(V$value_debt[V$land]) / vs)
add(5, "max competitor value share", max(vc), note = paste("argmax", names(which.max(vc))))
add(6, "C, base = all U rows", 100 * sum(U$cons) / nrow(U), note = "different-estimand"); add(6, "L, base = all U rows", 100 * sum(U$land) / nrow(U))
add(6, "share of U rows purpose-recorded", 100 * n_spec / nrow(U))
for (mm in c(TRUE, FALSE)) { d <- U[U$matched == mm, ]; ns <- sum(d$spec); lab <- if (mm) "matched" else "unmatched"
  add(7, paste("C,", lab), 100 * sum(d$cons) / ns, note = paste("n_spec", ns)); add(7, paste("L,", lab), 100 * sum(d$land) / ns)
  add(7, paste("min Delta,", lab), min(sapply(COMP, function(k) 100 * (sum(d$land) - sum(d$comp %in% k)) / ns))) }
oth <- c("Other consumption", "Other production", "Other mixed"); n8 <- n_spec - sum(U$comp %in% oth)
add(8, "C, Other rows dropped", 100 * sum(U$cons & !U$comp %in% oth) / n8); add(8, "L, Other rows dropped", 100 * sum(U$land) / n8)
add(8, "min Delta, Other rows dropped", min(sapply(setdiff(COMP, oth), function(k) 100 * (sum(U$land) - sum(U$comp %in% k)) / n8)))
add(9, "L - 50 (majority reading)", L - 50, quantile(bi$Lb - 50, 0.0125), quantile(bi$Lb - 50, 0.9875))
pc <- 100 * (bi$S[, "prod"] - bi$S[, "cons"]) / bi$ns
add(10, "production minus consumption share", 100 * (sum(U$prod) - sum(U$cons)) / n_spec, quantile(pc, 0.0125), quantile(pc, 0.9875))
dmin <- bi$Lb - apply(sapply(COMP, function(k) 100 * bi$S[, k] / bi$ns), 1, max)
add(11, "Dmin = L - max_c s_c (v1, diagnostic)", L - max(s_c), quantile(dmin, 0.0125), quantile(dmin, 0.9875), note = paste("argmax", names(which.max(s_c))))
add(12, "household_iden clusters (count)", n_distinct(a$household_iden), note = "household_iden unique per inventory: identical to primary")
U$dec <- floor(U$year / 10) * 10; U$dec[is.na(U$dec)] <- -1
Mdec <- cnt(U, U$dec); Sdec <- boot_counts(Mdec, B, 20261012); bd <- summ(Sdec, "decade block")
add(12, "decade blocks (count)", nrow(Mdec), note = paste("purpose rows per block min/med/max", paste(quantile(Mdec[, "spec"], c(0, .5, 1)), collapse = "/")))
for (k in COMP) add(12, paste("Delta, decade-block CI vs", k), L - s_c[[k]], bd$ci$lo[bd$ci$competitor == k], bd$ci$hi[bd$ci$competitor == k])
add(12, "decade-block: n contrasts lo<=0", sum(bd$ci$lo <= 0), note = paste("undefined draws", bd$undef))
sens <- bind_rows(S)
write_csv(chk, file.path(out, "H1_counts.csv")); write_csv(clus, file.path(out, "H1_clusters.csv"))
write_csv(prim, file.path(out, "H1_main_contrasts.csv")); write_csv(sens, file.path(out, "sensitivities_H1.csv"))
saveRDS(list(C = C, L = L, n_spec = n_spec, prim = prim, v_main = v_main, rule_main = rule_main, undef = bi$undef,
             argmax = names(which.max(s_c)), ver = ver), file.path(scr, "h1.rds"))
print(chk); print(prim, n = 21); print(clus); cat("H1-main:", v_main, "\n"); print(as.data.frame(sens), digits = 4)
