# S5 check 5: sensitivity of the Kimberley headline cells (T1 wheat/mealies; T2 wheat/mealies) to unstated choices.
# Reuses the S3 panel (read-only, from D: scratch); does not modify repro_r.
suppressMessages({library(dplyr)})
source("tools/paths.R")
panel <- readRDS(dpath("P03_BoF17","repro_r","_scratch","panel_raw.rds"))
grid <- expand.grid(year = 1897:1906, month = 1:12) |> arrange(year, month)
lp <- function(town, prod) { z <- panel |> filter(town == !!town, product == prod); log(z$price[match(paste(grid$year, grid$month), paste(z$year, z$month))]) }
dl <- function(v) c(NA, diff(v))
dgap <- function(v) { o <- rep(NA, length(v)); i <- which(is.finite(v)); o[i[-1]] <- diff(v[i]); o }  # difference across gaps
interp <- function(v) { i <- which(is.finite(v)); out <- v; out[min(i):max(i)] <- approx(i, v[i], min(i):max(i))$y; out }
deseas <- function(d) { ok <- is.finite(d); r <- rep(NA, length(d)); r[ok] <- resid(lm(d[ok] ~ factor(grid$month[ok]))); r }
cc <- function(a, b, sub = TRUE) { ok <- is.finite(a) & is.finite(b) & sub; n <- sum(ok); r <- cor(a[ok], b[ok]); c(r = r, se = sqrt((1-r^2)/(n-2)), n = n) }
pss <- function(y, x, p) { D <- data.frame(dy = dl(y), y1 = c(NA, head(y,-1)), x1 = c(NA, head(x,-1)))
  for (j in seq_len(p)) { D[[paste0("dy",j)]] <- c(rep(NA,j), head(dl(y),-j)); D[[paste0("dx",j)]] <- c(rep(NA,j), head(dl(x),-j)) }
  D <- D[complete.cases(D),]; rhs <- setdiff(names(D),"dy"); m1 <- lm(reformulate(rhs,"dy"), D); m0 <- lm(reformulate(setdiff(rhs,c("y1","x1")),"dy"), D)
  c(F = anova(m0,m1)$F[2], n = nrow(D), aic = AIC(m1)) }
out <- list()
for (pr in c("Wheat","Mealies")) {
  k <- lp("Kimberley", pr); ct <- lp("Cape Town", pr)
  t1 <- list(base_consecutive = cc(dl(k), dl(ct)), diff_across_gaps = cc(dgap(k), dgap(ct)),
             interpolated = cc(dl(interp(k)), dl(interp(ct))), deseasonalised = cc(deseas(dl(k)), deseas(dl(ct))),
             sub_1897_1901 = cc(dl(k), dl(ct), grid$year <= 1901), sub_1902_1906 = cc(dl(k), dl(ct), grid$year >= 1902))
  for (s in names(t1)) out[[length(out)+1]] <- data.frame(table = "T1", product = pr, spec = s, value = t1[[s]]["r"], se = t1[[s]]["se"], n = t1[[s]]["n"])
  for (dir in c("town_dep","cape_dep")) for (ip in c(FALSE, TRUE)) for (p in 0:3) {
    y <- if (dir == "town_dep") k else ct; x <- if (dir == "town_dep") ct else k
    if (ip) { y <- interp(y); x <- interp(x) }
    f <- pss(y, x, p); out[[length(out)+1]] <- data.frame(table = "T2", product = pr, spec = paste0(dir, ifelse(ip,"_interp",""), "_p", p), value = f["F"], se = NA, n = f["n"], aic = f["aic"])
  }
}
res <- bind_rows(out); rownames(res) <- NULL; res$above_5.08 <- ifelse(res$table == "T2", res$value > 5.08, NA)
print(res, digits = 3)
write.csv(res, "P03_BoF17/compare/s5_checks/s5_05_kimberley_out.csv", row.names = FALSE)
