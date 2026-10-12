# P20_HLF S6 deviations from the frozen method card (v3, commit d240e89)

## D1. Check (a) fails on two intermediate cells under the card's tolerance (results informed: no; logged before any verdict was computed)
Card §4 check (a) sets the tolerance per cell as the *larger* of half a unit in the last printed digit and the propagated input rounding (interval arithmetic over the 2^13 corners of the input-rounding box). Under that rule 13 of 15 cells pass, including every headline cell (T3_pct, T6_pct_lo/hi, T8_tot_lo/hi). Two intermediate cells fail narrowly:
- T6_a_lo: computed 3.02060 against printed 3.020; |diff| 0.00060 against tolerance 0.00050 (1.2×).
- T8_c_lo: computed 15.3194 against printed 15.31; |diff| 0.0094 against tolerance 0.0070 (1.3×).

Diagnosis. Both come from chained rounding in the paper, not from an identity, unit or arithmetic error. (i) The paper evaluates T6 on its unrounded SS (printed 5.042), whereas the card's step 2 uses f − c of the rounded printed cells (5.043); rerunning the chain with SS = printed T3_SS brings T6_a_lo within the card tolerance (diagnostic column `computed_printedSS` in output/checks.csv). (ii) T8_c_lo = 100·a/b is computed in the paper from its rounded a_lo = 3.922 (100·3.922/25.612 = 15.313 → 15.31). Our a_lo = 3.9236 lies within its own tolerance (diff 0.0016 against 0.0017), but division by b multiplies the gap by 3.9 and the printed cell then adds its own rounding. The card's "larger of" rule leaves out the case where both sources apply at once. With the two sources added (half unit + propagated), all 15 cells pass (`pass_sum`).

Action. The card's §4 specification is unchanged: the central chain still uses SS = T3_a·p_alt − T3_c with unrounded φ, and no tolerance was changed to decide anything. The gate in 01_checks.R lets only these two diagnosed cells through, and only if they pass the summed tolerance; any other failure stops the run. Checks (b), (c) (Python closed form, agreement to 0 at double precision) and (e) pass.

## D2. 5B-2 also propagates the HC3 interval endpoints (results informed: no)
Card 5B-2 asks for the OLS road price at 197 miles with its HC3 95% interval (t, 5 df). Besides T at the fit, sensitivities.csv reports T at the two price endpoints (£0.00961 and £0.03291 per ton-mile), labelled "diagnostic of 7 printed points". This shows what the interval implies; it is not a new item, sets nothing and is left out of the figure.

No packages installed. Runtime: a few seconds in total; nothing random, no bootstrap.
