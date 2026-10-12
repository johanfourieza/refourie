# P04_CF  S3 independent recreation  02_analysis.R
# Tables 1, 3-11 from the analysis file built in 01_clean.R. Writes output/*.tex, output/*.csv, results_r.csv
suppressMessages({
  library(dplyr); library(tidyr); library(stringr); library(readr); library(purrr)
  library(tidyxl); library(sandwich); library(modelsummary); library(kableExtra)
})
set.seed(20261011)
args <- commandArgs(trailingOnly = FALSE)
sp <- sub("--file=", "", args[grep("--file=", args)])
ROOT <- if (length(sp)) normalizePath(file.path(dirname(sp), "..")) else normalizePath("..")
source(file.path(dirname(ROOT), "tools", "paths.R"))  # [A6] data root on D:
RR <- file.path(ROOT, "repro_r"); SCR <- dpath("P04_CF", "repro_r", "_scratch"); OUT <- file.path(RR, "output")
XL <- dpath("P04_CF", "original", "CF Mobility", "Results latest", "Census_Comparisons.xlsx")
claims <- read_csv(file.path(ROOT, "claims/claims.csv"), show_col_types = FALSE)

d0 <- readRDS(file.path(SCR, "analysis.rds"))
CL <- c("W","F","S","U"); CLN <- c("White collar","Farmer","Skilled/semi-skilled","Unskilled")
COH <- c("Slavery","Stagnation","Diamonds","Gold")

# analysis sample builder: spec = primary | prisU | no1910 | coded
make_sample <- function(spec = "primary") {
  x <- d0
  if (spec == "prisU") x <- x |> mutate(last_son = last_son_prisU, last_father = last_father_prisU,
                                        occfirst_son = occfirst_son_prisU, keep = keep_prisU)
  if (spec == "coded") x <- x |> mutate(last_son = coded_son, last_father = coded_father,
                                        keep = !is.na(coded_son) & !is.na(coded_father))
  if (spec == "no1910") x <- x |> filter(!born1910)
  x |> filter(keep) |>
    mutate(son = factor(last_son, CL), father = factor(last_father, CL),
           cohort = factor(cohort, COH), mobile = as.integer(son != father),
           pre1868 = cohort %in% c("Slavery","Stagnation"))
}
d <- make_sample("primary")

res <- list()   # claim rows
add <- function(id, value, se = NA_real_, n = NA_real_, status = NA_character_)
  res[[length(res) + 1]] <<- tibble(claim_id = id, source = "r", value = value, se = se, n = n,
                                    status_override = status)

# ------------------------------------------------------------ Table 1: places
t1 <- map_dfr(seq_along(COH), function(k) {
  s <- d |> filter(cohort == COH[k]); nk <- sum(!is.na(s$place))
  s |> filter(!is.na(place)) |> count(place, sort = TRUE) |>
    mutate(share_known = 100 * n / nk, share_all = 100 * n / nrow(s), rank = row_number(), cohort = COH[k])
})
write_csv(t1 |> filter(rank <= 15), file.path(OUT, "table1_places.csv"))
for (k in seq_along(COH)) {
  tk <- t1 |> filter(cohort == COH[k])
  for (rk in 1:10) {
    id <- sprintf("T1_r%d_c%d", rk, k)
    nm <- str_match(claims$description[claims$claim_id == id], "\\(([^)]+)\\)")[, 2]
    v <- tk$share_known[tk$place == nm]; add(id, if (length(v)) v else 0, n = sum(tk$n))
  }
  add(sprintf("T1_r11_c%d", k), sum(tk$share_known[tk$rank <= 10]), n = sum(tk$n))
}
t1w <- t1 |> filter(rank <= 10) |> transmute(cohort, rank, cell = sprintf("%s %.1f", place, share_known)) |>
  pivot_wider(names_from = cohort, values_from = cell)
kbl(t1w, format = "latex", booktabs = TRUE, caption = "Top 10 place names (R recreation; share of sons with known place)") |>
  save_kable(file.path(OUT, "table1.tex"))

# ------------------------------------------------------------ Table 6 / 3 / 4 / 7
shares <- function(x, v) x |> count(cohort, cls = .data[[v]], .drop = FALSE) |> group_by(cohort) |>
  mutate(p = 100 * n / sum(n), N = sum(n)) |> ungroup()
t6 <- shares(d, "son")
t6w <- t6 |> select(cohort, cls, p) |> pivot_wider(names_from = cohort, values_from = p) |>
  mutate(change = Gold - Slavery)
for (i in 1:4) { for (k in 1:4) add(sprintf("T6_r%d_c%d", i, k), t6w[[COH[k]]][i], n = nrow(d))
  add(sprintf("T6_r%d_c5", i), t6w$change[i]) }
for (k in 1:4) { add(sprintf("T6_r5_c%d", k), 100); add(sprintf("T6_r6_c%d", k), sum(d$cohort == COH[k])) }
add("T6_r6_c5", nrow(d)); add("TXT_p8_a", nrow(d))
t6tex <- t6w |> mutate(cls = CLN) |> bind_rows(tibble(cls = "Cohort size", !!!setNames(as.list(as.numeric(table(d$cohort))), COH), change = nrow(d)))
kbl(t6tex, format = "latex", booktabs = TRUE, digits = 1, caption = "Table 6 (R): class shares by cohort") |>
  save_kable(file.path(OUT, "table6.tex"))

# census (input workbook)
cx <- xlsx_cells(XL)
cell <- function(sh, a) cx$numeric[cx$sheet == sh & cx$address == a]
cen <- tibble(cls = CL,
  c1865 = map_dbl(3:6, ~cell("Summaries", paste0("B", .x))), c1875 = map_dbl(3:6, ~cell("Summaries", paste0("C", .x))),
  c1891 = map_dbl(3:6, ~cell("Summaries", paste0("D", .x))), c1911 = map_dbl(3:6, ~cell("Summaries", paste0("E", .x))))
cenp <- cen |> mutate(across(starts_with("c1"), ~ 100 * .x / sum(.x)))
t3cols <- list(c1 = t6w$Slavery, c2 = t6w$Stagnation, c3 = cenp$c1865, c4 = t6w$Diamonds,
               c5 = cenp$c1875, c6 = cenp$c1891, c7 = t6w$Gold)
for (j in 1:7) { for (i in 1:4) add(sprintf("T3_r%d_c%d", i, j), t3cols[[j]][i]); add(sprintf("T3_r5_c%d", j), 100) }
for (i in 1:4) { add(sprintf("T4_r%d_c1", i), t6w$Gold[i]); add(sprintf("T4_r%d_c2", i), cenp$c1911[i]) }
add("T4_r5_c1", 100); add("T4_r5_c2", 100)
t3 <- as_tibble(t3cols) |> setNames(c("SAF 1806-34","SAF 1835-67","Census 1865","SAF 1868-86","Census 1875","Census 1891","SAF 1887-1909")) |>
  mutate(Class = CLN, .before = 1)
kbl(t3, format = "latex", booktabs = TRUE, digits = 1, caption = "Table 3 (R)") |> save_kable(file.path(OUT, "table3.tex"))
kbl(tibble(Class = CLN, `SAF 1887-1909` = t6w$Gold, `Census 1911` = cenp$c1911), format = "latex", booktabs = TRUE,
    digits = 1, caption = "Table 4 (R)") |> save_kable(file.path(OUT, "table4.tex"))

# Table 5: whites from Summaries; non-Europeans from own coding of 1911 orders (Union rows 8-99, cols G+L males)
u <- cx |> filter(sheet == "1911", row >= 8, row <= 99)
nonw <- u |> filter(col %in% c(7, 12)) |> group_by(row) |> summarise(m = sum(numeric, na.rm = TRUE))
map1911 <- c(setNames(rep("W", 15), 8:22), `27` = "S", `28` = "U", `31` = "W", `33` = "S", `34` = "U", `35` = "S",
  `36` = "U", `37` = "W", `38` = "U", `41` = "F", `42` = "F", `43` = "F", `44` = "F",
  setNames(rep("S", 13), 47:59), setNames(rep("S", 4), 61:64), `66` = "S", `67` = "S", `68` = "S",
  `70` = "S", `71` = "S", `72` = "S", `74` = "S", `75` = "S", `77` = "U", setNames(rep("S", 6), 78:83), `85` = "U")
nonw <- nonw |> mutate(cls = map1911[as.character(row)]) |> filter(!is.na(cls)) |> group_by(cls) |>
  summarise(m = sum(m)) |> right_join(tibble(cls = CL), by = "cls") |> arrange(match(cls, CL))
t5 <- tibble(cls = CL, wN = cen$c1911, nN = nonw$m) |> mutate(tN = wN + nN, wp = 100 * wN / tN, np = 100 * nN / tN)
t5 <- bind_rows(t5, tibble(cls = "Total", wN = sum(t5$wN), nN = sum(t5$nN), tN = sum(t5$tN)) |>
  mutate(wp = 100 * wN / tN, np = 100 * nN / tN))
for (i in 1:5) { v <- unlist(t5[i, c("wN","wp","nN","np","tN")]); for (j in 1:5) add(sprintf("T5_r%d_c%d", i, j), v[j]); add(sprintf("T5_r%d_c6", i), 100) }
add("TXT_p9_a", t5$np[2]); add("TXT_p9_b", t5$np[4])
kbl(t5 |> mutate(cls = c(CLN, "Total")), format = "latex", booktabs = TRUE, digits = 1, format.args = list(big.mark = ","),
    caption = "Table 5 (R): 1911 working-age males by race (non-European column own coding of 1911 orders)") |>
  save_kable(file.path(OUT, "table5.tex"))

# Table 7: first vs last (sons, pooled)
d7 <- d |> mutate(first = factor(occfirst_son, CL))
t7 <- tibble(cls = CL, first = 100 * as.numeric(table(d7$first)) / nrow(d7), last = 100 * as.numeric(table(d7$son)) / nrow(d7))
for (i in 1:4) { add(sprintf("T7_r%d_c1", i), t7$first[i]); add(sprintf("T7_r%d_c2", i), t7$last[i]) }
add("T7_r5_c1", 100); add("T7_r5_c2", 100); add("T7_r6_c1", nrow(d)); add("T7_r6_c2", nrow(d))
kbl(t7 |> mutate(cls = CLN), format = "latex", booktabs = TRUE, digits = 1, caption = "Table 7 (R)") |>
  save_kable(file.path(OUT, "table7.tex"))

# ------------------------------------------------------------ Tables 8 and 9
tab <- function(x) as.matrix(table(x$father, x$son))
tabs <- map(COH, ~ tab(d |> filter(cohort == .x))) |> setNames(COH)
ipf <- function(m, rt, ct, tol = 1e-10) {
  for (it in 1:10000) { m <- m * (rt / rowSums(m)); m <- t(t(m) * (ct / colSums(m)))
    if (max(abs(rowSums(m) - rt)) < tol) break }
  m
}
panel <- function(m) {
  rp <- 100 * m / rowSums(m); cp <- 100 * colSums(m) / sum(m)
  rbind(cbind(rp, n = rowSums(m)), `Col (%)` = c(cp, sum(m)))
}
t8 <- map(tabs, panel)
adj <- map(tabs, ~ ipf(.x, rowSums(tabs$Slavery), colSums(tabs$Slavery)))
t9 <- map(adj, panel)
emit <- function(tl, pre) for (p in 1:4) for (k in 1:5) for (j in 1:5)
  add(sprintf("%s_r%d_c%d", pre, (p - 1) * 5 + k, j), if (j == 5) round(tl[[p]][k, j]) else tl[[p]][k, j])
emit(t8, "T8"); emit(t9, "T9")
g <- function(tl, p, i, j) tl[[p]][i, j]
add("TXT_p12_a", g(t8, 1, 2, 2)); add("TXT_p12_b", g(t8, 1, 2, 2) - g(t8, 4, 2, 2)); add("TXT_p12_c", g(t8, 4, 1, 1) - g(t8, 1, 1, 1))
add("TXT_p12_d", g(t8, 4, 1, 4)); add("TXT_p12_e", g(t8, 4, 3, 1)); add("TXT_p12_f", g(t8, 4, 4, 1) - g(t8, 1, 4, 1))
stack_tex <- function(tl, file, cap) {
  x <- map2_dfr(tl, names(tl), ~ as_tibble(.x, rownames = "Father") |> mutate(Cohort = .y, .before = 1)) |>
    mutate(Father = recode(Father, W = "White collar", F = "Farmer", S = "Skilled/semi-skilled", U = "Unskilled"))
  write_csv(x, sub("\\.tex$", ".csv", file))
  kbl(x, format = "latex", booktabs = TRUE, digits = 1, caption = cap) |> save_kable(file)
}
stack_tex(t8, file.path(OUT, "table8.tex"), "Table 8 (R): absolute mobility, row percentages")
stack_tex(t9, file.path(OUT, "table9.tex"), "Table 9 (R): marginals adjusted to Slavery (Deming-Stephan IPF)")

# ------------------------------------------------------------ Table 10: Altham
lcpr <- function(m) { lp <- log(m / sum(m)); r <- nrow(m); c <- ncol(m)
  a <- array(0, c(r, c, r, c))
  for (i in 1:r) for (j in 1:c) for (l in 1:r) for (k in 1:c) a[i, j, l, k] <- lp[i, j] + lp[l, k] - lp[i, k] - lp[l, j]
  a }
offmask <- function(r) { a <- array(TRUE, c(r, r, r, r))
  for (i in 1:r) for (j in 1:r) for (l in 1:r) for (k in 1:r) a[i, j, l, k] <- i != j && l != k && i != k && l != j
  a }
altham <- function(P, Q = NULL, off = FALSE, half = FALSE) {
  LP <- lcpr(P); LQ <- if (is.null(Q)) 0 * LP else lcpr(Q); D <- (LP - LQ)^2
  if (off) D <- D[offmask(nrow(P))]
  if (half) { r <- nrow(P); keep <- array(FALSE, dim(LP)); for (j in 1:r) for (k in j:r) keep[, j, , k] <- TRUE; D <- (LP - LQ)[keep]^2 }
  sqrt(sum(D))
}
g2_indep <- function(m) { df <- as.data.frame(as.table(m)); names(df) <- c("R", "C", "n")
  f <- glm(n ~ R + C, poisson, df); c(G2 = deviance(f), df = df.residual(f), p = pchisq(deviance(f), df.residual(f), lower.tail = FALSE)) }
g2_common <- function(P, Q, off = FALSE) {
  df <- bind_rows(as.data.frame(as.table(P)) |> mutate(G = "P"), as.data.frame(as.table(Q)) |> mutate(G = "Q"))
  names(df)[1:3] <- c("R", "C", "n")
  if (off) df <- df |> filter(as.character(R) != as.character(C))
  f <- glm(n ~ G * R + G * C + R * C, poisson, df)
  c(G2 = deviance(f), df = df.residual(f), p = pchisq(deviance(f), df.residual(f), lower.tail = FALSE)) }
stars <- function(p) ifelse(p < .01, "***", ifelse(p < .05, "**", ifelse(p < .1, "*", "")))
altham_block <- function(x, rows = CL, fvar = "father", svar = "son") {
  P <- as.matrix(table(x[[fvar]][x$pre1868], x[[svar]][x$pre1868]))[rows, rows]
  Q <- as.matrix(table(x[[fvar]][!x$pre1868], x[[svar]][!x$pre1868]))[rows, rows]
  if (any(P == 0) || any(Q == 0)) { P <- P + 0.5; Q <- Q + 0.5 }
  tibble(stat = c("d(P,I)", "d(Q,I)", "d(P,Q)", "di(P,Q)"),
         value = c(altham(P), altham(Q), altham(P, Q), altham(P, Q, off = TRUE)),
         value_half = c(altham(P, half = TRUE), altham(Q, half = TRUE), altham(P, Q, half = TRUE), NA),
         G2 = c(g2_indep(P)["G2"], g2_indep(Q)["G2"], g2_common(P, Q)["G2"], g2_common(P, Q, TRUE)["G2"]),
         df = c(g2_indep(P)["df"], g2_indep(Q)["df"], g2_common(P, Q)["df"], g2_common(P, Q, TRUE)["df"]),
         p = c(g2_indep(P)["p"], g2_indep(Q)["p"], g2_common(P, Q)["p"], g2_common(P, Q, TRUE)["p"]),
         nP = sum(P), nQ = sum(Q)) |> mutate(stars = stars(p))
}
t10 <- altham_block(d)
t10nf <- altham_block(d, rows = c("W", "S", "U"))
hc <- d0 |> filter(!is.na(hc_son), !is.na(hc_father)) |>
  mutate(son5 = factor(hc_son, 1:5), father5 = factor(hc_father, 1:5), cohort = factor(cohort, COH),
         pre1868 = cohort %in% c("Slavery", "Stagnation"))
t10h <- altham_block(hc, rows = as.character(1:5), fvar = "father5", svar = "son5")
bind_rows(t10 |> mutate(spec = "4 classes"), t10nf |> mutate(spec = "excluding farmers"),
          t10h |> mutate(spec = "5 HISCLASS groups (authors' codes)")) |> write_csv(file.path(OUT, "table10_altham.csv"))
for (j in 1:4) add(sprintf("T10_r1_c%d", j), t10$value[j], n = t10$nP[1] + t10$nQ[1])
for (j in 1:3) add(paste0("TXT_p15_", letters[j]), t10nf$value[j])
for (j in 1:4) add(paste0("TXT_p15_fn9", letters[j]), t10h$value[j], n = t10h$nP[1] + t10h$nQ[1])
kbl(t10 |> transmute(Statistic = stat, Value = sprintf("%.2f%s", value, stars), G2 = round(G2, 2), df, p = signif(p, 3)),
    format = "latex", booktabs = TRUE, caption = "Table 10 (R): Altham statistics, before (P) vs after (Q) 1868") |>
  save_kable(file.path(OUT, "table10.tex"))

# ------------------------------------------------------------ Table 11
prep11 <- function(x) {
  cs <- x |> count(cohort, father) |> group_by(cohort) |> mutate(origin_share = 100 * n / sum(n)) |> select(-n)
  x |> left_join(cs, by = c("cohort", "father")) |>
    mutate(nonmigrant = as.integer(!migrant_father), later_born = as.integer(later_born),
           origin = relevel(droplevels(origin), "Netherlands"), prov = relevel(droplevels(prov), "Cape"),
           father = relevel(father, "W"), cohort = relevel(cohort, "Slavery"))
}
f1 <- mobile ~ cohort + nonmigrant + origin + later_born + prov
f2 <- update(f1, . ~ . + father); f3 <- update(f2, . ~ . + origin_share)
fit11 <- function(x) {
  x <- prep11(x)
  lg <- map(list(f1, f2, f3), ~ glm(.x, binomial, x)); ps <- map(list(f1, f2, f3), ~ glm(.x, poisson, x))
  list(x = x, logit = lg, pois = ps)
}
m <- fit11(d)
or_tab <- function(fl, vc = c("iid", "cl"), x) {
  map2_dfr(fl, 1:3, function(f, k) {
    V <- if (vc == "cl") vcovCL(f, cluster = f$data$fathers_id, type = "HC0") else if (family(f)$family == "poisson") vcovHC(f, "HC0") else vcov(f)
    b <- coef(f); se <- sqrt(diag(V))
    tibble(model = k, term = names(b), b = b, se_b = se, ratio = exp(b), se_ratio = exp(b) * se,
           p = 2 * pnorm(-abs(b / se)), stars = stars(p))
  })
}
or_iid <- or_tab(m$logit, "iid"); or_cl <- or_tab(m$logit, "cl")
rr_rob <- or_tab(m$pois, "iid"); rr_cl <- or_tab(m$pois, "cl")
fitstats <- map_dfr(1:3, function(k) { f <- m$logit[[k]]
  tibble(model = k, pseudoR2 = 1 - f$deviance / f$null.deviance, LR = f$null.deviance - f$deviance,
         df = f$df.null - f$df.residual, p_chi2 = pchisq(f$null.deviance - f$deviance, f$df.null - f$df.residual, lower.tail = FALSE),
         N = nobs(f)) })
bind_rows(or_iid |> mutate(est = "logit OR", vcov = "conventional"), or_cl |> mutate(est = "logit OR", vcov = "cluster father"),
          rr_rob |> mutate(est = "Poisson RR", vcov = "robust HC0"), rr_cl |> mutate(est = "Poisson RR", vcov = "cluster father")) |>
  write_csv(file.path(OUT, "table11_estimates.csv"))
write_csv(fitstats, file.path(OUT, "table11_fitstats.csv"))
termmap <- c(`cohortStagnation` = 2, `cohortDiamonds` = 3, `cohortGold` = 4, nonmigrant = 5, originFrance = 7,
  originGermany = 8, originUK = 9, `originOther west Europe` = 10, `originOther east Europe` = 11,
  provNatal = 14, provOFS = 15, provTransvaal = 16, fatherF = 18, fatherS = 19, fatherU = 20, origin_share = 21)
for (k in 1:3) {
  for (rr in c(1, 6, 12, 13, 17)) add(sprintf("T11_r%d_c%d", rr, k), 1)
  ek <- or_iid |> filter(model == k)
  for (tm in names(termmap)) { e <- ek[ek$term == tm, ]; if (nrow(e)) add(sprintf("T11_r%d_c%d", termmap[[tm]], k), e$ratio, e$se_ratio, fitstats$N[k]) }
  add(sprintf("T11_r22_c%d", k), fitstats$pseudoR2[k], n = fitstats$N[k])
  add(sprintf("T11_r23_c%d", k), fitstats$p_chi2[k], n = fitstats$N[k])
  add(sprintf("T11_r24_c%d", k), fitstats$N[k])
}
cm <- c(cohortStagnation = "Stagnation", cohortDiamonds = "Diamonds", cohortGold = "Gold",
  nonmigrant = "Non-migrant father (migrant ref.)", originFrance = "France", originGermany = "Germany", originUK = "UK",
  `originOther west Europe` = "Other west Europe", `originOther east Europe` = "Other east Europe", originUnknown = "Origin unknown",
  later_born = "Later-born son (first-born ref.)", provNatal = "Natal", provOFS = "OFS", provTransvaal = "Transvaal",
  provUnknown = "Province unknown", fatherF = "Father farmer", fatherS = "Father skilled/semi-skilled",
  fatherU = "Father unskilled", origin_share = "Origin class size")
ms_out <- function(mods, vc, file, title) {
  modelsummary(setNames(mods, paste("Model", 1:3)), exponentiate = TRUE, vcov = vc, coef_map = cm,
    stars = c("*" = .1, "**" = .05, "***" = .01), statistic = "({std.error})", fmt = 3,
    gof_map = c("nobs", "logLik"), output = file, title = title)
}
ms_out(m$logit, "iid", file.path(OUT, "table11_logit_conventional.tex"), "Table 11 (R): logit odds ratios, conventional SEs")
ms_out(m$logit, map(m$logit, ~ vcovCL(.x, cluster = .x$data$fathers_id, type = "HC0")), file.path(OUT, "table11_logit_cluster.tex"), "Table 11 (R): logit odds ratios, SEs clustered by father")
ms_out(m$pois, map(m$pois, ~ vcovCL(.x, cluster = .x$data$fathers_id, type = "HC0")), file.path(OUT, "table11_poissonRR_cluster.tex"), "Table 11 (R): modified-Poisson risk ratios, SEs clustered by father")

# ------------------------------------------------------------ sensitivities
sens <- map_dfr(c("primary", "prisU", "no1910", "coded"), function(sp) {
  x <- make_sample(sp); mm <- fit11(x); al <- altham_block(x)
  t6s <- shares(x, "son") |> filter(cohort %in% c("Slavery", "Gold"))
  tb <- as.matrix(table(x$father[x$cohort == "Gold"], x$son[x$cohort == "Gold"]))
  sl <- as.matrix(table(x$father[x$cohort == "Slavery"], x$son[x$cohort == "Slavery"]))
  g9 <- ipf(tb, rowSums(sl), colSums(sl))
  tibble(spec = sp, N = nrow(x),
    quantity = c("T11 Gold OR M1", "T11 Gold OR M3", "T11 Diamonds OR M2", "T11 nonmigrant OR M1", "T11 origin share OR M3",
                 "T10 d(P,I)", "T10 d(Q,I)", "T10 d(P,Q)", "T10 p d(P,Q)", "T10 di(P,Q)",
                 "T6 Farmer Slavery", "T6 Farmer Gold", "T6 Unskilled Slavery", "T8 F|F Slavery", "T9 F|F Gold adj"),
    value = c(exp(coef(mm$logit[[1]])["cohortGold"]), exp(coef(mm$logit[[3]])["cohortGold"]), exp(coef(mm$logit[[2]])["cohortDiamonds"]),
              exp(coef(mm$logit[[1]])["nonmigrant"]), exp(coef(mm$logit[[3]])["origin_share"]),
              al$value[1], al$value[2], al$value[3], al$p[3], al$value[4],
              t6s$p[t6s$cohort == "Slavery" & t6s$cls == "F"], t6s$p[t6s$cohort == "Gold" & t6s$cls == "F"],
              t6s$p[t6s$cohort == "Slavery" & t6s$cls == "U"], 100 * sl["F", "F"] / sum(sl["F", ]), 100 * g9["F", "F"] / sum(g9["F", ])))
})
write_csv(sens, file.path(OUT, "sensitivity.csv"))

# ------------------------------------------------------------ results_r.csv
out <- bind_rows(res) |> mutate(value = signif(value, 8), se = signif(se, 6))
miss <- setdiff(claims$claim_id, out$claim_id)
out <- bind_rows(out, tibble(claim_id = miss, source = "r", value = NA, se = NA, n = NA, status_override = "not-attempted"))
out <- out[match(claims$claim_id, out$claim_id), ]
stopifnot(!anyDuplicated(out$claim_id), all(claims$claim_id %in% out$claim_id))
write_csv(out, file.path(RR, "results_r.csv"), na = "")
cat("claims written:", nrow(out), " not-attempted:", sum(out$status_override %in% "not-attempted", na.rm = TRUE), "\n")
print(t10); print(fitstats); print(sens |> pivot_wider(names_from = spec, values_from = c(value, N)) |> select(-starts_with("N_")))
