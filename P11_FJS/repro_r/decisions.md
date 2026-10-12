# P11_FJS — S3 independent R recreation: decisions

Written 11 October 2026 before results were compared with the published values. Any later change is logged at the end.

**Not outcome-blind.** The agent saw the published numbers (the paper and `claims.csv`) before and during the recreation.

## Inputs

- Paper: `papers/JF_EtAl_PublicFinancesUnder.pdf` and `wiki/papers/JF_EtAl_PublicFinancesUnder.md` (p.17 method paragraph, pp.18–19 text, Images 2–9).
- `base.dta` (17,292 opgaafrol household records, 23 census years 1663–1773, districts `ds` 1–5).
- `Loanfarms.xls`, sheet `Loanfarms` (8,240 loan-farm register entries, 1687–1795).
- Not used, by the deny-list: `fiscalpolicy.do`, `Fiscal policy.xlsx`, `repro_original/`, `compare/`, `audit.md`.

## Independence level

**Full, with one disclosed caveat.** Both data files are raw transcriptions; every tax variable is built here from the p.17 description, and no original code was seen. Caveat: while inspecting `Loanfarms.xls` I saw its sheet `Sheet2`, which tabulates yearly new applications and renewals and multiplies them by 12 rixdollars. This is an intermediate calculation by the authors. It shaped decision D8 (counting new applications plus renewals in the census year) and is disclosed here. I recount everything from the raw register in sheet `Loanfarms` and do not read `Sheet2` in the scripts.

## Decisions on ambiguities

**D1. Unit of observation.** Each record in `base.dta` is one household (a taxpayer entry). I keep all records for the year, from all districts, including widows (`wed`) and free blacks (`vs`). The paper does not restrict the sample (spec (d)).

**D2. Variable reading** (Dutch opgaaf column abbreviations): `sm sv ss sd` are slave men, women, boys and girls (slaves = their sum); `pd` horses; `bste` cattle; `skpe` sheep; `vk` pigs; `wingst` vines; `wyn` wine in leaguers; `kgs/kgw` wheat sown/reaped, `rgs/rgw` rye, `cgs/cgw` barley, in muids; `ds` district (1 = Cape, 2 = Stellenbosch, 3 = Drakenstein, 4 = Swellendam, 5 appears only in 1688). The large codes 99, 999 and 9999 appear only a handful of times, alongside other large holdings, so I treat them as real values rather than missing-value codes.

**D3. Poll and hearth tax.** "Agricultural assets" means any positive cattle, sheep, pigs, vines, wine, or wheat, rye or barley sown or reaped. Horses do not count ("excluding horses"). A household with no agricultural assets pays:
- 32 stuivers if it owns no slaves;
- if it owns slaves, 4 rixdollars (192 stuivers) of hearth tax in the Cape district (`ds == 1`, used as the proxy for Cape Town, since the data do not separate town from district), or 32 stuivers elsewhere.

A household with agricultural assets pays no poll tax: its liability comes through the asset taxes, as in the Stellenbosch and Swellendam rule (p.13) that the poll tax fell on those without livestock. The tax is charged once per household, not per adult. I use 32 stuivers everywhere and not Swellendam's 36, because p.17 does so. In the Image 7 classification, hearth tax is counted under "poll tax".
*Robustness R1:* poll tax of 32 stuivers on every household that owns no cattle or sheep, whatever its other assets.

**D4. Wine tax.** `wyn` leaguers × 1 rixdollar before 1743 and × 3 rixdollars from 1743 (the 1752, 1757, 1762 and 1773 rolls). Vines are not taxed.

**D5. Grain tax.** 10% of the value of the recorded harvest (reaped, not sown): 0.1 × (6·`kgw` + 3·(`rgw` + `cgw`)) rixdollars. I make no adjustment for the one-third declaration rate (p.10) or for seed set-aside, because p.17 applies the rate to the recorded yield.

**D6. Livestock ("meat") tax.** 1 stuiver per head of cattle plus 16 stuivers per 100 sheep, charged pro rata (`skpe`×0.16 stuivers) and not per completed hundred. Pigs and horses are untaxed.

**D7. Currency.** All outputs are in Cape guilders: 1 guilder = 16 stuivers and 1 rixdollar = 48 stuivers = 3 guilders (fn 28).

**D8. Property tax (Image 7 only).** p.17 says property tax is excluded, but Image 7 shows a property-tax stream. `Loanfarms.xls` is the only property source supplied, so I build the stream from it. Property tax in year t = (number of register entries with `TYPE` "New application" or "Renewal" and `YEAR1` = t) × the annual loan-farm rent × 3 guilders. Hunting/salt permits, cancelled, crossed-out and withdrawn entries, and entries with blank `TYPE`, are excluded. The rent is 12 rixdollars (p.10: "twelve rixdollars, later increased to twenty-four"). The paper does not date the increase. Main choice: 24 rixdollars from 1732, the date of the tenure reform the paper mentions in the same passage, and 12 before. See the post-hoc log. Property tax is not assigned to households and is excluded from Images 8 and 9.

**D9. Streams not in the supplied data.** Wine pacht, brandy pacht and sales to foreigners have no source among the allowed files. I do not recreate them (`unavailable`). As a result the Image 7 bar totals, the 174 434 guilder 1773 total, the "more than sixty percent" direct-tax share and the 1777 extrapolation cannot be recreated (`unavailable`). For context only, I report the direct-tax subtotal (poll + wine + grain + meat + property) in `output/`.

**D10. Slave-owning deciles (Image 9, headline).** Each year, I rank households by total slaves and split them into ten equal-sized groups. The share is the decile's sum of household tax (D3–D6: poll/hearth + wine + grain + livestock) divided by the year's total. Most households own no slaves, so ties are common at the decile cut-points. Main: ties are broken at random, and I report the mean over 500 seeded draws (seed 20131201). *Robustness:* (R2) ties kept together, with the top group = households whose slave count is ≥ the 90th percentile (this group can exceed 10%); (R3/R4) ties broken by tax, ascending or descending, which brackets the effect of tie-breaking. Years: 1700, 1719, 1731, 1738, 1741, 1757 and 1773, as in Image 9.

**D11. Inference.** The paper reports no standard errors. For the top-decile shares I report a household bootstrap SE (500 resamples within the year, random tie-breaking redrawn each time) in the `se` column as descriptive sampling noise. There is no published analogue. `n` = households in the year.

**D12. Image 8.** I plot the total tax by source (poll, wheat [= grain], wine, meat) over the ten Image 7 years against the number of slaves owned (0–49), on a log scale. I report no claim for it.

**D13. Images 2–6 (secondary-source tables).** These cannot be recreated from data. I transcribe the inputs (revenue, expenditure, GDP and the other secondary figures) from the paper into `01_clean.R` and mark them `unavailable` (no data source). I recompute the derived cells (deficit = expenditure − revenue; Rev/GDP, Exp/GDP and Def/GDP in %) from the transcribed inputs as an arithmetic check, and report them as `r` values.

**D14. Parameters and conversions** (`txt_p17_*`, `txt_fn28_*`, `txt_p10_grain_declared`). These are inputs, applied as stated. Status `not-attempted`; no value is reported.

**D15. Digitised Image 7 segments** (`I7_1773_*`, `I7_1700_winepacht`). The `r` values are my poll, wine, grain, meat and property streams. The pacht and foreign-sales segments are `unavailable`.

## Post-hoc log

- **PH1 (D8, rent schedule).** In the scoping step, before the scripts were written, I saw that 1773 has 128 new applications plus renewals. At 12 rixdollars this gives 4,608 guilders; the digitised Image 7 property segment is about 9,200 guilders, which matches 24 rixdollars (9,216). The 1732 switch date in D8 comes from the historiography of loan-farm rent, but this observation informed the choice. *Alternative:* 12 rixdollars throughout, also reported in `output/image7_components.csv` (`property_12rd`).
- **PH2.** None of the D1–D15 choices was changed after the outputs were produced (first full run, 11 October 2026). `PH1` is the only post-hoc element.
