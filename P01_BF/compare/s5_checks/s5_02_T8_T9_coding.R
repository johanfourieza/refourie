# P01_BF S5 check 2: Table 8 / Figure 4 / Table 9 and origin-coding scenarios.
# (a) C1: T8 col 1 classical vs robust SEs and stars (l.1667 vs l.1672).
# (b) C2/C3: split the pooled cells (Cape-born/Mozambican early out of otb_early; 1790s SE Asian/Indian out of *_mid).
# (c) C5: SE of each Figure 4 level (constant + interaction), robust.
# (d) T9: search for the model behind Table 9 (no code survives), incl. headline T9_r5.
# (e) Origin-coding fix (l.1574-1579): "Kust"/"Cust" (Coromandel Coast, India) and "Westcoast" are coded Cape-born;
#     "Coehin" (Cochin) is coded Chinese. Re-estimate T6 headlines and T9_r5 under corrected codings.
# Inputs : ./P01_BF/original/Baten Fourie/data.dta
# Output : compare/s5_checks/s5_02_*.csv
suppressPackageStartupMessages({library(tidyverse); library(haven); library(sandwich); library(here)})
proj <- here::here(); source(file.path(proj, "tools", "paths.R"))
out  <- file.path(proj, "P01_BF", "compare", "s5_checks")
o <- read_dta(dpath("P01_BF", "original", "Baten Fourie", "data.dta")) |> zap_labels()
d <- o |> filter(age > 22, age < 83, !is.na(cyear)) |> mutate(y = 125 * exactage)   # l.1667 sample
stopifnot(nrow(d) == 1802)
cells <- c("eur_early","eur_mid","eur_post","id_early","id_mid","in_early","in_mid","ko_early","ko_mid","ko_post",
           "mz_mid","mz_post","otb_early","otb_mid","otb_post","za_mid","za_post")
stars <- function(p) case_when(p < .01 ~ "***", p < .05 ~ "**", p < .10 ~ "*", TRUE ~ "")

# (a) C1 -------------------------------------------------------------------------------
m8 <- lm(reformulate(c("female2", "age23", cells), "y"), data = d)
Vc <- vcov(m8); Vr <- vcovHC(m8, type = "HC1")
t8 <- tibble(term = names(coef(m8)), coef = coef(m8), se_conv = sqrt(diag(Vc)), se_rob = sqrt(diag(Vr))) |>
  mutate(p_conv = 2 * pt(-abs(coef / se_conv), m8$df.residual), p_rob = 2 * pt(-abs(coef / se_rob), m8$df.residual),
         st_conv = stars(p_conv), st_rob = stars(p_rob), se_rob_unscaled = se_rob / 125)
write_csv(t8, file.path(out, "s5_02_T8_conv_vs_robust.csv"))
cat("C1: star sets differ conv vs robust in", sum(t8$st_conv != t8$st_rob), "of", nrow(t8), "rows:\n")
print(t8 |> filter(st_conv != st_rob) |> select(term, coef, se_conv, se_rob, st_conv, st_rob))

# (c) C5: Figure 4 levels with robust SEs ---------------------------------------------------
lev <- map_dfr(c("(Intercept)", cells), function(t) {
  L <- setNames(rep(0, length(coef(m8))), names(coef(m8))); L["(Intercept)"] <- 1; if (t != "(Intercept)") L[t] <- 1
  tibble(cell = ifelse(t == "(Intercept)", "cn_all (constant)", t), level = sum(L * coef(m8)),
         se_rob = sqrt(drop(t(L) %*% Vr %*% L)))
})
write_csv(lev, file.path(out, "s5_02_F4_levels_se.csv"))
cat("\nC5: China bar = constant = pooled Chinese, n by cohort:\n"); print(table(d$bcoh[d$bco == "cn"]))
print(lev |> mutate(across(where(is.numeric), ~ round(., 2))), n = 20)

# (b) C2/C3: unpool -------------------------------------------------------------------------
d2 <- d |> mutate(otb_early = as.integer(bco == "oth_bl" & bcoh == 1), za_early = as.integer(bco == "za" & bcoh == 1),
                  mz_early = as.integer(bco == "mz" & bcoh == 1),
                  id_mid = as.integer(bco == "id" & bcoh == 2), id_post = as.integer(bco == "id" & bcoh == 3),
                  in_mid = as.integer(bco == "in" & bcoh == 2), in_post = as.integer(bco == "in" & bcoh == 3))
m8u <- lm(reformulate(c("female2", "age23", cells, "za_early", "mz_early", "id_post", "in_post"), "y"), data = d2)
unp <- tibble(term = c("otb_early", "id_mid", "in_mid", "za_early", "mz_early", "id_post", "in_post"),
              coef_pooled = coef(m8)[c("otb_early", "id_mid", "in_mid", NA, NA, NA, NA)],
              coef_unpooled = coef(m8u)[term], n_unpooled = map_int(term, ~ sum(d2[[.x]])))
write_csv(unp, file.path(out, "s5_02_T8_unpooled.csv"))
cat("\nC2/C3 unpooled cells:\n"); print(unp)

# (d) Table 9 model search -----------------------------------------------------------------
pub9 <- tribble(~id, ~g, ~c0, ~c1, ~pub, ~pub_p, ~pub_n,
  "T9_r1","in",1,2,-12.5,.286,71, "T9_r2","id",1,2,-18.3,.011,127, "T9_r3","eur",1,2,0.5,.925,337,
  "T9_r4","eur",2,3,1.4,.872,225, "T9_r5","ko",1,2,-43.9,.000,217, "T9_r6","ko",2,3,26.5,.000,340,
  "T9_r7","mz",2,3,35.5,.005,92, "T9_r8","za",2,3,9.5,.363,137, "T9_r9","otb",1,2,-14.8,.005,520,
  "T9_r10","otb",2,3,10.8,.172,235)
cellvar <- function(g, c) paste0(g, "_", c("early", "mid", "post")[c])
t9 <- pmap_dfr(pub9, function(id, g, c0, c1, pub, pub_p, pub_n) {
  dd <- d |> filter(.data[[cellvar(g, c0)]] == 1 | .data[[cellvar(g, c1)]] == 1) |>
    mutate(later = .data[[cellvar(g, c1)]])
  specs <- list(raw = "later", ctrl = c("later", "female2", "age23"), ctrl_bdec = c("later", "female2", "age23", "factor(bdec)"))
  r <- imap_dfr(specs, function(rhs, nm) {
    m <- lm(reformulate(rhs, "y"), data = dd)
    p <- if (length(unique(dd$bdec)) > 1 || nm != "ctrl_bdec") coef(summary(m))["later", 4] else NA
    tibble(spec = paste0("OLS_", nm), est = coef(m)["later"], p = p)
  })
  ml <- glm(exactage ~ later + female2 + age23, family = binomial, data = dd)
  X <- model.matrix(ml); xb <- colMeans(X); x1 <- xb; x0 <- xb; x1["later"] <- 1; x0["later"] <- 0
  r <- bind_rows(r, tibble(spec = "logit_MEM_ctrl", est = 125 * (plogis(sum(x1 * coef(ml))) - plogis(sum(x0 * coef(ml)))),
                           p = coef(summary(ml))["later", 4]),
                 tibble(spec = "T8_diff", est = coef(m8)[cellvar(g, c1)] - coef(m8)[cellvar(g, c0)], p = NA))
  r |> mutate(id = id, pub = pub, pub_p = pub_p, n = nrow(dd), pub_n = pub_n)
})
write_csv(t9, file.path(out, "s5_02_T9_model_search.csv"))
cat("\nT9 model search: mean |est - pub| by spec\n")
print(t9 |> group_by(spec) |> summarise(mad = mean(abs(est - pub)), max = max(abs(est - pub)), n_ok = all(n == pub_n)))
print(t9 |> filter(id == "T9_r5") |> mutate(across(c(est, p), ~ round(., 3))))

# (e) Origin-coding fix ---------------------------------------------------------------------
cat("\nOrigins coded Cape-born (bco == za) in the sample:\n"); print(count(d |> filter(bco == "za"), origin, origindum, sort = TRUE), n = 40)
lv <- c("za", "cn", "eur", "id", "in", "ko", "mz", "oth_bl")
mem_g <- function(dd) {
  m <- glm(exactage ~ female2 + age23 + g + factor(bdec), family = binomial,
           data = dd |> filter(bdec >= 1650) |> mutate(g = factor(g, levels = lv)))
  X <- model.matrix(m); xb <- colMeans(X); b <- coef(m)
  map_dfr(c("geur", "gid", "gin", "gmz"), function(t) { x1 <- xb; x0 <- xb; x1[t] <- 1; x0[t] <- 0
    tibble(term = sub("^g", "", t), me125 = 125 * (plogis(sum(x1 * b)) - plogis(sum(x0 * b)))) })
}
fixes <- list(
  orig = d |> mutate(g = bco),
  fix_kust = d |> mutate(g = if_else(origin %in% c("Kust", "Cust"), "in", bco)),
  fix_kust_westcoast = d |> mutate(g = case_when(origin %in% c("Kust", "Cust") ~ "in", origin == "Westcoast" ~ "oth_bl", TRUE ~ bco)),
  fix_kust_westcoast_cochin = d |> mutate(g = case_when(origin %in% c("Kust", "Cust", "Coehin") ~ "in", origin == "Westcoast" ~ "oth_bl", TRUE ~ bco)))
fx <- imap_dfr(fixes, ~ mem_g(.x) |> mutate(scenario = .y))
write_csv(fx, file.path(out, "s5_02_origin_fix_T6.csv"))
print(fx |> pivot_wider(names_from = term, values_from = me125))
