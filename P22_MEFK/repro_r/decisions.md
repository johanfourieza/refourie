# P22_MEFK S3 decisions (Tier 3 rebuild)

**Independence level.** High for inputs (raw 2018 transcription only; no code, analysis file or manuscript read). Claude read the published paper (wiki markdown) for classification rules. Sheets 1 and 4-10 of the workbook were not used in the scripts. After results_r.csv was fixed, Sheets 4-10 were inspected only to fill results_original.csv: they hold 2018 summary shares (Sheet4: language 41.3% Dutch, 58.3% English, 0.39% Xhosa; gender 4.8% female) and company subsets. None equals a published number.

**Data used.** `Shareholder Record.xlsx` Sheet2 (455 company records, founding year, nature of business) and Sheet3 (6,845 non-empty shareholder rows: title, gender, language, address, business, shares, Value). `Almanacs.mdb` was read through the 64-bit Access ODBC driver (via .NET; no R package installed). It holds 36 *subscriber* lists (1813-1891: African Court Calendar, Cape Almanac), with no company tables, and so cannot rebuild Figure 1 or TX_co_1861act.

**Choices.**
1. The company record id appears only on the first row of each block in Sheet3. It is filled down, and whitespace is removed (`LC C 6` = `LC C6`).
2. `Value` is treated as the holding's capital value: within 86% of companies Value/No_Shares is constant, which implies a per-share price times shares.
3. Unit for "share of investors" is the shareholder row (the paper's 6,883 is a row count). Investor-level claims (TX_multi, Table 3, diversification) identify an investor by normalised full name. This is a re-coding and merges namesakes.
4. Foreign means an address outside Africa (p.154: "from outside Africa"), coded with country keyword lists. Transvaal, OFS, Natal and Rhodesia count as "other Africa", not foreign.
5. Region (Table 3): towns are mapped to North/East/West by keyword lists. 1,000 or so rows (mostly farm names) stay unassigned. An investor's region is their modal region.
6. Investor class is an ordered regex dictionary on the occupation text, following pp.152-153 and 161: farmers separate; women (housewife, widow, spinster, employed women) and financiers go to middle class; occupation "lady" goes to rentiers; entities go to company investors; blank, "?" or "deceased" means no information. The authors also used genealogical searches (p.161) that do not survive. This is a **re-coding, not a reproduction**.
7. Sector: mining and financial are coded from Sheet2 Nature_of_Business keywords. The paper's 11-sector scheme is not recoverable.
8. Year-specific claims (1895, 1896, Transvaal by period) use the company's founding year.
9. TX_co_1892act counts Sheet2 companies founded 1892-1897 (200; 1892-1896 gives 159). It is a count of the transcribed sample, not of the registry.

**Impossible (status unavailable, 13 claims).** TX_co_1861act (no almanac company list), TX_brit_family (rule undefined), TX_found_mid (founder flag undocumented), distances TX_dist100/TX_dist_op/TX_med_office/TX_med_oper (no geocodes), TX_sector_mid_first/second (no 11-sector scheme), and the external facts TX_popgrowth, TX_urban1891, TX_eur_share, TX_railway.

**Labelling.** In `results_r.csv` the `note` column marks each value as `direct` (raw fields) or `RE-CODING`. Only direct rows test reproducibility. Re-coded rows test whether the published claim survives a transparent recoding of the raw transcription.
