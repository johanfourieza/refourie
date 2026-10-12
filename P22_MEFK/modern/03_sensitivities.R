# P22_MEFK S6, step 3: admissible sensitivities 1-8 (method card v3, §5). Reported only; none sets a verdict.
# Input: modern/_scratch/shareholders_c1.rds. Output: modern/output/sensitivities.csv, cohort_foreign.csv, bootstrap_diagnostics.csv
suppressPackageStartupMessages({library(dplyr); library(readr); library(tidyr); library(here)})
root <- here::here(); if (basename(root) != "Fourie_ReplicateMe") root <- normalizePath(file.path(root, ".."))
source(file.path(root, "tools", "paths.R"))
out <- file.path(root, "P22_MEFK", "modern", "output")
sh <- readRDS(dscratch("P22_MEFK", "modern", "shareholders_c1.rds"))
UNK <- c("Information not available", "Unclassified occupation")
CLS <- c("Middle class", "Businessmen", "Farmers", "Rentiers", "Working class", "Company investors")
sh <- sh |> mutate(okv = is.finite(val) & val >= 0, v = ifelse(okv, val, 0), U = cls %in% UNK,
                   UL = is.na(region) | region == "Unassigned", loc = region %in% c("Other Africa", "North", "East", "West"))
res <- list(); put <- function(sens, quantity, est, lo = NA, hi = NA, note = "") res[[length(res) + 1]] <<-
  tibble(sensitivity = sens, quantity = quantity, estimate = est, lower = lo, upper = hi, note = note)

# identified-set helper on any data frame with cls/U/v
idset <- function(d, cl, w) { x <- if (w == "rows") rep(1, nrow(d)) else d$v
  T <- sum(x); c(L = sum(x[d$cls == cl]) / T, U = sum(x[d$cls == cl | d$U]) / T) * 100 }
pairD <- function(d, w) sapply(setdiff(CLS, "Middle class"), function(j) { m <- idset(d, "Middle class", w); k <- idset(d, j, w); c(m[1] - k[2], m[2] - k[1]) })

# ---- 1. point estimates: (a) unknowns in denominator, allocated to none; (b) unknowns excluded from denominator ----
pt <- function(d) {
  a <- c(sapply(CLS, function(k) 100 * mean(d$cls == k)), sapply(CLS, function(k) 100 * sum(d$v[d$cls == k]) / sum(d$v)),
         100 * sum(d$v[d$foreign]) / sum(d$v), 100 * mean(d$loc))
  K <- !d$U; KL <- !d$UL
  b <- c(sapply(CLS, function(k) 100 * mean(d$cls[K] == k)), sapply(CLS, function(k) 100 * sum(d$v[K & d$cls == k]) / sum(d$v[K])),
         100 * sum(d$v[KL & d$foreign]) / sum(d$v[KL]), 100 * mean(d$loc[KL]))
  nm <- c(paste0("rows: ", CLS), paste0("value: ", CLS), "value: Foreign", "rows: Local")
  setNames(c(a, b), c(paste0("1a ", nm), paste0("1b ", nm))) }
p1 <- pt(sh)

# ---- 2. company-cluster bootstrap, B = 999, seed 20261012 (ratio of totals recomputed per draw) ----
set.seed(20261012); B <- 999
cos <- split(seq_len(nrow(sh)), sh$rec); nc <- length(cos)
bt <- t(vapply(seq_len(B), function(b) pt(sh[unlist(cos[sample.int(nc, nc, replace = TRUE)], use.names = FALSE), ]), numeric(length(p1))))
ci <- apply(bt, 2, quantile, c(.025, .975), na.rm = TRUE)
for (i in seq_along(p1)) put(if (startsWith(names(p1)[i], "1a")) "1a unknowns in denominator, allocated to none" else "1b unknowns excluded from denominator",
  sub("^1[ab] ", "", names(p1)[i]), p1[i], ci[1, i], ci[2, i], "lower/upper = sensitivity 2: company-cluster bootstrap 95% percentile interval, B=999")
cv <- sh |> group_by(rec) |> summarise(n = n(), v = sum(v))
mult <- sh |> filter(key != "") |> group_by(key) |> summarise(k = n_distinct(rec))
diag <- tibble(diagnostic = c("companies", "rows per company: min", "median", "max", "largest company share of Value (%)",
                              "top-5 companies share of Value (%)", "investors (name keys) in >1 company", "share of name keys in >1 company (%)"),
               value = c(nc, min(cv$n), median(cv$n), max(cv$n), 100 * max(cv$v) / sum(cv$v), 100 * sum(sort(cv$v, TRUE)[1:5]) / sum(cv$v),
                         sum(mult$k > 1), 100 * mean(mult$k > 1)))
write_csv(diag, file.path(out, "bootstrap_diagnostics.csv"))

# ---- 3. women -> Rentiers, financiers -> Businessmen ----
s3d <- sh |> mutate(cls = case_when(cls == "Middle class" & sub %in% "women" ~ "Rentiers", cls == "Middle class" & sub %in% "financiers" ~ "Businessmen", TRUE ~ cls))
for (w in c("rows", "value")) { b <- idset(s3d, "Middle class", w); D <- pairD(s3d, w)
  put("3 women->Rentiers, financiers->Businessmen", paste0(w, ": Middle class share (identified set)"), b[1], b[1], b[2])
  put("3 women->Rentiers, financiers->Businessmen", paste0(w, ": min_j D_j (identified set)"), NA, min(D[1, ]), min(D[2, ]), paste0("binding competitor for upper bound: ", colnames(D)[which.min(D[2, ])])) }

# ---- 4. "most capital" as a majority: c_mid - 50 ----
b <- idset(sh, "Middle class", "value"); put("4 majority reading", "value: Middle class share - 50 (identified set)", NA, b[1] - 50, b[2] - 50)

# ---- 5. investor level (normalised full name; modal known class, ties -> unknown) ----
modal <- function(x) { x <- x[!is.na(x)]; if (!length(x)) return(NA_character_); t <- table(x); m <- names(t)[t == max(t)]; if (length(m) > 1) NA_character_ else m }
inv <- sh |> filter(key != "") |> group_by(key) |>
  summarise(cls = modal(cls[!U]), v = sum(v), loc = modal(ifelse(UL, NA, ifelse(foreign, "F", "L"))), .groups = "drop") |>
  mutate(U = is.na(cls), cls = coalesce(cls, "unknown"))
for (w in c("rows", "value")) { b <- idset(inv, "Middle class", w); D <- pairD(inv, w)
  put("5 investor level", paste0(if (w == "rows") "investors" else "value", ": Middle class share (identified set)"), b[1], b[1], b[2], paste0(nrow(inv), " name keys"))
  put("5 investor level", paste0(if (w == "rows") "investors" else "value", ": min_j D_j (identified set)"), NA, min(D[1, ]), min(D[2, ])) }
put("5 investor level", "value: Foreign (identified set)", 100 * sum(inv$v[inv$loc %in% "F"]) / sum(inv$v), 100 * sum(inv$v[inv$loc %in% "F"]) / sum(inv$v), 100 * sum(inv$v[inv$loc %in% "F" | is.na(inv$loc)]) / sum(inv$v))
put("5 investor level", "investors: Local (identified set)", 100 * mean(inv$loc %in% "L"), 100 * mean(inv$loc %in% "L"), 100 * mean(inv$loc %in% "L" | is.na(inv$loc)))

# ---- 6. foreign = outside the Cape Colony (Other Africa counted foreign) ----
f6 <- sh$foreign | sh$region %in% "Other Africa"; l6 <- sh$region %in% c("North", "East", "West")
put("6 foreign = outside Cape Colony", "value: Foreign (identified set)", 100 * sum(sh$v[f6]) / sum(sh$v), 100 * sum(sh$v[f6]) / sum(sh$v), 100 * sum(sh$v[f6 | sh$UL]) / sum(sh$v))
put("6 foreign = outside Cape Colony", "rows: Local (identified set)", 100 * mean(l6), 100 * mean(l6), 100 * mean(l6 | sh$UL))

# ---- 7. leave-one-company-out range for point c_mid and c_for (definition 1a) ----
loo <- sapply(names(cos), function(r) { d <- sh[sh$rec != r, ]; c(100 * sum(d$v[d$cls == "Middle class"]) / sum(d$v), 100 * sum(d$v[d$foreign]) / sum(d$v)) })
put("7 leave-one-company-out", "value: Middle class (1a)", p1["1a value: Middle class"], min(loo[1, ]), max(loo[1, ]), paste0("range over ", nc, " companies"))
put("7 leave-one-company-out", "value: Foreign (1a)", p1["1a value: Foreign"], min(loo[2, ]), max(loo[2, ]), paste0("most influential: ", names(cos)[which.max(abs(loo[2, ] - p1["1a value: Foreign"]))]))

# ---- 8. founding-cohort series of the foreign capital share (cohort composition, not investment over time) ----
coh <- sh |> filter(found_year %in% 1892:1902) |> group_by(found_year) |>
  summarise(companies = n_distinct(rec), rows = n(), value = sum(v), foreign_L = 100 * sum(v[foreign]) / sum(v), foreign_U = 100 * sum(v[foreign | UL]) / sum(v))
write_csv(coh, file.path(out, "cohort_foreign.csv"))
for (i in seq_len(nrow(coh))) put("8 founding cohort", paste0("value: Foreign, cohort ", coh$found_year[i]), coh$foreign_L[i], coh$foreign_L[i], coh$foreign_U[i], paste0(coh$companies[i], " companies, ", coh$rows[i], " rows"))

sens <- bind_rows(res) |> mutate(across(c(estimate, lower, upper), ~ signif(.x, 6)))
write_csv(sens, file.path(out, "sensitivities.csv"), na = "")
print(as.data.frame(sens |> filter(!grepl("^8|^1b", sensitivity) | grepl("Middle class$|Businessmen$|Foreign|Local", quantity)) |> select(-note)), digits = 4)
print(as.data.frame(diag)); print(as.data.frame(coh), digits = 3)
