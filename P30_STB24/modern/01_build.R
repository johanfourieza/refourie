# P30_STB24 S6 step 1: build the corrected central data (card s3) and run the card's checks 1, 2 and 4 (s4).
source("P30_STB24/modern/00_common.R")
library(readr)

cmp <- function(a, b) {                       # max abs diff, NA/NaN treated as equal, mismatched missingness = Inf
  a <- as.matrix(a); b <- as.matrix(b); na <- !is.finite(a) | !is.finite(b)
  if (any(xor(!is.finite(a), !is.finite(b)))) return(Inf)
  max(abs(a[!na] - b[!na]))
}
idx_of <- function(m, base) { b <- unlist(m[year == base, ..ASSETS]); i <- copy(m); for (v in ASSETS) set(i, j = v, value = m[[v]] / b[[v]]); i }
ren <- function(d) setnames(copy(as.data.table(d)), c("wheat_vol", "barley_vol"), c("wheat", "barley"), skip_absent = TRUE)

# Check 1: K1-K5 off reproduces the S2 run
d0 <- build(K1 = FALSE, K3 = FALSE, K4 = FALSE, K5 = FALSE)
o5 <- ren(read_csv(file.path(PAPER, "repro_original/output/fig5_mean_values.csv"), show_col_types = FALSE))
o6 <- ren(read_csv(file.path(PAPER, "repro_original/output/fig6_gini_values.csv"), show_col_types = FALSE))
m0 <- year_means(d0); g0 <- year_ginis(d0, f = function(x) ineq::Gini(x, na.rm = TRUE))
c1 <- c(means = cmp(m0[, ..ASSETS], o5[, ..ASSETS]), ginis = cmp(g0[, ..ASSETS], o6[, ..ASSETS]), years = all(m0$year == o5$year))

# Check 2: K1, K2, K3, K5 on, K4 off reproduces S5 scenario S5_all_fixes_base1795
d2 <- build(K4 = FALSE)
s5i <- ren(read_csv(file.path(PAPER, "compare/s5_checks/output/fig5_index_S5_all_fixes_base1795.csv"), show_col_types = FALSE))
s5g <- ren(read_csv(file.path(PAPER, "compare/s5_checks/output/fig6_gini_S5_all_fixes_base1795.csv"), show_col_types = FALSE))
i2 <- idx_of(year_means(d2), 1795); g2 <- year_ginis(d2, f = function(x) ineq::Gini(x, na.rm = TRUE))
c2 <- c(index = cmp(i2[, ..ASSETS], s5i[, ..ASSETS]), ginis = cmp(g2[, ..ASSETS], s5g[, ..ASSETS]))

# Central build (K1-K5 on)
d <- build()
saveRDS(d, SCR("central.rds"))
c4 <- d[owner == TRUE, .N]

checks <- data.table(check = c("1 K1-K5 off vs S2 fig5 means", "1 K1-K5 off vs S2 fig6 Ginis", "2 K4 off vs S5 all_fixes_base1795 index",
                               "2 K4 off vs S5 all_fixes_base1795 Ginis", "4 owner rows before 1830"),
                     value = c(c1[["means"]], c1[["ginis"]], c2[["index"]], c2[["ginis"]], c4),
                     target = c("< 1e-6", "< 1e-6", "< 1e-6", "< 1e-6", "55940"))
checks[, pass := c(value[1:4] < 1e-6, value[5] == 55940)]
print(checks)
fwrite(checks, file.path(OUT, "checks.csv"))

# what K4 changes: asset-years made missing (all components missing after the zero-fill)
k4 <- merge(melt(year_means(d2), id.vars = "year", value.name = "m_K4off"), melt(year_means(d), id.vars = "year", value.name = "m_central"))
fwrite(k4[is.finite(m_K4off) != is.finite(m_central)], file.path(OUT, "k4_years_set_missing.csv"))
cat("rows:", nrow(d), " census years:", uniqueN(d$year), "\n")
