# P19_GF S6: shared data loading, mappings and the bounds machinery (method card v3, §3-§4, §8).
suppressPackageStartupMessages({library(readxl); library(dplyr); library(tidyr); library(readr)})
ROOT <- "."
source(file.path(ROOT, "tools/paths.R"))
MOD <- file.path(ROOT, "P19_GF/modern"); OUT <- file.path(MOD, "output")
dir.create(OUT, showWarnings = FALSE)
set.seed(19)
pth <- dpath("P19_GF", "original", "colonial govt fiscal", "Abel Gwaindepi CC fiscal records.xlsx")
pth2 <- dpath("P19_GF", "original", "colonial govt fiscal", "colonialfiscal 18271909.xlsx")

# Expenditure sheet, column cleaning of repro_r/01_clean.R (unchanged)
e <- suppressMessages(read_excel(pth, sheet = "Expenditure", .name_repair = "minimal"))
names(e) <- make.unique(trimws(gsub("[[:space:]]+", " ", names(e))))
e <- e |> select(-starts_with("YEAR."), year = YEAR) |> mutate(across(everything(), as.numeric))

# Table 1 mapping of repro_r/01_clean.R, unchanged (card §3, §6)
map <- list(
  hr   = c("Pensions","EducationNatives","Education Non- Natives","District Surgeons","Public Health",
           "Public Worship","Eastern Cape hospital and lepers","Somerset , old and new Hospital"),
  adm  = c("Colonial Secretary","The Governor","Crown Forests","Joint parliamentary expenses",
           "Transkeian territories","Rents, rates, insurance, gas , electric light","Headman & Chiefs Allowances"),
  mil  = c("Cape Town & frontier Mounted riflemen","Imperial Military Expr","Defence and Colonial Military allowance"),
  law  = c("Divisional Courts","Registrar of Deeds","High Sheriff","Superior Courts","Police and Gaol",
           "Convicts and Prisons","Robben Island"),
  debt = c("National Debt Servicing"),
  rail = c("Total Railways"),
  pwo  = c("Roads & Bridges","Works & Buildings","Conveyance of mails","Telegraph","Post Office",
           "Ports and Harbours","Customs","Mines","Surveyor General","Commissioner for public works"))
A2 <- c("Total Railways","Roads & Bridges","Works & Buildings","Ports and Harbours","Telegraph")  # Fig A2 legend
PWT1 <- c(map$rail, map$pwo)
GE <- unlist(map[c("hr","adm","mil","law","debt","rail","pwo")], use.names = FALSE)

# Claim specifications: numerator columns, denominator-only columns, optional fixed denominator column
spec <- function(num, den_only, den_fixed = NULL) list(num = num, den_only = den_only, den_fixed = den_fixed)
H1 <- spec(map$rail, setdiff(A2, map$rail))
H2 <- spec(c(PWT1, map$debt), setdiff(GE, c(PWT1, map$debt)))
W1 <- 1880:1909; W2 <- 1870:1909

# Caps (card §4): sheet-wide column max; §5A-2 doubles it; §5A-3 local max over |y - t| <= 5
# (the column is unknown at t, so this is the max over the ten surrounding years).
Mc <- sapply(e[-1], function(v) if (all(is.na(v))) NA_real_ else max(v, na.rm = TRUE))
cap_global <- function(col, t) Mc[[col]]
cap_double <- function(col, t) 2 * Mc[[col]]
cap_local  <- function(col, t) { v <- e[[col]][abs(e$year - t) <= 5]; if (all(is.na(v))) NA_real_ else max(v, na.rm = TRUE) }

# Annual shares and bounds for one claim over a window (card §4)
bounds <- function(sp, W, cap = cap_global, data = e) {
  rows <- lapply(W, function(t) {
    r <- data[data$year == t, , drop = FALSE]
    if (nrow(r) == 0) return(tibble(year = t, N_k = NA, D_k = NA, U_N = NA, U_O = NA, n_unknown = NA,
                                    unknown_cols = "no row", s0 = NA, s_lo = NA, s_hi = NA, undefined = TRUE))
    g <- function(cols) sapply(cols, function(c) r[[c]][1])
    vn <- g(sp$num); vo <- g(sp$den_only)
    un <- names(vn)[is.na(vn)]; uo <- names(vo)[is.na(vo)]
    capv <- function(cols) { if (!length(cols)) return(0); k <- sapply(cols, cap, t = t); if (any(!is.finite(k))) NA_real_ else sum(k) }
    N_k <- sum(vn, na.rm = TRUE); U_N <- capv(un)
    if (is.null(sp$den_fixed)) {
      D_k <- N_k + sum(vo, na.rm = TRUE); U_O <- capv(uo)
      dlo <- D_k + U_O; dhi <- D_k + U_N
      s_lo <- 100 * N_k / dlo; s_hi <- 100 * (N_k + U_N) / dhi
    } else {                        # reported total as denominator: unknowns move the numerator only
      D_k <- r[[sp$den_fixed]][1]; U_O <- 0; dlo <- dhi <- D_k
      s_lo <- 100 * N_k / D_k; s_hi <- 100 * (N_k + U_N) / D_k
    }
    undef <- !is.finite(D_k) || is.na(U_N) || is.na(U_O) || !is.finite(dlo) || !is.finite(dhi) || dlo <= 0 || dhi <= 0
    tibble(year = t, N_k = N_k, D_k = D_k, U_N = U_N, U_O = U_O, n_unknown = length(un) + length(uo),
           unknown_cols = paste(c(un, uo), collapse = "; "), s0 = 100 * N_k / D_k,
           s_lo = ifelse(undef, NA, s_lo), s_hi = ifelse(undef, NA, s_hi), undefined = undef)
  })
  bind_rows(rows) |> mutate(state = case_when(undefined ~ "indeterminate", s_lo > 70 ~ "above",
                                              s_hi <= 70 ~ "counterexample", TRUE ~ "indeterminate"),
                            dist_lo = s_lo - 70, dist_hi = s_hi - 70, dist_s0 = s0 - 70)
}
# Point evaluation (zero fill or complete years): state from s0 only
point_states <- function(b) mutate(b, state = case_when(!is.finite(s0) ~ "indeterminate", s0 > 70 ~ "above", TRUE ~ "counterexample"))

# §8 verdict rules, rows 1-4 (row 0 is handled by the stopifnot checks)
rule <- function(st) {
  A <- sum(st == "above"); C <- sum(st == "counterexample"); I <- sum(st == "indeterminate"); n <- length(st)
  stopifnot(A + C + I == n)
  v <- if (C >= 1) c("overturned", 1) else if (I == 0) c("confirmed", 2) else if (I == n) c("not-testable", 3) else c("qualified", 4)
  list(A = A, C = C, I = I, n = n, verdict = v[1], row = as.integer(v[2]))
}
yrs <- function(b, s) paste(b$year[b$state == s], collapse = " ")
summ <- function(b, id, claim, desc, change) {
  if (nrow(b) == 0) return(tibble(id = id, claim = claim, description = desc, estimand_change = change, n_years = 0L,
    A = 0L, C = 0L, I = 0L, as_if_verdict = "not-testable", as_if_rule = 3L, votes = "no"))   # no year left to evaluate
  rr <- rule(b$state)
  tibble(id = id, claim = claim, description = desc, estimand_change = change, n_years = rr$n, A = rr$A, C = rr$C, I = rr$I,
         as_if_verdict = rr$verdict, as_if_rule = rr$row, f_s0_gt70 = mean(b$s0 > 70, na.rm = TRUE),
         mean_s0 = mean(b$s0, na.rm = TRUE), min_s0 = min(b$s0, na.rm = TRUE), year_min_s0 = b$year[which.min(b$s0)],
         max_s0 = max(b$s0, na.rm = TRUE), min_s_lo = suppressWarnings(min(b$s_lo, na.rm = TRUE)),
         min_s_hi = suppressWarnings(min(b$s_hi, na.rm = TRUE)),
         counterexample_years = yrs(b, "counterexample"), indeterminate_years = yrs(b, "indeterminate"), votes = "no")
}
