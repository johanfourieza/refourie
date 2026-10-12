# P20_HLF S3 recreation: decisions

**Independence level: conditional.** The analysis workbook and the carting-price sample were not recovered, and the 1905 Report of the General Manager (42.6 MB scan) was not read in this run. The social-saving arithmetic is therefore an **arithmetic re-derivation from the inputs the paper itself prints** (ton-miles, fares and rates, speeds, wage values, elasticities, capital, net revenues, labour-productivity totals). It tests the paper's internal arithmetic and the stated formulas. It does not test the underlying data. The only file-based recreation is T1 per-1,000-population (1911 census xlsx).

Run: `Rscript P20_HLF/repro_r/02_analysis.R` (sources `01_clean.R`), then `03_figures.R`. Output: `results_r.csv` (249 claim ids, 78 computed, 171 `unavailable`), `output/`. The paper reports no SEs. For the road-cost fit (n = 7) I give conventional OLS SEs in `se`, with HC3 SEs in `output/road_fit.csv`.

## Ambiguities and choices (made before any systematic comparison unless marked POST-HOC)

1. **Chain of rounding.** Each cell is recomputed from the printed, rounded upstream inputs in the same table (e.g. c = 361.03 × 0.0065). The result differs slightly from the printed cell, which was computed from unrounded prices (T3 SS 5.018 vs 5.042).
2. **GDP 1905 is not printed.** I use GDP = printed SS 5.042 / printed 12.01% = £41.98m. This is circular for T3_pct and T4_r1_c1, so those are not independent checks. They enter the other %-of-GDP rows as a conditional input.
3. **Primary-source inputs.** The 1905 traffic and revenue figures (T3 a, b, d, e; T5 a, b, d, e, i, k; T7 a, e, f; T8 b, d, e, g) are taken as printed. They are not recreated, so the claim rows that merely echo them are `unavailable`.
4. **Road-price function.** Seven printed observations (distances 100, 250 and 300 miles from the text "about N miles"; 80, 30, 54 and 155 miles). The fit is `price ~ log(distance)` by OLS, evaluated at 197 miles. The fit gives 0.0213, against the paper's 0.020. The paper's sample (158 stagecoach rates, wider carting data) is unavailable, so this is not a replication of Fig. 5.
5. **29d per 100 lb (TX_p9_pe).** Converted with a long ton (2,240 lb) and 240d per £, with no CPI deflator (Verhoef et al. CPI not available): 0.0338 against 0.033 printed.
6. **Table 5 time values.** Row l uses h/k × 0.5. For 2nd/3rd class, j = 0 so n = −c, as the paper does.
7. **Elasticity ratio (fn 17).** The Greek symbols were lost in the text layer, so I use the Fogel/Leunig form (φ^(1−ε) − 1) / ((1−ε)(φ−1)), with the ε = 1 limit ln φ / (φ−1). Freight φ = 0.0204/0.0065 (price ratio). **Low = ε 0.8, high = ε 0.5**: the text calls the range "−0.5 to −0.8", so "low scenario" is ε = 0.8.
8. **POST-HOC (after reading the printed T6/T8 values in claims.csv).** (a) The first-class φ is the full-price ratio (road fare + time) / (rail fare + time) = 4.47. The garbled fn 17 does not say which ratio applies. With the fare-only ratio (5.0) the result would be 0.72 rather than 0.774. (b) The T8 pairing of bounds is low = low CS + high-depreciation loss, and high = high CS + low-depreciation loss. This is the pairing that reproduces the printed 3.922 / 4.623. Pairing the low CS with the low-depreciation loss would give 4.01. Both choices were made by checking against the printed values, so they carry no independent evidential weight.
9. **T8 capital contribution.** f = 4.06 × 3.84% = 0.156, h = f/g = 7.05 (printed 7.04). I use printed d, e and g. They need the Verhoef et al. GDP series and the capital series, which are not on the allow-list.
10. **Unavailable (inputs not on the allow-list or not recovered):**
    - T1 km and per-area columns, and the other countries (area figures and Mitchell not available).
    - T2 (1908 report).
    - T4 rows other than Cape.
    - All text claims on the network, on the GDP series and on traffic by district (TX_p22/p23), and the interest and PV series (TX_p18/p19: net-operating-revenue series and debt-interest series).
    - Citations from other papers (Ghana 27%, Latin America 2–4.4%, etc.) and the fn 15 counterfactuals.
    - Assumed parameters (elasticities, 3.7%, 1.7/2%, 4% discount rate).
    - Construction cost per mile (the mileage series was not available).
    - T8 b, d, e, g.
11. **Files inspected but not used for a claim.** `Rail Transport Rates (finaal).xlsx` holds rates by station and class (pence per 100 lb). It cannot be tied to T3_b or the average haul without the weights. `Rail network history.xlsx` holds only line completion dates. Neither maps to a claim row.
12. **Census population.** The Cape and Union totals are sums of the age-group cells (rows 12 and 9, columns 4–59): Cape 2,564,965 and Union 5,973,394. T1 per-1,000 values are 2.19 and 2.10, which match the printed ones. The area columns would need the implied areas, which are not independent.
13. **Figures** use a plain ggplot theme, not /leapstyle (not on the allow-list).

## Post-hoc change log
- None beyond items 8(a) and 8(b), which were made before the final run.
