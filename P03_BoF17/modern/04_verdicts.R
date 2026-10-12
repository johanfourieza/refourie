# P03_BoF17 S6 04: verdict tables (card §8) applied mechanically; §5C and §5D assembled; outputs and figures
source(here::here("P03_BoF17", "modern", "00_common.R"))
suppressMessages(library(ggplot2))
pc <- read.csv(file.path(odir, "primary_corr.csv")); bb <- read.csv(file.path(odir, "bounds_boot.csv"), check.names = FALSE)
dg <- read.csv(file.path(odir, "bounds_diagnostics.csv")); sc <- read.csv(file.path(odir, "sensitivities_corr.csv"))
g <- function(cl) pc[pc$claim == cl, ]
nt0 <- function(z) !z$repro_ok || !is.finite(z$r) || z$fail_rate > FAIL_MAX || abs(z$r) == 1

## ---- correlation verdicts ----
vH1 <- function(z) if (nt0(z)) c(0, "not-testable") else if (-0.025 < z$L99 && z$U99 < 0.025) c(1, "confirmed") else
  if (z$L99 > 0 || z$U99 < 0) c(2, "weakened") else c(3, "qualified (insignificant, but a null is not demonstrated)")
vH2 <- function(z) if (nt0(z)) c(0, "not-testable") else if (z$r >= 0.43 && z$L99 > 0) c(1, "confirmed") else
  if (z$r >= 0.43 && z$L99 <= 0 && z$L95 > 0) c(2, "qualified (inference-fragile)") else c(3, "weakened")
vH3 <- function(z, nt) if (nt) c(0, "not-testable") else if (z$L99 > 0) c(1, "confirmed") else
  if (z$L99 <= 0 && z$L95 > 0) c(2, "qualified (inference-fragile)") else c(3, "weakened")
vK <- function(z, f) if (nt0(z) || z$n_complete < 10) c(0, "not-testable") else if (z$U99 < 0) c(1, "overturned (opposite sign supported)") else
  if (-f < z$L99 && z$U99 < f) c(2, "overturned (credible null)") else if (z$L99 > 0 && z$r >= f) c(3, "confirmed") else
  if (z$L99 > 0 && z$r < f) c(4, "qualified (magnitude below floor)") else if (z$L99 <= 0 && z$L95 > 0) c(5, "qualified (inference-fragile)") else c(6, "weakened")
## ---- bounds verdicts ----
rej <- function(z, lev, cvF = paste0("F_ov_", lev), cvI = paste0("F_ind_", lev), cvt = paste0("t_", c("975" = "025", "90" = "10")[[lev]]))
  z$F_ov > z[[cvF]] && z$F_ind > z[[cvI]] && z$t_dep < z[[cvt]]
vB <- function(z, d) { if (!is.finite(z$F_ov) || !is.finite(z$t_dep) || !is.finite(z$F_ind) || z$df < 20 || z$fail_rate > FAIL_MAX) return(c(0, "not-testable"))
  diag_ok <- isTRUE(d$D1_pass == 1 && d$D2_pass == 1 && d$D3_pass == 1)
  if (rej(z, "975")) { if (diag_ok) c(1, "confirmed") else c(2, "qualified (specification diagnostic)") } else
  if (rej(z, "90")) c(3, "qualified (inference-fragile)") else c(4, "weakened") }

ver <- list()
add <- function(cl, est, int, p, band, v) ver[[cl]] <<- data.frame(claim = cl, estimate = as.character(est), interval = int, test_p = as.character(p), threshold_or_band = band, verdict = v[2], rule = paste0("§8 ", cl, " row ", v[1]))
bp <- function(cl) { f <- file.path(scr, if (cl %in% c("H1", "H2")) "bs_H.rds" else paste0("bs_", cl, ".rds")); b <- readRDS(f)
  if (cl == "H1") b <- b$pre; if (cl == "H2") b <- b$post; b <- b[is.finite(b)]; 2 * min(mean(b <= 0), mean(b >= 0)) }
iv <- function(z) sprintf("99%% [%.3f, %.3f]; 95%% [%.3f, %.3f]", z$L99, z$U99, z$L95, z$U95)
add("H1", round(g("H1")$r, 3), iv(g("H1")), round(bp("H1"), 3), "confirm if 99% CI inside (-0.025, 0.025)", vH1(g("H1")))
add("H2", round(g("H2")$r, 3), iv(g("H2")), round(bp("H2"), 3), "r >= 0.43 and 99% L > 0", vH2(g("H2")))
add("H3", round(g("H3")$r, 3), iv(g("H3")), NA, "99% MOVER(rho=-1) L > 0", vH3(g("H3"), nt0(g("H1")) || nt0(g("H2"))))
add("K1", round(g("K1")$r, 3), iv(g("K1")), round(bp("K1"), 3), "f = 0.135; null band (-0.135, 0.135)", vK(g("K1"), 0.135))
add("K2", round(g("K2")$r, 3), iv(g("K2")), round(bp("K2"), 3), "f = 0.15; null band (-0.15, 0.15)", vK(g("K2"), 0.15))
ce <- bb |> filter(variant == "central", spec == "aic")
for (cl in c("K3", "K4")) { z <- ce[ce$claim == cl, ]; arr <- readRDS(file.path(scr, paste0("boot_", cl, "_central.rds")))[, "aic", ]
  pv <- c(F_ov = mean(arr["F_ov", ] >= z$F_ov, na.rm = TRUE), F_ind = mean(arr["F_ind", ] >= z$F_ind, na.rm = TRUE), t_dep = mean(arr["t_dep", ] <= z$t_dep, na.rm = TRUE))
  add(cl, sprintf("ARDL(%d,%d) F_ov=%.2f t=%.2f F_ind=%.2f", z$p, z$q, z$F_ov, z$t_dep, z$F_ind),
      sprintf("CV 2.5%%: F_ov %.2f, t %.2f, F_ind %.2f; 10%%: %.2f, %.2f, %.2f (B=%d)", z$F_ov_975, z$t_025, z$F_ind_975, z$F_ov_90, z$t_10, z$F_ind_90, z$B),
      sprintf("F_ov %.3f; t %.3f; F_ind %.3f", pv[1], pv[2], pv[3]), "all three reject at 2.5% (+D1-D3); 10% unadjusted", vB(z, dg[dg$claim == cl, ])) }
verdict <- bind_rows(ver); write.csv(verdict, file.path(odir, "verdict.csv"), row.names = FALSE); print(verdict[, c(1, 2, 6, 7)])

## ---- primary.csv ----
prim <- bind_rows(pc |> mutate(spec = "moving-block bootstrap", across(everything(), as.character)),
  ce |> transmute(claim, spec = sprintf("bootstrap ARDL(%d,%d), AIC", p, q), r = NA, N = 120, n_complete = n, df, B, fail_rate, mc_flag,
    F_ov, t_dep, F_ind, F_ov_975, F_ov_95, F_ov_90, F_ind_975, F_ind_95, F_ind_90, t_025, t_05, t_10,
    se_F_ov_975, se_F_ind_975, se_t_025, se_F_ov_90, se_F_ind_90, se_t_10) |> mutate(across(everything(), as.character)) |>
    left_join(dg |> mutate(across(everything(), as.character)), by = "claim"))
write.csv(prim, file.path(odir, "primary.csv"), row.names = FALSE, na = "")

## ---- 5C: K3-K4 sensitivities ----
s5c <- bb |> filter(!(variant == "central" & spec == "aic")) |>
  transmute(group = "5C", claim, item = case_when(spec %in% c("fix1", "fix2", "fix3") ~ "1", spec == "bic" ~ "2", variant == "cape_dep" ~ "3", variant == "interp" ~ "4", variant == "block12" ~ "6"),
    kind = ifelse(variant == "interp", "admissible (A4d)", "admissible"), label = paste(variant, spec, sprintf("ARDL(%d,%d)", p, q)), est = F_ov,
    t_dep, F_ind, n, all3_25, all3_10, cv = sprintf("2.5%%: %.2f/%.2f/%.2f", F_ov_975, t_025, F_ind_975))
asy <- ce |> transmute(group = "5C", claim, item = "5", kind = "admissible", label = "asymptotic PSS Case III k=1 bounds", est = F_ov, t_dep, F_ind, n,
  all3_25 = NA, all3_10 = NA, cv = sprintf("F_ov %s; t_dep %s", ifelse(F_ov > 6.68, "> I(1) 2.5% (6.68)", ifelse(F_ov > 4.78, "> I(1) 10% (4.78), < 6.68", ifelse(F_ov > 4.04, "inside 10% bounds [4.04, 4.78]", "< I(0) 10% (4.04)"))),
    ifelse(t_dep < -3.50, "< I(1) 2.5% (-3.50)", ifelse(t_dep < -2.91, "< I(1) 10% (-2.91), > -3.50", ifelse(t_dep < -2.57, "inside 10% bounds", "> I(0) 10% (-2.57)")))))
nar <- ce |> transmute(group = "5C", claim, item = "7", kind = "admissible", label = "printed Narayan bounds [4.29; 5.08]", est = F_ov, t_dep = NA, F_ind = NA, n,
  all3_25 = NA, all3_10 = NA, cv = ifelse(F_ov > 5.08, "above upper bound 5.08", ifelse(F_ov > 4.29, "inside bounds", "below lower bound 4.29")))
## error documentation: S3/S5 fixed-lag grid without the contemporaneous term (F03)
LAG <- function(v, j) if (j == 0) v else c(rep(NA, j), head(v, -j))
err <- list(); for (cl in list(c("K3", "Wheat"), c("K4", "Mealies"))) { y <- lp("Kimberley", cl[2]); x <- lp("Cape Town", cl[2])
  for (p in 0:3) { D <- data.frame(dy = dl(y), y1 = LAG(y, 1), x1 = LAG(x, 1)); for (j in seq_len(p)) { D[[paste0("dy", j)]] <- LAG(dl(y), j); D[[paste0("dx", j)]] <- LAG(dl(x), j) }
    D <- D[complete.cases(D), ]; v <- setdiff(names(D), "dy"); a <- anova(lm(reformulate(c("1", setdiff(v, c("y1", "x1"))), "dy"), D), lm(reformulate(v, "dy"), D))
    err[[length(err) + 1]] <- data.frame(group = "5C", claim = cl[1], item = "err", kind = "error documentation", label = sprintf("no dx_t, p = q = %d (S3/S5 grid, F03)", p), est = a$F[2], n = nrow(D)) } }
scen <- bb |> filter(variant %in% c("central", "cape_dep", "interp"), !(variant == "central" & spec == "aic")) |> group_by(claim) |>
  summarise(group = "5C", item = "scenario", kind = "scenario display (assumption-conditional; equal weights are not probabilities)",
    label = sprintf("items 1-4, %d scenarios: F_ov range [%.2f, %.2f]; share all three reject at 2.5%% = %d/%d", n(), min(F_ov), max(F_ov), sum(all3_25), n()), est = NA)

## ---- 5D: one Bonferroni family of seven ----
a7 <- 0.05 / 7; s5d <- list()
for (cl in c("H1", "H2", "K1", "K2")) { z <- g(cl); b <- readRDS(file.path(scr, if (cl %in% c("H1", "H2")) "bs_H.rds" else paste0("bs_", cl, ".rds")))
  if (cl == "H1") b <- b$pre; if (cl == "H2") b <- b$post; z$L99 <- q7(b, a7 / 2); z$U99 <- q7(b, 1 - a7 / 2)
  v <- switch(cl, H1 = vH1(z), H2 = vH2(z), K1 = vK(z, 0.135), K2 = vK(z, 0.15))
  s5d[[cl]] <- data.frame(claim = cl, L = z$L99, U = z$U99, verdict_5D = v[2]) }
bH <- readRDS(file.path(scr, "bs_H.rds")); z <- g("H3"); z$L99 <- q7(bH$post, a7 / 4) - q7(bH$pre, 1 - a7 / 4); z$U99 <- q7(bH$post, 1 - a7 / 4) - q7(bH$pre, a7 / 4)
s5d[["H3"]] <- data.frame(claim = "H3", L = z$L99, U = z$U99, verdict_5D = vH3(z, FALSE)[2])
for (cl in c("K3", "K4")) { z <- ce[ce$claim == cl, ]; arr <- readRDS(file.path(scr, paste0("boot_", cl, "_central.rds")))[, "aic", ]; a3 <- a7 / 3
  z$F_ov_975 <- q7(arr["F_ov", ], 1 - a3); z$F_ind_975 <- q7(arr["F_ind", ], 1 - a3); z$t_025 <- q7(arr["t_dep", ], a3)
  s5d[[cl]] <- data.frame(claim = cl, L = NA, U = NA, verdict_5D = vB(z, dg[dg$claim == cl, ])[2]) }
s5d <- bind_rows(s5d) |> left_join(verdict[, c("claim", "verdict")], by = "claim") |> mutate(changes = verdict_5D != verdict)
print(s5d)

sens <- bind_rows(sc |> mutate(item = as.character(item)), s5c, asy, nar, bind_rows(err), scen,
  s5d |> transmute(group = "5D", claim, item = "1", kind = "admissible", label = paste0("Bonferroni over 7: ", verdict_5D, ifelse(changes, " (changes)", " (unchanged)")), L99 = L, U99 = U))
write.csv(sens, file.path(odir, "sensitivities.csv"), row.names = FALSE, na = "")

## ---- figures (LEAP palette) ----
pal <- c(plum = "#5C2346", blue = "#3D8EB9", sage = "#6B8E5E", gold = "#D4A03E", grey = "#AAAAAA")
fd <- pc |> mutate(claim = factor(claim, levels = rev(c("H1", "H2", "H3", "K1", "K2"))), floor = c(NA, 0.43, 0, 0.135, 0.15)[match(claim, c("H1", "H2", "H3", "K1", "K2"))],
  pub = c(0.05, 0.86, 0.81, 0.27, 0.30)[match(claim, c("H1", "H2", "H3", "K1", "K2"))])
p <- ggplot(fd, aes(y = claim)) + geom_vline(xintercept = 0, colour = pal["grey"]) +
  geom_errorbarh(aes(xmin = L99, xmax = U99), height = 0, linewidth = 0.6, colour = pal["blue"]) +
  geom_errorbarh(aes(xmin = L95, xmax = U95), height = 0, linewidth = 1.8, colour = pal["blue"]) +
  geom_point(aes(x = r), size = 2.6, colour = pal["plum"]) + geom_point(aes(x = pub), shape = 4, size = 2.6, colour = pal["gold"]) +
  geom_point(aes(x = floor), shape = 124, size = 5, colour = pal["sage"], na.rm = TRUE) +
  labs(x = "Correlation (H3: difference post − pre)", y = NULL,
       caption = "Dot: S6 estimate; thick bar: 95%; thin bar: 99% family interval (block bootstrap; H3 MOVER, rho = −1).\nCross: published value; green tick: card floor.") +
  theme_minimal(base_size = 11) + theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(), plot.caption = element_text(hjust = 0, size = 8))
ggsave(file.path(mdir, "fig_correlations.pdf"), p, width = 6.5, height = 3.6); ggsave(file.path(mdir, "fig_correlations.png"), p, width = 6.5, height = 3.6, dpi = 300)
fb <- ce |> select(claim, F_ov, F_ind, t_dep, F_ov_975, F_ind_975, t_025, F_ov_90, F_ind_90, t_10) |>
  transmute(claim, stat = list(c("F_ov", "F_ind", "t_dep")), obs = Map(c, F_ov, F_ind, abs(t_dep)), c25 = Map(c, F_ov_975, F_ind_975, abs(t_025)), c10 = Map(c, F_ov_90, F_ind_90, abs(t_10))) |>
  tidyr::unnest(c(stat, obs, c25, c10)) |> mutate(lab = paste(claim, c(K3 = "wheat", K4 = "maize")[claim], stat))
p2 <- ggplot(fb, aes(y = lab)) + geom_segment(aes(x = c10, xend = c25, yend = lab), colour = pal["grey"], linewidth = 2) +
  geom_point(aes(x = c10), colour = pal["blue"], size = 2.4) + geom_point(aes(x = c25), colour = pal["gold"], size = 2.4) + geom_point(aes(x = obs), colour = pal["plum"], size = 3, shape = 18) +
  labs(x = "Statistic (|t| for t_dep)", y = NULL, caption = "Diamond: observed; blue: bootstrap 10% critical value; gold: 2.5% critical value (B = 9,999).") +
  theme_minimal(base_size = 11) + theme(panel.grid.minor = element_blank(), plot.caption = element_text(hjust = 0, size = 8))
ggsave(file.path(mdir, "fig_bounds.pdf"), p2, width = 6.5, height = 3.2); ggsave(file.path(mdir, "fig_bounds.png"), p2, width = 6.5, height = 3.2, dpi = 300)
writeLines(capture.output(sessionInfo()), file.path(mdir, "sessionInfo.txt"))
