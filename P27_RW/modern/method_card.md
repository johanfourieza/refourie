# Method card: P27_RW, the remarkable wealth of the Dutch Cape Colony

Status: v3 (2026-10-12). Final under A9; no further Codex review. To be FROZEN with the commit message "FREEZE S6 card P27".
- History: v1 → Codex review (reviews/P27_RW_codex_S6card.md; 7 required changes) → v2 → Codex compliance check (reviews/P27_RW_codex_S6card_v2.md; 3 blocking issues) → v3.
- Margins follow AMENDMENTS.md A3, A4, A8 and A8a. All margins are defaults; none was chosen by the card author. No ceilings or bands were chosen from S5 results. The one gate (the 0.0625% undefined-draw rule, §4) was written into the card on 2026-10-12, after S5 had been seen. It is a numerical-stability rule, it is not tied to any S5 number, and it is disclosed in §4 and §8 as such.
- Rights class: open. Scripts read data from `D:\Data\ReplicateMe\P27_RW\` through `tools/paths.R` (A6).

## 0. Type of analysis
The paper has no estimator, standard error or test. Its headline results are descriptive: probate-inventory means of a 28-item index of household assets valued at fixed 1691–1748 median auction prices (Table 5), and one cell of the Table 4 comparison with the opgaafrolle. No original code produces a published table. The reproduction baseline is the S2 Excel-chain re-implementation and the S3 rebuild (`repro_r/`), which agree on every headline cell.

**Two estimands, kept apart.** The claims specification (§c) defines the headline cells as **inventory means**. The prose reads them as facts about **settler households**. These are different statistical targets, and unchanged observations do not make them the same estimand. The card therefore carries two sets of rows, each with its own single primary analysis and its own verdict:
- **Published-estimand rows (H1, H2, H3, H4, H5, H7):** the unweighted probate-inventory statistics the paper prints. Their new content is numerical reproduction (settled at S2/S3) and, for H5 and H7, uncertainty.
- **Settler-household rows (H1w, H2w, H3w, H5w, H8):** the estimand the authors' sentences name, estimated by a post-stratified mean, or (H8) the unconditional slave-ownership margin that the representativeness inference needs. These are labelled `different-estimand` relative to the print.

Neither set is a sensitivity of the other, and the summaries never merge them.

**Classification, per row.**
- **H1, H2, H3, H4:** (i) reproduction of the published estimand. Point rows, no inference.
- **H5, H7:** (ii) **inference-only**. The point estimate is the published one; only uncertainty is added. The A4b ladder applies and **"overturned" is unreachable**.
- **H1w, H2w, H3w, H5w:** (iv) a **new estimator** (post-stratified, calibrated mean) of the settler-household estimand, with (iii) bootstrap uncertainty for H5w. The estimand differs from the print, so the full ladder applies, including "overturned" for H5w.
- **H8:** (iv) a **new estimand** (the unconditional ownership share) for the paper's stated representativeness inference. The full ladder applies. Its conclusion is narrowed to slave ownership (§1).
- **H6, H9, H10:** not-testable.

**Verdicts rest only on the primary analysis of each row (§4).** The sensitivities in §5 are reported and never vote. Changed populations and changed estimands are flagged as such (A4d) and cannot set a verdict.

## 1. Claims family (frozen headline rows) and interpretations
The four `headline = 1` rows (A1 union): `T4_excl_inv_slaves_mean`, `T5_1700_mean`, `T5_1790_mean` and `T5_total_mean`. Interpretations are quoted from `claims/claims_spec.md` and `claims/headline_second.csv`. A cell with both a level and a comparison in the authors' reading gives separate rows.

| Row | Source row | Authors' reading (verbatim) | A8 type | Margin |
|---|---|---|---|---|
| H1 | `T5_1700_mean` = 759 (n = 71) | starting level for the "increase over the century" (p.436) | point | [683.1, 834.9] (±10%) |
| H2 | `T5_1790_mean` = 1,979 (n = 362) | "the high levels of the 1780s and early 1790s" (p.436) | point | [1,781.1, 2,176.9] (±10%) |
| H3 | `T5_total_mean` = 1,650 (n = 2,228) | the Table 5 pre-1801 total | point | [1,485, 1,815] (±10%) |
| H1w, H2w, H3w | the same cells | the same sentences, read as statements about the average settler household (p.446: "the average Cape household") | point | the same three bands, on the post-stratified mean (§3) |
| H4 | `T4_excl_inv_slaves_mean` = 7.49 (n = 1,694) | slave-owning inventories hold 7.49 slaves on average | point | [6.741, 8.239] (±10%) |
| H5 | `T5_1700_mean`, `T5_1790_mean` | "on average, household wealth increased over the century" (p.436) | comparative ">" | D90 = m₁₇₉₀ − m₁₇₀₀ > 0, CI excluding 0 (published estimand) |
| H5w | the same cells | the same sentence, settler-household estimand | comparative ">" | D90w = m̃₁₇₉₀ − m̃₁₇₀₀ > 0, CI excluding 0 |
| H6 | `T5_1700_mean` and Table 5's last pre-1801 row | "there is no evidence to suggest that living standards declined there over the course of the eighteenth century" (p.446) | — | **not-testable** (see below) |
| H7 | `T4_excl_inv_slaves_mean` vs opgaafrolle 7.42 | "a near exact match is recorded for slave ownership" (p.434) | comparative "similar" | R = μ⁺_inv / μ⁺_opg in [0.80, 1.25] |
| H8 | `T4_excl_inv_slaves_mean` (stated inference), narrowed | "this makes a strong case that the Cape probate inventory sample used here is representative of the Cape settler population" (p.434), **judged only on slave ownership** | comparative "similar" (shares) | Δ = π_inv − π_opg in [−0.03, +0.03] |
| H9 | `T5_total_mean` (stated inference) | "not living at a subsistence level" (p.446) | — | **not-testable**: the paper defines no subsistence line on its fixed-price index, and none can be set without an S5-informed choice. |
| H10 | abstract and conclusion | "comparable to some of the most prosperous regions of eighteenth-century England and Holland"; "equal to and often better than" (pp.419, 446) | — | **not-testable**: the comparator cells (T6–T8) are not headline rows, no comparator microdata survive, and the Cape slave classes are not the comparators' wealth classes (F5). |

**H6 is not-testable.** "No evidence to suggest that living standards declined" is a no-decline claim. It does not mean "the end-of-century level exceeds the start", and neither a significant endpoint rise nor a non-significant fall establishes the absence of a decline within the century. A8 has no default margin for "no evidence of X", and any margin would be chosen with the S5 numbers in view (the 17% fall from row 1790 to row 1800 and the further fall in 1801–06 are known). v1 used the endpoint reading; it is withdrawn. The late-century change and the endpoint contrast are reported as descriptive sensitivities (§5, items 14–15) and do not vote.

**Scope of H8.** An equivalence of ownership shares can establish similarity on one margin only. It cannot establish that the inventory sample is representative of settlers in age, wealth within class, district or marital status. The row is worded and reported as "representative with respect to slave ownership".

**Wording.** The index is a **fixed-price asset index** (a quantity index at 1691–1748 prices). The card and `results.md` do not equate it with living standards.

Notation: m_r is the unweighted mean wealth of Table 5 row r, and m̃_r the post-stratified mean (§3). Rows follow the dta `decade` variable, which labels each row by its decade-end year (S5-1): row 1700 = 1673–1700, row 1790 = 1781–90, row 1800 = 1791–1800. μ⁺ is the mean number of slaves among households with ≥ 1 slave; π is the share of households with ≥ 1 slave.

**A4c.** No row is an odds ratio or an OR-based probability. **Stars.** None are printed; `stars05` = 2 (default) and is not used.

## 2. Defects addressed
1. **Probate selection (S5-10, Codex F4; the most consequential defect).** Probate inventories over-represent slave owners: 65.74% own slaves, against 44.47% of opgaaf households in 1700–73. Slaves make up 33–42% of the 28-item value in every decade. The T5 levels are probate-sample means, yet the authors read them as means over settler households. **Fix (conditional, not demonstrated):** post-stratify the inventories to the opgaaf slave-holding distribution under the identification assumptions of §3 (Jones 1980, *Wealth of a Nation to Be*, ch. 2 and app. A; Lindert 1981, "An algorithm for probate sampling", *Journal of Interdisciplinary History* 11(4): 649–668; Gelman 2007, "Struggles with survey weighting and regression modeling", *Statistical Science* 22(2): 153–164). The result is a separate set of rows (H1w–H3w, H5w), not a replacement of the published rows.
2. **Conditional match read as representativeness (F4, interpretation audit).** The 7.49 vs 7.42 match conditions on owning slaves. **Fix:** test the printed comparison (H7, inference only) and the unconditional ownership margin (H8) separately, each with an equivalence test (Schuirmann 1987, *Journal of Pharmacokinetics and Biopharmaceutics* 15: 657–680) against the A8 "similar" default.
3. **Class boundaries (S5-4, F2).** The `group` variable puts 5-slave holders in class 3, while the notes say class 2. The primary weights use the stated boundaries 0 / 1–5 / 6–15 / 16+.
4. **No uncertainty statements.** None of the descriptive claims (rise, match) has an interval. **Fix:** a joint bootstrap of inventories and opgaaf households that respects the opgaaf's temporal dependence (§4).
5. **Not fixed, reported only:** fixed 1691–1748 prices applied to 1673–1800, which cannot be re-derived without the MOOC 10 extraction (S5-9, F8; §5 item 11 removes slave value); possible original/clerk duplicates (S5-8, disputed); the disclosed exclusion of 1801–06 (S5-2); the T7 column transposition and the text errors (S5-3, S5-5 to S5-7, F6, F7), which touch no headline row.

## 3. Estimands and identification
**Data.**
- **Inventory sample.** The 2,577 rows of `numbersandwealth.dta` with non-missing `date`. Wealth y = `wealthrijks`. Slaves s = `slavesnumb`. Table 5 sample = `decade` ≤ 1800 (n = 2,228).
- **Opgaaf sample.** `Opgaafrolle 1 Des 2010.xlsx`, sheet `Data`, `Jaar` in 1700–1773 (n = 15,587). Slaves = the sum of columns 34, 36, 38 and 40 (SM, SV, SS, SD, the second column of each pair), exactly as in `repro_r/01_clean.R`.
- **Classes** k ∈ {0, 1–5, 6–15, 16+}, from s.

**Post-stratification weights (time-balanced).**
- Four fixed time blocks of the overlap: T1 = 1700–1718, T2 = 1719–1736, T3 = 1737–1754, T4 = 1755–1773 (calendar year of `Jaar` for opgaaf, of `date` for inventories).
- Within each block b, p^opg_{k,b} and p^inv_{k,b} are the class shares in the two sources. **Time-balanced shares:** P^opg_k = ¼ Σ_b p^opg_{k,b}, and P^inv_k likewise. Both sources are thereby given the same equal-block time composition. This reduces, but does not eliminate, the dependence of the ratio on the sources' different time profiles: with class-specific selection probabilities s_k and a block normaliser Z_b, p^inv_{k,b} = s_k·p^pop_{k,b}/Z_b, and averaging shares over blocks yields weights proportional to 1/s_k only if Z_b is constant across blocks (I4).
- w_k = P^opg_k / P^inv_k, applied to every inventory in class k, in every row (pre-1801 and the 1806 row alike).
- The blocks were fixed on identification grounds (equal-length quarters of the overlap) before any weight was computed.

**Identification assumptions (conditional on which the post-stratified mean targets the settler-household mean).** All are untestable or only partly testable with these data, and §10 lists them as limitations.
- (I1) **Comparable household definition.** An opgaaf household and a probate estate are the same kind of unit. The paper itself doubts this (young single men in the opgaaf); S5 item 5 changes the opgaaf definition, but it is not a bound on this bias.
- (I2) **Class support.** Every class with P^opg_k > 0 has at least one inventory in each of the four blocks' union (P^inv_k > 0), and every block has at least one inventory. If not, the weights are undefined (§8, rule 0). Class counts per source, block and row are reported, with class-specific wealth means ȳ_{k,r} and the effective sample size (Σw)²/Σw² per row.
- (I3) **Selection into probate is independent of wealth given slave class.** Not testable.
- (I4) **Transportable relative selection, with constant normaliser.** The ratio of an estate's probate probability across slave classes is constant over time, and the overall probate-to-household rate (the normaliser Z_b above) is constant across the four blocks. Only then is w_k ∝ 1/s_k, and only then does it hold for 1673–1700 and 1774–1800 as well as for 1700–73. Time-balancing does not establish (I4); where Z_b varies, the weights are calibration weights that match the opgaaf class mix, and the "w" means are **calibrated inventory means**, not demonstrated household means. Item 4 of §5 relaxes (I4) within the overlap only.

**Estimands.**
- **H1, H2, H3 (published):** m_r = the unweighted mean of y in row r (r = 1700, 1790; pooled Table 5 sample for H3), computed on the full samples.
- **H1w, H2w, H3w:** m̃_r = Σᵢ∈r wᵢyᵢ / Σᵢ∈r wᵢ for r = 1700, 1790. This weighted mean uses the row's own class mix, so it estimates the row's settler-household mean under (I1)–(I4).
- **H3 and time (pooled rows).** The pooled mean (H3, H3w) weights inventories by the sample's own time composition (each inventory counts once, times w_k for H3w). It is **not** a household-population-weighted time average. The authors' "average Cape household" sentence is therefore judged on the sample's time composition; §10 notes this.
- **H5:** D90 = m₁₇₉₀ − m₁₇₀₀. **H5w:** D90w = m̃₁₇₉₀ − m̃₁₇₀₀.
- **H4:** μ⁺_inv = the unweighted mean of s over all 2,577 inventories with s ≥ 1 (the published estimand).
- **H7:** R = μ⁺_inv / μ⁺_opg, with μ⁺_opg = the mean slaves among opgaaf households 1700–73 with ≥ 1 slave (published 7.42).
- **H8:** Δ = π_inv − π_opg. π_inv is the share of all 2,577 inventories with s ≥ 1, and π_opg the share of opgaaf households 1700–73 with ≥ 1 slave. These are the populations of Table 4's zeros-included panel, which the paper prints.
- **Original vs new estimand.** H1–H5 and H7 use the published estimand. H1w–H3w, H5w and H8 use the new estimands named above. The two sets of verdicts are different claims about different quantities and are reported separately.

## 4. Primary analysis (one per row)
**Point estimates** are computed on the full samples as defined in §3. **Point rows (H1–H4, H1w–H3w) are decided on the full-sample point estimate alone.** They have no interval and no bootstrap input, so they cannot be affected by bootstrap failures. Each is reported with its 98.75% bootstrap interval for information only.

**Joint bootstrap (intervals for H5, H5w, H7, H8; information for the point rows).**
- **Inventories:** resampled with replacement within each `decade` row, including the 1806 row, which keeps every row's n fixed. Estates are treated as independent. A year-cluster alternative is reported (§5 item 22).
- (Items 21–22 in §5 cover the opgaaf and inventory dependence sensitivities respectively.)
- **Opgaaf households:** a **circular moving-block bootstrap over calendar years**, block length **5**. 15 block starts are drawn from the 74 years 1700–1773, the 75 resulting years are truncated to 74, and each drawn year carries all its households. Year blocks preserve within-year dependence and the persistence of households across adjacent annual rolls. They do not rely on a household identifier. Fixed block lengths of 1, 3 and 10 and a household-key cluster bootstrap are reported as dependence sensitivities (§5 items 21–22).
- **Reported:** the number of years with at least one opgaaf household, households per year (min, median, max, and the largest year's share), and the number of distinct name keys (`Van` plus `Naam`, normalised) with their cluster-size distribution.
- **Each draw** recomputes P^opg_k, P^inv_k, w_k and every estimand jointly. The two sources are resampled independently of each other. This treats the opgaaf and the probate sample as independent samples of the same population. It preserves the algebraic covariance of the estimands, not any dependence between the sources (§10).
- **B = 9,999** draws, seed `set.seed(20261012)`. Percentile intervals use `quantile(type = 7)` at the Family Q Bonferroni level 1 − 0.05/4 = **98.75%**, i.e. the 0.625% and 99.375% quantiles (about 62 draws in each tail). Monte Carlo precision is reported by repeating the whole bootstrap with seed 20261013 and listing both sets of endpoints. The second run is reported, never used for a verdict.
- **Undefined draws (symmetric failure rule).** A draw is undefined for a quantity if any denominator it needs is zero: P^inv_k = 0 for a class with P^opg_k > 0, a time block with no drawn inventories or no drawn opgaaf years, or no slave owners in the drawn samples. Intervals use the defined draws. The share of undefined draws is reported for every quantity. If it exceeds **0.0625%** (more than 6 of 9,999 draws), every **interval** row using that quantity is **not-testable**, whatever the direction of the estimate. **Provenance and disclosure:** one-tenth of the smallest tail mass used (0.625%), the same rule as in P10. It was selected on 2026-10-12 while writing this card, after S5 had been seen; S5 did not inform the value, which is a fixed fraction of the tail mass, and the rule applies identically to every interval row and to either sign of the estimate. No bootstrap had been run when it was fixed. The rule applies to interval rows only; point rows are governed by their full-sample rule 0.
- **Runtime:** a few minutes at most; no draw involves estimation.
- **Reported (point and interval rows):** n per row; class counts by source, block and row; the weights w_k; the effective sample size per row; the class-specific wealth means ȳ_{k,r}; the share of each row's weighted mean contributed by class 16+; the weight concentration (maximum w_k and the largest class's share of Σw).

**Scripts:** `modern/01_data.R`, `02_primary.R`, `03_sensitivities.R`, `04_verdicts.R`. Each regenerates its output from a clean Rscript session.

## 5. Admissible sensitivities (exhaustive; reported, never verdict-determining)
**Weighting scheme (H1w–H3w, H5w):**
1. **Pooled, not time-balanced,** four-class shares over 1700–73.
2. Two classes (0 vs ≥ 1), time-balanced, on the overlap.
3. The S5 scheme exactly: two classes, inventory shares from all 2,577 inventories.
4. **Time-varying selection:** weights estimated separately for 1700–1736 and 1737–1773 (inventories and opgaaf by the same split). Rows 1700–1740 take the first set; rows 1750–1800 take the second. This relaxes (I4) within the overlap only.
5. **Alternative opgaaf household definition (not a bound on household-definition bias):** opgaaf households restricted to those with a wife recorded (column 26, `V`, > 0). Applied to the weights and to H7 and H8.
6. The `group` variable's boundaries (5 slaves in class 3) instead of the stated ones.
7. Two and eight time blocks in place of four.

**Sample (all wealth rows unless stated):**

8. The 10 exact date-and-28-item duplicates dropped (S5-8; disputed whether they are duplicates).
9. **Changed sample (target changes):** the 49 all-zero inventories dropped. This excludes zero-wealth estates and is not a data-quality correction.
10. **Changed population (A4d):** 1801–06 included. H3 and H3w on all 2,577 inventories.
11. **Changed estimand:** wealth net of slave value (`wealthrijks − slawerijks`), weighted and unweighted.
12. **Changed estimand:** top 1% of wealth (pooled pre-1801) trimmed, weighted and unweighted.

**Shape of the change (descriptive; H6 is not-testable and these do not vote):**

13. OLS slope of y on `date`, 1673–1800, weighted and unweighted, with the same joint bootstrap.
14. **Late-century change** m₁₈₀₀ − m₁₇₉₀ and m̃₁₈₀₀ − m̃₁₇₉₀, with 98.75% intervals (unadjusted for any family).
15. **Endpoint contrast** m₁₈₀₀ − m₁₇₀₀ and m̃₁₈₀₀ − m̃₁₇₀₀, the v1 reading of H6, reported as a descriptive statistic only.
16. Row medians, p25 and p75, weighted and unweighted (the Fig 6 view).

**Representativeness (H7, H8):**

17. **Changed population (A4d):** period-aligned. Inventories dated 1700–1773 only.
18. Mean slaves per household including zeros: the ratio inventories/opgaaf (published 4.92 vs 3.30).
19. The same conditional and unconditional comparisons for cattle, horses and sheep (Table 4's other items).
20. `opgaafrolle.dta` (n = 15,577) in place of the workbook.

**Inference and dependence:**

21. **Opgaaf dependence.** Block lengths 1, 3 and 10 in place of 5, and a **household-key cluster bootstrap** (normalised `Van` + `Naam`; clusters resampled with all their annual records; the name key is fuzzy, so homonyms merge and spelling variants split households).
22. **Inventory dependence.** Inventories resampled in year clusters (by `date`) within each row, in place of independent estates.
23. **Decomposition of interval width.** (a) Opgaaf resampling suppressed, inventories resampled (weights uncertain through the inventory shares); (b) inventory resampling suppressed, opgaaf resampled. Neither treats the weights as known.
24. The second-seed bootstrap (§4) and the interval endpoints from a bootstrap with B = 4,999, to show Monte Carlo stability.

## 6. Fixed choices
- **Samples** as in §3. Table 5 rows follow the dta `decade` (decade-end labels). The pre-1801 restriction is applied as published. Prices are the fixed 1691–1748 medians embedded in `wealthrijks`; they are not re-derived.
- **Missing data.** The 867 undated rows have all 28 counts missing and are excluded (as in S2 and S3). Missing opgaaf slave cells count as 0, as in `repro_r/01_clean.R`.
- **No trimming** in the primary analysis. No gates, ceilings or thresholds beyond A8, A8a and the undefined-draw rule (§4).
- **Multiplicity:** one family of four inferential rows, **Family Q = {H5, H5w, H7, H8}**. All four use 98.75% percentile intervals. For the equivalence rows (H7, H8) this is more conservative than the 1 − 2α TOST interval, and the card accepts that. The point rows have no inference.
- **Boundary rules.** Band endpoints are inside the band. A CI endpoint at exactly 0 counts as "includes 0". A CI endpoint exactly on an equivalence bound counts as inside. A point estimate exactly at a band endpoint counts as inside.
- **Seeds:** 20261012 (primary), 20261013 (precision check only).

## 7. Margins and their provenance
| Row | Confirm | Provenance |
|---|---|---|
| H1, H1w | 683.1 ≤ m̂₁₇₀₀ ≤ 834.9 | A8 point default (±10%) |
| H2, H2w | 1,781.1 ≤ m̂₁₇₉₀ ≤ 2,176.9 | A8 point default |
| H3, H3w | 1,485 ≤ m̂_total ≤ 1,815 | A8 point default |
| H4 | 6.741 ≤ μ⁺_inv ≤ 8.239 | A8 point default |
| H5, H5w | 98.75% CI of D90 (D90w) > 0 | A8 comparative default |
| H7 | 98.75% CI of R within [0.80, 1.25] | A8 "similar" default |
| H8 | 98.75% CI of Δ within [−0.03, +0.03] | A8 "similar" default for shares (π is above 0.30, so A8a leaves ±0.03 unchanged; A8a governs point shares, not comparative-share equivalence) |

Here m̂ is m for the published rows and m̃ for the "w" rows. The "w" rows apply the same bands to the settler-household estimate because the authors attach the printed numbers to settler households in prose.
- No ceilings.
- **Plausibility flag** (reported, never decides): a point estimate above 1.5× the stated value on H1–H4 and H1w–H3w.
- **"Strengthened"** is unreachable on every row: the point rows have no inferential criterion, and the comparative rows have no published interval to tighten.
- **A4b.** H5 and H7 change only the inference. "Overturned" cannot be reached on those two rows.

## 8. Verdict tables (checked in order; the first rule that applies decides; exhaustive)
**Point rows H1, H2, H3, H1w, H2w, H3w** (A8 band [L_B, U_B] on the estimate q = m or m̃):
| # | Condition | Verdict |
|---|---|---|
| 0 | q undefined on the full sample (for the "w" rows: a zero denominator in the weights, per I2) | not-testable |
| 1 | L_B ≤ q ≤ U_B | confirmed |
| 2 | q < L_B | qualified (level below the stated value) |
| 3 | q > U_B | qualified (level above the stated value) |

**H4** (A8 point band on the unweighted μ⁺_inv):
| # | Condition | Verdict |
|---|---|---|
| 0 | computation fails | not-testable |
| 1 | 6.741 ≤ μ⁺_inv ≤ 8.239 | confirmed |
| 2 | μ⁺_inv < 6.741 | qualified (below the stated value) |
| 3 | μ⁺_inv > 8.239 | qualified (above the stated value) |

**H5** (inference-only, A4b ladder; X = D90; "overturned" unreachable):
| # | Condition | Verdict |
|---|---|---|
| 0 | the bootstrap fails, or the undefined-draw share for X exceeds 0.0625% | not-testable |
| 1 | CI of X entirely > 0 | confirmed |
| 2 | CI of X includes 0 | qualified (inference-fragile: the rise is not established at 98.75%) |
| 3 | CI of X entirely < 0 (the interval contradicts the positive published point estimate) | weakened |

**H5w** (changed estimand; X = D90w; full ladder):
| # | Condition | Verdict |
|---|---|---|
| 0 | D90w undefined on the full sample, the bootstrap fails, or the undefined-draw share exceeds 0.0625% | not-testable |
| 1 | CI of X entirely > 0 | confirmed |
| 2 | CI of X entirely < 0 | overturned (wealth fell between the rows) |
| 3 | CI of X includes 0 | weakened (change not established) |

**H7** (inference-only, A4b ladder; band [0.80, 1.25]; "overturned" unreachable):
| # | Condition | Verdict |
|---|---|---|
| 0 | the bootstrap fails, or the undefined-draw share for R exceeds 0.0625% | not-testable |
| 1 | CI of R within [0.80, 1.25] | confirmed |
| 2 | CI of R entirely < 0.80 or entirely > 1.25 | weakened (similarity contradicted by the interval) |
| 3 | otherwise (the CI straddles a bound) | qualified (inference-fragile: similarity not established at 98.75%) |

**H8** (changed estimand; equivalence on Δ; band [−0.03, +0.03]; ownership margin only):
| # | Condition | Verdict |
|---|---|---|
| 0 | the bootstrap fails, or the undefined-draw share for Δ exceeds 0.0625% | not-testable |
| 1 | CI of Δ within [−0.03, +0.03] | confirmed (ownership shares similar; representativeness on other margins not tested) |
| 2 | CI of Δ entirely > +0.03 or entirely < −0.03 | overturned (ownership margins differ; the representativeness inference fails on slaves) |
| 3 | otherwise | weakened (similarity of ownership shares not established) |

**H6, H9, H10:** not-testable.

**Summaries.**
- Coverage: 14 rows (H1–H10 and H1w, H2w, H3w, H5w); 11 assessed; H6, H9 and H10 not-testable. A row that is not-testable by rule 0 (computation or bootstrap failure) is counted as not assessed.
- Every row-level verdict is reported. The weakest verdict is reported separately for four groups, none of which mixes estimands: published levels and the rise (H1, H2, H3, H4, H5, H7); settler-household estimates (H1w, H2w, H3w, H5w); ownership representativeness (H8 alone). Order: overturned < weakened < qualified < confirmed. Not-testable rows are excluded from the weakest-verdict ordering and listed beside it; a group in which every row is not-testable is reported as not-testable. The groups are never merged. (Of the three groups above, only the first mixes row types, and these are all the published estimand.)
- Next to each verdict, `results.md` lists the §5 values for that row, labelled "sensitivity; does not decide".

**Disclosure.** S2, S4 and S5 produced the following numbers before this card was written. All bear on the verdicts.
- **Reproduction:** T5 row means 759.3 (1700), 1,978.7 (1790), 1,650.2 (pre-1801 total); μ⁺_inv 7.486. The published Table 5 means for rows 1700–1800 are 759, 1,479, 1,110, 1,224, 1,817, 2,084, 1,520, 1,557, 1,972, 1,979 and 1,633. Row 1800 is therefore 17% below row 1790 and 2.15× row 1700. The published-estimand rows H1–H4 are therefore confirmed in advance by the S2/S3 reproduction; their information lies in the reproduction itself, and the card's new content is in H5, H7 and the "w" rows.
- **S5 reweighting** (two classes, inventory shares from all 2,577): total 1,325.1, row 1700 496.8, row 1790 1,594.9; the rise is 3.2× against 2.6× unweighted. The four-class, time-balanced weights of the primary analysis have **not** been computed. Their direction, though not their size, is predictable from these numbers: the "w" levels are likely to fall below the stated values. The decision to carry the settler-household estimand as separate rows was made knowing this, and a miss is the card's own finding, not a tuning outcome.
- **Ownership:** 65.7% (Codex 65.74%) of inventories vs 44.5% (44.47%) of opgaaf households own slaves, Δ ≈ 0.21. Mean slaves including zeros: 4.92 vs 3.30. Zero-slave shares: 34.3% vs 55.5%. H8 is therefore expected to be overturned.
- **Other:** wealth net of slaves 1,065.5 (total), 466 (1700), 1,298 (1790); slaves are 33–42% of value in every decade. With 1801–06 included the total is 1,578.7, and the 1806 bin has mean 1,122. With duplicates dropped the total is 1,653.1. Class-boundary correction: T6 1711–50 class 2 rises from 18.78% to 20.39% (non-headline).

No interval, no four-class weight, no time-balanced weight, no period-aligned comparison and no wife-restricted opgaaf statistic has been computed. The opgaaf `Van` and `Naam` column headers were inspected to confirm that a name key exists; no values were summarised.

## 9. Codex review notes and responses
**Codex v2 compliance check** (reviews/P27_RW_codex_S6card_v2.md): revise-again with 3 blocking issues, all handled in v3: (a) weight identification: the claim was weakened, I4 now requires a constant normaliser, and the "w" rows are described as calibrated inventory means (§3, §10.1); (b) the undefined-draw gate is disclosed with its date and S5 independence (opening, §4); (c) summaries are split into four non-mixing groups, with H8 alone and a rule for not-testable rows (§8).

**Codex v1 review** (reviews/P27_RW_codex_S6card.md): approve-with-changes, 7 required changes and 2 optional suggestions, all addressed in v2.
1. **Weighting target and identification assumptions.** §3 now states four assumptions (I1–I4: comparable household definition; class support; selection independent of wealth within class; transportable relative selection). The pooled overlap ratio is replaced by **time-balanced shares** over four fixed blocks of 1700–73, so the two sources share a time composition. The card describes post-stratification as conditional, not as a demonstrated correction (§2, §3, §10).
2. **Numerical reproduction vs population interpretation.** The rows are split (§0, §1). H1–H5 and H7 carry the **published** inventory-mean estimand; H1w–H3w, H5w and H8 carry the **settler-household** (or unconditional-ownership) estimand and are labelled `different-estimand`. Each claim has one primary, the verdicts are separate, and the summaries never merge them. H3's temporal weighting is defined (the sample's own time composition, §3), and the index is called a fixed-price asset index, not living standards.
3. **H6.** The positive-growth reading is withdrawn and H6 is **not-testable**: A8 has no default for "no evidence of X", and any margin would be chosen with the S5 numbers known. The late-century change and the endpoint contrast are descriptive sensitivities (§5 items 14–15).
4. **Bootstrap dependence.** The opgaaf side now uses a circular moving-block bootstrap over years (block length 5), with block lengths 1, 3, 10 and a household-key cluster bootstrap as pre-specified sensitivities. The card reports occupied years, cluster sizes and name-key counts. It states the independence assumptions across estates and across sources, and what the joint recomputation does and does not preserve (§4, §5 items 21–22, §10).
5. **A4(b) contradiction and H8 scope.** H5 and H7 change only the inference and use the A4b ladder with "overturned" unreachable (§0, §8). H8 is classified as a new estimand, so the full ladder applies. Its conclusion is narrowed to slave ownership. A8's symmetric bands are kept, and A8a is shown not to alter the comparative-share band (§7).
6. **Numerical reliability and failure rules.** B is raised to 9,999 (about 62 draws per tail); the quantile type is fixed (type 7); Monte Carlo precision is reported through a second-seed run and B = 4,999 (§4, §5 item 24). Point rows are decided on the full sample only, and the undefined-draw rule applies to interval rows only, so the two rules no longer conflict. The 0.0625% threshold is the P10 rule, fixed before any bootstrap. No results-informed gate was added.
7. **Sensitivity labels and mechanics.** The wife restriction is relabelled "alternative household definition (not a bound)"; trimming and the all-zero drop are labelled changed estimand or changed sample. The old S19 is replaced by a decomposition in which neither side is treated as known (item 23), and dependence sensitivities are added (items 21–22). PPML and fixed-effects concerns do not apply: there is no regression in the primary analyses.

**Optional suggestions.** Class-specific wealth means, effective sample sizes and weight concentration are reported (§4). Under A9, v3 is a compliance check only, and unresolved identification limits are listed in §10.

## 10. Known limitations at freeze
1. **Identification of the settler-household estimand.** Assumptions I1–I4 (§3), including a constant probate normaliser across blocks, are not testable with these data, and time-balanced share ratios are not generally inverse-selection weights. The "w" rows are calibrated inventory means, conditional on them, and a miss or a confirmation is a statement about the weighted estimand, not a demonstration that the selection correction is right.
2. **Household definition (I1).** The opgaaf counts some young unmarried men as households, which inflates the zero-slave share and makes the weights over-correct. Sensitivity 5 changes the definition; it does not bound the bias.
3. **Time-invariant relative selection (I4).** The weights are estimated on 1700–73 and applied to 1673–1700 and 1774–1800. Time-balancing handles composition within the overlap only, and nothing can test selection outside it.
4. **Selection on slave class only.** Probate selection by age, wealth within class, district or marital status is not corrected. Slave class is the only covariate observed in both sources.
5. **Predictable outcome.** S5's two-class reweighting put all three levels 20–35% below the stated values, and the unconditional ownership gap is about 0.21. The "w" rows and H8 are likely to miss their bands. The published-estimand rows H1–H4 are confirmed in advance by reproduction (Disclosure). The Disclosure states this.
6. **H3 and time.** The pooled mean takes the sample's own time composition, not a household-population time average. The authors' "average Cape household" is not defined over time in the paper.
7. **Prices.** Fixed 1691–1748 medians make the index a quantity index. The medians cannot be re-derived (S5-9, F8), and no price uncertainty is propagated. Sensitivity 11 removes slave value only.
8. **Bootstrap dependence.** Year blocks of length 5 approximate the persistence of households in the opgaaf, and the name-key cluster bootstrap relies on a fuzzy key. Estates are treated as independent, and the two sources are resampled independently. Dependence between the sources (the same population in the same years) is not modelled. Sensitivities 21–23 show how much the intervals move, but no resampling scheme is correct by construction.
9. **Monte Carlo resolution.** With B = 9,999 the 98.75% endpoints rest on about 62 draws per tail. Verdicts use the primary seed only. The second seed is reported, not a gate.
10. **Equivalence rows.** H7 and H8 use the Bonferroni 98.75% percentile interval rather than a 1 − 2α TOST interval, which is more conservative. The A8 bands are defaults, not conclusions about economic similarity.
11. **H6, H9 and H10 are not-testable,** so the card cannot assess the abstract's central comparative sentence, the subsistence statement or the no-decline sentence. The comparative tables (T6–T8) fail the paper's own wording in places (F5), but no inferential test is possible without comparator microdata. H8 speaks to slave ownership only.
