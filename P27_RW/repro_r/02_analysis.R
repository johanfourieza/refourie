# 02_analysis.R -- recreate T3, T4, T5, T6-T8 (Cape cells), selected text/Fig 5 numbers
suppressMessages(library(dplyr))
source("tools/paths.R")
set.seed(27)
scr <- dscratch("P27_RW", "repro_r")
d <- readRDS(file.path(scr, "clean.rds")); inv <- d$inv; opg <- d$opg
cl <- read.csv("P27_RW/claims/claims.csv", stringsAsFactors = FALSE)
res <- data.frame(claim_id = cl$claim_id, source = "r", value = NA_real_, se = NA_real_, n = NA_real_,
                  status_override = "unavailable", stringsAsFactors = FALSE)
put <- function(id, v, se = NA, n = NA) { i <- match(id, res$claim_id)
  if (!is.na(i) && length(v) == 1 && is.finite(v)) { res$value[i] <<- v; res$se[i] <<- se; res$n[i] <<- n; res$status_override[i] <<- "" } }
q2 <- function(x, p) as.numeric(quantile(x, p, type = 2, names = FALSE))
stat1 <- function(x, s) {
  if (s == "n") return(length(x)); if (s == "sum") return(sum(x)); if (s == "mean") return(mean(x))
  if (s == "sd") return(sd(x)); if (s == "min") return(min(x)); if (s == "max") return(max(x))
  if (s %in% c("med", "p50")) return(q2(x, .5))
  if (grepl("^p[0-9]+$", s)) return(q2(x, as.numeric(sub("p", "", s)) / 100))
  if (s == "nonzero") return(sum(x != 0))
  if (grepl("zero|pct0|0s", s)) return(100 * mean(x == 0))
  NA_real_ }
fill <- function(id, x, s) { v <- stat1(x, s); put(id, v, se = if (s == "mean") sd(x) / sqrt(length(x)) else NA, n = length(x)) }

# ---- Table 3 (all 2,577 inventories)
items <- c("slaves","cattle","horses","sheep","ploughs","corn_sieves","fishing_boats","buckets","spades","guns","brandy_stills","wagons","anvils","bench_vices","balances","fire_tongs","ovens","bedsteads","chairs","trousers","irons","books","timepieces","snuff_boxes","paintings","mirrors","bird_cages","gold_rings")
for (id in grep("^T3_", res$claim_id, value = TRUE)) for (it in items) {
  for (nm in unique(c(it, gsub("_", "", it)))) { pre <- paste0("T3_", nm, "_")
    if (startsWith(id, pre)) fill(id, inv[[it]], sub(pre, "", id, fixed = TRUE)) } }

# ---- Table 4 (opgaafrolle 1700-73 vs inventories; zeros included / excluded)
for (id in grep("^T4_", res$claim_id, value = TRUE)) {
  m <- regmatches(id, regexec("^T4_(incl|excl)_(opg|inv)_([a-z]+)_(.+)$", id))[[1]]
  if (length(m) == 0) next
  x <- if (m[3] == "opg") opg[[m[4]]] else inv[[m[4]]]
  if (m[2] == "excl") x <- x[x > 0]
  fill(id, x, m[5]) }

# ---- Table 5 (wealth of the 28 items at median MOOC 10 prices; pre-1801 = drop decade row 1806)
w <- inv %>% filter(decade != 1806)
for (id in grep("^T5_", res$claim_id, value = TRUE)) {
  m <- regmatches(id, regexec("^T5_([0-9]+|total)_(.+)$", id))[[1]]
  if (length(m) == 0) next
  x <- if (m[2] == "total") w$wealth else w$wealth[w$decade == as.integer(m[2])]
  if (length(x)) fill(id, x, m[3]) }

# ---- Tables 6-8: Cape ownership shares by slave class and period
decode <- function(tok) { # tokens after 'cape_colony_' : [cK_]a[_b]
  cls <- NA; if (grepl("^c[0-9]", tok)) { cls <- as.integer(substr(tok, 2, 2)); tok <- sub("^c[0-9]_", "", tok) }
  p <- suppressWarnings(as.integer(strsplit(tok, "_")[[1]])); if (anyNA(p) || length(p) > 2) return(NULL)
  if (length(p) == 1) { lo <- p - 5; hi <- p + 4 } else { lo <- p[1]
    hi <- if (p[2] >= 1000) p[2] else if (p[2] < 10) p[1] - p[1] %% 10 + p[2] else floor(p[1] / 100) * 100 + p[2] }
  list(cls = cls, lo = lo, hi = hi) }
tab_item <- c(T6 = "books", T7 = "timepieces", T8 = "paintings")
for (id in grep("^T[678]_cape_colony_", res$claim_id, value = TRUE)) {
  t <- substr(id, 1, 2); dd <- decode(sub("^T[678]_cape_colony_", "", id)); if (is.null(dd)) next
  s <- inv %>% filter(date >= dd$lo, date <= dd$hi); if (!is.na(dd$cls)) s <- s %>% filter(group == dd$cls)
  if (nrow(s) > 0) { p <- mean(s[[tab_item[[t]]]] > 0); put(id, 100 * p, se = 100 * sqrt(p * (1 - p) / nrow(s)), n = nrow(s)) } }

# ---- Figure 5 / text
ann <- inv %>% filter(date >= 1700, date <= 1795) %>% group_by(date) %>% summarise(m = mean(wealth), .groups = "drop")
tr <- lm(m ~ date, ann); put("F5_trend_1700", predict(tr, data.frame(date = 1700)), n = nrow(ann)); put("F5_trend_1795", predict(tr, data.frame(date = 1795)), n = nrow(ann))
ma <- stats::filter(ann$m, rep(1 / 5, 5), sides = 2); for (y in c(1715, 1740, 1765, 1790)) put(paste0("F5_ma_", y), ma[ann$date == y], n = 5)
put("text_n_inv", nrow(inv)); put("text_n_inv_pre1801", nrow(w))
put("text_fishing_boats_pct", 100 * mean(inv$fishing_boats > 0)); put("text_bedsteads_mean", mean(inv$bedsteads)); put("text_chairs_mean", mean(inv$chairs))
put("text_opg_slaves_mean", mean(opg$slaves)); put("text_opg_zero_slaves", 100 * mean(opg$slaves == 0)); put("text_inv_zero_slaves", 100 * mean(inv$slaves == 0))
put("text_nz_slave_mean_opg", mean(opg$slaves[opg$slaves > 0])); put("text_nz_slave_mean_inv", mean(inv$slaves[inv$slaves > 0]))
put("text_fig5_early_level", mean(inv$wealth[inv$decade <= 1720]), n = sum(inv$decade <= 1720))

write.csv(res, "P27_RW/repro_r/results_r.csv", row.names = FALSE, na = "")
cat("filled", sum(res$status_override == ""), "of", nrow(res), "\n")
print(table(substr(res$claim_id, 1, 2), res$status_override == ""))
