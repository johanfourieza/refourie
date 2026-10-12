# P09_FIM S5 check 2 (Claude). Sensitivity checks on the S3 rebuild sample (aggregates only).
# (1) heights at/below 160.02 (S2-2; explains N 6,972 vs 6,896); (2) truncation treatment, weights, SE type
# on T3 cols 3-6; (3) headline proxies: pooled cohort model incl. WWII (no covariates) under variants;
# (4) col-8 identity WWII dummy vs Attestation; (6) S2-8 repeats; (7) S2-9 wildcard callings;
# (8) S2-10 birth-year shift (inside 3).
suppressPackageStartupMessages({ library(tidyverse); library(numDeriv); library(readxl) })
root <- here::here()
source(file.path(root, "tools", "paths.R"))
set.seed(20221)
out <- file.path(root, "P09_FIM", "compare", "s5_checks")
s <- readRDS(dscratch("P09_FIM", "repro_r", "analysis_sample.rds"))
TR <- 160.02
log <- list(); note <- function(k, v) { log[[length(log) + 1]] <<- tibble(check = k, value = as.character(v)) }

# trunc_fit: copied from repro_r/02_analysis.R (read-only); adds a strict (>) sample rule and a free truncation point
trunc_fit <- function(formula, data, w = NULL, c = TR, keep = TR, strict = FALSE) {
  data <- if (strict) filter(data, height > keep + 1e-9) else filter(data, height >= keep - 1e-9)
  mf <- model.frame(formula, data); X <- model.matrix(formula, mf); X <- X[, colSums(abs(X)) > 0, drop = FALSE]
  y <- model.response(mf); wv <- if (is.null(w)) rep(1, length(y)) else data[[w]][as.integer(rownames(mf))]
  k <- ncol(X)
  ll_i <- function(th) { b <- th[1:k]; sg <- th[k + 1]; xb <- drop(X %*% b)
    dnorm((y - xb) / sg, log = TRUE) - log(sg) - pnorm((c - xb) / sg, lower.tail = FALSE, log.p = TRUE) }
  sc_i <- function(th) { b <- th[1:k]; sg <- th[k + 1]; xb <- drop(X %*% b); z <- (y - xb) / sg; a <- (c - xb) / sg
    lam <- exp(dnorm(a, log = TRUE) - pnorm(a, lower.tail = FALSE, log.p = TRUE))
    cbind(X * (z - lam) / sg, (z^2 - 1 - a * lam) / sg) }
  negll <- function(p) { th <- c(p[1:k], exp(p[k + 1])); -sum(wv * ll_i(th)) }
  neggr <- function(p) { th <- c(p[1:k], exp(p[k + 1])); g <- colSums(wv * sc_i(th)); -c(g[1:k], g[k + 1] * th[k + 1]) }
  ols <- lm.wfit(X, y, wv); p0 <- c(coef(ols), log(sqrt(sum(wv * ols$residuals^2) / sum(wv)))); p0[is.na(p0)] <- 0
  op <- optim(p0, negll, neggr, method = "BFGS", control = list(maxit = 5000, reltol = 1e-14))
  th <- c(op$par[1:k], exp(op$par[k + 1]))
  for (it in 1:20) {
    H <- jacobian(function(t) colSums(wv * sc_i(t)), th)
    st <- tryCatch(solve(H, colSums(wv * sc_i(th))), error = function(e) 0 * th)
    th <- th - st; if (max(abs(st)) < 1e-10) break
  }
  H <- jacobian(function(t) colSums(wv * sc_i(t)), th); Hi <- solve(-H); S <- sc_i(th) * wv
  Vr <- Hi %*% crossprod(S) %*% Hi * length(y) / (length(y) - 1)
  tibble(term = c(colnames(X), "sigma"), est = th, se = sqrt(diag(Hi)), se_rob = sqrt(diag(Vr)), n = length(y))
}

# (1) heaping and below-truncation shares
s <- s %>% mutate(h63 = abs(height - TR) < 1e-6, below = height < TR - 1e-6)
hp <- s %>% group_by(force) %>% summarise(n = n(), at_160.02 = sum(h63), below_160.02 = sum(below), .groups = "drop")
write_csv(hp, file.path(out, "s5_heaping_by_force.csv"))
note("share below 160.02, all forces", round(mean(s$below), 4))
note("implied N after truncreg drop if published N=6972", round(6972 * (1 - mean(s$below))))
note("63*2.54 == 160.02 in double", isTRUE(63 * 2.54 == 160.02))

# weights exactly as 02_analysis.R
cov <- s %>% filter(force != "WWII") %>% mutate(prov = if_else(region %in% c("WCape", "ECape", "NCape"), "Cape", region))
census <- list(prov = c(Cape = 42.91, Natal = 8.43, Tvl = 35.60, OFS = 13.06),
  occ = c(Middle_class = 4.45, Agriculture = 36.48, Skilled = 46.92, Semi_skilled = 6.29, Unskilled = 5.85),
  town = c(gt10000 = 56.24, lt10000 = 100 - 56.24))
ratio <- function(x, target) { sh <- c(prop.table(table(x))) * 100; as.numeric(target[x] / sh[x]) }
cov <- cov %>% mutate(w = ratio(prov, census$prov) * ratio(occ, census$occ) * ratio(town, census$town), w = w / mean(w))
note("weight range (min/max)", paste(round(range(cov$w), 3), collapse = "/"))
note("Kish effective N / N (colonial+WWI)", round(sum(cov$w)^2 / sum(cov$w^2) / nrow(cov), 3))
prep <- function(d, ref) d %>% mutate(cohort = relevel(droplevels(factor(cohort)), ref = ref),
  region = relevel(factor(region), ref = "WCape"), occ = relevel(factor(occ), ref = "Agriculture"),
  town = relevel(factor(town), ref = "lt10000"))
f_full <- height ~ cohort + region + occ + town + attest

# (2) truncation treatment, weights and SE type on T3 cols 3-6
specs <- list(c3 = list("SAC", "1875_1884"), c4 = list("CMP", "1875_1884"), c5 = list("AOF", "1875_1884"),
              c6 = list("WWI", "1895_1904"))
var2 <- list(base = list(strict = FALSE, c = TR, w = "w"), strict = list(strict = TRUE, c = TR, w = "w"),
             below = list(strict = FALSE, c = 159.385, w = "w"), unweighted = list(strict = FALSE, c = TR, w = NULL))
r2 <- imap_dfr(specs, function(sp, nm) imap_dfr(var2, function(v, vn) {
  d <- prep(filter(cov, force == sp[[1]]), sp[[2]])
  trunc_fit(f_full, d, w = v$w, c = v$c, keep = TR, strict = v$strict) %>% mutate(col = nm, variant = vn) }))
write_csv(r2 %>% filter(str_detect(term, "cohort|town|sigma|attest")) %>% mutate(across(where(is.double), ~ round(.x, 3))),
          file.path(out, "s5_t3_variants.csv"))

# (3) headline proxies: pooled, all five forces, ref 1885-94, unweighted, no covariates (WWII has none)
labs <- c("1865_1874", "1875_1884", "1885_1894", "1895_1904", "1905_1914", "1915_1920")
pool <- s %>% mutate(cohort = relevel(droplevels(factor(cohort)), ref = "1885_1894"),
                     force = relevel(factor(force), ref = "WWI"), wwii = as.integer(force == "WWII"))
by_m1 <- pool %>% mutate(birthyear = if_else(force != "WWII", birthyear - 1, birthyear)) %>%
  filter(between(birthyear, 1865, 1920)) %>%
  mutate(cohort = relevel(cut(birthyear, c(1864, 1874, 1884, 1894, 1904, 1914, 1920), labels = labs), ref = "1885_1894"))
w12 <- filter(pool, force %in% c("WWI", "WWII")) %>% mutate(cohort = relevel(droplevels(factor(cohort)), ref = "1895_1904"))
pv <- list(
  p1_cohort_attest    = list(f = height ~ cohort + attest, d = pool),
  p2_plus_force       = list(f = height ~ cohort + attest + force, d = pool),
  p3_no_attest        = list(f = height ~ cohort, d = pool),
  p4_strict_trunc     = list(f = height ~ cohort + attest, d = pool, strict = TRUE),
  p5_ll_159.385       = list(f = height ~ cohort + attest, d = pool, c = 159.385),
  p6_birthyear_minus1 = list(f = height ~ cohort + attest, d = by_m1),
  p7_col8_wwi_wwii    = list(f = height ~ cohort + attest + wwii, d = w12),
  p8_col8_no_attest   = list(f = height ~ cohort + wwii, d = w12),
  p9_noWWII_cov       = list(f = height ~ cohort + attest + region + occ + town,
                             d = prep(cov, "1885_1894"))
)
r3 <- imap_dfr(pv, function(v, nm) trunc_fit(v$f, v$d, c = v$c %||% TR, keep = TR, strict = v$strict %||% FALSE) %>%
                 mutate(variant = nm))
write_csv(r3 %>% mutate(across(where(is.double), ~ round(.x, 3))), file.path(out, "s5_headline_proxies.csv"))
ma <- pool %>% group_by(force) %>% summarise(n = n(), mean_attest = mean(attest), min = min(year), max = max(year))
write_csv(ma, file.path(out, "s5_attest_by_force.csv"))
d_att <- ma$mean_attest[ma$force == "WWII"] - ma$mean_attest[ma$force == "WWI"]
note("mean attest gap WWII-WWI (years)", round(d_att, 2))
note("published col8: 6.334 + (-0.249)*gap (cf. col2 WWII 0.311)", round(6.334 - 0.249 * d_att, 3))
write_csv(pool %>% group_by(cohort) %>% summarise(mean_attest = mean(attest), share_wwii = mean(wwii)),
          file.path(out, "s5_attest_by_cohort.csv"))

# (6) S2-8: non-adjacent repeat enlistments (name + surname + birth year), counts only
f <- dpath("P09_FIM", "original", "FM White living standards", "Whitelivingstandards_7July.xlsx")
D <- read_excel(f, sheet = "Data", col_types = "text") %>%
  transmute(src = Source, nm = str_to_lower(str_squish(paste(Names, Surname))),
            by = suppressWarnings(as.numeric(Birthyear)), rep = suppressWarnings(as.numeric(Repeat)),
            region = Region, calling = Calling)
sa <- c("Western Cape", "Eastern Cape", "Northern Cape", "Natal", "Orange Free State", "Transvaal")
dup <- D %>% filter(!is.na(by), nchar(nm) > 3) %>% group_by(nm, by) %>% mutate(k = n(), ord = row_number()) %>% ungroup()
unfl <- dup %>% filter(k > 1, ord > 1, is.na(rep) | rep != 1)
note("rows sharing name+birthyear with another row", sum(dup$k > 1))
note("later copies not flagged Repeat (all)", nrow(unfl))
note("later unflagged copies, SA-born", sum(unfl$region %in% sa))
note("Repeat==1 flagged rows", sum(D$rep == 1, na.rm = TRUE))
write_csv(unfl %>% filter(region %in% sa) %>% count(src), file.path(out, "s5_unflagged_repeats_by_source.csv"))

# (7) S2-9: callings containing Excel wildcards
note("analysis-sample (colonial+WWI) callings with * or ?", sum(str_detect(coalesce(cov$calling, ""), "[*?]")))
note("Data rows with * or ? in calling", sum(str_detect(coalesce(D$calling, ""), "[*?]")))

write_csv(bind_rows(log), file.path(out, "s5_checks_log.csv"))
print(bind_rows(log), n = 50)
