# ReFourie: re-examining thirty of my own papers

*Johan Fourie, October 2026. Also at https://www.johanfourie.com/research/refourie.html*


Between 2010 and 2025 I published thirty empirical papers, most of them with coauthors. None came with a replication package. Economics now expects one: journals require code and data, and data editors check that they run. Most of my papers predate those rules. In October 2026 I asked a team of large language models to do for each paper what a diligent replicator would do: find the code and data that survive in my files, rerun them, rebuild the analysis independently, audit the code and the interpretation, and re-estimate the headline results with current methods. The question was simple: how many of my own papers could I re-estimate and, where possible, improve?

I had two further motives. The first was to see how useful language models have become for assessing past research, not as a writing aid but as tireless readers of old do-files, spreadsheets and archival transcriptions. The second was humility. Every one of these papers was coded and checked by people working without such help. Most of the errors this exercise found are the ordinary errors of careful people working by hand: a mis-coded occupation, two swapped columns, a spreadsheet function that silently returns zero. They are a reminder of how much of the empirical record of the pre-AI era rests on human attention alone, and how fallible that attention is.

> **Please read this first**
>
> - **Coauthors.** Most of these papers were written with coauthors, who often hold original data and code that I no longer have, or never had. Where files did not survive in my own folders, the models rebuilt the analysis from what did survive. A verdict of "not testable" or "weakened" may therefore reflect my missing files rather than the paper.
> - **Not corroborated.** I have not discussed these findings with my coauthors. They are the output of an automated audit, not agreed corrections.
> - **The machines can be wrong.** Two model families from different companies checked each other's work, and the points on which they disagree are reported as disputed. No human expert adjudicated the findings, and agreement between two models is not independent human validation.
> - **Responsibility.** I take full responsibility for every error exposed here. Coauthors and readers who see things differently are welcome to contact me.

## How the reanalysis was done

The rules were written down, reviewed and committed to a local version-controlled log before the results they govern were seen. The log records the order in which things were done; because it is local, it is evidence of sequence rather than a formal preregistration. Every later change to the rules is recorded, with a note on whether results had been seen. Each paper went through seven stages.

1. **Inventory and rights.** Every dataset was classified as open, restricted-licence (for example IPUMS census samples) or personal (for example genealogical records) before any model read it. Restricted and personal data were processed only locally and never shared with the second model.
2. **Freeze the claims.** Two independent extractions recorded every reported number in each paper, 11,005 in all, and identified the 102 headline claims on which the papers' conclusions rest. The list was frozen before any code ran.
3. **Run the original code.** Surviving Stata, R and Excel files were run as they were, with only file paths and software versions patched. Spreadsheets were recalculated formula by formula rather than read from cached values.
4. **Rebuild independently.** A separate agent rebuilt each analysis in R from the paper and the rawest available data, without seeing the original code. Its scripts were locked before any comparison. The rebuild is independent of the code, not of the results: the agent could read the published numbers, and for some papers only the authors' cleaned file survives.
5. **Compare.** Published numbers, original-code numbers and rebuilt numbers were compared pairwise against tolerances fixed in advance.
6. **Audit.** Claude and Codex audited the code and the interpretation separately. Every finding from either model was logged with its evidence and severity, and disagreements were kept rather than resolved by fiat.
7. **Reanalyse.** For each paper a method card set out one primary modern analysis, the admissible sensitivity checks, and the margins within which a result still counts as "the same interpretation" (by default, within 10% or 3 percentage points of the published value; for comparisons, a confidence interval that excludes zero). Codex reviewed each card twice before it was frozen; only then was the analysis run.

Each headline claim received one of five verdicts:

- **confirmed:** the claim holds within the margin under the primary modern analysis;
- **qualified:** the direction holds but the size or scope is different from what the paper states;
- **weakened:** the claim is no longer distinguishable from zero, or no longer supported at the stated strength;
- **overturned:** the evidence points the other way, or the stated claim is ruled out;
- **not testable:** the data needed to test the claim do not survive, or the claim cannot be identified from what does.

One methodological question remains disputed between the two models: whether a verdict reached on reconstructed records (when the original analysis file is lost) should count for the original claim. Claude kept such verdicts, labelled as conditional on the reconstruction; Codex would have reported them as extensions only. This affects two papers (the Cape capital market and the missing boys).

## What the machines did, and what it cost

The work took about 29 hours of elapsed time, from early on 11 October 2026 to mid-morning the next day. **Claude Opus 5.5** (Anthropic) acted as coordinator. It drafted the protocol, ran the first nine papers through subagents on my existing Claude subscription, wrote the instructions for every later agent, reconciled the audits and assembled the results. For the remaining 21 papers it dispatched independent agents through Anthropic's API: Opus 5.5 for the audits, method cards and modern reanalyses, and, in the last wave, the cheaper **Claude Sonnet 5.5** for the more routine stages of claim extraction, independent R rebuilds and card revisions. **OpenAI's Codex** (GPT-6 Astra, at high reasoning effort) was the independent second auditor. It audited the original code of every paper, reviewed every method card before it was frozen and checked every revision, in 85 separate reviews. My own role was to set the rules, answer questions and approve each wave before the next began.

In all, about 170 Claude sessions extracted 11,005 numbers from the papers, ran 126 original Stata and R scripts, wrote some 240 new R scripts (about 25,000 lines) and wrote audit reports totalling 129,000 words. The API agents alone took 3,449 turns and about 18 hours of computing time. The API bill came to **$268.79**: $197.26 for the second wave of seven papers, run entirely on Opus, and $71.45 for the final fourteen, where cheaper models and turn limits were used. One paper, on leader selection and education, cost $94.10 alone, because its agents worked through five million IPUMS census records. Everything else, including all of Codex's work and the coordination, ran on my existing Claude and ChatGPT subscriptions and is not costed. The per-paper figures below are API charges only. The 29 hours are elapsed time; because agents ran in parallel, computing time and elapsed time are different measures, and the time spent preparing the corpus beforehand is not counted.

## Results at a glance

Across the 102 headline claims: 52 confirmed, 17 qualified, 12 weakened, 5 overturned, 16 not testable

| Paper | Authors and journal | Headline claims | API cost |
|:--|:--|:--|--:|
| Inequality in the Cape Colony | Fourie 2025, South African Journal of Science | 2 confirmed, 1 qualified, 1 not testable | subscription |
| The Stellenbosch-Drakenstein tax censuses | Fourie, Green et al. 2024, South African Historical Journal | 3 confirmed, 2 weakened | $21.10 |
| The settlers' fortunes | Fourie & Garmon 2023, Economic History Review | 3 confirmed, 2 overturned | subscription |
| Leader selection and education | Maravall, Baten & Fourie 2023, Review of Development Economics | 1 confirmed, 2 weakened | $94.10 |
| Legacies of loss | Martins, Cilliers & Fourie 2023, Explorations in Economic History | 1 not testable | $2.06 |
| Settler heights 1865–1920 | Fourie, Inwood & Mariotti 2022, Economics and Human Biology | 1 qualified, 1 not testable | $19.71 |
| The missing boys | Marco-Gracia & Fourie 2022, Economic History of Developing Regions | 1 confirmed, 1 weakened | $3.49 |
| The 1918 influenza | de Kadt et al. 2021, South African Journal of Economics | 3 confirmed | $18.19 |
| Health inequality in the 1918 flu | Fourie & Jayes 2021, World Development | 1 qualified, 2 weakened | $7.10 |
| The Cape capital market, 1892–1902 | Maphosa, Ehlers, Fourie & Kerby 2021, Economic History of Developing Regions | 1 qualified, 2 not testable | $3.87 |
| Public sector growth, 1830–1910 | Gwaindepi & Fourie 2020, South African Journal of Economics | 1 confirmed, 1 overturned, 1 not testable | $4.69 |
| Slaves on the eastern frontier | Links, Fourie & Green 2020, Economic History of Developing Regions | 1 qualified, 1 weakened | $5.16 |
| Black disenfranchisement, 1887 | Nyika & Fourie 2020, Journal of Southern African Studies | 2 qualified, 1 not testable | $4.73 |
| Interracial marriages in Cape Town | Fourie & Inwood 2019, History of the Family | 3 confirmed, 2 weakened | subscription |
| The great divergence in South Africa | von Fintel & Fourie 2019, Journal of Comparative Economics | 4 confirmed, 2 qualified, 1 overturned | subscription |
| Occupational mobility during the industrial take-off | Cilliers & Fourie 2018, South African Journal of Economics | 3 confirmed, 1 weakened | subscription |
| Private credit at the Cape | Fourie & Swanepoel 2018, Journal of Southern African Studies | 1 confirmed, 2 not testable | $6.60 |
| Railways in the Cape Colony | Herranz-Loncan & Fourie 2018, European Review of Economic History | 1 qualified, 1 not testable | $5.87 |
| When SA markets joined the world | Boshoff & Fourie 2017, Journal for Studies in Economics and Econometrics | 1 confirmed, 2 qualified, 1 weakened | $6.50 |
| The South African Constabulary | Fourie, Grundlingh & Mariotti 2017, Journal of Imperial and Commonwealth History | 4 confirmed, 1 not testable | subscription |
| Numeracy at the Cape | Baten & Fourie 2015, Economic History Review | 3 confirmed | $15.71 |
| The missing people | Fourie & Green 2015, Journal of African History | 2 confirmed, 1 qualified, 1 not testable | subscription |
| The Quantitative Cape | Fourie 2014, South African Historical Journal | 2 confirmed, 1 qualified, 1 not testable | $2.34 |
| Huguenot wine-makers | Fourie & von Fintel 2014, Economic History Review | 2 confirmed, 1 qualified | subscription |
| Public finances under Company rule | Fourie, Jansen & Siebrits 2013, New Contree | 2 confirmed, 1 not testable | $13.12 |
| GDP in the Dutch Cape Colony | Fourie & van Zanden 2013, South African Journal of Economics | 4 confirmed | subscription |
| The remarkable wealth of the Cape | Fourie 2013, Economic History Review | 2 confirmed, 1 overturned | $7.44 |
| Income inequality at the Cape | Fourie & von Fintel 2011, Economic History of Developing Regions | 1 confirmed, 1 qualified, 1 not testable | $6.20 |
| The Cape trade route and business cycles | Boshoff & Fourie 2010, European Review of Economic History | 1 confirmed, 1 not testable | $5.39 |
| Inequality dynamics at the early Cape | Fourie & von Fintel 2010, Cliometrica | 3 confirmed, 1 qualified | $15.31 |

"Subscription" means the paper was handled within my existing Claude subscription, with no API charges.

## Paper by paper

### Inequality in the Cape Colony

*Fourie 2025, South African Journal of Science*

The script reproduces all six figures, but Figure 2 sums unpriced quantities, and the 'Khoe and settler combined' Ginis contain no settlers. Rebuilt with prices, the headline claims hold: settler Ginis stay above 0.6, and the 0.92 in the text is right, though the printed figure is not. The Khoe-settlement claim is partly untestable because two assets have one holder or none.

2 confirmed, 1 qualified, 1 not testable · API cost subscription · [Code and data](P29_INEQ25)

### The Stellenbosch-Drakenstein tax censuses

*Fourie, Green et al. 2024, South African Historical Journal*

The R script reproduces the figures, but read_excel guessed column types from the first rows and turned many livestock and wine counts into true/false. Corrected, the inequality claims hold: Ginis stay high and the wine Gini rises then falls. 'Stagnation or decline in most assets' does not hold, because horses, barley and wine rise.

3 confirmed, 2 weakened · API cost $21.10 · [Code and data](P30_STB24)

### The settlers' fortunes

*Fourie & Garmon 2023, Economic History Review*

The R code reproduces all eight headline numbers, but a prod() call silently sets the value of wheat to zero, and US grain is inflated 2.84× by a unit conversion. With both fixed, the Cape advantage over US farmers grows to an implausible 7.6×. That headline survives, flagged for its size. The claims that every Cape district was less unequal than Virginia, and that crops were more unequally held at the Cape, do not.

3 confirmed, 2 overturned · API cost subscription · [Code and data](P06_FGa)

### Leader selection and education

*Maravall, Baten & Fourie 2023, Review of Development Economics*

The Stata code reproduces Table 2 on 5 million IPUMS records. Leaders' birth regions were better educated, and that holds. The pre-independence interaction rests on Ghana, and the mission coefficient of 9.10 is a quasi-separation artefact (2.27 with Firth correction). The causal reading is not testable.

1 confirmed, 2 weakened · API cost $94.10 · [Code and data](P23_MBF)

### Legacies of loss

*Martins, Cilliers & Fourie 2023, Explorations in Economic History*

The linked claimant–genealogy dataset and all code were not recovered from my files, so no headline regression can be tested. Both auditors find the effect sizes misstated by two orders of magnitude if the shortfall is in pounds (−7.0% and −4.5% of lifespan per £10, not −0.07% and −0.04%). The shortfall tracks slave valuations closely, so its exogeneity is asserted rather than shown.

1 not testable · API cost $2.06 · [Code and data](P25_MCF)

### Settler heights 1865–1920

*Fourie, Inwood & Mariotti 2022, Economics and Human Biology*

Neither the final code nor the final analysis file survives; only a 2015 version for an earlier sample does. From the surviving data, the decline in mean height to the 1895–1904 cohort holds, but the weighted regression claims cannot be tested. Once force is controlled, the cohort recovery mostly disappears: within a war, cohort is confounded with age.

1 qualified, 1 not testable · API cost $19.71 · [Code and data](P09_FIM)

### The missing boys

*Marco-Gracia & Fourie 2022, Economic History of Developing Regions*

The census sex-ratio series reproduces from the authors' supplementary table, and the racial gap in under-five sex ratios stands. The Kimberley death-register evidence does not: on the recovered registers, black boys' excess deaths are not distinguishable from parity, and there is no black–white difference after 18 months. Death counts without populations at risk cannot show a preference for girls.

1 confirmed, 1 weakened · API cost $3.49 · [Code and data](P24_MGF)

### The 1918 influenza

*de Kadt et al. 2021, South African Journal of Economics*

The R pipeline reproduces Tables 1 and 3. After correcting some district assignments, all three headline associations hold: Black population share predicts mortality, conceptions fell sharply in October 1918, and higher mortality goes with lower later unemployment. The causal long-run reading is not identified by this design.

3 confirmed · API cost $18.19 · [Code and data](P05_DK)

### Health inequality in the 1918 flu

*Fourie & Jayes 2021, World Development*

No code survives, and four of the fifteen districts' transcriptions were not recovered from my files. On the eleven recovered districts every headline interaction keeps its sign, but with eleven clusters none survives small-cluster inference. The widening racial gap in doctor access is visible in the raw data, though smaller than printed, and the urban-reversal reading does not follow from the paper's own coefficients.

1 qualified, 2 weakened · API cost $7.10 · [Code and data](P12_FJ)

### The Cape capital market, 1892–1902

*Maphosa, Ehlers, Fourie & Kerby 2021, Economic History of Developing Regions*

Only the raw shareholder transcription survives. The direct fields reproduce: 15 African investors (0.22% of shareholders, not 0.1%) and mostly local shareholders. The middle-class headline is neither confirmed nor refuted, because shareholders without a recorded occupation hold half of all capital. Foreign capital is about 9% once a coding slip (East London as London) is fixed.

1 qualified, 2 not testable · API cost $3.87 · [Code and data](P22_MEFK)

### Public sector growth, 1830–1910

*Gwaindepi & Fourie 2020, South African Journal of Economics*

No calculation workbook survives. Railways took more than 70% of public works in every year from 1880, as the abstract says. The claim that public works and debt service exceeded 70% of spending from the 1870s fails in 21 of 40 years, even with every unknown item set at its maximum. The per-capita levels cannot be tested without the population and price series.

1 confirmed, 1 overturned, 1 not testable · API cost $4.69 · [Code and data](P19_GF)

### Slaves on the eastern frontier

*Links, Fourie & Green 2020, Economic History of Developing Regions*

No estimation code survives, but the rebuild on the authors' analysis file reproduces the three pooled complementarity estimates (0.84, 0.85, 0.90). The paper reports no inference: with household-clustered bootstraps few annual estimates exclude zero, and the slave–Khoe elasticity is negative in five later years. 'Complements throughout' is weakened; complementarity cannot carry the 'different tasks' reading.

1 qualified, 1 weakened · API cost $5.16 · [Code and data](P21_LFG)

### Black disenfranchisement, 1887

*Nyika & Fourie 2020, Journal of Southern African Studies*

The matching workbook was not recovered from my files, so only the published arithmetic can be audited. It sets a sixteen-division 1887 total against a fourteen-division 1886 total. On the same divisions the Black fall is 3,798 (not 2,825) and the white and coloured fall 10,189 (not 7,934). The paper's main point, that far fewer than 30,000 Black voters were struck off, holds.

2 qualified, 1 not testable · API cost $4.73 · [Code and data](P26_NF)

### Interracial marriages in Cape Town

*Fourie & Inwood 2019, History of the Family*

The headline coefficients reproduce on the 2018 data file. The surviving 2019 file adds six parishes that the script silently drops. Most of the decline in interracial marriage came before the 1949 Act, and that chronology is confirmed. The full-control Act and segregation coefficients lose significance once errors are clustered by parish and year.

3 confirmed, 2 weakened · API cost subscription · [Code and data](P10_FI)

### The great divergence in South Africa

*von Fintel & Fourie 2019, Journal of Comparative Economics*

Fully reproducible: the original code and an independent rebuild both match all 278 coefficients. The audit found the 1996 and 2011 night-lights columns swapped; re-extraction from the public satellite composites confirmed it. Population persistence and the unemployment results survive spatial inference. With corrected lights the homeland gap is half as large and narrowed after 1994, so the 'divergence since democracy' claim is overturned.

4 confirmed, 2 qualified, 1 overturned · API cost subscription · [Code and data](P28_VFF)

### Occupational mobility during the industrial take-off

*Cilliers & Fourie 2018, South African Journal of Economics*

The original Stata code reproduces every reachable headline exactly. The audit found that 'grazier' was coded unskilled, contradicting the authors' own HISCLASS file. That one choice drives the Altham result: with family-clustered inference the claimed rise in relative mobility after 1868 is not supported. The Gold-cohort, migrant and farmer-persistence results survive.

3 confirmed, 1 weakened · API cost subscription · [Code and data](P04_CF)

### Private credit at the Cape

*Fourie & Swanepoel 2018, Journal of Southern African Studies*

No code survives, but the Table 5 counts reproduce exactly, and land is the main stated purpose of borrowing on every variant. The 'Tobit' is OLS on borrowers only, and the stated exclusion of inheritance debts was not applied. The slave-ownership effect is robust in size (0.06–0.09) but its HC3 test is undefined, and the wealth result cannot be rebuilt.

1 confirmed, 2 not testable · API cost $6.60 · [Code and data](P13_FS)

### Railways in the Cape Colony

*Herranz-Loncan & Fourie 2018, European Review of Economic History*

The social-saving arithmetic reproduces from the paper's printed inputs, but no underlying data survive. Table 8 contradicts itself on productivity growth (2.94% against 2.21% a year), so the headline 22–25% contribution becomes a range of 20.5–28.9%. The railway's large contribution survives either way; its precise size does not.

1 qualified, 1 not testable · API cost $5.87 · [Code and data](P20_HLF)

### When SA markets joined the world

*Boshoff & Fourie 2017, Journal for Studies in Economics and Econometrics*

The trend correlations behind the 1872 integration story reproduce exactly from the surviving Excel workings, but once serial correlation is respected the post-1872 correlation of 0.86 is no longer distinguishable from zero at 1%. Kimberley wheat integration holds and is stronger; Kimberley maize and the long-run bounds tests do not.

1 confirmed, 2 qualified, 1 weakened · API cost $6.50 · [Code and data](P03_BoF17)

### The South African Constabulary

*Fourie, Grundlingh & Mariotti 2017, Journal of Imperial and Commonwealth History*

Table 3 reproduces cell for cell, but 43 t-statistics are printed with the wrong sign. Heights and the share of British-born recruits hold. The Afrikaans wage gap holds under the frozen wild-bootstrap test, but it depends on how surnames are classified and sits almost entirely in 1902 enlistments. The 'discrimination' reading is not identified.

4 confirmed, 1 not testable · API cost subscription · [Code and data](P08_SAC)

### Numeracy at the Cape

*Baten & Fourie 2015, Economic History Review*

The 2011 Stata pipeline reproduces the main numeracy table; code for the 2013 revision tables does not survive. With corrected origin coding and clustered inference, every headline gap holds: Europeans about 50 points more numerate than Cape-born slaves, imported slaves and the Khoesan lower. The Khoesan gap is the most fragile, because few court volumes contain Khoesan.

3 confirmed · API cost $15.71 · [Code and data](P01_BF)

### The missing people

*Fourie & Green 2015, Journal of African History*

Stata and Excel reproduce the tables almost exactly. The Khoesan counts are a mechanical imputation from one household's herd, with an undocumented Stellenbosch multiplier. When those assumptions are propagated, the productivity decline survives (−45%), the 1773 level depends on calibration, and the Theil claim cannot be tested: it mixes shares and levels, and the two auditors read it differently.

2 confirmed, 1 qualified, 1 not testable · API cost subscription · [Code and data](P07_FG)

### The Quantitative Cape

*Fourie 2014, South African Historical Journal*

A review article, so this is a source audit, not a reproduction. The released workbook reproduces the settler growth rate of 3.6%. Two other growth rates have a wrong base or a misattributed series, and the 24% slave share is cited for the wrong population and period. The comparative-welfare readings go further than the evidence: Cape GDP per capita exceeded Britain's in only 13 of 93 years.

2 confirmed, 1 qualified, 1 not testable · API cost $2.34 · [Code and data](P14_QC)

### Huguenot wine-makers

*Fourie & von Fintel 2014, Economic History Review*

No regression code survives, but a 2010 analysis file, rebuilt from its log, reproduces Tables 3–5 at every printed digit. The independent rebuild got smaller effects because the paper never states that regressions are weighted, nor how zero wine output is handled. On a scale-invariant outcome (Poisson) the wine-region advantage survives: +119% and +37%. The born-abroad result is qualified.

2 confirmed, 1 qualified · API cost subscription · [Code and data](P18_FvFS)

### Public finances under Company rule

*Fourie, Jansen & Siebrits 2013, New Contree*

The Stata do-file reproduces the pasted tax shares. The top decile's share rose from 47% to 64%, and the VOC ran deficits (40% of GDP in 1789); both are confirmed. The progressivity claim cannot be tested: the imputed taxes are levies proportional to output, so rising tax shares track rising output concentration.

2 confirmed, 1 not testable · API cost $13.12 · [Code and data](P11_FJS)

### GDP in the Dutch Cape Colony

*Fourie & van Zanden 2013, South African Journal of Economics*

The Excel national-accounts chain survives. It was recalculated cell by cell in R and reproduces 91 of 93 published years exactly. Rebuilt from the paper's description alone, levels come out about 1.2× higher, which shows how much of the method rests on unstated parameters, yet the century-long decline is the same −43%. Across 144 assumption scenarios every headline claim holds. The abstract's 'similar to Holland' does not.

4 confirmed · API cost subscription · [Code and data](P15_FvZ)

### The remarkable wealth of the Cape

*Fourie 2013, Economic History Review*

The Excel chain and the independent rebuild both reproduce the wealth levels exactly (759 rixdollars in the 1700s, 1,979 in the 1790s). The rise survives every check. The representativeness argument does not: inventories over-represent slave owners by 21 percentage points, and reweighting to the tax-roll population lowers wealth levels by about 20%.

2 confirmed, 1 overturned · API cost $7.44 · [Code and data](P27_RW)

### Income inequality at the Cape

*Fourie & von Fintel 2011, Economic History of Developing Regions*

The whole-population Ginis cannot be tested: the VOC wage microdata and the income files were not recovered from my files. Rebuilt from the tax rolls and the paper's own prices, farm-income inequality rose from 1700 to 1757 and wine was its leading source, both confirmed. The 1757 Gini comes out higher than printed (0.745 against 0.689), and the early rise to 1723 is not significant.

1 confirmed, 1 qualified, 1 not testable · API cost $6.20 · [Code and data](P17_FvFH)

### The Cape trade route and business cycles

*Boshoff & Fourie 2010, European Review of Economic History*

The analysis was interactive EViews, but the authors' filtered series survive in a spreadsheet, and on them the headline bounds F of 61.77 reproduces exactly. The test itself is the problem: on band-pass-filtered series it rejects independence for about half of all pairs of unrelated random walks, and the critical values used are those for four regressors. The headline is mechanically confirmed but close to uninformative; the Brunt-series results cannot be traced.

1 confirmed, 1 not testable · API cost $5.39 · [Code and data](P02_BoF10)

### Inequality dynamics at the early Cape

*Fourie & von Fintel 2010, Cliometrica*

No code survives, so the paper was rebuilt from the raw tax rolls. The Gini levels reproduce closely (0.53, 0.65, 0.63), and the later fall is confirmed. The early rise is significant only against one base year, because the published series drops zero-wealth households.

3 confirmed, 1 qualified · API cost $15.31 · [Code and data](P16_FvFC)

## Code and data

The [ReFourie repository](https://github.com/johanfourieza/refourie) contains, for each paper, the surviving original code, the independent R rebuild, the modern reanalysis, and the data where their licence allows it. Restricted-licence data (IPUMS census samples, for example) and personal or genealogical records are not included; the repository explains how to obtain them. The repository is a static archive of this exercise and will not be updated.
