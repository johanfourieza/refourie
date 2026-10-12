# Method card: P24_MGF, the missing boys (South African child sex ratios, 1894–2011)

Status: v3 (2026-10-12). Author: coordinator (Claude Opus 5.5, subscription), Tier-3 reduced protocol (WAVE3_PLAN.md). v1 reviewed by Codex (reviews/P24_MGF_codex_S6card.md).

## 0. Type of analysis
(ii) inference upgrade on two surviving inputs:
- the authors' supplementary census table (under-five counts by race and sex, 1894–2011). Rows built on it are **arithmetic** on the authors' own inputs; they test transcription and computation, not the census;
- the Kimberley death-register transcriptions: 12,092 of the 13,174 records reported, from eight register years (1895, 1900, 1905, 1910, 1925, 1930, 1935, 1940; one stray 1919 record is dropped). Rows built on them are **on the recovered registers**.

Every Kimberley quantity is the **sex composition of recorded deaths**, P(male | death). It is not a sex-specific mortality risk, because no population at risk by sex and age survives for Kimberley. Male predominance among deaths is therefore tested, and higher male mortality risk and the preference-for-girls mechanism are **not tested**. The registers differ from the authors' file (coverage, race and age coding; S5). They are the only surviving records, so the primary runs on them and the Kimberley verdicts are carried to the original claim IDs **labelled reconstruction-conditional**, the treatment used for the Tier-2 papers whose primaries ran on recovered records (P12, P17, P21). A4(d) is read as governing population-changing sensitivities, not a primary on the only surviving records (Codex disputes this reading; §10.6). Verdict ladders are symmetric.

## 1. Claims family and interpretations
Frozen headline rows:
| Row | claim_id | Published | Authors' interpretation | Type (A8) |
|---|---|---|---|---|
| C21 | F1_black_1921 | ≈ 89.2 | 1921 black under-five ratio, "one of the lowest ever recorded". The 1921 value is an under-one proxy (S5 F9) | point (ratio), arithmetic |
| C21e | TX_p130_black_1921_est_a | 90.61 | adjusted 1921 estimate, "below 91" | point + threshold |
| C80 | T4_black_1980_sr_04 | 101.0 | black under-five census ratio, 1980–84 | point (ratio), arithmetic |
| D80 | T4_black_1980_sr_death | 115.3 | boys dying per 100 girls dying, black, 1980–84 | point (ratio) |
| K04 | T5_black_0-4years_sr | 105.6 | Kimberley black sex ratio at death, ages 0–4 | point (ratio), numerical agreement only |

Interpretation rows attached to K04 (the authors' reading in claims_spec §c), with one primary each:
| Row | Reading | Estimand |
|---|---|---|
| K04-ex | "boys died more than girls" (black, 0–4) | d04 = p_B,0–59m − 0.5 |
| K18-ex | "black boys' excess persisted after 18 months (101.0)" | d18 = p_B,18–59m − 0.5 |
| KBW | "... unlike white boys (86.1)" | Δ18 = p_B,18–59m − p_W,18–59m |

## 2. Defects addressed
S5: Table 5 does not reproduce from the recovered registers; no uncertainty is attached to the death ratios (Figure 1 shows census intervals); the 1921 point is an under-one proxy; the persistence and black–white readings are untested descriptive comparisons.

## 3. Estimands
- Census: R = 100·M/F from the transcribed supplementary cells (`repro_r/output/supp_population_transcribed.csv`).
- Kimberley: race and age by the frozen S3 crosswalk (`repro_r/01_clean.R`). Age bands: 0–59 months; 18–59 months. p = M / (M + F) among recorded deaths in the cell; R_K = 100·M/F. Records with missing sex, race or age are excluded and counted.

## 4. Primary analysis (one per row)
- **C21, C80:** R from the census cells; decided on the point value. Clopper–Pearson intervals are reported but do not reflect enumeration or age-reporting error and do not vote.
- **C21e, D80:** inputs not recovered (1911/1936 under-one counts; Yearbook death counts): not-testable by construction.
- **K04:** R_K (black, 0–59 months), decided on the point value against the band. The band crosses parity, so this row tests numerical agreement only, not male predominance.
- **K04-ex, K18-ex, KBW:** one family of three, Bonferroni-adjusted intervals at exact coverage 1 − 0.05/3. With eight register years no cluster-robust method is reliable (Cameron and Miller 2015), so the primary **assumes independence of deaths across records** (stated, not tested): Clopper–Pearson intervals for d04 and d18, and a Newcombe hybrid-score interval for Δ18. A year-heterogeneity test of the male share (chi-square, or Fisher's exact test if any expected count is below 5) is reported as a diagnostic only; it does not vote and does not establish independence.
- **Failure rules:** an empty cell (M + F = 0) makes the row not-testable. F = 0 gives p = 1, which is valid. R_K is undefined if F = 0, which makes K04 not-testable.

## 5. Admissible sensitivities (reported, never verdict-setting)
1. Leave-one-register-year-out ranges for p and R_K in every K row (including dropping 1900, the siege year).
2. Year-cluster wild bootstrap (Webb weights, eight clusters) for d04, d18 and Δ18, labelled unreliable with few clusters.
3. Race recoding, explicit: (a) raw strings matching "american negro" → black and "ndebele" → black (S3 maps them to white and missing); (b) keep only records whose `race_raw` is among the 20 most frequent raw strings in the S3 crosswalk, dropping the rest.
4. Age boundary: the lower bound of the 18–59-month band at 17 months instead of 18 (S3 age in months as computed; no new date arithmetic).
5. Missing-record bounds: for each Table 5 cell (race × age band) with a published N, the deficit m = max(0, N_pub − N_rec) is allocated all male, then all female; for KBW the two extreme combinations (black all male with white all female, and the reverse) give its bounds. Cells where N_rec ≥ N_pub get no allocation.
6. Census context: the 1911 and 1936 points beside 1921 in the under-five series, with the Cape-to-Union break marked.

## 6. Fixed choices
S3 transcription and crosswalks as committed at c9224fd; no edits. Seed 20261012 (sensitivity 2 only).

## 7. Margins (A8 defaults; unrounded; none chosen by the card author)
- C21 89.2 → [80.28, 98.12]; C80 101.0 → [90.9, 111.1]; K04 105.6 → [95.04, 116.16].
- K04-ex, K18-ex: comparative, d > 0 with the adjusted interval excluding 0.
- KBW: comparative, Δ18 > 0 with the adjusted interval excluding 0.
- Plausibility flag (> 1.5× stated) reported only.

## 8. Verdict tables (primary only; first matching rule decides; exhaustive)
**Point rows (C21, C80, K04)**, point R, band [lo, hi]:
| # | Condition | Verdict |
|---|---|---|
| 0 | R undefined or inputs missing | not-testable |
| 1 | lo ≤ R ≤ hi | confirmed (C21, C80: arithmetic; K04: numerical agreement on the recovered registers) |
| 2 | R < lo | qualified (below the stated value) |
| 3 | R > hi | qualified (above the stated value) |

**C21e, D80:** not-testable (inputs not recovered).

**Comparative rows (K04-ex, K18-ex, KBW)**, estimate e (d04, d18 or Δ18), adjusted interval [el, eu]:
| # | Condition | Verdict |
|---|---|---|
| 0 | an empty cell, or the interval cannot be computed | not-testable |
| 1 | el > 0 | confirmed (reconstruction-conditional) |
| 2 | eu < 0 | overturned (the reverse holds on the recovered registers; reconstruction-conditional) |
| 3 | el ≤ 0 ≤ eu | weakened (not distinguishable from parity or from no black–white difference) |

## 9. Codex review notes and responses (v1 → v2)
1. Persistence after 18 months (K18-ex) and the black–white contrast (KBW) added as primary interpretation rows; the frozen numerical headlines are kept (§1).
2. All Kimberley rows framed as death composition, not mortality risk; mechanism untested; changed coverage cannot overturn (§0).
3. C21 labelled arithmetic on an under-one proxy; census intervals do not vote; the statement that no uncertainty was reported is corrected (Figure 1 shows intervals) (§2, §4).
4. Clustering resolved: eight register years listed; independence assumed and stated; heterogeneity diagnostic pre-specified and wired into the verdict; cluster bootstrap moved to sensitivity 2 (§4).
5. Exact-binomial fallback and the redraw/1% gate removed; F = 0 handled explicitly (§4).
6. Unrounded A8 bounds; A8a not used for directional rows; K04 limited to numerical agreement (§7, §8).
7. Three-row family with Bonferroni adjustment; direct Newcombe interval for the black–white contrast; recoding and age-boundary rules and missing-record bounds specified (§4, §5).
8. Reweighting sensitivity removed.
Optional 1 adopted (sensitivity 1).

### 9b. Compliance check of v2 and responses in v3
1. Heterogeneity gate removed from the verdict; reported as a diagnostic that does not establish independence; ladder symmetric (§4, §8).
2. A4(d): the weakened-only ceiling removed; reconstruction-conditional labelling with the reading stated and recorded as disputed (§0, §10.6).
3. Sensitivities made executable: explicit recodings, age boundary without new date arithmetic, missing-record bounds including KBW (§5).
4. Exact Bonferroni coverage 1 − 0.05/3 (§4). Disclosure: neither the removed gate nor the removed ceiling was informed by results; both were v2 design choices.

## 10. Known limitations at freeze
1. The recovered registers are 92% of the reported records (1915 and 1920 missing), and the authors' race and age coding differed, so the K rows test the readings on the recovered registers, not the authors' file.
2. The independence assumption across deaths is untestable beyond the year-heterogeneity diagnostic (household clustering is unobserved).
3. No population at risk exists, so no mortality-risk statement is possible.
4. The census rows test the authors' own supplementary table, not the census.
5. Disclosure: before writing this card the author saw S3/S5 values: Fig 1 points exact or close (1921: 89.17), the 1980–84 census ratio 101.05, the Kimberley black 0–4 ratio 108.5 and the black 18–59-month ratio 96.4 (95% CI 80–115) on the recovered registers; at the published counts, black (101.0) and white (86.1) were reported as not distinguishable. Margins are A8 defaults, not chosen with reference to these numbers.
6. **Disputed with Codex (A9 cap reached):** Codex holds that A4(d) bars reconstruction-based verdicts on the original claim IDs; the card treats the recovered registers as the primary, consistent with the Tier-2 cards. The synthesis reports both readings.
