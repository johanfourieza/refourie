# Method card: P21_LFG, the substitutability of slaves (Graaff-Reinet, 1805–1828)

Status: v3 (2026-10-12), frozen under A9.
- History: v1 → Codex review (reviews/P21_LFG_codex_S6card.md; verdict approve-with-changes, 7 required changes) → v2 → Codex compliance check (reviews/P21_LFG_codex_S6card_v2.md; freeze-after-minor-edits, 5 edits) → v3, frozen under A9.
- Margins follow AMENDMENTS.md A3, A4, A8 and A8a.

## 0. Type of analysis and scope of any verdict
The primary analysis is **(ii) an inference-only upgrade** (A4b ladder) of the S3 rebuild. The rebuild is the reproduction baseline because no original code survives (S1, S2).

- The point estimates are those of the S3 rebuild (`repro_r/02_analysis.R`, annual specification): pooled centres 0.8359 (F7), 0.8454 (F8) and 0.9005 (F9), and the 22 annual medians per pair. The primary analysis does not change them.
- It adds the inference the paper never reported (S5-02, Codex F04, F07): a linked-household cluster bootstrap across the whole 1805–1828 panel, with a simultaneous band for the 22 annual centres of each pair.
- It is not (i): S5 found no verified code or data error that moves an HEC. It is not (iii) or (iv).
- **Scope of confirmation (stated on every verdict).** Any verdict is **conditional on the S3 reconstruction**: annual OLS fits, ln(1+x) inputs, median of household HEC. The loss of the original code does not establish that this estimand equals the authors'. S5-01 (smoothing), S5-04 (zeros) and S5-05 (mean vs median) are unresolved. A "confirmed" therefore reads "confirmed on the S3 reconstruction"; it is not a statement that the authors' unrecoverable estimate was positive.
- **Why not correct the specification.** None of S5-01, -04 or -05 is a verified error. They are reported sensitivities (§5) and never vote.
- **A4b consequences.** The ladder is confirmed / qualified (inference-fragile) / weakened, plus not-testable. **Overturned cannot be reached**, including the A4a credible null and a supported nonpositive year. Such outcomes are flagged in the report and map to weakened. This asymmetry is imposed by the protocol (A4b); it is not evidence-based. **Strengthened is not on the ladder.**
- **A4c** does not apply (no odds ratios). **A4d:** sensitivities that change the population or estimand (§5B) cannot set a verdict.
- **The interpretation** (HEC > 0 means "not substitutable", "different tasks") is separate and not tested (INT, §1).

## 1. Claims, primary targets and interpretation
The paper prints no coefficient, SE or elasticity. The three headline rows are digitised boxplot centres. The authors' wording concerns **only the sign**, "throughout" the period (`claims_spec.md`). Each claim therefore has **one primary verdict target: the sign row** (A8 threshold claim, T = 0, "throughout" = every one of the 22 data years). The digitised centres are separate **point comparisons**, reported beside the verdict but **not voting** (§8C).

| Claim | Source row | Wording | Primary (sign) row | Reported point comparison |
|---|---|---|---|---|
| F7 | `F7_all_median` | household (family) labour and slaves: "complements throughout the period of analysis, since the Hicksian mean elasticities of complementarity are all positive" (p.15) | **F7-s**: c_FS,t > 0 for every year t | F7-pt: pooled centre vs [0.765, 0.935] (0.85 ± 10%) |
| F8 | `F8_all_median` | household labour and khoe: "also remain positive throughout" (p.16) | **F8-s**: c_FK,t > 0 for every t | F8-pt: pooled centre vs [0.72, 0.88] (0.8 ± 10%) |
| F9 | `F9_1812_1817_median` | slaves and khoe, "the major hypothesis": "remain complements throughout" (p.16); abstract "remain complements throughout the period of the study" | **F9-s**: c_SK,t > 0 for every t | F9-pt: 1811–1817 centre vs [0.81, 0.99] (0.9 ± 10%) |

The 22 data years are 1805–1828 without 1808 and 1827.

**Interpretation row INT (reported; verdict not-testable).** The authors read HEC > 0 as "not substitutable", "distinctly different types of labour" and slaves and khoe "performing different tasks". HEC > 0 (q-complementarity) does not imply non-substitutability: a Cobb–Douglas technology has HEC = 1 and an elasticity of substitution of 1 (S5-03, Codex F02). The HEC primary cannot test this reading, and the card does not test it by any other estimand (the v1 direct-elasticity D1 is withdrawn; §9).

**Not addressed.** The mechanisms in the abstract (location-specific khoe skills; slaves as artisans or collateral). Robustness Figs 10–16 are not headline rows.

## 2. Defects addressed
- **No inference anywhere (S5-02; Codex F04, F07).** The boxplot spread reflects variation in evaluation points, not sampling uncertainty, and "throughout" is asserted without any interval. The S5 bootstrap resampled within years and ignored that linked households recur across years (F04). The primary addresses this.
- **Specification uncertainty, documented, not corrected:** zero inputs (S5-04, F01); five-year smoothing (S5-01, F01); mean vs median (S5-05, F04, S0 e5); 1828 included despite p.6 (S5-13); monotonicity failures (S5-05). All are §5 sensitivities.
- **Interpretation (S5-03, F02):** the INT row only.

Sources:
- Hicks (1970, *Economic Journal*) and Sato and Koizumi (1973, *AER*), on the elasticity of complementarity;
- Blackorby and Russell (1989, *AER*), on Allen vs Morishima elasticities;
- Battese (1997, *J. Agricultural Economics*), on zero inputs;
- Cameron, Gelbach and Miller (2008, *REStat*) and Cameron and Miller (2015, *JHR*), on cluster resampling;
- Romano and Wolf (2005) and Berger and Hsu (1996, *Statistical Science*), on simultaneous inference and intersection–union tests.

## 3. Estimands
- **Original estimand.** The centre (stated "mean", plotted as a box centre) of the household-level HEC from annual OLS translog fits, with an unrecoverable zero treatment and smoothing.
- **New estimand (primary), identical to the S3 rebuild** (S4: close/exact on all three headline rows):
  - Data: `processed.dta` (`dpath("P21_LFG", "original", "Calumet Links", "processed.dta")`), years 1805–1828.
  - Variables: lq = ln(Tot_prodfl) for Tot_prodfl > 0, else NA; lk = ln(1+khoe), ls = ln(1+slaves), lf = ln(1+settlers).
  - For each year t, OLS on year-t rows with lq, lk, ls, lf all non-missing: lq ~ lk + ls + lf + ½lk² + ½ls² + ½lf² + lk·ls + lk·lf + ls·lf.
  - For each household row i in year t: M_i = b_i + Σ_j b_ij·ln X_j (squares carry their ½), HEC_ij = (b_ij + M_i M_j)/(M_i M_j), for the pairs FS, FK, SK.
  - **Annual centre** c_p,t = median of the finite household HEC_p in year t.
  - **Pooled centres** (point comparisons only): F7-pt and F8-pt = median over the 22 years of c_p,t; F9-pt = median of c_SK,t over 1811–1817 (7 data years).
- **Scale.** All inputs enter as ln(1+x). The HEC is therefore the complementarity of the shifted quantities 1+x, not of raw quantities. This is the rebuild's convention and is part of the conditional scope (§0).

## 4. Primary analysis

**Reproduction check (before inference).** The script must reproduce `repro_r/results_r.csv` (F7 0.8359, F8 0.8454, F9 0.9005) and the annual FS, FK and SK medians of `compare/s5_checks/annual_base_aux.csv` to < 1e-6. If it does not, the analysis stops, every row is not-testable, and the discrepancy is logged in `modern/DEVIATIONS.md`.

**Cluster definition and pre-run audit.**
- Clusters: the linkage variable `index`, over all 1805–1828 rows that enter any annual regression. A row with missing `index` is its own singleton cluster.
- **`modern/00_cluster_audit.R` runs and is committed before any bootstrap. It had not been run at freeze (§10.12).** It writes `modern/cluster_audit.csv` with:
  - the number of estimation rows overall and by year;
  - the number of distinct non-missing `index` values overall and by year, and the number of clusters under the definition above (the cluster count is *not* assumed to be 22; it is the number of distinct linked households plus singletons);
  - the number of `index` values repeated **within** a year (several rows, same household and year), with the maximum multiplicity;
  - the distribution of cluster sizes (rows and years spanned): mean, median, maximum, and the largest cluster's share of rows;
  - linkage coverage: the share of rows with missing `index`, overall and by year, and the distribution of `mscore` where present.
- **The design does not depend on the audit's outcome.** The definition above is fixed; the audit documents it and is not a gate. No clustering variable is switched after it is seen.
- **Justification.** `index` is the only available household identifier across years. Rows sharing it are the same linked household and are the unit of dependence. Rows with missing `index` cannot be shown to be dependent on any other row and are treated as independent singletons. If unlinked rows are in truth later or earlier records of linked households, the intervals understate the dependence (§10).
- **Resampling.** One replicate draws clusters with replacement, as many as there are clusters, from the full list. **Multiplicities are preserved**: a cluster drawn k times contributes all its rows k times, in every year, so a duplicated cluster is a duplicated record set, including duplicate rows within an annual regression. All 22 annual regressions are re-estimated on the replicate, the household HECs are recomputed for the replicate's year-t rows, and the annual centres are recomputed by §3.
- **What the intervals cover:** sampling variability from the finite set of linked households, allowing arbitrary dependence within a household across years. They do not cover the unknown original specification, transcription error, linkage error, price uncertainty in output valuation, or input endogeneity.
- **B = 999** (wave-3 cap), seed `set.seed(20261012, kind = "L'Ecuyer-CMRG")`, one sequential stream. No escalation of B.

**Multiplicity (recomputed for the sign rows only).** The voting family is the **three sign rows** {F7-s, F8-s, F9-s}. The point comparisons are not in the family. Each sign row uses a band over its 22 annual centres, and the Bonferroni correction runs over all 3 × 22 = 66 annual comparisons: α = 0.05/66, **z_band = qnorm(1 − 0.05/(2·66))**. The code computes z_band and z_pt from these unrounded `qnorm` expressions; 3.368 and 2.394 are display approximations only and never enter a bound. The corrections are fixed now and are not changed after any result.

**Intervals (normal, bootstrap SE).**
- se_t = sample SD (n − 1 denominator) of the replicate annual centre over the valid draws (below).
- **Band:** L_t = c_t − z_band·se_t, U_t = c_t + z_band·se_t (z_band ≈ 3.368).
- **Reported point-comparison intervals:** I = [G − z_pt·se, G + z_pt·se] for the pooled centre G, se from the same draws, z_pt = qnorm(1 − 0.05/6) ≈ 2.394 (family of the three point comparisons). Not verdict-setting.
- The same band decides supported positivity and supported nonpositivity. A deterministic critical value is used because, at B = 999, a percentile at the Bonferroni level (two-sided tail 0.05/66, about 0.08% per tail) rests on about one draw, and the sup-t quantile (98.333%) on about 17 draws.
- **Coverage is not claimed.** The statistic is a median of ratios whose denominator M_i·M_j can be near zero, and its bootstrap distribution can be heavy-tailed. Normal intervals with bootstrap SE are a stated approximation. The pre-specified diagnostics (§5C) show the departure from normality but cannot establish the coverage error, and no interval is switched because of them.

**Failed draws (symmetric, nothing silently dropped).**
- In a draw, the annual centre c*_p,t is *undefined* if the year-t regression is rank-deficient (any NA coefficient), the replicate has no estimation rows in year t, or no household HEC_p in year t is finite.
- A draw is *valid for claim k* (F7: FS; F8: FK; F9: SK) when all 22 annual centres for that pair are defined. The sign row and the reported comparison of claim k use the same valid-draw set.
- Let V_k = number of valid draws. If V_k ≥ 0.99·B (≥ 990 of 999), intervals use those draws. If V_k < 990, the sign row of claim k is **not-testable (row 0)**, whatever the direction of the estimate. **Provenance:** 1% is the card's own rule, fixed before any bootstrap was run; no failure rate has been seen. Failure counts are reported by year and pair.
- **Zero SE.** A year with se_t = 0 has L_t = U_t = c_t, flagged; the rules then apply to the point value (c_t > 0 gives L_t > 0; c_t ≤ 0 gives U_t ≤ 0).
- **Non-finite household HECs** (M_i·M_j = 0) are excluded from that year's median, as in S3, and counted per year (full data and mean over draws).
- **The same failure rules apply in every sensitivity that uses draws** (§5, item 6; §5C diagnostics): the valid-draw count is reported, the interval is shown only if V ≥ 0.99·(draws), and otherwise is "not available". Point-only sensitivities report "not computable" for an undefined fit or centre; none is imputed.

**Monte Carlo precision.** The valid draws, in draw order, are split into 10 consecutive batches of floor(V_k/10). Each verdict-relevant bound (L_t and U_t for the decisive years) is recomputed within each batch (se within the batch, point estimate fixed at the full-data value); MC SE = SD over batches/√10. Any bound within 2 MC SE of 0 is flagged "MC-fragile", whichever side it falls on. The flag does not change the verdict (B cannot be raised under the cap).

**Run-time.** About 22,000 OLS fits on 840–1,428 rows; expected well under 30 minutes.

## 5. Sensitivities (exhaustive; reported, never verdict-setting)
Unless stated otherwise each item gives point estimates only (the three pooled centres and the 22 annual centres per pair, with the count of years with c_t ≤ 0), on the full data, varied one at a time from the primary. Items that change the estimand are labelled so.

**5A. Same population, alternative readings of the unrecoverable specification.**
1. **Zero dummies (Battese 1997):** inputs ln(max(x, 1)) plus a dummy for x = 0 for each input that has zeros, entered linearly; HEC from the translog coefficients as in §3. **Qualification:** Battese (1997) validates estimation with zeros, not the derivatives at zero. Here the HEC for a household with x = 0 is evaluated at ln(max(x,1)) = 0, a **boundary convention with no economic interpretation at zero inputs**. Report separately the centres computed from rows with all inputs positive, where the convention does not bite.
2. **Five-year window regression:** years t−2…t+2 pooled with year dummies, HEC evaluated for year-t rows (the S3 `ma5_window` variant).
3. **Five-year moving average of annual centres:** centred average of c_t over the available years in t−2…t+2.
4. **5%-trimmed mean** of household HEC in place of the median (the paper says "mean").
5. **Untrimmed mean** of household HEC (flagged unstable where M_i M_j ≈ 0).
6. **Cluster-bootstrap design with B = 199 draws on items 1 and 2:** the §4 band, reported as a sensitivity only, under the same failure rule (valid-draw count; shown only if ≥ 0.99·199 = 198 valid).
7. **Joint variation:** zero dummies (item 1) and the five-year window regression (item 2) applied together (S5 identifies both ambiguities; one-at-a-time checks miss their interaction).

**5B. Changed population, period or estimand (A4d; never verdict-setting).**
8. 1828 excluded (p.6).
9. Slave-owning households only (the paper's robustness sample).
10. **Ordinary logs** using the file's log variables, missing at zero (Codex F01): only households with all inputs positive.
11. Monotone evaluation points only: household rows with M_i ≤ 0 or M_j ≤ 0 dropped before the median, per pair.
12. Households linked both before and after 1814 (`index` observed in some year < 1814 and some year > 1814; 7,680 rows in S3), as the closest available reading of the paper's 1814 sample.

**5C. Diagnostics (not verdict-setting).**
13. **Bootstrap-distribution diagnostics** for each annual centre: skewness, excess kurtosis, the ratio of the bootstrap SD to 1.4826·MAD, the share of draws with |c* − c| > 5·se, and the number of draws with |c*| > 10. Report only.
14. **Percentile intervals** (type 7, at the same two-sided level α = 0.05/66) and a **sup-t band** from the primary draws: c = type-7 quantile at 1 − 0.05/3 of max_t |c*_t − c_t|/se_t within a pair. Coordinates (years) with se_t = 0 are excluded from the max, not the draw, and counted; if no coordinate of a pair remains, the band is "not available". Ties are handled by type-7 interpolation. Report only; no verdict is switched to these.
15. **The S5 design:** iid household resampling within years, B = 999, for comparison with the cluster design.
16. Per-year counts of household rows with M ≤ 0 by input, and of non-finite HECs.
17. **D2, Cobb–Douglas in shifted inputs (exploratory).** For each year, the HC1 Wald statistic W = (R b)′ (R V R′)⁻¹ (R b) for H0: all six second-order coefficients of the year-t translog are 0, with V the HC1 covariance of the unrestricted OLS fit, referred to χ²(6). Report the 22 statistics and the unadjusted 5% rejections as a count; labelled **exploratory, not adjusted for 22 tests**. Zero second-order terms describe a Cobb–Douglas technology in (1+x), not in the raw inputs. The v1 cluster-bootstrap version is withdrawn (null-centering was unspecified; §9).

The 6% output scale (S5-12) is not a sensitivity: it is absorbed by the intercept.

## 6. Fixed choices
- No weights. No trimming in the primary.
- Missingness: rows with missing lq, lk, ls or lf are dropped from that year's regression (listwise, as S3); Tot_prodfl ≤ 0 counts as missing.
- Year set: all 22 data years 1805–1828 for the sign rows and F7-pt, F8-pt; 1811–1817 for F9-pt.
- Verdict comparisons use unrounded values; results are reported to 3 dp.
- Software: R 4.5.2, `stats::lm`, quantile type 7.

## 7. Margins (A8 defaults; none chosen by the card author)
| Row | Type (A8) | Margin |
|---|---|---|
| F7-s, F8-s, F9-s (primary) | threshold, "positive … throughout" = every period | c_t > 0 at each of the 22 years (T = 0, strict) |
| F7-pt (reported) | point, 0.85, ±10% | [0.765, 0.935] |
| F8-pt (reported) | point, 0.8, ±10% | [0.72, 0.88] |
| F9-pt (reported) | point, 0.9, ±10% | [0.81, 0.99] |

- The band is closed; the threshold is strict. A8a does not apply (HEC is not on [0, 1]).
- **No ceilings.** The A8 plausibility flag (estimate > 1.5× the stated value) is reported for the point comparisons and does not decide anything.
- Neither the digitising error recorded by the second extractor (about ±0.2) nor any S5 interval justifies widening the ±10% bands. They are kept as defaults and are not verdict-setting (§8C).
- A3's 50% magnitude floor does not apply: the authors state no magnitude in words, and A8 gives the threshold T = 0.

## 8. Verdict rules (primary analysis only; the first rule that applies decides; exhaustive)
Every verdict is read **"on the S3 reconstruction"** (§0).

### 8A. Sign rows F7-s, F8-s, F9-s
Annual centres c_t; band [L_t, U_t], t over the 22 years. For each year exactly one of the following holds: U_t ≤ 0 (supported nonpositive), L_t > 0 (supported positive), or L_t ≤ 0 < U_t (unsupported either way).

| # | Condition | Verdict |
|---|---|---|
| 0 | the §4 reproduction check fails, any c_t is not computable on the full data, or V_k < 990 | not-testable |
| 1 | **supported nonpositive year:** U_t ≤ 0 for at least one t | weakened (flag: "supported nonpositive year; overturned unreachable under A4b") |
| 2 | **supported positivity everywhere:** L_t > 0 for every t | confirmed (on the S3 reconstruction) |
| 3 | no row above applies (every U_t > 0, some L_t ≤ 0, i.e. positivity unsupported in at least one year) and **all** c_t > 0 | qualified (inference-fragile: positive throughout in the point estimates, not simultaneously supported) |
| 4 | no row above applies, and **some** c_t ≤ 0 | weakened (a nonpositive point estimate that the band does not exclude from being positive) |

- L_t = 0 is not positivity (strict); U_t = 0 counts as supported nonpositive.
- Rows 1–4 partition every case not caught by row 0: row 1 if any year is supported nonpositive; otherwise row 2 if all years are supported positive; otherwise row 3 or 4 by the sign of the point estimates. Rows 1 and 4 map to weakened; "overturned" is unreachable.

### 8B. Claim verdict
The claim verdict for F7, F8 and F9 **is the verdict of its sign row**. F7, F8 and F9 are reported separately and not aggregated. **INT:** not-testable.

### 8C. Reported point comparisons (not verdict-setting; no row votes)
For each of F7-pt, F8-pt and F9-pt, report the pooled estimate G, the interval I (§4), the A8 band [b_lo, b_hi] and exactly one status:

| # | Condition | Status |
|---|---|---|
| 0 | G not computable, the §4 check fails, or V_k < 990 | not computable |
| 1 | b_lo ≤ G ≤ b_hi and I ⊂ [b_lo, b_hi] | within the A8 band, interval inside |
| 2 | b_lo ≤ G ≤ b_hi and I ⊄ [b_lo, b_hi] | within the A8 band, interval wider than the band |
| 3 | G < b_lo | below the A8 band (flag "supported" if U < b_lo) |
| 4 | G > b_hi | above the A8 band (flag "supported" if L > b_hi; plausibility flag if G > 1.5× the stated value) |

The status never changes a verdict. It is a descriptive comparison of the rebuild with the digitised figure.

### 8D. Supplementary display
Beside each verdict the report lists the §5 items (point values and counts of years with c_t ≤ 0) and the §5C diagnostics, labelled "reported, not verdict-setting". **Sensitivities never vote.**

### 8E. Disclosure
The card author has seen the following S3/S5 numbers that bear on these verdicts.
- **Rebuild points (= primary points):** F7 0.8359, F8 0.8454, F9 0.9005; all three inside their A8 bands.
- **Annual centres (rebuild):** FS positive in all 22 years (minimum 0.277 in 1805; 2.1–3.1 in 1821, 1823–1825, 1828). FK positive in all 22 (minimum 0.323 in 1828). SK ≤ 0 in five years: 1820 −0.121, 1821 −1.921, 1824 −0.624, 1825 −0.110, 1826 −0.018. **Given row 0 is passed, F9-s is weakened (rule 1 or 4) whatever the intervals show.**
- **S5 within-year iid bootstrap (199 draws, unadjusted 95%):** F7 0.619–1.114, F8 0.649–1.011, F9 0.704–1.212; FS 1805 −0.207 to 0.961; SK 1821 −2.338 to 2.508, 1823 −0.741 to 1.105, 1828 −0.154 to 2.678. The FS 1805 interval includes 0 unadjusted; this bears on F7-s only, and the cluster band may differ. No F7-s or F8-s verdict is predicted.
- **HC1 t-statistics (22 annual fits):** |t| ≥ 1.96 for β_SF in 2 years (both negative), β_KF in 1 (negative), β_KS in 6 (all negative).
- **Sensitivities:** MA5 of annual medians 0.832/0.843/0.955 (SK negative in 4 years); zero dummies 0.837/1.098/1.105 (FS negative in 8 years, FK 1, SK 3); owners only 0.899/0.713/1.129; drop 1828 0.835/0.852/0.901; 5%-trimmed mean 0.765/0.827/0.904 (FK 2, SK 7); ordinary logs (Codex) FS −0.043 with 12 negative years on 6,523 rows; window-regression SK 1821 0.147, 1823 0.021, 1828 0.271.
- **Monotonicity:** M_S ≤ 0 for 23% (1821) and 18% (1828); M_K ≤ 0 for 27% (1819), 37% (1828), 16% (1826); untrimmed SK means −18.0 (1822) and 46.2 (1826).

No cluster-bootstrap interval has been computed, and no cluster count has been tabulated. All margins are A8 defaults. The card author chose no band, threshold or critical value with reference to these numbers; the primary-target change from v1 (sign row only) follows the Codex review and the claims specification's sign-only wording. This disclosure does not prove that nothing was tuned.

## 9. Codex review notes and responses
**Codex v1 review** (reviews/P21_LFG_codex_S6card.md): approve-with-changes, 7 required changes, addressed in v2, except that item 4's audit is only specified, not yet run, at freeze (§10.12).

1. **One primary verdict target per claim (v1 §§1, 8).** The v1 conjunction of a sign row and a digitised-centre row added a numerical gate to sign-only wording. *Fix:* one primary per claim, the sign row (§1, §8A, §8B). The digitised centres become reported point comparisons (§8C) that never vote; the voting family shrinks from six rows to three.
2. **Default margins, no inventions (§7).** *Fix:* T = 0 strict (A8 threshold); ±10% retained only for the reported comparisons; A8a inapplicable; no ceilings; no widening for digitising error or for disclosed S5 intervals. Unsupported positivity is now distinguished from a supported nonpositive year (§8A: rules 1, 3 and 4 are separate). The A4b prohibition on "overturned" is kept and described as protocol-imposed, not evidence-based.
3. **Scope of confirmation (§§0, 3, 8).** *Fix:* every verdict reads "on the S3 reconstruction" (annual, ln(1+x), median); S5-01, -04 and -05 are named as unresolved; shifted-input scale stated in §3; the interpretation row stays separate and untested.
4. **Cluster specification (§4).** *Fix:* `00_cluster_audit.R` and `cluster_audit.csv`, committed before any bootstrap, report cluster counts overall and by year, repeated IDs within years, cluster-size distribution and linkage coverage. The cluster count is not assumed to be 22. Independence across linked households and singleton treatment of unlinked rows are justified, and their weakness is stated (§10). Multiplicities of repeated draws are preserved. The audit documents; it does not gate or switch the design.
5. **Interval validity and numerical rules (§4, §5C).** *Fix:* the normal-interval approximation is stated as such and no coverage is claimed; distribution diagnostics are specified (item 13); sup-t ties and zero-SE handling are specified (item 14); the failed-draw rule applies in every sensitivity that uses draws; multiplicity is recomputed over the three sign rows × 22 years (66 comparisons, z = 3.368); no method is switched after results.
6. **D1 and the zero dummies (§5).** *Fix:* D1 is **withdrawn**, because a σ computed on shifted quantities 1+x is not the substitution between actual labour inputs, and the card does not specify curvature or boundary rules that would make it valid. Zero-dummy HECs at x = 0 are labelled a boundary convention without economic interpretation, with an all-positive-inputs companion (item 1).
7. **D2 (§5C.17).** *Fix:* the HC1 Wald statistic, covariance and reference distribution are specified; the cluster-bootstrap version is withdrawn (null-centering unspecified, and unrestricted rejection frequencies are not null p-values); the test is stated to concern Cobb–Douglas in (1+x); the count of rejections is labelled exploratory and unadjusted.

**Optional suggestions.**
- A joint zero-treatment × five-year-window sensitivity: **adopted** (item 7, non-voting).
- Explain that simultaneous bands are conservative for confirming a conjunction (Berger and Hsu): **adopted** in §10.4. They are not relaxed after inspecting results.
- PPML, weights and independent scenario draws: not applicable.

## 10. Known limitations at freeze
1. **The baseline is a rebuild, not the authors' code.** The original zero treatment, smoothing and summary statistic are unknown; the primary inherits the S3 choices (ln(1+x), annual fits, median). Verdicts are conditional on them (§0). §5A shows how much the annual signs depend on them, but no sensitivity can vote.
2. **F9-s is decided by point estimates already seen** (five nonpositive SK years), so the inference adds nothing to its verdict. This is disclosed, not adjusted. F9-s is weakened provided it passes row 0 (reproduction check, computability, V ≥ 990); otherwise not-testable. No verdict for F7-s or F8-s is predicted: the S5 FS 1805 interval was a within-year iid interval, not the cluster band, and F8 involves FK, not FS.
3. **A4b caps the ladder at weakened.** A supported nonpositive year, a credible null or a reversed sign maps to weakened (flagged), even though a corrected-estimator design would read it as overturned.
4. **Conservative simultaneous band.** Bonferroni over 66 annual comparisons is conservative for confirming "positive in every year" (an intersection–union claim; Berger and Hsu 1996). It favours "qualified" over "confirmed" and over supported nonpositivity, symmetrically. It is not relaxed after the results.
5. **Light inference under the wave-3 cap.** B = 999 rules out percentile quantiles at the Bonferroni level and leaves the sup-t quantile (98.333%) resting on about 17 draws, so the primary uses normal intervals with bootstrap SEs. Annual HEC medians can be skewed and heavy-tailed (1821); the diagnostics show the departure but not the coverage error.
6. **Cluster definition.** Independence across `index` households is assumed; unlinked rows are treated as independent singletons, which understates the dependence if they belong to linked households or to the same farms (the linkage is probabilistic: `mscore`). The aggregate counts are only known once the audit has run.
7. **Failure threshold.** The 1% valid-draw rule is a card choice fixed before any run; intervals below it are conditional on valid draws.
8. **What the intervals omit:** input endogeneity (OLS on inputs the paper itself calls endogenous), linkage and transcription error, and the valuation of livestock output at probate prices.
9. **Digitised centres.** The point comparisons use A8's ±10% bands, tighter than the digitising precision (about ±0.2). They are reported only and decide nothing.
10. **The interpretive claim** (non-substitutability, different tasks) is not testable with the HEC estimand. No substitution-elasticity estimand is offered (D1 withdrawn); the conceptual error is recorded in S5 (S5-03, F02).
11. **Shifted-input scale.** All HECs and the Cobb–Douglas check refer to 1+x inputs; zero-input households are evaluated at the boundary.
12. **Cluster audit not yet run.** `00_cluster_audit.R` and `cluster_audit.csv` do not exist at freeze. The cluster definition is fixed and does not depend on the audit (§4); the audit will be committed before any bootstrap and reports counts only. No aggregate linkage statistics were available to the card author.
