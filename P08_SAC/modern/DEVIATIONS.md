# P08_SAC S6 implementation deviations (card frozen at 17a056d)

Each entry gives the deviation, the reason, and whether results informed it. Unless stated otherwise, the choice was coded before any modern estimate was run.

- **D1. Script layout.** The card's four scripts are kept. `04_descriptives.R` also assembles `output/verdict.csv` and `output/primary.csv` and draws the figure. `01_build.R` writes `output/verification.csv`. No analysis is added. Reason: the task requires these outputs. Results informed: no.
- **D2. Missing enlistment month.** The card's cluster is EYear × EMonth. One wage-sample row (29 first terms) has no month. These rows form an "EYear_NA" cell rather than being dropped, so the published sample (N 7,389) is kept. Reason: the card is silent on missing months. Results informed: no.
- **D3. Place clusters (§5.2).** `Place` is missing ("." or blank) for 43.6% of the wage sample. Missing place is treated as one "unknown" cluster, the conservative choice. Spelling variants are normalised: lower case, letters only, Namahasha→Nomahasha, Sydenham variants→Sydenham. That leaves 35 place clusters in the wage sample. Reason: the card is silent on missing places. Results informed: no.
- **D4. ρ in the Carter–Schnepel–Steigerwald G\*.** The card does not fix ρ. G\* is computed with ρ = 1 (perfect within-cluster correlation, the worst case in CSS 2017), and that value sets the validity flag. Results informed: no (coded before the first run). **Disclosure:** after the first run showed the flag raised, G\* under ρ = 0 was added to `primary.csv` as a report-only column (I4 12.10; I5 12.29). Under ρ = 0 the I5 flag would not be raised, and I5-LP/PCT would be "weakened" (rule 2, p₁ = 0.134) rather than "not-testable" (rule 1). Neither reading confirms the claim. I4 does not change, because p₁ < 0.01 under either ρ.
- **D5. §5.1 scope.** The Rademacher WCR is run for I4/I5 only, the rows where WCR is the primary. For the difference-in-means rows, HC1 and HC3 come from a regression on a group dummy with t(N−2). Reason: the card's wording is ambiguous. Results informed: no.
- **D6. §5.2 tests.** The wage rows use CR1 by place (t, G−1), two-way CR1 (sandwich `vcovCL`, t, min G−1), a place-cluster WCR (Webb) and a two-way WCR with bootcluster = place (the coarser dimension, 35 vs 81). The difference rows use CR1 only. Reason: the card names no test type for §5.2. Results informed: no.
- **D7. Test type in §5.3a, §5.4, §5.6, §5.7.** The card names no test. Each reports HC3 (the secondary type) and WCR Webb by EYear × EMonth (the primary type), both at 99%. In §5.6 one observation has leverage 1, so HC3 is undefined; HC1 is added there. Results informed: HC1 was added after HC3 returned NaN (a mechanical failure, not an outcome).
- **D8. Score sensitivity (§5.3b) implementation.**
  - (a) Resampling clusters with replacement is implemented as multinomial frequency weights on clusters (SAC year × month over the full first-term file; SAF `family_id`). This is numerically identical to stacking duplicated clusters.
  - (b) SAF `year` is used as stored (stock A has 5,408 persons, matching the card's count).
  - (c) The SA-born HISCO/year merging for the compatriot refit is fixed at the full-sample coding.
  - (d) Data feature: the SAF stock holds only 612 distinct surnames, so 289 of 568 SA-born first terms have names unseen in both stocks and take p = π_r. EM gives π₅ = 0.933 and π₉ = 0.363. 23 of 4,999 draws failed (0.46%, below the 5% instability limit).
  - Results informed: no.
- **D9. Oaxaca–Blinder (§5.5).**
  - Group-specific coefficients that are not identified (a category absent in one group) are set to 0.
  - "Joint inference on R and U − 0.5R" is implemented as a 99% sup-t band from the year × month cluster bootstrap (B = 4,999).
  - The authors' `sa` re-run uses the wage-sample filters (Region ≠ ".", age > 18 or missing, Repeatlast = 0) and gets N 7,395 against the sheet's 7,426.
  - Results informed: no.
- **D10. Heights (§5.9).**
  - Age fixed effects use floor(age), with ages 35 and over pooled; (c) has no upper bound. Date-based age uses the Birth*/E* day-month-year columns. Ages ≤ 0 or ≥ 100 are set to missing. 15 recruits have no age and are dropped explicitly.
  - Each variant is reported for the I3a contrast and for an all-cohort SA−GB contrast.
  - In (d), the score enters as a regression of height on p_i.
  - Results informed: no.
- **D11. §5.9f not run.** The 'SAC comparisons' truncreg uses ll(160) but names no source, and the paper documents no minimum-height standard. The result is reported as "not run (threshold undocumented)", as the card prescribes.
- **D12. I1 definitions.** "Known Country" means `Country` is neither missing nor ".". UK means RegionDum ∈ {1, 7, 8, 10}, so the Augmented sheet's own region coding places the Isle of Wight, the Isle of Man and Jersey in England. Results informed: no.
- **D13. Years in South Africa (§5.6).**
  - Parsed from text as years + months/12 + weeks/52.18 + days/365.25, with fractions such as "2 1/2 years" handled.
  - "Born in SA"/"whole life" entries are set to the stated age.
  - 1,079 of 1,157 recorded first-term entries parse; the regression sample has 1,061 rows, 19 of them Afrikaans.
  - Results informed: no.
- **D14. Language diagnostic.** "Dutch recorded" means `Languages` or `Other languages?` matches dutch|hollan|afrik|taal. Results informed: no.
- **D15. WCR mechanics.** fwildclusterboot 0.14.3 is seeded through `set.seed` and `dqrng::dqset.seed`. Distinct bootstrap statistics are counted after rounding to 1e-10. No retry was triggered (9,999 distinct values for I4 and I5).
- **Runtime and packages.** A full run takes about 5 minutes; no replications were halved. No packages were installed. Outputs regenerate byte-identically from clean Rscript sessions (checked by md5).
