# P17_FvFH S6 -- 01_build.R: rebuild farm incomes (card §3) and the §4A diagnostics (decide nothing)
source(here::here("P17_FvFH", "modern", "00_functions.R"))
o <- load_roll(); b <- build(o)
saveRDS(list(o = o, b = b), file.path(SCR, "build.rds"))
# Verification: household size reproduces the S3 burgher counts (T2 current-sample column)
ver <- b %>% group_by(jaar) %>% summarise(rows = n(), burghers = sum(n), n0 = sum(n == 0), A0 = sum(n > 0 & A == 0),
  farming = sum(farm), sum_w_farming = sum(w[farm]), distinct_name = n_distinct(paste(van, naam)), distinct_loc = n_distinct(loc),
  dup_rows = sum(duplicated(o[o$jaar == first(jaar), ])), missing_counts = 0L, .groups = "drop") %>%
  mutate(T2_cur = pv[paste0("T2_cur_", jaar, "_burgher_total")], T4_farming_pop = pv[paste0("T4_", jaar, "_farming_burgher_pop")])
write_csv(ver, file.path(OUT, "diag_counts.csv"))
# Rebuilt decomposition beside Tables 6 and 8 (all three years)
L <- mats(b)
dg <- map_dfr(as.character(YRS), function(t) { d <- decomp(L[[t]]$M[L[[t]]$farm, ], full = TRUE)
  tibble(year = as.numeric(t), source = c(SRC, "total"),
    share = c(d$S, 1), gini = c(d$Gk, d$G), rank = c(d$Rk, NA), contrib = c(d$C, 1), elast = c(d$elast, NA)) }) %>%
  mutate(p_share = pv[paste0("T8_", year, "_", source, "_share")], p_gini = pv[paste0("T8_", year, "_", source, "_gini")],
    p_rank = pv[paste0("T8_", year, "_", source, "_rank")], p_contrib = pv[paste0("T8_", year, "_", source, "_contrib")],
    p_elast = pv[paste0("T8_", year, "_", source, "_elast")], T6_fb = ifelse(source == "total", pv[paste0("T6_fb_defl_", year)], NA))
write_csv(dg, file.path(OUT, "diag_decomposition.csv"))
print(as.data.frame(ver)); print(as.data.frame(mutate(dg, across(where(is.numeric), ~ round(., 3)))))
