# P03_BoF17 S3 decisions (written before any systematic comparison with reported values)

**Independence level: conditional.** Table 1 and Table 2 use the raw sheet only (`AgrPriceData 1.3.xlsx`, 'South Africa_original'; full independence for these). The annual SA wheat series (Figure 2, TXT_corr_*) comes from the sheet 'RSA wheat price data (logged)' of the Nov 2015 `Globalisation data.xlsx`, which is a pre-processed (logged, De Zwart-derived) series, so those claims are conditional. UK series built from 'Original 102 cities data'. `core.dta` was inspected but not used (it has no wheat or beef, only Butter/Eggs/Mealies/Mutton/Potatoes). The cleaned sheet 'SouthAfricacleaned' was not used. The deny-listed worksheets were not read.

## Choices
1. **File location.** `AgrPriceData 1.3.xlsx` is not in the 'Boshoff Fourie Globalisation' tree. I used `original/Boshoff Fourie/AgrPriceData 1.3.xlsx` (Jun 2013, 19 sheets); a smaller Feb 2013 copy sits in `Macro/` and was not used.
2. **Raw parsing.** Each issue has £, s, d columns (+ 'final'); price = 240£+12s+d pence, recomputed (the 'final' column ignored). '.' = missing; zero = missing. Month taken from the 'Date collected' text, year from row 3; duplicate issues in one year-month averaged. 201 issues parsed, 45,738 price observations.
3. **Table 1.** Monthly grid Jan 1897–Dec 1906 (120 months). Log first difference only between consecutive months (no differencing across gaps). Correlation with Cape Town for the same product. Reported SE = conventional sqrt((1-r²)/(n-2)) (matches the magnitude of the paper's brackets, ~1/sqrt(n)); Fisher-z SE also in output/table1_recreated.csv. No robust/clustered SE: a single bivariate correlation, none stated. Town-name mapping: Burgersdorp=Burghersdorp, Grahamstown=Graham's Town, Queenstown=Queen's Town.
4. **Table 2 (PSS bounds).** Lag order, deterministics, dependent variable and sample are unstated. Choice: dependent variable = town log price, regressor = Cape Town log price, unrestricted intercept, no trend (Case III), complete-case rows on the 1897–1906 monthly grid, **one lag of differences of each variable (primary; reported in results_r.csv)**. F-statistics for 0, 2 and 3 lags are in output/table2_recreated.csv; the F values are very sensitive to this choice, so Table 2 is a weak test of the claims. SE column is empty (F-statistic). Critical values were not computed (Narayan 2005 table not available offline).
5. **Annual correlations (TXT_corr_*).** Both series logged, in levels (as Figure 2 suggests). SA = column 'Cape and Natal (RSA)' (alt: 'Cape Colony', in sensitivity file). UK = log of equal-weight mean of the 12 city annual means (alt: mean of logs). Annual city means are the mean of available months. Years 1836–1913 (77 complete years). SE conventional; significance not adjusted for serial correlation or trends. First-difference correlations are reported in output/text_corr_sensitivity.csv as an extra.
6. **TXT_breakyear.** The paper picks 1872 by inspection with no formal test. My value is an exploratory scan (split year 1855–1895 maximising post-minus-pre correlation, ≥15 obs per side); it is not a replication of a procedure in the paper.
7. **TXT_ukcities / TXT_cycle_lo / TXT_cycle_hi.** Recorded as the design parameters I implemented (12 cities verified by name in 01_clean.R; Christiano–Fitzgerald asymmetric filter, 8–50 years, `mFilter::cffilter`, root=TRUE, drift=TRUE). Not independent outcomes.
8. **Figures.** Figure 2 and Figure 3 recreated (output/fig2_*, fig3_*); Figure 4 not recreated (no description in the allowed inputs).

## Unavailable (status_override = unavailable)
- TXT_diamond_exports (1872 exports > £1m): needs trade data (Trade.xlsx not on the allow-list).
- TXT_other_countries_break (1875): method not described; not attempted.
- TXT_telegraph_london (1885): historical fact, not data-derived.
- TXT_pss_towns (5): a count in the text that does not map to a computed quantity (Table 2 has 4 towns).
- TXT_pss_crit_lo/hi (4.29, 5.08): Narayan (2005) critical values, not computed.
- Table 1 cells with fewer than 4 usable differences (if any) are blank and marked unavailable.

## Post-hoc changes
None so far.
