# ReFourie

Code and data for an AI-assisted re-examination of thirty papers by Johan Fourie and coauthors (2010 to 2025). For each paper, language-model agents reran the surviving original code, rebuilt the analysis independently in R, and re-estimated the headline results with current methods. The process, the caveats and the findings are described at **[johanfourie.com/research/refourie](https://www.johanfourie.com/research/refourie.html)**; `REFOURIE.md` holds the same text.

This repository is a static archive. It will not be updated.

## Layout

Each paper has its own folder, `P##_<code>/`, with a README:

- `original/`: the released original data files, at the paths the scripts expect;
- `repro_original/`: the surviving original code (Stata, R or Excel recalculation), with path patches only (`PATCHES.md`);
- `repro_r/`: the independent R rebuild (`decisions.md` records its choices);
- `modern/`: the modern reanalysis, pre-specified in `method_card.md` (deviations in `DEVIATIONS.md`);
- `claims/claims.csv`: every number reported in the paper, as extracted before any code was run;
- `compare/`: comparison tables of published, original-code and rebuilt numbers.

`tools/` holds the path helpers and the comparison engine (`Rscript tools/run_compare.R P18_FvFS`). `env/` lists the R packages and Stata version used.

## Running

Run every script from the repository root, for example `Rscript P30_STB24/repro_r/01_clean.R`, in the numbered order given in each paper's README. R 4.5 with the tidyverse, fixest, modelsummary and the packages in `env/R_packages.csv`; Stata 19 for the do-files. Intermediate files are written to `_scratch/` folders.

## Data

Only data created by Johan Fourie, by LEAP (the Laboratory for the Economics of Africa's Past, Stellenbosch University) or jointly by a paper's authors are included, and only where no licence or privacy rule prevents it. Not included: third-party datasets and published series (each paper's README says where to obtain them), restricted-licence data such as IPUMS and Statistics South Africa census microdata, and personal records such as twentieth-century registers and genealogies. For many papers the scripts therefore cannot run from this repository alone.

| Folder | Paper | Authors and journal | Data files released | Original code runs | R rebuild runs | Modern runs |
|:--|:--|:--|--:|:--|:--|:--|
| [P01_BF](P01_BF/) | Numeracy at the Cape | Baten & Fourie 2015, Economic History Review | 0 | no | no | no |
| [P02_BoF10](P02_BoF10/) | The Cape trade route and business cycles | Boshoff & Fourie 2010, European Review of Economic History | 2 | no | no | no |
| [P03_BoF17](P03_BoF17/) | When SA markets joined the world | Boshoff & Fourie 2017, Journal for Studies in Economics and Econometrics | 1 | no | partial | partial |
| [P04_CF](P04_CF/) | Occupational mobility during the industrial take-off | Cilliers & Fourie 2018, South African Journal of Economics | 2 | partial | no | no |
| [P05_DK](P05_DK/) | The 1918 influenza | de Kadt et al. 2021, South African Journal of Economics | 5 | no | no | partial |
| [P06_FGa](P06_FGa/) | The settlers' fortunes | Fourie & Garmon 2023, Economic History Review | 1 | no | no | no |
| [P07_FG](P07_FG/) | The missing people | Fourie & Green 2015, Journal of African History | 3 | partial | yes | partial |
| [P08_SAC](P08_SAC/) | The South African Constabulary | Fourie, Grundlingh & Mariotti 2017, Journal of Imperial and Commonwealth History | 1 | no | no | no |
| [P09_FIM](P09_FIM/) | Settler heights 1865–1920 | Fourie, Inwood & Mariotti 2022, Economics and Human Biology | 1 | no | no | no |
| [P10_FI](P10_FI/) | Interracial marriages in Cape Town | Fourie & Inwood 2019, History of the Family | 3 | no | no | no |
| [P11_FJS](P11_FJS/) | Public finances under Company rule | Fourie, Jansen & Siebrits 2013, New Contree | 2 | partial | yes | partial |
| [P12_FJ](P12_FJ/) | Health inequality in the 1918 flu | Fourie & Jayes 2021, World Development | 0 | no | no | no |
| [P13_FS](P13_FS/) | Private credit at the Cape | Fourie & Swanepoel 2018, Journal of Southern African Studies | 0 | no | no | no |
| [P14_QC](P14_QC/) | The Quantitative Cape | Fourie 2014, South African Historical Journal | 0 | no | no | no |
| [P15_FvZ](P15_FvZ/) | GDP in the Dutch Cape Colony | Fourie & van Zanden 2013, South African Journal of Economics | 0 | no | no | no |
| [P16_FvFC](P16_FvFC/) | Inequality dynamics at the early Cape | Fourie & von Fintel 2010, Cliometrica | 1 | no | yes | yes |
| [P17_FvFH](P17_FvFH/) | Income inequality at the Cape | Fourie & von Fintel 2011, Economic History of Developing Regions | 3 | no | no | partial |
| [P18_FvFS](P18_FvFS/) | Huguenot wine-makers | Fourie & von Fintel 2014, Economic History Review | 4 | yes | partial | yes |
| [P19_GF](P19_GF/) | Public sector growth, 1830–1910 | Gwaindepi & Fourie 2020, South African Journal of Economics | 0 | no | no | no |
| [P20_HLF](P20_HLF/) | Railways in the Cape Colony | Herranz-Loncan & Fourie 2018, European Review of Economic History | 1 | no | yes | yes |
| [P21_LFG](P21_LFG/) | Slaves on the eastern frontier | Links, Fourie & Green 2020, Economic History of Developing Regions | 1 | no | yes | yes |
| [P22_MEFK](P22_MEFK/) | The Cape capital market, 1892–1902 | Maphosa, Ehlers, Fourie & Kerby 2021, Economic History of Developing Regions | 0 | no | no | no |
| [P23_MBF](P23_MBF/) | Leader selection and education | Maravall, Baten & Fourie 2023, Review of Development Economics | 0 | no | no | no |
| [P24_MGF](P24_MGF/) | The missing boys | Marco-Gracia & Fourie 2022, Economic History of Developing Regions | 0 | no | no | partial |
| [P25_MCF](P25_MCF/) | Legacies of loss | Martins, Cilliers & Fourie 2023, Explorations in Economic History | 1 | no | no | no |
| [P26_NF](P26_NF/) | Black disenfranchisement, 1887 | Nyika & Fourie 2020, Journal of Southern African Studies | 2 | no | yes | no |
| [P27_RW](P27_RW/) | The remarkable wealth of the Cape | Fourie 2013, Economic History Review | 7 | partial | no | no |
| [P28_VFF](P28_VFF/) | The great divergence in South Africa | von Fintel & Fourie 2019, Journal of Comparative Economics | 1 | no | no | no |
| [P29_INEQ25](P29_INEQ25/) | Inequality in the Cape Colony | Fourie 2025, South African Journal of Science | 8 | partial | no | no |
| [P30_STB24](P30_STB24/) | The Stellenbosch-Drakenstein tax censuses | Fourie, Green et al. 2024, South African Historical Journal | 2 | yes | yes | yes |

"Runs" means runs with the material in this repository; "partial" means some scripts do.

## Licence

Code: MIT (see `LICENSE`). Released data: CC BY 4.0. Please cite as in `CITATION.cff`.
