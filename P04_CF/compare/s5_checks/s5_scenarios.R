# S5: verification of C7/T9, C9, duplicates, and coding scenarios (grazier, century) through the original pipeline.
# Original pipeline = do-file l.14-157 logic (last listed coded term; first = position 1), Altham code l.207-251 and
# l.309-365 (re-implemented: anova RSS * 4rs, Poisson G2), logit Model 3 l.406 (share entered as value-label code).
# Run from P04_CF/. Output: compare/_scratch_s5/s5_results.csv (aggregates only).
suppressMessages({library(haven); library(dplyr); library(tidyr)})
source(file.path(normalizePath(".."), "tools", "paths.R"))  # [A6] data root on D:
dir.create(dpath("P04_CF", "compare", "_scratch_s5"), recursive = TRUE, showWarnings = FALSE)
a <- read_dta(dpath("P04_CF", "original", "CF Mobility", "Data", "CF_mobility_replication_data_anonymized.dta")) |> zap_labels()
b <- read_dta(dpath("P04_CF", "original", "CF Mobility", "Data", "SAF mobility data_10.08.2017.dta")) |> zap_labels()
cl <- read_dta(dpath("P04_CF", "compare", "_scratch_s5", "clusters.dta"))
lk <- readRDS(dpath("P04_CF", "compare", "_scratch_s5", "link.rds"))
map <- read.csv(dpath("P04_CF", "compare", "_scratch_s5", "termmap.csv"), stringsAsFactors = FALSE)
claims <- read.csv("claims/claims.csv", stringsAsFactors = FALSE)
pub <- function(id) claims$reported_value[claims$claim_id == id]
out <- list()
add <- function(scen, q, val, note = "") out[[length(out) + 1]] <<- data.frame(scenario = scen, quantity = q, value = val, note = note)

## ---- Altham (do-file algorithm) ----
altham <- function(P, Q) {  # P,Q: 4x4 count matrices, rows = father, cols = son
  F <- factor(rep(1:4, 4)); S <- factor(rep(1:4, each = 4)); p <- as.vector(P); q <- as.vector(Q)
  rs <- 4 * 4 * 4
  d <- function(y) sqrt(sum(resid(lm(y ~ F + S))^2) * rs)
  dpi <- d(log(p)); dqi <- d(log(q)); dpq <- d(log(p / q))
  T <- factor(rep(1:2, each = 16)); FF <- factor(rep(F, 2)); SS <- factor(rep(S, 2))
  mpq <- glm(c(p, q) ~ (SS + FF + T)^2, family = poisson)
  ind <- factor(ifelse(as.integer(F) == as.integer(S), as.integer(F), 5))
  dipq <- sqrt(sum(resid(lm(log(p / q) ~ F + S + ind))^2) * rs)
  II <- factor(rep(ind, 2))
  mi <- glm(c(p, q) ~ SS * FF + SS * T + FF * T + II * SS + II * FF + II * T, family = poisson)
  c(dpi = dpi, dqi = dqi, dpq = dpq, g2pq = mpq$deviance, dfpq = mpq$df.residual,
    ppq = 1 - pchisq(mpq$deviance, mpq$df.residual),
    dipq = dipq, g2ipq = mi$deviance, dfipq = mi$df.residual, pipq = 1 - pchisq(mi$deviance, mi$df.residual))
}
# validate on hard-coded frequencies (do-file l.184-201; father varies fastest)
pH <- c(432, 286, 104, 55, 257, 2170, 147, 223, 70, 143, 139, 33, 35, 209, 30, 137)
qH <- c(684, 614, 176, 86, 270, 2187, 92, 189, 126, 244, 132, 45, 17, 100, 7, 55)
v <- altham(matrix(pH, 4, 4), matrix(qH, 4, 4))
for (nm in names(v)) add("validate_hardcoded", nm, v[[nm]])

## ---- IPF (Deming-Stephan) ----
ipf <- function(X, rt, ct, tol = 1e-12) {
  for (it in 1:10000) {
    X <- X * rt / rowSums(X); X <- t(t(X) * ct / colSums(X))
    if (max(abs(rowSums(X) - rt)) < tol) break
  }
  X
}
tabs <- function(fa, so, per) lapply(1:4, function(k) {
  t <- table(factor(fa[per == k], 1:4), factor(so[per == k], 1:4)); matrix(as.numeric(t), 4, 4)
})
t9 <- function(fa, so, per) {
  T <- tabs(fa, so, per); S <- T[[1]]
  lapply(T, function(X) {
    A <- ipf(X, rowSums(S), colSums(S))
    list(rowpct = 100 * A / rowSums(A), n = rowSums(A), colpct = 100 * colSums(A) / sum(A))
  })
}

## C7: T9 from the 2016 analysis file with standard IPF vs published
T9 <- t9(a$f_occ_group_last, a$occ_group_last, a$period)
cmp <- data.frame()
for (k in 1:4) for (i in 1:4) {
  for (j in 1:4) {
    id <- sprintf("T9_r%d_c%d", (k - 1) * 5 + i, j)
    cmp <- rbind(cmp, data.frame(id = id, pub = pub(id), rep = T9[[k]]$rowpct[i, j]))
  }
  id <- sprintf("T9_r%d_c5", (k - 1) * 5 + i)
  cmp <- rbind(cmp, data.frame(id = id, pub = pub(id), rep = T9[[k]]$n[i]))
}
for (k in 1:4) for (j in 1:4) {
  id <- sprintf("T9_r%d_c%d", (k - 1) * 5 + 5, j)
  if (length(pub(id))) cmp <- rbind(cmp, data.frame(id = id, pub = pub(id), rep = T9[[k]]$colpct[j]))
}
cmp$absdiff <- abs(cmp$pub - cmp$rep)
write.csv(cmp, dpath("P04_CF", "compare", "_scratch_s5", "t9_ipf_vs_published.csv"), row.names = FALSE)
pc <- cmp[!grepl("_c5$", cmp$id), ]; nc <- cmp[grepl("_c5$", cmp$id), ]
add("T9_ipf_2016", "T9 pct cells compared", nrow(pc))
add("T9_ipf_2016", "T9 pct cells within 0.05", sum(pc$absdiff <= 0.0501))
add("T9_ipf_2016", "T9 pct cells within 0.15", sum(pc$absdiff <= 0.1501))
add("T9_ipf_2016", "T9 pct max abs diff", max(pc$absdiff))
add("T9_ipf_2016", "T9 n cells within 1", sum(nc$absdiff <= 1.0001), paste("of", nrow(nc)))
add("T9_ipf_2016", "T9 Gold farmer->farmer (adj)", T9[[4]]$rowpct[2, 2])

## ---- headline evaluator on a son-level frame ----
lab_code <- function(s) { lv <- sort(unique(sprintf("%.2f", s)), method = "radix"); match(sprintf("%.2f", s), lv) }
headline <- function(d, scen) {
  d <- d |> filter(!is.na(fl), !is.na(sl))
  add(scen, "N pairs", nrow(d))
  T <- tabs(d$fl, d$sl, d$period)
  P <- T[[1]] + T[[2]]; Q <- T[[3]] + T[[4]]
  add(scen, "min cell P,Q", min(P, Q))
  v <- altham(P, Q); for (nm in c("dpi", "dqi", "dpq", "ppq", "dipq", "pipq")) add(scen, nm, v[[nm]])
  add(scen, "T6 farmer share Slavery", 100 * mean(d$sl[d$period == 1] == 2))
  add(scen, "T6 farmer share Gold", 100 * mean(d$sl[d$period == 4] == 2))
  add(scen, "T6 unskilled share Slavery", 100 * mean(d$sl[d$period == 1] == 4))
  add(scen, "T6 unskilled share Gold", 100 * mean(d$sl[d$period == 4] == 4))
  add(scen, "T8 Slavery farmer->farmer", 100 * T[[1]][2, 2] / sum(T[[1]][2, ]))
  add(scen, "T8 Gold farmer->farmer", 100 * T[[4]][2, 2] / sum(T[[4]][2, ]))
  t <- t9(d$fl, d$sl, d$period)
  add(scen, "T9 Slavery farmer->farmer", t[[1]]$rowpct[2, 2])
  add(scen, "T9 Gold farmer->farmer (adj)", t[[4]]$rowpct[2, 2])
  add(scen, "T9 Gold skilled->skilled (adj)", t[[4]]$rowpct[3, 3])
  d$mob <- as.integer(d$fl != d$sl); add(scen, "mobility rate", mean(d$mob))
  d <- d |> group_by(period) |> mutate(np = n()) |> group_by(period, fl) |>
    mutate(share_true = round(100 * n() / np, 2)) |> ungroup()
  d$share_code <- lab_code(d$share_true)
  ctrl <- "factor(period) + factor(origin) + I(f_gen == 1) + factor(first_son) + factor(prov)"
  fit <- function(rhs) glm(as.formula(paste("mob ~", ctrl, rhs)), family = binomial, data = d)
  m1 <- fit(""); m2 <- fit("+ factor(fl)"); m3 <- fit("+ share_code + factor(fl)"); m3t <- fit("+ share_true + factor(fl)")
  g <- function(m, term) { s <- summary(m)$coefficients; c(exp(s[term, 1]), s[term, 4]) }
  ms <- list(M1 = m1, M2 = m2, M3 = m3, M3trueshare = m3t)
  for (nm in names(ms)) for (tt in c("factor(period)3", "factor(period)4")) {
    r <- g(ms[[nm]], tt); lab <- ifelse(tt == "factor(period)3", "Diamonds", "Gold")
    add(scen, paste(lab, "OR", nm), r[1]); add(scen, paste(lab, "p", nm), r[2])
  }
  r <- g(m1, "I(f_gen == 1)TRUE"); add(scen, "migrant-father OR M1", r[1]); add(scen, "migrant-father p M1", r[2])
  r <- g(m3, "share_code"); add(scen, "share OR M3 (label code)", r[1]); add(scen, "share p M3 (label code)", r[2])
  r <- g(m3t, "share_true"); add(scen, "share OR M3 (true share)", r[1]); add(scen, "share p M3 (true share)", r[2])
  r <- g(m3, "factor(fl)2"); add(scen, "farmer-father OR M3", r[1])
  invisible(d)
}

## baseline on the 2016 file (reproduces published)
base16 <- a |> transmute(id, period, origin, f_gen, first_son, prov, fl = f_occ_group_last, sl = occ_group_last, dob)
headline(base16, "published_data_2016")

## ---- rebuild classes from the 2017 term lists ----
recode <- function(rows, mp, pref, K) {
  M <- matrix(sapply(1:K, function(k) mp$g[match(rows[[paste0(pref, k)]], mp$term)]), ncol = K)
  last <- apply(M, 1, function(z) { z <- z[!is.na(z)]; if (length(z)) z[length(z)] else NA })
  list(M = M, last = last, first = M[, 1])
}
mp0 <- map
chkS <- recode(b, mp0, "occup", 8); chkF <- recode(b, mp0, "f_occup", 9)
og <- unname(as.matrix(b[paste0("occ_group", 1:8)])); fg <- unname(as.matrix(b[paste0("f_occ_group", 1:9)]))
okS <- identical(is.na(og), is.na(chkS$M)) && all(og == chkS$M, na.rm = TRUE)
okF <- identical(is.na(fg), is.na(chkF$M)) && all(fg == chkF$M, na.rm = TRUE)
add("counts", "rebuilt son groups identical to occ_group1-8", as.numeric(okS))
add("counts", "rebuilt father groups identical to f_occ_group1-9", as.numeric(okF))
lastterm <- function(pref, K) apply(b[paste0(pref, 1:K)], 1, function(z) {
  z <- z[!is.na(z) & z != ""]; z <- z[!is.na(mp0$g[match(z, mp0$term)])]; if (length(z)) z[length(z)] else NA })
ltS <- lastterm("occup", 8); ltF <- lastterm("f_occup", 9)
add("counts", "sons whose last coded term is grazier", sum(ltS == "grazier", na.rm = TRUE))
add("counts", "fathers whose last coded term is grazier", sum(ltF == "grazier", na.rm = TRUE))
add("counts", "sons whose last coded term is century", sum(ltS == "century", na.rm = TRUE))
add("counts", "fathers whose last coded term is century", sum(ltF == "century", na.rm = TRUE))
onlyc <- function(pref, K) apply(b[paste0(pref, 1:K)], 1, function(z) {
  z <- z[!is.na(z) & z != ""]; z <- z[!is.na(mp0$g[match(z, mp0$term)])]; length(z) > 0 && all(z == "century") })
add("counts", "sons with century as only coded term", sum(onlyc("occup", 8)))
add("counts", "fathers with century as only coded term", sum(onlyc("f_occup", 9)))
U_last <- sum(chkS$last == 4, na.rm = TRUE) + sum(chkF$last == 4, na.rm = TRUE)
add("counts", "unskilled last-class records son+father", U_last)
add("counts", "share of unskilled last-class records due to grazier",
    (sum(ltS == "grazier", na.rm = TRUE) + sum(ltF == "grazier", na.rm = TRUE)) / U_last)
# grazier position: always after farmer?
gz <- apply(b[paste0("occup", 1:15)], 1, function(z) { z <- z[!is.na(z) & z != ""]; i <- which(z == "grazier"); if (!length(i)) NA else (i[1] > 1 && "farmer" %in% z[seq_len(i[1] - 1)]) })
add("counts", "son records with grazier", sum(!is.na(gz))); add("counts", "  of which farmer listed earlier", sum(gz, na.rm = TRUE))
# term order: is the list chronological? pairwise order consistency (son lists)
pr <- do.call(rbind, lapply(seq_len(nrow(b)), function(i) {
  z <- unlist(b[i, paste0("occup", 1:15)]); z <- z[!is.na(z) & z != ""]
  if (length(z) < 2) return(NULL); cm <- combn(length(z), 2); data.frame(x = z[cm[1, ]], y = z[cm[2, ]]) }))
pr <- pr[pr$x != pr$y, ]
key <- ifelse(pr$x < pr$y, paste(pr$x, pr$y), paste(pr$y, pr$x)); fwd <- pr$x < pr$y
ord <- tapply(fwd, key, function(z) max(mean(z), 1 - mean(z))); w <- tapply(fwd, key, length)
add("counts", "pair instances in modal order", sum(ord * w) / sum(w))
add("counts", "distinct pairs (>=5 instances) seen in both orders", mean(ord[w >= 5] < 1))
add("counts", "sons with >1 distinct coded class", sum(apply(chkS$M, 1, function(z) length(unique(na.omit(z))) > 1)))

## scenarios through linked 2016 rows (origin/prov/f_gen/first_son from the 2016 file)
d0c <- base16 |> left_join(lk |> select(id, brow1), by = "id")
add("base_2017terms", "rows rebuilt son class != 2016 class", sum(chkS$last[d0c$brow1] != d0c$sl, na.rm = TRUE))
add("base_2017terms", "rows rebuilt father class != 2016 class", sum(chkF$last[d0c$brow1] != d0c$fl, na.rm = TRUE))
run_scen <- function(mp, scen) {
  S <- recode(b, mp, "occup", 8); Fz <- recode(b, mp, "f_occup", 9)
  d <- d0c; d$sl <- S$last[d$brow1]; d$fl <- Fz$last[d$brow1]
  headline(d, scen)
}
run_scen(mp0, "base_2017terms")
mpG <- mp0; mpG$g[mpG$term == "grazier"] <- 2
mpC <- mp0; mpC$g[mpC$term == "century"] <- NA
mpB <- mpG; mpB$g[mpB$term == "century"] <- NA
run_scen(mpG, "grazier_to_farmer"); run_scen(mpC, "century_dropped"); run_scen(mpB, "grazier_farmer_and_century_dropped")
# first-listed occupation instead of last (order question)
S <- recode(b, mp0, "occup", 8); Fz <- recode(b, mp0, "f_occup", 9)
firstcoded <- function(M) apply(M, 1, function(z) { z <- z[!is.na(z)]; if (length(z)) z[1] else NA })
d <- d0c; d$sl <- firstcoded(S$M)[d$brow1]; d$fl <- firstcoded(Fz$M)[d$brow1]; headline(d, "first_listed_occupation")
S <- recode(b, mpB, "occup", 8); Fz <- recode(b, mpB, "f_occup", 9)
d <- d0c; d$sl <- firstcoded(S$M)[d$brow1]; d$fl <- firstcoded(Fz$M)[d$brow1]; headline(d, "first_listed_both_fixes")

## C9 and duplicates on the 2016 file
headline(base16 |> filter(as.integer(format(as.Date(dob, origin = "1960-01-01"), "%Y")) <= 1909), "no_1910_births")
headline(base16 |> left_join(cl, by = "id") |> filter(dupflag == 0), "duplicates_dropped")

res <- bind_rows(out)
write.csv(res, dpath("P04_CF", "compare", "_scratch_s5", "s5_results.csv"), row.names = FALSE)
options(width = 250)
print(res |> filter(scenario %in% c("validate_hardcoded", "counts", "T9_ipf_2016") | grepl("rows rebuilt", quantity)) |> mutate(value = round(value, 4)))
wide <- res |> filter(!scenario %in% c("validate_hardcoded", "counts", "T9_ipf_2016"), !grepl("rows rebuilt", quantity)) |>
  mutate(value = round(value, 4)) |> select(-note) |> pivot_wider(names_from = scenario, values_from = value, values_fn = first)
names(wide) <- substr(names(wide), 1, 14)
print(as.data.frame(wide))
