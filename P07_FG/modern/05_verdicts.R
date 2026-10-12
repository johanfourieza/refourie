# P07_FG S6 step 5: verdict tables of card section 8, applied mechanically.
# Writes output/verdict.csv and output/sensitivities.csv (I1/I2 sensitivities + Theil readings).
source(file.path(here::here(), "P07_FG", "modern", "00_engine.R"))
ver <- read_csv(file.path(OUT, "verification.csv"), show_col_types = FALSE)
VER_OK <- ver$note[ver$check == "ALL"] == "PASS"
sc <- read_csv(file.path(OUT, "scenarios.csv"), show_col_types = FALSE)
th <- read_csv(file.path(OUT, "theil.csv"), show_col_types = FALSE)
cen <- sc |> filter(central)
f3 <- function(x) formatC(x, format = "f", digits = 3)

# ---- descriptive verdicts (I1a-mag, I1b, I1c, I2a, I2b): card 8, rules 0-4 ----
desc <- tribble(~claim, ~headline, ~stat, ~band, ~inR,
  "I1a-mag", "tx_p205_kh_growth (3.8)", "gK", "R+: g_K >= 1.9", function(v) v >= 1.9,
  "I1b", "tx_p205 'equivalent to slaves'", "rKS", "R+: r_KS in [0.80, 1.25]", function(v) v >= 0.80 & v <= 1.25,
  "I1c", "T1_1773_all_khoesan (6,843)", "I1c", "R+: K_1773/6843 in [0.90, 1.10]", function(v) v >= 0.90 & v <= 1.10,
  "I2a", "T5_Total_wheat_pct (-43.4)", "P_T5", "R+: P_T5 <= -21.7", function(v) v <= -21.7,
  "I2b", "T3_Total_without/with (14.5/8.2)", "P_T3", "R+: P_T3 <= -21.72", function(v) v <= -21.72)
vd <- bind_rows(lapply(seq_len(nrow(desc)), function(i) { r <- desc[i, ]; f <- r$inR[[1]]
  c0 <- cen[[r$stat]]; A <- sc[[r$stat]]; fin <- is.finite(A); nmiss <- sum(!fin)
  if (!VER_OK || !is.finite(c0)) { v <- "not-testable"; rule <- "0" }
  else if (f(c0) && all(fin) && all(f(A))) { v <- "confirmed"; rule <- "1" }
  else if (f(c0)) { v <- if (nmiss > 0) "qualified (range incomplete)" else "qualified (assumption-sensitive)"; rule <- "2" }
  else if (all(fin) && all(!f(A))) { v <- "overturned (contradicted under every assumption in A)"; rule <- "3" }
  else { v <- if (nmiss > 0) "weakened (range incomplete)" else "weakened (assumption-sensitive)"; rule <- "4" }
  tibble(claim = r$claim, headline = r$headline, estimate = c0, interval = paste0("A range [", f3(min(A[fin])), ", ", f3(max(A[fin])), "] (assumption range, not a CI)"),
         test_p = NA_real_, threshold_or_band = r$band, verdict = v, rule = rule,
         note = paste0(sum(f(A[fin])), "/16 scenarios in R+; non-finite ", nmiss)) }))

# plausibility flag (A8; not verdict-deciding)
flag <- c(gK = cen$gK > 5.7, P_T5 = abs(cen$P_T5) > 65.1, P_T3 = abs(cen$P_T3) > 65.17)
vd$note[vd$claim == "I1a-mag"] <- paste0(vd$note[vd$claim == "I1a-mag"], "; plausibility flag (g_K > 5.7): ", ifelse(flag["gK"], "RAISED", "not raised"))
vd$note[vd$claim == "I2a"] <- paste0(vd$note[vd$claim == "I2a"], "; plausibility flag (|P_T5| > 65.1): ", ifelse(flag["P_T5"], "RAISED", "not raised"))
vd$note[vd$claim == "I2b"] <- paste0(vd$note[vd$claim == "I2b"], "; plausibility flag (|P_T3| > 65.17): ", ifelse(flag["P_T3"], "RAISED", "not raised"))

# ---- I1a-fid (deterministic reporting accuracy) ----
fid <- tibble(claim = "I1a-fid", headline = "tx_p205_kh_growth (3.8) vs printed 122 -> 6,843", estimate = G_PUB, interval = NA_character_, test_p = NA_real_,
              threshold_or_band = "confirmed if g_pub in [3.42, 4.18]",
              verdict = if (!is.finite(G_PUB)) "not-testable" else if (G_PUB >= 3.42 && G_PUB <= 4.18) "confirmed (reporting)" else "overturned (reporting: the printed rate does not follow from the printed endpoints)",
              rule = if (!is.finite(G_PUB)) "0" else if (G_PUB >= 3.42 && G_PUB <= 4.18) "1" else "2",
              note = "g_pub = 100*((6843/122)^(1/88)-1); verdict known before freeze (card 7, 10)")

# ---- directional claims: not-testable (inference) with deterministic direction ----
sgn <- function(x) ifelse(x > 0, "up", ifelse(x < 0, "down", "zero"))
dA <- sgn(sc$K1773 - sc$K1685)
dir1 <- tibble(claim = "I1a-dir", headline = "T1_1685/1773_all_khoesan (122 -> 6,843) 'increased'", estimate = cen$K1773 - cen$K1685,
               interval = NA_character_, test_p = NA_real_, threshold_or_band = "no margin (no valid interval)",
               verdict = "not-testable (inference)", rule = "directional",
               note = paste0("deterministic direction central: ", sgn(cen$K1773 - cen$K1685), " (K 1685 ", round(cen$K1685, 1), " -> 1773 ", round(cen$K1773, 1),
                             "); same direction in ", sum(dA == sgn(cen$K1773 - cen$K1685)), "/16 scenarios of A"))
th4 <- th |> filter(grepl("^I3[bc]-", claim))
dir3 <- th4 |> transmute(claim, headline = "T7_GiniAll_fvf/khoesan row context (Theil, p.213/215)", estimate = new - old, interval = NA_character_, test_p = NA_real_,
                          threshold_or_band = "no margin (no valid interval)", verdict = "not-testable (inference); disputed (C7 vs F4)", rule = "directional",
                          note = paste0("deterministic direction: ", direction, " (", round(old, 4), " -> ", round(new, 4), ", basis ", basis, "); ",
                                        ifelse(agrees_with_authors, "agrees", "does not agree"), " with the authors' wording ('", authors, "')"))

# ---- not-testable by design ----
ntd <- tribble(~claim, ~headline, ~note,
  "I1d", "p.205 'did not leave the area'", "migration and pastoral abandonment unobserved; Table 1 is settler herd value",
  "I2c", "p.205 'slavery not as productive'", "economic productivity needs farm-level Khoesan inputs and their allocation",
  "I3a", "T7_GiniAll_fvf/khoesan (0.74/0.50)", paste0("no code or person-level microdata; sensitivity 11: total Theil ", th$old[th$claim == "I3a (sensitivity 11)"], " -> D12 ", round(th$new[th$claim == "I3a (sensitivity 11)"], 4), " (different index, no verdict)")) |>
  mutate(estimate = NA_real_, interval = NA_character_, test_p = NA_real_, threshold_or_band = NA_character_, verdict = "not-testable", rule = "by design")

# ---- group summaries ----
ord <- c("not-testable", "overturned", "weakened", "qualified", "confirmed")
lvl <- function(v) match(sub(" .*", "", v), ord)
weakest <- function(cl) { v <- vd$verdict[vd$claim %in% cl]; v[which.min(lvl(v))] }
grp <- tibble(claim = c("I1 (group)", "I2 (group)"), headline = c("weakest of I1a-mag, I1b, I1c", "weaker of I2a, I2b"),
              estimate = NA_real_, interval = NA_character_, test_p = NA_real_, threshold_or_band = NA_character_,
              verdict = c(weakest(c("I1a-mag", "I1b", "I1c")), weakest(c("I2a", "I2b"))), rule = "group summary (card 8)", note = NA_character_)

verdict <- bind_rows(dir1, vd[1, ], fid, vd[2:5, ], grp, dir3, ntd) |>
  select(claim, headline, estimate, interval, test_p, threshold_or_band, verdict, rule, note)
write_csv(verdict, file.path(OUT, "verdict.csv"))

# ---- combined sensitivities.csv ----
s1 <- read_csv(file.path(OUT, "sensitivities_I1I2.csv"), show_col_types = FALSE)
s11 <- th |> transmute(sensitivity = ifelse(claim == "I3a (sensitivity 11)", "11 total Theil level", "Theil readings (card 4.4)"),
                       variant = paste0(claim, ", ", basis), statistic = "old -> new", value = new, old = old, direction = direction)
write_csv(bind_rows(s1 |> mutate(old = NA_real_, direction = NA_character_), s11), file.path(OUT, "sensitivities.csv"))
options(width = 220); print(as.data.frame(verdict |> select(claim, estimate, verdict, rule) |> mutate(estimate = round(estimate, 3))))
