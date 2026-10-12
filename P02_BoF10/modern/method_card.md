# Method card: P02_BoF10, the Cape trade route and medium-term business cycles

Status: v3 (2026-10-12), to be FROZEN with the commit message "FREEZE S6 card P02" (A9).
- History: v1 → Codex review (reviews/P02_BoF10_codex_S6card.md; approve-with-changes, 7 required changes) → v2 → Codex compliance check (reviews/P02_BoF10_codex_S6card_v2.md; freeze-after-minor-edits, 5 edits) → v3 (this card). Issues not fully resolved are listed in §10.
- Margins follow AMENDMENTS.md A3, A4, A7, A8 and A8a. No substantive verdict threshold (the 1% and 5% levels, the verdict rows) was chosen from S5 results. The numerical-validity rules (§4), the Monte Carlo precision rule and draw counts (§4, §6) and the calibration design (§4a) are implementation choices made by the card author; they do not move a verdict except through the stated failure rule and two-stage rule, and are disclosed as such.
- Rights class: open. Data on D: (A6); scripts read them through `tools/paths.R`.
- No original code survives (S2 not attempted; interactive EViews). The S3 rebuild (`repro_r/`) is the formal reproduction baseline, but S5 recovered the authors' own filtered series and specification, which reproduce the headline cell exactly. The primary analysis therefore runs on the authors' surviving series, not on the rebuild (whose filter and series labels S5 showed to be wrong: S5-9, F4, pair-B reasons (i)–(iii)).

## 0. Type of analysis
**(ii) An inference-only upgrade (A4b ladder).** For the one testable headline row the statistic, the series, the lag order and the estimator are the authors'. Only the reference distribution changes: the PSS asymptotic bounds, which do not apply to band-pass-filtered series, are replaced by an empirical null built from phase-randomised surrogates of the authors' own filtered series. **The null therefore differs from the paper's** (§3): the surrogate null is independence of the two filtered series, not β_y = β_x = 0 with short-run dependence allowed. H1 is accordingly read only as evidence against independence under the surrogate model. "Overturned" cannot be reached (A4b). The paper makes no odds-ratio or probability claims, so A4c does not apply.

The primary analysis runs in minutes (9,999 surrogate draws of one OLS regression, with a possible second stage of 99,999), well inside the wave-3 limit of 30 minutes. The calibration study (§4a) is report-only.

## 1. Claims family (frozen headline rows) and interpretations
The four `headline = 1` rows of `claims/claims.csv` (A1 union) are the family. Interpretations are quoted from `claims/claims_spec.md`. Star legend: "*Statistically significant at 5% **Statistically significant at 1%", so `stars05` = 1 (A7) and ** marks p < 0.01.

| Row | Claim id | Published | Authors' interpretation | Type | Status |
|---|---|---|---|---|---|
| H1 | `T4_r3_F` | F = 61.77** (ships → wheat reaped, VDR corrected, 12–40 y band) | "We find strong evidence that overall wheat production was systematically related to ship traffic" (p.25); abstract: "a strong systematic co-movement between wheat production and ship traffic" | inferential (rejection of no long-run level relationship at the stated 1% level) | **testable**: the authors' filtered series survive and S5 reproduced F = 61.766 on them (a provenance check, §4; not a verdict condition) |
| H2 | `T4_r5_F` | F = 24.77** (ships → wheat reaped, Brunt 2007) | "We reach the same conclusion regardless of data source" (p.25) | inferential | **not-testable**: no Brunt series, raw or filtered, survives (S5-8; the rebuild's "Brunt" column is the VDR corrected series, S5-9/F4) |
| H3 | `T5_r3_coef` | θ = 2.18 (SE 1.012), ships → wheat reaped (Brunt) | ship traffic "had an equally large impact on overall wheat production" as on exports (2.88), so it "also encouraged agricultural production for local use" (p.29); a 10% medium-term excess of ships goes with ≈ 22% excess wheat output | magnitude (A3/A4), plus the embedded comparative claim "equally large" (A8 "similar": ratio in [0.80, 1.25]) and "above that of wheat exports" (A8 ">") | **not-testable**: same reason as H2 |
| H4 | `T5_r5_coef` | θ = 2.88 (SE 0.979), ships → wheat exports | "if ship traffic growth exceeded its long-run trend by 10 per cent, wheat exports also tended to accelerate, growing by 28 per cent in excess of their long-run trend" (p.28) | magnitude (A3/A4) | **not-testable**: no filtered exports series survives, and the construction of the published series is unresolved on at least four choices that each change the series and that the paper does not report: the treatment of the 11 internal gaps, the start and end year of the window, the filter options (EViews CF root/drift, inferred only for ships), and log versus level. The estimand (θ on the published series) is therefore not recoverable, independently of what any reconstruction returns. S5-8 stays unresolved. Reconstructions are reported as sensitivity 11 and never vote |

**Notes on the family.**
- H3's comparative sub-claims depend on the Brunt series and are not-testable with it. For the record (not a verdict): on the published numbers themselves the ratio 2.18/2.88 = 0.757 lies outside A8's [0.80, 1.25] "similar" band, and 2.18 < 2.88 contradicts "above that of wheat exports" (S5-4, F6a). This is an interpretation-audit result (S5), not an S6 verdict.
- The reverse direction (`T4_r4_F`, wheat → ships, 91.67) and the VDR long-run coefficient (`T5_r1_coef`, 4.53) are row-context, not headline. They are computed with the primary machinery and reported (sensitivities 6, 7) but decide nothing.
- The causal sentences ("catalyst for growth", "stimulated local demand through secondary and tertiary sector activities", the "little economic impact" hypothesis "should be rejected") are **not-testable**: bivariate correlations of filtered series identify neither direction nor channel (S5 interpretation audit (3)–(4), F6a).

## 2. Defects addressed
S5 (Claude S5-1 to S5-10, Codex F1–F7, reconciled in `audit.md`) found, in order of consequence for H1:
- (a) **The PSS bounds test has no known null distribution on band-pass-filtered series** (S5-2, F3). CF-filtered 12–40 y components are smooth, near-deterministic cycles; with only ≈ 2–7 cycles in 85–93 years, lagged levels dominate the ECM and F is enormous under independence. Sources: Granger and Newbold (1974) on spurious regression; Harvey and Jaeger (1993) and Cogley and Nason (1995) on spurious cycles induced by filtering; Pesaran, Shin and Smith (2001) on the bounds test's assumptions.
- (b) **Residual serial correlation** (F1): lag-1 ρ = 0.92 in the reproducing regression. Conventional F and delta-method SEs are invalid.
- (c) **Wrong critical values** (S5-1, F2): k = 4 bounds quoted for k = 1 equations.
- (d) **Knife-edge lag order** (S5-3, F5). Not fixable for the published estimand, which is defined at four lagged differences; handled by sensitivities.
- (e) **Untraceable series** for H2–H4 (S5-8). Not fixable with surviving data; those rows are not-testable.

The primary analysis addresses (a)–(c) jointly: a surrogate null that preserves the circular power spectrum of the authors' filtered dependent series and destroys only its relation to ships replaces the asymptotic bounds, so the reference distribution reflects the filtered series' autocorrelation and the correct number of regressors at once. It does so only approximately: Fourier magnitudes fix the circular autocovariance of y_w, not the finite-sample covariance of an asymmetrically filtered, windowed series, and the design does not nest the paper's null (§3). The size of the procedure in the actual design is assessed by simulation (§4a), not assumed. Method: Theiler et al. (1992, *Physica D*) on surrogate-data testing; Ebisuzaki (1997, *J. Climate*) on phase-randomisation tests of correlation between serially correlated series. The ideal modern design, low-frequency inference in the sense of Müller and Watson (2018, *Econometrica*, "Long-run covariability"), is not adopted as primary (§10.5).

## 3. Estimands
- **Original estimand (H1).** F, the Wald F-statistic for β_y = β_x = 0 in the case-III unrestricted ECM
  Δy_t = c + β_y y_{t−1} + β_x x_{t−1} + Σ_{i=1..4} (φ_i Δy_{t−i} + ψ_i Δx_{t−i}) + ω Δx_t + ε_t,
  with y = WHEATMF22 and x = SHIPSMF22 (log series, CF 12–40 y band, authors' EViews filter), as implemented in `compare/s5_checks/uecm_fn.R` with p = 5. The published inference compares F with [2.86; 4.01].
- **New inferential quantity.** The same statistic F on the same series, with a different reference distribution: p_s = P₀(F* ≥ F_obs), where P₀ is the distribution of F when y has its observed circular power spectrum and is independent of x.
- **The hypotheses differ.** PSS tests β_y = β_x = 0 in an ECM that permits short-run dependence between Δy and Δx, with bounds that presume I(0)/I(1) series. The surrogate null is independence of the whole series y_w from x_w, which is stronger. Rejecting it is evidence against independence under the surrogate model; it establishes neither cointegration nor a direction of influence. H1 is judged on the size of F relative to that null, and the verdict wording in §8 is restricted accordingly. Ebisuzaki (1997) and PSS (2001) address different nulls.
- H2–H4: original estimands as published; no new estimand (not-testable).

## 4. Primary analysis (H1 only)
**Data.** `causality for med freq.XLS`, first sheet, read with `readxl` from `dpath("P02_BoF10","original","Boshoff Fourie Ships","Business Cycle Cape Colony")` and coerced to numeric, exactly as in `compare/s5_checks/s5_mf22_p5.R`. Columns WHEATMF22 (y) and SHIPSMF22 (x).

**Window.** The first to last jointly non-missing observation of (y, x), as in `uecm_fn.R`; call the windowed series y_w, x_w, length n_w. If any value inside the window is missing, the analysis stops and H1 is not-testable (no interpolation).

**Implementation check (not a verdict gate).** F_obs = uecm(y_w, x_w, p = 5)["F"] is compared with the published 61.77. A value in [61.765, 61.775] is recorded "reproduced". Otherwise it is recorded "unreproduced", the discrepancy is investigated and logged in `audit.md` (window, column, lag, coercion), and the verdict is still computed from F_obs on the surviving series and carries the label "unreproduced". S5 obtained 61.766 with n = 80 regression observations.

**Regression validity checks (identical for the observed and every surrogate regression, in the primary and in every sensitivity).** For p lag order (p − 1 lagged differences of each series) the design matrix has K = 2p + 2 columns (constant, y_{t−1}, x_{t−1}, (p − 1) Δy lags, (p − 1) Δx lags, Δx_t); the primary has p = 5, K = 12. A regression is valid only if: (i) `qr(X)$rank` = K (no aliased column, so `lm` drops nothing); (ii) the Wald test has exactly 2 restrictions (β_y, β_x), both estimable; (iii) residual degrees of freedom (regression n − K) > 0 (expected 68 in the primary); (iv) `kappa(X, exact = FALSE)` is finite and < 1/.Machine$double.eps (numerical singularity only); (v) F is finite. F is computed from the explicit Wald form on the checked fit, not from a rank-reduced `lm`. If the observed regression is invalid, H1 is not-testable. An invalid surrogate regression is a failed draw (below).

**Surrogates.** For b = 1, …, B, with stage 1 B = 9,999:
1. Let m = mean(y_w), z = y_w − m, Z = fft(z) (base R, unnormalised). The surrogate preserves m and the circular periodogram |Z_j|² exactly. It does not preserve the finite-sample covariance of the filtered window (§10.2).
2. For j = 1, …, ⌊(n_w − 1)/2⌋, draw φ_j ~ U(0, 2π) and set Z*_{j} = Z_j·e^{iφ_j} and Z*_{n_w−j} = Conj(Z*_j) (0-based frequency index j; R index j + 1). Z*_0 = Z_0.
3. If n_w is even, the Nyquist coefficient is real; set Z*_{n_w/2} = ε·Z_{n_w/2} with ε = ±1 each with probability ½, which preserves its squared amplitude exactly. Ebisuzaki's √2·cos φ rescaling is not used because it changes that squared amplitude.
4. y*_b = m + Re(fft(Z*, inverse = TRUE))/n_w.
5. F*_b = uecm(y*_b, x_w, p = 5)["F"]. x is held at its observed values (the test conditions on ships, as the ECM does).

Seed: `set.seed(20261012)` once, default RNG kinds (Mersenne-Twister, Inversion), recorded with `RNGkind()`; phases (then the Nyquist sign) drawn in the order above, draw by draw.

**p-value.** With B_def valid draws and E = #{F*_b ≥ F_obs} among them, p_s = (1 + E)/(1 + B_def). If B_def = 0, H1 is not-testable.

**Monte Carlo precision (two stages, fixed in advance).** Stage 1 (B = 9,999 attempted) reports p_s and its Monte Carlo SE sqrt(p_s(1 − p_s)/B_def) (≈ 0.001 at p = 0.01). If the interval p_s ± 3.29·SE contains 0.01 or 0.05, stage 2 runs once with B = 99,999 and `set.seed(20261013)`; stage 2 alone then decides, and stage 1 is reported next to it. Otherwise stage 1 decides. If the stage-2 interval still contains a threshold, its p_s decides by the §8 table and the MC SE is reported.

**Failure rule (symmetric).** A draw fails if `lm` errors or any validity check above fails. With f failed draws, compute the bounds p_lo = (1 + E)/(1 + B) (failures counted as non-exceedances) and p_hi = (1 + E + f)/(1 + B) (failures counted as exceedances), with B the attempted draws of the deciding stage (p_s itself uses B_def and the stage's MC SE uses B_def). If p_lo and p_hi fall into different rows of the H1 verdict table (§8), H1 is not-testable; otherwise p_s decides. f is reported.

**Reported with the primary.** n_w, regression n, F_obs, p_s, p_lo, p_hi, f; the surrogate 90th, 95th and 99th percentiles of F* (critical values conditional on this surrogate design; their size is assessed in §4a); the observed residual lag-1 autocorrelation and the Breusch–Godfrey LM(4) statistic; the median F*; the implementation label (reproduced / unreproduced); the MC SE and the stage that decided.

**Scripts.** `modern/01_primary.R` (copies `uecm_fn.R` into `modern/`, adding only the validity checks above), `modern/02_sensitivities.R`, `modern/03_calibration.R`, `modern/04_verdicts.R`. Outputs: `modern/output/primary.csv`, `sensitivities.csv`, `calibration.csv`, `verdicts.csv`, `sessionInfo.txt`. Each script regenerates its output identically from a clean `Rscript` session.

## 4a. Calibration study (report-only; registered here, never verdict-determining)
Purpose: to show how the primary procedure behaves in a design that mimics the filtering, windowing and lag structure, so that readers can judge the surrogate p-value. It has no threshold and no veto. Its results are reported next to the H1 verdict and in the synthesis.
- **DGP A.** Two independent log random walks with drift, length 93 (the raw sample length), drift and innovation SD set to the OLS estimates from the observed raw ships and raw corrected VDR wheat (Δlog) series respectively.
- **DGP B.** Two independent AR(q) processes in Δlog (the sieve fits of sensitivity 5, intercept included), cumulated from the observed first level.
- **Per replication.** Filter each series with `mFilter::cffilter(pl = 12, pu = 40, root = TRUE, drift = TRUE)` over its full length; keep the central n_w observations (dropping ⌊(93 − n_w)/2⌋ at the start and the remainder at the end); compute F with p = 5; run the primary procedure with B = 199 and the same validity and failure rules; record p_s (failed draws counted as in p_hi).
- **Execution.** A single fixed stage with B = 199 per replication; the two-stage rule of §4 is not applied. This is a reduced-budget calibration of the surrogate test, not of the exact two-stage procedure. In each replication the observed regression is checked as in §4; if it is invalid the replication is "invalid" and excluded from the rejection-rate denominator, with the count reported. Otherwise p_s = (1 + E)/(1 + B_def) and p_lo, p_hi follow §4 with B = 199. A replication is "rejecting at level α" if p_hi < α (all failed draws counted as exceedances), "non-rejecting" if p_lo ≥ α, and "ambiguous" otherwise (p_lo < α ≤ p_hi). The rejection rate is reported as the share of rejecting among non-invalid replications, with the share of ambiguous replications alongside, and as the complete-case rate using p_s.
- **Size.** R = 1,000 replications per DGP; rejection rates at 1% and 5% with Monte Carlo SEs. With B = 199 the smallest attainable p is 0.005, so the 1% rate is coarse. `set.seed(20261014)`. Because it uses the R filter and not the authors' EViews series, it is a stylised check of the procedure, not of the authors' exact series.

## 5. Admissible sensitivities (exhaustive; reported, never verdict-determining)
All use B = 999 and seed 20261012 unless stated.

**Common specifications.** Series gaps: none are interpolated except in sensitivity 11. A sensitivity whose window contains an internal gap is logged "not run: gap". Filtering: `mFilter::cffilter(pl = 12, pu = 40, root = TRUE, drift = TRUE)` applied to the full available raw series, then restricted to the primary window (the trimming of sensitivity 12 is applied after filtering). Every sensitivity applies the §4 validity checks and failure rule. None is a repair of the primary or can change its verdict.

1. **Lag order.** p = 3, 4, 6 (2, 3, 5 lagged differences) on the authors' series, each with its own surrogate null.
2. **Lag selection inside the null.** Lag chosen by AIC, then by BIC, over 1–6 lagged differences on a common sample; selection repeated inside every surrogate draw, so the null reflects the selection step.
3. **Which series is randomised.** Surrogates of x (ships) with y fixed; independent surrogates of both. Independent surrogates of both are appropriate only for the independence null; they remove any short-run dependence that the paper's null would allow.
4. **Amplitude-adjusted surrogates.** IAAFT (Schreiber and Schmitz 1996), at most 100 iterations per draw, stopping early when the relative spectral discrepancy changes by less than 1e-8. It preserves the marginal distribution of y and approximates the spectrum. The distribution of final spectral discrepancies and the number of draws hitting the cap are reported; no draw is dropped for them.
5. **Sieve null on raw series.** Independent AR(q) sieve bootstraps of Δlog raw ships (`ships for eviews FROM 1652.xls`) and Δlog raw corrected VDR wheat (the `WHEAT` column of `agricultural output data for eviews.xls`, the source of WHEATMF22 per S5-9). Each AR is fitted by `lm` with an intercept, q ∈ {0, …, 4} by AIC; if the fitted AR has a root of modulus ≤ 1.0, q is reduced until the fit is stable (q = 0 is always stable). Centred residuals are resampled iid; the first q observed differences are the initial values, and the series is cumulated from the observed first level with no burn-in. Chosen q and root moduli are reported. Series are filtered in R and the statistic is recomputed on the R-refiltered observed series (harmonised, so observed and null share one filter). This changes the observed statistic (filter implementation).
6. **Reverse direction** (`T4_r4_F`, wheat → ships, published 91.67): the primary design with x and y swapped (surrogates of ships, now the dependent series). Bears on the "bidirectional" wording.
7. **Long-run coefficient** (`T5_r1_coef`, VDR, published 4.53): surrogate p for |θ| under the primary null, with the Newey–West delta-method SE (lag 4, `sandwich::NeweyWest`, prewhite = FALSE) and the conventional delta SE as published. Both are benchmarks, not repairs: the coefficient is a ratio −β_x/β_y whose denominator is unstable (S5-3), so delta-method intervals of either kind are unreliable.
8. **Conventional benchmarks.** F_obs against the PSS (2001) case-III k = 1 asymptotic bounds [4.94; 5.73] (5%) and [6.84; 7.84] (1%), and against the paper's [2.86; 4.01].
9. **Uncorrected VDR wheat** reaped (raw Van Duin and Ross sheet), R-refiltered, primary design. A changed series (A4d analogue).
10. **Alternative band** 12–20 y (the paper's p.21 sensitivity), R-refiltered ships and wheat, primary design.
11. **Exports reconstruction (H4 context).** Raw VDR "Exports of grains" (1706–93), the 11 internal gaps linearly interpolated, log, R CF 12–40 I(1)+drift; SHIPSMF22 and R-refiltered ships as regressor in turn; primary design for F and |θ|. H4 stays not-testable whatever this shows.
12. **Influence of the endpoints.** The primary with the first and the last 5 years of the (filtered) window dropped (CF end-point distortion). A probe of end-point behaviour, not a validation of the surrogate.
13. **S3 rebuild numbers** (pair B) carried along for reference, labelled as using an I(0) filter, three lagged differences and mislabelled series.

## 6. Fixed choices
- **Missing data.** No interpolation in the primary; an internal gap in the window makes H1 not-testable. Sensitivity 11 interpolates exports as the rebuild did and is labelled so.
- **Trimming/bandwidth.** The authors' 12–40 y CF band and their filtered series; no trimming in the primary.
- **Lag order.** Four lagged differences (p = 5), the only order that reproduces the published table (S5-3); fixed by reproduction, not chosen by the card.
- **Multiplicity.** The testable family has one row (H1). Not-testable rows do not enter it. No adjustment.
- **Weights.** None.
- **Boundary rules.** p_s = 0.01 is not significant at 1%; p_s = 0.05 is not significant at 5%. F*_b = F_obs counts as an exceedance.
- **Seeds.** 20261012 (primary stage 1, sensitivities); 20261013 (stage 2); 20261014 (calibration).
- **Draw counts.** Stage 1 B = 9,999; stage 2 B = 99,999; sensitivities B = 999; calibration B = 199 with R = 1,000.

## 7. Margins and their provenance
| Row | Confirm | Provenance |
|---|---|---|
| H1 | p_s < 0.01 | PROTOCOL S6 "the conclusion holds at the stated level"; the stated level is the authors' ** = 1% (A7, `stars05` = 1). A3 condition 2 (5%) defines the next rung of the A4b ladder. A3 conditions 1 and 3 (sign, 50% magnitude floor) do not apply to an F statistic, which has no sign and no magnitude in words. |
| H2, H3, H4 | none | not-testable |

- No ceilings, no bands. A8's plausibility flag does not apply to H1 (no stated magnitude).

**Disclosure.** S5 numbers already seen that bear on the H1 verdict or on the not-testable rows:
- **Reproduction:** T4_r3 F = 61.766 (n = 80) on WHEATMF22/SHIPSMF22, p = 5; T4_r4 91.67, T5_r1 θ = 4.525 (delta SE 5.683, t = 0.80) and seven further Table 4–5 cells reproduced.
- **Lag order (T4_r3):** F = 9.298 / 652.82 / 61.766 / 824.16 and θ = −19.008 / −0.152 / 4.525 / 0.059 for 2 / 3 / 4 / 5 lagged differences.
- **Null size under an independent-random-walk design** (R CF I(1)+drift, p = 5, n = 85, 1,000 pairs): median F 22.8, 95th percentile 470; P(F > 4.01) = 0.82, P(F > 24.77) = 0.48, P(F > 61.77) = 0.28; P(|θ| > 2.18) = 0.43. This is the closest S5 analogue of sensitivity 5 and strongly suggests the direction of the H1 verdict.
- **Residual diagnostics (Codex F1):** lag-1 residual autocorrelation 0.9205; BG LM(4) ≈ 76; 0.893–0.971 across ten equations.
- **R re-filter (same design):** T4_r3 F = 284.48, θ = 3.402.
- **Uncorrected VDR wheat:** F = 20.58, θ = −2.50.
- **Exports reconstruction:** F = 0.84 (published 18.97), θ = −1.44 (SE 2.16) (published 2.88); reverse F = 2.01 (published 25.02).
- **Rebuild (pair B):** T4_r3 235.40; "Brunt" (VDR corrected) T4_r5 182.80, T5_r3 2.90; exports T5_r5 1.514.
- **Corrected PSS bounds:** k = 1, [4.94; 5.73] at 5%, [6.84; 7.84] at 1%; F_obs exceeds both.

The phase-randomised surrogate null (the primary) and the calibration study have not been run. The verdict thresholds are the protocol's and the authors' own stated level; the card chose none of them after seeing these numbers.

## 8. Verdict tables (checked in order; the first rule that applies decides; exhaustive)
**H1 (`T4_r3_F`; A4b ladder, inference-only):**
| # | Condition | Verdict |
|---|---|---|
| 0 | data unreadable, an internal gap in the window, the observed regression fails a §4 validity check or F_obs is non-finite, or p_lo and p_hi fall in different rows below | not-testable |
| 1 | p_s < 0.01 | confirmed (F_obs is unusually large under independence with y's spectrum, at the authors' stated 1% level) |
| 2 | 0.01 ≤ p_s < 0.05 | qualified (inference-fragile: significant at the A3 5% level, not at the authors' stated 1%) |
| 3 | p_s ≥ 0.05 | weakened (F is not unusual under a null that respects the filtered series' autocorrelation, so "strong evidence" of co-movement is not supported) |

Every row carries the implementation label (reproduced / unreproduced), which does not move the row. No verdict wording speaks of cointegration or direction (§3). "Overturned" is unreachable (A4b): a failure to reject under a surrogate null is not a credible null of no co-movement, and an F statistic has no sign that could reverse. "Strengthened" is unreachable under the A4b ladder.

**H2 (`T4_r5_F`), H3 (`T5_r3_coef`, including its "equally large" and "above exports" sub-claims), H4 (`T5_r5_coef`):** not-testable (§1). **Causal and channel sentences:** not-testable.

**Summary and coverage.** The card reports exactly: "H1 [confirmed / qualified / weakened / not-testable]; coverage 1/4" when H1 is confirmed, qualified or weakened, and "H1 not-testable; coverage 0/4" when H1 is not-testable. There is no paper-level verdict. The magnitude claims (2.18, 2.88), the bidirectionality wording and the local-demand argument remain unassessed and are listed as such. Sensitivities 1–13 and the calibration study are listed next to the verdict, labelled "reported, not verdict-determining".

## 9. Codex review notes and responses
Review: `reviews/P02_BoF10_codex_S6card.md`, approve-with-changes, 7 required changes and 3 optional suggestions.

| # | Required change | Response in v2 |
|---|---|---|
| 1 | Distinguish the statistic from the hypothesis | §0 and §3 state that the surrogate null (independence of y_w from x_w with y's spectrum) differs from the paper's β_y = β_x = 0 with short-run dependence. H1 is read only as evidence against independence under the surrogate model, not as cointegration or direction (§3, §8 wording). |
| 2 | Justify calibration for the actual design | §2 drops the claim that critical values are "valid" and says the circular spectrum, not the finite-sample covariance, is preserved. New §4a registers a report-only size study (DGPs A and B, R-filtered, windowed, p = 5, 1,000 replications). Trimming (sens. 12) and IAAFT (sens. 4) are labelled probes, not validation. §10.2 records the residual gap. |
| 3 | Separate provenance checks from verdict eligibility; justify H4 independently of its reconstruction | §4: reproducing 61.77 is an implementation check with an "unreproduced" label and a logged investigation, not a not-testable trigger. §1: H4's exclusion rests on four unresolved construction choices (gaps, window, filter options, log/level), not on the reconstruction's sign or magnitude. |
| 4 | Narrow the summary verdict | §8 reports "H1 [verdict]; coverage 1/4" and no paper-level verdict; unassessed claims are listed. |
| 5 | Nyquist rule and Monte Carlo precision | §4: the Nyquist coefficient takes a random sign, preserving its squared amplitude exactly; the claim is now "circular periodogram preserved exactly". B = 9,999 with reported MC SE, and a fixed second stage (B = 99,999, new seed) if the 3.29-SE interval contains 0.01 or 0.05. Symmetric p_lo/p_hi failure bounds kept. |
| 6 | Finite but invalid regressions | §4: validity checks (rank 12, exactly 2 restrictions, df > 0, kappa < 1/eps, finite F) on the observed and every surrogate regression; F from the explicit Wald form. Observed failure → not-testable; surrogate failure → failed draw. |
| 7 | Complete the sensitivity specifications | §5 preamble and items 3, 4, 5, 7: gap rule, filter window and trimming order, AR intercept/stability/initial-value rules, IAAFT stopping and diagnostics. Newey–West (4) is labelled a benchmark on an unstable ratio; independent surrogates are labelled independence-only. |

| Optional suggestion | Response |
|---|---|
| Retain the 1%/5% ladder; no A3 floors, A8a bands, ceilings or sensitivity vetoes | Adopted unchanged (§7, §8). |
| Müller–Watson as a separately labelled extension | Not implemented in wave 3; recorded in §10.5. |
| A9 cap | v2 was followed by the compliance check; this is v3. |

**Compliance check of v2** (`reviews/P02_BoF10_codex_S6card_v2.md`): freeze-after-minor-edits; required changes 1, 3, 4, 5, 6 addressed, 2 and 7 partly. Responses in v3:

| # | Edit | Response in v3 |
|---|---|---|
| 1 | Validity rank for variable lag | §4: K = 2p + 2 columns, rank = K, df = n − K, for the primary and all sensitivities. |
| 2 | Calibration execution | §4a: single stage B = 199, labelled reduced-budget; invalid, ambiguous and complete-case rules and denominators specified. Residual gap (stylised filter, coarse 1% grid) in §10.2 and §10.10. |
| 3 | MC uncertainty on B_def | §4: p_s and MC SE use B_def; B_def = 0 is not-testable. |
| 4 | Coverage wording | §8: 0/4 if H1 is not-testable, else 1/4. |
| 5 | Provenance statement | Header: no substantive verdict threshold chosen from S5; implementation rules identified separately. |

## 10. Known limitations at freeze
1. **Coverage.** Three of four headline rows are not-testable because the Brunt and filtered exports series do not survive or cannot be reconstructed. The magnitude claims (2.18, 2.88), the bidirectionality wording and the local-demand argument receive no S6 verdict; only the S5 interpretation audit speaks to them. If the Brunt (2007) series is obtained later, an amendment can add H2–H3 under this design.
2. **Surrogate assumptions and size.** Phase randomisation assumes y is a stationary linear Gaussian process with the observed spectrum and preserves only the circular autocovariance. A CF filter applied asymmetrically over a finite sample has time-varying variance near the endpoints, and n_w ≈ 85–93 gives a coarse periodogram. The surrogate null is also not the paper's null. The calibration study (§4a) uses the R filter, not the authors' EViews series, so it cannot certify the exact design. Sensitivities 4, 5 and 12 and §4a inform the reader but do not vote.
3. **H4 not-testable despite surviving raw data.** The raw exports survive and the filter is partly recovered, but the construction choices of the published series are unresolved. A reviewer could argue for a reconstruction-based verdict, which the card rejects because it would confound reconstruction with method.
4. **Confirmation at 1%.** H1 is confirmed only at the authors' stated 1% level, read from their star legend; the A3 default 5% defines the qualified rung. This is a reading of PROTOCOL S6 ("at the stated level"), not an A8 default.
5. **Lighter primary than the ideal.** Müller–Watson long-run covariability inference on low-frequency cosine projections is the modern standard for co-movement at 12–40 y horizons. It needs a different estimand (a covariability parameter rather than an ECM F) and so could only be `different-estimand`; it is not implemented in wave 3.
6. **Knife-edge lag order.** The primary is fixed at the published lag order (S5-3). Sensitivities 1–2 show how far the result depends on it; they cannot change the verdict.
7. **Filter provenance.** The authors' series come from an EViews CF implementation whose exact options are inferred (r = 0.991 with the R I(1)+drift filter for ships). The primary uses the authors' series directly, so this matters only for sensitivities 5 and 9–11 and for §4a.
8. **No identification.** Even a confirmed H1 would establish departure from independence of filtered series, not that ships caused wheat output.
9. **Two-stage Monte Carlo.** If the stage-2 interval still contains a threshold, the point p_s decides with its MC SE reported; the verdict is then close to the boundary and should be read so.
10. **Calibration is reduced-budget and stylised.** §4a uses B = 199 (smallest p = 0.005), one stage, the R filter and a generic window; it cannot certify the size of the exact two-stage procedure on the authors' EViews series. It is report-only and never changes a verdict.
11. **Implementation rules not derived from the protocol.** The validity checks, the 3.29-SE two-stage rule, the draw counts and seeds are card-author implementation choices (disclosed in the header). They were fixed before the primary was run and affect a verdict only through the §4 failure rule and two-stage rule.
