# P27_RW S3 recreation: decisions

**Independence level: conditional.** The allow-list permitted `numbersandwealth.dta`, and its `wealthrijks` variable (inventory wealth at MOOC 10 median prices) was used as-is for Table 5. I did not rebuild the prices from the MOOC 10 Produkte XML. T3, T4 and T6–T8 use only item counts from the same file. No .do files, deny-list workbooks, `repro_original/`, `compare/` or `audit.md` were read.

Scripts run from the project root: `01_clean.R` (data), `02_analysis.R` (results_r.csv), `03_figures.R` (Fig 5 analogue in `output/`). Data scratch is in `D:\Data\ReplicateMe\P27_RW\repro_r\_scratch\`.

## Choices made before any systematic comparison
1. **Sample.** The 2,577 inventories are the rows of `numbersandwealth.dta` with a non-missing `date` (3,444 rows in total; the 867 undated rows are dropped). Double entries are not removed, because the paper does not say they are (inconsistency 11 in claims_spec); the item sums and n then reproduce T3.
2. **Slaves.** `slavesnumb` is the slave count (`slaves2` is not).
3. **Table 5.** The row label is the dta `decade` variable, so row 1700 holds inventories dated up to about 1709 and also the earliest ones. Pre-1801 = drop the "1806" decade (n = 2,228), which keeps the "1800" row (n = 414).
4. **Percentiles.** Type 2, `quantile(..., type = 2)`, as the nearest Stata analogue. SD uses n − 1. The SE column is sd/√n for means, and sqrt(p(1 − p)/n) × 100 for shares in T6–T8. These are conventional SEs and there are no clustering or robust analogues, as the paper has no estimates.
5. **Opgaafrolle (Table 4).** Sheet `Data` of `Opgaafrolle 1 Des 2010.xlsx`, years 1700–73, one row per household (n = 15,587). Column headers are ambiguous because they repeat. I identified the columns by matching **published column totals** (an acknowledged use of the published numbers): slaves = SM + SV + SS + SD (second column of each pair), horses = PD, cattle = BSTE, sheep = SKPE. The sums match T4 exactly.
6. **Tables 6–8, Cape cells.** Item shares = % of inventories with count > 0; T6 = books, T7 = timepieces, T8 = paintings. Class cK = the dta `group` variable, which is defined by slaves (1 = 0; 2 = 1–4; 3 = 5–15; 4 = 16+). This differs from the paper's stated 1–5 and 6–15 cut. Window codes: `a_b` = years a to b (b = 1 digit gives the end year of the decade, 2 digits the end year within the century); a single year y = window [y − 5, y + 4] (my guess).
7. **Fig 5.** Annual mean wealth for 1700–95, linear OLS trend evaluated at 1700 and 1795, centred 5-year moving average at 1715/1740/1765/1790 (guess for "five-period").

## Unavailable, with reasons
- **T1 (30):** the 1732 La Fontaine survey counts (Schutte) are not in the allowed data.
- **F4 and the auction-based text claims (price shares, 280 households):** these need a rebuild from MOOC 10 prices; not attempted within the turn cap.
- **T6–T8 comparator regions** (Chesapeake, England, Holland, etc.) and the cells printed under R/S book splits: no data.
- **Constants and citations** (conversion rates, Brunt growth rates, numeracy, Strijdom paintings, printing press, mirror shares by income group), `text_n_stell` (the dta `stb` flag sums to 678, not 134, so I did not use it), `text_inv_share_pop`.

## Post-hoc changes
- A first pass left the T3 claims on items whose ids have no underscore (e.g. `firetongs`) unfilled; I made the id matcher accept both spellings. This changed only which claims were filled, not any value.

## Observed (after the run)
T3 and T4 reproduce at 1% tolerance in ≥97% of rows (T4: all). T5 reproduces except for small-integer rounding (e.g. p10 of 1.58 vs 2). T6–T8 Cape cells agree less closely (45%, 37% and 57% within 1%), probably because of the window and class definitions. `text_fig5_early_level` is 1,120 against the printed 1,000 (the text says stuivers; unit ambiguity).
