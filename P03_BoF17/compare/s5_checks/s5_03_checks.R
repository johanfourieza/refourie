# S5 check 3: (a) trend vs level vs cycle correlations from the in-sheet series; (b) serial-correlation-adjusted
# significance (Pyper-Peterman 1998 effective N); (c) 'other countries' workings; (d) Mealies analysis vs Table 1
suppressMessages({library(tidyxl); library(readxl); library(dplyr); library(tidyr)})
source("tools/paths.R")
g15 <- dpath("P03_BoF17","original","Boshoff Fourie Globalisation","Globalisation data.xlsx")
s <- read_excel(g15, sheet = "SA & UK graphs", range = "C1:J79") |> suppressMessages()
names(s) <- c("year","cape_tr","sa_tr","uk_tr","y2","cape_cy","sa_cy","uk_cy")
pp <- function(x, y) { # Pyper-Peterman effective N, lags up to n/5
  n <- length(x); L <- floor(n/5); ax <- acf(x, L, plot=FALSE)$acf[-1]; ay <- acf(y, L, plot=FALSE)$acf[-1]
  ne <- 1 / (1/n + (2/n) * sum((n - 1:L)/n * ax * ay)); ne <- min(max(ne, 3), n)
  r <- cor(x, y); t <- r * sqrt((ne - 2)/(1 - r^2)); c(r = r, n = n, n_eff = ne, p_conv = 2*pt(-abs(r*sqrt((n-2)/(1-r^2))), n-2), p_pp = 2*pt(-abs(t), ne-2)) }
out <- list()
for (sp in list(c(1836,1871,"pre"), c(1872,1913,"post"))) {
  d <- s |> filter(year >= as.numeric(sp[1]), year <= as.numeric(sp[2]))
  out[[length(out)+1]] <- c(spec=paste0("trend_SA_",sp[3]), pp(d$sa_tr, d$uk_tr))
  out[[length(out)+1]] <- c(spec=paste0("trend_Cape_",sp[3]), pp(d$cape_tr, d$uk_tr))
  out[[length(out)+1]] <- c(spec=paste0("cycle_SA_",sp[3]), pp(d$sa_cy, d$uk_cy))
  out[[length(out)+1]] <- c(spec=paste0("dtrend_SA_",sp[3]), pp(diff(d$sa_tr), diff(d$uk_tr)))
}
# rebuild cycles (repro_r) for comparison with in-sheet cycles
rc <- read.csv("P03_BoF17/repro_r/output/fig3_cycles.csv") |> inner_join(s, by = "year")
out[[length(out)+1]] <- c(spec="cycle_rebuild_vs_insheet_SA", r = cor(rc$sa, rc$sa_cy), n = nrow(rc), n_eff=NA, p_conv=NA, p_pp=NA)
out[[length(out)+1]] <- c(spec="cycle_rebuild_vs_insheet_UK", r = cor(rc$uk, rc$uk_cy), n = nrow(rc), n_eff=NA, p_conv=NA, p_pp=NA)
res <- bind_rows(lapply(out, function(v) as.data.frame(t(v)))); print(res, digits = 3)
write.csv(res, dscratch("P03_BoF17","compare","s5_trendcorr.csv"), row.names = FALSE)
# (c) Sheet1 headers ('other countries')
sh <- xlsx_cells(g15, sheets = "Sheet1") |> filter(row <= 6 | col == 1, row <= 8) |> filter(!is.na(character) | !is.na(formula))
print(as.data.frame(sh |> select(address, character, formula, numeric)), right = FALSE)
# (d) Mealies analysis: what do the 'corr significant' sheets hold?
mea <- dpath("P03_BoF17","original","Boshoff Fourie","Mealies analysis.xlsx")
for (sn in c("corr significant","corr significant clean")) { m <- read_excel(mea, sheet = sn, col_names = FALSE) |> suppressMessages(); cat("\n##", sn, dim(m), "\n"); print(as.data.frame(m[1:min(24,nrow(m)), 1:min(8,ncol(m))])) }
cl <- read.csv("P03_BoF17/claims/claims.csv"); print(cl[grepl("^T1_r[0-9]+_c2$", cl$claim_id), c("claim_id","reported_value","reported_se","reported_stars")])
