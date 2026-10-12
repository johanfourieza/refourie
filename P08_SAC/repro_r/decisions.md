# P08_SAC — S3 independent R recreation: decisions

Written 11 October 2026 by the S3 agent, before any systematic comparison with the published values. The recreation is **not outcome-blind**: the agent read the paper and `claims.csv`, so it knew the published numbers while making these choices (PROTOCOL S3).

## Independence level: `full`

- **Data used:** only sheet `Original` of `original/FourieSAC2026/SAC final.xlsx`, which holds the combined raw attestation transcription (64 columns of transcribed text, such as "5ft 8inch", "10st 7lbs", "5 shillings/day", free-text calling). The agent did not open the `Augmented` sheet or any other sheet. It also did not open `SAC_FGM.dta`, the per-letter files in `SAC/Originals/`, any .do file, `fgm.txt`, `Descriptives.xlsx`, `repro_original/`, `compare/` or `audit.md`.
- **Code seen:** none. Every variable (wage, height, weight, age, chest, region, Afrikaans flag, HISCO codes, class, died, tenure) is built from the transcribed strings in `01_clean.R`.
- **Caveat:** the `Original` sheet is the authors' combined workbook, not the 30 per-letter originals. The per-letter files were not reconciled against it.

## Unit of observation

| Issue | Choice |
|---|---|
| Service term | A row of `Original` that carries a first name or surname. This gives 10,404 rows (paper: 10,399). |
| Person | A run of consecutive rows with the same value of the transcribers' `Unique` counter. The counter restarts in each source file. This gives 8,839 persons, with 1,540 having two or more terms, 24 three or more and 1 four (paper: 8,873; 1,512; 13; 1). Names were not used for matching. |
| First term | The first row of each run. In 1,535 of 1,540 multi-term runs the first row is also the earliest enlistment date, and repeat rows mostly leave country, height and calling blank. |
| "All repeat observations are dropped" (Table 1 note) | Tables 1, 2, 3, 5, 6 and 7 and all person-level text numbers use first terms only. Table 3 is also run on first terms (an assumption: the paper does not state the sample). Term-level text numbers (enlistment year, month and place, term length, causes of exit, deaths) use all terms. |

## Variable construction

- **Wage.** Shillings plus pence/12, parsed from strings such as "5 shillings, 3d/day" and "6 & sixpence/day". The source says *per day*, while the paper labels the unit *shillings per week*. The agent kept the numbers as transcribed. Log wage = ln(shillings).
- **Height.** Feet and inches, including fractions ("5ft 7 3/8inch"; "5ft 7.5/8inch" is read as 7 5/8), converted at 2.54 cm per inch. Values outside 145–205 cm are set to missing.
- **Weight.** Stones and pounds or pounds only, converted at 0.45359 kg per pound. Values outside 38–120 kg are set to missing. Typos such as "10st 6inch" are read as pounds.
- **Age.** The reported age, including "20 & 10mos" forms. Where it is missing, age is computed from the date of birth (d/m/yyyy; "Mon yyyy" → 15th; yyyy → 1 July) and the enlistment date (day 15 if the day is missing). The valid range is 14–65. The youngest and oldest recruits (text p.586) use reported age only, following fn 22.
- **Chest.** The mean of `Chestmin` and `Chestmax` when both are present, otherwise `Chest`. Units are inches, as transcribed; the paper's "centimetres" is treated as a mislabel.
- **Married** = 1 for "Married…" or "Separated", 0 for Single or Widower.
- **RC** = 1 if religion is Roman Catholic, Catholic or RC. "Catholic Apostolic" counts as 0.
- **Died** = 1 if the cause of discharge mentions died, death, dead, deceased, killed, drowned or suicide. It is defined for terms with a non-missing cause. Cause-of-death groups: battle (killed, wound, action), enteric, drowning, suicide, unknown (bare "died" or "deceased"), other.
- **Tenure.** Days parsed from `Lengthorig` as 365·years + 30.44·months + days, and missing if `Lengthorig` is missing. Discharge dates are not used as a fallback. Deaths are excluded (text p.588).
- **Exit categories** (text p.588), applied in this priority order: died > desertion > purchase > transfer (including rejoining the regiment) > medically unfit or invalided > dismissal (including unsuitable, misconduct and undesirable) > retrenchment (reduction of establishment, no longer required, abolition) > time expired, expiration or completion > free discharge > other. The denominator is all terms with a cause.
- **Region of birth.** From `Country`, falling back on `Birthplace` when `Country` is missing. Mapping:
  - Americas = Canada, Newfoundland, the USA, South America and the West Indies.
  - Australasia = the Australian colonies and New Zealand.
  - Asia = India, Ceylon, Japan, China, Asia Minor and Mauritius.
  - Europe = continental Europe, Gibraltar, Malta and Turkey.
  - England includes the Channel Islands and the Isle of Man. "S. Wales", "South Wales" and "N. Wales" are coded as Wales, not New South Wales.
  - Boer republics = Transvaal, ORC/OFS, "Burgher" and "Dutchman", plus Transvaal towns entered as country.
  - **Southern Africa** (the paper's "Southern Africa" or "Cape Colony & Natal") = Cape Colony (including Griqualand, Kimberley and Transkei), Natal, plain "South Africa" or "Africa", and the three recruits from elsewhere in southern Africa (Rhodesia, Matabeleland, Swaziland, German SA).
- **Afrikaans (Dutch-speaker) flag** = born in the Boer republics or Southern Africa *and* a Boer surname. The paper classified surnames without giving its rule (fn 18), so the agent wrote one before inspecting outcomes: a Dutch particle (van, de, du, le, te), Dutch orthography (`ij`, `-wyk`/`-dyk`), or a generic list of about 200 common Afrikaner surnames written from general knowledge. German, English and Scandinavian surnames are not counted. Non-SA-born recruits are 0.
- **Table 2 shares.**
  - Blue eyes = any eye colour containing "blue". Red or ruddy hair = red, ruddy, auburn or ginger.
  - Black language and French come from `Other languages?`. Black language means any mention of Kaffir, Zulu, Sotho or Basuto, Swazi, Matabele or Tebele, Shona, Xhosa, Sechuana, Shangaan or "native".
  - Tattoo = "tattoo" in Marks and Scars.
  - The denominator is non-missing responses for each item.
  - Ride, shoot and swim = 1 for "Yes" and for qualified positives (fair, fairly, good, well). They are 0 for No, Not, Nil, None, "a little", "little", "slight", "very little" and "learning".

## HISCO coding (own, documented in `output/hisco_rules.csv` and `output/hisco_dictionary.csv`)

- The agent coded 1,339 distinct normalised calling strings to HISCO **minor group** (2 digits) with ordered regex rules (first match wins). Parenthetical text is dropped. A compound calling ("soldier & clerk", "farmer/draper") takes the code of the **first-listed** occupation. "X's assistant" is 45 when X is a retail trade, and otherwise takes X's group. All strings were coded; "–" is treated as missing.
- The minor-group labels follow the paper's Table 6: 02 is merged into 03 (architects, engineers); 07 into 06 (nursing); 00 = gentleman, nil or none; 10 = students.
- **Departures from what the published table implies, kept on principle:**
  - "Farmer", "farming", "rancher", "planter" and "grazier" → **61**, the standard HISCO 61110 for general farmer. The published Table 6 puts only 58 recruits in 61 and 1,654 in 62, which suggests the authors coded "farmer" into 62. Major group 6 is unaffected.
  - "Engineer" (unqualified) → 03, but locomotive or railway engineer → 98, stationary engineer → 96, marine engineer → 04, and cycle or motor engineer → 84.
  - "Fireman" → 98 (locomotive or marine stoker), not firefighter.
  - "Mason" and "stone mason" → 95; stone cutter and monumental mason → 82.
  - "Storekeeper" → 41 (colonial usage: a shop owner), "storeman" → 39.
  - "Warehouseman" → 97.
  - Grooms, stablemen, stockmen, gardeners and horse breakers → 62.
  - Farrier and shoeing smith → 83.
- **Class (Tables 4, 5 and the Table 1 "Farmer" column).** The paper gives "farmers, upper-class and skilled workers, unskilled and labourers" without a mapping. The agent's rule:
  - Farmers = minor group 61.
  - Lower = 53–56, 59, 62–64, 97–99 (service, farm and forestry workers, material handlers, transport operators, labourers).
  - Upper, middle = all other groups, including 00 (gentlemen and no occupation, by the paper's own association of "gentlemen" with white-collar recruits), 58 (protective services) and skilled production (71–96).
- Table 4 shows the class by enlistment year 1900–1906. "Total" is all first terms with a calling, whatever the year.

## Table 3 (wage regressions)

- OLS of ln(wage). The paper names no estimator; the agent assumed OLS.
- **Spec 1:** Afrikaans only, on the SA-born sample (Boer republics + Southern Africa). The paper does not describe the Spec 1 sample. The agent chose SA-born because N = 554 is close to the 563 "locals", and because Spec 1's higher R² requires a sample other than Specs 2–4.
- **Spec 2:** + age (years), height (cm), weight (kg), married. All regions.
- **Spec 3:** + HISCO major-group dummies (6 = reference) + region dummies (Boer republics = reference).
- **Spec 4:** + enlistment-year dummies 1901–1907 (1900 = reference). Enlistments in 1908–1909 are dropped because the table prints no dummies for them.
- Each specification uses its own complete-case sample.
- **Standard errors:** conventional OLS (`results_r.csv`, the published analogue) and HC1 (`output/table3_long.csv`, `table3_hc1.tex`). The `_t` claims carry the conventional t. The paper prints positive coefficients with a negative bracketed statistic (claims_spec (e) 4). The agent reports the t with its true sign; S4 should compare absolute values.
- **Text gaps (p.594):** `tx_p594_gap_dutch` = −100·(exp(b_Afrikaans,S4) − 1); `tx_p594_gap_boer` = 100·(1 − exp(−b_England,S4)), the Boer-republic shortfall relative to England.

## Text claims: other choices

- **Birthplace shares (pp.584–585):** first terms with a known country. "Locals" = Cape + Natal + Transvaal + OFS + unspecified Boer republic + "South Africa". Canada = Canada, Nova Scotia and Vancouver (Newfoundland excluded). US = all USA variants.
- **"Colonial" heights (pp.588, 591):** pooled mean for the Americas, Australasia, Asia, Southern Africa and the Boer republics. "England and Scotland" is the pooled mean of the two.
- **Dutch- vs English-surname heights:** SA-born recruits with a valid height. A Welch t-test is in `output/height_dutch_english_test.csv`.
- **p.592:** 5s share = wage exactly 5; "4 shillings" = 4 ≤ wage < 5; "3 shillings" = wage < 4 (first terms).
- **p.597:**
  - "Professional and technical" = HISCO majors 0 + 1 for both Asia and the Boer republics.
  - Clerical = minor 30; protective = minor 58.
  - Welsh miners = minor 71 share of Welsh recruits.
  - Golfers, bushmen and cowboys = calling-string counts over all terms.
- **p.599 tenure gap:** mean tenure of recruits born in the British Isles and Europe, minus the Boer-republic mean.
- **Not attempted** (external to the data): `tx_p581_*` (force strength, districts, posts) and `tx_p591_ht_ww1/ww2`. `tx_p597_5each` was also not attempted, because it is a compound claim about three groups.

## Post-hoc log

Changes made after the first full run, and why:

1. Corrections to the HISCO regexes before any comparison with Tables 6 and 7: substring bugs in which "plumber" matched "lumber", "plasterer" matched "laster", "cabinet" matched "^cab", "contractor" matched "actor", "outfitter" matched "fitter", "nurseryman" matched "nurse" and "mineral" matched "miner". Rule order was also fixed so that silversmith and coppersmith are not caught by "smith$", stone or paper cutter not by "cutter", and gas or electrical fitter not by "fitter". These fixes came from reading the dictionary output, not from published values.
2. No other change was made after outputs were produced. In particular, the agent did not tune the class mapping, the surname list or any sample definition to the published numbers.

Outputs live in `output/`. Derived microdata (without names) are only in `D:/Data/ReplicateMe/P08_SAC/repro_r/_scratch/`. Nothing was committed to git by this agent; the coordinator should commit `repro_r/` before S4.
