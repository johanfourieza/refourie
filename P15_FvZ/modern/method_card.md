# Method card: P15_FvZ: GDP of the Dutch Cape Colony

Status: v2 (2026-10-11), revised after Codex review (reviews/P15_FvZ_codex_S6card.md). FROZEN at commit: see git log "FREEZE S6 card P15".

## 1. Headline claims and interpretations judged
- **I1 (early level):**
  - (a) Cape GDP per capita in 1701 was "on par with" Britain;
  - (b) it was "somewhat lower than" Holland.

  The abstract says "similar to Holland and England"; the text says on par with Britain and below Holland. Both are judged.
- **I2 (decline):** GDP per capita fell over the century (1,703 in 1701 → 1,011 in 1790), because GDP trend growth (2.1%) was below population growth (2.5%).
- **I3 (balanced population):** with a "balanced" population, GDP per capita lies between $600 and $1,000.

## 2. Defect addressed
The series is a deterministic reconstruction. S5 (Claude and Codex) identified two groups of problems:
- (i) **text-vs-workbook discrepancies**, where the paper states a rule that the workbook does not follow;
- (ii) **unresolved assumptions**: undocumented hard-coded values and ambiguous denominators.

The upgrade is scenario-based propagation of assumption uncertainty through the recalculated chain. This follows the logic of JCGM 101 (propagation through a model), and the practice of reporting bounds in historical national accounts (Broadberry et al. 2015, ch. 5). The results are **assumption-conditional uncertainty ranges**, not sampling intervals.

## 3. Estimands
The same as the original, with no change:
- GDP per capita (1990 GK$) for 1701 and 1790, and their ratio R = Y1790/Y1701;
- OLS trend growth of log real GDP and of log population over 1701–1793;
- the annual balanced-population series;
- the ratios of Cape 1701 GDP per capita to Britain's and Holland's 1701 values.

The comparator vintages are frozen as the values pasted in the workbook (Broadberry et al. 2011; van Zanden and van Leeuwen 2012), and the values used are listed in the output. The decade means for 1701–10 and 1781–90 are a sensitivity only.

## 4. Primary analysis: full enumeration of scenarios
The model is the faithful R chain (`repro_original/01_recalc_workbook.R`), extended so that every changed input propagates through every dependent formula.

**Central layer: text-consistent corrections, applied in all scenarios.** These are rules the paper states:
- C1: bakers' margin 0.10 (`resteconomy!H` column)
- C2: meat as the simple average of the consumption and livestock estimates (`Livestock in possession!AD` column)
- C3: wine retail margin on domestic consumption (`resteconomy!J` column, base G = D − E)
- C4: wissel 50% on gross transfers (`INCOMEVOCEMPLOYEES!I`, with the F term replaced by E)

**Unresolved layer: enumerated in full, equal weight.** Equal weighting is an explicit assumption of maximal ignorance. Results are also reported unweighted, as a min–max range.
- U1: investment price timing ∈ {two-year lag as coded, contemporaneous} (`resteconomy!AB5:AB93`)
- U2: vine-investment divisor ∈ {/5 as coded, /6} (`resteconomy!AA` column)
- U3: silver content after 1768 ∈ {as coded, 8.04 held constant} (`INCOMEVOCEMPLOYEES` conversion cells using 9.61, including J44)
- U4: CPI 1787 and 1793 ∈ {typed overrides, the neighbouring formula rule} (`total economy!I89, I95`)
- U5: population path:
  - P0: workbook, Khoesan = share × slaves as coded;
  - P0k: workbook with Khoesan = T·W/(1−W) (`Population!U`);
  - P1: total population rescaled each year to the digitised Fig. 1 total (claims rows for Fig. 1, linearly interpolated). Under P1 the Khoesan item is fixed as coded, to avoid double counting.

  Population changes enter every formula that references the Population sheet, including consumption-based output.
- U6: rest-of-economy level (craftsmen and construction), multiplier ∈ {0.75, 1.00, 1.25}. This covers the documentation gap shown by the independent rebuild (S5-19).

The enumeration gives 2⁴ × 3 × 3 = **144 scenarios**.

**Implementation rule.** Before any output is computed, the implementer lists the exact cells changed by each item in `modern/item_cells.csv`. It verifies that switching all items to "as coded", with C1–C4 off, reproduces the S2 recalculation to below 1e-9. Any draw that produces non-finite values is reported and excluded.

## 5. Admissible sensitivities (exhaustive; not verdict-determining)
1. Central layer off (everything as coded), together with the 144 enumerations of the unresolved layer.
2. Decade-mean versions of I2 (1781–90 vs 1701–10).
3. Each unresolved item varied alone around the central case (a tornado table).

## 6. Fixed choices
- No other parameters are varied.
- 19th-century values are out of scope.
- No sampling inference, clustering or regression weights apply.

## 7. Margins and their basis
For each claim, s = the share of the 144 scenarios that satisfy the condition.
- **I2.** A3 magnitude retention: the published decline is 41%, half of that is 20.5%. The condition is R ≤ 0.795 **and** population trend > GDP trend.
- **I1a, "on par" with Britain.** The ratio lies in [0.80, 1.25]. A symmetric ±20–25% band is a common reading of parity in level comparisons. This is a wording-based margin declared here, because A3 covers effect magnitudes, not level comparisons.
- **I1b, "somewhat lower" than Holland.** The ratio lies in [0.60, 1.00).
- **I3.** At least 80% of the years 1701–1793 have balanced GDP per capita within [540, 1,100], i.e. ±10% of the stated range ends.

## 8. Verdict table (per claim, from s)

| s | Verdict |
|---|---|
| ≥ 0.80 | confirmed |
| 0.50–0.80 | qualified |
| 0.20–0.50 | weakened |
| < 0.20 | overturned |

These categories are exhaustive and mutually exclusive, and symmetric between confirmation and rejection. A verdict counts as confirmed only if it also holds in the min–max view: ≥ 0.80 under equal weighting, **and** the central-layer scenario with all U items as coded satisfies the condition. If equal weighting gives ≥ 0.80 but that coded scenario fails, the claim is downgraded to qualified.

## 9. Codex review notes and responses
Codex v1 review: approve-with-changes, 8 required changes. Responses:
1. The probability model is now two layers, with equal weight stated as an explicit assumption (§2, §4).
2. Population paths replace the constant multiplier, and double counting is avoided (§4 U5).
3. The balanced claim I3 is added, and the endpoint estimand is primary (§3, §7).
4. Comparators are primary, with the wording preserved (§1, §7).
5. The basis for each margin is stated (§7).
6. The decision table is exhaustive (§8).
7. The rest-of-economy structural item is added (§4 U6).
8. Executable cell definitions and a verification rule are added (§4).
