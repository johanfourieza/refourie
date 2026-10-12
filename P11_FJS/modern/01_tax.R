# P11_FJS S6 01: household tax construction (card §3) and the pre-verdict checks of §4.
# (1) missing tax inputs in 1700 / 1773 (§4, Codex RC5); (2) corrections off -> S2 run-A1 household totaltax
# within 0.01 st; (3) corrections off + Stata xtile + workbook share -> Image 9 pastes Deciles!Q12:W21 to every
# printed digit (7 significant digits, as pasted from Stata).
# Outputs: output/check_missing.csv, output/check_corrections_off.csv, output/check_image9_cells.csv;
#          D:/.../modern/_scratch/households.rds (household level, A6).
source("./P11_FJS/modern/00_common.R")
suppressPackageStartupMessages(library(tidyxl))

base <- load_base()

# (1) missing tax inputs
miss <- base |> filter(jaar %in% c(1700, 1773)) |> group_by(jaar) |>
  summarise(n = n(), across(all_of(TAX_INPUTS), ~ sum(is.na(.x))), ds_missing = sum(is.na(ds))) |>
  mutate(any_tax_input_missing = rowSums(across(all_of(TAX_INPUTS))) > 0)
write_csv(miss, file.path(OUT, "check_missing.csv"))

# (2) corrections off vs S2 run A1
off  <- tax_off(base)
a1   <- read_dta(dpath(P, "repro_original", "_scratch", "runA1_households.dta")) |> zap_labels()
stopifnot(nrow(a1) == nrow(off), all(a1$naam == off$naam), all(a1$jaar == off$jaar))
d_tax <- max(abs(off$tax - a1$totaltax))

# (3) Stata xtile and workbook means vs Deciles!Q12:W21
off <- off |> group_by(jaar) |> mutate(dec = xtile10(tslaves)) |> ungroup()
dec_ok <- all(off$dec == a1$slavesdecile)
offf <- tax_off_float(base) |> mutate(dec = off$dec)          # Stata float storage (D2)
d_taxf <- max(abs(offf$tax - a1$totaltax))
cells <- xlsx_cells(dpath(P, "original", "Fourie Jansen Siebrits", "Fiscal policy.xlsx"), sheets = "Deciles")
img9 <- tibble(year = IMG9, col = 17:23) |> tidyr::crossing(dec = 1:10) |> mutate(row = 11 + dec) |>
  left_join(cells |> select(row, col, paste = numeric), by = c("row", "col"))
means9 <- function(d, nm) d |> filter(jaar %in% IMG9) |> group_by(year = jaar) |>
  summarise(m = list(wb_means(dec, tax))) |> tidyr::unnest_longer(m, indices_to = "dec") |> rename(!!nm := m)
img9 <- img9 |> left_join(means9(off, "m_double"), by = c("year", "dec")) |> left_join(means9(offf, "m_float"), by = c("year", "dec")) |>
  mutate(match_double = abs(signif(m_double, 7) - paste) <= 1e-9 * pmax(1, abs(paste)),
         match_float  = abs(signif(m_float, 7) - paste) <= 1e-9 * pmax(1, abs(paste)))
write_csv(img9 |> select(year, dec, paste, m_double, m_float, match_double, match_float), file.path(OUT, "check_image9_cells.csv"))
w24  <- with(filter(offf, jaar == 1773), share_wb(dec, tax))
w24p <- 100 * cells$numeric[cells$address == "W24"]

chk <- tibble(
  check = c("off construction vs S2 run-A1 household totaltax (max |diff|, st), double arithmetic",
            "off construction vs S2 run-A1 household totaltax (max |diff|, st), Stata float storage",
            "R xtile10 equals Stata slavesdecile (all retained records)",
            "Image 9 pastes Deciles!Q12:W21 to every printed digit, double arithmetic (cells matching / 70)",
            "Image 9 pastes Deciles!Q12:W21 to every printed digit, Stata float storage (cells matching / 70)",
            "workbook share 1773 from float means vs Deciles!W24 x100 (|diff| < 5e-5, 7 sig. digits of the pastes)",
            "no missing tax input in 1700 or 1773"),
  value = c(d_tax, d_taxf, dec_ok, sum(img9$match_double), sum(img9$match_float), w24, !any(miss$any_tax_input_missing)),
  pass  = c(d_tax <= 0.01, d_taxf <= 0.01, dec_ok, NA, all(img9$match_float), abs(w24 - w24p) < 5e-5,
            !any(miss$any_tax_input_missing)))
write_csv(chk, file.path(OUT, "check_corrections_off.csv"))
print(chk, width = 200)

# Primary household file (card §3) with the coded construction carried alongside for §5A
prim <- make_tax(base)
hh <- prim |> select(rid, jaar, ds, naam, van, tslaves, assets, uset, poll, winetax, graintax, meattax, tax, outO) |>
  mutate(tax_off = off$tax, dec_xtile = off$dec)
saveRDS(hh, file.path(SCR, "households.rds"))
cat("Gate (all checks pass):", all(chk$pass, na.rm = TRUE), "\n")
