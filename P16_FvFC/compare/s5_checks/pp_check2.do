* P16_FvFC S5: rebuilt series with only the 1663 point replaced by the published 0.501
clear all
log using pp_results2.log, replace text
import delimited using pp_series.csv, clear
tsset t
gen g_reb63 = g_reb
replace g_reb63 = g_pub if year == 1663
pperron g_reb63
log close
