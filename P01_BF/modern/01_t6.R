# P01_BF S6 step 1: pre-verdict reproduction checks G1-G4 (card §4), then the T6 primary analysis (card §4A):
# corrected origin coding + corrected (Cape-born) contrast at the retained mean profile, CR1 by court volume,
# t(G-1), separation detection and the cluster assessment (reported; decides nothing).
# Outputs: output/checks.csv, t6_primary.csv, t6_separation.csv, t6_cluster_assessment.csv, t6_influence.csv
source(here::here("P01_BF", "modern", "00_common.R"))

o <- load_raw(); d <- load_sample(o)
chk <- list(); addchk <- function(id, item, computed, reference, tol, pass)
  chk[[length(chk) + 1]] <<- tibble(check = id, item, computed = as.character(computed), reference = as.character(reference),
                                    tolerance = as.character(tol), pass = pass)

# ---- G1 counts (exact) --------------------------------------------------------------------------------
addchk("G1", "N", nrow(d), 1802, "exact", nrow(d) == 1802)
oc <- table(factor(d$origin[d$origin %in% c("Kust", "Cust", "Westcoast", "Coehin")], levels = c("Kust", "Cust", "Westcoast", "Coehin")))
addchk("G1", "origin counts Kust/Cust/Westcoast/Coehin", paste(oc, collapse = "/"), "3/1/2/1", "exact", all(oc == c(3, 1, 2, 1)))
pre <- d |> filter(origin %in% c("Kust", "Cust", "Westcoast", "Coehin"))
okpre <- all(pre$bco[pre$origin != "Coehin"] == "za") && all(pre$bco[pre$origin == "Coehin"] == "cn")
addchk("G1", "pre-recode bco (6 za, Coehin cn)", paste(pre$origin, pre$bco, sep = ":", collapse = ","), "za x6, cn x1", "exact", okpre)
pc <- table(d$g)[c("za", "in", "cn", "oth_bl")]
addchk("G1", "post-recode za/in/cn/oth_bl", paste(pc, collapse = "/"), "140/76/15/583", "exact", all(pc == c(140, 76, 15, 583)))
kc <- table(d$bcoh[d$bco == "ko" & d$bcoh %in% 1:2])
addchk("G1", "Khoesan early/mid", paste(kc, collapse = "/"), "28/189", "exact", all(kc == c(28, 189)))
nmiss <- sum(!complete.cases(d[, c("exactage", "female2", "age23", "bdec", "g", "source")]))
addchk("G1", "missing regressors (listwise)", nmiss, 0, "report", TRUE)
if (!all(map_lgl(chk, ~ .x$pass))) { write_csv(bind_rows(chk), file.path(out, "checks.csv")); stop("G1 failed: all rows not-testable") }

# ---- G2-G4 T6 reproductions ---------------------------------------------------------------------------
s501 <- read_csv(file.path(root, "compare", "s5_checks", "s5_01_T6_decomp.csv"), show_col_types = FALSE)
s502 <- read_csv(file.path(root, "compare", "s5_checks", "s5_02_origin_fix_T6.csv"), show_col_types = FALSE)
ro   <- read_csv(file.path(root, "repro_original", "results_original.csv"), show_col_types = FALSE)
m_orig <- t6_fit(t6_frame(d, "g_orig"))
pub_orig <- map_dbl(t6_contrasts(m_orig, convention = "published"), "pt")
m_prim_mf <- t6_frame(d, "g"); m_prim <- t6_fit(m_prim_mf)
pub_corr <- map_dbl(t6_contrasts(m_prim, convention = "published"), "pt")
tid <- c(eur = "T6_r4", id = "T6_r5", `in` = "T6_r6", mz = "T6_r8")
for (gr in names(HG)) {
  r2 <- s501$me125[s501$scenario == "orig_all" & s501$term == gr]
  addchk("G2", gr, sprintf("%.10f", pub_orig[gr]), sprintf("%.10f", r2), "1e-4", abs(pub_orig[gr] - r2) <= 1e-4)
  r3 <- ro$value[ro$claim_id == tid[gr]]
  addchk("G3", gr, sprintf("%.10f", pub_orig[gr]), sprintf("%.10f", r3), "1e-4", abs(pub_orig[gr] - r3) <= 1e-4)
  r4 <- s502$me125[s502$scenario == "fix_kust_westcoast_cochin" & s502$term == gr]
  addchk("G4", gr, sprintf("%.10f", pub_corr[gr]), sprintf("%.10f", r4), "1e-4", abs(pub_corr[gr] - r4) <= 1e-4)
}
chk_t6 <- bind_rows(chk)
t6_gate <- all(chk_t6$pass)
write_csv(chk_t6, file.path(out, "checks_t6.csv"))
cat("Checks G1-G4:\n"); print(chk_t6 |> select(check, item, computed, reference, pass), n = 30)

# ---- separation ---------------------------------------------------------------------------------------
sc <- sep_check(m_prim_mf)
sep_tab <- tibble(term = names(sc$coef), detect = unname(sc$coef), finite = is.finite(sc$coef), outcome = sc$outcome,
                  version = as.character(packageVersion("detectseparation")))
write_csv(sep_tab, file.path(out, "t6_separation.csv"))
blocked <- sep_blocked(sc)
fp <- fitted(m_prim); n_extreme <- sum(fp < 1e-8 | fp > 1 - 1e-8)
cat("Separation detected:", sc$outcome, "; blocked groups:", names(blocked)[blocked], "; extreme fitted:", n_extreme, "\n")

# ---- primary contrasts and inference ------------------------------------------------------------------
G <- n_distinct(d$source)
V <- vcov_cr1(m_prim, d$source)
cs <- t6_contrasts(m_prim)
prim <- delta_tab(cs, V, df = G - 1) |>
  mutate(G = G, df = G - 1, converged = m_prim$converged, n = nobs(m_prim),
         beta_g = coef(m_prim)[paste0("g", group)], se_beta_g = sqrt(diag(V))[paste0("g", group)],
         sep_blocked = blocked[group], n_clipped = attr(V, "n_clipped"), min_eig = attr(V, "min_eig"),
         n_extreme_fitted = n_extreme, gate_pass = t6_gate,
         fail = !gate_pass | !converged | sep_blocked | !is.finite(beta_g) | !is.finite(se_beta_g) |
                !is.finite(se) | se == 0 | p0 <= 0 | p1 <= 0)
write_csv(prim, file.path(out, "t6_primary.csv"))
print(prim |> select(row, est, se, p, ci_lo, ci_hi, fail) |> mutate(across(where(is.numeric), ~ signif(., 5))))

# ---- cluster assessment (reported; decides nothing) ---------------------------------------------------
cs_sz <- table(d$source)
ca <- list(tibble(item = "G (court volumes)", value = G),
           tibble(item = "cluster size min/median/max", value = NA, text = paste(min(cs_sz), median(cs_sz), max(cs_sz), sep = "/")),
           tibble(item = "largest cluster share of N", value = max(cs_sz) / nrow(d)))
for (gr in c("za", names(HG))) {
  dg <- d |> filter(g == gr)
  vs <- dg |> group_by(source) |> summarise(n = n(), mix = any(exactage == 1) & any(exactage == 0), .groups = "drop")
  ca[[length(ca) + 1]] <- tibble(item = paste0("support ", gr, ": volumes with >=1 / with exact+heaped / largest share"),
                                 value = NA, text = sprintf("%d / %d / %.3f", nrow(vs), sum(vs$mix), max(vs$n) / nrow(dg)))
}
ypv <- d |> group_by(source) |> summarise(k = n_distinct(cyear)); vpy <- d |> group_by(cyear) |> summarise(k = n_distinct(source))
nest <- if (all(ypv$k == 1) && all(vpy$k == 1)) "one-to-one" else if (all(ypv$k == 1)) "volumes nest within years" else
  if (all(vpy$k == 1)) "years nest within volumes" else "crossed"
ca[[length(ca) + 1]] <- tibble(item = "cyear per source (min/median/max); source per cyear (min/median/max); nesting", value = NA,
  text = sprintf("%d/%g/%d; %d/%g/%d; %s", min(ypv$k), median(ypv$k), max(ypv$k), min(vpy$k), median(vpy$k), max(vpy$k), nest))
ca[[length(ca) + 1]] <- tibble(item = "distinct cyear", value = n_distinct(d$cyear))
write_csv(bind_rows(ca), file.path(out, "t6_cluster_assessment.csv"))

# cluster influence: psi_c = grad' bread score_c (bread = unscaled inverse information)
X <- model.matrix(m_prim); sco <- X * (m_prim$y - fitted(m_prim)); bread0 <- vcov(m_prim)
Sc <- rowsum(sco, d$source)
infl <- imap_dfr(cs, function(c, gr) map_dfr(c("pt", "rel"), function(s) {
  gv <- c[[paste0("g_", s)]][colnames(X)]; psi <- drop(Sc %*% bread0 %*% gv)
  tibble(row = paste0(HG[gr], "-", s), max_share = max(psi^2) / sum(psi^2), top_volume = rownames(Sc)[which.max(psi^2)])
}))
write_csv(infl, file.path(out, "t6_influence.csv"))
print(infl)
