# =============================================================================
# P08_SAC  S6 modern reanalysis  --  04_descriptives.R
# Descriptive rows (card §4, §8): I1-L, I1-T, I3-L, I6-L; descriptive
# sensitivities §5.9e (height quantiles) and §5.10 (persons, missingness);
# assembles output/primary.csv and output/verdict.csv (§8 rules, headline
# mapping) and draws the coefficient/range figure.
# Aggregates only.
# =============================================================================
suppressMessages({library(tidyverse)})
PROJ <- "."
source(file.path(PROJ, "tools", "paths.R"))
MOD <- file.path(PROJ, "P08_SAC", "modern"); OUT <- file.path(MOD, "output")
SCR <- dscratch("P08_SAC", "modern")
d <- readRDS(file.path(SCR, "sac_all.rds")); inf <- readRDS(file.path(SCR, "inference.rds"))
ver <- readRDS(file.path(SCR, "verification.rds"))$verification
first <- d %>% filter(repeatlast == 0)
UK <- c(1, 7, 8, 10)
known <- function(x) !is.na(x) & !(trimws(x) %in% c(".", ""))

# ---------------------------------------------------- I1 composition -------
c1 <- first %>% filter(known(country))
uk <- mean(c1$regiondum %in% UK); eng <- mean(c1$regiondum %in% 1)
# ---------------------------------------------------- I3-L, I6-L -----------
t1 <- first %>% filter(!is.na(regiondum))
h_eng <- mean(t1$height[t1$regiondum == 1], na.rm = TRUE); h_cap <- mean(t1$height[t1$regiondum == 9], na.rm = TRUE)
w_boer <- mean(t1$wage[t1$regiondum == 5], na.rm = TRUE)

desc <- list()
dv <- function(claim, est, band_lo, band_hi, band_txt, n, extra = "") {
  v <- if (is.na(est)) c("not-testable", "0") else if (est >= band_lo & est <= band_hi) c("confirmed", "1") else c("qualified (level differs)", "2")
  desc[[length(desc) + 1]] <<- tibble(claim, estimate = est, ci_lo = NA_real_, ci_hi = NA_real_, p1 = NA_real_, p2 = NA_real_,
                                      band = band_txt, verdict = v[1], rule = v[2], n = n, flags = extra) }
dv("I1-L", uk, 0.801, 0.861, "0.801 <= UK share <= 0.861 (A8 +-0.03)", nrow(c1))
desc[[length(desc) + 1]] <- tibble(claim = "I1-T", estimate = uk, ci_lo = NA, ci_hi = NA, p1 = NA, p2 = NA, band = "UK share > 0.5",
                                   verdict = if (uk > 0.5) "confirmed" else "overturned", rule = if (uk > 0.5) "1" else "2", n = nrow(c1),
                                   flags = sprintf("England-born share %.4f (%s 0.5; literal 'English' reading)", eng, if (eng > 0.5) ">" else "<="))
# I3-L: both levels within +-10%
i3ok <- abs(h_eng - 172.91) <= 17.291 & abs(h_cap - 175.03) <= 17.503
desc[[length(desc) + 1]] <- tibble(claim = "I3-L", estimate = NA_real_, ci_lo = NA, ci_hi = NA, p1 = NA, p2 = NA,
                                   band = "each level within +-10% of 172.91 / 175.03 cm", verdict = if (i3ok) "confirmed" else "qualified (level differs)",
                                   rule = if (i3ok) "1" else "2", n = sum(!is.na(t1$height) & t1$regiondum %in% c(1, 9)),
                                   flags = sprintf("England %.3f; Cape/Natal %.3f cm", h_eng, h_cap))
dv("I6-L", w_boer, 4.014, 4.906, "4.014 <= mean <= 4.906 shillings/day (+-10%)", sum(!is.na(t1$wage) & t1$regiondum == 5))
desc <- bind_rows(desc)

# ---------------------------------------------------- §5.9e quantiles ------
lab <- c(`1` = "England", `2` = "Americas", `3` = "Asia", `4` = "Australasia", `5` = "Boer republics", `6` = "Europe",
         `7` = "Ireland", `8` = "Scotland", `9` = "Cape/Natal", `10` = "Wales")
qtab <- t1 %>% filter(!is.na(height)) %>% group_by(regiondum) %>%
  summarise(n = n(), q25 = quantile(height, .25), q50 = quantile(height, .5), q75 = quantile(height, .75), mean = mean(height), .groups = "drop") %>%
  mutate(region = lab[as.character(regiondum)])
sens_desc <- qtab %>% pivot_longer(c(q25, q50, q75, mean), names_to = "stat", values_to = "estimate") %>%
  transmute(section = "5.9", row = "I3", variant = paste0("(e) recruit-height ", stat, ", ", region, " (descriptive, not truncation-corrected)"), estimate, n)

# ---------------------------------------------------- §5.10 persons, missingness
s3p <- readRDS(dpath("P08_SAC", "compare", "_scratch", "sac_persons.rds"))
s3k <- s3p %>% filter(!is.na(region))
allk <- d %>% filter(known(country))
add10 <- function(variant, est, n, note = "") tibble(section = "5.10", row = "I1", variant, estimate = est, n = n, note = note)
sens10 <- bind_rows(
  add10("UK share, S3 Unique-run persons (first terms)", mean(s3k$region %in% c("England", "Scotland", "Ireland", "Wales")), nrow(s3k)),
  add10("England share, S3 Unique-run persons (first terms)", mean(s3k$region == "England"), nrow(s3k)),
  add10("UK share, all service terms", mean(allk$regiondum %in% UK), nrow(allk)),
  add10("England share, all service terms", mean(allk$regiondum %in% 1), nrow(allk)),
  add10("UK share, Repeatlast != 1 (8,887-row definition)", mean(d$regiondum[d$repeatlast != 1 & known(d$country)] %in% UK), sum(d$repeatlast != 1 & known(d$country))),
  add10("persons: rows with Repeatlast == 0", sum(d$repeatlast == 0), NA),
  add10("persons: rows with Repeatlast != 1", sum(d$repeatlast != 1), NA, "Repeatlast = 2 or 3 rows are third/fourth terms"),
  add10("first terms with unknown country (share)", mean(!known(first$country)), nrow(first)),
  t1 %>% group_by(regiondum) %>% summarise(h = mean(is.na(height)), w = mean(is.na(wage)), n = n(), .groups = "drop") %>%
    mutate(region = lab[as.character(regiondum)]) %>%
    { bind_rows(transmute(., section = "5.10", row = "I3/I6", variant = paste0("missing height share, ", region), estimate = h, n = n, note = ""),
                transmute(., section = "5.10", row = "I3/I6", variant = paste0("missing wage share, ", region), estimate = w, n = n, note = "")) })
sens <- read_csv(file.path(OUT, "sensitivities.csv"), show_col_types = FALSE) %>% filter(!section %in% c("5.10") & !grepl("^\\(e\\)", variant))
sens <- bind_rows(sens, sens_desc, sens10)
write_csv(sens, file.path(OUT, "sensitivities.csv"))

# ---------------------------------------------------- verdict assembly -----
iv <- inf$verdicts %>% mutate(n = NA_integer_,
  flags = pmap_chr(list(vflag, secondary_disagreement, plaus), function(a, b, c)
    paste(c(if (isTRUE(a)) "WCR validity flag raised", if (isTRUE(b)) "secondary disagreement (p2 on other side of 0.01)",
            if (isTRUE(c)) "plausibility flag (>1.5x stated)"), collapse = "; "))) %>%
  select(claim, estimate, ci_lo, ci_hi, p1, p2, band, verdict, rule, n, flags)
nt <- tibble(claim = c("I2", "I4-D"), estimate = c(10399, NA), ci_lo = NA, ci_hi = NA, p1 = NA, p2 = NA,
             band = c("count of digitised records; S4 governs", "discrimination not identified by these data"),
             verdict = "not-testable", rule = c("I2 rule", "I4-D rule"), n = NA, flags = c("Augmented sheet has 10,399 rows", "OB reported as sensitivity 5.5"))
V <- bind_rows(desc, iv, nt)
ord <- c("not-testable", "overturned", "weakened", "qualified", "confirmed")
rank_v <- function(v) match(sub(" .*", "", sub("^not-testable.*", "not-testable", v)), ord)
weakest <- function(cl) { vv <- V$verdict[match(cl, V$claim)]; vv[which.min(rank_v(vv))] }
H <- tibble(claim = c("HEADLINE tx_p585_uk", "HEADLINE T1_England_height / T1_SouthernAfrica_height", "p.592 cohort claim (own verdict)",
                      "HEADLINE T3_afrikaans_s4", "HEADLINE T3_england_s4", "HEADLINE T1_Boerrepublics_wage", "HEADLINE tx_p580_terms"),
            members = c("I1-L, I1-T", "I3-L, I3a-C, I3a-M", "I3b-C", "I4-LP, I4-PCT (I4-D beside: not-testable)", "I5-LP, I5-PCT", "I6-L, I6-C", "I2"),
            verdict = c(weakest(c("I1-L", "I1-T")), weakest(c("I3-L", "I3a-C", "I3a-M")), weakest("I3b-C"), weakest(c("I4-LP", "I4-PCT")),
                        weakest(c("I5-LP", "I5-PCT")), weakest(c("I6-L", "I6-C")), weakest("I2")))
fmt <- function(x, k = 4) ifelse(is.na(x), "", formatC(x, digits = k, format = "fg", flag = "#"))
verdict_csv <- bind_rows(
  V %>% transmute(claim, estimate = fmt(estimate, 5),
                  interval = ifelse(is.na(ci_lo), "", paste0("[", fmt(ci_lo, 4), ", ", fmt(ci_hi, 4), "] (99%)")),
                  test_p = ifelse(is.na(p1), "", paste0("p1=", signif(p1, 3), ifelse(is.na(p2), "", paste0("; p2=", signif(p2, 3))))),
                  threshold_or_band = band, verdict, rule_number = rule, flags),
  H %>% transmute(claim, estimate = "", interval = "", test_p = "", threshold_or_band = paste("weakest of", members), verdict,
                  rule_number = "headline mapping (§8)", flags = ""))
write_csv(verdict_csv, file.path(OUT, "verdict.csv"))
print(verdict_csv %>% select(claim, estimate, interval, verdict, rule_number) %>% as.data.frame(), right = FALSE)

# primary.csv: inferential primary + diagnostics, and descriptive rows
P <- bind_rows(read_csv(file.path(SCR, "primary_inferential.csv"), show_col_types = FALSE),
               desc %>% transmute(hyp = claim, estimand = paste("descriptive:", band), estimate, n, primary_test = "none (descriptive, A8 band)", note = flags))
write_csv(P, file.path(OUT, "primary.csv"))

# ---------------------------------------------------- figure ----------------
pal <- c(primary = "#5C2346", inference = "#3D8EB9", classifier = "#6B8E5E", estimand = "#D4A03E")
S <- read_csv(file.path(OUT, "sensitivities.csv"), show_col_types = FALSE)
w4 <- inf$wage %>% filter(hyp == "I4"); di <- inf$diff
pick <- function(sec, rw, pat) S %>% filter(section == sec, row == rw, grepl(pat, variant, fixed = TRUE)) %>% slice(1)
fig_a <- bind_rows(
  tibble(lab = "Primary: WCR (Webb), year x month", est = w4$estimate, lo = w4$ci99_lo, hi = w4$ci99_hi, type = "primary"),
  pick("5.1", "I4", "HC3") %>% transmute(lab = "HC3", est = estimate, lo = ci99_lo, hi = ci99_hi, type = "inference"),
  pick("5.1", "I4", "CR2") %>% transmute(lab = "CR2, BM df", est = estimate, lo = ci99_lo, hi = ci99_hi, type = "inference"),
  pick("5.2", "I4", "WCR Webb, clusters place") %>% transmute(lab = "WCR, place clusters", est = estimate, lo = ci99_lo, hi = ci99_hi, type = "inference"),
  pick("5.3a", "I4", "WCR Webb") %>% transmute(lab = "S3 surname rule (WCR)", est = estimate, lo = ci99_lo, hi = ci99_hi, type = "classifier"),
  pick("5.3b", "I4", "probabilistic") %>% transmute(lab = "Surname score (bootstrap)", est = estimate, lo = ci99_lo, hi = ci99_hi, type = "estimand"),
  pick("5.4", "I4", "SA-born only, authors' flag, WCR") %>% transmute(lab = "SA-born only, authors' flag (WCR)", est = estimate, lo = ci99_lo, hi = ci99_hi, type = "classifier"),
  pick("5.4", "I4", "SA-born only, S3 rule, WCR") %>% transmute(lab = "SA-born only, S3 rule (WCR)", est = estimate, lo = ci99_lo, hi = ci99_hi, type = "classifier")) %>%
  mutate(panel = "A. Afrikaans wage gap, spec 4 (log points)")
fig_b <- bind_rows(
  di %>% filter(hyp == "I3a") %>% transmute(lab = "Primary I3a: Cape/Natal - England (HC2)", est = estimate, lo = ci99_lo, hi = ci99_hi, type = "primary"),
  di %>% filter(hyp == "I3b") %>% transmute(lab = "Primary I3b: SA - GB, born 1860-85 (HC2)", est = estimate, lo = ci99_lo, hi = ci99_hi, type = "primary"),
  pick("5.1", "I3a", "CR2") %>% transmute(lab = "I3a, CR2 year x month", est = estimate, lo = ci99_lo, hi = ci99_hi, type = "inference"),
  pick("5.9", "I3a", "(a) adult") %>% transmute(lab = "I3a, adults 20-50, age FE", est = estimate, lo = ci99_lo, hi = ci99_hi, type = "estimand"),
  pick("5.9", "I3a", "(c) age >= 23") %>% transmute(lab = "I3a, age >= 23, age FE", est = estimate, lo = ci99_lo, hi = ci99_hi, type = "estimand")) %>%
  mutate(panel = "B. Height gap (cm)")
fg <- bind_rows(fig_a, fig_b) %>% mutate(lab = factor(lab, levels = rev(unique(lab))),
  type = factor(type, levels = names(pal), labels = c("Primary", "Inference variant", "Classifier / sample", "Different estimand")))
p <- ggplot(fg, aes(x = est, y = lab, colour = type)) +
  geom_vline(xintercept = 0, colour = "#AAAAAA", linewidth = 0.4) +
  geom_errorbar(aes(xmin = lo, xmax = hi), width = 0.25, linewidth = 0.6, orientation = "y") + geom_point(size = 2.2) +
  facet_wrap(~panel, scales = "free", ncol = 1) +
  scale_colour_manual(values = unname(pal), name = NULL) + scale_x_continuous(expand = expansion(mult = 0.08)) +
  labs(x = "Estimate with 99% interval", y = NULL) +
  theme_minimal(base_size = 10) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        strip.text = element_text(hjust = 0, face = "bold"), axis.line.x = element_line(colour = "#AAAAAA"))
ggsave(file.path(OUT, "fig_s6_estimates.pdf"), p, width = 7, height = 6.5)
ggsave(file.path(OUT, "fig_s6_estimates.png"), p, width = 7, height = 6.5, dpi = 300)

suppressMessages({library(sandwich); library(clubSandwich); library(fwildclusterboot); library(dqrng); library(readxl); library(haven)})
writeLines(capture.output(sessionInfo()), file.path(MOD, "sessionInfo.txt"))
