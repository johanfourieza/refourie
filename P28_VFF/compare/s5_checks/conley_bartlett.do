* P28_VFF S5: cross-check R Bartlett-kernel Conley SEs with the authors' bundled ols_spatial_HAC.ado (bartlett option)
* Run from P28_VFF/compare/s5_checks via PowerShell: StataMP-64.exe /e do conley_bartlett.do
version 15
do "`c(pwd)'/../../../tools/paths.do"  // A6: data root ($DATA)
global code "`c(pwd)'/../../original/Reversal of Fortunes"  // A6: code (.ado) stays in the project
global orig "$DATA/P28_VFF/original/Reversal of Fortunes"  // A6: data on D:
global scr "$DATA/P28_VFF/compare/_scratch_s5"  // A6: scratch on D:
cap mkdir "$scr"
cap log close
log using "$scr/conley_bartlett.log", text replace  // A6: was ../_scratch_s5/ (batch log stays here)
qui do "$code/ols_spatial_HAC.ado"
use "$orig/data.dta", clear
gen cons = 1
gen time = 1
tempname ph
postfile `ph' str12 model str12 var double(cutoff b se) using "$scr/conley_bartlett_stata.dta", replace
foreach cu in 100 1000 {
  foreach spec in "pop2011_3|l_pop2011 l_pop1911 p_home cons|l_pop1911" "pop2011_4|l_pop2011 l_pop1911 p_home tri rain_level cons|l_pop1911" ///
                  "u1996_3|l_u1996 l_pop1911 p_home cons|p_homeland" "u2011_4|l_u2011 l_pop1911 p_home tri rain_level cons|p_homeland" ///
                  "lights11_3|l_lights11 l_pop1911 p_home cons|p_homeland" "lights11_4|l_lights11 l_pop1911 p_home tri rain_level cons|p_homeland" ///
                  "settle_1b|l_pop1911 bl100 tri rain_level cons|bl100" {
    tokenize "`spec'", parse("|")
    qui ols_spatial_HAC `3' if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`cu') bartlett
    post `ph' ("`1'") ("`5'") (`cu') (_b[`5']) (_se[`5'])
  }
}
postclose `ph'
use "$scr/conley_bartlett_stata.dta", clear
list, clean noobs
export delimited using "$scr/conley_bartlett_stata.csv", replace
log close
