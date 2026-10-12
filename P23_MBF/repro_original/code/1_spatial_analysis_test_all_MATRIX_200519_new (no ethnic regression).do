		
*----------------------------------------------------------------------------------------------------------------------------------------------
*----------------------------------------------------------------------------------------------------------------------------------------------

                                                                * SPATIAL ANALYSIS*

*----------------------------------------------------------------------------------------------------------------------------------------------
*----------------------------------------------------------------------------------------------------------------------------------------------

*  I.   Spatial regressions for the whole dataset using sp commands

*  II.  Spatial regressions by region (using spatwmat and spatreg commands)

* Main file used: use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo.dta", clear

*----------------------------------------------------------------------------------------------------------------------------------------------
*----------------------------------------------------------------------------------------------------------------------------------------------



*===================================================================================================================================================
 *--------------------------------------------------------------------*
 *--------------------------------------------------------------------*
 * We generate variables for regression: 
 *--------------------------------------------------------------------*
 *--------------------------------------------------------------------*
*===================================================================================================================================================

use "ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo.dta", clear

* Interactions
generate int_birtplaceafter=d_independence* d_birth_all
generate int_ethnicafter=d_independence* d_lead_eth
generate int_d_franceafter=d_independence* d_france

*generate int_birtplaceafter_all=d_independence* d_birth_all_bef  /*Includes all leaders born before independence*/



* Dummy equal to 1 if birth decade after 1950s
generate d_bdec1950=0
replace d_bdec1950=1 if bdec>=1950


* Generate ratio years of schooling and abcc
sum abcc
sum yrschool
generate abcc_div100=abcc/100
generate abcc_to_yrs =abcc_div100/yrschool
sum abcc_to_yrs
codebook abcc_to_yrs, d
histogram abcc_to_yrs
graph box abcc_to_yrs, over(bdec) mark(1, mlab(id_birth))  /*Big outlier in Mali, id_birth=46650*/
graph box abcc_to_yrs if id_birth!=46650, over(bdec)


/*dummy equal to 1 if you belong to the birth cohort that matches with the decade when the leader was in office. 
*So that the early birth cohorts (like 1910, 1920, 1930, 1940, 1950) in a given geolev2 have a zero value because none of the leaders ruled during that period. */
*generate d_bdecoffice=0
*replace d_bdecoffice=1 if bdec==bdecoffice

*Interaction ethnicity and rural
*generate int_ethnicrural=d_ethnic*d_rural
*Interaction ethnicity & rural & independence
*generate int_indethnicrural=d_ethnic*d_rural*d_independence

*Interaction ethnicity & france & independence
*generate int_indethnicfrance=d_ethnic*d_france*d_independence

*Interaction ethnicity and rural
*generate int_ethnicfrance=d_ethnic*d_france

*Interaction ethnicity & d_railway & independence
*generate int_indethnicrw=d_ethnic*d_railway*d_independence

*This saved file contains no-within leader variation. It only shows if a geolev2 was a birthplace or belonged to a leader´s ethnic group. 
*save "ipumsi_africa_all_181115_abcc&yrschool_collapsed_final_20190509.dta", replace

save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo.dta", replace

* Region dummy	

use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo.dta", clear
generate d_western=0
replace d_western=1 if region=="Western Africa" 
save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo.dta", replace	


 * ===================================================================================================================================================
 * Descriptive statistics
 * ===================================================================================================================================================
 
use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo.dta", clear

*Descriptive statistics (I only kept first leader)
sum abcc, d
by country, sort: summarize abcc yrschool cyear
pwcorr abcc yrschool
by bdec, sort: summarize abcc yrschool
tab bdec country, summarize(abcc) means
tab  country, summarize(independence) means
gen ncint=int(nc)
mean  abcc [fweight=ncint],  over(bdec)

*Decsriptive commands
/*pwcorr tsi abcc crop_suitability  Lon Lat altitude 
tabstat abcc d_independence bdec independence, statistics(mean max min variance median)
tabstat abcc if d_independence==0, statistics(mean max min variance median)
tabstat abcc if d_independence==1, statistics(mean max min variance median)
tabstat abcc d_independence bdec independence, statistics(mean max min variance median)
tabstat abcc if d_birth_all==0, statistics(mean max min variance median)
tabstat abcc if d_birth_all==1, statistics(mean max min variance median)*/

*xtset id_unit1 bdec
*xtdescribe
 
 


 * ===================================================================================================================================================
 * ===================================================================================================================================================




clear
clear mata
set max_memory 32g, permanently
set matsize 11000, permanently 
 
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


corrtex yrschool gini d_birth_all d_lead_eth  tse_r railway_density slave_density  d_mission count_tribe d_centraliz d_capital dist_cap   d_western


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
	
	
	

****************END (the rest is not presented in the paper)






********************************************************************************
********************************************************************************

* Random effects 

********************************************************************************
********************************************************************************

use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec_balanced_all.dta", clear
merge m:1 id_birth using birth_region_sample_master_for_stata_1940_all.dta, force
keep if _merge==3
drop _merge
spset
*Optionally, tell Sp to use the common ID variable
*spset id_birth, modify replace
*xtset
spmatrix create contiguity W if bdec==1940, first replace /*normalize(spectral) is the default.  The matrix will be normalized so that its largest eigenvalue is 1.*/

*Note: I don´t include country fixed effects because there is a multicollinearity problem with other variables, especially d_western, which changes to the wrong sign. 

* 			    Dependent variable: yrschool
*				============================
tab cntry_code, gen(cntry)
pwcorr yrschool   d_birth_all  tse_r railway_density slave_density d_mission count_tribe d_centraliz d_capital   d_western d_bdec1950 cntry1 cntry2 cntry3 cntry4 cntry5 cntry6 cntry7 cntry8 cntry9 cntry10 cntry11, star(0.05)

tab cntry_name, gen(d_country)


tab d_capital if d_birth_all==1 & bdec==1960
tab  d_birth_all if bdec==1960

generate i_birth_indep=d_birth_all*d_independence
*generate i_birth_ethnic=d_lead_eth*d_independence




* (1) yrschool
spxtregress  yrschool   d_birth_all  cntry1 cntry2 cntry3 cntry4 cntry5 cntry6 cntry7 cntry8 cntry9 cntry10 cntry11, ///
re errorlag(W) 
outreg2 using "1_yrschool&abcc&gini_all.xls", replace  tex ///
drop(tse_r railway_density slave_density d_western d_mission count_tribe d_bdec1950 lat_id_bir lon_id_bir cntry1 cntry2 cntry3 cntry4 cntry5 cntry6 cntry7 cntry8 cntry9 cntry10 cntry11) ///
addtext(Controls, no, Country FE, yes) addstat(Pseudo R2, e(r2_p))  ctitle("yrschool" ) dec(2)  nocons

* (1) yrschool
spxtregress  yrschool   d_birth_all   tse_r   railway_density slave_density  d_mission count_tribe  d_capital  dist_cap  d_western  cntry1 cntry2 cntry3 cntry4 cntry5 cntry6 cntry7 cntry8 cntry9 cntry10 cntry11, ///
re errorlag(W) 
outreg2 using "1_yrschool&abcc&gini_all.xls", append  tex ///
drop(tse_r railway_density slave_density d_western d_mission count_tribe  dist_cap  d_capital d_bdec1950 lat_id_bir lon_id_bir cntry1 cntry2 cntry3 cntry4 cntry5 cntry6 cntry7 cntry8 cntry9 cntry10 cntry11) ///
addtext(Controls, yes, Country FE, yes) addstat(Pseudo R2, e(r2_p))  ctitle("yrschool" ) dec(2)  nocons


* (1) abcc

spxtregress abcc  d_birth_all  cntry1 cntry2 cntry3 cntry4 cntry5 cntry6 cntry7 cntry8 cntry9 cntry10 cntry11, ///
re errorlag(W) 
outreg2 using "1_yrschool&abcc&gini_all.xls", append tex ///
drop(tse_r railway_density slave_density d_western d_mission count_tribe d_bdec1950 lat_id_bir lon_id_bir cntry1 cntry2 cntry3 cntry4 cntry5 cntry6 cntry7 cntry8 cntry9 cntry10 cntry11) ///
sortvar(d_birth_all   d_lead_eth i_birth_indep d_lead_eth d_independence i_birth_ethnic  tse_r railway_density  slave_density  suit_cerea  d_mission d_capital d_france) ///
addtext(Controls, no, Country FE, yes) addstat(Pseudo R2, e(r2_p))  ctitle("abcc" ) dec(2)  nocons

* (2) abcc

spxtregress  abcc   d_birth_all   tse_r   railway_density slave_density  d_mission count_tribe  d_capital  dist_cap  d_western  cntry1 cntry2 cntry3 cntry4 cntry5 cntry6 cntry7 cntry8 cntry9 cntry10 cntry11, ///
re errorlag(W) 
outreg2 using "1_yrschool&abcc&gini_all.xls", append  tex ///
drop(tse_r railway_density slave_density d_western d_mission count_tribe  dist_cap d_capital d_bdec1950 lat_id_bir lon_id_bir cntry1 cntry2 cntry3 cntry4 cntry5 cntry6 cntry7 cntry8 cntry9 cntry10 cntry11) ///
sortvar(d_birth_all   d_lead_eth i_birth_indep d_lead_eth d_independence i_birth_ethnic  tse_r railway_density  slave_density  suit_cerea  d_mission d_capital d_france) ///
addtext(Controls, yes, Country FE, yes) addstat(Pseudo R2, e(r2_p))  ctitle("abcc" ) dec(2)  nocons


* Re-calculating the matrix for gini (66 observations less): 
************************************************************

use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec_balanced_all.dta", clear
bysort bdec: sum id_birth if gini==.  /*22 regions missing*/
drop if gini==.
spbalance, balance /*strongly balanced*/
xtdes
save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec_balanced_gini.dta", replace

keep if bdec==1940
keep cntry_name id_birth 
*I create an csv to import in qgis:
*export excel using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all.xls", replace
export delimited using "id_birth_sample_for_gis_all_gini.csv", replace
*import the file in qgis, merge it with master and export it to stata folder as shp

*Create dta from shapefile:
clear  
spset, clear
spshape2dta "birth_region_sample_master_for_stata_1940_gini.shp", replace   /*this is the shapefile created in qgis, it only includes the 1940 observations*/

use birth_region_sample_master_for_stata_1940_gini.dta, clear
merge 1:m id_birth using "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec_balanced_gini.dta", force
drop if _merge==2
keep _ID _CX _CY Shape_Leng Shape_Area id_birth region

*Look at trasnlated data: 
use birth_region_sample_master_for_stata_1940_gini.dta, clear
 describe
list in 1/5
spset id_birth, modify replace
save birth_region_sample_master_for_stata_1940_gini.dta, replace

*************************
*************************
*  Regression framework *
************************* 
*************************
use birth_region_sample_master_for_stata_1940_gini.dta, clear
 describe
list in 1/5
spset id_birth, modify replace

use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec_balanced_gini.dta", clear
merge m:1 id_birth using birth_region_sample_master_for_stata_1940_gini.dta, force
keep if _merge==3
drop _merge

*Optionally, tell Sp to use the common ID variable
spmatrix create contiguity W if bdec==1940, first replace /*normalize(spectral) is the default.  The matrix will be normalized so that its largest eigenvalue is 1.*/

tab cntry_code, gen(cntry)

* (1) gini

spxtregress  gini d_birth_all cntry1 cntry2 cntry3 cntry4 cntry5 cntry6 cntry7 cntry8 cntry9 cntry10 cntry11 , ///
re errorlag(W) 
outreg2 using "1_yrschool&abcc&gini_all.xls", append  tex ///
drop(lat_id_bir lon_id_bir cntry1 cntry2 cntry3 cntry4 cntry5 cntry6 cntry7 cntry8 cntry9 cntry10 cntry11) ///
sortvar(d_birth_all   d_lead_eth int_indep_birth   int_indep_ethnic tse_r railway_density  slave_density  suit_cerea  d_mission d_capital d_france) ///
addtext(Controls, no, Country FE, yes) addstat(Pseudo R2, e(r2_p))   ctitle("gini" ) dec(2)  nocons


* (2) gini

spxtregress  gini d_birth_all tse_r   railway_density slave_density  d_mission count_tribe  d_capital  dist_cap  d_western  cntry1 cntry2 cntry3 cntry4 cntry5 cntry6 cntry7 cntry8 cntry9 cntry10 cntry11, ///
re errorlag(W) 
outreg2 using "1_yrschool&abcc&gini_all.xls",append  tex ///
drop(tse_r   railway_density slave_density  d_mission count_tribe  d_capital  dist_cap  d_western  cntry1 cntry2 cntry3 cntry4 cntry5 cntry6 cntry7 cntry8 cntry9 cntry10 cntry11) ///
addtext(Controls, yes, Country FE, yes) addstat(Pseudo R2, e(r2_p))  ctitle("gini" ) dec(2)  nocons








/*
**********************************************************
* Calculating the matrix with coordinates (not shapefile): 
**********************************************************
use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec_balanced_all.dta", clear

preserve
keep if bdec==1940
tab bdec
*Step 5: Create inverse-distance matrix W weighting matrix
*Create inverse-distance matrix W weighting matrix:
   *spmat idistance W lat_id_bir lon_id_bir, id(id_birth) normalize(row) 
 spset, clear
spset id_birth, coord(lon_id_bir lat_id_bir)
spmatrix create idist W , replace
restore /*we dropped to calculate the distrance matrix for only one decade (to avoid repetition), but we now restore all observations with all bdec*/


*Optionally, tell Sp to use the common ID variable
spset id_birth, modify replace
xtset
* 			    Dependent variable: yrschool
*				============================

* (2) *Just d_ind, d_birthplace, d_france, d_bdec1950 

spxtregress  yrschool   d_birth_all  tse_r railway_density slave_density suit_cerea d_mission count_tribe d_centraliz d_capital   d_western d_bdec1950, ///
re errorlag(W) 
outreg2 using "1_yrschool_all.xls", append  tex ///
drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code) ///
sortvar(d_birth_all   d_lead_eth int_indep_birth   int_indep_ethnic tse_r railway_density  slave_density  suit_cerea  d_mission d_capital d_france) ///
addtext(Region FE, YES , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("yrschool_all" ) dec(2)  nocons

* (5) *Just d_ind, d_birthplace, d_france, d_bdec1950 

spxtregress  yrschool  d_lead_eth  tse_r railway_density slave_density suit_cerea d_mission count_tribe d_centraliz d_capital   d_western d_bdec1950, ///
re errorlag(W) 
outreg2 using "1_yrschool_all.xls",append  tex ///
drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code) ///
sortvar(d_birth_all   d_lead_eth int_indep_birth   int_indep_ethnic tse_r railway_density  slave_density  suit_cerea  d_mission d_capital d_france) ///
addtext(Region FE, YES , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("yrschool_all" ) dec(2)  nocons

* (8) *Just d_ind, d_birthplace, d_france, d_bdec1950 

spxtregress  yrschool d_birth_all d_lead_eth  tse_r railway_density slave_density suit_cerea d_mission count_tribe d_centraliz d_capital   d_western d_bdec1950, ///
re errorlag(W) 
outreg2 using "1_yrschool_all.xls",append  tex ///
drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code) ///
sortvar(d_birth_all   d_lead_eth int_indep_birth   int_indep_ethnic tse_r railway_density  slave_density  suit_cerea  d_mission d_capital d_france) ///
addtext(Region FE, YES , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("yrschool_all" ) dec(2)  nocons
*/





*************************
*************************
*  Regression framework *
************************* 
*************************

use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec_balanced_wa.dta", clear
merge m:1 id_birth using birth_region_sample_master_for_stata_all_wa, force
keep if _merge==3
drop _merge
spset
*Optionally, tell Sp to use the common ID variable
spset id_birth, modify replace
xtset
spmatrix create contiguity W if bdec==1940, first replace /*normalize(spectral) is the default.  The matrix will be normalized so that its largest eigenvalue is 1.*/

* 			    Dependent variable: yrschool
*				============================

*I include 1950s because of change in trend
* (1) *Just d_ind, d_birthplace, d_france, d_bdec1950 
spxtregress yrschool   d_birth_all  d_bdec1950  i.cntry_code, ///
re errorlag(W)
outreg2 using "1_yrschool_all.xls", replace  tex ///
drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code) ///
sortvar(d_birth_all   d_lead_eth int_indep_birth  int_ethnicafter tse_r railway_density  slave_density  suit_cerea  d_mission d_capital d_france) ///
addtext(Region FE, YES , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("yrschool_wa" ) dec(2)  nocons

* (2) Add d_ethnicity: d_lead_eth 
spxtregress yrschool  d_birth_all  d_lead_eth  d_bdec1950 i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_yrschool_all.xls", append  tex  ///
drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birth  int_ethnicafter  tse_r   railway_density  slave_density  suit_cerea  d_mission count_tribe  d_capital d_france) ///
addtext(Region FE, YES , Controls, 0) addstat(Pseudo R2, e(r2_p)) ctitle("yrschool_wa" ) dec(2)  nocons

* (3) Add many other controls (maybe six or so)
spxtregress  yrschool d_lead_eth d_birth_all d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital  d_france i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_yrschool_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth  int_indep_birth  int_ethnicafter tse_r railway_density slave_density  suit_cerea  d_mission count_tribe d_capital d_france) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("yrschool_wa" ) dec(2)  nocons


* (3) Add many other controls (maybe six or so)
spxtregress  yrschool  d_birth_all int_indep_birth d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital d_france  i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_yrschool_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birth   int_ethnicafter tse_r railway_density slave_density  suit_cerea  d_mission d_capital d_france) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("yrschool_wa" ) dec(2)  nocons


* (5) Add many other controls (maybe six or so)
spxtregress  yrschool d_lead_eth   int_indep_ethnic  d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital d_france i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_yrschool_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birth   int_indep_ethnic tse_r railway_density slave_density  suit_cerea  d_mission d_capital d_france ) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("yrschool_wa" ) dec(2)  nocons

* (6) Add many other controls (maybe six or so)
spxtregress  yrschool d_birth_all int_indep_birth d_lead_eth  int_indep_ethnic  d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital d_france  i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_yrschool_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birth  int_indep_ethnic  tse_r railway_density slave_density  suit_cerea  d_mission d_capital d_france) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("yrschool_wa" ) dec(2)  nocons




scatter yrschool r, mlabel(cntry_name)


* 				  Dependent variable: abbc
*				==========================

*I include 1950s because of change in trend
* (1) *Just d_ind, d_birthplace, d_france, d_bdec1950 
spxtregress abcc  d_birth_all  d_bdec1950  i.cntry_code, ///
re errorlag(W)
outreg2 using "1_abcc_all.xls", replace  tex ///
drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code) ///
sortvar(d_birth_all   d_lead_eth int_indep_birth   int_indep_ethnic tse_r railway_density  slave_density  suit_cerea  d_mission d_capital d_france) ///
addtext(Region FE, YES , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("abcc_wa" ) dec(2)  nocons

* (2) Add d_ethnicity: d_lead_eth 
spxtregress abcc  d_birth_all  d_lead_eth  d_bdec1950 i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_abcc_all.xls", append  tex  ///
drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birth   int_indep_ethnic  tse_r   railway_density  slave_density  suit_cerea  d_mission count_tribe  d_capital d_france) ///
addtext(Region FE, YES , Controls, 0) addstat(Pseudo R2, e(r2_p)) ctitle("abcc_wa" ) dec(2)  nocons

* (3) Add many other controls (maybe six or so)
spxtregress  abcc d_lead_eth d_birth_all d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital  d_france i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_abcc_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth  int_indep_birth   int_indep_ethnic tse_r railway_density slave_density  suit_cerea  d_mission count_tribe d_capital d_france) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("abcc_wa" ) dec(2)  nocons

* (3) Add many other controls (maybe six or so)
spxtregress  abcc  d_birth_all int_indep_birth  d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital  d_france i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_abcc_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birth    int_indep_ethnic tse_r railway_density slave_density  suit_cerea  d_mission d_capital d_france) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("abcc_wa" ) dec(2)  nocons

* (4) Add many other controls (maybe six or so)
spxtregress  abcc d_lead_eth   int_indep_ethnic  d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital  d_france i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_abcc_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birth   int_indep_ethnic tse_r railway_density slave_density  suit_cerea  d_mission d_capital d_france) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("abcc_wa" ) dec(2)  nocons

* (4) Add many other controls (maybe six or so)
spxtregress  abcc d_birth_all int_indep_birth  d_lead_eth   int_indep_ethnic d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital  d_france i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_abcc_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birth  int_indep_ethnic  tse_r railway_density slave_density  suit_cerea  d_mission d_capital d_france) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("abcc_wa" ) dec(2)  nocons


* 				  Dependent variable: gini
*				==========================
*Gini has the same number of observations available for Western Africa

*I include 1950s because of change in trend
* (1) *Just d_ind, d_birthplace, d_france, d_bdec1950 
spxtregress gini  d_birth_all  d_bdec1950  i.cntry_code, ///
re errorlag(W)
outreg2 using "1_gini_all.xls", replace  tex ///
drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code) ///
sortvar(d_birth_all   d_lead_eth iint_indep_birth   int_indep_ethnic tse_r railway_density  slave_density  suit_cerea  d_mission d_capital d_france) ///
addtext(Region FE, YES , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("gini_wa" ) dec(2)  nocons

* (2) Add d_ethnicity: d_lead_eth 
spxtregress  gini  d_birth_all  d_lead_eth  d_bdec1950 i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_gini_all.xls", append  tex  ///
drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birth   int_indep_ethnic  tse_r   railway_density  slave_density  suit_cerea  d_mission count_tribe  d_capital d_france) ///
addtext(Region FE, YES , Controls, 0) addstat(Pseudo R2, e(r2_p)) ctitle("gini_wa" ) dec(2)  nocons

* (3) Add many other controls (maybe six or so)
spxtregress   gini d_lead_eth d_birth_all d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital  d_france i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_gini_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth  int_indep_birth   int_indep_ethnic tse_r railway_density slave_density  suit_cerea  d_mission count_tribe d_capital d_france) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("gini_wa" ) dec(2)  nocons


* (3) Add many other controls (maybe six or so)
spxtregress   gini  d_birth_all int_indep_birth d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital  d_france i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_gini_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birth   int_indep_ethnic tse_r railway_density slave_density  suit_cerea  d_mission d_capital d_france) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("gini_wa" ) dec(2)  nocons


* (4) Add many other controls (maybe six or so)
spxtregress  gini d_lead_eth    int_indep_ethnic  d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital  d_france i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_gini_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birth    int_indep_ethnic tse_r railway_density slave_density  suit_cerea  d_mission d_capital d_france) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("gini_wa" ) dec(2)  nocons

* (4) Add many other controls (maybe six or so)
spxtregress   gini d_birth_all int_indep_birth  d_lead_eth    int_indep_ethnic  d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital  d_france i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_gini_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birth  int_indep_ethnic tse_r railway_density slave_density  suit_cerea  d_mission d_capital d_france) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("gini_wa" ) dec(2)  nocons



*=============================================== 
************************************************
*                Eastern Africa                *
************************************************
*=============================================== 

* Balance the dataset:
*---------------------

use  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", clear

keep if region=="Eastern Africa"

bysort region: tab country bdec , summarize(yrschool) 
bysort region: tab country bdec , summarize(abcc) 
bysort region: tab country bdec , summarize(gini) 

*Drop years when we miss one country:
*We could keep 1930, but the when balancing the sample would decrease significntly if we only maintain observations consistent throughout 4 bdec. This
*way it remains consistent with EA
drop if bdec==1920
drop if bdec==1930
drop if bdec==1980
bysort region: tab country bdec , summarize(yrschool) 


egen wanted = total(inrange(bdec, 1940, 1970)), by(id_birth)
tab wanted
keep if wanted==4 /*keep regions with observations those 3 bdec*/
bysort region: tab country bdec , summarize(yrschool) 
bysort region: tab country bdec , summarize(abcc) 
bysort region: tab country bdec , summarize(gini) 
xtset id_birth bdec
spbalance, balance /*strongly balanced*/
xtdes
save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec_balanced_ea.dta", replace


* Calculating the matrix: 

use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec_balanced_ea.dta", clear
keep if bdec==1940
generate eastern=1
keep cntry_name id_birth eastern

*I create an csv to import in qgis:
*export excel using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all.xls", replace
export delimited using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all_ea.csv", replace   /*Correct*/
*You then export the csv to same folder in GIS, so that you can join it with the master "1_birth_region_sample_master_lmb10.shp" and keep only the regions that were merged. 

*Create dta from shapefile:
clear  
spset, clear
spshape2dta "birth_region_sample_master_for_stata_all_ea.shp", replace   /*this is the shapefile created in qgis, it only includes the 1940 observations*/

use birth_region_sample_master_for_stata_all_ea.dta, clear
merge 1:m id_birth using "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec_balanced_ea.dta", force
drop if _merge==2
keep _ID _CX _CY Shape_Leng Shape_Area id_birth region
sort id_birth

*Look at trasnlated data: 
use birth_region_sample_master_for_stata_all_ea, clear
describe
list in 1/5
spset id_birth, modify replace
save, replace

*************************
*************************
*  Regression framework *
************************* 
*************************

use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec_balanced_ea.dta", clear
xtset id_birth bdec
spbalance
merge m:1 id_birth using birth_region_sample_master_for_stata_all_ea, force
keep if _merge==3
drop _merge
spset
*Optionally, tell Sp to use the common ID variable
spset id_birth, modify replace
xtset
spmatrix create contiguity W if bdec==1940, first replace /*normalize(spectral) is the default.  The matrix will be normalized so that its largest eigenvalue is 1.*/




* 			    Dependent variable: yrschool
*				============================

*I include 1950s because of change in trend
* (1) *Just d_ind, d_birthplace, d_france, d_bdec1950 
spxtregress yrschool   d_birth_all  d_bdec1950  i.cntry_code, ///
re errorlag(W)
outreg2 using "1_yrschool_all.xls", append  tex ///
drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code) ///
sortvar(d_birth_all   d_lead_eth int_indep_birthea   int_indep_ethnicea tse_r railway_density  slave_density  suit_cerea  d_mission d_capital d_france) ///
addtext(Region FE, YES , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("yrschool_ea" ) dec(2)  nocons

* (2) Add d_ethnicity: d_lead_eth 
spxtregress yrschool  d_birth_all  d_lead_eth  d_bdec1950 i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_yrschool_all.xls", append  tex  ///
drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birthea   int_indep_ethnicea  tse_r   railway_density  slave_density  suit_cerea  d_mission count_tribe  d_capital) ///
addtext(Region FE, YES , Controls, 0) addstat(Pseudo R2, e(r2_p)) ctitle("yrschool_ea" ) dec(2)  nocons

* (3) Add many other controls (maybe six or so)
spxtregress  yrschool d_lead_eth d_birth_all d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital   i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_yrschool_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth  int_indep_birthea   int_indep_ethnicea tse_r railway_density slave_density  suit_cerea  d_mission count_tribe d_capital ) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("yrschool_ea" ) dec(2)  nocons


* (3) Add many other controls (maybe six or so)
spxtregress  yrschool  d_birth_all int_indep_birthea d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital   i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_yrschool_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birthea   int_indep_ethnicea tse_r railway_density slave_density  suit_cerea  d_mission d_capital ) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("yrschool_ea" ) dec(2)  nocons


* (4) Add many other controls (maybe six or so)
spxtregress  yrschool d_lead_eth    int_indep_ethnicea  d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital  i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_yrschool_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birthea    int_indep_ethnicea tse_r railway_density slave_density  suit_cerea  d_mission d_capital ) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("yrschool_ea" ) dec(2)  nocons

* (4) Add many other controls (maybe six or so)
spxtregress  yrschool d_birth_all int_indep_birthea  d_lead_eth    int_indep_ethnicea  d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital   i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_yrschool_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birthea   int_indep_ethnicea  tse_r railway_density slave_density  suit_cerea  d_mission d_capital ) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("yrschool_ea" ) dec(2)  nocons

* 				  Dependent variable: abbc
*				==========================

*I include 1950s because of change in trend
* (1) *Just d_ind, d_birthplace, d_france, d_bdec1950 
spxtregress abcc  d_birth_all  d_bdec1950  i.cntry_code, ///
re errorlag(W)
outreg2 using "1_abcc_all.xls", append  tex ///
drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code) ///
sortvar(d_birth_all   d_lead_eth int_indep_birthea int_indep_ethnicea tse_r railway_density  slave_density  suit_cerea  d_mission d_capital ) ///
addtext(Region FE, YES , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("abcc_ea" ) dec(2)  nocons

* (2) Add d_ethnicity: d_lead_eth 
spxtregress abcc  d_birth_all  d_lead_eth  d_bdec1950 i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_abcc_all.xls", append  tex  ///
drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birthea  int_indep_ethnicea  tse_r   railway_density  slave_density  suit_cerea  d_mission count_tribe  d_capital ) ///
addtext(Region FE, YES , Controls, 0) addstat(Pseudo R2, e(r2_p)) ctitle("abcc_ea" ) dec(2)  nocons

* (3) Add many other controls (maybe six or so)
spxtregress  abcc d_lead_eth d_birth_all d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital  i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_abcc_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth  int_indep_birthea  int_indep_ethnicea tse_r railway_density slave_density  suit_cerea  d_mission count_tribe d_capital ) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("abcc_ea" ) dec(2)  nocons

* (3) Add many other controls (maybe six or so)
spxtregress  abcc  d_birth_all int_indep_birthea d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital  i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_abcc_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birthea  int_indep_ethnicea tse_r railway_density slave_density  suit_cerea  d_mission d_capital ) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("abcc_ea" ) dec(2)  nocons

* (4) Add many other controls (maybe six or so)
spxtregress  abcc d_lead_eth  int_indep_birthea  d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital  i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_abcc_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birthea int_indep_ethnicea tse_r railway_density slave_density  suit_cerea  d_mission d_capital ) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("abcc_ea" ) dec(2)  nocons

* (4) Add many other controls (maybe six or so)
spxtregress  abcc d_birth_all int_indep_birthea  d_lead_eth  int_indep_ethnicea  d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital   i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_abcc_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birthea  int_indep_ethnicea  tse_r railway_density slave_density  suit_cerea  d_mission d_capital ) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("abcc_ea" ) dec(2)  nocons


* 				  Dependent variable: gini
*				==========================


* Balance the dataset:
*---------------------

use  "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec.dta", clear

drop if gini==.
keep if region=="Eastern Africa"

bysort region: tab country bdec , summarize(gini) 

*Drop years when we miss one country:
*We could keep 1930, but the when balancing the sample would decrease significntly if we only maintain observations consistent throughout 4 bdec. This
*way it remains consistent with EA
drop if bdec==1930

egen wanted = total(inrange(bdec, 1940, 1970)), by(id_birth)
tab wanted
keep if wanted==4 /*keep regions with observations those 4 bdec*/
bysort region: tab country bdec , summarize(gini) 
xtset id_birth bdec
spbalance, balance /*strongly balanced*/
xtdes
save "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec_balanced_ea_gini.dta", replace

* Calculating the matrix: 
*-------------------------
use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec_balanced_ea_gini.dta", clear
generate eastern=1
keep if bdec==1940
keep id_birth eastern
*I create an csv to import in qgis:
*export excel using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all.xls", replace
export delimited using "C:\Users\laura\Dropbox\0_ACADEMIA\1_Tuebingen 2018-2020\3_Paper_SSA\ld\id_birth_sample_for_gis_all_ea_gini.csv", replace
*export in csv and import it as layer in gis. You join it with master file, keep only regions available (merged), and then export back as shapefile for stata. 

*Create dta from shapefile:
clear  
spset, clear
spshape2dta "birth_region_sample_master_for_stata_all_ea_gini.shp", replace   /*this is the shapefile created in qgis, it only includes the 1940 observations*/

use birth_region_sample_master_for_stata_all_ea_gini.dta, clear
merge 1:m id_birth using "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec_balanced_gini.dta", force
drop if _merge==1  /*These are all others that come from gis but are not in the balanced sample EA for gini*/
drop if _merge==2
keep _ID _CX _CY Shape_Leng Shape_Area id_birth region
sort id_birth
save, replace
*describe
*list in 1/5
*spset id_birth, modify replace
*save, replace


use "1_ipumsi_africa_all_abcc&yrschool_collapsed_birth_20190612_geo_allbdec_balanced_ea_gini.dta", clear
xtset id_birth bdec
spbalance
merge m:m id_birth using  birth_region_sample_master_for_stata_all_ea_gini, force
keep if _merge==3
drop _merge
spset
*Optionally, tell Sp to use the common ID variable
spset id_birth, modify replace
xtset
spmatrix create contiguity W if bdec==1940, first replace /*normalize(spectral) is the default.  The matrix will be normalized so that its largest eigenvalue is 1.*/


*I include 1950s because of change in trend
* (1) *Just d_ind, d_birthplace, d_france, d_bdec1950 
spxtregress gini  d_birth_all  d_bdec1950  i.cntry_code, ///
re errorlag(W)
outreg2 using "1_gini_all.xls", append  tex ///
drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code) ///
sortvar(d_birth_all   d_lead_eth int_indep_birthea  int_indep_ethnicea tse_r railway_density  slave_density  suit_cerea  d_mission d_capital ) ///
addtext(Region FE, YES , Controls, 0) addstat(Pseudo R2, e(r2_p))  ctitle("gini_ea" ) dec(2)  nocons

* (2) Add d_ethnicity: d_lead_eth 
spxtregress  gini  d_birth_all  d_lead_eth  d_bdec1950 i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_gini_all.xls", append  tex  ///
drop(d_benin d_ghana d_guinea d_kenya d_malawi d_mali d_senegal d_sierra d_uganda d_tanzania d_zambia i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birthea  int_indep_ethnicea  tse_r   railway_density  slave_density  suit_cerea  d_mission count_tribe  d_capital) ///
addtext(Region FE, YES , Controls, 0) addstat(Pseudo R2, e(r2_p)) ctitle("gini_ea" ) dec(2)  nocons

* (3) Add many other controls (maybe six or so)
spxtregress   gini d_lead_eth d_birth_all d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital   i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_gini_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth  int_indep_birthea int_indep_ethnicea tse_r railway_density slave_density  suit_cerea  d_mission count_tribe d_capital ) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("gini_ea" ) dec(2)  nocons


* (3) Add many other controls (maybe six or so)
spxtregress   gini  d_birth_all int_indep_birthea d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_gini_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birthea   int_indep_ethnicea tse_r railway_density slave_density  suit_cerea  d_mission d_capital ) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("gini_ea" ) dec(2)  nocons


* (4) Add many other controls (maybe six or so)
spxtregress  gini d_lead_eth  int_indep_ethnicea  d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital  i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_gini_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birthea   int_indep_ethnicea tse_r railway_density slave_density  suit_cerea  d_mission d_capital ) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("gini_ea" ) dec(2)  nocons

* (4) Add many other controls (maybe six or so)
spxtregress   gini d_birth_all int_indep_birthea  d_lead_eth   int_indep_ethnicea  d_bdec1950 tse_r railway_density slave_density suit_cerea d_mission count_tribe d_capital   i.cntry_code , ///
re  errorlag(W)
outreg2 using "1_gini_all.xls", append  tex ///
drop(i.cntry_code) ///
sortvar(d_birth_all d_lead_eth int_indep_birthea  int_indep_ethnicea  tse_r railway_density slave_density  suit_cerea  d_mission d_capital ) ///
addtext(Region FE, YES , Controls, 7) addstat(Pseudo R2, e(r2_p)) ctitle("gini_ea" ) dec(2)  nocons

























