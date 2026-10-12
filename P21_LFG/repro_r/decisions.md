# P21_LFG S3 recreation: decisions

**Independence level: CONDITIONAL.** The analysis file is the authors' `Calumet Links/processed.dta` (42,180 rows, 106 vars), which already contains the linkage, probate prices (`Pricesheep`, `Pricecattle`) and valued output (`Tot_prodfl` = stock value x 6%). I did not rebuild it from `FGvF 15 Oct.xlsx`, `Graaff Reinet 15 Oct.xlsx`, `mtchseries.csv.zip` or the MOOC8 price files (turn budget). Table 1 and counts therefore test the file's internal consistency, not the raw-to-analysis pipeline. Translog, HEC, quintiles, 1814 and owner counts are my own code.

## Choices made before comparison
1. **Sample.** processed.dta spans 1787-1828 (35 years). Table 1 and the 42,180 total use all years (the pooled means match to 2 dp), although the paper labels them 1805-1828. Annual regressions use 1805-1828 (22 years, 1808 and 1827 absent).
2. **Missing inputs.** `khoe` is NA for 7,671 rows (outside the khoe-recorded years); Table 1 drops NAs by variable, and regressions drop rows with missing inputs or output <= 0.
3. **Log transform.** ln(1+x) for khoe, slaves and settlers, because zeros are common (paper silent). Output = ln(Tot_prodfl), dropping Q <= 0.
4. **Translog.** Linear terms, 0.5*squares and cross-products by OLS per year; M_i = b_i + sum_j b_ij lnX_j; HEC_ij = (b_ij + M_i M_j)/(M_i M_j) per household, F = `settlers` (family labour), K = `khoe`, S = `slaves`. Conventional OLS only; no SEs are used because the claims are boxplot centres.
5. **Summary statistic.** Fig. centres are taken as the **median** of household HEC in each year. F7_all/F8_all = median over 1805-1828 of annual medians. F9_1812_1817 = median of annual medians 1811-1817.
6. **Five-year moving average.** Ambiguous. Primary (in results_r.csv) = plain annual regressions, since the stated per-year N (921, 1669) equals the single-year row count. A secondary variant (`ma5_window`: regression on years t-2..t+2 with year dummies, HEC evaluated for year-t households) is in `output/hec_summary_by_year.csv` and `*_ma5.*` figures. Variant medians: HEC_SK 1821 = 0.147, 1823 = 0.021, 1828 = 0.271, 1811-17 about 0.85-1.0; HEC_FS 1805 = 0.50, rising to 2.3-2.9 in the 1820s.
7. **Quintiles (Fig 4/5 text).** ntile of `livestock` over all pooled rows.
8. **1814 sample.** Households (variable `index`) observed in some year < 1814 and some year > 1814: 7,680 rows vs paper's 8,639. The paper's exact definition is unknown.
9. **Names.** Van der Walt = lastnamemen contains WALT and first name ANDRIES (1820); Van Heerden = CAREL (1826).

## Results vs claims (not systematic comparison)
- Table 1 reproduces except cattle max 2,813 vs 2,831 printed (probable transposition in the paper). Sheep/slaves/khoe/family match.
- Total N 42,180, owners 11,456, 1814 declines 33.5/37.7/31.1%, obs min/max 921/1669 all match; mean per year 1,380 vs 1,379.
- Van Heerden 1826: 57 slaves in the data vs 61 in the text (61 is the file's slave max, held by someone else).
- Quintile means: slaves 0.18/2.97 (paper 0.2/3.2), khoe 0.29/10.3 (paper 0.4/10.2); quintile definition differs.
- **HEC.** Annual F7/F8/F9 pooled medians are positive (0.84, 0.85, 0.90 for 1811-17). But annual per-year medians for slaves-khoe turn negative in 1820-21, 1824-26 (1821 = -1.92 vs about 0.35 digitised), and family-slaves HEC rises to 2-3 after 1820, unlike the roughly flat 0.85 in Fig 7. The "complements throughout" result is not reproduced for slaves-khoe in unsmoothed annual regressions; the smoothed variant is closer to Fig 9 pattern in 1819-1824 (0.02-0.4) but dips negative in 1825-26.
- Figures are drawn with fixed y-limits (-3, 5), outside values excluded.

## Unavailable / not attempted
No claim is marked unavailable in the final file. Robustness Figs 10-16 and the raw-to-analysis rebuild were not attempted.

## Post-hoc changes
None after first results were seen.
