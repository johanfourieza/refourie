# Method card: P03_BoF17, when South African markets integrated into the global economy

Status: v3 (2026-10-12), final revision; FREEZE under A9 on commit.
- History: v1 → Codex review (reviews/P03_BoF17_codex_S6card.md; 8 required changes, 2 optional) → v2 → Codex compliance check (reviews/P03_BoF17_codex_S6card_v2.md; 5 blocking issues) → v3 (this version). No further review round (A9).
- Margins follow AMENDMENTS.md A3, A4, A8 and A8a. No ceilings, no bands or gates chosen after S5 results. No modern estimate has been run.
- Rights class: see `registry/rights.csv`; all scripts run locally on D:.

## 0. Type of analysis
One primary analysis per claim; only it decides the verdict. Sensitivities never vote. No analysis code survives (S1, S2). The card rests on the surviving Excel workings where they exist and on the S3 rebuild (`repro_r/`) otherwise.

- **H1–H3 (annual SA–UK trend correlations): (ii) inference-only upgrade (A4b).** The point estimates are the authors' own statistics, recomputed from the in-sheet trend series (S5-01). Only the inference changes: a dependence-aware block-bootstrap interval replaces the unstated conventional test (S5-02). **"Overturned" and "strengthened" are unreachable for H1–H3.**
- **K1–K2 (Kimberley short-run correlations): (i) the stated-method rebuild from raw data, with dependence-aware inference.** The rebuild differs from the printed values for reasons S5 could not resolve (S5-03, S5-04), so A4b's premise (unchanged point estimate) fails. The A3/A4 ladder applies, including the A4a credible null. **"Strengthened" is unreachable** for any row (see §8): no row has a more credible design with a tighter interval on the same estimand, and a larger point estimate does not count (PROTOCOL).
- **K3–K4 (Kimberley bounds tests): (i) correction of a verified specification defect (F03) plus declared rules for unstated choices, and the standard companion tests of the same conditional ECM.** The model is the authors' (PSS 2001 conditional ECM, Case III). No new estimand is introduced. The ladder is confirmed / qualified / weakened: a non-rejection is not evidence of no relationship, so "overturned" is unreachable.

Not (iii): no measurement-uncertainty model is propagated. A4c does not apply: no odds ratios or probability statements. A4d applies: every analysis that changes the population (Cape-only series, subperiods, other split years, interpolated months) is a sensitivity and never votes. A8a does not apply (no share on [0, 1]). Clustering, PPML and weights are inapplicable.

## 1. Claims family (headline rows, frozen at S0) and interpretations
Six headline rows (`claims.csv`, headline = 1), plus the comparative row H3 (the authors' joint reading of the two text rows). The star legend is * 10%, ** 5% (`stars05.txt` = 2), so one star means significant at 10% only.

**What each row assesses (narrowed after review).** H1–H3 assess the **correlation of the >8-year trend components** of the SA and UK annual wheat-price series, conditional on a split at 1872 that the authors chose by inspection. They do not assess price integration, arbitrage, causation by the mineral revolution, or the *onset* of integration. K1–K2 assess correlations in **the stated-method reconstruction of the Kimberley sample from the surviving raw data**; the published sample is unknown (S5-03), so equivalence of populations is not asserted. K3–K4 assess whether the specified conditional ECM supports a levels relationship; they do not assess arbitrage or Kimberley's comparative standing.

| id | claim_id | published | authors' reading (verbatim where possible) | wording type |
|---|---|---|---|---|
| H1 | `TXT_corr_pre` | 0.05 | "between 1836 and 1871 it is a positive but statistically insignificant 0.05"; "no integration before the diamond discoveries" | null claim; judged as an equivalence-to-zero claim on the A3/A4a band ±0.5·0.05 |
| H2 | `TXT_corr_post` | 0.86 | "between 1872 and 1913 it changes to a positive and statistically significant 0.86, suggesting strong co-movement between the South African and UK prices" | magnitude claim (coefficient), A3/A4 |
| H3 | derived from H1 and H2 | 0.81 (= 0.86 − 0.05) | "it changes to …": the trend correlation is higher after 1872 than before | comparative claim "A > B", A8 |
| K1 | `T1_r11_c1` | 0.27* (0.17) | Kimberley wheat co-moves with Cape Town in the short run | magnitude claim (coefficient), A3/A4 |
| K2 | `T1_r11_c2` | 0.30* (0.17) | the same for mealies (maize) | magnitude claim (coefficient), A3/A4 |
| K3 | `T2_r1_c1` | F = 5.09* | "there was a long-term relationship between Kimberley's wheat … prices and those of Cape Town" | test claim: bounds test significant at the paper's 10% level |
| K4 | `T2_r1_c2` | F = 8.17* | the same for maize | test claim, as K3 |

**Summaries (reported, no verdict of their own).** For each of H-summary (H1–H3), K-SR (K1–K2) and K-LR (K3–K4), the report gives the member verdicts, the coverage (members assessed, not-testable) and the weakest assessed verdict, ordered overturned < weakened < qualified < confirmed. Summaries are not aggregated further and a not-testable member is reported as such, not ranked.

**Not testable with the surviving data or not a headline row (recorded, no verdict).**
- The causal attribution to the mineral revolution ("it seems", "immediately following"): one break chosen by inspection, no counterfactual.
- Kimberley as "the key market" among rail-connected towns: no comparative estimand is in the claims.
- "Much higher" long-run than short-run correlation for Kimberley (S5-12, F06): no long-run correlation magnitude exists.
- The abstract's Eastern Cape statement and the Graaff-Reinet cross-reference (S5-09, S5-10): not headline rows.

## 2. Defects addressed
1. **Overstated significance of the annual correlations (S5-02, C10).** Both series are >8-year low-pass trends with strongly autocorrelated values; a conventional test on 36 and 42 annual observations treats roughly 5–10 effective observations as 36–42. Sources: Granger and Newbold (1974); Afyouni, Smith and Elliott (2019, *NeuroImage*) on the variance of correlations between autocorrelated series; Künsch (1989) and Liu and Singh (1992) on the moving-block bootstrap.
2. **Undisclosed filtering (S5-01, F01).** The printed statistics correlate CF-filtered trends, not log prices. The card keeps the authors' computed estimand and reports the described one (log levels) as a changed estimand.
3. **Unreproducible Table 1 and its unstated test (S5-03, S5-04, S5-06, C1).** The rebuild from raw data with the stated method is the baseline; the interval is dependence-aware.
4. **Unstated bounds-test specification (S5-05, S5-07, F03, C9).** The lag order, dependent variable, sample and critical values are unstated; F ranges from 0.25 to 8.56 across reasonable choices; the S3 rebuild omitted the contemporaneous ΔCape Town term. Sources: Pesaran, Shin and Smith (2001); McNown, Sam and Goh (2018, *Applied Economics*) on the bootstrap ARDL test with its three companion statistics; Goh and McNown (2015) on degenerate cases.
5. **Multiplicity.** Seven inferential statements are made about one narrative; none is adjusted.

## 3. Estimands
- **H1, H2. Original = new.** Pearson correlation between the SA and UK trend components of annual log wheat prices (trend = log price minus its Christiano–Fitzgerald 2–8-year cycle), over 1836–1871 (H1, n = 36) and 1872–1913 (H2, n = 42). SA = Cape + Natal (De Zwart 2011); UK = equal-weight mean of 12 cities (Jacks 2006). Data: in-sheet columns `'SA & UK graphs'!E2:F79` of the Nov 2015 `Globalisation data.xlsx` (year C, SA trend E, UK trend F), the cells the printed CORREL formulas use. Stationarity of each trend within its period is an **assumption**, not tested; the trends are smooth and may contain a deterministic drift component. The described estimand (correlation of unfiltered prices) is reported in §5A as a changed estimand.
- **H3.** ρ_post − ρ_pre of the H1/H2 estimand, conditional on the 1871/1872 split.
- **K1, K2.** Pearson correlation of consecutive-month log first differences of the Kimberley and Cape Town price of the same product, monthly grid January 1897 – December 1906 (120 months), from `AgrPriceData 1.3.xlsx` sheet `South Africa_original` as parsed by S3 (`repro_r/01_clean.R`; panel at `dpath("P03_BoF17","repro_r","_scratch","panel_raw.rds")`). A difference is defined only between consecutive calendar months; no interpolation. This is the estimand in the Table 1 title. The S3 sample (n = 78 wheat, 76 mealies) is the stated-method sample.
- **K3, K4.** PSS (2001) conditional ECM, Case III (unrestricted intercept, no trend), k = 1:
  Δy_t = c + θ_y y_{t−1} + θ_x x_{t−1} + Σ_{i=1..p} φ_i Δy_{t−i} + ψ_0 Δx_t + Σ_{j=1..q} ψ_j Δx_{t−j} + e_t,
  y = Kimberley log price, x = Cape Town log price, same product, same monthly grid. Every lag is a true calendar-month lag; rows with any missing term are dropped (no interpolation). The three statistics: **F_ov** (H0: θ_y = θ_x = 0), **t_dep** (t on θ_y, H0: θ_y = 0), **F_ind** (H0: θ_x = 0). A levels relationship is supported only if all three reject (McNown, Sam and Goh 2018), which rules out the degenerate cases in which F_ov alone rejects.

## 4. Primary analysis: the central analysis

**Multiplicity families (A3: 95% familywise).**
- **Family C: {H1, H2, H3, K1, K2}**, the five correlation-interval claims of one integration narrative. Bonferroni over 5, α = 0.01 per claim (99% two-sided). H3 is a difference of two correlation estimators and is calibrated by its own component levels (see H3 below), so that its 99% interval is valid by Bonferroni over four one-sided component bounds.
- **Why two families.** Family C holds claims about the magnitude of correlations, judged by interval estimates; Family F holds existence tests whose error rate is controlled by an intersection-union test. The verdicts of the two families are not pooled and neither feeds the other, so the error rates controlled differ in kind. The price is that error is not controlled across all seven claims at once; a single Bonferroni over seven (α = 0.05/7) is displayed as a sensitivity (§5D) and the limitation is recorded (§10.9).
- **Family F: {K3, K4}**, the two bounds-test claims. Each claim is an intersection of three tests, each at α = 0.025 (a size-valid intersection-union test); Bonferroni over 2 claims gives 2.5% each for 5% familywise error. The paper's own 10% level is kept as the unadjusted level in the verdict tables.

**One interval procedure for every correlation claim: the moving-block bootstrap of paired rows.**
Justification: r is a smooth function of sample moments, so the moving-block bootstrap (Künsch 1989; Liu and Singh 1992) is consistent for weakly dependent stationary pairs and preserves both serial dependence and the cross-dependence of the pair; it needs no estimate of an effective sample size and no independence assumption between x and y. **Limits:** it assumes stationarity within the sample, and with 5–10 effective observations its percentile intervals are approximate and probably too narrow (see §10); no method recovers information the smoothed series do not contain.
1. Series of N paired rows (H1: N = 36; H2: N = 42; K1/K2: the 120-month grid of differences, NA rows kept).
2. Block length ℓ: **8 years** for H1/H2 (the >8-year low-pass band of the trend series implies dependence over at least that span) and **12 months** for K1/K2 (one seasonal cycle). Both are fixed by the construction of the series, not by S5 numbers; other values are sensitivities (§5).
3. Draw ⌈N/ℓ⌉ block start indices uniformly from 1…N − ℓ + 1 (overlapping, non-wrapped blocks), concatenate, truncate to N, and compute r on complete pairs. B = 9,999; seed 20261012 (`set.seed(20261012, kind = "L'Ecuyer-CMRG")`), re-seeded at the start of each claim.
4. Interval: percentile (type-7 quantiles of r*) at the family level (0.005/0.995) and at the unadjusted 95% (0.025/0.975). Reported: r, N, n_complete, ℓ, both intervals.
5. **Undefined draws (symmetric failure rule).** A draw is undefined if r* is undefined (zero variance) or, for K1/K2, fewer than 10 complete pairs (a conventional minimum for a correlation; the S3 samples of 76–78 pairs were known, so the gate does not bind and is not tuned). Intervals use defined draws; the failure rate is reported. If it exceeds 0.025% (more than 2 of 9,999 draws; one-tenth of the smallest tail probability used anywhere in the card, 0.25% for the H3 component bounds, fixed before any bootstrap was run), the claim is not-testable whatever the direction of the estimate.

**H1, H2.** Read the in-sheet series; split at 1871/1872. **Reproduction check:** r_pre and r_post must equal 0.0530 and 0.8581 to 4 dp, else stop and report (not-testable). Interval by the common procedure.

**H3: difference of the two correlations, valid under any dependence across the split.** The two periods are disjoint stretches of one filtered series, so their estimators are not independent: the filter and the series' persistence link observations on either side of 1872. The card does not model that covariance. It uses the Zou (2007) MOVER interval with the correlation between the two estimators set to its most adverse value, −1, which gives a bound valid whatever the dependence: with (l₁, u₁) for r₁ = r_post and (l₂, u₂) for r₂ = r_pre from the common procedure,
L = (r₁ − r₂) − (r₁ − l₁) − (u₂ − r₂) = l₁ − u₂, U = u₁ − l₂.
Coverage is set by Bonferroni, not by the dependence assumption: the difference interval [L, U] misses only if one of four one-sided component bounds (lower and upper, for each period) misses. For the 99% family interval each component bound is therefore taken at one-sided probability 0.0025, i.e. the component percentile interval at (0.0025, 0.9975); for the unadjusted 95% bound L95, at one-sided probability 0.0125, i.e. (0.0125, 0.9875). These component intervals are computed in the H3 step only; the H1 and H2 verdicts use their own 99% and 95% intervals. (The bound is conservative; the independent-periods interval, with ρ = 0, is a sensitivity.) **Inference is conditional on the historically chosen split**; the interval does not account for the choice of 1872 and the row does not identify when integration began.

**K1, K2.** Build x = Δlog Cape Town and y = Δlog Kimberley on the 120-month grid (consecutive months only), then set both to NA wherever either is NA. **Reproduction check:** r and n must equal the S3 values (0.3774, 78; 0.0508, 76) to 4 dp, else stop and report. Interval by the common procedure. Because the bootstrap resamples calendar blocks including their missing-data pattern, no lag-specific pair counts or autocorrelation estimates enter the primary analysis.

**K3, K4: bootstrap ARDL bounds procedure (McNown, Sam and Goh 2018), the whole procedure repeated in every replicate.**
*Observed data.*
1. Candidate set: p ∈ {0, 1, 2, 3} lagged Δy, q ∈ {0, 1, 2, 3} lagged Δx, with Δx_t always included (16 models).
2. Selection: AIC (`stats::AIC` on `lm`) over the **common sample** of rows complete for p = q = 3. Ties: fewer parameters, then smaller p.
3. Re-estimate the selected (p, q) on its own maximal complete-case sample, size n_K, residual df d_K. Compute F_ov, t_dep, F_ind (`anova` of nested `lm` fits; t from the `lm` summary). If d_K < 20 the claim is not-testable. (Gate provenance: the 20-df floor is a conventional minimum for finite-sample OLS tests with about eight parameters, set a priori. The S3 sample sizes of 68 and 66 rows were already known, so the floor does not bind and could not have been tuned to exclude a result.)

*Bootstrap critical values.*
4. Null DGP. Under H0 (θ_y = θ_x = 0) the y equation has no levels terms; the marginal x equation is left **unrestricted in levels**, as in McNown, Sam and Goh (2018), so that x may be I(0) or I(1). Fit by OLS, each on its own complete-case sample (rows with all terms observed on the calendar grid):
 Δx_t = a_x + λ_x x_{t−1} + λ_y y_{t−1} + Σ_{i=1..3}(α_i Δx_{t−i} + β_i Δy_{t−i}) + u_xt,
 Δy_t = a_y + γ Δx_t + Σ_{i=1..3}(φ_i Δy_{t−i} + ψ_i Δx_{t−i}) + u_yt.
 Residuals carry their calendar month. The resampling pool is the set of calendar months at which **both** residuals exist; the pair (û_x, û_y) of one month is drawn jointly (iid, with replacement, after centring each residual over the pool), which preserves the contemporaneous correlation. Months with only one residual are not in the pool.
5. Each replicate: from zero initial lags and levels, generate 50 + 120 consecutive calendar months recursively (x_t from its equation, then Δy_t given the generated Δx_t, y_t = y_{t−1} + Δy_t), **discard the first 50 months** (presample), and keep the remaining 120 as the replicate grid. The presample is discarded **before** masking, so every lag needed at grid month 1 onward exists in the generated series. Then apply the observed missingness mask separately to y and x (a month missing in the data is missing in the replicate); masked months are dropped from estimation exactly as in the observed data (a row is used only if all its true calendar-month lags are present). Then **repeat steps 1–3 completely** (AIC selection over the 16 models on the common sample, maximal-sample refit, F_ov, t_dep, F_ind).
6. B = 9,999, seed 20261012. Critical values: the 97.5%, 95% and 90% quantiles of F_ov* and F_ind* (type 7) and the 2.5%, 5% and 10% quantiles of t_dep*. A replicate with no estimable model or d_K < 20 is undefined; the same 0.025% failure rule as above applies (above it, the claim is not-testable).
7. **Monte Carlo precision and unresolved boundaries.** The MC SE of a critical value is the SD of its value over 10 consecutive batches of replicates, divided by √10. If any observed statistic lies within 2 MC SE of a critical value that decides the verdict, B is raised to 99,999 with the same seed, and the result is reported at that budget. If it is still within 2 MC SE, the verdict follows the strict comparison computed at 99,999 and is flagged "boundary unresolved".

*Pre-specified validity diagnostics on the selected model (observed data only; they enter the verdict table as conditions for "confirmed", not as discretionary gates).*
- **D1, integration order (no I(2)).** `urca::ur.df(type = "drift", selectlags = "AIC", lags = 6)` on Δy and on Δx, each on its longest gap-free run (a run shorter than 30 months, about two seasonal cycles plus lags, counts as not passed: a conventional gate set a priori); both must reject a unit root at 5%. Levels are not required to be I(1): the bounds test is agnostic about I(0)/I(1).
- **D2, residual autocorrelation.** Breusch–Godfrey LM test of order 12 on the selected model's residuals, placed on the calendar grid with missing lagged residuals set to 0; p ≥ 0.05.
- **D3, weak exogeneity of Cape Town.** The Δx_t equation of step 4 is augmented with ECT_{t−1} = y_{t−1} − β̂ x_{t−1}, β̂ = −θ̂_x/θ̂_y from the selected model; the t-test on the ECT coefficient must not reject at 5% (p ≥ 0.05).
- A diagnostic that cannot be computed (run shorter than 30 months, θ̂_y = 0) counts as not passed. This can only prevent "confirmed", never create it.

*Reported.* (p, q), n_K, d_K, the three statistics, all critical values at 2.5%, 5% and 10% with MC SE, the AIC table, D1–D3, and the printed Narayan bounds [4.29; 5.08] for display.

**Runtime.** Correlation bootstraps: seconds. Bounds bootstrap: 2 × 9,999 replicates of about 20 small OLS fits (minutes); the 99,999 re-run, if triggered, under an hour. No LLM API cost.

## 5. Sensitivities (exhaustive; reported, never verdict-setting)
Each group is split into **admissible sensitivities** (reasonable alternatives; the only ones that enter any range or share) and **error documentation** (S5 defects shown to explain the published numbers; excluded from every range and share).

**5A. H1–H3.**
*Admissible.*
1. Block length ℓ ∈ {4, 12} instead of 8.
2. Pyper and Peterman (1998) effective-N Fisher-z interval: 1/N* = 1/n + (2/n) Σ_{j=1..L} ((n − j)/n) ρ̂_xx(j) ρ̂_yy(j), L = ⌊n/5⌋, N* capped at n (annual series have no gaps, so ρ̂ from `acf` is well defined); and Bretherton et al. (1999) N* = n(1 − a_x a_y)/(1 + a_x a_y).
3. Ebisuzaki (1997) phase-randomisation test of r = 0 for each period, 999 surrogates of the SA trend, seed 20261012; p-value only.
4. H3 with independent periods (ρ = 0 in the MOVER formula).
5. Same estimand from raw data: the S3 annual series with the CF 2–8-year cycle removed (`mFilter::cffilter(x, pl = 2, pu = 8, root = TRUE, drift = TRUE)`), UK 1866 linearly interpolated (S5-11).
6. Descriptive split-year scan, 1860–1885: r_post − r_pre with block-bootstrap intervals for each split year, to show how much the answer depends on the chosen break.
7. Changed estimands: log levels (S3: 0.072/0.822); Fig 3 medium-term 8–50-year cycle (0.16/0.52); UK as mean of logs.
8. Changed populations (A4d): Cape-only SA series (−0.03/0.83); split after 1874 (in-sheet 0.052/0.853).
*Error documentation.* Annual first differences computed across the missing UK 1866 observation (0.0017 vs 0.212 with the step removed; S5-11, F02).

**5B. K1–K2.**
*Admissible.*
1. Block length ℓ ∈ {6, 24} instead of 12.
2. Conventional iid SE (S3) and unadjusted Fisher-z SE 1/√(n − 3).
3. Pyper–Peterman N* on the monthly grid with lag-specific available-pair counts: ρ̂_xx(j) = Σ_{t: x_t, x_{t−j} observed} (x_t − x̄)(x_{t−j} − x̄)/(n_j s²_x), n_j the number of such pairs; ρ̂(j) = 0 where n_j < 5; L = ⌊n/5⌋.
4. The surviving 2013 `Mealies analysis.xlsx` value for Kimberley mealies (0.186, n = 74), descriptive.
5. Deseasonalised differences (month dummies), a changed estimand.
6. Linear interpolation of gaps; subperiods 1897–1901 and 1902–1906 (changed data or populations, A4d).
*Error documentation.* Differences computed across gaps (S5 variant); the printed Table 1 cells themselves (unreproducible, S5-03).

**5C. K3–K4.**
*Admissible.*
1. Fixed-lag grid p = q ∈ {1, 2, 3}, with Δx_t, under the same bootstrap.
2. BIC instead of AIC.
3. Cape Town as the dependent variable.
4. Linearly interpolated gaps (A4d).
5. Asymptotic PSS Case III bounds (k = 1) for F_ov and t_dep.
6. Bootstrap with the null DGP's residuals drawn as a moving block of ℓ = 12 months rather than iid.
7. The central F_ov against the printed Narayan bounds [4.29; 5.08].
*Error documentation (not in any share).* The S3/S5 fixed-lag grid p = q ∈ {0, …, 3} **without** Δx_t (the F03 omission), including the zero-lag specification; the S3 one-lag F of 3.02/3.80.
*Scenario display.* For the admissible items 1–4 only, the range of F_ov and the share of scenarios in which all three tests reject at 2.5%, labelled "assumption-conditional; equal weights are not probabilities".

**5D. Multiplicity.** All seven claims in one Bonferroni family (α = 0.05/7 per claim; for K3–K4 the per-test level is a third of that); display of which verdicts change. Admissible, never verdict-setting.

## 6. Fixed choices
- No weights; no trimming; no bandwidths beyond the CF band fixed by the in-sheet series (H1–H3), ℓ (§4) and the lag grid.
- Missing data: no interpolation in any central analysis; complete pairs only (K1–K2); complete rows only (K3–K4).
- Verdict comparisons use unrounded values; reporting to 3 dp (F to 2 dp).
- Seeds: 20261012. Scripts: `modern/01_corr_boot.R` (H1–H3, K1–K2), `02_bounds_boot.R` (K3–K4), `03_sensitivities.R`, `04_verdicts.R`.
- Boundary rules: L = 0 or U = 0 counts as the interval including 0; the credible-null band is open (L = −f or U = f is not a credible null); |b| = f meets the floor; a critical value equal to the statistic is not a rejection.

## 7. Margins and their provenance (A8 defaults unless stated)
| Claim | Type | Margin | Provenance |
|---|---|---|---|
| H1 | null claim, b₀ = 0.05 | 99% interval inside (−0.025, 0.025) is practical equivalence to zero (confirmed, even if it excludes 0); otherwise excluding 0 contradicts the claim | A3/A4a band applied to the stated coefficient, as the review requires; no S5 number used |
| H2 | magnitude, b₀ = 0.86 | 99% interval excludes 0, same sign, r ≥ 0.43 | A3 |
| H3 | comparative ">" | ρ_post − ρ_pre > 0, 99% bound excludes 0 | A8 |
| K1 | magnitude, b₀ = 0.27 | f = 0.135: L > 0, r ≥ 0.135; credible null if the interval ⊂ (−0.135, 0.135) | A3/A4a |
| K2 | magnitude, b₀ = 0.30 | f = 0.15, as above | A3/A4a |
| K3, K4 | test claim | all three bootstrap tests reject at 2.5% each (family), plus D1–D3 | **departure from A8's "threshold is T itself"**, justified below |

- **No ceilings.** Plausibility flags (reported, not verdict-determining): |r| > 0.075 for H1; r > 1.29 for H2 (cannot occur); r > 0.405 (K1) and r > 0.45 (K2).
- **Wording-based departure (K3, K4), for Codex acceptance.** The printed T = 5.08 is the Narayan n = 30 upper bound (S5-07). The claim's content is that a long-term relationship exists, supported by a bounds test significant at 10%. Comparing F with 5.08 would test the table's n = 30 row, not the claim. The card therefore applies the authors' rule (reject when the statistic exceeds the bounds-test critical value) at the actual sample, with the standard companion tests, at the family-adjusted level A3 requires. The comparison with 5.08 is displayed (§5C.7).
- **H1 consequence, known ex ante.** The in-sheet r_pre = 0.0530 already exceeds the 0.025 band, so a 99% interval inside the band is nearly unreachable and H1 will almost surely be qualified or weakened, whatever the bootstrap shows (an interval narrower than 0.05 around a point estimate of 0.053 would be needed, which is essentially unreachable). The band follows the A3/A4a default; the card does not loosen it.

## 8. Verdict rules (central analysis only; first applicable row decides; exhaustive and mutually exclusive)
Notation: r = central estimate; [L, U] = 99% family interval; [L95, U95] = unadjusted 95% interval; f = 0.5|b₀|. "Reproduction check" and "failure rate" are as in §4.

**H1 (null claim; A4b: overturned and strengthened unreachable).**
| # | Condition | Verdict |
|---|---|---|
| 0 | reproduction check fails, r undefined, failure rate > 0.025%, or \|r\| = 1 | not-testable |
| 1 | −0.025 < L and U < 0.025 (practical equivalence to zero shown; takes precedence over row 2) | confirmed |
| 2 | L > 0 or U < 0 (significant pre-split association, not inside the band) | weakened |
| 3 | any other case (L ≤ 0 ≤ U, equivalence not shown) | qualified (insignificant, but a null is not demonstrated) |

Rows 1 and 2 are mutually exclusive by this ordering: an interval wholly inside ±0.025 that excludes 0 is confirmed under practical equivalence, because the claim is "no more than a negligible association".

**H2 (magnitude; A4b: overturned and strengthened unreachable).** r is fixed by the in-sheet series (0.8581 ≥ 0.43), so the floor holds mechanically; it is still checked.
| # | Condition | Verdict |
|---|---|---|
| 0 | as H1 row 0 | not-testable |
| 1 | r ≥ 0.43 and L > 0 | confirmed |
| 2 | r ≥ 0.43, L ≤ 0 and L95 > 0 | qualified (inference-fragile) |
| 3 | any other case (including r < 0.43 or L95 ≤ 0) | weakened |

**H3 (comparative; A4b).** L, L95 from the ρ = −1 MOVER bound (§4).
| # | Condition | Verdict |
|---|---|---|
| 0 | H1 or H2 row 0 applies | not-testable |
| 1 | L > 0 | confirmed |
| 2 | L ≤ 0 and L95 > 0 | qualified (inference-fragile) |
| 3 | any other case (including U < 0) | weakened |

**K1, K2 (magnitude; A3/A4 ladder without "strengthened").**
| # | Condition | Verdict |
|---|---|---|
| 0 | reproduction check fails, n < 10, r undefined, \|r\| = 1, or failure rate > 0.025% | not-testable |
| 1 | U < 0 | overturned (opposite sign supported) |
| 2 | −f < L and U < f | overturned (credible null) |
| 3 | L > 0 and r ≥ f | confirmed |
| 4 | L > 0 and r < f | qualified (magnitude below floor) |
| 5 | L ≤ 0 and L95 > 0 | qualified (inference-fragile) |
| 6 | any other case | weakened |

**K3, K4 (test claim; confirmed / qualified / weakened).** Let "all three reject at α" mean F_ov > its upper critical value, F_ind > its upper critical value and t_dep < its lower critical value at level α of the bootstrap distributions. Unadjusted level 10% is the paper's stated level.
| # | Condition | Verdict |
|---|---|---|
| 0 | no model estimable, d_K < 20, failure rate > 0.025%, or any statistic undefined | not-testable |
| 1 | all three reject at 2.5%, and D1, D2 and D3 pass | confirmed |
| 2 | all three reject at 2.5%, and any of D1–D3 fails or is unavailable | qualified (specification diagnostic) |
| 3 | all three reject at 10% but not all at 2.5% | qualified (inference-fragile) |
| 4 | any other case, including F_ov rejecting alone (degenerate case) | weakened |

"Overturned" is unreachable: a failure to reject is not evidence of no relationship. "Strengthened" is unreachable for every row.

**Summaries.** As in §1; reported, not aggregated further.

**Supplementary display.** Each verdict is shown with its §5 results, labelled "sensitivity; never verdict-setting". Error-documentation items are shown separately and enter no range or share.

**Disclosure.** S4/S5 numbers bearing on these claims were seen before this card was written.
- **H1/H2.** In-sheet trend correlations 0.0530/0.8581; raw rebuild 0.047/0.859; split after 1874 0.052/0.853; Pyper–Peterman N* = 10.3 (pre) and 5.2 (post), p = 0.88 and 0.055; conventional p = 4e−13 (post); log levels 0.072/0.822; first differences 0.0017 (0.212 with the 1866 step removed)/0.165; medium-term cycles 0.16/0.52 (adjusted p = 0.056); Cape-only −0.03/0.83.
- **K1/K2.** Rebuild 0.3774 (n = 78) and 0.0508 (n = 76); wheat 0.366–0.401 and mealies 0.007–0.081 across six variants; 2013 workbook mealies 0.186 (n = 74).
- **K3/K4.** S3 one-lag F 3.02/3.80; with Δx_t added 4.574/4.108; zero lags 6.668/7.364; 16-specification ranges 0.25–7.38 and 2.08–8.56. The bootstrap critical values, AIC-selected lags and the companion statistics have not been computed.

No block-bootstrap interval has been computed. The v1 draft used the Pyper–Peterman N*; v2 replaced it with the block bootstrap because Codex found the N*-Fisher interval unjustified, not because of any new result. The direction of some verdicts can still be guessed from the disclosed numbers (H1 cannot be confirmed, §7; K2's rebuild of 0.05 is below f = 0.15), so the card is not outcome-blind for them. All margins are A3/A4/A8 defaults except the flagged K3–K4 departure. This disclosure does not prove that nothing was tuned.

## 9. Codex review notes and responses
**Codex v1 review** (reviews/P03_BoF17_codex_S6card.md): approve-with-changes, 8 required changes, 2 optional. Responses:
1. **N*-Fisher intervals (§4).** Replaced by one covariance-aware procedure for every correlation claim, the moving-block bootstrap of paired rows, with its stationarity assumption, block-length rationale and small-sample limits stated (§4, §10). N* methods demoted to sensitivities (§5A.2, §5B.3).
2. **H3 independence.** The independence assumption is removed. H3 uses the Zou MOVER interval with the between-estimator correlation set to −1, valid under any dependence across the split; the ρ = 0 interval is a sensitivity. Inference is stated as conditional on the chosen 1872 split and not as evidence of when integration began; a split-year scan is displayed (§4, §1, §5A.4, §5A.6).
3. **Interpretation (§§1, 3).** Rows now assess the correlation of >8-year trends, K1–K2 assess the stated-method reconstruction of an unknown published sample, and K3–K4 assess levels-relationship support. The "key market" statement is recorded as not testable; arbitrage, causation and onset are not assessed.
4. **H1 band.** The bespoke 0.43 band and the upper-bound-only rule are deleted. Non-rejection is separated from equivalence: confirmed requires the 99% interval inside ±0.025 (the A3/A4a coefficient default on b₀ = 0.05); non-rejection without equivalence is qualified. The mechanical consequence is disclosed (§7, §10). A8a is not applied.
5. **Bounds calibration (§4).** The bootstrap simulates the calendar grid and the observed missingness mask, keeps a 50-month presample, and repeats AIC selection and maximal-sample refitting in every replicate. The n < 30 gate is replaced by an estimability rule (d_K < 20), justified on its own terms.
6. **Long-run primary.** One procedure is predefined: the McNown–Sam–Goh bootstrap ARDL test with F_ov, t_dep and F_ind, with diagnostics D1 (integration order), D2 (residual autocorrelation) and D3 (weak exogeneity) fixed in advance as conditions for "confirmed". The bootstrap algorithm is specified in full (§4).
7. **Verdicts and multiplicity.** "Strengthened" is removed from every table. H1–H3 keep A4b's restricted ladder; K1–K2 keep overturned (their point estimate differs) and K3–K4 never reach overturned. Family C is justified (one narrative, five correlation claims); Family F uses 2.5% per claim for 5% familywise error. Tables have explicit failure rows and are exhaustive.
8. **Sensitivities.** Error documentation is separated from admissible sensitivities; only admissible items enter any range or share. The monthly N* sensitivity defines lag-specific pair counts and undefined-ρ handling (§5B.3); the primary no longer uses `acf(na.pass)`.

Optional suggestions: (1) MC uncertainty at the final budget and unresolved-boundary handling are specified (§4 step 7). (2) One primary per claim is kept; clustering, PPML and weights are marked inapplicable (§0).

**Codex v2 compliance check** (reviews/P03_BoF17_codex_S6card_v2.md): revise-again, 5 blocking issues. Responses in v3:
1. **Bounds DGP.** The x equation is unrestricted in levels (McNown, Sam and Goh 2018); residual pairs are pooled over calendar months where both exist; the presample is generated and discarded before the mask is applied (§4 steps 4–5).
2. **H3 coverage.** Component intervals are taken at one-sided 0.0025 (family) and 0.0125 (unadjusted), so Bonferroni over four bounds gives 99% and 95% (§4).
3. **H1 precedence.** Practical equivalence takes precedence; rows reordered, §7 reconciled (§8).
4. **Gates.** The 20-df, 10-pair and 30-month gates are stated as a-priori conventions, known not to bind; the failure threshold is corrected to 0.025% (one-tenth of the smallest tail used, 0.25%).
5. **Multiplicity.** Separate families justified substantively; a pooled seven-claim Bonferroni is a displayed sensitivity (§5D).

## 10. Known limitations at freeze
1. **Very few effective observations.** The annual trend correlations rest on perhaps 5–10 effective observations. Block-bootstrap percentile intervals are approximate and probably too narrow at that size, and the within-period stationarity assumption is untested. Block length ℓ = 8 is a construction-based choice with about 4–5 blocks per period.
2. **H3 is conservative and conditional.** The ρ = −1 bound is valid under any dependence but wide; the split at 1872 was chosen by inspection and its selection is not accounted for.
3. **H1 is nearly unreachable for "confirmed"** by construction (r_pre = 0.053 lies outside the ±0.025 band). The band is the protocol default; the consequence is accepted rather than tuned.
4. **The published Table 1 sample is unknown** (S5-03). K1–K2 judge the claim on the stated-method sample, about 1.7 times the size the printed SEs imply; if the authors used another data version the card cannot reach it.
5. **The bounds-test specification is unrecoverable.** AIC selection is a declared rule, not the authors' choice. The null DGP is a VAR(3) in differences with iid residual pairs, which may not reproduce the data's gaps, heteroskedasticity or price-level jumps. D1–D3 have low power on about 65 gap-containing observations. The 20-df floor is a convention.
6. **K3–K4 depart from A8's literal "threshold is T itself"** on wording grounds (§7); the Codex compliance check accepted the departure (5.08 is a critical value, not an economic threshold).
7. **The causal claim, the Eastern Cape abstract statement, the "key market" and "much higher" statements are not testable** with these data and receive no verdict.
8. **Not outcome-blind.** Several verdict directions can be anticipated from S5 numbers (§8 Disclosure).
9. **Multiplicity is controlled within, not across, the two families.** Familywise error over all seven claims is not controlled by the central analysis (§5D displays the pooled correction).
10. **Gate independence is not proven.** The 20-df, 10-pair and 30-month gates are a-priori conventions, but the sample sizes were known before they were written.
