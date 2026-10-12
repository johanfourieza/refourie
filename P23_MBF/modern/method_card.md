# Method card: P23_MBF, leader selection and education in 11 African countries

Status: v3 (2026-10-11), final.
- History: v1 → Codex review (reviews/P23_MBF_codex_S6card.md; approve-with-changes, 8 required changes) → v2 → Codex compliance check (reviews/P23_MBF_codex_S6card_v2.md; freeze-after-minor-edits, 4 edits) → v3, which is frozen (A9). No further review round.
- Margins follow AMENDMENTS.md A3, A4, A8 and A8a. No margin, band, ceiling or gate is chosen by the card author.
- To be FROZEN with the commit message "FREEZE S6 card P23". Issues not fully resolved are listed in §10.
- **Numerical constants.** Every b₀, floor (0.5|b₀|), band endpoint (±0.5|b₀|) and plausibility threshold (1.5|b₀|) is computed in the scripts from its exact definition. For H2-lit and H2-RRR, b₀ = ln(1.32) exactly. Decimal values printed in this card (0.2776, 0.1388, 0.4164) are display values only and are never used in a comparison.

Rights class: restricted-licence for the IPUMS micro file (Table 2); open for the Murdock/ALTT/GIS region file (Table 5). Every script runs locally on D:. Codex sees this card, the code and aggregate outputs only, never IPUMS rows.

## 0. Type of analysis and the primary analysis per claim
**One primary analysis per claim.** Only that analysis decides a verdict; every other analysis in this card is a sensitivity or a diagnostic and never votes.
- **H1 and H2** (Table 2): primary analysis **A**, the published col 4 logit with wild cluster restricted score bootstrap inference (§4A).
- **H3** (Table 5): primary analysis **B**, a Firth penalised logit with profile penalised-likelihood inference (§4B).

Within its primary analysis, each claim has several verdict rows, one per interpretation (A4c requires separate odds-ratio and probability rows). Each row is decided by one statistic from that analysis and one inference rule (§6). The **claim-level verdict** is the verdict of the row that tests the frozen headline number on its printed scale: H1-OR for H1, H2-OR for H2, H3-OR for H3 (§8). The other rows are reported as separate verdicts and are never combined with it.

| Rows | Type | What changes | Consequence |
|---|---|---|---|
| H1-OR, H1-P, H2-OR | **(ii) inference-only upgrade** | The published Table 2 col 4 logit is kept exactly (β₁ = .3802, β₃ = .2810). Only the inference changes: a wild cluster restricted score bootstrap replaces analytic CR1 (§2a). | A4b ladder: confirmed / qualified (inference-fragile) / weakened. **Overturned is unreachable.** |
| H2-Pd, H2-lit, H2-RRR | **(iv) new statistics** on the probability scale, from the published model (A4c), with the same inference | The authors state odds ratios as probabilities. The logit interaction coefficient is not the interaction on the probability scale (Ai and Norton 2003). | The point estimates are new, so A3/A4/A8 apply in full. Overturned is reachable. |
| H3-OR, H3-P | **(iv) new estimator of the same estimand**: Firth in place of ML, same 64 regions and printed specification | ML is unreliable under quasi-separation: 15 events, about 23 parameters (C1). | A3/A4/A8 apply in full. Overturned is reachable. |

No row is type (i). The verified code and data errors in this paper (C7, C8, C9, F01–F03) concern Tables 3 and 4, which carry no headline row. The Table 5 discrepancy (C2, F04) is not a verified error: the printed specification is reproduced exactly by A', and the primary keeps it. No row is type (iii).

## 1. Claims family (frozen headline rows) and interpretations
The three `headline = 1` rows in `claims/claims.csv` (A1 union) map to the verdict rows below. Interpretations are quoted from `claims/claims_spec.md`. Stars: * .10, ** .05, *** .01 (`stars05` = 2). "Adj p" is the Bonferroni-adjusted p within the row's family (§6).

**H1, the birth-region gap** (`T2_br_c4`, .38*** (.11), log-odds; Table 2 col 4, N = 5,077,010, 624 clusters).
Authors' reading (p.1575): "the individuals born in a leader's birth region (irrespective of the age cohort) had a higher probability of completing primary education. This is the main result of the paper." Abstract: "leaders are selected from more advanced regions".

| Row | Claim | Scale | A8 type | Margin |
|---|---|---|---|---|
| **H1-OR** (claim-level) | the Birth Region coefficient .38 | log-odds, b₀ = 0.38 | magnitude | A3/A4: same sign, adj p < .05, β₁ ≥ 0.19 (fixed by A4b) |
| H1-P | "a higher probability … irrespective of the age cohort" | probability | comparative ">" with a universal quantifier | conjunction: the gap > 0 for post-independence cohorts (β₁) **and** pre-independence cohorts (β₁ + β₃), each with adj p < .05 (A8 default) |

In col 4, β₁ is the post-independence gap and β₁ + β₃ the pre-independence gap (C18), so "irrespective of the age cohort" requires both. In a logit, the individual discrete change of a binary regressor has the sign of its index coefficient for every individual, so "AME > 0" and "coefficient > 0" are the same hypothesis. H1-P is decided on the coefficient tests, and the two AMEs are reported. The authors state no probability magnitude, so H1-P has no floor (A8 comparative).

**H2, the gap was larger before independence** (`T2_ia_c4`, .28** (.13), log-odds).
Authors' reading (p.1575): ".28 + .38 = .66, i.e. equal to an odds ratio of 1.93. We thus find that, for individuals born in a leader's birthplace, the likelihood of completing primary education is 32% higher for those who attended primary school before independence than for those who attended primary school after independence." Conclusion (p.1585): "this difference was greater during the period before independence".

The "32% higher" sentence has two readings (claims_spec §(e)3; F08). Each gets its own row and is decided only by its own statistic:
- **Literal reading (the stated comparison):** inside leader birth regions, pre-independence cohorts against post-independence cohorts. On the log-odds scale this contrast is β₂ + β₃, not β₃.
- **Reconstructed reading (the authors' computation):** the number 1.32 is exp(β₃), a ratio of birth-region odds ratios. On the probability scale its counterpart is the ratio of the pre- to the post-independence birth-region risk ratio. This reading is labelled **reconstructed**: its verdict decides only its own row and cannot overturn, or rescue, the literal reading.

| Row | Claim | Scale | A8 type | Margin |
|---|---|---|---|---|
| **H2-OR** (claim-level) | the interaction coefficient .28 (OR 1.32) | log-odds, b₀ = 0.28 | magnitude | A3/A4: same sign, adj p < .05, β₃ ≥ 0.14 (fixed by A4b) |
| H2-Pd | "this difference was greater during the period before independence" | probability (pp) | comparative ">" | ΔAME > 0, adj p < .05 (A8 default) |
| H2-lit | "the likelihood … is 32% higher" (literal: within birth regions, pre vs post) | log risk ratio, b₀ = ln(1.32) (≈ 0.2776) | magnitude (A4c) | A3/A4: ln RR_lit > 0, adj p < .05, ln RR_lit ≥ 0.5·ln(1.32) (≈ 0.1388) |
| H2-RRR | the same number, reconstructed as exp(β₃) on the probability scale | log ratio of risk ratios, b₀ = ln(1.32) | magnitude (A4c) | A3/A4: ln RRR > 0, adj p < .05, ln RRR ≥ 0.5·ln(1.32) |

**H3, missions and leader birth regions** (`T5_mission_c4`, 9.10** (4.27), log-odds; Table 5 col 4, N = 64).
Authors' reading (p.1583): "the regions with higher levels of colonial education had a higher probability of producing a leader. This confirms that colonial education increased the probability that a leader would be born in a given region." No magnitude is stated in words.

| Row | Claim | Scale | A8 type | Margin |
|---|---|---|---|---|
| **H3-OR** (claim-level) | the mission coefficient 9.10 | log-odds, b₀ = 9.10 | magnitude | A3/A4: same sign, p < .05, β ≥ 4.55 |
| H3-P | "a higher probability of producing a leader" | probability | comparative ">" | β > 0, p < .05 (sign of the discrete change = sign of β, as for H1-P) |
| H3-causal | "colonial education increased the probability" | — | — | **not-testable**: a cross-section of 64 regions with no exogenous variation in mission placement |

**Not-testable abstract sentences.** "African leaders were created by colonial (and pre-colonial) institutions"; "can account for much of the variation in post-colonial outcomes"; "Favouritism was at least partially endogenous". The paper estimates no favouritism effect and no variance decomposition, and the data contain none. These sentences carry the paper's central causal interpretation; the card cannot assess it, and §8 reports this first.

**A4c.** Every headline coefficient is a logit coefficient. Each odds-ratio row (…-OR) is judged on the log-odds scale; each probability row (H1-P, H2-Pd, H2-lit, H2-RRR, H3-P) on a probability-scale statistic. They are separate rows in the verdict file.

## 2. Defects addressed
S5 (Claude C1–C19, Codex F01–F08, reconciled in `audit.md`) found:
- (a) **Few treated clusters in Table 2** (C5). Birth Region varies at the region level, and 29 of 624 clusters are leader birth regions. With few treated clusters, analytic CR1 can over-reject, and the restricted wild bootstrap can under-reject; neither failure is proven by the count alone, and the bootstrap is not guaranteed to be valid (MacKinnon and Webb 2017, *J. Applied Econometrics*; 2018, *Econometrics Journal*). Kline and Santos (2012, *J. Econometric Methods*) give the score bootstrap; Roodman, MacKinnon, Nielsen and Webb (2019, *Stata Journal*) give `boottest`. **Addressed by the primary inference of H1 and H2**, together with the leverage and influence diagnostics of §4A and the unrestricted bootstrap (S5) that brackets it.
- (b) **Odds ratios stated as probabilities, and the logit interaction read as a probability-scale interaction** (C18, F08). Sources: Ai and Norton (2003, *Economics Letters*); Norton, Dowd and Maciejewski (2018, *JAMA*); Muller and MacLehose (2014, *IJE*) on marginal standardisation. **Addressed by H2-Pd, H2-lit and H2-RRR.**
- (c) **Quasi-separation in Table 5** (C1): 64 regions, 15 events, about 23 parameters; the printed log-odds of 9.1 is an odds ratio of about 9,000. (The S5 figure of 0.954 came from `margins, dydx(d_mission)`, which treats the binary regressor as continuous. It is a derivative, not an established 95-point discrete change.) Sources: Firth (1993, *Biometrika*); Heinze and Schemper (2002, *Statistics in Medicine*); Puhr, Heinze, Nold, Lusa and Geroldinger (2017, *Statistics in Medicine*) for FLIC. Finite Firth estimates do not guarantee precision. **Addressed by the primary estimator of H3.**
- (d) **Table 5 specification and sample** (C2, C3, F04, F05): the printed col 4 needs an undisclosed `d_capital`; ML perfect prediction silently cuts the sample from 155 to 64 regions; the sample contains regions outside the 11 countries. Not a verified error. The primary keeps the printed specification and the 64 regions; the alternatives are sensitivities S18, S20, S23 and S24.
- (e) **Dependence on one country** (C6): without Ghana the interaction changes sign. Leave-one-country-out changes the population (A4d), so it is sensitivity S8 and does not vote. The concentration of treated clusters by country is reported (§4A).
- Not addressed (no headline row, or not fixable with these data): Table 3 cluster variable and sample (C7, C8, F01, F02); `d_centraliz` (C9, F03); ρ > 1 in Table 4 (C10, S2-5); construction risks (F06); `d_mission` missing → 0 (C4, sensitivity S23 only); labels and copy slips (C11–C13, C19, F07).

## 3. Estimands
**Notation (Table 2 col 4).** P(primary_i = 1) = Λ(x_i′β), with β₁ = `_b[d_birth]`, β₂ = `_b[d_age_prim_bef]`, β₃ = `_b[d_birth_bef_indep]`. Pre_i = `d_age_prim_bef` (turned 13 before independence). Estimation sample E: the published col 4 sample (N = 5,077,010). E_BR = {i ∈ E : `d_birth`_i = 1}.
- **H1-OR:** β₁. **H2-OR:** β₃. **H1-P:** β₁ and θ_pre = β₁ + β₃.
- **Counterfactual predictions.** For each i, all other regressors (including `age` and `i_age_age`) at their observed values, write p_i(b, c) = Λ(x_i′β with `d_birth` = b, `d_age_prim_bef` = c, `d_birth_bef_indep` = b·c).
- **Cohort-specific birth-region gap (H2-Pd, H2-RRR).** For each cohort group c ∈ {pre, post}, with i ranging over E with Pre_i = c, its own value of `d_age_prim_bef` kept:
  - AME_c = mean_i [p_i(1, Pre_i) − p_i(0, Pre_i)], unweighted;
  - RR_c = mean_i p_i(1, Pre_i) / mean_i p_i(0, Pre_i) (marginal standardisation).
  - **H2-Pd:** ΔAME = AME_pre − AME_post (pp). **H2-RRR:** ln RRR = ln RR_pre − ln RR_post.
  - **Label.** These are **realised cohort-specific contrasts**: each gap is averaged over its own cohort's covariate distribution. A difference between them combines a difference in the conditional gap with a difference in cohort composition. This is the target the card tests, because the authors' sentence compares the gap as it existed in each period. The composition-free version (both gaps averaged over one common distribution) is sensitivity S11.
- **H2-lit (literal comparison).** Over E_BR: RR_lit = mean_i p_i(1, 1) / mean_i p_i(1, 0); the estimand is **ln RR_lit**. Pre and post predictions are made for the same individuals, so there is no compositional difference; the contrast holds age at census fixed, as the published model does (§10 item 6). Its log-odds counterpart is β₂ + β₃.
- These are population-averaged statistics over the published estimation sample, conditional on its covariate distribution. Inference treats the covariate distribution as fixed and propagates the sampling variance of β̂ (§4A). The quality of that approximation is not assumed; it is checked by S12.

**Table 5 col 4.** P(d_birth_r = 1) = Λ(β·d_mission_r + z_r′γ + country FE), with the printed controls: lat, lon, coast, river, meanalt, tsi, meantemp (geographic); centralization, agricintensity, d_settlement, hierarchy, pop1800, d_slavery (pre-colonial); d_capital (A' alignment, `repro_original/code/run_t5_Aprime.do`). Unit: Murdock ethnic region.
- **H3-OR, H3-P:** β, the conditional log-odds coefficient on mission presence. Firth targets the same β as ML; it removes the O(1/n) bias and gives finite estimates under separation.
- **Discrete effect of mission presence (reported only).** From the FLIC fit (Puhr et al. 2017): mean over the 64 regions of p̂_r(d_mission = 1) − p̂_r(d_mission = 0), all other regressors at observed values. It decides nothing.

The original and new estimands coincide for H1-OR, H1-P, H2-OR, H3-OR and H3-P. H2-Pd, H2-lit and H2-RRR are probability-scale counterparts that A4c requires for probability wording; they are not `different-estimand` rows, because the authors state these claims on the probability scale.

## 4. Primary analyses

### A. Primary analysis for H1 and H2 (rows H1-OR, H1-P, H2-OR, H2-Pd, H2-lit, H2-RRR). Script `modern/01_t2_inference.do` (Stata)
- **Data:** `D:\Data\ReplicateMe\P23_MBF\original\ld\1_ipumsi_africa_birth_leaders_micro_geo_200527_final.dta`, loading only `cntry_code id_birth d_primary d_birth_all d_age_prim_bef age i_age_age d_female d_christian rural tse_r railway_density count_tribe slave_density d_mission d_capital dist_cap d_western`.
- **Model:** as published and as in `compare/s5_checks/s5_t2_wildboot.do`: `gen d_birth = d_birth_all`; `gen d_birth_bef_indep = d_age_prim_bef*d_birth`; `keep if d_birth_bef_indep < .`; `logit d_primary d_birth d_birth_bef_indep d_age_prim_bef age i_age_age d_female d_christian rural tse_r railway_density count_tribe slave_density d_mission d_capital dist_cap d_western i.cntry_code, vce(cluster id_birth)`.
- **Precondition (before any inference):** β₁ = 0.3802291, β₃ = 0.2809717, β₂ = 0.0207078; CR1 SEs 0.1116197 and 0.1269793 for β₁ and β₃; N = 5,077,010; 624 clusters; all to 1e-6. The analytic gradients g (below) agree with central finite differences (step 1e-5) to 1e-6 relative. If not met, the script stops, and every Table 2 row is not-testable.
- **Clustering.** By `id_birth`, the birth region. Birth Region is assigned at this level (it is constant within `id_birth`), so clustering at the assignment level is the design-based choice (Abadie, Athey, Imbens and Wooldridge 2023, *QJE*). Ethnic-group and country clustering are sensitivities S2 and S3.
- **Six hypotheses (Family M).** h1: β₁ = 0; h2: β₃ = 0; h3: β₁ + β₃ = 0; h4: ΔAME = 0; h5: ln RRR = 0; h6: ln RR_lit = 0. For θ ∈ {ΔAME, ln RRR, ln RR_lit}, θ̂ and its analytic gradient g = ∂θ/∂β at β̂ are computed in Mata (from the p_i and their derivatives p(1 − p)x). The hypothesis θ = r is tested in its first-order form g′β = g′β̂ − θ̂ + r. Coefficient hypotheses use g = the unit or sum vector.
- **Test: wild cluster restricted score bootstrap** (Kline–Santos), `boottest` (version recorded in `modern/env_stata_ado.txt`; ado path `D:\Data\ReplicateMe\P23_MBF\compare\s5\ado\plus`), with clusters `id_birth`, `reps(9999)`, `weight(webb)`, `ptype(symmetric)`, null imposed (the default after ML; `nonull` not specified), `seed(20261011)`. The seed is reset before every call, so every call uses the same matrix of Webb draws (common draws across hypotheses and across null values). Write p_h(r) for the bootstrap p-value of hypothesis h at null value r.
- **CI by explicit test inversion.** `boottest` does not construct confidence sets after `logit`, so the card inverts the test itself. For each h, with α* = 0.05/6 and s_h = √(g′V̂g), the CR1 SE of the hypothesis (used only to scale the grid):
  1. **Evaluation set.** Evaluate p_h at r = 0, at r = r̂_h (the estimate), at the grid r̂_h ± k·s_h/2 for k = 1, …, 24, at the midpoints r̂_h ± (k − ½)·s_h/2 for k = 1, …, 24 (so the grid step is s_h/4), and, for h5 and h6, at the null-band endpoints r = ±0.5·ln(1.32). All evaluated points, including 0, are sorted into one evaluation set. A point is *accepted* if p_h(r) ≥ α* and *rejected* otherwise.
  2. **Endpoints.** Between each adjacent accepted/rejected pair in the sorted set, bisect until the bracket is shorter than 10⁻³·s_h; the endpoint is the last accepted point. If 30 iterations do not achieve this, that endpoint is **unresolved**.
  3. **Tails.** If the outermost point on a side is accepted, that side is extended to k = 48 with the same step s_h/4. If the outermost point is still accepted, that side is **unresolved**: it is reported as "accepted to at least r̂_h ± 24·s_h", never as ±∞. The card does not claim that any confidence set is unbounded.
  4. **The confidence set** is, by definition, the union of the accepted segments returned by steps 1–3. Segments or gaps narrower than the step s_h/4 are not searched for (§10 item 16). A set of more than one segment is reported as disjoint.
  5. **Consistency with p_h(0).** Because 0 is a point of the evaluation set and every endpoint is an accepted point, the set contains 0 if and only if p_h(0) ≥ α*. No endpoint is ever moved or set to 0. The script checks this equivalence; a violation (possible only if `boottest` is not deterministic across calls with the same seed) triggers one rerun of that hypothesis's inversion; if the violation persists, the confidence set of that hypothesis is **unsupported**. Significance decisions always use p_h(0).
  6. **Deciding the credible-null condition (h5, h6).** "The set lies inside the open band (−0.5·ln(1.32), +0.5·ln(1.32))" is decided as follows, in order: (a) **not inside** if any accepted evaluated point (including r̂_h, the band endpoints of step 1 and every tail point) lies at or beyond ±0.5·ln(1.32); (b) **inside** if every endpoint and both tails are resolved and every segment lies strictly inside the band; (c) otherwise **undecidable**, and the confidence set is unsupported for the credible-null decision.
  7. For h4–h6, the CI for θ is the set for r mapped one to one (θ = r).
- **Restricted fits.** `boottest` refits the model under each null. The refits use the estimation command's ML settings with `tolerance(1e-8)` and `ltolerance(1e-10)`.
- **Each test yields:** the unadjusted p = p_h(0), the Bonferroni-adjusted p = min(1, 6·p_h(0)), and the 1 − 0.05/6 = 99.17% Bonferroni confidence set.
- **Monte Carlo precision.** For each verdict-relevant bootstrap p, MC SE = √(p(1 − p)/B). If p_h(0) for any h lies within 2 MC SE of α* or of 0.05, or p_h(±0.5·ln(1.32)) for h5 or h6 lies within 2 MC SE of α*, all six tests (with their inversions) are rerun with `reps(99999)`, same seed; the 99,999-draw results are final.
- **Failure and recovery (no fallback inference).** Analytic CR1 is the inference being challenged and is never substituted; it is always reported as sensitivity S1.
  - **Failure** of a call means boottest errors, returns a non-finite p, or a restricted refit does not converge. A call whose restricted refit has not converged is a failure even if it returns a finite p.
  - **Prespecified numerical recovery**, in order, for the failed call only, each step logged in `modern/DEVIATIONS.md`: (R1) the restricted refit is rerun with `difficult`, `iterate(1000)` and start values at β̂; (R2) the call is rerun with boottest's `matsizegb()` raised to 32; (R3) for an inversion, the grid step is halved and the range doubled.
  - **After recovery,** a quantity that is still unavailable is unsupported. A verdict row that needs an unsupported quantity is **not-testable** (§8 row 0). The quantities each row needs are: p_h(0) for every row; for H2-lit and H2-RRR also a decided credible-null condition (step 6 (a) or (b)); the condition is undecided if the confidence set is unsupported (step 5) or the condition is undecidable (step 6 (c)). The other confidence sets are reported only, and their failure changes no verdict.
- **Leverage and influence diagnostics (reported; never verdict-determining).**
  - Cluster sizes: minimum, median and maximum; the 29 treated clusters' share of N; the largest treated cluster's share of treated observations.
  - Concentration: treated clusters and treated observations by country (with Ghana's share).
  - Cluster influence: the one-step leave-cluster-out change Δ_g = −Ĥ⁻¹s_g(β̂) (the cluster's score contribution), mapped through g to β₁, β₃, β₁ + β₃, ΔAME, ln RRR and ln RR_lit. Report the ten most influential clusters for each, their treatment status and country, and the largest |Δ_g| relative to the CR1 SE.
  - Exact leave-one-treated-cluster-out re-estimation (29 runs; S13).
- **Reported for each test:** the bootstrap p, its MC SE, the confidence set, the number of treated clusters (29 expected), the CR1 p, and for the probability statistics θ̂, AME_pre, AME_post, RR_pre, RR_post, RR_lit and the predicted means behind them.

### B. Primary analysis for H3 (rows H3-OR, H3-P). Script `modern/02_t5_firth.R` (R)
- **Data:** `D:\Data\ReplicateMe\P23_MBF\original\ld\1_murdockanddbirth_final.dta` (open), read with `haven::read_dta`.
- **Sample:** the 64 regions of the printed col 4 (A'): complete cases on all model variables, then dropping regions in countries where `d_birth` is constant (Stata's perfect-prediction drops).
- **Precondition:** on that sample an ML logit (`glm`, binomial) with the printed specification gives N = 64, 15 events and β = 9.099 to 1e-3. If not, the script reads the Stata `e(sample)` indicator exported by `modern/02a_t5_sample.do` (region identifiers only, open data) and rechecks; if that also fails, H3-OR and H3-P are not-testable.
- **Estimator:** `logistf::logistf(d_birth ~ d_mission + lat + lon + coast + river + meanalt + tsi + meantemp + centralization + agricintensity + d_settlement + hierarchy + pop1800 + d_slavery + d_capital + factor(iso2), firth = TRUE, pl = TRUE, control = logistf.control(maxit = 1000), plcontrol = logistpl.control(maxit = 1000))` (logistf version recorded in `modern/sessionInfo.txt`). Country dummies with no variation in the sample are omitted.
- **Inference:** the penalised likelihood-ratio test of β = 0 (logistf's `prob` with `pl = TRUE`) and the 95% profile penalised-likelihood CI. The CI inverts the same test, so the two are compatible. Family R has one test (H3-OR and H3-P share it), so no multiplicity adjustment.
- **Dependence assumption.** The PL test treats regions as independent conditional on the regressors and country fixed effects. Spatial dependence among neighbouring regions is not modelled (§10 item 11).
- **Failure and recovery (no fallback inference).** The Wald form is the sparse-data inference that Firth's profile likelihood replaces and is never substituted; the Wald SE is reported only.
  - **Prespecified numerical recovery**, in order, each step logged in DEVIATIONS.md: (R1) if the fit does not converge (`iter` at `maxit`, or non-finite β), refit with `maxit = 10000` and `maxstep` halved from the default; (R2) if a profile bound is NA or `plcontrol` iterations are exhausted, rerun the profile for `d_mission` only with `logistpl.control(maxit = 10000)` and `maxstep` halved.
  - **Persistent nonconvergence is unsupported.** After recovery, a fit or profile that has not converged is unsupported even if it returns finite numbers. Non-convergence means: for the full fit or the restricted fit under β = 0, `iter` at `maxit` or logistf's convergence criterion not met; for a profile bound, the `plcontrol` iterations exhausted for that bound. A non-converged full fit makes β and the PLR p unsupported; a non-converged restricted fit makes the PLR p unsupported; a non-converged profile makes that CI bound unsupported.
  - **After recovery:** if β or the PLR p is unavailable or unsupported, H3-OR and H3-P are not-testable. If either PL CI bound is unavailable or unsupported, H3-OR is not-testable (its credible-null rule needs both bounds), and H3-P is decided on the PLR p alone.
- **Reported:** β, the PL CI, the PLR p, the Wald SE (report only); a plot of the profile penalised log-likelihood for β; the ML estimate on the same sample (benchmark); the number of events and parameters; the FLIC discrete effect of §3 with its 95% percentile CI from a bootstrap of regions resampled with replacement within country strata (B = 1,999, seed 20261011; failed fits counted and reported; reported only).

## 5. Admissible sensitivities (exhaustive; reported, never verdict-determining)
**Table 2 (H1, H2):**
1. Analytic CR1 by `id_birth` (published inference): all six tests, the probability statistics by the delta method.
2. Clustering on ethnic group (`tribe_co_1`): CR1 and the primary score bootstrap.
3. Score bootstrap clustered by country (11 clusters): diagnostic only.
4. Rademacher weights in place of Webb.
5. Wild cluster **unrestricted** score bootstrap (`nonull`), all six tests. With few treated clusters WCR tends to under-reject and WCU to over-reject (MacKinnon and Webb 2017, 2018); the two are reported side by side.
6. IPUMS person weights: `[pw=perwt]` in the fit, and perwt-weighted means in every probability statistic, with the primary inference.
7. Religion fixed (C14): a true Muslim dummy and a missing-religion dummy added.
8. **Leave-one-country-out** (11 runs, A4d): every primary statistic with the primary inference. Report the range, the share of runs meeting each row's confirm condition (A8 enumeration), and the number of drops that would change the verdict category.
9. Possible mediators and downstream controls removed: (a) without `d_mission` and `d_capital` (C17); (b) without the census-time `rural` and `d_christian` (F08); (c) both.
10. Linear probability model with the same regressors: the coefficients on `d_birth`, `d_birth_bef_indep`, their sum, and `d_age_prim_bef` + `d_birth_bef_indep`, with boottest WCR (OLS, Webb, B = 9,999).
11. **Standardised probability contrasts** (Codex change 7): ΔAME and ln RRR with both cohort gaps averaged over one common distribution, with `d_age_prim_bef` set to 1 and to 0 for everyone: (a) over all of E; (b) over common support, the individuals whose birth year lies in the range observed in both cohort groups (pooled over countries). Primary inference.
12. **Validation of the linearised inference** (Codex change 7), for ΔAME, ln RRR and ln RR_lit: (a) a one-step score-perturbation bootstrap, β*_b = β̂ + Ĥ⁻¹Σ_g w_gb s_g(β̂) with the primary Webb draws, θ computed nonlinearly at each β*_b, reporting the 99.17% percentile interval and the share of draws with θ* ≤ 0; (b) a pairs cluster bootstrap (624 clusters resampled with replacement, B = 399, seed 20261011, full logit re-estimation, θ computed nonlinearly), 99.17% percentile interval. Disagreements with the primary sign or significance are flagged in `results.md` and §10.
13. Exact leave-one-treated-cluster-out (29 runs): every primary point estimate; range and the cluster behind each extreme.
14. Diagnostic: the raw within-birth-region ratio P̄(primary | BR = 1, pre) / P̄(primary | BR = 1, post), with no model.
15. Table 3 cols 3–4 corrected to all leaders (C8) and without `d_centraliz` (C9), with the primary inference (non-headline; related evidence for H2).

**Table 5 (H3):**

16. ML logit on the 64 regions with robust SEs (published inference; benchmark).
17. Firth on the 64 regions with the printed col 1, col 2 and col 3 specifications.
18. Firth with the surviving-code col 4 specification (without `d_capital`; C2).
19. Bayesian logit, an alternative separation remedy (Gelman, Jakulin, Pittau and Su 2008), frozen as `arm::bayesglm(..., family = binomial(link = "logit"), prior.mean = 0, prior.scale = 2.5, prior.df = 1, prior.mean.for.intercept = 0, prior.scale.for.intercept = 10, prior.df.for.intercept = 1, scaled = TRUE)` (arm's default rescaling of inputs); posterior mode and SE of β.
20. **Firth on all complete-case regions** (124 regions, 17 events; the regions dropped by perfect prediction kept). Changed population (A4d).
21. Linear probability model with HC3 SEs, on the 64 regions and on the 124.
22. Leave-one-country-out with Firth (9 countries with an event, A4d): range and share as in item 8.
23. `d_mission` missing treated as missing rather than 0 (C4): Firth on the resulting complete cases. Changed population (A4d).
24. Regions restricted to the 11 countries of Table 1 (F05): Firth. Changed population (A4d).

## 6. Fixed choices
- **Samples and missing data:** listwise as published (Table 2; Table 5 printed col 4). No imputation. No weights in any primary analysis.
- **Multiplicity families.**
  - **Family M (Table 2): six tests**: β₁, β₃, β₁ + β₃, ΔAME, ln RRR, ln RR_lit. **Bonferroni throughout**: adjusted p = min(1, 6p); confidence sets at 1 − 0.05/6.
  - **Family R (Table 5): one test**: β (mission). 95% CI; no adjustment.
- **One adjustment, one interval.** Significance (A3 condition 2) is "adj p < .05", which is p_h(0) < 0.05/6, which is "the Bonferroni confidence set excludes 0". These are the same event by construction (§4A step 5; §4B for Family R). The v1 Holm rule is withdrawn, so no Holm–Bonferroni discordance can arise.
- **Boundary rules.**
  - p = 0.05 (adjusted) is not significant; p_h(0) = α* is not significant.
  - |b| = 0.5|b₀| meets the floor.
  - **Credible null (A4a) is strict:** the confidence set must lie inside the open band (−0.5|b₀|, +0.5|b₀|). An endpoint exactly at ±0.5|b₀| is not inside.
  - An estimate of exactly 0, or a CI endpoint exactly at 0, counts as "sign not established" and "CI includes 0".
  - A disjoint confidence set is inside a null band only if every segment lies strictly inside it. A set with an unresolved endpoint or tail is decided by §4A step 6: not inside if an accepted point lies at or beyond the band; otherwise undecidable, and the row is not-testable (§8).
- **Seeds:** 20261011 throughout. Scripts: `modern/01_t2_inference.do`, `02_t5_firth.R` (and `02a_t5_sample.do` if needed), `03_sensitivities_t2.do`, `04_sensitivities_t5.R`, `05_verdicts.R`.
- Verdict comparisons use unrounded values; results are reported to 3 dp (4 dp for p-values).

## 7. Margins and their provenance
| Row | Confirm condition | Provenance |
|---|---|---|
| H1-OR | adj p(β₁) < .05 (point .3802 ≥ 0.19 fixed) | A3 and A4b |
| H1-P | adj p(β₁) < .05 **and** adj p(β₁ + β₃) < .05 (both points positive, fixed) | A8 comparative default; "irrespective of the age cohort" read as a conjunction over the two cohort groups the model distinguishes |
| H2-OR | adj p(β₃) < .05 (point .2810 ≥ 0.14 fixed) | A3 and A4b |
| H2-Pd | ΔAME > 0, adj p < .05 | A8 comparative default |
| H2-lit | ln RR_lit > 0, adj p < .05, ln RR_lit ≥ 0.5·ln(1.32) | A3 (50% of b₀ = ln(1.32)) and A4a; A4c for the scale |
| H2-RRR | ln RRR > 0, adj p < .05, ln RRR ≥ 0.5·ln(1.32) | A3 (50% of b₀ = ln(1.32)) and A4a; A4c for the scale |
| H3-OR | β > 0, p < .05, β ≥ 4.55 | A3 (50% of 9.10) and A4a |
| H3-P | β > 0, p < .05 | A8 comparative default (no stated probability magnitude) |

- **Credible null (A4a, strict).** H2-lit and H2-RRR: the 99.17% Bonferroni confidence set inside (−0.5·ln(1.32), +0.5·ln(1.32)), decided by §4A step 6. H3-OR: the 95% PL CI inside (−4.55, 4.55). A4b makes the credible null unreachable for H1-OR, H1-P and H2-OR.
- **No null band for H2-Pd and H3-P.** A8's comparative ">" default has no null band, and A8a applies only to point bands for quantities on [0, 1], which these rows are not. The authors state no probability-scale magnitude, so A4a has no b₀ to apply. This follows from the protocol and the wording, not from a card choice.
- No ceilings.
- **Plausibility flag** (A8; not verdict-determining): |estimate| > 1.5|b₀| on a magnitude row with a new point estimate (H2-lit and H2-RRR above 1.5·ln(1.32), displayed 0.4164; H3-OR above 1.5 × 9.10 = 13.65). No other flag is defined; the v1 50-point AME flag is withdrawn.

**Disclosure.** S2 and S5 numbers seen before this card, all bearing on the verdicts:
- **Table 2 col 4 (published model):** β₁ 0.3802 (CR1 0.1116, p .00066); β₃ 0.2810 (0.1270, p .027); β₂ 0.0207 (0.0506; printed .02); β₁ + β₃ 0.6612 (0.1589, p .00003); hence β₂ + β₃ ≈ 0.302 (no SE computed); 29 treated clusters.
- **Probability scale:** AME_pre 0.0884, AME_post 0.0675 (S5 `margins`), mean of the outcome 0.4379; these imply ΔAME ≈ 0.021. RR_pre, RR_post, ln RRR and RR_lit have not been computed.
- **Score bootstrap (Webb, 999 reps, same seed):** β₁ p .005; β₃ p .094; β₁ + β₃ not returned.
- **Ethnic clustering (151):** SEs 0.1137 (p .0008), 0.1305 (p .031), 0.1659 for the sum. **perwt:** 0.3804 (0.1058), 0.2751 (0.1257). **Religion fixed:** 0.3799, 0.2809.
- **Leave-one-country-out:** β₁ 0.239 (drop TZA) to 0.473 (drop GHA), all p < .01; β₃ −0.096 (0.166) without Ghana to 0.341 (drop MWI), 9 of 11 p < .05 (Kenya p .051); β₁ + β₃ 0.376 without Ghana.
- **Table 3 (non-headline):** elite cols 3–4 without `d_centraliz`: β₁ .359/.360, β₃ .371/.379. All leaders (pair B): β₁ .39/.39, β₃ .27/.29.
- **Table 5 col 4:** surviving code 7.855 (3.309), p .018; A' 9.099 (4.268), p .033; ML `dydx` derivative 0.954 (0.410), not a discrete change; col 1 spec on the 64 regions 1.749 (0.818), p .033; col 2 spec 3.033 (1.569), p .053; LPM 0.336 (0.194), p .091; LPM on 124 regions 0.133 (0.087), p .128; **Firth on the 64 regions 2.268 (Wald SE 1.494), Wald p .129**; Firth on 124 regions 2.162 (1.343), p .107; leave-one-country-out: complete separation in 3 of 9 runs (b > 800), p > .05 in 4 of the other 6, p < .05 only without MWI (8.18) or SEN (8.52).

What these numbers imply under the rules of this card, stated before the primary is run:
- **H1-OR** is at the margin. The Bonferroni threshold for β₁ is 0.05/6 = .0083; the S5 bootstrap p was .005 at 999 draws (MC SE about .002), so the 9,999-draw run decides it, with escalation likely. Under v1's Holm rule the first-step threshold was .01. The tightening follows from two required changes (a sixth test for the literal reading, change 3; Bonferroni throughout, change 4), not from the result, but the author knew the S5 p when writing them.
- **H2-OR** is expected to be weakened (unadjusted bootstrap p .094 at 999 draws).
- **H3-OR** is expected to fall short of the 4.55 floor; the S5 Wald interval (about −0.66 to 5.20) is not inside (−4.55, 4.55), so a credible-null overturn is not expected. The PL CI has not been computed.
- **H3-P** is expected to be weakened (Wald p .129); the PLR p has not been computed.
- **H2-Pd, H2-lit and H2-RRR** have no S5 inference.

The primary estimators (score bootstrap for Table 2, Firth for Table 5) are the ones S5 used as diagnostics; they were chosen after their S5 results were seen (§10 items 1–2). Not yet run: the score bootstrap at 9,999 draws, any CI inversion, any probability-scale inference, the Firth PL CI and PLR test, FLIC, the Bayesian logit, and sensitivities 3, 4, 5, 8 (probability statistics), 9–14, 17, 19, 21 (on 64), 22 (with Firth), 23 and 24. All margins are protocol defaults; the card author chose none.

## 8. Verdict tables (primary analyses only; checked in order; the first rule that applies decides; exhaustive)
"Unsupported" means a quantity that the row needs is unavailable after the recovery steps of §4.

**H1-OR (claim-level verdict for H1) and H2-OR (claim-level verdict for H2)** (A4b ladder, inference-only; Family M). The point estimates equal the published-code values (.3802, .2810), both positive and above their floors:
| # | Condition | Verdict |
|---|---|---|
| 0 | the precondition fails, or p_h(0) is unsupported | not-testable |
| 1 | adj p < .05 | confirmed |
| 2 | adj p ≥ .05, unadjusted p < .05 | qualified (inference-fragile) |
| 3 | unadjusted p ≥ .05 | weakened |

"Overturned" is unreachable (A4b).

**H1-P** (A4b ladder, conjunction over β₁ and β₁ + β₃; Family M; both points positive, fixed):
| # | Condition | Verdict |
|---|---|---|
| 0 | the precondition fails, or either p is unsupported | not-testable |
| 1 | both adj p < .05 | confirmed |
| 2 | both unadjusted p < .05, at least one adj p ≥ .05 | qualified (inference-fragile) |
| 3 | at least one unadjusted p ≥ .05 | weakened (the gap is not established for every cohort group) |

"Overturned" is unreachable (A4b).

**H2-Pd** (comparative ">", new statistic; Family M):
| # | Condition | Verdict |
|---|---|---|
| 0 | the precondition fails, or p is unsupported | not-testable |
| 1 | ΔAME > 0, adj p < .05 | confirmed |
| 2 | ΔAME < 0, adj p < .05 | overturned (reversed: the realised probability gap was larger after independence) |
| 3 | ΔAME > 0, adj p ≥ .05 | weakened |
| 4 | all remaining cases (ΔAME ≤ 0 with adj p ≥ .05, or ΔAME = 0) | weakened (direction lost) |

No credible-null row (§7).

**H2-lit (literal reading) and H2-RRR (reconstructed reading)** (A3/A4, new statistics; Family M; b₀ = ln(1.32), floor and band half-width 0.5·ln(1.32), all exact; θ = ln RR_lit or ln RRR). Each row is decided separately; H2-RRR cannot change the H2-lit verdict:
| # | Condition | Verdict |
|---|---|---|
| 0 | the precondition fails, or p is unsupported | not-testable |
| 1 | θ̂ < 0, adj p < .05 | overturned (reversed) |
| 2 | the credible-null condition is undecided (confidence set unsupported, §4A step 5, or undecidable, step 6 (c)) | not-testable |
| 3 | 99.17% confidence set inside (−0.5·ln(1.32), +0.5·ln(1.32)) (§4A step 6 (b)) | overturned (credible null) |
| 4 | θ̂ > 0, adj p < .05, θ̂ ≥ 0.5·ln(1.32) | confirmed |
| 5 | θ̂ > 0, adj p < .05, θ̂ < 0.5·ln(1.32) | qualified (magnitude below the floor) |
| 6 | θ̂ > 0, adj p ≥ .05 | weakened |
| 7 | all remaining cases (θ̂ ≤ 0 with adj p ≥ .05, or θ̂ = 0) | weakened (direction lost) |

Row 2 never fires when row 4 would apply: θ̂ is accepted (its p is 1 by construction) and θ̂ ≥ 0.5·ln(1.32) lies outside the open band, so step 6 (a) decides "not inside".

**H3-OR (claim-level verdict for H3)** (A3/A4, Firth; Family R; b₀ = 9.10, floor 4.55):
| # | Condition | Verdict |
|---|---|---|
| 0 | the precondition fails; or β, the PLR p or either PL CI bound is unsupported | not-testable |
| 1 | β < 0, p < .05 | overturned (reversed) |
| 2 | 95% PL CI inside (−4.55, 4.55) | overturned (credible null) |
| 3 | β > 0, p < .05, β ≥ 4.55 | confirmed |
| 4 | β > 0, p < .05, β < 4.55 | qualified (magnitude below the floor) |
| 5 | β > 0, p ≥ .05 | weakened |
| 6 | all remaining cases (β ≤ 0 with p ≥ .05, or β = 0) | weakened (direction lost) |

**H3-P** (comparative ">", Firth; Family R):
| # | Condition | Verdict |
|---|---|---|
| 0 | the precondition fails, or β or the PLR p is unsupported | not-testable |
| 1 | β > 0, p < .05 | confirmed |
| 2 | β < 0, p < .05 | overturned (reversed) |
| 3 | β > 0, p ≥ .05 | weakened |
| 4 | all remaining cases (β ≤ 0 with p ≥ .05, or β = 0) | weakened (direction lost) |

No credible-null row (§7).

**H3-causal and the abstract sentences in §1:** not-testable.

**Reporting.** No summary rule combines rows.
1. **Not-testable causal claims first.** The report opens with H3-causal and the three abstract sentences, stating that the card cannot assess the paper's central causal interpretation.
2. **Claim-level verdicts:** H1 = H1-OR, H2 = H2-OR, H3 = H3-OR, each from its primary analysis.
3. **Row verdicts,** listed separately under two headings (A4c): odds-ratio rows (H1-OR, H2-OR, H3-OR) and probability rows (H1-P, H2-Pd, H2-lit, H2-RRR, H3-P). H2-RRR is labelled "reconstructed interpretation".
4. **Coverage:** verdict rows assessed; rows not-testable; claims not-testable.
5. Sensitivities and diagnostics are listed by item beside the verdicts. None changes a verdict.

## 9. Codex review notes and responses
**Codex v1 review** (reviews/P23_MBF_codex_S6card.md): approve-with-changes, 8 required changes and 2 optional suggestions. Responses in v2:
1. **Bootstrap CI inversion.** §4A now specifies the inversion algorithm explicitly: a grid of ±24 half-SE steps with extension to ±48, bisection to 10⁻³ SE, the confidence set as the union of accepted segments (disjoint sets reported; tail and endpoint handling revised in v3, below), explicit evaluation at 0 and at the null-band endpoints, a consistency rule tying the set to p_h(0), ML tolerances for the restricted refits, and common draws (seed reset before every call). The v1 reliance on `level(99)` is removed.
2. **No verdict-determining CR1/Wald fallbacks.** Both are deleted (§4A, §4B). Prespecified numerical recovery steps (R1–R3 for Table 2; R1–R2 for Table 5) are logged when used. After recovery, any row that needs an unavailable quantity is not-testable; §4A and §4B list which quantities each row needs. CR1 and the Wald SE are reported only (S1; §4B).
3. **H2's economic target.** The two readings are separate rows (§1, §3): **H2-lit** tests the stated comparison (within birth regions, pre vs post cohorts; ln RR_lit, log-odds counterpart β₂ + β₃), and **H2-RRR** is labelled a reconstructed interpretation that cannot overturn the literal reading (§1, §8). Each has one primary statistic, from primary analysis A. The raw ratio is diagnostic S14.
4. **Verdict rules reconciled with A3/A4/A8.** Bonferroni is used throughout Family M (§6), and confidence sets come from inverting the same bootstrap test, so "adj p < .05" and "the adjusted interval excludes 0" are the same event. The Holm rule is withdrawn. The null band is strict and open, as A4a states (§6, §7, §8). Default floors are kept; there are no ceilings; A4b's unreachable overturn is stated on each A4b table. §7 records that A8/A8a supply no band for the comparative rows.
5. **No "weakest row" verdict.** The rule is deleted. Each claim has one primary analysis (§0), and its claim-level verdict is the row that tests the frozen headline number (H1-OR, H2-OR, H3-OR). Odds-ratio and probability rows are reported separately (A4c). The not-testable causal claims open the report (§8 Reporting).
6. **Leverage and influence diagnostics.** §4A adds cluster-size imbalance, treated-cluster concentration by country, one-step cluster influence on each tested quantity, and exact leave-one-treated-cluster-out (S13). Clustering by `id_birth` is justified as the assignment level. The 11-country bootstrap is kept (S3), and the unrestricted bootstrap (S5) is added because WCR itself can fail with few influential treated clusters. §2(a) no longer says that 29 treated clusters prove CR1 failure.
7. **Probability inference clarified and validated.** §3 labels the target as a realised cohort-specific contrast that combines gap and composition differences. S11 adds the common-distribution and common-support standardisations. S12 validates the linearised inference against a nonlinear one-step score bootstrap and a pairs cluster bootstrap. The v1 statement that the sample size makes curvature negligible is withdrawn.
8. **Binary-effect reporting.** §2(c) and the disclosure label 0.954 as a `dydx` derivative, not a discrete change. The FLIC effect is defined as the mean of p̂(mission = 1) − p̂(mission = 0) (§3, §4B). The 50-point flag is removed (§7).

Optional suggestions:
1. **Adopted.** The dependence assumption of Firth inference is stated (§4B), and the FLIC bootstrap resamples within country strata. The Bayesian prior and scaling are frozen (S19). The perwt standardisation is fixed (S6). Changed-population sensitivities remain non-voting (A4d).
2. **Adopted.** Under A9, v2 consolidates every change. After one compliance check, v3 is frozen, and anything unresolved goes to §10.

**Codex v2 compliance check** (reviews/P23_MBF_codex_S6card_v2.md): freeze-after-minor-edits, 4 edits. Responses in v3:
1. **Inconsistent endpoints.** The rule that set an endpoint to 0 is deleted. Zero is now a point of the sorted evaluation set and every endpoint is an accepted point, so the set contains 0 exactly when p_h(0) ≥ α*. A violation triggers one rerun; if it persists, the set is unsupported (§4A step 5).
2. **Truncation versus unboundedness; disjoint segments.** An accepted outermost point at k = 48 is now an unresolved tail, reported as "accepted to at least r̂ ± 24 s_h", never ±∞. Bisection that fails to converge leaves an endpoint unresolved. The grid step is halved to s_h/4 by fixed midpoints, and the confidence set is defined as what this frozen procedure returns. Step 6 decides the credible-null condition: not inside if any accepted point lies at or beyond the band; inside only if everything is resolved and strictly inside; otherwise undecidable, which makes H2-lit or H2-RRR not-testable (§8 row 2). The residual resolution limit is §10 item 16.
3. **Persistent nonconvergence in Table 5.** After recovery, a non-converged fit or profile is unsupported even with finite output, and the existing row rules then apply (§4B). The same holds for a Table 2 call with a non-converged restricted refit (§4A).
4. **Exact constants.** b₀ = ln(1.32), floor and band 0.5·ln(1.32), plausibility threshold 1.5·ln(1.32) are defined exactly in the status header, §1, §4A, §7 and §8; 0.2776, 0.1388 and 0.4164 are display values only.

## 10. Known limitations at freeze
1. **Estimator chosen after its S5 result.** Firth was the S5 diagnostic for Table 5, and its S5 estimate (2.27, Wald p .13) was seen before this card. Firth is the standard remedy for separation (Heinze and Schemper 2002), and the Bayesian alternative (S19) is reported, but the choice is not blind.
2. **Inference chosen after its S5 result.** The score bootstrap was the S5 diagnostic for Table 2 (interaction p .094 at 999 draws). The few-treated-cluster problem was identified from the design (29 of 624), not from the p-value, but the choice is not blind.
3. **Threshold tightened with S5 p known.** The sixth test and Bonferroni throughout move β₁'s threshold from .01 (Holm first step) to .0083, with the S5 bootstrap p at .005. H1-OR may be qualified rather than confirmed for this reason alone (§7 disclosure).
4. **Bootstrap validity is not guaranteed.** With 29 treated clusters, WCR can under-reject when treated clusters are few or influential (MacKinnon and Webb 2017, 2018). WCU (S5) and the influence diagnostics (§4A) bracket the problem; they do not resolve it.
5. **Table 5 rests on 64 regions and 15 events with about 23 parameters.** Firth gives finite estimates and removes first-order bias; its profile CIs are still approximate at this events-per-parameter ratio. The 64-region population is itself defined by ML perfect-prediction drops; the 124-region alternative (S20) changes the population and cannot vote (A4d).
6. **H2-lit holds age at census fixed** while switching the cohort indicator, as the published model does. Cohort and age are related, so the contrast relies on cross-country variation in independence dates and partly extrapolates beyond common support; S11(b) and S14 are the only checks.
7. **Two readings of "32% higher".** The literal reading is decided on ln RR_lit and the reconstructed reading on ln RRR. The two may disagree, and the card does not choose between them; the claim-level H2 verdict rests on H2-OR.
8. **Linearised probability-scale inference.** H2-Pd, H2-lit and H2-RRR test the first-order form of θ = r and treat the covariate distribution as fixed. S12 checks this against nonlinear bootstraps but does not vote.
9. **No credible null for H2-Pd and H3-P.** The authors give no probability-scale number, so A4a cannot apply; these rows can be confirmed, reversed or weakened, but not overturned as a null.
10. **Ghana.** The interaction's dependence on one country (C6) enters only through S8 and the concentration diagnostics, because leave-one-country-out changes the population (A4d).
11. **Spatial dependence in Table 5.** The PL inference treats regions as independent given the regressors and country fixed effects. Neighbouring Murdock regions may share unmodelled shocks; with 9 countries, no cluster-robust alternative is credible.
12. **Unaddressed construction risks.** The `m:m` merge, the ethnicity-merge drops and the `yrschool>=90` filter (F06) are taken as given; the raw-to-analysis pipeline is not re-run. `d_mission` missing → 0 (C4) enters only through S23.
13. **Causal claims.** H3-causal and the abstract's "created by", "account for much of the variation" and "favouritism … endogenous" remain not-testable, so the card cannot assess the paper's central causal interpretation.
14. **Table 4 ρ > 1** (C10) and the Table 3 defects (C7–C9) carry no headline row and are not re-estimated, except Table 3 as related evidence in S15.
15. **Computational cost.** Each null value requires a restricted refit on 5.08 million observations, so the inversion grid (about 100–200 evaluations per hypothesis, including midpoints, tail extension and bisection) is expensive. The grid is frozen and is not shortened for cost.
16. **Finite resolution of the bootstrap confidence sets.** The inversion searches a grid with step s_h/4 out to ±24 s_h. Accepted segments or rejected gaps narrower than s_h/4 can be missed, and acceptance beyond ±24 s_h is reported as an unresolved tail rather than established unboundedness. The confidence set is defined operationally by the frozen procedure (§4A steps 1–4), not as the exact inverted set.
17. **Undecidable credible null leads to not-testable.** If an H2-lit or H2-RRR confidence set has an unresolved endpoint or tail and every accepted point lies inside the band, the credible-null condition cannot be decided and the row is not-testable (§8 row 2), even if the other conditions would give a verdict. This is the price of not treating truncated sets as bounded.
18. **Nonconvergence makes rows not-testable rather than falling back.** In both tables, a quantity from a non-converged fit is unsupported after the prespecified recovery steps, even if finite (§4A, §4B). Rows can therefore be not-testable for numerical reasons alone; no alternative estimator or inference substitutes.
