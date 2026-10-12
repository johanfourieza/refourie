# Method card: P20_HLF, railways in the British Cape Colony (social savings, 1905)

Status: v3 (2026-10-12). Final revision under A9, after the Codex compliance check (reviews/P20_HLF_codex_S6card_v2.md). No further review round; frozen on commit.

## 0. Type of analysis
The paper is a calibration (social-saving) exercise. It reports no statistical estimates, no standard errors and no sampling uncertainty, and no original workbook or code survives (S1, S2). The card is therefore built on the printed inputs, as used by the S3 rebuild (`repro_r/`) and the S5 chain (`compare/s5_checks/s5_verify.R`), which together form the reproduction baseline.

The primary analysis is **(iii) an uncertainty propagation**: it propagates an input conflict that the surviving material cannot resolve, as a **conditional scenario envelope** over the two internally consistent resolutions (not a sharp identified set; §3). It is not (i), a correction of a verified error, because S5 verified that Table 8's rows b and g are mutually inconsistent (S5-1, Codex F1) but could not verify which of them is wrong. It is not (ii), an inference-only upgrade, because the point values change; A4b does not apply. It is not (iv), a new estimator: the estimator (Table 8, c + h) is the authors'. The paper makes no odds-ratio or probability claims, so A4c does not apply.

**Only the central analysis (§4) sets a verdict.** The verdicts are descriptive, conditional accounting assessments of Table 8's arithmetic. They are not statistical evidence and they do not validate the causal attribution of growth to the railway (§3). The scenario grid (§5A) is reported as a range and a share, following A8; equal weights are assumption-conditional and are not probabilities. Changed estimators, data and assumptions (§5B) are reported one at a time and cannot set a verdict (S6, A4d).

## 1. Claims family (headline rows, frozen at S0) and interpretations
Headline rows (claims.csv, headline = 1): `T8_tot_lo`, `T8_tot_hi`, `T3_pct`, `T6_pct_lo`, `T6_pct_hi`, `TX_p19_pv`.

- **H1a** (`T8_tot_lo`, 22.35%) and **H1b** (`T8_tot_hi`, 25.09%): point claims under A8/A8a.
  - The claim: "the Cape Colony's railway ... account[s] for 22–25 percent of the increase in the Colony's labor productivity from 1873 to 1905" (abstract); "The railway directly accounted for approximately 22–25 percent of the increase in income per capita or labor productivity" (p.16); "the railway may account for 22–25 percent" (p.24).
  - The authors' interpretation: "Their contribution to economic growth was substantial ... a very large share for a single investment and a clear indicator of the transformative power of the railway" (p.24); "a fairly robust indication" despite "the relatively high error margin" (p.16); a lower bound, because it "excludes the indirect effects of the railway".
  - Testable: yes, as an internal-consistency reanalysis of printed inputs (§3, §4).
- **H1** (summary): the abstract states one claim, "22–25 percent", that covers both bounds. H1 is the weaker of H1a and H1b (conjunction; ordering in §8).
- **H1-r** (reported, no verdict): the range reading, i.e. whether each envelope lies inside [22, 25]. The wording "substantial", "very large share" and "lower bound" is not quantified by the authors and is reported qualitatively, next to the A3 floor (50% of the stated value).
- **H2** (`T3_pct`, 12.01%): "Freight social savings as % of GDP, unadjusted" (Table 3), a point claim. **Not-testable** (§10.2).
- **H3a, H3b** (`T6_pct_lo`, `T6_pct_hi`, 10.0 / 11.4%): elasticity-adjusted consumer surplus as % of GDP (Table 6), point claims. **Not-testable** (§10.2).
- **H4** (`TX_p19_pv`, £0.99m): "the 1908 present value of the sum of (positive and negative) net railway returns over 1873–1908 was £0.99 million", behind the abstract's "Little of the gains went to the state-owned company". **Not-testable**: the net-operating-revenue series and the reconstructed interest series (45% → 62% railway share of debt interest) are neither printed nor recovered (S5-6, agreed by Codex).

Secondary outputs (reported, never verdicts): the social return on capital (`TX_p17_sr_lo/hi`, 13.1–15.4%) gross of the opportunity cost (S5-2, F3), and gross of both opportunity cost and depreciation.

## 2. Defect addressed
**S5-1 / Codex F1 (agreed, changes-a-number).** Table 8 computes the TFP component as c = a/b, a level gain divided by the level change in labour productivity b = £25.612m, and the capital component as h = f/g, a growth-rate share with g = 2.21% a year. Note (b) to Table 8 defines b = GDP₁₉₀₅ − Pop₁₉₀₅·pcGDP₁₈₇₃ = GDP₁₉₀₅·(1 − (1+g)^−32), under the authors' stated assumption that labour productivity and GDP per capita grow at the same rate. With GDP₁₉₀₅ = £41.98m, which all the paper's %-of-GDP rows imply, the printed b implies g = 2.987% a year (compounded), and the printed g implies b = £21.124m. The two components rest on two different productivity paths. The GDP and population series (Verhoef et al. 2014) are not available, so the faulty input cannot be identified.

Response: when an input conflict cannot be resolved, report the envelope of values that the two internally consistent resolutions imply, in the spirit of bounds analysis (Manski 2003, *Partial Identification of Probability Distributions*; Tamer 2010, *Annual Review of Economics*). Sharp identification would need explicit restrictions on which inputs may vary; the card imposes the restrictions stated in §3 and claims no more. Social-saving growth accounting follows Crafts (2004, *Economic History Review*) and Leunig (2006, *Journal of Economic History*), and the elasticity adjustment follows Fogel (1979) and Leunig (2010).

Documented but not "fixed" in the central analysis, because the surviving material gives no rule: the road-price reconstruction (F4/S5-3; the paper's sample of carting and stagecoach rates is unavailable), the 2nd/3rd-class walking counterfactual (S5-5), the post-hoc first-class φ and the bound pairing (decisions.md 8, F2). These go to §5.

## 3. Estimands
- **Original estimand.** The share of the 1873–1905 increase in Cape labour productivity that the railway directly accounts for: T(k) = 100·a_k/b + 100·f/g, with k ∈ {lo, hi}, f = d·e/100, and b and g as printed. Units: a_k and b in £ million; f in percentage points a year and g in percent a year (printed units), so f/g is a fraction and 100·f/g a percent share; T in percent.
- **New estimand.** The same formula with b and g made consistent through the note-(b) identity b = GDP₁₉₀₅·(1 − (1+g)^−32), where g enters as a decimal rate in the identity. It is the same estimand, so it is verdict-eligible. It is evaluated under two anchors:
  - **A_g** (printed g correct): g = 2.21% a year; b_g = GDP₁₉₀₅·(1 − 1.0221^−32).
  - **A_b** (printed b correct): b = 25.612; g_b = (GDP₁₉₀₅/(GDP₁₉₀₅ − b))^(1/32) − 1.
- **Admissible model (explicit restrictions).** The envelope is conditional on: (R1) GDP₁₉₀₅ = T3_SS/(T3_pct/100), the value implied by every %-of-GDP row; (R2) Tables 3 and 8 use compatible price bases and GDP definitions; (R3) exactly one of printed b and printed g is faulty and the other is correct; (R4) note (b)'s assumption that labour productivity and GDP per capita grow at the same constant rate over 32 years; (R5) all other printed inputs are correct.
- **Conditional scenario envelope.** E_k = [L_k, U_k] = [min, max] of T(k) over {A_g, A_b}. It is the hull of two scenario values, not a sharp identified set: under the restrictions, intermediate values are neither implied nor excluded by the surviving material, and resolutions outside R1–R5 (for example a different GDP vintage, §10.5) are not covered. The printed (mixed-basis) value is not an element of either consistent scenario and is reported for reference only; whether it lies inside E_k is a numerical coincidence of the hull and is not evidence about any third model.
- **What the estimand is not.** Consistent denominators repair one defect. T(k) still adds a level-change component (c = a/b) to a growth-rate component (h = f/g), the mixture flagged in claims_spec §e15 and S5. The verdicts are conditional accounting assessments of Table 8, not a validation of causal growth attribution. Crafts (2004) separates social-saving counterfactuals from growth-accounting contributions; the Crafts framing is retained as sensitivity 5B-1.

## 4. Primary analysis (the central analysis; exactly one)
**Inputs.** Printed cells read from `claims/claims.csv` with the same ids as `s5_verify.R`: T3_a, T3_c, T3_f, T3_SS, T3_pct; T6_b, T6_c; T7_sp_lo, T7_sp_hi; T8_b, T8_d, T8_e, T8_g. Nothing else is used.

**Steps.**
1. GDP₁₉₀₅ = T3_SS / (T3_pct/100). This is circular for H2 (§10.2), but it is a common scale factor and does not affect the b/g identity beyond its stated role.
2. Unrounded rail price p_rw = T3_c/T3_a; road price p_alt = T3_f/T3_a; φ = p_alt/p_rw; SS = T3_a·p_alt − T3_c.
3. Freight consumer surplus = R(φ, ε)·SS, with the Fogel–Leunig ratio R(φ, ε) = (φ^(1−ε) − 1)/((1−ε)(φ−1)) (limit ln φ/(φ−1) at ε = 1). Low: ε = 0.8; high: ε = 0.5. Passenger surplus = T6_b + T6_c, as printed. Total consumer surplus CS_k = R(φ, ε_k)·SS + T6_b + T6_c, with ε_lo = 0.8 and ε_hi = 0.5.
4. TFP gains: a_lo = CS_lo + T7_sp_hi; a_hi = CS_hi + T7_sp_lo (CS_k as defined in step 3). This is the paper's min/max envelope pairing.
5. Capital term f = T8_d·T8_e/100 (0.1559 points a year). The capital share is computed from printed d, e and the anchor's g, so **both anchors use one formula**; the printed h = 7.04 is not used.
6. For each anchor j ∈ {A_g, A_b} and k ∈ {lo, hi}: T_j(k) = 100·a_k/b_j + 100·f/g_j, with a_k and b_j in £ million, f in percentage points a year and g_j in percent a year (g_b is converted to percent, 100·g_b, before use). Check: 100·0.1559/2.21 ≈ 7.05. Annual compounding, 32 years (1873 to 1905), as in note (b).
7. E_k = [min_j T_j(k), max_j T_j(k)].

**Inference.** None is sampling-based. The paper's inputs are point values. The one estimated input, the road price at 197 miles, comes from an unrecovered sample with no reported SE. There are therefore no confidence intervals, no bootstrap or permutation draws and no multiplicity correction. The "interval" in §8 is the scenario envelope E_k, which is deterministic. Seed 20261012 is set for form; nothing in §4 or §5A is random. Expected run time: under one second.

**Failure rules (symmetric).**
- Any required input that is missing or non-finite → the dependent claim is not-testable (§8 row 0).
- If either anchor is undefined (GDP₁₉₀₅ − b ≤ 0; g_b non-finite or ≤ 0; b_g ≤ 0), E_k is undefined and H1a/H1b are not-testable. **There is no single-anchor fallback** in either direction.
- Domain failures: p_rw ≤ 0, p_alt ≤ 0, φ ≤ 1 (the Fogel–Leunig ratio is defined for φ > 1), GDP₁₉₀₅ ≤ 0, or a non-positive argument of any logarithm or power. In the central analysis any such failure makes the dependent rows not-testable; in a sensitivity it makes that cell missing, never imputed.
- If the two anchors give equal values, E_k is a point and the §8 rules apply unchanged.

**Reproducibility checks (they gate the run, never the choice of specification).** The checks test identities, units and arithmetic, not numerical outcomes of this card.
- (a) **Printed-chain reproduction.** With printed b and printed h, the script recovers the printed T3, T6 and T8 cells. The tolerance for each cell is the larger of half a unit in its last printed digit and the rounding propagated from the printed inputs (computed by the script by interval arithmetic over input rounding). It is not a value taken from S5.
- (b) **Identity checks.** b_g satisfies b_g = GDP₁₉₀₅·(1 − (1+g)^−32) at g = 2.21%, and g_b satisfies the same identity at b = 25.612, each to 1e-9 on a round trip. The units in step 6 hold (a_k/b_j is a pure ratio; f/g_j is a ratio of percent rates and is multiplied by 100).
- (c) **Independent arithmetic.** The anchor calculations are re-implemented in a second language or in closed form (Python, or a direct computation) and agree with the R script to 1e-9. The script needs no S5 output as input.
- (d) **Reference reporting.** The report states whether the printed values (22.35, 25.09) lie in E_k (§3: reference only).
- (e) **Printed h = 7.04** is a rounding diagnostic: |h_computed − 7.04| is reported and must be consistent with the rounding of printed d, e and g. It is not a sensitivity and not a verdict input.

If a check fails, the run stops, the cause is diagnosed and logged in `modern/DEVIATIONS.md` (A5) before any verdict, and the specification is not changed to obtain a different outcome. **Registration status.** Hand calculations of the anchors (§8 Disclosure) preceded this card, so the card is a prospective registration of the implementation, not a registration made before any estimate was seen.

## 5. Admissible sensitivities (exhaustive; reported, never verdict-setting)
**5A. Same-estimand scenario grid (A8 range and share).**
- Road price p_alt ∈ {T3_f/T3_a (central), 0.023, 0.024}. The alternatives are the paper's own fn 12 rates: the simple average of all figures, and direct price evidence only.
- Anchor ∈ {A_g, A_b}.
- That gives 3 × 2 = 6 scenarios for each of H1a and H1b. For each claim the report gives the range and the share of scenarios whose T value lies inside the §7 band (assumption-conditional; equal weights are not probabilities). A scenario that cannot be computed is reported as missing; the share uses the defined scenarios and the count of missing ones is stated.

**5B. Changed estimator, data or assumption.** One item at a time from the central analysis, reported under both anchors. Units as in §4 (decimal rates inside logs and powers). None sets a verdict.
1. **Crafts (2004) growth-rate framing (logarithmic).** Per-year log growth of the TFP gain: γ_k = ln(GDP₁₉₀₅/(GDP₁₉₀₅ − a_k))/32. Then T = 100·[γ_k + f/100]/ln(1+g_j), with g_j as a decimal. Log and compound rates are not mixed: the denominator is the log of the anchor's compound rate. Domain: GDP₁₉₀₅ − a_k > 0. This is a changed estimator.
2. **Road price from the seven printed observations:** OLS of price on log(distance), evaluated at 197 miles, with the HC3 95% interval for the mean at 197 miles (analytic, Student t critical value with n−2 = 5 degrees of freedom, 2.571; no draws). The seven printed observations are a selected subset and cannot recover the uncertainty of the lost sample; the interval is a diagnostic of the printed points only. Changed data, so A4d applies. Domain: price at 197 miles > 0.
3. **2nd/3rd-class passengers with unit elasticity** (φ₂₃ = T5_m_23/(T5_c_23 + T5_g_23)) instead of zero. Domain: φ₂₃ > 1.
4. **Joint elasticity–depreciation scenarios.** All four combinations of {low, high} consumer surplus with {low, high} depreciation loss, reported separately (the paper's envelope pairing is one of the four and is the central choice). These are selected joint scenarios, not replacement bounds, and no independence between the two is assumed.
5. **First-class φ on the fare-only price ratio** (5.0) instead of the full-price ratio (4.47); T6_b is recomputed from the printed Table 5 inputs.
6. **Freight elasticity 0** (unadjusted SS) and **1** (limit ln φ/(φ−1)).
7. **Linear demand in place of constant elasticity:** R = 1 − ε(φ−1)/2 if ε(φ−1) ≤ 1, otherwise 1/(2ε(φ−1)) (the choke price falls below p_alt).
8. **Rounding re-propagated under each anchor:** the chain is recomputed from the printed, rounded prices (0.0065, 0.0032, 0.029), separately under A_g and A_b. The S3 rebuild outputs (`repro_r/results_r.csv`) are not imported, since they embed the mixed denominators.

**5C. Non-headline and not-testable rows (reported only).**
- T3_pct, T6_pct_lo and T6_pct_hi under the central chain and under 5A road prices and 5B items 2, 3, 5, 6, 7 and 8.
- The social return gross of the 3.7% opportunity cost, and gross of opportunity cost plus depreciation.
- H4: nothing can be computed. This is stated.

## 6. Fixed choices
- GDP₁₉₀₅ from T3 (step 1).
- 32 years, annual compounding.
- Printed T7 supernormal profits; the envelope pairing.
- Unrounded intermediate values. Results are reported to 2 dp, and verdict comparisons use unrounded values.
- No weights, no trimming and no missing-data imputation (there are no microdata).
- Multiplicity: not applicable, because nothing is inferential.

## 7. Margins (A8/A8a defaults; none chosen by the card author)
The headline rows are shares on [0, 1] below 0.30. A8a's band is the smaller of ±0.03 absolute and ±10% of the stated value, which is ±10% here. The A8 point-claim rule (±10%) gives the same band. The A3 floor (50% of the stated value) is used only for the downward rows of §8. It is the A3 wording-based analogue for a descriptive claim, not an A4 credible null: a deterministic envelope carries no confidence interval, and the authors' own wording ("substantial", "very large share") sets the sense of the floor.

| Claim | Type | Band B = [b_lo, b_hi] | A3 floor 0.5X |
|---|---|---|---|
| H1a | point, 22.35 | [20.115, 24.585] | 11.175 |
| H1b | point, 25.09 | [22.581, 27.599] | 12.545 |
| H2 (not-testable) | point, 12.01 | [10.809, 13.211] | — |
| H3a (not-testable) | point, 10.0 | [9.00, 11.00] | — |
| H3b (not-testable) | point, 11.4 | [10.26, 12.54] | — |
| H4 (not-testable) | point, £0.99m | [0.891, 1.089] | — |
| H1-r (reported) | range "22–25" | E_k ⊆ [22, 25] | — |

The bands are closed. A8 sets no upper ceiling: a value above the band does not count against the direction of the claim. A plausibility flag is reported if U_k > 1.5X; it does not decide the verdict.

## 8. Verdict rules (central analysis only; checked in order; the first rule that applies decides; exhaustive)
**H1a and H1b.** Stated value X; band B = [b_lo, b_hi]; scenario envelope E = [L, U] from §4.

| # | Condition | Verdict |
|---|---|---|
| 0 | E is undefined, or any required input is missing or non-finite (§4) | not-testable |
| 1 | containment: b_lo ≤ L and U ≤ b_hi | confirmed |
| 2a | U < 0 (the whole envelope has the opposite sign to the claim) | overturned (opposite sign) |
| 2b | 0 ≤ L ≤ U < 0.5X (the whole envelope is non-negative but below half the stated magnitude; the A3 wording-based floor) | overturned (below floor) |
| 3a | L < 0 ≤ U (the envelope straddles zero) | weakened (sign-straddling) |
| 3b | 0 ≤ L < 0.5X ≤ U (the envelope reaches below half the stated magnitude) | weakened (reaches below floor) |
| 4 | L > b_hi (the whole envelope lies above the band; the direction and the "substantial" and "lower bound" readings hold) | qualified (above) |
| 5 | U < b_lo, with L ≥ 0.5X (the whole envelope lies below the band but above the floor) | qualified (below) |
| 6 | otherwise: E overlaps B without being contained in it, with L ≥ 0.5X | qualified (envelope straddles the band) |

- **Exactness.** Containment needs both inequalities, and equality is allowed because the band is closed. Disjointness is strict (L > b_hi; U < b_lo). U = b_lo or L = b_hi with E reaching outside B falls under row 6. Rows 1–6 (with 2a/2b and 3a/3b) are mutually exclusive and exhaustive once row 0 does not apply.
- **Symmetry.** A set wholly above the band and a set wholly below the band (but above the floor) both give qualified, labelled by direction. Below the floor the rules are stricter (rows 2–3), because only a downward shortfall can remove the claimed magnitude; A8 has no upper ceiling, and no row lets a value above the band count against the claim. These verdicts are descriptive statements about an arithmetic envelope. They are not evidence in the A4 sense.
- **Strengthened is unreachable.** An envelope built from conflicting inputs cannot be tighter than the paper's point value.

**H1 summary:** the weaker of H1a and H1b, ordered not-testable < overturned < weakened < qualified < confirmed. Both member verdicts are reported.

**H2, H3a, H3b, H4:** not-testable, whatever any computed value is. Their 5C values are reported.

**Supplementary display.** Next to each verdict the report gives the 5A range and share, labelled "assumption-conditional; equal weights are not probabilities", the 5B values by item, H1-r, and the plausibility flag. None of them changes a verdict.

**Disclosure.** S5 and Codex have already produced the following numbers that bear on these verdicts.
- **Baseline chain:** T8 22.359 / 25.091; T3 12.012; T6 9.984 / 11.439. S3 rebuild (chained rounding): 22.32 / 25.04; T3 11.95.
- **Anchor A_g** (S5, with printed h = 7.04): T8 25.614 / 28.926 (Codex: 25.61–28.93). b_g = 21.12–21.124.
- **Anchor A_b:** implied g = 2.94% log (S5) or 2.987% compounded (Codex). S5 did not compute T8 under A_b. **While designing this card the author computed it by hand**: h ≈ 5.22, T8 ≈ 20.5 / 23.3. With the computed h = 7.05, A_g gives about 25.6 / 28.9.
- **Implied central envelopes, therefore (hand calculation; see the prospective-registration note in §4):** E_lo ≈ [20.5, 25.6] and E_hi ≈ [23.3, 28.9]. Both overlap their bands without containment, so the expected central verdict is **qualified (envelope straddles the band)** for H1a, H1b and H1. Envelope widths (≈ 5.1 and 5.6) exceed band widths (4.47 and 5.02), so **confirmed is arithmetically unreachable** under this design with these inputs. Under either single anchor the verdicts would be confirmed (A_b) or qualified above (A_g).
- **Road price:** rebuild fit 0.02126 → T8 22.815 / 25.738, T3 12.721, T6 10.262 / 11.834; fn 12 0.023 → T8 23.732 / 27.064, T3 14.217, T6 10.822 / 12.643; fn 12 0.024 → T8 24.234 / 27.804, T3 15.077, T6 11.128 / 13.094.
- **Other S5 values:** 2nd/3rd-class unit elasticity → T8 22.107 / 24.838, T6 9.830 / 11.285; Crafts framing (A_g) → 20.914 / 23.538; alternative pairing TFP gain 4.01 (decisions.md 8b); fare-only first-class φ → T6_b 0.72 against 0.774; social return gross of opportunity cost 16.79 / 19.125.
- H4: no number has been computed.

The choice of a two-anchor envelope over a single anchor was made with these numbers in view. It follows from the S5 finding that the faulty input cannot be identified (agreed by both models), not from the values. The disclosure does not prove that nothing was tuned. That confirmation is unreachable is reported as a property of the inputs; neither the bands nor the anchor choice are changed to alter it.

## 9. Codex review notes and responses
Review: `reviews/P20_HLF_codex_S6card.md` (approve-with-changes), then the A9 compliance check `reviews/P20_HLF_codex_S6card_v2.md` (revise again, three blocking issues). This is v3, the final revision; no further review round.

| # | Required change | Fix in v2 |
|---|---|---|
| 1 | Define the admissible model; the hull of two anchors is not a sharp identified set | §3 lists restrictions R1–R5 and renames the object a "conditional scenario envelope" (E_k); "identified set" is dropped throughout; §0 and §2 say sharp identification needs explicit restrictions and is not claimed |
| 2 | Resolve the GDP-vintage qualification; remove the contradictory §3 assertion | R2 states the compatible-price-base and GDP-definition assumption; §3 says the printed value is reference only and its presence in E_k is not evidence about a third model; §10.5 says the vintage resolution is not covered and cannot be tested |
| 3 | Limit the estimand claim | §0 and §3 ("What the estimand is not") describe verdicts as conditional accounting assessments, note the level/growth-rate mixture (claims_spec §e15, S5) and Crafts' distinction; the Crafts sensitivity is kept as 5B-1 |
| 4 | Separate descriptive verdicts from statistical evidence; justify the 50% rule; sign distinction; symmetric qualification; no ceilings; keep the confirmation disclosure | §7 calls the 50% floor the A3 wording-based analogue, not an A4 credible null; §8 rows 2a/2b and 3a/3b distinguish opposite-sign, straddling and below-floor envelopes; rows 4 and 5 stay symmetric; no upper ceiling; the "confirmed is unreachable" disclosure is kept, with a note that nothing was changed to alter it |
| 5 | Replace numerical outcome gates with reproducibility checks; explain tolerances; disclose prospective registration | §4 checks (a)–(e): identity, unit and independent-arithmetic checks; tolerance from printing precision and propagated input rounding; no S5 numbers used as gates; failure means diagnosis and a DEVIATIONS.md entry, never specification choice; the card states it is a prospective registration of the implementation |
| 6 | Specify sensitivity implementation | §3 and §4 declare units (percent, £ million, decimal rates in logs and powers); 5B-1 separates logarithmic from compound growth; 5B-2 fixes the HC3 t critical value (5 df) and states that seven selected points cannot recover the lost sample's uncertainty; §4 lists domain failures |
| 7 | Keep sensitivities admissible and subordinate | 5B-8 re-propagates rounding under each anchor and no longer imports S3 outputs; 5B-4 is relabelled as selected joint scenarios; printed h moved to §4 check (e) as a rounding diagnostic |
| Opt. 1 | Report all four elasticity–depreciation combinations | Adopted in 5B-4 |
| Opt. 2 | A9 process | Followed; v3 compliance check pending; unresolved limits are in §10 |

**v3 fixes (compliance check blocking issues).**

| # | Issue | Fix in v3 |
|---|---|---|
| B1 | Capital term understated 100× (f/g is a fraction) | §3 and §4 step 6 use T = 100·a/b + 100·f/g; g_b converted to percent; check 100·0.1559/2.21 ≈ 7.05 |
| B2 | Passenger surplus not explicitly in CS | §4 step 3 defines CS_k = R(φ, ε_k)·SS + T6_b + T6_c; step 4 uses it |
| B3 | Row 2b overlapped row 3a | Row 2b is now 0 ≤ L ≤ U < 0.5X; rows 2a–6 are exclusive |

Not applicable and not added, per the review: clustering, PPML, weights and Monte Carlo independence (the exercise is deterministic).

## 10. Known limitations at freeze
1. **The reanalysis is arithmetic on printed inputs.** No social-saving workbook, carting-price sample, GDP or population series, or transcription of the 1905 General Manager's report survives in usable form. The central analysis tests the internal consistency of Table 8, not the underlying data, and it is a descriptive accounting assessment, not statistical evidence. The 1905 ton-miles and fares could in principle be checked against the 42.6 MB report scan; that is a data-recovery task outside this card.
2. **H2 and H3 are not-testable.** GDP₁₉₀₅ is backed out of T3_pct itself, so T3_pct cannot differ from its printed value except through its numerator, and the numerator's inputs (ton-miles, the rail price, the road price at 197 miles) can only be taken as printed. S5 found no defect in the T3/T6 chain that a current method could fix. The chain closes (S4: T3 close, T6 exact) with unrounded φ. Their only fragility, the road price, rests on an unrecovered sample, so it is reported in 5A/5C and does not vote.
3. **H4 is not-testable** (no NOR or interest series).
4. **The central verdict is expected to be qualified and cannot be confirmed** (§8 Disclosure). The bound is as wide as the paper's input conflict, so the verdict reflects the unresolved b/g inconsistency rather than new evidence on the railway's contribution. An adjudicator who preferred a single anchor would get confirmed (A_b) or qualified above (A_g). Neither choice can produce weakened or overturned with these inputs.
5. **A third resolution exists:** b may have been computed from a different GDP vintage, such as a real series in which GDP₁₉₀₅ ≠ £41.98m, in which case both b and g, and the printed 22.35 / 25.09, would be right. This resolution violates R2 and is not covered by E_k. Whether the printed values lie inside E_k is a numerical coincidence of the hull; it does not show that this third model is covered. The vintage cannot be tested with the surviving material, so the envelope is conditional and not an unconditional identification.
6. **No sampling uncertainty is quantified.** The paper reports none, and the one estimated input's sample is lost. The HC3 interval in 5B item 2 rests on seven printed points and is a changed-data diagnostic only.
7. **The fn 17 elasticity formula** is garbled in the text layer. The Fogel–Leunig form reproduces the printed T6 freight values exactly with unrounded φ (S5), but the first-class φ and the bound pairing were chosen post hoc in S3 (decisions.md 8), so they carry no independent weight.
8. **Prospective registration only.** The anchors were computed by hand before this card was drafted (§8 Disclosure), so the card registers the implementation prospectively and was not registered before any estimate was seen.
9. **Mixed level and growth-rate estimand.** Even with consistent denominators, T(k) adds a level-change share to a growth-rate share (claims_spec §e15). The verdicts do not validate the causal attribution; 5B-1 reports the Crafts framing only as a sensitivity.
10. **The envelope is a two-point hull.** Intermediate resolutions are neither implied nor excluded (§3).
11. **No sampling uncertainty and no statistical verdicts.** The 50% floor is a wording-based descriptive rule (§7), not an A4 credible null.
