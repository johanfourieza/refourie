# Method card: P26_NF, black disenfranchisement in the Cape Colony, 1886–87

Status: v3 (2026-10-12), final under A9. Revised after the Codex compliance check of v2 (`reviews/P26_NF_codex_S6card_v2.md`; three blocking issues and one minor edit, all resolved in §9b). To be frozen with the commit message "FREEZE S6 card P26" (A9).
- Margins follow AMENDMENTS.md A3, A4, A8 and A8a. No band, ceiling or gate is chosen by the card author.
- Rights class: open. Runtime: the primary analysis is arithmetic on published cells and runs in seconds. The wave-3 limits (under 30 minutes; at most 999 draws) are met without any concession.

## 0. Type of analysis
The primary analysis is **(i) a correction of a verified data error**. The published 1886–87 falls subtract a 16-division 1887 total from a 14-division 1886 total (S5-1 / Codex F1). Both models confirmed the error by rerunning the arithmetic. The correction restricts both years to the divisions with a roll in both years.
- It is not (ii), an inference-only upgrade: the point estimates change, so A4b does not apply.
- It is not (iii): the counts are complete enumerations of the rolls, so there is no sampling uncertainty to propagate. The dominant uncertainty, classification and roll-completeness error, cannot be quantified (§10).
- It is not (iv), a new estimator: the estimator, a difference of registration counts, is the authors'.
- **No original code survives** (S1; S2 not attempted). The S3 rebuild (`repro_r/`) cannot produce the totals, because six divisions' rolls are missing (decisions D7). The primary analysis therefore uses the **published per-division cells** of Tables 1 and 2. All 200 cells were verified against the authors' surviving source tables (`Tables and figures.docx`; S5 check c4, both models). The rebuild enters only the classification sensitivity (§5 S5).
- **Inapplicable machinery, stated explicitly:** clustering, wild bootstrap, PPML, fixed effects, regression weights and multiplicity correction do not apply. There is no regression, no sampling process and no estimated parameter.
- The paper makes no odds-ratio or probability claims, so A4c does not apply. It prints no stars (`claims/stars05.txt` = 2, unused).

**Verdicts rest only on the primary analysis (§4, §8).** There is one primary analysis per claim. Every sensitivity in §5 is reported and never decides, qualifies or votes on a verdict. Changed populations (S2, S4) cannot decide a verdict (A4d).

**What a verdict means (A8 inference exception).** A8 requires a CI excluding 0 for comparatives. No CI exists here (§4 C). Every verdict in §8 is therefore a statement about **arithmetic on the published per-division cells, conditional on the authors' classification of voters and on the completeness of their rolls**. A "confirmed" verdict says that the corrected arithmetic satisfies the stated inequality or band. It does not confirm that the Act caused the fall, that the fall equals the number disenfranchised, or that the classifications are right. Each results table carries this label.

## 1. Claims family (headline rows, frozen at S0) and interpretations
There are six `headline = 1` rows in `claims/claims.csv`: `T1_Total_1886` (7,159), `T1_Total_1887` (4,334), `T2_Total_1886` (35,013), `T2_Total_1887` (27,079), `TX_black_fall_1887` (2,825) and `TX_white_col_fall` (7,934). The interpretations are quoted from `claims/claims_spec.md` (b)–(c).
- Wording-level sub-rows are **not independent claims**. They split the wording attached to one S0 headline into separate checks, each with one A8 type and one margin. Every sub-row maps to exactly one headline (table below). Coverage and the weakest verdict are reported at **both** levels (§8).
- Throughout, **B** is the net 1886–87 fall in registered black voters and **W** the net fall in registered white/coloured voters, **both measured across the comparable divisions 𝒟 (§3)**. Neither is a count of persons who lost a vote.

**Level rows (S0 headlines, four Total cells).**

| Sub-row | S0 headline | Claim | A8 type | Status |
|---|---|---|---|---|
| L-B86 | `T1_Total_1886` | 7,159 black registrations in 1886 | point count | **not-testable** (§4 E) |
| L-B87 | `T1_Total_1887` | 4,334 black registrations in 1887 | point count | **not-testable** |
| L-W86 | `T2_Total_1886` | 35,013 white/coloured registrations in 1886 | point count | **not-testable** |
| L-W87 | `T2_Total_1887` | 27,079 white/coloured registrations in 1887 | point count | **not-testable** |

**Black fall, headline `TX_black_fall_1887`.**

| Sub-row | Wording (page) | A8 type | Margin |
|---|---|---|---|
| B-pt | "the total number of black voters fell by 2,825" (p.465) | point count | 2,542.5 ≤ B ≤ 3,107.5 (±10% of 2,825) |
| B-rng | "reduced black voter registrations by between 2,800 and 3,000" (p.456) | threshold pair | 2,800 ≤ B ≤ 3,000 (T = the authors' bounds) |
| B-lt | "fewer than 3,000 blacks were disenfranchised" (p.467); "less than a tenth of the figure of 30,000" (p.465) | threshold (ratio B/30,000 < 0.1) | 0 < B < 3,000 |
| B-ten | "around a tenth of that number" (abstract) | point on a ratio in [0,1]: B/30,000 ≈ 0.10 | A8a: the smaller of ±0.03 and ±10% of 0.10, so ±0.01, so 2,700 ≤ B ≤ 3,300 |
| B-cmp | "much smaller than the 30,000 blacks that several authors claim" (p.467) | comparative "<", premise B > 0 | 0 < B < 30,000. A8 has no default for "much", so only the inequality is tested. B-lt and B-ten carry the authors' own magnitude. |
| B-causal | "the 1887 Act reduced black voter registrations by …" (p.456); "much less effective than the earlier literature claims" (p.468); resistance as the explanation (abstract) | causal | **not-testable** |

The p.466 wording "the correct number is probably closer to 3,000" is a hedged inference about a latent count, not a stated band. It is **not** a separate row and receives no equivalence criterion. Its numeric content (3,000 = a tenth of 30,000) is the centre of B-ten.

**White/coloured fall, headline `TX_white_col_fall`.**

| Sub-row | Wording (page) | A8 type | Margin |
|---|---|---|---|
| W-pt | "fell from 35,013 in 1886 to 27,079 in 1887, a difference of 7,934" (p.467) | point count | 7,140.6 ≤ W ≤ 8,727.4 (±10% of 7,934) |
| W-cmp | "the same Act disenfranchised more white and coloured voters than it did blacks" (p.456) | comparative ">", premises W > 0 and B > 0 | W − B > 0 with both falls positive |
| W-causal | "a large fraction of the 7,934 fewer voters were disenfranchised by the 1887 Act" (p.467); "larger than expected" (abstract); recession and white poverty as the explanation (abstract) | causal | **not-testable** |

**Mapping to S0 headlines.**

| S0 headline | Sub-rows |
|---|---|
| `T1_Total_1886` | L-B86 |
| `T1_Total_1887` | L-B87 |
| `T2_Total_1886` | L-W86 |
| `T2_Total_1887` | L-W87 |
| `TX_black_fall_1887` | B-pt, B-rng, B-lt, B-ten, B-cmp, B-causal |
| `TX_white_col_fall` | W-pt, W-cmp, W-causal |

The non-headline rows (`TX_black_fall_tenth`, `TX_black_fall_lt_tenth`, the 1892 Act rows) are not in the family. Their wording enters only as the interpretation of `TX_black_fall_1887` (B-lt, B-ten).

## 2. Defects addressed
Taken from the S5 findings as reconciled in `audit.md`.
- (a) **Unlike division sets** (S5-1, F1; agreed). Griqualand East (black 598, white/coloured 1,149) and Thembuland (375, 1,106) have no 1886 roll, yet enter the 1887 totals. The published falls therefore count those divisions' entire 1887 electorates as gains in registrations. **Fixed in the primary analysis.** The rule follows from the definition of a change over a fixed set of units; the reference is the standard like-for-like comparison of panel totals (Deaton 1997, ch. 1, on comparing survey aggregates across rounds with different coverage).
- (b) **Method switch** (S5-2, F4; agreed). Uitenhage and Victoria East are formula-counted in 1886 and manually counted in 1887. Dropping them changes the population, so the check is a sensitivity (S2) under A4d, as Codex also classifies it.
- (c) **Classification and roll completeness** (S5-3, F3, S5-4, S5-10; the substance is disputed). The surname formula, its normalisation and its dictionary are lost. Published counts depart widely from any matching rule tried on the surviving rolls, and the surviving rolls themselves differ from the published roll totals. **Not fixable.** Reported in sensitivities S5, S6 and S9. Background on measurement error in name-based ethnic classification: Mateos (2007); Fiscella and Fremont (2006).
- (d) **No counterfactual** (S5-5, F2; the severity is disputed). A raw before–after difference does not identify the effect of the Act (Shadish, Cook and Campbell 2002, ch. 4, on one-group pretest–posttest designs). **Not fixable** with these data: there is no untreated comparison group and no linkage of individual voters across rolls. The causal rows are not-testable. The benchmark against the white/coloured rate is reported as a different estimand (S7).
- (e) **The 1889 column sum** (S5-6, F7). Not in the family. Not addressed.

## 3. Estimands
- **Comparable set** 𝒟 = the divisions with a numeric entry in all four cells T1-1886, T1-1887, T2-1886 and T2-1887 of `claims/claims.csv`, excluding the `Total` row. It is computed by that rule, not by a list, **after** the key assertions of §4 B step 1 pass. The expected result is 14 divisions: all except Griqualand East and Thembuland.
- **B** = Σ_{d∈𝒟} T1_d,1886 − Σ_{d∈𝒟} T1_d,1887.
- **W** = Σ_{d∈𝒟} T2_d,1886 − Σ_{d∈𝒟} T2_d,1887.
- **Δ** = W − B (W-cmp). **R** = 30,000 − B (B-cmp).
- **Interpretation of B and W (narrowed).** B and W are **net changes in registered voters in the 14 divisions for which both rolls are available**. They are not losses among an identified 1886 electorate. The absence of an 1886 roll for Griqualand East and Thembuland does not show that no one held a vote there, and the rolls are not linked across years, so a net fall can hide gross removals and new registrations. The correction removes a coverage mismatch in the authors' arithmetic. It does not make the net fall equal "the number who lost the right to vote".
- **Original estimand:** the same differences, but with the 1887 sums over all 16 divisions (published: B = 2,825, W = 7,934). Restricting to 𝒟 is a change of the **accounting population** that restores like-for-like coverage. Under A4d it is the corrected primary analysis (the original claim's arithmetic is internally inconsistent), and the 16-division readings are reported as S1 and S4 and never decide a verdict.
- All quantities are registration counts. No B, W or Δ row measures disenfranchisement caused by the Act (§1, causal rows). Gross-removal and colony-wide claims (p.465 extrapolation to the colony) are **not-testable** and not in the family.

## 4. Primary analysis
**A. Data.** `claims/claims.csv` (frozen at S0), rows `T1_<div>_1886`, `T1_<div>_1887`, `T2_<div>_1886` and `T2_<div>_1887`, column `reported_value`. These cells equal the authors' `Tables and figures.docx` cell for cell (S5 c4). The script re-runs the c4 cross-check and reports any mismatch. If there is a mismatch, the journal values decide, because the claim is the published one.

**B. Computation.** `modern/01_primary.R`:
1. **Key assertions, before any filtering.** `claims/claims.csv` omits N/A cells (`claims_spec.md`, header), so a blank printed cell has no row. The expected key set is frozen here by rule: the 16 division names that occur in the `T1_<div>_1887` rows (`claims_spec.md` holds no separate list), crossed with tables T1 and T2 and years 1886 and 1887, giving 64 keys. For each key, assert that exactly one record exists and that `reported_value` is a parseable non-negative integer. **Exactly four keys are structurally absent and are accepted as absent:** `T1_Griqualand East_1886`, `T2_Griqualand East_1886`, `T1_Thembuland_1886` and `T2_Thembuland_1886` (the printed table leaves these blank; `Tables and figures.docx`). The script materialises them in memory as NA with the flag `structural`. Any other missing key, any duplicate key, any record present for one of the four structural keys, any literal "N/A" and any malformed value is an **integrity failure**. If the 1887 column does not yield 16 names, that is an integrity failure.
2. Build 𝒟 by the rule in §3.
3. Compute B, W, Δ and R, and the published-set analogues as a check (2,825 and 7,934).
4. Report |𝒟| and the names of the divisions in it, and the four structural keys.
5. Check that each column's division cells sum to its printed `Total`. Where they do not, the division sums are used and the gap is flagged.

**C. Inference (A8 exception, justified).** None. The counts are complete enumerations of the transcribed rolls. Complete enumeration removes sampling uncertainty. It does not remove measurement error (classification, roll completeness) or causal uncertainty (Abadie, Athey, Imbens and Wooldridge 2020 on design-based versus sampling-based uncertainty). A3 condition 2 ("95% CI excludes 0") and A8's "CI excluding 0" for comparatives cannot be computed. Comparatives are therefore decided on the sign of the point difference, and §0 labels every verdict as conditional arithmetic on the published cells. This is a design fact, not a margin choice.

**D. Failure rules (symmetric; no automatic verdicts after an integrity failure).**
- **Integrity failure (§4 B step 1), or 𝒟 empty, or a cell needed for a row non-numeric:** all rows that need the affected cells are **not-testable**, and the script halts before computing B, W, Δ, R. The failure is logged in `modern/DEVIATIONS.md` and reconciled against `Tables and figures.docx` by hand. A reconciled input requires a logged deviation with its reason, and no verdict is issued until it is.
- **|𝒟| ≠ 14 with all key assertions passing:** this is an unexpected coverage change. It is logged, flagged in `results.md` and reconciled. The primary rule still applies to the 𝒟 it produces only after the reconciliation entry exists. Without one, the affected rows are not-testable.
- **A docx–journal mismatch** is flagged, and the journal value is used.

**E. Level rows.** The four Total cells are not-testable at S6.
- They are internally consistent: each equals its column sum (S5 c2).
- An independent re-measurement is impossible. Six divisions' rolls are missing (Aliwal North, Cradock, East London, Fort Beaufort, Graaff-Reinet, Grahamstown). The surname formula, its dictionary and the manual counts are lost (S1 gaps 1–3).
- The partial checks in S5 and S6 cannot stand in for the totals.

**F. Seed.** None is needed in the primary analysis. No sensitivity uses randomness (S1–S9 are deterministic). If one did, the seed would be 20261012.

## 5. Admissible sensitivities (exhaustive; reported, never verdict-setting)
1. **S1, published division sets.** B = 2,825 and W = 7,934 as printed. This is the reproduction benchmark.
2. **S2, method-consistent set (A4d, changed population).** 𝒟 minus Uitenhage and Victoria East, the formula-to-manual switchers per the italic map in `Tables and figures.docx` (S5 c1). B, W, Δ and R are reported.
3. **S3, leave-one-division-out (influence diagnostic only; A4d).** B, W, Δ and R recomputed on 𝒟 minus each division in turn (14 runs). Report the range. The omitted-division populations are changed populations: the runs are influence diagnostics, are never verdict evidence, and the card does not count how many drops would flip a verdict.
4. **S4, 16-division imputation (A4d).** The 1886 cells for Griqualand East and Thembuland are filled in two ways: (a) 1886 = 1887 (no change in those divisions); (b) 1887 value × (Σ_𝒟 1886 / Σ_𝒟 1887), separately for T1 and T2. B, W and Δ are reported. The published figure implicitly sets both divisions' 1886 counts to 0.
5. **S5, classification rules on the surviving rolls (specification frozen here).** The five divisions with recovered rolls in both 1886 and 1887 are Kimberley, King William's Town, Port Elizabeth, Queenstown and Wodehouse. The implementation is `repro_r/01_clean.R` at the commit of the locked S3 rebuild (35b12d7), with 1886 and 1887 sheet assignments as confirmed in S5-8. The frozen specification:
   - **Algorithm (one, as coded in `repro_r/01_clean.R` and `02_analysis.R` at 35b12d7; no token voting).** *Normalisation* `skey`: lower case, non-letters replaced by spaces, the tokens "van, der, de, du, le, la, von, den, ten, te, jun, junr, jr, sen, senr, sr" and empty tokens removed, remaining tokens **concatenated** into one whole-surname key. *Dictionary:* the 1909 records (Voters1 sheet 58; July 2018 sheets 57 and 59) with a non-missing race code, grouped by key, with n = records per key and nb = records per key whose code is in the rule's black-code set. No re-download, no additions.
   - **Rules (each applied to the whole-surname key of a roll record):** (i) "any": black-code set {K, F, I, B}; key is black if nb > 0. (ii) "majority": black-code set {K, F, I, B}; key is black if nb / n > 0.5 (ties and nb = 0 are non-black). (iii) "KF": black-code set {K, F}; key is black if nb > 0. The empty key is never black.
   - **Unmatched and empty surnames:** a record whose key is absent from the black-key set is non-black (white/coloured), and unmatched keys are counted per division and year. The rebuild **drops** records with a missing surname or surname "." before classification; they are in neither the black nor the white/coloured count and are reported as "dropped, empty" per division and year. Records whose key is the empty string after normalisation are retained and counted non-black.
   - **Record integrity checks (F6):** report, per division and year, the number of roll records read, the number dropped by the rebuild's filters and the reason, and the number with empty surnames.
   - **Roll-completeness contrast:** next to each classification result, report the rebuilt total roll size (black + white/coloured) and the published printed total for the same division-year, and the difference. Differences in totals and differences in classification are reported side by side and are **not** separately attributed. The contrast is joint and cannot isolate classification error.
   - Report the black fall and the white/coloured fall on these five under (i)–(iii), next to the published fall on the same five (2,361). The values describe joint sensitivity and are not extrapolated to 𝒟.
6. **S6, 1909 dictionary coverage.** The share of 1886 and 1887 voters, by division, whose normalised surname appears anywhere in the recovered 1909 base (the S5-4 diagnostic; its direction is disputed by Codex).
7. **S7, proportional falls and the white/coloured benchmark (`different-estimand`).** On 𝒟: B/Σ T1_1886 and W/Σ T2_1886. Also the "excess" black fall B − (W/Σ T2_1886)·Σ T1_1886. This is a counterfactual benchmark that the paper does not adopt, so it cannot confirm or overturn any row.
8. **S8, colony-wide context.** The Statistical Register's net fall in registrations for all races, 1886–87 (18,343, as used in the S5 interpretation audit). It is reported as context with the Codex caveat (F2): a net fall does not bound gross removals.
9. **S9, deterministic classification-coupling check.** Because the white/coloured cells are the total minus the black cell, a misclassification between the two groups moves B and W together. On 𝒟, let m be a constant multiplier on both years' black cells with the same amount moved to or from the white/coloured cells (totals fixed). Report B(m) and W(m) on a grid m ∈ {0.5, 0.6, …, 1.5}, and the m at which B(m) = 3,000 and the m at which W(m) = 7,934. Also report the range of B(m) and W(m) over the grid, and the share of the 11 grid points at which each confirm condition of B-pt, B-rng, B-lt, B-ten, W-pt and W-cmp holds (A8 scenario rule). The grid points carry equal weights, which is an assumption and not a probability. This is a scenario table with no draws. It is not a test and not a band, and it never decides a verdict.

No other sensitivity is admissible. The 1891–95 cells and the rebuild's year-map correction (S5-8) concern non-headline years and are outside this card.

## 6. Fixed choices
- **Population:** 𝒟 by the §3 rule. **Years:** 1886 and 1887 columns as printed. **Race groups:** T1 = black and T2 = white and coloured, as the authors define them (T2 = total minus black).
- **Missing data:** the four structurally absent 1886 cells define 𝒟 (§4 B). No imputation in the primary analysis.
- **Weights:** none. **Clustering, fixed effects, PPML:** not applicable. **Multiplicity:** no family correction, because no inferential test is run.
- **Boundary rules.**
  - Band endpoints are inside the band.
  - B = 3,000 fails "fewer than 3,000"; B = 2,800 and B = 3,000 meet "between 2,800 and 3,000".
  - B = 30,000 fails "smaller than 30,000". Δ = 0 fails ">".
  - B ≤ 0 or W ≤ 0 means no fall.
- **Scripts:** `modern/01_primary.R`, `02_sensitivities.R`, `03_verdicts.R`. Data paths go through `tools/paths.R`, and the docx is read from `dpath("P26_NF", "original/2. DEMOCRACY AND DISENFRANCHISEMENT/Tables and figures.docx")`.

## 7. Margins (A8/A8a defaults; none chosen by the card author)
| Row | Confirm | Provenance |
|---|---|---|
| B-pt | 2,542.5 ≤ B ≤ 3,107.5 | A8 point default (±10% of 2,825) |
| B-rng | 2,800 ≤ B ≤ 3,000 | A8 threshold default (T = the authors' stated bounds) |
| B-lt | 0 < B < 3,000 | A8 threshold default (T = 3,000 = a tenth of 30,000) |
| B-ten | 2,700 ≤ B ≤ 3,300 | A8a: B/30,000 is a ratio on [0,1]; the smaller of ±0.03 and ±10% of 0.10 is ±0.01, which equals ±10% of 3,000 |
| B-cmp | 0 < B < 30,000 | A8 comparative default (no CI exists; §4 C), with the positive-fall premise |
| W-pt | 7,140.6 ≤ W ≤ 8,727.4 | A8 point default (±10% of 7,934; a count, not on [0,1]) |
| W-cmp | W > 0, B > 0, W − B > 0 | A8 comparative default (no CI exists; §4 C), with positive-fall premises |

- No ceilings. No gates beyond the positive-fall premise, which is part of the claims' own wording ("fell", "disenfranchised").
- A8a applies to B-ten only. All other quantities are counts.
- **Plausibility flag** (reported, not verdict-setting): B or W more than 1.5× the stated value (B > 4,237.5; W > 11,901).

**Disclosure.** S5 numbers seen before this card, all bearing on the verdicts:
- **The primary analysis was already computed in S5.** On the 14 like-for-like divisions: black 7,159 → 3,361 (B = 3,798, 12.7% of 30,000); white/coloured 35,013 → 24,824 (W = 10,189).
- **S2 (method-consistent set):** black 6,367 → 3,109 (B = 3,258); W = 8,742.
- **Rates:** the white/coloured rate is 22.7% on the published sets and 29.1% like-for-like; the black rate is 53.1% like-for-like; S5 summarised the ranges as 40–53% black against 23–29% white/coloured.
- **S7 excess black fall:** 1,203 (published sets) and 1,715 (like-for-like).
- **Five common divisions:** "any" rule B = 1,049 (36.8%, against 34.1% for white/coloured); "majority" rule 370; published 2,361; loose-match black 1886 sum 3,500 against a published 4,774.
- **Wodehouse:** 400 → 179 (55%) against the published 1,234 → 184 (85%).
- **1909 coverage:** 1886 Wodehouse 56.5%, Victoria East 47.5%, KWT 58.5%, Queenstown 60.1%; 1887 Wodehouse 80.2%, Thembuland 78.4%.
- **Statistical Register:** net colony-wide fall of 18,343.

Because the primary analysis is deterministic arithmetic whose result is listed above, this card cannot be outcome-blind. Its protection against tuning is that every margin is an A8/A8a default tied to the authors' own numbers, and the population rule (§3) follows from the definition of a like-for-like change, not from the S5 values. S9 and the S5 specification are written after seeing S5 results but only add reporting, never verdict rules.

## 8. Verdict tables (primary analysis only; checked in order; the first rule that applies decides; exhaustive)
Every verdict is conditional arithmetic on the published cells (§0). In every table, row 0 covers integrity failures, an empty 𝒟 and non-numeric needed cells (§4 D).

**B-pt**
| # | Condition | Verdict |
|---|---|---|
| 0 | integrity failure, 𝒟 empty, or a needed T1 cell non-numeric | not-testable |
| 1 | B ≤ 0 | overturned (no fall in black registrations) |
| 2 | 2,542.5 ≤ B ≤ 3,107.5 | confirmed |
| 3 | 0 < B < 2,542.5 | qualified (fall below the stated value) |
| 4 | B > 3,107.5 | qualified (fall above the stated value) |

**B-rng**
| # | Condition | Verdict |
|---|---|---|
| 0 | as B-pt | not-testable |
| 1 | B ≤ 0 | overturned (no fall) |
| 2 | 2,800 ≤ B ≤ 3,000 | confirmed |
| 3 | 0 < B < 2,800 | qualified (below the stated range) |
| 4 | B > 3,000 | qualified (above the stated range) |

**B-lt**
| # | Condition | Verdict |
|---|---|---|
| 0 | as B-pt | not-testable |
| 1 | B ≤ 0 | overturned (no fall) |
| 2 | 0 < B < 3,000 | confirmed |
| 3 | B ≥ 3,000 | qualified (threshold missed: at least a tenth of 30,000) |

**B-ten**
| # | Condition | Verdict |
|---|---|---|
| 0 | as B-pt | not-testable |
| 1 | B ≤ 0 | overturned (no fall) |
| 2 | 2,700 ≤ B ≤ 3,300 | confirmed |
| 3 | 0 < B < 2,700 | qualified (below a tenth) |
| 4 | B > 3,300 | qualified (above a tenth) |

**B-cmp**
| # | Condition | Verdict |
|---|---|---|
| 0 | as B-pt | not-testable |
| 1 | B ≤ 0 | overturned (premise fails: no fall in black registrations) |
| 2 | B ≥ 30,000 | overturned (the fall is as large as the literature's figure) |
| 3 | 0 < B < 30,000 | confirmed |

**W-pt**
| # | Condition | Verdict |
|---|---|---|
| 0 | integrity failure, 𝒟 empty, or a needed T2 cell non-numeric | not-testable |
| 1 | W ≤ 0 | overturned (no fall in white/coloured registrations) |
| 2 | 7,140.6 ≤ W ≤ 8,727.4 | confirmed |
| 3 | 0 < W < 7,140.6 | qualified (fall below the stated value) |
| 4 | W > 8,727.4 | qualified (fall above the stated value) |

**W-cmp**
| # | Condition | Verdict |
|---|---|---|
| 0 | integrity failure, 𝒟 empty, or a needed T1 or T2 cell non-numeric | not-testable |
| 1 | W ≤ 0 | overturned (premise fails: no fall in white/coloured registrations) |
| 2 | W > 0 and B ≤ 0 | qualified (the inequality holds only because black registrations did not fall) |
| 3 | W > 0, B > 0 and Δ > 0 | confirmed |
| 4 | W > 0, B > 0 and Δ < 0 | overturned (reversed: more black than white/coloured registrations lost) |
| 5 | W > 0, B > 0 and Δ = 0 | weakened (comparison not established) |

- **"Strengthened" is unreachable on every row.** There is no inference, so no interval can tighten, and the design is not made more credible than a difference of counts.
- **"Weakened" is reachable only on W-cmp.** Without inference, "not supported at the stated level" has no meaning except a tie.
- **L-B86, L-B87, L-W86, L-W87, B-causal and W-causal:** not-testable (§4 E; §2 d). **S7:** different-estimand, reported.

**Summaries (two levels).**
- **Wording level:** 13 sub-rows: 7 assessed (B-pt, B-rng, B-lt, B-ten, B-cmp, W-pt, W-cmp) and 6 not-testable (four level rows and two causal rows). Plus 1 different-estimand extension (S7).
- **Headline level (six S0 headlines):** the four Total headlines are not-testable. `TX_black_fall_1887` and `TX_white_col_fall` are each assessed on their assessed sub-rows. **Rule, checked in order:** (1) if any assessed sub-row of the headline is not-testable, the headline is **not-testable**, because row 0 fires on shared input cells; (2) otherwise the headline is the weakest sub-row verdict in the order overturned < weakened < qualified < confirmed. Every sub-row verdict is listed beside the headline. Coverage reports the number of headlines and of assessed sub-rows that are not-testable. The causal sub-rows (not-testable) are listed and do not enter the weakest-verdict rule. Seven wording checks are not seven independent claims. The synthesis counts headlines, not sub-rows.

## 9. Codex review notes and responses
Review of v1: `reviews/P26_NF_codex_S6card.md` (verdict: approve-with-changes). Seven required changes and two optional suggestions.

| # | Required change | Response in v2 |
|---|---|---|
| 1 | Narrow the estimand explicitly: net registration change in 14 observed divisions, not losses among an identified 1886 electorate; keep causal, gross-removal and colony-wide claims not-testable | §1 definition of B and W; §3 "Interpretation of B and W (narrowed)" replaces the v1 sentence about "the electorate that existed in 1886"; gross-removal and colony-wide claims named as not-testable (§3); causal rows unchanged (§1, §2 d). |
| 2 | Resolve the A8 comparative-inference exception | §0 "What a verdict means" and §4 C: sign-only decisions are justified as conditional arithmetic statements on the published cells, with complete enumeration removing sampling but not measurement or causal uncertainty; each verdict is labelled conditional and confirms no economic claim. |
| 3 | Make verdicts internally consistent (B-cmp confirms when B ≤ 0; W-cmp confirms when both groups gain) | §8: B-cmp now requires B > 0 (B ≤ 0 overturned, premise fails); W-cmp requires W > 0 and B > 0 for "confirmed", with W ≤ 0 overturned and W > 0 with B ≤ 0 qualified. The premise is the claims' own "fell", and no numerical gate is added. The tables are exhaustive. |
| 4 | Correct the A8a explanation; separate "closer to 3,000" | §1 and §7: B-ten is a ratio claim B/30,000 ≈ 0.10, band ±0.01 by A8a (smaller of ±0.03 and ±10% of 0.10), which equals 2,700–3,300 and is unchanged. The p.466 "probably closer to 3,000" wording is dropped as a separate row, because it is hedged inference and carries no stated equivalence criterion. B-pt and W-pt are counts and keep ±10%. |
| 5 | Repair the S5 classification sensitivity | §5 S5 freezes the dictionary version, normalisation, majority denominator, ties, unmatched and empty surnames, and the K/F matching rule; adds F6 dropped-record and empty-surname checks; reports rebuilt against printed roll totals beside every classification result, labelled a joint contrast that cannot isolate classification error. |
| 6 | Prevent silent population changes | §4 B step 1 asserts exactly one record per division-year-table key before filtering; structural N/A is accepted only for the two expected 1886 cells; any other missing, duplicate, malformed or N/A key is an integrity failure. §4 D: integrity failure halts, rows are not-testable, and a coverage change (|𝒟| ≠ 14) needs a logged reconciliation, not an automatic verdict. |
| 7 | Preserve the frozen headline structure; label S3 as an influence diagnostic | §1 mapping table of sub-rows to the six S0 headlines; §8 reports coverage at wording and headline level and states that wording checks are not independent claims; S3 is labelled an influence diagnostic that never counts as verdict evidence, and the v1 "number of drops that would change a verdict" is removed. All sensitivities remain subordinate to the single primary (§0). |
| Opt. 1 | Deterministic classification-coupling sensitivity | Adopted as S9 (scenario grid with W = total − B, no draws, no weights, never verdict-setting). |
| Opt. 2 | Mark clustering, PPML, fixed effects and weights inapplicable | Adopted: §0 and §6. |

### 9b. Compliance check of v2 and responses in v3
Review: `reviews/P26_NF_codex_S6card_v2.md` (verdict: revise again; three blocking issues, one minor edit).

| # | Issue | Response in v3 |
|---|---|---|
| B1 | §4 B assertions required literal N/A records, but `claims.csv` omits N/A cells; the division list was not in `claims_spec.md` | §4 B step 1 freezes the 64-key set by rule (16 names from the T1 1887 rows), names the four structurally absent keys, materialises them as NA in memory, and treats every other missing, duplicate, extra or malformed key as an integrity failure. |
| B2 | S5 described matched-token voting; the rebuild concatenates tokens and classifies on whole-surname keys with record shares | §5 S5 states the rebuild's single algorithm: concatenated key, 1909 dictionary of keys with nb and n, rules any / majority (nb/n > 0.5) / KF, and the treatment of empty and unmatched records. |
| B3 | Headline aggregation undefined when sub-rows are not-testable | §8 headline rule: any not-testable assessed sub-row makes the headline not-testable; otherwise the weakest verdict; coverage reported. |
| M1 | S9 lacked the A8 scenario range and the share meeting the condition | §5 S9 reports ranges and shares of grid points meeting each condition, with equal weights labelled an assumption. |

Disagreements: none. The review's conclusion that the 14-division correction is the right single primary is retained.

## 10. Known limitations at freeze
1. **Not outcome-blind.** The primary analysis is arithmetic already computed in S5 (Disclosure). The card adds the verdict mapping, not new evidence. Every margin is an A8/A8a default. The S5 specification (§5) and S9 were written after S5 and only add reporting.
2. **No inference; verdicts are conditional.** The counts are treated as population descriptions. The classification and roll-completeness error in the lost surname formula is probably larger than any sampling error, but it cannot be quantified: the formula, its normalisation and its dictionary are lost, and the bounds tried in S5 are disputed (F3, S5-10). The verdicts are conditional on the published per-division classifications and rolls being correct, and sign-only comparative verdicts do not meet A8's CI requirement (§4 C).
3. **Classification can move the levels a lot.** On the five divisions with surviving rolls, uniform rules give black falls between 370 and 1,049, against 2,361 published. If the published 1886 counts in black-majority divisions are overstated, B on 𝒟 is overstated too. Nothing in the primary analysis can detect this. S5, S6 and S9 report it, and S5 cannot separate classification from roll differences.
4. **Method switch.** The comparable set still contains Uitenhage and Victoria East, which change counting method between the two years. Removing them changes the population, so under A4d it is a sensitivity (S2), not the primary analysis.
5. **Net, not gross.** B and W are net registration changes in the 14 divisions with both rolls. They do not identify gross removals or the number who lost the vote, and the 16-division reading (S4) cannot decide a verdict.
6. **The level rows are not-testable.** The four printed totals cannot be re-measured, because six divisions' rolls, the formula and the manual counts are lost. Their internal arithmetic is correct (S5 c2).
7. **Causal claims are not-testable.** No row tests whether the 1887 Act caused any fall, or whether it was "much less effective" than claimed in proportional terms. The proportional benchmark (S7) suggests the opposite on rates, but it is a different estimand.
8. **"Much smaller" and "closer to 3,000."** A8 has no default for "much", so B-cmp tests only 0 < B < 30,000. The p.466 hedged wording has no row. The authors' own magnitude ("a tenth") is carried by B-lt and B-ten.
9. **Coverage.** The tallied divisions are not the colony. The authors' extrapolation ("highly unlikely that the total … would have been much larger", p.465) is not tested. S8 gives only net colony-wide context.
10. **Comparative premises.** The positive-fall premise in B-cmp and W-cmp follows the claims' wording. It is not a numerical gate, but it means a comparison can be "qualified" or "overturned" on a premise failure rather than on the inequality.
11. **Headline-level aggregation.** The not-testable-then-weakest-sub-row rule for the two assessed headlines is a reporting convention. The sub-rows decide on the same primary analysis and do not vote across analyses.
12. **Comparative CI exception.** B-cmp and W-cmp are decided on the sign of a point difference, because no CI exists. This is an explicit, justified exception to A8 (§4 C), not exact A8 compliance.
13. **S5 is a joint contrast.** The classification algorithm replicates the rebuild, not the authors' lost formula. Records dropped for empty surnames change roll totals, and the contrast with printed totals cannot separate classification from roll-completeness differences. S5 never decides a verdict.
14. **Division key list by rule.** The 16 division names come from the frozen claims file, not from a separate list. A name variant between the T1 and T2 rows triggers an integrity failure, and the run stops until reconciled by hand (§4 D).
