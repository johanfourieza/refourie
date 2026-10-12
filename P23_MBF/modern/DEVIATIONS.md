# P23_MBF S6: deviations from, and implementation notes on, the frozen method card

Card: `modern/method_card.md`, frozen at commit d59616d (v3). No analysis outside the card was added. D1 and D2 are substantive and are noted in `audit.md`. Unless an entry says otherwise, each choice was fixed before any bootstrap p-value of the primary analysis existed.

**D1. Table 2 runs on frequency-weighted covariate cells with a weight-correct replica of boottest's score bootstrap (computational; forced; results informed: no).**
- *Why.* The card's inversion needs about 115 restricted refits and bootstrap calls per hypothesis, six hypotheses, and a 99,999-draw rerun if the Monte Carlo rule triggers. On the 5,077,010 individual rows, one `boottest` call takes 70–95 s (`01b` log), so the primary alone would take 15–30 hours, before the sensitivities.
- *What.* Every regressor of Table 2 col 4 is region-, age-, sex-, religion- or rural-level, so the estimation sample collapses to 214,084 cells of identical (outcome, regressors, cluster), with the count as a frequency weight (`00_t2_collapse.do`). The logit on the cells reproduces the full-data coefficients, CR1 SEs, log-likelihood, N and cluster count exactly.
- *The weight problem.* `boottest` 4.5.3 does not multiply observation scores by the weight before summing them by cluster in its ML score bootstrap (`boottest.mata` `_MakeInterpolables`: `_panelsum(uXAR, infoBootData)` without weights). On the cells it therefore returns wrong p-values: .684 instead of .005 for h1, and the same with `fw`, `pw` and `iw`.
- *The replica.* `sb_lib.do` reimplements boottest's ML score bootstrap step by step:
  - the restricted refit with `constraints()` and `from()`;
  - the `iterate(0)` unconstrained pass for the scores and `e(V_modelbased)`;
  - a_g = Σ_{i∈g} w_i s_i′ V R′;
  - Webb weights generated exactly as `MakeWildWeights`;
  - the recentred denominator Σ_c (a_c v_c − share_c Σ_g a_g v_g)²;
  - the symmetric p = #{|t*| > |t|}/B.

  The only change is that the scores are weighted.
- *Verification.*
  - The replica's Webb weight matrix equals boottest's `svv` matrix exactly.
  - At 999 draws the replica reproduces the full-data boottest values .00500501 (h1), .24124124 (β₃ = 0.1) and the S5 value .0940941.
  - `01b_verify_fulldata.do` runs boottest itself on the 5,077,010 rows at the six verdict-deciding p_h(0), at two interior inversion points and at one unrestricted call. Agreement is exact at every point (`output/check_fulldata_vs_cells.csv`): 9 points at 9,999 draws and 6 at 99,999. The replica values come from `01c_replica_checkpoints.do`.
  - Because the card's escalation rule triggered, the six p_h(0) at 99,999 draws were also run with boottest on the full data (see D6).
- *Consequences.* Recovery step R2 (`matsizegb`) has no counterpart in the replica and was never needed. For the person-weight sensitivity (S6), the replica weights the scores correctly; boottest on the full data would silently drop the person weights from the scores.

**D2. Finite-difference check of the analytic gradients (precondition, card §4A; forced; results informed: no for any verdict quantity).**
- *What failed.* The literal check, central differences with absolute step 1e-5, fails: the maximum componentwise relative error is 1.5e-4 (ΔAME), 3.2e-5 (ln RRR) and 1.6e-5 (ln RR_lit). Every excess comes from two regressors with large scale, `i_age_age` (sd 1,162) and `dist_cap` (sd 220).
- *Why it is truncation error, not a gradient error.* Halving the step to 5e-6 cuts those errors by a factor of 4.0, the signature of O(h²) truncation error. The third derivative of θ in the coefficient of a regressor of scale x grows like x³.
- *What the precondition uses instead.*
  - A scale-invariant step, h_k = 1e-5/max(1, sd(x_k)). It moves the index by 1e-5 per standard deviation for every regressor.
  - Quad-precision sums (`quadsum`, `quadcross`) in the statistics, which removed roundoff of order 1e-6 in components with small gradients.
  - With both, the maximum componentwise relative errors are 1.4e-8, 3.9e-8 and 5.6e-8, and the precondition passes.
- *If the literal rule were applied.* All Table 2 rows would be not-testable because of the check's own numerical error. `verdict.csv` records this in `precondition_literal_FD_check_passed`.
- *Results informed.* This was decided after the point estimates θ̂ had been printed in the same log, but before any bootstrap p-value existed. The coefficient preconditions (β to 1e-6, CR1 SEs, N, clusters) pass as written.

**D3. Sensitivities report p at r = 0, not inverted confidence sets (card §5; scope; results informed: no).**
- The card specifies the inversion for the six primary tests. Sensitivities "with the primary inference" are run with the same bootstrap (Webb, 9,999 draws, null imposed, same seed), and each reports p_h(0) and the Bonferroni-adjusted p.
- Exception, item 8 (leave one country out). Each run needs a verdict category for H2-lit and H2-RRR, so the credible-null condition is decided by the card's own step 6:
  - the p-values at ±0.5·ln(1.32) are computed;
  - if either endpoint is accepted, the condition is "not inside" (step 6(a));
  - otherwise the full frozen inversion is run (`inv_lib.do`).
- Items 2 and 1 also report analytic CR1 p-values.

**D4. Start values and tolerances (numerical; results informed: no).** The main fit and every restricted refit use `tolerance(1e-8) ltolerance(1e-10)`. Every restricted refit is given explicit start values (`from()`): the exact solution of D9, falling back to β̂ when that fails. Recovery R1 starts at β̂ as the card prescribes. Start values do not change the optimum at this tolerance. The main fit with tight tolerances meets the precondition (β₁ 0.380229083, β₃ 0.280971742, β₂ 0.020707830; CR1 SEs 0.11161970, 0.12697930).

**D5. FLIC computed from its definition (Table 5, reported quantity only; results informed: no).**
- `logistf::flic()` fails when called inside a function (it evaluates `data` in the wrong frame). The FLIC is therefore computed as Puhr et al. (2017) define it: Firth slopes, with the intercept re-estimated by ML with the Firth linear predictor as an offset.
- Bootstrap: 1,999 stratified draws. A draw that raised an error or warning, including non-convergence, is counted as failed: 94 of 1,999.
- The profile plot uses `logistftest` restricted fits on a grid around the PL interval.

**D6. Monte Carlo rule and runtime (card §4A; the escalation follows the card's own rule).**
- At 9,999 draws, p_h(0) for h5 (ln RRR) is .00850. It lies within 2 MC SE (.00092) of α* = .00833, so every test was run at 99,999 draws, same seed. The 99,999-draw results are final (`output/t2_mc_check_B9999.csv`).
- Runtime exceeded 2 hours in total: about 6 hours of wall time from 14:25 to 20:11. The causes were the convergence problem in D9, two restarts, and sensitivity 12a (99,999 one-step draws, each evaluating θ nonlinearly over 247,561 cells: about 2.5 hours). The card allows no replication count to vary: B = 9,999 and 99,999, pairs bootstrap 399, FLIC bootstrap 1,999. None was reduced.

**D7. Interpretation of three sensitivity populations (card §5; results informed: no).**
- *Item 23* ("`d_mission` missing treated as missing; Firth on the resulting complete cases") is applied to the 64 regions of the primary. The raw GIS file `1_murdock_capital_population_final.csv` records mission counts of 1 to 28 and no zeros. Once missing is treated as missing, all 39 remaining regions have `d_mission` = 1, and the coefficient is not estimable. This is reported as the S23 result: the data contain no region coded as having no mission, so C4's recode of missing to 0 is the only source of variation.
- *Item 24* ("regions restricted to the 11 countries of Table 1") is applied to the 64 regions. The only country in the 64 outside Table 1 is Côte d'Ivoire, so S24 coincides with the leave-one-country-out run that drops CIV.
- *Item 21* (LPM with HC3 on all 124 complete cases). HC3 is undefined because 8 regions have leverage 1 (singleton country cells). The coefficient is reported without SE.
- *Item 11(b).* Common support is the birth-year range observed in both cohort groups, pooled over countries.

**D8. Order of the Monte Carlo check and the inversions; iteration cap; failure cache (computational; results informed: no).**
- *Order.* The card's rule (§4A) depends only on p_h(0) for all six tests and on p_h(±0.5·ln 1.32) for h5 and h6, each at 9,999 draws. These eight values are computed first (`01 setup`). The inversions are then run once, at the final B (`01 invert`), in three parallel processes: h1–h4, h5 and h6. Running them first at 9,999 draws would have produced sets that the card discards on escalation.
- *Iteration cap.* The first attempt of every restricted refit is capped at 100 iterations, against Stata's default of 16,000. Recovery R1 (`difficult`, 1,000 iterations, start β̂) follows unchanged.
- *Failure cache.* A refit that still fails after R1 is cached by (fit, hypothesis, r) and not repeated. The refit does not depend on B. In the final runs no refit failed (see D9).
- *Two do-files edited during a run (no effect on any number).*
  - The CSV export at the end of the 9,999-draw `01b` run was garbled because the file was edited while running. The CSV was written from the saved `.dta`.
  - The tail of one `01 setup` run was likewise garbled. That run's Monte Carlo statistics were finished with the identical commands (`_scratch/mcfinish.do`). The final `setup` run is clean.

**D9. Start values for the restricted refits (forced; results informed: no for any verdict quantity).**
- *The problem.* On the first runs, Stata's constrained `logit ... constraints()`, started at the infeasible β̂, stalled on saturated "not concave" plateaus at some grid points for the probability hypotheses (ln RRR and ln RR_lit): log-likelihood −10.9M to −20.2M, against −2.57M unconstrained. Recovery R1 also stalled.
- *Why this is the optimizer, not a missing maximum.* At the neighbouring point r = −0.264 (h6) the same constrained fit converged to −2,577,456. At r = −0.255 it failed from both β̂ and the neighbour's solution. Substituting the constraint out (an unconstrained logit with an offset, pivoting on the coefficient with the largest |R_j|/sd(x_j)) converges in 3 iterations to −2,577,187. The constrained maximum therefore exists.
- *The change.* `sb_repar_start` (`sb_lib.do`) computes that exact solution and passes it as the start value of the card's constrained refit. The refit then converges under the card's settings, `tolerance(1e-8) ltolerance(1e-10)`.
- *What is unchanged.* The card fixes start values only for R1 (β̂), which is unchanged. The estimator and the optimum are unchanged. At converged points the p-values are identical to those from the β̂ start, for example .0053005301, .0085008501 and .0236023602 for h1, h5 and h6 at r = 0.
- *Before the change.* The first inversion runs, all stopped, were spending 10–20 minutes per stalled point in R1.
