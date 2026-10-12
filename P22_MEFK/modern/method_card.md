# Method card: P22_MEFK, the Cape private capital market 1892–1902

Status: v3 (2026-10-12). Author: coordinator (Claude Opus 5.5, subscription), Tier-3 reduced protocol (WAVE3_PLAN.md). v1 reviewed by Codex (reviews/P22_MEFK_codex_S6card.md).

## 0. Type of analysis
(iv) **partial identification** (primary for every class and location row) plus (i) one coding correction, on the **S3 re-coding** of the raw 2018 transcription (`Shareholder Record.xlsx`, Sheets 2–3). The authors' classified file, their genealogical infilling of occupations and their 263-company selection rule do not survive (S5 F1, F2, F8). Every verdict is **reconstruction-conditional**: it asks whether the published shares are compatible with the surviving raw records under a transparent coding.

The population differs from the paper's (285 companies with shareholder rows against 263; shareholder rows against investors; recorded `Value` against paid capital). The surviving transcription is the only record of this sample, so the primary analysis runs on it and its verdicts are carried to the original claim IDs **labelled reconstruction-conditional**, the treatment used for every Tier-2 paper whose primary ran on recovered records (P12, P17, P21). A4(d) is read as governing sensitivities that change the population of an available primary; it does not bar a primary on the only surviving records (Codex disputes this reading; §10.6). Verdict ladders are symmetric.

**Finite-record descriptive exception (A8 comparative rule).** The transcription is treated as the complete set of surviving records for this convenience sample, and the authors disclaim sampling inference (p.152). Comparative rows are therefore judged on identification bounds, not confidence intervals, as in the P26 card's complete-enumeration exception; no population-inference claim is made. Sampling intervals are sensitivities only and never vote.

## 1. Claims family (headline rows, frozen at S0) and interpretations
| Row | claim_id | Published | Authors' interpretation | Type (A8) |
|---|---|---|---|---|
| M-inv | TX_mid_inv | 27% | middle-class share of investors | point (share) |
| M-inv-pl | TX_mid_inv (reading) | — | "the largest group of investors" | comparative (plurality) |
| M-cap | TX_cap_mid | 31% | middle-class share of total capital | point (share) |
| M-cap-pl | TX_cap_mid (reading) | — | "the largest source of private capital" (plurality; claims_spec §c). The abstract's "most" as a majority is sensitivity 4 | comparative (plurality) |
| F-cap | TX_cap_foreign | 11% | foreign share of total capital | point (share) |
| F-cap8 | TX_foreign_cap_8 | 8% | "foreign capital constituted 8%": tested as the same capital share as F-cap (the paper prints two values for one quantity; S5 F6) | point (share) |
| L-inv | TX_local | 95% | share of shareholders who were local | point (share) |
| A-sh | TX_africans_share | 0.1% | African share of shareholders | point (share) |
| A-n | TX_afr_n | 15 | number of African investors | point (count) |

**Aggregation to headline claim_ids (fixed):** both rows are always reported. The single verdict carried to the registry for TX_mid_inv is that of M-inv-pl, and for TX_cap_mid that of M-cap-pl, because the plurality is the authors' stated reading (claims_spec §c); the numeric rows M-inv and M-cap are reported beside them and never replace them. Every other claim_id has one row.

## 2. Defects addressed
F2/F3: class shares depend on undocumented infilling (unknown occupation 45% of rows in the raw file: "Information not available" 2,912 plus "Unclassified occupation" 169, against 35% printed) → identified sets over all allocations of the unknowns. F6: three foreign figures → each tested against one definition. S3 coding defect found in review: the UK pattern `london` also matches "East London" (Eastern Cape) → corrected (§3). F4: plurality vs "most" → separate primary and sensitivity.

## 3. Estimands and coding
- Unit: shareholder row (S3 decision 3). Capital: `Value` of the holding (S3 decision 2). Rows with missing, non-finite or negative `Value` are excluded from capital denominators and numerators; their count is reported.
- Classes (S3 dictionary, mutually exclusive): Middle class, Businessmen, Farmers, Rentiers, Working class, Company investors; unknown U = "Information not available" ∪ "Unclassified occupation".
- **Correction C1:** addresses containing "east london" are coded "Cape/Other Africa", never UK/foreign. All other S3 location codings are unchanged.
- Location: Foreign (outside Africa), Local/Africa, and unknown location UL = rows whose address is empty or matches no keyword list (S3 defaults these to non-foreign; here they are unknown).
- For class k: s_k^L = n_k / N, s_k^U = (n_k + n_U) / N; capital analogues c_k^L, c_k^U with Value.
- Plurality contrast vs each competitor j: D_j ∈ [s_mid^L − s_j^U, s_mid^U − s_j^L] (sharp bounds for a pairwise difference when unknowns can go to either class).
- Foreign capital: c_for ∈ [c_for^L, c_for^U] with UL rows as the unknowns; local share s_loc ∈ [s_loc^L, s_loc^U] likewise.
- African rows: Language field = Xhosa (direct field, no unknowns); s_afr = n_afr / N.

## 4. Primary analysis (one per row)
- **Class and location point rows (M-inv, M-cap, F-cap, F-cap8, L-inv):** the identified set [L, U] computed as in §3.
- **Plurality rows:** the identified sets for D_j for every competitor j ∈ {Businessmen, Farmers, Rentiers, Working class, Company investors}.
- **A-sh, A-n:** direct values (no unknowns in the Language field).
- No sampling inference in the primary (convenience sample; §0).
- **Failure rules:** if the S3 scripts with C1 cannot be re-run, or N = 0, or total Value = 0, the affected rows are not-testable.

## 5. Admissible sensitivities (reported, never verdict-setting; each answers a changed question)
1. Point estimates with unknowns in the denominator but allocated to none (the S3 numbers) and with unknowns excluded from the denominator.
2. Company-cluster bootstrap (B = 999, seed 20261012; resample companies with all their rows; ratio of totals recomputed per draw) percentile intervals for the point estimates in 1. Reported with cluster-size and capital-concentration diagnostics (largest company's share of Value; investors appearing in several companies). It describes across-company variability in the convenience sample only.
3. Women and financiers moved out of the middle class: women to "Rentiers", financiers to "Businessmen" (F13).
4. "Most capital" as a majority: identified set for c_mid − 0.5.
5. Investor-level shares (normalised full name; namesakes merged; investors with conflicting classes take their modal class, ties to unknown).
6. Foreign = outside the Cape Colony (Transvaal, OFS, Natal and Rhodesia counted foreign).
7. Leave-one-company-out range for the point c_mid and c_for.
8. Founding-cohort series of the foreign capital share (1892–1902), labelled cohort composition, not investment over time (F11).

## 6. Fixed choices
S3 scripts at c9224fd plus correction C1; no other edits. Seed 20261012. R 4.5.2.

## 7. Margins (A8/A8a defaults; none chosen by the card author; unrounded)
- M-inv 27%: smaller of ±3 pp and ±10% → [24.3, 29.7].
- M-cap 31% (> 0.30): ±3 pp → [28.0, 34.0].
- F-cap 11%: [9.9, 12.1]. F-cap8 8%: [7.2, 8.8]. L-inv 95%: [92.0, 98.0]. A-sh 0.1%: [0.09, 0.11]. A-n 15: [13.5, 16.5].
- Plurality: A8 comparative, D_j > 0 for every j.

## 8. Verdict tables (primary only; first matching rule decides; exhaustive)
**Identified-set point rows (M-inv, M-cap, F-cap, F-cap8, L-inv)**, identified set [L, U], band [lo, hi]:
| # | Condition | Verdict |
|---|---|---|
| 0 | failure rule | not-testable |
| 1 | lo ≤ L and U ≤ hi (set inside the band) | confirmed |
| 2 | U < lo (set wholly below) | qualified (below the stated value) |
| 3 | L > hi (set wholly above) | qualified (above the stated value) |
| 4 | otherwise (set overlaps the band but is not inside it) | not-testable (compatible, not identified) |

**Direct point rows (A-sh, A-n)**, value x:
| # | Condition | Verdict |
|---|---|---|
| 0 | failure rule | not-testable |
| 1 | lo ≤ x ≤ hi | confirmed |
| 2 | x < lo | qualified (below the stated value) |
| 3 | x > hi | qualified (above the stated value) |

**Plurality rows (M-inv-pl, M-cap-pl)**, identified sets [D_j^L, D_j^U]:
| # | Condition | Verdict |
|---|---|---|
| 0 | failure rule | not-testable |
| 1 | D_j^L > 0 for every j | confirmed |
| 2 | D_j^U ≤ 0 for some j (a strict plurality is ruled out under every allocation) | overturned (strict plurality ruled out; reconstruction-conditional) |
| 3 | otherwise | not-testable (compatible, not identified) |

## 9. Codex review notes and responses (v1 → v2)
1. Partial identification made primary for every class and location row (§0, §4); bootstrap moved to sensitivity 2.
2. Changed population: overturned made unreachable for every row; verdicts labelled reconstruction-conditional (§0).
3. Verdict rules rewritten for identified sets: inside / wholly outside / overlap; "x = 0 ⇒ overturned" removed (§8).
4. Separate row labels and a fixed aggregation rule (§1); plurality is the primary reading, majority a sensitivity (5.4).
5. Competitors enumerated from the S3 class list (§3); pairwise sharp bounds replace a bootstrapped maximum.
6. Company resampling defined as across-company variability only, with diagnostics (5.2).
7. "East London" correction C1; unmatched addresses treated as unknown location; Value missingness rule; F-cap8 defined as a capital share (§1, §3).
8. Sensitivities given executable rules and labelled as changed questions (§5).
Optional 1 adopted (5.8). Optional 2: B kept at 999 because intervals do not vote.

### 9b. Compliance check of v2 and responses in v3
1. Changed-population verdicts: reconstruction-conditional verdicts kept on the original claim IDs, with the reading of A4(d) stated in §0 and recorded as disputed (§10.6); the asymmetric ceiling removed.
2. A8 comparative inference: finite-record descriptive exception stated explicitly (§0).
3. Strict-plurality boundary: adverse rule changed to D_j^U ≤ 0, "strict plurality ruled out" (§8).
Disclosure: the removed ceiling was a v2 design choice, not informed by results.

## 10. Known limitations at freeze
1. All class rows rest on a re-coding; the authors' HISCO coding and infilling are lost, and 45% of rows have no usable occupation, so most class verdicts will likely be "compatible, not identified".
2. The 263-company selection rule is unknown; all 285 companies with shareholder rows are used.
3. `Value` is the recorded holding value, not necessarily paid-up capital.
4. Namesakes are merged in investor-level sensitivities.
5. Disclosure: before writing this card the author saw S3/S5 values: s_mid 18.4% of rows, c_mid 16.0% (businessmen 19.7%), foreign capital 11.36%, foreign rows 4.9%, 4.86 for the row mapped to "8%", local rows 95.1%, African share 0.22%, 15 African investors. The unknown-occupation share (45%) was seen in the S3 output. Margins are A8/A8a defaults, not chosen with reference to these numbers.
6. **Disputed with Codex (A9 cap reached):** Codex's compliance check holds that A4(d) bars reconstruction-based verdicts on the original claim IDs; the card treats the surviving transcription as the primary, consistent with the Tier-2 cards. The synthesis reports both readings.
