# Method card: P12_FJ, health inequality and the 1918 influenza in South Africa

Status: v3 (2026-10-12), FROZEN under A9.
- History: v1 → Codex review (reviews/P12_FJ_codex_S6card.md; approve-with-changes, 9 required changes) → v2 → Codex compliance check (reviews/P12_FJ_codex_S6card_v2.md; revise-again, 5 issues) → v3 (this card; A9 cap, frozen).
- Margins follow AMENDMENTS.md A3, A4, A8 and A8a, defaults only. The card author chose no band, margin or ceiling. The only author-set quantities are computational failure rules (§4D), which can only make a row not-testable, never confirm or overturn it.
- To be FROZEN with the commit message "FREEZE S6 card P12". Issues not resolved at v3 are in §10.

Rights class: personal (death certificates 1915–1920, FamilySearch-derived; also restricted-licence). Every script runs locally and reads row-level data from D: only (`dpath("P12_FJ", ...)`). Codex sees this card, the code and aggregate output only.

## 0. Type of analysis and baseline
**No original code survives (S1, S2).** The reproduction baseline is the S3 rebuild (`repro_r/`, independence FULL): 11 of the 15 districts (10 towns + Sea Point), N = 26,823 in specs 2–3. Fraserburg, Riversdale, Stellenbosch and Stockenstrom were not recovered. The published 15-district estimates (N = 32,555) cannot be re-estimated, so **every verdict below is a verdict on the 11-district subsample**, the only population the surviving data permit. This is the baseline, not a sensitivity, so A4d does not bar it from deciding verdicts; the limitation is carried to §10.

**Scope statement (carried into every verdict output).** Each verdict row in `results.md` and the verdict CSV carries the field `scope` = "11 of 15 districts; outcome = a doctor named on the death certificate, among decedents; not the 15-district estimand, not population access to healthcare, not mortality". No verdict can overturn or confirm the unavailable 15-district estimates.

**Classification, per verdict row.**
- **H1 race rows and H3-int (logit coefficients):** (i) **correction** of two verified departures of the rebuild from the paper's stated method (occupation coding, F3; death-in-family timing, F4), plus (ii) an **inference upgrade** from 11-cluster CR1 to the CV3 cluster jackknife with t(G − 1) reference (S5-5, F8). The point estimates change, so A3/A4 apply in full, including the symmetric credible null. A4b does not apply.
- **H3-rev (urban reversal):** (i) **correction** of the paper's interpretation arithmetic (F1; claims_spec (e)5). The claim is tested on the linear combination β_Street + β_P×Street, not on the interaction alone, with the same inference.
- **H2-P rows (probability-scale widening, A4c):** the authors state the race result as a probability ("the probability of access to healthcare dropped for all black and coloured people more than for white people"). Under A4c it is a separate row from the logit coefficient, built on a standardised average probability cross-difference (§3), a descriptive contrast among complete-case decedents, not a treatment effect (Puhani 2012). **The H2-P verdict is not-testable by rule (§4C): no valid inference exists for this functional with 11 clusters. The point estimates and the jackknife spread are reported descriptively.** H1 carries the inferential test of racial widening.
- **P rows (predicted probabilities TXT_p9_a–f):** (i) **correction** of the model used: the text numbers come from spec 2 (S5-3, F6), while S3 used spec 3. Point values from the corrected spec 2; no inference.

**A4c.** The headline coefficients are logit coefficients (log-odds), judged on the log-odds scale. The probability statements are separate rows (H2-P, P). No headline row is an odds ratio printed as such.

**Runtime.** Each logit (`fixest::feglm`, binomial, ≈ 27,000 rows, ≈ 50 parameters plus 10 district dummies) takes seconds. The primary needs 3 full-sample fits and 3 × 11 leave-one-district-out fits plus closed-form predictions; it runs in a few minutes. The heaviest sensitivity (score wild bootstrap, B = 999) runs in Stata in minutes. The whole card runs in well under 30 minutes.

## 1. Claims family (frozen headline rows, A1 union) and interpretations
Eleven rows in `claims/claims.csv` have `headline = 1`: five Table 5 coefficients and six predicted probabilities (TXT_p9_a–f). Interpretations are quoted from `claims/claims_spec.md` (b) and (c). Where one sentence carries a coefficient and a probability, or an interaction and a reversal, they are separate rows.

**H1, racial widening on the log-odds scale (Table 5).** The authors' reading: "the coefficient estimates for black and coloured in the baseline period as well as for the pandemic interaction are negative, large in magnitude, and significant at the 1% level" (p.9); "After controlling for age, sex, race, occupation and the literacy of the informant, we conclude that racial disparity in access to healthcare increased during the pandemic" (p.10).

| Row | Source | Published b₀ (SE) | A8 type | Confirm margin |
|---|---|---|---|---|
| H1-c2-col | `T5_c2_Coloured_x_Pandemic` | −0.7167** (0.2793) | magnitude | same sign, Bonferroni CI excludes 0, \|b\| ≥ 0.35835 |
| H1-c2-bl | `T5_c2_Black_x_Pandemic` | −1.215*** (0.3244) | magnitude | same sign, Bonferroni CI excludes 0, \|b\| ≥ 0.6075 |
| H1-c3-col | `T5_c3_Coloured_x_Pandemic` | −0.6029** (0.2915) | magnitude | same sign, Bonferroni CI excludes 0, \|b\| ≥ 0.30145 |
| H1-c3-bl | `T5_c3_Black_x_Pandemic` | −1.222*** (0.3218) | magnitude | same sign, Bonferroni CI excludes 0, \|b\| ≥ 0.611 |
| H1-all | p.10 sentence, both groups, full specification | conjunction of H1-c3-col and H1-c3-bl | universal | §8 conjunction rule |

The "1% level" in the authors' sentence is not an extra gate: A3 condition 2 (adjusted 5%) is the protocol default, and the printed stars already show that two of the four rows are only at 5% (claims_spec (e)2).

**H2, racial widening on the probability scale (A4c).** The authors' reading: "During the pandemic, with strained healthcare services, the probability of access to healthcare dropped for all black and coloured people more than for white people" (p.9). Comparative claim: the pandemic change in the probability of a named doctor is more negative for group k than for whites, i.e. DiD_k < 0. The target is the fixed 11-district estimation sample (§3), not a population of districts. The rows report a standardised descriptive cross-difference among complete-case decedents. They do not establish individual-level universality, a causal pandemic effect, or that each group's own change is a decline (each group's own change is reported, not voting).

| Row | Estimand | A8 type | Verdict |
|---|---|---|---|
| H2-P-col | DiD_col (§3), spec 2 | comparative "<" | not-testable (no valid inference, §4C); estimate and leave-one-out range reported |
| H2-P-bl | DiD_bl (§3), spec 2 | comparative "<" | not-testable (same) |
| H2-P-all | "for all black and coloured people" | universal | not-testable (conjunction rule, §8) |

Spec 2 is the central model for H2 because the p.9 passage and its numbers come from spec 2 (S5-3, F6). Spec 3 is sensitivity 13.

**H3, the urban reversal (Table 5 col. 3).**
- **H3-int** (`T5_c3_Pandemic_x_Street_road_and_stad`, −1.168*** (0.4356)). Magnitude claim on the interaction: same sign, Bonferroni CI excludes 0, \|b\| ≥ 0.584.
- **H3-rev.** "Living in the city ... became a health hazard rather than a benefit during the pandemic" (abstract); "the benefit of urban living in having access to healthcare was reversed during this pandemic" (p.16). Comparative claim with two parts: outside the pandemic urban addresses had better access (β_S > 0), and during the pandemic worse access (θ_U = β_S + β_P×S < 0). Each part has a symmetric reading: β_S > 0 / includes 0 / < 0 and θ_U < 0 / includes 0 / > 0 (§8). The sign of θ_U is the sign of the urban contrast on the probability scale for every covariate profile (the logit link is monotone), so no separate A4c row is needed for the reversal. The "35% to 31%" figures (TXT_p15) are not headline rows.
- **H3-mort** ("a health hazard" read as mortality; also the abstract's "unequal health outcomes were a consequence of unequal access"). **Not-testable.** The dependent variable is a doctor named on the certificate, observed only among decedents; no mortality model or exogenous variation in access exists in the data (S5-7, F9).

**P, predicted probabilities for the "representative inhabitant of Paarl"** (white or coloured or black, female, 25–34, Farming, illiterate informant). Point claims on [0,1], A8a band = min(±3 pp, ±10% of the stated value):

| Row | Source | Stated | Band (pp) |
|---|---|---|---|
| P-a | `TXT_p9_a` white, baseline | 93.4 | [90.4, 96.4] |
| P-b | `TXT_p9_b` coloured, baseline | 85.0 | [82.0, 88.0] |
| P-c | `TXT_p9_c` black, baseline | 69.8 | [66.8, 72.8] |
| P-d | `TXT_p9_d` white, pandemic | 57.7 | [54.7, 60.7] |
| P-e | `TXT_p9_e` coloured, pandemic | 21.0 | [18.9, 23.1] (±2.1, A8a) |
| P-f | `TXT_p9_f` black, pandemic | 6.2 | [5.58, 6.82] (±0.62, A8a) |

Endpoints are inside the band. These rows test what the authors printed: model-implied probabilities for a cell that has no certificates in the rebuild (S5-4). They therefore assess the functional-form extrapolation, not an observed group; the support count is reported next to each verdict (§5, sensitivity 16) and does not change it.

**Stars.** *** 0.01, ** 0.05, * 0.1 (Table 5 notes); `stars05` = 2 (A7).

## 2. Defects addressed
S5 (Claude S5-1 to S5-9, Codex F1–F10, reconciled in `audit.md`) found these defects and fixes:
- **(a) Small-cluster inference (S5-5, F8; changes-a-conclusion for the urban row).** The paper clusters by district with 15 clusters and no small-sample correction; the rebuild has 11 and a non-PSD CR1 matrix. **Fix:** the CV3 cluster jackknife with t(G − 1) critical values (MacKinnon, Nielsen and Webb 2023, "Cluster-robust inference: A guide to empirical practice", *J. Econometrics*; Bell and McCaffrey 2002). For logit models the guide is MacKinnon, Nielsen and Webb (2024, "Cluster-robust inference for binary response models", arXiv 2406.00650), which finds that CV3 and the score wild cluster bootstrap behave best for coefficients with few clusters and treats predictions and marginal effects with cluster fixed effects as an unresolved inference problem (their §4). The CV3 jackknife is therefore the primary for **coefficients and their linear combinations** (H1, H3), where it has direct support. For the AME cross-difference (H2) it is used under the explicit random-cluster interpretation in §4C, and the lack of logit-specific validity is carried to §10. The score wild bootstrap (Kline and Santos 2012; Roodman et al. 2019) is sensitivity 5.
- **(b) Urban reversal arithmetic (F1; claims_spec (e)5; changes-a-conclusion).** The interaction is read as the pandemic urban effect; the net pandemic contrast is the sum. **Fix:** H3-rev is judged on θ_U = β_S + β_P×S and on β_S.
- **(c) Occupation coding (F3; changes-a-number).** The rebuild sends every "farm" string to the Farming reference before the professional keywords, while the paper puts farmers (farm owners) in Professionals/Managers. **Fix:** §4A rule O.
- **(d) Death-in-family timing (F4; changes-a-number).** Days capped at 28, same-day deaths counted, nearest-record rule. **Fix:** §4A rule D.
- **(e) Predicted probabilities from the wrong model (S5-3, F6).** **Fix:** the P and H2-P rows use spec 2.
- **(f) Probability-scale widening (A4c; S5-5 interpretation).** The paper reports only log-odds but states probabilities. **Fix:** H2-P rows on a standardised average probability cross-difference (Ai and Norton 2003; Puhani 2012, who distinguishes the treatment-effect cross-difference from the raw nonlinear cross-difference; the card uses the latter as a descriptive contrast).
- **Not fixable:** the four missing districts; the paper's HISCO coding, race and doctor coding and reference district (unknown); the empty reference cell (S5-4); the causal mortality reading (S5-7); the death-in-family control as a possible mechanism (F9; spec 3 without it is sensitivity 12, no vote); star/SE mismatches in non-headline rows (S5-1, S5-2, F7).

## 3. Estimands
- **Model.** Pooled logit, Pr(doc = 1) = Λ(α_district + β_C·Col + β_B·Bl + γ·P + δ_C·Col·P + δ_B·Bl·P + X'λ + (P·X)'μ), with spec-2 X = age groups (25–34 reference), male, occupation groups (Farming reference), signature; spec-3 X adds birthplace (Cape reference), Death_in_Family, Nurse, Railway, Farm, Street_road_and_stad. P = 1 for deaths 1 Oct 1918 – 31 Jan 1919. Original estimand: these coefficients on the 15-district sample; new estimand: the same coefficients on the 11-district subsample with corrected coding (§0).
- **H1 rows:** δ_C, δ_B in spec 2 and spec 3.
- **H3-int:** μ_Street in spec 3. **H3-rev:** β_S = λ_Street and θ_U = λ_Street + μ_Street in spec 3.
- **H2-P rows (spec 2):** for each certificate i in the estimation sample, p̂_i(r, q) is the fitted probability with race set to r ∈ {W, C, B}, P set to q ∈ {0, 1}, every race × P and P × X term recomputed from the counterfactual r and q, and all other covariates (and the district) at their observed values.
  DiD_k (the standardised cross-difference) = (1/N) Σ_i [p̂_i(k, 1) − p̂_i(k, 0) − p̂_i(W, 1) + p̂_i(W, 0)], k ∈ {C, B}, in percentage points. The standardisation population is the complete-case decedents of the estimation sample; DiD_k is not interpreted as a causal effect of the pandemic.
- **P rows (spec 2):** 100 × Λ(x'_ref β̂) for the reference person: district Paarl; female; age 25–34; Farming; signature = 0; race and P as in §1; all other dummies 0.

## 4. Primary analysis (one per verdict row)
**A. Data and corrections.** Start from `repro_r/01_clean.R` logic on the two raw files (`New 10 towns 1915-1920.xlsx`, `2020-05 JB Sea Point 1915-1920.xlsx`) read from D:. `modern/01_build.R` reproduces the rebuild and changes only:
- **Rule O (occupation).** Before the rebuild's `case_when`, a string matching `\bfarmers?\b|farm ?owner|\bboer\b|landowner|grazier` and **not** matching `labour|worker|hand|servant|boy|bywoner|wife|daughter|son\b` is coded Professionals_and_managers. Strings matching "farm" together with `labour|worker|hand|servant|boy|bywoner` are Farming. All other rules and their order are unchanged ("wife" strings keep the rebuild's Sales_and_service rule).
- **Rule D (death in family).** Dates use the recorded day; a recorded day beyond the month's length is set to the month's last day; a missing day is set to 15 (as the rebuild; sensitivity 4 drops these from the rule). Death_in_Family = 1 if **any** other certificate with the same non-blank cleaned surname and the same town is dated **1 to 7 days earlier** (inclusive), reading "within the week before an individual's death" (Appendix A). Ties and record order cannot change the flag. Blank surname = 0.
- Pandemic, race, doctor, signature, age, birthplace, Nurse, Railway, Farm and Street_road_and_stad are the rebuild's definitions, unchanged.
- **Samples.** Spec 2 and spec 3 share one sample: complete cases on doc, race and every spec-3 regressor (the paper prints equal N; F5). Spec 2 on its own complete cases is sensitivity 11. Row counts by district and by race × period are reported.

**B. Estimation.** `fixest::feglm(doc ~ ... + factor(town), family = "binomial")`, default convergence settings, no weights.

**C. Inference (single rule for all rows with inference).**
- G = number of districts in the estimation sample (11 expected; reported).
- For each district g, refit the model without g (θ̂_(g)); for the descriptive H2-P statistics recompute DiD_k on the leave-one-out sample's own observations.
- **H2-P rows: no inferential verdict (frozen).** The target is the DiD_k of the fixed 11-district sample, so a sampling-based interval would need a cluster-sampling model, and no validity result exists for logit average marginal effects with district fixed effects (MNW 2024 §4). The card therefore does not test H2-P. It reports DiD_k, its leave-one-district-out range and the delete-one jackknife SE (recomputing DiD_k on each leave-one-out sample's own observations) as **descriptive influence measures**, with no CI, p-value or verdict role. Verdict: not-testable (§8). This is the choice offered by the Codex compliance check; the limitation is in §10.
- **CV3 variance:** V = ((G − 1)/G) Σ_g (θ̂_(g) − θ̂)², centred on the full-sample estimate θ̂ (the more conservative variant; the jackknife-mean-centred CV3J is sensitivity 7). For θ_U the jackknife is applied to the sum directly.
- t = θ̂ / √V, reference t distribution with G − 1 df. Unadjusted two-sided p from it; Bonferroni CI = θ̂ ± t_{G−1}(1 − 0.05/(2m))·√V, m = family size (R: 4; U: 3). Significance and credible-null/comparative decisions all use this one interval (§6).
- No seed is needed (deterministic). Reported per row: G, cluster sizes (min, median, max), the largest district's share of N, and every leave-one-out estimate.

**D. Failure rules (symmetric; decided before any modern estimate). A failure can only make a row not-testable; it never confirms or overturns.**
- **Package and tolerances (frozen).** R 4.5.2, `fixest` 0.13.2 (installed version at freeze; `modern/sessionInfo.txt` must show it, otherwise stop and report), `feglm` with `glm.tol = 1e-08`, `glm.iter = 25`, `fixef.tol = 1e-06`, `fixef.iter = 10000`, `collin.tol = 1e-09`, `nthreads = 1`. Nothing is changed after any estimate is seen. Non-convergence within these settings is a failure.
- **Full-sample failure → not-testable** for every row that needs the failing quantity if any of these holds:
  - feglm reports non-convergence;
  - a target coefficient (δ_C, δ_B, μ_Street, λ_Street, or any coefficient used by the row) is dropped for collinearity, is non-finite, or has a non-finite SE or jackknife value. The district dummy absent because it is the reference is expected and is not a failure; a district dummy dropped for any other reason, or any other dropped regressor, is logged and fails the row only if a target coefficient is affected;
  - **separation:** fixest removes observations or reports separation / infinite coefficients, or any fitted probability is below 1e-10 or above 1 − 1e-10 for a target-relevant observation. Finite output alone does not count as success.
- **Jackknife failure → not-testable for that row.** Any leave-one-out fit that fails to converge, drops a target coefficient, shows separation as defined above, or yields a non-finite value makes the row not-testable. There is no verdict-determining fallback. District-clustered CR1 (`vcov = ~town`) and the normal and t references are reported as diagnostics (sensitivity 6) only.
- **P rows:** not-testable if x'_ref β̂ needs a coefficient that is dropped or non-finite (including the Paarl dummy), or the prediction is non-finite.
- **Not-testable member of a family:** the family keeps its frozen size m, so the Bonferroni level stays at 1 − 0.05/m. Computational failures never relax another row's threshold.

## 5. Admissible sensitivities (exhaustive; reported, never verdict-determining)
Each sensitivity re-estimates every row it applies to with the primary inference unless stated.
1. The uncorrected S3 rebuild coding (rebuild occupation and death-in-family).
2. Rule O alone; rule D alone.
3. Death-in-family window 0–7 days (same-day deaths included).
4. Rule D computed only on certificates with a recorded day (imputed-day records get Death_in_Family = NA and leave spec 3).
5. **Score wild cluster bootstrap** (Kline and Santos 2012) via Stata `boottest` after `logit ..., vce(cluster town)`, null imposed, Webb weights, B = 999, `seed(20261012)`, CI by inversion where boottest provides it (coefficient rows and θ_U; not the AME rows). boottest installed into `P12_FJ/modern/ado/`.
6. District-clustered CR1 with t(G − 1), and with the normal reference (the paper's inference). Diagnostic only; also reported for any row not-testable under §4D.
7. CV3J (jackknife-mean-centred).
8. Leave-one-district-out: the range of each primary estimate and the number of drops that would change the verdict category.
9. LPM analogue of specs 2–3 with a wild cluster restricted bootstrap (`fwildclusterboot::boottest`, Webb, B = 999, seed 20261012). A different estimator; reported on the probability scale next to H2-P (descriptive).
10. Pandemic window 1 Oct – 31 Dec 1918.
11. Spec 2 on its own complete-case sample.
12. Spec 3 without Death_in_Family and its interaction (the mechanism concern in F9).
13. Spec 3 as the model for the H2-P and P rows.
14. Calendar-year fixed effects added (P is still identified within 1918–1919).
15. District × pandemic fixed effects (P absorbed): race × P compared within district.
16. Support: certificate counts in the reference cell (by race × period), the raw doctor share by race × period, and the spec-2 predictions for the most populated white, coloured and black covariate cells in each period. **Overlap for H2:** the distribution of the fitted probabilities p̂_i(r, q) by counterfactual race, and the share of observations with a counterfactual fitted probability below 0.01 or above 0.99.
17. Doctor coding: initials-only entries in `Medical man's name` treated as missing rather than as a named doctor.
18. Changed population (A4d): Sea Point excluded.
20. Descriptive race-specific trends: the raw doctor share by race and quarter, 1915 to 1920, with each race's pre-pandemic (1915 to September 1918) linear slope and post-pandemic level. It diagnoses differential pre-trends and composition; calendar-year fixed effects (sensitivity 14) do not.
21. Each group's own pandemic change p̂(k,1) − p̂(k,0) (the components of DiD_k), descriptive with jackknife spread.
19. Descriptive, non-headline (F2): the pandemic-period occupation contrasts (Production, Sales/service, Professionals vs Farming) as λ + μ sums with primary inference.

## 6. Fixed choices
- **Population:** 11 recovered districts, 1915–1920. **No weights.** **Missing data:** complete cases (§4A). **No trimming.**
- **Multiplicity families** (one Bonferroni CI at 1 − 0.05/m decides significance, credible nulls and comparative rows):
  - **Family R (m = 4):** H1-c2-col, H1-c2-bl, H1-c3-col, H1-c3-bl.
  - **Family U (m = 3):** μ_Street (H3-int), β_S, θ_U (H3-rev).
  - H2-P rows have no inferential family (§4C).
  - P rows have no inference.
- **Bonferroni rule (A3 condition 2).** A3 asks for a multiplicity-adjusted CI that excludes 0. The card uses exactly that: the Bonferroni CI at 1 − 0.05/m. "Significant" means this CI excludes 0 (equivalently, unadjusted p < 0.05/m). It is stricter than Holm and has no discordance case. Credible nulls (A4a) and comparative rows use the same CI.
- **Boundary rules:** a CI endpoint at exactly 0 counts as "CI includes 0" and an estimate of exactly 0 as "sign not established"; |b| = 0.5|b₀| meets the floor; **P-row band endpoints are inside the band (inclusive); a credible-null interval is open (A4a): the CI must lie strictly inside (−0.5|b₀|, +0.5|b₀|), so an endpoint on the limit is not a credible null.**
- **Seeds:** 20261012 (sensitivities 5 and 9 only). **Scripts:** `modern/01_build.R`, `02_primary.R`, `03_sensitivities.R`, `03b_score_boot.do`, `04_verdicts.R`.

## 7. Margins and their provenance
| Row | Confirm | Provenance |
|---|---|---|
| H1-c2-col / c2-bl / c3-col / c3-bl | same sign, Bonferroni CI excludes 0, \|b\| ≥ 0.35835 / 0.6075 / 0.30145 / 0.611 | A3 |
| H1 credible null | Bonferroni CI strictly within ±0.35835 / ±0.6075 / ±0.30145 / ±0.611 | A4a |
| H3-int | same sign, Bonferroni CI excludes 0, \|b\| ≥ 0.584; credible null strictly within ±0.584 | A3, A4a |
| H3-rev | Bonferroni CI of β_S > 0 and of θ_U < 0; the opposite entirely-signed CI on either part overturns | A8 comparative default, applied symmetrically to both parts of the authors' sentence |
| H2-P-col / bl | none: not-testable by rule (§4C) | A4c scale; no valid inference |
| P-a … P-f | bands in §1 | A8a (min of ±3 pp and ±10%) |
| H1-all, H2-P-all | conjunction (H2-P-all not-testable) | universal claim ("both", "all black and coloured") |

- No ceilings. **Plausibility flag** (reported, not verdict-determining): |b| > 1.5|b₀| on H1 and H3-int rows.
- "Strengthened" is not used: no row is judged on a design that is more credible for the same 15-district estimand.

**Disclosure.** S0, S4 and S5 numbers seen before this card, all bearing on the verdicts:
- **Published arithmetic:** urban contrast during the pandemic 1.338 − 1.168 = +0.170 (35% rural → 39.0% urban); Production 0.8088 − 0.5221 = 0.2867; Sales/service 0.2536; Railway 0.6251 + 0.1443 = 0.769 vs a text gap of 0.85.
- **Published predictions:** spec 2 anchored on 93.4% gives 85.0 / 69.8 / 90.2 and a white pandemic 60.0% (implied Pandemic −2.335 vs −2.243 printed); coloured and black pandemic 22.6 / 6.8; spec 3 anchored gives 85.3 / 72.1 and white pandemic 51.8.
- **Rebuild (11 districts; N 30,420 spec 1, 26,823 specs 2–3), district-clustered logit:** spec 2 Coloured × P −1.286 (p < 0.001), Black × P −0.897 (p 0.007), Pandemic −0.465 (p 0.146); spec 3 Coloured × P −0.979 (p 0.000024), Black × P −0.874 (p 0.036), Street × P −1.093 (p 0.125; iid SE 0.122 vs clustered 0.712).
- **Leave-one-district-out (spec 3):** Coloured × P −1.13 to −0.62 (max p 0.108); Black × P −1.21 to −0.51 (max p 0.153); Street × P −1.78 to −0.41 (max p 0.720).
- **Window Oct–Dec 1918:** −1.07 (p < 0.001), −0.905 (p 0.035), −1.14 (p 0.132).
- **LPM analogue, WCB (Webb, B 9,999):** Coloured × P −0.250 (p 0.008), Black × P −0.100 (p 0.257), Street × P −0.133 (p 0.337).
- **Rebuild predictions:** spec 3 86.1 / 72.3 / 53.6 and 80.7 / 39.8 / 24.5; spec 2 89.1 / 77.2 / 57.6 and 83.8 / 37.0 / 25.8.
- **Raw doctor shares (rebuild):** white 79.2% → 69.0% (n 3,396 and 523); coloured 68.7% → 33.7%; black 28.7% → 8.1%. Reference cell: 0 certificates in either period; white female farmers aged 25–34: 2 and 1.

Not yet run: the corrected coding (rules O and D), any CV3 jackknife, any AME DiD, the score bootstrap, and every sensitivity in §5 except the parts listed above. The rebuild's λ_Street (needed for θ_U) has not been seen. All margins are protocol defaults; the H3-rev two-part reading follows the authors' wording ("rather than a benefit", "reversed"), but the decision to judge the sum was made after F1's published +0.170 was seen (§10).

## 8. Verdict tables (central analysis only; checked in order; the first rule that applies decides; exhaustive)
**H1-c2-col, H1-c2-bl, H1-c3-col, H1-c3-bl, H3-int** (A3/A4; Family R or U, Bonferroni CIs at 1 − 0.05/m; b₀ < 0 for all):
| # | Condition | Verdict |
|---|---|---|
| 0 | not-testable under §4D | not-testable |
| 1 | b > 0 and Bonferroni CI excludes 0 | overturned (reversed) |
| 2 | Bonferroni CI strictly inside the open interval (−0.5\|b₀\|, +0.5\|b₀\|) | overturned (credible null) |
| 3 | b < 0, Bonferroni CI excludes 0, \|b\| ≥ 0.5\|b₀\| | confirmed |
| 4 | b < 0, Bonferroni CI excludes 0, \|b\| < 0.5\|b₀\| | qualified (magnitude below floor) |
| 5 | Bonferroni CI includes 0, b < 0 | weakened |
| 6 | Bonferroni CI includes 0, b ≥ 0 | weakened (direction lost) |

**H3-rev** (Family U; Bonferroni CIs at 1 − 0.05/3). Component status, same rule for both: β_S *supports* if its CI is entirely > 0, *contradicts* if entirely < 0; θ_U *supports* if its CI is entirely < 0, *contradicts* if entirely > 0; otherwise *uncertain* (CI includes 0). Same order as the conjunction table:
| # | Condition | Verdict |
|---|---|---|
| 1 | either component contradicts | overturned (names the contradicting component) |
| 2 | either component not-testable under §4D (and row 1 did not apply) | not-testable |
| 3 | both components support | confirmed |
| 4 | exactly one component supports, the other uncertain (either way round) | qualified |
| 5 | both components uncertain | weakened |

Rows are exhaustive: each component is one of supports / contradicts / uncertain / not-testable, and rows 1–5 cover every combination.

**H2-P-col, H2-P-bl:** not-testable (§4C); no table. The descriptive DiD_k, its leave-one-out range and the §5 results are reported next to the row.

**P-a … P-f** (A8a band B = [lo, hi]; estimate π̂):
| # | Condition | Verdict |
|---|---|---|
| 0 | prediction non-finite or model not-testable | not-testable |
| 1 | lo ≤ π̂ ≤ hi | confirmed |
| 2 | π̂ < lo | qualified (below the stated value) |
| 3 | π̂ > hi | qualified (above the stated value) |

**Conjunctions H1-all (members H1-c3-col, H1-c3-bl) and H2-P-all (members H2-P-col, H2-P-bl; always not-testable because both members are):**
| # | Condition | Verdict |
|---|---|---|
| 1 | any member overturned | overturned |
| 2 | any member not-testable | not-testable |
| 3 | all members confirmed | confirmed |
| 4 | otherwise | the weakest member verdict (weakened < qualified) |

**H3-mort:** not-testable.

**Scope.** Every verdict row carries the §0 `scope` field. Verdicts on H1 and H3 assess the 11-district subsample and the doctor-naming outcome only.

**Summaries and coverage.** For each family, report coverage (rows assessed; rows not-testable), every row-level verdict, and the weakest assessed verdict, ordered overturned < weakened < qualified < confirmed. The §5 results are reported next to each verdict, by item; none changes a verdict.

## 9. Codex review notes and responses
**Codex v1 review** (reviews/P12_FJ_codex_S6card.md): approve-with-changes, 9 required changes, addressed in v2. Items 2, 4, 5 and 6 were rated partly addressed by the v2 compliance check and are revised in v3 (see the v2 check below).
1. **CV3 justification.** §2(a) now cites MacKinnon, Nielsen and Webb (2024) for logit models, restricts the direct support claim to coefficients and linear combinations, and no longer claims uniform validity for marginal effects.
2. **H2 inferential target.** v2 froze a random-cluster interpretation; superseded in v3: H2-P verdicts are not-testable by rule (§4C).
3. **CR1 fallback removed.** §4D: a failed jackknife makes the row not-testable; CR1 is diagnostic only (sensitivity 6).
4. **Numerical failure rules.** §4D separates the reference district dummy from dropped target coefficients, and adds separation checks, prediction estimability for P rows, default tolerances and the recorded package version.
5. **Multiplicity.** Frozen family sizes (§4D). v2's Holm reconciliation is superseded in v3: the Bonferroni CI decides significance (§6).
6. **H3-rev symmetry.** §8 table: θ_U > 0 overturns (described as pandemic urban advantage), β_S < 0 overturns, and the rows are exhaustive.
7. **H2 interpretation.** Renamed a standardised descriptive probability cross-difference among complete-case decedents (§1, §3); components reported (sensitivity 21).
8. **Scope.** §0 `scope` field carried into every verdict output (§8).
9. **Randomisation "ideal" removed** from §10; sensitivities stay diagnostic.

Optional suggestions adopted: race-specific trends (sensitivity 20), overlap report (sensitivity 16). Not adopted: PPML, estimation weights and correlated-assumption simulation (not applicable to this design). 

**Codex v2 compliance check** (reviews/P12_FJ_codex_S6card_v2.md): revise-again, 5 issues, all resolved in v3.
1. **H2 target and inference.** H2-P verdicts are not-testable by rule; descriptive estimates remain (§4C, §8).
2. **A3 adjusted CI.** Significance now requires the Bonferroni CI to exclude 0 (§6); Holm is dropped, so no discordance case.
3. **H3-rev symmetry.** One component rule and the conjunction order: contradiction first, then not-testable, then confirmed / qualified / weakened (§8).
4. **Numerical reproducibility.** fixest 0.13.2, tolerances and iteration limits frozen (§4D).
5. **Open credible-null interval.** Strict containment for credible nulls; inclusive endpoints for P bands only (§6, §8).

## 10. Known limitations at freeze
1. **Subsample population.** Every verdict is on 11 of 15 districts (N ≈ 27,000 vs 32,555). The absence of Fraserburg, Riversdale, Stellenbosch and Stockenstrom may change the racial composition, the urban share and the number of clusters (11 vs 15). A confirmation or an overturn here does not establish the 15-district result.
2. **Inference with 11 clusters.** The primary uses the CV3 jackknife because one rule covers coefficients and sums and runs in minutes; the score bootstrap (B = 999, wave-3 cap) is sensitivity 5 and decides nothing. CV3 with 11 heterogeneous clusters (Sea Point has 343 certificates) can be imprecise in either direction. For the H2 AME cross-difference, no validity result exists for logit marginal effects with district fixed effects (MNW 2024 §4), so H2-P is not-testable by rule (§4C).
3. **Coding not identical to the paper.** Rule O is a keyword approximation of the paper's HISCO coding; race, doctor and Street/Farm source fields remain the rebuild's readings. The paper's reference district is unknown (irrelevant to coefficients, relevant to no row except via P rows, where Paarl is stated).
4. **One-model corrections.** Rules O and D implement Codex findings F3 (agreed) and F4 (one-model, accepted on code reading); no independent data check of how many records each rule moves was made before freeze.
5. **Empty reference cell.** The P rows test model extrapolations to a cell with no certificates; a confirmation does not show that any real group had these probabilities.
6. **H3-rev reading after F1.** The two-part reading follows the authors' words, but it was formalised after the published net contrast (+0.170) was seen, and that number already points against the reversal.
7. **Death-in-family window.** "Within the week before" is read as 1–7 days; the same-day reading is sensitivity 3.
8. **Bad control.** Spec 3 conditions on death in family, a possible mechanism (F9); the central spec-3 rows keep it as published; sensitivity 12 only.
9. **Not-testable claims.** H3-mort (and with it the abstract's causal health-outcome sentence) and the supply-side "no discrimination" claim (non-headline) are outside what the data can assess.
10. **Bonferroni is conservative.** Significance uses the Bonferroni CI (m = 4 or 3), stricter than Holm; with 11 clusters a row can fail the CI while a looser test would pass. The reported unadjusted p is descriptive only.
11. **H2 is descriptive and not-testable.** The probability-scale racial widening claim receives no verdict; only H1 (log-odds) tests racial widening. The cross-difference among complete-case decedents is not a causal pandemic effect and not individual-level; the doctor-naming outcome is not healthcare access in general.
12. **Not-testable on failure.** With 11 clusters a single leave-one-out failure removes a row's verdict; this is the cost of dropping the CR1 fallback.
13. **Status.** v3, frozen. Second-order issues not caught by the capped review (A9) are reported in the synthesis, not fixed.
