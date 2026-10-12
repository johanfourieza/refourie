# P10_FI — S3 independent R recreation: decisions

Paper: Fourie & Inwood (2019), *History of the Family* 24(3): 629–652.
Agent: S3 recreation agent, 11 October 2026. R 4.5.2.

## Independence level: `full`

- Inputs read: the paper (wiki markdown), `PROTOCOL.md`, `CLAUDE.md`, `claims.csv`, `claims_spec.md`, the raw transcription `CT 1 March 2019.xlsx` (sheet *Cape Town*) and `Cape Town sex ratio.xlsx`. No original code, `.RData`, `Occupations.xlsx`, `Interrace.xlsx`, `Tables.xlsx`, `Code*.docx`, `repro_original/`, `compare/` or `audit.md` was opened.
- Every derived variable (race groups, interracial marker, segregation, sex ratio, literacy, condition, foreign birth, occupation classes) was built from raw fields by this agent.
- **Not outcome-blind.** The published numbers in `claims.csv` were visible throughout. One post-hoc choice is logged below (D-PH1).
- Nothing was committed to git by this agent, because the brief limits writes to `repro_r/` and the D: scratch folder. The coordinator should commit `repro_r/` before comparison.

## Pipeline

| script | does |
|---|---|
| `01_clean.R` | reads raw data, drops names, codes all variables, writes `p10_clean.rds` to `D:\Data\ReplicateMe\P10_FI\repro_r\_scratch\`; writes dictionaries and coverage to `output/` |
| `02_analysis.R` | Tables 1–4, text numbers, Table 3 (iid and parish-clustered SEs), alternative specifications (`output/alt_specs.csv`), `results_r.csv` |
| `03_figures.R` | Figure 3 (`output/fig3_share_interracial.pdf/png`) and a reference Figure 6 |

`results_r.csv`: one row per claim (248). `se` holds the **conventional (iid) SE**, the analogue of the published SE. Parish-clustered SEs are in `output/table3_coefs_long.csv` and `output/table3_cluster.tex`. 11 claims are `not-attempted`: 1936 census religion counts (5), von Scholtz secondary-source numbers (5) and `txt_p646_n_occ` (the paper gives no separate construction for it; the spec-4 N is in `T3_obs_c4`).

## Pre-comparison decisions (made from the paper's description)

**D1. Data vintage (largest issue).** The file holds 47,246 records. The paper reports 33,086 transcribed records and a sample of 23,651. Applying the paper's own rule (1911–1964, race known for both spouses) gives **34,046**. All 46 parishes are Cape Town Anglican parishes. No field marks which records existed in the authors' working file, and the parish lookup workbook is on the deny list. I therefore used the full file and **did not try to subset it to hit 23,651**, since any such subset would be fitted to the target. All counts and Ns are expected to differ for reasons of `data-vintage`. Shares, means and coefficients are comparable only to the extent that the added records resemble the original ones. The added records are mostly coloured and white husbands (black husbands 1,388 against 1,288).

**D2. Sample.** `Date year` in 1911–1964, with both race fields mapping to white, coloured or black. Missing race (`.`, NA) and non-race strings (`Widow`, `v`) are excluded.

**D3. Race groups (note 17).** The mapping is in `output/dict_race.csv`. It produces 61 distinct raw strings that map to a group, against 41 in the paper; the difference comes from spelling variants and vintage. Choices:
- Indian, Chinese, Asiatic, Cape Malay, Mauritian, St Helenian, Indo-European, Egyptian and West Indian → **coloured**. This follows the three-way 1950 Population Registration Act scheme ("the three categories that would later be used by the apartheid-era government"), in which Asians were sub-groups of Coloured.
- Unspecified `Non-European` (152 husbands, 152 wives) → **coloured**, the modal non-European group in Anglican Cape Town.
- Krooman/Kruman, West Africa, Sudanese, American Negro, Amatonga, Mozambique, K, Hanga and Aboriginal → **black**. Each of these has n ≤ 5.
- Race at marriage comes from the `Male race`/`Female race` columns. Later reclassifications (`Race change`) are not applied; they are only counted (`txt_p639_reclass`).

**D4. Interracial** = husband group ≠ wife group. Type codes are `wc`, `bc`, `cw`, `cb`, `wb` and `bw`.

**D5. Ages.** Numeric strings from 10 to 100. `Full`, `F`, `Minor`, `M` and `.` → NA. Regressions use listwise deletion, which is the paper's apparent source of N < sample.

**D6. Literacy.** `Signed` = Yes → 1, No → 0, anything else → NA. **Regression literacy gap = |m − f|**, following the text: "1 … either the husband or the wife could not sign, … 0 … both … or neither". **The Table 2 "Literacy difference" column = mean(m − f)**, because the printed column is negative for some rows, so it must be signed.

**D7. Civil status.** Male: Bachelor (0/0), Widower, Divorced or Divorcee. Combined strings ("Divorced/Widower", "Widower + Divorced") get widower = 1 and divorcee = 1. Female: Spinster, Widow, Divorced or Divorcee. Other strings (`.`, occupations, "Married in Court" and so on) → NA, so they are dropped from specs 2–4. This is consistent with spec 2 N being slightly below spec 1 N in the paper.

**D8. Foreign-born.** `country` recorded and not South Africa. Misspellings of South Africa, Transkei, Pondoland, Zululand, Amatongaland and one place-name entry ("Plumstead") count as SA. `.`, `?` and NA → NA. Country is almost never recorded before the 1920s, which is consistent with "available from 1921".

**D9. Sex ratio, by race of the husband.** The Table 2 means by male race match this reading. The census benchmarks are the typed constants in sheet *Calculations*, for 1921, 1936, 1946 and 1960. For 1960 only totals and males are typed, so females = total − males. Ratio = males/females, linearly interpolated between benchmarks. **Primary: NA outside 1921–1960**, because the census input ends in 1960. Alternative C carries the 1960 value forward to 1961–64. I did not use the workbook's own interpolated sheet. Flag: the 1946 white-male count (52,512) is a typed constant but equals the linear interpolation 46,482 + 10 × 603 exactly. It may therefore be an interpolation rather than a census figure; I used it as given.

**D10. Segregation.** The paper says "weighted HHI of racial concentration by parish and year … only whites → 1". I used **HHI = Σ_r s_r²** over the three groups, where s_r is the share of race r among *all spouses (husbands and wives) with known race married in that parish-year*, using all records rather than only the analysis sample. I read "weighted" as share-weighting, meaning the HHI is computed from individual counts. The weights are not stated. Alternative D uses husbands only. The parish-year includes the observation's own marriage, which is mechanical but follows the paper's description. Figure 6 (reference only) is the unweighted mean across parishes.

**D11. Occupations (own HISCO-style dictionary).** I wrote ordered regex rules, first match wins (`output/dict_occupation_rules.csv`). Coverage by rule is in `dict_occupation_coverage.csv`, and the string → class mapping for strings with n ≥ 5 is in `dict_occupation_strings_n5plus.csv`. Classes:
- `prof` = HISCO 0–3 (professional, technical, administrative, managerial, clerical) → "manager" dummies;
- `sales` = HISCO 4–5 (sales and service, including domestic service, police and soldiers) → "sales" dummies;
- `prod` = HISCO 6–9 (agriculture, production, transport, labourers). This is the reference group and the residual for any unmatched non-empty string.

Non-occupations → NA and dropped from spec 4: blank, none, unemployed, household/home/domestic duties, housewife, housework, student, retired, pensioner, gentleman. The **primary** spec 4 sample therefore requires a coded occupation for both spouses (N = 15,928). Alternative E keeps wives with a non-occupation entry in the reference group. Known ambiguities: "Engineer" (n = 380) is coded professional; "Fireman" is coded service (it may be a railway stoker); "Domestic duties" is coded as a non-occupation. The unique-string counts reported for p.638/640 are distinct raw strings among sample records (5,671 male and 1,601 female).

**D12. Table 3 specification.** Dependent variable = interracial dummy. Regressors follow the table rows. **All four specifications include month dummies, parish dummies and a linear year** (table note: "All specifications include a month-dummy, a parish-dummy and a year-variable"). This applies to spec 1 too, even though no Year row is printed for column 1. Act = 1 if year ≥ 1949. Base categories: coloured husband and wife, bachelor/spinster, SA-born, production occupations, January, and the lowest parish ID. The constants therefore depend on R's base levels; the spec-1 logit constant is large because some parishes have no interracial marriages (quasi-separation in `glm`, which is kept, as the paper's N implies no parishes were dropped).
- Spec 1: logit (`glm`, binomial) with race, ages, Act, segregation and literacy gap.
- Spec 2: OLS (LPM), adding widower, male divorcee, widow and female divorcee.
- Spec 3: adds sex ratio and foreign-born for both spouses. The sample is 1921–1960 by construction (D9).
- Spec 4: adds the occupation dummies.
- **Recorded alternatives** (`output/alt_specs.csv`): (A) eq. (1) year fixed effects in place of linear year. The Act dummy is then collinear with the year effects. `lm` drops an aliased year dummy instead, so the Act number it prints is an arbitrary contrast between years and is not identified. Under A, segregation is −0.0265 (0.0053). (B) spec-1 logit without year. (C) sex ratio carried forward. (D) husbands-only segregation. (E) wives' non-occupations kept in the reference group. (F) logit versions of specs 2–4 (note 19).

**D13. Standard errors.** Conventional (iid) OLS and ML SEs are the published analogue. Parish-clustered SEs use `sandwich::vcovCL`, HC1 with parish clusters, 40 to 45 clusters. Stars in the `.tex` tables use 10/5/1%, which the paper does not state.

**D14. Text shares.**
- "pre-WWI" = 1911–1913 pooled.
- "1930s" = 1930–1939.
- "after 1949" = 1950–1964, all in percent.
- The 1925 "conservative" share = white-husband interracial / (white-husband interracial + white–white), following the paper's arithmetic 4/(4+105). The 1935 and 1945 shares use the same definition, because the text says "a similar decline, from 3.6% in 1925".
- The note-15 share and Figure 3 = all interracial / all marriages.
- `txt_p637_1925_ratio` = our 1925 share ÷ 0.9.

**D15. Table 2 NA row** = records in 1911–1964 whose husband's race is missing, regardless of the wife's race. Interracial and sex ratio are left blank, as printed.

## Post-hoc log (after seeing results)

- **D-PH1.** The literacy-gap coefficient under D6 is negative and insignificant: spec 2 −0.0013 (0.0018), against the published 0.005*** (0.002). I added alternative **G**, which uses the *signed* m − f difference. It gives +0.0044 (0.0016) in spec 2, close to the published value. This suggests the published regressions may have used the signed difference rather than the gap described in the text. The primary result keeps the text's definition. This is a lead for S4/S5 and was not used to change any primary number.
- No other primary choice was changed after results were seen.

## Observations for the comparison stage (not adjustments)

- Male age spec 2: we get 0.00038 (0.00011). This supports reading the published "0.003**" as a misprint for 0.0003 (claims_spec item 6).
- Act, spec 1 logit: −0.66 with year included and −1.25 without year (alt B, closer to the published −1.41). This hints that the published logit omitted the linear year. Recorded only; primary follows the table notes.
- Act, spec 2: our +0.0044 (iid p = 0.01; clustered p = 0.15) against the published 0.0003 (n.s.).
- Segregation is negative and significant in all four specifications under both SE types. Spec 2: −0.033 (iid 0.005; clustered 0.011), against the published −0.027 (0.005).
