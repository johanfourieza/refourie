# Method card: P18_FvFS: Huguenot wine-makers

Status: v2 (2026-10-11), revised after Codex review (reviews/P18_FvFS_codex_S6card.md). FROZEN at commit: see git log "FREEZE S6 card P18".

## 1. Headline claims addressed
The family is the frozen A1 union headline set: T3_r2_c4, T4_r1_c7, T4_r1_c10.
- **T3_r2_c4:** wine-region Huguenot (WH) vs non-Huguenots, full sample, full controls: 0.751*** (N = 9,078). Authors: "75 per cent".
- **T4_r1_c7:** WH vs non-wine-region Huguenots, Huguenot sample: 0.721*** (N = 2,230). Authors: "72 per cent".
- **T4_r1_c10:** WH among the born-abroad, no controls: 1.992*** (N = 368). Authors: "about 200 per cent". claims_spec calls this a supporting result. It is in the family because A1 made it a headline.

Stated interpretation: wine-region Huguenots produced substantially more wine per household member than comparable settlers, which the authors attribute to transmitted wine-making skill.

## 2. Defects addressed (S5, both auditors)
1. **The outcome is ill-defined at zero.** 6,800 of 9,078 values are set to 0.001 before logging, so the coefficient depends on that constant. Chen and Roth (2024, *QJE*) and Santos Silva and Tenreyro (2006, *REStat*) recommend a proportional mean model (PPML).
2. **Inference ignores dependence** (HC1 only).
3. **Undisclosed weights and mixed units.**
4. **Possible bad controls.**

## 3. Estimands
- **Original:** the WH difference in E[ln(max(wine per member, 0.001)) | X].
- **New:** the ratio of conditional arithmetic means of wine per member, exp(β), under an exponential conditional-mean model, given the same observed inputs and fixed effects. This is a **change of outcome scale**, from expected transformed output to a mean ratio. It is a descriptive conditional association, like the original. Neither identifies transmitted skill; the causal reading is judged separately (S5 X5).

The verdict asks whether the claim "WH produced substantially more wine per member, given observed inputs" survives on a scale-invariant outcome.

## 4. Primary analysis
- **Software and data:** fixest (version recorded in `modern/sessionInfo.txt`) on `P18_FvFS/repro_original/extracted/.../final_excl_1.dta`.
- **Samples and regressors:** identical to `repro_original/published_spec_attempt.do` for specs 4 (T3), 7 (T4) and 10 (T4). Same filters, N, regressor list and units.
- **Outcome:** wine per household member in levels, zeros included. Wine is the variable that the published log outcome is built from, before the 0.001 replacement; this is verified by showing that ln(max(·, 0.001)) reproduces the published dependent variable exactly.
- **Weights:** household size, as published. This keeps the published weighting of observations. It does not by itself make the estimand per person.
- **Estimator:** `fepois`, with year and district fixed effects as published.
- **Inference:**
  - CR1 cluster-robust SEs by surname, using the normalised surname field built in `P18_FvFS/compare/s5_checks/` (lower-case, trimmed, diacritics stripped). Rows with a missing surname form singleton clusters.
  - For each sample, report: the number of clusters; the number of clusters containing WH observations; the WH cluster share of the largest cluster.
  - **Small-cluster rule:** if the number of WH clusters is < 30 in a sample, the primary inference for that claim is the leave-one-cluster-out jackknife (CV3) SE, computed by re-estimation.
- **Separation:** observations removed by fixest separation or fixed-effect rules are reported, with the resulting N. If β cannot be estimated, the verdict is `not-testable`.
- **Multiplicity:** Holm adjustment across the three claims (p-values). Intervals are Bonferroni at the 1 − 0.05/3 level.
- **Seed:** 20261011.

## 5. Admissible sensitivities (exhaustive; none changes the verdict)
1. Unweighted PPML.
2. Household-total wine as the outcome, with offset ln(hhsize) and no weights (the exposure model). Same regressors.
3. All inputs per household, then all inputs per member (consistent units), each with and without weights.
4. Extensive margin: LPM of 1[wine > 0], with surname CR1 and a wild cluster bootstrap (Webb, 9,999 draws). Descriptive.
5. Intensive margin: OLS of ln(wine per member) among producers. A selected sample, so descriptive only.
6. Dropping household-choice controls (vines, married-to-Huguenot dummies, slaves). This changes the conditioning set and is labelled as such.
7. Dropping records that are identical on all variables (exact duplicates).
8. Clustering: two-way by surname and district × decade, and one-way by district × decade (with the few-cluster caveat stated).

## 6. Fixed choices
- Listwise deletion, as in the original.
- No trimming.
- Family = the three claims in §1.

## 7. Thresholds (Amendment A3, magnitude retention)
θ = exp(β) − 1. The magnitude threshold M is half the authors' stated magnitude:
- T3 c4: M = 0.375
- T4 c7: M = 0.36
- T4 c10: M = 1.00

A3 is a magnitude-retention rule, not a formal equivalence test.

**Disclosure.** Before this card was written, S5 had already run PPML variants, including surname-clustered PPML for T4 c7 (0.316 → +37%), and several alternative outcome constructions. A3 limits discretion by applying one rule to all papers. It does not prove the absence of tuning, and this is recorded as a freeze exception for the pilot.

## 8. Verdict table
Rules are checked in order; the first that applies decides. CI = Bonferroni-adjusted CI on θ; p = Holm-adjusted.

| # | Condition | Verdict |
|---|---|---|
| 0 | β not estimable (non-convergence or separation removes WH) | not-testable |
| 1 | θ < 0 and p < 0.05 | overturned |
| 2 | CI upper bound < 0.10 (rules out effects ≥ 10%; credible null) | overturned |
| 3 | p < 0.05, θ > 0, and θ ≥ M | confirmed |
| 4 | p < 0.05, θ > 0, and θ < M | qualified |
| 5 | p ≥ 0.05 and θ > 0 | weakened |
| 6 | p ≥ 0.05 and θ ≤ 0 (sign lost, not significant) | weakened |

`strengthened` does not apply: the primary changes the outcome scale but is not a stronger identification design.

## 9. Codex review notes and responses
Codex v1 review: approve-with-changes, 10 required changes. Responses:
1. Disclosure corrected (§7).
2. Estimand narrowed (§3).
3. Exhaustive table with a credible-null category (§8).
4. A3 described as magnitude retention (§7).
5. Family = three claims, Holm and Bonferroni (§4).
6. Cluster counts and the small-cluster rule (§4).
7. `summclust` dropped; jackknife instead (§4).
8. Executable specification: variables, normalisation, separation rule (§4).
9. Weights explained; exposure model added (§5.2).
10. Sensitivities repaired (§5).
