# P11_FJS  S2: recalculate the workbook formula chain and map the Stata output to the frozen claims.
#
# Inputs  : ./P11_FJS/repro_original/_scratch/run0_households.dta   (run_0_original.do)
#           ./P11_FJS/repro_original/_scratch/runA1_households.dta  (run_A1_wine48.do, A' alignment)
#           ./P11_FJS/original/Fourie Jansen Siebrits/Fiscal policy.xlsx (read only)
#           ./P15_FvZ/repro_original/recalc_cells_primary.rds (P15 S2 recalculated GDP chain, read only)
#           claims/claims.csv (frozen, read only)
# Outputs : repro_original/recalc_fidelity.csv     every workbook formula: recalculated vs cached
#           repro_original/image7_image9_check.csv Stata-derived Image 7 and Image 9 series vs the values pasted in the workbook
#           repro_original/results_original.csv     source = original (run 0, environment patches only)
#           repro_original/results_original_A1.csv  A' alignment run (separately labelled; not used in pair A)
#
# Workbook values are used only (a) as hard-coded secondary-source INPUTS where the workbook has no formula
# (property tax Tables!W, pachten VOC Income!C:E), and (b) to verify the recalculation. No claim value is a cached cell.

suppressPackageStartupMessages({library(dplyr); library(tidyr); library(readr); library(tidyxl); library(haven); library(stringr)})
args_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
root <- if (length(args_file)) normalizePath(file.path(dirname(args_file), "..")) else here::here()
od <- file.path(root, "repro_original")
source(file.path(root, "..", "tools", "paths.R"))
sc <- dpath("P11_FJS", "repro_original", "_scratch")
wb <- dpath("P11_FJS", "original", "Fourie Jansen Siebrits", "Fiscal policy.xlsx")
claims <- read_csv(file.path(root, "claims", "claims.csv"), show_col_types = FALSE)

# ---------------------------------------------------------------- 1. workbook formula chain -------------
cells <- xlsx_cells(wb) |> filter(!is_blank | !is.na(formula))
col2n <- function(s) { s <- utf8ToInt(s) - 64L; sum(s * 26^(rev(seq_along(s)) - 1)) }
val <- cells |> mutate(v = numeric) |> select(sheet, address, row, col, v, formula)
val$v[!is.na(val$formula)] <- NA_real_                      # clear every formula cell: inputs only
get1 <- function(sh, a) { k <- val$sheet == sh & val$address == a; x <- val$v[k]
  if (!length(x)) return(0)                                  # blank = 0
  if (is.na(x)) return(if (!is.na(val$formula[k])) NA_real_ else 0)   # unresolved/external formula propagates NA
  x }
getr <- function(sh, a1, a2) {
  p <- function(a) list(c = col2n(str_extract(a, "^[A-Z]+")), r = as.integer(str_extract(a, "[0-9]+$")))
  s <- p(a1); e <- p(a2)
  x <- val |> filter(sheet == sh, row >= s$r, row <= e$r, col >= s$c, col <= e$c)
  x$v[!is.na(x$v)]
}
evalf <- function(sh, f) {
  if (grepl("\\[1\\]", f)) return(NA_real_)                   # external link to a workbook that did not survive
  f <- gsub("\\$", "", sub("^\\+", "", f))
  f <- gsub("SUM\\(([A-Z]+[0-9]+):([A-Z]+[0-9]+)\\)", sprintf("sum(getr('%s','\\1','\\2'))", sh), f)
  f <- gsub("AVERAGE\\(([A-Z]+[0-9]+):([A-Z]+[0-9]+)\\)", sprintf("mean(getr('%s','\\1','\\2'))", sh), f)
  f <- gsub("(?<![A-Za-z'])([A-Z]{1,2}[0-9]+)(?![0-9']|',)", sprintf("get1('%s','\\1')", sh), f, perl = TRUE)
  eval(parse(text = f))
}
fx <- val |> filter(!is.na(formula))
for (pass in 1:5) for (i in seq_len(nrow(fx))) {               # 5 passes resolve the (shallow) dependency chain
  k <- which(val$sheet == fx$sheet[i] & val$address == fx$address[i])
  val$v[k] <- evalf(fx$sheet[i], fx$formula[i])
}
fid <- fx |> select(sheet, address, formula) |>
  left_join(val |> select(sheet, address, recalc = v), by = c("sheet", "address")) |>
  left_join(cells |> select(sheet, address, cached = numeric), by = c("sheet", "address")) |>
  mutate(abs_diff = abs(recalc - cached), ok = !is.na(abs_diff) & abs_diff < 1e-6,
         unresolved = is.na(recalc),
         note = ifelse(grepl("\\[1\\]", formula), "external link [1]Agricultural production (workbook not surviving)", ""))
write_csv(fid, file.path(od, "recalc_fidelity.csv"), na = "")
cat("Formula cells:", nrow(fid), " recalculated = cached:", sum(fid$ok), " not recalculable (external link or dependent):", sum(fid$unresolved), " mismatches among recalculable:", sum(!fid$ok & !fid$unresolved), "
")
rv <- function(sh, a) val$v[val$sheet == sh & val$address == a]

# secondary-source inputs (typed values) used by Image 7
prop <- val |> filter(sheet == "Tables", col == col2n("U"), row >= 2, row <= 80) |> select(row, year = v) |>
  left_join(val |> filter(sheet == "Tables", col == col2n("W")) |> select(row, property = v), by = "row") |> select(-row)
pacht <- val |> filter(sheet == "VOC Income (VD&R)", col == 1, row >= 4, row <= 97) |> select(row, year = v) |>
  left_join(val |> filter(sheet == "VOC Income (VD&R)", col %in% 3:5) |> select(row, col, v) |>
              pivot_wider(names_from = col, values_from = v), by = "row") |>
  transmute(year, winepacht = coalesce(`3`, 0), brandypacht = coalesce(`4`, 0), foreign = coalesce(`5`, 0))

# ---------------------------------------------------------------- 2. Stata output -> Image 7, Image 9 ----
img7_years <- c(1700, 1705, 1712, 1719, 1723, 1731, 1738, 1741, 1757, 1773)
img9_years <- c(1700, 1719, 1731, 1738, 1741, 1757, 1773)
build <- function(run) {
  h <- read_dta(file.path(sc, paste0(run, "_households.dta")))
  # Tables!L58 etc.: guilders = stuivers / 48 * 3
  s7 <- h |> group_by(year = as.numeric(jaar)) |>
    summarise(poll = sum(tax) / 48 * 3, winetax = sum(winetax) / 48 * 3, grain = sum(wheattax) / 48 * 3,
              meat = sum(meattax) / 48 * 3, n = n(), .groups = "drop") |>
    filter(year %in% img7_years) |>
    left_join(prop, by = "year") |> left_join(pacht, by = "year") |>
    mutate(property = coalesce(property, 0),
           total = poll + winetax + grain + meat + property + winepacht + brandypacht + foreign)
  # Deciles sheet: mean totaltax by slave decile; deciles emptied by ties take the mean of the
  # nearest lower non-empty decile (as in Deciles!Q12:W21), share = mean10 / sum of the 10 means (W24)
  d <- h |> filter(jaar %in% img9_years) |> group_by(year = as.numeric(jaar), dec = as.integer(slavesdecile)) |>
    summarise(n = n(), m = mean(totaltax), s = sum(totaltax), .groups = "drop")
  s9 <- d |> group_by(year) |> group_modify(function(x, k) {
    full <- tibble(dec = 1:10) |> left_join(x, by = "dec") |> fill(m, .direction = "down")
    tibble(top10_wb = 100 * full$m[10] / sum(full$m),                 # workbook method
           top10_exact = 100 * x$s[x$dec == 10] / sum(x$s),            # exact share of total tax (diagnostic)
           n = sum(x$n), n_top = x$n[x$dec == 10])
  }) |> ungroup()
  list(s7 = s7, s9 = s9)
}
R0 <- build("run0"); RA <- build("runA1")

# workbook pasted values (for the check only)
wb7 <- tibble(year = img7_years[1:10], row = 61:70) |> rowwise() |>
  mutate(wb_poll = rv("Tables", paste0("AA", row)), wb_wine = rv("Tables", paste0("AB", row)),
         wb_total = sum(sapply(c("AA","AB","AC","AD","AE","AF","AG","AH"), function(c) rv("Tables", paste0(c, row))))) |> ungroup()
wb9 <- tibble(year = img9_years, c = c("Q","R","S","T","U","V","W")) |> rowwise() |>
  mutate(wb_top10 = 100 * rv("Deciles", paste0(c, 21)) / sum(sapply(12:21, function(r) rv("Deciles", paste0(c, r)))),
         wb_m10 = rv("Deciles", paste0(c, 21))) |> ungroup()
chk <- bind_rows(
  wb7 |> left_join(R0$s7 |> select(year, run0_wine = winetax, run0_total = total), by = "year") |>
    left_join(RA$s7 |> select(year, A1_wine = winetax, A1_total = total), by = "year") |>
    pivot_longer(-c(year, row), names_to = "series") |> mutate(image = "7"),
  wb9 |> left_join(R0$s9 |> select(year, run0_top10 = top10_wb, run0_exact = top10_exact), by = "year") |>
    left_join(RA$s9 |> select(year, A1_top10 = top10_wb, A1_exact = top10_exact), by = "year") |>
    select(-c) |> pivot_longer(-year, names_to = "series") |> mutate(image = "9"))
write_csv(chk, file.path(od, "image7_image9_check.csv"))

# ---------------------------------------------------------------- 3. P15 GDP (Image 6) ------------------
p15 <- readRDS(dpath("P15_FvZ", "repro_original", "recalc_cells_primary.rds")) |>
  filter(sheet == "total economy", col == 5) |> transmute(year = row + 1698, gdp = 1000 * recalc)

# ---------------------------------------------------------------- 4. claims ----------------------------
mk <- function(R, tag) {
  out <- list(); add <- function(id, v, n = NA, st = NA, note = "") out[[length(out) + 1]] <<- tibble(claim_id = id, source = "original", value = v, se = NA_real_, n = n, status_override = st, note = note)
  s7 <- R$s7; s9 <- R$s9; g <- function(y, v) s7[[v]][s7$year == y]
  # Images 2-5, Image 6 revenue/expenditure, grain-declared share: secondary sources, no code or data in the package
  for (id in claims$claim_id[grepl("^I[2-5]_", claims$claim_id)]) add(id, NA, st = "unavailable", note = "secondary-source table (De Kock/Boeseken/Venter); no code or data survive")
  for (id in claims$claim_id[grepl("^I6_.*_(rev|exp)$", claims$claim_id)]) add(id, NA, st = "unavailable", note = "De Kock (secondary); not in workbook")
  for (id in claims$claim_id[grepl("^I6_.*_def$", claims$claim_id)]) add(id, NA, st = "unavailable", note = "no code; arithmetic exp-rev of the printed table checks (audit S2)")
  for (y in c(1777, 1787, 1789, 1791, 1792)) {
    G <- p15$gdp[p15$year == y]
    add(sprintf("I6_%d_gdp", y), G, note = "P15 S2 recalculated nominal GDP (Van Duin en Ross.xlsx total economy!E x 1000); printed GDP vintage not found in any surviving P15 workbook")
    for (k in c("rev", "exp", "def")) {
      id <- sprintf("I6_%d_%sgdp", y, k); nid <- sprintf("I6_%d_%s", y, k)
      if (!id %in% claims$claim_id) next
      num <- claims$reported_value[claims$claim_id == nid]
      if (!length(num)) num <- if (k == "def") NA else NA
      add(id, if (length(num) && !is.na(num)) 100 * num / G else NA, st = "ambiguous",
          note = "printed numerator (secondary) / P15 recalculated GDP; numerator not reproducible")
    }
  }
  add("txt_p16_defgdp_1789", 100 * 1403000 / p15$gdp[p15$year == 1789], st = "ambiguous", note = "printed deficit / P15 recalculated GDP")
  add("txt_p16_defgdp_1792", 100 * 342000 / p15$gdp[p15$year == 1792], st = "ambiguous", note = "printed deficit / P15 recalculated GDP")
  # Image 7
  for (y in img7_years) add(sprintf("I7_%d_total", y), g(y, "total"), n = g(y, "n"), note = paste(tag, "Stata sums /16 + typed property (Tables!W) + pachten (VOC Income)"))
  for (v in c("poll", "winetax", "grain", "meat", "property", "winepacht", "brandypacht", "foreign"))
    add(paste0("I7_1773_", v), g(1773, v), n = g(1773, "n"),
        note = if (v %in% c("property", "winepacht", "brandypacht", "foreign")) "typed secondary-source input in workbook (not code output)" else tag)
  add("I7_1700_winepacht", g(1700, "winepacht"), note = "typed secondary-source input (VOC Income!C4)")
  # Image 9 and text shares
  for (y in img9_years) add(sprintf("I9_%d_top10", y), s9$top10_wb[s9$year == y], n = s9$n[s9$year == y], note = paste(tag, "workbook method: mean10 / sum of 10 decile means"))
  add("txt_p19_top10_1700", s9$top10_wb[s9$year == 1700], n = s9$n[s9$year == 1700], note = tag)
  add("txt_p19_top10_1773", s9$top10_wb[s9$year == 1773], n = s9$n[s9$year == 1773], note = tag)
  add("txt_p21_top10_1773", s9$top10_wb[s9$year == 1773], n = s9$n[s9$year == 1773], note = tag)
  # Text p.18
  dir1773 <- with(s7[s7$year == 1773, ], poll + winetax + grain + meat + property)
  add("txt_p18_direct1773", 100 * dir1773 / g(1773, "total"), note = "direct = poll+wine tax+grain+meat+property over Image 7 total")
  add("txt_p18_rev1773", g(1773, "total"), note = "Image 7 1773 total; text figure equals this plus the no-0.7 wine tax (Tables!M74)")
  fit <- lm(total ~ year, data = s7)
  add("txt_p18_extrap1777", unname(predict(fit, data.frame(year = 1777))), st = "ambiguous", note = "method not documented; OLS linear trend on the 10 Image 7 totals")
  add("txt_p18_rev1777", NA, st = "unavailable", note = "Company-published figure (De Kock, secondary)")
  add("txt_p10_grain_declared", NA, st = "unavailable", note = "secondary source (Van Duin and Ross)")
  # reconstruction parameters, read from the code (stuivers; 48 stuivers = 1 Rd; guilders = stuivers/16)
  add("txt_p17_poll", 32, note = "fiscalpolicy.do:27,33")
  add("txt_p17_hearth", 192 / 48, note = "fiscalpolicy.do:30")
  add("txt_p17_wine_pre1743", if (tag == "run0") 72 / 48 else 48 / 48, note = if (tag == "run0") "fiscalpolicy.do:47 uses 72 stuivers = 1.5 Rd" else "A1: 48 stuivers")
  add("txt_p17_wine_post1743", 144 / 48, note = "fiscalpolicy.do:48 (x0.7 share brought to Cape Town; effective 2.1 Rd)")
  add("txt_p17_graintax", 10, note = "fiscalpolicy.do:63")
  add("txt_p17_wheatprice", 6, note = "fiscalpolicy.do:63")
  add("txt_p17_barleyprice", 3, note = "fiscalpolicy.do:63")
  add("txt_p17_cattle", 1, note = "fiscalpolicy.do:67")
  add("txt_p17_sheep", 16, note = "fiscalpolicy.do:67 (0.16 per sheep)")
  add("txt_fn28_rixdollar", 48, note = "fiscalpolicy.do:30 (4*48); workbook /48*3")
  add("txt_fn28_guilder", 16, note = "Tables!L58 etc. (/48*3 = /16)")
  bind_rows(out)
}
res0 <- mk(R0, "run0"); resA <- mk(RA, "A1") |> mutate(source = "original_A1")
miss <- setdiff(claims$claim_id, res0$claim_id); extra <- setdiff(res0$claim_id, claims$claim_id); dup <- res0$claim_id[duplicated(res0$claim_id)]
if (length(miss) || length(extra) || length(dup)) stop("claim mismatch: missing ", toString(miss), " | extra ", toString(extra), " | dup ", toString(dup))
write_csv(res0, file.path(od, "results_original.csv"), na = "")
write_csv(resA, file.path(od, "results_original_A1.csv"), na = "")
print(as.data.frame(chk |> pivot_wider(names_from = series, values_from = value) |> select(-any_of("row"))), digits = 6)
