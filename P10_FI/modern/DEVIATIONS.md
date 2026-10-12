# P10_FI S6: deviations from, and implementation notes on, the frozen method card

Card: `modern/method_card.md`, frozen at commit 17a056d. No analysis outside the card was added. Every choice below was fixed in code before the first run of the bootstrap or regression that it affects. The one exception is D6, a bug fix that does not change any number. Runtime is about 12 minutes for scripts 01–05, so no replication count was reduced. `parallel::parLapply` was not needed: each bootstrap uses one L'Ecuyer-CMRG stream from seed 20261011, and each `boottest` call is reseeded with `dqset.seed`/`set.seed(20261011)`. No package was installed. `summclust` 0.7.0 and `fwildclusterboot` 0.14.3 were already present.

**D1. Parish resampling unit = `parishdum` (36 parishes), not raw `pid` (37) (card §4 A-B; forced; results not informed).** The script maps pid 452 to CampsBay1 with the comment "foutinskrywing" (a mis-entry), and it maps pids 519 and 527 both to Mowbray1. Raw pid would therefore split single parishes. `parishdum` is the script's parish identifier and the LPM cluster variable, so the H1 bootstrap, S23, S24 and the LPM rows all use one parish definition. On the 2018 file every couple in the descriptive universe has a mapped `parishdum`.

**D2. Bootstrap and interval details the card leaves open (results not informed).**
- Percentile intervals use `quantile(type = 7)` at 0.625% and 99.375%.
- The Fieller-type set for F is computed on a grid over [−3, 4] in steps of 0.0005. It is reported as bounded and convex if no grid edge is accepted.
- In the H2-ITS circular moving-block residual bootstrap, block starts are drawn uniformly over the 53 years and the series is truncated to T.
- S4 uses circular 5-year blocks within each period pool, and the pools are drawn independently.

**D3. Sensitivity implementation details (results not informed).**
- **S10.** Placebo t-statistics use the primary specification (K = 2, HAC lag 3) re-centred at each break year. There are 38 placebo dates.
- **S11.** Prais–Winsten is iterated to convergence and uses conventional SEs from the transformed regression, with df = T − k − 1.
- **S13.** The second break is a level and slope change at 1939, applied to the pre-1949 segment only. Applied to the post segment it would be collinear. θ and Δslope are evaluated against the extrapolated pre-trend including these terms.
- **S14.** θ_micro is the `act` coefficient once the linear year is replaced by Pre·u, Pre·u² and Post·u.
- **S15.** The 258 records are allocated to years in proportion to N_t (largest remainder). Under (iv), 131/258 of the 1925 allocation enters the white-husband denominator, following the S2 Table 1 shortfall of 131 white–white couples.
- **S17/S16.** CR1 benchmarks use t on G − 1 df and the 1 − 0.05/4 level.
- **S18/S19/S22.** Only part of each family is re-estimated, so these rows report the unadjusted p and the Bonferroni CI without Holm. S16, S17, S20, S23 and S25 re-estimate whole families and report Holm.
- **S18.** The HHI rebuilt from the snapshot equals the script's `inequality` to within 1e-16. The leave-one-out HHI removes the couple's own husband. The lagged HHI is the same pid's HHI in t − 1, and couples without one are dropped.
- **S21.** The card names no inference for the logit. The OR CI uses two-way CR1 (the card's fallback estimator), with t on min(G) − 1 df at 95%. The AMEs are point values.
- **S23.** Only 9 parishes meet the ≥10-in-every-period rule. In standardisation the fixed weights are renormalised over parishes with marriages in the given year or period. None of the 9 parishes has a white-husband interracial marriage in 1925, so S25 = 0 there.
- **S24.** Drops cover all 36 `parishdum` values. For each drop the Family Q intervals are rebootstrapped with the same seed, and the Family E and L rows are re-estimated with Holm applied.
- **S25.** The six unmapped parishes get `parishdum = "pid<id>"`, and pid 557 is removed before the HHI-based LPMs. The HHI is per pid, so the other parishes are unaffected.

**D4. CI inversion failures in sensitivity runs (forced).** `boottest` sometimes reported "confidence inversion failed due to poorly chosen starting values".
- Where the primary inference function is used, the card's failure rule applies: two-way CR1 supplies all three inputs. This happened in S20 (H2-c2L) and in S24 (H2-c2 in 2 of 36 drops, H2-c2L in 4). Neither changes a verdict category.
- In S16 (parish × 5-year block) the CI could not be inverted for H2-c2 and H2-c2L. For these two rows the WCR p is reported with an empty CI, and no fallback is substituted, because S16 is itself a different clustering scheme.
- No primary row failed. All eight primary rows use two-way WCR with 0 degenerate draws.

**D5. Verification uses the S2 snapshots, not a fresh rerun of the original script.** The card's data step is the S2-patched original script on the 2018 file (`run_original.R v2018`). The S6 scripts read the snapshots that run left on D: (`repro_original/_scratch/v2018/`). They then check that the refit `model6`/`model8` reproduce the S2 coefficients, iid SEs and N exactly, and that the Figure-3 definition reproduces all 53 S2 Figure-3 values (`output/verification_*.csv`).

**D6. Bug fix after the first full run (results not informed).** In the first run of `04_sensitivities.R`, the S11 note string was passed positionally into the `p_holm` column. The call was corrected to a named argument and all scripts were rerun. No estimate changed.
