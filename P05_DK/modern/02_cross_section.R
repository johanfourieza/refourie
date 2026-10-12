# P05_DK S6 step 2 (card §4A): reproduction gate, then the corrected cross-section for H1 and H3
# (CR2 = HC2 with Bell-McCaffrey/Satterthwaite df; Bonferroni level 1 - 0.05/3).
# Usage (project root): Rscript P05_DK/modern/02_cross_section.R
source("./P05_DK/modern/common.R")

# ---------------------------------------------------------------- authors' data in the card's variable names
s2 <- readRDS(dpath(P, "repro_original", "_scratch", "s2_snapshot.rds"))
auth_h1 <- function() {
  a <- s2$analysis_data
  data.frame(unit_id = a$StndrdN, deaths = a$deaths_sflu_per_1000, black_share = a$black_share1911.x, col_share = a$col_share1911.x,
             density = a$density_1911.x, log_rail = log1p(a$rail_mdcentroid_to_nearestrail_km), rain = a$rainfall_sepoctmean19101950,
             region = factor(a$region.x, levels = reg_levels), black_n = a$black_1911.x, col_n = a$col_1911.x, total_n = a$total_1911.x)
}
auth_h3 <- function() {
  a <- s2$census_1936_reduced
  data.frame(unit_id = a$StndrdN, urate = a$unemployment_rate_w, deaths = a$deaths_sflu_per_1000, black_share = a$black_share1911,
             col_share = a$col_share1911, density = a$density_1911, log_rail = log1p(a$rail_mdcentroid_to_nearestrail_km),
             rain = a$rainfall_sepoctmean19101950, region = factor(a$region.x, levels = reg_levels),
             u_t = a$unemployed_w_t, wa = a$total_workingage_pop_w, u_m = a$unemployed_w_m, u_f = a$unemployed_w_f,
             wa_m = a$total_workingage_pop_w_m, wa_f = a$total_workingage_pop_w_f)
}
A1 <- auth_h1(); A3 <- auth_h3()

# ---------------------------------------------------------------- reproduction gate (full precision, card §4A)
ro <- read.csv(file.path(ROOT, P, "repro_original", "results_original.csv"))
ref <- function(id) ro[ro$claim_id == id & ro$source == "original", ]
g1 <- se_type(lm(F_H1, A1), T_H1, "HC2"); n1 <- nobs(lm(F_H1, A1))
g3 <- se_type(lm(F_H3, A3), T_H3, "const"); n3 <- nobs(lm(F_H3, A3))
gate <- data.frame(row = c("H1", "H3"), claim_id = c("T1_r1_c1", "T3_r1_c1"), b = c(g1$b, g3$b), se = c(g1$se, g3$se), n = c(n1, n3),
                   b_S2 = c(ref("T1_r1_c1")$value, ref("T3_r1_c1")$value), se_S2 = c(ref("T1_r1_c1")$se, ref("T3_r1_c1")$se),
                   n_S2 = c(ref("T1_r1_c1")$n, ref("T3_r1_c1")$n))
gate$b_card <- c(39.4315408322013, -0.00728048840341724); gate$se_card <- c(10.9332353140074, 0.00201121123103972)
gate$pass <- mapply(function(b, se, n, bs, ses, ns) gate_ok(b, bs) && gate_ok(se, ses) && n == ns, gate$b, gate$se, gate$n, gate$b_card, gate$se_card, gate$n_S2)
gate$abs_diff_b <- abs(gate$b - gate$b_card); gate$abs_diff_se <- abs(gate$se - gate$se_card)
print(gate, digits = 15)
write.csv(gate, file.path(OUT, "gate_cross_section.csv"), row.names = FALSE)
if (!all(gate$pass)) stop("REPRODUCTION GATE FAILED: ", paste(gate$row[!gate$pass], collapse = ", "))

# ---------------------------------------------------------------- corrected data (01_build.R)
B <- readRDS(file.path(SCR, "units.rds")); el <- B$el
D1 <- el[el$in_H1, ]; D3 <- el[el$in_H3, ]
D1$region <- factor(D1$region, levels = reg_levels); D3$region <- factor(D3$region, levels = reg_levels)
m1 <- lm(F_H1, D1); m3 <- lm(F_H3, D3)
fail_rule <- function(m) nobs(m) < length(coef(m)) + 1
pub_se <- c(H1 = 10.933, H3 = 0.002); pub_df <- c(H1 = 205 - 11, H3 = 205 - 12)
row_out <- function(row, m, term) {
  r <- bm_test(m, term)
  hc2 <- se_type(m, term, "HC2")
  qpub <- qt(1 - ALPHA / 2, pub_df[row])
  data.frame(row = row, term = term, n = nobs(m), k = length(coef(m)), b = r$b, se = r$se, df_bm = r$df, p = r$p,
             ci_lo = r$lo, ci_hi = r$hi, inference = r$inference, se_hc2 = hc2$se, p_hc2_t_nk = hc2$p,
             max_leverage = max(hatvalues(m)), fail_rule = fail_rule(m),
             width_ratio_vs_published = (r$hi - r$lo) / (2 * qpub * pub_se[row]))
}
prim <- rbind(row_out("H1", m1, T_H1), row_out("H3", m3, T_H3))
print(prim, digits = 6)
if (any(prim$inference != "CR2(=HC2)/BM-Satterthwaite")) message("FALLBACK used: log in DEVIATIONS.md")
write.csv(prim, file.path(SCR, "primary_cross_section.csv"), row.names = FALSE)

# full coefficient tables (aggregate), with CR2/BM SEs
coef_tab <- function(m, row) {
  ct <- coef_test(m, vcov = "CR2", cluster = seq_len(nobs(m)), test = "Satterthwaite")
  data.frame(row = row, term = ct$Coef, b = ct$beta, se_cr2 = ct$SE, df_bm = ct$df_Satt, p_bm = ct$p_Satt)
}
write.csv(rbind(coef_tab(m1, "H1"), coef_tab(m3, "H3")), file.path(OUT, "primary_coefficients_H1_H3.csv"), row.names = FALSE)
# corrected regressor summaries and correlations with the authors' versions (common units)
cm <- inner_join(D1, A1 |> select(unit_id, a_black = black_share, a_col = col_share, a_dens = density), by = "unit_id")
diagx <- data.frame(stat = c("n_common", "cor_black_share", "cor_col_share", "cor_log1p_density", "mean_black_share_corrected",
                             "mean_black_share_authors", "mean_density_corrected", "mean_density_authors", "mean_urate_corrected_H3sample"),
                    value = c(nrow(cm), cor(cm$black_share, cm$a_black), cor(cm$col_share, cm$a_col), cor(log1p(cm$density), log1p(cm$a_dens)),
                              mean(D1$black_share), mean(A1$black_share[A1$unit_id %in% s2$analysis_data$StndrdN[as.integer(rownames(model.frame(lm(F_H1, A1))))]]),
                              mean(D1$density), mean(A1$density, na.rm = TRUE), mean(D3$urate)))
write.csv(diagx, file.path(OUT, "primary_regressor_diagnostics.csv"), row.names = FALSE)
saveRDS(list(A1 = A1, A3 = A3, D1 = D1, D3 = D3, m1 = m1, m3 = m3), file.path(SCR, "cross_section.rds"))
cat("02_cross_section done\n")
