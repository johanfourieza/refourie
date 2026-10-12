# P17_FvFH S6 -- 02_primary.R: point rows and the stratified household bootstrap (card §4B-C)
source(here::here("P17_FvFH", "modern", "00_functions.R"))
b <- readRDS(file.path(SCR, "build.rds"))$b
L <- mats(b); pt <- stat(L)
t0 <- Sys.time(); D1 <- boot_draws(L, 9999, 20261012); t1 <- Sys.time()
D2 <- boot_draws(L, 9999, 20261013)
cat("bootstrap minutes per run:", round(as.numeric(difftime(t1, t0, units = "mins")), 2), "\n")
saveRDS(list(pt = pt, D1 = D1, D2 = D2), file.path(SCR, "primary.rds"))
ci1 <- ci_tab(pt, D1); ci2 <- ci_tab(pt, D2)
fails <- colSums(is.na(D1))
prim <- bind_rows(tibble(quantity = c("G1700", "G1723", "G1757", paste0("S_", SRC), paste0("C_", SRC)),
  estimate = pt[quantity], se = apply(D1[, quantity], 2, sd, na.rm = TRUE), failed = fails[quantity]),
  mutate(ci1, lo_seed2 = ci2$lo, hi_seed2 = ci2$hi)) %>% mutate(B = 9999, seed = 20261012, level = 1 - 0.05 / 9)
write_csv(prim, file.path(OUT, "primary.csv"))
v1 <- verdicts(pt, ci1); v2 <- verdicts(pt, ci2)
v1 <- v1 %>% mutate(seed2_verdict = v2$verdict, mc_flag = ifelse(verdict != seed2_verdict, "Monte Carlo-unstable", ""))
write_csv(v1, file.path(OUT, "verdict.csv"))
print(as.data.frame(mutate(prim, across(where(is.numeric), ~ signif(., 4))))); print(as.data.frame(v1[, c(1, 2, 3, 6, 7, 9)]))
