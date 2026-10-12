# P19_GF S6: supplementary analyses (method card v3 §5A-§5D). Reported only; none votes.
source("./P19_GF/modern/00_common.R")
z <- function(cols, d = e) rowSums(d[cols], na.rm = TRUE)
bH1 <- bounds(H1, W1); bH2 <- bounds(H2, W2)
mean_row <- function(b, id, claim, desc) tibble(id = id, claim = claim, description = desc,
  estimand_change = "summary statistic (period mean)", n_years = nrow(b), mean_s0 = mean(b$s0),
  as_if_verdict = ifelse(mean(b$s0) > 70, "mean above 70", "mean at or below 70"), votes = "no")

# ---- 5A same estimand, different treatment of unknowns --------------------------------------
drop_unknown <- function(b) { k <- filter(b, n_unknown == 0) |> point_states(); attr(k, "dropped") <- nrow(b) - nrow(k); k }
dH1 <- drop_unknown(bH1); dH2 <- drop_unknown(bH2)
# 5A-5: Robben Island moved from law to hr. Both classes are denominator-only in H2, so the spec is identical.
map_ri <- map; map_ri$law <- setdiff(map$law, "Robben Island"); map_ri$hr <- c(map$hr, "Robben Island")
GE_ri <- unlist(map_ri[c("hr","adm","mil","law","debt","rail","pwo")], use.names = FALSE)
bH2_ri <- bounds(spec(c(PWT1, map$debt), setdiff(GE_ri, c(PWT1, map$debt))), W2)
ri_diff <- max(abs(c(bH2_ri$s0 - bH2$s0, bH2_ri$s_lo - bH2$s_lo, bH2_ri$s_hi - bH2$s_hi)), na.rm = TRUE)
sA <- bind_rows(
  summ(point_states(bH1), "5A-1", "H1", "zero-fill point series (NA = 0)", "none (treatment of unknowns)"),
  summ(point_states(bH2), "5A-1", "H2", "zero-fill point series (NA = 0)", "none (treatment of unknowns)"),
  summ(bounds(H1, W1, cap_double), "5A-2", "H1", "wider cap 2*M_c", "none (treatment of unknowns)"),
  summ(bounds(H2, W2, cap_double), "5A-2", "H2", "wider cap 2*M_c", "none (treatment of unknowns)"),
  summ(bounds(H1, W1, cap_local), "5A-3", "H1", "narrower cap: column max over |year - t| <= 5", "none (treatment of unknowns)"),
  summ(bounds(H2, W2, cap_local), "5A-3", "H2", "narrower cap: column max over |year - t| <= 5", "none (treatment of unknowns)"),
  summ(dH1, "5A-4", "H1", sprintf("drop years with any unknown component (%d removed)", attr(dH1, "dropped")), "none (treatment of unknowns)"),
  summ(dH2, "5A-4", "H2", sprintf("drop years with any unknown component (%d removed)", attr(dH2, "dropped")), "none (treatment of unknowns)"),
  summ(bH2_ri, "5A-5", "H2", sprintf("Robben Island in human resources (max |share change| = %.1e)", ri_diff), "none (classification check)"))

# ---- 5B changed estimand or changed population of years -----------------------------------
num2 <- c(PWT1, map$debt)
sB <- bind_rows(
  summ(bounds(spec(map$rail, map$pwo), W1), "5B-1", "H1", "Table 1 public works (PW T1) as denominator", "denominator"),
  mean_row(bH1, "5B-2", "H1", "period mean of s0, 1880-1909, compared with 70"),
  summ(bounds(H1, 1877:1909), "5B-3", "H1", "window 1877-1909", "window"),
  summ(bounds(spec(num2, character(0), den_fixed = "Total Expenditure"), W2), "5B-4", "H2", "Total Expenditure as denominator", "denominator"),
  summ(bounds(spec(num2, setdiff(H2$den_only, map$mil)), W2), "5B-5", "H2", "GE minus defence (Table 2 construction)", "denominator"),
  summ(bounds(spec(c(A2, map$debt), setdiff(GE, c(A2, map$debt))), W2), "5B-6", "H2", "public works restricted to Fig A2 components, GE denominator", "numerator"),
  summ(bounds(H2, W1), "5B-7", "H2", "window 1880-1909", "window"),
  mean_row(bH2, "5B-8", "H2", "period mean of s0, 1870-1909, compared with 70"),
  summ(bounds(H2, setdiff(W2, 1872:1876)), "5B-9", "H2", "1870-1909 without 1872-1876 (cannot test the universal claim)", "population of years"))

# ---- 5C diagnostics ----------------------------------------------------------------------
# 5C-1 every year at or below 70 (s0), with distance from 70
le70 <- bind_rows(mutate(bH1, claim = "H1"), mutate(bH2, claim = "H2")) |> filter(s0 <= 70) |>
  select(claim, year, s0, s_lo, s_hi, dist_s0, state)
write_csv(le70, file.path(OUT, "diag_years_le70.csv"))
# 5C-2 classified / Total Expenditure, 1827-1909 (NA = 0 classified sum)
ratio <- tibble(year = e$year, classified = z(GE), total = e$`Total Expenditure`, ratio = classified / total)
write_csv(ratio, file.path(OUT, "diag_classified_total_ratio.csv"))
# 5C-3 item-level missingness
cols <- unique(c(A2, GE))
mi <- bind_rows(lapply(cols, function(c) {
  v <- e[[c]]; obs <- e$year[!is.na(v)]; na_y <- e$year[is.na(v)]
  w1 <- intersect(na_y, W1); w2 <- intersect(na_y, W2)
  int <- function(y) if (!length(y)) "" else paste(ifelse(y > min(obs) & y < max(obs), "interior", "edge"), collapse = " ")
  tibble(column = c, in_H1 = c %in% A2, in_H2 = c %in% GE, na_count_all = length(na_y), M_c = Mc[[c]],
         na_years_W1 = paste(w1, collapse = " "), na_type_W1 = int(w1), na_years_W2 = paste(w2, collapse = " "), na_type_W2 = int(w2))
}))
write_csv(mi, file.path(OUT, "missingness_items.csv"))
# 5C-4 components in the year of the minimum s0
minyr <- function(b, sp) { t <- b$year[which.min(b$s0)]; r <- e[e$year == t, ]
  tibble(year = t, column = c(sp$num, sp$den_only), role = rep(c("numerator", "denominator only"), c(length(sp$num), length(sp$den_only))),
         value = unlist(r[c(sp$num, sp$den_only)])) |> arrange(desc(value)) }
mins <- bind_rows(mutate(minyr(bH1, H1), claim = "H1"), mutate(minyr(bH2, H2), claim = "H2")) |> relocate(claim)
write_csv(mins, file.path(OUT, "diag_min_year_components.csv"), na = "NA")
# 5C-6 currency and units: non-integer columns; notes sheet of the predecessor workbook
notes <- suppressMessages(read_excel(pth2, sheet = "notes", col_names = FALSE))[[1]]
units <- tibble(column = cols, non_integer_values = sapply(cols, function(c) sum(abs(e[[c]] - round(e[[c]])) > 1e-9, na.rm = TRUE)),
                unit_note = paste(na.omit(notes[grepl("pound|shilling|pence|convert", notes, ignore.case = TRUE)]), collapse = " | "),
                column_specific_unit_note = FALSE)
write_csv(units, file.path(OUT, "diag_units.csv"))
# 5C-7 capital versus current: railway line exceeds non-railway classified total or Total Expenditure
capv <- tibble(year = e$year, rail = e$`Total Railways`, nonrail_classified = z(setdiff(GE, map$rail)),
               total = e$`Total Expenditure`) |>
  mutate(rail_over_nonrail = rail / nonrail_classified, rail_over_total = rail / total) |>
  filter(rail > nonrail_classified | rail > total)
write_csv(capv, file.path(OUT, "diag_capital_current.csv"))
# 5C-8 overlapping categories: cross-tab of columns by class
xt <- bind_rows(lapply(names(map), function(k) tibble(column = map[[k]], class = k))) |>
  mutate(in_A2 = column %in% A2) |> add_count(column, name = "n_classes") |>
  mutate(total_column_with_parts = column %in% c("Total Expenditure"))
stopifnot(all(xt$n_classes == 1), !any(xt$total_column_with_parts))
write_csv(xt, file.path(OUT, "diag_overlap.csv"))

# ---- 5D secondary outputs ---------------------------------------------------------------
cls <- tibble(year = e$year, hr = z(map$hr), adm = z(map$adm), mil = z(map$mil), law = z(map$law),
              debt = z(map$debt), pw = z(PWT1), total = e$`Total Expenditure`)
t2 <- tibble(year = c(1853, 1865, 1875, 1891, 1904), adm = c(.58, .44, .4, .59, 1.32), debt = c(.11, .56, .33, .83, .69),
             hr = c(.16, .13, .14, .21, .34), pw = c(1.3, 1.57, 1.44, 2.87, 4.46), tot = c(2.15, 2.7, 2.31, 4.5, 6.81))
w <- filter(cls, year %in% t2$year) |> mutate(den = adm + law + debt + hr + pw)
Sa <- tibble(year = t2$year, pub_pw = 100 * t2$pw / t2$tot, wb_pw = 100 * w$pw / w$den, pub_debt = 100 * t2$debt / t2$tot,
             wb_debt = 100 * w$debt / w$den, pub_hr = 100 * t2$hr / t2$tot, wb_hr = 100 * w$hr / w$den,
             pub_admlaw = 100 * t2$adm / t2$tot, wb_admlaw = 100 * (w$adm + w$law) / w$den, wb_defence_of_total = 100 * w$mil / w$total)
write_csv(Sa, file.path(OUT, "secondary_Sa_table2_composition.csv"))
r <- suppressMessages(read_excel(pth, sheet = "Revenue", .name_repair = "minimal"))
names(r) <- make.unique(names(r)); r <- mutate(r, across(everything(), as.numeric))
stopifnot(all(r$YEAR == r$YEAR.1, na.rm = TRUE))
bal <- inner_join(tibble(year = e$year, total = e$`Total Expenditure`, rail = z(map$rail)),
                  transmute(r, year = YEAR, rev = `Total Revenue`, railrev = `Railway revenue`), by = "year") |>
  filter(year >= 1872) |> mutate(def = total - rev, def_xrail = (total - rail) - (rev - ifelse(is.na(railrev), 0, railrev)))
d <- suppressMessages(read_excel(pth, sheet = "Public Debt -Blue Books")); names(d) <- c("year", "gdp", "gen_gov", "corp_boards", "pubdebt", "debt_serv")
d <- mutate(d, across(everything(), as.numeric), debt_gdp = 100 * pubdebt / gdp)
dg <- function(y) d$debt_gdp[d$year == y]
items <- sapply(map$pwo, function(c) max(e[[c]], na.rm = TRUE))
sD <- tribble(~id, ~claim, ~description, ~value, ~target,
  "5D S-a", "H5 analogue", "1904 workbook PW share of four-category total x 6.81 (different estimand)", Sa$wb_pw[5] / 100 * 6.81, "4.46",
  "5D S-b(i)", "deficit", sprintf("max (Total Exp - Total Rev) 1872-1909, m (year %d)", bal$year[which.max(bal$def)]), max(bal$def) / 1e6, "up to 2m",
  "5D S-b(ii)", "deficit", sprintf("max deficit excl. railway exp and receipts 1872-1909, m (year %d)", bal$year[which.max(bal$def_xrail)]), max(bal$def_xrail) / 1e6, "up to 2m",
  "5D S-c", "debt/GDP 1885", "public debt / GDP (national series needs Stone 1999, not recovered)", dg(1885), "close to 230",
  "5D S-c", "debt/GDP 1899", "public debt / GDP", dg(1899), "almost 200",
  "5D S-c", "debt/GDP 1900", "public debt / GDP", dg(1900), "almost 200",
  "5D S-c", "debt/GDP 1909", "public debt / GDP", dg(1909), "above 140",
  "5D S-d", "railway max", sprintf("max Total Railways, m (year %d)", e$year[which.max(e$`Total Railways`)]), max(e$`Total Railways`, na.rm = TRUE) / 1e6, "4.5m",
  "5D S-d", "other infra max", sprintf("max single non-railway PW item, m (%s)", names(which.max(items))), max(items) / 1e6, "0.5m") |>
  mutate(votes = "no")

sens <- bind_rows(sA, sB, sD) |> mutate(votes = "no")
write_csv(sens, file.path(OUT, "sensitivities.csv"), na = "")
options(width = 250)
print(as.data.frame(select(bind_rows(sA, sB), id, claim, n_years, A, C, I, as_if_verdict, mean_s0, min_s0, min_s_lo)))
print(as.data.frame(select(sD, id, claim, value, target))); print(round(as.data.frame(Sa), 1))
cat("Robben Island max diff:", ri_diff, "\n"); print(as.data.frame(capv)); print(as.data.frame(filter(ratio, ratio > 1.1 | ratio < 0.5)))
