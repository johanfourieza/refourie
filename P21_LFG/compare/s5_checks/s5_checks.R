# s5_checks.R -- P21_LFG S5 verification. No original code survives; checks the data and the S3 rebuild's choices.
suppressMessages({library(haven); library(dplyr); library(tidyr); library(readr); library(here); library(sandwich)})
source(here::here("tools", "paths.R")); set.seed(2105)
od <- here::here("P21_LFG", "compare", "s5_checks")
d0 <- read_dta(dpath("P21_LFG", "original", "Calumet Links", "processed.dta")) |> zap_labels()
cat("Tot_prod vs Tot_prodfl:\n"); print(summary(d0[, c("Tot_prod", "Tot_prodfl")]))
cat("cor:", cor(d0$Tot_prod, d0$Tot_prodfl, use = "complete.obs"), " ratio median:", median(d0$Tot_prodfl / d0$Tot_prod, na.rm = TRUE), "\n")
cat("zeros: slaves", mean(d0$slaves == 0, na.rm = TRUE), " khoe", mean(d0$khoe == 0, na.rm = TRUE), " settlers", mean(d0$settlers == 0, na.rm = TRUE), "\n")

prep <- function(d, y = "Tot_prodfl", logf = "log1p") {
  d$lq <- ifelse(d[[y]] > 0, log(d[[y]]), NA)
  if (logf == "log1p") { d$lk <- log1p(d$khoe); d$ls <- log1p(d$slaves); d$lf <- log1p(d$settlers); d$zk <- d$zs <- d$zf <- 0 }
  else { d$lk <- log(pmax(d$khoe, 1)); d$ls <- log(pmax(d$slaves, 1)); d$lf <- log(pmax(d$settlers, 1))   # Battese (1997) zero dummies
         d$zk <- 1 * (d$khoe == 0); d$zs <- 1 * (d$slaves == 0); d$zf <- 1 * (d$settlers == 0) }
  d |> filter(!is.na(lq), !is.na(lk), !is.na(ls), !is.na(lf), year >= 1805)
}
fm <- lq ~ lk + ls + lf + I(.5*lk^2) + I(.5*ls^2) + I(.5*lf^2) + I(lk*ls) + I(lk*lf) + I(ls*lf)
hec1 <- function(ev, dummies = FALSE) {
  f <- lm(if (dummies) update(fm, . ~ . + zk + zs + zf) else fm, data = ev)
  b <- coef(f); names(b)[5:10] <- c("kk","ss","ff","ks","kf","sf")
  Mk <- b["lk"] + b["kk"]*ev$lk + b["ks"]*ev$ls + b["kf"]*ev$lf
  Ms <- b["ls"] + b["ss"]*ev$ls + b["ks"]*ev$lk + b["sf"]*ev$lf
  Mf <- b["lf"] + b["ff"]*ev$lf + b["kf"]*ev$lk + b["sf"]*ev$ls
  H <- function(bij, Mi, Mj) unname((bij + Mi*Mj)/(Mi*Mj))
  V <- vcovHC(f, "HC1"); t <- b[8:10] / sqrt(diag(V)[8:10])
  list(h = tibble(FS = H(b["sf"], Ms, Mf), FK = H(b["kf"], Mk, Mf), SK = H(b["ks"], Ms, Mk)),
       aux = tibble(t_ks = t[1], t_kf = t[2], t_sf = t[3], negMs = mean(Ms <= 0), negMk = mean(Mk <= 0), negMf = mean(Mf <= 0)))
}
annual <- function(d, dummies = FALSE) bind_rows(lapply(sort(unique(d$year)), function(y) {
  r <- hec1(filter(d, year == y), dummies)
  bind_cols(tibble(year = y, n = sum(d$year == y)), summarise(r$h, across(everything(), ~median(.x[is.finite(.x)]))), r$aux) }))
heads <- function(A) tibble(F7_all_median = median(A$FS), F8_all_median = median(A$FK),
  F9_1812_1817_median = median(A$SK[A$year %in% 1811:1817]), F7_1805 = A$FS[A$year == 1805][1],
  F9_1821 = A$SK[A$year == 1821][1], F9_1823 = A$SK[A$year == 1823][1], F9_1828 = A$SK[A$year == 1828][1],
  negyrs_FS = sum(A$FS < 0), negyrs_FK = sum(A$FK < 0), negyrs_SK = sum(A$SK < 0))
ma5 <- function(A) { A <- arrange(A, year); for (v in c("FS","FK","SK")) A[[v]] <- sapply(A$year, function(y) mean(A[[v]][abs(A$year - y) <= 2])); A }

base <- prep(d0); A0 <- annual(base)
write_csv(A0, file.path(od, "annual_base_aux.csv"))
sc <- list(
  base_annual = heads(A0),
  ma5_of_annual_medians = heads(ma5(A0)),
  battese_zero_dummies = heads(annual(prep(d0, logf = "battese"), TRUE)),
  output_Tot_prod = heads(annual(prep(d0, y = "Tot_prod"))),
  owners_only = heads(annual(filter(base, slaves > 0))),
  drop_1828 = heads(filter(A0, year != 1828)))
# Mean (paper says "mean") instead of median, trimmed at 5% to tame M~0 blow-ups
Am <- bind_rows(lapply(sort(unique(base$year)), function(y) bind_cols(tibble(year = y),
  summarise(hec1(filter(base, year == y))$h, across(everything(), ~mean(.x[is.finite(.x)], trim = .05))))))
sc$trimmed_mean <- heads(Am)
S <- bind_rows(sc, .id = "scenario"); print(S, width = 200); write_csv(S, file.path(od, "scenarios.csv"))

# Bootstrap (households within year, 199 reps) for the headline medians-of-medians
B <- bind_rows(lapply(1:199, function(r) heads(annual(base |> group_by(year) |> slice_sample(prop = 1, replace = TRUE) |> ungroup()))))
ci <- B |> summarise(across(everything(), ~paste(round(quantile(.x, c(.025, .975)), 3), collapse = " to ")))
print(t(ci)); write_csv(B, dscratch("P21_LFG", "compare", "boot_heads.csv")); write_csv(as_tibble(t(ci), rownames = "stat"), file.path(od, "boot_ci.csv"))

# Descriptive gaps
cat("\n1814 sample variants:\n")
L <- d0 |> filter(!is.na(index)) |> group_by(index)
v <- c(pre_lt_post_gt_allyrs = nrow(L |> filter(any(year < 1814), any(year > 1814))),
       pre_le_post_ge = nrow(L |> filter(any(year <= 1814), any(year >= 1814), n_distinct(year) > 1)),
       pre_lt_post_gt_1805on = nrow(L |> filter(year >= 1805) |> filter(any(year < 1814), any(year > 1814))),
       in1813_and_1815 = nrow(L |> filter(any(year == 1813), any(year == 1815))),
       in1814_any = nrow(L |> filter(any(year == 1814))),
       pre_and_1814 = nrow(L |> filter(any(year < 1814), any(year == 1814))))
print(v)
cat("\nHeerden 1826 and slave max holders:\n")
print(d0 |> filter(grepl("HEERDEN", lastnamemen), year %in% 1824:1828, slaves >= 40) |> select(year, firstnamemen, lastnamemen, slaves))
print(d0 |> filter(slaves >= 55) |> select(year, firstnamemen, lastnamemen, slaves))
cat("cattle >= 2800:\n"); print(d0 |> filter(cattle >= 2700) |> select(year, firstnamemen, lastnamemen, cattle))
cat("\nQuintile variants (slaves q1/q5, khoe q1/q5):\n")
qv <- function(dd, g) dd |> mutate(q = ntile(livestock, 5)) |> filter(!is.na(q)) |> group_by(q) |>
  summarise(sl = mean(slaves, na.rm = TRUE), kh = mean(khoe, na.rm = TRUE)) |> filter(q %in% c(1, 5)) |> mutate(v = g)
print(bind_rows(qv(d0, "pooled_all"), qv(filter(d0, year >= 1805), "1805on"),
  d0 |> group_by(year) |> mutate(q = ntile(livestock, 5)) |> ungroup() |> filter(q %in% c(1, 5)) |>
    group_by(q) |> summarise(sl = mean(slaves, na.rm = TRUE), kh = mean(khoe, na.rm = TRUE)) |> mutate(v = "within_year"),
  qv(filter(d0, !is.na(khoe)), "khoe_years")))
