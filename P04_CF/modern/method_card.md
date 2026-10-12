# Method card: P04_CF, occupational mobility during the industrial take-off

Status: v2 (2026-10-11), revised after the Codex review (reviews/P04_CF_codex_S6card.md). FROZEN with the commit message "FREEZE S6 card P04".

## 1. Claims family (frozen A1 union) and interpretations
- **I1, relative mobility** (T10_r1_c3). The authors read d(P,Q) = 3.70* plus d(Q,I) < d(P,I) as "greater relative mobility after 1868".
- **I2, absolute mobility, Gold cohort** (T11_r4_c3). Model 3 OR is 1.303***. Two rows: I2-OR, the odds claim, and I2-RR, the authors' wording "more likely" (A4c).
- **I3, migrants** (T11_r5_c1). Model 1 OR is 1.497***. Two rows: I3-OR and I3-RR.
- **I4, farmer persistence** (T9_r17_c2). The marginal-adjusted farmer→farmer share is stable: Gold 77.7 against Slavery 78.1.

The scope is limited by construction. "Last occupation" is the do-file's dictionary-order proxy, not chronological attainment (S5 N3). The sample is the retained SAF genealogy sample. The verdicts concern the published endpoints (Gold vs Slavery, pre- vs post-1868). They say nothing about the precise onset year.

## 2. Defects addressed
S5 found:
- (a) occupation miscoding: grazier, century;
- (b) the class-size share entered as a label code;
- (c) no clustering by family;
- (d) odds ratios labelled as relative risks;
- (e) Altham statistics without uncertainty, read for direction;
- (g) 159 duplicate pairs.

Sources: Long and Ferrie (2013), Altham and Ferrie (2007), Cameron and Miller (2015) on cluster dependence, Zou (2004) on modified Poisson.

## 3. Estimands
- **I1.** The primary is Δ = d(P,I) − d(Q,I) (Δ > 0 means Q is closer to independence), which addresses the directional reading directly. d(P,Q) is reported as the association-difference statistic but does not decide the verdict.
- **I2/I3-OR.** The ORs as in the published models: Model 3 for Gold, Model 1 for migrants, with the share decoded.
- **I2/I3-RR.** Risk ratios from modified Poisson with the same regressors. This is a different conditional-mean model and is labelled as such.
- **I4.** D = the marginal-adjusted farmer→farmer share in Gold minus that in Slavery. The Gold and Slavery targets are recomputed jointly from the analysed sample.

## 4. Primary pipeline (one pipeline; inference rule per claim given here)
1. **Data.** The 2016 analysis file linked to the 2017 file by the frozen rule in `P04_CF/compare/s5_checks/s5_link.R`. Pairs that fail to link keep their own father-id singleton cluster.
2. **Coding.** The authors' Long–Ferrie map, with grazier → Farmer and century removed from occupation lists. The class variables are then rebuilt with the do-file's "last non-missing" rule.
3. **Shares.** The class-size share (`origin_occ_group_share` logic) is rebuilt after recoding, on the analysed sample. It is decoded to the numeric share and **recomputed within each bootstrap draw**.
4. **Sample.** Sons born 1800–1909 (the published definition: the 106 sons born in 1910 are excluded in the primary, per the paper's text) with codable son and father classes. Covariates with missing values are dropped listwise.
5. **Inference.**
   - **I1 and I4:** family-cluster bootstrap. Resample fathers with replacement, B = 4,999, seed 20261011. Use **studentised percentile-t** intervals for Δ and D, with the SE from a nested bootstrap of 199 draws. The p-value is two-sided and inverts the percentile-t interval. Altham statistics with zero cells take 0.5 added to every cell of that table in that draw (Altham–Ferrie convention). Deming–Stephan raking uses tolerance 1e-10 and at most 1,000 iterations; a draw that fails to converge is discarded and reported.
   - **I2 and I3, OR and RR:** CR1 SEs clustered by father, with the cluster counts and sizes reported after exclusions.
   - **Multiplicity.** Holm across six tests: I1, I2-OR, I2-RR, I3-OR, I3-RR and I4. For I4 the test is the equivalence (TOST) test against ±5 pp, using two one-sided percentile-t tests at the Holm-adjusted level. CIs are Bonferroni at the 1 − 0.05/6 level.

## 5. Admissible sensitivities (reported; they do not set the verdict, A4d)
1. The grazier correction only; the century correction only.
2. Corrections plus dropping one record of each duplicate pair (exact-match key as in `s5_duplicates.R`).
3. An order-free class: the highest class in the hierarchy Farmer < Unskilled < Semi/skilled < White collar. Highest = the max on this ordering, which is the Long–Ferrie ordinal order excluding farmers, with farmers placed lowest. This changes the definition and is labelled so.
4. Including the 1910 births.
5. Migrant Models 2 and 3 (I3 in alternative specifications).
6. **Diagnostic only:** the original coding with the primary inference, to isolate the effect of the inference upgrade.

## 6. Fixed choices
- Four Long–Ferrie classes.
- Periods as published (with the 1910 rule above).
- No weights.

## 7. Thresholds (A3 and A4)
| Claim | Published b₀ | Confirm threshold | Credible null (A4a) |
|---|---|---|---|
| I1 | Δ₀ = 0.42 | Δ ≥ 0.21 | CI within (−0.21, 0.21) |
| I2-OR | ln 1.303 = 0.265 | ln OR ≥ 0.132 (OR ≥ 1.142) | CI of ln OR within (−0.132, 0.132) |
| I3-OR | ln 1.497 = 0.403 | ln OR ≥ 0.202 (OR ≥ 1.223) | CI within (−0.202, 0.202) |

- **RR rows.** The authors' wording ("about 30% more likely") gives b₀ = ln 1.30 for I2-RR. For I3-RR, b₀ = ln 1.497. The same 50% rule applies on the log scale.
- **I4.** A wording-based equivalence band. "Stable" is read as within ±5 pp. That band is about a 6% relative change on a share near 78%, which is a conventional "no material change" band for shares, and it is declared in advance. Rounding uses 3 dp on the estimate scale.

**Disclosure.** S5 already ran the corrected coding with the original inference: d(P,Q) 9.29 with the direction reversed; Gold Model 3 between 1.04 and 1.49 depending on the share. The corrections rest on the authors' own HISCLASS file and on "century" not being an occupation. The thresholds follow A3/A4. This disclosure does not prove that nothing was tuned.

## 8. Verdict tables (checked in order; the first rule that applies decides; exhaustive)
**I1, I2-OR, I2-RR, I3-OR, I3-RR** (estimate e on the stated scale; p = Holm-adjusted; CI = Bonferroni):

| # | Condition | Verdict |
|---|---|---|
| 0 | estimation fails | not-testable |
| 1 | e has the opposite sign to b₀ and p < 0.05 | overturned (reversed) |
| 2 | CI within the credible-null band | overturned (credible null) |
| 3 | same sign, p < 0.05, \|e\| ≥ threshold | confirmed |
| 4 | same sign, p < 0.05, \|e\| < threshold | qualified |
| 5 | p ≥ 0.05, same sign | weakened |
| 6 | p ≥ 0.05, opposite sign | weakened (direction lost) |

**I4** (D, with the Bonferroni CI and the Holm-adjusted TOST):

| # | Condition | Verdict |
|---|---|---|
| 0 | estimation fails | not-testable |
| 1 | TOST rejects (CI within ±5 pp) | confirmed |
| 2 | CI excludes 0 and lies entirely outside ±5 pp on one side | overturned |
| 3 | CI excludes 0, not entirely outside ±5 pp | qualified (change detected, magnitude unclear) |
| 4 | CI includes 0, TOST does not reject | weakened (inconclusive) |

## 9. Codex review notes and responses
Codex v1 review: approve-with-changes, 8 required changes. Responses:
1. One pipeline, with the inference rule per claim (§4.5).
2. Estimands qualified: Δ primary, last-occupation proxy (§1, §3).
3. OR and RR rows separated (§1, §7, A4c).
4. Studentised bootstrap, two-sided p, Holm over six tests (§4.5).
5. Margins: A3/A4 symmetric rule; I4 band justified; disclosure (§7).
6. Exhaustive tables, TOST for I4 (§8).
7. Construction, numerical and failed-draw rules (§4).
8. Clusters reported after exclusions; dedup key; hierarchy defined; diagnostic labelled; migrant Models 2/3 added (§5).
