# P06_FGa — S3 independent R recreation: decisions

Written 11 October 2026 **before** any systematic comparison with `claims.csv`. The agent has read the paper (and therefore has seen the published numbers), so the recreation is **not outcome-blind**. Post-hoc changes are logged at the bottom with a reason.

## Independence level

**full (with one caveat).** No code, logs, .tex tables, manuscripts, `repro_original/`, `compare/` or `audit.md` were opened. Inputs used:

| File (under `D:/Data/ReplicateMe/P06_FGa/original/20 FG Comparisons/`) | Use |
|---|---|
| `Data/Data for Johan - Massachusetts and Virginia.xlsx` (Sheet1) | US household tax lists (Maine = State 10, Massachusetts = 4, Virginia = 3). Raw bushels, livestock and enslaved counts. |
| `Data/FourieGarmenCape.xlsx`, sheet `Full` | Cape household opgaafrol transcriptions stacked across the 12 district-year sheets. |
| `Data/FourieGarmenCape.xlsx`, raw sheet `STB1805` | Inspected to diagnose a column shift (see D7). |
| `Prices.xlsx` | US crop price data points (sheet `US Crops Annual Data Points`); Cape auction transcriptions (sheets `Cape auction`, `Cape auction 2–4`); conservative Cape enslaved price (sheet `Final2`, only number not otherwise derivable); cached `Final`/`Final2` rows used only for a sensitivity spec. |
| `Data/USA.xlsx` | Not used for analysis: same 26,915 rows as the raw US file plus derived (price × quantity) columns. |
| `Data/Analysis.xlsx` | Maddison comparators for Figs 1–2; not needed (no claims). |

Caveat: the Cape `Full` sheet is the authors' stacking of the 12 raw district-year sheets into common columns. I did not rebuild that mapping from the 12 Dutch-headed sheets; I checked it against the raw STB1805 sheet. `Final` (an authors' cleaned version of `Full`) was **not** used. Household counts in `Full` equal Table A2 observations exactly, so the household universe is not in question.

## Decisions (ambiguities in the paper and the choice made)

**D1 Benchmarks.** The census year closest to each benchmark: Cape GR 1787→1785, 1798→1795; Stb 1814→1815; Swe 1806→1805. US 1784/1785/1787→1785; 1792/1795→1795; 1801/1805/1806→1805; 1811/1814/1815→1815. Massachusetts has no 1805; Tulbagh and Swellendam only 1805 and 1815.

**D2 Household.** One row of a tax list = one household (taxpayer). The paper notes single men over 16 appear as separate households at the Cape; no adjustment.

**D3 Farmer.** A household is a farmer if total wheat+barley+rye+oats(+corn) reaped ≥ 1 bushel, or cattle > 0, or sheep > 0. Horses do not count (fn 45). Virginia has no crop or sheep data, so Virginia farmers = cattle owners. Farmers are the sample for Table 1, Table A1, crop/livestock income, and Figs 5–6.

**D4 Cattle.** Cape: `Cattle` (total). Massachusetts/Maine: `Total_Cattle` (cows + young cattle) **plus** `Total_Oxen` (oxen are cattle; Cape `Cattle` includes trek oxen). Virginia: `Total_Cattle` (missing coded 0; cattle not recorded in 1795 and partly 1805, so those households cannot be farmers).

**D5 Mudden = bushels.** Cape quantities are in mudden; the paper treats a mud as a bushel (claims_spec item 12). I follow the paper.

**D6 Fractions.** Cape cells such as `46½`, `⅜`, `1/16th` are parsed to decimals. `?`, `damaged`, `NA`, `Numbers` → missing → treated as 0 in sums.

**D7 Stellenbosch 1805 column shift.** 11 households in STB1805 have 7,000–150,000 in `Oatsreaped` (vine stocks). The raw sheet shows that for these rows the reaped block has only three values (wheat, barley, oats; consistent with zero rye sown and oats sown), followed by vines, wine, brandy, each displaced one column left. Fix: oats := `Ryereaped`, rye := 0, vines := `Oatsreaped`, wine := `Vines`, brandy := `Wine` for rows with `Oatsreaped` ≥ 1000. No other district-year shows such values (max wheat reaped anywhere is 950).

**D8 Valuation.** Crop value = Σ bushels × price (wheat, barley, rye, oats, corn). Crops + wine = crop value + wine leggers × P_wine + brandy leggers × P_brandy (Cape only). Livestock income = 0.06 × (cattle × P_cattle + sheep × P_sheep); horses excluded (text: "$148.7 for cattle and sheep"). Income = crop value + livestock income. Enslaved income = 0.06 × value of enslaved people.

**D9 US crop prices (not stated in the paper).** Wright's Massachusetts data points for barley, oats, rye, corn and Adams's Maryland wheat, years 1785–1815 inclusive; where a year has high and low quotes, use the midpoint; then the unweighted mean across years. Nominal dollars (the paper's "circa 1800 dollars" conversion is not described; no deflator applied).

**D10 Cape prices from auctions (crops, wine, brandy, enslaved).** Re-parsed from the four auction transcriptions: one lot = one row with a rijksdaalder price (price = rd + schellingen/8); quantity = leading number of the lot text (enslaved: 1; "half legger": 0.5). Mixed or composite lots ("en", "met haar kind", "hoop", "met wat wijn") and goats are excluded. Category by Dutch keyword (koorn→wheat, garst→barley, rog→rye, haver→oats, paard/merrij→horses, ossen/koeijen/bul/vaars/beesten→cattle, schapen/hamels→sheep, slave/slavin→enslaved, legger wijn→wine, brandewijn→brandy). Auction price = unweighted mean of lot unit prices; Cape price = unweighted mean over the auctions in which the commodity appears ("We take the average of these prices across the four auctions"). Exchange rate 5/4.53 = 1.104 rd per $ (paper rounds to 1.1).

**D11 Prices stated in the paper are taken as given (primary spec P1).** US horses 94.93, cattle 16.32, sheep 3.11; US enslaved 178.51 (16+), 162.95 (under 16: Virginia lists record ages 12–16 after 1787; applied to `Slaves_Under16` in all years). Cape livestock baseline 36.38/19.28/1.73 and conservative 20.24/9.37/1.18 (paper p.16). Conservative Cape enslaved price (Fig 7b) is not stated: taken from `Prices.xlsx` `Final2` (126.97). My own auction-derived livestock prices are reported as the recreation of the stated Cape baseline prices and used in sensitivity P3.

**D12 Sensitivity specs.** P2 = all prices from cached `Prices.xlsx` `Final` (baseline) / `Final2` (conservative). P3 = P1 but Cape livestock prices from my auction parse.

**D13 Gini.** Standard Gini on non-negative household values including zeros, G = Σ(2i−n−1)x(i) / (n Σx), no small-sample correction, pooled years, farmers only. Crops and crops+wine on dollar values; livestock on value of cattle + sheep (Virginia: cattle only); enslaved on head count.

**D14 Table A1.** Mean quantity per farmer (pooled years); "Crops" = sum of the five grain bushels; wine in leggers; horses per farmer reported though horses don't define farmers.

**D15 Table A2.** All households (not only farmers) by district-benchmark: count, mean and max enslaved people. Virginia enslaved = `Total_Slaves`.

**D16 Country averages.** Cape = pooled farmers of the four districts (household-weighted). US crop/income averages = Maine + Massachusetts farmers (fn 59 excludes Virginia). An alternative that counts Virginia farmers as zero crop is also written to `output/text_numbers.csv` (not used for claims).

**D17 Text averages of cattle (p.13).** Primary: mean cattle per farmer, Cape (4 districts) and US (3 states); "excluding non-owners" = mean among farmers with cattle > 0. Alternatives over all households also written out.

**D18 Enslaved ownership (p.17, Fig 7).** Ownership share = share of all households with ≥1 enslaved. Fig 7 income = 0.06 × value, among all slaveholding households (log axis implies owners only); Stellenbosch with conservative Cape price, Virginia with US prices.

**D19 Figures.** Fig 5 = cattle per farmer with cattle > 0, by district, box + violin, log axis. Fig 6 = crop value and crops+wine value among farmers with positive value, Cape vs US (ME+MA), log axis. LEAP theme. Medians written to `output/`.

**D20 Not assessable.** Rothenberg cattle price, the 2,614 appraisals, Virginia 20% sample, 1800 population figures, the conservative Cape livestock prices (from another source) cannot be computed from the allowed files; reported as NA with `status_override = not_assessed`. Paper-stated input prices are reported with `status_override = input`.

## Post-hoc changes

- **D21 (post-hoc, diagnostic only; added after first run, before any systematic comparison file was written).** The first run gave crop values far from the paper's (e.g. Stellenbosch $183 vs $59.1; Massachusetts $38 vs $93.7) and Cape cattle per farmer 52 vs the text's 33. I did **not** change any primary definition. I added two diagnostic outputs, not in `results_r.csv`: `output/diag_A1_per_commodity_producer.csv` (Table A1 means among producers of each commodity rather than among all farmers) and `output/diag_crop_value_definitions.csv` (crop value per farmer vs per crop-producing household, and Cape crops valued at US prices). `text_numbers.csv` already carries the all-household cattle means (Cape 33.5, US 4.7) as alternatives under D17. These diagnostics help S4 locate the source of the gaps; they are outcome-informed and labelled as such.
- Implementation note: an intermediate (unused) code block in `01_clean.R` for D7 was removed before the first full run; D7 as written above is what the script does.
