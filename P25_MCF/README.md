# Slaveholder compensation and health outcomes in the Cape Colony
Igor Martins, Jeanne Cilliers and Johan Fourie (2023), "Legacies of loss: the health outcomes of slaveholder compensation in the British Cape Colony", Explorations in Economic History.

## Folders
- `original/Slawerekords/`: `Slave Emancipation Dataset.xlsx` (Ekama, Fourie, Heese and Martin 2021).
- `repro_original/`: no original code survives; results_original.csv only.
- `repro_r/`: independent R rebuild of the compensation-shortfall checks.
- `modern/`: verdict file only (no code).

## Running
Run from the repository root. Scripts resolve data locations through `tools/paths.R` (R) or `tools/paths.do` (Stata) and find released files in this repository automatically.
`Rscript P25_MCF/repro_r/01_clean.R`, then `02_analysis.R`.

## Data not included
- The South African Families genealogies and the linked slaveholder-descendant file are personal data and are not read by released code.
