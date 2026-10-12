# Method card: P01_BF, numeracy of Africans, Asians and Europeans (Cape court registers)

Status: v3 (2026-10-11).
- History: v1, written after the S5 reconciliation in `audit.md` → Codex review (`reviews/P01_BF_codex_S6card.md`; approve-with-changes, 8 required changes) → v2 → Codex compliance check → v3, frozen (A9).
- Margins follow AMENDMENTS.md A3, A4, A8 and A8a. The card author chose no band, no ceiling and no verdict gate informed by results. One exception is disclosed: the reproduction tolerances (§4) were set with knowledge of the archived Stata–R discrepancy (4.4e-8); they can only make rows not-testable (§10.12).
- To be FROZEN with the commit message "FREEZE S6 card P01". Issues not fully resolved are listed in §10.

Rights class: open (court-record transcriptions). The Brazil file (`br300407.dta`, restricted-licence) was not recovered and plays no part here. Scripts run locally; data are read from `D:\Data\ReplicateMe\P01_BF\...` through `tools/paths.R`.

## 0. Type of analysis
The primary analysis is **one corrected central analysis**, with a classification for each row.

- **T6 rows (H1, H2): (i) a correction of verified code and data errors, plus an inference upgrade.** The estimator is the authors' own: a logit of `exactage` on female2, age23, birth-decade dummies and origin dummies, with the discrete change ×125 evaluated at the sample means of the non-origin covariates. Two verified errors are corrected:
  - **S5-1, origin coding** (Claude; verified against the source workbook's own `origincountry`). "Kust"/"Cust" (the Coromandel Coast, 4 obs) are coded Cape-born, "Westcoast" (Angola in the workbook, 2 obs) is coded Cape-born, and "Coehin" (Cochin, 1 obs) is coded Chinese (do-file l.1575–1579).
  - **F2, the contrast definition** (Codex; verified by reading l.1656–1657 and in Claude's replica `mem()` in `compare/s5_checks/s5_01_T6_decomp.R`). `mfx` switches one origin dummy while the other, mutually exclusive origin dummies sit at their sample means. The printed number is therefore not a contrast with Cape-born slaves, which the table notes ("'Constant' refers to Cape-born slaves") and the prose ("more numerate than the Cape-born slaves") describe. The correction evaluates the switch with every other origin dummy at 0.

  The point estimates change, so A4b does not apply. The full A3/A4 ladder applies, including the symmetric credible null.
- **T9_r5 (H3): (ii) an inference-only upgrade.** No code survives for Table 9. S5-3 showed that the published estimate is the unconditional difference in cell ABCC; this reproduces all ten T9 estimates within 0.09, and T9_r5 as −43.82 against −43.9. The primary keeps that unconditional estimator and its point estimate and changes only the inference. The origin corrections do not touch the Khoesan. A4b applies: "overturned" cannot be reached.
- Nothing in the primary is (iii) an uncertainty propagation or (iv) a new estimator. Alternative estimators (AME, LPM, Firth, controlled T9) appear only in §5.

**A4c.** No headline row is an odds ratio. The analogous problem here is that the authors state ABCC-**point** differences as **percentages** ("51 per cent more numerate"; S0 (e)12, S5 interpretation audit, F7). Following the A4c principle, each T6 claim is split into two verdict rows. The **-pt** row is judged on the table's estimand, the ABCC-point contrast. The **-rel** row is judged on the literal wording, the ratio of the two model-predicted ABCC levels, on the log scale (A4a).

## 1. Claims family (frozen headline rows) and interpretations
The five `headline = 1` rows in `claims/claims.csv` (A1 union) map to ten verdict rows. Interpretations are quoted from `claims/claims_spec.md`. Each verdict row has exactly one primary analysis (§4).

**H1, European advantage.** `T6_r4`, 51.38 (p 0.00), N = 1,802. "the Europeans were 51 per cent more numerate than the Cape-born slaves" (p.645); the settler–slave gap that "foreshadowed extreme income inequality" (abstract).

**H2, the Cape-born advantage over imported slaves.** `T6_r5` south-east Asian −28.63 (p 0.00); `T6_r6` Indian −20.25 (p 0.01); `T6_r8` Mozambican −21.38 (p 0.00). The prose reads "the Indians and south-east Asians were 29 and 20 per cent less numerate, and the slaves born in Mozambique (or Madagascar and Mauritius) were 21 per cent less numerate" (p.645). That sentence transposes the two Asian numbers (S5-9, C7, F7). The conclusion reads "Slaves from India, Indonesia, and Mozambique had significantly lower levels of numeracy than slaves born in the Cape Colony" (p.653), and calls the advantage "an important finding of this study".

**H3, the Khoesan fall.** `T9_r5`, −43.9* (p 0.000), n = 217: Khoesan ABCC in the 1750s–80s cohort minus the 1650s–1740s cohort, with no controls. "we found a sharp fall in their numeracy levels for the birth period following their integration into the settler economy" (p.654).

| Row | Source | Claim | Type (A3/A8) | b₀ (card scale) |
|---|---|---|---|---|
| H1-pt | T6_r4 | Europeans 51.38 ABCC points above Cape-born slaves | magnitude | +51.38 |
| H1-rel | T6_r4 | "51 per cent more numerate": ABCC_Eur / ABCC_Cape = 1.5138 | magnitude, log ratio | ln 1.5138 = +0.4146 |
| H2-SEA-pt | T6_r5 | south-east Asians 28.63 points below | magnitude | −28.63 |
| H2-SEA-rel | T6_r5 | "per cent less numerate": ratio 0.7137 | magnitude, log ratio | ln 0.7137 = −0.3373 |
| H2-IND-pt | T6_r6 | Indians 20.25 points below | magnitude | −20.25 |
| H2-IND-rel | T6_r6 | ratio 0.7975 | magnitude, log ratio | ln 0.7975 = −0.2263 |
| H2-MOZ-pt | T6_r8 | Mozambicans 21.38 points below | magnitude | −21.38 |
| H2-MOZ-rel | T6_r8 | ratio 0.7862 | magnitude, log ratio | ln 0.7862 = −0.2405 |
| H2-all | conclusion p.653 | all three imported groups "significantly lower" than Cape-born | strict comparative "<" (A8), conjunction | sign and significance only |
| H3 | T9_r5 | unconditional Khoesan fall of 43.9 points, early → middle cohort | magnitude; inference-only (A4b) | −43.9 |

- **The -rel magnitudes.** ρ₀ = 1 + v/100, where v is the T6 value. The prose rounds these to integers and transposes the two Asian rows. Both the T6 table and the S5 audits (both models) identify the transposition as a copy error, so the table assignment is used. The literal prose assignment (SE Asian 20, Indian 29) is sensitivity 12 and does not vote.
- **A8/A8a point bands do not apply.** No headline row is a level, count or share claim. The Europe "between 92 and 93" levels (Figure 4) are not headline rows.
- **What "confirmed" means.** A confirmed magnitude row meets the protocol's minimum: the same sign, multiplicity-adjusted significance and at least 50% of the stated magnitude (A3). It does not mean numerical agreement with the quoted number or percentage. A8 sets no ceiling, so a confirmed row may be much larger than stated; the plausibility flag (§7) reports that case.
- **What the estimates establish, and what they do not.** Each verdict concerns the estimand in §3: a difference (or ratio) in the predicted share of non-heaped ages, scaled to ABCC, among accused people in the Court of Justice records aged 23–72.
  - *Numeracy.* ABCC measures age heaping. Reading it as numeracy is the authors' construct, and the card does not test it. Sensitivity 18 (age awareness) is report-only.
  - *Population.* Nothing here concerns the Cape population at large. The sample is accused people, and origin rests on the authors' unauditable matching to the Robben Island lists (`origin2.do` is missing; F5).
  - *Causation.* The T6 contrasts are conditional associations, and the H3 difference is an unconditional cohort comparison. Neither identifies an effect of origin, of the slave lodge, or of integration into the settler economy.
- **Not-testable** (no verdict row; listed for coverage): the explanations of the Cape-born advantage ("formal education in the slave lodge, imitation behaviour, and, perhaps, better nutritional status"); "foreshadowed extreme income inequality"; and any reading of the gaps as numeracy rather than age awareness.

**Stars.** `stars05` = 2. Table 6 prints p-values and no stars; Table 9 prints p-values and "*" at 10%. The verdicts use p-values directly.

## 2. Defects addressed
- **(a) Origin misclassification** (S5-1; Claude only). Correct the 7 records as in §4. Effect in S5 (published contrast convention): Indian −20.25 → −22.94.
- **(b) The contrast definition** (F2; Codex only). Source: Williams (2012, *Stata Journal* 12(2): 308–331) on discrete changes for categorical regressors; Long and Freese (2014), *Regression Models for Categorical Dependent Variables Using Stata*, 3rd edn.
- **(c) Inference.** Conventional iid logit SEs (R2, S5-11) and no multiplicity control. Ages within a court volume were recorded by the same clerks in the same years, so heaping errors are plausibly correlated within volumes. Sources: Cameron and Miller (2015, *JHR*); MacKinnon and Webb (2017, *J. Applied Econometrics*); Roodman, MacKinnon, Nielsen and Webb (2019, *Stata Journal*); MacKinnon, Nielsen and Webb (2024, arXiv:2406.00650) on cluster-jackknife inference for logit; Carter, Schnepel and Steigerwald (2017, *REStat*) on the effective number of clusters; Holm (1979).
- **(d) Separation.** Sparse birth-decade and origin cells (16 Chinese; 28 early Khoesan) can produce infinite maximum-likelihood estimates that a converged glm hides. Source: Konis (2007, DPhil thesis, Oxford) on linear-programming detection; Kosmidis and Schumacher, `detectseparation` (R package).
- **(e) Table 9 model and p-value unstated** (S5-3). The early Khoesan cohort has 28 people, and the printed p (0.000) does not match the Welch test (0.0014).

**Documented, not corrected in the primary** (no verified error, or not fixable):
- the birth-decade convention (S5-2/F1, disputed): sensitivity 10;
- origin-matching integrity and denominators (F5): not testable; §10;
- numeracy against age awareness (interpretation audit): sensitivity 18, a changed population;
- selection into the court sample: T8 cols 2–3 have no surviving code; not addressed;
- reporting issues off the headline estimands (F3, F4, F6, S5-4 to S5-8, S5-12): logged in S5 only.

## 3. Estimands
**Original T6 estimand.** 125·[Λ(x̄'β | d_g = 1) − Λ(x̄'β | d_g = 0)], with every other regressor, **including the other origin dummies**, at its sample mean (Stata `mfx`, discrete change), on the original origin coding.

**New T6 estimands: a corrected origin contrast at the retained mean covariate profile.**
- Let x̄ᴺ be the sample means of the non-origin regressors (intercept, female2, age23, the birth-decade dummies) over the estimation sample. Let z₀ = x̄ᴺ'β, p₀ = Λ(z₀) and p_g = Λ(z₀ + β_g), with all origin dummies 0 except d_g.
- **-pt rows:** Δ_g = 125·(p_g − p₀), the ABCC-point gap between group g and Cape-born slaves at the mean covariate profile.
- **-rel rows:** ln ρ_g = ln p_g − ln p₀. Since ABCC = 125 × share exact on ages 23–72 (S5 checklist), ρ_g is the ratio of the two **model-predicted** ABCC levels at the mean profile. It is not the ratio of the two groups' raw ABCC levels.
- Both use the corrected origin coding.
- **Fidelity.** The correction makes the contrast one between origin g and Cape-born slaves, which is what the table notes and the prose describe. It keeps the published `mfx` covariate profile: fractional means of female2, age23 and the decade dummies. The table's constant, by contrast, refers to a specific reference person (a male Cape-born slave aged 33–72 in the base decade). Δ_g is therefore not the gap for that reference person, and the card does not claim it is. The profile is retained so that only the two verified errors change; the published convention is sensitivity 1–2, and the AME is sensitivity 5.

**H2-all.** The conjunction over g ∈ {SE Asian, Indian, Mozambican} of Δ_g < 0.

**H3: an unconditional cohort difference.** D = 125·(ē_mid − ē_early) among Khoesan (`bco == "ko"`), cohort `bcoh` 2 against 1, on the original cohort coding (`bdec` from l.83–84), with no controls. It equals the OLS coefficient on 1[bcoh = 2] in a regression of 125·`exactage` on that dummy and a constant, in the 217 Khoesan of the two cohorts. This is the original estimand as reconstructed in S5-3. It does not hold gender, age or court year constant (sensitivity 13 does).

## 4. Primary analysis
**Data and sample.**
- File: `data.dta` (`dpath("P01_BF", "original", "Baten Fourie", "data.dta")`), the verified substitute for `na110702.dta` (S2).
- Sample as l.1656: 22 < age < 83, `bdec` ≥ 1650 and non-missing, `cyear` non-missing.
- No weights. No missing regressors (S5-14); any missing value would be dropped listwise and reported.

**Origin correction.**
- Start from `bco`. Set `origin ∈ {"Kust", "Cust", "Coehin"}` → `"in"` and `origin == "Westcoast"` → `"oth_bl"`. Westcoast (Angola) belongs to no T6 group, so it goes to the residual "slave, origin unknown". This is the recode of S5 scenario `fix_kust_westcoast_cochin`.

**Pre-verdict reproduction checks.** The script runs these before any corrected estimate is computed. The references are the archived full-precision values, not the four-decimal figures quoted in prose.

| Check | Computed | Reference (file, field) | Tolerance |
|---|---|---|---|
| G1 counts | N; origin counts; Khoesan cohorts | 1,802; 3 Kust, 1 Cust, 2 Westcoast, 1 Coehin; before recoding the first six have `bco == "za"` and Coehin `bco == "cn"`; after recoding za 140, in 76, cn 15, oth_bl 583; Khoesan 217 = 28 + 189 | exact |
| G2 T6, both corrections off | the published `mfx` contrast ×125 for eur, id, in, mz | `compare/s5_checks/s5_01_T6_decomp.csv`, scenario `orig_all`, `me125` (R replica, full double precision) | \|diff\| ≤ 1e-4 |
| G3 T6, Stata cross-check | as G2 | `repro_original/results_original.csv`, rows T6_r4, r5, r6, r8, `value` (Stata S2, full double precision) | \|diff\| ≤ 1e-4 |
| G4 T6, coding correction only | published convention, corrected coding | `compare/s5_checks/s5_02_origin_fix_T6.csv`, scenario `fix_kust_westcoast_cochin` | \|diff\| ≤ 1e-4 |
| G5 H3 | D | `compare/s5_checks/s5_03_T9_pvalues.csv`, T9_r5, `est` (−43.81613756613756) | \|diff\| ≤ 1e-8 |

- **Tolerances.** 1e-4 on the ×125 scale is 50 times finer than the 0.005 precision of a two-decimal value and allows for optimiser and cross-software differences in a converged logit. D is a closed-form difference of means, so 1e-8 allows for floating-point error only. Disclosure: when the tolerances were set, the archived files showed a largest Stata–R discrepancy of 4.4e-8 on the T6 values. The printed table values (3-significant-figure `mfx` output scaled by hand; S5-10) are not used as references.
- **Failure.** If G1 fails, the script stops, and every row is not-testable until the cause is logged in DEVIATIONS.md. If G2, G3 or G4 fails, every T6 row (and so H2-all) is not-testable until the cause is logged. If G5 fails, H3 is not-testable until the cause is logged. A logged and resolved cause is reported as a deviation; the tolerances are not changed.

**A. T6 rows (H1-pt/rel, H2-SEA/IND/MOZ-pt/rel).**
- Estimator: `glm(exactage ~ female2 + age23 + factor(bdec) + g, family = binomial)`, with g the corrected 8-level origin factor (base Cape-born) and `control = glm.control(epsilon = 1e-10, maxit = 100)`.
- Point estimates Δ_g and ln ρ_g as in §3. x̄ᴺ is computed once on the estimation sample and treated as fixed.
- Inference: the delta method with analytic gradients:
  - ∂Δ_g/∂β = 125·[λ(z₀ + β_g)(x̄ᴺ + e_g) − λ(z₀)·x̄ᴺ], where λ = Λ(1 − Λ);
  - ∂ln ρ_g/∂β = (1 − p_g)(x̄ᴺ + e_g) − (1 − p₀)·x̄ᴺ.
- Covariance: CR1 clustered by court volume, `sandwich::vcovCL(m, cluster = ~source, type = "HC1")`. Negative eigenvalues are clipped at 0, and the clipping is reported.
- Reference distribution: t with G − 1 df (G = number of `source` values in the sample; 43 at S5).
- **Separation detection.** Before inference the same model is fitted with `detectseparation` (`glm(..., family = binomial, method = "detect_separation")`, default linear-programming implementation; package version recorded in `modern/sessionInfo.txt`). It returns, for every coefficient, whether its maximum-likelihood estimate is finite.
  - All non-origin coefficients (intercept, female2, age23 and every birth-decade dummy) enter both p₀ and p_g through x̄ᴺ. If any of them is infinite, every T6 row is not-testable.
  - β_g enters only row g. If β_g is infinite, the two rows for group g are not-testable.
  - An infinite coefficient for another origin group h enters no row for g. It is reported and makes only h's rows not-testable (if h is a headline group).
  - Fitted probabilities outside (1e-8, 1 − 1e-8) are reported as a diagnostic and decide nothing.
- **Cluster assessment (reported; decides nothing).**
  - G; the minimum, median and maximum cluster sizes; the largest cluster's share of N.
  - Origin-by-volume support: for each headline group and for Cape-born slaves, the number of volumes with at least one member, the number with at least one exact and one heaped member, and the largest volume's share of the group.
  - Volume/year nesting: the number of distinct `cyear` values per `source` and of `source` values per `cyear`, and whether volumes nest within years, years within volumes, or the two cross.
  - Cluster influence: for each row, ψ_c = ∇'·bread·score_c, the cluster-c contribution to the linearised contrast, and the largest share max_c ψ_c² / Σ_c ψ_c² of the CR1 meat.
- **Failure rule (symmetric).** A row is not-testable if a pre-verdict check covering it fails, if the glm fails to converge, if separation makes it not-testable as above, if β_g or its SE is non-finite, if the delta-method SE is non-finite or 0, or if p₀ or p_g is numerically 0 (so ln ρ_g is undefined). There is no fallback covariance and no fallback estimator.

**B. H3 (T9_r5).**
- Estimator: `lm(I(125 * exactage) ~ mid)` on Khoesan with `bcoh ∈ {1, 2}` (n = 217: 28 early, 189 middle; checked in G1).
- Inference: a wild cluster restricted bootstrap by court volume, `fwildclusterboot::boottest` (version recorded in `modern/sessionInfo.txt`). Common arguments:
  - `param = "mid"`, `clustid = "source"`, `type = "webb"`, `impose_null = TRUE`, `p_val_type = "two-tailed"`;
  - `ssc = boot_ssc(adj = TRUE, fixef.K = "none", cluster.adj = TRUE)`;
  - before every call, seeds are reset with `dqrng::dqset.seed(20261011)` and `set.seed(20261011)`.
- **Step 1, the p-value (decides H3).** `boottest(..., B = 9999, conf_int = FALSE)`. **Monte Carlo rule:** if the unadjusted p lies within 2·√(p(1 − p)/B) of 0.05 or of any Holm critical value 0.05/j (j = 1…9), step 1 is rerun with B = 99,999 after resetting the seeds, and that p is used. The B of the p used is the final B. This p is retained before step 2 and is the only inference that decides H3.
- **Step 2, the interval (reported only).** A separate call with the final B, the seeds reset, `conf_int = TRUE`, `sign_level = 0.05/9`, inversion `tol = 1e-6`, `maxiter = 10`. The H3 verdict uses p-values alone (A4b has no credible-null rule), so this Bonferroni CI is reported only. The p-value from step 2 is not used.
- **Cluster assessment (reported; decides nothing).** G (the court volumes containing these 217 people) and cluster sizes; the number of volumes containing early-cohort Khoesan, and the largest volume's share of the 28; the number of volumes containing both cohorts and the number containing only one; volume/year nesting as in §4A; and the effective number of clusters G* of Carter, Schnepel and Steigerwald (2017) for the `mid` coefficient, at ρ = 0 and ρ = 1.
- **Failure rule (no fallback).** If step 1 errors or returns a non-finite p (in either the B = 9,999 run or a required B = 99,999 rerun), H3 is not-testable. If step 2 errors or fails to invert, the step-1 p stands, the verdict is unaffected, and the interval is reported as "not inverted". CR1 by `source` with t(G − 1) is reported as a diagnostic in every case (sensitivity 16) and never replaces the bootstrap.

**C. Multiplicity.** One family of nine tests: H1-pt, H1-rel, H2-SEA-pt, H2-SEA-rel, H2-IND-pt, H2-IND-rel, H2-MOZ-pt, H2-MOZ-rel and H3.
- Holm-adjusted p-values decide significance. m = 9 always. A not-testable row enters the Holm procedure with p = 1, so the adjustment for the other rows does not depend on which rows fail.
- Bonferroni CIs at 1 − 0.05/9 (99.44%) decide credible nulls (A4a) for the T6 rows. For T6 rows the CI is estimate ± t_{G−1, 1−0.05/18}·SE.
- If Holm p < 0.05 while the Bonferroni CI includes 0, significance follows Holm, and the discordance is flagged in `results.md` (as in P04, P10).
- H2-all uses the member -pt rows' inputs; it adds no test.

## 5. Admissible sensitivities (exhaustive; reported, never verdict-setting)
Each sensitivity varies one item from the primary unless stated. A sensitivity that fails to run is reported as failed, with its error, and affects no verdict.

**Common rules for resampling sensitivities (15, 20, 21).** Sensitivity 15 covers T6 rows only; 20 and 21 cover T6 rows and H3.
- **T6 rows.** The covariate profile x̄ᴺ is held fixed at its full-sample value in every resample and every deletion, as in the primary delta method. Only β is re-estimated. A draw or deletion is **undefined** for row g if the glm fails to converge; if `detectseparation` finds an infinite coefficient that enters row g (§4A); if group g or the Cape-born reference group has no members; if a birth-decade level present in the full sample is absent (its coefficient is needed for the fixed profile); or if the row's prediction is not estimable (p₀ or p_g non-finite or numerically 0, or the contrast non-finite).
- **H3.** The estimate is the unconditional difference D of §3, recomputed on the retained Khoesan. A deletion is **undefined** only if either cohort (`bcoh` 1 or 2) has no members left, or D is non-finite. The logit, separation, origin-group and birth-decade conditions do not apply to H3.
- Undefined draws are counted and reported per row. An interval or jackknife SE is computed on the defined draws only when the undefined share is at most 0.05/18 (0.28%), the one-sided Bonferroni tail mass. Above that share the undefined draws could all lie beyond one endpoint, and the interval is reported as "unavailable".

**A. Decomposition of the corrections (same estimand as the published row).**
1. The coding correction only, with the published `mfx` convention (= S5 `fix_kust_westcoast_cochin`).
2. The contrast correction only, on the original coding (= Codex F2).
3. Each coding fix alone, with the corrected contrast: Kust/Cust; Westcoast; Coehin.
4. Diagnostic: the published coding and convention with the primary inference, which isolates the effect of the inference upgrade.

**B. Alternative estimators and estimands (labelled; a different estimand where stated).**

5. AME: the Cape-born contrast averaged over the estimation sample (`margins`-style, all origin dummies switched together). A different estimand.
6. The contrast averaged over the members of group g only. A different estimand.
7. LPM: 125·`exactage` on the same regressors, CR1 by `source`, t(G − 1).
8. Firth bias-reduced logit: `glm(..., family = binomial, method = brglm2::brglmFit, type = "AS_mean")`, with the primary contrast and delta-method gradients. Covariance: `sandwich::vcovCL(m_firth, cluster = ~source, type = "HC1")`. This uses the ordinary logit score contributions evaluated at the Firth estimates and the fitted information as bread; the O(1) adjustment term is ignored, so the SE is approximate and labelled as such.
9. Gender coding `female` or `female3` in place of `female2`.
10. Birth decade from `cyear − age` instead of `cyear − (agegr + 5)` (S5-2/F1). For T6 this changes the time controls. For H3 it changes cohort membership (n = 191 at S5), which is a changed population (A4d).
12. -rel rows with the literal prose magnitudes: SE Asian 20%, Indian 29%, and the integers 51% and 21%.
13. H3 conditional estimands: within-Khoesan OLS with female2 and age23; logit MEM with the same controls; the T8 col 1 difference `ko_mid − ko_early`.

**C. Alternative inference (same point estimates).**

14. Conventional logit vcov (as published) and HC1, for T6 rows.
15. A cluster pairs bootstrap over `source`, B = 9,999, seed 20261011, percentile intervals at the Bonferroni level, for T6 rows, under the common rules above.
16. H3: the Welch t-test, the Newcombe (1998) hybrid score interval for the difference of proportions (×125), and CR1 by `source` with t(G − 1).
17. Clustering by court year (`cyear`) in place of court volume, for all rows (CR1 for T6, WCR for H3).
21. Cluster jackknife (CV3) by `source` (MacKinnon, Nielsen and Webb 2024), for all T6 rows and H3. Let θ̂₍c₎ be the estimate with volume c deleted and θ̄ their mean. V = ((G − 1)/G)·Σ_c (θ̂₍c₎ − θ̄)². Report the SE, the t(G − 1) p-value and the Bonferroni interval, under the common rules above. The deletions are those of sensitivity 20, computed once.

**D. Changed populations and influence (A4d; never verdict-setting).**

18. Accused not recorded as guessing their age (`knowsage == 1`; 467 in the sample): all T6 rows and H3. This is the age-awareness check, and it changes the population.
19. Records with a non-blank `origin` only (the matched subsample, F5).
20. Leave-one-court-volume-out: every primary estimate re-estimated without each `source` in turn, under the common rules above. Report the range and the number of deletions that would change the verdict category.

**E. Audit decomposition (not an admissible alternative; reported for the pair-B reconciliation only).**

11. The S3 rebuild codings (origin from the workbook's `origincountry`, rebuild `bdec`, rebuild `female`), jointly. The S5 audit found that the rebuild's origin coding is itself wrong for Sambaua (Sumbawa, 6 slaves, coded Madagascar) and Mandar/Mandhaar (Sulawesi, 2, coded India). This run reproduces those errors and so is not an alternative coding. It explains the pair-B gap and nothing more.

## 6. Fixed choices
- No weights. Listwise deletion (none expected). The sample definition of l.1656.
- `female2`, `age23` and the `bdec` decade dummies as coded. Cohorts for H3 as `bcoh` in the original file.
- The covariate profile for T6: the sample means of the non-origin regressors (the published `mfx` profile), fixed at full-sample values in all resampling.
- Multiplicity: one family of nine tests, m = 9, not-testable rows at p = 1 (§4C).
- **Boundary rules.**
  - p = 0.05 is not significant.
  - |e| = 0.5|b₀| meets the magnitude floor.
  - The credible-null band is open (A4a): a CI endpoint equal to ±0.5|b₀| is not inside it.
  - e = 0, or a CI endpoint exactly at 0, counts as "sign not established" and "CI includes 0".
  - Verdict comparisons use unrounded values. Reports use 2 dp for points and 3 dp for log ratios.
- Seeds: 20261011. Scripts: `modern/01_t6.R`, `02_t9.R`, `03_sensitivities.R`, `04_verdicts.R`. Outputs go to `modern/output/` and are regenerated identically from a clean Rscript session.

## 7. Margins (A3, A4 and A8 defaults; none chosen by the card author)
| Row | b₀ | Confirm: same sign, Holm p < 0.05, and | Credible null (A4a): Bonferroni CI within | Plausibility flag (A8; no verdict) |
|---|---|---|---|---|
| H1-pt | +51.38 | Δ ≥ 25.69 | (−25.69, 25.69) | Δ > 77.07 |
| H1-rel | +0.4146 | ln ρ ≥ 0.2073 (ρ ≥ 1.230) | (−0.2073, 0.2073) | ln ρ > 0.6219 |
| H2-SEA-pt | −28.63 | Δ ≤ −14.315 | (−14.315, 14.315) | Δ < −42.945 |
| H2-SEA-rel | −0.33729 | ln ρ ≤ −0.16865 (ρ ≤ 0.845) | (−0.16865, 0.16865) | ln ρ < −0.5059 |
| H2-IND-pt | −20.25 | Δ ≤ −10.125 | (−10.125, 10.125) | Δ < −30.375 |
| H2-IND-rel | −0.2263 | ln ρ ≤ −0.1131 (ρ ≤ 0.893) | (−0.1131, 0.1131) | ln ρ < −0.3394 |
| H2-MOZ-pt | −21.38 | Δ ≤ −10.69 | (−10.69, 10.69) | Δ < −32.07 |
| H2-MOZ-rel | −0.2405 | ln ρ ≤ −0.1203 (ρ ≤ 0.887) | (−0.1203, 0.1203) | ln ρ < −0.3608 |
| H2-all | n/a | every member -pt row negative with Holm p < 0.05 (A8 comparative "<"; no magnitude threshold) | none: A8 sets no credible null for a strict comparative | n/a |
| H3 | −43.9 | Holm p < 0.05 (sign and magnitude fixed by A4b: D = −43.82, \|D\| ≥ 21.95) | not applicable (A4b) | n/a |

- No ceilings. b₀ is the printed T6/T9 value. The -rel values use ln(1 + v/100), and the bounds were computed to 4–5 dp before any modern estimate. The verdict script recomputes them from b₀ unrounded.
- A3 allows the magnitude "in words or in the headline number". The card uses the headline number, the printed table value, because the words transpose two rows (§1).
- The plausibility flag is 1.5 × b₀ on the row's scale (A8). It is reported next to the verdict and never changes it.

**Disclosure.** S2, S5 and the Codex audit produced the following numbers before v1 was written. All of them bear on the verdicts.
- **Original code (S2):** 51.38, −28.63, −20.26, −21.34; conventional p 0.0000, 0.0000, 0.0103, 0.0017. HC1 delta-method p for Indian 0.0098, Mozambican 0.0016. Clustered by `source` (43 volumes): Indian p 0.0140, Mozambican 0.0002, European and SE Asian p 0.0000. N = 1,802.
- **Coding correction, published convention (S5-1):**
  - Kust/Cust only: 49.96 / −29.72 / −23.04 / −22.34.
  - Plus Westcoast: 50.29 / −29.49 / −22.76 / −22.11.
  - Plus Coehin: 50.32 / −29.44 / −22.94 / −22.11.
- **Contrast correction, original coding (Codex F2):** European +50.61, SE Asian −26.41, Mozambican −20.16; conventional SEs 5.99, 6.81 and 7.21. The Indian value was not reported.
- **Estimators (original coding):**
  - AME: 49.25 / −26.22 / −19.02 / −19.91.
  - LPM HC1: 49.49 / −25.26 / −18.27 / −19.01, all p ≤ 0.021.
- **Codings:**
  - Birth year from `cyear − age`: 52.10 / −28.57 / −19.53 / −22.05.
  - Gender `female`: 51.13 / −28.61 / −20.48 / −21.09.
  - Rebuild origin: 50.36 / −27.99 / −23.57 / −21.86.
  - Rebuild all codings: 51.15 / −27.53 / −22.63 / −22.16.
  - Across all 13 S5 scenarios every T6 headline keeps p < 0.03.
- **H3:**
  - Raw difference −43.82 (Welch p 0.0014).
  - Controlled OLS −40.99; logit MEM −40.45; T8 difference −43.13.
  - Rebuild cohorts −46.0 to −47.0 (n = 191).
  - Early-cohort level 65.5 ± 11.9 (n = 28).
  - While drafting v1 the author counted 34 court volumes among the 217 Khoesan. No estimate was computed.
- **Levels:** the published Figure 4 shows Cape-born ABCC of about 37 (middle) and 45 (late). Combined with the gaps above, this implies that the -rel ratios will lie far from the stated percentages (the European ratio near 2 rather than 1.5), so plausibility flags are likely on the -rel rows. The rows are kept because the margins are A3 defaults and were not set from these numbers.
- **v2.** No new estimate was computed for v2. The only numbers consulted were the archived full-precision reference values for the pre-verdict checks (§4) and the 4.4e-8 Stata–R discrepancy disclosed there.
- **v3.** No new estimate was computed and no result file was opened for v3.

**Not yet computed:** the jointly corrected T6 estimates (coding plus contrast), any t(G − 1) CR1 p on the corrected model, any -rel ratio and its interval, the separation diagnostics, the cluster-support and influence diagnostics, G*, the H3 wild cluster bootstrap, and sensitivities 3–8 and 14–21 as specified here. The choice of court volume as the cluster was made after the S5 clustered p-values on the original coding had been seen (§10). This disclosure does not prove that nothing was tuned.

## 8. Verdict rules (primary analysis only; the first rule that applies decides; exhaustive)
"Strengthened" is not used. The published rows have no interval to compare with, and a smaller p-value alone does not qualify (S6). Sensitivities never enter these tables.

**-pt and -rel rows** (H1-pt, H1-rel, H2-SEA/IND/MOZ-pt, H2-SEA/IND/MOZ-rel). Estimate e on the row's scale; p = Holm-adjusted; CI = Bonferroni (§4C); thresholds from §7.

| # | Condition | Verdict |
|---|---|---|
| 0 | the §4A failure rule applies (pre-verdict check, convergence, separation, non-finite or zero SE, undefined log ratio) | not-testable |
| 1 | e has the opposite sign to b₀ and p < 0.05 | overturned (reversed) |
| 2 | CI lies entirely within (−0.5\|b₀\|, +0.5\|b₀\|) | overturned (credible null) |
| 3 | same sign as b₀, p < 0.05, \|e\| ≥ 0.5\|b₀\| | confirmed |
| 4 | same sign as b₀, p < 0.05, \|e\| < 0.5\|b₀\| | qualified (magnitude below half the stated value) |
| 5 | p ≥ 0.05, e has the same sign as b₀ | weakened |
| 6 | p ≥ 0.05, e = 0 or opposite sign | weakened (direction lost) |

The table is exhaustive under first-match precedence, and each row receives exactly one verdict: the first rule that holds. The conditions are not mutually exclusive. Rule 2 can hold together with rule 1, 4, 5 or 6; precedence then gives rule 1 (a significant reversal) over rule 2, and rule 2 over rules 4–6, so a CI inside the null band overturns the row whatever its p. Rule 2 cannot hold together with rule 3, because |e| ≥ 0.5|b₀| puts e outside the open band. Exhaustiveness once rule 0 does not apply: with p < 0.05, e ≠ 0, so either the sign is opposite (rule 1) or the same (rules 3 and 4); with p ≥ 0.05, rule 5 or 6 applies. The ladder is symmetric: confirmation needs at least half the stated magnitude, and a credible null needs the whole interval below half.

**H2-all** (strict comparative "<", conjunction over the three -pt members; no magnitude threshold, A8). Each member's inputs are its Δ_g and Holm p from the -pt row.

| # | Condition | Verdict |
|---|---|---|
| 1 | any testable member has Δ_g > 0 with Holm p < 0.05 | overturned (reversed for that group) |
| 2 | otherwise, any member -pt row is not-testable | not-testable |
| 3 | every member has Δ_g < 0 with Holm p < 0.05 | confirmed |
| 4 | otherwise (all members testable; none significantly reversed; at least one with Holm p ≥ 0.05) | weakened |

- Rule 1 comes first because one significant reversal refutes a universal claim whatever the other members show; rule 2 then applies because confirmation needs all three members.
- No credible-null rule applies. The claim states a sign, not a size, and a significant negative contrast confirms "lower" however small it is; the member -pt rows judge the size. A member whose -pt row is qualified or overturned as a credible null therefore does not by itself prevent H2-all from being confirmed. The member verdicts are reported alongside.
- The rules are exhaustive: if rule 1 fails and all members are testable, either all are significantly negative (rule 3) or at least one has Holm p ≥ 0.05 (rule 4).

**H3** (inference-only, A4b; D fixed at the reconstructed published estimate).

| # | Condition | Verdict |
|---|---|---|
| 0 | G1 or G5 fails (§4), or the bootstrap p is not available (§4B failure rule) | not-testable |
| 1 | Holm p < 0.05 | confirmed |
| 2 | Holm p ≥ 0.05, unadjusted p < 0.05 | qualified (inference-fragile) |
| 3 | unadjusted p ≥ 0.05 | weakened |

"Overturned" cannot be reached for H3 (A4b). Since D is fixed at the published value, the sign and the magnitude floor hold by construction, and only significance is in question. A CI that is "not inverted" does not trigger rule 0.

**Summaries and coverage.**
- H1, H2 and H3 are reported separately and not aggregated. Within H1 and H2, the -pt and -rel rows are reported side by side, with no summary across scales.
- Coverage: 10 verdict rows; the not-testable statements in §1 are listed as such.
- Every sensitivity in §5 is reported next to the verdict it accompanies, labelled "reported; does not set the verdict".

## 9. Codex review notes and responses
**Codex v1 review** (`reviews/P01_BF_codex_S6card.md`): approve-with-changes, 8 required changes, all addressed in v2.
1. **H2-all repaired (§7, §8).** The magnitude-based credible-null rule is deleted. H2-all is now judged on sign and Holm significance alone, as A8 prescribes for a strict comparative. The v1 assertion that a significant CI cannot lie within a member's null band is withdrawn; v2 states that such a member does not block confirmation. The table is reordered so that a significant reversal overturns before a not-testable member is considered.
2. **Estimand fidelity (§1, §3).** T6 is described as a corrected origin contrast at the retained mean covariate profile, and §3 states that it is not the gap for the table's reference person (male, aged 33–72, base decade). The -rel rows are ratios of model-predicted ABCC at that profile. H3 is described as an unconditional cohort difference throughout. A new §1 paragraph places numeracy, population-wide and causal readings outside what the estimates establish.
3. **Reproduction gates (§4).** The four-decimal targets at 1e-6 are replaced by a table of checks against archived full-precision files (`s5_01_T6_decomp.csv`, `results_original.csv`, `s5_02_origin_fix_T6.csv`, `s5_03_T9_pvalues.csv`), with tolerances justified by the precision of each reference (1e-4 for the logit contrasts, 1e-8 for the closed-form D). The printed 3-significant-figure values are not used. The consulted discrepancy (4.4e-8) is disclosed.
4. **Cluster assessment (§4A, §4B, §5).** Added, as reported diagnostics that decide nothing: origin-by-volume support, Khoesan cohort-by-volume support (volumes with early Khoesan, with both cohorts, the largest volume's share of the 28), volume/year nesting, per-row cluster influence on the CR1 meat, and G* for H3. A report-only logit cluster jackknife (CV3; MacKinnon, Nielsen and Webb 2024) is sensitivity 21. None of these became a gate, because any threshold would now be chosen after S5.
5. **Separation (§2d, §4A).** The fitted-probability heuristic no longer decides anything. `detectseparation` checks every coefficient; a row is not-testable if any coefficient entering its prediction (all non-origin coefficients, and β_g) is infinite. The same rule defines undefined resamples.
6. **H3 inference fixed (§4B, §8).** The CR1 fallback is removed. The bootstrap p is the only deciding inference; a failed CI inversion is reported and does not affect the verdict; a failed bootstrap p makes H3 not-testable. CR1 is a diagnostic only (sensitivity 16). Not-testable rows enter Holm at p = 1 with m = 9 (§4C).
7. **Sensitivity 11 reclassified (§5E).** It is now an audit decomposition, reported for the pair-B reconciliation only, because it reproduces the rebuild's Sambaua and Mandar errors.
8. **Bootstrap specifications (§5).** Common rules for sensitivities 15, 20 and 21: x̄ᴺ fixed at the full-sample value; undefined draws defined (non-convergence, relevant separation, missing group or decade level); intervals computed on defined draws only if the undefined share is at most 0.28% (the one-sided Bonferroni tail), otherwise "unavailable". The Firth covariance is specified (sensitivity 8), with its approximation stated.

**Codex compliance check of v2** (`reviews/P01_BF_codex_S6card_v2.md`): freeze-after-minor-edits; four edits, all made in v3.
1. **§4B.** The H3 p-value comes from a call with `conf_int = FALSE` and is retained; the interval is inverted in a separate call with the same final B and reset seeds. Only failure of the p-value call makes H3 not-testable.
2. **§5 common rules.** T6 and H3 are separated. T6 adds an absent Cape-born reference group and a non-estimable prediction as undefined; H3 is undefined only if a cohort is empty or D is non-finite, with no logit, origin or decade conditions.
3. **§8.** "Mutually exclusive" is replaced by "exhaustive under first-match precedence", and the overlaps of rule 2 are stated.
4. **Opening disclosure.** "No results-informed gate" is qualified for the reproduction tolerances.

Optional suggestions (v1 review):
1. AME, cohort recoding and age-awareness restrictions remain labelled sensitivities (5, 10, 18).
2. Adopted: §1 states that "confirmed" means meeting the protocol minimum, not agreement with the quoted percentage.
3. Followed: this is v2 under A9; v3 follows the compliance check, and unresolved issues are listed in §10 without results-informed gates.

## 10. Known limitations at freeze
1. **Origin matching cannot be audited** (F5). `origin2.do` is missing, so false, duplicate or lost matches to the Robben Island lists cannot be checked. Every T6 verdict is conditional on the authors' matching. Sensitivity 19 changes the population and does not vote.
2. **Numeracy against age awareness.** Imported adults may not have known their birth year, so the T6 gaps may partly measure age awareness. Sensitivity 18 (`knowsage == 1`) is report-only because it changes the population. The card cannot separate the two constructs, and its verdicts concern age heaping (§1).
3. **Selection into the court sample** is not addressed. T8 cols 2–3 have no surviving code.
4. **The cohort convention is retained** (S5-2/F1, disputed). The H3 verdict is conditional on the published `bdec` rule. The alternative rule, already seen, gives a larger fall (−46.0 to −47.0) on 191 people.
5. **H3 rests on 28 early-cohort Khoesan** and is unconditional. The bootstrap uses one-way clustering by volume (34 volumes, unbalanced), which misses shocks common to a court year (sensitivity 17 only). Cohort-by-volume support and G* are reported but cannot change the verdict.
6. **The -rel rows apply the A4c principle by analogy.** A4c covers odds ratios stated as probabilities; here ABCC points are stated as percentages. The literal relative reading is a card reading, and S5 had already judged the wording a misstatement. b₀ uses the table values, not the transposed prose.
7. **The F2 correction keeps the published at-means profile.** It includes fractional means of the birth-decade dummies and female2, so Δ_g describes no actual person and differs from the table's reference case. The AME (sensitivity 5) is a different estimand and does not vote.
8. **x̄ᴺ is treated as fixed** in the delta method and in every resample. Sampling variation in the profile is ignored; with N = 1,802 this is likely small, but it is not quantified.
9. **Westcoast → "unknown"** is a card choice, because Angola belongs to no T6 group. Sensitivity 3 isolates it.
10. **CR1 with 43 unbalanced clusters** may over-reject for a nonlinear model. No wild bootstrap is specified for the logit contrast. The pairs bootstrap (15) and the CV3 jackknife (21) are report-only, and the cluster diagnostics carry no thresholds, because any threshold set now would follow S5.
11. **Separation makes rows not-testable with no fallback.** If a sparse birth-decade or origin cell is separated, the affected T6 rows have no verdict; the Firth logit (sensitivity 8) is reported but does not substitute. Whether separation occurs was not checked before freeze.
12. **Reproduction tolerances** were set with knowledge of the archived Stata–R discrepancy (4.4e-8). They are justified by reference precision, not by that number, and they cannot affect any point estimate or verdict except through not-testable.
13. **The cluster unit was chosen after S5 clustered p-values had been seen** on the original coding (Indian p 0.014). It rests on how ages were recorded (clerk and volume), not on those values. An independent adjudicator may judge otherwise.
14. **H3 bootstrap seed and B.** The deciding p comes from one seeded draw (B = 9,999, or 99,999 under the Monte Carlo rule). Monte Carlo error near a Holm cutoff is reduced, not removed.
15. **Not testable:** the causal explanations of the Cape-born advantage and the link to later income inequality.
