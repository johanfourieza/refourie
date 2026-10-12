# P26_NF S3 recreation: decisions (written before any comparison with reported values)

**Independence level: conditional.** Inputs were the allow-listed files only. No reported cell was used to build a rule. The one exception is the folder-to-year assignment (D2), which rests on folder order, the 1887 map, and division sets present in each sheet. Magnitude plausibility checks against T2 totals were looked at while reading the claims file, so the mapping is not blind.

## Decisions
- D1 Race codes (no codebook). CCP.docx lists I, O, E, M. The data also contain K, F, H, B, C, S, Z. Primary black = {K, F, I, B}, read as Kaffir, Fingo, Indigenous, Bantu/Basuto. Excluded: E, O, M, H, C. Sensitivity: drop I; K+F only (`output/sensitivity_black_fall_common_divisions.csv`).
- D2 Surname rule. A year-roll voter is black if the normalised surname appears at least once among 1909 records with a black code ("any" rule, closest to the paper's Excel lookup). Normalisation: lower case, letters only, drop jun/sen and Dutch prefixes (van, der, de, du, le, la, von, den, ten, te), so "Zyl, van" equals "van Zyl". Sensitivity: "majority" rule, i.e. more than 50% of that surname's 1909 records are black-coded.
- D3 1909 database = July 2018 sheets 59 and 57 plus Voters1 sheet 58 (68,815 records, all divisions incl. western; about 25.7k records outside the western list by division string). The paper says 53,000, so the sheet set does not reproduce that count. `13 March 2017b` sheet 58 is a near-duplicate of Voters1 58 and was not used.
- D4 Folder-to-year (ASSUMED; only 1887 is documented in the map file: folders 21 and 22). Folder order is read as chronological, with two sheets per year (an A set: Kimberley, King William's Town, Port Elizabeth, Malmesbury, Namaqualand, Griqualand East; and a B set: Queenstown, Somerset, Stellenbosch, Swellendam, Tembuland, Wodehouse, Uitenhage, Victoria).
  - 1886 = July 18 + Voters1 19
  - 1887 = Voters1 21 (identical to March 2017b 21) + July 22
  - 1889 = July 24 + Voters1 25
  - 1891 = July 30 + July 28
  - 1893 = Voters1 33 + July 34
  - 1895 = no sheet, all 1895 claims unavailable
- D5 Where a division-year occurs in two sheets (Kimberley 1889: July 24 and Voters1 25), keep the sheet with more rows (Voters1 25, 4,442 vs 4,441).
- D6 Division mapping: "East Griqualand" (Voters1 25, 1889) and "Griqualand East" are treated as one. "Woodhouse/Woodhouse Glen Grey" is treated as Wodehouse. "Victoria" = Victoria East only (Victoria West excluded). Division is forward-filled within a sheet because continuation rows are blank. Rows are counted when the surname is non-missing and not ".". No de-duplication.
- D7 Not available: Aliwal North, Cradock, East London, Fort Beaufort, Graaff Reinet, Grahamstown. They are not in the allow-listed files. Also unavailable: 1895; 1891 Queenstown/Tembuland; 1893 Wodehouse partly; Uitenhage and Victoria after 1886; Kimberley/Port Elizabeth and others are covered only where a sheet exists. Because 6 divisions are missing, T1/T2 Total rows, TX_black_fall_*, TX_white_col_fall, TX_1892_* and the "tenth" ratios are unavailable. Literature figures (Roux, Hofmeyr, Statistical Register, Mills, Williams and Elliot, McCracken) are not recreatable. A like-for-like partial fall for the 5 divisions present in both 1886 and 1887 is in `output/partial_total_1886_87_common_divisions.csv`; it is not a claim.
- D8 The manual-count (italic) divisions cannot be identified. The "Italics" column of the 1909 sheets is ignored; all counts are surname-matched.
- D9 No SEs (counts). results_r.csv `se` is empty. TX_records_1909 reports the number of 1909 records read (68,815). TX_wodehouse_drop = black 1886 minus black 1887 for Wodehouse.

## Post-hoc log
- P1 (after the first run) the regex `\s` was rewritten as `[[:space:]]` because of a tool escaping problem. No substantive change.
