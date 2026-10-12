# Method card: P07_FG, the missing people (Khoesan labour at the Cape)

Status: v3 (2026-10-11), final revision after the Codex reviews (reviews/P07_FG_codex_S6card.md, reviews/P07_FG_codex_S6card_v2.md), under AMENDMENTS A8/A8a. To be FROZEN with the commit message "FREEZE S6 card P07".

## 1. Claims family (headline rows of claims.csv) and interpretations

**Headline rows:**
- T1_1685_all_khoesan (122) and T1_1773_all_khoesan (6,843);
- tx_p205_kh_growth (3.8);
- T3_Total_without/with (14.5/8.2);
- T5_Total_wheat_pct (−43.4);
- T7_GiniAll_fvf/khoesan (0.74/0.50).

Each interpretation is the authors' own (claims_spec.md §b–c). There are no odds-ratio or probability claims, so A4c does not apply.

**I1, Khoesan employed by settlers (accounting claims).**
- **I1a-dir.** The number "increased" from 1685 to 1773.
- **I1a-mag.** It grew at "3.8 per cent per annum", read as a magnitude.
- **I1a-fid.** The printed 3.8% matches the printed endpoints 122 → 6,843. This is numerical fidelity only.
- **I1b.** The growth was "equivalent to that of slaves".
- **I1c.** The 1773 level is 6,843.
- **I1d.** "The Khoesan did not leave the area"; settler expansion drove them to abandon pastoralism.

**I2, slave productivity overestimated (accounting claims).**
- **I2a.** T5 Total: output per worker falls 43.4% when Khoesan are added.
- **I2b.** T3 Total: 14.5 → 8.2 mudden per worker.
- **I2c.** "Slavery was not as productive an enterprise as earlier historians have claimed."

**I3, inequality.**
- **I3a.** Gini 0.74 → 0.50 in 1757; previous estimates "overestimated … social inequality".
- **I3b.** Between-group inequality "increases" (p.213) and "was underestimated" (p.215).
- **I3c.** Within-group inequality "decreases significantly" (p.213).

I3b and I3c are row-context cells that S0 records as part of the authors' reading of the T7 headline. They are the subject of the S5 dispute (C7 vs F4).

**Scope.**
- I1 and I2 are accounting claims: deterministic functions of census aggregates and assumed ratios. They are judged as such.
- Nothing here estimates a causal effect or the economic productivity of slavery.
- Figure 3 (GDP) and Table 6 are outside the family.

## 2. Defects addressed, type of analysis, inapplicable methods

S5 found the following defects (reconciled in audit.md):
- **C8/F5.** A one-household calibration of herd value per Khoesan; productivity falls by construction; no uncertainty is reported.
- **C1/F1.** Stellenbosch gets 3× in the code and 2× in the text.
- **N1/F2.** "Wheat" is all grain, and T5 has an unstated herd cap.
- **C2/F6a.** 3.8% is the growth rate of the CSD series; the printed all-region endpoints give 4.68%.
- **C7/F4.** The Theil comparison mixes shares and levels. **Disputed.**
- **N3/F5.** Labour units are inconsistent, and herders are counted as grain labour.

**Types of analysis.**
- I1 and I2: **(iii) assumption propagation**. One central scenario plus an explicit joint assumption range 𝒜 (Saltelli et al. 2019; JCGM 101, with the dependence between inputs encoded structurally, §4.2).
- I1a-fid, I3b and I3c: **(i) corrections of verified arithmetic or unit errors**.

**Inapplicable methods.** This is an accounting design, so PPML, fixed effects, estimation weights and regression upgrades do not apply. No valid sampling-inference model exists: these are household censuses, there is no household linkage across years, and the productivity Totals have only three districts (Cameron and Miller 2015). Two consequences follow:
- **No inferential verdicts.** A8 directional comparative claims ("A > B", "increased", "decreased") need a CI that excludes 0. They are **not-testable (inference)**, and their deterministic direction is reported beside the verdict (§8).
- **Assumption-propagation verdicts are descriptive.** Point, parity and magnitude claims (I1a-mag, I1b, I1c, I2a, I2b) receive descriptive verdicts on the central value and the assumption range 𝒜 (§8).

The range 𝒜 is an assumption range, **not** a confidence interval, and **not** A4's credible-null interval. Scenario shares under equal weights are assumption-conditional summaries and never verdict probabilities (A8).

## 3. Estimands

**Labour.** Khoesan labour for household i is Lᵢ = `vherd`ᵢ / dᵢ. λ enters **only** through the divisor d (§4.2), never as a multiplier on Lᵢ.

| Estimand | Definition |
|---|---|
| K_t | Σᵢ Lᵢ, all regions, analysis sample |
| g_K | 100·[(K_1773/K_1685)^(1/88) − 1], all regions |
| g_S | the same rate for total slaves, same sample |
| r_KS | g_K/g_S |
| P_T5 | 100·(m_with − m_without)/m_without; m_without = mean over farm-years of grain/`slavemales`; m_with = mean of grain/(`slavemales` + Lᵢ); T5 sample as coded, herd cap included (A4d); mean of ratios |
| P_T3 | the same statistic on the T3 sample |
| g_pub | 100·[(6,843/122)^(1/88) − 1] = 4.68: the printed endpoints, fixed, scenario-independent (I1a-fid) |
| Theil (I3b, I3c) | the deterministic directions under two unit-consistent readings (§4.4) |

**I3a** is **not-testable**. No code survives, and no FvF (2011) person-level income file survives (the P17 audit gives code_status unavailable). If the file is recovered, a new card version is needed.

## 4. Primary analysis

### 4.1 Data, sample and code rules
- **Data and script.**
  - Data: `missingpeople.dta`, read via `tools/paths.R` with `dpath("P07_FG", "original/14 FG Missing People/missingpeople.dta")`.
  - Script: `modern/01_scenarios.R`, an R re-implementation of CK l.3–67, restricted to §3.
- **Sample, as in the code (CK l.4–8).**
  - Drop `output == 0`.
  - Drop the years 1670, 1678, 1688, 1702, 1705, 1716, 1752 and 1762.
  - Drop district 4 in 1723.
  - Drop district 0.
- **District 0.**
  - The central scenario and 𝒜 use the **coded** totals, with district 0 dropped.
  - The **published-run** totals keep district 0 (C5: T5 N 1,096; slaves 1773 7,101). They are reported, but no verdict depends on them.
- **Variables.**
  - `vherd` = `vcattle` + `vsheep` + `vhorses`. It is missing if any component is missing.
  - `dsow` = 1 if any of `wheatsown`, `ryesown`, `barleysown` > 0.
  - `dviti` = 1 if `vineyards` > 0.
  - `dmix` = `dsow` + `dviti`.
- **Samples.**
  - T3: `year ≥ 1719 & vherd < 1000 & dviti == 0 & dsow != 0 & slavemales != 0`.
  - T5: `year ≥ 1719 & vherd < 1000 & dmix != 0 & slavemales != 0`.
  - The Totals cover districts 1–3.
- **Stata semantics, replicated exactly.**
  - Missing is greater than every number. So `vherd < 1000` is false when `vherd` is missing; `slaves > 5` is **true** when `slaves` is missing; `slaves == 0` and `slaves > 0 & slaves < 6` are false; `slavemales != 0` is true.
  - Lᵢ starts at 0, is replaced only where a district condition holds, and is missing when `vherd` is missing.
  - Division by 0 or by a missing value gives missing.
  - Sums and means omit missing values.
- **Paired support.** For each productivity table the script reports N_without and N_with. The verdict statistic uses each column's own support, as coded. If the two Ns differ, the paired version on the common support is reported.

### 4.2 Divisors and the joint assumption structure
- **Divisor.** dᵢ = D(district, year) · γ_c / γ_a.
  - c is household i's slave category (`slaves`: 0; 1–5; > 5; missing counts as > 5).
  - a is the slave category of the anchor household that sets D.
  - D is therefore the divisor of the **anchor's own category**, and each anchor reproduces its own observed ratio exactly under every gradient.
- **Cape district.** 0 Khoesan, as the authors assume.
- **Gradient γ = (γ_>5, γ_1–5, γ_0).**
  - stated: (1, 57.5/67.5, 47.5/67.5). This equals the coded −10 Rds steps in Swellendam and the −20 Rds steps in Stellenbosch and Drakenstein.
  - none: (1, 1, 1), so every category gets its anchor's rate.

**Anchors (provenance).**
- **Botha.** p.204 and CK:27; S5 lookup C8. Rds 3,375.2 of herd value, 50 Khoe, Swellendam, 1773, 23 slaves, so a = > 5. **λ applies here and only here:** D_Botha = 67.5/λ.
  - λ = 1 (as coded): all 50 people count as labour in adult-male-slave units.
  - λ = 0.5: an **assumption, not an anchor**. Half the clan counts as working labour (Codex F5, N3).
- **Tas.** p.204 (claims_spec §e.15); S5 lookup C8. Rds 2,041.2 and 11 Khoesan, Stellenbosch, 1709. D_Tas = 185.6, and a_Tas is read from Tas's 1709 slave count in the data before the run; the household found and its category are reported. The 11 are counted workers, so **λ does not apply** to D_Tas.
- **Not an anchor.** The 1790 'General description' compares Stellenbosch in 1790 with the combined districts in 1773 (claims_spec §e.4).

**Swellendam.** D = D_Botha = 67.5/λ, with a = > 5.

**Stellenbosch/Drakenstein rule S.**

| S | Stellenbosch | Drakenstein | Anchor category a | Basis |
|---|---|---|---|---|
| **text (central)** | D = 2·67.5/λ | D = 2·67.5/λ | > 5 | "double these rates" (p.204); λ enters once, via Botha |
| code | D = 3·67.5/λ | D = 2·67.5/λ | > 5 | CK:33–39 |
| Tas | D = 185.6 | D = 185.6 | a_Tas | Tas anchor; one rule for both districts, as in the text |
| drift | d(year) = exp of the linear interpolation in year between ln d_Tas,c (1709) and ln d_text,c (1773), extrapolated beyond those years | same | per category | the two dated anchors combined. d_Tas,c = 185.6·γ_c/γ_{a_Tas}; d_text,c = (2·67.5/λ)·γ_c. λ enters only through the text endpoint |

**Central scenario.** λ = 1, S = text, γ = stated. It applies the code's choices with the verified arithmetic errors corrected and the text's 2× Stellenbosch ratio, because the paper states that ratio. The central scenario alone determines c in §8.

**Assumption range 𝒜.** λ × S × γ gives 2 × 4 × 2 = **16 joint scenarios**, the central one included.
- The dependence between inputs is encoded structurally: λ only through the Botha-based divisors; Tas only through S; drift is a variant of S.
- Equal-weight shares are reported and labelled assumption-conditional.
- With every other input at its central value, the λ at which each I1c and I2 statistic crosses its margin is reported. These values are not used to set 𝒜.

### 4.3 Verification (run before any verdict output)
1. **Coded reference** (λ = 1, S = code, γ = stated) against the S5 Stata `base` (`compare/s5_checks/scenario_results.csv`), relative tolerance 1e-4:
   - K by year and region against the X1 sums;
   - T3 Total without/with (14.54454/8.189994);
   - T5 Total grain without/with;
   - sample Ns exactly: T3 126/38/206/370 and T5 321/207/567/1,095.
2. **Central scenario** against S5 `stel2x`, on the same cells.
3. **Anchor check.** In every scenario, Botha's household gets exactly 50·λ labourers. Under S = Tas, Tas's household gets exactly 11.
4. **Missing-value counts** reported per sample: `vherd`, `slaves`, `slavemales`.
5. **Failure.** If any check fails, every I1/I2 verdict is not-testable until a DEVIATIONS.md entry (A5) resolves the discrepancy.

The S5 `uniform` run assigned the 1–5 rate to every category, which does not preserve the anchor. It is therefore not a valid check for γ = none and is not used as one.

### 4.4 Theil readings (I3b, I3c; deterministic, units consistent within each reading)
- **Inputs.**
  - FvF (2011) Table 7, 1757: total T₀, between share b₀ and within share w₀ (P17 wiki).
  - Khoesan-added, `Dataset.xlsx` 'Inequality': D12 (0.7409483), D19 (between level, 0.3537841) and D20 (within level, 0.3871641).
- **Share reading.** Compare D19/D12 with b₀, and D20/D12 with w₀.
- **Level reading.** Compare D19 with b₀·T₀, and D20 with w₀·T₀.
- **Price basis.** The implementer finds the FvF Gini column (1700/1723/1757) that matches 'Inequality'!H3:J3 (0.837/0.816/0.744) to 3 dp, and uses that column's Theil values. The 1757-prices column gives T₀ = 1.273, b₀ = 0.331 and w₀ = 0.669.
  - If no column matches, both bases are reported (the alternative is "deflation by price index": 1.240/0.338/0.662).
  - If the direction differs between the bases, that reading's reported direction is "basis-dependent".
- **No benchmarks.** The authors' magnitudes (+0.02, −0.28) mix units and are not used.

## 5. Admissible sensitivities (exhaustive; reported, not verdict-determining)
1. **Tornado.** Each factor of 𝒜 varied alone around the central scenario. The full 16-scenario table and the min–max range are also given.
2. **No herd cap in T5.** This changes the population (A4d; F2).
3. **Wheat only.** A different outcome (N1).
4. **Ratio of means** instead of the mean of ratios. A different estimand.
5. **Labour allocation.** A share α of Khoesan labour enters L* for grain, α ∈ {0.5, 0}. α = 0 is the authors' own "only for herding purposes" (p.204), under which arable output per arable worker does not change. Applied to the central scenario and to 𝒜.
6. **Cape district Khoesan** at the Drakenstein divisor.
7. **Concave herd scaling.** Lᵢ = (3,375.2/dᵢ)·(`vherd`ᵢ/3,375.2)^0.75.
8. **Census years 1752 and 1762 restored.** This changes the population (A4d).
9. **Published-run totals** (district 0 kept, C5).
10. **CSD series** for g_K and g_S (the basis of the published 3.82%).
11. **Total Theil level** (T₀ → D12), reported beside I3a. It is a different index and gives no verdict.

The farm-year bootstrap is removed. There is no household linkage, and there are only three districts to cluster on.

## 6. Fixed choices and missing scenarios
- Census years, district codes, slave-category cut-offs, the T3/T5 samples and the herd cap are all as coded.
- No trimming and no weights.
- **Secondary district rows.** These are Stellenbosch 18.4 → 8.1, Drakenstein 15.1 → 5.6, and "even larger". They are reported for every scenario and carry no verdict.
- **Non-finite values (symmetric).**
  - A non-finite central value makes the claim not-testable.
  - If **one or more** of the 15 non-central scenarios is non-finite (any number from 1 to 15), the extreme verdicts are unavailable on both sides. "Confirmed" becomes "qualified (range incomplete)" and "overturned" becomes "weakened (range incomplete)", and the number missing is reported.
  - **Provenance.** This is a unanimity rule. Rows 1 and 3 of §8 require *every* scenario in 𝒜, so any gap removes both of them equally. No numerical gate is used. The v2 gate (≥ 25%) was set without reference to results and is withdrawn because it was asymmetric.

## 7. Margins (A8/A8a defaults; A3/A4 floors, no ceilings) and disclosure

For each claim, the regions are R⁺ (consistent with the claim) and R⁻ (contradicts it).

| Claim | Statistic | A8 class | R⁺ | R⁻ |
|---|---|---|---|---|
| I1a-mag | g_K | magnitude, b₀ = 3.8 | ≥ 1.9 | < 1.9 |
| I1a-fid | g_pub (fixed, 4.68) vs 3.8 | point, ±10% | g_pub ∈ [3.42, 4.18] | outside |
| I1b | r_KS | "similar" | [0.80, 1.25] | outside |
| I1c | K_1773/6,843 | point, ±10% | [0.90, 1.10] | outside |
| I2a | P_T5 | magnitude, b₀ = −43.4 | ≤ −21.7 | > −21.7 |
| I2b | P_T3 | magnitude, b₀ = 100·(8.2 − 14.5)/14.5 = −43.45 | ≤ −21.72 | > −21.72 |

**Plausibility flag** (A8; reported, not verdict-deciding). It is raised when g_K > 5.7, |P_T5| > 65.1 or |P_T3| > 65.17.

**Directional claims (I1a-dir, I3b, I3c).** No margin, because no inferential verdict is made (§2). The reported deterministic direction is:
- **I1a-dir.** The sign of K_1773 − K_1685 in the central scenario, and the number of scenarios in 𝒜 with that sign.
- **I3b and I3c.** The sign of new − old in each reading (§4.4).

The A8 deviation proposed in v2 was rejected by Codex and is withdrawn. A8a changes nothing here.

**Disclosure.** The following S5 numbers bear on the verdicts and were seen before this card was written:
- **Central scenario, already seen (= `stel2x`).**
  - K: 183 (1685) and 7,163 (1773), so I1c ≈ 1.047.
  - Growth: g_K 4.26 against g_S ≈ 4.02, so r_KS ≈ 1.06.
  - Productivity: T3 with 8.02 (P_T3 ≈ −44.8); P_T5 −45.2.
- **I1a-fid is decided by a number already known.** g_pub = 4.68 (C2), so the verdict is predetermined: overturned (reporting).
- **Other scenarios and sensitivities already seen.**
  - λ = 0.5 corresponds roughly to `div_x2`: 1773 count 3,421, P_T5 −32.1.
  - `uniform`: −44.3 (this is not a grid cell, §4.3).
  - No cap: −37.6. Wheat only: −42.9. `keep5262`: −41.6. Pair B: −39.2.
- **Theil.** Share reading: between 0.331 → 0.477 (up), within 0.669 → 0.523 (down). Level reading: between 0.421 → 0.354 (down), within 0.852 → 0.387 (down).
- **How the margins and rules were set.** They are A8/A3/A4 defaults. 𝒜 comes from documented anchors plus one declared assumption (λ = 0.5). The unanimity rule (§6) has no tunable parameter. This disclosure does not prove that nothing was tuned.

## 8. Verdict tables (checked in order; the first rule that applies decides; exhaustive)

**Descriptive verdicts: I1a-mag, I1b, I1c, I2a, I2b.** c is the central value; 𝒜 is the 16 joint scenarios.

| # | Condition | Verdict |
|---|---|---|
| 0 | verification (§4.3) fails, or c is non-finite | not-testable |
| 1 | c ∈ R⁺ and every scenario in 𝒜 is finite and ∈ R⁺ | confirmed |
| 2 | c ∈ R⁺ otherwise | qualified (assumption-sensitive, or range incomplete) |
| 3 | c ∈ R⁻ and every scenario in 𝒜 is finite and ∈ R⁻ | overturned (contradicted under every assumption in 𝒜) |
| 4 | c ∈ R⁻ otherwise | weakened (assumption-sensitive, or range incomplete) |

Every finite c lies in exactly one of R⁺ and R⁻, so the table is exhaustive. Rows 1/3 and 2/4 are exact mirrors. "Strengthened" cannot be reached.

**I1a-fid (deterministic, reporting accuracy):**

| # | Condition | Verdict |
|---|---|---|
| 0 | g_pub cannot be computed | not-testable |
| 1 | g_pub ∈ [3.42, 4.18] | confirmed (reporting) |
| 2 | otherwise | overturned (reporting: the printed rate does not follow from the printed endpoints) |

**Directional claims: I1a-dir, I3b-share, I3b-level, I3c-share, I3c-level.**
- Verdict: **not-testable (inference)**, because no valid interval exists (§2, A8).
- Reported with each: the deterministic direction (up / down / zero / basis-dependent).
- For I1a-dir, the direction across 𝒜.
- For I3b and I3c, a statement of whether that direction agrees with the authors' wording.
- I3b-share, I3b-level, I3c-share and I3c-level are **four separate rows. Each is marked "disputed (C7 vs F4)", and there is no combined Theil verdict.**

**Not-testable by design:**
- **I1d.** Migration and pastoral abandonment are unobserved, and Table 1 is settler herd value.
- **I2c.** The economic productivity of slavery would need farm-level Khoesan labour inputs and their allocation.
- **I3a.** No code or microdata.

**Group summaries (accounting claims).**
- I1: the weakest of I1a-mag, I1b and I1c.
- I2: the weaker of I2a and I2b.
- Ordering: not-testable < overturned < weakened < qualified < confirmed.
- I1a-fid, the directional rows, I1d, I2c and I3a are reported separately.

## 9. Codex review notes and responses

**v1 review** (approve-with-changes, 10 required changes):
1. Share-based verdicts are replaced by the central value plus 𝒜.
2. A8 margins are adopted, and growth is split into rows.
3. The reference veto is removed.
4. Population-changing choices are kept out of the verdicts.
5. The invalid 1790 anchor is removed.
6. Joint assumptions are made coherent.
7. Labour allocation and drift are added.
8. The bootstrap is removed.
9. Theil is judged in consistent units.
10. Implementation rules are added.

**v2 review** (revise again, 5 blocking issues). Responses:
1. **Calibration.** λ enters once, through the Botha divisor; Lᵢ = `vherd`/d has no λ multiplier (§3, §4.2). Tas is not λ-adjusted. D is defined as the anchor-category divisor with d = D·γ_c/γ_a, so D_Tas = 185.6 is consistent across the table, the gradient and drift. Drift is defined per category on the log scale. The anchor check is added (§4.3).
2. **A8 deviation rejected and withdrawn.** Directional claims get "not-testable (inference)" with the deterministic direction reported (§7, §8). The assumption range is no longer called A4's credible-null interval (§2, §8).
3. **Theil.** Each reading has its own row, marked disputed, with no combined verdict (§8).
4. **Missing scenarios.** A symmetric unanimity rule covering 1–15 missing scenarios, with its provenance stated (§6, §8).
5. **Benchmarks.** I1a-fid compares 3.8 with the fixed printed endpoints (g_pub = 4.68). I2b's benchmark is derived from 14.5 → 8.2 (−43.45; floor −21.72).

## 10. Known limitations at freeze
- **λ = 0.5 is a declared assumption, not a sourced demographic share.** Equal weights over 𝒜 have no probabilistic basis, which is why shares are never verdicts.
- **Tas's slave category (a_Tas) is read from the data at run time.** If the 1709 lookup fails, S = Tas and S = drift become non-finite. The I1/I2 claims then fall under the §6 range-incomplete rule, and confirmed or overturned is unavailable.
- **Directional claims (I1a-dir, I3b, I3c) receive no substantive verdict.** The data permit no valid interval. The Theil dispute (C7 vs F4) is therefore reported, not resolved.
- **The I1a-fid verdict was known before freezing** (g_pub = 4.68 in S5).
- **The price basis of the Khoesan-added Theil values (D12/D19/D20) is undocumented.** It is resolved only by the Gini-column match in §4.4.
- **The I2 verdicts concern the accounting ratio only.** Labour allocation (§5.5) can remove the fall entirely (α = 0) but does not enter the verdict, because the authors' own L* definition is the estimand.
- **γ = none has no S5 cross-check**, because S5 `uniform` did not preserve the anchors.
