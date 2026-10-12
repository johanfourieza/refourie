# S5 check 6: Table 1 internal consistency (stars vs r/SE) and pair-B agreement pattern across all 80 cells
suppressMessages(library(dplyr))
cl <- read.csv("P03_BoF17/claims/claims.csv") |> filter(grepl("^T1_", claim_id))
rb <- read.csv("P03_BoF17/repro_r/output/table1_recreated.csv")
d <- cl |> select(claim_id, pub = reported_value, pub_se = reported_se, stars = reported_stars) |> left_join(rb, by = "claim_id") |>
  mutate(stars = ifelse(is.na(stars), "", stars), z = pub/pub_se, star_implied = case_when(abs(z) >= 1.96 ~ "**", abs(z) >= 1.645 ~ "*", TRUE ~ ""),
         n_implied = round(1/pub_se^2 + 2), rb_sig = abs(r/se_conv) >= 1.645, pub_sig = stars != "")
cat("Star mismatches (published star vs published r/SE):\n"); print(d |> filter(stars != star_implied) |> select(claim_id, town, product, pub, pub_se, z, stars, star_implied), digits = 3)
cat("\ncor(pub, rebuild) =", round(cor(d$pub, d$r, use = "complete"), 3), "; mean |diff| =", round(mean(abs(d$pub - d$r), na.rm = TRUE), 3),
    "; same sign =", sum(sign(d$pub) == sign(d$r), na.rm = TRUE), "/", sum(!is.na(d$r)), "\n")
cat("10% significance agreement:", sum(d$rb_sig == d$pub_sig, na.rm = TRUE), "/ 80; pub sig =", sum(d$pub_sig), "; rebuild sig =", sum(d$rb_sig, na.rm = TRUE), "\n")
cat("implied n from published SE: median", median(d$n_implied), "range", range(d$n_implied), "; rebuild n median", median(d$n), "\n")
cat("cor(pub_se, 1/sqrt(rebuild n)) =", round(cor(d$pub_se, 1/sqrt(d$n)), 3), "\n")
print(d |> group_by(product) |> summarise(cor = cor(pub, r), mad = mean(abs(pub - r)), pub_sig = sum(pub_sig), rb_sig = sum(rb_sig)), digits = 3)
