# P15_FvZ S6: deviations from and implementation notes on the frozen method card

Card: `modern/method_card.md`, frozen at commit 404b4fb. No analysis outside the card was added. The items below are places where the card's cell definition could not be executed literally, or where it left an implementation detail open. Each states what was done and why.

**D1. C3 base column (deviation, forced).** The card defines the C3 base as `G = D − E`. In the workbook, `Agricultural production!G` equals `D − E` only from 1748 (rows 51–98). For 1701–1747 (rows 4–50) there is no wine-export series, so the workbook sets `G = 0.8·D`. C3 points `resteconomy!J` at column G in every row, which is the workbook's own domestic-consumption column. This is what S5 quantified. The alternative would be to apply the margin to D for 1701–47, which would leave C3 inactive in those years. That reading is not the text's rule ("city consumption"), so it was not used.

**D2. U3 cell set (card followed literally; noted).** The card limits U3 to "INCOMEVOCEMPLOYEES conversion cells using 9.61, including J44": H70:H95, J44 and J70:J95, 53 cells. The CPI cells `total economy!I71:I94` also divide by 9.61. Following the card's executable definition, they were **not** changed. The S5-5 quantification (1790: $1,011 → $924) included those CPI cells, so the U3 effect here differs from S5-5 and is not comparable with it.

**D3. U5 = P1 implementation (detail the card left open).** "Total population rescaled each year to the digitised Fig. 1 total" is implemented as follows:
- f_t = Fig1_t / X_t, where Fig1_t is the claims rows `F1_YYYY_total` interpolated linearly over 1701–1795 and X_t is the as-coded total (`Population!X`; `AC` in the copy).
- Every person-count input cell of the Population sheet in 1701–1795 is multiplied by f_t. These are the burgher, knecht and slave counts, Shell's slave totals, the typed VOC and dependant counts, and the typed Cape Town growth values. Share and year cells are left unchanged.
- So is the VOC-establishment link (`L`; `O` in the copy).
- Count cells that the workbook fills by interpolating their neighbours, `+(Ca+Cb)/2`, are rewritten as `+(Ca/fa+Cb/fb)/2*fr`. These occur in columns B–J, L, M and Q in the primary, and in the equivalent columns in the copy. Each year's value is then exactly f_t times the coded value.
- Every Population-sheet count, and the total, is then exactly f_t times the coded value. The check is max |X/Fig1 − 1| < 1e-9, which was asserted.
- All dependent formulas then follow the workbook's own chain, including wheat and meat consumption.
- Quantities that come from other sheets are not rescaled: sailors (`ships`) and VOC payroll employment and VOC slaves (`INCOMEVOCEMPLOYEES`, which enter `Population!AN`). As a result, the residual "rest" occupational share (`AR`) shifts slightly.

The Khoesan item is held as coded under P1, as the card requires.

**D4. U6 implementation.** The multiplier is applied to `resteconomy!D` (craftsmen + construction), written as `+m*(original)`. The column `resteconomy!U` (= D − craftsmen) inherits the change. It feeds only `total economy!AA:AB` (the investment ratio), which is not an estimand.

**D5. Two workbooks.** All estimands except the balanced series come from the primary workbook (`Van Duin en Ross.xlsx`). The balanced series (`total economy!Z`) exists only in `Copy of Van Duin en Ross.xlsx`. Every item is applied identically to both workbooks, and the Population cells are mapped to the copy's shifted layout (see `item_cells.csv`). In every scenario, the copy's GK-dollar series must match the primary's, with max abs diff < 1e-6, and this was asserted.

**D6. Comparators.** The comparators are the workbook's pasted 1701 values: Holland `total economy!V3` = 2,335.16 and Britain `total economy!Z3` = 1,616.25 (primary). They are listed in `output/comparators.csv`.

**D7. Trend growth.** Trend growth follows the S2 definition: 100·(e^b − 1), from OLS of the log of real GDP (`total economy!F`) and of the log of total population (`Population!X`) on year, 1701–1793.
