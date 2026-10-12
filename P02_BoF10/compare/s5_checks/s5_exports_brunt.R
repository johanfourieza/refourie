# S5 P02_BoF10: rebuild the authors' filter (CF 12-40, I(1)+drift) for series with no surviving MF22 (exports, Brunt); remaining T4/T5 rows
suppressPackageStartupMessages({library(tidyverse); library(readxl); library(mFilter); library(here); library(zoo)})
source(here("tools","paths.R")); source(here("P02_BoF10","compare","s5_checks","uecm_fn.R"))
b <- dpath("P02_BoF10","original","Boshoff Fourie Ships","Business Cycle Cape Colony")
cz <- suppressWarnings(read_excel(file.path(b, "causality for med freq.XLS"), 1) |> mutate(across(everything(), as.numeric)))
ag <- suppressWarnings(read_excel(file.path(b, "agricultural output data for eviews.xls"), 1) |> mutate(across(everything(), as.numeric)))
mfz <- function(yr, v) { ok <- !is.na(v); out <- rep(NA_real_, length(v)); out[ok] <- cffilter(log(v[ok]), 12, 40, root = TRUE, drift = TRUE)$cycle; out }
w <- mfz(ag$YEAR, ag$WHEAT); cat("WHEAT col -> WHEATMF22: cor", cor(w, cz$WHEATMF22, use = "c"), " max|diff|", max(abs(w - cz$WHEATMF22), na.rm = T), "\n")
s <- read_excel(file.path(b, "ships for eviews FROM 1652.xls"), 1, col_names = FALSE, skip = 1)[, 1:2] |> setNames(c("year","ships")) |> mutate(across(everything(), as.numeric)) |> filter(year %in% 1701:1793)
cat("ships -> SHIPSMF22 max|diff|", max(abs(mfz(s$year, s$ships) - cz$SHIPSMF22[match(s$year, cz$OBS)]), na.rm = T), "\n")
d <- read_csv(dscratch("P02_BoF10","repro_r","series.csv"), show_col_types = FALSE) |> filter(year %in% cz$OBS)
ex <- d$wheat_exports; r <- range(which(!is.na(ex))); exi <- ex; exi[r[1]:r[2]] <- na.approx(ex[r[1]:r[2]])
SH <- cz$SHIPSMF22[match(d$year, cz$OBS)]
EX <- mfz(d$year, exi); VR <- mfz(d$year, d$wheat_reaped); BR <- mfz(d$year, d$wheat_brunt)
rows <- list(
 T4_r7_F = list(EX, SH, 18.97), T4_r8_F = list(SH, EX, 25.02), T5_r5_coef = list(EX, SH, 2.88), T5_r6_coef = list(SH, EX, 0.73),
 T4_r3_uncorrVDR = list(VR, SH, 61.77), T4_r5_F_rebuildBrunt = list(BR, SH, 24.77), T4_r6_F_rebuildBrunt = list(SH, BR, 30.5),
 T4_r10_F = list(cz$SHIPSMF22, cz$TOTALVINESMF22, 5.68), T4_r12_F = list(cz$SHIPSMF22, cz$TOTALWINEMF22, 1.16),
 T5_r7_coef = list(cz$TOTALVINESMF22, cz$SHIPSMF22, 1.46), T5_r8_coef = list(cz$SHIPSMF22, cz$TOTALVINESMF22, 0.44))
R <- imap_dfr(rows, \(z, id) { u <- uecm(z[[1]], z[[2]], 5); tibble(id, pub = z[[3]], F = u["F"], theta = u["theta"], se = u["se"], n = u["n"]) })
print(as.data.frame(R), digits = 4)
write_csv(R, here("P02_BoF10","compare","s5_checks","exports_brunt_p5.csv"))
# look for a Brunt series in the surviving workbooks
for (f in list.files(b, "\.(xls|XLS|xlsx)$", full.names = TRUE)) for (sh in tryCatch(excel_sheets(f), error = \(e) character())) {
  h <- tryCatch(suppressMessages(read_excel(f, sh, col_names = FALSE, n_max = 4)), error = \(e) NULL)
  if (!is.null(h) && any(grepl("brunt", c(sh, unlist(h)), ignore.case = TRUE))) cat("BRUNT hit:", basename(f), "/", sh, "\n") }
