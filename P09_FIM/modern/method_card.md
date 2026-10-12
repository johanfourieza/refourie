# Method card: P09_FIM, living standards in settler South Africa, 1865–1920

Status: v3 (2026-10-11), final; frozen under A9 with the commit message "FREEZE S6 card P09".
- History: v1 → Codex review (reviews/P09_FIM_codex_S6card.md; approve-with-changes, 9 required changes) → v2 → Codex compliance check (reviews/P09_FIM_codex_S6card_v2.md; revise again, 5 corrections) → v3.
- No further review round (A9). Anything v3 does not fully resolve is listed in §10.
- Margins follow AMENDMENTS.md A3, A4, A8 and A8a, defaults only. A8a does not apply: no claim is a share on [0,1]. The card author chose no band, ceiling or threshold.

Rights class: personal and restricted-licence (`P09_FIM/rights.csv`; Codex not allowed microdata). Every script runs locally on D:. Codex sees this card, code and aggregate output only.

## 0. Type of analysis
**Controlling fact.** No code or analysis file for the 2022 paper survives (S2-1/F1). Pair A is unavailable for all 1,013 claims, and the weights, the WWII covariates and the published sample cannot be recovered. Every analysis below therefore runs on the **surviving data vintage**: the S3 analysis sample, built from raw workbooks by the locked recreation (commit d0fbc1c). On that sample the T2 cohort means are within 0.2 cm of the paper in all six cohorts. This fact is stated in every report and in §10.

**Classification, per row.**
- **T3 cohort rows (H3-65, H3-15, H3-dec, H3-rec): `different-estimand`.** The published estimand is a weighted truncated-regression coefficient conditional on region, occupation, town size and Attestation. The census weights and the WWII covariates do not survive, so no analysis on the surviving data targets that estimand. That the change is forced by the data does not make the new target equivalent to the old. The verdict on each T3 row is therefore `different-estimand`, fixed now and independent of any result. The primary analysis of §4B is run and its findings are reported as **conditional recruit-pattern findings** (rows R-65, R-15, R-dec, R-rec; §8B). They are labelled separately and cannot confirm or overturn the published estimand.
  - Within that analysis, one change is a **correction of a verified defect**: the truncation point moves off the 63-inch heap (S2-2/F2, confirmed by rerun).
  - Two changes are **design choices with a stated motivation, not proven corrections**: force fixed effects (motivated by C2/F7 and the abstract's wording; they hold force-level composition fixed, but do not address selection that changes within a force across cohorts), and growth dummies for ages 21–22 (part of C1).
  - Two **identifying restrictions** are imposed and are untestable with these data: R1 (no age effect at 23–49) and R2 (no within-force period trend, so no Attestation term). See §4B and §10.
- **T2 point rows (T2-c1, T2-c4):** recomputation on the surviving vintage. S5 found no defect in these descriptive means. No inference enters.
- **T2 comparative rows (T2-dec, T2-min):** (iii) **inference-only**. The paper printed these comparisons without uncertainty, and the only methodological change is the added inference. The point estimates differ from the printed ones only through the data vintage, not through any change of method. The A4b ladder applies: confirmed / qualified (inference-fragile) / weakened. **"Overturned" cannot be reached on these rows.**
- **H3-15-all, F8-gap, F8-all:** not-testable (§1).

**A4c.** No headline row is an odds ratio or an OR-based probability. All coefficients are in cm.

**Stars.** `claims/stars05.txt` = 1 (estout legend: * p < .05, ** p < .01, *** p < .001; A7).

## 1. Claims family (frozen headline rows) and interpretations
`claims/claims.csv` has five `headline = 1` rows (A1 union): `T2_Total_Total_c1`, `T2_Total_Total_c4`, `T3_Birthcohort_1865_1874_c1`, `T3_Birthcohort_1915_1920_c1` and `F8_SA_minus_NZ_mean`. The S5 text in `audit.md` and the extractor note in `claims/claims_spec.md` refer to "three headline claims"; that is the first extractor's set. Under A1 the headline set is the union, and this card uses the frozen five. Interpretations are quoted from `claims/claims_spec.md`.
- Where one printed sentence makes a level statement and a comparison, the two are separate rows.
- Universal wording ("unilaterally", "lowest", "all", "every") is judged by a conjunction rule over elementary contrasts, with simultaneous intervals (§4, §6).
- Each verdict row has exactly one primary analysis (§4), and only that analysis decides its verdict.

**T2, raw cohort means.** Source sentence (p.8): "Overall we see a decrease in height from a high of 175.4 cm in the 1865–74 cohort until they reach their lowest of 173.7 cm for the 1895–1904 cohort, increasing thereafter to end at 174.9 cm for those born 1915–1920."

| Row | Source | Claim | A8 type | Margin |
|---|---|---|---|---|
| T2-c1 | `T2_Total_Total_c1` (175.36) | the 1865–74 mean is 175.36 cm | point | [157.824, 192.896] (±10% of 175.36; A8 default) |
| T2-c4 | `T2_Total_Total_c4` (173.67) | the 1895–1904 mean is 173.67 cm | point | [156.303, 191.037] (±10% of 173.67; A8 default) |
| T2-dec | both rows | "a decrease in height from a high of 175.4 … until … 173.7": m₁ > m₄ | comparative ">" | e₁ = m₁ − m₄ > 0, simultaneous CI excluding 0 (A8 default; A4b ladder) |
| T2-min | `T2_Total_Total_c4` | "their lowest … for the 1895–1904 cohort": m₄ < m_j for every other cohort j | comparative ">", universal | e_j = m_j − m₄ > 0 for all j ∈ {1, 2, 3, 5, 6}, each simultaneous CI excluding 0 (conjunction; A4b ladder) |

"From a high of" is read as the starting level, not as a claim that the 1865–74 mean is the maximum. Whether it is the maximum is reported (S24) and decides nothing.

**T3, conditional cohort effects** (col 1, reference cohort 1885–94; stated as living standards). All four rows take the verdict `different-estimand` (§0). The interpretations below define what the recruit-pattern findings R-65, R-15, R-dec and R-rec measure.
- **H3-65** (`T3_Birthcohort_1865_1874_c1`, 1.028*, t 2.34, N 6,896). Men born in the late 1860s were "very tall"; living standards "were high by 1865". A magnitude claim, b₀ = 1.028.
- **H3-dec** (the interpretation attached to the same row). Living standards "decreased unilaterally as the nineteenth century wore on" (conclusion); "Living standards decreased in the 1880s and 1890s" (introduction). An ordering claim with universal wording: b(1865–74) > b(1875–84) > b(1885–94) ≡ 0 > b(1895–1904). A conjunction of three adjacent ">" contrasts (A8 comparative default).
- **H3-15** (`T3_Birthcohort_1915_1920_c1`, 1.551***, t 3.69). "A slight improvement in living standards after 1900"; living standards "began to recover slowly". A magnitude claim, b₀ = 1.551. A8 has no default for "slight", so the A3 floor applies with no ceiling.
- **H3-rec** (the interpretation attached to the same row). The improvement "after 1900" is measured from the trough: b(1915–20) > b(1895–1904). Comparative ">".
- **H3-15-all.** The improvement holds "across all regions and occupations". **Not-testable**: the surviving WWII file, the only source for the 1915–20 cohort, has no region or occupation.

**F8, international comparison.**
- **F8-gap** (`F8_SA_minus_NZ_mean`, 2.46 cm, digitised). The mean South Africa minus New Zealand gap in predicted farmer height. A point claim with A8 band [2.214, 2.706]. **Not-testable.**
- **F8-all.** "South Africans remain taller than all other countries in the sample": the SA farmer series lies above every comparison series in every cohort. A universal claim. **Not-testable.**
- Reason for both: no Australian, Canadian, New Zealand or English microdata survive, no SA prediction code survives, and the model type is unstated (C11). The SA farmer series cannot be rebuilt either, because WWII has no occupation.

**Out of family, recorded only.** "All classes taller" (conclusion; Figs 9–10) is not a headline row. S5 found that the digitised published values contradict it (C11/F7). The causal readings in the abstract ("in response to natural disasters", protein intake) are not-testable.

## 2. Defects addressed
S5 (Claude C1–C12 and S2-1 to S2-10; Codex F1–F8; reconciled in `audit.md`):
- **(a) Force composition** (C2, F7). The headline column omits force; only col 2 includes it. The abstract says the result holds "accounting for different selection across the forces". For 1915–20 the omitted contrast is WWII against WWI. Force fixed effects hold the force-level mean fixed. **They do not address selection that changes within a force across cohorts**, such as the age-selective WWII enlistment of men born 1898–1905 (footnote 6) or changing standards within a force over time (Bodenhorn, Guinnane and Mroz 2017, *JEH*). Force FE is a composition adjustment, not a selection correction; the residual within-force selection is listed in §10.
- **(b) Attestation** (C3, C4, F6). An undefined linear enlistment-year term. Its coding as enlistment year − 1900 is a Claude inference from the published col 8/col 2 identity and the rebuild fit (C3); **Codex disputes that this identification is established (F6), and the dispute stands.** Within a war, cohort = enlistment year − age, but with ten-year cohort bins cohort, age and enlistment year are not exactly collinear, so near-collinearity and the age identity do not prove that Attestation is a bad control. The card therefore does not claim to correct a defect here. It drops Attestation by imposing **R2** (no within-force period trend), an identifying restriction stated in §4B; S2c reports the fit with Attestation (relaxing R2). The col 8 WWII dummy (C3) is reported as an extrapolation over the 1921–38 gap and is not a headline.
- **(c) Truncation on the heap** (S2-2, F2). ll(160.02) sits exactly on the 63-inch enlistment minimum, so the sample depends on float or double storage. This is the one verified code defect the primary corrects. Sources: A'Hearn (2004, *EHB*); Komlos (2004, *Historical Methods*).
- **(d) Age at measurement** (C1; Claude-only). Within a war, cohort = enlistment year − age. The 1895–1904 cohort is measured at 21 in WWI and at 40 in WWII. Age, period and cohort are not jointly identified without a restriction (Fienberg and Mason 1985; Deaton 1997, ch. 2). **The primary does not resolve (d).** It imposes R1 and R2 (§4B) and reports the alternatives (S7–S10, S2c). See §10.
- **(e) Weights and covariates** (C5, F1). The census weights are unstated and cannot be rebuilt for WWII; nor can the region, occupation or town controls. Not fixable. This is why the T3 rows are `different-estimand` (§0).
- **(f) Adult occupation as a control** (F6, Codex-only). Occupation is an adult outcome. The primary omits it because the data force that; S20 reports it.
- **(g) SE type unstated** (C6). The primary uses individual-level sandwich SEs (White 1982). **Independence across recruits is an assumption, not an inference from deduplication.** The available grouping structures (force, force × enlistment year, candidate repeat pairs) are documented with counts (§4B), and S15 reports clustered alternatives. Five forces are too few for cluster-robust asymptotics (Cameron and Miller 2015, *JHR*), so force is never a clustering unit.
- **Bounded only:** birth year = enlistment year − floor(age) (S2-10; S16), and unflagged repeats (S2-8; S17).

## 3. Estimands
- **Original (T3 rows).** The weighted truncated-regression coefficient on each cohort dummy (reference 1885–94), conditional on region, occupation, town size and Attestation. The sample is the unrecovered N = 6,896.
- **New (recruit-pattern rows R-65, R-15, R-dec, R-rec; `different-estimand`).** b_k = the difference in the latent untruncated mean height between cohort k and 1885–94 among White SA-born recruits aged 21–49 in the surviving records, unweighted, holding force fixed, adjusting for growth at ages 21 and 22, under R1 and R2.
  - **Relation to the claim.** The authors read their covariate adjustment as compositional ("the cohort coefficients replicate the raw data … although more modestly", p.10), and the abstract reads the coefficients as cohort living standards "accounting for different selection across the forces". The new estimand shares that reading but not the conditioning set, the weights or the sample. It is therefore a different estimand (claims specification §c), and its findings describe recruit patterns on the surviving data. They are reported next to the T3 rows and never replace their verdict.
- **R-dec components.** d₁ = b(1865–74) − b(1875–84); d₂ = b(1875–84); d₃ = −b(1895–1904).
- **R-rec.** r = b(1915–20) − b(1895–1904).
- **T2.** m_k = the unweighted mean recorded height of cohort k in the T2 universe (§4A). e_j = m_j − m₄, j ∈ {1, 2, 3, 5, 6}. T2-dec uses e₁; T2-min uses all five.

## 4. Primary analyses (one per verdict row)
**Common data.**
- The S3 analysis sample, `dscratch("P09_FIM", "repro_r", "analysis_sample.rds")` on D:, built by the locked `repro_r/01_clean.R` (commit d0fbc1c). It covers all five forces (SAC, CMP, AOF, WWI from sheet `Data`; WWII from `WhitesWW2`).
- Sample rules as in `repro_r/decisions.md` D1–D4: White, SA-born, repeats dropped, enlisted 1890–1945, born 1865–1920, ages 21–49, height observed; complete covariates for colonial and WWI records. Ten-year cohorts with inclusive upper bounds.
- `modern/01_sample.R` checks that it reproduces `repro_r/output/table2_r.csv` (T2 total means) to 1e-6 before any estimate. If the check fails, nothing is estimated and the discrepancy is logged in DEVIATIONS.md. The override applies only to the computationally assessed rows: T2-c1, T2-c4, T2-dec and T2-min become not-testable, and every recruit-pattern finding (R-65, R-15, R-dec, R-rec) is not computable. The T3 rows keep their unconditional verdict `different-estimand`, and H3-15-all, F8-gap and F8-all stay not-testable (§0, §8A).

**A. T2 rows (verdict rows).**
- Universe: the whole S3 sample, including heights below 160.02 cm (as T2 includes them).
- Points m_k are computed as population descriptions of the surviving records. No inference enters T2-c1 or T2-c4.
- **Inference for T2-dec and T2-min: one family, Family D, of five elementary contrasts e₁, e₂, e₃, e₅, e₆.**
  - Var(m_k) = s_k²/n_k (sample variance, n − 1 denominator). Cov(e_j, e_l) = Var(m₄) for j ≠ l, since cohorts are disjoint. Normal reference.
  - **Simultaneous 95% intervals** e_j ± c_D·se(e_j), where c_D is the two-sided 95% quantile of max_j |Z_j| for Z ~ N(0, R_D), R_D the correlation matrix of the five contrasts. c_D is computed by `mvtnorm::qmvnorm(0.95, tail = "both.tails", corr = R_D)` with `GenzBretz(maxpts = 250000, abseps = 1e-6)`, seed 20261011. If the reported error exceeds 1e-5, maxpts is multiplied by 10 once; the error is reported.
  - The same intervals decide both T2-dec (e₁ only) and T2-min (all five). This is an intersection–union test with family-wise control over every component decision, so "all components positive" and "some component negative" are judged on the same intervals (Berger and Hsu 1996).
  - Recruits are treated as independent draws from the superpopulation of eligible recruits that generated the records (assumption; §2g).
- **Failure:** a cohort with fewer than two heights, or a non-finite c_D, makes every row that uses it not-testable.

**B. T3 recruit-pattern analysis (decides no verdict; T3 verdicts are `different-estimand`).**
- **Estimation sample and truncation point (coherent definition).** Truncation point c = 159.385 cm (62.75 in), the lower edge of the half-inch rounding interval of the 63-inch minimum. This corrects defect (c). The estimation sample is every S3 record with recorded height h ≥ c + 0.001 cm, so the sample and the truncation point are defined by the same number: every record above c is kept, including any recorded between c and 160.02, and every record at 160.02 (exactly 63 inches). The count with c < h < 160.02 is reported by force.
- **Model.** height_i ~ N(μ_i, σ²) truncated below at c, with
  μ_i = α + Σ_k b_k·1[cohort_i = k] + Σ_f φ_f·1[force_i = f] + g₂₁·1[age_i = 21] + g₂₂·1[age_i = 22],
  where:
  - cohorts are 1865–74, 1875–84, 1895–1904, 1905–14 and 1915–20 (reference 1885–94, as published);
  - forces are SAC, CMP, AOF and WWII (reference WWI);
  - age is integer age at enlistment.
  - There is no Attestation, region, occupation or town term, and no weights.
- **Identifying restrictions.**
  - **R1.** No age effect from 23 to 49: terminal height is reached by 23, and shrinkage before 50 is negligible.
  - **R2.** No within-force period trend: conditional on force, cohort and the growth dummies, enlistment year has no effect.
  - Both are card choices, not corrections, and neither is testable with these data (§10). S2c relaxes R2; S7–S10 relax R1.
- **Estimator.** The hand-coded truncated-normal log-likelihood of `repro_r/02_analysis.R` (`trunc_fit`; validated against Stata `truncreg` to 8e-4), with σ estimated on the log scale. BFGS from OLS start values, then Newton polish. **The R fit is the primary.**
  - **Convergence:** max |gradient| < 1e-5 and a negative-definite Hessian.
  - **Non-convergence:** retried from 20 starts perturbed by N(0, 0.1²) on every parameter (seed 20261011); the converged fit with the highest log-likelihood is used. If none converges, every R row is not computable.
- **Stata cross-check** (`modern/02b_truncreg_check.do`, batch mode): `truncreg height …, ll(159.385) vce(robust)` with height stored as double. If any b_k or contrast differs from R by more than 0.001, the discrepancy is **reconciled before anything is reported**, in this order:
  1. **Samples.** N and the record IDs used are compared. A difference is an implementation error; it is fixed in whichever script departs from the sample definition above, logged in DEVIATIONS.md, and both fits are rerun.
  2. **Likelihoods.** Both parameter vectors are evaluated in the R log-likelihood and in Stata's (`ml` evaluated at fixed parameters). A difference in the log-likelihood at the same parameters is an implementation error in one of the likelihoods; it is located and fixed, logged, and both are rerun.
  3. **Derivatives.** The analytic gradient and Hessian of the R likelihood are compared with numerical derivatives (`numDeriv`) at both solutions. If the R fit fails the convergence criteria at its own solution, it is restarted from the Stata solution.
  - Stata never replaces R as the primary. If, after steps 1–3, both fits satisfy the convergence criteria and still differ by more than 0.001, both are reported, the R fit is used, and the residual discrepancy is listed in DEVIATIONS.md.
- **Inference.** Sandwich SE, H⁻¹(Σ s_i s_i′)H⁻¹ × n/(n − 1), which is Stata's `vce(robust)` for ML. Normal reference.
  - **Family T: six elementary contrasts** b(1865–74), b(1915–20), d₁, d₂, d₃ and r, all linear in the coefficient vector, with their joint sandwich covariance.
  - **Structural redundancy.** The six contrasts are linear in only four parameters, b(1865–74), b(1875–84), b(1895–1904) and b(1915–20), and satisfy two exact identities: b(1865–74) = d₁ + d₂ and r = b(1915–20) + d₃. Their 6 × 6 correlation matrix R_T is therefore positive semidefinite with rank 4 by construction, never positive definite. This is expected and is not a failure.
  - **Simultaneous 95% intervals** θ_j ± c_T·se(θ_j), where c_T is the two-sided 95% quantile of max_j |Z_j| for Z ~ N(0, R_T). Because R_T is singular, c_T is computed on its independent subspace: eigendecompose R_T = QΛQ′, set eigenvalues below 1e-10 × λ_max to 0, form A = Q₄Λ₄^{1/2} from the retained eigenpairs, draw Z = AW with W ~ N(0, I₄), and take the 0.95 quantile of max_j |Z_j| over 2,000,000 draws (seed 20261011). The Monte Carlo standard error of c_T (by the order-statistic binomial interval) is reported; the 2,000,000 draws are fixed and not extended. These intervals are the single interval construction for every R-row decision: significance (A3 condition 2), the credible null (A4a) and every conjunction.
  - **R-dec directional p.** For each component, the one-sided p for H₀: d_j ≤ 0. The intersection–union p is the maximum of the three. It is reported; the decision uses the simultaneous intervals.
  - Unadjusted two-sided p-values are reported for every contrast and decide nothing.
- **Failure rules (symmetric; they apply whatever the direction of any estimate).**
  - **Non-identification:** the design matrix is rank-deficient (for example, a cohort or force with no observation in the estimation sample). The R rows using the unidentified parameter are not computable. **No minimum cell size is imposed**; small cells are reported (below).
  - **SE failure (estimation failure, distinct from structural redundancy):** the R rows using a contrast are not computable if (i) its sandwich SE is non-finite or ≤ 0, or (ii) the 4 × 4 sandwich covariance block of the four cohort coefficients is not positive definite (smallest eigenvalue ≤ 1e-10 × largest), which shows up as fewer than four retained eigenvalues of R_T. If (ii) holds, every R row is not computable, because c_T is defined jointly. More than four retained eigenvalues cannot occur under correct coding; it is treated as an implementation error, fixed and logged in DEVIATIONS.md. The model-based SE is reported (S14) and never substitutes.
- **Reported:**
  - N by force × cohort and by force × age group (21, 22, 23–49); cells under 30 are marked in the table as a reading aid, and the mark changes no estimate, finding or verdict;
  - the number of heights at exactly 63 inches by force, and between c and 160.02;
  - σ̂, the log-likelihood and c_T;
  - **grouping structure (§2g):** the number of force × enlistment-year groups, with minimum, median and maximum sizes and the largest group's share of N; the number of candidate repeat pairs (forename + surname + birth year) remaining in the sample;
  - the maximum leverage of any single force (S21).

## 5. Admissible sensitivities (exhaustive; reported, never verdict-determining)
Labels: **[same target]** varies the estimator, inference or a construction choice for the §3 recruit-pattern estimand; **[changed target]** changes the population, the conditioning set or the functional (A4d); **[diagnostic]** is a check, not an estimate of any claim. None votes. All use the §4 sample and inference unless stated.

**Decomposition of the primary (T3).**
1. **[diagnostic] Anchor.** The published col 1 analogue on the surviving data: cohort + Attestation, no force or age terms, truncation at 160.02 with the heights at exactly 63 inches kept (as with float storage). **Explicit implementation:** R sample h ≥ 160.02 − 0.001 with the density normalised by 1 − Φ((160.02 − μ)/σ); Stata `truncreg … , ll(160.0199)` with height stored as double. This places probability mass at the truncation point and is internally incoherent; that is why it is a diagnostic. It should reproduce the S5 proxy (`s5_headline_proxies.csv` p1) to 1e-3; a failure is logged in DEVIATIONS.md.
2. **One change at a time from the primary:** (a) [same target] drop force FE; (b) [same target] drop the growth dummies; (c) [same target] add Attestation (relaxes R2); (d) [diagnostic] truncation at 160.02 with the heights at 63 inches kept, implemented as in S1.

**Truncation and rounding.**

3. [same target] c = 159.71 (62.875 in; quarter-inch rounding), sample h ≥ 159.71 + 0.001.
4. [same target] Strict: c = 160.02, sample h ≥ 160.02 + 0.001 (heights at 63 inches dropped).
5. [changed target] Higher cut: c = 164.465, sample h ≥ 164.465 + 0.001 (65 in and above).
6. [same target] **Interval-rounded truncated likelihood.** Each recorded height is treated as lying in [h − w/2, h + w/2], intersected with the truncated support [c, ∞). With L_i = max(c, h − w/2) and U_i = h + w/2, the likelihood contribution is [Φ((U_i − μ_i)/σ) − Φ((L_i − μ_i)/σ)] / [1 − Φ((c − μ_i)/σ)], with c = 159.385 and the §4B sample. The lower endpoint is clipped because rounding intervals of records near c cross it. **Empty intersections:** a record with U_i ≤ c has no support and is dropped, with the count reported; on the §4B sample (h ≥ c + 0.001) this cannot occur, so a non-zero count is an implementation error, fixed and logged in DEVIATIONS.md. (a) w = 1.27 cm (half inch); (b) w = 0.635 cm (quarter inch). Same convergence rules and sandwich inference as the primary.

**Age at measurement: alternatives to R1.**

7. [same target] Growth dummies for ages 21–24 (terminal height at 25).
8. [changed target] Sample restricted to ages 23–39 (no growth, little shrinkage), truncation as the primary.
9. [same target] age + age² in place of the growth dummies (identification by functional form and binning; the C1 check).
10. [same target] **External shrinkage grid with observation-specific truncation.** Adjusted height h*_i = h_i + s·max(0, age_i − 35), and the truncation point moves with it: c_i = c + s·max(0, age_i − 35). The likelihood uses c_i for each record (Stata `ll(varname)` for the check); the sample is h*_i ≥ c_i + 0.001, which is the primary sample. s ∈ {0.05, 0.10} cm per year. **Provenance:** these are assumed values from outside the data. Sorkin, Muller and Andres (1999, *Am. J. Epidemiol.* 150: 969–977; Baltimore Longitudinal Study of Aging) report a cumulative height loss of about 3 cm for men between ages 30 and 70, which is about 0.075 cm per year. The grid brackets that average rate from below and above. No S5 run used shrinkage, so no result informed the grid (see §10).

**Estimator and inference.**

11. [same target] **Heteroskedastic truncated normal.** As the primary, with log σ_i = γ₀ + Σ_f γ_f·1[force_i = f] + Σ_k γ_k·1[cohort_i = k] (same references). Sandwich SEs, the same convergence rules, and the Family T simultaneous intervals recomputed by the rank-4 subspace rule of §4B. Under truncation a misspecified common σ biases the location coefficients, and sandwich SEs do not repair that; this sensitivity is the check.
12. [diagnostic] OLS on the §4B sample (no truncation correction), HC1. It is biased under truncation and does not substitute for S11.
13. [changed target] Median regression on the §4B sample, with a pairs bootstrap (B = 999, seed 20261011). It targets the conditional median of the truncated distribution, not the latent mean.
14. [same target] Model-based (−H⁻¹) SE for the primary, with c_T recomputed by the rank-4 subspace rule of §4B.
15. [same target] **Clustered inference** (§2g). (a) CR1 sandwich clustered by force × enlistment year, normal reference, number of groups reported; (b) pairs cluster bootstrap over force × enlistment-year groups, B = 999, seed 20261011, percentile intervals; (c) CR1 with each candidate repeat pair (forename + surname + birth year, across rows) merged into one cluster and all other records singletons. Force alone is never a clustering unit.

**Data construction.**

16. [same target] Birth year − 1 for all colonial and WWI records (the S2-10 bound).
17. [same target] Drop the later copy of the 67 unflagged name + birth-year repeats (S2-8).
18. [diagnostic] Five-year cohorts, reference 1890–94: the cohort profile only, mapped to no claim.
19. [changed target] **Relaxed complete-case rule.** Colonial and WWI records excluded in S3 only for missing region, occupation or town are added back (these covariates do not enter the primary). Records still need height, age, birth year and force. The number added, by force and cohort, is reported.

**Changed population or conditioning set (A4d; never verdict-determining).**

20. [changed target] Colonial forces + WWI only (no WWII, so cohorts ≤ 1895–1904; R-65 and the R-dec components only).
   - With region, occupation (S3 Armstrong coding), town flag and Attestation, as published.
   - Run unweighted, and with the S3 post-stratification weights (`repro_r/decisions.md` D7).
   - Repeated without occupation (F6).
21. [changed target] Leave one force out (five runs).
22. [changed target] Drop the horse-riding forces SAC and CMP.

**Descriptive (T2).**

23. [changed target] T2 means within ages 23–49 only, and the Family D contrasts on those means.
24. [diagnostic] Whether m₁ is the maximum of the six cohort means.
25. [diagnostic] Height-by-age profiles within WWI and within WWII, which illustrate the APC problem.

## 6. Fixed choices
- **Data:** the surviving vintage (S3 sample, d0fbc1c). **Cohorts:** ten-year, reference 1885–94. **Force reference:** WWI. **No weights.**
- **Missing data:** the S3 rules (complete cases for colonial and WWI covariates; WWII kept without covariates). Records with missing age are dropped from B (counts reported). S19 relaxes the covariate rule.
- **Multiplicity families and interval construction.**
  - **Family D (verdict rows T2-dec, T2-min):** five elementary contrasts e₁, e₂, e₃, e₅, e₆; simultaneous 95% sup-t intervals (§4A).
  - **Family T (recruit-pattern rows R-65, R-15, R-dec, R-rec; no verdict):** six elementary contrasts; simultaneous 95% sup-t intervals (§4B).
  - **One interval construction per family decides everything.** "Adjusted CI excludes 0" (A3 condition 2), the credible null (A4a) and every conjunction use the same simultaneous intervals. No Holm or Bonferroni step is used, so no discordance between a p-value rule and an interval rule can arise.
  - T2-c1 and T2-c4 have no inference.
- **Boundary rules.**
  - |b| = 0.5|b₀| meets the floor (A3).
  - **A8 point bands (T2-c1, T2-c4) are closed:** an estimate equal to an endpoint is inside the band.
  - **A4a credible-null intervals are open:** a simultaneous CI endpoint equal to ±0.5b₀ is not "within (−0.5b₀, 0.5b₀)", so the credible null fails at equality.
  - An estimate of exactly 0, or a CI endpoint at exactly 0, counts as "sign not established" and "CI includes 0".
  - Comparisons use unrounded values.
- **Seeds:** 20261011 (`set.seed`; L'Ecuyer-CMRG for S13 and S15b; `mvtnorm` critical values).
- **Scripts:** `modern/01_sample.R`, `02_primary.R`, `02b_truncreg_check.do`, `03_sensitivities.R`, `04_verdicts.R`. Output: `modern/results.md`, `modern/verdicts.csv`, `modern/sessionInfo.txt`.

## 7. Margins and their provenance
**Verdict rows.**
| Row | Confirm | Provenance |
|---|---|---|
| T2-c1 | 157.824 ≤ m₁ ≤ 192.896 | A8 point default (±10%) |
| T2-c4 | 156.303 ≤ m₄ ≤ 191.037 | A8 point default (±10%) |
| T2-dec | simultaneous CI of e₁ entirely > 0 | A8 comparative default; A4b ladder |
| T2-min | every simultaneous CI of e_j entirely > 0 | A8 comparative default; universal wording, so a conjunction; A4b ladder |
| H3-65, H3-15, H3-dec, H3-rec | none: verdict `different-estimand` | §0 (Codex required change 1) |

**Recruit-pattern rows (reported; no verdict).**
| Row | "Supported" | Provenance |
|---|---|---|
| R-65 | same sign, simultaneous CI > 0, b ≥ 0.514 | A3 (50% of 1.028) |
| R-15 | same sign, simultaneous CI > 0, b ≥ 0.7755 | A3 (50% of 1.551) |
| R-65 / R-15 credible null | simultaneous CI within (−0.514, 0.514) / (−0.7755, 0.7755) | A4a |
| R-dec | simultaneous CIs of d₁, d₂ and d₃ all entirely > 0 | A8 comparative default; "unilaterally", so a conjunction |
| R-rec | simultaneous CI of r entirely > 0 | A8 comparative default |

- No ceilings.
- **Plausibility flag** (A8; decides nothing): |b| > 1.5|b₀|, that is |b| > 1.542 (R-65) or |b| > 2.3265 (R-15), so large negative estimates are flagged too.
- **Low discriminatory value of the T2 point bands.** The A8 ±10% band on a height level of 175 cm allows ±17.5 cm, so it cannot fail on any plausible estimate. It is applied as written, because A8 forbids author bands, and no replacement is chosen from S5 evidence (§10). The S4 rounding and tolerance comparison is reported next to it and decides nothing. The informative T2 tests are the comparative rows.

**Disclosure.** S2, S4 and S5 numbers seen before this card, all bearing on the rows:
- **Published.** Col 1: 1865–74 1.028 (t 2.34); 1875–84 0.353 (t 1.25); 1895–1904 −0.0494 (t −0.13); 1905–14 0.968 (t 2.38); 1915–20 1.551 (t 3.69). Col 2 (force controls): 1865–74 0.510 (t 1.10); 1915–20 0.576 (t 1.24); no cohort coefficient significant. Col 8: 1905–14 0.728; 1915–20 1.342; WWII dummy 6.334.
- **T2 on the surviving vintage (S4 pair B).** 175.38, 174.69, 174.07, 173.57, 174.47 and 174.78 cm for the six cohorts. The T2 SDs are 6.35–6.83. All five e_j are positive in points (the smallest is about 0.5 cm).
- **Age structure.** WWI 1865–74 mean age 43.7; WWI 1895–1904 21.2; WWII 1885–94 47.5; WWII 1895–1904 39.7; WWII 1915–20 22.8. Mean WWII height falls from 175.08 (ages 21–22) to 173.29 (41–45); WWI height rises with age. At exactly 160.02 cm: 41 WWII heights, 19 WWI, 1 AOF. Below it: 67, all WWII.
- **S5 proxies** (surviving vintage, N 9,149; 1865–74 / 1915–20; SE in parentheses):
  - base, cohort + Attestation: 1.346 (0.430) / 1.134 (0.376);
  - with force dummies: 0.669 (0.455) / 0.177 (0.410), with 1875–84 0.116 and 1895–1904 −0.976 (0.377);
  - without Attestation: 1.413 / 0.981;
  - strict truncation: 1.418 / 0.946;
  - ll(159.385): 1.320 / 1.110;
  - OLS with age + age²: 1.70 (0.62) / 0.33 (0.70), against OLS base 1.16 / 1.04;
  - birth year − 1: 1.182 / 1.726;
  - colonial + WWI with covariates: 1865–74 0.457 (0.439), 1895–1904 −1.085 (0.492);
  - col 8 analogue: WWII dummy 6.431 with Attestation, 0.909 without.
- **Weights (WWI column).** 1865–74 is 2.324 unweighted and 1.270 with post-stratification weights (t 1.77 model-based, 1.29 sandwich).

The primary (force FE + growth dummies, no Attestation, c = 159.385) has not been run, nor has any simultaneous interval, the heteroskedastic model, the interval-rounded likelihood or any clustered alternative. The nearest run seen is the force-dummy proxy, which includes Attestation and truncates at 160.02; it suggests that R-15 will not reach its floor. Force FE enters on the abstract's wording and on C2/F7, which both models agree on. **The choice was made with that proxy in view, and this disclosure does not prove that nothing was tuned.** The v2 reclassification of the T3 rows as `different-estimand` and of T2-dec/T2-min under A4b follows the Codex review; the A4b choice removes "overturned" from rows whose points were already known to be positive. All margins are A3, A4 and A8 defaults.

## 8. Verdict tables (checked in order; the first rule that applies decides; exhaustive)

### 8A. Verdict rows
**T2-c1 and T2-c4** (A8 band alone; X = m₁ or m₄; band [lo, hi] from §7):
| # | Condition | Verdict |
|---|---|---|
| 0 | computation fails, or the §4 reproduction check fails | not-testable |
| 1 | lo ≤ X ≤ hi | confirmed |
| 2 | X < lo | qualified (mean below the stated value) |
| 3 | X > hi | qualified (mean above the stated value) |

**T2-dec** (comparative ">", inference-only, A4b ladder; Family D simultaneous interval of e₁):
| # | Condition | Verdict |
|---|---|---|
| 0 | computation fails (§4A failure rule) or the reproduction check fails | not-testable |
| 1 | CI of e₁ entirely > 0 | confirmed |
| 2 | CI of e₁ includes 0, e₁ > 0 | qualified (inference-fragile) |
| 3 | e₁ ≤ 0 (whatever the CI) | weakened |

**T2-min** (conjunction over e₁, e₂, e₃, e₅, e₆; inference-only, A4b ladder; Family D simultaneous intervals):
| # | Condition | Verdict |
|---|---|---|
| 0 | any component cannot be computed, or the reproduction check fails | not-testable |
| 1 | every CI entirely > 0 | confirmed |
| 2 | some CI includes 0, every point e_j > 0 | qualified (inference-fragile) |
| 3 | some point e_j ≤ 0 | weakened |

The rows are exhaustive: if every point is > 0, no CI can lie entirely < 0, so rows 1–2 cover that case; otherwise row 3 applies. "Overturned" cannot be reached on T2-dec or T2-min (A4b), including when a component interval lies entirely below 0; that case is reported as weakened with the interval shown.

**H3-65, H3-15, H3-dec, H3-rec:** `different-estimand`, unconditionally (§0). The recruit-pattern findings of §8B are reported beside them.

**H3-15-all, F8-gap, F8-all:** not-testable.

### 8B. Recruit-pattern findings (reported beside the T3 rows; they decide no verdict)
**R-65 and R-15** (A3/A4 margins; Family T simultaneous intervals; b₀ = 1.028 or 1.551):
| # | Condition | Finding |
|---|---|---|
| 0 | not computable (§4B failure rules) | not computable |
| 1 | CI entirely < 0 | reversed |
| 2 | CI within (−0.5b₀, 0.5b₀) | credible null |
| 3 | CI entirely > 0, b ≥ 0.5b₀ | supported |
| 4 | CI entirely > 0, b < 0.5b₀ | supported, below floor |
| 5 | CI includes 0, b > 0 | not established |
| 6 | CI includes 0, b ≤ 0 | not established, direction lost |

**R-rec** (comparative ">"; Family T simultaneous interval of r):
| # | Condition | Finding |
|---|---|---|
| 0 | not computable | not computable |
| 1 | CI of r entirely > 0 | supported |
| 2 | CI of r entirely < 0 | reversed |
| 3 | CI includes 0, r > 0 | not established (points hold) |
| 4 | CI includes 0, r ≤ 0 | not established, direction lost |

**R-dec** (conjunction over d₁, d₂, d₃; Family T simultaneous intervals; directional intersection–union p reported):
| # | Condition | Finding |
|---|---|---|
| 0 | any component not computable | not computable |
| 1 | at least one simultaneous CI entirely < 0 | reversed (for the named component) |
| 2 | every simultaneous CI entirely > 0 | supported |
| 3 | no CI entirely < 0, some CI includes 0, every point > 0 | not established (ordering holds in points) |
| 4 | no CI entirely < 0, some CI includes 0, some point ≤ 0 | not established, ordering broken in points |

Because the intervals are simultaneous across all six Family T contrasts, rows 1 and 2 are decisions with family-wise error control at 5%, not decisions on unadjusted components.

- Every finding is reported with its S1–S25 values beside it, labelled "reported; does not vote".
- "Strengthened" is not used anywhere.

**Summaries and coverage.** Report, for the verdict rows, the rows assessed, not-testable and different-estimand, and the weakest assessed verdict within T2, ordered overturned < weakened < qualified < confirmed. Report the recruit-pattern findings as a separate block, never merged with verdicts. Nothing is aggregated across families.

## 9. Codex review notes and responses
**Codex v1 review** (reviews/P09_FIM_codex_S6card.md): approve-with-changes, 9 required changes, all addressed in v2.
1. **T3 as `different-estimand`.** All four T3 rows now take the verdict `different-estimand`, fixed in advance (§0, §7, §8A). The primary T3 analysis is reported as conditional recruit-pattern findings R-65, R-15, R-dec and R-rec with their own finding labels, which cannot confirm or overturn the published estimand (§3, §8B). The v1 argument that the forced change preserved the estimand is withdrawn.
2. **Correction claims narrowed.** Only the truncation fix is called a correction of a verified defect (§0, §2c). Attestation is no longer called a bad control: the F6 dispute over its coding is recorded, the binned-cohort point is conceded, and dropping it is restated as identifying restriction R2 (§2b, §4B). Force FE is described as a composition adjustment that does not address within-force selection, citing Bodenhorn, Guinnane and Mroz (§2a). R1 is stated as an identifying assumption (§4B, §10).
3. **Conjunction inference repaired.** Each family now uses simultaneous sup-t intervals across its elementary contrasts (Family D: five T2 contrasts; Family T: six T3 contrasts), and the same intervals decide both "all components positive" and "some component reversed" (§4A, §4B, §8). R-dec reports directional one-sided component p-values and their intersection–union maximum (§4B).
4. **Protocol conflicts resolved.** (a) Holm and Bonferroni are removed; one simultaneous interval construction per family decides A3 condition 2, the A4a credible null and the conjunctions, so no p-value can override a displayed interval (§6). (b) T2-dec and T2-min are classified as inference-only and follow the A4b ladder, with "overturned" unreachable (§0, §8A); the choice and its timing are disclosed (§7).
5. **Gates and substitutions removed.** The N < 30 rule is deleted; non-identification means rank deficiency only, and small cells are reported and flagged (§4B). A failed sandwich SE makes the row not computable; the model-based SE never substitutes (§4B, S14). R–Stata discrepancies are reconciled in the order samples → likelihoods → derivatives before reporting, and R remains the primary (§4B).
6. **Rounding and truncation specified coherently.** The primary sample is defined by the truncation point itself (h ≥ c + 0.001), so every record above c is kept (§4B). An interval-rounded truncated likelihood is added (S6, half- and quarter-inch). The shrinkage grid now moves each record's truncation point with its adjusted height (S10). Keeping records at exactly 160.02 has an explicit R and Stata implementation, labelled diagnostic (S1, S2d).
7. **Heteroskedastic-variance model added.** S11 lets log σ vary by force and cohort, with the same inference. OLS and median regression are relabelled as a diagnostic and a changed target, and neither substitutes for S11 (S12, S13).
8. **Independence justified as an assumption.** §2g states independence as an assumption; §4B reports the force × enlistment-year grouping and the remaining candidate repeat pairs with counts; S15 adds CR1 and a pairs cluster bootstrap by force × enlistment year and a repeat-pair cluster variant. Force is never a clustering unit.
9. **Sensitivity definitions completed.** The shrinkage grid is tied to an external source, the ≈3 cm loss for men aged 30–70 in Sorkin, Muller and Andres (1999), with a provenance statement (S10; §10). Every sensitivity carries a [same target], [changed target] or [diagnostic] label; median regression (S13), the age-restricted sample (S8) and the age-restricted T2 means (S23) are changed targets. S19 relaxes the colonial/WWI complete-case rule for covariates the primary does not use. None votes.

**Codex v2 compliance check** (reviews/P09_FIM_codex_S6card_v2.md): revise again; earlier changes 1, 2, 4, 7, 8, 9 addressed and 3, 5, 6 partly. All five corrections are made in v3.
1. **Family T singularity.** R_T is rank 4 by construction (b(1865–74) = d₁ + d₂, r = b(1915–20) + d₃). The positive-definite gate is removed; c_T is computed on the four-dimensional independent subspace, and structural redundancy is separated from estimation failure (a non-positive-definite 4 × 4 cohort block) (§4B). This completes earlier changes 3 and 5.
2. **S6 support.** The lower integration endpoint is max(c, h − w/2), and empty intersections are defined and counted (§5 S6). This completes earlier change 6.
3. **Precedence.** A failed reproduction check now makes only the computationally assessed rows not-testable (and the R findings not computable); the T3 rows stay `different-estimand` (§4).
4. **Boundaries.** A8 point bands are closed; A4a credible-null intervals are open (§6).
5. **Plausibility flag.** |b| > 1.5|b₀| (§7).

Optional suggestions (v1 review):
1. Adopted: the broad T2 bands are kept as written and described as having low discriminatory value; nothing replaces them (§7, §10).
2. Adopted: the headline list is reconciled with the A1 union in §1. Unresolved issues are carried into §10 for v3 under A9.

## 10. Known limitations at freeze
1. **Surviving vintage, not the published sample.** No 2022 file exists. The S3 sample has more recruits than the paper, most of them WWII (5,681 against 3,601), and the published WWII covariate filter cannot be applied. Every verdict and finding is conditional on this vintage.
2. **No verdict on the published T3 estimand.** Because the weights and the region, town and occupation controls cannot be rebuilt, the four T3 rows are `different-estimand`. The card therefore cannot confirm or overturn the paper's conditional cohort effects; the recruit-pattern findings describe the surviving records only.
3. **Age–period–cohort is not identified.** R1 (no age effect at 23–49) attributes the within-WWII decline of height with age to cohort. If that decline is shrinkage or age-selective enlistment (footnote 6 of the paper), the recruit-pattern findings overstate the cohort gaps among WWII recruits. R2 (no within-force period trend) is equally untestable. S2c and S7–S10 report the alternatives. R1 and R2 are card choices, made knowing the age-quadratic and no-Attestation results in S5.
4. **Within-force selection.** Force FE removes force-level composition only. Selection that changes across cohorts within a force is not addressed.
5. **Force FE was chosen with the S5 force-dummy proxy in view** (§7 Disclosure). The basis is the abstract's wording and the agreed C2/F7 finding.
6. **Attestation coding is disputed** (F6). The card neither relies on Claude's year − 1900 inference in the primary nor resolves the dispute; it enters only S1, S2c and S20.
7. **Uninformative point bands.** The A8 ±10% band on 175 cm (±17.5 cm) cannot fail. It is applied as written, because A8 forbids author bands.
8. **A4b on T2 comparatives was adopted with the points known.** All five e_j were positive in S4, so the A4b ladder removed an outcome that was already implausible. The disclosure stands.
9. **Truncation point and rounding.** c = 159.385 assumes half-inch rounding at the 63-inch minimum and a common minimum across forces. The force-specific minima are unknown, and WWII has 67 heights below 63 inches. S3–S6 bound the consequence.
10. **Shrinkage grid provenance.** The values s = 0.05 and 0.10 cm per year bracket the average loss of about 0.075 cm per year that Sorkin, Muller and Andres (1999) report for men aged 30–70. Their study is of modern American men, and loss accelerates with age, so the rate at 35–49 may lie below the grid. The grid enters S10 only and informs no verdict.
11. **Independence is assumed.** The individual-level sandwich ignores any shared recruitment shocks; S15 is the only check, and its force × enlistment-year groups are few for some forces.
12. **Birth year and repeats** are bounded (S16, S17), not corrected.
13. **F8 and H3-15-all are not-testable**, so the card cannot assess the paper's international-ranking claim, its "across all regions and occupations" claim, or "all classes".
14. **Inference covers sampling variability among recruits only.** It does not cover transcription error, selection into enlistment, or the vintage gap.
15. **c_T is a Monte Carlo quantile.** Because R_T is singular, c_T comes from 2,000,000 fixed-seed draws on the rank-4 subspace rather than from `qmvnorm`. Its Monte Carlo error is reported; a contrast whose simultaneous CI endpoint lies within that error of a decision boundary is flagged as boundary-sensitive, and the finding is still read from the computed c_T. The v3 rules were not put through a further Codex check (A9).
