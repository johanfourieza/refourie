# P07_FG S6 step 1: verification checks of card 4.3, run before any verdict output.
# 1 coded reference vs S5 Stata `base`; 2 central vs S5 `stel2x`; 3 anchor check in all 16 scenarios;
# 4 missing-value counts per sample. Writes output/verification.csv and output/missing_counts.csv.
# Run from the project root: Rscript P07_FG/modern/01_verify.R
source(file.path(here::here(), "P07_FG", "modern", "00_engine.R"))
TOL <- 1e-4
s5 <- read_csv(file.path(ROOT, "P07_FG", "compare", "s5_checks", "scenario_results.csv"), show_col_types = FALSE)
d <- load_data()
tas <- tas_lookup(d)
cat("Tas lookup: found =", tas$found, "| rows =", tas$n, "| a_Tas =", tas$a, "\n")
if (tas$found) print(as.data.frame(tas$row[, c("surname", "name", "year", "district", "slaves", "slavemales", "vherd")]))

ycells <- function(d, L) {           # X1 sums: K, slaves by year x region (all / csd / swe)
  reg <- list(all = rep(TRUE, nrow(d)), csd = d$district < 4, swe = d$district == 4)
  bind_rows(lapply(names(reg), function(r) {
    m <- reg[[r]]; yy <- sort(unique(d$year[m]))
    bind_rows(lapply(yy, function(y) tibble(cell = c(paste0("T1_", y, "_", r, "_khoesan"), paste0("T1_", y, "_", r, "_slaves")),
      r_value = c(sum(L[m & d$year == y], na.rm = TRUE), sum(d$slaves[m & d$year == y], na.rm = TRUE)))))
  }))
}
prodcells <- function(d, L) {
  sm <- samples(d); nm <- c("1" = "Capedistrict", "2" = "Stellenbosch", "3" = "Drakenstein")
  out <- list()
  for (k in list(1, 2, 3, 1:3)) { lab <- if (length(k) > 1) "Total" else nm[as.character(k)]
    a <- prod_stat(d, L, sm$T3, dists = k); b <- prod_stat(d, L, sm$T5, dists = k)
    out[[length(out) + 1]] <- tibble(cell = paste0(c("T3_", "T3_", "T3_", "T5_", "T5_", "T5_"), lab,
                                                   c("_without", "_with", "_n", "_slagprod", "_labgprod", "_n")),
                                     r_value = c(a[["without"]], a[["with"]], a[["n_without"]], b[["without"]], b[["with"]], b[["n_without"]])) }
  bind_rows(out)
}
check_against <- function(scen, lambda, S) {
  dv <- divisor(d, lambda, S, "stated", tas$a); L <- labour(d, dv)
  r <- bind_rows(ycells(d, L), prodcells(d, L))
  ref <- s5 |> filter(scenario == scen) |> select(cell = claim_id, stata = value)
  r |> inner_join(ref, by = "cell") |>
    mutate(check = paste0(scen, " vs S5 ", scen), rel_diff = ifelse(stata == 0, abs(r_value), abs(r_value - stata) / abs(stata)),
           exact_n = grepl("_n$", cell), pass = ifelse(exact_n, r_value == stata, rel_diff <= TOL))
}
v1 <- check_against("base", 1, "code")      # coded reference: lambda 1, S = code, gamma stated
v2 <- check_against("stel2x", 1, "text")    # central: lambda 1, S = text, gamma stated
# card-listed Ns
nexp <- c(T3_Capedistrict_n = 126, T3_Stellenbosch_n = 38, T3_Drakenstein_n = 206, T3_Total_n = 370,
          T5_Capedistrict_n = 321, T5_Stellenbosch_n = 207, T5_Drakenstein_n = 567, T5_Total_n = 1095)
vn <- v1 |> filter(cell %in% names(nexp)) |> mutate(card = nexp[cell], pass_card = r_value == card)
cat("\nCheck 1 (coded reference vs S5 base):", sum(v1$pass), "/", nrow(v1), "cells pass; max rel diff",
    signif(max(v1$rel_diff[!v1$exact_n]), 3), "\n")
cat("  T3 Total without/with:", v1$r_value[v1$cell == "T3_Total_without"], v1$r_value[v1$cell == "T3_Total_with"], "\n")
cat("  card Ns:", paste(vn$cell, vn$r_value, collapse = "; "), "| all match:", all(vn$pass_card), "\n")
cat("Check 2 (central vs S5 stel2x):", sum(v2$pass), "/", nrow(v2), "cells pass; max rel diff",
    signif(max(v2$rel_diff[!v2$exact_n]), 3), "\n")

# Check 3: anchors in every scenario. Card divisors are the printed ratios (67.5, 185.6), so Botha gets
# 3375.2/67.5*lambda = 50.003*lambda and Tas 2041.2/185.6 = 10.998; tolerance 0.005 (DEVIATIONS D1).
v3 <- bind_rows(lapply(seq_len(nrow(grid_A)), function(i) { g <- grid_A[i, ]
  L <- labour(d, divisor(d, g$lambda, g$S, g$gamma, tas$a))
  tibble(scenario = g$scenario, L_botha = sum(L[d$botha]), target_botha = 50 * g$lambda,
         L_tas = sum(L[d$tas]), target_tas = ifelse(g$S == "Tas", 11, NA_real_)) })) |>
  mutate(pass_botha = abs(L_botha - target_botha) <= 0.005, pass_tas = is.na(target_tas) | abs(L_tas - target_tas) <= 0.005)
cat("Check 3 (anchors): Botha pass", sum(v3$pass_botha), "/ 16; Tas pass (S = Tas)", sum(v3$pass_tas[!is.na(v3$target_tas)]),
    "/", sum(!is.na(v3$target_tas)), "\n")

# Check 4: missing-value counts per sample
sm <- samples(d)
mc <- bind_rows(lapply(c("analysis", "T3", "T5"), function(s) { m <- if (s == "analysis") rep(TRUE, nrow(d)) else sm[[s]] & d$district %in% 1:3
  tibble(sample = s, n = sum(m), miss_vherd = sum(is.na(d$vherd[m])), miss_slaves = sum(is.na(d$slaves[m])), miss_slavemales = sum(is.na(d$slavemales[m]))) }))
print(as.data.frame(mc))

ok <- all(v1$pass) && all(v2$pass) && all(vn$pass_card) && all(v3$pass_botha) && all(v3$pass_tas) && tas$found
ver <- bind_rows(
  tibble(check = "1 coded reference vs S5 base", cells = nrow(v1), passed = sum(v1$pass), max_rel_diff = max(v1$rel_diff[!v1$exact_n]), note = "K by year/region, slaves, T3/T5 means and Ns; rel tol 1e-4, Ns exact"),
  tibble(check = "1b card-listed Ns (T3 126/38/206/370; T5 321/207/567/1095)", cells = nrow(vn), passed = sum(vn$pass_card), max_rel_diff = 0, note = paste(vn$r_value, collapse = "/")),
  tibble(check = "2 central vs S5 stel2x", cells = nrow(v2), passed = sum(v2$pass), max_rel_diff = max(v2$rel_diff[!v2$exact_n]), note = "same cells"),
  tibble(check = "3a Botha = 50*lambda in all 16 scenarios", cells = 16, passed = sum(v3$pass_botha), max_rel_diff = max(abs(v3$L_botha - v3$target_botha)), note = "abs diff shown; tol 0.005 (D1)"),
  tibble(check = "3b Tas = 11 under S = Tas", cells = sum(!is.na(v3$target_tas)), passed = sum(v3$pass_tas[!is.na(v3$target_tas)]), max_rel_diff = max(abs(v3$L_tas - v3$target_tas), na.rm = TRUE), note = paste0("a_Tas = ", tas$a, " (", tas$row$surname, " ", tas$row$name, ", 1709, ", tas$row$slaves, " slaves)")),
  tibble(check = "4 missing values (vherd, slaves, slavemales)", cells = 3 * nrow(mc), passed = sum(mc[, 3:5] == 0), max_rel_diff = NA, note = paste(mc$sample, mc$n, sep = " n=", collapse = "; ")),
  tibble(check = "ALL", cells = NA, passed = NA, max_rel_diff = NA, note = ifelse(ok, "PASS", "FAIL")))
write_csv(ver, file.path(OUT, "verification.csv")); write_csv(bind_rows(v1, v2), file.path(OUT, "verification_cells.csv"))
write_csv(v3, file.path(OUT, "anchor_check.csv")); write_csv(mc, file.path(OUT, "missing_counts.csv"))
cat("\nVERIFICATION:", ifelse(ok, "PASS", "FAIL"), "\n")
