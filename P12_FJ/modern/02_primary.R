# P12_FJ S6 02_primary.R -- verification (corrections off -> S3 Table 5) and the primary analysis of card §4:
# specs 2 and 3 on the shared complete-case sample, CV3 jackknife (full-sample centred, t(G-1)), DiD_k (descriptive), P rows.
source(here::here("P12_FJ", "modern", "00_common.R"))
scr <- dscratch("P12_FJ", "modern"); out <- here::here("P12_FJ", "modern", "output")
V <- readRDS(file.path(scr, "variants.rds"))
prep <- function(d) { d <- add_int(d); d[complete.cases(d[, c("doc","race", X3)]), ] }

# --- verification: uncorrected build, district-clustered CR1 = S3 Table 5 ---
s3 <- read.csv(here::here("P12_FJ", "repro_r", "output", "table5_all_se_subsample.csv"))
du <- prep(V$uncorr); chk <- NULL
for (sp in c("c2","c3")) { f <- fit1(fml(if (sp == "c2") X2 else X3), du); ct <- coeftable(summary(f, vcov = ~town))
  for (t in c("Coloured_x_Pandemic","Black_x_Pandemic","Pandemic_x_Street_road_and_stad")) if (t %in% rownames(ct)) {
    r <- s3[s3$spec == sp & s3$term == t, ]
    chk <- rbind(chk, data.frame(spec = sp, term = t, s6_est = ct[t, 1], s3_est = r$est, s6_se = ct[t, 2], s3_se = r$se_cluster, n_s6 = nobs(f), n_s3 = r$n)) } }
chk$match <- abs(chk$s6_est - chk$s3_est) < 1e-6 & abs(chk$s6_se - chk$s3_se) < 1e-6 & chk$n_s6 == chk$n_s3
write.csv(chk, file.path(out, "check_uncorrected_vs_S3.csv"), row.names = FALSE); print(chk)

# --- primary ---
d <- prep(V$main)
t0 <- Sys.time()
s2 <- run_spec(d, X2, want_did = TRUE)
s3m <- run_spec(d, X3)
cat("primary fits:", format(Sys.time() - t0), "\n")
R <- rbind(cbind(spec = "c2", cv3(s2$theta[c("Coloured_x_Pandemic","Black_x_Pandemic")], s2$loo[, c("Coloured_x_Pandemic","Black_x_Pandemic"), drop = FALSE], 4)),
           cbind(spec = "c3", cv3(s3m$theta[c("Coloured_x_Pandemic","Black_x_Pandemic")], s3m$loo[, c("Coloured_x_Pandemic","Black_x_Pandemic"), drop = FALSE], 4)))
U <- cbind(spec = "c3", cv3(s3m$theta[c("Pandemic_x_Street_road_and_stad","Street_road_and_stad","theta_U")], s3m$loo[, c("Pandemic_x_Street_road_and_stad","Street_road_and_stad","theta_U")], 3))
inf <- rbind(cbind(family = "R", R), cbind(family = "U", U))
ff <- function(s, t) { if (t == "theta_U") t <- c("Street_road_and_stad","Pandemic_x_Street_road_and_stad"); any(s$fail_full[t]) || any(s$fail_loo[t] > 0) || any(!is.finite(s$loo[, intersect(t, colnames(s$loo))])) }
inf$fail <- mapply(function(sp, t) ff(if (sp == "c2") s2 else s3m, t), inf$spec, inf$term)
inf$loo_min <- mapply(function(sp, t) min((if (sp == "c2") s2 else s3m)$loo[, t]), inf$spec, inf$term)
inf$loo_max <- mapply(function(sp, t) max((if (sp == "c2") s2 else s3m)$loo[, t]), inf$spec, inf$term)
inf$n <- ifelse(inf$spec == "c2", s2$n, s3m$n)
print(inf)
# DiD (descriptive; no inferential role)
G <- s2$G; jk <- function(th, l) sqrt((G - 1) / G * colSums(sweep(l, 2, th)^2))
H2 <- data.frame(quantity = names(s2$did), est_pp = s2$did, jk_se = jk(s2$did, s2$did_loo), loo_min = apply(s2$did_loo, 2, min), loo_max = apply(s2$did_loo, 2, max), row.names = NULL)
print(H2)
# P rows: Paarl reference person, spec 2
f2 <- s2$fit; ref <- d[1, ]; for (v in c("Coloured","Black","Pandemic", X3)) ref[[v]] <- 0; ref$town <- "Paarl"
pp <- function(r, q) { z <- ref; z$Coloured <- as.integer(r == "C"); z$Black <- as.integer(r == "B"); z$Pandemic <- q; 100 * predict(f2, newdata = add_int(z), type = "response") }
Pr <- data.frame(row = paste0("P-", letters[1:6]), source = paste0("TXT_p9_", letters[1:6]), race = rep(c("W","C","B"), 2), pandemic = rep(0:1, each = 3),
                 stated = c(93.4, 85.0, 69.8, 57.7, 21.0, 6.2), lo = c(90.4, 82.0, 66.8, 54.7, 18.9, 5.58), hi = c(96.4, 88.0, 72.8, 60.7, 23.1, 6.82))
Pr$est <- mapply(pp, Pr$race, Pr$pandemic)
Pr$paarl_coef_ok <- "factor(town)Paarl" %in% names(coef(f2)) && is.finite(coef(f2)["factor(town)Paarl"])
print(Pr)
# cluster diagnostics
cs <- table(d$town)
diag <- data.frame(G = length(cs), n = nrow(d), min = min(cs), median = median(cs), max = max(cs), largest = names(cs)[which.max(cs)], largest_share = max(cs) / nrow(d),
                   conv_c2 = isTRUE(s2$fit$convStatus), conv_c3 = isTRUE(s3m$fit$convStatus), collin_c2 = paste(s2$fit$collin.var, collapse = ";"), collin_c3 = paste(s3m$fit$collin.var, collapse = ";"),
                   extreme_fitted_c2 = sum(fitted(s2$fit) < 1e-10 | fitted(s2$fit) > 1 - 1e-10), extreme_fitted_c3 = sum(fitted(s3m$fit) < 1e-10 | fitted(s3m$fit) > 1 - 1e-10))
print(diag)
loo <- rbind(data.frame(spec = "c2", town = rownames(s2$loo), s2$loo, check.names = FALSE) |> tidyr::pivot_longer(-c(spec, town)),
             data.frame(spec = "c3", town = rownames(s3m$loo), s3m$loo, check.names = FALSE) |> tidyr::pivot_longer(-c(spec, town)))
write.csv(loo, file.path(out, "primary_loo.csv"), row.names = FALSE)
write.csv(as.data.frame(cs), file.path(out, "primary_cluster_sizes.csv"), row.names = FALSE)
saveRDS(list(inf = inf, H2 = H2, Pr = Pr, diag = diag), file.path(scr, "primary.rds"))
saveRDS(list(inf = inf, H2 = H2, Pr = Pr, diag = diag), file.path(out, "primary_aggregate.rds"))
