# P17_FvFH S6 -- 03_sensitivities.R: card §5 items 1-18 (reported, never verdict-determining)
source(here::here("P17_FvFH", "modern", "00_functions.R"))
bb <- readRDS(file.path(SCR, "build.rds")); o <- bb$o; b <- bb$b
P <- readRDS(file.path(SCR, "primary.rds")); pt0 <- P$pt; D1 <- P$D1
QS <- c("G1700", "G1723", "G1757", "C_wine", "S_wine", "C_grain", FAM)
long <- function(id, variant, pt, ci = NULL, note = "") {
  r <- tibble(sens = id, variant = variant, quantity = QS, estimate = unname(pt[QS]), lo = NA_real_, hi = NA_real_, note = note)
  if (!is.null(ci)) { r$lo <- ci$lo[match(QS, ci$quantity)]; r$hi <- ci$hi[match(QS, ci$quantity)] }
  r
}
pts <- function(bv, ...) stat(mats(bv, ...))
S <- list()
S[[1]] <- long("S1", "grain = kgw only", pts(build(o, grain = "kgw")))
S[[2]] <- bind_rows(long("S2", "weights = n only", pts(mutate(b, w = n))),
                    long("S2", "unweighted households", pts(mutate(b, w = 1))))
# S3a: factors from the surviving counts (Van Duin & Ross / .dta burgher totals, S3 clean.rds); 1702 factor for 1700
cr <- readRDS(dpath("P17_FvFH", "repro_r", "_scratch", "clean.rds"))
cc <- cr$cur; vv <- cr$vdr
f3 <- c(`1700` = vv$burgher_total[vv$year == 1702] / cc$burgher_total[cc$year == 1702],
        `1723` = vv$burgher_total[vv$year == 1723] / cc$burgher_total[cc$year == 1723],
        `1757` = vv$burgher_total[vv$year == 1757] / cc$burgher_total[cc$year == 1757])
S[[3]] <- bind_rows(long("S3a", "S3 factors from surviving counts", pts(build(o, wf = f3)), note = paste(names(f3), round(f3, 3), collapse = " ")),
  long("S3b", "factors re-estimated per draw", pt0, ci_tab(pt0, D1),
       note = "identical to primary by construction: one burgher factor per year scales w proportionally"))
S[[4]] <- long("S4", "household income, household weight wf", pts(mutate(b, wh = WF[as.character(jaar)]), percap = FALSE, wcol = "wh"))
S[[5]] <- bind_rows(long("S5", "1700 prices all years", pts(build(o, price_year = function(j) 1700))),
                    long("S5", "1757 prices all years", pts(build(o, price_year = function(j) 1757))))
# S6: nine joint sale-rate scenarios, bootstrap per scenario (B = 9999, primary seed)
sc <- expand_grid(rc = c(0.10, 0.15, 0.20), rh = c(0, 0.05, 0.10))
s6 <- pmap_dfr(sc, function(rc, rh) {
  L <- mats(build(o, rate_c = rc, rate_h = rh)); p <- stat(L)
  ci <- ci_tab(p, if (rc == 0.15 && rh == 0.05) D1 else boot_draws(L, 9999, 20261012))
  v <- verdicts(p, ci)
  long("S6", sprintf("cattle/sheep/pigs %.2f, horses %.2f", rc, rh), p, ci,
       note = paste(sub(" .*", "", v$claim[1:6]), v$rule[1:6] == 1, sep = "=", collapse = ";")) })
s6_share <- s6 %>% distinct(variant, note) %>% separate_rows(note, sep = ";") %>% separate(note, c("row", "met"), sep = "=") %>%
  group_by(row) %>% summarise(share_met = mean(met == "TRUE"), .groups = "drop")
S[[6]] <- s6
S[[7]] <- long("S7", "frequency-expanded (integer weights)", pts(mutate(b, w = round(w))),
               note = "unweighted LY on rows expanded by round(w) equals weighted LY with integer weights")
top1 <- b %>% mutate(y = A / n) %>% group_by(jaar) %>%
  mutate(r = rank(-ifelse(farm, y, -Inf), ties.method = "first"), keep = farm & r > ceiling(0.01 * sum(farm))) %>% ungroup()
S[[8]] <- long("S8", "top 1% of farming households dropped", pts(b, keep = top1$keep), note = paste("dropped", sum(top1$farm & !top1$keep)))
S[[9]] <- long("S9", "A = 0 households included", pts(b, keep = b$n > 0))
x <- readxl::read_excel(dpath("P17_FvFH", "original", "Wealth inequality", "Time 1663 - 1757 ----  EDITED.xls"))
x <- x %>% rename_with(tolower) %>% rename(cgw = ggw) %>% filter(jaar %in% YRS) %>%
  mutate(across(c(m, v, s, d, kgw, rgw, cgw, wyn, bste, skpe, vk, pd), ~ replace_na(suppressWarnings(as.numeric(.)), 0)))
S[[10]] <- long("S10", "raw xls (different population)", pts(build(x)), note = paste("rows", paste(table(x$jaar), collapse = "/")))
dup <- duplicated(o) & o$jaar == 1757
S[[11]] <- long("S11", "1757 duplicates dropped", pts(build(o[!dup, ])), note = paste("dropped", sum(dup)))
# S12 BCa: z0 from the primary draws, acceleration from delete-one jackknife over all rows of the years involved
L <- mats(b)
jk <- lapply(L, function(x) sapply(seq_len(nrow(x$M)), function(i) {
  if (!x$farm[i]) return(c(G = NA, C_wine = NA, S_wine = NA, setNames(rep(NA, 5), SRC[-2])))
  k <- x$farm; k[i] <- FALSE; d <- decomp(x$M[k, , drop = FALSE])
  c(G = d$G, C_wine = d$C[["wine"]], S_wine = d$S[["wine"]], d$C[SRC[-2]]) }))
G0 <- setNames(pt0[c("G1700", "G1723", "G1757")], YRS)
jg <- function(t) { v <- jk[[t]]["G", ]; v[is.na(v)] <- G0[[t]]; v }   # non-farming row deleted: statistic unchanged
j57 <- function(r) { v <- jk[["1757"]][r, ]
  v[is.na(v)] <- if (r == "G") G0[["1757"]] else if (r %in% SRC) pt0[[paste0("C_", r)]] else pt0[[r]]; v }
jv <- list(Delta = c(G0[["1757"]] - jg("1700"), jg("1757") - G0[["1700"]]),
           Da = c(G0[["1723"]] - jg("1700"), jg("1723") - G0[["1700"]]),
           Db = c(G0[["1757"]] - jg("1723"), jg("1757") - G0[["1723"]]),
           E = j57("C_wine") - j57("S_wine"))
for (k in SRC[-2]) jv[[paste0("D_", k)]] <- j57("C_wine") - j57(k)
bca <- map_dfr(FAM, function(q) {
  th <- D1[, q]; z0 <- qnorm(mean(th < pt0[[q]])); u <- mean(jv[[q]]) - jv[[q]]; a <- sum(u^3) / (6 * sum(u^2)^1.5)
  if (!is.finite(z0) || !is.finite(a)) return(tibble(quantity = q, lo = NA_real_, hi = NA_real_, note = "BCa not computed"))
  za <- qnorm(c(TAIL, 1 - TAIL)); al <- pnorm(z0 + (z0 + za) / (1 - a * (z0 + za)))
  tibble(quantity = q, lo = unname(quantile(th, al[1], type = 6)), hi = unname(quantile(th, al[2], type = 6)), note = sprintf("z0=%.3f a=%.4f", z0, a)) })
S[[12]] <- tibble(sens = "S12", variant = "BCa", quantity = bca$quantity, estimate = unname(pt0[bca$quantity]), lo = bca$lo, hi = bca$hi, note = bca$note)
dg <- read_csv(file.path(OUT, "diag_decomposition.csv"), show_col_types = FALSE) %>% filter(source != "total")
gw <- dg %>% filter(source %in% c("grain", "wine")) %>% select(year, source, contrib) %>% pivot_wider(names_from = source, values_from = contrib)
S[[13]] <- bind_rows(
  dg %>% pivot_longer(c(gini, rank, elast, contrib), names_to = "stat") %>%
    transmute(sens = "S13", variant = paste("year", year), quantity = paste0(stat, "_", source), estimate = value, lo = NA_real_, hi = NA_real_, note = ""),
  tibble(sens = "S13", variant = paste("year", gw$year), quantity = "C_grain - C_wine", estimate = gw$grain - gw$wine, lo = NA_real_, hi = NA_real_,
         note = ifelse(gw$grain > gw$wine, "grain ranks above wine", "wine ranks above grain")))
r14 <- pt0[["Delta"]] / 0.135
S[[14]] <- tibble(sens = "S14", variant = "magnitude", quantity = "Delta/0.135", estimate = r14, lo = NA_real_, hi = NA_real_,
                  note = ifelse(r14 < 0.5 | r14 > 1.5, "FLAG", "no flag"))
S[[15]] <- long("S15", "(a) drop missing / (b) median impute", pt0, note = "0 missing values in every used count, 1700/1723/1757: identical to primary")
# S16: cross-year dependence -- normal approximation under rho, and paired bootstrap by van+naam linkage
z <- qnorm(1 - TAIL); se <- apply(D1[, c("G1700", "G1723", "G1757")], 2, sd)
s16 <- map_dfr(c(-0.5, 0, 0.5), function(rho) map_dfr(list(c("Delta", "G1757", "G1700"), c("Da", "G1723", "G1700"), c("Db", "G1757", "G1723")),
  function(q) { s <- sqrt(se[[q[2]]]^2 + se[[q[3]]]^2 - 2 * rho * se[[q[2]]] * se[[q[3]]])
    tibble(sens = "S16", variant = paste0("normal, rho = ", rho), quantity = q[1], estimate = pt0[[q[1]]],
           lo = pt0[[q[1]]] - z * s, hi = pt0[[q[1]]] + z * s, note = "") }))
mult_boot <- function(unit, B = 9999, seed = 20261012, strata = NULL) {  # cluster bootstrap via multiplicity weights
  set.seed(seed); u <- as.integer(factor(unit)); nu <- max(u)
  st <- if (is.null(strata)) rep(1, nu) else tapply(strata, u, `[`, 1)
  t(vapply(seq_len(B), function(i) {
    mlt <- numeric(nu)
    for (s in unique(st)) { pool <- which(st == s); k <- pool[sample.int(length(pool), length(pool), replace = TRUE)]; mlt <- mlt + tabulate(k, nu) }
    mm <- mlt[u]
    Lb <- lapply(setNames(YRS, YRS), function(t) { i <- b$jaar == t; x <- L[[as.character(t)]]
      M <- x$M; M[, 1] <- M[, 1] * mm[i]; list(M = M, farm = x$farm & mm[i] > 0) })
    stat(Lb) }, numeric(length(pt0))))
}
id <- paste(b$van, b$naam); nlink <- sum(tapply(b$jaar, id, n_distinct) > 1)
Dp <- mult_boot(id)
S[[16]] <- bind_rows(s16, long("S16", "paired bootstrap, van+naam linkage", pt0, ci_tab(pt0, Dp, QS),
                               note = paste(n_distinct(id), "ids;", nlink, "linked across rolls")))
cid <- paste(b$jaar, replace_na(b$loc, "NA"))
Dc <- mult_boot(cid, strata = b$jaar)
S[[17]] <- long("S17", "cluster bootstrap by loc within year", pt0, ci_tab(pt0, Dc, QS),
                note = paste("clusters per year", paste(tapply(cid, b$jaar, n_distinct), collapse = "/")))
# S18: household influence on G1757 and C_wine (leave-one-out over 1757 rows)
inf <- tibble(row = seq_len(ncol(jk[["1757"]])), dG = j57("G") - G0[["1757"]], dC = j57("C_wine") - pt0[["C_wine"]]) %>% arrange(desc(abs(dG)))
write_csv(head(inf, 20), file.path(OUT, "s18_influence_top20.csv"))
S[[18]] <- tibble(sens = "S18", variant = "leave-one-out, 1757", quantity = c("max |shift| G1757", "max |shift| C_wine"),
                  estimate = c(max(abs(inf$dG)), max(abs(inf$dC))), lo = NA_real_, hi = NA_real_, note = "top 20 in s18_influence_top20.csv")
out <- bind_rows(S); write_csv(out, file.path(OUT, "sensitivities.csv")); write_csv(s6_share, file.path(OUT, "s6_share_met.csv"))
options(width = 200)
print(as.data.frame(out %>% filter(quantity %in% c("G1757", "C_wine", "Delta", "Da", "Db", "E", "D_grain") | sens %in% c("S14", "S18") | quantity == "C_grain - C_wine") %>%
  filter(!(sens == "S13" & quantity != "C_grain - C_wine")) %>% mutate(across(where(is.numeric), ~ round(., 3))) %>% select(-note)), row.names = FALSE)
print(s6_share); print(out %>% filter(note != "") %>% distinct(sens, variant, note) %>% filter(sens != "S6") %>% as.data.frame())
