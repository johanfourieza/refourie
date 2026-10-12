# P17_FvFH S6: deviations from the frozen method card (v3, commit d240e89)

**D1. Weighting factor.** Card §3 writes w = m·wf_m + v·wf_v + s·wf_s + d·wf_d "as printed in Table 2". Table 2 prints only one burgher factor per year (burgher total: 0.928 for 1702, 0.937 for 1723, 0.993 for 1757). The primary therefore uses w = n × wf_burgher_total(year). Because one factor scales every burgher household in a year by the same amount, it cancels in every within-year statistic, and Δ, Δa and Δb are differences of within-year Ginis. Sensitivities S2 (n only), S3a (S3 factors) and S3b (factors re-estimated in each draw) therefore equal the primary by construction (S3b is reported with the primary draws). This was read from `claims/claims.csv` before any statistic was computed. Results did not inform it.

**D2. S4 household weight.** The card does not say how to weight household income. S4 uses y = A with one weight per household, wf(year), so each household counts once. Results did not inform this choice.

**D3. Bootstrap mechanics.** The card fixes `set.seed(20261012)` with R's default RNG, so the primary and second-seed bootstraps run serially rather than with `parLapply`/L'Ecuyer streams as the task brief suggested (8 s per 9,999 draws; full pipeline under 3 minutes). S16 (paired bootstrap) and S17 (clusters) resample units by multiplicity weights, which is exactly equivalent to row replication for the weighted Gini and the decomposition. In S16, rows are linked across rolls by exact `van + naam`: 2,609 ids, 258 of them linked across rolls. In S17 the clusters are `loc` within year (10/11/11). With 10–11 clusters, a 0.28% percentile tail is degenerate, so S17 intervals are indicative only. Results did not inform this.

**D4. Sensitivities without intervals.** The card asks for bootstraps only in S6, S12, S16 and S17. S1–S5, S7–S11 and S15 are reported as point estimates. S15 is trivial: none of the used counts has a missing value in 1700, 1723 or 1757. Results did not inform this.

**D5. S10 raw xls.** The xls names the barley column `GGW` (`cgw` in the .dta). Text-typed columns (PD, SKPE, VK, etc.) are coerced to numeric, with NA set to 0, and the coercion warnings are suppressed. Rows: 439/1,681/1,787. Results did not inform this.

**D6. S8 definition.** "Top 1% of farming households by y" is the top ceiling(0.01·N) farming households per year by unweighted count: 19 households dropped in total. Results did not inform this.

**D7. Helper file.** Shared functions live in `00_functions.R`, which `01_`–`04_` source. This adds no analysis.

No CRAN packages were installed. No analysis outside the card was run.
