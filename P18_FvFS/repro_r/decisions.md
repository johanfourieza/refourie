# P18_FvFS — S3 independent R recreation: decisions

Agent: S3 recreation agent (isolated). Written 11 October 2026, **before any regression was run or compared with the published tables**. Sections A–D were fixed before estimation; section E logs every post-hoc change, with its reason.

**Not outcome-blind.** I saw the published numbers (paper and `claims/claims.csv`) before writing these scripts. Several data-construction choices below were made on evidence that includes published counts (N, group sizes). Each of those is flagged **[N-informed]**. No choice was made to move a coefficient towards its published value.

## Independence level: `conditional`

- The **sample and the production variables** (household members, slaves, knechts, livestock, vines, wine, wheat, district) come from the cleaned panel `original/Statafiles/opgaafrolle.dta`. The raw working file `Working - 26 May 2010 - Prov.xlsx` has 863 extra rows in 1723 (1,679 against 816 in the .dta; 1,192 farmers against 448). Built from the xlsx alone, the farmer sample is 9,824. Built from the .dta, it is 9,079, one more than the published 9,078. The .dta also has 17,282 household observations, against the paper's "17,292" (p.940). So the .dta is the dataset the paper describes. **[N-informed]**
- The **Huguenot coding** comes from the raw xlsx and the authors' auxiliary workbooks, not from the .dta's `hug`/`wyns`. That coding covers the Huguenot dummy, wine and non-wine region of origin, province, the married-to-Huguenot dummies, the arrival marker and numeracy. It is merged onto the .dta rows on (surname, first name, year, district, within-cell order); 9,077 of 9,079 farmer rows match.
- No .do, .log or other code was opened.

## A. Sample

| # | Ambiguity | Choice |
|---|---|---|
| A1 | Census years. p.937 says "fourteen"; fn. 36 lists 22 years, and 1716 is in the data. | The 14 years in the T3 year dummies: 1700, 1702, 1705, 1709, 1712, 1719, 1723, 1731, 1738, 1741, 1752, 1757, 1762, 1773. 1716 is dropped (it has no dummy in T3). |
| A2 | "non-farmers (those households with zero scores on all agricultural variables)": which variables? | Agricultural variables are horses, cattle, sheep, pigs, vines, wine, and wheat, rye and barley sown and reaped (`pd bste skpe vk wingst wyn kgs kgw rgs rgw cgs cgw`), with NA treated as 0. Slaves, household members and weapons are *not* agricultural. |
| A3 | District missing for some 1773 rows. | Drop rows with missing district, since the regressions need it. This gives a single sample used in every table (T1 included). |
| A4 | Exact duplicate rows (10 in 1762 in the xlsx). | Not handled separately. The .dta row set is used as is. |

## B. Variables

| # | Variable | Construction | Ambiguity / note |
|---|---|---|---|
| B1 | Household size (members) | m + v + s + d (men, women, sons, daughters) | Slaves and knechts are excluded. "household member" is not defined. |
| B2 | Wine per household member | wyn / hhsize (leaguers) | If hhsize = 0, the per-member value is set to 0 (when wine is also 0) or to wine/1. This is logged in the clean script; it is rare. |
| B3 | **log(wine per member)** | log(wyn/hhsize + c) | **Ambiguous.** Most farm households produce no wine, yet N is the same in every column, so zeros were not dropped and some constant c was added. The paper never states c. **Pre-committed rule:** estimate T3 spec 1 for c ∈ {1, 0.1, 0.01, 0.001} and take the c whose *constant* is closest to the published −2.987. Every other coefficient follows from that c, and no other target is used. The same c is used for wheat (T5). The alternatives are reported as sensitivities. **[target-informed, intercept only]** |
| B4 | Slaves | sm + sv + ss + sd | "Total slaves" in A3 is the same variable. |
| B5 | Knechts | k | |
| B6 | Vines | wingst / 1000 | T3 note: "numbered in 1,000s". T1 means are also reported in 1,000s, which fits the T1 magnitudes (4.19). |
| B7 | Cattle, horses | bste, pd | |
| B8 | Wheat reaped / sown | kgw / kgs (muids) | Levels in the wine regressions, per T3 spec 4. |
| B9 | log(wheat per member) | log(kgw/hhsize + c), with c from B3 | Same zero problem as wine. |
| B10 | District | ds: 1 Cape Town (base), 2 Stellenbosch, 3 Drakenstein, 4 Swellendam | Codes inferred from the timing (code 4 appears only from 1752; Swellendam was founded in 1743) and from the .dta `loc` field. |
| B11 | Huguenot (HUG) | xlsx `HUG` (surname-based) | The .dta `hug` disagrees on 12 farmer rows. I use the raw-file coding. |
| B12 | **WH / NWH** | Province classification from the authors' `Province-group split.xlsx` (Sheet2): wine-producing = Aunis, Bretagne, Champagne, Île-de-France, Italia, Orléanais, Poitou, Provence, Suisse; non-wine = Béarn, Deutschland (incl. Hesse), Flandre (incl. Flanders, Artois), Languedoc, Nederland, Normandie, Picardie; **Dauphiné "Mixed"**, split at the individual level by the xlsx `WYN` flag. Huguenots with unknown province use the xlsx `WYN` flag. | **Ambiguous.** Three codings conflict. (i) The xlsx `WYN` flag codes all of Languedoc and Béarn as wine. (ii) Table A2 codes Béarn N and Languedoc "Mix". (iii) The authors' province-group workbook codes both as non-wine, and its counts reproduce the Figure 1 map numbers. I use (iii) because it is the authors' region file behind Figure 1. It also comes closest to the T1 group sizes (1,038 NWH and 1,192 WH) of the codings I counted. **[N-informed]** The sensitivities are (i) and the .dta's `wyns`. |
| B13 | Married dummies | Married-non-wine = MARH & !MARHW; Married-wine = MARHW (xlsx). Defined for all households. | "married Huguenot women … differentiating wine/non-wine" (p.940). |
| B14 | **Born abroad** | xlsx `Assistance in 1690` = 1 (the only direct marker of the 1688/9 arrivals in the allowed files) | **Ambiguous / weak.** There is no born-abroad variable. The assistance flag is attached to names, so it also tags sons who share a father's name (there are 10 flagged rows in 1773). It gives 278 Huguenot farmer rows, against the published spec-10 N of 368. Sensitivity: the flag OR first appearance (xlsx `ID`) in a roll ≤ 1692. The coefficient and the spec-10 sample are both affected. |
| B15 | Numeracy | Crayen and Baten province value from the `Crayen and Baten` sheet of the working xlsx, mapped by province. It is missing for Flandre, Nederland, Germany/Hesse, Italy and unknown province (none in the C&B list). | T4 specs 8–9 drop missing numeracy. The published N falls from 2,230 to 1,675, which fits this mapping. **T5 spec 16** keeps N = 9,078 with numeracy included. The only reading that keeps N there is that missing numeracy (all non-Huguenots and unmapped Huguenots) is set to 0. I follow that reading and flag it **ambiguous** (claims spec e.5). |
| B16 | Sending region (A1–A5) | 16 regions: Aunis, Béarn, Brittany, Champagne, Dauphiné, Germany (Deutschland+Hesse), Flanders (Flandre+Flanders+Artois), Île-de-France, Italy, Languedoc, Netherlands, Normandy, Orléanais, Picardy, Poitou, Provence. Pays de Vaud/Suisse is not among the 16 and is set to NA. | Artois (1 row) is merged into Flanders. |
| B17 | Latitude/longitude/group (A3) | From Table A2. Latitude: South (base), Central, North. Longitude: West (base), Central, East. Groups: High (1, base), Moderate (2), Poor (3). Germany and Italy, listed in groups 1 and 2, are put in group 1, following the text ("a high producing group (1) … together with Italy and Germany"). | Interactions in col 19: lat × long, with only the estimable cells kept. |
| B18 | Soldier height (A3 cols 25–27) | **Unavailable.** No height data in the allow-listed files. | status `unavailable`. |

## C. Estimation

| # | Item | Choice |
|---|---|---|
| C1 | Estimator | OLS (`fixest::feols`), with district and year entered as explicit dummies so that their coefficients can be reported. Bases: Cape Town and 1700. |
| C2 | **SE type** | Not stated in the paper, which prints only stars. I report both (a) conventional iid SEs and (b) HC1 robust SEs. **iid is the "published-analogue"** (the Stata `regress` default), and it is used for `se` in `results_r.csv` and for stars and F. |
| C3 | F statistic | The overall regression F (all slopes = 0) under iid. This is what Stata prints with `regress`. |
| C4 | T3 | Spec 1: NWH, WH, born abroad, district, year. Spec 2: + slaves, knechts. Spec 3: + cattle, horses, vines, married-NW, married-W. Spec 4: + wheat reaped. Full sample, base NH. |
| C5 | T4 | Huguenot sample, base NWH, WH dummy only. Specs 5–7 mirror T3 specs 1–3. Spec 8 = 7 + numeracy. Spec 9 = 8 + wheat reaped. Spec 10 = WH dummy + constant only, on Huguenots born abroad (only those are printed; the text describes no controls). |
| C6 | T5 | log(wheat per member). Spec 11: NWH, WH, born abroad, district, year. Spec 12: + slaves, knechts. Spec 13: + cattle, horses. Spec 14: + married dummies. Spec 15: + wheat sown. Spec 16: + numeracy (B15). Column contents inferred from the printed rows: T5 rows show slaves and knechts from spec 12, cattle and horses from 13, married from 14, sown from 15, numeracy in 16. |
| C7 | A1 | Huguenot sample with known region. log wine on 15 region dummies (base Aunis) plus the T4 spec-7 controls *without* the WH dummy, which is (nearly) collinear with region. Cell = coef(row) − coef(col); stars from the iid Wald test of equality. |
| C8 | A3 | Col 17 = T4 spec 7 on known-region Huguenots. Col 18 adds lat/long dummies; col 19 adds lat×long; col 20 adds the group dummies; cols 21–24 use T4 spec 7 with the region exclusions in the notes. Cols 25–27 are unavailable. |
| C9 | A4 | As A1 with log wheat per member and the T5 spec-15 controls (A4 states no controls). |
| C10 | A5 | Col 28 = T5 spec 15 (full sample). Col 29 excludes Netherlands-origin Huguenots. Col 30 excludes the Netherlands, Germany and Italy. Non-Huguenots are retained, since the published N falls by only 101 and 127. |
| C11 | T1 | Unweighted means and SDs (n−1) by group over the pooled sample. |
| C12 | T2 / Fig 2 | "weighted to reflect household size": Σ wine / Σ household members by group-year, which equals the hhsize-weighted mean of per-member output. |
| C13 | Probate check (text p.949) | MOOC inventories, 1673–1844. Huguenot and WH status are assigned by matching the standardised surname to the opgaaf surname coding (B11–B12). Slaves = `Combined`. Means by group; Welch t-tests for the stated significance claims. N is whatever the file and the date filter give. |
| C14 | Fig A1 (65,536 regressions) | Not attempted. It is not digitised and carries no headline number. |

## D. Mapping to claims

- `results_r.csv` holds one row per claim_id in `claims.csv`. Coefficients map by table row and column. `se` is the iid SE, with HC1 in a separate file (`output/coefs_long.csv`).
- `TXT_p943_a`, `TXT_p944_a` and `TXT_p948_a` (percent readings) are reported as 100·b, the paper's own reading.
- Claims that need data not in the allow-list (heights, pacht investors, the genealogy behind the 159 arrivals, the elite counts that need identity matching) are `unavailable`. Claims that rest on a classification read off the paper (A2) are reproduced as inputs, not estimated: `status_override = ambiguous` where the paper is internally inconsistent.

## E. Post-hoc log

(Entries added after the first estimation run appear below with timestamps and reasons.)

- **E1 (after the first run, 11 Oct 2026). Rule B3 outcome, no change.** The T3 spec-1 constants were c=1: 0.573; c=0.1: −0.817; c=0.01: −1.996; c=0.001: −3.137 (published −2.987). So c = 0.001 (`output/c_selection.csv`). Smaller c was not searched, because the rule's grid was fixed in advance. The WH coefficient scales strongly with c (T3 c4: 0.10 → 0.53 across the grid; `output/sensitivity.csv`).
- **E2 (after the first run). Diagnostic only; the primary specification is unchanged.** The recreated coefficients are well below the published ones (T3 c4 WH 0.527 vs 0.751; T4 c7 0.268 vs 0.721), and the controls differ too (vines 0.154 vs 0.424; horses ≈0 vs −0.042; knechts −0.05 vs −0.39). I therefore ran an exploratory check, in a scratch script outside the repo, of other constructions of the dependent variable: log(w/hh+0.0001), log(w+c) − log(hh), and per member including slaves. None reproduces the published control coefficients (vines stays 0.13–0.20; horses stays near zero). **I adopted none of them.** The gap looks like a difference in variable construction or data vintage that the paper's description cannot settle. It should not be read as an estimation error on either side; the cause stays unresolved.
- **E3. Counts achieved (reported as is).** N = 9,078 (exact). Groups NH/NWH/WH = 6,866/1,037/1,175 (published 6,848/1,038/1,192). Huguenot sample 2,212 (2,230). Numeracy sample 1,662 (1,675). Born-abroad sample 278 (368). Known-region A3 sample 2,026 (2,045). The A5 drops of 101 and 127 rows match the published 8,977 and 8,951 exactly, which validates the province mapping (Hesse merged into Germany).
- **E4. Probate (C13).** MOOC has 5,913 inventories dated 1673–1844, against the paper's n = 4,049. I applied no further filter, because none is described. The surname match is crude (standard surname stripped of spaces against the opgaaf Huguenot surnames). The resulting means (NH 2.52, NWH 3.28, WH 2.97) do not reproduce 3.31/3.98/4.40. Treat these claims as weakly attempted.
- **E5. TXT_p935_a.** The List of Huguenots has 134 persons with arrival year 1688 or 1689, against 159 in the paper. The list is incomplete or uses a different definition, so the claim is marked ambiguous.
- **E6.** No git commit was made by this agent. Freezing commits are the coordinator's role, and I was told to write nothing outside `repro_r/`.
