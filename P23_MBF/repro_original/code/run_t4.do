* S2 PATCHED RUN FILE (environment only; see PATCHES.md). Lines 128-1226 of "1_spatial_analysis_test_all_MATRIX_200519_new (no ethnic regression).do"
* (line 1226 = "END (the rest is not presented in the paper)"). Lines 1-127 (variable generation, descriptives) are skipped:
* their input "ipumsi_africa_all_..._geo.dta" was re-saved in June 2022 without d_lead_eth, so the block cannot run; its saved
* output "1_ipumsi_africa_all_..._geo.dta" (27 Feb 2022, has all generated variables) is the entry point at line 130.
* Run in a work copy because the code overwrites its inputs.
version 16
clear all
set more off
local ado "./P23_MBF/repro_original/ado"
sysdir set PLUS "`ado'/plus"
sysdir set PERSONAL "`ado'/personal"
cd "./P23_MBF/repro_original/t4work"
set max_memory 32g
set matsize 11000
 
use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo.dta", clear


* Prepare dataset: 
*-----------------
* We drop the missing observations to create the W spatial analysis matrix. It doesn't allow missing observations. 
* Only gini has missing observations, which we drop later. 
drop if abcc==.
drop if yrschool==.
drop if cntry_name=="Cameroon"
bysort region cntry_name bdec: sum id_birth if gini==.

tab cntry_name [aweight=nc], sum(yrschool)
by bdec, sort: summarize abcc yrschool 
tab country bdec , summarize(abcc) 
bysort region: tab country bdec , summarize(gini) 

tab id_birth   /*there are left 3076 (id_birth*bdec) observations, we only have missing observations for gini (22 regions)*/

* Generate int_indep_birth: 
*--------------------------
generate d_1960s=0
replace d_1960s=1 if bdec==1960

generate d_1960_70s=0
replace d_1960_70s=1 if bdec==1960 | bdec==1970

generate int_indep_birth=d_1960s*d_birth_all

generate int_indep_birthea=d_1960_70s*d_birth_all /*for wa*/

bysort region cntry_name : tab int_indep_birth
bysort region cntry_name : tab int_indep_birthea

generate int_indep_ethnic=d_1960s*d_lead_eth
generate int_indep_ethnicea=d_1960_70s*d_lead_eth

bysort region cntry_name : tab int_indep_ethnic



* Before independence dummy
generate indep_bdec=0
replace indep_bdec=1 if bdec<1960
*replace indep_bdec=1 if bdec>=1960 & cntry_name=="Ghana"   /* 1957 is nearer to 1960 */
*replace indep_bdec=1 if bdec>=1960 & cntry_name=="Guinea"  /* 1958 is nearer to 1960 */
*replace indep_bdec=1 if bdec>=1960 & cntry_name=="Benin"   /* 1960 is  1960 */
*replace indep_bdec=1 if bdec>=1960 & cntry_name=="Mali"    /* 1960 is  1960 */
*replace indep_bdec=1 if bdec>=1960 & cntry_name=="Senegal" /* 1960 is  1960 */
*replace indep_bdec=1 if bdec>=1960 & cntry_name=="Sierra Leone" /* 1961 is  nearer to 1960 */
*replace indep_bdec=1 if bdec>=1960 & cntry_name=="Tanzania" /* 1961 is  nearer to 1960 */
*replace indep_bdec=1 if bdec>=1960 & cntry_name=="Uganda" /* 1962 is  nearer to 1960 */
*replace indep_bdec=1 if bdec>=1960 & cntry_name=="Kenya" /* 1963 is  nearer to 1960 */
*replace indep_bdec=1 if bdec>=1960 & cntry_name=="Zambia" /* 1964 is  nearer to 1960 */
*replace indep_bdec=1 if bdec>=1960 & cntry_name=="Malawi" /* 1966 is  nearer to 1960 */
generate int_birth_bef=indep_bdec*d_birth_all
generate int_ethnic_bef=indep_bdec*d_lead_eth


*By region and country: 
*---------------------
sort region
by region: tab cntry_name

*Verify that id_birth and bdec jointly identify the observations:
*---------------------------------------------------------------
assert id_birth!=.
assert bdec!=.
bysort id_birth bdec: assert _N==1

*Save dataset (before balancing):
*-------------------------------
save  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", replace


* Import largest tribe code (from murdock):
*-----------------------------------------
* I include this to also check for non spatial analysis but clustered by ethnic group. Results remain similar. 
use  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", clear
*drop _merge
merge m:1 id_birth using "id_birth_largest_tribe.dta"
drop if _merge==2
drop _merge

*Save dataset (before balancing):
*-------------------------------
save  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", replace


*=============================================== 
************************************************
*               All countries               *
************************************************
*=============================================== 


use  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", clear

tab country bdec , summarize(yrschool) 
tab country bdec , summarize(abcc) 
tab country bdec , summarize(gini) 

*Drop years when we miss one country:
*We could keep 1930, but the when balancing the sample would decrease significntly if we only maintain observations consistent throughout 4 bdec. This
*way it remains consistent with EA
drop if bdec==1920
drop if bdec==1930
drop if bdec==1970
drop if bdec==1980
tab country bdec , summarize(gini) 

egen wanted = total(inrange(bdec, 1940, 1960)), by(id_birth)
tab wanted
keep if wanted==3 /*keep regions with observations those 3 bdec*/
tab country bdec , summarize(yrschool) 
tab country bdec , summarize(abcc) 
tab country bdec , summarize(gini) 
xtset id_birth bdec
spbalance, balance /*strongly balanced*/
xtdes
save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec_balanced_all.dta", replace


* Calculating the matrix: 
***************************
use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec_balanced_all.dta", clear

keep if bdec==1940
keep cntry_name id_birth id_birth region yrschool
*I create an csv to import in qgis:
*export excel using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all.xls", replace
export delimited using "id_birth_sample_for_gis_all_all.csv", replace
save  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec_balanced_1940.dta", replace


*import the file in qgis, merge it with master and export it to stata folder as shp

*Create dta from shapefile:
clear  
spset, clear
spshape2dta "birth_region_sample_master_for_stata_1940_all.shp", replace   /*this is the shapefile created in qgis, it only includes the 1940 observations*/

use birth_region_sample_master_for_stata_1940_all.dta, clear
merge 1:m id_birth using "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec_balanced_all.dta", force
drop if _merge==2
keep _ID _CX _CY Shape_Leng Shape_Area id_birth region yrschool 

use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec_balanced_all.dta", clear


*Look at trasnlated data: 
use birth_region_sample_master_for_stata_1940_all.dta, clear
 describe
list in 1/5
spset id_birth, modify replace
save, replace



*************************
*************************
*  Regression framework *
************************* 
*************************





*===============================================================================
********************************************************************************
* table in excel and latex: 1_1930-1970_yrschool
********************************************************************************
*===============================================================================


capture noisily corrtex yrschool gini d_birth_all d_lead_eth  tse_r railway_density slave_density  d_mission count_tribe d_centraliz d_capital dist_cap   d_western


* Include for each birth decade (repeated cross sections).
*--------------------------------------------------------

* 			    Dependent variable: yrschool
*				============================

* 1930: Calculating the matrix: 
********************************
use  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", clear /* not balanced */
keep if bdec==1930
save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1930.dta", replace
keep cntry_name id_birth 
*I create an csv to import in qgis:
*export excel using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all.xls", replace
export delimited using "id_birth_sample_for_gis_all_1930.csv", replace
*import the file in qgis, join it with master and export it to stata folder as shp called: "birth_region_sample_master_for_stata_1930_all.shp"

*Create dta from shapefile:
clear  
spset, clear
spshape2dta "birth_region_sample_master_for_stata_1930_all.shp", replace   /*this is the shapefile created in qgis, it only includes the 1940 observations*/

use birth_region_sample_master_for_stata_1930_all.dta, clear
merge 1:m id_birth using "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1930.dta", force
drop if _merge==2
keep _ID _CX _CY Shape_Leng Shape_Area id_birth region

*Look at trasnlated data: 
use birth_region_sample_master_for_stata_1930_all.dta, clear
 describe
list in 1/5
spset id_birth, modify replace
save, replace

*  Regression *

use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1930.dta", clear
merge m:1 id_birth using birth_region_sample_master_for_stata_1930_all.dta, force
keep if _merge==3
drop _merge
spset
*Optionally, tell Sp to use the common ID variable
spset id_birth, modify replace
spmatrix create contiguity W , first replace /*normalize(spectral) is the default.  The matrix will be normalized so that its largest eigenvalue is 1.*/

// we deleted d_centraliz until we don't get a better variable

* (1)
spregress  yrschool   d_birth_all   i.cntry_code , gs2sls  errorlag(W) 
outreg2 using "1_yrschool_all.xls", replace  tex ///
drop( i.cntry_code) ///
sortvar(d_birth_all   d_lead_eth d_mission tse_r d_western  railway_density dist_cap d_capital d_centraliz count_tribe slave_density  suit_cerea    d_france) ///
addtext(Region FE, yes , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("yrschool" ) dec(2)  nocons



spregress  yrschool   d_birth_all  tse_r   railway_density slave_density  d_mission count_tribe  d_capital  dist_cap  d_western  i.cntry_code , gs2sls  errorlag(W) 
outreg2 using "1_yrschool_all.xls", append  tex ///
drop(tse_r   railway_density slave_density  d_mission count_tribe  d_capital  dist_cap  d_western  i.cntry_code) ///
sortvar(d_birth_all   d_lead_eth d_mission tse_r d_western  railway_density dist_cap d_capital d_centraliz count_tribe slave_density  suit_cerea    d_france) ///
addtext(Region FE, yes , Controls, 8) addstat(Pseudo R2, e(r2_p))  ctitle("yrschool" ) dec(2)  nocons


* 1940: Calculating the matrix: 
********************************
use  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", clear /* not balanced */
keep if bdec==1940
save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1940.dta", replace
keep cntry_name id_birth 
*I create an csv to import in qgis:
*export excel using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all.xls", replace
export delimited using "id_birth_sample_for_gis_all_1940.csv", replace
*import the file in qgis, join it with master and export it to stata folder as shp called: "birth_region_sample_master_for_stata_1930_all.shp"

*Create dta from shapefile:
clear  
spset, clear
spshape2dta "birth_region_sample_master_for_stata_1940_unbalanced.shp", replace   /*this is the shapefile created in qgis, it only includes the 1940 observations*/

use birth_region_sample_master_for_stata_1940_unbalanced.dta, clear
merge 1:m id_birth using "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1940.dta", force
drop if _merge==2
keep _ID _CX _CY Shape_Leng Shape_Area id_birth region

*Look at trasnlated data: 
use birth_region_sample_master_for_stata_1940_unbalanced.dta, clear
 describe
list in 1/5
spset id_birth, modify replace
save, replace

*  Regression *

use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1940.dta", clear
merge m:1 id_birth using birth_region_sample_master_for_stata_1940_unbalanced.dta, force
keep if _merge==3
drop _merge
spset
*Optionally, tell Sp to use the common ID variable
spset id_birth, modify replace
spmatrix create contiguity W , first replace /*normalize(spectral) is the default.  The matrix will be normalized so that its largest eigenvalue is 1.*/

* 			    Dependent variable: yrschool
*				============================

* (1)
spregress  yrschool   d_birth_all  i.cntry_code, gs2sls  errorlag(W) 
outreg2 using "1_yrschool_all.xls", append  tex ///
drop( i.cntry_code) ///
addtext(Region FE, yes , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("yrschool" ) dec(2)  nocons

*(2)
spregress  yrschool   d_birth_all   tse_r   railway_density slave_density  d_mission count_tribe  d_capital  dist_cap  d_western  i.cntry_code, gs2sls  errorlag(W) 
outreg2 using "1_yrschool_all.xls", append  tex ///
drop(tse_r railway_density slave_density  d_mission count_tribe d_capital dist_cap  d_western  i.cntry_code) ///
addtext(Region FE, yes , Controls, 8) addstat(Pseudo R2, e(r2_p))  ctitle("yrschool" ) dec(2)  nocons

********************************************************************************



* 1950: Calculating the matrix: 
********************************
use  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", clear /* not balanced */
keep if bdec==1950
save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1950.dta", replace
keep cntry_name id_birth 
*I create an csv to import in qgis:
*export excel using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all.xls", replace
export delimited using "id_birth_sample_for_gis_all_1950.csv", replace
*import the file in qgis, join it with master and export it to stata folder as shp called: "birth_region_sample_master_for_stata_1930_all.shp"

*Create dta from shapefile:
clear  
spset, clear
spshape2dta "birth_region_sample_master_for_stata_1950.shp", replace   /*this is the shapefile created in qgis, it only includes the 1940 observations*/

use birth_region_sample_master_for_stata_1950.dta, clear
merge 1:m id_birth using "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1950.dta", force
drop if _merge==2
keep _ID _CX _CY Shape_Leng Shape_Area id_birth region

*Look at trasnlated data: 
use birth_region_sample_master_for_stata_1950.dta, clear
 describe
list in 1/5
spset id_birth, modify replace
save, replace

*  Regression *

use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1950.dta", clear
merge m:1 id_birth using birth_region_sample_master_for_stata_1950.dta, force
keep if _merge==3
drop _merge
spset
*Optionally, tell Sp to use the common ID variable
spset id_birth, modify replace
spmatrix create contiguity W , first replace /*normalize(spectral) is the default.  The matrix will be normalized so that its largest eigenvalue is 1.*/

* 			    Dependent variable: yrschool
*				============================

* (1)
spregress  yrschool  d_birth_all i.cntry_code, gs2sls  errorlag(W) 
outreg2 using "1_yrschool_all.xls", append  tex ///
drop(i.cntry_code) ///
addtext(Region FE, yes , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("yrschool" ) dec(2)  nocons

*(2)
spregress  yrschool   d_birth_all  tse_r railway_density slave_density  d_mission count_tribe d_capital dist_cap d_western  i.cntry_code, gs2sls  errorlag(W) 
outreg2 using "1_yrschool_all.xls", append  tex ///
drop(tse_r railway_density slave_density  d_mission count_tribe d_capital dist_cap d_western  i.cntry_code) ///
addtext(Region FE, yes, Controls, 8) addstat(Pseudo R2, e(r2_p))  ctitle("yrschool" ) dec(2)  nocons


* 1960: Calculating the matrix: 
********************************
use  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", clear /* not balanced */
keep if bdec==1960
save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1960.dta", replace
keep cntry_name id_birth 
*I create an csv to import in qgis:
*export excel using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all.xls", replace
export delimited using "id_birth_sample_for_gis_all_1960.csv", replace
*import the file in qgis, join it with master and export it to stata folder as shp called: "birth_region_sample_master_for_stata_1930_all.shp"

*Create dta from shapefile:
clear  
spset, clear
spshape2dta "birth_region_sample_master_for_stata_1960.shp", replace   /*this is the shapefile created in qgis, it only includes the 1940 observations*/

use birth_region_sample_master_for_stata_1960.dta, clear
merge 1:m id_birth using "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1960.dta", force
drop if _merge==2
keep _ID _CX _CY Shape_Leng Shape_Area id_birth region

*Look at trasnlated data: 
use birth_region_sample_master_for_stata_1960.dta, clear
 describe
list in 1/5
spset id_birth, modify replace
save, replace

*  Regression *

use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1960.dta", clear
merge m:1 id_birth using birth_region_sample_master_for_stata_1960.dta, force
keep if _merge==3
drop _merge
spset
*Optionally, tell Sp to use the common ID variable
spcompress, force
spset id_birth, modify replace
spmatrix create contiguity W , first replace /*normalize(spectral) is the default.  The matrix will be normalized so that its largest eigenvalue is 1.*/

* 			    Dependent variable: yrschool
*				============================

* (1)

spregress  yrschool   d_birth_all  i.cntry_code, gs2sls  errorlag(W) 
outreg2 using "1_yrschool_all.xls", append  tex ///
drop( i.cntry_code) ///
addtext(Region FE, yes , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("yrschool" ) dec(2)  nocons

* (2)
spregress  yrschool   d_birth_all  tse_r railway_density slave_density  d_mission count_tribe  d_capital dist_cap d_western   i.cntry_code, gs2sls  errorlag(W) 
outreg2 using "1_yrschool_all.xls", append  tex ///
drop(tse_r railway_density slave_density  d_mission count_tribe  d_capital dist_cap d_western  i.cntry_code) ///
addtext(Region FE, yes , Controls, 8) addstat(Pseudo R2, e(r2_p))  ctitle("yrschool" ) dec(2)  nocons



* 1970: Calculating the matrix: 
********************************
use  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", clear /* not balanced */
keep if bdec==1970
save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1970.dta", replace
keep cntry_name id_birth 
*I create an csv to import in qgis:
*export excel using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all.xls", replace
export delimited using "id_birth_sample_for_gis_all_1970.csv", replace
*import the file in qgis, join it with master and export it to stata folder as shp called: "birth_region_sample_master_for_stata_1930_all.shp"

*Create dta from shapefile:
clear  
spset, clear
spshape2dta "birth_region_sample_master_for_stata_1970.shp", replace   /*this is the shapefile created in qgis, it only includes the 1940 observations*/

use birth_region_sample_master_for_stata_1970.dta, clear
merge 1:m id_birth using "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1970.dta", force
drop if _merge==2
keep _ID _CX _CY Shape_Leng Shape_Area id_birth region

*Look at trasnlated data: 
use birth_region_sample_master_for_stata_1970.dta, clear
 describe
list in 1/5
spset id_birth, modify replace
save, replace

*  Regression *

use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1970.dta", clear
merge m:1 id_birth using birth_region_sample_master_for_stata_1970.dta, force
keep if _merge==3
drop _merge
spset
*Optionally, tell Sp to use the common ID variable
spset id_birth, modify replace
spmatrix create contiguity W , first replace /*normalize(spectral) is the default.  The matrix will be normalized so that its largest eigenvalue is 1.*/

* 			    Dependent variable: yrschool
*				============================

* (1)
spregress  yrschool   d_birth_all  i.cntry_code , gs2sls  errorlag(W) 
outreg2 using "1_yrschool_all.xls", append  tex ///
drop( i.cntry_code) ///
addtext(Region FE, yes , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("yrschool" ) dec(2)  nocons

* (2)
spregress  yrschool   d_birth_all  tse_r railway_density slave_density  d_mission count_tribe d_capital dist_cap  d_western  i.cntry_code, gs2sls  errorlag(W) 
outreg2 using "1_yrschool_all.xls", append  tex ///
drop( tse_r railway_density slave_density  d_mission count_tribe d_capital dist_cap  d_western i.cntry_code) ///
addtext(Region FE, yes , Controls, 8) addstat(Pseudo R2, e(r2_p))  ctitle("yrschool" ) dec(2)  nocons








*===============================================================================
********************************************************************************
* table in excel and latex: tab_1_1930-1970_abcc
********************************************************************************
*===============================================================================



* 			    Dependent variable: abcc
*				========================

* 1930: Calculating the matrix: 
********************************
use  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", clear /* not balanced */
keep if bdec==1930
save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1930.dta", replace
keep cntry_name id_birth 
*I create an csv to import in qgis:
*export excel using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all.xls", replace
export delimited using "id_birth_sample_for_gis_all_1930.csv", replace
*import the file in qgis, join it with master and export it to stata folder as shp called: "birth_region_sample_master_for_stata_1930_all.shp"

*Create dta from shapefile:
clear  
spset, clear
spshape2dta "birth_region_sample_master_for_stata_1930_all.shp", replace   /*this is the shapefile created in qgis, it only includes the 1940 observations*/

use birth_region_sample_master_for_stata_1930_all.dta, clear
merge 1:m id_birth using "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1930.dta", force
drop if _merge==2
keep _ID _CX _CY Shape_Leng Shape_Area id_birth region

*Look at trasnlated data: 
use birth_region_sample_master_for_stata_1930_all.dta, clear
 describe
list in 1/5
spset id_birth, modify replace
save, replace

*  Regression *

use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1930.dta", clear
merge m:1 id_birth using birth_region_sample_master_for_stata_1930_all.dta, force
keep if _merge==3
drop _merge
spset
*Optionally, tell Sp to use the common ID variable
spset id_birth, modify replace
spmatrix create contiguity W , first replace /*normalize(spectral) is the default.  The matrix will be normalized so that its largest eigenvalue is 1.*/



* (1)

spregress  abcc    d_birth_all i.cntry_code , gs2sls force  errorlag(W) 
outreg2 using "1_abcc_all.xls", replace  tex ///
drop(i.cntry_code ) ///
sortvar(d_birth_all   d_lead_eth int_indep_birth   int_indep_ethnic tse_r d_western  railway_density dist_cap d_capital d_centraliz count_tribe slave_density  suit_cerea    d_france) ///
addtext(Country FE, no , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("abcc_1930" ) dec(2)  nocons

* (2)
spregress  abcc   d_birth_all  tse_r railway_density slave_density d_mission count_tribe d_centraliz d_capital dist_cap  d_western i.cntry_code, gs2sls force  errorlag(W) 
outreg2 using "1_abcc_all.xls", append tex ///
drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code tse_r railway_density slave_density d_mission count_tribe d_centraliz d_capital dist_cap  d_western ) ///
sortvar(d_birth_all   d_lead_eth int_indep_birth   int_indep_ethnic tse_r d_western  railway_density dist_cap d_capital d_centraliz count_tribe slave_density  suit_cerea    d_france) ///
addtext(Country FE, yes, Controls, 8) addstat(Pseudo R2, e(r2_p))  ctitle("abcc_1930" ) dec(2)  nocons


* 1940: Calculating the matrix: 
********************************
use  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", clear /* not balanced */
keep if bdec==1940
save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1940.dta", replace
keep cntry_name id_birth 
*I create an csv to import in qgis:
*export excel using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all.xls", replace
export delimited using "id_birth_sample_for_gis_all_1940.csv", replace
*import the file in qgis, join it with master and export it to stata folder as shp called: "birth_region_sample_master_for_stata_1930_all.shp"

*Create dta from shapefile:
clear  
spset, clear
spshape2dta "birth_region_sample_master_for_stata_1940_unbalanced.shp", replace   /*this is the shapefile created in qgis, it only includes the 1940 observations*/

use birth_region_sample_master_for_stata_1940_unbalanced.dta, clear
merge 1:m id_birth using "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1940.dta", force
drop if _merge==2
keep _ID _CX _CY Shape_Leng Shape_Area id_birth region

*Look at trasnlated data: 
use birth_region_sample_master_for_stata_1940_unbalanced.dta, clear
 describe
list in 1/5
spset id_birth, modify replace
save, replace

*  Regression *

use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1940.dta", clear
merge m:1 id_birth using birth_region_sample_master_for_stata_1940_unbalanced.dta, force
keep if _merge==3
drop _merge
spset
*Optionally, tell Sp to use the common ID variable
spset id_birth, modify replace
spmatrix create contiguity W , first replace /*normalize(spectral) is the default.  The matrix will be normalized so that its largest eigenvalue is 1.*/

* 			    Dependent variable: abcc
*				========================

* (1)

spregress  abcc   d_birth_all   i.cntry_code , gs2sls  force errorlag(W) 
outreg2 using "1_abcc_all.xls", append  tex ///
drop(i.cntry_code) ///
addtext(Country FE, yes  , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("abcc_1940" ) dec(2)  nocons

* (2)
spregress  abcc   d_birth_all  tse_r railway_density slave_density  d_mission count_tribe d_centraliz d_capital dist_cap  d_western  i.cntry_code , gs2sls  force errorlag(W) 
outreg2 using "1_abcc_all.xls", append  tex ///
drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code tse_r railway_density slave_density  d_mission count_tribe d_centraliz d_capital dist_cap  d_western  ) ///
addtext(Country FE, yes , Controls, 8) addstat(Pseudo R2, e(r2_p))  ctitle("abcc_1940" ) dec(2)  nocons

********************************************************************************



* 1950: Calculating the matrix: 
********************************
use  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", clear /* not balanced */
keep if bdec==1950
save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1950.dta", replace
keep cntry_name id_birth 
*I create an csv to import in qgis:
*export excel using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all.xls", replace
export delimited using "id_birth_sample_for_gis_all_1950.csv", replace
*import the file in qgis, join it with master and export it to stata folder as shp called: "birth_region_sample_master_for_stata_1930_all.shp"

*Create dta from shapefile:
clear  
spset, clear
spshape2dta "birth_region_sample_master_for_stata_1950.shp", replace   /*this is the shapefile created in qgis, it only includes the 1940 observations*/

use birth_region_sample_master_for_stata_1950.dta, clear
merge 1:m id_birth using "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1950.dta", force
drop if _merge==2
keep _ID _CX _CY Shape_Leng Shape_Area id_birth region

*Look at trasnlated data: 
use birth_region_sample_master_for_stata_1950.dta, clear
 describe
list in 1/5
spset id_birth, modify replace
save, replace

*  Regression *

use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1950.dta", clear
merge m:1 id_birth using birth_region_sample_master_for_stata_1950.dta, force
keep if _merge==3
drop _merge
spset
*Optionally, tell Sp to use the common ID variable
spset id_birth, modify replace
spmatrix create contiguity W , first replace /*normalize(spectral) is the default.  The matrix will be normalized so that its largest eigenvalue is 1.*/

* 			    Dependent variable: abcc
*				=========================

* (1)
spregress  abcc   d_birth_all i.cntry_code , gs2sls force errorlag(W) 
outreg2 using "1_abcc_all.xls", append  tex ///
drop(i.cntry_code) ///
addtext(Country FE, yes , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("abcc_1950" ) dec(2)  nocons

* (2)
spregress  abcc   d_birth_all  tse_r railway_density slave_density d_mission count_tribe  d_capital  dist_cap  d_western i.cntry_code, gs2sls force errorlag(W) 
outreg2 using "1_abcc_all.xls", append  tex ///
drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code tse_r railway_density slave_density d_mission count_tribe  d_capital  dist_cap  d_western) ///
addtext(Country FE, yes  , Controls, 8) addstat(Pseudo R2, e(r2_p))  ctitle("abcc_1950" ) dec(2)  nocons



* 1960: Calculating the matrix: 
********************************
use  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", clear /* not balanced */
keep if bdec==1960
save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1960.dta", replace
keep cntry_name id_birth 
*I create an csv to import in qgis:
*export excel using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all.xls", replace
export delimited using "id_birth_sample_for_gis_all_1960.csv", replace
*import the file in qgis, join it with master and export it to stata folder as shp called: "birth_region_sample_master_for_stata_1930_all.shp"

*Create dta from shapefile:
clear  
spset, clear
spshape2dta "birth_region_sample_master_for_stata_1960.shp", replace   /*this is the shapefile created in qgis, it only includes the 1940 observations*/

use birth_region_sample_master_for_stata_1960.dta, clear
merge 1:m id_birth using "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1960.dta", force
drop if _merge==2
keep _ID _CX _CY Shape_Leng Shape_Area id_birth region

*Look at trasnlated data: 
use birth_region_sample_master_for_stata_1960.dta, clear
 describe
list in 1/5
spset id_birth, modify replace
save, replace

*  Regression *

use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1960.dta", clear
merge m:1 id_birth using birth_region_sample_master_for_stata_1960.dta, force
keep if _merge==3
drop _merge
spset
spcompress, force
*Optionally, tell Sp to use the common ID variable
spset id_birth, modify replace
spmatrix create contiguity W , first replace /*normalize(spectral) is the default.  The matrix will be normalized so that its largest eigenvalue is 1.*/

* 			    Dependent variable: abcc
*				============================

* (1)
spregress  abcc   d_birth_all i.cntry_code, gs2sls force errorlag(W) 
outreg2 using "1_abcc_all.xls", append  tex ///
drop(i.cntry_code) ///
addtext(Country FE, yes , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("abcc_1960" ) dec(2)  nocons

* (2)
spregress  abcc   d_birth_all  tse_r railway_density slave_density  d_mission count_tribe  d_capital dist_cap   d_western i.cntry_code, gs2sls force errorlag(W) 
outreg2 using "1_abcc_all.xls", append  tex ///
drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code tse_r railway_density slave_density  d_mission count_tribe  d_capital dist_cap   d_western) ///
addtext(Country FE, yes  , Controls, 8) addstat(Pseudo R2, e(r2_p))  ctitle("abcc_1960" ) dec(2)  nocons


* 1970: Calculating the matrix: 
********************************
use  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", clear /* not balanced */
keep if bdec==1970
save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1970.dta", replace
keep cntry_name id_birth 
*I create an csv to import in qgis:
*export excel using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all.xls", replace
export delimited using "id_birth_sample_for_gis_all_1970.csv", replace
*import the file in qgis, join it with master and export it to stata folder as shp called: "birth_region_sample_master_for_stata_1930_all.shp"

*Create dta from shapefile:
clear  
spset, clear
spshape2dta "birth_region_sample_master_for_stata_1970.shp", replace   /*this is the shapefile created in qgis, it only includes the 1940 observations*/

use birth_region_sample_master_for_stata_1970.dta, clear
merge 1:m id_birth using "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1970.dta", force
drop if _merge==2
keep _ID _CX _CY Shape_Leng Shape_Area id_birth region

*Look at trasnlated data: 
use birth_region_sample_master_for_stata_1970.dta, clear
 describe
list in 1/5
spset id_birth, modify replace
save, replace

*  Regression *

use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1970.dta", clear
merge m:1 id_birth using birth_region_sample_master_for_stata_1970.dta, force
keep if _merge==3
drop _merge
spset
*Optionally, tell Sp to use the common ID variable
spset id_birth, modify replace
spmatrix create contiguity W , first replace /*normalize(spectral) is the default.  The matrix will be normalized so that its largest eigenvalue is 1.*/

* 			    Dependent variable: abcc
*				============================

* (1)

spregress  abcc   d_birth_all   i.cntry_code, gs2sls force errorlag(W) 
outreg2 using "1_abcc_all.xls", append  tex ///
drop(i.cntry_code) ///
addtext(Country FE, yes , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("abcc_1970" ) dec(2)  nocons

* (2)
spregress  abcc   d_birth_all  tse_r railway_density slave_density  d_mission count_tribe  d_capital  dist_cap  d_western i.cntry_code, gs2sls force errorlag(W) 
outreg2 using "1_abcc_all.xls", append  tex ///
drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code tse_r railway_density slave_density  d_mission count_tribe d_capital  dist_cap  d_western) ///
addtext(Country FE, yes, Controls, 8) addstat(Pseudo R2, e(r2_p))  ctitle("abcc_1970" ) dec(2)  nocons









*===============================================================================
********************************************************************************
* table in excel and latex: tab_1_1930-1970_gini
********************************************************************************
*===============================================================================

********************************************************************************

* 				  Dependent variable: gini
*				==========================


* 1930: Calculating the matrix: 
********************************

use  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", clear /* not balanced */
bysort bdec: sum id_birth if gini==.  /*22 regions missing*/
drop if gini==.
keep if bdec==1930
save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1930.dta", replace
keep cntry_name id_birth 
*I create an csv to import in qgis:
*export excel using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all.xls", replace
export delimited using "id_birth_sample_for_gis_all_1930.csv", replace
*import the file in qgis, join it with master and export it to stata folder as shp called: "birth_region_sample_master_for_stata_1930_all.shp"

*Create dta from shapefile:
clear  
spset, clear
spshape2dta "birth_region_sample_master_for_stata_1930_all.shp", replace   /*this is the shapefile created in qgis, it only includes the 1940 observations*/

use birth_region_sample_master_for_stata_1930_all.dta, clear
merge 1:m id_birth using "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1930.dta", force
drop if _merge==1
keep _ID _CX _CY Shape_Leng Shape_Area id_birth region

*Look at trasnlated data: 
use birth_region_sample_master_for_stata_1930_all.dta, clear
 describe
list in 1/5
spset id_birth, modify replace
save, replace

*  Regression *

use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1930.dta", clear
merge m:1 id_birth using birth_region_sample_master_for_stata_1930_all.dta, force
keep if _merge==3
drop _merge
spset
spcompress, force /* drop missing observations in gini */
*Optionally, tell Sp to use the common ID variable
spset id_birth, modify replace
spmatrix create contiguity W , first replace /*normalize(spectral) is the default.  The matrix will be normalized so that its largest eigenvalue is 1.*/


* (1)

spregress  gini  d_birth_all  i.cntry_code, gs2sls force errorlag(W) 
outreg2 using "1_gini_all.xls", replace  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all   d_lead_eth int_indep_birth   int_indep_ethnic tse_r d_western  railway_density dist_cap d_capital d_centraliz count_tribe slave_density  suit_cerea    d_france) ///
addtext(Region FE, yes , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("gini_1930" ) dec(2)  nocons

* (2)

spregress  gini   d_birth_all  tse_r railway_density slave_density  d_mission count_tribe  d_capital dist_cap   d_western i.cntry_code, gs2sls force errorlag(W) 
outreg2 using "1_gini_all.xls", append  tex ///
drop(tse_r railway_density slave_density  d_mission count_tribe d_centraliz d_capital dist_cap   d_western i.cntry_code) ///
sortvar(d_birth_all   d_lead_eth int_indep_birth   int_indep_ethnic tse_r d_western  railway_density dist_cap d_capital  count_tribe slave_density  suit_cerea    d_france) ///
addtext(Region FE, yes , Controls, 8) addstat(Pseudo R2, e(r2_p))  ctitle("gini_1930" ) dec(2)  nocons



* 1940: Calculating the matrix: 
********************************
use  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", clear /* not balanced */
bysort bdec: sum id_birth if gini==.  /*22 regions missing*/
drop if gini==.
keep if bdec==1940
save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1940.dta", replace
keep cntry_name id_birth 
*I create an csv to import in qgis:
*export excel using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all.xls", replace
export delimited using "id_birth_sample_for_gis_all_1940.csv", replace
*import the file in qgis, join it with master and export it to stata folder as shp called: "birth_region_sample_master_for_stata_1930_all.shp"

*Create dta from shapefile:
clear  
spset, clear
spshape2dta "birth_region_sample_master_for_stata_1940_unbalanced.shp", replace   /*this is the shapefile created in qgis, it only includes the 1940 observations*/

use birth_region_sample_master_for_stata_1940_unbalanced.dta, clear
merge 1:m id_birth using "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1940.dta", force
drop if _merge==2
keep _ID _CX _CY Shape_Leng Shape_Area id_birth region

*Look at trasnlated data: 
use birth_region_sample_master_for_stata_1940_unbalanced.dta, clear
 describe
list in 1/5
spset id_birth, modify replace
save, replace

*  Regression *

use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1940.dta", clear
merge m:1 id_birth using birth_region_sample_master_for_stata_1940_unbalanced.dta, force
keep if _merge==3
drop _merge
spcompress, force  /*22 fewer regions */
spset

*Optionally, tell Sp to use the common ID variable
spset id_birth, modify replace
spmatrix create contiguity W , first replace /*normalize(spectral) is the default.  The matrix will be normalized so that its largest eigenvalue is 1.*/

* 			    Dependent variable: gini
*				========================

* (1)
	spregress  gini   d_birth_all  i.cntry_code , gs2sls force errorlag(W) 
	outreg2 using "1_gini_all.xls", append  tex ///
	drop( i.cntry_code) ///
	addtext(Region FE, yes , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("gini_1940" ) dec(2)  nocons

* (2)
	spregress  gini   d_birth_all  tse_r railway_density slave_density  d_mission count_tribe d_centraliz d_capital dist_cap   d_western i.cntry_code, gs2sls force errorlag(W) 
	outreg2 using "1_gini_all.xls", append  tex ///
	drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code tse_r railway_density slave_density  d_mission count_tribe d_centraliz d_capital dist_cap   d_western) ///
	addtext(Region FE, yes , Controls, 8) addstat(Pseudo R2, e(r2_p))  ctitle("gini_1940" ) dec(2)  nocons


	********************************************************************************



	* 1950: Calculating the matrix: 
	********************************
	use  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", clear /* not balanced */
	drop if gini==.
	keep if bdec==1950
	save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1950.dta", replace
	keep cntry_name id_birth 
	*I create an csv to import in qgis:
	*export excel using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all.xls", replace
	export delimited using "id_birth_sample_for_gis_all_1950.csv", replace
	*import the file in qgis, join it with master and export it to stata folder as shp called: "birth_region_sample_master_for_stata_1930_all.shp"

	*Create dta from shapefile:
	clear  
	spset, clear
	spshape2dta "birth_region_sample_master_for_stata_1950.shp", replace   /*this is the shapefile created in qgis, it only includes the 1940 observations*/

	use birth_region_sample_master_for_stata_1950.dta, clear
	merge 1:m id_birth using "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1950.dta", force
	drop if _merge==2
	keep _ID _CX _CY Shape_Leng Shape_Area id_birth region

	*Look at trasnlated data: 
	use birth_region_sample_master_for_stata_1950.dta, clear
	 describe
	list in 1/5
	spset id_birth, modify replace
	save, replace

	*  Regression *

	use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1950.dta", clear
	merge m:1 id_birth using birth_region_sample_master_for_stata_1950.dta, force
	keep if _merge==3
	drop _merge
	spcompress, force
	spset
	*Optionally, tell Sp to use the common ID variable
	spset id_birth, modify replace
	spmatrix create contiguity W , first replace /*normalize(spectral) is the default.  The matrix will be normalized so that its largest eigenvalue is 1.*/

	* 			    Dependent variable: gini
	*				=========================

	* (1)

	spregress  gini   d_birth_all  i.cntry_code, gs2sls force errorlag(W) 
	outreg2 using "1_gini_all.xls", append  tex ///
	drop( i.cntry_code) ///
	addtext(Region FE, yes , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("gini_1950" ) dec(2)  nocons

	* (2)


	spregress  gini   d_birth_all  tse_r railway_density slave_density  d_mission count_tribe  d_capital dist_cap   d_western i.cntry_code, gs2sls force errorlag(W) 
	outreg2 using "1_gini_all.xls", append  tex ///
	drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code  tse_r railway_density slave_density  d_mission count_tribe  d_capital dist_cap   d_western) ///
	addtext(Region FE, yes , Controls, 8) addstat(Pseudo R2, e(r2_p))  ctitle("gini_1950" ) dec(2)  nocons



	* 1960: Calculating the matrix: 
	********************************
	use  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", clear /* not balanced */
	drop if gini==.
	keep if bdec==1960
	save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1960.dta", replace
	keep cntry_name id_birth 
	*I create an csv to import in qgis:
	*export excel using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all.xls", replace
	export delimited using "id_birth_sample_for_gis_all_1960.csv", replace
	*import the file in qgis, join it with master and export it to stata folder as shp called: "birth_region_sample_master_for_stata_1930_all.shp"

	*Create dta from shapefile:
	clear  
	spset, clear
	spshape2dta "birth_region_sample_master_for_stata_1960.shp", replace   /*this is the shapefile created in qgis, it only includes the 1940 observations*/

	use birth_region_sample_master_for_stata_1960.dta, clear
	merge 1:m id_birth using "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1960.dta", force
	drop if _merge==2
	keep _ID _CX _CY Shape_Leng Shape_Area id_birth region

	*Look at trasnlated data: 
	use birth_region_sample_master_for_stata_1960.dta, clear
	 describe
	list in 1/5
	spset id_birth, modify replace
	save, replace

	*  Regression *

	use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1960.dta", clear
	merge m:1 id_birth using birth_region_sample_master_for_stata_1960.dta, force
	keep if _merge==3
	drop _merge
	spcompress, force
	spset
	*Optionally, tell Sp to use the common ID variable
	spset id_birth, modify replace
	spmatrix create contiguity W , first replace /*normalize(spectral) is the default.  The matrix will be normalized so that its largest eigenvalue is 1.*/

	* 			    Dependent variable: gini
	*				============================

	* (1)

	spregress  gini   d_birth_all i.cntry_code, gs2sls force errorlag(W) 
	outreg2 using "1_gini_all.xls", append  tex ///
	drop(i.cntry_code) ///
	addtext(Region FE, yes , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("gini_1960" ) dec(2)  nocons

	* (2)

	spregress  gini   d_birth_all  tse_r railway_density slave_density d_mission count_tribe d_capital  dist_cap  d_western i.cntry_code, gs2sls force errorlag(W) 
	outreg2 using "1_gini_all.xls", append  tex ///
	drop( i.cntry_code   tse_r railway_density slave_density d_mission count_tribe  d_capital  dist_cap  d_western) ///
	addtext(Region FE, yes , Controls, 8) addstat(Pseudo R2, e(r2_p))  ctitle("gini_1960" ) dec(2)  nocons



	* 1970: Calculating the matrix: 
	********************************

	use  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", clear /* not balanced */
	drop if gini==.
	keep if bdec==1970
	save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1970.dta", replace
	keep cntry_name id_birth 
	*I create an csv to import in qgis:
	*export excel using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all.xls", replace
	export delimited using "id_birth_sample_for_gis_all_1970.csv", replace
	*import the file in qgis, join it with master and export it to stata folder as shp called: "birth_region_sample_master_for_stata_1930_all.shp"

	*Create dta from shapefile:
	clear  
	spset, clear
	spshape2dta "birth_region_sample_master_for_stata_1970.shp", replace   /*this is the shapefile created in qgis, it only includes the 1940 observations*/

	use birth_region_sample_master_for_stata_1970.dta, clear
	merge 1:m id_birth using "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1970.dta", force
	drop if _merge==2
	keep _ID _CX _CY Shape_Leng Shape_Area id_birth region

	*Look at trasnlated data: 
	use birth_region_sample_master_for_stata_1970.dta, clear
	 describe
	list in 1/5
	spset id_birth, modify replace
	save, replace

	*  Regression *

	use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_1970.dta", clear
	merge m:1 id_birth using birth_region_sample_master_for_stata_1970.dta, force
	keep if _merge==3
	drop _merge
	spcompress, force
	spset
	*Optionally, tell Sp to use the common ID variable
	spset id_birth, modify replace
	spmatrix create contiguity W , first replace /*normalize(spectral) is the default.  The matrix will be normalized so that its largest eigenvalue is 1.*/

	* 			    Dependent variable: gini
	*				============================

	* (1)

	spregress gini   d_birth_all  i.cntry_code , gs2sls force  errorlag(W) 
	outreg2 using "1_gini_all.xls", append  tex ///
	drop( i.cntry_code) ///
	addtext(Region FE, yes, Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("gini_1970" ) dec(2)  nocons

	* (2)

	spregress gini   d_birth_all  tse_r railway_density slave_density  d_mission count_tribe d_centraliz d_capital dist_cap   d_western i.cntry_code, gs2sls force  errorlag(W) 
	outreg2 using "1_gini_all.xls", append  tex ///
	drop(tse_r railway_density slave_density  d_mission count_tribe d_centraliz d_capital dist_cap   d_western i.cntry_code) ///
	addtext(Region FE, yes , Controls, 8) addstat(Pseudo R2, e(r2_p))  ctitle("gini_1970" ) dec(2)  nocons
	
	
	

