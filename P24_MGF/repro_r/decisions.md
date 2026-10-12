# P24_MGF S3 decisions (Tier 3: rebuild from surviving inputs)

**Independence level.** Rebuilt from raw inputs without original code (none survives) and without reading the manuscripts or any analysis workbook (none survives). The agent saw the published paper (claims, wiki) before building, so the recreation is blind to code but not to published numbers. The Kimberley classification rules were fixed from the label distributions, before the comparison was run, and were not tuned towards the published Table 5.

**Inputs.**
1. `Supplementary Data - DATA POPULATION` PDF (authors' published table; under-five males, females and printed sex ratios by race, 13 census years, 1894-2011). Transcribed with `pdftotext -raw` (the `-layout` mode scrambles columns). 39 rows, 9 numbers each; every printed sex ratio recomputes from the printed counts to 2 dp.
2. Kimberley death-register transcriptions: 1895; the 1900 sheet of the 1900 workbook (its 1895 sheet duplicates the 1895 file); the combined 1905+1910 workbook (1,777 + 1,258 + one stray 1919 row, kept); 1925, 1930, 1935, 1940. Total 12,092 records. Not used: the alternative 1905 transcription (`2020-04 AF ...`, same row count as the 1905 part of the combined file) and the one-row template.

**Choices.**
- Sex ratio = 100 x M/F. 95% CI: exact Clopper-Pearson interval on p = M/(M+F), mapped to SR = 100p/(1-p). The paper does not state its CI method. se in results_r.csv is the delta-method se of SR (Poisson counts).
- Figure 1 black 1921 uses the printed under-one counts, as the supplementary note and the Fig 1 notes say.
- Table 4 "SR 0-4" (not a frozen target of this task, but recomputable): census under-five ratio from the supplementary table for the census inside each Yearbook period: 1955-65 -> 1960, 1965-74 -> 1970, 1975-84 -> 1980, 1985-90 -> 1991; black 1980-84 -> 1980, 1985-90 -> 1991. This mapping is an inference; 9 of 10 cells then match exactly.
- Kimberley sex: Male/Manlik/Mannelik/Boy/Seun = M; Female/Vroulik variants/Girl = F; 8 records missing.
- Kimberley age converted to months. Bare numbers are years; units classified by the first letters of the word after each number (tolerates typos such as "Yaers", "Monhs", "Houers"); minutes/hours/"newly born"/"immediately after birth" = 0; fractions (½, ¼, 1/2) handled. "Adult", "Unknown", ranges ("between 50 and 60") left missing (95 records, all adults or unknown).
- Kimberley race: European/White/Blanke and named European nationalities = white; Mixed/Coloured/Hottentot/Malay/Griqua/Korana/Bastaard/Boesman = coloured; Indian/Chinese/Arab/Abyssinian = asian_other (excluded, 155 records); all named African groups (Kaffir, Native, Bechuana, Basuto, Fingo, Zulu, Xosa, Barolong/Morolong, Batlhaping variants, Shangaan, Mozambique, Blantyre etc.) = black; illegible/unknown missing (85). Crosswalk counts in `output/race_crosswalk_counts.csv`.
- Table 5 bands (main): [0,6), [6,18), [18,60) months, ages 0-4 = under 60 months. Sensitivities: inclusive boundaries at 6 and 18 months; excluding 1900 (siege of Kimberley); 1895-1910 only. All in `output/table5_rebuild.csv`.
- Text claims on p.138 recomputed from the rebuilt table: "more than 101" = black 18-59 month SR; "92" = white 18-59 month SR; "fell by X%" = 100 x (1 - male deaths 18-59m / male deaths 0-5m).

**What was impossible and why.**
- Tables 1-3, 6, Table 4 SR at birth / at death / differences, Fig 2-3, the 1911/1936 under-one adjustments (1.44, 1.11) and the 1921 estimates (90.61, 90.28), the 1960 cohort count, DHS and census under-one ratios: the census, Statistical Yearbook, MOH and DHS source values do not survive and were not re-entered (would require new transcription of published statistics).
- Table 5 exactly: 1,082 of the 13,174 transcribed certificates are missing (no Kimberley files for 1915 or 1920 survive), and the authors' race and age coding is unknown. The rebuild has 4,300 under-five deaths with known sex and race (black 2,325, coloured 1,197, white 778) against 4,968 published (3,137 / 934 / 897). More coloured and fewer white deaths than published, despite the missing files, means the classification differs, not only the coverage.

**Personal data.** The row-level cleaned file is `D:/Data/ReplicateMe/P24_MGF/repro_r/kimberley_clean.rds`. Outputs hold label counts and cell aggregates only.
