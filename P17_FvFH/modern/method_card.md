# Method card: P17_FvFH, income inequality in the Dutch Cape Colony (EHDR 2011)

Status: v3 (2026-10-12). Revised after the Codex v2 compliance check (reviews/P17_FvFH_codex_S6card_v2.md); §9 maps each requested edit to its fix.
- History: v1 → Codex review → v2 → Codex compliance check → v3, which is frozen (A9).
- Margins follow AMENDMENTS.md A3, A4, A8 and A8a, defaults only. No band was chosen by the card author.
- To be FROZEN with the commit message "FREEZE S6 card P17". Issues not resolved at freeze go to §10.

Rights class: open; the price workbook is restricted-licence (provisional). Every script runs locally and reads data from `D:\Data\ReplicateMe\P17_FvFH\` through `tools/paths.R`. Codex sees this card, code and aggregate output only.

## 0. Type of analysis
No analysis code survives (S1, S2), and all six headline rows are unavailable in pairs A and B (S4). The S3 rebuild reproduces the input tables (T1–T3) but did not attempt incomes. The card therefore splits the headline rows in two.

- **Farm-income rows** (T6_fb_defl_1757, T8_1757_wine_contrib). These rest on farming burghers' agricultural income alone. That income can be rebuilt from the surviving opgaafrolle file with the paper's printed recipe: Table 1 prices, the 15% sale rate for cattle, sheep and pigs, 5% for horses, per capita income weighted by household size and the Table 2 sampling weights. The primary analysis is **(iii) an uncertainty propagation** (sampling uncertainty, which the paper never reports; C13) on this **reconstruction of the published estimand**.
  - It is not (i): no code or data error in the farm-income pipeline can be verified without the code.
  - It is not (ii): there is no published-code point estimate to hold fixed, so the A4b ladder does not apply and the point estimates are judged under A3, A4 and A8.
  - It is not (iv): the estimators (weighted Gini; Lerman–Yitzhaki decomposition) are the authors'.
  - Because the point estimate is a reconstruction, every farm-income verdict is **reconstruction-conditional**: it says what the rebuilt roll-based estimand shows, not that the published cells were reproduced. There is **no numerical fidelity gate** (the v1 gate is deleted; §9 item 1). Discrepancies with Tables 6 and 8 are reported as diagnostics (§4A) and decide nothing.
- **Whole-population rows** (the four T6 whole-population cells). **Not-testable.** They need VOC wage microdata (TEPC monsterrollen), pacht fee records and the income-merge code, none of which survive, and the imputed slave and knecht incomes carry an unresolved price-base problem (F2/C3). No substitute design is built.

## 1. Claims family (frozen headline rows) and interpretations
The six `headline = 1` rows in `claims/claims.csv` (A1 union) map to the verdict rows below. Interpretations are quoted from `claims/claims_spec.md`. Where one sentence makes a level statement and a comparison, they are separate rows.

**A. Farm income (testable).**

| Row | Source | Claim as the authors state it | A8 type | Margin |
|---|---|---|---|---|
| FB-pt | `T6_fb_defl_1757` = 0.689 | farming-burgher Gini in 1757 | point (Gini) | [0.659, 0.719] (A8: ±0.03 for Ginis) |
| FB-rise | same row, text p.32 | the farming-burgher Gini "rose ... to 0.65–0.69 in 1757 ... an elite had indeed formed" (from 0.554 in 1700) | comparative ">" | Δ = G₁₇₅₇ − G₁₇₀₀ > 0, adjusted CI excluding 0 (A8) |
| FB-steady | same row, text p.32 | it "rose steadily" (0.554, 0.625, 0.689 for 1700, 1723, 1757) | comparative ">", universal over both steps | Δa = G₁₇₂₃ − G₁₇₀₀ > 0 **and** Δb = G₁₇₅₇ − G₁₇₂₃ > 0, each adjusted CI excluding 0 (conjunction) |
| W-pt | `T8_1757_wine_contrib` = 0.519 | wine's share of the 1757 agricultural-income Gini | point (share > 0.30) | [0.489, 0.549] (A8a: min of ±0.03 and ±10% = ±0.03) |
| W-cmp | same row | wine "contributes more to the overall Gini coefficient than its share in income" (0.519 vs 0.441) | comparative ">" | E = C_wine − S_wine > 0, adjusted CI excluding 0 (A8) |
| W-max | same row, abstract and conclusion | "especially wine": wine contributes most among the six sources in 1757 | comparative ">", universal over the five other sources | D_k = C_wine − C_k > 0 for each of the five other sources, each adjusted CI excluding 0 (conjunction) |
| W-causal | abstract, p.33, conclusion | wine and wheat "drive income inequality upwards" and "gave rise to an elite" | causal | **not-testable**: Table 8 is an accounting decomposition with no identifying variation (C9, F6) |

**B. Whole population (not-testable).**

| Row | Source | Claim |
|---|---|---|
| WP-all-defl | `T6_wp_all_defl_1700` = 0.792 | upper end of "0.792–0.837 in 1700"; "severe inequality"; falls to 0.742 in 1757 |
| WP-all-p57 | `T6_wp_all_p1757_1700` = 0.837 | upper bound of the conclusion's "0.543–0.837" range |
| WP-xp-defl | `T6_wp_xp_defl_1700` = 0.569 | the "conservative" estimate; "slight increase in inequality from 1700 to 1757"; "among the highest inequality measures documented before the 20th century" |
| WP-xp-p57 | `T6_wp_xp_p1757_1700` = 0.543 | lower bound of "0.543–0.837"; "one of the highest Gini-coefficients in pre-industrial societies" |

All four, and every reading attached to them (level, range, trend, ranking against Table 9), are **not-testable** (§0).

**A4c.** No headline row is an odds ratio or a probability. **Stars.** None are printed; `stars05` = 2 is irrelevant here.

## 2. Defects addressed
- **No uncertainty** (C13, F6). The Ginis and the decomposition carry no SEs or intervals, so neither the 1700→1757 rise nor the wine ranking has ever been tested against sampling variation. Sources: Davidson (2009, *J. Econometrics*) on Gini inference; Lerman and Yitzhaki (1985, *REStat*) and López-Feldman (2006, *Stata Journal*) on the source decomposition; Efron and Tibshirani (1993) on the percentile bootstrap.
- **No reproducible point estimate.** No code survives (S1). The farm-income rows are rebuilt from the documented recipe (§4A), with diagnostics and no gate.
- **Causal language on an accounting identity** (C9, F6). Handled by scope: W-causal is not-testable.
- **Not addressed, because the data do not permit it:** the price base of imputed slave and knecht incomes (F2/C3), the weight mismatches (C4/C5, F3), the 1700 identity failures (C6, F4), the pacht markup (C12). All bear on the whole-population rows only.

## 3. Estimands
- **Household.** One row of `original/Statafiles/opgaafrolle.dta` with `jaar` ∈ {1700, 1723, 1757}. Household size n = m + v + s + d (burgher members; knechts and slaves form separate households in the paper and are not part of farm income).
- **Source incomes (guilders, Table 1 prices of the year as printed).**
  - grain = (kgw + rgw + cgw) × p_grain (wheat, rye and barley reaped, in muid);
  - wine = wyn × p_wine (leaguers);
  - cattle = 0.15 × bste × p_cattle; sheep = 0.15 × skpe × p_sheep; pigs = 0.15 × vk × p_pig;
  - horses = 0.05 × pd × p_horse.
  - Table 1 periods 1700, 1724 and 1757 are used for the rolls of 1700, 1723 and 1757. Missing counts are 0 (as in S3).
  - A = sum of the six. Per capita: yₖ = sourceₖ/n, y = A/n.
- **Farming burgher.** A household with n > 0 and A > 0.
- **Weight.** w = m·wf_m + v·wf_v + s·wf_s + d·wf_d, with the burgher weighting factors **as printed in Table 2** (1702 factors for 1700, as the paper states). This is "household size and sampling adjustments".
- **G_t** = the weighted Gini of y among farming burghers in year t (weighted mean-difference form, weighted ranks). Deflation by a common price index does not change a within-year Gini, so G₁₇₅₇ is the estimand of the "deflated" column.
- **Decomposition (1757).** Sₖ = Σw·yₖ / Σw·y; F is the weighted mid-rank CDF of y; **Cₖ = cov_w(yₖ, F(y)) / cov_w(y, F(y))**, which equals Sₖ·Gₖ·Rₖ/G (Gₖ the weighted Gini of yₖ, Rₖ = cov_w(yₖ, F(y))/cov_w(yₖ, F(yₖ))). Gₖ and Rₖ are diagnostics. C_wine is the W-pt estimand.
- **Tested contrasts:** Δ, Δa, Δb (§1), E = C_wine − S_wine (the wine elasticity of the Gini, as S13 defines it: Cₖ − Sₖ) and the five differences D_k = C_wine − C_k, k ∈ {grain, cattle, sheep, pigs, horses}.
- **Reconstruction record (documented choices, no numerical fit used to choose or test them).**

| Element | Choice | Basis | Status |
|---|---|---|---|
| Grain | wheat + rye + barley reaped (kgw + rgw + cgw), in muid, valued at the Table 1 grain price | Table 1 lists one grain price; the .dta carries the three reaped variables; unit read from the variable labels and the paper's text | assumption on the unit and on the three-grain sum (sensitivity S1) |
| Livestock | 15% sale rate (cattle, sheep, pigs), 5% (horses) | printed in the paper (p.27) | documented |
| Wine | wyn (leaguers) × Table 1 wine price | printed | documented |
| Household size | n = m + v + s + d | S3 rebuild reproduces the 1700 and 1702 counts exactly (S4) | documented |
| Weights | Table 2 burgher factors as printed (fixed, not re-estimated) | printed; S5 F3/C4 shows the T4 totals exceed cur × wf by 10% in 1700 and 1723, so the exact weighting of the published Ginis is **unresolved** | assumption (sensitivity S2, S3) |
| Farming pachters | **not identifiable** in the surviving data; farming households include any farming pachters (34–48 represented, T4) | S1, S5 C12 | the estimand differs from the paper's wherever the paper's farming-burgher sample excludes pachters; the effect is unknown and no sensitivity here bounds it (§5 item 8) |
| Rolls | the cleaned .dta, which is short of T2 by 1–1.6% in 1723 and 1757 (S5 F1/C1); 7 duplicate 1757 rows kept | S5 | assumption (sensitivity S11) |

  Matching of shares to Table 8 cannot establish that the original population or income distribution has been recovered, and is not used to say so. Where an item above is an assumption that may change the estimand, the verdict is labelled conditional on it and the synthesis says so.
- **Original estimands.** The printed T6 and T8 cells. The published decomposition expands the data by frequency weights (T8 note); the card uses the weighted formula, which equals the expansion up to the rounding of weights (S9 replicates the expansion).

## 4. Primary analysis (one per verdict row)

**A. Rebuild and diagnostics (decide nothing).**
- Build the six source incomes, n, w and the farming-burgher sample for 1700, 1723 and 1757 (§3).
- Reported, never gating: rebuilt weighted shares Sₖ,t beside Table 8 with the differences; rebuilt G_t beside Table 6; the numbers of households (all, n = 0, A = 0, farming); the represented farming-burgher population Σw against T4 (845, 1,496, 3,303); rebuilt Gₖ and Rₖ beside the printed values. The synthesis prints these diagnostics next to every verdict.
- A row is **not-testable** only if the data cannot be read or the computation fails by the rule in C below. Numerical distance from the printed tables is never a reason.

**B. Point rows (FB-pt, W-pt).** Point values of G₁₇₅₇ and C_wine on the rebuilt roll, as descriptions of the recorded roll. No inference enters these verdicts.

**C. Contrast rows (FB-rise, FB-steady, W-cmp, W-max).**
- **Contributions.** Cₖ = cov_w(yₖ, F(y)) / cov_w(y, F(y)) (the Lerman–Yitzhaki share, algebraically Sₖ·Gₖ·Rₖ/G). A constant or absent source has Cₖ = 0 and needs no Rₖ. Gₖ and Rₖ are diagnostics only, so an undefined Rₖ cannot disable a contrast.
- **Inferential population.** A superpopulation of farming households generating each archival roll. The intervals are conditional on archival coverage and on the printed weights; they say nothing about households absent from the rolls. Household exchangeability within a roll is a **working assumption with no empirical justification**: it is the standard default for a household sample and is adopted because no sampling design or clustering information is known to survive. Rows are nominal households, not verified independent units: the 7 duplicate 1757 rows are retained in the primary, and the same household may recur across rolls. Clustering or family identifiers are used in sensitivities S16 and S17 if the .dta holds them; otherwise the household is the unit. The number of independent household rows per year, and the number of distinct values of any district, ward or name identifier present, are reported. Table 2 weights are held fixed in the primary draws (re-estimation is sensitivity S3b).
- **Bootstrap.** Nonparametric household bootstrap, **B = 9,999**, stratified by year: in each draw, resample all rows of each year's roll with replacement (sample size equal to that year's row count), then recompute the farming-burgher subset, w, G_t, Sₖ, Cₖ and the nine contrasts jointly. Seed `set.seed(20261012)`, R's default RNG. Years are treated as independent in the primary draws. B is raised from the v1 value of 999 because 999 leaves about five order statistics in each 0.5% tail. No document in the project (PLAN.md, PROTOCOL.md, WAVE3_PLAN.md) imposes a cap of 999 draws, and 9,999 draws on about 3,700 rows run in well under 30 minutes.
- **Intervals.** Percentile intervals at the family Bonferroni level 1 − 0.05/9, each tail 0.05/18 = 0.2778%: `quantile(x, c(0.05/18, 1 − 0.05/18), type = 6)`. Each tail rests on about 28 order statistics.
- **Failure rule (symmetric, per quantity).** A draw fails for a quantity only if that quantity is undefined in it (Σw·y = 0, or cov_w(y, F(y)) = 0 so that C is undefined). Failed draws are counted per quantity and reported. Provenance of the threshold: one-tenth of the smallest tail probability, 0.1 × 0.2778% = 0.0278%, which is 2.78 of 9,999 draws. The threshold applies **only to the bootstrap, hence only to the contrast rows** (FB-rise, FB-steady, W-cmp, W-max); point rows use no draws and are not-testable only under their own rule 0 (§8). A quantity with **3 or more** failed draws is unusable and every contrast row that needs it is **not-testable**, whichever direction the point estimate points. A contrast whose point estimate on the full roll is undefined, or whose data cannot be read, is likewise unusable. With 0–2 failed draws the interval uses the defined draws and the failures are reported. A quantity's failure never disables a row that does not use it. The threshold is fixed before any bootstrap or Gini was run.
- **Primary-seed rule.** The verdict is fixed by seed 20261012. A rerun with seed 20261013 is reported; if its verdict differs for any row, the row is flagged "Monte Carlo-unstable" and the primary verdict stands.
- **Wine's rank (W-max).** The five differences D_k = C_wine − C_k for k ∈ {grain, cattle, sheep, pigs, horses} are each given an interval in the family. No maximum or minimum is bootstrapped, so tied leaders do not bias the interval. W-max is confirmed only if all five intervals lie above 0 (an intersection–union rule) and overturned if any lies below 0.

## 5. Admissible sensitivities (exhaustive; reported, never verdict-determining)
1. Grain as wheat only (kgw).
2. Weights: n only (no Table 2 factors); and unweighted households.
3. (a) Weights rebuilt from the surviving .dta counts (S3 factors) instead of the printed Table 2 factors (C1). (b) The S3 factors re-estimated inside each bootstrap draw from the drawn counts.
4. Household income instead of per capita (changes the estimand).
5. The other two Table 6 price columns: 1700 prices for every year, and 1757 prices for every year. Reports the 0.652–0.689 range the authors cite for 1757 and the rise under each.
6. Joint sale-rate scenarios: cattle/sheep/pigs ∈ {10%, 15%, 20%} crossed with horses ∈ {0%, 5%, 10%}, nine scenarios, reported as a range of the point estimates, with the share of scenarios in which each row's claim condition is met (point rows: estimate inside the band; contrast rows: adjusted CI entirely on the claimed side of 0, from a bootstrap per scenario), as A8 requires. Equal weights are assumption-conditional and carry no probability meaning (A8).
7. Frequency-expanded decomposition: weights rounded to integers and rows expanded, unweighted Lerman–Yitzhaki (the T8 note's method).
8. Top-1% exclusion (changes the population, A4d): drop the top 1% of farming households by y in each year. It is **not** a pachter proxy and not a bound: pachters cannot be identified, and no assumption links the top percentile to them. It measures the influence of the upper tail only.
9. Households with A = 0 included as zero-income farmers (changes the population, A4d).
10. The raw xls (`Time 1663 - 1757 ----  EDITED.xls`) in place of the .dta (changes the population, A4d). Its 1719/1723 mixing makes the 1723 roll a different population, so this check cannot validate or refute the claim.
11. Duplicate 1757 rows (7 rows) dropped (C1).
12. BCa intervals for the nine contrasts from the same draws. Bias constant z₀ from the draw fraction below the point estimate; acceleration from the delete-one jackknife over all rows of the years involved; if z₀ is infinite or the acceleration is undefined, BCa is reported as not computed for that contrast. BCa does not cure thin tails and decides nothing.
13. Wine elasticity (Cₖ − Sₖ) and Gₖ, Rₖ for all six sources in all three years; the grain-versus-wine ranking in 1700 and 1723 (F6, C9).
14. Magnitude diagnostic for FB-rise: Δ / 0.135 (the printed rise 0.554 → 0.689); flag if below 0.5 or above 1.5. Never decides.
15. Missing counts beyond zero imputation: (a) drop rows with any missing count among the used variables; (b) impute the year-specific weighted median of the non-missing farming households. The number of missing values per variable and year is reported.
16. Cross-year dependence: the Δ, Δa, Δb intervals recomputed from the bootstrap standard errors under assumed correlations ρ ∈ {−0.5, 0, +0.5} between the two years' Ginis, SE_Δ(ρ) = √(se₁² + se₂² − 2ρ·se₁se₂), normal approximation around the point estimate. If the .dta holds a household or family identifier linking rolls, a paired bootstrap that resamples linked households together is added; if not, this is stated.
17. Clustered bootstrap: if the .dta holds a district, ward or similar grouping identifier, resample clusters instead of households.
18. Household influence: leave-one-out shifts in G₁₇₅₇ and C_wine for the 20 households with the largest weighted influence; the maximum shift is reported.

## 6. Fixed choices
- **Years:** the 1700, 1723 and 1757 rolls (`jaar`). **Prices:** Table 1 as printed (already in guilders). **Weights:** Table 2 burgher factors as printed.
- **Missing data:** missing counts → 0 in the primary; households with n = 0 or A = 0 are outside the farming-burgher population (counts reported).
- **Multiplicity family F:** {Δ, Δa, Δb, E, D_grain, D_cattle, D_sheep, D_pigs, D_horses}, nine contrasts, Bonferroni percentile CIs at 1 − 0.05/9. No p-values are used. Point rows carry no inference.
- **Boundary rules.** Band endpoints are inside the band. A CI endpoint at exactly 0 counts as "CI includes 0". A contrast exactly 0 is "sign not established".
- **Not-testable rows** (W-causal, the four WP rows) are reported as such and are never assigned a direction.
- **Scripts:** `modern/01_build.R` (rebuild, diagnostics), `02_primary.R` (points, bootstrap), `03_sensitivities.R`, `04_verdicts.R`. Seed 20261012. Outputs regenerate identically from a clean Rscript session.

## 7. Margins and their provenance
| Row | Confirm | Provenance |
|---|---|---|
| FB-pt | 0.659 ≤ G₁₇₅₇ ≤ 0.719 | A8 point default for Ginis (±0.03) |
| FB-rise | 99.44% CI of Δ > 0 | A8 comparative default |
| FB-steady | CIs of Δa and Δb both > 0 | A8 comparative default, conjunction over both steps; "steadily" read as "at each observed step" (**card reading**, §10) |
| W-pt | 0.489 ≤ C_wine ≤ 0.549 | A8a (share above 0.30: ±0.03) |
| W-cmp | CI of E > 0 | A8 comparative default |
| W-max | all five CIs of D_k > 0 | A8 comparative default, conjunction over the five other sources |

- No ceilings. **Plausibility flag** (not verdict-determining): S14, and any point estimate more than 1.5× its stated value.
- No symmetric credible-null rule (A4a) applies: none of these rows is a magnitude claim on a coefficient, and A8 governs points and comparisons.
- **Scope of the point rows.** Under the A8 point rule a point row can be confirmed or qualified (outside the band, in either direction); it cannot be overturned, because no sign or null claim is tested. No inference enters it.
- **Scope of confirmation.** Confirming a point row (FB-pt, W-pt) says only that the rebuilt roll's value lies within the band around the printed figure. Confirming a comparative row (FB-rise, FB-steady, W-cmp, W-max) says that the stated ordering holds on the rebuilt rolls beyond sampling variation, conditional on the reconstruction record (§3); it is not a statement about the printed values. Confirming W-pt, W-cmp or W-max does not validate the broader reading that wine drove inequality over time or caused it (S5 F6/C9: grain dominates in 1723, wine's rank rests on one year, the decomposition is accounting). Sensitivity S13 reports 1700 and 1723, and the synthesis states this.

**Disclosure.** Numbers seen before this card that bear on the verdicts:
- **Published:** T6 farming burghers 0.554 (1700), 0.625 (1723), 0.689 (1757); the 1757 range 0.652–0.689 across price columns; T8 1757 shares grain 0.258, cattle 0.156, wine 0.441, sheep 0.134, pigs 0.001, horses 0.010; contributions 0.301, 0.096, 0.519, 0.077, 0.001, 0.007; elasticities 0.043, −0.061, 0.078, −0.058, 0.000, −0.003; source Ginis (wine 0.880, grain 0.905); total 0.689; T8 1723 and 1700 rows (1723 grain contribution 0.348 vs wine 0.205; 1700 wine elasticity 0.008, grain 0.007, sheep 0.010).
- **S5:** C1 counts (1723 burghers 2,357 vs 2,395; 1757 5,312 vs 5,367; 7 duplicate 1757 rows); C3/F2 price factor 1.304543 and knecht incomes 204/140/218; S5 between-group shifts +0.031 (1700) and +0.057 (1757); 1757 count shift −0.0004; C4/C5 totals.
- **Seen while drafting v1:** the unweighted 1757 means of the .dta (1,788 rows): m 0.85, v 0.57, s 0.79, d 0.77, pd 3.95, bste 20.08, skpe 107.68, vk 0.20, wyn 1.64, kgw 6.51, rgw 0.20, cgw 1.01, which at Table 1 prices imply unweighted aggregate 1757 shares of about wine 0.44, grain 0.26, cattle 0.16, sheep 0.13, horses 0.01. The grain definition (kgw + rgw + cgw) was fixed with this knowledge (§10). The v1 fidelity gate used these shares and is deleted for that reason.

No Gini, decomposition, weighted share or bootstrap on the rebuilt data has been computed. The A8/A8a margins are protocol defaults; the "steadily" reading and the failure threshold are card choices with provenance stated in §4 and §10.

## 8. Verdict tables (checked in order; the first rule that applies decides; exhaustive)
All verdicts are reconstruction-conditional (§0).

**FB-pt** (A8 point band alone; confirmed or qualified only):
| # | Condition | Verdict |
|---|---|---|
| 0 | the data cannot be read, or G₁₇₅₇ is undefined | not-testable |
| 1 | 0.659 ≤ G₁₇₅₇ ≤ 0.719 | confirmed |
| 2 | G₁₇₅₇ < 0.659 | qualified (level below the stated value) |
| 3 | G₁₇₅₇ > 0.719 | qualified (level above the stated value) |

**W-pt** (A8a point band alone; confirmed or qualified only):
| # | Condition | Verdict |
|---|---|---|
| 0 | the data cannot be read, or C_wine is undefined | not-testable |
| 1 | 0.489 ≤ C_wine ≤ 0.549 | confirmed |
| 2 | C_wine < 0.489 | qualified (contribution below the stated value) |
| 3 | C_wine > 0.549 | qualified (contribution above the stated value) |

**FB-rise, W-cmp** (comparative ">", Bonferroni percentile CI at 1 − 0.05/9; X = Δ or E):
| # | Condition | Verdict |
|---|---|---|
| 0 | X is unusable: data cannot be read, X undefined on the full roll, or 3 or more failed draws for a quantity it needs (§4C) | not-testable |
| 1 | CI of X entirely > 0 | confirmed |
| 2 | CI of X entirely < 0 | overturned (reversed: the Gini fell / wine contributes less than its share) |
| 3 | CI of X includes 0 | weakened |

**W-max** (conjunction over D_k, k = grain, cattle, sheep, pigs, horses):
| # | Condition | Verdict |
|---|---|---|
| 0 | any D_k is unusable | not-testable |
| 1 | all five CIs entirely > 0 | confirmed |
| 2 | any CI entirely < 0 | overturned (another source contributes more than wine) |
| 3 | otherwise (at least one CI includes 0, none entirely < 0) | weakened |

**FB-steady** (conjunction over Δa and Δb):
| # | Condition | Verdict |
|---|---|---|
| 0 | Δa or Δb is unusable | not-testable |
| 1 | CIs of Δa and Δb both entirely > 0 | confirmed |
| 2 | CI of Δa or of Δb entirely < 0 | overturned (a step falls; "steadily" contradicted) |
| 3 | otherwise (at least one CI includes 0, none entirely < 0) | weakened |

**W-causal, WP-all-defl, WP-all-p57, WP-xp-defl, WP-xp-p57:** not-testable (§0, §1).

**Summaries and coverage.** Report every row-level verdict. Coverage is computed from realised testability: assessed rows (those not rated not-testable at rule 0) out of the 6 farm-income rows, plus the 5 structurally not-testable rows. The weakest verdict among assessed rows is reported, ordered overturned < weakened < qualified < confirmed. The synthesis must state that the four whole-population rows, which carry the paper's level and ranking conclusions, are untested, and that every confirmed row is reconstruction-conditional, with the scope of §7 (point rows: value within band; comparative rows: ordering on the rebuilt rolls).

## 9. Codex review notes and responses
**Codex v1 review** (reviews/P17_FvFH_codex_S6card.md): approve-with-changes, 8 required changes, all addressed in v2.
1. **Fidelity gate removed.** The gate (§4A) is deleted. Share, Gini and Σw discrepancies are diagnostics only (§4A), and no replacement numerical gate exists. The share-based inspection that motivated the gate is disclosed (§7).
2. **Fidelity independent of numerical fit.** §3 has a reconstruction record: grain definition and unit, livestock and wine rules, household size, weights, farming pachters and roll defects, each marked documented or assumption. Verdicts are labelled reconstruction-conditional (§0, §8), and the farming-pachter difference of estimand is stated.
3. **Bootstrap population.** §4C states the superpopulation, the conditioning on archival coverage and fixed weights, the exchangeability assumption, the reported household and identifier counts, and the fixed calibration factors. Sensitivities S3b (re-estimated factors), S16 (cross-year dependence, with linkage if an identifier exists) and S17 (clustering) are added.
4. **D_min replaced.** W-max uses five separate differences D_k, each with an interval in the family, confirmed only if all are positive and overturned if any is negative (§4C, §8). No maximum is bootstrapped. The "only plausible contenders" argument is deleted. The family grows to nine and the level to 1 − 0.05/9.
5. **Decomposition failures.** Cₖ = cov_w(yₖ, F(y)) / cov_w(y, F(y)), with no Rₖ. Failure is defined per quantity, so a failure disables only the rows that use it (§4C).
6. **Tail precision.** B is raised to 9,999 (about 28 order statistics per tail). The 999 cap has no authority in PLAN.md, PROTOCOL.md or WAVE3_PLAN.md, and that is stated. The failure threshold is rederived (3 or more of 9,999 draws). BCa is a sensitivity with specified z₀, acceleration and degeneracy handling (S12). A second seed is reported (§4C).
7. **Sensitivity labels.** The top-1% check is renamed and disclaimed (S8); the xls check is labelled a different population (S10); missing-count handling beyond zero imputation is added (S15); sale-rate scenarios are joint, nine in number, equal-weighted and without a probability reading (S6).
8. **Verdict scope.** Point rows can confirm or qualify but not overturn (§7). Comparative rows have symmetric reversals (§8). One primary analysis per claim. Coverage is computed from realised testability. 1757 confirmation does not validate the broader wine claim (§7).

Optional suggestions: household influence diagnostics added (S18).

**Codex v2 compliance check** (reviews/P17_FvFH_codex_S6card_v2.md): freeze-after-minor-edits, five edits, all made in v3.
1. Failure threshold restricted to the contrast rows; unreadable data and undefined point estimates feed rule 0 (§4C, §8).
2. Exchangeability stated as an unjustified working assumption; nominal rows versus independent households distinguished (§4C, §10 item 6).
3. S6 reports the range and the share of scenarios meeting each row's claim condition (§5).
4. Confirmation scope separated for point and comparative rows (§7, §8).
5. Elasticity definition reconciled: E = C_wine − S_wine (§3).
Under A9 this v3 is frozen; unresolved limitations are in §10 and go to the synthesis.

## 10. Known limitations at freeze
1. **Whole-population rows untested.** The paper's main conclusions ("severe", "0.543–0.837", "one of the highest") rest on rows that need data that do not survive. The card tests only the farm-income component.
2. **Reconstruction, not reproduction.** The farm-income estimand is rebuilt from the printed recipe with no numerical gate, so a verdict can describe a rebuilt estimand far from the printed cells. Diagnostics are printed beside every verdict. Pachters cannot be identified and no sensitivity bounds their effect. The grain unit, the three-grain definition and the burgher weighting (S5 F3) are assumptions.
3. **Inspection before design.** The unweighted 1757 column means were seen before the grain definition was fixed (§7). Confirmation of the 1757 rows is therefore weak evidence of anything beyond the rebuilt roll.
4. **"Steadily" reading.** Read as a rise at each observed step (a card reading, by analogy with A8's "consistently" = every reported period). Codex judged it an acceptable wording-based reading (v2 check).
5. **Tail precision.** At B = 9,999 each tail rests on about 28 order statistics; endpoints near 0 can still move between seeds. The second-seed check flags this.
6. **Independence across rolls and exchangeability within rolls.** Years are bootstrapped independently, and households are resampled as exchangeable units. Families recur across rolls, and neighbours share conditions. S16 and S17 probe this where identifiers exist; if they do not, the intervals may be too narrow. Exchangeability has no empirical justification, and nominal rows (including 7 retained duplicates) are not verified independent households.
7. **Sampling frame.** The bootstrap captures household sampling variation only, not price, sale-rate, weight-estimation or transcription uncertainty (S3b, S5, S6 report some of these as sensitivities).
8. **Percentile intervals** for contrasts of non-smooth or skewed statistics can under-cover; BCa (S12) is reported but does not vote.
9. **W-causal not-testable.** No identifying variation exists in the surviving data. Confirmed wine rows do not support the causal reading.
