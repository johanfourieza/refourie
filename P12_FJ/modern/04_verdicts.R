# P12_FJ S6 04_verdicts.R -- card §8 verdict tables applied mechanically; verdict.csv, primary.csv, figure.
suppressMessages({library(dplyr); library(readr); library(ggplot2)})
source(here::here("P12_FJ", "modern", "00_common.R"))
scr <- dscratch("P12_FJ", "modern"); md <- here::here("P12_FJ", "modern"); out <- file.path(md, "output")
pr <- readRDS(file.path(scr, "primary.rds")); inf <- pr$inf; H2 <- pr$H2; Pr <- pr$Pr
b0 <- c("c2:Coloured_x_Pandemic" = -0.7167, "c2:Black_x_Pandemic" = -1.215, "c3:Coloured_x_Pandemic" = -0.6029, "c3:Black_x_Pandemic" = -1.222, "c3:Pandemic_x_Street_road_and_stad" = -1.168)
coef_rule <- function(b, lo, hi, b0, fail) {   # §8 table for H1 rows and H3-int (b0 < 0)
  L <- 0.5 * abs(b0); excl <- lo > 0 | hi < 0
  if (fail) return(c("not-testable", 0))
  if (b > 0 && excl) return(c("overturned (reversed)", 1))
  if (lo > -L && hi < L) return(c("overturned (credible null)", 2))
  if (b < 0 && excl && abs(b) >= L) return(c("confirmed", 3))
  if (b < 0 && excl) return(c("qualified (magnitude below floor)", 4))
  if (b < 0) return(c("weakened", 5))
  c("weakened (direction lost)", 6)
}
get <- function(sp, t) inf[inf$spec == sp & inf$term == t, ]
fmt <- function(x, k = 3) formatC(x, format = "f", digits = k)
V <- NULL
rows <- list(c("H1-c2-col","c2","Coloured_x_Pandemic"), c("H1-c2-bl","c2","Black_x_Pandemic"), c("H1-c3-col","c3","Coloured_x_Pandemic"),
             c("H1-c3-bl","c3","Black_x_Pandemic"), c("H3-int","c3","Pandemic_x_Street_road_and_stad"))
for (r in rows) { z <- get(r[2], r[3]); bb <- b0[paste0(r[2], ":", r[3])]; v <- coef_rule(z$est, z$lo, z$hi, bb, z$fail)
  V <- rbind(V, tibble(claim = paste0(r[1], " (", r[2], " ", r[3], ", b0 = ", bb, ")"), estimate = fmt(z$est), interval = sprintf("Bonferroni %.4f CI [%s, %s], CV3 SE %s, G = %d", 1 - 0.05 / z$m, fmt(z$lo), fmt(z$hi), fmt(z$se), z$G),
    test_p = fmt(z$p, 4), threshold_or_band = sprintf("same sign, CI excludes 0, |b| >= %s; null if CI in (-%s, %s)", 0.5 * abs(bb), 0.5 * abs(bb), 0.5 * abs(bb)),
    verdict = v[1], rule = v[2], family = ifelse(r[2] == "c3" & grepl("Street", r[3]), "U (m = 3)", "R (m = 4)"), plausibility_flag = abs(z$est) > 1.5 * abs(bb))) }
# H1-all conjunction (members H1-c3-col, H1-c3-bl)
conj <- function(vs) { ord <- c("weakened", "qualified", "confirmed")
  if (any(grepl("^overturned", vs))) return(c("overturned", 1)); if (any(vs == "not-testable")) return(c("not-testable", 2))
  if (all(vs == "confirmed")) return(c("confirmed", 3)); base <- sub(" .*", "", vs); c(vs[which.min(match(base, ord))], 4) }
cv <- conj(V$verdict[3:4])
V <- rbind(V, tibble(claim = "H1-all (both groups, spec 3; members H1-c3-col, H1-c3-bl)", estimate = paste(V$estimate[3:4], collapse = "; "), interval = "see members", test_p = "",
  threshold_or_band = "conjunction (§8)", verdict = cv[1], rule = cv[2], family = "R", plausibility_flag = NA))
# H3-rev
bs <- get("c3", "Street_road_and_stad"); tu <- get("c3", "theta_U")
comp <- function(z, want) { if (z$fail) return("not-testable"); if (z$lo > 0) return(if (want > 0) "supports" else "contradicts"); if (z$hi < 0) return(if (want < 0) "supports" else "contradicts"); "uncertain" }
cs <- c(beta_S = comp(bs, 1), theta_U = comp(tu, -1))
hv <- if (any(cs == "contradicts")) c(paste0("overturned (", paste(names(cs)[cs == "contradicts"], collapse = ", "), ")"), 1) else if (any(cs == "not-testable")) c("not-testable", 2) else
  if (all(cs == "supports")) c("confirmed", 3) else if (sum(cs == "supports") == 1) c("qualified", 4) else c("weakened", 5)
V <- rbind(V, tibble(claim = "H3-rev (urban benefit reversed: beta_S > 0 and theta_U = beta_S + beta_PxS < 0)", estimate = sprintf("beta_S = %s; theta_U = %s", fmt(bs$est), fmt(tu$est)),
  interval = sprintf("Bonferroni 0.9833 CIs: beta_S [%s, %s]; theta_U [%s, %s]", fmt(bs$lo), fmt(bs$hi), fmt(tu$lo), fmt(tu$hi)), test_p = sprintf("%s; %s", fmt(bs$p, 4), fmt(tu$p, 4)),
  threshold_or_band = sprintf("components: beta_S %s, theta_U %s", cs[1], cs[2]), verdict = hv[1], rule = hv[2], family = "U (m = 3)", plausibility_flag = NA))
# H2-P (not-testable by rule) and H3-mort
for (k in c("C","B")) { h <- H2[H2$quantity == paste0("DiD_", k), ]
  V <- rbind(V, tibble(claim = paste0("H2-P-", ifelse(k == "C", "col", "bl"), " (DiD_", k, ", spec 2, pp)"), estimate = fmt(h$est_pp, 2),
    interval = sprintf("descriptive only: LOO range [%s, %s], jackknife SE %s", fmt(h$loo_min, 2), fmt(h$loo_max, 2), fmt(h$jk_se, 2)), test_p = "",
    threshold_or_band = "none (§4C)", verdict = "not-testable", rule = "§4C", family = "none", plausibility_flag = NA)) }
V <- rbind(V, tibble(claim = "H2-P-all (all black and coloured)", estimate = "", interval = "", test_p = "", threshold_or_band = "conjunction", verdict = "not-testable", rule = "2", family = "none", plausibility_flag = NA))
V <- rbind(V, tibble(claim = "H3-mort (city a health hazard: mortality reading)", estimate = "", interval = "", test_p = "", threshold_or_band = "no mortality model", verdict = "not-testable", rule = "§8", family = "none", plausibility_flag = NA))
# P rows
for (i in seq_len(nrow(Pr))) { p <- Pr[i, ]
  v <- if (!is.finite(p$est) || !p$paarl_coef_ok) c("not-testable", 0) else if (p$est >= p$lo && p$est <= p$hi) c("confirmed", 1) else if (p$est < p$lo) c("qualified (below the stated value)", 2) else c("qualified (above the stated value)", 3)
  V <- rbind(V, tibble(claim = sprintf("%s (%s = %.1f; %s, %s)", p$row, p$source, p$stated, c(W = "white", C = "coloured", B = "black")[p$race], ifelse(p$pandemic == 1, "pandemic", "baseline")),
    estimate = fmt(p$est, 1), interval = "point (no inference); spec 2, Paarl reference person", test_p = "", threshold_or_band = sprintf("A8a band [%s, %s]", p$lo, p$hi),
    verdict = v[1], rule = v[2], family = "none", plausibility_flag = NA)) }
V$scope <- SCOPE
write_csv(V, file.path(out, "verdict.csv"))
prim <- bind_rows(
  inf %>% transmute(row = paste(family, spec, term), estimate = est, se_cv3 = se, lo, hi, p, G, m, n, loo_min, loo_max, fail, note = "logit coefficient; CV3 jackknife, t(G-1), Bonferroni CI"),
  H2 %>% transmute(row = paste("H2", quantity), estimate = est_pp, se_cv3 = jk_se, loo_min, loo_max, G = 11, note = "pp, spec 2; descriptive, no inferential role"),
  Pr %>% transmute(row = paste(row, source), estimate = est, lo, hi, note = "pp, spec 2 Paarl reference person; lo/hi = A8a band"))
write_csv(prim, file.path(out, "primary.csv"))
# figure: coefficient rows with Bonferroni CV3 intervals, published b0 marked
fd <- inf %>% mutate(lab = paste0(spec, ": ", recode(term, Coloured_x_Pandemic = "Coloured x Pandemic", Black_x_Pandemic = "Black x Pandemic",
  Pandemic_x_Street_road_and_stad = "Pandemic x Street", Street_road_and_stad = "Street (baseline)", theta_U = "Street + Pandemic x Street")),
  pub = c(-0.7167, -1.215, -0.6029, -1.222, -1.168, 1.338, 0.170))
fd$lab <- factor(fd$lab, levels = rev(fd$lab))
g <- ggplot(fd, aes(y = lab)) + geom_vline(xintercept = 0, colour = "#AAAAAA") +
  geom_errorbar(aes(xmin = lo, xmax = hi, colour = family), width = 0, orientation = "y", linewidth = 0.8) +
  geom_point(aes(x = est, colour = family), size = 2.2) + geom_point(aes(x = pub), shape = 4, colour = "#D4A03E", size = 2.5, stroke = 1) +
  scale_colour_manual(values = c(R = "#5C2346", U = "#3D8EB9"), labels = c(R = "Race x pandemic (m = 4)", U = "Urban (m = 3)"), name = NULL) +
  labs(x = "Logit coefficient", y = NULL, caption = "Dots: corrected 11-district estimates; bars: Bonferroni CIs from the CV3 cluster jackknife, t(10). Crosses: published 15-district values\n(urban rows: 1.338 and 1.338 - 1.168 = 0.170).") +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom", panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(), plot.caption = element_text(hjust = 0, size = 7), plot.caption.position = "plot")
ggsave(file.path(md, "fig_primary.pdf"), g, width = 7, height = 4); ggsave(file.path(md, "fig_primary.png"), g, width = 7, height = 4, dpi = 300)
print(V %>% select(claim, estimate, verdict, rule), n = 30, width = 200)
# fold sensitivity 5 (Stata score bootstrap; p only, boottest gives no CI after logit) into sensitivities.csv
s <- read_csv(file.path(out, "sensitivities.csv"), col_types = cols(.default = "c"))
if (file.exists(file.path(out, "sens05_score_boot.csv"))) {
  sb <- read_csv(file.path(out, "sens05_score_boot.csv"), show_col_types = FALSE) |>
    mutate(term = recode(hyp, CxP = "Coloured_x_Pandemic", BxP = "Black_x_Pandemic", P_Street = "Pandemic_x_Street_road_and_stad", Street = "Street_road_and_stad"),
           category = ifelse(p < (1 - level / 100), "significant at Bonferroni level", "not significant at Bonferroni level")) |>
    transmute(sens = "5 score WCB (Stata boottest, Webb, B=999)", spec, term, est = as.character(est), p = as.character(p), category)
  s <- bind_rows(filter(s, !grepl("^5 score", sens)), sb) }
write_csv(s, file.path(out, "sensitivities.csv"))
writeLines(capture.output(sessionInfo()), file.path(md, "sessionInfo.txt"))
