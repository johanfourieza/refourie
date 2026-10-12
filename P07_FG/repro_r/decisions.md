# P07_FG S3 independent R recreation: decisions

Agent: S3 recreation subagent, 11 October 2026. Allow-list respected: I read PROTOCOL.md, CLAUDE.md, the paper (PDF text re-extracted with PyMuPDF, private-use digit glyphs U+F643–F64C remapped to 0–9), claims.csv, claims_spec.md and `Data.xlsx`. I opened `missingpeople.dta` only to read its schema. It is the same 17,292 × 41 opgaaf extract as `Data.xlsx` (lower-case names), so it adds nothing and I did not use it. I saw no .do files, no other original files, no repro_original/, no compare/ and no audit.md.

**Independence level: `full`.** The input is the rawest opgaaf extraction, and I saw no code. **Not outcome-blind.** The published numbers were visible throughout (protocol S3).

**Order of work, stated honestly.** Before writing the scripts I explored the data and tested several readings against published counts (Table 1 slave counts, Table 1 Swellendam cells, Table 3–5 N). The *primary* specification below follows the paper's text wherever the text decides the question. I chose it before running the final scripts. Where only the published numbers settled a question, the choice is marked **POST-HOC**, kept out of `results_r.csv`, and written to `output/sensitivity.csv`.

## Primary specification (text-based)

- **D1 Herd value** = Vhorses + Vcattle + Vsheep. The workbook values livestock at constant prices (horse Rds 15.8, cattle 8.7, sheep 1.0, the same in every year). The paper gives no prices, but two of its anchors match exactly: Botha in 1773 = 3,375.2 and Tas in 1709 = 2,041.2. Pigs are excluded because the text says "cattle, sheep, and horses".
- **D2 Districts.** Code 1 = Cape, 2 = Stellenbosch (Tas), 3 = Drakenstein, 4 = Swellendam (Botha). Code 5 (1688 only, 130 households) and code 0 (12 households in 1773) cannot be identified. They are counted in "All regions" but not in "Cape, Stellenbosch, and Drakenstein" (CSD = codes 1–3), and they get no Khoesan.
- **D3 Farmers.** "ignored all households that did not produce any of the commodities" is implemented as Output > 0 (any livestock, wine or grain value). This reading reproduces the Table 1 slave columns exactly in 14 of 15 years (1723 is off by 1 because of a code-4 household).
- **D4 Ratio categories** use total slaves owned: >5, 1–5, 0. Botha is described by his total slaves. Ratios as stated: Swellendam 67.5/57.5/47.5; Stellenbosch and Drakenstein 135/115/95; Cape 0. Khoesan per household = herd / ratio, unrounded.
- **D5 Rounding.** Yearly sums are rounded to integers. Each Total row is the sum of the rounded yearly cells over the 15 Table 1 years. The Swellendam total also includes any pre-1757 cell (only 1723 has one, = 6).
- **D6 Growth rate 1685–1773** = compound annual rate between the two endpoints. Log-linear OLS over the census years is a sensitivity.
- **D7 Baseline series (p.203).** The text is ambiguous. My reading: a linear trend from 50,000 (1652) to X (1780), with level cuts of 20% from 1713 and 5% from 1755, and X chosen so that the 1780 value equals 23,000. The trend's log growth, −0.39% p.a., is "the negative growth rate of 0.4 per cent". After 1780 the series is extended at that rate. It is used only in Figure 2.
- **D8 Productivity (Tables 3–6).**
  - (a) Years 1719, 1723, 1731, 1738, 1741, 1757 and 1773 (1931 read as 1731); districts 1–3.
  - (b) L = adult male slaves (Slavemales > 0 required); L* = Slavemales + imputed Khoesan.
  - (c) "Wheat" = Wheatreaped (mudden); wine = Wine (leaguers).
  - (d) Y/L is the **mean of farm-level ratios**. This is the only reading under which the published district Total rows equal N-weighted means of the district rows. Ratio of sums is sensitivity S3.
  - (e) Samples:
    - T3: herd ≤ 1000, wheat > 0, no viticulture (vines = 0 and wine = 0), following the table note rather than the contradictory "no viticulture" wording on p.208.
    - T4: herd ≤ 1000, wine > 0, no wheat (sown = reaped = 0).
    - T5: wheat > 0 or wine > 0, with **no herd cap**, because none is stated.
    - T6: the T5 sample split by total slaves (1–5 vs >5), consistent with D4.
  - (f) The Worden replication (p.208–9) uses Cape 1741, grain farmers with no viticulture, herd ≤ 400 or ≤ 1000, and the same Y/L.
  - (g) Wine redo, Stellenbosch 1773: wine farmers with no wheat.
- **Table 2** transcribes an archival document that is not in the data: `not-attempted`.
- **Table 7, F3 and tx_p213/214** need the Fourie–von Fintel (2011) income data and the Fourie–van Zanden GDP series. Neither is on the allow-list or in `Data.xlsx`: `unavailable`. `output/table7_proxy_illustrative.csv` shows the mechanism on a crude proxy: 1757 settler per-capita gross output, and slaves and Khoesan at the 10th-percentile settler income. It is **not comparable** to Table 7 and is not reported as a result.
- Other text claims that rest on external sources (Elphick, Guelke, FvZ 1795, 1806 census, 1830s rolls, Table 2 ratios) are `not-attempted`.

## Post-hoc findings (informed by published values; sensitivity only)

- **D9 / S1 Stellenbosch ratio.** I regressed the published Table 1 CSD Khoesan on herd value by district × slave category. Drakenstein recovers exactly 95/115/135. Stellenbosch recovers 142.4/171.8/202.8, i.e. **1.5 × the stated ratios** (142.5/172.5/202.5). With that change, every published Table 1 Khoesan cell 1663–1773 is reproduced exactly; the exception is the 1723 All-regions cell (+6, from the code-4 household). The paper does not state this ratio. The text says "double" for both districts. Under the stated ratios, CSD Khoesan is 10–50% above the published values (1773: 7,163 vs 6,843 for All regions).
- **S6 CSD = All − Swellendam.** Code-0 households are included in CSD under this reading. It reproduces the 1773 CSD slaves (6,369) and the Swellendam totals (6,783; 1,028).
- **S7 Grain output.** With Y = wheat + rye + barley, the Worden replication reproduces exactly: 22.3 (N = 4) and 16.0 (N = 17). Both Ns already match under the primary specification. This suggests the "wheat" productivity in Tables 3, 5 and 6 may be grain output, but I did not adopt it.
- **S5 Herd cap ≤ 1000 for Tables 5–6.** It brings the T5 total N to 1,062 (published 1,096), against 1,724 in the primary specification. The published Table 5 N is far below any uncapped definition.
- **S8 (S7 + S1 + S5 combined)** gives T5 totals of 9.3 / 5.2 (published 9.0 / 5.1). Table 6 Ns still do not match (568 vs 432 in the >5 group).
- **Not resolved:** the Table 3 and Table 4 Ns are close but not exact under every variant I tried. I stopped searching at that point to avoid fitting to the outcome.

## Notes for comparison

- The Swellendam Khoesan : male slave ratio, as the text defines it (6,783 / 738 male slaves, and the data give 738), is 9.2, not 6.6.
- The compound growth of Khoesan 1685–1773 is 4.3% under the primary specification and 4.7% from the published endpoints; the text says 3.8%. Log-linear growth under the primary specification is 3.9%.
