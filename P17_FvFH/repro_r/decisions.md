# P17_FvFH S3 decisions

**Independence level: conditional.** `Statafiles/opgaafrolle.dta` (the authors' cleaned file) supplies sample counts. Prices come from the authors' documented plan (`Summary ... .xlsx`, Burghers sheet), not from an independent archival source. Claims were read only for IDs and to match category names; no values were compared before the scripts ran.

## Choices
- Sample counts (T2 cur) are sums of m, v, s, d, k, sm, sv, ss, sd over `jaar` in the .dta. The burgher total is m+v+s+d. The 1700 sample uses the rows with jaar==1700.
- T2 VdR totals come from the Population sheet of `Van Duin en Ross.xlsx` (1702, 1723, 1757); the burgher total is men+women+boys+girls.
- Proportion captured = sample / VdR total, per the Table 2 note. 1700 has no VdR row, so 1702 is used.
- wf = 1/pc for burghers and knechts, per the Table 2 note.
- VOC slaves, and sample VOC slaves and VOC/burgher ratio, are set to 0 in the sample (the opgaafrolle contain no VOC-owned slaves by construction). The VdR VOC slave totals were **not found** in the Population, Company establishment or other sheets of the VdR workbook.
- T3 vdr = Company establishment sheet (1724, 1756 rows).
- T4 knecht represented population = sample knechts x wf (1700 uses the 1702 weight).
- T1 = Burghers sheet price column. The sheet lists a 1757 price for grain (6) and for the other goods. No conversion check (rijksdaalder to guilder) was possible from the file.

## Unavailable or not attempted
- VOC employee TEPC microdata were not recovered, so T3 tepc/pct/wf and all VOC rows in T4 are unavailable. So are every whole-population Gini or Theil in T5-T9, F2 and the text rows that need VOC employees.
- VdR VOC slave totals were not found, so T2 vdr_voc_slaves, vdr_voc_burgher and slave weighting factors (male, female, boy, girl) are unavailable. T4 slave pops depend on them.
- Farming-burgher, farming-pachter and non-farming-burgher incomes (T4 means, T5 fb column, T6 fb, T7, T8): **not attempted**. The .dta has no codebook (labels are bare uppercase names; `kode` is all missing), so the mapping of kgs/kgw/rgs/... to output units is ambiguous. The turn budget was also too small to reconstruct the income pipeline credibly. Slave and knecht income levels (52, 26, 204, ...) have no derivation in the allow-listed files.
- T9 and the other text rows: quoted from the literature or text, not recreated.

## Observations (logged before any comparison)
- The .dta gives 1723 burgher total 2357 and male slaves 2256 (the published table: 2395 and 2293). The other categories match the table exactly in the years where I looked (1700, 1702, 1757). The .dta is a conditional input; the 1723 gap flows into the 1723 pc and wf.
- No post-hoc changes made.
