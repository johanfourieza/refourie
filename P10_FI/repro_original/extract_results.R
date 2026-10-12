# Extract claim-level values from the S2 snapshots of the original script (run_original.R).
#   Rscript P10_FI/repro_original/extract_results.R            -> results_original.csv        (main run, CT 1 March 2019.xlsx)
#   Rscript P10_FI/repro_original/extract_results.R v2018      -> results_original_v2018.csv  (diagnostic, Anglican Cape Town.xlsx)
# Every value is read off objects the original code creates (models 5-8 = 'Final regressions',
# 'descriptives', 'literacy', 'years', with(angreg, table(...)), with(white, table(inter, year))).
# No arithmetic beyond what the paper itself applies (percent of total, ratio to 0.9%) is added.
# Output is aggregate only (rights class personal).
suppressPackageStartupMessages({ library(data.table); library(readr); library(dplyr) })
tag <- if (length(commandArgs(TRUE))) commandArgs(TRUE)[1] else "main"
source("tools/paths.R")
scr <- dpath("P10_FI", "repro_original", "_scratch", tag)
s3 <- readRDS(file.path(scr, "snap_table3.rds")); s24 <- readRDS(file.path(scr, "snap_tables24.rds"))
claims <- read_csv("P10_FI/claims/claims.csv", show_col_types = FALSE)
res <- tibble(claim_id = character(), value = numeric(), se = numeric(), n = numeric(), status_override = character(), note = character())
add <- function(id, value = NA_real_, se = NA_real_, n = NA_real_, ovr = NA_character_, note = "") {
  stopifnot(length(id) == 1, length(value) == 1)
  value <- as.numeric(value); se <- as.numeric(se); n <- as.numeric(n)
  stopifnot(id %in% claims$claim_id)
  res <<- add_row(res, claim_id = id, value = value, se = se, n = n, status_override = ovr, note = note)
}

# ---- Table 1: husband race x wife race, angreg (1911-1964 filter in script) ----
a <- s3$angreg
tab <- table(factor(a$mrace, c("Coloured", "White", "Black")), factor(a$frace, c("Coloured", "White", "Black")))
tab <- addmargins(tab); tot <- tab[4, 4]
k <- c(c = "Coloured", w = "White", b = "Black", t = "Sum")
for (m in c("c", "w", "b", "t")) for (f in c("c", "w", "b", "t")) {
  add(sprintf("t1_cnt_%s%s", m, f), tab[k[m], k[f]], n = tot, note = "with(angreg, table(mrace, frace)) [script l.8212-8214 tabulations]")
  if (m != "t") add(sprintf("t1_shr_%s%s", m, f), 100 * tab[k[m], k[f]] / tot, n = tot, note = "cell / grand total x 100")
}

# ---- Table 2: descriptives (script object 'descriptives', by mrace) ----
d <- as.data.frame(s24$descriptives); d$mrace <- as.character(d$mrace)
nr <- table(a$mrace, useNA = "ifany")
cols <- c(interracial = "interdum", maleage = "mage", femaleage = "fage", maleliteracy = "mlit",
          femaleliteracy = "flit", sexratio = "sex", segregation = "inequality", literacydifference = "dlit")
for (r in c(co = "Coloured", wh = "White", bl = "Black", na = NA)) {
  rr <- if (is.na(r)) which(is.na(d$mrace)) else which(d$mrace == r)
  ab <- if (is.na(r)) "na" else c(Coloured = "co", White = "wh", Black = "bl")[r]
  for (cn in names(cols)) {
    id <- sprintf("T2_%s_%s", ab, cn)
    if (id %in% claims$claim_id) add(id, d[rr, cols[cn]], n = if (is.na(r)) nr[is.na(names(nr))] else nr[r],
                                     note = "descriptives (group_by(mrace) means, na.rm) incl. NA-race group")
  }
}

# ---- Table 3: Final regressions model5 (logit), model6-8 (OLS); default (iid / MLE) SEs as stargazer prints ----
mods <- list(c1 = s3$model5, c2 = s3$model6, c3 = s3$model7, c4 = s3$model8)
term <- c(whitemale = "mraceWhite", blackmale = "mraceBlack", whitefemale = "fraceWhite", blackfemale = "fraceBlack",
          maleage = "mage", femaleage = "fage", act = "act", sexratio = "sex", segregation = "inequality",
          literacygap = "dlit", widower = "mcon1", maledivorcee = "mcon2", widow = "fcon1", femaledivorcee = "fcon2",
          foreignbornmale = "mcountrydum", foreignbornfemale = "fcountrydum",
          malemanager = "I(mhisco == 1)TRUE", malesales = "I(mhisco == 2)TRUE",
          femalemanager = "I(fhisco == 1)TRUE", femalesales = "I(fhisco == 2)TRUE", year = "year", constant = "(Intercept)")
for (cc in names(mods)) {
  m <- mods[[cc]]; ct <- summary(m)$coefficients; N <- nobs(m)
  for (v in names(term)) {
    id <- sprintf("T3_%s_%s", v, cc)
    if (id %in% claims$claim_id) add(id, ct[term[v], 1], se = ct[term[v], 2], n = N,
                                     note = sprintf("%s %s; SE = default %s", c(c1 = "model5", c2 = "model6", c3 = "model7", c4 = "model8")[cc], term[v], ifelse(inherits(m, "glm") && !identical(class(m), "lm"), "MLE (glm)", "iid OLS (lm)")))
  }
  add(sprintf("T3_obs_%s", cc), N, n = N, note = "nobs()")
  if (cc != "c1") {
    add(sprintf("T3_r2_%s", cc), summary(m)$r.squared, n = N)
    add(sprintf("T3_adjr2_%s", cc), summary(m)$adj.r.squared, n = N)
  }
}
add("T3_aic_c1", AIC(mods$c1), n = nobs(mods$c1), note = "AIC(model5)")

# ---- Table 4: literacy by mrace x interdum (script object 'literacy') ----
l <- as.data.frame(s24$literacy); l$mrace <- as.character(l$mrace)
for (r in c("Coloured", "White", "Black")) for (tn in c("same", "inter")) {
  ty <- c(same = 0, inter = 1)[tn]
  ab <- c(Coloured = "co", White = "wh", Black = "bl")[r]; rw <- which(l$mrace == r & l$interdum == ty)
  add(sprintf("T4_%s_%s_male", ab, tn), l$mlit[rw], note = "literacy: group_by(mrace, interdum) mean mlit")
  add(sprintf("T4_%s_%s_female", ab, tn), l$flit[rw], note = "literacy: group_by(mrace, interdum) mean flit")
}

# ---- Figure 3: 'years' share (computed on full ang before the 1909-1963 filter) ----
y <- as.data.frame(s24$years)
for (yr in 1911:1963) { id <- sprintf("F3_%d", yr); if (id %in% claims$claim_id) add(id, y$share[y$year == yr], note = "years$share (interdum by year x 100)") }

# ---- Text claims ----
add("txt_p629_n23000", tot, note = "T1 grand total ('more than 23,000')")
add("txt_p634_n_used", tot, note = "T1 grand total")
sh <- function(yrs) { z <- y[y$year %in% yrs, ]; 100 * sum(z$m) / (sum(z$m) + sum(z$s)) }
add("txt_p629_share_preWWI", ovr = "ambiguous", note = sprintf("period undefined; code: 1911=%.2f, max 1911-13=%.2f, pooled 1911-13=%.2f", y$share[y$year == 1911], max(y$share[y$year %in% 1911:1913]), sh(1911:1913)))
add("txt_p629_share_1930s", ovr = "ambiguous", note = sprintf("bound ('less than'); code: pooled 1930-39=%.2f, max annual=%.2f", sh(1930:1939), max(y$share[y$year %in% 1930:1939])))
add("txt_p630_share_post1949", ovr = "ambiguous", note = sprintf("bound ('less than'); code: pooled 1950-63=%.2f, max annual 1950-63=%.2f", sh(1950:1963), max(y$share[y$year %in% 1950:1963])))
for (x in c("txt_p634_n_transcribed", "txt_p638_racecats", "txt_p638_occ_male", "txt_p638_occ_female", "txt_p640_occ_male", "txt_p641_occ_female", "txt_p639_reclass"))
  add(x, ovr = "unavailable", note = "not computed by the original script")
for (x in c("txt_p635_angl_white", "txt_p635_angl_col", "txt_p635_afr_white", "txt_p635_afr_col", "txt_p635_jewish",
            "txt_p637_vs_inter1925", "txt_p637_vs_ww1925", "txt_p637_vs_sh1925", "txt_p637_vs_1935", "txt_p638_vs_1945"))
  add(x, ovr = "unavailable", note = "external source (1936 census / von Scholtz 1984); not in code")
add("txt_p636_colhusb_n", tab["Coloured", "Sum"]); add("txt_p636_colhusb_sh", 100 * tab["Coloured", "Sum"] / tot)
add("txt_p636_whhusb_n", tab["White", "Sum"]);    add("txt_p636_whhusb_sh", 100 * tab["White", "Sum"] / tot)
add("txt_p636_blhusb_n", tab["Black", "Sum"]);    add("txt_p636_blhusb_sh", 100 * tab["Black", "Sum"] / tot)
add("txt_p637_wc", tab["White", "Coloured"]); add("txt_p637_bc", tab["Black", "Coloured"], note = "code gives the T1 cell; text prints 158")
add("txt_p637_cw", tab["Coloured", "White"]); add("txt_p637_cb", tab["Coloured", "Black"])
add("txt_p637_wb", tab["White", "Black"]);    add("txt_p637_bw", tab["Black", "White"])
w <- a[mrace == "White"]; wt <- with(w, table(inter, year))           # script l.8217-8218
wsh <- function(yr) 100 * wt["Mixed", as.character(yr)] / sum(wt[, as.character(yr)])
add("txt_p637_1925_whinter", wt["Mixed", "1925"], note = "with(white, table(inter, year))")
add("txt_p637_1925_ww", tab_ww <- sum(a$year == 1925 & a$mrace == "White" & a$frace == "White", na.rm = TRUE), note = "ww marriages 1925 in angreg")
add("txt_p637_1925_inter", y$m[y$year == 1925], note = "years$m 1925")
add("txt_p637_1925_share", wsh(1925), note = "white-husband interracial / all white-husband marriages, 1925")
add("txt_p637_1925_ratio", wsh(1925) / 0.9, note = "1925 share / 0.9 (von Scholtz share, as in text)")
add("txt_fn15_1925_all", y$share[y$year == 1925], note = "years$share 1925")
add("txt_p638_1935", wsh(1935), note = "white-husband measure as for 1925"); add("txt_p638_1945", wsh(1945), note = "white-husband measure as for 1925")
add("txt_p639_black_inter", 100 * d$interdum[which(d$mrace == "Black")], note = "descriptives interdum, Black husbands x 100")
add("txt_p639_col_inter", 100 * d$interdum[which(d$mrace == "Coloured")], note = "descriptives interdum, Coloured husbands x 100 (text: 'less than 1%')")
add("txt_p645_bl_same_lit", 100 * l$mlit[which(l$mrace == "Black" & l$interdum == 0)], note = "literacy mlit x 100")
add("txt_p645_bl_inter_lit", 100 * l$mlit[which(l$mrace == "Black" & l$interdum == 1)], note = "literacy mlit x 100")
add("txt_p645_colw_colm_lit", 100 * l$flit[which(l$mrace == "Coloured" & l$interdum == 0)], note = "literacy flit x 100")
add("txt_p645_colw_whm_lit", 100 * l$flit[which(l$mrace == "White" & l$interdum == 1)], note = "literacy flit x 100")
add("txt_p646_n_occ", nobs(mods$c4), note = "nobs(model8)")

missing <- setdiff(claims$claim_id, res$claim_id)
if (length(missing)) { cat("Claims without a value:", missing, "\n"); for (x in missing) add(x, ovr = "not-attempted", note = "no mapping") }
res <- res |> mutate(source = "original", run = tag) |> select(claim_id, source, value, se, n, status_override, note, run)
out <- file.path("P10_FI", "repro_original", if (tag == "main") "results_original.csv" else paste0("results_original_", tag, ".csv"))
write_csv(res, out, na = ""); cat("Wrote", out, nrow(res), "rows\n")
