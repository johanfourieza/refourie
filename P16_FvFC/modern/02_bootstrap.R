# P16_FvFC S6 -- 02_bootstrap.R: central cluster bootstrap (card §4).
# B = 9,999 (seed 20261011, L'Ecuyer-CMRG, one stream per draw); equal-probability resampling of
# coarse name-key clusters; both pooled PCAs re-estimated in every draw; common draws feed every
# quantity. If any endpoint of a family row is flagged by the Monte Carlo rule, draws 10,000-39,999
# are added with the same seed (the 39,999 run contains the 9,999 run as a prefix).
# Outputs: D: scratch boot_central.rds; output/boot_flags_9999.csv, output/per_year.csv

source(here::here("P16_FvFC", "modern", "00_common.R"))
args <- commandArgs(trailingOnly = TRUE)
B1 <- 9999; B2 <- 39999
if (length(args) && args[1] == "test") B1 <- 120

C  <- readRDS(file.path(SCR, "central.rds")); hh <- C$hh; cen <- C$cen
P  <- prep(hh, key = "key")
trk <- which(hh$year == 1663 & hh$farmer)                       # 1663 farmers (5C item 25 tail diagnostics)
streams <- make_streams(if (B1 == 120) B1 else B2)

M <- run_boot(P, 1:B1, streams, "cluster", extras = TRUE, track_rows = trk, label = "central B1")
if (B1 == 120) { print(dim(M)); print(summary(draw_rows(M))); print(table(M[, "fail_far"])); quit(save = "no") }
R <- draw_rows(M)
A <- lapply(names(ROW_NEEDS), \(r) assess_row(r, M, R, cen)); names(A) <- names(ROW_NEEDS)
fl <- imap_dfr(A, \(a, r) tibble(row = r, endpoint = names(a$ep), value = a$ep, mcse = a$mcse[names(a$ep)],
                                 verdict_relevant = names(a$ep) %in% VR_EP(r),
                                 flagged = names(a$ep) %in% names(a$flag)[a$flag]))
write_csv(fl, file.path(OUT, "boot_flags_9999.csv"))
print(fl, n = 50)
esc <- names(A)[sapply(A, \(a) any(a$flag))]
cat("Rows flagged at B = 9,999:", if (length(esc)) paste(esc, collapse = ", ") else "none", "\n")

M2 <- NULL
if (length(esc)) {
  M2 <- run_boot(P, (B1 + 1):B2, streams, "cluster", extras = TRUE, track_rows = trk, label = "central escalation")
  M2 <- rbind(M, M2)
}
saveRDS(list(M = M, M2 = M2, escalated = esc, trk = trk), file.path(SCR, "boot_central.rds"))

# per-year sample sizes across replicates (card §4 "reported per year")
Mu <- if (is.null(M2)) M else M2
py <- read_csv(file.path(OUT, "per_year_static.csv"), show_col_types = FALSE)
rng <- \(p) t(apply(Mu[, paste0(p, YEARS)], 2, \(z) c(mean = mean(z), min = min(z), max = max(z))))
a <- rng("ns_"); f <- rng("nf_")
py <- py |> mutate(rep_households_mean = a[, "mean"], rep_households_min = a[, "min"], rep_households_max = a[, "max"],
                   rep_farmers_mean = f[, "mean"], rep_farmers_min = f[, "min"], rep_farmers_max = f[, "max"])
write_csv(py, file.path(OUT, "per_year.csv"))
