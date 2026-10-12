# P03_BoF17 S6 deviations from the frozen card (v3, commit d240e89)

Each entry gives the deviation, the reason, and whether results informed it. None changes a verdict.

**D1. D3 weak-exogeneity test estimated without the levels terms.** The card augments "the Δx_t equation of step 4" with ECT_{t−1} = y_{t−1} − β̂x_{t−1}. That equation already contains x_{t−1} and y_{t−1} unrestricted, so the ECT is an exact linear combination of existing regressors and its coefficient is not identified (confirmed: `D3_literal_estimable = 0` for both products). D3 is estimated in the standard form: Δx_t on an intercept, Δx_{t−1..3}, Δy_{t−1..3} and ECT_{t−1}. Results informed: no; the collinearity is algebraic and was identified while writing the code. Irrelevant to the verdicts: D1–D3 matter only in §8 K rows 1–2, which neither K3 nor K4 reaches. Under the literal reading ("cannot be computed counts as not passed") the verdicts are the same.

**D2. Bootstrap for the interpolation sensitivity (§5C.4).** The card does not say how the null DGP is formed for interpolated data. The DGP is fitted on the interpolated series. Each replicate is masked with the raw missingness pattern and then interpolated in the same way as the data. Results informed: no.

**D3. Block-residual sensitivity (§5C.6).** The residual pool has calendar gaps. Blocks are 12 consecutive entries of the calendar-ordered pool, non-wrapped. Results informed: no.

**D4. Presample lags (card §4 step 5, literal).** Lags at grid months 1–3 come from the generated presample, as the card states. In the observed data no pre-1897 month exists, so a replicate can use a few early grid rows that the observed data cannot. This follows the card literally and is noted for transparency. Results informed: no.

**D5. Operationalising "a critical value that decides the verdict" (§4 step 7).** A comparison of a statistic with its 2.5% or 10% critical value counts as deciding if reversing it would change the §8 row. The trigger did not fire for either claim, so B stayed at 9,999. Results informed: no; the rule was coded before the bootstrap ran.

**D6. Interval forms for sensitivities the card states only as estimates.** The card does not fix an interval for §5A.5, 5A.7, 5A.8 or 5B.5–6. These use the primary block bootstrap (ℓ = 8 annual, ℓ = 12 monthly; B = 9,999). The split-year scan (§5A.6) uses the ρ = −1 MOVER bound at 95% (component 0.0125/0.9875). For the CF-filtered raw rebuilds, the UK 1866 gap is linearly interpolated before filtering, which the card prescribes for §5A.5; the same rule is applied to §5A.7–8. The log-level correlation leaves 1866 missing (n = 35 before the split). Results informed: no.

**D7. Quantities the card does not define.** For H1, H2, K1 and K2, `verdict.csv` reports a descriptive two-sided percentile-bootstrap p (2·min share of r* on either side of 0); for K3–K4 it reports bootstrap tail shares. Neither enters a verdict. The Ebisuzaki p uses (1 + count)/(999 + 1). The Bretherton N* for H2 is 2.35 < 3, so its Fisher-z interval is undefined and is reported as NA. Results informed: no.

**D8. Error-documentation value.** The §5A error item "annual first differences across the missing UK 1866" gives −0.005 here against the 0.0017 disclosed from S5. The consecutive-years value (0.212) matches. The difference lies in how the S5 variant bridged the gap. It is error documentation only and enters no range. Results informed: no.

No packages were installed. Runtime: about 1.5 minutes in total, with 8 workers for the bounds bootstrap.
