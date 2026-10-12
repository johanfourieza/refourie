# Method card: P28_VFF, the great divergence in South Africa

Status: v2 (2026-10-11), revised after the Codex review (reviews/P28_VFF_codex_S6card.md). FROZEN with the commit message "FREEZE S6 card P28".

## 1. Claims family (frozen A1 union) and interpretations
- **I1, population persistence.** T2_r2_c6 (0.950***) and T2_r2_c7 (0.823***).
- **I2, post-apartheid homeland disadvantage, as partial associations.**
  - T3_r2_c1 (1996 unemployment, 0.522***)
  - T3_r2_c6 (2011 unemployment, 0.227***)
  - T3_r2_c9 and T3_r2_c10 (lights, −2.402*** and −2.025***)
- **I3, divergence since democracy.** The conditional *relative* luminosity of homeland districts fell between the two lights years. It is not a claim about absolute dimming, or about the wealth of any racial group, which the lights cannot distinguish.

**Scope.** These are cross-sectional partial associations. Spatial inference cannot establish institutional causation. The causal language is judged in S5, not here.

## 2. Defects addressed
S5 found:
- (a) iid SEs despite strong residual spatial autocorrelation;
- (b) exposure to spatial noise in a persistence design (Kelly 2019; 2021);
- (c) a degenerate uniform-kernel Conley estimator at long cut-offs;
- (d) night-lights year labels crossed between the analysis file and the authors' extraction shapefiles (provenance).

## 3. Estimands
The published OLS coefficients, unchanged (A4b: an inference-only upgrade for I1/I2, except where Step 0 relabels the lights). I3 is β_H(t2) − β_H(t1), the homeland coefficient on log lights, from one interacted model on the common 138-district sample. It uses the T3 column-10 specification (full controls, no migration), with every regressor and the intercept interacted with year.

## 4. Primary analysis
**Step 0, lights provenance (applies to T3 c9/c10 and to I3).**
- Source: the public DMSP-OLS v4 stable-lights annual composites F121996.v4b and F182011.v4c (NOAA/EOG or a documented mirror; record the URL and checksum).
- District value: the mean DN over pixels whose centres fall inside each 1911 polygon (the polygons in `P28_VFF/original/Reversal of Fortunes/1911_dc.shp`), with DN 0 included and no-data pixels excluded.
- Match the extracted values with the data.csv columns `lig96` and `lig11` on the 138 analysis districts, using Pearson correlation on logs (with +0.01 added).
- **Resolved:** one assignment has both correlations ≥ 0.99 and the crossed assignment has both < 0.95. Under that assignment, the T3 c9/c10 coefficients are recomputed with the correct year labels. Those estimates are then the "lights 2011" claims, and A4b no longer applies to them, because the point estimate may change.
- **Unresolved:** the lights claims in I2 are `not-testable (provenance)` and I3 is `not-testable`. Both labellings are reported.
- If resolved, an intercalibration sensitivity runs before the I3 verdict: the Elvidge et al. (2014) second-order coefficients for F12-1996 and F18-2011 applied to the pixel DN. The I3 verdict requires the same conclusion with and without intercalibration; otherwise it is qualified (calibration-sensitive).

**Spatial inference (all claims).**
- **Conley SE.** Bartlett kernel, cut-off 100 km, great-circle distance between WGS84 centroids of the 1911 polygons. No finite-sample correction. A non-PSD matrix is handled by clipping eigenvalues at 0. The implementation is the R code in `P28_VFF/compare/s5_checks/s5_checks.R`, which S5 validated against the authors' ado `bartlett` option to 3 dp. The 100 km cut-off is fixed by an external rule, not by S5 results: about twice the median nearest-neighbour centroid distance, rounded to 100 km. The median is reported.
- **Spatial-noise placebo, an additional gate (Kelly 2019).**
  - Residualise the key regressor (1911 density for I1, homeland share for I2) on the other regressors.
  - Fit an exponential covariance C(h) = σ²exp(−h/ρ) + τ²·1[h=0] by ML. Bounds: ρ ∈ [1, 2000] km. If the fit fails, use the variogram least-squares fit and report it.
  - Simulate R = 2,000 independent Gaussian series with the fitted covariance, using L'Ecuyer streams with seed 20261011.
  - Replace the key regressor with each series and re-estimate the full specification. Record |t| with Conley SEs.
  - placebo p = (1 + #{|t*| ≥ |t|})/(R + 1). Its Monte Carlo SE is reported. Uncertainty in the covariance parameters is not propagated, and this is stated as a limitation.
- **I3 inference.** The interacted model. The Conley Bartlett 100 km SE allows for dependence across districts and across the two years within a district: the district pair (i, j) at distance h gets weight w(h), and the same district across years gets weight 1.
- **Multiplicity.** Holm across the six coefficients (Conley p). I3 is a single separate test.

## 5. Admissible sensitivities (reported, not verdict-determining)
1. Conley at 50, 200 and 500 km.
2. HC1 (benchmark only).
3. Run A′ vintages.
4. For I1 (T2 cols 6/7), dropping the homeland-share control, which may be post-treatment for persistence (S5 C5-6).
5. Matérn covariance (ν = 1.5) for the placebo.
6. Spatial-trend controls (a quadratic in latitude and longitude) (Conley and Kelly 2024). This changes the conditioning set and is labelled so.
7. All 201 districts (changed population, A4d).

## 6. Fixed choices
- `data.dta`, N = 138.
- Controls as published.
- No weights.
- If any district lacks a centroid, it is dropped and the drop is reported.

## 7. Thresholds (A3 and A4)
- **Confirm:** the same sign; |b| ≥ 0.5|b₀|; Holm Conley p < 0.05; placebo p < 0.05.
- **Credible null:** the Bonferroni Conley CI lies within ±0.5|b₀|. It is reachable only for the relabelled lights coefficients, because elsewhere the point estimates do not change (A4b).
- **I3:** b₀ is the published contrast implied by the paper: 2011 coefficient (−2.025) minus the corresponding 1996 coefficient from the original run A (taken from repro_original output and reported). The same 50% rules apply.

**Disclosure.** S5 already computed Bartlett Conley SEs at 50–200 km (|t| ≥ 3.9), the all-201 estimates, and the swapped-label lights coefficients (−1.17/−0.88). The placebo and provenance check are new. The thresholds follow A3/A4.

## 8. Verdict tables (checked in order; the first rule that applies decides)
**Coefficients whose point estimate is unchanged (I1, unemployment rows, and lights rows if Step 0 confirms the original labels):** inference-only ladder (A4b).

| # | Condition | Verdict |
|---|---|---|
| 1 | Holm Conley p < 0.05 and placebo p < 0.05 | confirmed |
| 2 | Holm Conley p < 0.05, placebo p ≥ 0.05 | qualified (spatial-noise fragile) |
| 3 | Holm Conley p ≥ 0.05 | weakened |

**Lights rows if Step 0 relabels (point estimate changes):**

| # | Condition | Verdict |
|---|---|---|
| 0 | Step 0 unresolved | not-testable (provenance) |
| 1 | opposite sign, Holm p < 0.05, placebo p < 0.05 | overturned (reversed) |
| 2 | CI within ±0.5\|b₀\| | overturned (credible null) |
| 3 | same sign, \|b\| ≥ 0.5\|b₀\|, both p < 0.05 | confirmed |
| 4 | same sign, both p < 0.05, \|b\| < 0.5\|b₀\| | qualified |
| 5 | same sign, Holm p < 0.05, placebo p ≥ 0.05 | qualified (spatial-noise fragile) |
| 6 | otherwise | weakened |

**I3:**

| # | Condition | Verdict |
|---|---|---|
| 0 | Step 0 unresolved | not-testable |
| 1 | contrast > 0 (gap narrowed), p < 0.05, in both the calibrated and uncalibrated versions | overturned |
| 2 | contrast < 0 (gap widened), \|contrast\| ≥ 0.5\|b₀\|, p < 0.05, in both versions | confirmed |
| 3 | significant in only one version | qualified (calibration-sensitive) |
| 4 | otherwise | weakened |

**I1 and I2 summary:** the verdict of the weakest member, ordered not-testable < overturned < weakened < qualified < confirmed. The member-level verdicts are also reported.

## 9. Codex review notes and responses
Codex v1 review: approve-with-changes, 9 required changes. Responses:
1. Bartlett implementation specified and 100 km justified (§4).
2. Provenance applied to the I2 lights rows (§4 Step 0, §8).
3. Intercalibration sensitivity before the I3 verdict (§4).
4. Interpretation narrowed (§1).
5. I3 fully specified (§3, §4).
6. Margins follow A3/A4a; disclosure (§7).
7. Inference-only ladder; overturning only where estimates change (§8; A4b).
8. Placebo mechanics specified, with limitations (§4).
9. Sensitivities corrected; all-201 labelled as a changed population (§5).
