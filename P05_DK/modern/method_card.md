# Method card: P05_DK, correlates and consequences of the 1918 influenza in South Africa

Status: v3 (2026-10-11), frozen (A9).
- History: v1 → Codex review (reviews/P05_DK_codex_S6card.md; approve-with-changes, 8 required changes) → v2 → Codex compliance check (reviews/P05_DK_codex_S6card_v2.md; freeze-after-minor-edits, 2 edits) → v3, frozen (A9).
- Margins follow AMENDMENTS.md A3, A4, A8 and A8a, applied from the start. The card author chose no band, ceiling or margin. Card-author choices that are not margins (the eligibility rule, the missing-source rule, computational tolerances, the calibration grid) are listed with their provenance in §10.

Rights class: open (published statistics, LEAP transcriptions, shapefiles) for T1 and T3. T2 uses `voter_roll_birth.dta`, an aggregate of a personal-class source (the 1984 voters' roll). Only month-year counts are used, and no row-level record is read. All data sit on D: (A6). Codex sees this card, code and aggregate outputs only.

## 0. Type of analysis
Each verdict row (§4) has exactly one primary analysis. The classification differs by row:

| Row | Classification | Why |
|---|---|---|
| H1 (T1 Black share) | (i) correction of verified data-construction errors, with the inference the paper states (HC2) plus a small-sample df refinement | S5-6 and S5-8 change the regressors and the sample. The point estimate changes, so A3/A4 apply in full |
| H2-n (T2 births) | (ii) inference-only upgrade, A4b ladder | the coefficient reproduces exactly and no data error was found. Only the inference changes (S5-5) |
| H2-pct (T2 "25%") | (i) correction of a verified computation error (S5-3), with the H2-n inference | the denominator changes, so the point value changes and A3/A4 apply |
| H3 (T3 unemployment) | (i) correction of verified code and data errors, with HC2 inference as stated | S5-2, S5-6 and S5-7 change the SEs, the regressors and the outcome |

No row is (iii) uncertainty propagation or (iv) a new estimator. The randomization test for H2 (§4B) is a new inference procedure for the same OLS estimand, not a new estimator.

**"Strengthened" is excluded by an explicit restriction of this card.** S6 (PROTOCOL.md) allows "strengthened" when the same estimand is supported by a more credible design or inference, including a tighter credible interval. The card does not use the category, for two reasons:
- **H2-n** is inference-only. A4b, which postdates and specialises S6, sets its ladder at confirmed / qualified (inference-fragile) / weakened. That ladder has no "strengthened" rung.
- **H1, H3 and H2-pct** are corrections. The published intervals rest on erroneous data (S5-6, S5-8), an erroneous denominator (S5-3, S5-7) or misreported SEs (S5-2). A width comparison between the corrected and published intervals would therefore mix the data correction with the inference upgrade, and S6 gives no ex ante criterion for separating the two. The identification (selection on 1911 observables; two-way FE in the time series) is unchanged. A claim that passes is reported as "confirmed", and the ratio of corrected to published interval width is reported next to it as a non-voting statistic.

**A4c.** No headline row is an odds ratio, and no claim reads an OR as a probability. A4c does not apply.

**Stars.** The table notes use * .10, ** .05, *** .01. `claims/stars05.txt` = 2.

## 1. Claims family (frozen headline rows) and interpretations
The three `headline = 1` rows in `claims/claims.csv` (the A1 union of both extractors) are T1_r1_c1, T2_r3_c3 and T3_r1_c1. Interpretations are quoted from `claims/claims_spec.md`. Where one sentence makes two quantitative statements, each is a separate row.

| Row | Source | Published value | Authors' interpretation (verbatim) | A8 type | Margin |
|---|---|---|---|---|---|
| H1 | `T1_r1_c1` | 39.432*** (10.933), N 205 | "the black population share strongly predicts 1918 influenza mortality rates, both substantively and in terms of statistical significance. Moving from an exclusively white area to an exclusively black area increases mortality by nearly 40 deaths per 1,000 people" (p.181) | magnitude (coefficient) | A3/A4, b₀ = 39.432 |
| H2-n | `T2_r3_c3` | −460.648*** (110.832), N 108 | "The estimates suggest a reduction of 460 (white) births in October 1918" (p.187) | magnitude (coefficient), inference-only | A4b ladder, b₀ = −460.648 |
| H2-pct | `T2_r3_c3` | 25% (text) | "which represents a 25% decrease with respect to the average cohort size among individuals born between 1915 and 1923" (p.187) | magnitude ("x% less") | A3/A4, b₀ = −25 (%) |
| H3 | `T3_r1_c1` | −0.007*** (0.002), N 205 | "We find a robust negative association between the intensity of the 1918 flu and 1936 unemployment, at least among white South Africans … doubling the mortality rate … would result in a 0.49 percentage point decline in unemployment" (p.190) | magnitude (coefficient) | A3/A4, b₀ = −0.007 |

**Rows declared not-testable at freeze** (wording without an A8 default, or no data):
- **H2-large**: "a large … demographic shock" (abstract). A8 has no default for "large".
- **H2-short**: "short-lived" (abstract). It rests on Fig. 6, for which no code or data survive (S5-15).
- **H3-small**: "detectable, if small scale, long-term economic consequences" (abstract). A8 has no default for "small". The "detectable" half is the significance condition already in H3.
- **H3-causal**: "higher 1918 influenza mortality rates induced … lower unemployment" (conclusion). Cross-sectional OLS on pre-1918 observables cannot identify a causal effect, and the paper itself calls the evidence "suggestive".
- The maize half of "long-term economic consequences" (Table 4) is not a headline row and has no code or data. It is outside this family.

**Scope.**
- H1 and H3 are partial associations across 1918 magisterial districts, conditional on 1911 composition, density, 1907 rail access, rainfall and region. Each district has equal weight, so the estimand is an unweighted district-level projection; its weights depend on which districts form the population (§4A, Eligibility).
- H2 concerns white births as counted among survivors on the 1984 voters' roll, by month of birth. "Births in October 1918" means conceptions in October 1918, i.e. births in July 1919 (S5-4, S5-13). It is a survivor count, not a birth count, and the design does not identify a causal effect of the flu. These two scope labels are printed next to every H2 verdict.
- H3 concerns the white unemployment rate in 1936. It is an association; the H3-causal reading is not tested. This label is printed next to the H3 verdict.
- The rows are judged separately and not aggregated.

**Non-headline rows** (reported, never verdicts): T1 cols 2–4; T2 cols 1, 2, 4; T3 cols 2–3 (women, men); the rail "strong predictor" sentence (`T1_r4_*`).

## 2. Defects addressed
S5 (Claude S5-1 to S5-15 and Codex F1–F7, reconciled in `audit.md`) found, for the headline rows:

- (a) **1911 covariate construction (S5-6, F3).** Each 1970 district is assigned whole to the 1918 district of largest overlap, and its 1911 counts are summed there. Density is the unweighted mean of the 1970-district densities, which is not a density of the 1918 unit. Fix: area-weighted interpolation of counts onto the 1918 units, and density = interpolated 1911 population / covered area (§4A). Sources: Goodchild and Lam (1980) on areal interpolation; Gotway and Young (2002, *JASA*) on change of support; Eckert, Gvirtz, Liang and Peters (2020, *EEH*) on historical boundary crosswalks.
- (b) **Silent drops and mismatches (S5-8, C7, F4).** Port Shepstone has mortality and a 1918 polygon but no 1911 covariates, so it drops out. Paarl carries the combined Paarl/Wellington mortality rate against Paarl-only covariates. Fix: the eligibility rule of §4A, which gives Port Shepstone covariates and dissolves Paarl and Wellington into one unit, so that mortality and covariates cover the same territory.
- (c) **T3 denominator (S5-7, Claude-only).** The code sums ages 15–69; the text states 15–64. Fix: 15–64.
- (d) **T3 crosswalk (F3).** The 1936 counts reach the 1918 units through the largest-overlap 1937→1918 assignment. Fix: area-weighted interpolation of the counts, the same rule as (a).
- (e) **T3 SEs (S5-2, F2).** Classical SEs are printed under an HC2 note. Fix: HC2 as stated, with Bell–McCaffrey small-sample degrees of freedom (Bell and McCaffrey 2002; Imbens and Kolesár 2016, *REStat*; Pustejovsky and Tipton 2018, *JBES*). T1 col 1 already uses HC2; the df refinement is applied to it for consistency.
- (f) **T2 inference (S5-5).** A single-cell dummy with year and month FE has leverage 1, so HC SEs are undefined, and the classical SE assumes homoskedastic, serially uncorrelated monthly errors. Fix: a randomization test for one treated cell in the residual-permutation family of Chernozhukov, Wüthrich and Zhu (2021, *JASA*), with its exact finite-sample justification for this design stated in §4B, inverted exactly for a confidence set.
- (g) **T2 "25%" denominator (S5-3, C3).** The printed mean (1,787.016) averages all 1,647 cells of the file, including junk birth years. Fix: the mean of the 108 cells the text names (born 1915–1923).
- (h) **Missingness and join safeguards (F4, S5-14).** The authors' code sums age cells with `na.rm = TRUE`, sets missing unemployment to 0 and uses unasserted joins. Fix: the construction safeguards of §4A (unique keys, missing distinguished from zero, coverage and mass-conservation checks, positivity before logging).

Not fixed in the primary, because no verified error is involved: the outlier rule for cols 3–4 (S5-9), the means (S5-10), the rain label (S5-11, a pure rescaling), the authors' rail distance (S3 differs in projection, not by a demonstrated error), and spatial dependence (not tested in S5; §5 only).

## 3. Estimands
- **H1, original.** β_B in the OLS regression of deaths per 1,000 (Oct–Dec 1918, Phillips Table 13 col 7) on the 1911 Black share, the 1911 Coloured share, log(1 + 1911 density), log(1 + distance to 1907 rail in km), mean Sept/Oct rain 1910–1950 and region dummies (Cape omitted), across 205 1918 districts.
- **H1, new.** The same coefficient in the same regression, with the shares and density rebuilt by (a) and (h), on the eligible population of §4A. The estimand is the same partial association, on the population the paper states (all 1918 districts with their own mortality rate). Because the projection is unweighted, adding Port Shepstone and merging Paarl with Wellington change the district weights; the card does not claim the projection is literally unchanged.
- **H2-n.** θ, the coefficient on the indicator for the July 1919 birth cell (conception October 1918) in the OLS regression of the monthly count of white voters born, on year-of-birth FE and month-of-birth FE, Jan 1915–Dec 1923 (108 cells). Unchanged.
- **H2-pct, original.** 100·θ/1,787.016.
- **H2-pct, new.** P = 100·θ/ȳ, with ȳ the observed mean count over the 108 estimation cells. **Inferential target:** P is a descriptive normalisation of θ by the observed cohort size. Inference is for θ, conditional on the observed ȳ, which is treated as a fixed constant. The P interval is the θ confidence set scaled by 100/ȳ. It is not inference for a population ratio θ/E[y], and no claim is made about the size of ȳ's sampling variation (§10).
- **H3, original.** β_D in the OLS regression of the 1936 white unemployment rate (unemployed / white population aged 15–69 as coded) on log(deaths per 1,000), the T1 covariates and region FE.
- **H3, new.** The same coefficient with the outcome at ages 15–64, both outcome counts crosswalked by area weighting under (h), and the regressors and population rebuilt as for H1.

## 4. Primary analyses (one per verdict row)

### 4A. H1 and H3: the corrected cross-section
**Inputs (on D:, via `dpath("P05_DK", ...)`).**
- The authors' `analysis_data` and `census_1936_merge` objects, as snapshotted by the S2 harness (`repro_original/run_all.R`, patch P8) in the D: work tree.
- `original/Spanish_flu_group_folder/data/original/spatial/RSA_Pop_1904_70.shp` (fields `T1911`, `B_1911`, `C_1911`), `SA_1918.shp` (field `StndrdN`) and `1937.shp`.
- The authors' 1936 census workbooks (Tables 1 and 7), read cell by cell with `tidyxl` so that empty cells, zeros and dashes are distinguished.

**Geometry.**
- All layers are made valid (`sf::st_make_valid`) and projected to an Albers equal-area projection for South Africa (lat_1 = −24, lat_2 = −33, lon_0 = 24, WGS84). `sf_use_s2(FALSE)`.
- Lesotho polygons are excluded, as in `census_1904_1970_cleaning_ddk.R:66`.
- **Overlaps among 1918 polygons.** Pairwise intersections between 1918 polygons with positive area are listed with their areas. Each overlap is assigned to the unit whose `StndrdN` sorts first alphabetically (`st_difference` in that order), so that no territory is counted twice. This rule is deterministic and independent of any data value.
- Area = `st_area` in km² of each 1918 unit after the overlap rule and the dissolves below.

**Eligibility (the target population, defined directly; replaces the v1 population guard).**
- A **unit** is a 1918 polygon from `SA_1918.shp`, or the union of 1918 polygons that share one Phillips Table 13 rate.
  - **Combined rates.** Where the authors' mortality matching assigns one Phillips row to several 1918 polygons as that row's own territory, the polygons are dissolved into one unit carrying that rate. S5-8 identified one such case: Paarl and Wellington → `paarl_wellington`. The build script lists every Phillips row mapped to more than one polygon. Each listed case is dissolved under this rule, whether or not S5 found it.
  - **Borrowed rates.** A polygon that receives another district's rate without being part of that district's territory has no rate of its own and is ineligible. S5-8 identified Lower Umzimkulu (Natal), which received Umzimkulu's (Transkei) rate.
- **Eligible units** are those with their own Phillips col 7 rate. This is the paper's stated population ("the 1918 magisterial districts" with mortality data).
- **Why the two expected changes restore, rather than change, the target population (A4d).**
  - Port Shepstone has its own Phillips rate and a 1918 polygon. It left the published sample only because no 1970 district was assigned to it (S5-8), which is a construction error, not an eligibility rule.
  - The Paarl/Wellington rate refers to the combined territory. Dissolving the polygons puts the outcome and the covariates on the same territory.
  - A4d restricts sensitivities that *change* the population. The primary implements the stated population, so A4d does not bar it from deciding the verdict. Sensitivity 6 reports the result without Port Shepstone.
- **Analysis sample.** Every eligible unit with non-missing values for every variable of the specification (listwise deletion). No count threshold applies. Every unit that is in the published sample and not in the corrected one, or the reverse, is listed with its reason (ineligible, missing variable and which, dissolved).

**Construction safeguards (prespecified; F4, S5-14).**
- **Unique keys.** `StndrdN` (1918), the polygon identifier of `RSA_Pop_1904_70` and the 1937 polygon name are asserted unique after cleaning, and the dissolved key `paarl_wellington` is asserted unique. Every join is a keyed join with an asserted row count; a duplicate key or an unexpected row count stops the run.
- **Missing versus zero.** A count is zero only when the source records 0 or a dash. An empty or NA source cell is missing. Missing counts are never set to 0.
- **Missing-source rule (ratios over the non-missing support).** For each 1918 unit, the source polygons with complete counts for a given quantity form its support for that quantity.
  - Shares (B/T, C/T) and the unemployment rate (unemployed / persons 15–64) are computed with numerator and denominator both interpolated from the *same* support, so a missing source polygon drops out of both.
  - Density = interpolated T / the area of the unit covered by the T support.
  - A unit with an empty support for a quantity is missing on that quantity.
  - For each unit and quantity, the share of the unit's area whose source is missing is reported. Sensitivity 26 applies the strict alternative (any overlapping missing source → the unit is missing).
- **Coverage.** For each unit: covered area / unit area for each layer. Area not covered by any source polygon (coastline and boundary slivers) is excluded from the density denominator by the rule above. The distribution of coverage is reported.
- **Mass conservation.** For each interpolated count, the total over all 1918 units is compared with the total over the source polygons, apportioned by the share of each source's area that falls inside some 1918 unit. A relative discrepancy above 1e-6 indicates double counting or a geometry error and stops the run. The source mass lying outside every 1918 unit (Lesotho, sea, other territories) is reported by source polygon.
- **Positivity before logging.** log(deaths per 1,000) needs a positive rate. A unit with a rate ≤ 0 or missing is missing for H3 and is listed. The published code has the same domain (log of 0 is −∞ and `lm` would fail), so this does not depart from the published specification.
- **Division.** A unit with a zero or missing denominator for a share or rate is missing on that variable, never 0 or Inf.

**Regressors (H1 and H3).**
- `T1911`, `B_1911` and `C_1911` are interpolated from the `RSA_Pop_1904_70` polygons onto the 1918 units with `sf::st_interpolate_aw(..., extensive = TRUE)`, applied to the support of each quantity as defined above.
- Black share = B/T; Coloured share = C/T (the authors' definitions, `census_1904_1970_cleaning_ddk.R:192–194`, applied to the interpolated counts).
- Density = T / covered area (persons per km²); regressor log(1 + density).
- Rail: the authors' `log_rail_mdcentroid_to_nearestrail_km` for every undissolved unit. For a dissolved unit, the authors' rail algorithm (`railways_1907_cleaning_ddk.R`, existing lines only) is re-run on the dissolved polygon's centroid.
- Rain: the authors' `rainfall_sepoctmean19101950` (mm). A dissolved unit takes the area-weighted mean of its members' values over the members that have one (for `paarl_wellington`, Paarl's value, since Wellington has no series).
- Mortality: the authors' `deaths_sflu_per_1000` (Phillips col 7). A dissolved unit takes the combined rate.
- Region: the authors' `region`. The members of a dissolved unit must share a region (asserted; `paarl_wellington` is Cape). If they do not, the run stops and the case is logged in `DEVIATIONS.md`.

**Outcome (H3).**
- The authors' 1936 district → 1937 polygon name matching (agrep plus the correction CSV) is kept unchanged. Every 1936 district is asserted to match at least one 1937 polygon; unmatched districts are listed. A 1937 polygon with no matched 1936 district has missing counts (not zero).
- Counts per 1936 district: white unemployed persons (Table 1) and white persons aged 15–64 (Table 7 age columns 18:32, i.e. the authors' 18:33 without col 33, "65–"). If any age cell of 15–64 is missing, the district's denominator is missing. A missing unemployment cell is missing, not 0.
- Counts are attached to the matched 1937 polygons. If one 1936 district matches several 1937 polygons, its counts are split across them in proportion to area. They are then interpolated onto the 1918 units with `st_interpolate_aw(..., extensive = TRUE)` under the missing-source rule.
- Rate = interpolated unemployed / interpolated persons 15–64, both from the same support.

**Specifications.**
- H1: `lm(deaths_per_1000 ~ black_share + col_share + log(1 + density) + log_rail + rain + factor(region))`, Cape omitted, no outlier exclusion (col 1).
- H3: `lm(urate_1564 ~ log(deaths_per_1000) + black_share + col_share + log(1 + density) + log_rail + rain + factor(region))`.
- No weights.

**Inference (one rule, both rows).**
- HC2 with Bell–McCaffrey (Satterthwaite) degrees of freedom: `clubSandwich::coef_test(m, vcov = "CR2", cluster = unit_id, test = "Satterthwaite")`, with each unit its own cluster, so CR2 = HC2.
- The unadjusted two-sided p comes from that test. The Bonferroni interval comes from `clubSandwich::conf_int(m, vcov = "CR2", cluster = unit_id, test = "Satterthwaite", level = 1 − 0.05/3)`. Because the test and the interval use the same SE and df, p < 0.05/3 holds exactly when the interval excludes 0.
- **Failure and fallback.** Failure means an error, a non-finite or non-positive df, or a non-finite SE. For the failed row only, the fallback is HC2 (`sandwich::vcovHC(m, type = "HC2")`) with t on N − K df, which gives the unadjusted p and the Bonferroni interval with the same equivalence. If the HC2 SE is non-finite or 0 (leverage 1), the row is not-testable. The fallback is logged in `DEVIATIONS.md`.

**Reproduction gate (full precision).** With every correction switched off (the authors' regressors, outcome and sample; HC2 for T1, classical for T3), the script must reproduce the full-precision S2 values stored in `repro_original/results_original.csv` before any corrected estimate is computed:
- T1_r1_c1: b = 39.4315408322013, SE = 10.9332353140074, N = 205;
- T3_r1_c1: b = −0.00728048840341724, SE = 0.00201121123103972, N = 205.

The tolerance is |x − x_S2| ≤ 1e-8·max(1, |x_S2|) for each b and SE, and N must match exactly. If the gate fails, the run stops and the discrepancy is logged. A failure that is not resolved by a logged, results-blind deviation (A5) makes the affected row not-testable.

**Reported for each row:** N; the unit-list differences with reasons; the coverage, missing-support and mass-conservation diagnostics; the corrected Black-share and density summaries and their correlations with the authors' versions; the maximum leverage; the BM df; the unadjusted p; the Bonferroni interval; the Holm p (non-voting); and the ratio of corrected to published interval width (non-voting, §0).

### 4B. H2-n and H2-pct: randomization inference for one treated cell
**Data.** `voter_roll_birth.dta` (aggregate counts by birth year and month), restricted to birth months Jan 1915–Dec 1923: a complete 9 × 12 grid of 108 cells. y_t = count; T = the July 1919 cell. The grid is asserted complete (108 distinct year-month cells, none missing).

**Point estimate.** θ̂ = the coefficient on 1[t = T] in `lm(y ~ D_T + factor(year) + factor(month))`.
- **Reproduction gate (full precision).** θ̂ and its classical SE must match the S5 values stored in `compare/s5_checks/01_table2_offsets.csv` (−460.647727272724; 110.832058437886) with the tolerance |x − x_S5| ≤ 1e-8·max(1, |x_S5|). If the gate fails, H2-n and H2-pct are not-testable.

**Test of H0: θ = θ₀.**
- y⁰(θ₀) = y − θ₀·e_T, where e_T is the indicator of cell T.
- Fit `lm(y⁰ ~ factor(year) + factor(month))` on all 108 cells under the null (no dummy) and take the residuals û(θ₀) = (I − H)y⁰(θ₀), with H the two-way FE projection.
- Statistic: |û_T(θ₀)|. p(θ₀) = (1/108)·Σ_t 1{|û_t(θ₀)| ≥ |û_T(θ₀)|}. Ties count against rejection.
- The primary p for H2-n and H2-pct is p(0). Its smallest attainable value is 1/108 = 0.00926, below the Bonferroni threshold 0.05/3 = 0.0167, so rejection is reachable.

**Validity (replaces the v1 statement on iid and circular-shift permutations).**
- **Exact validity under separate exchangeability.** Write y = Xγ + θ·e_T + u, where X holds the year and month FE. Let G be the group of permutations of the grid that permute birth years among themselves and calendar months among themselves (9!·12! elements).
  - The balanced two-way projection H commutes with every g ∈ G, because G maps the year and month indicator spaces onto themselves. Under H0, û(θ₀) = (I − H)u.
  - Suppose the joint distribution of u is invariant under G (separate exchangeability of the error array across years and across months; this includes iid errors). Then gû = (I − H)gu has the same distribution as û for every g ∈ G.
  - G acts transitively on the 108 cells with stabilisers of equal size, so the randomization p-value (1/|G|)·Σ_g 1{|û_{g⁻¹(T)}| ≥ |û_T|} equals the cell average p(θ₀) above. Standard randomization-test theory (Lehmann and Romano 2005, ch. 15; Chernozhukov, Wüthrich and Zhu 2021, §2 on exact validity under exchangeability) gives P(p(θ₀) ≤ α) ≤ α under H0 for every finite sample.
  - This argument uses only the invariance of the error distribution and the balanced design. It needs neither consistent estimation of the FE nor large samples.
- **What it does not cover.** Serial dependence in calendar time (e.g. AR errors linking adjacent birth months, including across the December–January boundary) breaks separate exchangeability, and so does heteroskedasticity that varies by year or month. Chernozhukov, Wüthrich and Zhu (2021) give only approximate validity under stationary weakly dependent errors, and their conditions include consistent estimation of the null model, which a fixed 9 × 12 grid does not deliver. The card therefore claims exact validity under separate exchangeability only. Size under serial dependence is assessed by the prespecified calibration checks of §5 item 25, which are reported and never vote.
- v1's statement that the iid and circular-shift versions coincide is withdrawn; it did not establish validity under dependence.

**Confidence set by exact inversion (replaces the v1 grid).**
- û(θ₀) = a − θ₀·c, with a = û(0) and c = (I − H)e_T. Each |û_t(θ₀)| is the absolute value of an affine function of θ₀.
- Cell t's indicator can change only where a_t − θ₀c_t = ±(a_T − θ₀c_T), i.e. at θ₀ = (a_t − a_T)/(c_t − c_T) and θ₀ = (a_t + a_T)/(c_t + c_T) (where the denominator is non-zero). These at most 214 breakpoints are computed exactly. p(θ₀) is evaluated at every breakpoint and at the midpoint of every interval between consecutive breakpoints, and is constant on each open interval.
- The Bonferroni confidence set is C = {θ₀ : p(θ₀) ≥ 0.05/3}, a finite union of closed intervals with exact endpoints. 0 ∉ C holds exactly when p(0) < 0.05/3, so the test and the set agree.
- **Boundedness.** In the balanced grid, c_T = 1 − 20/108 and |c_t| ≤ 11/108 for t ≠ T, so for large |θ₀| cell T has the largest residual and p = 1/108 < 0.05/3. C is therefore bounded. The script computes c numerically and asserts c_T > max_{t≠T} |c_t|.
- **Credible null and the hull.** C is bounded, so C ⊂ (−L, L) holds exactly when min C > −L and max C < L. The hull [min C, max C] therefore gives the same credible-null decision as C itself. Non-convexity of C is flagged and its components are reported.
- Equality tests at breakpoints use a relative tolerance of 1e-10·max_t |a_t|, resolved in favour of non-rejection.

**H2-pct.** P̂ = 100·θ̂/ȳ, with ȳ = the mean of y over the 108 cells (§3). Its Bonferroni set is 100·C/ȳ. If ȳ ≤ 0 or is non-finite, H2-pct is not-testable.

**Reported:** θ̂, P̂, ȳ, p(0), the Holm p (non-voting), C and its hull, the full p(θ₀) step function, the five largest |û_t(0)| with their cells, and the §5 item 25 calibration results. The alternative denominators are in §5 item 17.

### 4C. Multiplicity (one coherent procedure; replaces the v1 Holm–Bonferroni rule)
- **Family P = {H1, H2-n, H3}: m = 3 tests.** H2-pct shares H2-n's hypothesis (θ = 0) and therefore its p-value; it is not a fourth test.
- **Bonferroni for both the test and the interval.** A row is significant ("adjusted CI excludes 0", A3 condition 2) exactly when its unadjusted p < 0.05/3, which is exactly when its Bonferroni interval (H1, H3) or set C (H2) excludes 0. Credible-null decisions (A4a) use the same interval or set. The test and the interval cannot disagree.
- Holm-adjusted p-values are reported for information and decide nothing.
- **Not-testable rows.** m stays at 3 whatever the number of rows that turn out not-testable. The family size is fixed before estimation and does not shrink with the results.
- Bonferroni is weakly more demanding than Holm for every row, so moving from Holm to Bonferroni can only make confirmation harder.

## 5. Admissible sensitivities (exhaustive; reported, never verdict-determining)
Every item below is labelled "sensitivity; does not set the verdict" in the output. Items that change the population or estimand are additionally labelled A4d.

**H1 and H3: construction.**
1. Diagnostic: the authors' data and sample with the primary inference (HC2/BM), isolating the effect of the corrections.
2. One correction at a time, from the authors' data: (a) area-weighted shares only; (b) density = interpolated total / covered area only; (c) Port Shepstone added only; (d) Paarl/Wellington dissolved only. For H3 also: (e) the 15–64 denominator only; (f) the area-weighted 1936 crosswalk only.
3. The full S3 rebuild (`repro_r/`, N 206; S3 rail, rain and outcome).
4. 1911 shares from Phillips Table 13 (B(1911), I&C(1911), Phillips TOTAL as denominator), as in the S3 sensitivity.
5. Rail: the S3 distance (equal-area projection, existing lines); all features including those "under construction".
6. Corrected sample without Port Shepstone (changed population; A4d).

**H1 and H3: inference.**

7. Classical, HC1 and HC3 SEs on the primary data.
8. Restricted wild bootstrap (Rademacher, HC2-type residual transformation, B = 9,999, seed 20261011).
9. Conley SEs, Bartlett kernel, cut-offs of 100, 200 and 500 km between great-circle centroid distances of the 1918 units (`conleyreg`).
10. Moran's I of the primary residuals (k = 5 nearest-neighbour weights, row-standardised), as a diagnostic.
11. Spatial-noise placebo (Kelly 2019) for the focal regressor, with the P28 mechanics: residualise the focal regressor on the others; fit an exponential covariance by ML (ρ ∈ [1, 2000] km); simulate R = 2,000 series (seed 20261011); placebo p = (1 + #{|t*| ≥ |t|})/(R + 1) with the Conley 100 km t.
12. Wild cluster bootstrap by region (6 clusters, Webb weights, B = 9,999), reported with the number of units per region, the largest region's share of N and the maximum partial leverage by region (`summclust`). Six clusters are too few for reliable inference, and the output says so.

**H1 and H3: specification and population (changed estimand or population; A4d).**

13. Log outcome (T1 col 2 analogue).
14. Outliers excluded: the top-3 |rstudent| of the corrected levels model (T1 col 3 analogue) and the top-3 of the corrected log model (col 4 analogue).
15. Leave-one-region-out; leave-one-unit-out (the range, and the number of drops that would change the verdict category); the ten largest |DFBETA|.
16. H3 only: the 15–69 denominator with all other corrections; the women and men columns with all corrections (non-headline); men and women with the original data and HC2.

**H2.**

17. Alternative denominators for H2-pct: the counterfactual July 1919 count ŷ_T (the FE prediction from the model without the dummy, fitted on the other 107 cells), and the July mean over 1915–1923.
18. Classical OLS SE and t-test (as published).
19. The S5 placebo-dummy distribution: θ̂_c for each of the 108 cells, and the rank of |θ̂_T|.
20. **Diagnostic (not a conformal test; repaired in v2 and v3).** Let E = the birth cells Jan 1919–Dec 1920 other than T (other flu-affected months). The null model `lm(y⁰ ~ factor(year) + factor(month))` is fitted on all 108 cells, as in §4B, so the scores are the primary null residuals |û_t(0)|. E is excluded **only from the reference set**: the rank of |û_T(0)| is reported among {|û_t(0)| : t ∉ E} (T included; 108 − |E| = 85 cells), together with the share of those cells with a score at least as large. The affected months remain in the fit and can still move the FE and hence û_T(0). No finite-sample guarantee is claimed. The v1 claim that the primary is conservative is withdrawn. (v2 excluded E from the fit, which left T alone in birth year 1919, so the year FE fitted it exactly and û_T was 0; that version is withdrawn.)
21. FGLS with AR(1) errors and year and month FE (`nlme::gls`, `corAR1`), with a test on the dummy.
22. Log count outcome (the dummy coefficient as a log-percentage).
23. Birth window 1916–1922 (changed sample period).
24. Diagnostic only: the 8-month offset of the saved `.tex` (dummy on the August 1919 cell).
25. **Serial-dependence calibration (prespecified; never votes).**
    - (a) The null residuals û(0) in calendar order: autocorrelations at lags 1 and 12; Ljung–Box statistics at lags 12 and 24.
    - (b) Monte Carlo size of the §4B test. Simulate u as a stationary Gaussian AR(1) in calendar order with ρ ∈ {0, 0.25, 0.5} and with ρ̂ = the lag-1 autocorrelation of û(0); generate y = Xγ̂ + u with γ̂ the null-model FE and σ² from û(0); compute p(0) for θ = 0; R = 5,000 replications per ρ, seed 20261011. Report the rejection rates at 0.05/3 and 0.05 with Monte Carlo SEs.
    - A size above nominal is reported next to the H2 verdicts as a flag. It does not change them (§10).

**Construction, all rows using §4A.**

26. The strict missing-source rule (a unit is missing on a quantity if any overlapping source polygon is missing it), and density = interpolated T / full unit area.

## 6. Fixed choices
- No weights anywhere. Listwise deletion as in §4A. No outlier exclusion in the primary.
- Rain in mm; coefficients on rain are not interpreted.
- Unrounded values decide every comparison; results are reported to 4 significant digits.
- **Boundary rules.**
  - A p-value equal to the threshold is not significant: significance needs p < 0.05/3.
  - |b| = 0.5|b₀| meets the floor.
  - A credible-null interval must lie strictly inside (−0.5|b₀|, +0.5|b₀|); an endpoint equal to ±0.5|b₀| fails it.
  - b = 0, or an interval endpoint at exactly 0, counts as "sign not established" and "interval includes 0".
- Seeds: 20261011 (bootstraps, placebos and the Monte Carlo calibration only; the primary analyses are deterministic).
- Scripts: `modern/01_build.R` (geometry, eligibility, interpolation, safeguards, outcome), `02_cross_section.R` (H1, H3), `03_t2_randomization.R` (H2), `04_sensitivities.R`, `05_verdicts.R`.

## 7. Margins (A3, A4 defaults; none chosen by the card author)
| Row | b₀ (published headline number) | Confirm | Credible null (A4a) | Plausibility flag (A8, not a verdict) |
|---|---|---|---|---|
| H1 | 39.432 | same sign, p < 0.05/3, b ≥ 19.716 | Bonferroni interval within (−19.716, 19.716) | \|b\| > 59.148 |
| H2-n | −460.648 | p(0) < 0.05/3 (A4b; the estimate is fixed) | unreachable (A4b) | none (estimate fixed) |
| H2-pct | −25 (%) | same sign, p(0) < 0.05/3, P ≤ −12.5 | 100·C/ȳ within (−12.5, 12.5) | \|P\| > 37.5 |
| H3 | −0.007 | same sign, p < 0.05/3, b ≤ −0.0035 | Bonferroni interval within (−0.0035, 0.0035) | \|b\| > 0.0105 |

- **b₀** is the printed headline number in every row. For H1 the words say "nearly 40" (floor 20 instead of 19.716). For H3 the words say 0.49 pp per doubling, which implies b = −0.00707 (floor 0.00354 instead of 0.0035). The printed number is used throughout; this rule is fixed for every row, not chosen per row.
- **H2-pct is a magnitude claim** ("a 25% decrease" is "x% less", A8). The A3 floor is therefore 12.5%, and A8 sets no ceiling. The S5 finding that the stated 25% should read about 19% is recorded in `audit.md` (S5-3, changes-a-number) and in the interpretation audit. It cannot by itself move this verdict (§10).
- The plausibility flag applies to the absolute magnitude (|b| > 1.5|b₀|), so a large estimate of either sign is flagged. It never changes a verdict.
- No ceilings on any row. A8a does not apply: no headline row is a share-level point claim.

**Disclosure.** S5 and S2 numbers seen before this card, all bearing on the verdicts:
- **H1.**
  - Published code: 39.4315, HC2 10.933, p 0.0004, N 205.
  - Area-weighted S3 shares swapped into the authors' data: 42.088 (HC2 11.810).
  - Density = 1911 total / 1918 area: 39.636 (10.79).
  - Full S3 rebuild: 41.774 (11.807), N 206; S3 without Port Shepstone 41.945.
  - Decomposition: shares +2.66, density +0.43, rail −0.57, Port Shepstone −0.17.
  - Col 4 HC2: 1.374 (0.595), p 0.022; col 4 with log-model outliers 1.803 (0.435); col 3 HC2 10.07.
  - Rail HC2 p 0.060–0.090 in all columns; rain col 3 HC2 p 0.042, col 4 p 0.145.
- **H2.**
  - θ̂ = −460.648 (classical 110.832), R² 0.892, reproduced from the aggregate file.
  - Placebo dummies: July 1919 ranks 1 of 108 (share with |θ̂_c| ≥ 460.6 = 0.009); next June 1919 (−253); Oct–Dec 1919 +285 to +352.
  - ȳ (108 cells) = 2,455.6, so P̂ ≈ −18.8%; against the July 1919 counterfactual −18.7%; against the printed mean 25.8%.
  - Because the placebo rank is 1 of 108, the primary p(0) is likely 1/108. That value, the confidence set and the calibration checks have not been computed.
- **H3.**
  - Published code: −0.00728; classical 0.00201 (p 0.0004); HC2 0.00269 (p 0.0073); HC3 0.00288 (p 0.012).
  - 15–64: −0.00741 (classical 0.00206; HC2 0.00274, p 0.0075); mean 0.0399; −0.513 pp per doubling.
  - Density = total/area: −0.00734.
  - S3 outcome (area-weighted, 15–64) on the authors' regressors: −0.00680 (HC2 0.00281); all S3 variables −0.00693 (0.00291); Codex reports the S3 rebuild at p ≈ 0.016.
  - Men: 15–64 HC2 −0.01097 (0.00395), p 0.006. Women: HC2 p 0.076.

**v2 choices made with these numbers in view.** The switch from Holm to Bonferroni (§4C) was made knowing that the disclosed H3 HC2 p ≈ 0.0075 lies below both the Holm and the Bonferroni thresholds; Bonferroni is weakly more demanding for every row, so it cannot favour confirmation. The eligibility rule (§4A) follows the paper's stated population and the S5-8 diagnosis, not any estimate, and S5 had already shown that Port Shepstone moves H1 by −0.17. The missing-source and coverage rules were written without any count of missing source cells having been seen.

Not yet run: the combined corrected cross-section of §4A, every safeguard diagnostic, the BM df, the §4B randomization test, the confidence set, the calibration checks and every §5 inference sensitivity. All margins are A3/A4 defaults, so the card author chose none of them. This disclosure does not prove that nothing was tuned.

## 8. Verdict tables (checked in order; the first rule that applies decides; exhaustive)
Notation: b = the primary estimate (P for H2-pct), b₀ its published value, p = the unadjusted p of the primary test (p(0) for H2), α′ = 0.05/3, CI = the Bonferroni interval (H1, H3) or the set C, scaled by 100/ȳ for H2-pct. "Significant" means p < α′, which is equivalent to "CI excludes 0" (§4C).

**Failure rules (all rows).** A row is not-testable if its reproduction gate fails and is not resolved by a logged, results-blind deviation; if the primary and the fallback both fail; if a safeguard stops the run and the cause is not resolved by a logged, results-blind deviation; or if the analysis sample has fewer observations than parameters plus one. These conditions depend on computation, not on the direction or size of any estimate.

**H1 and H3** (corrections; A3/A4 in full):
| # | Condition | Verdict |
|---|---|---|
| 0 | a failure rule applies | not-testable |
| 1 | sign(b) = −sign(b₀) and p < α′ | overturned (reversed) |
| 2 | CI strictly within (−0.5\|b₀\|, +0.5\|b₀\|) | overturned (credible null) |
| 3 | sign(b) = sign(b₀), p < α′, \|b\| ≥ 0.5\|b₀\| | confirmed |
| 4 | sign(b) = sign(b₀), p < α′, \|b\| < 0.5\|b₀\| | qualified (magnitude below the floor) |
| 5 | p ≥ α′, sign(b) = sign(b₀) | weakened |
| 6 | p ≥ α′, b = 0 or sign(b) = −sign(b₀) | weakened (direction lost) |

Exhaustiveness: if p < α′ the CI excludes 0 and therefore b ≠ 0, so rows 1, 3 and 4 cover every significant case not caught by row 2; rows 5 and 6 cover every non-significant case not caught by row 2. Rows 1/3 and 5/6 mirror each other in sign.

**H2-n** (inference-only, A4b ladder; θ̂ is fixed at the published value, so its sign and magnitude cannot change):
| # | Condition | Verdict |
|---|---|---|
| 0 | a failure rule applies, or p(0) cannot be computed | not-testable |
| 1 | p(0) < α′ | confirmed |
| 2 | α′ ≤ p(0) < 0.05 | qualified (inference-fragile) |
| 3 | p(0) ≥ 0.05 | weakened |

"Overturned" is unreachable on H2-n (A4b).

**H2-pct** (correction of the denominator; A3/A4 on P, with H2-n's p and set):
| # | Condition | Verdict |
|---|---|---|
| 0 | a failure rule applies, p(0) cannot be computed, or ȳ ≤ 0 or non-finite | not-testable |
| 1 | P > 0 and p(0) < α′ | overturned (reversed) |
| 2 | 100·C/ȳ strictly within (−12.5, +12.5) | overturned (credible null) |
| 3 | P < 0, p(0) < α′, P ≤ −12.5 | confirmed |
| 4 | P < 0, p(0) < α′, P > −12.5 | qualified (magnitude below the floor) |
| 5 | p(0) ≥ α′, P < 0 | weakened |
| 6 | p(0) ≥ α′, P ≥ 0 | weakened (direction lost) |

Row 1 cannot occur while the reproduction gate holds (θ̂ < 0 and ȳ > 0); it is listed for symmetry. θ̂ ∈ C always (û_T(θ̂) = 0, so p(θ̂) = 1), so P̂ lies in the scaled set, and the same exhaustiveness argument as for H1/H3 applies.

**H2-large, H2-short, H3-small, H3-causal:** not-testable.

**Summaries.**
- Each row's verdict is reported. H1, H2 and H3 are not aggregated across claims.
- **H2 summary:** the weaker of H2-n and H2-pct, ordered not-testable < overturned < weakened < qualified < confirmed. Both member verdicts are reported.
- Coverage: rows assessed versus rows not-testable, reported separately from the verdicts.
- Next to each verdict the report prints: the scope labels of §1 (survivor count and non-causal design for H2; association for H3); the item 25 calibration flag for H2; and the §5 results by item, each labelled "sensitivity; does not set the verdict".

## 9. Codex review notes and responses
**Codex v1 review** (reviews/P05_DK_codex_S6card.md): approve-with-changes, 8 required changes. All are addressed in v2.

| # | Required change | Fix in v2 |
|---|---|---|
| 1 | Justify H2's permutation validity; specify the invariance or stationarity conditions with year/month FE | §4B "Validity": an exact finite-sample argument. In the balanced 9 × 12 grid the FE projection commutes with the group of year and month permutations, so under separate exchangeability of the errors the residual vector is G-invariant, and the cell-average p equals the group randomization p. Exact validity is claimed only under that condition. Under serial dependence or year/month heteroskedasticity no validity is claimed; CWZ's approximate result is not invoked, because its consistency condition fails on a fixed grid. The v1 iid/circular-shift statement is withdrawn. |
| 2 | Repair sensitivity 20; remove the "conservative" assertion; add serial-dependence calibration | §5 item 20 is now a labelled diagnostic. v3 (after the compliance check): the null model is fitted on all 108 cells, E is excluded only from the reference ranking, T is retained, and no finite-sample guarantee is claimed; the v2 version, which excluded E from the fit and so made û_T identically 0, is withdrawn. "Conservative" is removed from §10. New §5 item 25: residual ACF at lags 1 and 12, Ljung–Box at lags 12 and 24, and a Monte Carlo size check under AR(1) with ρ ∈ {0, 0.25, 0.5, ρ̂}, R = 5,000; reported and flagged next to the H2 verdicts, never voting. |
| 3 | Align significance with A3; one coherent adjusted test/interval; multiplicity when a primary is not-testable | §4C: Bonferroni for both test and interval, so p < 0.05/3 holds exactly when the interval (or set C) excludes 0. Holm is reported and decides nothing. m = 3 is fixed whatever the number of rows that turn out not-testable. No amendment is needed: Bonferroni is a within-family adjustment under A3 condition 2. |
| 4 | Remove the five-unit population guard; define eligibility directly; explain the two restorations under A4d; do not claim the unweighted projection is unchanged | The guard is deleted. §4A "Eligibility" defines units (combined Phillips rates dissolved; borrowed rates ineligible) and the eligible population (own Phillips col 7 rate), with no count threshold. It explains why Port Shepstone and Paarl/Wellington restore the stated population and why A4d does not bar the primary. §1 Scope and §3 say the unweighted projection's weights change. |
| 5 | Strengthen construction safeguards: missing counts, coverage, mass conservation, unique identifiers, positive mortality before logging, missing vs zero; area weighting drops missing targets | §4A "Construction safeguards": asserted unique keys and keyed joins with row-count checks; cell-level reading with `tidyxl` so empty ≠ 0; missing never set to 0; ratios over a common non-missing support; density over covered area; coverage reported; a mass-conservation check that stops the run above 1e-6; positivity before logging; zero denominators → missing. §5 item 26 applies the strict missing rule. §10.3 records the uniformity assumption. |
| 6 | Reproduction against full-precision stored S2 estimates; exact or certified H2 inversion | §4A and §4B gates now compare with the stored full-precision values (`repro_original/results_original.csv`; `compare/s5_checks/01_table2_offsets.csv`) at relative tolerance 1e-8, b and SE, with N exact. The H2 grid is replaced by exact inversion: the residuals are affine in θ₀, all ≤ 214 breakpoints are computed in closed form, p is evaluated on every piece, and the set is proven bounded (c_T > max|c_t|, asserted). The hull gives the same credible-null decision as the set. |
| 7 | Define H2-pct's inferential target; remove the claim that denominator uncertainty is small; keep survivor and causal limitations beside verdicts | §3: P is a descriptive normalisation; inference is for θ conditional on the observed ȳ, not for a population ratio. The "small relative to θ̂" assertion is deleted (§10.6). §1 Scope and §8 Summaries print the survivor-count and non-causal labels next to every H2 verdict, and the association label next to H3. |
| 8 | Correct the "strengthened" rationale | §0 now states an explicit restriction: A4b governs H2-n and has no strengthened rung; for the correction rows, an interval-width comparison would mix the data correction with the inference upgrade, and S6 gives no ex ante way to separate them. The width ratio is reported as a non-voting statistic. The v1 reading of S6 is withdrawn. |

**Codex compliance check on v2** (reviews/P05_DK_codex_S6card_v2.md): freeze-after-minor-edits. Required changes 1 and 3–8 addressed; 2 partly addressed. Both listed edits are made in v3.

| # | Edit | Fix in v3 |
|---|---|---|
| 1 | Repair §5 item 20: fit on all 108 cells; exclude E only from the reference ranking, retaining T; keep the diagnostic label; acknowledge that affected months remain in the fit | §5 item 20 rewritten accordingly; §9 row 2 and §10.5 updated |
| 2 | Apply A8's plausibility flag to absolute magnitude | §7: \|b\| > 59.148 (H1), \|P\| > 37.5 (H2-pct), \|b\| > 0.0105 (H3) |

**Optional suggestions.**
1. Spatial sensitivities are retained (§5 items 9–11). Item 12 now reports cluster sizes, the largest cluster's share and the partial leverage by region.
2. A3/A4/A8 defaults are kept without ceilings. A8a does not apply (§7). H2-n's inability to overturn is cited to A4b (§8).
3. The A9 sequence is followed: v2 responds to the review, a Codex compliance check follows, and v3 is frozen. Unresolved issues are in §10.

## 10. Known limitations at freeze
1. **H2-pct cannot register the S5 denominator error.** Under A8 "a 25% decrease" is a magnitude claim with a 50% floor (12.5%). The corrected figure of about 19% passes that floor, so the verdict rules cannot distinguish 19% from 25%. The error is reported through S5-3 and the interpretation audit, not through the verdict.
2. **The corrected population adds Port Shepstone and dissolves Paarl/Wellington.** Both follow from the eligibility rule (§4A), which implements the paper's stated population. They nevertheless change the weights of the unweighted district projection. Sensitivity 6 reports the result without Port Shepstone. The eligibility rule was written after S5 had diagnosed both cases; it refers to Phillips's own rates and not to any estimate.
3. **Area-weighted interpolation assumes population is uniform within each source polygon.** No finer 1911 or 1936 geography exists in the data. The ratio-over-support rule further assumes that territory with missing source counts has the same composition as the covered territory of the same unit. Sensitivity 4 (Phillips shares) uses a different source, and sensitivity 26 applies the strict missing rule.
4. **Spatial dependence is not in the primary inference.** S5 did not test it. HC2/BM treats the 1918 districts as independent. Conley SEs, Moran's I and the spatial-noise placebo (§5 items 9–11) are reported only.
5. **H2's exact validity rests on separate exchangeability.** The test has a granularity of 1/108 (smallest p 0.00926 < α′ = 0.0167). It is exact when the error array is invariant under permutations of birth years and of calendar months. Serial dependence across adjacent months, seasonal or year-specific heteroskedasticity, and other flu-affected months (June 1919; the Oct–Dec 1919 rebound) can violate that condition, and the direction of any resulting size distortion is not known. Item 25 measures size under AR(1) and item 20 ranks July 1919 against the cells outside the other affected months, which remain in the FE fit and can contaminate it; both are reported beside the verdict and neither changes it.
6. **ȳ is treated as fixed.** The H2-pct interval is the θ set scaled by the observed ȳ. It is inference for θ conditional on the observed cohort sizes, not for a population ratio, and the joint variation of θ̂ and ȳ is not propagated. The card makes no claim about the size of ȳ's sampling variation.
7. **H2 counts are survivors on the 1984 voters' roll**, not births. Differential mortality or emigration by birth month between 1919 and 1984 would bias θ, and the aggregate file cannot address it. The label is printed next to every H2 verdict.
8. **The interpretation rows H2-large, H2-short, H3-small and H3-causal are not-testable**, and Table 4 (maize) and Fig. 6 have no code or data. The card therefore cannot assess the abstract's "short-lived" or the conclusion's causal "induced".
9. **Computational choices by the card author.** The overlap assignment by alphabetical `StndrdN`, the mass-conservation tolerance (1e-6), the reproduction tolerance (1e-8), the breakpoint tie tolerance (1e-10), the calibration grid ρ ∈ {0, 0.25, 0.5, ρ̂} and R = 5,000 are fixed for computation. None decides a verdict except through the failure rules, which depend on computation and not on any estimate.
10. **Bonferroni rather than Holm.** The card gives up Holm's extra power in exchange for exact agreement between test and interval. P10 and earlier cards kept the Holm–Bonferroni rule with flagged discordance, so P05 differs from them on this point. The Holm p is reported.
11. **Frozen at v3 under A9.** The compliance check found no blocking defect. Second-order issues that a further review round might raise are not addressed; the inferential limits above are those disclosed at freeze.
