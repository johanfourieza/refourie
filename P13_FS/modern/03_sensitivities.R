# P13_FS S6 03_sensitivities.R -- Table 6 sensitivities 13-26 and H3-ext (card sections 4C, 5). Reported, never voting.
suppressMessages({library(dplyr); library(readr); library(sandwich); library(lmtest); library(AER)})
source(here::here("tools", "paths.R"))
scr <- dscratch("P13_FS", "modern"); out <- here::here("P13_FS", "modern", "output")
z <- readRDS(file.path(scr, "h2.rds")); a <- z$a; d <- z$d; m <- z$m; s570 <- z$s570; XS <- z$XS
fml <- function(y, xs = XS) as.formula(paste(y, "~", paste(xs, collapse = " + ")))
R <- list()
rep_lm <- function(no, what, mod, term = "num_slaves", note = "") {
  b <- coef(mod)[term]; h <- hatvalues(mod)
  se3 <- tryCatch(sqrt(suppressWarnings(vcovHC(mod, "HC3"))[term, term]), error = function(e) NA_real_)
  se1 <- sqrt(vcovHC(mod, "HC1")[term, term]); dfr <- df.residual(mod)
  R[[length(R) + 1]] <<- tibble(sens = no, what, term, b = unname(b), se_hc3 = se3, p_hc3 = 2 * pt(-abs(b / se3), dfr),
                                se_hc1 = se1, p_hc1 = 2 * pt(-abs(b / se1), dfr), N = nobs(mod), max_lev = max(h), note)
}
add <- function(no, what, term, b, se = NA, p = NA, N = NA, note = "")
  R[[length(R) + 1]] <<- tibble(sens = no, what, term, b, se_hc3 = NA, p_hc3 = NA, se_hc1 = se, p_hc1 = p, N, max_lev = NA, note)
# 13 published dependent variable ldebt (inheritance included) on the stored 570 parent sample
m13 <- lm(fml("ldebt"), data = droplevels(a[s570, ])); rep_lm(13, "ldebt (inheritance incl.), stored 570, listwise", m13)
# 14 covariate versions
XSb <- replace(XS, XS == "bond1", "bond"); XSy <- replace(XS, XS == "dec", "dec_y")
rep_lm(14, "bond in place of bond1", lm(fml("y", XSb), data = d))
rep_lm(14, "decades from year", lm(fml("y", XSy), data = droplevels(d)))
rep_lm(14, "bond and year decades", lm(fml("y", replace(XSb, XSb == "dec", "dec_y")), data = droplevels(d)))
# 15 Tobit left = 0 on the primary sample (conventional SEs; diagnostic)
t15 <- tobit(fml("y"), left = 0, data = d); ct <- coef(summary(t15))
add(15, "AER::tobit(left = 0), primary sample", "num_slaves", ct["num_slaves", 1], ct["num_slaves", 2], ct["num_slaves", 4], nobs(t15), "conventional ML SE; 0 censored")
# 16 participation (matched, complete covariates, zero-debt included; D-missing excluded)
pp <- a[a$match == 1 & a$status != "D-missing", ]; pp$any <- as.numeric(pp$status == "positive")
pp <- droplevels(pp[complete.cases(pp[, XS]), ])
lg <- glm(fml("any"), family = binomial, data = pp)
bl <- coef(lg)["num_slaves"]; sel <- sqrt(vcovHC(lg, "HC0")["num_slaves", "num_slaves"])
ame <- mean(bl * dlogis(predict(lg, type = "link")))
add(16, "participation logit: odds ratio per slave", "num_slaves", exp(bl), NA, 2 * pnorm(-abs(bl / sel)), nobs(lg), sprintf("log-odds %.4f robust SE %.4f; share with debt %.3f", bl, sel, mean(pp$any)))
add(16, "participation logit: AME per slave", "num_slaves", ame, NA, NA, nobs(lg), "average marginal effect on Pr(any economic debt)")
rep_lm(16, "participation LPM", lm(fml("any"), data = pp), note = "different-estimand; changed population (A4d)")
add(16, "positive-debt part = primary OLS", "num_slaves", coef(m)["num_slaves"], NA, NA, nobs(m), "see H2_primary.csv")
# 17 real column
r <- a[a$`_est_tobitin` == 1 & !is.na(a$`_est_tobitin`), ]
rep_lm(17, "real: ldebtin, stored 178", lm(fml("ldebtin"), data = droplevels(r)))
r$yin <- ifelse(r$status == "positive", log(r$D_noinh * r$debt_infl / r$debt_value), NA)
rep_lm(17, "real: inheritance excluded", lm(fml("yin"), data = droplevels(r[is.finite(r$yin), ])))
rep_lm(18, "children dropped", lm(fml("y", setdiff(XS, "children")), data = d))
d$lslv <- log1p(d$num_slaves); rep_lm(19, "log(1 + slaves)", lm(fml("y", replace(XS, XS == "num_slaves", "lslv")), data = d), term = "lslv")
d$sg <- cut(d$num_slaves, c(-1, 0, 5, 10, 24, Inf), labels = c("0", "1-5", "6-10", "11-24", "25+"))
m19 <- lm(fml("y", replace(XS, XS == "num_slaves", "sg")), data = d)
for (g in c("sg1-5", "sg6-10", "sg11-24", "sg25+")) rep_lm(19, paste("slave group dummy", g, "vs 0"), m19, term = g)
rep_lm(20, "bond1 and both dropped", lm(fml("y", setdiff(XS, c("bond1", "both"))), data = d))
r3 <- read_csv(here::here("P13_FS", "repro_r", "results_r.csv"), show_col_types = FALSE) |> filter(claim_id == "T6A_slaves_nom_coef")
add(21, "S3 rebuild Panel A as locked (Tobit with zeros, N 736)", "num_slaves", r3$value, r3$se, NA, r3$n, "conventional ML SE")
# 22 influence
for (dc in levels(d$dec)) rep_lm(22, paste("leave out decade", dc), lm(fml("y"), data = droplevels(d[d$dec != dc, ])))
cut99 <- quantile(d$num_slaves, 0.99, type = 7)
rep_lm(22, sprintf("num_slaves >= p99 (%.0f) removed", cut99), lm(fml("y"), data = droplevels(d[d$num_slaves < cut99, ])), note = paste("dropped", sum(d$num_slaves >= cut99)))
dfb <- dfbeta(m)[, "num_slaves"]
add(22, "max |DFBETA| num_slaves (unscaled)", "num_slaves", max(abs(dfb[is.finite(dfb)])), N = nobs(m), note = paste("mooc", d$mooc[which.max(abs(dfb))]))
# 23 inference ladder on the primary point estimate
b0 <- coef(m)["num_slaves"]; dfr <- df.residual(m)
for (ty in c("const", "HC1", "HC2", "HC3")) {
  se <- tryCatch(sqrt(suppressWarnings(vcovHC(m, ty))["num_slaves", "num_slaves"]), error = function(e) NA_real_)
  add(23, paste("SE type", ty), "num_slaves", b0, se, 2 * pt(-abs(b0 / se), dfr), nobs(m), if (ty == "const") "conventional" else "")
}
# wild bootstrap, Rademacher, null imposed, B = 9,999; studentized with HC1 (HC3 undefined at h = 1; DEVIATIONS D3)
X <- model.matrix(m); y <- model.response(model.frame(m)); j <- which(colnames(X) == "num_slaves")
Xr <- X[, -j]; fr <- lm.fit(Xr, y); ur <- fr$residuals; yr <- y - ur
XtXi <- solve(crossprod(X)); A <- XtXi %*% t(X); aj <- A[j, ]
hcse <- function(E) sqrt(colSums((aj^2) * E^2) * nrow(X) / (nrow(X) - ncol(X)))
e0 <- residuals(m); t_obs <- b0 / hcse(matrix(e0))
RNGkind("L'Ecuyer-CMRG"); set.seed(20261012); Bw <- 9999
V <- matrix(sample(c(-1, 1), nrow(X) * Bw, replace = TRUE), nrow(X))
Ys <- yr + ur * V; Bs <- A %*% Ys; Es <- Ys - X %*% Bs
tb <- Bs[j, ] / hcse(Es)
add(23, "wild bootstrap (Rademacher, null imposed, HC1-studentized), B = 9999", "num_slaves", b0, NA, mean(abs(tb) >= abs(t_obs)), nobs(m), sprintf("t_obs %.3f", t_obs))
# 24 dependence
cs <- table(d$dec)
add(24, "decade clusters G", "num_slaves", length(cs), N = nobs(m), note = paste("sizes min/med/max", paste(quantile(as.numeric(cs), c(0, .5, 1)), collapse = "/")))
add(24, "household_iden clusters G", "num_slaves", length(unique(d$household_iden)), N = nobs(m), note = "one inventory per household_iden: equals HC case")
cr2 <- tryCatch({
  library(clubSandwich); vc <- vcovCR(m, cluster = d$dec, type = "CR2"); ctt <- coef_test(m, vcov = vc, test = "Satterthwaite", coefs = "num_slaves")
  add(24, "CR2 + Satterthwaite (decade)", "num_slaves", b0, ctt$SE, ctt$p_Satt, nobs(m), sprintf("df %.2f", ctt$df_Satt)); "ok"
}, error = function(e) { add(24, "CR2 + Satterthwaite (decade)", "num_slaves", b0, NA, NA, nobs(m), paste("failed:", conditionMessage(e))); "fail" })
wcb <- tryCatch({
  library(fwildclusterboot); dqrng::dqset.seed(20261012); set.seed(20261012)
  bt <- boottest(m, param = "num_slaves", clustid = "dec", B = 9999, type = "webb")
  add(24, "wild cluster bootstrap, Webb weights (decade), B = 9999", "num_slaves", b0, NA, pval(bt), nobs(m), sprintf("CI %.4f to %.4f", confint(bt)[1], confint(bt)[2])); "ok"
}, error = function(e) { add(24, "wild cluster bootstrap Webb (decade)", "num_slaves", b0, NA, NA, nobs(m), paste("failed:", conditionMessage(e))); "fail" })
# 25 leverage diagnostics
h <- hatvalues(m); hi <- which(h > 0.5)
add(25, "observations with h > 0.5", "num_slaves", length(hi), N = nobs(m), note = paste(sprintf("%s (dec %s, h=%.4f)", d$mooc[hi], d$dec[hi], h[hi]), collapse = "; "))
# H3-ext (4C) and sensitivity 26: three-variable wealth index percentile, copied from repro_r/02_analysis.R
cc0 <- complete.cases(a[, c("num_slaves", "num_prop", "cash1")])
pc <- prcomp(a[cc0, c("num_slaves", "num_prop", "cash1")], scale. = TRUE)
sc <- pc$x[, 1] * sign(cor(pc$x[, 1], a$num_slaves[cc0]))
a$wealth <- NA_real_; a$wealth[cc0] <- ceiling(100 * rank(sc, ties.method = "average") / sum(cc0))
a$ly_nom <- ifelse(a$debt_value > 0, log(a$debt_value), 0); a$decade <- floor(a$year / 10) * 10
xB <- c("age", "male", "married", "children", "farmer", "wealth", "bond", "both", "comp", "church", "wees")
dB <- a[a$match == 1, ]; dB <- dB[complete.cases(dB[, c("ly_nom", xB, "decade")]), ]; dB <- dB[dB$ly_nom > 0, ]; dB$dec3 <- factor(dB$decade)
mB <- lm(fml("ly_nom", c(xB, "dec3")), data = dB)
seB <- tryCatch(sqrt(suppressWarnings(vcovHC(mB, "HC3"))["wealth", "wealth"]), error = function(e) NA_real_)
h3 <- tibble(row = "H3-ext", b = coef(mB)["wealth"], se_hc3 = seB, ci_lo = b - qt(.975, df.residual(mB)) * seB, ci_hi = b + qt(.975, df.residual(mB)) * seB,
             p = 2 * pt(-abs(b / seB), df.residual(mB)), N = nobs(mB), max_lev = max(hatvalues(mB)), verdict = "different-estimand")
d$wealth <- a$wealth[match(d$mooc, a$mooc)]
rep_lm(26, "3-variable wealth percentile on S_A, y = log(D_noinh)", lm(fml("y", c(setdiff(XS, c("num_slaves", "num_prop", "cash1")), "wealth")), data = d), term = "wealth",
       note = "different-estimand")
sens <- bind_rows(R)
write_csv(sens, file.path(out, "sensitivities_H2H3.csv")); write_csv(h3, file.path(out, "H3_ext.csv"))
print(as.data.frame(sens), digits = 4); print(as.data.frame(h3))
