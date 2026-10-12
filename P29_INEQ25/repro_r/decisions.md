# P29_INEQ25 — S3 independent recreation: decisions

Written before the systematic comparison with the published values (pair B). The recreation agent had seen `claims.csv` (published and digitised values) before writing any code, as the protocol allows, so the recreation is **not outcome-blind**. No choice below was tuned to match a published value. Choices made after the first run are logged under "Post-hoc".

## Independence level

**conditional** (overall).
- Stellenbosch-Drakenstein series (Figs 1–2, top shares, slave-men Gini): only the cleaned, linked panel `stellenbosch_clean_april2025.xlsx` was available. Its variable harmonisation is shared with the original pipeline, so this block is *conditional*.
- The c.1825 cross-section (`1825 series.xlsx`), the Khoe settlement workbooks (`Groenekloof.xlsx`, `Swartrivier.xlsx`, `EBTstation.xlsx`), `MOOC_probates.xlsx`, `Slave Emancipation Dataset.xlsx` and `price_series.xlsx` are transcriptions or compiled source data, and the R code reads them independently. These blocks are close to *full*. `price_series.xlsx` is itself an aggregated product (decade prices from MOOC10) whose construction is not visible.
- No script, notebook, `opgaaf.xlsx`, pipeline zip, `Fourie_Inequality/` file, `repro_original/`, `compare/` or `audit.md` was opened. Directory listings of `original/2024F_Inequality/` showed file names only, including names such as "Data management and augmentation.pdf" and "Code for inequality paper.docx". These were **not** opened.
- **Bethelsdorp file.** No file named after Bethelsdorp exists. A search for Khoe-settlement names found only `Groenekloof.xlsx` and `Swartrivier.xlsx`. `EBTstation.xlsx` (not named in the allow-list) was opened for its sheet names and header row only, to establish whether it is a Khoe settlement workbook. It is: it holds the Bethelsdorp/Enon/Theopolis station returns, and its `Bethelsdorp` sheet has 425 rows, which matches the paper's 1814 count. It was then used as the Bethelsdorp source. It contains derived columns (`value`, `valueprobateprice`, …), and these were **not** used. The coordinator should confirm this file is within scope.

## Gini and inference

- G1. Gini = standard sample Gini (no small-sample correction) on non-negative holdings. **Zeros (households without the asset) are included** in every single-asset Gini. The paper does not state its treatment of zeros. This is the reading under which "Gini of horses among households" is a distributional statement about households. It is checked against `ineq::Gini` where installed.
- G2. Bootstrap SEs: households resampled with replacement within each cell (year, district, decade, settlement), B = 200, seed 20251126. For period averages of annual Ginis, the SE is the SD across replicates of the average of independent per-year replicates. The paper reports no SEs, so these are a by-product only.

## Stellenbosch-Drakenstein opgaaf (Figs 1–2, text pp.4–5)

- D1. Sample: all 142,293 rows of the cleaned panel, all 143 census years 1685–1844. Every row is treated as a household. There is no Khoe-household identifier, so no Khoe exclusion is applied beyond what the cleaned file already does (paper says Khoe excluded). The paper's 142,219 / 159 censuses cannot be matched exactly (see results).
- D2. Blank = zero within any year in which the component is recorded for at least one household. A component that is never recorded in a year is missing for that year, and the asset's Gini for that year is not computed.
- D3. Assets are sums of the sub-category columns. Horses = horses + work + riding + breeding + pleasure. Cattle = "bull" (the generic cattle column 1715–1804 and 1835+) + breeding + work + cows + heifers + calves. Sheep = sheep + breeding + wool + wethers. Wheat = `wheat_vol` (reaped). Vines = `vines`. Wine = `wine`. Goats and the 1839 `sheep_goats` are excluded.
- D4. **Trimming** (the rule is not stated; "manually trimmed"): a component value greater than 10 times the year-specific 99th percentile of positive values is treated as a transcription error. It is set to missing, and the household is dropped from that asset's Gini and from the total-value Gini for that year. This trimmed 14 cells in all.
- D5. Prices: `price_series.xlsx` gives decade prices (1690–1830) in rix-dollars. Year *t* uses the price of decade floor(*t*/10)·10. Years 1685–89 use 1690, and 1840–44 use 1830 (the paper does not state the rule outside 1701–1825).
- D6. Component-specific prices where the series has them (cattle_bull, cattle_work, cattle_breeding, cows, heifers, calves; horse_breeding, sheep_breeding, sheep_wether), and otherwise the generic `horses`/`sheep` price. Wheat at `wheat_vol` (per muid), wine at `wine` (per legger).
- D7. **Vines have no price** in the series, so total value is the sum of five priced assets (horses, cattle, sheep, wheat, wine). This departs from the paper's "six basket assets", forced by the data.
- D8. Fig 1 nodes = mean of annual Ginis within decades (caption: "averaged"). Fig 2 = mean of annual Ginis within 20-year periods (1680 = 1680–99, …, 1820 = 1820–39). The settlers-only line of Fig 2 is therefore the same measure as Fig 1 total value, aggregated to 20 years.
- D9. Scenarios. (ii) slave assets: every enslaved person in the household (men, women, sons, daughters) is valued at 200 sheep × the decade sheep price and added to total value. (iii) every enslaved man (`slave_men`) becomes a separate zero-asset household. (iv) as (iii), but each holds 12 sheep × the decade sheep price (the annual in-kind payment, not capitalised). In (iii)–(iv), settler households carry total value without slave assets.
- D9b. Text mapping. "0.92 by the late eighteenth century" = scenario (iii) in the 1780 period. "0.89–0.91" = min/max of scenario (iv) over the 1700–1820 periods. "0.6–0.75 for the entire eighteenth century" = min/max of the decade nodes 1700–1790. Conclusion "> 0.6" = minimum decade node. "Not a single asset has a Gini of less than 0.5" / F1_min_asset = minimum annual single-asset Gini over all years. Slave-men "consistently exceeded 0.7" = minimum annual Gini of `slave_men` (years with any slaves recorded).
- D9c. Top shares: annual shares of total value held by the top 1%, 0.1% and 0.01%, interpolating fractional households along the ranking, then averaged. Whole period = 1685–1844. "Eighteenth century" = 1700–99. "Early nineteenth century" = 1800–30.
- D9d. Counts: first decade = 1685–94, last decade = 1835–44, average = mean households per census year.

## c.1825 districts (Fig 3)

- D10. Sheets and years as stated in the paper (1825; Clanwilliam and Worcester 1824; Cradock 1823). Columns were identified from each sheet's multi-row header. Horses = saddle/wagon + breeding. Oxen = draught oxen. Cattle = breeding cattle. Sheep = wethers + breeding + Spanish. Wheat = muids reaped. Wine = leggers made.
- D11. A household is a row whose first column is a register number. Following unnumbered rows (wives, sons, inmates; in Cape and Swellendam each listed person) are added to it. The archival footer is dropped. This gives 9,857 households against the paper's 10,420. Cape and Swellendam list many persons per numbered entry, and counting persons instead would overshoot.
- D12. Gini per district × asset over all households, zeros included. Albany wine is undefined (no production).

## Probates (Fig 4)

- D13. `MOOC_probates.xlsx` (not the .xls). Counts `*_nr` (blank = 0), years 1700–1839. Exactly 4,423 probates, which matches the paper. Decade = floor(year/10)·10. All probates in a decade enter, zeros included. No trimming (the paper says it was unnecessary).

## Slave emancipation (Fig 5)

- D14. Owner = district × owner surname × owner first names (case and whitespace normalised). Owner valuation = sum of slave valuations over valued slaves. Owner compensation = sum of the (owner-level) compensation entries.
- D15. Owners-only valuation Gini: owners with at least one valued slave. Owners-only compensation Gini: owners with a recorded compensation entry. A sensitivity treats unrecorded compensation as zero (`owners_comp_zeros` in the output). Clanwilliam and Swellendam valuation are undefined; these two districts are not plotted.
- D16. **13,033 non-owners** (stated in the paper, used as an input) are allocated across districts in proportion to 1825 households holding no slaves (`1825 series.xlsx`). Somerset, absent in 1825, takes a share of Graaff-Reinet's count in proportion to the two districts' 1834 owners. Non-owners enter both Ginis with zero. The paper does not state the source or distribution of the 13,033.

## Khoe settlements (Fig 6)

- D17. Bethelsdorp: `EBTstation.xlsx`, sheet `Bethelsdorp` (1814, 425 rows). Horses = horseM + horseF. **Oxen = cattleM, cattle = cattleF** (by analogy with the 1825 "draught oxen" / "breeding cattle" split). Sheep = sheep_goats. Wheat = wheat_reaped.
- D18. Swartrivier: `Swartrivier.xlsx` sheet Data (364 rows). Horses = wagon/saddle + breeding (the unnamed column of 60/120 values is ignored). Oxen. Cattle = breeding cattle. Sheep = wethers + breeding. Wheat = reaped. Groenekloof: `Groenekloof.xlsx` sheet 1825, with the same layout and household rule as the Cape district sheet.
- D19. "Khoe and settler households in Groenekloof, Swartrivier and Swellendam combined" = Groenekloof + Swartrivier Khoe households pooled with Swellendam 1825 settler households. "Horses, oxen and wheat all exceed 0.77" = minimum of the three.

## Not attempted

Literature benchmarks (pp.1–2, Alvaredo), MOOC10 volume count, and the 12-sheep/6% inputs (stated parameters, not results). The 13,033 non-owners and the 200-sheep value are inputs, flagged `input-from-paper`.

## Post-hoc (after the first run, informed by seeing results against published values)

The primary specification above was **not changed**, and `results_r.csv` holds the pre-specified choices only. The sensitivities below were added after the first run. They are written to `output/sensitivity_posthoc.csv` and are not in `results_r.csv`.

- P1. D4 trimming applied to the 1825 cross-section. It has no material effect. Uitenhage cattle and sheep stay at about 0.96–0.98 because the sheet holds implausible values (one household with 9,814,068 cattle, several with 50,000–85,000). The 10×p99 rule cannot catch these because the 99th percentile is itself contaminated. This is a source-transcription problem that the paper's manual trimming presumably removed. Uitenhage cattle, sheep and oxen in `results_r.csv` reflect it.
- P2. Cape and Swellendam with every named person-entry as a household (13,211 households in total, against 10,420 published). This raises the Swellendam Ginis towards the published values and overshoots Cape. The household unit for these two sheets remains ambiguous.
- P3. Fig 5 valuation Gini over **individual enslaved persons** rather than owners. The text ("reports the valuation of each enslaved individual … I calculated the Gini coefficient of both") supports this reading. The owners-only slave-level values match the published values for 8 of 9 districts to within 0.01. The pre-specified owner-level valuation does not (0.42–0.65 against 0.29–0.47). The pre-specified rule is kept in results, and the reading in P3 is flagged as probably the author's.
- P4. Bethelsdorp cattle = cattleM + cattleF (0.691). This does not change the result.
- P5. **Fig 4 cattle and horses look exchanged.** The recreated *horses* series matches the published *cattle* line within about 0.01 in every decade, and the recreated *cattle* series matches the published *horses* line. Sheep, ploughs and wagons match within 0.007. Under exchanged labels, published "cattle" corresponds to the `horse_nr` column of `MOOC_probates.xlsx`. Either the figure legend or the column names are swapped. This is listed as a probable labelling error for S4/S5, and the results are reported under the pre-specified (column-name) mapping.

Other observations, reported and not acted on:
- Panel size is 142,293 rows over 143 census years (paper: 142,219 over 159). The average of 995 households per year and the last-decade mean of 1,442 match, so "159" is probably a typo for 143.
- The Fig 2 "settlers only" line cannot be the Fig 1 total-value measure. The recreated Fig 1 matches published Fig 1 (most nodes within 0.03), but the same measure on 20-year periods is 0.66–0.81 against the published 0.73–0.92 (claims_spec inconsistency 2).
- The top-1% share averages 12.2% (paper: about 12%), but the 1800–30 average is 11.8% (paper: about 18%). Top 0.1% and 0.01% do not match.
