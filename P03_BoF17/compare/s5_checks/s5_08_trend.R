# S5 check 8: rebuild the in-sheet 'SA trend'/'UK trend' from the S3 annual log series with CF filters, then the text correlations
suppressMessages({library(mFilter); library(readxl); library(dplyr)})
source("tools/paths.R")
ann <- readRDS(dpath("P03_BoF17","repro_r","_scratch","annual.rds")); print(names(ann))
s <- read_excel(dpath("P03_BoF17","original","Boshoff Fourie Globalisation","Globalisation data.xlsx"), sheet = "SA & UK graphs", range = "C1:F79") |> suppressMessages()
names(s) <- c("year","cape_tr","sa_tr","uk_tr"); d <- inner_join(ann, s, by = "year") |> arrange(year)
sa <- d[[grep("capenatal|sa_rsa|rsa|sa$", names(d), ignore.case = TRUE)[1]]]; uk <- d[[grep("^ln_uk", names(d), ignore.case = TRUE)[1]]]
cat("UK NA years:", d$year[is.na(uk)], "(linearly interpolated for the filter)
"); uk <- approx(d$year, uk, d$year, rule = 2)$y
cat("using columns:", grep("capenatal|sa_rsa|rsa|sa$", names(d), ignore.case = TRUE, value = TRUE)[1], grep("^ln_uk", names(d), ignore.case = TRUE, value = TRUE)[1], "\n")
tr <- function(x, lo, hi) as.numeric(x - cffilter(x, pl = lo, pu = hi, root = TRUE, drift = TRUE)$cycle)
spl <- function(a, b) c(pre = cor(a[d$year <= 1871], b[d$year <= 1871]), post = cor(a[d$year >= 1872], b[d$year >= 1872]))
for (b in list(c(2, 8), c(2, 10), c(2, 50))) { ts <- tr(sa, b[1], b[2]); tu <- tr(uk, b[1], b[2])
  cat(sprintf("band %d-%d: fit to sheet SA %.3f UK %.3f | corr pre %.3f post %.3f\n", b[1], b[2], cor(ts, d$sa_tr), cor(tu, d$uk_tr), spl(ts, tu)[1], spl(ts, tu)[2])) }
cat(sprintf("in-sheet trends: pre %.3f post %.3f | rebuild log levels: pre %.3f post %.3f\n", spl(d$sa_tr, d$uk_tr)[1], spl(d$sa_tr, d$uk_tr)[2], spl(sa, uk)[1], spl(sa, uk)[2]))
