# P12 S5 check 1: internal consistency of the published Table 5 and text numbers (no data needed).
suppressMessages({library(readr); library(dplyr)})
cl <- read_csv("P12_FJ/claims/claims.csv", col_types = cols(.default = "c"))
t5 <- cl %>% filter(grepl("^T5_c[123]_", claim_id), !is.na(reported_se)) %>%
  transmute(claim_id, b = as.numeric(reported_value), se = as.numeric(reported_se), stars = coalesce(reported_stars, ""))
t5 <- t5 %>% mutate(z = abs(b / se), implied = case_when(z >= qnorm(.995) ~ "***", z >= qnorm(.975) ~ "**", z >= qnorm(.95) ~ "*", TRUE ~ ""),
                    stars = gsub("[^*]", "", stars), mismatch = stars != implied)
write_csv(t5 %>% filter(mismatch), "P12_FJ/compare/s5_checks/01_star_mismatches.csv")
print(t5 %>% filter(mismatch), n = 50)
# Predicted probabilities: anchor on the 93.4% white baseline (unknown intercept + Paarl dummy) and add published coefficients.
lg <- qlogis(.934); P <- function(x) round(100 * plogis(x), 1)
b2 <- c(Col = -0.9187, Bl = -1.814, Pan = -2.243, ColP = -0.7167, BlP = -1.215, A70 = -0.4340, PA70 = 0.6985)
b3 <- c(Col = -0.8913, Bl = -1.701, Pan = -2.576, ColP = -0.6029, BlP = -1.222, A70 = -0.4794, PA70 = 0.6768)
pp <- function(b) c(p9_b = P(lg + b["Col"]), p9_c = P(lg + b["Bl"]), p9_d = P(lg + b["Pan"]), p9_e = P(lg + b["Pan"] + b["Col"] + b["ColP"]),
  p9_f = P(lg + b["Pan"] + b["Bl"] + b["BlP"]), p9_h = P(lg + b["A70"]), p9_j = P(lg + b["Pan"] + b["A70"] + b["PA70"]) - P(lg + b["Pan"]))
out <- tibble(claim = c("TXT_p9_b","TXT_p9_c","TXT_p9_d","TXT_p9_e","TXT_p9_f","TXT_p9_h","TXT_p9_j"),
  published = c(85, 69.8, 57.7, 21, 6.2, 90.2, 6.3), from_spec2 = unname(pp(b2)), from_spec3 = unname(pp(b3)))
# Implied pandemic main effect from 57.7% and the race gaps implied by the pandemic figures
out <- bind_rows(out, tibble(claim = c("implied_Pandemic_coef", "implied_Col+ColxPan", "implied_Bl+BlxPan", "implied_Railway_total_logit_gap_p13"),
  published = round(c(qlogis(.577) - lg, qlogis(.21) - qlogis(.577), qlogis(.062) - qlogis(.577), qlogis(.095) - qlogis(.043)), 3),
  from_spec2 = c(-2.243, -0.9187 - 0.7167, -1.814 - 1.215, NA), from_spec3 = c(-2.576, -0.8913 - 0.6029, -1.701 - 1.222, 0.1443)))
print(out); write_csv(out, "P12_FJ/compare/s5_checks/01_predicted_prob_check.csv")
cat("Railway x Pandemic 0.1443 / 0.4837: z =", round(0.1443 / 0.4837, 2), "; coefficient needed for p<0.10 with that SE:", round(1.645 * 0.4837, 3), "\n")
