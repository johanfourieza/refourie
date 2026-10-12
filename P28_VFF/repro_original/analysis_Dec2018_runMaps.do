* ===== S2 ENVIRONMENT PREAMBLE (P28_VFF Run Maps) — replaces original line 1 (cd "C:\Users\dieter2\...") =====
version 15
sysdir set PLUS     "`c(pwd)'/ado/plus"
sysdir set PERSONAL "`c(pwd)'/ado/personal"
do "`c(pwd)'/../../tools/paths.do"  // A6: data root ($DATA)
global code "`c(pwd)'/../original/Reversal of Fortunes"  // A6: code (ols_spatial_HAC.ado) stays in the project
global orig "$DATA/P28_VFF/original/Reversal of Fortunes"  // A6: data live on D:
global out "$DATA/P28_VFF/repro_original/runMaps"  // A6: data outputs (.dta/.xls) go to D:
cap mkdir "$out"
* S2 ENV PATCH (maps run): shp2dta treats any dot in the path as an extension, so resolve $orig without ".."
local here `c(pwd)'
qui cd "$orig"
global orig "`c(pwd)'"
qui cd "`here'"
adopath ++ "$code"  // A6 (was $orig)
cap mkdir runMaps
cd runMaps
cap log close
log using runMaps_results.log, text replace
* ===== end preamble =====
* ORIGINAL LINE 1 (disabled): cd "C:\Users\dieter2\Dropbox (Personal)\Research\1. Ongoing\Reversal of Fortunes"
global data off
global regs off  // S2 maps-only run (original: off)
global maps on   // S2 maps-only run (original: on)
global conley off // S2 maps-only run (original: off)

	*Which overlap threshold for Walker (1922) map?
global settle bl100


	*Import program that reports Conley Standard errors
cap do "$code/ols_spatial_HAC.ado"  // S2 path patch (original: cap do ols_spatial_HAC.ado)
	*Moran statistics
cap program drop addmoran
program define addmoran
args esttitle
estimates store `esttitle'
cap drop res
predict res, res
moransi res, lat(y_cent) lon(x_cent) swm(pow 3) dist(.) dunit(km) approx detail replace  // S2 ENV PATCH: moransi 1.31 (2025) creates local-Moran variables and needs replace; 2018 versions did not
scalar moran_z = r(zI)
scalar moran_p = r(pI)
estimates restore `esttitle'
estadd scalar moran_z
estadd scalar moran_p
drop res
end

	*Program to store conley results in memory
cap program drop estspat
program define estspat
args name
estimates restore spatial
estimates store `name'
end

	* S2 OUTPUT CAPTURE (additive; changes no estimate): write every stored estimate to CSV
cap program drop dumpest
program define dumpest
args fname tag
qui estimates dir
local names `r(names)'
tempname ph
postfile `ph' str32 model str32 var double(b se N r2 df_r) str16 vce str32 tag using "$out/`fname'.dta", replace
foreach m of local names {
	qui estimates restore `m'
	tempname B V
	matrix `B' = e(b)
	matrix `V' = e(V)
	local vars : colnames `B'
	local k = colsof(`B')
	forvalues i = 1/`k' {
		local v : word `i' of `vars'
		post `ph' ("`m'") ("`v'") (`B'[1,`i']) (sqrt(`V'[`i',`i'])) (e(N)) (e(r2)) (e(df_r)) ("`e(vce)'") ("`tag'")
	}
}
postclose `ph'
preserve
qui use "$out/`fname'.dta", clear
qui export delimited using `fname'.csv, replace
restore
end



if "$data"=="on"{
shp2dta using "$orig/1911_ZAEast_SWA_LSO", database(1911_db) coordinates(1911_coord) genid(_ID2) replace gencen(cent)
use 1911_db, clear
keep ID x_cent y_cent
ren ID id
tempfile gps
save `gps', replace

import delimited "$orig/data.csv", clear  // S2 path patch
merge 1:1 id using `gps'

gen l_pop1911 = log(popdens1911)
*label var l_pop1911 "log(1911 Pop Dens (/sqkm))"
label var l_pop1911 "Pop1911"
gen l_pop1996 = log(p_96/area)
*label var l_pop1996 "log(1996 Pop Dens (/sqkm))"
label var l_pop1996 "Pop1996"
gen l_pop2011 = log(popdens2011)
*label var l_pop2011 "log(2011 Pop Dens (/sqkm))"
label var l_pop2011 "Pop2011"
gen l_u1996 = log(u_96)
*label var l_u1996 "log(1996 Broad Unempl Rate (%))"
label var l_u1996 "Un1996"

gen l_u2011 = log(urate)
*label var l_u2011 "log(2011 Broad Unempl Rate (%))"
label var l_u2011 "Un2011"
*label var tri "TRI"
label var tri "Rugged"
replace tri = tri/10000
gen l_tri = log(tri)

gen l_inmig_lifetime = log(mp_11) 
label var l_inmig_lifetime "log(lifetime provincial migration rate (%))"

gen l_inmig_muni11 = log(mim_11) 
*label var l_inmig_muni11 "log(decadal municipal inmigration rate (%))"
label var l_inmig_muni11 "InMig11"

gen l_outmig_muni11 = log(mom_11) 
*label var l_outmig_muni11 "log(decadal municipal outmigration rate (%))"
label var l_outmig_muni11 "OutMig11"

gen l_inmig_muni96 = log(im_96)
*label var l_inmig_muni96 "log(decadal municipal inmigration rate (%))"
label var l_inmig_muni96 "InMig96"

gen l_outmig_muni96 = log(om_96)
*label var l_outmig_muni96 "log(decadal municipal outmigration rate (%))"
label var l_outmig_muni96 "OutMig96"

	*Inverse hyperbolic sin transformation because of negative net migration rates
gen l_netmig_11 = ln(nm_11_raw+sqrt(nm_11_raw^2+1))
label var l_netmig_11 "NetMig11"

label var l_tri "log(TRI)"
egen shockbeg = rowmean(shock_190* shock_1910)
egen shockend = rowmean(shock_2*)
egen distmin = rowmin( dist_pot dist_maritz dist_pot_mar dist_pot_uys dist_retief dist_treg_clipped dist_vrb)
gen l_dist = log(distmin)
label var l_dist "log(Dist to settler route (km))"
gen l_inv_dist = -log(distmin)
label var l_inv_dist "log(1/Dist to settler route)"
gen l_csi = log(csi)
label var l_csi "log(Caloric Suitability)"
gen l_rain = log(rain)
label var l_rain "log(LR Rainfall (mm))"
gen l_lights11 = log(lig11)
*label var l_lights11 "log(2011 Night Lights)"
label var l_lights11 "Lights2011"
gen l_lights96 = log(lig96)
*label var l_lights96 "log(1996 Night Lights)"
label var l_lights96 "Lights96"
gen l_inc96 = log(i_96)
label var l_inc96 "log(1996 per capita income)"
gen l_inc11 = log(i_11)
label var l_inc96 "log(2011 per capita income)"
gen l_u11 = log(u_11)
*label var l_u11 "log(2011 Broad Unempl Rate (%))"
label var l_u11 "Un2011"


*label var tri "Terrain Ruggedness"
label var tri "Rugged"
*label var rain_level "LR Rainfall (mm)"
label var rain_level "Rain"
label var csi "Caloric Suitability"
label var p_home "Homeland"

gen bl100 = settled1830==0
replace bl100 = . if sample==0 


gen bl90 = settled1830<=0.1
replace bl90 = . if sample==0

gen bl80 = settled1830<=0.2
replace bl80 = . if sample==0

gen bl70 = settled1830<=0.3
replace bl70 = . if sample==0


gen bl60 = settled1830<=0.4
replace bl60 = . if sample==0

gen bl50 = settled1830<=0.5
replace bl50 = . if sample==0

label var $settle "Settle1830"

keep if sample==1
save data, replace
}

* S2 ENV PATCH: with $data off the original relies on data.dta already being in memory
* (interactive session after a $data run). Load the surviving analysis file explicitly.
if "$data"!="on" use "$orig/data.dta", clear

if "$regs"=="on"{
*Correlations
corr $settle l_pop1911 l_pop1996 l_pop2011 l_u1996 l_u2011 l_lights96  l_lights11 rain tri csi if sample==1
matrix correl = r(C)
estout matrix(correl, fmt(3)) using T1.tex, style(tex) replace 


*1838 population density
reg $settle tri rain if sample==1
*reg l_inv_dist /*csi*/ l_tri rain if sample==1
addmoran pop1838

*1911 popdens
*reg l_pop1911 l_inv_dist if sample==1
reg l_pop1911 $settle if sample==1
addmoran pop1911_1a
reg l_pop1911 $settle tri rain /*csi*/ if sample==1
addmoran pop1911_1b

reg l_pop1911 tri rain if sample==1
addmoran pop1911_2
*reg l_pop1911 /*csi*/ l_tri rain l_inv_dist if sample==1
reg l_pop1911 /*csi*/ tri rain $settle if sample==1
addmoran pop1911_3

*Homelands
*reg p_home l_inv_dist if sample==1
reg p_home $settle if sample==1
addmoran home_1
reg p_home /*l_inv_dist*/ l_pop1911  if sample==1
addmoran home_2
reg p_home /*l_inv_dist*/ l_pop1911  /*csi*/ tri rain if sample==1
addmoran home_3

*1996 and 2011 
foreach var in pop1996 u1996 inc96 lights96 pop2011 u2011 u11 inc11 lights11{
reg l_`var' l_inv_dist if sample==1
addmoran `var'_1
reg l_`var' /*l_inv_dist*/ l_pop1911 if sample==1
addmoran `var'_2
reg l_`var' /*l_inv_dist*/ l_pop1911 p_home if sample==1
addmoran `var'_3
reg l_`var' /*l_inv_dist*/ l_pop1911 p_home /*csi*/ tri rain if sample==1
addmoran `var'_4
}

foreach var in pop2011 u1996 lights96 inc96{
reg l_`var' /*l_inv_dist*/ l_pop1911 l_pop1996 p_home if sample==1
addmoran `var'_5

reg l_`var' /*l_inv_dist*/ l_pop1911 l_pop1996 p_home /*csi*/ tri rain if sample==1
addmoran `var'_6

reg l_`var' /*l_inv_dist*/ l_pop1911 l_pop1996 p_home l_inmig_muni96 l_outmig_muni96 /*csi*/ tri rain if sample==1
addmoran `var'_7
}

reg l_pop2011 /*l_inv_dist*/ l_pop1911 l_pop1996 p_home l_netmig_11 /*csi*/ tri rain if sample==1
addmoran pop2011_7

foreach var in u2011 lights11 inc11{
reg l_`var' /*l_inv_dist*/ l_pop1911 l_pop2011 p_home if sample==1
addmoran `var'_5


reg l_`var' /*l_inv_dist*/ l_pop1911 l_pop2011 p_home /*csi*/ tri rain if sample==1
addmoran `var'_6

reg l_`var' /*l_inv_dist*/ l_pop1911 l_pop2011 p_home l_netmig_11 /*csi*/ tri rain if sample==1
addmoran `var'_7
}

estout pop* using "$out/pop.xls", order($settle l_pop1911 p_homeland l_pop1996 l_inmig_m l_outmig_m /*csi*/ tri rain_level)  replace cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F moran_z moran_p, fmt(3 3 3 3 3) label("R-squared" "N" "F" "Moran Z" "Moran p-value")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estout u1996* inc96* lights96*  u2011* u11* inc11* lights11* using "$out/RoF.xls", order($settle l_pop1911 p_homeland l_pop1996 l_inmig_m l_outmig_m	 /*csi*/ tri rain_level)  replace cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F moran_z moran_p, fmt(3 3 3 3 3) label("R-squared" "N" "F" "Moran Z" "Moran p-value")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label


estout /*pop1838*/ pop1911_1a pop1911_1b	/*pop1911_3*/	home_3	pop1996_3	pop1996_4	pop2011_3 pop2011_4 pop2011_5 pop2011_6 pop2011_7 using "$out/T2.xls", order($settle l_pop1911 p_homeland l_pop1996 l_inmig_m l_outmig_m /*csi*/ tri rain_level)  replace cells(b(fmt(3) star)) stats(r2 N F moran_z moran_p, fmt(3 3 3 3 3) label("R-squared" "N" "F" "Moran Z" "Moran p-value")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label

estout /*pop1838*/ pop1911_1a pop1911_1b	/*pop1911_3*/	home_3	pop1996_3	pop1996_4	pop2011_3 pop2011_4 pop2011_5 pop2011_6 pop2011_7 using T2.tex, style(tex) order($settle l_pop1911 p_homeland l_pop1996 l_inmig_m l_outmig_m /*csi*/ tri rain_level)  replace cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F moran_z moran_p, fmt(3 3 3 3 3) label("R-squared" "N" "F" "Moran Z" "Moran p-value")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label

estout u1996_3	u1996_4	/*u1996_6	u1996_7*/ /*inc96_3	inc96_4*/ lights96_3	lights96_4 /*lights96_6 lights96_7*/ u2011_3	u2011_4 u2011_6	u2011_7 /*inc11_3	inc11_4*/ lights11_3	lights11_4 lights11_6 lights11_7 using "$out/T3.xls",  order(l_pop1911 p_homeland l_pop1996 l_pop2011  l_netmig_11 /*csi*/ tri rain_level)  replace cells(b(fmt(3) star)) stats(r2 N F moran_z moran_p, fmt(3 3 3 3 3) label("R-squared" "N" "F" "Moran Z" "Moran p-value")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label

estout u1996_3	u1996_4	/*u1996_6	u1996_7*/  /*inc96_3	inc96_4*/ lights96_3	lights96_4 /*lights96_6 lights96_7*/ u2011_3	u2011_4	u2011_6	u2011_7 /*inc11_3	inc11_4*/ lights11_3	lights11_4 lights11_6 lights11_7 using T3.tex, style(tex) order(l_pop1911 p_homeland l_pop1996 l_pop2011 l_netmig_11 /*csi*/ tri rain_level)  replace cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F moran_z moran_p, fmt(3 3 3 3 3) label("R-squared" "N" "F" "Moran Z" "Moran p-value")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
}

* S2 OUTPUT CAPTURE (additive; changes no estimate): Table 1 matrix and Table 2-3 estimates to CSV
if "$regs"=="on" {
	local rn : rownames correl
	local cn : colnames correl
	tempname pc
	postfile `pc' str32 row str32 col double r using "$out/T1_corr.dta", replace
	forvalues i = 1/`=rowsof(correl)' {
		forvalues j = 1/`=colsof(correl)' {
			local a : word `i' of `rn'
			local b : word `j' of `cn'
			post `pc' ("`a'") ("`b'") (correl[`i',`j'])
		}
	}
	postclose `pc'
	preserve
	qui use "$out/T1_corr.dta", clear
	qui export delimited using T1_corr.csv, replace
	restore
	dumpest regs_est ols_default
}

if "$maps"=="on"{
*Maps

shp2dta using "$orig/settlers_merged", database($out/routes_db) coordinates($out/routes_coords) genid(_ID) replace
shp2dta using "$orig/homeland_clipped", database($out/homeland_db) coordinates($out/homeland_coords) genid(_ID) replace
shp2dta using "$orig/Landact1913", database($out/landact_db) coordinates($out/landact_coords) genid(_ID) replace

shp2dta using "$orig/1911_ZAEast_SWA_LSO", database($out/1911_db) coordinates($out/1911_coord) genid(_ID2) replace gencen(cent)
use $out/1911_db, clear
ren ID id
keep id _ID2
merge 1:1 id using "$orig/data", nogen  // S2 path patch


graph drop _all
spmap bl70 using $out/1911_coord, id(_ID) legend(off)  ndfcolor(gs15) clmethod(quantile) clnumber(3) fcolor(Greys2) line(data($out/routes_coords) pattern(solid) color(gs10) size(medthin) legtitle("Settler Routes")) title("(a) 1830 Indigenous settlement", size(small)) subtitle("and European settler routes", size(vsmall)) name(settlers) note("Source: Walker (1922)", size(tiny))
spmap l_pop1911 using $out/1911_coord, id(_ID) ndfcolor(gs15) clmethod(custom) clbreaks(-2 -1 0 1 2 3 4 5 6 7 8) fcolor(Terrain) title("(b) log(1911 Population/square km)", size(small)) subtitle("and borders delineated by 1913 Land Act", size(vsmall)) name(pop1911) legstyle(2) legend(on position(4)) polygon(data($out/landact_coords) opattern(solid) ocolor(gs3)) note("Source: 1911 Census", size(tiny))
spmap l_pop2011 using $out/1911_coord, id(_ID) ndfcolor(gs15) clmethod(custom) clbreaks(-2 -1 0 1 2 3 4 5 6 7 8) fcolor(Terrain) title("(c) log(2011 Population/square km)", size(small)) subtitle("and apartheid homeland borders", size(vsmall)) name(pop2011) legstyle(2) legend(on position(4)) polygon(data($out/homeland_coords) opattern(solid) ocolor(gs3)) note("Source: 2011 Census", size(tiny))
graph combine settlers pop1911 pop2011, row(1) scheme(plottig) title("Settlement Persistence")
graph export pop.png, as(png) width(1600) height(1200) replace
graph export pop.eps, as(eps) replace


graph drop _all
spmap csi using $out/1911_coord, id(_ID) ndfcolor(gs15) clmethod(custom) clbreaks(0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1) fcolor(Greens2) title("(a) Caloric Suitability Index", size(small)) subtitle("and apartheid homeland borders", size(vsmall)) name(csi) legstyle(2) legend(on position(4)) polygon(data($out/homeland_coords) opattern(solid) ocolor(gs3)) note("Source: Galor & Özak (2016)", size(tiny)) 
spmap rain using $out/1911_coord, id(_ID) ndfcolor(gs15) clmethod(custom) clbreaks(200 300 400 500 600 700 800 900 1000) fcolor(Blues2) title("(b) Long-run average rainfall (mm)", size(small)) subtitle("and apartheid homeland borders", size(vsmall)) name(rain) legstyle(2) legend(on position(4)) polygon(data($out/homeland_coords) opattern(solid) ocolor(gs3)) note("Source: Willmott & Matsuura (2012)", size(tiny))
spmap tri using $out/1911_coord, id(_ID) legend(on position(4)) legstyle(2)  ndfcolor(gs15) clmethod(custom) clbreaks(0 10 20 30 40 50 60) fcolor(Greys2) polygon(data($out/homeland_coords) opattern(solid) ocolor(gs3)) title("(c) Terrain Ruggedness", size(small)) subtitle("and apartheid homeland borders", size(vsmall)) name(tri) note("Sources: Nunn & Puga (2012)", size(tiny))
graph combine csi rain tri, row(1) scheme(plottig) title("Geography")
graph export geo.png, as(png) width(1600) height(1200) replace
graph export geo.eps, as(eps) replace

graph drop _all
spmap l_lights11 using $out/1911_coord, id(_ID) ndfcolor(gs12) clmethod(custom) clbreaks(-3 -2 -1 0 1 2 3 4) fcolor(Heat) title("(b) log(2011 Night Lights Luminosity)", size(small)) subtitle("and apartheid homeland borders", size(vsmall)) name(lights) legstyle(2) legend(on position(4)) polygon(data($out/homeland_coords) opattern(solid) ocolor(gs15)) note("Source: National Oceanic and Atmospheric Administration", size(tiny)) 
spmap u_11 using $out/1911_coord, id(_ID) ndfcolor(gs15) clmethod(custom) clbreaks(0.30 0.40 0.50 0.60 0.70 0.80) fcolor(Heat) title("(a) 2011 Broad Unemployment Rate (%)", size(small)) subtitle("and apartheid homeland borders", size(vsmall)) name(unemp) legstyle(2) legend(on position(4)) polygon(data($out/homeland_coords) opattern(solid) ocolor(gs10)) note("Source: Census 2011", size(tiny))
spmap l_netmig_11 using $out/1911_coord, id(_ID) ndfcolor(gs15) clmethod(custom) clbreaks(-11 -9 -7 -5 -3 3 5 7 9 11 13) fcolor(Heat) title("(c) 2001-2011 Net number of migrants" , size(small)) subtitle("(inverse hyperbolic sine)" "and apartheid homeland borders", size(vsmall)) name(netmig) legstyle(2) legend(on position(4) size(tiny)) polygon(data($out/homeland_coords) opattern(solid) ocolor(gs10)) note("Source: Census 2011", size(tiny))

graph combine unemp lights netmig, row(1) scheme(sj) title("Modern Fortunes")
graph export fortune.png, as(png) width(1600) height(1200) replace
graph export fortune.eps, as(eps) replace


}

cap program drop conley
program define conley

args distcut

cap drop cons
cap drop time
gen cons = 1
gen time = 1

*T2
estimates clear
*1911 popdens
ols_spatial_HAC l_pop1911 $settle cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_pop.xls, mlabels(pop1911_1a) replace order($settle l_pop1911 p_homeland l_pop1996 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat pop1911_1a

ols_spatial_HAC l_pop1911 $settle tri rain cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_pop.xls, mlabels(pop1911_1b) append order($settle l_pop1911 p_homeland l_pop1996 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat pop1911_1b


*Homelands
ols_spatial_HAC p_home /*l_inv_dist*/ l_pop1911  /*csi*/ tri rain cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_pop.xls, mlabels(home_3) append order($settle l_pop1911 p_homeland l_pop1996 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat home_3



*1996 and 2011 
ols_spatial_HAC l_pop1996 /*l_inv_dist*/ l_pop1911 p_home cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_pop.xls, mlabels(pop1996_3) append order($settle l_pop1911 p_homeland l_pop1996 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat pop1996_3

ols_spatial_HAC l_pop1996 /*l_inv_dist*/ l_pop1911 p_home /*csi*/ tri rain cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_pop.xls, mlabels(pop1996_4) append order($settle l_pop1911 p_homeland l_pop1996 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat pop1996_4

ols_spatial_HAC l_pop2011 /*l_inv_dist*/ l_pop1911 p_home cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_pop.xls, mlabels(pop2011_3) append order($settle l_pop1911 p_homeland l_pop1996 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat pop2011_3

ols_spatial_HAC l_pop2011 /*l_inv_dist*/ l_pop1911 p_home /*csi*/ tri rain cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_pop.xls, mlabels(pop2011_4) append order($settle l_pop1911 p_homeland l_pop1996 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat pop2011_4

ols_spatial_HAC  l_pop2011 /*l_inv_dist*/ l_pop1911 l_pop1996 p_home cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_pop.xls, mlabels(pop2011_5) append order($settle l_pop1911 p_homeland l_pop1996 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat pop2011_5

ols_spatial_HAC  l_pop2011 /*l_inv_dist*/ l_pop1911 l_pop1996 p_home /*csi*/ tri rain cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_pop.xls, mlabels(pop2011_6) append order($settle l_pop1911 p_homeland l_pop1996 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat pop2011_6

estimates drop OLS spatial spatHAC

esttab * using conley`distcut'_pop.tex, replace style(tex) order($settle l_pop1911 p_homeland l_pop1996 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) label

dumpest conley`distcut'_pop conley`distcut'  // S2 output capture
estimates clear

	*T3
ols_spatial_HAC l_u1996 /*l_inv_dist*/ l_pop1911 p_home cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_welfare.xls, mlabels(u1996_3) replace order(l_pop1911 p_homeland l_pop2011 l_netmig_11  /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat u1996_3

ols_spatial_HAC l_u1996 /*l_inv_dist*/ l_pop1911 p_home /*csi*/ tri rain cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_welfare.xls, mlabels(u1996_4) append order(l_pop1911 p_homeland l_pop2011 l_netmig_11  /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat u1996_4

ols_spatial_HAC l_lights96 /*l_inv_dist*/ l_pop1911 p_home cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_welfare.xls, mlabels(lights96_3) append order(l_pop1911 p_homeland l_pop2011 l_netmig_11  /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat lights96_3

ols_spatial_HAC l_lights96 /*l_inv_dist*/ l_pop1911 p_home /*csi*/ tri rain cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_welfare.xls, mlabels(lights96_4) append order(l_pop1911 p_homeland l_pop2011 l_netmig_11  /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat lights96_4

*ols_spatial_HAC l_lights96 /*l_inv_dist*/ l_pop1911 l_pop1996 p_home /*csi*/ tri rain cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_welfare.xls, mlabels(lights96_6) append order($settle l_pop1911 p_homeland l_pop1996 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label


ols_spatial_HAC l_u2011 /*l_inv_dist*/ l_pop1911 p_home cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_welfare.xls, mlabels(u11_3) append order(l_pop1911 p_homeland l_pop2011 l_netmig_11 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat u11_3

ols_spatial_HAC l_u2011 /*l_inv_dist*/ l_pop1911 p_home /*csi*/ tri rain cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_welfare.xls, mlabels(u11_4) append order(l_pop1911 p_homeland l_pop2011 l_netmig_11 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat u11_4

ols_spatial_HAC l_u2011 /*l_inv_dist*/ l_pop1911 l_pop2011 p_home /*csi*/ tri rain cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_welfare.xls, mlabels(u11_6) append order(l_pop1911 p_homeland l_pop2011 l_netmig_11 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat u11_6

ols_spatial_HAC l_u2011 /*l_inv_dist*/ l_pop1911 l_pop2011 p_home /*csi*/ l_netmig_11 tri rain cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_welfare.xls, mlabels(u11_7) append order(l_pop1911 p_homeland l_pop2011 l_netmig_11 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat u11_7


ols_spatial_HAC l_lights11 /*l_inv_dist*/ l_pop1911 p_home cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_welfare.xls, mlabels(lights11_3) append order(l_pop1911 p_homeland l_pop2011 l_netmig_11 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat lights11_3

ols_spatial_HAC l_lights11 /*l_inv_dist*/ l_pop1911 p_home /*csi*/ tri rain cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_welfare.xls, mlabels(lights11_4) append order(l_pop1911 p_homeland l_pop2011 l_netmig_11 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat lights11_4

ols_spatial_HAC l_lights11 /*l_inv_dist*/ l_pop1911 l_pop2011 p_home /*csi*/ tri rain cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_welfare.xls, mlabels(lights11_6) append order(l_pop1911 p_homeland l_pop2011 l_netmig_11 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat lights11_6

ols_spatial_HAC l_lights11 /*l_inv_dist*/ l_pop1911 l_pop2011 p_home l_netmig_11  /*csi*/ tri rain cons if sample==1, lat(y_cent) lon(x_cent) timevar(time) panelvar(id) distcutoff(`distcut') display star
*estout spatial using conley`distcut'_welfare.xls, mlabels(lights11_7) append order(l_pop1911 p_homeland l_pop2011 l_netmig_11 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) legend label
estspat lights11_7

estimates drop OLS spatial spatHAC


esttab * using conley`distcut'_welfare.tex, replace style(tex) order(l_pop1911 p_homeland l_pop2011 l_netmig_11 /*csi*/ tri rain_level) cells(b(fmt(3) star) se(fmt(3) par)) stats(r2 N F, fmt(3 3 3) label("R-squared" "N" "F")) varlabels(cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) label
dumpest conley`distcut'_welfare conley`distcut'  // S2 output capture
end


if "$conley"=="on"{
foreach d in 20 50 100 200 300 500 1000{
conley `d'
}
}



cap log close  // S2
