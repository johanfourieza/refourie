* P16_FvFC S5: Phillips-Perron test (fn 13, published p = 0.1485) on the published (digitised) and rebuilt core 1 Gini series.
clear all
set more off
log using pp_results.log, replace text
import delimited using pp_series.csv, clear
tsset t
foreach v in g_pub g_reb {
  di _n "==== `v' ===="
  pperron `v'
  forvalues L = 0/4 {
    qui pperron `v', lags(`L')
    di "`v' const lags(`L'): Z(t)=" %6.3f r(Zt) "  p=" %6.4f r(pval)
    qui pperron `v', lags(`L') trend
    di "`v' trend lags(`L'): Z(t)=" %6.3f r(Zt) "  p=" %6.4f r(pval)
    qui pperron `v', lags(`L') noconstant
    di "`v' nocons lags(`L'): Z(t)=" %6.3f r(Zt) "  p=" %6.4f r(pval)
    qui dfuller `v', lags(`L')
    di "`v' ADF const lags(`L'): Z(t)=" %6.3f r(Zt) "  p=" %6.4f r(p)
  }
}
* year-indexed (unequal spacing) is not a valid tsset for pperron with gaps; t index only.
log close
