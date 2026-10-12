# P26_NF S6 sensitivities S1-S9 (method card v3, §5). Reported only; none decides a verdict.
# S5/S6 reuse the locked S3 rebuild (repro_r/01_clean.R, 02_analysis.R at 35b12d7): its scratch r09.rds (1909 dictionary)
# and yr.rds (year rolls), plus a re-read of the four 1886/1887 sheets for the dropped-record counts (F6). Deterministic.
suppressMessages({library(tidyverse); library(readxl); library(here)})
source(here::here("tools", "paths.R"))
od <- here::here("P26_NF", "modern", "output")
p <- readRDS(dscratch("P26_NF", "modern", "primary.rds")); D <- p$D; wide <- p$wide; B0 <- p$B; W0 <- p$W
fall <- function(d) c(B = sum(d$T1_1886) - sum(d$T1_1887), W = sum(d$T2_1886) - sum(d$T2_1887))
row4 <- function(sens, spec, d, pop) { f <- fall(d); tibble(sens, spec, population = pop, n_div = nrow(d), B = f[["B"]], W = f[["W"]], Delta = f[["W"]] - f[["B"]], R = 30000 - f[["B"]]) }
res <- list()

# S1 published division sets (14-division 1886 minus 16-division 1887)
f1 <- c(B = sum(wide$T1_1886, na.rm = TRUE) - sum(wide$T1_1887), W = sum(wide$T2_1886, na.rm = TRUE) - sum(wide$T2_1887))
res$S1 <- tibble(sens = "S1", spec = "published division sets (as printed)", population = "14 (1886) vs 16 (1887)", n_div = 16, B = f1[["B"]], W = f1[["W"]], Delta = f1[["W"]] - f1[["B"]], R = 30000 - f1[["B"]])
# S2 method-consistent set
res$S2 <- row4("S2", "D minus Uitenhage, Victoria East (method switchers)", filter(D, !name %in% c("Uitenhage", "Victoria East")), "changed (A4d)")
# S3 leave-one-division-out
res$S3 <- bind_rows(lapply(D$name, function(n) row4("S3", paste("drop", n), filter(D, name != n), "changed (A4d), influence only")))
# S4 16-division imputation
miss <- wide |> filter(is.na(T1_1886))
imp_a <- bind_rows(D, miss |> mutate(T1_1886 = T1_1887, T2_1886 = T2_1887))
imp_b <- bind_rows(D, miss |> mutate(T1_1886 = T1_1887 * sum(D$T1_1886) / sum(D$T1_1887), T2_1886 = T2_1887 * sum(D$T2_1886) / sum(D$T2_1887)))
res$S4 <- bind_rows(row4("S4a", "16 divisions, 1886 = 1887 for Griqualand East, Thembuland", imp_a, "changed (A4d)"),
                    row4("S4b", "16 divisions, 1886 = 1887 x D-ratio (T1, T2 separately)", imp_b, "changed (A4d)"))
# S7 proportional falls and white/coloured benchmark (different estimand)
s7 <- tibble(sens = "S7", quantity = c("black_rate", "white_col_rate", "excess_black_fall"),
  value = c(B0 / sum(D$T1_1886), W0 / sum(D$T2_1886), B0 - (W0 / sum(D$T2_1886)) * sum(D$T1_1886)))
# S8 colony-wide context
cl <- read_csv(here::here("P26_NF", "claims", "claims.csv"), col_types = cols(.default = "c"))
s8 <- as.numeric(gsub(",", "", cl$reported_value[cl$claim_id == "TX_total_stat_fall"]))
# S9 classification-coupling scenario grid
m <- seq(0.5, 1.5, by = 0.1)
s9 <- tibble(m, B = m * B0, W = W0 + B0 - m * B0) |>
  mutate(Bpt = B >= 2542.5 & B <= 3107.5, Brng = B >= 2800 & B <= 3000, Blt = B > 0 & B < 3000, Bten = B >= 2700 & B <= 3300,
         Wpt = W >= 7140.6 & W <= 8727.4, Wcmp = W > 0 & B > 0 & W - B > 0)
s9_sum <- tibble(sens = "S9", quantity = c("m_B_eq_3000", "m_W_eq_7934", "B_min", "B_max", "W_min", "W_max", paste0("share_", c("Bpt", "Brng", "Blt", "Bten", "Wpt", "Wcmp"))),
  value = c(3000 / B0, (W0 + B0 - 7934) / B0, range(s9$B), range(s9$W), colMeans(s9[, c("Bpt", "Brng", "Blt", "Bten", "Wpt", "Wcmp")])))
write_csv(s9, file.path(od, "s9_grid.csv"))

# S5 classification rules on the five divisions with recovered 1886 and 1887 rolls (rebuild algorithm at 35b12d7)
scr <- dscratch("P26_NF", "repro_r"); r09 <- readRDS(file.path(scr, "r09.rds")); yr <- readRDS(file.path(scr, "yr.rds"))
build <- function(codes, rule = "any") {
  s <- r09 |> filter(!is.na(race)) |> group_by(key) |> summarise(nb = sum(race %in% codes), n = n(), .groups = "drop")
  if (rule == "any") s$key[s$nb > 0 & s$key != ""] else s$key[s$nb / s$n > 0.5 & s$key != ""]
}
rules <- list(any = build(c("K", "F", "I", "B")), majority = build(c("K", "F", "I", "B"), "majority"), KF = build(c("K", "F")))
dy <- yr |> filter(!is.na(division), year %in% c(1886, 1887)) |> group_by(division, year, k) |> mutate(n_sheet = n()) |>
  group_by(division, year) |> filter(k == k[which.max(n_sheet)][1]) |> ungroup()
five <- dy |> group_by(division) |> filter(n_distinct(year) == 2) |> ungroup()
five_div <- sort(unique(five$division)); all09 <- unique(r09$key[r09$key != ""])
cls <- bind_rows(lapply(names(rules), function(r) five |> mutate(black = key %in% rules[[r]], unmatched = !key %in% rules[[r]]) |>
  group_by(division, year, sheet = k) |> summarise(roll = n(), black = sum(black), unmatched = sum(unmatched), empty_key = sum(key == ""), .groups = "drop") |> mutate(rule = r)))
pubc <- wide |> mutate(division = substr(gsub("[^A-Za-z]", "", name), 1, 8)) |> filter(division %in% five_div)
pub_long <- pubc |> pivot_longer(c(T1_1886, T1_1887, T2_1886, T2_1887), names_to = c("t", "year"), names_sep = "_") |>
  pivot_wider(names_from = t, values_from = value) |> transmute(division, year = as.numeric(year), pub_black = T1, pub_total = T1 + T2)
# F6 record integrity: re-read the four 1886/87 sheets as in 01_clean.R, before its surname filter
b <- dpath("P26_NF", "original"); nm <- c("folder","image","div","cornet","no","surname","first","prof","qual","sit","emp","race","italics")
rd <- function(f, s) { d <- read_excel(file.path(b, f), sheet = s, col_names = FALSE, .name_repair = "minimal", col_types = "text", skip = 1)
  while (ncol(d) < 13) d[[paste0("x", ncol(d))]] <- NA_character_; d <- d[, 1:13]; names(d) <- nm; d }
raw <- bind_rows(rd("1870-1909/July 2018.xlsx", "18") |> mutate(k = "J18"), rd("1870-1909/July 2018.xlsx", "22") |> mutate(k = "J22"),
                 rd("Laura Voters/Voters1.xls", "19") |> mutate(k = "V19"), rd("Laura Voters/Voters1.xls", "21") |> mutate(k = "V21")) |>
  group_by(k) |> fill(div, .direction = "down") |> ungroup() |> mutate(dl = tolower(div),
  division = case_when(grepl("kimber", dl) ~ "Kimberle", grepl("king w", dl) ~ "KingWill", grepl("port eliz", dl) ~ "PortEliz",
    grepl("queen", dl) ~ "Queensto", grepl("wodeho|woodho", dl) ~ "Wodehous", TRUE ~ NA_character_)) |> filter(!is.na(division))
f6 <- raw |> group_by(sheet = k, division) |> summarise(records_read = n(), dropped_empty = sum(is.na(surname) | surname == "."), .groups = "drop")
s5 <- cls |> left_join(pub_long, by = c("division", "year")) |> left_join(f6, by = c("sheet", "division")) |>
  mutate(white_col = roll - black, roll_minus_pub_total = roll - pub_total)
write_csv(s5, file.path(od, "s5_division_year.csv"))
s5_sum <- s5 |> group_by(rule, year) |> summarise(black = sum(black), white_col = sum(white_col), roll = sum(roll), pub_black = sum(pub_black), pub_total = sum(pub_total), .groups = "drop") |>
  pivot_wider(names_from = year, values_from = c(black, white_col, roll, pub_black, pub_total)) |>
  mutate(B5 = black_1886 - black_1887, W5 = white_col_1886 - white_col_1887, B5_pub = pub_black_1886 - pub_black_1887)
# S6 1909 dictionary coverage, every 1886/87 sheet x division
s6 <- yr |> filter(!is.na(division), year %in% c(1886, 1887)) |> group_by(year, sheet = k, division) |>
  summarise(n = n(), share_in_1909 = mean(key %in% all09), .groups = "drop")
write_csv(s6, file.path(od, "s6_coverage.csv"))

# ---- assemble sensitivities.csv (long format)
counts <- bind_rows(res) |> pivot_longer(c(B, W, Delta, R), names_to = "quantity")
s5l <- s5_sum |> select(rule, B5, W5, B5_pub, roll_1886, pub_total_1886, roll_1887, pub_total_1887) |> pivot_longer(-rule, names_to = "quantity") |>
  transmute(sens = "S5", spec = paste("rule", rule, "on", paste(five_div, collapse = "/")), population = "five recovered divisions (joint classification + roll contrast)", n_div = 5, quantity, value)
s6l <- s6 |> transmute(sens = "S6", spec = paste(division, year, sheet), population = "coverage", n_div = 1, quantity = "share_in_1909", value = share_in_1909)
other <- bind_rows(s7 |> mutate(spec = "proportional falls on D", population = "different-estimand", n_div = nrow(D)),
  tibble(sens = "S8", quantity = "colony_net_fall_all_races", value = s8, spec = "Statistical Register 1886-87", population = "context (net, not gross)", n_div = NA),
  s9_sum |> mutate(spec = "B(m), W(m) on D, m in 0.5..1.5", population = "scenario (equal weights assumed)", n_div = nrow(D)))
sens <- bind_rows(counts, s5l, s6l, other) |> select(sens, spec, population, n_div, quantity, value)
write_csv(sens, file.path(od, "sensitivities.csv"))
cat("S1:", f1, "\n"); print(bind_rows(res$S2, res$S4)); print(res$S3 |> summarise(across(c(B, W, Delta, R), list(min = min, max = max))))
print(s7); print(s9_sum); print(s5_sum |> select(rule, B5, W5, B5_pub, roll_1886, pub_total_1886, roll_1887, pub_total_1887)); print(f6); print(s6, n = 40)
saveRDS(list(res = res, s5_sum = s5_sum), dscratch("P26_NF", "modern", "sens.rds"))
