# P19_GF S6: central analysis (method card v3 §4, §8). Checks first, then bounds, states and verdicts.
source("./P19_GF/modern/00_common.R")

# ---- Coverage map of Table 1 components (card §4, §5C-5) ------------------------------------
cov <- tribble(~component, ~class, ~workbook_column,
  "Pensions","hr","Pensions", "Education","hr","EducationNatives; Education Non- Natives",
  "District surgeons","hr","District Surgeons", "Public health","hr","Public Health",
  "Public worship","hr","Public Worship", "Hospitals (Eastern Cape and Somerset)","hr","Eastern Cape hospital and lepers; Somerset , old and new Hospital",
  "Controller and Auditor General","adm",NA, "Agent general","adm",NA, "Treasury","adm",NA,
  "Colonial Secretary","adm","Colonial Secretary", "The governor","adm","The Governor", "Crown forests","adm","Crown Forests",
  "Joint parliamentary services","adm","Joint parliamentary expenses", "Transkeian territories","adm","Transkeian territories",
  "Immigration","adm",NA, "Rents/rates/gas/lights","adm","Rents, rates, insurance, gas , electric light",
  "Headman & Chiefs allowances","adm","Headman & Chiefs Allowances",
  "Cape Town & frontier mounted riflemen","mil","Cape Town & frontier Mounted riflemen", "Cape forces","mil",NA,
  "Imperial military expenditure","mil","Imperial Military Expr", "Defence and military allowances","mil","Defence and Colonial Military allowance",
  "Divisional courts","law","Divisional Courts", "Registrar of Deeds","law","Registrar of Deeds", "High court Sheriff","law","High Sheriff",
  "Superior courts","law","Superior Courts", "Police and gaols","law","Police and Gaol", "Convicts","law","Convicts and Prisons",
  "(not listed in Table 1) Robben Island","law","Robben Island",
  "Loans repaid","debt",NA, "Public debt servicing","debt","National Debt Servicing", "Unpaid advances from the previous year","debt",NA,
  "Railways","pw","Total Railways", "Roads & Bridges","pw","Roads & Bridges", "Works and buildings","pw","Works & Buildings",
  "Conveyance of mails","pw","Conveyance of mails", "Telegraph","pw","Telegraph", "Post office","pw","Post Office",
  "Ports and harbours","pw","Ports and Harbours", "Customs","pw","Customs", "Mines","pw","Mines",
  "Lands and agriculture","pw",NA, "Surveyor General","pw","Surveyor General", "Engineer and inspector of works","pw",NA,
  "Lighthouse","pw",NA, "Commissioner of public works","pw","Commissioner for public works") |>
  mutate(in_workbook = !is.na(workbook_column),
         H2_role = ifelse(class %in% c("pw", "debt"), "numerator and denominator", "denominator only"),
         H1_role = case_when(workbook_column == "Total Railways" ~ "numerator and denominator",
                             workbook_column %in% A2 ~ "denominator only", TRUE ~ "not in claim"))
write_csv(cov, file.path(OUT, "coverage_map.csv"), na = "")

# ---- Checks before any verdict (card §4) ----------------------------------------------------
chk <- list()
# 1. unique years; window years absent from the sheet are inserted as NA rows (indeterminate), never dropped
stopifnot(!anyDuplicated(e$year))
miss_years <- setdiff(c(W1, W2), e$year)
chk$c1 <- sprintf("1. unique year keys: yes; window years absent from sheet: %s",
                  if (length(miss_years)) paste(miss_years, collapse = " ") else "none")
if (length(miss_years)) e <- bind_rows(e, tibble(year = miss_years))
# 4. columns exist; no column in two H2 classes; observed components non-negative (monotonicity, card §4)
stopifnot(all(c(A2, GE) %in% names(e)), !anyDuplicated(GE))
stopifnot(all(unlist(e[c(GE, "Total Expenditure")]) >= 0, na.rm = TRUE))
chk$c4 <- "4. all Fig A2 and Table 1 workbook columns exist; no column in two classes; no negative observed value"
# 5. Fig A2 aggregate is a subset of Table 1 public works
stopifnot(all(A2 %in% PWT1)); chk$c5 <- "5. Fig A2 components are a subset of Table 1 public works"
# 2. reproduce repro_r/results_r.csv with the rebuild's choices (NA = 0, period means)
z <- function(cols) rowSums(e[cols], na.rm = TRUE)
rr <- read_csv(file.path(ROOT, "P19_GF/repro_r/results_r.csv"), show_col_types = FALSE)
reb <- tibble(year = e$year, rail = z(map$rail), pw = z(PWT1), debt = z(map$debt), total = e$`Total Expenditure`)
b1 <- filter(reb, year %in% W1, rail > 0); h1_reb <- mean(100 * b1$rail / b1$pw)
a2 <- filter(reb, year %in% W2); h2_reb <- mean(100 * (a2$pw + a2$debt) / a2$total, na.rm = TRUE)
d1 <- abs(h1_reb - rr$value[rr$claim_id == "TX_abs_rail70"]); d2 <- abs(h2_reb - rr$value[rr$claim_id == "TX_p351_pwdebt70"])
stopifnot(d1 < 1e-9, d2 < 1e-9)
chk$c2 <- sprintf("2. rebuild reproduced: TX_abs_rail70 = %.10f (|diff| %.1e); TX_p351_pwdebt70 = %.10f (|diff| %.1e)", h1_reb, d1, h2_reb, d2)
# 3. H2 denominator with NA = 0 equals repro_r classified, year by year
xc <- read_csv(file.path(ROOT, "P19_GF/repro_r/output/expenditure_classes.csv"), show_col_types = FALSE)
ge0 <- z(GE)[match(xc$year, e$year)]; d3 <- max(abs(ge0 - xc$classified) / pmax(1, xc$classified))
stopifnot(d3 < 1e-12)
chk$c3 <- sprintf("3. GE (NA = 0) equals repro_r classified in all %d years (max rel. diff %.1e)", nrow(xc), d3)
writeLines(c("P19_GF S6 pre-verdict checks (card §4): all passed", unlist(chk[c("c1", "c2", "c3", "c4", "c5")])),
           file.path(OUT, "checks.txt"))
cat(unlist(chk[c("c1", "c2", "c3", "c4", "c5")]), sep = "\n")

# ---- Central analysis --------------------------------------------------------------------
bH1 <- bounds(H1, W1) |> mutate(claim = "H1"); bH2 <- bounds(H2, W2) |> mutate(claim = "H2")
comp <- e |> select(year, all_of(unique(c(A2, GE))))       # components, NA kept as NA
annual <- bind_rows(bH1, bH2) |> relocate(claim) |> left_join(comp, by = "year")
write_csv(annual, file.path(OUT, "annual_shares.csv"), na = "NA")

prim <- bind_rows(
  summ(bH1, "central", "H1", "rail / Fig A2 public works, every year 1880-1909, unknowns in [0, M_c]", "none"),
  summ(bH2, "central", "H2", "(Table 1 PW + debt) / GE (six classes), every year 1870-1909, unknowns in [0, M_c]", "none")) |>
  mutate(votes = "yes", above_years = c(yrs(bH1, "above"), yrs(bH2, "above")),
         max_s_lo = c(max(bH1$s_lo, na.rm = TRUE), max(bH2$s_lo, na.rm = TRUE)),
         max_s_hi = c(max(bH1$s_hi, na.rm = TRUE), max(bH2$s_hi, na.rm = TRUE)))
write_csv(prim, file.path(OUT, "primary.csv"))

vt <- function(p, thr, note) tibble(claim = p$claim,
  estimate = sprintf("min annual share %.2f (%d); A/C/I = %d/%d/%d of %d years", p$min_s0, p$year_min_s0, p$A, p$C, p$I, p$n_years),
  interval = sprintf("[%.2f, %.2f] = [min s_lo, min s_hi] over window", p$min_s_lo, p$min_s_hi), test_p = NA_real_,
  threshold_or_band = thr, verdict = p$as_if_verdict, rule = p$as_if_rule, note = note)
nt <- function(cl, band, why) tibble(claim = cl, estimate = NA_character_, interval = NA_character_, test_p = NA_real_,
                                     threshold_or_band = band, verdict = "not-testable", rule = NA_integer_, note = why)
verdict <- bind_rows(
  vt(prim[1, ], "s_t > 70 every year 1880-1909", "Fig A2 five-component denominator; concerns those components only; no inference (census)"),
  nt("H1-c", "n/a (causal clause)", "no identifying variation (card §1)"),
  vt(prim[2, ], "s_t > 70 every year 1870-1909", "reconstructed GE (six Table 1 classes from workbook); no inference (census)"),
  nt("H3", "[1.935, 2.365]", "population and De Zwart deflator not recovered"),
  nt("H4", "[6.129, 7.491]", "population and De Zwart deflator not recovered"),
  nt("H5", "[4.014, 4.906]", "population and De Zwart deflator not recovered"))
write_csv(verdict, file.path(OUT, "verdict.csv"), na = "")
write_csv(verdict, file.path(OUT, "verdicts.csv"), na = "")   # file name used in card §4
options(width = 250)
print(as.data.frame(select(prim, claim, n_years, A, C, I, as_if_verdict, as_if_rule, mean_s0, min_s0, year_min_s0,
                           min_s_lo, min_s_hi, counterexample_years, indeterminate_years)))
print(as.data.frame(select(filter(annual, state != "above"), claim, year, s0, s_lo, s_hi, state, unknown_cols)))
