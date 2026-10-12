# P30_STB24 — S3 independent recreation: decisions

**Independence level: full.** The recreation starts from `stellenbosch_panel_raw.xlsx` (the raw transcription, one sheet per census year, original Dutch/English headers, unharmonised), extracted from `cape_panel_raw_data_processing-main.zip`. No code, notebook, cleaned file (`stellenbosch_clean.xlsx` was not opened), figure folder or manuscript was read. Harmonisation, cleaning and analysis are my own, built from the paper's text (pp. 428–443).

**Not outcome-blind.** I saw `claims.csv` (published and digitised values) before writing the scripts. While checking the header mapping, I also saw per-census means and noticed that the horses index for 1685 (0.34/4.75 = 0.07) matched the digitised value. I changed no specification in response to that. Every choice below was fixed before `02_analysis.R` was first run and before any systematic comparison.

## Data and harmonisation (01_clean.R)

1. **Census universe.** The raw workbook has 143 year sheets (1685–1844), not 144. The paper's source list includes 1747 (VOC 4169), which has no sheet. I use all 143 sheets.
2. **Household rows.** A row is a household if column 1 holds a row number, or if the man's or woman's name column is non-empty. FOLIO, NB, total and transport rows are excluded. Sheet 1800 has no row numbers and is identified by names alone.
3. **Header mapping.** Each column's label is its bottom header cell, with the forward-filled top header as context. Columns are mapped to about 30 harmonised variables by explicit rules (`classify()`), and the full map is in `output/column_map.csv`. I did not attempt the paper's 168-column harmonisation. Special cases:
   - Pre-1804 grain columns come in (sown, reaped) pairs. A reaped column takes the crop of the sown column to its left. This fixes 1738, where the reaped-wheat column carries a "Rogge" top label.
   - In 1823 the "gewonnen" top label is missing, so the second occurrence of each crop label is treated as reaped.
   - Single-row headers (1790–1798) and free-text note rows are handled explicitly.
4. **Asset definitions.** All are household totals across sub-columns:
   - horses: all horse columns (riding/draught + breeding; 1830–34 "horses & mules" columns, excluding tax amounts);
   - cattle: oxen + cows + heifers + calves (1685–1716), then runderen/rundervee, trekossen + aanteel, hoornvee or cattle;
   - sheep: schapen, or hamels + aanteel + wolgevende/Spanish. In 1830–34 the category is "sheep, goats or pigs", and in 1839 "schapen en bokken"; both are taken as published;
   - wheat and barley: muids reaped (tarwe/koorn and garst). In 1830–34 only combined grain is recorded, so wheat and barley are missing there;
   - wine: leaguers of wine (vines and brandy excluded).
5. **Number parsing.** Unicode fractions (½, ¼, ¾, …) and "a b/c" are converted to decimals, and other characters are stripped. A cell with no digit counts as missing.
6. **Missing-data rule (paper p.434–435).** A variable with no entry in a census is not recorded (NA) for that census. If it has at least one entry, blanks in that census are set to zero.
7. **Enslaved people.** Pre-1804: slaven = men, slavinnen = women, jongetjes/jongens = boys, meisjes = girls. From 1804: men/boys split at 16, women/girls at 14 (20 in 1826–29 and 1835–37), as recorded. 1685/1689 record unsexed slave children, which are kept separately and excluded from the boys/girls panels. Apprentices labelled only as apprentices (1838 onwards) are excluded. Enslaved people are not recorded in 1830–34.

## Analysis (02_analysis.R)

8. **TX_rows / TX_censuses / F5_nobs.** These are counts of household rows (total and per census) under rule 2.
9. **Figure 5.** For each census, the mean per household (all household rows, zeros included per rule 6) is divided by its 1795 mean, and the series is plotted on a log scale. There is no deflation, trimming or smoothing, because the paper uses the log scale "to reduce the effects of outliers". Sensitivity, not used for results: wine entries above 1,000 leaguers set to missing. These are vine counts entered in the wine column, e.g. 60,000 in 1766.
10. **Figure 6.** The Gini is computed across all household rows of a census with zeros included (rule 6), using `ineq::Gini` without a small-sample correction. Sensitivity: positive values only. A descriptive OLS trend of Gini on year per asset is reported with conventional and HC1 SEs (`output/gini_trend.csv`). The paper reports no SEs, so `se` in results_r.csv is blank.
11. **Digitised anchor years without a census** (e.g. 1783, 1815): linear interpolation between adjacent censuses, mirroring a line plot.
12. **TX_gini_lo / TX_gini_hi.** The text says Ginis range "between 0.4 and 1 ... for most of the period". I operationalise the lower bound as the 10th percentile of all asset-year Ginis pooled, and the upper bound as their maximum. The share of asset-years in [0.4, 1] is in `output/diagnostics.csv`.
13. **TX_wineGini_peak.** This is the decade of the maximum of the centred 11-census rolling mean of the wine Gini.
14. **TX_break1804.** This is the census with the largest number of harmonised variables entering or leaving the recorded set relative to the previous census. It is coarser than the paper's 168 columns.
15. **Figure 3, surnames.** The household surname is taken from the man's name column, or from the woman's column if that is empty. With a comma ("Surname, Given") it is the text before the comma. Without one it is the last token plus preceding particles (de, du, le, van, der, …). Surnames are matched on spelling with case, spaces and punctuation removed, so "VanderMerwe" = "Van der Merwe"; there is no further standardisation (paper fn 64). Decades run 1700–1830, with 1830 covering 1830–39. Share = households with the surname / households with a surname in the decade × 100 (the axis label "percentage of all surnames"). The within-top-12 share is also written (`share_top12`) because of claims-spec inconsistency 2, but `share_all` is the primary value. The twelve surnames are those named in the text; a data-driven top 12 is also reported.
16. **TX_DV_rise.** This is the first decade of the uninterrupted rise in the De Villiers share up to its peak.
17. **Figure 4.** Marriage pairs are the husband's surname × the wife's surname (wife's name in "Surname, Given" form), 1700–1839. Each distinct couple (full names) is counted once, not once per census year. The top 100 surname pairs are plotted. Endogamy shares for De Villiers and Du Toit go in `output/fig4_endogamy_DV_DT.csv`.
18. **Louis Fourie (TX_fourie_*).** Search men's names 1695–1760 for given name "Lou…" with a surname matching F+(l|a|o|ou|au)r / faur / four / floru. First year, last year, the year from which all later entries read "Louis Fourie" or "Fourie, Louis", and the number of matched census entries strictly between the first appearance and that year.
19. **Figure 7.** Censuses up to 1838 are grouped into two-decade bins starting 1680 (1820 = 1820–38). For each type: the distribution of counts per household, with share zero, share >1, mean and p90.
20. **Not attempted:** TX_volumes (volume metadata are not in the census sheets); TX_vars and TX_cols50 (the 168-column harmonisation was not reproduced); TX_fn31_drop20, TX_top12 and TX_pairs100 (design parameters adopted by construction, not results); TX_shift_lo/hi, TX_frag1830, TX_const1750 and TX_var3dec (qualitative readings of figures with no operational definition).

## Post-hoc changes

1. **Louis Fourie search pattern (TX_fourie_1700, _17, _1750).** The pre-registered regex in rule 18 required a surname beginning F+(l|a|o|ou|au)r. Its output showed no entries between 1700 and 1718, an obvious matching failure: the names are recorded as "Fleuri", "Florie", "Floury" and so on. I broadened it to: given name Lou*/Ludovicus, family name beginning (f|v) followed by a vowel or l, excluding Verbrugge/Verburgh and "Van …". This was changed after seeing the matched rows, but before any comparison with claims.csv. Result: the first entry is 1689 ("Louis Faurit"), with further entries in 1692, 1693, 1696 and 1698, before "Louwis Floru" in 1700. The last entry is 1750.
2. **TX_fourie_1718.** Under the pre-registered definition (the first year from which every later entry is spelt exactly "Louis Fourie"), there is no such year: 23 later census years carry variants such as "Fouri" or "Fouris". I report instead the first year spelt exactly "Louis Fourie", which is 1718. TX_fourie_17 is the number of census years with an entry strictly between the paper's own anchor of 1700 and 1718, which is 15. Anchoring on 1700 rather than my first-appearance year of 1689 follows the claim's wording. Both choices are post-hoc and are flagged here.
3. **Coding fixes during development (before the first analysis run).** These were found by inspecting the column map, not results:
   - folio-row detection ("Folio Nr." headers in 1790–98);
   - note-row removal;
   - the 1738 and 1823 grain fixes;
   - the 1823 "trek & ryd" horses;
   - "calvers" (1691) as cattle;
   - 1841–44 owner-name columns.

## Observations for S4 (not used to tune anything)

- Household rows total 142,592 against the published 142,297 (+0.2%). There are 143 censuses against the published 144.
- The data-driven top 12 surnames match the paper's list in 11 of 12 cases: Bosman replaces Swart.
- Every asset-year Gini lies in [0.4, 1] in this recreation (p10 = 0.71). The digitised cattle values of about 0.34 are not reproduced.
- The 1795 base for barley is tiny (mean 0.04 muids per household), so the barley index sits at about 10–500 for most years. This is consistent with claims-spec inconsistency 3.
- The coarse structural-break metric (rule 14) picks 1835, where horses and cattle are absent from the transcription, not 1804. Under rule 14, 1804 has smaller harmonised changes.
- De Villiers endogamy is 25% of couples against 11% for Du Toit, which supports the p.438 qualitative claim.

