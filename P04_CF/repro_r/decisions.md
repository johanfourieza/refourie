# P04_CF — S3 independent R recreation: decisions

Written 2026-10-11 by the S3 recreation agent **before** any systematic comparison of R output with the published tables. Post-hoc changes are logged at the end, dated, with the reason.

**Outcome-blindness.** The agent has read the paper and `claims.csv`, so it has seen the published numbers. The recreation is *not* outcome-blind.

## Inputs actually used

| file | role |
|---|---|
| `original/CF Mobility/Data/SAF mobility data_10.08.2017.dta` | primary input: one row per son (9,494 rows), with raw occupation term lists `occup1..15` (son) and `f_occup1..9` (father), dates, birth/baptism place strings, genealogical generation, sibling rank, derived province. |
| `original/CF Mobility/Data/CF_mobility_replication_data_anonymized.dta` | used **only** for surname-origin (`origin`), which the raw file does not carry (see D7). |
| `original/CF Mobility/Results latest/Census_Comparisons.xlsx` | census class counts for Tables 3–5 (sheet `Summaries`, cells B3:E7) and the 1911 Union occupation table (sheet `1911`, rows 8–99) for the non-European column of Table 5. |

No `.do`, log, results workbook or code was opened. The raw file also contains coded class variables (`occ_group*`, `f_occ_group*`, `*_hcgroup`, `mobility`, `period`, `hc_share`). They are **not** used in the primary recreation. They are used only (a) for the clearly labelled sensitivity `S-coded` and (b) for the five-class HISCLASS Altham statistics of footnote 9, which cannot be built without a HISCO coding (see D12).

## Independence level

- Occupational classification, last/first occupation, mobility outcome, cohorts, tables, IPF, Altham statistics, regressions: **full** (built from raw term strings with an own dictionary; no code seen).
- Sample: the "raw" file already holds exactly 9,494 rows, i.e. the authors' analysis sample. Sample selection is therefore **inherited**, not recreated. Pairs whose terms are all non-occupational under the own dictionary are dropped (D3), so the R N can be below 9,494.
- Surname origin (Table 11): **conditional** (taken from the anonymised analysis file).
- Province (Table 11): **conditional-lite** (`prov_final` is a derived variable in the raw file; building a gazetteer for ~2,000 place strings was not attempted).
- Footnote-9 five-class Altham: **conditional** (authors' HISCLASS codes).

Overall label for registry: **full** for the analysis chain from raw occupation strings, with the inherited sample, origin and province flagged.

## Decisions

**D1. Unit and sample.** One row = one son with his father. All 9,494 rows are candidates. Sex is male for all rows.

**D2. Occupation terms and "last occupation".** The paper says occupations "are listed chronologically" and uses "the last occupation held". Each son's terms are `occup1..occupK`; the father's are `f_occup1..`. The *last occupation* is the last term (highest index) that the dictionary maps to a class; the *first occupation* (Table 7) is the first such term. Non-occupational terms are skipped, not treated as missing occupations.

*Observation recorded before comparison (data finding, not a choice):* term order is almost fully deterministic across individuals. Across all pairs of terms that co-occur in a list, 99.2% of pair-instances appear in the same order (e.g. "farmer" precedes "teacher" in all 140 co-occurrences, "farmer" precedes "merchant" in all 127). Chronological order would produce both orders. The term lists look like the output of a keyword extractor run in a fixed dictionary order, so "last listed term" is probably not the chronologically last occupation. The recreation follows the paper's stated rule anyway, because that is what the paper describes.

**D3. Dictionary (own, a priori).** The 165 distinct terms are mapped to W (white collar), F (farmer), S (skilled/semi-skilled), U (unskilled) or NA (not an occupation). The full mapping is written to `output/occ_dictionary.csv`. Principles:
- Follow the paper's Table 2 where it names a title: W = teacher, clerk, minister, solicitor, manager, general, merchant, physician, advocate, magistrate; S = carpenter, miner, barber, mason, wheelwright, general dealer, engineer, shopkeeper, butcher, blacksmith, policeman; U = labourer, assistant, digger, fisherman, transport rider, soldier, messenger of the court, prison warder, coachman, apprentice. Table 2 lists "Dealer engineer", read as two titles (general dealer; engineer).
- Otherwise a Ferrie-style rule: professionals, higher and local officials (magistrate, field cornet, judge, councillor, mayor, commissioner …), commissioned officers, merchants, managers and clerical workers → W; craftsmen, traders/shopkeepers, NCOs, police, miners, contractors, overseers → S; labourers, diggers, soldiers, sailors, transport workers, servants, slaves → U; farmer, grazier, sheep farmer, dairy farmer → F.
- **Non-occupations (NA):** `century`, `prisoner`, `smith`, `tenant`, `elder`, `deacon`, `guardian`, `duke`, `deserter`.
  - `tenant` always co-occurs with `lieutenant` (a substring artefact).
  - `general` is an artefact when the same list contains `general dealer` (all 79 co-occurrences in that order). It is dropped then; when alone it is a military general → W (Table 2 lists "General" as W).
  - `smith` (1,077 mentions) never occurs alone and mostly follows `farmer`; it also follows `blacksmith`. Table 2 does not list it among the ten most common skilled titles despite being the most frequent non-farm term, which implies the authors did not code it as skilled. Treated as NA.
  - `prisoner` (391) almost always follows `farmer` and reads as a prisoner of war (Anglo-Boer War), a status rather than an occupation. Not listed in Table 2. NA in the primary specification; sensitivity `S-prisonerU` codes it U.
  - `century` (516; 180 times alone) has no occupational meaning. NA. Individuals whose only term is `century` thus have no occupation.
  - `elder`, `deacon` are church offices held alongside an occupation. NA.
- Pairs in which son or father has no codable term are dropped; the drop count is reported.

**D4. Cohorts.** By son's birth year: Slavery 1806–1834, Stagnation 1835–1867, Diamonds 1868–1886, Gold 1887–1909. The data contain 106 sons born in 1910. The paper labels Gold "1887–1909" but also reports N = 9,494 and Gold n = 2,731, which equals 2,625 (1887–1909) + 106 (1910). **Choice:** include 1910 births in Gold (keeps the published N; the paper's database is described as complete "until 1910"). Sensitivity `S-no1910` drops them.

**D5. Table 1 (birth places).** Place = raw `birth_place`, else raw `baptism_place`. Normalisation: take the town in "farm, dist. Town" strings (the component after "dist."/"dist"/last comma), strip church prefixes (NGK, GK, NHK, "… Kerk,"), strip region suffixes (Kp, KP, Tvl., Natal, OVS), strip trailing digits/dates, unify "Graaff?Reinet"/"Graaff Reinet" → "Graaff-Reinet". Share = count / sons in the cohort **with a known place** (the paper's shares are too large to use all sons as denominator; this is an inference, logged as ambiguity A1). The alternative (all sons) is also written to the output.

**D6. Tables 3, 4, 6, 7.** SAF shares = son's last-occupation class shares by cohort (Table 6 = SAF columns of Tables 3–4). Census shares recomputed from the class counts in `Census_Comparisons.xlsx`/`Summaries` (B3:E6 for 1865, 1875, 1891, 1911; denominators = sum of the four classes). Table 6 "Overall change" = Gold share − Slavery share (percentage points). Table 7 = sons' first vs last occupation class shares, pooled.

**D7. Surname origin.** Not in the raw file. Linked from the anonymised file on a composite key (dob, generation, sibling rank, sibling total, first-son flag, father-generation flag, province, son and father HISCO-class codes, hc_share). 9,176 rows link uniquely. A surname → origin map is built from uniquely linked rows (modal origin per surname) and applied to all rows by surname. Categories: Netherlands (ref), France, Germany, UK, Other west Europe, Other east Europe, Unknown. Unknown is kept as its own dummy (the table does not report it).

**D8. Table 5.** European/white counts = `Summaries` E3:E6 (the 1911 white working-age male counts). Non-European counts are recreated from sheet `1911`, Union total rows, male columns G (urban) + L (rural), with an own mapping of the 1911 occupation orders: Professional orders I.A–B → W; Mercantile (III.E) → W; Post & telegraph → W; Agricultural order IV.G (rows 41–44) → F; Industrial orders V.H–M except mining and V.N general labour, plus board & lodging, rail and sea conveyance → S; mining (V.M.1), mechanical operations/labour (V.N), domestic attendance (II.D.2), roads/tramways, storage and other conveyance → U; domestic duties, indefinite, dependants and unspecified excluded. This is a transparent but low-confidence choice (ambiguity A5): the white column in the workbook does not equal any obvious sum of the same rows, so the authors used another source or age filter for whites.

**D9. Table 8.** Row percentages of son's class by father's class within each cohort; row n; column marginal (son shares).

**D10. Table 9 (Deming–Stephan).** For each later cohort, iterative proportional fitting of its 4×4 count table to the Slavery table's row totals and column totals (tolerance 1e-10). Report adjusted row percentages, adjusted row n (rounded) and column %.

**D11. Table 10 (Altham).** P = pooled Slavery + Stagnation (born before 1868), Q = pooled Diamonds + Gold. Statistic (paper eq. 1, Altham & Ferrie 2007):
d(P,Q) = { Σ_i Σ_j Σ_l Σ_m [ log( p_ij p_lm q_im q_lj / (p_im p_lj q_ij q_lm) ) ]² }^{1/2}, summed over all i,l ∈ 1..r and j,m ∈ 1..c, computed on cell proportions (scale-invariant). d(P,I) uses Q = independence (all log cross-product ratios 0). Footnote 8's printed lower limit "m=j" is read as a typesetting slip for m=1 (A&F sum over all indices); the half-sum variant (m ≥ j) is also reported.
Significance: likelihood-ratio G² tests as in Altham & Ferrie (2007): d(P,I) and d(Q,I) — independence G² in each table, df = 9; d(P,Q) — G² of the log-linear model [GR][GC][RC] (common association) against the saturated model on the 2×4×4 table, df = 9; d^i(P,Q) — the same test with the diagonal cells of both tables excluded (structural zeros), and the statistic restricted to cross-product ratios whose four cells are all off-diagonal, df from the fitted model. Stars at 10/5/1%.
Text p.15 (excluding farmers): drop the farmer row and column → 3×3 tables, same statistics.
Footnote 9 (five categories): uses the authors' HISCLASS five-group codes (`sons_hcgroup`, `fathers_hcgroup`) — conditional; rows with missing codes dropped.

**D12. Table 11 estimator.** The text calls the model a "binary logistic regression" with "odds ratios or relative risks", and the note says "No mobility as base outcome. Estimates expressed as relative risks". "Base outcome" and "relative-risk ratios" is the vocabulary of a multinomial logit; with a binary outcome a multinomial logit with RRR output is numerically identical to a binary logit reported as odds ratios. Pseudo-R² and "Prob > chi-square" are logit/mlogit output. **Decision:** the published-analogue estimator is a binary logit; coefficients are exponentiated (odds ratios). Additionally reported: a relative-risk model (Poisson GLM with log link, robust/clustered SEs — "modified Poisson"), which gives true risk ratios. Mobility is common (~45%), so ORs and RRs differ materially.
- Outcome: 1 if son's last-occupation class ≠ father's last-occupation class.
- Period: Slavery ref.
- Migrant status: the table label says "(Migrant father ref.)"; the text says the dummy is 1 if the father is a first-generation immigrant. These conflict. **Decision:** follow the table: regressor = father is *not* a first-generation immigrant, reference = migrant (first-generation) father. Migrant father = son's genealogical generation is 2 ("b"), i.e. the father is the progenitor (generation "a"); this is checked against the raw `gen_dad` flag and `gen_dad` is used if they agree.
- Origin country: D7. Province: son's birth province from `prov_final` (Cape ref; Natal, OFS, Transvaal; Unknown as own dummy).
- Sibling rank: dummy for later-born son (first-born ref), from raw `first_son`. (Table prints only the reference row.)
- Father's class (Models 2–3): W ref.
- Origin class size (Model 3): percentage of fathers in the son's cohort who are in the son's father's class (0–100 scale, so the odds ratio is per percentage point).
- SEs: conventional (iid) = published analogue; also clustered by father id (`fathers_id`). Stars from conventional SEs. Pseudo-R² = McFadden; "Prob > chi-square" = LR test against the intercept-only model.

**D13. Sensitivities written (not primary):** `S-prisonerU` (prisoner → U), `S-no1910` (drop 1910 births), `S-coded` (authors' coded classes `occ_group_last`/`f_occ_group_last`, conditional) — for Tables 6, 8, 10, 11 headline quantities, in `output/sensitivity.csv`.

## Ambiguities (paper description admits more than one reading)

- A1 Table 1 denominator (all sons vs sons with known place); place-string standardisation unspecified.
- A2 Gold cohort end year (1909 per label; 1910 implied by N).
- A3 Treatment of non-occupational terms (prisoner, century, smith, …) is not described; Table 7's jump in unskilled from 1.7% (first) to 6.2% (last) hints that the authors coded some frequent trailing term as unskilled.
- A4 Migrant dummy direction (text vs table label).
- A5 Table 5 non-European classification of 1911 census orders.
- A6 Altham index range in eq. (1) (m = j vs m = 1).
- A7 Estimator naming (odds ratio vs relative risk) — resolved in D12 as logit OR.
- A8 Whether Table 11 includes Unknown origin/province categories (assumed yes, as dummies).

**Figures.** The paper has no figures, so no `03_figures.R` is written.

## Post-hoc changes log

No change to any primary decision (D1–D13) was made after results were seen. The entries below are diagnostics and observations made after the first full run (2026-10-11), logged so the comparison agent knows what the recreation agent saw.

1. **2026-10-11, after first run — observation, results-informed.** The sensitivity `S-coded` (authors' coded classes, same R code) gives d(P,I) = 19.2, d(Q,I) = 18.8, d(P,Q) = 3.59 (p = 0.087, one star), Gold OR (Model 1) = 1.29, Diamonds OR (Model 2) = 1.12, and Table 6 farmer shares 64.6/49.7. These are close to the published values. The cohorts, the Altham statistic, the LR test and the logit estimator are therefore implemented as the authors did. Gaps in the primary run come from the occupation dictionary. Two exceptions: d^i(P,Q) = 1.27 under `S-coded` against a published 2.39 (the authors' off-diagonal definition differs from D11's), and the origin-class-size OR = 0.97 against a published 1.033 (the authors' share variable differs from D12's).
2. **2026-10-11 — diagnostic, results-informed.** A cross-tab of the own dictionary against the authors' coded last-occupation classes (`_scratch/diag.R` → `output/diag_dictionary_vs_coded.csv`, term-level counts only) shows two terms behind most of the gap. The authors code **`grazier` as Unskilled** (1,056 person-records, about three quarters of all father+son records they class as unskilled; the term always follows `farmer`). They code **`century` as White collar** (393 records, 180 of them with no other term). The own dictionary (F for grazier; NA for century) was kept as the primary specification. Changing it would have meant copying the authors' coding after seeing it. These two choices explain the R primary's higher farmer share (Slavery 74.0 vs 64.6) and lower unskilled share (1.3 vs 8.3). They also explain the much larger d(P,Q) (8.86***, published 3.70*).
3. **2026-10-11 — observation on A4 (migrant direction), results-informed.** Under `S-coded`, the OR on "non-migrant father" in Model 1 is 0.665, and 1/0.665 = 1.50 ≈ published 1.497. The published coefficient therefore belongs to a dummy for a *migrant* father with non-migrant fathers as reference, as the text says. The table label "(Migrant father ref.)" is wrong. The primary keeps the pre-registered coding (D12). The comparison should use 1/value for T11_r5_*. Its significance is unchanged.
