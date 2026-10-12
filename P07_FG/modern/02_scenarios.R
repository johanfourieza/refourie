# P07_FG S6 step 2: central scenario (primary) and the 16-scenario assumption range A (card 4.2),
# plus the lambda at which each I1c / I2 statistic crosses its margin, other inputs central (card 4.2).
# Writes output/primary.csv, output/scenarios.csv, output/lambda_crossings.csv.
source(file.path(here::here(), "P07_FG", "modern", "00_engine.R"))
ver <- read_csv(file.path(OUT, "verification.csv"), show_col_types = FALSE)
VER_OK <- ver$note[ver$check == "ALL"] == "PASS"
d <- load_data(); tas <- tas_lookup(d)
sc <- bind_rows(lapply(seq_len(nrow(grid_A)), function(i) { g <- grid_A[i, ]
  bind_cols(g, run_scenario(d, g$lambda, g$S, g$gamma, tas$a)) }))
write_csv(sc, file.path(OUT, "scenarios.csv"))

cen <- sc |> filter(central)
primary <- tibble(
  statistic = c("K_1685", "K_1773", "S_1685", "S_1773", "g_K", "g_S", "r_KS", "I1c = K_1773/6843", "g_pub",
                "T3_without", "T3_with", "T3_N_without", "T3_N_with", "P_T3", "T5_without", "T5_with", "T5_N_without", "T5_N_with", "P_T5",
                "T3_Stel_without", "T3_Stel_with", "T3_Drak_without", "T3_Drak_with", "P_T5_Stel", "P_T5_Drak"),
  central = c(cen$K1685, cen$K1773, cen$S1685, cen$S1773, cen$gK, cen$gS, cen$rKS, cen$I1c, G_PUB,
              cen$T3_without, cen$T3_with, cen$T3_n_without, cen$T3_n_with, cen$P_T3, cen$T5_without, cen$T5_with, cen$T5_n_without, cen$T5_n_with, cen$P_T5,
              cen$T3_Stel_without, cen$T3_Stel_with, cen$T3_Drak_without, cen$T3_Drak_with, cen$P_T5_Stel, cen$P_T5_Drak))
rng <- function(v) c(min(v), max(v))
amap <- c(g_K = "gK", r_KS = "rKS", "I1c = K_1773/6843" = "I1c", P_T3 = "P_T3", P_T5 = "P_T5", K_1685 = "K1685", K_1773 = "K1773",
          T3_with = "T3_with", T5_with = "T5_with", T3_Stel_with = "T3_Stel_with", T3_Drak_with = "T3_Drak_with", P_T5_Stel = "P_T5_Stel", P_T5_Drak = "P_T5_Drak")
primary <- primary |> mutate(A_min = NA_real_, A_max = NA_real_, A_nonfinite = NA_integer_)
for (k in names(amap)) { v <- sc[[amap[k]]]; i <- primary$statistic == k
  primary$A_min[i] <- min(v[is.finite(v)]); primary$A_max[i] <- max(v[is.finite(v)]); primary$A_nonfinite[i] <- sum(!is.finite(v)) }
primary$verification <- ifelse(VER_OK, "PASS", "FAIL")
primary$paired_note <- ifelse(cen$T3_n_without == cen$T3_n_with & cen$T5_n_without == cen$T5_n_with, "N_without = N_with in T3 and T5; paired = unpaired", "Ns differ; see P_*_paired")
write_csv(primary, file.path(OUT, "primary.csv"))

# lambda crossings (other inputs central)
f <- function(lam, stat) run_scenario(d, lam, "text", "stated", tas$a)[[stat]]
cross <- function(stat, thr) {
  h <- function(l) f(l, stat) - thr
  lo <- 0.05; hi <- 5
  if (sign(h(lo)) == sign(h(hi))) return(NA_real_)
  uniroot(h, c(lo, hi), tol = 1e-8)$root
}
lc <- tibble(claim = c("I1c", "I1c", "I2a", "I2b"), statistic = c("I1c", "I1c", "P_T5", "P_T3"),
             margin = c(0.90, 1.10, -21.7, -21.72)) |>
  rowwise() |> mutate(lambda_cross = cross(statistic, margin)) |> ungroup() |>
  mutate(note = "lambda at which the central-scenario statistic equals the margin; searched on [0.05, 5]; not used to set A")
write_csv(lc, file.path(OUT, "lambda_crossings.csv"))
options(width = 200)
print(as.data.frame(sc |> select(scenario, K1685, K1773, gK, rKS, I1c, P_T3, P_T5, T3_with) |> mutate(across(where(is.numeric), ~ round(.x, 3)))))
print(as.data.frame(lc))
