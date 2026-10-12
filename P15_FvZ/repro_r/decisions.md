# P15_FvZ — S3 independent recreation: decisions log

Written 11 October 2026 before any of this recreation's numbers were computed or compared with the published targets. The recreation is **not outcome-blind**: I read `claims.csv`, so I saw Table A1 and the digitised Fig. 1/2/3/7 values while I was planning. I did not tune any choice to them. Any change made after a comparison is logged at the end under "Post-hoc changes".

## Independence label: **conditional**

Two inputs are taken from the paper's own published numbers, not from data:
1. **Khoesan population** (Fig. 1, digitised in `claims.csv` as `F1_*_khoesan`, every fifth year, linearly interpolated). The paper's source, the share of Khoesan among individuals in the Court of Justice records, is not available. All per-capita series depend on this input, so the `F1_*_khoesan` claims are reported as `unavailable` (they would be circular).
2. **The 1990 GK-dollar conversion factor.** The paper converts 1701 Cape guilders to Dutch guilders with the barebones PPP (Holland "less than 1%" above the Cape in 1701), then to 1990 $ "via the Dutch ratio between current prices of 1701 and international dollars of 1990" (Van Zanden & Van Leeuwen 2012). Neither the PPP series (De Zwart 2011; Allen et al. 2011) nor the Dutch nominal/1990$ ratio is available. I therefore fix one factor, $ per 1701 Cape guilder = A1_1701 / F3_1701_GDPpc = 1702.7 / 161 = 10.576, from two published numbers, and apply it to every year. **Every 1990$ level in this recreation therefore rests on that typed factor.** Only the time path and the guilder level are independent tests. The factor is not fitted to my own estimate: my 1701 dollar value equals 10.576 × my own 1701 guilder value, which is free to differ from 161.

Labour-force shares from the 1732 de la Fontaine census (60/11/29%) are also typed from the text (p.473), because the census is not available.

No original calculation workbook, code or log was opened. The raw `Data/Van Duin en Ross.xlsx` contains a few derived working sheets (`Sheet1`, `Wimpie`, `Exports`, `Sheet2`, and the ratio columns in "Meet supplied to the Company"). I read their headers while inspecting the file but **do not use them**. Only the transcribed VDR tables are used.

## Inputs used (all from the allow-list)

| Input | Source sheet | Years |
|---|---|---|
| Free population by men/women/boys/girls/knechts; slaves by men/women/boys/girls (opgaafrolle) | VDR `Population` | 1701–1795 (1781, 1794 NA) |
| VOC Company establishment | VDR `Company establishment` | 1701–1793 |
| Wheat, barley and rye sown and reaped; vines; wine leggers | VDR `Agricultural production` | 1701–1795 |
| Wheat correction coefficient (1.3 → 3.0) by 5-year period | VDR `Production or wheat` | 1709–1793 |
| Cape Town internal wheat market (= 2.5 mud × Cape Town population) | VDR `Consumption of wheat` | 1704–1793, 5-yr averages |
| Livestock: horses, cattle, sheep | VDR `Livestock in possession` | 1701–1795 |
| Meat pacht prices: sheep (stuivers) and pond meat (duiten) | VDR `Prices of meat supplied` | 1701–1793 |
| Wages: nominal and actual | VDR `The payment of wages` | 1711–1789 |
| Wissel transfers | VDR `Wissel transfers` | 1702–1793 |
| Gross receipts from VOC sales (imports) | VDR `Gross receipts` | 1748–1776 (gaps) |
| VOC exports by value (grains and pulses, wines, stock products) | VDR `Exports in money value` | 1749–1793 |
| Exports of grains, peas and beans (mud), wine (aam) | VDR export sheets | 1706–1793 |
| Number of ships: Dutch (`Gem dae per besoek`) and non-Dutch (`Totale skepe`) | Verwerk.xls | 1652–1795 |
| Slave median prices by period | Slave prices.xlsx | 1692–1795 |
| Shipdays.xls | read but not needed (ship counts are used; ship-days only for a check) | |

## Inputs NOT available, and what I did instead

| Paper input | Status | Replacement / choice |
|---|---|---|
| Shell (1994:444–447) slave totals (incl. Company slaves) | missing | opgaafrolle slaves (VDR, all ages) **plus a constant 600 Company (Lodge) slaves**. The 600 is my recollection of the order of magnitude of the Lodge population in Shell; it is not verified. |
| Khoesan participation (Court of Justice share) | missing | Digitised Fig. 1 (typed; see above). |
| Van Duin & Ross wheat prices | not in file | Implied VOC export valuation per mud = value of grains & pulses exported / (grain + pea & bean mudden), 1749–1793. VDR state that 1749–53 and 1784–93 are valued at 1753–4 and early-1780s prices. Years without exports take the neighbouring price. **Before 1749 the price is held at the 1749–53 level.** So the wheat price only varies 1754–1783. |
| Wine farm-gate prices from inventories (Fourie 2012) | missing | VOC export valuation per legger = value of wines / aam exported × 3.75 aam per legger (1 legger ≈ 582 L per the paper's 0.38 legger = 221 L; 1 aam ≈ 155 L). Held constant before 1749. |
| Meat prices "as received by farmers" | partly | Farmer price per lb = sheep price (stuivers) / 16 stuivers per guilder / 42 lb per sheep. It is applied to both mutton and beef. The "pond meat" pacht price is a delivery-contract price and is not used. |
| De Zwart (2011) CPI and subsistence / barebones basket | missing | **Proxy subsistence basket per person per year** = (2.0 mud wheat × p_wheat + 20 lb meat × p_meat) / 0.70 (food assumed 70% of a barebones budget). It is used for: (a) VOC income in kind; (b) subsistence of slaves and Khoesan in the Europeans-only series (at 1701 prices); (c) the CPI proxy (index of this basket, 1701 = 1). |
| PPP series (Fig. 6) and Dutch/British GDP | missing | See the conversion factor above. Holland and GB series (`F7_*_Holland`, `F7_*_GB`, TXT_p478_a, e–h) are `unavailable`. |
| Opgaaf/inventory livestock correction (Fourie 2012) | missing | **k_livestock = 1.5** (assumption) applied to cattle, sheep and horses, for both meat output and capital formation. |
| VDR 1780 and 1790 meat consumption benchmarks | missing | The consumption series = c × total population + s × ships, with s = 5,000 lb per ship (assumption). c is chosen so that the consumption series equals my livestock-based series on average in 1780 and 1790 (i.e. my own livestock series stands in for VDR's benchmark). |
| Livestock slaughter (offtake) rates | not stated in paper | sheep 25% per year, cattle 10% per year (assumption). |
| Butter output and price | price missing | **Butter excluded** (the paper calls it small). |
| Barrow's vine investment cost | missing | 0.03 guilders per vine, constant (assumption). |
| Horse value | not stated | 4 × the value of a cow (300 lb × meat price). |
| Lease applications from 1712 (construction) | missing | Construction = 400 guilders × positive change in Cape Town population + 1,000 guilders × positive change in free adult men (proxy for new farms). Both coefficients are assumptions. |
| Cape Town population | not given directly | Derived from VDR "internal market" wheat consumption / 2.5 mud (VDR footnote), assigned to the period midpoints (1706, 1711, …, 1791) and linearly interpolated. Outside 1706–1791 the 1706 or 1791 share of total population is held constant. |
| Consumer price of wine (De Zwart) for the retail margin | missing | Consumer price assumed = 2 × farm-gate price, so margin per legger = farm-gate price. City consumption = 0.38 legger × Cape Town population. |
| Slave-trade margin | not stated | Imports = max(0, Δ opgaaf slaves); value added = 20% of import value at the median slave price. Prices in Slave prices.xlsx are assumed to be in Rixdollars at 3 guilders per Rds. |
| VOC craftsman wage | missing | Average VOC nominal wage per employee (wage bill / establishment) plus the subsistence basket (income in kind). |
| 1732 labour structure | census missing | Typed shares: industry 11%, tertiary 29%, of which VOC "more than half" → 15% VOC, so **25% of the labour force is in non-VOC industry and services**, held constant over time ("if we assume a stable structure of the labour force", p.474). |

## Ambiguities in the description and the choice made

1. **Currency units.** Fn 5 ("Twenty guilders were equal to one Rijksdaalder at the Cape, while 16 guilders equalled a Rijksdaalder in Holland") is garbled. The VDR note says Cape light money has 1 Rds = 3 guilders and 1 guilder = 16 stuivers. **Choice:** 16 stuivers = 1 Cape guilder, 8 duiten = 1 stuiver, 3 guilders = 1 Rds.
2. **Population groups.** "Europeans" = all free persons in the opgaafrolle (men, women, boys, girls, knechts) **plus the VOC establishment**. Slaves = opgaaf slaves (all ages) + 600 Lodge slaves. Khoesan = Fig. 1. Total = sum. Missing years 1781 and 1794 are interpolated linearly. For 1795 slave children, the 1793 child share is used.
3. **Typos in VDR transcription.** Rule set before looking at results: a value of a population or livestock column that deviates by more than 40% from the centred 5-year median of the original series is replaced by that median. Each replacement is logged to `output/outlier_fixes.csv` (6 fixes: sheep 1705 = 7,642, almost certainly 76,420; boys 1766 = 3,034; slave children 1715 and 1767; cattle 1779). *Pre-results revision:* the first version used the mean of the two neighbours applied sequentially. That version wrongly "fixed" sheep 1704 because its neighbour (1705) was the typo, so I replaced it before computing any GDP number. Girls 1785 (2,148, deviation 30%) is not flagged and is kept.
4. **Wheat series (i).** "Net wheat output" = correction coefficient × (reaped − sown) for wheat + barley + rye (seed is netted out). The coefficient for 1701–1708 takes the 1709–13 value (1.3). 1781 and 1794 output is interpolated.
5. **Wheat series (ii) (demand).** Adults × 2.5 + children × 1.25 + 40 × ships + grain exports. Adults: free men, women and knechts; adult slaves; the VOC establishment; Lodge slaves; and 60% of Khoesan (assumed adult share). Children: boys, girls and slave children, plus 40% of Khoesan. Ships = Dutch + non-Dutch arrivals. Seed is not added, so the series is consistent with net output.
6. **Rural wine consumption.** 0.30 legger per capita applies to **all** rural inhabitants (total population − Cape Town population), including slaves and Khoesan, read literally as "per capita". Total wine = VDR leggers + rural consumption.
7. **Meat.** The average of the livestock series and the consumption series (see the table above). Mutton and beef are valued at the same farmer price per lb.
8. **Agricultural capital formation.** Δ(k × cattle) × 300 lb × p_meat + Δ(k × sheep) × sheep price + Δ(k × horses) × 4 × cow value + Δ(corrected sown area, mud) × 2 × p_wheat + Δvines × 0.03. Net changes can be negative. Missing horse years 1778–1794 are interpolated between 1777 and 1795.
9. **VOC sector.** (i) the nominal wage bill (12 × monthly bill, the "Normal" column). Missing years are filled by interpolating the wage per employee and multiplying by the establishment; outside 1711–1789 the nearest per-employee wage is used. (ii) Income in kind = subsistence basket × (establishment + Lodge slaves). (iii) 50% of wissels (1701 = 1702 value; 1703 and 1722 interpolated). (iv) 10% × (imports + exports). Imports = gross receipts from VOC sales; outside the observed years, receipts per head of total population are held at their 1748–1776 average. Exports: VDR money value 1749–1793; before 1749, grain exports × wheat price.
10. **Rest of the economy.** The sum of: slave-trade margin; wine retail margin; 10% × domestic consumption of wheat and meat (population demand, excluding ships and exports); construction proxy; and craftsmen incomes (25% of the labour force × craftsman income). Labour force = free adult men + knechts + adult slaves + VOC establishment + Lodge slaves + 60% of Khoesan. **There may be double counting** between craftsmen and the bakers/construction items. I keep it because the paper lists them all.
11. **Deflator.** P_ag = Laspeyres index of wheat, wine and meat prices with 1701 quantity weights. "CPI" = the subsistence basket index. GDP deflator_t = s_ag,t × P_ag,t + (1 − s_ag,t) × CPI_t, where s_ag,t is agriculture's share of nominal GDP in year t. 1701 = 1. "Base year 1701 = 10" is read as an index normalisation and does not matter for levels.
12. **Per-capita series.** GDP pc = real GDP / total population. Europeans only = (real GDP − subsistence_1701 × (slaves + Khoesan)) / Europeans. Balanced = real GDP / (adult men / 0.30). Adult men = free men + knechts + adult male slaves + VOC establishment + 60% of Lodge slaves + 30% of Khoesan.
13. **Period.** GDP is computed for 1701–1793 (wages, wissels and the establishment end in 1793; Table A1 ends in 1793). Population runs 1701–1795.
14. **Trend growth "estimated as a fitted regression line".** OLS of ln(real GDP) on year over 1701–1793, and of ln(population) on year over 1701–1795. Growth = 100 × slope.
15. **"Balanced" ratio, first and second half.** Mean of balanced/actual population over 1701–1750 and 1751–1795.
16. **Text population shares (40% / 10%).** Mean over 1701–1795 of the annual group shares.
17. **Range "between $600 and $1,000".** Reported as the min and max of my annual balanced series in 1990 $, 1701–1793.
18. **Fig. 2 sectors.** Agriculture = wheat + wine + meat + agricultural capital formation; VOC = items (i)–(iv); secondary and tertiary = rest of the economy.
19. **Urban wine consumption per capita, 1748–1795 (TXT_p487_d).** Recomputed as (VDR leggers − wine exports in leggers) / Cape Town population, averaged over 1748–1793. This is only a consistency check of the inputs.

## Claims not attempted or unavailable
- All `A1_*_sa` and Cape values after 1800 (the 19th-century and 20th-century links): inputs unavailable.
- `F7_*_Holland`, `F7_*_GB`, TXT_p478_a, e–h: unavailable.
- `F1_*_khoesan`: unavailable (it is an input).
- TXT_p473_a–c (labour shares): they are inputs typed from the text, so not tested.
- Historical text counts for 1652–1700 (TXT_p481_*) and fixed assumptions (TXT_p487_a–c, f; p488; p489): these are inputs, not results, so they are not mapped.

## Implementation details fixed in code before any comparison (added to this log afterwards for completeness)
- Grain exports are 0 for 1701–1705 (the VDR series starts in 1706). Years marked "N.A." (1735, 1736, 1738) are interpolated.
- First-differences (investment, slave imports, construction) use the forward difference for 1701.
- Gross VOC receipts: interior gaps (1762, 1770, 1774) are interpolated. Outside 1748–1776, mean receipts per head × total population is used.
- The meat consumption benchmark constant comes out at c = 266.8 lb per head per year.

## Post-hoc changes
None. After the scripts were finished I made one summary comparison with claims.csv, for the report only (medians of the recreated/published ratios). No parameter or choice was changed afterwards.

Observations from that comparison, for the S4 agent (not acted on):
- My population is about 11–13% below Fig. 1. In 1701 my total is 3,356 against the paper's "about 4,500". The gap points to Shell's slave totals and a larger European count than the opgaaf free population + VOC establishment.
- My adult share of opgaaf slaves is 85–89%, against the paper's 65–70%. The paper's figure presumably uses Shell's age structure, which is not available here.
- My nominal GDP is about 1.2× the paper's, driven by "rest of the economy" (about 1.7×; the craftsmen item plus possible double counting). My real GDP per capita is about 1.2× higher in level, but its proportional decline 1701→1793 (−43%) is similar.
