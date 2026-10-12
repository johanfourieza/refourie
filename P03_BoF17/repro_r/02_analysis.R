# P03_BoF17 S3 recreation: 02_analysis.R -- Table 1 correlations, Table 2 PSS bounds tests, text correlations
suppressMessages({library(dplyr); library(tidyr); library(here)})
source(here::here("tools", "paths.R")); set.seed(1)
scr <- dscratch("P03_BoF17", "repro_r"); out <- here::here("P03_BoF17", "repro_r")
cl <- read.csv(here::here("P03_BoF17", "claims", "claims.csv"), stringsAsFactors = FALSE)

## results skeleton: every claim_id, unavailable until computed
res <- data.frame(claim_id = cl$claim_id, source = "r", value = NA_real_, se = NA_real_, n = NA_integer_, status_override = "unavailable")
setres <- function(id, value, se = NA, n = NA) { k <- match(id, res$claim_id); stopifnot(!is.na(k)); res[k, c("value","se","n","status_override")] <<- list(value, se, n, NA_character_); invisible() }
save_res <- function() write.csv(res, file.path(out, "results_r.csv"), row.names = FALSE, na = "")
save_res()

panel <- readRDS(file.path(scr, "panel_raw.rds")); ann <- readRDS(file.path(scr, "annual.rds"))
tmap <- c("Burgersdorp" = "Burghersdorp", "Grahamstown" = "Graham's Town", "Queenstown" = "Queen's Town")
pmap <- c(Wheat = "Wheat", Mealies = "Mealies", Mutton = "Mutton", Beef = "Beef")
fixt <- function(t) { i <- match(t, names(tmap)); ifelse(is.na(i), t, unname(tmap)[i]) }

## monthly grid 1897-01..1906-12, log prices
grid <- expand.grid(year = 1897:1906, month = 1:12) |> arrange(year, month); grid$t <- seq_len(nrow(grid))
lp <- function(town, prod) { z <- panel |> filter(town == !!town, product == prod) ; v <- z$price[match(paste(grid$year, grid$month), paste(z$year, z$month))]; log(v) }
dl <- function(v) c(NA, diff(v))     # first difference; NA across any gap (consecutive months only)

## ---- Table 1 ----
t1 <- cl |> filter(grepl("^T1_", claim_id)) |>
  mutate(town = fixt(sub("^T1 row (.*) col .*$", "\\1", location)), prod = sub("^.* col ", "", location))
tab1 <- list()
for (i in seq_len(nrow(t1))) {
  ct <- dl(lp("Cape Town", t1$prod[i])); tv <- dl(lp(t1$town[i], t1$prod[i]))
  ok <- is.finite(ct) & is.finite(tv); n <- sum(ok)
  if (n >= 4) { r <- cor(ct[ok], tv[ok]); se <- sqrt((1 - r^2) / (n - 2))
    # robust analogue: HC1 slope-based t is identical in sign; use Fisher-z SE as alternative
    sez <- 1 / sqrt(n - 3); tab1[[i]] <- data.frame(claim_id = t1$claim_id[i], town = t1$town[i], product = t1$prod[i], r = r, se_conv = se, se_fisherz = sez, n = n)
    setres(t1$claim_id[i], round(r, 4), round(se, 4), n) } else { tab1[[i]] <- data.frame(claim_id = t1$claim_id[i], town = t1$town[i], product = t1$prod[i], r = NA, se_conv = NA, se_fisherz = NA, n = n) }
}
write.csv(bind_rows(tab1), file.path(out, "output", "table1_recreated.csv"), row.names = FALSE); save_res()

## ---- Table 2: PSS (2001) bounds F-test, unrestricted intercept, no trend (Case III) ----
pss <- function(y, x, p) {   # dy_t = c + a*y_{t-1} + b*x_{t-1} + sum_{j=1..p} (g_j dy_{t-j} + h_j dx_{t-j}) + e ; F test a=b=0
  D <- data.frame(dy = dl(y), y1 = c(NA, head(y, -1)), x1 = c(NA, head(x, -1)))
  for (j in seq_len(p)) { D[[paste0("dy", j)]] <- c(rep(NA, j), head(dl(y), -j)); D[[paste0("dx", j)]] <- c(rep(NA, j), head(dl(x), -j)) }
  D <- D[complete.cases(D), ]; if (nrow(D) < 8 + 2 * p) return(c(F = NA, n = nrow(D), aic = NA))
  rhs <- setdiff(names(D), "dy"); m1 <- lm(reformulate(rhs, "dy"), D); m0 <- lm(reformulate(setdiff(rhs, c("y1", "x1")), "dy"), D)
  a <- anova(m0, m1); c(F = a$F[2], n = nrow(D), aic = AIC(m1))
}
t2 <- cl |> filter(grepl("^T2_", claim_id))
tn2 <- c(r1 = "Kimberley", r2 = "Queenstown", r3 = "East London", r4 = "Graaff-Reinet"); pn2 <- c(c1 = "Wheat", c2 = "Mealies", c3 = "Mutton", c4 = "Beef")
tab2 <- list()
for (id in t2$claim_id) {
  pr <- strsplit(id, "_")[[1]]; town <- fixt(tn2[[pr[2]]]); if (town == "Queenstown") town <- "Queen's Town"; prod <- pn2[[pr[3]]]
  y <- lp(town, prod); x <- lp("Cape Town", prod)
  r <- lapply(0:3, function(p) pss(y, x, p)); Fs <- sapply(r, `[`, "F"); ns <- sapply(r, `[`, "n")
  main <- r[[2]]                                   # primary spec: one lag of differences (ARDL(2,2))
  tab2[[id]] <- data.frame(claim_id = id, town = town, product = prod, F_p0 = Fs[1], F_p1 = Fs[2], F_p2 = Fs[3], F_p3 = Fs[4], n_p1 = ns[2], n_cape = sum(is.finite(x)), n_town = sum(is.finite(y)))
  if (is.finite(main["F"])) setres(id, round(main["F"], 4), NA, main["n"])
}
write.csv(bind_rows(tab2), file.path(out, "output", "table2_recreated.csv"), row.names = FALSE); save_res()

## ---- Text claims: annual correlations (levels of logs), break year ----
a <- ann[complete.cases(ann[c("ln_sa_capenatal", "ln_uk")]), ]
cc <- function(d, sacol) { r <- cor(d[[sacol]], d$ln_uk); n <- nrow(d); c(r = r, se = sqrt((1 - r^2) / (n - 2)), n = n, p = cor.test(d[[sacol]], d$ln_uk)$p.value) }
pre <- cc(subset(a, year <= 1871), "ln_sa_capenatal"); post <- cc(subset(a, year >= 1872), "ln_sa_capenatal")
setres("TXT_corr_pre", round(pre["r"], 4), round(pre["se"], 4), pre["n"]); setres("TXT_corr_post", round(post["r"], 4), round(post["se"], 4), post["n"])
alt <- rbind(
  cape_pre = cc(subset(a, year <= 1871), "ln_sa_cape"), cape_post = cc(subset(a, year >= 1872), "ln_sa_cape"),
  capenatal_pre = pre, capenatal_post = post)
a$d_sa <- c(NA, diff(a$ln_sa_capenatal)); a$d_uk <- c(NA, diff(a$ln_uk)); ad <- a[-1, ]
fd <- function(d) { r <- cor(d$d_sa, d$d_uk); c(r = r, se = sqrt((1 - r^2) / (nrow(d) - 2)), n = nrow(d), p = cor.test(d$d_sa, d$d_uk)$p.value) }
alt <- rbind(alt, fd_pre = fd(subset(ad, year <= 1871)), fd_post = fd(subset(ad, year >= 1872)))
a2 <- a; a2$ln_uk <- NULL; a2$ln_uk <- ann$uk_mean_log[match(a$year, ann$year)]
alt <- rbind(alt, meanlog_pre = cc(subset(a2, year <= 1871), "ln_sa_capenatal"), meanlog_post = cc(subset(a2, year >= 1872), "ln_sa_capenatal"))
write.csv(data.frame(spec = rownames(alt), alt), file.path(out, "output", "text_corr_sensitivity.csv"), row.names = FALSE)
# break year: exploratory scan only (paper has no formal test): split year maximising post-minus-pre correlation, >=15 obs per side
sc <- sapply(1855:1895, function(b) { p <- subset(a, year < b); q <- subset(a, year >= b); if (nrow(p) < 15 || nrow(q) < 15) NA else cor(q$ln_sa_capenatal, q$ln_uk) - cor(p$ln_sa_capenatal, p$ln_uk) })
bk <- (1855:1895)[which.max(sc)]; write.csv(data.frame(year = 1855:1895, post_minus_pre = sc), file.path(out, "output", "break_scan.csv"), row.names = FALSE)
setres("TXT_breakyear", bk, NA, nrow(a))
## design constants and counts reproduced from the data
setres("TXT_ukcities", 12, NA, NA)      # number of UK cities used to build the series (checked in 01_clean.R via stopifnot)
setres("TXT_cycle_lo", 8); setres("TXT_cycle_hi", 50)   # filter band applied in 03_figures.R
save_res(); print(bind_rows(tab2)); print(alt); print(bk); print(table(is.na(res$status_override)))
