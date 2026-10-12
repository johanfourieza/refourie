# Method card: P16_FvFC, the dynamics of inequality in the Cape Colony, 1663–1757

Status: v3 (2026-10-11).
- History: v1 → Codex review (reviews/P16_FvFC_codex_S6card.md; approve-with-changes, 7 required changes) → v2 → Codex compliance check (reviews/P16_FvFC_codex_S6card_v2.md; freeze-after-minor-edits, 5 edits) → v3 (A9 cap). v3 is to be FROZEN with the commit message "FREEZE S6 card P16". Issues v3 cannot resolve go to §10.
- Margins follow AMENDMENTS.md A3, A4, A8 and A8a. The card author chooses no band, floor, ceiling or gate. The card's wording readings are listed in §7 and §10.

Rights class: open. Data live on D: (`D:\Data\ReplicateMe\P16_FvFC\...`, A6). Codex may see the workbook.

## 0. Type of analysis
The primary analysis is **one corrected central analysis**: (i) a correction of a verified data-handling inconsistency, with (iii) uncertainty propagation and a replacement of the paper's significance rule by proper inference on differences. It is not (iv), a new estimator: the estimator (a household-size-weighted Gini of the per capita "core 1" index, the first principal component on SD-scaled, non-demeaned assets with pooled weights) is the authors'.

No original code survives (S1). The central analysis is therefore built on the independent S3 rebuild (`repro_r/01_clean.R`, `02_analysis.R`, decisions D1–D12), which reproduces the published Fig 4 and Fig 5c series. The **original analysis** is defined as the rebuild with the `ineqdeco` zero rule (zero-index farmers dropped from the farmer Ginis; zeros kept in the Fig 4 Ginis), because that is the version that reproduces every published headline value. The corrections are:
- **Zeros kept in every Gini (C1).** The published 1663 value (0.501) is reproduced only when the one farming household with a zero core 1 index is dropped, as Stata `ineqdeco` does by default; Fig 4 keeps zero-asset slaves. The stated population is "the farming population", which includes that household. The mechanism is inferred from an exact reproduction, not read from code (§10).
- **PCA uncertainty propagated.** The pooled PCA weights are re-estimated in every bootstrap replicate (the published CIs match a fixed-weight bootstrap; S5 checklist).
- **Recurring households resampled jointly.** Households are resampled in name-key clusters across census years (§4), not independently within years.
- **fn-14 rule replaced.** "Significant" changes are judged on bootstrap intervals for the **difference** of two Ginis, multiplicity-adjusted, not on whether one point leaves the other year's CI (C3, F5).

**A4b is applied row by row (Codex change 2).** A row is a *corrected* row if any central point estimate it uses differs from the original analysis, and an *inference-only* row otherwise. In S5 the zero rule moved the farmer Gini only in 1663, 1678, 1685, 1688, 1692, 1695, 1719 and 1741 (`zero_index_scenarios_by_year.csv`); 1709, 1738 and 1757 are unchanged, and the Fig 4 gap already keeps zeros. `01_central.R` re-checks this classification mechanically (|central − original| < 1e-6 for every quantity of a row) and stops if it differs from the table.

| Row | Point estimate vs original | Class | Attainable verdicts |
|---|---|---|---|
| H1 | changes (0.501 → 0.527) | corrected; point (A8 band), no inference | confirmed, qualified, not-testable |
| H2-pt, H3-pt | unchanged | unchanged point (A8 band), no inference; the A4b ladder is for inferential rows and does not enter | confirmed, qualified, not-testable |
| H2-rise | changes (1663 and 1678 contrasts) | corrected (A3/A8 comparative) | confirmed, qualified, weakened, overturned, not-testable |
| H3-rise, H4-w | unchanged | inference-only (A4b) | confirmed, qualified (inference-fragile), weakened, not-testable |
| H4 | unchanged (m equals the Fig 4 mean) | inference-only (A4b), A3 magnitude | confirmed, qualified, weakened, not-testable |

"Overturned" cannot be reached on the point rows (no inference enters them) or on the A4b rows. The paper reports no odds ratios or probability statements, so A4c does not apply. The star legend is irrelevant (no regressions; `stars05` = 2).

**Inferential verdicts rest only on the central analysis (§4).** There is one primary analysis per verdict row. Sensitivities (§5) are reported and never vote. Changed populations, indices and targets (§5B) cannot decide a verdict (A4d).

## 1. Claims family (frozen headline rows, A1 union) and interpretations
The four `headline = 1` rows map to the verdict rows below. Interpretations are quoted from `claims/claims_spec.md`. Where one sentence makes a level statement and a comparison, the two are separate rows, each on its own margin.

**H1 (`text_p26_gini_initial`, 0.501).** "The relatively low inequality (with a Gini coefficient of 0.501 based on the 'core 1' measure) initially registered" (p.26).

| Row | Claim | A8 type | Margin |
|---|---|---|---|
| H1 | the 1663 farmer Gini is 0.501 | point (Gini) | [0.471, 0.531] (A8; A8a leaves Ginis above 0.30 at ±0.03) |

**H2 (`text_p26_gini_1709`, 0.65).** "followed by a period of significant increase to fairly high levels (with the Gini reaching a maximum of 0.65 in 1709, which is beyond the bounds of the initial period)" (pp.24–26). The "initial period" is the period of the preceding sentence: "from the beginning of the period of analysis until 1682", i.e. the census years 1663, 1670, 1678 and 1682.

| Row | Claim | A8 type | Margin |
|---|---|---|---|
| H2-pt | the 1709 Gini is 0.65 | point (Gini) | [0.62, 0.68] |
| H2-rise | 1709 lies significantly above the initial period | comparative ">", universal over the four initial years | d_t = G₁₇₀₉ − G_t > 0 with the adjusted band excluding 0, for **every** t ∈ {1663, 1670, 1678, 1682} |

"A maximum of 0.65 in 1709" describes the observed series; it carries no significance language. It is **not a verdict row** (Codex change 1). The observed ranking is reported as secondary output S-0 (§5D).

**H3 (`text_p26_gini_1757`, 0.62).** "followed by yet another spurt of increases in inequality to 0.62 by 1757 (which is again significantly higher than in 1738)" (p.26).

| Row | Claim | A8 type | Margin |
|---|---|---|---|
| H3-pt | the 1757 Gini is 0.62 | point (Gini) | [0.59, 0.65] |
| H3-rise | 1757 is significantly higher than 1738 | comparative ">" | d = G₁₇₅₇ − G₁₇₃₈ > 0, adjusted CI excluding 0 |

**H4 (`text_p23_slave_gap`, 0.2).** "the inclusion of slaves as assetless individuals increases inequality in Cape society by roughly 0.2 Gini points over the period" (p.23); "An important observation, however, is the apparent widening gap over the course of the eighteenth century … it is the between-group inequality presented here, which most closely matches the Engerman and Sokoloff hypothesis".

| Row | Claim | A8 type | Margin |
|---|---|---|---|
| H4 | including slaves raises the Gini by 0.2 over the period | magnitude ("increases … by x"; A3/A4) | same sign, adjusted CI excluding 0, m ≥ 0.10 (50% of 0.2); A4a credible-null band (−0.10, 0.10) |
| H4-w | the gap widens over the eighteenth century | comparative ">" (slope) | s > 0, adjusted CI excluding 0 |
| H4-ES | the gap is between-group inequality supporting Engerman–Sokoloff | — | **not-testable**: slaves carry zero assets by construction, so the gap is a function of the slave share of persons (g_t = p_t(1 − G^S_t), checked in §5C), as the authors concede |

**Not-testable wording rows (no A8 default; no wording-based margin can be justified independently of S5).**
- **W-lvl.** "relatively low", "fairly moderate", "fairly high", "never recovered to sustained 'low' levels" (p.26).
- **W-cause.** The attributions to immigration (Sect. 7.3, 8), to viticulture and slaves (Sect. 9) and to VOC policy (abstract, Sect. 9). There is no counterfactual or exogenous variation.

**Scope and interpretation bounds (Codex change 7).** The estimands are Ginis of a per capita asset index over the households recorded in the opgaafrollen, with district coverage as recorded in each year (C4: 1663, 1670, 1682 and 1716 are Cape district only; DS4 enters in 1723). Point verdicts describe **the recorded households** of a census year, not the colony; bootstrap verdicts describe the process that generated those recorded households. No verdict licenses a colony-wide statement or a comparison with income Ginis, and none speaks to the causal attributions (W-cause) or the Engerman–Sokoloff reading (H4-ES).

**Classification of H4 as a magnitude claim (Codex ruling).** The sentence has the form "increases … by x", which is A8's magnitude category. The v1 card adopted this reading after the S5 mean (0.142) was seen. Codex accepted it as justified by the wording, independently of S5 (review, change 4). The row therefore uses A3's 0.10 floor, the symmetric A4a null band and no ceiling. **A confirmed H4 means that the gap retains at least half the stated magnitude with the right sign under the protocol; it does not mean that the gap equals "roughly 0.2".** The A8 point reading ([0.18, 0.22] under A8a) is reported as secondary output S-4 and never votes. Neither reading was or will be chosen by its result.

## 2. Defects addressed
- (a) **fn-14 significance rule** (C3, F5). A later point outside an earlier CI ignores the later year's sampling error. Under a two-sample test, 1709 vs 1663 is not significant on either the published CIs or the rebuild.
- (b) **Zero handling** (C1). The published 1663 Gini drops a zero-index farmer; Fig 4 keeps zero-asset slaves.
- (c) **PCA step ignored in the CIs** (S5 checklist). The CI method is unstated; the published CIs match a fixed-weight household bootstrap.
- (d) **Dependence between years** (F5: "ignores … the covariance"). The same households recur across census years; the published CIs and the fn-14 rule treat years as independent.
- (e) **Slave-gap magnitude** (C2, F6). The text says roughly 0.2; the authors' own Fig 4 averages 0.142. Assessed under A3; no correction changes the gap.
- (f) **Source coding** (F2, D2). Non-numeric count cells are set to 0. Not corrected: the zero rule reproduces Table 3, which shows it was the authors' rule. Reported in §5B (drop) and §5C (stress test).
- (g) **District coverage** (C4). Changes across years. A changed population, so §5B only (A4d), and stated as a bound on interpretation (§1).
- Not addressed, because no headline claim rests on them: the Table 1 price readings (F3), the Theil zero handling (F4), the PP misreading (C6), the pig share (C5) and the comparison Ginis (C10, C11). F3, F4 and C6 are reported as secondary outputs.

Sources: Davidson (2009, *J. Econometrics*) on Gini inference; Efron and Tibshirani (1993) on the bootstrap; Cameron, Gelbach and Miller (2008, *REStat*) and Cameron and Miller (2015, *JHR*) on cluster resampling and coarse clusters; Montiel Olea and Plagborg-Møller (2019, *J. Applied Econometrics*) on sup-t bands; Jolliffe (2002) on PCA; Cowell (2011) on inequality measures with zeros; Engerman and Sokoloff (1997).

## 3. Estimands
Notation. Year t ∈ T, the 20 census years 1663, 1670, 1678, 1682, 1685, 1688, 1692, 1695, 1700, 1702, 1709, 1712, 1716, 1719, 1723, 1731, 1738, 1741, 1752, 1757 (1705 dropped, fn 8). Household i in year t has assets x_ij, household size n_i = M + V + S + D (minimum 1; D5) and slaves k_i = SM + SV + SS + SD.

- **Core 1 index.** Items j: SM, SV, SS, SD, PD, BSTE, SKPE, VK, WINGST. Weights w = the first eigenvector of the correlation matrix of the items on the pooled sample, signed so that Σw_j > 0. Index I_i = Σ_j w_j x_ij / sd_j (not demeaned). If min_i I_i < 0 on the pooled sample, I_i is shifted by −min I_i (the paper's stated rule; a no-op when every loading is positive).
- **Farmer Gini G_t** (H1–H3). Pooled weights estimated on farmers (D4: non-zero on any of horses, cattle, sheep, pigs, vines, wine or grain). G_t = the Gini of y_i = I_i/n_i over the farmers of year t, each weighted by n_i, by the rebuild's `gini_w` (replication-equivalent formula for integer weights), **zeros included**.
- **H2-rise, H3-rise.** d_t = G₁₇₀₉ − G_t for t in the initial period; d = G₁₇₅₇ − G₁₇₃₈.
- **Gap g_t** (H4, H4-w). Pooled weights estimated on the whole settler sample (farmers and non-farmers; Fig 4 legend). g_t = the Gini over all settler households of year t (weight n_i) plus, for every settler household, k_i one-person households with value 0 (weight 1), minus the Gini over the settler households alone.
  - **H4:** m = (1/20) Σ_t g_t, the equal-year-weighted mean over the 20 census years (S3 claim mapping, frozen before S4).
  - **H4-w:** s = the OLS slope of g_t on (year − 1700)/10 over the 12 census years 1700–1757 ("the course of the eighteenth century"), in Gini points per decade.
- The original estimands are the same quantities as printed. They differ from the central estimands only in the zero-index farmers (1663 and 1678 among the verdict years) and in the inference behind "significant".

## 4. Primary analysis: the central analysis
**Data.** `D:\Data\ReplicateMe\P16_FvFC\original\Wealth inequality\Time 1663 - 1757 ----  EDITED.xls`, sheet `Data`, processed by `repro_r/01_clean.R` unchanged (D1–D6: non-numeric cells → 0, 1705 dropped, the farmer flag, household size). The household file is `D:\Data\ReplicateMe\P16_FvFC\repro_r\data\households.rds`.

**Checks before any verdict (compliance edit 1).** `01_central.R` reads the stored S3 values at full precision from the files, never from literals, and stops unless every absolute difference is < 1e-9: (a) the central estimates against `repro_r/results_r.csv` (`value` column): G₁₆₆₃ (`F5c_1663`, 0.5266510168082346), G₁₇₀₉ (`text_p26_gini_1709`, 0.6471974070129718), G₁₇₅₇ (`text_p26_gini_1757`, 0.626280536226927) and m (`text_p23_slave_gap`, 0.14171490921871213); (b) the original analysis against `compare/s5_checks/zero_index_scenarios_by_year.csv` (year 1663, `pca_sample` = "all farmers", `drop_zero_in_gini` = TRUE: 0.5012930355658187); (c) the §0 classification holds. The decimals quoted here and elsewhere in the card are for reading only; the stored values decide the check.

**Points (H1, H2-pt, H3-pt).** The opgaafrollen are a census of the taxed free population, and the authors attach significance language only to changes. Point rows are judged on the central point estimate as a description of the recorded households (§1); no inference enters these verdicts. Their 95% bootstrap intervals are reported.

**Bootstrap (H2-rise, H3-rise, H4, H4-w).**
- **Superpopulation.** Household histories drawn independently from the process that generated the recorded households, holding census coverage and recording practice fixed. The intervals capture the finite number of households, the dependence of a household's records across years, and the PCA estimation step. They **do not** capture transcription error, unrecorded assets, missing returns, district coverage or shocks common to all households in a year (one cross-section per year cannot identify those).
- **Clusters (Codex change 3).** No validated linkage of these records exists, and exact names do not establish identity. The cluster key is therefore deliberately **coarse**, to err towards merging: a false merge of two distinct households costs precision but not validity, whereas a missed link leaves dependence unmodelled. The key is **not** claimed to be a coarsening of true identity: it misses links (spelling variants, changed given names, widows under their own names; §10), so it is a working approximation, and primary inference rests on the conditional-independence assumption stated below (compliance edit 5).
  - Key = normalised surname + "|" + normalised first given name. Normalisation: lower case; diacritics removed; a trailing widow token ("wed", "weduwee") is removed from `Van` first; then every non-letter (spaces, apostrophes, full stops) is removed, so "van der Merwe" = "vandermerwe"; the first given name is the first whitespace token of `Naam`. The `WED` flag does not enter the key.
  - **Widows.** The data hold 753 rows with `WED` = 1. A widow recorded under her late husband's given name (e.g. ADRIAANSZ LAMBERT, `WED` = 1) gets his key and joins his cluster, which keeps a continuing household together. Rows whose `Naam` is only a widow token ("WED", "WEDUWEE"; 40 rows) get the key surname + "|weduwee", one cluster per surname. A widow recorded under her own given name forms her own cluster (a missed link; §10).
  - Rows with an empty `Van` or `Naam` after normalisation are singleton clusters (none in the current file; the rule is kept for safety).
  - **Ambiguous names.** Two or more rows with the same key in the same year (namesakes, or one person on separate holdings; C9) stay in one cluster. No attempt is made to split them.
  - **Reported before any interval:** the number of clusters; the cluster-size distribution in rows (mean, median, 90th percentile, maximum) and in years spanned; the share of rows in singleton clusters; the number of keys with ≥ 2 rows in a year, by year; the share of each year's rows whose key appears in another census year; the number of clusters that touch 1663, the initial period, 1709, 1738 and 1757; the `WED` = 1 rows by key type (husband's key, surname + "|weduwee", own given name).
  - **Primary inference is conditional on independence across key clusters.** Dependence through spelling variants, sons with different first names, or shared year shocks is not modelled. The exact-name key and the independent within-year design are §5A sensitivities.
- **Resampling (Codex change 6).** Clusters are drawn with replacement, **with equal probability**, from all clusters in the panel; a drawn cluster brings all its rows in every year, and a household's slaves travel with it. Year sample sizes therefore vary across replicates. Person weights (n_i; 1 for each added slave) enter only the Gini computation, never the resampling probabilities.
- **Within each replicate (common draws).** One resampled data set feeds both pipelines. Re-estimate both sets of pooled PCA weights (farmers; whole settler sample), with SDs from the replicate, the sign rule and the shift rule of §3. Recompute every G_t and every g_t, then d_t, d, m and s jointly.
- **B = 9,999**, seed 20261011, RNG L'Ecuyer-CMRG.
- **Multiplicity family: {H2-rise, H3-rise, H4, H4-w}**, Bonferroni α = 0.05/4 = 0.0125, i.e. 98.75% two-sided intervals (A3). H2-max is no longer a member (Codex change 1). Quantiles use R type 7.
  - H3-rise, H4, H4-w: percentile intervals [L, U]. For the A4b "inference-fragile" tier, the unadjusted 95% percentile interval [L₉₅, U₉₅] from the same draws is also computed.
  - H2-rise (4 contrasts): sup-t simultaneous band. se_t = the bootstrap SD (n − 1 denominator) of d*_t over the row's jointly valid draws; c = the 98.75% quantile of max_t |d*_t − d_t|/se_t over those draws (contrasts with se_t > 0); L_t = d_t − c·se_t, U_t = d_t + c·se_t.
- **Failed draws (symmetric rule; Codex change 6).**
  - A draw fails for a quantity if the PCA errors; any item has zero SD in the PCA sample (the correlation matrix is undefined; the draw fails for every quantity that uses that PCA, and no item is dropped); the first two eigenvalues differ by < 1e-8; a year needed by the quantity has no farmers (or no settler households); or the quantity is non-finite.
  - A draw is **jointly valid** for a row when every quantity the row needs is defined. All of a row's statistics (se_t, c, endpoints, Monte Carlo SE) use the same jointly valid draws.
  - **Why failed draws may be set aside, and the check that this is harmless.** With thousands of households pooled, every failure mode above is a degenerate replicate whose probability should be negligible; discarding them conditions on non-degenerate draws. That conditioning is not assumed harmless. For every row the verdict is computed twice: (a) on the jointly valid draws; (b) on the **failure-bounded** interval, in which every failed draw is placed at −∞ when computing L (or L_t) and at +∞ when computing U (or U_t), and assigned a sup-t statistic of +∞. If (a) and (b) give the same verdict, (a) stands; otherwise the row is not-testable.
  - Let F be the share of failed draws for a row. If F > 0.01 the row is not-testable without further computation. Failure counts by cause are reported for every row.
  - A contrast with se_t = 0 is left out of the max and gets L_t = U_t = d_t (flagged). If every contrast of a row has se_t = 0, the bounds equal the points.
  - If a central estimate is not computable, the row is not-testable.
- **Monte Carlo precision.** The jointly valid draws are split in draw order into 10 batches of floor(V/10) draws; each endpoint is recomputed per batch (for H2-rise, se_t, c and the bounds within the batch, with d_t fixed at the central value); MC SE = SD across batches/√10. An endpoint is *flagged* if it is verdict-relevant (L, U, L_t, U_t, L₉₅) and has MC SE > 0.002 or lies within 2 MC SE of any threshold it is compared with in §8 (0 for every endpoint; −0.10 and 0.10 for H4's L and U). If any endpoint of a row is flagged, B is raised to 39,999 with the same seed and that run replaces the first. **Unresolved after escalation (compliance edit 4):** let k be the number of endpoints of the row still flagged. The verdict is recomputed for **every joint perturbation**: each flagged endpoint is moved by δ ∈ {−2, 0, +2} MC SE, independently, over all 3^k combinations (at most 3^8 = 6,561 for H2-rise), with the other endpoints held at their values. The verdict stands only if all 3^k verdicts agree; otherwise the row is not-testable (Monte Carlo unresolved). The rule is symmetric: it does not favour any verdict.
- **Reported per year:** households, farmers, slaves added, persons, the number of zero-index farmers, the district composition (DS codes), and the mean and range of the year's sample size across replicates.

## 5. Supplementary analyses (exhaustive; reported, never verdict-determining)
**5A. Same estimand, central population and index, different inference.**
1. Independent within-year household bootstrap, stratified by year (the v1 central design), for all bootstrap rows.
2. Exact-name clusters: key = case-folded raw `Van` + full raw `Naam`, otherwise as §4.
3. PCA weights held fixed across replicates (the authors' implied CI method), all bootstrap rows.
4. Normal-approximation intervals X ± z·SE at the family level, from the central draws.

**5B. Changed population, index or target (A4d; labelled, never pooled with 5A).**
5. Zero-index farmers dropped from the farmer Ginis (`ineqdeco` default; reproduces 0.501): a population change.
6. Districts DS1–DS3 only (consistent coverage).
7. Cape district (DS1) only.
8. Households with any non-numeric count cell dropped (F2).
9. 1723: same-name records merged within year (a change of unit).
10. Exact duplicate rows removed.
11. Whole-sample PCA weights for the farmer Ginis (index).
12. Vines winsorised at the pooled 99.9th percentile (index).
13. 1705 farmers included in the PCA estimation, not in the Ginis (index).
14. Annual PCA weights (Fig 2 variant; index).
15. Core 2 (no vines) and Core 3 (no pigs) indices.
16. Household size including knegte.
17. Unweighted Gini (household as the unit).
18. H4 and H4-w with only farmers' slaves added.
19. H4-w over all 20 census years 1663–1757 (target).
20. H2-rise against (a) the pooled 1663–1682 farmer Gini and (b) the mean of the four initial-year Ginis, as single contrasts (targets).

**5C. Diagnostics and stress tests (not alternative estimates).**
21. Stress test, hypothetical: single-letter count cells decoded as A = 10 … Z = 35 (F2). No evidence supports this coding.
22. H4-w with OLS inference over the 12 year-points (HC1; Newey–West with 1 lag). A different stochastic model, treating irregularly spaced gaps as a time series.
23. The published fn-14 rule applied to the central series.
24. Leave-one-household-out for 1663 and 1709 (maximum |ΔG| and the ten most influential households).
25. Bootstrap-distribution diagnostics (Codex optional 1): for G₁₆₆₃, G₁₇₀₉, every d_t, d, m and s, the central-draw quantiles (0.625%, 2.5%, 50%, 97.5%, 99.375%), skewness and histogram; the replicate distribution of the 1663 farmer count (minimum; share of draws below 20); and, for draws in each 2.5% tail of d*₁₆₆₃, the over-representation of each 1663 farmer relative to its expected frequency (ten largest).
26. Gap identity (Codex optional 2): g_t against p_t(1 − G^S_t), where p_t is the slaves' share of persons and G^S_t the settler Gini; the maximum absolute discrepancy across years is reported.

**5D. Secondary outputs (non-headline; reported).**
- S-0. **The "maximum" in H2:** the rank of G₁₇₀₉ in the central series, the gap to the runner-up and the runner-up year, and the share of central bootstrap draws in which 1709 has the highest Gini (a bootstrap frequency, not a probability that the claim is true).
- S-1. The 1738 fall: G₁₇₃₈ − G₁₇₀₉ (`text_p26_gini_1738`, "a significant change") and the omitted 1716 dip (G₁₇₁₆ − G₁₇₁₂), with central-bootstrap 95% intervals.
- S-2. "Stable … until 1682": the four initial-year Ginis and their pairwise differences against the A8 "similar" band (±0.03), descriptive.
- S-3. "above 0.70 over the period" with slaves (p.29): the minimum incl-slaves Gini and the number of years ≤ 0.70.
- S-4. H4 under the A8 point reading, with A8a's band for small values (0.2 ± 0.02; compliance edit 2): m against [0.18, 0.22]; per-year g_t against the same band ("throughout" reading; count of years inside).
- S-5. Theil T with zeros at their limiting contribution, incl and excl slaves (F4).
- S-6. Phillips–Perron on the central series with Stata defaults (constant, no trend, 2 NW lags) and the corrected MacKinnon p (C6, C7).
- S-7. Table 1 raw-unit ratios w_j/sd_j relative to male slaves (F3).

## 6. Fixed choices
- Years: the 20 census years; 1705 excluded. Districts as recorded. No trimming.
- Missing and non-numeric counts → 0 (D2). Seed imputation (D3) is irrelevant to core 1.
- Weights: persons (household size) in every Gini; slave households weight 1. Resampling is unweighted (§4).
- Multiplicity: one family of four bootstrap rows, Bonferroni (§4). Point rows have no inference.
- **Boundary rules.** Band endpoints are inside the band. m = 0.10 meets the floor. A CI endpoint at exactly 0 counts as "includes 0". d_t = 0 or s = 0 counts as "direction not held". A4a's null interval (−0.10, 0.10) is open.
- Verdict comparisons use unrounded values; results are reported to 3 dp (gaps and slopes to 4 dp).
- Scripts: `modern/01_central.R`, `02_bootstrap.R`, `03_sensitivities.R`, `04_secondary.R`, `05_verdicts.R`. Each runs from a clean Rscript session; `sessionInfo()` is saved to `modern/sessionInfo.txt`.

## 7. Margins and their provenance
| Row | Confirm | Provenance |
|---|---|---|
| H1 | 0.471 ≤ G₁₆₆₃ ≤ 0.531 | A8 point (Gini, ±0.03) |
| H2-pt | 0.62 ≤ G₁₇₀₉ ≤ 0.68 | A8 point (Gini, ±0.03) |
| H3-pt | 0.59 ≤ G₁₇₅₇ ≤ 0.65 | A8 point (Gini, ±0.03); the text's 0.62, not the figure's 0.626 (frozen claim value) |
| H2-rise | L_t > 0 for all four initial years | A8 comparative; "beyond the bounds of the initial period" read as all of it (**card reading**) |
| H3-rise | L > 0 | A8 comparative; A4b ladder |
| H4 | L > 0 and m ≥ 0.10 | A8 magnitude → A3 floor; A4a null (−0.10, 0.10); A4b ladder; reading accepted by Codex (§1) |
| H4-w | L > 0 | A8 comparative; A4b ladder; 1700–1757 window (**card reading**) |

- No ceilings. **Plausibility flag** (not verdict-determining): m > 0.30 (1.5 × 0.2).
- The H4 period mean with equal year weights follows the S3 mapping frozen before S4; the "throughout" reading is S-4.

**Disclosure.** S2, S4 and S5 numbers already seen, all bearing on these verdicts:
- **Points (rebuild, zeros kept):** G₁₆₆₃ 0.5267 (0.5013 with the zero-index farmer dropped); G₁₆₇₈ 0.5370 (0.5361 dropped); G₁₇₀₉ 0.6472; G₁₇₅₇ 0.6263; G₁₇₃₈ 0.5640; initial years 0.5395 (1670), 0.5266 (1682); 1702 0.639 (published 0.646); 1695 0.621 (published 0.637).
- **Published (digitised):** 1663 0.501 (CI 0.357–0.645), 1709 0.648 (0.608–0.688), 1738 0.563 (0.531–0.595), 1757 0.626 (0.602–0.648).
- **Contrasts (two-sample z, 95%, independent years):** 1709 vs 1663 p = 0.054 (published), 0.114 (rebuild, fixed weights), 0.100 (PCA re-estimated); vs 1670 p 0.024–0.034; vs 1678 p < 0.001; vs 1682 p 0.004–0.005; 1738 vs 1709 p 0.001; 1757 vs 1738 p 0.002 (DS1–3: 0.001); 1716 vs 1712 p 0.06–0.08. Rebuilt 1663 95% CI 0.382–0.671.
- **Scenarios (`compare/s5_effects.csv`):** 1709 0.646–0.650 except unweighted 0.698 and knegte 0.617; 1757 0.624–0.630, Cape-only 0.585, unweighted 0.707, knegte 0.608; 1663 0.521–0.529, 0.552 with knegte. Cape-only 1738→1757 0.547→0.585 (z ≈ 1.0). F2 decoding: 1723 0.594 → 0.615.
- **Gap:** mean 0.1417 (published digitised and rebuild); range 0.054–0.222; 1663–1723 mean 0.125, 1731–1757 mean 0.193; 8 of 20 years ≥ 0.15; farmers' slaves only 0.136; trend over 1663–1757 +0.012 per decade (t = 4.8, OLS on 20 points); per-year gaps 1700–1757 in `compare/s5_checks/slave_gap_by_year.csv` (0.126 in 1700, 0.195 in 1716, 0.224 in 1738, 0.167 in 1757). Minimum incl-slaves Gini 0.696.
- **Other:** PCA re-estimation changes bootstrap SEs by < 5%; PP p 0.146 (published series), 0.294 (rebuild); within-year name repeats 0–13.5% of rows (`name_duplicates_by_year.csv`). For v2 the `Van`, `Naam` and `WED` fields were inspected to write the key rule (753 `WED` rows, 40 name-only widow rows, no empty names); no cluster was formed and no statistic computed.

No bootstrap with the §4 cluster design or family level, no sup-t band, no 1700–1757 slope interval and no sensitivity in §5 that is not listed above has been run. The A8 bands, the A3 floor and the A4a null are protocol defaults. The card's own readings are the conjunction reading of "initial period", the 1700–1757 window for "the eighteenth century", and the point-rows-without-inference rule; all were made with the numbers above in view. **The removal of H2-max (Codex change 1) removes a gate that the S5 numbers (1702 at 0.639 against 1709 at 0.647) suggested would fail; it was made on Codex's wording ground, and its direction favours confirmation of H2.** This disclosure does not prove that nothing was tuned.

## 8. Verdict tables (central analysis only; checked in order; the first rule that applies decides; exhaustive)
"Not-testable (inference)" below means any of: F > 0.01; the failure-bounded verdict differs from the jointly-valid verdict; or the row is Monte Carlo unresolved after escalation (§4).

**H1 (corrected), H2-pt and H3-pt (unchanged points)** (point band [b_lo, b_hi]; central point G; no inference):
| # | Condition | Verdict |
|---|---|---|
| 0 | G not computable | not-testable |
| 1 | b_lo ≤ G ≤ b_hi | confirmed |
| 2 | G < b_lo | qualified (below the stated value) |
| 3 | G > b_hi | qualified (above the stated value) |

Overturned is unattainable: without inference a point cannot be credibly different from the stated value. The verdict applies to the recorded households of that year (§1).

**H2-rise (corrected; sup-t band at 98.75% over t ∈ {1663, 1670, 1678, 1682})**:
| # | Condition | Verdict |
|---|---|---|
| 0 | central not computable, or not-testable (inference) | not-testable |
| 1 | U_t < 0 for at least one t | overturned (some initial year credibly above 1709) |
| 2 | L_t > 0 for every t | confirmed |
| 3 | L_t > 0 for at least one but not every t, and d_t > 0 for every t | qualified (significant against a subset of the initial period only) |
| 4 | L_t > 0 for no t, and d_t > 0 for every t | weakened (direction holds, not significant) |
| 5 | otherwise (d_t ≤ 0 for some t, no U_t < 0) | weakened (direction not held for some year) |

**H3-rise and H4-w (inference-only, A4b; X = d or s; 98.75% interval [L, U], unadjusted 95% interval [L₉₅, U₉₅])**:
| # | Condition | Verdict |
|---|---|---|
| 0 | central not computable, or not-testable (inference) | not-testable |
| 1 | X > 0 and L > 0 | confirmed |
| 2 | X > 0, L ≤ 0 and L₉₅ > 0 | qualified (inference-fragile) |
| 3 | X > 0 and L₉₅ ≤ 0 | weakened (direction holds, not significant) |
| 4 | X ≤ 0 | weakened (direction not held) |

Overturned is unattainable (A4b). If U < 0, the report notes "interval reversed; A4b caps the verdict at weakened".

**H4 (inference-only, A4b; A3 magnitude; b₀ = 0.2; 98.75% interval [L, U]; unadjusted [L₉₅, U₉₅])**:
| # | Condition | Verdict |
|---|---|---|
| 0 | central not computable, or not-testable (inference) | not-testable |
| 1 | −0.10 < L and U < 0.10 | weakened (credible null under A4a; A4b caps the verdict at weakened) |
| 2 | m ≥ 0.10 and L > 0 | confirmed (at least half the stated magnitude retained) |
| 3 | 0 < m < 0.10 and L > 0 | qualified (magnitude below 50% of the stated 0.2) |
| 4 | m > 0, L ≤ 0 and L₉₅ > 0 | qualified (inference-fragile) |
| 5 | otherwise | weakened |

Rows 1–5 are exhaustive once row 0 does not apply. Row 1 takes precedence over confirmation (compliance edit 3): a percentile interval can lie inside (−0.10, 0.10) with L > 0 while m ≥ 0.10, and such a row is weakened, not confirmed. Overturned is unattainable (A4b): the central m equals the Fig 4 value, which the precheck fixes at the stored S3 value. If U < 0 the report notes "interval reversed". The plausibility flag (m > 0.30) is reported beside the verdict.

**H4-ES, W-lvl, W-cause:** not-testable. **S-0 (the "maximum"):** reported, no verdict.

**Per-claim summaries.** H1 = H1. H2 = the weakest of {H2-pt, H2-rise}; H3 = the weakest of {H3-pt, H3-rise}; H4 = the weakest of {H4, H4-w}, ordered not-testable < overturned < weakened < qualified < confirmed. Every row-level verdict is reported, with its class (corrected, inference-only or unchanged point) and its attainable verdicts (§0). Coverage (rows assessed; rows not-testable) is reported separately. Beside each verdict the report lists the §5A, §5B and §5C results by item, labelled "reported, not verdict-determining".

## 9. Codex review notes and responses
**Codex v1 review** (reviews/P16_FvFC_codex_S6card.md): approve-with-changes, 7 required changes, all addressed in v2.
1. **H2-max removed as a significance gate.** "A maximum" is an observed description, so H2-max is no longer a verdict row. The observed ranking is S-0 (§5D). H2 now summarises {H2-pt, H2-rise}. The multiplicity family is {H2-rise, H3-rise, H4, H4-w}, Bonferroni at 98.75% (§4). The removal's favourable direction is disclosed (§7, §10).
2. **A4b by row.** §0 classifies each row as corrected or inference-only from the S5 per-year zero-rule results, with a mechanical re-check in `01_central.R`. H3-rise, H4-w and H4 are inference-only; H1 and H2-rise are corrected; H2-pt and H3-pt are unchanged point rows judged on their A8 bands, to which the A4b ladder does not apply. Each row's attainable verdicts are listed (§0), and §8 uses the A4b ladder (confirmed / qualified (inference-fragile) / weakened) for the inference-only bootstrap rows. Point rows cannot be overturned, and the card says so.
3. **Recurring households.** The central bootstrap now resamples coarse name-key clusters across years (§4): normalised surname + first given name, singletons for empty names, same-year namesakes kept in one cluster, widows recorded under the husband's given name in his cluster and name-only widow rows in a surname + "weduwee" cluster, with cluster counts, size and year-span distributions and ambiguity counts reported. Because no validated linkage exists, the key errs towards merging (valid under coarsening), and primary inference is labelled conditional on independence across key clusters. Exact-name clusters and the independent within-year design are §5A sensitivities.
4. **H4 classification.** Codex's ruling that "increases … by" is A8 magnitude wording, independently of S5, is recorded (§1). The 0.10 floor, the A4a null band and no ceiling are retained; §1 and §8 state that confirmation means retained magnitude, not equivalence to "roughly 0.2". S-4 keeps the point reading as secondary output. Because H4 is also inference-only, A4b caps its ladder; the A4a null is reported as a note (§8).
5. **§5 labels corrected.** Zero-dropping, district and coding drops, 1723 merging and duplicate removal (population); whole-sample, winsorised, 1705-augmented and annual PCA (index); the 1663–1757 slope and the pooled or mean initial-period contrasts (targets) are in §5B. §5A now holds only inference variants on the central estimand. Letter decoding is a labelled stress test, and HC1/Newey–West over 12 irregular dates a labelled different stochastic model (§5C).
6. **Implementation safeguards.** Equal-probability cluster resampling with person weights only in the Ginis; one resampled data set for both PCA pipelines; zero-SD items make the draw fail (no item dropped); failed draws are set aside only if a failure-bounded interval (failures placed at ±∞) gives the same verdict, otherwise the row is not-testable; the F > 0.01 cap and failure counts by cause are retained; unresolved Monte Carlo uncertainty after escalation is handled by a symmetric ±2 MC SE agreement rule (§4).
7. **Interpretation bounds and A9.** §1 limits point verdicts to recorded households and excludes colony-wide generalisation (C4); H4-ES and W-cause stay not-testable. History and the v2 → compliance check → v3 freeze path are in the header; unresolved issues are in §10.

**Codex compliance check of v2** (reviews/P16_FvFC_codex_S6card_v2.md): freeze-after-minor-edits; changes 1–5 and 7 addressed, 6 partly (Monte Carlo). All five edits are made in v3.
1. **Prechecks** read the stored S3 values at full precision from `repro_r/results_r.csv` and `zero_index_scenarios_by_year.csv`, tolerance < 1e-9 (§4). The v2 five-decimal literals would have failed.
2. **A8a band** for the secondary H4 point reading: [0.18, 0.22] (§1, §5D S-4, §10).
3. **H4 credible null** now has its own row ahead of confirmation (§8).
4. **Monte Carlo rule** recomputes the verdict over all 3^k joint ±2/0 MC SE perturbations of the flagged endpoints, with thresholds at 0 and ±0.10 (§4).
5. **Cluster justification** no longer claims the key coarsens true identity; it is a working approximation under conditional independence (§4, §10).

**Optional suggestions, both adopted:** bootstrap-distribution and tail-influence diagnostics for 1663 (§5C 25); the gap identity g_t = p_t(1 − G^S_t) (§5C 26, and cited for H4-ES in §1).

**Questions put to Codex in v1 and how they were resolved:**
1. H4 as magnitude: accepted by Codex (change 4).
2. Point rows without inference: accepted for recorded households only (change 7).
3. Conjunction readings: H2-max removed (change 1); Codex raised no objection to the four-year conjunction for H2-rise, which remains a card reading (§10).
4. Within-year independent bootstrap: judged inadequate as the primary design (change 3); replaced by the cluster design.

## 10. Known limitations at freeze
1. **No original code.** Every central estimate comes from the independent rebuild. The zero-exclusion mechanism behind 0.501 (C1), and hence the "original analysis" that fixes the §0 classification, is inferred from an exact reproduction, not from code.
2. **Unvalidated linkage.** The cluster key is a coarse name key, not a validated household link, and it is not a coarsening of true identity. Missed links (spelling variants, changed given names, widows recorded under their own given names) leave some dependence unmodelled, and common year shocks are not modelled at all. Primary inference is conditional on independence across key clusters.
3. **H2-max removed with S5 in view.** The removal follows Codex's wording argument, but the S5 numbers suggested the 19-contrast gate would fail (1702 at 0.639), so the change favours confirming H2 (§7). S-0 reports the ranking.
4. **H2-rise turns on 1663.** S5 found 1709 vs 1663 not significant at 5% under independence (p 0.10–0.11 on the rebuild). The four-year conjunction is a card reading made with this in view; the 1663 farmer sample is 24 households, all in the Cape district. The pooled and mean initial-period contrasts are §5B only.
5. **Point rows carry no inference** and are largely determined by numbers already seen: H1's central value (0.527) lies 0.004 inside its band, so the zero-handling correction is decisive for H1; H2-pt (0.647) and H3-pt (0.626) lie inside theirs. The 0.501 alternative is §5B item 5.
6. **H4 and A4b.** Codex accepted the magnitude reading, but it was first adopted after the S5 mean was seen, and the two A8 readings give different answers on the S5 point (magnitude: above the 0.10 floor; point band: outside [0.18, 0.22]). Because m is fixed by the precheck, the H4 verdict turns on inference alone; the A4a credible null cannot decide it.
7. **Failure and Monte Carlo rules can make a row not-testable** (failure-bounded disagreement; unresolved MC uncertainty). Both rules are symmetric, and neither has been tried on data.
8. **What the intervals omit.** Transcription error, unrecorded assets, missing returns, the non-numeric coding (F2) and district coverage (C4) enter only through §5.
9. **H4-w window.** "The course of the eighteenth century" is read as the census years 1700–1757; the full-period slope is §5B item 19.
10. **H4-ES, W-lvl and W-cause are not-testable**, so the card cannot assess the paper's Engerman–Sokoloff reading or its causal attributions.
