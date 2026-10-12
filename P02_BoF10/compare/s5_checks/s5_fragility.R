# S5 P02_BoF10: fragility of headline T4_r3/T5_r1 to the filter approximation and lag order; search for a Brunt series
suppressPackageStartupMessages({library(tidyverse); library(readxl); library(mFilter); library(here)})
source(here("tools","paths.R")); source(here("P02_BoF10","compare","s5_checks","uecm_fn.R"))
b <- dpath("P02_BoF10","original","Boshoff Fourie Ships","Business Cycle Cape Colony")
cz <- suppressWarnings(read_excel(file.path(b, "causality for med freq.XLS"), 1) |> mutate(across(everything(), as.numeric)))
ag <- suppressWarnings(read_excel(file.path(b, "agricultural output data for eviews.xls"), 1) |> mutate(across(everything(), as.numeric)))
s <- suppressMessages(read_excel(file.path(b, "ships for eviews FROM 1652.xls"), 1, col_names = FALSE, skip = 1))[, 1:2] |> setNames(c("year","ships")) |> mutate(across(everything(), as.numeric)) |> filter(year %in% 1701:1793)
mfz <- function(v) { ok <- !is.na(v); out <- rep(NA_real_, length(v)); out[ok] <- cffilter(log(v[ok]), 12, 40, root = TRUE, drift = TRUE)$cycle; out }
W2 <- mfz(ag$WHEAT); S2 <- mfz(s$ships)
out <- bind_rows(
  map_dfr(3:6, \(p) tibble(scenario = paste0("authors MF22, p=", p), F = uecm(cz$WHEATMF22, cz$SHIPSMF22, p)["F"], theta = uecm(cz$WHEATMF22, cz$SHIPSMF22, p)["theta"])),
  map_dfr(3:6, \(p) tibble(scenario = paste0("R CF(I1,drift) re-filter, p=", p), F = uecm(W2, S2, p)["F"], theta = uecm(W2, S2, p)["theta"])))
print(as.data.frame(out), digits = 4); write_csv(out, here("P02_BoF10","compare","s5_checks","fragility_T4r3.csv"))
for (f in list.files(b, "[.](xls|XLS|xlsx)$", full.names = TRUE, recursive = TRUE)) for (sh in tryCatch(excel_sheets(f), error = \(e) character())) {
  h <- tryCatch(suppressMessages(read_excel(f, sh, col_names = FALSE, n_max = 4)), error = \(e) NULL)
  if (any(grepl("brunt", c(sh, unlist(h)), ignore.case = TRUE))) cat("BRUNT hit:", basename(f), "/", sh, "\n") }
cat("done search\n")
